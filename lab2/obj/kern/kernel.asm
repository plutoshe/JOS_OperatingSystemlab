
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
f0100015:	b8 00 10 11 00       	mov    $0x111000,%eax
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
f0100034:	bc 00 10 11 f0       	mov    $0xf0111000,%esp

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
f010004e:	c7 04 24 80 1d 10 f0 	movl   $0xf0101d80,(%esp)
f0100055:	e8 6c 0c 00 00       	call   f0100cc6 <cprintf>
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
f010008b:	c7 04 24 9c 1d 10 f0 	movl   $0xf0101d9c,(%esp)
f0100092:	e8 2f 0c 00 00       	call   f0100cc6 <cprintf>
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
f01000a3:	b8 64 39 11 f0       	mov    $0xf0113964,%eax
f01000a8:	2d 20 33 11 f0       	sub    $0xf0113320,%eax
f01000ad:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000b1:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01000b8:	00 
f01000b9:	c7 04 24 20 33 11 f0 	movl   $0xf0113320,(%esp)
f01000c0:	e8 bc 17 00 00       	call   f0101881 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000c5:	e8 9a 04 00 00       	call   f0100564 <cons_init>
	cprintf("6828 decimal is %o octal!", 6828); 
f01000ca:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f01000d1:	00 
f01000d2:	c7 04 24 b7 1d 10 f0 	movl   $0xf0101db7,(%esp)
f01000d9:	e8 e8 0b 00 00       	call   f0100cc6 <cprintf>
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
f0100103:	83 3d 60 39 11 f0 00 	cmpl   $0x0,0xf0113960
f010010a:	75 3d                	jne    f0100149 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f010010c:	89 35 60 39 11 f0    	mov    %esi,0xf0113960

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
f0100125:	c7 04 24 d1 1d 10 f0 	movl   $0xf0101dd1,(%esp)
f010012c:	e8 95 0b 00 00       	call   f0100cc6 <cprintf>
	vcprintf(fmt, ap);
f0100131:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100135:	89 34 24             	mov    %esi,(%esp)
f0100138:	e8 56 0b 00 00       	call   f0100c93 <vcprintf>
	cprintf("\n");
f010013d:	c7 04 24 0d 1e 10 f0 	movl   $0xf0101e0d,(%esp)
f0100144:	e8 7d 0b 00 00       	call   f0100cc6 <cprintf>
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
f010016f:	c7 04 24 e9 1d 10 f0 	movl   $0xf0101de9,(%esp)
f0100176:	e8 4b 0b 00 00       	call   f0100cc6 <cprintf>
	vcprintf(fmt, ap);
f010017b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010017f:	8b 45 10             	mov    0x10(%ebp),%eax
f0100182:	89 04 24             	mov    %eax,(%esp)
f0100185:	e8 09 0b 00 00       	call   f0100c93 <vcprintf>
	cprintf("\n");
f010018a:	c7 04 24 0d 1e 10 f0 	movl   $0xf0101e0d,(%esp)
f0100191:	e8 30 0b 00 00       	call   f0100cc6 <cprintf>
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
f01001d9:	8b 15 44 35 11 f0    	mov    0xf0113544,%edx
f01001df:	88 82 40 33 11 f0    	mov    %al,-0xfeeccc0(%edx)
f01001e5:	8d 42 01             	lea    0x1(%edx),%eax
		if (cons.wpos == CONSBUFSIZE)
f01001e8:	3d 00 02 00 00       	cmp    $0x200,%eax
			cons.wpos = 0;
f01001ed:	ba 00 00 00 00       	mov    $0x0,%edx
f01001f2:	0f 44 c2             	cmove  %edx,%eax
f01001f5:	a3 44 35 11 f0       	mov    %eax,0xf0113544
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
f010027c:	0f b7 15 00 30 11 f0 	movzwl 0xf0113000,%edx
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
f01002b2:	0f b7 05 54 35 11 f0 	movzwl 0xf0113554,%eax
f01002b9:	66 85 c0             	test   %ax,%ax
f01002bc:	0f 84 e1 00 00 00    	je     f01003a3 <cons_putc+0x19c>
			crt_pos--;
f01002c2:	83 e8 01             	sub    $0x1,%eax
f01002c5:	66 a3 54 35 11 f0    	mov    %ax,0xf0113554
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01002cb:	0f b7 c0             	movzwl %ax,%eax
f01002ce:	b2 00                	mov    $0x0,%dl
f01002d0:	83 ca 20             	or     $0x20,%edx
f01002d3:	8b 0d 50 35 11 f0    	mov    0xf0113550,%ecx
f01002d9:	66 89 14 41          	mov    %dx,(%ecx,%eax,2)
f01002dd:	eb 77                	jmp    f0100356 <cons_putc+0x14f>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01002df:	66 83 05 54 35 11 f0 	addw   $0x50,0xf0113554
f01002e6:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01002e7:	0f b7 05 54 35 11 f0 	movzwl 0xf0113554,%eax
f01002ee:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01002f4:	c1 e8 16             	shr    $0x16,%eax
f01002f7:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01002fa:	c1 e0 04             	shl    $0x4,%eax
f01002fd:	66 a3 54 35 11 f0    	mov    %ax,0xf0113554
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
f0100339:	0f b7 05 54 35 11 f0 	movzwl 0xf0113554,%eax
f0100340:	0f b7 d8             	movzwl %ax,%ebx
f0100343:	8b 0d 50 35 11 f0    	mov    0xf0113550,%ecx
f0100349:	66 89 14 59          	mov    %dx,(%ecx,%ebx,2)
f010034d:	83 c0 01             	add    $0x1,%eax
f0100350:	66 a3 54 35 11 f0    	mov    %ax,0xf0113554
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100356:	66 81 3d 54 35 11 f0 	cmpw   $0x7cf,0xf0113554
f010035d:	cf 07 
f010035f:	76 42                	jbe    f01003a3 <cons_putc+0x19c>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100361:	a1 50 35 11 f0       	mov    0xf0113550,%eax
f0100366:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f010036d:	00 
f010036e:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100374:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100378:	89 04 24             	mov    %eax,(%esp)
f010037b:	e8 5c 15 00 00       	call   f01018dc <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100380:	8b 15 50 35 11 f0    	mov    0xf0113550,%edx
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
f010039b:	66 83 2d 54 35 11 f0 	subw   $0x50,0xf0113554
f01003a2:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f01003a3:	8b 0d 4c 35 11 f0    	mov    0xf011354c,%ecx
f01003a9:	b8 0e 00 00 00       	mov    $0xe,%eax
f01003ae:	89 ca                	mov    %ecx,%edx
f01003b0:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01003b1:	0f b7 35 54 35 11 f0 	movzwl 0xf0113554,%esi
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
f01003fc:	83 0d 48 35 11 f0 40 	orl    $0x40,0xf0113548
		return 0;
f0100403:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100408:	e9 c4 00 00 00       	jmp    f01004d1 <kbd_proc_data+0xf8>
	} else if (data & 0x80) {
f010040d:	84 c0                	test   %al,%al
f010040f:	79 37                	jns    f0100448 <kbd_proc_data+0x6f>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f0100411:	8b 0d 48 35 11 f0    	mov    0xf0113548,%ecx
f0100417:	89 cb                	mov    %ecx,%ebx
f0100419:	83 e3 40             	and    $0x40,%ebx
f010041c:	83 e0 7f             	and    $0x7f,%eax
f010041f:	85 db                	test   %ebx,%ebx
f0100421:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100424:	0f b6 d2             	movzbl %dl,%edx
f0100427:	0f b6 82 40 1e 10 f0 	movzbl -0xfefe1c0(%edx),%eax
f010042e:	83 c8 40             	or     $0x40,%eax
f0100431:	0f b6 c0             	movzbl %al,%eax
f0100434:	f7 d0                	not    %eax
f0100436:	21 c1                	and    %eax,%ecx
f0100438:	89 0d 48 35 11 f0    	mov    %ecx,0xf0113548
		return 0;
f010043e:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100443:	e9 89 00 00 00       	jmp    f01004d1 <kbd_proc_data+0xf8>
	} else if (shift & E0ESC) {
f0100448:	8b 0d 48 35 11 f0    	mov    0xf0113548,%ecx
f010044e:	f6 c1 40             	test   $0x40,%cl
f0100451:	74 0e                	je     f0100461 <kbd_proc_data+0x88>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100453:	89 c2                	mov    %eax,%edx
f0100455:	83 ca 80             	or     $0xffffff80,%edx
		shift &= ~E0ESC;
f0100458:	83 e1 bf             	and    $0xffffffbf,%ecx
f010045b:	89 0d 48 35 11 f0    	mov    %ecx,0xf0113548
	}

	shift |= shiftcode[data];
f0100461:	0f b6 d2             	movzbl %dl,%edx
f0100464:	0f b6 82 40 1e 10 f0 	movzbl -0xfefe1c0(%edx),%eax
f010046b:	0b 05 48 35 11 f0    	or     0xf0113548,%eax
	shift ^= togglecode[data];
f0100471:	0f b6 8a 40 1f 10 f0 	movzbl -0xfefe0c0(%edx),%ecx
f0100478:	31 c8                	xor    %ecx,%eax
f010047a:	a3 48 35 11 f0       	mov    %eax,0xf0113548

	c = charcode[shift & (CTL | SHIFT)][data];
f010047f:	89 c1                	mov    %eax,%ecx
f0100481:	83 e1 03             	and    $0x3,%ecx
f0100484:	8b 0c 8d 40 20 10 f0 	mov    -0xfefdfc0(,%ecx,4),%ecx
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
f01004ba:	c7 04 24 03 1e 10 f0 	movl   $0xf0101e03,(%esp)
f01004c1:	e8 00 08 00 00       	call   f0100cc6 <cprintf>
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
f01004ec:	66 a3 00 30 11 f0    	mov    %ax,0xf0113000
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
f01004fa:	80 3d 20 33 11 f0 00 	cmpb   $0x0,0xf0113320
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
f0100531:	8b 15 40 35 11 f0    	mov    0xf0113540,%edx
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
f010053c:	3b 15 44 35 11 f0    	cmp    0xf0113544,%edx
f0100542:	74 1e                	je     f0100562 <cons_getc+0x41>
		c = cons.buf[cons.rpos++];
f0100544:	0f b6 82 40 33 11 f0 	movzbl -0xfeeccc0(%edx),%eax
f010054b:	83 c2 01             	add    $0x1,%edx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
f010054e:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100554:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100559:	0f 44 d1             	cmove  %ecx,%edx
f010055c:	89 15 40 35 11 f0    	mov    %edx,0xf0113540
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
f010058a:	c7 05 4c 35 11 f0 b4 	movl   $0x3b4,0xf011354c
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
f01005a2:	c7 05 4c 35 11 f0 d4 	movl   $0x3d4,0xf011354c
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
f01005b1:	8b 0d 4c 35 11 f0    	mov    0xf011354c,%ecx
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
f01005d6:	89 35 50 35 11 f0    	mov    %esi,0xf0113550

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f01005dc:	0f b6 d8             	movzbl %al,%ebx
f01005df:	09 df                	or     %ebx,%edi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f01005e1:	66 89 3d 54 35 11 f0 	mov    %di,0xf0113554
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
f0100634:	a2 20 33 11 f0       	mov    %al,0xf0113320
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
f0100645:	c7 04 24 0f 1e 10 f0 	movl   $0xf0101e0f,(%esp)
f010064c:	e8 75 06 00 00       	call   f0100cc6 <cprintf>
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
f0100696:	c7 04 24 50 20 10 f0 	movl   $0xf0102050,(%esp)
f010069d:	e8 24 06 00 00       	call   f0100cc6 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f01006a2:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f01006a9:	00 
f01006aa:	c7 04 24 70 21 10 f0 	movl   $0xf0102170,(%esp)
f01006b1:	e8 10 06 00 00       	call   f0100cc6 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006b6:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f01006bd:	00 
f01006be:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f01006c5:	f0 
f01006c6:	c7 04 24 98 21 10 f0 	movl   $0xf0102198,(%esp)
f01006cd:	e8 f4 05 00 00       	call   f0100cc6 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006d2:	c7 44 24 08 75 1d 10 	movl   $0x101d75,0x8(%esp)
f01006d9:	00 
f01006da:	c7 44 24 04 75 1d 10 	movl   $0xf0101d75,0x4(%esp)
f01006e1:	f0 
f01006e2:	c7 04 24 bc 21 10 f0 	movl   $0xf01021bc,(%esp)
f01006e9:	e8 d8 05 00 00       	call   f0100cc6 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006ee:	c7 44 24 08 20 33 11 	movl   $0x113320,0x8(%esp)
f01006f5:	00 
f01006f6:	c7 44 24 04 20 33 11 	movl   $0xf0113320,0x4(%esp)
f01006fd:	f0 
f01006fe:	c7 04 24 e0 21 10 f0 	movl   $0xf01021e0,(%esp)
f0100705:	e8 bc 05 00 00       	call   f0100cc6 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f010070a:	c7 44 24 08 64 39 11 	movl   $0x113964,0x8(%esp)
f0100711:	00 
f0100712:	c7 44 24 04 64 39 11 	movl   $0xf0113964,0x4(%esp)
f0100719:	f0 
f010071a:	c7 04 24 04 22 10 f0 	movl   $0xf0102204,(%esp)
f0100721:	e8 a0 05 00 00       	call   f0100cc6 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f0100726:	b8 63 3d 11 f0       	mov    $0xf0113d63,%eax
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
f0100747:	c7 04 24 28 22 10 f0 	movl   $0xf0102228,(%esp)
f010074e:	e8 73 05 00 00       	call   f0100cc6 <cprintf>
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
f0100766:	8b 83 64 23 10 f0    	mov    -0xfefdc9c(%ebx),%eax
f010076c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100770:	8b 83 60 23 10 f0    	mov    -0xfefdca0(%ebx),%eax
f0100776:	89 44 24 04          	mov    %eax,0x4(%esp)
f010077a:	c7 04 24 69 20 10 f0 	movl   $0xf0102069,(%esp)
f0100781:	e8 40 05 00 00       	call   f0100cc6 <cprintf>
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
f01007a9:	c7 04 24 72 20 10 f0 	movl   $0xf0102072,(%esp)
f01007b0:	e8 11 05 00 00       	call   f0100cc6 <cprintf>
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
f01007e8:	c7 04 24 54 22 10 f0 	movl   $0xf0102254,(%esp)
f01007ef:	e8 d2 04 00 00       	call   f0100cc6 <cprintf>
		struct Eipdebuginfo temp_debuginfo;
		debuginfo_eip((uintptr_t) eip, &temp_debuginfo);		
f01007f4:	8d 45 d0             	lea    -0x30(%ebp),%eax
f01007f7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007fb:	89 3c 24             	mov    %edi,(%esp)
f01007fe:	e8 bd 05 00 00       	call   f0100dc0 <debuginfo_eip>
		cprintf("       %s:%d: ", temp_debuginfo.eip_file, temp_debuginfo.eip_line);
