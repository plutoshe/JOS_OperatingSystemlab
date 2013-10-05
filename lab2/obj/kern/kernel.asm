
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
f0100015:	b8 00 70 11 00       	mov    $0x117000,%eax
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
f0100034:	bc 00 70 11 f0       	mov    $0xf0117000,%esp

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
f0100046:	b8 90 99 11 f0       	mov    $0xf0119990,%eax
f010004b:	2d 20 93 11 f0       	sub    $0xf0119320,%eax
f0100050:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100054:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010005b:	00 
f010005c:	c7 04 24 20 93 11 f0 	movl   $0xf0119320,(%esp)
f0100063:	e8 e9 40 00 00       	call   f0104151 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100068:	e8 97 04 00 00       	call   f0100504 <cons_init>
	cprintf("6828 decimal is %o octal!\n", 6828);
f010006d:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f0100074:	00 
f0100075:	c7 04 24 60 46 10 f0 	movl   $0xf0104660,(%esp)
f010007c:	e8 0d 35 00 00       	call   f010358e <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100081:	e8 27 19 00 00       	call   f01019ad <mem_init>
	// Test the stack backtrace function (lab 1 only)
//>>>>>>> lab1

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f0100086:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010008d:	e8 37 0f 00 00       	call   f0100fc9 <monitor>
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
f010009f:	83 3d 80 99 11 f0 00 	cmpl   $0x0,0xf0119980
f01000a6:	75 3d                	jne    f01000e5 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f01000a8:	89 35 80 99 11 f0    	mov    %esi,0xf0119980

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
f01000c1:	c7 04 24 7b 46 10 f0 	movl   $0xf010467b,(%esp)
f01000c8:	e8 c1 34 00 00       	call   f010358e <cprintf>
	vcprintf(fmt, ap);
f01000cd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01000d1:	89 34 24             	mov    %esi,(%esp)
f01000d4:	e8 82 34 00 00       	call   f010355b <vcprintf>
	cprintf("\n");
f01000d9:	c7 04 24 bc 58 10 f0 	movl   $0xf01058bc,(%esp)
f01000e0:	e8 a9 34 00 00       	call   f010358e <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000e5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000ec:	e8 d8 0e 00 00       	call   f0100fc9 <monitor>
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
f010010b:	c7 04 24 93 46 10 f0 	movl   $0xf0104693,(%esp)
f0100112:	e8 77 34 00 00       	call   f010358e <cprintf>
	vcprintf(fmt, ap);
f0100117:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010011b:	8b 45 10             	mov    0x10(%ebp),%eax
f010011e:	89 04 24             	mov    %eax,(%esp)
f0100121:	e8 35 34 00 00       	call   f010355b <vcprintf>
	cprintf("\n");
f0100126:	c7 04 24 bc 58 10 f0 	movl   $0xf01058bc,(%esp)
f010012d:	e8 5c 34 00 00       	call   f010358e <cprintf>
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
f0100179:	8b 15 44 95 11 f0    	mov    0xf0119544,%edx
f010017f:	88 82 40 93 11 f0    	mov    %al,-0xfee6cc0(%edx)
f0100185:	8d 42 01             	lea    0x1(%edx),%eax
		if (cons.wpos == CONSBUFSIZE)
f0100188:	3d 00 02 00 00       	cmp    $0x200,%eax
			cons.wpos = 0;
f010018d:	ba 00 00 00 00       	mov    $0x0,%edx
f0100192:	0f 44 c2             	cmove  %edx,%eax
f0100195:	a3 44 95 11 f0       	mov    %eax,0xf0119544
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
f010021c:	0f b7 15 00 90 11 f0 	movzwl 0xf0119000,%edx
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
f0100252:	0f b7 05 54 95 11 f0 	movzwl 0xf0119554,%eax
f0100259:	66 85 c0             	test   %ax,%ax
f010025c:	0f 84 e1 00 00 00    	je     f0100343 <cons_putc+0x19c>
			crt_pos--;
f0100262:	83 e8 01             	sub    $0x1,%eax
f0100265:	66 a3 54 95 11 f0    	mov    %ax,0xf0119554
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f010026b:	0f b7 c0             	movzwl %ax,%eax
f010026e:	b2 00                	mov    $0x0,%dl
f0100270:	83 ca 20             	or     $0x20,%edx
f0100273:	8b 0d 50 95 11 f0    	mov    0xf0119550,%ecx
f0100279:	66 89 14 41          	mov    %dx,(%ecx,%eax,2)
f010027d:	eb 77                	jmp    f01002f6 <cons_putc+0x14f>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f010027f:	66 83 05 54 95 11 f0 	addw   $0x50,0xf0119554
f0100286:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f0100287:	0f b7 05 54 95 11 f0 	movzwl 0xf0119554,%eax
f010028e:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100294:	c1 e8 16             	shr    $0x16,%eax
f0100297:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010029a:	c1 e0 04             	shl    $0x4,%eax
f010029d:	66 a3 54 95 11 f0    	mov    %ax,0xf0119554
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
f01002d9:	0f b7 05 54 95 11 f0 	movzwl 0xf0119554,%eax
f01002e0:	0f b7 d8             	movzwl %ax,%ebx
f01002e3:	8b 0d 50 95 11 f0    	mov    0xf0119550,%ecx
f01002e9:	66 89 14 59          	mov    %dx,(%ecx,%ebx,2)
f01002ed:	83 c0 01             	add    $0x1,%eax
f01002f0:	66 a3 54 95 11 f0    	mov    %ax,0xf0119554
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f01002f6:	66 81 3d 54 95 11 f0 	cmpw   $0x7cf,0xf0119554
f01002fd:	cf 07 
f01002ff:	76 42                	jbe    f0100343 <cons_putc+0x19c>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100301:	a1 50 95 11 f0       	mov    0xf0119550,%eax
f0100306:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f010030d:	00 
f010030e:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100314:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100318:	89 04 24             	mov    %eax,(%esp)
f010031b:	e8 8c 3e 00 00       	call   f01041ac <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100320:	8b 15 50 95 11 f0    	mov    0xf0119550,%edx
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
f010033b:	66 83 2d 54 95 11 f0 	subw   $0x50,0xf0119554
f0100342:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100343:	8b 0d 4c 95 11 f0    	mov    0xf011954c,%ecx
f0100349:	b8 0e 00 00 00       	mov    $0xe,%eax
f010034e:	89 ca                	mov    %ecx,%edx
f0100350:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100351:	0f b7 35 54 95 11 f0 	movzwl 0xf0119554,%esi
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
f010039c:	83 0d 48 95 11 f0 40 	orl    $0x40,0xf0119548
		return 0;
f01003a3:	bb 00 00 00 00       	mov    $0x0,%ebx
f01003a8:	e9 c4 00 00 00       	jmp    f0100471 <kbd_proc_data+0xf8>
	} else if (data & 0x80) {
f01003ad:	84 c0                	test   %al,%al
f01003af:	79 37                	jns    f01003e8 <kbd_proc_data+0x6f>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01003b1:	8b 0d 48 95 11 f0    	mov    0xf0119548,%ecx
f01003b7:	89 cb                	mov    %ecx,%ebx
f01003b9:	83 e3 40             	and    $0x40,%ebx
f01003bc:	83 e0 7f             	and    $0x7f,%eax
f01003bf:	85 db                	test   %ebx,%ebx
f01003c1:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01003c4:	0f b6 d2             	movzbl %dl,%edx
f01003c7:	0f b6 82 e0 46 10 f0 	movzbl -0xfefb920(%edx),%eax
f01003ce:	83 c8 40             	or     $0x40,%eax
f01003d1:	0f b6 c0             	movzbl %al,%eax
f01003d4:	f7 d0                	not    %eax
f01003d6:	21 c1                	and    %eax,%ecx
f01003d8:	89 0d 48 95 11 f0    	mov    %ecx,0xf0119548
		return 0;
f01003de:	bb 00 00 00 00       	mov    $0x0,%ebx
f01003e3:	e9 89 00 00 00       	jmp    f0100471 <kbd_proc_data+0xf8>
	} else if (shift & E0ESC) {
f01003e8:	8b 0d 48 95 11 f0    	mov    0xf0119548,%ecx
f01003ee:	f6 c1 40             	test   $0x40,%cl
f01003f1:	74 0e                	je     f0100401 <kbd_proc_data+0x88>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f01003f3:	89 c2                	mov    %eax,%edx
f01003f5:	83 ca 80             	or     $0xffffff80,%edx
		shift &= ~E0ESC;
f01003f8:	83 e1 bf             	and    $0xffffffbf,%ecx
f01003fb:	89 0d 48 95 11 f0    	mov    %ecx,0xf0119548
	}

	shift |= shiftcode[data];
f0100401:	0f b6 d2             	movzbl %dl,%edx
f0100404:	0f b6 82 e0 46 10 f0 	movzbl -0xfefb920(%edx),%eax
f010040b:	0b 05 48 95 11 f0    	or     0xf0119548,%eax
	shift ^= togglecode[data];
f0100411:	0f b6 8a e0 47 10 f0 	movzbl -0xfefb820(%edx),%ecx
f0100418:	31 c8                	xor    %ecx,%eax
f010041a:	a3 48 95 11 f0       	mov    %eax,0xf0119548

	c = charcode[shift & (CTL | SHIFT)][data];
f010041f:	89 c1                	mov    %eax,%ecx
f0100421:	83 e1 03             	and    $0x3,%ecx
f0100424:	8b 0c 8d e0 48 10 f0 	mov    -0xfefb720(,%ecx,4),%ecx
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
f010045a:	c7 04 24 ad 46 10 f0 	movl   $0xf01046ad,(%esp)
f0100461:	e8 28 31 00 00       	call   f010358e <cprintf>
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
f010048c:	66 a3 00 90 11 f0    	mov    %ax,0xf0119000
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
f010049a:	80 3d 20 93 11 f0 00 	cmpb   $0x0,0xf0119320
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
f01004d1:	8b 15 40 95 11 f0    	mov    0xf0119540,%edx
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
f01004dc:	3b 15 44 95 11 f0    	cmp    0xf0119544,%edx
f01004e2:	74 1e                	je     f0100502 <cons_getc+0x41>
		c = cons.buf[cons.rpos++];
f01004e4:	0f b6 82 40 93 11 f0 	movzbl -0xfee6cc0(%edx),%eax
f01004eb:	83 c2 01             	add    $0x1,%edx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
f01004ee:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01004f4:	b9 00 00 00 00       	mov    $0x0,%ecx
f01004f9:	0f 44 d1             	cmove  %ecx,%edx
f01004fc:	89 15 40 95 11 f0    	mov    %edx,0xf0119540
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
f010052a:	c7 05 4c 95 11 f0 b4 	movl   $0x3b4,0xf011954c
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
f0100542:	c7 05 4c 95 11 f0 d4 	movl   $0x3d4,0xf011954c
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
f0100551:	8b 0d 4c 95 11 f0    	mov    0xf011954c,%ecx
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
f0100576:	89 35 50 95 11 f0    	mov    %esi,0xf0119550

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f010057c:	0f b6 d8             	movzbl %al,%ebx
f010057f:	09 df                	or     %ebx,%edi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f0100581:	66 89 3d 54 95 11 f0 	mov    %di,0xf0119554
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
f01005d4:	a2 20 93 11 f0       	mov    %al,0xf0119320
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
f01005e5:	c7 04 24 b9 46 10 f0 	movl   $0xf01046b9,(%esp)
f01005ec:	e8 9d 2f 00 00       	call   f010358e <cprintf>
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
f0100636:	c7 04 24 f0 48 10 f0 	movl   $0xf01048f0,(%esp)
f010063d:	e8 4c 2f 00 00       	call   f010358e <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100642:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f0100649:	00 
f010064a:	c7 04 24 20 4b 10 f0 	movl   $0xf0104b20,(%esp)
f0100651:	e8 38 2f 00 00       	call   f010358e <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100656:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f010065d:	00 
f010065e:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f0100665:	f0 
f0100666:	c7 04 24 48 4b 10 f0 	movl   $0xf0104b48,(%esp)
f010066d:	e8 1c 2f 00 00       	call   f010358e <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100672:	c7 44 24 08 45 46 10 	movl   $0x104645,0x8(%esp)
f0100679:	00 
f010067a:	c7 44 24 04 45 46 10 	movl   $0xf0104645,0x4(%esp)
f0100681:	f0 
f0100682:	c7 04 24 6c 4b 10 f0 	movl   $0xf0104b6c,(%esp)
f0100689:	e8 00 2f 00 00       	call   f010358e <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010068e:	c7 44 24 08 20 93 11 	movl   $0x119320,0x8(%esp)
f0100695:	00 
f0100696:	c7 44 24 04 20 93 11 	movl   $0xf0119320,0x4(%esp)
f010069d:	f0 
f010069e:	c7 04 24 90 4b 10 f0 	movl   $0xf0104b90,(%esp)
f01006a5:	e8 e4 2e 00 00       	call   f010358e <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006aa:	c7 44 24 08 90 99 11 	movl   $0x119990,0x8(%esp)
f01006b1:	00 
f01006b2:	c7 44 24 04 90 99 11 	movl   $0xf0119990,0x4(%esp)
f01006b9:	f0 
f01006ba:	c7 04 24 b4 4b 10 f0 	movl   $0xf0104bb4,(%esp)
f01006c1:	e8 c8 2e 00 00       	call   f010358e <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f01006c6:	b8 8f 9d 11 f0       	mov    $0xf0119d8f,%eax
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
f01006e7:	c7 04 24 d8 4b 10 f0 	movl   $0xf0104bd8,(%esp)
f01006ee:	e8 9b 2e 00 00       	call   f010358e <cprintf>
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
f0100706:	8b 83 c4 4e 10 f0    	mov    -0xfefb13c(%ebx),%eax
f010070c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100710:	8b 83 c0 4e 10 f0    	mov    -0xfefb140(%ebx),%eax
f0100716:	89 44 24 04          	mov    %eax,0x4(%esp)
f010071a:	c7 04 24 09 49 10 f0 	movl   $0xf0104909,(%esp)
f0100721:	e8 68 2e 00 00       	call   f010358e <cprintf>
f0100726:	83 c3 0c             	add    $0xc,%ebx
int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
	int i;

	for (i = 0; i < NCOMMANDS; i++)
f0100729:	83 fb 60             	cmp    $0x60,%ebx
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
f0100749:	c7 04 24 12 49 10 f0 	movl   $0xf0104912,(%esp)
f0100750:	e8 39 2e 00 00       	call   f010358e <cprintf>
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
f0100788:	c7 04 24 04 4c 10 f0 	movl   $0xf0104c04,(%esp)
f010078f:	e8 fa 2d 00 00       	call   f010358e <cprintf>
		struct Eipdebuginfo temp_debuginfo;
		debuginfo_eip((uintptr_t) eip, &temp_debuginfo);		
f0100794:	8d 45 d0             	lea    -0x30(%ebp),%eax
f0100797:	89 44 24 04          	mov    %eax,0x4(%esp)
f010079b:	89 3c 24             	mov    %edi,(%esp)
f010079e:	e8 e5 2e 00 00       	call   f0103688 <debuginfo_eip>
		cprintf("       %s:%d: ", temp_debuginfo.eip_file, temp_debuginfo.eip_line);
f01007a3:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01007a6:	89 44 24 08          	mov    %eax,0x8(%esp)
f01007aa:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01007ad:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007b1:	c7 04 24 23 49 10 f0 	movl   $0xf0104923,(%esp)
f01007b8:	e8 d1 2d 00 00       	call   f010358e <cprintf>
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
f01007d3:	c7 04 24 32 49 10 f0 	movl   $0xf0104932,(%esp)
f01007da:	e8 af 2d 00 00       	call   f010358e <cprintf>
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
f01007ee:	c7 04 24 35 49 10 f0 	movl   $0xf0104935,(%esp)
f01007f5:	e8 94 2d 00 00       	call   f010358e <cprintf>
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
f0100826:	c7 44 24 04 3a 49 10 	movl   $0xf010493a,0x4(%esp)
f010082d:	f0 
f010082e:	8b 46 08             	mov    0x8(%esi),%eax
f0100831:	89 04 24             	mov    %eax,(%esp)
f0100834:	e8 42 38 00 00       	call   f010407b <strcmp>
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
f0100846:	c7 44 24 04 3e 49 10 	movl   $0xf010493e,0x4(%esp)
f010084d:	f0 
f010084e:	8b 46 08             	mov    0x8(%esi),%eax
f0100851:	89 04 24             	mov    %eax,(%esp)
f0100854:	e8 22 38 00 00       	call   f010407b <strcmp>
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
f0100866:	c7 44 24 04 42 49 10 	movl   $0xf0104942,0x4(%esp)
f010086d:	f0 
f010086e:	8b 46 08             	mov    0x8(%esi),%eax
f0100871:	89 04 24             	mov    %eax,(%esp)
f0100874:	e8 02 38 00 00       	call   f010407b <strcmp>
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
f0100886:	c7 44 24 04 46 49 10 	movl   $0xf0104946,0x4(%esp)
f010088d:	f0 
f010088e:	8b 46 08             	mov    0x8(%esi),%eax
f0100891:	89 04 24             	mov    %eax,(%esp)
f0100894:	e8 e2 37 00 00       	call   f010407b <strcmp>
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
f01008a6:	c7 44 24 04 4a 49 10 	movl   $0xf010494a,0x4(%esp)
f01008ad:	f0 
f01008ae:	8b 46 08             	mov    0x8(%esi),%eax
f01008b1:	89 04 24             	mov    %eax,(%esp)
f01008b4:	e8 c2 37 00 00       	call   f010407b <strcmp>
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
f01008c6:	c7 44 24 04 4e 49 10 	movl   $0xf010494e,0x4(%esp)
f01008cd:	f0 
f01008ce:	8b 46 08             	mov    0x8(%esi),%eax
f01008d1:	89 04 24             	mov    %eax,(%esp)
f01008d4:	e8 a2 37 00 00       	call   f010407b <strcmp>
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
f01008e2:	c7 44 24 04 52 49 10 	movl   $0xf0104952,0x4(%esp)
f01008e9:	f0 
f01008ea:	8b 46 08             	mov    0x8(%esi),%eax
f01008ed:	89 04 24             	mov    %eax,(%esp)
f01008f0:	e8 86 37 00 00       	call   f010407b <strcmp>
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
f01008fe:	c7 44 24 04 56 49 10 	movl   $0xf0104956,0x4(%esp)
f0100905:	f0 
f0100906:	8b 46 08             	mov    0x8(%esi),%eax
f0100909:	89 04 24             	mov    %eax,(%esp)
f010090c:	e8 6a 37 00 00       	call   f010407b <strcmp>
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
f010091a:	c7 44 24 04 5a 49 10 	movl   $0xf010495a,0x4(%esp)
f0100921:	f0 
f0100922:	8b 46 08             	mov    0x8(%esi),%eax
f0100925:	89 04 24             	mov    %eax,(%esp)
f0100928:	e8 4e 37 00 00       	call   f010407b <strcmp>
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
f0100936:	c7 44 24 04 5e 49 10 	movl   $0xf010495e,0x4(%esp)
f010093d:	f0 
f010093e:	8b 46 08             	mov    0x8(%esi),%eax
f0100941:	89 04 24             	mov    %eax,(%esp)
f0100944:	e8 32 37 00 00       	call   f010407b <strcmp>
			ch_color1=COLOR_CYN
f0100949:	83 f8 01             	cmp    $0x1,%eax
f010094c:	19 ff                	sbb    %edi,%edi
f010094e:	83 e7 04             	and    $0x4,%edi
f0100951:	83 c7 07             	add    $0x7,%edi
	else ch_color1=COLOR_WHT;
	if(strcmp(argv[1],"blk")==0)
f0100954:	c7 44 24 04 3a 49 10 	movl   $0xf010493a,0x4(%esp)
f010095b:	f0 
f010095c:	8b 46 04             	mov    0x4(%esi),%eax
f010095f:	89 04 24             	mov    %eax,(%esp)
f0100962:	e8 14 37 00 00       	call   f010407b <strcmp>
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
f0100974:	c7 44 24 04 3e 49 10 	movl   $0xf010493e,0x4(%esp)
f010097b:	f0 
f010097c:	8b 46 04             	mov    0x4(%esi),%eax
f010097f:	89 04 24             	mov    %eax,(%esp)
f0100982:	e8 f4 36 00 00       	call   f010407b <strcmp>
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
f0100991:	c7 44 24 04 42 49 10 	movl   $0xf0104942,0x4(%esp)
f0100998:	f0 
f0100999:	8b 46 04             	mov    0x4(%esi),%eax
f010099c:	89 04 24             	mov    %eax,(%esp)
f010099f:	e8 d7 36 00 00       	call   f010407b <strcmp>
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
f01009ae:	c7 44 24 04 46 49 10 	movl   $0xf0104946,0x4(%esp)
f01009b5:	f0 
f01009b6:	8b 46 04             	mov    0x4(%esi),%eax
f01009b9:	89 04 24             	mov    %eax,(%esp)
f01009bc:	e8 ba 36 00 00       	call   f010407b <strcmp>
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
f01009cb:	c7 44 24 04 4a 49 10 	movl   $0xf010494a,0x4(%esp)
f01009d2:	f0 
f01009d3:	8b 46 04             	mov    0x4(%esi),%eax
f01009d6:	89 04 24             	mov    %eax,(%esp)
f01009d9:	e8 9d 36 00 00       	call   f010407b <strcmp>
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
f01009e8:	c7 44 24 04 4e 49 10 	movl   $0xf010494e,0x4(%esp)
f01009ef:	f0 
f01009f0:	8b 46 04             	mov    0x4(%esi),%eax
f01009f3:	89 04 24             	mov    %eax,(%esp)
f01009f6:	e8 80 36 00 00       	call   f010407b <strcmp>
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
f0100a01:	c7 44 24 04 52 49 10 	movl   $0xf0104952,0x4(%esp)
f0100a08:	f0 
f0100a09:	8b 46 04             	mov    0x4(%esi),%eax
f0100a0c:	89 04 24             	mov    %eax,(%esp)
f0100a0f:	e8 67 36 00 00       	call   f010407b <strcmp>
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
f0100a1a:	c7 44 24 04 56 49 10 	movl   $0xf0104956,0x4(%esp)
f0100a21:	f0 
f0100a22:	8b 46 04             	mov    0x4(%esi),%eax
f0100a25:	89 04 24             	mov    %eax,(%esp)
f0100a28:	e8 4e 36 00 00       	call   f010407b <strcmp>
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
f0100a33:	c7 44 24 04 5a 49 10 	movl   $0xf010495a,0x4(%esp)
f0100a3a:	f0 
f0100a3b:	8b 46 04             	mov    0x4(%esi),%eax
f0100a3e:	89 04 24             	mov    %eax,(%esp)
f0100a41:	e8 35 36 00 00       	call   f010407b <strcmp>
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
f0100a4c:	c7 44 24 04 5e 49 10 	movl   $0xf010495e,0x4(%esp)
f0100a53:	f0 
f0100a54:	8b 46 04             	mov    0x4(%esi),%eax
f0100a57:	89 04 24             	mov    %eax,(%esp)
f0100a5a:	e8 1c 36 00 00       	call   f010407b <strcmp>
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
f0100a84:	c7 04 24 38 4c 10 f0 	movl   $0xf0104c38,(%esp)
f0100a8b:	e8 fe 2a 00 00       	call   f010358e <cprintf>
	return 0;
}
f0100a90:	b8 00 00 00 00       	mov    $0x0,%eax
f0100a95:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0100a98:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0100a9b:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0100a9e:	89 ec                	mov    %ebp,%esp
f0100aa0:	5d                   	pop    %ebp
f0100aa1:	c3                   	ret    

f0100aa2 <printPermission>:

void printPermission(pte_t now) {
f0100aa2:	55                   	push   %ebp
f0100aa3:	89 e5                	mov    %esp,%ebp
f0100aa5:	53                   	push   %ebx
f0100aa6:	83 ec 14             	sub    $0x14,%esp
f0100aa9:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("PTE_U : %d ", ((now & PTE_U) != 0));
f0100aac:	f6 c3 04             	test   $0x4,%bl
f0100aaf:	0f 95 c0             	setne  %al
f0100ab2:	0f b6 c0             	movzbl %al,%eax
f0100ab5:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100ab9:	c7 04 24 62 49 10 f0 	movl   $0xf0104962,(%esp)
f0100ac0:	e8 c9 2a 00 00       	call   f010358e <cprintf>
	cprintf("PTE_W : %d ", ((now & PTE_W) != 0));
f0100ac5:	f6 c3 02             	test   $0x2,%bl
f0100ac8:	0f 95 c0             	setne  %al
f0100acb:	0f b6 c0             	movzbl %al,%eax
f0100ace:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100ad2:	c7 04 24 6e 49 10 f0 	movl   $0xf010496e,(%esp)
f0100ad9:	e8 b0 2a 00 00       	call   f010358e <cprintf>
	cprintf("PTE_P : %d ", ((now & PTE_P) != 0));
f0100ade:	83 e3 01             	and    $0x1,%ebx
f0100ae1:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100ae5:	c7 04 24 7a 49 10 f0 	movl   $0xf010497a,(%esp)
f0100aec:	e8 9d 2a 00 00       	call   f010358e <cprintf>
}
f0100af1:	83 c4 14             	add    $0x14,%esp
f0100af4:	5b                   	pop    %ebx
f0100af5:	5d                   	pop    %ebp
f0100af6:	c3                   	ret    

f0100af7 <xtoi>:

uint32_t xtoi(char* origin, bool* check) {
f0100af7:	55                   	push   %ebp
f0100af8:	89 e5                	mov    %esp,%ebp
f0100afa:	83 ec 38             	sub    $0x38,%esp
f0100afd:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0100b00:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0100b03:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0100b06:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0100b09:	8b 75 0c             	mov    0xc(%ebp),%esi
	uint32_t i = 0, temp = 0, len = strlen(origin);
f0100b0c:	89 1c 24             	mov    %ebx,(%esp)
f0100b0f:	e8 5c 34 00 00       	call   f0103f70 <strlen>
	*check = true;
f0100b14:	c6 06 01             	movb   $0x1,(%esi)
	if ((origin[0] != '0') || (origin[1] != 'x' && origin[1] != 'X')) 
f0100b17:	80 3b 30             	cmpb   $0x30,(%ebx)
f0100b1a:	75 1f                	jne    f0100b3b <xtoi+0x44>
f0100b1c:	0f b6 53 01          	movzbl 0x1(%ebx),%edx
f0100b20:	80 fa 78             	cmp    $0x78,%dl
f0100b23:	74 05                	je     f0100b2a <xtoi+0x33>
f0100b25:	80 fa 58             	cmp    $0x58,%dl
f0100b28:	75 11                	jne    f0100b3b <xtoi+0x44>
	{
		*check = false;
		return -1;
	}
	for (i = 2; i < len; i++) {
f0100b2a:	bf 00 00 00 00       	mov    $0x0,%edi
f0100b2f:	ba 02 00 00 00       	mov    $0x2,%edx
f0100b34:	83 f8 02             	cmp    $0x2,%eax
f0100b37:	77 0c                	ja     f0100b45 <xtoi+0x4e>
f0100b39:	eb 5d                	jmp    f0100b98 <xtoi+0xa1>
uint32_t xtoi(char* origin, bool* check) {
	uint32_t i = 0, temp = 0, len = strlen(origin);
	*check = true;
	if ((origin[0] != '0') || (origin[1] != 'x' && origin[1] != 'X')) 
	{
		*check = false;
f0100b3b:	c6 06 00             	movb   $0x0,(%esi)
		return -1;
f0100b3e:	bf ff ff ff ff       	mov    $0xffffffff,%edi
f0100b43:	eb 53                	jmp    f0100b98 <xtoi+0xa1>
f0100b45:	89 75 e4             	mov    %esi,-0x1c(%ebp)
f0100b48:	89 c6                	mov    %eax,%esi
	}
	for (i = 2; i < len; i++) {
		temp *= 16;
f0100b4a:	c1 e7 04             	shl    $0x4,%edi
		if (origin[i] >= '0' && origin[i] <= '9')
f0100b4d:	0f b6 04 13          	movzbl (%ebx,%edx,1),%eax
f0100b51:	8d 48 d0             	lea    -0x30(%eax),%ecx
f0100b54:	80 f9 09             	cmp    $0x9,%cl
f0100b57:	77 09                	ja     f0100b62 <xtoi+0x6b>
			temp += origin[i] - '0';
f0100b59:	0f be c0             	movsbl %al,%eax
f0100b5c:	8d 7c 07 d0          	lea    -0x30(%edi,%eax,1),%edi
f0100b60:	eb 2f                	jmp    f0100b91 <xtoi+0x9a>
		else if (origin[i] >= 'a' && origin[i] <= 'f')
f0100b62:	8d 48 9f             	lea    -0x61(%eax),%ecx
f0100b65:	80 f9 05             	cmp    $0x5,%cl
f0100b68:	77 09                	ja     f0100b73 <xtoi+0x7c>
			temp += origin[i] - 'a' + 10;
f0100b6a:	0f be c0             	movsbl %al,%eax
f0100b6d:	8d 7c 07 a9          	lea    -0x57(%edi,%eax,1),%edi
f0100b71:	eb 1e                	jmp    f0100b91 <xtoi+0x9a>
		else if (origin[i] >= 'A' && origin[i] <= 'F')
f0100b73:	8d 48 bf             	lea    -0x41(%eax),%ecx
f0100b76:	80 f9 05             	cmp    $0x5,%cl
f0100b79:	77 09                	ja     f0100b84 <xtoi+0x8d>
			temp += origin[i] - 'A' + 10;
f0100b7b:	0f be c0             	movsbl %al,%eax
f0100b7e:	8d 7c 07 c9          	lea    -0x37(%edi,%eax,1),%edi
f0100b82:	eb 0d                	jmp    f0100b91 <xtoi+0x9a>
f0100b84:	8b 75 e4             	mov    -0x1c(%ebp),%esi
		else {
			*check = false;
f0100b87:	c6 06 00             	movb   $0x0,(%esi)
			return -1;
f0100b8a:	bf ff ff ff ff       	mov    $0xffffffff,%edi
f0100b8f:	eb 07                	jmp    f0100b98 <xtoi+0xa1>
	if ((origin[0] != '0') || (origin[1] != 'x' && origin[1] != 'X')) 
	{
		*check = false;
		return -1;
	}
	for (i = 2; i < len; i++) {
f0100b91:	83 c2 01             	add    $0x1,%edx
f0100b94:	39 d6                	cmp    %edx,%esi
f0100b96:	75 b2                	jne    f0100b4a <xtoi+0x53>
			*check = false;
			return -1;
		}
	}
	return temp;
}
f0100b98:	89 f8                	mov    %edi,%eax
f0100b9a:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0100b9d:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0100ba0:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0100ba3:	89 ec                	mov    %ebp,%esp
f0100ba5:	5d                   	pop    %ebp
f0100ba6:	c3                   	ret    

f0100ba7 <pxtoi>:

bool pxtoi(uint32_t *va, char *origin) {
f0100ba7:	55                   	push   %ebp
f0100ba8:	89 e5                	mov    %esp,%ebp
f0100baa:	83 ec 28             	sub    $0x28,%esp
	bool check = true;
f0100bad:	c6 45 f7 01          	movb   $0x1,-0x9(%ebp)
	*va = xtoi(origin, &check);
f0100bb1:	8d 45 f7             	lea    -0x9(%ebp),%eax
f0100bb4:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100bb8:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100bbb:	89 04 24             	mov    %eax,(%esp)
f0100bbe:	e8 34 ff ff ff       	call   f0100af7 <xtoi>
f0100bc3:	8b 55 08             	mov    0x8(%ebp),%edx
f0100bc6:	89 02                	mov    %eax,(%edx)
	if (!check) {
		cprintf("Address typing error\n");
		return false;
	}
	return true;
f0100bc8:	b8 01 00 00 00       	mov    $0x1,%eax
}

bool pxtoi(uint32_t *va, char *origin) {
	bool check = true;
	*va = xtoi(origin, &check);
	if (!check) {
f0100bcd:	80 7d f7 00          	cmpb   $0x0,-0x9(%ebp)
f0100bd1:	75 11                	jne    f0100be4 <pxtoi+0x3d>
		cprintf("Address typing error\n");
f0100bd3:	c7 04 24 86 49 10 f0 	movl   $0xf0104986,(%esp)
f0100bda:	e8 af 29 00 00       	call   f010358e <cprintf>
		return false;
f0100bdf:	b8 00 00 00 00       	mov    $0x0,%eax
	}
	return true;
}
f0100be4:	c9                   	leave  
f0100be5:	c3                   	ret    

f0100be6 <mon_showmapping>:
	} else cprintf("invalid command\n");
	return 0;

}
int mon_showmapping(int argc, char **argv, struct Trapframe *tf) 
{
f0100be6:	55                   	push   %ebp
f0100be7:	89 e5                	mov    %esp,%ebp
f0100be9:	53                   	push   %ebx
f0100bea:	83 ec 24             	sub    $0x24,%esp
f0100bed:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	uintptr_t begin, end;
	if (!pxtoi(&begin, argv[1])) return 0;
f0100bf0:	8b 43 04             	mov    0x4(%ebx),%eax
f0100bf3:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100bf7:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100bfa:	89 04 24             	mov    %eax,(%esp)
f0100bfd:	e8 a5 ff ff ff       	call   f0100ba7 <pxtoi>
f0100c02:	84 c0                	test   %al,%al
f0100c04:	0f 84 eb 00 00 00    	je     f0100cf5 <mon_showmapping+0x10f>
//	cprintf("%d", !pxtoi(&begin, argv[1]));
	if (!pxtoi(&end, argv[2])) return 0;
f0100c0a:	8b 43 08             	mov    0x8(%ebx),%eax
f0100c0d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100c11:	8d 45 f0             	lea    -0x10(%ebp),%eax
f0100c14:	89 04 24             	mov    %eax,(%esp)
f0100c17:	e8 8b ff ff ff       	call   f0100ba7 <pxtoi>
f0100c1c:	84 c0                	test   %al,%al
f0100c1e:	0f 84 d1 00 00 00    	je     f0100cf5 <mon_showmapping+0x10f>
	begin = ROUNDUP(begin, PGSIZE); 
f0100c24:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0100c27:	81 c2 ff 0f 00 00    	add    $0xfff,%edx
f0100c2d:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100c33:	89 55 f4             	mov    %edx,-0xc(%ebp)
	end   = ROUNDUP(end, PGSIZE);
f0100c36:	8b 4d f0             	mov    -0x10(%ebp),%ecx
f0100c39:	81 c1 ff 0f 00 00    	add    $0xfff,%ecx
f0100c3f:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0100c45:	89 4d f0             	mov    %ecx,-0x10(%ebp)
	for (;begin <= end; begin += PGSIZE) {
f0100c48:	89 d0                	mov    %edx,%eax
f0100c4a:	39 d1                	cmp    %edx,%ecx
f0100c4c:	0f 82 a3 00 00 00    	jb     f0100cf5 <mon_showmapping+0x10f>
		pte_t *mapper = pgdir_walk(kern_pgdir, (void*) begin, 1);
f0100c52:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0100c59:	00 
f0100c5a:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100c5e:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f0100c63:	89 04 24             	mov    %eax,(%esp)
f0100c66:	e8 6a 0a 00 00       	call   f01016d5 <pgdir_walk>
f0100c6b:	89 c3                	mov    %eax,%ebx
		cprintf("VA 0x%08x : ", begin);
f0100c6d:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100c70:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100c74:	c7 04 24 9c 49 10 f0 	movl   $0xf010499c,(%esp)
f0100c7b:	e8 0e 29 00 00       	call   f010358e <cprintf>
		if (mapper != NULL) {
f0100c80:	85 db                	test   %ebx,%ebx
f0100c82:	74 41                	je     f0100cc5 <mon_showmapping+0xdf>
			if (*mapper & PTE_P) {
f0100c84:	8b 03                	mov    (%ebx),%eax
f0100c86:	a8 01                	test   $0x1,%al
f0100c88:	74 2d                	je     f0100cb7 <mon_showmapping+0xd1>
				cprintf("mapping 0x%08x ", PTE_ADDR(*mapper));//, PADDR((void*)begin));
f0100c8a:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100c8f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100c93:	c7 04 24 a9 49 10 f0 	movl   $0xf01049a9,(%esp)
f0100c9a:	e8 ef 28 00 00       	call   f010358e <cprintf>
				printPermission((pte_t)*mapper);
f0100c9f:	8b 03                	mov    (%ebx),%eax
f0100ca1:	89 04 24             	mov    %eax,(%esp)
f0100ca4:	e8 f9 fd ff ff       	call   f0100aa2 <printPermission>
				cprintf("\n");
f0100ca9:	c7 04 24 bc 58 10 f0 	movl   $0xf01058bc,(%esp)
f0100cb0:	e8 d9 28 00 00       	call   f010358e <cprintf>
f0100cb5:	eb 2a                	jmp    f0100ce1 <mon_showmapping+0xfb>
			} else {
				cprintf("page not mapping\n");
f0100cb7:	c7 04 24 b9 49 10 f0 	movl   $0xf01049b9,(%esp)
f0100cbe:	e8 cb 28 00 00       	call   f010358e <cprintf>
f0100cc3:	eb 1c                	jmp    f0100ce1 <mon_showmapping+0xfb>
			}
		} else {
			panic("error, out of memory");
f0100cc5:	c7 44 24 08 cb 49 10 	movl   $0xf01049cb,0x8(%esp)
f0100ccc:	f0 
f0100ccd:	c7 44 24 04 e9 00 00 	movl   $0xe9,0x4(%esp)
f0100cd4:	00 
f0100cd5:	c7 04 24 e0 49 10 f0 	movl   $0xf01049e0,(%esp)
f0100cdc:	e8 b3 f3 ff ff       	call   f0100094 <_panic>
	if (!pxtoi(&begin, argv[1])) return 0;
//	cprintf("%d", !pxtoi(&begin, argv[1]));
	if (!pxtoi(&end, argv[2])) return 0;
	begin = ROUNDUP(begin, PGSIZE); 
	end   = ROUNDUP(end, PGSIZE);
	for (;begin <= end; begin += PGSIZE) {
f0100ce1:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100ce4:	05 00 10 00 00       	add    $0x1000,%eax
f0100ce9:	89 45 f4             	mov    %eax,-0xc(%ebp)
f0100cec:	39 45 f0             	cmp    %eax,-0x10(%ebp)
f0100cef:	0f 83 5d ff ff ff    	jae    f0100c52 <mon_showmapping+0x6c>
		} else {
			panic("error, out of memory");
		}
	}
	return 0;
}
f0100cf5:	b8 00 00 00 00       	mov    $0x0,%eax
f0100cfa:	83 c4 24             	add    $0x24,%esp
f0100cfd:	5b                   	pop    %ebx
f0100cfe:	5d                   	pop    %ebp
f0100cff:	c3                   	ret    

f0100d00 <mon_dump>:
	pte_t *mapper = pgdir_walk(kern_pgdir, (void*) ((va >> PDXSHIFT) << PDXSHIFT), 1);
	cprintf("Page Table Entry Address : 0x%08x\n", mapper); 
	return 0;
}
#define POINT_SIZE 8
int mon_dump(int argc, char **argv, struct Trapframe *tf) {
f0100d00:	55                   	push   %ebp
f0100d01:	89 e5                	mov    %esp,%ebp
f0100d03:	53                   	push   %ebx
f0100d04:	83 ec 24             	sub    $0x24,%esp
f0100d07:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	uint32_t begin, end;
	if (argc < 3) {
f0100d0a:	83 7d 08 02          	cmpl   $0x2,0x8(%ebp)
f0100d0e:	7f 11                	jg     f0100d21 <mon_dump+0x21>
		cprintf("invalid command\n");
f0100d10:	c7 04 24 ef 49 10 f0 	movl   $0xf01049ef,(%esp)
f0100d17:	e8 72 28 00 00       	call   f010358e <cprintf>
		return 0;
f0100d1c:	e9 13 01 00 00       	jmp    f0100e34 <mon_dump+0x134>
	}
	if (!pxtoi(&begin, argv[2])) return 0;
f0100d21:	8b 43 08             	mov    0x8(%ebx),%eax
f0100d24:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100d28:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100d2b:	89 04 24             	mov    %eax,(%esp)
f0100d2e:	e8 74 fe ff ff       	call   f0100ba7 <pxtoi>
f0100d33:	84 c0                	test   %al,%al
f0100d35:	0f 84 f9 00 00 00    	je     f0100e34 <mon_dump+0x134>
	if (!pxtoi(&end, argv[3])) return 0;
f0100d3b:	8b 43 0c             	mov    0xc(%ebx),%eax
f0100d3e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100d42:	8d 45 f0             	lea    -0x10(%ebp),%eax
f0100d45:	89 04 24             	mov    %eax,(%esp)
f0100d48:	e8 5a fe ff ff       	call   f0100ba7 <pxtoi>
f0100d4d:	84 c0                	test   %al,%al
f0100d4f:	0f 84 df 00 00 00    	je     f0100e34 <mon_dump+0x134>
	if (argv[1][0] == 'p') {
f0100d55:	8b 43 04             	mov    0x4(%ebx),%eax
f0100d58:	0f b6 00             	movzbl (%eax),%eax
f0100d5b:	3c 70                	cmp    $0x70,%al
f0100d5d:	0f 85 90 00 00 00    	jne    f0100df3 <mon_dump+0xf3>
		if (PGNUM(end) >= npages || PGNUM(end) >= npages){
f0100d63:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0100d66:	8b 0d 84 99 11 f0    	mov    0xf0119984,%ecx
f0100d6c:	89 d0                	mov    %edx,%eax
f0100d6e:	c1 e8 0c             	shr    $0xc,%eax
f0100d71:	39 c8                	cmp    %ecx,%eax
f0100d73:	73 16                	jae    f0100d8b <mon_dump+0x8b>
			cprintf("out of memory\n");
			return 0;	
		}
		for (;begin <= end; begin += POINT_SIZE)
f0100d75:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100d78:	39 c2                	cmp    %eax,%edx
f0100d7a:	0f 82 b4 00 00 00    	jb     f0100e34 <mon_dump+0x134>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100d80:	89 c2                	mov    %eax,%edx
f0100d82:	c1 ea 0c             	shr    $0xc,%edx
f0100d85:	39 d1                	cmp    %edx,%ecx
f0100d87:	77 40                	ja     f0100dc9 <mon_dump+0xc9>
f0100d89:	eb 1e                	jmp    f0100da9 <mon_dump+0xa9>
	}
	if (!pxtoi(&begin, argv[2])) return 0;
	if (!pxtoi(&end, argv[3])) return 0;
	if (argv[1][0] == 'p') {
		if (PGNUM(end) >= npages || PGNUM(end) >= npages){
			cprintf("out of memory\n");
f0100d8b:	c7 04 24 00 4a 10 f0 	movl   $0xf0104a00,(%esp)
f0100d92:	e8 f7 27 00 00       	call   f010358e <cprintf>
			return 0;	
f0100d97:	e9 98 00 00 00       	jmp    f0100e34 <mon_dump+0x134>
f0100d9c:	89 c2                	mov    %eax,%edx
f0100d9e:	c1 ea 0c             	shr    $0xc,%edx
f0100da1:	3b 15 84 99 11 f0    	cmp    0xf0119984,%edx
f0100da7:	72 20                	jb     f0100dc9 <mon_dump+0xc9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100da9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100dad:	c7 44 24 08 6c 4c 10 	movl   $0xf0104c6c,0x8(%esp)
f0100db4:	f0 
f0100db5:	c7 44 24 04 cc 00 00 	movl   $0xcc,0x4(%esp)
f0100dbc:	00 
f0100dbd:	c7 04 24 e0 49 10 f0 	movl   $0xf01049e0,(%esp)
f0100dc4:	e8 cb f2 ff ff       	call   f0100094 <_panic>
		}
		for (;begin <= end; begin += POINT_SIZE)
			cprintf("pa 0x%08x : 0x%08x\n", begin, *((uint32_t*)KADDR(begin)));
f0100dc9:	8b 90 00 00 00 f0    	mov    -0x10000000(%eax),%edx
f0100dcf:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100dd3:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100dd7:	c7 04 24 0f 4a 10 f0 	movl   $0xf0104a0f,(%esp)
f0100dde:	e8 ab 27 00 00       	call   f010358e <cprintf>
	if (argv[1][0] == 'p') {
		if (PGNUM(end) >= npages || PGNUM(end) >= npages){
			cprintf("out of memory\n");
			return 0;	
		}
		for (;begin <= end; begin += POINT_SIZE)
f0100de3:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100de6:	83 c0 08             	add    $0x8,%eax
f0100de9:	89 45 f4             	mov    %eax,-0xc(%ebp)
f0100dec:	39 45 f0             	cmp    %eax,-0x10(%ebp)
f0100def:	73 ab                	jae    f0100d9c <mon_dump+0x9c>
f0100df1:	eb 41                	jmp    f0100e34 <mon_dump+0x134>
			cprintf("pa 0x%08x : 0x%08x\n", begin, *((uint32_t*)KADDR(begin)));
	} else if (argv[1][0] == 'v') {
f0100df3:	3c 76                	cmp    $0x76,%al
f0100df5:	75 31                	jne    f0100e28 <mon_dump+0x128>
		for (;begin <= end; begin+=POINT_SIZE) {
f0100df7:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100dfa:	3b 45 f0             	cmp    -0x10(%ebp),%eax
f0100dfd:	8d 76 00             	lea    0x0(%esi),%esi
f0100e00:	77 32                	ja     f0100e34 <mon_dump+0x134>
			cprintf("Va 0x%08x : 0x%08x\n", begin, *((uint32_t*)begin));
f0100e02:	8b 10                	mov    (%eax),%edx
f0100e04:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100e08:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100e0c:	c7 04 24 23 4a 10 f0 	movl   $0xf0104a23,(%esp)
f0100e13:	e8 76 27 00 00       	call   f010358e <cprintf>
			return 0;	
		}
		for (;begin <= end; begin += POINT_SIZE)
			cprintf("pa 0x%08x : 0x%08x\n", begin, *((uint32_t*)KADDR(begin)));
	} else if (argv[1][0] == 'v') {
		for (;begin <= end; begin+=POINT_SIZE) {
f0100e18:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100e1b:	83 c0 08             	add    $0x8,%eax
f0100e1e:	89 45 f4             	mov    %eax,-0xc(%ebp)
f0100e21:	39 45 f0             	cmp    %eax,-0x10(%ebp)
f0100e24:	73 dc                	jae    f0100e02 <mon_dump+0x102>
f0100e26:	eb 0c                	jmp    f0100e34 <mon_dump+0x134>
			cprintf("Va 0x%08x : 0x%08x\n", begin, *((uint32_t*)begin));
		}
	} else cprintf("invalid command\n");
f0100e28:	c7 04 24 ef 49 10 f0 	movl   $0xf01049ef,(%esp)
f0100e2f:	e8 5a 27 00 00       	call   f010358e <cprintf>
	return 0;

}
f0100e34:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e39:	83 c4 24             	add    $0x24,%esp
f0100e3c:	5b                   	pop    %ebx
f0100e3d:	5d                   	pop    %ebp
f0100e3e:	c3                   	ret    

f0100e3f <mon_showPT>:
	cprintf("after change ");  printPermission(*mapper); cprintf("\n");
	return 0;
}


int mon_showPT(int argc, char **argv, struct Trapframe *tf) {
f0100e3f:	55                   	push   %ebp
f0100e40:	89 e5                	mov    %esp,%ebp
f0100e42:	83 ec 28             	sub    $0x28,%esp
	uintptr_t va;
	if (!pxtoi(&va, argv[1])) return 0;
f0100e45:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100e48:	8b 40 04             	mov    0x4(%eax),%eax
f0100e4b:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100e4f:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100e52:	89 04 24             	mov    %eax,(%esp)
f0100e55:	e8 4d fd ff ff       	call   f0100ba7 <pxtoi>
f0100e5a:	84 c0                	test   %al,%al
f0100e5c:	74 31                	je     f0100e8f <mon_showPT+0x50>
	
	pte_t *mapper = pgdir_walk(kern_pgdir, (void*) ((va >> PDXSHIFT) << PDXSHIFT), 1);
f0100e5e:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0100e65:	00 
f0100e66:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100e69:	25 00 00 c0 ff       	and    $0xffc00000,%eax
f0100e6e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100e72:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f0100e77:	89 04 24             	mov    %eax,(%esp)
f0100e7a:	e8 56 08 00 00       	call   f01016d5 <pgdir_walk>
	cprintf("Page Table Entry Address : 0x%08x\n", mapper); 
f0100e7f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100e83:	c7 04 24 90 4c 10 f0 	movl   $0xf0104c90,(%esp)
f0100e8a:	e8 ff 26 00 00       	call   f010358e <cprintf>
	return 0;
}
f0100e8f:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e94:	c9                   	leave  
f0100e95:	c3                   	ret    

f0100e96 <mon_changePermission>:
	}
	return true;
}

int mon_changePermission(int argc, char **argv, struct Trapframe *tf) 
{
f0100e96:	55                   	push   %ebp
f0100e97:	89 e5                	mov    %esp,%ebp
f0100e99:	83 ec 38             	sub    $0x38,%esp
f0100e9c:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0100e9f:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0100ea2:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0100ea5:	8b 7d 08             	mov    0x8(%ebp),%edi
f0100ea8:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	if (argc < 2) {
f0100eab:	83 ff 01             	cmp    $0x1,%edi
f0100eae:	7f 11                	jg     f0100ec1 <mon_changePermission+0x2b>
		cprintf("invalid number of parameters\n");
f0100eb0:	c7 04 24 37 4a 10 f0 	movl   $0xf0104a37,(%esp)
f0100eb7:	e8 d2 26 00 00       	call   f010358e <cprintf>
		return 0;
f0100ebc:	e9 f6 00 00 00       	jmp    f0100fb7 <mon_changePermission+0x121>
	}
	uintptr_t va;
	if (!pxtoi(&va,argv[1]))	return 0;
f0100ec1:	8b 43 04             	mov    0x4(%ebx),%eax
f0100ec4:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100ec8:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0100ecb:	89 04 24             	mov    %eax,(%esp)
f0100ece:	e8 d4 fc ff ff       	call   f0100ba7 <pxtoi>
f0100ed3:	84 c0                	test   %al,%al
f0100ed5:	0f 84 dc 00 00 00    	je     f0100fb7 <mon_changePermission+0x121>
	
	pte_t* mapper = pgdir_walk(kern_pgdir, (void*) va, 1);
f0100edb:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0100ee2:	00 
f0100ee3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100ee6:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100eea:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f0100eef:	89 04 24             	mov    %eax,(%esp)
f0100ef2:	e8 de 07 00 00       	call   f01016d5 <pgdir_walk>
f0100ef7:	89 c6                	mov    %eax,%esi
	if (!mapper) 
f0100ef9:	85 c0                	test   %eax,%eax
f0100efb:	75 1c                	jne    f0100f19 <mon_changePermission+0x83>
		panic("error, out of memory");
f0100efd:	c7 44 24 08 cb 49 10 	movl   $0xf01049cb,0x8(%esp)
f0100f04:	f0 
f0100f05:	c7 44 24 04 9f 00 00 	movl   $0x9f,0x4(%esp)
f0100f0c:	00 
f0100f0d:	c7 04 24 e0 49 10 f0 	movl   $0xf01049e0,(%esp)
f0100f14:	e8 7b f1 ff ff       	call   f0100094 <_panic>
	physaddr_t pa = PTE_ADDR(*mapper);
	int perm = 0;
	//PTE_U PET_W PTE_P
	if (argc != 2) {
f0100f19:	83 ff 02             	cmp    $0x2,%edi
f0100f1c:	74 45                	je     f0100f63 <mon_changePermission+0xcd>
		if (argc != 5) {
f0100f1e:	83 ff 05             	cmp    $0x5,%edi
f0100f21:	74 11                	je     f0100f34 <mon_changePermission+0x9e>
			cprintf("invalid number of parameters\n");
f0100f23:	c7 04 24 37 4a 10 f0 	movl   $0xf0104a37,(%esp)
f0100f2a:	e8 5f 26 00 00       	call   f010358e <cprintf>
			return 0;
f0100f2f:	e9 83 00 00 00       	jmp    f0100fb7 <mon_changePermission+0x121>
		}
		if (argv[2][0] == '1') perm |= PTE_U;
f0100f34:	8b 43 08             	mov    0x8(%ebx),%eax
	
	pte_t* mapper = pgdir_walk(kern_pgdir, (void*) va, 1);
	if (!mapper) 
		panic("error, out of memory");
	physaddr_t pa = PTE_ADDR(*mapper);
	int perm = 0;
f0100f37:	80 38 31             	cmpb   $0x31,(%eax)
f0100f3a:	0f 94 c0             	sete   %al
f0100f3d:	0f b6 c0             	movzbl %al,%eax
f0100f40:	89 c7                	mov    %eax,%edi
f0100f42:	c1 e7 02             	shl    $0x2,%edi
		if (argc != 5) {
			cprintf("invalid number of parameters\n");
			return 0;
		}
		if (argv[2][0] == '1') perm |= PTE_U;
		if (argv[3][0] == '1') perm |= PTE_W;
f0100f45:	8b 53 0c             	mov    0xc(%ebx),%edx
f0100f48:	89 f8                	mov    %edi,%eax
f0100f4a:	83 c8 02             	or     $0x2,%eax
f0100f4d:	80 3a 31             	cmpb   $0x31,(%edx)
f0100f50:	0f 44 f8             	cmove  %eax,%edi
		if (argv[4][0] == '1') perm |= PTE_P;
f0100f53:	8b 53 10             	mov    0x10(%ebx),%edx
f0100f56:	89 f8                	mov    %edi,%eax
f0100f58:	83 c8 01             	or     $0x1,%eax
f0100f5b:	80 3a 31             	cmpb   $0x31,(%edx)
f0100f5e:	0f 44 f8             	cmove  %eax,%edi
f0100f61:	eb 05                	jmp    f0100f68 <mon_changePermission+0xd2>
	
	pte_t* mapper = pgdir_walk(kern_pgdir, (void*) va, 1);
	if (!mapper) 
		panic("error, out of memory");
	physaddr_t pa = PTE_ADDR(*mapper);
	int perm = 0;
f0100f63:	bf 00 00 00 00       	mov    $0x0,%edi
		if (argv[2][0] == '1') perm |= PTE_U;
		if (argv[3][0] == '1') perm |= PTE_W;
		if (argv[4][0] == '1') perm |= PTE_P;
	}
//	boot_map_region(kern_pgdir, va, PGSIZE, pa, perm);	
	cprintf("before change "); printPermission(*mapper); cprintf("\n");
f0100f68:	c7 04 24 55 4a 10 f0 	movl   $0xf0104a55,(%esp)
f0100f6f:	e8 1a 26 00 00       	call   f010358e <cprintf>
f0100f74:	8b 06                	mov    (%esi),%eax
f0100f76:	89 04 24             	mov    %eax,(%esp)
f0100f79:	e8 24 fb ff ff       	call   f0100aa2 <printPermission>
f0100f7e:	c7 04 24 bc 58 10 f0 	movl   $0xf01058bc,(%esp)
f0100f85:	e8 04 26 00 00       	call   f010358e <cprintf>
	
	*mapper = PTE_ADDR(*mapper) | perm;
f0100f8a:	8b 06                	mov    (%esi),%eax
f0100f8c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100f91:	09 c7                	or     %eax,%edi
f0100f93:	89 3e                	mov    %edi,(%esi)
	cprintf("after change ");  printPermission(*mapper); cprintf("\n");
f0100f95:	c7 04 24 64 4a 10 f0 	movl   $0xf0104a64,(%esp)
f0100f9c:	e8 ed 25 00 00       	call   f010358e <cprintf>
f0100fa1:	8b 06                	mov    (%esi),%eax
f0100fa3:	89 04 24             	mov    %eax,(%esp)
f0100fa6:	e8 f7 fa ff ff       	call   f0100aa2 <printPermission>
f0100fab:	c7 04 24 bc 58 10 f0 	movl   $0xf01058bc,(%esp)
f0100fb2:	e8 d7 25 00 00       	call   f010358e <cprintf>
	return 0;
}
f0100fb7:	b8 00 00 00 00       	mov    $0x0,%eax
f0100fbc:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0100fbf:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0100fc2:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0100fc5:	89 ec                	mov    %ebp,%esp
f0100fc7:	5d                   	pop    %ebp
f0100fc8:	c3                   	ret    

f0100fc9 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100fc9:	55                   	push   %ebp
f0100fca:	89 e5                	mov    %esp,%ebp
f0100fcc:	57                   	push   %edi
f0100fcd:	56                   	push   %esi
f0100fce:	53                   	push   %ebx
f0100fcf:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100fd2:	c7 04 24 b4 4c 10 f0 	movl   $0xf0104cb4,(%esp)
f0100fd9:	e8 b0 25 00 00       	call   f010358e <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100fde:	c7 04 24 d8 4c 10 f0 	movl   $0xf0104cd8,(%esp)
f0100fe5:	e8 a4 25 00 00       	call   f010358e <cprintf>
  //	cprintf("x %d, y %x, z %d\n", x, y, z);
//	unsigned int i = 0x00646c72;
//	cprintf("H%x Wo%s", 57616, &i);

	while (1) {
		buf = readline("K> ");
f0100fea:	c7 04 24 72 4a 10 f0 	movl   $0xf0104a72,(%esp)
f0100ff1:	e8 aa 2e 00 00       	call   f0103ea0 <readline>
f0100ff6:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100ff8:	85 c0                	test   %eax,%eax
f0100ffa:	74 ee                	je     f0100fea <monitor+0x21>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100ffc:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0101003:	be 00 00 00 00       	mov    $0x0,%esi
f0101008:	eb 06                	jmp    f0101010 <monitor+0x47>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f010100a:	c6 03 00             	movb   $0x0,(%ebx)
f010100d:	83 c3 01             	add    $0x1,%ebx
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0101010:	0f b6 03             	movzbl (%ebx),%eax
f0101013:	84 c0                	test   %al,%al
f0101015:	74 6a                	je     f0101081 <monitor+0xb8>
f0101017:	0f be c0             	movsbl %al,%eax
f010101a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010101e:	c7 04 24 76 4a 10 f0 	movl   $0xf0104a76,(%esp)
f0101025:	e8 cc 30 00 00       	call   f01040f6 <strchr>
f010102a:	85 c0                	test   %eax,%eax
f010102c:	75 dc                	jne    f010100a <monitor+0x41>
			*buf++ = 0;
		if (*buf == 0)
f010102e:	80 3b 00             	cmpb   $0x0,(%ebx)
f0101031:	74 4e                	je     f0101081 <monitor+0xb8>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0101033:	83 fe 0f             	cmp    $0xf,%esi
f0101036:	75 16                	jne    f010104e <monitor+0x85>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0101038:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f010103f:	00 
f0101040:	c7 04 24 7b 4a 10 f0 	movl   $0xf0104a7b,(%esp)
f0101047:	e8 42 25 00 00       	call   f010358e <cprintf>
f010104c:	eb 9c                	jmp    f0100fea <monitor+0x21>
			return 0;
		}
		argv[argc++] = buf;
f010104e:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0101052:	83 c6 01             	add    $0x1,%esi
		while (*buf && !strchr(WHITESPACE, *buf))
f0101055:	0f b6 03             	movzbl (%ebx),%eax
f0101058:	84 c0                	test   %al,%al
f010105a:	75 0c                	jne    f0101068 <monitor+0x9f>
f010105c:	eb b2                	jmp    f0101010 <monitor+0x47>
			buf++;
f010105e:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0101061:	0f b6 03             	movzbl (%ebx),%eax
f0101064:	84 c0                	test   %al,%al
f0101066:	74 a8                	je     f0101010 <monitor+0x47>
f0101068:	0f be c0             	movsbl %al,%eax
f010106b:	89 44 24 04          	mov    %eax,0x4(%esp)
f010106f:	c7 04 24 76 4a 10 f0 	movl   $0xf0104a76,(%esp)
f0101076:	e8 7b 30 00 00       	call   f01040f6 <strchr>
f010107b:	85 c0                	test   %eax,%eax
f010107d:	74 df                	je     f010105e <monitor+0x95>
f010107f:	eb 8f                	jmp    f0101010 <monitor+0x47>
			buf++;
	}
	argv[argc] = 0;
f0101081:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0101088:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0101089:	85 f6                	test   %esi,%esi
f010108b:	0f 84 59 ff ff ff    	je     f0100fea <monitor+0x21>
f0101091:	bb c0 4e 10 f0       	mov    $0xf0104ec0,%ebx
f0101096:	bf 00 00 00 00       	mov    $0x0,%edi
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f010109b:	8b 03                	mov    (%ebx),%eax
f010109d:	89 44 24 04          	mov    %eax,0x4(%esp)
f01010a1:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01010a4:	89 04 24             	mov    %eax,(%esp)
f01010a7:	e8 cf 2f 00 00       	call   f010407b <strcmp>
f01010ac:	85 c0                	test   %eax,%eax
f01010ae:	75 24                	jne    f01010d4 <monitor+0x10b>
			return commands[i].func(argc, argv, tf);
f01010b0:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f01010b3:	8b 55 08             	mov    0x8(%ebp),%edx
f01010b6:	89 54 24 08          	mov    %edx,0x8(%esp)
f01010ba:	8d 55 a8             	lea    -0x58(%ebp),%edx
f01010bd:	89 54 24 04          	mov    %edx,0x4(%esp)
f01010c1:	89 34 24             	mov    %esi,(%esp)
f01010c4:	ff 14 85 c8 4e 10 f0 	call   *-0xfefb138(,%eax,4)
//	cprintf("H%x Wo%s", 57616, &i);

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f01010cb:	85 c0                	test   %eax,%eax
f01010cd:	78 28                	js     f01010f7 <monitor+0x12e>
f01010cf:	e9 16 ff ff ff       	jmp    f0100fea <monitor+0x21>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f01010d4:	83 c7 01             	add    $0x1,%edi
f01010d7:	83 c3 0c             	add    $0xc,%ebx
f01010da:	83 ff 08             	cmp    $0x8,%edi
f01010dd:	75 bc                	jne    f010109b <monitor+0xd2>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f01010df:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01010e2:	89 44 24 04          	mov    %eax,0x4(%esp)
f01010e6:	c7 04 24 98 4a 10 f0 	movl   $0xf0104a98,(%esp)
f01010ed:	e8 9c 24 00 00       	call   f010358e <cprintf>
f01010f2:	e9 f3 fe ff ff       	jmp    f0100fea <monitor+0x21>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f01010f7:	83 c4 5c             	add    $0x5c,%esp
f01010fa:	5b                   	pop    %ebx
f01010fb:	5e                   	pop    %esi
f01010fc:	5f                   	pop    %edi
f01010fd:	5d                   	pop    %ebp
f01010fe:	c3                   	ret    
	...

f0101100 <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0101100:	55                   	push   %ebp
f0101101:	89 e5                	mov    %esp,%ebp
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0101103:	83 3d 5c 95 11 f0 00 	cmpl   $0x0,0xf011955c
f010110a:	75 11                	jne    f010111d <boot_alloc+0x1d>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f010110c:	ba 8f a9 11 f0       	mov    $0xf011a98f,%edx
f0101111:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101117:	89 15 5c 95 11 f0    	mov    %edx,0xf011955c
		void *temp = nextfree;
		nextfree += n;
		nextfree = ROUNDUP(nextfree, PGSIZE);
		return temp;
	} else if (n == 0) {
		return (void*)nextfree;
f010111d:	8b 15 5c 95 11 f0    	mov    0xf011955c,%edx
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	// page_alloc() is the real allocator.

	// LAB 2: Your code here.
	if (n > 0) {
f0101123:	85 c0                	test   %eax,%eax
f0101125:	74 11                	je     f0101138 <boot_alloc+0x38>
		void *temp = nextfree;
		nextfree += n;
		nextfree = ROUNDUP(nextfree, PGSIZE);
f0101127:	8d 84 02 ff 0f 00 00 	lea    0xfff(%edx,%eax,1),%eax
f010112e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0101133:	a3 5c 95 11 f0       	mov    %eax,0xf011955c
		return temp;
	} else if (n == 0) {
		return (void*)nextfree;
	}
	return NULL;
}
f0101138:	89 d0                	mov    %edx,%eax
f010113a:	5d                   	pop    %ebp
f010113b:	c3                   	ret    

f010113c <check_va2pa>:
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f010113c:	55                   	push   %ebp
f010113d:	89 e5                	mov    %esp,%ebp
f010113f:	83 ec 18             	sub    $0x18,%esp
//	cprintf("!");
	pte_t *p;
	//cprintf("!");
	pgdir = &pgdir[PDX(va)];
f0101142:	89 d1                	mov    %edx,%ecx
f0101144:	c1 e9 16             	shr    $0x16,%ecx
	if (!(*pgdir & PTE_P))
f0101147:	8b 0c 88             	mov    (%eax,%ecx,4),%ecx
		return ~0;
f010114a:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
{
//	cprintf("!");
	pte_t *p;
	//cprintf("!");
	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f010114f:	f6 c1 01             	test   $0x1,%cl
f0101152:	74 57                	je     f01011ab <check_va2pa+0x6f>
		return ~0;
 //	cprintf("!");	
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0101154:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010115a:	89 c8                	mov    %ecx,%eax
f010115c:	c1 e8 0c             	shr    $0xc,%eax
f010115f:	3b 05 84 99 11 f0    	cmp    0xf0119984,%eax
f0101165:	72 20                	jb     f0101187 <check_va2pa+0x4b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101167:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010116b:	c7 44 24 08 6c 4c 10 	movl   $0xf0104c6c,0x8(%esp)
f0101172:	f0 
f0101173:	c7 44 24 04 d8 02 00 	movl   $0x2d8,0x4(%esp)
f010117a:	00 
f010117b:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f0101182:	e8 0d ef ff ff       	call   f0100094 <_panic>
	if (!(p[PTX(va)] & PTE_P))
f0101187:	c1 ea 0c             	shr    $0xc,%edx
f010118a:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0101190:	8b 84 91 00 00 00 f0 	mov    -0x10000000(%ecx,%edx,4),%eax
f0101197:	89 c2                	mov    %eax,%edx
f0101199:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f010119c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f01011a1:	85 d2                	test   %edx,%edx
f01011a3:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f01011a8:	0f 44 c2             	cmove  %edx,%eax
}
f01011ab:	c9                   	leave  
f01011ac:	c3                   	ret    

f01011ad <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f01011ad:	55                   	push   %ebp
f01011ae:	89 e5                	mov    %esp,%ebp
f01011b0:	83 ec 18             	sub    $0x18,%esp
f01011b3:	89 5d f8             	mov    %ebx,-0x8(%ebp)
f01011b6:	89 75 fc             	mov    %esi,-0x4(%ebp)
f01011b9:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f01011bb:	89 04 24             	mov    %eax,(%esp)
f01011be:	e8 5d 23 00 00       	call   f0103520 <mc146818_read>
f01011c3:	89 c6                	mov    %eax,%esi
f01011c5:	83 c3 01             	add    $0x1,%ebx
f01011c8:	89 1c 24             	mov    %ebx,(%esp)
f01011cb:	e8 50 23 00 00       	call   f0103520 <mc146818_read>
f01011d0:	c1 e0 08             	shl    $0x8,%eax
f01011d3:	09 f0                	or     %esi,%eax
}
f01011d5:	8b 5d f8             	mov    -0x8(%ebp),%ebx
f01011d8:	8b 75 fc             	mov    -0x4(%ebp),%esi
f01011db:	89 ec                	mov    %ebp,%esp
f01011dd:	5d                   	pop    %ebp
f01011de:	c3                   	ret    

f01011df <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f01011df:	55                   	push   %ebp
f01011e0:	89 e5                	mov    %esp,%ebp
f01011e2:	57                   	push   %edi
f01011e3:	56                   	push   %esi
f01011e4:	53                   	push   %ebx
f01011e5:	83 ec 3c             	sub    $0x3c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f01011e8:	3c 01                	cmp    $0x1,%al
f01011ea:	19 f6                	sbb    %esi,%esi
f01011ec:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
f01011f2:	83 c6 01             	add    $0x1,%esi
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f01011f5:	8b 1d 60 95 11 f0    	mov    0xf0119560,%ebx
f01011fb:	85 db                	test   %ebx,%ebx
f01011fd:	75 1c                	jne    f010121b <check_page_free_list+0x3c>
		panic("'page_free_list' is a null pointer!");
