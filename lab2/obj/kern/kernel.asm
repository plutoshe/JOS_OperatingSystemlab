
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
f0100063:	e8 d9 40 00 00       	call   f0104141 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100068:	e8 97 04 00 00       	call   f0100504 <cons_init>
	cprintf("6828 decimal is %o octal!\n", 6828);
f010006d:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f0100074:	00 
f0100075:	c7 04 24 40 46 10 f0 	movl   $0xf0104640,(%esp)
f010007c:	e8 05 35 00 00       	call   f0103586 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100081:	e8 2b 19 00 00       	call   f01019b1 <mem_init>
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
f01000c1:	c7 04 24 5b 46 10 f0 	movl   $0xf010465b,(%esp)
f01000c8:	e8 b9 34 00 00       	call   f0103586 <cprintf>
	vcprintf(fmt, ap);
f01000cd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01000d1:	89 34 24             	mov    %esi,(%esp)
f01000d4:	e8 7a 34 00 00       	call   f0103553 <vcprintf>
	cprintf("\n");
f01000d9:	c7 04 24 90 58 10 f0 	movl   $0xf0105890,(%esp)
f01000e0:	e8 a1 34 00 00       	call   f0103586 <cprintf>
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
f010010b:	c7 04 24 73 46 10 f0 	movl   $0xf0104673,(%esp)
f0100112:	e8 6f 34 00 00       	call   f0103586 <cprintf>
	vcprintf(fmt, ap);
f0100117:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010011b:	8b 45 10             	mov    0x10(%ebp),%eax
f010011e:	89 04 24             	mov    %eax,(%esp)
f0100121:	e8 2d 34 00 00       	call   f0103553 <vcprintf>
	cprintf("\n");
f0100126:	c7 04 24 90 58 10 f0 	movl   $0xf0105890,(%esp)
f010012d:	e8 54 34 00 00       	call   f0103586 <cprintf>
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
f010031b:	e8 7c 3e 00 00       	call   f010419c <memmove>
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
f01003c7:	0f b6 82 c0 46 10 f0 	movzbl -0xfefb940(%edx),%eax
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
f0100404:	0f b6 82 c0 46 10 f0 	movzbl -0xfefb940(%edx),%eax
f010040b:	0b 05 48 95 11 f0    	or     0xf0119548,%eax
	shift ^= togglecode[data];
f0100411:	0f b6 8a c0 47 10 f0 	movzbl -0xfefb840(%edx),%ecx
f0100418:	31 c8                	xor    %ecx,%eax
f010041a:	a3 48 95 11 f0       	mov    %eax,0xf0119548

	c = charcode[shift & (CTL | SHIFT)][data];
f010041f:	89 c1                	mov    %eax,%ecx
f0100421:	83 e1 03             	and    $0x3,%ecx
f0100424:	8b 0c 8d c0 48 10 f0 	mov    -0xfefb740(,%ecx,4),%ecx
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
f010045a:	c7 04 24 8d 46 10 f0 	movl   $0xf010468d,(%esp)
f0100461:	e8 20 31 00 00       	call   f0103586 <cprintf>
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
f01005e5:	c7 04 24 99 46 10 f0 	movl   $0xf0104699,(%esp)
f01005ec:	e8 95 2f 00 00       	call   f0103586 <cprintf>
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
f0100636:	c7 04 24 d0 48 10 f0 	movl   $0xf01048d0,(%esp)
f010063d:	e8 44 2f 00 00       	call   f0103586 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100642:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f0100649:	00 
f010064a:	c7 04 24 00 4b 10 f0 	movl   $0xf0104b00,(%esp)
f0100651:	e8 30 2f 00 00       	call   f0103586 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100656:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f010065d:	00 
f010065e:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f0100665:	f0 
f0100666:	c7 04 24 28 4b 10 f0 	movl   $0xf0104b28,(%esp)
f010066d:	e8 14 2f 00 00       	call   f0103586 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100672:	c7 44 24 08 35 46 10 	movl   $0x104635,0x8(%esp)
f0100679:	00 
f010067a:	c7 44 24 04 35 46 10 	movl   $0xf0104635,0x4(%esp)
f0100681:	f0 
f0100682:	c7 04 24 4c 4b 10 f0 	movl   $0xf0104b4c,(%esp)
f0100689:	e8 f8 2e 00 00       	call   f0103586 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010068e:	c7 44 24 08 20 93 11 	movl   $0x119320,0x8(%esp)
f0100695:	00 
f0100696:	c7 44 24 04 20 93 11 	movl   $0xf0119320,0x4(%esp)
f010069d:	f0 
f010069e:	c7 04 24 70 4b 10 f0 	movl   $0xf0104b70,(%esp)
f01006a5:	e8 dc 2e 00 00       	call   f0103586 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006aa:	c7 44 24 08 90 99 11 	movl   $0x119990,0x8(%esp)
f01006b1:	00 
f01006b2:	c7 44 24 04 90 99 11 	movl   $0xf0119990,0x4(%esp)
f01006b9:	f0 
f01006ba:	c7 04 24 94 4b 10 f0 	movl   $0xf0104b94,(%esp)
f01006c1:	e8 c0 2e 00 00       	call   f0103586 <cprintf>
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
f01006e7:	c7 04 24 b8 4b 10 f0 	movl   $0xf0104bb8,(%esp)
f01006ee:	e8 93 2e 00 00       	call   f0103586 <cprintf>
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
f0100706:	8b 83 a4 4e 10 f0    	mov    -0xfefb15c(%ebx),%eax
f010070c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100710:	8b 83 a0 4e 10 f0    	mov    -0xfefb160(%ebx),%eax
f0100716:	89 44 24 04          	mov    %eax,0x4(%esp)
f010071a:	c7 04 24 e9 48 10 f0 	movl   $0xf01048e9,(%esp)
f0100721:	e8 60 2e 00 00       	call   f0103586 <cprintf>
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
f0100749:	c7 04 24 f2 48 10 f0 	movl   $0xf01048f2,(%esp)
f0100750:	e8 31 2e 00 00       	call   f0103586 <cprintf>
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
f0100788:	c7 04 24 e4 4b 10 f0 	movl   $0xf0104be4,(%esp)
f010078f:	e8 f2 2d 00 00       	call   f0103586 <cprintf>
		struct Eipdebuginfo temp_debuginfo;
		debuginfo_eip((uintptr_t) eip, &temp_debuginfo);		
f0100794:	8d 45 d0             	lea    -0x30(%ebp),%eax
f0100797:	89 44 24 04          	mov    %eax,0x4(%esp)
f010079b:	89 3c 24             	mov    %edi,(%esp)
f010079e:	e8 dd 2e 00 00       	call   f0103680 <debuginfo_eip>
		cprintf("       %s:%d: ", temp_debuginfo.eip_file, temp_debuginfo.eip_line);
f01007a3:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01007a6:	89 44 24 08          	mov    %eax,0x8(%esp)
f01007aa:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01007ad:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007b1:	c7 04 24 03 49 10 f0 	movl   $0xf0104903,(%esp)
f01007b8:	e8 c9 2d 00 00       	call   f0103586 <cprintf>
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
f01007d3:	c7 04 24 12 49 10 f0 	movl   $0xf0104912,(%esp)
f01007da:	e8 a7 2d 00 00       	call   f0103586 <cprintf>
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
f01007ee:	c7 04 24 15 49 10 f0 	movl   $0xf0104915,(%esp)
f01007f5:	e8 8c 2d 00 00       	call   f0103586 <cprintf>
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
f0100826:	c7 44 24 04 1a 49 10 	movl   $0xf010491a,0x4(%esp)
f010082d:	f0 
f010082e:	8b 46 08             	mov    0x8(%esi),%eax
f0100831:	89 04 24             	mov    %eax,(%esp)
f0100834:	e8 32 38 00 00       	call   f010406b <strcmp>
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
f0100846:	c7 44 24 04 1e 49 10 	movl   $0xf010491e,0x4(%esp)
f010084d:	f0 
f010084e:	8b 46 08             	mov    0x8(%esi),%eax
f0100851:	89 04 24             	mov    %eax,(%esp)
f0100854:	e8 12 38 00 00       	call   f010406b <strcmp>
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
f0100866:	c7 44 24 04 22 49 10 	movl   $0xf0104922,0x4(%esp)
f010086d:	f0 
f010086e:	8b 46 08             	mov    0x8(%esi),%eax
f0100871:	89 04 24             	mov    %eax,(%esp)
f0100874:	e8 f2 37 00 00       	call   f010406b <strcmp>
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
f0100886:	c7 44 24 04 26 49 10 	movl   $0xf0104926,0x4(%esp)
f010088d:	f0 
f010088e:	8b 46 08             	mov    0x8(%esi),%eax
f0100891:	89 04 24             	mov    %eax,(%esp)
f0100894:	e8 d2 37 00 00       	call   f010406b <strcmp>
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
f01008a6:	c7 44 24 04 2a 49 10 	movl   $0xf010492a,0x4(%esp)
f01008ad:	f0 
f01008ae:	8b 46 08             	mov    0x8(%esi),%eax
f01008b1:	89 04 24             	mov    %eax,(%esp)
f01008b4:	e8 b2 37 00 00       	call   f010406b <strcmp>
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
f01008c6:	c7 44 24 04 2e 49 10 	movl   $0xf010492e,0x4(%esp)
f01008cd:	f0 
f01008ce:	8b 46 08             	mov    0x8(%esi),%eax
f01008d1:	89 04 24             	mov    %eax,(%esp)
f01008d4:	e8 92 37 00 00       	call   f010406b <strcmp>
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
f01008e2:	c7 44 24 04 32 49 10 	movl   $0xf0104932,0x4(%esp)
f01008e9:	f0 
f01008ea:	8b 46 08             	mov    0x8(%esi),%eax
f01008ed:	89 04 24             	mov    %eax,(%esp)
f01008f0:	e8 76 37 00 00       	call   f010406b <strcmp>
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
f01008fe:	c7 44 24 04 36 49 10 	movl   $0xf0104936,0x4(%esp)
f0100905:	f0 
f0100906:	8b 46 08             	mov    0x8(%esi),%eax
f0100909:	89 04 24             	mov    %eax,(%esp)
f010090c:	e8 5a 37 00 00       	call   f010406b <strcmp>
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
f010091a:	c7 44 24 04 3a 49 10 	movl   $0xf010493a,0x4(%esp)
f0100921:	f0 
f0100922:	8b 46 08             	mov    0x8(%esi),%eax
f0100925:	89 04 24             	mov    %eax,(%esp)
f0100928:	e8 3e 37 00 00       	call   f010406b <strcmp>
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
f0100936:	c7 44 24 04 3e 49 10 	movl   $0xf010493e,0x4(%esp)
f010093d:	f0 
f010093e:	8b 46 08             	mov    0x8(%esi),%eax
f0100941:	89 04 24             	mov    %eax,(%esp)
f0100944:	e8 22 37 00 00       	call   f010406b <strcmp>
			ch_color1=COLOR_CYN
f0100949:	83 f8 01             	cmp    $0x1,%eax
f010094c:	19 ff                	sbb    %edi,%edi
f010094e:	83 e7 04             	and    $0x4,%edi
f0100951:	83 c7 07             	add    $0x7,%edi
	else ch_color1=COLOR_WHT;
	if(strcmp(argv[1],"blk")==0)
f0100954:	c7 44 24 04 1a 49 10 	movl   $0xf010491a,0x4(%esp)
f010095b:	f0 
f010095c:	8b 46 04             	mov    0x4(%esi),%eax
f010095f:	89 04 24             	mov    %eax,(%esp)
f0100962:	e8 04 37 00 00       	call   f010406b <strcmp>
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
f0100974:	c7 44 24 04 1e 49 10 	movl   $0xf010491e,0x4(%esp)
f010097b:	f0 
f010097c:	8b 46 04             	mov    0x4(%esi),%eax
f010097f:	89 04 24             	mov    %eax,(%esp)
f0100982:	e8 e4 36 00 00       	call   f010406b <strcmp>
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
f0100991:	c7 44 24 04 22 49 10 	movl   $0xf0104922,0x4(%esp)
f0100998:	f0 
f0100999:	8b 46 04             	mov    0x4(%esi),%eax
f010099c:	89 04 24             	mov    %eax,(%esp)
f010099f:	e8 c7 36 00 00       	call   f010406b <strcmp>
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
f01009ae:	c7 44 24 04 26 49 10 	movl   $0xf0104926,0x4(%esp)
f01009b5:	f0 
f01009b6:	8b 46 04             	mov    0x4(%esi),%eax
f01009b9:	89 04 24             	mov    %eax,(%esp)
f01009bc:	e8 aa 36 00 00       	call   f010406b <strcmp>
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
f01009cb:	c7 44 24 04 2a 49 10 	movl   $0xf010492a,0x4(%esp)
f01009d2:	f0 
f01009d3:	8b 46 04             	mov    0x4(%esi),%eax
f01009d6:	89 04 24             	mov    %eax,(%esp)
f01009d9:	e8 8d 36 00 00       	call   f010406b <strcmp>
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
f01009e8:	c7 44 24 04 2e 49 10 	movl   $0xf010492e,0x4(%esp)
f01009ef:	f0 
f01009f0:	8b 46 04             	mov    0x4(%esi),%eax
f01009f3:	89 04 24             	mov    %eax,(%esp)
f01009f6:	e8 70 36 00 00       	call   f010406b <strcmp>
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
f0100a01:	c7 44 24 04 32 49 10 	movl   $0xf0104932,0x4(%esp)
f0100a08:	f0 
f0100a09:	8b 46 04             	mov    0x4(%esi),%eax
f0100a0c:	89 04 24             	mov    %eax,(%esp)
f0100a0f:	e8 57 36 00 00       	call   f010406b <strcmp>
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
f0100a1a:	c7 44 24 04 36 49 10 	movl   $0xf0104936,0x4(%esp)
f0100a21:	f0 
f0100a22:	8b 46 04             	mov    0x4(%esi),%eax
f0100a25:	89 04 24             	mov    %eax,(%esp)
f0100a28:	e8 3e 36 00 00       	call   f010406b <strcmp>
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
f0100a33:	c7 44 24 04 3a 49 10 	movl   $0xf010493a,0x4(%esp)
f0100a3a:	f0 
f0100a3b:	8b 46 04             	mov    0x4(%esi),%eax
f0100a3e:	89 04 24             	mov    %eax,(%esp)
f0100a41:	e8 25 36 00 00       	call   f010406b <strcmp>
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
f0100a4c:	c7 44 24 04 3e 49 10 	movl   $0xf010493e,0x4(%esp)
f0100a53:	f0 
f0100a54:	8b 46 04             	mov    0x4(%esi),%eax
f0100a57:	89 04 24             	mov    %eax,(%esp)
f0100a5a:	e8 0c 36 00 00       	call   f010406b <strcmp>
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
f0100a84:	c7 04 24 18 4c 10 f0 	movl   $0xf0104c18,(%esp)
f0100a8b:	e8 f6 2a 00 00       	call   f0103586 <cprintf>
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
f0100ab9:	c7 04 24 42 49 10 f0 	movl   $0xf0104942,(%esp)
f0100ac0:	e8 c1 2a 00 00       	call   f0103586 <cprintf>
	cprintf("PTE_W : %d ", ((now & PTE_W) != 0));
f0100ac5:	f6 c3 02             	test   $0x2,%bl
f0100ac8:	0f 95 c0             	setne  %al
f0100acb:	0f b6 c0             	movzbl %al,%eax
f0100ace:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100ad2:	c7 04 24 4e 49 10 f0 	movl   $0xf010494e,(%esp)
f0100ad9:	e8 a8 2a 00 00       	call   f0103586 <cprintf>
	cprintf("PTE_P : %d ", ((now & PTE_P) != 0));
f0100ade:	83 e3 01             	and    $0x1,%ebx
f0100ae1:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100ae5:	c7 04 24 5a 49 10 f0 	movl   $0xf010495a,(%esp)
f0100aec:	e8 95 2a 00 00       	call   f0103586 <cprintf>
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
f0100b0f:	e8 4c 34 00 00       	call   f0103f60 <strlen>
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
f0100bd3:	c7 04 24 66 49 10 f0 	movl   $0xf0104966,(%esp)
f0100bda:	e8 a7 29 00 00       	call   f0103586 <cprintf>
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
f0100c66:	e8 49 0a 00 00       	call   f01016b4 <pgdir_walk>
f0100c6b:	89 c3                	mov    %eax,%ebx
		cprintf("VA 0x%08x : ", begin);
f0100c6d:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100c70:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100c74:	c7 04 24 7c 49 10 f0 	movl   $0xf010497c,(%esp)
f0100c7b:	e8 06 29 00 00       	call   f0103586 <cprintf>
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
f0100c93:	c7 04 24 89 49 10 f0 	movl   $0xf0104989,(%esp)
f0100c9a:	e8 e7 28 00 00       	call   f0103586 <cprintf>
				printPermission((pte_t)*mapper);
f0100c9f:	8b 03                	mov    (%ebx),%eax
f0100ca1:	89 04 24             	mov    %eax,(%esp)
f0100ca4:	e8 f9 fd ff ff       	call   f0100aa2 <printPermission>
				cprintf("\n");
f0100ca9:	c7 04 24 90 58 10 f0 	movl   $0xf0105890,(%esp)
f0100cb0:	e8 d1 28 00 00       	call   f0103586 <cprintf>
f0100cb5:	eb 2a                	jmp    f0100ce1 <mon_showmapping+0xfb>
			} else {
				cprintf("page not mapping\n");
f0100cb7:	c7 04 24 99 49 10 f0 	movl   $0xf0104999,(%esp)
f0100cbe:	e8 c3 28 00 00       	call   f0103586 <cprintf>
f0100cc3:	eb 1c                	jmp    f0100ce1 <mon_showmapping+0xfb>
			}
		} else {
			panic("error, out of memory");
f0100cc5:	c7 44 24 08 ab 49 10 	movl   $0xf01049ab,0x8(%esp)
f0100ccc:	f0 
f0100ccd:	c7 44 24 04 e9 00 00 	movl   $0xe9,0x4(%esp)
f0100cd4:	00 
f0100cd5:	c7 04 24 c0 49 10 f0 	movl   $0xf01049c0,(%esp)
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
#define POINT_SIZE 4
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
f0100d10:	c7 04 24 cf 49 10 f0 	movl   $0xf01049cf,(%esp)
f0100d17:	e8 6a 28 00 00       	call   f0103586 <cprintf>
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
f0100d8b:	c7 04 24 e0 49 10 f0 	movl   $0xf01049e0,(%esp)
f0100d92:	e8 ef 27 00 00       	call   f0103586 <cprintf>
			return 0;	
f0100d97:	e9 98 00 00 00       	jmp    f0100e34 <mon_dump+0x134>
f0100d9c:	89 c2                	mov    %eax,%edx
f0100d9e:	c1 ea 0c             	shr    $0xc,%edx
f0100da1:	3b 15 84 99 11 f0    	cmp    0xf0119984,%edx
f0100da7:	72 20                	jb     f0100dc9 <mon_dump+0xc9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100da9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100dad:	c7 44 24 08 4c 4c 10 	movl   $0xf0104c4c,0x8(%esp)
f0100db4:	f0 
f0100db5:	c7 44 24 04 cc 00 00 	movl   $0xcc,0x4(%esp)
f0100dbc:	00 
f0100dbd:	c7 04 24 c0 49 10 f0 	movl   $0xf01049c0,(%esp)
f0100dc4:	e8 cb f2 ff ff       	call   f0100094 <_panic>
		}
		for (;begin <= end; begin += POINT_SIZE)
			cprintf("pa 0x%08x : 0x%08x\n", begin, *((uint32_t*)KADDR(begin)));
f0100dc9:	8b 90 00 00 00 f0    	mov    -0x10000000(%eax),%edx
f0100dcf:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100dd3:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100dd7:	c7 04 24 ef 49 10 f0 	movl   $0xf01049ef,(%esp)
f0100dde:	e8 a3 27 00 00       	call   f0103586 <cprintf>
	if (argv[1][0] == 'p') {
		if (PGNUM(end) >= npages || PGNUM(end) >= npages){
			cprintf("out of memory\n");
			return 0;	
		}
		for (;begin <= end; begin += POINT_SIZE)
f0100de3:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100de6:	83 c0 04             	add    $0x4,%eax
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
f0100e0c:	c7 04 24 03 4a 10 f0 	movl   $0xf0104a03,(%esp)
f0100e13:	e8 6e 27 00 00       	call   f0103586 <cprintf>
			return 0;	
		}
		for (;begin <= end; begin += POINT_SIZE)
			cprintf("pa 0x%08x : 0x%08x\n", begin, *((uint32_t*)KADDR(begin)));
	} else if (argv[1][0] == 'v') {
		for (;begin <= end; begin+=POINT_SIZE) {
f0100e18:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100e1b:	83 c0 04             	add    $0x4,%eax
f0100e1e:	89 45 f4             	mov    %eax,-0xc(%ebp)
f0100e21:	39 45 f0             	cmp    %eax,-0x10(%ebp)
f0100e24:	73 dc                	jae    f0100e02 <mon_dump+0x102>
f0100e26:	eb 0c                	jmp    f0100e34 <mon_dump+0x134>
			cprintf("Va 0x%08x : 0x%08x\n", begin, *((uint32_t*)begin));
		}
	} else cprintf("invalid command\n");
f0100e28:	c7 04 24 cf 49 10 f0 	movl   $0xf01049cf,(%esp)
f0100e2f:	e8 52 27 00 00       	call   f0103586 <cprintf>
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
f0100e7a:	e8 35 08 00 00       	call   f01016b4 <pgdir_walk>
	cprintf("Page Table Entry Address : 0x%08x\n", mapper); 
f0100e7f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100e83:	c7 04 24 70 4c 10 f0 	movl   $0xf0104c70,(%esp)
f0100e8a:	e8 f7 26 00 00       	call   f0103586 <cprintf>
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
f0100eb0:	c7 04 24 17 4a 10 f0 	movl   $0xf0104a17,(%esp)
f0100eb7:	e8 ca 26 00 00       	call   f0103586 <cprintf>
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
f0100ef2:	e8 bd 07 00 00       	call   f01016b4 <pgdir_walk>
f0100ef7:	89 c6                	mov    %eax,%esi
	if (!mapper) 
f0100ef9:	85 c0                	test   %eax,%eax
f0100efb:	75 1c                	jne    f0100f19 <mon_changePermission+0x83>
		panic("error, out of memory");
f0100efd:	c7 44 24 08 ab 49 10 	movl   $0xf01049ab,0x8(%esp)
f0100f04:	f0 
f0100f05:	c7 44 24 04 9f 00 00 	movl   $0x9f,0x4(%esp)
f0100f0c:	00 
f0100f0d:	c7 04 24 c0 49 10 f0 	movl   $0xf01049c0,(%esp)
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
f0100f23:	c7 04 24 17 4a 10 f0 	movl   $0xf0104a17,(%esp)
f0100f2a:	e8 57 26 00 00       	call   f0103586 <cprintf>
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
f0100f68:	c7 04 24 35 4a 10 f0 	movl   $0xf0104a35,(%esp)
f0100f6f:	e8 12 26 00 00       	call   f0103586 <cprintf>
f0100f74:	8b 06                	mov    (%esi),%eax
f0100f76:	89 04 24             	mov    %eax,(%esp)
f0100f79:	e8 24 fb ff ff       	call   f0100aa2 <printPermission>
f0100f7e:	c7 04 24 90 58 10 f0 	movl   $0xf0105890,(%esp)
f0100f85:	e8 fc 25 00 00       	call   f0103586 <cprintf>
	
	*mapper = PTE_ADDR(*mapper) | perm;
f0100f8a:	8b 06                	mov    (%esi),%eax
f0100f8c:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100f91:	09 c7                	or     %eax,%edi
f0100f93:	89 3e                	mov    %edi,(%esi)
	cprintf("after change ");  printPermission(*mapper); cprintf("\n");
f0100f95:	c7 04 24 44 4a 10 f0 	movl   $0xf0104a44,(%esp)
f0100f9c:	e8 e5 25 00 00       	call   f0103586 <cprintf>
f0100fa1:	8b 06                	mov    (%esi),%eax
f0100fa3:	89 04 24             	mov    %eax,(%esp)
f0100fa6:	e8 f7 fa ff ff       	call   f0100aa2 <printPermission>
f0100fab:	c7 04 24 90 58 10 f0 	movl   $0xf0105890,(%esp)
f0100fb2:	e8 cf 25 00 00       	call   f0103586 <cprintf>
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
f0100fd2:	c7 04 24 94 4c 10 f0 	movl   $0xf0104c94,(%esp)
f0100fd9:	e8 a8 25 00 00       	call   f0103586 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100fde:	c7 04 24 b8 4c 10 f0 	movl   $0xf0104cb8,(%esp)
f0100fe5:	e8 9c 25 00 00       	call   f0103586 <cprintf>
  //	cprintf("x %d, y %x, z %d\n", x, y, z);