f0100803:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100806:	89 44 24 08          	mov    %eax,0x8(%esp)
f010080a:	8b 45 d0             	mov    -0x30(%ebp),%eax
f010080d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100811:	c7 04 24 83 20 10 f0 	movl   $0xf0102083,(%esp)
f0100818:	e8 a9 04 00 00       	call   f0100cc6 <cprintf>
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
f0100833:	c7 04 24 92 20 10 f0 	movl   $0xf0102092,(%esp)
f010083a:	e8 87 04 00 00       	call   f0100cc6 <cprintf>
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
f010084e:	c7 04 24 95 20 10 f0 	movl   $0xf0102095,(%esp)
f0100855:	e8 6c 04 00 00       	call   f0100cc6 <cprintf>
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
f0100886:	c7 44 24 04 9a 20 10 	movl   $0xf010209a,0x4(%esp)
f010088d:	f0 
f010088e:	8b 46 08             	mov    0x8(%esi),%eax
f0100891:	89 04 24             	mov    %eax,(%esp)
f0100894:	e8 12 0f 00 00       	call   f01017ab <strcmp>
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
f01008a6:	c7 44 24 04 9e 20 10 	movl   $0xf010209e,0x4(%esp)
f01008ad:	f0 
f01008ae:	8b 46 08             	mov    0x8(%esi),%eax
f01008b1:	89 04 24             	mov    %eax,(%esp)
f01008b4:	e8 f2 0e 00 00       	call   f01017ab <strcmp>
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
f01008c6:	c7 44 24 04 a2 20 10 	movl   $0xf01020a2,0x4(%esp)
f01008cd:	f0 
f01008ce:	8b 46 08             	mov    0x8(%esi),%eax
f01008d1:	89 04 24             	mov    %eax,(%esp)
f01008d4:	e8 d2 0e 00 00       	call   f01017ab <strcmp>
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
f01008e6:	c7 44 24 04 a6 20 10 	movl   $0xf01020a6,0x4(%esp)
f01008ed:	f0 
f01008ee:	8b 46 08             	mov    0x8(%esi),%eax
f01008f1:	89 04 24             	mov    %eax,(%esp)
f01008f4:	e8 b2 0e 00 00       	call   f01017ab <strcmp>
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
f0100906:	c7 44 24 04 aa 20 10 	movl   $0xf01020aa,0x4(%esp)
f010090d:	f0 
f010090e:	8b 46 08             	mov    0x8(%esi),%eax
f0100911:	89 04 24             	mov    %eax,(%esp)
f0100914:	e8 92 0e 00 00       	call   f01017ab <strcmp>
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
f0100926:	c7 44 24 04 ae 20 10 	movl   $0xf01020ae,0x4(%esp)
f010092d:	f0 
f010092e:	8b 46 08             	mov    0x8(%esi),%eax
f0100931:	89 04 24             	mov    %eax,(%esp)
f0100934:	e8 72 0e 00 00       	call   f01017ab <strcmp>
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
f0100942:	c7 44 24 04 b2 20 10 	movl   $0xf01020b2,0x4(%esp)
f0100949:	f0 
f010094a:	8b 46 08             	mov    0x8(%esi),%eax
f010094d:	89 04 24             	mov    %eax,(%esp)
f0100950:	e8 56 0e 00 00       	call   f01017ab <strcmp>
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
f010095e:	c7 44 24 04 b6 20 10 	movl   $0xf01020b6,0x4(%esp)
f0100965:	f0 
f0100966:	8b 46 08             	mov    0x8(%esi),%eax
f0100969:	89 04 24             	mov    %eax,(%esp)
f010096c:	e8 3a 0e 00 00       	call   f01017ab <strcmp>
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
f010097a:	c7 44 24 04 ba 20 10 	movl   $0xf01020ba,0x4(%esp)
f0100981:	f0 
f0100982:	8b 46 08             	mov    0x8(%esi),%eax
f0100985:	89 04 24             	mov    %eax,(%esp)
f0100988:	e8 1e 0e 00 00       	call   f01017ab <strcmp>
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
f0100996:	c7 44 24 04 be 20 10 	movl   $0xf01020be,0x4(%esp)
f010099d:	f0 
f010099e:	8b 46 08             	mov    0x8(%esi),%eax
f01009a1:	89 04 24             	mov    %eax,(%esp)
f01009a4:	e8 02 0e 00 00       	call   f01017ab <strcmp>
			ch_color1=COLOR_CYN
f01009a9:	83 f8 01             	cmp    $0x1,%eax
f01009ac:	19 ff                	sbb    %edi,%edi
f01009ae:	83 e7 04             	and    $0x4,%edi
f01009b1:	83 c7 07             	add    $0x7,%edi
	else ch_color1=COLOR_WHT;
	if(strcmp(argv[1],"blk")==0)
f01009b4:	c7 44 24 04 9a 20 10 	movl   $0xf010209a,0x4(%esp)
f01009bb:	f0 
f01009bc:	8b 46 04             	mov    0x4(%esi),%eax
f01009bf:	89 04 24             	mov    %eax,(%esp)
f01009c2:	e8 e4 0d 00 00       	call   f01017ab <strcmp>
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
f01009d4:	c7 44 24 04 9e 20 10 	movl   $0xf010209e,0x4(%esp)
f01009db:	f0 
f01009dc:	8b 46 04             	mov    0x4(%esi),%eax
f01009df:	89 04 24             	mov    %eax,(%esp)
f01009e2:	e8 c4 0d 00 00       	call   f01017ab <strcmp>
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
f01009f1:	c7 44 24 04 a2 20 10 	movl   $0xf01020a2,0x4(%esp)
f01009f8:	f0 
f01009f9:	8b 46 04             	mov    0x4(%esi),%eax
f01009fc:	89 04 24             	mov    %eax,(%esp)
f01009ff:	e8 a7 0d 00 00       	call   f01017ab <strcmp>
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
f0100a0e:	c7 44 24 04 a6 20 10 	movl   $0xf01020a6,0x4(%esp)
f0100a15:	f0 
f0100a16:	8b 46 04             	mov    0x4(%esi),%eax
f0100a19:	89 04 24             	mov    %eax,(%esp)
f0100a1c:	e8 8a 0d 00 00       	call   f01017ab <strcmp>
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
f0100a2b:	c7 44 24 04 aa 20 10 	movl   $0xf01020aa,0x4(%esp)
f0100a32:	f0 
f0100a33:	8b 46 04             	mov    0x4(%esi),%eax
f0100a36:	89 04 24             	mov    %eax,(%esp)
f0100a39:	e8 6d 0d 00 00       	call   f01017ab <strcmp>
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
f0100a48:	c7 44 24 04 ae 20 10 	movl   $0xf01020ae,0x4(%esp)
f0100a4f:	f0 
f0100a50:	8b 46 04             	mov    0x4(%esi),%eax
f0100a53:	89 04 24             	mov    %eax,(%esp)
f0100a56:	e8 50 0d 00 00       	call   f01017ab <strcmp>
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
f0100a61:	c7 44 24 04 b2 20 10 	movl   $0xf01020b2,0x4(%esp)
f0100a68:	f0 
f0100a69:	8b 46 04             	mov    0x4(%esi),%eax
f0100a6c:	89 04 24             	mov    %eax,(%esp)
f0100a6f:	e8 37 0d 00 00       	call   f01017ab <strcmp>
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
f0100a7a:	c7 44 24 04 b6 20 10 	movl   $0xf01020b6,0x4(%esp)
f0100a81:	f0 
f0100a82:	8b 46 04             	mov    0x4(%esi),%eax
f0100a85:	89 04 24             	mov    %eax,(%esp)
f0100a88:	e8 1e 0d 00 00       	call   f01017ab <strcmp>
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
f0100a93:	c7 44 24 04 ba 20 10 	movl   $0xf01020ba,0x4(%esp)
f0100a9a:	f0 
f0100a9b:	8b 46 04             	mov    0x4(%esi),%eax
f0100a9e:	89 04 24             	mov    %eax,(%esp)
f0100aa1:	e8 05 0d 00 00       	call   f01017ab <strcmp>
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
f0100aac:	c7 44 24 04 be 20 10 	movl   $0xf01020be,0x4(%esp)
f0100ab3:	f0 
f0100ab4:	8b 46 04             	mov    0x4(%esi),%eax
f0100ab7:	89 04 24             	mov    %eax,(%esp)
f0100aba:	e8 ec 0c 00 00       	call   f01017ab <strcmp>
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
f0100ae4:	c7 04 24 88 22 10 f0 	movl   $0xf0102288,(%esp)
f0100aeb:	e8 d6 01 00 00       	call   f0100cc6 <cprintf>
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
f0100b08:	83 ec 6c             	sub    $0x6c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100b0b:	c7 04 24 bc 22 10 f0 	movl   $0xf01022bc,(%esp)
f0100b12:	e8 af 01 00 00       	call   f0100cc6 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100b17:	c7 04 24 e0 22 10 f0 	movl   $0xf01022e0,(%esp)
f0100b1e:	e8 a3 01 00 00       	call   f0100cc6 <cprintf>
	int x = 1, y = 3, z = 4;
  	cprintf("x %d, y %x, z %d\n", x, y, z);
f0100b23:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
f0100b2a:	00 
f0100b2b:	c7 44 24 08 03 00 00 	movl   $0x3,0x8(%esp)
f0100b32:	00 
f0100b33:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0100b3a:	00 
f0100b3b:	c7 04 24 c2 20 10 f0 	movl   $0xf01020c2,(%esp)
f0100b42:	e8 7f 01 00 00       	call   f0100cc6 <cprintf>
	unsigned int i = 0x00646c72;
f0100b47:	c7 45 e4 72 6c 64 00 	movl   $0x646c72,-0x1c(%ebp)
	cprintf("H%x Wo%s", 57616, &i);
f0100b4e:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0100b51:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100b55:	c7 44 24 04 10 e1 00 	movl   $0xe110,0x4(%esp)
f0100b5c:	00 
f0100b5d:	c7 04 24 d4 20 10 f0 	movl   $0xf01020d4,(%esp)
f0100b64:	e8 5d 01 00 00       	call   f0100cc6 <cprintf>

	while (1) {
		buf = readline("K> ");
f0100b69:	c7 04 24 dd 20 10 f0 	movl   $0xf01020dd,(%esp)
f0100b70:	e8 5b 0a 00 00       	call   f01015d0 <readline>
f0100b75:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100b77:	85 c0                	test   %eax,%eax
f0100b79:	74 ee                	je     f0100b69 <monitor+0x67>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100b7b:	c7 45 a4 00 00 00 00 	movl   $0x0,-0x5c(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100b82:	be 00 00 00 00       	mov    $0x0,%esi
f0100b87:	eb 06                	jmp    f0100b8f <monitor+0x8d>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100b89:	c6 03 00             	movb   $0x0,(%ebx)
f0100b8c:	83 c3 01             	add    $0x1,%ebx
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100b8f:	0f b6 03             	movzbl (%ebx),%eax
f0100b92:	84 c0                	test   %al,%al
f0100b94:	74 6a                	je     f0100c00 <monitor+0xfe>
f0100b96:	0f be c0             	movsbl %al,%eax
f0100b99:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100b9d:	c7 04 24 e1 20 10 f0 	movl   $0xf01020e1,(%esp)
f0100ba4:	e8 7d 0c 00 00       	call   f0101826 <strchr>
f0100ba9:	85 c0                	test   %eax,%eax
f0100bab:	75 dc                	jne    f0100b89 <monitor+0x87>
			*buf++ = 0;
		if (*buf == 0)
f0100bad:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100bb0:	74 4e                	je     f0100c00 <monitor+0xfe>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100bb2:	83 fe 0f             	cmp    $0xf,%esi
f0100bb5:	75 16                	jne    f0100bcd <monitor+0xcb>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100bb7:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f0100bbe:	00 
f0100bbf:	c7 04 24 e6 20 10 f0 	movl   $0xf01020e6,(%esp)
f0100bc6:	e8 fb 00 00 00       	call   f0100cc6 <cprintf>
f0100bcb:	eb 9c                	jmp    f0100b69 <monitor+0x67>
			return 0;
		}
		argv[argc++] = buf;
f0100bcd:	89 5c b5 a4          	mov    %ebx,-0x5c(%ebp,%esi,4)
f0100bd1:	83 c6 01             	add    $0x1,%esi
		while (*buf && !strchr(WHITESPACE, *buf))
f0100bd4:	0f b6 03             	movzbl (%ebx),%eax
f0100bd7:	84 c0                	test   %al,%al
f0100bd9:	75 0c                	jne    f0100be7 <monitor+0xe5>
f0100bdb:	eb b2                	jmp    f0100b8f <monitor+0x8d>
			buf++;
f0100bdd:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100be0:	0f b6 03             	movzbl (%ebx),%eax
f0100be3:	84 c0                	test   %al,%al
f0100be5:	74 a8                	je     f0100b8f <monitor+0x8d>
f0100be7:	0f be c0             	movsbl %al,%eax
f0100bea:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100bee:	c7 04 24 e1 20 10 f0 	movl   $0xf01020e1,(%esp)
f0100bf5:	e8 2c 0c 00 00       	call   f0101826 <strchr>
f0100bfa:	85 c0                	test   %eax,%eax
f0100bfc:	74 df                	je     f0100bdd <monitor+0xdb>
f0100bfe:	eb 8f                	jmp    f0100b8f <monitor+0x8d>
			buf++;
	}
	argv[argc] = 0;
f0100c00:	c7 44 b5 a4 00 00 00 	movl   $0x0,-0x5c(%ebp,%esi,4)
f0100c07:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100c08:	85 f6                	test   %esi,%esi
f0100c0a:	0f 84 59 ff ff ff    	je     f0100b69 <monitor+0x67>
f0100c10:	bb 60 23 10 f0       	mov    $0xf0102360,%ebx
f0100c15:	bf 00 00 00 00       	mov    $0x0,%edi
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100c1a:	8b 03                	mov    (%ebx),%eax
f0100c1c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100c20:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f0100c23:	89 04 24             	mov    %eax,(%esp)
f0100c26:	e8 80 0b 00 00       	call   f01017ab <strcmp>
f0100c2b:	85 c0                	test   %eax,%eax
f0100c2d:	75 24                	jne    f0100c53 <monitor+0x151>
			return commands[i].func(argc, argv, tf);
