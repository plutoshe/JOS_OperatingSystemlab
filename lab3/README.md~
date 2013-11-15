JOS Lab3 Report
====================================
Result
----------------------------
```
divzero: OK (1.9s) 
softint: OK (0.9s) 
badsegment: OK (0.9s) 
Part A score: 30/30

faultread: OK (0.9s) 
faultreadkernel: OK (1.5s) 
faultwrite: OK (2.4s) 
faultwritekernel: OK (2.1s) 
breakpoint: OK (0.9s) 
testbss: OK (1.6s) 
hello: OK (2.0s) 
buggyhello: OK (2.4s) 
buggyhello2: OK (1.1s) 
evilhello: OK (1.5s) 
Part B score: 50/50

Score: 80/80
```
在做lab时，有一个问题是我在完成所以程序之后，testbss的测试仍没有通过，但是我调试了很久并没有发现我程序的原因，当我把我的程序重命名，然后再copy一份后，make grade就得到了满分，这个不清楚是为什么，之前我也使用过了make clean，但还是testbss过不了，导致不了对应的缺页中断。
做这个lab最大的感受就是需要把握到全局，关于整个系统对于进程调用，进程陷入到内核中各种保护和切换有了一个清晰的全局认识。
结合了操统课上所学到的关于进程的知识，对于操作系统对于进程的管理有了一个大致的认识，也充分了解了操作系统的中断机制。


Part A: User Environments and Exception Handling
======================================
exercise 1
----------------------------
```
Exercise 1. Modify mem_init() in kern/pmap.c to allocate and map the envs array. This array consists of exactly NENV instances of the Env structure allocated much like how you allocated the pages array. Also like the pages array, the memory backing envs should also be mapped user read-only at UENVS (defined in inc/memlayout.h) so user processes can read from this array.

You should run your code and make sure check_kern_pgdir() succeeds.
```
###exercise 1解答
如果之前lab2一样，首先由于envs的指针为空，所以我们需要为他们分配内存，在boot_alloc为对应的env分配NENV个struct Env大小的空间，之后使用boot_map_region将逻辑地址和物理地址对应起来。<br />
mem_init():
```
	envs = (struct Env*) boot_alloc(NENV * sizeof(struct Env));
	boot_map_region(kern_pgdir, UENVS, ROUNDUP(NENV * sizeof(struct Env), PGSIZE), PADDR(envs), PTE_U | PTE_P);
```
exercise 2
--------------
```
Exercise 2. In the file env.c, finish coding the following functions:

env_init()
Initialize all of the Env structures in the envs array and add them to the env_free_list. Also calls env_init_percpu, which configures the segmentation hardware with separate segments for privilege level 0 (kernel) and privilege level 3 (user).
env_setup_vm()
Allocate a page directory for a new environment and initialize the kernel portion of the new environment's address space.
region_alloc()
Allocates and maps physical memory for an environment
load_icode()
You will need to parse an ELF binary image, much like the boot loader already does, and load its contents into the user address space of a new environment.
env_create()
Allocate an environment with env_alloc and call load_icode load an ELF binary into it.
env_run()
Start a given environment running in user mode.
As you write these functions, you might find the new cprintf verb %e useful -- it prints a description corresponding to an error code. For example,

	r = -E_NO_MEM;
	panic("env_alloc: %e", r);
will panic with the message "env_alloc: out of memory".
```
###exercise 2解答 

```
env_init:
	int i;
	env_free_list = NULL;	
	for (i = NENV - 1; i >= 0; i--) {
		envs[i].env_id = 0;
		envs[i].env_link = env_free_list;
		env_free_list = &envs[i];
	}
```
env_init从大到小把对应的页面加入到env_free_list中。
<br />

```
env_setup_vm:
	e->env_pgdir = (pde_t*) page2kva(p);
	p->pp_ref++;
	memcpy(e->env_pgdir, kern_pgdir, PGSIZE); 
	memset(e->env_pgdir, 0, PDX(UTOP) * sizeof(pde_t));
	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
```
这里对应注释我将对应的环境的虚拟地址进行了设置。一开始我使用的是pgdir_walk找对应的页，然后复制到对应的env_pgdir的对应位置，之后发现可以直接使用memcpy，所以直接对应的将要求完成了。


