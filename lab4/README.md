JOS Lab4 Report
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
----------------------------
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
----------------------------
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
----------------------------
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
----------------------------
```
Apply the big kernel lock as described above, by calling lock_kernel() and unlock_kernel() at the proper locations.
```
###exercise5解答
为了防止多个进程不会同时进入内核模式，所以我们使用了锁来保护，按照注释在对应的4个地方acquire或者release锁即可。
Question
----------------------------
```
It seems that using the big kernel lock guarantees that only one CPU can run the kernel code at a time. Why do we still need separate kernel stacks for each CPU? Describe a scenario in which using a shared kernel stack will go wrong, even with the protection of the big kernel lock.
```
还是不能共享内核栈，因为内核栈中存储着需要恢复的环境，如果多个内核共用的话，内核栈里存储的需要恢复的环境在恢复时会产生混乱。
exercise 6
----------------------------
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
----------------------------

```
In your implementation of env_run() you should have called lcr3(). Before and after the call to lcr3(), your code makes references (at least it should) to the variable e, the argument to env_run. Upon loading the %cr3 register, the addressing context used by the MMU is instantly changed. But a virtual address (namely e) has meaning relative to a given address context--the address context specifies the physical address to which the virtual address maps. Why can the pointer e be dereferenced both before and after the addressing switch?

```
由于我们在每个Env做了对于已物理地址的映射，所以无论切换到哪个进程我们的虚拟地址到物理地址的映射都不会出错。

```
Whenever the kernel switches from one environment to another, it must ensure the old environment's registers are saved so they can be restored properly later. Why? Where does this happen?

```
因为之后cpu要进行环境的恢复，如果不保存好的话，之后对于该进程的恢复会产生问题。
exercise 7
----------------------------
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
这里是将2个进程的对应的地址空间进行映射，将 srcenvid 进程地址空间中的线性地址 srcva 的页映射到 dstenvid 进程地址空间中的dstva 地址处,并设置页属性为 perm。
此处的操作并非数据拷贝而是页表操作,即两进程共享同一个页的地址，即实现之后COPY-ON-Write技术的只读内存共享的操作。
<br />
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
-----
```
Implement the sys_env_set_pgfault_upcall system call. Be sure to enable permission checking when looking up the environment ID of the target environment, since this is a "dangerous" system call.
```
###exercise8解答
```
	struct Env *e; 
	int r = envid2env(envid, &e, 1);
	if (r < 0) return r; //-E_BAD_ENV;   
	e->env_pgfault_upcall = func;
	cprintf("sys %d\n", e->env_tf.tf_err);
	return 0;
```
在这里的按照注释进行对于进程的page_upcall的处理程序进行编写即可，这里的作用是用户进程调用系统调用告知系统我的page fault的处理程序。
exercise 9
----------------------------
```
Implement the code in page_fault_handler in kern/trap.c required to dispatch page faults to the user-mode handler. Be sure to take appropriate precautions when writing into the exception stack. (What happens if the user environment runs out of space on the exception stack?)
```
###exercise9解答
```
 if (curenv->env_pgfault_upcall) {
//		cprintf("!!entry\n");
		struct UTrapframe *uetf;
		uint32_t add;
		if (tf->tf_esp >= UXSTACKTOP - PGSIZE && tf->tf_esp < UXSTACKTOP) {
			add = tf->tf_esp - sizeof(struct UTrapframe) - 4;
		} else {
			add = UXSTACKTOP - sizeof(struct UTrapframe);
		}
		uetf = (struct UTrapframe *) add;
		user_mem_assert(curenv, (void*)add, sizeof(struct UTrapframe), PTE_U | PTE_W);
		uetf->utf_eflags = tf->tf_eflags;
		uetf->utf_eip = tf->tf_eip;
		uetf->utf_err = tf->tf_err;
//		cprintf("%d\n", uetf->utf_err);
		uetf->utf_fault_va = fault_va;
		uetf->utf_regs = tf->tf_regs;
		uetf->utf_esp = tf->tf_esp;
		curenv->env_tf.tf_eip = (uint32_t)curenv->env_pgfault_upcall;
//		cprintf("~~");
		curenv->env_tf.tf_esp = add;
//		cprintf("!!");
		env_run(curenv);

	}

```
这里是如果是user差生的page fault的话我们切换到的栈为UTrapframe，而这么做更高效的原因是由于因为是进程内的pgfault，所以进程中的很多环境都不会变化，所以做到了更为高效。这里需要注意的是如果是递归调用的话，它需要多空出一个32 bit的空间以来实现在excepion stack中的递归调用。
exercise 10
----------------------------
```
 Implement the _pgfault_upcall routine in lib/pfentry.S. The interesting part is returning to the original point in the user code that caused the page fault. You'll return directly there, without going back through the kernel. The hard part is simultaneously switching stacks and re-loading the EIP.
```
###exercise10解答
```
	movl 0x30(%esp), %eax
	subl $0x4, %eax
	movl %eax, 0x30(%esp)
	movl 0x28(%esp), %ebx
	movl %ebx, (%eax)

	// Restore the trap-time registers.  After you do this, you
	// can no longer modify any general-purpose registers.
	// LAB 4: Your code here.
	addl $0x8 , %esp
	popal

	// Restore eflags from the stack.  After you do this, you can
	// no longer use arithmetic operations or anything else that
	// modifies eflags.
	// LAB 4: Your code here.
	addl $0x4, %esp
	popfl

	// Switch back to the adjusted trap-time stack.
	// LAB 4: Your code here.
	popl %esp

	// Return to re-execute the instruction that faulted.
	// LAB 4: Your code here.
	ret
```
这里非常感谢张弛的报告，他的报告非常详细的介绍了这段转换的每一步的作用而这样做的原因。在这个程序处理之前我们的栈里所有的是reserver 32 bit, 之后的trap结构的esp，eflags，Pushregs的结构，errcode，fault_va，所以我们出栈则是先加8跳过errcode，fault_va,之后是Pushregs的出栈，按照trapentrye.S同样处理，eflags类似处理，最后就到了esp和reserver 32 bit了，这里使用ret而对应的我们需要做一些处理，因为我们的返回地址是之前指向的esp往上4位，所以在之前我们对对应的esp做减4的操作，esp之后就会到该到的位置，而返回的地址为reserved 32 bit处，所以我们要调用为返回地址，在哪里找返回地址呢？在当前tf结构的eip中存储了之前的那一条语句地址，所以我们只需要将tf结构的eip值赋值给他即可。ret这条语句过后就能完美解决exception stack递归的问题了。

