# parser-main-struct

## parser数据结构分析

1. packet_buffer
    本区域数据用来描述报文数据本身
    ``` strcut or class
    packet_addr
    packet_len
    ```

1. packet_header
    本区域数据用来描述报文操作指针
    ``` strcut or class
    header_addr
    header_len
    ```

1. packet_ops
    本区域数据用来描述报文操作指针
    ``` strcut or class
    packet_op_cursor_addr
    ```

1. header_stack
    packet_header
     ``` strcut or class
    packet_header[MAX_STACK_NUM]
    stack_layer_num
    ```

1. local_var
    
     ``` strcut or class
    lvar
    {
        char name[32]
        b32 value
    }[MAX_LOCAL_NUM]
    ```

1. user_meta
    用户metadata数据
     ``` strcut or class
    u32 option[MAX_USER_META_NUM]
    ```

1. sys_meta
    系统metadata数据
    引用结构packet_header
     ``` strcut or class
    b32 parse_seg_num
    b1 valid[MAX_HEADER_NUM]
    packet_header[MAX_HEADER_NUM]

    ```

1. tcam_key
    进行tcam需要的多个key组合，每个parser过程抽象为统一的tcam查找
     ``` strcut or class
    b32 key_num
    key[MAX_KEY_NUM]
    max[MAX_KEY_NUM]
    register?
    cur_state
    ```

1. tcam_result
    存储tcam查找的结果
     ``` strcut or class
    next_state
    register?
    ```

1. state_error
    1. 存储error发生后的处理起始代码的地址
     ``` strcut or class
    cur_state
    errno
    ```

## 参考链接

1. parser-requirement.md
