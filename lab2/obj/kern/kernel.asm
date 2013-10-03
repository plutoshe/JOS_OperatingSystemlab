
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
f0100015:	b8 00 40 11 00       	mov    $0x114000,%eax
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
f0100034:	bc 00 40 11 f0       	mov    $0xf0114000,%esp

	# now to C code
	call	i386_init
f0100039:	e8 02 00 00 00       	call   f0100040 <i386_init>

f010003e <spin>:

	# Should never get here, but in case we do, just spin.
spin:	jmp	spin
f010003e:	eb fe                	jmp    f010003e <spin>

f0100040 <i386_init>:
#include <kern/kclock.h>


void
i386_init(void)
{
f0100040:	55                   	push   %ebp
f0100041:	89 e5                	mov    %esp,%ebp
f0100043:	83 ec 18             	sub    $0x18,%esp
	extern char edata[], end[];

	// Before doing anything else, complete the ELF loading process.
	// Clear the uninitialized global data (BSS) section of our program.
	// This ensures that all static/global variables start out zero.
	memset(edata, 0, end - edata);
f0100046:	b8 90 69 11 f0       	mov    $0xf0116990,%eax
f010004b:	2d 20 63 11 f0       	sub    $0xf0116320,%eax
f0100050:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100054:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010005b:	00 
f010005c:	c7 04 24 20 63 11 f0 	movl   $0xf0116320,(%esp)
f0100063:	e8 a9 2a 00 00       	call   f0102b11 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100068:	e8 97 04 00 00       	call   f0100504 <cons_init>
	cprintf("6828 decimal is %o octal!\n", 6828);
f010006d:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f0100074:	00 
f0100075:	c7 04 24 20 30 10 f0 	movl   $0xf0103020,(%esp)
f010007c:	e8 d1 1e 00 00       	call   f0101f52 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100081:	e8 24 11 00 00       	call   f01011aa <mem_init>
	// Test the stack backtrace function (lab 1 only)
//>>>>>>> lab1

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f0100086:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010008d:	e8 10 0a 00 00       	call   f0100aa2 <monitor>
f0100092:	eb f2                	jmp    f0100086 <i386_init+0x46>

f0100094 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f0100094:	55                   	push   %ebp
f0100095:	89 e5                	mov    %esp,%ebp
f0100097:	56                   	push   %esi
f0100098:	53                   	push   %ebx
f0100099:	83 ec 10             	sub    $0x10,%esp
f010009c:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f010009f:	83 3d 80 69 11 f0 00 	cmpl   $0x0,0xf0116980
f01000a6:	75 3d                	jne    f01000e5 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f01000a8:	89 35 80 69 11 f0    	mov    %esi,0xf0116980

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f01000ae:	fa                   	cli    
f01000af:	fc                   	cld    

	va_start(ap, fmt);
f01000b0:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f01000b3:	8b 45 0c             	mov    0xc(%ebp),%eax
f01000b6:	89 44 24 08          	mov    %eax,0x8(%esp)
f01000ba:	8b 45 08             	mov    0x8(%ebp),%eax
f01000bd:	89 44 24 04          	mov    %eax,0x4(%esp)
f01000c1:	c7 04 24 3b 30 10 f0 	movl   $0xf010303b,(%esp)
f01000c8:	e8 85 1e 00 00       	call   f0101f52 <cprintf>
	vcprintf(fmt, ap);
f01000cd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01000d1:	89 34 24             	mov    %esi,(%esp)
f01000d4:	e8 46 1e 00 00       	call   f0101f1f <vcprintf>
	cprintf("\n");
f01000d9:	c7 04 24 77 30 10 f0 	movl   $0xf0103077,(%esp)
f01000e0:	e8 6d 1e 00 00       	call   f0101f52 <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000e5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000ec:	e8 b1 09 00 00       	call   f0100aa2 <monitor>
f01000f1:	eb f2                	jmp    f01000e5 <_panic+0x51>

f01000f3 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f01000f3:	55                   	push   %ebp
f01000f4:	89 e5                	mov    %esp,%ebp
f01000f6:	53                   	push   %ebx
f01000f7:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f01000fa:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f01000fd:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100100:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100104:	8b 45 08             	mov    0x8(%ebp),%eax
f0100107:	89 44 24 04          	mov    %eax,0x4(%esp)
f010010b:	c7 04 24 53 30 10 f0 	movl   $0xf0103053,(%esp)
f0100112:	e8 3b 1e 00 00       	call   f0101f52 <cprintf>
	vcprintf(fmt, ap);
f0100117:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010011b:	8b 45 10             	mov    0x10(%ebp),%eax
f010011e:	89 04 24             	mov    %eax,(%esp)
f0100121:	e8 f9 1d 00 00       	call   f0101f1f <vcprintf>
	cprintf("\n");
f0100126:	c7 04 24 77 30 10 f0 	movl   $0xf0103077,(%esp)
f010012d:	e8 20 1e 00 00       	call   f0101f52 <cprintf>
	va_end(ap);
}
f0100132:	83 c4 14             	add    $0x14,%esp
f0100135:	5b                   	pop    %ebx
f0100136:	5d                   	pop    %ebp
f0100137:	c3                   	ret    
	...

f0100140 <delay>:
static void cons_putc(int c);

// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
f0100140:	55                   	push   %ebp
f0100141:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100143:	ba 84 00 00 00       	mov    $0x84,%edx
f0100148:	ec                   	in     (%dx),%al
f0100149:	ec                   	in     (%dx),%al
f010014a:	ec                   	in     (%dx),%al
f010014b:	ec                   	in     (%dx),%al
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
f010014c:	5d                   	pop    %ebp
f010014d:	c3                   	ret    

f010014e <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f010014e:	55                   	push   %ebp
f010014f:	89 e5                	mov    %esp,%ebp
f0100151:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100156:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f0100157:	b9 ff ff ff ff       	mov    $0xffffffff,%ecx
static bool serial_exists;

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f010015c:	a8 01                	test   $0x1,%al
f010015e:	74 06                	je     f0100166 <serial_proc_data+0x18>
f0100160:	b2 f8                	mov    $0xf8,%dl
f0100162:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f0100163:	0f b6 c8             	movzbl %al,%ecx
}
f0100166:	89 c8                	mov    %ecx,%eax
f0100168:	5d                   	pop    %ebp
f0100169:	c3                   	ret    

f010016a <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f010016a:	55                   	push   %ebp
f010016b:	89 e5                	mov    %esp,%ebp
f010016d:	53                   	push   %ebx
f010016e:	83 ec 04             	sub    $0x4,%esp
f0100171:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f0100173:	eb 25                	jmp    f010019a <cons_intr+0x30>
		if (c == 0)
f0100175:	85 c0                	test   %eax,%eax
f0100177:	74 21                	je     f010019a <cons_intr+0x30>
			continue;
		cons.buf[cons.wpos++] = c;
f0100179:	8b 15 44 65 11 f0    	mov    0xf0116544,%edx
f010017f:	88 82 40 63 11 f0    	mov    %al,-0xfee9cc0(%edx)
f0100185:	8d 42 01             	lea    0x1(%edx),%eax
		if (cons.wpos == CONSBUFSIZE)
f0100188:	3d 00 02 00 00       	cmp    $0x200,%eax
			cons.wpos = 0;
f010018d:	ba 00 00 00 00       	mov    $0x0,%edx
f0100192:	0f 44 c2             	cmove  %edx,%eax
f0100195:	a3 44 65 11 f0       	mov    %eax,0xf0116544
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f010019a:	ff d3                	call   *%ebx
f010019c:	83 f8 ff             	cmp    $0xffffffff,%eax
f010019f:	75 d4                	jne    f0100175 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01001a1:	83 c4 04             	add    $0x4,%esp
f01001a4:	5b                   	pop    %ebx
f01001a5:	5d                   	pop    %ebp
f01001a6:	c3                   	ret    

f01001a7 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01001a7:	55                   	push   %ebp
f01001a8:	89 e5                	mov    %esp,%ebp
f01001aa:	57                   	push   %edi
f01001ab:	56                   	push   %esi
f01001ac:	53                   	push   %ebx
f01001ad:	83 ec 2c             	sub    $0x2c,%esp
f01001b0:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01001b3:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01001b8:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01001b9:	a8 20                	test   $0x20,%al
f01001bb:	75 1b                	jne    f01001d8 <cons_putc+0x31>
f01001bd:	bb 00 32 00 00       	mov    $0x3200,%ebx
f01001c2:	be fd 03 00 00       	mov    $0x3fd,%esi
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
f01001c7:	e8 74 ff ff ff       	call   f0100140 <delay>
f01001cc:	89 f2                	mov    %esi,%edx
f01001ce:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f01001cf:	a8 20                	test   $0x20,%al
f01001d1:	75 05                	jne    f01001d8 <cons_putc+0x31>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f01001d3:	83 eb 01             	sub    $0x1,%ebx
f01001d6:	75 ef                	jne    f01001c7 <cons_putc+0x20>
	     i++)
		delay();

	outb(COM1 + COM_TX, c);
f01001d8:	0f b6 7d e4          	movzbl -0x1c(%ebp),%edi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01001dc:	ba f8 03 00 00       	mov    $0x3f8,%edx
f01001e1:	89 f8                	mov    %edi,%eax
f01001e3:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01001e4:	b2 79                	mov    $0x79,%dl
f01001e6:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01001e7:	84 c0                	test   %al,%al
f01001e9:	78 1b                	js     f0100206 <cons_putc+0x5f>
f01001eb:	bb 00 32 00 00       	mov    $0x3200,%ebx
f01001f0:	be 79 03 00 00       	mov    $0x379,%esi
		delay();
f01001f5:	e8 46 ff ff ff       	call   f0100140 <delay>
f01001fa:	89 f2                	mov    %esi,%edx
f01001fc:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f01001fd:	84 c0                	test   %al,%al
f01001ff:	78 05                	js     f0100206 <cons_putc+0x5f>
f0100201:	83 eb 01             	sub    $0x1,%ebx
f0100204:	75 ef                	jne    f01001f5 <cons_putc+0x4e>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100206:	ba 78 03 00 00       	mov    $0x378,%edx
f010020b:	89 f8                	mov    %edi,%eax
f010020d:	ee                   	out    %al,(%dx)
f010020e:	b2 7a                	mov    $0x7a,%dl
f0100210:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100215:	ee                   	out    %al,(%dx)
f0100216:	b8 08 00 00 00       	mov    $0x8,%eax
f010021b:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	c = c + attribute_color;
f010021c:	0f b7 15 00 60 11 f0 	movzwl 0xf0116000,%edx
f0100223:	03 55 e4             	add    -0x1c(%ebp),%edx
	//if (!(c & ~0xFF))
	//	c |= 0x0700;

	switch (c & 0xff) {
f0100226:	0f b6 c2             	movzbl %dl,%eax
f0100229:	83 f8 09             	cmp    $0x9,%eax
f010022c:	74 77                	je     f01002a5 <cons_putc+0xfe>
f010022e:	83 f8 09             	cmp    $0x9,%eax
f0100231:	7f 0f                	jg     f0100242 <cons_putc+0x9b>
f0100233:	83 f8 08             	cmp    $0x8,%eax
f0100236:	0f 85 9d 00 00 00    	jne    f01002d9 <cons_putc+0x132>
f010023c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0100240:	eb 10                	jmp    f0100252 <cons_putc+0xab>
f0100242:	83 f8 0a             	cmp    $0xa,%eax
f0100245:	74 38                	je     f010027f <cons_putc+0xd8>
f0100247:	83 f8 0d             	cmp    $0xd,%eax
f010024a:	0f 85 89 00 00 00    	jne    f01002d9 <cons_putc+0x132>
f0100250:	eb 35                	jmp    f0100287 <cons_putc+0xe0>
	case '\b':
		if (crt_pos > 0) {
f0100252:	0f b7 05 54 65 11 f0 	movzwl 0xf0116554,%eax
f0100259:	66 85 c0             	test   %ax,%ax
f010025c:	0f 84 e1 00 00 00    	je     f0100343 <cons_putc+0x19c>
			crt_pos--;
f0100262:	83 e8 01             	sub    $0x1,%eax
f0100265:	66 a3 54 65 11 f0    	mov    %ax,0xf0116554
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f010026b:	0f b7 c0             	movzwl %ax,%eax
f010026e:	b2 00                	mov    $0x0,%dl
f0100270:	83 ca 20             	or     $0x20,%edx
f0100273:	8b 0d 50 65 11 f0    	mov    0xf0116550,%ecx
f0100279:	66 89 14 41          	mov    %dx,(%ecx,%eax,2)
f010027d:	eb 77                	jmp    f01002f6 <cons_putc+0x14f>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f010027f:	66 83 05 54 65 11 f0 	addw   $0x50,0xf0116554
f0100286:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f0100287:	0f b7 05 54 65 11 f0 	movzwl 0xf0116554,%eax
f010028e:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100294:	c1 e8 16             	shr    $0x16,%eax
f0100297:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010029a:	c1 e0 04             	shl    $0x4,%eax
f010029d:	66 a3 54 65 11 f0    	mov    %ax,0xf0116554
f01002a3:	eb 51                	jmp    f01002f6 <cons_putc+0x14f>
		break;
	case '\t':
		cons_putc(' ');
f01002a5:	b8 20 00 00 00       	mov    $0x20,%eax
f01002aa:	e8 f8 fe ff ff       	call   f01001a7 <cons_putc>
		cons_putc(' ');
f01002af:	b8 20 00 00 00       	mov    $0x20,%eax
f01002b4:	e8 ee fe ff ff       	call   f01001a7 <cons_putc>
		cons_putc(' ');
f01002b9:	b8 20 00 00 00       	mov    $0x20,%eax
f01002be:	e8 e4 fe ff ff       	call   f01001a7 <cons_putc>
		cons_putc(' ');
f01002c3:	b8 20 00 00 00       	mov    $0x20,%eax
f01002c8:	e8 da fe ff ff       	call   f01001a7 <cons_putc>
		cons_putc(' ');
f01002cd:	b8 20 00 00 00       	mov    $0x20,%eax
f01002d2:	e8 d0 fe ff ff       	call   f01001a7 <cons_putc>
f01002d7:	eb 1d                	jmp    f01002f6 <cons_putc+0x14f>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f01002d9:	0f b7 05 54 65 11 f0 	movzwl 0xf0116554,%eax
f01002e0:	0f b7 d8             	movzwl %ax,%ebx
f01002e3:	8b 0d 50 65 11 f0    	mov    0xf0116550,%ecx
f01002e9:	66 89 14 59          	mov    %dx,(%ecx,%ebx,2)
f01002ed:	83 c0 01             	add    $0x1,%eax
f01002f0:	66 a3 54 65 11 f0    	mov    %ax,0xf0116554
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f01002f6:	66 81 3d 54 65 11 f0 	cmpw   $0x7cf,0xf0116554
f01002fd:	cf 07 
f01002ff:	76 42                	jbe    f0100343 <cons_putc+0x19c>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100301:	a1 50 65 11 f0       	mov    0xf0116550,%eax
f0100306:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f010030d:	00 
f010030e:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100314:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100318:	89 04 24             	mov    %eax,(%esp)
f010031b:	e8 4c 28 00 00       	call   f0102b6c <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100320:	8b 15 50 65 11 f0    	mov    0xf0116550,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100326:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f010032b:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100331:	83 c0 01             	add    $0x1,%eax
f0100334:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f0100339:	75 f0                	jne    f010032b <cons_putc+0x184>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f010033b:	66 83 2d 54 65 11 f0 	subw   $0x50,0xf0116554
f0100342:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100343:	8b 0d 4c 65 11 f0    	mov    0xf011654c,%ecx
f0100349:	b8 0e 00 00 00       	mov    $0xe,%eax
f010034e:	89 ca                	mov    %ecx,%edx
f0100350:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100351:	0f b7 35 54 65 11 f0 	movzwl 0xf0116554,%esi
f0100358:	8d 59 01             	lea    0x1(%ecx),%ebx
f010035b:	89 f0                	mov    %esi,%eax
f010035d:	66 c1 e8 08          	shr    $0x8,%ax
f0100361:	89 da                	mov    %ebx,%edx
f0100363:	ee                   	out    %al,(%dx)
f0100364:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100369:	89 ca                	mov    %ecx,%edx
f010036b:	ee                   	out    %al,(%dx)
f010036c:	89 f0                	mov    %esi,%eax
f010036e:	89 da                	mov    %ebx,%edx
f0100370:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f0100371:	83 c4 2c             	add    $0x2c,%esp
f0100374:	5b                   	pop    %ebx
f0100375:	5e                   	pop    %esi
f0100376:	5f                   	pop    %edi
f0100377:	5d                   	pop    %ebp
f0100378:	c3                   	ret    

f0100379 <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f0100379:	55                   	push   %ebp
f010037a:	89 e5                	mov    %esp,%ebp
f010037c:	53                   	push   %ebx
f010037d:	83 ec 14             	sub    $0x14,%esp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100380:	ba 64 00 00 00       	mov    $0x64,%edx
f0100385:	ec                   	in     (%dx),%al
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f0100386:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f010038b:	a8 01                	test   $0x1,%al
f010038d:	0f 84 de 00 00 00    	je     f0100471 <kbd_proc_data+0xf8>
f0100393:	b2 60                	mov    $0x60,%dl
f0100395:	ec                   	in     (%dx),%al
f0100396:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f0100398:	3c e0                	cmp    $0xe0,%al
f010039a:	75 11                	jne    f01003ad <kbd_proc_data+0x34>
		// E0 escape character
		shift |= E0ESC;
f010039c:	83 0d 48 65 11 f0 40 	orl    $0x40,0xf0116548
		return 0;
f01003a3:	bb 00 00 00 00       	mov    $0x0,%ebx
f01003a8:	e9 c4 00 00 00       	jmp    f0100471 <kbd_proc_data+0xf8>
	} else if (data & 0x80) {
f01003ad:	84 c0                	test   %al,%al
f01003af:	79 37                	jns    f01003e8 <kbd_proc_data+0x6f>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01003b1:	8b 0d 48 65 11 f0    	mov    0xf0116548,%ecx
f01003b7:	89 cb                	mov    %ecx,%ebx
f01003b9:	83 e3 40             	and    $0x40,%ebx
f01003bc:	83 e0 7f             	and    $0x7f,%eax
f01003bf:	85 db                	test   %ebx,%ebx
f01003c1:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01003c4:	0f b6 d2             	movzbl %dl,%edx
f01003c7:	0f b6 82 a0 30 10 f0 	movzbl -0xfefcf60(%edx),%eax
f01003ce:	83 c8 40             	or     $0x40,%eax
f01003d1:	0f b6 c0             	movzbl %al,%eax
f01003d4:	f7 d0                	not    %eax
f01003d6:	21 c1                	and    %eax,%ecx
f01003d8:	89 0d 48 65 11 f0    	mov    %ecx,0xf0116548
		return 0;
f01003de:	bb 00 00 00 00       	mov    $0x0,%ebx
f01003e3:	e9 89 00 00 00       	jmp    f0100471 <kbd_proc_data+0xf8>
	} else if (shift & E0ESC) {
f01003e8:	8b 0d 48 65 11 f0    	mov    0xf0116548,%ecx
f01003ee:	f6 c1 40             	test   $0x40,%cl
f01003f1:	74 0e                	je     f0100401 <kbd_proc_data+0x88>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f01003f3:	89 c2                	mov    %eax,%edx
f01003f5:	83 ca 80             	or     $0xffffff80,%edx
		shift &= ~E0ESC;
f01003f8:	83 e1 bf             	and    $0xffffffbf,%ecx
f01003fb:	89 0d 48 65 11 f0    	mov    %ecx,0xf0116548
	}

	shift |= shiftcode[data];
f0100401:	0f b6 d2             	movzbl %dl,%edx
f0100404:	0f b6 82 a0 30 10 f0 	movzbl -0xfefcf60(%edx),%eax
f010040b:	0b 05 48 65 11 f0    	or     0xf0116548,%eax
	shift ^= togglecode[data];
f0100411:	0f b6 8a a0 31 10 f0 	movzbl -0xfefce60(%edx),%ecx
f0100418:	31 c8                	xor    %ecx,%eax
f010041a:	a3 48 65 11 f0       	mov    %eax,0xf0116548

	c = charcode[shift & (CTL | SHIFT)][data];
f010041f:	89 c1                	mov    %eax,%ecx
f0100421:	83 e1 03             	and    $0x3,%ecx
f0100424:	8b 0c 8d a0 32 10 f0 	mov    -0xfefcd60(,%ecx,4),%ecx
f010042b:	0f b6 1c 11          	movzbl (%ecx,%edx,1),%ebx
	if (shift & CAPSLOCK) {
f010042f:	a8 08                	test   $0x8,%al
f0100431:	74 19                	je     f010044c <kbd_proc_data+0xd3>
		if ('a' <= c && c <= 'z')
f0100433:	8d 53 9f             	lea    -0x61(%ebx),%edx
f0100436:	83 fa 19             	cmp    $0x19,%edx
f0100439:	77 05                	ja     f0100440 <kbd_proc_data+0xc7>
			c += 'A' - 'a';
f010043b:	83 eb 20             	sub    $0x20,%ebx
f010043e:	eb 0c                	jmp    f010044c <kbd_proc_data+0xd3>
		else if ('A' <= c && c <= 'Z')
f0100440:	8d 4b bf             	lea    -0x41(%ebx),%ecx
			c += 'a' - 'A';
f0100443:	8d 53 20             	lea    0x20(%ebx),%edx
f0100446:	83 f9 19             	cmp    $0x19,%ecx
f0100449:	0f 46 da             	cmovbe %edx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f010044c:	f7 d0                	not    %eax
f010044e:	a8 06                	test   $0x6,%al
f0100450:	75 1f                	jne    f0100471 <kbd_proc_data+0xf8>
f0100452:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f0100458:	75 17                	jne    f0100471 <kbd_proc_data+0xf8>
		cprintf("Rebooting!\n");
f010045a:	c7 04 24 6d 30 10 f0 	movl   $0xf010306d,(%esp)
f0100461:	e8 ec 1a 00 00       	call   f0101f52 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100466:	ba 92 00 00 00       	mov    $0x92,%edx
f010046b:	b8 03 00 00 00       	mov    $0x3,%eax
f0100470:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f0100471:	89 d8                	mov    %ebx,%eax
f0100473:	83 c4 14             	add    $0x14,%esp
f0100476:	5b                   	pop    %ebx
f0100477:	5d                   	pop    %ebp
f0100478:	c3                   	ret    

f0100479 <set_attribute_color>:
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
	return inb(COM1+COM_RX);
}

void set_attribute_color(uint16_t back, uint16_t fore) {
f0100479:	55                   	push   %ebp
f010047a:	89 e5                	mov    %esp,%ebp
	attribute_color = (back << 12) | (fore << 8);
f010047c:	0f b7 55 0c          	movzwl 0xc(%ebp),%edx
f0100480:	c1 e2 08             	shl    $0x8,%edx
f0100483:	0f b7 45 08          	movzwl 0x8(%ebp),%eax
f0100487:	c1 e0 0c             	shl    $0xc,%eax
f010048a:	09 d0                	or     %edx,%eax
f010048c:	66 a3 00 60 11 f0    	mov    %ax,0xf0116000
}
f0100492:	5d                   	pop    %ebp
f0100493:	c3                   	ret    

f0100494 <serial_intr>:

void
serial_intr(void)
{
f0100494:	55                   	push   %ebp
f0100495:	89 e5                	mov    %esp,%ebp
f0100497:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
f010049a:	80 3d 20 63 11 f0 00 	cmpb   $0x0,0xf0116320
f01004a1:	74 0a                	je     f01004ad <serial_intr+0x19>
		cons_intr(serial_proc_data);
f01004a3:	b8 4e 01 10 f0       	mov    $0xf010014e,%eax
f01004a8:	e8 bd fc ff ff       	call   f010016a <cons_intr>
}
f01004ad:	c9                   	leave  
f01004ae:	c3                   	ret    

f01004af <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01004af:	55                   	push   %ebp
f01004b0:	89 e5                	mov    %esp,%ebp
f01004b2:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f01004b5:	b8 79 03 10 f0       	mov    $0xf0100379,%eax
f01004ba:	e8 ab fc ff ff       	call   f010016a <cons_intr>
}
f01004bf:	c9                   	leave  
f01004c0:	c3                   	ret    

f01004c1 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f01004c1:	55                   	push   %ebp
f01004c2:	89 e5                	mov    %esp,%ebp
f01004c4:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f01004c7:	e8 c8 ff ff ff       	call   f0100494 <serial_intr>
	kbd_intr();
f01004cc:	e8 de ff ff ff       	call   f01004af <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004d1:	8b 15 40 65 11 f0    	mov    0xf0116540,%edx
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
	}
	return 0;
f01004d7:	b8 00 00 00 00       	mov    $0x0,%eax
	// (e.g., when called from the kernel monitor).
	serial_intr();
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f01004dc:	3b 15 44 65 11 f0    	cmp    0xf0116544,%edx
f01004e2:	74 1e                	je     f0100502 <cons_getc+0x41>
		c = cons.buf[cons.rpos++];
f01004e4:	0f b6 82 40 63 11 f0 	movzbl -0xfee9cc0(%edx),%eax
f01004eb:	83 c2 01             	add    $0x1,%edx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
f01004ee:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01004f4:	b9 00 00 00 00       	mov    $0x0,%ecx
f01004f9:	0f 44 d1             	cmove  %ecx,%edx
f01004fc:	89 15 40 65 11 f0    	mov    %edx,0xf0116540
		return c;
	}
	return 0;
}
f0100502:	c9                   	leave  
f0100503:	c3                   	ret    

f0100504 <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f0100504:	55                   	push   %ebp
f0100505:	89 e5                	mov    %esp,%ebp
f0100507:	57                   	push   %edi
f0100508:	56                   	push   %esi
f0100509:	53                   	push   %ebx
f010050a:	83 ec 1c             	sub    $0x1c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f010050d:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f0100514:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f010051b:	5a a5 
	if (*cp != 0xA55A) {
f010051d:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f0100524:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100528:	74 11                	je     f010053b <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f010052a:	c7 05 4c 65 11 f0 b4 	movl   $0x3b4,0xf011654c
f0100531:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100534:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f0100539:	eb 16                	jmp    f0100551 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f010053b:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100542:	c7 05 4c 65 11 f0 d4 	movl   $0x3d4,0xf011654c
f0100549:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f010054c:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f0100551:	8b 0d 4c 65 11 f0    	mov    0xf011654c,%ecx
f0100557:	b8 0e 00 00 00       	mov    $0xe,%eax
f010055c:	89 ca                	mov    %ecx,%edx
f010055e:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f010055f:	8d 59 01             	lea    0x1(%ecx),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100562:	89 da                	mov    %ebx,%edx
f0100564:	ec                   	in     (%dx),%al
f0100565:	0f b6 f8             	movzbl %al,%edi
f0100568:	c1 e7 08             	shl    $0x8,%edi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010056b:	b8 0f 00 00 00       	mov    $0xf,%eax
f0100570:	89 ca                	mov    %ecx,%edx
f0100572:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100573:	89 da                	mov    %ebx,%edx
f0100575:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f0100576:	89 35 50 65 11 f0    	mov    %esi,0xf0116550

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f010057c:	0f b6 d8             	movzbl %al,%ebx
f010057f:	09 df                	or     %ebx,%edi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f0100581:	66 89 3d 54 65 11 f0 	mov    %di,0xf0116554
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100588:	bb fa 03 00 00       	mov    $0x3fa,%ebx
f010058d:	b8 00 00 00 00       	mov    $0x0,%eax
f0100592:	89 da                	mov    %ebx,%edx
f0100594:	ee                   	out    %al,(%dx)
f0100595:	b2 fb                	mov    $0xfb,%dl
f0100597:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f010059c:	ee                   	out    %al,(%dx)
f010059d:	b9 f8 03 00 00       	mov    $0x3f8,%ecx
f01005a2:	b8 0c 00 00 00       	mov    $0xc,%eax
f01005a7:	89 ca                	mov    %ecx,%edx
f01005a9:	ee                   	out    %al,(%dx)
f01005aa:	b2 f9                	mov    $0xf9,%dl
f01005ac:	b8 00 00 00 00       	mov    $0x0,%eax
f01005b1:	ee                   	out    %al,(%dx)
f01005b2:	b2 fb                	mov    $0xfb,%dl
f01005b4:	b8 03 00 00 00       	mov    $0x3,%eax
f01005b9:	ee                   	out    %al,(%dx)
f01005ba:	b2 fc                	mov    $0xfc,%dl
f01005bc:	b8 00 00 00 00       	mov    $0x0,%eax
f01005c1:	ee                   	out    %al,(%dx)
f01005c2:	b2 f9                	mov    $0xf9,%dl
f01005c4:	b8 01 00 00 00       	mov    $0x1,%eax
f01005c9:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005ca:	b2 fd                	mov    $0xfd,%dl
f01005cc:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f01005cd:	3c ff                	cmp    $0xff,%al
f01005cf:	0f 95 c0             	setne  %al
f01005d2:	89 c6                	mov    %eax,%esi
f01005d4:	a2 20 63 11 f0       	mov    %al,0xf0116320
f01005d9:	89 da                	mov    %ebx,%edx
f01005db:	ec                   	in     (%dx),%al
f01005dc:	89 ca                	mov    %ecx,%edx
f01005de:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f01005df:	89 f0                	mov    %esi,%eax
f01005e1:	84 c0                	test   %al,%al
f01005e3:	75 0c                	jne    f01005f1 <cons_init+0xed>
		cprintf("Serial port does not exist!\n");
f01005e5:	c7 04 24 79 30 10 f0 	movl   $0xf0103079,(%esp)
f01005ec:	e8 61 19 00 00       	call   f0101f52 <cprintf>
}
f01005f1:	83 c4 1c             	add    $0x1c,%esp
f01005f4:	5b                   	pop    %ebx
f01005f5:	5e                   	pop    %esi
f01005f6:	5f                   	pop    %edi
f01005f7:	5d                   	pop    %ebp
f01005f8:	c3                   	ret    

f01005f9 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f01005f9:	55                   	push   %ebp
f01005fa:	89 e5                	mov    %esp,%ebp
f01005fc:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f01005ff:	8b 45 08             	mov    0x8(%ebp),%eax
f0100602:	e8 a0 fb ff ff       	call   f01001a7 <cons_putc>
}
f0100607:	c9                   	leave  
f0100608:	c3                   	ret    

