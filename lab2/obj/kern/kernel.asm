
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
f0100063:	e8 59 3f 00 00       	call   f0103fc1 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100068:	e8 97 04 00 00       	call   f0100504 <cons_init>
	cprintf("6828 decimal is %o octal!\n", 6828);
f010006d:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f0100074:	00 
f0100075:	c7 04 24 c0 44 10 f0 	movl   $0xf01044c0,(%esp)
f010007c:	e8 7d 33 00 00       	call   f01033fe <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100081:	e8 97 17 00 00       	call   f010181d <mem_init>
	// Test the stack backtrace function (lab 1 only)
//>>>>>>> lab1

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f0100086:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010008d:	e8 a6 0d 00 00       	call   f0100e38 <monitor>
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
f01000c1:	c7 04 24 db 44 10 f0 	movl   $0xf01044db,(%esp)
f01000c8:	e8 31 33 00 00       	call   f01033fe <cprintf>
	vcprintf(fmt, ap);
f01000cd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01000d1:	89 34 24             	mov    %esi,(%esp)
f01000d4:	e8 f2 32 00 00       	call   f01033cb <vcprintf>
	cprintf("\n");
f01000d9:	c7 04 24 04 56 10 f0 	movl   $0xf0105604,(%esp)
f01000e0:	e8 19 33 00 00       	call   f01033fe <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000e5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000ec:	e8 47 0d 00 00       	call   f0100e38 <monitor>
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
f010010b:	c7 04 24 f3 44 10 f0 	movl   $0xf01044f3,(%esp)
f0100112:	e8 e7 32 00 00       	call   f01033fe <cprintf>
	vcprintf(fmt, ap);
f0100117:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010011b:	8b 45 10             	mov    0x10(%ebp),%eax
f010011e:	89 04 24             	mov    %eax,(%esp)
f0100121:	e8 a5 32 00 00       	call   f01033cb <vcprintf>
	cprintf("\n");
f0100126:	c7 04 24 04 56 10 f0 	movl   $0xf0105604,(%esp)
f010012d:	e8 cc 32 00 00       	call   f01033fe <cprintf>
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
f010031b:	e8 fc 3c 00 00       	call   f010401c <memmove>
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
f01003c7:	0f b6 82 40 45 10 f0 	movzbl -0xfefbac0(%edx),%eax
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
f0100404:	0f b6 82 40 45 10 f0 	movzbl -0xfefbac0(%edx),%eax
f010040b:	0b 05 48 95 11 f0    	or     0xf0119548,%eax
	shift ^= togglecode[data];
f0100411:	0f b6 8a 40 46 10 f0 	movzbl -0xfefb9c0(%edx),%ecx
f0100418:	31 c8                	xor    %ecx,%eax
f010041a:	a3 48 95 11 f0       	mov    %eax,0xf0119548

	c = charcode[shift & (CTL | SHIFT)][data];
f010041f:	89 c1                	mov    %eax,%ecx
f0100421:	83 e1 03             	and    $0x3,%ecx
f0100424:	8b 0c 8d 40 47 10 f0 	mov    -0xfefb8c0(,%ecx,4),%ecx
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
f010045a:	c7 04 24 0d 45 10 f0 	movl   $0xf010450d,(%esp)
f0100461:	e8 98 2f 00 00       	call   f01033fe <cprintf>
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
f01005e5:	c7 04 24 19 45 10 f0 	movl   $0xf0104519,(%esp)
f01005ec:	e8 0d 2e 00 00       	call   f01033fe <cprintf>
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
f0100636:	c7 04 24 50 47 10 f0 	movl   $0xf0104750,(%esp)
f010063d:	e8 bc 2d 00 00       	call   f01033fe <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100642:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f0100649:	00 
f010064a:	c7 04 24 28 49 10 f0 	movl   $0xf0104928,(%esp)
f0100651:	e8 a8 2d 00 00       	call   f01033fe <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100656:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f010065d:	00 
f010065e:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f0100665:	f0 
f0100666:	c7 04 24 50 49 10 f0 	movl   $0xf0104950,(%esp)
f010066d:	e8 8c 2d 00 00       	call   f01033fe <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100672:	c7 44 24 08 b5 44 10 	movl   $0x1044b5,0x8(%esp)
f0100679:	00 
f010067a:	c7 44 24 04 b5 44 10 	movl   $0xf01044b5,0x4(%esp)
f0100681:	f0 
f0100682:	c7 04 24 74 49 10 f0 	movl   $0xf0104974,(%esp)
f0100689:	e8 70 2d 00 00       	call   f01033fe <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010068e:	c7 44 24 08 20 93 11 	movl   $0x119320,0x8(%esp)
f0100695:	00 
f0100696:	c7 44 24 04 20 93 11 	movl   $0xf0119320,0x4(%esp)
f010069d:	f0 
f010069e:	c7 04 24 98 49 10 f0 	movl   $0xf0104998,(%esp)
f01006a5:	e8 54 2d 00 00       	call   f01033fe <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006aa:	c7 44 24 08 90 99 11 	movl   $0x119990,0x8(%esp)
f01006b1:	00 
f01006b2:	c7 44 24 04 90 99 11 	movl   $0xf0119990,0x4(%esp)
f01006b9:	f0 
f01006ba:	c7 04 24 bc 49 10 f0 	movl   $0xf01049bc,(%esp)
f01006c1:	e8 38 2d 00 00       	call   f01033fe <cprintf>
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
f01006e7:	c7 04 24 e0 49 10 f0 	movl   $0xf01049e0,(%esp)
f01006ee:	e8 0b 2d 00 00       	call   f01033fe <cprintf>
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
f0100706:	8b 83 24 4c 10 f0    	mov    -0xfefb3dc(%ebx),%eax
f010070c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100710:	8b 83 20 4c 10 f0    	mov    -0xfefb3e0(%ebx),%eax
f0100716:	89 44 24 04          	mov    %eax,0x4(%esp)
f010071a:	c7 04 24 69 47 10 f0 	movl   $0xf0104769,(%esp)
f0100721:	e8 d8 2c 00 00       	call   f01033fe <cprintf>
f0100726:	83 c3 0c             	add    $0xc,%ebx
int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
	int i;

	for (i = 0; i < NCOMMANDS; i++)
f0100729:	83 fb 48             	cmp    $0x48,%ebx
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
f0100749:	c7 04 24 72 47 10 f0 	movl   $0xf0104772,(%esp)
f0100750:	e8 a9 2c 00 00       	call   f01033fe <cprintf>
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
f0100788:	c7 04 24 0c 4a 10 f0 	movl   $0xf0104a0c,(%esp)
f010078f:	e8 6a 2c 00 00       	call   f01033fe <cprintf>
		struct Eipdebuginfo temp_debuginfo;
		debuginfo_eip((uintptr_t) eip, &temp_debuginfo);		
f0100794:	8d 45 d0             	lea    -0x30(%ebp),%eax
f0100797:	89 44 24 04          	mov    %eax,0x4(%esp)
f010079b:	89 3c 24             	mov    %edi,(%esp)
f010079e:	e8 55 2d 00 00       	call   f01034f8 <debuginfo_eip>
		cprintf("       %s:%d: ", temp_debuginfo.eip_file, temp_debuginfo.eip_line);
f01007a3:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01007a6:	89 44 24 08          	mov    %eax,0x8(%esp)
f01007aa:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01007ad:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007b1:	c7 04 24 83 47 10 f0 	movl   $0xf0104783,(%esp)
f01007b8:	e8 41 2c 00 00       	call   f01033fe <cprintf>
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
f01007d3:	c7 04 24 92 47 10 f0 	movl   $0xf0104792,(%esp)
f01007da:	e8 1f 2c 00 00       	call   f01033fe <cprintf>
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
f01007ee:	c7 04 24 95 47 10 f0 	movl   $0xf0104795,(%esp)
f01007f5:	e8 04 2c 00 00       	call   f01033fe <cprintf>
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
f0100826:	c7 44 24 04 9a 47 10 	movl   $0xf010479a,0x4(%esp)
f010082d:	f0 
f010082e:	8b 46 08             	mov    0x8(%esi),%eax
f0100831:	89 04 24             	mov    %eax,(%esp)
f0100834:	e8 b2 36 00 00       	call   f0103eeb <strcmp>
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
f0100846:	c7 44 24 04 9e 47 10 	movl   $0xf010479e,0x4(%esp)
f010084d:	f0 
f010084e:	8b 46 08             	mov    0x8(%esi),%eax
f0100851:	89 04 24             	mov    %eax,(%esp)
f0100854:	e8 92 36 00 00       	call   f0103eeb <strcmp>
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
f0100866:	c7 44 24 04 a2 47 10 	movl   $0xf01047a2,0x4(%esp)
f010086d:	f0 
f010086e:	8b 46 08             	mov    0x8(%esi),%eax
f0100871:	89 04 24             	mov    %eax,(%esp)
f0100874:	e8 72 36 00 00       	call   f0103eeb <strcmp>
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
f0100886:	c7 44 24 04 a6 47 10 	movl   $0xf01047a6,0x4(%esp)
f010088d:	f0 
f010088e:	8b 46 08             	mov    0x8(%esi),%eax
f0100891:	89 04 24             	mov    %eax,(%esp)
f0100894:	e8 52 36 00 00       	call   f0103eeb <strcmp>
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
f01008a6:	c7 44 24 04 aa 47 10 	movl   $0xf01047aa,0x4(%esp)
f01008ad:	f0 
f01008ae:	8b 46 08             	mov    0x8(%esi),%eax
f01008b1:	89 04 24             	mov    %eax,(%esp)
f01008b4:	e8 32 36 00 00       	call   f0103eeb <strcmp>
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
f01008c6:	c7 44 24 04 ae 47 10 	movl   $0xf01047ae,0x4(%esp)
f01008cd:	f0 
f01008ce:	8b 46 08             	mov    0x8(%esi),%eax
f01008d1:	89 04 24             	mov    %eax,(%esp)
f01008d4:	e8 12 36 00 00       	call   f0103eeb <strcmp>
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
f01008e2:	c7 44 24 04 b2 47 10 	movl   $0xf01047b2,0x4(%esp)
f01008e9:	f0 
f01008ea:	8b 46 08             	mov    0x8(%esi),%eax
f01008ed:	89 04 24             	mov    %eax,(%esp)
f01008f0:	e8 f6 35 00 00       	call   f0103eeb <strcmp>
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
f01008fe:	c7 44 24 04 b6 47 10 	movl   $0xf01047b6,0x4(%esp)
f0100905:	f0 
f0100906:	8b 46 08             	mov    0x8(%esi),%eax
f0100909:	89 04 24             	mov    %eax,(%esp)
f010090c:	e8 da 35 00 00       	call   f0103eeb <strcmp>
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
f010091a:	c7 44 24 04 ba 47 10 	movl   $0xf01047ba,0x4(%esp)
f0100921:	f0 
f0100922:	8b 46 08             	mov    0x8(%esi),%eax
f0100925:	89 04 24             	mov    %eax,(%esp)
f0100928:	e8 be 35 00 00       	call   f0103eeb <strcmp>
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
f0100936:	c7 44 24 04 be 47 10 	movl   $0xf01047be,0x4(%esp)
f010093d:	f0 
f010093e:	8b 46 08             	mov    0x8(%esi),%eax
f0100941:	89 04 24             	mov    %eax,(%esp)
f0100944:	e8 a2 35 00 00       	call   f0103eeb <strcmp>
			ch_color1=COLOR_CYN
f0100949:	83 f8 01             	cmp    $0x1,%eax
f010094c:	19 ff                	sbb    %edi,%edi
f010094e:	83 e7 04             	and    $0x4,%edi
f0100951:	83 c7 07             	add    $0x7,%edi
	else ch_color1=COLOR_WHT;
	if(strcmp(argv[1],"blk")==0)
f0100954:	c7 44 24 04 9a 47 10 	movl   $0xf010479a,0x4(%esp)
f010095b:	f0 
f010095c:	8b 46 04             	mov    0x4(%esi),%eax
f010095f:	89 04 24             	mov    %eax,(%esp)
f0100962:	e8 84 35 00 00       	call   f0103eeb <strcmp>
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
f0100974:	c7 44 24 04 9e 47 10 	movl   $0xf010479e,0x4(%esp)
f010097b:	f0 
f010097c:	8b 46 04             	mov    0x4(%esi),%eax
f010097f:	89 04 24             	mov    %eax,(%esp)
f0100982:	e8 64 35 00 00       	call   f0103eeb <strcmp>
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
f0100991:	c7 44 24 04 a2 47 10 	movl   $0xf01047a2,0x4(%esp)
f0100998:	f0 
f0100999:	8b 46 04             	mov    0x4(%esi),%eax
f010099c:	89 04 24             	mov    %eax,(%esp)
f010099f:	e8 47 35 00 00       	call   f0103eeb <strcmp>
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
f01009ae:	c7 44 24 04 a6 47 10 	movl   $0xf01047a6,0x4(%esp)
f01009b5:	f0 
f01009b6:	8b 46 04             	mov    0x4(%esi),%eax
f01009b9:	89 04 24             	mov    %eax,(%esp)
f01009bc:	e8 2a 35 00 00       	call   f0103eeb <strcmp>
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
f01009cb:	c7 44 24 04 aa 47 10 	movl   $0xf01047aa,0x4(%esp)
f01009d2:	f0 
f01009d3:	8b 46 04             	mov    0x4(%esi),%eax
f01009d6:	89 04 24             	mov    %eax,(%esp)
f01009d9:	e8 0d 35 00 00       	call   f0103eeb <strcmp>
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
f01009e8:	c7 44 24 04 ae 47 10 	movl   $0xf01047ae,0x4(%esp)
f01009ef:	f0 
f01009f0:	8b 46 04             	mov    0x4(%esi),%eax
f01009f3:	89 04 24             	mov    %eax,(%esp)
f01009f6:	e8 f0 34 00 00       	call   f0103eeb <strcmp>
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
f0100a01:	c7 44 24 04 b2 47 10 	movl   $0xf01047b2,0x4(%esp)
f0100a08:	f0 
f0100a09:	8b 46 04             	mov    0x4(%esi),%eax
f0100a0c:	89 04 24             	mov    %eax,(%esp)
f0100a0f:	e8 d7 34 00 00       	call   f0103eeb <strcmp>
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
f0100a1a:	c7 44 24 04 b6 47 10 	movl   $0xf01047b6,0x4(%esp)
f0100a21:	f0 
f0100a22:	8b 46 04             	mov    0x4(%esi),%eax
f0100a25:	89 04 24             	mov    %eax,(%esp)
f0100a28:	e8 be 34 00 00       	call   f0103eeb <strcmp>
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
f0100a33:	c7 44 24 04 ba 47 10 	movl   $0xf01047ba,0x4(%esp)
f0100a3a:	f0 
f0100a3b:	8b 46 04             	mov    0x4(%esi),%eax
f0100a3e:	89 04 24             	mov    %eax,(%esp)
f0100a41:	e8 a5 34 00 00       	call   f0103eeb <strcmp>
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
f0100a4c:	c7 44 24 04 be 47 10 	movl   $0xf01047be,0x4(%esp)
f0100a53:	f0 
f0100a54:	8b 46 04             	mov    0x4(%esi),%eax
f0100a57:	89 04 24             	mov    %eax,(%esp)
f0100a5a:	e8 8c 34 00 00       	call   f0103eeb <strcmp>
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
f0100a84:	c7 04 24 40 4a 10 f0 	movl   $0xf0104a40,(%esp)
f0100a8b:	e8 6e 29 00 00       	call   f01033fe <cprintf>
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
f0100ab9:	c7 04 24 c2 47 10 f0 	movl   $0xf01047c2,(%esp)
f0100ac0:	e8 39 29 00 00       	call   f01033fe <cprintf>
	cprintf("PTE_W : %d ", ((now & PTE_W) != 0));
f0100ac5:	f6 c3 02             	test   $0x2,%bl
f0100ac8:	0f 95 c0             	setne  %al
f0100acb:	0f b6 c0             	movzbl %al,%eax
f0100ace:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100ad2:	c7 04 24 ce 47 10 f0 	movl   $0xf01047ce,(%esp)
f0100ad9:	e8 20 29 00 00       	call   f01033fe <cprintf>
	cprintf("PTE_P : %d ", ((now & PTE_P) != 0));
f0100ade:	83 e3 01             	and    $0x1,%ebx
f0100ae1:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100ae5:	c7 04 24 da 47 10 f0 	movl   $0xf01047da,(%esp)
f0100aec:	e8 0d 29 00 00       	call   f01033fe <cprintf>
}
f0100af1:	83 c4 14             	add    $0x14,%esp
f0100af4:	5b                   	pop    %ebx
f0100af5:	5d                   	pop    %ebp
f0100af6:	c3                   	ret    

f0100af7 <xtoi>:

uint32_t xtoi(char* origin, bool* check) {
f0100af7:	55                   	push   %ebp
f0100af8:	89 e5                	mov    %esp,%ebp
f0100afa:	83 ec 28             	sub    $0x28,%esp
f0100afd:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0100b00:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0100b03:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0100b06:	8b 5d 08             	mov    0x8(%ebp),%ebx
	uint32_t i = 0, temp = 0, len = strlen(origin);
f0100b09:	89 1c 24             	mov    %ebx,(%esp)
f0100b0c:	e8 cf 32 00 00       	call   f0103de0 <strlen>
	*check = true;
f0100b11:	8b 55 0c             	mov    0xc(%ebp),%edx
f0100b14:	c6 02 01             	movb   $0x1,(%edx)
	if ((origin[0] != '0') || (origin[1] != 'x' && origin[1] != 'X')) 
	{
		check = false;
		return -1;
f0100b17:	ba ff ff ff ff       	mov    $0xffffffff,%edx
}

uint32_t xtoi(char* origin, bool* check) {
	uint32_t i = 0, temp = 0, len = strlen(origin);
	*check = true;
	if ((origin[0] != '0') || (origin[1] != 'x' && origin[1] != 'X')) 
f0100b1c:	80 3b 30             	cmpb   $0x30,(%ebx)
f0100b1f:	75 67                	jne    f0100b88 <xtoi+0x91>
f0100b21:	0f b6 4b 01          	movzbl 0x1(%ebx),%ecx
f0100b25:	80 f9 78             	cmp    $0x78,%cl
f0100b28:	74 05                	je     f0100b2f <xtoi+0x38>
f0100b2a:	80 f9 58             	cmp    $0x58,%cl
f0100b2d:	75 59                	jne    f0100b88 <xtoi+0x91>
	cprintf("PTE_W : %d ", ((now & PTE_W) != 0));
	cprintf("PTE_P : %d ", ((now & PTE_P) != 0));
}

uint32_t xtoi(char* origin, bool* check) {
	uint32_t i = 0, temp = 0, len = strlen(origin);
f0100b2f:	89 c6                	mov    %eax,%esi
	if ((origin[0] != '0') || (origin[1] != 'x' && origin[1] != 'X')) 
	{
		check = false;
		return -1;
	}
	for (i = 2; i < len; i++) {
f0100b31:	ba 00 00 00 00       	mov    $0x0,%edx
f0100b36:	83 f8 02             	cmp    $0x2,%eax
f0100b39:	76 4d                	jbe    f0100b88 <xtoi+0x91>
f0100b3b:	b8 02 00 00 00       	mov    $0x2,%eax
		temp *= 16;
f0100b40:	89 d7                	mov    %edx,%edi
f0100b42:	c1 e7 04             	shl    $0x4,%edi
		if (origin[i] >= '0' && origin[i] <= '9')
f0100b45:	0f b6 0c 03          	movzbl (%ebx,%eax,1),%ecx
f0100b49:	8d 51 d0             	lea    -0x30(%ecx),%edx
f0100b4c:	80 fa 09             	cmp    $0x9,%dl
f0100b4f:	77 09                	ja     f0100b5a <xtoi+0x63>
			temp += origin[i] - '0';
f0100b51:	0f be c9             	movsbl %cl,%ecx
f0100b54:	8d 54 0f d0          	lea    -0x30(%edi,%ecx,1),%edx
f0100b58:	eb 20                	jmp    f0100b7a <xtoi+0x83>
		else if (origin[i] >= 'a' && origin[i] <= 'f')
f0100b5a:	8d 51 9f             	lea    -0x61(%ecx),%edx
f0100b5d:	80 fa 05             	cmp    $0x5,%dl
f0100b60:	77 09                	ja     f0100b6b <xtoi+0x74>
			temp += origin[i] - 'a' + 10;
f0100b62:	0f be c9             	movsbl %cl,%ecx
f0100b65:	8d 54 0f a9          	lea    -0x57(%edi,%ecx,1),%edx
f0100b69:	eb 0f                	jmp    f0100b7a <xtoi+0x83>
		else if (origin[i] >= 'A' && origin[i] <= 'F')
f0100b6b:	8d 51 bf             	lea    -0x41(%ecx),%edx
f0100b6e:	80 fa 05             	cmp    $0x5,%dl
f0100b71:	77 10                	ja     f0100b83 <xtoi+0x8c>
			temp += origin[i] - 'A' + 10;
f0100b73:	0f be c9             	movsbl %cl,%ecx
f0100b76:	8d 54 0f c9          	lea    -0x37(%edi,%ecx,1),%edx
	if ((origin[0] != '0') || (origin[1] != 'x' && origin[1] != 'X')) 
	{
		check = false;
		return -1;
	}
	for (i = 2; i < len; i++) {
f0100b7a:	83 c0 01             	add    $0x1,%eax
f0100b7d:	39 c6                	cmp    %eax,%esi
f0100b7f:	75 bf                	jne    f0100b40 <xtoi+0x49>
f0100b81:	eb 05                	jmp    f0100b88 <xtoi+0x91>
			temp += origin[i] - 'a' + 10;
		else if (origin[i] >= 'A' && origin[i] <= 'F')
			temp += origin[i] - 'A' + 10;
		else {
			check = false;
			return -1;
f0100b83:	ba ff ff ff ff       	mov    $0xffffffff,%edx
		}
	}
	return temp;
}
f0100b88:	89 d0                	mov    %edx,%eax
f0100b8a:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0100b8d:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0100b90:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0100b93:	89 ec                	mov    %ebp,%esp
f0100b95:	5d                   	pop    %ebp
f0100b96:	c3                   	ret    

f0100b97 <mon_showmapping>:
}
int mon_show(int argc, char **argv, struct Trapframe *tf) {
	return 0;
}
int mon_showmapping(int argc, char **argv, struct Trapframe *tf) 
{
f0100b97:	55                   	push   %ebp
f0100b98:	89 e5                	mov    %esp,%ebp
f0100b9a:	57                   	push   %edi
f0100b9b:	56                   	push   %esi
f0100b9c:	53                   	push   %ebx
f0100b9d:	83 ec 3c             	sub    $0x3c,%esp
f0100ba0:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	uintptr_t begin, end;
	bool check1, check2;
	begin = xtoi(argv[1], &check1); end = xtoi(argv[2], &check2);
f0100ba3:	8d 45 e7             	lea    -0x19(%ebp),%eax
f0100ba6:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100baa:	8b 43 04             	mov    0x4(%ebx),%eax
f0100bad:	89 04 24             	mov    %eax,(%esp)
f0100bb0:	e8 42 ff ff ff       	call   f0100af7 <xtoi>
f0100bb5:	89 c6                	mov    %eax,%esi
f0100bb7:	8d 45 e6             	lea    -0x1a(%ebp),%eax
f0100bba:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100bbe:	8b 43 08             	mov    0x8(%ebx),%eax
f0100bc1:	89 04 24             	mov    %eax,(%esp)
f0100bc4:	e8 2e ff ff ff       	call   f0100af7 <xtoi>
	if (!check1 || !check2) {
f0100bc9:	80 7d e7 00          	cmpb   $0x0,-0x19(%ebp)
f0100bcd:	74 06                	je     f0100bd5 <mon_showmapping+0x3e>
f0100bcf:	80 7d e6 00          	cmpb   $0x0,-0x1a(%ebp)
f0100bd3:	75 11                	jne    f0100be6 <mon_showmapping+0x4f>
		cprintf("Address typing error\n");
f0100bd5:	c7 04 24 e6 47 10 f0 	movl   $0xf01047e6,(%esp)
f0100bdc:	e8 1d 28 00 00       	call   f01033fe <cprintf>
		return 0;
f0100be1:	e9 ee 00 00 00       	jmp    f0100cd4 <mon_showmapping+0x13d>
	}
	begin = ROUNDUP(begin, PGSIZE); 
f0100be6:	8d 9e ff 0f 00 00    	lea    0xfff(%esi),%ebx
f0100bec:	81 e3 00 f0 ff ff    	and    $0xfffff000,%ebx
	end   = ROUNDUP(end, PGSIZE);
f0100bf2:	05 ff 0f 00 00       	add    $0xfff,%eax
f0100bf7:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100bfc:	89 45 d4             	mov    %eax,-0x2c(%ebp)
	for (;begin <= end; begin += PGSIZE) {
f0100bff:	39 c3                	cmp    %eax,%ebx
f0100c01:	0f 87 cd 00 00 00    	ja     f0100cd4 <mon_showmapping+0x13d>
		pte_t *mapper = pgdir_walk(kern_pgdir, (void*) begin, 1);
f0100c07:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0100c0e:	00 
f0100c0f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100c13:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f0100c18:	89 04 24             	mov    %eax,(%esp)
f0100c1b:	e8 25 09 00 00       	call   f0101545 <pgdir_walk>
f0100c20:	89 c6                	mov    %eax,%esi
		cprintf("VA %x : ", begin);
f0100c22:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100c26:	c7 04 24 fc 47 10 f0 	movl   $0xf01047fc,(%esp)
f0100c2d:	e8 cc 27 00 00       	call   f01033fe <cprintf>
		if (mapper != NULL) {
f0100c32:	85 f6                	test   %esi,%esi
f0100c34:	74 73                	je     f0100ca9 <mon_showmapping+0x112>
			if (*mapper & PTE_P) {
f0100c36:	8b 06                	mov    (%esi),%eax
f0100c38:	a8 01                	test   $0x1,%al
f0100c3a:	74 5f                	je     f0100c9b <mon_showmapping+0x104>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0100c3c:	81 fb ff ff ff ef    	cmp    $0xefffffff,%ebx
f0100c42:	77 20                	ja     f0100c64 <mon_showmapping+0xcd>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0100c44:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0100c48:	c7 44 24 08 74 4a 10 	movl   $0xf0104a74,0x8(%esp)
f0100c4f:	f0 
f0100c50:	c7 44 24 04 c0 00 00 	movl   $0xc0,0x4(%esp)
f0100c57:	00 
f0100c58:	c7 04 24 05 48 10 f0 	movl   $0xf0104805,(%esp)
f0100c5f:	e8 30 f4 ff ff       	call   f0100094 <_panic>
	return 0;
}
int mon_show(int argc, char **argv, struct Trapframe *tf) {
	return 0;
}
int mon_showmapping(int argc, char **argv, struct Trapframe *tf) 
f0100c64:	8d 93 00 00 00 10    	lea    0x10000000(%ebx),%edx
	for (;begin <= end; begin += PGSIZE) {
		pte_t *mapper = pgdir_walk(kern_pgdir, (void*) begin, 1);
		cprintf("VA %x : ", begin);
		if (mapper != NULL) {
			if (*mapper & PTE_P) {
				cprintf("mapping %x %x", PTE_ADDR(*mapper), PADDR((void*)begin));
f0100c6a:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100c6e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100c73:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100c77:	c7 04 24 14 48 10 f0 	movl   $0xf0104814,(%esp)
f0100c7e:	e8 7b 27 00 00       	call   f01033fe <cprintf>
				printPermission((pte_t)*mapper);
f0100c83:	8b 06                	mov    (%esi),%eax
f0100c85:	89 04 24             	mov    %eax,(%esp)
f0100c88:	e8 15 fe ff ff       	call   f0100aa2 <printPermission>
				cprintf("\n");
f0100c8d:	c7 04 24 04 56 10 f0 	movl   $0xf0105604,(%esp)
f0100c94:	e8 65 27 00 00       	call   f01033fe <cprintf>
f0100c99:	eb 2a                	jmp    f0100cc5 <mon_showmapping+0x12e>
			} else {
				cprintf("page not mapping\n");
f0100c9b:	c7 04 24 22 48 10 f0 	movl   $0xf0104822,(%esp)
f0100ca2:	e8 57 27 00 00       	call   f01033fe <cprintf>
f0100ca7:	eb 1c                	jmp    f0100cc5 <mon_showmapping+0x12e>
			}
		} else {
			panic("error, out of memory");
f0100ca9:	c7 44 24 08 34 48 10 	movl   $0xf0104834,0x8(%esp)
f0100cb0:	f0 
f0100cb1:	c7 44 24 04 c7 00 00 	movl   $0xc7,0x4(%esp)
f0100cb8:	00 
f0100cb9:	c7 04 24 05 48 10 f0 	movl   $0xf0104805,(%esp)
f0100cc0:	e8 cf f3 ff ff       	call   f0100094 <_panic>
		cprintf("Address typing error\n");
		return 0;
	}
	begin = ROUNDUP(begin, PGSIZE); 
	end   = ROUNDUP(end, PGSIZE);
	for (;begin <= end; begin += PGSIZE) {
f0100cc5:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0100ccb:	39 5d d4             	cmp    %ebx,-0x2c(%ebp)
f0100cce:	0f 83 33 ff ff ff    	jae    f0100c07 <mon_showmapping+0x70>
		} else {
			panic("error, out of memory");
		}
	}
	return 0;
}
f0100cd4:	b8 00 00 00 00       	mov    $0x0,%eax
f0100cd9:	83 c4 3c             	add    $0x3c,%esp
f0100cdc:	5b                   	pop    %ebx
f0100cdd:	5e                   	pop    %esi
f0100cde:	5f                   	pop    %edi
f0100cdf:	5d                   	pop    %ebp
f0100ce0:	c3                   	ret    

f0100ce1 <mon_changePermission>:
	}
	return temp;
}

int mon_changePermission(int argc, char **argv, struct Trapframe *tf) 
{
f0100ce1:	55                   	push   %ebp
f0100ce2:	89 e5                	mov    %esp,%ebp
f0100ce4:	83 ec 38             	sub    $0x38,%esp
f0100ce7:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0100cea:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0100ced:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0100cf0:	8b 7d 08             	mov    0x8(%ebp),%edi
f0100cf3:	8b 75 0c             	mov    0xc(%ebp),%esi
	bool check = true;
f0100cf6:	c6 45 e7 01          	movb   $0x1,-0x19(%ebp)
	if (argc < 2) {
f0100cfa:	83 ff 01             	cmp    $0x1,%edi
f0100cfd:	7f 11                	jg     f0100d10 <mon_changePermission+0x2f>
		cprintf("invalid number of parameters\n");
f0100cff:	c7 04 24 49 48 10 f0 	movl   $0xf0104849,(%esp)
f0100d06:	e8 f3 26 00 00       	call   f01033fe <cprintf>
		return 0;
f0100d0b:	e9 02 01 00 00       	jmp    f0100e12 <mon_changePermission+0x131>
	}
	uintptr_t va = xtoi(argv[1], &check);
f0100d10:	8d 45 e7             	lea    -0x19(%ebp),%eax
f0100d13:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100d17:	8b 46 04             	mov    0x4(%esi),%eax
f0100d1a:	89 04 24             	mov    %eax,(%esp)
f0100d1d:	e8 d5 fd ff ff       	call   f0100af7 <xtoi>
	if (!check) {
f0100d22:	80 7d e7 00          	cmpb   $0x0,-0x19(%ebp)
f0100d26:	75 11                	jne    f0100d39 <mon_changePermission+0x58>
		cprintf("Address typing error\n");
f0100d28:	c7 04 24 e6 47 10 f0 	movl   $0xf01047e6,(%esp)
f0100d2f:	e8 ca 26 00 00       	call   f01033fe <cprintf>
		return 0;
f0100d34:	e9 d9 00 00 00       	jmp    f0100e12 <mon_changePermission+0x131>
	}
	pte_t* mapper = pgdir_walk(kern_pgdir, (void*) va, 1);
f0100d39:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0100d40:	00 
f0100d41:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100d45:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f0100d4a:	89 04 24             	mov    %eax,(%esp)
f0100d4d:	e8 f3 07 00 00       	call   f0101545 <pgdir_walk>
f0100d52:	89 c3                	mov    %eax,%ebx
	if (!mapper) 
f0100d54:	85 c0                	test   %eax,%eax
f0100d56:	75 1c                	jne    f0100d74 <mon_changePermission+0x93>
		panic("error, out of memory");
f0100d58:	c7 44 24 08 34 48 10 	movl   $0xf0104834,0x8(%esp)
f0100d5f:	f0 
f0100d60:	c7 44 24 04 96 00 00 	movl   $0x96,0x4(%esp)
f0100d67:	00 
f0100d68:	c7 04 24 05 48 10 f0 	movl   $0xf0104805,(%esp)
f0100d6f:	e8 20 f3 ff ff       	call   f0100094 <_panic>
	physaddr_t pa = PTE_ADDR(*mapper);
	int perm = 0;
	//PTE_U PET_W PTE_P
	if (argc != 2) {
f0100d74:	83 ff 02             	cmp    $0x2,%edi
f0100d77:	74 45                	je     f0100dbe <mon_changePermission+0xdd>
		if (argc != 5) {
f0100d79:	83 ff 05             	cmp    $0x5,%edi
f0100d7c:	74 11                	je     f0100d8f <mon_changePermission+0xae>
			cprintf("invalid number of parameters\n");
f0100d7e:	c7 04 24 49 48 10 f0 	movl   $0xf0104849,(%esp)
f0100d85:	e8 74 26 00 00       	call   f01033fe <cprintf>
			return 0;
f0100d8a:	e9 83 00 00 00       	jmp    f0100e12 <mon_changePermission+0x131>
		}
		if (argv[2][0] == '1') perm |= PTE_U;
f0100d8f:	8b 46 08             	mov    0x8(%esi),%eax
	}
	pte_t* mapper = pgdir_walk(kern_pgdir, (void*) va, 1);
	if (!mapper) 
		panic("error, out of memory");
	physaddr_t pa = PTE_ADDR(*mapper);
	int perm = 0;
f0100d92:	80 38 31             	cmpb   $0x31,(%eax)
f0100d95:	0f 94 c0             	sete   %al
f0100d98:	0f b6 c0             	movzbl %al,%eax
f0100d9b:	89 c7                	mov    %eax,%edi
f0100d9d:	c1 e7 02             	shl    $0x2,%edi
		if (argc != 5) {
			cprintf("invalid number of parameters\n");
			return 0;
		}
		if (argv[2][0] == '1') perm |= PTE_U;
		if (argv[3][0] == '1') perm |= PTE_W;
f0100da0:	8b 56 0c             	mov    0xc(%esi),%edx
f0100da3:	89 f8                	mov    %edi,%eax
f0100da5:	83 c8 02             	or     $0x2,%eax
f0100da8:	80 3a 31             	cmpb   $0x31,(%edx)
f0100dab:	0f 44 f8             	cmove  %eax,%edi
		if (argv[4][0] == '1') perm |= PTE_P;
f0100dae:	8b 56 10             	mov    0x10(%esi),%edx
f0100db1:	89 f8                	mov    %edi,%eax
f0100db3:	83 c8 01             	or     $0x1,%eax
f0100db6:	80 3a 31             	cmpb   $0x31,(%edx)
f0100db9:	0f 44 f8             	cmove  %eax,%edi
f0100dbc:	eb 05                	jmp    f0100dc3 <mon_changePermission+0xe2>
	}
	pte_t* mapper = pgdir_walk(kern_pgdir, (void*) va, 1);
	if (!mapper) 
		panic("error, out of memory");
	physaddr_t pa = PTE_ADDR(*mapper);
	int perm = 0;
f0100dbe:	bf 00 00 00 00       	mov    $0x0,%edi
		if (argv[2][0] == '1') perm |= PTE_U;
		if (argv[3][0] == '1') perm |= PTE_W;
		if (argv[4][0] == '1') perm |= PTE_P;
	}