//	unsigned int i = 0x00646c72;
//	cprintf("H%x Wo%s", 57616, &i);

	while (1) {
		buf = readline("K> ");
f0100fea:	c7 04 24 52 4a 10 f0 	movl   $0xf0104a52,(%esp)
f0100ff1:	e8 9a 2e 00 00       	call   f0103e90 <readline>
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
f010101e:	c7 04 24 56 4a 10 f0 	movl   $0xf0104a56,(%esp)
f0101025:	e8 bc 30 00 00       	call   f01040e6 <strchr>
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
f0101040:	c7 04 24 5b 4a 10 f0 	movl   $0xf0104a5b,(%esp)
f0101047:	e8 3a 25 00 00       	call   f0103586 <cprintf>
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
f010106f:	c7 04 24 56 4a 10 f0 	movl   $0xf0104a56,(%esp)
f0101076:	e8 6b 30 00 00       	call   f01040e6 <strchr>
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
f0101091:	bb a0 4e 10 f0       	mov    $0xf0104ea0,%ebx
f0101096:	bf 00 00 00 00       	mov    $0x0,%edi
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f010109b:	8b 03                	mov    (%ebx),%eax
f010109d:	89 44 24 04          	mov    %eax,0x4(%esp)
f01010a1:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01010a4:	89 04 24             	mov    %eax,(%esp)
f01010a7:	e8 bf 2f 00 00       	call   f010406b <strcmp>
f01010ac:	85 c0                	test   %eax,%eax
f01010ae:	75 24                	jne    f01010d4 <monitor+0x10b>
			return commands[i].func(argc, argv, tf);
f01010b0:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f01010b3:	8b 55 08             	mov    0x8(%ebp),%edx
f01010b6:	89 54 24 08          	mov    %edx,0x8(%esp)
f01010ba:	8d 55 a8             	lea    -0x58(%ebp),%edx
f01010bd:	89 54 24 04          	mov    %edx,0x4(%esp)
f01010c1:	89 34 24             	mov    %esi,(%esp)
f01010c4:	ff 14 85 a8 4e 10 f0 	call   *-0xfefb158(,%eax,4)
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
f01010e6:	c7 04 24 78 4a 10 f0 	movl   $0xf0104a78,(%esp)
f01010ed:	e8 94 24 00 00       	call   f0103586 <cprintf>
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
f010116b:	c7 44 24 08 4c 4c 10 	movl   $0xf0104c4c,0x8(%esp)
f0101172:	f0 
f0101173:	c7 44 24 04 d9 02 00 	movl   $0x2d9,0x4(%esp)
f010117a:	00 
f010117b:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
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
f01011be:	e8 55 23 00 00       	call   f0103518 <mc146818_read>
f01011c3:	89 c6                	mov    %eax,%esi
f01011c5:	83 c3 01             	add    $0x1,%ebx
f01011c8:	89 1c 24             	mov    %ebx,(%esp)
f01011cb:	e8 48 23 00 00       	call   f0103518 <mc146818_read>
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
f01011ff:	c7 44 24 08 00 4f 10 	movl   $0xf0104f00,0x8(%esp)
f0101206:	f0 
f0101207:	c7 44 24 04 19 02 00 	movl   $0x219,0x4(%esp)
f010120e:	00 
f010120f:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
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
f0101297:	c7 44 24 08 4c 4c 10 	movl   $0xf0104c4c,0x8(%esp)
f010129e:	f0 
f010129f:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f01012a6:	00 
f01012a7:	c7 04 24 04 56 10 f0 	movl   $0xf0105604,(%esp)
f01012ae:	e8 e1 ed ff ff       	call   f0100094 <_panic>
			memset(page2kva(pp), 0x97, 128);
f01012b3:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
f01012ba:	00 
f01012bb:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
f01012c2:	00 
	return (void *)(pa + KERNBASE);
f01012c3:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01012c8:	89 04 24             	mov    %eax,(%esp)
f01012cb:	e8 71 2e 00 00       	call   f0104141 <memset>
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
f0101348:	c7 44 24 0c 12 56 10 	movl   $0xf0105612,0xc(%esp)
f010134f:	f0 
f0101350:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f0101357:	f0 
f0101358:	c7 44 24 04 33 02 00 	movl   $0x233,0x4(%esp)
f010135f:	00 
f0101360:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f0101367:	e8 28 ed ff ff       	call   f0100094 <_panic>
		assert(pp < pages + npages);
f010136c:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f010136f:	72 24                	jb     f0101395 <check_page_free_list+0x1b6>
f0101371:	c7 44 24 0c 33 56 10 	movl   $0xf0105633,0xc(%esp)
f0101378:	f0 
f0101379:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f0101380:	f0 
f0101381:	c7 44 24 04 34 02 00 	movl   $0x234,0x4(%esp)
f0101388:	00 
f0101389:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f0101390:	e8 ff ec ff ff       	call   f0100094 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0101395:	89 d0                	mov    %edx,%eax
f0101397:	2b 45 d0             	sub    -0x30(%ebp),%eax
f010139a:	a8 07                	test   $0x7,%al
f010139c:	74 24                	je     f01013c2 <check_page_free_list+0x1e3>
f010139e:	c7 44 24 0c 24 4f 10 	movl   $0xf0104f24,0xc(%esp)
f01013a5:	f0 
f01013a6:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f01013ad:	f0 
f01013ae:	c7 44 24 04 35 02 00 	movl   $0x235,0x4(%esp)
f01013b5:	00 
f01013b6:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f01013bd:	e8 d2 ec ff ff       	call   f0100094 <_panic>
f01013c2:	c1 f8 03             	sar    $0x3,%eax
f01013c5:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f01013c8:	85 c0                	test   %eax,%eax
f01013ca:	75 24                	jne    f01013f0 <check_page_free_list+0x211>
f01013cc:	c7 44 24 0c 47 56 10 	movl   $0xf0105647,0xc(%esp)
f01013d3:	f0 
f01013d4:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f01013db:	f0 
f01013dc:	c7 44 24 04 38 02 00 	movl   $0x238,0x4(%esp)
f01013e3:	00 
f01013e4:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f01013eb:	e8 a4 ec ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f01013f0:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f01013f5:	75 24                	jne    f010141b <check_page_free_list+0x23c>
f01013f7:	c7 44 24 0c 58 56 10 	movl   $0xf0105658,0xc(%esp)
f01013fe:	f0 
f01013ff:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f0101406:	f0 
f0101407:	c7 44 24 04 39 02 00 	movl   $0x239,0x4(%esp)
f010140e:	00 
f010140f:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f0101416:	e8 79 ec ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f010141b:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0101420:	75 24                	jne    f0101446 <check_page_free_list+0x267>
f0101422:	c7 44 24 0c 58 4f 10 	movl   $0xf0104f58,0xc(%esp)
f0101429:	f0 
f010142a:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f0101431:	f0 
f0101432:	c7 44 24 04 3a 02 00 	movl   $0x23a,0x4(%esp)
f0101439:	00 
f010143a:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f0101441:	e8 4e ec ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0101446:	3d 00 00 10 00       	cmp    $0x100000,%eax
f010144b:	75 24                	jne    f0101471 <check_page_free_list+0x292>
f010144d:	c7 44 24 0c 71 56 10 	movl   $0xf0105671,0xc(%esp)
f0101454:	f0 
f0101455:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f010145c:	f0 
f010145d:	c7 44 24 04 3b 02 00 	movl   $0x23b,0x4(%esp)
f0101464:	00 
f0101465:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
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
f0101486:	c7 44 24 08 4c 4c 10 	movl   $0xf0104c4c,0x8(%esp)
f010148d:	f0 
f010148e:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0101495:	00 
f0101496:	c7 04 24 04 56 10 f0 	movl   $0xf0105604,(%esp)
f010149d:	e8 f2 eb ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f01014a2:	81 e9 00 00 00 10    	sub    $0x10000000,%ecx
f01014a8:	39 4d c8             	cmp    %ecx,-0x38(%ebp)
f01014ab:	76 29                	jbe    f01014d6 <check_page_free_list+0x2f7>
f01014ad:	c7 44 24 0c 7c 4f 10 	movl   $0xf0104f7c,0xc(%esp)
f01014b4:	f0 
f01014b5:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f01014bc:	f0 
f01014bd:	c7 44 24 04 3c 02 00 	movl   $0x23c,0x4(%esp)
f01014c4:	00 
f01014c5:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
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
f01014e7:	c7 44 24 0c 8b 56 10 	movl   $0xf010568b,0xc(%esp)
f01014ee:	f0 
f01014ef:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f01014f6:	f0 
f01014f7:	c7 44 24 04 44 02 00 	movl   $0x244,0x4(%esp)
f01014fe:	00 
f01014ff:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f0101506:	e8 89 eb ff ff       	call   f0100094 <_panic>
	assert(nfree_extmem > 0);
f010150b:	85 f6                	test   %esi,%esi
f010150d:	7f 24                	jg     f0101533 <check_page_free_list+0x354>
f010150f:	c7 44 24 0c 9d 56 10 	movl   $0xf010569d,0xc(%esp)
f0101516:	f0 
f0101517:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f010151e:	f0 
f010151f:	c7 44 24 04 45 02 00 	movl   $0x245,0x4(%esp)
f0101526:	00 
f0101527:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
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
f0101558:	c7 44 24 08 c4 4f 10 	movl   $0xf0104fc4,0x8(%esp)
f010155f:	f0 
f0101560:	c7 44 24 04 05 01 00 	movl   $0x105,0x4(%esp)
f0101567:	00 
f0101568:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f010156f:	e8 20 eb ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0101574:	8d 98 00 00 00 10    	lea    0x10000000(%eax),%ebx
f010157a:	c1 eb 0c             	shr    $0xc,%ebx
//	cprintf("!!%d %d %d\n", npages, low, top);
//	cprintf("00");
	page_free_list = NULL;
f010157d:	c7 05 60 95 11 f0 00 	movl   $0x0,0xf0119560
f0101584:	00 00 00 
	for (i = 0; i < npages; i++) {
f0101587:	83 3d 84 99 11 f0 00 	cmpl   $0x0,0xf0119984
f010158e:	74 64                	je     f01015f4 <page_init+0xb9>
f0101590:	b8 00 00 00 00       	mov    $0x0,%eax
f0101595:	ba 00 00 00 00       	mov    $0x0,%edx
		if (i == 0 || (i >= low && i < top)){
f010159a:	85 d2                	test   %edx,%edx
f010159c:	74 0c                	je     f01015aa <page_init+0x6f>
f010159e:	81 fa 9f 00 00 00    	cmp    $0x9f,%edx
f01015a4:	76 1f                	jbe    f01015c5 <page_init+0x8a>
f01015a6:	39 da                	cmp    %ebx,%edx
f01015a8:	73 1b                	jae    f01015c5 <page_init+0x8a>
			pages[i].pp_ref = 1;
f01015aa:	8d 0c d5 00 00 00 00 	lea    0x0(,%edx,8),%ecx
f01015b1:	03 0d 8c 99 11 f0    	add    0xf011998c,%ecx
f01015b7:	66 c7 41 04 01 00    	movw   $0x1,0x4(%ecx)
			pages[i].pp_link = NULL;
f01015bd:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
			continue;
f01015c3:	eb 1f                	jmp    f01015e4 <page_init+0xa9>
		}
		pages[i].pp_ref = 0;
f01015c5:	8d 0c d5 00 00 00 00 	lea    0x0(,%edx,8),%ecx
f01015cc:	8b 35 8c 99 11 f0    	mov    0xf011998c,%esi
f01015d2:	66 c7 44 0e 04 00 00 	movw   $0x0,0x4(%esi,%ecx,1)
	//	cprintf("%d\n", i);
		pages[i].pp_link = page_free_list;
f01015d9:	89 04 d6             	mov    %eax,(%esi,%edx,8)
		page_free_list = &pages[i];
f01015dc:	89 c8                	mov    %ecx,%eax
f01015de:	03 05 8c 99 11 f0    	add    0xf011998c,%eax
	size_t low = IOPHYSMEM / PGSIZE;	
	size_t top = (PADDR(boot_alloc(0))) / PGSIZE;
//	cprintf("!!%d %d %d\n", npages, low, top);
//	cprintf("00");
	page_free_list = NULL;
	for (i = 0; i < npages; i++) {
f01015e4:	83 c2 01             	add    $0x1,%edx
f01015e7:	39 15 84 99 11 f0    	cmp    %edx,0xf0119984
f01015ed:	77 ab                	ja     f010159a <page_init+0x5f>
f01015ef:	a3 60 95 11 f0       	mov    %eax,0xf0119560
		pages[i].pp_ref = 0;
	//	cprintf("%d\n", i);
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
}
f01015f4:	83 c4 10             	add    $0x10,%esp
f01015f7:	5b                   	pop    %ebx
f01015f8:	5e                   	pop    %esi
f01015f9:	5d                   	pop    %ebp
f01015fa:	c3                   	ret    

f01015fb <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f01015fb:	55                   	push   %ebp
f01015fc:	89 e5                	mov    %esp,%ebp
f01015fe:	83 ec 18             	sub    $0x18,%esp
	// Fill this function in
	if (page_free_list != NULL) {
f0101601:	a1 60 95 11 f0       	mov    0xf0119560,%eax
f0101606:	85 c0                	test   %eax,%eax
f0101608:	74 6b                	je     f0101675 <page_alloc+0x7a>
		if (alloc_flags & ALLOC_ZERO) {
f010160a:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f010160e:	74 56                	je     f0101666 <page_alloc+0x6b>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101610:	2b 05 8c 99 11 f0    	sub    0xf011998c,%eax
f0101616:	c1 f8 03             	sar    $0x3,%eax
f0101619:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010161c:	89 c2                	mov    %eax,%edx
f010161e:	c1 ea 0c             	shr    $0xc,%edx
f0101621:	3b 15 84 99 11 f0    	cmp    0xf0119984,%edx
f0101627:	72 20                	jb     f0101649 <page_alloc+0x4e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101629:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010162d:	c7 44 24 08 4c 4c 10 	movl   $0xf0104c4c,0x8(%esp)
f0101634:	f0 
f0101635:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f010163c:	00 
f010163d:	c7 04 24 04 56 10 f0 	movl   $0xf0105604,(%esp)
f0101644:	e8 4b ea ff ff       	call   f0100094 <_panic>
//			cprintf("\n````!!!");
			memset(page2kva(page_free_list), 0, PGSIZE);
f0101649:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101650:	00 
f0101651:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101658:	00 
	return (void *)(pa + KERNBASE);
f0101659:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010165e:	89 04 24             	mov    %eax,(%esp)
f0101661:	e8 db 2a 00 00       	call   f0104141 <memset>
		}
		struct PageInfo* temp = page_free_list;
f0101666:	a1 60 95 11 f0       	mov    0xf0119560,%eax
		page_free_list = page_free_list->pp_link;
f010166b:	8b 10                	mov    (%eax),%edx
f010166d:	89 15 60 95 11 f0    	mov    %edx,0xf0119560
//		return (struct PageInfo*) page_free_list;
		return temp;
f0101673:	eb 05                	jmp    f010167a <page_alloc+0x7f>
	}
	return NULL;
f0101675:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010167a:	c9                   	leave  
f010167b:	c3                   	ret    

f010167c <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f010167c:	55                   	push   %ebp
f010167d:	89 e5                	mov    %esp,%ebp
f010167f:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	pp->pp_link = page_free_list;
f0101682:	8b 15 60 95 11 f0    	mov    0xf0119560,%edx
f0101688:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f010168a:	a3 60 95 11 f0       	mov    %eax,0xf0119560
}
f010168f:	5d                   	pop    %ebp
f0101690:	c3                   	ret    

f0101691 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0101691:	55                   	push   %ebp
f0101692:	89 e5                	mov    %esp,%ebp
f0101694:	83 ec 04             	sub    $0x4,%esp
f0101697:	8b 45 08             	mov    0x8(%ebp),%eax
	if (--pp->pp_ref == 0)
f010169a:	0f b7 50 04          	movzwl 0x4(%eax),%edx
f010169e:	83 ea 01             	sub    $0x1,%edx
f01016a1:	66 89 50 04          	mov    %dx,0x4(%eax)
f01016a5:	66 85 d2             	test   %dx,%dx
f01016a8:	75 08                	jne    f01016b2 <page_decref+0x21>
		page_free(pp);
f01016aa:	89 04 24             	mov    %eax,(%esp)
f01016ad:	e8 ca ff ff ff       	call   f010167c <page_free>
}
f01016b2:	c9                   	leave  
f01016b3:	c3                   	ret    

f01016b4 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f01016b4:	55                   	push   %ebp
f01016b5:	89 e5                	mov    %esp,%ebp
f01016b7:	56                   	push   %esi
f01016b8:	53                   	push   %ebx
f01016b9:	83 ec 10             	sub    $0x10,%esp
f01016bc:	8b 75 0c             	mov    0xc(%ebp),%esi
	// Fill this function in
	bool exist = false;
	pte_t *ptdir;
	if	(pgdir[PDX(va)] & PTE_P) {
f01016bf:	89 f3                	mov    %esi,%ebx
f01016c1:	c1 eb 16             	shr    $0x16,%ebx
f01016c4:	c1 e3 02             	shl    $0x2,%ebx
f01016c7:	03 5d 08             	add    0x8(%ebp),%ebx
f01016ca:	8b 03                	mov    (%ebx),%eax
f01016cc:	a8 01                	test   $0x1,%al
f01016ce:	74 47                	je     f0101717 <pgdir_walk+0x63>
//		pte_t * ptdir = (pte_t*) (PGNUM(*(pgdir + PDX(va))) << PGSHIFT);
		ptdir = (pte_t*) KADDR(PTE_ADDR(pgdir[PDX(va)]));
f01016d0:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01016d5:	89 c2                	mov    %eax,%edx
f01016d7:	c1 ea 0c             	shr    $0xc,%edx
f01016da:	3b 15 84 99 11 f0    	cmp    0xf0119984,%edx
f01016e0:	72 20                	jb     f0101702 <pgdir_walk+0x4e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01016e2:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01016e6:	c7 44 24 08 4c 4c 10 	movl   $0xf0104c4c,0x8(%esp)
f01016ed:	f0 
f01016ee:	c7 44 24 04 65 01 00 	movl   $0x165,0x4(%esp)
f01016f5:	00 
f01016f6:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f01016fd:	e8 92 e9 ff ff       	call   f0100094 <_panic>
//		pgdir[PDX(va)];
//		cprintf("%d", va);
		return ptdir + PTX(va);
f0101702:	c1 ee 0a             	shr    $0xa,%esi
f0101705:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f010170b:	8d 84 30 00 00 00 f0 	lea    -0x10000000(%eax,%esi,1),%eax
f0101712:	e9 85 00 00 00       	jmp    f010179c <pgdir_walk+0xe8>
	} else {
		if (create) {
f0101717:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f010171b:	74 73                	je     f0101790 <pgdir_walk+0xdc>
			struct PageInfo * temp = page_alloc(ALLOC_ZERO);
f010171d:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101724:	e8 d2 fe ff ff       	call   f01015fb <page_alloc>
			if (temp == NULL) return NULL;
f0101729:	85 c0                	test   %eax,%eax
f010172b:	74 6a                	je     f0101797 <pgdir_walk+0xe3>
			temp->pp_ref++;
f010172d:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101732:	89 c2                	mov    %eax,%edx
f0101734:	2b 15 8c 99 11 f0    	sub    0xf011998c,%edx
f010173a:	c1 fa 03             	sar    $0x3,%edx
f010173d:	c1 e2 0c             	shl    $0xc,%edx
			pgdir[PDX(va)] = page2pa(temp) | PTE_P | PTE_U | PTE_W;
f0101740:	83 ca 07             	or     $0x7,%edx
f0101743:	89 13                	mov    %edx,(%ebx)
f0101745:	2b 05 8c 99 11 f0    	sub    0xf011998c,%eax
f010174b:	c1 f8 03             	sar    $0x3,%eax
f010174e:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101751:	89 c2                	mov    %eax,%edx
f0101753:	c1 ea 0c             	shr    $0xc,%edx
f0101756:	3b 15 84 99 11 f0    	cmp    0xf0119984,%edx
f010175c:	72 20                	jb     f010177e <pgdir_walk+0xca>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010175e:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101762:	c7 44 24 08 4c 4c 10 	movl   $0xf0104c4c,0x8(%esp)
f0101769:	f0 
f010176a:	c7 44 24 04 6f 01 00 	movl   $0x16f,0x4(%esp)
f0101771:	00 
f0101772:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f0101779:	e8 16 e9 ff ff       	call   f0100094 <_panic>
			ptdir = (pte_t*) KADDR(page2pa(temp));
			return ptdir + PTX(va);
f010177e:	c1 ee 0a             	shr    $0xa,%esi
f0101781:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f0101787:	8d 84 30 00 00 00 f0 	lea    -0x10000000(%eax,%esi,1),%eax
f010178e:	eb 0c                	jmp    f010179c <pgdir_walk+0xe8>
		} else return NULL;
f0101790:	b8 00 00 00 00       	mov    $0x0,%eax
f0101795:	eb 05                	jmp    f010179c <pgdir_walk+0xe8>
//		cprintf("%d", va);
		return ptdir + PTX(va);
	} else {
		if (create) {
			struct PageInfo * temp = page_alloc(ALLOC_ZERO);
			if (temp == NULL) return NULL;
f0101797:	b8 00 00 00 00       	mov    $0x0,%eax
			return ptdir + PTX(va);
		} else return NULL;
	}
	//temp + PTXSHIFT(va)
	return NULL;
}
f010179c:	83 c4 10             	add    $0x10,%esp
f010179f:	5b                   	pop    %ebx
f01017a0:	5e                   	pop    %esi
f01017a1:	5d                   	pop    %ebp
f01017a2:	c3                   	ret    

f01017a3 <boot_map_region>:
// mapped pages.
// 
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f01017a3:	55                   	push   %ebp
f01017a4:	89 e5                	mov    %esp,%ebp
f01017a6:	57                   	push   %edi
f01017a7:	56                   	push   %esi
f01017a8:	53                   	push   %ebx
f01017a9:	83 ec 2c             	sub    $0x2c,%esp
f01017ac:	89 c7                	mov    %eax,%edi
f01017ae:	89 d3                	mov    %edx,%ebx
f01017b0:	8b 75 08             	mov    0x8(%ebp),%esi
	// Fill this function in
	uintptr_t end = va + size;
f01017b3:	01 d1                	add    %edx,%ecx
f01017b5:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	pte_t* now;
	for (;va != end; va += PGSIZE, pa += PGSIZE) {
f01017b8:	39 ca                	cmp    %ecx,%edx
f01017ba:	74 5b                	je     f0101817 <boot_map_region+0x74>
		now = pgdir_walk(pgdir, (void*)va, 1);
		if (now == NULL)
			panic("stopped");
		*now = PTE_ADDR(pa) | perm | PTE_P;
f01017bc:	8b 45 0c             	mov    0xc(%ebp),%eax
f01017bf:	83 c8 01             	or     $0x1,%eax
f01017c2:	89 45 e0             	mov    %eax,-0x20(%ebp)
{
	// Fill this function in
	uintptr_t end = va + size;
	pte_t* now;
	for (;va != end; va += PGSIZE, pa += PGSIZE) {
		now = pgdir_walk(pgdir, (void*)va, 1);
f01017c5:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01017cc:	00 
f01017cd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01017d1:	89 3c 24             	mov    %edi,(%esp)
f01017d4:	e8 db fe ff ff       	call   f01016b4 <pgdir_walk>
		if (now == NULL)
f01017d9:	85 c0                	test   %eax,%eax
f01017db:	75 1c                	jne    f01017f9 <boot_map_region+0x56>
			panic("stopped");
f01017dd:	c7 44 24 08 ae 56 10 	movl   $0xf01056ae,0x8(%esp)
f01017e4:	f0 
f01017e5:	c7 44 24 04 8a 01 00 	movl   $0x18a,0x4(%esp)
f01017ec:	00 
f01017ed:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f01017f4:	e8 9b e8 ff ff       	call   f0100094 <_panic>
		*now = PTE_ADDR(pa) | perm | PTE_P;
f01017f9:	89 f2                	mov    %esi,%edx
f01017fb:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101801:	0b 55 e0             	or     -0x20(%ebp),%edx
f0101804:	89 10                	mov    %edx,(%eax)
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	uintptr_t end = va + size;
	pte_t* now;
	for (;va != end; va += PGSIZE, pa += PGSIZE) {
f0101806:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f010180c:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0101812:	39 5d e4             	cmp    %ebx,-0x1c(%ebp)
f0101815:	75 ae                	jne    f01017c5 <boot_map_region+0x22>
		now = pgdir_walk(pgdir, (void*)va, 1);
		if (now == NULL)
			panic("stopped");
		*now = PTE_ADDR(pa) | perm | PTE_P;
	}
}
f0101817:	83 c4 2c             	add    $0x2c,%esp
f010181a:	5b                   	pop    %ebx
f010181b:	5e                   	pop    %esi
f010181c:	5f                   	pop    %edi
f010181d:	5d                   	pop    %ebp
f010181e:	c3                   	ret    

f010181f <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f010181f:	55                   	push   %ebp
f0101820:	89 e5                	mov    %esp,%ebp
f0101822:	53                   	push   %ebx
f0101823:	83 ec 14             	sub    $0x14,%esp
f0101826:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// Fill this function in
	pte_t* now = pgdir_walk(pgdir, va, 0);
f0101829:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101830:	00 
f0101831:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101834:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101838:	8b 45 08             	mov    0x8(%ebp),%eax
f010183b:	89 04 24             	mov    %eax,(%esp)
f010183e:	e8 71 fe ff ff       	call   f01016b4 <pgdir_walk>
	if (now != NULL) {
f0101843:	85 c0                	test   %eax,%eax
f0101845:	74 3a                	je     f0101881 <page_lookup+0x62>
		if (pte_store != NULL) {
f0101847:	85 db                	test   %ebx,%ebx
f0101849:	74 02                	je     f010184d <page_lookup+0x2e>
			*pte_store = now;
f010184b:	89 03                	mov    %eax,(%ebx)
		}
		return pa2page(PTE_ADDR(*now));
f010184d:	8b 00                	mov    (%eax),%eax
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010184f:	c1 e8 0c             	shr    $0xc,%eax
f0101852:	3b 05 84 99 11 f0    	cmp    0xf0119984,%eax
f0101858:	72 1c                	jb     f0101876 <page_lookup+0x57>
		panic("pa2page called with invalid pa");
f010185a:	c7 44 24 08 e8 4f 10 	movl   $0xf0104fe8,0x8(%esp)
f0101861:	f0 
f0101862:	c7 44 24 04 4b 00 00 	movl   $0x4b,0x4(%esp)
f0101869:	00 
f010186a:	c7 04 24 04 56 10 f0 	movl   $0xf0105604,(%esp)
f0101871:	e8 1e e8 ff ff       	call   f0100094 <_panic>
	return &pages[PGNUM(pa)];
f0101876:	c1 e0 03             	shl    $0x3,%eax
f0101879:	03 05 8c 99 11 f0    	add    0xf011998c,%eax
f010187f:	eb 05                	jmp    f0101886 <page_lookup+0x67>
	}
	return NULL;
f0101881:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101886:	83 c4 14             	add    $0x14,%esp
f0101889:	5b                   	pop    %ebx
f010188a:	5d                   	pop    %ebp
f010188b:	c3                   	ret    

f010188c <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f010188c:	55                   	push   %ebp
f010188d:	89 e5                	mov    %esp,%ebp
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f010188f:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101892:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f0101895:	5d                   	pop    %ebp
f0101896:	c3                   	ret    

f0101897 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0101897:	55                   	push   %ebp
f0101898:	89 e5                	mov    %esp,%ebp
f010189a:	83 ec 28             	sub    $0x28,%esp
f010189d:	89 5d f8             	mov    %ebx,-0x8(%ebp)
f01018a0:	89 75 fc             	mov    %esi,-0x4(%ebp)
f01018a3:	8b 75 08             	mov    0x8(%ebp),%esi
f01018a6:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
//	if (pgdir & PTE_P == 1) {
	pte_t* now;	
	struct PageInfo* temp = page_lookup(pgdir, va, &now);
f01018a9:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01018ac:	89 44 24 08          	mov    %eax,0x8(%esp)
f01018b0:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01018b4:	89 34 24             	mov    %esi,(%esp)
f01018b7:	e8 63 ff ff ff       	call   f010181f <page_lookup>
	if (temp != NULL) {
f01018bc:	85 c0                	test   %eax,%eax
f01018be:	74 19                	je     f01018d9 <page_remove+0x42>
//		cprintf("%d", now);
		if (*now & PTE_P) {
f01018c0:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01018c3:	f6 02 01             	testb  $0x1,(%edx)
f01018c6:	74 08                	je     f01018d0 <page_remove+0x39>
//			cprintf("subtraction finish!");
			page_decref(temp);
f01018c8:	89 04 24             	mov    %eax,(%esp)
f01018cb:	e8 c1 fd ff ff       	call   f0101691 <page_decref>
		}
		//page_decref(temp);
	//}
		*now = 0;
f01018d0:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01018d3:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	}
	tlb_invalidate(pgdir, va);
f01018d9:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01018dd:	89 34 24             	mov    %esi,(%esp)
f01018e0:	e8 a7 ff ff ff       	call   f010188c <tlb_invalidate>

}
f01018e5:	8b 5d f8             	mov    -0x8(%ebp),%ebx
f01018e8:	8b 75 fc             	mov    -0x4(%ebp),%esi
f01018eb:	89 ec                	mov    %ebp,%esp
f01018ed:	5d                   	pop    %ebp
f01018ee:	c3                   	ret    

f01018ef <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa隐式声明函数‘page_walk’.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f01018ef:	55                   	push   %ebp
f01018f0:	89 e5                	mov    %esp,%ebp
f01018f2:	83 ec 28             	sub    $0x28,%esp
f01018f5:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f01018f8:	89 75 f8             	mov    %esi,-0x8(%ebp)
f01018fb:	89 7d fc             	mov    %edi,-0x4(%ebp)
f01018fe:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101901:	8b 7d 10             	mov    0x10(%ebp),%edi
	// Fill this function in
	pte_t* now = pgdir_walk(pgdir, va, 0);
f0101904:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f010190b:	00 
f010190c:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101910:	8b 45 08             	mov    0x8(%ebp),%eax
f0101913:	89 04 24             	mov    %eax,(%esp)
f0101916:	e8 99 fd ff ff       	call   f01016b4 <pgdir_walk>
f010191b:	89 c3                	mov    %eax,%ebx
	if ((now != NULL) && (*now & PTE_P)) {
f010191d:	85 c0                	test   %eax,%eax
f010191f:	74 3f                	je     f0101960 <page_insert+0x71>
f0101921:	8b 00                	mov    (%eax),%eax
f0101923:	a8 01                	test   $0x1,%al
f0101925:	74 5b                	je     f0101982 <page_insert+0x93>
		//cprintf("!");
//		PageInfo* now_page = (PageInfo*) pa2page(PTE_ADDR(now) + PGOFF(va));
//		page_remove(now_page);
		if (PTE_ADDR(*now) == page2pa(pp)) {
f0101927:	25 00 f0 ff ff       	and    $0xfffff000,%eax
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010192c:	89 f2                	mov    %esi,%edx
f010192e:	2b 15 8c 99 11 f0    	sub    0xf011998c,%edx
f0101934:	c1 fa 03             	sar    $0x3,%edx
f0101937:	c1 e2 0c             	shl    $0xc,%edx
f010193a:	39 d0                	cmp    %edx,%eax
f010193c:	75 11                	jne    f010194f <page_insert+0x60>
			*now = PTE_ADDR(page2pa(pp)) | perm | PTE_P;
f010193e:	8b 55 14             	mov    0x14(%ebp),%edx
f0101941:	83 ca 01             	or     $0x1,%edx
f0101944:	09 d0                	or     %edx,%eax
f0101946:	89 03                	mov    %eax,(%ebx)
			return 0;
f0101948:	b8 00 00 00 00       	mov    $0x0,%eax
f010194d:	eb 55                	jmp    f01019a4 <page_insert+0xb5>
		}
//		cprintf("%d\n", *now);
		page_remove(pgdir, va);
f010194f:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101953:	8b 45 08             	mov    0x8(%ebp),%eax
f0101956:	89 04 24             	mov    %eax,(%esp)
f0101959:	e8 39 ff ff ff       	call   f0101897 <page_remove>
f010195e:	eb 22                	jmp    f0101982 <page_insert+0x93>
	}
	if (now == NULL) now = pgdir_walk(pgdir, va, 1);
f0101960:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0101967:	00 
f0101968:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010196c:	8b 45 08             	mov    0x8(%ebp),%eax
f010196f:	89 04 24             	mov    %eax,(%esp)
f0101972:	e8 3d fd ff ff       	call   f01016b4 <pgdir_walk>
f0101977:	89 c3                	mov    %eax,%ebx
	if (now == NULL) return -E_NO_MEM;
f0101979:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f010197e:	85 db                	test   %ebx,%ebx
f0101980:	74 22                	je     f01019a4 <page_insert+0xb5>
	*now = PTE_ADDR(page2pa(pp)) | perm | PTE_P;
f0101982:	8b 45 14             	mov    0x14(%ebp),%eax
f0101985:	83 c8 01             	or     $0x1,%eax
f0101988:	89 f2                	mov    %esi,%edx
f010198a:	2b 15 8c 99 11 f0    	sub    0xf011998c,%edx
f0101990:	c1 fa 03             	sar    $0x3,%edx
f0101993:	c1 e2 0c             	shl    $0xc,%edx
f0101996:	09 d0                	or     %edx,%eax
f0101998:	89 03                	mov    %eax,(%ebx)
	pp->pp_ref++;
f010199a:	66 83 46 04 01       	addw   $0x1,0x4(%esi)
	return 0;
f010199f:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01019a4:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f01019a7:	8b 75 f8             	mov    -0x8(%ebp),%esi
f01019aa:	8b 7d fc             	mov    -0x4(%ebp),%edi
f01019ad:	89 ec                	mov    %ebp,%esp
f01019af:	5d                   	pop    %ebp
f01019b0:	c3                   	ret    

f01019b1 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f01019b1:	55                   	push   %ebp
f01019b2:	89 e5                	mov    %esp,%ebp
f01019b4:	57                   	push   %edi
f01019b5:	56                   	push   %esi
f01019b6:	53                   	push   %ebx
f01019b7:	83 ec 3c             	sub    $0x3c,%esp
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f01019ba:	b8 15 00 00 00       	mov    $0x15,%eax
f01019bf:	e8 e9 f7 ff ff       	call   f01011ad <nvram_read>
f01019c4:	c1 e0 0a             	shl    $0xa,%eax
f01019c7:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f01019cd:	85 c0                	test   %eax,%eax
f01019cf:	0f 48 c2             	cmovs  %edx,%eax
f01019d2:	c1 f8 0c             	sar    $0xc,%eax
f01019d5:	a3 58 95 11 f0       	mov    %eax,0xf0119558
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f01019da:	b8 17 00 00 00       	mov    $0x17,%eax
f01019df:	e8 c9 f7 ff ff       	call   f01011ad <nvram_read>
f01019e4:	c1 e0 0a             	shl    $0xa,%eax
f01019e7:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f01019ed:	85 c0                	test   %eax,%eax
f01019ef:	0f 48 c2             	cmovs  %edx,%eax
f01019f2:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f01019f5:	85 c0                	test   %eax,%eax
f01019f7:	74 0e                	je     f0101a07 <mem_init+0x56>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f01019f9:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f01019ff:	89 15 84 99 11 f0    	mov    %edx,0xf0119984
f0101a05:	eb 0c                	jmp    f0101a13 <mem_init+0x62>
	else
		npages = npages_basemem;
f0101a07:	8b 15 58 95 11 f0    	mov    0xf0119558,%edx
f0101a0d:	89 15 84 99 11 f0    	mov    %edx,0xf0119984

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
		npages_extmem * PGSIZE / 1024);