f0100c2f:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f0100c32:	8b 55 08             	mov    0x8(%ebp),%edx
f0100c35:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100c39:	8d 55 a4             	lea    -0x5c(%ebp),%edx
f0100c3c:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100c40:	89 34 24             	mov    %esi,(%esp)
f0100c43:	ff 14 85 68 23 10 f0 	call   *-0xfefdc98(,%eax,4)
	cprintf("H%x Wo%s", 57616, &i);

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100c4a:	85 c0                	test   %eax,%eax
f0100c4c:	78 28                	js     f0100c76 <monitor+0x174>
f0100c4e:	e9 16 ff ff ff       	jmp    f0100b69 <monitor+0x67>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f0100c53:	83 c7 01             	add    $0x1,%edi
f0100c56:	83 c3 0c             	add    $0xc,%ebx
f0100c59:	83 ff 04             	cmp    $0x4,%edi
f0100c5c:	75 bc                	jne    f0100c1a <monitor+0x118>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100c5e:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f0100c61:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100c65:	c7 04 24 03 21 10 f0 	movl   $0xf0102103,(%esp)
f0100c6c:	e8 55 00 00 00       	call   f0100cc6 <cprintf>
f0100c71:	e9 f3 fe ff ff       	jmp    f0100b69 <monitor+0x67>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100c76:	83 c4 6c             	add    $0x6c,%esp
f0100c79:	5b                   	pop    %ebx
f0100c7a:	5e                   	pop    %esi
f0100c7b:	5f                   	pop    %edi
f0100c7c:	5d                   	pop    %ebp
f0100c7d:	c3                   	ret    
	...

f0100c80 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100c80:	55                   	push   %ebp
f0100c81:	89 e5                	mov    %esp,%ebp
f0100c83:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f0100c86:	8b 45 08             	mov    0x8(%ebp),%eax
f0100c89:	89 04 24             	mov    %eax,(%esp)
f0100c8c:	e8 c8 f9 ff ff       	call   f0100659 <cputchar>
	*cnt++;
}
f0100c91:	c9                   	leave  
f0100c92:	c3                   	ret    

f0100c93 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0100c93:	55                   	push   %ebp
f0100c94:	89 e5                	mov    %esp,%ebp
f0100c96:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f0100c99:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100ca0:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100ca3:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100ca7:	8b 45 08             	mov    0x8(%ebp),%eax
f0100caa:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100cae:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100cb1:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100cb5:	c7 04 24 80 0c 10 f0 	movl   $0xf0100c80,(%esp)
f0100cbc:	e8 b9 04 00 00       	call   f010117a <vprintfmt>
	return cnt;
}
f0100cc1:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100cc4:	c9                   	leave  
f0100cc5:	c3                   	ret    

f0100cc6 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0100cc6:	55                   	push   %ebp
f0100cc7:	89 e5                	mov    %esp,%ebp
f0100cc9:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0100ccc:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0100ccf:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100cd3:	8b 45 08             	mov    0x8(%ebp),%eax
f0100cd6:	89 04 24             	mov    %eax,(%esp)
f0100cd9:	e8 b5 ff ff ff       	call   f0100c93 <vcprintf>
	va_end(ap);

	return cnt;
}
f0100cde:	c9                   	leave  
f0100cdf:	c3                   	ret    

f0100ce0 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100ce0:	55                   	push   %ebp
f0100ce1:	89 e5                	mov    %esp,%ebp
f0100ce3:	57                   	push   %edi
f0100ce4:	56                   	push   %esi
f0100ce5:	53                   	push   %ebx
f0100ce6:	83 ec 10             	sub    $0x10,%esp
f0100ce9:	89 c3                	mov    %eax,%ebx
f0100ceb:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0100cee:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0100cf1:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100cf4:	8b 0a                	mov    (%edx),%ecx
f0100cf6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100cf9:	8b 00                	mov    (%eax),%eax
f0100cfb:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100cfe:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)

	while (l <= r) {
f0100d05:	eb 77                	jmp    f0100d7e <stab_binsearch+0x9e>
		int true_m = (l + r) / 2, m = true_m;
f0100d07:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100d0a:	01 c8                	add    %ecx,%eax
f0100d0c:	bf 02 00 00 00       	mov    $0x2,%edi
f0100d11:	99                   	cltd   
f0100d12:	f7 ff                	idiv   %edi
f0100d14:	89 c2                	mov    %eax,%edx

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100d16:	eb 01                	jmp    f0100d19 <stab_binsearch+0x39>
			m--;
f0100d18:	4a                   	dec    %edx

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100d19:	39 ca                	cmp    %ecx,%edx
f0100d1b:	7c 1d                	jl     f0100d3a <stab_binsearch+0x5a>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0100d1d:	6b fa 0c             	imul   $0xc,%edx,%edi

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100d20:	0f b6 7c 3b 04       	movzbl 0x4(%ebx,%edi,1),%edi
f0100d25:	39 f7                	cmp    %esi,%edi
f0100d27:	75 ef                	jne    f0100d18 <stab_binsearch+0x38>
f0100d29:	89 55 ec             	mov    %edx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100d2c:	6b fa 0c             	imul   $0xc,%edx,%edi
f0100d2f:	8b 7c 3b 08          	mov    0x8(%ebx,%edi,1),%edi
f0100d33:	3b 7d 0c             	cmp    0xc(%ebp),%edi
f0100d36:	73 18                	jae    f0100d50 <stab_binsearch+0x70>
f0100d38:	eb 05                	jmp    f0100d3f <stab_binsearch+0x5f>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0100d3a:	8d 48 01             	lea    0x1(%eax),%ecx
			continue;
f0100d3d:	eb 3f                	jmp    f0100d7e <stab_binsearch+0x9e>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0100d3f:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0100d42:	89 11                	mov    %edx,(%ecx)
			l = true_m + 1;
f0100d44:	8d 48 01             	lea    0x1(%eax),%ecx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100d47:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100d4e:	eb 2e                	jmp    f0100d7e <stab_binsearch+0x9e>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0100d50:	3b 7d 0c             	cmp    0xc(%ebp),%edi
f0100d53:	76 15                	jbe    f0100d6a <stab_binsearch+0x8a>
			*region_right = m - 1;
f0100d55:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0100d58:	4f                   	dec    %edi
f0100d59:	89 7d f0             	mov    %edi,-0x10(%ebp)
f0100d5c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100d5f:	89 38                	mov    %edi,(%eax)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100d61:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100d68:	eb 14                	jmp    f0100d7e <stab_binsearch+0x9e>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100d6a:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0100d6d:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0100d70:	89 39                	mov    %edi,(%ecx)
			l = m;
			addr++;
f0100d72:	ff 45 0c             	incl   0xc(%ebp)
f0100d75:	89 d1                	mov    %edx,%ecx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100d77:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0100d7e:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
f0100d81:	7e 84                	jle    f0100d07 <stab_binsearch+0x27>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100d83:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0100d87:	75 0d                	jne    f0100d96 <stab_binsearch+0xb6>
		*region_right = *region_left - 1;
f0100d89:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100d8c:	8b 02                	mov    (%edx),%eax
f0100d8e:	48                   	dec    %eax
f0100d8f:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100d92:	89 01                	mov    %eax,(%ecx)
f0100d94:	eb 22                	jmp    f0100db8 <stab_binsearch+0xd8>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100d96:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100d99:	8b 01                	mov    (%ecx),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100d9b:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100d9e:	8b 0a                	mov    (%edx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100da0:	eb 01                	jmp    f0100da3 <stab_binsearch+0xc3>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100da2:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100da3:	39 c1                	cmp    %eax,%ecx
f0100da5:	7d 0c                	jge    f0100db3 <stab_binsearch+0xd3>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0100da7:	6b d0 0c             	imul   $0xc,%eax,%edx
	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
		     l > *region_left && stabs[l].n_type != type;
f0100daa:	0f b6 54 13 04       	movzbl 0x4(%ebx,%edx,1),%edx
f0100daf:	39 f2                	cmp    %esi,%edx
f0100db1:	75 ef                	jne    f0100da2 <stab_binsearch+0xc2>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100db3:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100db6:	89 02                	mov    %eax,(%edx)
	}
}
f0100db8:	83 c4 10             	add    $0x10,%esp
f0100dbb:	5b                   	pop    %ebx
f0100dbc:	5e                   	pop    %esi
f0100dbd:	5f                   	pop    %edi
f0100dbe:	5d                   	pop    %ebp
f0100dbf:	c3                   	ret    

f0100dc0 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100dc0:	55                   	push   %ebp
f0100dc1:	89 e5                	mov    %esp,%ebp
f0100dc3:	83 ec 58             	sub    $0x58,%esp
f0100dc6:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0100dc9:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0100dcc:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0100dcf:	8b 75 08             	mov    0x8(%ebp),%esi
f0100dd2:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100dd5:	c7 03 90 23 10 f0    	movl   $0xf0102390,(%ebx)
	info->eip_line = 0;
f0100ddb:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100de2:	c7 43 08 90 23 10 f0 	movl   $0xf0102390,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100de9:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100df0:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100df3:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100dfa:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100e00:	76 12                	jbe    f0100e14 <debuginfo_eip+0x54>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100e02:	b8 78 80 10 f0       	mov    $0xf0108078,%eax
f0100e07:	3d 81 66 10 f0       	cmp    $0xf0106681,%eax
f0100e0c:	0f 86 f1 01 00 00    	jbe    f0101003 <debuginfo_eip+0x243>
f0100e12:	eb 1c                	jmp    f0100e30 <debuginfo_eip+0x70>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100e14:	c7 44 24 08 9a 23 10 	movl   $0xf010239a,0x8(%esp)
f0100e1b:	f0 
f0100e1c:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0100e23:	00 
f0100e24:	c7 04 24 a7 23 10 f0 	movl   $0xf01023a7,(%esp)
f0100e2b:	e8 c8 f2 ff ff       	call   f01000f8 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100e30:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100e35:	80 3d 77 80 10 f0 00 	cmpb   $0x0,0xf0108077
f0100e3c:	0f 85 cd 01 00 00    	jne    f010100f <debuginfo_eip+0x24f>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100e42:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100e49:	b8 80 66 10 f0       	mov    $0xf0106680,%eax
f0100e4e:	2d c4 25 10 f0       	sub    $0xf01025c4,%eax
f0100e53:	c1 f8 02             	sar    $0x2,%eax
f0100e56:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100e5c:	83 e8 01             	sub    $0x1,%eax
f0100e5f:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100e62:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100e66:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0100e6d:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100e70:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100e73:	b8 c4 25 10 f0       	mov    $0xf01025c4,%eax
f0100e78:	e8 63 fe ff ff       	call   f0100ce0 <stab_binsearch>
	if (lfile == 0)
f0100e7d:	8b 55 e4             	mov    -0x1c(%ebp),%edx
		return -1;
f0100e80:	b8 ff ff ff ff       	mov    $0xffffffff,%eax

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
f0100e85:	85 d2                	test   %edx,%edx
f0100e87:	0f 84 82 01 00 00    	je     f010100f <debuginfo_eip+0x24f>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100e8d:	89 55 dc             	mov    %edx,-0x24(%ebp)
	rfun = rfile;
