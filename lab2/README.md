JOS Lab2 Report
====================================
Result
----------------------------
		running JOS: (1.1s) 
		Physical page allocator: OK 
		Page management: OK 
		Kernel page directory: OK 
		Page management 2: OK 
		Score: 70/70

Preparation
-----------------------------------
花了一下午学习了git相关的知识，从之前的lab1，转换了branch到了lab2，并merge了lab1分支，将这部分内容重新commit，push到了我现在个人的repository
Related Macro and Function
------------------------------------
PGSIZE表页大小
PTE_U, PTE_P, PTE_W代表有关权限
PADDR, KADDR分别是返回匹配虚拟地址的物理地址和返回匹配到物理地址的虚拟地址。
PDX(la), PTX(la), PGOFF(la)代表该线性地址的Page Directory Index, Page Table Index, Page Offset 
PTE_ADDR(pte)返回该page的入口
page2pa, pa2page, page2kva这三个函数，
其中page指的是struct PageInfo结构，这3个函数完成了这个结构对物理地址和逻辑地址的相互转换。
Part 1: Physical Page Management
=======
Exercise 1
-----------------------------------
```
Exercise 1. In the file kern/pmap.c, you must implement code for the following functions (probably in the order given).

boot_alloc()
mem_init() (only up to the call to check_page_free_list(1))
page_init()
page_alloc()
page_free()

check_page_free_list() and check_page_alloc() test your physical page allocator. You should boot JOS and see whether check_page_alloc() reports success. Fix your code so that it passes. You may find it helpful to add your own assert()s to verify that your assumptions are correct.
```
由于不像lab1那样有这样那样的提示，所以一开始从ics书开始复习，到操统书的这一部分都浏览了一遍，基本上有了一些了解，从张驰的报告中看到了有关的ppt，
接下来基本上是看注释加了解，边尝试边探索的前进。
需要注意的一点是程序在lab2中全是virtual address，要注意转换
###exercise1解答
mem_init():
```
	pages = (struct PageInfo*) boot_alloc(npages * sizeof(struct PageInfo));
```
boot_alloc():
```
	if (n > 0) {
		void *temp = nextfree;
		nextfree += n;
		nextfree = ROUNDUP(nextfree, PGSIZE);
		return temp;
	} else if (n == 0) {
		return (void*)nextfree;
	}
	return NULL;
```
page_init():
```
	size_t i;
	size_t low = IOPHYSMEM / PGSIZE;	
	size_t top = (PADDR(boot_alloc(0))) / PGSIZE;
	page_free_list = NULL;
	for (i = 0; i < npages; i++) {
		if (i == 0 || (i >= low && i < top)){
			pages[i].pp_ref = 1;
			pages[i].pp_link = NULL;
			continue;
		}
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
```
page_alloc()
```
	if (page_free_list != NULL) {
		if (alloc_flags & ALLOC_ZERO) {

			memset(page2kva(page_free_list), 0, PGSIZE);
		}
		struct PageInfo* temp = page_free_list;
		page_free_list = page_free_list->pp_link;
		return temp;
	}
	return NULL;
```
page_free():
```
	pp->pp_link = page_free_list;
	page_free_list = pp;
```
###exercise1中出现的错误
```
EAX=00000000 EBX=00010094 ECX=000003d4 EDX=000003d5
ESI=00010094 EDI=000f0118 EBP=f0113f88 ESP=f0113f60
EIP=f01010af EFL=00000006 [-----P-] CPL=0 II=0 A20=1 SMM=0 HLT=0
ES =0010 00000000 ffffffff 00cf9300 DPL=0 DS [-WA]
CS =0008 00000000 ffffffff 00cf9a00 DPL=0 CS32 [-R-]
SS =0010 00000000 ffffffff 00cf9300 DPL=0 DS [-WA]
DS =0010 00000000 ffffffff 00cf9300 DPL=0 DS [-WA]
FS =0010 00000000 ffffffff 00cf9300 DPL=0 DS [-WA]
GS =0010 00000000 ffffffff 00cf9300 DPL=0 DS [-WA]
LDT=0000 00000000 0000ffff 00008200 DPL=0 LDT
TR =0000 00000000 0000ffff 00008b00 DPL=0 TSS32-busy
GDT= 00007c4c 00000017
IDT= 00000000 000003ff
CR0=80010011 CR2=00000004 CR3=00114000 CR4=00000000
DR0=00000000 DR1=00000000 DR2=00000000 DR3=00000000 
DR6=ffff0ff0 DR7=00000400
EFER=0000000000000000
Triple fault. Halting for inspection via QEMU monitor.
```
在mem_init没住主要到首先要对于pages赋值，以为pages已经赋值过了，所以是空指针错误

 
```
kernel panic at kern/pmap.c:502: assertion failed: nfree_extmem > 0
```
没有注意到page_init()中的i++是加PGSIZE，所以对于low和top忘记除PGSIZE了，造成top没有赋值为对应的地址


