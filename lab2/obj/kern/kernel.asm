
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
f0100063:	e8 c9 40 00 00       	call   f0104131 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100068:	e8 97 04 00 00       	call   f0100504 <cons_init>
	cprintf("6828 decimal is %o octal!\n", 6828);
f010006d:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f0100074:	00 
f0100075:	c7 04 24 40 46 10 f0 	movl   $0xf0104640,(%esp)
f010007c:	e8 f9 34 00 00       	call   f010357a <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100081:	e8 1f 19 00 00       	call   f01019a5 <mem_init>
	// Test the stack backtrace function (lab 1 only)
//>>>>>>> lab1

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f0100086:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010008d:	e8 2c 0f 00 00       	call   f0100fbe <monitor>
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
f01000c8:	e8 ad 34 00 00       	call   f010357a <cprintf>
	vcprintf(fmt, ap);
f01000cd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01000d1:	89 34 24             	mov    %esi,(%esp)
f01000d4:	e8 6e 34 00 00       	call   f0103547 <vcprintf>
	cprintf("\n");
f01000d9:	c7 04 24 70 58 10 f0 	movl   $0xf0105870,(%esp)
f01000e0:	e8 95 34 00 00       	call   f010357a <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f01000e5:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000ec:	e8 cd 0e 00 00       	call   f0100fbe <monitor>
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
f0100112:	e8 63 34 00 00       	call   f010357a <cprintf>
	vcprintf(fmt, ap);
f0100117:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010011b:	8b 45 10             	mov    0x10(%ebp),%eax
f010011e:	89 04 24             	mov    %eax,(%esp)
f0100121:	e8 21 34 00 00       	call   f0103547 <vcprintf>
	cprintf("\n");
f0100126:	c7 04 24 70 58 10 f0 	movl   $0xf0105870,(%esp)
f010012d:	e8 48 34 00 00       	call   f010357a <cprintf>
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
f010031b:	e8 6c 3e 00 00       	call   f010418c <memmove>
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
f0100461:	e8 14 31 00 00       	call   f010357a <cprintf>
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
f01005ec:	e8 89 2f 00 00       	call   f010357a <cprintf>
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
f010063d:	e8 38 2f 00 00       	call   f010357a <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100642:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f0100649:	00 
f010064a:	c7 04 24 04 4b 10 f0 	movl   $0xf0104b04,(%esp)
f0100651:	e8 24 2f 00 00       	call   f010357a <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100656:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f010065d:	00 
f010065e:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f0100665:	f0 
f0100666:	c7 04 24 2c 4b 10 f0 	movl   $0xf0104b2c,(%esp)
f010066d:	e8 08 2f 00 00       	call   f010357a <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100672:	c7 44 24 08 25 46 10 	movl   $0x104625,0x8(%esp)
f0100679:	00 
f010067a:	c7 44 24 04 25 46 10 	movl   $0xf0104625,0x4(%esp)
f0100681:	f0 
f0100682:	c7 04 24 50 4b 10 f0 	movl   $0xf0104b50,(%esp)
f0100689:	e8 ec 2e 00 00       	call   f010357a <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010068e:	c7 44 24 08 20 93 11 	movl   $0x119320,0x8(%esp)
f0100695:	00 
f0100696:	c7 44 24 04 20 93 11 	movl   $0xf0119320,0x4(%esp)
f010069d:	f0 
f010069e:	c7 04 24 74 4b 10 f0 	movl   $0xf0104b74,(%esp)
f01006a5:	e8 d0 2e 00 00       	call   f010357a <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006aa:	c7 44 24 08 90 99 11 	movl   $0x119990,0x8(%esp)
f01006b1:	00 
f01006b2:	c7 44 24 04 90 99 11 	movl   $0xf0119990,0x4(%esp)
f01006b9:	f0 
f01006ba:	c7 04 24 98 4b 10 f0 	movl   $0xf0104b98,(%esp)
f01006c1:	e8 b4 2e 00 00       	call   f010357a <cprintf>
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
f01006e7:	c7 04 24 bc 4b 10 f0 	movl   $0xf0104bbc,(%esp)
f01006ee:	e8 87 2e 00 00       	call   f010357a <cprintf>
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
f0100706:	8b 83 84 4e 10 f0    	mov    -0xfefb17c(%ebx),%eax
f010070c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100710:	8b 83 80 4e 10 f0    	mov    -0xfefb180(%ebx),%eax
f0100716:	89 44 24 04          	mov    %eax,0x4(%esp)
f010071a:	c7 04 24 e9 48 10 f0 	movl   $0xf01048e9,(%esp)
f0100721:	e8 54 2e 00 00       	call   f010357a <cprintf>
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
f0100750:	e8 25 2e 00 00       	call   f010357a <cprintf>
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
f0100788:	c7 04 24 e8 4b 10 f0 	movl   $0xf0104be8,(%esp)
f010078f:	e8 e6 2d 00 00       	call   f010357a <cprintf>
		struct Eipdebuginfo temp_debuginfo;
		debuginfo_eip((uintptr_t) eip, &temp_debuginfo);		
f0100794:	8d 45 d0             	lea    -0x30(%ebp),%eax
f0100797:	89 44 24 04          	mov    %eax,0x4(%esp)
f010079b:	89 3c 24             	mov    %edi,(%esp)
f010079e:	e8 d1 2e 00 00       	call   f0103674 <debuginfo_eip>
		cprintf("       %s:%d: ", temp_debuginfo.eip_file, temp_debuginfo.eip_line);
f01007a3:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01007a6:	89 44 24 08          	mov    %eax,0x8(%esp)
f01007aa:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01007ad:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007b1:	c7 04 24 03 49 10 f0 	movl   $0xf0104903,(%esp)
f01007b8:	e8 bd 2d 00 00       	call   f010357a <cprintf>
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
f01007da:	e8 9b 2d 00 00       	call   f010357a <cprintf>
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
f01007f5:	e8 80 2d 00 00       	call   f010357a <cprintf>
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

f0100814 <mon_showPT>:
	cprintf("after change ");  printPermission(*mapper); cprintf("\n");
	return 0;
}


int mon_showPT(int argc, char **argv, struct Trapframe *tf) {
f0100814:	55                   	push   %ebp
f0100815:	89 e5                	mov    %esp,%ebp
f0100817:	83 ec 18             	sub    $0x18,%esp
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010081a:	83 3d 84 99 11 f0 00 	cmpl   $0x0,0xf0119984
f0100821:	75 24                	jne    f0100847 <mon_showPT+0x33>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100823:	c7 44 24 0c 08 00 00 	movl   $0x8,0xc(%esp)
f010082a:	00 
f010082b:	c7 44 24 08 1c 4c 10 	movl   $0xf0104c1c,0x8(%esp)
f0100832:	f0 
f0100833:	c7 44 24 04 b7 00 00 	movl   $0xb7,0x4(%esp)
f010083a:	00 
f010083b:	c7 04 24 1a 49 10 f0 	movl   $0xf010491a,(%esp)
f0100842:	e8 4d f8 ff ff       	call   f0100094 <_panic>
	extern int gdtdesc;
	cprintf("%x", *((uint32_t*)KADDR(GD_KT)));
f0100847:	a1 08 00 00 f0       	mov    0xf0000008,%eax
f010084c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100850:	c7 04 24 29 49 10 f0 	movl   $0xf0104929,(%esp)
f0100857:	e8 1e 2d 00 00       	call   f010357a <cprintf>
	if (!pxtoi(&va, argv[1])) return 0;
	
	pte_t *mapper = pgdir_walk(kern_pgdir, (void*) ((va >> PDXSHIFT) << PDXSHIFT), 1);
	cprintf("Page Table Entry Address : 0x%08x\n", mapper); */
	return 0;
}
f010085c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100861:	c9                   	leave  
f0100862:	c3                   	ret    

f0100863 <mon_setcolor>:
	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
	return 0;
}

int mon_setcolor(int argc, char **argv, struct Trapframe *tf) {
f0100863:	55                   	push   %ebp
f0100864:	89 e5                	mov    %esp,%ebp
f0100866:	83 ec 28             	sub    $0x28,%esp
f0100869:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f010086c:	89 75 f8             	mov    %esi,-0x8(%ebp)
f010086f:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0100872:	8b 75 0c             	mov    0xc(%ebp),%esi
	//argv
	uint16_t ch_color1, ch_color;
	if(strcmp(argv[2],"blk")==0)
f0100875:	c7 44 24 04 2c 49 10 	movl   $0xf010492c,0x4(%esp)
f010087c:	f0 
f010087d:	8b 46 08             	mov    0x8(%esi),%eax
f0100880:	89 04 24             	mov    %eax,(%esp)
f0100883:	e8 d3 37 00 00       	call   f010405b <strcmp>
			ch_color1=COLOR_BLK
f0100888:	bf 00 00 00 00       	mov    $0x0,%edi
}

