JOS Lab3 Report
====================================
Result
----------------------------
```

```


Part A: Multiprocessor Support and Cooperative Multitasking
======================================
这个part主要是让我们实现多cpu和多任务下的运行，涉及到对应的地址空间和程序陷入的理解。
exercise 1
----------------------------
```
Exercise 1. Implement mmio_map_region in kern/pmap.c. To see how this is used, look at the beginning of lapic_init in kern/lapic.c. You'll have to do the next exercise, too, before the tests for mmio_map_region will run.
```
###exercise 1解答
这个exercise是为了解决IO空间的映射问题，我可以用之前写的boot_map_region函数对于指定的对应空间进行映射来达到我们需要的效果。
```
size = ROUNDUP(pa+size, PGSIZE);
	pa = ROUNDDOWN(pa, PGSIZE);
	size -= pa;
	if (base+size >= MMIOLIM) panic("not enough memory");
	boot_map_region(kern_pgdir, base, size, pa, PTE_PCD|PTE_PWT|PTE_W);
	base += size;
	return (void*) (base - size);
	panic("mmio_map_region not implemented");

```

exercise 2
———
```
Exercise 2. Read boot_aps() and mp_main() in kern/init.c, and the assembly code in kern/mpentry.S. Make sure you understand the control flow transfer during the bootstrap of APs. Then modify your implementation of page_init() in kern/pmap.c to avoid adding the page at MPENTRY_PADDR to the free list, so that we can safely copy and run AP bootstrap code at that physical address. Your code should pass the updated check_page_free_list() test (but might fail the updated check_kern_pgdir() test, which we will fix soon).
```
###exercise2解答
这个exercise是为了解决启动APs的问题，所以这一部分内存我们不能使用，所以在page_init中，我们在之中加入对于mpentry页的判断即可。
```
	page_free_list = NULL;
	for (i = 0; i < npages; i++) {
		if (i == 0 || (i >= low && i < top) || (i == MPENTRY_PADDR / PGSIZE)){
			pages[i].pp_ref = 1;
			pages[i].pp_link = NULL;
			continue;
		}
		pages[i].pp_ref = 0;
	//	cprintf("%d\n", i);
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
```

Question 
这里通过参看
——-
```
Compare kern/mpentry.S side by side with boot/boot.S. Bearing in mind that kern/mpentry.S is compiled and linked to run above KERNBASE just like everything else in the kernel, what is the purpose of macro MPBOOTPHYS? Why is it necessary in kern/mpentry.S but not in boot/boot.S? In other words, what could go wrong if it were omitted in kern/mpentry.S? 
Hint: recall the differences between the link address and the load address that we have discussed in Lab 1.
```
因为这里已经是高位地址，而我们需要链接的是对应低地址的代码，如果不使用MPBOOTPHYS宏将高地址转换为低地址的话，程序会引起page fault
exercise 3
———
```
Modify mem_init_mp() (in kern/pmap.c) to map per-CPU stacks starting at KSTACKTOP, as shown in inc/memlayout.h. The size of each stack is KSTKSIZE bytes plus KSTKGAP bytes of unmapped guard pages. Your code should pass the new check in check_kern_pgdir().
```
###exercise3解答
查询对应的memlayout.h，每个cpu的内核栈依次在KSTACKTOP以下排列，使用以前的boot_map_region完成对应内核栈的映射。
```
	int i;
	for (i = 0; i < NCPU; i++) {
		boot_map_region(kern_pgdir,  KSTACKTOP - i * (KSTKSIZE + KSTKGAP) - KSTKSIZE, KSTKSIZE, PADDR(percpu_kstacks[i]), PTE_W);
	}
```