//	boot_map_region(kern_pgdir, va, PGSIZE, pa, perm);	
	cprintf("before change "); printPermission(*mapper); cprintf("\n");
f0100dc3:	c7 04 24 67 48 10 f0 	movl   $0xf0104867,(%esp)
f0100dca:	e8 2f 26 00 00       	call   f01033fe <cprintf>
f0100dcf:	8b 03                	mov    (%ebx),%eax
f0100dd1:	89 04 24             	mov    %eax,(%esp)
f0100dd4:	e8 c9 fc ff ff       	call   f0100aa2 <printPermission>
f0100dd9:	c7 04 24 04 56 10 f0 	movl   $0xf0105604,(%esp)
f0100de0:	e8 19 26 00 00       	call   f01033fe <cprintf>
	
	*mapper = PTE_ADDR(*mapper) | perm;
f0100de5:	8b 03                	mov    (%ebx),%eax
f0100de7:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100dec:	09 c7                	or     %eax,%edi
f0100dee:	89 3b                	mov    %edi,(%ebx)
	cprintf("after change ");  printPermission(*mapper); cprintf("\n");
f0100df0:	c7 04 24 76 48 10 f0 	movl   $0xf0104876,(%esp)
f0100df7:	e8 02 26 00 00       	call   f01033fe <cprintf>
f0100dfc:	8b 03                	mov    (%ebx),%eax
f0100dfe:	89 04 24             	mov    %eax,(%esp)
f0100e01:	e8 9c fc ff ff       	call   f0100aa2 <printPermission>
f0100e06:	c7 04 24 04 56 10 f0 	movl   $0xf0105604,(%esp)
f0100e0d:	e8 ec 25 00 00       	call   f01033fe <cprintf>
	return 0;
}
f0100e12:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e17:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0100e1a:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0100e1d:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0100e20:	89 ec                	mov    %ebp,%esp
f0100e22:	5d                   	pop    %ebp
f0100e23:	c3                   	ret    

f0100e24 <mon_showvm>:
int mon_showvm(int argc, char **argv, struct Trapframe *tf) {
f0100e24:	55                   	push   %ebp
f0100e25:	89 e5                	mov    %esp,%ebp
	return 0;
}
f0100e27:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e2c:	5d                   	pop    %ebp
f0100e2d:	c3                   	ret    

f0100e2e <mon_show>:
int mon_show(int argc, char **argv, struct Trapframe *tf) {
f0100e2e:	55                   	push   %ebp
f0100e2f:	89 e5                	mov    %esp,%ebp
	return 0;
}
f0100e31:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e36:	5d                   	pop    %ebp
f0100e37:	c3                   	ret    

f0100e38 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100e38:	55                   	push   %ebp
f0100e39:	89 e5                	mov    %esp,%ebp
f0100e3b:	57                   	push   %edi
f0100e3c:	56                   	push   %esi
f0100e3d:	53                   	push   %ebx
f0100e3e:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100e41:	c7 04 24 98 4a 10 f0 	movl   $0xf0104a98,(%esp)
f0100e48:	e8 b1 25 00 00       	call   f01033fe <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100e4d:	c7 04 24 bc 4a 10 f0 	movl   $0xf0104abc,(%esp)
f0100e54:	e8 a5 25 00 00       	call   f01033fe <cprintf>
  //	cprintf("x %d, y %x, z %d\n", x, y, z);
//	unsigned int i = 0x00646c72;
//	cprintf("H%x Wo%s", 57616, &i);

	while (1) {
		buf = readline("K> ");
f0100e59:	c7 04 24 84 48 10 f0 	movl   $0xf0104884,(%esp)
f0100e60:	e8 ab 2e 00 00       	call   f0103d10 <readline>
f0100e65:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100e67:	85 c0                	test   %eax,%eax
f0100e69:	74 ee                	je     f0100e59 <monitor+0x21>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100e6b:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100e72:	be 00 00 00 00       	mov    $0x0,%esi
f0100e77:	eb 06                	jmp    f0100e7f <monitor+0x47>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100e79:	c6 03 00             	movb   $0x0,(%ebx)
f0100e7c:	83 c3 01             	add    $0x1,%ebx
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100e7f:	0f b6 03             	movzbl (%ebx),%eax
f0100e82:	84 c0                	test   %al,%al
f0100e84:	74 6a                	je     f0100ef0 <monitor+0xb8>
f0100e86:	0f be c0             	movsbl %al,%eax
f0100e89:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100e8d:	c7 04 24 88 48 10 f0 	movl   $0xf0104888,(%esp)
f0100e94:	e8 cd 30 00 00       	call   f0103f66 <strchr>
f0100e99:	85 c0                	test   %eax,%eax
f0100e9b:	75 dc                	jne    f0100e79 <monitor+0x41>
			*buf++ = 0;
		if (*buf == 0)
f0100e9d:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100ea0:	74 4e                	je     f0100ef0 <monitor+0xb8>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100ea2:	83 fe 0f             	cmp    $0xf,%esi
f0100ea5:	75 16                	jne    f0100ebd <monitor+0x85>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100ea7:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f0100eae:	00 
f0100eaf:	c7 04 24 8d 48 10 f0 	movl   $0xf010488d,(%esp)
f0100eb6:	e8 43 25 00 00       	call   f01033fe <cprintf>
f0100ebb:	eb 9c                	jmp    f0100e59 <monitor+0x21>
			return 0;
		}
		argv[argc++] = buf;
f0100ebd:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0100ec1:	83 c6 01             	add    $0x1,%esi
		while (*buf && !strchr(WHITESPACE, *buf))
f0100ec4:	0f b6 03             	movzbl (%ebx),%eax
f0100ec7:	84 c0                	test   %al,%al
f0100ec9:	75 0c                	jne    f0100ed7 <monitor+0x9f>
f0100ecb:	eb b2                	jmp    f0100e7f <monitor+0x47>
			buf++;
f0100ecd:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100ed0:	0f b6 03             	movzbl (%ebx),%eax
f0100ed3:	84 c0                	test   %al,%al
f0100ed5:	74 a8                	je     f0100e7f <monitor+0x47>
f0100ed7:	0f be c0             	movsbl %al,%eax
f0100eda:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100ede:	c7 04 24 88 48 10 f0 	movl   $0xf0104888,(%esp)
f0100ee5:	e8 7c 30 00 00       	call   f0103f66 <strchr>
f0100eea:	85 c0                	test   %eax,%eax
f0100eec:	74 df                	je     f0100ecd <monitor+0x95>
f0100eee:	eb 8f                	jmp    f0100e7f <monitor+0x47>
			buf++;
	}
	argv[argc] = 0;
f0100ef0:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f0100ef7:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100ef8:	85 f6                	test   %esi,%esi
f0100efa:	0f 84 59 ff ff ff    	je     f0100e59 <monitor+0x21>
f0100f00:	bb 20 4c 10 f0       	mov    $0xf0104c20,%ebx
f0100f05:	bf 00 00 00 00       	mov    $0x0,%edi
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100f0a:	8b 03                	mov    (%ebx),%eax
f0100f0c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100f10:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100f13:	89 04 24             	mov    %eax,(%esp)
f0100f16:	e8 d0 2f 00 00       	call   f0103eeb <strcmp>
f0100f1b:	85 c0                	test   %eax,%eax
f0100f1d:	75 24                	jne    f0100f43 <monitor+0x10b>
			return commands[i].func(argc, argv, tf);
f0100f1f:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f0100f22:	8b 55 08             	mov    0x8(%ebp),%edx
f0100f25:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100f29:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100f2c:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100f30:	89 34 24             	mov    %esi,(%esp)
f0100f33:	ff 14 85 28 4c 10 f0 	call   *-0xfefb3d8(,%eax,4)
//	cprintf("H%x Wo%s", 57616, &i);

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100f3a:	85 c0                	test   %eax,%eax
f0100f3c:	78 28                	js     f0100f66 <monitor+0x12e>
f0100f3e:	e9 16 ff ff ff       	jmp    f0100e59 <monitor+0x21>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f0100f43:	83 c7 01             	add    $0x1,%edi
f0100f46:	83 c3 0c             	add    $0xc,%ebx
f0100f49:	83 ff 06             	cmp    $0x6,%edi
f0100f4c:	75 bc                	jne    f0100f0a <monitor+0xd2>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100f4e:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100f51:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100f55:	c7 04 24 aa 48 10 f0 	movl   $0xf01048aa,(%esp)
f0100f5c:	e8 9d 24 00 00       	call   f01033fe <cprintf>
f0100f61:	e9 f3 fe ff ff       	jmp    f0100e59 <monitor+0x21>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100f66:	83 c4 5c             	add    $0x5c,%esp
f0100f69:	5b                   	pop    %ebx
f0100f6a:	5e                   	pop    %esi
f0100f6b:	5f                   	pop    %edi
f0100f6c:	5d                   	pop    %ebp
f0100f6d:	c3                   	ret    
	...

f0100f70 <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f0100f70:	55                   	push   %ebp
f0100f71:	89 e5                	mov    %esp,%ebp
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100f73:	83 3d 5c 95 11 f0 00 	cmpl   $0x0,0xf011955c
f0100f7a:	75 11                	jne    f0100f8d <boot_alloc+0x1d>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100f7c:	ba 8f a9 11 f0       	mov    $0xf011a98f,%edx
f0100f81:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100f87:	89 15 5c 95 11 f0    	mov    %edx,0xf011955c
		void *temp = nextfree;
		nextfree += n;
		nextfree = ROUNDUP(nextfree, PGSIZE);
		return temp;
	} else if (n == 0) {
		return (void*)nextfree;
f0100f8d:	8b 15 5c 95 11 f0    	mov    0xf011955c,%edx
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	// page_alloc() is the real allocator.

	// LAB 2: Your code here.
	if (n > 0) {
f0100f93:	85 c0                	test   %eax,%eax
f0100f95:	74 11                	je     f0100fa8 <boot_alloc+0x38>
		void *temp = nextfree;
		nextfree += n;
		nextfree = ROUNDUP(nextfree, PGSIZE);
f0100f97:	8d 84 02 ff 0f 00 00 	lea    0xfff(%edx,%eax,1),%eax
f0100f9e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100fa3:	a3 5c 95 11 f0       	mov    %eax,0xf011955c
		return temp;
	} else if (n == 0) {
		return (void*)nextfree;
	}
	return NULL;
}
f0100fa8:	89 d0                	mov    %edx,%eax
f0100faa:	5d                   	pop    %ebp
f0100fab:	c3                   	ret    

f0100fac <check_va2pa>:
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0100fac:	55                   	push   %ebp
f0100fad:	89 e5                	mov    %esp,%ebp
f0100faf:	83 ec 18             	sub    $0x18,%esp
//	cprintf("!");
	pte_t *p;
	//cprintf("!");
	pgdir = &pgdir[PDX(va)];
f0100fb2:	89 d1                	mov    %edx,%ecx
f0100fb4:	c1 e9 16             	shr    $0x16,%ecx
	if (!(*pgdir & PTE_P))
f0100fb7:	8b 0c 88             	mov    (%eax,%ecx,4),%ecx
		return ~0;
f0100fba:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
{
//	cprintf("!");
	pte_t *p;
	//cprintf("!");
	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f0100fbf:	f6 c1 01             	test   $0x1,%cl
f0100fc2:	74 57                	je     f010101b <check_va2pa+0x6f>
		return ~0;
 //	cprintf("!");	
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100fc4:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100fca:	89 c8                	mov    %ecx,%eax
f0100fcc:	c1 e8 0c             	shr    $0xc,%eax
f0100fcf:	3b 05 84 99 11 f0    	cmp    0xf0119984,%eax
f0100fd5:	72 20                	jb     f0100ff7 <check_va2pa+0x4b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100fd7:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0100fdb:	c7 44 24 08 68 4c 10 	movl   $0xf0104c68,0x8(%esp)
f0100fe2:	f0 
f0100fe3:	c7 44 24 04 d8 02 00 	movl   $0x2d8,0x4(%esp)
f0100fea:	00 
f0100feb:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f0100ff2:	e8 9d f0 ff ff       	call   f0100094 <_panic>
	if (!(p[PTX(va)] & PTE_P))
f0100ff7:	c1 ea 0c             	shr    $0xc,%edx
f0100ffa:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0101000:	8b 84 91 00 00 00 f0 	mov    -0x10000000(%ecx,%edx,4),%eax
f0101007:	89 c2                	mov    %eax,%edx
f0101009:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f010100c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0101011:	85 d2                	test   %edx,%edx
f0101013:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0101018:	0f 44 c2             	cmove  %edx,%eax
}
f010101b:	c9                   	leave  
f010101c:	c3                   	ret    

f010101d <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f010101d:	55                   	push   %ebp
f010101e:	89 e5                	mov    %esp,%ebp
f0101020:	83 ec 18             	sub    $0x18,%esp
f0101023:	89 5d f8             	mov    %ebx,-0x8(%ebp)
f0101026:	89 75 fc             	mov    %esi,-0x4(%ebp)
f0101029:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f010102b:	89 04 24             	mov    %eax,(%esp)
f010102e:	e8 5d 23 00 00       	call   f0103390 <mc146818_read>
f0101033:	89 c6                	mov    %eax,%esi
f0101035:	83 c3 01             	add    $0x1,%ebx
f0101038:	89 1c 24             	mov    %ebx,(%esp)
f010103b:	e8 50 23 00 00       	call   f0103390 <mc146818_read>
f0101040:	c1 e0 08             	shl    $0x8,%eax
f0101043:	09 f0                	or     %esi,%eax
}
f0101045:	8b 5d f8             	mov    -0x8(%ebp),%ebx
f0101048:	8b 75 fc             	mov    -0x4(%ebp),%esi
f010104b:	89 ec                	mov    %ebp,%esp
f010104d:	5d                   	pop    %ebp
f010104e:	c3                   	ret    

f010104f <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f010104f:	55                   	push   %ebp
f0101050:	89 e5                	mov    %esp,%ebp
f0101052:	57                   	push   %edi
f0101053:	56                   	push   %esi
f0101054:	53                   	push   %ebx
f0101055:	83 ec 3c             	sub    $0x3c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0101058:	3c 01                	cmp    $0x1,%al
f010105a:	19 f6                	sbb    %esi,%esi
f010105c:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
f0101062:	83 c6 01             	add    $0x1,%esi
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0101065:	8b 1d 60 95 11 f0    	mov    0xf0119560,%ebx
f010106b:	85 db                	test   %ebx,%ebx
f010106d:	75 1c                	jne    f010108b <check_page_free_list+0x3c>
		panic("'page_free_list' is a null pointer!");
f010106f:	c7 44 24 08 8c 4c 10 	movl   $0xf0104c8c,0x8(%esp)
f0101076:	f0 
f0101077:	c7 44 24 04 18 02 00 	movl   $0x218,0x4(%esp)
f010107e:	00 
f010107f:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f0101086:	e8 09 f0 ff ff       	call   f0100094 <_panic>

	if (only_low_memory) {
f010108b:	84 c0                	test   %al,%al
f010108d:	74 50                	je     f01010df <check_page_free_list+0x90>
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f010108f:	8d 45 e0             	lea    -0x20(%ebp),%eax
f0101092:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101095:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101098:	89 45 dc             	mov    %eax,-0x24(%ebp)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010109b:	89 d8                	mov    %ebx,%eax
f010109d:	2b 05 8c 99 11 f0    	sub    0xf011998c,%eax
f01010a3:	c1 e0 09             	shl    $0x9,%eax
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f01010a6:	c1 e8 16             	shr    $0x16,%eax
f01010a9:	39 c6                	cmp    %eax,%esi
f01010ab:	0f 96 c0             	setbe  %al
f01010ae:	0f b6 c0             	movzbl %al,%eax
			*tp[pagetype] = pp;
f01010b1:	8b 54 85 d8          	mov    -0x28(%ebp,%eax,4),%edx
f01010b5:	89 1a                	mov    %ebx,(%edx)
			tp[pagetype] = &pp->pp_link;
f01010b7:	89 5c 85 d8          	mov    %ebx,-0x28(%ebp,%eax,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f01010bb:	8b 1b                	mov    (%ebx),%ebx
f01010bd:	85 db                	test   %ebx,%ebx
f01010bf:	75 da                	jne    f010109b <check_page_free_list+0x4c>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f01010c1:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01010c4:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f01010ca:	8b 45 d8             	mov    -0x28(%ebp),%eax
f01010cd:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01010d0:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f01010d2:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f01010d5:	89 1d 60 95 11 f0    	mov    %ebx,0xf0119560
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01010db:	85 db                	test   %ebx,%ebx
f01010dd:	74 67                	je     f0101146 <check_page_free_list+0xf7>
f01010df:	89 d8                	mov    %ebx,%eax
f01010e1:	2b 05 8c 99 11 f0    	sub    0xf011998c,%eax
f01010e7:	c1 f8 03             	sar    $0x3,%eax
f01010ea:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f01010ed:	89 c2                	mov    %eax,%edx
f01010ef:	c1 ea 16             	shr    $0x16,%edx
f01010f2:	39 d6                	cmp    %edx,%esi
f01010f4:	76 4a                	jbe    f0101140 <check_page_free_list+0xf1>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01010f6:	89 c2                	mov    %eax,%edx
f01010f8:	c1 ea 0c             	shr    $0xc,%edx
f01010fb:	3b 15 84 99 11 f0    	cmp    0xf0119984,%edx
f0101101:	72 20                	jb     f0101123 <check_page_free_list+0xd4>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101103:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101107:	c7 44 24 08 68 4c 10 	movl   $0xf0104c68,0x8(%esp)
f010110e:	f0 
f010110f:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0101116:	00 
f0101117:	c7 04 24 6c 53 10 f0 	movl   $0xf010536c,(%esp)
f010111e:	e8 71 ef ff ff       	call   f0100094 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0101123:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
f010112a:	00 
f010112b:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
f0101132:	00 
	return (void *)(pa + KERNBASE);
f0101133:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101138:	89 04 24             	mov    %eax,(%esp)
f010113b:	e8 81 2e 00 00       	call   f0103fc1 <memset>
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101140:	8b 1b                	mov    (%ebx),%ebx
f0101142:	85 db                	test   %ebx,%ebx
f0101144:	75 99                	jne    f01010df <check_page_free_list+0x90>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0101146:	b8 00 00 00 00       	mov    $0x0,%eax
f010114b:	e8 20 fe ff ff       	call   f0100f70 <boot_alloc>
f0101150:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0101153:	8b 15 60 95 11 f0    	mov    0xf0119560,%edx
f0101159:	85 d2                	test   %edx,%edx
f010115b:	0f 84 f6 01 00 00    	je     f0101357 <check_page_free_list+0x308>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0101161:	8b 1d 8c 99 11 f0    	mov    0xf011998c,%ebx
f0101167:	39 da                	cmp    %ebx,%edx
f0101169:	72 4d                	jb     f01011b8 <check_page_free_list+0x169>
		assert(pp < pages + npages);
f010116b:	a1 84 99 11 f0       	mov    0xf0119984,%eax
f0101170:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0101173:	8d 04 c3             	lea    (%ebx,%eax,8),%eax
f0101176:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101179:	39 c2                	cmp    %eax,%edx
f010117b:	73 64                	jae    f01011e1 <check_page_free_list+0x192>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f010117d:	89 5d d0             	mov    %ebx,-0x30(%ebp)
f0101180:	89 d0                	mov    %edx,%eax
f0101182:	29 d8                	sub    %ebx,%eax
f0101184:	a8 07                	test   $0x7,%al
f0101186:	0f 85 82 00 00 00    	jne    f010120e <check_page_free_list+0x1bf>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010118c:	c1 f8 03             	sar    $0x3,%eax
f010118f:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0101192:	85 c0                	test   %eax,%eax
f0101194:	0f 84 a2 00 00 00    	je     f010123c <check_page_free_list+0x1ed>
		assert(page2pa(pp) != IOPHYSMEM);
f010119a:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f010119f:	0f 84 c2 00 00 00    	je     f0101267 <check_page_free_list+0x218>
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f01011a5:	be 00 00 00 00       	mov    $0x0,%esi
f01011aa:	bf 00 00 00 00       	mov    $0x0,%edi
f01011af:	e9 d7 00 00 00       	jmp    f010128b <check_page_free_list+0x23c>
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f01011b4:	39 da                	cmp    %ebx,%edx
f01011b6:	73 24                	jae    f01011dc <check_page_free_list+0x18d>
f01011b8:	c7 44 24 0c 7a 53 10 	movl   $0xf010537a,0xc(%esp)
f01011bf:	f0 
f01011c0:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f01011c7:	f0 
f01011c8:	c7 44 24 04 32 02 00 	movl   $0x232,0x4(%esp)
f01011cf:	00 
f01011d0:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f01011d7:	e8 b8 ee ff ff       	call   f0100094 <_panic>
		assert(pp < pages + npages);
f01011dc:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f01011df:	72 24                	jb     f0101205 <check_page_free_list+0x1b6>
f01011e1:	c7 44 24 0c 9b 53 10 	movl   $0xf010539b,0xc(%esp)
f01011e8:	f0 
f01011e9:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f01011f0:	f0 
f01011f1:	c7 44 24 04 33 02 00 	movl   $0x233,0x4(%esp)
f01011f8:	00 
f01011f9:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f0101200:	e8 8f ee ff ff       	call   f0100094 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0101205:	89 d0                	mov    %edx,%eax
f0101207:	2b 45 d0             	sub    -0x30(%ebp),%eax
f010120a:	a8 07                	test   $0x7,%al
f010120c:	74 24                	je     f0101232 <check_page_free_list+0x1e3>
f010120e:	c7 44 24 0c b0 4c 10 	movl   $0xf0104cb0,0xc(%esp)
f0101215:	f0 
f0101216:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f010121d:	f0 
f010121e:	c7 44 24 04 34 02 00 	movl   $0x234,0x4(%esp)
f0101225:	00 
f0101226:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f010122d:	e8 62 ee ff ff       	call   f0100094 <_panic>
f0101232:	c1 f8 03             	sar    $0x3,%eax
f0101235:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0101238:	85 c0                	test   %eax,%eax
f010123a:	75 24                	jne    f0101260 <check_page_free_list+0x211>
f010123c:	c7 44 24 0c af 53 10 	movl   $0xf01053af,0xc(%esp)
f0101243:	f0 
f0101244:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f010124b:	f0 
f010124c:	c7 44 24 04 37 02 00 	movl   $0x237,0x4(%esp)
f0101253:	00 
f0101254:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f010125b:	e8 34 ee ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0101260:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0101265:	75 24                	jne    f010128b <check_page_free_list+0x23c>
f0101267:	c7 44 24 0c c0 53 10 	movl   $0xf01053c0,0xc(%esp)
f010126e:	f0 
f010126f:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f0101276:	f0 
f0101277:	c7 44 24 04 38 02 00 	movl   $0x238,0x4(%esp)
f010127e:	00 
f010127f:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f0101286:	e8 09 ee ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f010128b:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0101290:	75 24                	jne    f01012b6 <check_page_free_list+0x267>
f0101292:	c7 44 24 0c e4 4c 10 	movl   $0xf0104ce4,0xc(%esp)
f0101299:	f0 
f010129a:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f01012a1:	f0 
f01012a2:	c7 44 24 04 39 02 00 	movl   $0x239,0x4(%esp)
f01012a9:	00 
f01012aa:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f01012b1:	e8 de ed ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f01012b6:	3d 00 00 10 00       	cmp    $0x100000,%eax
f01012bb:	75 24                	jne    f01012e1 <check_page_free_list+0x292>
f01012bd:	c7 44 24 0c d9 53 10 	movl   $0xf01053d9,0xc(%esp)
f01012c4:	f0 
f01012c5:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f01012cc:	f0 
f01012cd:	c7 44 24 04 3a 02 00 	movl   $0x23a,0x4(%esp)
f01012d4:	00 
f01012d5:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f01012dc:	e8 b3 ed ff ff       	call   f0100094 <_panic>
f01012e1:	89 c1                	mov    %eax,%ecx
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f01012e3:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f01012e8:	76 57                	jbe    f0101341 <check_page_free_list+0x2f2>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01012ea:	c1 e8 0c             	shr    $0xc,%eax
f01012ed:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f01012f0:	77 20                	ja     f0101312 <check_page_free_list+0x2c3>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01012f2:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01012f6:	c7 44 24 08 68 4c 10 	movl   $0xf0104c68,0x8(%esp)
f01012fd:	f0 
f01012fe:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0101305:	00 
f0101306:	c7 04 24 6c 53 10 f0 	movl   $0xf010536c,(%esp)
f010130d:	e8 82 ed ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0101312:	81 e9 00 00 00 10    	sub    $0x10000000,%ecx
f0101318:	39 4d c8             	cmp    %ecx,-0x38(%ebp)
f010131b:	76 29                	jbe    f0101346 <check_page_free_list+0x2f7>
f010131d:	c7 44 24 0c 08 4d 10 	movl   $0xf0104d08,0xc(%esp)
f0101324:	f0 
f0101325:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f010132c:	f0 
f010132d:	c7 44 24 04 3b 02 00 	movl   $0x23b,0x4(%esp)
f0101334:	00 
f0101335:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f010133c:	e8 53 ed ff ff       	call   f0100094 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0101341:	83 c7 01             	add    $0x1,%edi
f0101344:	eb 03                	jmp    f0101349 <check_page_free_list+0x2fa>
		else
			++nfree_extmem;
f0101346:	83 c6 01             	add    $0x1,%esi
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0101349:	8b 12                	mov    (%edx),%edx
f010134b:	85 d2                	test   %edx,%edx
f010134d:	0f 85 61 fe ff ff    	jne    f01011b4 <check_page_free_list+0x165>
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0101353:	85 ff                	test   %edi,%edi
f0101355:	7f 24                	jg     f010137b <check_page_free_list+0x32c>
f0101357:	c7 44 24 0c f3 53 10 	movl   $0xf01053f3,0xc(%esp)
f010135e:	f0 
f010135f:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f0101366:	f0 
f0101367:	c7 44 24 04 43 02 00 	movl   $0x243,0x4(%esp)
f010136e:	00 
f010136f:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f0101376:	e8 19 ed ff ff       	call   f0100094 <_panic>
	assert(nfree_extmem > 0);
f010137b:	85 f6                	test   %esi,%esi
f010137d:	7f 24                	jg     f01013a3 <check_page_free_list+0x354>
f010137f:	c7 44 24 0c 05 54 10 	movl   $0xf0105405,0xc(%esp)
f0101386:	f0 
f0101387:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f010138e:	f0 
f010138f:	c7 44 24 04 44 02 00 	movl   $0x244,0x4(%esp)
f0101396:	00 
f0101397:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f010139e:	e8 f1 ec ff ff       	call   f0100094 <_panic>
}
f01013a3:	83 c4 3c             	add    $0x3c,%esp
f01013a6:	5b                   	pop    %ebx
f01013a7:	5e                   	pop    %esi
f01013a8:	5f                   	pop    %edi
f01013a9:	5d                   	pop    %ebp
f01013aa:	c3                   	ret    

f01013ab <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f01013ab:	55                   	push   %ebp
f01013ac:	89 e5                	mov    %esp,%ebp
f01013ae:	56                   	push   %esi
f01013af:	53                   	push   %ebx
f01013b0:	83 ec 10             	sub    $0x10,%esp
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	size_t low = IOPHYSMEM / PGSIZE;	
	size_t top = (PADDR(boot_alloc(0))) / PGSIZE;
f01013b3:	b8 00 00 00 00       	mov    $0x0,%eax
f01013b8:	e8 b3 fb ff ff       	call   f0100f70 <boot_alloc>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01013bd:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01013c2:	77 20                	ja     f01013e4 <page_init+0x39>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01013c4:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01013c8:	c7 44 24 08 74 4a 10 	movl   $0xf0104a74,0x8(%esp)
f01013cf:	f0 
f01013d0:	c7 44 24 04 05 01 00 	movl   $0x105,0x4(%esp)
f01013d7:	00 
f01013d8:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f01013df:	e8 b0 ec ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f01013e4:	8d 98 00 00 00 10    	lea    0x10000000(%eax),%ebx
f01013ea:	c1 eb 0c             	shr    $0xc,%ebx
	cprintf("!!%d %d %d\n", npages, low, top);
f01013ed:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f01013f1:	c7 44 24 08 a0 00 00 	movl   $0xa0,0x8(%esp)
f01013f8:	00 
f01013f9:	a1 84 99 11 f0       	mov    0xf0119984,%eax
f01013fe:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101402:	c7 04 24 16 54 10 f0 	movl   $0xf0105416,(%esp)
f0101409:	e8 f0 1f 00 00       	call   f01033fe <cprintf>
//	cprintf("00");
	page_free_list = NULL;
f010140e:	c7 05 60 95 11 f0 00 	movl   $0x0,0xf0119560
f0101415:	00 00 00 
	for (i = 0; i < npages; i++) {
f0101418:	83 3d 84 99 11 f0 00 	cmpl   $0x0,0xf0119984
f010141f:	74 64                	je     f0101485 <page_init+0xda>
f0101421:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101426:	b8 00 00 00 00       	mov    $0x0,%eax
		if (i == 0 || (i >= low && i < top)){
f010142b:	85 c0                	test   %eax,%eax
f010142d:	74 0b                	je     f010143a <page_init+0x8f>
f010142f:	3d 9f 00 00 00       	cmp    $0x9f,%eax
f0101434:	76 1f                	jbe    f0101455 <page_init+0xaa>
f0101436:	39 d8                	cmp    %ebx,%eax
f0101438:	73 1b                	jae    f0101455 <page_init+0xaa>
			pages[i].pp_ref = 1;
f010143a:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
f0101441:	03 15 8c 99 11 f0    	add    0xf011998c,%edx
f0101447:	66 c7 42 04 01 00    	movw   $0x1,0x4(%edx)
			pages[i].pp_link = NULL;
f010144d:	c7 02 00 00 00 00    	movl   $0x0,(%edx)
			continue;
f0101453:	eb 1f                	jmp    f0101474 <page_init+0xc9>
		}
		pages[i].pp_ref = 0;
f0101455:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
f010145c:	8b 35 8c 99 11 f0    	mov    0xf011998c,%esi
f0101462:	66 c7 44 16 04 00 00 	movw   $0x0,0x4(%esi,%edx,1)
	//	cprintf("%d\n", i);
		pages[i].pp_link = page_free_list;
f0101469:	89 0c c6             	mov    %ecx,(%esi,%eax,8)
		page_free_list = &pages[i];
f010146c:	89 d1                	mov    %edx,%ecx
f010146e:	03 0d 8c 99 11 f0    	add    0xf011998c,%ecx
	size_t low = IOPHYSMEM / PGSIZE;	
	size_t top = (PADDR(boot_alloc(0))) / PGSIZE;
	cprintf("!!%d %d %d\n", npages, low, top);
//	cprintf("00");
	page_free_list = NULL;
	for (i = 0; i < npages; i++) {
f0101474:	83 c0 01             	add    $0x1,%eax
f0101477:	39 05 84 99 11 f0    	cmp    %eax,0xf0119984
f010147d:	77 ac                	ja     f010142b <page_init+0x80>
f010147f:	89 0d 60 95 11 f0    	mov    %ecx,0xf0119560
		pages[i].pp_ref = 0;
	//	cprintf("%d\n", i);
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
}
f0101485:	83 c4 10             	add    $0x10,%esp
f0101488:	5b                   	pop    %ebx
f0101489:	5e                   	pop    %esi
f010148a:	5d                   	pop    %ebp
f010148b:	c3                   	ret    

f010148c <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f010148c:	55                   	push   %ebp
f010148d:	89 e5                	mov    %esp,%ebp
f010148f:	83 ec 18             	sub    $0x18,%esp
	// Fill this function in
	if (page_free_list != NULL) {
f0101492:	a1 60 95 11 f0       	mov    0xf0119560,%eax
f0101497:	85 c0                	test   %eax,%eax
f0101499:	74 6b                	je     f0101506 <page_alloc+0x7a>
		if (alloc_flags & ALLOC_ZERO) {
f010149b:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f010149f:	74 56                	je     f01014f7 <page_alloc+0x6b>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01014a1:	2b 05 8c 99 11 f0    	sub    0xf011998c,%eax
f01014a7:	c1 f8 03             	sar    $0x3,%eax
f01014aa:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01014ad:	89 c2                	mov    %eax,%edx
f01014af:	c1 ea 0c             	shr    $0xc,%edx
f01014b2:	3b 15 84 99 11 f0    	cmp    0xf0119984,%edx
f01014b8:	72 20                	jb     f01014da <page_alloc+0x4e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01014ba:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01014be:	c7 44 24 08 68 4c 10 	movl   $0xf0104c68,0x8(%esp)
f01014c5:	f0 
f01014c6:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f01014cd:	00 
f01014ce:	c7 04 24 6c 53 10 f0 	movl   $0xf010536c,(%esp)
f01014d5:	e8 ba eb ff ff       	call   f0100094 <_panic>
//			cprintf("\n````!!!");
			memset(page2kva(page_free_list), 0, PGSIZE);
f01014da:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01014e1:	00 
f01014e2:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01014e9:	00 
	return (void *)(pa + KERNBASE);
f01014ea:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01014ef:	89 04 24             	mov    %eax,(%esp)
f01014f2:	e8 ca 2a 00 00       	call   f0103fc1 <memset>
		}
		struct PageInfo* temp = page_free_list;
f01014f7:	a1 60 95 11 f0       	mov    0xf0119560,%eax
		page_free_list = page_free_list->pp_link;
f01014fc:	8b 10                	mov    (%eax),%edx
f01014fe:	89 15 60 95 11 f0    	mov    %edx,0xf0119560
//		return (struct PageInfo*) page_free_list;
		return temp;
f0101504:	eb 05                	jmp    f010150b <page_alloc+0x7f>
	}
	return NULL;
f0101506:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010150b:	c9                   	leave  
f010150c:	c3                   	ret    

f010150d <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f010150d:	55                   	push   %ebp
f010150e:	89 e5                	mov    %esp,%ebp
f0101510:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	pp->pp_link = page_free_list;
f0101513:	8b 15 60 95 11 f0    	mov    0xf0119560,%edx
f0101519:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f010151b:	a3 60 95 11 f0       	mov    %eax,0xf0119560
}
f0101520:	5d                   	pop    %ebp
f0101521:	c3                   	ret    

f0101522 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0101522:	55                   	push   %ebp
f0101523:	89 e5                	mov    %esp,%ebp
f0101525:	83 ec 04             	sub    $0x4,%esp
f0101528:	8b 45 08             	mov    0x8(%ebp),%eax
	if (--pp->pp_ref == 0)
f010152b:	0f b7 50 04          	movzwl 0x4(%eax),%edx
f010152f:	83 ea 01             	sub    $0x1,%edx
f0101532:	66 89 50 04          	mov    %dx,0x4(%eax)
f0101536:	66 85 d2             	test   %dx,%dx
f0101539:	75 08                	jne    f0101543 <page_decref+0x21>
		page_free(pp);
f010153b:	89 04 24             	mov    %eax,(%esp)
f010153e:	e8 ca ff ff ff       	call   f010150d <page_free>
}
f0101543:	c9                   	leave  
f0101544:	c3                   	ret    