f0101a13:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101a16:	c1 e8 0a             	shr    $0xa,%eax
f0101a19:	89 44 24 0c          	mov    %eax,0xc(%esp)
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
f0101a1d:	a1 58 95 11 f0       	mov    0xf0119558,%eax
f0101a22:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101a25:	c1 e8 0a             	shr    $0xa,%eax
f0101a28:	89 44 24 08          	mov    %eax,0x8(%esp)
		npages * PGSIZE / 1024,
f0101a2c:	a1 84 99 11 f0       	mov    0xf0119984,%eax
f0101a31:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101a34:	c1 e8 0a             	shr    $0xa,%eax
f0101a37:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101a3b:	c7 04 24 08 50 10 f0 	movl   $0xf0105008,(%esp)
f0101a42:	e8 3f 1b 00 00       	call   f0103586 <cprintf>
	// Remove this line when you're ready to test this function.
//	panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0101a47:	b8 00 10 00 00       	mov    $0x1000,%eax
f0101a4c:	e8 af f6 ff ff       	call   f0101100 <boot_alloc>
f0101a51:	a3 88 99 11 f0       	mov    %eax,0xf0119988
	memset(kern_pgdir, 0, PGSIZE);
f0101a56:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101a5d:	00 
f0101a5e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101a65:	00 
f0101a66:	89 04 24             	mov    %eax,(%esp)
f0101a69:	e8 d3 26 00 00       	call   f0104141 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0101a6e:	a1 88 99 11 f0       	mov    0xf0119988,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0101a73:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101a78:	77 20                	ja     f0101a9a <mem_init+0xe9>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101a7a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101a7e:	c7 44 24 08 c4 4f 10 	movl   $0xf0104fc4,0x8(%esp)
f0101a85:	f0 
f0101a86:	c7 44 24 04 91 00 00 	movl   $0x91,0x4(%esp)
f0101a8d:	00 
f0101a8e:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f0101a95:	e8 fa e5 ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0101a9a:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0101aa0:	83 ca 05             	or     $0x5,%edx
f0101aa3:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate an array of npages 'struct PageInfo's and store it in 'pages'.
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.
	// Your code goes here:
	pages = (struct PageInfo*) boot_alloc(npages * sizeof(struct PageInfo));
f0101aa9:	a1 84 99 11 f0       	mov    0xf0119984,%eax
f0101aae:	c1 e0 03             	shl    $0x3,%eax
f0101ab1:	e8 4a f6 ff ff       	call   f0101100 <boot_alloc>
f0101ab6:	a3 8c 99 11 f0       	mov    %eax,0xf011998c
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f0101abb:	e8 7b fa ff ff       	call   f010153b <page_init>
	//cprintf("!!!");

	check_page_free_list(1);
f0101ac0:	b8 01 00 00 00       	mov    $0x1,%eax
f0101ac5:	e8 15 f7 ff ff       	call   f01011df <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f0101aca:	83 3d 8c 99 11 f0 00 	cmpl   $0x0,0xf011998c
f0101ad1:	75 1c                	jne    f0101aef <mem_init+0x13e>
		panic("'pages' is a null pointer!");
f0101ad3:	c7 44 24 08 b6 56 10 	movl   $0xf01056b6,0x8(%esp)
f0101ada:	f0 
f0101adb:	c7 44 24 04 56 02 00 	movl   $0x256,0x4(%esp)
f0101ae2:	00 
f0101ae3:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f0101aea:	e8 a5 e5 ff ff       	call   f0100094 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101aef:	a1 60 95 11 f0       	mov    0xf0119560,%eax
f0101af4:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101af9:	85 c0                	test   %eax,%eax
f0101afb:	74 09                	je     f0101b06 <mem_init+0x155>
		++nfree;
f0101afd:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101b00:	8b 00                	mov    (%eax),%eax
f0101b02:	85 c0                	test   %eax,%eax
f0101b04:	75 f7                	jne    f0101afd <mem_init+0x14c>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101b06:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101b0d:	e8 e9 fa ff ff       	call   f01015fb <page_alloc>
f0101b12:	89 c6                	mov    %eax,%esi
f0101b14:	85 c0                	test   %eax,%eax
f0101b16:	75 24                	jne    f0101b3c <mem_init+0x18b>
f0101b18:	c7 44 24 0c d1 56 10 	movl   $0xf01056d1,0xc(%esp)
f0101b1f:	f0 
f0101b20:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f0101b27:	f0 
f0101b28:	c7 44 24 04 5e 02 00 	movl   $0x25e,0x4(%esp)
f0101b2f:	00 
f0101b30:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f0101b37:	e8 58 e5 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f0101b3c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101b43:	e8 b3 fa ff ff       	call   f01015fb <page_alloc>
f0101b48:	89 c7                	mov    %eax,%edi
f0101b4a:	85 c0                	test   %eax,%eax
f0101b4c:	75 24                	jne    f0101b72 <mem_init+0x1c1>
f0101b4e:	c7 44 24 0c e7 56 10 	movl   $0xf01056e7,0xc(%esp)
f0101b55:	f0 
f0101b56:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f0101b5d:	f0 
f0101b5e:	c7 44 24 04 5f 02 00 	movl   $0x25f,0x4(%esp)
f0101b65:	00 
f0101b66:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f0101b6d:	e8 22 e5 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0101b72:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101b79:	e8 7d fa ff ff       	call   f01015fb <page_alloc>
f0101b7e:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101b81:	85 c0                	test   %eax,%eax
f0101b83:	75 24                	jne    f0101ba9 <mem_init+0x1f8>
f0101b85:	c7 44 24 0c fd 56 10 	movl   $0xf01056fd,0xc(%esp)
f0101b8c:	f0 
f0101b8d:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f0101b94:	f0 
f0101b95:	c7 44 24 04 60 02 00 	movl   $0x260,0x4(%esp)
f0101b9c:	00 
f0101b9d:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f0101ba4:	e8 eb e4 ff ff       	call   f0100094 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101ba9:	39 fe                	cmp    %edi,%esi
f0101bab:	75 24                	jne    f0101bd1 <mem_init+0x220>
f0101bad:	c7 44 24 0c 13 57 10 	movl   $0xf0105713,0xc(%esp)
f0101bb4:	f0 
f0101bb5:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f0101bbc:	f0 
f0101bbd:	c7 44 24 04 63 02 00 	movl   $0x263,0x4(%esp)
f0101bc4:	00 
f0101bc5:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f0101bcc:	e8 c3 e4 ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101bd1:	3b 7d d4             	cmp    -0x2c(%ebp),%edi
f0101bd4:	74 05                	je     f0101bdb <mem_init+0x22a>
f0101bd6:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f0101bd9:	75 24                	jne    f0101bff <mem_init+0x24e>
f0101bdb:	c7 44 24 0c 44 50 10 	movl   $0xf0105044,0xc(%esp)
f0101be2:	f0 
f0101be3:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f0101bea:	f0 
f0101beb:	c7 44 24 04 64 02 00 	movl   $0x264,0x4(%esp)
f0101bf2:	00 
f0101bf3:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f0101bfa:	e8 95 e4 ff ff       	call   f0100094 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101bff:	8b 15 8c 99 11 f0    	mov    0xf011998c,%edx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101c05:	a1 84 99 11 f0       	mov    0xf0119984,%eax
f0101c0a:	c1 e0 0c             	shl    $0xc,%eax
f0101c0d:	89 f1                	mov    %esi,%ecx
f0101c0f:	29 d1                	sub    %edx,%ecx
f0101c11:	c1 f9 03             	sar    $0x3,%ecx
f0101c14:	c1 e1 0c             	shl    $0xc,%ecx
f0101c17:	39 c1                	cmp    %eax,%ecx
f0101c19:	72 24                	jb     f0101c3f <mem_init+0x28e>
f0101c1b:	c7 44 24 0c 25 57 10 	movl   $0xf0105725,0xc(%esp)
f0101c22:	f0 
f0101c23:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f0101c2a:	f0 
f0101c2b:	c7 44 24 04 65 02 00 	movl   $0x265,0x4(%esp)
f0101c32:	00 
f0101c33:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f0101c3a:	e8 55 e4 ff ff       	call   f0100094 <_panic>
f0101c3f:	89 f9                	mov    %edi,%ecx
f0101c41:	29 d1                	sub    %edx,%ecx
f0101c43:	c1 f9 03             	sar    $0x3,%ecx
f0101c46:	c1 e1 0c             	shl    $0xc,%ecx
	assert(page2pa(pp1) < npages*PGSIZE);
f0101c49:	39 c8                	cmp    %ecx,%eax
f0101c4b:	77 24                	ja     f0101c71 <mem_init+0x2c0>
f0101c4d:	c7 44 24 0c 42 57 10 	movl   $0xf0105742,0xc(%esp)
f0101c54:	f0 
f0101c55:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f0101c5c:	f0 
f0101c5d:	c7 44 24 04 66 02 00 	movl   $0x266,0x4(%esp)
f0101c64:	00 
f0101c65:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f0101c6c:	e8 23 e4 ff ff       	call   f0100094 <_panic>
f0101c71:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101c74:	29 d1                	sub    %edx,%ecx
f0101c76:	89 ca                	mov    %ecx,%edx
f0101c78:	c1 fa 03             	sar    $0x3,%edx
f0101c7b:	c1 e2 0c             	shl    $0xc,%edx
	assert(page2pa(pp2) < npages*PGSIZE);
f0101c7e:	39 d0                	cmp    %edx,%eax
f0101c80:	77 24                	ja     f0101ca6 <mem_init+0x2f5>
f0101c82:	c7 44 24 0c 5f 57 10 	movl   $0xf010575f,0xc(%esp)
f0101c89:	f0 
f0101c8a:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f0101c91:	f0 
f0101c92:	c7 44 24 04 67 02 00 	movl   $0x267,0x4(%esp)
f0101c99:	00 
f0101c9a:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f0101ca1:	e8 ee e3 ff ff       	call   f0100094 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101ca6:	a1 60 95 11 f0       	mov    0xf0119560,%eax
f0101cab:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101cae:	c7 05 60 95 11 f0 00 	movl   $0x0,0xf0119560
f0101cb5:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101cb8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101cbf:	e8 37 f9 ff ff       	call   f01015fb <page_alloc>
f0101cc4:	85 c0                	test   %eax,%eax
f0101cc6:	74 24                	je     f0101cec <mem_init+0x33b>
f0101cc8:	c7 44 24 0c 7c 57 10 	movl   $0xf010577c,0xc(%esp)
f0101ccf:	f0 
f0101cd0:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f0101cd7:	f0 
f0101cd8:	c7 44 24 04 6e 02 00 	movl   $0x26e,0x4(%esp)
f0101cdf:	00 
f0101ce0:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f0101ce7:	e8 a8 e3 ff ff       	call   f0100094 <_panic>

	// free and re-allocate?
	page_free(pp0);
f0101cec:	89 34 24             	mov    %esi,(%esp)
f0101cef:	e8 88 f9 ff ff       	call   f010167c <page_free>
	page_free(pp1);
f0101cf4:	89 3c 24             	mov    %edi,(%esp)
f0101cf7:	e8 80 f9 ff ff       	call   f010167c <page_free>
	page_free(pp2);
f0101cfc:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101cff:	89 04 24             	mov    %eax,(%esp)
f0101d02:	e8 75 f9 ff ff       	call   f010167c <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101d07:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101d0e:	e8 e8 f8 ff ff       	call   f01015fb <page_alloc>
f0101d13:	89 c6                	mov    %eax,%esi
f0101d15:	85 c0                	test   %eax,%eax
f0101d17:	75 24                	jne    f0101d3d <mem_init+0x38c>
f0101d19:	c7 44 24 0c d1 56 10 	movl   $0xf01056d1,0xc(%esp)
f0101d20:	f0 
f0101d21:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f0101d28:	f0 
f0101d29:	c7 44 24 04 75 02 00 	movl   $0x275,0x4(%esp)
f0101d30:	00 
f0101d31:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f0101d38:	e8 57 e3 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f0101d3d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101d44:	e8 b2 f8 ff ff       	call   f01015fb <page_alloc>
f0101d49:	89 c7                	mov    %eax,%edi
f0101d4b:	85 c0                	test   %eax,%eax
f0101d4d:	75 24                	jne    f0101d73 <mem_init+0x3c2>
f0101d4f:	c7 44 24 0c e7 56 10 	movl   $0xf01056e7,0xc(%esp)
f0101d56:	f0 
f0101d57:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f0101d5e:	f0 
f0101d5f:	c7 44 24 04 76 02 00 	movl   $0x276,0x4(%esp)
f0101d66:	00 
f0101d67:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f0101d6e:	e8 21 e3 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0101d73:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101d7a:	e8 7c f8 ff ff       	call   f01015fb <page_alloc>
f0101d7f:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101d82:	85 c0                	test   %eax,%eax
f0101d84:	75 24                	jne    f0101daa <mem_init+0x3f9>
f0101d86:	c7 44 24 0c fd 56 10 	movl   $0xf01056fd,0xc(%esp)
f0101d8d:	f0 
f0101d8e:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f0101d95:	f0 
f0101d96:	c7 44 24 04 77 02 00 	movl   $0x277,0x4(%esp)
f0101d9d:	00 
f0101d9e:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f0101da5:	e8 ea e2 ff ff       	call   f0100094 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101daa:	39 fe                	cmp    %edi,%esi
f0101dac:	75 24                	jne    f0101dd2 <mem_init+0x421>
f0101dae:	c7 44 24 0c 13 57 10 	movl   $0xf0105713,0xc(%esp)
f0101db5:	f0 
f0101db6:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f0101dbd:	f0 
f0101dbe:	c7 44 24 04 79 02 00 	movl   $0x279,0x4(%esp)
f0101dc5:	00 
f0101dc6:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f0101dcd:	e8 c2 e2 ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101dd2:	3b 7d d4             	cmp    -0x2c(%ebp),%edi
f0101dd5:	74 05                	je     f0101ddc <mem_init+0x42b>
f0101dd7:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f0101dda:	75 24                	jne    f0101e00 <mem_init+0x44f>
f0101ddc:	c7 44 24 0c 44 50 10 	movl   $0xf0105044,0xc(%esp)
f0101de3:	f0 
f0101de4:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f0101deb:	f0 
f0101dec:	c7 44 24 04 7a 02 00 	movl   $0x27a,0x4(%esp)
f0101df3:	00 
f0101df4:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f0101dfb:	e8 94 e2 ff ff       	call   f0100094 <_panic>
	assert(!page_alloc(0));
f0101e00:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101e07:	e8 ef f7 ff ff       	call   f01015fb <page_alloc>
f0101e0c:	85 c0                	test   %eax,%eax
f0101e0e:	74 24                	je     f0101e34 <mem_init+0x483>
f0101e10:	c7 44 24 0c 7c 57 10 	movl   $0xf010577c,0xc(%esp)
f0101e17:	f0 
f0101e18:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f0101e1f:	f0 
f0101e20:	c7 44 24 04 7b 02 00 	movl   $0x27b,0x4(%esp)
f0101e27:	00 
f0101e28:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f0101e2f:	e8 60 e2 ff ff       	call   f0100094 <_panic>
f0101e34:	89 f0                	mov    %esi,%eax
f0101e36:	2b 05 8c 99 11 f0    	sub    0xf011998c,%eax
f0101e3c:	c1 f8 03             	sar    $0x3,%eax
f0101e3f:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101e42:	89 c2                	mov    %eax,%edx
f0101e44:	c1 ea 0c             	shr    $0xc,%edx
f0101e47:	3b 15 84 99 11 f0    	cmp    0xf0119984,%edx
f0101e4d:	72 20                	jb     f0101e6f <mem_init+0x4be>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101e4f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101e53:	c7 44 24 08 4c 4c 10 	movl   $0xf0104c4c,0x8(%esp)
f0101e5a:	f0 
f0101e5b:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0101e62:	00 
f0101e63:	c7 04 24 04 56 10 f0 	movl   $0xf0105604,(%esp)
f0101e6a:	e8 25 e2 ff ff       	call   f0100094 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f0101e6f:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101e76:	00 
f0101e77:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0101e7e:	00 
	return (void *)(pa + KERNBASE);
f0101e7f:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101e84:	89 04 24             	mov    %eax,(%esp)
f0101e87:	e8 b5 22 00 00       	call   f0104141 <memset>
	page_free(pp0);
f0101e8c:	89 34 24             	mov    %esi,(%esp)
f0101e8f:	e8 e8 f7 ff ff       	call   f010167c <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101e94:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101e9b:	e8 5b f7 ff ff       	call   f01015fb <page_alloc>
f0101ea0:	85 c0                	test   %eax,%eax
f0101ea2:	75 24                	jne    f0101ec8 <mem_init+0x517>
f0101ea4:	c7 44 24 0c 8b 57 10 	movl   $0xf010578b,0xc(%esp)
f0101eab:	f0 
f0101eac:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f0101eb3:	f0 
f0101eb4:	c7 44 24 04 80 02 00 	movl   $0x280,0x4(%esp)
f0101ebb:	00 
f0101ebc:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f0101ec3:	e8 cc e1 ff ff       	call   f0100094 <_panic>
	assert(pp && pp0 == pp);
f0101ec8:	39 c6                	cmp    %eax,%esi
f0101eca:	74 24                	je     f0101ef0 <mem_init+0x53f>
f0101ecc:	c7 44 24 0c a9 57 10 	movl   $0xf01057a9,0xc(%esp)
f0101ed3:	f0 
f0101ed4:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f0101edb:	f0 
f0101edc:	c7 44 24 04 81 02 00 	movl   $0x281,0x4(%esp)
f0101ee3:	00 
f0101ee4:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f0101eeb:	e8 a4 e1 ff ff       	call   f0100094 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101ef0:	89 f2                	mov    %esi,%edx
f0101ef2:	2b 15 8c 99 11 f0    	sub    0xf011998c,%edx
f0101ef8:	c1 fa 03             	sar    $0x3,%edx
f0101efb:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101efe:	89 d0                	mov    %edx,%eax
f0101f00:	c1 e8 0c             	shr    $0xc,%eax
f0101f03:	3b 05 84 99 11 f0    	cmp    0xf0119984,%eax
f0101f09:	72 20                	jb     f0101f2b <mem_init+0x57a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101f0b:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101f0f:	c7 44 24 08 4c 4c 10 	movl   $0xf0104c4c,0x8(%esp)
f0101f16:	f0 
f0101f17:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0101f1e:	00 
f0101f1f:	c7 04 24 04 56 10 f0 	movl   $0xf0105604,(%esp)
f0101f26:	e8 69 e1 ff ff       	call   f0100094 <_panic>
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++) 
		assert(c[i] == 0);
f0101f2b:	80 ba 00 00 00 f0 00 	cmpb   $0x0,-0x10000000(%edx)
f0101f32:	75 11                	jne    f0101f45 <mem_init+0x594>
f0101f34:	8d 82 01 00 00 f0    	lea    -0xfffffff(%edx),%eax
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0101f3a:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++) 
		assert(c[i] == 0);
f0101f40:	80 38 00             	cmpb   $0x0,(%eax)
f0101f43:	74 24                	je     f0101f69 <mem_init+0x5b8>
f0101f45:	c7 44 24 0c b9 57 10 	movl   $0xf01057b9,0xc(%esp)
f0101f4c:	f0 
f0101f4d:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f0101f54:	f0 
f0101f55:	c7 44 24 04 84 02 00 	movl   $0x284,0x4(%esp)
f0101f5c:	00 
f0101f5d:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f0101f64:	e8 2b e1 ff ff       	call   f0100094 <_panic>
f0101f69:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++) 
f0101f6c:	39 d0                	cmp    %edx,%eax
f0101f6e:	75 d0                	jne    f0101f40 <mem_init+0x58f>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101f70:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0101f73:	89 15 60 95 11 f0    	mov    %edx,0xf0119560

	// free the pages we took
	page_free(pp0);
f0101f79:	89 34 24             	mov    %esi,(%esp)
f0101f7c:	e8 fb f6 ff ff       	call   f010167c <page_free>
	page_free(pp1);
f0101f81:	89 3c 24             	mov    %edi,(%esp)
f0101f84:	e8 f3 f6 ff ff       	call   f010167c <page_free>
	page_free(pp2);
f0101f89:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f8c:	89 04 24             	mov    %eax,(%esp)
f0101f8f:	e8 e8 f6 ff ff       	call   f010167c <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101f94:	a1 60 95 11 f0       	mov    0xf0119560,%eax
f0101f99:	85 c0                	test   %eax,%eax
f0101f9b:	74 09                	je     f0101fa6 <mem_init+0x5f5>
		--nfree;
f0101f9d:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101fa0:	8b 00                	mov    (%eax),%eax
f0101fa2:	85 c0                	test   %eax,%eax
f0101fa4:	75 f7                	jne    f0101f9d <mem_init+0x5ec>
		--nfree;
	assert(nfree == 0);
f0101fa6:	85 db                	test   %ebx,%ebx
f0101fa8:	74 24                	je     f0101fce <mem_init+0x61d>
f0101faa:	c7 44 24 0c c3 57 10 	movl   $0xf01057c3,0xc(%esp)
f0101fb1:	f0 
f0101fb2:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f0101fb9:	f0 
f0101fba:	c7 44 24 04 91 02 00 	movl   $0x291,0x4(%esp)
f0101fc1:	00 
f0101fc2:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f0101fc9:	e8 c6 e0 ff ff       	call   f0100094 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f0101fce:	c7 04 24 64 50 10 f0 	movl   $0xf0105064,(%esp)
f0101fd5:	e8 ac 15 00 00       	call   f0103586 <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101fda:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101fe1:	e8 15 f6 ff ff       	call   f01015fb <page_alloc>
f0101fe6:	89 c6                	mov    %eax,%esi
f0101fe8:	85 c0                	test   %eax,%eax
f0101fea:	75 24                	jne    f0102010 <mem_init+0x65f>
f0101fec:	c7 44 24 0c d1 56 10 	movl   $0xf01056d1,0xc(%esp)
f0101ff3:	f0 
f0101ff4:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f0101ffb:	f0 
f0101ffc:	c7 44 24 04 ed 02 00 	movl   $0x2ed,0x4(%esp)
f0102003:	00 
f0102004:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f010200b:	e8 84 e0 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f0102010:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102017:	e8 df f5 ff ff       	call   f01015fb <page_alloc>
f010201c:	89 c7                	mov    %eax,%edi
f010201e:	85 c0                	test   %eax,%eax
f0102020:	75 24                	jne    f0102046 <mem_init+0x695>
f0102022:	c7 44 24 0c e7 56 10 	movl   $0xf01056e7,0xc(%esp)
f0102029:	f0 
f010202a:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f0102031:	f0 
f0102032:	c7 44 24 04 ee 02 00 	movl   $0x2ee,0x4(%esp)
f0102039:	00 
f010203a:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f0102041:	e8 4e e0 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0102046:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010204d:	e8 a9 f5 ff ff       	call   f01015fb <page_alloc>
f0102052:	89 c3                	mov    %eax,%ebx
f0102054:	85 c0                	test   %eax,%eax
f0102056:	75 24                	jne    f010207c <mem_init+0x6cb>
f0102058:	c7 44 24 0c fd 56 10 	movl   $0xf01056fd,0xc(%esp)
f010205f:	f0 
f0102060:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f0102067:	f0 
f0102068:	c7 44 24 04 ef 02 00 	movl   $0x2ef,0x4(%esp)
f010206f:	00 
f0102070:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f0102077:	e8 18 e0 ff ff       	call   f0100094 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010207c:	39 fe                	cmp    %edi,%esi
f010207e:	75 24                	jne    f01020a4 <mem_init+0x6f3>
f0102080:	c7 44 24 0c 13 57 10 	movl   $0xf0105713,0xc(%esp)
f0102087:	f0 
f0102088:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f010208f:	f0 
f0102090:	c7 44 24 04 f2 02 00 	movl   $0x2f2,0x4(%esp)
f0102097:	00 
f0102098:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f010209f:	e8 f0 df ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f01020a4:	39 c7                	cmp    %eax,%edi
f01020a6:	74 04                	je     f01020ac <mem_init+0x6fb>
f01020a8:	39 c6                	cmp    %eax,%esi
f01020aa:	75 24                	jne    f01020d0 <mem_init+0x71f>
f01020ac:	c7 44 24 0c 44 50 10 	movl   $0xf0105044,0xc(%esp)
f01020b3:	f0 
f01020b4:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f01020bb:	f0 
f01020bc:	c7 44 24 04 f3 02 00 	movl   $0x2f3,0x4(%esp)
f01020c3:	00 
f01020c4:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f01020cb:	e8 c4 df ff ff       	call   f0100094 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01020d0:	8b 15 60 95 11 f0    	mov    0xf0119560,%edx
f01020d6:	89 55 cc             	mov    %edx,-0x34(%ebp)
	page_free_list = 0;
f01020d9:	c7 05 60 95 11 f0 00 	movl   $0x0,0xf0119560
f01020e0:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01020e3:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01020ea:	e8 0c f5 ff ff       	call   f01015fb <page_alloc>
f01020ef:	85 c0                	test   %eax,%eax
f01020f1:	74 24                	je     f0102117 <mem_init+0x766>
f01020f3:	c7 44 24 0c 7c 57 10 	movl   $0xf010577c,0xc(%esp)
f01020fa:	f0 
f01020fb:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f0102102:	f0 
f0102103:	c7 44 24 04 fa 02 00 	movl   $0x2fa,0x4(%esp)
f010210a:	00 
f010210b:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f0102112:	e8 7d df ff ff       	call   f0100094 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0102117:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010211a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010211e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102125:	00 
f0102126:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f010212b:	89 04 24             	mov    %eax,(%esp)
f010212e:	e8 ec f6 ff ff       	call   f010181f <page_lookup>
f0102133:	85 c0                	test   %eax,%eax
f0102135:	74 24                	je     f010215b <mem_init+0x7aa>
f0102137:	c7 44 24 0c 84 50 10 	movl   $0xf0105084,0xc(%esp)
f010213e:	f0 
f010213f:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f0102146:	f0 
f0102147:	c7 44 24 04 fd 02 00 	movl   $0x2fd,0x4(%esp)
f010214e:	00 
f010214f:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f0102156:	e8 39 df ff ff       	call   f0100094 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f010215b:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102162:	00 
f0102163:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f010216a:	00 
f010216b:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010216f:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f0102174:	89 04 24             	mov    %eax,(%esp)
f0102177:	e8 73 f7 ff ff       	call   f01018ef <page_insert>
f010217c:	85 c0                	test   %eax,%eax
f010217e:	78 24                	js     f01021a4 <mem_init+0x7f3>
f0102180:	c7 44 24 0c bc 50 10 	movl   $0xf01050bc,0xc(%esp)
f0102187:	f0 
f0102188:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f010218f:	f0 
f0102190:	c7 44 24 04 00 03 00 	movl   $0x300,0x4(%esp)
f0102197:	00 
f0102198:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f010219f:	e8 f0 de ff ff       	call   f0100094 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f01021a4:	89 34 24             	mov    %esi,(%esp)
f01021a7:	e8 d0 f4 ff ff       	call   f010167c <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f01021ac:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01021b3:	00 
f01021b4:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01021bb:	00 
f01021bc:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01021c0:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f01021c5:	89 04 24             	mov    %eax,(%esp)
f01021c8:	e8 22 f7 ff ff       	call   f01018ef <page_insert>
f01021cd:	85 c0                	test   %eax,%eax
f01021cf:	74 24                	je     f01021f5 <mem_init+0x844>
f01021d1:	c7 44 24 0c ec 50 10 	movl   $0xf01050ec,0xc(%esp)
f01021d8:	f0 
f01021d9:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f01021e0:	f0 
f01021e1:	c7 44 24 04 04 03 00 	movl   $0x304,0x4(%esp)
f01021e8:	00 
f01021e9:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f01021f0:	e8 9f de ff ff       	call   f0100094 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01021f5:	8b 0d 88 99 11 f0    	mov    0xf0119988,%ecx
f01021fb:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01021fe:	a1 8c 99 11 f0       	mov    0xf011998c,%eax
f0102203:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102206:	8b 11                	mov    (%ecx),%edx
f0102208:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010220e:	89 f0                	mov    %esi,%eax
f0102210:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0102213:	c1 f8 03             	sar    $0x3,%eax
f0102216:	c1 e0 0c             	shl    $0xc,%eax
f0102219:	39 c2                	cmp    %eax,%edx
f010221b:	74 24                	je     f0102241 <mem_init+0x890>
f010221d:	c7 44 24 0c 1c 51 10 	movl   $0xf010511c,0xc(%esp)
f0102224:	f0 
f0102225:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f010222c:	f0 
f010222d:	c7 44 24 04 05 03 00 	movl   $0x305,0x4(%esp)
f0102234:	00 
f0102235:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f010223c:	e8 53 de ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0102241:	ba 00 00 00 00       	mov    $0x0,%edx
f0102246:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102249:	e8 ee ee ff ff       	call   f010113c <check_va2pa>
f010224e:	89 fa                	mov    %edi,%edx
f0102250:	2b 55 d0             	sub    -0x30(%ebp),%edx
f0102253:	c1 fa 03             	sar    $0x3,%edx
f0102256:	c1 e2 0c             	shl    $0xc,%edx
f0102259:	39 d0                	cmp    %edx,%eax
f010225b:	74 24                	je     f0102281 <mem_init+0x8d0>
f010225d:	c7 44 24 0c 44 51 10 	movl   $0xf0105144,0xc(%esp)
f0102264:	f0 
f0102265:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f010226c:	f0 
f010226d:	c7 44 24 04 06 03 00 	movl   $0x306,0x4(%esp)
f0102274:	00 
f0102275:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f010227c:	e8 13 de ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 1);
f0102281:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102286:	74 24                	je     f01022ac <mem_init+0x8fb>
f0102288:	c7 44 24 0c ce 57 10 	movl   $0xf01057ce,0xc(%esp)
f010228f:	f0 
f0102290:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f0102297:	f0 
f0102298:	c7 44 24 04 07 03 00 	movl   $0x307,0x4(%esp)
f010229f:	00 
f01022a0:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f01022a7:	e8 e8 dd ff ff       	call   f0100094 <_panic>
	assert(pp0->pp_ref == 1);
