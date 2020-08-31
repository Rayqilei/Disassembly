# 第三章节 Hello world
每个函数都有标志性的函数序言（prologue）和尾声（epilogue）

AND ESP,0FFFFFF0h 令栈地址向16字节对齐，属于初始化指令，如果没有对齐，那么CPU将会访问2次才可以进行栈内数据取值，目前的32|64位的框架则是需要进行8字节的对齐。

当我们清空寄存器时候有很多方案
```
mov eax,0
---
xor eax,eax
```
opcode时间方面，由于CPU结构异或的操作时间小于0值传递时间。因此编译器如果不明确表明是会进行优化的

LEAVE指令相当于
```
mov esp,ebp
pop ebp
```
也就是恢复数据栈指针寄存器esp，并且将ebp寄存器的数值恢复到这个函数之前的状态。因为在之前开始函数的阶段中**对ebp,esp寄存器进行了初始化操作，（mov ebp,esp/and esp,0ffffff0h ...），所以在退出之前要恢复寄存器的状态，也就是恢复现场。**

### AT&T风格
常用在unix系统中，也是汇编语言的一种表达风格。

在AT&T的汇编风格中，以小数点开头的，这种汇编语体大量使用了宏，可以使用
```
-fno-asynchronous-unwind-tables
```
来预处理出没有cfi宏的汇编指令

### X64
在x86-64框架的CPU，所有的物理寄存器都被扩展到位64位寄存器，程序可通过R-字头的名称直接调用整个64位的寄存器。

为了尽可能充分利用寄存器，减少访问内存数据的次数，编译器会充分利用寄存器传递函数参数（fastcall），也就是说编译器会优化使用寄存器传递部分参数，再利用内存（数据栈）传递其余参数

WIN64程序中，还会使用RCX，RDX，R8，R9这4个寄存器来存放参数，

目前x64的硬件平台上，寄存器和指针都是64位的，R-开头的寄存器64，但是低32位一样可以执行e-寄存器的工作，x86框架向下兼容的方案。

C语言的程序中,main()函数的返回是整数类型的0,但是出于兼容性和可移植性的考虑,编译器使用32位0,EAX是0,RAX可不一定是0.

阴影空间,在我们代码初始化的时候就有sub rsp,40.,在结束之前还有add rsp,40.在 8.2.1中介绍.

##### mov & lea
mov默认对寄存器值或变量进行操作,可以从寄存器到寄存器,从立即数到寄存器,存储单元到寄存器.
1.  mov指令中的源操作数决定不能是立即数或者CS
2.  mov指令中不允许2个内存单元
3.  mov指令中绝对不允许在2个段寄存器之间传送
4.  mov不会影响标志

lea是load effective address的缩写,是取源操作数的偏移地址,并将其传送到目的操作数单元,类似于C语言的&取地址符号,
```
假设：SI=1000H , DS=5000H, (51000H)=1234H
执行指令 LEA BX , [SI]后，BX=1000H
执行指令 MOV BX , [SI]后，BX=1234H
有时，LEA指令也可用取偏移地址的MOV指令替代。
```

#   第四章 函数序言(prologue) 函数尾声(epilogue)
函数序言是函数在启动时候的一系列指令大致如下
```
push ebp
mov ebp,esp
sub esp,x
```
这些功能是在栈中保存ebp的内容,将esp的值复制到ebp寄存器,然后在修改esp.在函数执行期间ebp寄存器不受函数运行的影响,他是函数访问局部变量和函数参数的基准值,esp则不会动,一直指向当前栈的底部.

在我们退出调动时候就要进行反操作,尾声
```
mov esp,ebp
pop ebp
ret 0
```
##### 所以递归调用的函数会受到栈大小和硬件性能影响,效率很低

# 第五章 栈
x86平台一般指的是esp,rsp,每一次push指令都会对esp/rsp的值-4(32)或者-8(64),

而pop则是+4 / +8 ,是push的逆操作.

引用一篇文献:
```
程序镜像(进程),在逻辑上分为3个段.从虚拟地址空间的0地址开始,第一个段是文本段也是代码段.
代码段在执行过程中不可写,即使一个程序被调用多次,它也必须共享一份文本段
在程序虚拟空间中文本段8kb的边界上,是不共享的,可写数据段heap/stack
```

## 参数的传递
在x86平台上,最常用的参数传递约定是cdecl,以cdecl方式处理参数,其上下文大体是
```
push arg3
push arg2
push arg1
call f
add esp,12;4*3=12
```
地址 | 内容
--- | ---
esp | 返回地址
esp + 4 | arg1,在IDA中记做arg_0
esp + 8 | arg2,在IDA记arg_4
esp + 12 | arg3,在IDA记做arg_8

+   __cdecl:C Declaration,表示的是C语言默认的函数调用方式,所有参数从右向左依次入栈,这些参数的调用者清楚,手动清栈,被调用函数不会要求调用者传递多少参数,调用者过多或者过少的参数,甚至完全不同的参数都不会产生编译阶段的错误.
+   __stdcall:standardCall的缩写,是用C++的标准调用方式,所有参数从右向左入栈,如果是调用类成员,最后一个入栈的是this指针,这些堆栈中的参数由被调用的函数再返回后清除retnX
+   __fastcall是编译器指定的快速调用打多少的函数参数个数很少,使用堆栈传递费时