f0100609 <getchar>:

int
getchar(void)
{
f0100609:	55                   	push   %ebp
f010060a:	89 e5                	mov    %esp,%ebp
f010060c:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f010060f:	e8 ad fe ff ff       	call   f01004c1 <cons_getc>
f0100614:	85 c0                	test   %eax,%eax
f0100616:	74 f7                	je     f010060f <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100618:	c9                   	leave  
f0100619:	c3                   	ret    

f010061a <iscons>:

int
iscons(int fdnum)
{
f010061a:	55                   	push   %ebp
f010061b:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f010061d:	b8 01 00 00 00       	mov    $0x1,%eax
f0100622:	5d                   	pop    %ebp
f0100623:	c3                   	ret    
	...

f0100630 <mon_kerninfo>:
	return 0;
}

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100630:	55                   	push   %ebp
f0100631:	89 e5                	mov    %esp,%ebp
f0100633:	83 ec 18             	sub    $0x18,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100636:	c7 04 24 b0 32 10 f0 	movl   $0xf01032b0,(%esp)
f010063d:	e8 10 19 00 00       	call   f0101f52 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100642:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f0100649:	00 
f010064a:	c7 04 24 b4 33 10 f0 	movl   $0xf01033b4,(%esp)
f0100651:	e8 fc 18 00 00       	call   f0101f52 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100656:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f010065d:	00 
f010065e:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f0100665:	f0 
f0100666:	c7 04 24 dc 33 10 f0 	movl   $0xf01033dc,(%esp)
f010066d:	e8 e0 18 00 00       	call   f0101f52 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100672:	c7 44 24 08 05 30 10 	movl   $0x103005,0x8(%esp)
f0100679:	00 
f010067a:	c7 44 24 04 05 30 10 	movl   $0xf0103005,0x4(%esp)
f0100681:	f0 
f0100682:	c7 04 24 00 34 10 f0 	movl   $0xf0103400,(%esp)
f0100689:	e8 c4 18 00 00       	call   f0101f52 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010068e:	c7 44 24 08 20 63 11 	movl   $0x116320,0x8(%esp)
f0100695:	00 
f0100696:	c7 44 24 04 20 63 11 	movl   $0xf0116320,0x4(%esp)
f010069d:	f0 
f010069e:	c7 04 24 24 34 10 f0 	movl   $0xf0103424,(%esp)
f01006a5:	e8 a8 18 00 00       	call   f0101f52 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006aa:	c7 44 24 08 90 69 11 	movl   $0x116990,0x8(%esp)
f01006b1:	00 
f01006b2:	c7 44 24 04 90 69 11 	movl   $0xf0116990,0x4(%esp)
f01006b9:	f0 
f01006ba:	c7 04 24 48 34 10 f0 	movl   $0xf0103448,(%esp)
f01006c1:	e8 8c 18 00 00       	call   f0101f52 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f01006c6:	b8 8f 6d 11 f0       	mov    $0xf0116d8f,%eax
f01006cb:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
f01006d0:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f01006d5:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f01006db:	85 c0                	test   %eax,%eax
f01006dd:	0f 48 c2             	cmovs  %edx,%eax
f01006e0:	c1 f8 0a             	sar    $0xa,%eax
f01006e3:	89 44 24 04          	mov    %eax,0x4(%esp)
f01006e7:	c7 04 24 6c 34 10 f0 	movl   $0xf010346c,(%esp)
f01006ee:	e8 5f 18 00 00       	call   f0101f52 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f01006f3:	b8 00 00 00 00       	mov    $0x0,%eax
f01006f8:	c9                   	leave  
f01006f9:	c3                   	ret    

f01006fa <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f01006fa:	55                   	push   %ebp
f01006fb:	89 e5                	mov    %esp,%ebp
f01006fd:	53                   	push   %ebx
f01006fe:	83 ec 14             	sub    $0x14,%esp
f0100701:	bb 00 00 00 00       	mov    $0x0,%ebx
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100706:	8b 83 a4 35 10 f0    	mov    -0xfefca5c(%ebx),%eax
f010070c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100710:	8b 83 a0 35 10 f0    	mov    -0xfefca60(%ebx),%eax
f0100716:	89 44 24 04          	mov    %eax,0x4(%esp)
f010071a:	c7 04 24 c9 32 10 f0 	movl   $0xf01032c9,(%esp)
f0100721:	e8 2c 18 00 00       	call   f0101f52 <cprintf>
f0100726:	83 c3 0c             	add    $0xc,%ebx
int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
	int i;

	for (i = 0; i < NCOMMANDS; i++)
f0100729:	83 fb 30             	cmp    $0x30,%ebx
f010072c:	75 d8                	jne    f0100706 <mon_help+0xc>
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
	return 0;
}
f010072e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100733:	83 c4 14             	add    $0x14,%esp
f0100736:	5b                   	pop    %ebx
f0100737:	5d                   	pop    %ebp
f0100738:	c3                   	ret    

f0100739 <mon_backtrace>:
	return 0;
}

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100739:	55                   	push   %ebp
f010073a:	89 e5                	mov    %esp,%ebp
f010073c:	57                   	push   %edi
f010073d:	56                   	push   %esi
f010073e:	53                   	push   %ebx
f010073f:	83 ec 4c             	sub    $0x4c,%esp

static __inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f0100742:	89 eb                	mov    %ebp,%ebx
// Your code here.
//	cprintf("%08x", read_ebp());
	uint32_t *eip, *ebp;
	ebp = (uint32_t*) read_ebp();
f0100744:	89 de                	mov    %ebx,%esi
	eip = (uint32_t*) ebp[1];
f0100746:	8b 7b 04             	mov    0x4(%ebx),%edi
	cprintf("Stackbacktrace:\n");
f0100749:	c7 04 24 d2 32 10 f0 	movl   $0xf01032d2,(%esp)
f0100750:	e8 fd 17 00 00       	call   f0101f52 <cprintf>
	while (ebp!=0) {
f0100755:	85 db                	test   %ebx,%ebx
f0100757:	0f 84 aa 00 00 00    	je     f0100807 <mon_backtrace+0xce>
		cprintf("ebp %08x eip %08x args %08x %08x %08x %08x %08x\n",ebp, eip, ebp[2] ,ebp[3], ebp[4], ebp[5] ,ebp[6]);
f010075d:	8b 46 18             	mov    0x18(%esi),%eax
f0100760:	89 44 24 1c          	mov    %eax,0x1c(%esp)
f0100764:	8b 46 14             	mov    0x14(%esi),%eax
f0100767:	89 44 24 18          	mov    %eax,0x18(%esp)
f010076b:	8b 46 10             	mov    0x10(%esi),%eax
f010076e:	89 44 24 14          	mov    %eax,0x14(%esp)
f0100772:	8b 46 0c             	mov    0xc(%esi),%eax
f0100775:	89 44 24 10          	mov    %eax,0x10(%esp)
f0100779:	8b 46 08             	mov    0x8(%esi),%eax
f010077c:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100780:	89 7c 24 08          	mov    %edi,0x8(%esp)
f0100784:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100788:	c7 04 24 98 34 10 f0 	movl   $0xf0103498,(%esp)
f010078f:	e8 be 17 00 00       	call   f0101f52 <cprintf>
		struct Eipdebuginfo temp_debuginfo;
		debuginfo_eip((uintptr_t) eip, &temp_debuginfo);		
f0100794:	8d 45 d0             	lea    -0x30(%ebp),%eax
f0100797:	89 44 24 04          	mov    %eax,0x4(%esp)
f010079b:	89 3c 24             	mov    %edi,(%esp)
f010079e:	e8 a9 18 00 00       	call   f010204c <debuginfo_eip>
		cprintf("       %s:%d: ", temp_debuginfo.eip_file, temp_debuginfo.eip_line);
f01007a3:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01007a6:	89 44 24 08          	mov    %eax,0x8(%esp)
f01007aa:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01007ad:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007b1:	c7 04 24 e3 32 10 f0 	movl   $0xf01032e3,(%esp)
f01007b8:	e8 95 17 00 00       	call   f0101f52 <cprintf>
		uint32_t i = 0;// = temp_debuginfo.eip_fn_namelen;
		while  (i < temp_debuginfo.eip_fn_namelen){
f01007bd:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f01007c1:	74 24                	je     f01007e7 <mon_backtrace+0xae>
	while (ebp!=0) {
		cprintf("ebp %08x eip %08x args %08x %08x %08x %08x %08x\n",ebp, eip, ebp[2] ,ebp[3], ebp[4], ebp[5] ,ebp[6]);
		struct Eipdebuginfo temp_debuginfo;
		debuginfo_eip((uintptr_t) eip, &temp_debuginfo);		
		cprintf("       %s:%d: ", temp_debuginfo.eip_file, temp_debuginfo.eip_line);
		uint32_t i = 0;// = temp_debuginfo.eip_fn_namelen;
f01007c3:	bb 00 00 00 00       	mov    $0x0,%ebx
		while  (i < temp_debuginfo.eip_fn_namelen){
			cprintf("%c", temp_debuginfo.eip_fn_name[i]);
f01007c8:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01007cb:	0f be 04 18          	movsbl (%eax,%ebx,1),%eax
f01007cf:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007d3:	c7 04 24 f2 32 10 f0 	movl   $0xf01032f2,(%esp)
f01007da:	e8 73 17 00 00       	call   f0101f52 <cprintf>
			i++;	
f01007df:	83 c3 01             	add    $0x1,%ebx
		cprintf("ebp %08x eip %08x args %08x %08x %08x %08x %08x\n",ebp, eip, ebp[2] ,ebp[3], ebp[4], ebp[5] ,ebp[6]);
		struct Eipdebuginfo temp_debuginfo;
		debuginfo_eip((uintptr_t) eip, &temp_debuginfo);		
		cprintf("       %s:%d: ", temp_debuginfo.eip_file, temp_debuginfo.eip_line);
		uint32_t i = 0;// = temp_debuginfo.eip_fn_namelen;
		while  (i < temp_debuginfo.eip_fn_namelen){
f01007e2:	39 5d dc             	cmp    %ebx,-0x24(%ebp)
f01007e5:	77 e1                	ja     f01007c8 <mon_backtrace+0x8f>
			cprintf("%c", temp_debuginfo.eip_fn_name[i]);
			i++;	
		}
		int p = (int)eip;
		int q = (int)temp_debuginfo.eip_fn_addr;
		cprintf("+%x\n", p - q);
f01007e7:	2b 7d e0             	sub    -0x20(%ebp),%edi
f01007ea:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01007ee:	c7 04 24 f5 32 10 f0 	movl   $0xf01032f5,(%esp)
f01007f5:	e8 58 17 00 00       	call   f0101f52 <cprintf>
		ebp=(uint32_t*)ebp[0];
f01007fa:	8b 36                	mov    (%esi),%esi
		eip=(uint32_t*)ebp[1]; 
f01007fc:	8b 7e 04             	mov    0x4(%esi),%edi
//	cprintf("%08x", read_ebp());
	uint32_t *eip, *ebp;
	ebp = (uint32_t*) read_ebp();
	eip = (uint32_t*) ebp[1];
	cprintf("Stackbacktrace:\n");
	while (ebp!=0) {
f01007ff:	85 f6                	test   %esi,%esi
f0100801:	0f 85 56 ff ff ff    	jne    f010075d <mon_backtrace+0x24>
		eip=(uint32_t*)ebp[1]; 
	}
	
//	cprintf("%d", read_esp());
	return 0;
}
f0100807:	b8 00 00 00 00       	mov    $0x0,%eax
f010080c:	83 c4 4c             	add    $0x4c,%esp
f010080f:	5b                   	pop    %ebx
f0100810:	5e                   	pop    %esi
f0100811:	5f                   	pop    %edi
f0100812:	5d                   	pop    %ebp
f0100813:	c3                   	ret    

f0100814 <mon_setcolor>:
	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
	return 0;
}

int mon_setcolor(int argc, char **argv, struct Trapframe *tf) {
f0100814:	55                   	push   %ebp
f0100815:	89 e5                	mov    %esp,%ebp
f0100817:	83 ec 28             	sub    $0x28,%esp
f010081a:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f010081d:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0100820:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0100823:	8b 75 0c             	mov    0xc(%ebp),%esi
	//argv
	uint16_t ch_color1, ch_color;
	if(strcmp(argv[2],"blk")==0)
f0100826:	c7 44 24 04 fa 32 10 	movl   $0xf01032fa,0x4(%esp)
f010082d:	f0 
f010082e:	8b 46 08             	mov    0x8(%esi),%eax
f0100831:	89 04 24             	mov    %eax,(%esp)
f0100834:	e8 02 22 00 00       	call   f0102a3b <strcmp>
			ch_color1=COLOR_BLK
f0100839:	bf 00 00 00 00       	mov    $0x0,%edi
}

int mon_setcolor(int argc, char **argv, struct Trapframe *tf) {
	//argv
	uint16_t ch_color1, ch_color;
	if(strcmp(argv[2],"blk")==0)
f010083e:	85 c0                	test   %eax,%eax
f0100840:	0f 84 0e 01 00 00    	je     f0100954 <mon_setcolor+0x140>
			ch_color1=COLOR_BLK
	else if(strcmp(argv[2],"wht")==0)
f0100846:	c7 44 24 04 fe 32 10 	movl   $0xf01032fe,0x4(%esp)
f010084d:	f0 
f010084e:	8b 46 08             	mov    0x8(%esi),%eax
f0100851:	89 04 24             	mov    %eax,(%esp)
f0100854:	e8 e2 21 00 00       	call   f0102a3b <strcmp>
			ch_color1=COLOR_WHT
f0100859:	bf 07 00 00 00       	mov    $0x7,%edi
int mon_setcolor(int argc, char **argv, struct Trapframe *tf) {
	//argv
	uint16_t ch_color1, ch_color;
	if(strcmp(argv[2],"blk")==0)
			ch_color1=COLOR_BLK
	else if(strcmp(argv[2],"wht")==0)
f010085e:	85 c0                	test   %eax,%eax
f0100860:	0f 84 ee 00 00 00    	je     f0100954 <mon_setcolor+0x140>
			ch_color1=COLOR_WHT
	else if(strcmp(argv[2],"blu")==0)
f0100866:	c7 44 24 04 02 33 10 	movl   $0xf0103302,0x4(%esp)
f010086d:	f0 
f010086e:	8b 46 08             	mov    0x8(%esi),%eax
f0100871:	89 04 24             	mov    %eax,(%esp)
f0100874:	e8 c2 21 00 00       	call   f0102a3b <strcmp>
			ch_color1=COLOR_BLU
f0100879:	bf 01 00 00 00       	mov    $0x1,%edi
	uint16_t ch_color1, ch_color;
	if(strcmp(argv[2],"blk")==0)
			ch_color1=COLOR_BLK
	else if(strcmp(argv[2],"wht")==0)
			ch_color1=COLOR_WHT
	else if(strcmp(argv[2],"blu")==0)
f010087e:	85 c0                	test   %eax,%eax
f0100880:	0f 84 ce 00 00 00    	je     f0100954 <mon_setcolor+0x140>
			ch_color1=COLOR_BLU
	else if(strcmp(argv[2],"grn")==0)
f0100886:	c7 44 24 04 06 33 10 	movl   $0xf0103306,0x4(%esp)
f010088d:	f0 
f010088e:	8b 46 08             	mov    0x8(%esi),%eax
f0100891:	89 04 24             	mov    %eax,(%esp)
f0100894:	e8 a2 21 00 00       	call   f0102a3b <strcmp>
			ch_color1=COLOR_GRN
f0100899:	bf 02 00 00 00       	mov    $0x2,%edi
			ch_color1=COLOR_BLK
	else if(strcmp(argv[2],"wht")==0)
			ch_color1=COLOR_WHT
	else if(strcmp(argv[2],"blu")==0)
			ch_color1=COLOR_BLU
	else if(strcmp(argv[2],"grn")==0)
f010089e:	85 c0                	test   %eax,%eax
f01008a0:	0f 84 ae 00 00 00    	je     f0100954 <mon_setcolor+0x140>
			ch_color1=COLOR_GRN
	else if(strcmp(argv[2],"red")==0)
f01008a6:	c7 44 24 04 0a 33 10 	movl   $0xf010330a,0x4(%esp)
f01008ad:	f0 
f01008ae:	8b 46 08             	mov    0x8(%esi),%eax
f01008b1:	89 04 24             	mov    %eax,(%esp)
f01008b4:	e8 82 21 00 00       	call   f0102a3b <strcmp>
			ch_color1=COLOR_RED
f01008b9:	bf 04 00 00 00       	mov    $0x4,%edi
			ch_color1=COLOR_WHT
	else if(strcmp(argv[2],"blu")==0)
			ch_color1=COLOR_BLU
	else if(strcmp(argv[2],"grn")==0)
			ch_color1=COLOR_GRN
	else if(strcmp(argv[2],"red")==0)
f01008be:	85 c0                	test   %eax,%eax
f01008c0:	0f 84 8e 00 00 00    	je     f0100954 <mon_setcolor+0x140>
			ch_color1=COLOR_RED
	else if(strcmp(argv[2],"gry")==0)
f01008c6:	c7 44 24 04 0e 33 10 	movl   $0xf010330e,0x4(%esp)
f01008cd:	f0 
f01008ce:	8b 46 08             	mov    0x8(%esi),%eax
f01008d1:	89 04 24             	mov    %eax,(%esp)
f01008d4:	e8 62 21 00 00       	call   f0102a3b <strcmp>
			ch_color1=COLOR_GRY
f01008d9:	bf 08 00 00 00       	mov    $0x8,%edi
			ch_color1=COLOR_BLU
	else if(strcmp(argv[2],"grn")==0)
			ch_color1=COLOR_GRN
	else if(strcmp(argv[2],"red")==0)
			ch_color1=COLOR_RED
	else if(strcmp(argv[2],"gry")==0)
f01008de:	85 c0                	test   %eax,%eax
f01008e0:	74 72                	je     f0100954 <mon_setcolor+0x140>
			ch_color1=COLOR_GRY
	else if(strcmp(argv[2],"ylw")==0)
f01008e2:	c7 44 24 04 12 33 10 	movl   $0xf0103312,0x4(%esp)
f01008e9:	f0 
f01008ea:	8b 46 08             	mov    0x8(%esi),%eax
f01008ed:	89 04 24             	mov    %eax,(%esp)
f01008f0:	e8 46 21 00 00       	call   f0102a3b <strcmp>
			ch_color1=COLOR_YLW
f01008f5:	bf 0f 00 00 00       	mov    $0xf,%edi
			ch_color1=COLOR_GRN
	else if(strcmp(argv[2],"red")==0)
			ch_color1=COLOR_RED
	else if(strcmp(argv[2],"gry")==0)
			ch_color1=COLOR_GRY
	else if(strcmp(argv[2],"ylw")==0)
f01008fa:	85 c0                	test   %eax,%eax
f01008fc:	74 56                	je     f0100954 <mon_setcolor+0x140>
			ch_color1=COLOR_YLW
	else if(strcmp(argv[2],"org")==0)
f01008fe:	c7 44 24 04 16 33 10 	movl   $0xf0103316,0x4(%esp)
f0100905:	f0 
f0100906:	8b 46 08             	mov    0x8(%esi),%eax
f0100909:	89 04 24             	mov    %eax,(%esp)
f010090c:	e8 2a 21 00 00       	call   f0102a3b <strcmp>
			ch_color1=COLOR_ORG
f0100911:	bf 0c 00 00 00       	mov    $0xc,%edi
			ch_color1=COLOR_RED
	else if(strcmp(argv[2],"gry")==0)
			ch_color1=COLOR_GRY
	else if(strcmp(argv[2],"ylw")==0)
			ch_color1=COLOR_YLW
	else if(strcmp(argv[2],"org")==0)
f0100916:	85 c0                	test   %eax,%eax
f0100918:	74 3a                	je     f0100954 <mon_setcolor+0x140>
			ch_color1=COLOR_ORG
	else if(strcmp(argv[2],"pur")==0)
f010091a:	c7 44 24 04 1a 33 10 	movl   $0xf010331a,0x4(%esp)
f0100921:	f0 
f0100922:	8b 46 08             	mov    0x8(%esi),%eax
f0100925:	89 04 24             	mov    %eax,(%esp)
f0100928:	e8 0e 21 00 00       	call   f0102a3b <strcmp>
			ch_color1=COLOR_PUR
f010092d:	bf 06 00 00 00       	mov    $0x6,%edi
			ch_color1=COLOR_GRY
	else if(strcmp(argv[2],"ylw")==0)
			ch_color1=COLOR_YLW
	else if(strcmp(argv[2],"org")==0)
			ch_color1=COLOR_ORG
	else if(strcmp(argv[2],"pur")==0)
f0100932:	85 c0                	test   %eax,%eax
f0100934:	74 1e                	je     f0100954 <mon_setcolor+0x140>
			ch_color1=COLOR_PUR
	else if(strcmp(argv[2],"cyn")==0)
f0100936:	c7 44 24 04 1e 33 10 	movl   $0xf010331e,0x4(%esp)
f010093d:	f0 
f010093e:	8b 46 08             	mov    0x8(%esi),%eax
f0100941:	89 04 24             	mov    %eax,(%esp)
f0100944:	e8 f2 20 00 00       	call   f0102a3b <strcmp>
			ch_color1=COLOR_CYN
f0100949:	83 f8 01             	cmp    $0x1,%eax
f010094c:	19 ff                	sbb    %edi,%edi
f010094e:	83 e7 04             	and    $0x4,%edi
f0100951:	83 c7 07             	add    $0x7,%edi
	else ch_color1=COLOR_WHT;
	if(strcmp(argv[1],"blk")==0)
f0100954:	c7 44 24 04 fa 32 10 	movl   $0xf01032fa,0x4(%esp)
f010095b:	f0 
f010095c:	8b 46 04             	mov    0x4(%esi),%eax
f010095f:	89 04 24             	mov    %eax,(%esp)
f0100962:	e8 d4 20 00 00       	call   f0102a3b <strcmp>
			ch_color=COLOR_BLK
f0100967:	bb 00 00 00 00       	mov    $0x0,%ebx
	else if(strcmp(argv[2],"pur")==0)
			ch_color1=COLOR_PUR
	else if(strcmp(argv[2],"cyn")==0)
			ch_color1=COLOR_CYN
	else ch_color1=COLOR_WHT;
	if(strcmp(argv[1],"blk")==0)
f010096c:	85 c0                	test   %eax,%eax
f010096e:	0f 84 f6 00 00 00    	je     f0100a6a <mon_setcolor+0x256>
			ch_color=COLOR_BLK
	else if(strcmp(argv[1],"wht")==0)
f0100974:	c7 44 24 04 fe 32 10 	movl   $0xf01032fe,0x4(%esp)
f010097b:	f0 
f010097c:	8b 46 04             	mov    0x4(%esi),%eax
f010097f:	89 04 24             	mov    %eax,(%esp)
f0100982:	e8 b4 20 00 00       	call   f0102a3b <strcmp>
			ch_color=COLOR_WHT
f0100987:	b3 07                	mov    $0x7,%bl
	else if(strcmp(argv[2],"cyn")==0)
			ch_color1=COLOR_CYN
	else ch_color1=COLOR_WHT;
	if(strcmp(argv[1],"blk")==0)
			ch_color=COLOR_BLK
	else if(strcmp(argv[1],"wht")==0)
f0100989:	85 c0                	test   %eax,%eax
f010098b:	0f 84 d9 00 00 00    	je     f0100a6a <mon_setcolor+0x256>
			ch_color=COLOR_WHT
	else if(strcmp(argv[1],"blu")==0)
f0100991:	c7 44 24 04 02 33 10 	movl   $0xf0103302,0x4(%esp)
f0100998:	f0 
f0100999:	8b 46 04             	mov    0x4(%esi),%eax
f010099c:	89 04 24             	mov    %eax,(%esp)
f010099f:	e8 97 20 00 00       	call   f0102a3b <strcmp>
			ch_color=COLOR_BLU
f01009a4:	b3 01                	mov    $0x1,%bl
	else ch_color1=COLOR_WHT;
	if(strcmp(argv[1],"blk")==0)
			ch_color=COLOR_BLK
	else if(strcmp(argv[1],"wht")==0)
			ch_color=COLOR_WHT
	else if(strcmp(argv[1],"blu")==0)
f01009a6:	85 c0                	test   %eax,%eax
f01009a8:	0f 84 bc 00 00 00    	je     f0100a6a <mon_setcolor+0x256>
			ch_color=COLOR_BLU
	else if(strcmp(argv[1],"grn")==0)
f01009ae:	c7 44 24 04 06 33 10 	movl   $0xf0103306,0x4(%esp)
f01009b5:	f0 
f01009b6:	8b 46 04             	mov    0x4(%esi),%eax
f01009b9:	89 04 24             	mov    %eax,(%esp)
f01009bc:	e8 7a 20 00 00       	call   f0102a3b <strcmp>
			ch_color=COLOR_GRN
f01009c1:	b3 02                	mov    $0x2,%bl
			ch_color=COLOR_BLK
	else if(strcmp(argv[1],"wht")==0)
			ch_color=COLOR_WHT
	else if(strcmp(argv[1],"blu")==0)
			ch_color=COLOR_BLU
	else if(strcmp(argv[1],"grn")==0)
f01009c3:	85 c0                	test   %eax,%eax
f01009c5:	0f 84 9f 00 00 00    	je     f0100a6a <mon_setcolor+0x256>
			ch_color=COLOR_GRN
	else if(strcmp(argv[1],"red")==0)
f01009cb:	c7 44 24 04 0a 33 10 	movl   $0xf010330a,0x4(%esp)
f01009d2:	f0 
f01009d3:	8b 46 04             	mov    0x4(%esi),%eax
f01009d6:	89 04 24             	mov    %eax,(%esp)
f01009d9:	e8 5d 20 00 00       	call   f0102a3b <strcmp>
			ch_color=COLOR_RED
f01009de:	b3 04                	mov    $0x4,%bl
			ch_color=COLOR_WHT
	else if(strcmp(argv[1],"blu")==0)
			ch_color=COLOR_BLU
	else if(strcmp(argv[1],"grn")==0)
			ch_color=COLOR_GRN
	else if(strcmp(argv[1],"red")==0)
f01009e0:	85 c0                	test   %eax,%eax
f01009e2:	0f 84 82 00 00 00    	je     f0100a6a <mon_setcolor+0x256>
			ch_color=COLOR_RED
	else if(strcmp(argv[1],"gry")==0)
f01009e8:	c7 44 24 04 0e 33 10 	movl   $0xf010330e,0x4(%esp)
f01009ef:	f0 
f01009f0:	8b 46 04             	mov    0x4(%esi),%eax
f01009f3:	89 04 24             	mov    %eax,(%esp)
f01009f6:	e8 40 20 00 00       	call   f0102a3b <strcmp>
			ch_color=COLOR_GRY
f01009fb:	b3 08                	mov    $0x8,%bl
			ch_color=COLOR_BLU
	else if(strcmp(argv[1],"grn")==0)
			ch_color=COLOR_GRN
	else if(strcmp(argv[1],"red")==0)
			ch_color=COLOR_RED
	else if(strcmp(argv[1],"gry")==0)
f01009fd:	85 c0                	test   %eax,%eax
f01009ff:	74 69                	je     f0100a6a <mon_setcolor+0x256>
			ch_color=COLOR_GRY
	else if(strcmp(argv[1],"ylw")==0)
f0100a01:	c7 44 24 04 12 33 10 	movl   $0xf0103312,0x4(%esp)
f0100a08:	f0 
f0100a09:	8b 46 04             	mov    0x4(%esi),%eax
f0100a0c:	89 04 24             	mov    %eax,(%esp)
f0100a0f:	e8 27 20 00 00       	call   f0102a3b <strcmp>
			ch_color=COLOR_YLW
f0100a14:	b3 0f                	mov    $0xf,%bl
			ch_color=COLOR_GRN
	else if(strcmp(argv[1],"red")==0)
			ch_color=COLOR_RED
	else if(strcmp(argv[1],"gry")==0)
			ch_color=COLOR_GRY
	else if(strcmp(argv[1],"ylw")==0)
f0100a16:	85 c0                	test   %eax,%eax
f0100a18:	74 50                	je     f0100a6a <mon_setcolor+0x256>
			ch_color=COLOR_YLW
	else if(strcmp(argv[1],"org")==0)
f0100a1a:	c7 44 24 04 16 33 10 	movl   $0xf0103316,0x4(%esp)
f0100a21:	f0 
f0100a22:	8b 46 04             	mov    0x4(%esi),%eax
f0100a25:	89 04 24             	mov    %eax,(%esp)
f0100a28:	e8 0e 20 00 00       	call   f0102a3b <strcmp>
			ch_color=COLOR_ORG
f0100a2d:	b3 0c                	mov    $0xc,%bl
			ch_color=COLOR_RED
	else if(strcmp(argv[1],"gry")==0)
			ch_color=COLOR_GRY
	else if(strcmp(argv[1],"ylw")==0)
			ch_color=COLOR_YLW
	else if(strcmp(argv[1],"org")==0)
f0100a2f:	85 c0                	test   %eax,%eax
f0100a31:	74 37                	je     f0100a6a <mon_setcolor+0x256>
			ch_color=COLOR_ORG
	else if(strcmp(argv[1],"pur")==0)
f0100a33:	c7 44 24 04 1a 33 10 	movl   $0xf010331a,0x4(%esp)
f0100a3a:	f0 
f0100a3b:	8b 46 04             	mov    0x4(%esi),%eax
f0100a3e:	89 04 24             	mov    %eax,(%esp)
f0100a41:	e8 f5 1f 00 00       	call   f0102a3b <strcmp>
			ch_color=COLOR_PUR
f0100a46:	b3 06                	mov    $0x6,%bl
			ch_color=COLOR_GRY
	else if(strcmp(argv[1],"ylw")==0)
			ch_color=COLOR_YLW
	else if(strcmp(argv[1],"org")==0)
			ch_color=COLOR_ORG
	else if(strcmp(argv[1],"pur")==0)
f0100a48:	85 c0                	test   %eax,%eax
f0100a4a:	74 1e                	je     f0100a6a <mon_setcolor+0x256>
			ch_color=COLOR_PUR
	else if(strcmp(argv[1],"cyn")==0)
f0100a4c:	c7 44 24 04 1e 33 10 	movl   $0xf010331e,0x4(%esp)
f0100a53:	f0 
f0100a54:	8b 46 04             	mov    0x4(%esi),%eax
f0100a57:	89 04 24             	mov    %eax,(%esp)
f0100a5a:	e8 dc 1f 00 00       	call   f0102a3b <strcmp>
			ch_color=COLOR_CYN
f0100a5f:	83 f8 01             	cmp    $0x1,%eax
f0100a62:	19 db                	sbb    %ebx,%ebx
f0100a64:	83 e3 04             	and    $0x4,%ebx
f0100a67:	83 c3 07             	add    $0x7,%ebx
	else ch_color=COLOR_WHT;
	set_attribute_color((uint64_t) ch_color, (uint64_t) ch_color1);
f0100a6a:	0f b7 f7             	movzwl %di,%esi
f0100a6d:	0f b7 db             	movzwl %bx,%ebx
f0100a70:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100a74:	89 1c 24             	mov    %ebx,(%esp)
f0100a77:	e8 fd f9 ff ff       	call   f0100479 <set_attribute_color>
	cprintf("console back-color :  %d \n        fore-color :  %d\n", ch_color, ch_color1);	
f0100a7c:	89 74 24 08          	mov    %esi,0x8(%esp)
f0100a80:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100a84:	c7 04 24 cc 34 10 f0 	movl   $0xf01034cc,(%esp)
f0100a8b:	e8 c2 14 00 00       	call   f0101f52 <cprintf>
	return 0;
}
f0100a90:	b8 00 00 00 00       	mov    $0x0,%eax
f0100a95:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0100a98:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0100a9b:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0100a9e:	89 ec                	mov    %ebp,%esp
f0100aa0:	5d                   	pop    %ebp
f0100aa1:	c3                   	ret    

f0100aa2 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100aa2:	55                   	push   %ebp
f0100aa3:	89 e5                	mov    %esp,%ebp
f0100aa5:	57                   	push   %edi
f0100aa6:	56                   	push   %esi
f0100aa7:	53                   	push   %ebx
f0100aa8:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100aab:	c7 04 24 00 35 10 f0 	movl   $0xf0103500,(%esp)
f0100ab2:	e8 9b 14 00 00       	call   f0101f52 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100ab7:	c7 04 24 24 35 10 f0 	movl   $0xf0103524,(%esp)
f0100abe:	e8 8f 14 00 00       	call   f0101f52 <cprintf>
  //	cprintf("x %d, y %x, z %d\n", x, y, z);
//	unsigned int i = 0x00646c72;
//	cprintf("H%x Wo%s", 57616, &i);

	while (1) {
		buf = readline("K> ");
f0100ac3:	c7 04 24 22 33 10 f0 	movl   $0xf0103322,(%esp)
f0100aca:	e8 91 1d 00 00       	call   f0102860 <readline>
f0100acf:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100ad1:	85 c0                	test   %eax,%eax
f0100ad3:	74 ee                	je     f0100ac3 <monitor+0x21>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100ad5:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100adc:	be 00 00 00 00       	mov    $0x0,%esi
f0100ae1:	eb 06                	jmp    f0100ae9 <monitor+0x47>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100ae3:	c6 03 00             	movb   $0x0,(%ebx)
f0100ae6:	83 c3 01             	add    $0x1,%ebx
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100ae9:	0f b6 03             	movzbl (%ebx),%eax
f0100aec:	84 c0                	test   %al,%al
f0100aee:	74 6b                	je     f0100b5b <monitor+0xb9>
f0100af0:	0f be c0             	movsbl %al,%eax
f0100af3:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100af7:	c7 04 24 26 33 10 f0 	movl   $0xf0103326,(%esp)
f0100afe:	e8 b3 1f 00 00       	call   f0102ab6 <strchr>
f0100b03:	85 c0                	test   %eax,%eax
f0100b05:	75 dc                	jne    f0100ae3 <monitor+0x41>
			*buf++ = 0;
		if (*buf == 0)
f0100b07:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100b0a:	74 4f                	je     f0100b5b <monitor+0xb9>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100b0c:	83 fe 0f             	cmp    $0xf,%esi
f0100b0f:	90                   	nop
f0100b10:	75 16                	jne    f0100b28 <monitor+0x86>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100b12:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f0100b19:	00 
f0100b1a:	c7 04 24 2b 33 10 f0 	movl   $0xf010332b,(%esp)
f0100b21:	e8 2c 14 00 00       	call   f0101f52 <cprintf>
f0100b26:	eb 9b                	jmp    f0100ac3 <monitor+0x21>
			return 0;
		}
		argv[argc++] = buf;
f0100b28:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100b2c:	83 c6 01             	add    $0x1,%esi
		while (*buf && !strchr(WHITESPACE, *buf))
f0100b2f:	0f b6 03             	movzbl (%ebx),%eax
f0100b32:	84 c0                	test   %al,%al
f0100b34:	75 0c                	jne    f0100b42 <monitor+0xa0>
f0100b36:	eb b1                	jmp    f0100ae9 <monitor+0x47>
			buf++;
f0100b38:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100b3b:	0f b6 03             	movzbl (%ebx),%eax
f0100b3e:	84 c0                	test   %al,%al
f0100b40:	74 a7                	je     f0100ae9 <monitor+0x47>
f0100b42:	0f be c0             	movsbl %al,%eax
f0100b45:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100b49:	c7 04 24 26 33 10 f0 	movl   $0xf0103326,(%esp)
f0100b50:	e8 61 1f 00 00       	call   f0102ab6 <strchr>
f0100b55:	85 c0                	test   %eax,%eax
f0100b57:	74 df                	je     f0100b38 <monitor+0x96>
f0100b59:	eb 8e                	jmp    f0100ae9 <monitor+0x47>
			buf++;
	}
	argv[argc] = 0;
f0100b5b:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100b62:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100b63:	85 f6                	test   %esi,%esi
f0100b65:	0f 84 58 ff ff ff    	je     f0100ac3 <monitor+0x21>
f0100b6b:	bb a0 35 10 f0       	mov    $0xf01035a0,%ebx
f0100b70:	bf 00 00 00 00       	mov    $0x0,%edi
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100b75:	8b 03                	mov    (%ebx),%eax
f0100b77:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100b7b:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100b7e:	89 04 24             	mov    %eax,(%esp)
f0100b81:	e8 b5 1e 00 00       	call   f0102a3b <strcmp>
f0100b86:	85 c0                	test   %eax,%eax
f0100b88:	75 24                	jne    f0100bae <monitor+0x10c>
			return commands[i].func(argc, argv, tf);
f0100b8a:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f0100b8d:	8b 55 08             	mov    0x8(%ebp),%edx
f0100b90:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100b94:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100b97:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100b9b:	89 34 24             	mov    %esi,(%esp)
f0100b9e:	ff 14 85 a8 35 10 f0 	call   *-0xfefca58(,%eax,4)
//	cprintf("H%x Wo%s", 57616, &i);

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100ba5:	85 c0                	test   %eax,%eax
f0100ba7:	78 28                	js     f0100bd1 <monitor+0x12f>
f0100ba9:	e9 15 ff ff ff       	jmp    f0100ac3 <monitor+0x21>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f0100bae:	83 c7 01             	add    $0x1,%edi
f0100bb1:	83 c3 0c             	add    $0xc,%ebx
f0100bb4:	83 ff 04             	cmp    $0x4,%edi
f0100bb7:	75 bc                	jne    f0100b75 <monitor+0xd3>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100bb9:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100bbc:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100bc0:	c7 04 24 48 33 10 f0 	movl   $0xf0103348,(%esp)
f0100bc7:	e8 86 13 00 00       	call   f0101f52 <cprintf>
f0100bcc:	e9 f2 fe ff ff       	jmp    f0100ac3 <monitor+0x21>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100bd1:	83 c4 5c             	add    $0x5c,%esp
f0100bd4:	5b                   	pop    %ebx
f0100bd5:	5e                   	pop    %esi
f0100bd6:	5f                   	pop    %edi
f0100bd7:	5d                   	pop    %ebp
f0100bd8:	c3                   	ret    
f0100bd9:	00 00                	add    %al,(%eax)
	...

f0100bdc <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100bdc:	55                   	push   %ebp
f0100bdd:	89 e5                	mov    %esp,%ebp
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100bdf:	83 3d 5c 65 11 f0 00 	cmpl   $0x0,0xf011655c
f0100be6:	75 11                	jne    f0100bf9 <boot_alloc+0x1d>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100be8:	ba 8f 79 11 f0       	mov    $0xf011798f,%edx
f0100bed:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100bf3:	89 15 5c 65 11 f0    	mov    %edx,0xf011655c
		void *temp = nextfree;
		nextfree += n;
		nextfree = ROUNDUP(nextfree, PGSIZE);
		return temp;
	} else if (n == 0) {
		return (void*)nextfree;
f0100bf9:	8b 15 5c 65 11 f0    	mov    0xf011655c,%edx
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	// page_alloc() is the real allocator.

	// LAB 2: Your code here.
	if (n > 0) {
f0100bff:	85 c0                	test   %eax,%eax
f0100c01:	74 11                	je     f0100c14 <boot_alloc+0x38>
		void *temp = nextfree;
		nextfree += n;
		nextfree = ROUNDUP(nextfree, PGSIZE);
f0100c03:	8d 84 02 ff 0f 00 00 	lea    0xfff(%edx,%eax,1),%eax
f0100c0a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100c0f:	a3 5c 65 11 f0       	mov    %eax,0xf011655c
		return temp;
	} else if (n == 0) {
		return (void*)nextfree;
	}
	return NULL;
}
f0100c14:	89 d0                	mov    %edx,%eax
f0100c16:	5d                   	pop    %ebp
f0100c17:	c3                   	ret    

f0100c18 <check_va2pa>:
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100c18:	55                   	push   %ebp
f0100c19:	89 e5                	mov    %esp,%ebp
f0100c1b:	83 ec 18             	sub    $0x18,%esp
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
f0100c1e:	89 d1                	mov    %edx,%ecx
f0100c20:	c1 e9 16             	shr    $0x16,%ecx
	if (!(*pgdir & PTE_P))
f0100c23:	8b 0c 88             	mov    (%eax,%ecx,4),%ecx
		return ~0;
f0100c26:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
check_va2pa(pde_t *pgdir, uintptr_t va)
{
	pte_t *p;

	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f0100c2b:	f6 c1 01             	test   $0x1,%cl
f0100c2e:	74 57                	je     f0100c87 <check_va2pa+0x6f>
		return ~0;
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100c30:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100c36:	89 c8                	mov    %ecx,%eax
f0100c38:	c1 e8 0c             	shr    $0xc,%eax
f0100c3b:	3b 05 84 69 11 f0    	cmp    0xf0116984,%eax
f0100c41:	72 20                	jb     f0100c63 <check_va2pa+0x4b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100c43:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0100c47:	c7 44 24 08 d0 35 10 	movl   $0xf01035d0,0x8(%esp)
f0100c4e:	f0 
f0100c4f:	c7 44 24 04 8f 02 00 	movl   $0x28f,0x4(%esp)
f0100c56:	00 
f0100c57:	c7 04 24 d4 39 10 f0 	movl   $0xf01039d4,(%esp)
f0100c5e:	e8 31 f4 ff ff       	call   f0100094 <_panic>
	if (!(p[PTX(va)] & PTE_P))
f0100c63:	c1 ea 0c             	shr    $0xc,%edx
f0100c66:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0100c6c:	8b 84 91 00 00 00 f0 	mov    -0x10000000(%ecx,%edx,4),%eax
f0100c73:	89 c2                	mov    %eax,%edx
f0100c75:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100c78:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100c7d:	85 d2                	test   %edx,%edx
f0100c7f:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100c84:	0f 44 c2             	cmove  %edx,%eax
}
f0100c87:	c9                   	leave  
f0100c88:	c3                   	ret    

f0100c89 <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f0100c89:	55                   	push   %ebp
f0100c8a:	89 e5                	mov    %esp,%ebp
f0100c8c:	83 ec 18             	sub    $0x18,%esp
f0100c8f:	89 5d f8             	mov    %ebx,-0x8(%ebp)
f0100c92:	89 75 fc             	mov    %esi,-0x4(%ebp)
f0100c95:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100c97:	89 04 24             	mov    %eax,(%esp)
f0100c9a:	e8 45 12 00 00       	call   f0101ee4 <mc146818_read>
f0100c9f:	89 c6                	mov    %eax,%esi
f0100ca1:	83 c3 01             	add    $0x1,%ebx
f0100ca4:	89 1c 24             	mov    %ebx,(%esp)
f0100ca7:	e8 38 12 00 00       	call   f0101ee4 <mc146818_read>
f0100cac:	c1 e0 08             	shl    $0x8,%eax
f0100caf:	09 f0                	or     %esi,%eax
}
f0100cb1:	8b 5d f8             	mov    -0x8(%ebp),%ebx
f0100cb4:	8b 75 fc             	mov    -0x4(%ebp),%esi
f0100cb7:	89 ec                	mov    %ebp,%esp
f0100cb9:	5d                   	pop    %ebp
f0100cba:	c3                   	ret    

