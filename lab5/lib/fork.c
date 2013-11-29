// implement fork from user space

#include <inc/string.h>
#include <inc/lib.h>

// PTE_COW marks copy-on-write page table entries.
// It is one of the bits explicitly allocated to user processes (PTE_AVAIL).
#define PTE_COW		0x800

//
// Custom page fault handler - if faulting page is copy-on-write,
// map in our own private writable copy.
//
static void
pgfault(struct UTrapframe *utf)
{
	void *addr = (void *) utf->utf_fault_va;
	uint32_t err = utf->utf_err;
	int r;

	// Check that the faulting access was (1) a write, and (2) to a
	// copy-on-write page.  If not, panic.
	// Hint:
	//   Use the read-only page table mappings at uvpt
	//   (see <inc/memlayout.h>).
	// LAB 4: Your code here.
//	cprintf("err %d %d\n", err, err & FEC_WR);
//				cprintf("%d %d %d\n",addr, ((uint32_t)addr) / PGSIZE, uvpt[((uint32_t)addr) / PGSIZE] & PTE_COW);//uvpd[PDX(addr)] & PTE_P);
//				cprintf("%d %d\n",((uint32_t)977917*PGSIZE) / PGSIZE, uvpt[977917] & PTE_COW);//uvpd[PDX(addr)] & PTE_P);
	if (!(err & FEC_WR)) {
		panic("FEC_WR fault access check failed");
	}
	if ((uvpd[PDX(addr)] & PTE_P) == 0 || (uvpt[((uint32_t)addr) / PGSIZE] & PTE_COW) == 0)
	{
		panic("fault access check failed");
	}


	// Allocate a new page, map it at a temporary location (PFTEMP),
	// copy the data from the old page to the new page, then move the new
	// page to the old page's address.
	// Hint:
	//   You should make three system calls.
	//   No need to explicitly delete the old page's mapping.

	// LAB 4: Your code here.
	r = sys_page_alloc(0, (void*)PFTEMP, PTE_P | PTE_W | PTE_U);
	if (r < 0) panic("page alloc failed");
	addr = ROUNDDOWN (addr, PGSIZE);
	memcpy(PFTEMP, addr, PGSIZE);
	r =	sys_page_map(0, (void*) PFTEMP, 0, addr, PTE_P | PTE_W | PTE_U);
	if (r < 0) panic("sys_page_map failed");

	//panic("pgfault not implemented");
}

//
// Map our virtual page pn (address pn*PGSIZE) into the target envid
// at the same virtual address.  If the page is writable or copy-on-write,
// the new mapping must be created copy-on-write, and then our mapping must be
// marked copy-on-write as well.  (Exercise: Why do we need to mark ours
// copy-on-write again if it was already copy-on-write at the beginning of
// this function?)
//
// Returns: 0 on success, < 0 on error.
// It is also OK to panic on error.
//
static int
duppage(envid_t envid, unsigned pn)
{
	if (pn * PGSIZE == UXSTACKTOP - PGSIZE) return 0;

int r;

	// LAB 4: Your code here.
	if (uvpt[pn] & PTE_SHARE) {
		r = sys_page_map (0, (void*) (pn * PGSIZE), envid, (void*) (pn * PGSIZE), uvpt[pn] & PTE_SYSCALL);
		if (r < 0) panic("duppage sys_page_map error : %e\n", r);
	} 

	if ((uvpt[pn] & PTE_W) || (uvpt[pn] & PTE_COW)) {
		r = sys_page_map(0, (void*) (pn * PGSIZE), envid, (void*) (pn * PGSIZE), PTE_U | PTE_P | PTE_COW);
		if (r < 0) panic("map failed");
		r = sys_page_map(0, (void*) (pn * PGSIZE), 0, (void*) (pn * PGSIZE), PTE_U | PTE_P | PTE_COW);
		if (r < 0) panic("map failed");
	}
	else {
		r = sys_page_map(0, (void*) (pn * PGSIZE), envid, (void*) (pn * PGSIZE), PTE_U | PTE_P);
		if (r < 0) panic("map failed");
	}
//	panic("duppage not implemented");
	return 0;
}

//
// User-level fork with copy-on-write.
// Set up our page fault handler appropriately.
// Create a child.
// Copy our address space and page fault handler setup to the child.
// Then mark the child as runnable and return.
//
// Returns: child's envid to the parent, 0 to the child, < 0 on error.
// It is also OK to panic on error.
//
// Hint:
//   Use uvpd, uvpt, and duppage.
//   Remember to fix "thisenv" in the child process.
//   Neither user exception stack should ever be marked copy-on-write,
//   so you must allocate a new page for the child's user exception stack.
//
envid_t
fork(void)
{
	// LAB 4: our code here.
//	static int pri = 10000;
	set_pgfault_handler(pgfault);
	int envid = sys_exofork();
	if (envid < 0) {
		panic("sys_exofork: %e", envid);
	}
	int r;
	if (envid == 0) {
//		cprintf("child\n");
		thisenv = &envs[ENVX(sys_getenvid())];
		return 0;
	} else {
//		cprintf("father\n");
		uint32_t i;
		for (i = 0; i != UTOP; i += PGSIZE)
			if ((uvpd[PDX(i)] & PTE_P) && (uvpt[i / PGSIZE] & PTE_P) && (uvpt[i / PGSIZE] & PTE_U)) {
				cprintf("%d\n", uvpd[PDX(i)] & PTE_P);
	 			duppage(envid, i / PGSIZE);
	 		}
//		cprintf("father1\n");
	 	r = sys_page_alloc(envid, (void *)(UXSTACKTOP - PGSIZE), PTE_U |PTE_W | PTE_P);
	 	if (r < 0) 
			panic("sys_page_alloc: %e", r);
	 	extern void _pgfault_upcall(void);
	 	r = sys_env_set_pgfault_upcall(envid, _pgfault_upcall);
	 	if (r < 0) 
			panic("set pgfault upcall fail : %e", r);
	//	pri--;
	//	sys_change_priority(envid, pri);
	 	r = sys_env_set_status(envid, ENV_RUNNABLE);

	 	if (r < 0) 
			panic("set child process to ENV_RUNNABLE error : %e", r);
	 	return envid;
	}
	panic("fork not implemented");
}

// Challenge!
int
sfork(void)
{
	panic("sfork not implemented");
	return -E_INVAL;
}