## alloca()
alloca()函数直接使用栈来分配内存,除此之外与malloc()并无显著的区别.函数尾声的代码还会吧ESP值还原,把数据栈还原成之前的样子.

alloca()。其调用序列与malloc相同，但是它是在当前函数的栈帧上分配存储空间，而不是在堆中。其优点是：当 函数返回时，自动释放它所使用的栈帧，所以不必再为释放空间而费心。其缺点是：某些系统在函数已被调用后不能增加栈帧长度，于是也就不能支持alloca 函数。尽管如此，很多软件包还是使用alloca函数，也有很多系统支持它。

## 栈的脏数据
噪音,脏数据:当数据出栈,原有空间的局部变量不会被自动清理.

# 第六章 printf()函数与参数传递
在进行调试的时候gdb中的反向汇编是AT&T语法,我们可以使用指令

**set disassembly-flavor intel** --- 进行设定.指定生成intel语法

### ntdll
反汇编的时候我看到了这个东西，ntdll.dll是windowsNT内核级别的文件，描述了windows本地NTAPI的接口，当Windows启动时候，ntdll就存在内存中特定的写保护去，别的程序是无法占用这个内存区域的。

ntdll.dll是Windows系统从ring3到ring0的入口。位于Kernel32.dll和user32.dll中的所有win32 API 最终都是调用ntdll.dll中的函数实现的。ntdll.dll中的函数使用SYSENTRY进入ring0，函数的实现实体在ring0中。

很多CRT的许多基本函数都是这里实现的，包括qsort,ceil这样的函数，还有strcpy堆的释放，进程管理都是ntdll实现的，是超级核心。

### SEH链
结构化一场处理是Windows操作系统上，微软对C++语法的拓展，用于处理异常时间的程序控制就结构

异常事件是打断程序正常执行流程的不在以往之中的硬件，软件时间，硬件异常是CPU抛出除以0，数值溢出，软件异常是操作系统与程序通过RaiseException语句抛出的异常

## X64传递9个参数

当我们把参数加到9个 rcx rdx r8 r9寄存器传递4个参数,使用栈传递其余的参数.
```
gcc -m64 test.c -o test
```

## 总结
调用函数的时候,会压栈然后call 再ret

# 第七章 scanf()
好吧,大量使用scanf是没有前途的.本章节逆向分析该函数

## 指针
在CS中,"指针"是很重要的,在我们向函数传递大型数组,结构体或数据对象的时候,传参压栈会很开销巨大,使用指针会降低开销.

在我们传入一个结构体的时候,函数处理完成结构体还要返回一个结构体,那么参数的传递过程是出奇的复杂,因此使用指针传递参数的方式只负责传递数据或者结构体的地址

在msvc中使用 /Fa 来编译为windows的asm文件.ORG $+1 意思则是 内存地址偏移一位.

scanf函数会返回接收到的字符长度,0代表错误.

**可以进行打补丁操作直接跳过判断，JE上面直接修改ZF位置干扰程序跳转。**

# 第八章 传参
标准得从右向左入栈，在我们调试得时候会发现LEA指令用的比ADD多，对于CPU得构造来说，不接引用得取地址比加法运算器更快。

在我们使用64位得时候原本在寄存器得三个参数都被送到了栈中，这种现象叫做**阴影空间(shadow space5)**:对于每一个win64程序来说,都可以(但是不是必须),把4个寄存器得值保存到阴影空间里面,使用引用空间又一下两个优点:
    1.  通过栈传递参数,可以避免浪费寄存器资源(有时候可能占用4个寄存器)
    2.  便于调试器debugger,在程序终端时候找到函数参数.
    
大型函数把输入参数保存在阴影空间中,但是小型函数可能就不会使用阴影空间,,在使用阴影空间时候由吊用放函数分配栈空间,由被调用函数根据需要将寄存器参数转存到引用空间中.

# 第九章:返回值
在x86系统中,被调用方的函数通常通过EAX寄存器进行运算书的返回.
+   如果是byte或者char类型的数据,返回值将存储于EAX寄存器的低8位--AL寄存器.
+   如果返回结果是float类型,那么返回值存储在FPU位ST(0)寄存器中.

### void型函数返回值
主调main函数通常类型是void而不是int,程序如何处理返回值?
```
push envp
push argv
push argc
call main
push eax
call exit
```
转换成C源代码
```
exit(main(argc,argv,envp));
```
当声明的void main(),则函数不会明确返回任何值(没有return指令),不过再main退出时候,EAX还是会存有数据,eax寄存器残存的数据会传递给后者exit()函数,成为后者的输入参数,通常eax寄存器的值会是被调用方残留的确定数据,所以void类型的函数返回值,也就是主代码退出代码,往往是一个伪随机数(pseudorandom)

在之前的案例中使用puts()替换printf(),而且puts()函数会返回它所输出的字符的总数.eax是不清零的.

## 返回类型为结构体
函数只能使用EAX这么一个寄存器返回值,因为有这种局限性,古老一些的C编译器是不能编译返回大于EAX容量的寄存器的,(一般来说,int类型数据),在那个年代如果要返回多个值就只能使用函数返回一个值,再通过指针传递其他返回值