f01022ac:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01022b1:	74 24                	je     f01022d7 <mem_init+0x926>
f01022b3:	c7 44 24 0c df 57 10 	movl   $0xf01057df,0xc(%esp)
f01022ba:	f0 
f01022bb:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f01022c2:	f0 
f01022c3:	c7 44 24 04 08 03 00 	movl   $0x308,0x4(%esp)
f01022ca:	00 
f01022cb:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f01022d2:	e8 bd dd ff ff       	call   f0100094 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01022d7:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01022de:	00 
f01022df:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01022e6:	00 
f01022e7:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01022eb:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01022ee:	89 14 24             	mov    %edx,(%esp)
f01022f1:	e8 f9 f5 ff ff       	call   f01018ef <page_insert>
f01022f6:	85 c0                	test   %eax,%eax
f01022f8:	74 24                	je     f010231e <mem_init+0x96d>
f01022fa:	c7 44 24 0c 74 51 10 	movl   $0xf0105174,0xc(%esp)
f0102301:	f0 
f0102302:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f0102309:	f0 
f010230a:	c7 44 24 04 0b 03 00 	movl   $0x30b,0x4(%esp)
f0102311:	00 
f0102312:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f0102319:	e8 76 dd ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f010231e:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102323:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f0102328:	e8 0f ee ff ff       	call   f010113c <check_va2pa>
f010232d:	89 da                	mov    %ebx,%edx
f010232f:	2b 15 8c 99 11 f0    	sub    0xf011998c,%edx
f0102335:	c1 fa 03             	sar    $0x3,%edx
f0102338:	c1 e2 0c             	shl    $0xc,%edx
f010233b:	39 d0                	cmp    %edx,%eax
f010233d:	74 24                	je     f0102363 <mem_init+0x9b2>
f010233f:	c7 44 24 0c b0 51 10 	movl   $0xf01051b0,0xc(%esp)
f0102346:	f0 
f0102347:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f010234e:	f0 
f010234f:	c7 44 24 04 0c 03 00 	movl   $0x30c,0x4(%esp)
f0102356:	00 
f0102357:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f010235e:	e8 31 dd ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0102363:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102368:	74 24                	je     f010238e <mem_init+0x9dd>
f010236a:	c7 44 24 0c f0 57 10 	movl   $0xf01057f0,0xc(%esp)
f0102371:	f0 
f0102372:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f0102379:	f0 
f010237a:	c7 44 24 04 0d 03 00 	movl   $0x30d,0x4(%esp)
f0102381:	00 
f0102382:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f0102389:	e8 06 dd ff ff       	call   f0100094 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f010238e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102395:	e8 61 f2 ff ff       	call   f01015fb <page_alloc>
f010239a:	85 c0                	test   %eax,%eax
f010239c:	74 24                	je     f01023c2 <mem_init+0xa11>
f010239e:	c7 44 24 0c 7c 57 10 	movl   $0xf010577c,0xc(%esp)
f01023a5:	f0 
f01023a6:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f01023ad:	f0 
f01023ae:	c7 44 24 04 10 03 00 	movl   $0x310,0x4(%esp)
f01023b5:	00 
f01023b6:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f01023bd:	e8 d2 dc ff ff       	call   f0100094 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01023c2:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01023c9:	00 
f01023ca:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01023d1:	00 
f01023d2:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01023d6:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f01023db:	89 04 24             	mov    %eax,(%esp)
f01023de:	e8 0c f5 ff ff       	call   f01018ef <page_insert>
f01023e3:	85 c0                	test   %eax,%eax
f01023e5:	74 24                	je     f010240b <mem_init+0xa5a>
f01023e7:	c7 44 24 0c 74 51 10 	movl   $0xf0105174,0xc(%esp)
f01023ee:	f0 
f01023ef:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f01023f6:	f0 
f01023f7:	c7 44 24 04 13 03 00 	movl   $0x313,0x4(%esp)
f01023fe:	00 
f01023ff:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f0102406:	e8 89 dc ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f010240b:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102410:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f0102415:	e8 22 ed ff ff       	call   f010113c <check_va2pa>
f010241a:	89 da                	mov    %ebx,%edx
f010241c:	2b 15 8c 99 11 f0    	sub    0xf011998c,%edx
f0102422:	c1 fa 03             	sar    $0x3,%edx
f0102425:	c1 e2 0c             	shl    $0xc,%edx
f0102428:	39 d0                	cmp    %edx,%eax
f010242a:	74 24                	je     f0102450 <mem_init+0xa9f>
f010242c:	c7 44 24 0c b0 51 10 	movl   $0xf01051b0,0xc(%esp)
f0102433:	f0 
f0102434:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f010243b:	f0 
f010243c:	c7 44 24 04 14 03 00 	movl   $0x314,0x4(%esp)
f0102443:	00 
f0102444:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f010244b:	e8 44 dc ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0102450:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102455:	74 24                	je     f010247b <mem_init+0xaca>
f0102457:	c7 44 24 0c f0 57 10 	movl   $0xf01057f0,0xc(%esp)
f010245e:	f0 
f010245f:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f0102466:	f0 
f0102467:	c7 44 24 04 15 03 00 	movl   $0x315,0x4(%esp)
f010246e:	00 
f010246f:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f0102476:	e8 19 dc ff ff       	call   f0100094 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f010247b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102482:	e8 74 f1 ff ff       	call   f01015fb <page_alloc>
f0102487:	85 c0                	test   %eax,%eax
f0102489:	74 24                	je     f01024af <mem_init+0xafe>
f010248b:	c7 44 24 0c 7c 57 10 	movl   $0xf010577c,0xc(%esp)
f0102492:	f0 
f0102493:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f010249a:	f0 
f010249b:	c7 44 24 04 19 03 00 	movl   $0x319,0x4(%esp)
f01024a2:	00 
f01024a3:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f01024aa:	e8 e5 db ff ff       	call   f0100094 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f01024af:	8b 15 88 99 11 f0    	mov    0xf0119988,%edx
f01024b5:	8b 02                	mov    (%edx),%eax
f01024b7:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01024bc:	89 c1                	mov    %eax,%ecx
f01024be:	c1 e9 0c             	shr    $0xc,%ecx
f01024c1:	3b 0d 84 99 11 f0    	cmp    0xf0119984,%ecx
f01024c7:	72 20                	jb     f01024e9 <mem_init+0xb38>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01024c9:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01024cd:	c7 44 24 08 4c 4c 10 	movl   $0xf0104c4c,0x8(%esp)
f01024d4:	f0 
f01024d5:	c7 44 24 04 1c 03 00 	movl   $0x31c,0x4(%esp)
f01024dc:	00 
f01024dd:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f01024e4:	e8 ab db ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f01024e9:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01024ee:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f01024f1:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01024f8:	00 
f01024f9:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102500:	00 
f0102501:	89 14 24             	mov    %edx,(%esp)
f0102504:	e8 ab f1 ff ff       	call   f01016b4 <pgdir_walk>
f0102509:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f010250c:	83 c2 04             	add    $0x4,%edx
f010250f:	39 d0                	cmp    %edx,%eax
f0102511:	74 24                	je     f0102537 <mem_init+0xb86>
f0102513:	c7 44 24 0c e0 51 10 	movl   $0xf01051e0,0xc(%esp)
f010251a:	f0 
f010251b:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f0102522:	f0 
f0102523:	c7 44 24 04 1d 03 00 	movl   $0x31d,0x4(%esp)
f010252a:	00 
f010252b:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f0102532:	e8 5d db ff ff       	call   f0100094 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0102537:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f010253e:	00 
f010253f:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102546:	00 
f0102547:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010254b:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f0102550:	89 04 24             	mov    %eax,(%esp)
f0102553:	e8 97 f3 ff ff       	call   f01018ef <page_insert>
f0102558:	85 c0                	test   %eax,%eax
f010255a:	74 24                	je     f0102580 <mem_init+0xbcf>
f010255c:	c7 44 24 0c 20 52 10 	movl   $0xf0105220,0xc(%esp)
f0102563:	f0 
f0102564:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f010256b:	f0 
f010256c:	c7 44 24 04 20 03 00 	movl   $0x320,0x4(%esp)
f0102573:	00 
f0102574:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f010257b:	e8 14 db ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0102580:	8b 0d 88 99 11 f0    	mov    0xf0119988,%ecx
f0102586:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f0102589:	ba 00 10 00 00       	mov    $0x1000,%edx
f010258e:	89 c8                	mov    %ecx,%eax
f0102590:	e8 a7 eb ff ff       	call   f010113c <check_va2pa>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102595:	89 da                	mov    %ebx,%edx
f0102597:	2b 15 8c 99 11 f0    	sub    0xf011998c,%edx
f010259d:	c1 fa 03             	sar    $0x3,%edx
f01025a0:	c1 e2 0c             	shl    $0xc,%edx
f01025a3:	39 d0                	cmp    %edx,%eax
f01025a5:	74 24                	je     f01025cb <mem_init+0xc1a>
f01025a7:	c7 44 24 0c b0 51 10 	movl   $0xf01051b0,0xc(%esp)
f01025ae:	f0 
f01025af:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f01025b6:	f0 
f01025b7:	c7 44 24 04 21 03 00 	movl   $0x321,0x4(%esp)
f01025be:	00 
f01025bf:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f01025c6:	e8 c9 da ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f01025cb:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01025d0:	74 24                	je     f01025f6 <mem_init+0xc45>
f01025d2:	c7 44 24 0c f0 57 10 	movl   $0xf01057f0,0xc(%esp)
f01025d9:	f0 
f01025da:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f01025e1:	f0 
f01025e2:	c7 44 24 04 22 03 00 	movl   $0x322,0x4(%esp)
f01025e9:	00 
f01025ea:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f01025f1:	e8 9e da ff ff       	call   f0100094 <_panic>

	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f01025f6:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01025fd:	00 
f01025fe:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102605:	00 
f0102606:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102609:	89 04 24             	mov    %eax,(%esp)
f010260c:	e8 a3 f0 ff ff       	call   f01016b4 <pgdir_walk>
f0102611:	f6 00 04             	testb  $0x4,(%eax)
f0102614:	75 24                	jne    f010263a <mem_init+0xc89>
f0102616:	c7 44 24 0c 60 52 10 	movl   $0xf0105260,0xc(%esp)
f010261d:	f0 
f010261e:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f0102625:	f0 
f0102626:	c7 44 24 04 24 03 00 	movl   $0x324,0x4(%esp)
f010262d:	00 
f010262e:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f0102635:	e8 5a da ff ff       	call   f0100094 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f010263a:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f010263f:	f6 00 04             	testb  $0x4,(%eax)
f0102642:	75 24                	jne    f0102668 <mem_init+0xcb7>
f0102644:	c7 44 24 0c 01 58 10 	movl   $0xf0105801,0xc(%esp)
f010264b:	f0 
f010264c:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f0102653:	f0 
f0102654:	c7 44 24 04 25 03 00 	movl   $0x325,0x4(%esp)
f010265b:	00 
f010265c:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f0102663:	e8 2c da ff ff       	call   f0100094 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0102668:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f010266f:	00 
f0102670:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102677:	00 
f0102678:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010267c:	89 04 24             	mov    %eax,(%esp)
f010267f:	e8 6b f2 ff ff       	call   f01018ef <page_insert>
f0102684:	85 c0                	test   %eax,%eax
f0102686:	74 24                	je     f01026ac <mem_init+0xcfb>
f0102688:	c7 44 24 0c 74 51 10 	movl   $0xf0105174,0xc(%esp)
f010268f:	f0 
f0102690:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f0102697:	f0 
f0102698:	c7 44 24 04 28 03 00 	movl   $0x328,0x4(%esp)
f010269f:	00 
f01026a0:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f01026a7:	e8 e8 d9 ff ff       	call   f0100094 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f01026ac:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01026b3:	00 
f01026b4:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01026bb:	00 
f01026bc:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f01026c1:	89 04 24             	mov    %eax,(%esp)
f01026c4:	e8 eb ef ff ff       	call   f01016b4 <pgdir_walk>
f01026c9:	f6 00 02             	testb  $0x2,(%eax)
f01026cc:	75 24                	jne    f01026f2 <mem_init+0xd41>
f01026ce:	c7 44 24 0c 94 52 10 	movl   $0xf0105294,0xc(%esp)
f01026d5:	f0 
f01026d6:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f01026dd:	f0 
f01026de:	c7 44 24 04 29 03 00 	movl   $0x329,0x4(%esp)
f01026e5:	00 
f01026e6:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f01026ed:	e8 a2 d9 ff ff       	call   f0100094 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f01026f2:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01026f9:	00 
f01026fa:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102701:	00 
f0102702:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f0102707:	89 04 24             	mov    %eax,(%esp)
f010270a:	e8 a5 ef ff ff       	call   f01016b4 <pgdir_walk>
f010270f:	f6 00 04             	testb  $0x4,(%eax)
f0102712:	74 24                	je     f0102738 <mem_init+0xd87>
f0102714:	c7 44 24 0c c8 52 10 	movl   $0xf01052c8,0xc(%esp)
f010271b:	f0 
f010271c:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f0102723:	f0 
f0102724:	c7 44 24 04 2a 03 00 	movl   $0x32a,0x4(%esp)
f010272b:	00 
f010272c:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f0102733:	e8 5c d9 ff ff       	call   f0100094 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f0102738:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f010273f:	00 
f0102740:	c7 44 24 08 00 00 40 	movl   $0x400000,0x8(%esp)
f0102747:	00 
f0102748:	89 74 24 04          	mov    %esi,0x4(%esp)
f010274c:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f0102751:	89 04 24             	mov    %eax,(%esp)
f0102754:	e8 96 f1 ff ff       	call   f01018ef <page_insert>
f0102759:	85 c0                	test   %eax,%eax
f010275b:	78 24                	js     f0102781 <mem_init+0xdd0>
f010275d:	c7 44 24 0c 00 53 10 	movl   $0xf0105300,0xc(%esp)
f0102764:	f0 
f0102765:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f010276c:	f0 
f010276d:	c7 44 24 04 2d 03 00 	movl   $0x32d,0x4(%esp)
f0102774:	00 
f0102775:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f010277c:	e8 13 d9 ff ff       	call   f0100094 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
//	cprintf("~~w");
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0102781:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102788:	00 
f0102789:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102790:	00 
f0102791:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0102795:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f010279a:	89 04 24             	mov    %eax,(%esp)
f010279d:	e8 4d f1 ff ff       	call   f01018ef <page_insert>
f01027a2:	85 c0                	test   %eax,%eax
f01027a4:	74 24                	je     f01027ca <mem_init+0xe19>
f01027a6:	c7 44 24 0c 38 53 10 	movl   $0xf0105338,0xc(%esp)
f01027ad:	f0 
f01027ae:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f01027b5:	f0 
f01027b6:	c7 44 24 04 31 03 00 	movl   $0x331,0x4(%esp)
f01027bd:	00 
f01027be:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f01027c5:	e8 ca d8 ff ff       	call   f0100094 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f01027ca:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01027d1:	00 
f01027d2:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01027d9:	00 
f01027da:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f01027df:	89 04 24             	mov    %eax,(%esp)
f01027e2:	e8 cd ee ff ff       	call   f01016b4 <pgdir_walk>
f01027e7:	f6 00 04             	testb  $0x4,(%eax)
f01027ea:	74 24                	je     f0102810 <mem_init+0xe5f>
f01027ec:	c7 44 24 0c c8 52 10 	movl   $0xf01052c8,0xc(%esp)
f01027f3:	f0 
f01027f4:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f01027fb:	f0 
f01027fc:	c7 44 24 04 32 03 00 	movl   $0x332,0x4(%esp)
f0102803:	00 
f0102804:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f010280b:	e8 84 d8 ff ff       	call   f0100094 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0102810:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f0102815:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102818:	ba 00 00 00 00       	mov    $0x0,%edx
f010281d:	e8 1a e9 ff ff       	call   f010113c <check_va2pa>
f0102822:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102825:	89 f8                	mov    %edi,%eax
f0102827:	2b 05 8c 99 11 f0    	sub    0xf011998c,%eax
f010282d:	c1 f8 03             	sar    $0x3,%eax
f0102830:	c1 e0 0c             	shl    $0xc,%eax
f0102833:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0102836:	74 24                	je     f010285c <mem_init+0xeab>
f0102838:	c7 44 24 0c 74 53 10 	movl   $0xf0105374,0xc(%esp)
f010283f:	f0 
f0102840:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f0102847:	f0 
f0102848:	c7 44 24 04 35 03 00 	movl   $0x335,0x4(%esp)
f010284f:	00 
f0102850:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f0102857:	e8 38 d8 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f010285c:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102861:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102864:	e8 d3 e8 ff ff       	call   f010113c <check_va2pa>
f0102869:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f010286c:	74 24                	je     f0102892 <mem_init+0xee1>
f010286e:	c7 44 24 0c a0 53 10 	movl   $0xf01053a0,0xc(%esp)
f0102875:	f0 
f0102876:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f010287d:	f0 
f010287e:	c7 44 24 04 36 03 00 	movl   $0x336,0x4(%esp)
f0102885:	00 
f0102886:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f010288d:	e8 02 d8 ff ff       	call   f0100094 <_panic>
	// ... and ref counts should reflect this
//	cprintf("%d %d", pp1->pp_ref, pp2->pp_ref);
	assert(pp1->pp_ref == 2);
f0102892:	66 83 7f 04 02       	cmpw   $0x2,0x4(%edi)
f0102897:	74 24                	je     f01028bd <mem_init+0xf0c>
f0102899:	c7 44 24 0c 17 58 10 	movl   $0xf0105817,0xc(%esp)
f01028a0:	f0 
f01028a1:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f01028a8:	f0 
f01028a9:	c7 44 24 04 39 03 00 	movl   $0x339,0x4(%esp)
f01028b0:	00 
f01028b1:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f01028b8:	e8 d7 d7 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f01028bd:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f01028c2:	74 24                	je     f01028e8 <mem_init+0xf37>
f01028c4:	c7 44 24 0c 28 58 10 	movl   $0xf0105828,0xc(%esp)
f01028cb:	f0 
f01028cc:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f01028d3:	f0 
f01028d4:	c7 44 24 04 3a 03 00 	movl   $0x33a,0x4(%esp)
f01028db:	00 
f01028dc:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f01028e3:	e8 ac d7 ff ff       	call   f0100094 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f01028e8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01028ef:	e8 07 ed ff ff       	call   f01015fb <page_alloc>
f01028f4:	85 c0                	test   %eax,%eax
f01028f6:	74 04                	je     f01028fc <mem_init+0xf4b>
f01028f8:	39 c3                	cmp    %eax,%ebx
f01028fa:	74 24                	je     f0102920 <mem_init+0xf6f>
f01028fc:	c7 44 24 0c d0 53 10 	movl   $0xf01053d0,0xc(%esp)
f0102903:	f0 
f0102904:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f010290b:	f0 
f010290c:	c7 44 24 04 3d 03 00 	movl   $0x33d,0x4(%esp)
f0102913:	00 
f0102914:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f010291b:	e8 74 d7 ff ff       	call   f0100094 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0102920:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102927:	00 
f0102928:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f010292d:	89 04 24             	mov    %eax,(%esp)
f0102930:	e8 62 ef ff ff       	call   f0101897 <page_remove>
//	cprintf("~~~");
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102935:	8b 15 88 99 11 f0    	mov    0xf0119988,%edx
f010293b:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f010293e:	ba 00 00 00 00       	mov    $0x0,%edx
f0102943:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102946:	e8 f1 e7 ff ff       	call   f010113c <check_va2pa>
f010294b:	83 f8 ff             	cmp    $0xffffffff,%eax
f010294e:	74 24                	je     f0102974 <mem_init+0xfc3>
f0102950:	c7 44 24 0c f4 53 10 	movl   $0xf01053f4,0xc(%esp)
f0102957:	f0 
f0102958:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f010295f:	f0 
f0102960:	c7 44 24 04 42 03 00 	movl   $0x342,0x4(%esp)
f0102967:	00 
f0102968:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f010296f:	e8 20 d7 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0102974:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102979:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010297c:	e8 bb e7 ff ff       	call   f010113c <check_va2pa>
f0102981:	89 fa                	mov    %edi,%edx
f0102983:	2b 15 8c 99 11 f0    	sub    0xf011998c,%edx
f0102989:	c1 fa 03             	sar    $0x3,%edx
f010298c:	c1 e2 0c             	shl    $0xc,%edx
f010298f:	39 d0                	cmp    %edx,%eax
f0102991:	74 24                	je     f01029b7 <mem_init+0x1006>
f0102993:	c7 44 24 0c a0 53 10 	movl   $0xf01053a0,0xc(%esp)
f010299a:	f0 
f010299b:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f01029a2:	f0 
f01029a3:	c7 44 24 04 43 03 00 	movl   $0x343,0x4(%esp)
f01029aa:	00 
f01029ab:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f01029b2:	e8 dd d6 ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 1);
f01029b7:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f01029bc:	74 24                	je     f01029e2 <mem_init+0x1031>
f01029be:	c7 44 24 0c ce 57 10 	movl   $0xf01057ce,0xc(%esp)
f01029c5:	f0 
f01029c6:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f01029cd:	f0 
f01029ce:	c7 44 24 04 44 03 00 	movl   $0x344,0x4(%esp)
f01029d5:	00 
f01029d6:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f01029dd:	e8 b2 d6 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f01029e2:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f01029e7:	74 24                	je     f0102a0d <mem_init+0x105c>
f01029e9:	c7 44 24 0c 28 58 10 	movl   $0xf0105828,0xc(%esp)
f01029f0:	f0 
f01029f1:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f01029f8:	f0 
f01029f9:	c7 44 24 04 45 03 00 	movl   $0x345,0x4(%esp)
f0102a00:	00 
f0102a01:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f0102a08:	e8 87 d6 ff ff       	call   f0100094 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102a0d:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102a14:	00 
f0102a15:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0102a18:	89 0c 24             	mov    %ecx,(%esp)
f0102a1b:	e8 77 ee ff ff       	call   f0101897 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102a20:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f0102a25:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102a28:	ba 00 00 00 00       	mov    $0x0,%edx
f0102a2d:	e8 0a e7 ff ff       	call   f010113c <check_va2pa>
f0102a32:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102a35:	74 24                	je     f0102a5b <mem_init+0x10aa>
f0102a37:	c7 44 24 0c f4 53 10 	movl   $0xf01053f4,0xc(%esp)
f0102a3e:	f0 
f0102a3f:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f0102a46:	f0 
f0102a47:	c7 44 24 04 49 03 00 	movl   $0x349,0x4(%esp)
f0102a4e:	00 
f0102a4f:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f0102a56:	e8 39 d6 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0102a5b:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102a60:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102a63:	e8 d4 e6 ff ff       	call   f010113c <check_va2pa>
f0102a68:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102a6b:	74 24                	je     f0102a91 <mem_init+0x10e0>
f0102a6d:	c7 44 24 0c 18 54 10 	movl   $0xf0105418,0xc(%esp)
f0102a74:	f0 
f0102a75:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f0102a7c:	f0 
f0102a7d:	c7 44 24 04 4a 03 00 	movl   $0x34a,0x4(%esp)
f0102a84:	00 
f0102a85:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f0102a8c:	e8 03 d6 ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 0);
f0102a91:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102a96:	74 24                	je     f0102abc <mem_init+0x110b>
f0102a98:	c7 44 24 0c 39 58 10 	movl   $0xf0105839,0xc(%esp)
f0102a9f:	f0 
f0102aa0:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f0102aa7:	f0 
f0102aa8:	c7 44 24 04 4b 03 00 	movl   $0x34b,0x4(%esp)
f0102aaf:	00 
f0102ab0:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f0102ab7:	e8 d8 d5 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f0102abc:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102ac1:	74 24                	je     f0102ae7 <mem_init+0x1136>
f0102ac3:	c7 44 24 0c 28 58 10 	movl   $0xf0105828,0xc(%esp)
f0102aca:	f0 
f0102acb:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f0102ad2:	f0 
f0102ad3:	c7 44 24 04 4c 03 00 	movl   $0x34c,0x4(%esp)
f0102ada:	00 
f0102adb:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f0102ae2:	e8 ad d5 ff ff       	call   f0100094 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0102ae7:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102aee:	e8 08 eb ff ff       	call   f01015fb <page_alloc>
f0102af3:	85 c0                	test   %eax,%eax
f0102af5:	74 04                	je     f0102afb <mem_init+0x114a>
f0102af7:	39 c7                	cmp    %eax,%edi
f0102af9:	74 24                	je     f0102b1f <mem_init+0x116e>
f0102afb:	c7 44 24 0c 40 54 10 	movl   $0xf0105440,0xc(%esp)
f0102b02:	f0 
f0102b03:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f0102b0a:	f0 
f0102b0b:	c7 44 24 04 4f 03 00 	movl   $0x34f,0x4(%esp)
f0102b12:	00 
f0102b13:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f0102b1a:	e8 75 d5 ff ff       	call   f0100094 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0102b1f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102b26:	e8 d0 ea ff ff       	call   f01015fb <page_alloc>
f0102b2b:	85 c0                	test   %eax,%eax
f0102b2d:	74 24                	je     f0102b53 <mem_init+0x11a2>
f0102b2f:	c7 44 24 0c 7c 57 10 	movl   $0xf010577c,0xc(%esp)
f0102b36:	f0 
f0102b37:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f0102b3e:	f0 
f0102b3f:	c7 44 24 04 52 03 00 	movl   $0x352,0x4(%esp)
f0102b46:	00 
f0102b47:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f0102b4e:	e8 41 d5 ff ff       	call   f0100094 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102b53:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f0102b58:	8b 08                	mov    (%eax),%ecx
f0102b5a:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0102b60:	89 f2                	mov    %esi,%edx
f0102b62:	2b 15 8c 99 11 f0    	sub    0xf011998c,%edx
f0102b68:	c1 fa 03             	sar    $0x3,%edx
f0102b6b:	c1 e2 0c             	shl    $0xc,%edx
f0102b6e:	39 d1                	cmp    %edx,%ecx
f0102b70:	74 24                	je     f0102b96 <mem_init+0x11e5>
f0102b72:	c7 44 24 0c 1c 51 10 	movl   $0xf010511c,0xc(%esp)
f0102b79:	f0 
f0102b7a:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f0102b81:	f0 
f0102b82:	c7 44 24 04 55 03 00 	movl   $0x355,0x4(%esp)
f0102b89:	00 
f0102b8a:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f0102b91:	e8 fe d4 ff ff       	call   f0100094 <_panic>
	kern_pgdir[0] = 0;
f0102b96:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f0102b9c:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102ba1:	74 24                	je     f0102bc7 <mem_init+0x1216>
f0102ba3:	c7 44 24 0c df 57 10 	movl   $0xf01057df,0xc(%esp)
f0102baa:	f0 
f0102bab:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f0102bb2:	f0 
f0102bb3:	c7 44 24 04 57 03 00 	movl   $0x357,0x4(%esp)
f0102bba:	00 
f0102bbb:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f0102bc2:	e8 cd d4 ff ff       	call   f0100094 <_panic>
	pp0->pp_ref = 0;
f0102bc7:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0102bcd:	89 34 24             	mov    %esi,(%esp)
f0102bd0:	e8 a7 ea ff ff       	call   f010167c <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0102bd5:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0102bdc:	00 
f0102bdd:	c7 44 24 04 00 10 40 	movl   $0x401000,0x4(%esp)
f0102be4:	00 
f0102be5:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f0102bea:	89 04 24             	mov    %eax,(%esp)
f0102bed:	e8 c2 ea ff ff       	call   f01016b4 <pgdir_walk>
f0102bf2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0102bf5:	8b 0d 88 99 11 f0    	mov    0xf0119988,%ecx
f0102bfb:	8b 51 04             	mov    0x4(%ecx),%edx
f0102bfe:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102c04:	89 55 d4             	mov    %edx,-0x2c(%ebp)
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102c07:	8b 15 84 99 11 f0    	mov    0xf0119984,%edx
f0102c0d:	89 55 c8             	mov    %edx,-0x38(%ebp)
f0102c10:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0102c13:	c1 ea 0c             	shr    $0xc,%edx
f0102c16:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0102c19:	8b 55 c8             	mov    -0x38(%ebp),%edx
f0102c1c:	39 55 d0             	cmp    %edx,-0x30(%ebp)
f0102c1f:	72 23                	jb     f0102c44 <mem_init+0x1293>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102c21:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0102c24:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0102c28:	c7 44 24 08 4c 4c 10 	movl   $0xf0104c4c,0x8(%esp)
f0102c2f:	f0 
f0102c30:	c7 44 24 04 5e 03 00 	movl   $0x35e,0x4(%esp)
f0102c37:	00 
f0102c38:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f0102c3f:	e8 50 d4 ff ff       	call   f0100094 <_panic>
	assert(ptep == ptep1 + PTX(va));