f0101545 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0101545:	55                   	push   %ebp
f0101546:	89 e5                	mov    %esp,%ebp
f0101548:	56                   	push   %esi
f0101549:	53                   	push   %ebx
f010154a:	83 ec 10             	sub    $0x10,%esp
f010154d:	8b 75 0c             	mov    0xc(%ebp),%esi
	// Fill this function in
	bool exist = false;
	pte_t *ptdir;
	if	(pgdir[PDX(va)] & PTE_P) {
f0101550:	89 f3                	mov    %esi,%ebx
f0101552:	c1 eb 16             	shr    $0x16,%ebx
f0101555:	c1 e3 02             	shl    $0x2,%ebx
f0101558:	03 5d 08             	add    0x8(%ebp),%ebx
f010155b:	8b 03                	mov    (%ebx),%eax
f010155d:	a8 01                	test   $0x1,%al
f010155f:	74 47                	je     f01015a8 <pgdir_walk+0x63>
//		pte_t * ptdir = (pte_t*) (PGNUM(*(pgdir + PDX(va))) << PGSHIFT);
		ptdir = (pte_t*) KADDR(PTE_ADDR(pgdir[PDX(va)]));
f0101561:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101566:	89 c2                	mov    %eax,%edx
f0101568:	c1 ea 0c             	shr    $0xc,%edx
f010156b:	3b 15 84 99 11 f0    	cmp    0xf0119984,%edx
f0101571:	72 20                	jb     f0101593 <pgdir_walk+0x4e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101573:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101577:	c7 44 24 08 68 4c 10 	movl   $0xf0104c68,0x8(%esp)
f010157e:	f0 
f010157f:	c7 44 24 04 65 01 00 	movl   $0x165,0x4(%esp)
f0101586:	00 
f0101587:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f010158e:	e8 01 eb ff ff       	call   f0100094 <_panic>
//		pgdir[PDX(va)];
//		cprintf("%d", va);
		return ptdir + PTX(va);
f0101593:	c1 ee 0a             	shr    $0xa,%esi
f0101596:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f010159c:	8d 84 30 00 00 00 f0 	lea    -0x10000000(%eax,%esi,1),%eax
f01015a3:	e9 85 00 00 00       	jmp    f010162d <pgdir_walk+0xe8>
	} else {
		if (create) {
f01015a8:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f01015ac:	74 73                	je     f0101621 <pgdir_walk+0xdc>
			struct PageInfo * temp = page_alloc(ALLOC_ZERO);
f01015ae:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f01015b5:	e8 d2 fe ff ff       	call   f010148c <page_alloc>
			if (temp == NULL) return NULL;
f01015ba:	85 c0                	test   %eax,%eax
f01015bc:	74 6a                	je     f0101628 <pgdir_walk+0xe3>
			temp->pp_ref++;
f01015be:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01015c3:	89 c2                	mov    %eax,%edx
f01015c5:	2b 15 8c 99 11 f0    	sub    0xf011998c,%edx
f01015cb:	c1 fa 03             	sar    $0x3,%edx
f01015ce:	c1 e2 0c             	shl    $0xc,%edx
			pgdir[PDX(va)] = page2pa(temp) | PTE_P | PTE_U | PTE_W;
f01015d1:	83 ca 07             	or     $0x7,%edx
f01015d4:	89 13                	mov    %edx,(%ebx)
f01015d6:	2b 05 8c 99 11 f0    	sub    0xf011998c,%eax
f01015dc:	c1 f8 03             	sar    $0x3,%eax
f01015df:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01015e2:	89 c2                	mov    %eax,%edx
f01015e4:	c1 ea 0c             	shr    $0xc,%edx
f01015e7:	3b 15 84 99 11 f0    	cmp    0xf0119984,%edx
f01015ed:	72 20                	jb     f010160f <pgdir_walk+0xca>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01015ef:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01015f3:	c7 44 24 08 68 4c 10 	movl   $0xf0104c68,0x8(%esp)
f01015fa:	f0 
f01015fb:	c7 44 24 04 6f 01 00 	movl   $0x16f,0x4(%esp)
f0101602:	00 
f0101603:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f010160a:	e8 85 ea ff ff       	call   f0100094 <_panic>
			ptdir = (pte_t*) KADDR(page2pa(temp));
			return ptdir + PTX(va);
f010160f:	c1 ee 0a             	shr    $0xa,%esi
f0101612:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f0101618:	8d 84 30 00 00 00 f0 	lea    -0x10000000(%eax,%esi,1),%eax
f010161f:	eb 0c                	jmp    f010162d <pgdir_walk+0xe8>
		} else return NULL;
f0101621:	b8 00 00 00 00       	mov    $0x0,%eax
f0101626:	eb 05                	jmp    f010162d <pgdir_walk+0xe8>
//		cprintf("%d", va);
		return ptdir + PTX(va);
	} else {
		if (create) {
			struct PageInfo * temp = page_alloc(ALLOC_ZERO);
			if (temp == NULL) return NULL;
f0101628:	b8 00 00 00 00       	mov    $0x0,%eax
			return ptdir + PTX(va);
		} else return NULL;
	}
	//temp + PTXSHIFT(va)
	return NULL;
}
f010162d:	83 c4 10             	add    $0x10,%esp
f0101630:	5b                   	pop    %ebx
f0101631:	5e                   	pop    %esi
f0101632:	5d                   	pop    %ebp
f0101633:	c3                   	ret    

f0101634 <boot_map_region>:
// mapped pages.
// 
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f0101634:	55                   	push   %ebp
f0101635:	89 e5                	mov    %esp,%ebp
f0101637:	57                   	push   %edi
f0101638:	56                   	push   %esi
f0101639:	53                   	push   %ebx
f010163a:	83 ec 2c             	sub    $0x2c,%esp
f010163d:	89 c7                	mov    %eax,%edi
f010163f:	89 d3                	mov    %edx,%ebx
f0101641:	8b 75 08             	mov    0x8(%ebp),%esi
	// Fill this function in
	uintptr_t end = va + size;
f0101644:	01 d1                	add    %edx,%ecx
f0101646:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	pte_t* now;
	for (;va != end; va += PGSIZE, pa += PGSIZE) {
f0101649:	39 ca                	cmp    %ecx,%edx
f010164b:	74 5b                	je     f01016a8 <boot_map_region+0x74>
		now = pgdir_walk(pgdir, (void*)va, 1);
		if (now == NULL)
			panic("stopped");
		*now = PTE_ADDR(pa) | perm | PTE_P;
f010164d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101650:	83 c8 01             	or     $0x1,%eax
f0101653:	89 45 e0             	mov    %eax,-0x20(%ebp)
{
	// Fill this function in
	uintptr_t end = va + size;
	pte_t* now;
	for (;va != end; va += PGSIZE, pa += PGSIZE) {
		now = pgdir_walk(pgdir, (void*)va, 1);
f0101656:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f010165d:	00 
f010165e:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101662:	89 3c 24             	mov    %edi,(%esp)
f0101665:	e8 db fe ff ff       	call   f0101545 <pgdir_walk>
		if (now == NULL)
f010166a:	85 c0                	test   %eax,%eax
f010166c:	75 1c                	jne    f010168a <boot_map_region+0x56>
			panic("stopped");
f010166e:	c7 44 24 08 22 54 10 	movl   $0xf0105422,0x8(%esp)
f0101675:	f0 
f0101676:	c7 44 24 04 8a 01 00 	movl   $0x18a,0x4(%esp)
f010167d:	00 
f010167e:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f0101685:	e8 0a ea ff ff       	call   f0100094 <_panic>
		*now = PTE_ADDR(pa) | perm | PTE_P;
f010168a:	89 f2                	mov    %esi,%edx
f010168c:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101692:	0b 55 e0             	or     -0x20(%ebp),%edx
f0101695:	89 10                	mov    %edx,(%eax)
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	uintptr_t end = va + size;
	pte_t* now;
	for (;va != end; va += PGSIZE, pa += PGSIZE) {
f0101697:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f010169d:	81 c6 00 10 00 00    	add    $0x1000,%esi
f01016a3:	39 5d e4             	cmp    %ebx,-0x1c(%ebp)
f01016a6:	75 ae                	jne    f0101656 <boot_map_region+0x22>
		now = pgdir_walk(pgdir, (void*)va, 1);
		if (now == NULL)
			panic("stopped");
		*now = PTE_ADDR(pa) | perm | PTE_P;
	}
}
f01016a8:	83 c4 2c             	add    $0x2c,%esp
f01016ab:	5b                   	pop    %ebx
f01016ac:	5e                   	pop    %esi
f01016ad:	5f                   	pop    %edi
f01016ae:	5d                   	pop    %ebp
f01016af:	c3                   	ret    

f01016b0 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f01016b0:	55                   	push   %ebp
f01016b1:	89 e5                	mov    %esp,%ebp
f01016b3:	53                   	push   %ebx
f01016b4:	83 ec 14             	sub    $0x14,%esp
f01016b7:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// Fill this function in
	pte_t* now = pgdir_walk(pgdir, va, 0);
f01016ba:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01016c1:	00 
f01016c2:	8b 45 0c             	mov    0xc(%ebp),%eax
f01016c5:	89 44 24 04          	mov    %eax,0x4(%esp)
f01016c9:	8b 45 08             	mov    0x8(%ebp),%eax
f01016cc:	89 04 24             	mov    %eax,(%esp)
f01016cf:	e8 71 fe ff ff       	call   f0101545 <pgdir_walk>
	if (now != NULL) {
f01016d4:	85 c0                	test   %eax,%eax
f01016d6:	74 3a                	je     f0101712 <page_lookup+0x62>
		if (pte_store != NULL) {
f01016d8:	85 db                	test   %ebx,%ebx
f01016da:	74 02                	je     f01016de <page_lookup+0x2e>
			*pte_store = now;
f01016dc:	89 03                	mov    %eax,(%ebx)
		}
		return pa2page(PTE_ADDR(*now));
f01016de:	8b 00                	mov    (%eax),%eax
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01016e0:	c1 e8 0c             	shr    $0xc,%eax
f01016e3:	3b 05 84 99 11 f0    	cmp    0xf0119984,%eax
f01016e9:	72 1c                	jb     f0101707 <page_lookup+0x57>
		panic("pa2page called with invalid pa");
f01016eb:	c7 44 24 08 50 4d 10 	movl   $0xf0104d50,0x8(%esp)
f01016f2:	f0 
f01016f3:	c7 44 24 04 4b 00 00 	movl   $0x4b,0x4(%esp)
f01016fa:	00 
f01016fb:	c7 04 24 6c 53 10 f0 	movl   $0xf010536c,(%esp)
f0101702:	e8 8d e9 ff ff       	call   f0100094 <_panic>
	return &pages[PGNUM(pa)];
f0101707:	c1 e0 03             	shl    $0x3,%eax
f010170a:	03 05 8c 99 11 f0    	add    0xf011998c,%eax
f0101710:	eb 05                	jmp    f0101717 <page_lookup+0x67>
	}
	return NULL;
f0101712:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101717:	83 c4 14             	add    $0x14,%esp
f010171a:	5b                   	pop    %ebx
f010171b:	5d                   	pop    %ebp
f010171c:	c3                   	ret    

f010171d <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f010171d:	55                   	push   %ebp
f010171e:	89 e5                	mov    %esp,%ebp
f0101720:	83 ec 28             	sub    $0x28,%esp
	// Fill this function in
//	if (pgdir & PTE_P == 1) {
	pte_t* now;	
	struct PageInfo* temp = page_lookup(pgdir, va, &now);
f0101723:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101726:	89 44 24 08          	mov    %eax,0x8(%esp)
f010172a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010172d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101731:	8b 45 08             	mov    0x8(%ebp),%eax
f0101734:	89 04 24             	mov    %eax,(%esp)
f0101737:	e8 74 ff ff ff       	call   f01016b0 <page_lookup>
	if (temp != NULL) {
f010173c:	85 c0                	test   %eax,%eax
f010173e:	74 19                	je     f0101759 <page_remove+0x3c>
//		cprintf("%d", now);
		if (*now & PTE_P) {
f0101740:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0101743:	f6 02 01             	testb  $0x1,(%edx)
f0101746:	74 08                	je     f0101750 <page_remove+0x33>
//			cprintf("subtraction finish!");
			page_decref(temp);
f0101748:	89 04 24             	mov    %eax,(%esp)
f010174b:	e8 d2 fd ff ff       	call   f0101522 <page_decref>
		}
		//page_decref(temp);
	//}
		*now = 0;
f0101750:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101753:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	}

}
f0101759:	c9                   	leave  
f010175a:	c3                   	ret    

f010175b <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa隐式声明函数‘page_walk’.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f010175b:	55                   	push   %ebp
f010175c:	89 e5                	mov    %esp,%ebp
f010175e:	83 ec 28             	sub    $0x28,%esp
f0101761:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0101764:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0101767:	89 7d fc             	mov    %edi,-0x4(%ebp)
f010176a:	8b 75 0c             	mov    0xc(%ebp),%esi
f010176d:	8b 7d 10             	mov    0x10(%ebp),%edi
	// Fill this function in
	pte_t* now = pgdir_walk(pgdir, va, 0);
f0101770:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101777:	00 
f0101778:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010177c:	8b 45 08             	mov    0x8(%ebp),%eax
f010177f:	89 04 24             	mov    %eax,(%esp)
f0101782:	e8 be fd ff ff       	call   f0101545 <pgdir_walk>
f0101787:	89 c3                	mov    %eax,%ebx
	if ((now != NULL) && (*now & PTE_P)) {
f0101789:	85 c0                	test   %eax,%eax
f010178b:	74 3f                	je     f01017cc <page_insert+0x71>
f010178d:	8b 00                	mov    (%eax),%eax
f010178f:	a8 01                	test   $0x1,%al
f0101791:	74 5b                	je     f01017ee <page_insert+0x93>
		//cprintf("!");
//		PageInfo* now_page = (PageInfo*) pa2page(PTE_ADDR(now) + PGOFF(va));
//		page_remove(now_page);
		if (PTE_ADDR(*now) == page2pa(pp)) {
f0101793:	25 00 f0 ff ff       	and    $0xfffff000,%eax
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101798:	89 f2                	mov    %esi,%edx
f010179a:	2b 15 8c 99 11 f0    	sub    0xf011998c,%edx
f01017a0:	c1 fa 03             	sar    $0x3,%edx
f01017a3:	c1 e2 0c             	shl    $0xc,%edx
f01017a6:	39 d0                	cmp    %edx,%eax
f01017a8:	75 11                	jne    f01017bb <page_insert+0x60>
			*now = PTE_ADDR(page2pa(pp)) | perm | PTE_P;
f01017aa:	8b 55 14             	mov    0x14(%ebp),%edx
f01017ad:	83 ca 01             	or     $0x1,%edx
f01017b0:	09 d0                	or     %edx,%eax
f01017b2:	89 03                	mov    %eax,(%ebx)
			return 0;
f01017b4:	b8 00 00 00 00       	mov    $0x0,%eax
f01017b9:	eb 55                	jmp    f0101810 <page_insert+0xb5>
		}
//		cprintf("%d\n", *now);
		page_remove(pgdir, va);
f01017bb:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01017bf:	8b 45 08             	mov    0x8(%ebp),%eax
f01017c2:	89 04 24             	mov    %eax,(%esp)
f01017c5:	e8 53 ff ff ff       	call   f010171d <page_remove>
f01017ca:	eb 22                	jmp    f01017ee <page_insert+0x93>
	}
	if (now == NULL) now = pgdir_walk(pgdir, va, 1);
f01017cc:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01017d3:	00 
f01017d4:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01017d8:	8b 45 08             	mov    0x8(%ebp),%eax
f01017db:	89 04 24             	mov    %eax,(%esp)
f01017de:	e8 62 fd ff ff       	call   f0101545 <pgdir_walk>
f01017e3:	89 c3                	mov    %eax,%ebx
	if (now == NULL) return -E_NO_MEM;
f01017e5:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f01017ea:	85 db                	test   %ebx,%ebx
f01017ec:	74 22                	je     f0101810 <page_insert+0xb5>
	*now = PTE_ADDR(page2pa(pp)) | perm | PTE_P;
f01017ee:	8b 45 14             	mov    0x14(%ebp),%eax
f01017f1:	83 c8 01             	or     $0x1,%eax
f01017f4:	89 f2                	mov    %esi,%edx
f01017f6:	2b 15 8c 99 11 f0    	sub    0xf011998c,%edx
f01017fc:	c1 fa 03             	sar    $0x3,%edx
f01017ff:	c1 e2 0c             	shl    $0xc,%edx
f0101802:	09 d0                	or     %edx,%eax
f0101804:	89 03                	mov    %eax,(%ebx)
	pp->pp_ref++;
f0101806:	66 83 46 04 01       	addw   $0x1,0x4(%esi)
	return 0;
f010180b:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101810:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0101813:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0101816:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0101819:	89 ec                	mov    %ebp,%esp
f010181b:	5d                   	pop    %ebp
f010181c:	c3                   	ret    

f010181d <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f010181d:	55                   	push   %ebp
f010181e:	89 e5                	mov    %esp,%ebp
f0101820:	57                   	push   %edi
f0101821:	56                   	push   %esi
f0101822:	53                   	push   %ebx
f0101823:	83 ec 3c             	sub    $0x3c,%esp
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f0101826:	b8 15 00 00 00       	mov    $0x15,%eax
f010182b:	e8 ed f7 ff ff       	call   f010101d <nvram_read>
f0101830:	c1 e0 0a             	shl    $0xa,%eax
f0101833:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101839:	85 c0                	test   %eax,%eax
f010183b:	0f 48 c2             	cmovs  %edx,%eax
f010183e:	c1 f8 0c             	sar    $0xc,%eax
f0101841:	a3 58 95 11 f0       	mov    %eax,0xf0119558
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f0101846:	b8 17 00 00 00       	mov    $0x17,%eax
f010184b:	e8 cd f7 ff ff       	call   f010101d <nvram_read>
f0101850:	c1 e0 0a             	shl    $0xa,%eax
f0101853:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101859:	85 c0                	test   %eax,%eax
f010185b:	0f 48 c2             	cmovs  %edx,%eax
f010185e:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f0101861:	85 c0                	test   %eax,%eax
f0101863:	74 0e                	je     f0101873 <mem_init+0x56>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f0101865:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f010186b:	89 15 84 99 11 f0    	mov    %edx,0xf0119984
f0101871:	eb 0c                	jmp    f010187f <mem_init+0x62>
	else
		npages = npages_basemem;
f0101873:	8b 15 58 95 11 f0    	mov    0xf0119558,%edx
f0101879:	89 15 84 99 11 f0    	mov    %edx,0xf0119984

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
		npages_extmem * PGSIZE / 1024);
f010187f:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101882:	c1 e8 0a             	shr    $0xa,%eax
f0101885:	89 44 24 0c          	mov    %eax,0xc(%esp)
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
f0101889:	a1 58 95 11 f0       	mov    0xf0119558,%eax
f010188e:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101891:	c1 e8 0a             	shr    $0xa,%eax
f0101894:	89 44 24 08          	mov    %eax,0x8(%esp)
		npages * PGSIZE / 1024,
f0101898:	a1 84 99 11 f0       	mov    0xf0119984,%eax
f010189d:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01018a0:	c1 e8 0a             	shr    $0xa,%eax
f01018a3:	89 44 24 04          	mov    %eax,0x4(%esp)
f01018a7:	c7 04 24 70 4d 10 f0 	movl   $0xf0104d70,(%esp)
f01018ae:	e8 4b 1b 00 00       	call   f01033fe <cprintf>
	// Remove this line when you're ready to test this function.
//	panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f01018b3:	b8 00 10 00 00       	mov    $0x1000,%eax
f01018b8:	e8 b3 f6 ff ff       	call   f0100f70 <boot_alloc>
f01018bd:	a3 88 99 11 f0       	mov    %eax,0xf0119988
	memset(kern_pgdir, 0, PGSIZE);
f01018c2:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01018c9:	00 
f01018ca:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01018d1:	00 
f01018d2:	89 04 24             	mov    %eax,(%esp)
f01018d5:	e8 e7 26 00 00       	call   f0103fc1 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f01018da:	a1 88 99 11 f0       	mov    0xf0119988,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01018df:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01018e4:	77 20                	ja     f0101906 <mem_init+0xe9>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01018e6:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01018ea:	c7 44 24 08 74 4a 10 	movl   $0xf0104a74,0x8(%esp)
f01018f1:	f0 
f01018f2:	c7 44 24 04 91 00 00 	movl   $0x91,0x4(%esp)
f01018f9:	00 
f01018fa:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f0101901:	e8 8e e7 ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0101906:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f010190c:	83 ca 05             	or     $0x5,%edx
f010190f:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate an array of npages 'struct PageInfo's and store it in 'pages'.
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.
	// Your code goes here:
	pages = (struct PageInfo*) boot_alloc(npages * sizeof(struct PageInfo));
f0101915:	a1 84 99 11 f0       	mov    0xf0119984,%eax
f010191a:	c1 e0 03             	shl    $0x3,%eax
f010191d:	e8 4e f6 ff ff       	call   f0100f70 <boot_alloc>
f0101922:	a3 8c 99 11 f0       	mov    %eax,0xf011998c
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f0101927:	e8 7f fa ff ff       	call   f01013ab <page_init>
	//cprintf("!!!");

	check_page_free_list(1);
f010192c:	b8 01 00 00 00       	mov    $0x1,%eax
f0101931:	e8 19 f7 ff ff       	call   f010104f <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f0101936:	83 3d 8c 99 11 f0 00 	cmpl   $0x0,0xf011998c
f010193d:	75 1c                	jne    f010195b <mem_init+0x13e>
		panic("'pages' is a null pointer!");
f010193f:	c7 44 24 08 2a 54 10 	movl   $0xf010542a,0x8(%esp)
f0101946:	f0 
f0101947:	c7 44 24 04 55 02 00 	movl   $0x255,0x4(%esp)
f010194e:	00 
f010194f:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f0101956:	e8 39 e7 ff ff       	call   f0100094 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010195b:	a1 60 95 11 f0       	mov    0xf0119560,%eax
f0101960:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101965:	85 c0                	test   %eax,%eax
f0101967:	74 09                	je     f0101972 <mem_init+0x155>
		++nfree;
f0101969:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f010196c:	8b 00                	mov    (%eax),%eax
f010196e:	85 c0                	test   %eax,%eax
f0101970:	75 f7                	jne    f0101969 <mem_init+0x14c>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101972:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101979:	e8 0e fb ff ff       	call   f010148c <page_alloc>
f010197e:	89 c6                	mov    %eax,%esi
f0101980:	85 c0                	test   %eax,%eax
f0101982:	75 24                	jne    f01019a8 <mem_init+0x18b>
f0101984:	c7 44 24 0c 45 54 10 	movl   $0xf0105445,0xc(%esp)
f010198b:	f0 
f010198c:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f0101993:	f0 
f0101994:	c7 44 24 04 5d 02 00 	movl   $0x25d,0x4(%esp)
f010199b:	00 
f010199c:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f01019a3:	e8 ec e6 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f01019a8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01019af:	e8 d8 fa ff ff       	call   f010148c <page_alloc>
f01019b4:	89 c7                	mov    %eax,%edi
f01019b6:	85 c0                	test   %eax,%eax
f01019b8:	75 24                	jne    f01019de <mem_init+0x1c1>
f01019ba:	c7 44 24 0c 5b 54 10 	movl   $0xf010545b,0xc(%esp)
f01019c1:	f0 
f01019c2:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f01019c9:	f0 
f01019ca:	c7 44 24 04 5e 02 00 	movl   $0x25e,0x4(%esp)
f01019d1:	00 
f01019d2:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f01019d9:	e8 b6 e6 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f01019de:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01019e5:	e8 a2 fa ff ff       	call   f010148c <page_alloc>
f01019ea:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01019ed:	85 c0                	test   %eax,%eax
f01019ef:	75 24                	jne    f0101a15 <mem_init+0x1f8>
f01019f1:	c7 44 24 0c 71 54 10 	movl   $0xf0105471,0xc(%esp)
f01019f8:	f0 
f01019f9:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f0101a00:	f0 
f0101a01:	c7 44 24 04 5f 02 00 	movl   $0x25f,0x4(%esp)
f0101a08:	00 
f0101a09:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f0101a10:	e8 7f e6 ff ff       	call   f0100094 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101a15:	39 fe                	cmp    %edi,%esi
f0101a17:	75 24                	jne    f0101a3d <mem_init+0x220>
f0101a19:	c7 44 24 0c 87 54 10 	movl   $0xf0105487,0xc(%esp)
f0101a20:	f0 
f0101a21:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f0101a28:	f0 
f0101a29:	c7 44 24 04 62 02 00 	movl   $0x262,0x4(%esp)
f0101a30:	00 
f0101a31:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f0101a38:	e8 57 e6 ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101a3d:	3b 7d d4             	cmp    -0x2c(%ebp),%edi
f0101a40:	74 05                	je     f0101a47 <mem_init+0x22a>
f0101a42:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f0101a45:	75 24                	jne    f0101a6b <mem_init+0x24e>
f0101a47:	c7 44 24 0c ac 4d 10 	movl   $0xf0104dac,0xc(%esp)
f0101a4e:	f0 
f0101a4f:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f0101a56:	f0 
f0101a57:	c7 44 24 04 63 02 00 	movl   $0x263,0x4(%esp)
f0101a5e:	00 
f0101a5f:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f0101a66:	e8 29 e6 ff ff       	call   f0100094 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101a6b:	8b 15 8c 99 11 f0    	mov    0xf011998c,%edx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101a71:	a1 84 99 11 f0       	mov    0xf0119984,%eax
f0101a76:	c1 e0 0c             	shl    $0xc,%eax
f0101a79:	89 f1                	mov    %esi,%ecx
f0101a7b:	29 d1                	sub    %edx,%ecx
f0101a7d:	c1 f9 03             	sar    $0x3,%ecx
f0101a80:	c1 e1 0c             	shl    $0xc,%ecx
f0101a83:	39 c1                	cmp    %eax,%ecx
f0101a85:	72 24                	jb     f0101aab <mem_init+0x28e>
f0101a87:	c7 44 24 0c 99 54 10 	movl   $0xf0105499,0xc(%esp)
f0101a8e:	f0 
f0101a8f:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f0101a96:	f0 
f0101a97:	c7 44 24 04 64 02 00 	movl   $0x264,0x4(%esp)
f0101a9e:	00 
f0101a9f:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f0101aa6:	e8 e9 e5 ff ff       	call   f0100094 <_panic>
f0101aab:	89 f9                	mov    %edi,%ecx
f0101aad:	29 d1                	sub    %edx,%ecx
f0101aaf:	c1 f9 03             	sar    $0x3,%ecx
f0101ab2:	c1 e1 0c             	shl    $0xc,%ecx
	assert(page2pa(pp1) < npages*PGSIZE);
f0101ab5:	39 c8                	cmp    %ecx,%eax
f0101ab7:	77 24                	ja     f0101add <mem_init+0x2c0>
f0101ab9:	c7 44 24 0c b6 54 10 	movl   $0xf01054b6,0xc(%esp)
f0101ac0:	f0 
f0101ac1:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f0101ac8:	f0 
f0101ac9:	c7 44 24 04 65 02 00 	movl   $0x265,0x4(%esp)
f0101ad0:	00 
f0101ad1:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f0101ad8:	e8 b7 e5 ff ff       	call   f0100094 <_panic>
f0101add:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101ae0:	29 d1                	sub    %edx,%ecx
f0101ae2:	89 ca                	mov    %ecx,%edx
f0101ae4:	c1 fa 03             	sar    $0x3,%edx
f0101ae7:	c1 e2 0c             	shl    $0xc,%edx
	assert(page2pa(pp2) < npages*PGSIZE);
f0101aea:	39 d0                	cmp    %edx,%eax
f0101aec:	77 24                	ja     f0101b12 <mem_init+0x2f5>
f0101aee:	c7 44 24 0c d3 54 10 	movl   $0xf01054d3,0xc(%esp)
f0101af5:	f0 
f0101af6:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f0101afd:	f0 
f0101afe:	c7 44 24 04 66 02 00 	movl   $0x266,0x4(%esp)
f0101b05:	00 
f0101b06:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f0101b0d:	e8 82 e5 ff ff       	call   f0100094 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101b12:	a1 60 95 11 f0       	mov    0xf0119560,%eax
f0101b17:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101b1a:	c7 05 60 95 11 f0 00 	movl   $0x0,0xf0119560
f0101b21:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101b24:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101b2b:	e8 5c f9 ff ff       	call   f010148c <page_alloc>
f0101b30:	85 c0                	test   %eax,%eax
f0101b32:	74 24                	je     f0101b58 <mem_init+0x33b>
f0101b34:	c7 44 24 0c f0 54 10 	movl   $0xf01054f0,0xc(%esp)
f0101b3b:	f0 
f0101b3c:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f0101b43:	f0 
f0101b44:	c7 44 24 04 6d 02 00 	movl   $0x26d,0x4(%esp)
f0101b4b:	00 
f0101b4c:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f0101b53:	e8 3c e5 ff ff       	call   f0100094 <_panic>

	// free and re-allocate?
	page_free(pp0);
f0101b58:	89 34 24             	mov    %esi,(%esp)
f0101b5b:	e8 ad f9 ff ff       	call   f010150d <page_free>
	page_free(pp1);
f0101b60:	89 3c 24             	mov    %edi,(%esp)
f0101b63:	e8 a5 f9 ff ff       	call   f010150d <page_free>
	page_free(pp2);