f0100e90:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100e93:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100e96:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100e9a:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0100ea1:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100ea4:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100ea7:	b8 c4 25 10 f0       	mov    $0xf01025c4,%eax
f0100eac:	e8 2f fe ff ff       	call   f0100ce0 <stab_binsearch>

	if (lfun <= rfun) {
f0100eb1:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100eb4:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100eb7:	39 d0                	cmp    %edx,%eax
f0100eb9:	7f 3d                	jg     f0100ef8 <debuginfo_eip+0x138>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100ebb:	6b c8 0c             	imul   $0xc,%eax,%ecx
f0100ebe:	8d b9 c4 25 10 f0    	lea    -0xfefda3c(%ecx),%edi
f0100ec4:	89 7d c0             	mov    %edi,-0x40(%ebp)
f0100ec7:	8b 89 c4 25 10 f0    	mov    -0xfefda3c(%ecx),%ecx
f0100ecd:	bf 78 80 10 f0       	mov    $0xf0108078,%edi
f0100ed2:	81 ef 81 66 10 f0    	sub    $0xf0106681,%edi
f0100ed8:	39 f9                	cmp    %edi,%ecx
f0100eda:	73 09                	jae    f0100ee5 <debuginfo_eip+0x125>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100edc:	81 c1 81 66 10 f0    	add    $0xf0106681,%ecx
f0100ee2:	89 4b 08             	mov    %ecx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100ee5:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0100ee8:	8b 4f 08             	mov    0x8(%edi),%ecx
f0100eeb:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0100eee:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0100ef0:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0100ef3:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0100ef6:	eb 0f                	jmp    f0100f07 <debuginfo_eip+0x147>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100ef8:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100efb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100efe:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0100f01:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100f04:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100f07:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0100f0e:	00 
f0100f0f:	8b 43 08             	mov    0x8(%ebx),%eax
f0100f12:	89 04 24             	mov    %eax,(%esp)
f0100f15:	e8 40 09 00 00       	call   f010185a <strfind>
f0100f1a:	2b 43 08             	sub    0x8(%ebx),%eax
f0100f1d:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0100f20:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100f24:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f0100f2b:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0100f2e:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0100f31:	b8 c4 25 10 f0       	mov    $0xf01025c4,%eax
f0100f36:	e8 a5 fd ff ff       	call   f0100ce0 <stab_binsearch>
	if (lline <= rline) {
f0100f3b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100f3e:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0100f41:	7f 0f                	jg     f0100f52 <debuginfo_eip+0x192>
		info->eip_line = stabs[lline].n_desc;
f0100f43:	6b c0 0c             	imul   $0xc,%eax,%eax
f0100f46:	0f b7 80 ca 25 10 f0 	movzwl -0xfefda36(%eax),%eax
f0100f4d:	89 43 04             	mov    %eax,0x4(%ebx)
f0100f50:	eb 07                	jmp    f0100f59 <debuginfo_eip+0x199>
	} else {
		info->eip_line = -1;
f0100f52:	c7 43 04 ff ff ff ff 	movl   $0xffffffff,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100f59:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100f5c:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100f5f:	39 c8                	cmp    %ecx,%eax
f0100f61:	7c 5f                	jl     f0100fc2 <debuginfo_eip+0x202>
	       && stabs[lline].n_type != N_SOL
f0100f63:	89 c2                	mov    %eax,%edx
f0100f65:	6b f0 0c             	imul   $0xc,%eax,%esi
f0100f68:	80 be c8 25 10 f0 84 	cmpb   $0x84,-0xfefda38(%esi)
f0100f6f:	75 18                	jne    f0100f89 <debuginfo_eip+0x1c9>
f0100f71:	eb 30                	jmp    f0100fa3 <debuginfo_eip+0x1e3>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0100f73:	83 e8 01             	sub    $0x1,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100f76:	39 c1                	cmp    %eax,%ecx
f0100f78:	7f 48                	jg     f0100fc2 <debuginfo_eip+0x202>
	       && stabs[lline].n_type != N_SOL
f0100f7a:	89 c2                	mov    %eax,%edx
f0100f7c:	8d 34 40             	lea    (%eax,%eax,2),%esi
f0100f7f:	80 3c b5 c8 25 10 f0 	cmpb   $0x84,-0xfefda38(,%esi,4)
f0100f86:	84 
f0100f87:	74 1a                	je     f0100fa3 <debuginfo_eip+0x1e3>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100f89:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0100f8c:	8d 14 95 c4 25 10 f0 	lea    -0xfefda3c(,%edx,4),%edx
f0100f93:	80 7a 04 64          	cmpb   $0x64,0x4(%edx)
f0100f97:	75 da                	jne    f0100f73 <debuginfo_eip+0x1b3>
f0100f99:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f0100f9d:	74 d4                	je     f0100f73 <debuginfo_eip+0x1b3>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100f9f:	39 c8                	cmp    %ecx,%eax
f0100fa1:	7c 1f                	jl     f0100fc2 <debuginfo_eip+0x202>
f0100fa3:	6b c0 0c             	imul   $0xc,%eax,%eax
f0100fa6:	8b 80 c4 25 10 f0    	mov    -0xfefda3c(%eax),%eax
f0100fac:	ba 78 80 10 f0       	mov    $0xf0108078,%edx
f0100fb1:	81 ea 81 66 10 f0    	sub    $0xf0106681,%edx
f0100fb7:	39 d0                	cmp    %edx,%eax
f0100fb9:	73 07                	jae    f0100fc2 <debuginfo_eip+0x202>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100fbb:	05 81 66 10 f0       	add    $0xf0106681,%eax
f0100fc0:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100fc2:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100fc5:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100fc8:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100fcd:	39 ca                	cmp    %ecx,%edx
f0100fcf:	7d 3e                	jge    f010100f <debuginfo_eip+0x24f>
		for (lline = lfun + 1;
f0100fd1:	83 c2 01             	add    $0x1,%edx
f0100fd4:	39 d1                	cmp    %edx,%ecx
f0100fd6:	7e 37                	jle    f010100f <debuginfo_eip+0x24f>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100fd8:	6b f2 0c             	imul   $0xc,%edx,%esi
f0100fdb:	80 be c8 25 10 f0 a0 	cmpb   $0xa0,-0xfefda38(%esi)
f0100fe2:	75 2b                	jne    f010100f <debuginfo_eip+0x24f>
		     lline++)
			info->eip_fn_narg++;
f0100fe4:	83 43 14 01          	addl   $0x1,0x14(%ebx)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0100fe8:	83 c2 01             	add    $0x1,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100feb:	39 d1                	cmp    %edx,%ecx
f0100fed:	7e 1b                	jle    f010100a <debuginfo_eip+0x24a>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100fef:	8d 04 52             	lea    (%edx,%edx,2),%eax
f0100ff2:	80 3c 85 c8 25 10 f0 	cmpb   $0xa0,-0xfefda38(,%eax,4)
f0100ff9:	a0 
f0100ffa:	74 e8                	je     f0100fe4 <debuginfo_eip+0x224>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100ffc:	b8 00 00 00 00       	mov    $0x0,%eax
f0101001:	eb 0c                	jmp    f010100f <debuginfo_eip+0x24f>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0101003:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0101008:	eb 05                	jmp    f010100f <debuginfo_eip+0x24f>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f010100a:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010100f:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0101012:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0101015:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0101018:	89 ec                	mov    %ebp,%esp
f010101a:	5d                   	pop    %ebp
f010101b:	c3                   	ret    
f010101c:	00 00                	add    %al,(%eax)
	...

f0101020 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0101020:	55                   	push   %ebp
f0101021:	89 e5                	mov    %esp,%ebp
f0101023:	57                   	push   %edi
f0101024:	56                   	push   %esi
f0101025:	53                   	push   %ebx
f0101026:	83 ec 3c             	sub    $0x3c,%esp
f0101029:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010102c:	89 d7                	mov    %edx,%edi
f010102e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101031:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0101034:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101037:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010103a:	8b 5d 14             	mov    0x14(%ebp),%ebx
f010103d:	8b 75 18             	mov    0x18(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0101040:	b8 00 00 00 00       	mov    $0x0,%eax
f0101045:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0101048:	72 11                	jb     f010105b <printnum+0x3b>
f010104a:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010104d:	39 45 10             	cmp    %eax,0x10(%ebp)
f0101050:	76 09                	jbe    f010105b <printnum+0x3b>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0101052:	83 eb 01             	sub    $0x1,%ebx
f0101055:	85 db                	test   %ebx,%ebx
f0101057:	7f 51                	jg     f01010aa <printnum+0x8a>
f0101059:	eb 5e                	jmp    f01010b9 <printnum+0x99>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
f010105b:	89 74 24 10          	mov    %esi,0x10(%esp)
f010105f:	83 eb 01             	sub    $0x1,%ebx
f0101062:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0101066:	8b 45 10             	mov    0x10(%ebp),%eax
f0101069:	89 44 24 08          	mov    %eax,0x8(%esp)
f010106d:	8b 5c 24 08          	mov    0x8(%esp),%ebx
f0101071:	8b 74 24 0c          	mov    0xc(%esp),%esi
f0101075:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f010107c:	00 
f010107d:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0101080:	89 04 24             	mov    %eax,(%esp)
f0101083:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101086:	89 44 24 04          	mov    %eax,0x4(%esp)
f010108a:	e8 41 0a 00 00       	call   f0101ad0 <__udivdi3>
f010108f:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0101093:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0101097:	89 04 24             	mov    %eax,(%esp)
f010109a:	89 54 24 04          	mov    %edx,0x4(%esp)
f010109e:	89 fa                	mov    %edi,%edx
f01010a0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01010a3:	e8 78 ff ff ff       	call   f0101020 <printnum>
f01010a8:	eb 0f                	jmp    f01010b9 <printnum+0x99>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f01010aa:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01010ae:	89 34 24             	mov    %esi,(%esp)
f01010b1:	ff 55 e4             	call   *-0x1c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f01010b4:	83 eb 01             	sub    $0x1,%ebx
f01010b7:	75 f1                	jne    f01010aa <printnum+0x8a>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f01010b9:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01010bd:	8b 7c 24 04          	mov    0x4(%esp),%edi
f01010c1:	8b 45 10             	mov    0x10(%ebp),%eax
f01010c4:	89 44 24 08          	mov    %eax,0x8(%esp)
f01010c8:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f01010cf:	00 
f01010d0:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01010d3:	89 04 24             	mov    %eax,(%esp)
f01010d6:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01010d9:	89 44 24 04          	mov    %eax,0x4(%esp)
f01010dd:	e8 1e 0b 00 00       	call   f0101c00 <__umoddi3>
f01010e2:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01010e6:	0f be 80 b5 23 10 f0 	movsbl -0xfefdc4b(%eax),%eax
f01010ed:	89 04 24             	mov    %eax,(%esp)
f01010f0:	ff 55 e4             	call   *-0x1c(%ebp)
}
f01010f3:	83 c4 3c             	add    $0x3c,%esp
f01010f6:	5b                   	pop    %ebx
f01010f7:	5e                   	pop    %esi
f01010f8:	5f                   	pop    %edi
f01010f9:	5d                   	pop    %ebp
f01010fa:	c3                   	ret    

f01010fb <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f01010fb:	55                   	push   %ebp
f01010fc:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f01010fe:	83 fa 01             	cmp    $0x1,%edx
f0101101:	7e 0e                	jle    f0101111 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0101103:	8b 10                	mov    (%eax),%edx
f0101105:	8d 4a 08             	lea    0x8(%edx),%ecx
f0101108:	89 08                	mov    %ecx,(%eax)
f010110a:	8b 02                	mov    (%edx),%eax
f010110c:	8b 52 04             	mov    0x4(%edx),%edx
f010110f:	eb 22                	jmp    f0101133 <getuint+0x38>
	else if (lflag)
f0101111:	85 d2                	test   %edx,%edx
f0101113:	74 10                	je     f0101125 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0101115:	8b 10                	mov    (%eax),%edx
f0101117:	8d 4a 04             	lea    0x4(%edx),%ecx
f010111a:	89 08                	mov    %ecx,(%eax)
f010111c:	8b 02                	mov    (%edx),%eax
f010111e:	ba 00 00 00 00       	mov    $0x0,%edx
f0101123:	eb 0e                	jmp    f0101133 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0101125:	8b 10                	mov    (%eax),%edx
f0101127:	8d 4a 04             	lea    0x4(%edx),%ecx
f010112a:	89 08                	mov    %ecx,(%eax)
f010112c:	8b 02                	mov    (%edx),%eax
f010112e:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0101133:	5d                   	pop    %ebp
f0101134:	c3                   	ret    

f0101135 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0101135:	55                   	push   %ebp
f0101136:	89 e5                	mov    %esp,%ebp
f0101138:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f010113b:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f010113f:	8b 10                	mov    (%eax),%edx
f0101141:	3b 50 04             	cmp    0x4(%eax),%edx
f0101144:	73 0a                	jae    f0101150 <sprintputch+0x1b>
		*b->buf++ = ch;
f0101146:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101149:	88 0a                	mov    %cl,(%edx)
f010114b:	83 c2 01             	add    $0x1,%edx
f010114e:	89 10                	mov    %edx,(%eax)
}
f0101150:	5d                   	pop    %ebp
f0101151:	c3                   	ret    

f0101152 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0101152:	55                   	push   %ebp
f0101153:	89 e5                	mov    %esp,%ebp
f0101155:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f0101158:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f010115b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010115f:	8b 45 10             	mov    0x10(%ebp),%eax
f0101162:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101166:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101169:	89 44 24 04          	mov    %eax,0x4(%esp)
f010116d:	8b 45 08             	mov    0x8(%ebp),%eax
f0101170:	89 04 24             	mov    %eax,(%esp)
f0101173:	e8 02 00 00 00       	call   f010117a <vprintfmt>
	va_end(ap);
}
f0101178:	c9                   	leave  
f0101179:	c3                   	ret    

f010117a <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f010117a:	55                   	push   %ebp
f010117b:	89 e5                	mov    %esp,%ebp
f010117d:	57                   	push   %edi
f010117e:	56                   	push   %esi
f010117f:	53                   	push   %ebx
f0101180:	83 ec 4c             	sub    $0x4c,%esp
f0101183:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101186:	8b 75 10             	mov    0x10(%ebp),%esi
f0101189:	eb 12                	jmp    f010119d <vprintfmt+0x23>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f010118b:	85 c0                	test   %eax,%eax
f010118d:	0f 84 a9 03 00 00    	je     f010153c <vprintfmt+0x3c2>
				return;
			putch(ch, putdat);
