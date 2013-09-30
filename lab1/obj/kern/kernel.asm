
obj/kern/kernel:     file format elf32-i386


Disassembly of section .text:

f0100000 <_start+0xeffffff4>:
.globl		_start
_start = RELOC(entry)

.globl entry
entry:
	movw	$0x1234,0x472			# warm boot
f0100000:	02 b0 ad 1b 00 00    	add    0x1bad(%eax),%dh
f0100006:	00 00                	add    %al,(%eax)
f0100008:	fe 4f 52             	decb   0x52(%edi)
f010000b:	e4 66                	in     $0x66,%al

f010000c <entry>:
f010000c:	66 c7 05 72 04 00 00 	movw   $0x1234,0x472
f0100013:	34 12 
	# sufficient until we set up our real page table in mem_init
	# in lab 2.

	# Load the physical address of entry_pgdir into cr3.  entry_pgdir
	# is defined in entrypgdir.c.
	movl	$(RELOC(entry_pgdir)), %eax
f0100015:	b8 00 00 11 00       	mov    $0x110000,%eax
	movl	%eax, %cr3
f010001a:	0f 22 d8             	mov    %eax,%cr3
	# Turn on paging.
	movl	%cr0, %eax
f010001d:	0f 20 c0             	mov    %cr0,%eax
	orl	$(CR0_PE|CR0_PG|CR0_WP), %eax
f0100020:	0d 01 00 01 80       	or     $0x80010001,%eax
	movl	%eax, %cr0
f0100025:	0f 22 c0             	mov    %eax,%cr0

	# Now paging is enabled, but we're still running at a low EIP
	# (why is this okay?).  Jump up above KERNBASE before entering
	# C code.
	mov	$relocated, %eax
f0100028:	b8 2f 00 10 f0       	mov    $0xf010002f,%eax
	jmp	*%eax
f010002d:	ff e0                	jmp    *%eax

f010002f <relocated>:
relocated:

	# Clear the frame pointer register (EBP)
	# so that once we get into debugging C code,
	# stack backtraces will be terminated properly.
	movl	$0x0,%ebp			# nuke frame pointer
f010002f:	bd 00 00 00 00       	mov    $0x0,%ebp

	# Set the stack pointer
	movl	$(bootstacktop),%esp
f0100034:	bc 00 00 11 f0       	mov    $0xf0110000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 5f 00 00 00       	call   f010009d <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <test_backtrace>:
#include <kern/console.h>

// Test the stack backtrace function (lab 1 only)
void
test_backtrace(int x)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	53                   	push   %ebx
f0100044:	83 ec 14             	sub    $0x14,%esp
f0100047:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("entering test_backtrace %d\n", x);
f010004a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010004e:	c7 04 24 40 1d 10 f0 	movl   $0xf0101d40,(%esp)
f0100055:	e8 28 0c 00 00       	call   f0100c82 <cprintf>
	if (x > 0)
f010005a:	85 db                	test   %ebx,%ebx
f010005c:	7e 0d                	jle    f010006b <test_backtrace+0x2b>
		test_backtrace(x-1);
f010005e:	8d 43 ff             	lea    -0x1(%ebx),%eax
f0100061:	89 04 24             	mov    %eax,(%esp)
f0100064:	e8 d7 ff ff ff       	call   f0100040 <test_backtrace>
f0100069:	eb 1c                	jmp    f0100087 <test_backtrace+0x47>
	else
		mon_backtrace(0, 0, 0);
f010006b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0100072:	00 
f0100073:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010007a:	00 
f010007b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100082:	e8 12 07 00 00       	call   f0100799 <mon_backtrace>
	cprintf("leaving test_backtrace %d\n", x);
f0100087:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010008b:	c7 04 24 5c 1d 10 f0 	movl   $0xf0101d5c,(%esp)
f0100092:	e8 eb 0b 00 00       	call   f0100c82 <cprintf>
}
f0100097:	83 c4 14             	add    $0x14,%esp
f010009a:	5b                   	pop    %ebx
f010009b:	5d                   	pop    %ebp
f010009c:	c3                   	ret    

f010009d <i386_init>:

void
i386_init(void)
{
f010009d:	55                   	push   %ebp
f010009e:	89 e5                	mov    %esp,%ebp
f01000a0:	83 ec 18             	sub    $0x18,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f01000a3:	b8 64 29 11 f0       	mov    $0xf0112964,%eax
f01000a8:	2d 20 23 11 f0       	sub    $0xf0112320,%eax
f01000ad:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000b1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01000b8:	00 
f01000b9:	c7 04 24 20 23 11 f0 	movl   $0xf0112320,(%esp)
f01000c0:	e8 7c 17 00 00       	call   f0101841 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000c5:	e8 9a 04 00 00       	call   f0100564 <cons_init>
	cprintf("6828 decimal is %o octal!\n", 6828);
f01000ca:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f01000d1:	00 
f01000d2:	c7 04 24 77 1d 10 f0 	movl   $0xf0101d77,(%esp)
f01000d9:	e8 a4 0b 00 00       	call   f0100c82 <cprintf>
	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000de:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000e5:	e8 56 ff ff ff       	call   f0100040 <test_backtrace>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000ea:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000f1:	e8 0c 0a 00 00       	call   f0100b02 <monitor>
f01000f6:	eb f2                	jmp    f01000ea <i386_init+0x4d>

f01000f8 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000f8:	55                   	push   %ebp
f01000f9:	89 e5                	mov    %esp,%ebp
f01000fb:	56                   	push   %esi
f01000fc:	53                   	push   %ebx
f01000fd:	83 ec 10             	sub    $0x10,%esp
f0100100:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f0100103:	83 3d 60 29 11 f0 00 	cmpl   $0x0,0xf0112960
f010010a:	75 3d                	jne    f0100149 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f010010c:	89 35 60 29 11 f0    	mov    %esi,0xf0112960

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f0100112:	fa                   	cli    
f0100113:	fc                   	cld    

	va_start(ap, fmt);
f0100114:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f0100117:	8b 45 0c             	mov    0xc(%ebp),%eax
f010011a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010011e:	8b 45 08             	mov    0x8(%ebp),%eax
f0100121:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100125:	c7 04 24 92 1d 10 f0 	movl   $0xf0101d92,(%esp)
f010012c:	e8 51 0b 00 00       	call   f0100c82 <cprintf>
	vcprintf(fmt, ap);
f0100131:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100135:	89 34 24             	mov    %esi,(%esp)
f0100138:	e8 12 0b 00 00       	call   f0100c4f <vcprintf>
	cprintf("\n");
f010013d:	c7 04 24 ce 1d 10 f0 	movl   $0xf0101dce,(%esp)
f0100144:	e8 39 0b 00 00       	call   f0100c82 <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f0100149:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0100150:	e8 ad 09 00 00       	call   f0100b02 <monitor>
f0100155:	eb f2                	jmp    f0100149 <_panic+0x51>

f0100157 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100157:	55                   	push   %ebp
f0100158:	89 e5                	mov    %esp,%ebp
f010015a:	53                   	push   %ebx
f010015b:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f010015e:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f0100161:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100164:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100168:	8b 45 08             	mov    0x8(%ebp),%eax
f010016b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010016f:	c7 04 24 aa 1d 10 f0 	movl   $0xf0101daa,(%esp)
f0100176:	e8 07 0b 00 00       	call   f0100c82 <cprintf>
	vcprintf(fmt, ap);
f010017b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010017f:	8b 45 10             	mov    0x10(%ebp),%eax
f0100182:	89 04 24             	mov    %eax,(%esp)
f0100185:	e8 c5 0a 00 00       	call   f0100c4f <vcprintf>
	cprintf("\n");
f010018a:	c7 04 24 ce 1d 10 f0 	movl   $0xf0101dce,(%esp)
f0100191:	e8 ec 0a 00 00       	call   f0100c82 <cprintf>
	va_end(ap);
}
f0100196:	83 c4 14             	add    $0x14,%esp
f0100199:	5b                   	pop    %ebx
f010019a:	5d                   	pop    %ebp
f010019b:	c3                   	ret    
f010019c:	00 00                	add    %al,(%eax)
	...

f01001a0 <delay>:
static void cons_putc(int c);

// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
f01001a0:	55                   	push   %ebp
f01001a1:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01001a3:	ba 84 00 00 00       	mov    $0x84,%edx
f01001a8:	ec                   	in     (%dx),%al
f01001a9:	ec                   	in     (%dx),%al
f01001aa:	ec                   	in     (%dx),%al
f01001ab:	ec                   	in     (%dx),%al
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
f01001ac:	5d                   	pop    %ebp
f01001ad:	c3                   	ret    

f01001ae <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f01001ae:	55                   	push   %ebp
f01001af:	89 e5                	mov    %esp,%ebp
f01001b1:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01001b6:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f01001b7:	b9 ff ff ff ff       	mov    $0xffffffff,%ecx
static bool serial_exists;

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f01001bc:	a8 01                	test   $0x1,%al
f01001be:	74 06                	je     f01001c6 <serial_proc_data+0x18>
f01001c0:	b2 f8                	mov    $0xf8,%dl
f01001c2:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f01001c3:	0f b6 c8             	movzbl %al,%ecx
}
f01001c6:	89 c8                	mov    %ecx,%eax
f01001c8:	5d                   	pop    %ebp
f01001c9:	c3                   	ret    

f01001ca <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f01001ca:	55                   	push   %ebp
f01001cb:	89 e5                	mov    %esp,%ebp
f01001cd:	53                   	push   %ebx
f01001ce:	83 ec 04             	sub    $0x4,%esp
f01001d1:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f01001d3:	eb 25                	jmp    f01001fa <cons_intr+0x30>
		if (c == 0)
f01001d5:	85 c0                	test   %eax,%eax
f01001d7:	74 21                	je     f01001fa <cons_intr+0x30>
			continue;
		cons.buf[cons.wpos++] = c;
f01001d9:	8b 15 44 25 11 f0    	mov    0xf0112544,%edx
f01001df:	88 82 40 23 11 f0    	mov    %al,-0xfeedcc0(%edx)
f01001e5:	8d 42 01             	lea    0x1(%edx),%eax
		if (cons.wpos == CONSBUFSIZE)
f01001e8:	3d 00 02 00 00       	cmp    $0x200,%eax
			cons.wpos = 0;
f01001ed:	ba 00 00 00 00       	mov    $0x0,%edx
f01001f2:	0f 44 c2             	cmove  %edx,%eax
f01001f5:	a3 44 25 11 f0       	mov    %eax,0xf0112544
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01001fa:	ff d3                	call   *%ebx
f01001fc:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001ff:	75 d4                	jne    f01001d5 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f0100201:	83 c4 04             	add    $0x4,%esp
f0100204:	5b                   	pop    %ebx
f0100205:	5d                   	pop    %ebp
f0100206:	c3                   	ret    

f0100207 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f0100207:	55                   	push   %ebp
f0100208:	89 e5                	mov    %esp,%ebp
f010020a:	57                   	push   %edi
f010020b:	56                   	push   %esi
f010020c:	53                   	push   %ebx
f010020d:	83 ec 2c             	sub    $0x2c,%esp
f0100210:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100213:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100218:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f0100219:	a8 20                	test   $0x20,%al
f010021b:	75 1b                	jne    f0100238 <cons_putc+0x31>
f010021d:	bb 00 32 00 00       	mov    $0x3200,%ebx
f0100222:	be fd 03 00 00       	mov    $0x3fd,%esi
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
f0100227:	e8 74 ff ff ff       	call   f01001a0 <delay>
f010022c:	89 f2                	mov    %esi,%edx
f010022e:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f010022f:	a8 20                	test   $0x20,%al
f0100231:	75 05                	jne    f0100238 <cons_putc+0x31>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100233:	83 eb 01             	sub    $0x1,%ebx
f0100236:	75 ef                	jne    f0100227 <cons_putc+0x20>
	     i++)
		delay();

	outb(COM1 + COM_TX, c);
f0100238:	0f b6 7d e4          	movzbl -0x1c(%ebp),%edi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010023c:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100241:	89 f8                	mov    %edi,%eax
f0100243:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100244:	b2 79                	mov    $0x79,%dl
f0100246:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100247:	84 c0                	test   %al,%al
f0100249:	78 1b                	js     f0100266 <cons_putc+0x5f>
f010024b:	bb 00 32 00 00       	mov    $0x3200,%ebx
f0100250:	be 79 03 00 00       	mov    $0x379,%esi
		delay();
f0100255:	e8 46 ff ff ff       	call   f01001a0 <delay>
f010025a:	89 f2                	mov    %esi,%edx
f010025c:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010025d:	84 c0                	test   %al,%al
f010025f:	78 05                	js     f0100266 <cons_putc+0x5f>
f0100261:	83 eb 01             	sub    $0x1,%ebx
f0100264:	75 ef                	jne    f0100255 <cons_putc+0x4e>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100266:	ba 78 03 00 00       	mov    $0x378,%edx
f010026b:	89 f8                	mov    %edi,%eax
f010026d:	ee                   	out    %al,(%dx)
f010026e:	b2 7a                	mov    $0x7a,%dl
f0100270:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100275:	ee                   	out    %al,(%dx)
f0100276:	b8 08 00 00 00       	mov    $0x8,%eax
f010027b:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	c = c + attribute_color;
f010027c:	0f b7 15 00 20 11 f0 	movzwl 0xf0112000,%edx
f0100283:	03 55 e4             	add    -0x1c(%ebp),%edx
	//if (!(c & ~0xFF))
	//	c |= 0x0700;

	switch (c & 0xff) {
f0100286:	0f b6 c2             	movzbl %dl,%eax
f0100289:	83 f8 09             	cmp    $0x9,%eax
f010028c:	74 77                	je     f0100305 <cons_putc+0xfe>
f010028e:	83 f8 09             	cmp    $0x9,%eax
f0100291:	7f 0f                	jg     f01002a2 <cons_putc+0x9b>
f0100293:	83 f8 08             	cmp    $0x8,%eax
f0100296:	0f 85 9d 00 00 00    	jne    f0100339 <cons_putc+0x132>
f010029c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01002a0:	eb 10                	jmp    f01002b2 <cons_putc+0xab>
f01002a2:	83 f8 0a             	cmp    $0xa,%eax
f01002a5:	74 38                	je     f01002df <cons_putc+0xd8>
f01002a7:	83 f8 0d             	cmp    $0xd,%eax
f01002aa:	0f 85 89 00 00 00    	jne    f0100339 <cons_putc+0x132>
f01002b0:	eb 35                	jmp    f01002e7 <cons_putc+0xe0>
	case '\b':
		if (crt_pos > 0) {
f01002b2:	0f b7 05 54 25 11 f0 	movzwl 0xf0112554,%eax
f01002b9:	66 85 c0             	test   %ax,%ax
f01002bc:	0f 84 e1 00 00 00    	je     f01003a3 <cons_putc+0x19c>
			crt_pos--;
f01002c2:	83 e8 01             	sub    $0x1,%eax
f01002c5:	66 a3 54 25 11 f0    	mov    %ax,0xf0112554
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01002cb:	0f b7 c0             	movzwl %ax,%eax
f01002ce:	b2 00                	mov    $0x0,%dl
f01002d0:	83 ca 20             	or     $0x20,%edx
f01002d3:	8b 0d 50 25 11 f0    	mov    0xf0112550,%ecx
f01002d9:	66 89 14 41          	mov    %dx,(%ecx,%eax,2)
f01002dd:	eb 77                	jmp    f0100356 <cons_putc+0x14f>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01002df:	66 83 05 54 25 11 f0 	addw   $0x50,0xf0112554
f01002e6:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01002e7:	0f b7 05 54 25 11 f0 	movzwl 0xf0112554,%eax
f01002ee:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01002f4:	c1 e8 16             	shr    $0x16,%eax
f01002f7:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01002fa:	c1 e0 04             	shl    $0x4,%eax
f01002fd:	66 a3 54 25 11 f0    	mov    %ax,0xf0112554
f0100303:	eb 51                	jmp    f0100356 <cons_putc+0x14f>
		break;
	case '\t':
		cons_putc(' ');
f0100305:	b8 20 00 00 00       	mov    $0x20,%eax
f010030a:	e8 f8 fe ff ff       	call   f0100207 <cons_putc>
		cons_putc(' ');
f010030f:	b8 20 00 00 00       	mov    $0x20,%eax
f0100314:	e8 ee fe ff ff       	call   f0100207 <cons_putc>
		cons_putc(' ');
f0100319:	b8 20 00 00 00       	mov    $0x20,%eax
f010031e:	e8 e4 fe ff ff       	call   f0100207 <cons_putc>
		cons_putc(' ');
f0100323:	b8 20 00 00 00       	mov    $0x20,%eax
f0100328:	e8 da fe ff ff       	call   f0100207 <cons_putc>
		cons_putc(' ');
f010032d:	b8 20 00 00 00       	mov    $0x20,%eax
f0100332:	e8 d0 fe ff ff       	call   f0100207 <cons_putc>
f0100337:	eb 1d                	jmp    f0100356 <cons_putc+0x14f>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100339:	0f b7 05 54 25 11 f0 	movzwl 0xf0112554,%eax
f0100340:	0f b7 d8             	movzwl %ax,%ebx
f0100343:	8b 0d 50 25 11 f0    	mov    0xf0112550,%ecx
f0100349:	66 89 14 59          	mov    %dx,(%ecx,%ebx,2)
f010034d:	83 c0 01             	add    $0x1,%eax
f0100350:	66 a3 54 25 11 f0    	mov    %ax,0xf0112554
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100356:	66 81 3d 54 25 11 f0 	cmpw   $0x7cf,0xf0112554
f010035d:	cf 07 
f010035f:	76 42                	jbe    f01003a3 <cons_putc+0x19c>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100361:	a1 50 25 11 f0       	mov    0xf0112550,%eax
f0100366:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f010036d:	00 
f010036e:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100374:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100378:	89 04 24             	mov    %eax,(%esp)
f010037b:	e8 1c 15 00 00       	call   f010189c <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100380:	8b 15 50 25 11 f0    	mov    0xf0112550,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100386:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f010038b:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100391:	83 c0 01             	add    $0x1,%eax
f0100394:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f0100399:	75 f0                	jne    f010038b <cons_putc+0x184>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f010039b:	66 83 2d 54 25 11 f0 	subw   $0x50,0xf0112554
f01003a2:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f01003a3:	8b 0d 4c 25 11 f0    	mov    0xf011254c,%ecx
f01003a9:	b8 0e 00 00 00       	mov    $0xe,%eax
f01003ae:	89 ca                	mov    %ecx,%edx
f01003b0:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01003b1:	0f b7 35 54 25 11 f0 	movzwl 0xf0112554,%esi
f01003b8:	8d 59 01             	lea    0x1(%ecx),%ebx
f01003bb:	89 f0                	mov    %esi,%eax
f01003bd:	66 c1 e8 08          	shr    $0x8,%ax
f01003c1:	89 da                	mov    %ebx,%edx
f01003c3:	ee                   	out    %al,(%dx)
f01003c4:	b8 0f 00 00 00       	mov    $0xf,%eax
f01003c9:	89 ca                	mov    %ecx,%edx
f01003cb:	ee                   	out    %al,(%dx)
f01003cc:	89 f0                	mov    %esi,%eax
f01003ce:	89 da                	mov    %ebx,%edx
f01003d0:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01003d1:	83 c4 2c             	add    $0x2c,%esp
f01003d4:	5b                   	pop    %ebx
f01003d5:	5e                   	pop    %esi
f01003d6:	5f                   	pop    %edi
f01003d7:	5d                   	pop    %ebp
f01003d8:	c3                   	ret    

f01003d9 <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01003d9:	55                   	push   %ebp
f01003da:	89 e5                	mov    %esp,%ebp
f01003dc:	53                   	push   %ebx
f01003dd:	83 ec 14             	sub    $0x14,%esp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01003e0:	ba 64 00 00 00       	mov    $0x64,%edx
f01003e5:	ec                   	in     (%dx),%al
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f01003e6:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f01003eb:	a8 01                	test   $0x1,%al
f01003ed:	0f 84 de 00 00 00    	je     f01004d1 <kbd_proc_data+0xf8>
f01003f3:	b2 60                	mov    $0x60,%dl
f01003f5:	ec                   	in     (%dx),%al
f01003f6:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01003f8:	3c e0                	cmp    $0xe0,%al
f01003fa:	75 11                	jne    f010040d <kbd_proc_data+0x34>
		// E0 escape character
		shift |= E0ESC;
f01003fc:	83 0d 48 25 11 f0 40 	orl    $0x40,0xf0112548
		return 0;
f0100403:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100408:	e9 c4 00 00 00       	jmp    f01004d1 <kbd_proc_data+0xf8>
	} else if (data & 0x80) {
f010040d:	84 c0                	test   %al,%al
f010040f:	79 37                	jns    f0100448 <kbd_proc_data+0x6f>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f0100411:	8b 0d 48 25 11 f0    	mov    0xf0112548,%ecx
f0100417:	89 cb                	mov    %ecx,%ebx
f0100419:	83 e3 40             	and    $0x40,%ebx
f010041c:	83 e0 7f             	and    $0x7f,%eax
f010041f:	85 db                	test   %ebx,%ebx
f0100421:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100424:	0f b6 d2             	movzbl %dl,%edx
f0100427:	0f b6 82 00 1e 10 f0 	movzbl -0xfefe200(%edx),%eax
f010042e:	83 c8 40             	or     $0x40,%eax
f0100431:	0f b6 c0             	movzbl %al,%eax
f0100434:	f7 d0                	not    %eax
f0100436:	21 c1                	and    %eax,%ecx
f0100438:	89 0d 48 25 11 f0    	mov    %ecx,0xf0112548
		return 0;
f010043e:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100443:	e9 89 00 00 00       	jmp    f01004d1 <kbd_proc_data+0xf8>
	} else if (shift & E0ESC) {
f0100448:	8b 0d 48 25 11 f0    	mov    0xf0112548,%ecx
f010044e:	f6 c1 40             	test   $0x40,%cl
f0100451:	74 0e                	je     f0100461 <kbd_proc_data+0x88>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100453:	89 c2                	mov    %eax,%edx
f0100455:	83 ca 80             	or     $0xffffff80,%edx
		shift &= ~E0ESC;
f0100458:	83 e1 bf             	and    $0xffffffbf,%ecx
f010045b:	89 0d 48 25 11 f0    	mov    %ecx,0xf0112548
	}

	shift |= shiftcode[data];
f0100461:	0f b6 d2             	movzbl %dl,%edx
f0100464:	0f b6 82 00 1e 10 f0 	movzbl -0xfefe200(%edx),%eax
f010046b:	0b 05 48 25 11 f0    	or     0xf0112548,%eax
	shift ^= togglecode[data];
f0100471:	0f b6 8a 00 1f 10 f0 	movzbl -0xfefe100(%edx),%ecx
f0100478:	31 c8                	xor    %ecx,%eax
f010047a:	a3 48 25 11 f0       	mov    %eax,0xf0112548

	c = charcode[shift & (CTL | SHIFT)][data];
f010047f:	89 c1                	mov    %eax,%ecx
f0100481:	83 e1 03             	and    $0x3,%ecx
f0100484:	8b 0c 8d 00 20 10 f0 	mov    -0xfefe000(,%ecx,4),%ecx
f010048b:	0f b6 1c 11          	movzbl (%ecx,%edx,1),%ebx
	if (shift & CAPSLOCK) {
f010048f:	a8 08                	test   $0x8,%al
f0100491:	74 19                	je     f01004ac <kbd_proc_data+0xd3>
		if ('a' <= c && c <= 'z')
f0100493:	8d 53 9f             	lea    -0x61(%ebx),%edx
f0100496:	83 fa 19             	cmp    $0x19,%edx
f0100499:	77 05                	ja     f01004a0 <kbd_proc_data+0xc7>
			c += 'A' - 'a';
f010049b:	83 eb 20             	sub    $0x20,%ebx
f010049e:	eb 0c                	jmp    f01004ac <kbd_proc_data+0xd3>
		else if ('A' <= c && c <= 'Z')
f01004a0:	8d 4b bf             	lea    -0x41(%ebx),%ecx
			c += 'a' - 'A';
f01004a3:	8d 53 20             	lea    0x20(%ebx),%edx
f01004a6:	83 f9 19             	cmp    $0x19,%ecx
f01004a9:	0f 46 da             	cmovbe %edx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f01004ac:	f7 d0                	not    %eax
f01004ae:	a8 06                	test   $0x6,%al
f01004b0:	75 1f                	jne    f01004d1 <kbd_proc_data+0xf8>
f01004b2:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01004b8:	75 17                	jne    f01004d1 <kbd_proc_data+0xf8>
		cprintf("Rebooting!\n");
f01004ba:	c7 04 24 c4 1d 10 f0 	movl   $0xf0101dc4,(%esp)
f01004c1:	e8 bc 07 00 00       	call   f0100c82 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01004c6:	ba 92 00 00 00       	mov    $0x92,%edx
f01004cb:	b8 03 00 00 00       	mov    $0x3,%eax
f01004d0:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01004d1:	89 d8                	mov    %ebx,%eax
f01004d3:	83 c4 14             	add    $0x14,%esp
f01004d6:	5b                   	pop    %ebx
f01004d7:	5d                   	pop    %ebp
f01004d8:	c3                   	ret    

f01004d9 <set_attribute_color>:
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
	return inb(COM1+COM_RX);
}

void set_attribute_color(uint16_t back, uint16_t fore) {
f01004d9:	55                   	push   %ebp
f01004da:	89 e5                	mov    %esp,%ebp
	attribute_color = (back << 12) | (fore << 8);
f01004dc:	0f b7 55 0c          	movzwl 0xc(%ebp),%edx
f01004e0:	c1 e2 08             	shl    $0x8,%edx
f01004e3:	0f b7 45 08          	movzwl 0x8(%ebp),%eax
f01004e7:	c1 e0 0c             	shl    $0xc,%eax
f01004ea:	09 d0                	or     %edx,%eax
f01004ec:	66 a3 00 20 11 f0    	mov    %ax,0xf0112000
}
f01004f2:	5d                   	pop    %ebp
f01004f3:	c3                   	ret    

f01004f4 <serial_intr>:

void
serial_intr(void)
{
f01004f4:	55                   	push   %ebp
f01004f5:	89 e5                	mov    %esp,%ebp
f01004f7:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
f01004fa:	80 3d 20 23 11 f0 00 	cmpb   $0x0,0xf0112320
f0100501:	74 0a                	je     f010050d <serial_intr+0x19>
		cons_intr(serial_proc_data);
f0100503:	b8 ae 01 10 f0       	mov    $0xf01001ae,%eax
f0100508:	e8 bd fc ff ff       	call   f01001ca <cons_intr>
}
f010050d:	c9                   	leave  
f010050e:	c3                   	ret    

f010050f <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f010050f:	55                   	push   %ebp
f0100510:	89 e5                	mov    %esp,%ebp
f0100512:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f0100515:	b8 d9 03 10 f0       	mov    $0xf01003d9,%eax
f010051a:	e8 ab fc ff ff       	call   f01001ca <cons_intr>
}
f010051f:	c9                   	leave  
f0100520:	c3                   	ret    