```
region_alloc：
	size_t begin = ROUNDDOWN((size_t)va, PGSIZE);
	size_t end = ROUNDUP(((size_t)va) + len, PGSIZE);
	for (;begin != end; begin += PGSIZE) {
		struct PageInfo *temp = page_alloc(PGSIZE);

		if (!temp) {
			panic("alloc fail");
			return;
		}
		page_insert(e->env_pgdir, temp, (void*)begin, PTE_W | PTE_U); 
	}
	return;
```
在region_alloc中，直接将需要的物理地址加到我们的env_pgdir中去。
<br />

```
load_icode
struct Elf* now = (struct Elf*) binary;
	struct Proghdr *ph, *eph;

	// is this a valid ELF?
	if (now->e_magic != ELF_MAGIC)
		panic("wrong");
	// load each program segment (ignores ph flags)
	lcr3(PADDR(e->env_pgdir));
	ph = (struct Proghdr *) ((uint8_t *) now + now->e_phoff);
	eph = ph + now->e_phnum;
	for (; ph < eph; ph++)
		// p_pa is the load address of this segment (as well
		// as the physical address)
		if (ph->p_type == ELF_PROG_LOAD) {
			region_alloc(e, (void*) ph->p_pa, ph->p_memsz);
			memset((void*)(ph->p_va), 0, ph->p_memsz);
			memcpy((void*)ph->p_va, binary + ph->p_offset, ph->p_filesz);

		}
	e->env_tf.tf_eip = now->e_entry;

	lcr3(PADDR(kern_pgdir));
	region_alloc(e, (void*) (USTACKTOP - PGSIZE), PGSIZE);
```
这里参照的是main.c的程序进行了相应的填写。
<br />

```
env_create:
struct Env* e;
	
	if (env_alloc(&e, 0) < 0) panic("wrong");
	load_icode(e, binary, size);
	e->env_type = type;
	return;
```
<br />

```
env_run:
if (curenv != NULL && curenv->env_status == ENV_RUNNING) {
		curenv->env_status = ENV_RUNNABLE;
	}
	curenv = e;
	curenv->env_status = ENV_RUNNING ;
	curenv->env_runs++;
	lcr3(PADDR(curenv->env_pgdir));
	env_pop_tf(&curenv->env_tf);
	panic("env_run not yet implemented");
```
###exercise 2遇到的问题
在进行是否能运行到int $30的检查时，我一直Triple Fault了在
```
Program received signal SIGTRAP, Trace/breakpoint trap.
=> 0xf0104ed2 <memmove+102>:	rep movsl %ds:(%esi),%es:(%edi)
0xf0104ed2 in memmove (dst=0x200000, src=0xf011e378, n=<unknown type>) at lib/string.c:162
162				asm volatile("cld; rep movsl\n"
```
纠结了这个错误很久的时间，一开始查看代码没有发现任何错误，在单步运行之后，发现是在load_icode出现错误，查明原因是因为自己在这里理解有错误，我们需要的是对与环境对应的页面进行相应的赋值，所以在这里需要用到的是进程的页面机制，在之前加入对面的设置cr3的代码lcr3(PADDR(e->env_pgdir))即可。
exercise 3
--------------
```
Exercise 3. Read Chapter 9, Exceptions and Interrupts in the 80386 Programmer's Manual (or Chapter 5 of the IA-32 Developer's Manual), if you haven't already.
```
###exercise 3解答