现在的C语言编译器已经没有这样的短板了,return指令甚至可以返回结构体的数据,知识时下很少人这么做了,如果函数眼返回一个大的结构体,会由调用方函数**caller**负责分配空间,给结构体分配指针,再把指针作为第一个参数传给调用函数,现在的编译器已经能够代替程序员做这样的操作了.其处理方式相当于上述几个步骤,知识编译器隐藏了有关操作.

# 指针
#### 补充:内联函数(这个概念经常的忘记)
在CS中,内联函数(有时候叫做**在线函数**或者**编译时期展开函数**)是一种编程语言结构,用来建议编译器对一些特殊函数进行内联扩展(有时候称作在线拓展);也就是说++建议编译器将执行的函数插入并取代每一处调用该函数++的地方(上下文)从而节省了每次调用函数带来的额外时间开销,使用内联函数时候,必须在程序占用空间和程序执行效率之间权衡,因为过多的使用比较复杂的内联扩展将带来很大的存储资源开支,另外还需要特别注意的是**对递归函数的内联拓展**可能引起部分编译器的无穷编译

设计内联函数的动机,是一种用于消除调用函数锁造成的固有时间消耗的方式,一般用于能够快速执行函数,因为在这种情况下函数调用的时间会过大,这种 inline 的方式对于很小的函数有很大的益处.

没有内联函式,难以控制.

# 第十一章 GOTO语句
在源代码中goto语句直接被编译成了JMP指令,这两个指令的效果完全相同,无条件跳转程序的另一个地方.

只有在人为干预的情况下才会使用第二个printf,俗称打补丁 patching技术.

# 第十二章 条件转义指令
JLE -- Jump if Less or Equal  ----- 无符号数的比较 JBE Below

JGE -- Jump if Great or Equal   ----- 无符号数的比较  JAE Above
 
## cmp
cmp是比较指令,cmp的功能相当于做减法,知识不保存结果,执行之后会对相关的**标志寄存器**产生影响
```
ZF=1则AX=BX
ZF=0则AX！=BX
SF=1则AX<BX
SF=0则AX>=BX
SF=0并ZF=0则AX>BX
SF=1或ZF=1则AX<=BX
```

## cmove
该指令会先查看zf位置,如果=1那么就会移动
```
cmp eax,ebx
cmove ecx,eax
```
比较eax与ebx,如果相等那么就把eax放入ecx中


# switch
MSVC编译器在处理栈内部数据的实时,按照其需求,可能给这些内部变量以TV开头的宏变量.

其实这也是分支判断的一种形式,在Python中已经取消了switch

# 循环体
X86指令集中有一条专门给的loop指令,loop指令检测ECX寄存器的值是否为0,如果是0则跳出,否则就是递减,并且跳转回到标签处.

因为循环指令过于复杂的员工,LOOP指令很少被直接使用进行循环控制,如果**用了那么它很可能是手写的汇编**

在不使用优化的时候一般使用eax来进行变量的控制,而使用优化选项之后MSVC/GCC分别使用ESI和EBX寄存器进行循环体的控制,可见对于循环的LOOP使用是很少的.

# C语言字符串的函数
本章节是循环控制语句的具体应用,strlen()函数由循环语句while()来实现.

在本章节的代码中出现了TEST和MOVSX
+   TEST之前由过介绍也是做减法但是不会影响寄存器内的数据只影响标志寄存器的
+   MOVSSX命令是 MOV with Sign-Extend的缩写,把小空间的数据转换为大空间的数据,存在填充高位数据的问题.本章节中使用原始数据的8位数据填充EDX的低八位,如果原始数据是负数,那么就用1来填充剩余的24位,如果是正数那么用0来填充高24位.

当我们使用GCC进行编译的时候,编译器使用了MOVZX:MOV with Zero-Extent的缩写.在将8位和16位数据转化为32的数据,它直接转化复制原始数据到目标寄存器的相对应的低位,然后使用0来填充剩余的位置.相当于完成了

```
xor eax,eax
mov al,[8/16 数据]
```
在处理字符串问题上,主要是为了让char类型的变量转换成int,需要用0填充高位.
# 数据计算指令的替换
出于性能的考虑,编译器可能会将1条计算指令替换为其他的1条指令,甚至是一组等效指令

例如:LEA指令通过替代其他的简单计算指令

## 乘法
```
_TEXT	SEGMENT
a$ = 8
f	PROC
; File C:\Users\82595\Documents\GitHub\Disassembly\mul\main.c
; Line 2
	mov	DWORD PTR [rsp+8], ecx
; Line 3
	mov	eax, DWORD PTR a$[rsp]
	shl	eax, 3
; Line 4
	ret	0
f	ENDP
_TEXT	ENDS
```
编译器会把他作为向左移动的指令2^3 = 8,因此向左边移动了3位,如果是触发则会向右边移动.

如果使用的乘法倍数不是2的幂,那么就会使用imul,作为有符号乘法,imul eax,eax,0Ch 3:乘数,2:被乘数,1:被放入的寄存器
```
_TEXT	SEGMENT
a$ = 8
f	PROC
; File C:\Users\82595\Documents\GitHub\Disassembly\mul\main.c
; Line 2
	mov	DWORD PTR [rsp+8], ecx
; Line 3
	imul	eax, DWORD PTR a$[rsp], 5
; Line 4
	ret	0
f	ENDP
_TEXT	ENDS
```

+   总计:编译器处理乘法由三种方案:1> 进行累加运算 2>进行左侧移动 3>imul 这个api进行移动

## 除法