f0102c44:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0102c47:	81 ea fc ff ff 0f    	sub    $0xffffffc,%edx
f0102c4d:	39 d0                	cmp    %edx,%eax
f0102c4f:	74 24                	je     f0102c75 <mem_init+0x12c4>
f0102c51:	c7 44 24 0c 4a 58 10 	movl   $0xf010584a,0xc(%esp)
f0102c58:	f0 
f0102c59:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f0102c60:	f0 
f0102c61:	c7 44 24 04 5f 03 00 	movl   $0x35f,0x4(%esp)
f0102c68:	00 
f0102c69:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f0102c70:	e8 1f d4 ff ff       	call   f0100094 <_panic>
	kern_pgdir[PDX(va)] = 0;
f0102c75:	c7 41 04 00 00 00 00 	movl   $0x0,0x4(%ecx)
	pp0->pp_ref = 0;
f0102c7c:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102c82:	89 f0                	mov    %esi,%eax
f0102c84:	2b 05 8c 99 11 f0    	sub    0xf011998c,%eax
f0102c8a:	c1 f8 03             	sar    $0x3,%eax
f0102c8d:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102c90:	89 c1                	mov    %eax,%ecx
f0102c92:	c1 e9 0c             	shr    $0xc,%ecx
f0102c95:	39 4d c8             	cmp    %ecx,-0x38(%ebp)
f0102c98:	77 20                	ja     f0102cba <mem_init+0x1309>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102c9a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102c9e:	c7 44 24 08 4c 4c 10 	movl   $0xf0104c4c,0x8(%esp)
f0102ca5:	f0 
f0102ca6:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0102cad:	00 
f0102cae:	c7 04 24 04 56 10 f0 	movl   $0xf0105604,(%esp)
f0102cb5:	e8 da d3 ff ff       	call   f0100094 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0102cba:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102cc1:	00 
f0102cc2:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
f0102cc9:	00 
	return (void *)(pa + KERNBASE);
f0102cca:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102ccf:	89 04 24             	mov    %eax,(%esp)
f0102cd2:	e8 6a 14 00 00       	call   f0104141 <memset>
	page_free(pp0);
f0102cd7:	89 34 24             	mov    %esi,(%esp)
f0102cda:	e8 9d e9 ff ff       	call   f010167c <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0102cdf:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0102ce6:	00 
f0102ce7:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102cee:	00 
f0102cef:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f0102cf4:	89 04 24             	mov    %eax,(%esp)
f0102cf7:	e8 b8 e9 ff ff       	call   f01016b4 <pgdir_walk>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102cfc:	89 f2                	mov    %esi,%edx
f0102cfe:	2b 15 8c 99 11 f0    	sub    0xf011998c,%edx
f0102d04:	c1 fa 03             	sar    $0x3,%edx
f0102d07:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102d0a:	89 d0                	mov    %edx,%eax
f0102d0c:	c1 e8 0c             	shr    $0xc,%eax
f0102d0f:	3b 05 84 99 11 f0    	cmp    0xf0119984,%eax
f0102d15:	72 20                	jb     f0102d37 <mem_init+0x1386>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102d17:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0102d1b:	c7 44 24 08 4c 4c 10 	movl   $0xf0104c4c,0x8(%esp)
f0102d22:	f0 
f0102d23:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0102d2a:	00 
f0102d2b:	c7 04 24 04 56 10 f0 	movl   $0xf0105604,(%esp)
f0102d32:	e8 5d d3 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0102d37:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f0102d3d:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102d40:	f6 82 00 00 00 f0 01 	testb  $0x1,-0x10000000(%edx)
f0102d47:	75 11                	jne    f0102d5a <mem_init+0x13a9>
f0102d49:	8d 82 04 00 00 f0    	lea    -0xffffffc(%edx),%eax
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0102d4f:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102d55:	f6 00 01             	testb  $0x1,(%eax)
f0102d58:	74 24                	je     f0102d7e <mem_init+0x13cd>
f0102d5a:	c7 44 24 0c 62 58 10 	movl   $0xf0105862,0xc(%esp)
f0102d61:	f0 
f0102d62:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f0102d69:	f0 
f0102d6a:	c7 44 24 04 69 03 00 	movl   $0x369,0x4(%esp)
f0102d71:	00 
f0102d72:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f0102d79:	e8 16 d3 ff ff       	call   f0100094 <_panic>
f0102d7e:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f0102d81:	39 d0                	cmp    %edx,%eax
f0102d83:	75 d0                	jne    f0102d55 <mem_init+0x13a4>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f0102d85:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f0102d8a:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102d90:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// give free list back
	page_free_list = fl;
f0102d96:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0102d99:	89 0d 60 95 11 f0    	mov    %ecx,0xf0119560

	// free the pages we took
	page_free(pp0);
f0102d9f:	89 34 24             	mov    %esi,(%esp)
f0102da2:	e8 d5 e8 ff ff       	call   f010167c <page_free>
	page_free(pp1);
f0102da7:	89 3c 24             	mov    %edi,(%esp)
f0102daa:	e8 cd e8 ff ff       	call   f010167c <page_free>
	page_free(pp2);
f0102daf:	89 1c 24             	mov    %ebx,(%esp)
f0102db2:	e8 c5 e8 ff ff       	call   f010167c <page_free>

	cprintf("check_page() succeeded!\n");
f0102db7:	c7 04 24 79 58 10 f0 	movl   $0xf0105879,(%esp)
f0102dbe:	e8 c3 07 00 00       	call   f0103586 <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, UPAGES, ROUNDUP(npages * sizeof(struct PageInfo), PGSIZE), PADDR(pages), PTE_U | PTE_P);
f0102dc3:	a1 8c 99 11 f0       	mov    0xf011998c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102dc8:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102dcd:	77 20                	ja     f0102def <mem_init+0x143e>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102dcf:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102dd3:	c7 44 24 08 c4 4f 10 	movl   $0xf0104fc4,0x8(%esp)
f0102dda:	f0 
f0102ddb:	c7 44 24 04 b2 00 00 	movl   $0xb2,0x4(%esp)
f0102de2:	00 
f0102de3:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f0102dea:	e8 a5 d2 ff ff       	call   f0100094 <_panic>
f0102def:	8b 15 84 99 11 f0    	mov    0xf0119984,%edx
f0102df5:	8d 0c d5 ff 0f 00 00 	lea    0xfff(,%edx,8),%ecx
f0102dfc:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0102e02:	c7 44 24 04 05 00 00 	movl   $0x5,0x4(%esp)
f0102e09:	00 
	return (physaddr_t)kva - KERNBASE;
f0102e0a:	05 00 00 00 10       	add    $0x10000000,%eax
f0102e0f:	89 04 24             	mov    %eax,(%esp)
f0102e12:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102e17:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f0102e1c:	e8 82 e9 ff ff       	call   f01017a3 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102e21:	be 00 f0 10 f0       	mov    $0xf010f000,%esi
f0102e26:	81 fe ff ff ff ef    	cmp    $0xefffffff,%esi
f0102e2c:	77 20                	ja     f0102e4e <mem_init+0x149d>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102e2e:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0102e32:	c7 44 24 08 c4 4f 10 	movl   $0xf0104fc4,0x8(%esp)
f0102e39:	f0 
f0102e3a:	c7 44 24 04 bf 00 00 	movl   $0xbf,0x4(%esp)
f0102e41:	00 
f0102e42:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f0102e49:	e8 46 d2 ff ff       	call   f0100094 <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KSTACKTOP - KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W);
f0102e4e:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f0102e55:	00 
f0102e56:	c7 04 24 00 f0 10 00 	movl   $0x10f000,(%esp)
f0102e5d:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102e62:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f0102e67:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f0102e6c:	e8 32 e9 ff ff       	call   f01017a3 <boot_map_region>
	//      the PA range [0, 2^32 - KERNBASE)
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KERNBASE, /*(1 << 32)*/ - KERNBASE, 0, PTE_W); 
f0102e71:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f0102e78:	00 
f0102e79:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102e80:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f0102e85:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0102e8a:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f0102e8f:	e8 0f e9 ff ff       	call   f01017a3 <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f0102e94:	8b 1d 88 99 11 f0    	mov    0xf0119988,%ebx

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0102e9a:	8b 35 84 99 11 f0    	mov    0xf0119984,%esi
f0102ea0:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f0102ea3:	8d 3c f5 ff 0f 00 00 	lea    0xfff(,%esi,8),%edi
	for (i = 0; i < n; i += PGSIZE) {
f0102eaa:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
f0102eb0:	74 79                	je     f0102f2b <mem_init+0x157a>
f0102eb2:	be 00 00 00 00       	mov    $0x0,%esi
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0102eb7:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx
	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE) {
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102ebd:	89 d8                	mov    %ebx,%eax
f0102ebf:	e8 78 e2 ff ff       	call   f010113c <check_va2pa>
f0102ec4:	8b 15 8c 99 11 f0    	mov    0xf011998c,%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102eca:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0102ed0:	77 20                	ja     f0102ef2 <mem_init+0x1541>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102ed2:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0102ed6:	c7 44 24 08 c4 4f 10 	movl   $0xf0104fc4,0x8(%esp)
f0102edd:	f0 
f0102ede:	c7 44 24 04 a9 02 00 	movl   $0x2a9,0x4(%esp)
f0102ee5:	00 
f0102ee6:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f0102eed:	e8 a2 d1 ff ff       	call   f0100094 <_panic>
f0102ef2:	8d 94 32 00 00 00 10 	lea    0x10000000(%edx,%esi,1),%edx
f0102ef9:	39 d0                	cmp    %edx,%eax
f0102efb:	74 24                	je     f0102f21 <mem_init+0x1570>
f0102efd:	c7 44 24 0c 64 54 10 	movl   $0xf0105464,0xc(%esp)
f0102f04:	f0 
f0102f05:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f0102f0c:	f0 
f0102f0d:	c7 44 24 04 a9 02 00 	movl   $0x2a9,0x4(%esp)
f0102f14:	00 
f0102f15:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f0102f1c:	e8 73 d1 ff ff       	call   f0100094 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE) {
f0102f21:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102f27:	39 f7                	cmp    %esi,%edi
f0102f29:	77 8c                	ja     f0102eb7 <mem_init+0x1506>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
	}


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102f2b:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102f2e:	c1 e7 0c             	shl    $0xc,%edi
f0102f31:	85 ff                	test   %edi,%edi
f0102f33:	74 44                	je     f0102f79 <mem_init+0x15c8>
f0102f35:	be 00 00 00 00       	mov    $0x0,%esi
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0102f3a:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
	}


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102f40:	89 d8                	mov    %ebx,%eax
f0102f42:	e8 f5 e1 ff ff       	call   f010113c <check_va2pa>
f0102f47:	39 c6                	cmp    %eax,%esi
f0102f49:	74 24                	je     f0102f6f <mem_init+0x15be>
f0102f4b:	c7 44 24 0c 98 54 10 	movl   $0xf0105498,0xc(%esp)
f0102f52:	f0 
f0102f53:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f0102f5a:	f0 
f0102f5b:	c7 44 24 04 af 02 00 	movl   $0x2af,0x4(%esp)
f0102f62:	00 
f0102f63:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f0102f6a:	e8 25 d1 ff ff       	call   f0100094 <_panic>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
	}


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102f6f:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102f75:	39 fe                	cmp    %edi,%esi
f0102f77:	72 c1                	jb     f0102f3a <mem_init+0x1589>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102f79:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f0102f7e:	89 d8                	mov    %ebx,%eax
f0102f80:	e8 b7 e1 ff ff       	call   f010113c <check_va2pa>
f0102f85:	be 00 90 ff ef       	mov    $0xefff9000,%esi
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0102f8a:	bf 00 f0 10 f0       	mov    $0xf010f000,%edi
f0102f8f:	81 c7 00 70 00 20    	add    $0x20007000,%edi
f0102f95:	8d 14 37             	lea    (%edi,%esi,1),%edx
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102f98:	39 c2                	cmp    %eax,%edx
f0102f9a:	74 24                	je     f0102fc0 <mem_init+0x160f>
f0102f9c:	c7 44 24 0c c0 54 10 	movl   $0xf01054c0,0xc(%esp)
f0102fa3:	f0 
f0102fa4:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f0102fab:	f0 
f0102fac:	c7 44 24 04 b3 02 00 	movl   $0x2b3,0x4(%esp)
f0102fb3:	00 
f0102fb4:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f0102fbb:	e8 d4 d0 ff ff       	call   f0100094 <_panic>
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0102fc0:	81 fe 00 00 00 f0    	cmp    $0xf0000000,%esi
f0102fc6:	0f 85 37 05 00 00    	jne    f0103503 <mem_init+0x1b52>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102fcc:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f0102fd1:	89 d8                	mov    %ebx,%eax
f0102fd3:	e8 64 e1 ff ff       	call   f010113c <check_va2pa>
f0102fd8:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102fdb:	74 24                	je     f0103001 <mem_init+0x1650>
f0102fdd:	c7 44 24 0c 08 55 10 	movl   $0xf0105508,0xc(%esp)
f0102fe4:	f0 
f0102fe5:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f0102fec:	f0 
f0102fed:	c7 44 24 04 b4 02 00 	movl   $0x2b4,0x4(%esp)
f0102ff4:	00 
f0102ff5:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f0102ffc:	e8 93 d0 ff ff       	call   f0100094 <_panic>
f0103001:	b8 00 00 00 00       	mov    $0x0,%eax

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f0103006:	ba 01 00 00 00       	mov    $0x1,%edx
f010300b:	8d 88 44 fc ff ff    	lea    -0x3bc(%eax),%ecx
f0103011:	83 f9 03             	cmp    $0x3,%ecx
f0103014:	77 39                	ja     f010304f <mem_init+0x169e>
f0103016:	89 d6                	mov    %edx,%esi
f0103018:	d3 e6                	shl    %cl,%esi
f010301a:	89 f1                	mov    %esi,%ecx
f010301c:	f6 c1 0b             	test   $0xb,%cl
f010301f:	74 2e                	je     f010304f <mem_init+0x169e>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
f0103021:	f6 04 83 01          	testb  $0x1,(%ebx,%eax,4)
f0103025:	0f 85 aa 00 00 00    	jne    f01030d5 <mem_init+0x1724>
f010302b:	c7 44 24 0c 92 58 10 	movl   $0xf0105892,0xc(%esp)
f0103032:	f0 
f0103033:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f010303a:	f0 
f010303b:	c7 44 24 04 bc 02 00 	movl   $0x2bc,0x4(%esp)
f0103042:	00 
f0103043:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f010304a:	e8 45 d0 ff ff       	call   f0100094 <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f010304f:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0103054:	76 55                	jbe    f01030ab <mem_init+0x16fa>
				assert(pgdir[i] & PTE_P);
f0103056:	8b 0c 83             	mov    (%ebx,%eax,4),%ecx
f0103059:	f6 c1 01             	test   $0x1,%cl
f010305c:	75 24                	jne    f0103082 <mem_init+0x16d1>
f010305e:	c7 44 24 0c 92 58 10 	movl   $0xf0105892,0xc(%esp)
f0103065:	f0 
f0103066:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f010306d:	f0 
f010306e:	c7 44 24 04 c0 02 00 	movl   $0x2c0,0x4(%esp)
f0103075:	00 
f0103076:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f010307d:	e8 12 d0 ff ff       	call   f0100094 <_panic>
				assert(pgdir[i] & PTE_W);
f0103082:	f6 c1 02             	test   $0x2,%cl
f0103085:	75 4e                	jne    f01030d5 <mem_init+0x1724>
f0103087:	c7 44 24 0c a3 58 10 	movl   $0xf01058a3,0xc(%esp)
f010308e:	f0 
f010308f:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f0103096:	f0 
f0103097:	c7 44 24 04 c1 02 00 	movl   $0x2c1,0x4(%esp)
f010309e:	00 
f010309f:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f01030a6:	e8 e9 cf ff ff       	call   f0100094 <_panic>
			} else
				assert(pgdir[i] == 0);
f01030ab:	83 3c 83 00          	cmpl   $0x0,(%ebx,%eax,4)
f01030af:	74 24                	je     f01030d5 <mem_init+0x1724>
f01030b1:	c7 44 24 0c b4 58 10 	movl   $0xf01058b4,0xc(%esp)
f01030b8:	f0 
f01030b9:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f01030c0:	f0 
f01030c1:	c7 44 24 04 c3 02 00 	movl   $0x2c3,0x4(%esp)
f01030c8:	00 
f01030c9:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f01030d0:	e8 bf cf ff ff       	call   f0100094 <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f01030d5:	83 c0 01             	add    $0x1,%eax
f01030d8:	3d 00 04 00 00       	cmp    $0x400,%eax
f01030dd:	0f 85 28 ff ff ff    	jne    f010300b <mem_init+0x165a>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f01030e3:	c7 04 24 38 55 10 f0 	movl   $0xf0105538,(%esp)
f01030ea:	e8 97 04 00 00       	call   f0103586 <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f01030ef:	a1 88 99 11 f0       	mov    0xf0119988,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01030f4:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01030f9:	77 20                	ja     f010311b <mem_init+0x176a>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01030fb:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01030ff:	c7 44 24 08 c4 4f 10 	movl   $0xf0104fc4,0x8(%esp)
f0103106:	f0 
f0103107:	c7 44 24 04 d4 00 00 	movl   $0xd4,0x4(%esp)
f010310e:	00 
f010310f:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f0103116:	e8 79 cf ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f010311b:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0103120:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f0103123:	b8 00 00 00 00       	mov    $0x0,%eax
f0103128:	e8 b2 e0 ff ff       	call   f01011df <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f010312d:	0f 20 c0             	mov    %cr0,%eax

	// entry.S set the really important flags in cr0 (including enabling
	// paging).  Here we configure the rest of the flags that we care about.
	cr0 = rcr0();
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_MP;
f0103130:	0d 23 00 05 80       	or     $0x80050023,%eax
	cr0 &= ~(CR0_TS|CR0_EM);
f0103135:	83 e0 f3             	and    $0xfffffff3,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f0103138:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010313b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0103142:	e8 b4 e4 ff ff       	call   f01015fb <page_alloc>
f0103147:	89 c6                	mov    %eax,%esi
f0103149:	85 c0                	test   %eax,%eax
f010314b:	75 24                	jne    f0103171 <mem_init+0x17c0>
f010314d:	c7 44 24 0c d1 56 10 	movl   $0xf01056d1,0xc(%esp)
f0103154:	f0 
f0103155:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f010315c:	f0 
f010315d:	c7 44 24 04 84 03 00 	movl   $0x384,0x4(%esp)
f0103164:	00 
f0103165:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f010316c:	e8 23 cf ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f0103171:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0103178:	e8 7e e4 ff ff       	call   f01015fb <page_alloc>
f010317d:	89 c7                	mov    %eax,%edi
f010317f:	85 c0                	test   %eax,%eax
f0103181:	75 24                	jne    f01031a7 <mem_init+0x17f6>
f0103183:	c7 44 24 0c e7 56 10 	movl   $0xf01056e7,0xc(%esp)
f010318a:	f0 
f010318b:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f0103192:	f0 
f0103193:	c7 44 24 04 85 03 00 	movl   $0x385,0x4(%esp)
f010319a:	00 
f010319b:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f01031a2:	e8 ed ce ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f01031a7:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01031ae:	e8 48 e4 ff ff       	call   f01015fb <page_alloc>
f01031b3:	89 c3                	mov    %eax,%ebx
f01031b5:	85 c0                	test   %eax,%eax
f01031b7:	75 24                	jne    f01031dd <mem_init+0x182c>
f01031b9:	c7 44 24 0c fd 56 10 	movl   $0xf01056fd,0xc(%esp)
f01031c0:	f0 
f01031c1:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f01031c8:	f0 
f01031c9:	c7 44 24 04 86 03 00 	movl   $0x386,0x4(%esp)
f01031d0:	00 
f01031d1:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f01031d8:	e8 b7 ce ff ff       	call   f0100094 <_panic>
	page_free(pp0);
f01031dd:	89 34 24             	mov    %esi,(%esp)
f01031e0:	e8 97 e4 ff ff       	call   f010167c <page_free>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01031e5:	89 f8                	mov    %edi,%eax
f01031e7:	2b 05 8c 99 11 f0    	sub    0xf011998c,%eax
f01031ed:	c1 f8 03             	sar    $0x3,%eax
f01031f0:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01031f3:	89 c2                	mov    %eax,%edx
f01031f5:	c1 ea 0c             	shr    $0xc,%edx
f01031f8:	3b 15 84 99 11 f0    	cmp    0xf0119984,%edx
f01031fe:	72 20                	jb     f0103220 <mem_init+0x186f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0103200:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103204:	c7 44 24 08 4c 4c 10 	movl   $0xf0104c4c,0x8(%esp)
f010320b:	f0 
f010320c:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0103213:	00 
f0103214:	c7 04 24 04 56 10 f0 	movl   $0xf0105604,(%esp)
f010321b:	e8 74 ce ff ff       	call   f0100094 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f0103220:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0103227:	00 
f0103228:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f010322f:	00 
	return (void *)(pa + KERNBASE);
f0103230:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0103235:	89 04 24             	mov    %eax,(%esp)
f0103238:	e8 04 0f 00 00       	call   f0104141 <memset>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010323d:	89 d8                	mov    %ebx,%eax
f010323f:	2b 05 8c 99 11 f0    	sub    0xf011998c,%eax
f0103245:	c1 f8 03             	sar    $0x3,%eax
f0103248:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010324b:	89 c2                	mov    %eax,%edx
f010324d:	c1 ea 0c             	shr    $0xc,%edx
f0103250:	3b 15 84 99 11 f0    	cmp    0xf0119984,%edx
f0103256:	72 20                	jb     f0103278 <mem_init+0x18c7>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0103258:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010325c:	c7 44 24 08 4c 4c 10 	movl   $0xf0104c4c,0x8(%esp)
f0103263:	f0 
f0103264:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f010326b:	00 
f010326c:	c7 04 24 04 56 10 f0 	movl   $0xf0105604,(%esp)
f0103273:	e8 1c ce ff ff       	call   f0100094 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f0103278:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010327f:	00 
f0103280:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f0103287:	00 
	return (void *)(pa + KERNBASE);
f0103288:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010328d:	89 04 24             	mov    %eax,(%esp)
f0103290:	e8 ac 0e 00 00       	call   f0104141 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0103295:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f010329c:	00 
f010329d:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01032a4:	00 
f01032a5:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01032a9:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f01032ae:	89 04 24             	mov    %eax,(%esp)
f01032b1:	e8 39 e6 ff ff       	call   f01018ef <page_insert>
	assert(pp1->pp_ref == 1);
f01032b6:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f01032bb:	74 24                	je     f01032e1 <mem_init+0x1930>
f01032bd:	c7 44 24 0c ce 57 10 	movl   $0xf01057ce,0xc(%esp)
f01032c4:	f0 
f01032c5:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f01032cc:	f0 
f01032cd:	c7 44 24 04 8b 03 00 	movl   $0x38b,0x4(%esp)
f01032d4:	00 
f01032d5:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f01032dc:	e8 b3 cd ff ff       	call   f0100094 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f01032e1:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f01032e8:	01 01 01 
f01032eb:	74 24                	je     f0103311 <mem_init+0x1960>
f01032ed:	c7 44 24 0c 58 55 10 	movl   $0xf0105558,0xc(%esp)
f01032f4:	f0 
f01032f5:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f01032fc:	f0 
f01032fd:	c7 44 24 04 8c 03 00 	movl   $0x38c,0x4(%esp)
f0103304:	00 
f0103305:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f010330c:	e8 83 cd ff ff       	call   f0100094 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0103311:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0103318:	00 
f0103319:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0103320:	00 
f0103321:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103325:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f010332a:	89 04 24             	mov    %eax,(%esp)
f010332d:	e8 bd e5 ff ff       	call   f01018ef <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0103332:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0103339:	02 02 02 
f010333c:	74 24                	je     f0103362 <mem_init+0x19b1>
f010333e:	c7 44 24 0c 7c 55 10 	movl   $0xf010557c,0xc(%esp)
f0103345:	f0 
f0103346:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f010334d:	f0 
f010334e:	c7 44 24 04 8e 03 00 	movl   $0x38e,0x4(%esp)
f0103355:	00 
f0103356:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f010335d:	e8 32 cd ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0103362:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0103367:	74 24                	je     f010338d <mem_init+0x19dc>
f0103369:	c7 44 24 0c f0 57 10 	movl   $0xf01057f0,0xc(%esp)
f0103370:	f0 
f0103371:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f0103378:	f0 
f0103379:	c7 44 24 04 8f 03 00 	movl   $0x38f,0x4(%esp)
f0103380:	00 
f0103381:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f0103388:	e8 07 cd ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 0);
f010338d:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0103392:	74 24                	je     f01033b8 <mem_init+0x1a07>
f0103394:	c7 44 24 0c 39 58 10 	movl   $0xf0105839,0xc(%esp)
f010339b:	f0 
f010339c:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f01033a3:	f0 
f01033a4:	c7 44 24 04 90 03 00 	movl   $0x390,0x4(%esp)
f01033ab:	00 
f01033ac:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f01033b3:	e8 dc cc ff ff       	call   f0100094 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f01033b8:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f01033bf:	03 03 03 
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01033c2:	89 d8                	mov    %ebx,%eax
f01033c4:	2b 05 8c 99 11 f0    	sub    0xf011998c,%eax
f01033ca:	c1 f8 03             	sar    $0x3,%eax
f01033cd:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01033d0:	89 c2                	mov    %eax,%edx
f01033d2:	c1 ea 0c             	shr    $0xc,%edx
f01033d5:	3b 15 84 99 11 f0    	cmp    0xf0119984,%edx
f01033db:	72 20                	jb     f01033fd <mem_init+0x1a4c>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01033dd:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01033e1:	c7 44 24 08 4c 4c 10 	movl   $0xf0104c4c,0x8(%esp)
f01033e8:	f0 
f01033e9:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f01033f0:	00 
f01033f1:	c7 04 24 04 56 10 f0 	movl   $0xf0105604,(%esp)
f01033f8:	e8 97 cc ff ff       	call   f0100094 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f01033fd:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0103404:	03 03 03 
f0103407:	74 24                	je     f010342d <mem_init+0x1a7c>
f0103409:	c7 44 24 0c a0 55 10 	movl   $0xf01055a0,0xc(%esp)
f0103410:	f0 
f0103411:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f0103418:	f0 
f0103419:	c7 44 24 04 92 03 00 	movl   $0x392,0x4(%esp)
f0103420:	00 
f0103421:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f0103428:	e8 67 cc ff ff       	call   f0100094 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f010342d:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0103434:	00 
f0103435:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f010343a:	89 04 24             	mov    %eax,(%esp)
f010343d:	e8 55 e4 ff ff       	call   f0101897 <page_remove>
	assert(pp2->pp_ref == 0);
f0103442:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0103447:	74 24                	je     f010346d <mem_init+0x1abc>
f0103449:	c7 44 24 0c 28 58 10 	movl   $0xf0105828,0xc(%esp)
f0103450:	f0 
f0103451:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f0103458:	f0 
f0103459:	c7 44 24 04 94 03 00 	movl   $0x394,0x4(%esp)
f0103460:	00 
f0103461:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f0103468:	e8 27 cc ff ff       	call   f0100094 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010346d:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f0103472:	8b 08                	mov    (%eax),%ecx
f0103474:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010347a:	89 f2                	mov    %esi,%edx
f010347c:	2b 15 8c 99 11 f0    	sub    0xf011998c,%edx
f0103482:	c1 fa 03             	sar    $0x3,%edx
f0103485:	c1 e2 0c             	shl    $0xc,%edx
f0103488:	39 d1                	cmp    %edx,%ecx
f010348a:	74 24                	je     f01034b0 <mem_init+0x1aff>
f010348c:	c7 44 24 0c 1c 51 10 	movl   $0xf010511c,0xc(%esp)
f0103493:	f0 
f0103494:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f010349b:	f0 
f010349c:	c7 44 24 04 97 03 00 	movl   $0x397,0x4(%esp)
f01034a3:	00 
f01034a4:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f01034ab:	e8 e4 cb ff ff       	call   f0100094 <_panic>
	kern_pgdir[0] = 0;
f01034b0:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f01034b6:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01034bb:	74 24                	je     f01034e1 <mem_init+0x1b30>
f01034bd:	c7 44 24 0c df 57 10 	movl   $0xf01057df,0xc(%esp)
f01034c4:	f0 
f01034c5:	c7 44 24 08 1e 56 10 	movl   $0xf010561e,0x8(%esp)
f01034cc:	f0 
f01034cd:	c7 44 24 04 99 03 00 	movl   $0x399,0x4(%esp)
f01034d4:	00 
f01034d5:	c7 04 24 f8 55 10 f0 	movl   $0xf01055f8,(%esp)
f01034dc:	e8 b3 cb ff ff       	call   f0100094 <_panic>
	pp0->pp_ref = 0;
f01034e1:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// free the pages we took
	page_free(pp0);
f01034e7:	89 34 24             	mov    %esi,(%esp)
f01034ea:	e8 8d e1 ff ff       	call   f010167c <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f01034ef:	c7 04 24 cc 55 10 f0 	movl   $0xf01055cc,(%esp)
f01034f6:	e8 8b 00 00 00       	call   f0103586 <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f01034fb:	83 c4 3c             	add    $0x3c,%esp
f01034fe:	5b                   	pop    %ebx
f01034ff:	5e                   	pop    %esi
f0103500:	5f                   	pop    %edi
f0103501:	5d                   	pop    %ebp
f0103502:	c3                   	ret    
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0103503:	89 f2                	mov    %esi,%edx
f0103505:	89 d8                	mov    %ebx,%eax
f0103507:	e8 30 dc ff ff       	call   f010113c <check_va2pa>
f010350c:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0103512:	e9 7e fa ff ff       	jmp    f0102f95 <mem_init+0x15e4>
	...

