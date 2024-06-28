# parser requirement

## 简介

本文总结了基于parser的功能需求

## 需求分析

1. core.p4 packet_in接口

    ``` p4
    extern packet_in {
        /// Read a header from the packet into a fixed-sized header @hdr and advance the cursor.
        /// May trigger error PacketTooShort or StackOutOfBounds.
        /// @T must be a fixed-size header type
        void extract<T>(out T hdr);
        /// Read bits from the packet into a variable-sized header @variableSizeHeader
        /// and advance the cursor.
        /// @T must be a header containing exactly 1 varbit field.
        /// May trigger errors PacketTooShort, StackOutOfBounds, or HeaderTooShort.
        void extract<T>(out T variableSizeHeader,
                        in bit<32> variableFieldSizeInBits);
        /// Read bits from the packet without advancing the cursor.
        /// @returns: the bits read from the packet.
        /// T may be an arbitrary fixed-size type.
        T lookahead<T>();
        /// Advance the packet cursor by the specified number of bits.
        void advance(in bit<32> sizeInBits);
        /// @return packet length in bytes.  This method may be unavailable on
        /// some target architectures.
        bit<32> length();
    }
    ```

1. core.p4 error

    ``` p4
    /// Standard error codes.  New error codes can be declared by users.
    error {
        NoError,           /// No error.
        PacketTooShort,    /// Not enough bits in packet for 'extract'.
        NoMatch,           /// 'select' expression has no matches.
        StackOutOfBounds,  /// Reference to invalid element of a header stack.
        HeaderTooShort,    /// Extracting too many bits into a varbit field.
        ParserTimeout,     /// Parser execution time limit exceeded.
        ParserInvalidArgument  /// Parser operation was called with a value
                            /// not supported by the implementation.
    }
    ```

1. transition accept reject

    ``` p4
    transition accept;

    transition reject;
    ```

1. 支持局部变量

    ``` p4
    // erroneous example
    parser p() {
        bit<4> t;
        state start {
        t = 1;
        transition accept;
        }
    }
    ```

1. user meta初始化

    ``` p4
    state start {
        local_metadata.admit_to_l3 = false;
        local_metadata.vrf_id = kDefaultVrf;
        local_metadata.packet_rewrites.src_mac = 0;
        local_metadata.packet_rewrites.dst_mac = 0;
        local_metadata.l4_src_port = 0;
        local_metadata.l4_dst_port = 0;
        local_metadata.wcmp_selector_input = 0;
        local_metadata.mirror_session_id_valid = false;
        local_metadata.color = MeterColor_t.GREEN;
        local_metadata.ingress_port = (port_id_t)standard_metadata.ingress_port;
        local_metadata.route_metadata = 0;
        transition parse_ethernet;
    }
    ```

1. user meta变量赋值

    ``` p4
    state parse_udp {
        packet.extract(hdr.udp);
        local_meta.l4_sport = hdr.udp.sport;
        local_meta.l4_dport = hdr.udp.dport;
    }
    state parse_tcp {
        packet.extract(hdr.tcp);
        local_meta.l4_sport = hdr.tcp.sport;
        local_meta.l4_dport = hdr.tcp.dport;
        transition accept;
    }
    ```

1. select语句

    ``` p4
    select (headers.ipv4.protocol) {
        8w6  : parse_tcp;
        8w17 : parse_udp;
        _    : accept;
    }
    ```

1. select多个key组合

    ``` p4
    transition select(hdr.udp.dport, gtpu.version, gtpu.msgtype) {
        (L4Port.IPV4_IN_UDP, default, default): parse_inner_ipv4;
        (L4Port.GTP_GPDU, GTP_V1, GTPUMessageType.GPDU): parse_gtpu;
        default: accept;
    }
    ```

1. select的ternary匹配

    ``` p4
    select (p.tcp.port) {
        16w0 &&& 16w0xFC00: well_known_port;
        _: other_port;
    }
    ```

1. parser value set支持运行时下发entry进行匹配

    ``` p4
    struct vsk_t {
        @match(ternary)
        bit<16> port;
    }
    value_set<vsk_t>(4) pvs;
    select (p.tcp.port) {
        pvs: runtime_defined_port;
        _: other_port;
    }
    ```