f0101b68:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101b6b:	89 04 24             	mov    %eax,(%esp)
f0101b6e:	e8 9a f9 ff ff       	call   f010150d <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101b73:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101b7a:	e8 0d f9 ff ff       	call   f010148c <page_alloc>
f0101b7f:	89 c6                	mov    %eax,%esi
f0101b81:	85 c0                	test   %eax,%eax
f0101b83:	75 24                	jne    f0101ba9 <mem_init+0x38c>
f0101b85:	c7 44 24 0c 45 54 10 	movl   $0xf0105445,0xc(%esp)
f0101b8c:	f0 
f0101b8d:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f0101b94:	f0 
f0101b95:	c7 44 24 04 74 02 00 	movl   $0x274,0x4(%esp)
f0101b9c:	00 
f0101b9d:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f0101ba4:	e8 eb e4 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f0101ba9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101bb0:	e8 d7 f8 ff ff       	call   f010148c <page_alloc>
f0101bb5:	89 c7                	mov    %eax,%edi
f0101bb7:	85 c0                	test   %eax,%eax
f0101bb9:	75 24                	jne    f0101bdf <mem_init+0x3c2>
f0101bbb:	c7 44 24 0c 5b 54 10 	movl   $0xf010545b,0xc(%esp)
f0101bc2:	f0 
f0101bc3:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f0101bca:	f0 
f0101bcb:	c7 44 24 04 75 02 00 	movl   $0x275,0x4(%esp)
f0101bd2:	00 
f0101bd3:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f0101bda:	e8 b5 e4 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0101bdf:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101be6:	e8 a1 f8 ff ff       	call   f010148c <page_alloc>
f0101beb:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101bee:	85 c0                	test   %eax,%eax
f0101bf0:	75 24                	jne    f0101c16 <mem_init+0x3f9>
f0101bf2:	c7 44 24 0c 71 54 10 	movl   $0xf0105471,0xc(%esp)
f0101bf9:	f0 
f0101bfa:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f0101c01:	f0 
f0101c02:	c7 44 24 04 76 02 00 	movl   $0x276,0x4(%esp)
f0101c09:	00 
f0101c0a:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f0101c11:	e8 7e e4 ff ff       	call   f0100094 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101c16:	39 fe                	cmp    %edi,%esi
f0101c18:	75 24                	jne    f0101c3e <mem_init+0x421>
f0101c1a:	c7 44 24 0c 87 54 10 	movl   $0xf0105487,0xc(%esp)
f0101c21:	f0 
f0101c22:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f0101c29:	f0 
f0101c2a:	c7 44 24 04 78 02 00 	movl   $0x278,0x4(%esp)
f0101c31:	00 
f0101c32:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f0101c39:	e8 56 e4 ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101c3e:	3b 7d d4             	cmp    -0x2c(%ebp),%edi
f0101c41:	74 05                	je     f0101c48 <mem_init+0x42b>
f0101c43:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f0101c46:	75 24                	jne    f0101c6c <mem_init+0x44f>
f0101c48:	c7 44 24 0c ac 4d 10 	movl   $0xf0104dac,0xc(%esp)
f0101c4f:	f0 
f0101c50:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f0101c57:	f0 
f0101c58:	c7 44 24 04 79 02 00 	movl   $0x279,0x4(%esp)
f0101c5f:	00 
f0101c60:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f0101c67:	e8 28 e4 ff ff       	call   f0100094 <_panic>
	assert(!page_alloc(0));
f0101c6c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101c73:	e8 14 f8 ff ff       	call   f010148c <page_alloc>
f0101c78:	85 c0                	test   %eax,%eax
f0101c7a:	74 24                	je     f0101ca0 <mem_init+0x483>
f0101c7c:	c7 44 24 0c f0 54 10 	movl   $0xf01054f0,0xc(%esp)
f0101c83:	f0 
f0101c84:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f0101c8b:	f0 
f0101c8c:	c7 44 24 04 7a 02 00 	movl   $0x27a,0x4(%esp)
f0101c93:	00 
f0101c94:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f0101c9b:	e8 f4 e3 ff ff       	call   f0100094 <_panic>
f0101ca0:	89 f0                	mov    %esi,%eax
f0101ca2:	2b 05 8c 99 11 f0    	sub    0xf011998c,%eax
f0101ca8:	c1 f8 03             	sar    $0x3,%eax
f0101cab:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101cae:	89 c2                	mov    %eax,%edx
f0101cb0:	c1 ea 0c             	shr    $0xc,%edx
f0101cb3:	3b 15 84 99 11 f0    	cmp    0xf0119984,%edx
f0101cb9:	72 20                	jb     f0101cdb <mem_init+0x4be>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101cbb:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101cbf:	c7 44 24 08 68 4c 10 	movl   $0xf0104c68,0x8(%esp)
f0101cc6:	f0 
f0101cc7:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0101cce:	00 
f0101ccf:	c7 04 24 6c 53 10 f0 	movl   $0xf010536c,(%esp)
f0101cd6:	e8 b9 e3 ff ff       	call   f0100094 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f0101cdb:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101ce2:	00 
f0101ce3:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0101cea:	00 
	return (void *)(pa + KERNBASE);
f0101ceb:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101cf0:	89 04 24             	mov    %eax,(%esp)
f0101cf3:	e8 c9 22 00 00       	call   f0103fc1 <memset>
	page_free(pp0);
f0101cf8:	89 34 24             	mov    %esi,(%esp)
f0101cfb:	e8 0d f8 ff ff       	call   f010150d <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101d00:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101d07:	e8 80 f7 ff ff       	call   f010148c <page_alloc>
f0101d0c:	85 c0                	test   %eax,%eax
f0101d0e:	75 24                	jne    f0101d34 <mem_init+0x517>
f0101d10:	c7 44 24 0c ff 54 10 	movl   $0xf01054ff,0xc(%esp)
f0101d17:	f0 
f0101d18:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f0101d1f:	f0 
f0101d20:	c7 44 24 04 7f 02 00 	movl   $0x27f,0x4(%esp)
f0101d27:	00 
f0101d28:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f0101d2f:	e8 60 e3 ff ff       	call   f0100094 <_panic>
	assert(pp && pp0 == pp);
f0101d34:	39 c6                	cmp    %eax,%esi
f0101d36:	74 24                	je     f0101d5c <mem_init+0x53f>
f0101d38:	c7 44 24 0c 1d 55 10 	movl   $0xf010551d,0xc(%esp)
f0101d3f:	f0 
f0101d40:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f0101d47:	f0 
f0101d48:	c7 44 24 04 80 02 00 	movl   $0x280,0x4(%esp)
f0101d4f:	00 
f0101d50:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f0101d57:	e8 38 e3 ff ff       	call   f0100094 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101d5c:	89 f2                	mov    %esi,%edx
f0101d5e:	2b 15 8c 99 11 f0    	sub    0xf011998c,%edx
f0101d64:	c1 fa 03             	sar    $0x3,%edx
f0101d67:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101d6a:	89 d0                	mov    %edx,%eax
f0101d6c:	c1 e8 0c             	shr    $0xc,%eax
f0101d6f:	3b 05 84 99 11 f0    	cmp    0xf0119984,%eax
f0101d75:	72 20                	jb     f0101d97 <mem_init+0x57a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101d77:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101d7b:	c7 44 24 08 68 4c 10 	movl   $0xf0104c68,0x8(%esp)
f0101d82:	f0 
f0101d83:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0101d8a:	00 
f0101d8b:	c7 04 24 6c 53 10 f0 	movl   $0xf010536c,(%esp)
f0101d92:	e8 fd e2 ff ff       	call   f0100094 <_panic>
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++) 
		assert(c[i] == 0);
f0101d97:	80 ba 00 00 00 f0 00 	cmpb   $0x0,-0x10000000(%edx)
f0101d9e:	75 11                	jne    f0101db1 <mem_init+0x594>
f0101da0:	8d 82 01 00 00 f0    	lea    -0xfffffff(%edx),%eax
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0101da6:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++) 
		assert(c[i] == 0);
f0101dac:	80 38 00             	cmpb   $0x0,(%eax)
f0101daf:	74 24                	je     f0101dd5 <mem_init+0x5b8>
f0101db1:	c7 44 24 0c 2d 55 10 	movl   $0xf010552d,0xc(%esp)
f0101db8:	f0 
f0101db9:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f0101dc0:	f0 
f0101dc1:	c7 44 24 04 83 02 00 	movl   $0x283,0x4(%esp)
f0101dc8:	00 
f0101dc9:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f0101dd0:	e8 bf e2 ff ff       	call   f0100094 <_panic>
f0101dd5:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++) 
f0101dd8:	39 d0                	cmp    %edx,%eax
f0101dda:	75 d0                	jne    f0101dac <mem_init+0x58f>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101ddc:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0101ddf:	89 15 60 95 11 f0    	mov    %edx,0xf0119560

	// free the pages we took
	page_free(pp0);
f0101de5:	89 34 24             	mov    %esi,(%esp)
f0101de8:	e8 20 f7 ff ff       	call   f010150d <page_free>
	page_free(pp1);
f0101ded:	89 3c 24             	mov    %edi,(%esp)
f0101df0:	e8 18 f7 ff ff       	call   f010150d <page_free>
	page_free(pp2);
f0101df5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101df8:	89 04 24             	mov    %eax,(%esp)
f0101dfb:	e8 0d f7 ff ff       	call   f010150d <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101e00:	a1 60 95 11 f0       	mov    0xf0119560,%eax
f0101e05:	85 c0                	test   %eax,%eax
f0101e07:	74 09                	je     f0101e12 <mem_init+0x5f5>
		--nfree;
f0101e09:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101e0c:	8b 00                	mov    (%eax),%eax
f0101e0e:	85 c0                	test   %eax,%eax
f0101e10:	75 f7                	jne    f0101e09 <mem_init+0x5ec>
		--nfree;
	assert(nfree == 0);
f0101e12:	85 db                	test   %ebx,%ebx
f0101e14:	74 24                	je     f0101e3a <mem_init+0x61d>
f0101e16:	c7 44 24 0c 37 55 10 	movl   $0xf0105537,0xc(%esp)
f0101e1d:	f0 
f0101e1e:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f0101e25:	f0 
f0101e26:	c7 44 24 04 90 02 00 	movl   $0x290,0x4(%esp)
f0101e2d:	00 
f0101e2e:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f0101e35:	e8 5a e2 ff ff       	call   f0100094 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f0101e3a:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f0101e41:	e8 b8 15 00 00       	call   f01033fe <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101e46:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101e4d:	e8 3a f6 ff ff       	call   f010148c <page_alloc>
f0101e52:	89 c6                	mov    %eax,%esi
f0101e54:	85 c0                	test   %eax,%eax
f0101e56:	75 24                	jne    f0101e7c <mem_init+0x65f>
f0101e58:	c7 44 24 0c 45 54 10 	movl   $0xf0105445,0xc(%esp)
f0101e5f:	f0 
f0101e60:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f0101e67:	f0 
f0101e68:	c7 44 24 04 ec 02 00 	movl   $0x2ec,0x4(%esp)
f0101e6f:	00 
f0101e70:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f0101e77:	e8 18 e2 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f0101e7c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101e83:	e8 04 f6 ff ff       	call   f010148c <page_alloc>
f0101e88:	89 c7                	mov    %eax,%edi
f0101e8a:	85 c0                	test   %eax,%eax
f0101e8c:	75 24                	jne    f0101eb2 <mem_init+0x695>
f0101e8e:	c7 44 24 0c 5b 54 10 	movl   $0xf010545b,0xc(%esp)
f0101e95:	f0 
f0101e96:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f0101e9d:	f0 
f0101e9e:	c7 44 24 04 ed 02 00 	movl   $0x2ed,0x4(%esp)
f0101ea5:	00 
f0101ea6:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f0101ead:	e8 e2 e1 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0101eb2:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101eb9:	e8 ce f5 ff ff       	call   f010148c <page_alloc>
f0101ebe:	89 c3                	mov    %eax,%ebx
f0101ec0:	85 c0                	test   %eax,%eax
f0101ec2:	75 24                	jne    f0101ee8 <mem_init+0x6cb>
f0101ec4:	c7 44 24 0c 71 54 10 	movl   $0xf0105471,0xc(%esp)
f0101ecb:	f0 
f0101ecc:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f0101ed3:	f0 
f0101ed4:	c7 44 24 04 ee 02 00 	movl   $0x2ee,0x4(%esp)
f0101edb:	00 
f0101edc:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f0101ee3:	e8 ac e1 ff ff       	call   f0100094 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101ee8:	39 fe                	cmp    %edi,%esi
f0101eea:	75 24                	jne    f0101f10 <mem_init+0x6f3>
f0101eec:	c7 44 24 0c 87 54 10 	movl   $0xf0105487,0xc(%esp)
f0101ef3:	f0 
f0101ef4:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f0101efb:	f0 
f0101efc:	c7 44 24 04 f1 02 00 	movl   $0x2f1,0x4(%esp)
f0101f03:	00 
f0101f04:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f0101f0b:	e8 84 e1 ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101f10:	39 c7                	cmp    %eax,%edi
f0101f12:	74 04                	je     f0101f18 <mem_init+0x6fb>
f0101f14:	39 c6                	cmp    %eax,%esi
f0101f16:	75 24                	jne    f0101f3c <mem_init+0x71f>
f0101f18:	c7 44 24 0c ac 4d 10 	movl   $0xf0104dac,0xc(%esp)
f0101f1f:	f0 
f0101f20:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f0101f27:	f0 
f0101f28:	c7 44 24 04 f2 02 00 	movl   $0x2f2,0x4(%esp)
f0101f2f:	00 
f0101f30:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f0101f37:	e8 58 e1 ff ff       	call   f0100094 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101f3c:	8b 15 60 95 11 f0    	mov    0xf0119560,%edx
f0101f42:	89 55 cc             	mov    %edx,-0x34(%ebp)
	page_free_list = 0;
f0101f45:	c7 05 60 95 11 f0 00 	movl   $0x0,0xf0119560
f0101f4c:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101f4f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101f56:	e8 31 f5 ff ff       	call   f010148c <page_alloc>
f0101f5b:	85 c0                	test   %eax,%eax
f0101f5d:	74 24                	je     f0101f83 <mem_init+0x766>
f0101f5f:	c7 44 24 0c f0 54 10 	movl   $0xf01054f0,0xc(%esp)
f0101f66:	f0 
f0101f67:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f0101f6e:	f0 
f0101f6f:	c7 44 24 04 f9 02 00 	movl   $0x2f9,0x4(%esp)
f0101f76:	00 
f0101f77:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f0101f7e:	e8 11 e1 ff ff       	call   f0100094 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101f83:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101f86:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101f8a:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101f91:	00 
f0101f92:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f0101f97:	89 04 24             	mov    %eax,(%esp)
f0101f9a:	e8 11 f7 ff ff       	call   f01016b0 <page_lookup>
f0101f9f:	85 c0                	test   %eax,%eax
f0101fa1:	74 24                	je     f0101fc7 <mem_init+0x7aa>
f0101fa3:	c7 44 24 0c ec 4d 10 	movl   $0xf0104dec,0xc(%esp)
f0101faa:	f0 
f0101fab:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f0101fb2:	f0 
f0101fb3:	c7 44 24 04 fc 02 00 	movl   $0x2fc,0x4(%esp)
f0101fba:	00 
f0101fbb:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f0101fc2:	e8 cd e0 ff ff       	call   f0100094 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101fc7:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101fce:	00 
f0101fcf:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101fd6:	00 
f0101fd7:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101fdb:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f0101fe0:	89 04 24             	mov    %eax,(%esp)
f0101fe3:	e8 73 f7 ff ff       	call   f010175b <page_insert>
f0101fe8:	85 c0                	test   %eax,%eax
f0101fea:	78 24                	js     f0102010 <mem_init+0x7f3>
f0101fec:	c7 44 24 0c 24 4e 10 	movl   $0xf0104e24,0xc(%esp)
f0101ff3:	f0 
f0101ff4:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f0101ffb:	f0 
f0101ffc:	c7 44 24 04 ff 02 00 	movl   $0x2ff,0x4(%esp)
f0102003:	00 
f0102004:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f010200b:	e8 84 e0 ff ff       	call   f0100094 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0102010:	89 34 24             	mov    %esi,(%esp)
f0102013:	e8 f5 f4 ff ff       	call   f010150d <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0102018:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f010201f:	00 
f0102020:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102027:	00 
f0102028:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010202c:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f0102031:	89 04 24             	mov    %eax,(%esp)
f0102034:	e8 22 f7 ff ff       	call   f010175b <page_insert>
f0102039:	85 c0                	test   %eax,%eax
f010203b:	74 24                	je     f0102061 <mem_init+0x844>
f010203d:	c7 44 24 0c 54 4e 10 	movl   $0xf0104e54,0xc(%esp)
f0102044:	f0 
f0102045:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f010204c:	f0 
f010204d:	c7 44 24 04 03 03 00 	movl   $0x303,0x4(%esp)
f0102054:	00 
f0102055:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f010205c:	e8 33 e0 ff ff       	call   f0100094 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102061:	8b 0d 88 99 11 f0    	mov    0xf0119988,%ecx
f0102067:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010206a:	a1 8c 99 11 f0       	mov    0xf011998c,%eax
f010206f:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102072:	8b 11                	mov    (%ecx),%edx
f0102074:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010207a:	89 f0                	mov    %esi,%eax
f010207c:	2b 45 d0             	sub    -0x30(%ebp),%eax
f010207f:	c1 f8 03             	sar    $0x3,%eax
f0102082:	c1 e0 0c             	shl    $0xc,%eax
f0102085:	39 c2                	cmp    %eax,%edx
f0102087:	74 24                	je     f01020ad <mem_init+0x890>
f0102089:	c7 44 24 0c 84 4e 10 	movl   $0xf0104e84,0xc(%esp)
f0102090:	f0 
f0102091:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f0102098:	f0 
f0102099:	c7 44 24 04 04 03 00 	movl   $0x304,0x4(%esp)
f01020a0:	00 
f01020a1:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f01020a8:	e8 e7 df ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f01020ad:	ba 00 00 00 00       	mov    $0x0,%edx
f01020b2:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01020b5:	e8 f2 ee ff ff       	call   f0100fac <check_va2pa>
f01020ba:	89 fa                	mov    %edi,%edx
f01020bc:	2b 55 d0             	sub    -0x30(%ebp),%edx
f01020bf:	c1 fa 03             	sar    $0x3,%edx
f01020c2:	c1 e2 0c             	shl    $0xc,%edx
f01020c5:	39 d0                	cmp    %edx,%eax
f01020c7:	74 24                	je     f01020ed <mem_init+0x8d0>
f01020c9:	c7 44 24 0c ac 4e 10 	movl   $0xf0104eac,0xc(%esp)
f01020d0:	f0 
f01020d1:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f01020d8:	f0 
f01020d9:	c7 44 24 04 05 03 00 	movl   $0x305,0x4(%esp)
f01020e0:	00 
f01020e1:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f01020e8:	e8 a7 df ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 1);
f01020ed:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f01020f2:	74 24                	je     f0102118 <mem_init+0x8fb>
f01020f4:	c7 44 24 0c 42 55 10 	movl   $0xf0105542,0xc(%esp)
f01020fb:	f0 
f01020fc:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f0102103:	f0 
f0102104:	c7 44 24 04 06 03 00 	movl   $0x306,0x4(%esp)
f010210b:	00 
f010210c:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f0102113:	e8 7c df ff ff       	call   f0100094 <_panic>
	assert(pp0->pp_ref == 1);
f0102118:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f010211d:	74 24                	je     f0102143 <mem_init+0x926>
f010211f:	c7 44 24 0c 53 55 10 	movl   $0xf0105553,0xc(%esp)
f0102126:	f0 
f0102127:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f010212e:	f0 
f010212f:	c7 44 24 04 07 03 00 	movl   $0x307,0x4(%esp)
f0102136:	00 
f0102137:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f010213e:	e8 51 df ff ff       	call   f0100094 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0102143:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f010214a:	00 
f010214b:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102152:	00 
f0102153:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102157:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f010215a:	89 14 24             	mov    %edx,(%esp)
f010215d:	e8 f9 f5 ff ff       	call   f010175b <page_insert>
f0102162:	85 c0                	test   %eax,%eax
f0102164:	74 24                	je     f010218a <mem_init+0x96d>
f0102166:	c7 44 24 0c dc 4e 10 	movl   $0xf0104edc,0xc(%esp)
f010216d:	f0 
f010216e:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f0102175:	f0 
f0102176:	c7 44 24 04 0a 03 00 	movl   $0x30a,0x4(%esp)
f010217d:	00 
f010217e:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f0102185:	e8 0a df ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f010218a:	ba 00 10 00 00       	mov    $0x1000,%edx
f010218f:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f0102194:	e8 13 ee ff ff       	call   f0100fac <check_va2pa>
f0102199:	89 da                	mov    %ebx,%edx
f010219b:	2b 15 8c 99 11 f0    	sub    0xf011998c,%edx
f01021a1:	c1 fa 03             	sar    $0x3,%edx
f01021a4:	c1 e2 0c             	shl    $0xc,%edx
f01021a7:	39 d0                	cmp    %edx,%eax
f01021a9:	74 24                	je     f01021cf <mem_init+0x9b2>
f01021ab:	c7 44 24 0c 18 4f 10 	movl   $0xf0104f18,0xc(%esp)
f01021b2:	f0 
f01021b3:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f01021ba:	f0 
f01021bb:	c7 44 24 04 0b 03 00 	movl   $0x30b,0x4(%esp)
f01021c2:	00 
f01021c3:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f01021ca:	e8 c5 de ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f01021cf:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01021d4:	74 24                	je     f01021fa <mem_init+0x9dd>
f01021d6:	c7 44 24 0c 64 55 10 	movl   $0xf0105564,0xc(%esp)
f01021dd:	f0 
f01021de:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f01021e5:	f0 
f01021e6:	c7 44 24 04 0c 03 00 	movl   $0x30c,0x4(%esp)
f01021ed:	00 
f01021ee:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f01021f5:	e8 9a de ff ff       	call   f0100094 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f01021fa:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102201:	e8 86 f2 ff ff       	call   f010148c <page_alloc>
f0102206:	85 c0                	test   %eax,%eax
f0102208:	74 24                	je     f010222e <mem_init+0xa11>
f010220a:	c7 44 24 0c f0 54 10 	movl   $0xf01054f0,0xc(%esp)
f0102211:	f0 
f0102212:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f0102219:	f0 
f010221a:	c7 44 24 04 0f 03 00 	movl   $0x30f,0x4(%esp)
f0102221:	00 
f0102222:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f0102229:	e8 66 de ff ff       	call   f0100094 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f010222e:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102235:	00 
f0102236:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010223d:	00 
f010223e:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102242:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f0102247:	89 04 24             	mov    %eax,(%esp)
f010224a:	e8 0c f5 ff ff       	call   f010175b <page_insert>
f010224f:	85 c0                	test   %eax,%eax
f0102251:	74 24                	je     f0102277 <mem_init+0xa5a>
f0102253:	c7 44 24 0c dc 4e 10 	movl   $0xf0104edc,0xc(%esp)
f010225a:	f0 
f010225b:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f0102262:	f0 
f0102263:	c7 44 24 04 12 03 00 	movl   $0x312,0x4(%esp)
f010226a:	00 
f010226b:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f0102272:	e8 1d de ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0102277:	ba 00 10 00 00       	mov    $0x1000,%edx
f010227c:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f0102281:	e8 26 ed ff ff       	call   f0100fac <check_va2pa>
f0102286:	89 da                	mov    %ebx,%edx
f0102288:	2b 15 8c 99 11 f0    	sub    0xf011998c,%edx
f010228e:	c1 fa 03             	sar    $0x3,%edx
f0102291:	c1 e2 0c             	shl    $0xc,%edx
f0102294:	39 d0                	cmp    %edx,%eax
f0102296:	74 24                	je     f01022bc <mem_init+0xa9f>
f0102298:	c7 44 24 0c 18 4f 10 	movl   $0xf0104f18,0xc(%esp)
f010229f:	f0 
f01022a0:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f01022a7:	f0 
f01022a8:	c7 44 24 04 13 03 00 	movl   $0x313,0x4(%esp)
f01022af:	00 
f01022b0:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f01022b7:	e8 d8 dd ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f01022bc:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01022c1:	74 24                	je     f01022e7 <mem_init+0xaca>
f01022c3:	c7 44 24 0c 64 55 10 	movl   $0xf0105564,0xc(%esp)
f01022ca:	f0 
f01022cb:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f01022d2:	f0 
f01022d3:	c7 44 24 04 14 03 00 	movl   $0x314,0x4(%esp)
f01022da:	00 
f01022db:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f01022e2:	e8 ad dd ff ff       	call   f0100094 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f01022e7:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01022ee:	e8 99 f1 ff ff       	call   f010148c <page_alloc>
f01022f3:	85 c0                	test   %eax,%eax
f01022f5:	74 24                	je     f010231b <mem_init+0xafe>
f01022f7:	c7 44 24 0c f0 54 10 	movl   $0xf01054f0,0xc(%esp)
f01022fe:	f0 
f01022ff:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f0102306:	f0 
f0102307:	c7 44 24 04 18 03 00 	movl   $0x318,0x4(%esp)
f010230e:	00 
f010230f:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f0102316:	e8 79 dd ff ff       	call   f0100094 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f010231b:	8b 15 88 99 11 f0    	mov    0xf0119988,%edx
f0102321:	8b 02                	mov    (%edx),%eax
f0102323:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102328:	89 c1                	mov    %eax,%ecx
f010232a:	c1 e9 0c             	shr    $0xc,%ecx
f010232d:	3b 0d 84 99 11 f0    	cmp    0xf0119984,%ecx
f0102333:	72 20                	jb     f0102355 <mem_init+0xb38>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102335:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102339:	c7 44 24 08 68 4c 10 	movl   $0xf0104c68,0x8(%esp)
f0102340:	f0 
f0102341:	c7 44 24 04 1b 03 00 	movl   $0x31b,0x4(%esp)
f0102348:	00 
f0102349:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f0102350:	e8 3f dd ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0102355:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010235a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f010235d:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102364:	00 
f0102365:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f010236c:	00 
f010236d:	89 14 24             	mov    %edx,(%esp)
f0102370:	e8 d0 f1 ff ff       	call   f0101545 <pgdir_walk>
f0102375:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0102378:	83 c2 04             	add    $0x4,%edx
f010237b:	39 d0                	cmp    %edx,%eax
f010237d:	74 24                	je     f01023a3 <mem_init+0xb86>
f010237f:	c7 44 24 0c 48 4f 10 	movl   $0xf0104f48,0xc(%esp)
f0102386:	f0 
f0102387:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f010238e:	f0 
f010238f:	c7 44 24 04 1c 03 00 	movl   $0x31c,0x4(%esp)
f0102396:	00 
f0102397:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f010239e:	e8 f1 dc ff ff       	call   f0100094 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f01023a3:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f01023aa:	00 
f01023ab:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01023b2:	00 
f01023b3:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01023b7:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f01023bc:	89 04 24             	mov    %eax,(%esp)
f01023bf:	e8 97 f3 ff ff       	call   f010175b <page_insert>
f01023c4:	85 c0                	test   %eax,%eax
f01023c6:	74 24                	je     f01023ec <mem_init+0xbcf>
f01023c8:	c7 44 24 0c 88 4f 10 	movl   $0xf0104f88,0xc(%esp)
f01023cf:	f0 
f01023d0:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f01023d7:	f0 
f01023d8:	c7 44 24 04 1f 03 00 	movl   $0x31f,0x4(%esp)
f01023df:	00 
f01023e0:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f01023e7:	e8 a8 dc ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01023ec:	8b 0d 88 99 11 f0    	mov    0xf0119988,%ecx
f01023f2:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f01023f5:	ba 00 10 00 00       	mov    $0x1000,%edx
f01023fa:	89 c8                	mov    %ecx,%eax
f01023fc:	e8 ab eb ff ff       	call   f0100fac <check_va2pa>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102401:	89 da                	mov    %ebx,%edx
f0102403:	2b 15 8c 99 11 f0    	sub    0xf011998c,%edx
f0102409:	c1 fa 03             	sar    $0x3,%edx
f010240c:	c1 e2 0c             	shl    $0xc,%edx
f010240f:	39 d0                	cmp    %edx,%eax
f0102411:	74 24                	je     f0102437 <mem_init+0xc1a>
f0102413:	c7 44 24 0c 18 4f 10 	movl   $0xf0104f18,0xc(%esp)
f010241a:	f0 
f010241b:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f0102422:	f0 
f0102423:	c7 44 24 04 20 03 00 	movl   $0x320,0x4(%esp)
f010242a:	00 
f010242b:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f0102432:	e8 5d dc ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0102437:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f010243c:	74 24                	je     f0102462 <mem_init+0xc45>
f010243e:	c7 44 24 0c 64 55 10 	movl   $0xf0105564,0xc(%esp)
f0102445:	f0 
f0102446:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f010244d:	f0 
f010244e:	c7 44 24 04 21 03 00 	movl   $0x321,0x4(%esp)
f0102455:	00 
f0102456:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f010245d:	e8 32 dc ff ff       	call   f0100094 <_panic>

	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f0102462:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102469:	00 
f010246a:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102471:	00 
f0102472:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102475:	89 04 24             	mov    %eax,(%esp)
f0102478:	e8 c8 f0 ff ff       	call   f0101545 <pgdir_walk>
f010247d:	f6 00 04             	testb  $0x4,(%eax)
f0102480:	75 24                	jne    f01024a6 <mem_init+0xc89>
f0102482:	c7 44 24 0c c8 4f 10 	movl   $0xf0104fc8,0xc(%esp)
f0102489:	f0 
f010248a:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f0102491:	f0 
f0102492:	c7 44 24 04 23 03 00 	movl   $0x323,0x4(%esp)
f0102499:	00 
f010249a:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f01024a1:	e8 ee db ff ff       	call   f0100094 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f01024a6:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f01024ab:	f6 00 04             	testb  $0x4,(%eax)
f01024ae:	75 24                	jne    f01024d4 <mem_init+0xcb7>
f01024b0:	c7 44 24 0c 75 55 10 	movl   $0xf0105575,0xc(%esp)
f01024b7:	f0 
f01024b8:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f01024bf:	f0 
f01024c0:	c7 44 24 04 24 03 00 	movl   $0x324,0x4(%esp)
f01024c7:	00 
f01024c8:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f01024cf:	e8 c0 db ff ff       	call   f0100094 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01024d4:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01024db:	00 
f01024dc:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01024e3:	00 
f01024e4:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01024e8:	89 04 24             	mov    %eax,(%esp)
f01024eb:	e8 6b f2 ff ff       	call   f010175b <page_insert>
f01024f0:	85 c0                	test   %eax,%eax
f01024f2:	74 24                	je     f0102518 <mem_init+0xcfb>
f01024f4:	c7 44 24 0c dc 4e 10 	movl   $0xf0104edc,0xc(%esp)
f01024fb:	f0 
f01024fc:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f0102503:	f0 
f0102504:	c7 44 24 04 27 03 00 	movl   $0x327,0x4(%esp)
f010250b:	00 
f010250c:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f0102513:	e8 7c db ff ff       	call   f0100094 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0102518:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f010251f:	00 
f0102520:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102527:	00 
f0102528:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f010252d:	89 04 24             	mov    %eax,(%esp)
f0102530:	e8 10 f0 ff ff       	call   f0101545 <pgdir_walk>
f0102535:	f6 00 02             	testb  $0x2,(%eax)
f0102538:	75 24                	jne    f010255e <mem_init+0xd41>
f010253a:	c7 44 24 0c fc 4f 10 	movl   $0xf0104ffc,0xc(%esp)
f0102541:	f0 
f0102542:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f0102549:	f0 
f010254a:	c7 44 24 04 28 03 00 	movl   $0x328,0x4(%esp)
f0102551:	00 
f0102552:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f0102559:	e8 36 db ff ff       	call   f0100094 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f010255e:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102565:	00 
f0102566:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f010256d:	00 
f010256e:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f0102573:	89 04 24             	mov    %eax,(%esp)
f0102576:	e8 ca ef ff ff       	call   f0101545 <pgdir_walk>
f010257b:	f6 00 04             	testb  $0x4,(%eax)
f010257e:	74 24                	je     f01025a4 <mem_init+0xd87>
f0102580:	c7 44 24 0c 30 50 10 	movl   $0xf0105030,0xc(%esp)
f0102587:	f0 
f0102588:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f010258f:	f0 
f0102590:	c7 44 24 04 29 03 00 	movl   $0x329,0x4(%esp)
f0102597:	00 
f0102598:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f010259f:	e8 f0 da ff ff       	call   f0100094 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f01025a4:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01025ab:	00 
f01025ac:	c7 44 24 08 00 00 40 	movl   $0x400000,0x8(%esp)
f01025b3:	00 
f01025b4:	89 74 24 04          	mov    %esi,0x4(%esp)
f01025b8:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f01025bd:	89 04 24             	mov    %eax,(%esp)
f01025c0:	e8 96 f1 ff ff       	call   f010175b <page_insert>
f01025c5:	85 c0                	test   %eax,%eax
f01025c7:	78 24                	js     f01025ed <mem_init+0xdd0>
f01025c9:	c7 44 24 0c 68 50 10 	movl   $0xf0105068,0xc(%esp)
f01025d0:	f0 
f01025d1:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f01025d8:	f0 
f01025d9:	c7 44 24 04 2c 03 00 	movl   $0x32c,0x4(%esp)
f01025e0:	00 
f01025e1:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f01025e8:	e8 a7 da ff ff       	call   f0100094 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
//	cprintf("~~w");
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f01025ed:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01025f4:	00 
f01025f5:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01025fc:	00 
f01025fd:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0102601:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f0102606:	89 04 24             	mov    %eax,(%esp)
f0102609:	e8 4d f1 ff ff       	call   f010175b <page_insert>
f010260e:	85 c0                	test   %eax,%eax
f0102610:	74 24                	je     f0102636 <mem_init+0xe19>
f0102612:	c7 44 24 0c a0 50 10 	movl   $0xf01050a0,0xc(%esp)
f0102619:	f0 
f010261a:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f0102621:	f0 
f0102622:	c7 44 24 04 30 03 00 	movl   $0x330,0x4(%esp)
f0102629:	00 
f010262a:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f0102631:	e8 5e da ff ff       	call   f0100094 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0102636:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f010263d:	00 
f010263e:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102645:	00 
f0102646:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f010264b:	89 04 24             	mov    %eax,(%esp)
f010264e:	e8 f2 ee ff ff       	call   f0101545 <pgdir_walk>
f0102653:	f6 00 04             	testb  $0x4,(%eax)
f0102656:	74 24                	je     f010267c <mem_init+0xe5f>
f0102658:	c7 44 24 0c 30 50 10 	movl   $0xf0105030,0xc(%esp)
f010265f:	f0 
f0102660:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f0102667:	f0 
f0102668:	c7 44 24 04 31 03 00 	movl   $0x331,0x4(%esp)
f010266f:	00 
f0102670:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f0102677:	e8 18 da ff ff       	call   f0100094 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f010267c:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f0102681:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102684:	ba 00 00 00 00       	mov    $0x0,%edx
f0102689:	e8 1e e9 ff ff       	call   f0100fac <check_va2pa>
f010268e:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102691:	89 f8                	mov    %edi,%eax
f0102693:	2b 05 8c 99 11 f0    	sub    0xf011998c,%eax
f0102699:	c1 f8 03             	sar    $0x3,%eax
f010269c:	c1 e0 0c             	shl    $0xc,%eax
f010269f:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f01026a2:	74 24                	je     f01026c8 <mem_init+0xeab>
f01026a4:	c7 44 24 0c dc 50 10 	movl   $0xf01050dc,0xc(%esp)
f01026ab:	f0 
f01026ac:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f01026b3:	f0 
f01026b4:	c7 44 24 04 34 03 00 	movl   $0x334,0x4(%esp)
f01026bb:	00 
f01026bc:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f01026c3:	e8 cc d9 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01026c8:	ba 00 10 00 00       	mov    $0x1000,%edx
f01026cd:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01026d0:	e8 d7 e8 ff ff       	call   f0100fac <check_va2pa>
f01026d5:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f01026d8:	74 24                	je     f01026fe <mem_init+0xee1>
f01026da:	c7 44 24 0c 08 51 10 	movl   $0xf0105108,0xc(%esp)
f01026e1:	f0 
f01026e2:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f01026e9:	f0 
f01026ea:	c7 44 24 04 35 03 00 	movl   $0x335,0x4(%esp)
f01026f1:	00 
f01026f2:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f01026f9:	e8 96 d9 ff ff       	call   f0100094 <_panic>
	// ... and ref counts should reflect this