f0100521 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f0100521:	55                   	push   %ebp
f0100522:	89 e5                	mov    %esp,%ebp
f0100524:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f0100527:	e8 c8 ff ff ff       	call   f01004f4 <serial_intr>
	kbd_intr();
f010052c:	e8 de ff ff ff       	call   f010050f <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100531:	8b 15 40 25 11 f0    	mov    0xf0112540,%edx
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
	}
	return 0;
f0100537:	b8 00 00 00 00       	mov    $0x0,%eax
	// (e.g., when called from the kernel monitor).
	serial_intr();
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f010053c:	3b 15 44 25 11 f0    	cmp    0xf0112544,%edx
f0100542:	74 1e                	je     f0100562 <cons_getc+0x41>
		c = cons.buf[cons.rpos++];
f0100544:	0f b6 82 40 23 11 f0 	movzbl -0xfeedcc0(%edx),%eax
f010054b:	83 c2 01             	add    $0x1,%edx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
f010054e:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100554:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100559:	0f 44 d1             	cmove  %ecx,%edx
f010055c:	89 15 40 25 11 f0    	mov    %edx,0xf0112540
		return c;
	}
	return 0;
}
f0100562:	c9                   	leave  
f0100563:	c3                   	ret    

f0100564 <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f0100564:	55                   	push   %ebp
f0100565:	89 e5                	mov    %esp,%ebp
f0100567:	57                   	push   %edi
f0100568:	56                   	push   %esi
f0100569:	53                   	push   %ebx
f010056a:	83 ec 1c             	sub    $0x1c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f010056d:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f0100574:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f010057b:	5a a5 
	if (*cp != 0xA55A) {
f010057d:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f0100584:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100588:	74 11                	je     f010059b <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f010058a:	c7 05 4c 25 11 f0 b4 	movl   $0x3b4,0xf011254c
f0100591:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100594:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f0100599:	eb 16                	jmp    f01005b1 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f010059b:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f01005a2:	c7 05 4c 25 11 f0 d4 	movl   $0x3d4,0xf011254c
f01005a9:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f01005ac:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f01005b1:	8b 0d 4c 25 11 f0    	mov    0xf011254c,%ecx
f01005b7:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005bc:	89 ca                	mov    %ecx,%edx
f01005be:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01005bf:	8d 59 01             	lea    0x1(%ecx),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005c2:	89 da                	mov    %ebx,%edx
f01005c4:	ec                   	in     (%dx),%al
f01005c5:	0f b6 f8             	movzbl %al,%edi
f01005c8:	c1 e7 08             	shl    $0x8,%edi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005cb:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005d0:	89 ca                	mov    %ecx,%edx
f01005d2:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005d3:	89 da                	mov    %ebx,%edx
f01005d5:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01005d6:	89 35 50 25 11 f0    	mov    %esi,0xf0112550

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f01005dc:	0f b6 d8             	movzbl %al,%ebx
f01005df:	09 df                	or     %ebx,%edi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f01005e1:	66 89 3d 54 25 11 f0 	mov    %di,0xf0112554
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005e8:	bb fa 03 00 00       	mov    $0x3fa,%ebx
f01005ed:	b8 00 00 00 00       	mov    $0x0,%eax
f01005f2:	89 da                	mov    %ebx,%edx
f01005f4:	ee                   	out    %al,(%dx)
f01005f5:	b2 fb                	mov    $0xfb,%dl
f01005f7:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01005fc:	ee                   	out    %al,(%dx)
f01005fd:	b9 f8 03 00 00       	mov    $0x3f8,%ecx
f0100602:	b8 0c 00 00 00       	mov    $0xc,%eax
f0100607:	89 ca                	mov    %ecx,%edx
f0100609:	ee                   	out    %al,(%dx)
f010060a:	b2 f9                	mov    $0xf9,%dl
f010060c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100611:	ee                   	out    %al,(%dx)
f0100612:	b2 fb                	mov    $0xfb,%dl
f0100614:	b8 03 00 00 00       	mov    $0x3,%eax
f0100619:	ee                   	out    %al,(%dx)
f010061a:	b2 fc                	mov    $0xfc,%dl
f010061c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100621:	ee                   	out    %al,(%dx)
f0100622:	b2 f9                	mov    $0xf9,%dl
f0100624:	b8 01 00 00 00       	mov    $0x1,%eax
f0100629:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010062a:	b2 fd                	mov    $0xfd,%dl
f010062c:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f010062d:	3c ff                	cmp    $0xff,%al
f010062f:	0f 95 c0             	setne  %al
f0100632:	89 c6                	mov    %eax,%esi
f0100634:	a2 20 23 11 f0       	mov    %al,0xf0112320
f0100639:	89 da                	mov    %ebx,%edx
f010063b:	ec                   	in     (%dx),%al
f010063c:	89 ca                	mov    %ecx,%edx
f010063e:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f010063f:	89 f0                	mov    %esi,%eax
f0100641:	84 c0                	test   %al,%al
f0100643:	75 0c                	jne    f0100651 <cons_init+0xed>
		cprintf("Serial port does not exist!\n");
f0100645:	c7 04 24 d0 1d 10 f0 	movl   $0xf0101dd0,(%esp)
f010064c:	e8 31 06 00 00       	call   f0100c82 <cprintf>
}
f0100651:	83 c4 1c             	add    $0x1c,%esp
f0100654:	5b                   	pop    %ebx
f0100655:	5e                   	pop    %esi
f0100656:	5f                   	pop    %edi
f0100657:	5d                   	pop    %ebp
f0100658:	c3                   	ret    

f0100659 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100659:	55                   	push   %ebp
f010065a:	89 e5                	mov    %esp,%ebp
f010065c:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f010065f:	8b 45 08             	mov    0x8(%ebp),%eax
f0100662:	e8 a0 fb ff ff       	call   f0100207 <cons_putc>
}
f0100667:	c9                   	leave  
f0100668:	c3                   	ret    

f0100669 <getchar>:

int
getchar(void)
{
f0100669:	55                   	push   %ebp
f010066a:	89 e5                	mov    %esp,%ebp
f010066c:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f010066f:	e8 ad fe ff ff       	call   f0100521 <cons_getc>
f0100674:	85 c0                	test   %eax,%eax
f0100676:	74 f7                	je     f010066f <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100678:	c9                   	leave  
f0100679:	c3                   	ret    

f010067a <iscons>:

int
iscons(int fdnum)
{
f010067a:	55                   	push   %ebp
f010067b:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f010067d:	b8 01 00 00 00       	mov    $0x1,%eax
f0100682:	5d                   	pop    %ebp
f0100683:	c3                   	ret    
	...

f0100690 <mon_kerninfo>:
	return 0;
}

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100690:	55                   	push   %ebp
f0100691:	89 e5                	mov    %esp,%ebp
f0100693:	83 ec 18             	sub    $0x18,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100696:	c7 04 24 10 20 10 f0 	movl   $0xf0102010,(%esp)
f010069d:	e8 e0 05 00 00       	call   f0100c82 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01006a2:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f01006a9:	00 
f01006aa:	c7 04 24 14 21 10 f0 	movl   $0xf0102114,(%esp)
f01006b1:	e8 cc 05 00 00       	call   f0100c82 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006b6:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f01006bd:	00 
f01006be:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f01006c5:	f0 
f01006c6:	c7 04 24 3c 21 10 f0 	movl   $0xf010213c,(%esp)
f01006cd:	e8 b0 05 00 00       	call   f0100c82 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006d2:	c7 44 24 08 35 1d 10 	movl   $0x101d35,0x8(%esp)
f01006d9:	00 
f01006da:	c7 44 24 04 35 1d 10 	movl   $0xf0101d35,0x4(%esp)
f01006e1:	f0 
f01006e2:	c7 04 24 60 21 10 f0 	movl   $0xf0102160,(%esp)
f01006e9:	e8 94 05 00 00       	call   f0100c82 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006ee:	c7 44 24 08 20 23 11 	movl   $0x112320,0x8(%esp)
f01006f5:	00 
f01006f6:	c7 44 24 04 20 23 11 	movl   $0xf0112320,0x4(%esp)
f01006fd:	f0 
f01006fe:	c7 04 24 84 21 10 f0 	movl   $0xf0102184,(%esp)
f0100705:	e8 78 05 00 00       	call   f0100c82 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010070a:	c7 44 24 08 64 29 11 	movl   $0x112964,0x8(%esp)
f0100711:	00 
f0100712:	c7 44 24 04 64 29 11 	movl   $0xf0112964,0x4(%esp)
f0100719:	f0 
f010071a:	c7 04 24 a8 21 10 f0 	movl   $0xf01021a8,(%esp)
f0100721:	e8 5c 05 00 00       	call   f0100c82 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f0100726:	b8 63 2d 11 f0       	mov    $0xf0112d63,%eax
f010072b:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
f0100730:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100735:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f010073b:	85 c0                	test   %eax,%eax
f010073d:	0f 48 c2             	cmovs  %edx,%eax
f0100740:	c1 f8 0a             	sar    $0xa,%eax
f0100743:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100747:	c7 04 24 cc 21 10 f0 	movl   $0xf01021cc,(%esp)
f010074e:	e8 2f 05 00 00       	call   f0100c82 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100753:	b8 00 00 00 00       	mov    $0x0,%eax
f0100758:	c9                   	leave  
f0100759:	c3                   	ret    

f010075a <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f010075a:	55                   	push   %ebp
f010075b:	89 e5                	mov    %esp,%ebp
f010075d:	53                   	push   %ebx
f010075e:	83 ec 14             	sub    $0x14,%esp
f0100761:	bb 00 00 00 00       	mov    $0x0,%ebx
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100766:	8b 83 04 23 10 f0    	mov    -0xfefdcfc(%ebx),%eax
f010076c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100770:	8b 83 00 23 10 f0    	mov    -0xfefdd00(%ebx),%eax
f0100776:	89 44 24 04          	mov    %eax,0x4(%esp)
f010077a:	c7 04 24 29 20 10 f0 	movl   $0xf0102029,(%esp)
f0100781:	e8 fc 04 00 00       	call   f0100c82 <cprintf>
f0100786:	83 c3 0c             	add    $0xc,%ebx
int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
	int i;

	for (i = 0; i < NCOMMANDS; i++)
f0100789:	83 fb 30             	cmp    $0x30,%ebx
f010078c:	75 d8                	jne    f0100766 <mon_help+0xc>
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
	return 0;
}
f010078e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100793:	83 c4 14             	add    $0x14,%esp
f0100796:	5b                   	pop    %ebx
f0100797:	5d                   	pop    %ebp
f0100798:	c3                   	ret    

f0100799 <mon_backtrace>:
	return 0;
}

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100799:	55                   	push   %ebp
f010079a:	89 e5                	mov    %esp,%ebp
f010079c:	57                   	push   %edi
f010079d:	56                   	push   %esi
f010079e:	53                   	push   %ebx
f010079f:	83 ec 4c             	sub    $0x4c,%esp

static __inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f01007a2:	89 eb                	mov    %ebp,%ebx
// Your code here.
//	cprintf("%08x", read_ebp());
	uint32_t *eip, *ebp;
	ebp = (uint32_t*) read_ebp();
f01007a4:	89 de                	mov    %ebx,%esi
	eip = (uint32_t*) ebp[1];
f01007a6:	8b 7b 04             	mov    0x4(%ebx),%edi
	cprintf("Stackbacktrace:\n");
