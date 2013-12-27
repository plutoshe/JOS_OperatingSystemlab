JOS Extension Report
====================================
Main Point
----------------------------
关于JOS Extension的内容，我主要做的是关于raid的调研和在JOS上实现了RAID2，以及关于RAID2的正确性的检测。在这个基础上我对RAID这一技术有了一个很好的了解，而在JOS实现它算是对自己的一个思考问题解决问题的能力的提升了吧。

调研
===
关于调研，我基本上只在google上查找有需要的资料，而http://blog.open-e.com/what-is-raid-0/这个 blog给予我的启发比较大，wiki和百度百科的解释过于概括，这让我对于整个RAID技术的发展有了一个清晰的认识，虽然课上也许没有讲的太清楚。<br/>

由于需要实现RAID2，所以需要清楚的知道RAID2的实现机制，而RAID2的关键就在于海明码，关于海明码的知识和编码的知识主要通过离散数学书和网上的一些资料了解。

实现
===
由于如果要在JOS的实现真正的RAID需要写硬盘驱动，这又是一个大的项目，所以我考虑内存上实现对应的RAID技术，一开始想到的是page_alloc函数，但之后考虑到这样一页一页的申请，不但繁琐，而且对于我“硬盘”的结构是一种限制，对于PGSIZE的空间如何分配又是一件很复杂的事情，所以参考了之前关于pages和envs空间的申请的方法，我直接在内存中申请了一片空间做为我的RAID硬盘的空间。并在其中加入对应的虚拟地址的映射，方便我的检测用户程序使用。由于JOS会检查我申请空间是否位被使用，我需要将那处的检查删去，才能成功运行我的程序。
```
raid2_disks = (struct My_Disk*) boot_alloc(nraid2_disks * sizeof(struct My_Disk));

boot_map_region(kern_pgdir, URAID, ROUNDUP(nraid2_disks * sizeof(struct My_Disk), PGSIZE), PADDR(raid2_disks), PTE_U | PTE_P);
```
而我为我的“硬盘”结构设置为之下的结构，
```
struct My_Disk {
	bool dirty;
	struct My_Disk* next;
	int now;
	int data;
};
```
dirty标示该硬盘是否被改过或者污染，next标示我的该组硬盘下一个硬盘是哪一个，now标示我的data写到了第几位，data表示我的硬盘的数据，data这里为了方便我直接使用了int，其实可以把它改称一个数组，占更大的空间，这样更符合实际。
```
int nraid2_disks = 100;
struct My_Disk* raid2_disks;
struct My_Disk* origin_raid2_disk[7];
struct My_Disk* user_raid2_disk[7];
int now_raid2_add;
int now_raid2_disk;
int nn_add[7] = {0, 0, 4, 0, 5, 6, 2}; 
#define URAID 0x700000
```
上面是我定义的一些初始的变量和常量，我使用的是7位的RAID2，其中有4位数据，3位hamming码。所以nn_add表示我下一个位需要加到哪一个硬盘链。now_raid2_add表示我现在，now_raid2_disk,raid2_disks为我申请的可用的”硬盘“