f0103518 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0103518:	55                   	push   %ebp
f0103519:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010351b:	ba 70 00 00 00       	mov    $0x70,%edx
f0103520:	8b 45 08             	mov    0x8(%ebp),%eax
f0103523:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0103524:	b2 71                	mov    $0x71,%dl
f0103526:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0103527:	0f b6 c0             	movzbl %al,%eax
}
f010352a:	5d                   	pop    %ebp
f010352b:	c3                   	ret    

f010352c <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f010352c:	55                   	push   %ebp
f010352d:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010352f:	ba 70 00 00 00       	mov    $0x70,%edx
f0103534:	8b 45 08             	mov    0x8(%ebp),%eax
f0103537:	ee                   	out    %al,(%dx)
f0103538:	b2 71                	mov    $0x71,%dl
f010353a:	8b 45 0c             	mov    0xc(%ebp),%eax
f010353d:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f010353e:	5d                   	pop    %ebp
f010353f:	c3                   	ret    

f0103540 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0103540:	55                   	push   %ebp
f0103541:	89 e5                	mov    %esp,%ebp
f0103543:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f0103546:	8b 45 08             	mov    0x8(%ebp),%eax
f0103549:	89 04 24             	mov    %eax,(%esp)
f010354c:	e8 a8 d0 ff ff       	call   f01005f9 <cputchar>
	*cnt++;
}
f0103551:	c9                   	leave  
f0103552:	c3                   	ret    

f0103553 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0103553:	55                   	push   %ebp
f0103554:	89 e5                	mov    %esp,%ebp
f0103556:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f0103559:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0103560:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103563:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103567:	8b 45 08             	mov    0x8(%ebp),%eax
f010356a:	89 44 24 08          	mov    %eax,0x8(%esp)
f010356e:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0103571:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103575:	c7 04 24 40 35 10 f0 	movl   $0xf0103540,(%esp)
f010357c:	e8 b9 04 00 00       	call   f0103a3a <vprintfmt>
	return cnt;
}
f0103581:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103584:	c9                   	leave  
f0103585:	c3                   	ret    

f0103586 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0103586:	55                   	push   %ebp
f0103587:	89 e5                	mov    %esp,%ebp
f0103589:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f010358c:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f010358f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103593:	8b 45 08             	mov    0x8(%ebp),%eax
f0103596:	89 04 24             	mov    %eax,(%esp)
f0103599:	e8 b5 ff ff ff       	call   f0103553 <vcprintf>
	va_end(ap);

	return cnt;
}
f010359e:	c9                   	leave  
f010359f:	c3                   	ret    

f01035a0 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f01035a0:	55                   	push   %ebp
f01035a1:	89 e5                	mov    %esp,%ebp
f01035a3:	57                   	push   %edi
f01035a4:	56                   	push   %esi
f01035a5:	53                   	push   %ebx
f01035a6:	83 ec 10             	sub    $0x10,%esp
f01035a9:	89 c3                	mov    %eax,%ebx
f01035ab:	89 55 e8             	mov    %edx,-0x18(%ebp)
f01035ae:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f01035b1:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f01035b4:	8b 0a                	mov    (%edx),%ecx
f01035b6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01035b9:	8b 00                	mov    (%eax),%eax
f01035bb:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01035be:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)

	while (l <= r) {
f01035c5:	eb 77                	jmp    f010363e <stab_binsearch+0x9e>
		int true_m = (l + r) / 2, m = true_m;
f01035c7:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01035ca:	01 c8                	add    %ecx,%eax
f01035cc:	bf 02 00 00 00       	mov    $0x2,%edi
f01035d1:	99                   	cltd   
f01035d2:	f7 ff                	idiv   %edi
f01035d4:	89 c2                	mov    %eax,%edx

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01035d6:	eb 01                	jmp    f01035d9 <stab_binsearch+0x39>
			m--;
f01035d8:	4a                   	dec    %edx

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01035d9:	39 ca                	cmp    %ecx,%edx
f01035db:	7c 1d                	jl     f01035fa <stab_binsearch+0x5a>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f01035dd:	6b fa 0c             	imul   $0xc,%edx,%edi

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01035e0:	0f b6 7c 3b 04       	movzbl 0x4(%ebx,%edi,1),%edi
f01035e5:	39 f7                	cmp    %esi,%edi
f01035e7:	75 ef                	jne    f01035d8 <stab_binsearch+0x38>
f01035e9:	89 55 ec             	mov    %edx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01035ec:	6b fa 0c             	imul   $0xc,%edx,%edi
f01035ef:	8b 7c 3b 08          	mov    0x8(%ebx,%edi,1),%edi
f01035f3:	3b 7d 0c             	cmp    0xc(%ebp),%edi
f01035f6:	73 18                	jae    f0103610 <stab_binsearch+0x70>
f01035f8:	eb 05                	jmp    f01035ff <stab_binsearch+0x5f>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f01035fa:	8d 48 01             	lea    0x1(%eax),%ecx
			continue;
f01035fd:	eb 3f                	jmp    f010363e <stab_binsearch+0x9e>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f01035ff:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0103602:	89 11                	mov    %edx,(%ecx)
			l = true_m + 1;
f0103604:	8d 48 01             	lea    0x1(%eax),%ecx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0103607:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f010360e:	eb 2e                	jmp    f010363e <stab_binsearch+0x9e>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0103610:	3b 7d 0c             	cmp    0xc(%ebp),%edi
f0103613:	76 15                	jbe    f010362a <stab_binsearch+0x8a>
			*region_right = m - 1;
f0103615:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0103618:	4f                   	dec    %edi
f0103619:	89 7d f0             	mov    %edi,-0x10(%ebp)
f010361c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010361f:	89 38                	mov    %edi,(%eax)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0103621:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0103628:	eb 14                	jmp    f010363e <stab_binsearch+0x9e>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f010362a:	8b 7d ec             	mov    -0x14(%ebp),%edi
f010362d:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0103630:	89 39                	mov    %edi,(%ecx)
			l = m;
			addr++;
f0103632:	ff 45 0c             	incl   0xc(%ebp)
f0103635:	89 d1                	mov    %edx,%ecx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0103637:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f010363e:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
f0103641:	7e 84                	jle    f01035c7 <stab_binsearch+0x27>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0103643:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0103647:	75 0d                	jne    f0103656 <stab_binsearch+0xb6>
		*region_right = *region_left - 1;
f0103649:	8b 55 e8             	mov    -0x18(%ebp),%edx
f010364c:	8b 02                	mov    (%edx),%eax
f010364e:	48                   	dec    %eax
f010364f:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0103652:	89 01                	mov    %eax,(%ecx)
f0103654:	eb 22                	jmp    f0103678 <stab_binsearch+0xd8>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103656:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0103659:	8b 01                	mov    (%ecx),%eax
		     l > *region_left && stabs[l].n_type != type;
f010365b:	8b 55 e8             	mov    -0x18(%ebp),%edx
f010365e:	8b 0a                	mov    (%edx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103660:	eb 01                	jmp    f0103663 <stab_binsearch+0xc3>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0103662:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103663:	39 c1                	cmp    %eax,%ecx
f0103665:	7d 0c                	jge    f0103673 <stab_binsearch+0xd3>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0103667:	6b d0 0c             	imul   $0xc,%eax,%edx
	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
		     l > *region_left && stabs[l].n_type != type;
f010366a:	0f b6 54 13 04       	movzbl 0x4(%ebx,%edx,1),%edx
f010366f:	39 f2                	cmp    %esi,%edx
f0103671:	75 ef                	jne    f0103662 <stab_binsearch+0xc2>
		     l--)
			/* do nothing */;
		*region_left = l;
f0103673:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0103676:	89 02                	mov    %eax,(%edx)
	}
}
f0103678:	83 c4 10             	add    $0x10,%esp
f010367b:	5b                   	pop    %ebx
f010367c:	5e                   	pop    %esi
f010367d:	5f                   	pop    %edi
f010367e:	5d                   	pop    %ebp
f010367f:	c3                   	ret    

f0103680 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0103680:	55                   	push   %ebp
f0103681:	89 e5                	mov    %esp,%ebp
f0103683:	83 ec 58             	sub    $0x58,%esp
f0103686:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0103689:	89 75 f8             	mov    %esi,-0x8(%ebp)
f010368c:	89 7d fc             	mov    %edi,-0x4(%ebp)
f010368f:	8b 75 08             	mov    0x8(%ebp),%esi
f0103692:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0103695:	c7 03 c2 58 10 f0    	movl   $0xf01058c2,(%ebx)
	info->eip_line = 0;
f010369b:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f01036a2:	c7 43 08 c2 58 10 f0 	movl   $0xf01058c2,0x8(%ebx)
	info->eip_fn_namelen = 9;
f01036a9:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f01036b0:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f01036b3:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f01036ba:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f01036c0:	76 12                	jbe    f01036d4 <debuginfo_eip+0x54>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01036c2:	b8 7f e8 10 f0       	mov    $0xf010e87f,%eax
f01036c7:	3d 51 c8 10 f0       	cmp    $0xf010c851,%eax
f01036cc:	0f 86 f1 01 00 00    	jbe    f01038c3 <debuginfo_eip+0x243>
f01036d2:	eb 1c                	jmp    f01036f0 <debuginfo_eip+0x70>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f01036d4:	c7 44 24 08 cc 58 10 	movl   $0xf01058cc,0x8(%esp)
f01036db:	f0 
f01036dc:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f01036e3:	00 
f01036e4:	c7 04 24 d9 58 10 f0 	movl   $0xf01058d9,(%esp)
f01036eb:	e8 a4 c9 ff ff       	call   f0100094 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f01036f0:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01036f5:	80 3d 7e e8 10 f0 00 	cmpb   $0x0,0xf010e87e
f01036fc:	0f 85 cd 01 00 00    	jne    f01038cf <debuginfo_eip+0x24f>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0103702:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0103709:	b8 50 c8 10 f0       	mov    $0xf010c850,%eax
f010370e:	2d e8 5a 10 f0       	sub    $0xf0105ae8,%eax
f0103713:	c1 f8 02             	sar    $0x2,%eax
f0103716:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f010371c:	83 e8 01             	sub    $0x1,%eax
f010371f:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0103722:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103726:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f010372d:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0103730:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0103733:	b8 e8 5a 10 f0       	mov    $0xf0105ae8,%eax
f0103738:	e8 63 fe ff ff       	call   f01035a0 <stab_binsearch>
	if (lfile == 0)
f010373d:	8b 55 e4             	mov    -0x1c(%ebp),%edx
		return -1;
f0103740:	b8 ff ff ff ff       	mov    $0xffffffff,%eax

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
f0103745:	85 d2                	test   %edx,%edx
f0103747:	0f 84 82 01 00 00    	je     f01038cf <debuginfo_eip+0x24f>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f010374d:	89 55 dc             	mov    %edx,-0x24(%ebp)
	rfun = rfile;
f0103750:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103753:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0103756:	89 74 24 04          	mov    %esi,0x4(%esp)
f010375a:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0103761:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0103764:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0103767:	b8 e8 5a 10 f0       	mov    $0xf0105ae8,%eax
f010376c:	e8 2f fe ff ff       	call   f01035a0 <stab_binsearch>

	if (lfun <= rfun) {
f0103771:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103774:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0103777:	39 d0                	cmp    %edx,%eax
f0103779:	7f 3d                	jg     f01037b8 <debuginfo_eip+0x138>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f010377b:	6b c8 0c             	imul   $0xc,%eax,%ecx
f010377e:	8d b9 e8 5a 10 f0    	lea    -0xfefa518(%ecx),%edi
f0103784:	89 7d c0             	mov    %edi,-0x40(%ebp)
f0103787:	8b 89 e8 5a 10 f0    	mov    -0xfefa518(%ecx),%ecx
f010378d:	bf 7f e8 10 f0       	mov    $0xf010e87f,%edi
f0103792:	81 ef 51 c8 10 f0    	sub    $0xf010c851,%edi
f0103798:	39 f9                	cmp    %edi,%ecx
f010379a:	73 09                	jae    f01037a5 <debuginfo_eip+0x125>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f010379c:	81 c1 51 c8 10 f0    	add    $0xf010c851,%ecx
f01037a2:	89 4b 08             	mov    %ecx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f01037a5:	8b 7d c0             	mov    -0x40(%ebp),%edi
f01037a8:	8b 4f 08             	mov    0x8(%edi),%ecx
f01037ab:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f01037ae:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f01037b0:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f01037b3:	89 55 d0             	mov    %edx,-0x30(%ebp)
f01037b6:	eb 0f                	jmp    f01037c7 <debuginfo_eip+0x147>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f01037b8:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f01037bb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01037be:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f01037c1:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01037c4:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f01037c7:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f01037ce:	00 
f01037cf:	8b 43 08             	mov    0x8(%ebx),%eax
f01037d2:	89 04 24             	mov    %eax,(%esp)
f01037d5:	e8 40 09 00 00       	call   f010411a <strfind>
f01037da:	2b 43 08             	sub    0x8(%ebx),%eax
f01037dd:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f01037e0:	89 74 24 04          	mov    %esi,0x4(%esp)
f01037e4:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f01037eb:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f01037ee:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f01037f1:	b8 e8 5a 10 f0       	mov    $0xf0105ae8,%eax
f01037f6:	e8 a5 fd ff ff       	call   f01035a0 <stab_binsearch>
	if (lline <= rline) {
f01037fb:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01037fe:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0103801:	7f 0f                	jg     f0103812 <debuginfo_eip+0x192>
		info->eip_line = stabs[lline].n_desc;
f0103803:	6b c0 0c             	imul   $0xc,%eax,%eax
f0103806:	0f b7 80 ee 5a 10 f0 	movzwl -0xfefa512(%eax),%eax
f010380d:	89 43 04             	mov    %eax,0x4(%ebx)
f0103810:	eb 07                	jmp    f0103819 <debuginfo_eip+0x199>
	} else {
		info->eip_line = -1;
f0103812:	c7 43 04 ff ff ff ff 	movl   $0xffffffff,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0103819:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010381c:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f010381f:	39 c8                	cmp    %ecx,%eax
f0103821:	7c 5f                	jl     f0103882 <debuginfo_eip+0x202>
	       && stabs[lline].n_type != N_SOL
f0103823:	89 c2                	mov    %eax,%edx
f0103825:	6b f0 0c             	imul   $0xc,%eax,%esi
f0103828:	80 be ec 5a 10 f0 84 	cmpb   $0x84,-0xfefa514(%esi)
f010382f:	75 18                	jne    f0103849 <debuginfo_eip+0x1c9>
f0103831:	eb 30                	jmp    f0103863 <debuginfo_eip+0x1e3>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0103833:	83 e8 01             	sub    $0x1,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0103836:	39 c1                	cmp    %eax,%ecx
f0103838:	7f 48                	jg     f0103882 <debuginfo_eip+0x202>
	       && stabs[lline].n_type != N_SOL
f010383a:	89 c2                	mov    %eax,%edx
f010383c:	8d 34 40             	lea    (%eax,%eax,2),%esi
f010383f:	80 3c b5 ec 5a 10 f0 	cmpb   $0x84,-0xfefa514(,%esi,4)
f0103846:	84 
f0103847:	74 1a                	je     f0103863 <debuginfo_eip+0x1e3>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0103849:	8d 14 52             	lea    (%edx,%edx,2),%edx
f010384c:	8d 14 95 e8 5a 10 f0 	lea    -0xfefa518(,%edx,4),%edx
f0103853:	80 7a 04 64          	cmpb   $0x64,0x4(%edx)
f0103857:	75 da                	jne    f0103833 <debuginfo_eip+0x1b3>
f0103859:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f010385d:	74 d4                	je     f0103833 <debuginfo_eip+0x1b3>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f010385f:	39 c8                	cmp    %ecx,%eax
f0103861:	7c 1f                	jl     f0103882 <debuginfo_eip+0x202>
f0103863:	6b c0 0c             	imul   $0xc,%eax,%eax
f0103866:	8b 80 e8 5a 10 f0    	mov    -0xfefa518(%eax),%eax
f010386c:	ba 7f e8 10 f0       	mov    $0xf010e87f,%edx
f0103871:	81 ea 51 c8 10 f0    	sub    $0xf010c851,%edx
f0103877:	39 d0                	cmp    %edx,%eax
f0103879:	73 07                	jae    f0103882 <debuginfo_eip+0x202>
		info->eip_file = stabstr + stabs[lline].n_strx;
f010387b:	05 51 c8 10 f0       	add    $0xf010c851,%eax
f0103880:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103882:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103885:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103888:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f010388d:	39 ca                	cmp    %ecx,%edx
f010388f:	7d 3e                	jge    f01038cf <debuginfo_eip+0x24f>
		for (lline = lfun + 1;
f0103891:	83 c2 01             	add    $0x1,%edx
f0103894:	39 d1                	cmp    %edx,%ecx
f0103896:	7e 37                	jle    f01038cf <debuginfo_eip+0x24f>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0103898:	6b f2 0c             	imul   $0xc,%edx,%esi
f010389b:	80 be ec 5a 10 f0 a0 	cmpb   $0xa0,-0xfefa514(%esi)
f01038a2:	75 2b                	jne    f01038cf <debuginfo_eip+0x24f>
		     lline++)
			info->eip_fn_narg++;
f01038a4:	83 43 14 01          	addl   $0x1,0x14(%ebx)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f01038a8:	83 c2 01             	add    $0x1,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f01038ab:	39 d1                	cmp    %edx,%ecx
f01038ad:	7e 1b                	jle    f01038ca <debuginfo_eip+0x24a>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f01038af:	8d 04 52             	lea    (%edx,%edx,2),%eax
f01038b2:	80 3c 85 ec 5a 10 f0 	cmpb   $0xa0,-0xfefa514(,%eax,4)
f01038b9:	a0 
f01038ba:	74 e8                	je     f01038a4 <debuginfo_eip+0x224>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01038bc:	b8 00 00 00 00       	mov    $0x0,%eax
f01038c1:	eb 0c                	jmp    f01038cf <debuginfo_eip+0x24f>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f01038c3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01038c8:	eb 05                	jmp    f01038cf <debuginfo_eip+0x24f>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01038ca:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01038cf:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f01038d2:	8b 75 f8             	mov    -0x8(%ebp),%esi
f01038d5:	8b 7d fc             	mov    -0x4(%ebp),%edi
f01038d8:	89 ec                	mov    %ebp,%esp
f01038da:	5d                   	pop    %ebp
f01038db:	c3                   	ret    
f01038dc:	00 00                	add    %al,(%eax)
	...

f01038e0 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f01038e0:	55                   	push   %ebp
f01038e1:	89 e5                	mov    %esp,%ebp
f01038e3:	57                   	push   %edi
f01038e4:	56                   	push   %esi
f01038e5:	53                   	push   %ebx
f01038e6:	83 ec 3c             	sub    $0x3c,%esp
f01038e9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01038ec:	89 d7                	mov    %edx,%edi
f01038ee:	8b 45 08             	mov    0x8(%ebp),%eax
f01038f1:	89 45 dc             	mov    %eax,-0x24(%ebp)
f01038f4:	8b 45 0c             	mov    0xc(%ebp),%eax
f01038f7:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01038fa:	8b 5d 14             	mov    0x14(%ebp),%ebx
f01038fd:	8b 75 18             	mov    0x18(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0103900:	b8 00 00 00 00       	mov    $0x0,%eax
f0103905:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0103908:	72 11                	jb     f010391b <printnum+0x3b>
f010390a:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010390d:	39 45 10             	cmp    %eax,0x10(%ebp)
f0103910:	76 09                	jbe    f010391b <printnum+0x3b>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0103912:	83 eb 01             	sub    $0x1,%ebx
f0103915:	85 db                	test   %ebx,%ebx
f0103917:	7f 51                	jg     f010396a <printnum+0x8a>
f0103919:	eb 5e                	jmp    f0103979 <printnum+0x99>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
f010391b:	89 74 24 10          	mov    %esi,0x10(%esp)
f010391f:	83 eb 01             	sub    $0x1,%ebx
f0103922:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0103926:	8b 45 10             	mov    0x10(%ebp),%eax
f0103929:	89 44 24 08          	mov    %eax,0x8(%esp)
f010392d:	8b 5c 24 08          	mov    0x8(%esp),%ebx
f0103931:	8b 74 24 0c          	mov    0xc(%esp),%esi
f0103935:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f010393c:	00 
f010393d:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103940:	89 04 24             	mov    %eax,(%esp)
f0103943:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103946:	89 44 24 04          	mov    %eax,0x4(%esp)
f010394a:	e8 41 0a 00 00       	call   f0104390 <__udivdi3>
f010394f:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0103953:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0103957:	89 04 24             	mov    %eax,(%esp)
f010395a:	89 54 24 04          	mov    %edx,0x4(%esp)
f010395e:	89 fa                	mov    %edi,%edx
f0103960:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103963:	e8 78 ff ff ff       	call   f01038e0 <printnum>
f0103968:	eb 0f                	jmp    f0103979 <printnum+0x99>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f010396a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010396e:	89 34 24             	mov    %esi,(%esp)
f0103971:	ff 55 e4             	call   *-0x1c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0103974:	83 eb 01             	sub    $0x1,%ebx
f0103977:	75 f1                	jne    f010396a <printnum+0x8a>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0103979:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010397d:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0103981:	8b 45 10             	mov    0x10(%ebp),%eax
f0103984:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103988:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f010398f:	00 
f0103990:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103993:	89 04 24             	mov    %eax,(%esp)
f0103996:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103999:	89 44 24 04          	mov    %eax,0x4(%esp)
f010399d:	e8 1e 0b 00 00       	call   f01044c0 <__umoddi3>
f01039a2:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01039a6:	0f be 80 e7 58 10 f0 	movsbl -0xfefa719(%eax),%eax
f01039ad:	89 04 24             	mov    %eax,(%esp)
f01039b0:	ff 55 e4             	call   *-0x1c(%ebp)
}
f01039b3:	83 c4 3c             	add    $0x3c,%esp
f01039b6:	5b                   	pop    %ebx
f01039b7:	5e                   	pop    %esi
f01039b8:	5f                   	pop    %edi
f01039b9:	5d                   	pop    %ebp
f01039ba:	c3                   	ret    

f01039bb <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f01039bb:	55                   	push   %ebp
f01039bc:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f01039be:	83 fa 01             	cmp    $0x1,%edx
f01039c1:	7e 0e                	jle    f01039d1 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f01039c3:	8b 10                	mov    (%eax),%edx
f01039c5:	8d 4a 08             	lea    0x8(%edx),%ecx
f01039c8:	89 08                	mov    %ecx,(%eax)
f01039ca:	8b 02                	mov    (%edx),%eax
f01039cc:	8b 52 04             	mov    0x4(%edx),%edx
f01039cf:	eb 22                	jmp    f01039f3 <getuint+0x38>
	else if (lflag)
f01039d1:	85 d2                	test   %edx,%edx
f01039d3:	74 10                	je     f01039e5 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f01039d5:	8b 10                	mov    (%eax),%edx
f01039d7:	8d 4a 04             	lea    0x4(%edx),%ecx
f01039da:	89 08                	mov    %ecx,(%eax)
f01039dc:	8b 02                	mov    (%edx),%eax
f01039de:	ba 00 00 00 00       	mov    $0x0,%edx
f01039e3:	eb 0e                	jmp    f01039f3 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f01039e5:	8b 10                	mov    (%eax),%edx
f01039e7:	8d 4a 04             	lea    0x4(%edx),%ecx
f01039ea:	89 08                	mov    %ecx,(%eax)
f01039ec:	8b 02                	mov    (%edx),%eax
f01039ee:	ba 00 00 00 00       	mov    $0x0,%edx
}
f01039f3:	5d                   	pop    %ebp
f01039f4:	c3                   	ret    

f01039f5 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f01039f5:	55                   	push   %ebp
f01039f6:	89 e5                	mov    %esp,%ebp
f01039f8:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f01039fb:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f01039ff:	8b 10                	mov    (%eax),%edx
f0103a01:	3b 50 04             	cmp    0x4(%eax),%edx
f0103a04:	73 0a                	jae    f0103a10 <sprintputch+0x1b>
		*b->buf++ = ch;
f0103a06:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103a09:	88 0a                	mov    %cl,(%edx)
f0103a0b:	83 c2 01             	add    $0x1,%edx
f0103a0e:	89 10                	mov    %edx,(%eax)
}
f0103a10:	5d                   	pop    %ebp
f0103a11:	c3                   	ret    

f0103a12 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0103a12:	55                   	push   %ebp
f0103a13:	89 e5                	mov    %esp,%ebp
f0103a15:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f0103a18:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0103a1b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103a1f:	8b 45 10             	mov    0x10(%ebp),%eax
f0103a22:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103a26:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103a29:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103a2d:	8b 45 08             	mov    0x8(%ebp),%eax
f0103a30:	89 04 24             	mov    %eax,(%esp)
f0103a33:	e8 02 00 00 00       	call   f0103a3a <vprintfmt>
	va_end(ap);
}
f0103a38:	c9                   	leave  
f0103a39:	c3                   	ret    

f0103a3a <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0103a3a:	55                   	push   %ebp
f0103a3b:	89 e5                	mov    %esp,%ebp
f0103a3d:	57                   	push   %edi
f0103a3e:	56                   	push   %esi
f0103a3f:	53                   	push   %ebx
f0103a40:	83 ec 4c             	sub    $0x4c,%esp
f0103a43:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103a46:	8b 75 10             	mov    0x10(%ebp),%esi
f0103a49:	eb 12                	jmp    f0103a5d <vprintfmt+0x23>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0103a4b:	85 c0                	test   %eax,%eax
f0103a4d:	0f 84 a9 03 00 00    	je     f0103dfc <vprintfmt+0x3c2>
				return;
			putch(ch, putdat);