f0100cbb <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100cbb:	55                   	push   %ebp
f0100cbc:	89 e5                	mov    %esp,%ebp
f0100cbe:	57                   	push   %edi
f0100cbf:	56                   	push   %esi
f0100cc0:	53                   	push   %ebx
f0100cc1:	83 ec 3c             	sub    $0x3c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100cc4:	3c 01                	cmp    $0x1,%al
f0100cc6:	19 f6                	sbb    %esi,%esi
f0100cc8:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
f0100cce:	83 c6 01             	add    $0x1,%esi
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100cd1:	8b 1d 60 65 11 f0    	mov    0xf0116560,%ebx
f0100cd7:	85 db                	test   %ebx,%ebx
f0100cd9:	75 1c                	jne    f0100cf7 <check_page_free_list+0x3c>
		panic("'page_free_list' is a null pointer!");
f0100cdb:	c7 44 24 08 f4 35 10 	movl   $0xf01035f4,0x8(%esp)
f0100ce2:	f0 
f0100ce3:	c7 44 24 04 d2 01 00 	movl   $0x1d2,0x4(%esp)
f0100cea:	00 
f0100ceb:	c7 04 24 d4 39 10 f0 	movl   $0xf01039d4,(%esp)
f0100cf2:	e8 9d f3 ff ff       	call   f0100094 <_panic>

	if (only_low_memory) {
f0100cf7:	84 c0                	test   %al,%al
f0100cf9:	74 50                	je     f0100d4b <check_page_free_list+0x90>
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100cfb:	8d 45 e0             	lea    -0x20(%ebp),%eax
f0100cfe:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100d01:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0100d04:	89 45 dc             	mov    %eax,-0x24(%ebp)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100d07:	89 d8                	mov    %ebx,%eax
f0100d09:	2b 05 8c 69 11 f0    	sub    0xf011698c,%eax
f0100d0f:	c1 e0 09             	shl    $0x9,%eax
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100d12:	c1 e8 16             	shr    $0x16,%eax
f0100d15:	39 c6                	cmp    %eax,%esi
f0100d17:	0f 96 c0             	setbe  %al
f0100d1a:	0f b6 c0             	movzbl %al,%eax
			*tp[pagetype] = pp;
f0100d1d:	8b 54 85 d8          	mov    -0x28(%ebp,%eax,4),%edx
f0100d21:	89 1a                	mov    %ebx,(%edx)
			tp[pagetype] = &pp->pp_link;
f0100d23:	89 5c 85 d8          	mov    %ebx,-0x28(%ebp,%eax,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100d27:	8b 1b                	mov    (%ebx),%ebx
f0100d29:	85 db                	test   %ebx,%ebx
f0100d2b:	75 da                	jne    f0100d07 <check_page_free_list+0x4c>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100d2d:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100d30:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100d36:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100d39:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0100d3c:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100d3e:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0100d41:	89 1d 60 65 11 f0    	mov    %ebx,0xf0116560
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100d47:	85 db                	test   %ebx,%ebx
f0100d49:	74 67                	je     f0100db2 <check_page_free_list+0xf7>
f0100d4b:	89 d8                	mov    %ebx,%eax
f0100d4d:	2b 05 8c 69 11 f0    	sub    0xf011698c,%eax
f0100d53:	c1 f8 03             	sar    $0x3,%eax
f0100d56:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100d59:	89 c2                	mov    %eax,%edx
f0100d5b:	c1 ea 16             	shr    $0x16,%edx
f0100d5e:	39 d6                	cmp    %edx,%esi
f0100d60:	76 4a                	jbe    f0100dac <check_page_free_list+0xf1>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100d62:	89 c2                	mov    %eax,%edx
f0100d64:	c1 ea 0c             	shr    $0xc,%edx
f0100d67:	3b 15 84 69 11 f0    	cmp    0xf0116984,%edx
f0100d6d:	72 20                	jb     f0100d8f <check_page_free_list+0xd4>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100d6f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100d73:	c7 44 24 08 d0 35 10 	movl   $0xf01035d0,0x8(%esp)
f0100d7a:	f0 
f0100d7b:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100d82:	00 
f0100d83:	c7 04 24 e0 39 10 f0 	movl   $0xf01039e0,(%esp)
f0100d8a:	e8 05 f3 ff ff       	call   f0100094 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100d8f:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
f0100d96:	00 
f0100d97:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
f0100d9e:	00 
	return (void *)(pa + KERNBASE);
f0100d9f:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100da4:	89 04 24             	mov    %eax,(%esp)
f0100da7:	e8 65 1d 00 00       	call   f0102b11 <memset>
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100dac:	8b 1b                	mov    (%ebx),%ebx
f0100dae:	85 db                	test   %ebx,%ebx
f0100db0:	75 99                	jne    f0100d4b <check_page_free_list+0x90>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100db2:	b8 00 00 00 00       	mov    $0x0,%eax
f0100db7:	e8 20 fe ff ff       	call   f0100bdc <boot_alloc>
f0100dbc:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100dbf:	8b 15 60 65 11 f0    	mov    0xf0116560,%edx
f0100dc5:	85 d2                	test   %edx,%edx
f0100dc7:	0f 84 f6 01 00 00    	je     f0100fc3 <check_page_free_list+0x308>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100dcd:	8b 1d 8c 69 11 f0    	mov    0xf011698c,%ebx
f0100dd3:	39 da                	cmp    %ebx,%edx
f0100dd5:	72 4d                	jb     f0100e24 <check_page_free_list+0x169>
		assert(pp < pages + npages);
f0100dd7:	a1 84 69 11 f0       	mov    0xf0116984,%eax
f0100ddc:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0100ddf:	8d 04 c3             	lea    (%ebx,%eax,8),%eax
f0100de2:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0100de5:	39 c2                	cmp    %eax,%edx
f0100de7:	73 64                	jae    f0100e4d <check_page_free_list+0x192>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100de9:	89 5d d0             	mov    %ebx,-0x30(%ebp)
f0100dec:	89 d0                	mov    %edx,%eax
f0100dee:	29 d8                	sub    %ebx,%eax
f0100df0:	a8 07                	test   $0x7,%al
f0100df2:	0f 85 82 00 00 00    	jne    f0100e7a <check_page_free_list+0x1bf>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100df8:	c1 f8 03             	sar    $0x3,%eax
f0100dfb:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100dfe:	85 c0                	test   %eax,%eax
f0100e00:	0f 84 a2 00 00 00    	je     f0100ea8 <check_page_free_list+0x1ed>
		assert(page2pa(pp) != IOPHYSMEM);
f0100e06:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100e0b:	0f 84 c2 00 00 00    	je     f0100ed3 <check_page_free_list+0x218>
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100e11:	be 00 00 00 00       	mov    $0x0,%esi
f0100e16:	bf 00 00 00 00       	mov    $0x0,%edi
f0100e1b:	e9 d7 00 00 00       	jmp    f0100ef7 <check_page_free_list+0x23c>
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100e20:	39 da                	cmp    %ebx,%edx
f0100e22:	73 24                	jae    f0100e48 <check_page_free_list+0x18d>
f0100e24:	c7 44 24 0c ee 39 10 	movl   $0xf01039ee,0xc(%esp)
f0100e2b:	f0 
f0100e2c:	c7 44 24 08 fa 39 10 	movl   $0xf01039fa,0x8(%esp)
f0100e33:	f0 
f0100e34:	c7 44 24 04 ec 01 00 	movl   $0x1ec,0x4(%esp)
f0100e3b:	00 
f0100e3c:	c7 04 24 d4 39 10 f0 	movl   $0xf01039d4,(%esp)
f0100e43:	e8 4c f2 ff ff       	call   f0100094 <_panic>
		assert(pp < pages + npages);
f0100e48:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100e4b:	72 24                	jb     f0100e71 <check_page_free_list+0x1b6>
f0100e4d:	c7 44 24 0c 0f 3a 10 	movl   $0xf0103a0f,0xc(%esp)
f0100e54:	f0 
f0100e55:	c7 44 24 08 fa 39 10 	movl   $0xf01039fa,0x8(%esp)
f0100e5c:	f0 
f0100e5d:	c7 44 24 04 ed 01 00 	movl   $0x1ed,0x4(%esp)
f0100e64:	00 
f0100e65:	c7 04 24 d4 39 10 f0 	movl   $0xf01039d4,(%esp)
f0100e6c:	e8 23 f2 ff ff       	call   f0100094 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100e71:	89 d0                	mov    %edx,%eax
f0100e73:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0100e76:	a8 07                	test   $0x7,%al
f0100e78:	74 24                	je     f0100e9e <check_page_free_list+0x1e3>
f0100e7a:	c7 44 24 0c 18 36 10 	movl   $0xf0103618,0xc(%esp)
f0100e81:	f0 
f0100e82:	c7 44 24 08 fa 39 10 	movl   $0xf01039fa,0x8(%esp)
f0100e89:	f0 
f0100e8a:	c7 44 24 04 ee 01 00 	movl   $0x1ee,0x4(%esp)
f0100e91:	00 
f0100e92:	c7 04 24 d4 39 10 f0 	movl   $0xf01039d4,(%esp)
f0100e99:	e8 f6 f1 ff ff       	call   f0100094 <_panic>
f0100e9e:	c1 f8 03             	sar    $0x3,%eax
f0100ea1:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100ea4:	85 c0                	test   %eax,%eax
f0100ea6:	75 24                	jne    f0100ecc <check_page_free_list+0x211>
f0100ea8:	c7 44 24 0c 23 3a 10 	movl   $0xf0103a23,0xc(%esp)
f0100eaf:	f0 
f0100eb0:	c7 44 24 08 fa 39 10 	movl   $0xf01039fa,0x8(%esp)
f0100eb7:	f0 
f0100eb8:	c7 44 24 04 f1 01 00 	movl   $0x1f1,0x4(%esp)
f0100ebf:	00 
f0100ec0:	c7 04 24 d4 39 10 f0 	movl   $0xf01039d4,(%esp)
f0100ec7:	e8 c8 f1 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100ecc:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100ed1:	75 24                	jne    f0100ef7 <check_page_free_list+0x23c>
f0100ed3:	c7 44 24 0c 34 3a 10 	movl   $0xf0103a34,0xc(%esp)
f0100eda:	f0 
f0100edb:	c7 44 24 08 fa 39 10 	movl   $0xf01039fa,0x8(%esp)
f0100ee2:	f0 
f0100ee3:	c7 44 24 04 f2 01 00 	movl   $0x1f2,0x4(%esp)
f0100eea:	00 
f0100eeb:	c7 04 24 d4 39 10 f0 	movl   $0xf01039d4,(%esp)
f0100ef2:	e8 9d f1 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100ef7:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100efc:	75 24                	jne    f0100f22 <check_page_free_list+0x267>
f0100efe:	c7 44 24 0c 4c 36 10 	movl   $0xf010364c,0xc(%esp)
f0100f05:	f0 
f0100f06:	c7 44 24 08 fa 39 10 	movl   $0xf01039fa,0x8(%esp)
f0100f0d:	f0 
f0100f0e:	c7 44 24 04 f3 01 00 	movl   $0x1f3,0x4(%esp)
f0100f15:	00 
f0100f16:	c7 04 24 d4 39 10 f0 	movl   $0xf01039d4,(%esp)
f0100f1d:	e8 72 f1 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100f22:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100f27:	75 24                	jne    f0100f4d <check_page_free_list+0x292>
f0100f29:	c7 44 24 0c 4d 3a 10 	movl   $0xf0103a4d,0xc(%esp)
f0100f30:	f0 
f0100f31:	c7 44 24 08 fa 39 10 	movl   $0xf01039fa,0x8(%esp)
f0100f38:	f0 
f0100f39:	c7 44 24 04 f4 01 00 	movl   $0x1f4,0x4(%esp)
f0100f40:	00 
f0100f41:	c7 04 24 d4 39 10 f0 	movl   $0xf01039d4,(%esp)
f0100f48:	e8 47 f1 ff ff       	call   f0100094 <_panic>
f0100f4d:	89 c1                	mov    %eax,%ecx
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100f4f:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100f54:	76 57                	jbe    f0100fad <check_page_free_list+0x2f2>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100f56:	c1 e8 0c             	shr    $0xc,%eax
f0100f59:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100f5c:	77 20                	ja     f0100f7e <check_page_free_list+0x2c3>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100f5e:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0100f62:	c7 44 24 08 d0 35 10 	movl   $0xf01035d0,0x8(%esp)
f0100f69:	f0 
f0100f6a:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100f71:	00 
f0100f72:	c7 04 24 e0 39 10 f0 	movl   $0xf01039e0,(%esp)
f0100f79:	e8 16 f1 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0100f7e:	81 e9 00 00 00 10    	sub    $0x10000000,%ecx
f0100f84:	39 4d c8             	cmp    %ecx,-0x38(%ebp)
f0100f87:	76 29                	jbe    f0100fb2 <check_page_free_list+0x2f7>
f0100f89:	c7 44 24 0c 70 36 10 	movl   $0xf0103670,0xc(%esp)
f0100f90:	f0 
f0100f91:	c7 44 24 08 fa 39 10 	movl   $0xf01039fa,0x8(%esp)
f0100f98:	f0 
f0100f99:	c7 44 24 04 f5 01 00 	movl   $0x1f5,0x4(%esp)
f0100fa0:	00 
f0100fa1:	c7 04 24 d4 39 10 f0 	movl   $0xf01039d4,(%esp)
f0100fa8:	e8 e7 f0 ff ff       	call   f0100094 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100fad:	83 c7 01             	add    $0x1,%edi
f0100fb0:	eb 03                	jmp    f0100fb5 <check_page_free_list+0x2fa>
		else
			++nfree_extmem;
f0100fb2:	83 c6 01             	add    $0x1,%esi
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100fb5:	8b 12                	mov    (%edx),%edx
f0100fb7:	85 d2                	test   %edx,%edx
f0100fb9:	0f 85 61 fe ff ff    	jne    f0100e20 <check_page_free_list+0x165>
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100fbf:	85 ff                	test   %edi,%edi
f0100fc1:	7f 24                	jg     f0100fe7 <check_page_free_list+0x32c>
f0100fc3:	c7 44 24 0c 67 3a 10 	movl   $0xf0103a67,0xc(%esp)
f0100fca:	f0 
f0100fcb:	c7 44 24 08 fa 39 10 	movl   $0xf01039fa,0x8(%esp)
f0100fd2:	f0 
f0100fd3:	c7 44 24 04 fd 01 00 	movl   $0x1fd,0x4(%esp)
f0100fda:	00 
f0100fdb:	c7 04 24 d4 39 10 f0 	movl   $0xf01039d4,(%esp)
f0100fe2:	e8 ad f0 ff ff       	call   f0100094 <_panic>
	assert(nfree_extmem > 0);
f0100fe7:	85 f6                	test   %esi,%esi
f0100fe9:	7f 24                	jg     f010100f <check_page_free_list+0x354>
f0100feb:	c7 44 24 0c 79 3a 10 	movl   $0xf0103a79,0xc(%esp)
f0100ff2:	f0 
f0100ff3:	c7 44 24 08 fa 39 10 	movl   $0xf01039fa,0x8(%esp)
f0100ffa:	f0 
f0100ffb:	c7 44 24 04 fe 01 00 	movl   $0x1fe,0x4(%esp)
f0101002:	00 
f0101003:	c7 04 24 d4 39 10 f0 	movl   $0xf01039d4,(%esp)
f010100a:	e8 85 f0 ff ff       	call   f0100094 <_panic>
}
f010100f:	83 c4 3c             	add    $0x3c,%esp
f0101012:	5b                   	pop    %ebx
f0101013:	5e                   	pop    %esi
f0101014:	5f                   	pop    %edi
f0101015:	5d                   	pop    %ebp
f0101016:	c3                   	ret    

f0101017 <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0101017:	55                   	push   %ebp
f0101018:	89 e5                	mov    %esp,%ebp
f010101a:	56                   	push   %esi
f010101b:	53                   	push   %ebx
f010101c:	83 ec 10             	sub    $0x10,%esp
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	size_t low = IOPHYSMEM / PGSIZE;	
	size_t top = (PADDR(boot_alloc(0))) / PGSIZE;
f010101f:	b8 00 00 00 00       	mov    $0x0,%eax
f0101024:	e8 b3 fb ff ff       	call   f0100bdc <boot_alloc>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0101029:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010102e:	77 20                	ja     f0101050 <page_init+0x39>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101030:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101034:	c7 44 24 08 b8 36 10 	movl   $0xf01036b8,0x8(%esp)
f010103b:	f0 
f010103c:	c7 44 24 04 03 01 00 	movl   $0x103,0x4(%esp)
f0101043:	00 
f0101044:	c7 04 24 d4 39 10 f0 	movl   $0xf01039d4,(%esp)
f010104b:	e8 44 f0 ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0101050:	8d b0 00 00 00 10    	lea    0x10000000(%eax),%esi
f0101056:	c1 ee 0c             	shr    $0xc,%esi
//	cprintf("00");
	page_free_list = NULL;
f0101059:	c7 05 60 65 11 f0 00 	movl   $0x0,0xf0116560
f0101060:	00 00 00 
	for (i = 0; i < npages; i++) {
f0101063:	83 3d 84 69 11 f0 00 	cmpl   $0x0,0xf0116984
f010106a:	75 48                	jne    f01010b4 <page_init+0x9d>
f010106c:	eb 5e                	jmp    f01010cc <page_init+0xb5>
		pages[i].pp_ref = 0;
f010106e:	8d 0c d5 00 00 00 00 	lea    0x0(,%edx,8),%ecx
f0101075:	a1 8c 69 11 f0       	mov    0xf011698c,%eax
f010107a:	66 c7 44 08 04 00 00 	movw   $0x0,0x4(%eax,%ecx,1)
		if (i == 0) continue;
f0101081:	85 d2                	test   %edx,%edx
f0101083:	74 1c                	je     f01010a1 <page_init+0x8a>
		if (i >= low && i < top) continue; 
f0101085:	81 fa 9f 00 00 00    	cmp    $0x9f,%edx
f010108b:	76 04                	jbe    f0101091 <page_init+0x7a>
f010108d:	39 d6                	cmp    %edx,%esi
f010108f:	77 10                	ja     f01010a1 <page_init+0x8a>
	//	cprintf("%d\n", i);
		pages[i].pp_link = page_free_list;
f0101091:	a1 8c 69 11 f0       	mov    0xf011698c,%eax
f0101096:	89 1c 08             	mov    %ebx,(%eax,%ecx,1)
		page_free_list = &pages[i];
f0101099:	89 cb                	mov    %ecx,%ebx
f010109b:	03 1d 8c 69 11 f0    	add    0xf011698c,%ebx
	size_t i;
	size_t low = IOPHYSMEM / PGSIZE;	
	size_t top = (PADDR(boot_alloc(0))) / PGSIZE;
//	cprintf("00");
	page_free_list = NULL;
	for (i = 0; i < npages; i++) {
f01010a1:	83 c2 01             	add    $0x1,%edx
f01010a4:	39 15 84 69 11 f0    	cmp    %edx,0xf0116984
f01010aa:	77 c2                	ja     f010106e <page_init+0x57>
f01010ac:	89 1d 60 65 11 f0    	mov    %ebx,0xf0116560
f01010b2:	eb 18                	jmp    f01010cc <page_init+0xb5>
		pages[i].pp_ref = 0;
f01010b4:	a1 8c 69 11 f0       	mov    0xf011698c,%eax
f01010b9:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
f01010bf:	8b 1d 60 65 11 f0    	mov    0xf0116560,%ebx
	size_t i;
	size_t low = IOPHYSMEM / PGSIZE;	
	size_t top = (PADDR(boot_alloc(0))) / PGSIZE;
//	cprintf("00");
	page_free_list = NULL;
	for (i = 0; i < npages; i++) {
f01010c5:	ba 00 00 00 00       	mov    $0x0,%edx
f01010ca:	eb d5                	jmp    f01010a1 <page_init+0x8a>
		if (i >= low && i < top) continue; 
	//	cprintf("%d\n", i);
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
}
f01010cc:	83 c4 10             	add    $0x10,%esp
f01010cf:	5b                   	pop    %ebx
f01010d0:	5e                   	pop    %esi
f01010d1:	5d                   	pop    %ebp
f01010d2:	c3                   	ret    

f01010d3 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f01010d3:	55                   	push   %ebp
f01010d4:	89 e5                	mov    %esp,%ebp
f01010d6:	83 ec 18             	sub    $0x18,%esp
	// Fill this function in
	if (page_free_list != NULL) {
f01010d9:	a1 60 65 11 f0       	mov    0xf0116560,%eax
f01010de:	85 c0                	test   %eax,%eax
f01010e0:	74 6b                	je     f010114d <page_alloc+0x7a>
		if (alloc_flags & ALLOC_ZERO) {
f01010e2:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f01010e6:	74 56                	je     f010113e <page_alloc+0x6b>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01010e8:	2b 05 8c 69 11 f0    	sub    0xf011698c,%eax
f01010ee:	c1 f8 03             	sar    $0x3,%eax
f01010f1:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01010f4:	89 c2                	mov    %eax,%edx
f01010f6:	c1 ea 0c             	shr    $0xc,%edx
f01010f9:	3b 15 84 69 11 f0    	cmp    0xf0116984,%edx
f01010ff:	72 20                	jb     f0101121 <page_alloc+0x4e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101101:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101105:	c7 44 24 08 d0 35 10 	movl   $0xf01035d0,0x8(%esp)
f010110c:	f0 
f010110d:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0101114:	00 
f0101115:	c7 04 24 e0 39 10 f0 	movl   $0xf01039e0,(%esp)
f010111c:	e8 73 ef ff ff       	call   f0100094 <_panic>
//			cprintf("\n````!!!");
			memset(page2kva(page_free_list), 0, PGSIZE);
f0101121:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101128:	00 
f0101129:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101130:	00 
	return (void *)(pa + KERNBASE);
f0101131:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101136:	89 04 24             	mov    %eax,(%esp)
f0101139:	e8 d3 19 00 00       	call   f0102b11 <memset>
		}
		struct PageInfo* temp = page_free_list;
f010113e:	a1 60 65 11 f0       	mov    0xf0116560,%eax
		page_free_list = page_free_list->pp_link;
f0101143:	8b 10                	mov    (%eax),%edx
f0101145:	89 15 60 65 11 f0    	mov    %edx,0xf0116560
//		return (struct PageInfo*) page_free_list;
		return temp;
f010114b:	eb 05                	jmp    f0101152 <page_alloc+0x7f>
	}
	return 0;
f010114d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101152:	c9                   	leave  
f0101153:	c3                   	ret    

f0101154 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0101154:	55                   	push   %ebp
f0101155:	89 e5                	mov    %esp,%ebp
f0101157:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	pp->pp_link = page_free_list;
f010115a:	8b 15 60 65 11 f0    	mov    0xf0116560,%edx
f0101160:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f0101162:	a3 60 65 11 f0       	mov    %eax,0xf0116560
}
f0101167:	5d                   	pop    %ebp
f0101168:	c3                   	ret    

f0101169 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0101169:	55                   	push   %ebp
f010116a:	89 e5                	mov    %esp,%ebp
f010116c:	83 ec 04             	sub    $0x4,%esp
f010116f:	8b 45 08             	mov    0x8(%ebp),%eax
	if (--pp->pp_ref == 0)
f0101172:	0f b7 50 04          	movzwl 0x4(%eax),%edx
f0101176:	83 ea 01             	sub    $0x1,%edx
f0101179:	66 89 50 04          	mov    %dx,0x4(%eax)
f010117d:	66 85 d2             	test   %dx,%dx
f0101180:	75 08                	jne    f010118a <page_decref+0x21>
		page_free(pp);
f0101182:	89 04 24             	mov    %eax,(%esp)
f0101185:	e8 ca ff ff ff       	call   f0101154 <page_free>
}
f010118a:	c9                   	leave  
f010118b:	c3                   	ret    

f010118c <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f010118c:	55                   	push   %ebp
f010118d:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return NULL;
}
f010118f:	b8 00 00 00 00       	mov    $0x0,%eax
f0101194:	5d                   	pop    %ebp
f0101195:	c3                   	ret    