```
SHR 逻辑右bai移指令
SAR 算术右移指令
SHR 和 SAR都是右du移指令。
只不过SHR右移的时候zhi，它的最高位用0填补，最低位移入daoCF
而SAR右移的时候，最高位不变，最低位移入CF
例如, AL = 1110 1110, BL = 0110 1100, CL = 2
SHR AL, CL后
AL = 0011 1011 SHR最高位用0填补
SAR AL,CL
AL = 1111 1011 SAR最高位不变
SAR BL,CL
BL = 0011 1011 SAR最高位不变
```

SHR(SHift Right)指令将Reg中的数值向右移动,使用0来填充空缺位,并且将舍弃的的数据移动出空间的比特位,那么舍弃的bit正是余数,

SHR与SHL运算的模式相同,但是移动方向不同.

```
CDQ 是一个让很多人感到困惑的指令。  这个指令把 EAX 的第 31 bit 复制到 EDX 的每一个 bit 上。 它大多出现在除法运算之前。它实际的作用只是把EDX的所有位都设成EAX最高位的值。也就是说，当EAX <80000000, EDX 为00000000；当EAX >= 80000000， EDX 则为FFFFFFFF。
```
### 补充一下原理
虽然我们在编程语言中可以直接使用+-/，但是对某些要求不能用/的情况下，我们有必要了解一下计算机是怎样完成乘除法的。

首先，我们要明确一下计算机所能完成的最基本操作是：+（-）和左移右移。虽然ISA中一般都有MUL类指令，但是这些经过译码之后最终的元操作还是加法和移位指令。

其实对于计算机来说,向左移动一位代表 * 2,向右移动一位代表 / 2

#### 举个例子 5 * 3
+   3在内存中0011
+   3的第0位1,5左移动0位为5.
+   3的第1位是1,5左移动1位是5*2 = 10
+   其他位置都是0,不进行移动.
+   然后将我们的结果进行累加 15 .

#### 人类的除法
当我们在计算51/3=17，抛开9*9乘法表。

1.  从被除数的最高位5开始,从0-9选一个数,使得5-i\*3>0 而 使得 5-(i+1)\*3 <0,于是乎我们选择了1,余数是2
2.  将余数 \* 10 + 1 = 21,继续从0-9中选一个数,使得21-3\*i > = 0,那么我们选择了7
3.  从此我们找到了答案17

#### 计算机的除法
计算机计算除法的过程与人类计算的过程很类似，只是选择范围变成了0或1.
还以51/3为例说明（51：110011；3:11）

1.  从第一位开始位1,小于11,结果位置0,余数位1.
2.  从第二位开始,余\*2 + 1 == 11,等于11,结果位置1,余数0;
3.  从第三第四位置开始,余数\*2 + 0 = 0 < 011 ,结果位置0,余数0
4.  从第五位开始余数 \*2 + 1 == 1 结果 0 ,余数1
5.  第六位开始,结果1,余数0.至此运算结束

从此是的结果位置相互连接出来是10001(17),就是我们除法计算的结果
# FPU
FPU是一个专门用作浮点数运算的单元.是CPU上的一个组件,**在早期的计算机体系中,FPU位于CPU之外独立的运算芯片上**

IEEE 754标准规定了计算机程序设计环境中的二进制和是禁止的浮点数的交换,算数格式,以及方法,符合这种标准的浮点数由符号位,尾数(又称作有效数字,小数位),指数位组成.

在80486的处理器问世之前,FPU和CPU并不在一起,FPU叫做辅助处理器,FPU不属于主板的标准配置,如果想要在主板上安装FPU,人们还得单独购买它.当初为了在没有FPU的32位计算机上运算兼容DOOM游戏,John Carmack设计了一套"软"浮点数运算系统,这种系统使用CPU的高16位来存放整数部分,低16位存放浮点数的小数部分.仅仅使用32位通用寄存器就可以完成浮点运算.

ESC字符段(opcode以D8~DF开头)的指令,都会在FPU上面运行.

FPU自带8个80位寄存器用来存储IEEE754格式的浮点数数据,通常叫做ST(0)~ST(7),这8个寄存器组成了一个循环栈结构,在IDA和dbg程序中都把ST(0)显示为ST,在不少的教科书中也叫做栈顶寄存器(Stack top)

在标准的C/C++语言中支持两种浮点类型的数据,单精度32float,双精度64double,GCC还支持long double,即80位的增强浮点类型.

## SSE
SSE(Streaming SIMD Extensions)是英特尔在AMD的3D Now!发布一年之后,在其计算机奔腾3中加入的指令集,是MMX的拓展指令集,SSE指令集提供了70多条的新指令,AMD在athion xp中加入了对这些新指令集的支持

数据流拓展指令集意义在于,加快浮点运算的同事,改善内存的使用效率,是的内存速度更快,按照INTEL的说法,SSE对下面几个领域影响深远,3D几何运算,动画处理,图形处理,视频编辑压缩,语音识别,声音压缩合成.

8个SIMD浮点数寄存器(XMM0~XMM7),他们都是128位紧缩浮点数...浮点数寄存器都是新增的,需要相对应的OS对他进行支持