exercise 11
----------------------------
```
Finish set_pgfault_handler() in lib/pgfault.c.
```
###exercise11解答
```
	int r;
	if (_pgfault_handler == 0) {
		// First time through!
		// LAB 4: Your code here.
		if ((r = sys_page_alloc(0, (void*) (UXSTACKTOP - PGSIZE), PTE_U | PTE_P | PTE_W)) < 0)
			panic("set_pgfault_handler %d", r);
		sys_env_set_pgfault_upcall(0, _pgfault_upcall);
		

	}

	// Save handler pointer for assembly to call.
	_pgfault_handler = handler;
```
这里的代码需要将对应的user的pgfault的处理函数进行注册，并且分配对应的exception stack的空间。按照注释来十分容易实现，只是要注意的是，栈空间是从高到低，所以在page分配的时候应该分配UXSTACKTOP - PGSIZE的地方以上的page给他，这个我一开始并没有注意。 <br />
Make sure you understand why user/faultalloc and user/faultallocbad behave differently.这里lab问了这么一个问题，以我的理解为cprintf在调用cputs之前跳到了相应的地址导致page fault的引发，导致了之后user_mem检查的通过，而cputs由于没有做对应的Page fault所以检查对应地址的时候会发生失败。
用户进程


exercise 12
----------------------------
```
 Implement fork, duppage and pgfault in lib/fork.c.

Test your code with the forktree program. It should produce the following messages, with interspersed 'new env', 'free env', and 'exiting gracefully' messages. The messages may not appear in this order, and the environment IDs may be different.

	1000: I am ''
	1001: I am '0'
	2000: I am '00'
	2001: I am '000'
	1002: I am '1'
	3000: I am '11'
	3001: I am '10'
	4000: I am '100'
	1003: I am '01'
	5000: I am '010'
	4001: I am '011'
	2002: I am '110'
	1004: I am '001'
	1005: I am '111'
	1006: I am '101'
```
这里需要你实现一个完整的运用COW技术的fork函数，有以下的3个函数需要完成。<br />