exercise 4
———
```
The code in trap_init_percpu() (kern/trap.c) initializes the TSS and TSS descriptor for the BSP. It worked in Lab 3, but is incorrect when running on other CPUs. Change the code so that it can work on all CPUs. (Note: your new code should not use the global ts variable any more.)
```
###exercise4解答
将对应的ts结构换成对应的thiscpu的ts结构即可
```
	int i = thiscpu->cpu_id;
	thiscpu->cpu_ts.ts_esp0 = (int)percpu_kstacks[i] + KSTKSIZE;
	thiscpu->cpu_ts.ts_ss0 = GD_KD;
	gdt[(GD_TSS0 >> 3) + i] = SEG16(STS_T32A, (uint32_t) (&(thiscpu->cpu_ts)), sizeof(struct Taskstate), 0);
	gdt[(GD_TSS0 >> 3) + i].sd_s = 0;
	ltr(GD_TSS0 + 8 * i);
	lidt(&idt_pd);
```
exercise 5
———
```
Apply the big kernel lock as described above, by calling lock_kernel() and unlock_kernel() at the proper locations.
```
###exercise5解答
为了防止多个进程不会同时进入内核模式，所以我们使用了锁来保护，按照注释在对应的4个地方acquire或者release锁即可。
Question
——-
```
It seems that using the big kernel lock guarantees that only one CPU can run the kernel code at a time. Why do we still need separate kernel stacks for each CPU? Describe a scenario in which using a shared kernel stack will go wrong, even with the protection of the big kernel lock.
```
还是不能共享内核栈，因为内核栈中存储着需要恢复的环境，如果多个内核共用的话，内核栈里存储的需要恢复的环境在恢复时会产生混乱。
exercise 6
———
```
Implement round-robin scheduling in sched_yield() as described above. Don't forget to modify syscall() to dispatch sys_yield().

Modify kern/init.c to create three (or more!) environments that all run the program user/yield.c. You should see the environments switch back and forth between each other five times before terminating, like this:

...
Hello, I am environment 00001000.
Hello, I am environment 00001001.
Hello, I am environment 00001002.
Back in environment 00001000, iteration 0.
Back in environment 00001001, iteration 0.
Back in environment 00001002, iteration 0.
Back in environment 00001000, iteration 1.
Back in environment 00001001, iteration 1.
Back in environment 00001002, iteration 1.
...
After the yield programs exit, there will be no runnable environment in the system, the scheduler should invoke the JOS kernel monitor. If any of this does not happen, then fix your code before proceeding.
```
###exercise6解答
这里需要我们实现一个round-robin调度算法，我们在每次当前进程之后选择第一个可以RUNNABLE的进程进行下一次执行。
```
int now, i;
	if (curenv) {
		now = (ENVX(curenv->env_id) + 1)% NENV;
	} else {
		now = 0;
	}
	for (i = 0; i < NENV; i++, now = (now + 1) % NENV) {
		if (now == 1) cprintf("%d  %d\n",ENV_RUNNABLE,envs[now].env_status);
		if (envs[now].env_status == ENV_RUNNABLE) {
			env_run(&envs[now]);
		}
	}
	if (curenv && curenv->env_status == ENV_RUNNING) {
       env_run(curenv);
	}

```
为了检测程序的正确性，在init.c中我们添加了3行对应的测试程序来完成之上的测试
```
	ENV_CREATE(user_yield, ENV_TYPE_USER);
	ENV_CREATE(user_yield, ENV_TYPE_USER);
	ENV_CREATE(user_yield, ENV_TYPE_USER);
```
这里我的调试遇上了很大的困难，最开始发现的错误是忘了按照提示所提示的为对应的SYS_yield系统调用匹配，使得我这里一直出现了相应的系统保护中断，这里查了我至少30分钟。<br \>
然后我发现我测试出现了这样的情况
```
[00000000] new env 00001000
[00000000] new env 00001001
[00000000] new env 00001002
Hello, I am environment 00001000.
Hello, I am environment 00001000.
Hello, I am environment 00001000.
Back in environment 00001000, iteration 0.
Back in environment 00001000, iteration 0.
Back in environment 00001000, iteration 0.
Back in environment 00001000, iteration 1.
Back in environment 00001000, iteration 1.
Back in environment 00001000, iteration 1.
Back in environment 00001000, iteration 2.
Back in environment 00001000, iteration 2.
Back in environment 00001000, iteration 2.
Back in environment 00001000, iteration 3.
Back in environment 00001000, iteration 3.
Back in environment 00001000, iteration 3.
Back in environment 00001000, iteration 4.
All done in environment 00001000.
[00001000] exiting gracefully
[00001000] free env 00001000
Back in environment 00001000, iteration 4.
All done in environment 00001000.
[00001001] exiting gracefully
[00001001] free env 00001001
Back in environment 00001000, iteration 4.
All done in environment 00001000.
[00001002] exiting gracefully
[00001002] free env 00001002
```
他一直在1000环境下，这里我一开始非常不理解，我查看了我的调度程序很久并没有发现错误，最后非常伤心的是原因是因为在syscall中的getenvid我没有return他的返回值，导致他的返回值一直是0，所以才出现了这样的错误，这个错误让我调了1个多小时。
Question
———