f0101193:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101197:	89 04 24             	mov    %eax,(%esp)
f010119a:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f010119d:	0f b6 06             	movzbl (%esi),%eax
f01011a0:	83 c6 01             	add    $0x1,%esi
f01011a3:	83 f8 25             	cmp    $0x25,%eax
f01011a6:	75 e3                	jne    f010118b <vprintfmt+0x11>
f01011a8:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
f01011ac:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
f01011b3:	bf ff ff ff ff       	mov    $0xffffffff,%edi
f01011b8:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
f01011bf:	b9 00 00 00 00       	mov    $0x0,%ecx
f01011c4:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f01011c7:	eb 2b                	jmp    f01011f4 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01011c9:	8b 75 e0             	mov    -0x20(%ebp),%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f01011cc:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
f01011d0:	eb 22                	jmp    f01011f4 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01011d2:	8b 75 e0             	mov    -0x20(%ebp),%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f01011d5:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
f01011d9:	eb 19                	jmp    f01011f4 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01011db:	8b 75 e0             	mov    -0x20(%ebp),%esi
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
f01011de:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f01011e5:	eb 0d                	jmp    f01011f4 <vprintfmt+0x7a>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f01011e7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01011ea:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01011ed:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01011f4:	0f b6 06             	movzbl (%esi),%eax
f01011f7:	0f b6 d0             	movzbl %al,%edx
f01011fa:	8d 7e 01             	lea    0x1(%esi),%edi
f01011fd:	89 7d e0             	mov    %edi,-0x20(%ebp)
f0101200:	83 e8 23             	sub    $0x23,%eax
f0101203:	3c 55                	cmp    $0x55,%al
f0101205:	0f 87 0b 03 00 00    	ja     f0101516 <vprintfmt+0x39c>
f010120b:	0f b6 c0             	movzbl %al,%eax
f010120e:	ff 24 85 40 24 10 f0 	jmp    *-0xfefdbc0(,%eax,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0101215:	83 ea 30             	sub    $0x30,%edx
f0101218:	89 55 d4             	mov    %edx,-0x2c(%ebp)
				ch = *fmt;
f010121b:	0f be 46 01          	movsbl 0x1(%esi),%eax
				if (ch < '0' || ch > '9')
f010121f:	8d 50 d0             	lea    -0x30(%eax),%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101222:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
f0101225:	83 fa 09             	cmp    $0x9,%edx
f0101228:	77 4a                	ja     f0101274 <vprintfmt+0xfa>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010122a:	8b 7d d4             	mov    -0x2c(%ebp),%edi
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f010122d:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
f0101230:	8d 14 bf             	lea    (%edi,%edi,4),%edx
f0101233:	8d 7c 50 d0          	lea    -0x30(%eax,%edx,2),%edi
				ch = *fmt;
f0101237:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f010123a:	8d 50 d0             	lea    -0x30(%eax),%edx
f010123d:	83 fa 09             	cmp    $0x9,%edx
f0101240:	76 eb                	jbe    f010122d <vprintfmt+0xb3>
f0101242:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0101245:	eb 2d                	jmp    f0101274 <vprintfmt+0xfa>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0101247:	8b 45 14             	mov    0x14(%ebp),%eax
f010124a:	8d 50 04             	lea    0x4(%eax),%edx
f010124d:	89 55 14             	mov    %edx,0x14(%ebp)
f0101250:	8b 00                	mov    (%eax),%eax
f0101252:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101255:	8b 75 e0             	mov    -0x20(%ebp),%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0101258:	eb 1a                	jmp    f0101274 <vprintfmt+0xfa>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010125a:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case '*':
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
f010125d:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0101261:	79 91                	jns    f01011f4 <vprintfmt+0x7a>
f0101263:	e9 73 ff ff ff       	jmp    f01011db <vprintfmt+0x61>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101268:	8b 75 e0             	mov    -0x20(%ebp),%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f010126b:	c7 45 dc 01 00 00 00 	movl   $0x1,-0x24(%ebp)
			goto reswitch;
f0101272:	eb 80                	jmp    f01011f4 <vprintfmt+0x7a>

		process_precision:
			if (width < 0)
f0101274:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0101278:	0f 89 76 ff ff ff    	jns    f01011f4 <vprintfmt+0x7a>
f010127e:	e9 64 ff ff ff       	jmp    f01011e7 <vprintfmt+0x6d>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0101283:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101286:	8b 75 e0             	mov    -0x20(%ebp),%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0101289:	e9 66 ff ff ff       	jmp    f01011f4 <vprintfmt+0x7a>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f010128e:	8b 45 14             	mov    0x14(%ebp),%eax
f0101291:	8d 50 04             	lea    0x4(%eax),%edx
f0101294:	89 55 14             	mov    %edx,0x14(%ebp)
f0101297:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010129b:	8b 00                	mov    (%eax),%eax
f010129d:	89 04 24             	mov    %eax,(%esp)
f01012a0:	ff 55 08             	call   *0x8(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01012a3:	8b 75 e0             	mov    -0x20(%ebp),%esi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f01012a6:	e9 f2 fe ff ff       	jmp    f010119d <vprintfmt+0x23>

		// error message
		case 'e':
			err = va_arg(ap, int);
f01012ab:	8b 45 14             	mov    0x14(%ebp),%eax
f01012ae:	8d 50 04             	lea    0x4(%eax),%edx
f01012b1:	89 55 14             	mov    %edx,0x14(%ebp)
f01012b4:	8b 00                	mov    (%eax),%eax
f01012b6:	89 c2                	mov    %eax,%edx
f01012b8:	c1 fa 1f             	sar    $0x1f,%edx
f01012bb:	31 d0                	xor    %edx,%eax
f01012bd:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f01012bf:	83 f8 06             	cmp    $0x6,%eax
f01012c2:	7f 0b                	jg     f01012cf <vprintfmt+0x155>
f01012c4:	8b 14 85 98 25 10 f0 	mov    -0xfefda68(,%eax,4),%edx
f01012cb:	85 d2                	test   %edx,%edx
f01012cd:	75 23                	jne    f01012f2 <vprintfmt+0x178>
				printfmt(putch, putdat, "error %d", err);
f01012cf:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01012d3:	c7 44 24 08 cd 23 10 	movl   $0xf01023cd,0x8(%esp)
f01012da:	f0 
f01012db:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01012df:	8b 7d 08             	mov    0x8(%ebp),%edi
f01012e2:	89 3c 24             	mov    %edi,(%esp)
f01012e5:	e8 68 fe ff ff       	call   f0101152 <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01012ea:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f01012ed:	e9 ab fe ff ff       	jmp    f010119d <vprintfmt+0x23>
			else
				printfmt(putch, putdat, "%s", p);
f01012f2:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01012f6:	c7 44 24 08 da 20 10 	movl   $0xf01020da,0x8(%esp)
f01012fd:	f0 
f01012fe:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101302:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101305:	89 3c 24             	mov    %edi,(%esp)
f0101308:	e8 45 fe ff ff       	call   f0101152 <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010130d:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0101310:	e9 88 fe ff ff       	jmp    f010119d <vprintfmt+0x23>
f0101315:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0101318:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010131b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f010131e:	8b 45 14             	mov    0x14(%ebp),%eax
f0101321:	8d 50 04             	lea    0x4(%eax),%edx
f0101324:	89 55 14             	mov    %edx,0x14(%ebp)
f0101327:	8b 30                	mov    (%eax),%esi
				p = "(null)";
f0101329:	85 f6                	test   %esi,%esi
f010132b:	ba c6 23 10 f0       	mov    $0xf01023c6,%edx
f0101330:	0f 44 f2             	cmove  %edx,%esi
			if (width > 0 && padc != '-')
f0101333:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f0101337:	7e 06                	jle    f010133f <vprintfmt+0x1c5>
f0101339:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
f010133d:	75 10                	jne    f010134f <vprintfmt+0x1d5>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f010133f:	0f be 06             	movsbl (%esi),%eax
f0101342:	83 c6 01             	add    $0x1,%esi
f0101345:	85 c0                	test   %eax,%eax
f0101347:	0f 85 86 00 00 00    	jne    f01013d3 <vprintfmt+0x259>
f010134d:	eb 76                	jmp    f01013c5 <vprintfmt+0x24b>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010134f:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101353:	89 34 24             	mov    %esi,(%esp)
f0101356:	e8 60 03 00 00       	call   f01016bb <strnlen>
f010135b:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f010135e:	29 c2                	sub    %eax,%edx
f0101360:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0101363:	85 d2                	test   %edx,%edx
f0101365:	7e d8                	jle    f010133f <vprintfmt+0x1c5>
					putch(padc, putdat);
f0101367:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
f010136b:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f010136e:	89 d6                	mov    %edx,%esi
f0101370:	89 7d d0             	mov    %edi,-0x30(%ebp)
f0101373:	89 c7                	mov    %eax,%edi
f0101375:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101379:	89 3c 24             	mov    %edi,(%esp)
f010137c:	ff 55 08             	call   *0x8(%ebp)
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010137f:	83 ee 01             	sub    $0x1,%esi
f0101382:	75 f1                	jne    f0101375 <vprintfmt+0x1fb>
f0101384:	89 75 e4             	mov    %esi,-0x1c(%ebp)
f0101387:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f010138a:	8b 7d d0             	mov    -0x30(%ebp),%edi
f010138d:	eb b0                	jmp    f010133f <vprintfmt+0x1c5>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f010138f:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0101393:	74 18                	je     f01013ad <vprintfmt+0x233>
f0101395:	8d 50 e0             	lea    -0x20(%eax),%edx
f0101398:	83 fa 5e             	cmp    $0x5e,%edx
f010139b:	76 10                	jbe    f01013ad <vprintfmt+0x233>
					putch('?', putdat);
f010139d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01013a1:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f01013a8:	ff 55 08             	call   *0x8(%ebp)
f01013ab:	eb 0a                	jmp    f01013b7 <vprintfmt+0x23d>
				else
					putch(ch, putdat);
f01013ad:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01013b1:	89 04 24             	mov    %eax,(%esp)
f01013b4:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01013b7:	83 6d e4 01          	subl   $0x1,-0x1c(%ebp)
f01013bb:	0f be 06             	movsbl (%esi),%eax
f01013be:	83 c6 01             	add    $0x1,%esi
f01013c1:	85 c0                	test   %eax,%eax
f01013c3:	75 0e                	jne    f01013d3 <vprintfmt+0x259>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01013c5:	8b 75 e0             	mov    -0x20(%ebp),%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f01013c8:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01013cc:	7f 16                	jg     f01013e4 <vprintfmt+0x26a>
f01013ce:	e9 ca fd ff ff       	jmp    f010119d <vprintfmt+0x23>
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01013d3:	85 ff                	test   %edi,%edi
f01013d5:	78 b8                	js     f010138f <vprintfmt+0x215>
f01013d7:	83 ef 01             	sub    $0x1,%edi
f01013da:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01013e0:	79 ad                	jns    f010138f <vprintfmt+0x215>
f01013e2:	eb e1                	jmp    f01013c5 <vprintfmt+0x24b>
f01013e4:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01013e7:	8b 7d 08             	mov    0x8(%ebp),%edi
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f01013ea:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01013ee:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f01013f5:	ff d7                	call   *%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f01013f7:	83 ee 01             	sub    $0x1,%esi
f01013fa:	75 ee                	jne    f01013ea <vprintfmt+0x270>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01013fc:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01013ff:	e9 99 fd ff ff       	jmp    f010119d <vprintfmt+0x23>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0101404:	83 f9 01             	cmp    $0x1,%ecx
f0101407:	7e 10                	jle    f0101419 <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f0101409:	8b 45 14             	mov    0x14(%ebp),%eax
f010140c:	8d 50 08             	lea    0x8(%eax),%edx
f010140f:	89 55 14             	mov    %edx,0x14(%ebp)
f0101412:	8b 30                	mov    (%eax),%esi
f0101414:	8b 78 04             	mov    0x4(%eax),%edi
f0101417:	eb 26                	jmp    f010143f <vprintfmt+0x2c5>
	else if (lflag)
f0101419:	85 c9                	test   %ecx,%ecx
f010141b:	74 12                	je     f010142f <vprintfmt+0x2b5>
		return va_arg(*ap, long);
f010141d:	8b 45 14             	mov    0x14(%ebp),%eax
f0101420:	8d 50 04             	lea    0x4(%eax),%edx
f0101423:	89 55 14             	mov    %edx,0x14(%ebp)
f0101426:	8b 30                	mov    (%eax),%esi
f0101428:	89 f7                	mov    %esi,%edi
f010142a:	c1 ff 1f             	sar    $0x1f,%edi
f010142d:	eb 10                	jmp    f010143f <vprintfmt+0x2c5>
	else
		return va_arg(*ap, int);
f010142f:	8b 45 14             	mov    0x14(%ebp),%eax
f0101432:	8d 50 04             	lea    0x4(%eax),%edx
f0101435:	89 55 14             	mov    %edx,0x14(%ebp)
f0101438:	8b 30                	mov    (%eax),%esi
f010143a:	89 f7                	mov    %esi,%edi
f010143c:	c1 ff 1f             	sar    $0x1f,%edi
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f010143f:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0101444:	85 ff                	test   %edi,%edi
f0101446:	0f 89 8c 00 00 00    	jns    f01014d8 <vprintfmt+0x35e>
				putch('-', putdat);
f010144c:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101450:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f0101457:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f010145a:	f7 de                	neg    %esi
f010145c:	83 d7 00             	adc    $0x0,%edi
f010145f:	f7 df                	neg    %edi
			}
			base = 10;
f0101461:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101466:	eb 70                	jmp    f01014d8 <vprintfmt+0x35e>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0101468:	89 ca                	mov    %ecx,%edx
f010146a:	8d 45 14             	lea    0x14(%ebp),%eax
f010146d:	e8 89 fc ff ff       	call   f01010fb <getuint>
f0101472:	89 c6                	mov    %eax,%esi
f0101474:	89 d7                	mov    %edx,%edi
			base = 10;
f0101476:	b8 0a 00 00 00       	mov    $0xa,%eax
			goto number;
f010147b:	eb 5b                	jmp    f01014d8 <vprintfmt+0x35e>
			// Replace this with your code.
			//putch('0', putdat);
			//putch('X', putdat);
			//putch('X', putdat);
			//break;
			num = getuint(&ap, lflag);
f010147d:	89 ca                	mov    %ecx,%edx
f010147f:	8d 45 14             	lea    0x14(%ebp),%eax
f0101482:	e8 74 fc ff ff       	call   f01010fb <getuint>
f0101487:	89 c6                	mov    %eax,%esi
f0101489:	89 d7                	mov    %edx,%edi
			base = 8;
f010148b:	b8 08 00 00 00       	mov    $0x8,%eax
			goto number;
f0101490:	eb 46                	jmp    f01014d8 <vprintfmt+0x35e>
		// pointer
		case 'p':
			putch('0', putdat);
f0101492:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101496:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f010149d:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f01014a0:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01014a4:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f01014ab:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f01014ae:	8b 45 14             	mov    0x14(%ebp),%eax
f01014b1:	8d 50 04             	lea    0x4(%eax),%edx
f01014b4:	89 55 14             	mov    %edx,0x14(%ebp)
			goto number;
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f01014b7:	8b 30                	mov    (%eax),%esi
f01014b9:	bf 00 00 00 00       	mov    $0x0,%edi
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f01014be:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f01014c3:	eb 13                	jmp    f01014d8 <vprintfmt+0x35e>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f01014c5:	89 ca                	mov    %ecx,%edx
f01014c7:	8d 45 14             	lea    0x14(%ebp),%eax
f01014ca:	e8 2c fc ff ff       	call   f01010fb <getuint>
f01014cf:	89 c6                	mov    %eax,%esi
f01014d1:	89 d7                	mov    %edx,%edi
			base = 16;
f01014d3:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f01014d8:	0f be 55 d8          	movsbl -0x28(%ebp),%edx
f01014dc:	89 54 24 10          	mov    %edx,0x10(%esp)
f01014e0:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01014e3:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01014e7:	89 44 24 08          	mov    %eax,0x8(%esp)
f01014eb:	89 34 24             	mov    %esi,(%esp)
f01014ee:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01014f2:	89 da                	mov    %ebx,%edx
f01014f4:	8b 45 08             	mov    0x8(%ebp),%eax
f01014f7:	e8 24 fb ff ff       	call   f0101020 <printnum>
			break;
f01014fc:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01014ff:	e9 99 fc ff ff       	jmp    f010119d <vprintfmt+0x23>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0101504:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101508:	89 14 24             	mov    %edx,(%esp)
f010150b:	ff 55 08             	call   *0x8(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010150e:	8b 75 e0             	mov    -0x20(%ebp),%esi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0101511:	e9 87 fc ff ff       	jmp    f010119d <vprintfmt+0x23>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0101516:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010151a:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0101521:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0101524:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
f0101528:	0f 84 6f fc ff ff    	je     f010119d <vprintfmt+0x23>
f010152e:	83 ee 01             	sub    $0x1,%esi
f0101531:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
f0101535:	75 f7                	jne    f010152e <vprintfmt+0x3b4>
f0101537:	e9 61 fc ff ff       	jmp    f010119d <vprintfmt+0x23>
				/* do nothing */;
			break;
		}
	}
}
f010153c:	83 c4 4c             	add    $0x4c,%esp
f010153f:	5b                   	pop    %ebx
f0101540:	5e                   	pop    %esi
f0101541:	5f                   	pop    %edi
f0101542:	5d                   	pop    %ebp
f0101543:	c3                   	ret    

f0101544 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0101544:	55                   	push   %ebp
f0101545:	89 e5                	mov    %esp,%ebp
f0101547:	83 ec 28             	sub    $0x28,%esp
f010154a:	8b 45 08             	mov    0x8(%ebp),%eax
f010154d:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0101550:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101553:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0101557:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f010155a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0101561:	85 c0                	test   %eax,%eax
f0101563:	74 30                	je     f0101595 <vsnprintf+0x51>
f0101565:	85 d2                	test   %edx,%edx
f0101567:	7e 2c                	jle    f0101595 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0101569:	8b 45 14             	mov    0x14(%ebp),%eax
f010156c:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101570:	8b 45 10             	mov    0x10(%ebp),%eax
f0101573:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101577:	8d 45 ec             	lea    -0x14(%ebp),%eax
f010157a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010157e:	c7 04 24 35 11 10 f0 	movl   $0xf0101135,(%esp)
f0101585:	e8 f0 fb ff ff       	call   f010117a <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f010158a:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010158d:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0101590:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101593:	eb 05                	jmp    f010159a <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0101595:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f010159a:	c9                   	leave  
f010159b:	c3                   	ret    

f010159c <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010159c:	55                   	push   %ebp
f010159d:	89 e5                	mov    %esp,%ebp
f010159f:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f01015a2:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f01015a5:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01015a9:	8b 45 10             	mov    0x10(%ebp),%eax
f01015ac:	89 44 24 08          	mov    %eax,0x8(%esp)
f01015b0:	8b 45 0c             	mov    0xc(%ebp),%eax
f01015b3:	89 44 24 04          	mov    %eax,0x4(%esp)
f01015b7:	8b 45 08             	mov    0x8(%ebp),%eax
f01015ba:	89 04 24             	mov    %eax,(%esp)
f01015bd:	e8 82 ff ff ff       	call   f0101544 <vsnprintf>
	va_end(ap);

	return rc;
}
f01015c2:	c9                   	leave  
f01015c3:	c3                   	ret    
	...