```
kernel panic at kern/pmap.c:532: assertion failed: pp1 && pp1 != pp0
```
对于page_free_list在page_alloc函数中alloc之后没有到放弃这一个页面，赋值为下一个pp_link

```
kernel panic at kern/pmap.c:570: assertion failed: c[i] == 0
```
从c = page2kva这条语句发现这个问题，从而重新查看了一边pmap.h和mmu.h。弄清处了相关的宏和函数。
发现自己这时候并没有注意到程序中的地址都是逻辑地址。对物理地址，逻辑地址以及struct Pageinfo的这三个东西没有区分清楚，理解透彻，在清0的时候直接使用了page_next_list，然后就发现实际的并没有清0，应该使用page2kva，将对应的P
PageInfo结构转到应有的逻辑地址上。
将page_alloc（）中的memset(page_next_list, 0, PGSIZE)改变成
memset(page2kva(page_next_list), 0, PGSIZE)

Part 2: Virtual Memory
============

exercise 2
--------------------
```
Exercise 2. Look at chapters 5 and 6 of the Intel 80386 Reference Manual, if you haven't done so already. Read the sections about page translation and page-based protection closely (5.2 and 6.4). We recommend that you also skim the sections about segmentation; while JOS uses paging for virtual memory and protection, segment translation and segment-based protection cannot be disabled on the x86, so you will need a basic understanding of it.
```
因为之前复习过ics，另外读了张弛介绍老师的文稿，所以这部分算是比较清楚了

exercise 3
-----------------------
```
Exercise 3. While GDB can only access QEMU's memory by virtual address, it's often useful to be able to inspect physical memory while setting up virtual memory. Review the QEMU monitor commands from the lab tools guide, especially the xp command, which lets you inspect physical memory. To access the QEMU monitor, press Ctrl-a c in the terminal (the same binding returns to the serial console).

Use the xp command in the QEMU monitor and the x command in GDB to inspect memory at corresponding physical and virtual addresses and make sure you see the same data.

Our patched version of QEMU provides an info pg command that may also prove useful: it shows a compact but detailed representation of the current page tables, including all mapped memory ranges, permissions, and flags. Stock QEMU also provides an info mem command that shows an overview of which ranges of virtual memory are mapped and with what permissions.
```
我的qemu好像并没有这些个命令，所以直接略过了。
```
Question

Assuming that the following JOS kernel code is correct, what type should variable x have, uintptr_t or physaddr_t?
	mystery_t x;
	char* value = return_a_pointer();
	*value = 10;
	x = (mystery_t) value;
```
因为the kernel can't sensibly dereference a physical address，所以这个地址是逻辑地址，x的类型应该为uintptr_t.

 

exercise 4
-------------------------------
```
Exercise 4. In the file kern/pmap.c, you must implement code for the following functions.

        pgdir_walk()
        boot_map_region()
        page_lookup()
        page_remove()
        page_insert()
	
check_page(), called from mem_init(), tests your page table management routines. You should make sure it reports success before proceeding.
```