int mon_setcolor(int argc, char **argv, struct Trapframe *tf) {
	//argv
	uint16_t ch_color1, ch_color;
	if(strcmp(argv[2],"blk")==0)
f010088d:	85 c0                	test   %eax,%eax
f010088f:	0f 84 0e 01 00 00    	je     f01009a3 <mon_setcolor+0x140>
			ch_color1=COLOR_BLK
	else if(strcmp(argv[2],"wht")==0)
f0100895:	c7 44 24 04 30 49 10 	movl   $0xf0104930,0x4(%esp)
f010089c:	f0 
f010089d:	8b 46 08             	mov    0x8(%esi),%eax
f01008a0:	89 04 24             	mov    %eax,(%esp)
f01008a3:	e8 b3 37 00 00       	call   f010405b <strcmp>
			ch_color1=COLOR_WHT
f01008a8:	bf 07 00 00 00       	mov    $0x7,%edi
int mon_setcolor(int argc, char **argv, struct Trapframe *tf) {
	//argv
	uint16_t ch_color1, ch_color;
	if(strcmp(argv[2],"blk")==0)
			ch_color1=COLOR_BLK
	else if(strcmp(argv[2],"wht")==0)
f01008ad:	85 c0                	test   %eax,%eax
f01008af:	0f 84 ee 00 00 00    	je     f01009a3 <mon_setcolor+0x140>
			ch_color1=COLOR_WHT
	else if(strcmp(argv[2],"blu")==0)
f01008b5:	c7 44 24 04 34 49 10 	movl   $0xf0104934,0x4(%esp)
f01008bc:	f0 
f01008bd:	8b 46 08             	mov    0x8(%esi),%eax
f01008c0:	89 04 24             	mov    %eax,(%esp)
f01008c3:	e8 93 37 00 00       	call   f010405b <strcmp>
			ch_color1=COLOR_BLU
f01008c8:	bf 01 00 00 00       	mov    $0x1,%edi
	uint16_t ch_color1, ch_color;
	if(strcmp(argv[2],"blk")==0)
			ch_color1=COLOR_BLK
	else if(strcmp(argv[2],"wht")==0)
			ch_color1=COLOR_WHT
	else if(strcmp(argv[2],"blu")==0)
f01008cd:	85 c0                	test   %eax,%eax
f01008cf:	0f 84 ce 00 00 00    	je     f01009a3 <mon_setcolor+0x140>
			ch_color1=COLOR_BLU
	else if(strcmp(argv[2],"grn")==0)
f01008d5:	c7 44 24 04 38 49 10 	movl   $0xf0104938,0x4(%esp)
f01008dc:	f0 
f01008dd:	8b 46 08             	mov    0x8(%esi),%eax
f01008e0:	89 04 24             	mov    %eax,(%esp)
f01008e3:	e8 73 37 00 00       	call   f010405b <strcmp>
			ch_color1=COLOR_GRN
f01008e8:	bf 02 00 00 00       	mov    $0x2,%edi
			ch_color1=COLOR_BLK
	else if(strcmp(argv[2],"wht")==0)
			ch_color1=COLOR_WHT
	else if(strcmp(argv[2],"blu")==0)
			ch_color1=COLOR_BLU
	else if(strcmp(argv[2],"grn")==0)
f01008ed:	85 c0                	test   %eax,%eax
f01008ef:	0f 84 ae 00 00 00    	je     f01009a3 <mon_setcolor+0x140>
			ch_color1=COLOR_GRN
	else if(strcmp(argv[2],"red")==0)
f01008f5:	c7 44 24 04 3c 49 10 	movl   $0xf010493c,0x4(%esp)
f01008fc:	f0 
f01008fd:	8b 46 08             	mov    0x8(%esi),%eax
f0100900:	89 04 24             	mov    %eax,(%esp)
f0100903:	e8 53 37 00 00       	call   f010405b <strcmp>
			ch_color1=COLOR_RED
f0100908:	bf 04 00 00 00       	mov    $0x4,%edi
			ch_color1=COLOR_WHT
	else if(strcmp(argv[2],"blu")==0)
			ch_color1=COLOR_BLU
	else if(strcmp(argv[2],"grn")==0)
			ch_color1=COLOR_GRN
	else if(strcmp(argv[2],"red")==0)
f010090d:	85 c0                	test   %eax,%eax
f010090f:	0f 84 8e 00 00 00    	je     f01009a3 <mon_setcolor+0x140>
			ch_color1=COLOR_RED
	else if(strcmp(argv[2],"gry")==0)
f0100915:	c7 44 24 04 40 49 10 	movl   $0xf0104940,0x4(%esp)
f010091c:	f0 
f010091d:	8b 46 08             	mov    0x8(%esi),%eax
f0100920:	89 04 24             	mov    %eax,(%esp)
f0100923:	e8 33 37 00 00       	call   f010405b <strcmp>
			ch_color1=COLOR_GRY
f0100928:	bf 08 00 00 00       	mov    $0x8,%edi
			ch_color1=COLOR_BLU
	else if(strcmp(argv[2],"grn")==0)
			ch_color1=COLOR_GRN
	else if(strcmp(argv[2],"red")==0)
			ch_color1=COLOR_RED
	else if(strcmp(argv[2],"gry")==0)
f010092d:	85 c0                	test   %eax,%eax
f010092f:	74 72                	je     f01009a3 <mon_setcolor+0x140>
			ch_color1=COLOR_GRY
	else if(strcmp(argv[2],"ylw")==0)
f0100931:	c7 44 24 04 44 49 10 	movl   $0xf0104944,0x4(%esp)
f0100938:	f0 
f0100939:	8b 46 08             	mov    0x8(%esi),%eax
f010093c:	89 04 24             	mov    %eax,(%esp)
f010093f:	e8 17 37 00 00       	call   f010405b <strcmp>
			ch_color1=COLOR_YLW
f0100944:	bf 0f 00 00 00       	mov    $0xf,%edi
			ch_color1=COLOR_GRN
	else if(strcmp(argv[2],"red")==0)
			ch_color1=COLOR_RED
	else if(strcmp(argv[2],"gry")==0)
			ch_color1=COLOR_GRY
	else if(strcmp(argv[2],"ylw")==0)
f0100949:	85 c0                	test   %eax,%eax
f010094b:	74 56                	je     f01009a3 <mon_setcolor+0x140>
			ch_color1=COLOR_YLW
	else if(strcmp(argv[2],"org")==0)
f010094d:	c7 44 24 04 48 49 10 	movl   $0xf0104948,0x4(%esp)
f0100954:	f0 
f0100955:	8b 46 08             	mov    0x8(%esi),%eax
f0100958:	89 04 24             	mov    %eax,(%esp)
f010095b:	e8 fb 36 00 00       	call   f010405b <strcmp>
			ch_color1=COLOR_ORG
f0100960:	bf 0c 00 00 00       	mov    $0xc,%edi
			ch_color1=COLOR_RED
	else if(strcmp(argv[2],"gry")==0)
			ch_color1=COLOR_GRY
	else if(strcmp(argv[2],"ylw")==0)
			ch_color1=COLOR_YLW
	else if(strcmp(argv[2],"org")==0)
f0100965:	85 c0                	test   %eax,%eax
f0100967:	74 3a                	je     f01009a3 <mon_setcolor+0x140>
			ch_color1=COLOR_ORG
	else if(strcmp(argv[2],"pur")==0)
f0100969:	c7 44 24 04 4c 49 10 	movl   $0xf010494c,0x4(%esp)
f0100970:	f0 
f0100971:	8b 46 08             	mov    0x8(%esi),%eax
f0100974:	89 04 24             	mov    %eax,(%esp)
f0100977:	e8 df 36 00 00       	call   f010405b <strcmp>
			ch_color1=COLOR_PUR
f010097c:	bf 06 00 00 00       	mov    $0x6,%edi
			ch_color1=COLOR_GRY
	else if(strcmp(argv[2],"ylw")==0)
			ch_color1=COLOR_YLW
	else if(strcmp(argv[2],"org")==0)
			ch_color1=COLOR_ORG
	else if(strcmp(argv[2],"pur")==0)
f0100981:	85 c0                	test   %eax,%eax
f0100983:	74 1e                	je     f01009a3 <mon_setcolor+0x140>
			ch_color1=COLOR_PUR
	else if(strcmp(argv[2],"cyn")==0)
f0100985:	c7 44 24 04 50 49 10 	movl   $0xf0104950,0x4(%esp)
f010098c:	f0 
f010098d:	8b 46 08             	mov    0x8(%esi),%eax
f0100990:	89 04 24             	mov    %eax,(%esp)
f0100993:	e8 c3 36 00 00       	call   f010405b <strcmp>
			ch_color1=COLOR_CYN
f0100998:	83 f8 01             	cmp    $0x1,%eax
f010099b:	19 ff                	sbb    %edi,%edi
f010099d:	83 e7 04             	and    $0x4,%edi
f01009a0:	83 c7 07             	add    $0x7,%edi
	else ch_color1=COLOR_WHT;
	if(strcmp(argv[1],"blk")==0)
f01009a3:	c7 44 24 04 2c 49 10 	movl   $0xf010492c,0x4(%esp)
f01009aa:	f0 
f01009ab:	8b 46 04             	mov    0x4(%esi),%eax
f01009ae:	89 04 24             	mov    %eax,(%esp)
f01009b1:	e8 a5 36 00 00       	call   f010405b <strcmp>
			ch_color=COLOR_BLK
f01009b6:	bb 00 00 00 00       	mov    $0x0,%ebx
	else if(strcmp(argv[2],"pur")==0)
			ch_color1=COLOR_PUR
	else if(strcmp(argv[2],"cyn")==0)
			ch_color1=COLOR_CYN
	else ch_color1=COLOR_WHT;
	if(strcmp(argv[1],"blk")==0)
f01009bb:	85 c0                	test   %eax,%eax
f01009bd:	0f 84 f6 00 00 00    	je     f0100ab9 <mon_setcolor+0x256>
			ch_color=COLOR_BLK
	else if(strcmp(argv[1],"wht")==0)
f01009c3:	c7 44 24 04 30 49 10 	movl   $0xf0104930,0x4(%esp)
f01009ca:	f0 
f01009cb:	8b 46 04             	mov    0x4(%esi),%eax
f01009ce:	89 04 24             	mov    %eax,(%esp)
f01009d1:	e8 85 36 00 00       	call   f010405b <strcmp>
			ch_color=COLOR_WHT
f01009d6:	b3 07                	mov    $0x7,%bl
	else if(strcmp(argv[2],"cyn")==0)
			ch_color1=COLOR_CYN
	else ch_color1=COLOR_WHT;
	if(strcmp(argv[1],"blk")==0)
			ch_color=COLOR_BLK
	else if(strcmp(argv[1],"wht")==0)
f01009d8:	85 c0                	test   %eax,%eax
f01009da:	0f 84 d9 00 00 00    	je     f0100ab9 <mon_setcolor+0x256>
			ch_color=COLOR_WHT
	else if(strcmp(argv[1],"blu")==0)
f01009e0:	c7 44 24 04 34 49 10 	movl   $0xf0104934,0x4(%esp)
f01009e7:	f0 
f01009e8:	8b 46 04             	mov    0x4(%esi),%eax
f01009eb:	89 04 24             	mov    %eax,(%esp)
f01009ee:	e8 68 36 00 00       	call   f010405b <strcmp>
			ch_color=COLOR_BLU
f01009f3:	b3 01                	mov    $0x1,%bl
	else ch_color1=COLOR_WHT;
	if(strcmp(argv[1],"blk")==0)
			ch_color=COLOR_BLK
	else if(strcmp(argv[1],"wht")==0)
			ch_color=COLOR_WHT
	else if(strcmp(argv[1],"blu")==0)
f01009f5:	85 c0                	test   %eax,%eax
f01009f7:	0f 84 bc 00 00 00    	je     f0100ab9 <mon_setcolor+0x256>
			ch_color=COLOR_BLU
	else if(strcmp(argv[1],"grn")==0)
f01009fd:	c7 44 24 04 38 49 10 	movl   $0xf0104938,0x4(%esp)
f0100a04:	f0 
f0100a05:	8b 46 04             	mov    0x4(%esi),%eax
f0100a08:	89 04 24             	mov    %eax,(%esp)
f0100a0b:	e8 4b 36 00 00       	call   f010405b <strcmp>
			ch_color=COLOR_GRN
f0100a10:	b3 02                	mov    $0x2,%bl
			ch_color=COLOR_BLK
	else if(strcmp(argv[1],"wht")==0)
			ch_color=COLOR_WHT
	else if(strcmp(argv[1],"blu")==0)
			ch_color=COLOR_BLU
	else if(strcmp(argv[1],"grn")==0)
f0100a12:	85 c0                	test   %eax,%eax
f0100a14:	0f 84 9f 00 00 00    	je     f0100ab9 <mon_setcolor+0x256>
			ch_color=COLOR_GRN
	else if(strcmp(argv[1],"red")==0)
f0100a1a:	c7 44 24 04 3c 49 10 	movl   $0xf010493c,0x4(%esp)
f0100a21:	f0 
f0100a22:	8b 46 04             	mov    0x4(%esi),%eax
f0100a25:	89 04 24             	mov    %eax,(%esp)
f0100a28:	e8 2e 36 00 00       	call   f010405b <strcmp>
			ch_color=COLOR_RED
f0100a2d:	b3 04                	mov    $0x4,%bl
			ch_color=COLOR_WHT
	else if(strcmp(argv[1],"blu")==0)
			ch_color=COLOR_BLU
	else if(strcmp(argv[1],"grn")==0)
			ch_color=COLOR_GRN
	else if(strcmp(argv[1],"red")==0)
f0100a2f:	85 c0                	test   %eax,%eax
f0100a31:	0f 84 82 00 00 00    	je     f0100ab9 <mon_setcolor+0x256>
			ch_color=COLOR_RED
	else if(strcmp(argv[1],"gry")==0)
f0100a37:	c7 44 24 04 40 49 10 	movl   $0xf0104940,0x4(%esp)
f0100a3e:	f0 
f0100a3f:	8b 46 04             	mov    0x4(%esi),%eax
f0100a42:	89 04 24             	mov    %eax,(%esp)
f0100a45:	e8 11 36 00 00       	call   f010405b <strcmp>
			ch_color=COLOR_GRY
f0100a4a:	b3 08                	mov    $0x8,%bl
			ch_color=COLOR_BLU
	else if(strcmp(argv[1],"grn")==0)
			ch_color=COLOR_GRN
	else if(strcmp(argv[1],"red")==0)
			ch_color=COLOR_RED
	else if(strcmp(argv[1],"gry")==0)
f0100a4c:	85 c0                	test   %eax,%eax
f0100a4e:	74 69                	je     f0100ab9 <mon_setcolor+0x256>
			ch_color=COLOR_GRY
	else if(strcmp(argv[1],"ylw")==0)
f0100a50:	c7 44 24 04 44 49 10 	movl   $0xf0104944,0x4(%esp)
f0100a57:	f0 
f0100a58:	8b 46 04             	mov    0x4(%esi),%eax
f0100a5b:	89 04 24             	mov    %eax,(%esp)
f0100a5e:	e8 f8 35 00 00       	call   f010405b <strcmp>
			ch_color=COLOR_YLW
f0100a63:	b3 0f                	mov    $0xf,%bl
			ch_color=COLOR_GRN
	else if(strcmp(argv[1],"red")==0)
			ch_color=COLOR_RED
	else if(strcmp(argv[1],"gry")==0)
			ch_color=COLOR_GRY
	else if(strcmp(argv[1],"ylw")==0)
f0100a65:	85 c0                	test   %eax,%eax
f0100a67:	74 50                	je     f0100ab9 <mon_setcolor+0x256>
			ch_color=COLOR_YLW
	else if(strcmp(argv[1],"org")==0)
f0100a69:	c7 44 24 04 48 49 10 	movl   $0xf0104948,0x4(%esp)
f0100a70:	f0 
f0100a71:	8b 46 04             	mov    0x4(%esi),%eax
f0100a74:	89 04 24             	mov    %eax,(%esp)
f0100a77:	e8 df 35 00 00       	call   f010405b <strcmp>
			ch_color=COLOR_ORG
f0100a7c:	b3 0c                	mov    $0xc,%bl
			ch_color=COLOR_RED
	else if(strcmp(argv[1],"gry")==0)
			ch_color=COLOR_GRY
	else if(strcmp(argv[1],"ylw")==0)
			ch_color=COLOR_YLW
	else if(strcmp(argv[1],"org")==0)
f0100a7e:	85 c0                	test   %eax,%eax
f0100a80:	74 37                	je     f0100ab9 <mon_setcolor+0x256>
			ch_color=COLOR_ORG
	else if(strcmp(argv[1],"pur")==0)
f0100a82:	c7 44 24 04 4c 49 10 	movl   $0xf010494c,0x4(%esp)
f0100a89:	f0 
f0100a8a:	8b 46 04             	mov    0x4(%esi),%eax
f0100a8d:	89 04 24             	mov    %eax,(%esp)
f0100a90:	e8 c6 35 00 00       	call   f010405b <strcmp>
			ch_color=COLOR_PUR
f0100a95:	b3 06                	mov    $0x6,%bl
			ch_color=COLOR_GRY
	else if(strcmp(argv[1],"ylw")==0)
			ch_color=COLOR_YLW
	else if(strcmp(argv[1],"org")==0)
			ch_color=COLOR_ORG
	else if(strcmp(argv[1],"pur")==0)
f0100a97:	85 c0                	test   %eax,%eax
f0100a99:	74 1e                	je     f0100ab9 <mon_setcolor+0x256>
			ch_color=COLOR_PUR
	else if(strcmp(argv[1],"cyn")==0)
f0100a9b:	c7 44 24 04 50 49 10 	movl   $0xf0104950,0x4(%esp)
f0100aa2:	f0 
f0100aa3:	8b 46 04             	mov    0x4(%esi),%eax
f0100aa6:	89 04 24             	mov    %eax,(%esp)
f0100aa9:	e8 ad 35 00 00       	call   f010405b <strcmp>
			ch_color=COLOR_CYN
f0100aae:	83 f8 01             	cmp    $0x1,%eax
f0100ab1:	19 db                	sbb    %ebx,%ebx
f0100ab3:	83 e3 04             	and    $0x4,%ebx
f0100ab6:	83 c3 07             	add    $0x7,%ebx
	else ch_color=COLOR_WHT;
	set_attribute_color((uint64_t) ch_color, (uint64_t) ch_color1);
f0100ab9:	0f b7 f7             	movzwl %di,%esi
f0100abc:	0f b7 db             	movzwl %bx,%ebx
f0100abf:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100ac3:	89 1c 24             	mov    %ebx,(%esp)
f0100ac6:	e8 ae f9 ff ff       	call   f0100479 <set_attribute_color>
	cprintf("console back-color :  %d \n        fore-color :  %d\n", ch_color, ch_color1);	
f0100acb:	89 74 24 08          	mov    %esi,0x8(%esp)
f0100acf:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100ad3:	c7 04 24 40 4c 10 f0 	movl   $0xf0104c40,(%esp)
f0100ada:	e8 9b 2a 00 00       	call   f010357a <cprintf>
	return 0;
}
f0100adf:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ae4:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0100ae7:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0100aea:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0100aed:	89 ec                	mov    %ebp,%esp
f0100aef:	5d                   	pop    %ebp
f0100af0:	c3                   	ret    

f0100af1 <printPermission>:

void printPermission(pte_t now) {
f0100af1:	55                   	push   %ebp
f0100af2:	89 e5                	mov    %esp,%ebp
f0100af4:	53                   	push   %ebx
f0100af5:	83 ec 14             	sub    $0x14,%esp
f0100af8:	8b 5d 08             	mov    0x8(%ebp),%ebx
	cprintf("PTE_U : %d ", ((now & PTE_U) != 0));
f0100afb:	f6 c3 04             	test   $0x4,%bl
f0100afe:	0f 95 c0             	setne  %al
f0100b01:	0f b6 c0             	movzbl %al,%eax
f0100b04:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100b08:	c7 04 24 54 49 10 f0 	movl   $0xf0104954,(%esp)
f0100b0f:	e8 66 2a 00 00       	call   f010357a <cprintf>
	cprintf("PTE_W : %d ", ((now & PTE_W) != 0));
f0100b14:	f6 c3 02             	test   $0x2,%bl
f0100b17:	0f 95 c0             	setne  %al
f0100b1a:	0f b6 c0             	movzbl %al,%eax
f0100b1d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100b21:	c7 04 24 60 49 10 f0 	movl   $0xf0104960,(%esp)
f0100b28:	e8 4d 2a 00 00       	call   f010357a <cprintf>
	cprintf("PTE_P : %d ", ((now & PTE_P) != 0));
f0100b2d:	83 e3 01             	and    $0x1,%ebx
f0100b30:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100b34:	c7 04 24 6c 49 10 f0 	movl   $0xf010496c,(%esp)
f0100b3b:	e8 3a 2a 00 00       	call   f010357a <cprintf>
}
f0100b40:	83 c4 14             	add    $0x14,%esp
f0100b43:	5b                   	pop    %ebx
f0100b44:	5d                   	pop    %ebp
f0100b45:	c3                   	ret    

f0100b46 <xtoi>:

uint32_t xtoi(char* origin, bool* check) {
f0100b46:	55                   	push   %ebp
f0100b47:	89 e5                	mov    %esp,%ebp
f0100b49:	83 ec 38             	sub    $0x38,%esp
f0100b4c:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0100b4f:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0100b52:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0100b55:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0100b58:	8b 75 0c             	mov    0xc(%ebp),%esi
	uint32_t i = 0, temp = 0, len = strlen(origin);
f0100b5b:	89 1c 24             	mov    %ebx,(%esp)
f0100b5e:	e8 ed 33 00 00       	call   f0103f50 <strlen>
	*check = true;
f0100b63:	c6 06 01             	movb   $0x1,(%esi)
	if ((origin[0] != '0') || (origin[1] != 'x' && origin[1] != 'X')) 
f0100b66:	80 3b 30             	cmpb   $0x30,(%ebx)
f0100b69:	75 1f                	jne    f0100b8a <xtoi+0x44>
f0100b6b:	0f b6 53 01          	movzbl 0x1(%ebx),%edx
f0100b6f:	80 fa 78             	cmp    $0x78,%dl
f0100b72:	74 05                	je     f0100b79 <xtoi+0x33>
f0100b74:	80 fa 58             	cmp    $0x58,%dl
f0100b77:	75 11                	jne    f0100b8a <xtoi+0x44>
	{
		*check = false;
		return -1;
	}
	for (i = 2; i < len; i++) {
f0100b79:	bf 00 00 00 00       	mov    $0x0,%edi
f0100b7e:	ba 02 00 00 00       	mov    $0x2,%edx
f0100b83:	83 f8 02             	cmp    $0x2,%eax
f0100b86:	77 0c                	ja     f0100b94 <xtoi+0x4e>
f0100b88:	eb 5d                	jmp    f0100be7 <xtoi+0xa1>
uint32_t xtoi(char* origin, bool* check) {
	uint32_t i = 0, temp = 0, len = strlen(origin);
	*check = true;
	if ((origin[0] != '0') || (origin[1] != 'x' && origin[1] != 'X')) 
	{
		*check = false;
f0100b8a:	c6 06 00             	movb   $0x0,(%esi)
		return -1;
f0100b8d:	bf ff ff ff ff       	mov    $0xffffffff,%edi
f0100b92:	eb 53                	jmp    f0100be7 <xtoi+0xa1>
f0100b94:	89 75 e4             	mov    %esi,-0x1c(%ebp)
f0100b97:	89 c6                	mov    %eax,%esi
	}
	for (i = 2; i < len; i++) {
		temp *= 16;
f0100b99:	c1 e7 04             	shl    $0x4,%edi
		if (origin[i] >= '0' && origin[i] <= '9')
f0100b9c:	0f b6 04 13          	movzbl (%ebx,%edx,1),%eax
f0100ba0:	8d 48 d0             	lea    -0x30(%eax),%ecx
f0100ba3:	80 f9 09             	cmp    $0x9,%cl
f0100ba6:	77 09                	ja     f0100bb1 <xtoi+0x6b>
			temp += origin[i] - '0';
f0100ba8:	0f be c0             	movsbl %al,%eax
f0100bab:	8d 7c 07 d0          	lea    -0x30(%edi,%eax,1),%edi
f0100baf:	eb 2f                	jmp    f0100be0 <xtoi+0x9a>
		else if (origin[i] >= 'a' && origin[i] <= 'f')
f0100bb1:	8d 48 9f             	lea    -0x61(%eax),%ecx
f0100bb4:	80 f9 05             	cmp    $0x5,%cl
f0100bb7:	77 09                	ja     f0100bc2 <xtoi+0x7c>
			temp += origin[i] - 'a' + 10;
f0100bb9:	0f be c0             	movsbl %al,%eax
f0100bbc:	8d 7c 07 a9          	lea    -0x57(%edi,%eax,1),%edi
f0100bc0:	eb 1e                	jmp    f0100be0 <xtoi+0x9a>
		else if (origin[i] >= 'A' && origin[i] <= 'F')
f0100bc2:	8d 48 bf             	lea    -0x41(%eax),%ecx
f0100bc5:	80 f9 05             	cmp    $0x5,%cl
f0100bc8:	77 09                	ja     f0100bd3 <xtoi+0x8d>
			temp += origin[i] - 'A' + 10;
f0100bca:	0f be c0             	movsbl %al,%eax
f0100bcd:	8d 7c 07 c9          	lea    -0x37(%edi,%eax,1),%edi
f0100bd1:	eb 0d                	jmp    f0100be0 <xtoi+0x9a>
f0100bd3:	8b 75 e4             	mov    -0x1c(%ebp),%esi
		else {
			*check = false;
f0100bd6:	c6 06 00             	movb   $0x0,(%esi)
			return -1;
f0100bd9:	bf ff ff ff ff       	mov    $0xffffffff,%edi
f0100bde:	eb 07                	jmp    f0100be7 <xtoi+0xa1>
	if ((origin[0] != '0') || (origin[1] != 'x' && origin[1] != 'X')) 
	{
		*check = false;
		return -1;
	}
	for (i = 2; i < len; i++) {
f0100be0:	83 c2 01             	add    $0x1,%edx
f0100be3:	39 d6                	cmp    %edx,%esi
f0100be5:	75 b2                	jne    f0100b99 <xtoi+0x53>
			*check = false;
			return -1;
		}
	}
	return temp;
}
f0100be7:	89 f8                	mov    %edi,%eax
f0100be9:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0100bec:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0100bef:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0100bf2:	89 ec                	mov    %ebp,%esp
f0100bf4:	5d                   	pop    %ebp
f0100bf5:	c3                   	ret    

f0100bf6 <pxtoi>:

bool pxtoi(uint32_t *va, char *origin) {
f0100bf6:	55                   	push   %ebp
f0100bf7:	89 e5                	mov    %esp,%ebp
f0100bf9:	83 ec 28             	sub    $0x28,%esp
	bool check = true;
f0100bfc:	c6 45 f7 01          	movb   $0x1,-0x9(%ebp)
	*va = xtoi(origin, &check);
f0100c00:	8d 45 f7             	lea    -0x9(%ebp),%eax
f0100c03:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100c07:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100c0a:	89 04 24             	mov    %eax,(%esp)
f0100c0d:	e8 34 ff ff ff       	call   f0100b46 <xtoi>
f0100c12:	8b 55 08             	mov    0x8(%ebp),%edx
f0100c15:	89 02                	mov    %eax,(%edx)
	if (!check) {
		cprintf("Address typing error\n");
		return false;
	}
	return true;
f0100c17:	b8 01 00 00 00       	mov    $0x1,%eax
}

bool pxtoi(uint32_t *va, char *origin) {
	bool check = true;
	*va = xtoi(origin, &check);
	if (!check) {
f0100c1c:	80 7d f7 00          	cmpb   $0x0,-0x9(%ebp)
f0100c20:	75 11                	jne    f0100c33 <pxtoi+0x3d>
		cprintf("Address typing error\n");
f0100c22:	c7 04 24 78 49 10 f0 	movl   $0xf0104978,(%esp)
f0100c29:	e8 4c 29 00 00       	call   f010357a <cprintf>
		return false;
f0100c2e:	b8 00 00 00 00       	mov    $0x0,%eax
	}
	return true;
}
f0100c33:	c9                   	leave  
f0100c34:	c3                   	ret    

f0100c35 <mon_showmapping>:
	} else cprintf("invalid command\n");
	return 0;

}
int mon_showmapping(int argc, char **argv, struct Trapframe *tf) 
{
f0100c35:	55                   	push   %ebp
f0100c36:	89 e5                	mov    %esp,%ebp
f0100c38:	53                   	push   %ebx
f0100c39:	83 ec 24             	sub    $0x24,%esp
f0100c3c:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	uintptr_t begin, end;
	if (!pxtoi(&begin, argv[1])) return 0;
f0100c3f:	8b 43 04             	mov    0x4(%ebx),%eax
f0100c42:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100c46:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100c49:	89 04 24             	mov    %eax,(%esp)
f0100c4c:	e8 a5 ff ff ff       	call   f0100bf6 <pxtoi>
f0100c51:	84 c0                	test   %al,%al
f0100c53:	0f 84 eb 00 00 00    	je     f0100d44 <mon_showmapping+0x10f>
//	cprintf("%d", !pxtoi(&begin, argv[1]));
	if (!pxtoi(&end, argv[2])) return 0;
f0100c59:	8b 43 08             	mov    0x8(%ebx),%eax
f0100c5c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100c60:	8d 45 f0             	lea    -0x10(%ebp),%eax
f0100c63:	89 04 24             	mov    %eax,(%esp)
f0100c66:	e8 8b ff ff ff       	call   f0100bf6 <pxtoi>
f0100c6b:	84 c0                	test   %al,%al
f0100c6d:	0f 84 d1 00 00 00    	je     f0100d44 <mon_showmapping+0x10f>
	begin = ROUNDUP(begin, PGSIZE); 
f0100c73:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0100c76:	81 c2 ff 0f 00 00    	add    $0xfff,%edx
f0100c7c:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100c82:	89 55 f4             	mov    %edx,-0xc(%ebp)
	end   = ROUNDUP(end, PGSIZE);
f0100c85:	8b 4d f0             	mov    -0x10(%ebp),%ecx
f0100c88:	81 c1 ff 0f 00 00    	add    $0xfff,%ecx
f0100c8e:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0100c94:	89 4d f0             	mov    %ecx,-0x10(%ebp)
	for (;begin <= end; begin += PGSIZE) {
f0100c97:	89 d0                	mov    %edx,%eax
f0100c99:	39 d1                	cmp    %edx,%ecx
f0100c9b:	0f 82 a3 00 00 00    	jb     f0100d44 <mon_showmapping+0x10f>
		pte_t *mapper = pgdir_walk(kern_pgdir, (void*) begin, 1);
f0100ca1:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0100ca8:	00 
f0100ca9:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100cad:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f0100cb2:	89 04 24             	mov    %eax,(%esp)
f0100cb5:	e8 ee 09 00 00       	call   f01016a8 <pgdir_walk>
f0100cba:	89 c3                	mov    %eax,%ebx
		cprintf("VA 0x%08x : ", begin);
f0100cbc:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100cbf:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100cc3:	c7 04 24 8e 49 10 f0 	movl   $0xf010498e,(%esp)
f0100cca:	e8 ab 28 00 00       	call   f010357a <cprintf>
		if (mapper != NULL) {
f0100ccf:	85 db                	test   %ebx,%ebx
f0100cd1:	74 41                	je     f0100d14 <mon_showmapping+0xdf>
			if (*mapper & PTE_P) {
f0100cd3:	8b 03                	mov    (%ebx),%eax
f0100cd5:	a8 01                	test   $0x1,%al
f0100cd7:	74 2d                	je     f0100d06 <mon_showmapping+0xd1>
				cprintf("mapping 0x%08x ", PTE_ADDR(*mapper));//, PADDR((void*)begin));
f0100cd9:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100cde:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100ce2:	c7 04 24 9b 49 10 f0 	movl   $0xf010499b,(%esp)
f0100ce9:	e8 8c 28 00 00       	call   f010357a <cprintf>
				printPermission((pte_t)*mapper);
f0100cee:	8b 03                	mov    (%ebx),%eax
f0100cf0:	89 04 24             	mov    %eax,(%esp)
f0100cf3:	e8 f9 fd ff ff       	call   f0100af1 <printPermission>
				cprintf("\n");
f0100cf8:	c7 04 24 70 58 10 f0 	movl   $0xf0105870,(%esp)
f0100cff:	e8 76 28 00 00       	call   f010357a <cprintf>
f0100d04:	eb 2a                	jmp    f0100d30 <mon_showmapping+0xfb>
			} else {
				cprintf("page not mapping\n");
f0100d06:	c7 04 24 ab 49 10 f0 	movl   $0xf01049ab,(%esp)
f0100d0d:	e8 68 28 00 00       	call   f010357a <cprintf>
f0100d12:	eb 1c                	jmp    f0100d30 <mon_showmapping+0xfb>
			}
		} else {
			panic("error, out of memory");
f0100d14:	c7 44 24 08 bd 49 10 	movl   $0xf01049bd,0x8(%esp)
f0100d1b:	f0 
f0100d1c:	c7 44 24 04 eb 00 00 	movl   $0xeb,0x4(%esp)
f0100d23:	00 
f0100d24:	c7 04 24 1a 49 10 f0 	movl   $0xf010491a,(%esp)
f0100d2b:	e8 64 f3 ff ff       	call   f0100094 <_panic>
	if (!pxtoi(&begin, argv[1])) return 0;
//	cprintf("%d", !pxtoi(&begin, argv[1]));
	if (!pxtoi(&end, argv[2])) return 0;
	begin = ROUNDUP(begin, PGSIZE); 
	end   = ROUNDUP(end, PGSIZE);
	for (;begin <= end; begin += PGSIZE) {
f0100d30:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100d33:	05 00 10 00 00       	add    $0x1000,%eax
f0100d38:	89 45 f4             	mov    %eax,-0xc(%ebp)
f0100d3b:	39 45 f0             	cmp    %eax,-0x10(%ebp)
f0100d3e:	0f 83 5d ff ff ff    	jae    f0100ca1 <mon_showmapping+0x6c>
		} else {
			panic("error, out of memory");
		}
	}
	return 0;
}
f0100d44:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d49:	83 c4 24             	add    $0x24,%esp
f0100d4c:	5b                   	pop    %ebx
f0100d4d:	5d                   	pop    %ebp
f0100d4e:	c3                   	ret    

f0100d4f <mon_dump>:
	pte_t *mapper = pgdir_walk(kern_pgdir, (void*) ((va >> PDXSHIFT) << PDXSHIFT), 1);
	cprintf("Page Table Entry Address : 0x%08x\n", mapper); */
	return 0;
}
#define POINT_SIZE 4
int mon_dump(int argc, char **argv, struct Trapframe *tf) {
f0100d4f:	55                   	push   %ebp
f0100d50:	89 e5                	mov    %esp,%ebp
f0100d52:	53                   	push   %ebx
f0100d53:	83 ec 24             	sub    $0x24,%esp
f0100d56:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	uint32_t begin, end;
	if (argc < 3) {
f0100d59:	83 7d 08 02          	cmpl   $0x2,0x8(%ebp)
f0100d5d:	7f 11                	jg     f0100d70 <mon_dump+0x21>
		cprintf("invalid command\n");
f0100d5f:	c7 04 24 d2 49 10 f0 	movl   $0xf01049d2,(%esp)
f0100d66:	e8 0f 28 00 00       	call   f010357a <cprintf>
		return 0;
f0100d6b:	e9 10 01 00 00       	jmp    f0100e80 <mon_dump+0x131>
	}
	if (!pxtoi(&begin, argv[2])) return 0;
f0100d70:	8b 43 08             	mov    0x8(%ebx),%eax
f0100d73:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100d77:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100d7a:	89 04 24             	mov    %eax,(%esp)
f0100d7d:	e8 74 fe ff ff       	call   f0100bf6 <pxtoi>
f0100d82:	84 c0                	test   %al,%al
f0100d84:	0f 84 f6 00 00 00    	je     f0100e80 <mon_dump+0x131>
	if (!pxtoi(&end, argv[3])) return 0;
f0100d8a:	8b 43 0c             	mov    0xc(%ebx),%eax
f0100d8d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100d91:	8d 45 f0             	lea    -0x10(%ebp),%eax
f0100d94:	89 04 24             	mov    %eax,(%esp)
f0100d97:	e8 5a fe ff ff       	call   f0100bf6 <pxtoi>
f0100d9c:	84 c0                	test   %al,%al
f0100d9e:	0f 84 dc 00 00 00    	je     f0100e80 <mon_dump+0x131>
	if (argv[1][0] == 'p') {
f0100da4:	8b 43 04             	mov    0x4(%ebx),%eax
f0100da7:	0f b6 00             	movzbl (%eax),%eax
f0100daa:	3c 70                	cmp    $0x70,%al
f0100dac:	0f 85 90 00 00 00    	jne    f0100e42 <mon_dump+0xf3>
		if (PGNUM(end) >= npages || PGNUM(end) >= npages){
f0100db2:	8b 55 f0             	mov    -0x10(%ebp),%edx
f0100db5:	8b 0d 84 99 11 f0    	mov    0xf0119984,%ecx
f0100dbb:	89 d0                	mov    %edx,%eax
f0100dbd:	c1 e8 0c             	shr    $0xc,%eax
f0100dc0:	39 c8                	cmp    %ecx,%eax
f0100dc2:	73 16                	jae    f0100dda <mon_dump+0x8b>
			cprintf("out of memory\n");
			return 0;	
		}
		for (;begin <= end; begin += POINT_SIZE)
f0100dc4:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100dc7:	39 c2                	cmp    %eax,%edx
f0100dc9:	0f 82 b1 00 00 00    	jb     f0100e80 <mon_dump+0x131>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100dcf:	89 c2                	mov    %eax,%edx
f0100dd1:	c1 ea 0c             	shr    $0xc,%edx
f0100dd4:	39 d1                	cmp    %edx,%ecx
f0100dd6:	77 40                	ja     f0100e18 <mon_dump+0xc9>
f0100dd8:	eb 1e                	jmp    f0100df8 <mon_dump+0xa9>
	}
	if (!pxtoi(&begin, argv[2])) return 0;
	if (!pxtoi(&end, argv[3])) return 0;
	if (argv[1][0] == 'p') {
		if (PGNUM(end) >= npages || PGNUM(end) >= npages){
			cprintf("out of memory\n");
f0100dda:	c7 04 24 e3 49 10 f0 	movl   $0xf01049e3,(%esp)
f0100de1:	e8 94 27 00 00       	call   f010357a <cprintf>
			return 0;	
f0100de6:	e9 95 00 00 00       	jmp    f0100e80 <mon_dump+0x131>
f0100deb:	89 c2                	mov    %eax,%edx
f0100ded:	c1 ea 0c             	shr    $0xc,%edx
f0100df0:	3b 15 84 99 11 f0    	cmp    0xf0119984,%edx
f0100df6:	72 20                	jb     f0100e18 <mon_dump+0xc9>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100df8:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100dfc:	c7 44 24 08 1c 4c 10 	movl   $0xf0104c1c,0x8(%esp)
f0100e03:	f0 
f0100e04:	c7 44 24 04 ce 00 00 	movl   $0xce,0x4(%esp)
f0100e0b:	00 
f0100e0c:	c7 04 24 1a 49 10 f0 	movl   $0xf010491a,(%esp)
f0100e13:	e8 7c f2 ff ff       	call   f0100094 <_panic>
		}
		for (;begin <= end; begin += POINT_SIZE)
			cprintf("pa 0x%08x : 0x%08x\n", begin, *((uint32_t*)KADDR(begin)));
f0100e18:	8b 90 00 00 00 f0    	mov    -0x10000000(%eax),%edx
f0100e1e:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100e22:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100e26:	c7 04 24 f2 49 10 f0 	movl   $0xf01049f2,(%esp)
f0100e2d:	e8 48 27 00 00       	call   f010357a <cprintf>
	if (argv[1][0] == 'p') {
		if (PGNUM(end) >= npages || PGNUM(end) >= npages){
			cprintf("out of memory\n");
			return 0;	
		}
		for (;begin <= end; begin += POINT_SIZE)
f0100e32:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100e35:	83 c0 04             	add    $0x4,%eax
f0100e38:	89 45 f4             	mov    %eax,-0xc(%ebp)
f0100e3b:	39 45 f0             	cmp    %eax,-0x10(%ebp)
f0100e3e:	73 ab                	jae    f0100deb <mon_dump+0x9c>
f0100e40:	eb 3e                	jmp    f0100e80 <mon_dump+0x131>
			cprintf("pa 0x%08x : 0x%08x\n", begin, *((uint32_t*)KADDR(begin)));
	} else if (argv[1][0] == 'v') {
f0100e42:	3c 76                	cmp    $0x76,%al
f0100e44:	75 2e                	jne    f0100e74 <mon_dump+0x125>
		for (;begin <= end; begin+=POINT_SIZE) {
f0100e46:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100e49:	3b 45 f0             	cmp    -0x10(%ebp),%eax
f0100e4c:	77 32                	ja     f0100e80 <mon_dump+0x131>
			cprintf("Va 0x%08x : 0x%08x\n", begin, *((uint32_t*)begin));
f0100e4e:	8b 10                	mov    (%eax),%edx
f0100e50:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100e54:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100e58:	c7 04 24 06 4a 10 f0 	movl   $0xf0104a06,(%esp)
f0100e5f:	e8 16 27 00 00       	call   f010357a <cprintf>
			return 0;	
		}
		for (;begin <= end; begin += POINT_SIZE)
			cprintf("pa 0x%08x : 0x%08x\n", begin, *((uint32_t*)KADDR(begin)));
	} else if (argv[1][0] == 'v') {
		for (;begin <= end; begin+=POINT_SIZE) {
f0100e64:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100e67:	83 c0 04             	add    $0x4,%eax
f0100e6a:	89 45 f4             	mov    %eax,-0xc(%ebp)
f0100e6d:	39 45 f0             	cmp    %eax,-0x10(%ebp)
f0100e70:	73 dc                	jae    f0100e4e <mon_dump+0xff>
f0100e72:	eb 0c                	jmp    f0100e80 <mon_dump+0x131>
			cprintf("Va 0x%08x : 0x%08x\n", begin, *((uint32_t*)begin));
		}
	} else cprintf("invalid command\n");
f0100e74:	c7 04 24 d2 49 10 f0 	movl   $0xf01049d2,(%esp)
f0100e7b:	e8 fa 26 00 00       	call   f010357a <cprintf>
	return 0;

}
f0100e80:	b8 00 00 00 00       	mov    $0x0,%eax
f0100e85:	83 c4 24             	add    $0x24,%esp
f0100e88:	5b                   	pop    %ebx
f0100e89:	5d                   	pop    %ebp
f0100e8a:	c3                   	ret    

f0100e8b <mon_changePermission>:
	}
	return true;
}

int mon_changePermission(int argc, char **argv, struct Trapframe *tf) 
{
f0100e8b:	55                   	push   %ebp
f0100e8c:	89 e5                	mov    %esp,%ebp
f0100e8e:	83 ec 38             	sub    $0x38,%esp
f0100e91:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0100e94:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0100e97:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0100e9a:	8b 7d 08             	mov    0x8(%ebp),%edi
f0100e9d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	if (argc < 2) {
f0100ea0:	83 ff 01             	cmp    $0x1,%edi
f0100ea3:	7f 11                	jg     f0100eb6 <mon_changePermission+0x2b>
		cprintf("invalid number of parameters\n");
f0100ea5:	c7 04 24 1a 4a 10 f0 	movl   $0xf0104a1a,(%esp)
f0100eac:	e8 c9 26 00 00       	call   f010357a <cprintf>
		return 0;
f0100eb1:	e9 f6 00 00 00       	jmp    f0100fac <mon_changePermission+0x121>
	}
	uintptr_t va;
	if (!pxtoi(&va,argv[1]))	return 0;
f0100eb6:	8b 43 04             	mov    0x4(%ebx),%eax
f0100eb9:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100ebd:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0100ec0:	89 04 24             	mov    %eax,(%esp)
f0100ec3:	e8 2e fd ff ff       	call   f0100bf6 <pxtoi>
f0100ec8:	84 c0                	test   %al,%al
f0100eca:	0f 84 dc 00 00 00    	je     f0100fac <mon_changePermission+0x121>
	
	pte_t* mapper = pgdir_walk(kern_pgdir, (void*) va, 1);
f0100ed0:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0100ed7:	00 
f0100ed8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100edb:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100edf:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f0100ee4:	89 04 24             	mov    %eax,(%esp)
f0100ee7:	e8 bc 07 00 00       	call   f01016a8 <pgdir_walk>
f0100eec:	89 c6                	mov    %eax,%esi
	if (!mapper) 
f0100eee:	85 c0                	test   %eax,%eax
f0100ef0:	75 1c                	jne    f0100f0e <mon_changePermission+0x83>
		panic("error, out of memory");
f0100ef2:	c7 44 24 08 bd 49 10 	movl   $0xf01049bd,0x8(%esp)
f0100ef9:	f0 
f0100efa:	c7 44 24 04 9f 00 00 	movl   $0x9f,0x4(%esp)
f0100f01:	00 
f0100f02:	c7 04 24 1a 49 10 f0 	movl   $0xf010491a,(%esp)
f0100f09:	e8 86 f1 ff ff       	call   f0100094 <_panic>
	physaddr_t pa = PTE_ADDR(*mapper);
	int perm = 0;
	//PTE_U PET_W PTE_P
	if (argc != 2) {
f0100f0e:	83 ff 02             	cmp    $0x2,%edi
f0100f11:	74 45                	je     f0100f58 <mon_changePermission+0xcd>
		if (argc != 5) {
f0100f13:	83 ff 05             	cmp    $0x5,%edi
f0100f16:	74 11                	je     f0100f29 <mon_changePermission+0x9e>
			cprintf("invalid number of parameters\n");
f0100f18:	c7 04 24 1a 4a 10 f0 	movl   $0xf0104a1a,(%esp)
f0100f1f:	e8 56 26 00 00       	call   f010357a <cprintf>
			return 0;
f0100f24:	e9 83 00 00 00       	jmp    f0100fac <mon_changePermission+0x121>
		}
		if (argv[2][0] == '1') perm |= PTE_U;
f0100f29:	8b 43 08             	mov    0x8(%ebx),%eax
	
	pte_t* mapper = pgdir_walk(kern_pgdir, (void*) va, 1);
	if (!mapper) 
		panic("error, out of memory");
	physaddr_t pa = PTE_ADDR(*mapper);
	int perm = 0;
f0100f2c:	80 38 31             	cmpb   $0x31,(%eax)
f0100f2f:	0f 94 c0             	sete   %al
f0100f32:	0f b6 c0             	movzbl %al,%eax
f0100f35:	89 c7                	mov    %eax,%edi
f0100f37:	c1 e7 02             	shl    $0x2,%edi
		if (argc != 5) {
			cprintf("invalid number of parameters\n");
			return 0;
		}
		if (argv[2][0] == '1') perm |= PTE_U;
		if (argv[3][0] == '1') perm |= PTE_W;
f0100f3a:	8b 53 0c             	mov    0xc(%ebx),%edx
f0100f3d:	89 f8                	mov    %edi,%eax
f0100f3f:	83 c8 02             	or     $0x2,%eax
f0100f42:	80 3a 31             	cmpb   $0x31,(%edx)
f0100f45:	0f 44 f8             	cmove  %eax,%edi
		if (argv[4][0] == '1') perm |= PTE_P;
f0100f48:	8b 53 10             	mov    0x10(%ebx),%edx
f0100f4b:	89 f8                	mov    %edi,%eax
f0100f4d:	83 c8 01             	or     $0x1,%eax
f0100f50:	80 3a 31             	cmpb   $0x31,(%edx)
f0100f53:	0f 44 f8             	cmove  %eax,%edi
f0100f56:	eb 05                	jmp    f0100f5d <mon_changePermission+0xd2>
	
	pte_t* mapper = pgdir_walk(kern_pgdir, (void*) va, 1);
	if (!mapper) 
		panic("error, out of memory");
	physaddr_t pa = PTE_ADDR(*mapper);
	int perm = 0;
f0100f58:	bf 00 00 00 00       	mov    $0x0,%edi
		if (argv[2][0] == '1') perm |= PTE_U;
		if (argv[3][0] == '1') perm |= PTE_W;
		if (argv[4][0] == '1') perm |= PTE_P;
	}
//	boot_map_region(kern_pgdir, va, PGSIZE, pa, perm);	
	cprintf("before change "); printPermission(*mapper); cprintf("\n");
f0100f5d:	c7 04 24 38 4a 10 f0 	movl   $0xf0104a38,(%esp)
f0100f64:	e8 11 26 00 00       	call   f010357a <cprintf>
f0100f69:	8b 06                	mov    (%esi),%eax
f0100f6b:	89 04 24             	mov    %eax,(%esp)
f0100f6e:	e8 7e fb ff ff       	call   f0100af1 <printPermission>
f0100f73:	c7 04 24 70 58 10 f0 	movl   $0xf0105870,(%esp)
f0100f7a:	e8 fb 25 00 00       	call   f010357a <cprintf>
	
	*mapper = PTE_ADDR(*mapper) | perm;
f0100f7f:	8b 06                	mov    (%esi),%eax
f0100f81:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100f86:	09 c7                	or     %eax,%edi
f0100f88:	89 3e                	mov    %edi,(%esi)
	cprintf("after change ");  printPermission(*mapper); cprintf("\n");
f0100f8a:	c7 04 24 47 4a 10 f0 	movl   $0xf0104a47,(%esp)
f0100f91:	e8 e4 25 00 00       	call   f010357a <cprintf>
f0100f96:	8b 06                	mov    (%esi),%eax
f0100f98:	89 04 24             	mov    %eax,(%esp)
f0100f9b:	e8 51 fb ff ff       	call   f0100af1 <printPermission>
f0100fa0:	c7 04 24 70 58 10 f0 	movl   $0xf0105870,(%esp)
f0100fa7:	e8 ce 25 00 00       	call   f010357a <cprintf>
	return 0;
}
f0100fac:	b8 00 00 00 00       	mov    $0x0,%eax
f0100fb1:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0100fb4:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0100fb7:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0100fba:	89 ec                	mov    %ebp,%esp
f0100fbc:	5d                   	pop    %ebp
f0100fbd:	c3                   	ret    

f0100fbe <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100fbe:	55                   	push   %ebp
f0100fbf:	89 e5                	mov    %esp,%ebp
f0100fc1:	57                   	push   %edi
f0100fc2:	56                   	push   %esi
f0100fc3:	53                   	push   %ebx
f0100fc4:	83 ec 5c             	sub    $0x5c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100fc7:	c7 04 24 74 4c 10 f0 	movl   $0xf0104c74,(%esp)
f0100fce:	e8 a7 25 00 00       	call   f010357a <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100fd3:	c7 04 24 98 4c 10 f0 	movl   $0xf0104c98,(%esp)
f0100fda:	e8 9b 25 00 00       	call   f010357a <cprintf>
  //	cprintf("x %d, y %x, z %d\n", x, y, z);
//	unsigned int i = 0x00646c72;
//	cprintf("H%x Wo%s", 57616, &i);

	while (1) {
		buf = readline("K> ");
f0100fdf:	c7 04 24 55 4a 10 f0 	movl   $0xf0104a55,(%esp)
f0100fe6:	e8 95 2e 00 00       	call   f0103e80 <readline>
f0100feb:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100fed:	85 c0                	test   %eax,%eax
f0100fef:	74 ee                	je     f0100fdf <monitor+0x21>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100ff1:	c7 45 a8 00 00 00 00 	movl   $0x0,-0x58(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100ff8:	be 00 00 00 00       	mov    $0x0,%esi
f0100ffd:	eb 06                	jmp    f0101005 <monitor+0x47>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100fff:	c6 03 00             	movb   $0x0,(%ebx)
f0101002:	83 c3 01             	add    $0x1,%ebx
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0101005:	0f b6 03             	movzbl (%ebx),%eax
f0101008:	84 c0                	test   %al,%al
f010100a:	74 6a                	je     f0101076 <monitor+0xb8>
f010100c:	0f be c0             	movsbl %al,%eax
f010100f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101013:	c7 04 24 59 4a 10 f0 	movl   $0xf0104a59,(%esp)
f010101a:	e8 b7 30 00 00       	call   f01040d6 <strchr>
f010101f:	85 c0                	test   %eax,%eax
f0101021:	75 dc                	jne    f0100fff <monitor+0x41>
			*buf++ = 0;
		if (*buf == 0)
f0101023:	80 3b 00             	cmpb   $0x0,(%ebx)
f0101026:	74 4e                	je     f0101076 <monitor+0xb8>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0101028:	83 fe 0f             	cmp    $0xf,%esi
f010102b:	75 16                	jne    f0101043 <monitor+0x85>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f010102d:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f0101034:	00 
f0101035:	c7 04 24 5e 4a 10 f0 	movl   $0xf0104a5e,(%esp)
f010103c:	e8 39 25 00 00       	call   f010357a <cprintf>
f0101041:	eb 9c                	jmp    f0100fdf <monitor+0x21>
			return 0;
		}
		argv[argc++] = buf;
f0101043:	89 5c b5 a8          	mov    %ebx,-0x58(%ebp,%esi,4)
f0101047:	83 c6 01             	add    $0x1,%esi
		while (*buf && !strchr(WHITESPACE, *buf))
f010104a:	0f b6 03             	movzbl (%ebx),%eax
f010104d:	84 c0                	test   %al,%al
f010104f:	75 0c                	jne    f010105d <monitor+0x9f>
f0101051:	eb b2                	jmp    f0101005 <monitor+0x47>
			buf++;
f0101053:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0101056:	0f b6 03             	movzbl (%ebx),%eax
f0101059:	84 c0                	test   %al,%al
f010105b:	74 a8                	je     f0101005 <monitor+0x47>
f010105d:	0f be c0             	movsbl %al,%eax
f0101060:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101064:	c7 04 24 59 4a 10 f0 	movl   $0xf0104a59,(%esp)
f010106b:	e8 66 30 00 00       	call   f01040d6 <strchr>
f0101070:	85 c0                	test   %eax,%eax
f0101072:	74 df                	je     f0101053 <monitor+0x95>
f0101074:	eb 8f                	jmp    f0101005 <monitor+0x47>
			buf++;
	}
	argv[argc] = 0;
f0101076:	c7 44 b5 a8 00 00 00 	movl   $0x0,-0x58(%ebp,%esi,4)
f010107d:	00 

	// Lookup and invoke the command
	if (argc == 0)
f010107e:	85 f6                	test   %esi,%esi
f0101080:	0f 84 59 ff ff ff    	je     f0100fdf <monitor+0x21>
f0101086:	bb 80 4e 10 f0       	mov    $0xf0104e80,%ebx
f010108b:	bf 00 00 00 00       	mov    $0x0,%edi
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0101090:	8b 03                	mov    (%ebx),%eax
f0101092:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101096:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0101099:	89 04 24             	mov    %eax,(%esp)
f010109c:	e8 ba 2f 00 00       	call   f010405b <strcmp>
f01010a1:	85 c0                	test   %eax,%eax
f01010a3:	75 24                	jne    f01010c9 <monitor+0x10b>
			return commands[i].func(argc, argv, tf);
f01010a5:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f01010a8:	8b 55 08             	mov    0x8(%ebp),%edx
f01010ab:	89 54 24 08          	mov    %edx,0x8(%esp)
f01010af:	8d 55 a8             	lea    -0x58(%ebp),%edx
f01010b2:	89 54 24 04          	mov    %edx,0x4(%esp)
f01010b6:	89 34 24             	mov    %esi,(%esp)
f01010b9:	ff 14 85 88 4e 10 f0 	call   *-0xfefb178(,%eax,4)
//	cprintf("H%x Wo%s", 57616, &i);

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f01010c0:	85 c0                	test   %eax,%eax
f01010c2:	78 28                	js     f01010ec <monitor+0x12e>
f01010c4:	e9 16 ff ff ff       	jmp    f0100fdf <monitor+0x21>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f01010c9:	83 c7 01             	add    $0x1,%edi
f01010cc:	83 c3 0c             	add    $0xc,%ebx
f01010cf:	83 ff 08             	cmp    $0x8,%edi
f01010d2:	75 bc                	jne    f0101090 <monitor+0xd2>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f01010d4:	8b 45 a8             	mov    -0x58(%ebp),%eax
f01010d7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01010db:	c7 04 24 7b 4a 10 f0 	movl   $0xf0104a7b,(%esp)
f01010e2:	e8 93 24 00 00       	call   f010357a <cprintf>
f01010e7:	e9 f3 fe ff ff       	jmp    f0100fdf <monitor+0x21>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f01010ec:	83 c4 5c             	add    $0x5c,%esp
f01010ef:	5b                   	pop    %ebx
f01010f0:	5e                   	pop    %esi
f01010f1:	5f                   	pop    %edi
f01010f2:	5d                   	pop    %ebp
f01010f3:	c3                   	ret    

f01010f4 <boot_alloc>:
// If we're out of memory, boot_alloc should panic.
// This function may ONLY be used during initialization,
// before the page_free_list list has been set up.
static void *
boot_alloc(uint32_t n)
{
f01010f4:	55                   	push   %ebp
f01010f5:	89 e5                	mov    %esp,%ebp
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f01010f7:	83 3d 5c 95 11 f0 00 	cmpl   $0x0,0xf011955c
f01010fe:	75 11                	jne    f0101111 <boot_alloc+0x1d>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0101100:	ba 8f a9 11 f0       	mov    $0xf011a98f,%edx
f0101105:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010110b:	89 15 5c 95 11 f0    	mov    %edx,0xf011955c
		void *temp = nextfree;
		nextfree += n;
		nextfree = ROUNDUP(nextfree, PGSIZE);
		return temp;
	} else if (n == 0) {
		return (void*)nextfree;
f0101111:	8b 15 5c 95 11 f0    	mov    0xf011955c,%edx
	// nextfree.  Make sure nextfree is kept aligned
	// to a multiple of PGSIZE.
	// page_alloc() is the real allocator.

	// LAB 2: Your code here.
	if (n > 0) {
f0101117:	85 c0                	test   %eax,%eax
f0101119:	74 11                	je     f010112c <boot_alloc+0x38>
		void *temp = nextfree;
		nextfree += n;
		nextfree = ROUNDUP(nextfree, PGSIZE);
f010111b:	8d 84 02 ff 0f 00 00 	lea    0xfff(%edx,%eax,1),%eax
f0101122:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0101127:	a3 5c 95 11 f0       	mov    %eax,0xf011955c
		return temp;
	} else if (n == 0) {
		return (void*)nextfree;
	}
	return NULL;
}
f010112c:	89 d0                	mov    %edx,%eax
f010112e:	5d                   	pop    %ebp
f010112f:	c3                   	ret    

f0101130 <check_va2pa>:
// this functionality for us!  We define our own version to help check
// the check_kern_pgdir() function; it shouldn't be used elsewhere.

static physaddr_t
check_va2pa(pde_t *pgdir, uintptr_t va)
{
f0101130:	55                   	push   %ebp
f0101131:	89 e5                	mov    %esp,%ebp
f0101133:	83 ec 18             	sub    $0x18,%esp
//	cprintf("!");
	pte_t *p;
	//cprintf("!");
	pgdir = &pgdir[PDX(va)];
f0101136:	89 d1                	mov    %edx,%ecx
f0101138:	c1 e9 16             	shr    $0x16,%ecx
	if (!(*pgdir & PTE_P))
f010113b:	8b 0c 88             	mov    (%eax,%ecx,4),%ecx
		return ~0;
f010113e:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
{
//	cprintf("!");
	pte_t *p;
	//cprintf("!");
	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f0101143:	f6 c1 01             	test   $0x1,%cl
f0101146:	74 57                	je     f010119f <check_va2pa+0x6f>
		return ~0;
 //	cprintf("!");	
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0101148:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010114e:	89 c8                	mov    %ecx,%eax
f0101150:	c1 e8 0c             	shr    $0xc,%eax
f0101153:	3b 05 84 99 11 f0    	cmp    0xf0119984,%eax
f0101159:	72 20                	jb     f010117b <check_va2pa+0x4b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010115b:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010115f:	c7 44 24 08 1c 4c 10 	movl   $0xf0104c1c,0x8(%esp)
f0101166:	f0 
f0101167:	c7 44 24 04 d9 02 00 	movl   $0x2d9,0x4(%esp)
f010116e:	00 
f010116f:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f0101176:	e8 19 ef ff ff       	call   f0100094 <_panic>
	if (!(p[PTX(va)] & PTE_P))
f010117b:	c1 ea 0c             	shr    $0xc,%edx
f010117e:	81 e2 ff 03 00 00    	and    $0x3ff,%edx
f0101184:	8b 84 91 00 00 00 f0 	mov    -0x10000000(%ecx,%edx,4),%eax
f010118b:	89 c2                	mov    %eax,%edx
f010118d:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0101190:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0101195:	85 d2                	test   %edx,%edx
f0101197:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f010119c:	0f 44 c2             	cmove  %edx,%eax
}
f010119f:	c9                   	leave  
f01011a0:	c3                   	ret    

f01011a1 <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f01011a1:	55                   	push   %ebp
f01011a2:	89 e5                	mov    %esp,%ebp
f01011a4:	83 ec 18             	sub    $0x18,%esp
f01011a7:	89 5d f8             	mov    %ebx,-0x8(%ebp)
f01011aa:	89 75 fc             	mov    %esi,-0x4(%ebp)
f01011ad:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f01011af:	89 04 24             	mov    %eax,(%esp)
f01011b2:	e8 55 23 00 00       	call   f010350c <mc146818_read>
f01011b7:	89 c6                	mov    %eax,%esi
f01011b9:	83 c3 01             	add    $0x1,%ebx
f01011bc:	89 1c 24             	mov    %ebx,(%esp)
f01011bf:	e8 48 23 00 00       	call   f010350c <mc146818_read>
f01011c4:	c1 e0 08             	shl    $0x8,%eax
f01011c7:	09 f0                	or     %esi,%eax
}
f01011c9:	8b 5d f8             	mov    -0x8(%ebp),%ebx
f01011cc:	8b 75 fc             	mov    -0x4(%ebp),%esi
f01011cf:	89 ec                	mov    %ebp,%esp
f01011d1:	5d                   	pop    %ebp
f01011d2:	c3                   	ret    

f01011d3 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f01011d3:	55                   	push   %ebp
f01011d4:	89 e5                	mov    %esp,%ebp
f01011d6:	57                   	push   %edi
f01011d7:	56                   	push   %esi
f01011d8:	53                   	push   %ebx
f01011d9:	83 ec 3c             	sub    $0x3c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f01011dc:	3c 01                	cmp    $0x1,%al
f01011de:	19 f6                	sbb    %esi,%esi
f01011e0:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
f01011e6:	83 c6 01             	add    $0x1,%esi
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f01011e9:	8b 1d 60 95 11 f0    	mov    0xf0119560,%ebx
f01011ef:	85 db                	test   %ebx,%ebx
f01011f1:	75 1c                	jne    f010120f <check_page_free_list+0x3c>
		panic("'page_free_list' is a null pointer!");
f01011f3:	c7 44 24 08 e0 4e 10 	movl   $0xf0104ee0,0x8(%esp)
f01011fa:	f0 
f01011fb:	c7 44 24 04 19 02 00 	movl   $0x219,0x4(%esp)
f0101202:	00 
f0101203:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f010120a:	e8 85 ee ff ff       	call   f0100094 <_panic>

	if (only_low_memory) {
f010120f:	84 c0                	test   %al,%al
f0101211:	74 50                	je     f0101263 <check_page_free_list+0x90>
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0101213:	8d 45 e0             	lea    -0x20(%ebp),%eax
f0101216:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0101219:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010121c:	89 45 dc             	mov    %eax,-0x24(%ebp)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010121f:	89 d8                	mov    %ebx,%eax
f0101221:	2b 05 8c 99 11 f0    	sub    0xf011998c,%eax
f0101227:	c1 e0 09             	shl    $0x9,%eax
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f010122a:	c1 e8 16             	shr    $0x16,%eax
f010122d:	39 c6                	cmp    %eax,%esi
f010122f:	0f 96 c0             	setbe  %al
f0101232:	0f b6 c0             	movzbl %al,%eax
			*tp[pagetype] = pp;
f0101235:	8b 54 85 d8          	mov    -0x28(%ebp,%eax,4),%edx
f0101239:	89 1a                	mov    %ebx,(%edx)
			tp[pagetype] = &pp->pp_link;
f010123b:	89 5c 85 d8          	mov    %ebx,-0x28(%ebp,%eax,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f010123f:	8b 1b                	mov    (%ebx),%ebx
f0101241:	85 db                	test   %ebx,%ebx
f0101243:	75 da                	jne    f010121f <check_page_free_list+0x4c>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0101245:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0101248:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f010124e:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0101251:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0101254:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0101256:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0101259:	89 1d 60 95 11 f0    	mov    %ebx,0xf0119560
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f010125f:	85 db                	test   %ebx,%ebx
f0101261:	74 67                	je     f01012ca <check_page_free_list+0xf7>
f0101263:	89 d8                	mov    %ebx,%eax
f0101265:	2b 05 8c 99 11 f0    	sub    0xf011998c,%eax
f010126b:	c1 f8 03             	sar    $0x3,%eax
f010126e:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0101271:	89 c2                	mov    %eax,%edx
f0101273:	c1 ea 16             	shr    $0x16,%edx
f0101276:	39 d6                	cmp    %edx,%esi
f0101278:	76 4a                	jbe    f01012c4 <check_page_free_list+0xf1>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010127a:	89 c2                	mov    %eax,%edx
f010127c:	c1 ea 0c             	shr    $0xc,%edx
f010127f:	3b 15 84 99 11 f0    	cmp    0xf0119984,%edx
f0101285:	72 20                	jb     f01012a7 <check_page_free_list+0xd4>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101287:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010128b:	c7 44 24 08 1c 4c 10 	movl   $0xf0104c1c,0x8(%esp)
f0101292:	f0 
f0101293:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f010129a:	00 
f010129b:	c7 04 24 e4 55 10 f0 	movl   $0xf01055e4,(%esp)
f01012a2:	e8 ed ed ff ff       	call   f0100094 <_panic>
			memset(page2kva(pp), 0x97, 128);
f01012a7:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
f01012ae:	00 
f01012af:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
f01012b6:	00 
	return (void *)(pa + KERNBASE);
f01012b7:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01012bc:	89 04 24             	mov    %eax,(%esp)
f01012bf:	e8 6d 2e 00 00       	call   f0104131 <memset>
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f01012c4:	8b 1b                	mov    (%ebx),%ebx
f01012c6:	85 db                	test   %ebx,%ebx
f01012c8:	75 99                	jne    f0101263 <check_page_free_list+0x90>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f01012ca:	b8 00 00 00 00       	mov    $0x0,%eax
f01012cf:	e8 20 fe ff ff       	call   f01010f4 <boot_alloc>
f01012d4:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f01012d7:	8b 15 60 95 11 f0    	mov    0xf0119560,%edx
f01012dd:	85 d2                	test   %edx,%edx
f01012df:	0f 84 f6 01 00 00    	je     f01014db <check_page_free_list+0x308>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f01012e5:	8b 1d 8c 99 11 f0    	mov    0xf011998c,%ebx
f01012eb:	39 da                	cmp    %ebx,%edx
f01012ed:	72 4d                	jb     f010133c <check_page_free_list+0x169>
		assert(pp < pages + npages);
f01012ef:	a1 84 99 11 f0       	mov    0xf0119984,%eax
f01012f4:	89 45 cc             	mov    %eax,-0x34(%ebp)
f01012f7:	8d 04 c3             	lea    (%ebx,%eax,8),%eax
f01012fa:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01012fd:	39 c2                	cmp    %eax,%edx
f01012ff:	73 64                	jae    f0101365 <check_page_free_list+0x192>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0101301:	89 5d d0             	mov    %ebx,-0x30(%ebp)
f0101304:	89 d0                	mov    %edx,%eax
f0101306:	29 d8                	sub    %ebx,%eax
f0101308:	a8 07                	test   $0x7,%al
f010130a:	0f 85 82 00 00 00    	jne    f0101392 <check_page_free_list+0x1bf>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101310:	c1 f8 03             	sar    $0x3,%eax
f0101313:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0101316:	85 c0                	test   %eax,%eax
f0101318:	0f 84 a2 00 00 00    	je     f01013c0 <check_page_free_list+0x1ed>
		assert(page2pa(pp) != IOPHYSMEM);
f010131e:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0101323:	0f 84 c2 00 00 00    	je     f01013eb <check_page_free_list+0x218>
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0101329:	be 00 00 00 00       	mov    $0x0,%esi
f010132e:	bf 00 00 00 00       	mov    $0x0,%edi
f0101333:	e9 d7 00 00 00       	jmp    f010140f <check_page_free_list+0x23c>
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0101338:	39 da                	cmp    %ebx,%edx
f010133a:	73 24                	jae    f0101360 <check_page_free_list+0x18d>
f010133c:	c7 44 24 0c f2 55 10 	movl   $0xf01055f2,0xc(%esp)
f0101343:	f0 
f0101344:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f010134b:	f0 
f010134c:	c7 44 24 04 33 02 00 	movl   $0x233,0x4(%esp)
f0101353:	00 
f0101354:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f010135b:	e8 34 ed ff ff       	call   f0100094 <_panic>
		assert(pp < pages + npages);
f0101360:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0101363:	72 24                	jb     f0101389 <check_page_free_list+0x1b6>
f0101365:	c7 44 24 0c 13 56 10 	movl   $0xf0105613,0xc(%esp)
f010136c:	f0 
f010136d:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f0101374:	f0 
f0101375:	c7 44 24 04 34 02 00 	movl   $0x234,0x4(%esp)
f010137c:	00 
f010137d:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f0101384:	e8 0b ed ff ff       	call   f0100094 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0101389:	89 d0                	mov    %edx,%eax
f010138b:	2b 45 d0             	sub    -0x30(%ebp),%eax
f010138e:	a8 07                	test   $0x7,%al
f0101390:	74 24                	je     f01013b6 <check_page_free_list+0x1e3>
f0101392:	c7 44 24 0c 04 4f 10 	movl   $0xf0104f04,0xc(%esp)
f0101399:	f0 
f010139a:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f01013a1:	f0 
f01013a2:	c7 44 24 04 35 02 00 	movl   $0x235,0x4(%esp)
f01013a9:	00 
f01013aa:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f01013b1:	e8 de ec ff ff       	call   f0100094 <_panic>
f01013b6:	c1 f8 03             	sar    $0x3,%eax
f01013b9:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f01013bc:	85 c0                	test   %eax,%eax
f01013be:	75 24                	jne    f01013e4 <check_page_free_list+0x211>
f01013c0:	c7 44 24 0c 27 56 10 	movl   $0xf0105627,0xc(%esp)
f01013c7:	f0 
f01013c8:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f01013cf:	f0 
f01013d0:	c7 44 24 04 38 02 00 	movl   $0x238,0x4(%esp)
f01013d7:	00 
f01013d8:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f01013df:	e8 b0 ec ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f01013e4:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f01013e9:	75 24                	jne    f010140f <check_page_free_list+0x23c>
f01013eb:	c7 44 24 0c 38 56 10 	movl   $0xf0105638,0xc(%esp)
f01013f2:	f0 
f01013f3:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f01013fa:	f0 
f01013fb:	c7 44 24 04 39 02 00 	movl   $0x239,0x4(%esp)
f0101402:	00 
f0101403:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f010140a:	e8 85 ec ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f010140f:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0101414:	75 24                	jne    f010143a <check_page_free_list+0x267>
f0101416:	c7 44 24 0c 38 4f 10 	movl   $0xf0104f38,0xc(%esp)
f010141d:	f0 
f010141e:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f0101425:	f0 
f0101426:	c7 44 24 04 3a 02 00 	movl   $0x23a,0x4(%esp)
f010142d:	00 
f010142e:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f0101435:	e8 5a ec ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f010143a:	3d 00 00 10 00       	cmp    $0x100000,%eax
f010143f:	75 24                	jne    f0101465 <check_page_free_list+0x292>
f0101441:	c7 44 24 0c 51 56 10 	movl   $0xf0105651,0xc(%esp)
f0101448:	f0 
f0101449:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f0101450:	f0 
f0101451:	c7 44 24 04 3b 02 00 	movl   $0x23b,0x4(%esp)
f0101458:	00 
f0101459:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f0101460:	e8 2f ec ff ff       	call   f0100094 <_panic>
f0101465:	89 c1                	mov    %eax,%ecx
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0101467:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f010146c:	76 57                	jbe    f01014c5 <check_page_free_list+0x2f2>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010146e:	c1 e8 0c             	shr    $0xc,%eax
f0101471:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0101474:	77 20                	ja     f0101496 <check_page_free_list+0x2c3>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101476:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f010147a:	c7 44 24 08 1c 4c 10 	movl   $0xf0104c1c,0x8(%esp)
f0101481:	f0 
f0101482:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0101489:	00 
f010148a:	c7 04 24 e4 55 10 f0 	movl   $0xf01055e4,(%esp)
f0101491:	e8 fe eb ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0101496:	81 e9 00 00 00 10    	sub    $0x10000000,%ecx
f010149c:	39 4d c8             	cmp    %ecx,-0x38(%ebp)
f010149f:	76 29                	jbe    f01014ca <check_page_free_list+0x2f7>
f01014a1:	c7 44 24 0c 5c 4f 10 	movl   $0xf0104f5c,0xc(%esp)
f01014a8:	f0 
f01014a9:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f01014b0:	f0 
f01014b1:	c7 44 24 04 3c 02 00 	movl   $0x23c,0x4(%esp)
f01014b8:	00 
f01014b9:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f01014c0:	e8 cf eb ff ff       	call   f0100094 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f01014c5:	83 c7 01             	add    $0x1,%edi
f01014c8:	eb 03                	jmp    f01014cd <check_page_free_list+0x2fa>
		else
			++nfree_extmem;
f01014ca:	83 c6 01             	add    $0x1,%esi
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f01014cd:	8b 12                	mov    (%edx),%edx
f01014cf:	85 d2                	test   %edx,%edx
f01014d1:	0f 85 61 fe ff ff    	jne    f0101338 <check_page_free_list+0x165>
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f01014d7:	85 ff                	test   %edi,%edi
f01014d9:	7f 24                	jg     f01014ff <check_page_free_list+0x32c>
f01014db:	c7 44 24 0c 6b 56 10 	movl   $0xf010566b,0xc(%esp)
f01014e2:	f0 
f01014e3:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f01014ea:	f0 
f01014eb:	c7 44 24 04 44 02 00 	movl   $0x244,0x4(%esp)
f01014f2:	00 
f01014f3:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f01014fa:	e8 95 eb ff ff       	call   f0100094 <_panic>
	assert(nfree_extmem > 0);
f01014ff:	85 f6                	test   %esi,%esi
f0101501:	7f 24                	jg     f0101527 <check_page_free_list+0x354>
f0101503:	c7 44 24 0c 7d 56 10 	movl   $0xf010567d,0xc(%esp)
f010150a:	f0 
f010150b:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f0101512:	f0 
f0101513:	c7 44 24 04 45 02 00 	movl   $0x245,0x4(%esp)
f010151a:	00 
f010151b:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f0101522:	e8 6d eb ff ff       	call   f0100094 <_panic>
}
f0101527:	83 c4 3c             	add    $0x3c,%esp
f010152a:	5b                   	pop    %ebx
f010152b:	5e                   	pop    %esi
f010152c:	5f                   	pop    %edi
f010152d:	5d                   	pop    %ebp
f010152e:	c3                   	ret    

f010152f <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f010152f:	55                   	push   %ebp
f0101530:	89 e5                	mov    %esp,%ebp
f0101532:	56                   	push   %esi
f0101533:	53                   	push   %ebx
f0101534:	83 ec 10             	sub    $0x10,%esp
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	size_t low = IOPHYSMEM / PGSIZE;	
	size_t top = (PADDR(boot_alloc(0))) / PGSIZE;
f0101537:	b8 00 00 00 00       	mov    $0x0,%eax
f010153c:	e8 b3 fb ff ff       	call   f01010f4 <boot_alloc>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0101541:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101546:	77 20                	ja     f0101568 <page_init+0x39>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101548:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010154c:	c7 44 24 08 a4 4f 10 	movl   $0xf0104fa4,0x8(%esp)
f0101553:	f0 
f0101554:	c7 44 24 04 05 01 00 	movl   $0x105,0x4(%esp)
f010155b:	00 
f010155c:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f0101563:	e8 2c eb ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0101568:	8d 98 00 00 00 10    	lea    0x10000000(%eax),%ebx
f010156e:	c1 eb 0c             	shr    $0xc,%ebx
//	cprintf("!!%d %d %d\n", npages, low, top);
//	cprintf("00");
	page_free_list = NULL;
f0101571:	c7 05 60 95 11 f0 00 	movl   $0x0,0xf0119560
f0101578:	00 00 00 
	for (i = 0; i < npages; i++) {
f010157b:	83 3d 84 99 11 f0 00 	cmpl   $0x0,0xf0119984
f0101582:	74 64                	je     f01015e8 <page_init+0xb9>
f0101584:	b8 00 00 00 00       	mov    $0x0,%eax
f0101589:	ba 00 00 00 00       	mov    $0x0,%edx
		if (i == 0 || (i >= low && i < top)){
f010158e:	85 d2                	test   %edx,%edx
f0101590:	74 0c                	je     f010159e <page_init+0x6f>
f0101592:	81 fa 9f 00 00 00    	cmp    $0x9f,%edx
f0101598:	76 1f                	jbe    f01015b9 <page_init+0x8a>
f010159a:	39 da                	cmp    %ebx,%edx
f010159c:	73 1b                	jae    f01015b9 <page_init+0x8a>
			pages[i].pp_ref = 1;
f010159e:	8d 0c d5 00 00 00 00 	lea    0x0(,%edx,8),%ecx
f01015a5:	03 0d 8c 99 11 f0    	add    0xf011998c,%ecx
f01015ab:	66 c7 41 04 01 00    	movw   $0x1,0x4(%ecx)
			pages[i].pp_link = NULL;
f01015b1:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
			continue;
f01015b7:	eb 1f                	jmp    f01015d8 <page_init+0xa9>
		}
		pages[i].pp_ref = 0;
f01015b9:	8d 0c d5 00 00 00 00 	lea    0x0(,%edx,8),%ecx
f01015c0:	8b 35 8c 99 11 f0    	mov    0xf011998c,%esi
f01015c6:	66 c7 44 0e 04 00 00 	movw   $0x0,0x4(%esi,%ecx,1)
	//	cprintf("%d\n", i);
		pages[i].pp_link = page_free_list;
f01015cd:	89 04 d6             	mov    %eax,(%esi,%edx,8)
		page_free_list = &pages[i];
f01015d0:	89 c8                	mov    %ecx,%eax
f01015d2:	03 05 8c 99 11 f0    	add    0xf011998c,%eax
	size_t low = IOPHYSMEM / PGSIZE;	
	size_t top = (PADDR(boot_alloc(0))) / PGSIZE;
//	cprintf("!!%d %d %d\n", npages, low, top);
//	cprintf("00");
	page_free_list = NULL;
	for (i = 0; i < npages; i++) {
f01015d8:	83 c2 01             	add    $0x1,%edx
f01015db:	39 15 84 99 11 f0    	cmp    %edx,0xf0119984
f01015e1:	77 ab                	ja     f010158e <page_init+0x5f>
f01015e3:	a3 60 95 11 f0       	mov    %eax,0xf0119560
		pages[i].pp_ref = 0;
	//	cprintf("%d\n", i);
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
}
f01015e8:	83 c4 10             	add    $0x10,%esp
f01015eb:	5b                   	pop    %ebx
f01015ec:	5e                   	pop    %esi
f01015ed:	5d                   	pop    %ebp
f01015ee:	c3                   	ret    

f01015ef <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f01015ef:	55                   	push   %ebp
f01015f0:	89 e5                	mov    %esp,%ebp
f01015f2:	83 ec 18             	sub    $0x18,%esp
	// Fill this function in
	if (page_free_list != NULL) {
f01015f5:	a1 60 95 11 f0       	mov    0xf0119560,%eax
f01015fa:	85 c0                	test   %eax,%eax
f01015fc:	74 6b                	je     f0101669 <page_alloc+0x7a>
		if (alloc_flags & ALLOC_ZERO) {
f01015fe:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0101602:	74 56                	je     f010165a <page_alloc+0x6b>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101604:	2b 05 8c 99 11 f0    	sub    0xf011998c,%eax
f010160a:	c1 f8 03             	sar    $0x3,%eax
f010160d:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101610:	89 c2                	mov    %eax,%edx
f0101612:	c1 ea 0c             	shr    $0xc,%edx
f0101615:	3b 15 84 99 11 f0    	cmp    0xf0119984,%edx
f010161b:	72 20                	jb     f010163d <page_alloc+0x4e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010161d:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101621:	c7 44 24 08 1c 4c 10 	movl   $0xf0104c1c,0x8(%esp)
f0101628:	f0 
f0101629:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0101630:	00 
f0101631:	c7 04 24 e4 55 10 f0 	movl   $0xf01055e4,(%esp)
f0101638:	e8 57 ea ff ff       	call   f0100094 <_panic>
//			cprintf("\n````!!!");
			memset(page2kva(page_free_list), 0, PGSIZE);
f010163d:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101644:	00 
f0101645:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010164c:	00 
	return (void *)(pa + KERNBASE);
f010164d:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101652:	89 04 24             	mov    %eax,(%esp)
f0101655:	e8 d7 2a 00 00       	call   f0104131 <memset>
		}
		struct PageInfo* temp = page_free_list;
f010165a:	a1 60 95 11 f0       	mov    0xf0119560,%eax
		page_free_list = page_free_list->pp_link;
f010165f:	8b 10                	mov    (%eax),%edx
f0101661:	89 15 60 95 11 f0    	mov    %edx,0xf0119560
//		return (struct PageInfo*) page_free_list;
		return temp;
f0101667:	eb 05                	jmp    f010166e <page_alloc+0x7f>
	}
	return NULL;
f0101669:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010166e:	c9                   	leave  
f010166f:	c3                   	ret    

f0101670 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0101670:	55                   	push   %ebp
f0101671:	89 e5                	mov    %esp,%ebp
f0101673:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	pp->pp_link = page_free_list;
f0101676:	8b 15 60 95 11 f0    	mov    0xf0119560,%edx
f010167c:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f010167e:	a3 60 95 11 f0       	mov    %eax,0xf0119560
}
f0101683:	5d                   	pop    %ebp
f0101684:	c3                   	ret    

f0101685 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0101685:	55                   	push   %ebp
f0101686:	89 e5                	mov    %esp,%ebp
f0101688:	83 ec 04             	sub    $0x4,%esp
f010168b:	8b 45 08             	mov    0x8(%ebp),%eax
	if (--pp->pp_ref == 0)
f010168e:	0f b7 50 04          	movzwl 0x4(%eax),%edx
f0101692:	83 ea 01             	sub    $0x1,%edx
f0101695:	66 89 50 04          	mov    %dx,0x4(%eax)
f0101699:	66 85 d2             	test   %dx,%dx
f010169c:	75 08                	jne    f01016a6 <page_decref+0x21>
		page_free(pp);
f010169e:	89 04 24             	mov    %eax,(%esp)
f01016a1:	e8 ca ff ff ff       	call   f0101670 <page_free>
}
f01016a6:	c9                   	leave  
f01016a7:	c3                   	ret    

f01016a8 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f01016a8:	55                   	push   %ebp
f01016a9:	89 e5                	mov    %esp,%ebp
f01016ab:	56                   	push   %esi
f01016ac:	53                   	push   %ebx
f01016ad:	83 ec 10             	sub    $0x10,%esp
f01016b0:	8b 75 0c             	mov    0xc(%ebp),%esi
	// Fill this function in
	bool exist = false;
	pte_t *ptdir;
	if	(pgdir[PDX(va)] & PTE_P) {
f01016b3:	89 f3                	mov    %esi,%ebx
f01016b5:	c1 eb 16             	shr    $0x16,%ebx
f01016b8:	c1 e3 02             	shl    $0x2,%ebx
f01016bb:	03 5d 08             	add    0x8(%ebp),%ebx
f01016be:	8b 03                	mov    (%ebx),%eax
f01016c0:	a8 01                	test   $0x1,%al
f01016c2:	74 47                	je     f010170b <pgdir_walk+0x63>
//		pte_t * ptdir = (pte_t*) (PGNUM(*(pgdir + PDX(va))) << PGSHIFT);
		ptdir = (pte_t*) KADDR(PTE_ADDR(pgdir[PDX(va)]));
f01016c4:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01016c9:	89 c2                	mov    %eax,%edx
f01016cb:	c1 ea 0c             	shr    $0xc,%edx
f01016ce:	3b 15 84 99 11 f0    	cmp    0xf0119984,%edx
f01016d4:	72 20                	jb     f01016f6 <pgdir_walk+0x4e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01016d6:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01016da:	c7 44 24 08 1c 4c 10 	movl   $0xf0104c1c,0x8(%esp)
f01016e1:	f0 
f01016e2:	c7 44 24 04 65 01 00 	movl   $0x165,0x4(%esp)
f01016e9:	00 
f01016ea:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f01016f1:	e8 9e e9 ff ff       	call   f0100094 <_panic>
//		pgdir[PDX(va)];
//		cprintf("%d", va);
		return ptdir + PTX(va);
f01016f6:	c1 ee 0a             	shr    $0xa,%esi
f01016f9:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f01016ff:	8d 84 30 00 00 00 f0 	lea    -0x10000000(%eax,%esi,1),%eax
f0101706:	e9 85 00 00 00       	jmp    f0101790 <pgdir_walk+0xe8>
	} else {
		if (create) {
f010170b:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f010170f:	74 73                	je     f0101784 <pgdir_walk+0xdc>
			struct PageInfo * temp = page_alloc(ALLOC_ZERO);
f0101711:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101718:	e8 d2 fe ff ff       	call   f01015ef <page_alloc>
			if (temp == NULL) return NULL;
f010171d:	85 c0                	test   %eax,%eax
f010171f:	74 6a                	je     f010178b <pgdir_walk+0xe3>
			temp->pp_ref++;
f0101721:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101726:	89 c2                	mov    %eax,%edx
f0101728:	2b 15 8c 99 11 f0    	sub    0xf011998c,%edx
f010172e:	c1 fa 03             	sar    $0x3,%edx
f0101731:	c1 e2 0c             	shl    $0xc,%edx
			pgdir[PDX(va)] = page2pa(temp) | PTE_P | PTE_U | PTE_W;
f0101734:	83 ca 07             	or     $0x7,%edx
f0101737:	89 13                	mov    %edx,(%ebx)
f0101739:	2b 05 8c 99 11 f0    	sub    0xf011998c,%eax
f010173f:	c1 f8 03             	sar    $0x3,%eax
f0101742:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101745:	89 c2                	mov    %eax,%edx
f0101747:	c1 ea 0c             	shr    $0xc,%edx
f010174a:	3b 15 84 99 11 f0    	cmp    0xf0119984,%edx
f0101750:	72 20                	jb     f0101772 <pgdir_walk+0xca>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101752:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101756:	c7 44 24 08 1c 4c 10 	movl   $0xf0104c1c,0x8(%esp)
f010175d:	f0 
f010175e:	c7 44 24 04 6f 01 00 	movl   $0x16f,0x4(%esp)
f0101765:	00 
f0101766:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f010176d:	e8 22 e9 ff ff       	call   f0100094 <_panic>
			ptdir = (pte_t*) KADDR(page2pa(temp));
			return ptdir + PTX(va);
f0101772:	c1 ee 0a             	shr    $0xa,%esi
f0101775:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f010177b:	8d 84 30 00 00 00 f0 	lea    -0x10000000(%eax,%esi,1),%eax
f0101782:	eb 0c                	jmp    f0101790 <pgdir_walk+0xe8>
		} else return NULL;
f0101784:	b8 00 00 00 00       	mov    $0x0,%eax
f0101789:	eb 05                	jmp    f0101790 <pgdir_walk+0xe8>
//		cprintf("%d", va);
		return ptdir + PTX(va);
	} else {
		if (create) {
			struct PageInfo * temp = page_alloc(ALLOC_ZERO);
			if (temp == NULL) return NULL;
f010178b:	b8 00 00 00 00       	mov    $0x0,%eax
			return ptdir + PTX(va);
		} else return NULL;
	}
	//temp + PTXSHIFT(va)
	return NULL;
}
f0101790:	83 c4 10             	add    $0x10,%esp
f0101793:	5b                   	pop    %ebx
f0101794:	5e                   	pop    %esi
f0101795:	5d                   	pop    %ebp
f0101796:	c3                   	ret    