f0103a53:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103a57:	89 04 24             	mov    %eax,(%esp)
f0103a5a:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0103a5d:	0f b6 06             	movzbl (%esi),%eax
f0103a60:	83 c6 01             	add    $0x1,%esi
f0103a63:	83 f8 25             	cmp    $0x25,%eax
f0103a66:	75 e3                	jne    f0103a4b <vprintfmt+0x11>
f0103a68:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
f0103a6c:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
f0103a73:	bf ff ff ff ff       	mov    $0xffffffff,%edi
f0103a78:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
f0103a7f:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103a84:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0103a87:	eb 2b                	jmp    f0103ab4 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103a89:	8b 75 e0             	mov    -0x20(%ebp),%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f0103a8c:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
f0103a90:	eb 22                	jmp    f0103ab4 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103a92:	8b 75 e0             	mov    -0x20(%ebp),%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0103a95:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
f0103a99:	eb 19                	jmp    f0103ab4 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103a9b:	8b 75 e0             	mov    -0x20(%ebp),%esi
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
f0103a9e:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f0103aa5:	eb 0d                	jmp    f0103ab4 <vprintfmt+0x7a>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f0103aa7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103aaa:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103aad:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103ab4:	0f b6 06             	movzbl (%esi),%eax
f0103ab7:	0f b6 d0             	movzbl %al,%edx
f0103aba:	8d 7e 01             	lea    0x1(%esi),%edi
f0103abd:	89 7d e0             	mov    %edi,-0x20(%ebp)
f0103ac0:	83 e8 23             	sub    $0x23,%eax
f0103ac3:	3c 55                	cmp    $0x55,%al
f0103ac5:	0f 87 0b 03 00 00    	ja     f0103dd6 <vprintfmt+0x39c>
f0103acb:	0f b6 c0             	movzbl %al,%eax
f0103ace:	ff 24 85 64 59 10 f0 	jmp    *-0xfefa69c(,%eax,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0103ad5:	83 ea 30             	sub    $0x30,%edx
f0103ad8:	89 55 d4             	mov    %edx,-0x2c(%ebp)
				ch = *fmt;
f0103adb:	0f be 46 01          	movsbl 0x1(%esi),%eax
				if (ch < '0' || ch > '9')
f0103adf:	8d 50 d0             	lea    -0x30(%eax),%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103ae2:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
f0103ae5:	83 fa 09             	cmp    $0x9,%edx
f0103ae8:	77 4a                	ja     f0103b34 <vprintfmt+0xfa>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103aea:	8b 7d d4             	mov    -0x2c(%ebp),%edi
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0103aed:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
f0103af0:	8d 14 bf             	lea    (%edi,%edi,4),%edx
f0103af3:	8d 7c 50 d0          	lea    -0x30(%eax,%edx,2),%edi
				ch = *fmt;
f0103af7:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f0103afa:	8d 50 d0             	lea    -0x30(%eax),%edx
f0103afd:	83 fa 09             	cmp    $0x9,%edx
f0103b00:	76 eb                	jbe    f0103aed <vprintfmt+0xb3>
f0103b02:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0103b05:	eb 2d                	jmp    f0103b34 <vprintfmt+0xfa>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0103b07:	8b 45 14             	mov    0x14(%ebp),%eax
f0103b0a:	8d 50 04             	lea    0x4(%eax),%edx
f0103b0d:	89 55 14             	mov    %edx,0x14(%ebp)
f0103b10:	8b 00                	mov    (%eax),%eax
f0103b12:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103b15:	8b 75 e0             	mov    -0x20(%ebp),%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0103b18:	eb 1a                	jmp    f0103b34 <vprintfmt+0xfa>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103b1a:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case '*':
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
f0103b1d:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0103b21:	79 91                	jns    f0103ab4 <vprintfmt+0x7a>
f0103b23:	e9 73 ff ff ff       	jmp    f0103a9b <vprintfmt+0x61>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103b28:	8b 75 e0             	mov    -0x20(%ebp),%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0103b2b:	c7 45 dc 01 00 00 00 	movl   $0x1,-0x24(%ebp)
			goto reswitch;
f0103b32:	eb 80                	jmp    f0103ab4 <vprintfmt+0x7a>

		process_precision:
			if (width < 0)
f0103b34:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0103b38:	0f 89 76 ff ff ff    	jns    f0103ab4 <vprintfmt+0x7a>
f0103b3e:	e9 64 ff ff ff       	jmp    f0103aa7 <vprintfmt+0x6d>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0103b43:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103b46:	8b 75 e0             	mov    -0x20(%ebp),%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0103b49:	e9 66 ff ff ff       	jmp    f0103ab4 <vprintfmt+0x7a>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0103b4e:	8b 45 14             	mov    0x14(%ebp),%eax
f0103b51:	8d 50 04             	lea    0x4(%eax),%edx
f0103b54:	89 55 14             	mov    %edx,0x14(%ebp)
f0103b57:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103b5b:	8b 00                	mov    (%eax),%eax
f0103b5d:	89 04 24             	mov    %eax,(%esp)
f0103b60:	ff 55 08             	call   *0x8(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103b63:	8b 75 e0             	mov    -0x20(%ebp),%esi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0103b66:	e9 f2 fe ff ff       	jmp    f0103a5d <vprintfmt+0x23>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0103b6b:	8b 45 14             	mov    0x14(%ebp),%eax
f0103b6e:	8d 50 04             	lea    0x4(%eax),%edx
f0103b71:	89 55 14             	mov    %edx,0x14(%ebp)
f0103b74:	8b 00                	mov    (%eax),%eax
f0103b76:	89 c2                	mov    %eax,%edx
f0103b78:	c1 fa 1f             	sar    $0x1f,%edx
f0103b7b:	31 d0                	xor    %edx,%eax
f0103b7d:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0103b7f:	83 f8 06             	cmp    $0x6,%eax
f0103b82:	7f 0b                	jg     f0103b8f <vprintfmt+0x155>
f0103b84:	8b 14 85 bc 5a 10 f0 	mov    -0xfefa544(,%eax,4),%edx
f0103b8b:	85 d2                	test   %edx,%edx
f0103b8d:	75 23                	jne    f0103bb2 <vprintfmt+0x178>
				printfmt(putch, putdat, "error %d", err);
f0103b8f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103b93:	c7 44 24 08 ff 58 10 	movl   $0xf01058ff,0x8(%esp)
f0103b9a:	f0 
f0103b9b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103b9f:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103ba2:	89 3c 24             	mov    %edi,(%esp)
f0103ba5:	e8 68 fe ff ff       	call   f0103a12 <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103baa:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0103bad:	e9 ab fe ff ff       	jmp    f0103a5d <vprintfmt+0x23>
			else
				printfmt(putch, putdat, "%s", p);
f0103bb2:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103bb6:	c7 44 24 08 30 56 10 	movl   $0xf0105630,0x8(%esp)
f0103bbd:	f0 
f0103bbe:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103bc2:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103bc5:	89 3c 24             	mov    %edi,(%esp)
f0103bc8:	e8 45 fe ff ff       	call   f0103a12 <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103bcd:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0103bd0:	e9 88 fe ff ff       	jmp    f0103a5d <vprintfmt+0x23>
f0103bd5:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0103bd8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103bdb:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0103bde:	8b 45 14             	mov    0x14(%ebp),%eax
f0103be1:	8d 50 04             	lea    0x4(%eax),%edx
f0103be4:	89 55 14             	mov    %edx,0x14(%ebp)
f0103be7:	8b 30                	mov    (%eax),%esi
				p = "(null)";
f0103be9:	85 f6                	test   %esi,%esi
f0103beb:	ba f8 58 10 f0       	mov    $0xf01058f8,%edx
f0103bf0:	0f 44 f2             	cmove  %edx,%esi
			if (width > 0 && padc != '-')
f0103bf3:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f0103bf7:	7e 06                	jle    f0103bff <vprintfmt+0x1c5>
f0103bf9:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
f0103bfd:	75 10                	jne    f0103c0f <vprintfmt+0x1d5>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0103bff:	0f be 06             	movsbl (%esi),%eax
f0103c02:	83 c6 01             	add    $0x1,%esi
f0103c05:	85 c0                	test   %eax,%eax
f0103c07:	0f 85 86 00 00 00    	jne    f0103c93 <vprintfmt+0x259>
f0103c0d:	eb 76                	jmp    f0103c85 <vprintfmt+0x24b>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0103c0f:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103c13:	89 34 24             	mov    %esi,(%esp)
f0103c16:	e8 60 03 00 00       	call   f0103f7b <strnlen>
f0103c1b:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0103c1e:	29 c2                	sub    %eax,%edx
f0103c20:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0103c23:	85 d2                	test   %edx,%edx
f0103c25:	7e d8                	jle    f0103bff <vprintfmt+0x1c5>
					putch(padc, putdat);
f0103c27:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
f0103c2b:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f0103c2e:	89 d6                	mov    %edx,%esi
f0103c30:	89 7d d0             	mov    %edi,-0x30(%ebp)
f0103c33:	89 c7                	mov    %eax,%edi
f0103c35:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103c39:	89 3c 24             	mov    %edi,(%esp)
f0103c3c:	ff 55 08             	call   *0x8(%ebp)
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0103c3f:	83 ee 01             	sub    $0x1,%esi
f0103c42:	75 f1                	jne    f0103c35 <vprintfmt+0x1fb>
f0103c44:	89 75 e4             	mov    %esi,-0x1c(%ebp)
f0103c47:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f0103c4a:	8b 7d d0             	mov    -0x30(%ebp),%edi
f0103c4d:	eb b0                	jmp    f0103bff <vprintfmt+0x1c5>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0103c4f:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0103c53:	74 18                	je     f0103c6d <vprintfmt+0x233>
f0103c55:	8d 50 e0             	lea    -0x20(%eax),%edx
f0103c58:	83 fa 5e             	cmp    $0x5e,%edx
f0103c5b:	76 10                	jbe    f0103c6d <vprintfmt+0x233>
					putch('?', putdat);
f0103c5d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103c61:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0103c68:	ff 55 08             	call   *0x8(%ebp)
f0103c6b:	eb 0a                	jmp    f0103c77 <vprintfmt+0x23d>
				else
					putch(ch, putdat);
f0103c6d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103c71:	89 04 24             	mov    %eax,(%esp)
f0103c74:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0103c77:	83 6d e4 01          	subl   $0x1,-0x1c(%ebp)
f0103c7b:	0f be 06             	movsbl (%esi),%eax
f0103c7e:	83 c6 01             	add    $0x1,%esi
f0103c81:	85 c0                	test   %eax,%eax
f0103c83:	75 0e                	jne    f0103c93 <vprintfmt+0x259>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103c85:	8b 75 e0             	mov    -0x20(%ebp),%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0103c88:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0103c8c:	7f 16                	jg     f0103ca4 <vprintfmt+0x26a>
f0103c8e:	e9 ca fd ff ff       	jmp    f0103a5d <vprintfmt+0x23>
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0103c93:	85 ff                	test   %edi,%edi
f0103c95:	78 b8                	js     f0103c4f <vprintfmt+0x215>
f0103c97:	83 ef 01             	sub    $0x1,%edi
f0103c9a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103ca0:	79 ad                	jns    f0103c4f <vprintfmt+0x215>
f0103ca2:	eb e1                	jmp    f0103c85 <vprintfmt+0x24b>
f0103ca4:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103ca7:	8b 7d 08             	mov    0x8(%ebp),%edi
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0103caa:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103cae:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0103cb5:	ff d7                	call   *%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0103cb7:	83 ee 01             	sub    $0x1,%esi
f0103cba:	75 ee                	jne    f0103caa <vprintfmt+0x270>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103cbc:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0103cbf:	e9 99 fd ff ff       	jmp    f0103a5d <vprintfmt+0x23>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0103cc4:	83 f9 01             	cmp    $0x1,%ecx
f0103cc7:	7e 10                	jle    f0103cd9 <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f0103cc9:	8b 45 14             	mov    0x14(%ebp),%eax
f0103ccc:	8d 50 08             	lea    0x8(%eax),%edx
f0103ccf:	89 55 14             	mov    %edx,0x14(%ebp)
f0103cd2:	8b 30                	mov    (%eax),%esi
f0103cd4:	8b 78 04             	mov    0x4(%eax),%edi
f0103cd7:	eb 26                	jmp    f0103cff <vprintfmt+0x2c5>
	else if (lflag)
f0103cd9:	85 c9                	test   %ecx,%ecx
f0103cdb:	74 12                	je     f0103cef <vprintfmt+0x2b5>
		return va_arg(*ap, long);
f0103cdd:	8b 45 14             	mov    0x14(%ebp),%eax
f0103ce0:	8d 50 04             	lea    0x4(%eax),%edx
f0103ce3:	89 55 14             	mov    %edx,0x14(%ebp)
f0103ce6:	8b 30                	mov    (%eax),%esi
f0103ce8:	89 f7                	mov    %esi,%edi
f0103cea:	c1 ff 1f             	sar    $0x1f,%edi
f0103ced:	eb 10                	jmp    f0103cff <vprintfmt+0x2c5>
	else
		return va_arg(*ap, int);
f0103cef:	8b 45 14             	mov    0x14(%ebp),%eax
f0103cf2:	8d 50 04             	lea    0x4(%eax),%edx
f0103cf5:	89 55 14             	mov    %edx,0x14(%ebp)
f0103cf8:	8b 30                	mov    (%eax),%esi
f0103cfa:	89 f7                	mov    %esi,%edi
f0103cfc:	c1 ff 1f             	sar    $0x1f,%edi
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0103cff:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0103d04:	85 ff                	test   %edi,%edi
f0103d06:	0f 89 8c 00 00 00    	jns    f0103d98 <vprintfmt+0x35e>
				putch('-', putdat);
f0103d0c:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103d10:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f0103d17:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f0103d1a:	f7 de                	neg    %esi
f0103d1c:	83 d7 00             	adc    $0x0,%edi
f0103d1f:	f7 df                	neg    %edi
			}
			base = 10;
f0103d21:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103d26:	eb 70                	jmp    f0103d98 <vprintfmt+0x35e>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0103d28:	89 ca                	mov    %ecx,%edx
f0103d2a:	8d 45 14             	lea    0x14(%ebp),%eax
f0103d2d:	e8 89 fc ff ff       	call   f01039bb <getuint>
f0103d32:	89 c6                	mov    %eax,%esi
f0103d34:	89 d7                	mov    %edx,%edi
			base = 10;
f0103d36:	b8 0a 00 00 00       	mov    $0xa,%eax
			goto number;
f0103d3b:	eb 5b                	jmp    f0103d98 <vprintfmt+0x35e>
			// Replace this with your code.
			//putch('0', putdat);
			//putch('X', putdat);
			//putch('X', putdat);
			//break;
			num = getuint(&ap, lflag);
f0103d3d:	89 ca                	mov    %ecx,%edx
f0103d3f:	8d 45 14             	lea    0x14(%ebp),%eax
f0103d42:	e8 74 fc ff ff       	call   f01039bb <getuint>
f0103d47:	89 c6                	mov    %eax,%esi
f0103d49:	89 d7                	mov    %edx,%edi
			base = 8;
f0103d4b:	b8 08 00 00 00       	mov    $0x8,%eax
			goto number;
f0103d50:	eb 46                	jmp    f0103d98 <vprintfmt+0x35e>
		// pointer
		case 'p':
			putch('0', putdat);
f0103d52:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103d56:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f0103d5d:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f0103d60:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103d64:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f0103d6b:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0103d6e:	8b 45 14             	mov    0x14(%ebp),%eax
f0103d71:	8d 50 04             	lea    0x4(%eax),%edx
f0103d74:	89 55 14             	mov    %edx,0x14(%ebp)
			goto number;
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0103d77:	8b 30                	mov    (%eax),%esi
f0103d79:	bf 00 00 00 00       	mov    $0x0,%edi
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0103d7e:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f0103d83:	eb 13                	jmp    f0103d98 <vprintfmt+0x35e>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0103d85:	89 ca                	mov    %ecx,%edx
f0103d87:	8d 45 14             	lea    0x14(%ebp),%eax
f0103d8a:	e8 2c fc ff ff       	call   f01039bb <getuint>
f0103d8f:	89 c6                	mov    %eax,%esi
f0103d91:	89 d7                	mov    %edx,%edi
			base = 16;
f0103d93:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f0103d98:	0f be 55 d8          	movsbl -0x28(%ebp),%edx
f0103d9c:	89 54 24 10          	mov    %edx,0x10(%esp)
f0103da0:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0103da3:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103da7:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103dab:	89 34 24             	mov    %esi,(%esp)
f0103dae:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103db2:	89 da                	mov    %ebx,%edx
f0103db4:	8b 45 08             	mov    0x8(%ebp),%eax
f0103db7:	e8 24 fb ff ff       	call   f01038e0 <printnum>
			break;
f0103dbc:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0103dbf:	e9 99 fc ff ff       	jmp    f0103a5d <vprintfmt+0x23>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0103dc4:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103dc8:	89 14 24             	mov    %edx,(%esp)
f0103dcb:	ff 55 08             	call   *0x8(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103dce:	8b 75 e0             	mov    -0x20(%ebp),%esi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0103dd1:	e9 87 fc ff ff       	jmp    f0103a5d <vprintfmt+0x23>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0103dd6:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103dda:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0103de1:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0103de4:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
f0103de8:	0f 84 6f fc ff ff    	je     f0103a5d <vprintfmt+0x23>
f0103dee:	83 ee 01             	sub    $0x1,%esi
f0103df1:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
f0103df5:	75 f7                	jne    f0103dee <vprintfmt+0x3b4>
f0103df7:	e9 61 fc ff ff       	jmp    f0103a5d <vprintfmt+0x23>
				/* do nothing */;
			break;
		}
	}
}
f0103dfc:	83 c4 4c             	add    $0x4c,%esp
f0103dff:	5b                   	pop    %ebx
f0103e00:	5e                   	pop    %esi
f0103e01:	5f                   	pop    %edi
f0103e02:	5d                   	pop    %ebp
f0103e03:	c3                   	ret    

f0103e04 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0103e04:	55                   	push   %ebp
f0103e05:	89 e5                	mov    %esp,%ebp
f0103e07:	83 ec 28             	sub    $0x28,%esp
f0103e0a:	8b 45 08             	mov    0x8(%ebp),%eax
f0103e0d:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0103e10:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103e13:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0103e17:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0103e1a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0103e21:	85 c0                	test   %eax,%eax
f0103e23:	74 30                	je     f0103e55 <vsnprintf+0x51>
f0103e25:	85 d2                	test   %edx,%edx
f0103e27:	7e 2c                	jle    f0103e55 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0103e29:	8b 45 14             	mov    0x14(%ebp),%eax
f0103e2c:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103e30:	8b 45 10             	mov    0x10(%ebp),%eax
f0103e33:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103e37:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0103e3a:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103e3e:	c7 04 24 f5 39 10 f0 	movl   $0xf01039f5,(%esp)
f0103e45:	e8 f0 fb ff ff       	call   f0103a3a <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0103e4a:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0103e4d:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0103e50:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103e53:	eb 05                	jmp    f0103e5a <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0103e55:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0103e5a:	c9                   	leave  
f0103e5b:	c3                   	ret    

f0103e5c <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0103e5c:	55                   	push   %ebp
f0103e5d:	89 e5                	mov    %esp,%ebp
f0103e5f:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0103e62:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0103e65:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103e69:	8b 45 10             	mov    0x10(%ebp),%eax
f0103e6c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103e70:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103e73:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103e77:	8b 45 08             	mov    0x8(%ebp),%eax
f0103e7a:	89 04 24             	mov    %eax,(%esp)
f0103e7d:	e8 82 ff ff ff       	call   f0103e04 <vsnprintf>
	va_end(ap);

	return rc;
}
f0103e82:	c9                   	leave  
f0103e83:	c3                   	ret    
	...

f0103e90 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0103e90:	55                   	push   %ebp
f0103e91:	89 e5                	mov    %esp,%ebp
f0103e93:	57                   	push   %edi
f0103e94:	56                   	push   %esi
f0103e95:	53                   	push   %ebx
f0103e96:	83 ec 1c             	sub    $0x1c,%esp
f0103e99:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0103e9c:	85 c0                	test   %eax,%eax
f0103e9e:	74 10                	je     f0103eb0 <readline+0x20>
		cprintf("%s", prompt);
f0103ea0:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103ea4:	c7 04 24 30 56 10 f0 	movl   $0xf0105630,(%esp)
f0103eab:	e8 d6 f6 ff ff       	call   f0103586 <cprintf>

	i = 0;
	echoing = iscons(0);
f0103eb0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0103eb7:	e8 5e c7 ff ff       	call   f010061a <iscons>
f0103ebc:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0103ebe:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0103ec3:	e8 41 c7 ff ff       	call   f0100609 <getchar>
f0103ec8:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0103eca:	85 c0                	test   %eax,%eax
f0103ecc:	79 17                	jns    f0103ee5 <readline+0x55>
			cprintf("read error: %e\n", c);
f0103ece:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103ed2:	c7 04 24 d8 5a 10 f0 	movl   $0xf0105ad8,(%esp)
f0103ed9:	e8 a8 f6 ff ff       	call   f0103586 <cprintf>
			return NULL;
f0103ede:	b8 00 00 00 00       	mov    $0x0,%eax
f0103ee3:	eb 6d                	jmp    f0103f52 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0103ee5:	83 f8 08             	cmp    $0x8,%eax
f0103ee8:	74 05                	je     f0103eef <readline+0x5f>
f0103eea:	83 f8 7f             	cmp    $0x7f,%eax
f0103eed:	75 19                	jne    f0103f08 <readline+0x78>
f0103eef:	85 f6                	test   %esi,%esi
f0103ef1:	7e 15                	jle    f0103f08 <readline+0x78>
			if (echoing)
f0103ef3:	85 ff                	test   %edi,%edi
f0103ef5:	74 0c                	je     f0103f03 <readline+0x73>
				cputchar('\b');
f0103ef7:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f0103efe:	e8 f6 c6 ff ff       	call   f01005f9 <cputchar>
			i--;
f0103f03:	83 ee 01             	sub    $0x1,%esi
f0103f06:	eb bb                	jmp    f0103ec3 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0103f08:	83 fb 1f             	cmp    $0x1f,%ebx
f0103f0b:	7e 1f                	jle    f0103f2c <readline+0x9c>
f0103f0d:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0103f13:	7f 17                	jg     f0103f2c <readline+0x9c>
			if (echoing)
f0103f15:	85 ff                	test   %edi,%edi
f0103f17:	74 08                	je     f0103f21 <readline+0x91>
				cputchar(c);
f0103f19:	89 1c 24             	mov    %ebx,(%esp)
f0103f1c:	e8 d8 c6 ff ff       	call   f01005f9 <cputchar>
			buf[i++] = c;
f0103f21:	88 9e 80 95 11 f0    	mov    %bl,-0xfee6a80(%esi)
f0103f27:	83 c6 01             	add    $0x1,%esi
f0103f2a:	eb 97                	jmp    f0103ec3 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f0103f2c:	83 fb 0a             	cmp    $0xa,%ebx
f0103f2f:	74 05                	je     f0103f36 <readline+0xa6>
f0103f31:	83 fb 0d             	cmp    $0xd,%ebx
f0103f34:	75 8d                	jne    f0103ec3 <readline+0x33>
			if (echoing)
f0103f36:	85 ff                	test   %edi,%edi
f0103f38:	74 0c                	je     f0103f46 <readline+0xb6>
				cputchar('\n');
f0103f3a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0103f41:	e8 b3 c6 ff ff       	call   f01005f9 <cputchar>
			buf[i] = 0;
f0103f46:	c6 86 80 95 11 f0 00 	movb   $0x0,-0xfee6a80(%esi)
			return buf;
f0103f4d:	b8 80 95 11 f0       	mov    $0xf0119580,%eax
		}
	}
}
f0103f52:	83 c4 1c             	add    $0x1c,%esp
f0103f55:	5b                   	pop    %ebx
f0103f56:	5e                   	pop    %esi
f0103f57:	5f                   	pop    %edi
f0103f58:	5d                   	pop    %ebp
f0103f59:	c3                   	ret    
f0103f5a:	00 00                	add    %al,(%eax)
f0103f5c:	00 00                	add    %al,(%eax)
	...

f0103f60 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0103f60:	55                   	push   %ebp
f0103f61:	89 e5                	mov    %esp,%ebp
f0103f63:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0103f66:	b8 00 00 00 00       	mov    $0x0,%eax
f0103f6b:	80 3a 00             	cmpb   $0x0,(%edx)
f0103f6e:	74 09                	je     f0103f79 <strlen+0x19>
		n++;
f0103f70:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0103f73:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0103f77:	75 f7                	jne    f0103f70 <strlen+0x10>
		n++;
	return n;
}
f0103f79:	5d                   	pop    %ebp
f0103f7a:	c3                   	ret    

f0103f7b <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0103f7b:	55                   	push   %ebp
f0103f7c:	89 e5                	mov    %esp,%ebp
f0103f7e:	53                   	push   %ebx
f0103f7f:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103f82:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103f85:	b8 00 00 00 00       	mov    $0x0,%eax
f0103f8a:	85 c9                	test   %ecx,%ecx
f0103f8c:	74 1a                	je     f0103fa8 <strnlen+0x2d>
f0103f8e:	80 3b 00             	cmpb   $0x0,(%ebx)
f0103f91:	74 15                	je     f0103fa8 <strnlen+0x2d>
f0103f93:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
f0103f98:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103f9a:	39 ca                	cmp    %ecx,%edx
f0103f9c:	74 0a                	je     f0103fa8 <strnlen+0x2d>
f0103f9e:	83 c2 01             	add    $0x1,%edx
f0103fa1:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
f0103fa6:	75 f0                	jne    f0103f98 <strnlen+0x1d>
		n++;
	return n;
}
f0103fa8:	5b                   	pop    %ebx
f0103fa9:	5d                   	pop    %ebp
f0103faa:	c3                   	ret    

f0103fab <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0103fab:	55                   	push   %ebp
f0103fac:	89 e5                	mov    %esp,%ebp
f0103fae:	53                   	push   %ebx
f0103faf:	8b 45 08             	mov    0x8(%ebp),%eax
f0103fb2:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0103fb5:	ba 00 00 00 00       	mov    $0x0,%edx
f0103fba:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f0103fbe:	88 0c 10             	mov    %cl,(%eax,%edx,1)
f0103fc1:	83 c2 01             	add    $0x1,%edx
f0103fc4:	84 c9                	test   %cl,%cl
f0103fc6:	75 f2                	jne    f0103fba <strcpy+0xf>
		/* do nothing */;
	return ret;
}
f0103fc8:	5b                   	pop    %ebx
f0103fc9:	5d                   	pop    %ebp
f0103fca:	c3                   	ret    

f0103fcb <strcat>:

char *
strcat(char *dst, const char *src)
{
f0103fcb:	55                   	push   %ebp
f0103fcc:	89 e5                	mov    %esp,%ebp
f0103fce:	53                   	push   %ebx
f0103fcf:	83 ec 08             	sub    $0x8,%esp
f0103fd2:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0103fd5:	89 1c 24             	mov    %ebx,(%esp)
f0103fd8:	e8 83 ff ff ff       	call   f0103f60 <strlen>
	strcpy(dst + len, src);
f0103fdd:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103fe0:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103fe4:	01 d8                	add    %ebx,%eax
f0103fe6:	89 04 24             	mov    %eax,(%esp)
f0103fe9:	e8 bd ff ff ff       	call   f0103fab <strcpy>
	return dst;
}
f0103fee:	89 d8                	mov    %ebx,%eax
f0103ff0:	83 c4 08             	add    $0x8,%esp
f0103ff3:	5b                   	pop    %ebx
f0103ff4:	5d                   	pop    %ebp
f0103ff5:	c3                   	ret    

f0103ff6 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0103ff6:	55                   	push   %ebp
f0103ff7:	89 e5                	mov    %esp,%ebp
f0103ff9:	56                   	push   %esi
f0103ffa:	53                   	push   %ebx
f0103ffb:	8b 45 08             	mov    0x8(%ebp),%eax
f0103ffe:	8b 55 0c             	mov    0xc(%ebp),%edx
f0104001:	8b 75 10             	mov    0x10(%ebp),%esi
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104004:	85 f6                	test   %esi,%esi
f0104006:	74 18                	je     f0104020 <strncpy+0x2a>
f0104008:	b9 00 00 00 00       	mov    $0x0,%ecx
		*dst++ = *src;
f010400d:	0f b6 1a             	movzbl (%edx),%ebx
f0104010:	88 1c 08             	mov    %bl,(%eax,%ecx,1)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0104013:	80 3a 01             	cmpb   $0x1,(%edx)
f0104016:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104019:	83 c1 01             	add    $0x1,%ecx
f010401c:	39 f1                	cmp    %esi,%ecx
f010401e:	75 ed                	jne    f010400d <strncpy+0x17>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0104020:	5b                   	pop    %ebx
f0104021:	5e                   	pop    %esi
f0104022:	5d                   	pop    %ebp
f0104023:	c3                   	ret    

f0104024 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0104024:	55                   	push   %ebp
f0104025:	89 e5                	mov    %esp,%ebp
f0104027:	57                   	push   %edi
f0104028:	56                   	push   %esi
f0104029:	53                   	push   %ebx
f010402a:	8b 7d 08             	mov    0x8(%ebp),%edi
f010402d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104030:	8b 75 10             	mov    0x10(%ebp),%esi
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0104033:	89 f8                	mov    %edi,%eax
f0104035:	85 f6                	test   %esi,%esi
f0104037:	74 2b                	je     f0104064 <strlcpy+0x40>
		while (--size > 0 && *src != '\0')
f0104039:	83 fe 01             	cmp    $0x1,%esi
f010403c:	74 23                	je     f0104061 <strlcpy+0x3d>
f010403e:	0f b6 0b             	movzbl (%ebx),%ecx
f0104041:	84 c9                	test   %cl,%cl
f0104043:	74 1c                	je     f0104061 <strlcpy+0x3d>
	}
	return ret;
}

size_t
strlcpy(char *dst, const char *src, size_t size)
f0104045:	83 ee 02             	sub    $0x2,%esi
f0104048:	ba 00 00 00 00       	mov    $0x0,%edx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f010404d:	88 08                	mov    %cl,(%eax)
f010404f:	83 c0 01             	add    $0x1,%eax
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0104052:	39 f2                	cmp    %esi,%edx
f0104054:	74 0b                	je     f0104061 <strlcpy+0x3d>
f0104056:	83 c2 01             	add    $0x1,%edx
f0104059:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f010405d:	84 c9                	test   %cl,%cl
f010405f:	75 ec                	jne    f010404d <strlcpy+0x29>
			*dst++ = *src++;
		*dst = '\0';
f0104061:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0104064:	29 f8                	sub    %edi,%eax
}
f0104066:	5b                   	pop    %ebx
f0104067:	5e                   	pop    %esi
f0104068:	5f                   	pop    %edi
f0104069:	5d                   	pop    %ebp
f010406a:	c3                   	ret    

f010406b <strcmp>:

int
strcmp(const char *p, const char *q)
{
f010406b:	55                   	push   %ebp
f010406c:	89 e5                	mov    %esp,%ebp
f010406e:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104071:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0104074:	0f b6 01             	movzbl (%ecx),%eax
f0104077:	84 c0                	test   %al,%al
f0104079:	74 16                	je     f0104091 <strcmp+0x26>
f010407b:	3a 02                	cmp    (%edx),%al
f010407d:	75 12                	jne    f0104091 <strcmp+0x26>
		p++, q++;
f010407f:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0104082:	0f b6 41 01          	movzbl 0x1(%ecx),%eax
f0104086:	84 c0                	test   %al,%al
f0104088:	74 07                	je     f0104091 <strcmp+0x26>
f010408a:	83 c1 01             	add    $0x1,%ecx
f010408d:	3a 02                	cmp    (%edx),%al
f010408f:	74 ee                	je     f010407f <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0104091:	0f b6 c0             	movzbl %al,%eax
f0104094:	0f b6 12             	movzbl (%edx),%edx
f0104097:	29 d0                	sub    %edx,%eax
}
f0104099:	5d                   	pop    %ebp
f010409a:	c3                   	ret    

f010409b <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f010409b:	55                   	push   %ebp
f010409c:	89 e5                	mov    %esp,%ebp
f010409e:	53                   	push   %ebx
f010409f:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01040a2:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01040a5:	8b 55 10             	mov    0x10(%ebp),%edx
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f01040a8:	b8 00 00 00 00       	mov    $0x0,%eax
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01040ad:	85 d2                	test   %edx,%edx
f01040af:	74 28                	je     f01040d9 <strncmp+0x3e>
f01040b1:	0f b6 01             	movzbl (%ecx),%eax
f01040b4:	84 c0                	test   %al,%al
f01040b6:	74 24                	je     f01040dc <strncmp+0x41>
f01040b8:	3a 03                	cmp    (%ebx),%al
f01040ba:	75 20                	jne    f01040dc <strncmp+0x41>
f01040bc:	83 ea 01             	sub    $0x1,%edx
f01040bf:	74 13                	je     f01040d4 <strncmp+0x39>
		n--, p++, q++;
f01040c1:	83 c1 01             	add    $0x1,%ecx
f01040c4:	83 c3 01             	add    $0x1,%ebx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01040c7:	0f b6 01             	movzbl (%ecx),%eax
f01040ca:	84 c0                	test   %al,%al
f01040cc:	74 0e                	je     f01040dc <strncmp+0x41>
f01040ce:	3a 03                	cmp    (%ebx),%al
f01040d0:	74 ea                	je     f01040bc <strncmp+0x21>
f01040d2:	eb 08                	jmp    f01040dc <strncmp+0x41>
		n--, p++, q++;
	if (n == 0)
		return 0;