f01007a9:	c7 04 24 32 20 10 f0 	movl   $0xf0102032,(%esp)
f01007b0:	e8 cd 04 00 00       	call   f0100c82 <cprintf>
	while (ebp!=0) {
f01007b5:	85 db                	test   %ebx,%ebx
f01007b7:	0f 84 aa 00 00 00    	je     f0100867 <mon_backtrace+0xce>
		cprintf("ebp %08x eip %08x args %08x %08x %08x %08x %08x\n",ebp, eip, ebp[2] ,ebp[3], ebp[4], ebp[5] ,ebp[6]);
f01007bd:	8b 46 18             	mov    0x18(%esi),%eax
f01007c0:	89 44 24 1c          	mov    %eax,0x1c(%esp)
f01007c4:	8b 46 14             	mov    0x14(%esi),%eax
f01007c7:	89 44 24 18          	mov    %eax,0x18(%esp)
f01007cb:	8b 46 10             	mov    0x10(%esi),%eax
f01007ce:	89 44 24 14          	mov    %eax,0x14(%esp)
f01007d2:	8b 46 0c             	mov    0xc(%esi),%eax
f01007d5:	89 44 24 10          	mov    %eax,0x10(%esp)
f01007d9:	8b 46 08             	mov    0x8(%esi),%eax
f01007dc:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01007e0:	89 7c 24 08          	mov    %edi,0x8(%esp)
f01007e4:	89 74 24 04          	mov    %esi,0x4(%esp)
f01007e8:	c7 04 24 f8 21 10 f0 	movl   $0xf01021f8,(%esp)
f01007ef:	e8 8e 04 00 00       	call   f0100c82 <cprintf>
		struct Eipdebuginfo temp_debuginfo;
		debuginfo_eip((uintptr_t) eip, &temp_debuginfo);		
f01007f4:	8d 45 d0             	lea    -0x30(%ebp),%eax
f01007f7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007fb:	89 3c 24             	mov    %edi,(%esp)
f01007fe:	e8 79 05 00 00       	call   f0100d7c <debuginfo_eip>
		cprintf("       %s:%d: ", temp_debuginfo.eip_file, temp_debuginfo.eip_line);
f0100803:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100806:	89 44 24 08          	mov    %eax,0x8(%esp)
f010080a:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010080d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100811:	c7 04 24 43 20 10 f0 	movl   $0xf0102043,(%esp)
f0100818:	e8 65 04 00 00       	call   f0100c82 <cprintf>
		uint32_t i = 0;// = temp_debuginfo.eip_fn_namelen;
		while  (i < temp_debuginfo.eip_fn_namelen){
f010081d:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0100821:	74 24                	je     f0100847 <mon_backtrace+0xae>
	while (ebp!=0) {
		cprintf("ebp %08x eip %08x args %08x %08x %08x %08x %08x\n",ebp, eip, ebp[2] ,ebp[3], ebp[4], ebp[5] ,ebp[6]);
		struct Eipdebuginfo temp_debuginfo;
		debuginfo_eip((uintptr_t) eip, &temp_debuginfo);		
		cprintf("       %s:%d: ", temp_debuginfo.eip_file, temp_debuginfo.eip_line);
		uint32_t i = 0;// = temp_debuginfo.eip_fn_namelen;
f0100823:	bb 00 00 00 00       	mov    $0x0,%ebx
		while  (i < temp_debuginfo.eip_fn_namelen){
			cprintf("%c", temp_debuginfo.eip_fn_name[i]);
f0100828:	8b 45 d8             	mov    -0x28(%ebp),%eax
f010082b:	0f be 04 18          	movsbl (%eax,%ebx,1),%eax
f010082f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100833:	c7 04 24 52 20 10 f0 	movl   $0xf0102052,(%esp)
f010083a:	e8 43 04 00 00       	call   f0100c82 <cprintf>
			i++;	
f010083f:	83 c3 01             	add    $0x1,%ebx
		cprintf("ebp %08x eip %08x args %08x %08x %08x %08x %08x\n",ebp, eip, ebp[2] ,ebp[3], ebp[4], ebp[5] ,ebp[6]);
		struct Eipdebuginfo temp_debuginfo;
		debuginfo_eip((uintptr_t) eip, &temp_debuginfo);		
		cprintf("       %s:%d: ", temp_debuginfo.eip_file, temp_debuginfo.eip_line);
		uint32_t i = 0;// = temp_debuginfo.eip_fn_namelen;
		while  (i < temp_debuginfo.eip_fn_namelen){
f0100842:	39 5d dc             	cmp    %ebx,-0x24(%ebp)
f0100845:	77 e1                	ja     f0100828 <mon_backtrace+0x8f>
			cprintf("%c", temp_debuginfo.eip_fn_name[i]);
			i++;	
		}
		int p = (int)eip;
		int q = (int)temp_debuginfo.eip_fn_addr;
		cprintf("+%x\n", p - q);
f0100847:	2b 7d e0             	sub    -0x20(%ebp),%edi
f010084a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010084e:	c7 04 24 55 20 10 f0 	movl   $0xf0102055,(%esp)
f0100855:	e8 28 04 00 00       	call   f0100c82 <cprintf>
		ebp=(uint32_t*)ebp[0];
f010085a:	8b 36                	mov    (%esi),%esi
		eip=(uint32_t*)ebp[1]; 
f010085c:	8b 7e 04             	mov    0x4(%esi),%edi
//	cprintf("%08x", read_ebp());
	uint32_t *eip, *ebp;
	ebp = (uint32_t*) read_ebp();
	eip = (uint32_t*) ebp[1];
	cprintf("Stackbacktrace:\n");
	while (ebp!=0) {
f010085f:	85 f6                	test   %esi,%esi
f0100861:	0f 85 56 ff ff ff    	jne    f01007bd <mon_backtrace+0x24>
		eip=(uint32_t*)ebp[1]; 
	}
	
//	cprintf("%d", read_esp());
	return 0;
}
f0100867:	b8 00 00 00 00       	mov    $0x0,%eax
f010086c:	83 c4 4c             	add    $0x4c,%esp
f010086f:	5b                   	pop    %ebx
f0100870:	5e                   	pop    %esi
f0100871:	5f                   	pop    %edi
f0100872:	5d                   	pop    %ebp
f0100873:	c3                   	ret    

f0100874 <mon_setcolor>:
	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
	return 0;
}

int mon_setcolor(int argc, char **argv, struct Trapframe *tf) {
f0100874:	55                   	push   %ebp
f0100875:	89 e5                	mov    %esp,%ebp
f0100877:	83 ec 28             	sub    $0x28,%esp
f010087a:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f010087d:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0100880:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0100883:	8b 75 0c             	mov    0xc(%ebp),%esi
	//argv
	uint16_t ch_color1, ch_color;
	if(strcmp(argv[2],"blk")==0)
f0100886:	c7 44 24 04 5a 20 10 	movl   $0xf010205a,0x4(%esp)
f010088d:	f0 
f010088e:	8b 46 08             	mov    0x8(%esi),%eax
f0100891:	89 04 24             	mov    %eax,(%esp)
f0100894:	e8 d2 0e 00 00       	call   f010176b <strcmp>
			ch_color1=COLOR_BLK
f0100899:	bf 00 00 00 00       	mov    $0x0,%edi
}

int mon_setcolor(int argc, char **argv, struct Trapframe *tf) {
	//argv
	uint16_t ch_color1, ch_color;
	if(strcmp(argv[2],"blk")==0)
f010089e:	85 c0                	test   %eax,%eax
f01008a0:	0f 84 0e 01 00 00    	je     f01009b4 <mon_setcolor+0x140>
			ch_color1=COLOR_BLK
	else if(strcmp(argv[2],"wht")==0)
f01008a6:	c7 44 24 04 5e 20 10 	movl   $0xf010205e,0x4(%esp)
f01008ad:	f0 
f01008ae:	8b 46 08             	mov    0x8(%esi),%eax
f01008b1:	89 04 24             	mov    %eax,(%esp)
f01008b4:	e8 b2 0e 00 00       	call   f010176b <strcmp>
			ch_color1=COLOR_WHT
f01008b9:	bf 07 00 00 00       	mov    $0x7,%edi
int mon_setcolor(int argc, char **argv, struct Trapframe *tf) {
	//argv
	uint16_t ch_color1, ch_color;
	if(strcmp(argv[2],"blk")==0)
			ch_color1=COLOR_BLK
	else if(strcmp(argv[2],"wht")==0)
f01008be:	85 c0                	test   %eax,%eax
f01008c0:	0f 84 ee 00 00 00    	je     f01009b4 <mon_setcolor+0x140>
			ch_color1=COLOR_WHT
	else if(strcmp(argv[2],"blu")==0)
f01008c6:	c7 44 24 04 62 20 10 	movl   $0xf0102062,0x4(%esp)
f01008cd:	f0 
f01008ce:	8b 46 08             	mov    0x8(%esi),%eax
f01008d1:	89 04 24             	mov    %eax,(%esp)
f01008d4:	e8 92 0e 00 00       	call   f010176b <strcmp>
			ch_color1=COLOR_BLU
f01008d9:	bf 01 00 00 00       	mov    $0x1,%edi
	uint16_t ch_color1, ch_color;
	if(strcmp(argv[2],"blk")==0)
			ch_color1=COLOR_BLK
	else if(strcmp(argv[2],"wht")==0)
			ch_color1=COLOR_WHT
	else if(strcmp(argv[2],"blu")==0)
f01008de:	85 c0                	test   %eax,%eax
f01008e0:	0f 84 ce 00 00 00    	je     f01009b4 <mon_setcolor+0x140>
			ch_color1=COLOR_BLU
	else if(strcmp(argv[2],"grn")==0)
f01008e6:	c7 44 24 04 66 20 10 	movl   $0xf0102066,0x4(%esp)
f01008ed:	f0 
f01008ee:	8b 46 08             	mov    0x8(%esi),%eax
f01008f1:	89 04 24             	mov    %eax,(%esp)
f01008f4:	e8 72 0e 00 00       	call   f010176b <strcmp>
			ch_color1=COLOR_GRN
f01008f9:	bf 02 00 00 00       	mov    $0x2,%edi
			ch_color1=COLOR_BLK
	else if(strcmp(argv[2],"wht")==0)
			ch_color1=COLOR_WHT
	else if(strcmp(argv[2],"blu")==0)
			ch_color1=COLOR_BLU
	else if(strcmp(argv[2],"grn")==0)
f01008fe:	85 c0                	test   %eax,%eax
f0100900:	0f 84 ae 00 00 00    	je     f01009b4 <mon_setcolor+0x140>
			ch_color1=COLOR_GRN
	else if(strcmp(argv[2],"red")==0)
f0100906:	c7 44 24 04 6a 20 10 	movl   $0xf010206a,0x4(%esp)
f010090d:	f0 
f010090e:	8b 46 08             	mov    0x8(%esi),%eax
f0100911:	89 04 24             	mov    %eax,(%esp)
f0100914:	e8 52 0e 00 00       	call   f010176b <strcmp>
			ch_color1=COLOR_RED
f0100919:	bf 04 00 00 00       	mov    $0x4,%edi
			ch_color1=COLOR_WHT
	else if(strcmp(argv[2],"blu")==0)
			ch_color1=COLOR_BLU
	else if(strcmp(argv[2],"grn")==0)
			ch_color1=COLOR_GRN
	else if(strcmp(argv[2],"red")==0)
f010091e:	85 c0                	test   %eax,%eax
f0100920:	0f 84 8e 00 00 00    	je     f01009b4 <mon_setcolor+0x140>
			ch_color1=COLOR_RED
	else if(strcmp(argv[2],"gry")==0)
f0100926:	c7 44 24 04 6e 20 10 	movl   $0xf010206e,0x4(%esp)
f010092d:	f0 
f010092e:	8b 46 08             	mov    0x8(%esi),%eax
f0100931:	89 04 24             	mov    %eax,(%esp)
f0100934:	e8 32 0e 00 00       	call   f010176b <strcmp>
			ch_color1=COLOR_GRY
f0100939:	bf 08 00 00 00       	mov    $0x8,%edi
			ch_color1=COLOR_BLU
	else if(strcmp(argv[2],"grn")==0)
			ch_color1=COLOR_GRN
	else if(strcmp(argv[2],"red")==0)
			ch_color1=COLOR_RED
	else if(strcmp(argv[2],"gry")==0)
f010093e:	85 c0                	test   %eax,%eax
f0100940:	74 72                	je     f01009b4 <mon_setcolor+0x140>
			ch_color1=COLOR_GRY
	else if(strcmp(argv[2],"ylw")==0)
f0100942:	c7 44 24 04 72 20 10 	movl   $0xf0102072,0x4(%esp)
f0100949:	f0 
f010094a:	8b 46 08             	mov    0x8(%esi),%eax
f010094d:	89 04 24             	mov    %eax,(%esp)
f0100950:	e8 16 0e 00 00       	call   f010176b <strcmp>
			ch_color1=COLOR_YLW
f0100955:	bf 0f 00 00 00       	mov    $0xf,%edi
			ch_color1=COLOR_GRN
	else if(strcmp(argv[2],"red")==0)
			ch_color1=COLOR_RED
	else if(strcmp(argv[2],"gry")==0)
			ch_color1=COLOR_GRY
	else if(strcmp(argv[2],"ylw")==0)
f010095a:	85 c0                	test   %eax,%eax
f010095c:	74 56                	je     f01009b4 <mon_setcolor+0x140>
			ch_color1=COLOR_YLW
	else if(strcmp(argv[2],"org")==0)
f010095e:	c7 44 24 04 76 20 10 	movl   $0xf0102076,0x4(%esp)
f0100965:	f0 
f0100966:	8b 46 08             	mov    0x8(%esi),%eax
f0100969:	89 04 24             	mov    %eax,(%esp)
f010096c:	e8 fa 0d 00 00       	call   f010176b <strcmp>
			ch_color1=COLOR_ORG
f0100971:	bf 0c 00 00 00       	mov    $0xc,%edi
			ch_color1=COLOR_RED
	else if(strcmp(argv[2],"gry")==0)
			ch_color1=COLOR_GRY
	else if(strcmp(argv[2],"ylw")==0)
			ch_color1=COLOR_YLW
	else if(strcmp(argv[2],"org")==0)
f0100976:	85 c0                	test   %eax,%eax
f0100978:	74 3a                	je     f01009b4 <mon_setcolor+0x140>
			ch_color1=COLOR_ORG
	else if(strcmp(argv[2],"pur")==0)
f010097a:	c7 44 24 04 7a 20 10 	movl   $0xf010207a,0x4(%esp)
f0100981:	f0 
f0100982:	8b 46 08             	mov    0x8(%esi),%eax
f0100985:	89 04 24             	mov    %eax,(%esp)
f0100988:	e8 de 0d 00 00       	call   f010176b <strcmp>
			ch_color1=COLOR_PUR
f010098d:	bf 06 00 00 00       	mov    $0x6,%edi
			ch_color1=COLOR_GRY
	else if(strcmp(argv[2],"ylw")==0)
			ch_color1=COLOR_YLW
	else if(strcmp(argv[2],"org")==0)
			ch_color1=COLOR_ORG
	else if(strcmp(argv[2],"pur")==0)
f0100992:	85 c0                	test   %eax,%eax
f0100994:	74 1e                	je     f01009b4 <mon_setcolor+0x140>
			ch_color1=COLOR_PUR
	else if(strcmp(argv[2],"cyn")==0)
f0100996:	c7 44 24 04 7e 20 10 	movl   $0xf010207e,0x4(%esp)
f010099d:	f0 
f010099e:	8b 46 08             	mov    0x8(%esi),%eax
f01009a1:	89 04 24             	mov    %eax,(%esp)
f01009a4:	e8 c2 0d 00 00       	call   f010176b <strcmp>
			ch_color1=COLOR_CYN
f01009a9:	83 f8 01             	cmp    $0x1,%eax
f01009ac:	19 ff                	sbb    %edi,%edi
f01009ae:	83 e7 04             	and    $0x4,%edi
f01009b1:	83 c7 07             	add    $0x7,%edi
	else ch_color1=COLOR_WHT;
	if(strcmp(argv[1],"blk")==0)
f01009b4:	c7 44 24 04 5a 20 10 	movl   $0xf010205a,0x4(%esp)
f01009bb:	f0 
f01009bc:	8b 46 04             	mov    0x4(%esi),%eax
f01009bf:	89 04 24             	mov    %eax,(%esp)
f01009c2:	e8 a4 0d 00 00       	call   f010176b <strcmp>
			ch_color=COLOR_BLK
f01009c7:	bb 00 00 00 00       	mov    $0x0,%ebx
	else if(strcmp(argv[2],"pur")==0)
			ch_color1=COLOR_PUR
	else if(strcmp(argv[2],"cyn")==0)
			ch_color1=COLOR_CYN
	else ch_color1=COLOR_WHT;
	if(strcmp(argv[1],"blk")==0)
f01009cc:	85 c0                	test   %eax,%eax
f01009ce:	0f 84 f6 00 00 00    	je     f0100aca <mon_setcolor+0x256>
			ch_color=COLOR_BLK
	else if(strcmp(argv[1],"wht")==0)
f01009d4:	c7 44 24 04 5e 20 10 	movl   $0xf010205e,0x4(%esp)
f01009db:	f0 
f01009dc:	8b 46 04             	mov    0x4(%esi),%eax
f01009df:	89 04 24             	mov    %eax,(%esp)
f01009e2:	e8 84 0d 00 00       	call   f010176b <strcmp>
			ch_color=COLOR_WHT
f01009e7:	b3 07                	mov    $0x7,%bl
	else if(strcmp(argv[2],"cyn")==0)
			ch_color1=COLOR_CYN
	else ch_color1=COLOR_WHT;
	if(strcmp(argv[1],"blk")==0)
			ch_color=COLOR_BLK
	else if(strcmp(argv[1],"wht")==0)
f01009e9:	85 c0                	test   %eax,%eax
f01009eb:	0f 84 d9 00 00 00    	je     f0100aca <mon_setcolor+0x256>
			ch_color=COLOR_WHT
	else if(strcmp(argv[1],"blu")==0)
f01009f1:	c7 44 24 04 62 20 10 	movl   $0xf0102062,0x4(%esp)
f01009f8:	f0 
f01009f9:	8b 46 04             	mov    0x4(%esi),%eax
f01009fc:	89 04 24             	mov    %eax,(%esp)
f01009ff:	e8 67 0d 00 00       	call   f010176b <strcmp>
			ch_color=COLOR_BLU
f0100a04:	b3 01                	mov    $0x1,%bl
	else ch_color1=COLOR_WHT;
	if(strcmp(argv[1],"blk")==0)
			ch_color=COLOR_BLK
	else if(strcmp(argv[1],"wht")==0)
			ch_color=COLOR_WHT
	else if(strcmp(argv[1],"blu")==0)
f0100a06:	85 c0                	test   %eax,%eax
f0100a08:	0f 84 bc 00 00 00    	je     f0100aca <mon_setcolor+0x256>
			ch_color=COLOR_BLU
	else if(strcmp(argv[1],"grn")==0)
f0100a0e:	c7 44 24 04 66 20 10 	movl   $0xf0102066,0x4(%esp)
f0100a15:	f0 
f0100a16:	8b 46 04             	mov    0x4(%esi),%eax
f0100a19:	89 04 24             	mov    %eax,(%esp)
f0100a1c:	e8 4a 0d 00 00       	call   f010176b <strcmp>
			ch_color=COLOR_GRN
f0100a21:	b3 02                	mov    $0x2,%bl
			ch_color=COLOR_BLK
	else if(strcmp(argv[1],"wht")==0)
			ch_color=COLOR_WHT
	else if(strcmp(argv[1],"blu")==0)
			ch_color=COLOR_BLU
	else if(strcmp(argv[1],"grn")==0)
f0100a23:	85 c0                	test   %eax,%eax
f0100a25:	0f 84 9f 00 00 00    	je     f0100aca <mon_setcolor+0x256>
			ch_color=COLOR_GRN
	else if(strcmp(argv[1],"red")==0)
f0100a2b:	c7 44 24 04 6a 20 10 	movl   $0xf010206a,0x4(%esp)
f0100a32:	f0 
f0100a33:	8b 46 04             	mov    0x4(%esi),%eax
f0100a36:	89 04 24             	mov    %eax,(%esp)
f0100a39:	e8 2d 0d 00 00       	call   f010176b <strcmp>
			ch_color=COLOR_RED
f0100a3e:	b3 04                	mov    $0x4,%bl
			ch_color=COLOR_WHT
	else if(strcmp(argv[1],"blu")==0)
			ch_color=COLOR_BLU
	else if(strcmp(argv[1],"grn")==0)
			ch_color=COLOR_GRN
	else if(strcmp(argv[1],"red")==0)
f0100a40:	85 c0                	test   %eax,%eax
f0100a42:	0f 84 82 00 00 00    	je     f0100aca <mon_setcolor+0x256>
			ch_color=COLOR_RED
	else if(strcmp(argv[1],"gry")==0)
f0100a48:	c7 44 24 04 6e 20 10 	movl   $0xf010206e,0x4(%esp)
f0100a4f:	f0 
f0100a50:	8b 46 04             	mov    0x4(%esi),%eax
f0100a53:	89 04 24             	mov    %eax,(%esp)
f0100a56:	e8 10 0d 00 00       	call   f010176b <strcmp>
			ch_color=COLOR_GRY
f0100a5b:	b3 08                	mov    $0x8,%bl
			ch_color=COLOR_BLU
	else if(strcmp(argv[1],"grn")==0)
			ch_color=COLOR_GRN
	else if(strcmp(argv[1],"red")==0)
			ch_color=COLOR_RED
	else if(strcmp(argv[1],"gry")==0)
f0100a5d:	85 c0                	test   %eax,%eax
f0100a5f:	74 69                	je     f0100aca <mon_setcolor+0x256>
			ch_color=COLOR_GRY
	else if(strcmp(argv[1],"ylw")==0)
f0100a61:	c7 44 24 04 72 20 10 	movl   $0xf0102072,0x4(%esp)
f0100a68:	f0 
f0100a69:	8b 46 04             	mov    0x4(%esi),%eax
f0100a6c:	89 04 24             	mov    %eax,(%esp)
f0100a6f:	e8 f7 0c 00 00       	call   f010176b <strcmp>
			ch_color=COLOR_YLW
f0100a74:	b3 0f                	mov    $0xf,%bl
			ch_color=COLOR_GRN
	else if(strcmp(argv[1],"red")==0)
			ch_color=COLOR_RED
	else if(strcmp(argv[1],"gry")==0)
			ch_color=COLOR_GRY
	else if(strcmp(argv[1],"ylw")==0)
f0100a76:	85 c0                	test   %eax,%eax
f0100a78:	74 50                	je     f0100aca <mon_setcolor+0x256>
			ch_color=COLOR_YLW
	else if(strcmp(argv[1],"org")==0)
f0100a7a:	c7 44 24 04 76 20 10 	movl   $0xf0102076,0x4(%esp)
f0100a81:	f0 
f0100a82:	8b 46 04             	mov    0x4(%esi),%eax
f0100a85:	89 04 24             	mov    %eax,(%esp)
f0100a88:	e8 de 0c 00 00       	call   f010176b <strcmp>
			ch_color=COLOR_ORG
f0100a8d:	b3 0c                	mov    $0xc,%bl
			ch_color=COLOR_RED
	else if(strcmp(argv[1],"gry")==0)
			ch_color=COLOR_GRY
	else if(strcmp(argv[1],"ylw")==0)
			ch_color=COLOR_YLW
	else if(strcmp(argv[1],"org")==0)
f0100a8f:	85 c0                	test   %eax,%eax
f0100a91:	74 37                	je     f0100aca <mon_setcolor+0x256>
			ch_color=COLOR_ORG
	else if(strcmp(argv[1],"pur")==0)
f0100a93:	c7 44 24 04 7a 20 10 	movl   $0xf010207a,0x4(%esp)
f0100a9a:	f0 
f0100a9b:	8b 46 04             	mov    0x4(%esi),%eax
f0100a9e:	89 04 24             	mov    %eax,(%esp)
f0100aa1:	e8 c5 0c 00 00       	call   f010176b <strcmp>
			ch_color=COLOR_PUR
f0100aa6:	b3 06                	mov    $0x6,%bl
			ch_color=COLOR_GRY
	else if(strcmp(argv[1],"ylw")==0)
			ch_color=COLOR_YLW
	else if(strcmp(argv[1],"org")==0)
			ch_color=COLOR_ORG
	else if(strcmp(argv[1],"pur")==0)
f0100aa8:	85 c0                	test   %eax,%eax
f0100aaa:	74 1e                	je     f0100aca <mon_setcolor+0x256>
			ch_color=COLOR_PUR
	else if(strcmp(argv[1],"cyn")==0)
f0100aac:	c7 44 24 04 7e 20 10 	movl   $0xf010207e,0x4(%esp)
f0100ab3:	f0 
f0100ab4:	8b 46 04             	mov    0x4(%esi),%eax
f0100ab7:	89 04 24             	mov    %eax,(%esp)
f0100aba:	e8 ac 0c 00 00       	call   f010176b <strcmp>
			ch_color=COLOR_CYN
f0100abf:	83 f8 01             	cmp    $0x1,%eax
f0100ac2:	19 db                	sbb    %ebx,%ebx
f0100ac4:	83 e3 04             	and    $0x4,%ebx
f0100ac7:	83 c3 07             	add    $0x7,%ebx
	else ch_color=COLOR_WHT;
	set_attribute_color((uint64_t) ch_color, (uint64_t) ch_color1);
f0100aca:	0f b7 f7             	movzwl %di,%esi
f0100acd:	0f b7 db             	movzwl %bx,%ebx
f0100ad0:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100ad4:	89 1c 24             	mov    %ebx,(%esp)
f0100ad7:	e8 fd f9 ff ff       	call   f01004d9 <set_attribute_color>
	cprintf("console back-color :  %d \n        fore-color :  %d\n", ch_color, ch_color1);	
f0100adc:	89 74 24 08          	mov    %esi,0x8(%esp)
f0100ae0:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100ae4:	c7 04 24 2c 22 10 f0 	movl   $0xf010222c,(%esp)
f0100aeb:	e8 92 01 00 00       	call   f0100c82 <cprintf>
	return 0;
}
f0100af0:	b8 00 00 00 00       	mov    $0x0,%eax
f0100af5:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0100af8:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0100afb:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0100afe:	89 ec                	mov    %ebp,%esp
f0100b00:	5d                   	pop    %ebp
f0100b01:	c3                   	ret    

f0100b02 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100b02:	55                   	push   %ebp
f0100b03:	89 e5                	mov    %esp,%ebp
f0100b05:	57                   	push   %edi
f0100b06:	56                   	push   %esi
f0100b07:	53                   	push   %ebx
f0100b08:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100b0b:	c7 04 24 60 22 10 f0 	movl   $0xf0102260,(%esp)
f0100b12:	e8 6b 01 00 00       	call   f0100c82 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100b17:	c7 04 24 84 22 10 f0 	movl   $0xf0102284,(%esp)
f0100b1e:	e8 5f 01 00 00       	call   f0100c82 <cprintf>
  //	cprintf("x %d, y %x, z %d\n", x, y, z);
//	unsigned int i = 0x00646c72;
//	cprintf("H%x Wo%s", 57616, &i);

	while (1) {
		buf = readline("K> ");
f0100b23:	c7 04 24 82 20 10 f0 	movl   $0xf0102082,(%esp)
f0100b2a:	e8 61 0a 00 00       	call   f0101590 <readline>
f0100b2f:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100b31:	85 c0                	test   %eax,%eax
f0100b33:	74 ee                	je     f0100b23 <monitor+0x21>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100b35:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100b3c:	be 00 00 00 00       	mov    $0x0,%esi
f0100b41:	eb 06                	jmp    f0100b49 <monitor+0x47>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100b43:	c6 03 00             	movb   $0x0,(%ebx)
f0100b46:	83 c3 01             	add    $0x1,%ebx
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100b49:	0f b6 03             	movzbl (%ebx),%eax
f0100b4c:	84 c0                	test   %al,%al
f0100b4e:	74 6b                	je     f0100bbb <monitor+0xb9>
f0100b50:	0f be c0             	movsbl %al,%eax
f0100b53:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100b57:	c7 04 24 86 20 10 f0 	movl   $0xf0102086,(%esp)
f0100b5e:	e8 83 0c 00 00       	call   f01017e6 <strchr>
f0100b63:	85 c0                	test   %eax,%eax
f0100b65:	75 dc                	jne    f0100b43 <monitor+0x41>
			*buf++ = 0;
		if (*buf == 0)
f0100b67:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100b6a:	74 4f                	je     f0100bbb <monitor+0xb9>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100b6c:	83 fe 0f             	cmp    $0xf,%esi
f0100b6f:	90                   	nop
f0100b70:	75 16                	jne    f0100b88 <monitor+0x86>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100b72:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f0100b79:	00 
f0100b7a:	c7 04 24 8b 20 10 f0 	movl   $0xf010208b,(%esp)
f0100b81:	e8 fc 00 00 00       	call   f0100c82 <cprintf>
f0100b86:	eb 9b                	jmp    f0100b23 <monitor+0x21>
			return 0;
		}
		argv[argc++] = buf;
f0100b88:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100b8c:	83 c6 01             	add    $0x1,%esi
		while (*buf && !strchr(WHITESPACE, *buf))
f0100b8f:	0f b6 03             	movzbl (%ebx),%eax
f0100b92:	84 c0                	test   %al,%al
f0100b94:	75 0c                	jne    f0100ba2 <monitor+0xa0>
f0100b96:	eb b1                	jmp    f0100b49 <monitor+0x47>
			buf++;
f0100b98:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100b9b:	0f b6 03             	movzbl (%ebx),%eax
f0100b9e:	84 c0                	test   %al,%al
f0100ba0:	74 a7                	je     f0100b49 <monitor+0x47>
f0100ba2:	0f be c0             	movsbl %al,%eax
f0100ba5:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100ba9:	c7 04 24 86 20 10 f0 	movl   $0xf0102086,(%esp)
f0100bb0:	e8 31 0c 00 00       	call   f01017e6 <strchr>
f0100bb5:	85 c0                	test   %eax,%eax
f0100bb7:	74 df                	je     f0100b98 <monitor+0x96>
f0100bb9:	eb 8e                	jmp    f0100b49 <monitor+0x47>
			buf++;
	}
	argv[argc] = 0;
f0100bbb:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100bc2:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100bc3:	85 f6                	test   %esi,%esi
f0100bc5:	0f 84 58 ff ff ff    	je     f0100b23 <monitor+0x21>
f0100bcb:	bb 00 23 10 f0       	mov    $0xf0102300,%ebx
f0100bd0:	bf 00 00 00 00       	mov    $0x0,%edi
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100bd5:	8b 03                	mov    (%ebx),%eax
f0100bd7:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100bdb:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100bde:	89 04 24             	mov    %eax,(%esp)
f0100be1:	e8 85 0b 00 00       	call   f010176b <strcmp>
f0100be6:	85 c0                	test   %eax,%eax
f0100be8:	75 24                	jne    f0100c0e <monitor+0x10c>
			return commands[i].func(argc, argv, tf);
f0100bea:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f0100bed:	8b 55 08             	mov    0x8(%ebp),%edx
f0100bf0:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100bf4:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100bf7:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100bfb:	89 34 24             	mov    %esi,(%esp)
f0100bfe:	ff 14 85 08 23 10 f0 	call   *-0xfefdcf8(,%eax,4)
//	cprintf("H%x Wo%s", 57616, &i);

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100c05:	85 c0                	test   %eax,%eax
f0100c07:	78 28                	js     f0100c31 <monitor+0x12f>
f0100c09:	e9 15 ff ff ff       	jmp    f0100b23 <monitor+0x21>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f0100c0e:	83 c7 01             	add    $0x1,%edi
f0100c11:	83 c3 0c             	add    $0xc,%ebx
f0100c14:	83 ff 04             	cmp    $0x4,%edi
f0100c17:	75 bc                	jne    f0100bd5 <monitor+0xd3>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100c19:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100c1c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100c20:	c7 04 24 a8 20 10 f0 	movl   $0xf01020a8,(%esp)
f0100c27:	e8 56 00 00 00       	call   f0100c82 <cprintf>
f0100c2c:	e9 f2 fe ff ff       	jmp    f0100b23 <monitor+0x21>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100c31:	83 c4 5c             	add    $0x5c,%esp
f0100c34:	5b                   	pop    %ebx
f0100c35:	5e                   	pop    %esi
f0100c36:	5f                   	pop    %edi
f0100c37:	5d                   	pop    %ebp
f0100c38:	c3                   	ret    
f0100c39:	00 00                	add    %al,(%eax)
	...

f0100c3c <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100c3c:	55                   	push   %ebp
f0100c3d:	89 e5                	mov    %esp,%ebp
f0100c3f:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f0100c42:	8b 45 08             	mov    0x8(%ebp),%eax
f0100c45:	89 04 24             	mov    %eax,(%esp)
f0100c48:	e8 0c fa ff ff       	call   f0100659 <cputchar>
	*cnt++;
}
f0100c4d:	c9                   	leave  
f0100c4e:	c3                   	ret    

f0100c4f <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0100c4f:	55                   	push   %ebp
f0100c50:	89 e5                	mov    %esp,%ebp
f0100c52:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f0100c55:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100c5c:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100c5f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100c63:	8b 45 08             	mov    0x8(%ebp),%eax
f0100c66:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100c6a:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100c6d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100c71:	c7 04 24 3c 0c 10 f0 	movl   $0xf0100c3c,(%esp)
f0100c78:	e8 bd 04 00 00       	call   f010113a <vprintfmt>
	return cnt;
}
f0100c7d:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100c80:	c9                   	leave  
f0100c81:	c3                   	ret    