```
In your implementation of env_run() you should have called lcr3(). Before and after the call to lcr3(), your code makes references (at least it should) to the variable e, the argument to env_run. Upon loading the %cr3 register, the addressing context used by the MMU is instantly changed. But a virtual address (namely e) has meaning relative to a given address context--the address context specifies the physical address to which the virtual address maps. Why can the pointer e be dereferenced both before and after the addressing switch?

```

```
Whenever the kernel switches from one environment to another, it must ensure the old environment's registers are saved so they can be restored properly later. Why? Where does this happen?

```
exercise 7
———
```
Implement the system calls described above in kern/syscall.c. You will need to use various functions in kern/pmap.c and kern/env.c, particularly envid2env(). For now, whenever you call envid2env(), pass 1 in the checkperm parameter. Be sure you check for any invalid system call arguments, returning -E_INVAL in that case. Test your JOS kernel with user/dumbfork and make sure it works before proceeding.
```
###exercise7解答
这里在对应的syscall按照注释添加代码即可 <br />
sys_exofork:
```
struct Env *e;
	int r = env_alloc(&e, curenv->env_id);
	if (r < 0) return r;
	e->env_status = ENV_NOT_RUNNABLE;
	e->env_tf = curenv->env_tf;
	e->env_tf.tf_regs.reg_eax = 0;
	cprintf("e pgdir: %x\n", e, e->env_pgdir);
	return e->env_id;

```
这里是创造一个新的子进程，我们只需要env_alloc分配一个新的进程，并把父进程的对一个tf赋给子进程即可，需要注意的是这里的返回值，需要将子进程eax寄存器赋值为0，而对应的return也返回为子进程id。
sys_env_set_status:
```
	if (status != ENV_NOT_RUNNABLE && status != ENV_RUNNABLE) return -E_INVAL;
	struct Env *e;
	int r = envid2env(envid, &e, 1);
	if (r < 0) return -E_BAD_ENV;
	e->env_status = status;

```
这个调用是为了将对应的进程的状态改变，按照注释判断对应状态是否为符合的状态，之后进行改变。 <br />
sys_page_alloc:
```
	struct Env* e;
	int r = envid2env(envid , &e , 1);
	if (r < 0) 
		return -E_BAD_ENV;
	if ((uint32_t)va >= UTOP || ROUNDUP(va, PGSIZE) != va) 
		return -E_INVAL;
	if (!((perm & PTE_U) && (perm & PTE_P) && (perm & (~PTE_SYSCALL))==0))
		return -E_INVAL;
	struct PageInfo *i = page_alloc(ALLOC_ZERO);
	if (i == NULL) 
		return -E_NO_MEM;
	if (page_insert(e->env_pgdir, i, va, perm) < 0) {
		page_free(i);
		return -E_NO_MEM;
	}
	return 0;
```
这里是为进程分配页，将对应的权限和它需要判断的东西判断杰克，之后将分配一个页和对应虚拟地址进行映射即可。 <br />