f01011ff:	c7 44 24 08 20 4f 10 	movl   $0xf0104f20,0x8(%esp)
f0101206:	f0 
f0101207:	c7 44 24 04 18 02 00 	movl   $0x218,0x4(%esp)
f010120e:	00 
f010120f:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f0101216:	e8 79 ee ff ff       	call   f0100094 <_panic>

	if (only_low_memory) {
f010121b:	84 c0                	test   %al,%al
f010121d:	74 50                	je     f010126f <check_page_free_list+0x90>
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f010121f:	8d 45 e0             	lea    -0x20(%ebp),%eax
f0101222:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101225:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101228:	89 45 dc             	mov    %eax,-0x24(%ebp)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010122b:	89 d8                	mov    %ebx,%eax
f010122d:	2b 05 8c 99 11 f0    	sub    0xf011998c,%eax
f0101233:	c1 e0 09             	shl    $0x9,%eax
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0101236:	c1 e8 16             	shr    $0x16,%eax
f0101239:	39 c6                	cmp    %eax,%esi
f010123b:	0f 96 c0             	setbe  %al
f010123e:	0f b6 c0             	movzbl %al,%eax
			*tp[pagetype] = pp;
f0101241:	8b 54 85 d8          	mov    -0x28(%ebp,%eax,4),%edx
f0101245:	89 1a                	mov    %ebx,(%edx)
			tp[pagetype] = &pp->pp_link;
f0101247:	89 5c 85 d8          	mov    %ebx,-0x28(%ebp,%eax,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f010124b:	8b 1b                	mov    (%ebx),%ebx
f010124d:	85 db                	test   %ebx,%ebx
f010124f:	75 da                	jne    f010122b <check_page_free_list+0x4c>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0101251:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0101254:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f010125a:	8b 45 d8             	mov    -0x28(%ebp),%eax
f010125d:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0101260:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0101262:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0101265:	89 1d 60 95 11 f0    	mov    %ebx,0xf0119560
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010126b:	85 db                	test   %ebx,%ebx
f010126d:	74 67                	je     f01012d6 <check_page_free_list+0xf7>
f010126f:	89 d8                	mov    %ebx,%eax
f0101271:	2b 05 8c 99 11 f0    	sub    0xf011998c,%eax
f0101277:	c1 f8 03             	sar    $0x3,%eax
f010127a:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f010127d:	89 c2                	mov    %eax,%edx
f010127f:	c1 ea 16             	shr    $0x16,%edx
f0101282:	39 d6                	cmp    %edx,%esi
f0101284:	76 4a                	jbe    f01012d0 <check_page_free_list+0xf1>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101286:	89 c2                	mov    %eax,%edx
f0101288:	c1 ea 0c             	shr    $0xc,%edx
f010128b:	3b 15 84 99 11 f0    	cmp    0xf0119984,%edx
f0101291:	72 20                	jb     f01012b3 <check_page_free_list+0xd4>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101293:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101297:	c7 44 24 08 6c 4c 10 	movl   $0xf0104c6c,0x8(%esp)
f010129e:	f0 
f010129f:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f01012a6:	00 
f01012a7:	c7 04 24 24 56 10 f0 	movl   $0xf0105624,(%esp)
f01012ae:	e8 e1 ed ff ff       	call   f0100094 <_panic>
			memset(page2kva(pp), 0x97, 128);
f01012b3:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
f01012ba:	00 
f01012bb:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
f01012c2:	00 
	return (void *)(pa + KERNBASE);
f01012c3:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01012c8:	89 04 24             	mov    %eax,(%esp)
f01012cb:	e8 81 2e 00 00       	call   f0104151 <memset>
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01012d0:	8b 1b                	mov    (%ebx),%ebx
f01012d2:	85 db                	test   %ebx,%ebx
f01012d4:	75 99                	jne    f010126f <check_page_free_list+0x90>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f01012d6:	b8 00 00 00 00       	mov    $0x0,%eax
f01012db:	e8 20 fe ff ff       	call   f0101100 <boot_alloc>
f01012e0:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f01012e3:	8b 15 60 95 11 f0    	mov    0xf0119560,%edx
f01012e9:	85 d2                	test   %edx,%edx
f01012eb:	0f 84 f6 01 00 00    	je     f01014e7 <check_page_free_list+0x308>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f01012f1:	8b 1d 8c 99 11 f0    	mov    0xf011998c,%ebx
f01012f7:	39 da                	cmp    %ebx,%edx
f01012f9:	72 4d                	jb     f0101348 <check_page_free_list+0x169>
		assert(pp < pages + npages);
f01012fb:	a1 84 99 11 f0       	mov    0xf0119984,%eax
f0101300:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101303:	8d 04 c3             	lea    (%ebx,%eax,8),%eax
f0101306:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101309:	39 c2                	cmp    %eax,%edx
f010130b:	73 64                	jae    f0101371 <check_page_free_list+0x192>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f010130d:	89 5d d0             	mov    %ebx,-0x30(%ebp)
f0101310:	89 d0                	mov    %edx,%eax
f0101312:	29 d8                	sub    %ebx,%eax
f0101314:	a8 07                	test   $0x7,%al
f0101316:	0f 85 82 00 00 00    	jne    f010139e <check_page_free_list+0x1bf>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010131c:	c1 f8 03             	sar    $0x3,%eax
f010131f:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0101322:	85 c0                	test   %eax,%eax
f0101324:	0f 84 a2 00 00 00    	je     f01013cc <check_page_free_list+0x1ed>
		assert(page2pa(pp) != IOPHYSMEM);
f010132a:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f010132f:	0f 84 c2 00 00 00    	je     f01013f7 <check_page_free_list+0x218>
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0101335:	be 00 00 00 00       	mov    $0x0,%esi
f010133a:	bf 00 00 00 00       	mov    $0x0,%edi
f010133f:	e9 d7 00 00 00       	jmp    f010141b <check_page_free_list+0x23c>
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0101344:	39 da                	cmp    %ebx,%edx
f0101346:	73 24                	jae    f010136c <check_page_free_list+0x18d>
f0101348:	c7 44 24 0c 32 56 10 	movl   $0xf0105632,0xc(%esp)
f010134f:	f0 
f0101350:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f0101357:	f0 
f0101358:	c7 44 24 04 32 02 00 	movl   $0x232,0x4(%esp)
f010135f:	00 
f0101360:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f0101367:	e8 28 ed ff ff       	call   f0100094 <_panic>
		assert(pp < pages + npages);
f010136c:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f010136f:	72 24                	jb     f0101395 <check_page_free_list+0x1b6>
f0101371:	c7 44 24 0c 53 56 10 	movl   $0xf0105653,0xc(%esp)
f0101378:	f0 
f0101379:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f0101380:	f0 
f0101381:	c7 44 24 04 33 02 00 	movl   $0x233,0x4(%esp)
f0101388:	00 
f0101389:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f0101390:	e8 ff ec ff ff       	call   f0100094 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0101395:	89 d0                	mov    %edx,%eax
f0101397:	2b 45 d0             	sub    -0x30(%ebp),%eax
f010139a:	a8 07                	test   $0x7,%al
f010139c:	74 24                	je     f01013c2 <check_page_free_list+0x1e3>
f010139e:	c7 44 24 0c 44 4f 10 	movl   $0xf0104f44,0xc(%esp)
f01013a5:	f0 
f01013a6:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f01013ad:	f0 
f01013ae:	c7 44 24 04 34 02 00 	movl   $0x234,0x4(%esp)
f01013b5:	00 
f01013b6:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f01013bd:	e8 d2 ec ff ff       	call   f0100094 <_panic>
f01013c2:	c1 f8 03             	sar    $0x3,%eax
f01013c5:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f01013c8:	85 c0                	test   %eax,%eax
f01013ca:	75 24                	jne    f01013f0 <check_page_free_list+0x211>
f01013cc:	c7 44 24 0c 67 56 10 	movl   $0xf0105667,0xc(%esp)
f01013d3:	f0 
f01013d4:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f01013db:	f0 
f01013dc:	c7 44 24 04 37 02 00 	movl   $0x237,0x4(%esp)
f01013e3:	00 
f01013e4:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f01013eb:	e8 a4 ec ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f01013f0:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f01013f5:	75 24                	jne    f010141b <check_page_free_list+0x23c>
f01013f7:	c7 44 24 0c 78 56 10 	movl   $0xf0105678,0xc(%esp)
f01013fe:	f0 
f01013ff:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f0101406:	f0 
f0101407:	c7 44 24 04 38 02 00 	movl   $0x238,0x4(%esp)
f010140e:	00 
f010140f:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f0101416:	e8 79 ec ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f010141b:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0101420:	75 24                	jne    f0101446 <check_page_free_list+0x267>
f0101422:	c7 44 24 0c 78 4f 10 	movl   $0xf0104f78,0xc(%esp)
f0101429:	f0 
f010142a:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f0101431:	f0 
f0101432:	c7 44 24 04 39 02 00 	movl   $0x239,0x4(%esp)
f0101439:	00 
f010143a:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f0101441:	e8 4e ec ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0101446:	3d 00 00 10 00       	cmp    $0x100000,%eax
f010144b:	75 24                	jne    f0101471 <check_page_free_list+0x292>
f010144d:	c7 44 24 0c 91 56 10 	movl   $0xf0105691,0xc(%esp)
f0101454:	f0 
f0101455:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f010145c:	f0 
f010145d:	c7 44 24 04 3a 02 00 	movl   $0x23a,0x4(%esp)
f0101464:	00 
f0101465:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f010146c:	e8 23 ec ff ff       	call   f0100094 <_panic>
f0101471:	89 c1                	mov    %eax,%ecx
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0101473:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0101478:	76 57                	jbe    f01014d1 <check_page_free_list+0x2f2>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010147a:	c1 e8 0c             	shr    $0xc,%eax
f010147d:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101480:	77 20                	ja     f01014a2 <check_page_free_list+0x2c3>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101482:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0101486:	c7 44 24 08 6c 4c 10 	movl   $0xf0104c6c,0x8(%esp)
f010148d:	f0 
f010148e:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0101495:	00 
f0101496:	c7 04 24 24 56 10 f0 	movl   $0xf0105624,(%esp)
f010149d:	e8 f2 eb ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f01014a2:	81 e9 00 00 00 10    	sub    $0x10000000,%ecx
f01014a8:	39 4d c8             	cmp    %ecx,-0x38(%ebp)
f01014ab:	76 29                	jbe    f01014d6 <check_page_free_list+0x2f7>
f01014ad:	c7 44 24 0c 9c 4f 10 	movl   $0xf0104f9c,0xc(%esp)
f01014b4:	f0 
f01014b5:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f01014bc:	f0 
f01014bd:	c7 44 24 04 3b 02 00 	movl   $0x23b,0x4(%esp)
f01014c4:	00 
f01014c5:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f01014cc:	e8 c3 eb ff ff       	call   f0100094 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f01014d1:	83 c7 01             	add    $0x1,%edi
f01014d4:	eb 03                	jmp    f01014d9 <check_page_free_list+0x2fa>
		else
			++nfree_extmem;
f01014d6:	83 c6 01             	add    $0x1,%esi
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f01014d9:	8b 12                	mov    (%edx),%edx
f01014db:	85 d2                	test   %edx,%edx
f01014dd:	0f 85 61 fe ff ff    	jne    f0101344 <check_page_free_list+0x165>
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f01014e3:	85 ff                	test   %edi,%edi
f01014e5:	7f 24                	jg     f010150b <check_page_free_list+0x32c>
f01014e7:	c7 44 24 0c ab 56 10 	movl   $0xf01056ab,0xc(%esp)
f01014ee:	f0 
f01014ef:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f01014f6:	f0 
f01014f7:	c7 44 24 04 43 02 00 	movl   $0x243,0x4(%esp)
f01014fe:	00 
f01014ff:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f0101506:	e8 89 eb ff ff       	call   f0100094 <_panic>
	assert(nfree_extmem > 0);
f010150b:	85 f6                	test   %esi,%esi
f010150d:	7f 24                	jg     f0101533 <check_page_free_list+0x354>
f010150f:	c7 44 24 0c bd 56 10 	movl   $0xf01056bd,0xc(%esp)
f0101516:	f0 
f0101517:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f010151e:	f0 
f010151f:	c7 44 24 04 44 02 00 	movl   $0x244,0x4(%esp)
f0101526:	00 
f0101527:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f010152e:	e8 61 eb ff ff       	call   f0100094 <_panic>
}
f0101533:	83 c4 3c             	add    $0x3c,%esp
f0101536:	5b                   	pop    %ebx
f0101537:	5e                   	pop    %esi
f0101538:	5f                   	pop    %edi
f0101539:	5d                   	pop    %ebp
f010153a:	c3                   	ret    

f010153b <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f010153b:	55                   	push   %ebp
f010153c:	89 e5                	mov    %esp,%ebp
f010153e:	56                   	push   %esi
f010153f:	53                   	push   %ebx
f0101540:	83 ec 10             	sub    $0x10,%esp
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	size_t low = IOPHYSMEM / PGSIZE;	
	size_t top = (PADDR(boot_alloc(0))) / PGSIZE;
f0101543:	b8 00 00 00 00       	mov    $0x0,%eax
f0101548:	e8 b3 fb ff ff       	call   f0101100 <boot_alloc>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010154d:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101552:	77 20                	ja     f0101574 <page_init+0x39>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101554:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101558:	c7 44 24 08 e4 4f 10 	movl   $0xf0104fe4,0x8(%esp)
f010155f:	f0 
f0101560:	c7 44 24 04 05 01 00 	movl   $0x105,0x4(%esp)
f0101567:	00 
f0101568:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f010156f:	e8 20 eb ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0101574:	8d 98 00 00 00 10    	lea    0x10000000(%eax),%ebx
f010157a:	c1 eb 0c             	shr    $0xc,%ebx
	cprintf("!!%d %d %d\n", npages, low, top);
f010157d:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0101581:	c7 44 24 08 a0 00 00 	movl   $0xa0,0x8(%esp)
f0101588:	00 
f0101589:	a1 84 99 11 f0       	mov    0xf0119984,%eax
f010158e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101592:	c7 04 24 ce 56 10 f0 	movl   $0xf01056ce,(%esp)
f0101599:	e8 f0 1f 00 00       	call   f010358e <cprintf>
//	cprintf("00");
	page_free_list = NULL;
f010159e:	c7 05 60 95 11 f0 00 	movl   $0x0,0xf0119560
f01015a5:	00 00 00 
	for (i = 0; i < npages; i++) {
f01015a8:	83 3d 84 99 11 f0 00 	cmpl   $0x0,0xf0119984
f01015af:	74 64                	je     f0101615 <page_init+0xda>
f01015b1:	b9 00 00 00 00       	mov    $0x0,%ecx
f01015b6:	b8 00 00 00 00       	mov    $0x0,%eax
		if (i == 0 || (i >= low && i < top)){
f01015bb:	85 c0                	test   %eax,%eax
f01015bd:	74 0b                	je     f01015ca <page_init+0x8f>
f01015bf:	3d 9f 00 00 00       	cmp    $0x9f,%eax
f01015c4:	76 1f                	jbe    f01015e5 <page_init+0xaa>
f01015c6:	39 d8                	cmp    %ebx,%eax
f01015c8:	73 1b                	jae    f01015e5 <page_init+0xaa>
			pages[i].pp_ref = 1;
f01015ca:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
f01015d1:	03 15 8c 99 11 f0    	add    0xf011998c,%edx
f01015d7:	66 c7 42 04 01 00    	movw   $0x1,0x4(%edx)
			pages[i].pp_link = NULL;
f01015dd:	c7 02 00 00 00 00    	movl   $0x0,(%edx)
			continue;
f01015e3:	eb 1f                	jmp    f0101604 <page_init+0xc9>
		}
		pages[i].pp_ref = 0;
f01015e5:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
f01015ec:	8b 35 8c 99 11 f0    	mov    0xf011998c,%esi
f01015f2:	66 c7 44 16 04 00 00 	movw   $0x0,0x4(%esi,%edx,1)
	//	cprintf("%d\n", i);
		pages[i].pp_link = page_free_list;
f01015f9:	89 0c c6             	mov    %ecx,(%esi,%eax,8)
		page_free_list = &pages[i];
f01015fc:	89 d1                	mov    %edx,%ecx
f01015fe:	03 0d 8c 99 11 f0    	add    0xf011998c,%ecx
	size_t low = IOPHYSMEM / PGSIZE;	
	size_t top = (PADDR(boot_alloc(0))) / PGSIZE;
	cprintf("!!%d %d %d\n", npages, low, top);
//	cprintf("00");
	page_free_list = NULL;
	for (i = 0; i < npages; i++) {
f0101604:	83 c0 01             	add    $0x1,%eax
f0101607:	39 05 84 99 11 f0    	cmp    %eax,0xf0119984
f010160d:	77 ac                	ja     f01015bb <page_init+0x80>
f010160f:	89 0d 60 95 11 f0    	mov    %ecx,0xf0119560
		pages[i].pp_ref = 0;
	//	cprintf("%d\n", i);
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
}
f0101615:	83 c4 10             	add    $0x10,%esp
f0101618:	5b                   	pop    %ebx
f0101619:	5e                   	pop    %esi
f010161a:	5d                   	pop    %ebp
f010161b:	c3                   	ret    

f010161c <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f010161c:	55                   	push   %ebp
f010161d:	89 e5                	mov    %esp,%ebp
f010161f:	83 ec 18             	sub    $0x18,%esp
	// Fill this function in
	if (page_free_list != NULL) {
f0101622:	a1 60 95 11 f0       	mov    0xf0119560,%eax
f0101627:	85 c0                	test   %eax,%eax
f0101629:	74 6b                	je     f0101696 <page_alloc+0x7a>
		if (alloc_flags & ALLOC_ZERO) {
f010162b:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f010162f:	74 56                	je     f0101687 <page_alloc+0x6b>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101631:	2b 05 8c 99 11 f0    	sub    0xf011998c,%eax
f0101637:	c1 f8 03             	sar    $0x3,%eax
f010163a:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010163d:	89 c2                	mov    %eax,%edx
f010163f:	c1 ea 0c             	shr    $0xc,%edx
f0101642:	3b 15 84 99 11 f0    	cmp    0xf0119984,%edx
f0101648:	72 20                	jb     f010166a <page_alloc+0x4e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010164a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010164e:	c7 44 24 08 6c 4c 10 	movl   $0xf0104c6c,0x8(%esp)
f0101655:	f0 
f0101656:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f010165d:	00 
f010165e:	c7 04 24 24 56 10 f0 	movl   $0xf0105624,(%esp)
f0101665:	e8 2a ea ff ff       	call   f0100094 <_panic>
//			cprintf("\n````!!!");
			memset(page2kva(page_free_list), 0, PGSIZE);
f010166a:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101671:	00 
f0101672:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101679:	00 
	return (void *)(pa + KERNBASE);
f010167a:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010167f:	89 04 24             	mov    %eax,(%esp)
f0101682:	e8 ca 2a 00 00       	call   f0104151 <memset>
		}
		struct PageInfo* temp = page_free_list;
f0101687:	a1 60 95 11 f0       	mov    0xf0119560,%eax
		page_free_list = page_free_list->pp_link;
f010168c:	8b 10                	mov    (%eax),%edx
f010168e:	89 15 60 95 11 f0    	mov    %edx,0xf0119560
//		return (struct PageInfo*) page_free_list;
		return temp;
f0101694:	eb 05                	jmp    f010169b <page_alloc+0x7f>
	}
	return NULL;
f0101696:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010169b:	c9                   	leave  
f010169c:	c3                   	ret    

f010169d <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f010169d:	55                   	push   %ebp
f010169e:	89 e5                	mov    %esp,%ebp
f01016a0:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	pp->pp_link = page_free_list;
f01016a3:	8b 15 60 95 11 f0    	mov    0xf0119560,%edx
f01016a9:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f01016ab:	a3 60 95 11 f0       	mov    %eax,0xf0119560
}
f01016b0:	5d                   	pop    %ebp
f01016b1:	c3                   	ret    

f01016b2 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f01016b2:	55                   	push   %ebp
f01016b3:	89 e5                	mov    %esp,%ebp
f01016b5:	83 ec 04             	sub    $0x4,%esp
f01016b8:	8b 45 08             	mov    0x8(%ebp),%eax
	if (--pp->pp_ref == 0)
f01016bb:	0f b7 50 04          	movzwl 0x4(%eax),%edx
f01016bf:	83 ea 01             	sub    $0x1,%edx
f01016c2:	66 89 50 04          	mov    %dx,0x4(%eax)
f01016c6:	66 85 d2             	test   %dx,%dx
f01016c9:	75 08                	jne    f01016d3 <page_decref+0x21>
		page_free(pp);
f01016cb:	89 04 24             	mov    %eax,(%esp)
f01016ce:	e8 ca ff ff ff       	call   f010169d <page_free>
}
f01016d3:	c9                   	leave  
f01016d4:	c3                   	ret    

f01016d5 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f01016d5:	55                   	push   %ebp
f01016d6:	89 e5                	mov    %esp,%ebp
f01016d8:	56                   	push   %esi
f01016d9:	53                   	push   %ebx
f01016da:	83 ec 10             	sub    $0x10,%esp
f01016dd:	8b 75 0c             	mov    0xc(%ebp),%esi
	// Fill this function in
	bool exist = false;
	pte_t *ptdir;
	if	(pgdir[PDX(va)] & PTE_P) {
f01016e0:	89 f3                	mov    %esi,%ebx
f01016e2:	c1 eb 16             	shr    $0x16,%ebx
f01016e5:	c1 e3 02             	shl    $0x2,%ebx
f01016e8:	03 5d 08             	add    0x8(%ebp),%ebx
f01016eb:	8b 03                	mov    (%ebx),%eax
f01016ed:	a8 01                	test   $0x1,%al
f01016ef:	74 47                	je     f0101738 <pgdir_walk+0x63>
//		pte_t * ptdir = (pte_t*) (PGNUM(*(pgdir + PDX(va))) << PGSHIFT);
		ptdir = (pte_t*) KADDR(PTE_ADDR(pgdir[PDX(va)]));
f01016f1:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01016f6:	89 c2                	mov    %eax,%edx
f01016f8:	c1 ea 0c             	shr    $0xc,%edx
f01016fb:	3b 15 84 99 11 f0    	cmp    0xf0119984,%edx
f0101701:	72 20                	jb     f0101723 <pgdir_walk+0x4e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101703:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101707:	c7 44 24 08 6c 4c 10 	movl   $0xf0104c6c,0x8(%esp)
f010170e:	f0 
f010170f:	c7 44 24 04 65 01 00 	movl   $0x165,0x4(%esp)
f0101716:	00 
f0101717:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f010171e:	e8 71 e9 ff ff       	call   f0100094 <_panic>
//		pgdir[PDX(va)];
//		cprintf("%d", va);
		return ptdir + PTX(va);
f0101723:	c1 ee 0a             	shr    $0xa,%esi
f0101726:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f010172c:	8d 84 30 00 00 00 f0 	lea    -0x10000000(%eax,%esi,1),%eax
f0101733:	e9 85 00 00 00       	jmp    f01017bd <pgdir_walk+0xe8>
	} else {
		if (create) {
f0101738:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f010173c:	74 73                	je     f01017b1 <pgdir_walk+0xdc>
			struct PageInfo * temp = page_alloc(ALLOC_ZERO);
f010173e:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101745:	e8 d2 fe ff ff       	call   f010161c <page_alloc>
			if (temp == NULL) return NULL;
f010174a:	85 c0                	test   %eax,%eax
f010174c:	74 6a                	je     f01017b8 <pgdir_walk+0xe3>
			temp->pp_ref++;
f010174e:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101753:	89 c2                	mov    %eax,%edx
f0101755:	2b 15 8c 99 11 f0    	sub    0xf011998c,%edx
f010175b:	c1 fa 03             	sar    $0x3,%edx
f010175e:	c1 e2 0c             	shl    $0xc,%edx
			pgdir[PDX(va)] = page2pa(temp) | PTE_P | PTE_U | PTE_W;
f0101761:	83 ca 07             	or     $0x7,%edx
f0101764:	89 13                	mov    %edx,(%ebx)
f0101766:	2b 05 8c 99 11 f0    	sub    0xf011998c,%eax
f010176c:	c1 f8 03             	sar    $0x3,%eax
f010176f:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101772:	89 c2                	mov    %eax,%edx
f0101774:	c1 ea 0c             	shr    $0xc,%edx
f0101777:	3b 15 84 99 11 f0    	cmp    0xf0119984,%edx
f010177d:	72 20                	jb     f010179f <pgdir_walk+0xca>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010177f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101783:	c7 44 24 08 6c 4c 10 	movl   $0xf0104c6c,0x8(%esp)
f010178a:	f0 
f010178b:	c7 44 24 04 6f 01 00 	movl   $0x16f,0x4(%esp)
f0101792:	00 
f0101793:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f010179a:	e8 f5 e8 ff ff       	call   f0100094 <_panic>
			ptdir = (pte_t*) KADDR(page2pa(temp));
			return ptdir + PTX(va);
f010179f:	c1 ee 0a             	shr    $0xa,%esi
f01017a2:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f01017a8:	8d 84 30 00 00 00 f0 	lea    -0x10000000(%eax,%esi,1),%eax
f01017af:	eb 0c                	jmp    f01017bd <pgdir_walk+0xe8>
		} else return NULL;
f01017b1:	b8 00 00 00 00       	mov    $0x0,%eax
f01017b6:	eb 05                	jmp    f01017bd <pgdir_walk+0xe8>
//		cprintf("%d", va);
		return ptdir + PTX(va);
	} else {
		if (create) {
			struct PageInfo * temp = page_alloc(ALLOC_ZERO);
			if (temp == NULL) return NULL;
f01017b8:	b8 00 00 00 00       	mov    $0x0,%eax
			return ptdir + PTX(va);
		} else return NULL;
	}
	//temp + PTXSHIFT(va)
	return NULL;
}
f01017bd:	83 c4 10             	add    $0x10,%esp
f01017c0:	5b                   	pop    %ebx
f01017c1:	5e                   	pop    %esi
f01017c2:	5d                   	pop    %ebp
f01017c3:	c3                   	ret    

f01017c4 <boot_map_region>:
// mapped pages.
// 
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f01017c4:	55                   	push   %ebp
f01017c5:	89 e5                	mov    %esp,%ebp
f01017c7:	57                   	push   %edi
f01017c8:	56                   	push   %esi
f01017c9:	53                   	push   %ebx
f01017ca:	83 ec 2c             	sub    $0x2c,%esp
f01017cd:	89 c7                	mov    %eax,%edi
f01017cf:	89 d3                	mov    %edx,%ebx
f01017d1:	8b 75 08             	mov    0x8(%ebp),%esi
	// Fill this function in
	uintptr_t end = va + size;
f01017d4:	01 d1                	add    %edx,%ecx
f01017d6:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	pte_t* now;
	for (;va != end; va += PGSIZE, pa += PGSIZE) {
f01017d9:	39 ca                	cmp    %ecx,%edx
f01017db:	74 5b                	je     f0101838 <boot_map_region+0x74>
		now = pgdir_walk(pgdir, (void*)va, 1);
		if (now == NULL)
			panic("stopped");
		*now = PTE_ADDR(pa) | perm | PTE_P;
f01017dd:	8b 45 0c             	mov    0xc(%ebp),%eax
f01017e0:	83 c8 01             	or     $0x1,%eax
f01017e3:	89 45 e0             	mov    %eax,-0x20(%ebp)
{
	// Fill this function in
	uintptr_t end = va + size;
	pte_t* now;
	for (;va != end; va += PGSIZE, pa += PGSIZE) {
		now = pgdir_walk(pgdir, (void*)va, 1);
f01017e6:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01017ed:	00 
f01017ee:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01017f2:	89 3c 24             	mov    %edi,(%esp)
f01017f5:	e8 db fe ff ff       	call   f01016d5 <pgdir_walk>
		if (now == NULL)
f01017fa:	85 c0                	test   %eax,%eax
f01017fc:	75 1c                	jne    f010181a <boot_map_region+0x56>
			panic("stopped");
f01017fe:	c7 44 24 08 da 56 10 	movl   $0xf01056da,0x8(%esp)
f0101805:	f0 
f0101806:	c7 44 24 04 8a 01 00 	movl   $0x18a,0x4(%esp)
f010180d:	00 
f010180e:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f0101815:	e8 7a e8 ff ff       	call   f0100094 <_panic>
		*now = PTE_ADDR(pa) | perm | PTE_P;
f010181a:	89 f2                	mov    %esi,%edx
f010181c:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101822:	0b 55 e0             	or     -0x20(%ebp),%edx
f0101825:	89 10                	mov    %edx,(%eax)
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	uintptr_t end = va + size;
	pte_t* now;
	for (;va != end; va += PGSIZE, pa += PGSIZE) {
f0101827:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f010182d:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0101833:	39 5d e4             	cmp    %ebx,-0x1c(%ebp)
f0101836:	75 ae                	jne    f01017e6 <boot_map_region+0x22>
		now = pgdir_walk(pgdir, (void*)va, 1);
		if (now == NULL)
			panic("stopped");
		*now = PTE_ADDR(pa) | perm | PTE_P;
	}
}
f0101838:	83 c4 2c             	add    $0x2c,%esp
f010183b:	5b                   	pop    %ebx
f010183c:	5e                   	pop    %esi
f010183d:	5f                   	pop    %edi
f010183e:	5d                   	pop    %ebp
f010183f:	c3                   	ret    

f0101840 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0101840:	55                   	push   %ebp
f0101841:	89 e5                	mov    %esp,%ebp
f0101843:	53                   	push   %ebx
f0101844:	83 ec 14             	sub    $0x14,%esp
f0101847:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// Fill this function in
	pte_t* now = pgdir_walk(pgdir, va, 0);
f010184a:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101851:	00 
f0101852:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101855:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101859:	8b 45 08             	mov    0x8(%ebp),%eax
f010185c:	89 04 24             	mov    %eax,(%esp)
f010185f:	e8 71 fe ff ff       	call   f01016d5 <pgdir_walk>
	if (now != NULL) {
f0101864:	85 c0                	test   %eax,%eax
f0101866:	74 3a                	je     f01018a2 <page_lookup+0x62>
		if (pte_store != NULL) {
f0101868:	85 db                	test   %ebx,%ebx
f010186a:	74 02                	je     f010186e <page_lookup+0x2e>
			*pte_store = now;
f010186c:	89 03                	mov    %eax,(%ebx)
		}
		return pa2page(PTE_ADDR(*now));
f010186e:	8b 00                	mov    (%eax),%eax
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101870:	c1 e8 0c             	shr    $0xc,%eax
f0101873:	3b 05 84 99 11 f0    	cmp    0xf0119984,%eax
f0101879:	72 1c                	jb     f0101897 <page_lookup+0x57>
		panic("pa2page called with invalid pa");
f010187b:	c7 44 24 08 08 50 10 	movl   $0xf0105008,0x8(%esp)
f0101882:	f0 
f0101883:	c7 44 24 04 4b 00 00 	movl   $0x4b,0x4(%esp)
f010188a:	00 
f010188b:	c7 04 24 24 56 10 f0 	movl   $0xf0105624,(%esp)
f0101892:	e8 fd e7 ff ff       	call   f0100094 <_panic>
	return &pages[PGNUM(pa)];
f0101897:	c1 e0 03             	shl    $0x3,%eax
f010189a:	03 05 8c 99 11 f0    	add    0xf011998c,%eax
f01018a0:	eb 05                	jmp    f01018a7 <page_lookup+0x67>
	}
	return NULL;
f01018a2:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01018a7:	83 c4 14             	add    $0x14,%esp
f01018aa:	5b                   	pop    %ebx
f01018ab:	5d                   	pop    %ebp
f01018ac:	c3                   	ret    

f01018ad <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f01018ad:	55                   	push   %ebp
f01018ae:	89 e5                	mov    %esp,%ebp
f01018b0:	83 ec 28             	sub    $0x28,%esp
	// Fill this function in
//	if (pgdir & PTE_P == 1) {
	pte_t* now;	
	struct PageInfo* temp = page_lookup(pgdir, va, &now);
f01018b3:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01018b6:	89 44 24 08          	mov    %eax,0x8(%esp)
f01018ba:	8b 45 0c             	mov    0xc(%ebp),%eax
f01018bd:	89 44 24 04          	mov    %eax,0x4(%esp)
f01018c1:	8b 45 08             	mov    0x8(%ebp),%eax
f01018c4:	89 04 24             	mov    %eax,(%esp)
f01018c7:	e8 74 ff ff ff       	call   f0101840 <page_lookup>
	if (temp != NULL) {
f01018cc:	85 c0                	test   %eax,%eax
f01018ce:	74 19                	je     f01018e9 <page_remove+0x3c>
//		cprintf("%d", now);
		if (*now & PTE_P) {
f01018d0:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01018d3:	f6 02 01             	testb  $0x1,(%edx)
f01018d6:	74 08                	je     f01018e0 <page_remove+0x33>
//			cprintf("subtraction finish!");
			page_decref(temp);
f01018d8:	89 04 24             	mov    %eax,(%esp)
f01018db:	e8 d2 fd ff ff       	call   f01016b2 <page_decref>
		}
		//page_decref(temp);
	//}
		*now = 0;
f01018e0:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01018e3:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	}

}
f01018e9:	c9                   	leave  
f01018ea:	c3                   	ret    

f01018eb <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa隐式声明函数‘page_walk’.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f01018eb:	55                   	push   %ebp
f01018ec:	89 e5                	mov    %esp,%ebp
f01018ee:	83 ec 28             	sub    $0x28,%esp
f01018f1:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f01018f4:	89 75 f8             	mov    %esi,-0x8(%ebp)
f01018f7:	89 7d fc             	mov    %edi,-0x4(%ebp)
f01018fa:	8b 75 0c             	mov    0xc(%ebp),%esi
f01018fd:	8b 7d 10             	mov    0x10(%ebp),%edi
	// Fill this function in
	pte_t* now = pgdir_walk(pgdir, va, 0);
f0101900:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101907:	00 
f0101908:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010190c:	8b 45 08             	mov    0x8(%ebp),%eax
f010190f:	89 04 24             	mov    %eax,(%esp)
f0101912:	e8 be fd ff ff       	call   f01016d5 <pgdir_walk>
f0101917:	89 c3                	mov    %eax,%ebx
	if ((now != NULL) && (*now & PTE_P)) {
f0101919:	85 c0                	test   %eax,%eax
f010191b:	74 3f                	je     f010195c <page_insert+0x71>
f010191d:	8b 00                	mov    (%eax),%eax
f010191f:	a8 01                	test   $0x1,%al
f0101921:	74 5b                	je     f010197e <page_insert+0x93>
		//cprintf("!");
//		PageInfo* now_page = (PageInfo*) pa2page(PTE_ADDR(now) + PGOFF(va));
//		page_remove(now_page);
		if (PTE_ADDR(*now) == page2pa(pp)) {
f0101923:	25 00 f0 ff ff       	and    $0xfffff000,%eax
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101928:	89 f2                	mov    %esi,%edx
f010192a:	2b 15 8c 99 11 f0    	sub    0xf011998c,%edx
f0101930:	c1 fa 03             	sar    $0x3,%edx
f0101933:	c1 e2 0c             	shl    $0xc,%edx
f0101936:	39 d0                	cmp    %edx,%eax
f0101938:	75 11                	jne    f010194b <page_insert+0x60>
			*now = PTE_ADDR(page2pa(pp)) | perm | PTE_P;
f010193a:	8b 55 14             	mov    0x14(%ebp),%edx
f010193d:	83 ca 01             	or     $0x1,%edx
f0101940:	09 d0                	or     %edx,%eax
f0101942:	89 03                	mov    %eax,(%ebx)
			return 0;
f0101944:	b8 00 00 00 00       	mov    $0x0,%eax
f0101949:	eb 55                	jmp    f01019a0 <page_insert+0xb5>
		}
//		cprintf("%d\n", *now);
		page_remove(pgdir, va);
f010194b:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010194f:	8b 45 08             	mov    0x8(%ebp),%eax
f0101952:	89 04 24             	mov    %eax,(%esp)
f0101955:	e8 53 ff ff ff       	call   f01018ad <page_remove>
f010195a:	eb 22                	jmp    f010197e <page_insert+0x93>
	}
	if (now == NULL) now = pgdir_walk(pgdir, va, 1);
f010195c:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0101963:	00 
f0101964:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101968:	8b 45 08             	mov    0x8(%ebp),%eax
f010196b:	89 04 24             	mov    %eax,(%esp)
f010196e:	e8 62 fd ff ff       	call   f01016d5 <pgdir_walk>
f0101973:	89 c3                	mov    %eax,%ebx
	if (now == NULL) return -E_NO_MEM;
f0101975:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f010197a:	85 db                	test   %ebx,%ebx
f010197c:	74 22                	je     f01019a0 <page_insert+0xb5>
	*now = PTE_ADDR(page2pa(pp)) | perm | PTE_P;
f010197e:	8b 45 14             	mov    0x14(%ebp),%eax
f0101981:	83 c8 01             	or     $0x1,%eax
f0101984:	89 f2                	mov    %esi,%edx
f0101986:	2b 15 8c 99 11 f0    	sub    0xf011998c,%edx
f010198c:	c1 fa 03             	sar    $0x3,%edx
f010198f:	c1 e2 0c             	shl    $0xc,%edx
f0101992:	09 d0                	or     %edx,%eax
f0101994:	89 03                	mov    %eax,(%ebx)
	pp->pp_ref++;
f0101996:	66 83 46 04 01       	addw   $0x1,0x4(%esi)
	return 0;
f010199b:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01019a0:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f01019a3:	8b 75 f8             	mov    -0x8(%ebp),%esi
f01019a6:	8b 7d fc             	mov    -0x4(%ebp),%edi
f01019a9:	89 ec                	mov    %ebp,%esp
f01019ab:	5d                   	pop    %ebp
f01019ac:	c3                   	ret    

f01019ad <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f01019ad:	55                   	push   %ebp
f01019ae:	89 e5                	mov    %esp,%ebp
f01019b0:	57                   	push   %edi
f01019b1:	56                   	push   %esi
f01019b2:	53                   	push   %ebx
f01019b3:	83 ec 3c             	sub    $0x3c,%esp
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f01019b6:	b8 15 00 00 00       	mov    $0x15,%eax
f01019bb:	e8 ed f7 ff ff       	call   f01011ad <nvram_read>
f01019c0:	c1 e0 0a             	shl    $0xa,%eax
f01019c3:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f01019c9:	85 c0                	test   %eax,%eax
f01019cb:	0f 48 c2             	cmovs  %edx,%eax
f01019ce:	c1 f8 0c             	sar    $0xc,%eax
f01019d1:	a3 58 95 11 f0       	mov    %eax,0xf0119558
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f01019d6:	b8 17 00 00 00       	mov    $0x17,%eax
f01019db:	e8 cd f7 ff ff       	call   f01011ad <nvram_read>
f01019e0:	c1 e0 0a             	shl    $0xa,%eax
f01019e3:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f01019e9:	85 c0                	test   %eax,%eax
f01019eb:	0f 48 c2             	cmovs  %edx,%eax
f01019ee:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f01019f1:	85 c0                	test   %eax,%eax
f01019f3:	74 0e                	je     f0101a03 <mem_init+0x56>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f01019f5:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f01019fb:	89 15 84 99 11 f0    	mov    %edx,0xf0119984
f0101a01:	eb 0c                	jmp    f0101a0f <mem_init+0x62>
	else
		npages = npages_basemem;
f0101a03:	8b 15 58 95 11 f0    	mov    0xf0119558,%edx
f0101a09:	89 15 84 99 11 f0    	mov    %edx,0xf0119984

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
		npages_extmem * PGSIZE / 1024);