+   位12~位7组成数值异常屏蔽。如果相应的位置1，则该种异常被屏蔽；如果相应的位被清除，则该种异常开放。在复位时，这些位全被置为1，意味着屏蔽所有的数值异常。
+   位14~位13为舍入控制字段。舍人控制除提供定向舍入、截尾舍入之外，还控制着公用的就近舍入方式。在复位时，舍入控制被置为就近舍入。
+   位15( FZ)用来启动“清洗为0( Flush To Zero)"方式。在复位时，该位被清除，为禁止“清洗为0”方式。MXCSR寄存器的其他位(位31 ~ 位16和位6)定义为保留位并清除为0。试图使用FXRSTOR或者LDMXCSR指令对保留位写人非0值，将引起通用保护异常

DQ操作符,在汇编中定义单位的长度double quad 的缩写
```
message DQ "HELLO"
```
那么其中每一个字符都占用8个字节.

## IEEE 745 中定义的API 

目前我的计算机中编译出来的程序已经使用了SSE的定义,不在使用这种IEEE定义的指令集了.不过还是要多写一些在这个笔记之中方便日后的查看
+   FLD:类似于PUSH指令(存入数据到FPU中)
+   FSTP:类似于POP指令(从FPU中取出数据)
+   FADD:类似于ADD指令(fadd memvar // st0 = st0 + memvar)
+   FSUB:类似于SUB指令
+   FMUL:乘法指令
+   FDIV:触发指令
+   FILD:将证书放入FPU中

SEE
+   movss:浮点数转移到xmm寄存器
+   addss:浮点数做加法
+   mulss:浮点数乘法
+   divss:浮点数除法
+   **cvttss2si**:浮点数变整数

## 栈,计算器,逆波兰算法

# 第十八章 数组
在内存中,数据是按照次序排列的,相同数据类型的一组数据

C语言的字符串是一个每一个元素都是const char 的数组,我们可以使用常量数组"string"[i]来对常量字符串上的字符来取值.

## 缓冲区溢出
编译器借助index,以array[index]的形式标示数组,若仔细审查二进制代码可以发现,程序并没有对数据进行边界的检查,并没有判断索引是为再20以内,那么如果程序访问数组边界以外的数据,就会发生异常,这也是C语言备受争议之处.

```
#include <stdio.h>

int main()
{
    int a[20];
    int i;

    for(i=0;i<20;i++)
    {
        a[i]=i*2;
    }

    printf("a[20] = %d\n",a[20]);

    return 0;
}
```
书中提供了这么一个程序,其结果是显而易见的,会把数组最后一个地方的噪声打印再printf函数中.

4字节大小的int * 20个 应该是80个字节大大小,总共是80 * 8 = 640 bit大小.

C语言可以自己写逻辑进行边界检查,如今的JAVA PYTHON都有边界检查的功能,但是这种功能的开销很大.

## 程序崩溃
程序我们可以看到本来将数字20赋值给了a[19],在函数推出之前会通过栈回复EBP的初始值,当我们继续向越界数组写入代码,就会改写这个地址的位置,CPU修找执行代码的时候没有可执行的代码了,程序就会崩溃了.

假设一下:我们使用字符串代替int数组,可以构造个超长的字符串,吧字符串传递给程序;因为函数不会检测字符串长度,会直接赋值给较短的缓冲区,我就可以强制这个程序跳转到其他程序的地址.*虽然是纸上谈兵,但是这个原理是正确的*

## 缓冲区溢出的保护方案
MSVC:
+   /RTCs:启用栈帧的实时检测
+   /GZ:启用栈检测

**另外还可以再函数启动时候构造一些本地的变量,再写入随机数,再函数结束之前检查这些数值是否发生了变化,如果这些值发生了变化那么就是出现了溢出**

有人把这种写入随机值的方法叫做"百灵鸟 canary",这个绰号来自于"矿工的百灵鸟",过去的矿工下矿要带这百灵鸟,这种动物会检测矿内的毒气,它们面对矿内毒气的时候会暴躁不安,甚至直接死亡.

## C语言编译器无法编译的程序
```
void func(int size)
{
    int a[size];
    ...
}
```

在程序的编译阶段,编译器需要确切的知道到底要分配多大的空间给数组,所以编译器无法处理上述的可变长度的数组.

如果事先我们无法确定可变长度的数组,那么就要使用Malloc()函数在堆中分配一块区域来进行程序.

## 字符串指针
--

## 数组溢出
大于11的情况.

### 数组溢出的保护
如果指望着吊用函数的用户能够保证参数不超过正常的取值范围,那真是天真.我们在使用C的时候可以使用assert()来处理,assert(month < 12 || month > -1); 当条件不在这个范围内就会引发异常

严格的来说assert并不是一个函数,只能称作一个宏,在编译的时候它进行了展开在函数内部进行判断如果出问题再把信息传递给后面的函数中.

## 多维数组
多维数组本质上和我们的线性数组是一样的,因为计算机内部本身是线性的空间.

不过在进行索引的时候 C/C++,Python这种语言使用的是++ 行优先 ++.

而R,Matlab则使用的列优先.

## 小结
数组就是一次排列的一组相同类型的数据,数据元素可以是任意类型的数据,甚至是结构体,如果访问数据中的特定元素首先就要计算其地址.

# 第十九章 位操作
有很多程序都把输入的参数的某些位作为标识符来处理,从表面来看使用不二变量足够代替标志位寄存器了但是这种做法是不理智的

##  特定位
Win32的API有这么一段接口声明
```
#include <windows.h>

int main()
{
    HANDLE fh;

    fh=CreateFile("file.txt",\
    GENERIC_WRITE|GENERIC_READ,FILE_SHARE_READ,\
    NULL,OPEN_ALWAYS,\
    FILE_ATTRIBUTE_NORMAL,NULL);
    return 0;
}
---
进行汇编

; Listing generated by Microsoft (R) Optimizing Compiler Version 19.27.29111.0 

include listing.inc

INCLUDELIB MSVCRT
INCLUDELIB OLDNAMES

PUBLIC	main
EXTRN	__imp_CreateFileA:PROC
pdata	SEGMENT
$pdata$main DD	imagerel $LN3
	DD	imagerel $LN3+68
	DD	imagerel $unwind$main
pdata	ENDS
_DATA	SEGMENT
$SG95360 DB	'file.txt', 00H
_DATA	ENDS
xdata	SEGMENT
$unwind$main DD	010401H
	DD	0a204H
xdata	ENDS
; Function compile flags: /Odtp
_TEXT	SEGMENT
fh$ = 64
main	PROC
; File C:\Users\82595\Documents\GitHub\Disassembly\bit_op\winNT.c
; Line 4
$LN3:
	sub	rsp, 88					; 00000058H
; Line 7
	mov	QWORD PTR [rsp+48], 0
	mov	DWORD PTR [rsp+40], 128			; 00000080H
	mov	DWORD PTR [rsp+32], 4
	xor	r9d, r9d
	mov	r8d, 1
	mov	edx, -1073741824			; c0000000H
	lea	rcx, OFFSET FLAT:$SG95360
	call	QWORD PTR __imp_CreateFileA
	mov	QWORD PTR fh$[rsp], rax
; Line 8
	xor	eax, eax
; Line 9
	add	rsp, 88					; 00000058H
	ret	0
main	ENDP
_TEXT	ENDS
END
```

在API中第二个参数就是我们压栈中的BIT位,我们的CreateFile函数通过KERNEL32.DLL中的函数进行,仅仅使用了TEST指令.
```
if((dwDesiredAccess&0x40000000)==0) goto loc_.....
```
**在X86的汇编中,所有堆操作书进行算数和逻辑运算的指令,都会根据结果修改ZF标志位**.

在大多数情况下,运算结果对ZF的修改,由结果是否为0来决定.
+   若是运算结果为0,那么ZF=1
+   若是运算结果非0,那么ZF=0

#### 举个一些例子
ADD,ADC,INC 加法

SUB,SBB,CMP,DEC,NEG

AND,TEST,OR,XOR,NOT

SHL,SHR,SAL,SAR,RCL,RCR

调整指令 AAA,AAS

#### 本章节小结
C/C++语言中的位移操作符<< >> 相对应,x86指令集中又操作无符号数的SHR|SHL指令和操作有符号数的SAR|SHL.

# 第二十章 线性同余法与伪随机函数
"线性同余法"大概是生成随机数的最简方法,虽然现在的随机函数基本不采用这种技术了,但是它原理简单(只涉及乘法,加法和运算),但是仍然值得研究.

# 第二十二章 结构体
C程序中结构体是一些列的简单数据结构堆积而成的类型,结构体中的各个元素可以是不同类型的数据.

再OD进行SYSTEMTIME结构体的调试,我们发现是一个8 \* word类型的数据结构,如果我们修改层序改成一个int array[8]一样是可以进行编译的,只不过这样做没什么目的,而且还会让代码变得晦涩难懂.

使用数组代替法的代码,编译之后是一样的,一般我们无法通过汇编代码来查看是数组形式的源代码还是结构体形式.

虽说数组可以替换结构体,但是这种做法是不值得一提的,
## malloc() 分配结构体空间
使用malloc()函数会在堆中开辟一块区域

在我们为结构体开辟内存空间的时候,结构体中的各个数据都会进行4字节的对其,目的还是方便CPU读取数据,但是缺点也是很明显的,浪费空间,在我们使用Memcpy的时候如果是10字节的结构体她不会是1个1个字节去cpy,而是4 \* 4 的去复制.
```
cl /GS /Zp1 
```
上述的编译指令就会让我们的编译器进行1字节的对其(不对齐),还有边界检测.

```
#pragma pack(1)
```
也是一个字节对其.

书中我们使用OD对默认封装格式的代码进行了调试,可以发现我们的变量虽然只有1个字节的大小,但是存储的间隔确实是4字节,但是再字节之间还有这一些噪音.(0x30,0x37,0x1).这些脏数据在传递给调用者函数的时候,编译器会使用movsx来进行传递,会把高位置抹0,因此是没有任何影响的

当我们使用了1字节的边界对齐的时候.内存中的数据就是聚集在一起的.

#### 嵌套结构
在我们使用嵌套结构体的时候,我们在汇编代码中并找不到内嵌结构的影子,相反的编译器会把结构体展开,最终成为一个一维的结构体.
+   当然了,如果我们使用的是结构体指针镶嵌在结构体内部,那么它的结构会大有不同.

## 结构体中位操作
用时间换空间,用空间换时间,这是我们编程的时候的铁律.CPUID指令就是用来获取当前CPU的特性信息的.一些bit位置都表达了CPU的信息.

MSVC中有CPUID的宏,但是GCC没有,我们来写一个吧.

值得一提的是,在我们使用C语言进行汇编语言的内嵌的时候,比单纯的进行汇编语言的书写要复杂一些.

### 在GCC中
```
__asm__ [__volatile__]("<asm_route>":output:input:modify);
```
其中,asm表达了汇编程序的开始,volatile表达了不被编译器所优化,这一点很重要,因为被修改的汇编语言会使得意义改变.

asm_route 这教室湖边指令的部分了,可以使用寄存器样板操作数,使用之前加上一个%.%0,%1,%2....
+   也可以使用集体的寄存器名称,但是要加上2个%,例如%%rax

### 对于输出部分
用来规定输出变量如何与寄存器结合的约束,输出部分可以有多个约束或,相互使用逗号隔开,每个约束用"="开头举个例子:

“\=r”(\_\_dummy) :“\=r”表示相应的目标操作数，也就是指令部分的%0,可以使用任何一个通用寄存器，并且变量\_\_dummy ,存放在这个寄存器中。

整理一下代表的意义
```
:I/O,表示使用一个通用寄存器,由GCC在%eax/%ax/%al、%ebx/%bx/%bl、%ecx/%cx/%cl、%edx/%dx/%dl中选取一个GCC认为是合适的; 
q:I/O,表示使用一个通用寄存器,与r的意义相同; 
g:I/O,表示使用寄存器或内存地址; 
m:I/O,表示使用内存地址; 
a:I/O,表示使用%eax/%ax/%al; 
b:I/O,表示使用%ebx/%bx/%bl; 
c:I/O,表示使用%ecx/%cx/%cl; 
d:I/O,表示使用%edx/%dx/%dl; 
D:I/O,表示使用%edi/%di; 
S:I/O,表示使用%esi/%si; 
f:I/O,表示使用浮点寄存器; 
t:I/O,表示使用第一个浮点寄存器; 
u:I/O,表示使用第二个浮点寄存器; 
A:I/O,表示把%eax与%edx组合成一个64位的整数值; 
o:I/O,表示使用一个内存位置的偏移量; 
V:I/O,表示仅仅使用一个直接内存位置; 
i:I/O,表示使用一个整数类型的立即数; 
n:I/O,表示使用一个带有已知整数值的立即数; 
F:I/O,表示使用一个浮点类型的立即数;
```

### 输入部分
与输出部分很像,但是没有了"=",对于同时属于输入|输出的操作数的,在标记之前加上"+"
```
asm("add %1, %0" : "+r"(a) : "r"(b));
```
由于是AT&T的格式,这条指令代表了add eax,ebx,在这里我们的a变量即是输入数据,也是被加数,因此在之前加上了+

我们还可以指定寄存器
```
register int a asm(“%eax”) = 1; // statement 1
```

### 修改部分
这部分常常以”memory”为约束条件，以表示操作完成后，内存中的内容已有改变，如果原来 

某个寄存器的内容来自内存，那么现在内存中这个单元的内容已经改变。

## MSVC x64 禁用了内联汇编
error C4235: 使用了非标准扩展: 不支持在此结构上使用“__asm”关键字

也就是说在x64编译模式下不支持__asm的汇编嵌入。从网上的资料上查到虽然不能直接嵌入汇编程序段，但是可以将程序段全部放到一个asm文件下进行编译，最后asm文件编译生成的obj文件和.cpp文件编译生成的obj文件链接到一起就可以生成exe文件了。
```

.CODE
 
Int_3 PROC
		MOV EAX, 1234  ;返回1234
		RET
Int_3 ENDP
 
 
MY_TEST PROC
		MOV EAX, 23 ;返回23
		RET
MY_TEST ENDP
 
END
```
上述代码段中一个两个汇编函数Int_3和MY_TEST。然后新建一个.h文件来对汇编程序中的代码作声明。这里建立一个名为test.h的头文件。写入如下声明信息：
```
#ifndef __ASMCODE_H
#define __ASMCODE_H
 
 
extern "C"
{
	int _stdcall Int_3();
	int _stdcall MY_TEST();
}
	
 
#endif
```
# 第二十二章 共用体(UNION)
伪随机数生成器:我们可以通过不同的方法生成一个介于1-0之间的随机浮点数,最简单的做法就是:使用Mersenne Twister(马特赛特旋转演算法)之类的P{RNG生成32位DWORD值,把这个值转化为单精度float之后再除以RAND_MAX,这样就得到了一个随机数

Mersenne Twister算法的原理：Mersenne Twister算法是利用线性反馈移位寄存器(LFSR)产生随机数的，LFSR的反馈函数是寄存器中某些位的简单异或，这些位也称之为抽头序列。一个n位的LFSR能够在重复之前产生2^n-1位长的伪随机序列。只有具有一定抽头序列的LFSR才能通过所有2^n-1个内部状态，产生2^n - 1位长的伪随机序列，这个输出的序列就称之为m序列。为了使LFSR成为最大周期的LFSR，由抽头序列加上常数1形成的多项式必须是本原多项式。一个n阶本原多项式是不可约多项式，它能整除x^(2*n-1)+1而不能整除x^d+1，其中d能整除2^n-1。例如(32,7,5,3,2,1,0)是指本原多项式x^32+x^7+x^5+x^3+x^2+x+1，把它转化为最大周期LFSR就是在LFSR的第32，7，5，2，1位抽头。利用上述两种方法产生周期为m的伪随机序列后，只需要将产生的伪随机序列除以序列的周期，就可以得到(0，1)上均匀分布的伪随机序列了。
Mersenne Twister有以下优点：随机性好，在计算机上容易实现，占用内存较少(mt19937的C程式码执行仅需624个字的工作区域)，与其它已使用的伪随机数发生器相比，产生随机数的速度快、周期长，可达到2^19937-1，且具有623维均匀分布的性质，对于一般的应用来说，足够大了，序列关联比较小，能通过很多随机性测试。

对于共用体,只开辟一片最大的空间供union使用.放入其中一个就算是饱和状态.

# 第二十三章 函数指针
函数指针和其他的指针没什么大区别,它所代表的是代码段的起始地址.

此类指针主要引用于:
+   标准C函数 qsort()快速排序
+   NIX系统信号(signal)
+   启动线程CreateThread() windows和pthread_create()POSIX函数
+   Win32的多种函数
+   Linux内核函数

callback方法要比大量使用switch更为方便简单

# 第二十四章 32位处理64位系统
此章节忽略

# SIMD
SIMD意为"单指令流多数据",其意义为"Single Instruction,Multiple Data",这类指令可以一次处理多个数据,在X86的CPU中SIMD子系统和FPU都有专用模块实现.

不久之后,x86 CPU通过MMX指令率先整合了SIMD的运算功能,支持这种技术的CPU里面都有8个64位寄存器,即MM0~MM7,**每个MMX寄存器都是8字节寄存器**,可以容纳2个32位数据,或者4个16位寄存器,使用SIMD指令进行运算的时候,可以使用一条指令进行多个数据的运算.

SSE2指令:
+   movdqu:从内存中加载16字节数据,并复制给XMM寄存器.
+   PADDD:是4对32位数据进行加法运算,并把运算结果存储到第一个操作付的指令,此外,该指令不会设置任何标志位,在溢出时候只保存结果的低32位,也不会保错.
+   movdqa:要求操作数16位对齐其他的与movdqu一样.

我推测显卡用的就是这种基础,属于大量的浮点数运算,一个指令 安排多个像素点进行运算.

在我们使用memcpy的时候,sse2用的多.


在C语言中_m128i xmm0 =....... 一个128字节的浮点类型,用于SSE2运算.

# 硬件基础 第三十章节 有符号数的表示方法
有符号数,补码,取反+1

# 第三十一章 字节序
字节序是指多字节类型的数据在内存中的存放顺序,通常可分为小端和大端.

BSWAP指令可在汇编层面转换数据的字节序

TCP/IP数据序的封装规范采用大端序字节序,所以采用小端序的字节平台要使用专门的转换字节序函数,htonl(),htons().

在TCP/IP的术语里面大端字节序又称为"网络字节序"(Network Byte Order),网络主机采用的字节序叫做"主机字节顺序".x86和其他一些平台的主机序是小端字节序,但是IBM POWER等著名服务器都是采用大端序.

# 第三十儿章 内存布局
C/C++把内存换分为许多个区域 --> 之前写过了

# 第三十三章 CPU
### 分支预测
现在的主流编译器基本都不怎么分配条件转义指令了,虽然目前的分支预测还不完美但是还在努力

**分支预测( Branch predictor)**:当处理一个分支指令时,有可能会产生跳转,从而打断流水线指令的处理,因为处理器无法确定该指令的下一条指令,直到分支指令执行完毕。流水线越长,处理器等待时间便越长,分支预测技术就是为了解决这一问题而出现的。因此,分支预测是处理器在程序分支指令执行前预测其结果的一种机制。在ARM中,使用全局分支预测器,该预测器由转移目标缓冲器( Branch Target Buffer,BTB)、全局历史缓冲器( Global History Buffer,GHB) MicroBe,以及 Return Stack组成。

采用分支预测，处理器猜测进入哪个分支，并且基于预测结果来取指、译码。如果猜测正确，就能节省时间，如果猜测错误，大不了从头再来，刷新流水线，在新的地址处取指、译码。分支预测算法：无条件跳转指令必然会跳转,而条件跳转指令有时候跳转,有时候不跳转,一种简单的预测方式就是根据该指令上一次是否跳转来预测当前时刻是否跳转。如果该跳转指令上次发生跳转,就预测这一次也会跳转,如果上一次没有跳转,就预测这一次也不会跳转。这种预测方式称为:1位预测(1- bit prediction)

# 第三十四章 哈希函数
哈希函数(hash)函数能够产生可靠的程序较高的校验和(CheckSum),可充分满足数据检验的需要.CRC32,算法就是一种不太复杂的哈希算法,哈希值是一种固定长度的信息摘要,不可能根据哈希值逆向"推测"出原文信息无论其原文长度由多长,只能生成32位的校验和,但是从加密学的角度来看,我们可能轻易地伪造出满足同一CRC32哈希值的多个信息原文,当然防止伪造就是哈希函数的任务.

此外人们还使用MD5,SHA1,等哈希算法生成用户密码的摘要(哈希值),然后孜阿坝密码摘要存在数据库中,实际上网上论坛设计用户密码的数据库都是哈希值,否则一旦发生数据库泄漏现象,入侵人员能够轻易的获取密码原文,

### CRC算法的原理
在对信息的处理过程中,我们可以将要被处理的数据块M看成一个n阶的二进制多项式