f0101797 <boot_map_region>:
// mapped pages.
// 
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f0101797:	55                   	push   %ebp
f0101798:	89 e5                	mov    %esp,%ebp
f010179a:	57                   	push   %edi
f010179b:	56                   	push   %esi
f010179c:	53                   	push   %ebx
f010179d:	83 ec 2c             	sub    $0x2c,%esp
f01017a0:	89 c7                	mov    %eax,%edi
f01017a2:	89 d3                	mov    %edx,%ebx
f01017a4:	8b 75 08             	mov    0x8(%ebp),%esi
	// Fill this function in
	uintptr_t end = va + size;
f01017a7:	01 d1                	add    %edx,%ecx
f01017a9:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	pte_t* now;
	for (;va != end; va += PGSIZE, pa += PGSIZE) {
f01017ac:	39 ca                	cmp    %ecx,%edx
f01017ae:	74 5b                	je     f010180b <boot_map_region+0x74>
		now = pgdir_walk(pgdir, (void*)va, 1);
		if (now == NULL)
			panic("stopped");
		*now = PTE_ADDR(pa) | perm | PTE_P;
f01017b0:	8b 45 0c             	mov    0xc(%ebp),%eax
f01017b3:	83 c8 01             	or     $0x1,%eax
f01017b6:	89 45 e0             	mov    %eax,-0x20(%ebp)
{
	// Fill this function in
	uintptr_t end = va + size;
	pte_t* now;
	for (;va != end; va += PGSIZE, pa += PGSIZE) {
		now = pgdir_walk(pgdir, (void*)va, 1);
f01017b9:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01017c0:	00 
f01017c1:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01017c5:	89 3c 24             	mov    %edi,(%esp)
f01017c8:	e8 db fe ff ff       	call   f01016a8 <pgdir_walk>
		if (now == NULL)
f01017cd:	85 c0                	test   %eax,%eax
f01017cf:	75 1c                	jne    f01017ed <boot_map_region+0x56>
			panic("stopped");
f01017d1:	c7 44 24 08 8e 56 10 	movl   $0xf010568e,0x8(%esp)
f01017d8:	f0 
f01017d9:	c7 44 24 04 8a 01 00 	movl   $0x18a,0x4(%esp)
f01017e0:	00 
f01017e1:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f01017e8:	e8 a7 e8 ff ff       	call   f0100094 <_panic>
		*now = PTE_ADDR(pa) | perm | PTE_P;
f01017ed:	89 f2                	mov    %esi,%edx
f01017ef:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01017f5:	0b 55 e0             	or     -0x20(%ebp),%edx
f01017f8:	89 10                	mov    %edx,(%eax)
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	uintptr_t end = va + size;
	pte_t* now;
	for (;va != end; va += PGSIZE, pa += PGSIZE) {
f01017fa:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f0101800:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0101806:	39 5d e4             	cmp    %ebx,-0x1c(%ebp)
f0101809:	75 ae                	jne    f01017b9 <boot_map_region+0x22>
		now = pgdir_walk(pgdir, (void*)va, 1);
		if (now == NULL)
			panic("stopped");
		*now = PTE_ADDR(pa) | perm | PTE_P;
	}
}
f010180b:	83 c4 2c             	add    $0x2c,%esp
f010180e:	5b                   	pop    %ebx
f010180f:	5e                   	pop    %esi
f0101810:	5f                   	pop    %edi
f0101811:	5d                   	pop    %ebp
f0101812:	c3                   	ret    

f0101813 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0101813:	55                   	push   %ebp
f0101814:	89 e5                	mov    %esp,%ebp
f0101816:	53                   	push   %ebx
f0101817:	83 ec 14             	sub    $0x14,%esp
f010181a:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// Fill this function in
	pte_t* now = pgdir_walk(pgdir, va, 0);
f010181d:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101824:	00 
f0101825:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101828:	89 44 24 04          	mov    %eax,0x4(%esp)
f010182c:	8b 45 08             	mov    0x8(%ebp),%eax
f010182f:	89 04 24             	mov    %eax,(%esp)
f0101832:	e8 71 fe ff ff       	call   f01016a8 <pgdir_walk>
	if (now != NULL) {
f0101837:	85 c0                	test   %eax,%eax
f0101839:	74 3a                	je     f0101875 <page_lookup+0x62>
		if (pte_store != NULL) {
f010183b:	85 db                	test   %ebx,%ebx
f010183d:	74 02                	je     f0101841 <page_lookup+0x2e>
			*pte_store = now;
f010183f:	89 03                	mov    %eax,(%ebx)
		}
		return pa2page(PTE_ADDR(*now));
f0101841:	8b 00                	mov    (%eax),%eax
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101843:	c1 e8 0c             	shr    $0xc,%eax
f0101846:	3b 05 84 99 11 f0    	cmp    0xf0119984,%eax
f010184c:	72 1c                	jb     f010186a <page_lookup+0x57>
		panic("pa2page called with invalid pa");
f010184e:	c7 44 24 08 c8 4f 10 	movl   $0xf0104fc8,0x8(%esp)
f0101855:	f0 
f0101856:	c7 44 24 04 4b 00 00 	movl   $0x4b,0x4(%esp)
f010185d:	00 
f010185e:	c7 04 24 e4 55 10 f0 	movl   $0xf01055e4,(%esp)
f0101865:	e8 2a e8 ff ff       	call   f0100094 <_panic>
	return &pages[PGNUM(pa)];
f010186a:	c1 e0 03             	shl    $0x3,%eax
f010186d:	03 05 8c 99 11 f0    	add    0xf011998c,%eax
f0101873:	eb 05                	jmp    f010187a <page_lookup+0x67>
	}
	return NULL;
f0101875:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010187a:	83 c4 14             	add    $0x14,%esp
f010187d:	5b                   	pop    %ebx
f010187e:	5d                   	pop    %ebp
f010187f:	c3                   	ret    

f0101880 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0101880:	55                   	push   %ebp
f0101881:	89 e5                	mov    %esp,%ebp
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0101883:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101886:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f0101889:	5d                   	pop    %ebp
f010188a:	c3                   	ret    

f010188b <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f010188b:	55                   	push   %ebp
f010188c:	89 e5                	mov    %esp,%ebp
f010188e:	83 ec 28             	sub    $0x28,%esp
f0101891:	89 5d f8             	mov    %ebx,-0x8(%ebp)
f0101894:	89 75 fc             	mov    %esi,-0x4(%ebp)
f0101897:	8b 75 08             	mov    0x8(%ebp),%esi
f010189a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	// Fill this function in
//	if (pgdir & PTE_P == 1) {
	pte_t* now;	
	struct PageInfo* temp = page_lookup(pgdir, va, &now);
f010189d:	8d 45 f4             	lea    -0xc(%ebp),%eax
f01018a0:	89 44 24 08          	mov    %eax,0x8(%esp)
f01018a4:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01018a8:	89 34 24             	mov    %esi,(%esp)
f01018ab:	e8 63 ff ff ff       	call   f0101813 <page_lookup>
	if (temp != NULL) {
f01018b0:	85 c0                	test   %eax,%eax
f01018b2:	74 19                	je     f01018cd <page_remove+0x42>
//		cprintf("%d", now);
		if (*now & PTE_P) {
f01018b4:	8b 55 f4             	mov    -0xc(%ebp),%edx
f01018b7:	f6 02 01             	testb  $0x1,(%edx)
f01018ba:	74 08                	je     f01018c4 <page_remove+0x39>
//			cprintf("subtraction finish!");
			page_decref(temp);
f01018bc:	89 04 24             	mov    %eax,(%esp)
f01018bf:	e8 c1 fd ff ff       	call   f0101685 <page_decref>
		}
		//page_decref(temp);
	//}
		*now = 0;
f01018c4:	8b 45 f4             	mov    -0xc(%ebp),%eax
f01018c7:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	}
	tlb_invalidate(pgdir, va);
f01018cd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01018d1:	89 34 24             	mov    %esi,(%esp)
f01018d4:	e8 a7 ff ff ff       	call   f0101880 <tlb_invalidate>

}
f01018d9:	8b 5d f8             	mov    -0x8(%ebp),%ebx
f01018dc:	8b 75 fc             	mov    -0x4(%ebp),%esi
f01018df:	89 ec                	mov    %ebp,%esp
f01018e1:	5d                   	pop    %ebp
f01018e2:	c3                   	ret    

f01018e3 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa隐式声明函数‘page_walk’.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f01018e3:	55                   	push   %ebp
f01018e4:	89 e5                	mov    %esp,%ebp
f01018e6:	83 ec 28             	sub    $0x28,%esp
f01018e9:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f01018ec:	89 75 f8             	mov    %esi,-0x8(%ebp)
f01018ef:	89 7d fc             	mov    %edi,-0x4(%ebp)
f01018f2:	8b 75 0c             	mov    0xc(%ebp),%esi
f01018f5:	8b 7d 10             	mov    0x10(%ebp),%edi
	// Fill this function in
	pte_t* now = pgdir_walk(pgdir, va, 0);
f01018f8:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01018ff:	00 
f0101900:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101904:	8b 45 08             	mov    0x8(%ebp),%eax
f0101907:	89 04 24             	mov    %eax,(%esp)
f010190a:	e8 99 fd ff ff       	call   f01016a8 <pgdir_walk>
f010190f:	89 c3                	mov    %eax,%ebx
	if ((now != NULL) && (*now & PTE_P)) {
f0101911:	85 c0                	test   %eax,%eax
f0101913:	74 3f                	je     f0101954 <page_insert+0x71>
f0101915:	8b 00                	mov    (%eax),%eax
f0101917:	a8 01                	test   $0x1,%al
f0101919:	74 5b                	je     f0101976 <page_insert+0x93>
		//cprintf("!");
//		PageInfo* now_page = (PageInfo*) pa2page(PTE_ADDR(now) + PGOFF(va));
//		page_remove(now_page);
		if (PTE_ADDR(*now) == page2pa(pp)) {
f010191b:	25 00 f0 ff ff       	and    $0xfffff000,%eax
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101920:	89 f2                	mov    %esi,%edx
f0101922:	2b 15 8c 99 11 f0    	sub    0xf011998c,%edx
f0101928:	c1 fa 03             	sar    $0x3,%edx
f010192b:	c1 e2 0c             	shl    $0xc,%edx
f010192e:	39 d0                	cmp    %edx,%eax
f0101930:	75 11                	jne    f0101943 <page_insert+0x60>
			*now = PTE_ADDR(page2pa(pp)) | perm | PTE_P;
f0101932:	8b 55 14             	mov    0x14(%ebp),%edx
f0101935:	83 ca 01             	or     $0x1,%edx
f0101938:	09 d0                	or     %edx,%eax
f010193a:	89 03                	mov    %eax,(%ebx)
			return 0;
f010193c:	b8 00 00 00 00       	mov    $0x0,%eax
f0101941:	eb 55                	jmp    f0101998 <page_insert+0xb5>
		}
//		cprintf("%d\n", *now);
		page_remove(pgdir, va);
f0101943:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101947:	8b 45 08             	mov    0x8(%ebp),%eax
f010194a:	89 04 24             	mov    %eax,(%esp)
f010194d:	e8 39 ff ff ff       	call   f010188b <page_remove>
f0101952:	eb 22                	jmp    f0101976 <page_insert+0x93>
	}
	if (now == NULL) now = pgdir_walk(pgdir, va, 1);
f0101954:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f010195b:	00 
f010195c:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101960:	8b 45 08             	mov    0x8(%ebp),%eax
f0101963:	89 04 24             	mov    %eax,(%esp)
f0101966:	e8 3d fd ff ff       	call   f01016a8 <pgdir_walk>
f010196b:	89 c3                	mov    %eax,%ebx
	if (now == NULL) return -E_NO_MEM;
f010196d:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f0101972:	85 db                	test   %ebx,%ebx
f0101974:	74 22                	je     f0101998 <page_insert+0xb5>
	*now = PTE_ADDR(page2pa(pp)) | perm | PTE_P;
f0101976:	8b 45 14             	mov    0x14(%ebp),%eax
f0101979:	83 c8 01             	or     $0x1,%eax
f010197c:	89 f2                	mov    %esi,%edx
f010197e:	2b 15 8c 99 11 f0    	sub    0xf011998c,%edx
f0101984:	c1 fa 03             	sar    $0x3,%edx
f0101987:	c1 e2 0c             	shl    $0xc,%edx
f010198a:	09 d0                	or     %edx,%eax
f010198c:	89 03                	mov    %eax,(%ebx)
	pp->pp_ref++;
f010198e:	66 83 46 04 01       	addw   $0x1,0x4(%esi)
	return 0;
f0101993:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101998:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f010199b:	8b 75 f8             	mov    -0x8(%ebp),%esi
f010199e:	8b 7d fc             	mov    -0x4(%ebp),%edi
f01019a1:	89 ec                	mov    %ebp,%esp
f01019a3:	5d                   	pop    %ebp
f01019a4:	c3                   	ret    

f01019a5 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f01019a5:	55                   	push   %ebp
f01019a6:	89 e5                	mov    %esp,%ebp
f01019a8:	57                   	push   %edi
f01019a9:	56                   	push   %esi
f01019aa:	53                   	push   %ebx
f01019ab:	83 ec 3c             	sub    $0x3c,%esp
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f01019ae:	b8 15 00 00 00       	mov    $0x15,%eax
f01019b3:	e8 e9 f7 ff ff       	call   f01011a1 <nvram_read>
f01019b8:	c1 e0 0a             	shl    $0xa,%eax
f01019bb:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f01019c1:	85 c0                	test   %eax,%eax
f01019c3:	0f 48 c2             	cmovs  %edx,%eax
f01019c6:	c1 f8 0c             	sar    $0xc,%eax
f01019c9:	a3 58 95 11 f0       	mov    %eax,0xf0119558
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f01019ce:	b8 17 00 00 00       	mov    $0x17,%eax
f01019d3:	e8 c9 f7 ff ff       	call   f01011a1 <nvram_read>
f01019d8:	c1 e0 0a             	shl    $0xa,%eax
f01019db:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f01019e1:	85 c0                	test   %eax,%eax
f01019e3:	0f 48 c2             	cmovs  %edx,%eax
f01019e6:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f01019e9:	85 c0                	test   %eax,%eax
f01019eb:	74 0e                	je     f01019fb <mem_init+0x56>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f01019ed:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f01019f3:	89 15 84 99 11 f0    	mov    %edx,0xf0119984
f01019f9:	eb 0c                	jmp    f0101a07 <mem_init+0x62>
	else
		npages = npages_basemem;
f01019fb:	8b 15 58 95 11 f0    	mov    0xf0119558,%edx
f0101a01:	89 15 84 99 11 f0    	mov    %edx,0xf0119984

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
		npages_extmem * PGSIZE / 1024);
