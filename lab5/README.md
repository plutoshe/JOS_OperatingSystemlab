JOS Lab5 Report
====================================
Result
----------------------------
```


```


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

Question 
---------------
```
Do you have to do anything else to ensure that this I/O privilege setting is saved and restored properly when you subsequently switch from one environment to another? Why?
```

exercise 2
----------------------------
```
Exercise 2. Implement the bc_pgfault functions in fs/bc.c. bc_pgfault is a page fault handler, just like the one your wrote in the previous lab for copy-on-write fork, except that its job is to load pages in from the disk in response to a page fault. When writing this, keep in mind that (1) addr may not be aligned to a block boundary and (2) ide_read operates in sectors, not blocks.

Use make grade to test your code. Your code should pass "check_super".
```
###exercise2解答



Spawning Processes
===

exercise 3
----------------------------
```
Exercise 3. spawn relies on the new syscall sys_env_set_trapframe to initialize the state of the newly created environment. Implement sys_env_set_trapframe. Test your code by running the user/spawnhello program from kern/init.c, which will attempt to spawn /hello from the file system.

Use make grade to test your code.
```
###exercise3解答


Challenge! 
-----------
```
Challenge! Implement Unix-style exec.
```
###Challenge解答
```
```

exercise 4
----------------------------
```
Exercise 4. Change duppage in lib/fork.c to follow the new convention. If the page table entry has the PTE_SHARE bit set, just copy the mapping directly. (You should use PTE_SYSCALL, not 0xfff, to mask out the relevant bits from the page table entry. 0xfff picks up the accessed and dirty bits as well.)

Likewise, implement copy_shared_pages in lib/spawn.c. It should loop through all page table entries in the current process (just like fork did), copying any page mappings that have the PTE_SHARE bit set into the child process.
```
###exercise4解答

exercise 5
----------------------------
```
Exercise 5. In your kern/trap.c, call kbd_intr to handle trap IRQ_OFFSET+IRQ_KBD and serial_intr to handle trap IRQ_OFFSET+IRQ_SERIAL.
```
###exercise5解答


The Shell
===
Question
----------------------------
```
How long approximately did it take you to do this lab?
```
Question
----------------------------
```
We simplified the file system this year with the goal of making more time for the final project. Do you feel like you gained a basic understanding of the file I/O in JOS? Feel free to suggest things we could improve.
```

 


