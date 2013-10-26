JOS Lab3 Report
====================================
Result
----------------------------


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

###exercise 2遇到的问题
在进行是否能运行到int $30的检查时，我一直Triple Fault了在
```
Program received signal SIGTRAP, Trace/breakpoint trap.
=> 0xf0104ed2 <memmove+102>:	rep movsl %ds:(%esi),%es:(%edi)
0xf0104ed2 in memmove (dst=0x200000, src=0xf011e378, n=<unknown type>) at lib/string.c:162
162				asm volatile("cld; rep movsl\n"
```
纠结了这个错误很久的时间，一开始查看代码没有发现任何错误，在单步运行之后，发现是在load_icode出现错误，查明原因是因为在这里需要用到的是进程的页面机制，在之前加入对面的设置cr3的代码lcr3(PADDR(e->env_pgdir))即可。
exercise 3
--------------
###exercise 3解答
仔细阅读了相关文档，学到了很多知识~~~
exercise 4
--------------
###exercise 4解答

challenge 1
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
所以之后想到了将.text和.data段合在一起可以减少一半的代码量