f01015d0 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01015d0:	55                   	push   %ebp
f01015d1:	89 e5                	mov    %esp,%ebp
f01015d3:	57                   	push   %edi
f01015d4:	56                   	push   %esi
f01015d5:	53                   	push   %ebx
f01015d6:	83 ec 1c             	sub    $0x1c,%esp
f01015d9:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01015dc:	85 c0                	test   %eax,%eax
f01015de:	74 10                	je     f01015f0 <readline+0x20>
		cprintf("%s", prompt);
f01015e0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01015e4:	c7 04 24 da 20 10 f0 	movl   $0xf01020da,(%esp)
f01015eb:	e8 d6 f6 ff ff       	call   f0100cc6 <cprintf>

	i = 0;
	echoing = iscons(0);
f01015f0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01015f7:	e8 7e f0 ff ff       	call   f010067a <iscons>
f01015fc:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f01015fe:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0101603:	e8 61 f0 ff ff       	call   f0100669 <getchar>
f0101608:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010160a:	85 c0                	test   %eax,%eax
f010160c:	79 17                	jns    f0101625 <readline+0x55>
			cprintf("read error: %e\n", c);
f010160e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101612:	c7 04 24 b4 25 10 f0 	movl   $0xf01025b4,(%esp)
f0101619:	e8 a8 f6 ff ff       	call   f0100cc6 <cprintf>
			return NULL;
f010161e:	b8 00 00 00 00       	mov    $0x0,%eax
f0101623:	eb 6d                	jmp    f0101692 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101625:	83 f8 08             	cmp    $0x8,%eax
f0101628:	74 05                	je     f010162f <readline+0x5f>
f010162a:	83 f8 7f             	cmp    $0x7f,%eax
f010162d:	75 19                	jne    f0101648 <readline+0x78>
f010162f:	85 f6                	test   %esi,%esi
f0101631:	7e 15                	jle    f0101648 <readline+0x78>
			if (echoing)
f0101633:	85 ff                	test   %edi,%edi
f0101635:	74 0c                	je     f0101643 <readline+0x73>
				cputchar('\b');
f0101637:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f010163e:	e8 16 f0 ff ff       	call   f0100659 <cputchar>
			i--;
f0101643:	83 ee 01             	sub    $0x1,%esi
f0101646:	eb bb                	jmp    f0101603 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101648:	83 fb 1f             	cmp    $0x1f,%ebx
f010164b:	7e 1f                	jle    f010166c <readline+0x9c>
f010164d:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0101653:	7f 17                	jg     f010166c <readline+0x9c>
			if (echoing)
f0101655:	85 ff                	test   %edi,%edi
f0101657:	74 08                	je     f0101661 <readline+0x91>
				cputchar(c);
f0101659:	89 1c 24             	mov    %ebx,(%esp)
f010165c:	e8 f8 ef ff ff       	call   f0100659 <cputchar>
			buf[i++] = c;
f0101661:	88 9e 60 35 11 f0    	mov    %bl,-0xfeecaa0(%esi)
f0101667:	83 c6 01             	add    $0x1,%esi
f010166a:	eb 97                	jmp    f0101603 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f010166c:	83 fb 0a             	cmp    $0xa,%ebx
f010166f:	74 05                	je     f0101676 <readline+0xa6>
f0101671:	83 fb 0d             	cmp    $0xd,%ebx
f0101674:	75 8d                	jne    f0101603 <readline+0x33>
			if (echoing)
f0101676:	85 ff                	test   %edi,%edi
f0101678:	74 0c                	je     f0101686 <readline+0xb6>
				cputchar('\n');
f010167a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0101681:	e8 d3 ef ff ff       	call   f0100659 <cputchar>
			buf[i] = 0;
f0101686:	c6 86 60 35 11 f0 00 	movb   $0x0,-0xfeecaa0(%esi)
			return buf;
f010168d:	b8 60 35 11 f0       	mov    $0xf0113560,%eax
		}
	}
}
f0101692:	83 c4 1c             	add    $0x1c,%esp
f0101695:	5b                   	pop    %ebx
f0101696:	5e                   	pop    %esi
f0101697:	5f                   	pop    %edi
f0101698:	5d                   	pop    %ebp
f0101699:	c3                   	ret    
f010169a:	00 00                	add    %al,(%eax)
f010169c:	00 00                	add    %al,(%eax)
	...

f01016a0 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f01016a0:	55                   	push   %ebp
f01016a1:	89 e5                	mov    %esp,%ebp
f01016a3:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f01016a6:	b8 00 00 00 00       	mov    $0x0,%eax
f01016ab:	80 3a 00             	cmpb   $0x0,(%edx)
f01016ae:	74 09                	je     f01016b9 <strlen+0x19>
		n++;
f01016b0:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01016b3:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01016b7:	75 f7                	jne    f01016b0 <strlen+0x10>
		n++;
	return n;
}
f01016b9:	5d                   	pop    %ebp
f01016ba:	c3                   	ret    

f01016bb <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01016bb:	55                   	push   %ebp
f01016bc:	89 e5                	mov    %esp,%ebp
f01016be:	53                   	push   %ebx
f01016bf:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01016c2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01016c5:	b8 00 00 00 00       	mov    $0x0,%eax
f01016ca:	85 c9                	test   %ecx,%ecx
f01016cc:	74 1a                	je     f01016e8 <strnlen+0x2d>
f01016ce:	80 3b 00             	cmpb   $0x0,(%ebx)
f01016d1:	74 15                	je     f01016e8 <strnlen+0x2d>
f01016d3:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
f01016d8:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01016da:	39 ca                	cmp    %ecx,%edx
f01016dc:	74 0a                	je     f01016e8 <strnlen+0x2d>
f01016de:	83 c2 01             	add    $0x1,%edx
f01016e1:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
f01016e6:	75 f0                	jne    f01016d8 <strnlen+0x1d>
		n++;
	return n;
}
f01016e8:	5b                   	pop    %ebx
f01016e9:	5d                   	pop    %ebp
f01016ea:	c3                   	ret    

f01016eb <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01016eb:	55                   	push   %ebp
f01016ec:	89 e5                	mov    %esp,%ebp
f01016ee:	53                   	push   %ebx
f01016ef:	8b 45 08             	mov    0x8(%ebp),%eax
f01016f2:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01016f5:	ba 00 00 00 00       	mov    $0x0,%edx
f01016fa:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f01016fe:	88 0c 10             	mov    %cl,(%eax,%edx,1)
f0101701:	83 c2 01             	add    $0x1,%edx
f0101704:	84 c9                	test   %cl,%cl
f0101706:	75 f2                	jne    f01016fa <strcpy+0xf>
		/* do nothing */;
	return ret;
}
f0101708:	5b                   	pop    %ebx
f0101709:	5d                   	pop    %ebp
f010170a:	c3                   	ret    

f010170b <strcat>:

char *
strcat(char *dst, const char *src)
{
f010170b:	55                   	push   %ebp
f010170c:	89 e5                	mov    %esp,%ebp
f010170e:	53                   	push   %ebx
f010170f:	83 ec 08             	sub    $0x8,%esp
f0101712:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0101715:	89 1c 24             	mov    %ebx,(%esp)
f0101718:	e8 83 ff ff ff       	call   f01016a0 <strlen>
	strcpy(dst + len, src);
f010171d:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101720:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101724:	01 d8                	add    %ebx,%eax
f0101726:	89 04 24             	mov    %eax,(%esp)
f0101729:	e8 bd ff ff ff       	call   f01016eb <strcpy>
	return dst;
}
f010172e:	89 d8                	mov    %ebx,%eax
f0101730:	83 c4 08             	add    $0x8,%esp
f0101733:	5b                   	pop    %ebx
f0101734:	5d                   	pop    %ebp
f0101735:	c3                   	ret    

f0101736 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0101736:	55                   	push   %ebp
f0101737:	89 e5                	mov    %esp,%ebp
f0101739:	56                   	push   %esi
f010173a:	53                   	push   %ebx
f010173b:	8b 45 08             	mov    0x8(%ebp),%eax
f010173e:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101741:	8b 75 10             	mov    0x10(%ebp),%esi
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101744:	85 f6                	test   %esi,%esi
f0101746:	74 18                	je     f0101760 <strncpy+0x2a>
f0101748:	b9 00 00 00 00       	mov    $0x0,%ecx
		*dst++ = *src;
f010174d:	0f b6 1a             	movzbl (%edx),%ebx
f0101750:	88 1c 08             	mov    %bl,(%eax,%ecx,1)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0101753:	80 3a 01             	cmpb   $0x1,(%edx)
f0101756:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101759:	83 c1 01             	add    $0x1,%ecx
f010175c:	39 f1                	cmp    %esi,%ecx
f010175e:	75 ed                	jne    f010174d <strncpy+0x17>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0101760:	5b                   	pop    %ebx
f0101761:	5e                   	pop    %esi
f0101762:	5d                   	pop    %ebp
f0101763:	c3                   	ret    

f0101764 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0101764:	55                   	push   %ebp
f0101765:	89 e5                	mov    %esp,%ebp
f0101767:	57                   	push   %edi
f0101768:	56                   	push   %esi
f0101769:	53                   	push   %ebx
f010176a:	8b 7d 08             	mov    0x8(%ebp),%edi
f010176d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101770:	8b 75 10             	mov    0x10(%ebp),%esi
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0101773:	89 f8                	mov    %edi,%eax
f0101775:	85 f6                	test   %esi,%esi
f0101777:	74 2b                	je     f01017a4 <strlcpy+0x40>
		while (--size > 0 && *src != '\0')
f0101779:	83 fe 01             	cmp    $0x1,%esi
f010177c:	74 23                	je     f01017a1 <strlcpy+0x3d>
f010177e:	0f b6 0b             	movzbl (%ebx),%ecx
f0101781:	84 c9                	test   %cl,%cl
f0101783:	74 1c                	je     f01017a1 <strlcpy+0x3d>
	}
	return ret;
}

size_t
strlcpy(char *dst, const char *src, size_t size)
f0101785:	83 ee 02             	sub    $0x2,%esi
f0101788:	ba 00 00 00 00       	mov    $0x0,%edx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f010178d:	88 08                	mov    %cl,(%eax)
f010178f:	83 c0 01             	add    $0x1,%eax
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0101792:	39 f2                	cmp    %esi,%edx
f0101794:	74 0b                	je     f01017a1 <strlcpy+0x3d>
f0101796:	83 c2 01             	add    $0x1,%edx
f0101799:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f010179d:	84 c9                	test   %cl,%cl
f010179f:	75 ec                	jne    f010178d <strlcpy+0x29>
			*dst++ = *src++;
		*dst = '\0';
f01017a1:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f01017a4:	29 f8                	sub    %edi,%eax
}
f01017a6:	5b                   	pop    %ebx
f01017a7:	5e                   	pop    %esi
f01017a8:	5f                   	pop    %edi
f01017a9:	5d                   	pop    %ebp
f01017aa:	c3                   	ret    

f01017ab <strcmp>:

int
strcmp(const char *p, const char *q)
{
f01017ab:	55                   	push   %ebp
f01017ac:	89 e5                	mov    %esp,%ebp
f01017ae:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01017b1:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01017b4:	0f b6 01             	movzbl (%ecx),%eax
f01017b7:	84 c0                	test   %al,%al
f01017b9:	74 16                	je     f01017d1 <strcmp+0x26>
f01017bb:	3a 02                	cmp    (%edx),%al
f01017bd:	75 12                	jne    f01017d1 <strcmp+0x26>
		p++, q++;
f01017bf:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01017c2:	0f b6 41 01          	movzbl 0x1(%ecx),%eax
f01017c6:	84 c0                	test   %al,%al
f01017c8:	74 07                	je     f01017d1 <strcmp+0x26>
f01017ca:	83 c1 01             	add    $0x1,%ecx
f01017cd:	3a 02                	cmp    (%edx),%al
f01017cf:	74 ee                	je     f01017bf <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01017d1:	0f b6 c0             	movzbl %al,%eax
f01017d4:	0f b6 12             	movzbl (%edx),%edx
f01017d7:	29 d0                	sub    %edx,%eax
}
f01017d9:	5d                   	pop    %ebp
f01017da:	c3                   	ret    

f01017db <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01017db:	55                   	push   %ebp
f01017dc:	89 e5                	mov    %esp,%ebp
f01017de:	53                   	push   %ebx
f01017df:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01017e2:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01017e5:	8b 55 10             	mov    0x10(%ebp),%edx
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f01017e8:	b8 00 00 00 00       	mov    $0x0,%eax
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01017ed:	85 d2                	test   %edx,%edx
f01017ef:	74 28                	je     f0101819 <strncmp+0x3e>
f01017f1:	0f b6 01             	movzbl (%ecx),%eax
f01017f4:	84 c0                	test   %al,%al
f01017f6:	74 24                	je     f010181c <strncmp+0x41>
f01017f8:	3a 03                	cmp    (%ebx),%al
f01017fa:	75 20                	jne    f010181c <strncmp+0x41>
f01017fc:	83 ea 01             	sub    $0x1,%edx
f01017ff:	74 13                	je     f0101814 <strncmp+0x39>
		n--, p++, q++;
f0101801:	83 c1 01             	add    $0x1,%ecx
f0101804:	83 c3 01             	add    $0x1,%ebx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0101807:	0f b6 01             	movzbl (%ecx),%eax
f010180a:	84 c0                	test   %al,%al
f010180c:	74 0e                	je     f010181c <strncmp+0x41>
f010180e:	3a 03                	cmp    (%ebx),%al
f0101810:	74 ea                	je     f01017fc <strncmp+0x21>
f0101812:	eb 08                	jmp    f010181c <strncmp+0x41>
		n--, p++, q++;
	if (n == 0)
		return 0;
f0101814:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0101819:	5b                   	pop    %ebx
f010181a:	5d                   	pop    %ebp
f010181b:	c3                   	ret    
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f010181c:	0f b6 01             	movzbl (%ecx),%eax
f010181f:	0f b6 13             	movzbl (%ebx),%edx
f0101822:	29 d0                	sub    %edx,%eax
f0101824:	eb f3                	jmp    f0101819 <strncmp+0x3e>

f0101826 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0101826:	55                   	push   %ebp
f0101827:	89 e5                	mov    %esp,%ebp
f0101829:	8b 45 08             	mov    0x8(%ebp),%eax
f010182c:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101830:	0f b6 10             	movzbl (%eax),%edx
f0101833:	84 d2                	test   %dl,%dl
f0101835:	74 1c                	je     f0101853 <strchr+0x2d>
		if (*s == c)