f0100c82 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0100c82:	55                   	push   %ebp
f0100c83:	89 e5                	mov    %esp,%ebp
f0100c85:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0100c88:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0100c8b:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100c8f:	8b 45 08             	mov    0x8(%ebp),%eax
f0100c92:	89 04 24             	mov    %eax,(%esp)
f0100c95:	e8 b5 ff ff ff       	call   f0100c4f <vcprintf>
	va_end(ap);

	return cnt;
}
f0100c9a:	c9                   	leave  
f0100c9b:	c3                   	ret    

f0100c9c <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100c9c:	55                   	push   %ebp
f0100c9d:	89 e5                	mov    %esp,%ebp
f0100c9f:	57                   	push   %edi
f0100ca0:	56                   	push   %esi
f0100ca1:	53                   	push   %ebx
f0100ca2:	83 ec 10             	sub    $0x10,%esp
f0100ca5:	89 c3                	mov    %eax,%ebx
f0100ca7:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0100caa:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0100cad:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100cb0:	8b 0a                	mov    (%edx),%ecx
f0100cb2:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100cb5:	8b 00                	mov    (%eax),%eax
f0100cb7:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100cba:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)

	while (l <= r) {
f0100cc1:	eb 77                	jmp    f0100d3a <stab_binsearch+0x9e>
		int true_m = (l + r) / 2, m = true_m;
f0100cc3:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100cc6:	01 c8                	add    %ecx,%eax
f0100cc8:	bf 02 00 00 00       	mov    $0x2,%edi
f0100ccd:	99                   	cltd   
f0100cce:	f7 ff                	idiv   %edi
f0100cd0:	89 c2                	mov    %eax,%edx

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100cd2:	eb 01                	jmp    f0100cd5 <stab_binsearch+0x39>
			m--;
f0100cd4:	4a                   	dec    %edx

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100cd5:	39 ca                	cmp    %ecx,%edx
f0100cd7:	7c 1d                	jl     f0100cf6 <stab_binsearch+0x5a>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0100cd9:	6b fa 0c             	imul   $0xc,%edx,%edi

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100cdc:	0f b6 7c 3b 04       	movzbl 0x4(%ebx,%edi,1),%edi
f0100ce1:	39 f7                	cmp    %esi,%edi
f0100ce3:	75 ef                	jne    f0100cd4 <stab_binsearch+0x38>
f0100ce5:	89 55 ec             	mov    %edx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100ce8:	6b fa 0c             	imul   $0xc,%edx,%edi
f0100ceb:	8b 7c 3b 08          	mov    0x8(%ebx,%edi,1),%edi
f0100cef:	3b 7d 0c             	cmp    0xc(%ebp),%edi
f0100cf2:	73 18                	jae    f0100d0c <stab_binsearch+0x70>
f0100cf4:	eb 05                	jmp    f0100cfb <stab_binsearch+0x5f>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0100cf6:	8d 48 01             	lea    0x1(%eax),%ecx
			continue;
f0100cf9:	eb 3f                	jmp    f0100d3a <stab_binsearch+0x9e>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0100cfb:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0100cfe:	89 11                	mov    %edx,(%ecx)
			l = true_m + 1;
f0100d00:	8d 48 01             	lea    0x1(%eax),%ecx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100d03:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100d0a:	eb 2e                	jmp    f0100d3a <stab_binsearch+0x9e>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0100d0c:	3b 7d 0c             	cmp    0xc(%ebp),%edi
f0100d0f:	76 15                	jbe    f0100d26 <stab_binsearch+0x8a>
			*region_right = m - 1;
f0100d11:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0100d14:	4f                   	dec    %edi
f0100d15:	89 7d f0             	mov    %edi,-0x10(%ebp)
f0100d18:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100d1b:	89 38                	mov    %edi,(%eax)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100d1d:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100d24:	eb 14                	jmp    f0100d3a <stab_binsearch+0x9e>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100d26:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0100d29:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0100d2c:	89 39                	mov    %edi,(%ecx)
			l = m;
			addr++;
f0100d2e:	ff 45 0c             	incl   0xc(%ebp)
f0100d31:	89 d1                	mov    %edx,%ecx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100d33:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0100d3a:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
f0100d3d:	7e 84                	jle    f0100cc3 <stab_binsearch+0x27>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100d3f:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0100d43:	75 0d                	jne    f0100d52 <stab_binsearch+0xb6>
		*region_right = *region_left - 1;
f0100d45:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100d48:	8b 02                	mov    (%edx),%eax
f0100d4a:	48                   	dec    %eax
f0100d4b:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100d4e:	89 01                	mov    %eax,(%ecx)
f0100d50:	eb 22                	jmp    f0100d74 <stab_binsearch+0xd8>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100d52:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100d55:	8b 01                	mov    (%ecx),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100d57:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100d5a:	8b 0a                	mov    (%edx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100d5c:	eb 01                	jmp    f0100d5f <stab_binsearch+0xc3>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100d5e:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100d5f:	39 c1                	cmp    %eax,%ecx
f0100d61:	7d 0c                	jge    f0100d6f <stab_binsearch+0xd3>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0100d63:	6b d0 0c             	imul   $0xc,%eax,%edx
	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
		     l > *region_left && stabs[l].n_type != type;
f0100d66:	0f b6 54 13 04       	movzbl 0x4(%ebx,%edx,1),%edx
f0100d6b:	39 f2                	cmp    %esi,%edx
f0100d6d:	75 ef                	jne    f0100d5e <stab_binsearch+0xc2>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100d6f:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100d72:	89 02                	mov    %eax,(%edx)
	}
}
f0100d74:	83 c4 10             	add    $0x10,%esp
f0100d77:	5b                   	pop    %ebx
f0100d78:	5e                   	pop    %esi
f0100d79:	5f                   	pop    %edi
f0100d7a:	5d                   	pop    %ebp
f0100d7b:	c3                   	ret    

f0100d7c <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100d7c:	55                   	push   %ebp
f0100d7d:	89 e5                	mov    %esp,%ebp
f0100d7f:	83 ec 58             	sub    $0x58,%esp
f0100d82:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0100d85:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0100d88:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0100d8b:	8b 75 08             	mov    0x8(%ebp),%esi
f0100d8e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100d91:	c7 03 30 23 10 f0    	movl   $0xf0102330,(%ebx)
	info->eip_line = 0;