sys_page_map:
```
	struct Env *e1, *e2;
	int r;
	r = envid2env(dstenvid , &e2 , 1);
	if (r < 0)
		return -E_BAD_ENV;
	r = envid2env(srcenvid, &e1, 1);
	if (r < 0) 
		return -E_BAD_ENV;
	if (( uint32_t)srcva >= UTOP || ROUNDUP(srcva , PGSIZE) != srcva) 
		return -E_INVAL;
	if (( uint32_t)dstva >= UTOP || ROUNDUP(dstva , PGSIZE) != dstva) 
		return -E_INVAL;
	if (!((perm & PTE_U) && (perm & PTE_P) && (perm & (~PTE_SYSCALL))==0))
		return -E_INVAL;
	struct PageInfo *i;
	pte_t *pte;
	i = page_lookup(e1->env_pgdir, srcva, &pte);
	if (!i) return -E_INVAL;

	if ((perm & PTE_W) && (((*pte) & PTE_W) == 0))
		return -E_INVAL;
	if (page_insert(e2->env_pgdir, i, dstva, perm) < 0) 
		return -E_NO_MEM;

	return 0;

```
这里是将2个进程的对应的地址空间进行映射，按照注释进行判断和映射做下去就可以了。 <br />
sys_page_unmap:
```

	struct Env *e;
	int r = envid2env(envid, &e, 1);
	if (r < 0) 
		return -E_BAD_ENV;
	if ((uint32_t)va >= UTOP || ROUNDUP(va, PGSIZE) != va) 
		return -E_INVAL;
	page_remove(e->env_pgdir, va);
	return 0;
```
这里是取消映射，需要将对应页remove掉。  <br />
这里的测试我一直出现了
```
SMP: CPU 0 found 1 CPU(s)
enabled interrupts: 1 2
[00000000] new env 00001000
[00000000] new env 00001001
[00000000] new env 00001002
[00000000] user panic in <unknown> at lib/fork.c:82: fork not implemented
Welcome to the JOS kernel monitor!
```
这样的错误，我这里非常的疑惑，我并没有对相应的fork函数有任何的改动，认为是之前的程序（像trap.c这样的)自己错了，在这里卡了至少2个小时，检查了很久，通过不断输出调试，最后发现自己是粗心在syscall中没有将一个调用的case加进去，导致了这个错误。操作系统的调试主要是涉及的方面太多，如果一个变量打错的话，他可能会在另外的一个地方出错，这考验了你对操作系统整体的了解，否则你会非常难以发觉错误的地方，关键是在写程序时要边写边check，不然之后很难发现是哪里错误了，这对我以后对于大工程的编写很有启发意义。

Part B: Copy-on-Write Fork
===
这里part主要是针对fork函数，在dumb fork测试程序中，我们已经实现了实现了一个基本的fork函数，而copy-on-write技术可以使得我们更加有效的fork，这个技术的优势是在复制一个对象的时候并不是真正的把原先的对象复制到内存的另外一个位置上，而是在新对象的内存映射表中设置一个指针，指向源对象的位置，并把那块内存的Copy-On-Write位设置为1.在对这个对象执行读操作的时候，内存数据没有变动，直接执行就可以。在写的时候，才真正将原始对象复制一份到新的地址，修改新对象的内存映射表到这个新的位置。这样能高效的进行fork，只对很少的一部分内存进行操作。而我们之后的工作就是实现这样的一个技术。
exercise 8
———
```
```
###exercise3解答
exercise 9
———
```
```
###exercise3解答
exercise 10
———
```
```
###exercise3解答
exercise 11
———
```
```
###exercise3解答
exercise 12
———
```
```
###exercise3解答
exercise 13
———
```
```
###exercise3解答
exercise 14
———
```
```
###exercise3解答
exercise 15
———
```
```
###exercise3解答


 

卡了2次地方，调试了3个小时，
在fork.c中的pgfault一个是给权限给错了，给成了PTE_COW
在duppage中的uvpt写成了uvpd