f0101196 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f0101196:	55                   	push   %ebp
f0101197:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return 0;
}
f0101199:	b8 00 00 00 00       	mov    $0x0,%eax
f010119e:	5d                   	pop    %ebp
f010119f:	c3                   	ret    

f01011a0 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f01011a0:	55                   	push   %ebp
f01011a1:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return NULL;
}
f01011a3:	b8 00 00 00 00       	mov    $0x0,%eax
f01011a8:	5d                   	pop    %ebp
f01011a9:	c3                   	ret    

f01011aa <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f01011aa:	55                   	push   %ebp
f01011ab:	89 e5                	mov    %esp,%ebp
f01011ad:	57                   	push   %edi
f01011ae:	56                   	push   %esi
f01011af:	53                   	push   %ebx
f01011b0:	83 ec 3c             	sub    $0x3c,%esp
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f01011b3:	b8 15 00 00 00       	mov    $0x15,%eax
f01011b8:	e8 cc fa ff ff       	call   f0100c89 <nvram_read>
f01011bd:	c1 e0 0a             	shl    $0xa,%eax
f01011c0:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f01011c6:	85 c0                	test   %eax,%eax
f01011c8:	0f 48 c2             	cmovs  %edx,%eax
f01011cb:	c1 f8 0c             	sar    $0xc,%eax
f01011ce:	a3 58 65 11 f0       	mov    %eax,0xf0116558
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f01011d3:	b8 17 00 00 00       	mov    $0x17,%eax
f01011d8:	e8 ac fa ff ff       	call   f0100c89 <nvram_read>
f01011dd:	c1 e0 0a             	shl    $0xa,%eax
f01011e0:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f01011e6:	85 c0                	test   %eax,%eax
f01011e8:	0f 48 c2             	cmovs  %edx,%eax
f01011eb:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f01011ee:	85 c0                	test   %eax,%eax
f01011f0:	74 0e                	je     f0101200 <mem_init+0x56>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f01011f2:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f01011f8:	89 15 84 69 11 f0    	mov    %edx,0xf0116984
f01011fe:	eb 0c                	jmp    f010120c <mem_init+0x62>
	else
		npages = npages_basemem;
f0101200:	8b 15 58 65 11 f0    	mov    0xf0116558,%edx
f0101206:	89 15 84 69 11 f0    	mov    %edx,0xf0116984

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
		npages_extmem * PGSIZE / 1024);
f010120c:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f010120f:	c1 e8 0a             	shr    $0xa,%eax
f0101212:	89 44 24 0c          	mov    %eax,0xc(%esp)
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
f0101216:	a1 58 65 11 f0       	mov    0xf0116558,%eax
f010121b:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f010121e:	c1 e8 0a             	shr    $0xa,%eax
f0101221:	89 44 24 08          	mov    %eax,0x8(%esp)
		npages * PGSIZE / 1024,
f0101225:	a1 84 69 11 f0       	mov    0xf0116984,%eax
f010122a:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f010122d:	c1 e8 0a             	shr    $0xa,%eax
f0101230:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101234:	c7 04 24 dc 36 10 f0 	movl   $0xf01036dc,(%esp)
f010123b:	e8 12 0d 00 00       	call   f0101f52 <cprintf>
	// Remove this line when you're ready to test this function.
//	panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0101240:	b8 00 10 00 00       	mov    $0x1000,%eax
f0101245:	e8 92 f9 ff ff       	call   f0100bdc <boot_alloc>
f010124a:	a3 88 69 11 f0       	mov    %eax,0xf0116988
	memset(kern_pgdir, 0, PGSIZE);
f010124f:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101256:	00 
f0101257:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010125e:	00 
f010125f:	89 04 24             	mov    %eax,(%esp)
f0101262:	e8 aa 18 00 00       	call   f0102b11 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0101267:	a1 88 69 11 f0       	mov    0xf0116988,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010126c:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101271:	77 20                	ja     f0101293 <mem_init+0xe9>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101273:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101277:	c7 44 24 08 b8 36 10 	movl   $0xf01036b8,0x8(%esp)
f010127e:	f0 
f010127f:	c7 44 24 04 91 00 00 	movl   $0x91,0x4(%esp)
f0101286:	00 
f0101287:	c7 04 24 d4 39 10 f0 	movl   $0xf01039d4,(%esp)
f010128e:	e8 01 ee ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0101293:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0101299:	83 ca 05             	or     $0x5,%edx
f010129c:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	cprintf("~~~");
f01012a2:	c7 04 24 8a 3a 10 f0 	movl   $0xf0103a8a,(%esp)
f01012a9:	e8 a4 0c 00 00       	call   f0101f52 <cprintf>
	// Allocate an array of npages 'struct PageInfo's and store it in 'pages'.
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.
	// Your code goes here:
	pages = (struct PageInfo*) boot_alloc(npages * sizeof(struct PageInfo));
f01012ae:	a1 84 69 11 f0       	mov    0xf0116984,%eax
f01012b3:	c1 e0 03             	shl    $0x3,%eax
f01012b6:	e8 21 f9 ff ff       	call   f0100bdc <boot_alloc>
f01012bb:	a3 8c 69 11 f0       	mov    %eax,0xf011698c
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f01012c0:	e8 52 fd ff ff       	call   f0101017 <page_init>
	cprintf("!!!");
f01012c5:	c7 04 24 8e 3a 10 f0 	movl   $0xf0103a8e,(%esp)
f01012cc:	e8 81 0c 00 00       	call   f0101f52 <cprintf>

	check_page_free_list(1);
f01012d1:	b8 01 00 00 00       	mov    $0x1,%eax
f01012d6:	e8 e0 f9 ff ff       	call   f0100cbb <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f01012db:	83 3d 8c 69 11 f0 00 	cmpl   $0x0,0xf011698c
f01012e2:	75 1c                	jne    f0101300 <mem_init+0x156>
		panic("'pages' is a null pointer!");
f01012e4:	c7 44 24 08 92 3a 10 	movl   $0xf0103a92,0x8(%esp)
f01012eb:	f0 
f01012ec:	c7 44 24 04 0f 02 00 	movl   $0x20f,0x4(%esp)
f01012f3:	00 
f01012f4:	c7 04 24 d4 39 10 f0 	movl   $0xf01039d4,(%esp)
f01012fb:	e8 94 ed ff ff       	call   f0100094 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101300:	a1 60 65 11 f0       	mov    0xf0116560,%eax
f0101305:	bb 00 00 00 00       	mov    $0x0,%ebx
f010130a:	85 c0                	test   %eax,%eax
f010130c:	74 09                	je     f0101317 <mem_init+0x16d>
		++nfree;
f010130e:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101311:	8b 00                	mov    (%eax),%eax
f0101313:	85 c0                	test   %eax,%eax
f0101315:	75 f7                	jne    f010130e <mem_init+0x164>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101317:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010131e:	e8 b0 fd ff ff       	call   f01010d3 <page_alloc>
f0101323:	89 c6                	mov    %eax,%esi
f0101325:	85 c0                	test   %eax,%eax
f0101327:	75 24                	jne    f010134d <mem_init+0x1a3>
f0101329:	c7 44 24 0c ad 3a 10 	movl   $0xf0103aad,0xc(%esp)
f0101330:	f0 
f0101331:	c7 44 24 08 fa 39 10 	movl   $0xf01039fa,0x8(%esp)
f0101338:	f0 
f0101339:	c7 44 24 04 17 02 00 	movl   $0x217,0x4(%esp)
f0101340:	00 
f0101341:	c7 04 24 d4 39 10 f0 	movl   $0xf01039d4,(%esp)
f0101348:	e8 47 ed ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f010134d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101354:	e8 7a fd ff ff       	call   f01010d3 <page_alloc>
f0101359:	89 c7                	mov    %eax,%edi
f010135b:	85 c0                	test   %eax,%eax
f010135d:	75 24                	jne    f0101383 <mem_init+0x1d9>
f010135f:	c7 44 24 0c c3 3a 10 	movl   $0xf0103ac3,0xc(%esp)
f0101366:	f0 
f0101367:	c7 44 24 08 fa 39 10 	movl   $0xf01039fa,0x8(%esp)
f010136e:	f0 
f010136f:	c7 44 24 04 18 02 00 	movl   $0x218,0x4(%esp)
f0101376:	00 
f0101377:	c7 04 24 d4 39 10 f0 	movl   $0xf01039d4,(%esp)
f010137e:	e8 11 ed ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0101383:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010138a:	e8 44 fd ff ff       	call   f01010d3 <page_alloc>
f010138f:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101392:	85 c0                	test   %eax,%eax
f0101394:	75 24                	jne    f01013ba <mem_init+0x210>
f0101396:	c7 44 24 0c d9 3a 10 	movl   $0xf0103ad9,0xc(%esp)
f010139d:	f0 
f010139e:	c7 44 24 08 fa 39 10 	movl   $0xf01039fa,0x8(%esp)
f01013a5:	f0 
f01013a6:	c7 44 24 04 19 02 00 	movl   $0x219,0x4(%esp)
f01013ad:	00 
f01013ae:	c7 04 24 d4 39 10 f0 	movl   $0xf01039d4,(%esp)
f01013b5:	e8 da ec ff ff       	call   f0100094 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01013ba:	39 fe                	cmp    %edi,%esi
f01013bc:	75 24                	jne    f01013e2 <mem_init+0x238>
f01013be:	c7 44 24 0c ef 3a 10 	movl   $0xf0103aef,0xc(%esp)
f01013c5:	f0 
f01013c6:	c7 44 24 08 fa 39 10 	movl   $0xf01039fa,0x8(%esp)
f01013cd:	f0 
f01013ce:	c7 44 24 04 1c 02 00 	movl   $0x21c,0x4(%esp)
f01013d5:	00 
f01013d6:	c7 04 24 d4 39 10 f0 	movl   $0xf01039d4,(%esp)
f01013dd:	e8 b2 ec ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01013e2:	3b 7d d4             	cmp    -0x2c(%ebp),%edi
f01013e5:	74 05                	je     f01013ec <mem_init+0x242>
f01013e7:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f01013ea:	75 24                	jne    f0101410 <mem_init+0x266>
f01013ec:	c7 44 24 0c 18 37 10 	movl   $0xf0103718,0xc(%esp)
f01013f3:	f0 
f01013f4:	c7 44 24 08 fa 39 10 	movl   $0xf01039fa,0x8(%esp)
f01013fb:	f0 
f01013fc:	c7 44 24 04 1d 02 00 	movl   $0x21d,0x4(%esp)
f0101403:	00 
f0101404:	c7 04 24 d4 39 10 f0 	movl   $0xf01039d4,(%esp)
f010140b:	e8 84 ec ff ff       	call   f0100094 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101410:	8b 15 8c 69 11 f0    	mov    0xf011698c,%edx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101416:	a1 84 69 11 f0       	mov    0xf0116984,%eax
f010141b:	c1 e0 0c             	shl    $0xc,%eax
f010141e:	89 f1                	mov    %esi,%ecx
f0101420:	29 d1                	sub    %edx,%ecx
f0101422:	c1 f9 03             	sar    $0x3,%ecx
f0101425:	c1 e1 0c             	shl    $0xc,%ecx
f0101428:	39 c1                	cmp    %eax,%ecx
f010142a:	72 24                	jb     f0101450 <mem_init+0x2a6>
f010142c:	c7 44 24 0c 01 3b 10 	movl   $0xf0103b01,0xc(%esp)
f0101433:	f0 
f0101434:	c7 44 24 08 fa 39 10 	movl   $0xf01039fa,0x8(%esp)
f010143b:	f0 
f010143c:	c7 44 24 04 1e 02 00 	movl   $0x21e,0x4(%esp)
f0101443:	00 
f0101444:	c7 04 24 d4 39 10 f0 	movl   $0xf01039d4,(%esp)
f010144b:	e8 44 ec ff ff       	call   f0100094 <_panic>
f0101450:	89 f9                	mov    %edi,%ecx
f0101452:	29 d1                	sub    %edx,%ecx
f0101454:	c1 f9 03             	sar    $0x3,%ecx
f0101457:	c1 e1 0c             	shl    $0xc,%ecx
	assert(page2pa(pp1) < npages*PGSIZE);
f010145a:	39 c8                	cmp    %ecx,%eax
f010145c:	77 24                	ja     f0101482 <mem_init+0x2d8>
f010145e:	c7 44 24 0c 1e 3b 10 	movl   $0xf0103b1e,0xc(%esp)
f0101465:	f0 
f0101466:	c7 44 24 08 fa 39 10 	movl   $0xf01039fa,0x8(%esp)
f010146d:	f0 
f010146e:	c7 44 24 04 1f 02 00 	movl   $0x21f,0x4(%esp)
f0101475:	00 
f0101476:	c7 04 24 d4 39 10 f0 	movl   $0xf01039d4,(%esp)
f010147d:	e8 12 ec ff ff       	call   f0100094 <_panic>
f0101482:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101485:	29 d1                	sub    %edx,%ecx
f0101487:	89 ca                	mov    %ecx,%edx
f0101489:	c1 fa 03             	sar    $0x3,%edx
f010148c:	c1 e2 0c             	shl    $0xc,%edx
	assert(page2pa(pp2) < npages*PGSIZE);
f010148f:	39 d0                	cmp    %edx,%eax
f0101491:	77 24                	ja     f01014b7 <mem_init+0x30d>
f0101493:	c7 44 24 0c 3b 3b 10 	movl   $0xf0103b3b,0xc(%esp)
f010149a:	f0 
f010149b:	c7 44 24 08 fa 39 10 	movl   $0xf01039fa,0x8(%esp)
f01014a2:	f0 
f01014a3:	c7 44 24 04 20 02 00 	movl   $0x220,0x4(%esp)
f01014aa:	00 
f01014ab:	c7 04 24 d4 39 10 f0 	movl   $0xf01039d4,(%esp)
f01014b2:	e8 dd eb ff ff       	call   f0100094 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01014b7:	a1 60 65 11 f0       	mov    0xf0116560,%eax
f01014bc:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f01014bf:	c7 05 60 65 11 f0 00 	movl   $0x0,0xf0116560
f01014c6:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01014c9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01014d0:	e8 fe fb ff ff       	call   f01010d3 <page_alloc>
f01014d5:	85 c0                	test   %eax,%eax
f01014d7:	74 24                	je     f01014fd <mem_init+0x353>
f01014d9:	c7 44 24 0c 58 3b 10 	movl   $0xf0103b58,0xc(%esp)
f01014e0:	f0 
f01014e1:	c7 44 24 08 fa 39 10 	movl   $0xf01039fa,0x8(%esp)
f01014e8:	f0 
f01014e9:	c7 44 24 04 27 02 00 	movl   $0x227,0x4(%esp)
f01014f0:	00 
f01014f1:	c7 04 24 d4 39 10 f0 	movl   $0xf01039d4,(%esp)
f01014f8:	e8 97 eb ff ff       	call   f0100094 <_panic>

	// free and re-allocate?
	page_free(pp0);
f01014fd:	89 34 24             	mov    %esi,(%esp)
f0101500:	e8 4f fc ff ff       	call   f0101154 <page_free>
	page_free(pp1);
f0101505:	89 3c 24             	mov    %edi,(%esp)
f0101508:	e8 47 fc ff ff       	call   f0101154 <page_free>
	page_free(pp2);
f010150d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101510:	89 04 24             	mov    %eax,(%esp)
f0101513:	e8 3c fc ff ff       	call   f0101154 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101518:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010151f:	e8 af fb ff ff       	call   f01010d3 <page_alloc>
f0101524:	89 c6                	mov    %eax,%esi
f0101526:	85 c0                	test   %eax,%eax
f0101528:	75 24                	jne    f010154e <mem_init+0x3a4>
f010152a:	c7 44 24 0c ad 3a 10 	movl   $0xf0103aad,0xc(%esp)
f0101531:	f0 
f0101532:	c7 44 24 08 fa 39 10 	movl   $0xf01039fa,0x8(%esp)
f0101539:	f0 
f010153a:	c7 44 24 04 2e 02 00 	movl   $0x22e,0x4(%esp)
f0101541:	00 
f0101542:	c7 04 24 d4 39 10 f0 	movl   $0xf01039d4,(%esp)
f0101549:	e8 46 eb ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f010154e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101555:	e8 79 fb ff ff       	call   f01010d3 <page_alloc>
f010155a:	89 c7                	mov    %eax,%edi
f010155c:	85 c0                	test   %eax,%eax
f010155e:	75 24                	jne    f0101584 <mem_init+0x3da>
f0101560:	c7 44 24 0c c3 3a 10 	movl   $0xf0103ac3,0xc(%esp)
f0101567:	f0 
f0101568:	c7 44 24 08 fa 39 10 	movl   $0xf01039fa,0x8(%esp)
f010156f:	f0 
f0101570:	c7 44 24 04 2f 02 00 	movl   $0x22f,0x4(%esp)
f0101577:	00 
f0101578:	c7 04 24 d4 39 10 f0 	movl   $0xf01039d4,(%esp)
f010157f:	e8 10 eb ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0101584:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010158b:	e8 43 fb ff ff       	call   f01010d3 <page_alloc>
f0101590:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101593:	85 c0                	test   %eax,%eax
f0101595:	75 24                	jne    f01015bb <mem_init+0x411>
f0101597:	c7 44 24 0c d9 3a 10 	movl   $0xf0103ad9,0xc(%esp)
f010159e:	f0 
f010159f:	c7 44 24 08 fa 39 10 	movl   $0xf01039fa,0x8(%esp)
f01015a6:	f0 
f01015a7:	c7 44 24 04 30 02 00 	movl   $0x230,0x4(%esp)
f01015ae:	00 
f01015af:	c7 04 24 d4 39 10 f0 	movl   $0xf01039d4,(%esp)
f01015b6:	e8 d9 ea ff ff       	call   f0100094 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f01015bb:	39 fe                	cmp    %edi,%esi
f01015bd:	75 24                	jne    f01015e3 <mem_init+0x439>
f01015bf:	c7 44 24 0c ef 3a 10 	movl   $0xf0103aef,0xc(%esp)
f01015c6:	f0 
f01015c7:	c7 44 24 08 fa 39 10 	movl   $0xf01039fa,0x8(%esp)
f01015ce:	f0 
f01015cf:	c7 44 24 04 32 02 00 	movl   $0x232,0x4(%esp)
f01015d6:	00 
f01015d7:	c7 04 24 d4 39 10 f0 	movl   $0xf01039d4,(%esp)
f01015de:	e8 b1 ea ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01015e3:	3b 7d d4             	cmp    -0x2c(%ebp),%edi
f01015e6:	74 05                	je     f01015ed <mem_init+0x443>
f01015e8:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f01015eb:	75 24                	jne    f0101611 <mem_init+0x467>
f01015ed:	c7 44 24 0c 18 37 10 	movl   $0xf0103718,0xc(%esp)
f01015f4:	f0 
f01015f5:	c7 44 24 08 fa 39 10 	movl   $0xf01039fa,0x8(%esp)
f01015fc:	f0 
f01015fd:	c7 44 24 04 33 02 00 	movl   $0x233,0x4(%esp)
f0101604:	00 
f0101605:	c7 04 24 d4 39 10 f0 	movl   $0xf01039d4,(%esp)
f010160c:	e8 83 ea ff ff       	call   f0100094 <_panic>
	assert(!page_alloc(0));
f0101611:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101618:	e8 b6 fa ff ff       	call   f01010d3 <page_alloc>
f010161d:	85 c0                	test   %eax,%eax
f010161f:	74 24                	je     f0101645 <mem_init+0x49b>
f0101621:	c7 44 24 0c 58 3b 10 	movl   $0xf0103b58,0xc(%esp)
f0101628:	f0 
f0101629:	c7 44 24 08 fa 39 10 	movl   $0xf01039fa,0x8(%esp)
f0101630:	f0 
f0101631:	c7 44 24 04 34 02 00 	movl   $0x234,0x4(%esp)
f0101638:	00 
f0101639:	c7 04 24 d4 39 10 f0 	movl   $0xf01039d4,(%esp)
f0101640:	e8 4f ea ff ff       	call   f0100094 <_panic>
f0101645:	89 f0                	mov    %esi,%eax
f0101647:	2b 05 8c 69 11 f0    	sub    0xf011698c,%eax
f010164d:	c1 f8 03             	sar    $0x3,%eax
f0101650:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101653:	89 c2                	mov    %eax,%edx
f0101655:	c1 ea 0c             	shr    $0xc,%edx
f0101658:	3b 15 84 69 11 f0    	cmp    0xf0116984,%edx
f010165e:	72 20                	jb     f0101680 <mem_init+0x4d6>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101660:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101664:	c7 44 24 08 d0 35 10 	movl   $0xf01035d0,0x8(%esp)
f010166b:	f0 
f010166c:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0101673:	00 
f0101674:	c7 04 24 e0 39 10 f0 	movl   $0xf01039e0,(%esp)
f010167b:	e8 14 ea ff ff       	call   f0100094 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f0101680:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101687:	00 
f0101688:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f010168f:	00 
	return (void *)(pa + KERNBASE);
f0101690:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101695:	89 04 24             	mov    %eax,(%esp)
f0101698:	e8 74 14 00 00       	call   f0102b11 <memset>
	page_free(pp0);
f010169d:	89 34 24             	mov    %esi,(%esp)
f01016a0:	e8 af fa ff ff       	call   f0101154 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f01016a5:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01016ac:	e8 22 fa ff ff       	call   f01010d3 <page_alloc>
f01016b1:	85 c0                	test   %eax,%eax
f01016b3:	75 24                	jne    f01016d9 <mem_init+0x52f>
f01016b5:	c7 44 24 0c 67 3b 10 	movl   $0xf0103b67,0xc(%esp)
f01016bc:	f0 
f01016bd:	c7 44 24 08 fa 39 10 	movl   $0xf01039fa,0x8(%esp)
f01016c4:	f0 
f01016c5:	c7 44 24 04 39 02 00 	movl   $0x239,0x4(%esp)
f01016cc:	00 
f01016cd:	c7 04 24 d4 39 10 f0 	movl   $0xf01039d4,(%esp)
f01016d4:	e8 bb e9 ff ff       	call   f0100094 <_panic>
	assert(pp && pp0 == pp);
f01016d9:	39 c6                	cmp    %eax,%esi
f01016db:	74 24                	je     f0101701 <mem_init+0x557>
f01016dd:	c7 44 24 0c 85 3b 10 	movl   $0xf0103b85,0xc(%esp)
f01016e4:	f0 
f01016e5:	c7 44 24 08 fa 39 10 	movl   $0xf01039fa,0x8(%esp)
f01016ec:	f0 
f01016ed:	c7 44 24 04 3a 02 00 	movl   $0x23a,0x4(%esp)
f01016f4:	00 
f01016f5:	c7 04 24 d4 39 10 f0 	movl   $0xf01039d4,(%esp)
f01016fc:	e8 93 e9 ff ff       	call   f0100094 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101701:	89 f2                	mov    %esi,%edx
f0101703:	2b 15 8c 69 11 f0    	sub    0xf011698c,%edx
f0101709:	c1 fa 03             	sar    $0x3,%edx
f010170c:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010170f:	89 d0                	mov    %edx,%eax
f0101711:	c1 e8 0c             	shr    $0xc,%eax
f0101714:	3b 05 84 69 11 f0    	cmp    0xf0116984,%eax
f010171a:	72 20                	jb     f010173c <mem_init+0x592>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010171c:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101720:	c7 44 24 08 d0 35 10 	movl   $0xf01035d0,0x8(%esp)
f0101727:	f0 
f0101728:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f010172f:	00 
f0101730:	c7 04 24 e0 39 10 f0 	movl   $0xf01039e0,(%esp)
f0101737:	e8 58 e9 ff ff       	call   f0100094 <_panic>
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++) 
		assert(c[i] == 0);