f0101837:	38 ca                	cmp    %cl,%dl
f0101839:	75 09                	jne    f0101844 <strchr+0x1e>
f010183b:	eb 1b                	jmp    f0101858 <strchr+0x32>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f010183d:	83 c0 01             	add    $0x1,%eax
		if (*s == c)
f0101840:	38 ca                	cmp    %cl,%dl
f0101842:	74 14                	je     f0101858 <strchr+0x32>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0101844:	0f b6 50 01          	movzbl 0x1(%eax),%edx
f0101848:	84 d2                	test   %dl,%dl
f010184a:	75 f1                	jne    f010183d <strchr+0x17>
		if (*s == c)
			return (char *) s;
	return 0;
f010184c:	b8 00 00 00 00       	mov    $0x0,%eax
f0101851:	eb 05                	jmp    f0101858 <strchr+0x32>
f0101853:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101858:	5d                   	pop    %ebp
f0101859:	c3                   	ret    

f010185a <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010185a:	55                   	push   %ebp
f010185b:	89 e5                	mov    %esp,%ebp
f010185d:	8b 45 08             	mov    0x8(%ebp),%eax
f0101860:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101864:	0f b6 10             	movzbl (%eax),%edx
f0101867:	84 d2                	test   %dl,%dl
f0101869:	74 14                	je     f010187f <strfind+0x25>
		if (*s == c)
f010186b:	38 ca                	cmp    %cl,%dl
f010186d:	75 06                	jne    f0101875 <strfind+0x1b>
f010186f:	eb 0e                	jmp    f010187f <strfind+0x25>
f0101871:	38 ca                	cmp    %cl,%dl
f0101873:	74 0a                	je     f010187f <strfind+0x25>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f0101875:	83 c0 01             	add    $0x1,%eax
f0101878:	0f b6 10             	movzbl (%eax),%edx
f010187b:	84 d2                	test   %dl,%dl
f010187d:	75 f2                	jne    f0101871 <strfind+0x17>
		if (*s == c)
			break;
	return (char *) s;
}
f010187f:	5d                   	pop    %ebp
f0101880:	c3                   	ret    

f0101881 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0101881:	55                   	push   %ebp
f0101882:	89 e5                	mov    %esp,%ebp
f0101884:	83 ec 0c             	sub    $0xc,%esp
f0101887:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f010188a:	89 75 f8             	mov    %esi,-0x8(%ebp)
f010188d:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0101890:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101893:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101896:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0101899:	85 c9                	test   %ecx,%ecx
f010189b:	74 30                	je     f01018cd <memset+0x4c>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f010189d:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01018a3:	75 25                	jne    f01018ca <memset+0x49>
f01018a5:	f6 c1 03             	test   $0x3,%cl
f01018a8:	75 20                	jne    f01018ca <memset+0x49>
		c &= 0xFF;
f01018aa:	0f b6 d0             	movzbl %al,%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f01018ad:	89 d3                	mov    %edx,%ebx
f01018af:	c1 e3 08             	shl    $0x8,%ebx
f01018b2:	89 d6                	mov    %edx,%esi
f01018b4:	c1 e6 18             	shl    $0x18,%esi
f01018b7:	89 d0                	mov    %edx,%eax
f01018b9:	c1 e0 10             	shl    $0x10,%eax
f01018bc:	09 f0                	or     %esi,%eax
f01018be:	09 d0                	or     %edx,%eax
f01018c0:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f01018c2:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f01018c5:	fc                   	cld    
f01018c6:	f3 ab                	rep stos %eax,%es:(%edi)
f01018c8:	eb 03                	jmp    f01018cd <memset+0x4c>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01018ca:	fc                   	cld    
f01018cb:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01018cd:	89 f8                	mov    %edi,%eax
f01018cf:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f01018d2:	8b 75 f8             	mov    -0x8(%ebp),%esi
f01018d5:	8b 7d fc             	mov    -0x4(%ebp),%edi
f01018d8:	89 ec                	mov    %ebp,%esp
f01018da:	5d                   	pop    %ebp
f01018db:	c3                   	ret    

f01018dc <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01018dc:	55                   	push   %ebp
f01018dd:	89 e5                	mov    %esp,%ebp
f01018df:	83 ec 08             	sub    $0x8,%esp
f01018e2:	89 75 f8             	mov    %esi,-0x8(%ebp)
f01018e5:	89 7d fc             	mov    %edi,-0x4(%ebp)
f01018e8:	8b 45 08             	mov    0x8(%ebp),%eax
f01018eb:	8b 75 0c             	mov    0xc(%ebp),%esi
f01018ee:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01018f1:	39 c6                	cmp    %eax,%esi
f01018f3:	73 36                	jae    f010192b <memmove+0x4f>
f01018f5:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01018f8:	39 d0                	cmp    %edx,%eax
f01018fa:	73 2f                	jae    f010192b <memmove+0x4f>
		s += n;
		d += n;
f01018fc:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01018ff:	f6 c2 03             	test   $0x3,%dl
f0101902:	75 1b                	jne    f010191f <memmove+0x43>
f0101904:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010190a:	75 13                	jne    f010191f <memmove+0x43>
f010190c:	f6 c1 03             	test   $0x3,%cl
f010190f:	75 0e                	jne    f010191f <memmove+0x43>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0101911:	83 ef 04             	sub    $0x4,%edi
f0101914:	8d 72 fc             	lea    -0x4(%edx),%esi
f0101917:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f010191a:	fd                   	std    
f010191b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010191d:	eb 09                	jmp    f0101928 <memmove+0x4c>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f010191f:	83 ef 01             	sub    $0x1,%edi
f0101922:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0101925:	fd                   	std    
f0101926:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0101928:	fc                   	cld    
f0101929:	eb 20                	jmp    f010194b <memmove+0x6f>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010192b:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0101931:	75 13                	jne    f0101946 <memmove+0x6a>
f0101933:	a8 03                	test   $0x3,%al
f0101935:	75 0f                	jne    f0101946 <memmove+0x6a>
f0101937:	f6 c1 03             	test   $0x3,%cl
f010193a:	75 0a                	jne    f0101946 <memmove+0x6a>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f010193c:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f010193f:	89 c7                	mov    %eax,%edi
f0101941:	fc                   	cld    
f0101942:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101944:	eb 05                	jmp    f010194b <memmove+0x6f>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0101946:	89 c7                	mov    %eax,%edi
f0101948:	fc                   	cld    
f0101949:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f010194b:	8b 75 f8             	mov    -0x8(%ebp),%esi
f010194e:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0101951:	89 ec                	mov    %ebp,%esp
f0101953:	5d                   	pop    %ebp
f0101954:	c3                   	ret    

f0101955 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0101955:	55                   	push   %ebp
f0101956:	89 e5                	mov    %esp,%ebp
f0101958:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f010195b:	8b 45 10             	mov    0x10(%ebp),%eax
f010195e:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101962:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101965:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101969:	8b 45 08             	mov    0x8(%ebp),%eax
f010196c:	89 04 24             	mov    %eax,(%esp)
f010196f:	e8 68 ff ff ff       	call   f01018dc <memmove>
}
f0101974:	c9                   	leave  
f0101975:	c3                   	ret    

f0101976 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0101976:	55                   	push   %ebp
f0101977:	89 e5                	mov    %esp,%ebp
f0101979:	57                   	push   %edi
f010197a:	56                   	push   %esi
f010197b:	53                   	push   %ebx
f010197c:	8b 5d 08             	mov    0x8(%ebp),%ebx
f010197f:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101982:	8b 7d 10             	mov    0x10(%ebp),%edi
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0101985:	b8 00 00 00 00       	mov    $0x0,%eax
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010198a:	85 ff                	test   %edi,%edi
f010198c:	74 37                	je     f01019c5 <memcmp+0x4f>
		if (*s1 != *s2)
f010198e:	0f b6 03             	movzbl (%ebx),%eax
f0101991:	0f b6 0e             	movzbl (%esi),%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101994:	83 ef 01             	sub    $0x1,%edi
f0101997:	ba 00 00 00 00       	mov    $0x0,%edx
		if (*s1 != *s2)
f010199c:	38 c8                	cmp    %cl,%al
f010199e:	74 1c                	je     f01019bc <memcmp+0x46>
f01019a0:	eb 10                	jmp    f01019b2 <memcmp+0x3c>
f01019a2:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
f01019a7:	83 c2 01             	add    $0x1,%edx
f01019aa:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
f01019ae:	38 c8                	cmp    %cl,%al
f01019b0:	74 0a                	je     f01019bc <memcmp+0x46>
			return (int) *s1 - (int) *s2;
f01019b2:	0f b6 c0             	movzbl %al,%eax
f01019b5:	0f b6 c9             	movzbl %cl,%ecx
f01019b8:	29 c8                	sub    %ecx,%eax
f01019ba:	eb 09                	jmp    f01019c5 <memcmp+0x4f>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01019bc:	39 fa                	cmp    %edi,%edx
f01019be:	75 e2                	jne    f01019a2 <memcmp+0x2c>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01019c0:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01019c5:	5b                   	pop    %ebx
f01019c6:	5e                   	pop    %esi
f01019c7:	5f                   	pop    %edi
f01019c8:	5d                   	pop    %ebp
f01019c9:	c3                   	ret    

f01019ca <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01019ca:	55                   	push   %ebp
f01019cb:	89 e5                	mov    %esp,%ebp
f01019cd:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f01019d0:	89 c2                	mov    %eax,%edx
f01019d2:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f01019d5:	39 d0                	cmp    %edx,%eax
f01019d7:	73 19                	jae    f01019f2 <memfind+0x28>
		if (*(const unsigned char *) s == (unsigned char) c)
f01019d9:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
f01019dd:	38 08                	cmp    %cl,(%eax)
f01019df:	75 06                	jne    f01019e7 <memfind+0x1d>
f01019e1:	eb 0f                	jmp    f01019f2 <memfind+0x28>
f01019e3:	38 08                	cmp    %cl,(%eax)
f01019e5:	74 0b                	je     f01019f2 <memfind+0x28>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01019e7:	83 c0 01             	add    $0x1,%eax
f01019ea:	39 d0                	cmp    %edx,%eax
f01019ec:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01019f0:	75 f1                	jne    f01019e3 <memfind+0x19>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01019f2:	5d                   	pop    %ebp
f01019f3:	c3                   	ret    

f01019f4 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01019f4:	55                   	push   %ebp
f01019f5:	89 e5                	mov    %esp,%ebp
f01019f7:	57                   	push   %edi
f01019f8:	56                   	push   %esi
f01019f9:	53                   	push   %ebx
f01019fa:	8b 55 08             	mov    0x8(%ebp),%edx
f01019fd:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101a00:	0f b6 02             	movzbl (%edx),%eax
f0101a03:	3c 20                	cmp    $0x20,%al
f0101a05:	74 04                	je     f0101a0b <strtol+0x17>
f0101a07:	3c 09                	cmp    $0x9,%al
f0101a09:	75 0e                	jne    f0101a19 <strtol+0x25>
		s++;
f0101a0b:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101a0e:	0f b6 02             	movzbl (%edx),%eax
f0101a11:	3c 20                	cmp    $0x20,%al
f0101a13:	74 f6                	je     f0101a0b <strtol+0x17>
f0101a15:	3c 09                	cmp    $0x9,%al
f0101a17:	74 f2                	je     f0101a0b <strtol+0x17>
		s++;

	// plus/minus sign
	if (*s == '+')
f0101a19:	3c 2b                	cmp    $0x2b,%al
f0101a1b:	75 0a                	jne    f0101a27 <strtol+0x33>
		s++;
f0101a1d:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0101a20:	bf 00 00 00 00       	mov    $0x0,%edi
f0101a25:	eb 10                	jmp    f0101a37 <strtol+0x43>
f0101a27:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0101a2c:	3c 2d                	cmp    $0x2d,%al
f0101a2e:	75 07                	jne    f0101a37 <strtol+0x43>
		s++, neg = 1;
f0101a30:	83 c2 01             	add    $0x1,%edx
f0101a33:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0101a37:	85 db                	test   %ebx,%ebx
f0101a39:	0f 94 c0             	sete   %al
f0101a3c:	74 05                	je     f0101a43 <strtol+0x4f>
f0101a3e:	83 fb 10             	cmp    $0x10,%ebx
f0101a41:	75 15                	jne    f0101a58 <strtol+0x64>
f0101a43:	80 3a 30             	cmpb   $0x30,(%edx)
f0101a46:	75 10                	jne    f0101a58 <strtol+0x64>
f0101a48:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0101a4c:	75 0a                	jne    f0101a58 <strtol+0x64>
		s += 2, base = 16;
f0101a4e:	83 c2 02             	add    $0x2,%edx
f0101a51:	bb 10 00 00 00       	mov    $0x10,%ebx
f0101a56:	eb 13                	jmp    f0101a6b <strtol+0x77>
	else if (base == 0 && s[0] == '0')
f0101a58:	84 c0                	test   %al,%al
f0101a5a:	74 0f                	je     f0101a6b <strtol+0x77>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0101a5c:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101a61:	80 3a 30             	cmpb   $0x30,(%edx)
f0101a64:	75 05                	jne    f0101a6b <strtol+0x77>
		s++, base = 8;
f0101a66:	83 c2 01             	add    $0x1,%edx
f0101a69:	b3 08                	mov    $0x8,%bl
	else if (base == 0)
		base = 10;
f0101a6b:	b8 00 00 00 00       	mov    $0x0,%eax
f0101a70:	89 de                	mov    %ebx,%esi

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0101a72:	0f b6 0a             	movzbl (%edx),%ecx
f0101a75:	8d 59 d0             	lea    -0x30(%ecx),%ebx
f0101a78:	80 fb 09             	cmp    $0x9,%bl
f0101a7b:	77 08                	ja     f0101a85 <strtol+0x91>
			dig = *s - '0';
f0101a7d:	0f be c9             	movsbl %cl,%ecx
f0101a80:	83 e9 30             	sub    $0x30,%ecx
f0101a83:	eb 1e                	jmp    f0101aa3 <strtol+0xaf>
		else if (*s >= 'a' && *s <= 'z')
f0101a85:	8d 59 9f             	lea    -0x61(%ecx),%ebx
f0101a88:	80 fb 19             	cmp    $0x19,%bl
f0101a8b:	77 08                	ja     f0101a95 <strtol+0xa1>
			dig = *s - 'a' + 10;
f0101a8d:	0f be c9             	movsbl %cl,%ecx
f0101a90:	83 e9 57             	sub    $0x57,%ecx
f0101a93:	eb 0e                	jmp    f0101aa3 <strtol+0xaf>
		else if (*s >= 'A' && *s <= 'Z')