//	cprintf("%d %d", pp1->pp_ref, pp2->pp_ref);
	assert(pp1->pp_ref == 2);
f01026fe:	66 83 7f 04 02       	cmpw   $0x2,0x4(%edi)
f0102703:	74 24                	je     f0102729 <mem_init+0xf0c>
f0102705:	c7 44 24 0c 8b 55 10 	movl   $0xf010558b,0xc(%esp)
f010270c:	f0 
f010270d:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f0102714:	f0 
f0102715:	c7 44 24 04 38 03 00 	movl   $0x338,0x4(%esp)
f010271c:	00 
f010271d:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f0102724:	e8 6b d9 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f0102729:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f010272e:	74 24                	je     f0102754 <mem_init+0xf37>
f0102730:	c7 44 24 0c 9c 55 10 	movl   $0xf010559c,0xc(%esp)
f0102737:	f0 
f0102738:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f010273f:	f0 
f0102740:	c7 44 24 04 39 03 00 	movl   $0x339,0x4(%esp)
f0102747:	00 
f0102748:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f010274f:	e8 40 d9 ff ff       	call   f0100094 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f0102754:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010275b:	e8 2c ed ff ff       	call   f010148c <page_alloc>
f0102760:	85 c0                	test   %eax,%eax
f0102762:	74 04                	je     f0102768 <mem_init+0xf4b>
f0102764:	39 c3                	cmp    %eax,%ebx
f0102766:	74 24                	je     f010278c <mem_init+0xf6f>
f0102768:	c7 44 24 0c 38 51 10 	movl   $0xf0105138,0xc(%esp)
f010276f:	f0 
f0102770:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f0102777:	f0 
f0102778:	c7 44 24 04 3c 03 00 	movl   $0x33c,0x4(%esp)
f010277f:	00 
f0102780:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f0102787:	e8 08 d9 ff ff       	call   f0100094 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f010278c:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102793:	00 
f0102794:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f0102799:	89 04 24             	mov    %eax,(%esp)
f010279c:	e8 7c ef ff ff       	call   f010171d <page_remove>
//	cprintf("~~~");
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f01027a1:	8b 15 88 99 11 f0    	mov    0xf0119988,%edx
f01027a7:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f01027aa:	ba 00 00 00 00       	mov    $0x0,%edx
f01027af:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01027b2:	e8 f5 e7 ff ff       	call   f0100fac <check_va2pa>
f01027b7:	83 f8 ff             	cmp    $0xffffffff,%eax
f01027ba:	74 24                	je     f01027e0 <mem_init+0xfc3>
f01027bc:	c7 44 24 0c 5c 51 10 	movl   $0xf010515c,0xc(%esp)
f01027c3:	f0 
f01027c4:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f01027cb:	f0 
f01027cc:	c7 44 24 04 41 03 00 	movl   $0x341,0x4(%esp)
f01027d3:	00 
f01027d4:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f01027db:	e8 b4 d8 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01027e0:	ba 00 10 00 00       	mov    $0x1000,%edx
f01027e5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01027e8:	e8 bf e7 ff ff       	call   f0100fac <check_va2pa>
f01027ed:	89 fa                	mov    %edi,%edx
f01027ef:	2b 15 8c 99 11 f0    	sub    0xf011998c,%edx
f01027f5:	c1 fa 03             	sar    $0x3,%edx
f01027f8:	c1 e2 0c             	shl    $0xc,%edx
f01027fb:	39 d0                	cmp    %edx,%eax
f01027fd:	74 24                	je     f0102823 <mem_init+0x1006>
f01027ff:	c7 44 24 0c 08 51 10 	movl   $0xf0105108,0xc(%esp)
f0102806:	f0 
f0102807:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f010280e:	f0 
f010280f:	c7 44 24 04 42 03 00 	movl   $0x342,0x4(%esp)
f0102816:	00 
f0102817:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f010281e:	e8 71 d8 ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 1);
f0102823:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102828:	74 24                	je     f010284e <mem_init+0x1031>
f010282a:	c7 44 24 0c 42 55 10 	movl   $0xf0105542,0xc(%esp)
f0102831:	f0 
f0102832:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f0102839:	f0 
f010283a:	c7 44 24 04 43 03 00 	movl   $0x343,0x4(%esp)
f0102841:	00 
f0102842:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f0102849:	e8 46 d8 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f010284e:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102853:	74 24                	je     f0102879 <mem_init+0x105c>
f0102855:	c7 44 24 0c 9c 55 10 	movl   $0xf010559c,0xc(%esp)
f010285c:	f0 
f010285d:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f0102864:	f0 
f0102865:	c7 44 24 04 44 03 00 	movl   $0x344,0x4(%esp)
f010286c:	00 
f010286d:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f0102874:	e8 1b d8 ff ff       	call   f0100094 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102879:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102880:	00 
f0102881:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0102884:	89 0c 24             	mov    %ecx,(%esp)
f0102887:	e8 91 ee ff ff       	call   f010171d <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f010288c:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f0102891:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102894:	ba 00 00 00 00       	mov    $0x0,%edx
f0102899:	e8 0e e7 ff ff       	call   f0100fac <check_va2pa>
f010289e:	83 f8 ff             	cmp    $0xffffffff,%eax
f01028a1:	74 24                	je     f01028c7 <mem_init+0x10aa>
f01028a3:	c7 44 24 0c 5c 51 10 	movl   $0xf010515c,0xc(%esp)
f01028aa:	f0 
f01028ab:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f01028b2:	f0 
f01028b3:	c7 44 24 04 48 03 00 	movl   $0x348,0x4(%esp)
f01028ba:	00 
f01028bb:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f01028c2:	e8 cd d7 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f01028c7:	ba 00 10 00 00       	mov    $0x1000,%edx
f01028cc:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01028cf:	e8 d8 e6 ff ff       	call   f0100fac <check_va2pa>
f01028d4:	83 f8 ff             	cmp    $0xffffffff,%eax
f01028d7:	74 24                	je     f01028fd <mem_init+0x10e0>
f01028d9:	c7 44 24 0c 80 51 10 	movl   $0xf0105180,0xc(%esp)
f01028e0:	f0 
f01028e1:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f01028e8:	f0 
f01028e9:	c7 44 24 04 49 03 00 	movl   $0x349,0x4(%esp)
f01028f0:	00 
f01028f1:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f01028f8:	e8 97 d7 ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 0);
f01028fd:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102902:	74 24                	je     f0102928 <mem_init+0x110b>
f0102904:	c7 44 24 0c ad 55 10 	movl   $0xf01055ad,0xc(%esp)
f010290b:	f0 
f010290c:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f0102913:	f0 
f0102914:	c7 44 24 04 4a 03 00 	movl   $0x34a,0x4(%esp)
f010291b:	00 
f010291c:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f0102923:	e8 6c d7 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f0102928:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f010292d:	74 24                	je     f0102953 <mem_init+0x1136>
f010292f:	c7 44 24 0c 9c 55 10 	movl   $0xf010559c,0xc(%esp)
f0102936:	f0 
f0102937:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f010293e:	f0 
f010293f:	c7 44 24 04 4b 03 00 	movl   $0x34b,0x4(%esp)
f0102946:	00 
f0102947:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f010294e:	e8 41 d7 ff ff       	call   f0100094 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0102953:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010295a:	e8 2d eb ff ff       	call   f010148c <page_alloc>
f010295f:	85 c0                	test   %eax,%eax
f0102961:	74 04                	je     f0102967 <mem_init+0x114a>
f0102963:	39 c7                	cmp    %eax,%edi
f0102965:	74 24                	je     f010298b <mem_init+0x116e>
f0102967:	c7 44 24 0c a8 51 10 	movl   $0xf01051a8,0xc(%esp)
f010296e:	f0 
f010296f:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f0102976:	f0 
f0102977:	c7 44 24 04 4e 03 00 	movl   $0x34e,0x4(%esp)
f010297e:	00 
f010297f:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f0102986:	e8 09 d7 ff ff       	call   f0100094 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f010298b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102992:	e8 f5 ea ff ff       	call   f010148c <page_alloc>
f0102997:	85 c0                	test   %eax,%eax
f0102999:	74 24                	je     f01029bf <mem_init+0x11a2>
f010299b:	c7 44 24 0c f0 54 10 	movl   $0xf01054f0,0xc(%esp)
f01029a2:	f0 
f01029a3:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f01029aa:	f0 
f01029ab:	c7 44 24 04 51 03 00 	movl   $0x351,0x4(%esp)
f01029b2:	00 
f01029b3:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f01029ba:	e8 d5 d6 ff ff       	call   f0100094 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01029bf:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f01029c4:	8b 08                	mov    (%eax),%ecx
f01029c6:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f01029cc:	89 f2                	mov    %esi,%edx
f01029ce:	2b 15 8c 99 11 f0    	sub    0xf011998c,%edx
f01029d4:	c1 fa 03             	sar    $0x3,%edx
f01029d7:	c1 e2 0c             	shl    $0xc,%edx
f01029da:	39 d1                	cmp    %edx,%ecx
f01029dc:	74 24                	je     f0102a02 <mem_init+0x11e5>
f01029de:	c7 44 24 0c 84 4e 10 	movl   $0xf0104e84,0xc(%esp)
f01029e5:	f0 
f01029e6:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f01029ed:	f0 
f01029ee:	c7 44 24 04 54 03 00 	movl   $0x354,0x4(%esp)
f01029f5:	00 
f01029f6:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f01029fd:	e8 92 d6 ff ff       	call   f0100094 <_panic>
	kern_pgdir[0] = 0;
f0102a02:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f0102a08:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102a0d:	74 24                	je     f0102a33 <mem_init+0x1216>
f0102a0f:	c7 44 24 0c 53 55 10 	movl   $0xf0105553,0xc(%esp)
f0102a16:	f0 
f0102a17:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f0102a1e:	f0 
f0102a1f:	c7 44 24 04 56 03 00 	movl   $0x356,0x4(%esp)
f0102a26:	00 
f0102a27:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f0102a2e:	e8 61 d6 ff ff       	call   f0100094 <_panic>
	pp0->pp_ref = 0;
f0102a33:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0102a39:	89 34 24             	mov    %esi,(%esp)
f0102a3c:	e8 cc ea ff ff       	call   f010150d <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0102a41:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0102a48:	00 
f0102a49:	c7 44 24 04 00 10 40 	movl   $0x401000,0x4(%esp)
f0102a50:	00 
f0102a51:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f0102a56:	89 04 24             	mov    %eax,(%esp)
f0102a59:	e8 e7 ea ff ff       	call   f0101545 <pgdir_walk>
f0102a5e:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0102a61:	8b 0d 88 99 11 f0    	mov    0xf0119988,%ecx
f0102a67:	8b 51 04             	mov    0x4(%ecx),%edx
f0102a6a:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102a70:	89 55 d4             	mov    %edx,-0x2c(%ebp)
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102a73:	8b 15 84 99 11 f0    	mov    0xf0119984,%edx
f0102a79:	89 55 c8             	mov    %edx,-0x38(%ebp)
f0102a7c:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0102a7f:	c1 ea 0c             	shr    $0xc,%edx
f0102a82:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0102a85:	8b 55 c8             	mov    -0x38(%ebp),%edx
f0102a88:	39 55 d0             	cmp    %edx,-0x30(%ebp)
f0102a8b:	72 23                	jb     f0102ab0 <mem_init+0x1293>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102a8d:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0102a90:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0102a94:	c7 44 24 08 68 4c 10 	movl   $0xf0104c68,0x8(%esp)
f0102a9b:	f0 
f0102a9c:	c7 44 24 04 5d 03 00 	movl   $0x35d,0x4(%esp)
f0102aa3:	00 
f0102aa4:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f0102aab:	e8 e4 d5 ff ff       	call   f0100094 <_panic>
	assert(ptep == ptep1 + PTX(va));
f0102ab0:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0102ab3:	81 ea fc ff ff 0f    	sub    $0xffffffc,%edx
f0102ab9:	39 d0                	cmp    %edx,%eax
f0102abb:	74 24                	je     f0102ae1 <mem_init+0x12c4>
f0102abd:	c7 44 24 0c be 55 10 	movl   $0xf01055be,0xc(%esp)
f0102ac4:	f0 
f0102ac5:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f0102acc:	f0 
f0102acd:	c7 44 24 04 5e 03 00 	movl   $0x35e,0x4(%esp)
f0102ad4:	00 
f0102ad5:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f0102adc:	e8 b3 d5 ff ff       	call   f0100094 <_panic>
	kern_pgdir[PDX(va)] = 0;
f0102ae1:	c7 41 04 00 00 00 00 	movl   $0x0,0x4(%ecx)
	pp0->pp_ref = 0;
f0102ae8:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102aee:	89 f0                	mov    %esi,%eax
f0102af0:	2b 05 8c 99 11 f0    	sub    0xf011998c,%eax
f0102af6:	c1 f8 03             	sar    $0x3,%eax
f0102af9:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102afc:	89 c1                	mov    %eax,%ecx
f0102afe:	c1 e9 0c             	shr    $0xc,%ecx
f0102b01:	39 4d c8             	cmp    %ecx,-0x38(%ebp)
f0102b04:	77 20                	ja     f0102b26 <mem_init+0x1309>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102b06:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102b0a:	c7 44 24 08 68 4c 10 	movl   $0xf0104c68,0x8(%esp)
f0102b11:	f0 
f0102b12:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0102b19:	00 
f0102b1a:	c7 04 24 6c 53 10 f0 	movl   $0xf010536c,(%esp)
f0102b21:	e8 6e d5 ff ff       	call   f0100094 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0102b26:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102b2d:	00 
f0102b2e:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
f0102b35:	00 
	return (void *)(pa + KERNBASE);
f0102b36:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102b3b:	89 04 24             	mov    %eax,(%esp)
f0102b3e:	e8 7e 14 00 00       	call   f0103fc1 <memset>
	page_free(pp0);
f0102b43:	89 34 24             	mov    %esi,(%esp)
f0102b46:	e8 c2 e9 ff ff       	call   f010150d <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0102b4b:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0102b52:	00 
f0102b53:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102b5a:	00 
f0102b5b:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f0102b60:	89 04 24             	mov    %eax,(%esp)
f0102b63:	e8 dd e9 ff ff       	call   f0101545 <pgdir_walk>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102b68:	89 f2                	mov    %esi,%edx
f0102b6a:	2b 15 8c 99 11 f0    	sub    0xf011998c,%edx
f0102b70:	c1 fa 03             	sar    $0x3,%edx
f0102b73:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102b76:	89 d0                	mov    %edx,%eax
f0102b78:	c1 e8 0c             	shr    $0xc,%eax
f0102b7b:	3b 05 84 99 11 f0    	cmp    0xf0119984,%eax
f0102b81:	72 20                	jb     f0102ba3 <mem_init+0x1386>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102b83:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0102b87:	c7 44 24 08 68 4c 10 	movl   $0xf0104c68,0x8(%esp)
f0102b8e:	f0 
f0102b8f:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0102b96:	00 
f0102b97:	c7 04 24 6c 53 10 f0 	movl   $0xf010536c,(%esp)
f0102b9e:	e8 f1 d4 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0102ba3:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f0102ba9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102bac:	f6 82 00 00 00 f0 01 	testb  $0x1,-0x10000000(%edx)
f0102bb3:	75 11                	jne    f0102bc6 <mem_init+0x13a9>
f0102bb5:	8d 82 04 00 00 f0    	lea    -0xffffffc(%edx),%eax
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0102bbb:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102bc1:	f6 00 01             	testb  $0x1,(%eax)
f0102bc4:	74 24                	je     f0102bea <mem_init+0x13cd>
f0102bc6:	c7 44 24 0c d6 55 10 	movl   $0xf01055d6,0xc(%esp)
f0102bcd:	f0 
f0102bce:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f0102bd5:	f0 
f0102bd6:	c7 44 24 04 68 03 00 	movl   $0x368,0x4(%esp)
f0102bdd:	00 
f0102bde:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f0102be5:	e8 aa d4 ff ff       	call   f0100094 <_panic>
f0102bea:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f0102bed:	39 d0                	cmp    %edx,%eax
f0102bef:	75 d0                	jne    f0102bc1 <mem_init+0x13a4>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f0102bf1:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f0102bf6:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102bfc:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// give free list back
	page_free_list = fl;
f0102c02:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0102c05:	89 0d 60 95 11 f0    	mov    %ecx,0xf0119560

	// free the pages we took
	page_free(pp0);
f0102c0b:	89 34 24             	mov    %esi,(%esp)
f0102c0e:	e8 fa e8 ff ff       	call   f010150d <page_free>
	page_free(pp1);
f0102c13:	89 3c 24             	mov    %edi,(%esp)
f0102c16:	e8 f2 e8 ff ff       	call   f010150d <page_free>
	page_free(pp2);
f0102c1b:	89 1c 24             	mov    %ebx,(%esp)
f0102c1e:	e8 ea e8 ff ff       	call   f010150d <page_free>

	cprintf("check_page() succeeded!\n");
f0102c23:	c7 04 24 ed 55 10 f0 	movl   $0xf01055ed,(%esp)
f0102c2a:	e8 cf 07 00 00       	call   f01033fe <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, UPAGES, ROUNDUP(npages * sizeof(struct PageInfo), PGSIZE), PADDR(pages), PTE_U | PTE_P);
f0102c2f:	a1 8c 99 11 f0       	mov    0xf011998c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102c34:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102c39:	77 20                	ja     f0102c5b <mem_init+0x143e>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102c3b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102c3f:	c7 44 24 08 74 4a 10 	movl   $0xf0104a74,0x8(%esp)
f0102c46:	f0 
f0102c47:	c7 44 24 04 b2 00 00 	movl   $0xb2,0x4(%esp)
f0102c4e:	00 
f0102c4f:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f0102c56:	e8 39 d4 ff ff       	call   f0100094 <_panic>
f0102c5b:	8b 15 84 99 11 f0    	mov    0xf0119984,%edx
f0102c61:	8d 0c d5 ff 0f 00 00 	lea    0xfff(,%edx,8),%ecx
f0102c68:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0102c6e:	c7 44 24 04 05 00 00 	movl   $0x5,0x4(%esp)
f0102c75:	00 
	return (physaddr_t)kva - KERNBASE;
f0102c76:	05 00 00 00 10       	add    $0x10000000,%eax
f0102c7b:	89 04 24             	mov    %eax,(%esp)
f0102c7e:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102c83:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f0102c88:	e8 a7 e9 ff ff       	call   f0101634 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102c8d:	be 00 f0 10 f0       	mov    $0xf010f000,%esi
f0102c92:	81 fe ff ff ff ef    	cmp    $0xefffffff,%esi
f0102c98:	77 20                	ja     f0102cba <mem_init+0x149d>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102c9a:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0102c9e:	c7 44 24 08 74 4a 10 	movl   $0xf0104a74,0x8(%esp)
f0102ca5:	f0 
f0102ca6:	c7 44 24 04 bf 00 00 	movl   $0xbf,0x4(%esp)
f0102cad:	00 
f0102cae:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f0102cb5:	e8 da d3 ff ff       	call   f0100094 <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KSTACKTOP - KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W);
f0102cba:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f0102cc1:	00 
f0102cc2:	c7 04 24 00 f0 10 00 	movl   $0x10f000,(%esp)
f0102cc9:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102cce:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f0102cd3:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f0102cd8:	e8 57 e9 ff ff       	call   f0101634 <boot_map_region>
	//      the PA range [0, 2^32 - KERNBASE)
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KERNBASE, /*(1 << 32)*/ - KERNBASE, 0, PTE_W); 
f0102cdd:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f0102ce4:	00 
f0102ce5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102cec:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f0102cf1:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0102cf6:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f0102cfb:	e8 34 e9 ff ff       	call   f0101634 <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f0102d00:	8b 1d 88 99 11 f0    	mov    0xf0119988,%ebx

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0102d06:	8b 35 84 99 11 f0    	mov    0xf0119984,%esi
f0102d0c:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f0102d0f:	8d 3c f5 ff 0f 00 00 	lea    0xfff(,%esi,8),%edi
	for (i = 0; i < n; i += PGSIZE) {
f0102d16:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
f0102d1c:	74 79                	je     f0102d97 <mem_init+0x157a>
f0102d1e:	be 00 00 00 00       	mov    $0x0,%esi
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0102d23:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx
	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE) {
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102d29:	89 d8                	mov    %ebx,%eax
f0102d2b:	e8 7c e2 ff ff       	call   f0100fac <check_va2pa>
f0102d30:	8b 15 8c 99 11 f0    	mov    0xf011998c,%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102d36:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0102d3c:	77 20                	ja     f0102d5e <mem_init+0x1541>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102d3e:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0102d42:	c7 44 24 08 74 4a 10 	movl   $0xf0104a74,0x8(%esp)
f0102d49:	f0 
f0102d4a:	c7 44 24 04 a8 02 00 	movl   $0x2a8,0x4(%esp)
f0102d51:	00 
f0102d52:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f0102d59:	e8 36 d3 ff ff       	call   f0100094 <_panic>
f0102d5e:	8d 94 32 00 00 00 10 	lea    0x10000000(%edx,%esi,1),%edx
f0102d65:	39 d0                	cmp    %edx,%eax
f0102d67:	74 24                	je     f0102d8d <mem_init+0x1570>
f0102d69:	c7 44 24 0c cc 51 10 	movl   $0xf01051cc,0xc(%esp)
f0102d70:	f0 
f0102d71:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f0102d78:	f0 
f0102d79:	c7 44 24 04 a8 02 00 	movl   $0x2a8,0x4(%esp)
f0102d80:	00 
f0102d81:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f0102d88:	e8 07 d3 ff ff       	call   f0100094 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE) {
f0102d8d:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102d93:	39 f7                	cmp    %esi,%edi
f0102d95:	77 8c                	ja     f0102d23 <mem_init+0x1506>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
	}


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102d97:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102d9a:	c1 e7 0c             	shl    $0xc,%edi
f0102d9d:	85 ff                	test   %edi,%edi
f0102d9f:	74 44                	je     f0102de5 <mem_init+0x15c8>
f0102da1:	be 00 00 00 00       	mov    $0x0,%esi
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0102da6:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
	}


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102dac:	89 d8                	mov    %ebx,%eax
f0102dae:	e8 f9 e1 ff ff       	call   f0100fac <check_va2pa>
f0102db3:	39 c6                	cmp    %eax,%esi
f0102db5:	74 24                	je     f0102ddb <mem_init+0x15be>
f0102db7:	c7 44 24 0c 00 52 10 	movl   $0xf0105200,0xc(%esp)
f0102dbe:	f0 
f0102dbf:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f0102dc6:	f0 
f0102dc7:	c7 44 24 04 ae 02 00 	movl   $0x2ae,0x4(%esp)
f0102dce:	00 
f0102dcf:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f0102dd6:	e8 b9 d2 ff ff       	call   f0100094 <_panic>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
	}


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102ddb:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102de1:	39 fe                	cmp    %edi,%esi
f0102de3:	72 c1                	jb     f0102da6 <mem_init+0x1589>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102de5:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f0102dea:	89 d8                	mov    %ebx,%eax
f0102dec:	e8 bb e1 ff ff       	call   f0100fac <check_va2pa>
f0102df1:	be 00 90 ff ef       	mov    $0xefff9000,%esi
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0102df6:	bf 00 f0 10 f0       	mov    $0xf010f000,%edi
f0102dfb:	81 c7 00 70 00 20    	add    $0x20007000,%edi
f0102e01:	8d 14 37             	lea    (%edi,%esi,1),%edx
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102e04:	39 c2                	cmp    %eax,%edx
f0102e06:	74 24                	je     f0102e2c <mem_init+0x160f>
f0102e08:	c7 44 24 0c 28 52 10 	movl   $0xf0105228,0xc(%esp)
f0102e0f:	f0 
f0102e10:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f0102e17:	f0 
f0102e18:	c7 44 24 04 b2 02 00 	movl   $0x2b2,0x4(%esp)
f0102e1f:	00 
f0102e20:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f0102e27:	e8 68 d2 ff ff       	call   f0100094 <_panic>
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0102e2c:	81 fe 00 00 00 f0    	cmp    $0xf0000000,%esi
f0102e32:	0f 85 37 05 00 00    	jne    f010336f <mem_init+0x1b52>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102e38:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f0102e3d:	89 d8                	mov    %ebx,%eax
f0102e3f:	e8 68 e1 ff ff       	call   f0100fac <check_va2pa>
f0102e44:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102e47:	74 24                	je     f0102e6d <mem_init+0x1650>
f0102e49:	c7 44 24 0c 70 52 10 	movl   $0xf0105270,0xc(%esp)
f0102e50:	f0 
f0102e51:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f0102e58:	f0 
f0102e59:	c7 44 24 04 b3 02 00 	movl   $0x2b3,0x4(%esp)
f0102e60:	00 
f0102e61:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f0102e68:	e8 27 d2 ff ff       	call   f0100094 <_panic>
f0102e6d:	b8 00 00 00 00       	mov    $0x0,%eax

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f0102e72:	ba 01 00 00 00       	mov    $0x1,%edx
f0102e77:	8d 88 44 fc ff ff    	lea    -0x3bc(%eax),%ecx
f0102e7d:	83 f9 03             	cmp    $0x3,%ecx
f0102e80:	77 39                	ja     f0102ebb <mem_init+0x169e>
f0102e82:	89 d6                	mov    %edx,%esi
f0102e84:	d3 e6                	shl    %cl,%esi
f0102e86:	89 f1                	mov    %esi,%ecx
f0102e88:	f6 c1 0b             	test   $0xb,%cl
f0102e8b:	74 2e                	je     f0102ebb <mem_init+0x169e>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
f0102e8d:	f6 04 83 01          	testb  $0x1,(%ebx,%eax,4)
f0102e91:	0f 85 aa 00 00 00    	jne    f0102f41 <mem_init+0x1724>
f0102e97:	c7 44 24 0c 06 56 10 	movl   $0xf0105606,0xc(%esp)
f0102e9e:	f0 
f0102e9f:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f0102ea6:	f0 
f0102ea7:	c7 44 24 04 bb 02 00 	movl   $0x2bb,0x4(%esp)
f0102eae:	00 
f0102eaf:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f0102eb6:	e8 d9 d1 ff ff       	call   f0100094 <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f0102ebb:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102ec0:	76 55                	jbe    f0102f17 <mem_init+0x16fa>
				assert(pgdir[i] & PTE_P);
f0102ec2:	8b 0c 83             	mov    (%ebx,%eax,4),%ecx
f0102ec5:	f6 c1 01             	test   $0x1,%cl
f0102ec8:	75 24                	jne    f0102eee <mem_init+0x16d1>
f0102eca:	c7 44 24 0c 06 56 10 	movl   $0xf0105606,0xc(%esp)
f0102ed1:	f0 
f0102ed2:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f0102ed9:	f0 
f0102eda:	c7 44 24 04 bf 02 00 	movl   $0x2bf,0x4(%esp)
f0102ee1:	00 
f0102ee2:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f0102ee9:	e8 a6 d1 ff ff       	call   f0100094 <_panic>
				assert(pgdir[i] & PTE_W);
f0102eee:	f6 c1 02             	test   $0x2,%cl
f0102ef1:	75 4e                	jne    f0102f41 <mem_init+0x1724>
f0102ef3:	c7 44 24 0c 17 56 10 	movl   $0xf0105617,0xc(%esp)
f0102efa:	f0 
f0102efb:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f0102f02:	f0 
f0102f03:	c7 44 24 04 c0 02 00 	movl   $0x2c0,0x4(%esp)
f0102f0a:	00 
f0102f0b:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f0102f12:	e8 7d d1 ff ff       	call   f0100094 <_panic>
			} else
				assert(pgdir[i] == 0);
f0102f17:	83 3c 83 00          	cmpl   $0x0,(%ebx,%eax,4)
f0102f1b:	74 24                	je     f0102f41 <mem_init+0x1724>
f0102f1d:	c7 44 24 0c 28 56 10 	movl   $0xf0105628,0xc(%esp)
f0102f24:	f0 
f0102f25:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f0102f2c:	f0 
f0102f2d:	c7 44 24 04 c2 02 00 	movl   $0x2c2,0x4(%esp)
f0102f34:	00 
f0102f35:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f0102f3c:	e8 53 d1 ff ff       	call   f0100094 <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0102f41:	83 c0 01             	add    $0x1,%eax
f0102f44:	3d 00 04 00 00       	cmp    $0x400,%eax
f0102f49:	0f 85 28 ff ff ff    	jne    f0102e77 <mem_init+0x165a>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f0102f4f:	c7 04 24 a0 52 10 f0 	movl   $0xf01052a0,(%esp)
f0102f56:	e8 a3 04 00 00       	call   f01033fe <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f0102f5b:	a1 88 99 11 f0       	mov    0xf0119988,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102f60:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102f65:	77 20                	ja     f0102f87 <mem_init+0x176a>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102f67:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102f6b:	c7 44 24 08 74 4a 10 	movl   $0xf0104a74,0x8(%esp)
f0102f72:	f0 
f0102f73:	c7 44 24 04 d4 00 00 	movl   $0xd4,0x4(%esp)
f0102f7a:	00 
f0102f7b:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f0102f82:	e8 0d d1 ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0102f87:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0102f8c:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f0102f8f:	b8 00 00 00 00       	mov    $0x0,%eax
f0102f94:	e8 b6 e0 ff ff       	call   f010104f <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f0102f99:	0f 20 c0             	mov    %cr0,%eax

	// entry.S set the really important flags in cr0 (including enabling
	// paging).  Here we configure the rest of the flags that we care about.
	cr0 = rcr0();
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_MP;
f0102f9c:	0d 23 00 05 80       	or     $0x80050023,%eax
	cr0 &= ~(CR0_TS|CR0_EM);