仔细阅读了相关文档，学到了很多知识，关于具体的中断的实现机制有了一个清晰的了解。
exercise 4
--------------
```
Exercise 4. Edit trapentry.S and trap.c and implement the features described above. The macros TRAPHANDLER and TRAPHANDLER_NOEC in trapentry.S should help you, as well as the T_* defines in inc/trap.h. You will need to add an entry point in trapentry.S (using those macros) for each trap defined in inc/trap.h, and you'll have to provide _alltraps which the TRAPHANDLER macros refer to. You will also need to modify trap_init() to initialize the idt to point to each of these entry points defined in trapentry.S; the SETGATE macro will be helpful here.

Your _alltraps should:

push values to make the stack look like a struct Trapframe
load GD_KD into %ds and %es
pushl %esp to pass a pointer to the Trapframe as an argument to trap()
call trap (can trap ever return?)
Consider using the pushal instruction; it fits nicely with the layout of the struct Trapframe.

Test your trap handling code using some of the test programs in the user directory that cause exceptions before making any system calls, such as user/divzero. You should be able to get make grade to succeed on the divzero, softint, and badsegment tests at this point.
```
###exercise 4解答
查询了相关资料，找到关于error code不同中断的处理方式。
```
向量号	助记符	描述	类型	出错码	源
0	#DE	除法错	Fault	无	DIV和IDIV指令
1	#DB	调试异常	Fault/Trap	无	任何代码和数据的访问
2	—	非屏蔽中断	Interrupt	无	非屏蔽外部中断
3	#BP	调试断点	Trap	无	指令INT 3
4	#OF	溢出	Trap	无	指令INTO
5	#BR	越界	Fault	无	指令BOUND
6	#UD	无效（未定义）操作码	Fault	无	指令UD2或无效指令
7	#NM	设备不可用（无数学协处理器）	Fault	无	浮点或WAIT/FWAIT指令
8	#DF	双重错误	Abort	有（0）	所有能产生异常或NMI或INTR
的指令
9	 	协处理器段越界（保留）	Fault	无	浮点指令（386后不再处理此
异常）
10	#TS	无效TSS	Fault	有	任务切换或访问TSS时
11	#NP	段不存在	Fault	有	加载段寄存器或访问系统段时
12	#SS	堆栈段错误	Fault	有	堆栈操作或加载SS时
13	#GP	常规保护错误	Fault	有	内存或其他保护检验
14	#PF	页错误	Fault	有	内存访问
15	—	Intel保留，未使用	 	 	 
16	#MF	x87FPU浮点错（数学错）	Fault	无	x87FPU浮点指令或WAIT/FWAIT指令
17	#AC	对齐检验	Fault	有（0）	内存中的数据访问（486开始支持）
18	#MC	Machine Check	Abort	无	错误码（若有的话）和源依赖于
具体模式（奔腾CPU开始支持）
19	#XF	SIMD浮点异常	Fault	无	SSE和SSE2浮点指令（奔腾三
开始支持）
20~31	—	Inter保留，未使用	 	 	 
32~255	—	用户定义中断	Interrupt	 	外部中断或int n指令
```

所以在trapentry.S，需要通过使用他提供的2种不同的宏对于这多种中断进行相应的初始化。
```
TRAPHANDLER_NOEC(trap_handler0, 0)
TRAPHANDLER_NOEC(trap_handler1, 1)
TRAPHANDLER_NOEC(trap_handler2, 2)
TRAPHANDLER_NOEC(trap_handler3, 3)
TRAPHANDLER_NOEC(trap_handler4, 4)
TRAPHANDLER_NOEC(trap_handler6, 6)
TRAPHANDLER_NOEC(trap_handler7, 7)
TRAPHANDLER_NOEC(trap_handler8, 8)
TRAPHANDLER_NOEC(trap_handler9, 9)
TRAPHANDLER(trap_handler10, 10)
TRAPHANDLER(trap_handler11, 11)
TRAPHANDLER(trap_handler12, 12)
TRAPHANDLER(trap_handler13, 13)
TRAPHANDLER(trap_handler14, 14)
TRAPHANDLER_NOEC(trap_handler16, 16)
TRAPHANDLER(trap_handler17, 17)
TRAPHANDLER_NOEC(trap_handler18, 18)
TRAPHANDLER_NOEC(trap_handler19, 19)
```
并且在trap.c中对于IDT向量表进行相应的初始化
```
	extern void trap_handler0();
	extern void trap_handler1();
	extern void trap_handler2();
	extern void trap_handler3();
	extern void trap_handler4();
	extern void trap_handler6();
	extern void trap_handler7();
	extern void trap_handler8();
	extern void trap_handler9();
	extern void trap_handler10();
	extern void trap_handler11();
	extern void trap_handler12();
	extern void trap_handler13();
	extern void trap_handler14();
	extern void trap_handler16();
	extern void trap_handler17();
	extern void trap_handler18();
	extern void trap_handler19();
	// LAB 3: Your code here.

	SETGATE(idt[0], 0, GD_KT, trap_handler0, 0); 
	SETGATE(idt[1], 0, GD_KT, trap_handler1, 0); 
	SETGATE(idt[2], 0, GD_KT, trap_handler2, 0); 
	SETGATE(idt[3], 0, GD_KT, trap_handler3, 0); 
	SETGATE(idt[4], 0, GD_KT, trap_handler4, 0); 

	SETGATE(idt[6], 0, GD_KT, trap_handler6, 0); 
	SETGATE(idt[7], 0, GD_KT, trap_handler7, 0); 
	SETGATE(idt[8], 0, GD_KT, trap_handler8, 0); 
	SETGATE(idt[10], 0, GD_KT, trap_handler10, 0);
	SETGATE(idt[11], 0, GD_KT, trap_handler11, 0); 
	SETGATE(idt[12], 0, GD_KT, trap_handler12, 0); 
	SETGATE(idt[13], 0, GD_KT, trap_handler13, 0); 
	SETGATE(idt[14], 0, GD_KT, trap_handler14, 0); 

	SETGATE(idt[16], 0, GD_KT, trap_handler16, 0); 
	SETGATE(idt[17], 0, GD_KT, trap_handler17, 0); 
	SETGATE(idt[18], 0, GD_KT, trap_handler18, 0); 
	SETGATE(idt[19], 0, GD_KT, trap_handler19, 0); 
```

