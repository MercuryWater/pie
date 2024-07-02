
# architecture

## 简介

本文介绍了pie项目的整体架构设计

## 总体架构

TODO: 图片

## 基本组件

* pie (packet instruction extension)，基于其他的通用处理器指令集的，以模块扩展方式实现的，用于通用的协议无关的报文数据处理的专用硬件架构，以及与之关联的一组处理器指令集
* pie-core (pie core)，支持pie扩展的一个处理器核心实现
* pie-pipe (pie pipeline)，支持pie架构的，以多个pie core为基本单元的，实现一整套数据处理流程的pie数据面实现
* pie-lang (pie language)，用于描述基于pie架构的pie pipe中数据处理流程的编程语言
* pie-c (pie compiler)，用于编译pie lang，生成可以被pie core执行的程序代码，以及相对应的pie runtime api接口声明
* pie-sim (pie simulator)，pie pipe的软件仿真器
* pie-rt (pie runtime)，pie架构的控制面框架，包含运行时数据操作接口描述

## pie v1

pie v1是pie架构的第一个实现版本，基本特性如下

1. pie基于riscv rv64i指令集为基础，作为rv64i的扩展指令集设计
1. pie-lang使用p4 16版本，包含四个子功能的实现
    1. pipeline描述数据流水线
    1. parser描述数据解析至硬件的流程
    1. control描述数据处理流程
    1. deparser描述从硬件重组为数据包的流程
1. pie-c使用以p4c为框架，基于pie的llvm后端为实现
1. pie-sim基于riscv仿真器spike实现pie core的功能仿真
