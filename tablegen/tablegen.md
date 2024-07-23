抽象记录和 具体记录
    抽象记录称为类
    具体记录通常称为记录
    类和具体记录具有唯一的名称
    请注意，TableGen 不为字段分配任何含义
    TableGen 允许任意层次的类，以便两个概念的抽象类可以共享第三个超类
    类和具体记录都可能包含未初始化的字段
    未初始化的“值”用问号 ( ?) 表示
    类通常具有未初始化的字段，这些字段预计在具体记录继承这些类时被填充
    多类来将一组记录定义集中到一个地方
    多类是一种宏，可以“调用”它来同时定义多个具体记录
    多类可以从其他多类继承

保留字：
    assert     bit           bits          class         code
    dag        def           dump          else          false
    foreach    defm          defset        defvar        field
    if         in            include       int           let
    list       multiclass    string        then          true

数字：正负整数，0x/0b 

字符串

代码：[{ "多行文本" }]

标识符：
    identifier
    n identifier
    $ identifier

Bang: 
    !add         !and         !cast        !con         !dag
    !div         !empty       !eq          !exists      !filter
    !find        !foldl       !foreach     !ge          !getdagarg
    !getdagname  !getdagop    !gt          !head        !if
    !interleave  !isa         !le          !listconcat  !listremove
    !listsplat   !logtwo      !lt          !mul         !ne
    !not         !or          !range       !repr        !setdagarg
    !setdagname  !setdagop    !shl         !size        !sra
    !srl         !strconcat   !sub         !subst       !substr
    !tail        !tolower     !toupper     !xor
    !cond

类型：
    bit int string dag
    bits<n>
    list<T>
    class id

值和表达式
    Value:
        简单值 后缀
        值 # 值
    后缀：
        { V, V }
        [切片, ]
        .xxx
    切片：
        I
        I I
        I ... I
        I - I

简单值
    true/false
    ?
    { V, V, ... }
    [ V, V, ... ] opt <T>
    ( dagarg, ... )
        dagarg: V    V: $x   $x

sample:
    def Foo {
    int Bar = 5;
    int Baz = Bar;
    }

    multiclass Foo <int Bar> {
    def : SomeClass<Bar>;
    }

    foreach i = 0...5 in
    def Foo#i;

    条件(V:V, V:V, ...)

value
    {17} bit 17
    {8...15}
    [i]
    [i,]
    [4...7, 17, 2...3, 4]
    .field

"#" 粘贴运算符

1.6 语句
    Assert | Class | Def | Defm | Defset | Deftype | Defvar | Dump  | Foreach | If | Let | MultiClass

    定义类：
    class A <dag d> {
        dag the_dag = d;
    }
    定义记录：
    def rec1 : A<(ops rec1)>;

    继承：class A : B, C

    body:
        field
        let: 重置某些数，包括bit n
        defvar: 定义变量，而非field
        assert