f0101a95:	8d 59 bf             	lea    -0x41(%ecx),%ebx
f0101a98:	80 fb 19             	cmp    $0x19,%bl
f0101a9b:	77 14                	ja     f0101ab1 <strtol+0xbd>
			dig = *s - 'A' + 10;
f0101a9d:	0f be c9             	movsbl %cl,%ecx
f0101aa0:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0101aa3:	39 f1                	cmp    %esi,%ecx
f0101aa5:	7d 0e                	jge    f0101ab5 <strtol+0xc1>
			break;
		s++, val = (val * base) + dig;
f0101aa7:	83 c2 01             	add    $0x1,%edx
f0101aaa:	0f af c6             	imul   %esi,%eax
f0101aad:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
f0101aaf:	eb c1                	jmp    f0101a72 <strtol+0x7e>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
f0101ab1:	89 c1                	mov    %eax,%ecx
f0101ab3:	eb 02                	jmp    f0101ab7 <strtol+0xc3>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0101ab5:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
f0101ab7:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0101abb:	74 05                	je     f0101ac2 <strtol+0xce>
		*endptr = (char *) s;
f0101abd:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101ac0:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
f0101ac2:	89 ca                	mov    %ecx,%edx
f0101ac4:	f7 da                	neg    %edx
f0101ac6:	85 ff                	test   %edi,%edi
f0101ac8:	0f 45 c2             	cmovne %edx,%eax
}
f0101acb:	5b                   	pop    %ebx
f0101acc:	5e                   	pop    %esi
f0101acd:	5f                   	pop    %edi
f0101ace:	5d                   	pop    %ebp
f0101acf:	c3                   	ret    

f0101ad0 <__udivdi3>:
f0101ad0:	83 ec 1c             	sub    $0x1c,%esp
f0101ad3:	89 7c 24 14          	mov    %edi,0x14(%esp)
f0101ad7:	8b 7c 24 2c          	mov    0x2c(%esp),%edi
f0101adb:	8b 44 24 20          	mov    0x20(%esp),%eax
f0101adf:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0101ae3:	89 74 24 10          	mov    %esi,0x10(%esp)
f0101ae7:	8b 74 24 24          	mov    0x24(%esp),%esi
f0101aeb:	85 ff                	test   %edi,%edi
f0101aed:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f0101af1:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101af5:	89 cd                	mov    %ecx,%ebp
f0101af7:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101afb:	75 33                	jne    f0101b30 <__udivdi3+0x60>
f0101afd:	39 f1                	cmp    %esi,%ecx
f0101aff:	77 57                	ja     f0101b58 <__udivdi3+0x88>
f0101b01:	85 c9                	test   %ecx,%ecx
f0101b03:	75 0b                	jne    f0101b10 <__udivdi3+0x40>
f0101b05:	b8 01 00 00 00       	mov    $0x1,%eax
f0101b0a:	31 d2                	xor    %edx,%edx
f0101b0c:	f7 f1                	div    %ecx
f0101b0e:	89 c1                	mov    %eax,%ecx
f0101b10:	89 f0                	mov    %esi,%eax
f0101b12:	31 d2                	xor    %edx,%edx
f0101b14:	f7 f1                	div    %ecx
f0101b16:	89 c6                	mov    %eax,%esi
f0101b18:	8b 44 24 04          	mov    0x4(%esp),%eax
f0101b1c:	f7 f1                	div    %ecx
f0101b1e:	89 f2                	mov    %esi,%edx
f0101b20:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101b24:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101b28:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101b2c:	83 c4 1c             	add    $0x1c,%esp
f0101b2f:	c3                   	ret    
f0101b30:	31 d2                	xor    %edx,%edx
f0101b32:	31 c0                	xor    %eax,%eax
f0101b34:	39 f7                	cmp    %esi,%edi
f0101b36:	77 e8                	ja     f0101b20 <__udivdi3+0x50>
f0101b38:	0f bd cf             	bsr    %edi,%ecx
f0101b3b:	83 f1 1f             	xor    $0x1f,%ecx
f0101b3e:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0101b42:	75 2c                	jne    f0101b70 <__udivdi3+0xa0>
f0101b44:	3b 6c 24 08          	cmp    0x8(%esp),%ebp
f0101b48:	76 04                	jbe    f0101b4e <__udivdi3+0x7e>
f0101b4a:	39 f7                	cmp    %esi,%edi
f0101b4c:	73 d2                	jae    f0101b20 <__udivdi3+0x50>
f0101b4e:	31 d2                	xor    %edx,%edx
f0101b50:	b8 01 00 00 00       	mov    $0x1,%eax
f0101b55:	eb c9                	jmp    f0101b20 <__udivdi3+0x50>
f0101b57:	90                   	nop
f0101b58:	89 f2                	mov    %esi,%edx
f0101b5a:	f7 f1                	div    %ecx
f0101b5c:	31 d2                	xor    %edx,%edx
f0101b5e:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101b62:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101b66:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101b6a:	83 c4 1c             	add    $0x1c,%esp
f0101b6d:	c3                   	ret    
f0101b6e:	66 90                	xchg   %ax,%ax
f0101b70:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101b75:	b8 20 00 00 00       	mov    $0x20,%eax
f0101b7a:	89 ea                	mov    %ebp,%edx
f0101b7c:	2b 44 24 04          	sub    0x4(%esp),%eax
f0101b80:	d3 e7                	shl    %cl,%edi
f0101b82:	89 c1                	mov    %eax,%ecx
f0101b84:	d3 ea                	shr    %cl,%edx
f0101b86:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101b8b:	09 fa                	or     %edi,%edx
f0101b8d:	89 f7                	mov    %esi,%edi
f0101b8f:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101b93:	89 f2                	mov    %esi,%edx
f0101b95:	8b 74 24 08          	mov    0x8(%esp),%esi
f0101b99:	d3 e5                	shl    %cl,%ebp
f0101b9b:	89 c1                	mov    %eax,%ecx
f0101b9d:	d3 ef                	shr    %cl,%edi
f0101b9f:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101ba4:	d3 e2                	shl    %cl,%edx
f0101ba6:	89 c1                	mov    %eax,%ecx
f0101ba8:	d3 ee                	shr    %cl,%esi
f0101baa:	09 d6                	or     %edx,%esi
f0101bac:	89 fa                	mov    %edi,%edx
f0101bae:	89 f0                	mov    %esi,%eax
f0101bb0:	f7 74 24 0c          	divl   0xc(%esp)
f0101bb4:	89 d7                	mov    %edx,%edi
f0101bb6:	89 c6                	mov    %eax,%esi
f0101bb8:	f7 e5                	mul    %ebp
f0101bba:	39 d7                	cmp    %edx,%edi
f0101bbc:	72 22                	jb     f0101be0 <__udivdi3+0x110>
f0101bbe:	8b 6c 24 08          	mov    0x8(%esp),%ebp
f0101bc2:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101bc7:	d3 e5                	shl    %cl,%ebp
f0101bc9:	39 c5                	cmp    %eax,%ebp
f0101bcb:	73 04                	jae    f0101bd1 <__udivdi3+0x101>
f0101bcd:	39 d7                	cmp    %edx,%edi
f0101bcf:	74 0f                	je     f0101be0 <__udivdi3+0x110>
f0101bd1:	89 f0                	mov    %esi,%eax
f0101bd3:	31 d2                	xor    %edx,%edx
f0101bd5:	e9 46 ff ff ff       	jmp    f0101b20 <__udivdi3+0x50>
f0101bda:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101be0:	8d 46 ff             	lea    -0x1(%esi),%eax
f0101be3:	31 d2                	xor    %edx,%edx
f0101be5:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101be9:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101bed:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101bf1:	83 c4 1c             	add    $0x1c,%esp
f0101bf4:	c3                   	ret    
	...

f0101c00 <__umoddi3>:
f0101c00:	83 ec 1c             	sub    $0x1c,%esp
f0101c03:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f0101c07:	8b 6c 24 2c          	mov    0x2c(%esp),%ebp
f0101c0b:	8b 44 24 20          	mov    0x20(%esp),%eax
f0101c0f:	89 74 24 10          	mov    %esi,0x10(%esp)
f0101c13:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0101c17:	8b 74 24 24          	mov    0x24(%esp),%esi
f0101c1b:	85 ed                	test   %ebp,%ebp
f0101c1d:	89 7c 24 14          	mov    %edi,0x14(%esp)
f0101c21:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101c25:	89 cf                	mov    %ecx,%edi
f0101c27:	89 04 24             	mov    %eax,(%esp)
f0101c2a:	89 f2                	mov    %esi,%edx
f0101c2c:	75 1a                	jne    f0101c48 <__umoddi3+0x48>
f0101c2e:	39 f1                	cmp    %esi,%ecx
f0101c30:	76 4e                	jbe    f0101c80 <__umoddi3+0x80>
f0101c32:	f7 f1                	div    %ecx
f0101c34:	89 d0                	mov    %edx,%eax
f0101c36:	31 d2                	xor    %edx,%edx
f0101c38:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101c3c:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101c40:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101c44:	83 c4 1c             	add    $0x1c,%esp
f0101c47:	c3                   	ret    
f0101c48:	39 f5                	cmp    %esi,%ebp
f0101c4a:	77 54                	ja     f0101ca0 <__umoddi3+0xa0>
f0101c4c:	0f bd c5             	bsr    %ebp,%eax
f0101c4f:	83 f0 1f             	xor    $0x1f,%eax
f0101c52:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101c56:	75 60                	jne    f0101cb8 <__umoddi3+0xb8>
f0101c58:	3b 0c 24             	cmp    (%esp),%ecx
f0101c5b:	0f 87 07 01 00 00    	ja     f0101d68 <__umoddi3+0x168>
f0101c61:	89 f2                	mov    %esi,%edx
f0101c63:	8b 34 24             	mov    (%esp),%esi
f0101c66:	29 ce                	sub    %ecx,%esi
f0101c68:	19 ea                	sbb    %ebp,%edx
f0101c6a:	89 34 24             	mov    %esi,(%esp)
f0101c6d:	8b 04 24             	mov    (%esp),%eax
f0101c70:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101c74:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101c78:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101c7c:	83 c4 1c             	add    $0x1c,%esp
f0101c7f:	c3                   	ret    
f0101c80:	85 c9                	test   %ecx,%ecx
f0101c82:	75 0b                	jne    f0101c8f <__umoddi3+0x8f>
f0101c84:	b8 01 00 00 00       	mov    $0x1,%eax
f0101c89:	31 d2                	xor    %edx,%edx
f0101c8b:	f7 f1                	div    %ecx
f0101c8d:	89 c1                	mov    %eax,%ecx
f0101c8f:	89 f0                	mov    %esi,%eax
f0101c91:	31 d2                	xor    %edx,%edx
f0101c93:	f7 f1                	div    %ecx
f0101c95:	8b 04 24             	mov    (%esp),%eax
f0101c98:	f7 f1                	div    %ecx
f0101c9a:	eb 98                	jmp    f0101c34 <__umoddi3+0x34>
f0101c9c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101ca0:	89 f2                	mov    %esi,%edx
f0101ca2:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101ca6:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101caa:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101cae:	83 c4 1c             	add    $0x1c,%esp
f0101cb1:	c3                   	ret    
f0101cb2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101cb8:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101cbd:	89 e8                	mov    %ebp,%eax
f0101cbf:	bd 20 00 00 00       	mov    $0x20,%ebp
f0101cc4:	2b 6c 24 04          	sub    0x4(%esp),%ebp
f0101cc8:	89 fa                	mov    %edi,%edx
f0101cca:	d3 e0                	shl    %cl,%eax
f0101ccc:	89 e9                	mov    %ebp,%ecx
f0101cce:	d3 ea                	shr    %cl,%edx
f0101cd0:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101cd5:	09 c2                	or     %eax,%edx
f0101cd7:	8b 44 24 08          	mov    0x8(%esp),%eax
f0101cdb:	89 14 24             	mov    %edx,(%esp)
f0101cde:	89 f2                	mov    %esi,%edx
f0101ce0:	d3 e7                	shl    %cl,%edi
f0101ce2:	89 e9                	mov    %ebp,%ecx
f0101ce4:	d3 ea                	shr    %cl,%edx
f0101ce6:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101ceb:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101cef:	d3 e6                	shl    %cl,%esi
f0101cf1:	89 e9                	mov    %ebp,%ecx
f0101cf3:	d3 e8                	shr    %cl,%eax
f0101cf5:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101cfa:	09 f0                	or     %esi,%eax
f0101cfc:	8b 74 24 08          	mov    0x8(%esp),%esi
f0101d00:	f7 34 24             	divl   (%esp)
f0101d03:	d3 e6                	shl    %cl,%esi
f0101d05:	89 74 24 08          	mov    %esi,0x8(%esp)
f0101d09:	89 d6                	mov    %edx,%esi
f0101d0b:	f7 e7                	mul    %edi
f0101d0d:	39 d6                	cmp    %edx,%esi
f0101d0f:	89 c1                	mov    %eax,%ecx
f0101d11:	89 d7                	mov    %edx,%edi
f0101d13:	72 3f                	jb     f0101d54 <__umoddi3+0x154>
f0101d15:	39 44 24 08          	cmp    %eax,0x8(%esp)
f0101d19:	72 35                	jb     f0101d50 <__umoddi3+0x150>
f0101d1b:	8b 44 24 08          	mov    0x8(%esp),%eax
f0101d1f:	29 c8                	sub    %ecx,%eax
f0101d21:	19 fe                	sbb    %edi,%esi
f0101d23:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101d28:	89 f2                	mov    %esi,%edx
f0101d2a:	d3 e8                	shr    %cl,%eax
f0101d2c:	89 e9                	mov    %ebp,%ecx
f0101d2e:	d3 e2                	shl    %cl,%edx
f0101d30:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101d35:	09 d0                	or     %edx,%eax
f0101d37:	89 f2                	mov    %esi,%edx
f0101d39:	d3 ea                	shr    %cl,%edx
f0101d3b:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101d3f:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101d43:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101d47:	83 c4 1c             	add    $0x1c,%esp
f0101d4a:	c3                   	ret    
f0101d4b:	90                   	nop
f0101d4c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101d50:	39 d6                	cmp    %edx,%esi
f0101d52:	75 c7                	jne    f0101d1b <__umoddi3+0x11b>
f0101d54:	89 d7                	mov    %edx,%edi
f0101d56:	89 c1                	mov    %eax,%ecx
f0101d58:	2b 4c 24 0c          	sub    0xc(%esp),%ecx
f0101d5c:	1b 3c 24             	sbb    (%esp),%edi
f0101d5f:	eb ba                	jmp    f0101d1b <__umoddi3+0x11b>
f0101d61:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101d68:	39 f5                	cmp    %esi,%ebp
f0101d6a:	0f 82 f1 fe ff ff    	jb     f0101c61 <__umoddi3+0x61>
f0101d70:	e9 f8 fe ff ff       	jmp    f0101c6d <__umoddi3+0x6d>
