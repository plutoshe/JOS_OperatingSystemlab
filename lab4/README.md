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



SMP: CPU 0 found 1 CPU(s)
enabled interrupts: 1 2
[00000000] new env 00001000
[00000000] new env 00001001
[00000000] new env 00001002
[00000000] user panic in <unknown> at lib/fork.c:82: fork not implemented
Welcome to the JOS kernel monitor!

把user_perms那句删了，带来了权限问题

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
没做相应的调用的返回值

 [00001000] user panic in <unknown> at user/dumbfork.c:78: sys_env_set_status: invalid parameter
没有写相应的系统调用的case