f0101a0f:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101a12:	c1 e8 0a             	shr    $0xa,%eax
f0101a15:	89 44 24 0c          	mov    %eax,0xc(%esp)
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
f0101a19:	a1 58 95 11 f0       	mov    0xf0119558,%eax
f0101a1e:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101a21:	c1 e8 0a             	shr    $0xa,%eax
f0101a24:	89 44 24 08          	mov    %eax,0x8(%esp)
		npages * PGSIZE / 1024,
f0101a28:	a1 84 99 11 f0       	mov    0xf0119984,%eax
f0101a2d:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101a30:	c1 e8 0a             	shr    $0xa,%eax
f0101a33:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101a37:	c7 04 24 28 50 10 f0 	movl   $0xf0105028,(%esp)
f0101a3e:	e8 4b 1b 00 00       	call   f010358e <cprintf>
	// Remove this line when you're ready to test this function.
//	panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0101a43:	b8 00 10 00 00       	mov    $0x1000,%eax
f0101a48:	e8 b3 f6 ff ff       	call   f0101100 <boot_alloc>
f0101a4d:	a3 88 99 11 f0       	mov    %eax,0xf0119988
	memset(kern_pgdir, 0, PGSIZE);
f0101a52:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101a59:	00 
f0101a5a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101a61:	00 
f0101a62:	89 04 24             	mov    %eax,(%esp)
f0101a65:	e8 e7 26 00 00       	call   f0104151 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0101a6a:	a1 88 99 11 f0       	mov    0xf0119988,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0101a6f:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101a74:	77 20                	ja     f0101a96 <mem_init+0xe9>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101a76:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101a7a:	c7 44 24 08 e4 4f 10 	movl   $0xf0104fe4,0x8(%esp)
f0101a81:	f0 
f0101a82:	c7 44 24 04 91 00 00 	movl   $0x91,0x4(%esp)
f0101a89:	00 
f0101a8a:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f0101a91:	e8 fe e5 ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0101a96:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0101a9c:	83 ca 05             	or     $0x5,%edx
f0101a9f:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate an array of npages 'struct PageInfo's and store it in 'pages'.
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.
	// Your code goes here:
	pages = (struct PageInfo*) boot_alloc(npages * sizeof(struct PageInfo));
f0101aa5:	a1 84 99 11 f0       	mov    0xf0119984,%eax
f0101aaa:	c1 e0 03             	shl    $0x3,%eax
f0101aad:	e8 4e f6 ff ff       	call   f0101100 <boot_alloc>
f0101ab2:	a3 8c 99 11 f0       	mov    %eax,0xf011998c
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f0101ab7:	e8 7f fa ff ff       	call   f010153b <page_init>
	//cprintf("!!!");

	check_page_free_list(1);
f0101abc:	b8 01 00 00 00       	mov    $0x1,%eax
f0101ac1:	e8 19 f7 ff ff       	call   f01011df <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f0101ac6:	83 3d 8c 99 11 f0 00 	cmpl   $0x0,0xf011998c
f0101acd:	75 1c                	jne    f0101aeb <mem_init+0x13e>
		panic("'pages' is a null pointer!");
f0101acf:	c7 44 24 08 e2 56 10 	movl   $0xf01056e2,0x8(%esp)
f0101ad6:	f0 
f0101ad7:	c7 44 24 04 55 02 00 	movl   $0x255,0x4(%esp)
f0101ade:	00 
f0101adf:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f0101ae6:	e8 a9 e5 ff ff       	call   f0100094 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101aeb:	a1 60 95 11 f0       	mov    0xf0119560,%eax
f0101af0:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101af5:	85 c0                	test   %eax,%eax
f0101af7:	74 09                	je     f0101b02 <mem_init+0x155>
		++nfree;
f0101af9:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101afc:	8b 00                	mov    (%eax),%eax
f0101afe:	85 c0                	test   %eax,%eax
f0101b00:	75 f7                	jne    f0101af9 <mem_init+0x14c>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101b02:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101b09:	e8 0e fb ff ff       	call   f010161c <page_alloc>
f0101b0e:	89 c6                	mov    %eax,%esi
f0101b10:	85 c0                	test   %eax,%eax
f0101b12:	75 24                	jne    f0101b38 <mem_init+0x18b>
f0101b14:	c7 44 24 0c fd 56 10 	movl   $0xf01056fd,0xc(%esp)
f0101b1b:	f0 
f0101b1c:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f0101b23:	f0 
f0101b24:	c7 44 24 04 5d 02 00 	movl   $0x25d,0x4(%esp)
f0101b2b:	00 
f0101b2c:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f0101b33:	e8 5c e5 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f0101b38:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101b3f:	e8 d8 fa ff ff       	call   f010161c <page_alloc>
f0101b44:	89 c7                	mov    %eax,%edi
f0101b46:	85 c0                	test   %eax,%eax
f0101b48:	75 24                	jne    f0101b6e <mem_init+0x1c1>
f0101b4a:	c7 44 24 0c 13 57 10 	movl   $0xf0105713,0xc(%esp)
f0101b51:	f0 
f0101b52:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f0101b59:	f0 
f0101b5a:	c7 44 24 04 5e 02 00 	movl   $0x25e,0x4(%esp)
f0101b61:	00 
f0101b62:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f0101b69:	e8 26 e5 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0101b6e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101b75:	e8 a2 fa ff ff       	call   f010161c <page_alloc>
f0101b7a:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101b7d:	85 c0                	test   %eax,%eax
f0101b7f:	75 24                	jne    f0101ba5 <mem_init+0x1f8>
f0101b81:	c7 44 24 0c 29 57 10 	movl   $0xf0105729,0xc(%esp)
f0101b88:	f0 
f0101b89:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f0101b90:	f0 
f0101b91:	c7 44 24 04 5f 02 00 	movl   $0x25f,0x4(%esp)
f0101b98:	00 
f0101b99:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f0101ba0:	e8 ef e4 ff ff       	call   f0100094 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101ba5:	39 fe                	cmp    %edi,%esi
f0101ba7:	75 24                	jne    f0101bcd <mem_init+0x220>
f0101ba9:	c7 44 24 0c 3f 57 10 	movl   $0xf010573f,0xc(%esp)
f0101bb0:	f0 
f0101bb1:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f0101bb8:	f0 
f0101bb9:	c7 44 24 04 62 02 00 	movl   $0x262,0x4(%esp)
f0101bc0:	00 
f0101bc1:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f0101bc8:	e8 c7 e4 ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101bcd:	3b 7d d4             	cmp    -0x2c(%ebp),%edi
f0101bd0:	74 05                	je     f0101bd7 <mem_init+0x22a>
f0101bd2:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f0101bd5:	75 24                	jne    f0101bfb <mem_init+0x24e>
f0101bd7:	c7 44 24 0c 64 50 10 	movl   $0xf0105064,0xc(%esp)
f0101bde:	f0 
f0101bdf:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f0101be6:	f0 
f0101be7:	c7 44 24 04 63 02 00 	movl   $0x263,0x4(%esp)
f0101bee:	00 
f0101bef:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f0101bf6:	e8 99 e4 ff ff       	call   f0100094 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101bfb:	8b 15 8c 99 11 f0    	mov    0xf011998c,%edx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101c01:	a1 84 99 11 f0       	mov    0xf0119984,%eax
f0101c06:	c1 e0 0c             	shl    $0xc,%eax
f0101c09:	89 f1                	mov    %esi,%ecx
f0101c0b:	29 d1                	sub    %edx,%ecx
f0101c0d:	c1 f9 03             	sar    $0x3,%ecx
f0101c10:	c1 e1 0c             	shl    $0xc,%ecx
f0101c13:	39 c1                	cmp    %eax,%ecx
f0101c15:	72 24                	jb     f0101c3b <mem_init+0x28e>
f0101c17:	c7 44 24 0c 51 57 10 	movl   $0xf0105751,0xc(%esp)
f0101c1e:	f0 
f0101c1f:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f0101c26:	f0 
f0101c27:	c7 44 24 04 64 02 00 	movl   $0x264,0x4(%esp)
f0101c2e:	00 
f0101c2f:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f0101c36:	e8 59 e4 ff ff       	call   f0100094 <_panic>
f0101c3b:	89 f9                	mov    %edi,%ecx
f0101c3d:	29 d1                	sub    %edx,%ecx
f0101c3f:	c1 f9 03             	sar    $0x3,%ecx
f0101c42:	c1 e1 0c             	shl    $0xc,%ecx
	assert(page2pa(pp1) < npages*PGSIZE);
f0101c45:	39 c8                	cmp    %ecx,%eax
f0101c47:	77 24                	ja     f0101c6d <mem_init+0x2c0>
f0101c49:	c7 44 24 0c 6e 57 10 	movl   $0xf010576e,0xc(%esp)
f0101c50:	f0 
f0101c51:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f0101c58:	f0 
f0101c59:	c7 44 24 04 65 02 00 	movl   $0x265,0x4(%esp)
f0101c60:	00 
f0101c61:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f0101c68:	e8 27 e4 ff ff       	call   f0100094 <_panic>
f0101c6d:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101c70:	29 d1                	sub    %edx,%ecx
f0101c72:	89 ca                	mov    %ecx,%edx
f0101c74:	c1 fa 03             	sar    $0x3,%edx
f0101c77:	c1 e2 0c             	shl    $0xc,%edx
	assert(page2pa(pp2) < npages*PGSIZE);
f0101c7a:	39 d0                	cmp    %edx,%eax
f0101c7c:	77 24                	ja     f0101ca2 <mem_init+0x2f5>
f0101c7e:	c7 44 24 0c 8b 57 10 	movl   $0xf010578b,0xc(%esp)
f0101c85:	f0 
f0101c86:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f0101c8d:	f0 
f0101c8e:	c7 44 24 04 66 02 00 	movl   $0x266,0x4(%esp)
f0101c95:	00 
f0101c96:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f0101c9d:	e8 f2 e3 ff ff       	call   f0100094 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101ca2:	a1 60 95 11 f0       	mov    0xf0119560,%eax
f0101ca7:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101caa:	c7 05 60 95 11 f0 00 	movl   $0x0,0xf0119560
f0101cb1:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101cb4:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101cbb:	e8 5c f9 ff ff       	call   f010161c <page_alloc>
f0101cc0:	85 c0                	test   %eax,%eax
f0101cc2:	74 24                	je     f0101ce8 <mem_init+0x33b>
f0101cc4:	c7 44 24 0c a8 57 10 	movl   $0xf01057a8,0xc(%esp)
f0101ccb:	f0 
f0101ccc:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f0101cd3:	f0 
f0101cd4:	c7 44 24 04 6d 02 00 	movl   $0x26d,0x4(%esp)
f0101cdb:	00 
f0101cdc:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f0101ce3:	e8 ac e3 ff ff       	call   f0100094 <_panic>

	// free and re-allocate?
	page_free(pp0);
f0101ce8:	89 34 24             	mov    %esi,(%esp)
f0101ceb:	e8 ad f9 ff ff       	call   f010169d <page_free>
	page_free(pp1);
f0101cf0:	89 3c 24             	mov    %edi,(%esp)
f0101cf3:	e8 a5 f9 ff ff       	call   f010169d <page_free>
	page_free(pp2);
f0101cf8:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101cfb:	89 04 24             	mov    %eax,(%esp)
f0101cfe:	e8 9a f9 ff ff       	call   f010169d <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101d03:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101d0a:	e8 0d f9 ff ff       	call   f010161c <page_alloc>
f0101d0f:	89 c6                	mov    %eax,%esi
f0101d11:	85 c0                	test   %eax,%eax
f0101d13:	75 24                	jne    f0101d39 <mem_init+0x38c>
f0101d15:	c7 44 24 0c fd 56 10 	movl   $0xf01056fd,0xc(%esp)
f0101d1c:	f0 
f0101d1d:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f0101d24:	f0 
f0101d25:	c7 44 24 04 74 02 00 	movl   $0x274,0x4(%esp)
f0101d2c:	00 
f0101d2d:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f0101d34:	e8 5b e3 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f0101d39:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101d40:	e8 d7 f8 ff ff       	call   f010161c <page_alloc>
f0101d45:	89 c7                	mov    %eax,%edi
f0101d47:	85 c0                	test   %eax,%eax
f0101d49:	75 24                	jne    f0101d6f <mem_init+0x3c2>
f0101d4b:	c7 44 24 0c 13 57 10 	movl   $0xf0105713,0xc(%esp)
f0101d52:	f0 
f0101d53:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f0101d5a:	f0 
f0101d5b:	c7 44 24 04 75 02 00 	movl   $0x275,0x4(%esp)
f0101d62:	00 
f0101d63:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f0101d6a:	e8 25 e3 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0101d6f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101d76:	e8 a1 f8 ff ff       	call   f010161c <page_alloc>
f0101d7b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101d7e:	85 c0                	test   %eax,%eax
f0101d80:	75 24                	jne    f0101da6 <mem_init+0x3f9>
f0101d82:	c7 44 24 0c 29 57 10 	movl   $0xf0105729,0xc(%esp)
f0101d89:	f0 
f0101d8a:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f0101d91:	f0 
f0101d92:	c7 44 24 04 76 02 00 	movl   $0x276,0x4(%esp)
f0101d99:	00 
f0101d9a:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f0101da1:	e8 ee e2 ff ff       	call   f0100094 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101da6:	39 fe                	cmp    %edi,%esi
f0101da8:	75 24                	jne    f0101dce <mem_init+0x421>
f0101daa:	c7 44 24 0c 3f 57 10 	movl   $0xf010573f,0xc(%esp)
f0101db1:	f0 
f0101db2:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f0101db9:	f0 
f0101dba:	c7 44 24 04 78 02 00 	movl   $0x278,0x4(%esp)
f0101dc1:	00 
f0101dc2:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f0101dc9:	e8 c6 e2 ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101dce:	3b 7d d4             	cmp    -0x2c(%ebp),%edi
f0101dd1:	74 05                	je     f0101dd8 <mem_init+0x42b>
f0101dd3:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f0101dd6:	75 24                	jne    f0101dfc <mem_init+0x44f>
f0101dd8:	c7 44 24 0c 64 50 10 	movl   $0xf0105064,0xc(%esp)
f0101ddf:	f0 
f0101de0:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f0101de7:	f0 
f0101de8:	c7 44 24 04 79 02 00 	movl   $0x279,0x4(%esp)
f0101def:	00 
f0101df0:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f0101df7:	e8 98 e2 ff ff       	call   f0100094 <_panic>
	assert(!page_alloc(0));
f0101dfc:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101e03:	e8 14 f8 ff ff       	call   f010161c <page_alloc>
f0101e08:	85 c0                	test   %eax,%eax
f0101e0a:	74 24                	je     f0101e30 <mem_init+0x483>
f0101e0c:	c7 44 24 0c a8 57 10 	movl   $0xf01057a8,0xc(%esp)
f0101e13:	f0 
f0101e14:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f0101e1b:	f0 
f0101e1c:	c7 44 24 04 7a 02 00 	movl   $0x27a,0x4(%esp)
f0101e23:	00 
f0101e24:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f0101e2b:	e8 64 e2 ff ff       	call   f0100094 <_panic>
f0101e30:	89 f0                	mov    %esi,%eax
f0101e32:	2b 05 8c 99 11 f0    	sub    0xf011998c,%eax
f0101e38:	c1 f8 03             	sar    $0x3,%eax
f0101e3b:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101e3e:	89 c2                	mov    %eax,%edx
f0101e40:	c1 ea 0c             	shr    $0xc,%edx
f0101e43:	3b 15 84 99 11 f0    	cmp    0xf0119984,%edx
f0101e49:	72 20                	jb     f0101e6b <mem_init+0x4be>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101e4b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101e4f:	c7 44 24 08 6c 4c 10 	movl   $0xf0104c6c,0x8(%esp)
f0101e56:	f0 
f0101e57:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0101e5e:	00 
f0101e5f:	c7 04 24 24 56 10 f0 	movl   $0xf0105624,(%esp)
f0101e66:	e8 29 e2 ff ff       	call   f0100094 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f0101e6b:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101e72:	00 
f0101e73:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0101e7a:	00 
	return (void *)(pa + KERNBASE);
f0101e7b:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101e80:	89 04 24             	mov    %eax,(%esp)
f0101e83:	e8 c9 22 00 00       	call   f0104151 <memset>
	page_free(pp0);
f0101e88:	89 34 24             	mov    %esi,(%esp)
f0101e8b:	e8 0d f8 ff ff       	call   f010169d <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101e90:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101e97:	e8 80 f7 ff ff       	call   f010161c <page_alloc>
f0101e9c:	85 c0                	test   %eax,%eax
f0101e9e:	75 24                	jne    f0101ec4 <mem_init+0x517>
f0101ea0:	c7 44 24 0c b7 57 10 	movl   $0xf01057b7,0xc(%esp)
f0101ea7:	f0 
f0101ea8:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f0101eaf:	f0 
f0101eb0:	c7 44 24 04 7f 02 00 	movl   $0x27f,0x4(%esp)
f0101eb7:	00 
f0101eb8:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f0101ebf:	e8 d0 e1 ff ff       	call   f0100094 <_panic>
	assert(pp && pp0 == pp);
f0101ec4:	39 c6                	cmp    %eax,%esi
f0101ec6:	74 24                	je     f0101eec <mem_init+0x53f>
f0101ec8:	c7 44 24 0c d5 57 10 	movl   $0xf01057d5,0xc(%esp)
f0101ecf:	f0 
f0101ed0:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f0101ed7:	f0 
f0101ed8:	c7 44 24 04 80 02 00 	movl   $0x280,0x4(%esp)
f0101edf:	00 
f0101ee0:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f0101ee7:	e8 a8 e1 ff ff       	call   f0100094 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101eec:	89 f2                	mov    %esi,%edx
f0101eee:	2b 15 8c 99 11 f0    	sub    0xf011998c,%edx
f0101ef4:	c1 fa 03             	sar    $0x3,%edx
f0101ef7:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101efa:	89 d0                	mov    %edx,%eax
f0101efc:	c1 e8 0c             	shr    $0xc,%eax
f0101eff:	3b 05 84 99 11 f0    	cmp    0xf0119984,%eax
f0101f05:	72 20                	jb     f0101f27 <mem_init+0x57a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101f07:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101f0b:	c7 44 24 08 6c 4c 10 	movl   $0xf0104c6c,0x8(%esp)
f0101f12:	f0 
f0101f13:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0101f1a:	00 
f0101f1b:	c7 04 24 24 56 10 f0 	movl   $0xf0105624,(%esp)
f0101f22:	e8 6d e1 ff ff       	call   f0100094 <_panic>
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++) 
		assert(c[i] == 0);
f0101f27:	80 ba 00 00 00 f0 00 	cmpb   $0x0,-0x10000000(%edx)
f0101f2e:	75 11                	jne    f0101f41 <mem_init+0x594>
f0101f30:	8d 82 01 00 00 f0    	lea    -0xfffffff(%edx),%eax
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0101f36:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++) 
		assert(c[i] == 0);
f0101f3c:	80 38 00             	cmpb   $0x0,(%eax)
f0101f3f:	74 24                	je     f0101f65 <mem_init+0x5b8>
f0101f41:	c7 44 24 0c e5 57 10 	movl   $0xf01057e5,0xc(%esp)
f0101f48:	f0 
f0101f49:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f0101f50:	f0 
f0101f51:	c7 44 24 04 83 02 00 	movl   $0x283,0x4(%esp)
f0101f58:	00 
f0101f59:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f0101f60:	e8 2f e1 ff ff       	call   f0100094 <_panic>
f0101f65:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++) 
f0101f68:	39 d0                	cmp    %edx,%eax
f0101f6a:	75 d0                	jne    f0101f3c <mem_init+0x58f>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101f6c:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0101f6f:	89 15 60 95 11 f0    	mov    %edx,0xf0119560

	// free the pages we took
	page_free(pp0);
f0101f75:	89 34 24             	mov    %esi,(%esp)
f0101f78:	e8 20 f7 ff ff       	call   f010169d <page_free>
	page_free(pp1);
f0101f7d:	89 3c 24             	mov    %edi,(%esp)
f0101f80:	e8 18 f7 ff ff       	call   f010169d <page_free>
	page_free(pp2);
f0101f85:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f88:	89 04 24             	mov    %eax,(%esp)
f0101f8b:	e8 0d f7 ff ff       	call   f010169d <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101f90:	a1 60 95 11 f0       	mov    0xf0119560,%eax
f0101f95:	85 c0                	test   %eax,%eax
f0101f97:	74 09                	je     f0101fa2 <mem_init+0x5f5>
		--nfree;
f0101f99:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101f9c:	8b 00                	mov    (%eax),%eax
f0101f9e:	85 c0                	test   %eax,%eax
f0101fa0:	75 f7                	jne    f0101f99 <mem_init+0x5ec>
		--nfree;
	assert(nfree == 0);
f0101fa2:	85 db                	test   %ebx,%ebx
f0101fa4:	74 24                	je     f0101fca <mem_init+0x61d>
f0101fa6:	c7 44 24 0c ef 57 10 	movl   $0xf01057ef,0xc(%esp)
f0101fad:	f0 
f0101fae:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f0101fb5:	f0 
f0101fb6:	c7 44 24 04 90 02 00 	movl   $0x290,0x4(%esp)
f0101fbd:	00 
f0101fbe:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f0101fc5:	e8 ca e0 ff ff       	call   f0100094 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f0101fca:	c7 04 24 84 50 10 f0 	movl   $0xf0105084,(%esp)
f0101fd1:	e8 b8 15 00 00       	call   f010358e <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101fd6:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101fdd:	e8 3a f6 ff ff       	call   f010161c <page_alloc>
f0101fe2:	89 c6                	mov    %eax,%esi
f0101fe4:	85 c0                	test   %eax,%eax
f0101fe6:	75 24                	jne    f010200c <mem_init+0x65f>
f0101fe8:	c7 44 24 0c fd 56 10 	movl   $0xf01056fd,0xc(%esp)
f0101fef:	f0 
f0101ff0:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f0101ff7:	f0 
f0101ff8:	c7 44 24 04 ec 02 00 	movl   $0x2ec,0x4(%esp)
f0101fff:	00 
f0102000:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f0102007:	e8 88 e0 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f010200c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102013:	e8 04 f6 ff ff       	call   f010161c <page_alloc>
f0102018:	89 c7                	mov    %eax,%edi
f010201a:	85 c0                	test   %eax,%eax
f010201c:	75 24                	jne    f0102042 <mem_init+0x695>
f010201e:	c7 44 24 0c 13 57 10 	movl   $0xf0105713,0xc(%esp)
f0102025:	f0 
f0102026:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f010202d:	f0 
f010202e:	c7 44 24 04 ed 02 00 	movl   $0x2ed,0x4(%esp)
f0102035:	00 
f0102036:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f010203d:	e8 52 e0 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0102042:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102049:	e8 ce f5 ff ff       	call   f010161c <page_alloc>
f010204e:	89 c3                	mov    %eax,%ebx
f0102050:	85 c0                	test   %eax,%eax
f0102052:	75 24                	jne    f0102078 <mem_init+0x6cb>
f0102054:	c7 44 24 0c 29 57 10 	movl   $0xf0105729,0xc(%esp)
f010205b:	f0 
f010205c:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f0102063:	f0 
f0102064:	c7 44 24 04 ee 02 00 	movl   $0x2ee,0x4(%esp)
f010206b:	00 
f010206c:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f0102073:	e8 1c e0 ff ff       	call   f0100094 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0102078:	39 fe                	cmp    %edi,%esi
f010207a:	75 24                	jne    f01020a0 <mem_init+0x6f3>
f010207c:	c7 44 24 0c 3f 57 10 	movl   $0xf010573f,0xc(%esp)
f0102083:	f0 
f0102084:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f010208b:	f0 
f010208c:	c7 44 24 04 f1 02 00 	movl   $0x2f1,0x4(%esp)
f0102093:	00 
f0102094:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f010209b:	e8 f4 df ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01020a0:	39 c7                	cmp    %eax,%edi
f01020a2:	74 04                	je     f01020a8 <mem_init+0x6fb>
f01020a4:	39 c6                	cmp    %eax,%esi
f01020a6:	75 24                	jne    f01020cc <mem_init+0x71f>
f01020a8:	c7 44 24 0c 64 50 10 	movl   $0xf0105064,0xc(%esp)
f01020af:	f0 
f01020b0:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f01020b7:	f0 
f01020b8:	c7 44 24 04 f2 02 00 	movl   $0x2f2,0x4(%esp)
f01020bf:	00 
f01020c0:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f01020c7:	e8 c8 df ff ff       	call   f0100094 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01020cc:	8b 15 60 95 11 f0    	mov    0xf0119560,%edx
f01020d2:	89 55 cc             	mov    %edx,-0x34(%ebp)
	page_free_list = 0;
f01020d5:	c7 05 60 95 11 f0 00 	movl   $0x0,0xf0119560
f01020dc:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01020df:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01020e6:	e8 31 f5 ff ff       	call   f010161c <page_alloc>
f01020eb:	85 c0                	test   %eax,%eax
f01020ed:	74 24                	je     f0102113 <mem_init+0x766>
f01020ef:	c7 44 24 0c a8 57 10 	movl   $0xf01057a8,0xc(%esp)
f01020f6:	f0 
f01020f7:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f01020fe:	f0 
f01020ff:	c7 44 24 04 f9 02 00 	movl   $0x2f9,0x4(%esp)
f0102106:	00 
f0102107:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f010210e:	e8 81 df ff ff       	call   f0100094 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0102113:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0102116:	89 44 24 08          	mov    %eax,0x8(%esp)
f010211a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102121:	00 
f0102122:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f0102127:	89 04 24             	mov    %eax,(%esp)
f010212a:	e8 11 f7 ff ff       	call   f0101840 <page_lookup>
f010212f:	85 c0                	test   %eax,%eax
f0102131:	74 24                	je     f0102157 <mem_init+0x7aa>
f0102133:	c7 44 24 0c a4 50 10 	movl   $0xf01050a4,0xc(%esp)
f010213a:	f0 
f010213b:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f0102142:	f0 
f0102143:	c7 44 24 04 fc 02 00 	movl   $0x2fc,0x4(%esp)
f010214a:	00 
f010214b:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f0102152:	e8 3d df ff ff       	call   f0100094 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0102157:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f010215e:	00 
f010215f:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102166:	00 
f0102167:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010216b:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f0102170:	89 04 24             	mov    %eax,(%esp)
f0102173:	e8 73 f7 ff ff       	call   f01018eb <page_insert>
f0102178:	85 c0                	test   %eax,%eax
f010217a:	78 24                	js     f01021a0 <mem_init+0x7f3>
f010217c:	c7 44 24 0c dc 50 10 	movl   $0xf01050dc,0xc(%esp)
f0102183:	f0 
f0102184:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f010218b:	f0 
f010218c:	c7 44 24 04 ff 02 00 	movl   $0x2ff,0x4(%esp)
f0102193:	00 
f0102194:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f010219b:	e8 f4 de ff ff       	call   f0100094 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f01021a0:	89 34 24             	mov    %esi,(%esp)
f01021a3:	e8 f5 f4 ff ff       	call   f010169d <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f01021a8:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01021af:	00 
f01021b0:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01021b7:	00 
f01021b8:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01021bc:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f01021c1:	89 04 24             	mov    %eax,(%esp)
f01021c4:	e8 22 f7 ff ff       	call   f01018eb <page_insert>
f01021c9:	85 c0                	test   %eax,%eax
f01021cb:	74 24                	je     f01021f1 <mem_init+0x844>
f01021cd:	c7 44 24 0c 0c 51 10 	movl   $0xf010510c,0xc(%esp)
f01021d4:	f0 
f01021d5:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f01021dc:	f0 
f01021dd:	c7 44 24 04 03 03 00 	movl   $0x303,0x4(%esp)
f01021e4:	00 
f01021e5:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f01021ec:	e8 a3 de ff ff       	call   f0100094 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01021f1:	8b 0d 88 99 11 f0    	mov    0xf0119988,%ecx
f01021f7:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01021fa:	a1 8c 99 11 f0       	mov    0xf011998c,%eax
f01021ff:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102202:	8b 11                	mov    (%ecx),%edx
f0102204:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010220a:	89 f0                	mov    %esi,%eax
f010220c:	2b 45 d0             	sub    -0x30(%ebp),%eax
f010220f:	c1 f8 03             	sar    $0x3,%eax
f0102212:	c1 e0 0c             	shl    $0xc,%eax
f0102215:	39 c2                	cmp    %eax,%edx
f0102217:	74 24                	je     f010223d <mem_init+0x890>
f0102219:	c7 44 24 0c 3c 51 10 	movl   $0xf010513c,0xc(%esp)
f0102220:	f0 
f0102221:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f0102228:	f0 
f0102229:	c7 44 24 04 04 03 00 	movl   $0x304,0x4(%esp)
f0102230:	00 
f0102231:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f0102238:	e8 57 de ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f010223d:	ba 00 00 00 00       	mov    $0x0,%edx
f0102242:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102245:	e8 f2 ee ff ff       	call   f010113c <check_va2pa>
f010224a:	89 fa                	mov    %edi,%edx
f010224c:	2b 55 d0             	sub    -0x30(%ebp),%edx
f010224f:	c1 fa 03             	sar    $0x3,%edx
f0102252:	c1 e2 0c             	shl    $0xc,%edx
f0102255:	39 d0                	cmp    %edx,%eax
f0102257:	74 24                	je     f010227d <mem_init+0x8d0>
f0102259:	c7 44 24 0c 64 51 10 	movl   $0xf0105164,0xc(%esp)
f0102260:	f0 
f0102261:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f0102268:	f0 
f0102269:	c7 44 24 04 05 03 00 	movl   $0x305,0x4(%esp)
f0102270:	00 
f0102271:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f0102278:	e8 17 de ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 1);
f010227d:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102282:	74 24                	je     f01022a8 <mem_init+0x8fb>
f0102284:	c7 44 24 0c fa 57 10 	movl   $0xf01057fa,0xc(%esp)
f010228b:	f0 
f010228c:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f0102293:	f0 
f0102294:	c7 44 24 04 06 03 00 	movl   $0x306,0x4(%esp)
f010229b:	00 
f010229c:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f01022a3:	e8 ec dd ff ff       	call   f0100094 <_panic>
	assert(pp0->pp_ref == 1);