f0101a07:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101a0a:	c1 e8 0a             	shr    $0xa,%eax
f0101a0d:	89 44 24 0c          	mov    %eax,0xc(%esp)
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
f0101a11:	a1 58 95 11 f0       	mov    0xf0119558,%eax
f0101a16:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101a19:	c1 e8 0a             	shr    $0xa,%eax
f0101a1c:	89 44 24 08          	mov    %eax,0x8(%esp)
		npages * PGSIZE / 1024,
f0101a20:	a1 84 99 11 f0       	mov    0xf0119984,%eax
f0101a25:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0101a28:	c1 e8 0a             	shr    $0xa,%eax
f0101a2b:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101a2f:	c7 04 24 e8 4f 10 f0 	movl   $0xf0104fe8,(%esp)
f0101a36:	e8 3f 1b 00 00       	call   f010357a <cprintf>
	// Remove this line when you're ready to test this function.
//	panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f0101a3b:	b8 00 10 00 00       	mov    $0x1000,%eax
f0101a40:	e8 af f6 ff ff       	call   f01010f4 <boot_alloc>
f0101a45:	a3 88 99 11 f0       	mov    %eax,0xf0119988
	memset(kern_pgdir, 0, PGSIZE);
f0101a4a:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101a51:	00 
f0101a52:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101a59:	00 
f0101a5a:	89 04 24             	mov    %eax,(%esp)
f0101a5d:	e8 cf 26 00 00       	call   f0104131 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0101a62:	a1 88 99 11 f0       	mov    0xf0119988,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0101a67:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0101a6c:	77 20                	ja     f0101a8e <mem_init+0xe9>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101a6e:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101a72:	c7 44 24 08 a4 4f 10 	movl   $0xf0104fa4,0x8(%esp)
f0101a79:	f0 
f0101a7a:	c7 44 24 04 91 00 00 	movl   $0x91,0x4(%esp)
f0101a81:	00 
f0101a82:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f0101a89:	e8 06 e6 ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0101a8e:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0101a94:	83 ca 05             	or     $0x5,%edx
f0101a97:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate an array of npages 'struct PageInfo's and store it in 'pages'.
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.
	// Your code goes here:
	pages = (struct PageInfo*) boot_alloc(npages * sizeof(struct PageInfo));
f0101a9d:	a1 84 99 11 f0       	mov    0xf0119984,%eax
f0101aa2:	c1 e0 03             	shl    $0x3,%eax
f0101aa5:	e8 4a f6 ff ff       	call   f01010f4 <boot_alloc>
f0101aaa:	a3 8c 99 11 f0       	mov    %eax,0xf011998c
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f0101aaf:	e8 7b fa ff ff       	call   f010152f <page_init>
	//cprintf("!!!");

	check_page_free_list(1);
f0101ab4:	b8 01 00 00 00       	mov    $0x1,%eax
f0101ab9:	e8 15 f7 ff ff       	call   f01011d3 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f0101abe:	83 3d 8c 99 11 f0 00 	cmpl   $0x0,0xf011998c
f0101ac5:	75 1c                	jne    f0101ae3 <mem_init+0x13e>
		panic("'pages' is a null pointer!");
f0101ac7:	c7 44 24 08 96 56 10 	movl   $0xf0105696,0x8(%esp)
f0101ace:	f0 
f0101acf:	c7 44 24 04 56 02 00 	movl   $0x256,0x4(%esp)
f0101ad6:	00 
f0101ad7:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f0101ade:	e8 b1 e5 ff ff       	call   f0100094 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101ae3:	a1 60 95 11 f0       	mov    0xf0119560,%eax
f0101ae8:	bb 00 00 00 00       	mov    $0x0,%ebx
f0101aed:	85 c0                	test   %eax,%eax
f0101aef:	74 09                	je     f0101afa <mem_init+0x155>
		++nfree;
f0101af1:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101af4:	8b 00                	mov    (%eax),%eax
f0101af6:	85 c0                	test   %eax,%eax
f0101af8:	75 f7                	jne    f0101af1 <mem_init+0x14c>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101afa:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101b01:	e8 e9 fa ff ff       	call   f01015ef <page_alloc>
f0101b06:	89 c6                	mov    %eax,%esi
f0101b08:	85 c0                	test   %eax,%eax
f0101b0a:	75 24                	jne    f0101b30 <mem_init+0x18b>
f0101b0c:	c7 44 24 0c b1 56 10 	movl   $0xf01056b1,0xc(%esp)
f0101b13:	f0 
f0101b14:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f0101b1b:	f0 
f0101b1c:	c7 44 24 04 5e 02 00 	movl   $0x25e,0x4(%esp)
f0101b23:	00 
f0101b24:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f0101b2b:	e8 64 e5 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f0101b30:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101b37:	e8 b3 fa ff ff       	call   f01015ef <page_alloc>
f0101b3c:	89 c7                	mov    %eax,%edi
f0101b3e:	85 c0                	test   %eax,%eax
f0101b40:	75 24                	jne    f0101b66 <mem_init+0x1c1>
f0101b42:	c7 44 24 0c c7 56 10 	movl   $0xf01056c7,0xc(%esp)
f0101b49:	f0 
f0101b4a:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f0101b51:	f0 
f0101b52:	c7 44 24 04 5f 02 00 	movl   $0x25f,0x4(%esp)
f0101b59:	00 
f0101b5a:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f0101b61:	e8 2e e5 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0101b66:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101b6d:	e8 7d fa ff ff       	call   f01015ef <page_alloc>
f0101b72:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101b75:	85 c0                	test   %eax,%eax
f0101b77:	75 24                	jne    f0101b9d <mem_init+0x1f8>
f0101b79:	c7 44 24 0c dd 56 10 	movl   $0xf01056dd,0xc(%esp)
f0101b80:	f0 
f0101b81:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f0101b88:	f0 
f0101b89:	c7 44 24 04 60 02 00 	movl   $0x260,0x4(%esp)
f0101b90:	00 
f0101b91:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f0101b98:	e8 f7 e4 ff ff       	call   f0100094 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101b9d:	39 fe                	cmp    %edi,%esi
f0101b9f:	75 24                	jne    f0101bc5 <mem_init+0x220>
f0101ba1:	c7 44 24 0c f3 56 10 	movl   $0xf01056f3,0xc(%esp)
f0101ba8:	f0 
f0101ba9:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f0101bb0:	f0 
f0101bb1:	c7 44 24 04 63 02 00 	movl   $0x263,0x4(%esp)
f0101bb8:	00 
f0101bb9:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f0101bc0:	e8 cf e4 ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101bc5:	3b 7d d4             	cmp    -0x2c(%ebp),%edi
f0101bc8:	74 05                	je     f0101bcf <mem_init+0x22a>
f0101bca:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f0101bcd:	75 24                	jne    f0101bf3 <mem_init+0x24e>
f0101bcf:	c7 44 24 0c 24 50 10 	movl   $0xf0105024,0xc(%esp)
f0101bd6:	f0 
f0101bd7:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f0101bde:	f0 
f0101bdf:	c7 44 24 04 64 02 00 	movl   $0x264,0x4(%esp)
f0101be6:	00 
f0101be7:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f0101bee:	e8 a1 e4 ff ff       	call   f0100094 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101bf3:	8b 15 8c 99 11 f0    	mov    0xf011998c,%edx
	assert(page2pa(pp0) < npages*PGSIZE);
f0101bf9:	a1 84 99 11 f0       	mov    0xf0119984,%eax
f0101bfe:	c1 e0 0c             	shl    $0xc,%eax
f0101c01:	89 f1                	mov    %esi,%ecx
f0101c03:	29 d1                	sub    %edx,%ecx
f0101c05:	c1 f9 03             	sar    $0x3,%ecx
f0101c08:	c1 e1 0c             	shl    $0xc,%ecx
f0101c0b:	39 c1                	cmp    %eax,%ecx
f0101c0d:	72 24                	jb     f0101c33 <mem_init+0x28e>
f0101c0f:	c7 44 24 0c 05 57 10 	movl   $0xf0105705,0xc(%esp)
f0101c16:	f0 
f0101c17:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f0101c1e:	f0 
f0101c1f:	c7 44 24 04 65 02 00 	movl   $0x265,0x4(%esp)
f0101c26:	00 
f0101c27:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f0101c2e:	e8 61 e4 ff ff       	call   f0100094 <_panic>
f0101c33:	89 f9                	mov    %edi,%ecx
f0101c35:	29 d1                	sub    %edx,%ecx
f0101c37:	c1 f9 03             	sar    $0x3,%ecx
f0101c3a:	c1 e1 0c             	shl    $0xc,%ecx
	assert(page2pa(pp1) < npages*PGSIZE);
f0101c3d:	39 c8                	cmp    %ecx,%eax
f0101c3f:	77 24                	ja     f0101c65 <mem_init+0x2c0>
f0101c41:	c7 44 24 0c 22 57 10 	movl   $0xf0105722,0xc(%esp)
f0101c48:	f0 
f0101c49:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f0101c50:	f0 
f0101c51:	c7 44 24 04 66 02 00 	movl   $0x266,0x4(%esp)
f0101c58:	00 
f0101c59:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f0101c60:	e8 2f e4 ff ff       	call   f0100094 <_panic>
f0101c65:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0101c68:	29 d1                	sub    %edx,%ecx
f0101c6a:	89 ca                	mov    %ecx,%edx
f0101c6c:	c1 fa 03             	sar    $0x3,%edx
f0101c6f:	c1 e2 0c             	shl    $0xc,%edx
	assert(page2pa(pp2) < npages*PGSIZE);
f0101c72:	39 d0                	cmp    %edx,%eax
f0101c74:	77 24                	ja     f0101c9a <mem_init+0x2f5>
f0101c76:	c7 44 24 0c 3f 57 10 	movl   $0xf010573f,0xc(%esp)
f0101c7d:	f0 
f0101c7e:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f0101c85:	f0 
f0101c86:	c7 44 24 04 67 02 00 	movl   $0x267,0x4(%esp)
f0101c8d:	00 
f0101c8e:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f0101c95:	e8 fa e3 ff ff       	call   f0100094 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101c9a:	a1 60 95 11 f0       	mov    0xf0119560,%eax
f0101c9f:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101ca2:	c7 05 60 95 11 f0 00 	movl   $0x0,0xf0119560
f0101ca9:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101cac:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101cb3:	e8 37 f9 ff ff       	call   f01015ef <page_alloc>
f0101cb8:	85 c0                	test   %eax,%eax
f0101cba:	74 24                	je     f0101ce0 <mem_init+0x33b>
f0101cbc:	c7 44 24 0c 5c 57 10 	movl   $0xf010575c,0xc(%esp)
f0101cc3:	f0 
f0101cc4:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f0101ccb:	f0 
f0101ccc:	c7 44 24 04 6e 02 00 	movl   $0x26e,0x4(%esp)
f0101cd3:	00 
f0101cd4:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f0101cdb:	e8 b4 e3 ff ff       	call   f0100094 <_panic>

	// free and re-allocate?
	page_free(pp0);
f0101ce0:	89 34 24             	mov    %esi,(%esp)
f0101ce3:	e8 88 f9 ff ff       	call   f0101670 <page_free>
	page_free(pp1);
f0101ce8:	89 3c 24             	mov    %edi,(%esp)
f0101ceb:	e8 80 f9 ff ff       	call   f0101670 <page_free>
	page_free(pp2);
f0101cf0:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101cf3:	89 04 24             	mov    %eax,(%esp)
f0101cf6:	e8 75 f9 ff ff       	call   f0101670 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101cfb:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101d02:	e8 e8 f8 ff ff       	call   f01015ef <page_alloc>
f0101d07:	89 c6                	mov    %eax,%esi
f0101d09:	85 c0                	test   %eax,%eax
f0101d0b:	75 24                	jne    f0101d31 <mem_init+0x38c>
f0101d0d:	c7 44 24 0c b1 56 10 	movl   $0xf01056b1,0xc(%esp)
f0101d14:	f0 
f0101d15:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f0101d1c:	f0 
f0101d1d:	c7 44 24 04 75 02 00 	movl   $0x275,0x4(%esp)
f0101d24:	00 
f0101d25:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f0101d2c:	e8 63 e3 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f0101d31:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101d38:	e8 b2 f8 ff ff       	call   f01015ef <page_alloc>
f0101d3d:	89 c7                	mov    %eax,%edi
f0101d3f:	85 c0                	test   %eax,%eax
f0101d41:	75 24                	jne    f0101d67 <mem_init+0x3c2>
f0101d43:	c7 44 24 0c c7 56 10 	movl   $0xf01056c7,0xc(%esp)
f0101d4a:	f0 
f0101d4b:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f0101d52:	f0 
f0101d53:	c7 44 24 04 76 02 00 	movl   $0x276,0x4(%esp)
f0101d5a:	00 
f0101d5b:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f0101d62:	e8 2d e3 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0101d67:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101d6e:	e8 7c f8 ff ff       	call   f01015ef <page_alloc>
f0101d73:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101d76:	85 c0                	test   %eax,%eax
f0101d78:	75 24                	jne    f0101d9e <mem_init+0x3f9>
f0101d7a:	c7 44 24 0c dd 56 10 	movl   $0xf01056dd,0xc(%esp)
f0101d81:	f0 
f0101d82:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f0101d89:	f0 
f0101d8a:	c7 44 24 04 77 02 00 	movl   $0x277,0x4(%esp)
f0101d91:	00 
f0101d92:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f0101d99:	e8 f6 e2 ff ff       	call   f0100094 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101d9e:	39 fe                	cmp    %edi,%esi
f0101da0:	75 24                	jne    f0101dc6 <mem_init+0x421>
f0101da2:	c7 44 24 0c f3 56 10 	movl   $0xf01056f3,0xc(%esp)
f0101da9:	f0 
f0101daa:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f0101db1:	f0 
f0101db2:	c7 44 24 04 79 02 00 	movl   $0x279,0x4(%esp)
f0101db9:	00 
f0101dba:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f0101dc1:	e8 ce e2 ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101dc6:	3b 7d d4             	cmp    -0x2c(%ebp),%edi
f0101dc9:	74 05                	je     f0101dd0 <mem_init+0x42b>
f0101dcb:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f0101dce:	75 24                	jne    f0101df4 <mem_init+0x44f>
f0101dd0:	c7 44 24 0c 24 50 10 	movl   $0xf0105024,0xc(%esp)
f0101dd7:	f0 
f0101dd8:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f0101ddf:	f0 
f0101de0:	c7 44 24 04 7a 02 00 	movl   $0x27a,0x4(%esp)
f0101de7:	00 
f0101de8:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f0101def:	e8 a0 e2 ff ff       	call   f0100094 <_panic>
	assert(!page_alloc(0));
f0101df4:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101dfb:	e8 ef f7 ff ff       	call   f01015ef <page_alloc>
f0101e00:	85 c0                	test   %eax,%eax
f0101e02:	74 24                	je     f0101e28 <mem_init+0x483>
f0101e04:	c7 44 24 0c 5c 57 10 	movl   $0xf010575c,0xc(%esp)
f0101e0b:	f0 
f0101e0c:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f0101e13:	f0 
f0101e14:	c7 44 24 04 7b 02 00 	movl   $0x27b,0x4(%esp)
f0101e1b:	00 
f0101e1c:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f0101e23:	e8 6c e2 ff ff       	call   f0100094 <_panic>
f0101e28:	89 f0                	mov    %esi,%eax
f0101e2a:	2b 05 8c 99 11 f0    	sub    0xf011998c,%eax
f0101e30:	c1 f8 03             	sar    $0x3,%eax
f0101e33:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101e36:	89 c2                	mov    %eax,%edx
f0101e38:	c1 ea 0c             	shr    $0xc,%edx
f0101e3b:	3b 15 84 99 11 f0    	cmp    0xf0119984,%edx
f0101e41:	72 20                	jb     f0101e63 <mem_init+0x4be>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101e43:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101e47:	c7 44 24 08 1c 4c 10 	movl   $0xf0104c1c,0x8(%esp)
f0101e4e:	f0 
f0101e4f:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0101e56:	00 
f0101e57:	c7 04 24 e4 55 10 f0 	movl   $0xf01055e4,(%esp)
f0101e5e:	e8 31 e2 ff ff       	call   f0100094 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f0101e63:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101e6a:	00 
f0101e6b:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0101e72:	00 
	return (void *)(pa + KERNBASE);
f0101e73:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101e78:	89 04 24             	mov    %eax,(%esp)
f0101e7b:	e8 b1 22 00 00       	call   f0104131 <memset>
	page_free(pp0);
f0101e80:	89 34 24             	mov    %esi,(%esp)
f0101e83:	e8 e8 f7 ff ff       	call   f0101670 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101e88:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101e8f:	e8 5b f7 ff ff       	call   f01015ef <page_alloc>
f0101e94:	85 c0                	test   %eax,%eax
f0101e96:	75 24                	jne    f0101ebc <mem_init+0x517>
f0101e98:	c7 44 24 0c 6b 57 10 	movl   $0xf010576b,0xc(%esp)
f0101e9f:	f0 
f0101ea0:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f0101ea7:	f0 
f0101ea8:	c7 44 24 04 80 02 00 	movl   $0x280,0x4(%esp)
f0101eaf:	00 
f0101eb0:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f0101eb7:	e8 d8 e1 ff ff       	call   f0100094 <_panic>
	assert(pp && pp0 == pp);
f0101ebc:	39 c6                	cmp    %eax,%esi
f0101ebe:	74 24                	je     f0101ee4 <mem_init+0x53f>
f0101ec0:	c7 44 24 0c 89 57 10 	movl   $0xf0105789,0xc(%esp)
f0101ec7:	f0 
f0101ec8:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f0101ecf:	f0 
f0101ed0:	c7 44 24 04 81 02 00 	movl   $0x281,0x4(%esp)
f0101ed7:	00 
f0101ed8:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f0101edf:	e8 b0 e1 ff ff       	call   f0100094 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101ee4:	89 f2                	mov    %esi,%edx
f0101ee6:	2b 15 8c 99 11 f0    	sub    0xf011998c,%edx
f0101eec:	c1 fa 03             	sar    $0x3,%edx
f0101eef:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101ef2:	89 d0                	mov    %edx,%eax
f0101ef4:	c1 e8 0c             	shr    $0xc,%eax
f0101ef7:	3b 05 84 99 11 f0    	cmp    0xf0119984,%eax
f0101efd:	72 20                	jb     f0101f1f <mem_init+0x57a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101eff:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101f03:	c7 44 24 08 1c 4c 10 	movl   $0xf0104c1c,0x8(%esp)
f0101f0a:	f0 
f0101f0b:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0101f12:	00 
f0101f13:	c7 04 24 e4 55 10 f0 	movl   $0xf01055e4,(%esp)
f0101f1a:	e8 75 e1 ff ff       	call   f0100094 <_panic>
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++) 
		assert(c[i] == 0);
f0101f1f:	80 ba 00 00 00 f0 00 	cmpb   $0x0,-0x10000000(%edx)
f0101f26:	75 11                	jne    f0101f39 <mem_init+0x594>
f0101f28:	8d 82 01 00 00 f0    	lea    -0xfffffff(%edx),%eax
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0101f2e:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++) 
		assert(c[i] == 0);
f0101f34:	80 38 00             	cmpb   $0x0,(%eax)
f0101f37:	74 24                	je     f0101f5d <mem_init+0x5b8>
f0101f39:	c7 44 24 0c 99 57 10 	movl   $0xf0105799,0xc(%esp)
f0101f40:	f0 
f0101f41:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f0101f48:	f0 
f0101f49:	c7 44 24 04 84 02 00 	movl   $0x284,0x4(%esp)
f0101f50:	00 
f0101f51:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f0101f58:	e8 37 e1 ff ff       	call   f0100094 <_panic>
f0101f5d:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++) 
f0101f60:	39 d0                	cmp    %edx,%eax
f0101f62:	75 d0                	jne    f0101f34 <mem_init+0x58f>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101f64:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0101f67:	89 15 60 95 11 f0    	mov    %edx,0xf0119560

	// free the pages we took
	page_free(pp0);
f0101f6d:	89 34 24             	mov    %esi,(%esp)
f0101f70:	e8 fb f6 ff ff       	call   f0101670 <page_free>
	page_free(pp1);
f0101f75:	89 3c 24             	mov    %edi,(%esp)
f0101f78:	e8 f3 f6 ff ff       	call   f0101670 <page_free>
	page_free(pp2);
f0101f7d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101f80:	89 04 24             	mov    %eax,(%esp)
f0101f83:	e8 e8 f6 ff ff       	call   f0101670 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101f88:	a1 60 95 11 f0       	mov    0xf0119560,%eax
f0101f8d:	85 c0                	test   %eax,%eax
f0101f8f:	74 09                	je     f0101f9a <mem_init+0x5f5>
		--nfree;
f0101f91:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101f94:	8b 00                	mov    (%eax),%eax
f0101f96:	85 c0                	test   %eax,%eax
f0101f98:	75 f7                	jne    f0101f91 <mem_init+0x5ec>
		--nfree;
	assert(nfree == 0);
f0101f9a:	85 db                	test   %ebx,%ebx
f0101f9c:	74 24                	je     f0101fc2 <mem_init+0x61d>
f0101f9e:	c7 44 24 0c a3 57 10 	movl   $0xf01057a3,0xc(%esp)
f0101fa5:	f0 
f0101fa6:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f0101fad:	f0 
f0101fae:	c7 44 24 04 91 02 00 	movl   $0x291,0x4(%esp)
f0101fb5:	00 
f0101fb6:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f0101fbd:	e8 d2 e0 ff ff       	call   f0100094 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f0101fc2:	c7 04 24 44 50 10 f0 	movl   $0xf0105044,(%esp)
f0101fc9:	e8 ac 15 00 00       	call   f010357a <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101fce:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101fd5:	e8 15 f6 ff ff       	call   f01015ef <page_alloc>
f0101fda:	89 c6                	mov    %eax,%esi
f0101fdc:	85 c0                	test   %eax,%eax
f0101fde:	75 24                	jne    f0102004 <mem_init+0x65f>
f0101fe0:	c7 44 24 0c b1 56 10 	movl   $0xf01056b1,0xc(%esp)
f0101fe7:	f0 
f0101fe8:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f0101fef:	f0 
f0101ff0:	c7 44 24 04 ed 02 00 	movl   $0x2ed,0x4(%esp)
f0101ff7:	00 
f0101ff8:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f0101fff:	e8 90 e0 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f0102004:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010200b:	e8 df f5 ff ff       	call   f01015ef <page_alloc>
f0102010:	89 c7                	mov    %eax,%edi
f0102012:	85 c0                	test   %eax,%eax
f0102014:	75 24                	jne    f010203a <mem_init+0x695>
f0102016:	c7 44 24 0c c7 56 10 	movl   $0xf01056c7,0xc(%esp)
f010201d:	f0 
f010201e:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f0102025:	f0 
f0102026:	c7 44 24 04 ee 02 00 	movl   $0x2ee,0x4(%esp)
f010202d:	00 
f010202e:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f0102035:	e8 5a e0 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f010203a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102041:	e8 a9 f5 ff ff       	call   f01015ef <page_alloc>
f0102046:	89 c3                	mov    %eax,%ebx
f0102048:	85 c0                	test   %eax,%eax
f010204a:	75 24                	jne    f0102070 <mem_init+0x6cb>
f010204c:	c7 44 24 0c dd 56 10 	movl   $0xf01056dd,0xc(%esp)
f0102053:	f0 
f0102054:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f010205b:	f0 
f010205c:	c7 44 24 04 ef 02 00 	movl   $0x2ef,0x4(%esp)
f0102063:	00 
f0102064:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f010206b:	e8 24 e0 ff ff       	call   f0100094 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0102070:	39 fe                	cmp    %edi,%esi
f0102072:	75 24                	jne    f0102098 <mem_init+0x6f3>
f0102074:	c7 44 24 0c f3 56 10 	movl   $0xf01056f3,0xc(%esp)
f010207b:	f0 
f010207c:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f0102083:	f0 
f0102084:	c7 44 24 04 f2 02 00 	movl   $0x2f2,0x4(%esp)
f010208b:	00 
f010208c:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f0102093:	e8 fc df ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0102098:	39 c7                	cmp    %eax,%edi
f010209a:	74 04                	je     f01020a0 <mem_init+0x6fb>
f010209c:	39 c6                	cmp    %eax,%esi
f010209e:	75 24                	jne    f01020c4 <mem_init+0x71f>
f01020a0:	c7 44 24 0c 24 50 10 	movl   $0xf0105024,0xc(%esp)
f01020a7:	f0 
f01020a8:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f01020af:	f0 
f01020b0:	c7 44 24 04 f3 02 00 	movl   $0x2f3,0x4(%esp)
f01020b7:	00 
f01020b8:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f01020bf:	e8 d0 df ff ff       	call   f0100094 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f01020c4:	8b 15 60 95 11 f0    	mov    0xf0119560,%edx
f01020ca:	89 55 cc             	mov    %edx,-0x34(%ebp)
	page_free_list = 0;
f01020cd:	c7 05 60 95 11 f0 00 	movl   $0x0,0xf0119560
f01020d4:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f01020d7:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01020de:	e8 0c f5 ff ff       	call   f01015ef <page_alloc>
f01020e3:	85 c0                	test   %eax,%eax
f01020e5:	74 24                	je     f010210b <mem_init+0x766>
f01020e7:	c7 44 24 0c 5c 57 10 	movl   $0xf010575c,0xc(%esp)
f01020ee:	f0 
f01020ef:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f01020f6:	f0 
f01020f7:	c7 44 24 04 fa 02 00 	movl   $0x2fa,0x4(%esp)
f01020fe:	00 
f01020ff:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f0102106:	e8 89 df ff ff       	call   f0100094 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f010210b:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f010210e:	89 44 24 08          	mov    %eax,0x8(%esp)
f0102112:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102119:	00 
f010211a:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f010211f:	89 04 24             	mov    %eax,(%esp)
f0102122:	e8 ec f6 ff ff       	call   f0101813 <page_lookup>
f0102127:	85 c0                	test   %eax,%eax
f0102129:	74 24                	je     f010214f <mem_init+0x7aa>
f010212b:	c7 44 24 0c 64 50 10 	movl   $0xf0105064,0xc(%esp)
f0102132:	f0 
f0102133:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f010213a:	f0 
f010213b:	c7 44 24 04 fd 02 00 	movl   $0x2fd,0x4(%esp)
f0102142:	00 
f0102143:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f010214a:	e8 45 df ff ff       	call   f0100094 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f010214f:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102156:	00 
f0102157:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f010215e:	00 
f010215f:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0102163:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f0102168:	89 04 24             	mov    %eax,(%esp)
f010216b:	e8 73 f7 ff ff       	call   f01018e3 <page_insert>
f0102170:	85 c0                	test   %eax,%eax
f0102172:	78 24                	js     f0102198 <mem_init+0x7f3>
f0102174:	c7 44 24 0c 9c 50 10 	movl   $0xf010509c,0xc(%esp)
f010217b:	f0 
f010217c:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f0102183:	f0 
f0102184:	c7 44 24 04 00 03 00 	movl   $0x300,0x4(%esp)
f010218b:	00 
f010218c:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f0102193:	e8 fc de ff ff       	call   f0100094 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0102198:	89 34 24             	mov    %esi,(%esp)
f010219b:	e8 d0 f4 ff ff       	call   f0101670 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f01021a0:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01021a7:	00 
f01021a8:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01021af:	00 
f01021b0:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01021b4:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f01021b9:	89 04 24             	mov    %eax,(%esp)
f01021bc:	e8 22 f7 ff ff       	call   f01018e3 <page_insert>
f01021c1:	85 c0                	test   %eax,%eax
f01021c3:	74 24                	je     f01021e9 <mem_init+0x844>
f01021c5:	c7 44 24 0c cc 50 10 	movl   $0xf01050cc,0xc(%esp)
f01021cc:	f0 
f01021cd:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f01021d4:	f0 
f01021d5:	c7 44 24 04 04 03 00 	movl   $0x304,0x4(%esp)
f01021dc:	00 
f01021dd:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f01021e4:	e8 ab de ff ff       	call   f0100094 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01021e9:	8b 0d 88 99 11 f0    	mov    0xf0119988,%ecx
f01021ef:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01021f2:	a1 8c 99 11 f0       	mov    0xf011998c,%eax
f01021f7:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01021fa:	8b 11                	mov    (%ecx),%edx
f01021fc:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102202:	89 f0                	mov    %esi,%eax
f0102204:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0102207:	c1 f8 03             	sar    $0x3,%eax
f010220a:	c1 e0 0c             	shl    $0xc,%eax
f010220d:	39 c2                	cmp    %eax,%edx
f010220f:	74 24                	je     f0102235 <mem_init+0x890>
f0102211:	c7 44 24 0c fc 50 10 	movl   $0xf01050fc,0xc(%esp)
f0102218:	f0 
f0102219:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f0102220:	f0 
f0102221:	c7 44 24 04 05 03 00 	movl   $0x305,0x4(%esp)
f0102228:	00 
f0102229:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f0102230:	e8 5f de ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0102235:	ba 00 00 00 00       	mov    $0x0,%edx
f010223a:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010223d:	e8 ee ee ff ff       	call   f0101130 <check_va2pa>
f0102242:	89 fa                	mov    %edi,%edx
f0102244:	2b 55 d0             	sub    -0x30(%ebp),%edx
f0102247:	c1 fa 03             	sar    $0x3,%edx
f010224a:	c1 e2 0c             	shl    $0xc,%edx
f010224d:	39 d0                	cmp    %edx,%eax
f010224f:	74 24                	je     f0102275 <mem_init+0x8d0>
f0102251:	c7 44 24 0c 24 51 10 	movl   $0xf0105124,0xc(%esp)
f0102258:	f0 
f0102259:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f0102260:	f0 
f0102261:	c7 44 24 04 06 03 00 	movl   $0x306,0x4(%esp)
f0102268:	00 
f0102269:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f0102270:	e8 1f de ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 1);
f0102275:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f010227a:	74 24                	je     f01022a0 <mem_init+0x8fb>
f010227c:	c7 44 24 0c ae 57 10 	movl   $0xf01057ae,0xc(%esp)
f0102283:	f0 
f0102284:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f010228b:	f0 
f010228c:	c7 44 24 04 07 03 00 	movl   $0x307,0x4(%esp)
f0102293:	00 
f0102294:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f010229b:	e8 f4 dd ff ff       	call   f0100094 <_panic>
	assert(pp0->pp_ref == 1);
