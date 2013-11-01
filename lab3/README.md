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


Part A: User Environments and Exception Handling
======================================
exercise 1
----------------------------
###exercise 1解答
如果之前lab2一样，首先由于envs的指针为空，所以我们需要为他们分配内存，在boot_alloc为对应的env分配NENV个struct Env大小的空间，之后使用boot_map_region将逻辑地址和物理地址对应起来。<br />
mem_init():
```
	envs = (struct Env*) boot_alloc(NENV * sizeof(struct Env));
	boot_map_region(kern_pgdir, UENVS, ROUNDUP(NENV * sizeof(struct Env), PGSIZE), PADDR(envs), PTE_U | PTE_P);
```
exercise 2
--------------
###exercise 2解答 
env_init:
```
int i;
	env_free_list = NULL;	
	for (i = NENV - 1; i >= 0; i--) {
		envs[i].env_id = 0;
		envs[i].env_link = env_free_list;
		env_free_list = &envs[i];
	}
```
env_init从大到小把对应的页面加入到env_free_list中。
</br>
env_setup_vm:
```
	e->env_pgdir = (pde_t*) page2kva(p);
	p->pp_ref++;
	memcpy(e->env_pgdir, kern_pgdir, PGSIZE); 
	memset(e->env_pgdir, 0, PDX(UTOP) * sizeof(pde_t));
	// UVPT maps the env's own page table read-only.
	// Permissions: kernel R, user R
	e->env_pgdir[PDX(UVPT)] = PADDR(e->env_pgdir) | PTE_P | PTE_U;
```
这里对应注释我将对应的环境的虚拟地址进行了设置。一开始我使用的是pgdir_walk找对应的页，然后复制到对应的env_pgdir的对应位置，之后发现可以直接使用memcpy，所以直接对应的将要求完成了。
</br>
region_alloc：
```
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
</br>
load_icode
```
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
这里参照的是main.c的程序进行了相应的填写。</br>
env_create:
```
struct Env* e;
	
	if (env_alloc(&e, 0) < 0) panic("wrong");
	load_icode(e, binary, size);
	e->env_type = type;
	return;
```
</br>
env_run:
```
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
###exercise 3解答
仔细阅读了相关文档，学到了很多知识~~~
exercise 4
--------------
###exercise 4解答
```
Interrupt ID Error Code
divide error 0 				N
debug exception 1			N
non-maskable interrupt 2		N
breakpoint 3				N
overflow 4				N
bounds check 5				N
illegal opcode 6			N
device not available 7			N
double fault 8				N
invalid task switch segment 10 		Y
segment not present stack exception 12 	Y
general protection fault 13 		Y
page fault 14 				Y
floating point error 16 		N
aligment check 17 			Y
machine check 18 			N
SIMD floating point error 19 		N
	
```
Challenge 1
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
之后发现这样其实是把trap.c中的这个操作移动到了.S文件中去做，实际的代码量并没有减少，所以之后考虑到是否能将这一部分优化，之后发现.text和.data几乎做了相同的事情，如果能使用LOOP编译命令是否可以更加的优，之后发现这么做是不行的，毕竟在error code的压栈时，要分别考虑，这样写更为麻烦。<\br>
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
```
Q1
```
如果不采用特定的方式的话，他们error code的插入，权限的设置都是一样的，但实际上这是需要对于不同的trap，需要进行不同的设置的。
```
Q2
```

exercise 5 
---
###exercise 5解答
在这里直接对tf->trapno进行判断即可

```
if (tf->tf_trapno == 14) 
//		page_fault_handler(tf);
```

exercise6
---
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

exercise7
---
###exercise 7解答
查看对应的代码段，通过阅读GCC-Inline-Assembly-HOWTO,了解了asm volatile干了什么，而对应的syscall的代码，通过判断syscallno，来调用相应的函数，而调用该系统调用需要提供对应的数据，在中断的trap结构的寄存器中，在trap_dispatch中按照顺序将对应的寄存器存入，之后将结果最后保存在eax寄存器中。<\br>
syscall.c:
```
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
trap.c:
```
		case T_SYSCALL :
			r = syscall(tf->tf_regs.reg_eax, tf->tf_regs.reg_edx, tf->tf_regs.reg_ecx, tf->tf_regs.reg_ebx, tf->tf_regs.reg_edi, tf->tf_regs.reg_esi);
			tf->tf_regs.reg_eax = r;
			break;
```
exercise8
---
###exercise 8解答
这里在libmain中加入以下代码即可
```
thisenv = envs + ENVX(sys_getenvid());
```
exercise9&10
---
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