f010173c:	80 ba 00 00 00 f0 00 	cmpb   $0x0,-0x10000000(%edx)
f0101743:	75 11                	jne    f0101756 <mem_init+0x5ac>
f0101745:	8d 82 01 00 00 f0    	lea    -0xfffffff(%edx),%eax
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f010174b:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++) 
		assert(c[i] == 0);
f0101751:	80 38 00             	cmpb   $0x0,(%eax)
f0101754:	74 24                	je     f010177a <mem_init+0x5d0>
f0101756:	c7 44 24 0c 95 3b 10 	movl   $0xf0103b95,0xc(%esp)
f010175d:	f0 
f010175e:	c7 44 24 08 fa 39 10 	movl   $0xf01039fa,0x8(%esp)
f0101765:	f0 
f0101766:	c7 44 24 04 3d 02 00 	movl   $0x23d,0x4(%esp)
f010176d:	00 
f010176e:	c7 04 24 d4 39 10 f0 	movl   $0xf01039d4,(%esp)
f0101775:	e8 1a e9 ff ff       	call   f0100094 <_panic>
f010177a:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++) 
f010177d:	39 d0                	cmp    %edx,%eax
f010177f:	75 d0                	jne    f0101751 <mem_init+0x5a7>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101781:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0101784:	89 0d 60 65 11 f0    	mov    %ecx,0xf0116560

	// free the pages we took
	page_free(pp0);
f010178a:	89 34 24             	mov    %esi,(%esp)
f010178d:	e8 c2 f9 ff ff       	call   f0101154 <page_free>
	page_free(pp1);
f0101792:	89 3c 24             	mov    %edi,(%esp)
f0101795:	e8 ba f9 ff ff       	call   f0101154 <page_free>
	page_free(pp2);
f010179a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010179d:	89 04 24             	mov    %eax,(%esp)
f01017a0:	e8 af f9 ff ff       	call   f0101154 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01017a5:	a1 60 65 11 f0       	mov    0xf0116560,%eax
f01017aa:	85 c0                	test   %eax,%eax
f01017ac:	74 09                	je     f01017b7 <mem_init+0x60d>
		--nfree;
f01017ae:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01017b1:	8b 00                	mov    (%eax),%eax
f01017b3:	85 c0                	test   %eax,%eax
f01017b5:	75 f7                	jne    f01017ae <mem_init+0x604>
		--nfree;
	assert(nfree == 0);
f01017b7:	85 db                	test   %ebx,%ebx
f01017b9:	74 24                	je     f01017df <mem_init+0x635>
f01017bb:	c7 44 24 0c 9f 3b 10 	movl   $0xf0103b9f,0xc(%esp)
f01017c2:	f0 
f01017c3:	c7 44 24 08 fa 39 10 	movl   $0xf01039fa,0x8(%esp)
f01017ca:	f0 
f01017cb:	c7 44 24 04 4a 02 00 	movl   $0x24a,0x4(%esp)
f01017d2:	00 
f01017d3:	c7 04 24 d4 39 10 f0 	movl   $0xf01039d4,(%esp)
f01017da:	e8 b5 e8 ff ff       	call   f0100094 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f01017df:	c7 04 24 38 37 10 f0 	movl   $0xf0103738,(%esp)
f01017e6:	e8 67 07 00 00       	call   f0101f52 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01017eb:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01017f2:	e8 dc f8 ff ff       	call   f01010d3 <page_alloc>
f01017f7:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01017fa:	85 c0                	test   %eax,%eax
f01017fc:	75 24                	jne    f0101822 <mem_init+0x678>
f01017fe:	c7 44 24 0c ad 3a 10 	movl   $0xf0103aad,0xc(%esp)
f0101805:	f0 
f0101806:	c7 44 24 08 fa 39 10 	movl   $0xf01039fa,0x8(%esp)
f010180d:	f0 
f010180e:	c7 44 24 04 a3 02 00 	movl   $0x2a3,0x4(%esp)
f0101815:	00 
f0101816:	c7 04 24 d4 39 10 f0 	movl   $0xf01039d4,(%esp)
f010181d:	e8 72 e8 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f0101822:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101829:	e8 a5 f8 ff ff       	call   f01010d3 <page_alloc>
f010182e:	89 c6                	mov    %eax,%esi
f0101830:	85 c0                	test   %eax,%eax
f0101832:	75 24                	jne    f0101858 <mem_init+0x6ae>
f0101834:	c7 44 24 0c c3 3a 10 	movl   $0xf0103ac3,0xc(%esp)
f010183b:	f0 
f010183c:	c7 44 24 08 fa 39 10 	movl   $0xf01039fa,0x8(%esp)
f0101843:	f0 
f0101844:	c7 44 24 04 a4 02 00 	movl   $0x2a4,0x4(%esp)
f010184b:	00 
f010184c:	c7 04 24 d4 39 10 f0 	movl   $0xf01039d4,(%esp)
f0101853:	e8 3c e8 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0101858:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010185f:	e8 6f f8 ff ff       	call   f01010d3 <page_alloc>
f0101864:	89 c3                	mov    %eax,%ebx
f0101866:	85 c0                	test   %eax,%eax
f0101868:	75 24                	jne    f010188e <mem_init+0x6e4>
f010186a:	c7 44 24 0c d9 3a 10 	movl   $0xf0103ad9,0xc(%esp)
f0101871:	f0 
f0101872:	c7 44 24 08 fa 39 10 	movl   $0xf01039fa,0x8(%esp)
f0101879:	f0 
f010187a:	c7 44 24 04 a5 02 00 	movl   $0x2a5,0x4(%esp)
f0101881:	00 
f0101882:	c7 04 24 d4 39 10 f0 	movl   $0xf01039d4,(%esp)
f0101889:	e8 06 e8 ff ff       	call   f0100094 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010188e:	39 75 d4             	cmp    %esi,-0x2c(%ebp)
f0101891:	75 24                	jne    f01018b7 <mem_init+0x70d>
f0101893:	c7 44 24 0c ef 3a 10 	movl   $0xf0103aef,0xc(%esp)
f010189a:	f0 
f010189b:	c7 44 24 08 fa 39 10 	movl   $0xf01039fa,0x8(%esp)
f01018a2:	f0 
f01018a3:	c7 44 24 04 a8 02 00 	movl   $0x2a8,0x4(%esp)
f01018aa:	00 
f01018ab:	c7 04 24 d4 39 10 f0 	movl   $0xf01039d4,(%esp)
f01018b2:	e8 dd e7 ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01018b7:	39 c6                	cmp    %eax,%esi
f01018b9:	74 05                	je     f01018c0 <mem_init+0x716>
f01018bb:	39 45 d4             	cmp    %eax,-0x2c(%ebp)
f01018be:	75 24                	jne    f01018e4 <mem_init+0x73a>
f01018c0:	c7 44 24 0c 18 37 10 	movl   $0xf0103718,0xc(%esp)
f01018c7:	f0 
f01018c8:	c7 44 24 08 fa 39 10 	movl   $0xf01039fa,0x8(%esp)
f01018cf:	f0 
f01018d0:	c7 44 24 04 a9 02 00 	movl   $0x2a9,0x4(%esp)
f01018d7:	00 
f01018d8:	c7 04 24 d4 39 10 f0 	movl   $0xf01039d4,(%esp)
f01018df:	e8 b0 e7 ff ff       	call   f0100094 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
	page_free_list = 0;
f01018e4:	c7 05 60 65 11 f0 00 	movl   $0x0,0xf0116560
f01018eb:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01018ee:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01018f5:	e8 d9 f7 ff ff       	call   f01010d3 <page_alloc>
f01018fa:	85 c0                	test   %eax,%eax
f01018fc:	74 24                	je     f0101922 <mem_init+0x778>
f01018fe:	c7 44 24 0c 58 3b 10 	movl   $0xf0103b58,0xc(%esp)
f0101905:	f0 
f0101906:	c7 44 24 08 fa 39 10 	movl   $0xf01039fa,0x8(%esp)
f010190d:	f0 
f010190e:	c7 44 24 04 b0 02 00 	movl   $0x2b0,0x4(%esp)
f0101915:	00 
f0101916:	c7 04 24 d4 39 10 f0 	movl   $0xf01039d4,(%esp)
f010191d:	e8 72 e7 ff ff       	call   f0100094 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101922:	8b 3d 88 69 11 f0    	mov    0xf0116988,%edi
f0101928:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010192b:	89 44 24 08          	mov    %eax,0x8(%esp)
f010192f:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101936:	00 
f0101937:	89 3c 24             	mov    %edi,(%esp)
f010193a:	e8 61 f8 ff ff       	call   f01011a0 <page_lookup>
f010193f:	85 c0                	test   %eax,%eax
f0101941:	74 24                	je     f0101967 <mem_init+0x7bd>
f0101943:	c7 44 24 0c 58 37 10 	movl   $0xf0103758,0xc(%esp)
f010194a:	f0 
f010194b:	c7 44 24 08 fa 39 10 	movl   $0xf01039fa,0x8(%esp)
f0101952:	f0 
f0101953:	c7 44 24 04 b3 02 00 	movl   $0x2b3,0x4(%esp)
f010195a:	00 
f010195b:	c7 04 24 d4 39 10 f0 	movl   $0xf01039d4,(%esp)
f0101962:	e8 2d e7 ff ff       	call   f0100094 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101967:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f010196e:	00 
f010196f:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101976:	00 
f0101977:	89 74 24 04          	mov    %esi,0x4(%esp)
f010197b:	89 3c 24             	mov    %edi,(%esp)
f010197e:	e8 13 f8 ff ff       	call   f0101196 <page_insert>
f0101983:	85 c0                	test   %eax,%eax
f0101985:	78 24                	js     f01019ab <mem_init+0x801>
f0101987:	c7 44 24 0c 90 37 10 	movl   $0xf0103790,0xc(%esp)
f010198e:	f0 
f010198f:	c7 44 24 08 fa 39 10 	movl   $0xf01039fa,0x8(%esp)
f0101996:	f0 
f0101997:	c7 44 24 04 b6 02 00 	movl   $0x2b6,0x4(%esp)
f010199e:	00 
f010199f:	c7 04 24 d4 39 10 f0 	movl   $0xf01039d4,(%esp)
f01019a6:	e8 e9 e6 ff ff       	call   f0100094 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f01019ab:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01019ae:	89 04 24             	mov    %eax,(%esp)
f01019b1:	e8 9e f7 ff ff       	call   f0101154 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f01019b6:	8b 3d 88 69 11 f0    	mov    0xf0116988,%edi
f01019bc:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01019c3:	00 
f01019c4:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01019cb:	00 
f01019cc:	89 74 24 04          	mov    %esi,0x4(%esp)
f01019d0:	89 3c 24             	mov    %edi,(%esp)
f01019d3:	e8 be f7 ff ff       	call   f0101196 <page_insert>
f01019d8:	85 c0                	test   %eax,%eax
f01019da:	74 24                	je     f0101a00 <mem_init+0x856>
f01019dc:	c7 44 24 0c c0 37 10 	movl   $0xf01037c0,0xc(%esp)
f01019e3:	f0 
f01019e4:	c7 44 24 08 fa 39 10 	movl   $0xf01039fa,0x8(%esp)
f01019eb:	f0 
f01019ec:	c7 44 24 04 ba 02 00 	movl   $0x2ba,0x4(%esp)
f01019f3:	00 
f01019f4:	c7 04 24 d4 39 10 f0 	movl   $0xf01039d4,(%esp)
f01019fb:	e8 94 e6 ff ff       	call   f0100094 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101a00:	8b 0d 8c 69 11 f0    	mov    0xf011698c,%ecx
f0101a06:	89 4d d0             	mov    %ecx,-0x30(%ebp)
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101a09:	8b 17                	mov    (%edi),%edx
f0101a0b:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101a11:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a14:	29 c8                	sub    %ecx,%eax
f0101a16:	c1 f8 03             	sar    $0x3,%eax
f0101a19:	c1 e0 0c             	shl    $0xc,%eax
f0101a1c:	39 c2                	cmp    %eax,%edx
f0101a1e:	74 24                	je     f0101a44 <mem_init+0x89a>
f0101a20:	c7 44 24 0c f0 37 10 	movl   $0xf01037f0,0xc(%esp)
f0101a27:	f0 
f0101a28:	c7 44 24 08 fa 39 10 	movl   $0xf01039fa,0x8(%esp)
f0101a2f:	f0 
f0101a30:	c7 44 24 04 bb 02 00 	movl   $0x2bb,0x4(%esp)
f0101a37:	00 
f0101a38:	c7 04 24 d4 39 10 f0 	movl   $0xf01039d4,(%esp)
f0101a3f:	e8 50 e6 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101a44:	ba 00 00 00 00       	mov    $0x0,%edx
f0101a49:	89 f8                	mov    %edi,%eax
f0101a4b:	e8 c8 f1 ff ff       	call   f0100c18 <check_va2pa>
f0101a50:	89 f2                	mov    %esi,%edx
f0101a52:	2b 55 d0             	sub    -0x30(%ebp),%edx
f0101a55:	c1 fa 03             	sar    $0x3,%edx
f0101a58:	c1 e2 0c             	shl    $0xc,%edx
f0101a5b:	39 d0                	cmp    %edx,%eax
f0101a5d:	74 24                	je     f0101a83 <mem_init+0x8d9>
f0101a5f:	c7 44 24 0c 18 38 10 	movl   $0xf0103818,0xc(%esp)
f0101a66:	f0 
f0101a67:	c7 44 24 08 fa 39 10 	movl   $0xf01039fa,0x8(%esp)
f0101a6e:	f0 
f0101a6f:	c7 44 24 04 bc 02 00 	movl   $0x2bc,0x4(%esp)
f0101a76:	00 
f0101a77:	c7 04 24 d4 39 10 f0 	movl   $0xf01039d4,(%esp)
f0101a7e:	e8 11 e6 ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 1);
f0101a83:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101a88:	74 24                	je     f0101aae <mem_init+0x904>
f0101a8a:	c7 44 24 0c aa 3b 10 	movl   $0xf0103baa,0xc(%esp)
f0101a91:	f0 
f0101a92:	c7 44 24 08 fa 39 10 	movl   $0xf01039fa,0x8(%esp)
f0101a99:	f0 
f0101a9a:	c7 44 24 04 bd 02 00 	movl   $0x2bd,0x4(%esp)
f0101aa1:	00 
f0101aa2:	c7 04 24 d4 39 10 f0 	movl   $0xf01039d4,(%esp)
f0101aa9:	e8 e6 e5 ff ff       	call   f0100094 <_panic>
	assert(pp0->pp_ref == 1);
f0101aae:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101ab1:	66 83 78 04 01       	cmpw   $0x1,0x4(%eax)
f0101ab6:	74 24                	je     f0101adc <mem_init+0x932>
f0101ab8:	c7 44 24 0c bb 3b 10 	movl   $0xf0103bbb,0xc(%esp)
f0101abf:	f0 
f0101ac0:	c7 44 24 08 fa 39 10 	movl   $0xf01039fa,0x8(%esp)
f0101ac7:	f0 
f0101ac8:	c7 44 24 04 be 02 00 	movl   $0x2be,0x4(%esp)
f0101acf:	00 
f0101ad0:	c7 04 24 d4 39 10 f0 	movl   $0xf01039d4,(%esp)
f0101ad7:	e8 b8 e5 ff ff       	call   f0100094 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101adc:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101ae3:	00 
f0101ae4:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101aeb:	00 
f0101aec:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101af0:	89 3c 24             	mov    %edi,(%esp)
f0101af3:	e8 9e f6 ff ff       	call   f0101196 <page_insert>
f0101af8:	85 c0                	test   %eax,%eax
f0101afa:	74 24                	je     f0101b20 <mem_init+0x976>
f0101afc:	c7 44 24 0c 48 38 10 	movl   $0xf0103848,0xc(%esp)
f0101b03:	f0 
f0101b04:	c7 44 24 08 fa 39 10 	movl   $0xf01039fa,0x8(%esp)
f0101b0b:	f0 
f0101b0c:	c7 44 24 04 c1 02 00 	movl   $0x2c1,0x4(%esp)
f0101b13:	00 
f0101b14:	c7 04 24 d4 39 10 f0 	movl   $0xf01039d4,(%esp)
f0101b1b:	e8 74 e5 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101b20:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101b25:	89 f8                	mov    %edi,%eax
f0101b27:	e8 ec f0 ff ff       	call   f0100c18 <check_va2pa>
f0101b2c:	89 da                	mov    %ebx,%edx
f0101b2e:	2b 55 d0             	sub    -0x30(%ebp),%edx
f0101b31:	c1 fa 03             	sar    $0x3,%edx
f0101b34:	c1 e2 0c             	shl    $0xc,%edx
f0101b37:	39 d0                	cmp    %edx,%eax
f0101b39:	74 24                	je     f0101b5f <mem_init+0x9b5>
f0101b3b:	c7 44 24 0c 84 38 10 	movl   $0xf0103884,0xc(%esp)
f0101b42:	f0 
f0101b43:	c7 44 24 08 fa 39 10 	movl   $0xf01039fa,0x8(%esp)
f0101b4a:	f0 
f0101b4b:	c7 44 24 04 c2 02 00 	movl   $0x2c2,0x4(%esp)
f0101b52:	00 
f0101b53:	c7 04 24 d4 39 10 f0 	movl   $0xf01039d4,(%esp)
f0101b5a:	e8 35 e5 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101b5f:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101b64:	74 24                	je     f0101b8a <mem_init+0x9e0>
f0101b66:	c7 44 24 0c cc 3b 10 	movl   $0xf0103bcc,0xc(%esp)
f0101b6d:	f0 
f0101b6e:	c7 44 24 08 fa 39 10 	movl   $0xf01039fa,0x8(%esp)
f0101b75:	f0 
f0101b76:	c7 44 24 04 c3 02 00 	movl   $0x2c3,0x4(%esp)
f0101b7d:	00 
f0101b7e:	c7 04 24 d4 39 10 f0 	movl   $0xf01039d4,(%esp)
f0101b85:	e8 0a e5 ff ff       	call   f0100094 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101b8a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101b91:	e8 3d f5 ff ff       	call   f01010d3 <page_alloc>
f0101b96:	85 c0                	test   %eax,%eax
f0101b98:	74 24                	je     f0101bbe <mem_init+0xa14>
f0101b9a:	c7 44 24 0c 58 3b 10 	movl   $0xf0103b58,0xc(%esp)
f0101ba1:	f0 
f0101ba2:	c7 44 24 08 fa 39 10 	movl   $0xf01039fa,0x8(%esp)
f0101ba9:	f0 
f0101baa:	c7 44 24 04 c6 02 00 	movl   $0x2c6,0x4(%esp)
f0101bb1:	00 
f0101bb2:	c7 04 24 d4 39 10 f0 	movl   $0xf01039d4,(%esp)
f0101bb9:	e8 d6 e4 ff ff       	call   f0100094 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101bbe:	8b 35 88 69 11 f0    	mov    0xf0116988,%esi
f0101bc4:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101bcb:	00 
f0101bcc:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101bd3:	00 
f0101bd4:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101bd8:	89 34 24             	mov    %esi,(%esp)
f0101bdb:	e8 b6 f5 ff ff       	call   f0101196 <page_insert>
f0101be0:	85 c0                	test   %eax,%eax
f0101be2:	74 24                	je     f0101c08 <mem_init+0xa5e>
f0101be4:	c7 44 24 0c 48 38 10 	movl   $0xf0103848,0xc(%esp)
f0101beb:	f0 
f0101bec:	c7 44 24 08 fa 39 10 	movl   $0xf01039fa,0x8(%esp)
f0101bf3:	f0 
f0101bf4:	c7 44 24 04 c9 02 00 	movl   $0x2c9,0x4(%esp)
f0101bfb:	00 
f0101bfc:	c7 04 24 d4 39 10 f0 	movl   $0xf01039d4,(%esp)
f0101c03:	e8 8c e4 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101c08:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101c0d:	89 f0                	mov    %esi,%eax
f0101c0f:	e8 04 f0 ff ff       	call   f0100c18 <check_va2pa>
f0101c14:	89 da                	mov    %ebx,%edx
f0101c16:	2b 15 8c 69 11 f0    	sub    0xf011698c,%edx
f0101c1c:	c1 fa 03             	sar    $0x3,%edx
f0101c1f:	c1 e2 0c             	shl    $0xc,%edx
f0101c22:	39 d0                	cmp    %edx,%eax
f0101c24:	74 24                	je     f0101c4a <mem_init+0xaa0>
f0101c26:	c7 44 24 0c 84 38 10 	movl   $0xf0103884,0xc(%esp)
f0101c2d:	f0 
f0101c2e:	c7 44 24 08 fa 39 10 	movl   $0xf01039fa,0x8(%esp)
f0101c35:	f0 
f0101c36:	c7 44 24 04 ca 02 00 	movl   $0x2ca,0x4(%esp)
f0101c3d:	00 
f0101c3e:	c7 04 24 d4 39 10 f0 	movl   $0xf01039d4,(%esp)
f0101c45:	e8 4a e4 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101c4a:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101c4f:	74 24                	je     f0101c75 <mem_init+0xacb>
f0101c51:	c7 44 24 0c cc 3b 10 	movl   $0xf0103bcc,0xc(%esp)
f0101c58:	f0 
f0101c59:	c7 44 24 08 fa 39 10 	movl   $0xf01039fa,0x8(%esp)
f0101c60:	f0 
f0101c61:	c7 44 24 04 cb 02 00 	movl   $0x2cb,0x4(%esp)
f0101c68:	00 
f0101c69:	c7 04 24 d4 39 10 f0 	movl   $0xf01039d4,(%esp)
f0101c70:	e8 1f e4 ff ff       	call   f0100094 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101c75:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101c7c:	e8 52 f4 ff ff       	call   f01010d3 <page_alloc>
f0101c81:	85 c0                	test   %eax,%eax
f0101c83:	74 24                	je     f0101ca9 <mem_init+0xaff>
f0101c85:	c7 44 24 0c 58 3b 10 	movl   $0xf0103b58,0xc(%esp)
f0101c8c:	f0 
f0101c8d:	c7 44 24 08 fa 39 10 	movl   $0xf01039fa,0x8(%esp)
f0101c94:	f0 
f0101c95:	c7 44 24 04 cf 02 00 	movl   $0x2cf,0x4(%esp)
f0101c9c:	00 
f0101c9d:	c7 04 24 d4 39 10 f0 	movl   $0xf01039d4,(%esp)
f0101ca4:	e8 eb e3 ff ff       	call   f0100094 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101ca9:	8b 35 88 69 11 f0    	mov    0xf0116988,%esi
f0101caf:	8b 0e                	mov    (%esi),%ecx
f0101cb1:	89 4d d0             	mov    %ecx,-0x30(%ebp)
f0101cb4:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0101cba:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101cbd:	89 c8                	mov    %ecx,%eax
f0101cbf:	c1 e8 0c             	shr    $0xc,%eax
f0101cc2:	3b 05 84 69 11 f0    	cmp    0xf0116984,%eax
f0101cc8:	72 20                	jb     f0101cea <mem_init+0xb40>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101cca:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0101cce:	c7 44 24 08 d0 35 10 	movl   $0xf01035d0,0x8(%esp)
f0101cd5:	f0 
f0101cd6:	c7 44 24 04 d2 02 00 	movl   $0x2d2,0x4(%esp)
f0101cdd:	00 
f0101cde:	c7 04 24 d4 39 10 f0 	movl   $0xf01039d4,(%esp)
f0101ce5:	e8 aa e3 ff ff       	call   f0100094 <_panic>
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101cea:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101cf1:	00 
f0101cf2:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101cf9:	00 
f0101cfa:	89 34 24             	mov    %esi,(%esp)
f0101cfd:	e8 8a f4 ff ff       	call   f010118c <pgdir_walk>
f0101d02:	89 c7                	mov    %eax,%edi
f0101d04:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101d07:	2d fc ff ff 0f       	sub    $0xffffffc,%eax
f0101d0c:	39 c7                	cmp    %eax,%edi
f0101d0e:	74 24                	je     f0101d34 <mem_init+0xb8a>
f0101d10:	c7 44 24 0c b4 38 10 	movl   $0xf01038b4,0xc(%esp)
f0101d17:	f0 
f0101d18:	c7 44 24 08 fa 39 10 	movl   $0xf01039fa,0x8(%esp)
f0101d1f:	f0 
f0101d20:	c7 44 24 04 d3 02 00 	movl   $0x2d3,0x4(%esp)
f0101d27:	00 
f0101d28:	c7 04 24 d4 39 10 f0 	movl   $0xf01039d4,(%esp)
f0101d2f:	e8 60 e3 ff ff       	call   f0100094 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101d34:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f0101d3b:	00 
f0101d3c:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101d43:	00 
f0101d44:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101d48:	89 34 24             	mov    %esi,(%esp)
f0101d4b:	e8 46 f4 ff ff       	call   f0101196 <page_insert>
f0101d50:	85 c0                	test   %eax,%eax
f0101d52:	74 24                	je     f0101d78 <mem_init+0xbce>
f0101d54:	c7 44 24 0c f4 38 10 	movl   $0xf01038f4,0xc(%esp)
f0101d5b:	f0 
f0101d5c:	c7 44 24 08 fa 39 10 	movl   $0xf01039fa,0x8(%esp)
f0101d63:	f0 
f0101d64:	c7 44 24 04 d6 02 00 	movl   $0x2d6,0x4(%esp)
f0101d6b:	00 
f0101d6c:	c7 04 24 d4 39 10 f0 	movl   $0xf01039d4,(%esp)
f0101d73:	e8 1c e3 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101d78:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101d7d:	89 f0                	mov    %esi,%eax
f0101d7f:	e8 94 ee ff ff       	call   f0100c18 <check_va2pa>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101d84:	89 da                	mov    %ebx,%edx
f0101d86:	2b 15 8c 69 11 f0    	sub    0xf011698c,%edx
f0101d8c:	c1 fa 03             	sar    $0x3,%edx
f0101d8f:	c1 e2 0c             	shl    $0xc,%edx
f0101d92:	39 d0                	cmp    %edx,%eax
f0101d94:	74 24                	je     f0101dba <mem_init+0xc10>
f0101d96:	c7 44 24 0c 84 38 10 	movl   $0xf0103884,0xc(%esp)
f0101d9d:	f0 
f0101d9e:	c7 44 24 08 fa 39 10 	movl   $0xf01039fa,0x8(%esp)
f0101da5:	f0 
f0101da6:	c7 44 24 04 d7 02 00 	movl   $0x2d7,0x4(%esp)
f0101dad:	00 
f0101dae:	c7 04 24 d4 39 10 f0 	movl   $0xf01039d4,(%esp)
f0101db5:	e8 da e2 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101dba:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101dbf:	74 24                	je     f0101de5 <mem_init+0xc3b>
f0101dc1:	c7 44 24 0c cc 3b 10 	movl   $0xf0103bcc,0xc(%esp)
f0101dc8:	f0 
f0101dc9:	c7 44 24 08 fa 39 10 	movl   $0xf01039fa,0x8(%esp)
f0101dd0:	f0 
f0101dd1:	c7 44 24 04 d8 02 00 	movl   $0x2d8,0x4(%esp)
f0101dd8:	00 
f0101dd9:	c7 04 24 d4 39 10 f0 	movl   $0xf01039d4,(%esp)
f0101de0:	e8 af e2 ff ff       	call   f0100094 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0101de5:	8b 3f                	mov    (%edi),%edi
f0101de7:	f7 c7 04 00 00 00    	test   $0x4,%edi
f0101ded:	75 24                	jne    f0101e13 <mem_init+0xc69>
f0101def:	c7 44 24 0c 34 39 10 	movl   $0xf0103934,0xc(%esp)
f0101df6:	f0 
f0101df7:	c7 44 24 08 fa 39 10 	movl   $0xf01039fa,0x8(%esp)
f0101dfe:	f0 
f0101dff:	c7 44 24 04 d9 02 00 	movl   $0x2d9,0x4(%esp)
f0101e06:	00 
f0101e07:	c7 04 24 d4 39 10 f0 	movl   $0xf01039d4,(%esp)
f0101e0e:	e8 81 e2 ff ff       	call   f0100094 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0101e13:	f6 45 d0 04          	testb  $0x4,-0x30(%ebp)
f0101e17:	75 24                	jne    f0101e3d <mem_init+0xc93>
f0101e19:	c7 44 24 0c dd 3b 10 	movl   $0xf0103bdd,0xc(%esp)
f0101e20:	f0 
f0101e21:	c7 44 24 08 fa 39 10 	movl   $0xf01039fa,0x8(%esp)
f0101e28:	f0 
f0101e29:	c7 44 24 04 da 02 00 	movl   $0x2da,0x4(%esp)
f0101e30:	00 
f0101e31:	c7 04 24 d4 39 10 f0 	movl   $0xf01039d4,(%esp)
f0101e38:	e8 57 e2 ff ff       	call   f0100094 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101e3d:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101e44:	00 
f0101e45:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101e4c:	00 
f0101e4d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101e51:	89 34 24             	mov    %esi,(%esp)
f0101e54:	e8 3d f3 ff ff       	call   f0101196 <page_insert>
f0101e59:	85 c0                	test   %eax,%eax
f0101e5b:	74 24                	je     f0101e81 <mem_init+0xcd7>
f0101e5d:	c7 44 24 0c 48 38 10 	movl   $0xf0103848,0xc(%esp)
f0101e64:	f0 
f0101e65:	c7 44 24 08 fa 39 10 	movl   $0xf01039fa,0x8(%esp)
f0101e6c:	f0 
f0101e6d:	c7 44 24 04 dd 02 00 	movl   $0x2dd,0x4(%esp)
f0101e74:	00 
f0101e75:	c7 04 24 d4 39 10 f0 	movl   $0xf01039d4,(%esp)
f0101e7c:	e8 13 e2 ff ff       	call   f0100094 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0101e81:	f7 c7 02 00 00 00    	test   $0x2,%edi
f0101e87:	75 24                	jne    f0101ead <mem_init+0xd03>
f0101e89:	c7 44 24 0c 68 39 10 	movl   $0xf0103968,0xc(%esp)
f0101e90:	f0 
f0101e91:	c7 44 24 08 fa 39 10 	movl   $0xf01039fa,0x8(%esp)
f0101e98:	f0 
f0101e99:	c7 44 24 04 de 02 00 	movl   $0x2de,0x4(%esp)
f0101ea0:	00 
f0101ea1:	c7 04 24 d4 39 10 f0 	movl   $0xf01039d4,(%esp)
f0101ea8:	e8 e7 e1 ff ff       	call   f0100094 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0101ead:	c7 44 24 0c 9c 39 10 	movl   $0xf010399c,0xc(%esp)
f0101eb4:	f0 
f0101eb5:	c7 44 24 08 fa 39 10 	movl   $0xf01039fa,0x8(%esp)
f0101ebc:	f0 
f0101ebd:	c7 44 24 04 df 02 00 	movl   $0x2df,0x4(%esp)
f0101ec4:	00 
f0101ec5:	c7 04 24 d4 39 10 f0 	movl   $0xf01039d4,(%esp)
f0101ecc:	e8 c3 e1 ff ff       	call   f0100094 <_panic>

