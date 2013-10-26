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