f01022a0:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01022a5:	74 24                	je     f01022cb <mem_init+0x926>
f01022a7:	c7 44 24 0c bf 57 10 	movl   $0xf01057bf,0xc(%esp)
f01022ae:	f0 
f01022af:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f01022b6:	f0 
f01022b7:	c7 44 24 04 08 03 00 	movl   $0x308,0x4(%esp)
f01022be:	00 
f01022bf:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f01022c6:	e8 c9 dd ff ff       	call   f0100094 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01022cb:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01022d2:	00 
f01022d3:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01022da:	00 
f01022db:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01022df:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01022e2:	89 14 24             	mov    %edx,(%esp)
f01022e5:	e8 f9 f5 ff ff       	call   f01018e3 <page_insert>
f01022ea:	85 c0                	test   %eax,%eax
f01022ec:	74 24                	je     f0102312 <mem_init+0x96d>
f01022ee:	c7 44 24 0c 54 51 10 	movl   $0xf0105154,0xc(%esp)
f01022f5:	f0 
f01022f6:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f01022fd:	f0 
f01022fe:	c7 44 24 04 0b 03 00 	movl   $0x30b,0x4(%esp)
f0102305:	00 
f0102306:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f010230d:	e8 82 dd ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0102312:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102317:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f010231c:	e8 0f ee ff ff       	call   f0101130 <check_va2pa>
f0102321:	89 da                	mov    %ebx,%edx
f0102323:	2b 15 8c 99 11 f0    	sub    0xf011998c,%edx
f0102329:	c1 fa 03             	sar    $0x3,%edx
f010232c:	c1 e2 0c             	shl    $0xc,%edx
f010232f:	39 d0                	cmp    %edx,%eax
f0102331:	74 24                	je     f0102357 <mem_init+0x9b2>
f0102333:	c7 44 24 0c 90 51 10 	movl   $0xf0105190,0xc(%esp)
f010233a:	f0 
f010233b:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f0102342:	f0 
f0102343:	c7 44 24 04 0c 03 00 	movl   $0x30c,0x4(%esp)
f010234a:	00 
f010234b:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f0102352:	e8 3d dd ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0102357:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f010235c:	74 24                	je     f0102382 <mem_init+0x9dd>
f010235e:	c7 44 24 0c d0 57 10 	movl   $0xf01057d0,0xc(%esp)
f0102365:	f0 
f0102366:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f010236d:	f0 
f010236e:	c7 44 24 04 0d 03 00 	movl   $0x30d,0x4(%esp)
f0102375:	00 
f0102376:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f010237d:	e8 12 dd ff ff       	call   f0100094 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0102382:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102389:	e8 61 f2 ff ff       	call   f01015ef <page_alloc>
f010238e:	85 c0                	test   %eax,%eax
f0102390:	74 24                	je     f01023b6 <mem_init+0xa11>
f0102392:	c7 44 24 0c 5c 57 10 	movl   $0xf010575c,0xc(%esp)
f0102399:	f0 
f010239a:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f01023a1:	f0 
f01023a2:	c7 44 24 04 10 03 00 	movl   $0x310,0x4(%esp)
f01023a9:	00 
f01023aa:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f01023b1:	e8 de dc ff ff       	call   f0100094 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01023b6:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01023bd:	00 
f01023be:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01023c5:	00 
f01023c6:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01023ca:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f01023cf:	89 04 24             	mov    %eax,(%esp)
f01023d2:	e8 0c f5 ff ff       	call   f01018e3 <page_insert>
f01023d7:	85 c0                	test   %eax,%eax
f01023d9:	74 24                	je     f01023ff <mem_init+0xa5a>
f01023db:	c7 44 24 0c 54 51 10 	movl   $0xf0105154,0xc(%esp)
f01023e2:	f0 
f01023e3:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f01023ea:	f0 
f01023eb:	c7 44 24 04 13 03 00 	movl   $0x313,0x4(%esp)
f01023f2:	00 
f01023f3:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f01023fa:	e8 95 dc ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f01023ff:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102404:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f0102409:	e8 22 ed ff ff       	call   f0101130 <check_va2pa>
f010240e:	89 da                	mov    %ebx,%edx
f0102410:	2b 15 8c 99 11 f0    	sub    0xf011998c,%edx
f0102416:	c1 fa 03             	sar    $0x3,%edx
f0102419:	c1 e2 0c             	shl    $0xc,%edx
f010241c:	39 d0                	cmp    %edx,%eax
f010241e:	74 24                	je     f0102444 <mem_init+0xa9f>
f0102420:	c7 44 24 0c 90 51 10 	movl   $0xf0105190,0xc(%esp)
f0102427:	f0 
f0102428:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f010242f:	f0 
f0102430:	c7 44 24 04 14 03 00 	movl   $0x314,0x4(%esp)
f0102437:	00 
f0102438:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f010243f:	e8 50 dc ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0102444:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102449:	74 24                	je     f010246f <mem_init+0xaca>
f010244b:	c7 44 24 0c d0 57 10 	movl   $0xf01057d0,0xc(%esp)
f0102452:	f0 
f0102453:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f010245a:	f0 
f010245b:	c7 44 24 04 15 03 00 	movl   $0x315,0x4(%esp)
f0102462:	00 
f0102463:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f010246a:	e8 25 dc ff ff       	call   f0100094 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f010246f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102476:	e8 74 f1 ff ff       	call   f01015ef <page_alloc>
f010247b:	85 c0                	test   %eax,%eax
f010247d:	74 24                	je     f01024a3 <mem_init+0xafe>
f010247f:	c7 44 24 0c 5c 57 10 	movl   $0xf010575c,0xc(%esp)
f0102486:	f0 
f0102487:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f010248e:	f0 
f010248f:	c7 44 24 04 19 03 00 	movl   $0x319,0x4(%esp)
f0102496:	00 
f0102497:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f010249e:	e8 f1 db ff ff       	call   f0100094 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f01024a3:	8b 15 88 99 11 f0    	mov    0xf0119988,%edx
f01024a9:	8b 02                	mov    (%edx),%eax
f01024ab:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01024b0:	89 c1                	mov    %eax,%ecx
f01024b2:	c1 e9 0c             	shr    $0xc,%ecx
f01024b5:	3b 0d 84 99 11 f0    	cmp    0xf0119984,%ecx
f01024bb:	72 20                	jb     f01024dd <mem_init+0xb38>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01024bd:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01024c1:	c7 44 24 08 1c 4c 10 	movl   $0xf0104c1c,0x8(%esp)
f01024c8:	f0 
f01024c9:	c7 44 24 04 1c 03 00 	movl   $0x31c,0x4(%esp)
f01024d0:	00 
f01024d1:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f01024d8:	e8 b7 db ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f01024dd:	2d 00 00 00 10       	sub    $0x10000000,%eax
f01024e2:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f01024e5:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01024ec:	00 
f01024ed:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01024f4:	00 
f01024f5:	89 14 24             	mov    %edx,(%esp)
f01024f8:	e8 ab f1 ff ff       	call   f01016a8 <pgdir_walk>
f01024fd:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0102500:	83 c2 04             	add    $0x4,%edx
f0102503:	39 d0                	cmp    %edx,%eax
f0102505:	74 24                	je     f010252b <mem_init+0xb86>
f0102507:	c7 44 24 0c c0 51 10 	movl   $0xf01051c0,0xc(%esp)
f010250e:	f0 
f010250f:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f0102516:	f0 
f0102517:	c7 44 24 04 1d 03 00 	movl   $0x31d,0x4(%esp)
f010251e:	00 
f010251f:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f0102526:	e8 69 db ff ff       	call   f0100094 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f010252b:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f0102532:	00 
f0102533:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010253a:	00 
f010253b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010253f:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f0102544:	89 04 24             	mov    %eax,(%esp)
f0102547:	e8 97 f3 ff ff       	call   f01018e3 <page_insert>
f010254c:	85 c0                	test   %eax,%eax
f010254e:	74 24                	je     f0102574 <mem_init+0xbcf>
f0102550:	c7 44 24 0c 00 52 10 	movl   $0xf0105200,0xc(%esp)
f0102557:	f0 
f0102558:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f010255f:	f0 
f0102560:	c7 44 24 04 20 03 00 	movl   $0x320,0x4(%esp)
f0102567:	00 
f0102568:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f010256f:	e8 20 db ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0102574:	8b 0d 88 99 11 f0    	mov    0xf0119988,%ecx
f010257a:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f010257d:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102582:	89 c8                	mov    %ecx,%eax
f0102584:	e8 a7 eb ff ff       	call   f0101130 <check_va2pa>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102589:	89 da                	mov    %ebx,%edx
f010258b:	2b 15 8c 99 11 f0    	sub    0xf011998c,%edx
f0102591:	c1 fa 03             	sar    $0x3,%edx
f0102594:	c1 e2 0c             	shl    $0xc,%edx
f0102597:	39 d0                	cmp    %edx,%eax
f0102599:	74 24                	je     f01025bf <mem_init+0xc1a>
f010259b:	c7 44 24 0c 90 51 10 	movl   $0xf0105190,0xc(%esp)
f01025a2:	f0 
f01025a3:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f01025aa:	f0 
f01025ab:	c7 44 24 04 21 03 00 	movl   $0x321,0x4(%esp)
f01025b2:	00 
f01025b3:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f01025ba:	e8 d5 da ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f01025bf:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f01025c4:	74 24                	je     f01025ea <mem_init+0xc45>
f01025c6:	c7 44 24 0c d0 57 10 	movl   $0xf01057d0,0xc(%esp)
f01025cd:	f0 
f01025ce:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f01025d5:	f0 
f01025d6:	c7 44 24 04 22 03 00 	movl   $0x322,0x4(%esp)
f01025dd:	00 
f01025de:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f01025e5:	e8 aa da ff ff       	call   f0100094 <_panic>

	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f01025ea:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01025f1:	00 
f01025f2:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01025f9:	00 
f01025fa:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01025fd:	89 04 24             	mov    %eax,(%esp)
f0102600:	e8 a3 f0 ff ff       	call   f01016a8 <pgdir_walk>
f0102605:	f6 00 04             	testb  $0x4,(%eax)
f0102608:	75 24                	jne    f010262e <mem_init+0xc89>
f010260a:	c7 44 24 0c 40 52 10 	movl   $0xf0105240,0xc(%esp)
f0102611:	f0 
f0102612:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f0102619:	f0 
f010261a:	c7 44 24 04 24 03 00 	movl   $0x324,0x4(%esp)
f0102621:	00 
f0102622:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f0102629:	e8 66 da ff ff       	call   f0100094 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f010262e:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f0102633:	f6 00 04             	testb  $0x4,(%eax)
f0102636:	75 24                	jne    f010265c <mem_init+0xcb7>
f0102638:	c7 44 24 0c e1 57 10 	movl   $0xf01057e1,0xc(%esp)
f010263f:	f0 
f0102640:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f0102647:	f0 
f0102648:	c7 44 24 04 25 03 00 	movl   $0x325,0x4(%esp)
f010264f:	00 
f0102650:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f0102657:	e8 38 da ff ff       	call   f0100094 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f010265c:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102663:	00 
f0102664:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010266b:	00 
f010266c:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102670:	89 04 24             	mov    %eax,(%esp)
f0102673:	e8 6b f2 ff ff       	call   f01018e3 <page_insert>
f0102678:	85 c0                	test   %eax,%eax
f010267a:	74 24                	je     f01026a0 <mem_init+0xcfb>
f010267c:	c7 44 24 0c 54 51 10 	movl   $0xf0105154,0xc(%esp)
f0102683:	f0 
f0102684:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f010268b:	f0 
f010268c:	c7 44 24 04 28 03 00 	movl   $0x328,0x4(%esp)
f0102693:	00 
f0102694:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f010269b:	e8 f4 d9 ff ff       	call   f0100094 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f01026a0:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01026a7:	00 
f01026a8:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01026af:	00 
f01026b0:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f01026b5:	89 04 24             	mov    %eax,(%esp)
f01026b8:	e8 eb ef ff ff       	call   f01016a8 <pgdir_walk>
f01026bd:	f6 00 02             	testb  $0x2,(%eax)
f01026c0:	75 24                	jne    f01026e6 <mem_init+0xd41>
f01026c2:	c7 44 24 0c 74 52 10 	movl   $0xf0105274,0xc(%esp)
f01026c9:	f0 
f01026ca:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f01026d1:	f0 
f01026d2:	c7 44 24 04 29 03 00 	movl   $0x329,0x4(%esp)
f01026d9:	00 
f01026da:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f01026e1:	e8 ae d9 ff ff       	call   f0100094 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f01026e6:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01026ed:	00 
f01026ee:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01026f5:	00 
f01026f6:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f01026fb:	89 04 24             	mov    %eax,(%esp)
f01026fe:	e8 a5 ef ff ff       	call   f01016a8 <pgdir_walk>
f0102703:	f6 00 04             	testb  $0x4,(%eax)
f0102706:	74 24                	je     f010272c <mem_init+0xd87>
f0102708:	c7 44 24 0c a8 52 10 	movl   $0xf01052a8,0xc(%esp)
f010270f:	f0 
f0102710:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f0102717:	f0 
f0102718:	c7 44 24 04 2a 03 00 	movl   $0x32a,0x4(%esp)
f010271f:	00 
f0102720:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f0102727:	e8 68 d9 ff ff       	call   f0100094 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f010272c:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102733:	00 
f0102734:	c7 44 24 08 00 00 40 	movl   $0x400000,0x8(%esp)
f010273b:	00 
f010273c:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102740:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f0102745:	89 04 24             	mov    %eax,(%esp)
f0102748:	e8 96 f1 ff ff       	call   f01018e3 <page_insert>
f010274d:	85 c0                	test   %eax,%eax
f010274f:	78 24                	js     f0102775 <mem_init+0xdd0>
f0102751:	c7 44 24 0c e0 52 10 	movl   $0xf01052e0,0xc(%esp)
f0102758:	f0 
f0102759:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f0102760:	f0 
f0102761:	c7 44 24 04 2d 03 00 	movl   $0x32d,0x4(%esp)
f0102768:	00 
f0102769:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f0102770:	e8 1f d9 ff ff       	call   f0100094 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
//	cprintf("~~w");
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0102775:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f010277c:	00 
f010277d:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102784:	00 
f0102785:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0102789:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f010278e:	89 04 24             	mov    %eax,(%esp)
f0102791:	e8 4d f1 ff ff       	call   f01018e3 <page_insert>
f0102796:	85 c0                	test   %eax,%eax
f0102798:	74 24                	je     f01027be <mem_init+0xe19>
f010279a:	c7 44 24 0c 18 53 10 	movl   $0xf0105318,0xc(%esp)
f01027a1:	f0 
f01027a2:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f01027a9:	f0 
f01027aa:	c7 44 24 04 31 03 00 	movl   $0x331,0x4(%esp)
f01027b1:	00 
f01027b2:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f01027b9:	e8 d6 d8 ff ff       	call   f0100094 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f01027be:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01027c5:	00 
f01027c6:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01027cd:	00 
f01027ce:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f01027d3:	89 04 24             	mov    %eax,(%esp)
f01027d6:	e8 cd ee ff ff       	call   f01016a8 <pgdir_walk>
f01027db:	f6 00 04             	testb  $0x4,(%eax)
f01027de:	74 24                	je     f0102804 <mem_init+0xe5f>
f01027e0:	c7 44 24 0c a8 52 10 	movl   $0xf01052a8,0xc(%esp)
f01027e7:	f0 
f01027e8:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f01027ef:	f0 
f01027f0:	c7 44 24 04 32 03 00 	movl   $0x332,0x4(%esp)
f01027f7:	00 
f01027f8:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f01027ff:	e8 90 d8 ff ff       	call   f0100094 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f0102804:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f0102809:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f010280c:	ba 00 00 00 00       	mov    $0x0,%edx
f0102811:	e8 1a e9 ff ff       	call   f0101130 <check_va2pa>
f0102816:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0102819:	89 f8                	mov    %edi,%eax
f010281b:	2b 05 8c 99 11 f0    	sub    0xf011998c,%eax
f0102821:	c1 f8 03             	sar    $0x3,%eax
f0102824:	c1 e0 0c             	shl    $0xc,%eax
f0102827:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f010282a:	74 24                	je     f0102850 <mem_init+0xeab>
f010282c:	c7 44 24 0c 54 53 10 	movl   $0xf0105354,0xc(%esp)
f0102833:	f0 
f0102834:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f010283b:	f0 
f010283c:	c7 44 24 04 35 03 00 	movl   $0x335,0x4(%esp)
f0102843:	00 
f0102844:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f010284b:	e8 44 d8 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0102850:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102855:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102858:	e8 d3 e8 ff ff       	call   f0101130 <check_va2pa>
f010285d:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0102860:	74 24                	je     f0102886 <mem_init+0xee1>
f0102862:	c7 44 24 0c 80 53 10 	movl   $0xf0105380,0xc(%esp)
f0102869:	f0 
f010286a:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f0102871:	f0 
f0102872:	c7 44 24 04 36 03 00 	movl   $0x336,0x4(%esp)
f0102879:	00 
f010287a:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f0102881:	e8 0e d8 ff ff       	call   f0100094 <_panic>
	// ... and ref counts should reflect this
//	cprintf("%d %d", pp1->pp_ref, pp2->pp_ref);
	assert(pp1->pp_ref == 2);
f0102886:	66 83 7f 04 02       	cmpw   $0x2,0x4(%edi)
f010288b:	74 24                	je     f01028b1 <mem_init+0xf0c>
f010288d:	c7 44 24 0c f7 57 10 	movl   $0xf01057f7,0xc(%esp)
f0102894:	f0 
f0102895:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f010289c:	f0 
f010289d:	c7 44 24 04 39 03 00 	movl   $0x339,0x4(%esp)
f01028a4:	00 
f01028a5:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f01028ac:	e8 e3 d7 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f01028b1:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f01028b6:	74 24                	je     f01028dc <mem_init+0xf37>
f01028b8:	c7 44 24 0c 08 58 10 	movl   $0xf0105808,0xc(%esp)
f01028bf:	f0 
f01028c0:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f01028c7:	f0 
f01028c8:	c7 44 24 04 3a 03 00 	movl   $0x33a,0x4(%esp)
f01028cf:	00 
f01028d0:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f01028d7:	e8 b8 d7 ff ff       	call   f0100094 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f01028dc:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01028e3:	e8 07 ed ff ff       	call   f01015ef <page_alloc>
f01028e8:	85 c0                	test   %eax,%eax
f01028ea:	74 04                	je     f01028f0 <mem_init+0xf4b>
f01028ec:	39 c3                	cmp    %eax,%ebx
f01028ee:	74 24                	je     f0102914 <mem_init+0xf6f>
f01028f0:	c7 44 24 0c b0 53 10 	movl   $0xf01053b0,0xc(%esp)
f01028f7:	f0 
f01028f8:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f01028ff:	f0 
f0102900:	c7 44 24 04 3d 03 00 	movl   $0x33d,0x4(%esp)
f0102907:	00 
f0102908:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f010290f:	e8 80 d7 ff ff       	call   f0100094 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f0102914:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010291b:	00 
f010291c:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f0102921:	89 04 24             	mov    %eax,(%esp)
f0102924:	e8 62 ef ff ff       	call   f010188b <page_remove>
//	cprintf("~~~");
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102929:	8b 15 88 99 11 f0    	mov    0xf0119988,%edx
f010292f:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f0102932:	ba 00 00 00 00       	mov    $0x0,%edx
f0102937:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010293a:	e8 f1 e7 ff ff       	call   f0101130 <check_va2pa>
f010293f:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102942:	74 24                	je     f0102968 <mem_init+0xfc3>
f0102944:	c7 44 24 0c d4 53 10 	movl   $0xf01053d4,0xc(%esp)
f010294b:	f0 
f010294c:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f0102953:	f0 
f0102954:	c7 44 24 04 42 03 00 	movl   $0x342,0x4(%esp)
f010295b:	00 
f010295c:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f0102963:	e8 2c d7 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0102968:	ba 00 10 00 00       	mov    $0x1000,%edx
f010296d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102970:	e8 bb e7 ff ff       	call   f0101130 <check_va2pa>
f0102975:	89 fa                	mov    %edi,%edx
f0102977:	2b 15 8c 99 11 f0    	sub    0xf011998c,%edx
f010297d:	c1 fa 03             	sar    $0x3,%edx
f0102980:	c1 e2 0c             	shl    $0xc,%edx
f0102983:	39 d0                	cmp    %edx,%eax
f0102985:	74 24                	je     f01029ab <mem_init+0x1006>
f0102987:	c7 44 24 0c 80 53 10 	movl   $0xf0105380,0xc(%esp)
f010298e:	f0 
f010298f:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f0102996:	f0 
f0102997:	c7 44 24 04 43 03 00 	movl   $0x343,0x4(%esp)
f010299e:	00 
f010299f:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f01029a6:	e8 e9 d6 ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 1);
f01029ab:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f01029b0:	74 24                	je     f01029d6 <mem_init+0x1031>
f01029b2:	c7 44 24 0c ae 57 10 	movl   $0xf01057ae,0xc(%esp)
f01029b9:	f0 
f01029ba:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f01029c1:	f0 
f01029c2:	c7 44 24 04 44 03 00 	movl   $0x344,0x4(%esp)
f01029c9:	00 
f01029ca:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f01029d1:	e8 be d6 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f01029d6:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f01029db:	74 24                	je     f0102a01 <mem_init+0x105c>
f01029dd:	c7 44 24 0c 08 58 10 	movl   $0xf0105808,0xc(%esp)
f01029e4:	f0 
f01029e5:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f01029ec:	f0 
f01029ed:	c7 44 24 04 45 03 00 	movl   $0x345,0x4(%esp)
f01029f4:	00 
f01029f5:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f01029fc:	e8 93 d6 ff ff       	call   f0100094 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102a01:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102a08:	00 
f0102a09:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0102a0c:	89 0c 24             	mov    %ecx,(%esp)
f0102a0f:	e8 77 ee ff ff       	call   f010188b <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f0102a14:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f0102a19:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0102a1c:	ba 00 00 00 00       	mov    $0x0,%edx
f0102a21:	e8 0a e7 ff ff       	call   f0101130 <check_va2pa>
f0102a26:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102a29:	74 24                	je     f0102a4f <mem_init+0x10aa>
f0102a2b:	c7 44 24 0c d4 53 10 	movl   $0xf01053d4,0xc(%esp)
f0102a32:	f0 
f0102a33:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f0102a3a:	f0 
f0102a3b:	c7 44 24 04 49 03 00 	movl   $0x349,0x4(%esp)
f0102a42:	00 
f0102a43:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f0102a4a:	e8 45 d6 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0102a4f:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102a54:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102a57:	e8 d4 e6 ff ff       	call   f0101130 <check_va2pa>
f0102a5c:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102a5f:	74 24                	je     f0102a85 <mem_init+0x10e0>
f0102a61:	c7 44 24 0c f8 53 10 	movl   $0xf01053f8,0xc(%esp)
f0102a68:	f0 
f0102a69:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f0102a70:	f0 
f0102a71:	c7 44 24 04 4a 03 00 	movl   $0x34a,0x4(%esp)
f0102a78:	00 
f0102a79:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f0102a80:	e8 0f d6 ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 0);
f0102a85:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102a8a:	74 24                	je     f0102ab0 <mem_init+0x110b>
f0102a8c:	c7 44 24 0c 19 58 10 	movl   $0xf0105819,0xc(%esp)
f0102a93:	f0 
f0102a94:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f0102a9b:	f0 
f0102a9c:	c7 44 24 04 4b 03 00 	movl   $0x34b,0x4(%esp)
f0102aa3:	00 
f0102aa4:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f0102aab:	e8 e4 d5 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f0102ab0:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102ab5:	74 24                	je     f0102adb <mem_init+0x1136>
f0102ab7:	c7 44 24 0c 08 58 10 	movl   $0xf0105808,0xc(%esp)
f0102abe:	f0 
f0102abf:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f0102ac6:	f0 
f0102ac7:	c7 44 24 04 4c 03 00 	movl   $0x34c,0x4(%esp)
f0102ace:	00 
f0102acf:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f0102ad6:	e8 b9 d5 ff ff       	call   f0100094 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0102adb:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102ae2:	e8 08 eb ff ff       	call   f01015ef <page_alloc>
f0102ae7:	85 c0                	test   %eax,%eax
f0102ae9:	74 04                	je     f0102aef <mem_init+0x114a>
f0102aeb:	39 c7                	cmp    %eax,%edi
f0102aed:	74 24                	je     f0102b13 <mem_init+0x116e>
f0102aef:	c7 44 24 0c 20 54 10 	movl   $0xf0105420,0xc(%esp)
f0102af6:	f0 
f0102af7:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f0102afe:	f0 
f0102aff:	c7 44 24 04 4f 03 00 	movl   $0x34f,0x4(%esp)
f0102b06:	00 
f0102b07:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f0102b0e:	e8 81 d5 ff ff       	call   f0100094 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0102b13:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102b1a:	e8 d0 ea ff ff       	call   f01015ef <page_alloc>
f0102b1f:	85 c0                	test   %eax,%eax
f0102b21:	74 24                	je     f0102b47 <mem_init+0x11a2>
f0102b23:	c7 44 24 0c 5c 57 10 	movl   $0xf010575c,0xc(%esp)
f0102b2a:	f0 
f0102b2b:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f0102b32:	f0 
f0102b33:	c7 44 24 04 52 03 00 	movl   $0x352,0x4(%esp)
f0102b3a:	00 
f0102b3b:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f0102b42:	e8 4d d5 ff ff       	call   f0100094 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102b47:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f0102b4c:	8b 08                	mov    (%eax),%ecx
f0102b4e:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0102b54:	89 f2                	mov    %esi,%edx
f0102b56:	2b 15 8c 99 11 f0    	sub    0xf011998c,%edx
f0102b5c:	c1 fa 03             	sar    $0x3,%edx
f0102b5f:	c1 e2 0c             	shl    $0xc,%edx
f0102b62:	39 d1                	cmp    %edx,%ecx
f0102b64:	74 24                	je     f0102b8a <mem_init+0x11e5>
f0102b66:	c7 44 24 0c fc 50 10 	movl   $0xf01050fc,0xc(%esp)
f0102b6d:	f0 
f0102b6e:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f0102b75:	f0 
f0102b76:	c7 44 24 04 55 03 00 	movl   $0x355,0x4(%esp)
f0102b7d:	00 
f0102b7e:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f0102b85:	e8 0a d5 ff ff       	call   f0100094 <_panic>
	kern_pgdir[0] = 0;
f0102b8a:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f0102b90:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102b95:	74 24                	je     f0102bbb <mem_init+0x1216>
f0102b97:	c7 44 24 0c bf 57 10 	movl   $0xf01057bf,0xc(%esp)
f0102b9e:	f0 
f0102b9f:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f0102ba6:	f0 
f0102ba7:	c7 44 24 04 57 03 00 	movl   $0x357,0x4(%esp)
f0102bae:	00 
f0102baf:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f0102bb6:	e8 d9 d4 ff ff       	call   f0100094 <_panic>
	pp0->pp_ref = 0;
f0102bbb:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0102bc1:	89 34 24             	mov    %esi,(%esp)
f0102bc4:	e8 a7 ea ff ff       	call   f0101670 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f0102bc9:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0102bd0:	00 
f0102bd1:	c7 44 24 04 00 10 40 	movl   $0x401000,0x4(%esp)
f0102bd8:	00 
f0102bd9:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f0102bde:	89 04 24             	mov    %eax,(%esp)
f0102be1:	e8 c2 ea ff ff       	call   f01016a8 <pgdir_walk>
f0102be6:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f0102be9:	8b 0d 88 99 11 f0    	mov    0xf0119988,%ecx
f0102bef:	8b 51 04             	mov    0x4(%ecx),%edx
f0102bf2:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0102bf8:	89 55 d4             	mov    %edx,-0x2c(%ebp)
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102bfb:	8b 15 84 99 11 f0    	mov    0xf0119984,%edx
f0102c01:	89 55 c8             	mov    %edx,-0x38(%ebp)
f0102c04:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0102c07:	c1 ea 0c             	shr    $0xc,%edx
f0102c0a:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0102c0d:	8b 55 c8             	mov    -0x38(%ebp),%edx
f0102c10:	39 55 d0             	cmp    %edx,-0x30(%ebp)
f0102c13:	72 23                	jb     f0102c38 <mem_init+0x1293>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102c15:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f0102c18:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0102c1c:	c7 44 24 08 1c 4c 10 	movl   $0xf0104c1c,0x8(%esp)
f0102c23:	f0 
f0102c24:	c7 44 24 04 5e 03 00 	movl   $0x35e,0x4(%esp)
f0102c2b:	00 
f0102c2c:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f0102c33:	e8 5c d4 ff ff       	call   f0100094 <_panic>
	assert(ptep == ptep1 + PTX(va));
f0102c38:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0102c3b:	81 ea fc ff ff 0f    	sub    $0xffffffc,%edx
f0102c41:	39 d0                	cmp    %edx,%eax
f0102c43:	74 24                	je     f0102c69 <mem_init+0x12c4>
f0102c45:	c7 44 24 0c 2a 58 10 	movl   $0xf010582a,0xc(%esp)
f0102c4c:	f0 
f0102c4d:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f0102c54:	f0 
f0102c55:	c7 44 24 04 5f 03 00 	movl   $0x35f,0x4(%esp)
f0102c5c:	00 
f0102c5d:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f0102c64:	e8 2b d4 ff ff       	call   f0100094 <_panic>
	kern_pgdir[PDX(va)] = 0;
f0102c69:	c7 41 04 00 00 00 00 	movl   $0x0,0x4(%ecx)
	pp0->pp_ref = 0;
f0102c70:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102c76:	89 f0                	mov    %esi,%eax
f0102c78:	2b 05 8c 99 11 f0    	sub    0xf011998c,%eax
f0102c7e:	c1 f8 03             	sar    $0x3,%eax
f0102c81:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102c84:	89 c1                	mov    %eax,%ecx
f0102c86:	c1 e9 0c             	shr    $0xc,%ecx
f0102c89:	39 4d c8             	cmp    %ecx,-0x38(%ebp)
f0102c8c:	77 20                	ja     f0102cae <mem_init+0x1309>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102c8e:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102c92:	c7 44 24 08 1c 4c 10 	movl   $0xf0104c1c,0x8(%esp)
f0102c99:	f0 
f0102c9a:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0102ca1:	00 
f0102ca2:	c7 04 24 e4 55 10 f0 	movl   $0xf01055e4,(%esp)
f0102ca9:	e8 e6 d3 ff ff       	call   f0100094 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0102cae:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102cb5:	00 
f0102cb6:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
f0102cbd:	00 
	return (void *)(pa + KERNBASE);
f0102cbe:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102cc3:	89 04 24             	mov    %eax,(%esp)
f0102cc6:	e8 66 14 00 00       	call   f0104131 <memset>
	page_free(pp0);
f0102ccb:	89 34 24             	mov    %esi,(%esp)
f0102cce:	e8 9d e9 ff ff       	call   f0101670 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0102cd3:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0102cda:	00 
f0102cdb:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102ce2:	00 
f0102ce3:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f0102ce8:	89 04 24             	mov    %eax,(%esp)
f0102ceb:	e8 b8 e9 ff ff       	call   f01016a8 <pgdir_walk>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102cf0:	89 f2                	mov    %esi,%edx
f0102cf2:	2b 15 8c 99 11 f0    	sub    0xf011998c,%edx
f0102cf8:	c1 fa 03             	sar    $0x3,%edx
f0102cfb:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102cfe:	89 d0                	mov    %edx,%eax
f0102d00:	c1 e8 0c             	shr    $0xc,%eax
f0102d03:	3b 05 84 99 11 f0    	cmp    0xf0119984,%eax
f0102d09:	72 20                	jb     f0102d2b <mem_init+0x1386>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102d0b:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0102d0f:	c7 44 24 08 1c 4c 10 	movl   $0xf0104c1c,0x8(%esp)
f0102d16:	f0 
f0102d17:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0102d1e:	00 
f0102d1f:	c7 04 24 e4 55 10 f0 	movl   $0xf01055e4,(%esp)
f0102d26:	e8 69 d3 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0102d2b:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f0102d31:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102d34:	f6 82 00 00 00 f0 01 	testb  $0x1,-0x10000000(%edx)
f0102d3b:	75 11                	jne    f0102d4e <mem_init+0x13a9>
f0102d3d:	8d 82 04 00 00 f0    	lea    -0xffffffc(%edx),%eax
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0102d43:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f0102d49:	f6 00 01             	testb  $0x1,(%eax)
f0102d4c:	74 24                	je     f0102d72 <mem_init+0x13cd>
f0102d4e:	c7 44 24 0c 42 58 10 	movl   $0xf0105842,0xc(%esp)
f0102d55:	f0 
f0102d56:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f0102d5d:	f0 
f0102d5e:	c7 44 24 04 69 03 00 	movl   $0x369,0x4(%esp)
f0102d65:	00 
f0102d66:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f0102d6d:	e8 22 d3 ff ff       	call   f0100094 <_panic>
f0102d72:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f0102d75:	39 d0                	cmp    %edx,%eax
f0102d77:	75 d0                	jne    f0102d49 <mem_init+0x13a4>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f0102d79:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f0102d7e:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102d84:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// give free list back
	page_free_list = fl;
f0102d8a:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0102d8d:	89 0d 60 95 11 f0    	mov    %ecx,0xf0119560

	// free the pages we took
	page_free(pp0);
f0102d93:	89 34 24             	mov    %esi,(%esp)
f0102d96:	e8 d5 e8 ff ff       	call   f0101670 <page_free>
	page_free(pp1);
f0102d9b:	89 3c 24             	mov    %edi,(%esp)
f0102d9e:	e8 cd e8 ff ff       	call   f0101670 <page_free>
	page_free(pp2);
f0102da3:	89 1c 24             	mov    %ebx,(%esp)
f0102da6:	e8 c5 e8 ff ff       	call   f0101670 <page_free>

	cprintf("check_page() succeeded!\n");
f0102dab:	c7 04 24 59 58 10 f0 	movl   $0xf0105859,(%esp)
f0102db2:	e8 c3 07 00 00       	call   f010357a <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, UPAGES, ROUNDUP(npages * sizeof(struct PageInfo), PGSIZE), PADDR(pages), PTE_U | PTE_P);
f0102db7:	a1 8c 99 11 f0       	mov    0xf011998c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102dbc:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102dc1:	77 20                	ja     f0102de3 <mem_init+0x143e>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102dc3:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102dc7:	c7 44 24 08 a4 4f 10 	movl   $0xf0104fa4,0x8(%esp)
f0102dce:	f0 
f0102dcf:	c7 44 24 04 b2 00 00 	movl   $0xb2,0x4(%esp)
f0102dd6:	00 
f0102dd7:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f0102dde:	e8 b1 d2 ff ff       	call   f0100094 <_panic>
f0102de3:	8b 15 84 99 11 f0    	mov    0xf0119984,%edx
f0102de9:	8d 0c d5 ff 0f 00 00 	lea    0xfff(,%edx,8),%ecx
f0102df0:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0102df6:	c7 44 24 04 05 00 00 	movl   $0x5,0x4(%esp)
f0102dfd:	00 
	return (physaddr_t)kva - KERNBASE;