Challenge 1
```
Challenge! You probably have a lot of very similar code right now, between the lists of TRAPHANDLER in trapentry.S and their installations in trap.c. Clean this up. Change the macros in trapentry.S to automatically generate a table for trap.c to use. Note that you can switch between laying down code and data in the assembler by using the directives .text and .data.
```
---
##challenge 1解答
这个challenge的本质是让我们写一个data段来共享一个全局变量使得我们可以循环来直接调用我们的数组，我当时最直接的做法是开启一个data段的数据为数据直接赋值，让之后的trap.c的SETGATE的操作可以直接循环做。如：
```
.data
.long trap_handler0
.long trap_handler1
.long trap_handler2
.long trap_handler3
.long trap_handler4
.long 0
.long trap_handler6
.long trap_handler7
.long trap_handler8
.long 0
.long trap_handler10
.long trap_handler11
.long trap_handler12
.long trap_handler13
.long trap_handler14
.long 0
.long trap_handler16
.long trap_handler17
.long trap_handler18
.long trap_handler19
```
这是对trap.c中的代码的优化:
```
	extern uint32_t vectors[];
	int i;
	for (i = 0; i < 20; i++) {
		SETGATE(idt[i], 0, GD_KT, vectors[i], 0);
	}
```
之后发现这样其实是把trap.c中的这个操作移动到了.S文件中去做，实际的代码量并没有减少，所以之后考虑到是否能将这一部分优化，之后发现.text和.data几乎做了相同的事情，如果能使用LOOP编译命令是否可以更加的优，之后发现这么做是不行的，毕竟在error code的压栈时，要分别考虑，这样写更为麻烦。<br />
所以之后想到了将.text和.data段合在一起可以减少一半的代码量，之后发现在实现我对应的宏时发生了这样的错误:
```
Error: junk at end of line, first unrecognized character is `t'
kern/trapentry.S:133: Error: bad or irreducible absolute expression
```
之后注意到是自己在实现宏时没有注意到宏是以一行来表示，在.data和.text代码后要加入;号使得语法正确。
```
#define MYHANDLER(name, num)						\
	.text;				\
	.globl name;		/* define global symbol for 'name' */	\
	.type name, @function;	/* symbol type is function */		\
	.align 2;		/* align function definition */		\
	name:			/* function starts here */		\
	pushl $(num);							\
	jmp _alltraps; \
	.data; \
	.long name 

#define MYHANDLER_NOEC(name, num)					\
	.text; \
	.globl name;							\
	.type name, @function;						\
	.align 2;							\
	name:								\
	pushl $0;							\
	pushl $(num);							\
	jmp _alltraps; 						\
	.data;						\
	.long name

#define MYHANDLER_NULL() \
	.data; \
	.long 0
/*
 * Lab 3: Your code here for generating entry points for the different traps.
 */
.data
.align 2
.global vectors

vectors:
.text
MYHANDLER_NOEC(trap_handler0, 0)
MYHANDLER_NOEC(trap_handler1, 1)
MYHANDLER_NOEC(trap_handler2, 2)
MYHANDLER_NOEC(trap_handler3, 3)
MYHANDLER_NOEC(trap_handler4, 4)
MYHANDLER_NULL()
MYHANDLER_NOEC(trap_handler6, 6)
MYHANDLER_NOEC(trap_handler7, 7)
MYHANDLER_NOEC(trap_handler8, 8)
MYHANDLER_NULL()
MYHANDLER(trap_handler10, 10)
MYHANDLER(trap_handler11, 11)
MYHANDLER(trap_handler12, 12)
MYHANDLER(trap_handler13, 13)
MYHANDLER(trap_handler14, 14)
MYHANDLER_NULL()
MYHANDLER_NOEC(trap_handler16, 16)
MYHANDLER(trap_handler17, 17)
MYHANDLER_NOEC(trap_handler18, 18)
MYHANDLER_NOEC(trap_handler19, 19)
```

Question
---
Q1:
```
Answer the following questions in your answers-lab3.txt:

What is the purpose of having an individual handler function for each exception/interrupt? (i.e., if all exceptions/interrupts were delivered to the same handler, what feature that exists in the current implementation could not be provided?)

```
如果不采用特定的方式的话，他们error code的插入，权限的设置都是一样的，但实际上这是需要对于不同的trap，需要进行不同的设置的。
<br />
Q2:
```
Did you have to do anything to make the user/softint program behave correctly? The grade script expects it to produce a general protection fault (trap 13), but softint's code says int $14. Why should this produce interrupt vector 13? What happens if the kernel actually allows softint's int $14 instruction to invoke the kernel's page fault handler (which is interrupt vector 14)?
```
因为用户权限的问题，我们在IDT向量表中设置了page fault的权限为内核，所以当用户产生这种中断时,会触发 general protection fault。
如果允许用户触发page fault的话，如果有病毒不断产生该中断的话，会导致系统资源被大量占用，从而导致系统崩溃。

Part B: Page Faults, Breakpoints Exceptions, and System Calls
====

exercise 5 
---
```
Exercise 5. Modify trap_dispatch() to dispatch page fault exceptions to page_fault_handler(). You should now be able to get make grade to succeed on the faultread, faultreadkernel, faultwrite, and faultwritekernel tests. If any of them don't work, figure out why and fix them. Remember that you can boot JOS into a particular user program using make run-x or make run-x-nox.
```
###exercise 5解答
在这里直接对tf->trapno进行判断即可

```
if (tf->tf_trapno == 14) 
//		page_fault_handler(tf);
```

exercise6
---
```
Exercise 6. Modify trap_dispatch() to make breakpoint exceptions invoke the kernel monitor. You should now be able to get make grade to succeed on the breakpoint test.
```
###exercise 6解答
发现需要对应多个trapno所以将if改成了switch
```
	switch (tf->tf_trapno) {
		case T_PGFLT : 
			page_fault_handler(tf);
			break;
		case T_BRKPT : 
			monitor(tf);
			break;
	}
```
###exercise 6遇到的问题
在这个exercise写完对应代码之后出现了这个错误
```
breakpoint: FAIL (2.5s) 
    ...
         check_page_installed_pgdir() succeeded!
         [00000000] new env 00001000
    GOOD Incoming TRAP frame at 0xefffffbc
    GOOD TRAP frame at 0xf01a2000
           edi  0x00000000
           esi  0x00000000
    ...
           trap 0x0000000d General Protection
           err  0x0000001a
    GOOD   eip  0x00800037
           cs   0x----001b
           flag 0x00000046
           esp  0xeebfdfd0
    GOOD   ss   0x----0023
    BAD  [00001000] free env 00001000
         Destroyed the only environment - nothing more to do!
    GOOD Welcome to the JOS kernel monitor!
         Type 'help' for a list of commands.
         
         QEMU: Terminated via GDBstub
    unexpected lines in output
    MISSING '  trap 0x00000003 Breakpoint'
    QEMU output saved to jos.out.breakpoint
```
说唯一的进程被停止了，这个错误我非常的困惑，当时看程序猜原因可能是他把env直接给了交互式程序导致了唯一的程序，之后发现根本原因是权限的错误，原因是之前我没有把对应的BRKPT对应的中断的权限调整成用户权限，导致之后用户调用该中断时，发现没有权限，系统为了保护所以导致了错误。
Challenge 2
----
```
Challenge! Modify the JOS kernel monitor so that you can 'continue' execution from the current location (e.g., after the int3, if the kernel monitor was invoked via the breakpoint exception), and so that you can single-step one instruction at a time. You will need to understand certain bits of the EFLAGS register in order to implement single-stepping.