f0100d97:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100d9e:	c7 43 08 30 23 10 f0 	movl   $0xf0102330,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100da5:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100dac:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100daf:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100db6:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100dbc:	76 12                	jbe    f0100dd0 <debuginfo_eip+0x54>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100dbe:	b8 e4 7f 10 f0       	mov    $0xf0107fe4,%eax
f0100dc3:	3d f5 65 10 f0       	cmp    $0xf01065f5,%eax
f0100dc8:	0f 86 f1 01 00 00    	jbe    f0100fbf <debuginfo_eip+0x243>
f0100dce:	eb 1c                	jmp    f0100dec <debuginfo_eip+0x70>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100dd0:	c7 44 24 08 3a 23 10 	movl   $0xf010233a,0x8(%esp)
f0100dd7:	f0 
f0100dd8:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0100ddf:	00 
f0100de0:	c7 04 24 47 23 10 f0 	movl   $0xf0102347,(%esp)
f0100de7:	e8 0c f3 ff ff       	call   f01000f8 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100dec:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100df1:	80 3d e3 7f 10 f0 00 	cmpb   $0x0,0xf0107fe3
f0100df8:	0f 85 cd 01 00 00    	jne    f0100fcb <debuginfo_eip+0x24f>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100dfe:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100e05:	b8 f4 65 10 f0       	mov    $0xf01065f4,%eax
f0100e0a:	2d 68 25 10 f0       	sub    $0xf0102568,%eax
f0100e0f:	c1 f8 02             	sar    $0x2,%eax
f0100e12:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100e18:	83 e8 01             	sub    $0x1,%eax
f0100e1b:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100e1e:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100e22:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0100e29:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100e2c:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100e2f:	b8 68 25 10 f0       	mov    $0xf0102568,%eax
f0100e34:	e8 63 fe ff ff       	call   f0100c9c <stab_binsearch>
	if (lfile == 0)
f0100e39:	8b 55 e4             	mov    -0x1c(%ebp),%edx
		return -1;
f0100e3c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
f0100e41:	85 d2                	test   %edx,%edx
f0100e43:	0f 84 82 01 00 00    	je     f0100fcb <debuginfo_eip+0x24f>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100e49:	89 55 dc             	mov    %edx,-0x24(%ebp)
	rfun = rfile;
f0100e4c:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100e4f:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100e52:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100e56:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0100e5d:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100e60:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100e63:	b8 68 25 10 f0       	mov    $0xf0102568,%eax
f0100e68:	e8 2f fe ff ff       	call   f0100c9c <stab_binsearch>

	if (lfun <= rfun) {
f0100e6d:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100e70:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100e73:	39 d0                	cmp    %edx,%eax
f0100e75:	7f 3d                	jg     f0100eb4 <debuginfo_eip+0x138>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100e77:	6b c8 0c             	imul   $0xc,%eax,%ecx
f0100e7a:	8d b9 68 25 10 f0    	lea    -0xfefda98(%ecx),%edi
f0100e80:	89 7d c0             	mov    %edi,-0x40(%ebp)
f0100e83:	8b 89 68 25 10 f0    	mov    -0xfefda98(%ecx),%ecx
f0100e89:	bf e4 7f 10 f0       	mov    $0xf0107fe4,%edi
f0100e8e:	81 ef f5 65 10 f0    	sub    $0xf01065f5,%edi
f0100e94:	39 f9                	cmp    %edi,%ecx
f0100e96:	73 09                	jae    f0100ea1 <debuginfo_eip+0x125>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100e98:	81 c1 f5 65 10 f0    	add    $0xf01065f5,%ecx
f0100e9e:	89 4b 08             	mov    %ecx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100ea1:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0100ea4:	8b 4f 08             	mov    0x8(%edi),%ecx
f0100ea7:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0100eaa:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0100eac:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0100eaf:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0100eb2:	eb 0f                	jmp    f0100ec3 <debuginfo_eip+0x147>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100eb4:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100eb7:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100eba:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0100ebd:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100ec0:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100ec3:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0100eca:	00 
f0100ecb:	8b 43 08             	mov    0x8(%ebx),%eax
f0100ece:	89 04 24             	mov    %eax,(%esp)
f0100ed1:	e8 44 09 00 00       	call   f010181a <strfind>
f0100ed6:	2b 43 08             	sub    0x8(%ebx),%eax
f0100ed9:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0100edc:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100ee0:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f0100ee7:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0100eea:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0100eed:	b8 68 25 10 f0       	mov    $0xf0102568,%eax
f0100ef2:	e8 a5 fd ff ff       	call   f0100c9c <stab_binsearch>
	if (lline <= rline) {
f0100ef7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100efa:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0100efd:	7f 0f                	jg     f0100f0e <debuginfo_eip+0x192>
		info->eip_line = stabs[lline].n_desc;
f0100eff:	6b c0 0c             	imul   $0xc,%eax,%eax
f0100f02:	0f b7 80 6e 25 10 f0 	movzwl -0xfefda92(%eax),%eax
f0100f09:	89 43 04             	mov    %eax,0x4(%ebx)
f0100f0c:	eb 07                	jmp    f0100f15 <debuginfo_eip+0x199>
	} else {
		info->eip_line = -1;
f0100f0e:	c7 43 04 ff ff ff ff 	movl   $0xffffffff,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100f15:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100f18:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100f1b:	39 c8                	cmp    %ecx,%eax
f0100f1d:	7c 5f                	jl     f0100f7e <debuginfo_eip+0x202>
	       && stabs[lline].n_type != N_SOL
f0100f1f:	89 c2                	mov    %eax,%edx
f0100f21:	6b f0 0c             	imul   $0xc,%eax,%esi
f0100f24:	80 be 6c 25 10 f0 84 	cmpb   $0x84,-0xfefda94(%esi)
f0100f2b:	75 18                	jne    f0100f45 <debuginfo_eip+0x1c9>
f0100f2d:	eb 30                	jmp    f0100f5f <debuginfo_eip+0x1e3>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0100f2f:	83 e8 01             	sub    $0x1,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100f32:	39 c1                	cmp    %eax,%ecx
f0100f34:	7f 48                	jg     f0100f7e <debuginfo_eip+0x202>
	       && stabs[lline].n_type != N_SOL
f0100f36:	89 c2                	mov    %eax,%edx
f0100f38:	8d 34 40             	lea    (%eax,%eax,2),%esi
f0100f3b:	80 3c b5 6c 25 10 f0 	cmpb   $0x84,-0xfefda94(,%esi,4)
f0100f42:	84 
f0100f43:	74 1a                	je     f0100f5f <debuginfo_eip+0x1e3>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100f45:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0100f48:	8d 14 95 68 25 10 f0 	lea    -0xfefda98(,%edx,4),%edx
f0100f4f:	80 7a 04 64          	cmpb   $0x64,0x4(%edx)
f0100f53:	75 da                	jne    f0100f2f <debuginfo_eip+0x1b3>
f0100f55:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f0100f59:	74 d4                	je     f0100f2f <debuginfo_eip+0x1b3>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100f5b:	39 c8                	cmp    %ecx,%eax
f0100f5d:	7c 1f                	jl     f0100f7e <debuginfo_eip+0x202>
f0100f5f:	6b c0 0c             	imul   $0xc,%eax,%eax
f0100f62:	8b 80 68 25 10 f0    	mov    -0xfefda98(%eax),%eax
f0100f68:	ba e4 7f 10 f0       	mov    $0xf0107fe4,%edx
f0100f6d:	81 ea f5 65 10 f0    	sub    $0xf01065f5,%edx
f0100f73:	39 d0                	cmp    %edx,%eax
f0100f75:	73 07                	jae    f0100f7e <debuginfo_eip+0x202>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100f77:	05 f5 65 10 f0       	add    $0xf01065f5,%eax
f0100f7c:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100f7e:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100f81:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100f84:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100f89:	39 ca                	cmp    %ecx,%edx
f0100f8b:	7d 3e                	jge    f0100fcb <debuginfo_eip+0x24f>
		for (lline = lfun + 1;
f0100f8d:	83 c2 01             	add    $0x1,%edx
f0100f90:	39 d1                	cmp    %edx,%ecx
f0100f92:	7e 37                	jle    f0100fcb <debuginfo_eip+0x24f>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100f94:	6b f2 0c             	imul   $0xc,%edx,%esi
f0100f97:	80 be 6c 25 10 f0 a0 	cmpb   $0xa0,-0xfefda94(%esi)
f0100f9e:	75 2b                	jne    f0100fcb <debuginfo_eip+0x24f>
		     lline++)
			info->eip_fn_narg++;
f0100fa0:	83 43 14 01          	addl   $0x1,0x14(%ebx)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0100fa4:	83 c2 01             	add    $0x1,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100fa7:	39 d1                	cmp    %edx,%ecx
f0100fa9:	7e 1b                	jle    f0100fc6 <debuginfo_eip+0x24a>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100fab:	8d 04 52             	lea    (%edx,%edx,2),%eax
f0100fae:	80 3c 85 6c 25 10 f0 	cmpb   $0xa0,-0xfefda94(,%eax,4)
f0100fb5:	a0 
f0100fb6:	74 e8                	je     f0100fa0 <debuginfo_eip+0x224>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100fb8:	b8 00 00 00 00       	mov    $0x0,%eax
f0100fbd:	eb 0c                	jmp    f0100fcb <debuginfo_eip+0x24f>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100fbf:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100fc4:	eb 05                	jmp    f0100fcb <debuginfo_eip+0x24f>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100fc6:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100fcb:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0100fce:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0100fd1:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0100fd4:	89 ec                	mov    %ebp,%esp
f0100fd6:	5d                   	pop    %ebp
f0100fd7:	c3                   	ret    
	...

f0100fe0 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0100fe0:	55                   	push   %ebp
f0100fe1:	89 e5                	mov    %esp,%ebp
f0100fe3:	57                   	push   %edi
f0100fe4:	56                   	push   %esi
f0100fe5:	53                   	push   %ebx
f0100fe6:	83 ec 3c             	sub    $0x3c,%esp
f0100fe9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100fec:	89 d7                	mov    %edx,%edi
f0100fee:	8b 45 08             	mov    0x8(%ebp),%eax
f0100ff1:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0100ff4:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100ff7:	89 45 e0             	mov    %eax,-0x20(%ebp)
f0100ffa:	8b 5d 14             	mov    0x14(%ebp),%ebx
f0100ffd:	8b 75 18             	mov    0x18(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0101000:	b8 00 00 00 00       	mov    $0x0,%eax
f0101005:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0101008:	72 11                	jb     f010101b <printnum+0x3b>
f010100a:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010100d:	39 45 10             	cmp    %eax,0x10(%ebp)
f0101010:	76 09                	jbe    f010101b <printnum+0x3b>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0101012:	83 eb 01             	sub    $0x1,%ebx
f0101015:	85 db                	test   %ebx,%ebx
f0101017:	7f 51                	jg     f010106a <printnum+0x8a>
f0101019:	eb 5e                	jmp    f0101079 <printnum+0x99>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
f010101b:	89 74 24 10          	mov    %esi,0x10(%esp)
f010101f:	83 eb 01             	sub    $0x1,%ebx
f0101022:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0101026:	8b 45 10             	mov    0x10(%ebp),%eax
f0101029:	89 44 24 08          	mov    %eax,0x8(%esp)
f010102d:	8b 5c 24 08          	mov    0x8(%esp),%ebx
f0101031:	8b 74 24 0c          	mov    0xc(%esp),%esi
f0101035:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f010103c:	00 
f010103d:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0101040:	89 04 24             	mov    %eax,(%esp)
f0101043:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101046:	89 44 24 04          	mov    %eax,0x4(%esp)
f010104a:	e8 41 0a 00 00       	call   f0101a90 <__udivdi3>
f010104f:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0101053:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0101057:	89 04 24             	mov    %eax,(%esp)
f010105a:	89 54 24 04          	mov    %edx,0x4(%esp)
f010105e:	89 fa                	mov    %edi,%edx
f0101060:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101063:	e8 78 ff ff ff       	call   f0100fe0 <printnum>
f0101068:	eb 0f                	jmp    f0101079 <printnum+0x99>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f010106a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010106e:	89 34 24             	mov    %esi,(%esp)
f0101071:	ff 55 e4             	call   *-0x1c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0101074:	83 eb 01             	sub    $0x1,%ebx
f0101077:	75 f1                	jne    f010106a <printnum+0x8a>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0101079:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010107d:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0101081:	8b 45 10             	mov    0x10(%ebp),%eax
f0101084:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101088:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f010108f:	00 
f0101090:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0101093:	89 04 24             	mov    %eax,(%esp)
f0101096:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101099:	89 44 24 04          	mov    %eax,0x4(%esp)
f010109d:	e8 1e 0b 00 00       	call   f0101bc0 <__umoddi3>
f01010a2:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01010a6:	0f be 80 55 23 10 f0 	movsbl -0xfefdcab(%eax),%eax
f01010ad:	89 04 24             	mov    %eax,(%esp)
f01010b0:	ff 55 e4             	call   *-0x1c(%ebp)
}
f01010b3:	83 c4 3c             	add    $0x3c,%esp
f01010b6:	5b                   	pop    %ebx
f01010b7:	5e                   	pop    %esi
f01010b8:	5f                   	pop    %edi
f01010b9:	5d                   	pop    %ebp
f01010ba:	c3                   	ret    

f01010bb <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f01010bb:	55                   	push   %ebp
f01010bc:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f01010be:	83 fa 01             	cmp    $0x1,%edx
f01010c1:	7e 0e                	jle    f01010d1 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f01010c3:	8b 10                	mov    (%eax),%edx
f01010c5:	8d 4a 08             	lea    0x8(%edx),%ecx
f01010c8:	89 08                	mov    %ecx,(%eax)
f01010ca:	8b 02                	mov    (%edx),%eax
f01010cc:	8b 52 04             	mov    0x4(%edx),%edx
f01010cf:	eb 22                	jmp    f01010f3 <getuint+0x38>
	else if (lflag)
f01010d1:	85 d2                	test   %edx,%edx
f01010d3:	74 10                	je     f01010e5 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f01010d5:	8b 10                	mov    (%eax),%edx
f01010d7:	8d 4a 04             	lea    0x4(%edx),%ecx
f01010da:	89 08                	mov    %ecx,(%eax)
f01010dc:	8b 02                	mov    (%edx),%eax
f01010de:	ba 00 00 00 00       	mov    $0x0,%edx
f01010e3:	eb 0e                	jmp    f01010f3 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f01010e5:	8b 10                	mov    (%eax),%edx
f01010e7:	8d 4a 04             	lea    0x4(%edx),%ecx
f01010ea:	89 08                	mov    %ecx,(%eax)
f01010ec:	8b 02                	mov    (%edx),%eax
f01010ee:	ba 00 00 00 00       	mov    $0x0,%edx
}
f01010f3:	5d                   	pop    %ebp
f01010f4:	c3                   	ret    

f01010f5 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f01010f5:	55                   	push   %ebp
f01010f6:	89 e5                	mov    %esp,%ebp
f01010f8:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f01010fb:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f01010ff:	8b 10                	mov    (%eax),%edx
f0101101:	3b 50 04             	cmp    0x4(%eax),%edx
f0101104:	73 0a                	jae    f0101110 <sprintputch+0x1b>
		*b->buf++ = ch;
f0101106:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101109:	88 0a                	mov    %cl,(%edx)
f010110b:	83 c2 01             	add    $0x1,%edx
f010110e:	89 10                	mov    %edx,(%eax)
}
f0101110:	5d                   	pop    %ebp
f0101111:	c3                   	ret    

f0101112 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0101112:	55                   	push   %ebp
f0101113:	89 e5                	mov    %esp,%ebp
f0101115:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f0101118:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f010111b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010111f:	8b 45 10             	mov    0x10(%ebp),%eax
f0101122:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101126:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101129:	89 44 24 04          	mov    %eax,0x4(%esp)
f010112d:	8b 45 08             	mov    0x8(%ebp),%eax
f0101130:	89 04 24             	mov    %eax,(%esp)
f0101133:	e8 02 00 00 00       	call   f010113a <vprintfmt>
	va_end(ap);
}
f0101138:	c9                   	leave  
f0101139:	c3                   	ret    

f010113a <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f010113a:	55                   	push   %ebp
f010113b:	89 e5                	mov    %esp,%ebp
f010113d:	57                   	push   %edi
f010113e:	56                   	push   %esi
f010113f:	53                   	push   %ebx
f0101140:	83 ec 4c             	sub    $0x4c,%esp
f0101143:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101146:	8b 75 10             	mov    0x10(%ebp),%esi
f0101149:	eb 12                	jmp    f010115d <vprintfmt+0x23>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f010114b:	85 c0                	test   %eax,%eax
f010114d:	0f 84 a9 03 00 00    	je     f01014fc <vprintfmt+0x3c2>
				return;
			putch(ch, putdat);