f0102fa1:	83 e0 f3             	and    $0xfffffff3,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f0102fa4:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102fa7:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102fae:	e8 d9 e4 ff ff       	call   f010148c <page_alloc>
f0102fb3:	89 c6                	mov    %eax,%esi
f0102fb5:	85 c0                	test   %eax,%eax
f0102fb7:	75 24                	jne    f0102fdd <mem_init+0x17c0>
f0102fb9:	c7 44 24 0c 45 54 10 	movl   $0xf0105445,0xc(%esp)
f0102fc0:	f0 
f0102fc1:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f0102fc8:	f0 
f0102fc9:	c7 44 24 04 83 03 00 	movl   $0x383,0x4(%esp)
f0102fd0:	00 
f0102fd1:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f0102fd8:	e8 b7 d0 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f0102fdd:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102fe4:	e8 a3 e4 ff ff       	call   f010148c <page_alloc>
f0102fe9:	89 c7                	mov    %eax,%edi
f0102feb:	85 c0                	test   %eax,%eax
f0102fed:	75 24                	jne    f0103013 <mem_init+0x17f6>
f0102fef:	c7 44 24 0c 5b 54 10 	movl   $0xf010545b,0xc(%esp)
f0102ff6:	f0 
f0102ff7:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f0102ffe:	f0 
f0102fff:	c7 44 24 04 84 03 00 	movl   $0x384,0x4(%esp)
f0103006:	00 
f0103007:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f010300e:	e8 81 d0 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0103013:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010301a:	e8 6d e4 ff ff       	call   f010148c <page_alloc>
f010301f:	89 c3                	mov    %eax,%ebx
f0103021:	85 c0                	test   %eax,%eax
f0103023:	75 24                	jne    f0103049 <mem_init+0x182c>
f0103025:	c7 44 24 0c 71 54 10 	movl   $0xf0105471,0xc(%esp)
f010302c:	f0 
f010302d:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f0103034:	f0 
f0103035:	c7 44 24 04 85 03 00 	movl   $0x385,0x4(%esp)
f010303c:	00 
f010303d:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f0103044:	e8 4b d0 ff ff       	call   f0100094 <_panic>
	page_free(pp0);
f0103049:	89 34 24             	mov    %esi,(%esp)
f010304c:	e8 bc e4 ff ff       	call   f010150d <page_free>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0103051:	89 f8                	mov    %edi,%eax
f0103053:	2b 05 8c 99 11 f0    	sub    0xf011998c,%eax
f0103059:	c1 f8 03             	sar    $0x3,%eax
f010305c:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010305f:	89 c2                	mov    %eax,%edx
f0103061:	c1 ea 0c             	shr    $0xc,%edx
f0103064:	3b 15 84 99 11 f0    	cmp    0xf0119984,%edx
f010306a:	72 20                	jb     f010308c <mem_init+0x186f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010306c:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103070:	c7 44 24 08 68 4c 10 	movl   $0xf0104c68,0x8(%esp)
f0103077:	f0 
f0103078:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f010307f:	00 
f0103080:	c7 04 24 6c 53 10 f0 	movl   $0xf010536c,(%esp)
f0103087:	e8 08 d0 ff ff       	call   f0100094 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f010308c:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0103093:	00 
f0103094:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f010309b:	00 
	return (void *)(pa + KERNBASE);
f010309c:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01030a1:	89 04 24             	mov    %eax,(%esp)
f01030a4:	e8 18 0f 00 00       	call   f0103fc1 <memset>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01030a9:	89 d8                	mov    %ebx,%eax
f01030ab:	2b 05 8c 99 11 f0    	sub    0xf011998c,%eax
f01030b1:	c1 f8 03             	sar    $0x3,%eax
f01030b4:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01030b7:	89 c2                	mov    %eax,%edx
f01030b9:	c1 ea 0c             	shr    $0xc,%edx
f01030bc:	3b 15 84 99 11 f0    	cmp    0xf0119984,%edx
f01030c2:	72 20                	jb     f01030e4 <mem_init+0x18c7>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01030c4:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01030c8:	c7 44 24 08 68 4c 10 	movl   $0xf0104c68,0x8(%esp)
f01030cf:	f0 
f01030d0:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f01030d7:	00 
f01030d8:	c7 04 24 6c 53 10 f0 	movl   $0xf010536c,(%esp)
f01030df:	e8 b0 cf ff ff       	call   f0100094 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f01030e4:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01030eb:	00 
f01030ec:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f01030f3:	00 
	return (void *)(pa + KERNBASE);
f01030f4:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01030f9:	89 04 24             	mov    %eax,(%esp)
f01030fc:	e8 c0 0e 00 00       	call   f0103fc1 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0103101:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0103108:	00 
f0103109:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0103110:	00 
f0103111:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103115:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f010311a:	89 04 24             	mov    %eax,(%esp)
f010311d:	e8 39 e6 ff ff       	call   f010175b <page_insert>
	assert(pp1->pp_ref == 1);
f0103122:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0103127:	74 24                	je     f010314d <mem_init+0x1930>
f0103129:	c7 44 24 0c 42 55 10 	movl   $0xf0105542,0xc(%esp)
f0103130:	f0 
f0103131:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f0103138:	f0 
f0103139:	c7 44 24 04 8a 03 00 	movl   $0x38a,0x4(%esp)
f0103140:	00 
f0103141:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f0103148:	e8 47 cf ff ff       	call   f0100094 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f010314d:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0103154:	01 01 01 
f0103157:	74 24                	je     f010317d <mem_init+0x1960>
f0103159:	c7 44 24 0c c0 52 10 	movl   $0xf01052c0,0xc(%esp)
f0103160:	f0 
f0103161:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f0103168:	f0 
f0103169:	c7 44 24 04 8b 03 00 	movl   $0x38b,0x4(%esp)
f0103170:	00 
f0103171:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f0103178:	e8 17 cf ff ff       	call   f0100094 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f010317d:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0103184:	00 
f0103185:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010318c:	00 
f010318d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103191:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f0103196:	89 04 24             	mov    %eax,(%esp)
f0103199:	e8 bd e5 ff ff       	call   f010175b <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f010319e:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f01031a5:	02 02 02 
f01031a8:	74 24                	je     f01031ce <mem_init+0x19b1>
f01031aa:	c7 44 24 0c e4 52 10 	movl   $0xf01052e4,0xc(%esp)
f01031b1:	f0 
f01031b2:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f01031b9:	f0 
f01031ba:	c7 44 24 04 8d 03 00 	movl   $0x38d,0x4(%esp)
f01031c1:	00 
f01031c2:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f01031c9:	e8 c6 ce ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f01031ce:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01031d3:	74 24                	je     f01031f9 <mem_init+0x19dc>
f01031d5:	c7 44 24 0c 64 55 10 	movl   $0xf0105564,0xc(%esp)
f01031dc:	f0 
f01031dd:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f01031e4:	f0 
f01031e5:	c7 44 24 04 8e 03 00 	movl   $0x38e,0x4(%esp)
f01031ec:	00 
f01031ed:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f01031f4:	e8 9b ce ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 0);
f01031f9:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f01031fe:	74 24                	je     f0103224 <mem_init+0x1a07>
f0103200:	c7 44 24 0c ad 55 10 	movl   $0xf01055ad,0xc(%esp)
f0103207:	f0 
f0103208:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f010320f:	f0 
f0103210:	c7 44 24 04 8f 03 00 	movl   $0x38f,0x4(%esp)
f0103217:	00 
f0103218:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f010321f:	e8 70 ce ff ff       	call   f0100094 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0103224:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f010322b:	03 03 03 
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010322e:	89 d8                	mov    %ebx,%eax
f0103230:	2b 05 8c 99 11 f0    	sub    0xf011998c,%eax
f0103236:	c1 f8 03             	sar    $0x3,%eax
f0103239:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010323c:	89 c2                	mov    %eax,%edx
f010323e:	c1 ea 0c             	shr    $0xc,%edx
f0103241:	3b 15 84 99 11 f0    	cmp    0xf0119984,%edx
f0103247:	72 20                	jb     f0103269 <mem_init+0x1a4c>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0103249:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010324d:	c7 44 24 08 68 4c 10 	movl   $0xf0104c68,0x8(%esp)
f0103254:	f0 
f0103255:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f010325c:	00 
f010325d:	c7 04 24 6c 53 10 f0 	movl   $0xf010536c,(%esp)
f0103264:	e8 2b ce ff ff       	call   f0100094 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0103269:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0103270:	03 03 03 
f0103273:	74 24                	je     f0103299 <mem_init+0x1a7c>
f0103275:	c7 44 24 0c 08 53 10 	movl   $0xf0105308,0xc(%esp)
f010327c:	f0 
f010327d:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f0103284:	f0 
f0103285:	c7 44 24 04 91 03 00 	movl   $0x391,0x4(%esp)
f010328c:	00 
f010328d:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f0103294:	e8 fb cd ff ff       	call   f0100094 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0103299:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01032a0:	00 
f01032a1:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f01032a6:	89 04 24             	mov    %eax,(%esp)
f01032a9:	e8 6f e4 ff ff       	call   f010171d <page_remove>
	assert(pp2->pp_ref == 0);
f01032ae:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f01032b3:	74 24                	je     f01032d9 <mem_init+0x1abc>
f01032b5:	c7 44 24 0c 9c 55 10 	movl   $0xf010559c,0xc(%esp)
f01032bc:	f0 
f01032bd:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f01032c4:	f0 
f01032c5:	c7 44 24 04 93 03 00 	movl   $0x393,0x4(%esp)
f01032cc:	00 
f01032cd:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f01032d4:	e8 bb cd ff ff       	call   f0100094 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01032d9:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f01032de:	8b 08                	mov    (%eax),%ecx
f01032e0:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01032e6:	89 f2                	mov    %esi,%edx
f01032e8:	2b 15 8c 99 11 f0    	sub    0xf011998c,%edx
f01032ee:	c1 fa 03             	sar    $0x3,%edx
f01032f1:	c1 e2 0c             	shl    $0xc,%edx
f01032f4:	39 d1                	cmp    %edx,%ecx
f01032f6:	74 24                	je     f010331c <mem_init+0x1aff>
f01032f8:	c7 44 24 0c 84 4e 10 	movl   $0xf0104e84,0xc(%esp)
f01032ff:	f0 
f0103300:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f0103307:	f0 
f0103308:	c7 44 24 04 96 03 00 	movl   $0x396,0x4(%esp)
f010330f:	00 
f0103310:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f0103317:	e8 78 cd ff ff       	call   f0100094 <_panic>
	kern_pgdir[0] = 0;
f010331c:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f0103322:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0103327:	74 24                	je     f010334d <mem_init+0x1b30>
f0103329:	c7 44 24 0c 53 55 10 	movl   $0xf0105553,0xc(%esp)
f0103330:	f0 
f0103331:	c7 44 24 08 86 53 10 	movl   $0xf0105386,0x8(%esp)
f0103338:	f0 
f0103339:	c7 44 24 04 98 03 00 	movl   $0x398,0x4(%esp)
f0103340:	00 
f0103341:	c7 04 24 60 53 10 f0 	movl   $0xf0105360,(%esp)
f0103348:	e8 47 cd ff ff       	call   f0100094 <_panic>
	pp0->pp_ref = 0;
f010334d:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// free the pages we took
	page_free(pp0);
f0103353:	89 34 24             	mov    %esi,(%esp)
f0103356:	e8 b2 e1 ff ff       	call   f010150d <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f010335b:	c7 04 24 34 53 10 f0 	movl   $0xf0105334,(%esp)
f0103362:	e8 97 00 00 00       	call   f01033fe <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0103367:	83 c4 3c             	add    $0x3c,%esp
f010336a:	5b                   	pop    %ebx
f010336b:	5e                   	pop    %esi
f010336c:	5f                   	pop    %edi
f010336d:	5d                   	pop    %ebp
f010336e:	c3                   	ret    
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f010336f:	89 f2                	mov    %esi,%edx
f0103371:	89 d8                	mov    %ebx,%eax
f0103373:	e8 34 dc ff ff       	call   f0100fac <check_va2pa>
f0103378:	81 c6 00 10 00 00    	add    $0x1000,%esi
f010337e:	e9 7e fa ff ff       	jmp    f0102e01 <mem_init+0x15e4>

f0103383 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0103383:	55                   	push   %ebp
f0103384:	89 e5                	mov    %esp,%ebp
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0103386:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103389:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f010338c:	5d                   	pop    %ebp
f010338d:	c3                   	ret    
	...

f0103390 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0103390:	55                   	push   %ebp
f0103391:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0103393:	ba 70 00 00 00       	mov    $0x70,%edx
f0103398:	8b 45 08             	mov    0x8(%ebp),%eax
f010339b:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010339c:	b2 71                	mov    $0x71,%dl
f010339e:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f010339f:	0f b6 c0             	movzbl %al,%eax
}
f01033a2:	5d                   	pop    %ebp
f01033a3:	c3                   	ret    

f01033a4 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f01033a4:	55                   	push   %ebp
f01033a5:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01033a7:	ba 70 00 00 00       	mov    $0x70,%edx
f01033ac:	8b 45 08             	mov    0x8(%ebp),%eax
f01033af:	ee                   	out    %al,(%dx)
f01033b0:	b2 71                	mov    $0x71,%dl
f01033b2:	8b 45 0c             	mov    0xc(%ebp),%eax
f01033b5:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f01033b6:	5d                   	pop    %ebp
f01033b7:	c3                   	ret    

f01033b8 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f01033b8:	55                   	push   %ebp
f01033b9:	89 e5                	mov    %esp,%ebp
f01033bb:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f01033be:	8b 45 08             	mov    0x8(%ebp),%eax
f01033c1:	89 04 24             	mov    %eax,(%esp)
f01033c4:	e8 30 d2 ff ff       	call   f01005f9 <cputchar>
	*cnt++;
}
f01033c9:	c9                   	leave  
f01033ca:	c3                   	ret    

f01033cb <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f01033cb:	55                   	push   %ebp
f01033cc:	89 e5                	mov    %esp,%ebp
f01033ce:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f01033d1:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f01033d8:	8b 45 0c             	mov    0xc(%ebp),%eax
f01033db:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01033df:	8b 45 08             	mov    0x8(%ebp),%eax
f01033e2:	89 44 24 08          	mov    %eax,0x8(%esp)
f01033e6:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01033e9:	89 44 24 04          	mov    %eax,0x4(%esp)
f01033ed:	c7 04 24 b8 33 10 f0 	movl   $0xf01033b8,(%esp)
f01033f4:	e8 c1 04 00 00       	call   f01038ba <vprintfmt>
	return cnt;
}
f01033f9:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01033fc:	c9                   	leave  
f01033fd:	c3                   	ret    

f01033fe <cprintf>:

int
cprintf(const char *fmt, ...)
{
f01033fe:	55                   	push   %ebp
f01033ff:	89 e5                	mov    %esp,%ebp
f0103401:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0103404:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0103407:	89 44 24 04          	mov    %eax,0x4(%esp)
f010340b:	8b 45 08             	mov    0x8(%ebp),%eax
f010340e:	89 04 24             	mov    %eax,(%esp)
f0103411:	e8 b5 ff ff ff       	call   f01033cb <vcprintf>
	va_end(ap);

	return cnt;
}
f0103416:	c9                   	leave  
f0103417:	c3                   	ret    

f0103418 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0103418:	55                   	push   %ebp
f0103419:	89 e5                	mov    %esp,%ebp
f010341b:	57                   	push   %edi
f010341c:	56                   	push   %esi
f010341d:	53                   	push   %ebx
f010341e:	83 ec 10             	sub    $0x10,%esp
f0103421:	89 c3                	mov    %eax,%ebx
f0103423:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0103426:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0103429:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f010342c:	8b 0a                	mov    (%edx),%ecx
f010342e:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103431:	8b 00                	mov    (%eax),%eax
f0103433:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0103436:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)

	while (l <= r) {
f010343d:	eb 77                	jmp    f01034b6 <stab_binsearch+0x9e>
		int true_m = (l + r) / 2, m = true_m;
f010343f:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0103442:	01 c8                	add    %ecx,%eax
f0103444:	bf 02 00 00 00       	mov    $0x2,%edi
f0103449:	99                   	cltd   
f010344a:	f7 ff                	idiv   %edi
f010344c:	89 c2                	mov    %eax,%edx

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f010344e:	eb 01                	jmp    f0103451 <stab_binsearch+0x39>
			m--;
f0103450:	4a                   	dec    %edx

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0103451:	39 ca                	cmp    %ecx,%edx
f0103453:	7c 1d                	jl     f0103472 <stab_binsearch+0x5a>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0103455:	6b fa 0c             	imul   $0xc,%edx,%edi

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0103458:	0f b6 7c 3b 04       	movzbl 0x4(%ebx,%edi,1),%edi
f010345d:	39 f7                	cmp    %esi,%edi
f010345f:	75 ef                	jne    f0103450 <stab_binsearch+0x38>
f0103461:	89 55 ec             	mov    %edx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0103464:	6b fa 0c             	imul   $0xc,%edx,%edi
f0103467:	8b 7c 3b 08          	mov    0x8(%ebx,%edi,1),%edi
f010346b:	3b 7d 0c             	cmp    0xc(%ebp),%edi
f010346e:	73 18                	jae    f0103488 <stab_binsearch+0x70>
f0103470:	eb 05                	jmp    f0103477 <stab_binsearch+0x5f>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0103472:	8d 48 01             	lea    0x1(%eax),%ecx
			continue;
f0103475:	eb 3f                	jmp    f01034b6 <stab_binsearch+0x9e>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0103477:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f010347a:	89 11                	mov    %edx,(%ecx)
			l = true_m + 1;
f010347c:	8d 48 01             	lea    0x1(%eax),%ecx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010347f:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0103486:	eb 2e                	jmp    f01034b6 <stab_binsearch+0x9e>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0103488:	3b 7d 0c             	cmp    0xc(%ebp),%edi
f010348b:	76 15                	jbe    f01034a2 <stab_binsearch+0x8a>
			*region_right = m - 1;
f010348d:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0103490:	4f                   	dec    %edi
f0103491:	89 7d f0             	mov    %edi,-0x10(%ebp)
f0103494:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103497:	89 38                	mov    %edi,(%eax)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0103499:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f01034a0:	eb 14                	jmp    f01034b6 <stab_binsearch+0x9e>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01034a2:	8b 7d ec             	mov    -0x14(%ebp),%edi
f01034a5:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f01034a8:	89 39                	mov    %edi,(%ecx)
			l = m;
			addr++;
f01034aa:	ff 45 0c             	incl   0xc(%ebp)
f01034ad:	89 d1                	mov    %edx,%ecx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01034af:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f01034b6:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
f01034b9:	7e 84                	jle    f010343f <stab_binsearch+0x27>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f01034bb:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f01034bf:	75 0d                	jne    f01034ce <stab_binsearch+0xb6>
		*region_right = *region_left - 1;
f01034c1:	8b 55 e8             	mov    -0x18(%ebp),%edx
f01034c4:	8b 02                	mov    (%edx),%eax
f01034c6:	48                   	dec    %eax
f01034c7:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f01034ca:	89 01                	mov    %eax,(%ecx)
f01034cc:	eb 22                	jmp    f01034f0 <stab_binsearch+0xd8>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01034ce:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f01034d1:	8b 01                	mov    (%ecx),%eax
		     l > *region_left && stabs[l].n_type != type;
f01034d3:	8b 55 e8             	mov    -0x18(%ebp),%edx
f01034d6:	8b 0a                	mov    (%edx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01034d8:	eb 01                	jmp    f01034db <stab_binsearch+0xc3>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f01034da:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f01034db:	39 c1                	cmp    %eax,%ecx
f01034dd:	7d 0c                	jge    f01034eb <stab_binsearch+0xd3>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f01034df:	6b d0 0c             	imul   $0xc,%eax,%edx
	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
		     l > *region_left && stabs[l].n_type != type;
f01034e2:	0f b6 54 13 04       	movzbl 0x4(%ebx,%edx,1),%edx
f01034e7:	39 f2                	cmp    %esi,%edx
f01034e9:	75 ef                	jne    f01034da <stab_binsearch+0xc2>
		     l--)
			/* do nothing */;
		*region_left = l;
f01034eb:	8b 55 e8             	mov    -0x18(%ebp),%edx
f01034ee:	89 02                	mov    %eax,(%edx)
	}
}
f01034f0:	83 c4 10             	add    $0x10,%esp
f01034f3:	5b                   	pop    %ebx
f01034f4:	5e                   	pop    %esi
f01034f5:	5f                   	pop    %edi
f01034f6:	5d                   	pop    %ebp
f01034f7:	c3                   	ret    

f01034f8 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f01034f8:	55                   	push   %ebp
f01034f9:	89 e5                	mov    %esp,%ebp
f01034fb:	83 ec 58             	sub    $0x58,%esp
f01034fe:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0103501:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0103504:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0103507:	8b 75 08             	mov    0x8(%ebp),%esi
f010350a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f010350d:	c7 03 36 56 10 f0    	movl   $0xf0105636,(%ebx)
	info->eip_line = 0;
f0103513:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f010351a:	c7 43 08 36 56 10 f0 	movl   $0xf0105636,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0103521:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0103528:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f010352b:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0103532:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0103538:	76 12                	jbe    f010354c <debuginfo_eip+0x54>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f010353a:	b8 e8 e3 10 f0       	mov    $0xf010e3e8,%eax
f010353f:	3d e5 c3 10 f0       	cmp    $0xf010c3e5,%eax
f0103544:	0f 86 f1 01 00 00    	jbe    f010373b <debuginfo_eip+0x243>
f010354a:	eb 1c                	jmp    f0103568 <debuginfo_eip+0x70>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f010354c:	c7 44 24 08 40 56 10 	movl   $0xf0105640,0x8(%esp)
f0103553:	f0 
f0103554:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f010355b:	00 
f010355c:	c7 04 24 4d 56 10 f0 	movl   $0xf010564d,(%esp)
f0103563:	e8 2c cb ff ff       	call   f0100094 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0103568:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f010356d:	80 3d e7 e3 10 f0 00 	cmpb   $0x0,0xf010e3e7
f0103574:	0f 85 cd 01 00 00    	jne    f0103747 <debuginfo_eip+0x24f>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f010357a:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0103581:	b8 e4 c3 10 f0       	mov    $0xf010c3e4,%eax
f0103586:	2d 5c 58 10 f0       	sub    $0xf010585c,%eax
f010358b:	c1 f8 02             	sar    $0x2,%eax
f010358e:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0103594:	83 e8 01             	sub    $0x1,%eax
f0103597:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f010359a:	89 74 24 04          	mov    %esi,0x4(%esp)
f010359e:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f01035a5:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f01035a8:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01035ab:	b8 5c 58 10 f0       	mov    $0xf010585c,%eax
f01035b0:	e8 63 fe ff ff       	call   f0103418 <stab_binsearch>
	if (lfile == 0)
f01035b5:	8b 55 e4             	mov    -0x1c(%ebp),%edx
		return -1;
f01035b8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
f01035bd:	85 d2                	test   %edx,%edx
f01035bf:	0f 84 82 01 00 00    	je     f0103747 <debuginfo_eip+0x24f>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f01035c5:	89 55 dc             	mov    %edx,-0x24(%ebp)
	rfun = rfile;
f01035c8:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01035cb:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f01035ce:	89 74 24 04          	mov    %esi,0x4(%esp)
f01035d2:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f01035d9:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f01035dc:	8d 55 dc             	lea    -0x24(%ebp),%edx
f01035df:	b8 5c 58 10 f0       	mov    $0xf010585c,%eax
f01035e4:	e8 2f fe ff ff       	call   f0103418 <stab_binsearch>

	if (lfun <= rfun) {
f01035e9:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01035ec:	8b 55 d8             	mov    -0x28(%ebp),%edx
f01035ef:	39 d0                	cmp    %edx,%eax
f01035f1:	7f 3d                	jg     f0103630 <debuginfo_eip+0x138>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f01035f3:	6b c8 0c             	imul   $0xc,%eax,%ecx
f01035f6:	8d b9 5c 58 10 f0    	lea    -0xfefa7a4(%ecx),%edi
f01035fc:	89 7d c0             	mov    %edi,-0x40(%ebp)
f01035ff:	8b 89 5c 58 10 f0    	mov    -0xfefa7a4(%ecx),%ecx
f0103605:	bf e8 e3 10 f0       	mov    $0xf010e3e8,%edi
f010360a:	81 ef e5 c3 10 f0    	sub    $0xf010c3e5,%edi
f0103610:	39 f9                	cmp    %edi,%ecx
f0103612:	73 09                	jae    f010361d <debuginfo_eip+0x125>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0103614:	81 c1 e5 c3 10 f0    	add    $0xf010c3e5,%ecx
f010361a:	89 4b 08             	mov    %ecx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f010361d:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0103620:	8b 4f 08             	mov    0x8(%edi),%ecx
f0103623:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0103626:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0103628:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f010362b:	89 55 d0             	mov    %edx,-0x30(%ebp)
f010362e:	eb 0f                	jmp    f010363f <debuginfo_eip+0x147>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0103630:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0103633:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103636:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0103639:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010363c:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f010363f:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0103646:	00 
f0103647:	8b 43 08             	mov    0x8(%ebx),%eax
f010364a:	89 04 24             	mov    %eax,(%esp)
f010364d:	e8 48 09 00 00       	call   f0103f9a <strfind>
f0103652:	2b 43 08             	sub    0x8(%ebx),%eax
f0103655:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0103658:	89 74 24 04          	mov    %esi,0x4(%esp)
f010365c:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f0103663:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0103666:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0103669:	b8 5c 58 10 f0       	mov    $0xf010585c,%eax
f010366e:	e8 a5 fd ff ff       	call   f0103418 <stab_binsearch>
	if (lline <= rline) {
f0103673:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103676:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0103679:	7f 0f                	jg     f010368a <debuginfo_eip+0x192>
		info->eip_line = stabs[lline].n_desc;
f010367b:	6b c0 0c             	imul   $0xc,%eax,%eax
f010367e:	0f b7 80 62 58 10 f0 	movzwl -0xfefa79e(%eax),%eax
f0103685:	89 43 04             	mov    %eax,0x4(%ebx)
f0103688:	eb 07                	jmp    f0103691 <debuginfo_eip+0x199>
	} else {
		info->eip_line = -1;
f010368a:	c7 43 04 ff ff ff ff 	movl   $0xffffffff,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0103691:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103694:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0103697:	39 c8                	cmp    %ecx,%eax
f0103699:	7c 5f                	jl     f01036fa <debuginfo_eip+0x202>
	       && stabs[lline].n_type != N_SOL
f010369b:	89 c2                	mov    %eax,%edx
f010369d:	6b f0 0c             	imul   $0xc,%eax,%esi
f01036a0:	80 be 60 58 10 f0 84 	cmpb   $0x84,-0xfefa7a0(%esi)
f01036a7:	75 18                	jne    f01036c1 <debuginfo_eip+0x1c9>
f01036a9:	eb 30                	jmp    f01036db <debuginfo_eip+0x1e3>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f01036ab:	83 e8 01             	sub    $0x1,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01036ae:	39 c1                	cmp    %eax,%ecx
f01036b0:	7f 48                	jg     f01036fa <debuginfo_eip+0x202>
	       && stabs[lline].n_type != N_SOL
f01036b2:	89 c2                	mov    %eax,%edx
f01036b4:	8d 34 40             	lea    (%eax,%eax,2),%esi
f01036b7:	80 3c b5 60 58 10 f0 	cmpb   $0x84,-0xfefa7a0(,%esi,4)
f01036be:	84 
f01036bf:	74 1a                	je     f01036db <debuginfo_eip+0x1e3>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f01036c1:	8d 14 52             	lea    (%edx,%edx,2),%edx
f01036c4:	8d 14 95 5c 58 10 f0 	lea    -0xfefa7a4(,%edx,4),%edx
f01036cb:	80 7a 04 64          	cmpb   $0x64,0x4(%edx)
f01036cf:	75 da                	jne    f01036ab <debuginfo_eip+0x1b3>
f01036d1:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f01036d5:	74 d4                	je     f01036ab <debuginfo_eip+0x1b3>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f01036d7:	39 c8                	cmp    %ecx,%eax
f01036d9:	7c 1f                	jl     f01036fa <debuginfo_eip+0x202>
f01036db:	6b c0 0c             	imul   $0xc,%eax,%eax
f01036de:	8b 80 5c 58 10 f0    	mov    -0xfefa7a4(%eax),%eax
f01036e4:	ba e8 e3 10 f0       	mov    $0xf010e3e8,%edx
f01036e9:	81 ea e5 c3 10 f0    	sub    $0xf010c3e5,%edx
f01036ef:	39 d0                	cmp    %edx,%eax
f01036f1:	73 07                	jae    f01036fa <debuginfo_eip+0x202>
		info->eip_file = stabstr + stabs[lline].n_strx;
f01036f3:	05 e5 c3 10 f0       	add    $0xf010c3e5,%eax
f01036f8:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01036fa:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01036fd:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103700:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103705:	39 ca                	cmp    %ecx,%edx
f0103707:	7d 3e                	jge    f0103747 <debuginfo_eip+0x24f>
		for (lline = lfun + 1;
f0103709:	83 c2 01             	add    $0x1,%edx
f010370c:	39 d1                	cmp    %edx,%ecx
f010370e:	7e 37                	jle    f0103747 <debuginfo_eip+0x24f>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0103710:	6b f2 0c             	imul   $0xc,%edx,%esi
f0103713:	80 be 60 58 10 f0 a0 	cmpb   $0xa0,-0xfefa7a0(%esi)
f010371a:	75 2b                	jne    f0103747 <debuginfo_eip+0x24f>
		     lline++)
			info->eip_fn_narg++;
f010371c:	83 43 14 01          	addl   $0x1,0x14(%ebx)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0103720:	83 c2 01             	add    $0x1,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0103723:	39 d1                	cmp    %edx,%ecx
f0103725:	7e 1b                	jle    f0103742 <debuginfo_eip+0x24a>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0103727:	8d 04 52             	lea    (%edx,%edx,2),%eax
f010372a:	80 3c 85 60 58 10 f0 	cmpb   $0xa0,-0xfefa7a0(,%eax,4)
f0103731:	a0 
f0103732:	74 e8                	je     f010371c <debuginfo_eip+0x224>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103734:	b8 00 00 00 00       	mov    $0x0,%eax
f0103739:	eb 0c                	jmp    f0103747 <debuginfo_eip+0x24f>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f010373b:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0103740:	eb 05                	jmp    f0103747 <debuginfo_eip+0x24f>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103742:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103747:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f010374a:	8b 75 f8             	mov    -0x8(%ebp),%esi
f010374d:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0103750:	89 ec                	mov    %ebp,%esp
f0103752:	5d                   	pop    %ebp
f0103753:	c3                   	ret    
	...

f0103760 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0103760:	55                   	push   %ebp
f0103761:	89 e5                	mov    %esp,%ebp
f0103763:	57                   	push   %edi
f0103764:	56                   	push   %esi
f0103765:	53                   	push   %ebx
f0103766:	83 ec 3c             	sub    $0x3c,%esp
f0103769:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010376c:	89 d7                	mov    %edx,%edi
f010376e:	8b 45 08             	mov    0x8(%ebp),%eax
f0103771:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0103774:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103777:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010377a:	8b 5d 14             	mov    0x14(%ebp),%ebx
f010377d:	8b 75 18             	mov    0x18(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0103780:	b8 00 00 00 00       	mov    $0x0,%eax
f0103785:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0103788:	72 11                	jb     f010379b <printnum+0x3b>
f010378a:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010378d:	39 45 10             	cmp    %eax,0x10(%ebp)
f0103790:	76 09                	jbe    f010379b <printnum+0x3b>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0103792:	83 eb 01             	sub    $0x1,%ebx
f0103795:	85 db                	test   %ebx,%ebx
f0103797:	7f 51                	jg     f01037ea <printnum+0x8a>
f0103799:	eb 5e                	jmp    f01037f9 <printnum+0x99>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
f010379b:	89 74 24 10          	mov    %esi,0x10(%esp)
f010379f:	83 eb 01             	sub    $0x1,%ebx
f01037a2:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f01037a6:	8b 45 10             	mov    0x10(%ebp),%eax
f01037a9:	89 44 24 08          	mov    %eax,0x8(%esp)
f01037ad:	8b 5c 24 08          	mov    0x8(%esp),%ebx
f01037b1:	8b 74 24 0c          	mov    0xc(%esp),%esi
f01037b5:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f01037bc:	00 
f01037bd:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01037c0:	89 04 24             	mov    %eax,(%esp)
f01037c3:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01037c6:	89 44 24 04          	mov    %eax,0x4(%esp)
f01037ca:	e8 41 0a 00 00       	call   f0104210 <__udivdi3>
f01037cf:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f01037d3:	89 74 24 0c          	mov    %esi,0xc(%esp)
f01037d7:	89 04 24             	mov    %eax,(%esp)
f01037da:	89 54 24 04          	mov    %edx,0x4(%esp)
f01037de:	89 fa                	mov    %edi,%edx
f01037e0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01037e3:	e8 78 ff ff ff       	call   f0103760 <printnum>
f01037e8:	eb 0f                	jmp    f01037f9 <printnum+0x99>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f01037ea:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01037ee:	89 34 24             	mov    %esi,(%esp)
f01037f1:	ff 55 e4             	call   *-0x1c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f01037f4:	83 eb 01             	sub    $0x1,%ebx
f01037f7:	75 f1                	jne    f01037ea <printnum+0x8a>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f01037f9:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01037fd:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0103801:	8b 45 10             	mov    0x10(%ebp),%eax
f0103804:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103808:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f010380f:	00 
f0103810:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103813:	89 04 24             	mov    %eax,(%esp)
f0103816:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103819:	89 44 24 04          	mov    %eax,0x4(%esp)
f010381d:	e8 1e 0b 00 00       	call   f0104340 <__umoddi3>
f0103822:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103826:	0f be 80 5b 56 10 f0 	movsbl -0xfefa9a5(%eax),%eax
f010382d:	89 04 24             	mov    %eax,(%esp)
f0103830:	ff 55 e4             	call   *-0x1c(%ebp)
}
f0103833:	83 c4 3c             	add    $0x3c,%esp
f0103836:	5b                   	pop    %ebx
f0103837:	5e                   	pop    %esi
f0103838:	5f                   	pop    %edi
f0103839:	5d                   	pop    %ebp
f010383a:	c3                   	ret    

f010383b <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f010383b:	55                   	push   %ebp
f010383c:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f010383e:	83 fa 01             	cmp    $0x1,%edx
f0103841:	7e 0e                	jle    f0103851 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0103843:	8b 10                	mov    (%eax),%edx
f0103845:	8d 4a 08             	lea    0x8(%edx),%ecx
f0103848:	89 08                	mov    %ecx,(%eax)
f010384a:	8b 02                	mov    (%edx),%eax
f010384c:	8b 52 04             	mov    0x4(%edx),%edx
f010384f:	eb 22                	jmp    f0103873 <getuint+0x38>
	else if (lflag)
f0103851:	85 d2                	test   %edx,%edx
f0103853:	74 10                	je     f0103865 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0103855:	8b 10                	mov    (%eax),%edx
f0103857:	8d 4a 04             	lea    0x4(%edx),%ecx
f010385a:	89 08                	mov    %ecx,(%eax)
f010385c:	8b 02                	mov    (%edx),%eax
f010385e:	ba 00 00 00 00       	mov    $0x0,%edx
f0103863:	eb 0e                	jmp    f0103873 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0103865:	8b 10                	mov    (%eax),%edx
f0103867:	8d 4a 04             	lea    0x4(%edx),%ecx
f010386a:	89 08                	mov    %ecx,(%eax)
f010386c:	8b 02                	mov    (%edx),%eax
f010386e:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0103873:	5d                   	pop    %ebp
f0103874:	c3                   	ret    

f0103875 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0103875:	55                   	push   %ebp
f0103876:	89 e5                	mov    %esp,%ebp
f0103878:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f010387b:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f010387f:	8b 10                	mov    (%eax),%edx
f0103881:	3b 50 04             	cmp    0x4(%eax),%edx
f0103884:	73 0a                	jae    f0103890 <sprintputch+0x1b>
		*b->buf++ = ch;
f0103886:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103889:	88 0a                	mov    %cl,(%edx)
f010388b:	83 c2 01             	add    $0x1,%edx
f010388e:	89 10                	mov    %edx,(%eax)
}
f0103890:	5d                   	pop    %ebp
f0103891:	c3                   	ret    

f0103892 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0103892:	55                   	push   %ebp
f0103893:	89 e5                	mov    %esp,%ebp
f0103895:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f0103898:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f010389b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010389f:	8b 45 10             	mov    0x10(%ebp),%eax
f01038a2:	89 44 24 08          	mov    %eax,0x8(%esp)
f01038a6:	8b 45 0c             	mov    0xc(%ebp),%eax
f01038a9:	89 44 24 04          	mov    %eax,0x4(%esp)
f01038ad:	8b 45 08             	mov    0x8(%ebp),%eax
f01038b0:	89 04 24             	mov    %eax,(%esp)
f01038b3:	e8 02 00 00 00       	call   f01038ba <vprintfmt>
	va_end(ap);
}
f01038b8:	c9                   	leave  
f01038b9:	c3                   	ret    