f0102dfe:	05 00 00 00 10       	add    $0x10000000,%eax
f0102e03:	89 04 24             	mov    %eax,(%esp)
f0102e06:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f0102e0b:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f0102e10:	e8 82 e9 ff ff       	call   f0101797 <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102e15:	be 00 f0 10 f0       	mov    $0xf010f000,%esi
f0102e1a:	81 fe ff ff ff ef    	cmp    $0xefffffff,%esi
f0102e20:	77 20                	ja     f0102e42 <mem_init+0x149d>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102e22:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0102e26:	c7 44 24 08 a4 4f 10 	movl   $0xf0104fa4,0x8(%esp)
f0102e2d:	f0 
f0102e2e:	c7 44 24 04 bf 00 00 	movl   $0xbf,0x4(%esp)
f0102e35:	00 
f0102e36:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f0102e3d:	e8 52 d2 ff ff       	call   f0100094 <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KSTACKTOP - KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W);
f0102e42:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f0102e49:	00 
f0102e4a:	c7 04 24 00 f0 10 00 	movl   $0x10f000,(%esp)
f0102e51:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102e56:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f0102e5b:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f0102e60:	e8 32 e9 ff ff       	call   f0101797 <boot_map_region>
	//      the PA range [0, 2^32 - KERNBASE)
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KERNBASE, /*(1 << 32)*/ - KERNBASE, 0, PTE_W); 
f0102e65:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f0102e6c:	00 
f0102e6d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102e74:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f0102e79:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0102e7e:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f0102e83:	e8 0f e9 ff ff       	call   f0101797 <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f0102e88:	8b 1d 88 99 11 f0    	mov    0xf0119988,%ebx

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0102e8e:	8b 35 84 99 11 f0    	mov    0xf0119984,%esi
f0102e94:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f0102e97:	8d 3c f5 ff 0f 00 00 	lea    0xfff(,%esi,8),%edi
	for (i = 0; i < n; i += PGSIZE) {
f0102e9e:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
f0102ea4:	74 79                	je     f0102f1f <mem_init+0x157a>
f0102ea6:	be 00 00 00 00       	mov    $0x0,%esi
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0102eab:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx
	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE) {
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102eb1:	89 d8                	mov    %ebx,%eax
f0102eb3:	e8 78 e2 ff ff       	call   f0101130 <check_va2pa>
f0102eb8:	8b 15 8c 99 11 f0    	mov    0xf011998c,%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102ebe:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0102ec4:	77 20                	ja     f0102ee6 <mem_init+0x1541>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102ec6:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0102eca:	c7 44 24 08 a4 4f 10 	movl   $0xf0104fa4,0x8(%esp)
f0102ed1:	f0 
f0102ed2:	c7 44 24 04 a9 02 00 	movl   $0x2a9,0x4(%esp)
f0102ed9:	00 
f0102eda:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f0102ee1:	e8 ae d1 ff ff       	call   f0100094 <_panic>
f0102ee6:	8d 94 32 00 00 00 10 	lea    0x10000000(%edx,%esi,1),%edx
f0102eed:	39 d0                	cmp    %edx,%eax
f0102eef:	74 24                	je     f0102f15 <mem_init+0x1570>
f0102ef1:	c7 44 24 0c 44 54 10 	movl   $0xf0105444,0xc(%esp)
f0102ef8:	f0 
f0102ef9:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f0102f00:	f0 
f0102f01:	c7 44 24 04 a9 02 00 	movl   $0x2a9,0x4(%esp)
f0102f08:	00 
f0102f09:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f0102f10:	e8 7f d1 ff ff       	call   f0100094 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE) {
f0102f15:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102f1b:	39 f7                	cmp    %esi,%edi
f0102f1d:	77 8c                	ja     f0102eab <mem_init+0x1506>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
	}


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102f1f:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0102f22:	c1 e7 0c             	shl    $0xc,%edi
f0102f25:	85 ff                	test   %edi,%edi
f0102f27:	74 44                	je     f0102f6d <mem_init+0x15c8>
f0102f29:	be 00 00 00 00       	mov    $0x0,%esi
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0102f2e:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
	}


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f0102f34:	89 d8                	mov    %ebx,%eax
f0102f36:	e8 f5 e1 ff ff       	call   f0101130 <check_va2pa>
f0102f3b:	39 c6                	cmp    %eax,%esi
f0102f3d:	74 24                	je     f0102f63 <mem_init+0x15be>
f0102f3f:	c7 44 24 0c 78 54 10 	movl   $0xf0105478,0xc(%esp)
f0102f46:	f0 
f0102f47:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f0102f4e:	f0 
f0102f4f:	c7 44 24 04 af 02 00 	movl   $0x2af,0x4(%esp)
f0102f56:	00 
f0102f57:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f0102f5e:	e8 31 d1 ff ff       	call   f0100094 <_panic>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
	}


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102f63:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102f69:	39 fe                	cmp    %edi,%esi
f0102f6b:	72 c1                	jb     f0102f2e <mem_init+0x1589>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102f6d:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f0102f72:	89 d8                	mov    %ebx,%eax
f0102f74:	e8 b7 e1 ff ff       	call   f0101130 <check_va2pa>
f0102f79:	be 00 90 ff ef       	mov    $0xefff9000,%esi
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0102f7e:	bf 00 f0 10 f0       	mov    $0xf010f000,%edi
f0102f83:	81 c7 00 70 00 20    	add    $0x20007000,%edi
f0102f89:	8d 14 37             	lea    (%edi,%esi,1),%edx
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102f8c:	39 c2                	cmp    %eax,%edx
f0102f8e:	74 24                	je     f0102fb4 <mem_init+0x160f>
f0102f90:	c7 44 24 0c a0 54 10 	movl   $0xf01054a0,0xc(%esp)
f0102f97:	f0 
f0102f98:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f0102f9f:	f0 
f0102fa0:	c7 44 24 04 b3 02 00 	movl   $0x2b3,0x4(%esp)
f0102fa7:	00 
f0102fa8:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f0102faf:	e8 e0 d0 ff ff       	call   f0100094 <_panic>
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0102fb4:	81 fe 00 00 00 f0    	cmp    $0xf0000000,%esi
f0102fba:	0f 85 37 05 00 00    	jne    f01034f7 <mem_init+0x1b52>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102fc0:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f0102fc5:	89 d8                	mov    %ebx,%eax
f0102fc7:	e8 64 e1 ff ff       	call   f0101130 <check_va2pa>
f0102fcc:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102fcf:	74 24                	je     f0102ff5 <mem_init+0x1650>
f0102fd1:	c7 44 24 0c e8 54 10 	movl   $0xf01054e8,0xc(%esp)
f0102fd8:	f0 
f0102fd9:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f0102fe0:	f0 
f0102fe1:	c7 44 24 04 b4 02 00 	movl   $0x2b4,0x4(%esp)
f0102fe8:	00 
f0102fe9:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f0102ff0:	e8 9f d0 ff ff       	call   f0100094 <_panic>
f0102ff5:	b8 00 00 00 00       	mov    $0x0,%eax

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f0102ffa:	ba 01 00 00 00       	mov    $0x1,%edx
f0102fff:	8d 88 44 fc ff ff    	lea    -0x3bc(%eax),%ecx
f0103005:	83 f9 03             	cmp    $0x3,%ecx
f0103008:	77 39                	ja     f0103043 <mem_init+0x169e>
f010300a:	89 d6                	mov    %edx,%esi
f010300c:	d3 e6                	shl    %cl,%esi
f010300e:	89 f1                	mov    %esi,%ecx
f0103010:	f6 c1 0b             	test   $0xb,%cl
f0103013:	74 2e                	je     f0103043 <mem_init+0x169e>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
f0103015:	f6 04 83 01          	testb  $0x1,(%ebx,%eax,4)
f0103019:	0f 85 aa 00 00 00    	jne    f01030c9 <mem_init+0x1724>
f010301f:	c7 44 24 0c 72 58 10 	movl   $0xf0105872,0xc(%esp)
f0103026:	f0 
f0103027:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f010302e:	f0 
f010302f:	c7 44 24 04 bc 02 00 	movl   $0x2bc,0x4(%esp)
f0103036:	00 
f0103037:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f010303e:	e8 51 d0 ff ff       	call   f0100094 <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f0103043:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0103048:	76 55                	jbe    f010309f <mem_init+0x16fa>
				assert(pgdir[i] & PTE_P);
f010304a:	8b 0c 83             	mov    (%ebx,%eax,4),%ecx
f010304d:	f6 c1 01             	test   $0x1,%cl
f0103050:	75 24                	jne    f0103076 <mem_init+0x16d1>
f0103052:	c7 44 24 0c 72 58 10 	movl   $0xf0105872,0xc(%esp)
f0103059:	f0 
f010305a:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f0103061:	f0 
f0103062:	c7 44 24 04 c0 02 00 	movl   $0x2c0,0x4(%esp)
f0103069:	00 
f010306a:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f0103071:	e8 1e d0 ff ff       	call   f0100094 <_panic>
				assert(pgdir[i] & PTE_W);
f0103076:	f6 c1 02             	test   $0x2,%cl
f0103079:	75 4e                	jne    f01030c9 <mem_init+0x1724>
f010307b:	c7 44 24 0c 83 58 10 	movl   $0xf0105883,0xc(%esp)
f0103082:	f0 
f0103083:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f010308a:	f0 
f010308b:	c7 44 24 04 c1 02 00 	movl   $0x2c1,0x4(%esp)
f0103092:	00 
f0103093:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f010309a:	e8 f5 cf ff ff       	call   f0100094 <_panic>
			} else
				assert(pgdir[i] == 0);
f010309f:	83 3c 83 00          	cmpl   $0x0,(%ebx,%eax,4)
f01030a3:	74 24                	je     f01030c9 <mem_init+0x1724>
f01030a5:	c7 44 24 0c 94 58 10 	movl   $0xf0105894,0xc(%esp)
f01030ac:	f0 
f01030ad:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f01030b4:	f0 
f01030b5:	c7 44 24 04 c3 02 00 	movl   $0x2c3,0x4(%esp)
f01030bc:	00 
f01030bd:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f01030c4:	e8 cb cf ff ff       	call   f0100094 <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f01030c9:	83 c0 01             	add    $0x1,%eax
f01030cc:	3d 00 04 00 00       	cmp    $0x400,%eax
f01030d1:	0f 85 28 ff ff ff    	jne    f0102fff <mem_init+0x165a>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f01030d7:	c7 04 24 18 55 10 f0 	movl   $0xf0105518,(%esp)
f01030de:	e8 97 04 00 00       	call   f010357a <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f01030e3:	a1 88 99 11 f0       	mov    0xf0119988,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01030e8:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01030ed:	77 20                	ja     f010310f <mem_init+0x176a>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01030ef:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01030f3:	c7 44 24 08 a4 4f 10 	movl   $0xf0104fa4,0x8(%esp)
f01030fa:	f0 
f01030fb:	c7 44 24 04 d4 00 00 	movl   $0xd4,0x4(%esp)
f0103102:	00 
f0103103:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f010310a:	e8 85 cf ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f010310f:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0103114:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f0103117:	b8 00 00 00 00       	mov    $0x0,%eax
f010311c:	e8 b2 e0 ff ff       	call   f01011d3 <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f0103121:	0f 20 c0             	mov    %cr0,%eax

	// entry.S set the really important flags in cr0 (including enabling
	// paging).  Here we configure the rest of the flags that we care about.
	cr0 = rcr0();
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_MP;
f0103124:	0d 23 00 05 80       	or     $0x80050023,%eax
	cr0 &= ~(CR0_TS|CR0_EM);
f0103129:	83 e0 f3             	and    $0xfffffff3,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f010312c:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010312f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0103136:	e8 b4 e4 ff ff       	call   f01015ef <page_alloc>
f010313b:	89 c6                	mov    %eax,%esi
f010313d:	85 c0                	test   %eax,%eax
f010313f:	75 24                	jne    f0103165 <mem_init+0x17c0>
f0103141:	c7 44 24 0c b1 56 10 	movl   $0xf01056b1,0xc(%esp)
f0103148:	f0 
f0103149:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f0103150:	f0 
f0103151:	c7 44 24 04 84 03 00 	movl   $0x384,0x4(%esp)
f0103158:	00 
f0103159:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f0103160:	e8 2f cf ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f0103165:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010316c:	e8 7e e4 ff ff       	call   f01015ef <page_alloc>
f0103171:	89 c7                	mov    %eax,%edi
f0103173:	85 c0                	test   %eax,%eax
f0103175:	75 24                	jne    f010319b <mem_init+0x17f6>
f0103177:	c7 44 24 0c c7 56 10 	movl   $0xf01056c7,0xc(%esp)
f010317e:	f0 
f010317f:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f0103186:	f0 
f0103187:	c7 44 24 04 85 03 00 	movl   $0x385,0x4(%esp)
f010318e:	00 
f010318f:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f0103196:	e8 f9 ce ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f010319b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01031a2:	e8 48 e4 ff ff       	call   f01015ef <page_alloc>
f01031a7:	89 c3                	mov    %eax,%ebx
f01031a9:	85 c0                	test   %eax,%eax
f01031ab:	75 24                	jne    f01031d1 <mem_init+0x182c>
f01031ad:	c7 44 24 0c dd 56 10 	movl   $0xf01056dd,0xc(%esp)
f01031b4:	f0 
f01031b5:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f01031bc:	f0 
f01031bd:	c7 44 24 04 86 03 00 	movl   $0x386,0x4(%esp)
f01031c4:	00 
f01031c5:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f01031cc:	e8 c3 ce ff ff       	call   f0100094 <_panic>
	page_free(pp0);
f01031d1:	89 34 24             	mov    %esi,(%esp)
f01031d4:	e8 97 e4 ff ff       	call   f0101670 <page_free>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01031d9:	89 f8                	mov    %edi,%eax
f01031db:	2b 05 8c 99 11 f0    	sub    0xf011998c,%eax
f01031e1:	c1 f8 03             	sar    $0x3,%eax
f01031e4:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01031e7:	89 c2                	mov    %eax,%edx
f01031e9:	c1 ea 0c             	shr    $0xc,%edx
f01031ec:	3b 15 84 99 11 f0    	cmp    0xf0119984,%edx
f01031f2:	72 20                	jb     f0103214 <mem_init+0x186f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01031f4:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01031f8:	c7 44 24 08 1c 4c 10 	movl   $0xf0104c1c,0x8(%esp)
f01031ff:	f0 
f0103200:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0103207:	00 
f0103208:	c7 04 24 e4 55 10 f0 	movl   $0xf01055e4,(%esp)
f010320f:	e8 80 ce ff ff       	call   f0100094 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f0103214:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010321b:	00 
f010321c:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0103223:	00 
	return (void *)(pa + KERNBASE);
f0103224:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0103229:	89 04 24             	mov    %eax,(%esp)
f010322c:	e8 00 0f 00 00       	call   f0104131 <memset>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0103231:	89 d8                	mov    %ebx,%eax
f0103233:	2b 05 8c 99 11 f0    	sub    0xf011998c,%eax
f0103239:	c1 f8 03             	sar    $0x3,%eax
f010323c:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010323f:	89 c2                	mov    %eax,%edx
f0103241:	c1 ea 0c             	shr    $0xc,%edx
f0103244:	3b 15 84 99 11 f0    	cmp    0xf0119984,%edx
f010324a:	72 20                	jb     f010326c <mem_init+0x18c7>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010324c:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103250:	c7 44 24 08 1c 4c 10 	movl   $0xf0104c1c,0x8(%esp)
f0103257:	f0 
f0103258:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f010325f:	00 
f0103260:	c7 04 24 e4 55 10 f0 	movl   $0xf01055e4,(%esp)
f0103267:	e8 28 ce ff ff       	call   f0100094 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f010326c:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0103273:	00 
f0103274:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f010327b:	00 
	return (void *)(pa + KERNBASE);
f010327c:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0103281:	89 04 24             	mov    %eax,(%esp)
f0103284:	e8 a8 0e 00 00       	call   f0104131 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0103289:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0103290:	00 
f0103291:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0103298:	00 
f0103299:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010329d:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f01032a2:	89 04 24             	mov    %eax,(%esp)
f01032a5:	e8 39 e6 ff ff       	call   f01018e3 <page_insert>
	assert(pp1->pp_ref == 1);
f01032aa:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f01032af:	74 24                	je     f01032d5 <mem_init+0x1930>
f01032b1:	c7 44 24 0c ae 57 10 	movl   $0xf01057ae,0xc(%esp)
f01032b8:	f0 
f01032b9:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f01032c0:	f0 
f01032c1:	c7 44 24 04 8b 03 00 	movl   $0x38b,0x4(%esp)
f01032c8:	00 
f01032c9:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f01032d0:	e8 bf cd ff ff       	call   f0100094 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f01032d5:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f01032dc:	01 01 01 
f01032df:	74 24                	je     f0103305 <mem_init+0x1960>
f01032e1:	c7 44 24 0c 38 55 10 	movl   $0xf0105538,0xc(%esp)
f01032e8:	f0 
f01032e9:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f01032f0:	f0 
f01032f1:	c7 44 24 04 8c 03 00 	movl   $0x38c,0x4(%esp)
f01032f8:	00 
f01032f9:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f0103300:	e8 8f cd ff ff       	call   f0100094 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0103305:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f010330c:	00 
f010330d:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0103314:	00 
f0103315:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103319:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f010331e:	89 04 24             	mov    %eax,(%esp)
f0103321:	e8 bd e5 ff ff       	call   f01018e3 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0103326:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f010332d:	02 02 02 
f0103330:	74 24                	je     f0103356 <mem_init+0x19b1>
f0103332:	c7 44 24 0c 5c 55 10 	movl   $0xf010555c,0xc(%esp)
f0103339:	f0 
f010333a:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f0103341:	f0 
f0103342:	c7 44 24 04 8e 03 00 	movl   $0x38e,0x4(%esp)
f0103349:	00 
f010334a:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f0103351:	e8 3e cd ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0103356:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f010335b:	74 24                	je     f0103381 <mem_init+0x19dc>
f010335d:	c7 44 24 0c d0 57 10 	movl   $0xf01057d0,0xc(%esp)
f0103364:	f0 
f0103365:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f010336c:	f0 
f010336d:	c7 44 24 04 8f 03 00 	movl   $0x38f,0x4(%esp)
f0103374:	00 
f0103375:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f010337c:	e8 13 cd ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 0);
f0103381:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0103386:	74 24                	je     f01033ac <mem_init+0x1a07>
f0103388:	c7 44 24 0c 19 58 10 	movl   $0xf0105819,0xc(%esp)
f010338f:	f0 
f0103390:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f0103397:	f0 
f0103398:	c7 44 24 04 90 03 00 	movl   $0x390,0x4(%esp)
f010339f:	00 
f01033a0:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f01033a7:	e8 e8 cc ff ff       	call   f0100094 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f01033ac:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f01033b3:	03 03 03 
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01033b6:	89 d8                	mov    %ebx,%eax
f01033b8:	2b 05 8c 99 11 f0    	sub    0xf011998c,%eax
f01033be:	c1 f8 03             	sar    $0x3,%eax
f01033c1:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01033c4:	89 c2                	mov    %eax,%edx
f01033c6:	c1 ea 0c             	shr    $0xc,%edx
f01033c9:	3b 15 84 99 11 f0    	cmp    0xf0119984,%edx
f01033cf:	72 20                	jb     f01033f1 <mem_init+0x1a4c>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01033d1:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01033d5:	c7 44 24 08 1c 4c 10 	movl   $0xf0104c1c,0x8(%esp)
f01033dc:	f0 
f01033dd:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f01033e4:	00 
f01033e5:	c7 04 24 e4 55 10 f0 	movl   $0xf01055e4,(%esp)
f01033ec:	e8 a3 cc ff ff       	call   f0100094 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f01033f1:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f01033f8:	03 03 03 
f01033fb:	74 24                	je     f0103421 <mem_init+0x1a7c>
f01033fd:	c7 44 24 0c 80 55 10 	movl   $0xf0105580,0xc(%esp)
f0103404:	f0 
f0103405:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f010340c:	f0 
f010340d:	c7 44 24 04 92 03 00 	movl   $0x392,0x4(%esp)
f0103414:	00 
f0103415:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f010341c:	e8 73 cc ff ff       	call   f0100094 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0103421:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0103428:	00 
f0103429:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f010342e:	89 04 24             	mov    %eax,(%esp)
f0103431:	e8 55 e4 ff ff       	call   f010188b <page_remove>
	assert(pp2->pp_ref == 0);
f0103436:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f010343b:	74 24                	je     f0103461 <mem_init+0x1abc>
f010343d:	c7 44 24 0c 08 58 10 	movl   $0xf0105808,0xc(%esp)
f0103444:	f0 
f0103445:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f010344c:	f0 
f010344d:	c7 44 24 04 94 03 00 	movl   $0x394,0x4(%esp)
f0103454:	00 
f0103455:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f010345c:	e8 33 cc ff ff       	call   f0100094 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0103461:	a1 88 99 11 f0       	mov    0xf0119988,%eax
f0103466:	8b 08                	mov    (%eax),%ecx
f0103468:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010346e:	89 f2                	mov    %esi,%edx
f0103470:	2b 15 8c 99 11 f0    	sub    0xf011998c,%edx
f0103476:	c1 fa 03             	sar    $0x3,%edx
f0103479:	c1 e2 0c             	shl    $0xc,%edx
f010347c:	39 d1                	cmp    %edx,%ecx
f010347e:	74 24                	je     f01034a4 <mem_init+0x1aff>
f0103480:	c7 44 24 0c fc 50 10 	movl   $0xf01050fc,0xc(%esp)
f0103487:	f0 
f0103488:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f010348f:	f0 
f0103490:	c7 44 24 04 97 03 00 	movl   $0x397,0x4(%esp)
f0103497:	00 
f0103498:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f010349f:	e8 f0 cb ff ff       	call   f0100094 <_panic>
	kern_pgdir[0] = 0;
f01034a4:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f01034aa:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f01034af:	74 24                	je     f01034d5 <mem_init+0x1b30>
f01034b1:	c7 44 24 0c bf 57 10 	movl   $0xf01057bf,0xc(%esp)
f01034b8:	f0 
f01034b9:	c7 44 24 08 fe 55 10 	movl   $0xf01055fe,0x8(%esp)
f01034c0:	f0 
f01034c1:	c7 44 24 04 99 03 00 	movl   $0x399,0x4(%esp)
f01034c8:	00 
f01034c9:	c7 04 24 d8 55 10 f0 	movl   $0xf01055d8,(%esp)
f01034d0:	e8 bf cb ff ff       	call   f0100094 <_panic>
	pp0->pp_ref = 0;
f01034d5:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// free the pages we took
	page_free(pp0);
f01034db:	89 34 24             	mov    %esi,(%esp)
f01034de:	e8 8d e1 ff ff       	call   f0101670 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f01034e3:	c7 04 24 ac 55 10 f0 	movl   $0xf01055ac,(%esp)
f01034ea:	e8 8b 00 00 00       	call   f010357a <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f01034ef:	83 c4 3c             	add    $0x3c,%esp
f01034f2:	5b                   	pop    %ebx
f01034f3:	5e                   	pop    %esi
f01034f4:	5f                   	pop    %edi
f01034f5:	5d                   	pop    %ebp
f01034f6:	c3                   	ret    
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f01034f7:	89 f2                	mov    %esi,%edx
f01034f9:	89 d8                	mov    %ebx,%eax
f01034fb:	e8 30 dc ff ff       	call   f0101130 <check_va2pa>
f0103500:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0103506:	e9 7e fa ff ff       	jmp    f0102f89 <mem_init+0x15e4>
	...

f010350c <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f010350c:	55                   	push   %ebp
f010350d:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010350f:	ba 70 00 00 00       	mov    $0x70,%edx
f0103514:	8b 45 08             	mov    0x8(%ebp),%eax
f0103517:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0103518:	b2 71                	mov    $0x71,%dl
f010351a:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f010351b:	0f b6 c0             	movzbl %al,%eax
}
f010351e:	5d                   	pop    %ebp
f010351f:	c3                   	ret    

f0103520 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
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
f010352c:	b2 71                	mov    $0x71,%dl
f010352e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103531:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0103532:	5d                   	pop    %ebp
f0103533:	c3                   	ret    

f0103534 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0103534:	55                   	push   %ebp
f0103535:	89 e5                	mov    %esp,%ebp
f0103537:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f010353a:	8b 45 08             	mov    0x8(%ebp),%eax
f010353d:	89 04 24             	mov    %eax,(%esp)
f0103540:	e8 b4 d0 ff ff       	call   f01005f9 <cputchar>
	*cnt++;
}
f0103545:	c9                   	leave  
f0103546:	c3                   	ret    

f0103547 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0103547:	55                   	push   %ebp
f0103548:	89 e5                	mov    %esp,%ebp
f010354a:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f010354d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0103554:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103557:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010355b:	8b 45 08             	mov    0x8(%ebp),%eax
f010355e:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103562:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0103565:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103569:	c7 04 24 34 35 10 f0 	movl   $0xf0103534,(%esp)
f0103570:	e8 b5 04 00 00       	call   f0103a2a <vprintfmt>
	return cnt;
}
f0103575:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103578:	c9                   	leave  
f0103579:	c3                   	ret    

f010357a <cprintf>:

int
cprintf(const char *fmt, ...)
{
f010357a:	55                   	push   %ebp
f010357b:	89 e5                	mov    %esp,%ebp
f010357d:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0103580:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0103583:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103587:	8b 45 08             	mov    0x8(%ebp),%eax
f010358a:	89 04 24             	mov    %eax,(%esp)
f010358d:	e8 b5 ff ff ff       	call   f0103547 <vcprintf>
	va_end(ap);

	return cnt;
}
f0103592:	c9                   	leave  
f0103593:	c3                   	ret    

f0103594 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0103594:	55                   	push   %ebp
f0103595:	89 e5                	mov    %esp,%ebp
f0103597:	57                   	push   %edi
f0103598:	56                   	push   %esi
f0103599:	53                   	push   %ebx
f010359a:	83 ec 10             	sub    $0x10,%esp
f010359d:	89 c3                	mov    %eax,%ebx
f010359f:	89 55 e8             	mov    %edx,-0x18(%ebp)
f01035a2:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f01035a5:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f01035a8:	8b 0a                	mov    (%edx),%ecx
f01035aa:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01035ad:	8b 00                	mov    (%eax),%eax
f01035af:	89 45 f0             	mov    %eax,-0x10(%ebp)
f01035b2:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)

	while (l <= r) {
f01035b9:	eb 77                	jmp    f0103632 <stab_binsearch+0x9e>
		int true_m = (l + r) / 2, m = true_m;
f01035bb:	8b 45 f0             	mov    -0x10(%ebp),%eax
f01035be:	01 c8                	add    %ecx,%eax
f01035c0:	bf 02 00 00 00       	mov    $0x2,%edi
f01035c5:	99                   	cltd   
f01035c6:	f7 ff                	idiv   %edi
f01035c8:	89 c2                	mov    %eax,%edx

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01035ca:	eb 01                	jmp    f01035cd <stab_binsearch+0x39>
			m--;
f01035cc:	4a                   	dec    %edx

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01035cd:	39 ca                	cmp    %ecx,%edx
f01035cf:	7c 1d                	jl     f01035ee <stab_binsearch+0x5a>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f01035d1:	6b fa 0c             	imul   $0xc,%edx,%edi

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01035d4:	0f b6 7c 3b 04       	movzbl 0x4(%ebx,%edi,1),%edi
f01035d9:	39 f7                	cmp    %esi,%edi
f01035db:	75 ef                	jne    f01035cc <stab_binsearch+0x38>
f01035dd:	89 55 ec             	mov    %edx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01035e0:	6b fa 0c             	imul   $0xc,%edx,%edi
f01035e3:	8b 7c 3b 08          	mov    0x8(%ebx,%edi,1),%edi
f01035e7:	3b 7d 0c             	cmp    0xc(%ebp),%edi
f01035ea:	73 18                	jae    f0103604 <stab_binsearch+0x70>
f01035ec:	eb 05                	jmp    f01035f3 <stab_binsearch+0x5f>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f01035ee:	8d 48 01             	lea    0x1(%eax),%ecx
			continue;
f01035f1:	eb 3f                	jmp    f0103632 <stab_binsearch+0x9e>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f01035f3:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f01035f6:	89 11                	mov    %edx,(%ecx)
			l = true_m + 1;
f01035f8:	8d 48 01             	lea    0x1(%eax),%ecx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01035fb:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0103602:	eb 2e                	jmp    f0103632 <stab_binsearch+0x9e>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0103604:	3b 7d 0c             	cmp    0xc(%ebp),%edi
f0103607:	76 15                	jbe    f010361e <stab_binsearch+0x8a>
			*region_right = m - 1;
f0103609:	8b 7d ec             	mov    -0x14(%ebp),%edi
f010360c:	4f                   	dec    %edi
f010360d:	89 7d f0             	mov    %edi,-0x10(%ebp)
f0103610:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103613:	89 38                	mov    %edi,(%eax)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0103615:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f010361c:	eb 14                	jmp    f0103632 <stab_binsearch+0x9e>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f010361e:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0103621:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0103624:	89 39                	mov    %edi,(%ecx)
			l = m;
			addr++;
f0103626:	ff 45 0c             	incl   0xc(%ebp)
f0103629:	89 d1                	mov    %edx,%ecx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010362b:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0103632:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
f0103635:	7e 84                	jle    f01035bb <stab_binsearch+0x27>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0103637:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f010363b:	75 0d                	jne    f010364a <stab_binsearch+0xb6>
		*region_right = *region_left - 1;
f010363d:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0103640:	8b 02                	mov    (%edx),%eax
f0103642:	48                   	dec    %eax
f0103643:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0103646:	89 01                	mov    %eax,(%ecx)
f0103648:	eb 22                	jmp    f010366c <stab_binsearch+0xd8>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010364a:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f010364d:	8b 01                	mov    (%ecx),%eax
		     l > *region_left && stabs[l].n_type != type;
f010364f:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0103652:	8b 0a                	mov    (%edx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103654:	eb 01                	jmp    f0103657 <stab_binsearch+0xc3>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0103656:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103657:	39 c1                	cmp    %eax,%ecx
f0103659:	7d 0c                	jge    f0103667 <stab_binsearch+0xd3>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f010365b:	6b d0 0c             	imul   $0xc,%eax,%edx
	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
		     l > *region_left && stabs[l].n_type != type;
f010365e:	0f b6 54 13 04       	movzbl 0x4(%ebx,%edx,1),%edx
f0103663:	39 f2                	cmp    %esi,%edx
f0103665:	75 ef                	jne    f0103656 <stab_binsearch+0xc2>
		     l--)
			/* do nothing */;
		*region_left = l;
f0103667:	8b 55 e8             	mov    -0x18(%ebp),%edx
f010366a:	89 02                	mov    %eax,(%edx)
	}
}
f010366c:	83 c4 10             	add    $0x10,%esp
f010366f:	5b                   	pop    %ebx
f0103670:	5e                   	pop    %esi
f0103671:	5f                   	pop    %edi
f0103672:	5d                   	pop    %ebp
f0103673:	c3                   	ret    

f0103674 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0103674:	55                   	push   %ebp
f0103675:	89 e5                	mov    %esp,%ebp
f0103677:	83 ec 58             	sub    $0x58,%esp
f010367a:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f010367d:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0103680:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0103683:	8b 75 08             	mov    0x8(%ebp),%esi
f0103686:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0103689:	c7 03 a2 58 10 f0    	movl   $0xf01058a2,(%ebx)
	info->eip_line = 0;
f010368f:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0103696:	c7 43 08 a2 58 10 f0 	movl   $0xf01058a2,0x8(%ebx)
	info->eip_fn_namelen = 9;
f010369d:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f01036a4:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f01036a7:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f01036ae:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f01036b4:	76 12                	jbe    f01036c8 <debuginfo_eip+0x54>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01036b6:	b8 3b e8 10 f0       	mov    $0xf010e83b,%eax
f01036bb:	3d 0d c8 10 f0       	cmp    $0xf010c80d,%eax
f01036c0:	0f 86 f1 01 00 00    	jbe    f01038b7 <debuginfo_eip+0x243>
f01036c6:	eb 1c                	jmp    f01036e4 <debuginfo_eip+0x70>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f01036c8:	c7 44 24 08 ac 58 10 	movl   $0xf01058ac,0x8(%esp)
f01036cf:	f0 
f01036d0:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f01036d7:	00 
f01036d8:	c7 04 24 b9 58 10 f0 	movl   $0xf01058b9,(%esp)
f01036df:	e8 b0 c9 ff ff       	call   f0100094 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f01036e4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01036e9:	80 3d 3a e8 10 f0 00 	cmpb   $0x0,0xf010e83a
f01036f0:	0f 85 cd 01 00 00    	jne    f01038c3 <debuginfo_eip+0x24f>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f01036f6:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f01036fd:	b8 0c c8 10 f0       	mov    $0xf010c80c,%eax
f0103702:	2d c8 5a 10 f0       	sub    $0xf0105ac8,%eax
f0103707:	c1 f8 02             	sar    $0x2,%eax
f010370a:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0103710:	83 e8 01             	sub    $0x1,%eax
f0103713:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0103716:	89 74 24 04          	mov    %esi,0x4(%esp)
f010371a:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0103721:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0103724:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0103727:	b8 c8 5a 10 f0       	mov    $0xf0105ac8,%eax
f010372c:	e8 63 fe ff ff       	call   f0103594 <stab_binsearch>
	if (lfile == 0)
f0103731:	8b 55 e4             	mov    -0x1c(%ebp),%edx
		return -1;
f0103734:	b8 ff ff ff ff       	mov    $0xffffffff,%eax

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
f0103739:	85 d2                	test   %edx,%edx
f010373b:	0f 84 82 01 00 00    	je     f01038c3 <debuginfo_eip+0x24f>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0103741:	89 55 dc             	mov    %edx,-0x24(%ebp)
	rfun = rfile;