f0101153:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101157:	89 04 24             	mov    %eax,(%esp)
f010115a:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f010115d:	0f b6 06             	movzbl (%esi),%eax
f0101160:	83 c6 01             	add    $0x1,%esi
f0101163:	83 f8 25             	cmp    $0x25,%eax
f0101166:	75 e3                	jne    f010114b <vprintfmt+0x11>
f0101168:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
f010116c:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
f0101173:	bf ff ff ff ff       	mov    $0xffffffff,%edi
f0101178:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
f010117f:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101184:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0101187:	eb 2b                	jmp    f01011b4 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101189:	8b 75 e0             	mov    -0x20(%ebp),%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f010118c:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
f0101190:	eb 22                	jmp    f01011b4 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101192:	8b 75 e0             	mov    -0x20(%ebp),%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0101195:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
f0101199:	eb 19                	jmp    f01011b4 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010119b:	8b 75 e0             	mov    -0x20(%ebp),%esi
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
f010119e:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f01011a5:	eb 0d                	jmp    f01011b4 <vprintfmt+0x7a>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f01011a7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01011aa:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01011ad:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01011b4:	0f b6 06             	movzbl (%esi),%eax
f01011b7:	0f b6 d0             	movzbl %al,%edx
f01011ba:	8d 7e 01             	lea    0x1(%esi),%edi
f01011bd:	89 7d e0             	mov    %edi,-0x20(%ebp)
f01011c0:	83 e8 23             	sub    $0x23,%eax
f01011c3:	3c 55                	cmp    $0x55,%al
f01011c5:	0f 87 0b 03 00 00    	ja     f01014d6 <vprintfmt+0x39c>
f01011cb:	0f b6 c0             	movzbl %al,%eax
f01011ce:	ff 24 85 e4 23 10 f0 	jmp    *-0xfefdc1c(,%eax,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f01011d5:	83 ea 30             	sub    $0x30,%edx
f01011d8:	89 55 d4             	mov    %edx,-0x2c(%ebp)
				ch = *fmt;
f01011db:	0f be 46 01          	movsbl 0x1(%esi),%eax
				if (ch < '0' || ch > '9')
f01011df:	8d 50 d0             	lea    -0x30(%eax),%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01011e2:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
f01011e5:	83 fa 09             	cmp    $0x9,%edx
f01011e8:	77 4a                	ja     f0101234 <vprintfmt+0xfa>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01011ea:	8b 7d d4             	mov    -0x2c(%ebp),%edi
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f01011ed:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
f01011f0:	8d 14 bf             	lea    (%edi,%edi,4),%edx
f01011f3:	8d 7c 50 d0          	lea    -0x30(%eax,%edx,2),%edi
				ch = *fmt;
f01011f7:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f01011fa:	8d 50 d0             	lea    -0x30(%eax),%edx
f01011fd:	83 fa 09             	cmp    $0x9,%edx
f0101200:	76 eb                	jbe    f01011ed <vprintfmt+0xb3>
f0101202:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0101205:	eb 2d                	jmp    f0101234 <vprintfmt+0xfa>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0101207:	8b 45 14             	mov    0x14(%ebp),%eax
f010120a:	8d 50 04             	lea    0x4(%eax),%edx
f010120d:	89 55 14             	mov    %edx,0x14(%ebp)
f0101210:	8b 00                	mov    (%eax),%eax
f0101212:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101215:	8b 75 e0             	mov    -0x20(%ebp),%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0101218:	eb 1a                	jmp    f0101234 <vprintfmt+0xfa>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010121a:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case '*':
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
f010121d:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0101221:	79 91                	jns    f01011b4 <vprintfmt+0x7a>
f0101223:	e9 73 ff ff ff       	jmp    f010119b <vprintfmt+0x61>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101228:	8b 75 e0             	mov    -0x20(%ebp),%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f010122b:	c7 45 dc 01 00 00 00 	movl   $0x1,-0x24(%ebp)
			goto reswitch;
f0101232:	eb 80                	jmp    f01011b4 <vprintfmt+0x7a>

		process_precision:
			if (width < 0)
f0101234:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0101238:	0f 89 76 ff ff ff    	jns    f01011b4 <vprintfmt+0x7a>
f010123e:	e9 64 ff ff ff       	jmp    f01011a7 <vprintfmt+0x6d>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0101243:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101246:	8b 75 e0             	mov    -0x20(%ebp),%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0101249:	e9 66 ff ff ff       	jmp    f01011b4 <vprintfmt+0x7a>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f010124e:	8b 45 14             	mov    0x14(%ebp),%eax
f0101251:	8d 50 04             	lea    0x4(%eax),%edx
f0101254:	89 55 14             	mov    %edx,0x14(%ebp)
f0101257:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010125b:	8b 00                	mov    (%eax),%eax
f010125d:	89 04 24             	mov    %eax,(%esp)
f0101260:	ff 55 08             	call   *0x8(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101263:	8b 75 e0             	mov    -0x20(%ebp),%esi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0101266:	e9 f2 fe ff ff       	jmp    f010115d <vprintfmt+0x23>

		// error message
		case 'e':
			err = va_arg(ap, int);
f010126b:	8b 45 14             	mov    0x14(%ebp),%eax
f010126e:	8d 50 04             	lea    0x4(%eax),%edx
f0101271:	89 55 14             	mov    %edx,0x14(%ebp)
f0101274:	8b 00                	mov    (%eax),%eax
f0101276:	89 c2                	mov    %eax,%edx
f0101278:	c1 fa 1f             	sar    $0x1f,%edx
f010127b:	31 d0                	xor    %edx,%eax
f010127d:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f010127f:	83 f8 06             	cmp    $0x6,%eax
f0101282:	7f 0b                	jg     f010128f <vprintfmt+0x155>
f0101284:	8b 14 85 3c 25 10 f0 	mov    -0xfefdac4(,%eax,4),%edx
f010128b:	85 d2                	test   %edx,%edx
f010128d:	75 23                	jne    f01012b2 <vprintfmt+0x178>
				printfmt(putch, putdat, "error %d", err);
f010128f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101293:	c7 44 24 08 6d 23 10 	movl   $0xf010236d,0x8(%esp)
f010129a:	f0 
f010129b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010129f:	8b 7d 08             	mov    0x8(%ebp),%edi
f01012a2:	89 3c 24             	mov    %edi,(%esp)
f01012a5:	e8 68 fe ff ff       	call   f0101112 <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01012aa:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f01012ad:	e9 ab fe ff ff       	jmp    f010115d <vprintfmt+0x23>
			else
				printfmt(putch, putdat, "%s", p);
f01012b2:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01012b6:	c7 44 24 08 76 23 10 	movl   $0xf0102376,0x8(%esp)
f01012bd:	f0 
f01012be:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01012c2:	8b 7d 08             	mov    0x8(%ebp),%edi
f01012c5:	89 3c 24             	mov    %edi,(%esp)
f01012c8:	e8 45 fe ff ff       	call   f0101112 <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01012cd:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01012d0:	e9 88 fe ff ff       	jmp    f010115d <vprintfmt+0x23>
f01012d5:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01012d8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01012db:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f01012de:	8b 45 14             	mov    0x14(%ebp),%eax
f01012e1:	8d 50 04             	lea    0x4(%eax),%edx
f01012e4:	89 55 14             	mov    %edx,0x14(%ebp)
f01012e7:	8b 30                	mov    (%eax),%esi
				p = "(null)";
f01012e9:	85 f6                	test   %esi,%esi
f01012eb:	ba 66 23 10 f0       	mov    $0xf0102366,%edx
f01012f0:	0f 44 f2             	cmove  %edx,%esi
			if (width > 0 && padc != '-')
f01012f3:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f01012f7:	7e 06                	jle    f01012ff <vprintfmt+0x1c5>
f01012f9:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
f01012fd:	75 10                	jne    f010130f <vprintfmt+0x1d5>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01012ff:	0f be 06             	movsbl (%esi),%eax
f0101302:	83 c6 01             	add    $0x1,%esi
f0101305:	85 c0                	test   %eax,%eax
f0101307:	0f 85 86 00 00 00    	jne    f0101393 <vprintfmt+0x259>
f010130d:	eb 76                	jmp    f0101385 <vprintfmt+0x24b>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010130f:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101313:	89 34 24             	mov    %esi,(%esp)
f0101316:	e8 60 03 00 00       	call   f010167b <strnlen>
f010131b:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f010131e:	29 c2                	sub    %eax,%edx
f0101320:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0101323:	85 d2                	test   %edx,%edx
f0101325:	7e d8                	jle    f01012ff <vprintfmt+0x1c5>
					putch(padc, putdat);
f0101327:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
f010132b:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f010132e:	89 d6                	mov    %edx,%esi
f0101330:	89 7d d0             	mov    %edi,-0x30(%ebp)
f0101333:	89 c7                	mov    %eax,%edi
f0101335:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101339:	89 3c 24             	mov    %edi,(%esp)
f010133c:	ff 55 08             	call   *0x8(%ebp)
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010133f:	83 ee 01             	sub    $0x1,%esi
f0101342:	75 f1                	jne    f0101335 <vprintfmt+0x1fb>
f0101344:	89 75 e4             	mov    %esi,-0x1c(%ebp)
f0101347:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f010134a:	8b 7d d0             	mov    -0x30(%ebp),%edi
f010134d:	eb b0                	jmp    f01012ff <vprintfmt+0x1c5>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f010134f:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0101353:	74 18                	je     f010136d <vprintfmt+0x233>
f0101355:	8d 50 e0             	lea    -0x20(%eax),%edx
f0101358:	83 fa 5e             	cmp    $0x5e,%edx
f010135b:	76 10                	jbe    f010136d <vprintfmt+0x233>
					putch('?', putdat);
f010135d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101361:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0101368:	ff 55 08             	call   *0x8(%ebp)
f010136b:	eb 0a                	jmp    f0101377 <vprintfmt+0x23d>
				else
					putch(ch, putdat);
f010136d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101371:	89 04 24             	mov    %eax,(%esp)
f0101374:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101377:	83 6d e4 01          	subl   $0x1,-0x1c(%ebp)
f010137b:	0f be 06             	movsbl (%esi),%eax
f010137e:	83 c6 01             	add    $0x1,%esi
f0101381:	85 c0                	test   %eax,%eax
f0101383:	75 0e                	jne    f0101393 <vprintfmt+0x259>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101385:	8b 75 e0             	mov    -0x20(%ebp),%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101388:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f010138c:	7f 16                	jg     f01013a4 <vprintfmt+0x26a>
f010138e:	e9 ca fd ff ff       	jmp    f010115d <vprintfmt+0x23>
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101393:	85 ff                	test   %edi,%edi
f0101395:	78 b8                	js     f010134f <vprintfmt+0x215>
f0101397:	83 ef 01             	sub    $0x1,%edi
f010139a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01013a0:	79 ad                	jns    f010134f <vprintfmt+0x215>
f01013a2:	eb e1                	jmp    f0101385 <vprintfmt+0x24b>
f01013a4:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01013a7:	8b 7d 08             	mov    0x8(%ebp),%edi
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f01013aa:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01013ae:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f01013b5:	ff d7                	call   *%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f01013b7:	83 ee 01             	sub    $0x1,%esi
f01013ba:	75 ee                	jne    f01013aa <vprintfmt+0x270>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01013bc:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01013bf:	e9 99 fd ff ff       	jmp    f010115d <vprintfmt+0x23>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f01013c4:	83 f9 01             	cmp    $0x1,%ecx
f01013c7:	7e 10                	jle    f01013d9 <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f01013c9:	8b 45 14             	mov    0x14(%ebp),%eax
f01013cc:	8d 50 08             	lea    0x8(%eax),%edx
f01013cf:	89 55 14             	mov    %edx,0x14(%ebp)
f01013d2:	8b 30                	mov    (%eax),%esi
f01013d4:	8b 78 04             	mov    0x4(%eax),%edi
f01013d7:	eb 26                	jmp    f01013ff <vprintfmt+0x2c5>
	else if (lflag)
f01013d9:	85 c9                	test   %ecx,%ecx
f01013db:	74 12                	je     f01013ef <vprintfmt+0x2b5>
		return va_arg(*ap, long);
f01013dd:	8b 45 14             	mov    0x14(%ebp),%eax
f01013e0:	8d 50 04             	lea    0x4(%eax),%edx
f01013e3:	89 55 14             	mov    %edx,0x14(%ebp)
f01013e6:	8b 30                	mov    (%eax),%esi
f01013e8:	89 f7                	mov    %esi,%edi
f01013ea:	c1 ff 1f             	sar    $0x1f,%edi
f01013ed:	eb 10                	jmp    f01013ff <vprintfmt+0x2c5>
	else
		return va_arg(*ap, int);
f01013ef:	8b 45 14             	mov    0x14(%ebp),%eax
f01013f2:	8d 50 04             	lea    0x4(%eax),%edx
f01013f5:	89 55 14             	mov    %edx,0x14(%ebp)
f01013f8:	8b 30                	mov    (%eax),%esi
f01013fa:	89 f7                	mov    %esi,%edi
f01013fc:	c1 ff 1f             	sar    $0x1f,%edi
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f01013ff:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0101404:	85 ff                	test   %edi,%edi
f0101406:	0f 89 8c 00 00 00    	jns    f0101498 <vprintfmt+0x35e>
				putch('-', putdat);
f010140c:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101410:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f0101417:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f010141a:	f7 de                	neg    %esi
f010141c:	83 d7 00             	adc    $0x0,%edi
f010141f:	f7 df                	neg    %edi
			}
			base = 10;
f0101421:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101426:	eb 70                	jmp    f0101498 <vprintfmt+0x35e>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0101428:	89 ca                	mov    %ecx,%edx
f010142a:	8d 45 14             	lea    0x14(%ebp),%eax
f010142d:	e8 89 fc ff ff       	call   f01010bb <getuint>
f0101432:	89 c6                	mov    %eax,%esi
f0101434:	89 d7                	mov    %edx,%edi
			base = 10;
f0101436:	b8 0a 00 00 00       	mov    $0xa,%eax
			goto number;
f010143b:	eb 5b                	jmp    f0101498 <vprintfmt+0x35e>
			// Replace this with your code.
			//putch('0', putdat);
			//putch('X', putdat);
			//putch('X', putdat);
			//break;
			num = getuint(&ap, lflag);
f010143d:	89 ca                	mov    %ecx,%edx
f010143f:	8d 45 14             	lea    0x14(%ebp),%eax
f0101442:	e8 74 fc ff ff       	call   f01010bb <getuint>
f0101447:	89 c6                	mov    %eax,%esi
f0101449:	89 d7                	mov    %edx,%edi
			base = 8;
f010144b:	b8 08 00 00 00       	mov    $0x8,%eax
			goto number;
f0101450:	eb 46                	jmp    f0101498 <vprintfmt+0x35e>
		// pointer
		case 'p':
			putch('0', putdat);
f0101452:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101456:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f010145d:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f0101460:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101464:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f010146b:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f010146e:	8b 45 14             	mov    0x14(%ebp),%eax
f0101471:	8d 50 04             	lea    0x4(%eax),%edx
f0101474:	89 55 14             	mov    %edx,0x14(%ebp)
			goto number;
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0101477:	8b 30                	mov    (%eax),%esi
f0101479:	bf 00 00 00 00       	mov    $0x0,%edi
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f010147e:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f0101483:	eb 13                	jmp    f0101498 <vprintfmt+0x35e>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0101485:	89 ca                	mov    %ecx,%edx
f0101487:	8d 45 14             	lea    0x14(%ebp),%eax
f010148a:	e8 2c fc ff ff       	call   f01010bb <getuint>
f010148f:	89 c6                	mov    %eax,%esi
f0101491:	89 d7                	mov    %edx,%edi
			base = 16;
f0101493:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f0101498:	0f be 55 d8          	movsbl -0x28(%ebp),%edx
f010149c:	89 54 24 10          	mov    %edx,0x10(%esp)
f01014a0:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01014a3:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01014a7:	89 44 24 08          	mov    %eax,0x8(%esp)
f01014ab:	89 34 24             	mov    %esi,(%esp)
f01014ae:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01014b2:	89 da                	mov    %ebx,%edx
f01014b4:	8b 45 08             	mov    0x8(%ebp),%eax
f01014b7:	e8 24 fb ff ff       	call   f0100fe0 <printnum>
			break;
f01014bc:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01014bf:	e9 99 fc ff ff       	jmp    f010115d <vprintfmt+0x23>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f01014c4:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01014c8:	89 14 24             	mov    %edx,(%esp)
f01014cb:	ff 55 08             	call   *0x8(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01014ce:	8b 75 e0             	mov    -0x20(%ebp),%esi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f01014d1:	e9 87 fc ff ff       	jmp    f010115d <vprintfmt+0x23>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f01014d6:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01014da:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f01014e1:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f01014e4:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
f01014e8:	0f 84 6f fc ff ff    	je     f010115d <vprintfmt+0x23>
f01014ee:	83 ee 01             	sub    $0x1,%esi
f01014f1:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
f01014f5:	75 f7                	jne    f01014ee <vprintfmt+0x3b4>
f01014f7:	e9 61 fc ff ff       	jmp    f010115d <vprintfmt+0x23>
				/* do nothing */;
			break;
		}
	}
}
f01014fc:	83 c4 4c             	add    $0x4c,%esp
f01014ff:	5b                   	pop    %ebx
f0101500:	5e                   	pop    %esi
f0101501:	5f                   	pop    %edi
f0101502:	5d                   	pop    %ebp
f0101503:	c3                   	ret    

f0101504 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0101504:	55                   	push   %ebp
f0101505:	89 e5                	mov    %esp,%ebp
f0101507:	83 ec 28             	sub    $0x28,%esp
f010150a:	8b 45 08             	mov    0x8(%ebp),%eax
f010150d:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0101510:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101513:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0101517:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f010151a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0101521:	85 c0                	test   %eax,%eax
f0101523:	74 30                	je     f0101555 <vsnprintf+0x51>
f0101525:	85 d2                	test   %edx,%edx
f0101527:	7e 2c                	jle    f0101555 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0101529:	8b 45 14             	mov    0x14(%ebp),%eax
f010152c:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101530:	8b 45 10             	mov    0x10(%ebp),%eax
f0101533:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101537:	8d 45 ec             	lea    -0x14(%ebp),%eax
f010153a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010153e:	c7 04 24 f5 10 10 f0 	movl   $0xf01010f5,(%esp)
f0101545:	e8 f0 fb ff ff       	call   f010113a <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f010154a:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010154d:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0101550:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101553:	eb 05                	jmp    f010155a <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0101555:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f010155a:	c9                   	leave  
f010155b:	c3                   	ret    

f010155c <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010155c:	55                   	push   %ebp
f010155d:	89 e5                	mov    %esp,%ebp
f010155f:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0101562:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0101565:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101569:	8b 45 10             	mov    0x10(%ebp),%eax
f010156c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101570:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101573:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101577:	8b 45 08             	mov    0x8(%ebp),%eax
f010157a:	89 04 24             	mov    %eax,(%esp)
f010157d:	e8 82 ff ff ff       	call   f0101504 <vsnprintf>
	va_end(ap);

	return rc;
}
f0101582:	c9                   	leave  
f0101583:	c3                   	ret    
	...

f0101590 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0101590:	55                   	push   %ebp
f0101591:	89 e5                	mov    %esp,%ebp
f0101593:	57                   	push   %edi
f0101594:	56                   	push   %esi
f0101595:	53                   	push   %ebx
f0101596:	83 ec 1c             	sub    $0x1c,%esp
f0101599:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010159c:	85 c0                	test   %eax,%eax
f010159e:	74 10                	je     f01015b0 <readline+0x20>
		cprintf("%s", prompt);
f01015a0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01015a4:	c7 04 24 76 23 10 f0 	movl   $0xf0102376,(%esp)
f01015ab:	e8 d2 f6 ff ff       	call   f0100c82 <cprintf>

	i = 0;
	echoing = iscons(0);
f01015b0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01015b7:	e8 be f0 ff ff       	call   f010067a <iscons>
f01015bc:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f01015be:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f01015c3:	e8 a1 f0 ff ff       	call   f0100669 <getchar>
f01015c8:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01015ca:	85 c0                	test   %eax,%eax
f01015cc:	79 17                	jns    f01015e5 <readline+0x55>
			cprintf("read error: %e\n", c);
f01015ce:	89 44 24 04          	mov    %eax,0x4(%esp)
f01015d2:	c7 04 24 58 25 10 f0 	movl   $0xf0102558,(%esp)
f01015d9:	e8 a4 f6 ff ff       	call   f0100c82 <cprintf>
			return NULL;
f01015de:	b8 00 00 00 00       	mov    $0x0,%eax
f01015e3:	eb 6d                	jmp    f0101652 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01015e5:	83 f8 08             	cmp    $0x8,%eax
f01015e8:	74 05                	je     f01015ef <readline+0x5f>
f01015ea:	83 f8 7f             	cmp    $0x7f,%eax
f01015ed:	75 19                	jne    f0101608 <readline+0x78>
f01015ef:	85 f6                	test   %esi,%esi
f01015f1:	7e 15                	jle    f0101608 <readline+0x78>
			if (echoing)
f01015f3:	85 ff                	test   %edi,%edi
f01015f5:	74 0c                	je     f0101603 <readline+0x73>
				cputchar('\b');
f01015f7:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f01015fe:	e8 56 f0 ff ff       	call   f0100659 <cputchar>
			i--;
f0101603:	83 ee 01             	sub    $0x1,%esi
f0101606:	eb bb                	jmp    f01015c3 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101608:	83 fb 1f             	cmp    $0x1f,%ebx
f010160b:	7e 1f                	jle    f010162c <readline+0x9c>
f010160d:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0101613:	7f 17                	jg     f010162c <readline+0x9c>
			if (echoing)
f0101615:	85 ff                	test   %edi,%edi
f0101617:	74 08                	je     f0101621 <readline+0x91>
				cputchar(c);
f0101619:	89 1c 24             	mov    %ebx,(%esp)
f010161c:	e8 38 f0 ff ff       	call   f0100659 <cputchar>
			buf[i++] = c;
f0101621:	88 9e 60 25 11 f0    	mov    %bl,-0xfeedaa0(%esi)
f0101627:	83 c6 01             	add    $0x1,%esi
f010162a:	eb 97                	jmp    f01015c3 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f010162c:	83 fb 0a             	cmp    $0xa,%ebx
f010162f:	74 05                	je     f0101636 <readline+0xa6>
f0101631:	83 fb 0d             	cmp    $0xd,%ebx
f0101634:	75 8d                	jne    f01015c3 <readline+0x33>
			if (echoing)
f0101636:	85 ff                	test   %edi,%edi
f0101638:	74 0c                	je     f0101646 <readline+0xb6>
				cputchar('\n');
f010163a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0101641:	e8 13 f0 ff ff       	call   f0100659 <cputchar>
			buf[i] = 0;
f0101646:	c6 86 60 25 11 f0 00 	movb   $0x0,-0xfeedaa0(%esi)
			return buf;
f010164d:	b8 60 25 11 f0       	mov    $0xf0112560,%eax
		}
	}
}
f0101652:	83 c4 1c             	add    $0x1c,%esp
f0101655:	5b                   	pop    %ebx
f0101656:	5e                   	pop    %esi
f0101657:	5f                   	pop    %edi
f0101658:	5d                   	pop    %ebp
f0101659:	c3                   	ret    
f010165a:	00 00                	add    %al,(%eax)
f010165c:	00 00                	add    %al,(%eax)
	...