f01038ba <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f01038ba:	55                   	push   %ebp
f01038bb:	89 e5                	mov    %esp,%ebp
f01038bd:	57                   	push   %edi
f01038be:	56                   	push   %esi
f01038bf:	53                   	push   %ebx
f01038c0:	83 ec 4c             	sub    $0x4c,%esp
f01038c3:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01038c6:	8b 75 10             	mov    0x10(%ebp),%esi
f01038c9:	eb 12                	jmp    f01038dd <vprintfmt+0x23>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f01038cb:	85 c0                	test   %eax,%eax
f01038cd:	0f 84 a9 03 00 00    	je     f0103c7c <vprintfmt+0x3c2>
				return;
			putch(ch, putdat);
f01038d3:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01038d7:	89 04 24             	mov    %eax,(%esp)
f01038da:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f01038dd:	0f b6 06             	movzbl (%esi),%eax
f01038e0:	83 c6 01             	add    $0x1,%esi
f01038e3:	83 f8 25             	cmp    $0x25,%eax
f01038e6:	75 e3                	jne    f01038cb <vprintfmt+0x11>
f01038e8:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
f01038ec:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
f01038f3:	bf ff ff ff ff       	mov    $0xffffffff,%edi
f01038f8:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
f01038ff:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103904:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0103907:	eb 2b                	jmp    f0103934 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103909:	8b 75 e0             	mov    -0x20(%ebp),%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f010390c:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
f0103910:	eb 22                	jmp    f0103934 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103912:	8b 75 e0             	mov    -0x20(%ebp),%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0103915:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
f0103919:	eb 19                	jmp    f0103934 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010391b:	8b 75 e0             	mov    -0x20(%ebp),%esi
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
f010391e:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f0103925:	eb 0d                	jmp    f0103934 <vprintfmt+0x7a>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f0103927:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010392a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010392d:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103934:	0f b6 06             	movzbl (%esi),%eax
f0103937:	0f b6 d0             	movzbl %al,%edx
f010393a:	8d 7e 01             	lea    0x1(%esi),%edi
f010393d:	89 7d e0             	mov    %edi,-0x20(%ebp)
f0103940:	83 e8 23             	sub    $0x23,%eax
f0103943:	3c 55                	cmp    $0x55,%al
f0103945:	0f 87 0b 03 00 00    	ja     f0103c56 <vprintfmt+0x39c>
f010394b:	0f b6 c0             	movzbl %al,%eax
f010394e:	ff 24 85 d8 56 10 f0 	jmp    *-0xfefa928(,%eax,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0103955:	83 ea 30             	sub    $0x30,%edx
f0103958:	89 55 d4             	mov    %edx,-0x2c(%ebp)
				ch = *fmt;
f010395b:	0f be 46 01          	movsbl 0x1(%esi),%eax
				if (ch < '0' || ch > '9')
f010395f:	8d 50 d0             	lea    -0x30(%eax),%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103962:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
f0103965:	83 fa 09             	cmp    $0x9,%edx
f0103968:	77 4a                	ja     f01039b4 <vprintfmt+0xfa>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010396a:	8b 7d d4             	mov    -0x2c(%ebp),%edi
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f010396d:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
f0103970:	8d 14 bf             	lea    (%edi,%edi,4),%edx
f0103973:	8d 7c 50 d0          	lea    -0x30(%eax,%edx,2),%edi
				ch = *fmt;
f0103977:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f010397a:	8d 50 d0             	lea    -0x30(%eax),%edx
f010397d:	83 fa 09             	cmp    $0x9,%edx
f0103980:	76 eb                	jbe    f010396d <vprintfmt+0xb3>
f0103982:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0103985:	eb 2d                	jmp    f01039b4 <vprintfmt+0xfa>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0103987:	8b 45 14             	mov    0x14(%ebp),%eax
f010398a:	8d 50 04             	lea    0x4(%eax),%edx
f010398d:	89 55 14             	mov    %edx,0x14(%ebp)
f0103990:	8b 00                	mov    (%eax),%eax
f0103992:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103995:	8b 75 e0             	mov    -0x20(%ebp),%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0103998:	eb 1a                	jmp    f01039b4 <vprintfmt+0xfa>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010399a:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case '*':
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
f010399d:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01039a1:	79 91                	jns    f0103934 <vprintfmt+0x7a>
f01039a3:	e9 73 ff ff ff       	jmp    f010391b <vprintfmt+0x61>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01039a8:	8b 75 e0             	mov    -0x20(%ebp),%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f01039ab:	c7 45 dc 01 00 00 00 	movl   $0x1,-0x24(%ebp)
			goto reswitch;
f01039b2:	eb 80                	jmp    f0103934 <vprintfmt+0x7a>

		process_precision:
			if (width < 0)
f01039b4:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01039b8:	0f 89 76 ff ff ff    	jns    f0103934 <vprintfmt+0x7a>
f01039be:	e9 64 ff ff ff       	jmp    f0103927 <vprintfmt+0x6d>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f01039c3:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01039c6:	8b 75 e0             	mov    -0x20(%ebp),%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f01039c9:	e9 66 ff ff ff       	jmp    f0103934 <vprintfmt+0x7a>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f01039ce:	8b 45 14             	mov    0x14(%ebp),%eax
f01039d1:	8d 50 04             	lea    0x4(%eax),%edx
f01039d4:	89 55 14             	mov    %edx,0x14(%ebp)
f01039d7:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01039db:	8b 00                	mov    (%eax),%eax
f01039dd:	89 04 24             	mov    %eax,(%esp)
f01039e0:	ff 55 08             	call   *0x8(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01039e3:	8b 75 e0             	mov    -0x20(%ebp),%esi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f01039e6:	e9 f2 fe ff ff       	jmp    f01038dd <vprintfmt+0x23>

		// error message
		case 'e':
			err = va_arg(ap, int);
f01039eb:	8b 45 14             	mov    0x14(%ebp),%eax
f01039ee:	8d 50 04             	lea    0x4(%eax),%edx
f01039f1:	89 55 14             	mov    %edx,0x14(%ebp)
f01039f4:	8b 00                	mov    (%eax),%eax
f01039f6:	89 c2                	mov    %eax,%edx
f01039f8:	c1 fa 1f             	sar    $0x1f,%edx
f01039fb:	31 d0                	xor    %edx,%eax
f01039fd:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f01039ff:	83 f8 06             	cmp    $0x6,%eax
f0103a02:	7f 0b                	jg     f0103a0f <vprintfmt+0x155>
f0103a04:	8b 14 85 30 58 10 f0 	mov    -0xfefa7d0(,%eax,4),%edx
f0103a0b:	85 d2                	test   %edx,%edx
f0103a0d:	75 23                	jne    f0103a32 <vprintfmt+0x178>
				printfmt(putch, putdat, "error %d", err);
f0103a0f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103a13:	c7 44 24 08 73 56 10 	movl   $0xf0105673,0x8(%esp)
f0103a1a:	f0 
f0103a1b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103a1f:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103a22:	89 3c 24             	mov    %edi,(%esp)
f0103a25:	e8 68 fe ff ff       	call   f0103892 <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103a2a:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0103a2d:	e9 ab fe ff ff       	jmp    f01038dd <vprintfmt+0x23>
			else
				printfmt(putch, putdat, "%s", p);
f0103a32:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103a36:	c7 44 24 08 98 53 10 	movl   $0xf0105398,0x8(%esp)
f0103a3d:	f0 
f0103a3e:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103a42:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103a45:	89 3c 24             	mov    %edi,(%esp)
f0103a48:	e8 45 fe ff ff       	call   f0103892 <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103a4d:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0103a50:	e9 88 fe ff ff       	jmp    f01038dd <vprintfmt+0x23>
f0103a55:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0103a58:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103a5b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0103a5e:	8b 45 14             	mov    0x14(%ebp),%eax
f0103a61:	8d 50 04             	lea    0x4(%eax),%edx
f0103a64:	89 55 14             	mov    %edx,0x14(%ebp)
f0103a67:	8b 30                	mov    (%eax),%esi
				p = "(null)";
f0103a69:	85 f6                	test   %esi,%esi
f0103a6b:	ba 6c 56 10 f0       	mov    $0xf010566c,%edx
f0103a70:	0f 44 f2             	cmove  %edx,%esi
			if (width > 0 && padc != '-')
f0103a73:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f0103a77:	7e 06                	jle    f0103a7f <vprintfmt+0x1c5>
f0103a79:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
f0103a7d:	75 10                	jne    f0103a8f <vprintfmt+0x1d5>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0103a7f:	0f be 06             	movsbl (%esi),%eax
f0103a82:	83 c6 01             	add    $0x1,%esi
f0103a85:	85 c0                	test   %eax,%eax
f0103a87:	0f 85 86 00 00 00    	jne    f0103b13 <vprintfmt+0x259>
f0103a8d:	eb 76                	jmp    f0103b05 <vprintfmt+0x24b>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0103a8f:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103a93:	89 34 24             	mov    %esi,(%esp)
f0103a96:	e8 60 03 00 00       	call   f0103dfb <strnlen>
f0103a9b:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0103a9e:	29 c2                	sub    %eax,%edx
f0103aa0:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0103aa3:	85 d2                	test   %edx,%edx
f0103aa5:	7e d8                	jle    f0103a7f <vprintfmt+0x1c5>
					putch(padc, putdat);
f0103aa7:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
f0103aab:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f0103aae:	89 d6                	mov    %edx,%esi
f0103ab0:	89 7d d0             	mov    %edi,-0x30(%ebp)
f0103ab3:	89 c7                	mov    %eax,%edi
f0103ab5:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103ab9:	89 3c 24             	mov    %edi,(%esp)
f0103abc:	ff 55 08             	call   *0x8(%ebp)
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0103abf:	83 ee 01             	sub    $0x1,%esi
f0103ac2:	75 f1                	jne    f0103ab5 <vprintfmt+0x1fb>
f0103ac4:	89 75 e4             	mov    %esi,-0x1c(%ebp)
f0103ac7:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f0103aca:	8b 7d d0             	mov    -0x30(%ebp),%edi
f0103acd:	eb b0                	jmp    f0103a7f <vprintfmt+0x1c5>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0103acf:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0103ad3:	74 18                	je     f0103aed <vprintfmt+0x233>
f0103ad5:	8d 50 e0             	lea    -0x20(%eax),%edx
f0103ad8:	83 fa 5e             	cmp    $0x5e,%edx
f0103adb:	76 10                	jbe    f0103aed <vprintfmt+0x233>
					putch('?', putdat);
f0103add:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103ae1:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0103ae8:	ff 55 08             	call   *0x8(%ebp)
f0103aeb:	eb 0a                	jmp    f0103af7 <vprintfmt+0x23d>
				else
					putch(ch, putdat);
f0103aed:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103af1:	89 04 24             	mov    %eax,(%esp)
f0103af4:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0103af7:	83 6d e4 01          	subl   $0x1,-0x1c(%ebp)
f0103afb:	0f be 06             	movsbl (%esi),%eax
f0103afe:	83 c6 01             	add    $0x1,%esi
f0103b01:	85 c0                	test   %eax,%eax
f0103b03:	75 0e                	jne    f0103b13 <vprintfmt+0x259>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103b05:	8b 75 e0             	mov    -0x20(%ebp),%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0103b08:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0103b0c:	7f 16                	jg     f0103b24 <vprintfmt+0x26a>
f0103b0e:	e9 ca fd ff ff       	jmp    f01038dd <vprintfmt+0x23>
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0103b13:	85 ff                	test   %edi,%edi
f0103b15:	78 b8                	js     f0103acf <vprintfmt+0x215>
f0103b17:	83 ef 01             	sub    $0x1,%edi
f0103b1a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103b20:	79 ad                	jns    f0103acf <vprintfmt+0x215>
f0103b22:	eb e1                	jmp    f0103b05 <vprintfmt+0x24b>
f0103b24:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103b27:	8b 7d 08             	mov    0x8(%ebp),%edi
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0103b2a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103b2e:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0103b35:	ff d7                	call   *%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0103b37:	83 ee 01             	sub    $0x1,%esi
f0103b3a:	75 ee                	jne    f0103b2a <vprintfmt+0x270>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103b3c:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0103b3f:	e9 99 fd ff ff       	jmp    f01038dd <vprintfmt+0x23>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0103b44:	83 f9 01             	cmp    $0x1,%ecx
f0103b47:	7e 10                	jle    f0103b59 <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f0103b49:	8b 45 14             	mov    0x14(%ebp),%eax
f0103b4c:	8d 50 08             	lea    0x8(%eax),%edx
f0103b4f:	89 55 14             	mov    %edx,0x14(%ebp)
f0103b52:	8b 30                	mov    (%eax),%esi
f0103b54:	8b 78 04             	mov    0x4(%eax),%edi
f0103b57:	eb 26                	jmp    f0103b7f <vprintfmt+0x2c5>
	else if (lflag)
f0103b59:	85 c9                	test   %ecx,%ecx
f0103b5b:	74 12                	je     f0103b6f <vprintfmt+0x2b5>
		return va_arg(*ap, long);
f0103b5d:	8b 45 14             	mov    0x14(%ebp),%eax
f0103b60:	8d 50 04             	lea    0x4(%eax),%edx
f0103b63:	89 55 14             	mov    %edx,0x14(%ebp)
f0103b66:	8b 30                	mov    (%eax),%esi
f0103b68:	89 f7                	mov    %esi,%edi
f0103b6a:	c1 ff 1f             	sar    $0x1f,%edi
f0103b6d:	eb 10                	jmp    f0103b7f <vprintfmt+0x2c5>
	else
		return va_arg(*ap, int);
f0103b6f:	8b 45 14             	mov    0x14(%ebp),%eax
f0103b72:	8d 50 04             	lea    0x4(%eax),%edx
f0103b75:	89 55 14             	mov    %edx,0x14(%ebp)
f0103b78:	8b 30                	mov    (%eax),%esi
f0103b7a:	89 f7                	mov    %esi,%edi
f0103b7c:	c1 ff 1f             	sar    $0x1f,%edi
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0103b7f:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0103b84:	85 ff                	test   %edi,%edi
f0103b86:	0f 89 8c 00 00 00    	jns    f0103c18 <vprintfmt+0x35e>
				putch('-', putdat);
f0103b8c:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103b90:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f0103b97:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f0103b9a:	f7 de                	neg    %esi
f0103b9c:	83 d7 00             	adc    $0x0,%edi
f0103b9f:	f7 df                	neg    %edi
			}
			base = 10;
f0103ba1:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103ba6:	eb 70                	jmp    f0103c18 <vprintfmt+0x35e>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0103ba8:	89 ca                	mov    %ecx,%edx
f0103baa:	8d 45 14             	lea    0x14(%ebp),%eax
f0103bad:	e8 89 fc ff ff       	call   f010383b <getuint>
f0103bb2:	89 c6                	mov    %eax,%esi
f0103bb4:	89 d7                	mov    %edx,%edi
			base = 10;
f0103bb6:	b8 0a 00 00 00       	mov    $0xa,%eax
			goto number;
f0103bbb:	eb 5b                	jmp    f0103c18 <vprintfmt+0x35e>
			// Replace this with your code.
			//putch('0', putdat);
			//putch('X', putdat);
			//putch('X', putdat);
			//break;
			num = getuint(&ap, lflag);
f0103bbd:	89 ca                	mov    %ecx,%edx
f0103bbf:	8d 45 14             	lea    0x14(%ebp),%eax
f0103bc2:	e8 74 fc ff ff       	call   f010383b <getuint>
f0103bc7:	89 c6                	mov    %eax,%esi
f0103bc9:	89 d7                	mov    %edx,%edi
			base = 8;
f0103bcb:	b8 08 00 00 00       	mov    $0x8,%eax
			goto number;
f0103bd0:	eb 46                	jmp    f0103c18 <vprintfmt+0x35e>
		// pointer
		case 'p':
			putch('0', putdat);
f0103bd2:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103bd6:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f0103bdd:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f0103be0:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103be4:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f0103beb:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0103bee:	8b 45 14             	mov    0x14(%ebp),%eax
f0103bf1:	8d 50 04             	lea    0x4(%eax),%edx
f0103bf4:	89 55 14             	mov    %edx,0x14(%ebp)
			goto number;
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0103bf7:	8b 30                	mov    (%eax),%esi
f0103bf9:	bf 00 00 00 00       	mov    $0x0,%edi
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0103bfe:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f0103c03:	eb 13                	jmp    f0103c18 <vprintfmt+0x35e>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0103c05:	89 ca                	mov    %ecx,%edx
f0103c07:	8d 45 14             	lea    0x14(%ebp),%eax
f0103c0a:	e8 2c fc ff ff       	call   f010383b <getuint>
f0103c0f:	89 c6                	mov    %eax,%esi
f0103c11:	89 d7                	mov    %edx,%edi
			base = 16;
f0103c13:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f0103c18:	0f be 55 d8          	movsbl -0x28(%ebp),%edx
f0103c1c:	89 54 24 10          	mov    %edx,0x10(%esp)
f0103c20:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0103c23:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103c27:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103c2b:	89 34 24             	mov    %esi,(%esp)
f0103c2e:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103c32:	89 da                	mov    %ebx,%edx
f0103c34:	8b 45 08             	mov    0x8(%ebp),%eax
f0103c37:	e8 24 fb ff ff       	call   f0103760 <printnum>
			break;
f0103c3c:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0103c3f:	e9 99 fc ff ff       	jmp    f01038dd <vprintfmt+0x23>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0103c44:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103c48:	89 14 24             	mov    %edx,(%esp)
f0103c4b:	ff 55 08             	call   *0x8(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103c4e:	8b 75 e0             	mov    -0x20(%ebp),%esi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0103c51:	e9 87 fc ff ff       	jmp    f01038dd <vprintfmt+0x23>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0103c56:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103c5a:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0103c61:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0103c64:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
f0103c68:	0f 84 6f fc ff ff    	je     f01038dd <vprintfmt+0x23>
f0103c6e:	83 ee 01             	sub    $0x1,%esi
f0103c71:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
f0103c75:	75 f7                	jne    f0103c6e <vprintfmt+0x3b4>
f0103c77:	e9 61 fc ff ff       	jmp    f01038dd <vprintfmt+0x23>
				/* do nothing */;
			break;
		}
	}
}
f0103c7c:	83 c4 4c             	add    $0x4c,%esp
f0103c7f:	5b                   	pop    %ebx
f0103c80:	5e                   	pop    %esi
f0103c81:	5f                   	pop    %edi
f0103c82:	5d                   	pop    %ebp
f0103c83:	c3                   	ret    

f0103c84 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0103c84:	55                   	push   %ebp
f0103c85:	89 e5                	mov    %esp,%ebp
f0103c87:	83 ec 28             	sub    $0x28,%esp
f0103c8a:	8b 45 08             	mov    0x8(%ebp),%eax
f0103c8d:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0103c90:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103c93:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0103c97:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0103c9a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0103ca1:	85 c0                	test   %eax,%eax
f0103ca3:	74 30                	je     f0103cd5 <vsnprintf+0x51>
f0103ca5:	85 d2                	test   %edx,%edx
f0103ca7:	7e 2c                	jle    f0103cd5 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0103ca9:	8b 45 14             	mov    0x14(%ebp),%eax
f0103cac:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103cb0:	8b 45 10             	mov    0x10(%ebp),%eax
f0103cb3:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103cb7:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0103cba:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103cbe:	c7 04 24 75 38 10 f0 	movl   $0xf0103875,(%esp)
f0103cc5:	e8 f0 fb ff ff       	call   f01038ba <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0103cca:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0103ccd:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0103cd0:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103cd3:	eb 05                	jmp    f0103cda <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0103cd5:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0103cda:	c9                   	leave  
f0103cdb:	c3                   	ret    

f0103cdc <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0103cdc:	55                   	push   %ebp
f0103cdd:	89 e5                	mov    %esp,%ebp
f0103cdf:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0103ce2:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0103ce5:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103ce9:	8b 45 10             	mov    0x10(%ebp),%eax
f0103cec:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103cf0:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103cf3:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103cf7:	8b 45 08             	mov    0x8(%ebp),%eax
f0103cfa:	89 04 24             	mov    %eax,(%esp)
f0103cfd:	e8 82 ff ff ff       	call   f0103c84 <vsnprintf>
	va_end(ap);

	return rc;
}
f0103d02:	c9                   	leave  
f0103d03:	c3                   	ret    
	...

f0103d10 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0103d10:	55                   	push   %ebp
f0103d11:	89 e5                	mov    %esp,%ebp
f0103d13:	57                   	push   %edi
f0103d14:	56                   	push   %esi
f0103d15:	53                   	push   %ebx
f0103d16:	83 ec 1c             	sub    $0x1c,%esp
f0103d19:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0103d1c:	85 c0                	test   %eax,%eax
f0103d1e:	74 10                	je     f0103d30 <readline+0x20>
		cprintf("%s", prompt);
f0103d20:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103d24:	c7 04 24 98 53 10 f0 	movl   $0xf0105398,(%esp)
f0103d2b:	e8 ce f6 ff ff       	call   f01033fe <cprintf>

	i = 0;
	echoing = iscons(0);
f0103d30:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0103d37:	e8 de c8 ff ff       	call   f010061a <iscons>
f0103d3c:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0103d3e:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0103d43:	e8 c1 c8 ff ff       	call   f0100609 <getchar>
f0103d48:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0103d4a:	85 c0                	test   %eax,%eax
f0103d4c:	79 17                	jns    f0103d65 <readline+0x55>
			cprintf("read error: %e\n", c);
f0103d4e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103d52:	c7 04 24 4c 58 10 f0 	movl   $0xf010584c,(%esp)
f0103d59:	e8 a0 f6 ff ff       	call   f01033fe <cprintf>
			return NULL;
f0103d5e:	b8 00 00 00 00       	mov    $0x0,%eax
f0103d63:	eb 6d                	jmp    f0103dd2 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0103d65:	83 f8 08             	cmp    $0x8,%eax
f0103d68:	74 05                	je     f0103d6f <readline+0x5f>
f0103d6a:	83 f8 7f             	cmp    $0x7f,%eax
f0103d6d:	75 19                	jne    f0103d88 <readline+0x78>
f0103d6f:	85 f6                	test   %esi,%esi
f0103d71:	7e 15                	jle    f0103d88 <readline+0x78>
			if (echoing)
f0103d73:	85 ff                	test   %edi,%edi
f0103d75:	74 0c                	je     f0103d83 <readline+0x73>
				cputchar('\b');
f0103d77:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f0103d7e:	e8 76 c8 ff ff       	call   f01005f9 <cputchar>
			i--;
f0103d83:	83 ee 01             	sub    $0x1,%esi
f0103d86:	eb bb                	jmp    f0103d43 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0103d88:	83 fb 1f             	cmp    $0x1f,%ebx
f0103d8b:	7e 1f                	jle    f0103dac <readline+0x9c>
f0103d8d:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0103d93:	7f 17                	jg     f0103dac <readline+0x9c>
			if (echoing)
f0103d95:	85 ff                	test   %edi,%edi
f0103d97:	74 08                	je     f0103da1 <readline+0x91>
				cputchar(c);
f0103d99:	89 1c 24             	mov    %ebx,(%esp)
f0103d9c:	e8 58 c8 ff ff       	call   f01005f9 <cputchar>
			buf[i++] = c;
f0103da1:	88 9e 80 95 11 f0    	mov    %bl,-0xfee6a80(%esi)
f0103da7:	83 c6 01             	add    $0x1,%esi
f0103daa:	eb 97                	jmp    f0103d43 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f0103dac:	83 fb 0a             	cmp    $0xa,%ebx
f0103daf:	74 05                	je     f0103db6 <readline+0xa6>
f0103db1:	83 fb 0d             	cmp    $0xd,%ebx
f0103db4:	75 8d                	jne    f0103d43 <readline+0x33>
			if (echoing)
f0103db6:	85 ff                	test   %edi,%edi
f0103db8:	74 0c                	je     f0103dc6 <readline+0xb6>
				cputchar('\n');
f0103dba:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0103dc1:	e8 33 c8 ff ff       	call   f01005f9 <cputchar>
			buf[i] = 0;
f0103dc6:	c6 86 80 95 11 f0 00 	movb   $0x0,-0xfee6a80(%esi)
			return buf;
f0103dcd:	b8 80 95 11 f0       	mov    $0xf0119580,%eax
		}
	}
}
f0103dd2:	83 c4 1c             	add    $0x1c,%esp
f0103dd5:	5b                   	pop    %ebx
f0103dd6:	5e                   	pop    %esi
f0103dd7:	5f                   	pop    %edi
f0103dd8:	5d                   	pop    %ebp
f0103dd9:	c3                   	ret    
f0103dda:	00 00                	add    %al,(%eax)
f0103ddc:	00 00                	add    %al,(%eax)
	...

f0103de0 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0103de0:	55                   	push   %ebp
f0103de1:	89 e5                	mov    %esp,%ebp
f0103de3:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0103de6:	b8 00 00 00 00       	mov    $0x0,%eax
f0103deb:	80 3a 00             	cmpb   $0x0,(%edx)
f0103dee:	74 09                	je     f0103df9 <strlen+0x19>
		n++;
f0103df0:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0103df3:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0103df7:	75 f7                	jne    f0103df0 <strlen+0x10>
		n++;
	return n;
}
f0103df9:	5d                   	pop    %ebp
f0103dfa:	c3                   	ret    

f0103dfb <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0103dfb:	55                   	push   %ebp
f0103dfc:	89 e5                	mov    %esp,%ebp
f0103dfe:	53                   	push   %ebx
f0103dff:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103e02:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103e05:	b8 00 00 00 00       	mov    $0x0,%eax
f0103e0a:	85 c9                	test   %ecx,%ecx
f0103e0c:	74 1a                	je     f0103e28 <strnlen+0x2d>
f0103e0e:	80 3b 00             	cmpb   $0x0,(%ebx)
f0103e11:	74 15                	je     f0103e28 <strnlen+0x2d>
f0103e13:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
f0103e18:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103e1a:	39 ca                	cmp    %ecx,%edx
f0103e1c:	74 0a                	je     f0103e28 <strnlen+0x2d>
f0103e1e:	83 c2 01             	add    $0x1,%edx
f0103e21:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
f0103e26:	75 f0                	jne    f0103e18 <strnlen+0x1d>
		n++;
	return n;
}
f0103e28:	5b                   	pop    %ebx
f0103e29:	5d                   	pop    %ebp
f0103e2a:	c3                   	ret    

f0103e2b <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0103e2b:	55                   	push   %ebp
f0103e2c:	89 e5                	mov    %esp,%ebp
f0103e2e:	53                   	push   %ebx
f0103e2f:	8b 45 08             	mov    0x8(%ebp),%eax
f0103e32:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0103e35:	ba 00 00 00 00       	mov    $0x0,%edx
f0103e3a:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f0103e3e:	88 0c 10             	mov    %cl,(%eax,%edx,1)
f0103e41:	83 c2 01             	add    $0x1,%edx
f0103e44:	84 c9                	test   %cl,%cl
f0103e46:	75 f2                	jne    f0103e3a <strcpy+0xf>
		/* do nothing */;
	return ret;
}
f0103e48:	5b                   	pop    %ebx
f0103e49:	5d                   	pop    %ebp
f0103e4a:	c3                   	ret    

f0103e4b <strcat>:

char *
strcat(char *dst, const char *src)
{
f0103e4b:	55                   	push   %ebp
f0103e4c:	89 e5                	mov    %esp,%ebp
f0103e4e:	53                   	push   %ebx
f0103e4f:	83 ec 08             	sub    $0x8,%esp
f0103e52:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0103e55:	89 1c 24             	mov    %ebx,(%esp)
f0103e58:	e8 83 ff ff ff       	call   f0103de0 <strlen>
	strcpy(dst + len, src);
f0103e5d:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103e60:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103e64:	01 d8                	add    %ebx,%eax
f0103e66:	89 04 24             	mov    %eax,(%esp)
f0103e69:	e8 bd ff ff ff       	call   f0103e2b <strcpy>
	return dst;
}
f0103e6e:	89 d8                	mov    %ebx,%eax
f0103e70:	83 c4 08             	add    $0x8,%esp
f0103e73:	5b                   	pop    %ebx
f0103e74:	5d                   	pop    %ebp
f0103e75:	c3                   	ret    

f0103e76 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0103e76:	55                   	push   %ebp
f0103e77:	89 e5                	mov    %esp,%ebp
f0103e79:	56                   	push   %esi
f0103e7a:	53                   	push   %ebx
f0103e7b:	8b 45 08             	mov    0x8(%ebp),%eax
f0103e7e:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103e81:	8b 75 10             	mov    0x10(%ebp),%esi
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103e84:	85 f6                	test   %esi,%esi
f0103e86:	74 18                	je     f0103ea0 <strncpy+0x2a>
f0103e88:	b9 00 00 00 00       	mov    $0x0,%ecx
		*dst++ = *src;
f0103e8d:	0f b6 1a             	movzbl (%edx),%ebx
f0103e90:	88 1c 08             	mov    %bl,(%eax,%ecx,1)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0103e93:	80 3a 01             	cmpb   $0x1,(%edx)
f0103e96:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103e99:	83 c1 01             	add    $0x1,%ecx
f0103e9c:	39 f1                	cmp    %esi,%ecx
f0103e9e:	75 ed                	jne    f0103e8d <strncpy+0x17>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0103ea0:	5b                   	pop    %ebx
f0103ea1:	5e                   	pop    %esi
f0103ea2:	5d                   	pop    %ebp
f0103ea3:	c3                   	ret    

f0103ea4 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0103ea4:	55                   	push   %ebp
f0103ea5:	89 e5                	mov    %esp,%ebp
f0103ea7:	57                   	push   %edi
f0103ea8:	56                   	push   %esi
f0103ea9:	53                   	push   %ebx
f0103eaa:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103ead:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103eb0:	8b 75 10             	mov    0x10(%ebp),%esi
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0103eb3:	89 f8                	mov    %edi,%eax
f0103eb5:	85 f6                	test   %esi,%esi
f0103eb7:	74 2b                	je     f0103ee4 <strlcpy+0x40>
		while (--size > 0 && *src != '\0')
f0103eb9:	83 fe 01             	cmp    $0x1,%esi
f0103ebc:	74 23                	je     f0103ee1 <strlcpy+0x3d>
f0103ebe:	0f b6 0b             	movzbl (%ebx),%ecx
f0103ec1:	84 c9                	test   %cl,%cl
f0103ec3:	74 1c                	je     f0103ee1 <strlcpy+0x3d>
	}
	return ret;
}

size_t
strlcpy(char *dst, const char *src, size_t size)
f0103ec5:	83 ee 02             	sub    $0x2,%esi
f0103ec8:	ba 00 00 00 00       	mov    $0x0,%edx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0103ecd:	88 08                	mov    %cl,(%eax)
f0103ecf:	83 c0 01             	add    $0x1,%eax
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0103ed2:	39 f2                	cmp    %esi,%edx
f0103ed4:	74 0b                	je     f0103ee1 <strlcpy+0x3d>
f0103ed6:	83 c2 01             	add    $0x1,%edx
f0103ed9:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f0103edd:	84 c9                	test   %cl,%cl
f0103edf:	75 ec                	jne    f0103ecd <strlcpy+0x29>
			*dst++ = *src++;
		*dst = '\0';
