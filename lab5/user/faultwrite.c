// buggy program - faults with a write to location zero

#include <inc/lib.h>

void
umain(int argc, char **argv)
{
	int a[3];
	sys_raid2_init();
	a[0] = 1; a[1] = 2; a[2] = 3;
	sys_raid2_add(3 * 32, a);
	sys_raid2_change(1, 1, 4);
	sys_raid2_check();
	return;
}
/*void
umain(int argc, char **argv)
{
	*(unsigned*)0 = 0;
}
*/