f01022a8:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01022ad:	74 24                	je     f01022d3 <mem_init+0x926>
f01022af:	c7 44 24 0c 0b 58 10 	movl   $0xf010580b,0xc(%esp)
f01022b6:	f0 
f01022b7:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f01022be:	f0 
f01022bf:	c7 44 24 04 07 03 00 	movl   $0x307,0x4(%esp)
f01022c6:	00 
f01022c7:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f01022ce:	e8 c1 dd ff ff       	call   f0100094 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01022d3:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01022da:	00 
f01022db:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01022e2:	00 
f01022e3:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01022e7:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01022ea:	89 14 24             	mov    %edx,(%esp)
f01022ed:	e8 f9 f5 ff ff       	call   f01018eb <page_insert>
f01022f2:	85 c0                	test   %eax,%eax
f01022f4:	74 24                	je     f010231a <mem_init+0x96d>
f01022f6:	c7 44 24 0c 94 51 10 	movl   $0xf0105194,0xc(%esp)
f01022fd:	f0 
f01022fe:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f0102305:	f0 
f0102306:	c7 44 24 04 0a 03 00 	movl   $0x30a,0x4(%esp)
f010230d:	00 
f010230e:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f0102315:	e8 7a dd ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f010231a:	ba 00 10 00 00       	mov    $0x1000,%edx
f010231f:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f0102324:	e8 13 ee ff ff       	call   f010113c <check_va2pa>
f0102329:	89 da                	mov    %ebx,%edx
f010232b:	2b 15 8c 99 11 f0    	sub    0xf011998c,%edx
f0102331:	c1 fa 03             	sar    $0x3,%edx
f0102334:	c1 e2 0c             	shl    $0xc,%edx
f0102337:	39 d0                	cmp    %edx,%eax
f0102339:	74 24                	je     f010235f <mem_init+0x9b2>
f010233b:	c7 44 24 0c d0 51 10 	movl   $0xf01051d0,0xc(%esp)
f0102342:	f0 
f0102343:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f010234a:	f0 
f010234b:	c7 44 24 04 0b 03 00 	movl   $0x30b,0x4(%esp)
f0102352:	00 
f0102353:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f010235a:	e8 35 dd ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f010235f:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102364:	74 24                	je     f010238a <mem_init+0x9dd>
f0102366:	c7 44 24 0c 1c 58 10 	movl   $0xf010581c,0xc(%esp)
f010236d:	f0 
f010236e:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f0102375:	f0 
f0102376:	c7 44 24 04 0c 03 00 	movl   $0x30c,0x4(%esp)
f010237d:	00 
f010237e:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f0102385:	e8 0a dd ff ff       	call   f0100094 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f010238a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102391:	e8 86 f2 ff ff       	call   f010161c <page_alloc>
f0102396:	85 c0                	test   %eax,%eax
f0102398:	74 24                	je     f01023be <mem_init+0xa11>
f010239a:	c7 44 24 0c a8 57 10 	movl   $0xf01057a8,0xc(%esp)
f01023a1:	f0 
f01023a2:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f01023a9:	f0 
f01023aa:	c7 44 24 04 0f 03 00 	movl   $0x30f,0x4(%esp)
f01023b1:	00 
f01023b2:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f01023b9:	e8 d6 dc ff ff       	call   f0100094 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01023be:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01023c5:	00 
f01023c6:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01023cd:	00 
f01023ce:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01023d2:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f01023d7:	89 04 24             	mov    %eax,(%esp)
f01023da:	e8 0c f5 ff ff       	call   f01018eb <page_insert>
f01023df:	85 c0                	test   %eax,%eax
f01023e1:	74 24                	je     f0102407 <mem_init+0xa5a>
f01023e3:	c7 44 24 0c 94 51 10 	movl   $0xf0105194,0xc(%esp)
f01023ea:	f0 
f01023eb:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f01023f2:	f0 
f01023f3:	c7 44 24 04 12 03 00 	movl   $0x312,0x4(%esp)
f01023fa:	00 
f01023fb:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f0102402:	e8 8d dc ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0102407:	ba 00 10 00 00       	mov    $0x1000,%edx
f010240c:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f0102411:	e8 26 ed ff ff       	call   f010113c <check_va2pa>
f0102416:	89 da                	mov    %ebx,%edx
f0102418:	2b 15 8c 99 11 f0    	sub    0xf011998c,%edx
f010241e:	c1 fa 03             	sar    $0x3,%edx
f0102421:	c1 e2 0c             	shl    $0xc,%edx
f0102424:	39 d0                	cmp    %edx,%eax
f0102426:	74 24                	je     f010244c <mem_init+0xa9f>
f0102428:	c7 44 24 0c d0 51 10 	movl   $0xf01051d0,0xc(%esp)
f010242f:	f0 
f0102430:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f0102437:	f0 
f0102438:	c7 44 24 04 13 03 00 	movl   $0x313,0x4(%esp)
f010243f:	00 
f0102440:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f0102447:	e8 48 dc ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f010244c:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102451:	74 24                	je     f0102477 <mem_init+0xaca>
f0102453:	c7 44 24 0c 1c 58 10 	movl   $0xf010581c,0xc(%esp)
f010245a:	f0 
f010245b:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f0102462:	f0 
f0102463:	c7 44 24 04 14 03 00 	movl   $0x314,0x4(%esp)
f010246a:	00 
f010246b:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f0102472:	e8 1d dc ff ff       	call   f0100094 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0102477:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010247e:	e8 99 f1 ff ff       	call   f010161c <page_alloc>
f0102483:	85 c0                	test   %eax,%eax
f0102485:	74 24                	je     f01024ab <mem_init+0xafe>
f0102487:	c7 44 24 0c a8 57 10 	movl   $0xf01057a8,0xc(%esp)
f010248e:	f0 
f010248f:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f0102496:	f0 
f0102497:	c7 44 24 04 18 03 00 	movl   $0x318,0x4(%esp)
f010249e:	00 
f010249f:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f01024a6:	e8 e9 db ff ff       	call   f0100094 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f01024ab:	8b 15 88 99 11 f0    	mov    0xf0119988,%edx
f01024b1:	8b 02                	mov    (%edx),%eax
f01024b3:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01024b8:	89 c1                	mov    %eax,%ecx
f01024ba:	c1 e9 0c             	shr    $0xc,%ecx
f01024bd:	3b 0d 84 99 11 f0    	cmp    0xf0119984,%ecx
f01024c3:	72 20                	jb     f01024e5 <mem_init+0xb38>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01024c5:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01024c9:	c7 44 24 08 6c 4c 10 	movl   $0xf0104c6c,0x8(%esp)
f01024d0:	f0 
f01024d1:	c7 44 24 04 1b 03 00 	movl   $0x31b,0x4(%esp)
f01024d8:	00 
f01024d9:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f01024e0:	e8 af db ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f01024e5:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01024ea:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f01024ed:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01024f4:	00 
f01024f5:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01024fc:	00 
f01024fd:	89 14 24             	mov    %edx,(%esp)
f0102500:	e8 d0 f1 ff ff       	call   f01016d5 <pgdir_walk>
f0102505:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0102508:	83 c2 04             	add    $0x4,%edx
f010250b:	39 d0                	cmp    %edx,%eax
f010250d:	74 24                	je     f0102533 <mem_init+0xb86>
f010250f:	c7 44 24 0c 00 52 10 	movl   $0xf0105200,0xc(%esp)
f0102516:	f0 
f0102517:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f010251e:	f0 
f010251f:	c7 44 24 04 1c 03 00 	movl   $0x31c,0x4(%esp)
f0102526:	00 
f0102527:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f010252e:	e8 61 db ff ff       	call   f0100094 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0102533:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f010253a:	00 
f010253b:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102542:	00 
f0102543:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102547:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f010254c:	89 04 24             	mov    %eax,(%esp)
f010254f:	e8 97 f3 ff ff       	call   f01018eb <page_insert>
f0102554:	85 c0                	test   %eax,%eax
f0102556:	74 24                	je     f010257c <mem_init+0xbcf>
f0102558:	c7 44 24 0c 40 52 10 	movl   $0xf0105240,0xc(%esp)
f010255f:	f0 
f0102560:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f0102567:	f0 
f0102568:	c7 44 24 04 1f 03 00 	movl   $0x31f,0x4(%esp)
f010256f:	00 
f0102570:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f0102577:	e8 18 db ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f010257c:	8b 0d 88 99 11 f0    	mov    0xf0119988,%ecx
f0102582:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f0102585:	ba 00 10 00 00       	mov    $0x1000,%edx
f010258a:	89 c8                	mov    %ecx,%eax
f010258c:	e8 ab eb ff ff       	call   f010113c <check_va2pa>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102591:	89 da                	mov    %ebx,%edx
f0102593:	2b 15 8c 99 11 f0    	sub    0xf011998c,%edx
f0102599:	c1 fa 03             	sar    $0x3,%edx
f010259c:	c1 e2 0c             	shl    $0xc,%edx
f010259f:	39 d0                	cmp    %edx,%eax
f01025a1:	74 24                	je     f01025c7 <mem_init+0xc1a>
f01025a3:	c7 44 24 0c d0 51 10 	movl   $0xf01051d0,0xc(%esp)
f01025aa:	f0 
f01025ab:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f01025b2:	f0 
f01025b3:	c7 44 24 04 20 03 00 	movl   $0x320,0x4(%esp)
f01025ba:	00 
f01025bb:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f01025c2:	e8 cd da ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f01025c7:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01025cc:	74 24                	je     f01025f2 <mem_init+0xc45>
f01025ce:	c7 44 24 0c 1c 58 10 	movl   $0xf010581c,0xc(%esp)
f01025d5:	f0 
f01025d6:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f01025dd:	f0 
f01025de:	c7 44 24 04 21 03 00 	movl   $0x321,0x4(%esp)
f01025e5:	00 
f01025e6:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f01025ed:	e8 a2 da ff ff       	call   f0100094 <_panic>

	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f01025f2:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01025f9:	00 
f01025fa:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102601:	00 
f0102602:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102605:	89 04 24             	mov    %eax,(%esp)
f0102608:	e8 c8 f0 ff ff       	call   f01016d5 <pgdir_walk>
f010260d:	f6 00 04             	testb  $0x4,(%eax)
f0102610:	75 24                	jne    f0102636 <mem_init+0xc89>
f0102612:	c7 44 24 0c 80 52 10 	movl   $0xf0105280,0xc(%esp)
f0102619:	f0 
f010261a:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f0102621:	f0 
f0102622:	c7 44 24 04 23 03 00 	movl   $0x323,0x4(%esp)
f0102629:	00 
f010262a:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f0102631:	e8 5e da ff ff       	call   f0100094 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f0102636:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f010263b:	f6 00 04             	testb  $0x4,(%eax)
f010263e:	75 24                	jne    f0102664 <mem_init+0xcb7>
f0102640:	c7 44 24 0c 2d 58 10 	movl   $0xf010582d,0xc(%esp)
f0102647:	f0 
f0102648:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f010264f:	f0 
f0102650:	c7 44 24 04 24 03 00 	movl   $0x324,0x4(%esp)
f0102657:	00 
f0102658:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f010265f:	e8 30 da ff ff       	call   f0100094 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0102664:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f010266b:	00 
f010266c:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102673:	00 
f0102674:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102678:	89 04 24             	mov    %eax,(%esp)
f010267b:	e8 6b f2 ff ff       	call   f01018eb <page_insert>
f0102680:	85 c0                	test   %eax,%eax
f0102682:	74 24                	je     f01026a8 <mem_init+0xcfb>
f0102684:	c7 44 24 0c 94 51 10 	movl   $0xf0105194,0xc(%esp)
f010268b:	f0 
f010268c:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f0102693:	f0 
f0102694:	c7 44 24 04 27 03 00 	movl   $0x327,0x4(%esp)
f010269b:	00 
f010269c:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f01026a3:	e8 ec d9 ff ff       	call   f0100094 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f01026a8:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01026af:	00 
f01026b0:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01026b7:	00 
f01026b8:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f01026bd:	89 04 24             	mov    %eax,(%esp)
f01026c0:	e8 10 f0 ff ff       	call   f01016d5 <pgdir_walk>
f01026c5:	f6 00 02             	testb  $0x2,(%eax)
f01026c8:	75 24                	jne    f01026ee <mem_init+0xd41>
f01026ca:	c7 44 24 0c b4 52 10 	movl   $0xf01052b4,0xc(%esp)
f01026d1:	f0 
f01026d2:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f01026d9:	f0 
f01026da:	c7 44 24 04 28 03 00 	movl   $0x328,0x4(%esp)
f01026e1:	00 
f01026e2:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f01026e9:	e8 a6 d9 ff ff       	call   f0100094 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f01026ee:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01026f5:	00 
f01026f6:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01026fd:	00 
f01026fe:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f0102703:	89 04 24             	mov    %eax,(%esp)
f0102706:	e8 ca ef ff ff       	call   f01016d5 <pgdir_walk>
f010270b:	f6 00 04             	testb  $0x4,(%eax)
f010270e:	74 24                	je     f0102734 <mem_init+0xd87>
f0102710:	c7 44 24 0c e8 52 10 	movl   $0xf01052e8,0xc(%esp)
f0102717:	f0 
f0102718:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f010271f:	f0 
f0102720:	c7 44 24 04 29 03 00 	movl   $0x329,0x4(%esp)
f0102727:	00 
f0102728:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f010272f:	e8 60 d9 ff ff       	call   f0100094 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0102734:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f010273b:	00 
f010273c:	c7 44 24 08 00 00 40 	movl   $0x400000,0x8(%esp)
f0102743:	00 
f0102744:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102748:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f010274d:	89 04 24             	mov    %eax,(%esp)
f0102750:	e8 96 f1 ff ff       	call   f01018eb <page_insert>
f0102755:	85 c0                	test   %eax,%eax
f0102757:	78 24                	js     f010277d <mem_init+0xdd0>
f0102759:	c7 44 24 0c 20 53 10 	movl   $0xf0105320,0xc(%esp)
f0102760:	f0 
f0102761:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f0102768:	f0 
f0102769:	c7 44 24 04 2c 03 00 	movl   $0x32c,0x4(%esp)
f0102770:	00 
f0102771:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f0102778:	e8 17 d9 ff ff       	call   f0100094 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
//	cprintf("~~w");
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f010277d:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102784:	00 
f0102785:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010278c:	00 
f010278d:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0102791:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f0102796:	89 04 24             	mov    %eax,(%esp)
f0102799:	e8 4d f1 ff ff       	call   f01018eb <page_insert>
f010279e:	85 c0                	test   %eax,%eax
f01027a0:	74 24                	je     f01027c6 <mem_init+0xe19>
f01027a2:	c7 44 24 0c 58 53 10 	movl   $0xf0105358,0xc(%esp)
f01027a9:	f0 
f01027aa:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f01027b1:	f0 
f01027b2:	c7 44 24 04 30 03 00 	movl   $0x330,0x4(%esp)
f01027b9:	00 
f01027ba:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f01027c1:	e8 ce d8 ff ff       	call   f0100094 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f01027c6:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01027cd:	00 
f01027ce:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01027d5:	00 
f01027d6:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f01027db:	89 04 24             	mov    %eax,(%esp)
f01027de:	e8 f2 ee ff ff       	call   f01016d5 <pgdir_walk>
f01027e3:	f6 00 04             	testb  $0x4,(%eax)
f01027e6:	74 24                	je     f010280c <mem_init+0xe5f>
f01027e8:	c7 44 24 0c e8 52 10 	movl   $0xf01052e8,0xc(%esp)
f01027ef:	f0 
f01027f0:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f01027f7:	f0 
f01027f8:	c7 44 24 04 31 03 00 	movl   $0x331,0x4(%esp)
f01027ff:	00 
f0102800:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f0102807:	e8 88 d8 ff ff       	call   f0100094 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f010280c:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f0102811:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102814:	ba 00 00 00 00       	mov    $0x0,%edx
f0102819:	e8 1e e9 ff ff       	call   f010113c <check_va2pa>
f010281e:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102821:	89 f8                	mov    %edi,%eax
f0102823:	2b 05 8c 99 11 f0    	sub    0xf011998c,%eax
f0102829:	c1 f8 03             	sar    $0x3,%eax
f010282c:	c1 e0 0c             	shl    $0xc,%eax
f010282f:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0102832:	74 24                	je     f0102858 <mem_init+0xeab>
f0102834:	c7 44 24 0c 94 53 10 	movl   $0xf0105394,0xc(%esp)
f010283b:	f0 
f010283c:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f0102843:	f0 
f0102844:	c7 44 24 04 34 03 00 	movl   $0x334,0x4(%esp)
f010284b:	00 
f010284c:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f0102853:	e8 3c d8 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0102858:	ba 00 10 00 00       	mov    $0x1000,%edx
f010285d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102860:	e8 d7 e8 ff ff       	call   f010113c <check_va2pa>
f0102865:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0102868:	74 24                	je     f010288e <mem_init+0xee1>
f010286a:	c7 44 24 0c c0 53 10 	movl   $0xf01053c0,0xc(%esp)
f0102871:	f0 
f0102872:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f0102879:	f0 
f010287a:	c7 44 24 04 35 03 00 	movl   $0x335,0x4(%esp)
f0102881:	00 
f0102882:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f0102889:	e8 06 d8 ff ff       	call   f0100094 <_panic>
	// ... and ref counts should reflect this
//	cprintf("%d %d", pp1->pp_ref, pp2->pp_ref);
	assert(pp1->pp_ref == 2);
f010288e:	66 83 7f 04 02       	cmpw   $0x2,0x4(%edi)
f0102893:	74 24                	je     f01028b9 <mem_init+0xf0c>
f0102895:	c7 44 24 0c 43 58 10 	movl   $0xf0105843,0xc(%esp)
f010289c:	f0 
f010289d:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f01028a4:	f0 
f01028a5:	c7 44 24 04 38 03 00 	movl   $0x338,0x4(%esp)
f01028ac:	00 
f01028ad:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f01028b4:	e8 db d7 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f01028b9:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f01028be:	74 24                	je     f01028e4 <mem_init+0xf37>
f01028c0:	c7 44 24 0c 54 58 10 	movl   $0xf0105854,0xc(%esp)
f01028c7:	f0 
f01028c8:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f01028cf:	f0 
f01028d0:	c7 44 24 04 39 03 00 	movl   $0x339,0x4(%esp)
f01028d7:	00 
f01028d8:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f01028df:	e8 b0 d7 ff ff       	call   f0100094 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f01028e4:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01028eb:	e8 2c ed ff ff       	call   f010161c <page_alloc>
f01028f0:	85 c0                	test   %eax,%eax
f01028f2:	74 04                	je     f01028f8 <mem_init+0xf4b>
f01028f4:	39 c3                	cmp    %eax,%ebx
f01028f6:	74 24                	je     f010291c <mem_init+0xf6f>
f01028f8:	c7 44 24 0c f0 53 10 	movl   $0xf01053f0,0xc(%esp)
f01028ff:	f0 
f0102900:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f0102907:	f0 
f0102908:	c7 44 24 04 3c 03 00 	movl   $0x33c,0x4(%esp)
f010290f:	00 
f0102910:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f0102917:	e8 78 d7 ff ff       	call   f0100094 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f010291c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102923:	00 
f0102924:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f0102929:	89 04 24             	mov    %eax,(%esp)
f010292c:	e8 7c ef ff ff       	call   f01018ad <page_remove>
//	cprintf("~~~");
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102931:	8b 15 88 99 11 f0    	mov    0xf0119988,%edx
f0102937:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f010293a:	ba 00 00 00 00       	mov    $0x0,%edx
f010293f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102942:	e8 f5 e7 ff ff       	call   f010113c <check_va2pa>
f0102947:	83 f8 ff             	cmp    $0xffffffff,%eax
f010294a:	74 24                	je     f0102970 <mem_init+0xfc3>
f010294c:	c7 44 24 0c 14 54 10 	movl   $0xf0105414,0xc(%esp)
f0102953:	f0 
f0102954:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f010295b:	f0 
f010295c:	c7 44 24 04 41 03 00 	movl   $0x341,0x4(%esp)
f0102963:	00 
f0102964:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f010296b:	e8 24 d7 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0102970:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102975:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102978:	e8 bf e7 ff ff       	call   f010113c <check_va2pa>
f010297d:	89 fa                	mov    %edi,%edx
f010297f:	2b 15 8c 99 11 f0    	sub    0xf011998c,%edx
f0102985:	c1 fa 03             	sar    $0x3,%edx
f0102988:	c1 e2 0c             	shl    $0xc,%edx
f010298b:	39 d0                	cmp    %edx,%eax
f010298d:	74 24                	je     f01029b3 <mem_init+0x1006>
f010298f:	c7 44 24 0c c0 53 10 	movl   $0xf01053c0,0xc(%esp)
f0102996:	f0 
f0102997:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f010299e:	f0 
f010299f:	c7 44 24 04 42 03 00 	movl   $0x342,0x4(%esp)
f01029a6:	00 
f01029a7:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f01029ae:	e8 e1 d6 ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 1);
f01029b3:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f01029b8:	74 24                	je     f01029de <mem_init+0x1031>
f01029ba:	c7 44 24 0c fa 57 10 	movl   $0xf01057fa,0xc(%esp)
f01029c1:	f0 
f01029c2:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f01029c9:	f0 
f01029ca:	c7 44 24 04 43 03 00 	movl   $0x343,0x4(%esp)
f01029d1:	00 
f01029d2:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f01029d9:	e8 b6 d6 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f01029de:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f01029e3:	74 24                	je     f0102a09 <mem_init+0x105c>
f01029e5:	c7 44 24 0c 54 58 10 	movl   $0xf0105854,0xc(%esp)
f01029ec:	f0 
f01029ed:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f01029f4:	f0 
f01029f5:	c7 44 24 04 44 03 00 	movl   $0x344,0x4(%esp)
f01029fc:	00 
f01029fd:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f0102a04:	e8 8b d6 ff ff       	call   f0100094 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102a09:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102a10:	00 
f0102a11:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0102a14:	89 0c 24             	mov    %ecx,(%esp)
f0102a17:	e8 91 ee ff ff       	call   f01018ad <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102a1c:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f0102a21:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102a24:	ba 00 00 00 00       	mov    $0x0,%edx
f0102a29:	e8 0e e7 ff ff       	call   f010113c <check_va2pa>
f0102a2e:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102a31:	74 24                	je     f0102a57 <mem_init+0x10aa>
f0102a33:	c7 44 24 0c 14 54 10 	movl   $0xf0105414,0xc(%esp)
f0102a3a:	f0 
f0102a3b:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f0102a42:	f0 
f0102a43:	c7 44 24 04 48 03 00 	movl   $0x348,0x4(%esp)
f0102a4a:	00 
f0102a4b:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f0102a52:	e8 3d d6 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0102a57:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102a5c:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102a5f:	e8 d8 e6 ff ff       	call   f010113c <check_va2pa>
f0102a64:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102a67:	74 24                	je     f0102a8d <mem_init+0x10e0>
f0102a69:	c7 44 24 0c 38 54 10 	movl   $0xf0105438,0xc(%esp)
f0102a70:	f0 
f0102a71:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f0102a78:	f0 
f0102a79:	c7 44 24 04 49 03 00 	movl   $0x349,0x4(%esp)
f0102a80:	00 
f0102a81:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f0102a88:	e8 07 d6 ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 0);
f0102a8d:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102a92:	74 24                	je     f0102ab8 <mem_init+0x110b>
f0102a94:	c7 44 24 0c 65 58 10 	movl   $0xf0105865,0xc(%esp)
f0102a9b:	f0 
f0102a9c:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f0102aa3:	f0 
f0102aa4:	c7 44 24 04 4a 03 00 	movl   $0x34a,0x4(%esp)
f0102aab:	00 
f0102aac:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f0102ab3:	e8 dc d5 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f0102ab8:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102abd:	74 24                	je     f0102ae3 <mem_init+0x1136>
f0102abf:	c7 44 24 0c 54 58 10 	movl   $0xf0105854,0xc(%esp)
f0102ac6:	f0 
f0102ac7:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f0102ace:	f0 
f0102acf:	c7 44 24 04 4b 03 00 	movl   $0x34b,0x4(%esp)
f0102ad6:	00 
f0102ad7:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f0102ade:	e8 b1 d5 ff ff       	call   f0100094 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0102ae3:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102aea:	e8 2d eb ff ff       	call   f010161c <page_alloc>
f0102aef:	85 c0                	test   %eax,%eax
f0102af1:	74 04                	je     f0102af7 <mem_init+0x114a>
f0102af3:	39 c7                	cmp    %eax,%edi
f0102af5:	74 24                	je     f0102b1b <mem_init+0x116e>
f0102af7:	c7 44 24 0c 60 54 10 	movl   $0xf0105460,0xc(%esp)
f0102afe:	f0 
f0102aff:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f0102b06:	f0 
f0102b07:	c7 44 24 04 4e 03 00 	movl   $0x34e,0x4(%esp)
f0102b0e:	00 
f0102b0f:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f0102b16:	e8 79 d5 ff ff       	call   f0100094 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0102b1b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102b22:	e8 f5 ea ff ff       	call   f010161c <page_alloc>
f0102b27:	85 c0                	test   %eax,%eax
f0102b29:	74 24                	je     f0102b4f <mem_init+0x11a2>
f0102b2b:	c7 44 24 0c a8 57 10 	movl   $0xf01057a8,0xc(%esp)
f0102b32:	f0 
f0102b33:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f0102b3a:	f0 
f0102b3b:	c7 44 24 04 51 03 00 	movl   $0x351,0x4(%esp)
f0102b42:	00 
f0102b43:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f0102b4a:	e8 45 d5 ff ff       	call   f0100094 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102b4f:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f0102b54:	8b 08                	mov    (%eax),%ecx
f0102b56:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0102b5c:	89 f2                	mov    %esi,%edx
f0102b5e:	2b 15 8c 99 11 f0    	sub    0xf011998c,%edx
f0102b64:	c1 fa 03             	sar    $0x3,%edx
f0102b67:	c1 e2 0c             	shl    $0xc,%edx
f0102b6a:	39 d1                	cmp    %edx,%ecx
f0102b6c:	74 24                	je     f0102b92 <mem_init+0x11e5>
f0102b6e:	c7 44 24 0c 3c 51 10 	movl   $0xf010513c,0xc(%esp)
f0102b75:	f0 
f0102b76:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f0102b7d:	f0 
f0102b7e:	c7 44 24 04 54 03 00 	movl   $0x354,0x4(%esp)
f0102b85:	00 
f0102b86:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f0102b8d:	e8 02 d5 ff ff       	call   f0100094 <_panic>
	kern_pgdir[0] = 0;
f0102b92:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f0102b98:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102b9d:	74 24                	je     f0102bc3 <mem_init+0x1216>
f0102b9f:	c7 44 24 0c 0b 58 10 	movl   $0xf010580b,0xc(%esp)
f0102ba6:	f0 
f0102ba7:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f0102bae:	f0 
f0102baf:	c7 44 24 04 56 03 00 	movl   $0x356,0x4(%esp)
f0102bb6:	00 
f0102bb7:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f0102bbe:	e8 d1 d4 ff ff       	call   f0100094 <_panic>
	pp0->pp_ref = 0;
f0102bc3:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0102bc9:	89 34 24             	mov    %esi,(%esp)
f0102bcc:	e8 cc ea ff ff       	call   f010169d <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0102bd1:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0102bd8:	00 
f0102bd9:	c7 44 24 04 00 10 40 	movl   $0x401000,0x4(%esp)
f0102be0:	00 
f0102be1:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f0102be6:	89 04 24             	mov    %eax,(%esp)
f0102be9:	e8 e7 ea ff ff       	call   f01016d5 <pgdir_walk>
f0102bee:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0102bf1:	8b 0d 88 99 11 f0    	mov    0xf0119988,%ecx
f0102bf7:	8b 51 04             	mov    0x4(%ecx),%edx
f0102bfa:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102c00:	89 55 d4             	mov    %edx,-0x2c(%ebp)
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102c03:	8b 15 84 99 11 f0    	mov    0xf0119984,%edx
f0102c09:	89 55 c8             	mov    %edx,-0x38(%ebp)
f0102c0c:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0102c0f:	c1 ea 0c             	shr    $0xc,%edx
f0102c12:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0102c15:	8b 55 c8             	mov    -0x38(%ebp),%edx
f0102c18:	39 55 d0             	cmp    %edx,-0x30(%ebp)
f0102c1b:	72 23                	jb     f0102c40 <mem_init+0x1293>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102c1d:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0102c20:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0102c24:	c7 44 24 08 6c 4c 10 	movl   $0xf0104c6c,0x8(%esp)
f0102c2b:	f0 
f0102c2c:	c7 44 24 04 5d 03 00 	movl   $0x35d,0x4(%esp)
f0102c33:	00 
f0102c34:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f0102c3b:	e8 54 d4 ff ff       	call   f0100094 <_panic>
	assert(ptep == ptep1 + PTX(va));
f0102c40:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0102c43:	81 ea fc ff ff 0f    	sub    $0xffffffc,%edx
f0102c49:	39 d0                	cmp    %edx,%eax
f0102c4b:	74 24                	je     f0102c71 <mem_init+0x12c4>
f0102c4d:	c7 44 24 0c 76 58 10 	movl   $0xf0105876,0xc(%esp)
f0102c54:	f0 
f0102c55:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f0102c5c:	f0 
f0102c5d:	c7 44 24 04 5e 03 00 	movl   $0x35e,0x4(%esp)
f0102c64:	00 
f0102c65:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f0102c6c:	e8 23 d4 ff ff       	call   f0100094 <_panic>
	kern_pgdir[PDX(va)] = 0;
f0102c71:	c7 41 04 00 00 00 00 	movl   $0x0,0x4(%ecx)
	pp0->pp_ref = 0;
f0102c78:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102c7e:	89 f0                	mov    %esi,%eax
f0102c80:	2b 05 8c 99 11 f0    	sub    0xf011998c,%eax
f0102c86:	c1 f8 03             	sar    $0x3,%eax
f0102c89:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102c8c:	89 c1                	mov    %eax,%ecx
f0102c8e:	c1 e9 0c             	shr    $0xc,%ecx
f0102c91:	39 4d c8             	cmp    %ecx,-0x38(%ebp)
f0102c94:	77 20                	ja     f0102cb6 <mem_init+0x1309>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102c96:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102c9a:	c7 44 24 08 6c 4c 10 	movl   $0xf0104c6c,0x8(%esp)
f0102ca1:	f0 
f0102ca2:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0102ca9:	00 
f0102caa:	c7 04 24 24 56 10 f0 	movl   $0xf0105624,(%esp)
f0102cb1:	e8 de d3 ff ff       	call   f0100094 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0102cb6:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102cbd:	00 
f0102cbe:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
f0102cc5:	00 
	return (void *)(pa + KERNBASE);
f0102cc6:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102ccb:	89 04 24             	mov    %eax,(%esp)
f0102cce:	e8 7e 14 00 00       	call   f0104151 <memset>
	page_free(pp0);
f0102cd3:	89 34 24             	mov    %esi,(%esp)
f0102cd6:	e8 c2 e9 ff ff       	call   f010169d <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0102cdb:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0102ce2:	00 
f0102ce3:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102cea:	00 
f0102ceb:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f0102cf0:	89 04 24             	mov    %eax,(%esp)
f0102cf3:	e8 dd e9 ff ff       	call   f01016d5 <pgdir_walk>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102cf8:	89 f2                	mov    %esi,%edx
f0102cfa:	2b 15 8c 99 11 f0    	sub    0xf011998c,%edx
f0102d00:	c1 fa 03             	sar    $0x3,%edx
f0102d03:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102d06:	89 d0                	mov    %edx,%eax
f0102d08:	c1 e8 0c             	shr    $0xc,%eax
f0102d0b:	3b 05 84 99 11 f0    	cmp    0xf0119984,%eax
f0102d11:	72 20                	jb     f0102d33 <mem_init+0x1386>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102d13:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0102d17:	c7 44 24 08 6c 4c 10 	movl   $0xf0104c6c,0x8(%esp)
f0102d1e:	f0 
f0102d1f:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0102d26:	00 
f0102d27:	c7 04 24 24 56 10 f0 	movl   $0xf0105624,(%esp)
f0102d2e:	e8 61 d3 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0102d33:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f0102d39:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102d3c:	f6 82 00 00 00 f0 01 	testb  $0x1,-0x10000000(%edx)
f0102d43:	75 11                	jne    f0102d56 <mem_init+0x13a9>
f0102d45:	8d 82 04 00 00 f0    	lea    -0xffffffc(%edx),%eax
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0102d4b:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102d51:	f6 00 01             	testb  $0x1,(%eax)
f0102d54:	74 24                	je     f0102d7a <mem_init+0x13cd>
f0102d56:	c7 44 24 0c 8e 58 10 	movl   $0xf010588e,0xc(%esp)
f0102d5d:	f0 
f0102d5e:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f0102d65:	f0 
f0102d66:	c7 44 24 04 68 03 00 	movl   $0x368,0x4(%esp)
f0102d6d:	00 
f0102d6e:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f0102d75:	e8 1a d3 ff ff       	call   f0100094 <_panic>
f0102d7a:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f0102d7d:	39 d0                	cmp    %edx,%eax
f0102d7f:	75 d0                	jne    f0102d51 <mem_init+0x13a4>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f0102d81:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f0102d86:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102d8c:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// give free list back
	page_free_list = fl;
f0102d92:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0102d95:	89 0d 60 95 11 f0    	mov    %ecx,0xf0119560

	// free the pages we took
	page_free(pp0);
f0102d9b:	89 34 24             	mov    %esi,(%esp)
f0102d9e:	e8 fa e8 ff ff       	call   f010169d <page_free>
	page_free(pp1);
f0102da3:	89 3c 24             	mov    %edi,(%esp)
f0102da6:	e8 f2 e8 ff ff       	call   f010169d <page_free>
	page_free(pp2);
f0102dab:	89 1c 24             	mov    %ebx,(%esp)
f0102dae:	e8 ea e8 ff ff       	call   f010169d <page_free>

	cprintf("check_page() succeeded!\n");
f0102db3:	c7 04 24 a5 58 10 f0 	movl   $0xf01058a5,(%esp)
f0102dba:	e8 cf 07 00 00       	call   f010358e <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, UPAGES, ROUNDUP(npages * sizeof(struct PageInfo), PGSIZE), PADDR(pages), PTE_U | PTE_P);
f0102dbf:	a1 8c 99 11 f0       	mov    0xf011998c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102dc4:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102dc9:	77 20                	ja     f0102deb <mem_init+0x143e>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102dcb:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102dcf:	c7 44 24 08 e4 4f 10 	movl   $0xf0104fe4,0x8(%esp)
f0102dd6:	f0 
f0102dd7:	c7 44 24 04 b2 00 00 	movl   $0xb2,0x4(%esp)
f0102dde:	00 
f0102ddf:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f0102de6:	e8 a9 d2 ff ff       	call   f0100094 <_panic>
f0102deb:	8b 15 84 99 11 f0    	mov    0xf0119984,%edx
f0102df1:	8d 0c d5 ff 0f 00 00 	lea    0xfff(,%edx,8),%ecx
f0102df8:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0102dfe:	c7 44 24 04 05 00 00 	movl   $0x5,0x4(%esp)
f0102e05:	00 
	return (physaddr_t)kva - KERNBASE;
f0102e06:	05 00 00 00 10       	add    $0x10000000,%eax
f0102e0b:	89 04 24             	mov    %eax,(%esp)
f0102e0e:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102e13:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f0102e18:	e8 a7 e9 ff ff       	call   f01017c4 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102e1d:	be 00 f0 10 f0       	mov    $0xf010f000,%esi
f0102e22:	81 fe ff ff ff ef    	cmp    $0xefffffff,%esi
f0102e28:	77 20                	ja     f0102e4a <mem_init+0x149d>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102e2a:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0102e2e:	c7 44 24 08 e4 4f 10 	movl   $0xf0104fe4,0x8(%esp)
f0102e35:	f0 
f0102e36:	c7 44 24 04 bf 00 00 	movl   $0xbf,0x4(%esp)
f0102e3d:	00 
f0102e3e:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f0102e45:	e8 4a d2 ff ff       	call   f0100094 <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KSTACKTOP - KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W);
f0102e4a:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f0102e51:	00 
f0102e52:	c7 04 24 00 f0 10 00 	movl   $0x10f000,(%esp)
f0102e59:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102e5e:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f0102e63:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f0102e68:	e8 57 e9 ff ff       	call   f01017c4 <boot_map_region>
	//      the PA range [0, 2^32 - KERNBASE)
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KERNBASE, /*(1 << 32)*/ - KERNBASE, 0, PTE_W); 
f0102e6d:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f0102e74:	00 
f0102e75:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102e7c:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f0102e81:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0102e86:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f0102e8b:	e8 34 e9 ff ff       	call   f01017c4 <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f0102e90:	8b 1d 88 99 11 f0    	mov    0xf0119988,%ebx

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0102e96:	8b 35 84 99 11 f0    	mov    0xf0119984,%esi
f0102e9c:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f0102e9f:	8d 3c f5 ff 0f 00 00 	lea    0xfff(,%esi,8),%edi
	for (i = 0; i < n; i += PGSIZE) {
f0102ea6:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
f0102eac:	74 79                	je     f0102f27 <mem_init+0x157a>
f0102eae:	be 00 00 00 00       	mov    $0x0,%esi
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0102eb3:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx
	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE) {
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102eb9:	89 d8                	mov    %ebx,%eax
f0102ebb:	e8 7c e2 ff ff       	call   f010113c <check_va2pa>
f0102ec0:	8b 15 8c 99 11 f0    	mov    0xf011998c,%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102ec6:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0102ecc:	77 20                	ja     f0102eee <mem_init+0x1541>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102ece:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0102ed2:	c7 44 24 08 e4 4f 10 	movl   $0xf0104fe4,0x8(%esp)
f0102ed9:	f0 
f0102eda:	c7 44 24 04 a8 02 00 	movl   $0x2a8,0x4(%esp)
f0102ee1:	00 
f0102ee2:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f0102ee9:	e8 a6 d1 ff ff       	call   f0100094 <_panic>
f0102eee:	8d 94 32 00 00 00 10 	lea    0x10000000(%edx,%esi,1),%edx
f0102ef5:	39 d0                	cmp    %edx,%eax
f0102ef7:	74 24                	je     f0102f1d <mem_init+0x1570>
f0102ef9:	c7 44 24 0c 84 54 10 	movl   $0xf0105484,0xc(%esp)
f0102f00:	f0 
f0102f01:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f0102f08:	f0 
f0102f09:	c7 44 24 04 a8 02 00 	movl   $0x2a8,0x4(%esp)
f0102f10:	00 
f0102f11:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f0102f18:	e8 77 d1 ff ff       	call   f0100094 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE) {
f0102f1d:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102f23:	39 f7                	cmp    %esi,%edi
f0102f25:	77 8c                	ja     f0102eb3 <mem_init+0x1506>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
	}


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102f27:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102f2a:	c1 e7 0c             	shl    $0xc,%edi
f0102f2d:	85 ff                	test   %edi,%edi
f0102f2f:	74 44                	je     f0102f75 <mem_init+0x15c8>
f0102f31:	be 00 00 00 00       	mov    $0x0,%esi
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0102f36:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
	}


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102f3c:	89 d8                	mov    %ebx,%eax
f0102f3e:	e8 f9 e1 ff ff       	call   f010113c <check_va2pa>
f0102f43:	39 c6                	cmp    %eax,%esi
f0102f45:	74 24                	je     f0102f6b <mem_init+0x15be>
f0102f47:	c7 44 24 0c b8 54 10 	movl   $0xf01054b8,0xc(%esp)
f0102f4e:	f0 
f0102f4f:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f0102f56:	f0 
f0102f57:	c7 44 24 04 ae 02 00 	movl   $0x2ae,0x4(%esp)
f0102f5e:	00 
f0102f5f:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f0102f66:	e8 29 d1 ff ff       	call   f0100094 <_panic>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
	}


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102f6b:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102f71:	39 fe                	cmp    %edi,%esi
f0102f73:	72 c1                	jb     f0102f36 <mem_init+0x1589>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102f75:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f0102f7a:	89 d8                	mov    %ebx,%eax
f0102f7c:	e8 bb e1 ff ff       	call   f010113c <check_va2pa>
f0102f81:	be 00 90 ff ef       	mov    $0xefff9000,%esi
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0102f86:	bf 00 f0 10 f0       	mov    $0xf010f000,%edi
f0102f8b:	81 c7 00 70 00 20    	add    $0x20007000,%edi
f0102f91:	8d 14 37             	lea    (%edi,%esi,1),%edx
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102f94:	39 c2                	cmp    %eax,%edx
f0102f96:	74 24                	je     f0102fbc <mem_init+0x160f>
f0102f98:	c7 44 24 0c e0 54 10 	movl   $0xf01054e0,0xc(%esp)
f0102f9f:	f0 
f0102fa0:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f0102fa7:	f0 
f0102fa8:	c7 44 24 04 b2 02 00 	movl   $0x2b2,0x4(%esp)
f0102faf:	00 
f0102fb0:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f0102fb7:	e8 d8 d0 ff ff       	call   f0100094 <_panic>
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0102fbc:	81 fe 00 00 00 f0    	cmp    $0xf0000000,%esi
f0102fc2:	0f 85 37 05 00 00    	jne    f01034ff <mem_init+0x1b52>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102fc8:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f0102fcd:	89 d8                	mov    %ebx,%eax
f0102fcf:	e8 68 e1 ff ff       	call   f010113c <check_va2pa>
f0102fd4:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102fd7:	74 24                	je     f0102ffd <mem_init+0x1650>
f0102fd9:	c7 44 24 0c 28 55 10 	movl   $0xf0105528,0xc(%esp)
f0102fe0:	f0 
f0102fe1:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f0102fe8:	f0 
f0102fe9:	c7 44 24 04 b3 02 00 	movl   $0x2b3,0x4(%esp)
f0102ff0:	00 
f0102ff1:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f0102ff8:	e8 97 d0 ff ff       	call   f0100094 <_panic>
f0102ffd:	b8 00 00 00 00       	mov    $0x0,%eax

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f0103002:	ba 01 00 00 00       	mov    $0x1,%edx
f0103007:	8d 88 44 fc ff ff    	lea    -0x3bc(%eax),%ecx
f010300d:	83 f9 03             	cmp    $0x3,%ecx
f0103010:	77 39                	ja     f010304b <mem_init+0x169e>
f0103012:	89 d6                	mov    %edx,%esi
f0103014:	d3 e6                	shl    %cl,%esi
f0103016:	89 f1                	mov    %esi,%ecx
f0103018:	f6 c1 0b             	test   $0xb,%cl
f010301b:	74 2e                	je     f010304b <mem_init+0x169e>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
f010301d:	f6 04 83 01          	testb  $0x1,(%ebx,%eax,4)
f0103021:	0f 85 aa 00 00 00    	jne    f01030d1 <mem_init+0x1724>
f0103027:	c7 44 24 0c be 58 10 	movl   $0xf01058be,0xc(%esp)
f010302e:	f0 
f010302f:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f0103036:	f0 
f0103037:	c7 44 24 04 bb 02 00 	movl   $0x2bb,0x4(%esp)
f010303e:	00 
f010303f:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f0103046:	e8 49 d0 ff ff       	call   f0100094 <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f010304b:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0103050:	76 55                	jbe    f01030a7 <mem_init+0x16fa>
				assert(pgdir[i] & PTE_P);