1. verify，支持通过运行时比较，若false，则更新error值为指定值，并跳转reject

    ``` p4
    extern void verify(in bool condition, in error err);
    ```

1. 固定长度extract

    ``` p4
    struct Result { Ethernet_h ethernet;  /* more fields omitted */ }
    parser P(packet_in b, out Result r) {
        state start {
            b.extract(r.ethernet);
        }
    }
    ```

1. 可变长度extract

    ``` p4
    state parse_ipv4_options {
        // use information in the ipv4 header to compute the number of bits to extract
        b.extract(headers.ipv4options,
                    (bit<32>)(((bit<16>)headers.ipv4.ihl - 5) * 32));
        transition dispatch_on_protocol;
    }
    ```

1. lookahead

    ``` p4
    state parse_tcp_option_sack {
        bit<8> n = b.lookahead<Tcp_option_sack_top>().length;
        b.extract(vec.next.sack, (bit<32>) (8 * n - 16));
        transition start;
    }
    ```

1. skip

    ``` p4
    b.extract<T>(_)
    ```

1. Header stacks

    ``` p4
    struct Pkthdr {
        Ethernet_h ethernet;
        Mpls_h[3] mpls;
        // other headers omitted
    }

    parser P(packet_in b, out Pkthdr p) {
        state start {
            b.extract(p.ethernet);
            transition select(p.ethernet.etherType) {
            0x8847: parse_mpls;
            0x0800: parse_ipv4;
            }
        }
        state parse_mpls {
            b.extract(p.mpls.next);
            transition select(p.mpls.last.bos) {
                0: parse_mpls; // This creates a loop
                1: parse_ipv4;
            }
        }
    }
    ```

1. Header stacks中包含可变长的header union成员

    ``` p4
    header Tcp_option_end_h {
        bit<8> kind;
    }
    header Tcp_option_nop_h {
        bit<8> kind;
    }
    header Tcp_option_ss_h {
        bit<8>  kind;
        bit<32> maxSegmentSize;
    }
    header Tcp_option_s_h {
        bit<8>  kind;
        bit<24> scale;
    }
    header Tcp_option_sack_h {
        bit<8>         kind;
        bit<8>         length;
        varbit<256>    sack;
    }
    header_union Tcp_option_h {
        Tcp_option_end_h  end;
        Tcp_option_nop_h  nop;
        Tcp_option_ss_h   ss;
        Tcp_option_s_h    s;
        Tcp_option_sack_h sack;
    }

    typedef Tcp_option_h[10] Tcp_option_stack;
    ```

1. parser语句内的条件语句

    ``` p4
    parser p(out bit<32> b) {
        bit<32> a = 1;
        state start {
            b = (a == 0) ? 32w2 : 3;
            b = b + 1;
            b = (a > 0) ? ((a > 1) ? b+1 : b+2) : b+3;
            transition accept;
        }
    }

    state start {
        if (std.ingress_port == 0)
            std.ingress_port = 2;
        transition accept;
    }
    ```

1. sub parser

    ``` p4
    parser callee(packet_in packet, out IPv4 ipv4) { /* body omitted */ }
    parser caller(packet_in packet, out Headers h) {
        callee() subparser;  // instance of callee
        state subroutine {
            subparser.apply(packet, h.ipv4);  // invoke sub-parser
            transition accept;  // accept if sub-parser ends in accept state
        }
    }
    ```

## 需求列表

1. packet_in
    1. extract固定长度header
    1. extract可变长header
    1. loopahead跳过x bit，获取y bit数据
    1. 跳过可变数量bit
    1. 获取报文长度
        1. 总长还是剩余长度？
1. 存储parse过程中发生的错误
1. 存储临时变量
1. 存储user meta
1. tcam匹配

## 输入

1. 可变长的bit流
    1. 设备相关的元数据
    1. packet header
        1. 即需要进行解析的部分
    1. packet payload
        1. 即不需要解析的部分

## 输出

1. parser解析的error code
1. header
    1. header.valid
    1. 定长header
    1. 可变长的header
1. 设备平台相关的metadata
1. 用户声明的metadata

## 参考链接

1. [p4 16 spec](https://p4.org/p4-spec/docs/P4-16-v1.2.4.html#sec-packet-parsing)
