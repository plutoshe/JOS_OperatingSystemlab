JOS Lab5 Report
====================================
Result
----------------------------
```
internal FS tests: OK (2.2s) 
  fs i/o: OK 
  check_super: OK 
spawn via spawnhello: OK (1.3s) 
PTE_SHARE [testpteshare]: OK (1.5s) 
PTE_SHARE [testfdsharing]: OK (1.9s) 
start the shell [icode]: OK (1.3s) 
testshell: OK (2.9s) 
primespipe: OK (15.3s) 
Score: 75/75

```
这个lab虽然看起来很少，但一是因为有许多代码需要阅读，二是是因为综合了之前的所有的内容，之前的lab没有发现的错误会累积到这个lab来调试，所以这个lab我做起来并不容易。由于我这个lab做的比较晚，文件系统的相关知识已经有所了解，而且也阅读过xv6的代码，所以对于这个部分的代码的阅读没有遇到太大的困难，只是有时候会看不懂为什么这么做。


File system preliminaries
======================================
这个部分主要关于文件系统的磁盘读入问题
exercise 1
----------------------------
```
Exercise 1. i386_init identifies the file system environment by passing the type ENV_TYPE_FS to your environment creation function, env_create. Modify env_create in env.c, so that it gives the file system environment I/O privilege, but never gives that privilege to any other environment.

Make sure you can start the file environment without causing a General Protection fault. You should pass the "fs i/o" test in make grade.
```
###exercise 1解答
这个是给予对应进程以权限，所以给予相应的权限即可。
```
	if (e->env_type == ENV_TYPE_FS) {
		e->env_tf.tf_eflags |= FL_IOPL_3; 
	}
```
Question 
---------------
```
Do you have to do anything else to ensure that this I/O privilege setting is saved and restored properly when you subsequently switch from one environment to another? Why?
```
不需要，在进程切换时，栈会保存你对应的状态的，所以你不需要保存。
exercise 2
----------------------------
```
Exercise 2. Implement the bc_pgfault functions in fs/bc.c. bc_pgfault is a page fault handler, just like the one your wrote in the previous lab for copy-on-write fork, except that its job is to load pages in from the disk in response to a page fault. When writing this, keep in mind that (1) addr may not be aligned to a block boundary and (2) ide_read operates in sectors, not blocks.

Use make grade to test your code. Your code should pass "check_super".
```
###exercise2解答
```
	addr = ROUNDDOWN(addr, PGSIZE);
	r = sys_page_alloc(0, addr, PTE_W | PTE_U | PTE_P);
	if (r < 0) panic("can not alloc a page for bc_pgfault %e\n", r);
	r = ide_read(blockno * BLKSECTS , addr , BLKSECTS);
	if (r < 0) panic("bc_pgfault ide_read error %e\n", r);
```
按照注释，之前先分配一页，对于对应的磁盘读入对应内容即可。会读入BLKSECTS个SECTSIZE的内容，因为BLKSECTS = BLKSIZE / SECTSIZE，而BLKSIZE在定义中为PGSIZE，所以正好读一个页的内容。


Spawning Processes
===

exercise 3
----------------------------
```
Exercise 3. spawn relies on the new syscall sys_env_set_trapframe to initialize the state of the newly created environment. Implement sys_env_set_trapframe. Test your code by running the user/spawnhello program from kern/init.c, which will attempt to spawn /hello from the file system.

Use make grade to test your code.
```
###exercise3解答
在这个地方我非常郁闷，一直产生了pagefault，一开始以为我之前lab有错误，所以查看了很久，之后发现我的程序根本没有进入到测试程序，我非常困惑这是为什么，不知道为什么会导致这样，之后通过git diff查看与之前的代码的区别，发现自己之前由于merge的冲突，在init.c中把下列代码给注释掉了
```
#if defined(TEST)
	// Don't touch -- used by grading script!
	ENV_CREATE(TEST, ENV_TYPE_USER);
#else
	ENV_CREATE(user_spawnhello, ENV_TYPE_USER);
#endif
```
导致了之后我的测试一直开始不了，估计之前的exercise不需要test程序，所以我才会通过之前的exercise。<br/>
这个错误非常恶心，导致我调了很久很久。

Challenge! 
-----------
```
Challenge! Implement Unix-style exec.
```
###Challenge解答
通过查看他的spawn函数的实现，发现他是使用了fork函数，将需要执行的内容和之前进程的栈内容赋予到了新的child中，而exec是直接从该进程运行我们的代码而不再运，由于条件的限制，我想到的是直接通过对该进程的内容进行修改，因为我们对于进程的内容不能直接修改会有权限和对于未知的错误，所以我们需要陷入到内核去处理我们的进程的内容，，而新的栈的内容也需要先放置在新的临时内存中。因此需要更改一下 init_stack 函数中,即设置一下映射的地址即可