f0101ed1 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0101ed1:	55                   	push   %ebp
f0101ed2:	89 e5                	mov    %esp,%ebp
	// Fill this function in
}
f0101ed4:	5d                   	pop    %ebp
f0101ed5:	c3                   	ret    

f0101ed6 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0101ed6:	55                   	push   %ebp
f0101ed7:	89 e5                	mov    %esp,%ebp
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0101ed9:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101edc:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f0101edf:	5d                   	pop    %ebp
f0101ee0:	c3                   	ret    
f0101ee1:	00 00                	add    %al,(%eax)
	...

f0101ee4 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0101ee4:	55                   	push   %ebp
f0101ee5:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0101ee7:	ba 70 00 00 00       	mov    $0x70,%edx
f0101eec:	8b 45 08             	mov    0x8(%ebp),%eax
f0101eef:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0101ef0:	b2 71                	mov    $0x71,%dl
f0101ef2:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0101ef3:	0f b6 c0             	movzbl %al,%eax
}
f0101ef6:	5d                   	pop    %ebp
f0101ef7:	c3                   	ret    

f0101ef8 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0101ef8:	55                   	push   %ebp
f0101ef9:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0101efb:	ba 70 00 00 00       	mov    $0x70,%edx
f0101f00:	8b 45 08             	mov    0x8(%ebp),%eax
f0101f03:	ee                   	out    %al,(%dx)
f0101f04:	b2 71                	mov    $0x71,%dl
f0101f06:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101f09:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0101f0a:	5d                   	pop    %ebp
f0101f0b:	c3                   	ret    

f0101f0c <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0101f0c:	55                   	push   %ebp
f0101f0d:	89 e5                	mov    %esp,%ebp
f0101f0f:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f0101f12:	8b 45 08             	mov    0x8(%ebp),%eax
f0101f15:	89 04 24             	mov    %eax,(%esp)
f0101f18:	e8 dc e6 ff ff       	call   f01005f9 <cputchar>
	*cnt++;
}
f0101f1d:	c9                   	leave  
f0101f1e:	c3                   	ret    

f0101f1f <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0101f1f:	55                   	push   %ebp
f0101f20:	89 e5                	mov    %esp,%ebp
f0101f22:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f0101f25:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0101f2c:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101f2f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101f33:	8b 45 08             	mov    0x8(%ebp),%eax
f0101f36:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101f3a:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101f3d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101f41:	c7 04 24 0c 1f 10 f0 	movl   $0xf0101f0c,(%esp)
f0101f48:	e8 bd 04 00 00       	call   f010240a <vprintfmt>
	return cnt;
}
f0101f4d:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101f50:	c9                   	leave  
f0101f51:	c3                   	ret    

f0101f52 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0101f52:	55                   	push   %ebp
f0101f53:	89 e5                	mov    %esp,%ebp
f0101f55:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0101f58:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0101f5b:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101f5f:	8b 45 08             	mov    0x8(%ebp),%eax
f0101f62:	89 04 24             	mov    %eax,(%esp)
f0101f65:	e8 b5 ff ff ff       	call   f0101f1f <vcprintf>
	va_end(ap);

	return cnt;
}
f0101f6a:	c9                   	leave  
f0101f6b:	c3                   	ret    

f0101f6c <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0101f6c:	55                   	push   %ebp
f0101f6d:	89 e5                	mov    %esp,%ebp
f0101f6f:	57                   	push   %edi
f0101f70:	56                   	push   %esi
f0101f71:	53                   	push   %ebx
f0101f72:	83 ec 10             	sub    $0x10,%esp
f0101f75:	89 c3                	mov    %eax,%ebx
f0101f77:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0101f7a:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0101f7d:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f0101f80:	8b 0a                	mov    (%edx),%ecx
f0101f82:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101f85:	8b 00                	mov    (%eax),%eax
f0101f87:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0101f8a:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)

	while (l <= r) {
f0101f91:	eb 77                	jmp    f010200a <stab_binsearch+0x9e>
		int true_m = (l + r) / 2, m = true_m;
f0101f93:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0101f96:	01 c8                	add    %ecx,%eax
f0101f98:	bf 02 00 00 00       	mov    $0x2,%edi
f0101f9d:	99                   	cltd   
f0101f9e:	f7 ff                	idiv   %edi
f0101fa0:	89 c2                	mov    %eax,%edx

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0101fa2:	eb 01                	jmp    f0101fa5 <stab_binsearch+0x39>
			m--;
f0101fa4:	4a                   	dec    %edx

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0101fa5:	39 ca                	cmp    %ecx,%edx
f0101fa7:	7c 1d                	jl     f0101fc6 <stab_binsearch+0x5a>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0101fa9:	6b fa 0c             	imul   $0xc,%edx,%edi

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0101fac:	0f b6 7c 3b 04       	movzbl 0x4(%ebx,%edi,1),%edi
f0101fb1:	39 f7                	cmp    %esi,%edi
f0101fb3:	75 ef                	jne    f0101fa4 <stab_binsearch+0x38>
f0101fb5:	89 55 ec             	mov    %edx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0101fb8:	6b fa 0c             	imul   $0xc,%edx,%edi
f0101fbb:	8b 7c 3b 08          	mov    0x8(%ebx,%edi,1),%edi
f0101fbf:	3b 7d 0c             	cmp    0xc(%ebp),%edi
f0101fc2:	73 18                	jae    f0101fdc <stab_binsearch+0x70>
f0101fc4:	eb 05                	jmp    f0101fcb <stab_binsearch+0x5f>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0101fc6:	8d 48 01             	lea    0x1(%eax),%ecx
			continue;
f0101fc9:	eb 3f                	jmp    f010200a <stab_binsearch+0x9e>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0101fcb:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0101fce:	89 11                	mov    %edx,(%ecx)
			l = true_m + 1;
f0101fd0:	8d 48 01             	lea    0x1(%eax),%ecx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0101fd3:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0101fda:	eb 2e                	jmp    f010200a <stab_binsearch+0x9e>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0101fdc:	3b 7d 0c             	cmp    0xc(%ebp),%edi
f0101fdf:	76 15                	jbe    f0101ff6 <stab_binsearch+0x8a>
			*region_right = m - 1;
f0101fe1:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0101fe4:	4f                   	dec    %edi
f0101fe5:	89 7d f0             	mov    %edi,-0x10(%ebp)
f0101fe8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101feb:	89 38                	mov    %edi,(%eax)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0101fed:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0101ff4:	eb 14                	jmp    f010200a <stab_binsearch+0x9e>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0101ff6:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0101ff9:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0101ffc:	89 39                	mov    %edi,(%ecx)
			l = m;
			addr++;
f0101ffe:	ff 45 0c             	incl   0xc(%ebp)
f0102001:	89 d1                	mov    %edx,%ecx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102003:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f010200a:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
f010200d:	7e 84                	jle    f0101f93 <stab_binsearch+0x27>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f010200f:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0102013:	75 0d                	jne    f0102022 <stab_binsearch+0xb6>
		*region_right = *region_left - 1;
f0102015:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0102018:	8b 02                	mov    (%edx),%eax
f010201a:	48                   	dec    %eax
f010201b:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f010201e:	89 01                	mov    %eax,(%ecx)
f0102020:	eb 22                	jmp    f0102044 <stab_binsearch+0xd8>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0102022:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0102025:	8b 01                	mov    (%ecx),%eax
		     l > *region_left && stabs[l].n_type != type;
f0102027:	8b 55 e8             	mov    -0x18(%ebp),%edx
f010202a:	8b 0a                	mov    (%edx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010202c:	eb 01                	jmp    f010202f <stab_binsearch+0xc3>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f010202e:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010202f:	39 c1                	cmp    %eax,%ecx
f0102031:	7d 0c                	jge    f010203f <stab_binsearch+0xd3>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0102033:	6b d0 0c             	imul   $0xc,%eax,%edx
	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
		     l > *region_left && stabs[l].n_type != type;
f0102036:	0f b6 54 13 04       	movzbl 0x4(%ebx,%edx,1),%edx
f010203b:	39 f2                	cmp    %esi,%edx
f010203d:	75 ef                	jne    f010202e <stab_binsearch+0xc2>
		     l--)
			/* do nothing */;
		*region_left = l;
f010203f:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0102042:	89 02                	mov    %eax,(%edx)
	}
}
f0102044:	83 c4 10             	add    $0x10,%esp
f0102047:	5b                   	pop    %ebx
f0102048:	5e                   	pop    %esi
f0102049:	5f                   	pop    %edi
f010204a:	5d                   	pop    %ebp
f010204b:	c3                   	ret    

f010204c <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f010204c:	55                   	push   %ebp
f010204d:	89 e5                	mov    %esp,%ebp
f010204f:	83 ec 58             	sub    $0x58,%esp
f0102052:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0102055:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0102058:	89 7d fc             	mov    %edi,-0x4(%ebp)
f010205b:	8b 75 08             	mov    0x8(%ebp),%esi
f010205e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0102061:	c7 03 f3 3b 10 f0    	movl   $0xf0103bf3,(%ebx)
	info->eip_line = 0;
f0102067:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f010206e:	c7 43 08 f3 3b 10 f0 	movl   $0xf0103bf3,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0102075:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f010207c:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f010207f:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0102086:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f010208c:	76 12                	jbe    f01020a0 <debuginfo_eip+0x54>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f010208e:	b8 e5 b2 10 f0       	mov    $0xf010b2e5,%eax
f0102093:	3d bd 94 10 f0       	cmp    $0xf01094bd,%eax
f0102098:	0f 86 f1 01 00 00    	jbe    f010228f <debuginfo_eip+0x243>
f010209e:	eb 1c                	jmp    f01020bc <debuginfo_eip+0x70>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f01020a0:	c7 44 24 08 fd 3b 10 	movl   $0xf0103bfd,0x8(%esp)
f01020a7:	f0 
f01020a8:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f01020af:	00 
f01020b0:	c7 04 24 0a 3c 10 f0 	movl   $0xf0103c0a,(%esp)
f01020b7:	e8 d8 df ff ff       	call   f0100094 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f01020bc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01020c1:	80 3d e4 b2 10 f0 00 	cmpb   $0x0,0xf010b2e4
f01020c8:	0f 85 cd 01 00 00    	jne    f010229b <debuginfo_eip+0x24f>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f01020ce:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f01020d5:	b8 bc 94 10 f0       	mov    $0xf01094bc,%eax
f01020da:	2d 28 3e 10 f0       	sub    $0xf0103e28,%eax
f01020df:	c1 f8 02             	sar    $0x2,%eax
f01020e2:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f01020e8:	83 e8 01             	sub    $0x1,%eax
f01020eb:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f01020ee:	89 74 24 04          	mov    %esi,0x4(%esp)
f01020f2:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f01020f9:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f01020fc:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01020ff:	b8 28 3e 10 f0       	mov    $0xf0103e28,%eax
f0102104:	e8 63 fe ff ff       	call   f0101f6c <stab_binsearch>
	if (lfile == 0)
f0102109:	8b 55 e4             	mov    -0x1c(%ebp),%edx
		return -1;
f010210c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
f0102111:	85 d2                	test   %edx,%edx
f0102113:	0f 84 82 01 00 00    	je     f010229b <debuginfo_eip+0x24f>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0102119:	89 55 dc             	mov    %edx,-0x24(%ebp)
	rfun = rfile;
f010211c:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010211f:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0102122:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102126:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f010212d:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0102130:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0102133:	b8 28 3e 10 f0       	mov    $0xf0103e28,%eax
f0102138:	e8 2f fe ff ff       	call   f0101f6c <stab_binsearch>

	if (lfun <= rfun) {
f010213d:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0102140:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0102143:	39 d0                	cmp    %edx,%eax
f0102145:	7f 3d                	jg     f0102184 <debuginfo_eip+0x138>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0102147:	6b c8 0c             	imul   $0xc,%eax,%ecx
f010214a:	8d b9 28 3e 10 f0    	lea    -0xfefc1d8(%ecx),%edi
f0102150:	89 7d c0             	mov    %edi,-0x40(%ebp)
f0102153:	8b 89 28 3e 10 f0    	mov    -0xfefc1d8(%ecx),%ecx
f0102159:	bf e5 b2 10 f0       	mov    $0xf010b2e5,%edi
f010215e:	81 ef bd 94 10 f0    	sub    $0xf01094bd,%edi
f0102164:	39 f9                	cmp    %edi,%ecx
f0102166:	73 09                	jae    f0102171 <debuginfo_eip+0x125>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0102168:	81 c1 bd 94 10 f0    	add    $0xf01094bd,%ecx
f010216e:	89 4b 08             	mov    %ecx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0102171:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0102174:	8b 4f 08             	mov    0x8(%edi),%ecx
f0102177:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f010217a:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f010217c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f010217f:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0102182:	eb 0f                	jmp    f0102193 <debuginfo_eip+0x147>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0102184:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0102187:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010218a:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f010218d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102190:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0102193:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f010219a:	00 
f010219b:	8b 43 08             	mov    0x8(%ebx),%eax
f010219e:	89 04 24             	mov    %eax,(%esp)
f01021a1:	e8 44 09 00 00       	call   f0102aea <strfind>
f01021a6:	2b 43 08             	sub    0x8(%ebx),%eax
f01021a9:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f01021ac:	89 74 24 04          	mov    %esi,0x4(%esp)
f01021b0:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f01021b7:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f01021ba:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f01021bd:	b8 28 3e 10 f0       	mov    $0xf0103e28,%eax
f01021c2:	e8 a5 fd ff ff       	call   f0101f6c <stab_binsearch>
	if (lline <= rline) {
f01021c7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01021ca:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f01021cd:	7f 0f                	jg     f01021de <debuginfo_eip+0x192>
		info->eip_line = stabs[lline].n_desc;
f01021cf:	6b c0 0c             	imul   $0xc,%eax,%eax
f01021d2:	0f b7 80 2e 3e 10 f0 	movzwl -0xfefc1d2(%eax),%eax
f01021d9:	89 43 04             	mov    %eax,0x4(%ebx)
f01021dc:	eb 07                	jmp    f01021e5 <debuginfo_eip+0x199>
	} else {
		info->eip_line = -1;
f01021de:	c7 43 04 ff ff ff ff 	movl   $0xffffffff,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01021e5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01021e8:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f01021eb:	39 c8                	cmp    %ecx,%eax
f01021ed:	7c 5f                	jl     f010224e <debuginfo_eip+0x202>
	       && stabs[lline].n_type != N_SOL
f01021ef:	89 c2                	mov    %eax,%edx
f01021f1:	6b f0 0c             	imul   $0xc,%eax,%esi
f01021f4:	80 be 2c 3e 10 f0 84 	cmpb   $0x84,-0xfefc1d4(%esi)
f01021fb:	75 18                	jne    f0102215 <debuginfo_eip+0x1c9>
f01021fd:	eb 30                	jmp    f010222f <debuginfo_eip+0x1e3>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f01021ff:	83 e8 01             	sub    $0x1,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0102202:	39 c1                	cmp    %eax,%ecx
f0102204:	7f 48                	jg     f010224e <debuginfo_eip+0x202>
	       && stabs[lline].n_type != N_SOL
f0102206:	89 c2                	mov    %eax,%edx
f0102208:	8d 34 40             	lea    (%eax,%eax,2),%esi
f010220b:	80 3c b5 2c 3e 10 f0 	cmpb   $0x84,-0xfefc1d4(,%esi,4)
f0102212:	84 
f0102213:	74 1a                	je     f010222f <debuginfo_eip+0x1e3>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0102215:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0102218:	8d 14 95 28 3e 10 f0 	lea    -0xfefc1d8(,%edx,4),%edx
f010221f:	80 7a 04 64          	cmpb   $0x64,0x4(%edx)
f0102223:	75 da                	jne    f01021ff <debuginfo_eip+0x1b3>
f0102225:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f0102229:	74 d4                	je     f01021ff <debuginfo_eip+0x1b3>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f010222b:	39 c8                	cmp    %ecx,%eax
f010222d:	7c 1f                	jl     f010224e <debuginfo_eip+0x202>
f010222f:	6b c0 0c             	imul   $0xc,%eax,%eax
f0102232:	8b 80 28 3e 10 f0    	mov    -0xfefc1d8(%eax),%eax
f0102238:	ba e5 b2 10 f0       	mov    $0xf010b2e5,%edx
f010223d:	81 ea bd 94 10 f0    	sub    $0xf01094bd,%edx
f0102243:	39 d0                	cmp    %edx,%eax
f0102245:	73 07                	jae    f010224e <debuginfo_eip+0x202>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0102247:	05 bd 94 10 f0       	add    $0xf01094bd,%eax
f010224c:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f010224e:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0102251:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102254:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0102259:	39 ca                	cmp    %ecx,%edx
f010225b:	7d 3e                	jge    f010229b <debuginfo_eip+0x24f>
		for (lline = lfun + 1;
f010225d:	83 c2 01             	add    $0x1,%edx
f0102260:	39 d1                	cmp    %edx,%ecx
f0102262:	7e 37                	jle    f010229b <debuginfo_eip+0x24f>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0102264:	6b f2 0c             	imul   $0xc,%edx,%esi
f0102267:	80 be 2c 3e 10 f0 a0 	cmpb   $0xa0,-0xfefc1d4(%esi)
f010226e:	75 2b                	jne    f010229b <debuginfo_eip+0x24f>
		     lline++)
			info->eip_fn_narg++;
f0102270:	83 43 14 01          	addl   $0x1,0x14(%ebx)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0102274:	83 c2 01             	add    $0x1,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0102277:	39 d1                	cmp    %edx,%ecx
f0102279:	7e 1b                	jle    f0102296 <debuginfo_eip+0x24a>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f010227b:	8d 04 52             	lea    (%edx,%edx,2),%eax
f010227e:	80 3c 85 2c 3e 10 f0 	cmpb   $0xa0,-0xfefc1d4(,%eax,4)
f0102285:	a0 
f0102286:	74 e8                	je     f0102270 <debuginfo_eip+0x224>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102288:	b8 00 00 00 00       	mov    $0x0,%eax
f010228d:	eb 0c                	jmp    f010229b <debuginfo_eip+0x24f>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f010228f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0102294:	eb 05                	jmp    f010229b <debuginfo_eip+0x24f>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0102296:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010229b:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f010229e:	8b 75 f8             	mov    -0x8(%ebp),%esi
f01022a1:	8b 7d fc             	mov    -0x4(%ebp),%edi
f01022a4:	89 ec                	mov    %ebp,%esp
f01022a6:	5d                   	pop    %ebp
f01022a7:	c3                   	ret    
	...

f01022b0 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f01022b0:	55                   	push   %ebp
f01022b1:	89 e5                	mov    %esp,%ebp
f01022b3:	57                   	push   %edi
f01022b4:	56                   	push   %esi
f01022b5:	53                   	push   %ebx
f01022b6:	83 ec 3c             	sub    $0x3c,%esp
f01022b9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01022bc:	89 d7                	mov    %edx,%edi
f01022be:	8b 45 08             	mov    0x8(%ebp),%eax
f01022c1:	89 45 dc             	mov    %eax,-0x24(%ebp)
f01022c4:	8b 45 0c             	mov    0xc(%ebp),%eax
f01022c7:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01022ca:	8b 5d 14             	mov    0x14(%ebp),%ebx
f01022cd:	8b 75 18             	mov    0x18(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f01022d0:	b8 00 00 00 00       	mov    $0x0,%eax
f01022d5:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f01022d8:	72 11                	jb     f01022eb <printnum+0x3b>
f01022da:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01022dd:	39 45 10             	cmp    %eax,0x10(%ebp)
f01022e0:	76 09                	jbe    f01022eb <printnum+0x3b>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f01022e2:	83 eb 01             	sub    $0x1,%ebx
f01022e5:	85 db                	test   %ebx,%ebx
f01022e7:	7f 51                	jg     f010233a <printnum+0x8a>
f01022e9:	eb 5e                	jmp    f0102349 <printnum+0x99>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
f01022eb:	89 74 24 10          	mov    %esi,0x10(%esp)
f01022ef:	83 eb 01             	sub    $0x1,%ebx
f01022f2:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f01022f6:	8b 45 10             	mov    0x10(%ebp),%eax
f01022f9:	89 44 24 08          	mov    %eax,0x8(%esp)
f01022fd:	8b 5c 24 08          	mov    0x8(%esp),%ebx
f0102301:	8b 74 24 0c          	mov    0xc(%esp),%esi
f0102305:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f010230c:	00 
f010230d:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0102310:	89 04 24             	mov    %eax,(%esp)
f0102313:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102316:	89 44 24 04          	mov    %eax,0x4(%esp)
f010231a:	e8 41 0a 00 00       	call   f0102d60 <__udivdi3>
f010231f:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0102323:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0102327:	89 04 24             	mov    %eax,(%esp)
f010232a:	89 54 24 04          	mov    %edx,0x4(%esp)
f010232e:	89 fa                	mov    %edi,%edx
f0102330:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102333:	e8 78 ff ff ff       	call   f01022b0 <printnum>
f0102338:	eb 0f                	jmp    f0102349 <printnum+0x99>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f010233a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010233e:	89 34 24             	mov    %esi,(%esp)
f0102341:	ff 55 e4             	call   *-0x1c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0102344:	83 eb 01             	sub    $0x1,%ebx
f0102347:	75 f1                	jne    f010233a <printnum+0x8a>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0102349:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010234d:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0102351:	8b 45 10             	mov    0x10(%ebp),%eax
f0102354:	89 44 24 08          	mov    %eax,0x8(%esp)
f0102358:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f010235f:	00 
f0102360:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0102363:	89 04 24             	mov    %eax,(%esp)
f0102366:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0102369:	89 44 24 04          	mov    %eax,0x4(%esp)
f010236d:	e8 1e 0b 00 00       	call   f0102e90 <__umoddi3>
f0102372:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0102376:	0f be 80 18 3c 10 f0 	movsbl -0xfefc3e8(%eax),%eax
f010237d:	89 04 24             	mov    %eax,(%esp)
f0102380:	ff 55 e4             	call   *-0x1c(%ebp)
}
f0102383:	83 c4 3c             	add    $0x3c,%esp
f0102386:	5b                   	pop    %ebx
f0102387:	5e                   	pop    %esi
f0102388:	5f                   	pop    %edi
f0102389:	5d                   	pop    %ebp
f010238a:	c3                   	ret    

f010238b <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f010238b:	55                   	push   %ebp
f010238c:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f010238e:	83 fa 01             	cmp    $0x1,%edx
f0102391:	7e 0e                	jle    f01023a1 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0102393:	8b 10                	mov    (%eax),%edx
f0102395:	8d 4a 08             	lea    0x8(%edx),%ecx
f0102398:	89 08                	mov    %ecx,(%eax)
f010239a:	8b 02                	mov    (%edx),%eax
f010239c:	8b 52 04             	mov    0x4(%edx),%edx
f010239f:	eb 22                	jmp    f01023c3 <getuint+0x38>
	else if (lflag)
f01023a1:	85 d2                	test   %edx,%edx
f01023a3:	74 10                	je     f01023b5 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f01023a5:	8b 10                	mov    (%eax),%edx
f01023a7:	8d 4a 04             	lea    0x4(%edx),%ecx
f01023aa:	89 08                	mov    %ecx,(%eax)
f01023ac:	8b 02                	mov    (%edx),%eax
f01023ae:	ba 00 00 00 00       	mov    $0x0,%edx
f01023b3:	eb 0e                	jmp    f01023c3 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f01023b5:	8b 10                	mov    (%eax),%edx
f01023b7:	8d 4a 04             	lea    0x4(%edx),%ecx
f01023ba:	89 08                	mov    %ecx,(%eax)
f01023bc:	8b 02                	mov    (%edx),%eax
f01023be:	ba 00 00 00 00       	mov    $0x0,%edx
}
f01023c3:	5d                   	pop    %ebp
f01023c4:	c3                   	ret    

f01023c5 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f01023c5:	55                   	push   %ebp
f01023c6:	89 e5                	mov    %esp,%ebp
f01023c8:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f01023cb:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f01023cf:	8b 10                	mov    (%eax),%edx
f01023d1:	3b 50 04             	cmp    0x4(%eax),%edx
f01023d4:	73 0a                	jae    f01023e0 <sprintputch+0x1b>
		*b->buf++ = ch;
f01023d6:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01023d9:	88 0a                	mov    %cl,(%edx)
f01023db:	83 c2 01             	add    $0x1,%edx
f01023de:	89 10                	mov    %edx,(%eax)
}
f01023e0:	5d                   	pop    %ebp
f01023e1:	c3                   	ret    

f01023e2 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f01023e2:	55                   	push   %ebp
f01023e3:	89 e5                	mov    %esp,%ebp
f01023e5:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f01023e8:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f01023eb:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01023ef:	8b 45 10             	mov    0x10(%ebp),%eax
f01023f2:	89 44 24 08          	mov    %eax,0x8(%esp)
f01023f6:	8b 45 0c             	mov    0xc(%ebp),%eax
f01023f9:	89 44 24 04          	mov    %eax,0x4(%esp)
f01023fd:	8b 45 08             	mov    0x8(%ebp),%eax
f0102400:	89 04 24             	mov    %eax,(%esp)
f0102403:	e8 02 00 00 00       	call   f010240a <vprintfmt>
	va_end(ap);
}
f0102408:	c9                   	leave  
f0102409:	c3                   	ret    

f010240a <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f010240a:	55                   	push   %ebp
f010240b:	89 e5                	mov    %esp,%ebp
f010240d:	57                   	push   %edi
f010240e:	56                   	push   %esi
f010240f:	53                   	push   %ebx
f0102410:	83 ec 4c             	sub    $0x4c,%esp
f0102413:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102416:	8b 75 10             	mov    0x10(%ebp),%esi
f0102419:	eb 12                	jmp    f010242d <vprintfmt+0x23>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f010241b:	85 c0                	test   %eax,%eax
f010241d:	0f 84 a9 03 00 00    	je     f01027cc <vprintfmt+0x3c2>
				return;
			putch(ch, putdat);