f0103052:	8b 0c 83             	mov    (%ebx,%eax,4),%ecx
f0103055:	f6 c1 01             	test   $0x1,%cl
f0103058:	75 24                	jne    f010307e <mem_init+0x16d1>
f010305a:	c7 44 24 0c be 58 10 	movl   $0xf01058be,0xc(%esp)
f0103061:	f0 
f0103062:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f0103069:	f0 
f010306a:	c7 44 24 04 bf 02 00 	movl   $0x2bf,0x4(%esp)
f0103071:	00 
f0103072:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f0103079:	e8 16 d0 ff ff       	call   f0100094 <_panic>
				assert(pgdir[i] & PTE_W);
f010307e:	f6 c1 02             	test   $0x2,%cl
f0103081:	75 4e                	jne    f01030d1 <mem_init+0x1724>
f0103083:	c7 44 24 0c cf 58 10 	movl   $0xf01058cf,0xc(%esp)
f010308a:	f0 
f010308b:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f0103092:	f0 
f0103093:	c7 44 24 04 c0 02 00 	movl   $0x2c0,0x4(%esp)
f010309a:	00 
f010309b:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f01030a2:	e8 ed cf ff ff       	call   f0100094 <_panic>
			} else
				assert(pgdir[i] == 0);
f01030a7:	83 3c 83 00          	cmpl   $0x0,(%ebx,%eax,4)
f01030ab:	74 24                	je     f01030d1 <mem_init+0x1724>
f01030ad:	c7 44 24 0c e0 58 10 	movl   $0xf01058e0,0xc(%esp)
f01030b4:	f0 
f01030b5:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f01030bc:	f0 
f01030bd:	c7 44 24 04 c2 02 00 	movl   $0x2c2,0x4(%esp)
f01030c4:	00 
f01030c5:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f01030cc:	e8 c3 cf ff ff       	call   f0100094 <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f01030d1:	83 c0 01             	add    $0x1,%eax
f01030d4:	3d 00 04 00 00       	cmp    $0x400,%eax
f01030d9:	0f 85 28 ff ff ff    	jne    f0103007 <mem_init+0x165a>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f01030df:	c7 04 24 58 55 10 f0 	movl   $0xf0105558,(%esp)
f01030e6:	e8 a3 04 00 00       	call   f010358e <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f01030eb:	a1 88 99 11 f0       	mov    0xf0119988,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01030f0:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01030f5:	77 20                	ja     f0103117 <mem_init+0x176a>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01030f7:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01030fb:	c7 44 24 08 e4 4f 10 	movl   $0xf0104fe4,0x8(%esp)
f0103102:	f0 
f0103103:	c7 44 24 04 d4 00 00 	movl   $0xd4,0x4(%esp)
f010310a:	00 
f010310b:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f0103112:	e8 7d cf ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0103117:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f010311c:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f010311f:	b8 00 00 00 00       	mov    $0x0,%eax
f0103124:	e8 b6 e0 ff ff       	call   f01011df <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f0103129:	0f 20 c0             	mov    %cr0,%eax

	// entry.S set the really important flags in cr0 (including enabling
	// paging).  Here we configure the rest of the flags that we care about.
	cr0 = rcr0();
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_MP;
f010312c:	0d 23 00 05 80       	or     $0x80050023,%eax
	cr0 &= ~(CR0_TS|CR0_EM);
f0103131:	83 e0 f3             	and    $0xfffffff3,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f0103134:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0103137:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010313e:	e8 d9 e4 ff ff       	call   f010161c <page_alloc>
f0103143:	89 c6                	mov    %eax,%esi
f0103145:	85 c0                	test   %eax,%eax
f0103147:	75 24                	jne    f010316d <mem_init+0x17c0>
f0103149:	c7 44 24 0c fd 56 10 	movl   $0xf01056fd,0xc(%esp)
f0103150:	f0 
f0103151:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f0103158:	f0 
f0103159:	c7 44 24 04 83 03 00 	movl   $0x383,0x4(%esp)
f0103160:	00 
f0103161:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f0103168:	e8 27 cf ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f010316d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0103174:	e8 a3 e4 ff ff       	call   f010161c <page_alloc>
f0103179:	89 c7                	mov    %eax,%edi
f010317b:	85 c0                	test   %eax,%eax
f010317d:	75 24                	jne    f01031a3 <mem_init+0x17f6>
f010317f:	c7 44 24 0c 13 57 10 	movl   $0xf0105713,0xc(%esp)
f0103186:	f0 
f0103187:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f010318e:	f0 
f010318f:	c7 44 24 04 84 03 00 	movl   $0x384,0x4(%esp)
f0103196:	00 
f0103197:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f010319e:	e8 f1 ce ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f01031a3:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01031aa:	e8 6d e4 ff ff       	call   f010161c <page_alloc>
f01031af:	89 c3                	mov    %eax,%ebx
f01031b1:	85 c0                	test   %eax,%eax
f01031b3:	75 24                	jne    f01031d9 <mem_init+0x182c>
f01031b5:	c7 44 24 0c 29 57 10 	movl   $0xf0105729,0xc(%esp)
f01031bc:	f0 
f01031bd:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f01031c4:	f0 
f01031c5:	c7 44 24 04 85 03 00 	movl   $0x385,0x4(%esp)
f01031cc:	00 
f01031cd:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f01031d4:	e8 bb ce ff ff       	call   f0100094 <_panic>
	page_free(pp0);
f01031d9:	89 34 24             	mov    %esi,(%esp)
f01031dc:	e8 bc e4 ff ff       	call   f010169d <page_free>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01031e1:	89 f8                	mov    %edi,%eax
f01031e3:	2b 05 8c 99 11 f0    	sub    0xf011998c,%eax
f01031e9:	c1 f8 03             	sar    $0x3,%eax
f01031ec:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01031ef:	89 c2                	mov    %eax,%edx
f01031f1:	c1 ea 0c             	shr    $0xc,%edx
f01031f4:	3b 15 84 99 11 f0    	cmp    0xf0119984,%edx
f01031fa:	72 20                	jb     f010321c <mem_init+0x186f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01031fc:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103200:	c7 44 24 08 6c 4c 10 	movl   $0xf0104c6c,0x8(%esp)
f0103207:	f0 
f0103208:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f010320f:	00 
f0103210:	c7 04 24 24 56 10 f0 	movl   $0xf0105624,(%esp)
f0103217:	e8 78 ce ff ff       	call   f0100094 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f010321c:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0103223:	00 
f0103224:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f010322b:	00 
	return (void *)(pa + KERNBASE);
f010322c:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0103231:	89 04 24             	mov    %eax,(%esp)
f0103234:	e8 18 0f 00 00       	call   f0104151 <memset>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0103239:	89 d8                	mov    %ebx,%eax
f010323b:	2b 05 8c 99 11 f0    	sub    0xf011998c,%eax
f0103241:	c1 f8 03             	sar    $0x3,%eax
f0103244:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0103247:	89 c2                	mov    %eax,%edx
f0103249:	c1 ea 0c             	shr    $0xc,%edx
f010324c:	3b 15 84 99 11 f0    	cmp    0xf0119984,%edx
f0103252:	72 20                	jb     f0103274 <mem_init+0x18c7>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0103254:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103258:	c7 44 24 08 6c 4c 10 	movl   $0xf0104c6c,0x8(%esp)
f010325f:	f0 
f0103260:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0103267:	00 
f0103268:	c7 04 24 24 56 10 f0 	movl   $0xf0105624,(%esp)
f010326f:	e8 20 ce ff ff       	call   f0100094 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f0103274:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010327b:	00 
f010327c:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f0103283:	00 
	return (void *)(pa + KERNBASE);
f0103284:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0103289:	89 04 24             	mov    %eax,(%esp)
f010328c:	e8 c0 0e 00 00       	call   f0104151 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0103291:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0103298:	00 
f0103299:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01032a0:	00 
f01032a1:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01032a5:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f01032aa:	89 04 24             	mov    %eax,(%esp)
f01032ad:	e8 39 e6 ff ff       	call   f01018eb <page_insert>
	assert(pp1->pp_ref == 1);
f01032b2:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f01032b7:	74 24                	je     f01032dd <mem_init+0x1930>
f01032b9:	c7 44 24 0c fa 57 10 	movl   $0xf01057fa,0xc(%esp)
f01032c0:	f0 
f01032c1:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f01032c8:	f0 
f01032c9:	c7 44 24 04 8a 03 00 	movl   $0x38a,0x4(%esp)
f01032d0:	00 
f01032d1:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f01032d8:	e8 b7 cd ff ff       	call   f0100094 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f01032dd:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f01032e4:	01 01 01 
f01032e7:	74 24                	je     f010330d <mem_init+0x1960>
f01032e9:	c7 44 24 0c 78 55 10 	movl   $0xf0105578,0xc(%esp)
f01032f0:	f0 
f01032f1:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f01032f8:	f0 
f01032f9:	c7 44 24 04 8b 03 00 	movl   $0x38b,0x4(%esp)
f0103300:	00 
f0103301:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f0103308:	e8 87 cd ff ff       	call   f0100094 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f010330d:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0103314:	00 
f0103315:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010331c:	00 
f010331d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103321:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f0103326:	89 04 24             	mov    %eax,(%esp)
f0103329:	e8 bd e5 ff ff       	call   f01018eb <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f010332e:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0103335:	02 02 02 
f0103338:	74 24                	je     f010335e <mem_init+0x19b1>
f010333a:	c7 44 24 0c 9c 55 10 	movl   $0xf010559c,0xc(%esp)
f0103341:	f0 
f0103342:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f0103349:	f0 
f010334a:	c7 44 24 04 8d 03 00 	movl   $0x38d,0x4(%esp)
f0103351:	00 
f0103352:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f0103359:	e8 36 cd ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f010335e:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0103363:	74 24                	je     f0103389 <mem_init+0x19dc>
f0103365:	c7 44 24 0c 1c 58 10 	movl   $0xf010581c,0xc(%esp)
f010336c:	f0 
f010336d:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f0103374:	f0 
f0103375:	c7 44 24 04 8e 03 00 	movl   $0x38e,0x4(%esp)
f010337c:	00 
f010337d:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f0103384:	e8 0b cd ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 0);
f0103389:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f010338e:	74 24                	je     f01033b4 <mem_init+0x1a07>
f0103390:	c7 44 24 0c 65 58 10 	movl   $0xf0105865,0xc(%esp)
f0103397:	f0 
f0103398:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f010339f:	f0 
f01033a0:	c7 44 24 04 8f 03 00 	movl   $0x38f,0x4(%esp)
f01033a7:	00 
f01033a8:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f01033af:	e8 e0 cc ff ff       	call   f0100094 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f01033b4:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f01033bb:	03 03 03 
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01033be:	89 d8                	mov    %ebx,%eax
f01033c0:	2b 05 8c 99 11 f0    	sub    0xf011998c,%eax
f01033c6:	c1 f8 03             	sar    $0x3,%eax
f01033c9:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01033cc:	89 c2                	mov    %eax,%edx
f01033ce:	c1 ea 0c             	shr    $0xc,%edx
f01033d1:	3b 15 84 99 11 f0    	cmp    0xf0119984,%edx
f01033d7:	72 20                	jb     f01033f9 <mem_init+0x1a4c>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01033d9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01033dd:	c7 44 24 08 6c 4c 10 	movl   $0xf0104c6c,0x8(%esp)
f01033e4:	f0 
f01033e5:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f01033ec:	00 
f01033ed:	c7 04 24 24 56 10 f0 	movl   $0xf0105624,(%esp)
f01033f4:	e8 9b cc ff ff       	call   f0100094 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f01033f9:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0103400:	03 03 03 
f0103403:	74 24                	je     f0103429 <mem_init+0x1a7c>
f0103405:	c7 44 24 0c c0 55 10 	movl   $0xf01055c0,0xc(%esp)
f010340c:	f0 
f010340d:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f0103414:	f0 
f0103415:	c7 44 24 04 91 03 00 	movl   $0x391,0x4(%esp)
f010341c:	00 
f010341d:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f0103424:	e8 6b cc ff ff       	call   f0100094 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0103429:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0103430:	00 
f0103431:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f0103436:	89 04 24             	mov    %eax,(%esp)
f0103439:	e8 6f e4 ff ff       	call   f01018ad <page_remove>
	assert(pp2->pp_ref == 0);
f010343e:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0103443:	74 24                	je     f0103469 <mem_init+0x1abc>
f0103445:	c7 44 24 0c 54 58 10 	movl   $0xf0105854,0xc(%esp)
f010344c:	f0 
f010344d:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f0103454:	f0 
f0103455:	c7 44 24 04 93 03 00 	movl   $0x393,0x4(%esp)
f010345c:	00 
f010345d:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f0103464:	e8 2b cc ff ff       	call   f0100094 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0103469:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f010346e:	8b 08                	mov    (%eax),%ecx
f0103470:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0103476:	89 f2                	mov    %esi,%edx
f0103478:	2b 15 8c 99 11 f0    	sub    0xf011998c,%edx
f010347e:	c1 fa 03             	sar    $0x3,%edx
f0103481:	c1 e2 0c             	shl    $0xc,%edx
f0103484:	39 d1                	cmp    %edx,%ecx
f0103486:	74 24                	je     f01034ac <mem_init+0x1aff>
f0103488:	c7 44 24 0c 3c 51 10 	movl   $0xf010513c,0xc(%esp)
f010348f:	f0 
f0103490:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f0103497:	f0 
f0103498:	c7 44 24 04 96 03 00 	movl   $0x396,0x4(%esp)
f010349f:	00 
f01034a0:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f01034a7:	e8 e8 cb ff ff       	call   f0100094 <_panic>
	kern_pgdir[0] = 0;
f01034ac:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f01034b2:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01034b7:	74 24                	je     f01034dd <mem_init+0x1b30>
f01034b9:	c7 44 24 0c 0b 58 10 	movl   $0xf010580b,0xc(%esp)
f01034c0:	f0 
f01034c1:	c7 44 24 08 3e 56 10 	movl   $0xf010563e,0x8(%esp)
f01034c8:	f0 
f01034c9:	c7 44 24 04 98 03 00 	movl   $0x398,0x4(%esp)
f01034d0:	00 
f01034d1:	c7 04 24 18 56 10 f0 	movl   $0xf0105618,(%esp)
f01034d8:	e8 b7 cb ff ff       	call   f0100094 <_panic>
	pp0->pp_ref = 0;
f01034dd:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// free the pages we took
	page_free(pp0);
f01034e3:	89 34 24             	mov    %esi,(%esp)
f01034e6:	e8 b2 e1 ff ff       	call   f010169d <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f01034eb:	c7 04 24 ec 55 10 f0 	movl   $0xf01055ec,(%esp)
f01034f2:	e8 97 00 00 00       	call   f010358e <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f01034f7:	83 c4 3c             	add    $0x3c,%esp
f01034fa:	5b                   	pop    %ebx
f01034fb:	5e                   	pop    %esi
f01034fc:	5f                   	pop    %edi
f01034fd:	5d                   	pop    %ebp
f01034fe:	c3                   	ret    
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f01034ff:	89 f2                	mov    %esi,%edx
f0103501:	89 d8                	mov    %ebx,%eax
f0103503:	e8 34 dc ff ff       	call   f010113c <check_va2pa>
f0103508:	81 c6 00 10 00 00    	add    $0x1000,%esi
f010350e:	e9 7e fa ff ff       	jmp    f0102f91 <mem_init+0x15e4>

f0103513 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0103513:	55                   	push   %ebp
f0103514:	89 e5                	mov    %esp,%ebp
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0103516:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103519:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f010351c:	5d                   	pop    %ebp
f010351d:	c3                   	ret    
	...

f0103520 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0103520:	55                   	push   %ebp
f0103521:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103523:	ba 70 00 00 00       	mov    $0x70,%edx
f0103528:	8b 45 08             	mov    0x8(%ebp),%eax
f010352b:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010352c:	b2 71                	mov    $0x71,%dl
f010352e:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f010352f:	0f b6 c0             	movzbl %al,%eax
}
f0103532:	5d                   	pop    %ebp
f0103533:	c3                   	ret    

f0103534 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0103534:	55                   	push   %ebp
f0103535:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103537:	ba 70 00 00 00       	mov    $0x70,%edx
f010353c:	8b 45 08             	mov    0x8(%ebp),%eax
f010353f:	ee                   	out    %al,(%dx)
f0103540:	b2 71                	mov    $0x71,%dl
f0103542:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103545:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0103546:	5d                   	pop    %ebp
f0103547:	c3                   	ret    

f0103548 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0103548:	55                   	push   %ebp
f0103549:	89 e5                	mov    %esp,%ebp
f010354b:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f010354e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103551:	89 04 24             	mov    %eax,(%esp)
f0103554:	e8 a0 d0 ff ff       	call   f01005f9 <cputchar>
	*cnt++;
}
f0103559:	c9                   	leave  
f010355a:	c3                   	ret    

f010355b <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f010355b:	55                   	push   %ebp
f010355c:	89 e5                	mov    %esp,%ebp
f010355e:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f0103561:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0103568:	8b 45 0c             	mov    0xc(%ebp),%eax
f010356b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010356f:	8b 45 08             	mov    0x8(%ebp),%eax
f0103572:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103576:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0103579:	89 44 24 04          	mov    %eax,0x4(%esp)
f010357d:	c7 04 24 48 35 10 f0 	movl   $0xf0103548,(%esp)
f0103584:	e8 c1 04 00 00       	call   f0103a4a <vprintfmt>
	return cnt;
}
f0103589:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010358c:	c9                   	leave  
f010358d:	c3                   	ret    

f010358e <cprintf>:

int
cprintf(const char *fmt, ...)
{
f010358e:	55                   	push   %ebp
f010358f:	89 e5                	mov    %esp,%ebp
f0103591:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0103594:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0103597:	89 44 24 04          	mov    %eax,0x4(%esp)
f010359b:	8b 45 08             	mov    0x8(%ebp),%eax
f010359e:	89 04 24             	mov    %eax,(%esp)
f01035a1:	e8 b5 ff ff ff       	call   f010355b <vcprintf>
	va_end(ap);

	return cnt;
}
f01035a6:	c9                   	leave  
f01035a7:	c3                   	ret    

f01035a8 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01035a8:	55                   	push   %ebp
f01035a9:	89 e5                	mov    %esp,%ebp
f01035ab:	57                   	push   %edi
f01035ac:	56                   	push   %esi
f01035ad:	53                   	push   %ebx
f01035ae:	83 ec 10             	sub    $0x10,%esp
f01035b1:	89 c3                	mov    %eax,%ebx
f01035b3:	89 55 e8             	mov    %edx,-0x18(%ebp)
f01035b6:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f01035b9:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f01035bc:	8b 0a                	mov    (%edx),%ecx
f01035be:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01035c1:	8b 00                	mov    (%eax),%eax
f01035c3:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01035c6:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)

	while (l <= r) {
f01035cd:	eb 77                	jmp    f0103646 <stab_binsearch+0x9e>
		int true_m = (l + r) / 2, m = true_m;
f01035cf:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01035d2:	01 c8                	add    %ecx,%eax
f01035d4:	bf 02 00 00 00       	mov    $0x2,%edi
f01035d9:	99                   	cltd   
f01035da:	f7 ff                	idiv   %edi
f01035dc:	89 c2                	mov    %eax,%edx

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01035de:	eb 01                	jmp    f01035e1 <stab_binsearch+0x39>
			m--;
f01035e0:	4a                   	dec    %edx

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01035e1:	39 ca                	cmp    %ecx,%edx
f01035e3:	7c 1d                	jl     f0103602 <stab_binsearch+0x5a>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f01035e5:	6b fa 0c             	imul   $0xc,%edx,%edi

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01035e8:	0f b6 7c 3b 04       	movzbl 0x4(%ebx,%edi,1),%edi
f01035ed:	39 f7                	cmp    %esi,%edi
f01035ef:	75 ef                	jne    f01035e0 <stab_binsearch+0x38>
f01035f1:	89 55 ec             	mov    %edx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01035f4:	6b fa 0c             	imul   $0xc,%edx,%edi
f01035f7:	8b 7c 3b 08          	mov    0x8(%ebx,%edi,1),%edi
f01035fb:	3b 7d 0c             	cmp    0xc(%ebp),%edi
f01035fe:	73 18                	jae    f0103618 <stab_binsearch+0x70>
f0103600:	eb 05                	jmp    f0103607 <stab_binsearch+0x5f>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0103602:	8d 48 01             	lea    0x1(%eax),%ecx
			continue;
f0103605:	eb 3f                	jmp    f0103646 <stab_binsearch+0x9e>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0103607:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f010360a:	89 11                	mov    %edx,(%ecx)
			l = true_m + 1;
f010360c:	8d 48 01             	lea    0x1(%eax),%ecx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010360f:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0103616:	eb 2e                	jmp    f0103646 <stab_binsearch+0x9e>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0103618:	3b 7d 0c             	cmp    0xc(%ebp),%edi
f010361b:	76 15                	jbe    f0103632 <stab_binsearch+0x8a>
			*region_right = m - 1;
f010361d:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0103620:	4f                   	dec    %edi
f0103621:	89 7d f0             	mov    %edi,-0x10(%ebp)
f0103624:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103627:	89 38                	mov    %edi,(%eax)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0103629:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0103630:	eb 14                	jmp    f0103646 <stab_binsearch+0x9e>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0103632:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0103635:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0103638:	89 39                	mov    %edi,(%ecx)
			l = m;
			addr++;
f010363a:	ff 45 0c             	incl   0xc(%ebp)
f010363d:	89 d1                	mov    %edx,%ecx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010363f:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0103646:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
f0103649:	7e 84                	jle    f01035cf <stab_binsearch+0x27>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f010364b:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f010364f:	75 0d                	jne    f010365e <stab_binsearch+0xb6>
		*region_right = *region_left - 1;
f0103651:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0103654:	8b 02                	mov    (%edx),%eax
f0103656:	48                   	dec    %eax
f0103657:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f010365a:	89 01                	mov    %eax,(%ecx)
f010365c:	eb 22                	jmp    f0103680 <stab_binsearch+0xd8>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010365e:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0103661:	8b 01                	mov    (%ecx),%eax
		     l > *region_left && stabs[l].n_type != type;
f0103663:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0103666:	8b 0a                	mov    (%edx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103668:	eb 01                	jmp    f010366b <stab_binsearch+0xc3>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f010366a:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010366b:	39 c1                	cmp    %eax,%ecx
f010366d:	7d 0c                	jge    f010367b <stab_binsearch+0xd3>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f010366f:	6b d0 0c             	imul   $0xc,%eax,%edx
	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
		     l > *region_left && stabs[l].n_type != type;
f0103672:	0f b6 54 13 04       	movzbl 0x4(%ebx,%edx,1),%edx
f0103677:	39 f2                	cmp    %esi,%edx
f0103679:	75 ef                	jne    f010366a <stab_binsearch+0xc2>
		     l--)
			/* do nothing */;
		*region_left = l;
f010367b:	8b 55 e8             	mov    -0x18(%ebp),%edx
f010367e:	89 02                	mov    %eax,(%edx)
	}
}
f0103680:	83 c4 10             	add    $0x10,%esp
f0103683:	5b                   	pop    %ebx
f0103684:	5e                   	pop    %esi
f0103685:	5f                   	pop    %edi
f0103686:	5d                   	pop    %ebp
f0103687:	c3                   	ret    

f0103688 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0103688:	55                   	push   %ebp
f0103689:	89 e5                	mov    %esp,%ebp
f010368b:	83 ec 58             	sub    $0x58,%esp
f010368e:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0103691:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0103694:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0103697:	8b 75 08             	mov    0x8(%ebp),%esi
f010369a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f010369d:	c7 03 ee 58 10 f0    	movl   $0xf01058ee,(%ebx)
	info->eip_line = 0;
f01036a3:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f01036aa:	c7 43 08 ee 58 10 f0 	movl   $0xf01058ee,0x8(%ebx)
	info->eip_fn_namelen = 9;
f01036b1:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f01036b8:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f01036bb:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f01036c2:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f01036c8:	76 12                	jbe    f01036dc <debuginfo_eip+0x54>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01036ca:	b8 ab e8 10 f0       	mov    $0xf010e8ab,%eax
f01036cf:	3d 7d c8 10 f0       	cmp    $0xf010c87d,%eax
f01036d4:	0f 86 f1 01 00 00    	jbe    f01038cb <debuginfo_eip+0x243>
f01036da:	eb 1c                	jmp    f01036f8 <debuginfo_eip+0x70>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f01036dc:	c7 44 24 08 f8 58 10 	movl   $0xf01058f8,0x8(%esp)
f01036e3:	f0 
f01036e4:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f01036eb:	00 
f01036ec:	c7 04 24 05 59 10 f0 	movl   $0xf0105905,(%esp)
f01036f3:	e8 9c c9 ff ff       	call   f0100094 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f01036f8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01036fd:	80 3d aa e8 10 f0 00 	cmpb   $0x0,0xf010e8aa
f0103704:	0f 85 cd 01 00 00    	jne    f01038d7 <debuginfo_eip+0x24f>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f010370a:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0103711:	b8 7c c8 10 f0       	mov    $0xf010c87c,%eax
f0103716:	2d 14 5b 10 f0       	sub    $0xf0105b14,%eax
f010371b:	c1 f8 02             	sar    $0x2,%eax
f010371e:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0103724:	83 e8 01             	sub    $0x1,%eax
f0103727:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f010372a:	89 74 24 04          	mov    %esi,0x4(%esp)
f010372e:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0103735:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0103738:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f010373b:	b8 14 5b 10 f0       	mov    $0xf0105b14,%eax
f0103740:	e8 63 fe ff ff       	call   f01035a8 <stab_binsearch>
	if (lfile == 0)
f0103745:	8b 55 e4             	mov    -0x1c(%ebp),%edx
		return -1;
f0103748:	b8 ff ff ff ff       	mov    $0xffffffff,%eax

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
f010374d:	85 d2                	test   %edx,%edx
f010374f:	0f 84 82 01 00 00    	je     f01038d7 <debuginfo_eip+0x24f>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0103755:	89 55 dc             	mov    %edx,-0x24(%ebp)
	rfun = rfile;