###exercise4解答
pgdir_walk():
```
	bool exist = false;
	pte_t *ptdir;
	if	(pgdir[PDX(va)] & PTE_P) {
		ptdir = (pte_t*) KADDR(PTE_ADDR(pgdir[PDX(va)]));
		return ptdir + PTX(va);
	} else {
		if (create) {
			struct PageInfo * temp = page_alloc(ALLOC_ZERO);
			if (temp == NULL) return NULL;
			temp->pp_ref++;
			pgdir[PDX(va)] = page2pa(temp) | PTE_P | PTE_U | PTE_W;
			ptdir = (pte_t*) KADDR(page2pa(temp));
			return ptdir + PTX(va);
		} else return NULL;
	}
	return NULL;
```
boot_map_region():
```
	uintptr_t end = va + size;
	pte_t* now;
	for (;va != end; va += PGSIZE, pa += PGSIZE) {
		now = pgdir_walk(pgdir, (void*)va, 1);
		if (now == NULL)
			panic("stopped");
		*now = PTE_ADDR(pa) | perm | PTE_P;
	}
```
page_lookup():
```
	pte_t* now = pgdir_walk(pgdir, va, 0);
	if (now != NULL) {
		if (pte_store != NULL) {
			*pte_store = now;
		}
		return pa2page(PTE_ADDR(*now));
	}
	return NULL;
```
page_remove():
```
	pte_t* now;	
	struct PageInfo* temp = page_lookup(pgdir, va, &now);
	if (temp != NULL) {
		if (*now & PTE_P) {
			page_decref(temp);
		}
		*now = 0;
	}

```
page_insert():
```
	pte_t* now = pgdir_walk(pgdir, va, 0);
	if ((now != NULL) && (*now & PTE_P)) {
		if (PTE_ADDR(*now) == page2pa(pp)) {
			*now = PTE_ADDR(page2pa(pp)) | perm | PTE_P;
			return 0;
		}
		page_remove(pgdir, va);
	}
	if (now == NULL) now = pgdir_walk(pgdir, va, 1);
	if (now == NULL) return -E_NO_MEM;
	*now = PTE_ADDR(page2pa(pp)) | perm | PTE_P;
	pp->pp_ref++;
	return 0;
```

###exercise4遇到的困难和错误
由于读到了有关与reference的区别，对于一开始的page_init()函数进行了修改，对于之前那些不能引用的pp_ref设为1。


 
```
kernel panic at kern/pmap.c:354: KADDR called with invalid pa f0119000
```
对于这个错误非常有感触，一开是认为a+4和a[4]是相同的，之后经过考虑，发现如果a是一个int*的话，a+4还是表示一个int指针，而a[4]则是一个int，所以这两者不同，这个错误属于自己对于指针的理解错误，所以对于pgdir_walk中的物理地址没有引用正确导致了这个错误。

 
```
kernel panic at kern/pmap.c:775: assertion failed: !page_alloc(0)
```
在page_insert()函数中没有考虑insert的page跟已有的配对的page相同的情况

 
```
kernel panic at kern/pmap.c:790: assertion failed: *pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U
```
在之前判断insert的page跟已有的配对的相同，我直接return 0了，没有给他这个页的权限重新赋值。


```
kernel panic at kern/pmap.c:821: assertion failed: pp2->pp_ref == 0
```
这里在insert取到的pte_t和remove时取到的pte_t不同，最后发现是在page_lookup中犯了一个指针的常识错误，在对pte_store赋值的时候，我直接使用了下面的语句

```
if (pte_store != NULL) {
	pte_store = &now;
}
```
但实际上应该是
```
if (pte_store != NULL) {
	*pte_store = now;
}
```
我将传入的指针换了一个地址，所以才会出现这个错误。
上面的大部分错误都是对于指针的错误，所以lab1自以为对于指针有了一个很好的理解，其实并没有理解的特别透彻，这次算是给自己重新认识了一遍指针。

Part 3: Kernel Address Space
===========================