```
		case SYS_raid2_init :
			sys_raid2_init();
			goto _success_invoke;
		case SYS_raid2_add :
			sys_raid2_add(a1, (uint32_t*) a2);
			goto _success_invoke;
		case SYS_raid2_change :
			sys_raid2_change(a1, a2, a3);
			goto _success_invoke;
		case SYS_raid2_check :
			sys_raid2_check();
			goto _success_invoke;
```
在系统调用中，我主要实现了以上4个系统调用，便于我RAID2的添加和检测
```
static void sys_raid2_init() {
	cprintf("~~~~~~~~~~~~~~~~~~%d~~~~~~~~~~~~~~~~~~~~", now_raid2_disk);
	int i;
	for (i = 0; i < 7; i++, now_raid2_disk++) {
		user_raid2_disk[i] = &raid2_disks[now_raid2_disk];
		origin_raid2_disk[i] = &raid2_disks[now_raid2_disk];
		user_raid2_disk[i]->next = NULL;
		user_raid2_disk[i]->data = 0;
		user_raid2_disk[i]->now = 0;
		user_raid2_disk[i]->dirty = false;
	}
	now_raid2_add = 2;
	return;
}
```
raid2_init主要将我硬盘初始化。
```
static void sys_raid2_add(int num, uint32_t* a) {
	int l = (num - 1)/ 32 + 1;
	if (num == 0) return;
	int i, j;
	for (i = 0; i < l; i++) {
//		cprintf("add %d\n", a[i]);
		for (j = 0; j < 32; j++) {
			int tmp = (a[i] & (1 << j))? 1 : 0;
//			cprintf("   padd %d %d %d\n ", tmp, now_raid2_add, user_raid2_disk[now_raid2_add]->now);
			if (tmp)
				user_raid2_disk[now_raid2_add]->data |= 1 << (user_raid2_disk[now_raid2_add]->now);
			else 
				user_raid2_disk[now_raid2_add]->data &= ~(1 << (user_raid2_disk[now_raid2_add]->now));
			user_raid2_disk[now_raid2_add]->now++;
			now_raid2_add = nn_add[now_raid2_add];
			num--;
			if (num == 0) {
				Hamming(user_raid2_disk[2]->now - 1, 1);
				break;
			}
			if (now_raid2_add == 2) {
				Hamming(user_raid2_disk[2]->now - 1, 1);
			}
		}
	}
	cprintf("!!!!");
	for (i = 0; i < 7; i++)
		cprintf("%x\n", user_raid2_disk[i]->data);
}

```
sys_raid2_add 将用户需要加入的数据加入到我的RAID2中。
```
static void sys_raid2_change(int is_disk, int num, int change) {
	if (is_disk) {
		raid2_disks[num].dirty = true;
		raid2_disks[num].data = change;
		return;
	}
	struct My_Disk* tmp_disk[7];

	int i;
	for (i = 0; i < 7; i++) 
		tmp_disk[i] = origin_raid2_disk[i];
	for (;num > 32 * 4;) {
		num -= 32 * 4;
		for (i = 0; i < 7; i++)
			tmp_disk[i] = tmp_disk[i]->next;
	}
	int row = num / 4;
	int col = num % 4;
	if (col >= 1) col += 3; else col += 2;
	tmp_disk[col]->data &= ~(1 << row);
	tmp_disk[col]->data |= change;
	return;

}
```
sys_raid2_change是将我的硬盘的数据进行修改，以便我进行检测，is_disk表明我是不是整块硬盘进行修改，而change为我进行修改的值，num在修改硬盘情况下，表示我修改的是第几块硬盘，否则表示我修改是数据第多少位。
```
static void sys_raid2_check() { 
	cprintf("check check\n");
	int sum_d = 0;
	int i;
	for (i = 0; i < 7; i++) {
		tmp_disk[i] = origin_raid2_disk[i];
		if (tmp_disk[i]->dirty) sum_d++;
	}
	int now_num = 0;
	for (;tmp_disk[0] != NULL;) {
		cprintf("-------------------------------------%d %d\n", now_num, sum_d);
		uint32_t a1 = (tmp_disk[2]->data ^ tmp_disk[4]->data ^ tmp_disk[6]->data ^ tmp_disk[0]->data);
		uint32_t a2 = (tmp_disk[2]->data ^ tmp_disk[5]->data ^ tmp_disk[6]->data ^ tmp_disk[1]->data);
		uint32_t a3 = (tmp_disk[5]->data ^ tmp_disk[4]->data ^ tmp_disk[6]->data ^ tmp_disk[3]->data);
		cprintf("start!\n");
		for (i = 0; i < 7; i++) {
			cprintf("%x\n", tmp_disk[i]->data); 
		}
		cprintf("end!\n");
//		cout << a1 << endl;
	//	cprintf("%x  %x  %x\n", a1, a2, a3);
//		cout << a2 << endl;
//		cout
		int l = 0;
		int t = 0;
		for (i = 0; i < tmp_disk[2]->now; i++) {
			int b1 = 0, b2 = 0, b3 = 0;
			if ((a1) & (1 << i)) {
				b1 = 1;
			}
			if ((a2) & (1 << i)) {
				b2 = 2;
			}
			if ((a3) & (1 << i)) {
				b3 = 4;
			}
			int st = b1 + b2 + b3 - 1;
			if (st< 0) continue;
			cprintf("%d\n", st);
			if (sum_d > 2 || !tmp_disk[st]->dirty) {
				cprintf("%d round disk %d bit cannot repair\n", now_num, i);
			} else {
				cprintf("%d round disk %d bit repair\n", now_num, i);
				tmp_disk[st]->data ^= (1 << i);
			}
		}
		cprintf("data\n");
		for (i = 0; i < tmp_disk[2]->now; i++) {	
			t |= (!!(tmp_disk[2]->data & (1 << i))) <<  l;
			l++;
			t |= (!!(tmp_disk[4]->data & (1 << i))) <<  l;
			l++;
			t |= (!!(tmp_disk[5]->data & (1 << i))) <<  l;
			l++;
			t |= (!!(tmp_disk[6]->data & (1 << i))) <<  l;
			l++;
			if (l == 32) {
				cprintf("%d ", t);
				l = 0;
				t = 0;
			}
		}
		if (l != 0) {
			cprintf("%d", t);
		}
		cprintf("\n");
		
//		check_raid2_disk();
		sum_d = 0;
		for (i = 0; i < 7; i++) {
			if (tmp_disk[i]->next == NULL) return;
			tmp_disk[i] = tmp_disk[i]->next;
			if (tmp_disk[i]->dirty) sum_d++;
		}
		now_num++;
	}
	return;

}
```
sys_raid2_check是对于我的raid2中的数据进行检测，如果raid2中数据被改变，则查看是否可以被修复。


检测
===
针对不同的位数，进行了不同的检测，如果是一位的话，直接使用了
```
void
umain(int argc, char **argv)
{
	int a[100];
	sys_raid2_init();
	int i;
	for (i = 0; i < 100; i++) 
		a[i] = i;
	sys_raid2_add(100 * 32, a);
	sys_raid2_change(1, 32, 4);
	sys_raid2_check();
	return;
}
```
得出的答案符合预期，如同ppt中所示，ppt在raid文件夹中。<br/>
如果是两位的话，使用如下的检测程序
```
// buggy program - faults with a write to location zero

#include <inc/lib.h>

void
umain(int argc, char **argv)
{
	int a[100];
	sys_raid2_init();
	int i;
	for (i = 0; i < 100; i++) 
		a[i] = i;
	sys_raid2_add(100 * 32, a);
	sys_raid2_change(1, 32, 4);
	sys_raid2_change(0, 0, 1);
	sys_raid2_check();
	return;
}


```
检测也符合预期。<br/>
三位的话直接修改对应的3块硬盘，发现是不可修复的。这样我就完成了我对我RAID2实现的检测。