f0102423:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102427:	89 04 24             	mov    %eax,(%esp)
f010242a:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f010242d:	0f b6 06             	movzbl (%esi),%eax
f0102430:	83 c6 01             	add    $0x1,%esi
f0102433:	83 f8 25             	cmp    $0x25,%eax
f0102436:	75 e3                	jne    f010241b <vprintfmt+0x11>
f0102438:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
f010243c:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
f0102443:	bf ff ff ff ff       	mov    $0xffffffff,%edi
f0102448:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
f010244f:	b9 00 00 00 00       	mov    $0x0,%ecx
f0102454:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0102457:	eb 2b                	jmp    f0102484 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102459:	8b 75 e0             	mov    -0x20(%ebp),%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f010245c:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
f0102460:	eb 22                	jmp    f0102484 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102462:	8b 75 e0             	mov    -0x20(%ebp),%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0102465:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
f0102469:	eb 19                	jmp    f0102484 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010246b:	8b 75 e0             	mov    -0x20(%ebp),%esi
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
f010246e:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f0102475:	eb 0d                	jmp    f0102484 <vprintfmt+0x7a>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f0102477:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010247a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010247d:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102484:	0f b6 06             	movzbl (%esi),%eax
f0102487:	0f b6 d0             	movzbl %al,%edx
f010248a:	8d 7e 01             	lea    0x1(%esi),%edi
f010248d:	89 7d e0             	mov    %edi,-0x20(%ebp)
f0102490:	83 e8 23             	sub    $0x23,%eax
f0102493:	3c 55                	cmp    $0x55,%al
f0102495:	0f 87 0b 03 00 00    	ja     f01027a6 <vprintfmt+0x39c>
f010249b:	0f b6 c0             	movzbl %al,%eax
f010249e:	ff 24 85 a4 3c 10 f0 	jmp    *-0xfefc35c(,%eax,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f01024a5:	83 ea 30             	sub    $0x30,%edx
f01024a8:	89 55 d4             	mov    %edx,-0x2c(%ebp)
				ch = *fmt;
f01024ab:	0f be 46 01          	movsbl 0x1(%esi),%eax
				if (ch < '0' || ch > '9')
f01024af:	8d 50 d0             	lea    -0x30(%eax),%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01024b2:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
f01024b5:	83 fa 09             	cmp    $0x9,%edx
f01024b8:	77 4a                	ja     f0102504 <vprintfmt+0xfa>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01024ba:	8b 7d d4             	mov    -0x2c(%ebp),%edi
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f01024bd:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
f01024c0:	8d 14 bf             	lea    (%edi,%edi,4),%edx
f01024c3:	8d 7c 50 d0          	lea    -0x30(%eax,%edx,2),%edi
				ch = *fmt;
f01024c7:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f01024ca:	8d 50 d0             	lea    -0x30(%eax),%edx
f01024cd:	83 fa 09             	cmp    $0x9,%edx
f01024d0:	76 eb                	jbe    f01024bd <vprintfmt+0xb3>
f01024d2:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f01024d5:	eb 2d                	jmp    f0102504 <vprintfmt+0xfa>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f01024d7:	8b 45 14             	mov    0x14(%ebp),%eax
f01024da:	8d 50 04             	lea    0x4(%eax),%edx
f01024dd:	89 55 14             	mov    %edx,0x14(%ebp)
f01024e0:	8b 00                	mov    (%eax),%eax
f01024e2:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01024e5:	8b 75 e0             	mov    -0x20(%ebp),%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f01024e8:	eb 1a                	jmp    f0102504 <vprintfmt+0xfa>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01024ea:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case '*':
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
f01024ed:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01024f1:	79 91                	jns    f0102484 <vprintfmt+0x7a>
f01024f3:	e9 73 ff ff ff       	jmp    f010246b <vprintfmt+0x61>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01024f8:	8b 75 e0             	mov    -0x20(%ebp),%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f01024fb:	c7 45 dc 01 00 00 00 	movl   $0x1,-0x24(%ebp)
			goto reswitch;
f0102502:	eb 80                	jmp    f0102484 <vprintfmt+0x7a>

		process_precision:
			if (width < 0)
f0102504:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0102508:	0f 89 76 ff ff ff    	jns    f0102484 <vprintfmt+0x7a>
f010250e:	e9 64 ff ff ff       	jmp    f0102477 <vprintfmt+0x6d>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0102513:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102516:	8b 75 e0             	mov    -0x20(%ebp),%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0102519:	e9 66 ff ff ff       	jmp    f0102484 <vprintfmt+0x7a>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f010251e:	8b 45 14             	mov    0x14(%ebp),%eax
f0102521:	8d 50 04             	lea    0x4(%eax),%edx
f0102524:	89 55 14             	mov    %edx,0x14(%ebp)
f0102527:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010252b:	8b 00                	mov    (%eax),%eax
f010252d:	89 04 24             	mov    %eax,(%esp)
f0102530:	ff 55 08             	call   *0x8(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102533:	8b 75 e0             	mov    -0x20(%ebp),%esi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0102536:	e9 f2 fe ff ff       	jmp    f010242d <vprintfmt+0x23>

		// error message
		case 'e':
			err = va_arg(ap, int);
f010253b:	8b 45 14             	mov    0x14(%ebp),%eax
f010253e:	8d 50 04             	lea    0x4(%eax),%edx
f0102541:	89 55 14             	mov    %edx,0x14(%ebp)
f0102544:	8b 00                	mov    (%eax),%eax
f0102546:	89 c2                	mov    %eax,%edx
f0102548:	c1 fa 1f             	sar    $0x1f,%edx
f010254b:	31 d0                	xor    %edx,%eax
f010254d:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f010254f:	83 f8 06             	cmp    $0x6,%eax
f0102552:	7f 0b                	jg     f010255f <vprintfmt+0x155>
f0102554:	8b 14 85 fc 3d 10 f0 	mov    -0xfefc204(,%eax,4),%edx
f010255b:	85 d2                	test   %edx,%edx
f010255d:	75 23                	jne    f0102582 <vprintfmt+0x178>
				printfmt(putch, putdat, "error %d", err);
f010255f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102563:	c7 44 24 08 30 3c 10 	movl   $0xf0103c30,0x8(%esp)
f010256a:	f0 
f010256b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010256f:	8b 7d 08             	mov    0x8(%ebp),%edi
f0102572:	89 3c 24             	mov    %edi,(%esp)
f0102575:	e8 68 fe ff ff       	call   f01023e2 <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010257a:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f010257d:	e9 ab fe ff ff       	jmp    f010242d <vprintfmt+0x23>
			else
				printfmt(putch, putdat, "%s", p);
f0102582:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0102586:	c7 44 24 08 0c 3a 10 	movl   $0xf0103a0c,0x8(%esp)
f010258d:	f0 
f010258e:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102592:	8b 7d 08             	mov    0x8(%ebp),%edi
f0102595:	89 3c 24             	mov    %edi,(%esp)
f0102598:	e8 45 fe ff ff       	call   f01023e2 <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010259d:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01025a0:	e9 88 fe ff ff       	jmp    f010242d <vprintfmt+0x23>
f01025a5:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01025a8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01025ab:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f01025ae:	8b 45 14             	mov    0x14(%ebp),%eax
f01025b1:	8d 50 04             	lea    0x4(%eax),%edx
f01025b4:	89 55 14             	mov    %edx,0x14(%ebp)
f01025b7:	8b 30                	mov    (%eax),%esi
				p = "(null)";
f01025b9:	85 f6                	test   %esi,%esi
f01025bb:	ba 29 3c 10 f0       	mov    $0xf0103c29,%edx
f01025c0:	0f 44 f2             	cmove  %edx,%esi
			if (width > 0 && padc != '-')
f01025c3:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f01025c7:	7e 06                	jle    f01025cf <vprintfmt+0x1c5>
f01025c9:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
f01025cd:	75 10                	jne    f01025df <vprintfmt+0x1d5>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01025cf:	0f be 06             	movsbl (%esi),%eax
f01025d2:	83 c6 01             	add    $0x1,%esi
f01025d5:	85 c0                	test   %eax,%eax
f01025d7:	0f 85 86 00 00 00    	jne    f0102663 <vprintfmt+0x259>
f01025dd:	eb 76                	jmp    f0102655 <vprintfmt+0x24b>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01025df:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01025e3:	89 34 24             	mov    %esi,(%esp)
f01025e6:	e8 60 03 00 00       	call   f010294b <strnlen>
f01025eb:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01025ee:	29 c2                	sub    %eax,%edx
f01025f0:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01025f3:	85 d2                	test   %edx,%edx
f01025f5:	7e d8                	jle    f01025cf <vprintfmt+0x1c5>
					putch(padc, putdat);
f01025f7:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
f01025fb:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f01025fe:	89 d6                	mov    %edx,%esi
f0102600:	89 7d d0             	mov    %edi,-0x30(%ebp)
f0102603:	89 c7                	mov    %eax,%edi
f0102605:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102609:	89 3c 24             	mov    %edi,(%esp)
f010260c:	ff 55 08             	call   *0x8(%ebp)
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010260f:	83 ee 01             	sub    $0x1,%esi
f0102612:	75 f1                	jne    f0102605 <vprintfmt+0x1fb>
f0102614:	89 75 e4             	mov    %esi,-0x1c(%ebp)
f0102617:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f010261a:	8b 7d d0             	mov    -0x30(%ebp),%edi
f010261d:	eb b0                	jmp    f01025cf <vprintfmt+0x1c5>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f010261f:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0102623:	74 18                	je     f010263d <vprintfmt+0x233>
f0102625:	8d 50 e0             	lea    -0x20(%eax),%edx
f0102628:	83 fa 5e             	cmp    $0x5e,%edx
f010262b:	76 10                	jbe    f010263d <vprintfmt+0x233>
					putch('?', putdat);
f010262d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102631:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0102638:	ff 55 08             	call   *0x8(%ebp)
f010263b:	eb 0a                	jmp    f0102647 <vprintfmt+0x23d>
				else
					putch(ch, putdat);
f010263d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102641:	89 04 24             	mov    %eax,(%esp)
f0102644:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0102647:	83 6d e4 01          	subl   $0x1,-0x1c(%ebp)
f010264b:	0f be 06             	movsbl (%esi),%eax
f010264e:	83 c6 01             	add    $0x1,%esi
f0102651:	85 c0                	test   %eax,%eax
f0102653:	75 0e                	jne    f0102663 <vprintfmt+0x259>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0102655:	8b 75 e0             	mov    -0x20(%ebp),%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0102658:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f010265c:	7f 16                	jg     f0102674 <vprintfmt+0x26a>
f010265e:	e9 ca fd ff ff       	jmp    f010242d <vprintfmt+0x23>
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0102663:	85 ff                	test   %edi,%edi
f0102665:	78 b8                	js     f010261f <vprintfmt+0x215>
f0102667:	83 ef 01             	sub    $0x1,%edi
f010266a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0102670:	79 ad                	jns    f010261f <vprintfmt+0x215>
f0102672:	eb e1                	jmp    f0102655 <vprintfmt+0x24b>
f0102674:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0102677:	8b 7d 08             	mov    0x8(%ebp),%edi
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f010267a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010267e:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0102685:	ff d7                	call   *%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0102687:	83 ee 01             	sub    $0x1,%esi
f010268a:	75 ee                	jne    f010267a <vprintfmt+0x270>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010268c:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010268f:	e9 99 fd ff ff       	jmp    f010242d <vprintfmt+0x23>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0102694:	83 f9 01             	cmp    $0x1,%ecx
f0102697:	7e 10                	jle    f01026a9 <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f0102699:	8b 45 14             	mov    0x14(%ebp),%eax
f010269c:	8d 50 08             	lea    0x8(%eax),%edx
f010269f:	89 55 14             	mov    %edx,0x14(%ebp)
f01026a2:	8b 30                	mov    (%eax),%esi
f01026a4:	8b 78 04             	mov    0x4(%eax),%edi
f01026a7:	eb 26                	jmp    f01026cf <vprintfmt+0x2c5>
	else if (lflag)
f01026a9:	85 c9                	test   %ecx,%ecx
f01026ab:	74 12                	je     f01026bf <vprintfmt+0x2b5>
		return va_arg(*ap, long);
f01026ad:	8b 45 14             	mov    0x14(%ebp),%eax
f01026b0:	8d 50 04             	lea    0x4(%eax),%edx
f01026b3:	89 55 14             	mov    %edx,0x14(%ebp)
f01026b6:	8b 30                	mov    (%eax),%esi
f01026b8:	89 f7                	mov    %esi,%edi
f01026ba:	c1 ff 1f             	sar    $0x1f,%edi
f01026bd:	eb 10                	jmp    f01026cf <vprintfmt+0x2c5>
	else
		return va_arg(*ap, int);
f01026bf:	8b 45 14             	mov    0x14(%ebp),%eax
f01026c2:	8d 50 04             	lea    0x4(%eax),%edx
f01026c5:	89 55 14             	mov    %edx,0x14(%ebp)
f01026c8:	8b 30                	mov    (%eax),%esi
f01026ca:	89 f7                	mov    %esi,%edi
f01026cc:	c1 ff 1f             	sar    $0x1f,%edi
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f01026cf:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f01026d4:	85 ff                	test   %edi,%edi
f01026d6:	0f 89 8c 00 00 00    	jns    f0102768 <vprintfmt+0x35e>
				putch('-', putdat);
f01026dc:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01026e0:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f01026e7:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f01026ea:	f7 de                	neg    %esi
f01026ec:	83 d7 00             	adc    $0x0,%edi
f01026ef:	f7 df                	neg    %edi
			}
			base = 10;
f01026f1:	b8 0a 00 00 00       	mov    $0xa,%eax
f01026f6:	eb 70                	jmp    f0102768 <vprintfmt+0x35e>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f01026f8:	89 ca                	mov    %ecx,%edx
f01026fa:	8d 45 14             	lea    0x14(%ebp),%eax
f01026fd:	e8 89 fc ff ff       	call   f010238b <getuint>
f0102702:	89 c6                	mov    %eax,%esi
f0102704:	89 d7                	mov    %edx,%edi
			base = 10;
f0102706:	b8 0a 00 00 00       	mov    $0xa,%eax
			goto number;
f010270b:	eb 5b                	jmp    f0102768 <vprintfmt+0x35e>
			// Replace this with your code.
			//putch('0', putdat);
			//putch('X', putdat);
			//putch('X', putdat);
			//break;
			num = getuint(&ap, lflag);
f010270d:	89 ca                	mov    %ecx,%edx
f010270f:	8d 45 14             	lea    0x14(%ebp),%eax
f0102712:	e8 74 fc ff ff       	call   f010238b <getuint>
f0102717:	89 c6                	mov    %eax,%esi
f0102719:	89 d7                	mov    %edx,%edi
			base = 8;
f010271b:	b8 08 00 00 00       	mov    $0x8,%eax
			goto number;
f0102720:	eb 46                	jmp    f0102768 <vprintfmt+0x35e>
		// pointer
		case 'p':
			putch('0', putdat);
f0102722:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102726:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f010272d:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f0102730:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102734:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f010273b:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f010273e:	8b 45 14             	mov    0x14(%ebp),%eax
f0102741:	8d 50 04             	lea    0x4(%eax),%edx
f0102744:	89 55 14             	mov    %edx,0x14(%ebp)
			goto number;
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0102747:	8b 30                	mov    (%eax),%esi
f0102749:	bf 00 00 00 00       	mov    $0x0,%edi
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f010274e:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f0102753:	eb 13                	jmp    f0102768 <vprintfmt+0x35e>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0102755:	89 ca                	mov    %ecx,%edx
f0102757:	8d 45 14             	lea    0x14(%ebp),%eax
f010275a:	e8 2c fc ff ff       	call   f010238b <getuint>
f010275f:	89 c6                	mov    %eax,%esi
f0102761:	89 d7                	mov    %edx,%edi
			base = 16;
f0102763:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f0102768:	0f be 55 d8          	movsbl -0x28(%ebp),%edx
f010276c:	89 54 24 10          	mov    %edx,0x10(%esp)
f0102770:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0102773:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0102777:	89 44 24 08          	mov    %eax,0x8(%esp)
f010277b:	89 34 24             	mov    %esi,(%esp)
f010277e:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0102782:	89 da                	mov    %ebx,%edx
f0102784:	8b 45 08             	mov    0x8(%ebp),%eax
f0102787:	e8 24 fb ff ff       	call   f01022b0 <printnum>
			break;
f010278c:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010278f:	e9 99 fc ff ff       	jmp    f010242d <vprintfmt+0x23>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0102794:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102798:	89 14 24             	mov    %edx,(%esp)
f010279b:	ff 55 08             	call   *0x8(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010279e:	8b 75 e0             	mov    -0x20(%ebp),%esi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f01027a1:	e9 87 fc ff ff       	jmp    f010242d <vprintfmt+0x23>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f01027a6:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01027aa:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f01027b1:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f01027b4:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
f01027b8:	0f 84 6f fc ff ff    	je     f010242d <vprintfmt+0x23>
f01027be:	83 ee 01             	sub    $0x1,%esi
f01027c1:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
f01027c5:	75 f7                	jne    f01027be <vprintfmt+0x3b4>
f01027c7:	e9 61 fc ff ff       	jmp    f010242d <vprintfmt+0x23>
				/* do nothing */;
			break;
		}
	}
}
f01027cc:	83 c4 4c             	add    $0x4c,%esp
f01027cf:	5b                   	pop    %ebx
f01027d0:	5e                   	pop    %esi
f01027d1:	5f                   	pop    %edi
f01027d2:	5d                   	pop    %ebp
f01027d3:	c3                   	ret    

f01027d4 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01027d4:	55                   	push   %ebp
f01027d5:	89 e5                	mov    %esp,%ebp
f01027d7:	83 ec 28             	sub    $0x28,%esp
f01027da:	8b 45 08             	mov    0x8(%ebp),%eax
f01027dd:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01027e0:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01027e3:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01027e7:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01027ea:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01027f1:	85 c0                	test   %eax,%eax
f01027f3:	74 30                	je     f0102825 <vsnprintf+0x51>
f01027f5:	85 d2                	test   %edx,%edx
f01027f7:	7e 2c                	jle    f0102825 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01027f9:	8b 45 14             	mov    0x14(%ebp),%eax
f01027fc:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102800:	8b 45 10             	mov    0x10(%ebp),%eax
f0102803:	89 44 24 08          	mov    %eax,0x8(%esp)
f0102807:	8d 45 ec             	lea    -0x14(%ebp),%eax
f010280a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010280e:	c7 04 24 c5 23 10 f0 	movl   $0xf01023c5,(%esp)
f0102815:	e8 f0 fb ff ff       	call   f010240a <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f010281a:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010281d:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0102820:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102823:	eb 05                	jmp    f010282a <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0102825:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f010282a:	c9                   	leave  
f010282b:	c3                   	ret    

f010282c <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010282c:	55                   	push   %ebp
f010282d:	89 e5                	mov    %esp,%ebp
f010282f:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0102832:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0102835:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102839:	8b 45 10             	mov    0x10(%ebp),%eax
f010283c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0102840:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102843:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102847:	8b 45 08             	mov    0x8(%ebp),%eax
f010284a:	89 04 24             	mov    %eax,(%esp)
f010284d:	e8 82 ff ff ff       	call   f01027d4 <vsnprintf>
	va_end(ap);

	return rc;
}
f0102852:	c9                   	leave  
f0102853:	c3                   	ret    
	...

f0102860 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0102860:	55                   	push   %ebp
f0102861:	89 e5                	mov    %esp,%ebp
f0102863:	57                   	push   %edi
f0102864:	56                   	push   %esi
f0102865:	53                   	push   %ebx
f0102866:	83 ec 1c             	sub    $0x1c,%esp
f0102869:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010286c:	85 c0                	test   %eax,%eax
f010286e:	74 10                	je     f0102880 <readline+0x20>
		cprintf("%s", prompt);
f0102870:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102874:	c7 04 24 0c 3a 10 f0 	movl   $0xf0103a0c,(%esp)
f010287b:	e8 d2 f6 ff ff       	call   f0101f52 <cprintf>

	i = 0;
	echoing = iscons(0);
f0102880:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102887:	e8 8e dd ff ff       	call   f010061a <iscons>
f010288c:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010288e:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0102893:	e8 71 dd ff ff       	call   f0100609 <getchar>
f0102898:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010289a:	85 c0                	test   %eax,%eax
f010289c:	79 17                	jns    f01028b5 <readline+0x55>
			cprintf("read error: %e\n", c);
f010289e:	89 44 24 04          	mov    %eax,0x4(%esp)
f01028a2:	c7 04 24 18 3e 10 f0 	movl   $0xf0103e18,(%esp)
f01028a9:	e8 a4 f6 ff ff       	call   f0101f52 <cprintf>
			return NULL;
f01028ae:	b8 00 00 00 00       	mov    $0x0,%eax
f01028b3:	eb 6d                	jmp    f0102922 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01028b5:	83 f8 08             	cmp    $0x8,%eax
f01028b8:	74 05                	je     f01028bf <readline+0x5f>
f01028ba:	83 f8 7f             	cmp    $0x7f,%eax
f01028bd:	75 19                	jne    f01028d8 <readline+0x78>
f01028bf:	85 f6                	test   %esi,%esi
f01028c1:	7e 15                	jle    f01028d8 <readline+0x78>
			if (echoing)
f01028c3:	85 ff                	test   %edi,%edi
f01028c5:	74 0c                	je     f01028d3 <readline+0x73>
				cputchar('\b');
f01028c7:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f01028ce:	e8 26 dd ff ff       	call   f01005f9 <cputchar>
			i--;
f01028d3:	83 ee 01             	sub    $0x1,%esi
f01028d6:	eb bb                	jmp    f0102893 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01028d8:	83 fb 1f             	cmp    $0x1f,%ebx
f01028db:	7e 1f                	jle    f01028fc <readline+0x9c>
f01028dd:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01028e3:	7f 17                	jg     f01028fc <readline+0x9c>
			if (echoing)
f01028e5:	85 ff                	test   %edi,%edi
f01028e7:	74 08                	je     f01028f1 <readline+0x91>
				cputchar(c);
f01028e9:	89 1c 24             	mov    %ebx,(%esp)
f01028ec:	e8 08 dd ff ff       	call   f01005f9 <cputchar>
			buf[i++] = c;
f01028f1:	88 9e 80 65 11 f0    	mov    %bl,-0xfee9a80(%esi)
f01028f7:	83 c6 01             	add    $0x1,%esi
f01028fa:	eb 97                	jmp    f0102893 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f01028fc:	83 fb 0a             	cmp    $0xa,%ebx
f01028ff:	74 05                	je     f0102906 <readline+0xa6>
f0102901:	83 fb 0d             	cmp    $0xd,%ebx
f0102904:	75 8d                	jne    f0102893 <readline+0x33>
			if (echoing)
f0102906:	85 ff                	test   %edi,%edi
f0102908:	74 0c                	je     f0102916 <readline+0xb6>
				cputchar('\n');
f010290a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0102911:	e8 e3 dc ff ff       	call   f01005f9 <cputchar>
			buf[i] = 0;
f0102916:	c6 86 80 65 11 f0 00 	movb   $0x0,-0xfee9a80(%esi)
			return buf;
f010291d:	b8 80 65 11 f0       	mov    $0xf0116580,%eax
		}
	}
}
f0102922:	83 c4 1c             	add    $0x1c,%esp
f0102925:	5b                   	pop    %ebx
f0102926:	5e                   	pop    %esi
f0102927:	5f                   	pop    %edi
f0102928:	5d                   	pop    %ebp
f0102929:	c3                   	ret    
f010292a:	00 00                	add    %al,(%eax)
f010292c:	00 00                	add    %al,(%eax)
	...

f0102930 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0102930:	55                   	push   %ebp
f0102931:	89 e5                	mov    %esp,%ebp
f0102933:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0102936:	b8 00 00 00 00       	mov    $0x0,%eax
f010293b:	80 3a 00             	cmpb   $0x0,(%edx)
f010293e:	74 09                	je     f0102949 <strlen+0x19>
		n++;
f0102940:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0102943:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0102947:	75 f7                	jne    f0102940 <strlen+0x10>
		n++;
	return n;
}
f0102949:	5d                   	pop    %ebp
f010294a:	c3                   	ret    

f010294b <strnlen>:

int
strnlen(const char *s, size_t size)
{
f010294b:	55                   	push   %ebp
f010294c:	89 e5                	mov    %esp,%ebp
f010294e:	53                   	push   %ebx
f010294f:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0102952:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0102955:	b8 00 00 00 00       	mov    $0x0,%eax
f010295a:	85 c9                	test   %ecx,%ecx
f010295c:	74 1a                	je     f0102978 <strnlen+0x2d>
f010295e:	80 3b 00             	cmpb   $0x0,(%ebx)
f0102961:	74 15                	je     f0102978 <strnlen+0x2d>
f0102963:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
f0102968:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010296a:	39 ca                	cmp    %ecx,%edx
f010296c:	74 0a                	je     f0102978 <strnlen+0x2d>
f010296e:	83 c2 01             	add    $0x1,%edx
f0102971:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
f0102976:	75 f0                	jne    f0102968 <strnlen+0x1d>
		n++;
	return n;
}
f0102978:	5b                   	pop    %ebx
f0102979:	5d                   	pop    %ebp
f010297a:	c3                   	ret    

f010297b <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f010297b:	55                   	push   %ebp
f010297c:	89 e5                	mov    %esp,%ebp
f010297e:	53                   	push   %ebx
f010297f:	8b 45 08             	mov    0x8(%ebp),%eax
f0102982:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0102985:	ba 00 00 00 00       	mov    $0x0,%edx
f010298a:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f010298e:	88 0c 10             	mov    %cl,(%eax,%edx,1)
f0102991:	83 c2 01             	add    $0x1,%edx
f0102994:	84 c9                	test   %cl,%cl
f0102996:	75 f2                	jne    f010298a <strcpy+0xf>
		/* do nothing */;
	return ret;
}
f0102998:	5b                   	pop    %ebx
f0102999:	5d                   	pop    %ebp
f010299a:	c3                   	ret    

f010299b <strcat>:

char *
strcat(char *dst, const char *src)
{
f010299b:	55                   	push   %ebp
f010299c:	89 e5                	mov    %esp,%ebp
f010299e:	53                   	push   %ebx
f010299f:	83 ec 08             	sub    $0x8,%esp
f01029a2:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01029a5:	89 1c 24             	mov    %ebx,(%esp)
f01029a8:	e8 83 ff ff ff       	call   f0102930 <strlen>
	strcpy(dst + len, src);
f01029ad:	8b 55 0c             	mov    0xc(%ebp),%edx
f01029b0:	89 54 24 04          	mov    %edx,0x4(%esp)
f01029b4:	01 d8                	add    %ebx,%eax
f01029b6:	89 04 24             	mov    %eax,(%esp)
f01029b9:	e8 bd ff ff ff       	call   f010297b <strcpy>
	return dst;
}
f01029be:	89 d8                	mov    %ebx,%eax
f01029c0:	83 c4 08             	add    $0x8,%esp
f01029c3:	5b                   	pop    %ebx
f01029c4:	5d                   	pop    %ebp
f01029c5:	c3                   	ret    

f01029c6 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01029c6:	55                   	push   %ebp
f01029c7:	89 e5                	mov    %esp,%ebp
f01029c9:	56                   	push   %esi
f01029ca:	53                   	push   %ebx
f01029cb:	8b 45 08             	mov    0x8(%ebp),%eax
f01029ce:	8b 55 0c             	mov    0xc(%ebp),%edx
f01029d1:	8b 75 10             	mov    0x10(%ebp),%esi
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01029d4:	85 f6                	test   %esi,%esi
f01029d6:	74 18                	je     f01029f0 <strncpy+0x2a>
f01029d8:	b9 00 00 00 00       	mov    $0x0,%ecx
		*dst++ = *src;
f01029dd:	0f b6 1a             	movzbl (%edx),%ebx
f01029e0:	88 1c 08             	mov    %bl,(%eax,%ecx,1)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01029e3:	80 3a 01             	cmpb   $0x1,(%edx)
f01029e6:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01029e9:	83 c1 01             	add    $0x1,%ecx
f01029ec:	39 f1                	cmp    %esi,%ecx
f01029ee:	75 ed                	jne    f01029dd <strncpy+0x17>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01029f0:	5b                   	pop    %ebx
f01029f1:	5e                   	pop    %esi
f01029f2:	5d                   	pop    %ebp
f01029f3:	c3                   	ret    

f01029f4 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01029f4:	55                   	push   %ebp
f01029f5:	89 e5                	mov    %esp,%ebp
f01029f7:	57                   	push   %edi
f01029f8:	56                   	push   %esi
f01029f9:	53                   	push   %ebx
f01029fa:	8b 7d 08             	mov    0x8(%ebp),%edi
f01029fd:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102a00:	8b 75 10             	mov    0x10(%ebp),%esi
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0102a03:	89 f8                	mov    %edi,%eax
f0102a05:	85 f6                	test   %esi,%esi
f0102a07:	74 2b                	je     f0102a34 <strlcpy+0x40>
		while (--size > 0 && *src != '\0')
f0102a09:	83 fe 01             	cmp    $0x1,%esi
f0102a0c:	74 23                	je     f0102a31 <strlcpy+0x3d>
f0102a0e:	0f b6 0b             	movzbl (%ebx),%ecx
f0102a11:	84 c9                	test   %cl,%cl
f0102a13:	74 1c                	je     f0102a31 <strlcpy+0x3d>
	}
	return ret;
}

size_t
strlcpy(char *dst, const char *src, size_t size)
f0102a15:	83 ee 02             	sub    $0x2,%esi
f0102a18:	ba 00 00 00 00       	mov    $0x0,%edx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0102a1d:	88 08                	mov    %cl,(%eax)
f0102a1f:	83 c0 01             	add    $0x1,%eax
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0102a22:	39 f2                	cmp    %esi,%edx
f0102a24:	74 0b                	je     f0102a31 <strlcpy+0x3d>
f0102a26:	83 c2 01             	add    $0x1,%edx
f0102a29:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f0102a2d:	84 c9                	test   %cl,%cl
f0102a2f:	75 ec                	jne    f0102a1d <strlcpy+0x29>
			*dst++ = *src++;
		*dst = '\0';
f0102a31:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0102a34:	29 f8                	sub    %edi,%eax
}
f0102a36:	5b                   	pop    %ebx
f0102a37:	5e                   	pop    %esi
f0102a38:	5f                   	pop    %edi
f0102a39:	5d                   	pop    %ebp
f0102a3a:	c3                   	ret    

f0102a3b <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0102a3b:	55                   	push   %ebp
f0102a3c:	89 e5                	mov    %esp,%ebp
f0102a3e:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0102a41:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0102a44:	0f b6 01             	movzbl (%ecx),%eax
f0102a47:	84 c0                	test   %al,%al
f0102a49:	74 16                	je     f0102a61 <strcmp+0x26>
f0102a4b:	3a 02                	cmp    (%edx),%al
f0102a4d:	75 12                	jne    f0102a61 <strcmp+0x26>
		p++, q++;
f0102a4f:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0102a52:	0f b6 41 01          	movzbl 0x1(%ecx),%eax
f0102a56:	84 c0                	test   %al,%al
f0102a58:	74 07                	je     f0102a61 <strcmp+0x26>
f0102a5a:	83 c1 01             	add    $0x1,%ecx
f0102a5d:	3a 02                	cmp    (%edx),%al
f0102a5f:	74 ee                	je     f0102a4f <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0102a61:	0f b6 c0             	movzbl %al,%eax
f0102a64:	0f b6 12             	movzbl (%edx),%edx
f0102a67:	29 d0                	sub    %edx,%eax
}
f0102a69:	5d                   	pop    %ebp
f0102a6a:	c3                   	ret    

f0102a6b <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0102a6b:	55                   	push   %ebp
f0102a6c:	89 e5                	mov    %esp,%ebp
f0102a6e:	53                   	push   %ebx
f0102a6f:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0102a72:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102a75:	8b 55 10             	mov    0x10(%ebp),%edx
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0102a78:	b8 00 00 00 00       	mov    $0x0,%eax
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0102a7d:	85 d2                	test   %edx,%edx
f0102a7f:	74 28                	je     f0102aa9 <strncmp+0x3e>
f0102a81:	0f b6 01             	movzbl (%ecx),%eax
f0102a84:	84 c0                	test   %al,%al
f0102a86:	74 24                	je     f0102aac <strncmp+0x41>
f0102a88:	3a 03                	cmp    (%ebx),%al
f0102a8a:	75 20                	jne    f0102aac <strncmp+0x41>
f0102a8c:	83 ea 01             	sub    $0x1,%edx
f0102a8f:	74 13                	je     f0102aa4 <strncmp+0x39>
		n--, p++, q++;
f0102a91:	83 c1 01             	add    $0x1,%ecx
f0102a94:	83 c3 01             	add    $0x1,%ebx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0102a97:	0f b6 01             	movzbl (%ecx),%eax
f0102a9a:	84 c0                	test   %al,%al
f0102a9c:	74 0e                	je     f0102aac <strncmp+0x41>
f0102a9e:	3a 03                	cmp    (%ebx),%al
f0102aa0:	74 ea                	je     f0102a8c <strncmp+0x21>
f0102aa2:	eb 08                	jmp    f0102aac <strncmp+0x41>
		n--, p++, q++;
	if (n == 0)
		return 0;
f0102aa4:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0102aa9:	5b                   	pop    %ebx
f0102aaa:	5d                   	pop    %ebp
f0102aab:	c3                   	ret    
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0102aac:	0f b6 01             	movzbl (%ecx),%eax
f0102aaf:	0f b6 13             	movzbl (%ebx),%edx
f0102ab2:	29 d0                	sub    %edx,%eax
f0102ab4:	eb f3                	jmp    f0102aa9 <strncmp+0x3e>

f0102ab6 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0102ab6:	55                   	push   %ebp
f0102ab7:	89 e5                	mov    %esp,%ebp
f0102ab9:	8b 45 08             	mov    0x8(%ebp),%eax
f0102abc:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0102ac0:	0f b6 10             	movzbl (%eax),%edx
f0102ac3:	84 d2                	test   %dl,%dl
f0102ac5:	74 1c                	je     f0102ae3 <strchr+0x2d>
		if (*s == c)