Exercise 5
--------------------
```
Exercise 5. Fill in the missing code in mem_init() after the call to check_page().
```
###exercise5解答
```
Map 'pages' read-only by the user at linear address UPAGES
Use the physical memory that 'bootstack' refers to as the kernel stack.  The kernel stack grows down from virtual address KSTACKTOP.
Map all of physical memory at KERNBASE.
Your code should now pass the check_kern_pgdir() and
 check_page_installed_pgdir() checks.

```
根据要求的对应夜页面和权限，得到以下代码:
```
	boot_map_region(kern_pgdir, UPAGES, ROUNDUP(npages * sizeof(struct PageInfo), PGSIZE), PADDR(pages), PTE_U | PTE_P);
	boot_map_region(kern_pgdir, KSTACKTOP - KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W);
	boot_map_region(kern_pgdir, KERNBASE, /*(1 << 32)*/ - KERNBASE, 0, PTE_W); 

```
###exercise5遇到的困难和错误
```
kernel panic at kern/pmap.c:685: assertion failed: check_va2pa(pgdir, KERNBASE + i) == i
```
这个错误是在boot_map_region中我写的循环没有考虑到尾地址越界的情况，直接使用了< 号，其实应该使用！=号
```
	uintptr_t end = va + size;
	for (;va < end; va += PGSIZE, pa += PGSIZE) 
```
应该改成
```
	uintptr_t end = va + size;
	for (;va ！= end; va += PGSIZE, pa += PGSIZE) {
 
```
###问题解答
```
Question:
What entries (rows) in the page directory have been filled in at this point? What addresses do they map and where do they point? In other words, fill out this table as much as possible:
Entry	Base Virtual Address	Points to (logically):
1023	?	Page table for top 4MB of phys memory
1022	?	?
.	?	?
.	?	?
.	?	?
2	0x00800000	?
1	0x00400000	?
0	0x00000000	[see next question]
```
UPAGES下没有匹配的物理地址
[UPAGES, ULIM)有相匹配的物理地址，匹配到相应的页面信息
[KSTACK - KSTACKSIZE, KSTACK)有相匹配的物理地址，匹配到相应的栈
KERNBASE之上有相匹配的物理地址，匹配到相应的内核地址。

```
Question:
(From Lecture 3) We have placed the kernel and user environment in the same address space. Why will user programs not be able to read or write the kernel's memory? What specific mechanisms protect the kernel memory?
```
在这一段中我们只给了用户可读的权限，及PTE_U，用户是不被允许修改此处的代码的，从而带到了保护的目的。
<br />
```
Question:
What is the maximum amount of physical memory that this operating system can support? Why?
```
因为UPAGES物理地址处存放的就是相关的PAGE，存放的结构为Page Info结构，占用的空间为8b，根据PTSIZE，算出PGSIZE*NPTENTRIES/sizeof(struct PageInfo)为512KB, 所以每个Page Table对应一个PGSIZE的页空间大约为2G
<br />
```
Question:
How much space overhead is there for managing memory, if we actually had the maximum amount of physical memory? How is this overhead broken down?
```
一般物理地址为4G，所以page table就为4M，所需的struct PageInfo为8M+8kb，总共大约12M
```
Question:
Revisit the page table setup in kern/entry.S and kern/entrypgdir.c. Immediately after we turn on paging, EIP is still a low number (a little over 1MB). At what point do we transition to running at an EIP above KERNBASE? What makes it possible for us to continue executing at a low EIP between when we enable paging and when we begin running at an EIP above KERNBASE? Why is this transition necessary?
```

Challenge
----------------
```
Challenge! We consumed many physical pages to hold the page tables for the KERNBASE mapping. Do a more space-efficient job using the PTE_PS ("Page Size") bit in the page directory entries. This bit was not supported in the original 80386, but is supported on more recent x86 processors. You will therefore have to refer to Volume 3 of the current Intel manuals. Make sure you design the kernel to use this optimization only on processors that support it!
```
查阅了相关资料，感觉重写一个有些困难，所以没有做这个challenge
<br />