f0103744:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103747:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f010374a:	89 74 24 04          	mov    %esi,0x4(%esp)
f010374e:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0103755:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0103758:	8d 55 dc             	lea    -0x24(%ebp),%edx
f010375b:	b8 c8 5a 10 f0       	mov    $0xf0105ac8,%eax
f0103760:	e8 2f fe ff ff       	call   f0103594 <stab_binsearch>

	if (lfun <= rfun) {
f0103765:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103768:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010376b:	39 d0                	cmp    %edx,%eax
f010376d:	7f 3d                	jg     f01037ac <debuginfo_eip+0x138>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f010376f:	6b c8 0c             	imul   $0xc,%eax,%ecx
f0103772:	8d b9 c8 5a 10 f0    	lea    -0xfefa538(%ecx),%edi
f0103778:	89 7d c0             	mov    %edi,-0x40(%ebp)
f010377b:	8b 89 c8 5a 10 f0    	mov    -0xfefa538(%ecx),%ecx
f0103781:	bf 3b e8 10 f0       	mov    $0xf010e83b,%edi
f0103786:	81 ef 0d c8 10 f0    	sub    $0xf010c80d,%edi
f010378c:	39 f9                	cmp    %edi,%ecx
f010378e:	73 09                	jae    f0103799 <debuginfo_eip+0x125>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0103790:	81 c1 0d c8 10 f0    	add    $0xf010c80d,%ecx
f0103796:	89 4b 08             	mov    %ecx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0103799:	8b 7d c0             	mov    -0x40(%ebp),%edi
f010379c:	8b 4f 08             	mov    0x8(%edi),%ecx
f010379f:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f01037a2:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f01037a4:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f01037a7:	89 55 d0             	mov    %edx,-0x30(%ebp)
f01037aa:	eb 0f                	jmp    f01037bb <debuginfo_eip+0x147>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f01037ac:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f01037af:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01037b2:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f01037b5:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01037b8:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f01037bb:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f01037c2:	00 
f01037c3:	8b 43 08             	mov    0x8(%ebx),%eax
f01037c6:	89 04 24             	mov    %eax,(%esp)
f01037c9:	e8 3c 09 00 00       	call   f010410a <strfind>
f01037ce:	2b 43 08             	sub    0x8(%ebx),%eax
f01037d1:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f01037d4:	89 74 24 04          	mov    %esi,0x4(%esp)
f01037d8:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f01037df:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f01037e2:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f01037e5:	b8 c8 5a 10 f0       	mov    $0xf0105ac8,%eax
f01037ea:	e8 a5 fd ff ff       	call   f0103594 <stab_binsearch>
	if (lline <= rline) {
f01037ef:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01037f2:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f01037f5:	7f 0f                	jg     f0103806 <debuginfo_eip+0x192>
		info->eip_line = stabs[lline].n_desc;
f01037f7:	6b c0 0c             	imul   $0xc,%eax,%eax
f01037fa:	0f b7 80 ce 5a 10 f0 	movzwl -0xfefa532(%eax),%eax
f0103801:	89 43 04             	mov    %eax,0x4(%ebx)
f0103804:	eb 07                	jmp    f010380d <debuginfo_eip+0x199>
	} else {
		info->eip_line = -1;
f0103806:	c7 43 04 ff ff ff ff 	movl   $0xffffffff,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f010380d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103810:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0103813:	39 c8                	cmp    %ecx,%eax
f0103815:	7c 5f                	jl     f0103876 <debuginfo_eip+0x202>
	       && stabs[lline].n_type != N_SOL
f0103817:	89 c2                	mov    %eax,%edx
f0103819:	6b f0 0c             	imul   $0xc,%eax,%esi
f010381c:	80 be cc 5a 10 f0 84 	cmpb   $0x84,-0xfefa534(%esi)
f0103823:	75 18                	jne    f010383d <debuginfo_eip+0x1c9>
f0103825:	eb 30                	jmp    f0103857 <debuginfo_eip+0x1e3>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0103827:	83 e8 01             	sub    $0x1,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f010382a:	39 c1                	cmp    %eax,%ecx
f010382c:	7f 48                	jg     f0103876 <debuginfo_eip+0x202>
	       && stabs[lline].n_type != N_SOL
f010382e:	89 c2                	mov    %eax,%edx
f0103830:	8d 34 40             	lea    (%eax,%eax,2),%esi
f0103833:	80 3c b5 cc 5a 10 f0 	cmpb   $0x84,-0xfefa534(,%esi,4)
f010383a:	84 
f010383b:	74 1a                	je     f0103857 <debuginfo_eip+0x1e3>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f010383d:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0103840:	8d 14 95 c8 5a 10 f0 	lea    -0xfefa538(,%edx,4),%edx
f0103847:	80 7a 04 64          	cmpb   $0x64,0x4(%edx)
f010384b:	75 da                	jne    f0103827 <debuginfo_eip+0x1b3>
f010384d:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f0103851:	74 d4                	je     f0103827 <debuginfo_eip+0x1b3>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0103853:	39 c8                	cmp    %ecx,%eax
f0103855:	7c 1f                	jl     f0103876 <debuginfo_eip+0x202>
f0103857:	6b c0 0c             	imul   $0xc,%eax,%eax
f010385a:	8b 80 c8 5a 10 f0    	mov    -0xfefa538(%eax),%eax
f0103860:	ba 3b e8 10 f0       	mov    $0xf010e83b,%edx
f0103865:	81 ea 0d c8 10 f0    	sub    $0xf010c80d,%edx
f010386b:	39 d0                	cmp    %edx,%eax
f010386d:	73 07                	jae    f0103876 <debuginfo_eip+0x202>
		info->eip_file = stabstr + stabs[lline].n_strx;
f010386f:	05 0d c8 10 f0       	add    $0xf010c80d,%eax
f0103874:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103876:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103879:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f010387c:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103881:	39 ca                	cmp    %ecx,%edx
f0103883:	7d 3e                	jge    f01038c3 <debuginfo_eip+0x24f>
		for (lline = lfun + 1;
f0103885:	83 c2 01             	add    $0x1,%edx
f0103888:	39 d1                	cmp    %edx,%ecx
f010388a:	7e 37                	jle    f01038c3 <debuginfo_eip+0x24f>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f010388c:	6b f2 0c             	imul   $0xc,%edx,%esi
f010388f:	80 be cc 5a 10 f0 a0 	cmpb   $0xa0,-0xfefa534(%esi)
f0103896:	75 2b                	jne    f01038c3 <debuginfo_eip+0x24f>
		     lline++)
			info->eip_fn_narg++;
f0103898:	83 43 14 01          	addl   $0x1,0x14(%ebx)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f010389c:	83 c2 01             	add    $0x1,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f010389f:	39 d1                	cmp    %edx,%ecx
f01038a1:	7e 1b                	jle    f01038be <debuginfo_eip+0x24a>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f01038a3:	8d 04 52             	lea    (%edx,%edx,2),%eax
f01038a6:	80 3c 85 cc 5a 10 f0 	cmpb   $0xa0,-0xfefa534(,%eax,4)
f01038ad:	a0 
f01038ae:	74 e8                	je     f0103898 <debuginfo_eip+0x224>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01038b0:	b8 00 00 00 00       	mov    $0x0,%eax
f01038b5:	eb 0c                	jmp    f01038c3 <debuginfo_eip+0x24f>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f01038b7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01038bc:	eb 05                	jmp    f01038c3 <debuginfo_eip+0x24f>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01038be:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01038c3:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f01038c6:	8b 75 f8             	mov    -0x8(%ebp),%esi
f01038c9:	8b 7d fc             	mov    -0x4(%ebp),%edi
f01038cc:	89 ec                	mov    %ebp,%esp
f01038ce:	5d                   	pop    %ebp
f01038cf:	c3                   	ret    

f01038d0 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f01038d0:	55                   	push   %ebp
f01038d1:	89 e5                	mov    %esp,%ebp
f01038d3:	57                   	push   %edi
f01038d4:	56                   	push   %esi
f01038d5:	53                   	push   %ebx
f01038d6:	83 ec 3c             	sub    $0x3c,%esp
f01038d9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01038dc:	89 d7                	mov    %edx,%edi
f01038de:	8b 45 08             	mov    0x8(%ebp),%eax
f01038e1:	89 45 dc             	mov    %eax,-0x24(%ebp)
f01038e4:	8b 45 0c             	mov    0xc(%ebp),%eax
f01038e7:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01038ea:	8b 5d 14             	mov    0x14(%ebp),%ebx
f01038ed:	8b 75 18             	mov    0x18(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f01038f0:	b8 00 00 00 00       	mov    $0x0,%eax
f01038f5:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f01038f8:	72 11                	jb     f010390b <printnum+0x3b>
f01038fa:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01038fd:	39 45 10             	cmp    %eax,0x10(%ebp)
f0103900:	76 09                	jbe    f010390b <printnum+0x3b>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0103902:	83 eb 01             	sub    $0x1,%ebx
f0103905:	85 db                	test   %ebx,%ebx
f0103907:	7f 51                	jg     f010395a <printnum+0x8a>
f0103909:	eb 5e                	jmp    f0103969 <printnum+0x99>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
f010390b:	89 74 24 10          	mov    %esi,0x10(%esp)
f010390f:	83 eb 01             	sub    $0x1,%ebx
f0103912:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0103916:	8b 45 10             	mov    0x10(%ebp),%eax
f0103919:	89 44 24 08          	mov    %eax,0x8(%esp)
f010391d:	8b 5c 24 08          	mov    0x8(%esp),%ebx
f0103921:	8b 74 24 0c          	mov    0xc(%esp),%esi
f0103925:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f010392c:	00 
f010392d:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103930:	89 04 24             	mov    %eax,(%esp)
f0103933:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103936:	89 44 24 04          	mov    %eax,0x4(%esp)
f010393a:	e8 41 0a 00 00       	call   f0104380 <__udivdi3>
f010393f:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0103943:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0103947:	89 04 24             	mov    %eax,(%esp)
f010394a:	89 54 24 04          	mov    %edx,0x4(%esp)
f010394e:	89 fa                	mov    %edi,%edx
f0103950:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103953:	e8 78 ff ff ff       	call   f01038d0 <printnum>
f0103958:	eb 0f                	jmp    f0103969 <printnum+0x99>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f010395a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010395e:	89 34 24             	mov    %esi,(%esp)
f0103961:	ff 55 e4             	call   *-0x1c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0103964:	83 eb 01             	sub    $0x1,%ebx
f0103967:	75 f1                	jne    f010395a <printnum+0x8a>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0103969:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010396d:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0103971:	8b 45 10             	mov    0x10(%ebp),%eax
f0103974:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103978:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f010397f:	00 
f0103980:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103983:	89 04 24             	mov    %eax,(%esp)
f0103986:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103989:	89 44 24 04          	mov    %eax,0x4(%esp)
f010398d:	e8 1e 0b 00 00       	call   f01044b0 <__umoddi3>
f0103992:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103996:	0f be 80 c7 58 10 f0 	movsbl -0xfefa739(%eax),%eax
f010399d:	89 04 24             	mov    %eax,(%esp)
f01039a0:	ff 55 e4             	call   *-0x1c(%ebp)
}
f01039a3:	83 c4 3c             	add    $0x3c,%esp
f01039a6:	5b                   	pop    %ebx
f01039a7:	5e                   	pop    %esi
f01039a8:	5f                   	pop    %edi
f01039a9:	5d                   	pop    %ebp
f01039aa:	c3                   	ret    

f01039ab <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f01039ab:	55                   	push   %ebp
f01039ac:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f01039ae:	83 fa 01             	cmp    $0x1,%edx
f01039b1:	7e 0e                	jle    f01039c1 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f01039b3:	8b 10                	mov    (%eax),%edx
f01039b5:	8d 4a 08             	lea    0x8(%edx),%ecx
f01039b8:	89 08                	mov    %ecx,(%eax)
f01039ba:	8b 02                	mov    (%edx),%eax
f01039bc:	8b 52 04             	mov    0x4(%edx),%edx
f01039bf:	eb 22                	jmp    f01039e3 <getuint+0x38>
	else if (lflag)
f01039c1:	85 d2                	test   %edx,%edx
f01039c3:	74 10                	je     f01039d5 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f01039c5:	8b 10                	mov    (%eax),%edx
f01039c7:	8d 4a 04             	lea    0x4(%edx),%ecx
f01039ca:	89 08                	mov    %ecx,(%eax)
f01039cc:	8b 02                	mov    (%edx),%eax
f01039ce:	ba 00 00 00 00       	mov    $0x0,%edx
f01039d3:	eb 0e                	jmp    f01039e3 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f01039d5:	8b 10                	mov    (%eax),%edx
f01039d7:	8d 4a 04             	lea    0x4(%edx),%ecx
f01039da:	89 08                	mov    %ecx,(%eax)
f01039dc:	8b 02                	mov    (%edx),%eax
f01039de:	ba 00 00 00 00       	mov    $0x0,%edx
}
f01039e3:	5d                   	pop    %ebp
f01039e4:	c3                   	ret    

f01039e5 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f01039e5:	55                   	push   %ebp
f01039e6:	89 e5                	mov    %esp,%ebp
f01039e8:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f01039eb:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f01039ef:	8b 10                	mov    (%eax),%edx
f01039f1:	3b 50 04             	cmp    0x4(%eax),%edx
f01039f4:	73 0a                	jae    f0103a00 <sprintputch+0x1b>
		*b->buf++ = ch;
f01039f6:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01039f9:	88 0a                	mov    %cl,(%edx)
f01039fb:	83 c2 01             	add    $0x1,%edx
f01039fe:	89 10                	mov    %edx,(%eax)
}
f0103a00:	5d                   	pop    %ebp
f0103a01:	c3                   	ret    

f0103a02 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0103a02:	55                   	push   %ebp
f0103a03:	89 e5                	mov    %esp,%ebp
f0103a05:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f0103a08:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f0103a0b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103a0f:	8b 45 10             	mov    0x10(%ebp),%eax
f0103a12:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103a16:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103a19:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103a1d:	8b 45 08             	mov    0x8(%ebp),%eax
f0103a20:	89 04 24             	mov    %eax,(%esp)
f0103a23:	e8 02 00 00 00       	call   f0103a2a <vprintfmt>
	va_end(ap);
}
f0103a28:	c9                   	leave  
f0103a29:	c3                   	ret    

f0103a2a <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f0103a2a:	55                   	push   %ebp
f0103a2b:	89 e5                	mov    %esp,%ebp
f0103a2d:	57                   	push   %edi
f0103a2e:	56                   	push   %esi
f0103a2f:	53                   	push   %ebx
f0103a30:	83 ec 4c             	sub    $0x4c,%esp
f0103a33:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103a36:	8b 75 10             	mov    0x10(%ebp),%esi
f0103a39:	eb 12                	jmp    f0103a4d <vprintfmt+0x23>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f0103a3b:	85 c0                	test   %eax,%eax
f0103a3d:	0f 84 a9 03 00 00    	je     f0103dec <vprintfmt+0x3c2>
				return;
			putch(ch, putdat);
f0103a43:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103a47:	89 04 24             	mov    %eax,(%esp)
f0103a4a:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f0103a4d:	0f b6 06             	movzbl (%esi),%eax
f0103a50:	83 c6 01             	add    $0x1,%esi
f0103a53:	83 f8 25             	cmp    $0x25,%eax
f0103a56:	75 e3                	jne    f0103a3b <vprintfmt+0x11>
f0103a58:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
f0103a5c:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
f0103a63:	bf ff ff ff ff       	mov    $0xffffffff,%edi
f0103a68:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
f0103a6f:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103a74:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0103a77:	eb 2b                	jmp    f0103aa4 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103a79:	8b 75 e0             	mov    -0x20(%ebp),%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f0103a7c:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
f0103a80:	eb 22                	jmp    f0103aa4 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103a82:	8b 75 e0             	mov    -0x20(%ebp),%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0103a85:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
f0103a89:	eb 19                	jmp    f0103aa4 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103a8b:	8b 75 e0             	mov    -0x20(%ebp),%esi
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
f0103a8e:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f0103a95:	eb 0d                	jmp    f0103aa4 <vprintfmt+0x7a>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f0103a97:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103a9a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0103a9d:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103aa4:	0f b6 06             	movzbl (%esi),%eax
f0103aa7:	0f b6 d0             	movzbl %al,%edx
f0103aaa:	8d 7e 01             	lea    0x1(%esi),%edi
f0103aad:	89 7d e0             	mov    %edi,-0x20(%ebp)
f0103ab0:	83 e8 23             	sub    $0x23,%eax
f0103ab3:	3c 55                	cmp    $0x55,%al
f0103ab5:	0f 87 0b 03 00 00    	ja     f0103dc6 <vprintfmt+0x39c>
f0103abb:	0f b6 c0             	movzbl %al,%eax
f0103abe:	ff 24 85 44 59 10 f0 	jmp    *-0xfefa6bc(,%eax,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0103ac5:	83 ea 30             	sub    $0x30,%edx
f0103ac8:	89 55 d4             	mov    %edx,-0x2c(%ebp)
				ch = *fmt;
f0103acb:	0f be 46 01          	movsbl 0x1(%esi),%eax
				if (ch < '0' || ch > '9')
f0103acf:	8d 50 d0             	lea    -0x30(%eax),%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103ad2:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
f0103ad5:	83 fa 09             	cmp    $0x9,%edx
f0103ad8:	77 4a                	ja     f0103b24 <vprintfmt+0xfa>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103ada:	8b 7d d4             	mov    -0x2c(%ebp),%edi
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f0103add:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
f0103ae0:	8d 14 bf             	lea    (%edi,%edi,4),%edx
f0103ae3:	8d 7c 50 d0          	lea    -0x30(%eax,%edx,2),%edi
				ch = *fmt;
f0103ae7:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f0103aea:	8d 50 d0             	lea    -0x30(%eax),%edx
f0103aed:	83 fa 09             	cmp    $0x9,%edx
f0103af0:	76 eb                	jbe    f0103add <vprintfmt+0xb3>
f0103af2:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0103af5:	eb 2d                	jmp    f0103b24 <vprintfmt+0xfa>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0103af7:	8b 45 14             	mov    0x14(%ebp),%eax
f0103afa:	8d 50 04             	lea    0x4(%eax),%edx
f0103afd:	89 55 14             	mov    %edx,0x14(%ebp)
f0103b00:	8b 00                	mov    (%eax),%eax
f0103b02:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103b05:	8b 75 e0             	mov    -0x20(%ebp),%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0103b08:	eb 1a                	jmp    f0103b24 <vprintfmt+0xfa>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103b0a:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case '*':
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
f0103b0d:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0103b11:	79 91                	jns    f0103aa4 <vprintfmt+0x7a>
f0103b13:	e9 73 ff ff ff       	jmp    f0103a8b <vprintfmt+0x61>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103b18:	8b 75 e0             	mov    -0x20(%ebp),%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f0103b1b:	c7 45 dc 01 00 00 00 	movl   $0x1,-0x24(%ebp)
			goto reswitch;
f0103b22:	eb 80                	jmp    f0103aa4 <vprintfmt+0x7a>

		process_precision:
			if (width < 0)
f0103b24:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0103b28:	0f 89 76 ff ff ff    	jns    f0103aa4 <vprintfmt+0x7a>
f0103b2e:	e9 64 ff ff ff       	jmp    f0103a97 <vprintfmt+0x6d>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0103b33:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103b36:	8b 75 e0             	mov    -0x20(%ebp),%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0103b39:	e9 66 ff ff ff       	jmp    f0103aa4 <vprintfmt+0x7a>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f0103b3e:	8b 45 14             	mov    0x14(%ebp),%eax
f0103b41:	8d 50 04             	lea    0x4(%eax),%edx
f0103b44:	89 55 14             	mov    %edx,0x14(%ebp)
f0103b47:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103b4b:	8b 00                	mov    (%eax),%eax
f0103b4d:	89 04 24             	mov    %eax,(%esp)
f0103b50:	ff 55 08             	call   *0x8(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103b53:	8b 75 e0             	mov    -0x20(%ebp),%esi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0103b56:	e9 f2 fe ff ff       	jmp    f0103a4d <vprintfmt+0x23>

		// error message
		case 'e':
			err = va_arg(ap, int);
f0103b5b:	8b 45 14             	mov    0x14(%ebp),%eax
f0103b5e:	8d 50 04             	lea    0x4(%eax),%edx
f0103b61:	89 55 14             	mov    %edx,0x14(%ebp)
f0103b64:	8b 00                	mov    (%eax),%eax
f0103b66:	89 c2                	mov    %eax,%edx
f0103b68:	c1 fa 1f             	sar    $0x1f,%edx
f0103b6b:	31 d0                	xor    %edx,%eax
f0103b6d:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f0103b6f:	83 f8 06             	cmp    $0x6,%eax
f0103b72:	7f 0b                	jg     f0103b7f <vprintfmt+0x155>
f0103b74:	8b 14 85 9c 5a 10 f0 	mov    -0xfefa564(,%eax,4),%edx
f0103b7b:	85 d2                	test   %edx,%edx
f0103b7d:	75 23                	jne    f0103ba2 <vprintfmt+0x178>
				printfmt(putch, putdat, "error %d", err);
f0103b7f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103b83:	c7 44 24 08 df 58 10 	movl   $0xf01058df,0x8(%esp)
f0103b8a:	f0 
f0103b8b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103b8f:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103b92:	89 3c 24             	mov    %edi,(%esp)
f0103b95:	e8 68 fe ff ff       	call   f0103a02 <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103b9a:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f0103b9d:	e9 ab fe ff ff       	jmp    f0103a4d <vprintfmt+0x23>
			else
				printfmt(putch, putdat, "%s", p);
f0103ba2:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103ba6:	c7 44 24 08 10 56 10 	movl   $0xf0105610,0x8(%esp)
f0103bad:	f0 
f0103bae:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103bb2:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103bb5:	89 3c 24             	mov    %edi,(%esp)
f0103bb8:	e8 45 fe ff ff       	call   f0103a02 <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103bbd:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0103bc0:	e9 88 fe ff ff       	jmp    f0103a4d <vprintfmt+0x23>
f0103bc5:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0103bc8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103bcb:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f0103bce:	8b 45 14             	mov    0x14(%ebp),%eax
f0103bd1:	8d 50 04             	lea    0x4(%eax),%edx
f0103bd4:	89 55 14             	mov    %edx,0x14(%ebp)
f0103bd7:	8b 30                	mov    (%eax),%esi
				p = "(null)";
f0103bd9:	85 f6                	test   %esi,%esi
f0103bdb:	ba d8 58 10 f0       	mov    $0xf01058d8,%edx
f0103be0:	0f 44 f2             	cmove  %edx,%esi
			if (width > 0 && padc != '-')
f0103be3:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f0103be7:	7e 06                	jle    f0103bef <vprintfmt+0x1c5>
f0103be9:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
f0103bed:	75 10                	jne    f0103bff <vprintfmt+0x1d5>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0103bef:	0f be 06             	movsbl (%esi),%eax
f0103bf2:	83 c6 01             	add    $0x1,%esi
f0103bf5:	85 c0                	test   %eax,%eax
f0103bf7:	0f 85 86 00 00 00    	jne    f0103c83 <vprintfmt+0x259>
f0103bfd:	eb 76                	jmp    f0103c75 <vprintfmt+0x24b>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0103bff:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103c03:	89 34 24             	mov    %esi,(%esp)
f0103c06:	e8 60 03 00 00       	call   f0103f6b <strnlen>
f0103c0b:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0103c0e:	29 c2                	sub    %eax,%edx
f0103c10:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0103c13:	85 d2                	test   %edx,%edx
f0103c15:	7e d8                	jle    f0103bef <vprintfmt+0x1c5>
					putch(padc, putdat);
f0103c17:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
f0103c1b:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f0103c1e:	89 d6                	mov    %edx,%esi
f0103c20:	89 7d d0             	mov    %edi,-0x30(%ebp)
f0103c23:	89 c7                	mov    %eax,%edi
f0103c25:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103c29:	89 3c 24             	mov    %edi,(%esp)
f0103c2c:	ff 55 08             	call   *0x8(%ebp)
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f0103c2f:	83 ee 01             	sub    $0x1,%esi
f0103c32:	75 f1                	jne    f0103c25 <vprintfmt+0x1fb>
f0103c34:	89 75 e4             	mov    %esi,-0x1c(%ebp)
f0103c37:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f0103c3a:	8b 7d d0             	mov    -0x30(%ebp),%edi
f0103c3d:	eb b0                	jmp    f0103bef <vprintfmt+0x1c5>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f0103c3f:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0103c43:	74 18                	je     f0103c5d <vprintfmt+0x233>
f0103c45:	8d 50 e0             	lea    -0x20(%eax),%edx
f0103c48:	83 fa 5e             	cmp    $0x5e,%edx
f0103c4b:	76 10                	jbe    f0103c5d <vprintfmt+0x233>
					putch('?', putdat);
f0103c4d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103c51:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0103c58:	ff 55 08             	call   *0x8(%ebp)
f0103c5b:	eb 0a                	jmp    f0103c67 <vprintfmt+0x23d>
				else
					putch(ch, putdat);
f0103c5d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103c61:	89 04 24             	mov    %eax,(%esp)
f0103c64:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0103c67:	83 6d e4 01          	subl   $0x1,-0x1c(%ebp)
f0103c6b:	0f be 06             	movsbl (%esi),%eax
f0103c6e:	83 c6 01             	add    $0x1,%esi
f0103c71:	85 c0                	test   %eax,%eax
f0103c73:	75 0e                	jne    f0103c83 <vprintfmt+0x259>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103c75:	8b 75 e0             	mov    -0x20(%ebp),%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0103c78:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0103c7c:	7f 16                	jg     f0103c94 <vprintfmt+0x26a>
f0103c7e:	e9 ca fd ff ff       	jmp    f0103a4d <vprintfmt+0x23>
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0103c83:	85 ff                	test   %edi,%edi
f0103c85:	78 b8                	js     f0103c3f <vprintfmt+0x215>
f0103c87:	83 ef 01             	sub    $0x1,%edi
f0103c8a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103c90:	79 ad                	jns    f0103c3f <vprintfmt+0x215>
f0103c92:	eb e1                	jmp    f0103c75 <vprintfmt+0x24b>
f0103c94:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103c97:	8b 7d 08             	mov    0x8(%ebp),%edi
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f0103c9a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103c9e:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0103ca5:	ff d7                	call   *%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0103ca7:	83 ee 01             	sub    $0x1,%esi
f0103caa:	75 ee                	jne    f0103c9a <vprintfmt+0x270>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103cac:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0103caf:	e9 99 fd ff ff       	jmp    f0103a4d <vprintfmt+0x23>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0103cb4:	83 f9 01             	cmp    $0x1,%ecx
f0103cb7:	7e 10                	jle    f0103cc9 <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f0103cb9:	8b 45 14             	mov    0x14(%ebp),%eax
f0103cbc:	8d 50 08             	lea    0x8(%eax),%edx
f0103cbf:	89 55 14             	mov    %edx,0x14(%ebp)
f0103cc2:	8b 30                	mov    (%eax),%esi
f0103cc4:	8b 78 04             	mov    0x4(%eax),%edi
f0103cc7:	eb 26                	jmp    f0103cef <vprintfmt+0x2c5>
	else if (lflag)
f0103cc9:	85 c9                	test   %ecx,%ecx
f0103ccb:	74 12                	je     f0103cdf <vprintfmt+0x2b5>
		return va_arg(*ap, long);
f0103ccd:	8b 45 14             	mov    0x14(%ebp),%eax
f0103cd0:	8d 50 04             	lea    0x4(%eax),%edx
f0103cd3:	89 55 14             	mov    %edx,0x14(%ebp)
f0103cd6:	8b 30                	mov    (%eax),%esi
f0103cd8:	89 f7                	mov    %esi,%edi
f0103cda:	c1 ff 1f             	sar    $0x1f,%edi
f0103cdd:	eb 10                	jmp    f0103cef <vprintfmt+0x2c5>
	else
		return va_arg(*ap, int);
f0103cdf:	8b 45 14             	mov    0x14(%ebp),%eax
f0103ce2:	8d 50 04             	lea    0x4(%eax),%edx
f0103ce5:	89 55 14             	mov    %edx,0x14(%ebp)
f0103ce8:	8b 30                	mov    (%eax),%esi
f0103cea:	89 f7                	mov    %esi,%edi
f0103cec:	c1 ff 1f             	sar    $0x1f,%edi
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f0103cef:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0103cf4:	85 ff                	test   %edi,%edi
f0103cf6:	0f 89 8c 00 00 00    	jns    f0103d88 <vprintfmt+0x35e>
				putch('-', putdat);
f0103cfc:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103d00:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f0103d07:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f0103d0a:	f7 de                	neg    %esi
f0103d0c:	83 d7 00             	adc    $0x0,%edi
f0103d0f:	f7 df                	neg    %edi
			}
			base = 10;
f0103d11:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103d16:	eb 70                	jmp    f0103d88 <vprintfmt+0x35e>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0103d18:	89 ca                	mov    %ecx,%edx
f0103d1a:	8d 45 14             	lea    0x14(%ebp),%eax
f0103d1d:	e8 89 fc ff ff       	call   f01039ab <getuint>
f0103d22:	89 c6                	mov    %eax,%esi
f0103d24:	89 d7                	mov    %edx,%edi
			base = 10;
f0103d26:	b8 0a 00 00 00       	mov    $0xa,%eax
			goto number;
f0103d2b:	eb 5b                	jmp    f0103d88 <vprintfmt+0x35e>
			// Replace this with your code.
			//putch('0', putdat);
			//putch('X', putdat);
			//putch('X', putdat);
			//break;
			num = getuint(&ap, lflag);
f0103d2d:	89 ca                	mov    %ecx,%edx
f0103d2f:	8d 45 14             	lea    0x14(%ebp),%eax
f0103d32:	e8 74 fc ff ff       	call   f01039ab <getuint>
f0103d37:	89 c6                	mov    %eax,%esi
f0103d39:	89 d7                	mov    %edx,%edi
			base = 8;
f0103d3b:	b8 08 00 00 00       	mov    $0x8,%eax
			goto number;
f0103d40:	eb 46                	jmp    f0103d88 <vprintfmt+0x35e>
		// pointer
		case 'p':
			putch('0', putdat);
f0103d42:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103d46:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f0103d4d:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f0103d50:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103d54:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f0103d5b:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f0103d5e:	8b 45 14             	mov    0x14(%ebp),%eax
f0103d61:	8d 50 04             	lea    0x4(%eax),%edx
f0103d64:	89 55 14             	mov    %edx,0x14(%ebp)
			goto number;
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0103d67:	8b 30                	mov    (%eax),%esi
f0103d69:	bf 00 00 00 00       	mov    $0x0,%edi
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f0103d6e:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f0103d73:	eb 13                	jmp    f0103d88 <vprintfmt+0x35e>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0103d75:	89 ca                	mov    %ecx,%edx
f0103d77:	8d 45 14             	lea    0x14(%ebp),%eax
f0103d7a:	e8 2c fc ff ff       	call   f01039ab <getuint>
f0103d7f:	89 c6                	mov    %eax,%esi
f0103d81:	89 d7                	mov    %edx,%edi
			base = 16;
f0103d83:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f0103d88:	0f be 55 d8          	movsbl -0x28(%ebp),%edx
f0103d8c:	89 54 24 10          	mov    %edx,0x10(%esp)
f0103d90:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0103d93:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103d97:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103d9b:	89 34 24             	mov    %esi,(%esp)
f0103d9e:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103da2:	89 da                	mov    %ebx,%edx
f0103da4:	8b 45 08             	mov    0x8(%ebp),%eax
f0103da7:	e8 24 fb ff ff       	call   f01038d0 <printnum>
			break;
f0103dac:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0103daf:	e9 99 fc ff ff       	jmp    f0103a4d <vprintfmt+0x23>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0103db4:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103db8:	89 14 24             	mov    %edx,(%esp)
f0103dbb:	ff 55 08             	call   *0x8(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103dbe:	8b 75 e0             	mov    -0x20(%ebp),%esi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0103dc1:	e9 87 fc ff ff       	jmp    f0103a4d <vprintfmt+0x23>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0103dc6:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103dca:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0103dd1:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0103dd4:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
f0103dd8:	0f 84 6f fc ff ff    	je     f0103a4d <vprintfmt+0x23>
f0103dde:	83 ee 01             	sub    $0x1,%esi
f0103de1:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
f0103de5:	75 f7                	jne    f0103dde <vprintfmt+0x3b4>
f0103de7:	e9 61 fc ff ff       	jmp    f0103a4d <vprintfmt+0x23>
				/* do nothing */;
			break;
		}
	}
}
f0103dec:	83 c4 4c             	add    $0x4c,%esp
f0103def:	5b                   	pop    %ebx
f0103df0:	5e                   	pop    %esi
f0103df1:	5f                   	pop    %edi
f0103df2:	5d                   	pop    %ebp
f0103df3:	c3                   	ret    

f0103df4 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0103df4:	55                   	push   %ebp
f0103df5:	89 e5                	mov    %esp,%ebp
f0103df7:	83 ec 28             	sub    $0x28,%esp
f0103dfa:	8b 45 08             	mov    0x8(%ebp),%eax
f0103dfd:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0103e00:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103e03:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0103e07:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f0103e0a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0103e11:	85 c0                	test   %eax,%eax
f0103e13:	74 30                	je     f0103e45 <vsnprintf+0x51>
f0103e15:	85 d2                	test   %edx,%edx
f0103e17:	7e 2c                	jle    f0103e45 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0103e19:	8b 45 14             	mov    0x14(%ebp),%eax
f0103e1c:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103e20:	8b 45 10             	mov    0x10(%ebp),%eax
f0103e23:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103e27:	8d 45 ec             	lea    -0x14(%ebp),%eax
f0103e2a:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103e2e:	c7 04 24 e5 39 10 f0 	movl   $0xf01039e5,(%esp)
f0103e35:	e8 f0 fb ff ff       	call   f0103a2a <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f0103e3a:	8b 45 ec             	mov    -0x14(%ebp),%eax
f0103e3d:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0103e40:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103e43:	eb 05                	jmp    f0103e4a <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0103e45:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f0103e4a:	c9                   	leave  
f0103e4b:	c3                   	ret    

f0103e4c <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f0103e4c:	55                   	push   %ebp
f0103e4d:	89 e5                	mov    %esp,%ebp
f0103e4f:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0103e52:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0103e55:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103e59:	8b 45 10             	mov    0x10(%ebp),%eax
f0103e5c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103e60:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103e63:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103e67:	8b 45 08             	mov    0x8(%ebp),%eax
f0103e6a:	89 04 24             	mov    %eax,(%esp)
f0103e6d:	e8 82 ff ff ff       	call   f0103df4 <vsnprintf>
	va_end(ap);

	return rc;
}
f0103e72:	c9                   	leave  
f0103e73:	c3                   	ret    
	...

f0103e80 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0103e80:	55                   	push   %ebp
f0103e81:	89 e5                	mov    %esp,%ebp
f0103e83:	57                   	push   %edi
f0103e84:	56                   	push   %esi
f0103e85:	53                   	push   %ebx
f0103e86:	83 ec 1c             	sub    $0x1c,%esp
f0103e89:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f0103e8c:	85 c0                	test   %eax,%eax
f0103e8e:	74 10                	je     f0103ea0 <readline+0x20>
		cprintf("%s", prompt);
f0103e90:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103e94:	c7 04 24 10 56 10 f0 	movl   $0xf0105610,(%esp)
f0103e9b:	e8 da f6 ff ff       	call   f010357a <cprintf>

	i = 0;
	echoing = iscons(0);
f0103ea0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0103ea7:	e8 6e c7 ff ff       	call   f010061a <iscons>
f0103eac:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f0103eae:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0103eb3:	e8 51 c7 ff ff       	call   f0100609 <getchar>
f0103eb8:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f0103eba:	85 c0                	test   %eax,%eax
f0103ebc:	79 17                	jns    f0103ed5 <readline+0x55>
			cprintf("read error: %e\n", c);
f0103ebe:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103ec2:	c7 04 24 b8 5a 10 f0 	movl   $0xf0105ab8,(%esp)
f0103ec9:	e8 ac f6 ff ff       	call   f010357a <cprintf>
			return NULL;
f0103ece:	b8 00 00 00 00       	mov    $0x0,%eax
f0103ed3:	eb 6d                	jmp    f0103f42 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0103ed5:	83 f8 08             	cmp    $0x8,%eax
f0103ed8:	74 05                	je     f0103edf <readline+0x5f>
f0103eda:	83 f8 7f             	cmp    $0x7f,%eax
f0103edd:	75 19                	jne    f0103ef8 <readline+0x78>
f0103edf:	85 f6                	test   %esi,%esi
f0103ee1:	7e 15                	jle    f0103ef8 <readline+0x78>
			if (echoing)
f0103ee3:	85 ff                	test   %edi,%edi
f0103ee5:	74 0c                	je     f0103ef3 <readline+0x73>
				cputchar('\b');
f0103ee7:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f0103eee:	e8 06 c7 ff ff       	call   f01005f9 <cputchar>
			i--;
f0103ef3:	83 ee 01             	sub    $0x1,%esi
f0103ef6:	eb bb                	jmp    f0103eb3 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0103ef8:	83 fb 1f             	cmp    $0x1f,%ebx
f0103efb:	7e 1f                	jle    f0103f1c <readline+0x9c>
f0103efd:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0103f03:	7f 17                	jg     f0103f1c <readline+0x9c>
			if (echoing)
f0103f05:	85 ff                	test   %edi,%edi
f0103f07:	74 08                	je     f0103f11 <readline+0x91>
				cputchar(c);
f0103f09:	89 1c 24             	mov    %ebx,(%esp)
f0103f0c:	e8 e8 c6 ff ff       	call   f01005f9 <cputchar>
			buf[i++] = c;
f0103f11:	88 9e 80 95 11 f0    	mov    %bl,-0xfee6a80(%esi)
f0103f17:	83 c6 01             	add    $0x1,%esi
f0103f1a:	eb 97                	jmp    f0103eb3 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f0103f1c:	83 fb 0a             	cmp    $0xa,%ebx
f0103f1f:	74 05                	je     f0103f26 <readline+0xa6>
f0103f21:	83 fb 0d             	cmp    $0xd,%ebx
f0103f24:	75 8d                	jne    f0103eb3 <readline+0x33>
			if (echoing)
f0103f26:	85 ff                	test   %edi,%edi
f0103f28:	74 0c                	je     f0103f36 <readline+0xb6>
				cputchar('\n');
f0103f2a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0103f31:	e8 c3 c6 ff ff       	call   f01005f9 <cputchar>
			buf[i] = 0;
f0103f36:	c6 86 80 95 11 f0 00 	movb   $0x0,-0xfee6a80(%esi)
			return buf;
f0103f3d:	b8 80 95 11 f0       	mov    $0xf0119580,%eax
		}
	}
}
f0103f42:	83 c4 1c             	add    $0x1c,%esp
f0103f45:	5b                   	pop    %ebx
f0103f46:	5e                   	pop    %esi
f0103f47:	5f                   	pop    %edi
f0103f48:	5d                   	pop    %ebp
f0103f49:	c3                   	ret    
f0103f4a:	00 00                	add    %al,(%eax)
f0103f4c:	00 00                	add    %al,(%eax)
	...

f0103f50 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0103f50:	55                   	push   %ebp
f0103f51:	89 e5                	mov    %esp,%ebp
f0103f53:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0103f56:	b8 00 00 00 00       	mov    $0x0,%eax
f0103f5b:	80 3a 00             	cmpb   $0x0,(%edx)
f0103f5e:	74 09                	je     f0103f69 <strlen+0x19>
		n++;
f0103f60:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0103f63:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0103f67:	75 f7                	jne    f0103f60 <strlen+0x10>
		n++;
	return n;
}
f0103f69:	5d                   	pop    %ebp
f0103f6a:	c3                   	ret    

f0103f6b <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0103f6b:	55                   	push   %ebp
f0103f6c:	89 e5                	mov    %esp,%ebp
f0103f6e:	53                   	push   %ebx
f0103f6f:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103f72:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103f75:	b8 00 00 00 00       	mov    $0x0,%eax
f0103f7a:	85 c9                	test   %ecx,%ecx
f0103f7c:	74 1a                	je     f0103f98 <strnlen+0x2d>
f0103f7e:	80 3b 00             	cmpb   $0x0,(%ebx)
f0103f81:	74 15                	je     f0103f98 <strnlen+0x2d>
f0103f83:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
f0103f88:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103f8a:	39 ca                	cmp    %ecx,%edx
f0103f8c:	74 0a                	je     f0103f98 <strnlen+0x2d>
f0103f8e:	83 c2 01             	add    $0x1,%edx
f0103f91:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
f0103f96:	75 f0                	jne    f0103f88 <strnlen+0x1d>
		n++;
	return n;
}
f0103f98:	5b                   	pop    %ebx
f0103f99:	5d                   	pop    %ebp
f0103f9a:	c3                   	ret    

f0103f9b <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0103f9b:	55                   	push   %ebp
f0103f9c:	89 e5                	mov    %esp,%ebp
f0103f9e:	53                   	push   %ebx
f0103f9f:	8b 45 08             	mov    0x8(%ebp),%eax
f0103fa2:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0103fa5:	ba 00 00 00 00       	mov    $0x0,%edx
f0103faa:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f0103fae:	88 0c 10             	mov    %cl,(%eax,%edx,1)
f0103fb1:	83 c2 01             	add    $0x1,%edx
f0103fb4:	84 c9                	test   %cl,%cl
f0103fb6:	75 f2                	jne    f0103faa <strcpy+0xf>
		/* do nothing */;
	return ret;
}
f0103fb8:	5b                   	pop    %ebx
f0103fb9:	5d                   	pop    %ebp
f0103fba:	c3                   	ret    

f0103fbb <strcat>:

char *
strcat(char *dst, const char *src)
{
f0103fbb:	55                   	push   %ebp
f0103fbc:	89 e5                	mov    %esp,%ebp
f0103fbe:	53                   	push   %ebx
f0103fbf:	83 ec 08             	sub    $0x8,%esp
f0103fc2:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0103fc5:	89 1c 24             	mov    %ebx,(%esp)
f0103fc8:	e8 83 ff ff ff       	call   f0103f50 <strlen>
	strcpy(dst + len, src);
f0103fcd:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103fd0:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103fd4:	01 d8                	add    %ebx,%eax
f0103fd6:	89 04 24             	mov    %eax,(%esp)
f0103fd9:	e8 bd ff ff ff       	call   f0103f9b <strcpy>
	return dst;
}
f0103fde:	89 d8                	mov    %ebx,%eax
f0103fe0:	83 c4 08             	add    $0x8,%esp
f0103fe3:	5b                   	pop    %ebx
f0103fe4:	5d                   	pop    %ebp
f0103fe5:	c3                   	ret    

