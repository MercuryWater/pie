# parser basic sample

## 简介

本文描述了一个最简单的parser样例程序，以及该parser程序由编译期编译程序的流程伪代码

## parser简单样例程序

如下所示，为最简的parser程序用例

``` p4
const bit<16> ETHERTYPE_IPV4 = 0x0800;
const bit<16> ETHERTYPE_IPV6 = 0x86dd;

struct standard_metadata_t {
    bit<8> error;
    bit<1> drop;
    bit<7> reserved0;
    bit<16> in_port;
    bit<16> out_port;
}

header ethernet_t {
    bit<48> dst_addr;
    bit<48> src_addr;
    bit<16> eth_type;
}

header ipv4_t {
    bit<4> version;
    bit<4> ihl;
    bit<6> dscp;
    bit<2> ecn;
    bit<16> total_len;
    bit<16> identification;
    bit<3> flags;
    bit<13> frag_offset;
    bit<8> ttl;
    bit<8> protocol;
    bit<16> hdr_checksum;
    bit<32> src_addr;
    bit<32> dst_addr;
}

header ipv6_t {
    bit<4> version;
    bit<8> traffic_class;
    bit<20> flow_label;
    bit<16> payload_len;
    bit<8> next_hdr;
    bit<8> hop_limit;
    bit<128> src_addr;
    bit<128> dst_addr;
}

struct parsed_headers_t {
    ethernet_t ethernet;
    ipv4_t ipv4;
    ipv6_t ipv6;
}

parser Parser(packet_in packet,
              out parsed_headers_t hdr,
              inout standard_metadata_t std_meta) {
    state start {
        packet.extract(hdr.ethernet);
        transition select(hdr.ethernet.eth_type){
            ETHERTYPE_IPV4: parse_ipv4;
            ETHERTYPE_IPV6: parse_ipv6;
            default: reject;
        }
    }

    state parse_ipv4 {
        packet.extract(hdr.ipv4);
        transition accept;
    }

    state parse_ipv6 {
        packet.extract(hdr.ipv6);
        transition accept;
    }
}

pie(
    parser()
) main;

```

### package

package当前仅支持parser

### standard metadata

standard metadata为架构预定义的标准元数据

### Parser

parser部分输出两个struct：
1. 报文头
2. 标准元数据

## 编译输出

### parsed_packet_buffer

编译器应当为parser中声明的struct分配至parsed_packet_buffer中固定相对地址，

以c语言结构体的分配为例：

```c

#define HEADER_ATTR __attribute__((scalar_storage_order("big-endian"))) __attribute__((__packed__))

struct HEADER_ATTR standard_metadata_t {
    uint64_t error:8;
    uint64_t drop:1;
    uint64_t reserved0:7;
    uint64_t in_port:16;
    uint64_t out_port:16;
};

struct HEADER_ATTR ethernet_t {
    uint64_t dst_addr:48;
    uint64_t src_addr:48;
    uint64_t eth_type:16;
};

struct HEADER_ATTR ipv4_t {
    uint64_t version:4;
    uint64_t ihl:4;
    uint64_t dscp:6;
    uint64_t ecn:2;
    uint64_t total_len:16;
    uint64_t identification:16;
    uint64_t flags:3;
    uint64_t frag_offset:13;
    uint64_t ttl:8;
    uint64_t protocol:8;
    uint64_t hdr_checksum:16;
    uint64_t src_addr:32;
    uint64_t dst_addr:32;
};

struct HEADER_ATTR ipv6_t {
    uint64_t version:4;
    uint64_t traffic_class:8;
    uint64_t flow_label:20;
    uint64_t payload_len:16;
    uint64_t next_hdr:8;
    uint64_t hop_limit:8;
    uint64_t src_addr_0:64;
    uint64_t src_addr_1:64;
    uint64_t dst_addr_0:64;
    uint64_t dst_addr_1:64;
};

struct HEADER_ATTR __parsed_packet_buffer_t
{
    struct __standard_metadata_t __std_meta;

    struct __fix_header_t {
        struct ethernet_t ethernet;
        struct ipv4_t ipv4;
        struct ipv6_t ipv6;
    } __fix_header;
};
```

### state id

编译器为每一个state分配一个state id，用于state table查表和跳转。当前应分配如下：

| id | state | comment |
| - | - | - |
| 0 | _except | 预分配的用于异常处理的固定保留id |
| 1 | _accept | 为accept分配的固定id |
| 2 | _reject | 为reject分配的固定id |
| 3 | start | 用户编写的入口state |
| 4 | parse_ipv4 | |
| 5 | parse_ipv6 | |

### state table

编译器应为transition语句生成相应的tcam表表项

| id | state_mask | state_key | mask | key | next_state | next_addr |
| - | - | - | - | - | - | - |
| 0 | ~0 | 3 | ~0 | 0x0800 | 4 | <parse_ipv4> |
| 0 | ~0 | 3 | ~0 | 0x86dd | 5 | <parse_ipv6> |
| 0 | ~0 | 3 | 0 | 0 | 2 | <_reject> |
| 0 | ~0 | 4 | 0 | 0 | 1 | <_accept> |
| 0 | ~0 | 5 | 0 | 0 | 1 | <_accept> |
| -1 | 0 | 0 | 0 | 0 | 0 | <_except> |

### 指令

以下为生成的样例程序

``` c
void _start()
{
    __bootrom();
    parser_main();
}

void parser_main()
{
    uint8_t *parsed_packet_buffer_ptr = get_parsed_packet_buffer_base();
    struct __parsed_packet_buffer_t *c = parsed_packet_buffer_ptr;
    reg_t extract_length = 0;
    reg_t error = 0;
    for(;; __wait_packet())
    {
    __PRE_STATE_START:
        error = 0;
        copy_packet(&parsed_packet_buffer->__std_meta), sizeof(__std_meta));
        goto state_start;

    state_start:
        extract_length = sizeof(ethernet_t);
        if (extract_length > read_csr(CSR_PARSER_PACKET_REMAIN))
        {
            error = PARSER_ERROR_PacketTooShort;
            goto __ERROR;
        }
        extract_packet(&parsed_packet_buffer->__fix_header.ethernet), extract_length);

        reg_t key0 = parsed_packet_buffer->__fix_header.ethernet.eth_type;
        write_csr(CSR_PARSER_STATE_REQUEST_U16_0, key0);
        lookup_parser_state_table();

    state_parse_ipv4:
        extract_length = sizeof(ipv4_t);
        if (extract_length > read_csr(CSR_PARSER_PACKET_REMAIN))
        {
            error = PARSER_ERROR_PacketTooShort;
            goto __ERROR;
        }
        extract_packet(&parsed_packet_buffer->__fix_header.ipv4), extract_length);

        lookup_parser_state_table();

    state_parse_ipv6:
        extract_length = sizeof(ipv6_t);
        if (extract_length > read_csr(CSR_PARSER_PACKET_REMAIN))
        {
            error = PARSER_ERROR_PacketTooShort;
            goto __ERROR;
        }
        extract_packet(parsed_packet_buffer_ptr + offsetof(__parsed_packet_buffer_t, __fix_header.ipv6), extract_length);

        lookup_parser_state_table();

    __ERROR:
        parsed_packet_buffer->__std_meta.error = error;
        goto __REJECT;

    __REJECT:
        parsed_packet_buffer->__std_meta.drop = 1;
        goto __END;

    __ACCEPT:
        goto __END;

    __END:
        __send_packet();
        continue;
    }

_except:
    halt();
}

```