f0103758:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010375b:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f010375e:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103762:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0103769:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f010376c:	8d 55 dc             	lea    -0x24(%ebp),%edx
f010376f:	b8 14 5b 10 f0       	mov    $0xf0105b14,%eax
f0103774:	e8 2f fe ff ff       	call   f01035a8 <stab_binsearch>

	if (lfun <= rfun) {
f0103779:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010377c:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010377f:	39 d0                	cmp    %edx,%eax
f0103781:	7f 3d                	jg     f01037c0 <debuginfo_eip+0x138>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0103783:	6b c8 0c             	imul   $0xc,%eax,%ecx
f0103786:	8d b9 14 5b 10 f0    	lea    -0xfefa4ec(%ecx),%edi
f010378c:	89 7d c0             	mov    %edi,-0x40(%ebp)
f010378f:	8b 89 14 5b 10 f0    	mov    -0xfefa4ec(%ecx),%ecx
f0103795:	bf ab e8 10 f0       	mov    $0xf010e8ab,%edi
f010379a:	81 ef 7d c8 10 f0    	sub    $0xf010c87d,%edi
f01037a0:	39 f9                	cmp    %edi,%ecx
f01037a2:	73 09                	jae    f01037ad <debuginfo_eip+0x125>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f01037a4:	81 c1 7d c8 10 f0    	add    $0xf010c87d,%ecx
f01037aa:	89 4b 08             	mov    %ecx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f01037ad:	8b 7d c0             	mov    -0x40(%ebp),%edi
f01037b0:	8b 4f 08             	mov    0x8(%edi),%ecx
f01037b3:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f01037b6:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f01037b8:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f01037bb:	89 55 d0             	mov    %edx,-0x30(%ebp)
f01037be:	eb 0f                	jmp    f01037cf <debuginfo_eip+0x147>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f01037c0:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f01037c3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01037c6:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f01037c9:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01037cc:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f01037cf:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f01037d6:	00 
f01037d7:	8b 43 08             	mov    0x8(%ebx),%eax
f01037da:	89 04 24             	mov    %eax,(%esp)
f01037dd:	e8 48 09 00 00       	call   f010412a <strfind>
f01037e2:	2b 43 08             	sub    0x8(%ebx),%eax
f01037e5:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f01037e8:	89 74 24 04          	mov    %esi,0x4(%esp)
f01037ec:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f01037f3:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f01037f6:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f01037f9:	b8 14 5b 10 f0       	mov    $0xf0105b14,%eax
f01037fe:	e8 a5 fd ff ff       	call   f01035a8 <stab_binsearch>
	if (lline <= rline) {
f0103803:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103806:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0103809:	7f 0f                	jg     f010381a <debuginfo_eip+0x192>
		info->eip_line = stabs[lline].n_desc;
f010380b:	6b c0 0c             	imul   $0xc,%eax,%eax
f010380e:	0f b7 80 1a 5b 10 f0 	movzwl -0xfefa4e6(%eax),%eax
f0103815:	89 43 04             	mov    %eax,0x4(%ebx)
f0103818:	eb 07                	jmp    f0103821 <debuginfo_eip+0x199>
	} else {
		info->eip_line = -1;
f010381a:	c7 43 04 ff ff ff ff 	movl   $0xffffffff,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0103821:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103824:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0103827:	39 c8                	cmp    %ecx,%eax
f0103829:	7c 5f                	jl     f010388a <debuginfo_eip+0x202>
	       && stabs[lline].n_type != N_SOL
f010382b:	89 c2                	mov    %eax,%edx
f010382d:	6b f0 0c             	imul   $0xc,%eax,%esi
f0103830:	80 be 18 5b 10 f0 84 	cmpb   $0x84,-0xfefa4e8(%esi)
f0103837:	75 18                	jne    f0103851 <debuginfo_eip+0x1c9>
f0103839:	eb 30                	jmp    f010386b <debuginfo_eip+0x1e3>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f010383b:	83 e8 01             	sub    $0x1,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f010383e:	39 c1                	cmp    %eax,%ecx
f0103840:	7f 48                	jg     f010388a <debuginfo_eip+0x202>
	       && stabs[lline].n_type != N_SOL
f0103842:	89 c2                	mov    %eax,%edx
f0103844:	8d 34 40             	lea    (%eax,%eax,2),%esi
f0103847:	80 3c b5 18 5b 10 f0 	cmpb   $0x84,-0xfefa4e8(,%esi,4)
f010384e:	84 
f010384f:	74 1a                	je     f010386b <debuginfo_eip+0x1e3>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0103851:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0103854:	8d 14 95 14 5b 10 f0 	lea    -0xfefa4ec(,%edx,4),%edx
f010385b:	80 7a 04 64          	cmpb   $0x64,0x4(%edx)
f010385f:	75 da                	jne    f010383b <debuginfo_eip+0x1b3>
f0103861:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f0103865:	74 d4                	je     f010383b <debuginfo_eip+0x1b3>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0103867:	39 c8                	cmp    %ecx,%eax
f0103869:	7c 1f                	jl     f010388a <debuginfo_eip+0x202>
f010386b:	6b c0 0c             	imul   $0xc,%eax,%eax
f010386e:	8b 80 14 5b 10 f0    	mov    -0xfefa4ec(%eax),%eax
f0103874:	ba ab e8 10 f0       	mov    $0xf010e8ab,%edx
f0103879:	81 ea 7d c8 10 f0    	sub    $0xf010c87d,%edx
f010387f:	39 d0                	cmp    %edx,%eax
f0103881:	73 07                	jae    f010388a <debuginfo_eip+0x202>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0103883:	05 7d c8 10 f0       	add    $0xf010c87d,%eax
f0103888:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f010388a:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010388d:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103890:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103895:	39 ca                	cmp    %ecx,%edx
f0103897:	7d 3e                	jge    f01038d7 <debuginfo_eip+0x24f>
		for (lline = lfun + 1;
f0103899:	83 c2 01             	add    $0x1,%edx
f010389c:	39 d1                	cmp    %edx,%ecx
f010389e:	7e 37                	jle    f01038d7 <debuginfo_eip+0x24f>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f01038a0:	6b f2 0c             	imul   $0xc,%edx,%esi
f01038a3:	80 be 18 5b 10 f0 a0 	cmpb   $0xa0,-0xfefa4e8(%esi)
f01038aa:	75 2b                	jne    f01038d7 <debuginfo_eip+0x24f>
		     lline++)
			info->eip_fn_narg++;
f01038ac:	83 43 14 01          	addl   $0x1,0x14(%ebx)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f01038b0:	83 c2 01             	add    $0x1,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f01038b3:	39 d1                	cmp    %edx,%ecx
f01038b5:	7e 1b                	jle    f01038d2 <debuginfo_eip+0x24a>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f01038b7:	8d 04 52             	lea    (%edx,%edx,2),%eax
f01038ba:	80 3c 85 18 5b 10 f0 	cmpb   $0xa0,-0xfefa4e8(,%eax,4)
f01038c1:	a0 
f01038c2:	74 e8                	je     f01038ac <debuginfo_eip+0x224>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01038c4:	b8 00 00 00 00       	mov    $0x0,%eax
f01038c9:	eb 0c                	jmp    f01038d7 <debuginfo_eip+0x24f>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f01038cb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01038d0:	eb 05                	jmp    f01038d7 <debuginfo_eip+0x24f>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01038d2:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01038d7:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f01038da:	8b 75 f8             	mov    -0x8(%ebp),%esi
f01038dd:	8b 7d fc             	mov    -0x4(%ebp),%edi
f01038e0:	89 ec                	mov    %ebp,%esp
f01038e2:	5d                   	pop    %ebp
f01038e3:	c3                   	ret    
	...

f01038f0 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f01038f0:	55                   	push   %ebp
f01038f1:	89 e5                	mov    %esp,%ebp
f01038f3:	57                   	push   %edi
f01038f4:	56                   	push   %esi
f01038f5:	53                   	push   %ebx
f01038f6:	83 ec 3c             	sub    $0x3c,%esp
f01038f9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01038fc:	89 d7                	mov    %edx,%edi
f01038fe:	8b 45 08             	mov    0x8(%ebp),%eax
f0103901:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0103904:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103907:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010390a:	8b 5d 14             	mov    0x14(%ebp),%ebx
f010390d:	8b 75 18             	mov    0x18(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0103910:	b8 00 00 00 00       	mov    $0x0,%eax
f0103915:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0103918:	72 11                	jb     f010392b <printnum+0x3b>
f010391a:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010391d:	39 45 10             	cmp    %eax,0x10(%ebp)
f0103920:	76 09                	jbe    f010392b <printnum+0x3b>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0103922:	83 eb 01             	sub    $0x1,%ebx
f0103925:	85 db                	test   %ebx,%ebx
f0103927:	7f 51                	jg     f010397a <printnum+0x8a>
f0103929:	eb 5e                	jmp    f0103989 <printnum+0x99>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
f010392b:	89 74 24 10          	mov    %esi,0x10(%esp)
f010392f:	83 eb 01             	sub    $0x1,%ebx
f0103932:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0103936:	8b 45 10             	mov    0x10(%ebp),%eax
f0103939:	89 44 24 08          	mov    %eax,0x8(%esp)
f010393d:	8b 5c 24 08          	mov    0x8(%esp),%ebx
f0103941:	8b 74 24 0c          	mov    0xc(%esp),%esi
f0103945:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f010394c:	00 
f010394d:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103950:	89 04 24             	mov    %eax,(%esp)
f0103953:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103956:	89 44 24 04          	mov    %eax,0x4(%esp)
f010395a:	e8 41 0a 00 00       	call   f01043a0 <__udivdi3>
f010395f:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0103963:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0103967:	89 04 24             	mov    %eax,(%esp)
f010396a:	89 54 24 04          	mov    %edx,0x4(%esp)
f010396e:	89 fa                	mov    %edi,%edx
f0103970:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103973:	e8 78 ff ff ff       	call   f01038f0 <printnum>
f0103978:	eb 0f                	jmp    f0103989 <printnum+0x99>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f010397a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010397e:	89 34 24             	mov    %esi,(%esp)
f0103981:	ff 55 e4             	call   *-0x1c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0103984:	83 eb 01             	sub    $0x1,%ebx
f0103987:	75 f1                	jne    f010397a <printnum+0x8a>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0103989:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010398d:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0103991:	8b 45 10             	mov    0x10(%ebp),%eax
f0103994:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103998:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f010399f:	00 
f01039a0:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01039a3:	89 04 24             	mov    %eax,(%esp)
f01039a6:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01039a9:	89 44 24 04          	mov    %eax,0x4(%esp)
f01039ad:	e8 1e 0b 00 00       	call   f01044d0 <__umoddi3>
f01039b2:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01039b6:	0f be 80 13 59 10 f0 	movsbl -0xfefa6ed(%eax),%eax
f01039bd:	89 04 24             	mov    %eax,(%esp)
f01039c0:	ff 55 e4             	call   *-0x1c(%ebp)
}
f01039c3:	83 c4 3c             	add    $0x3c,%esp
f01039c6:	5b                   	pop    %ebx
f01039c7:	5e                   	pop    %esi
f01039c8:	5f                   	pop    %edi
f01039c9:	5d                   	pop    %ebp
f01039ca:	c3                   	ret    

f01039cb <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f01039cb:	55                   	push   %ebp
f01039cc:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f01039ce:	83 fa 01             	cmp    $0x1,%edx
f01039d1:	7e 0e                	jle    f01039e1 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f01039d3:	8b 10                	mov    (%eax),%edx
f01039d5:	8d 4a 08             	lea    0x8(%edx),%ecx
f01039d8:	89 08                	mov    %ecx,(%eax)
f01039da:	8b 02                	mov    (%edx),%eax
f01039dc:	8b 52 04             	mov    0x4(%edx),%edx
f01039df:	eb 22                	jmp    f0103a03 <getuint+0x38>
	else if (lflag)
f01039e1:	85 d2                	test   %edx,%edx
f01039e3:	74 10                	je     f01039f5 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f01039e5:	8b 10                	mov    (%eax),%edx
f01039e7:	8d 4a 04             	lea    0x4(%edx),%ecx
f01039ea:	89 08                	mov    %ecx,(%eax)
f01039ec:	8b 02                	mov    (%edx),%eax
f01039ee:	ba 00 00 00 00       	mov    $0x0,%edx
f01039f3:	eb 0e                	jmp    f0103a03 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f01039f5:	8b 10                	mov    (%eax),%edx
f01039f7:	8d 4a 04             	lea    0x4(%edx),%ecx
f01039fa:	89 08                	mov    %ecx,(%eax)
f01039fc:	8b 02                	mov    (%edx),%eax
f01039fe:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0103a03:	5d                   	pop    %ebp
f0103a04:	c3                   	ret    

f0103a05 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0103a05:	55                   	push   %ebp
f0103a06:	89 e5                	mov    %esp,%ebp
f0103a08:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f0103a0b:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f0103a0f:	8b 10                	mov    (%eax),%edx
f0103a11:	3b 50 04             	cmp    0x4(%eax),%edx
f0103a14:	73 0a                	jae    f0103a20 <sprintputch+0x1b>
		*b->buf++ = ch;
f0103a16:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103a19:	88 0a                	mov    %cl,(%edx)
f0103a1b:	83 c2 01             	add    $0x1,%edx
f0103a1e:	89 10                	mov    %edx,(%eax)
}
f0103a20:	5d                   	pop    %ebp
f0103a21:	c3                   	ret    

f0103a22 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0103a22:	55                   	push   %ebp
f0103a23:	89 e5                	mov    %esp,%ebp
f0103a25:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f0103a28:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0103a2b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103a2f:	8b 45 10             	mov    0x10(%ebp),%eax
f0103a32:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103a36:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103a39:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103a3d:	8b 45 08             	mov    0x8(%ebp),%eax
f0103a40:	89 04 24             	mov    %eax,(%esp)
f0103a43:	e8 02 00 00 00       	call   f0103a4a <vprintfmt>
	va_end(ap);
}
f0103a48:	c9                   	leave  
f0103a49:	c3                   	ret    

f0103a4a <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0103a4a:	55                   	push   %ebp
f0103a4b:	89 e5                	mov    %esp,%ebp
f0103a4d:	57                   	push   %edi
f0103a4e:	56                   	push   %esi
f0103a4f:	53                   	push   %ebx
f0103a50:	83 ec 4c             	sub    $0x4c,%esp
f0103a53:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103a56:	8b 75 10             	mov    0x10(%ebp),%esi
f0103a59:	eb 12                	jmp    f0103a6d <vprintfmt+0x23>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0103a5b:	85 c0                	test   %eax,%eax
f0103a5d:	0f 84 a9 03 00 00    	je     f0103e0c <vprintfmt+0x3c2>
				return;
			putch(ch, putdat);
f0103a63:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103a67:	89 04 24             	mov    %eax,(%esp)
f0103a6a:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0103a6d:	0f b6 06             	movzbl (%esi),%eax
f0103a70:	83 c6 01             	add    $0x1,%esi
f0103a73:	83 f8 25             	cmp    $0x25,%eax
f0103a76:	75 e3                	jne    f0103a5b <vprintfmt+0x11>
f0103a78:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
f0103a7c:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
f0103a83:	bf ff ff ff ff       	mov    $0xffffffff,%edi
f0103a88:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
f0103a8f:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103a94:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0103a97:	eb 2b                	jmp    f0103ac4 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103a99:	8b 75 e0             	mov    -0x20(%ebp),%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f0103a9c:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
f0103aa0:	eb 22                	jmp    f0103ac4 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103aa2:	8b 75 e0             	mov    -0x20(%ebp),%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0103aa5:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
f0103aa9:	eb 19                	jmp    f0103ac4 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103aab:	8b 75 e0             	mov    -0x20(%ebp),%esi
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
f0103aae:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f0103ab5:	eb 0d                	jmp    f0103ac4 <vprintfmt+0x7a>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f0103ab7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103aba:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103abd:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103ac4:	0f b6 06             	movzbl (%esi),%eax
f0103ac7:	0f b6 d0             	movzbl %al,%edx
f0103aca:	8d 7e 01             	lea    0x1(%esi),%edi
f0103acd:	89 7d e0             	mov    %edi,-0x20(%ebp)
f0103ad0:	83 e8 23             	sub    $0x23,%eax
f0103ad3:	3c 55                	cmp    $0x55,%al
f0103ad5:	0f 87 0b 03 00 00    	ja     f0103de6 <vprintfmt+0x39c>
f0103adb:	0f b6 c0             	movzbl %al,%eax
f0103ade:	ff 24 85 90 59 10 f0 	jmp    *-0xfefa670(,%eax,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0103ae5:	83 ea 30             	sub    $0x30,%edx
f0103ae8:	89 55 d4             	mov    %edx,-0x2c(%ebp)
				ch = *fmt;
f0103aeb:	0f be 46 01          	movsbl 0x1(%esi),%eax
				if (ch < '0' || ch > '9')
f0103aef:	8d 50 d0             	lea    -0x30(%eax),%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103af2:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
f0103af5:	83 fa 09             	cmp    $0x9,%edx
f0103af8:	77 4a                	ja     f0103b44 <vprintfmt+0xfa>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103afa:	8b 7d d4             	mov    -0x2c(%ebp),%edi
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0103afd:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
f0103b00:	8d 14 bf             	lea    (%edi,%edi,4),%edx
f0103b03:	8d 7c 50 d0          	lea    -0x30(%eax,%edx,2),%edi
				ch = *fmt;
f0103b07:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f0103b0a:	8d 50 d0             	lea    -0x30(%eax),%edx
f0103b0d:	83 fa 09             	cmp    $0x9,%edx
f0103b10:	76 eb                	jbe    f0103afd <vprintfmt+0xb3>
f0103b12:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0103b15:	eb 2d                	jmp    f0103b44 <vprintfmt+0xfa>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0103b17:	8b 45 14             	mov    0x14(%ebp),%eax
f0103b1a:	8d 50 04             	lea    0x4(%eax),%edx
f0103b1d:	89 55 14             	mov    %edx,0x14(%ebp)
f0103b20:	8b 00                	mov    (%eax),%eax
f0103b22:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103b25:	8b 75 e0             	mov    -0x20(%ebp),%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0103b28:	eb 1a                	jmp    f0103b44 <vprintfmt+0xfa>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103b2a:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case '*':
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
f0103b2d:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0103b31:	79 91                	jns    f0103ac4 <vprintfmt+0x7a>
f0103b33:	e9 73 ff ff ff       	jmp    f0103aab <vprintfmt+0x61>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103b38:	8b 75 e0             	mov    -0x20(%ebp),%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0103b3b:	c7 45 dc 01 00 00 00 	movl   $0x1,-0x24(%ebp)
			goto reswitch;
f0103b42:	eb 80                	jmp    f0103ac4 <vprintfmt+0x7a>

		process_precision:
			if (width < 0)
f0103b44:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0103b48:	0f 89 76 ff ff ff    	jns    f0103ac4 <vprintfmt+0x7a>
f0103b4e:	e9 64 ff ff ff       	jmp    f0103ab7 <vprintfmt+0x6d>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0103b53:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103b56:	8b 75 e0             	mov    -0x20(%ebp),%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0103b59:	e9 66 ff ff ff       	jmp    f0103ac4 <vprintfmt+0x7a>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0103b5e:	8b 45 14             	mov    0x14(%ebp),%eax
f0103b61:	8d 50 04             	lea    0x4(%eax),%edx
f0103b64:	89 55 14             	mov    %edx,0x14(%ebp)
f0103b67:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103b6b:	8b 00                	mov    (%eax),%eax
f0103b6d:	89 04 24             	mov    %eax,(%esp)
f0103b70:	ff 55 08             	call   *0x8(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103b73:	8b 75 e0             	mov    -0x20(%ebp),%esi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0103b76:	e9 f2 fe ff ff       	jmp    f0103a6d <vprintfmt+0x23>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0103b7b:	8b 45 14             	mov    0x14(%ebp),%eax
f0103b7e:	8d 50 04             	lea    0x4(%eax),%edx
f0103b81:	89 55 14             	mov    %edx,0x14(%ebp)
f0103b84:	8b 00                	mov    (%eax),%eax
f0103b86:	89 c2                	mov    %eax,%edx
f0103b88:	c1 fa 1f             	sar    $0x1f,%edx
f0103b8b:	31 d0                	xor    %edx,%eax
f0103b8d:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0103b8f:	83 f8 06             	cmp    $0x6,%eax
f0103b92:	7f 0b                	jg     f0103b9f <vprintfmt+0x155>
f0103b94:	8b 14 85 e8 5a 10 f0 	mov    -0xfefa518(,%eax,4),%edx
f0103b9b:	85 d2                	test   %edx,%edx
f0103b9d:	75 23                	jne    f0103bc2 <vprintfmt+0x178>
				printfmt(putch, putdat, "error %d", err);
f0103b9f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103ba3:	c7 44 24 08 2b 59 10 	movl   $0xf010592b,0x8(%esp)
f0103baa:	f0 
f0103bab:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103baf:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103bb2:	89 3c 24             	mov    %edi,(%esp)
f0103bb5:	e8 68 fe ff ff       	call   f0103a22 <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103bba:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0103bbd:	e9 ab fe ff ff       	jmp    f0103a6d <vprintfmt+0x23>
			else
				printfmt(putch, putdat, "%s", p);
f0103bc2:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103bc6:	c7 44 24 08 50 56 10 	movl   $0xf0105650,0x8(%esp)
f0103bcd:	f0 
f0103bce:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103bd2:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103bd5:	89 3c 24             	mov    %edi,(%esp)
f0103bd8:	e8 45 fe ff ff       	call   f0103a22 <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103bdd:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0103be0:	e9 88 fe ff ff       	jmp    f0103a6d <vprintfmt+0x23>
f0103be5:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0103be8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103beb:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0103bee:	8b 45 14             	mov    0x14(%ebp),%eax
f0103bf1:	8d 50 04             	lea    0x4(%eax),%edx
f0103bf4:	89 55 14             	mov    %edx,0x14(%ebp)
f0103bf7:	8b 30                	mov    (%eax),%esi
				p = "(null)";
f0103bf9:	85 f6                	test   %esi,%esi
f0103bfb:	ba 24 59 10 f0       	mov    $0xf0105924,%edx
f0103c00:	0f 44 f2             	cmove  %edx,%esi
			if (width > 0 && padc != '-')
f0103c03:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f0103c07:	7e 06                	jle    f0103c0f <vprintfmt+0x1c5>
f0103c09:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
f0103c0d:	75 10                	jne    f0103c1f <vprintfmt+0x1d5>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0103c0f:	0f be 06             	movsbl (%esi),%eax
f0103c12:	83 c6 01             	add    $0x1,%esi
f0103c15:	85 c0                	test   %eax,%eax
f0103c17:	0f 85 86 00 00 00    	jne    f0103ca3 <vprintfmt+0x259>
f0103c1d:	eb 76                	jmp    f0103c95 <vprintfmt+0x24b>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0103c1f:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103c23:	89 34 24             	mov    %esi,(%esp)
f0103c26:	e8 60 03 00 00       	call   f0103f8b <strnlen>
f0103c2b:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0103c2e:	29 c2                	sub    %eax,%edx
f0103c30:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0103c33:	85 d2                	test   %edx,%edx
f0103c35:	7e d8                	jle    f0103c0f <vprintfmt+0x1c5>
					putch(padc, putdat);
f0103c37:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
f0103c3b:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f0103c3e:	89 d6                	mov    %edx,%esi
f0103c40:	89 7d d0             	mov    %edi,-0x30(%ebp)
f0103c43:	89 c7                	mov    %eax,%edi
f0103c45:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103c49:	89 3c 24             	mov    %edi,(%esp)
f0103c4c:	ff 55 08             	call   *0x8(%ebp)
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0103c4f:	83 ee 01             	sub    $0x1,%esi
f0103c52:	75 f1                	jne    f0103c45 <vprintfmt+0x1fb>
f0103c54:	89 75 e4             	mov    %esi,-0x1c(%ebp)
f0103c57:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f0103c5a:	8b 7d d0             	mov    -0x30(%ebp),%edi
f0103c5d:	eb b0                	jmp    f0103c0f <vprintfmt+0x1c5>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0103c5f:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0103c63:	74 18                	je     f0103c7d <vprintfmt+0x233>
f0103c65:	8d 50 e0             	lea    -0x20(%eax),%edx
f0103c68:	83 fa 5e             	cmp    $0x5e,%edx
f0103c6b:	76 10                	jbe    f0103c7d <vprintfmt+0x233>
					putch('?', putdat);
f0103c6d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103c71:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0103c78:	ff 55 08             	call   *0x8(%ebp)
f0103c7b:	eb 0a                	jmp    f0103c87 <vprintfmt+0x23d>
				else
					putch(ch, putdat);
f0103c7d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103c81:	89 04 24             	mov    %eax,(%esp)
f0103c84:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0103c87:	83 6d e4 01          	subl   $0x1,-0x1c(%ebp)
f0103c8b:	0f be 06             	movsbl (%esi),%eax
f0103c8e:	83 c6 01             	add    $0x1,%esi
f0103c91:	85 c0                	test   %eax,%eax
f0103c93:	75 0e                	jne    f0103ca3 <vprintfmt+0x259>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103c95:	8b 75 e0             	mov    -0x20(%ebp),%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0103c98:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0103c9c:	7f 16                	jg     f0103cb4 <vprintfmt+0x26a>
f0103c9e:	e9 ca fd ff ff       	jmp    f0103a6d <vprintfmt+0x23>
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0103ca3:	85 ff                	test   %edi,%edi
f0103ca5:	78 b8                	js     f0103c5f <vprintfmt+0x215>
f0103ca7:	83 ef 01             	sub    $0x1,%edi
f0103caa:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103cb0:	79 ad                	jns    f0103c5f <vprintfmt+0x215>
f0103cb2:	eb e1                	jmp    f0103c95 <vprintfmt+0x24b>
f0103cb4:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103cb7:	8b 7d 08             	mov    0x8(%ebp),%edi
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0103cba:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103cbe:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0103cc5:	ff d7                	call   *%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0103cc7:	83 ee 01             	sub    $0x1,%esi
f0103cca:	75 ee                	jne    f0103cba <vprintfmt+0x270>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103ccc:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0103ccf:	e9 99 fd ff ff       	jmp    f0103a6d <vprintfmt+0x23>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0103cd4:	83 f9 01             	cmp    $0x1,%ecx
f0103cd7:	7e 10                	jle    f0103ce9 <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f0103cd9:	8b 45 14             	mov    0x14(%ebp),%eax
f0103cdc:	8d 50 08             	lea    0x8(%eax),%edx
f0103cdf:	89 55 14             	mov    %edx,0x14(%ebp)
f0103ce2:	8b 30                	mov    (%eax),%esi
f0103ce4:	8b 78 04             	mov    0x4(%eax),%edi
f0103ce7:	eb 26                	jmp    f0103d0f <vprintfmt+0x2c5>
	else if (lflag)
f0103ce9:	85 c9                	test   %ecx,%ecx
f0103ceb:	74 12                	je     f0103cff <vprintfmt+0x2b5>
		return va_arg(*ap, long);
f0103ced:	8b 45 14             	mov    0x14(%ebp),%eax
f0103cf0:	8d 50 04             	lea    0x4(%eax),%edx
f0103cf3:	89 55 14             	mov    %edx,0x14(%ebp)
f0103cf6:	8b 30                	mov    (%eax),%esi
f0103cf8:	89 f7                	mov    %esi,%edi
f0103cfa:	c1 ff 1f             	sar    $0x1f,%edi
f0103cfd:	eb 10                	jmp    f0103d0f <vprintfmt+0x2c5>
	else
		return va_arg(*ap, int);
f0103cff:	8b 45 14             	mov    0x14(%ebp),%eax
f0103d02:	8d 50 04             	lea    0x4(%eax),%edx
f0103d05:	89 55 14             	mov    %edx,0x14(%ebp)
f0103d08:	8b 30                	mov    (%eax),%esi
f0103d0a:	89 f7                	mov    %esi,%edi
f0103d0c:	c1 ff 1f             	sar    $0x1f,%edi
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0103d0f:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0103d14:	85 ff                	test   %edi,%edi
f0103d16:	0f 89 8c 00 00 00    	jns    f0103da8 <vprintfmt+0x35e>
				putch('-', putdat);
f0103d1c:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103d20:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f0103d27:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f0103d2a:	f7 de                	neg    %esi
f0103d2c:	83 d7 00             	adc    $0x0,%edi
f0103d2f:	f7 df                	neg    %edi
			}
			base = 10;
f0103d31:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103d36:	eb 70                	jmp    f0103da8 <vprintfmt+0x35e>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0103d38:	89 ca                	mov    %ecx,%edx
f0103d3a:	8d 45 14             	lea    0x14(%ebp),%eax
f0103d3d:	e8 89 fc ff ff       	call   f01039cb <getuint>
f0103d42:	89 c6                	mov    %eax,%esi
f0103d44:	89 d7                	mov    %edx,%edi
			base = 10;
f0103d46:	b8 0a 00 00 00       	mov    $0xa,%eax
			goto number;
f0103d4b:	eb 5b                	jmp    f0103da8 <vprintfmt+0x35e>
			// Replace this with your code.
			//putch('0', putdat);
			//putch('X', putdat);
			//putch('X', putdat);
			//break;
			num = getuint(&ap, lflag);
f0103d4d:	89 ca                	mov    %ecx,%edx
f0103d4f:	8d 45 14             	lea    0x14(%ebp),%eax
f0103d52:	e8 74 fc ff ff       	call   f01039cb <getuint>
f0103d57:	89 c6                	mov    %eax,%esi
f0103d59:	89 d7                	mov    %edx,%edi
			base = 8;
f0103d5b:	b8 08 00 00 00       	mov    $0x8,%eax
			goto number;
f0103d60:	eb 46                	jmp    f0103da8 <vprintfmt+0x35e>
		// pointer
		case 'p':
			putch('0', putdat);
f0103d62:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103d66:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f0103d6d:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f0103d70:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103d74:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f0103d7b:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0103d7e:	8b 45 14             	mov    0x14(%ebp),%eax
f0103d81:	8d 50 04             	lea    0x4(%eax),%edx
f0103d84:	89 55 14             	mov    %edx,0x14(%ebp)
			goto number;
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0103d87:	8b 30                	mov    (%eax),%esi
f0103d89:	bf 00 00 00 00       	mov    $0x0,%edi
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0103d8e:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f0103d93:	eb 13                	jmp    f0103da8 <vprintfmt+0x35e>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0103d95:	89 ca                	mov    %ecx,%edx
f0103d97:	8d 45 14             	lea    0x14(%ebp),%eax
f0103d9a:	e8 2c fc ff ff       	call   f01039cb <getuint>
f0103d9f:	89 c6                	mov    %eax,%esi
f0103da1:	89 d7                	mov    %edx,%edi
			base = 16;
f0103da3:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f0103da8:	0f be 55 d8          	movsbl -0x28(%ebp),%edx
f0103dac:	89 54 24 10          	mov    %edx,0x10(%esp)
f0103db0:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0103db3:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103db7:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103dbb:	89 34 24             	mov    %esi,(%esp)
f0103dbe:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103dc2:	89 da                	mov    %ebx,%edx
f0103dc4:	8b 45 08             	mov    0x8(%ebp),%eax
f0103dc7:	e8 24 fb ff ff       	call   f01038f0 <printnum>
			break;
f0103dcc:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0103dcf:	e9 99 fc ff ff       	jmp    f0103a6d <vprintfmt+0x23>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0103dd4:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103dd8:	89 14 24             	mov    %edx,(%esp)
f0103ddb:	ff 55 08             	call   *0x8(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103dde:	8b 75 e0             	mov    -0x20(%ebp),%esi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0103de1:	e9 87 fc ff ff       	jmp    f0103a6d <vprintfmt+0x23>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0103de6:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103dea:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0103df1:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0103df4:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
f0103df8:	0f 84 6f fc ff ff    	je     f0103a6d <vprintfmt+0x23>
f0103dfe:	83 ee 01             	sub    $0x1,%esi
f0103e01:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
f0103e05:	75 f7                	jne    f0103dfe <vprintfmt+0x3b4>
f0103e07:	e9 61 fc ff ff       	jmp    f0103a6d <vprintfmt+0x23>
				/* do nothing */;
			break;
		}
	}
}
f0103e0c:	83 c4 4c             	add    $0x4c,%esp
f0103e0f:	5b                   	pop    %ebx
f0103e10:	5e                   	pop    %esi
f0103e11:	5f                   	pop    %edi
f0103e12:	5d                   	pop    %ebp
f0103e13:	c3                   	ret    

f0103e14 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0103e14:	55                   	push   %ebp
f0103e15:	89 e5                	mov    %esp,%ebp
f0103e17:	83 ec 28             	sub    $0x28,%esp
f0103e1a:	8b 45 08             	mov    0x8(%ebp),%eax
f0103e1d:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0103e20:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103e23:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0103e27:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0103e2a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0103e31:	85 c0                	test   %eax,%eax
f0103e33:	74 30                	je     f0103e65 <vsnprintf+0x51>
f0103e35:	85 d2                	test   %edx,%edx
f0103e37:	7e 2c                	jle    f0103e65 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0103e39:	8b 45 14             	mov    0x14(%ebp),%eax
f0103e3c:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103e40:	8b 45 10             	mov    0x10(%ebp),%eax
f0103e43:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103e47:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0103e4a:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103e4e:	c7 04 24 05 3a 10 f0 	movl   $0xf0103a05,(%esp)
f0103e55:	e8 f0 fb ff ff       	call   f0103a4a <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0103e5a:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0103e5d:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0103e60:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103e63:	eb 05                	jmp    f0103e6a <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0103e65:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0103e6a:	c9                   	leave  
f0103e6b:	c3                   	ret    

f0103e6c <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0103e6c:	55                   	push   %ebp
f0103e6d:	89 e5                	mov    %esp,%ebp
f0103e6f:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0103e72:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0103e75:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103e79:	8b 45 10             	mov    0x10(%ebp),%eax
f0103e7c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103e80:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103e83:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103e87:	8b 45 08             	mov    0x8(%ebp),%eax
f0103e8a:	89 04 24             	mov    %eax,(%esp)
f0103e8d:	e8 82 ff ff ff       	call   f0103e14 <vsnprintf>
	va_end(ap);

	return rc;
}
f0103e92:	c9                   	leave  
f0103e93:	c3                   	ret    
	...

f0103ea0 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0103ea0:	55                   	push   %ebp
f0103ea1:	89 e5                	mov    %esp,%ebp
f0103ea3:	57                   	push   %edi
f0103ea4:	56                   	push   %esi
f0103ea5:	53                   	push   %ebx
f0103ea6:	83 ec 1c             	sub    $0x1c,%esp
f0103ea9:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0103eac:	85 c0                	test   %eax,%eax
f0103eae:	74 10                	je     f0103ec0 <readline+0x20>
		cprintf("%s", prompt);
f0103eb0:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103eb4:	c7 04 24 50 56 10 f0 	movl   $0xf0105650,(%esp)
f0103ebb:	e8 ce f6 ff ff       	call   f010358e <cprintf>

	i = 0;
	echoing = iscons(0);
f0103ec0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0103ec7:	e8 4e c7 ff ff       	call   f010061a <iscons>
f0103ecc:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0103ece:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0103ed3:	e8 31 c7 ff ff       	call   f0100609 <getchar>
f0103ed8:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0103eda:	85 c0                	test   %eax,%eax
f0103edc:	79 17                	jns    f0103ef5 <readline+0x55>
			cprintf("read error: %e\n", c);
f0103ede:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103ee2:	c7 04 24 04 5b 10 f0 	movl   $0xf0105b04,(%esp)
f0103ee9:	e8 a0 f6 ff ff       	call   f010358e <cprintf>
			return NULL;
f0103eee:	b8 00 00 00 00       	mov    $0x0,%eax
f0103ef3:	eb 6d                	jmp    f0103f62 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0103ef5:	83 f8 08             	cmp    $0x8,%eax
f0103ef8:	74 05                	je     f0103eff <readline+0x5f>
f0103efa:	83 f8 7f             	cmp    $0x7f,%eax
f0103efd:	75 19                	jne    f0103f18 <readline+0x78>
f0103eff:	85 f6                	test   %esi,%esi
f0103f01:	7e 15                	jle    f0103f18 <readline+0x78>
			if (echoing)
f0103f03:	85 ff                	test   %edi,%edi
f0103f05:	74 0c                	je     f0103f13 <readline+0x73>
				cputchar('\b');
f0103f07:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f0103f0e:	e8 e6 c6 ff ff       	call   f01005f9 <cputchar>
			i--;
f0103f13:	83 ee 01             	sub    $0x1,%esi
f0103f16:	eb bb                	jmp    f0103ed3 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0103f18:	83 fb 1f             	cmp    $0x1f,%ebx
f0103f1b:	7e 1f                	jle    f0103f3c <readline+0x9c>
f0103f1d:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0103f23:	7f 17                	jg     f0103f3c <readline+0x9c>
			if (echoing)
f0103f25:	85 ff                	test   %edi,%edi
f0103f27:	74 08                	je     f0103f31 <readline+0x91>
				cputchar(c);
f0103f29:	89 1c 24             	mov    %ebx,(%esp)
f0103f2c:	e8 c8 c6 ff ff       	call   f01005f9 <cputchar>
			buf[i++] = c;
f0103f31:	88 9e 80 95 11 f0    	mov    %bl,-0xfee6a80(%esi)
f0103f37:	83 c6 01             	add    $0x1,%esi
f0103f3a:	eb 97                	jmp    f0103ed3 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f0103f3c:	83 fb 0a             	cmp    $0xa,%ebx
f0103f3f:	74 05                	je     f0103f46 <readline+0xa6>
f0103f41:	83 fb 0d             	cmp    $0xd,%ebx
f0103f44:	75 8d                	jne    f0103ed3 <readline+0x33>
			if (echoing)
f0103f46:	85 ff                	test   %edi,%edi
f0103f48:	74 0c                	je     f0103f56 <readline+0xb6>
				cputchar('\n');
f0103f4a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0103f51:	e8 a3 c6 ff ff       	call   f01005f9 <cputchar>
			buf[i] = 0;
f0103f56:	c6 86 80 95 11 f0 00 	movb   $0x0,-0xfee6a80(%esi)
			return buf;
f0103f5d:	b8 80 95 11 f0       	mov    $0xf0119580,%eax
		}
	}
}
f0103f62:	83 c4 1c             	add    $0x1c,%esp
f0103f65:	5b                   	pop    %ebx
f0103f66:	5e                   	pop    %esi
f0103f67:	5f                   	pop    %edi
f0103f68:	5d                   	pop    %ebp
f0103f69:	c3                   	ret    
f0103f6a:	00 00                	add    %al,(%eax)
f0103f6c:	00 00                	add    %al,(%eax)
	...

f0103f70 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0103f70:	55                   	push   %ebp
f0103f71:	89 e5                	mov    %esp,%ebp
f0103f73:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0103f76:	b8 00 00 00 00       	mov    $0x0,%eax
f0103f7b:	80 3a 00             	cmpb   $0x0,(%edx)
f0103f7e:	74 09                	je     f0103f89 <strlen+0x19>
		n++;
f0103f80:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0103f83:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0103f87:	75 f7                	jne    f0103f80 <strlen+0x10>
		n++;
	return n;
}
f0103f89:	5d                   	pop    %ebp
f0103f8a:	c3                   	ret    

f0103f8b <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0103f8b:	55                   	push   %ebp
f0103f8c:	89 e5                	mov    %esp,%ebp
f0103f8e:	53                   	push   %ebx
f0103f8f:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103f92:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103f95:	b8 00 00 00 00       	mov    $0x0,%eax
f0103f9a:	85 c9                	test   %ecx,%ecx
f0103f9c:	74 1a                	je     f0103fb8 <strnlen+0x2d>
f0103f9e:	80 3b 00             	cmpb   $0x0,(%ebx)
f0103fa1:	74 15                	je     f0103fb8 <strnlen+0x2d>
f0103fa3:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
f0103fa8:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103faa:	39 ca                	cmp    %ecx,%edx
f0103fac:	74 0a                	je     f0103fb8 <strnlen+0x2d>
f0103fae:	83 c2 01             	add    $0x1,%edx
f0103fb1:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
f0103fb6:	75 f0                	jne    f0103fa8 <strnlen+0x1d>
		n++;
	return n;
}
f0103fb8:	5b                   	pop    %ebx
f0103fb9:	5d                   	pop    %ebp
f0103fba:	c3                   	ret    

f0103fbb <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0103fbb:	55                   	push   %ebp
f0103fbc:	89 e5                	mov    %esp,%ebp
f0103fbe:	53                   	push   %ebx
f0103fbf:	8b 45 08             	mov    0x8(%ebp),%eax
f0103fc2:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0103fc5:	ba 00 00 00 00       	mov    $0x0,%edx
f0103fca:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f0103fce:	88 0c 10             	mov    %cl,(%eax,%edx,1)
f0103fd1:	83 c2 01             	add    $0x1,%edx
f0103fd4:	84 c9                	test   %cl,%cl
f0103fd6:	75 f2                	jne    f0103fca <strcpy+0xf>
		/* do nothing */;
	return ret;
}
f0103fd8:	5b                   	pop    %ebx
f0103fd9:	5d                   	pop    %ebp
f0103fda:	c3                   	ret    

f0103fdb <strcat>:

char *
strcat(char *dst, const char *src)
{
f0103fdb:	55                   	push   %ebp
f0103fdc:	89 e5                	mov    %esp,%ebp
f0103fde:	53                   	push   %ebx
f0103fdf:	83 ec 08             	sub    $0x8,%esp
f0103fe2:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0103fe5:	89 1c 24             	mov    %ebx,(%esp)
f0103fe8:	e8 83 ff ff ff       	call   f0103f70 <strlen>
	strcpy(dst + len, src);
f0103fed:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103ff0:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103ff4:	01 d8                	add    %ebx,%eax
f0103ff6:	89 04 24             	mov    %eax,(%esp)
f0103ff9:	e8 bd ff ff ff       	call   f0103fbb <strcpy>
	return dst;
}
f0103ffe:	89 d8                	mov    %ebx,%eax
f0104000:	83 c4 08             	add    $0x8,%esp
f0104003:	5b                   	pop    %ebx
f0104004:	5d                   	pop    %ebp
f0104005:	c3                   	ret    