f0103fe6 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0103fe6:	55                   	push   %ebp
f0103fe7:	89 e5                	mov    %esp,%ebp
f0103fe9:	56                   	push   %esi
f0103fea:	53                   	push   %ebx
f0103feb:	8b 45 08             	mov    0x8(%ebp),%eax
f0103fee:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103ff1:	8b 75 10             	mov    0x10(%ebp),%esi
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103ff4:	85 f6                	test   %esi,%esi
f0103ff6:	74 18                	je     f0104010 <strncpy+0x2a>
f0103ff8:	b9 00 00 00 00       	mov    $0x0,%ecx
		*dst++ = *src;
f0103ffd:	0f b6 1a             	movzbl (%edx),%ebx
f0104000:	88 1c 08             	mov    %bl,(%eax,%ecx,1)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0104003:	80 3a 01             	cmpb   $0x1,(%edx)
f0104006:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0104009:	83 c1 01             	add    $0x1,%ecx
f010400c:	39 f1                	cmp    %esi,%ecx
f010400e:	75 ed                	jne    f0103ffd <strncpy+0x17>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0104010:	5b                   	pop    %ebx
f0104011:	5e                   	pop    %esi
f0104012:	5d                   	pop    %ebp
f0104013:	c3                   	ret    

f0104014 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0104014:	55                   	push   %ebp
f0104015:	89 e5                	mov    %esp,%ebp
f0104017:	57                   	push   %edi
f0104018:	56                   	push   %esi
f0104019:	53                   	push   %ebx
f010401a:	8b 7d 08             	mov    0x8(%ebp),%edi
f010401d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104020:	8b 75 10             	mov    0x10(%ebp),%esi
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0104023:	89 f8                	mov    %edi,%eax
f0104025:	85 f6                	test   %esi,%esi
f0104027:	74 2b                	je     f0104054 <strlcpy+0x40>
		while (--size > 0 && *src != '\0')
f0104029:	83 fe 01             	cmp    $0x1,%esi
f010402c:	74 23                	je     f0104051 <strlcpy+0x3d>
f010402e:	0f b6 0b             	movzbl (%ebx),%ecx
f0104031:	84 c9                	test   %cl,%cl
f0104033:	74 1c                	je     f0104051 <strlcpy+0x3d>
	}
	return ret;
}

size_t
strlcpy(char *dst, const char *src, size_t size)
f0104035:	83 ee 02             	sub    $0x2,%esi
f0104038:	ba 00 00 00 00       	mov    $0x0,%edx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f010403d:	88 08                	mov    %cl,(%eax)
f010403f:	83 c0 01             	add    $0x1,%eax
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0104042:	39 f2                	cmp    %esi,%edx
f0104044:	74 0b                	je     f0104051 <strlcpy+0x3d>
f0104046:	83 c2 01             	add    $0x1,%edx
f0104049:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f010404d:	84 c9                	test   %cl,%cl
f010404f:	75 ec                	jne    f010403d <strlcpy+0x29>
			*dst++ = *src++;
		*dst = '\0';
f0104051:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0104054:	29 f8                	sub    %edi,%eax
}
f0104056:	5b                   	pop    %ebx
f0104057:	5e                   	pop    %esi
f0104058:	5f                   	pop    %edi
f0104059:	5d                   	pop    %ebp
f010405a:	c3                   	ret    

f010405b <strcmp>:

int
strcmp(const char *p, const char *q)
{
f010405b:	55                   	push   %ebp
f010405c:	89 e5                	mov    %esp,%ebp
f010405e:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104061:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0104064:	0f b6 01             	movzbl (%ecx),%eax
f0104067:	84 c0                	test   %al,%al
f0104069:	74 16                	je     f0104081 <strcmp+0x26>
f010406b:	3a 02                	cmp    (%edx),%al
f010406d:	75 12                	jne    f0104081 <strcmp+0x26>
		p++, q++;
f010406f:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0104072:	0f b6 41 01          	movzbl 0x1(%ecx),%eax
f0104076:	84 c0                	test   %al,%al
f0104078:	74 07                	je     f0104081 <strcmp+0x26>
f010407a:	83 c1 01             	add    $0x1,%ecx
f010407d:	3a 02                	cmp    (%edx),%al
f010407f:	74 ee                	je     f010406f <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0104081:	0f b6 c0             	movzbl %al,%eax
f0104084:	0f b6 12             	movzbl (%edx),%edx
f0104087:	29 d0                	sub    %edx,%eax
}
f0104089:	5d                   	pop    %ebp
f010408a:	c3                   	ret    

f010408b <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f010408b:	55                   	push   %ebp
f010408c:	89 e5                	mov    %esp,%ebp
f010408e:	53                   	push   %ebx
f010408f:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0104092:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104095:	8b 55 10             	mov    0x10(%ebp),%edx
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0104098:	b8 00 00 00 00       	mov    $0x0,%eax
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f010409d:	85 d2                	test   %edx,%edx
f010409f:	74 28                	je     f01040c9 <strncmp+0x3e>
f01040a1:	0f b6 01             	movzbl (%ecx),%eax
f01040a4:	84 c0                	test   %al,%al
f01040a6:	74 24                	je     f01040cc <strncmp+0x41>
f01040a8:	3a 03                	cmp    (%ebx),%al
f01040aa:	75 20                	jne    f01040cc <strncmp+0x41>
f01040ac:	83 ea 01             	sub    $0x1,%edx
f01040af:	74 13                	je     f01040c4 <strncmp+0x39>
		n--, p++, q++;
f01040b1:	83 c1 01             	add    $0x1,%ecx
f01040b4:	83 c3 01             	add    $0x1,%ebx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01040b7:	0f b6 01             	movzbl (%ecx),%eax
f01040ba:	84 c0                	test   %al,%al
f01040bc:	74 0e                	je     f01040cc <strncmp+0x41>
f01040be:	3a 03                	cmp    (%ebx),%al
f01040c0:	74 ea                	je     f01040ac <strncmp+0x21>
f01040c2:	eb 08                	jmp    f01040cc <strncmp+0x41>
		n--, p++, q++;
	if (n == 0)
		return 0;
f01040c4:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01040c9:	5b                   	pop    %ebx
f01040ca:	5d                   	pop    %ebp
f01040cb:	c3                   	ret    
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01040cc:	0f b6 01             	movzbl (%ecx),%eax
f01040cf:	0f b6 13             	movzbl (%ebx),%edx
f01040d2:	29 d0                	sub    %edx,%eax
f01040d4:	eb f3                	jmp    f01040c9 <strncmp+0x3e>

f01040d6 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01040d6:	55                   	push   %ebp
f01040d7:	89 e5                	mov    %esp,%ebp
f01040d9:	8b 45 08             	mov    0x8(%ebp),%eax
f01040dc:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01040e0:	0f b6 10             	movzbl (%eax),%edx
f01040e3:	84 d2                	test   %dl,%dl
f01040e5:	74 1c                	je     f0104103 <strchr+0x2d>
		if (*s == c)
f01040e7:	38 ca                	cmp    %cl,%dl
f01040e9:	75 09                	jne    f01040f4 <strchr+0x1e>
f01040eb:	eb 1b                	jmp    f0104108 <strchr+0x32>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01040ed:	83 c0 01             	add    $0x1,%eax
		if (*s == c)
f01040f0:	38 ca                	cmp    %cl,%dl
f01040f2:	74 14                	je     f0104108 <strchr+0x32>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01040f4:	0f b6 50 01          	movzbl 0x1(%eax),%edx
f01040f8:	84 d2                	test   %dl,%dl
f01040fa:	75 f1                	jne    f01040ed <strchr+0x17>
		if (*s == c)
			return (char *) s;
	return 0;
f01040fc:	b8 00 00 00 00       	mov    $0x0,%eax
f0104101:	eb 05                	jmp    f0104108 <strchr+0x32>
f0104103:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104108:	5d                   	pop    %ebp
f0104109:	c3                   	ret    

f010410a <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010410a:	55                   	push   %ebp
f010410b:	89 e5                	mov    %esp,%ebp
f010410d:	8b 45 08             	mov    0x8(%ebp),%eax
f0104110:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0104114:	0f b6 10             	movzbl (%eax),%edx
f0104117:	84 d2                	test   %dl,%dl
f0104119:	74 14                	je     f010412f <strfind+0x25>
		if (*s == c)
f010411b:	38 ca                	cmp    %cl,%dl
f010411d:	75 06                	jne    f0104125 <strfind+0x1b>
f010411f:	eb 0e                	jmp    f010412f <strfind+0x25>
f0104121:	38 ca                	cmp    %cl,%dl
f0104123:	74 0a                	je     f010412f <strfind+0x25>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f0104125:	83 c0 01             	add    $0x1,%eax
f0104128:	0f b6 10             	movzbl (%eax),%edx
f010412b:	84 d2                	test   %dl,%dl
f010412d:	75 f2                	jne    f0104121 <strfind+0x17>
		if (*s == c)
			break;
	return (char *) s;
}
f010412f:	5d                   	pop    %ebp
f0104130:	c3                   	ret    

f0104131 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0104131:	55                   	push   %ebp
f0104132:	89 e5                	mov    %esp,%ebp
f0104134:	83 ec 0c             	sub    $0xc,%esp
f0104137:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f010413a:	89 75 f8             	mov    %esi,-0x8(%ebp)
f010413d:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0104140:	8b 7d 08             	mov    0x8(%ebp),%edi
f0104143:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104146:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0104149:	85 c9                	test   %ecx,%ecx
f010414b:	74 30                	je     f010417d <memset+0x4c>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f010414d:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0104153:	75 25                	jne    f010417a <memset+0x49>
f0104155:	f6 c1 03             	test   $0x3,%cl
f0104158:	75 20                	jne    f010417a <memset+0x49>
		c &= 0xFF;
f010415a:	0f b6 d0             	movzbl %al,%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f010415d:	89 d3                	mov    %edx,%ebx
f010415f:	c1 e3 08             	shl    $0x8,%ebx
f0104162:	89 d6                	mov    %edx,%esi
f0104164:	c1 e6 18             	shl    $0x18,%esi
f0104167:	89 d0                	mov    %edx,%eax
f0104169:	c1 e0 10             	shl    $0x10,%eax
f010416c:	09 f0                	or     %esi,%eax
f010416e:	09 d0                	or     %edx,%eax
f0104170:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0104172:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f0104175:	fc                   	cld    
f0104176:	f3 ab                	rep stos %eax,%es:(%edi)
f0104178:	eb 03                	jmp    f010417d <memset+0x4c>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f010417a:	fc                   	cld    
f010417b:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f010417d:	89 f8                	mov    %edi,%eax
f010417f:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0104182:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0104185:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0104188:	89 ec                	mov    %ebp,%esp
f010418a:	5d                   	pop    %ebp
f010418b:	c3                   	ret    

f010418c <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f010418c:	55                   	push   %ebp
f010418d:	89 e5                	mov    %esp,%ebp
f010418f:	83 ec 08             	sub    $0x8,%esp
f0104192:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0104195:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0104198:	8b 45 08             	mov    0x8(%ebp),%eax
f010419b:	8b 75 0c             	mov    0xc(%ebp),%esi
f010419e:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01041a1:	39 c6                	cmp    %eax,%esi
f01041a3:	73 36                	jae    f01041db <memmove+0x4f>
f01041a5:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01041a8:	39 d0                	cmp    %edx,%eax
f01041aa:	73 2f                	jae    f01041db <memmove+0x4f>
		s += n;
		d += n;
f01041ac:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01041af:	f6 c2 03             	test   $0x3,%dl
f01041b2:	75 1b                	jne    f01041cf <memmove+0x43>
f01041b4:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01041ba:	75 13                	jne    f01041cf <memmove+0x43>
f01041bc:	f6 c1 03             	test   $0x3,%cl
f01041bf:	75 0e                	jne    f01041cf <memmove+0x43>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f01041c1:	83 ef 04             	sub    $0x4,%edi
f01041c4:	8d 72 fc             	lea    -0x4(%edx),%esi
f01041c7:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f01041ca:	fd                   	std    
f01041cb:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01041cd:	eb 09                	jmp    f01041d8 <memmove+0x4c>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f01041cf:	83 ef 01             	sub    $0x1,%edi
f01041d2:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f01041d5:	fd                   	std    
f01041d6:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f01041d8:	fc                   	cld    
f01041d9:	eb 20                	jmp    f01041fb <memmove+0x6f>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01041db:	f7 c6 03 00 00 00    	test   $0x3,%esi
f01041e1:	75 13                	jne    f01041f6 <memmove+0x6a>
f01041e3:	a8 03                	test   $0x3,%al
f01041e5:	75 0f                	jne    f01041f6 <memmove+0x6a>
f01041e7:	f6 c1 03             	test   $0x3,%cl
f01041ea:	75 0a                	jne    f01041f6 <memmove+0x6a>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f01041ec:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f01041ef:	89 c7                	mov    %eax,%edi
f01041f1:	fc                   	cld    
f01041f2:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f01041f4:	eb 05                	jmp    f01041fb <memmove+0x6f>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f01041f6:	89 c7                	mov    %eax,%edi
f01041f8:	fc                   	cld    
f01041f9:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f01041fb:	8b 75 f8             	mov    -0x8(%ebp),%esi
f01041fe:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0104201:	89 ec                	mov    %ebp,%esp
f0104203:	5d                   	pop    %ebp
f0104204:	c3                   	ret    

f0104205 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0104205:	55                   	push   %ebp
f0104206:	89 e5                	mov    %esp,%ebp
f0104208:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f010420b:	8b 45 10             	mov    0x10(%ebp),%eax
f010420e:	89 44 24 08          	mov    %eax,0x8(%esp)
f0104212:	8b 45 0c             	mov    0xc(%ebp),%eax
f0104215:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104219:	8b 45 08             	mov    0x8(%ebp),%eax
f010421c:	89 04 24             	mov    %eax,(%esp)
f010421f:	e8 68 ff ff ff       	call   f010418c <memmove>
}
f0104224:	c9                   	leave  
f0104225:	c3                   	ret    

f0104226 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0104226:	55                   	push   %ebp
f0104227:	89 e5                	mov    %esp,%ebp
f0104229:	57                   	push   %edi
f010422a:	56                   	push   %esi
f010422b:	53                   	push   %ebx
f010422c:	8b 5d 08             	mov    0x8(%ebp),%ebx
f010422f:	8b 75 0c             	mov    0xc(%ebp),%esi
f0104232:	8b 7d 10             	mov    0x10(%ebp),%edi
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0104235:	b8 00 00 00 00       	mov    $0x0,%eax
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010423a:	85 ff                	test   %edi,%edi
f010423c:	74 37                	je     f0104275 <memcmp+0x4f>
		if (*s1 != *s2)
f010423e:	0f b6 03             	movzbl (%ebx),%eax
f0104241:	0f b6 0e             	movzbl (%esi),%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0104244:	83 ef 01             	sub    $0x1,%edi
f0104247:	ba 00 00 00 00       	mov    $0x0,%edx
		if (*s1 != *s2)
f010424c:	38 c8                	cmp    %cl,%al
f010424e:	74 1c                	je     f010426c <memcmp+0x46>
f0104250:	eb 10                	jmp    f0104262 <memcmp+0x3c>
f0104252:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
f0104257:	83 c2 01             	add    $0x1,%edx
f010425a:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
f010425e:	38 c8                	cmp    %cl,%al
f0104260:	74 0a                	je     f010426c <memcmp+0x46>
			return (int) *s1 - (int) *s2;
f0104262:	0f b6 c0             	movzbl %al,%eax
f0104265:	0f b6 c9             	movzbl %cl,%ecx
f0104268:	29 c8                	sub    %ecx,%eax
f010426a:	eb 09                	jmp    f0104275 <memcmp+0x4f>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010426c:	39 fa                	cmp    %edi,%edx
f010426e:	75 e2                	jne    f0104252 <memcmp+0x2c>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0104270:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0104275:	5b                   	pop    %ebx
f0104276:	5e                   	pop    %esi
f0104277:	5f                   	pop    %edi
f0104278:	5d                   	pop    %ebp
f0104279:	c3                   	ret    

f010427a <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f010427a:	55                   	push   %ebp
f010427b:	89 e5                	mov    %esp,%ebp
f010427d:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0104280:	89 c2                	mov    %eax,%edx
f0104282:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0104285:	39 d0                	cmp    %edx,%eax
f0104287:	73 19                	jae    f01042a2 <memfind+0x28>
		if (*(const unsigned char *) s == (unsigned char) c)
f0104289:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
f010428d:	38 08                	cmp    %cl,(%eax)
f010428f:	75 06                	jne    f0104297 <memfind+0x1d>
f0104291:	eb 0f                	jmp    f01042a2 <memfind+0x28>
f0104293:	38 08                	cmp    %cl,(%eax)
f0104295:	74 0b                	je     f01042a2 <memfind+0x28>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0104297:	83 c0 01             	add    $0x1,%eax
f010429a:	39 d0                	cmp    %edx,%eax
f010429c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01042a0:	75 f1                	jne    f0104293 <memfind+0x19>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01042a2:	5d                   	pop    %ebp
f01042a3:	c3                   	ret    

f01042a4 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01042a4:	55                   	push   %ebp
f01042a5:	89 e5                	mov    %esp,%ebp
f01042a7:	57                   	push   %edi
f01042a8:	56                   	push   %esi
f01042a9:	53                   	push   %ebx
f01042aa:	8b 55 08             	mov    0x8(%ebp),%edx
f01042ad:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01042b0:	0f b6 02             	movzbl (%edx),%eax
f01042b3:	3c 20                	cmp    $0x20,%al
f01042b5:	74 04                	je     f01042bb <strtol+0x17>
f01042b7:	3c 09                	cmp    $0x9,%al
f01042b9:	75 0e                	jne    f01042c9 <strtol+0x25>
		s++;
f01042bb:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01042be:	0f b6 02             	movzbl (%edx),%eax
f01042c1:	3c 20                	cmp    $0x20,%al
f01042c3:	74 f6                	je     f01042bb <strtol+0x17>
f01042c5:	3c 09                	cmp    $0x9,%al
f01042c7:	74 f2                	je     f01042bb <strtol+0x17>
		s++;

	// plus/minus sign
	if (*s == '+')
f01042c9:	3c 2b                	cmp    $0x2b,%al
f01042cb:	75 0a                	jne    f01042d7 <strtol+0x33>
		s++;
f01042cd:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f01042d0:	bf 00 00 00 00       	mov    $0x0,%edi
f01042d5:	eb 10                	jmp    f01042e7 <strtol+0x43>
f01042d7:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f01042dc:	3c 2d                	cmp    $0x2d,%al
f01042de:	75 07                	jne    f01042e7 <strtol+0x43>
		s++, neg = 1;
f01042e0:	83 c2 01             	add    $0x1,%edx
f01042e3:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f01042e7:	85 db                	test   %ebx,%ebx
f01042e9:	0f 94 c0             	sete   %al
f01042ec:	74 05                	je     f01042f3 <strtol+0x4f>
f01042ee:	83 fb 10             	cmp    $0x10,%ebx
f01042f1:	75 15                	jne    f0104308 <strtol+0x64>
f01042f3:	80 3a 30             	cmpb   $0x30,(%edx)
f01042f6:	75 10                	jne    f0104308 <strtol+0x64>
f01042f8:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f01042fc:	75 0a                	jne    f0104308 <strtol+0x64>
		s += 2, base = 16;
f01042fe:	83 c2 02             	add    $0x2,%edx
f0104301:	bb 10 00 00 00       	mov    $0x10,%ebx
f0104306:	eb 13                	jmp    f010431b <strtol+0x77>
	else if (base == 0 && s[0] == '0')
f0104308:	84 c0                	test   %al,%al
f010430a:	74 0f                	je     f010431b <strtol+0x77>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f010430c:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0104311:	80 3a 30             	cmpb   $0x30,(%edx)
f0104314:	75 05                	jne    f010431b <strtol+0x77>
		s++, base = 8;
f0104316:	83 c2 01             	add    $0x1,%edx
f0104319:	b3 08                	mov    $0x8,%bl
	else if (base == 0)
		base = 10;
f010431b:	b8 00 00 00 00       	mov    $0x0,%eax
f0104320:	89 de                	mov    %ebx,%esi

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0104322:	0f b6 0a             	movzbl (%edx),%ecx
f0104325:	8d 59 d0             	lea    -0x30(%ecx),%ebx
f0104328:	80 fb 09             	cmp    $0x9,%bl
f010432b:	77 08                	ja     f0104335 <strtol+0x91>
			dig = *s - '0';
f010432d:	0f be c9             	movsbl %cl,%ecx
f0104330:	83 e9 30             	sub    $0x30,%ecx
f0104333:	eb 1e                	jmp    f0104353 <strtol+0xaf>
		else if (*s >= 'a' && *s <= 'z')
f0104335:	8d 59 9f             	lea    -0x61(%ecx),%ebx
f0104338:	80 fb 19             	cmp    $0x19,%bl
f010433b:	77 08                	ja     f0104345 <strtol+0xa1>
			dig = *s - 'a' + 10;
f010433d:	0f be c9             	movsbl %cl,%ecx
f0104340:	83 e9 57             	sub    $0x57,%ecx
f0104343:	eb 0e                	jmp    f0104353 <strtol+0xaf>
		else if (*s >= 'A' && *s <= 'Z')
f0104345:	8d 59 bf             	lea    -0x41(%ecx),%ebx
f0104348:	80 fb 19             	cmp    $0x19,%bl
f010434b:	77 14                	ja     f0104361 <strtol+0xbd>
			dig = *s - 'A' + 10;
f010434d:	0f be c9             	movsbl %cl,%ecx
f0104350:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0104353:	39 f1                	cmp    %esi,%ecx
f0104355:	7d 0e                	jge    f0104365 <strtol+0xc1>
			break;
		s++, val = (val * base) + dig;
f0104357:	83 c2 01             	add    $0x1,%edx
f010435a:	0f af c6             	imul   %esi,%eax
f010435d:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
f010435f:	eb c1                	jmp    f0104322 <strtol+0x7e>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
f0104361:	89 c1                	mov    %eax,%ecx
f0104363:	eb 02                	jmp    f0104367 <strtol+0xc3>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0104365:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
f0104367:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f010436b:	74 05                	je     f0104372 <strtol+0xce>
		*endptr = (char *) s;
f010436d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0104370:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
f0104372:	89 ca                	mov    %ecx,%edx
f0104374:	f7 da                	neg    %edx
f0104376:	85 ff                	test   %edi,%edi
f0104378:	0f 45 c2             	cmovne %edx,%eax
}
f010437b:	5b                   	pop    %ebx
f010437c:	5e                   	pop    %esi
f010437d:	5f                   	pop    %edi
f010437e:	5d                   	pop    %ebp
f010437f:	c3                   	ret    

f0104380 <__udivdi3>:
f0104380:	83 ec 1c             	sub    $0x1c,%esp
f0104383:	89 7c 24 14          	mov    %edi,0x14(%esp)
f0104387:	8b 7c 24 2c          	mov    0x2c(%esp),%edi
f010438b:	8b 44 24 20          	mov    0x20(%esp),%eax
f010438f:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0104393:	89 74 24 10          	mov    %esi,0x10(%esp)
f0104397:	8b 74 24 24          	mov    0x24(%esp),%esi
f010439b:	85 ff                	test   %edi,%edi
f010439d:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f01043a1:	89 44 24 08          	mov    %eax,0x8(%esp)
f01043a5:	89 cd                	mov    %ecx,%ebp
f01043a7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01043ab:	75 33                	jne    f01043e0 <__udivdi3+0x60>
f01043ad:	39 f1                	cmp    %esi,%ecx
f01043af:	77 57                	ja     f0104408 <__udivdi3+0x88>
f01043b1:	85 c9                	test   %ecx,%ecx
f01043b3:	75 0b                	jne    f01043c0 <__udivdi3+0x40>
f01043b5:	b8 01 00 00 00       	mov    $0x1,%eax
f01043ba:	31 d2                	xor    %edx,%edx
f01043bc:	f7 f1                	div    %ecx
f01043be:	89 c1                	mov    %eax,%ecx
f01043c0:	89 f0                	mov    %esi,%eax
f01043c2:	31 d2                	xor    %edx,%edx
f01043c4:	f7 f1                	div    %ecx
f01043c6:	89 c6                	mov    %eax,%esi
f01043c8:	8b 44 24 04          	mov    0x4(%esp),%eax
f01043cc:	f7 f1                	div    %ecx
f01043ce:	89 f2                	mov    %esi,%edx
f01043d0:	8b 74 24 10          	mov    0x10(%esp),%esi
f01043d4:	8b 7c 24 14          	mov    0x14(%esp),%edi
f01043d8:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f01043dc:	83 c4 1c             	add    $0x1c,%esp
f01043df:	c3                   	ret    
f01043e0:	31 d2                	xor    %edx,%edx
f01043e2:	31 c0                	xor    %eax,%eax
f01043e4:	39 f7                	cmp    %esi,%edi
f01043e6:	77 e8                	ja     f01043d0 <__udivdi3+0x50>
f01043e8:	0f bd cf             	bsr    %edi,%ecx
f01043eb:	83 f1 1f             	xor    $0x1f,%ecx
f01043ee:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f01043f2:	75 2c                	jne    f0104420 <__udivdi3+0xa0>
f01043f4:	3b 6c 24 08          	cmp    0x8(%esp),%ebp
f01043f8:	76 04                	jbe    f01043fe <__udivdi3+0x7e>
f01043fa:	39 f7                	cmp    %esi,%edi
f01043fc:	73 d2                	jae    f01043d0 <__udivdi3+0x50>
f01043fe:	31 d2                	xor    %edx,%edx
f0104400:	b8 01 00 00 00       	mov    $0x1,%eax
f0104405:	eb c9                	jmp    f01043d0 <__udivdi3+0x50>
f0104407:	90                   	nop
f0104408:	89 f2                	mov    %esi,%edx
f010440a:	f7 f1                	div    %ecx
f010440c:	31 d2                	xor    %edx,%edx
f010440e:	8b 74 24 10          	mov    0x10(%esp),%esi
f0104412:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0104416:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f010441a:	83 c4 1c             	add    $0x1c,%esp
f010441d:	c3                   	ret    
f010441e:	66 90                	xchg   %ax,%ax
f0104420:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0104425:	b8 20 00 00 00       	mov    $0x20,%eax
f010442a:	89 ea                	mov    %ebp,%edx
f010442c:	2b 44 24 04          	sub    0x4(%esp),%eax
f0104430:	d3 e7                	shl    %cl,%edi
f0104432:	89 c1                	mov    %eax,%ecx
f0104434:	d3 ea                	shr    %cl,%edx
f0104436:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f010443b:	09 fa                	or     %edi,%edx
f010443d:	89 f7                	mov    %esi,%edi
f010443f:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0104443:	89 f2                	mov    %esi,%edx
f0104445:	8b 74 24 08          	mov    0x8(%esp),%esi
f0104449:	d3 e5                	shl    %cl,%ebp
f010444b:	89 c1                	mov    %eax,%ecx
f010444d:	d3 ef                	shr    %cl,%edi
f010444f:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0104454:	d3 e2                	shl    %cl,%edx
f0104456:	89 c1                	mov    %eax,%ecx
f0104458:	d3 ee                	shr    %cl,%esi
f010445a:	09 d6                	or     %edx,%esi
f010445c:	89 fa                	mov    %edi,%edx
f010445e:	89 f0                	mov    %esi,%eax
f0104460:	f7 74 24 0c          	divl   0xc(%esp)
f0104464:	89 d7                	mov    %edx,%edi
f0104466:	89 c6                	mov    %eax,%esi
f0104468:	f7 e5                	mul    %ebp
f010446a:	39 d7                	cmp    %edx,%edi
f010446c:	72 22                	jb     f0104490 <__udivdi3+0x110>
f010446e:	8b 6c 24 08          	mov    0x8(%esp),%ebp
f0104472:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0104477:	d3 e5                	shl    %cl,%ebp
f0104479:	39 c5                	cmp    %eax,%ebp
f010447b:	73 04                	jae    f0104481 <__udivdi3+0x101>
f010447d:	39 d7                	cmp    %edx,%edi
f010447f:	74 0f                	je     f0104490 <__udivdi3+0x110>
f0104481:	89 f0                	mov    %esi,%eax
f0104483:	31 d2                	xor    %edx,%edx
f0104485:	e9 46 ff ff ff       	jmp    f01043d0 <__udivdi3+0x50>
f010448a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0104490:	8d 46 ff             	lea    -0x1(%esi),%eax
f0104493:	31 d2                	xor    %edx,%edx
f0104495:	8b 74 24 10          	mov    0x10(%esp),%esi
f0104499:	8b 7c 24 14          	mov    0x14(%esp),%edi
f010449d:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f01044a1:	83 c4 1c             	add    $0x1c,%esp
f01044a4:	c3                   	ret    
	...

f01044b0 <__umoddi3>:
f01044b0:	83 ec 1c             	sub    $0x1c,%esp
f01044b3:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f01044b7:	8b 6c 24 2c          	mov    0x2c(%esp),%ebp
f01044bb:	8b 44 24 20          	mov    0x20(%esp),%eax
f01044bf:	89 74 24 10          	mov    %esi,0x10(%esp)
f01044c3:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f01044c7:	8b 74 24 24          	mov    0x24(%esp),%esi
f01044cb:	85 ed                	test   %ebp,%ebp
f01044cd:	89 7c 24 14          	mov    %edi,0x14(%esp)
f01044d1:	89 44 24 08          	mov    %eax,0x8(%esp)
f01044d5:	89 cf                	mov    %ecx,%edi
f01044d7:	89 04 24             	mov    %eax,(%esp)
f01044da:	89 f2                	mov    %esi,%edx
f01044dc:	75 1a                	jne    f01044f8 <__umoddi3+0x48>
f01044de:	39 f1                	cmp    %esi,%ecx
f01044e0:	76 4e                	jbe    f0104530 <__umoddi3+0x80>
f01044e2:	f7 f1                	div    %ecx
f01044e4:	89 d0                	mov    %edx,%eax
f01044e6:	31 d2                	xor    %edx,%edx
f01044e8:	8b 74 24 10          	mov    0x10(%esp),%esi
f01044ec:	8b 7c 24 14          	mov    0x14(%esp),%edi
f01044f0:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f01044f4:	83 c4 1c             	add    $0x1c,%esp
f01044f7:	c3                   	ret    
f01044f8:	39 f5                	cmp    %esi,%ebp
f01044fa:	77 54                	ja     f0104550 <__umoddi3+0xa0>
f01044fc:	0f bd c5             	bsr    %ebp,%eax
f01044ff:	83 f0 1f             	xor    $0x1f,%eax
f0104502:	89 44 24 04          	mov    %eax,0x4(%esp)
f0104506:	75 60                	jne    f0104568 <__umoddi3+0xb8>
f0104508:	3b 0c 24             	cmp    (%esp),%ecx
f010450b:	0f 87 07 01 00 00    	ja     f0104618 <__umoddi3+0x168>
f0104511:	89 f2                	mov    %esi,%edx
f0104513:	8b 34 24             	mov    (%esp),%esi
f0104516:	29 ce                	sub    %ecx,%esi
f0104518:	19 ea                	sbb    %ebp,%edx
f010451a:	89 34 24             	mov    %esi,(%esp)
f010451d:	8b 04 24             	mov    (%esp),%eax
f0104520:	8b 74 24 10          	mov    0x10(%esp),%esi
f0104524:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0104528:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f010452c:	83 c4 1c             	add    $0x1c,%esp
f010452f:	c3                   	ret    
f0104530:	85 c9                	test   %ecx,%ecx
f0104532:	75 0b                	jne    f010453f <__umoddi3+0x8f>
f0104534:	b8 01 00 00 00       	mov    $0x1,%eax
f0104539:	31 d2                	xor    %edx,%edx
f010453b:	f7 f1                	div    %ecx
f010453d:	89 c1                	mov    %eax,%ecx
f010453f:	89 f0                	mov    %esi,%eax
f0104541:	31 d2                	xor    %edx,%edx
f0104543:	f7 f1                	div    %ecx
f0104545:	8b 04 24             	mov    (%esp),%eax
f0104548:	f7 f1                	div    %ecx
f010454a:	eb 98                	jmp    f01044e4 <__umoddi3+0x34>
f010454c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104550:	89 f2                	mov    %esi,%edx
f0104552:	8b 74 24 10          	mov    0x10(%esp),%esi
f0104556:	8b 7c 24 14          	mov    0x14(%esp),%edi
f010455a:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f010455e:	83 c4 1c             	add    $0x1c,%esp
f0104561:	c3                   	ret    
f0104562:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0104568:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f010456d:	89 e8                	mov    %ebp,%eax
f010456f:	bd 20 00 00 00       	mov    $0x20,%ebp
f0104574:	2b 6c 24 04          	sub    0x4(%esp),%ebp
f0104578:	89 fa                	mov    %edi,%edx
f010457a:	d3 e0                	shl    %cl,%eax
f010457c:	89 e9                	mov    %ebp,%ecx
f010457e:	d3 ea                	shr    %cl,%edx
f0104580:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0104585:	09 c2                	or     %eax,%edx
f0104587:	8b 44 24 08          	mov    0x8(%esp),%eax
f010458b:	89 14 24             	mov    %edx,(%esp)
f010458e:	89 f2                	mov    %esi,%edx
f0104590:	d3 e7                	shl    %cl,%edi
f0104592:	89 e9                	mov    %ebp,%ecx
f0104594:	d3 ea                	shr    %cl,%edx
f0104596:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f010459b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f010459f:	d3 e6                	shl    %cl,%esi
f01045a1:	89 e9                	mov    %ebp,%ecx
f01045a3:	d3 e8                	shr    %cl,%eax
f01045a5:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f01045aa:	09 f0                	or     %esi,%eax
f01045ac:	8b 74 24 08          	mov    0x8(%esp),%esi
f01045b0:	f7 34 24             	divl   (%esp)
f01045b3:	d3 e6                	shl    %cl,%esi
f01045b5:	89 74 24 08          	mov    %esi,0x8(%esp)
f01045b9:	89 d6                	mov    %edx,%esi
f01045bb:	f7 e7                	mul    %edi
f01045bd:	39 d6                	cmp    %edx,%esi
f01045bf:	89 c1                	mov    %eax,%ecx
f01045c1:	89 d7                	mov    %edx,%edi
f01045c3:	72 3f                	jb     f0104604 <__umoddi3+0x154>
f01045c5:	39 44 24 08          	cmp    %eax,0x8(%esp)
f01045c9:	72 35                	jb     f0104600 <__umoddi3+0x150>
f01045cb:	8b 44 24 08          	mov    0x8(%esp),%eax
f01045cf:	29 c8                	sub    %ecx,%eax
f01045d1:	19 fe                	sbb    %edi,%esi
f01045d3:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f01045d8:	89 f2                	mov    %esi,%edx
f01045da:	d3 e8                	shr    %cl,%eax
f01045dc:	89 e9                	mov    %ebp,%ecx
f01045de:	d3 e2                	shl    %cl,%edx
f01045e0:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f01045e5:	09 d0                	or     %edx,%eax
f01045e7:	89 f2                	mov    %esi,%edx
f01045e9:	d3 ea                	shr    %cl,%edx
f01045eb:	8b 74 24 10          	mov    0x10(%esp),%esi
f01045ef:	8b 7c 24 14          	mov    0x14(%esp),%edi
f01045f3:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f01045f7:	83 c4 1c             	add    $0x1c,%esp
f01045fa:	c3                   	ret    
f01045fb:	90                   	nop
f01045fc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104600:	39 d6                	cmp    %edx,%esi
f0104602:	75 c7                	jne    f01045cb <__umoddi3+0x11b>
f0104604:	89 d7                	mov    %edx,%edi
f0104606:	89 c1                	mov    %eax,%ecx
f0104608:	2b 4c 24 0c          	sub    0xc(%esp),%ecx
f010460c:	1b 3c 24             	sbb    (%esp),%edi
f010460f:	eb ba                	jmp    f01045cb <__umoddi3+0x11b>
f0104611:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104618:	39 f5                	cmp    %esi,%ebp
f010461a:	0f 82 f1 fe ff ff    	jb     f0104511 <__umoddi3+0x61>
f0104620:	e9 f8 fe ff ff       	jmp    f010451d <__umoddi3+0x6d>
