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
//	sys_raid2_change(0, 0, 1);
	sys_raid2_check();
	return;
}
/*void
umain(int argc, char **argv)
{
	*(unsigned*)0 = 0;
}
*/