```
Challenge! Extend the JOS kernel monitor with commands to:

Display in a useful and easy-to-read format all of the physical page mappings (or lack thereof) that apply to a particular range of virtual/linear addresses in the currently active address space. For example, you might enter 'showmappings 0x3000 0x5000' to display the physical page mappings and corresponding permission bits that apply to the pages at virtual addresses 0x3000, 0x4000, and 0x5000.
Explicitly set, clear, or change the permissions of any mapping in the current address space.
Dump the contents of a range of memory given either a virtual or physical address range. Be sure the dump code behaves correctly when the range extends across page boundaries!
Do anything else that you think might be useful later for debugging the kernel. (There's a good chance it will be!)
```
实现了相关的命令行，由于地址是16进制的所以需要写一个转换进制的函数，其中判断了是否是个无效的地址，由于需要这一步所以加入了一个ptoi的函数
```
uint32_t xtoi(char* origin, bool* check) {
	uint32_t i = 0, temp = 0, len = strlen(origin);
	*check = true;
	if ((origin[0] != '0') || (origin[1] != 'x' && origin[1] != 'X')) 
	{
		*check = false;
		return -1;
	}
	for (i = 2; i < len; i++) {
		temp *= 16;
		if (origin[i] >= '0' && origin[i] <= '9')
			temp += origin[i] - '0';
		else if (origin[i] >= 'a' && origin[i] <= 'f')
			temp += origin[i] - 'a' + 10;
		else if (origin[i] >= 'A' && origin[i] <= 'F')
			temp += origin[i] - 'A' + 10;
		else {
			*check = false;
			return -1;
		}
	}
	return temp;
}

bool pxtoi(uint32_t *va, char *origin) {
	bool check = true;
	*va = xtoi(origin, &check);
	if (!check) {
		cprintf("Address typing error\n");
		return false;
	}
	return true;
}

```
于此同时为了方便，所以加入了相应的permissiong的输出代码。
```
void printPermission(pte_t now) {
	cprintf("PTE_U : %d ", ((now & PTE_U) != 0));
	cprintf("PTE_W : %d ", ((now & PTE_W) != 0));
	cprintf("PTE_P : %d ", ((now & PTE_P) != 0));
}
```
1.showmapping
```
int mon_showmapping(int argc, char **argv, struct Trapframe *tf) 
{
	uintptr_t begin, end;
	if (!pxtoi(&begin, argv[1])) return 0;
	if (!pxtoi(&end, argv[2])) return 0;
	begin = ROUNDUP(begin, PGSIZE); 
	end   = ROUNDUP(end, PGSIZE);
	for (;begin <= end; begin += PGSIZE) {
		pte_t *mapper = pgdir_walk(kern_pgdir, (void*) begin, 1);
		cprintf("VA 0x%08x : ", begin);
		if (mapper != NULL) {
			if (*mapper & PTE_P) {
				cprintf("mapping 0x%08x ", PTE_ADDR(*mapper));//, PADDR((void*)begin));
				printPermission((pte_t)*mapper);
				cprintf("\n");
			} else {
				cprintf("page not mapping\n");
			}
		} else {
			panic("error, out of memory");
		}
	}
	return 0;
}
```
关于这个命令行，我直接使用了pgdir_walk函数来查找他对应的page table，从而找他的物理地址来实现，之后发现可以直接使用PADDR，但由于他的_panic的找不到具体的代码，只是在assert.h中有提及，所以猜测这个只是针对最初步的情况，很有可能他的映射会导致fault，之后在测试栈的映射时候果然发现会触发相应的fault，说明这个函数只是在一开始有用。
从KADDR也可以看出这点，毕竟他直接减了KERNBASE。下面展示效果，分别查找我们的UPAGES以上的部分，以下的部分，stack的部分这几方面保证正确性。
```
K> showmappings 0xefff0000 0xf0000000
VA 0xefff0000 : page not mapping
VA 0xefff1000 : page not mapping
VA 0xefff2000 : page not mapping
VA 0xefff3000 : page not mapping
VA 0xefff4000 : page not mapping
VA 0xefff5000 : page not mapping
VA 0xefff6000 : page not mapping
VA 0xefff7000 : page not mapping
VA 0xefff8000 : mapping 0x0010f000 PTE_U : 0 PTE_W : 1 PTE_P : 1 
VA 0xefff9000 : mapping 0x00110000 PTE_U : 0 PTE_W : 1 PTE_P : 1 
VA 0xefffa000 : mapping 0x00111000 PTE_U : 0 PTE_W : 1 PTE_P : 1 
VA 0xefffb000 : mapping 0x00112000 PTE_U : 0 PTE_W : 1 PTE_P : 1 
VA 0xefffc000 : mapping 0x00113000 PTE_U : 0 PTE_W : 1 PTE_P : 1 
VA 0xefffd000 : mapping 0x00114000 PTE_U : 0 PTE_W : 1 PTE_P : 1 
VA 0xefffe000 : mapping 0x00115000 PTE_U : 0 PTE_W : 1 PTE_P : 1 
VA 0xeffff000 : mapping 0x00116000 PTE_U : 0 PTE_W : 1 PTE_P : 1 
VA 0xf0000000 : mapping 0x00000000 PTE_U : 0 PTE_W : 1 PTE_P : 1 
K> showmappings 0xe0000000 0xe000f000
VA 0xe0000000 : page not mapping
VA 0xe0001000 : page not mapping
VA 0xe0002000 : page not mapping
VA 0xe0003000 : page not mapping
VA 0xe0004000 : page not mapping
VA 0xe0005000 : page not mapping
VA 0xe0006000 : page not mapping
VA 0xe0007000 : page not mapping
VA 0xe0008000 : page not mapping
VA 0xe0009000 : page not mapping
VA 0xe000a000 : page not mapping
VA 0xe000b000 : page not mapping
VA 0xe000c000 : page not mapping
VA 0xe000d000 : page not mapping
VA 0xe000e000 : page not mapping
VA 0xe000f000 : page not mapping
K> showmappings 0xf0000000 0xf000f000
VA 0xf0000000 : mapping 0x00000000 PTE_U : 0 PTE_W : 1 PTE_P : 1 
VA 0xf0001000 : mapping 0x00001000 PTE_U : 0 PTE_W : 1 PTE_P : 1 
VA 0xf0002000 : mapping 0x00002000 PTE_U : 0 PTE_W : 1 PTE_P : 1 
VA 0xf0003000 : mapping 0x00003000 PTE_U : 0 PTE_W : 1 PTE_P : 1 
VA 0xf0004000 : mapping 0x00004000 PTE_U : 0 PTE_W : 1 PTE_P : 1 
VA 0xf0005000 : mapping 0x00005000 PTE_U : 0 PTE_W : 1 PTE_P : 1 
VA 0xf0006000 : mapping 0x00006000 PTE_U : 0 PTE_W : 1 PTE_P : 1 
VA 0xf0007000 : mapping 0x00007000 PTE_U : 0 PTE_W : 1 PTE_P : 1 
VA 0xf0008000 : mapping 0x00008000 PTE_U : 0 PTE_W : 1 PTE_P : 1 
VA 0xf0009000 : mapping 0x00009000 PTE_U : 0 PTE_W : 1 PTE_P : 1 
VA 0xf000a000 : mapping 0x0000a000 PTE_U : 0 PTE_W : 1 PTE_P : 1 
VA 0xf000b000 : mapping 0x0000b000 PTE_U : 0 PTE_W : 1 PTE_P : 1 
VA 0xf000c000 : mapping 0x0000c000 PTE_U : 0 PTE_W : 1 PTE_P : 1 
VA 0xf000d000 : mapping 0x0000d000 PTE_U : 0 PTE_W : 1 PTE_P : 1 
VA 0xf000e000 : mapping 0x0000e000 PTE_U : 0 PTE_W : 1 PTE_P : 1 
VA 0xf000f000 : mapping 0x0000f000 PTE_U : 0 PTE_W : 1 PTE_P : 1 
```
2.setPermission
```
int mon_changePermission(int argc, char **argv, struct Trapframe *tf) 
{
	bool check = true;
	if (argc < 2) {
		cprintf("invalid number of parameters\n");
		return 0;
	}
	uintptr_t va = xtoi(argv[1], &check);
	if (!check) {
		cprintf("Address typing error\n");
		return 0;
	}
	pte_t* mapper = pgdir_walk(kern_pgdir, (void*) va, 1);
	if (!mapper) 
		panic("error, out of memory");
	physaddr_t pa = PTE_ADDR(*mapper);
	int perm = 0;
	//PTE_U PET_W PTE_P
	if (argc != 2) {
		if (argc != 5) {
			cprintf("invalid number of parameters\n");
			return 0;
		}
		if (argv[2][0] == '1') perm |= PTE_U;
		if (argv[3][0] == '1') perm |= PTE_W;
		if (argv[4][0] == '1') perm |= PTE_P;
	}
//	boot_map_region(kern_pgdir, va, PGSIZE, pa, perm);	
	cprintf("before change "); printPermission(*mapper); cprintf("\n");
	
	*mapper = PTE_ADDR(*mapper) | perm;
	cprintf("after change ");  printPermission(*mapper); cprintf("\n");
	return 0;
}
```
接下来实现了相应的设置权限的命令行，一开始使用了boot_map_region函数，但发现这个函数是个本地函数，所以换成了直接对于他的物理地址的权限进行赋值。当缺省时，我默认为权限clear操作。下面是效果。
```
K> setp 0x100000
before change PTE_U : 0 PTE_W : 0 PTE_P : 0 
after change PTE_U : 0 PTE_W : 0 PTE_P : 0 
K> setp 0x1000000 1 1 1
before change PTE_U : 0 PTE_W : 0 PTE_P : 0 
after change PTE_U : 1 PTE_W : 1 PTE_P : 1 
K> setp 0x1000000 0 1 0
before change PTE_U : 1 PTE_W : 1 PTE_P : 1 
after change PTE_U : 0 PTE_W : 1 PTE_P : 0 
```
3.dump
```
int mon_dump(int argc, char **argv, struct Trapframe *tf) {
	uint32_t begin, end;
	if (argc < 3) {
		cprintf("invalid command\n");
		return 0;
	}
	if (!pxtoi(&begin, argv[2])) return 0;
	if (!pxtoi(&end, argv[3])) return 0;
	if (argv[1][0] == 'p') {
		if (PGNUM(end) >= npages || PGNUM(end) >= npages){
			cprintf("out of memory\n");
			return 0;	
		}
		for (;begin <= end; begin += POINT_SIZE)
			cprintf("pa 0x%08x : 0x%08x\n", begin, *((uint32_t*)KADDR(begin)));
	} else if (argv[1][0] == 'v') {
		for (;begin <= end; begin+=POINT_SIZE) {
			cprintf("Va 0x%08x : 0x%08x\n", begin, *((uint32_t*)begin));
		}
	} else cprintf("invalid command\n");
	return 0;

}
```
看逻辑地址的很好做，因为程序里都已经是逻辑地址，直接取他的值就可以了，但是物理地址就不是很清楚怎么做了，我直接使用了KADDR这种可能会导致fault的宏，把它强制先倒成逻辑地址，再直接取值。
效果
```
K>  dump v 0xf0000000 0xf0000010
Va 0xf0000000 : 0xf000ff53
Va 0xf0000008 : 0xf000e2c3
Va 0xf0000010 : 0xf000ff53
K> dump p 0x0 0x10
pa 0x00000000 : 0xf000ff53
pa 0x00000008 : 0xf000e2c3
pa 0x00000010 : 0xf000ff53

```
4.PageTable
```
int mon_showPT(int argc, char **argv, struct Trapframe *tf) {
	uintptr_t va;
	if (!pxtoi(&va, argv[1])) return 0;
	
	pte_t *mapper = pgdir_walk(kern_pgdir, (void*) ((va >> PDXSHIFT) << PDXSHIFT), 1);
	cprintf("Page Table Entry Address : 0x%08x\n", mapper); 
	return 0;
}
```
为了以防万一，我写了一个查找对应的PT的入口的函数