f0102ac7:	38 ca                	cmp    %cl,%dl
f0102ac9:	75 09                	jne    f0102ad4 <strchr+0x1e>
f0102acb:	eb 1b                	jmp    f0102ae8 <strchr+0x32>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0102acd:	83 c0 01             	add    $0x1,%eax
		if (*s == c)
f0102ad0:	38 ca                	cmp    %cl,%dl
f0102ad2:	74 14                	je     f0102ae8 <strchr+0x32>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0102ad4:	0f b6 50 01          	movzbl 0x1(%eax),%edx
f0102ad8:	84 d2                	test   %dl,%dl
f0102ada:	75 f1                	jne    f0102acd <strchr+0x17>
		if (*s == c)
			return (char *) s;
	return 0;
f0102adc:	b8 00 00 00 00       	mov    $0x0,%eax
f0102ae1:	eb 05                	jmp    f0102ae8 <strchr+0x32>
f0102ae3:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102ae8:	5d                   	pop    %ebp
f0102ae9:	c3                   	ret    

f0102aea <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0102aea:	55                   	push   %ebp
f0102aeb:	89 e5                	mov    %esp,%ebp
f0102aed:	8b 45 08             	mov    0x8(%ebp),%eax
f0102af0:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0102af4:	0f b6 10             	movzbl (%eax),%edx
f0102af7:	84 d2                	test   %dl,%dl
f0102af9:	74 14                	je     f0102b0f <strfind+0x25>
		if (*s == c)
f0102afb:	38 ca                	cmp    %cl,%dl
f0102afd:	75 06                	jne    f0102b05 <strfind+0x1b>
f0102aff:	eb 0e                	jmp    f0102b0f <strfind+0x25>
f0102b01:	38 ca                	cmp    %cl,%dl
f0102b03:	74 0a                	je     f0102b0f <strfind+0x25>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f0102b05:	83 c0 01             	add    $0x1,%eax
f0102b08:	0f b6 10             	movzbl (%eax),%edx
f0102b0b:	84 d2                	test   %dl,%dl
f0102b0d:	75 f2                	jne    f0102b01 <strfind+0x17>
		if (*s == c)
			break;
	return (char *) s;
}
f0102b0f:	5d                   	pop    %ebp
f0102b10:	c3                   	ret    

f0102b11 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0102b11:	55                   	push   %ebp
f0102b12:	89 e5                	mov    %esp,%ebp
f0102b14:	83 ec 0c             	sub    $0xc,%esp
f0102b17:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0102b1a:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0102b1d:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0102b20:	8b 7d 08             	mov    0x8(%ebp),%edi
f0102b23:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102b26:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0102b29:	85 c9                	test   %ecx,%ecx
f0102b2b:	74 30                	je     f0102b5d <memset+0x4c>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0102b2d:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0102b33:	75 25                	jne    f0102b5a <memset+0x49>
f0102b35:	f6 c1 03             	test   $0x3,%cl
f0102b38:	75 20                	jne    f0102b5a <memset+0x49>
		c &= 0xFF;
f0102b3a:	0f b6 d0             	movzbl %al,%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0102b3d:	89 d3                	mov    %edx,%ebx
f0102b3f:	c1 e3 08             	shl    $0x8,%ebx
f0102b42:	89 d6                	mov    %edx,%esi
f0102b44:	c1 e6 18             	shl    $0x18,%esi
f0102b47:	89 d0                	mov    %edx,%eax
f0102b49:	c1 e0 10             	shl    $0x10,%eax
f0102b4c:	09 f0                	or     %esi,%eax
f0102b4e:	09 d0                	or     %edx,%eax
f0102b50:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0102b52:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f0102b55:	fc                   	cld    
f0102b56:	f3 ab                	rep stos %eax,%es:(%edi)
f0102b58:	eb 03                	jmp    f0102b5d <memset+0x4c>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0102b5a:	fc                   	cld    
f0102b5b:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0102b5d:	89 f8                	mov    %edi,%eax
f0102b5f:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0102b62:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0102b65:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0102b68:	89 ec                	mov    %ebp,%esp
f0102b6a:	5d                   	pop    %ebp
f0102b6b:	c3                   	ret    

f0102b6c <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0102b6c:	55                   	push   %ebp
f0102b6d:	89 e5                	mov    %esp,%ebp
f0102b6f:	83 ec 08             	sub    $0x8,%esp
f0102b72:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0102b75:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0102b78:	8b 45 08             	mov    0x8(%ebp),%eax
f0102b7b:	8b 75 0c             	mov    0xc(%ebp),%esi
f0102b7e:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0102b81:	39 c6                	cmp    %eax,%esi
f0102b83:	73 36                	jae    f0102bbb <memmove+0x4f>
f0102b85:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0102b88:	39 d0                	cmp    %edx,%eax
f0102b8a:	73 2f                	jae    f0102bbb <memmove+0x4f>
		s += n;
		d += n;
f0102b8c:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0102b8f:	f6 c2 03             	test   $0x3,%dl
f0102b92:	75 1b                	jne    f0102baf <memmove+0x43>
f0102b94:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0102b9a:	75 13                	jne    f0102baf <memmove+0x43>
f0102b9c:	f6 c1 03             	test   $0x3,%cl
f0102b9f:	75 0e                	jne    f0102baf <memmove+0x43>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0102ba1:	83 ef 04             	sub    $0x4,%edi
f0102ba4:	8d 72 fc             	lea    -0x4(%edx),%esi
f0102ba7:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f0102baa:	fd                   	std    
f0102bab:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0102bad:	eb 09                	jmp    f0102bb8 <memmove+0x4c>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0102baf:	83 ef 01             	sub    $0x1,%edi
f0102bb2:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0102bb5:	fd                   	std    
f0102bb6:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0102bb8:	fc                   	cld    
f0102bb9:	eb 20                	jmp    f0102bdb <memmove+0x6f>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0102bbb:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0102bc1:	75 13                	jne    f0102bd6 <memmove+0x6a>
f0102bc3:	a8 03                	test   $0x3,%al
f0102bc5:	75 0f                	jne    f0102bd6 <memmove+0x6a>
f0102bc7:	f6 c1 03             	test   $0x3,%cl
f0102bca:	75 0a                	jne    f0102bd6 <memmove+0x6a>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0102bcc:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f0102bcf:	89 c7                	mov    %eax,%edi
f0102bd1:	fc                   	cld    
f0102bd2:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0102bd4:	eb 05                	jmp    f0102bdb <memmove+0x6f>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0102bd6:	89 c7                	mov    %eax,%edi
f0102bd8:	fc                   	cld    
f0102bd9:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0102bdb:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0102bde:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0102be1:	89 ec                	mov    %ebp,%esp
f0102be3:	5d                   	pop    %ebp
f0102be4:	c3                   	ret    

f0102be5 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0102be5:	55                   	push   %ebp
f0102be6:	89 e5                	mov    %esp,%ebp
f0102be8:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0102beb:	8b 45 10             	mov    0x10(%ebp),%eax
f0102bee:	89 44 24 08          	mov    %eax,0x8(%esp)
f0102bf2:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102bf5:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102bf9:	8b 45 08             	mov    0x8(%ebp),%eax
f0102bfc:	89 04 24             	mov    %eax,(%esp)
f0102bff:	e8 68 ff ff ff       	call   f0102b6c <memmove>
}
f0102c04:	c9                   	leave  
f0102c05:	c3                   	ret    

f0102c06 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0102c06:	55                   	push   %ebp
f0102c07:	89 e5                	mov    %esp,%ebp
f0102c09:	57                   	push   %edi
f0102c0a:	56                   	push   %esi
f0102c0b:	53                   	push   %ebx
f0102c0c:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0102c0f:	8b 75 0c             	mov    0xc(%ebp),%esi
f0102c12:	8b 7d 10             	mov    0x10(%ebp),%edi
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0102c15:	b8 00 00 00 00       	mov    $0x0,%eax
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0102c1a:	85 ff                	test   %edi,%edi
f0102c1c:	74 37                	je     f0102c55 <memcmp+0x4f>
		if (*s1 != *s2)
f0102c1e:	0f b6 03             	movzbl (%ebx),%eax
f0102c21:	0f b6 0e             	movzbl (%esi),%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0102c24:	83 ef 01             	sub    $0x1,%edi
f0102c27:	ba 00 00 00 00       	mov    $0x0,%edx
		if (*s1 != *s2)
f0102c2c:	38 c8                	cmp    %cl,%al
f0102c2e:	74 1c                	je     f0102c4c <memcmp+0x46>
f0102c30:	eb 10                	jmp    f0102c42 <memcmp+0x3c>
f0102c32:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
f0102c37:	83 c2 01             	add    $0x1,%edx
f0102c3a:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
f0102c3e:	38 c8                	cmp    %cl,%al
f0102c40:	74 0a                	je     f0102c4c <memcmp+0x46>
			return (int) *s1 - (int) *s2;
f0102c42:	0f b6 c0             	movzbl %al,%eax
f0102c45:	0f b6 c9             	movzbl %cl,%ecx
f0102c48:	29 c8                	sub    %ecx,%eax
f0102c4a:	eb 09                	jmp    f0102c55 <memcmp+0x4f>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0102c4c:	39 fa                	cmp    %edi,%edx
f0102c4e:	75 e2                	jne    f0102c32 <memcmp+0x2c>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0102c50:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0102c55:	5b                   	pop    %ebx
f0102c56:	5e                   	pop    %esi
f0102c57:	5f                   	pop    %edi
f0102c58:	5d                   	pop    %ebp
f0102c59:	c3                   	ret    

f0102c5a <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0102c5a:	55                   	push   %ebp
f0102c5b:	89 e5                	mov    %esp,%ebp
f0102c5d:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0102c60:	89 c2                	mov    %eax,%edx
f0102c62:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0102c65:	39 d0                	cmp    %edx,%eax
f0102c67:	73 19                	jae    f0102c82 <memfind+0x28>
		if (*(const unsigned char *) s == (unsigned char) c)
f0102c69:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
f0102c6d:	38 08                	cmp    %cl,(%eax)
f0102c6f:	75 06                	jne    f0102c77 <memfind+0x1d>
f0102c71:	eb 0f                	jmp    f0102c82 <memfind+0x28>
f0102c73:	38 08                	cmp    %cl,(%eax)
f0102c75:	74 0b                	je     f0102c82 <memfind+0x28>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0102c77:	83 c0 01             	add    $0x1,%eax
f0102c7a:	39 d0                	cmp    %edx,%eax
f0102c7c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0102c80:	75 f1                	jne    f0102c73 <memfind+0x19>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0102c82:	5d                   	pop    %ebp
f0102c83:	c3                   	ret    

f0102c84 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0102c84:	55                   	push   %ebp
f0102c85:	89 e5                	mov    %esp,%ebp
f0102c87:	57                   	push   %edi
f0102c88:	56                   	push   %esi
f0102c89:	53                   	push   %ebx
f0102c8a:	8b 55 08             	mov    0x8(%ebp),%edx
f0102c8d:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0102c90:	0f b6 02             	movzbl (%edx),%eax
f0102c93:	3c 20                	cmp    $0x20,%al
f0102c95:	74 04                	je     f0102c9b <strtol+0x17>
f0102c97:	3c 09                	cmp    $0x9,%al
f0102c99:	75 0e                	jne    f0102ca9 <strtol+0x25>
		s++;
f0102c9b:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0102c9e:	0f b6 02             	movzbl (%edx),%eax
f0102ca1:	3c 20                	cmp    $0x20,%al
f0102ca3:	74 f6                	je     f0102c9b <strtol+0x17>
f0102ca5:	3c 09                	cmp    $0x9,%al
f0102ca7:	74 f2                	je     f0102c9b <strtol+0x17>
		s++;

	// plus/minus sign
	if (*s == '+')
f0102ca9:	3c 2b                	cmp    $0x2b,%al
f0102cab:	75 0a                	jne    f0102cb7 <strtol+0x33>
		s++;
f0102cad:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0102cb0:	bf 00 00 00 00       	mov    $0x0,%edi
f0102cb5:	eb 10                	jmp    f0102cc7 <strtol+0x43>
f0102cb7:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0102cbc:	3c 2d                	cmp    $0x2d,%al
f0102cbe:	75 07                	jne    f0102cc7 <strtol+0x43>
		s++, neg = 1;
f0102cc0:	83 c2 01             	add    $0x1,%edx
f0102cc3:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0102cc7:	85 db                	test   %ebx,%ebx
f0102cc9:	0f 94 c0             	sete   %al
f0102ccc:	74 05                	je     f0102cd3 <strtol+0x4f>
f0102cce:	83 fb 10             	cmp    $0x10,%ebx
f0102cd1:	75 15                	jne    f0102ce8 <strtol+0x64>
f0102cd3:	80 3a 30             	cmpb   $0x30,(%edx)
f0102cd6:	75 10                	jne    f0102ce8 <strtol+0x64>
f0102cd8:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0102cdc:	75 0a                	jne    f0102ce8 <strtol+0x64>
		s += 2, base = 16;
f0102cde:	83 c2 02             	add    $0x2,%edx
f0102ce1:	bb 10 00 00 00       	mov    $0x10,%ebx
f0102ce6:	eb 13                	jmp    f0102cfb <strtol+0x77>
	else if (base == 0 && s[0] == '0')
f0102ce8:	84 c0                	test   %al,%al
f0102cea:	74 0f                	je     f0102cfb <strtol+0x77>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0102cec:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0102cf1:	80 3a 30             	cmpb   $0x30,(%edx)
f0102cf4:	75 05                	jne    f0102cfb <strtol+0x77>
		s++, base = 8;
f0102cf6:	83 c2 01             	add    $0x1,%edx
f0102cf9:	b3 08                	mov    $0x8,%bl
	else if (base == 0)
		base = 10;
f0102cfb:	b8 00 00 00 00       	mov    $0x0,%eax
f0102d00:	89 de                	mov    %ebx,%esi

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0102d02:	0f b6 0a             	movzbl (%edx),%ecx
f0102d05:	8d 59 d0             	lea    -0x30(%ecx),%ebx
f0102d08:	80 fb 09             	cmp    $0x9,%bl
f0102d0b:	77 08                	ja     f0102d15 <strtol+0x91>
			dig = *s - '0';
f0102d0d:	0f be c9             	movsbl %cl,%ecx
f0102d10:	83 e9 30             	sub    $0x30,%ecx
f0102d13:	eb 1e                	jmp    f0102d33 <strtol+0xaf>
		else if (*s >= 'a' && *s <= 'z')
f0102d15:	8d 59 9f             	lea    -0x61(%ecx),%ebx
f0102d18:	80 fb 19             	cmp    $0x19,%bl
f0102d1b:	77 08                	ja     f0102d25 <strtol+0xa1>
			dig = *s - 'a' + 10;
f0102d1d:	0f be c9             	movsbl %cl,%ecx
f0102d20:	83 e9 57             	sub    $0x57,%ecx
f0102d23:	eb 0e                	jmp    f0102d33 <strtol+0xaf>
		else if (*s >= 'A' && *s <= 'Z')
f0102d25:	8d 59 bf             	lea    -0x41(%ecx),%ebx
f0102d28:	80 fb 19             	cmp    $0x19,%bl
f0102d2b:	77 14                	ja     f0102d41 <strtol+0xbd>
			dig = *s - 'A' + 10;
f0102d2d:	0f be c9             	movsbl %cl,%ecx
f0102d30:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0102d33:	39 f1                	cmp    %esi,%ecx
f0102d35:	7d 0e                	jge    f0102d45 <strtol+0xc1>
			break;
		s++, val = (val * base) + dig;
f0102d37:	83 c2 01             	add    $0x1,%edx
f0102d3a:	0f af c6             	imul   %esi,%eax
f0102d3d:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
f0102d3f:	eb c1                	jmp    f0102d02 <strtol+0x7e>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
f0102d41:	89 c1                	mov    %eax,%ecx
f0102d43:	eb 02                	jmp    f0102d47 <strtol+0xc3>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0102d45:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
f0102d47:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0102d4b:	74 05                	je     f0102d52 <strtol+0xce>
		*endptr = (char *) s;
f0102d4d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0102d50:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
f0102d52:	89 ca                	mov    %ecx,%edx
f0102d54:	f7 da                	neg    %edx
f0102d56:	85 ff                	test   %edi,%edi
f0102d58:	0f 45 c2             	cmovne %edx,%eax
}
f0102d5b:	5b                   	pop    %ebx
f0102d5c:	5e                   	pop    %esi
f0102d5d:	5f                   	pop    %edi
f0102d5e:	5d                   	pop    %ebp
f0102d5f:	c3                   	ret    

f0102d60 <__udivdi3>:
f0102d60:	83 ec 1c             	sub    $0x1c,%esp
f0102d63:	89 7c 24 14          	mov    %edi,0x14(%esp)
f0102d67:	8b 7c 24 2c          	mov    0x2c(%esp),%edi
f0102d6b:	8b 44 24 20          	mov    0x20(%esp),%eax
f0102d6f:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0102d73:	89 74 24 10          	mov    %esi,0x10(%esp)
f0102d77:	8b 74 24 24          	mov    0x24(%esp),%esi
f0102d7b:	85 ff                	test   %edi,%edi
f0102d7d:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f0102d81:	89 44 24 08          	mov    %eax,0x8(%esp)
f0102d85:	89 cd                	mov    %ecx,%ebp
f0102d87:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102d8b:	75 33                	jne    f0102dc0 <__udivdi3+0x60>
f0102d8d:	39 f1                	cmp    %esi,%ecx
f0102d8f:	77 57                	ja     f0102de8 <__udivdi3+0x88>
f0102d91:	85 c9                	test   %ecx,%ecx
f0102d93:	75 0b                	jne    f0102da0 <__udivdi3+0x40>
f0102d95:	b8 01 00 00 00       	mov    $0x1,%eax
f0102d9a:	31 d2                	xor    %edx,%edx
f0102d9c:	f7 f1                	div    %ecx
f0102d9e:	89 c1                	mov    %eax,%ecx
f0102da0:	89 f0                	mov    %esi,%eax
f0102da2:	31 d2                	xor    %edx,%edx
f0102da4:	f7 f1                	div    %ecx
f0102da6:	89 c6                	mov    %eax,%esi
f0102da8:	8b 44 24 04          	mov    0x4(%esp),%eax
f0102dac:	f7 f1                	div    %ecx
f0102dae:	89 f2                	mov    %esi,%edx
f0102db0:	8b 74 24 10          	mov    0x10(%esp),%esi
f0102db4:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0102db8:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0102dbc:	83 c4 1c             	add    $0x1c,%esp
f0102dbf:	c3                   	ret    
f0102dc0:	31 d2                	xor    %edx,%edx
f0102dc2:	31 c0                	xor    %eax,%eax
f0102dc4:	39 f7                	cmp    %esi,%edi
f0102dc6:	77 e8                	ja     f0102db0 <__udivdi3+0x50>
f0102dc8:	0f bd cf             	bsr    %edi,%ecx
f0102dcb:	83 f1 1f             	xor    $0x1f,%ecx
f0102dce:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0102dd2:	75 2c                	jne    f0102e00 <__udivdi3+0xa0>
f0102dd4:	3b 6c 24 08          	cmp    0x8(%esp),%ebp
f0102dd8:	76 04                	jbe    f0102dde <__udivdi3+0x7e>
f0102dda:	39 f7                	cmp    %esi,%edi
f0102ddc:	73 d2                	jae    f0102db0 <__udivdi3+0x50>
f0102dde:	31 d2                	xor    %edx,%edx
f0102de0:	b8 01 00 00 00       	mov    $0x1,%eax
f0102de5:	eb c9                	jmp    f0102db0 <__udivdi3+0x50>
f0102de7:	90                   	nop
f0102de8:	89 f2                	mov    %esi,%edx
f0102dea:	f7 f1                	div    %ecx
f0102dec:	31 d2                	xor    %edx,%edx
f0102dee:	8b 74 24 10          	mov    0x10(%esp),%esi
f0102df2:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0102df6:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0102dfa:	83 c4 1c             	add    $0x1c,%esp
f0102dfd:	c3                   	ret    
f0102dfe:	66 90                	xchg   %ax,%ax
f0102e00:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0102e05:	b8 20 00 00 00       	mov    $0x20,%eax
f0102e0a:	89 ea                	mov    %ebp,%edx
f0102e0c:	2b 44 24 04          	sub    0x4(%esp),%eax
f0102e10:	d3 e7                	shl    %cl,%edi
f0102e12:	89 c1                	mov    %eax,%ecx
f0102e14:	d3 ea                	shr    %cl,%edx
f0102e16:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0102e1b:	09 fa                	or     %edi,%edx
f0102e1d:	89 f7                	mov    %esi,%edi
f0102e1f:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0102e23:	89 f2                	mov    %esi,%edx
f0102e25:	8b 74 24 08          	mov    0x8(%esp),%esi
f0102e29:	d3 e5                	shl    %cl,%ebp
f0102e2b:	89 c1                	mov    %eax,%ecx
f0102e2d:	d3 ef                	shr    %cl,%edi
f0102e2f:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0102e34:	d3 e2                	shl    %cl,%edx
f0102e36:	89 c1                	mov    %eax,%ecx
f0102e38:	d3 ee                	shr    %cl,%esi
f0102e3a:	09 d6                	or     %edx,%esi
f0102e3c:	89 fa                	mov    %edi,%edx
f0102e3e:	89 f0                	mov    %esi,%eax
f0102e40:	f7 74 24 0c          	divl   0xc(%esp)
f0102e44:	89 d7                	mov    %edx,%edi
f0102e46:	89 c6                	mov    %eax,%esi
f0102e48:	f7 e5                	mul    %ebp
f0102e4a:	39 d7                	cmp    %edx,%edi
f0102e4c:	72 22                	jb     f0102e70 <__udivdi3+0x110>
f0102e4e:	8b 6c 24 08          	mov    0x8(%esp),%ebp
f0102e52:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0102e57:	d3 e5                	shl    %cl,%ebp
f0102e59:	39 c5                	cmp    %eax,%ebp
f0102e5b:	73 04                	jae    f0102e61 <__udivdi3+0x101>
f0102e5d:	39 d7                	cmp    %edx,%edi
f0102e5f:	74 0f                	je     f0102e70 <__udivdi3+0x110>
f0102e61:	89 f0                	mov    %esi,%eax
f0102e63:	31 d2                	xor    %edx,%edx
f0102e65:	e9 46 ff ff ff       	jmp    f0102db0 <__udivdi3+0x50>
f0102e6a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0102e70:	8d 46 ff             	lea    -0x1(%esi),%eax
f0102e73:	31 d2                	xor    %edx,%edx
f0102e75:	8b 74 24 10          	mov    0x10(%esp),%esi
f0102e79:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0102e7d:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0102e81:	83 c4 1c             	add    $0x1c,%esp
f0102e84:	c3                   	ret    
	...

f0102e90 <__umoddi3>:
f0102e90:	83 ec 1c             	sub    $0x1c,%esp
f0102e93:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f0102e97:	8b 6c 24 2c          	mov    0x2c(%esp),%ebp
f0102e9b:	8b 44 24 20          	mov    0x20(%esp),%eax
f0102e9f:	89 74 24 10          	mov    %esi,0x10(%esp)
f0102ea3:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0102ea7:	8b 74 24 24          	mov    0x24(%esp),%esi
f0102eab:	85 ed                	test   %ebp,%ebp
f0102ead:	89 7c 24 14          	mov    %edi,0x14(%esp)
f0102eb1:	89 44 24 08          	mov    %eax,0x8(%esp)
f0102eb5:	89 cf                	mov    %ecx,%edi
f0102eb7:	89 04 24             	mov    %eax,(%esp)
f0102eba:	89 f2                	mov    %esi,%edx
f0102ebc:	75 1a                	jne    f0102ed8 <__umoddi3+0x48>
f0102ebe:	39 f1                	cmp    %esi,%ecx
f0102ec0:	76 4e                	jbe    f0102f10 <__umoddi3+0x80>
f0102ec2:	f7 f1                	div    %ecx
f0102ec4:	89 d0                	mov    %edx,%eax
f0102ec6:	31 d2                	xor    %edx,%edx
f0102ec8:	8b 74 24 10          	mov    0x10(%esp),%esi
f0102ecc:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0102ed0:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0102ed4:	83 c4 1c             	add    $0x1c,%esp
f0102ed7:	c3                   	ret    
f0102ed8:	39 f5                	cmp    %esi,%ebp
f0102eda:	77 54                	ja     f0102f30 <__umoddi3+0xa0>
f0102edc:	0f bd c5             	bsr    %ebp,%eax
f0102edf:	83 f0 1f             	xor    $0x1f,%eax
f0102ee2:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102ee6:	75 60                	jne    f0102f48 <__umoddi3+0xb8>
f0102ee8:	3b 0c 24             	cmp    (%esp),%ecx
f0102eeb:	0f 87 07 01 00 00    	ja     f0102ff8 <__umoddi3+0x168>
f0102ef1:	89 f2                	mov    %esi,%edx
f0102ef3:	8b 34 24             	mov    (%esp),%esi
f0102ef6:	29 ce                	sub    %ecx,%esi
f0102ef8:	19 ea                	sbb    %ebp,%edx
f0102efa:	89 34 24             	mov    %esi,(%esp)
f0102efd:	8b 04 24             	mov    (%esp),%eax
f0102f00:	8b 74 24 10          	mov    0x10(%esp),%esi
f0102f04:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0102f08:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0102f0c:	83 c4 1c             	add    $0x1c,%esp
f0102f0f:	c3                   	ret    
f0102f10:	85 c9                	test   %ecx,%ecx
f0102f12:	75 0b                	jne    f0102f1f <__umoddi3+0x8f>
f0102f14:	b8 01 00 00 00       	mov    $0x1,%eax
f0102f19:	31 d2                	xor    %edx,%edx
f0102f1b:	f7 f1                	div    %ecx
f0102f1d:	89 c1                	mov    %eax,%ecx
f0102f1f:	89 f0                	mov    %esi,%eax
f0102f21:	31 d2                	xor    %edx,%edx
f0102f23:	f7 f1                	div    %ecx
f0102f25:	8b 04 24             	mov    (%esp),%eax
f0102f28:	f7 f1                	div    %ecx
f0102f2a:	eb 98                	jmp    f0102ec4 <__umoddi3+0x34>
f0102f2c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0102f30:	89 f2                	mov    %esi,%edx
f0102f32:	8b 74 24 10          	mov    0x10(%esp),%esi
f0102f36:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0102f3a:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0102f3e:	83 c4 1c             	add    $0x1c,%esp
f0102f41:	c3                   	ret    
f0102f42:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0102f48:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0102f4d:	89 e8                	mov    %ebp,%eax
f0102f4f:	bd 20 00 00 00       	mov    $0x20,%ebp
f0102f54:	2b 6c 24 04          	sub    0x4(%esp),%ebp
f0102f58:	89 fa                	mov    %edi,%edx
f0102f5a:	d3 e0                	shl    %cl,%eax
f0102f5c:	89 e9                	mov    %ebp,%ecx
f0102f5e:	d3 ea                	shr    %cl,%edx
f0102f60:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0102f65:	09 c2                	or     %eax,%edx
f0102f67:	8b 44 24 08          	mov    0x8(%esp),%eax
f0102f6b:	89 14 24             	mov    %edx,(%esp)
f0102f6e:	89 f2                	mov    %esi,%edx
f0102f70:	d3 e7                	shl    %cl,%edi
f0102f72:	89 e9                	mov    %ebp,%ecx
f0102f74:	d3 ea                	shr    %cl,%edx
f0102f76:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0102f7b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0102f7f:	d3 e6                	shl    %cl,%esi
f0102f81:	89 e9                	mov    %ebp,%ecx
f0102f83:	d3 e8                	shr    %cl,%eax
f0102f85:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0102f8a:	09 f0                	or     %esi,%eax
f0102f8c:	8b 74 24 08          	mov    0x8(%esp),%esi
f0102f90:	f7 34 24             	divl   (%esp)
f0102f93:	d3 e6                	shl    %cl,%esi
f0102f95:	89 74 24 08          	mov    %esi,0x8(%esp)
f0102f99:	89 d6                	mov    %edx,%esi
f0102f9b:	f7 e7                	mul    %edi
f0102f9d:	39 d6                	cmp    %edx,%esi
f0102f9f:	89 c1                	mov    %eax,%ecx
f0102fa1:	89 d7                	mov    %edx,%edi
f0102fa3:	72 3f                	jb     f0102fe4 <__umoddi3+0x154>
f0102fa5:	39 44 24 08          	cmp    %eax,0x8(%esp)
f0102fa9:	72 35                	jb     f0102fe0 <__umoddi3+0x150>
f0102fab:	8b 44 24 08          	mov    0x8(%esp),%eax
f0102faf:	29 c8                	sub    %ecx,%eax
f0102fb1:	19 fe                	sbb    %edi,%esi
f0102fb3:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0102fb8:	89 f2                	mov    %esi,%edx
f0102fba:	d3 e8                	shr    %cl,%eax
f0102fbc:	89 e9                	mov    %ebp,%ecx
f0102fbe:	d3 e2                	shl    %cl,%edx
f0102fc0:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0102fc5:	09 d0                	or     %edx,%eax
f0102fc7:	89 f2                	mov    %esi,%edx
f0102fc9:	d3 ea                	shr    %cl,%edx
f0102fcb:	8b 74 24 10          	mov    0x10(%esp),%esi
f0102fcf:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0102fd3:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0102fd7:	83 c4 1c             	add    $0x1c,%esp
f0102fda:	c3                   	ret    
f0102fdb:	90                   	nop
f0102fdc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0102fe0:	39 d6                	cmp    %edx,%esi
f0102fe2:	75 c7                	jne    f0102fab <__umoddi3+0x11b>
f0102fe4:	89 d7                	mov    %edx,%edi
f0102fe6:	89 c1                	mov    %eax,%ecx
f0102fe8:	2b 4c 24 0c          	sub    0xc(%esp),%ecx
f0102fec:	1b 3c 24             	sbb    (%esp),%edi
f0102fef:	eb ba                	jmp    f0102fab <__umoddi3+0x11b>
f0102ff1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0102ff8:	39 f5                	cmp    %esi,%ebp
f0102ffa:	0f 82 f1 fe ff ff    	jb     f0102ef1 <__umoddi3+0x61>
f0103000:	e9 f8 fe ff ff       	jmp    f0102efd <__umoddi3+0x6d>