Optional: If you're feeling really adventurous, find some x86 disassembler source code - e.g., by ripping it out of QEMU, or out of GNU binutils, or just write it yourself - and extend the JOS kernel monitor to be able to disassemble and display instructions as you are stepping through them. Combined with the symbol table loading from lab 2, this is the stuff of which real kernel debuggers are made.
```
###challenge 2解答
做这个challenge就需要了解EFLAGS寄存器，通过查询相关资料，发现TF位才是我们在这个Challenge需要的。
TF(bit 8) [Trap flag]   将该位设置为1以允许单步调试模式，清零则禁用该模式。
那么continue的程序很容易实现，只需要在monitor中加入env.h，接着继续载入我们的当前进程的环境继续运行即可
```
int mon_continue(int argc, char **argv, struct Trapframe *tf)
{
	if (argc > 1) {
		cprintf("invalid number of parameters\n");
		return 0;
	}
	if (tf == NULL) {
		cprintf("continue error.\n");
		return 0;
	}
	tf->tf_eflags &= ~FL_TF;
	env_run(curenv);
	panic("continue error, env ret");
	return 0;
}
```
修改了对应的breakpoint程序，检测我们的程序的正确性，
```
void
umain(int argc, char **argv)
{
	asm volatile("int $3");
	int i = 1;
	cprintf("break point test point %d\n", i);
	cprintf("A\n");
	asm volatile("int $3");
	i++;
	cprintf("break point test point %d\n", i);
	cprintf("A\n");
	cprintf("A\n");
}
```
得到的结果为下图，符合预期
```
K> continue
Incoming TRAP frame at 0xefffffbc
TRAP NO : 48
SYSCALL NO : 0
break point test point 1
Incoming TRAP frame at 0xefffffbc
TRAP NO : 48
SYSCALL NO : 0
A
Incoming TRAP frame at 0xefffffbc
TRAP NO : 3
Welcome to the JOS kernel monitor!
Type 'help' for a list of commands.
TRAP frame at 0xf01a3000
  edi  0x00000000
  esi  0x00000000
  ebp  0xeebfdfd0
  oesp 0xefffffdc
  ebx  0x00000000
  edx  0xeebfde88
  ecx  0x00000002
  eax  0x00000002
  es   0x----0023
  ds   0x----0023
  trap 0x00000003 Breakpoint
  err  0x00000000
  eip  0x0080005c
  cs   0x----001b
  flag 0x00000092
  esp  0xeebfdfb8
  ss   0x----0023
K> continue
Incoming TRAP frame at 0xefffffbc
TRAP NO : 48
SYSCALL NO : 0
break point test point 2
Incoming TRAP frame at 0xefffffbc
TRAP NO : 48
SYSCALL NO : 0
A
Incoming TRAP frame at 0xefffffbc
TRAP NO : 48
SYSCALL NO : 0
A
Incoming TRAP frame at 0xefffffbc
TRAP NO : 48
SYSCALL NO : 3
[00001000] exiting gracefully
[00001000] free env 00001000
Destroyed the only environment - nothing more to do!
Welcome to the JOS kernel monitor!
Type 'help' for a list of commands.
```
之后在si的命令与continue的命令的程序非常类似，需要更改的只是在si命令上需要将TF赋值位为1。
```
int mon_si(int argc, char **argv, struct Trapframe *tf) {
	if (argc > 1) {
		cprintf("invalid number of parameters\n");
		return 0;
	}
	if (tf == NULL) {
		cprintf("si error.\n");
		return 0;
	}
	tf->tf_eflags |= FL_TF;
	env_run(curenv);
	panic("si error, env ret");
	return 0;
}

```
但完成对应的代码后，之后程序并没有按照我所预期的那么运行，发生了以下情况
```
K> si
Incoming TRAP frame at 0xefffffbc
TRAP NO : 1
TRAP frame at 0xf01a2000
  edi  0x00000000
  esi  0x00000000
  ebp  0xeebfdfd0
  oesp 0xefffffdc
  ebx  0x00000000
  edx  0x00000000
  ecx  0x00000000
  eax  0xeec00000
  es   0x----0023
  ds   0x----0023
  trap 0x00000001 Debug
  err  0x00000000
  eip  0x00800042
  cs   0x----001b
  flag 0x00000196
  esp  0xeebfdfb8
  ss   0x----0023
[00001000] free env 00001000
Destroyed the only environment - nothing more to do!

```
发现程序调用了trap为1的debug中断，导致了唯一的进程的崩溃，之后了解原因为需要将DEBUG的中断加入到tf_dispatch中，即
```
		case T_DEBUG : 
			monitor(tf);
			break;