f0104006 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0104006:	55                   	push   %ebp
f0104007:	89 e5                	mov    %esp,%ebp
f0104009:	56                   	push   %esi
f010400a:	53                   	push   %ebx
f010400b:	8b 45 08             	mov    0x8(%ebp),%eax
f010400e:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104011:	8b 75 10             	mov    0x10(%ebp),%esi
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104014:	85 f6                	test   %esi,%esi
f0104016:	74 18                	je     f0104030 <strncpy+0x2a>
f0104018:	b9 00 00 00 00       	mov    $0x0,%ecx
		*dst++ = *src;
f010401d:	0f b6 1a             	movzbl (%edx),%ebx
f0104020:	88 1c 08             	mov    %bl,(%eax,%ecx,1)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0104023:	80 3a 01             	cmpb   $0x1,(%edx)
f0104026:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104029:	83 c1 01             	add    $0x1,%ecx
f010402c:	39 f1                	cmp    %esi,%ecx
f010402e:	75 ed                	jne    f010401d <strncpy+0x17>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0104030:	5b                   	pop    %ebx
f0104031:	5e                   	pop    %esi
f0104032:	5d                   	pop    %ebp
f0104033:	c3                   	ret    

f0104034 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0104034:	55                   	push   %ebp
f0104035:	89 e5                	mov    %esp,%ebp
f0104037:	57                   	push   %edi
f0104038:	56                   	push   %esi
f0104039:	53                   	push   %ebx
f010403a:	8b 7d 08             	mov    0x8(%ebp),%edi
f010403d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104040:	8b 75 10             	mov    0x10(%ebp),%esi
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0104043:	89 f8                	mov    %edi,%eax
f0104045:	85 f6                	test   %esi,%esi
f0104047:	74 2b                	je     f0104074 <strlcpy+0x40>
		while (--size > 0 && *src != '\0')
f0104049:	83 fe 01             	cmp    $0x1,%esi
f010404c:	74 23                	je     f0104071 <strlcpy+0x3d>
f010404e:	0f b6 0b             	movzbl (%ebx),%ecx
f0104051:	84 c9                	test   %cl,%cl
f0104053:	74 1c                	je     f0104071 <strlcpy+0x3d>
	}
	return ret;
}

size_t
strlcpy(char *dst, const char *src, size_t size)
f0104055:	83 ee 02             	sub    $0x2,%esi
f0104058:	ba 00 00 00 00       	mov    $0x0,%edx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f010405d:	88 08                	mov    %cl,(%eax)
f010405f:	83 c0 01             	add    $0x1,%eax
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0104062:	39 f2                	cmp    %esi,%edx
f0104064:	74 0b                	je     f0104071 <strlcpy+0x3d>
f0104066:	83 c2 01             	add    $0x1,%edx
f0104069:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f010406d:	84 c9                	test   %cl,%cl
f010406f:	75 ec                	jne    f010405d <strlcpy+0x29>
			*dst++ = *src++;
		*dst = '\0';
f0104071:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0104074:	29 f8                	sub    %edi,%eax
}
f0104076:	5b                   	pop    %ebx
f0104077:	5e                   	pop    %esi
f0104078:	5f                   	pop    %edi
f0104079:	5d                   	pop    %ebp
f010407a:	c3                   	ret    

f010407b <strcmp>:

int
strcmp(const char *p, const char *q)
{
f010407b:	55                   	push   %ebp
f010407c:	89 e5                	mov    %esp,%ebp
f010407e:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104081:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0104084:	0f b6 01             	movzbl (%ecx),%eax
f0104087:	84 c0                	test   %al,%al
f0104089:	74 16                	je     f01040a1 <strcmp+0x26>
f010408b:	3a 02                	cmp    (%edx),%al
f010408d:	75 12                	jne    f01040a1 <strcmp+0x26>
		p++, q++;
f010408f:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0104092:	0f b6 41 01          	movzbl 0x1(%ecx),%eax
f0104096:	84 c0                	test   %al,%al
f0104098:	74 07                	je     f01040a1 <strcmp+0x26>
f010409a:	83 c1 01             	add    $0x1,%ecx
f010409d:	3a 02                	cmp    (%edx),%al
f010409f:	74 ee                	je     f010408f <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01040a1:	0f b6 c0             	movzbl %al,%eax
f01040a4:	0f b6 12             	movzbl (%edx),%edx
f01040a7:	29 d0                	sub    %edx,%eax
}
f01040a9:	5d                   	pop    %ebp
f01040aa:	c3                   	ret    

f01040ab <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01040ab:	55                   	push   %ebp
f01040ac:	89 e5                	mov    %esp,%ebp
f01040ae:	53                   	push   %ebx
f01040af:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01040b2:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01040b5:	8b 55 10             	mov    0x10(%ebp),%edx
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f01040b8:	b8 00 00 00 00       	mov    $0x0,%eax
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01040bd:	85 d2                	test   %edx,%edx
f01040bf:	74 28                	je     f01040e9 <strncmp+0x3e>
f01040c1:	0f b6 01             	movzbl (%ecx),%eax
f01040c4:	84 c0                	test   %al,%al
f01040c6:	74 24                	je     f01040ec <strncmp+0x41>
f01040c8:	3a 03                	cmp    (%ebx),%al
f01040ca:	75 20                	jne    f01040ec <strncmp+0x41>
f01040cc:	83 ea 01             	sub    $0x1,%edx
f01040cf:	74 13                	je     f01040e4 <strncmp+0x39>
		n--, p++, q++;
f01040d1:	83 c1 01             	add    $0x1,%ecx
f01040d4:	83 c3 01             	add    $0x1,%ebx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01040d7:	0f b6 01             	movzbl (%ecx),%eax
f01040da:	84 c0                	test   %al,%al
f01040dc:	74 0e                	je     f01040ec <strncmp+0x41>
f01040de:	3a 03                	cmp    (%ebx),%al
f01040e0:	74 ea                	je     f01040cc <strncmp+0x21>
f01040e2:	eb 08                	jmp    f01040ec <strncmp+0x41>
		n--, p++, q++;
	if (n == 0)
		return 0;
f01040e4:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01040e9:	5b                   	pop    %ebx
f01040ea:	5d                   	pop    %ebp
f01040eb:	c3                   	ret    
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01040ec:	0f b6 01             	movzbl (%ecx),%eax
f01040ef:	0f b6 13             	movzbl (%ebx),%edx
f01040f2:	29 d0                	sub    %edx,%eax
f01040f4:	eb f3                	jmp    f01040e9 <strncmp+0x3e>

f01040f6 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01040f6:	55                   	push   %ebp
f01040f7:	89 e5                	mov    %esp,%ebp
f01040f9:	8b 45 08             	mov    0x8(%ebp),%eax
f01040fc:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0104100:	0f b6 10             	movzbl (%eax),%edx
f0104103:	84 d2                	test   %dl,%dl
f0104105:	74 1c                	je     f0104123 <strchr+0x2d>
		if (*s == c)
f0104107:	38 ca                	cmp    %cl,%dl
f0104109:	75 09                	jne    f0104114 <strchr+0x1e>
f010410b:	eb 1b                	jmp    f0104128 <strchr+0x32>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f010410d:	83 c0 01             	add    $0x1,%eax
		if (*s == c)
f0104110:	38 ca                	cmp    %cl,%dl
f0104112:	74 14                	je     f0104128 <strchr+0x32>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0104114:	0f b6 50 01          	movzbl 0x1(%eax),%edx
f0104118:	84 d2                	test   %dl,%dl
f010411a:	75 f1                	jne    f010410d <strchr+0x17>
		if (*s == c)
			return (char *) s;
	return 0;
f010411c:	b8 00 00 00 00       	mov    $0x0,%eax
f0104121:	eb 05                	jmp    f0104128 <strchr+0x32>
f0104123:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104128:	5d                   	pop    %ebp
f0104129:	c3                   	ret    

f010412a <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010412a:	55                   	push   %ebp
f010412b:	89 e5                	mov    %esp,%ebp
f010412d:	8b 45 08             	mov    0x8(%ebp),%eax
f0104130:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0104134:	0f b6 10             	movzbl (%eax),%edx
f0104137:	84 d2                	test   %dl,%dl
f0104139:	74 14                	je     f010414f <strfind+0x25>
		if (*s == c)
f010413b:	38 ca                	cmp    %cl,%dl
f010413d:	75 06                	jne    f0104145 <strfind+0x1b>
f010413f:	eb 0e                	jmp    f010414f <strfind+0x25>
f0104141:	38 ca                	cmp    %cl,%dl
f0104143:	74 0a                	je     f010414f <strfind+0x25>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f0104145:	83 c0 01             	add    $0x1,%eax
f0104148:	0f b6 10             	movzbl (%eax),%edx
f010414b:	84 d2                	test   %dl,%dl
f010414d:	75 f2                	jne    f0104141 <strfind+0x17>
		if (*s == c)
			break;
	return (char *) s;
}
f010414f:	5d                   	pop    %ebp
f0104150:	c3                   	ret    

f0104151 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0104151:	55                   	push   %ebp
f0104152:	89 e5                	mov    %esp,%ebp
f0104154:	83 ec 0c             	sub    $0xc,%esp
f0104157:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f010415a:	89 75 f8             	mov    %esi,-0x8(%ebp)
f010415d:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0104160:	8b 7d 08             	mov    0x8(%ebp),%edi
f0104163:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104166:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0104169:	85 c9                	test   %ecx,%ecx
f010416b:	74 30                	je     f010419d <memset+0x4c>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f010416d:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0104173:	75 25                	jne    f010419a <memset+0x49>
f0104175:	f6 c1 03             	test   $0x3,%cl
f0104178:	75 20                	jne    f010419a <memset+0x49>
		c &= 0xFF;
f010417a:	0f b6 d0             	movzbl %al,%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f010417d:	89 d3                	mov    %edx,%ebx
f010417f:	c1 e3 08             	shl    $0x8,%ebx
f0104182:	89 d6                	mov    %edx,%esi
f0104184:	c1 e6 18             	shl    $0x18,%esi
f0104187:	89 d0                	mov    %edx,%eax
f0104189:	c1 e0 10             	shl    $0x10,%eax
f010418c:	09 f0                	or     %esi,%eax
f010418e:	09 d0                	or     %edx,%eax
f0104190:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0104192:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f0104195:	fc                   	cld    
f0104196:	f3 ab                	rep stos %eax,%es:(%edi)
f0104198:	eb 03                	jmp    f010419d <memset+0x4c>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f010419a:	fc                   	cld    
f010419b:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f010419d:	89 f8                	mov    %edi,%eax
f010419f:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f01041a2:	8b 75 f8             	mov    -0x8(%ebp),%esi
f01041a5:	8b 7d fc             	mov    -0x4(%ebp),%edi
f01041a8:	89 ec                	mov    %ebp,%esp
f01041aa:	5d                   	pop    %ebp
f01041ab:	c3                   	ret    

f01041ac <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01041ac:	55                   	push   %ebp
f01041ad:	89 e5                	mov    %esp,%ebp
f01041af:	83 ec 08             	sub    $0x8,%esp
f01041b2:	89 75 f8             	mov    %esi,-0x8(%ebp)
f01041b5:	89 7d fc             	mov    %edi,-0x4(%ebp)
f01041b8:	8b 45 08             	mov    0x8(%ebp),%eax
f01041bb:	8b 75 0c             	mov    0xc(%ebp),%esi
f01041be:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01041c1:	39 c6                	cmp    %eax,%esi
f01041c3:	73 36                	jae    f01041fb <memmove+0x4f>
f01041c5:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01041c8:	39 d0                	cmp    %edx,%eax
f01041ca:	73 2f                	jae    f01041fb <memmove+0x4f>
		s += n;
		d += n;
f01041cc:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01041cf:	f6 c2 03             	test   $0x3,%dl
f01041d2:	75 1b                	jne    f01041ef <memmove+0x43>
f01041d4:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01041da:	75 13                	jne    f01041ef <memmove+0x43>
f01041dc:	f6 c1 03             	test   $0x3,%cl
f01041df:	75 0e                	jne    f01041ef <memmove+0x43>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f01041e1:	83 ef 04             	sub    $0x4,%edi
f01041e4:	8d 72 fc             	lea    -0x4(%edx),%esi
f01041e7:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f01041ea:	fd                   	std    
f01041eb:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01041ed:	eb 09                	jmp    f01041f8 <memmove+0x4c>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f01041ef:	83 ef 01             	sub    $0x1,%edi
f01041f2:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01041f5:	fd                   	std    
f01041f6:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01041f8:	fc                   	cld    
f01041f9:	eb 20                	jmp    f010421b <memmove+0x6f>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01041fb:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0104201:	75 13                	jne    f0104216 <memmove+0x6a>
f0104203:	a8 03                	test   $0x3,%al
f0104205:	75 0f                	jne    f0104216 <memmove+0x6a>
f0104207:	f6 c1 03             	test   $0x3,%cl
f010420a:	75 0a                	jne    f0104216 <memmove+0x6a>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f010420c:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f010420f:	89 c7                	mov    %eax,%edi
f0104211:	fc                   	cld    
f0104212:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0104214:	eb 05                	jmp    f010421b <memmove+0x6f>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0104216:	89 c7                	mov    %eax,%edi
f0104218:	fc                   	cld    
f0104219:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f010421b:	8b 75 f8             	mov    -0x8(%ebp),%esi
f010421e:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0104221:	89 ec                	mov    %ebp,%esp
f0104223:	5d                   	pop    %ebp
f0104224:	c3                   	ret    

f0104225 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0104225:	55                   	push   %ebp
f0104226:	89 e5                	mov    %esp,%ebp
f0104228:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f010422b:	8b 45 10             	mov    0x10(%ebp),%eax
f010422e:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104232:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104235:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104239:	8b 45 08             	mov    0x8(%ebp),%eax
f010423c:	89 04 24             	mov    %eax,(%esp)
f010423f:	e8 68 ff ff ff       	call   f01041ac <memmove>
}
f0104244:	c9                   	leave  
f0104245:	c3                   	ret    

f0104246 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0104246:	55                   	push   %ebp
f0104247:	89 e5                	mov    %esp,%ebp
f0104249:	57                   	push   %edi
f010424a:	56                   	push   %esi
f010424b:	53                   	push   %ebx
f010424c:	8b 5d 08             	mov    0x8(%ebp),%ebx
f010424f:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104252:	8b 7d 10             	mov    0x10(%ebp),%edi
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0104255:	b8 00 00 00 00       	mov    $0x0,%eax
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010425a:	85 ff                	test   %edi,%edi
f010425c:	74 37                	je     f0104295 <memcmp+0x4f>
		if (*s1 != *s2)
f010425e:	0f b6 03             	movzbl (%ebx),%eax
f0104261:	0f b6 0e             	movzbl (%esi),%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0104264:	83 ef 01             	sub    $0x1,%edi
f0104267:	ba 00 00 00 00       	mov    $0x0,%edx
		if (*s1 != *s2)
f010426c:	38 c8                	cmp    %cl,%al
f010426e:	74 1c                	je     f010428c <memcmp+0x46>
f0104270:	eb 10                	jmp    f0104282 <memcmp+0x3c>
f0104272:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
f0104277:	83 c2 01             	add    $0x1,%edx
f010427a:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
f010427e:	38 c8                	cmp    %cl,%al
f0104280:	74 0a                	je     f010428c <memcmp+0x46>
			return (int) *s1 - (int) *s2;
f0104282:	0f b6 c0             	movzbl %al,%eax
f0104285:	0f b6 c9             	movzbl %cl,%ecx
f0104288:	29 c8                	sub    %ecx,%eax
f010428a:	eb 09                	jmp    f0104295 <memcmp+0x4f>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010428c:	39 fa                	cmp    %edi,%edx
f010428e:	75 e2                	jne    f0104272 <memcmp+0x2c>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0104290:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104295:	5b                   	pop    %ebx
f0104296:	5e                   	pop    %esi
f0104297:	5f                   	pop    %edi
f0104298:	5d                   	pop    %ebp
f0104299:	c3                   	ret    

f010429a <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f010429a:	55                   	push   %ebp
f010429b:	89 e5                	mov    %esp,%ebp
f010429d:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f01042a0:	89 c2                	mov    %eax,%edx
f01042a2:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f01042a5:	39 d0                	cmp    %edx,%eax
f01042a7:	73 19                	jae    f01042c2 <memfind+0x28>
		if (*(const unsigned char *) s == (unsigned char) c)
f01042a9:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
f01042ad:	38 08                	cmp    %cl,(%eax)
f01042af:	75 06                	jne    f01042b7 <memfind+0x1d>
f01042b1:	eb 0f                	jmp    f01042c2 <memfind+0x28>
f01042b3:	38 08                	cmp    %cl,(%eax)
f01042b5:	74 0b                	je     f01042c2 <memfind+0x28>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01042b7:	83 c0 01             	add    $0x1,%eax
f01042ba:	39 d0                	cmp    %edx,%eax
f01042bc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01042c0:	75 f1                	jne    f01042b3 <memfind+0x19>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01042c2:	5d                   	pop    %ebp
f01042c3:	c3                   	ret    

f01042c4 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01042c4:	55                   	push   %ebp
f01042c5:	89 e5                	mov    %esp,%ebp
f01042c7:	57                   	push   %edi
f01042c8:	56                   	push   %esi
f01042c9:	53                   	push   %ebx
f01042ca:	8b 55 08             	mov    0x8(%ebp),%edx
f01042cd:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01042d0:	0f b6 02             	movzbl (%edx),%eax
f01042d3:	3c 20                	cmp    $0x20,%al
f01042d5:	74 04                	je     f01042db <strtol+0x17>
f01042d7:	3c 09                	cmp    $0x9,%al
f01042d9:	75 0e                	jne    f01042e9 <strtol+0x25>
		s++;
f01042db:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01042de:	0f b6 02             	movzbl (%edx),%eax
f01042e1:	3c 20                	cmp    $0x20,%al
f01042e3:	74 f6                	je     f01042db <strtol+0x17>
f01042e5:	3c 09                	cmp    $0x9,%al
f01042e7:	74 f2                	je     f01042db <strtol+0x17>
		s++;

	// plus/minus sign
	if (*s == '+')
f01042e9:	3c 2b                	cmp    $0x2b,%al
f01042eb:	75 0a                	jne    f01042f7 <strtol+0x33>
		s++;
f01042ed:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01042f0:	bf 00 00 00 00       	mov    $0x0,%edi
f01042f5:	eb 10                	jmp    f0104307 <strtol+0x43>
f01042f7:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f01042fc:	3c 2d                	cmp    $0x2d,%al
f01042fe:	75 07                	jne    f0104307 <strtol+0x43>
		s++, neg = 1;
f0104300:	83 c2 01             	add    $0x1,%edx
f0104303:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0104307:	85 db                	test   %ebx,%ebx
f0104309:	0f 94 c0             	sete   %al
f010430c:	74 05                	je     f0104313 <strtol+0x4f>
f010430e:	83 fb 10             	cmp    $0x10,%ebx
f0104311:	75 15                	jne    f0104328 <strtol+0x64>
f0104313:	80 3a 30             	cmpb   $0x30,(%edx)
f0104316:	75 10                	jne    f0104328 <strtol+0x64>
f0104318:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f010431c:	75 0a                	jne    f0104328 <strtol+0x64>
		s += 2, base = 16;
f010431e:	83 c2 02             	add    $0x2,%edx
f0104321:	bb 10 00 00 00       	mov    $0x10,%ebx
f0104326:	eb 13                	jmp    f010433b <strtol+0x77>
	else if (base == 0 && s[0] == '0')
f0104328:	84 c0                	test   %al,%al
f010432a:	74 0f                	je     f010433b <strtol+0x77>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f010432c:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0104331:	80 3a 30             	cmpb   $0x30,(%edx)
f0104334:	75 05                	jne    f010433b <strtol+0x77>
		s++, base = 8;
f0104336:	83 c2 01             	add    $0x1,%edx
f0104339:	b3 08                	mov    $0x8,%bl
	else if (base == 0)
		base = 10;
f010433b:	b8 00 00 00 00       	mov    $0x0,%eax
f0104340:	89 de                	mov    %ebx,%esi

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0104342:	0f b6 0a             	movzbl (%edx),%ecx
f0104345:	8d 59 d0             	lea    -0x30(%ecx),%ebx
f0104348:	80 fb 09             	cmp    $0x9,%bl
f010434b:	77 08                	ja     f0104355 <strtol+0x91>
			dig = *s - '0';
f010434d:	0f be c9             	movsbl %cl,%ecx
f0104350:	83 e9 30             	sub    $0x30,%ecx
f0104353:	eb 1e                	jmp    f0104373 <strtol+0xaf>
		else if (*s >= 'a' && *s <= 'z')
f0104355:	8d 59 9f             	lea    -0x61(%ecx),%ebx
f0104358:	80 fb 19             	cmp    $0x19,%bl
f010435b:	77 08                	ja     f0104365 <strtol+0xa1>
			dig = *s - 'a' + 10;
f010435d:	0f be c9             	movsbl %cl,%ecx
f0104360:	83 e9 57             	sub    $0x57,%ecx
f0104363:	eb 0e                	jmp    f0104373 <strtol+0xaf>
		else if (*s >= 'A' && *s <= 'Z')
f0104365:	8d 59 bf             	lea    -0x41(%ecx),%ebx
f0104368:	80 fb 19             	cmp    $0x19,%bl
f010436b:	77 14                	ja     f0104381 <strtol+0xbd>
			dig = *s - 'A' + 10;
f010436d:	0f be c9             	movsbl %cl,%ecx
f0104370:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0104373:	39 f1                	cmp    %esi,%ecx
f0104375:	7d 0e                	jge    f0104385 <strtol+0xc1>
			break;
		s++, val = (val * base) + dig;
f0104377:	83 c2 01             	add    $0x1,%edx
f010437a:	0f af c6             	imul   %esi,%eax
f010437d:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
f010437f:	eb c1                	jmp    f0104342 <strtol+0x7e>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
f0104381:	89 c1                	mov    %eax,%ecx
f0104383:	eb 02                	jmp    f0104387 <strtol+0xc3>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0104385:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
f0104387:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f010438b:	74 05                	je     f0104392 <strtol+0xce>
		*endptr = (char *) s;
f010438d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104390:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
f0104392:	89 ca                	mov    %ecx,%edx
f0104394:	f7 da                	neg    %edx
f0104396:	85 ff                	test   %edi,%edi
f0104398:	0f 45 c2             	cmovne %edx,%eax
}
f010439b:	5b                   	pop    %ebx
f010439c:	5e                   	pop    %esi
f010439d:	5f                   	pop    %edi
f010439e:	5d                   	pop    %ebp
f010439f:	c3                   	ret    

f01043a0 <__udivdi3>:
f01043a0:	83 ec 1c             	sub    $0x1c,%esp
f01043a3:	89 7c 24 14          	mov    %edi,0x14(%esp)
f01043a7:	8b 7c 24 2c          	mov    0x2c(%esp),%edi
f01043ab:	8b 44 24 20          	mov    0x20(%esp),%eax
f01043af:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f01043b3:	89 74 24 10          	mov    %esi,0x10(%esp)
f01043b7:	8b 74 24 24          	mov    0x24(%esp),%esi
f01043bb:	85 ff                	test   %edi,%edi
f01043bd:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f01043c1:	89 44 24 08          	mov    %eax,0x8(%esp)
f01043c5:	89 cd                	mov    %ecx,%ebp
f01043c7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01043cb:	75 33                	jne    f0104400 <__udivdi3+0x60>
f01043cd:	39 f1                	cmp    %esi,%ecx
f01043cf:	77 57                	ja     f0104428 <__udivdi3+0x88>
f01043d1:	85 c9                	test   %ecx,%ecx
f01043d3:	75 0b                	jne    f01043e0 <__udivdi3+0x40>
f01043d5:	b8 01 00 00 00       	mov    $0x1,%eax
f01043da:	31 d2                	xor    %edx,%edx
f01043dc:	f7 f1                	div    %ecx
f01043de:	89 c1                	mov    %eax,%ecx
f01043e0:	89 f0                	mov    %esi,%eax
f01043e2:	31 d2                	xor    %edx,%edx
f01043e4:	f7 f1                	div    %ecx
f01043e6:	89 c6                	mov    %eax,%esi
f01043e8:	8b 44 24 04          	mov    0x4(%esp),%eax
f01043ec:	f7 f1                	div    %ecx
f01043ee:	89 f2                	mov    %esi,%edx
f01043f0:	8b 74 24 10          	mov    0x10(%esp),%esi
f01043f4:	8b 7c 24 14          	mov    0x14(%esp),%edi
f01043f8:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f01043fc:	83 c4 1c             	add    $0x1c,%esp
f01043ff:	c3                   	ret    
f0104400:	31 d2                	xor    %edx,%edx
f0104402:	31 c0                	xor    %eax,%eax
f0104404:	39 f7                	cmp    %esi,%edi
f0104406:	77 e8                	ja     f01043f0 <__udivdi3+0x50>
f0104408:	0f bd cf             	bsr    %edi,%ecx
f010440b:	83 f1 1f             	xor    $0x1f,%ecx
f010440e:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0104412:	75 2c                	jne    f0104440 <__udivdi3+0xa0>
f0104414:	3b 6c 24 08          	cmp    0x8(%esp),%ebp
f0104418:	76 04                	jbe    f010441e <__udivdi3+0x7e>
f010441a:	39 f7                	cmp    %esi,%edi
f010441c:	73 d2                	jae    f01043f0 <__udivdi3+0x50>
f010441e:	31 d2                	xor    %edx,%edx
f0104420:	b8 01 00 00 00       	mov    $0x1,%eax
f0104425:	eb c9                	jmp    f01043f0 <__udivdi3+0x50>
f0104427:	90                   	nop
f0104428:	89 f2                	mov    %esi,%edx
f010442a:	f7 f1                	div    %ecx
f010442c:	31 d2                	xor    %edx,%edx
f010442e:	8b 74 24 10          	mov    0x10(%esp),%esi
f0104432:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0104436:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f010443a:	83 c4 1c             	add    $0x1c,%esp
f010443d:	c3                   	ret    
f010443e:	66 90                	xchg   %ax,%ax
f0104440:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0104445:	b8 20 00 00 00       	mov    $0x20,%eax
f010444a:	89 ea                	mov    %ebp,%edx
f010444c:	2b 44 24 04          	sub    0x4(%esp),%eax
f0104450:	d3 e7                	shl    %cl,%edi
f0104452:	89 c1                	mov    %eax,%ecx
f0104454:	d3 ea                	shr    %cl,%edx
f0104456:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f010445b:	09 fa                	or     %edi,%edx
f010445d:	89 f7                	mov    %esi,%edi
f010445f:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0104463:	89 f2                	mov    %esi,%edx
f0104465:	8b 74 24 08          	mov    0x8(%esp),%esi
f0104469:	d3 e5                	shl    %cl,%ebp
f010446b:	89 c1                	mov    %eax,%ecx
f010446d:	d3 ef                	shr    %cl,%edi
f010446f:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0104474:	d3 e2                	shl    %cl,%edx
f0104476:	89 c1                	mov    %eax,%ecx
f0104478:	d3 ee                	shr    %cl,%esi
f010447a:	09 d6                	or     %edx,%esi
f010447c:	89 fa                	mov    %edi,%edx
f010447e:	89 f0                	mov    %esi,%eax
f0104480:	f7 74 24 0c          	divl   0xc(%esp)
f0104484:	89 d7                	mov    %edx,%edi
f0104486:	89 c6                	mov    %eax,%esi
f0104488:	f7 e5                	mul    %ebp
f010448a:	39 d7                	cmp    %edx,%edi
f010448c:	72 22                	jb     f01044b0 <__udivdi3+0x110>
f010448e:	8b 6c 24 08          	mov    0x8(%esp),%ebp
f0104492:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0104497:	d3 e5                	shl    %cl,%ebp
f0104499:	39 c5                	cmp    %eax,%ebp
f010449b:	73 04                	jae    f01044a1 <__udivdi3+0x101>
f010449d:	39 d7                	cmp    %edx,%edi
f010449f:	74 0f                	je     f01044b0 <__udivdi3+0x110>
f01044a1:	89 f0                	mov    %esi,%eax
f01044a3:	31 d2                	xor    %edx,%edx
f01044a5:	e9 46 ff ff ff       	jmp    f01043f0 <__udivdi3+0x50>
f01044aa:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01044b0:	8d 46 ff             	lea    -0x1(%esi),%eax
f01044b3:	31 d2                	xor    %edx,%edx
f01044b5:	8b 74 24 10          	mov    0x10(%esp),%esi
f01044b9:	8b 7c 24 14          	mov    0x14(%esp),%edi
f01044bd:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f01044c1:	83 c4 1c             	add    $0x1c,%esp
f01044c4:	c3                   	ret    
	...

f01044d0 <__umoddi3>:
f01044d0:	83 ec 1c             	sub    $0x1c,%esp
f01044d3:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f01044d7:	8b 6c 24 2c          	mov    0x2c(%esp),%ebp
f01044db:	8b 44 24 20          	mov    0x20(%esp),%eax
f01044df:	89 74 24 10          	mov    %esi,0x10(%esp)
f01044e3:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f01044e7:	8b 74 24 24          	mov    0x24(%esp),%esi
f01044eb:	85 ed                	test   %ebp,%ebp
f01044ed:	89 7c 24 14          	mov    %edi,0x14(%esp)
f01044f1:	89 44 24 08          	mov    %eax,0x8(%esp)
f01044f5:	89 cf                	mov    %ecx,%edi
f01044f7:	89 04 24             	mov    %eax,(%esp)
f01044fa:	89 f2                	mov    %esi,%edx
f01044fc:	75 1a                	jne    f0104518 <__umoddi3+0x48>
f01044fe:	39 f1                	cmp    %esi,%ecx
f0104500:	76 4e                	jbe    f0104550 <__umoddi3+0x80>
f0104502:	f7 f1                	div    %ecx
f0104504:	89 d0                	mov    %edx,%eax
f0104506:	31 d2                	xor    %edx,%edx
f0104508:	8b 74 24 10          	mov    0x10(%esp),%esi
f010450c:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0104510:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0104514:	83 c4 1c             	add    $0x1c,%esp
f0104517:	c3                   	ret    
f0104518:	39 f5                	cmp    %esi,%ebp
f010451a:	77 54                	ja     f0104570 <__umoddi3+0xa0>
f010451c:	0f bd c5             	bsr    %ebp,%eax
f010451f:	83 f0 1f             	xor    $0x1f,%eax
f0104522:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104526:	75 60                	jne    f0104588 <__umoddi3+0xb8>
f0104528:	3b 0c 24             	cmp    (%esp),%ecx
f010452b:	0f 87 07 01 00 00    	ja     f0104638 <__umoddi3+0x168>
f0104531:	89 f2                	mov    %esi,%edx
f0104533:	8b 34 24             	mov    (%esp),%esi
f0104536:	29 ce                	sub    %ecx,%esi
f0104538:	19 ea                	sbb    %ebp,%edx
f010453a:	89 34 24             	mov    %esi,(%esp)
f010453d:	8b 04 24             	mov    (%esp),%eax
f0104540:	8b 74 24 10          	mov    0x10(%esp),%esi
f0104544:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0104548:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f010454c:	83 c4 1c             	add    $0x1c,%esp
f010454f:	c3                   	ret    
f0104550:	85 c9                	test   %ecx,%ecx
f0104552:	75 0b                	jne    f010455f <__umoddi3+0x8f>
f0104554:	b8 01 00 00 00       	mov    $0x1,%eax
f0104559:	31 d2                	xor    %edx,%edx
f010455b:	f7 f1                	div    %ecx
f010455d:	89 c1                	mov    %eax,%ecx
f010455f:	89 f0                	mov    %esi,%eax
f0104561:	31 d2                	xor    %edx,%edx
f0104563:	f7 f1                	div    %ecx
f0104565:	8b 04 24             	mov    (%esp),%eax
f0104568:	f7 f1                	div    %ecx
f010456a:	eb 98                	jmp    f0104504 <__umoddi3+0x34>
f010456c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104570:	89 f2                	mov    %esi,%edx
f0104572:	8b 74 24 10          	mov    0x10(%esp),%esi
f0104576:	8b 7c 24 14          	mov    0x14(%esp),%edi
f010457a:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f010457e:	83 c4 1c             	add    $0x1c,%esp
f0104581:	c3                   	ret    
f0104582:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0104588:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f010458d:	89 e8                	mov    %ebp,%eax
f010458f:	bd 20 00 00 00       	mov    $0x20,%ebp
f0104594:	2b 6c 24 04          	sub    0x4(%esp),%ebp
f0104598:	89 fa                	mov    %edi,%edx
f010459a:	d3 e0                	shl    %cl,%eax
f010459c:	89 e9                	mov    %ebp,%ecx
f010459e:	d3 ea                	shr    %cl,%edx
f01045a0:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f01045a5:	09 c2                	or     %eax,%edx
f01045a7:	8b 44 24 08          	mov    0x8(%esp),%eax
f01045ab:	89 14 24             	mov    %edx,(%esp)
f01045ae:	89 f2                	mov    %esi,%edx
f01045b0:	d3 e7                	shl    %cl,%edi
f01045b2:	89 e9                	mov    %ebp,%ecx
f01045b4:	d3 ea                	shr    %cl,%edx
f01045b6:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f01045bb:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01045bf:	d3 e6                	shl    %cl,%esi
f01045c1:	89 e9                	mov    %ebp,%ecx
f01045c3:	d3 e8                	shr    %cl,%eax
f01045c5:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f01045ca:	09 f0                	or     %esi,%eax
f01045cc:	8b 74 24 08          	mov    0x8(%esp),%esi
f01045d0:	f7 34 24             	divl   (%esp)
f01045d3:	d3 e6                	shl    %cl,%esi
f01045d5:	89 74 24 08          	mov    %esi,0x8(%esp)
f01045d9:	89 d6                	mov    %edx,%esi
f01045db:	f7 e7                	mul    %edi
f01045dd:	39 d6                	cmp    %edx,%esi
f01045df:	89 c1                	mov    %eax,%ecx
f01045e1:	89 d7                	mov    %edx,%edi
f01045e3:	72 3f                	jb     f0104624 <__umoddi3+0x154>
f01045e5:	39 44 24 08          	cmp    %eax,0x8(%esp)
f01045e9:	72 35                	jb     f0104620 <__umoddi3+0x150>
f01045eb:	8b 44 24 08          	mov    0x8(%esp),%eax
f01045ef:	29 c8                	sub    %ecx,%eax
f01045f1:	19 fe                	sbb    %edi,%esi
f01045f3:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f01045f8:	89 f2                	mov    %esi,%edx
f01045fa:	d3 e8                	shr    %cl,%eax
f01045fc:	89 e9                	mov    %ebp,%ecx
f01045fe:	d3 e2                	shl    %cl,%edx
f0104600:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0104605:	09 d0                	or     %edx,%eax
f0104607:	89 f2                	mov    %esi,%edx
f0104609:	d3 ea                	shr    %cl,%edx
f010460b:	8b 74 24 10          	mov    0x10(%esp),%esi
f010460f:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0104613:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0104617:	83 c4 1c             	add    $0x1c,%esp
f010461a:	c3                   	ret    
f010461b:	90                   	nop
f010461c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104620:	39 d6                	cmp    %edx,%esi
f0104622:	75 c7                	jne    f01045eb <__umoddi3+0x11b>
f0104624:	89 d7                	mov    %edx,%edi
f0104626:	89 c1                	mov    %eax,%ecx
f0104628:	2b 4c 24 0c          	sub    0xc(%esp),%ecx
f010462c:	1b 3c 24             	sbb    (%esp),%edi
f010462f:	eb ba                	jmp    f01045eb <__umoddi3+0x11b>
f0104631:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104638:	39 f5                	cmp    %esi,%ebp
f010463a:	0f 82 f1 fe ff ff    	jb     f0104531 <__umoddi3+0x61>
f0104640:	e9 f8 fe ff ff       	jmp    f010453d <__umoddi3+0x6d>
