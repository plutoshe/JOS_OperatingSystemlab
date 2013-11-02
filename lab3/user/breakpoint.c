// program to cause a breakpoint trap

#include <inc/lib.h>

void
umain(int argc, char **argv)
{
	asm volatile("int $3");
	int i = 1;
	cprintf("break point test point %d\n", i);
	cprintf("A\n");
	asm volatile("int $3");
	i++;
	cprintf("break point test point %d\n", i);
	cprintf("A\n");
	cprintf("A\n");
}