f0103ee1:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0103ee4:	29 f8                	sub    %edi,%eax
}
f0103ee6:	5b                   	pop    %ebx
f0103ee7:	5e                   	pop    %esi
f0103ee8:	5f                   	pop    %edi
f0103ee9:	5d                   	pop    %ebp
f0103eea:	c3                   	ret    

f0103eeb <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0103eeb:	55                   	push   %ebp
f0103eec:	89 e5                	mov    %esp,%ebp
f0103eee:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103ef1:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0103ef4:	0f b6 01             	movzbl (%ecx),%eax
f0103ef7:	84 c0                	test   %al,%al
f0103ef9:	74 16                	je     f0103f11 <strcmp+0x26>
f0103efb:	3a 02                	cmp    (%edx),%al
f0103efd:	75 12                	jne    f0103f11 <strcmp+0x26>
		p++, q++;
f0103eff:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0103f02:	0f b6 41 01          	movzbl 0x1(%ecx),%eax
f0103f06:	84 c0                	test   %al,%al
f0103f08:	74 07                	je     f0103f11 <strcmp+0x26>
f0103f0a:	83 c1 01             	add    $0x1,%ecx
f0103f0d:	3a 02                	cmp    (%edx),%al
f0103f0f:	74 ee                	je     f0103eff <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0103f11:	0f b6 c0             	movzbl %al,%eax
f0103f14:	0f b6 12             	movzbl (%edx),%edx
f0103f17:	29 d0                	sub    %edx,%eax
}
f0103f19:	5d                   	pop    %ebp
f0103f1a:	c3                   	ret    

f0103f1b <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0103f1b:	55                   	push   %ebp
f0103f1c:	89 e5                	mov    %esp,%ebp
f0103f1e:	53                   	push   %ebx
f0103f1f:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103f22:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103f25:	8b 55 10             	mov    0x10(%ebp),%edx
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0103f28:	b8 00 00 00 00       	mov    $0x0,%eax
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0103f2d:	85 d2                	test   %edx,%edx
f0103f2f:	74 28                	je     f0103f59 <strncmp+0x3e>
f0103f31:	0f b6 01             	movzbl (%ecx),%eax
f0103f34:	84 c0                	test   %al,%al
f0103f36:	74 24                	je     f0103f5c <strncmp+0x41>
f0103f38:	3a 03                	cmp    (%ebx),%al
f0103f3a:	75 20                	jne    f0103f5c <strncmp+0x41>
f0103f3c:	83 ea 01             	sub    $0x1,%edx
f0103f3f:	74 13                	je     f0103f54 <strncmp+0x39>
		n--, p++, q++;
f0103f41:	83 c1 01             	add    $0x1,%ecx
f0103f44:	83 c3 01             	add    $0x1,%ebx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0103f47:	0f b6 01             	movzbl (%ecx),%eax
f0103f4a:	84 c0                	test   %al,%al
f0103f4c:	74 0e                	je     f0103f5c <strncmp+0x41>
f0103f4e:	3a 03                	cmp    (%ebx),%al
f0103f50:	74 ea                	je     f0103f3c <strncmp+0x21>
f0103f52:	eb 08                	jmp    f0103f5c <strncmp+0x41>
		n--, p++, q++;
	if (n == 0)
		return 0;
f0103f54:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0103f59:	5b                   	pop    %ebx
f0103f5a:	5d                   	pop    %ebp
f0103f5b:	c3                   	ret    
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0103f5c:	0f b6 01             	movzbl (%ecx),%eax
f0103f5f:	0f b6 13             	movzbl (%ebx),%edx
f0103f62:	29 d0                	sub    %edx,%eax
f0103f64:	eb f3                	jmp    f0103f59 <strncmp+0x3e>

f0103f66 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0103f66:	55                   	push   %ebp
f0103f67:	89 e5                	mov    %esp,%ebp
f0103f69:	8b 45 08             	mov    0x8(%ebp),%eax
f0103f6c:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103f70:	0f b6 10             	movzbl (%eax),%edx
f0103f73:	84 d2                	test   %dl,%dl
f0103f75:	74 1c                	je     f0103f93 <strchr+0x2d>
		if (*s == c)
f0103f77:	38 ca                	cmp    %cl,%dl
f0103f79:	75 09                	jne    f0103f84 <strchr+0x1e>
f0103f7b:	eb 1b                	jmp    f0103f98 <strchr+0x32>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0103f7d:	83 c0 01             	add    $0x1,%eax
		if (*s == c)
f0103f80:	38 ca                	cmp    %cl,%dl
f0103f82:	74 14                	je     f0103f98 <strchr+0x32>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0103f84:	0f b6 50 01          	movzbl 0x1(%eax),%edx
f0103f88:	84 d2                	test   %dl,%dl
f0103f8a:	75 f1                	jne    f0103f7d <strchr+0x17>
		if (*s == c)
			return (char *) s;
	return 0;
f0103f8c:	b8 00 00 00 00       	mov    $0x0,%eax
f0103f91:	eb 05                	jmp    f0103f98 <strchr+0x32>
f0103f93:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103f98:	5d                   	pop    %ebp
f0103f99:	c3                   	ret    

f0103f9a <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0103f9a:	55                   	push   %ebp
f0103f9b:	89 e5                	mov    %esp,%ebp
f0103f9d:	8b 45 08             	mov    0x8(%ebp),%eax
f0103fa0:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103fa4:	0f b6 10             	movzbl (%eax),%edx
f0103fa7:	84 d2                	test   %dl,%dl
f0103fa9:	74 14                	je     f0103fbf <strfind+0x25>
		if (*s == c)
f0103fab:	38 ca                	cmp    %cl,%dl
f0103fad:	75 06                	jne    f0103fb5 <strfind+0x1b>
f0103faf:	eb 0e                	jmp    f0103fbf <strfind+0x25>
f0103fb1:	38 ca                	cmp    %cl,%dl
f0103fb3:	74 0a                	je     f0103fbf <strfind+0x25>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f0103fb5:	83 c0 01             	add    $0x1,%eax
f0103fb8:	0f b6 10             	movzbl (%eax),%edx
f0103fbb:	84 d2                	test   %dl,%dl
f0103fbd:	75 f2                	jne    f0103fb1 <strfind+0x17>
		if (*s == c)
			break;
	return (char *) s;
}
f0103fbf:	5d                   	pop    %ebp
f0103fc0:	c3                   	ret    

f0103fc1 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0103fc1:	55                   	push   %ebp
f0103fc2:	89 e5                	mov    %esp,%ebp
f0103fc4:	83 ec 0c             	sub    $0xc,%esp
f0103fc7:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0103fca:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0103fcd:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0103fd0:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103fd3:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103fd6:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0103fd9:	85 c9                	test   %ecx,%ecx
f0103fdb:	74 30                	je     f010400d <memset+0x4c>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0103fdd:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0103fe3:	75 25                	jne    f010400a <memset+0x49>
f0103fe5:	f6 c1 03             	test   $0x3,%cl
f0103fe8:	75 20                	jne    f010400a <memset+0x49>
		c &= 0xFF;
f0103fea:	0f b6 d0             	movzbl %al,%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0103fed:	89 d3                	mov    %edx,%ebx
f0103fef:	c1 e3 08             	shl    $0x8,%ebx
f0103ff2:	89 d6                	mov    %edx,%esi
f0103ff4:	c1 e6 18             	shl    $0x18,%esi
f0103ff7:	89 d0                	mov    %edx,%eax
f0103ff9:	c1 e0 10             	shl    $0x10,%eax
f0103ffc:	09 f0                	or     %esi,%eax
f0103ffe:	09 d0                	or     %edx,%eax
f0104000:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0104002:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f0104005:	fc                   	cld    
f0104006:	f3 ab                	rep stos %eax,%es:(%edi)
f0104008:	eb 03                	jmp    f010400d <memset+0x4c>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f010400a:	fc                   	cld    
f010400b:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f010400d:	89 f8                	mov    %edi,%eax
f010400f:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0104012:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0104015:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0104018:	89 ec                	mov    %ebp,%esp
f010401a:	5d                   	pop    %ebp
f010401b:	c3                   	ret    

f010401c <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f010401c:	55                   	push   %ebp
f010401d:	89 e5                	mov    %esp,%ebp
f010401f:	83 ec 08             	sub    $0x8,%esp
f0104022:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0104025:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0104028:	8b 45 08             	mov    0x8(%ebp),%eax
f010402b:	8b 75 0c             	mov    0xc(%ebp),%esi
f010402e:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0104031:	39 c6                	cmp    %eax,%esi
f0104033:	73 36                	jae    f010406b <memmove+0x4f>
f0104035:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0104038:	39 d0                	cmp    %edx,%eax
f010403a:	73 2f                	jae    f010406b <memmove+0x4f>
		s += n;
		d += n;
f010403c:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010403f:	f6 c2 03             	test   $0x3,%dl
f0104042:	75 1b                	jne    f010405f <memmove+0x43>
f0104044:	f7 c7 03 00 00 00    	test   $0x3,%edi
f010404a:	75 13                	jne    f010405f <memmove+0x43>
f010404c:	f6 c1 03             	test   $0x3,%cl
f010404f:	75 0e                	jne    f010405f <memmove+0x43>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0104051:	83 ef 04             	sub    $0x4,%edi
f0104054:	8d 72 fc             	lea    -0x4(%edx),%esi
f0104057:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f010405a:	fd                   	std    
f010405b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010405d:	eb 09                	jmp    f0104068 <memmove+0x4c>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f010405f:	83 ef 01             	sub    $0x1,%edi
f0104062:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0104065:	fd                   	std    
f0104066:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0104068:	fc                   	cld    
f0104069:	eb 20                	jmp    f010408b <memmove+0x6f>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010406b:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0104071:	75 13                	jne    f0104086 <memmove+0x6a>
f0104073:	a8 03                	test   $0x3,%al
f0104075:	75 0f                	jne    f0104086 <memmove+0x6a>
f0104077:	f6 c1 03             	test   $0x3,%cl
f010407a:	75 0a                	jne    f0104086 <memmove+0x6a>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f010407c:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f010407f:	89 c7                	mov    %eax,%edi
f0104081:	fc                   	cld    
f0104082:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0104084:	eb 05                	jmp    f010408b <memmove+0x6f>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0104086:	89 c7                	mov    %eax,%edi
f0104088:	fc                   	cld    
f0104089:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f010408b:	8b 75 f8             	mov    -0x8(%ebp),%esi
f010408e:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0104091:	89 ec                	mov    %ebp,%esp
f0104093:	5d                   	pop    %ebp
f0104094:	c3                   	ret    

f0104095 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0104095:	55                   	push   %ebp
f0104096:	89 e5                	mov    %esp,%ebp
f0104098:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f010409b:	8b 45 10             	mov    0x10(%ebp),%eax
f010409e:	89 44 24 08          	mov    %eax,0x8(%esp)
f01040a2:	8b 45 0c             	mov    0xc(%ebp),%eax
f01040a5:	89 44 24 04          	mov    %eax,0x4(%esp)
f01040a9:	8b 45 08             	mov    0x8(%ebp),%eax
f01040ac:	89 04 24             	mov    %eax,(%esp)
f01040af:	e8 68 ff ff ff       	call   f010401c <memmove>
}
f01040b4:	c9                   	leave  
f01040b5:	c3                   	ret    

f01040b6 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f01040b6:	55                   	push   %ebp
f01040b7:	89 e5                	mov    %esp,%ebp
f01040b9:	57                   	push   %edi
f01040ba:	56                   	push   %esi
f01040bb:	53                   	push   %ebx
f01040bc:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01040bf:	8b 75 0c             	mov    0xc(%ebp),%esi
f01040c2:	8b 7d 10             	mov    0x10(%ebp),%edi
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01040c5:	b8 00 00 00 00       	mov    $0x0,%eax
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01040ca:	85 ff                	test   %edi,%edi
f01040cc:	74 37                	je     f0104105 <memcmp+0x4f>
		if (*s1 != *s2)
f01040ce:	0f b6 03             	movzbl (%ebx),%eax
f01040d1:	0f b6 0e             	movzbl (%esi),%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01040d4:	83 ef 01             	sub    $0x1,%edi
f01040d7:	ba 00 00 00 00       	mov    $0x0,%edx
		if (*s1 != *s2)
f01040dc:	38 c8                	cmp    %cl,%al
f01040de:	74 1c                	je     f01040fc <memcmp+0x46>
f01040e0:	eb 10                	jmp    f01040f2 <memcmp+0x3c>
f01040e2:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
f01040e7:	83 c2 01             	add    $0x1,%edx
f01040ea:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
f01040ee:	38 c8                	cmp    %cl,%al
f01040f0:	74 0a                	je     f01040fc <memcmp+0x46>
			return (int) *s1 - (int) *s2;
f01040f2:	0f b6 c0             	movzbl %al,%eax
f01040f5:	0f b6 c9             	movzbl %cl,%ecx
f01040f8:	29 c8                	sub    %ecx,%eax
f01040fa:	eb 09                	jmp    f0104105 <memcmp+0x4f>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01040fc:	39 fa                	cmp    %edi,%edx
f01040fe:	75 e2                	jne    f01040e2 <memcmp+0x2c>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0104100:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104105:	5b                   	pop    %ebx
f0104106:	5e                   	pop    %esi
f0104107:	5f                   	pop    %edi
f0104108:	5d                   	pop    %ebp
f0104109:	c3                   	ret    

f010410a <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f010410a:	55                   	push   %ebp
f010410b:	89 e5                	mov    %esp,%ebp
f010410d:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0104110:	89 c2                	mov    %eax,%edx
f0104112:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0104115:	39 d0                	cmp    %edx,%eax
f0104117:	73 19                	jae    f0104132 <memfind+0x28>
		if (*(const unsigned char *) s == (unsigned char) c)
f0104119:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
f010411d:	38 08                	cmp    %cl,(%eax)
f010411f:	75 06                	jne    f0104127 <memfind+0x1d>
f0104121:	eb 0f                	jmp    f0104132 <memfind+0x28>
f0104123:	38 08                	cmp    %cl,(%eax)
f0104125:	74 0b                	je     f0104132 <memfind+0x28>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0104127:	83 c0 01             	add    $0x1,%eax
f010412a:	39 d0                	cmp    %edx,%eax
f010412c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104130:	75 f1                	jne    f0104123 <memfind+0x19>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0104132:	5d                   	pop    %ebp
f0104133:	c3                   	ret    

f0104134 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0104134:	55                   	push   %ebp
f0104135:	89 e5                	mov    %esp,%ebp
f0104137:	57                   	push   %edi
f0104138:	56                   	push   %esi
f0104139:	53                   	push   %ebx
f010413a:	8b 55 08             	mov    0x8(%ebp),%edx
f010413d:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0104140:	0f b6 02             	movzbl (%edx),%eax
f0104143:	3c 20                	cmp    $0x20,%al
f0104145:	74 04                	je     f010414b <strtol+0x17>
f0104147:	3c 09                	cmp    $0x9,%al
f0104149:	75 0e                	jne    f0104159 <strtol+0x25>
		s++;
f010414b:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f010414e:	0f b6 02             	movzbl (%edx),%eax
f0104151:	3c 20                	cmp    $0x20,%al
f0104153:	74 f6                	je     f010414b <strtol+0x17>
f0104155:	3c 09                	cmp    $0x9,%al
f0104157:	74 f2                	je     f010414b <strtol+0x17>
		s++;

	// plus/minus sign
	if (*s == '+')
f0104159:	3c 2b                	cmp    $0x2b,%al
f010415b:	75 0a                	jne    f0104167 <strtol+0x33>
		s++;
f010415d:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0104160:	bf 00 00 00 00       	mov    $0x0,%edi
f0104165:	eb 10                	jmp    f0104177 <strtol+0x43>
f0104167:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f010416c:	3c 2d                	cmp    $0x2d,%al
f010416e:	75 07                	jne    f0104177 <strtol+0x43>
		s++, neg = 1;
f0104170:	83 c2 01             	add    $0x1,%edx
f0104173:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0104177:	85 db                	test   %ebx,%ebx
f0104179:	0f 94 c0             	sete   %al
f010417c:	74 05                	je     f0104183 <strtol+0x4f>
f010417e:	83 fb 10             	cmp    $0x10,%ebx
f0104181:	75 15                	jne    f0104198 <strtol+0x64>
f0104183:	80 3a 30             	cmpb   $0x30,(%edx)
f0104186:	75 10                	jne    f0104198 <strtol+0x64>
f0104188:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f010418c:	75 0a                	jne    f0104198 <strtol+0x64>
		s += 2, base = 16;
f010418e:	83 c2 02             	add    $0x2,%edx
f0104191:	bb 10 00 00 00       	mov    $0x10,%ebx
f0104196:	eb 13                	jmp    f01041ab <strtol+0x77>
	else if (base == 0 && s[0] == '0')
f0104198:	84 c0                	test   %al,%al
f010419a:	74 0f                	je     f01041ab <strtol+0x77>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f010419c:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f01041a1:	80 3a 30             	cmpb   $0x30,(%edx)
f01041a4:	75 05                	jne    f01041ab <strtol+0x77>
		s++, base = 8;
f01041a6:	83 c2 01             	add    $0x1,%edx
f01041a9:	b3 08                	mov    $0x8,%bl
	else if (base == 0)
		base = 10;
f01041ab:	b8 00 00 00 00       	mov    $0x0,%eax
f01041b0:	89 de                	mov    %ebx,%esi

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f01041b2:	0f b6 0a             	movzbl (%edx),%ecx
f01041b5:	8d 59 d0             	lea    -0x30(%ecx),%ebx
f01041b8:	80 fb 09             	cmp    $0x9,%bl
f01041bb:	77 08                	ja     f01041c5 <strtol+0x91>
			dig = *s - '0';
f01041bd:	0f be c9             	movsbl %cl,%ecx
f01041c0:	83 e9 30             	sub    $0x30,%ecx
f01041c3:	eb 1e                	jmp    f01041e3 <strtol+0xaf>
		else if (*s >= 'a' && *s <= 'z')
f01041c5:	8d 59 9f             	lea    -0x61(%ecx),%ebx
f01041c8:	80 fb 19             	cmp    $0x19,%bl
f01041cb:	77 08                	ja     f01041d5 <strtol+0xa1>
			dig = *s - 'a' + 10;
f01041cd:	0f be c9             	movsbl %cl,%ecx
f01041d0:	83 e9 57             	sub    $0x57,%ecx
f01041d3:	eb 0e                	jmp    f01041e3 <strtol+0xaf>
		else if (*s >= 'A' && *s <= 'Z')
f01041d5:	8d 59 bf             	lea    -0x41(%ecx),%ebx
f01041d8:	80 fb 19             	cmp    $0x19,%bl
f01041db:	77 14                	ja     f01041f1 <strtol+0xbd>
			dig = *s - 'A' + 10;
f01041dd:	0f be c9             	movsbl %cl,%ecx
f01041e0:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f01041e3:	39 f1                	cmp    %esi,%ecx
f01041e5:	7d 0e                	jge    f01041f5 <strtol+0xc1>
			break;
		s++, val = (val * base) + dig;
f01041e7:	83 c2 01             	add    $0x1,%edx
f01041ea:	0f af c6             	imul   %esi,%eax
f01041ed:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
f01041ef:	eb c1                	jmp    f01041b2 <strtol+0x7e>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
f01041f1:	89 c1                	mov    %eax,%ecx
f01041f3:	eb 02                	jmp    f01041f7 <strtol+0xc3>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f01041f5:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
f01041f7:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f01041fb:	74 05                	je     f0104202 <strtol+0xce>
		*endptr = (char *) s;
f01041fd:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104200:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
f0104202:	89 ca                	mov    %ecx,%edx
f0104204:	f7 da                	neg    %edx
f0104206:	85 ff                	test   %edi,%edi
f0104208:	0f 45 c2             	cmovne %edx,%eax
}
f010420b:	5b                   	pop    %ebx
f010420c:	5e                   	pop    %esi
f010420d:	5f                   	pop    %edi
f010420e:	5d                   	pop    %ebp
f010420f:	c3                   	ret    

f0104210 <__udivdi3>:
f0104210:	83 ec 1c             	sub    $0x1c,%esp
f0104213:	89 7c 24 14          	mov    %edi,0x14(%esp)
f0104217:	8b 7c 24 2c          	mov    0x2c(%esp),%edi
f010421b:	8b 44 24 20          	mov    0x20(%esp),%eax
f010421f:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0104223:	89 74 24 10          	mov    %esi,0x10(%esp)
f0104227:	8b 74 24 24          	mov    0x24(%esp),%esi
f010422b:	85 ff                	test   %edi,%edi
f010422d:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f0104231:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104235:	89 cd                	mov    %ecx,%ebp
f0104237:	89 44 24 04          	mov    %eax,0x4(%esp)
f010423b:	75 33                	jne    f0104270 <__udivdi3+0x60>
f010423d:	39 f1                	cmp    %esi,%ecx
f010423f:	77 57                	ja     f0104298 <__udivdi3+0x88>
f0104241:	85 c9                	test   %ecx,%ecx
f0104243:	75 0b                	jne    f0104250 <__udivdi3+0x40>
f0104245:	b8 01 00 00 00       	mov    $0x1,%eax
f010424a:	31 d2                	xor    %edx,%edx
f010424c:	f7 f1                	div    %ecx
f010424e:	89 c1                	mov    %eax,%ecx
f0104250:	89 f0                	mov    %esi,%eax
f0104252:	31 d2                	xor    %edx,%edx
f0104254:	f7 f1                	div    %ecx
f0104256:	89 c6                	mov    %eax,%esi
f0104258:	8b 44 24 04          	mov    0x4(%esp),%eax
f010425c:	f7 f1                	div    %ecx
f010425e:	89 f2                	mov    %esi,%edx
f0104260:	8b 74 24 10          	mov    0x10(%esp),%esi
f0104264:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0104268:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f010426c:	83 c4 1c             	add    $0x1c,%esp
f010426f:	c3                   	ret    
f0104270:	31 d2                	xor    %edx,%edx
f0104272:	31 c0                	xor    %eax,%eax
f0104274:	39 f7                	cmp    %esi,%edi
f0104276:	77 e8                	ja     f0104260 <__udivdi3+0x50>
f0104278:	0f bd cf             	bsr    %edi,%ecx
f010427b:	83 f1 1f             	xor    $0x1f,%ecx
f010427e:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0104282:	75 2c                	jne    f01042b0 <__udivdi3+0xa0>
f0104284:	3b 6c 24 08          	cmp    0x8(%esp),%ebp
f0104288:	76 04                	jbe    f010428e <__udivdi3+0x7e>
f010428a:	39 f7                	cmp    %esi,%edi
f010428c:	73 d2                	jae    f0104260 <__udivdi3+0x50>
f010428e:	31 d2                	xor    %edx,%edx
f0104290:	b8 01 00 00 00       	mov    $0x1,%eax
f0104295:	eb c9                	jmp    f0104260 <__udivdi3+0x50>
f0104297:	90                   	nop
f0104298:	89 f2                	mov    %esi,%edx
f010429a:	f7 f1                	div    %ecx
f010429c:	31 d2                	xor    %edx,%edx
f010429e:	8b 74 24 10          	mov    0x10(%esp),%esi
f01042a2:	8b 7c 24 14          	mov    0x14(%esp),%edi
f01042a6:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f01042aa:	83 c4 1c             	add    $0x1c,%esp
f01042ad:	c3                   	ret    
f01042ae:	66 90                	xchg   %ax,%ax
f01042b0:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f01042b5:	b8 20 00 00 00       	mov    $0x20,%eax
f01042ba:	89 ea                	mov    %ebp,%edx
f01042bc:	2b 44 24 04          	sub    0x4(%esp),%eax
f01042c0:	d3 e7                	shl    %cl,%edi
f01042c2:	89 c1                	mov    %eax,%ecx
f01042c4:	d3 ea                	shr    %cl,%edx
f01042c6:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f01042cb:	09 fa                	or     %edi,%edx
f01042cd:	89 f7                	mov    %esi,%edi
f01042cf:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01042d3:	89 f2                	mov    %esi,%edx
f01042d5:	8b 74 24 08          	mov    0x8(%esp),%esi
f01042d9:	d3 e5                	shl    %cl,%ebp
f01042db:	89 c1                	mov    %eax,%ecx
f01042dd:	d3 ef                	shr    %cl,%edi
f01042df:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f01042e4:	d3 e2                	shl    %cl,%edx
f01042e6:	89 c1                	mov    %eax,%ecx
f01042e8:	d3 ee                	shr    %cl,%esi
f01042ea:	09 d6                	or     %edx,%esi
f01042ec:	89 fa                	mov    %edi,%edx
f01042ee:	89 f0                	mov    %esi,%eax
f01042f0:	f7 74 24 0c          	divl   0xc(%esp)
f01042f4:	89 d7                	mov    %edx,%edi
f01042f6:	89 c6                	mov    %eax,%esi
f01042f8:	f7 e5                	mul    %ebp
f01042fa:	39 d7                	cmp    %edx,%edi
f01042fc:	72 22                	jb     f0104320 <__udivdi3+0x110>
f01042fe:	8b 6c 24 08          	mov    0x8(%esp),%ebp
f0104302:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0104307:	d3 e5                	shl    %cl,%ebp
f0104309:	39 c5                	cmp    %eax,%ebp
f010430b:	73 04                	jae    f0104311 <__udivdi3+0x101>
f010430d:	39 d7                	cmp    %edx,%edi
f010430f:	74 0f                	je     f0104320 <__udivdi3+0x110>
f0104311:	89 f0                	mov    %esi,%eax
f0104313:	31 d2                	xor    %edx,%edx
f0104315:	e9 46 ff ff ff       	jmp    f0104260 <__udivdi3+0x50>
f010431a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0104320:	8d 46 ff             	lea    -0x1(%esi),%eax
f0104323:	31 d2                	xor    %edx,%edx
f0104325:	8b 74 24 10          	mov    0x10(%esp),%esi
f0104329:	8b 7c 24 14          	mov    0x14(%esp),%edi
f010432d:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0104331:	83 c4 1c             	add    $0x1c,%esp
f0104334:	c3                   	ret    
	...

f0104340 <__umoddi3>:
f0104340:	83 ec 1c             	sub    $0x1c,%esp
f0104343:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f0104347:	8b 6c 24 2c          	mov    0x2c(%esp),%ebp
f010434b:	8b 44 24 20          	mov    0x20(%esp),%eax
f010434f:	89 74 24 10          	mov    %esi,0x10(%esp)
f0104353:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0104357:	8b 74 24 24          	mov    0x24(%esp),%esi
f010435b:	85 ed                	test   %ebp,%ebp
f010435d:	89 7c 24 14          	mov    %edi,0x14(%esp)
f0104361:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104365:	89 cf                	mov    %ecx,%edi
f0104367:	89 04 24             	mov    %eax,(%esp)
f010436a:	89 f2                	mov    %esi,%edx
f010436c:	75 1a                	jne    f0104388 <__umoddi3+0x48>
f010436e:	39 f1                	cmp    %esi,%ecx
f0104370:	76 4e                	jbe    f01043c0 <__umoddi3+0x80>
f0104372:	f7 f1                	div    %ecx
f0104374:	89 d0                	mov    %edx,%eax
f0104376:	31 d2                	xor    %edx,%edx
f0104378:	8b 74 24 10          	mov    0x10(%esp),%esi
f010437c:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0104380:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0104384:	83 c4 1c             	add    $0x1c,%esp
f0104387:	c3                   	ret    
f0104388:	39 f5                	cmp    %esi,%ebp
f010438a:	77 54                	ja     f01043e0 <__umoddi3+0xa0>
f010438c:	0f bd c5             	bsr    %ebp,%eax
f010438f:	83 f0 1f             	xor    $0x1f,%eax
f0104392:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104396:	75 60                	jne    f01043f8 <__umoddi3+0xb8>
f0104398:	3b 0c 24             	cmp    (%esp),%ecx
f010439b:	0f 87 07 01 00 00    	ja     f01044a8 <__umoddi3+0x168>
f01043a1:	89 f2                	mov    %esi,%edx
f01043a3:	8b 34 24             	mov    (%esp),%esi
f01043a6:	29 ce                	sub    %ecx,%esi
f01043a8:	19 ea                	sbb    %ebp,%edx
f01043aa:	89 34 24             	mov    %esi,(%esp)
f01043ad:	8b 04 24             	mov    (%esp),%eax
f01043b0:	8b 74 24 10          	mov    0x10(%esp),%esi
f01043b4:	8b 7c 24 14          	mov    0x14(%esp),%edi
f01043b8:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f01043bc:	83 c4 1c             	add    $0x1c,%esp
f01043bf:	c3                   	ret    
f01043c0:	85 c9                	test   %ecx,%ecx
f01043c2:	75 0b                	jne    f01043cf <__umoddi3+0x8f>
f01043c4:	b8 01 00 00 00       	mov    $0x1,%eax
f01043c9:	31 d2                	xor    %edx,%edx
f01043cb:	f7 f1                	div    %ecx
f01043cd:	89 c1                	mov    %eax,%ecx
f01043cf:	89 f0                	mov    %esi,%eax
f01043d1:	31 d2                	xor    %edx,%edx
f01043d3:	f7 f1                	div    %ecx
f01043d5:	8b 04 24             	mov    (%esp),%eax
f01043d8:	f7 f1                	div    %ecx
f01043da:	eb 98                	jmp    f0104374 <__umoddi3+0x34>
f01043dc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01043e0:	89 f2                	mov    %esi,%edx
f01043e2:	8b 74 24 10          	mov    0x10(%esp),%esi
f01043e6:	8b 7c 24 14          	mov    0x14(%esp),%edi
f01043ea:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f01043ee:	83 c4 1c             	add    $0x1c,%esp
f01043f1:	c3                   	ret    
f01043f2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01043f8:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f01043fd:	89 e8                	mov    %ebp,%eax
f01043ff:	bd 20 00 00 00       	mov    $0x20,%ebp
f0104404:	2b 6c 24 04          	sub    0x4(%esp),%ebp
f0104408:	89 fa                	mov    %edi,%edx
f010440a:	d3 e0                	shl    %cl,%eax
f010440c:	89 e9                	mov    %ebp,%ecx
f010440e:	d3 ea                	shr    %cl,%edx
f0104410:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0104415:	09 c2                	or     %eax,%edx
f0104417:	8b 44 24 08          	mov    0x8(%esp),%eax
f010441b:	89 14 24             	mov    %edx,(%esp)
f010441e:	89 f2                	mov    %esi,%edx
f0104420:	d3 e7                	shl    %cl,%edi
f0104422:	89 e9                	mov    %ebp,%ecx
f0104424:	d3 ea                	shr    %cl,%edx
f0104426:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f010442b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f010442f:	d3 e6                	shl    %cl,%esi
f0104431:	89 e9                	mov    %ebp,%ecx
f0104433:	d3 e8                	shr    %cl,%eax
f0104435:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f010443a:	09 f0                	or     %esi,%eax
f010443c:	8b 74 24 08          	mov    0x8(%esp),%esi
f0104440:	f7 34 24             	divl   (%esp)
f0104443:	d3 e6                	shl    %cl,%esi
f0104445:	89 74 24 08          	mov    %esi,0x8(%esp)
f0104449:	89 d6                	mov    %edx,%esi
f010444b:	f7 e7                	mul    %edi
f010444d:	39 d6                	cmp    %edx,%esi
f010444f:	89 c1                	mov    %eax,%ecx
f0104451:	89 d7                	mov    %edx,%edi
f0104453:	72 3f                	jb     f0104494 <__umoddi3+0x154>
f0104455:	39 44 24 08          	cmp    %eax,0x8(%esp)
f0104459:	72 35                	jb     f0104490 <__umoddi3+0x150>
f010445b:	8b 44 24 08          	mov    0x8(%esp),%eax
f010445f:	29 c8                	sub    %ecx,%eax
f0104461:	19 fe                	sbb    %edi,%esi
f0104463:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0104468:	89 f2                	mov    %esi,%edx
f010446a:	d3 e8                	shr    %cl,%eax
f010446c:	89 e9                	mov    %ebp,%ecx
f010446e:	d3 e2                	shl    %cl,%edx
f0104470:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0104475:	09 d0                	or     %edx,%eax
f0104477:	89 f2                	mov    %esi,%edx
f0104479:	d3 ea                	shr    %cl,%edx
f010447b:	8b 74 24 10          	mov    0x10(%esp),%esi
f010447f:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0104483:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0104487:	83 c4 1c             	add    $0x1c,%esp
f010448a:	c3                   	ret    
f010448b:	90                   	nop
f010448c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104490:	39 d6                	cmp    %edx,%esi
f0104492:	75 c7                	jne    f010445b <__umoddi3+0x11b>
f0104494:	89 d7                	mov    %edx,%edi
f0104496:	89 c1                	mov    %eax,%ecx
f0104498:	2b 4c 24 0c          	sub    0xc(%esp),%ecx
f010449c:	1b 3c 24             	sbb    (%esp),%edi
f010449f:	eb ba                	jmp    f010445b <__umoddi3+0x11b>
f01044a1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01044a8:	39 f5                	cmp    %esi,%ebp
f01044aa:	0f 82 f1 fe ff ff    	jb     f01043a1 <__umoddi3+0x61>
f01044b0:	e9 f8 fe ff ff       	jmp    f01043ad <__umoddi3+0x6d>
