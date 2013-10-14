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