```
Challenge! Write up an outline of how a kernel could be designed to allow user environments unrestricted use of the full 4GB virtual and linear address space. Hint: the technique is sometimes known as "follow the bouncing kernel." In your design, be sure to address exactly what has to happen when the processor transitions between kernel and user modes, and how the kernel would accomplish such transitions. Also describe how the kernel would access physical memory and I/O devices in this scheme, and how the kernel would access a user environment's virtual address space during system calls and the like. Finally, think about and describe the advantages and disadvantages of such a scheme in terms of flexibility, performance, kernel complexity, and other factors you can think of.
```

关于kernel 在内核态和用户态的转化这一部分内容我还没有想法，估计等到以后对系统认识更深刻的时候，可能对这个会有自己的想法了。

```
Challenge! Since our JOS kernel's memory management system only allocates and frees memory on page granularity, we do not have anything comparable to a general-purpose malloc/free facility that we can use within the kernel. This could be a problem if we want to support certain types of I/O devices that require physically contiguous buffers larger than 4KB in size, or if we want user-level environments, and not just the kernel, to be able to allocate and map 4MB superpages for maximum processor efficiency. (See the earlier challenge problem about PTE_PS.)
Generalize the kernel's memory allocation system to support pages of a variety of power-of-two allocation unit sizes from 4KB up to some reasonable maximum of your choice. Be sure you have some way to divide larger allocation units into smaller ones on demand, and to coalesce multiple small allocation units back into larger units when possible. Think about the issues that might arise in such a system.
```
可以使用伙伴系统，把内存分为1，2，4这种2的幂次的多条空间块链，在请求空间时，向上取最近的2的幂次的块，假设为2^k，如果不存在的话，再不断往上找离的最近的空闲块，假设为2^j。然后使用j递归不断切成2半，直到有一个2^k的空闲块，其他的空闲块加入相应的链，如果存在同等的块的化，就合并往上，但这样做的缺点是会产生很多内部碎片。