f01040d4:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01040d9:	5b                   	pop    %ebx
f01040da:	5d                   	pop    %ebp
f01040db:	c3                   	ret    
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01040dc:	0f b6 01             	movzbl (%ecx),%eax
f01040df:	0f b6 13             	movzbl (%ebx),%edx
f01040e2:	29 d0                	sub    %edx,%eax
f01040e4:	eb f3                	jmp    f01040d9 <strncmp+0x3e>

f01040e6 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01040e6:	55                   	push   %ebp
f01040e7:	89 e5                	mov    %esp,%ebp
f01040e9:	8b 45 08             	mov    0x8(%ebp),%eax
f01040ec:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01040f0:	0f b6 10             	movzbl (%eax),%edx
f01040f3:	84 d2                	test   %dl,%dl
f01040f5:	74 1c                	je     f0104113 <strchr+0x2d>
		if (*s == c)
f01040f7:	38 ca                	cmp    %cl,%dl
f01040f9:	75 09                	jne    f0104104 <strchr+0x1e>
f01040fb:	eb 1b                	jmp    f0104118 <strchr+0x32>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01040fd:	83 c0 01             	add    $0x1,%eax
		if (*s == c)
f0104100:	38 ca                	cmp    %cl,%dl
f0104102:	74 14                	je     f0104118 <strchr+0x32>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0104104:	0f b6 50 01          	movzbl 0x1(%eax),%edx
f0104108:	84 d2                	test   %dl,%dl
f010410a:	75 f1                	jne    f01040fd <strchr+0x17>
		if (*s == c)
			return (char *) s;
	return 0;
f010410c:	b8 00 00 00 00       	mov    $0x0,%eax
f0104111:	eb 05                	jmp    f0104118 <strchr+0x32>
f0104113:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104118:	5d                   	pop    %ebp
f0104119:	c3                   	ret    

f010411a <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010411a:	55                   	push   %ebp
f010411b:	89 e5                	mov    %esp,%ebp
f010411d:	8b 45 08             	mov    0x8(%ebp),%eax
f0104120:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0104124:	0f b6 10             	movzbl (%eax),%edx
f0104127:	84 d2                	test   %dl,%dl
f0104129:	74 14                	je     f010413f <strfind+0x25>
		if (*s == c)
f010412b:	38 ca                	cmp    %cl,%dl
f010412d:	75 06                	jne    f0104135 <strfind+0x1b>
f010412f:	eb 0e                	jmp    f010413f <strfind+0x25>
f0104131:	38 ca                	cmp    %cl,%dl
f0104133:	74 0a                	je     f010413f <strfind+0x25>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f0104135:	83 c0 01             	add    $0x1,%eax
f0104138:	0f b6 10             	movzbl (%eax),%edx
f010413b:	84 d2                	test   %dl,%dl
f010413d:	75 f2                	jne    f0104131 <strfind+0x17>
		if (*s == c)
			break;
	return (char *) s;
}
f010413f:	5d                   	pop    %ebp
f0104140:	c3                   	ret    

f0104141 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0104141:	55                   	push   %ebp
f0104142:	89 e5                	mov    %esp,%ebp
f0104144:	83 ec 0c             	sub    $0xc,%esp
f0104147:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f010414a:	89 75 f8             	mov    %esi,-0x8(%ebp)
f010414d:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0104150:	8b 7d 08             	mov    0x8(%ebp),%edi
f0104153:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104156:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0104159:	85 c9                	test   %ecx,%ecx
f010415b:	74 30                	je     f010418d <memset+0x4c>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f010415d:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0104163:	75 25                	jne    f010418a <memset+0x49>
f0104165:	f6 c1 03             	test   $0x3,%cl
f0104168:	75 20                	jne    f010418a <memset+0x49>
		c &= 0xFF;
f010416a:	0f b6 d0             	movzbl %al,%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f010416d:	89 d3                	mov    %edx,%ebx
f010416f:	c1 e3 08             	shl    $0x8,%ebx
f0104172:	89 d6                	mov    %edx,%esi
f0104174:	c1 e6 18             	shl    $0x18,%esi
f0104177:	89 d0                	mov    %edx,%eax
f0104179:	c1 e0 10             	shl    $0x10,%eax
f010417c:	09 f0                	or     %esi,%eax
f010417e:	09 d0                	or     %edx,%eax
f0104180:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0104182:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f0104185:	fc                   	cld    
f0104186:	f3 ab                	rep stos %eax,%es:(%edi)
f0104188:	eb 03                	jmp    f010418d <memset+0x4c>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f010418a:	fc                   	cld    
f010418b:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f010418d:	89 f8                	mov    %edi,%eax
f010418f:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0104192:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0104195:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0104198:	89 ec                	mov    %ebp,%esp
f010419a:	5d                   	pop    %ebp
f010419b:	c3                   	ret    

f010419c <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f010419c:	55                   	push   %ebp
f010419d:	89 e5                	mov    %esp,%ebp
f010419f:	83 ec 08             	sub    $0x8,%esp
f01041a2:	89 75 f8             	mov    %esi,-0x8(%ebp)
f01041a5:	89 7d fc             	mov    %edi,-0x4(%ebp)
f01041a8:	8b 45 08             	mov    0x8(%ebp),%eax
f01041ab:	8b 75 0c             	mov    0xc(%ebp),%esi
f01041ae:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01041b1:	39 c6                	cmp    %eax,%esi
f01041b3:	73 36                	jae    f01041eb <memmove+0x4f>
f01041b5:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01041b8:	39 d0                	cmp    %edx,%eax
f01041ba:	73 2f                	jae    f01041eb <memmove+0x4f>
		s += n;
		d += n;
f01041bc:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01041bf:	f6 c2 03             	test   $0x3,%dl
f01041c2:	75 1b                	jne    f01041df <memmove+0x43>
f01041c4:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01041ca:	75 13                	jne    f01041df <memmove+0x43>
f01041cc:	f6 c1 03             	test   $0x3,%cl
f01041cf:	75 0e                	jne    f01041df <memmove+0x43>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f01041d1:	83 ef 04             	sub    $0x4,%edi
f01041d4:	8d 72 fc             	lea    -0x4(%edx),%esi
f01041d7:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f01041da:	fd                   	std    
f01041db:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01041dd:	eb 09                	jmp    f01041e8 <memmove+0x4c>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f01041df:	83 ef 01             	sub    $0x1,%edi
f01041e2:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01041e5:	fd                   	std    
f01041e6:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01041e8:	fc                   	cld    
f01041e9:	eb 20                	jmp    f010420b <memmove+0x6f>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01041eb:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01041f1:	75 13                	jne    f0104206 <memmove+0x6a>
f01041f3:	a8 03                	test   $0x3,%al
f01041f5:	75 0f                	jne    f0104206 <memmove+0x6a>
f01041f7:	f6 c1 03             	test   $0x3,%cl
f01041fa:	75 0a                	jne    f0104206 <memmove+0x6a>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f01041fc:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f01041ff:	89 c7                	mov    %eax,%edi
f0104201:	fc                   	cld    
f0104202:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0104204:	eb 05                	jmp    f010420b <memmove+0x6f>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0104206:	89 c7                	mov    %eax,%edi
f0104208:	fc                   	cld    
f0104209:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f010420b:	8b 75 f8             	mov    -0x8(%ebp),%esi
f010420e:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0104211:	89 ec                	mov    %ebp,%esp
f0104213:	5d                   	pop    %ebp
f0104214:	c3                   	ret    

f0104215 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0104215:	55                   	push   %ebp
f0104216:	89 e5                	mov    %esp,%ebp
f0104218:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f010421b:	8b 45 10             	mov    0x10(%ebp),%eax
f010421e:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104222:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104225:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104229:	8b 45 08             	mov    0x8(%ebp),%eax
f010422c:	89 04 24             	mov    %eax,(%esp)
f010422f:	e8 68 ff ff ff       	call   f010419c <memmove>
}
f0104234:	c9                   	leave  
f0104235:	c3                   	ret    

f0104236 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0104236:	55                   	push   %ebp
f0104237:	89 e5                	mov    %esp,%ebp
f0104239:	57                   	push   %edi
f010423a:	56                   	push   %esi
f010423b:	53                   	push   %ebx
f010423c:	8b 5d 08             	mov    0x8(%ebp),%ebx
f010423f:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104242:	8b 7d 10             	mov    0x10(%ebp),%edi
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0104245:	b8 00 00 00 00       	mov    $0x0,%eax
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010424a:	85 ff                	test   %edi,%edi
f010424c:	74 37                	je     f0104285 <memcmp+0x4f>
		if (*s1 != *s2)
f010424e:	0f b6 03             	movzbl (%ebx),%eax
f0104251:	0f b6 0e             	movzbl (%esi),%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0104254:	83 ef 01             	sub    $0x1,%edi
f0104257:	ba 00 00 00 00       	mov    $0x0,%edx
		if (*s1 != *s2)
f010425c:	38 c8                	cmp    %cl,%al
f010425e:	74 1c                	je     f010427c <memcmp+0x46>
f0104260:	eb 10                	jmp    f0104272 <memcmp+0x3c>
f0104262:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
f0104267:	83 c2 01             	add    $0x1,%edx
f010426a:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
f010426e:	38 c8                	cmp    %cl,%al
f0104270:	74 0a                	je     f010427c <memcmp+0x46>
			return (int) *s1 - (int) *s2;
f0104272:	0f b6 c0             	movzbl %al,%eax
f0104275:	0f b6 c9             	movzbl %cl,%ecx
f0104278:	29 c8                	sub    %ecx,%eax
f010427a:	eb 09                	jmp    f0104285 <memcmp+0x4f>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010427c:	39 fa                	cmp    %edi,%edx
f010427e:	75 e2                	jne    f0104262 <memcmp+0x2c>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0104280:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104285:	5b                   	pop    %ebx
f0104286:	5e                   	pop    %esi
f0104287:	5f                   	pop    %edi
f0104288:	5d                   	pop    %ebp
f0104289:	c3                   	ret    

f010428a <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f010428a:	55                   	push   %ebp
f010428b:	89 e5                	mov    %esp,%ebp
f010428d:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0104290:	89 c2                	mov    %eax,%edx
f0104292:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0104295:	39 d0                	cmp    %edx,%eax
f0104297:	73 19                	jae    f01042b2 <memfind+0x28>
		if (*(const unsigned char *) s == (unsigned char) c)
f0104299:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
f010429d:	38 08                	cmp    %cl,(%eax)
f010429f:	75 06                	jne    f01042a7 <memfind+0x1d>
f01042a1:	eb 0f                	jmp    f01042b2 <memfind+0x28>
f01042a3:	38 08                	cmp    %cl,(%eax)
f01042a5:	74 0b                	je     f01042b2 <memfind+0x28>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01042a7:	83 c0 01             	add    $0x1,%eax
f01042aa:	39 d0                	cmp    %edx,%eax
f01042ac:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01042b0:	75 f1                	jne    f01042a3 <memfind+0x19>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01042b2:	5d                   	pop    %ebp
f01042b3:	c3                   	ret    

f01042b4 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01042b4:	55                   	push   %ebp
f01042b5:	89 e5                	mov    %esp,%ebp
f01042b7:	57                   	push   %edi
f01042b8:	56                   	push   %esi
f01042b9:	53                   	push   %ebx
f01042ba:	8b 55 08             	mov    0x8(%ebp),%edx
f01042bd:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01042c0:	0f b6 02             	movzbl (%edx),%eax
f01042c3:	3c 20                	cmp    $0x20,%al
f01042c5:	74 04                	je     f01042cb <strtol+0x17>
f01042c7:	3c 09                	cmp    $0x9,%al
f01042c9:	75 0e                	jne    f01042d9 <strtol+0x25>
		s++;
f01042cb:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01042ce:	0f b6 02             	movzbl (%edx),%eax
f01042d1:	3c 20                	cmp    $0x20,%al
f01042d3:	74 f6                	je     f01042cb <strtol+0x17>
f01042d5:	3c 09                	cmp    $0x9,%al
f01042d7:	74 f2                	je     f01042cb <strtol+0x17>
		s++;

	// plus/minus sign
	if (*s == '+')
f01042d9:	3c 2b                	cmp    $0x2b,%al
f01042db:	75 0a                	jne    f01042e7 <strtol+0x33>
		s++;
f01042dd:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01042e0:	bf 00 00 00 00       	mov    $0x0,%edi
f01042e5:	eb 10                	jmp    f01042f7 <strtol+0x43>
f01042e7:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f01042ec:	3c 2d                	cmp    $0x2d,%al
f01042ee:	75 07                	jne    f01042f7 <strtol+0x43>
		s++, neg = 1;
f01042f0:	83 c2 01             	add    $0x1,%edx
f01042f3:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01042f7:	85 db                	test   %ebx,%ebx
f01042f9:	0f 94 c0             	sete   %al
f01042fc:	74 05                	je     f0104303 <strtol+0x4f>
f01042fe:	83 fb 10             	cmp    $0x10,%ebx
f0104301:	75 15                	jne    f0104318 <strtol+0x64>
f0104303:	80 3a 30             	cmpb   $0x30,(%edx)
f0104306:	75 10                	jne    f0104318 <strtol+0x64>
f0104308:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f010430c:	75 0a                	jne    f0104318 <strtol+0x64>
		s += 2, base = 16;
f010430e:	83 c2 02             	add    $0x2,%edx
f0104311:	bb 10 00 00 00       	mov    $0x10,%ebx
f0104316:	eb 13                	jmp    f010432b <strtol+0x77>
	else if (base == 0 && s[0] == '0')
f0104318:	84 c0                	test   %al,%al
f010431a:	74 0f                	je     f010432b <strtol+0x77>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f010431c:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0104321:	80 3a 30             	cmpb   $0x30,(%edx)
f0104324:	75 05                	jne    f010432b <strtol+0x77>
		s++, base = 8;
f0104326:	83 c2 01             	add    $0x1,%edx
f0104329:	b3 08                	mov    $0x8,%bl
	else if (base == 0)
		base = 10;
f010432b:	b8 00 00 00 00       	mov    $0x0,%eax
f0104330:	89 de                	mov    %ebx,%esi

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0104332:	0f b6 0a             	movzbl (%edx),%ecx
f0104335:	8d 59 d0             	lea    -0x30(%ecx),%ebx
f0104338:	80 fb 09             	cmp    $0x9,%bl
f010433b:	77 08                	ja     f0104345 <strtol+0x91>
			dig = *s - '0';
f010433d:	0f be c9             	movsbl %cl,%ecx
f0104340:	83 e9 30             	sub    $0x30,%ecx
f0104343:	eb 1e                	jmp    f0104363 <strtol+0xaf>
		else if (*s >= 'a' && *s <= 'z')
f0104345:	8d 59 9f             	lea    -0x61(%ecx),%ebx
f0104348:	80 fb 19             	cmp    $0x19,%bl
f010434b:	77 08                	ja     f0104355 <strtol+0xa1>
			dig = *s - 'a' + 10;
f010434d:	0f be c9             	movsbl %cl,%ecx
f0104350:	83 e9 57             	sub    $0x57,%ecx
f0104353:	eb 0e                	jmp    f0104363 <strtol+0xaf>
		else if (*s >= 'A' && *s <= 'Z')
f0104355:	8d 59 bf             	lea    -0x41(%ecx),%ebx
f0104358:	80 fb 19             	cmp    $0x19,%bl
f010435b:	77 14                	ja     f0104371 <strtol+0xbd>
			dig = *s - 'A' + 10;
f010435d:	0f be c9             	movsbl %cl,%ecx
f0104360:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0104363:	39 f1                	cmp    %esi,%ecx
f0104365:	7d 0e                	jge    f0104375 <strtol+0xc1>
			break;
		s++, val = (val * base) + dig;
f0104367:	83 c2 01             	add    $0x1,%edx
f010436a:	0f af c6             	imul   %esi,%eax
f010436d:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
f010436f:	eb c1                	jmp    f0104332 <strtol+0x7e>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
f0104371:	89 c1                	mov    %eax,%ecx
f0104373:	eb 02                	jmp    f0104377 <strtol+0xc3>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0104375:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
f0104377:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f010437b:	74 05                	je     f0104382 <strtol+0xce>
		*endptr = (char *) s;
f010437d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104380:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
f0104382:	89 ca                	mov    %ecx,%edx
f0104384:	f7 da                	neg    %edx
f0104386:	85 ff                	test   %edi,%edi
f0104388:	0f 45 c2             	cmovne %edx,%eax
}
f010438b:	5b                   	pop    %ebx
f010438c:	5e                   	pop    %esi
f010438d:	5f                   	pop    %edi
f010438e:	5d                   	pop    %ebp
f010438f:	c3                   	ret    

f0104390 <__udivdi3>:
f0104390:	83 ec 1c             	sub    $0x1c,%esp
f0104393:	89 7c 24 14          	mov    %edi,0x14(%esp)
f0104397:	8b 7c 24 2c          	mov    0x2c(%esp),%edi
f010439b:	8b 44 24 20          	mov    0x20(%esp),%eax
f010439f:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f01043a3:	89 74 24 10          	mov    %esi,0x10(%esp)
f01043a7:	8b 74 24 24          	mov    0x24(%esp),%esi
f01043ab:	85 ff                	test   %edi,%edi
f01043ad:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f01043b1:	89 44 24 08          	mov    %eax,0x8(%esp)
f01043b5:	89 cd                	mov    %ecx,%ebp
f01043b7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01043bb:	75 33                	jne    f01043f0 <__udivdi3+0x60>
f01043bd:	39 f1                	cmp    %esi,%ecx
f01043bf:	77 57                	ja     f0104418 <__udivdi3+0x88>
f01043c1:	85 c9                	test   %ecx,%ecx
f01043c3:	75 0b                	jne    f01043d0 <__udivdi3+0x40>
f01043c5:	b8 01 00 00 00       	mov    $0x1,%eax
f01043ca:	31 d2                	xor    %edx,%edx
f01043cc:	f7 f1                	div    %ecx
f01043ce:	89 c1                	mov    %eax,%ecx
f01043d0:	89 f0                	mov    %esi,%eax
f01043d2:	31 d2                	xor    %edx,%edx
f01043d4:	f7 f1                	div    %ecx
f01043d6:	89 c6                	mov    %eax,%esi
f01043d8:	8b 44 24 04          	mov    0x4(%esp),%eax
f01043dc:	f7 f1                	div    %ecx
f01043de:	89 f2                	mov    %esi,%edx
f01043e0:	8b 74 24 10          	mov    0x10(%esp),%esi
f01043e4:	8b 7c 24 14          	mov    0x14(%esp),%edi
f01043e8:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f01043ec:	83 c4 1c             	add    $0x1c,%esp
f01043ef:	c3                   	ret    
f01043f0:	31 d2                	xor    %edx,%edx
f01043f2:	31 c0                	xor    %eax,%eax
f01043f4:	39 f7                	cmp    %esi,%edi
f01043f6:	77 e8                	ja     f01043e0 <__udivdi3+0x50>
f01043f8:	0f bd cf             	bsr    %edi,%ecx
f01043fb:	83 f1 1f             	xor    $0x1f,%ecx
f01043fe:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0104402:	75 2c                	jne    f0104430 <__udivdi3+0xa0>
f0104404:	3b 6c 24 08          	cmp    0x8(%esp),%ebp
f0104408:	76 04                	jbe    f010440e <__udivdi3+0x7e>
f010440a:	39 f7                	cmp    %esi,%edi
f010440c:	73 d2                	jae    f01043e0 <__udivdi3+0x50>
f010440e:	31 d2                	xor    %edx,%edx
f0104410:	b8 01 00 00 00       	mov    $0x1,%eax
f0104415:	eb c9                	jmp    f01043e0 <__udivdi3+0x50>
f0104417:	90                   	nop
f0104418:	89 f2                	mov    %esi,%edx
f010441a:	f7 f1                	div    %ecx
f010441c:	31 d2                	xor    %edx,%edx
f010441e:	8b 74 24 10          	mov    0x10(%esp),%esi
f0104422:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0104426:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f010442a:	83 c4 1c             	add    $0x1c,%esp
f010442d:	c3                   	ret    
f010442e:	66 90                	xchg   %ax,%ax
f0104430:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0104435:	b8 20 00 00 00       	mov    $0x20,%eax
f010443a:	89 ea                	mov    %ebp,%edx
f010443c:	2b 44 24 04          	sub    0x4(%esp),%eax
f0104440:	d3 e7                	shl    %cl,%edi
f0104442:	89 c1                	mov    %eax,%ecx
f0104444:	d3 ea                	shr    %cl,%edx
f0104446:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f010444b:	09 fa                	or     %edi,%edx
f010444d:	89 f7                	mov    %esi,%edi
f010444f:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0104453:	89 f2                	mov    %esi,%edx
f0104455:	8b 74 24 08          	mov    0x8(%esp),%esi
f0104459:	d3 e5                	shl    %cl,%ebp
f010445b:	89 c1                	mov    %eax,%ecx
f010445d:	d3 ef                	shr    %cl,%edi
f010445f:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0104464:	d3 e2                	shl    %cl,%edx
f0104466:	89 c1                	mov    %eax,%ecx
f0104468:	d3 ee                	shr    %cl,%esi
f010446a:	09 d6                	or     %edx,%esi
f010446c:	89 fa                	mov    %edi,%edx
f010446e:	89 f0                	mov    %esi,%eax
f0104470:	f7 74 24 0c          	divl   0xc(%esp)
f0104474:	89 d7                	mov    %edx,%edi
f0104476:	89 c6                	mov    %eax,%esi
f0104478:	f7 e5                	mul    %ebp
f010447a:	39 d7                	cmp    %edx,%edi
f010447c:	72 22                	jb     f01044a0 <__udivdi3+0x110>
f010447e:	8b 6c 24 08          	mov    0x8(%esp),%ebp
f0104482:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0104487:	d3 e5                	shl    %cl,%ebp
f0104489:	39 c5                	cmp    %eax,%ebp
f010448b:	73 04                	jae    f0104491 <__udivdi3+0x101>
f010448d:	39 d7                	cmp    %edx,%edi
f010448f:	74 0f                	je     f01044a0 <__udivdi3+0x110>
f0104491:	89 f0                	mov    %esi,%eax
f0104493:	31 d2                	xor    %edx,%edx
f0104495:	e9 46 ff ff ff       	jmp    f01043e0 <__udivdi3+0x50>
f010449a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01044a0:	8d 46 ff             	lea    -0x1(%esi),%eax
f01044a3:	31 d2                	xor    %edx,%edx
f01044a5:	8b 74 24 10          	mov    0x10(%esp),%esi
f01044a9:	8b 7c 24 14          	mov    0x14(%esp),%edi
f01044ad:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f01044b1:	83 c4 1c             	add    $0x1c,%esp
f01044b4:	c3                   	ret    
	...

f01044c0 <__umoddi3>:
f01044c0:	83 ec 1c             	sub    $0x1c,%esp
f01044c3:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f01044c7:	8b 6c 24 2c          	mov    0x2c(%esp),%ebp
f01044cb:	8b 44 24 20          	mov    0x20(%esp),%eax
f01044cf:	89 74 24 10          	mov    %esi,0x10(%esp)
f01044d3:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f01044d7:	8b 74 24 24          	mov    0x24(%esp),%esi
f01044db:	85 ed                	test   %ebp,%ebp
f01044dd:	89 7c 24 14          	mov    %edi,0x14(%esp)
f01044e1:	89 44 24 08          	mov    %eax,0x8(%esp)
f01044e5:	89 cf                	mov    %ecx,%edi
f01044e7:	89 04 24             	mov    %eax,(%esp)
f01044ea:	89 f2                	mov    %esi,%edx
f01044ec:	75 1a                	jne    f0104508 <__umoddi3+0x48>
f01044ee:	39 f1                	cmp    %esi,%ecx
f01044f0:	76 4e                	jbe    f0104540 <__umoddi3+0x80>
f01044f2:	f7 f1                	div    %ecx
f01044f4:	89 d0                	mov    %edx,%eax
f01044f6:	31 d2                	xor    %edx,%edx
f01044f8:	8b 74 24 10          	mov    0x10(%esp),%esi
f01044fc:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0104500:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0104504:	83 c4 1c             	add    $0x1c,%esp
f0104507:	c3                   	ret    
f0104508:	39 f5                	cmp    %esi,%ebp
f010450a:	77 54                	ja     f0104560 <__umoddi3+0xa0>
f010450c:	0f bd c5             	bsr    %ebp,%eax
f010450f:	83 f0 1f             	xor    $0x1f,%eax
f0104512:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104516:	75 60                	jne    f0104578 <__umoddi3+0xb8>
f0104518:	3b 0c 24             	cmp    (%esp),%ecx
f010451b:	0f 87 07 01 00 00    	ja     f0104628 <__umoddi3+0x168>
f0104521:	89 f2                	mov    %esi,%edx
f0104523:	8b 34 24             	mov    (%esp),%esi
f0104526:	29 ce                	sub    %ecx,%esi
f0104528:	19 ea                	sbb    %ebp,%edx
f010452a:	89 34 24             	mov    %esi,(%esp)
f010452d:	8b 04 24             	mov    (%esp),%eax
f0104530:	8b 74 24 10          	mov    0x10(%esp),%esi
f0104534:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0104538:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f010453c:	83 c4 1c             	add    $0x1c,%esp
f010453f:	c3                   	ret    
f0104540:	85 c9                	test   %ecx,%ecx
f0104542:	75 0b                	jne    f010454f <__umoddi3+0x8f>
f0104544:	b8 01 00 00 00       	mov    $0x1,%eax
f0104549:	31 d2                	xor    %edx,%edx
f010454b:	f7 f1                	div    %ecx
f010454d:	89 c1                	mov    %eax,%ecx
f010454f:	89 f0                	mov    %esi,%eax
f0104551:	31 d2                	xor    %edx,%edx
f0104553:	f7 f1                	div    %ecx
f0104555:	8b 04 24             	mov    (%esp),%eax
f0104558:	f7 f1                	div    %ecx
f010455a:	eb 98                	jmp    f01044f4 <__umoddi3+0x34>
f010455c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104560:	89 f2                	mov    %esi,%edx
f0104562:	8b 74 24 10          	mov    0x10(%esp),%esi
f0104566:	8b 7c 24 14          	mov    0x14(%esp),%edi
f010456a:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f010456e:	83 c4 1c             	add    $0x1c,%esp
f0104571:	c3                   	ret    
f0104572:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0104578:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f010457d:	89 e8                	mov    %ebp,%eax
f010457f:	bd 20 00 00 00       	mov    $0x20,%ebp
f0104584:	2b 6c 24 04          	sub    0x4(%esp),%ebp
f0104588:	89 fa                	mov    %edi,%edx
f010458a:	d3 e0                	shl    %cl,%eax
f010458c:	89 e9                	mov    %ebp,%ecx
f010458e:	d3 ea                	shr    %cl,%edx
f0104590:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0104595:	09 c2                	or     %eax,%edx
f0104597:	8b 44 24 08          	mov    0x8(%esp),%eax
f010459b:	89 14 24             	mov    %edx,(%esp)
f010459e:	89 f2                	mov    %esi,%edx
f01045a0:	d3 e7                	shl    %cl,%edi
f01045a2:	89 e9                	mov    %ebp,%ecx
f01045a4:	d3 ea                	shr    %cl,%edx
f01045a6:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f01045ab:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f01045af:	d3 e6                	shl    %cl,%esi
f01045b1:	89 e9                	mov    %ebp,%ecx
f01045b3:	d3 e8                	shr    %cl,%eax
f01045b5:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f01045ba:	09 f0                	or     %esi,%eax
f01045bc:	8b 74 24 08          	mov    0x8(%esp),%esi
f01045c0:	f7 34 24             	divl   (%esp)
f01045c3:	d3 e6                	shl    %cl,%esi
f01045c5:	89 74 24 08          	mov    %esi,0x8(%esp)
f01045c9:	89 d6                	mov    %edx,%esi
f01045cb:	f7 e7                	mul    %edi
f01045cd:	39 d6                	cmp    %edx,%esi
f01045cf:	89 c1                	mov    %eax,%ecx
f01045d1:	89 d7                	mov    %edx,%edi
f01045d3:	72 3f                	jb     f0104614 <__umoddi3+0x154>
f01045d5:	39 44 24 08          	cmp    %eax,0x8(%esp)
f01045d9:	72 35                	jb     f0104610 <__umoddi3+0x150>
f01045db:	8b 44 24 08          	mov    0x8(%esp),%eax
f01045df:	29 c8                	sub    %ecx,%eax
f01045e1:	19 fe                	sbb    %edi,%esi
f01045e3:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f01045e8:	89 f2                	mov    %esi,%edx
f01045ea:	d3 e8                	shr    %cl,%eax
f01045ec:	89 e9                	mov    %ebp,%ecx
f01045ee:	d3 e2                	shl    %cl,%edx
f01045f0:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f01045f5:	09 d0                	or     %edx,%eax
f01045f7:	89 f2                	mov    %esi,%edx
f01045f9:	d3 ea                	shr    %cl,%edx
f01045fb:	8b 74 24 10          	mov    0x10(%esp),%esi
f01045ff:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0104603:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0104607:	83 c4 1c             	add    $0x1c,%esp
f010460a:	c3                   	ret    
f010460b:	90                   	nop
f010460c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104610:	39 d6                	cmp    %edx,%esi
f0104612:	75 c7                	jne    f01045db <__umoddi3+0x11b>
f0104614:	89 d7                	mov    %edx,%edi
f0104616:	89 c1                	mov    %eax,%ecx
f0104618:	2b 4c 24 0c          	sub    0xc(%esp),%ecx
f010461c:	1b 3c 24             	sbb    (%esp),%edi
f010461f:	eb ba                	jmp    f01045db <__umoddi3+0x11b>
f0104621:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104628:	39 f5                	cmp    %esi,%ebp
f010462a:	0f 82 f1 fe ff ff    	jb     f0104521 <__umoddi3+0x61>
f0104630:	e9 f8 fe ff ff       	jmp    f010452d <__umoddi3+0x6d>