```
结果通过观察trap的eip的变化证明了程序的正确性
```
K> si
Incoming TRAP frame at 0xefffffbc
TRAP NO : 1
Welcome to the JOS kernel monitor!
Type 'help' for a list of commands.
TRAP frame at 0xf01a3000
  edi  0x00000000
  esi  0x00000000
  ebp  0xeebfdfb0
  oesp 0xefffffdc
  ebx  0x00000000
  edx  0xeebfde88
  ecx  0x00000002
  eax  0x00800f98
  es   0x----0023
  ds   0x----0023
  trap 0x00000001 Debug
  err  0x00000000
  eip  0x00800136
  cs   0x----001b
  flag 0x00000192
  esp  0xeebfdf94
  ss   0x----0023
K> si
Incoming TRAP frame at 0xefffffbc
TRAP NO : 1
Welcome to the JOS kernel monitor!
Type 'help' for a list of commands.
TRAP frame at 0xf01a3000
  edi  0x00000000
  esi  0x00000000
  ebp  0xeebfdfb0
  oesp 0xefffffdc
  ebx  0x00000000
  edx  0xeebfde88
  ecx  0x00000002
  eax  0x00800f98
  es   0x----0023
  ds   0x----0023
  trap 0x00000001 Debug
  err  0x00000000
  eip  0x00800137
  cs   0x----001b
  flag 0x00000192
  esp  0xeebfdf90
  ss   0x----0023

```
这样challenge 2就基本完成了，关于他所需要的反编译的每行代码，个人认为应该结合反编译的obj文件，记录obj文件的一个指针，跟当前运行的位置进行比对，之后输出对应的代码即可，以后有时间可以继续做做。

Question
---
```
The break point test case will either generate a break point exception or a general protection fault depending on how you initialized the break point entry in the IDT (i.e., your call to SETGATE from trap_init). Why? How do you need to set it up in order to get the breakpoint exception to work as specified above and what incorrect setup would cause it to trigger a general protection fault?
```
因为break point应该为用户权限的中断，如果设置权限为内核，会导致对应的general protection fault
```
What do you think is the point of these mechanisms, particularly in light of what the user/softint test program does?
```
这种机制可以限制用户使用中断而造成的问题，保护了整个系统，我们可以通过设置 IDT 的dpl位来控制用户的中断的所能进行的行为。

exercise7
---

```
Exercise 7. Add a handler in the kernel for interrupt vector T_SYSCALL. You will have to edit kern/trapentry.S and kern/trap.c's trap_init(). You also need to change trap_dispatch() to handle the system call interrupt by calling syscall() (defined in kern/syscall.c) with the appropriate arguments, and then arranging for the return value to be passed back to the user process in %eax. Finally, you need to implement syscall() in kern/syscall.c. Make sure syscall() returns -E_INVAL if the system call number is invalid. You should read and understand lib/syscall.c (especially the inline assembly routine) in order to confirm your understanding of the system call interface. You may also find it helpful to read inc/syscall.h.

Run the user/hello program under your kernel (make run-hello). It should print "hello, world" on the console and then cause a page fault in user mode. If this does not happen, it probably means your system call handler isn't quite right. You should also now be able to get make grade to succeed on the testbss test.
```
###exercise 7解答
查看对应的代码段，通过阅读GCC-Inline-Assembly-HOWTO,了解了asm volatile干了什么，而对应的syscall的代码，通过判断syscallno，来调用相应的函数，而调用该系统调用需要提供对应的数据，在中断的trap结构的寄存器中，在trap_dispatch中按照顺序将对应的寄存器存入，之后将结果最后保存在eax寄存器中。<br/>

```
syscall.c:
	cprintf("SYSCALL NO : %d\n", syscallno);
	switch (syscallno) {
		case SYS_cgetc : 
			sys_cgetc();
			goto _success_invoke;
		case SYS_env_destroy : 
			sys_env_destroy((envid_t) a1);
			goto _success_invoke;
		case SYS_getenvid :
			sys_getenvid();
			goto _success_invoke;
		case SYS_cputs :
			sys_cputs((char*) a1, (size_t) a2);
			goto _success_invoke;
		default :
			return -E_INVAL;
		
	}

	panic("syscall not implemented");
	_success_invoke : 
		return 0;