f0101660 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0101660:	55                   	push   %ebp
f0101661:	89 e5                	mov    %esp,%ebp
f0101663:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0101666:	b8 00 00 00 00       	mov    $0x0,%eax
f010166b:	80 3a 00             	cmpb   $0x0,(%edx)
f010166e:	74 09                	je     f0101679 <strlen+0x19>
		n++;
f0101670:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0101673:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0101677:	75 f7                	jne    f0101670 <strlen+0x10>
		n++;
	return n;
}
f0101679:	5d                   	pop    %ebp
f010167a:	c3                   	ret    

f010167b <strnlen>:

int
strnlen(const char *s, size_t size)
{
f010167b:	55                   	push   %ebp
f010167c:	89 e5                	mov    %esp,%ebp
f010167e:	53                   	push   %ebx
f010167f:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0101682:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101685:	b8 00 00 00 00       	mov    $0x0,%eax
f010168a:	85 c9                	test   %ecx,%ecx
f010168c:	74 1a                	je     f01016a8 <strnlen+0x2d>
f010168e:	80 3b 00             	cmpb   $0x0,(%ebx)
f0101691:	74 15                	je     f01016a8 <strnlen+0x2d>
f0101693:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
f0101698:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010169a:	39 ca                	cmp    %ecx,%edx
f010169c:	74 0a                	je     f01016a8 <strnlen+0x2d>
f010169e:	83 c2 01             	add    $0x1,%edx
f01016a1:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
f01016a6:	75 f0                	jne    f0101698 <strnlen+0x1d>
		n++;
	return n;
}
f01016a8:	5b                   	pop    %ebx
f01016a9:	5d                   	pop    %ebp
f01016aa:	c3                   	ret    

f01016ab <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01016ab:	55                   	push   %ebp
f01016ac:	89 e5                	mov    %esp,%ebp
f01016ae:	53                   	push   %ebx
f01016af:	8b 45 08             	mov    0x8(%ebp),%eax
f01016b2:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01016b5:	ba 00 00 00 00       	mov    $0x0,%edx
f01016ba:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f01016be:	88 0c 10             	mov    %cl,(%eax,%edx,1)
f01016c1:	83 c2 01             	add    $0x1,%edx
f01016c4:	84 c9                	test   %cl,%cl
f01016c6:	75 f2                	jne    f01016ba <strcpy+0xf>
		/* do nothing */;
	return ret;
}
f01016c8:	5b                   	pop    %ebx
f01016c9:	5d                   	pop    %ebp
f01016ca:	c3                   	ret    

f01016cb <strcat>:

char *
strcat(char *dst, const char *src)
{
f01016cb:	55                   	push   %ebp
f01016cc:	89 e5                	mov    %esp,%ebp
f01016ce:	53                   	push   %ebx
f01016cf:	83 ec 08             	sub    $0x8,%esp
f01016d2:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01016d5:	89 1c 24             	mov    %ebx,(%esp)
f01016d8:	e8 83 ff ff ff       	call   f0101660 <strlen>
	strcpy(dst + len, src);
f01016dd:	8b 55 0c             	mov    0xc(%ebp),%edx
f01016e0:	89 54 24 04          	mov    %edx,0x4(%esp)
f01016e4:	01 d8                	add    %ebx,%eax
f01016e6:	89 04 24             	mov    %eax,(%esp)
f01016e9:	e8 bd ff ff ff       	call   f01016ab <strcpy>
	return dst;
}
f01016ee:	89 d8                	mov    %ebx,%eax
f01016f0:	83 c4 08             	add    $0x8,%esp
f01016f3:	5b                   	pop    %ebx
f01016f4:	5d                   	pop    %ebp
f01016f5:	c3                   	ret    

f01016f6 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01016f6:	55                   	push   %ebp
f01016f7:	89 e5                	mov    %esp,%ebp
f01016f9:	56                   	push   %esi
f01016fa:	53                   	push   %ebx
f01016fb:	8b 45 08             	mov    0x8(%ebp),%eax
f01016fe:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101701:	8b 75 10             	mov    0x10(%ebp),%esi
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101704:	85 f6                	test   %esi,%esi
f0101706:	74 18                	je     f0101720 <strncpy+0x2a>
f0101708:	b9 00 00 00 00       	mov    $0x0,%ecx
		*dst++ = *src;
f010170d:	0f b6 1a             	movzbl (%edx),%ebx
f0101710:	88 1c 08             	mov    %bl,(%eax,%ecx,1)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0101713:	80 3a 01             	cmpb   $0x1,(%edx)
f0101716:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101719:	83 c1 01             	add    $0x1,%ecx
f010171c:	39 f1                	cmp    %esi,%ecx
f010171e:	75 ed                	jne    f010170d <strncpy+0x17>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0101720:	5b                   	pop    %ebx
f0101721:	5e                   	pop    %esi
f0101722:	5d                   	pop    %ebp
f0101723:	c3                   	ret    

f0101724 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0101724:	55                   	push   %ebp
f0101725:	89 e5                	mov    %esp,%ebp
f0101727:	57                   	push   %edi
f0101728:	56                   	push   %esi
f0101729:	53                   	push   %ebx
f010172a:	8b 7d 08             	mov    0x8(%ebp),%edi
f010172d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101730:	8b 75 10             	mov    0x10(%ebp),%esi
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0101733:	89 f8                	mov    %edi,%eax
f0101735:	85 f6                	test   %esi,%esi
f0101737:	74 2b                	je     f0101764 <strlcpy+0x40>
		while (--size > 0 && *src != '\0')
f0101739:	83 fe 01             	cmp    $0x1,%esi
f010173c:	74 23                	je     f0101761 <strlcpy+0x3d>
f010173e:	0f b6 0b             	movzbl (%ebx),%ecx
f0101741:	84 c9                	test   %cl,%cl
f0101743:	74 1c                	je     f0101761 <strlcpy+0x3d>
	}
	return ret;
}

size_t
strlcpy(char *dst, const char *src, size_t size)
f0101745:	83 ee 02             	sub    $0x2,%esi
f0101748:	ba 00 00 00 00       	mov    $0x0,%edx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f010174d:	88 08                	mov    %cl,(%eax)
f010174f:	83 c0 01             	add    $0x1,%eax
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0101752:	39 f2                	cmp    %esi,%edx
f0101754:	74 0b                	je     f0101761 <strlcpy+0x3d>
f0101756:	83 c2 01             	add    $0x1,%edx
f0101759:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f010175d:	84 c9                	test   %cl,%cl
f010175f:	75 ec                	jne    f010174d <strlcpy+0x29>
			*dst++ = *src++;
		*dst = '\0';
f0101761:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0101764:	29 f8                	sub    %edi,%eax
}
f0101766:	5b                   	pop    %ebx
f0101767:	5e                   	pop    %esi
f0101768:	5f                   	pop    %edi
f0101769:	5d                   	pop    %ebp
f010176a:	c3                   	ret    

f010176b <strcmp>:

int
strcmp(const char *p, const char *q)
{
f010176b:	55                   	push   %ebp
f010176c:	89 e5                	mov    %esp,%ebp
f010176e:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101771:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0101774:	0f b6 01             	movzbl (%ecx),%eax
f0101777:	84 c0                	test   %al,%al
f0101779:	74 16                	je     f0101791 <strcmp+0x26>
f010177b:	3a 02                	cmp    (%edx),%al
f010177d:	75 12                	jne    f0101791 <strcmp+0x26>
		p++, q++;
f010177f:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0101782:	0f b6 41 01          	movzbl 0x1(%ecx),%eax
f0101786:	84 c0                	test   %al,%al
f0101788:	74 07                	je     f0101791 <strcmp+0x26>
f010178a:	83 c1 01             	add    $0x1,%ecx
f010178d:	3a 02                	cmp    (%edx),%al
f010178f:	74 ee                	je     f010177f <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0101791:	0f b6 c0             	movzbl %al,%eax
f0101794:	0f b6 12             	movzbl (%edx),%edx
f0101797:	29 d0                	sub    %edx,%eax
}
f0101799:	5d                   	pop    %ebp
f010179a:	c3                   	ret    

f010179b <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f010179b:	55                   	push   %ebp
f010179c:	89 e5                	mov    %esp,%ebp
f010179e:	53                   	push   %ebx
f010179f:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01017a2:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01017a5:	8b 55 10             	mov    0x10(%ebp),%edx
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f01017a8:	b8 00 00 00 00       	mov    $0x0,%eax
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01017ad:	85 d2                	test   %edx,%edx
f01017af:	74 28                	je     f01017d9 <strncmp+0x3e>
f01017b1:	0f b6 01             	movzbl (%ecx),%eax
f01017b4:	84 c0                	test   %al,%al
f01017b6:	74 24                	je     f01017dc <strncmp+0x41>
f01017b8:	3a 03                	cmp    (%ebx),%al
f01017ba:	75 20                	jne    f01017dc <strncmp+0x41>
f01017bc:	83 ea 01             	sub    $0x1,%edx
f01017bf:	74 13                	je     f01017d4 <strncmp+0x39>
		n--, p++, q++;
f01017c1:	83 c1 01             	add    $0x1,%ecx
f01017c4:	83 c3 01             	add    $0x1,%ebx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01017c7:	0f b6 01             	movzbl (%ecx),%eax
f01017ca:	84 c0                	test   %al,%al
f01017cc:	74 0e                	je     f01017dc <strncmp+0x41>
f01017ce:	3a 03                	cmp    (%ebx),%al
f01017d0:	74 ea                	je     f01017bc <strncmp+0x21>
f01017d2:	eb 08                	jmp    f01017dc <strncmp+0x41>
		n--, p++, q++;
	if (n == 0)
		return 0;
f01017d4:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01017d9:	5b                   	pop    %ebx
f01017da:	5d                   	pop    %ebp
f01017db:	c3                   	ret    
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01017dc:	0f b6 01             	movzbl (%ecx),%eax
f01017df:	0f b6 13             	movzbl (%ebx),%edx
f01017e2:	29 d0                	sub    %edx,%eax
f01017e4:	eb f3                	jmp    f01017d9 <strncmp+0x3e>

f01017e6 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01017e6:	55                   	push   %ebp
f01017e7:	89 e5                	mov    %esp,%ebp
f01017e9:	8b 45 08             	mov    0x8(%ebp),%eax
f01017ec:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01017f0:	0f b6 10             	movzbl (%eax),%edx
f01017f3:	84 d2                	test   %dl,%dl
f01017f5:	74 1c                	je     f0101813 <strchr+0x2d>
		if (*s == c)
f01017f7:	38 ca                	cmp    %cl,%dl
f01017f9:	75 09                	jne    f0101804 <strchr+0x1e>
f01017fb:	eb 1b                	jmp    f0101818 <strchr+0x32>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01017fd:	83 c0 01             	add    $0x1,%eax
		if (*s == c)
f0101800:	38 ca                	cmp    %cl,%dl
f0101802:	74 14                	je     f0101818 <strchr+0x32>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0101804:	0f b6 50 01          	movzbl 0x1(%eax),%edx
f0101808:	84 d2                	test   %dl,%dl
f010180a:	75 f1                	jne    f01017fd <strchr+0x17>
		if (*s == c)
			return (char *) s;
	return 0;
f010180c:	b8 00 00 00 00       	mov    $0x0,%eax
f0101811:	eb 05                	jmp    f0101818 <strchr+0x32>
f0101813:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101818:	5d                   	pop    %ebp
f0101819:	c3                   	ret    

f010181a <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010181a:	55                   	push   %ebp
f010181b:	89 e5                	mov    %esp,%ebp
f010181d:	8b 45 08             	mov    0x8(%ebp),%eax
f0101820:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101824:	0f b6 10             	movzbl (%eax),%edx
f0101827:	84 d2                	test   %dl,%dl
f0101829:	74 14                	je     f010183f <strfind+0x25>
		if (*s == c)
f010182b:	38 ca                	cmp    %cl,%dl
f010182d:	75 06                	jne    f0101835 <strfind+0x1b>
f010182f:	eb 0e                	jmp    f010183f <strfind+0x25>
f0101831:	38 ca                	cmp    %cl,%dl
f0101833:	74 0a                	je     f010183f <strfind+0x25>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f0101835:	83 c0 01             	add    $0x1,%eax
f0101838:	0f b6 10             	movzbl (%eax),%edx
f010183b:	84 d2                	test   %dl,%dl
f010183d:	75 f2                	jne    f0101831 <strfind+0x17>
		if (*s == c)
			break;
	return (char *) s;
}
f010183f:	5d                   	pop    %ebp
f0101840:	c3                   	ret    

f0101841 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0101841:	55                   	push   %ebp
f0101842:	89 e5                	mov    %esp,%ebp
f0101844:	83 ec 0c             	sub    $0xc,%esp
f0101847:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f010184a:	89 75 f8             	mov    %esi,-0x8(%ebp)
f010184d:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0101850:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101853:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101856:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0101859:	85 c9                	test   %ecx,%ecx
f010185b:	74 30                	je     f010188d <memset+0x4c>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f010185d:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0101863:	75 25                	jne    f010188a <memset+0x49>
f0101865:	f6 c1 03             	test   $0x3,%cl
f0101868:	75 20                	jne    f010188a <memset+0x49>
		c &= 0xFF;
f010186a:	0f b6 d0             	movzbl %al,%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f010186d:	89 d3                	mov    %edx,%ebx
f010186f:	c1 e3 08             	shl    $0x8,%ebx
f0101872:	89 d6                	mov    %edx,%esi
f0101874:	c1 e6 18             	shl    $0x18,%esi
f0101877:	89 d0                	mov    %edx,%eax
f0101879:	c1 e0 10             	shl    $0x10,%eax
f010187c:	09 f0                	or     %esi,%eax
f010187e:	09 d0                	or     %edx,%eax
f0101880:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0101882:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f0101885:	fc                   	cld    
f0101886:	f3 ab                	rep stos %eax,%es:(%edi)
f0101888:	eb 03                	jmp    f010188d <memset+0x4c>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f010188a:	fc                   	cld    
f010188b:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f010188d:	89 f8                	mov    %edi,%eax
f010188f:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0101892:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0101895:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0101898:	89 ec                	mov    %ebp,%esp
f010189a:	5d                   	pop    %ebp
f010189b:	c3                   	ret    

f010189c <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f010189c:	55                   	push   %ebp
f010189d:	89 e5                	mov    %esp,%ebp
f010189f:	83 ec 08             	sub    $0x8,%esp
f01018a2:	89 75 f8             	mov    %esi,-0x8(%ebp)
f01018a5:	89 7d fc             	mov    %edi,-0x4(%ebp)
f01018a8:	8b 45 08             	mov    0x8(%ebp),%eax
f01018ab:	8b 75 0c             	mov    0xc(%ebp),%esi
f01018ae:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01018b1:	39 c6                	cmp    %eax,%esi
f01018b3:	73 36                	jae    f01018eb <memmove+0x4f>
f01018b5:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01018b8:	39 d0                	cmp    %edx,%eax
f01018ba:	73 2f                	jae    f01018eb <memmove+0x4f>
		s += n;
		d += n;
f01018bc:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01018bf:	f6 c2 03             	test   $0x3,%dl
f01018c2:	75 1b                	jne    f01018df <memmove+0x43>
f01018c4:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01018ca:	75 13                	jne    f01018df <memmove+0x43>
f01018cc:	f6 c1 03             	test   $0x3,%cl
f01018cf:	75 0e                	jne    f01018df <memmove+0x43>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f01018d1:	83 ef 04             	sub    $0x4,%edi
f01018d4:	8d 72 fc             	lea    -0x4(%edx),%esi
f01018d7:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f01018da:	fd                   	std    
f01018db:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01018dd:	eb 09                	jmp    f01018e8 <memmove+0x4c>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f01018df:	83 ef 01             	sub    $0x1,%edi
f01018e2:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01018e5:	fd                   	std    
f01018e6:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01018e8:	fc                   	cld    
f01018e9:	eb 20                	jmp    f010190b <memmove+0x6f>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01018eb:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01018f1:	75 13                	jne    f0101906 <memmove+0x6a>
f01018f3:	a8 03                	test   $0x3,%al
f01018f5:	75 0f                	jne    f0101906 <memmove+0x6a>
f01018f7:	f6 c1 03             	test   $0x3,%cl
f01018fa:	75 0a                	jne    f0101906 <memmove+0x6a>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f01018fc:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f01018ff:	89 c7                	mov    %eax,%edi
f0101901:	fc                   	cld    
f0101902:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101904:	eb 05                	jmp    f010190b <memmove+0x6f>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0101906:	89 c7                	mov    %eax,%edi
f0101908:	fc                   	cld    
f0101909:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f010190b:	8b 75 f8             	mov    -0x8(%ebp),%esi
f010190e:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0101911:	89 ec                	mov    %ebp,%esp
f0101913:	5d                   	pop    %ebp
f0101914:	c3                   	ret    

f0101915 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0101915:	55                   	push   %ebp
f0101916:	89 e5                	mov    %esp,%ebp
f0101918:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f010191b:	8b 45 10             	mov    0x10(%ebp),%eax
f010191e:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101922:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101925:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101929:	8b 45 08             	mov    0x8(%ebp),%eax
f010192c:	89 04 24             	mov    %eax,(%esp)
f010192f:	e8 68 ff ff ff       	call   f010189c <memmove>
}
f0101934:	c9                   	leave  
f0101935:	c3                   	ret    

f0101936 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0101936:	55                   	push   %ebp
f0101937:	89 e5                	mov    %esp,%ebp
f0101939:	57                   	push   %edi
f010193a:	56                   	push   %esi
f010193b:	53                   	push   %ebx
f010193c:	8b 5d 08             	mov    0x8(%ebp),%ebx
f010193f:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101942:	8b 7d 10             	mov    0x10(%ebp),%edi
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0101945:	b8 00 00 00 00       	mov    $0x0,%eax
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010194a:	85 ff                	test   %edi,%edi
f010194c:	74 37                	je     f0101985 <memcmp+0x4f>
		if (*s1 != *s2)
f010194e:	0f b6 03             	movzbl (%ebx),%eax
f0101951:	0f b6 0e             	movzbl (%esi),%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101954:	83 ef 01             	sub    $0x1,%edi
f0101957:	ba 00 00 00 00       	mov    $0x0,%edx
		if (*s1 != *s2)
f010195c:	38 c8                	cmp    %cl,%al
f010195e:	74 1c                	je     f010197c <memcmp+0x46>
f0101960:	eb 10                	jmp    f0101972 <memcmp+0x3c>
f0101962:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
f0101967:	83 c2 01             	add    $0x1,%edx
f010196a:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
f010196e:	38 c8                	cmp    %cl,%al
f0101970:	74 0a                	je     f010197c <memcmp+0x46>
			return (int) *s1 - (int) *s2;
f0101972:	0f b6 c0             	movzbl %al,%eax
f0101975:	0f b6 c9             	movzbl %cl,%ecx
f0101978:	29 c8                	sub    %ecx,%eax
f010197a:	eb 09                	jmp    f0101985 <memcmp+0x4f>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010197c:	39 fa                	cmp    %edi,%edx
f010197e:	75 e2                	jne    f0101962 <memcmp+0x2c>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0101980:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101985:	5b                   	pop    %ebx
f0101986:	5e                   	pop    %esi
f0101987:	5f                   	pop    %edi
f0101988:	5d                   	pop    %ebp
f0101989:	c3                   	ret    

f010198a <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f010198a:	55                   	push   %ebp
f010198b:	89 e5                	mov    %esp,%ebp
f010198d:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0101990:	89 c2                	mov    %eax,%edx
f0101992:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0101995:	39 d0                	cmp    %edx,%eax
f0101997:	73 19                	jae    f01019b2 <memfind+0x28>
		if (*(const unsigned char *) s == (unsigned char) c)
