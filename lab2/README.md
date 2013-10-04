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
Exercise 1
-----------------------------------
由于不像lab1那样有这样那样的提示，所以一开始从ics书开始复习，到操统书的这一部分都浏览了一遍，基本上有了一些了解，从张驰的报告中看到了有关的ppt，
接下来基本上是看注释加了解，边尝试边探索的前进。
程序在lab2中全是virtual address，要注意转换，PADDR
###exercise1
###exercise1错误
没有注意到i++是加PGSIZE，所以对于low和top忘记除PGSIZE了
首先对于pages没有赋值
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

发生上述错误，基本上是空指针错误

 

对于top没有赋值为对应的地址
kernel panic at kern/pmap.c:502: assertion failed: nfree_extmem > 0

第三个错误
对于page_free_list在alloc之后没有到放弃这一个页面，到下一个pp_link
kernel panic at kern/pmap.c:532: assertion failed: pp1 && pp1 != pp0

还是没有注意到程序中的地址都是虚拟地址，对概念没有理解透彻，在清0的时候直接使用了page_next_list，直接对这个节然后就发现实际的并没有清0，应该使用page2kva，转到应有的虚拟地址上
从memset(page_next_list, 0, PGSIZE)到
memset(page2kva(page_next_list), 0, PGSIZE)
从c = page2kva发现这个问题
kernel panic at kern/pmap.c:570: assertion failed: c[i] == 0

exercise 2
因为之前复习过ics，另外读了张弛介绍老师的文稿，所以这部分算是比较清楚了

exercise 3
我的qemu好像并没有这些个命令。
Q:
Assuming that the following JOS kernel code is correct, what type
   	  should variable x have, uintptr_t or physaddr_t?
   	  mystery_t x;
   	  char* value = return_a_pointer();
  	   *value = 10;
  	   x = (mystery_t) value;

因为the kernel can't sensibly dereference a physical address，所以这个地址是虚拟地址

kernel panic at kern/pmap.c:696: assertion failed: page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0

 

exercise 4

由于读到了有关与reference的区别，对于一开始的初始化进行了修改，对于之前那些不能引用的pp_ref设为1

 

Be careful when using page_alloc. The page it returns will always have a reference count of 0, so pp_ref should be incremented as soon as you've done something with the returned page (like inserting it into a page table). Sometimes this is handled by other functions (for example, page_insert) and sometimes the function calling page_alloc must do it directly.

 

kernel panic at kern/pmap.c:354: KADDR called with invalid pa f0119000

a + 4 和a[4]不同

 

kernel panic at kern/pmap.c:775: assertion failed: !page_alloc(0)

没有考虑insert的page跟已有的配对的相同

 

kernel panic at kern/pmap.c:790: assertion failed: *pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U

在之前nsert的page跟已有的配对的相同，我直接return 0了，没有赋他的权限

// page_remove(now_page);
if (PTE_ADDR(*now) == page2pa(pp)) {
// *now = PTE_ADDR(page2pa(pp)) | perm | PTE_P;
return 0;
}

kernel panic at kern/pmap.c:821: assertion failed: pp2->pp_ref == 0

这里在insert取到的pte_t和remove时取到的pte_t不同，最后发现是在page_lookup中犯了一个指针的常识错误，在对pte_store赋值的时候，我直接使用了下面的语句

if (pte_store != NULL) {
pte_store = &now;
}

但实际上应该是

if (pte_store != NULL) {
*pte_store = now;
}

我将传入的指针换了一个地址，所以才会出现这个错误。



Exercise 5

kernel panic at kern/pmap.c:685: assertion failed: check_va2pa(pgdir, KERNBASE + i) == i

这个错误是在boot_map_region中我写的循环没有考虑到尾地址越界的情况，直接使用了< 号，其实应该使用！=号

uintptr_t end = va + size;

for (;va < end; va += PGSIZE, pa += PGSIZE) {

应该改成

uintptr_t end = va + size;

for (;va ！= end; va += PGSIZE, pa += PGSIZE) {

 

 

大标题
===================================
  大标题一般显示工程名,类似html的\<h1\><br />
  你只要在标题下面跟上=====即可

  
中标题
-----------------------------------
  中标题一般显示重点项,类似html的\<h2\><br />
  你只要在标题下面输入------即可
  
### 小标题
  小标题类似html的\<h3\><br />
  小标题的格式如下 ### 小标题<br />
  注意#和标题字符中间要有空格

### 注意!!!下面所有语法的提示我都先用小标题提醒了!!! 

### 单行文本框
    这是一个单行的文本框,只要两个Tab再输入文字即可
        
### 多行文本框  
    这是一个有多行的文本框
    你可以写入代码等,每行文字只要输入两个Tab再输入文字即可
    这里你可以输入一段代码

### 比如我们可以在多行文本框里输入一段代码,来一个Java版本的HelloWorld吧
    public class HelloWorld {

      /**
      * @param args
   */
   public static void main(String[] args) {
   System.out.println("HelloWorld!");

   }

    }
### 链接
1.[点击这里你可以链接到www.google.com](http://www.google.com)<br />
2.[点击这里我你可以链接到我的博客](http://guoyunsky.iteye.com)<br />

###只是显示图片
![github](http://github.com/unicorn.png "github")

###想点击某个图片进入一个网页,比如我想点击github的icorn然后再进入www.github.com
[![image]](http://www.github.com/)
[image]: http://github.com/github.png "github"

### 文字被些字符包围
> 文字被些字符包围
>
> 只要再文字前面加上>空格即可
>
> 如果你要换行的话,新起一行,输入>空格即可,后面不接文字
> 但> 只能放在行首才有效

### 文字被些字符包围,多重包围
> 文字被些字符包围开始
>
> > 只要再文字前面加上>空格即可
>
>  > > 如果你要换行的话,新起一行,输入>空格即可,后面不接文字
>
> > > > 但> 只能放在行首才有效

### 特殊字符处理
有一些特殊字符如<,#等,只要在特殊字符前面加上转义字符\即可<br />
你想换行的话其实可以直接用html标签\<br /\>