```

```
trap.c:
		case T_SYSCALL :
			r = syscall(tf->tf_regs.reg_eax, tf->tf_regs.reg_edx, tf->tf_regs.reg_ecx, tf->tf_regs.reg_ebx, tf->tf_regs.reg_edi, tf->tf_regs.reg_esi);
			tf->tf_regs.reg_eax = r;
			break;
```
这里也需要注意的是系统调用的权限为也为3。

exercise8
---
```
Exercise 8. Add the required code to the user library, then boot your kernel. You should see user/hello print "hello, world" and then print "i am environment 00001000". user/hello then attempts to "exit" by calling sys_env_destroy() (see lib/libmain.c and lib/exit.c). Since the kernel currently only supports one user environment, it should report that it has destroyed the only environment and then drop into the kernel monitor. You should be able to get make grade to succeed on the hello test.
```
###exercise 8解答
这里在libmain中加入以下代码即可
```
thisenv = envs + ENVX(sys_getenvid());
```
exercise9&10
---
```
Exercise 9. Change kern/trap.c to panic if a page fault happens in kernel mode.

Hint: to determine whether a fault happened in user mode or in kernel mode, check the low bits of the tf_cs.

Read user_mem_assert in kern/pmap.c and implement user_mem_check in that same file.

Change kern/syscall.c to sanity check arguments to system calls.

Boot your kernel, running user/buggyhello. The environment should be destroyed, and the kernel should not panic. You should see:

	[00001000] user_mem_check assertion failure for va 00000001
	[00001000] free env 00001000
	Destroyed the only environment - nothing more to do!
	
Finally, change debuginfo_eip in kern/kdebug.c to call user_mem_check on usd, stabs, and stabstr. If you now run user/breakpoint, you should be able to run backtrace from the kernel monitor and see the backtrace traverse into lib/libmain.c before the kernel panics with a page fault. What causes this page fault? You don't need to fix it, but you should understand why it happens.
```
```
Exercise 10. Boot your kernel, running user/evilhello. The environment should be destroyed, and the kernel should not panic. You should see:

	[00000000] new env 00001000
	[00001000] user_mem_check assertion failure for va f0100020
	[00001000] free env 00001000
	
```
###exercise 9&10解答
这个exercise需要对用户调用的空间进行对应的检查，所以在user_mem_check按照他的提示对对应的空间进行了检查。
```
int
user_mem_check(struct Env *env, const void *va, size_t len, int perm)
{
	// LAB 3: Your code here.
	pde_t*  now;
	perm |= PTE_P;
	int l = 1;
	uint32_t begin = ROUNDDOWN((uint32_t) va, PGSIZE);
	uint32_t end = ROUNDUP((uint32_t)(va) + len, PGSIZE);
	for (; begin != end; begin += PGSIZE) {
		if (begin >= ULIM) { 
			if (l) begin = (uint32_t) va;
			user_mem_check_addr = begin; return -E_FAULT;
		}
		now = pgdir_walk(env->env_pgdir, (void*)begin, 0);
		if (now == NULL || (*now & perm) != perm) {
			if (l) begin = (uint32_t) va;
			user_mem_check_addr = begin;
			return -E_FAULT;
		}
		l = 0;
	}


	return 0;
}

```
在 kern/kdebug.c 加入对 usd, stabs, stabstr 的检查
```

		if (user_mem_check(curenv , (void *)usd , sizeof(struct UserStabData), PTE_U) < 0) {
			return -1;
		}

		stabs = usd->stabs;
		stab_end = usd->stab_end;
		stabstr = usd->stabstr;
		stabstr_end = usd->stabstr_end;

		// Make sure the STABS and string table memory is valid.
		// LAB 3: Your code here.
		if (user_mem_check(curenv , (void *)stabs , (uint32_t)stab_end - (uint32_t)stabs , PTE_U) < 0) {
			return -1;
		}
		if (user_mem_check(curenv , (void *) stabstr , (uint32_t)stabstr_end - (uint32_t)stabstr , PTE_U) < 0) {
			return -1;
		}

	}
```
###exercise 9&10遇到的错误
这个exercise我但是buggyhello老是过不了，通过查询对应的结果文件和测试程序，发现我犯了一个常识的错误，如果一开始begin页面就会发生错误的话，我的输出是ROUND_DOWN((uint32_t) va, PGSIZE），而需要的页面是在对应的区间之中的，所以应该输出va，所以对应的我将程序特判了一下避免了这个错误。


