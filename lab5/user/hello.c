// hello, world
#include <inc/lib.h>

void
umain(int argc, char **argv)
{
	int i;
	i = fork();
		if (i != 0) {
			sys_change_priority((envid_t) i, 1);
//			cprintf("**%d\n", i);
//			cpinrtf("%d", envs[i]->priority);
			sys_yield();
			cprintf("\n~~~%d\n", 0);
			cprintf("\n~~~%d\n", 0);
			cprintf("\n~~~%d\n", 0);
		} else {
			sys_yield();
			cprintf("^^%d\n", i);
			cprintf("\n!!!\n");
			cprintf("\n!!!\n");
			cprintf("\n!!!\n");
			return;
		}
		i =fork();
		if (i != 0) {
			sys_change_priority(i, 1);
			sys_yield();
			cprintf("\n~~~%d\n", 0);
			cprintf("\n~~~%d\n", 0);
			cprintf("\n~~~%d\n", 0);
			cprintf("\n~~~%d\n", 0);
		} else {
			cprintf("\n%d\n", 2);
			cprintf("\n%d\n", 2);
			cprintf("\n%d\n", 2);
			cprintf("\n%d\n", 2);
			return;
		}
	cprintf("hello, world\n");
	cprintf("i am environment %08x\n", thisenv->env_id);
		int child , j;
		for (i = 0; i != 3; i++) {
			child = fork ();
			if (child == 0) {
				for (j = 0; j != 10; j++) {
					cprintf("hello world from : %d\n", i);
					sys_yield ();
				}
				break;
			}
		}


}