f0101999:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
f010199d:	38 08                	cmp    %cl,(%eax)
f010199f:	75 06                	jne    f01019a7 <memfind+0x1d>
f01019a1:	eb 0f                	jmp    f01019b2 <memfind+0x28>
f01019a3:	38 08                	cmp    %cl,(%eax)
f01019a5:	74 0b                	je     f01019b2 <memfind+0x28>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01019a7:	83 c0 01             	add    $0x1,%eax
f01019aa:	39 d0                	cmp    %edx,%eax
f01019ac:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01019b0:	75 f1                	jne    f01019a3 <memfind+0x19>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01019b2:	5d                   	pop    %ebp
f01019b3:	c3                   	ret    

f01019b4 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01019b4:	55                   	push   %ebp
f01019b5:	89 e5                	mov    %esp,%ebp
f01019b7:	57                   	push   %edi
f01019b8:	56                   	push   %esi
f01019b9:	53                   	push   %ebx
f01019ba:	8b 55 08             	mov    0x8(%ebp),%edx
f01019bd:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01019c0:	0f b6 02             	movzbl (%edx),%eax
f01019c3:	3c 20                	cmp    $0x20,%al
f01019c5:	74 04                	je     f01019cb <strtol+0x17>
f01019c7:	3c 09                	cmp    $0x9,%al
f01019c9:	75 0e                	jne    f01019d9 <strtol+0x25>
		s++;
f01019cb:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01019ce:	0f b6 02             	movzbl (%edx),%eax
f01019d1:	3c 20                	cmp    $0x20,%al
f01019d3:	74 f6                	je     f01019cb <strtol+0x17>
f01019d5:	3c 09                	cmp    $0x9,%al
f01019d7:	74 f2                	je     f01019cb <strtol+0x17>
		s++;

	// plus/minus sign
	if (*s == '+')
f01019d9:	3c 2b                	cmp    $0x2b,%al
f01019db:	75 0a                	jne    f01019e7 <strtol+0x33>
		s++;
f01019dd:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01019e0:	bf 00 00 00 00       	mov    $0x0,%edi
f01019e5:	eb 10                	jmp    f01019f7 <strtol+0x43>
f01019e7:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f01019ec:	3c 2d                	cmp    $0x2d,%al
f01019ee:	75 07                	jne    f01019f7 <strtol+0x43>
		s++, neg = 1;
f01019f0:	83 c2 01             	add    $0x1,%edx
f01019f3:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01019f7:	85 db                	test   %ebx,%ebx
f01019f9:	0f 94 c0             	sete   %al
f01019fc:	74 05                	je     f0101a03 <strtol+0x4f>
f01019fe:	83 fb 10             	cmp    $0x10,%ebx
f0101a01:	75 15                	jne    f0101a18 <strtol+0x64>
f0101a03:	80 3a 30             	cmpb   $0x30,(%edx)
f0101a06:	75 10                	jne    f0101a18 <strtol+0x64>
f0101a08:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0101a0c:	75 0a                	jne    f0101a18 <strtol+0x64>
		s += 2, base = 16;
f0101a0e:	83 c2 02             	add    $0x2,%edx
f0101a11:	bb 10 00 00 00       	mov    $0x10,%ebx
f0101a16:	eb 13                	jmp    f0101a2b <strtol+0x77>
	else if (base == 0 && s[0] == '0')
f0101a18:	84 c0                	test   %al,%al
f0101a1a:	74 0f                	je     f0101a2b <strtol+0x77>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0101a1c:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101a21:	80 3a 30             	cmpb   $0x30,(%edx)
f0101a24:	75 05                	jne    f0101a2b <strtol+0x77>
		s++, base = 8;
f0101a26:	83 c2 01             	add    $0x1,%edx
f0101a29:	b3 08                	mov    $0x8,%bl
	else if (base == 0)
		base = 10;
f0101a2b:	b8 00 00 00 00       	mov    $0x0,%eax
f0101a30:	89 de                	mov    %ebx,%esi

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0101a32:	0f b6 0a             	movzbl (%edx),%ecx
f0101a35:	8d 59 d0             	lea    -0x30(%ecx),%ebx
f0101a38:	80 fb 09             	cmp    $0x9,%bl
f0101a3b:	77 08                	ja     f0101a45 <strtol+0x91>
			dig = *s - '0';
f0101a3d:	0f be c9             	movsbl %cl,%ecx
f0101a40:	83 e9 30             	sub    $0x30,%ecx
f0101a43:	eb 1e                	jmp    f0101a63 <strtol+0xaf>
		else if (*s >= 'a' && *s <= 'z')
f0101a45:	8d 59 9f             	lea    -0x61(%ecx),%ebx
f0101a48:	80 fb 19             	cmp    $0x19,%bl
f0101a4b:	77 08                	ja     f0101a55 <strtol+0xa1>
			dig = *s - 'a' + 10;
f0101a4d:	0f be c9             	movsbl %cl,%ecx
f0101a50:	83 e9 57             	sub    $0x57,%ecx
f0101a53:	eb 0e                	jmp    f0101a63 <strtol+0xaf>
		else if (*s >= 'A' && *s <= 'Z')
f0101a55:	8d 59 bf             	lea    -0x41(%ecx),%ebx
f0101a58:	80 fb 19             	cmp    $0x19,%bl
f0101a5b:	77 14                	ja     f0101a71 <strtol+0xbd>
			dig = *s - 'A' + 10;
f0101a5d:	0f be c9             	movsbl %cl,%ecx
f0101a60:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0101a63:	39 f1                	cmp    %esi,%ecx
f0101a65:	7d 0e                	jge    f0101a75 <strtol+0xc1>
			break;
		s++, val = (val * base) + dig;
f0101a67:	83 c2 01             	add    $0x1,%edx
f0101a6a:	0f af c6             	imul   %esi,%eax
f0101a6d:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
f0101a6f:	eb c1                	jmp    f0101a32 <strtol+0x7e>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
f0101a71:	89 c1                	mov    %eax,%ecx
f0101a73:	eb 02                	jmp    f0101a77 <strtol+0xc3>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0101a75:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
f0101a77:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0101a7b:	74 05                	je     f0101a82 <strtol+0xce>
		*endptr = (char *) s;
f0101a7d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101a80:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
f0101a82:	89 ca                	mov    %ecx,%edx
f0101a84:	f7 da                	neg    %edx
f0101a86:	85 ff                	test   %edi,%edi
f0101a88:	0f 45 c2             	cmovne %edx,%eax
}
f0101a8b:	5b                   	pop    %ebx
f0101a8c:	5e                   	pop    %esi
f0101a8d:	5f                   	pop    %edi
f0101a8e:	5d                   	pop    %ebp
f0101a8f:	c3                   	ret    

f0101a90 <__udivdi3>:
f0101a90:	83 ec 1c             	sub    $0x1c,%esp
f0101a93:	89 7c 24 14          	mov    %edi,0x14(%esp)
f0101a97:	8b 7c 24 2c          	mov    0x2c(%esp),%edi
f0101a9b:	8b 44 24 20          	mov    0x20(%esp),%eax
f0101a9f:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0101aa3:	89 74 24 10          	mov    %esi,0x10(%esp)
f0101aa7:	8b 74 24 24          	mov    0x24(%esp),%esi
f0101aab:	85 ff                	test   %edi,%edi
f0101aad:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f0101ab1:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101ab5:	89 cd                	mov    %ecx,%ebp
f0101ab7:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101abb:	75 33                	jne    f0101af0 <__udivdi3+0x60>
f0101abd:	39 f1                	cmp    %esi,%ecx
f0101abf:	77 57                	ja     f0101b18 <__udivdi3+0x88>
f0101ac1:	85 c9                	test   %ecx,%ecx
f0101ac3:	75 0b                	jne    f0101ad0 <__udivdi3+0x40>
f0101ac5:	b8 01 00 00 00       	mov    $0x1,%eax
f0101aca:	31 d2                	xor    %edx,%edx
f0101acc:	f7 f1                	div    %ecx
f0101ace:	89 c1                	mov    %eax,%ecx
f0101ad0:	89 f0                	mov    %esi,%eax
f0101ad2:	31 d2                	xor    %edx,%edx
f0101ad4:	f7 f1                	div    %ecx
f0101ad6:	89 c6                	mov    %eax,%esi
f0101ad8:	8b 44 24 04          	mov    0x4(%esp),%eax
f0101adc:	f7 f1                	div    %ecx
f0101ade:	89 f2                	mov    %esi,%edx
f0101ae0:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101ae4:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101ae8:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101aec:	83 c4 1c             	add    $0x1c,%esp
f0101aef:	c3                   	ret    
f0101af0:	31 d2                	xor    %edx,%edx
f0101af2:	31 c0                	xor    %eax,%eax
f0101af4:	39 f7                	cmp    %esi,%edi
f0101af6:	77 e8                	ja     f0101ae0 <__udivdi3+0x50>
f0101af8:	0f bd cf             	bsr    %edi,%ecx
f0101afb:	83 f1 1f             	xor    $0x1f,%ecx
f0101afe:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0101b02:	75 2c                	jne    f0101b30 <__udivdi3+0xa0>
f0101b04:	3b 6c 24 08          	cmp    0x8(%esp),%ebp
f0101b08:	76 04                	jbe    f0101b0e <__udivdi3+0x7e>
f0101b0a:	39 f7                	cmp    %esi,%edi
f0101b0c:	73 d2                	jae    f0101ae0 <__udivdi3+0x50>
f0101b0e:	31 d2                	xor    %edx,%edx
f0101b10:	b8 01 00 00 00       	mov    $0x1,%eax
f0101b15:	eb c9                	jmp    f0101ae0 <__udivdi3+0x50>
f0101b17:	90                   	nop
f0101b18:	89 f2                	mov    %esi,%edx
f0101b1a:	f7 f1                	div    %ecx
f0101b1c:	31 d2                	xor    %edx,%edx
f0101b1e:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101b22:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101b26:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101b2a:	83 c4 1c             	add    $0x1c,%esp
f0101b2d:	c3                   	ret    
f0101b2e:	66 90                	xchg   %ax,%ax
f0101b30:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101b35:	b8 20 00 00 00       	mov    $0x20,%eax
f0101b3a:	89 ea                	mov    %ebp,%edx
f0101b3c:	2b 44 24 04          	sub    0x4(%esp),%eax
f0101b40:	d3 e7                	shl    %cl,%edi
f0101b42:	89 c1                	mov    %eax,%ecx
f0101b44:	d3 ea                	shr    %cl,%edx
f0101b46:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101b4b:	09 fa                	or     %edi,%edx
f0101b4d:	89 f7                	mov    %esi,%edi
f0101b4f:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101b53:	89 f2                	mov    %esi,%edx
f0101b55:	8b 74 24 08          	mov    0x8(%esp),%esi
f0101b59:	d3 e5                	shl    %cl,%ebp
f0101b5b:	89 c1                	mov    %eax,%ecx
f0101b5d:	d3 ef                	shr    %cl,%edi
f0101b5f:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101b64:	d3 e2                	shl    %cl,%edx
f0101b66:	89 c1                	mov    %eax,%ecx
f0101b68:	d3 ee                	shr    %cl,%esi
f0101b6a:	09 d6                	or     %edx,%esi
f0101b6c:	89 fa                	mov    %edi,%edx
f0101b6e:	89 f0                	mov    %esi,%eax
f0101b70:	f7 74 24 0c          	divl   0xc(%esp)
f0101b74:	89 d7                	mov    %edx,%edi
f0101b76:	89 c6                	mov    %eax,%esi
f0101b78:	f7 e5                	mul    %ebp
f0101b7a:	39 d7                	cmp    %edx,%edi
f0101b7c:	72 22                	jb     f0101ba0 <__udivdi3+0x110>
f0101b7e:	8b 6c 24 08          	mov    0x8(%esp),%ebp
f0101b82:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101b87:	d3 e5                	shl    %cl,%ebp
f0101b89:	39 c5                	cmp    %eax,%ebp
f0101b8b:	73 04                	jae    f0101b91 <__udivdi3+0x101>
f0101b8d:	39 d7                	cmp    %edx,%edi
f0101b8f:	74 0f                	je     f0101ba0 <__udivdi3+0x110>
f0101b91:	89 f0                	mov    %esi,%eax
f0101b93:	31 d2                	xor    %edx,%edx
f0101b95:	e9 46 ff ff ff       	jmp    f0101ae0 <__udivdi3+0x50>
f0101b9a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101ba0:	8d 46 ff             	lea    -0x1(%esi),%eax
f0101ba3:	31 d2                	xor    %edx,%edx
f0101ba5:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101ba9:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101bad:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101bb1:	83 c4 1c             	add    $0x1c,%esp
f0101bb4:	c3                   	ret    
	...

f0101bc0 <__umoddi3>:
f0101bc0:	83 ec 1c             	sub    $0x1c,%esp
f0101bc3:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f0101bc7:	8b 6c 24 2c          	mov    0x2c(%esp),%ebp
f0101bcb:	8b 44 24 20          	mov    0x20(%esp),%eax
f0101bcf:	89 74 24 10          	mov    %esi,0x10(%esp)
f0101bd3:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0101bd7:	8b 74 24 24          	mov    0x24(%esp),%esi
f0101bdb:	85 ed                	test   %ebp,%ebp
f0101bdd:	89 7c 24 14          	mov    %edi,0x14(%esp)
f0101be1:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101be5:	89 cf                	mov    %ecx,%edi
f0101be7:	89 04 24             	mov    %eax,(%esp)
f0101bea:	89 f2                	mov    %esi,%edx
f0101bec:	75 1a                	jne    f0101c08 <__umoddi3+0x48>
f0101bee:	39 f1                	cmp    %esi,%ecx
f0101bf0:	76 4e                	jbe    f0101c40 <__umoddi3+0x80>
f0101bf2:	f7 f1                	div    %ecx
f0101bf4:	89 d0                	mov    %edx,%eax
f0101bf6:	31 d2                	xor    %edx,%edx
f0101bf8:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101bfc:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101c00:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101c04:	83 c4 1c             	add    $0x1c,%esp
f0101c07:	c3                   	ret    
f0101c08:	39 f5                	cmp    %esi,%ebp
f0101c0a:	77 54                	ja     f0101c60 <__umoddi3+0xa0>
f0101c0c:	0f bd c5             	bsr    %ebp,%eax
f0101c0f:	83 f0 1f             	xor    $0x1f,%eax
f0101c12:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101c16:	75 60                	jne    f0101c78 <__umoddi3+0xb8>
f0101c18:	3b 0c 24             	cmp    (%esp),%ecx
f0101c1b:	0f 87 07 01 00 00    	ja     f0101d28 <__umoddi3+0x168>
f0101c21:	89 f2                	mov    %esi,%edx
f0101c23:	8b 34 24             	mov    (%esp),%esi
f0101c26:	29 ce                	sub    %ecx,%esi
f0101c28:	19 ea                	sbb    %ebp,%edx
f0101c2a:	89 34 24             	mov    %esi,(%esp)
f0101c2d:	8b 04 24             	mov    (%esp),%eax
f0101c30:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101c34:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101c38:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101c3c:	83 c4 1c             	add    $0x1c,%esp
f0101c3f:	c3                   	ret    
f0101c40:	85 c9                	test   %ecx,%ecx
f0101c42:	75 0b                	jne    f0101c4f <__umoddi3+0x8f>
f0101c44:	b8 01 00 00 00       	mov    $0x1,%eax
f0101c49:	31 d2                	xor    %edx,%edx
f0101c4b:	f7 f1                	div    %ecx
f0101c4d:	89 c1                	mov    %eax,%ecx
f0101c4f:	89 f0                	mov    %esi,%eax
f0101c51:	31 d2                	xor    %edx,%edx
f0101c53:	f7 f1                	div    %ecx
f0101c55:	8b 04 24             	mov    (%esp),%eax
f0101c58:	f7 f1                	div    %ecx
f0101c5a:	eb 98                	jmp    f0101bf4 <__umoddi3+0x34>
f0101c5c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101c60:	89 f2                	mov    %esi,%edx
f0101c62:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101c66:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101c6a:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101c6e:	83 c4 1c             	add    $0x1c,%esp
f0101c71:	c3                   	ret    
f0101c72:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101c78:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101c7d:	89 e8                	mov    %ebp,%eax
f0101c7f:	bd 20 00 00 00       	mov    $0x20,%ebp
f0101c84:	2b 6c 24 04          	sub    0x4(%esp),%ebp
f0101c88:	89 fa                	mov    %edi,%edx
f0101c8a:	d3 e0                	shl    %cl,%eax
f0101c8c:	89 e9                	mov    %ebp,%ecx
f0101c8e:	d3 ea                	shr    %cl,%edx
f0101c90:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101c95:	09 c2                	or     %eax,%edx
f0101c97:	8b 44 24 08          	mov    0x8(%esp),%eax
f0101c9b:	89 14 24             	mov    %edx,(%esp)
f0101c9e:	89 f2                	mov    %esi,%edx
f0101ca0:	d3 e7                	shl    %cl,%edi
f0101ca2:	89 e9                	mov    %ebp,%ecx
f0101ca4:	d3 ea                	shr    %cl,%edx
f0101ca6:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101cab:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101caf:	d3 e6                	shl    %cl,%esi
f0101cb1:	89 e9                	mov    %ebp,%ecx
f0101cb3:	d3 e8                	shr    %cl,%eax
f0101cb5:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101cba:	09 f0                	or     %esi,%eax
f0101cbc:	8b 74 24 08          	mov    0x8(%esp),%esi
f0101cc0:	f7 34 24             	divl   (%esp)
f0101cc3:	d3 e6                	shl    %cl,%esi
f0101cc5:	89 74 24 08          	mov    %esi,0x8(%esp)
f0101cc9:	89 d6                	mov    %edx,%esi
f0101ccb:	f7 e7                	mul    %edi
f0101ccd:	39 d6                	cmp    %edx,%esi
f0101ccf:	89 c1                	mov    %eax,%ecx
f0101cd1:	89 d7                	mov    %edx,%edi
f0101cd3:	72 3f                	jb     f0101d14 <__umoddi3+0x154>
f0101cd5:	39 44 24 08          	cmp    %eax,0x8(%esp)
f0101cd9:	72 35                	jb     f0101d10 <__umoddi3+0x150>
f0101cdb:	8b 44 24 08          	mov    0x8(%esp),%eax
f0101cdf:	29 c8                	sub    %ecx,%eax
f0101ce1:	19 fe                	sbb    %edi,%esi
f0101ce3:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101ce8:	89 f2                	mov    %esi,%edx
f0101cea:	d3 e8                	shr    %cl,%eax
f0101cec:	89 e9                	mov    %ebp,%ecx
f0101cee:	d3 e2                	shl    %cl,%edx
f0101cf0:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101cf5:	09 d0                	or     %edx,%eax
f0101cf7:	89 f2                	mov    %esi,%edx
f0101cf9:	d3 ea                	shr    %cl,%edx
f0101cfb:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101cff:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101d03:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101d07:	83 c4 1c             	add    $0x1c,%esp
f0101d0a:	c3                   	ret    
f0101d0b:	90                   	nop
f0101d0c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101d10:	39 d6                	cmp    %edx,%esi
f0101d12:	75 c7                	jne    f0101cdb <__umoddi3+0x11b>
f0101d14:	89 d7                	mov    %edx,%edi
f0101d16:	89 c1                	mov    %eax,%ecx
f0101d18:	2b 4c 24 0c          	sub    0xc(%esp),%ecx
f0101d1c:	1b 3c 24             	sbb    (%esp),%edi
f0101d1f:	eb ba                	jmp    f0101cdb <__umoddi3+0x11b>
f0101d21:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101d28:	39 f5                	cmp    %esi,%ebp
f0101d2a:	0f 82 f1 fe ff ff    	jb     f0101c21 <__umoddi3+0x61>
f0101d30:	e9 f8 fe ff ff       	jmp    f0101c2d <__umoddi3+0x6d>