```
	uint32_t now_addr = DTEMP;
	ph = (struct Proghdr *) (elf_buf + elf->e_phoff);
	for (i = 0; i < elf->e_phnum; i++, ph++) {
		if (ph->p_type != ELF_PROG_LOAD)
			continue ;
		perm = PTE_P | PTE_U;
		if (ph->p_flags & ELF_PROG_FLAG_WRITE)
			perm |= PTE_W;
		if ((r = map_segment(0, PGOFF(ph->p_va) + now_addr, ph->p_memsz, fd, ph->p_filesz, ph->p_offset, perm)) < 0)
			goto error;
		now_addr += ROUNDUP(ph->p_memsz + PGOFF(ph->p_va), PGSIZE);
	}
	close(fd);
	fd = -1;
	if ((r = init_stack(0, argv, &tf_esp, now_addr)) < 0)
		return r;
	if (sys_exec(elf->e_entry , tf_esp , (void *)(elf_buf + elf->e_phoff), elf->e_phnum) < 0)
		goto error;
	return 0;
```
在syscall中实现相应的load即可。实验结果，在spawn和exec后cprint("wawawa")，按照预期之后spawn会输出，结果也如预料一样。
```
SMP: CPU 0 found 1 CPU(s)
enabled interrupts: 1 2 4
FS is running
FS can do I/O
Device 1 presence: 1
superblock is good
i am parent environment 00001001
wawawa
fork start
hello, world
i am environment 00001002
```
而exec则是：
```
SMP: CPU 0 found 1 CPU(s)
enabled interrupts: 1 2 4
FS is running
FS can do I/O
Device 1 presence: 1
superblock is good
i am parent environment 00001001
fork start
hello, world
i am environment 00001001
```

exercise 4
----------------------------
```
Exercise 4. Change duppage in lib/fork.c to follow the new convention. If the page table entry has the PTE_SHARE bit set, just copy the mapping directly. (You should use PTE_SYSCALL, not 0xfff, to mask out the relevant bits from the page table entry. 0xfff picks up the accessed and dirty bits as well.)

Likewise, implement copy_shared_pages in lib/spawn.c. It should loop through all page table entries in the current process (just like fork did), copying any page mappings that have the PTE_SHARE bit set into the child process.
```
###exercise4解答
因为进程之间对于 file descriptor 是共享的，所以在duppage函数中加入对于page table权限的判断
```
	if (uvpt[pn] & PTE_SHARE) {
		r = sys_page_map (0, (void*) (pn * PGSIZE), envid, (void*) (pn * PGSIZE), uvpt[pn] & PTE_SYSCALL);
		if (r < 0) panic("duppage sys_page_map error : %e\n", r);
	} 
	else if ((uvpt[pn] & PTE_W) || (uvpt[pn] & PTE_COW)) {
		r = sys_page_map(0, (void*) (pn * PGSIZE), envid, (void*) (pn * PGSIZE), PTE_U | PTE_P | PTE_COW);
		if (r < 0) panic("map failed");
		r = sys_page_map(0, (void*) (pn * PGSIZE), 0, (void*) (pn * PGSIZE), PTE_U | PTE_P | PTE_COW);
		if (r < 0) panic("map failed");
	}
	else {
		r = sys_page_map(0, (void*) (pn * PGSIZE), envid, (void*) (pn * PGSIZE), PTE_U | PTE_P);
		if (r < 0) panic("map failed");
	}
```
exercise 5
----------------------------
```
Exercise 5. In your kern/trap.c, call kbd_intr to handle trap IRQ_OFFSET+IRQ_KBD and serial_intr to handle trap IRQ_OFFSET+IRQ_SERIAL.
```
###exercise5解答
这一部分在trap.c中直接加入对于这两个中断的判断即可。
```
	if (tf->tf_trapno == IRQ_OFFSET + IRQ_KBD) {
		kbd_intr();
		return;
	}
	if (tf->tf_trapno == IRQ_OFFSET + IRQ_SERIAL) {
		serial_intr();
		return;
	}
```

The Shell
===
Question
----------------------------
```
How long approximately did it take you to do this lab?
```
大概做了14个小时。因为之前说过的错误卡了很长的时间，challenge也想了很久应该如何做。
Question
----------------------------
```
We simplified the file system this year with the goal of making more time for the final project. Do you feel like you gained a basic understanding of the file I/O in JOS? Feel free to suggest things we could improve.
```
只读代码和注释的话感觉虽然可以对于文件系统还是有了一个大致的了解，但是在一些具体细节上可能不是特别清楚，毕竟只是一扫而过的话，感觉很多东西综合起来还是理解不全，如果在内容中加入图片会更好一点，比如block分布图。

 