pgfault:
```
void *addr = (void *) utf->utf_fault_va;
	uint32_t err = utf->utf_err;
	int r;
	cprintf("err %d %d\n", err, err & FEC_WR);
				cprintf("%d %d %d\n",addr, ((uint32_t)addr) / PGSIZE, uvpt[((uint32_t)addr) / PGSIZE] & PTE_COW);//uvpd[PDX(addr)] & PTE_P);
				cprintf("%d %d\n",((uint32_t)977917*PGSIZE) / PGSIZE, uvpt[977917] & PTE_COW);//uvpd[PDX(addr)] & PTE_P);
	if (!(err & FEC_WR)) {
		panic("FEC_WR fault access check failed");
	}
	if ((uvpd[PDX(addr)] & PTE_P) == 0 || (uvpt[((uint32_t)addr) / PGSIZE] & PTE_COW) == 0)
	{
		panic("fault access check failed");
	}

	r = sys_page_alloc(0, (void*)PFTEMP, PTE_P | PTE_W | PTE_U);
	if (r < 0) panic("page alloc failed");
	addr = ROUNDDOWN (addr, PGSIZE);
	memcpy(PFTEMP, addr, PGSIZE);
	r =	sys_page_map(0, (void*) PFTEMP, 0, addr, PTE_P | PTE_W | PTE_U);
	if (r < 0) panic("sys_page_map failed");

```
这里需要完成的是对相应的权限的检查加上之后
<br />
duppage:
```
	if (pn * PGSIZE == UXSTACKTOP - PGSIZE) return 0;

int r;

	// LAB 4: Your code here.
	if ((uvpt[pn] & PTE_W) || (uvpt[pn] & PTE_COW)) {
		r = sys_page_map(0, (void*) (pn * PGSIZE), envid, (void*) (pn * PGSIZE), PTE_U | PTE_P | PTE_COW);
		if (r < 0) panic("map failed");
		r = sys_page_map(0, (void*) (pn * PGSIZE), 0, (void*) (pn * PGSIZE), PTE_U | PTE_P | PTE_COW);
		if (r < 0) panic("map failed");
	}
	else {
		r = sys_page_map(0, (void*) (pn * PGSIZE), envid, (void*) (pn * PGSIZE), PTE_U | PTE_P);
		if (r < 0) panic("map failed");
	}
//	panic("duppage not implemented");
	return 0;
```
这部分就是实现页表的复制,需要区分读和写即可。如果是读,则需要更改子进程的同时自己页表的标志位也需要更改。
<br />
fork:
```
set_pgfault_handler(pgfault);
	int envid = sys_exofork();
	if (envid < 0) {
		panic("sys_exofork: %e", envid);
	}
	int r;
	if (envid == 0) {
		cprintf("child\n");
		thisenv = &envs[ENVX(sys_getenvid())];
		return 0;
	} else {
		cprintf("father\n");
		uint32_t i;
		for (i = 0; i != UTOP; i += PGSIZE)
			if ((uvpd[PDX(i)] & PTE_P) && (uvpt[i / PGSIZE] & PTE_P) && (uvpt[i / PGSIZE] & PTE_U)) {
				cprintf("%d\n", uvpd[PDX(i)] & PTE_P);
	 			duppage(envid, i / PGSIZE);
	 		}
		cprintf("father1\n");
	 	r = sys_page_alloc(envid, (void *)(UXSTACKTOP - PGSIZE), PTE_U |PTE_W | PTE_P);
	 	if (r < 0) 
			panic("sys_page_alloc: %e", r);
	 	extern void _pgfault_upcall(void);
	 	r = sys_env_set_pgfault_upcall(envid, _pgfault_upcall);
	 	if (r < 0) 
			panic("set pgfault upcall fail : %e", r);
	 	r = sys_env_set_status(envid, ENV_RUNNABLE);

	 	if (r < 0) 
			panic("set child process to ENV_RUNNABLE error : %e", r);
	 	return envid;
	}
	panic("fork not implemented");
```
set_pgfault_handler(handler)->sys_env_set_pgfault_upcall()->注册用户页错误处理函数->如果发生页错误,在trap.c中的page_fault_handler()进行处理->_pgfault_upcall()调用页错误处理函数并返回用户进程
卡了2次地方，调试了3个小时，
在fork.c中的pgfault一个是给权限给错了，给成了PTE_COW
在duppage中的uvpt写成了uvpd
###exercise12解答
exercise 13
----------------------------
```
 Modify kern/trapentry.S and kern/trap.c to initialize the appropriate entries in the IDT and provide handlers for IRQs 0 through 15. Then modify the code in env_alloc() in kern/env.c to ensure that user environments are always run with interrupts enabled.

The processor never pushes an error code or checks the Descriptor Privilege Level (DPL) of the IDT entry when invoking a hardware interrupt handler. You might want to re-read section 9.2 of the 80386 Reference Manual, or section 5.8 of the IA-32 Intel Architecture Software Developer's Manual, Volume 3, at this time.

After doing this exercise, if you run your kernel with any test program that runs for a non-trivial length of time (e.g., spin), you should see the kernel print trap frames for hardware interrupts. While interrupts are now enabled in the processor, JOS isn't yet handling them, so you should see it misattribute each interrupt to the currently running user environment and destroy it. Eventually it should run out of environments to destroy and drop into the monitor.
```
###exercise13解答
exercise 14
----------------------------
```
Modify the kernel's trap_dispatch() function so that it calls sched_yield() to find and run a different environment whenever a clock interrupt takes place.

You should now be able to get the user/spin test to work: the parent environment should fork off the child, sys_yield() to it a couple times but in each case regain control of the CPU after one time slice, and finally kill the child environment and terminate gracefully.
```
###exercise14解答
exercise 15
----------------------------
```
Implement sys_ipc_recv and sys_ipc_try_send in kern/syscall.c. Read the comments on both before implementing them, since they have to work together. When you call envid2env in these routines, you should set the checkperm flag to 0, meaning that any environment is allowed to send IPC messages to any other environment, and the kernel does no special permission checking other than verifying that the target envid is valid.

Then implement the ipc_recv and ipc_send functions in lib/ipc.c.

Use the user/pingpong and user/primes functions to test your IPC mechanism. You might find it interesting to read user/primes.c to see all the forking and IPC going on behind the scenes.
```
###exercise15解答


 


