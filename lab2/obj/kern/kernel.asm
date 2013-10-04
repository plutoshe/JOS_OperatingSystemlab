
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
f0100015:	b8 00 60 11 00       	mov    $0x116000,%eax
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
f0100034:	bc 00 60 11 f0       	mov    $0xf0116000,%esp

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
f0100046:	b8 90 89 11 f0       	mov    $0xf0118990,%eax
f010004b:	2d 20 83 11 f0       	sub    $0xf0118320,%eax
f0100050:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100054:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010005b:	00 
f010005c:	c7 04 24 20 83 11 f0 	movl   $0xf0118320,(%esp)
f0100063:	e8 d9 3a 00 00       	call   f0103b41 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100068:	e8 97 04 00 00       	call   f0100504 <cons_init>
	cprintf("6828 decimal is %o octal!\n", 6828);
f010006d:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f0100074:	00 
f0100075:	c7 04 24 40 40 10 f0 	movl   $0xf0104040,(%esp)
f010007c:	e8 fd 2e 00 00       	call   f0102f7e <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100081:	e8 a4 13 00 00       	call   f010142a <mem_init>
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
f010009f:	83 3d 80 89 11 f0 00 	cmpl   $0x0,0xf0118980
f01000a6:	75 3d                	jne    f01000e5 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f01000a8:	89 35 80 89 11 f0    	mov    %esi,0xf0118980

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
f01000c1:	c7 04 24 5b 40 10 f0 	movl   $0xf010405b,(%esp)
f01000c8:	e8 b1 2e 00 00       	call   f0102f7e <cprintf>
	vcprintf(fmt, ap);
f01000cd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01000d1:	89 34 24             	mov    %esi,(%esp)
f01000d4:	e8 72 2e 00 00       	call   f0102f4b <vcprintf>
	cprintf("\n");
f01000d9:	c7 04 24 8c 48 10 f0 	movl   $0xf010488c,(%esp)
f01000e0:	e8 99 2e 00 00       	call   f0102f7e <cprintf>
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
f010010b:	c7 04 24 73 40 10 f0 	movl   $0xf0104073,(%esp)
f0100112:	e8 67 2e 00 00       	call   f0102f7e <cprintf>
	vcprintf(fmt, ap);
f0100117:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010011b:	8b 45 10             	mov    0x10(%ebp),%eax
f010011e:	89 04 24             	mov    %eax,(%esp)
f0100121:	e8 25 2e 00 00       	call   f0102f4b <vcprintf>
	cprintf("\n");
f0100126:	c7 04 24 8c 48 10 f0 	movl   $0xf010488c,(%esp)
f010012d:	e8 4c 2e 00 00       	call   f0102f7e <cprintf>
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
f0100179:	8b 15 44 85 11 f0    	mov    0xf0118544,%edx
f010017f:	88 82 40 83 11 f0    	mov    %al,-0xfee7cc0(%edx)
f0100185:	8d 42 01             	lea    0x1(%edx),%eax
		if (cons.wpos == CONSBUFSIZE)
f0100188:	3d 00 02 00 00       	cmp    $0x200,%eax
			cons.wpos = 0;
f010018d:	ba 00 00 00 00       	mov    $0x0,%edx
f0100192:	0f 44 c2             	cmove  %edx,%eax
f0100195:	a3 44 85 11 f0       	mov    %eax,0xf0118544
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
f010021c:	0f b7 15 00 80 11 f0 	movzwl 0xf0118000,%edx
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
f0100252:	0f b7 05 54 85 11 f0 	movzwl 0xf0118554,%eax
f0100259:	66 85 c0             	test   %ax,%ax
f010025c:	0f 84 e1 00 00 00    	je     f0100343 <cons_putc+0x19c>
			crt_pos--;
f0100262:	83 e8 01             	sub    $0x1,%eax
f0100265:	66 a3 54 85 11 f0    	mov    %ax,0xf0118554
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f010026b:	0f b7 c0             	movzwl %ax,%eax
f010026e:	b2 00                	mov    $0x0,%dl
f0100270:	83 ca 20             	or     $0x20,%edx
f0100273:	8b 0d 50 85 11 f0    	mov    0xf0118550,%ecx
f0100279:	66 89 14 41          	mov    %dx,(%ecx,%eax,2)
f010027d:	eb 77                	jmp    f01002f6 <cons_putc+0x14f>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f010027f:	66 83 05 54 85 11 f0 	addw   $0x50,0xf0118554
f0100286:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f0100287:	0f b7 05 54 85 11 f0 	movzwl 0xf0118554,%eax
f010028e:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100294:	c1 e8 16             	shr    $0x16,%eax
f0100297:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010029a:	c1 e0 04             	shl    $0x4,%eax
f010029d:	66 a3 54 85 11 f0    	mov    %ax,0xf0118554
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
f01002d9:	0f b7 05 54 85 11 f0 	movzwl 0xf0118554,%eax
f01002e0:	0f b7 d8             	movzwl %ax,%ebx
f01002e3:	8b 0d 50 85 11 f0    	mov    0xf0118550,%ecx
f01002e9:	66 89 14 59          	mov    %dx,(%ecx,%ebx,2)
f01002ed:	83 c0 01             	add    $0x1,%eax
f01002f0:	66 a3 54 85 11 f0    	mov    %ax,0xf0118554
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f01002f6:	66 81 3d 54 85 11 f0 	cmpw   $0x7cf,0xf0118554
f01002fd:	cf 07 
f01002ff:	76 42                	jbe    f0100343 <cons_putc+0x19c>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100301:	a1 50 85 11 f0       	mov    0xf0118550,%eax
f0100306:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f010030d:	00 
f010030e:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100314:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100318:	89 04 24             	mov    %eax,(%esp)
f010031b:	e8 7c 38 00 00       	call   f0103b9c <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100320:	8b 15 50 85 11 f0    	mov    0xf0118550,%edx
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
f010033b:	66 83 2d 54 85 11 f0 	subw   $0x50,0xf0118554
f0100342:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100343:	8b 0d 4c 85 11 f0    	mov    0xf011854c,%ecx
f0100349:	b8 0e 00 00 00       	mov    $0xe,%eax
f010034e:	89 ca                	mov    %ecx,%edx
f0100350:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100351:	0f b7 35 54 85 11 f0 	movzwl 0xf0118554,%esi
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
f010039c:	83 0d 48 85 11 f0 40 	orl    $0x40,0xf0118548
		return 0;
f01003a3:	bb 00 00 00 00       	mov    $0x0,%ebx
f01003a8:	e9 c4 00 00 00       	jmp    f0100471 <kbd_proc_data+0xf8>
	} else if (data & 0x80) {
f01003ad:	84 c0                	test   %al,%al
f01003af:	79 37                	jns    f01003e8 <kbd_proc_data+0x6f>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01003b1:	8b 0d 48 85 11 f0    	mov    0xf0118548,%ecx
f01003b7:	89 cb                	mov    %ecx,%ebx
f01003b9:	83 e3 40             	and    $0x40,%ebx
f01003bc:	83 e0 7f             	and    $0x7f,%eax
f01003bf:	85 db                	test   %ebx,%ebx
f01003c1:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01003c4:	0f b6 d2             	movzbl %dl,%edx
f01003c7:	0f b6 82 c0 40 10 f0 	movzbl -0xfefbf40(%edx),%eax
f01003ce:	83 c8 40             	or     $0x40,%eax
f01003d1:	0f b6 c0             	movzbl %al,%eax
f01003d4:	f7 d0                	not    %eax
f01003d6:	21 c1                	and    %eax,%ecx
f01003d8:	89 0d 48 85 11 f0    	mov    %ecx,0xf0118548
		return 0;
f01003de:	bb 00 00 00 00       	mov    $0x0,%ebx
f01003e3:	e9 89 00 00 00       	jmp    f0100471 <kbd_proc_data+0xf8>
	} else if (shift & E0ESC) {
f01003e8:	8b 0d 48 85 11 f0    	mov    0xf0118548,%ecx
f01003ee:	f6 c1 40             	test   $0x40,%cl
f01003f1:	74 0e                	je     f0100401 <kbd_proc_data+0x88>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f01003f3:	89 c2                	mov    %eax,%edx
f01003f5:	83 ca 80             	or     $0xffffff80,%edx
		shift &= ~E0ESC;
f01003f8:	83 e1 bf             	and    $0xffffffbf,%ecx
f01003fb:	89 0d 48 85 11 f0    	mov    %ecx,0xf0118548
	}

	shift |= shiftcode[data];
f0100401:	0f b6 d2             	movzbl %dl,%edx
f0100404:	0f b6 82 c0 40 10 f0 	movzbl -0xfefbf40(%edx),%eax
f010040b:	0b 05 48 85 11 f0    	or     0xf0118548,%eax
	shift ^= togglecode[data];
f0100411:	0f b6 8a c0 41 10 f0 	movzbl -0xfefbe40(%edx),%ecx
f0100418:	31 c8                	xor    %ecx,%eax
f010041a:	a3 48 85 11 f0       	mov    %eax,0xf0118548

	c = charcode[shift & (CTL | SHIFT)][data];
f010041f:	89 c1                	mov    %eax,%ecx
f0100421:	83 e1 03             	and    $0x3,%ecx
f0100424:	8b 0c 8d c0 42 10 f0 	mov    -0xfefbd40(,%ecx,4),%ecx
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
f010045a:	c7 04 24 8d 40 10 f0 	movl   $0xf010408d,(%esp)
f0100461:	e8 18 2b 00 00       	call   f0102f7e <cprintf>
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
f010048c:	66 a3 00 80 11 f0    	mov    %ax,0xf0118000
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
f010049a:	80 3d 20 83 11 f0 00 	cmpb   $0x0,0xf0118320
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
f01004d1:	8b 15 40 85 11 f0    	mov    0xf0118540,%edx
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
f01004dc:	3b 15 44 85 11 f0    	cmp    0xf0118544,%edx
f01004e2:	74 1e                	je     f0100502 <cons_getc+0x41>
		c = cons.buf[cons.rpos++];
f01004e4:	0f b6 82 40 83 11 f0 	movzbl -0xfee7cc0(%edx),%eax
f01004eb:	83 c2 01             	add    $0x1,%edx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
f01004ee:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01004f4:	b9 00 00 00 00       	mov    $0x0,%ecx
f01004f9:	0f 44 d1             	cmove  %ecx,%edx
f01004fc:	89 15 40 85 11 f0    	mov    %edx,0xf0118540
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
f010052a:	c7 05 4c 85 11 f0 b4 	movl   $0x3b4,0xf011854c
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
f0100542:	c7 05 4c 85 11 f0 d4 	movl   $0x3d4,0xf011854c
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
f0100551:	8b 0d 4c 85 11 f0    	mov    0xf011854c,%ecx
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
f0100576:	89 35 50 85 11 f0    	mov    %esi,0xf0118550

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f010057c:	0f b6 d8             	movzbl %al,%ebx
f010057f:	09 df                	or     %ebx,%edi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f0100581:	66 89 3d 54 85 11 f0 	mov    %di,0xf0118554
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
f01005d4:	a2 20 83 11 f0       	mov    %al,0xf0118320
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
f01005e5:	c7 04 24 99 40 10 f0 	movl   $0xf0104099,(%esp)
f01005ec:	e8 8d 29 00 00       	call   f0102f7e <cprintf>
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
f0100636:	c7 04 24 d0 42 10 f0 	movl   $0xf01042d0,(%esp)
f010063d:	e8 3c 29 00 00       	call   f0102f7e <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100642:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f0100649:	00 
f010064a:	c7 04 24 d4 43 10 f0 	movl   $0xf01043d4,(%esp)
f0100651:	e8 28 29 00 00       	call   f0102f7e <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100656:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f010065d:	00 
f010065e:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f0100665:	f0 
f0100666:	c7 04 24 fc 43 10 f0 	movl   $0xf01043fc,(%esp)
f010066d:	e8 0c 29 00 00       	call   f0102f7e <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100672:	c7 44 24 08 35 40 10 	movl   $0x104035,0x8(%esp)
f0100679:	00 
f010067a:	c7 44 24 04 35 40 10 	movl   $0xf0104035,0x4(%esp)
f0100681:	f0 
f0100682:	c7 04 24 20 44 10 f0 	movl   $0xf0104420,(%esp)
f0100689:	e8 f0 28 00 00       	call   f0102f7e <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010068e:	c7 44 24 08 20 83 11 	movl   $0x118320,0x8(%esp)
f0100695:	00 
f0100696:	c7 44 24 04 20 83 11 	movl   $0xf0118320,0x4(%esp)
f010069d:	f0 
f010069e:	c7 04 24 44 44 10 f0 	movl   $0xf0104444,(%esp)
f01006a5:	e8 d4 28 00 00       	call   f0102f7e <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006aa:	c7 44 24 08 90 89 11 	movl   $0x118990,0x8(%esp)
f01006b1:	00 
f01006b2:	c7 44 24 04 90 89 11 	movl   $0xf0118990,0x4(%esp)
f01006b9:	f0 
f01006ba:	c7 04 24 68 44 10 f0 	movl   $0xf0104468,(%esp)
f01006c1:	e8 b8 28 00 00       	call   f0102f7e <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f01006c6:	b8 8f 8d 11 f0       	mov    $0xf0118d8f,%eax
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
f01006e7:	c7 04 24 8c 44 10 f0 	movl   $0xf010448c,(%esp)
f01006ee:	e8 8b 28 00 00       	call   f0102f7e <cprintf>
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
f0100706:	8b 83 c4 45 10 f0    	mov    -0xfefba3c(%ebx),%eax
f010070c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100710:	8b 83 c0 45 10 f0    	mov    -0xfefba40(%ebx),%eax
f0100716:	89 44 24 04          	mov    %eax,0x4(%esp)
f010071a:	c7 04 24 e9 42 10 f0 	movl   $0xf01042e9,(%esp)
f0100721:	e8 58 28 00 00       	call   f0102f7e <cprintf>
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
f0100749:	c7 04 24 f2 42 10 f0 	movl   $0xf01042f2,(%esp)
f0100750:	e8 29 28 00 00       	call   f0102f7e <cprintf>
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
f0100788:	c7 04 24 b8 44 10 f0 	movl   $0xf01044b8,(%esp)
f010078f:	e8 ea 27 00 00       	call   f0102f7e <cprintf>
		struct Eipdebuginfo temp_debuginfo;
		debuginfo_eip((uintptr_t) eip, &temp_debuginfo);		
f0100794:	8d 45 d0             	lea    -0x30(%ebp),%eax
f0100797:	89 44 24 04          	mov    %eax,0x4(%esp)
f010079b:	89 3c 24             	mov    %edi,(%esp)
f010079e:	e8 d5 28 00 00       	call   f0103078 <debuginfo_eip>
		cprintf("       %s:%d: ", temp_debuginfo.eip_file, temp_debuginfo.eip_line);
f01007a3:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01007a6:	89 44 24 08          	mov    %eax,0x8(%esp)
f01007aa:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01007ad:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007b1:	c7 04 24 03 43 10 f0 	movl   $0xf0104303,(%esp)
f01007b8:	e8 c1 27 00 00       	call   f0102f7e <cprintf>
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
f01007d3:	c7 04 24 12 43 10 f0 	movl   $0xf0104312,(%esp)
f01007da:	e8 9f 27 00 00       	call   f0102f7e <cprintf>
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
f01007ee:	c7 04 24 15 43 10 f0 	movl   $0xf0104315,(%esp)
f01007f5:	e8 84 27 00 00       	call   f0102f7e <cprintf>
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
f0100826:	c7 44 24 04 1a 43 10 	movl   $0xf010431a,0x4(%esp)
f010082d:	f0 
f010082e:	8b 46 08             	mov    0x8(%esi),%eax
f0100831:	89 04 24             	mov    %eax,(%esp)
f0100834:	e8 32 32 00 00       	call   f0103a6b <strcmp>
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
f0100846:	c7 44 24 04 1e 43 10 	movl   $0xf010431e,0x4(%esp)
f010084d:	f0 
f010084e:	8b 46 08             	mov    0x8(%esi),%eax
f0100851:	89 04 24             	mov    %eax,(%esp)
f0100854:	e8 12 32 00 00       	call   f0103a6b <strcmp>
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
f0100866:	c7 44 24 04 22 43 10 	movl   $0xf0104322,0x4(%esp)
f010086d:	f0 
f010086e:	8b 46 08             	mov    0x8(%esi),%eax
f0100871:	89 04 24             	mov    %eax,(%esp)
f0100874:	e8 f2 31 00 00       	call   f0103a6b <strcmp>
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
f0100886:	c7 44 24 04 26 43 10 	movl   $0xf0104326,0x4(%esp)
f010088d:	f0 
f010088e:	8b 46 08             	mov    0x8(%esi),%eax
f0100891:	89 04 24             	mov    %eax,(%esp)
f0100894:	e8 d2 31 00 00       	call   f0103a6b <strcmp>
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
f01008a6:	c7 44 24 04 2a 43 10 	movl   $0xf010432a,0x4(%esp)
f01008ad:	f0 
f01008ae:	8b 46 08             	mov    0x8(%esi),%eax
f01008b1:	89 04 24             	mov    %eax,(%esp)
f01008b4:	e8 b2 31 00 00       	call   f0103a6b <strcmp>
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
f01008c6:	c7 44 24 04 2e 43 10 	movl   $0xf010432e,0x4(%esp)
f01008cd:	f0 
f01008ce:	8b 46 08             	mov    0x8(%esi),%eax
f01008d1:	89 04 24             	mov    %eax,(%esp)
f01008d4:	e8 92 31 00 00       	call   f0103a6b <strcmp>
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
f01008e2:	c7 44 24 04 32 43 10 	movl   $0xf0104332,0x4(%esp)
f01008e9:	f0 
f01008ea:	8b 46 08             	mov    0x8(%esi),%eax
f01008ed:	89 04 24             	mov    %eax,(%esp)
f01008f0:	e8 76 31 00 00       	call   f0103a6b <strcmp>
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
f01008fe:	c7 44 24 04 36 43 10 	movl   $0xf0104336,0x4(%esp)
f0100905:	f0 
f0100906:	8b 46 08             	mov    0x8(%esi),%eax
f0100909:	89 04 24             	mov    %eax,(%esp)
f010090c:	e8 5a 31 00 00       	call   f0103a6b <strcmp>
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
f010091a:	c7 44 24 04 3a 43 10 	movl   $0xf010433a,0x4(%esp)
f0100921:	f0 
f0100922:	8b 46 08             	mov    0x8(%esi),%eax
f0100925:	89 04 24             	mov    %eax,(%esp)
f0100928:	e8 3e 31 00 00       	call   f0103a6b <strcmp>
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
f0100936:	c7 44 24 04 3e 43 10 	movl   $0xf010433e,0x4(%esp)
f010093d:	f0 
f010093e:	8b 46 08             	mov    0x8(%esi),%eax
f0100941:	89 04 24             	mov    %eax,(%esp)
f0100944:	e8 22 31 00 00       	call   f0103a6b <strcmp>
			ch_color1=COLOR_CYN
f0100949:	83 f8 01             	cmp    $0x1,%eax
f010094c:	19 ff                	sbb    %edi,%edi
f010094e:	83 e7 04             	and    $0x4,%edi
f0100951:	83 c7 07             	add    $0x7,%edi
	else ch_color1=COLOR_WHT;
	if(strcmp(argv[1],"blk")==0)
f0100954:	c7 44 24 04 1a 43 10 	movl   $0xf010431a,0x4(%esp)
f010095b:	f0 
f010095c:	8b 46 04             	mov    0x4(%esi),%eax
f010095f:	89 04 24             	mov    %eax,(%esp)
f0100962:	e8 04 31 00 00       	call   f0103a6b <strcmp>
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
f0100974:	c7 44 24 04 1e 43 10 	movl   $0xf010431e,0x4(%esp)
f010097b:	f0 
f010097c:	8b 46 04             	mov    0x4(%esi),%eax
f010097f:	89 04 24             	mov    %eax,(%esp)
f0100982:	e8 e4 30 00 00       	call   f0103a6b <strcmp>
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
f0100991:	c7 44 24 04 22 43 10 	movl   $0xf0104322,0x4(%esp)
f0100998:	f0 
f0100999:	8b 46 04             	mov    0x4(%esi),%eax
f010099c:	89 04 24             	mov    %eax,(%esp)
f010099f:	e8 c7 30 00 00       	call   f0103a6b <strcmp>
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
f01009ae:	c7 44 24 04 26 43 10 	movl   $0xf0104326,0x4(%esp)
f01009b5:	f0 
f01009b6:	8b 46 04             	mov    0x4(%esi),%eax
f01009b9:	89 04 24             	mov    %eax,(%esp)
f01009bc:	e8 aa 30 00 00       	call   f0103a6b <strcmp>
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
f01009cb:	c7 44 24 04 2a 43 10 	movl   $0xf010432a,0x4(%esp)
f01009d2:	f0 
f01009d3:	8b 46 04             	mov    0x4(%esi),%eax
f01009d6:	89 04 24             	mov    %eax,(%esp)
f01009d9:	e8 8d 30 00 00       	call   f0103a6b <strcmp>
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
f01009e8:	c7 44 24 04 2e 43 10 	movl   $0xf010432e,0x4(%esp)
f01009ef:	f0 
f01009f0:	8b 46 04             	mov    0x4(%esi),%eax
f01009f3:	89 04 24             	mov    %eax,(%esp)
f01009f6:	e8 70 30 00 00       	call   f0103a6b <strcmp>
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
f0100a01:	c7 44 24 04 32 43 10 	movl   $0xf0104332,0x4(%esp)
f0100a08:	f0 
f0100a09:	8b 46 04             	mov    0x4(%esi),%eax
f0100a0c:	89 04 24             	mov    %eax,(%esp)
f0100a0f:	e8 57 30 00 00       	call   f0103a6b <strcmp>
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
f0100a1a:	c7 44 24 04 36 43 10 	movl   $0xf0104336,0x4(%esp)
f0100a21:	f0 
f0100a22:	8b 46 04             	mov    0x4(%esi),%eax
f0100a25:	89 04 24             	mov    %eax,(%esp)
f0100a28:	e8 3e 30 00 00       	call   f0103a6b <strcmp>
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
f0100a33:	c7 44 24 04 3a 43 10 	movl   $0xf010433a,0x4(%esp)
f0100a3a:	f0 
f0100a3b:	8b 46 04             	mov    0x4(%esi),%eax
f0100a3e:	89 04 24             	mov    %eax,(%esp)
f0100a41:	e8 25 30 00 00       	call   f0103a6b <strcmp>
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
f0100a4c:	c7 44 24 04 3e 43 10 	movl   $0xf010433e,0x4(%esp)
f0100a53:	f0 
f0100a54:	8b 46 04             	mov    0x4(%esi),%eax
f0100a57:	89 04 24             	mov    %eax,(%esp)
f0100a5a:	e8 0c 30 00 00       	call   f0103a6b <strcmp>
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
f0100a84:	c7 04 24 ec 44 10 f0 	movl   $0xf01044ec,(%esp)
f0100a8b:	e8 ee 24 00 00       	call   f0102f7e <cprintf>
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
f0100aab:	c7 04 24 20 45 10 f0 	movl   $0xf0104520,(%esp)
f0100ab2:	e8 c7 24 00 00       	call   f0102f7e <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100ab7:	c7 04 24 44 45 10 f0 	movl   $0xf0104544,(%esp)
f0100abe:	e8 bb 24 00 00       	call   f0102f7e <cprintf>
  //	cprintf("x %d, y %x, z %d\n", x, y, z);
//	unsigned int i = 0x00646c72;
//	cprintf("H%x Wo%s", 57616, &i);

	while (1) {
		buf = readline("K> ");
f0100ac3:	c7 04 24 42 43 10 f0 	movl   $0xf0104342,(%esp)
f0100aca:	e8 c1 2d 00 00       	call   f0103890 <readline>
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
f0100af7:	c7 04 24 46 43 10 f0 	movl   $0xf0104346,(%esp)
f0100afe:	e8 e3 2f 00 00       	call   f0103ae6 <strchr>
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
f0100b1a:	c7 04 24 4b 43 10 f0 	movl   $0xf010434b,(%esp)
f0100b21:	e8 58 24 00 00       	call   f0102f7e <cprintf>
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
f0100b49:	c7 04 24 46 43 10 f0 	movl   $0xf0104346,(%esp)
f0100b50:	e8 91 2f 00 00       	call   f0103ae6 <strchr>
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
f0100b6b:	bb c0 45 10 f0       	mov    $0xf01045c0,%ebx
f0100b70:	bf 00 00 00 00       	mov    $0x0,%edi
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100b75:	8b 03                	mov    (%ebx),%eax
f0100b77:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100b7b:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100b7e:	89 04 24             	mov    %eax,(%esp)
f0100b81:	e8 e5 2e 00 00       	call   f0103a6b <strcmp>
f0100b86:	85 c0                	test   %eax,%eax
f0100b88:	75 24                	jne    f0100bae <monitor+0x10c>
			return commands[i].func(argc, argv, tf);
f0100b8a:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f0100b8d:	8b 55 08             	mov    0x8(%ebp),%edx
f0100b90:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100b94:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100b97:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100b9b:	89 34 24             	mov    %esi,(%esp)
f0100b9e:	ff 14 85 c8 45 10 f0 	call   *-0xfefba38(,%eax,4)
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
f0100bc0:	c7 04 24 68 43 10 f0 	movl   $0xf0104368,(%esp)
f0100bc7:	e8 b2 23 00 00       	call   f0102f7e <cprintf>
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
f0100bdf:	83 3d 5c 85 11 f0 00 	cmpl   $0x0,0xf011855c
f0100be6:	75 11                	jne    f0100bf9 <boot_alloc+0x1d>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100be8:	ba 8f 99 11 f0       	mov    $0xf011998f,%edx
f0100bed:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0100bf3:	89 15 5c 85 11 f0    	mov    %edx,0xf011855c
		void *temp = nextfree;
		nextfree += n;
		nextfree = ROUNDUP(nextfree, PGSIZE);
		return temp;
	} else if (n == 0) {
		return (void*)nextfree;
f0100bf9:	8b 15 5c 85 11 f0    	mov    0xf011855c,%edx
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
f0100c0f:	a3 5c 85 11 f0       	mov    %eax,0xf011855c
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
f0100c1e:	89 5d f8             	mov    %ebx,-0x8(%ebp)
f0100c21:	89 75 fc             	mov    %esi,-0x4(%ebp)
f0100c24:	89 c3                	mov    %eax,%ebx
f0100c26:	89 d6                	mov    %edx,%esi
//	cprintf("!");
	pte_t *p;
	cprintf("!");
f0100c28:	c7 04 24 ac 46 10 f0 	movl   $0xf01046ac,(%esp)
f0100c2f:	e8 4a 23 00 00       	call   f0102f7e <cprintf>
	pgdir = &pgdir[PDX(va)];
f0100c34:	89 f0                	mov    %esi,%eax
f0100c36:	c1 e8 16             	shr    $0x16,%eax
	if (!(*pgdir & PTE_P))
f0100c39:	8b 14 83             	mov    (%ebx,%eax,4),%edx
		return ~0;
f0100c3c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
{
//	cprintf("!");
	pte_t *p;
	cprintf("!");
	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f0100c41:	f6 c2 01             	test   $0x1,%dl
f0100c44:	74 57                	je     f0100c9d <check_va2pa+0x85>
		return ~0;
 //	cprintf("!");	
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100c46:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100c4c:	89 d0                	mov    %edx,%eax
f0100c4e:	c1 e8 0c             	shr    $0xc,%eax
f0100c51:	3b 05 84 89 11 f0    	cmp    0xf0118984,%eax
f0100c57:	72 20                	jb     f0100c79 <check_va2pa+0x61>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100c59:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0100c5d:	c7 44 24 08 c0 48 10 	movl   $0xf01048c0,0x8(%esp)
f0100c64:	f0 
f0100c65:	c7 44 24 04 d6 02 00 	movl   $0x2d6,0x4(%esp)
f0100c6c:	00 
f0100c6d:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f0100c74:	e8 1b f4 ff ff       	call   f0100094 <_panic>
	if (!(p[PTX(va)] & PTE_P))
f0100c79:	c1 ee 0c             	shr    $0xc,%esi
f0100c7c:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
f0100c82:	8b 84 b2 00 00 00 f0 	mov    -0x10000000(%edx,%esi,4),%eax
f0100c89:	89 c2                	mov    %eax,%edx
f0100c8b:	83 e2 01             	and    $0x1,%edx
		return ~0;
	return PTE_ADDR(p[PTX(va)]);
f0100c8e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100c93:	85 d2                	test   %edx,%edx
f0100c95:	ba ff ff ff ff       	mov    $0xffffffff,%edx
f0100c9a:	0f 44 c2             	cmove  %edx,%eax
}
f0100c9d:	8b 5d f8             	mov    -0x8(%ebp),%ebx
f0100ca0:	8b 75 fc             	mov    -0x4(%ebp),%esi
f0100ca3:	89 ec                	mov    %ebp,%esp
f0100ca5:	5d                   	pop    %ebp
f0100ca6:	c3                   	ret    

f0100ca7 <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f0100ca7:	55                   	push   %ebp
f0100ca8:	89 e5                	mov    %esp,%ebp
f0100caa:	83 ec 18             	sub    $0x18,%esp
f0100cad:	89 5d f8             	mov    %ebx,-0x8(%ebp)
f0100cb0:	89 75 fc             	mov    %esi,-0x4(%ebp)
f0100cb3:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100cb5:	89 04 24             	mov    %eax,(%esp)
f0100cb8:	e8 53 22 00 00       	call   f0102f10 <mc146818_read>
f0100cbd:	89 c6                	mov    %eax,%esi
f0100cbf:	83 c3 01             	add    $0x1,%ebx
f0100cc2:	89 1c 24             	mov    %ebx,(%esp)
f0100cc5:	e8 46 22 00 00       	call   f0102f10 <mc146818_read>
f0100cca:	c1 e0 08             	shl    $0x8,%eax
f0100ccd:	09 f0                	or     %esi,%eax
}
f0100ccf:	8b 5d f8             	mov    -0x8(%ebp),%ebx
f0100cd2:	8b 75 fc             	mov    -0x4(%ebp),%esi
f0100cd5:	89 ec                	mov    %ebp,%esp
f0100cd7:	5d                   	pop    %ebp
f0100cd8:	c3                   	ret    

f0100cd9 <check_page_free_list>:
//
// Check that the pages on the page_free_list are reasonable.
//
static void
check_page_free_list(bool only_low_memory)
{
f0100cd9:	55                   	push   %ebp
f0100cda:	89 e5                	mov    %esp,%ebp
f0100cdc:	57                   	push   %edi
f0100cdd:	56                   	push   %esi
f0100cde:	53                   	push   %ebx
f0100cdf:	83 ec 3c             	sub    $0x3c,%esp
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
f0100ce2:	3c 01                	cmp    $0x1,%al
f0100ce4:	19 f6                	sbb    %esi,%esi
f0100ce6:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
f0100cec:	83 c6 01             	add    $0x1,%esi
	int nfree_basemem = 0, nfree_extmem = 0;
	char *first_free_page;

	if (!page_free_list)
f0100cef:	8b 1d 60 85 11 f0    	mov    0xf0118560,%ebx
f0100cf5:	85 db                	test   %ebx,%ebx
f0100cf7:	75 1c                	jne    f0100d15 <check_page_free_list+0x3c>
		panic("'page_free_list' is a null pointer!");
f0100cf9:	c7 44 24 08 e4 48 10 	movl   $0xf01048e4,0x8(%esp)
f0100d00:	f0 
f0100d01:	c7 44 24 04 15 02 00 	movl   $0x215,0x4(%esp)
f0100d08:	00 
f0100d09:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f0100d10:	e8 7f f3 ff ff       	call   f0100094 <_panic>

	if (only_low_memory) {
f0100d15:	84 c0                	test   %al,%al
f0100d17:	74 50                	je     f0100d69 <check_page_free_list+0x90>
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
f0100d19:	8d 45 e0             	lea    -0x20(%ebp),%eax
f0100d1c:	89 45 d8             	mov    %eax,-0x28(%ebp)
f0100d1f:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0100d22:	89 45 dc             	mov    %eax,-0x24(%ebp)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100d25:	89 d8                	mov    %ebx,%eax
f0100d27:	2b 05 8c 89 11 f0    	sub    0xf011898c,%eax
f0100d2d:	c1 e0 09             	shl    $0x9,%eax
		for (pp = page_free_list; pp; pp = pp->pp_link) {
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
f0100d30:	c1 e8 16             	shr    $0x16,%eax
f0100d33:	39 c6                	cmp    %eax,%esi
f0100d35:	0f 96 c0             	setbe  %al
f0100d38:	0f b6 c0             	movzbl %al,%eax
			*tp[pagetype] = pp;
f0100d3b:	8b 54 85 d8          	mov    -0x28(%ebp,%eax,4),%edx
f0100d3f:	89 1a                	mov    %ebx,(%edx)
			tp[pagetype] = &pp->pp_link;
f0100d41:	89 5c 85 d8          	mov    %ebx,-0x28(%ebp,%eax,4)
	if (only_low_memory) {
		// Move pages with lower addresses first in the free
		// list, since entry_pgdir does not map all pages.
		struct PageInfo *pp1, *pp2;
		struct PageInfo **tp[2] = { &pp1, &pp2 };
		for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100d45:	8b 1b                	mov    (%ebx),%ebx
f0100d47:	85 db                	test   %ebx,%ebx
f0100d49:	75 da                	jne    f0100d25 <check_page_free_list+0x4c>
			int pagetype = PDX(page2pa(pp)) >= pdx_limit;
			*tp[pagetype] = pp;
			tp[pagetype] = &pp->pp_link;
		}
		*tp[1] = 0;
f0100d4b:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100d4e:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
		*tp[0] = pp2;
f0100d54:	8b 45 d8             	mov    -0x28(%ebp),%eax
f0100d57:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0100d5a:	89 10                	mov    %edx,(%eax)
		page_free_list = pp1;
f0100d5c:	8b 5d e0             	mov    -0x20(%ebp),%ebx
f0100d5f:	89 1d 60 85 11 f0    	mov    %ebx,0xf0118560
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100d65:	85 db                	test   %ebx,%ebx
f0100d67:	74 67                	je     f0100dd0 <check_page_free_list+0xf7>
f0100d69:	89 d8                	mov    %ebx,%eax
f0100d6b:	2b 05 8c 89 11 f0    	sub    0xf011898c,%eax
f0100d71:	c1 f8 03             	sar    $0x3,%eax
f0100d74:	c1 e0 0c             	shl    $0xc,%eax
		if (PDX(page2pa(pp)) < pdx_limit)
f0100d77:	89 c2                	mov    %eax,%edx
f0100d79:	c1 ea 16             	shr    $0x16,%edx
f0100d7c:	39 d6                	cmp    %edx,%esi
f0100d7e:	76 4a                	jbe    f0100dca <check_page_free_list+0xf1>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100d80:	89 c2                	mov    %eax,%edx
f0100d82:	c1 ea 0c             	shr    $0xc,%edx
f0100d85:	3b 15 84 89 11 f0    	cmp    0xf0118984,%edx
f0100d8b:	72 20                	jb     f0100dad <check_page_free_list+0xd4>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100d8d:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100d91:	c7 44 24 08 c0 48 10 	movl   $0xf01048c0,0x8(%esp)
f0100d98:	f0 
f0100d99:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100da0:	00 
f0100da1:	c7 04 24 fc 45 10 f0 	movl   $0xf01045fc,(%esp)
f0100da8:	e8 e7 f2 ff ff       	call   f0100094 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100dad:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
f0100db4:	00 
f0100db5:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
f0100dbc:	00 
	return (void *)(pa + KERNBASE);
f0100dbd:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100dc2:	89 04 24             	mov    %eax,(%esp)
f0100dc5:	e8 77 2d 00 00       	call   f0103b41 <memset>
		page_free_list = pp1;
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100dca:	8b 1b                	mov    (%ebx),%ebx
f0100dcc:	85 db                	test   %ebx,%ebx
f0100dce:	75 99                	jne    f0100d69 <check_page_free_list+0x90>
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
f0100dd0:	b8 00 00 00 00       	mov    $0x0,%eax
f0100dd5:	e8 02 fe ff ff       	call   f0100bdc <boot_alloc>
f0100dda:	89 45 c8             	mov    %eax,-0x38(%ebp)
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100ddd:	8b 15 60 85 11 f0    	mov    0xf0118560,%edx
f0100de3:	85 d2                	test   %edx,%edx
f0100de5:	0f 84 f6 01 00 00    	je     f0100fe1 <check_page_free_list+0x308>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100deb:	8b 1d 8c 89 11 f0    	mov    0xf011898c,%ebx
f0100df1:	39 da                	cmp    %ebx,%edx
f0100df3:	72 4d                	jb     f0100e42 <check_page_free_list+0x169>
		assert(pp < pages + npages);
f0100df5:	a1 84 89 11 f0       	mov    0xf0118984,%eax
f0100dfa:	89 45 cc             	mov    %eax,-0x34(%ebp)
f0100dfd:	8d 04 c3             	lea    (%ebx,%eax,8),%eax
f0100e00:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0100e03:	39 c2                	cmp    %eax,%edx
f0100e05:	73 64                	jae    f0100e6b <check_page_free_list+0x192>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100e07:	89 5d d0             	mov    %ebx,-0x30(%ebp)
f0100e0a:	89 d0                	mov    %edx,%eax
f0100e0c:	29 d8                	sub    %ebx,%eax
f0100e0e:	a8 07                	test   $0x7,%al
f0100e10:	0f 85 82 00 00 00    	jne    f0100e98 <check_page_free_list+0x1bf>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0100e16:	c1 f8 03             	sar    $0x3,%eax
f0100e19:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100e1c:	85 c0                	test   %eax,%eax
f0100e1e:	0f 84 a2 00 00 00    	je     f0100ec6 <check_page_free_list+0x1ed>
		assert(page2pa(pp) != IOPHYSMEM);
f0100e24:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100e29:	0f 84 c2 00 00 00    	je     f0100ef1 <check_page_free_list+0x218>
static void
check_page_free_list(bool only_low_memory)
{
	struct PageInfo *pp;
	unsigned pdx_limit = only_low_memory ? 1 : NPDENTRIES;
	int nfree_basemem = 0, nfree_extmem = 0;
f0100e2f:	be 00 00 00 00       	mov    $0x0,%esi
f0100e34:	bf 00 00 00 00       	mov    $0x0,%edi
f0100e39:	e9 d7 00 00 00       	jmp    f0100f15 <check_page_free_list+0x23c>
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100e3e:	39 da                	cmp    %ebx,%edx
f0100e40:	73 24                	jae    f0100e66 <check_page_free_list+0x18d>
f0100e42:	c7 44 24 0c 0a 46 10 	movl   $0xf010460a,0xc(%esp)
f0100e49:	f0 
f0100e4a:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f0100e51:	f0 
f0100e52:	c7 44 24 04 2f 02 00 	movl   $0x22f,0x4(%esp)
f0100e59:	00 
f0100e5a:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f0100e61:	e8 2e f2 ff ff       	call   f0100094 <_panic>
		assert(pp < pages + npages);
f0100e66:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100e69:	72 24                	jb     f0100e8f <check_page_free_list+0x1b6>
f0100e6b:	c7 44 24 0c 2b 46 10 	movl   $0xf010462b,0xc(%esp)
f0100e72:	f0 
f0100e73:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f0100e7a:	f0 
f0100e7b:	c7 44 24 04 30 02 00 	movl   $0x230,0x4(%esp)
f0100e82:	00 
f0100e83:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f0100e8a:	e8 05 f2 ff ff       	call   f0100094 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100e8f:	89 d0                	mov    %edx,%eax
f0100e91:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0100e94:	a8 07                	test   $0x7,%al
f0100e96:	74 24                	je     f0100ebc <check_page_free_list+0x1e3>
f0100e98:	c7 44 24 0c 08 49 10 	movl   $0xf0104908,0xc(%esp)
f0100e9f:	f0 
f0100ea0:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f0100ea7:	f0 
f0100ea8:	c7 44 24 04 31 02 00 	movl   $0x231,0x4(%esp)
f0100eaf:	00 
f0100eb0:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f0100eb7:	e8 d8 f1 ff ff       	call   f0100094 <_panic>
f0100ebc:	c1 f8 03             	sar    $0x3,%eax
f0100ebf:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100ec2:	85 c0                	test   %eax,%eax
f0100ec4:	75 24                	jne    f0100eea <check_page_free_list+0x211>
f0100ec6:	c7 44 24 0c 3f 46 10 	movl   $0xf010463f,0xc(%esp)
f0100ecd:	f0 
f0100ece:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f0100ed5:	f0 
f0100ed6:	c7 44 24 04 34 02 00 	movl   $0x234,0x4(%esp)
f0100edd:	00 
f0100ede:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f0100ee5:	e8 aa f1 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100eea:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100eef:	75 24                	jne    f0100f15 <check_page_free_list+0x23c>
f0100ef1:	c7 44 24 0c 50 46 10 	movl   $0xf0104650,0xc(%esp)
f0100ef8:	f0 
f0100ef9:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f0100f00:	f0 
f0100f01:	c7 44 24 04 35 02 00 	movl   $0x235,0x4(%esp)
f0100f08:	00 
f0100f09:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f0100f10:	e8 7f f1 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100f15:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100f1a:	75 24                	jne    f0100f40 <check_page_free_list+0x267>
f0100f1c:	c7 44 24 0c 3c 49 10 	movl   $0xf010493c,0xc(%esp)
f0100f23:	f0 
f0100f24:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f0100f2b:	f0 
f0100f2c:	c7 44 24 04 36 02 00 	movl   $0x236,0x4(%esp)
f0100f33:	00 
f0100f34:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f0100f3b:	e8 54 f1 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100f40:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100f45:	75 24                	jne    f0100f6b <check_page_free_list+0x292>
f0100f47:	c7 44 24 0c 69 46 10 	movl   $0xf0104669,0xc(%esp)
f0100f4e:	f0 
f0100f4f:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f0100f56:	f0 
f0100f57:	c7 44 24 04 37 02 00 	movl   $0x237,0x4(%esp)
f0100f5e:	00 
f0100f5f:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f0100f66:	e8 29 f1 ff ff       	call   f0100094 <_panic>
f0100f6b:	89 c1                	mov    %eax,%ecx
		assert(page2pa(pp) < EXTPHYSMEM || (char *) page2kva(pp) >= first_free_page);
f0100f6d:	3d ff ff 0f 00       	cmp    $0xfffff,%eax
f0100f72:	76 57                	jbe    f0100fcb <check_page_free_list+0x2f2>
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100f74:	c1 e8 0c             	shr    $0xc,%eax
f0100f77:	39 45 cc             	cmp    %eax,-0x34(%ebp)
f0100f7a:	77 20                	ja     f0100f9c <check_page_free_list+0x2c3>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100f7c:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0100f80:	c7 44 24 08 c0 48 10 	movl   $0xf01048c0,0x8(%esp)
f0100f87:	f0 
f0100f88:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100f8f:	00 
f0100f90:	c7 04 24 fc 45 10 f0 	movl   $0xf01045fc,(%esp)
f0100f97:	e8 f8 f0 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0100f9c:	81 e9 00 00 00 10    	sub    $0x10000000,%ecx
f0100fa2:	39 4d c8             	cmp    %ecx,-0x38(%ebp)
f0100fa5:	76 29                	jbe    f0100fd0 <check_page_free_list+0x2f7>
f0100fa7:	c7 44 24 0c 60 49 10 	movl   $0xf0104960,0xc(%esp)
f0100fae:	f0 
f0100faf:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f0100fb6:	f0 
f0100fb7:	c7 44 24 04 38 02 00 	movl   $0x238,0x4(%esp)
f0100fbe:	00 
f0100fbf:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f0100fc6:	e8 c9 f0 ff ff       	call   f0100094 <_panic>

		if (page2pa(pp) < EXTPHYSMEM)
			++nfree_basemem;
f0100fcb:	83 c7 01             	add    $0x1,%edi
f0100fce:	eb 03                	jmp    f0100fd3 <check_page_free_list+0x2fa>
		else
			++nfree_extmem;
f0100fd0:	83 c6 01             	add    $0x1,%esi
	for (pp = page_free_list; pp; pp = pp->pp_link)
		if (PDX(page2pa(pp)) < pdx_limit)
			memset(page2kva(pp), 0x97, 128);

	first_free_page = (char *) boot_alloc(0);
	for (pp = page_free_list; pp; pp = pp->pp_link) {
f0100fd3:	8b 12                	mov    (%edx),%edx
f0100fd5:	85 d2                	test   %edx,%edx
f0100fd7:	0f 85 61 fe ff ff    	jne    f0100e3e <check_page_free_list+0x165>
			++nfree_basemem;
		else
			++nfree_extmem;
	}

	assert(nfree_basemem > 0);
f0100fdd:	85 ff                	test   %edi,%edi
f0100fdf:	7f 24                	jg     f0101005 <check_page_free_list+0x32c>
f0100fe1:	c7 44 24 0c 83 46 10 	movl   $0xf0104683,0xc(%esp)
f0100fe8:	f0 
f0100fe9:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f0100ff0:	f0 
f0100ff1:	c7 44 24 04 40 02 00 	movl   $0x240,0x4(%esp)
f0100ff8:	00 
f0100ff9:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f0101000:	e8 8f f0 ff ff       	call   f0100094 <_panic>
	assert(nfree_extmem > 0);
f0101005:	85 f6                	test   %esi,%esi
f0101007:	7f 24                	jg     f010102d <check_page_free_list+0x354>
f0101009:	c7 44 24 0c 95 46 10 	movl   $0xf0104695,0xc(%esp)
f0101010:	f0 
f0101011:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f0101018:	f0 
f0101019:	c7 44 24 04 41 02 00 	movl   $0x241,0x4(%esp)
f0101020:	00 
f0101021:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f0101028:	e8 67 f0 ff ff       	call   f0100094 <_panic>
}
f010102d:	83 c4 3c             	add    $0x3c,%esp
f0101030:	5b                   	pop    %ebx
f0101031:	5e                   	pop    %esi
f0101032:	5f                   	pop    %edi
f0101033:	5d                   	pop    %ebp
f0101034:	c3                   	ret    

f0101035 <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0101035:	55                   	push   %ebp
f0101036:	89 e5                	mov    %esp,%ebp
f0101038:	56                   	push   %esi
f0101039:	53                   	push   %ebx
f010103a:	83 ec 10             	sub    $0x10,%esp
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	size_t low = IOPHYSMEM / PGSIZE;	
	size_t top = (PADDR(boot_alloc(0))) / PGSIZE;
f010103d:	b8 00 00 00 00       	mov    $0x0,%eax
f0101042:	e8 95 fb ff ff       	call   f0100bdc <boot_alloc>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0101047:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010104c:	77 20                	ja     f010106e <page_init+0x39>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010104e:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101052:	c7 44 24 08 a8 49 10 	movl   $0xf01049a8,0x8(%esp)
f0101059:	f0 
f010105a:	c7 44 24 04 03 01 00 	movl   $0x103,0x4(%esp)
f0101061:	00 
f0101062:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f0101069:	e8 26 f0 ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f010106e:	8d 98 00 00 00 10    	lea    0x10000000(%eax),%ebx
f0101074:	c1 eb 0c             	shr    $0xc,%ebx
//	cprintf("00");
	page_free_list = NULL;
f0101077:	c7 05 60 85 11 f0 00 	movl   $0x0,0xf0118560
f010107e:	00 00 00 
	for (i = 0; i < npages; i++) {
f0101081:	83 3d 84 89 11 f0 00 	cmpl   $0x0,0xf0118984
f0101088:	74 64                	je     f01010ee <page_init+0xb9>
f010108a:	b8 00 00 00 00       	mov    $0x0,%eax
f010108f:	ba 00 00 00 00       	mov    $0x0,%edx
		if (i == 0 || (i >= low && i < top)){
f0101094:	85 d2                	test   %edx,%edx
f0101096:	74 0c                	je     f01010a4 <page_init+0x6f>
f0101098:	81 fa 9f 00 00 00    	cmp    $0x9f,%edx
f010109e:	76 1f                	jbe    f01010bf <page_init+0x8a>
f01010a0:	39 da                	cmp    %ebx,%edx
f01010a2:	73 1b                	jae    f01010bf <page_init+0x8a>
			pages[i].pp_ref = 1;
f01010a4:	8d 0c d5 00 00 00 00 	lea    0x0(,%edx,8),%ecx
f01010ab:	03 0d 8c 89 11 f0    	add    0xf011898c,%ecx
f01010b1:	66 c7 41 04 01 00    	movw   $0x1,0x4(%ecx)
			pages[i].pp_link = NULL;
f01010b7:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
			continue;
f01010bd:	eb 1f                	jmp    f01010de <page_init+0xa9>
		}
		pages[i].pp_ref = 0;
f01010bf:	8d 0c d5 00 00 00 00 	lea    0x0(,%edx,8),%ecx
f01010c6:	8b 35 8c 89 11 f0    	mov    0xf011898c,%esi
f01010cc:	66 c7 44 0e 04 00 00 	movw   $0x0,0x4(%esi,%ecx,1)
	//	cprintf("%d\n", i);
		pages[i].pp_link = page_free_list;
f01010d3:	89 04 d6             	mov    %eax,(%esi,%edx,8)
		page_free_list = &pages[i];
f01010d6:	89 c8                	mov    %ecx,%eax
f01010d8:	03 05 8c 89 11 f0    	add    0xf011898c,%eax
	size_t i;
	size_t low = IOPHYSMEM / PGSIZE;	
	size_t top = (PADDR(boot_alloc(0))) / PGSIZE;
//	cprintf("00");
	page_free_list = NULL;
	for (i = 0; i < npages; i++) {
f01010de:	83 c2 01             	add    $0x1,%edx
f01010e1:	39 15 84 89 11 f0    	cmp    %edx,0xf0118984
f01010e7:	77 ab                	ja     f0101094 <page_init+0x5f>
f01010e9:	a3 60 85 11 f0       	mov    %eax,0xf0118560
		pages[i].pp_ref = 0;
	//	cprintf("%d\n", i);
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
}
f01010ee:	83 c4 10             	add    $0x10,%esp
f01010f1:	5b                   	pop    %ebx
f01010f2:	5e                   	pop    %esi
f01010f3:	5d                   	pop    %ebp
f01010f4:	c3                   	ret    

f01010f5 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f01010f5:	55                   	push   %ebp
f01010f6:	89 e5                	mov    %esp,%ebp
f01010f8:	83 ec 18             	sub    $0x18,%esp
	// Fill this function in
	if (page_free_list != NULL) {
f01010fb:	a1 60 85 11 f0       	mov    0xf0118560,%eax
f0101100:	85 c0                	test   %eax,%eax
f0101102:	74 6b                	je     f010116f <page_alloc+0x7a>
		if (alloc_flags & ALLOC_ZERO) {
f0101104:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0101108:	74 56                	je     f0101160 <page_alloc+0x6b>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010110a:	2b 05 8c 89 11 f0    	sub    0xf011898c,%eax
f0101110:	c1 f8 03             	sar    $0x3,%eax
f0101113:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101116:	89 c2                	mov    %eax,%edx
f0101118:	c1 ea 0c             	shr    $0xc,%edx
f010111b:	3b 15 84 89 11 f0    	cmp    0xf0118984,%edx
f0101121:	72 20                	jb     f0101143 <page_alloc+0x4e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101123:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101127:	c7 44 24 08 c0 48 10 	movl   $0xf01048c0,0x8(%esp)
f010112e:	f0 
f010112f:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0101136:	00 
f0101137:	c7 04 24 fc 45 10 f0 	movl   $0xf01045fc,(%esp)
f010113e:	e8 51 ef ff ff       	call   f0100094 <_panic>
//			cprintf("\n````!!!");
			memset(page2kva(page_free_list), 0, PGSIZE);
f0101143:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010114a:	00 
f010114b:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101152:	00 
	return (void *)(pa + KERNBASE);
f0101153:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101158:	89 04 24             	mov    %eax,(%esp)
f010115b:	e8 e1 29 00 00       	call   f0103b41 <memset>
		}
		struct PageInfo* temp = page_free_list;
f0101160:	a1 60 85 11 f0       	mov    0xf0118560,%eax
		page_free_list = page_free_list->pp_link;
f0101165:	8b 10                	mov    (%eax),%edx
f0101167:	89 15 60 85 11 f0    	mov    %edx,0xf0118560
//		return (struct PageInfo*) page_free_list;
		return temp;
f010116d:	eb 05                	jmp    f0101174 <page_alloc+0x7f>
	}
	return NULL;
f010116f:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101174:	c9                   	leave  
f0101175:	c3                   	ret    

f0101176 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0101176:	55                   	push   %ebp
f0101177:	89 e5                	mov    %esp,%ebp
f0101179:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	pp->pp_link = page_free_list;
f010117c:	8b 15 60 85 11 f0    	mov    0xf0118560,%edx
f0101182:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f0101184:	a3 60 85 11 f0       	mov    %eax,0xf0118560
}
f0101189:	5d                   	pop    %ebp
f010118a:	c3                   	ret    

f010118b <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f010118b:	55                   	push   %ebp
f010118c:	89 e5                	mov    %esp,%ebp
f010118e:	83 ec 04             	sub    $0x4,%esp
f0101191:	8b 45 08             	mov    0x8(%ebp),%eax
	if (--pp->pp_ref == 0)
f0101194:	0f b7 50 04          	movzwl 0x4(%eax),%edx
f0101198:	83 ea 01             	sub    $0x1,%edx
f010119b:	66 89 50 04          	mov    %dx,0x4(%eax)
f010119f:	66 85 d2             	test   %dx,%dx
f01011a2:	75 08                	jne    f01011ac <page_decref+0x21>
		page_free(pp);
f01011a4:	89 04 24             	mov    %eax,(%esp)
f01011a7:	e8 ca ff ff ff       	call   f0101176 <page_free>
}
f01011ac:	c9                   	leave  
f01011ad:	c3                   	ret    

f01011ae <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f01011ae:	55                   	push   %ebp
f01011af:	89 e5                	mov    %esp,%ebp
f01011b1:	56                   	push   %esi
f01011b2:	53                   	push   %ebx
f01011b3:	83 ec 10             	sub    $0x10,%esp
f01011b6:	8b 75 0c             	mov    0xc(%ebp),%esi
	// Fill this function in
	bool exist = false;
	pte_t *ptdir;
	if	(pgdir[PDX(va)] & PTE_P) {
f01011b9:	89 f3                	mov    %esi,%ebx
f01011bb:	c1 eb 16             	shr    $0x16,%ebx
f01011be:	c1 e3 02             	shl    $0x2,%ebx
f01011c1:	03 5d 08             	add    0x8(%ebp),%ebx
f01011c4:	8b 03                	mov    (%ebx),%eax
f01011c6:	a8 01                	test   $0x1,%al
f01011c8:	74 47                	je     f0101211 <pgdir_walk+0x63>
//		pte_t * ptdir = (pte_t*) (PGNUM(*(pgdir + PDX(va))) << PGSHIFT);
		ptdir = (pte_t*) KADDR(PTE_ADDR(pgdir[PDX(va)]));
f01011ca:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01011cf:	89 c2                	mov    %eax,%edx
f01011d1:	c1 ea 0c             	shr    $0xc,%edx
f01011d4:	3b 15 84 89 11 f0    	cmp    0xf0118984,%edx
f01011da:	72 20                	jb     f01011fc <pgdir_walk+0x4e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01011dc:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01011e0:	c7 44 24 08 c0 48 10 	movl   $0xf01048c0,0x8(%esp)
f01011e7:	f0 
f01011e8:	c7 44 24 04 62 01 00 	movl   $0x162,0x4(%esp)
f01011ef:	00 
f01011f0:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f01011f7:	e8 98 ee ff ff       	call   f0100094 <_panic>
//		pgdir[PDX(va)];
//		cprintf("%d", va);
		return ptdir + PTX(va);
f01011fc:	c1 ee 0a             	shr    $0xa,%esi
f01011ff:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f0101205:	8d 84 30 00 00 00 f0 	lea    -0x10000000(%eax,%esi,1),%eax
f010120c:	e9 85 00 00 00       	jmp    f0101296 <pgdir_walk+0xe8>
	} else {
		if (create) {
f0101211:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f0101215:	74 73                	je     f010128a <pgdir_walk+0xdc>
			struct PageInfo * temp = page_alloc(ALLOC_ZERO);
f0101217:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f010121e:	e8 d2 fe ff ff       	call   f01010f5 <page_alloc>
			if (temp == NULL) return NULL;
f0101223:	85 c0                	test   %eax,%eax
f0101225:	74 6a                	je     f0101291 <pgdir_walk+0xe3>
			temp->pp_ref++;
f0101227:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010122c:	89 c2                	mov    %eax,%edx
f010122e:	2b 15 8c 89 11 f0    	sub    0xf011898c,%edx
f0101234:	c1 fa 03             	sar    $0x3,%edx
f0101237:	c1 e2 0c             	shl    $0xc,%edx
			pgdir[PDX(va)] = page2pa(temp) | PTE_P | PTE_U | PTE_W;
f010123a:	83 ca 07             	or     $0x7,%edx
f010123d:	89 13                	mov    %edx,(%ebx)
f010123f:	2b 05 8c 89 11 f0    	sub    0xf011898c,%eax
f0101245:	c1 f8 03             	sar    $0x3,%eax
f0101248:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010124b:	89 c2                	mov    %eax,%edx
f010124d:	c1 ea 0c             	shr    $0xc,%edx
f0101250:	3b 15 84 89 11 f0    	cmp    0xf0118984,%edx
f0101256:	72 20                	jb     f0101278 <pgdir_walk+0xca>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101258:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010125c:	c7 44 24 08 c0 48 10 	movl   $0xf01048c0,0x8(%esp)
f0101263:	f0 
f0101264:	c7 44 24 04 6c 01 00 	movl   $0x16c,0x4(%esp)
f010126b:	00 
f010126c:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f0101273:	e8 1c ee ff ff       	call   f0100094 <_panic>
			ptdir = (pte_t*) KADDR(page2pa(temp));
			return ptdir + PTX(va);
f0101278:	c1 ee 0a             	shr    $0xa,%esi
f010127b:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f0101281:	8d 84 30 00 00 00 f0 	lea    -0x10000000(%eax,%esi,1),%eax
f0101288:	eb 0c                	jmp    f0101296 <pgdir_walk+0xe8>
		} else return NULL;
f010128a:	b8 00 00 00 00       	mov    $0x0,%eax
f010128f:	eb 05                	jmp    f0101296 <pgdir_walk+0xe8>
//		cprintf("%d", va);
		return ptdir + PTX(va);
	} else {
		if (create) {
			struct PageInfo * temp = page_alloc(ALLOC_ZERO);
			if (temp == NULL) return NULL;
f0101291:	b8 00 00 00 00       	mov    $0x0,%eax
			return ptdir + PTX(va);
		} else return NULL;
	}
	//temp + PTXSHIFT(va)
	return NULL;
}
f0101296:	83 c4 10             	add    $0x10,%esp
f0101299:	5b                   	pop    %ebx
f010129a:	5e                   	pop    %esi
f010129b:	5d                   	pop    %ebp
f010129c:	c3                   	ret    

f010129d <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f010129d:	55                   	push   %ebp
f010129e:	89 e5                	mov    %esp,%ebp
f01012a0:	53                   	push   %ebx
f01012a1:	83 ec 14             	sub    $0x14,%esp
f01012a4:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// Fill this function in
	pte_t* now = pgdir_walk(pgdir, va, 0);
f01012a7:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01012ae:	00 
f01012af:	8b 45 0c             	mov    0xc(%ebp),%eax
f01012b2:	89 44 24 04          	mov    %eax,0x4(%esp)
f01012b6:	8b 45 08             	mov    0x8(%ebp),%eax
f01012b9:	89 04 24             	mov    %eax,(%esp)
f01012bc:	e8 ed fe ff ff       	call   f01011ae <pgdir_walk>
	if (now != NULL) {
f01012c1:	85 c0                	test   %eax,%eax
f01012c3:	74 3a                	je     f01012ff <page_lookup+0x62>
		if (pte_store != NULL) {
f01012c5:	85 db                	test   %ebx,%ebx
f01012c7:	74 02                	je     f01012cb <page_lookup+0x2e>
			*pte_store = now;
f01012c9:	89 03                	mov    %eax,(%ebx)
		}
		return pa2page(PTE_ADDR(*now));
f01012cb:	8b 00                	mov    (%eax),%eax
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01012cd:	c1 e8 0c             	shr    $0xc,%eax
f01012d0:	3b 05 84 89 11 f0    	cmp    0xf0118984,%eax
f01012d6:	72 1c                	jb     f01012f4 <page_lookup+0x57>
		panic("pa2page called with invalid pa");
f01012d8:	c7 44 24 08 cc 49 10 	movl   $0xf01049cc,0x8(%esp)
f01012df:	f0 
f01012e0:	c7 44 24 04 4b 00 00 	movl   $0x4b,0x4(%esp)
f01012e7:	00 
f01012e8:	c7 04 24 fc 45 10 f0 	movl   $0xf01045fc,(%esp)
f01012ef:	e8 a0 ed ff ff       	call   f0100094 <_panic>
	return &pages[PGNUM(pa)];
f01012f4:	c1 e0 03             	shl    $0x3,%eax
f01012f7:	03 05 8c 89 11 f0    	add    0xf011898c,%eax
f01012fd:	eb 05                	jmp    f0101304 <page_lookup+0x67>
	}
	return NULL;
f01012ff:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101304:	83 c4 14             	add    $0x14,%esp
f0101307:	5b                   	pop    %ebx
f0101308:	5d                   	pop    %ebp
f0101309:	c3                   	ret    

f010130a <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f010130a:	55                   	push   %ebp
f010130b:	89 e5                	mov    %esp,%ebp
f010130d:	83 ec 28             	sub    $0x28,%esp
	// Fill this function in
//	if (pgdir & PTE_P == 1) {
	pte_t* now;	
	struct PageInfo* temp = page_lookup(pgdir, va, &now);
f0101310:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101313:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101317:	8b 45 0c             	mov    0xc(%ebp),%eax
f010131a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010131e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101321:	89 04 24             	mov    %eax,(%esp)
f0101324:	e8 74 ff ff ff       	call   f010129d <page_lookup>
	if (temp != NULL) {
f0101329:	85 c0                	test   %eax,%eax
f010132b:	74 19                	je     f0101346 <page_remove+0x3c>
//		cprintf("%d", now);
		if (*now & PTE_P) {
f010132d:	8b 55 f4             	mov    -0xc(%ebp),%edx
f0101330:	f6 02 01             	testb  $0x1,(%edx)
f0101333:	74 08                	je     f010133d <page_remove+0x33>
//			cprintf("subtraction finish!");
			page_decref(temp);
f0101335:	89 04 24             	mov    %eax,(%esp)
f0101338:	e8 4e fe ff ff       	call   f010118b <page_decref>
		}
		//page_decref(temp);
	//}
		*now = 0;
f010133d:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101340:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	}

}
f0101346:	c9                   	leave  
f0101347:	c3                   	ret    

f0101348 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa隐式声明函数‘page_walk’.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f0101348:	55                   	push   %ebp
f0101349:	89 e5                	mov    %esp,%ebp
f010134b:	83 ec 28             	sub    $0x28,%esp
f010134e:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0101351:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0101354:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0101357:	8b 75 0c             	mov    0xc(%ebp),%esi
f010135a:	8b 7d 10             	mov    0x10(%ebp),%edi
	// Fill this function in
	pte_t* now = pgdir_walk(pgdir, va, 0);
f010135d:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101364:	00 
f0101365:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101369:	8b 45 08             	mov    0x8(%ebp),%eax
f010136c:	89 04 24             	mov    %eax,(%esp)
f010136f:	e8 3a fe ff ff       	call   f01011ae <pgdir_walk>
f0101374:	89 c3                	mov    %eax,%ebx
	if ((now != NULL) && (*now & PTE_P)) {
f0101376:	85 c0                	test   %eax,%eax
f0101378:	74 5f                	je     f01013d9 <page_insert+0x91>
f010137a:	f6 00 01             	testb  $0x1,(%eax)
f010137d:	74 7c                	je     f01013fb <page_insert+0xb3>
		cprintf("!");
f010137f:	c7 04 24 ac 46 10 f0 	movl   $0xf01046ac,(%esp)
f0101386:	e8 f3 1b 00 00       	call   f0102f7e <cprintf>
//		PageInfo* now_page = (PageInfo*) pa2page(PTE_ADDR(now) + PGOFF(va));
//		page_remove(now_page);
		if (PTE_ADDR(*now) == page2pa(pp)) {
f010138b:	8b 03                	mov    (%ebx),%eax
f010138d:	89 c1                	mov    %eax,%ecx
f010138f:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101395:	89 f2                	mov    %esi,%edx
f0101397:	2b 15 8c 89 11 f0    	sub    0xf011898c,%edx
f010139d:	c1 fa 03             	sar    $0x3,%edx
f01013a0:	c1 e2 0c             	shl    $0xc,%edx
f01013a3:	39 d1                	cmp    %edx,%ecx
f01013a5:	75 11                	jne    f01013b8 <page_insert+0x70>
			*now = PTE_ADDR(page2pa(pp)) | perm | PTE_P;
f01013a7:	8b 45 14             	mov    0x14(%ebp),%eax
f01013aa:	83 c8 01             	or     $0x1,%eax
f01013ad:	09 c1                	or     %eax,%ecx
f01013af:	89 0b                	mov    %ecx,(%ebx)
			return 0;
f01013b1:	b8 00 00 00 00       	mov    $0x0,%eax
f01013b6:	eb 65                	jmp    f010141d <page_insert+0xd5>
		}
		cprintf("%d\n", *now);
f01013b8:	89 44 24 04          	mov    %eax,0x4(%esp)
f01013bc:	c7 04 24 a6 46 10 f0 	movl   $0xf01046a6,(%esp)
f01013c3:	e8 b6 1b 00 00       	call   f0102f7e <cprintf>
		page_remove(pgdir, va);
f01013c8:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01013cc:	8b 45 08             	mov    0x8(%ebp),%eax
f01013cf:	89 04 24             	mov    %eax,(%esp)
f01013d2:	e8 33 ff ff ff       	call   f010130a <page_remove>
f01013d7:	eb 22                	jmp    f01013fb <page_insert+0xb3>
	}
	if (now == NULL) now = pgdir_walk(pgdir, va, 1);
f01013d9:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01013e0:	00 
f01013e1:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01013e5:	8b 45 08             	mov    0x8(%ebp),%eax
f01013e8:	89 04 24             	mov    %eax,(%esp)
f01013eb:	e8 be fd ff ff       	call   f01011ae <pgdir_walk>
f01013f0:	89 c3                	mov    %eax,%ebx
	if (now == NULL) return -E_NO_MEM;
f01013f2:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f01013f7:	85 db                	test   %ebx,%ebx
f01013f9:	74 22                	je     f010141d <page_insert+0xd5>
	*now = PTE_ADDR(page2pa(pp)) | perm | PTE_P;
f01013fb:	8b 55 14             	mov    0x14(%ebp),%edx
f01013fe:	83 ca 01             	or     $0x1,%edx
f0101401:	89 f0                	mov    %esi,%eax
f0101403:	2b 05 8c 89 11 f0    	sub    0xf011898c,%eax
f0101409:	c1 f8 03             	sar    $0x3,%eax
f010140c:	c1 e0 0c             	shl    $0xc,%eax
f010140f:	09 d0                	or     %edx,%eax
f0101411:	89 03                	mov    %eax,(%ebx)
	pp->pp_ref++;
f0101413:	66 83 46 04 01       	addw   $0x1,0x4(%esi)
	return 0;
f0101418:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010141d:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0101420:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0101423:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0101426:	89 ec                	mov    %ebp,%esp
f0101428:	5d                   	pop    %ebp
f0101429:	c3                   	ret    

f010142a <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f010142a:	55                   	push   %ebp
f010142b:	89 e5                	mov    %esp,%ebp
f010142d:	57                   	push   %edi
f010142e:	56                   	push   %esi
f010142f:	53                   	push   %ebx
f0101430:	83 ec 3c             	sub    $0x3c,%esp
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f0101433:	b8 15 00 00 00       	mov    $0x15,%eax
f0101438:	e8 6a f8 ff ff       	call   f0100ca7 <nvram_read>
f010143d:	c1 e0 0a             	shl    $0xa,%eax
f0101440:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101446:	85 c0                	test   %eax,%eax
f0101448:	0f 48 c2             	cmovs  %edx,%eax
f010144b:	c1 f8 0c             	sar    $0xc,%eax
f010144e:	a3 58 85 11 f0       	mov    %eax,0xf0118558
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f0101453:	b8 17 00 00 00       	mov    $0x17,%eax
f0101458:	e8 4a f8 ff ff       	call   f0100ca7 <nvram_read>
f010145d:	c1 e0 0a             	shl    $0xa,%eax
f0101460:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101466:	85 c0                	test   %eax,%eax
f0101468:	0f 48 c2             	cmovs  %edx,%eax
f010146b:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f010146e:	85 c0                	test   %eax,%eax
f0101470:	74 0e                	je     f0101480 <mem_init+0x56>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f0101472:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f0101478:	89 15 84 89 11 f0    	mov    %edx,0xf0118984
f010147e:	eb 0c                	jmp    f010148c <mem_init+0x62>
	else
		npages = npages_basemem;
f0101480:	8b 15 58 85 11 f0    	mov    0xf0118558,%edx
f0101486:	89 15 84 89 11 f0    	mov    %edx,0xf0118984

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
		npages_extmem * PGSIZE / 1024);
f010148c:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f010148f:	c1 e8 0a             	shr    $0xa,%eax
f0101492:	89 44 24 0c          	mov    %eax,0xc(%esp)
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
f0101496:	a1 58 85 11 f0       	mov    0xf0118558,%eax
f010149b:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f010149e:	c1 e8 0a             	shr    $0xa,%eax
f01014a1:	89 44 24 08          	mov    %eax,0x8(%esp)
		npages * PGSIZE / 1024,
f01014a5:	a1 84 89 11 f0       	mov    0xf0118984,%eax
f01014aa:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01014ad:	c1 e8 0a             	shr    $0xa,%eax
f01014b0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01014b4:	c7 04 24 ec 49 10 f0 	movl   $0xf01049ec,(%esp)
f01014bb:	e8 be 1a 00 00       	call   f0102f7e <cprintf>
	// Remove this line when you're ready to test this function.
//	panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f01014c0:	b8 00 10 00 00       	mov    $0x1000,%eax
f01014c5:	e8 12 f7 ff ff       	call   f0100bdc <boot_alloc>
f01014ca:	a3 88 89 11 f0       	mov    %eax,0xf0118988
	memset(kern_pgdir, 0, PGSIZE);
f01014cf:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01014d6:	00 
f01014d7:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01014de:	00 
f01014df:	89 04 24             	mov    %eax,(%esp)
f01014e2:	e8 5a 26 00 00       	call   f0103b41 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f01014e7:	a1 88 89 11 f0       	mov    0xf0118988,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01014ec:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f01014f1:	77 20                	ja     f0101513 <mem_init+0xe9>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01014f3:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01014f7:	c7 44 24 08 a8 49 10 	movl   $0xf01049a8,0x8(%esp)
f01014fe:	f0 
f01014ff:	c7 44 24 04 91 00 00 	movl   $0x91,0x4(%esp)
f0101506:	00 
f0101507:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f010150e:	e8 81 eb ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0101513:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0101519:	83 ca 05             	or     $0x5,%edx
f010151c:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate an array of npages 'struct PageInfo's and store it in 'pages'.
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.
	// Your code goes here:
	pages = (struct PageInfo*) boot_alloc(npages * sizeof(struct PageInfo));
f0101522:	a1 84 89 11 f0       	mov    0xf0118984,%eax
f0101527:	c1 e0 03             	shl    $0x3,%eax
f010152a:	e8 ad f6 ff ff       	call   f0100bdc <boot_alloc>
f010152f:	a3 8c 89 11 f0       	mov    %eax,0xf011898c
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f0101534:	e8 fc fa ff ff       	call   f0101035 <page_init>
	cprintf("!!!");
f0101539:	c7 04 24 aa 46 10 f0 	movl   $0xf01046aa,(%esp)
f0101540:	e8 39 1a 00 00       	call   f0102f7e <cprintf>

	check_page_free_list(1);
f0101545:	b8 01 00 00 00       	mov    $0x1,%eax
f010154a:	e8 8a f7 ff ff       	call   f0100cd9 <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f010154f:	83 3d 8c 89 11 f0 00 	cmpl   $0x0,0xf011898c
f0101556:	75 1c                	jne    f0101574 <mem_init+0x14a>
		panic("'pages' is a null pointer!");
f0101558:	c7 44 24 08 ae 46 10 	movl   $0xf01046ae,0x8(%esp)
f010155f:	f0 
f0101560:	c7 44 24 04 52 02 00 	movl   $0x252,0x4(%esp)
f0101567:	00 
f0101568:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f010156f:	e8 20 eb ff ff       	call   f0100094 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101574:	a1 60 85 11 f0       	mov    0xf0118560,%eax
f0101579:	bb 00 00 00 00       	mov    $0x0,%ebx
f010157e:	85 c0                	test   %eax,%eax
f0101580:	74 09                	je     f010158b <mem_init+0x161>
		++nfree;
f0101582:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f0101585:	8b 00                	mov    (%eax),%eax
f0101587:	85 c0                	test   %eax,%eax
f0101589:	75 f7                	jne    f0101582 <mem_init+0x158>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010158b:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101592:	e8 5e fb ff ff       	call   f01010f5 <page_alloc>
f0101597:	89 c6                	mov    %eax,%esi
f0101599:	85 c0                	test   %eax,%eax
f010159b:	75 24                	jne    f01015c1 <mem_init+0x197>
f010159d:	c7 44 24 0c c9 46 10 	movl   $0xf01046c9,0xc(%esp)
f01015a4:	f0 
f01015a5:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f01015ac:	f0 
f01015ad:	c7 44 24 04 5a 02 00 	movl   $0x25a,0x4(%esp)
f01015b4:	00 
f01015b5:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f01015bc:	e8 d3 ea ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f01015c1:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01015c8:	e8 28 fb ff ff       	call   f01010f5 <page_alloc>
f01015cd:	89 c7                	mov    %eax,%edi
f01015cf:	85 c0                	test   %eax,%eax
f01015d1:	75 24                	jne    f01015f7 <mem_init+0x1cd>
f01015d3:	c7 44 24 0c df 46 10 	movl   $0xf01046df,0xc(%esp)
f01015da:	f0 
f01015db:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f01015e2:	f0 
f01015e3:	c7 44 24 04 5b 02 00 	movl   $0x25b,0x4(%esp)
f01015ea:	00 
f01015eb:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f01015f2:	e8 9d ea ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f01015f7:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01015fe:	e8 f2 fa ff ff       	call   f01010f5 <page_alloc>
f0101603:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101606:	85 c0                	test   %eax,%eax
f0101608:	75 24                	jne    f010162e <mem_init+0x204>
f010160a:	c7 44 24 0c f5 46 10 	movl   $0xf01046f5,0xc(%esp)
f0101611:	f0 
f0101612:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f0101619:	f0 
f010161a:	c7 44 24 04 5c 02 00 	movl   $0x25c,0x4(%esp)
f0101621:	00 
f0101622:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f0101629:	e8 66 ea ff ff       	call   f0100094 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010162e:	39 fe                	cmp    %edi,%esi
f0101630:	75 24                	jne    f0101656 <mem_init+0x22c>
f0101632:	c7 44 24 0c 0b 47 10 	movl   $0xf010470b,0xc(%esp)
f0101639:	f0 
f010163a:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f0101641:	f0 
f0101642:	c7 44 24 04 5f 02 00 	movl   $0x25f,0x4(%esp)
f0101649:	00 
f010164a:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f0101651:	e8 3e ea ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101656:	3b 7d d4             	cmp    -0x2c(%ebp),%edi
f0101659:	74 05                	je     f0101660 <mem_init+0x236>
f010165b:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f010165e:	75 24                	jne    f0101684 <mem_init+0x25a>
f0101660:	c7 44 24 0c 28 4a 10 	movl   $0xf0104a28,0xc(%esp)
f0101667:	f0 
f0101668:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f010166f:	f0 
f0101670:	c7 44 24 04 60 02 00 	movl   $0x260,0x4(%esp)
f0101677:	00 
f0101678:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f010167f:	e8 10 ea ff ff       	call   f0100094 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101684:	8b 15 8c 89 11 f0    	mov    0xf011898c,%edx
	assert(page2pa(pp0) < npages*PGSIZE);
f010168a:	a1 84 89 11 f0       	mov    0xf0118984,%eax
f010168f:	c1 e0 0c             	shl    $0xc,%eax
f0101692:	89 f1                	mov    %esi,%ecx
f0101694:	29 d1                	sub    %edx,%ecx
f0101696:	c1 f9 03             	sar    $0x3,%ecx
f0101699:	c1 e1 0c             	shl    $0xc,%ecx
f010169c:	39 c1                	cmp    %eax,%ecx
f010169e:	72 24                	jb     f01016c4 <mem_init+0x29a>
f01016a0:	c7 44 24 0c 1d 47 10 	movl   $0xf010471d,0xc(%esp)
f01016a7:	f0 
f01016a8:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f01016af:	f0 
f01016b0:	c7 44 24 04 61 02 00 	movl   $0x261,0x4(%esp)
f01016b7:	00 
f01016b8:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f01016bf:	e8 d0 e9 ff ff       	call   f0100094 <_panic>
f01016c4:	89 f9                	mov    %edi,%ecx
f01016c6:	29 d1                	sub    %edx,%ecx
f01016c8:	c1 f9 03             	sar    $0x3,%ecx
f01016cb:	c1 e1 0c             	shl    $0xc,%ecx
	assert(page2pa(pp1) < npages*PGSIZE);
f01016ce:	39 c8                	cmp    %ecx,%eax
f01016d0:	77 24                	ja     f01016f6 <mem_init+0x2cc>
f01016d2:	c7 44 24 0c 3a 47 10 	movl   $0xf010473a,0xc(%esp)
f01016d9:	f0 
f01016da:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f01016e1:	f0 
f01016e2:	c7 44 24 04 62 02 00 	movl   $0x262,0x4(%esp)
f01016e9:	00 
f01016ea:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f01016f1:	e8 9e e9 ff ff       	call   f0100094 <_panic>
f01016f6:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01016f9:	29 d1                	sub    %edx,%ecx
f01016fb:	89 ca                	mov    %ecx,%edx
f01016fd:	c1 fa 03             	sar    $0x3,%edx
f0101700:	c1 e2 0c             	shl    $0xc,%edx
	assert(page2pa(pp2) < npages*PGSIZE);
f0101703:	39 d0                	cmp    %edx,%eax
f0101705:	77 24                	ja     f010172b <mem_init+0x301>
f0101707:	c7 44 24 0c 57 47 10 	movl   $0xf0104757,0xc(%esp)
f010170e:	f0 
f010170f:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f0101716:	f0 
f0101717:	c7 44 24 04 63 02 00 	movl   $0x263,0x4(%esp)
f010171e:	00 
f010171f:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f0101726:	e8 69 e9 ff ff       	call   f0100094 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f010172b:	a1 60 85 11 f0       	mov    0xf0118560,%eax
f0101730:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101733:	c7 05 60 85 11 f0 00 	movl   $0x0,0xf0118560
f010173a:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f010173d:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101744:	e8 ac f9 ff ff       	call   f01010f5 <page_alloc>
f0101749:	85 c0                	test   %eax,%eax
f010174b:	74 24                	je     f0101771 <mem_init+0x347>
f010174d:	c7 44 24 0c 74 47 10 	movl   $0xf0104774,0xc(%esp)
f0101754:	f0 
f0101755:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f010175c:	f0 
f010175d:	c7 44 24 04 6a 02 00 	movl   $0x26a,0x4(%esp)
f0101764:	00 
f0101765:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f010176c:	e8 23 e9 ff ff       	call   f0100094 <_panic>

	// free and re-allocate?
	page_free(pp0);
f0101771:	89 34 24             	mov    %esi,(%esp)
f0101774:	e8 fd f9 ff ff       	call   f0101176 <page_free>
	page_free(pp1);
f0101779:	89 3c 24             	mov    %edi,(%esp)
f010177c:	e8 f5 f9 ff ff       	call   f0101176 <page_free>
	page_free(pp2);
f0101781:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101784:	89 04 24             	mov    %eax,(%esp)
f0101787:	e8 ea f9 ff ff       	call   f0101176 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f010178c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101793:	e8 5d f9 ff ff       	call   f01010f5 <page_alloc>
f0101798:	89 c6                	mov    %eax,%esi
f010179a:	85 c0                	test   %eax,%eax
f010179c:	75 24                	jne    f01017c2 <mem_init+0x398>
f010179e:	c7 44 24 0c c9 46 10 	movl   $0xf01046c9,0xc(%esp)
f01017a5:	f0 
f01017a6:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f01017ad:	f0 
f01017ae:	c7 44 24 04 71 02 00 	movl   $0x271,0x4(%esp)
f01017b5:	00 
f01017b6:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f01017bd:	e8 d2 e8 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f01017c2:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01017c9:	e8 27 f9 ff ff       	call   f01010f5 <page_alloc>
f01017ce:	89 c7                	mov    %eax,%edi
f01017d0:	85 c0                	test   %eax,%eax
f01017d2:	75 24                	jne    f01017f8 <mem_init+0x3ce>
f01017d4:	c7 44 24 0c df 46 10 	movl   $0xf01046df,0xc(%esp)
f01017db:	f0 
f01017dc:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f01017e3:	f0 
f01017e4:	c7 44 24 04 72 02 00 	movl   $0x272,0x4(%esp)
f01017eb:	00 
f01017ec:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f01017f3:	e8 9c e8 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f01017f8:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01017ff:	e8 f1 f8 ff ff       	call   f01010f5 <page_alloc>
f0101804:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101807:	85 c0                	test   %eax,%eax
f0101809:	75 24                	jne    f010182f <mem_init+0x405>
f010180b:	c7 44 24 0c f5 46 10 	movl   $0xf01046f5,0xc(%esp)
f0101812:	f0 
f0101813:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f010181a:	f0 
f010181b:	c7 44 24 04 73 02 00 	movl   $0x273,0x4(%esp)
f0101822:	00 
f0101823:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f010182a:	e8 65 e8 ff ff       	call   f0100094 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f010182f:	39 fe                	cmp    %edi,%esi
f0101831:	75 24                	jne    f0101857 <mem_init+0x42d>
f0101833:	c7 44 24 0c 0b 47 10 	movl   $0xf010470b,0xc(%esp)
f010183a:	f0 
f010183b:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f0101842:	f0 
f0101843:	c7 44 24 04 75 02 00 	movl   $0x275,0x4(%esp)
f010184a:	00 
f010184b:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f0101852:	e8 3d e8 ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101857:	3b 7d d4             	cmp    -0x2c(%ebp),%edi
f010185a:	74 05                	je     f0101861 <mem_init+0x437>
f010185c:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f010185f:	75 24                	jne    f0101885 <mem_init+0x45b>
f0101861:	c7 44 24 0c 28 4a 10 	movl   $0xf0104a28,0xc(%esp)
f0101868:	f0 
f0101869:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f0101870:	f0 
f0101871:	c7 44 24 04 76 02 00 	movl   $0x276,0x4(%esp)
f0101878:	00 
f0101879:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f0101880:	e8 0f e8 ff ff       	call   f0100094 <_panic>
	assert(!page_alloc(0));
f0101885:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010188c:	e8 64 f8 ff ff       	call   f01010f5 <page_alloc>
f0101891:	85 c0                	test   %eax,%eax
f0101893:	74 24                	je     f01018b9 <mem_init+0x48f>
f0101895:	c7 44 24 0c 74 47 10 	movl   $0xf0104774,0xc(%esp)
f010189c:	f0 
f010189d:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f01018a4:	f0 
f01018a5:	c7 44 24 04 77 02 00 	movl   $0x277,0x4(%esp)
f01018ac:	00 
f01018ad:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f01018b4:	e8 db e7 ff ff       	call   f0100094 <_panic>
f01018b9:	89 f0                	mov    %esi,%eax
f01018bb:	2b 05 8c 89 11 f0    	sub    0xf011898c,%eax
f01018c1:	c1 f8 03             	sar    $0x3,%eax
f01018c4:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01018c7:	89 c2                	mov    %eax,%edx
f01018c9:	c1 ea 0c             	shr    $0xc,%edx
f01018cc:	3b 15 84 89 11 f0    	cmp    0xf0118984,%edx
f01018d2:	72 20                	jb     f01018f4 <mem_init+0x4ca>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01018d4:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01018d8:	c7 44 24 08 c0 48 10 	movl   $0xf01048c0,0x8(%esp)
f01018df:	f0 
f01018e0:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f01018e7:	00 
f01018e8:	c7 04 24 fc 45 10 f0 	movl   $0xf01045fc,(%esp)
f01018ef:	e8 a0 e7 ff ff       	call   f0100094 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f01018f4:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01018fb:	00 
f01018fc:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0101903:	00 
	return (void *)(pa + KERNBASE);
f0101904:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101909:	89 04 24             	mov    %eax,(%esp)
f010190c:	e8 30 22 00 00       	call   f0103b41 <memset>
	page_free(pp0);
f0101911:	89 34 24             	mov    %esi,(%esp)
f0101914:	e8 5d f8 ff ff       	call   f0101176 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f0101919:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101920:	e8 d0 f7 ff ff       	call   f01010f5 <page_alloc>
f0101925:	85 c0                	test   %eax,%eax
f0101927:	75 24                	jne    f010194d <mem_init+0x523>
f0101929:	c7 44 24 0c 83 47 10 	movl   $0xf0104783,0xc(%esp)
f0101930:	f0 
f0101931:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f0101938:	f0 
f0101939:	c7 44 24 04 7c 02 00 	movl   $0x27c,0x4(%esp)
f0101940:	00 
f0101941:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f0101948:	e8 47 e7 ff ff       	call   f0100094 <_panic>
	assert(pp && pp0 == pp);
f010194d:	39 c6                	cmp    %eax,%esi
f010194f:	74 24                	je     f0101975 <mem_init+0x54b>
f0101951:	c7 44 24 0c a1 47 10 	movl   $0xf01047a1,0xc(%esp)
f0101958:	f0 
f0101959:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f0101960:	f0 
f0101961:	c7 44 24 04 7d 02 00 	movl   $0x27d,0x4(%esp)
f0101968:	00 
f0101969:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f0101970:	e8 1f e7 ff ff       	call   f0100094 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101975:	89 f2                	mov    %esi,%edx
f0101977:	2b 15 8c 89 11 f0    	sub    0xf011898c,%edx
f010197d:	c1 fa 03             	sar    $0x3,%edx
f0101980:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101983:	89 d0                	mov    %edx,%eax
f0101985:	c1 e8 0c             	shr    $0xc,%eax
f0101988:	3b 05 84 89 11 f0    	cmp    0xf0118984,%eax
f010198e:	72 20                	jb     f01019b0 <mem_init+0x586>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101990:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101994:	c7 44 24 08 c0 48 10 	movl   $0xf01048c0,0x8(%esp)
f010199b:	f0 
f010199c:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f01019a3:	00 
f01019a4:	c7 04 24 fc 45 10 f0 	movl   $0xf01045fc,(%esp)
f01019ab:	e8 e4 e6 ff ff       	call   f0100094 <_panic>
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++) 
		assert(c[i] == 0);
f01019b0:	80 ba 00 00 00 f0 00 	cmpb   $0x0,-0x10000000(%edx)
f01019b7:	75 11                	jne    f01019ca <mem_init+0x5a0>
f01019b9:	8d 82 01 00 00 f0    	lea    -0xfffffff(%edx),%eax
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f01019bf:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++) 
		assert(c[i] == 0);
f01019c5:	80 38 00             	cmpb   $0x0,(%eax)
f01019c8:	74 24                	je     f01019ee <mem_init+0x5c4>
f01019ca:	c7 44 24 0c b1 47 10 	movl   $0xf01047b1,0xc(%esp)
f01019d1:	f0 
f01019d2:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f01019d9:	f0 
f01019da:	c7 44 24 04 80 02 00 	movl   $0x280,0x4(%esp)
f01019e1:	00 
f01019e2:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f01019e9:	e8 a6 e6 ff ff       	call   f0100094 <_panic>
f01019ee:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++) 
f01019f1:	39 d0                	cmp    %edx,%eax
f01019f3:	75 d0                	jne    f01019c5 <mem_init+0x59b>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f01019f5:	8b 55 d0             	mov    -0x30(%ebp),%edx
f01019f8:	89 15 60 85 11 f0    	mov    %edx,0xf0118560

	// free the pages we took
	page_free(pp0);
f01019fe:	89 34 24             	mov    %esi,(%esp)
f0101a01:	e8 70 f7 ff ff       	call   f0101176 <page_free>
	page_free(pp1);
f0101a06:	89 3c 24             	mov    %edi,(%esp)
f0101a09:	e8 68 f7 ff ff       	call   f0101176 <page_free>
	page_free(pp2);
f0101a0e:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a11:	89 04 24             	mov    %eax,(%esp)
f0101a14:	e8 5d f7 ff ff       	call   f0101176 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101a19:	a1 60 85 11 f0       	mov    0xf0118560,%eax
f0101a1e:	85 c0                	test   %eax,%eax
f0101a20:	74 09                	je     f0101a2b <mem_init+0x601>
		--nfree;
f0101a22:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101a25:	8b 00                	mov    (%eax),%eax
f0101a27:	85 c0                	test   %eax,%eax
f0101a29:	75 f7                	jne    f0101a22 <mem_init+0x5f8>
		--nfree;
	assert(nfree == 0);
f0101a2b:	85 db                	test   %ebx,%ebx
f0101a2d:	74 24                	je     f0101a53 <mem_init+0x629>
f0101a2f:	c7 44 24 0c bb 47 10 	movl   $0xf01047bb,0xc(%esp)
f0101a36:	f0 
f0101a37:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f0101a3e:	f0 
f0101a3f:	c7 44 24 04 8d 02 00 	movl   $0x28d,0x4(%esp)
f0101a46:	00 
f0101a47:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f0101a4e:	e8 41 e6 ff ff       	call   f0100094 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f0101a53:	c7 04 24 48 4a 10 f0 	movl   $0xf0104a48,(%esp)
f0101a5a:	e8 1f 15 00 00       	call   f0102f7e <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101a5f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101a66:	e8 8a f6 ff ff       	call   f01010f5 <page_alloc>
f0101a6b:	89 c6                	mov    %eax,%esi
f0101a6d:	85 c0                	test   %eax,%eax
f0101a6f:	75 24                	jne    f0101a95 <mem_init+0x66b>
f0101a71:	c7 44 24 0c c9 46 10 	movl   $0xf01046c9,0xc(%esp)
f0101a78:	f0 
f0101a79:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f0101a80:	f0 
f0101a81:	c7 44 24 04 ea 02 00 	movl   $0x2ea,0x4(%esp)
f0101a88:	00 
f0101a89:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f0101a90:	e8 ff e5 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f0101a95:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101a9c:	e8 54 f6 ff ff       	call   f01010f5 <page_alloc>
f0101aa1:	89 c7                	mov    %eax,%edi
f0101aa3:	85 c0                	test   %eax,%eax
f0101aa5:	75 24                	jne    f0101acb <mem_init+0x6a1>
f0101aa7:	c7 44 24 0c df 46 10 	movl   $0xf01046df,0xc(%esp)
f0101aae:	f0 
f0101aaf:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f0101ab6:	f0 
f0101ab7:	c7 44 24 04 eb 02 00 	movl   $0x2eb,0x4(%esp)
f0101abe:	00 
f0101abf:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f0101ac6:	e8 c9 e5 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0101acb:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101ad2:	e8 1e f6 ff ff       	call   f01010f5 <page_alloc>
f0101ad7:	89 c3                	mov    %eax,%ebx
f0101ad9:	85 c0                	test   %eax,%eax
f0101adb:	75 24                	jne    f0101b01 <mem_init+0x6d7>
f0101add:	c7 44 24 0c f5 46 10 	movl   $0xf01046f5,0xc(%esp)
f0101ae4:	f0 
f0101ae5:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f0101aec:	f0 
f0101aed:	c7 44 24 04 ec 02 00 	movl   $0x2ec,0x4(%esp)
f0101af4:	00 
f0101af5:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f0101afc:	e8 93 e5 ff ff       	call   f0100094 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101b01:	39 fe                	cmp    %edi,%esi
f0101b03:	75 24                	jne    f0101b29 <mem_init+0x6ff>
f0101b05:	c7 44 24 0c 0b 47 10 	movl   $0xf010470b,0xc(%esp)
f0101b0c:	f0 
f0101b0d:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f0101b14:	f0 
f0101b15:	c7 44 24 04 ef 02 00 	movl   $0x2ef,0x4(%esp)
f0101b1c:	00 
f0101b1d:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f0101b24:	e8 6b e5 ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101b29:	39 c7                	cmp    %eax,%edi
f0101b2b:	74 04                	je     f0101b31 <mem_init+0x707>
f0101b2d:	39 c6                	cmp    %eax,%esi
f0101b2f:	75 24                	jne    f0101b55 <mem_init+0x72b>
f0101b31:	c7 44 24 0c 28 4a 10 	movl   $0xf0104a28,0xc(%esp)
f0101b38:	f0 
f0101b39:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f0101b40:	f0 
f0101b41:	c7 44 24 04 f0 02 00 	movl   $0x2f0,0x4(%esp)
f0101b48:	00 
f0101b49:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f0101b50:	e8 3f e5 ff ff       	call   f0100094 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101b55:	8b 15 60 85 11 f0    	mov    0xf0118560,%edx
f0101b5b:	89 55 d0             	mov    %edx,-0x30(%ebp)
	page_free_list = 0;
f0101b5e:	c7 05 60 85 11 f0 00 	movl   $0x0,0xf0118560
f0101b65:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101b68:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101b6f:	e8 81 f5 ff ff       	call   f01010f5 <page_alloc>
f0101b74:	85 c0                	test   %eax,%eax
f0101b76:	74 24                	je     f0101b9c <mem_init+0x772>
f0101b78:	c7 44 24 0c 74 47 10 	movl   $0xf0104774,0xc(%esp)
f0101b7f:	f0 
f0101b80:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f0101b87:	f0 
f0101b88:	c7 44 24 04 f7 02 00 	movl   $0x2f7,0x4(%esp)
f0101b8f:	00 
f0101b90:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f0101b97:	e8 f8 e4 ff ff       	call   f0100094 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101b9c:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101b9f:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101ba3:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101baa:	00 
f0101bab:	a1 88 89 11 f0       	mov    0xf0118988,%eax
f0101bb0:	89 04 24             	mov    %eax,(%esp)
f0101bb3:	e8 e5 f6 ff ff       	call   f010129d <page_lookup>
f0101bb8:	85 c0                	test   %eax,%eax
f0101bba:	74 24                	je     f0101be0 <mem_init+0x7b6>
f0101bbc:	c7 44 24 0c 68 4a 10 	movl   $0xf0104a68,0xc(%esp)
f0101bc3:	f0 
f0101bc4:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f0101bcb:	f0 
f0101bcc:	c7 44 24 04 fa 02 00 	movl   $0x2fa,0x4(%esp)
f0101bd3:	00 
f0101bd4:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f0101bdb:	e8 b4 e4 ff ff       	call   f0100094 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101be0:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101be7:	00 
f0101be8:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101bef:	00 
f0101bf0:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101bf4:	a1 88 89 11 f0       	mov    0xf0118988,%eax
f0101bf9:	89 04 24             	mov    %eax,(%esp)
f0101bfc:	e8 47 f7 ff ff       	call   f0101348 <page_insert>
f0101c01:	85 c0                	test   %eax,%eax
f0101c03:	78 24                	js     f0101c29 <mem_init+0x7ff>
f0101c05:	c7 44 24 0c a0 4a 10 	movl   $0xf0104aa0,0xc(%esp)
f0101c0c:	f0 
f0101c0d:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f0101c14:	f0 
f0101c15:	c7 44 24 04 fd 02 00 	movl   $0x2fd,0x4(%esp)
f0101c1c:	00 
f0101c1d:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f0101c24:	e8 6b e4 ff ff       	call   f0100094 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101c29:	89 34 24             	mov    %esi,(%esp)
f0101c2c:	e8 45 f5 ff ff       	call   f0101176 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101c31:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101c38:	00 
f0101c39:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101c40:	00 
f0101c41:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101c45:	a1 88 89 11 f0       	mov    0xf0118988,%eax
f0101c4a:	89 04 24             	mov    %eax,(%esp)
f0101c4d:	e8 f6 f6 ff ff       	call   f0101348 <page_insert>
f0101c52:	85 c0                	test   %eax,%eax
f0101c54:	74 24                	je     f0101c7a <mem_init+0x850>
f0101c56:	c7 44 24 0c d0 4a 10 	movl   $0xf0104ad0,0xc(%esp)
f0101c5d:	f0 
f0101c5e:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f0101c65:	f0 
f0101c66:	c7 44 24 04 01 03 00 	movl   $0x301,0x4(%esp)
f0101c6d:	00 
f0101c6e:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f0101c75:	e8 1a e4 ff ff       	call   f0100094 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101c7a:	a1 88 89 11 f0       	mov    0xf0118988,%eax
f0101c7f:	8b 08                	mov    (%eax),%ecx
f0101c81:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101c87:	89 f2                	mov    %esi,%edx
f0101c89:	2b 15 8c 89 11 f0    	sub    0xf011898c,%edx
f0101c8f:	c1 fa 03             	sar    $0x3,%edx
f0101c92:	c1 e2 0c             	shl    $0xc,%edx
f0101c95:	39 d1                	cmp    %edx,%ecx
f0101c97:	74 24                	je     f0101cbd <mem_init+0x893>
f0101c99:	c7 44 24 0c 00 4b 10 	movl   $0xf0104b00,0xc(%esp)
f0101ca0:	f0 
f0101ca1:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f0101ca8:	f0 
f0101ca9:	c7 44 24 04 02 03 00 	movl   $0x302,0x4(%esp)
f0101cb0:	00 
f0101cb1:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f0101cb8:	e8 d7 e3 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101cbd:	ba 00 00 00 00       	mov    $0x0,%edx
f0101cc2:	e8 51 ef ff ff       	call   f0100c18 <check_va2pa>
f0101cc7:	89 fa                	mov    %edi,%edx
f0101cc9:	2b 15 8c 89 11 f0    	sub    0xf011898c,%edx
f0101ccf:	c1 fa 03             	sar    $0x3,%edx
f0101cd2:	c1 e2 0c             	shl    $0xc,%edx
f0101cd5:	39 d0                	cmp    %edx,%eax
f0101cd7:	74 24                	je     f0101cfd <mem_init+0x8d3>
f0101cd9:	c7 44 24 0c 28 4b 10 	movl   $0xf0104b28,0xc(%esp)
f0101ce0:	f0 
f0101ce1:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f0101ce8:	f0 
f0101ce9:	c7 44 24 04 03 03 00 	movl   $0x303,0x4(%esp)
f0101cf0:	00 
f0101cf1:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f0101cf8:	e8 97 e3 ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 1);
f0101cfd:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0101d02:	74 24                	je     f0101d28 <mem_init+0x8fe>
f0101d04:	c7 44 24 0c c6 47 10 	movl   $0xf01047c6,0xc(%esp)
f0101d0b:	f0 
f0101d0c:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f0101d13:	f0 
f0101d14:	c7 44 24 04 04 03 00 	movl   $0x304,0x4(%esp)
f0101d1b:	00 
f0101d1c:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f0101d23:	e8 6c e3 ff ff       	call   f0100094 <_panic>
	assert(pp0->pp_ref == 1);
f0101d28:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101d2d:	74 24                	je     f0101d53 <mem_init+0x929>
f0101d2f:	c7 44 24 0c d7 47 10 	movl   $0xf01047d7,0xc(%esp)
f0101d36:	f0 
f0101d37:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f0101d3e:	f0 
f0101d3f:	c7 44 24 04 05 03 00 	movl   $0x305,0x4(%esp)
f0101d46:	00 
f0101d47:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f0101d4e:	e8 41 e3 ff ff       	call   f0100094 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101d53:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101d5a:	00 
f0101d5b:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101d62:	00 
f0101d63:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101d67:	a1 88 89 11 f0       	mov    0xf0118988,%eax
f0101d6c:	89 04 24             	mov    %eax,(%esp)
f0101d6f:	e8 d4 f5 ff ff       	call   f0101348 <page_insert>
f0101d74:	85 c0                	test   %eax,%eax
f0101d76:	74 24                	je     f0101d9c <mem_init+0x972>
f0101d78:	c7 44 24 0c 58 4b 10 	movl   $0xf0104b58,0xc(%esp)
f0101d7f:	f0 
f0101d80:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f0101d87:	f0 
f0101d88:	c7 44 24 04 08 03 00 	movl   $0x308,0x4(%esp)
f0101d8f:	00 
f0101d90:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f0101d97:	e8 f8 e2 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101d9c:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101da1:	a1 88 89 11 f0       	mov    0xf0118988,%eax
f0101da6:	e8 6d ee ff ff       	call   f0100c18 <check_va2pa>
f0101dab:	89 da                	mov    %ebx,%edx
f0101dad:	2b 15 8c 89 11 f0    	sub    0xf011898c,%edx
f0101db3:	c1 fa 03             	sar    $0x3,%edx
f0101db6:	c1 e2 0c             	shl    $0xc,%edx
f0101db9:	39 d0                	cmp    %edx,%eax
f0101dbb:	74 24                	je     f0101de1 <mem_init+0x9b7>
f0101dbd:	c7 44 24 0c 94 4b 10 	movl   $0xf0104b94,0xc(%esp)
f0101dc4:	f0 
f0101dc5:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f0101dcc:	f0 
f0101dcd:	c7 44 24 04 09 03 00 	movl   $0x309,0x4(%esp)
f0101dd4:	00 
f0101dd5:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f0101ddc:	e8 b3 e2 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101de1:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101de6:	74 24                	je     f0101e0c <mem_init+0x9e2>
f0101de8:	c7 44 24 0c e8 47 10 	movl   $0xf01047e8,0xc(%esp)
f0101def:	f0 
f0101df0:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f0101df7:	f0 
f0101df8:	c7 44 24 04 0a 03 00 	movl   $0x30a,0x4(%esp)
f0101dff:	00 
f0101e00:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f0101e07:	e8 88 e2 ff ff       	call   f0100094 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101e0c:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101e13:	e8 dd f2 ff ff       	call   f01010f5 <page_alloc>
f0101e18:	85 c0                	test   %eax,%eax
f0101e1a:	74 24                	je     f0101e40 <mem_init+0xa16>
f0101e1c:	c7 44 24 0c 74 47 10 	movl   $0xf0104774,0xc(%esp)
f0101e23:	f0 
f0101e24:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f0101e2b:	f0 
f0101e2c:	c7 44 24 04 0d 03 00 	movl   $0x30d,0x4(%esp)
f0101e33:	00 
f0101e34:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f0101e3b:	e8 54 e2 ff ff       	call   f0100094 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101e40:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101e47:	00 
f0101e48:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101e4f:	00 
f0101e50:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101e54:	a1 88 89 11 f0       	mov    0xf0118988,%eax
f0101e59:	89 04 24             	mov    %eax,(%esp)
f0101e5c:	e8 e7 f4 ff ff       	call   f0101348 <page_insert>
f0101e61:	85 c0                	test   %eax,%eax
f0101e63:	74 24                	je     f0101e89 <mem_init+0xa5f>
f0101e65:	c7 44 24 0c 58 4b 10 	movl   $0xf0104b58,0xc(%esp)
f0101e6c:	f0 
f0101e6d:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f0101e74:	f0 
f0101e75:	c7 44 24 04 10 03 00 	movl   $0x310,0x4(%esp)
f0101e7c:	00 
f0101e7d:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f0101e84:	e8 0b e2 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101e89:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101e8e:	a1 88 89 11 f0       	mov    0xf0118988,%eax
f0101e93:	e8 80 ed ff ff       	call   f0100c18 <check_va2pa>
f0101e98:	89 da                	mov    %ebx,%edx
f0101e9a:	2b 15 8c 89 11 f0    	sub    0xf011898c,%edx
f0101ea0:	c1 fa 03             	sar    $0x3,%edx
f0101ea3:	c1 e2 0c             	shl    $0xc,%edx
f0101ea6:	39 d0                	cmp    %edx,%eax
f0101ea8:	74 24                	je     f0101ece <mem_init+0xaa4>
f0101eaa:	c7 44 24 0c 94 4b 10 	movl   $0xf0104b94,0xc(%esp)
f0101eb1:	f0 
f0101eb2:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f0101eb9:	f0 
f0101eba:	c7 44 24 04 11 03 00 	movl   $0x311,0x4(%esp)
f0101ec1:	00 
f0101ec2:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f0101ec9:	e8 c6 e1 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101ece:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101ed3:	74 24                	je     f0101ef9 <mem_init+0xacf>
f0101ed5:	c7 44 24 0c e8 47 10 	movl   $0xf01047e8,0xc(%esp)
f0101edc:	f0 
f0101edd:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f0101ee4:	f0 
f0101ee5:	c7 44 24 04 12 03 00 	movl   $0x312,0x4(%esp)
f0101eec:	00 
f0101eed:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f0101ef4:	e8 9b e1 ff ff       	call   f0100094 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101ef9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101f00:	e8 f0 f1 ff ff       	call   f01010f5 <page_alloc>
f0101f05:	85 c0                	test   %eax,%eax
f0101f07:	74 24                	je     f0101f2d <mem_init+0xb03>
f0101f09:	c7 44 24 0c 74 47 10 	movl   $0xf0104774,0xc(%esp)
f0101f10:	f0 
f0101f11:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f0101f18:	f0 
f0101f19:	c7 44 24 04 16 03 00 	movl   $0x316,0x4(%esp)
f0101f20:	00 
f0101f21:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f0101f28:	e8 67 e1 ff ff       	call   f0100094 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101f2d:	8b 15 88 89 11 f0    	mov    0xf0118988,%edx
f0101f33:	8b 02                	mov    (%edx),%eax
f0101f35:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101f3a:	89 c1                	mov    %eax,%ecx
f0101f3c:	c1 e9 0c             	shr    $0xc,%ecx
f0101f3f:	3b 0d 84 89 11 f0    	cmp    0xf0118984,%ecx
f0101f45:	72 20                	jb     f0101f67 <mem_init+0xb3d>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101f47:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101f4b:	c7 44 24 08 c0 48 10 	movl   $0xf01048c0,0x8(%esp)
f0101f52:	f0 
f0101f53:	c7 44 24 04 19 03 00 	movl   $0x319,0x4(%esp)
f0101f5a:	00 
f0101f5b:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f0101f62:	e8 2d e1 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0101f67:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101f6c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101f6f:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101f76:	00 
f0101f77:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101f7e:	00 
f0101f7f:	89 14 24             	mov    %edx,(%esp)
f0101f82:	e8 27 f2 ff ff       	call   f01011ae <pgdir_walk>
f0101f87:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0101f8a:	83 c2 04             	add    $0x4,%edx
f0101f8d:	39 d0                	cmp    %edx,%eax
f0101f8f:	74 24                	je     f0101fb5 <mem_init+0xb8b>
f0101f91:	c7 44 24 0c c4 4b 10 	movl   $0xf0104bc4,0xc(%esp)
f0101f98:	f0 
f0101f99:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f0101fa0:	f0 
f0101fa1:	c7 44 24 04 1a 03 00 	movl   $0x31a,0x4(%esp)
f0101fa8:	00 
f0101fa9:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f0101fb0:	e8 df e0 ff ff       	call   f0100094 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101fb5:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f0101fbc:	00 
f0101fbd:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101fc4:	00 
f0101fc5:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101fc9:	a1 88 89 11 f0       	mov    0xf0118988,%eax
f0101fce:	89 04 24             	mov    %eax,(%esp)
f0101fd1:	e8 72 f3 ff ff       	call   f0101348 <page_insert>
f0101fd6:	85 c0                	test   %eax,%eax
f0101fd8:	74 24                	je     f0101ffe <mem_init+0xbd4>
f0101fda:	c7 44 24 0c 04 4c 10 	movl   $0xf0104c04,0xc(%esp)
f0101fe1:	f0 
f0101fe2:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f0101fe9:	f0 
f0101fea:	c7 44 24 04 1d 03 00 	movl   $0x31d,0x4(%esp)
f0101ff1:	00 
f0101ff2:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f0101ff9:	e8 96 e0 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101ffe:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102003:	a1 88 89 11 f0       	mov    0xf0118988,%eax
f0102008:	e8 0b ec ff ff       	call   f0100c18 <check_va2pa>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010200d:	89 da                	mov    %ebx,%edx
f010200f:	2b 15 8c 89 11 f0    	sub    0xf011898c,%edx
f0102015:	c1 fa 03             	sar    $0x3,%edx
f0102018:	c1 e2 0c             	shl    $0xc,%edx
f010201b:	39 d0                	cmp    %edx,%eax
f010201d:	74 24                	je     f0102043 <mem_init+0xc19>
f010201f:	c7 44 24 0c 94 4b 10 	movl   $0xf0104b94,0xc(%esp)
f0102026:	f0 
f0102027:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f010202e:	f0 
f010202f:	c7 44 24 04 1e 03 00 	movl   $0x31e,0x4(%esp)
f0102036:	00 
f0102037:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f010203e:	e8 51 e0 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0102043:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102048:	74 24                	je     f010206e <mem_init+0xc44>
f010204a:	c7 44 24 0c e8 47 10 	movl   $0xf01047e8,0xc(%esp)
f0102051:	f0 
f0102052:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f0102059:	f0 
f010205a:	c7 44 24 04 1f 03 00 	movl   $0x31f,0x4(%esp)
f0102061:	00 
f0102062:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f0102069:	e8 26 e0 ff ff       	call   f0100094 <_panic>

	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f010206e:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102075:	00 
f0102076:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f010207d:	00 
f010207e:	a1 88 89 11 f0       	mov    0xf0118988,%eax
f0102083:	89 04 24             	mov    %eax,(%esp)
f0102086:	e8 23 f1 ff ff       	call   f01011ae <pgdir_walk>
f010208b:	f6 00 04             	testb  $0x4,(%eax)
f010208e:	75 24                	jne    f01020b4 <mem_init+0xc8a>
f0102090:	c7 44 24 0c 44 4c 10 	movl   $0xf0104c44,0xc(%esp)
f0102097:	f0 
f0102098:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f010209f:	f0 
f01020a0:	c7 44 24 04 21 03 00 	movl   $0x321,0x4(%esp)
f01020a7:	00 
f01020a8:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f01020af:	e8 e0 df ff ff       	call   f0100094 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f01020b4:	a1 88 89 11 f0       	mov    0xf0118988,%eax
f01020b9:	f6 00 04             	testb  $0x4,(%eax)
f01020bc:	75 24                	jne    f01020e2 <mem_init+0xcb8>
f01020be:	c7 44 24 0c f9 47 10 	movl   $0xf01047f9,0xc(%esp)
f01020c5:	f0 
f01020c6:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f01020cd:	f0 
f01020ce:	c7 44 24 04 22 03 00 	movl   $0x322,0x4(%esp)
f01020d5:	00 
f01020d6:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f01020dd:	e8 b2 df ff ff       	call   f0100094 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f01020e2:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01020e9:	00 
f01020ea:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f01020f1:	00 
f01020f2:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01020f6:	89 04 24             	mov    %eax,(%esp)
f01020f9:	e8 4a f2 ff ff       	call   f0101348 <page_insert>
f01020fe:	85 c0                	test   %eax,%eax
f0102100:	74 24                	je     f0102126 <mem_init+0xcfc>
f0102102:	c7 44 24 0c 58 4b 10 	movl   $0xf0104b58,0xc(%esp)
f0102109:	f0 
f010210a:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f0102111:	f0 
f0102112:	c7 44 24 04 25 03 00 	movl   $0x325,0x4(%esp)
f0102119:	00 
f010211a:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f0102121:	e8 6e df ff ff       	call   f0100094 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0102126:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f010212d:	00 
f010212e:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102135:	00 
f0102136:	a1 88 89 11 f0       	mov    0xf0118988,%eax
f010213b:	89 04 24             	mov    %eax,(%esp)
f010213e:	e8 6b f0 ff ff       	call   f01011ae <pgdir_walk>
f0102143:	f6 00 02             	testb  $0x2,(%eax)
f0102146:	75 24                	jne    f010216c <mem_init+0xd42>
f0102148:	c7 44 24 0c 78 4c 10 	movl   $0xf0104c78,0xc(%esp)
f010214f:	f0 
f0102150:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f0102157:	f0 
f0102158:	c7 44 24 04 26 03 00 	movl   $0x326,0x4(%esp)
f010215f:	00 
f0102160:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f0102167:	e8 28 df ff ff       	call   f0100094 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f010216c:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102173:	00 
f0102174:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f010217b:	00 
f010217c:	a1 88 89 11 f0       	mov    0xf0118988,%eax
f0102181:	89 04 24             	mov    %eax,(%esp)
f0102184:	e8 25 f0 ff ff       	call   f01011ae <pgdir_walk>
f0102189:	f6 00 04             	testb  $0x4,(%eax)
f010218c:	74 24                	je     f01021b2 <mem_init+0xd88>
f010218e:	c7 44 24 0c ac 4c 10 	movl   $0xf0104cac,0xc(%esp)
f0102195:	f0 
f0102196:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f010219d:	f0 
f010219e:	c7 44 24 04 27 03 00 	movl   $0x327,0x4(%esp)
f01021a5:	00 
f01021a6:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f01021ad:	e8 e2 de ff ff       	call   f0100094 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f01021b2:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01021b9:	00 
f01021ba:	c7 44 24 08 00 00 40 	movl   $0x400000,0x8(%esp)
f01021c1:	00 
f01021c2:	89 74 24 04          	mov    %esi,0x4(%esp)
f01021c6:	a1 88 89 11 f0       	mov    0xf0118988,%eax
f01021cb:	89 04 24             	mov    %eax,(%esp)
f01021ce:	e8 75 f1 ff ff       	call   f0101348 <page_insert>
f01021d3:	85 c0                	test   %eax,%eax
f01021d5:	78 24                	js     f01021fb <mem_init+0xdd1>
f01021d7:	c7 44 24 0c e4 4c 10 	movl   $0xf0104ce4,0xc(%esp)
f01021de:	f0 
f01021df:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f01021e6:	f0 
f01021e7:	c7 44 24 04 2a 03 00 	movl   $0x32a,0x4(%esp)
f01021ee:	00 
f01021ef:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f01021f6:	e8 99 de ff ff       	call   f0100094 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
//	cprintf("~~w");
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f01021fb:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102202:	00 
f0102203:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010220a:	00 
f010220b:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010220f:	a1 88 89 11 f0       	mov    0xf0118988,%eax
f0102214:	89 04 24             	mov    %eax,(%esp)
f0102217:	e8 2c f1 ff ff       	call   f0101348 <page_insert>
f010221c:	85 c0                	test   %eax,%eax
f010221e:	74 24                	je     f0102244 <mem_init+0xe1a>
f0102220:	c7 44 24 0c 1c 4d 10 	movl   $0xf0104d1c,0xc(%esp)
f0102227:	f0 
f0102228:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f010222f:	f0 
f0102230:	c7 44 24 04 2e 03 00 	movl   $0x32e,0x4(%esp)
f0102237:	00 
f0102238:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f010223f:	e8 50 de ff ff       	call   f0100094 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0102244:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f010224b:	00 
f010224c:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102253:	00 
f0102254:	a1 88 89 11 f0       	mov    0xf0118988,%eax
f0102259:	89 04 24             	mov    %eax,(%esp)
f010225c:	e8 4d ef ff ff       	call   f01011ae <pgdir_walk>
f0102261:	f6 00 04             	testb  $0x4,(%eax)
f0102264:	74 24                	je     f010228a <mem_init+0xe60>
f0102266:	c7 44 24 0c ac 4c 10 	movl   $0xf0104cac,0xc(%esp)
f010226d:	f0 
f010226e:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f0102275:	f0 
f0102276:	c7 44 24 04 2f 03 00 	movl   $0x32f,0x4(%esp)
f010227d:	00 
f010227e:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f0102285:	e8 0a de ff ff       	call   f0100094 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f010228a:	ba 00 00 00 00       	mov    $0x0,%edx
f010228f:	a1 88 89 11 f0       	mov    0xf0118988,%eax
f0102294:	e8 7f e9 ff ff       	call   f0100c18 <check_va2pa>
f0102299:	89 fa                	mov    %edi,%edx
f010229b:	2b 15 8c 89 11 f0    	sub    0xf011898c,%edx
f01022a1:	c1 fa 03             	sar    $0x3,%edx
f01022a4:	c1 e2 0c             	shl    $0xc,%edx
f01022a7:	39 d0                	cmp    %edx,%eax
f01022a9:	74 24                	je     f01022cf <mem_init+0xea5>
f01022ab:	c7 44 24 0c 58 4d 10 	movl   $0xf0104d58,0xc(%esp)
f01022b2:	f0 
f01022b3:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f01022ba:	f0 
f01022bb:	c7 44 24 04 32 03 00 	movl   $0x332,0x4(%esp)
f01022c2:	00 
f01022c3:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f01022ca:	e8 c5 dd ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01022cf:	ba 00 10 00 00       	mov    $0x1000,%edx
f01022d4:	a1 88 89 11 f0       	mov    0xf0118988,%eax
f01022d9:	e8 3a e9 ff ff       	call   f0100c18 <check_va2pa>
f01022de:	89 fa                	mov    %edi,%edx
f01022e0:	2b 15 8c 89 11 f0    	sub    0xf011898c,%edx
f01022e6:	c1 fa 03             	sar    $0x3,%edx
f01022e9:	c1 e2 0c             	shl    $0xc,%edx
f01022ec:	39 d0                	cmp    %edx,%eax
f01022ee:	74 24                	je     f0102314 <mem_init+0xeea>
f01022f0:	c7 44 24 0c 84 4d 10 	movl   $0xf0104d84,0xc(%esp)
f01022f7:	f0 
f01022f8:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f01022ff:	f0 
f0102300:	c7 44 24 04 33 03 00 	movl   $0x333,0x4(%esp)
f0102307:	00 
f0102308:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f010230f:	e8 80 dd ff ff       	call   f0100094 <_panic>
	// ... and ref counts should reflect this
//	cprintf("%d %d", pp1->pp_ref, pp2->pp_ref);
	assert(pp1->pp_ref == 2);
f0102314:	66 83 7f 04 02       	cmpw   $0x2,0x4(%edi)
f0102319:	74 24                	je     f010233f <mem_init+0xf15>
f010231b:	c7 44 24 0c 0f 48 10 	movl   $0xf010480f,0xc(%esp)
f0102322:	f0 
f0102323:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f010232a:	f0 
f010232b:	c7 44 24 04 36 03 00 	movl   $0x336,0x4(%esp)
f0102332:	00 
f0102333:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f010233a:	e8 55 dd ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f010233f:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102344:	74 24                	je     f010236a <mem_init+0xf40>
f0102346:	c7 44 24 0c 20 48 10 	movl   $0xf0104820,0xc(%esp)
f010234d:	f0 
f010234e:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f0102355:	f0 
f0102356:	c7 44 24 04 37 03 00 	movl   $0x337,0x4(%esp)
f010235d:	00 
f010235e:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f0102365:	e8 2a dd ff ff       	call   f0100094 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f010236a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102371:	e8 7f ed ff ff       	call   f01010f5 <page_alloc>
f0102376:	85 c0                	test   %eax,%eax
f0102378:	74 04                	je     f010237e <mem_init+0xf54>
f010237a:	39 c3                	cmp    %eax,%ebx
f010237c:	74 24                	je     f01023a2 <mem_init+0xf78>
f010237e:	c7 44 24 0c b4 4d 10 	movl   $0xf0104db4,0xc(%esp)
f0102385:	f0 
f0102386:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f010238d:	f0 
f010238e:	c7 44 24 04 3a 03 00 	movl   $0x33a,0x4(%esp)
f0102395:	00 
f0102396:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f010239d:	e8 f2 dc ff ff       	call   f0100094 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f01023a2:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01023a9:	00 
f01023aa:	a1 88 89 11 f0       	mov    0xf0118988,%eax
f01023af:	89 04 24             	mov    %eax,(%esp)
f01023b2:	e8 53 ef ff ff       	call   f010130a <page_remove>
	cprintf("~~~");
f01023b7:	c7 04 24 31 48 10 f0 	movl   $0xf0104831,(%esp)
f01023be:	e8 bb 0b 00 00       	call   f0102f7e <cprintf>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f01023c3:	ba 00 00 00 00       	mov    $0x0,%edx
f01023c8:	a1 88 89 11 f0       	mov    0xf0118988,%eax
f01023cd:	e8 46 e8 ff ff       	call   f0100c18 <check_va2pa>
f01023d2:	83 f8 ff             	cmp    $0xffffffff,%eax
f01023d5:	74 24                	je     f01023fb <mem_init+0xfd1>
f01023d7:	c7 44 24 0c d8 4d 10 	movl   $0xf0104dd8,0xc(%esp)
f01023de:	f0 
f01023df:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f01023e6:	f0 
f01023e7:	c7 44 24 04 3f 03 00 	movl   $0x33f,0x4(%esp)
f01023ee:	00 
f01023ef:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f01023f6:	e8 99 dc ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f01023fb:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102400:	a1 88 89 11 f0       	mov    0xf0118988,%eax
f0102405:	e8 0e e8 ff ff       	call   f0100c18 <check_va2pa>
f010240a:	89 fa                	mov    %edi,%edx
f010240c:	2b 15 8c 89 11 f0    	sub    0xf011898c,%edx
f0102412:	c1 fa 03             	sar    $0x3,%edx
f0102415:	c1 e2 0c             	shl    $0xc,%edx
f0102418:	39 d0                	cmp    %edx,%eax
f010241a:	74 24                	je     f0102440 <mem_init+0x1016>
f010241c:	c7 44 24 0c 84 4d 10 	movl   $0xf0104d84,0xc(%esp)
f0102423:	f0 
f0102424:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f010242b:	f0 
f010242c:	c7 44 24 04 40 03 00 	movl   $0x340,0x4(%esp)
f0102433:	00 
f0102434:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f010243b:	e8 54 dc ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 1);
f0102440:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102445:	74 24                	je     f010246b <mem_init+0x1041>
f0102447:	c7 44 24 0c c6 47 10 	movl   $0xf01047c6,0xc(%esp)
f010244e:	f0 
f010244f:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f0102456:	f0 
f0102457:	c7 44 24 04 41 03 00 	movl   $0x341,0x4(%esp)
f010245e:	00 
f010245f:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f0102466:	e8 29 dc ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f010246b:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102470:	74 24                	je     f0102496 <mem_init+0x106c>
f0102472:	c7 44 24 0c 20 48 10 	movl   $0xf0104820,0xc(%esp)
f0102479:	f0 
f010247a:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f0102481:	f0 
f0102482:	c7 44 24 04 42 03 00 	movl   $0x342,0x4(%esp)
f0102489:	00 
f010248a:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f0102491:	e8 fe db ff ff       	call   f0100094 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102496:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f010249d:	00 
f010249e:	a1 88 89 11 f0       	mov    0xf0118988,%eax
f01024a3:	89 04 24             	mov    %eax,(%esp)
f01024a6:	e8 5f ee ff ff       	call   f010130a <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f01024ab:	ba 00 00 00 00       	mov    $0x0,%edx
f01024b0:	a1 88 89 11 f0       	mov    0xf0118988,%eax
f01024b5:	e8 5e e7 ff ff       	call   f0100c18 <check_va2pa>
f01024ba:	83 f8 ff             	cmp    $0xffffffff,%eax
f01024bd:	74 24                	je     f01024e3 <mem_init+0x10b9>
f01024bf:	c7 44 24 0c d8 4d 10 	movl   $0xf0104dd8,0xc(%esp)
f01024c6:	f0 
f01024c7:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f01024ce:	f0 
f01024cf:	c7 44 24 04 46 03 00 	movl   $0x346,0x4(%esp)
f01024d6:	00 
f01024d7:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f01024de:	e8 b1 db ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f01024e3:	ba 00 10 00 00       	mov    $0x1000,%edx
f01024e8:	a1 88 89 11 f0       	mov    0xf0118988,%eax
f01024ed:	e8 26 e7 ff ff       	call   f0100c18 <check_va2pa>
f01024f2:	83 f8 ff             	cmp    $0xffffffff,%eax
f01024f5:	74 24                	je     f010251b <mem_init+0x10f1>
f01024f7:	c7 44 24 0c fc 4d 10 	movl   $0xf0104dfc,0xc(%esp)
f01024fe:	f0 
f01024ff:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f0102506:	f0 
f0102507:	c7 44 24 04 47 03 00 	movl   $0x347,0x4(%esp)
f010250e:	00 
f010250f:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f0102516:	e8 79 db ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 0);
f010251b:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102520:	74 24                	je     f0102546 <mem_init+0x111c>
f0102522:	c7 44 24 0c 35 48 10 	movl   $0xf0104835,0xc(%esp)
f0102529:	f0 
f010252a:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f0102531:	f0 
f0102532:	c7 44 24 04 48 03 00 	movl   $0x348,0x4(%esp)
f0102539:	00 
f010253a:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f0102541:	e8 4e db ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f0102546:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f010254b:	74 24                	je     f0102571 <mem_init+0x1147>
f010254d:	c7 44 24 0c 20 48 10 	movl   $0xf0104820,0xc(%esp)
f0102554:	f0 
f0102555:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f010255c:	f0 
f010255d:	c7 44 24 04 49 03 00 	movl   $0x349,0x4(%esp)
f0102564:	00 
f0102565:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f010256c:	e8 23 db ff ff       	call   f0100094 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f0102571:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102578:	e8 78 eb ff ff       	call   f01010f5 <page_alloc>
f010257d:	85 c0                	test   %eax,%eax
f010257f:	74 04                	je     f0102585 <mem_init+0x115b>
f0102581:	39 c7                	cmp    %eax,%edi
f0102583:	74 24                	je     f01025a9 <mem_init+0x117f>
f0102585:	c7 44 24 0c 24 4e 10 	movl   $0xf0104e24,0xc(%esp)
f010258c:	f0 
f010258d:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f0102594:	f0 
f0102595:	c7 44 24 04 4c 03 00 	movl   $0x34c,0x4(%esp)
f010259c:	00 
f010259d:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f01025a4:	e8 eb da ff ff       	call   f0100094 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f01025a9:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01025b0:	e8 40 eb ff ff       	call   f01010f5 <page_alloc>
f01025b5:	85 c0                	test   %eax,%eax
f01025b7:	74 24                	je     f01025dd <mem_init+0x11b3>
f01025b9:	c7 44 24 0c 74 47 10 	movl   $0xf0104774,0xc(%esp)
f01025c0:	f0 
f01025c1:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f01025c8:	f0 
f01025c9:	c7 44 24 04 4f 03 00 	movl   $0x34f,0x4(%esp)
f01025d0:	00 
f01025d1:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f01025d8:	e8 b7 da ff ff       	call   f0100094 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f01025dd:	a1 88 89 11 f0       	mov    0xf0118988,%eax
f01025e2:	8b 08                	mov    (%eax),%ecx
f01025e4:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f01025ea:	89 f2                	mov    %esi,%edx
f01025ec:	2b 15 8c 89 11 f0    	sub    0xf011898c,%edx
f01025f2:	c1 fa 03             	sar    $0x3,%edx
f01025f5:	c1 e2 0c             	shl    $0xc,%edx
f01025f8:	39 d1                	cmp    %edx,%ecx
f01025fa:	74 24                	je     f0102620 <mem_init+0x11f6>
f01025fc:	c7 44 24 0c 00 4b 10 	movl   $0xf0104b00,0xc(%esp)
f0102603:	f0 
f0102604:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f010260b:	f0 
f010260c:	c7 44 24 04 52 03 00 	movl   $0x352,0x4(%esp)
f0102613:	00 
f0102614:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f010261b:	e8 74 da ff ff       	call   f0100094 <_panic>
	kern_pgdir[0] = 0;
f0102620:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f0102626:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f010262b:	74 24                	je     f0102651 <mem_init+0x1227>
f010262d:	c7 44 24 0c d7 47 10 	movl   $0xf01047d7,0xc(%esp)
f0102634:	f0 
f0102635:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f010263c:	f0 
f010263d:	c7 44 24 04 54 03 00 	movl   $0x354,0x4(%esp)
f0102644:	00 
f0102645:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f010264c:	e8 43 da ff ff       	call   f0100094 <_panic>
	pp0->pp_ref = 0;
f0102651:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0102657:	89 34 24             	mov    %esi,(%esp)
f010265a:	e8 17 eb ff ff       	call   f0101176 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f010265f:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0102666:	00 
f0102667:	c7 44 24 04 00 10 40 	movl   $0x401000,0x4(%esp)
f010266e:	00 
f010266f:	a1 88 89 11 f0       	mov    0xf0118988,%eax
f0102674:	89 04 24             	mov    %eax,(%esp)
f0102677:	e8 32 eb ff ff       	call   f01011ae <pgdir_walk>
f010267c:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f010267f:	8b 0d 88 89 11 f0    	mov    0xf0118988,%ecx
f0102685:	8b 51 04             	mov    0x4(%ecx),%edx
f0102688:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f010268e:	89 55 d4             	mov    %edx,-0x2c(%ebp)
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102691:	8b 15 84 89 11 f0    	mov    0xf0118984,%edx
f0102697:	89 55 c8             	mov    %edx,-0x38(%ebp)
f010269a:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f010269d:	c1 ea 0c             	shr    $0xc,%edx
f01026a0:	89 55 cc             	mov    %edx,-0x34(%ebp)
f01026a3:	8b 55 c8             	mov    -0x38(%ebp),%edx
f01026a6:	39 55 cc             	cmp    %edx,-0x34(%ebp)
f01026a9:	72 23                	jb     f01026ce <mem_init+0x12a4>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01026ab:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01026ae:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01026b2:	c7 44 24 08 c0 48 10 	movl   $0xf01048c0,0x8(%esp)
f01026b9:	f0 
f01026ba:	c7 44 24 04 5b 03 00 	movl   $0x35b,0x4(%esp)
f01026c1:	00 
f01026c2:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f01026c9:	e8 c6 d9 ff ff       	call   f0100094 <_panic>
	assert(ptep == ptep1 + PTX(va));
f01026ce:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01026d1:	81 ea fc ff ff 0f    	sub    $0xffffffc,%edx
f01026d7:	39 d0                	cmp    %edx,%eax
f01026d9:	74 24                	je     f01026ff <mem_init+0x12d5>
f01026db:	c7 44 24 0c 46 48 10 	movl   $0xf0104846,0xc(%esp)
f01026e2:	f0 
f01026e3:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f01026ea:	f0 
f01026eb:	c7 44 24 04 5c 03 00 	movl   $0x35c,0x4(%esp)
f01026f2:	00 
f01026f3:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f01026fa:	e8 95 d9 ff ff       	call   f0100094 <_panic>
	kern_pgdir[PDX(va)] = 0;
f01026ff:	c7 41 04 00 00 00 00 	movl   $0x0,0x4(%ecx)
	pp0->pp_ref = 0;
f0102706:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010270c:	89 f0                	mov    %esi,%eax
f010270e:	2b 05 8c 89 11 f0    	sub    0xf011898c,%eax
f0102714:	c1 f8 03             	sar    $0x3,%eax
f0102717:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010271a:	89 c1                	mov    %eax,%ecx
f010271c:	c1 e9 0c             	shr    $0xc,%ecx
f010271f:	39 4d c8             	cmp    %ecx,-0x38(%ebp)
f0102722:	77 20                	ja     f0102744 <mem_init+0x131a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102724:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102728:	c7 44 24 08 c0 48 10 	movl   $0xf01048c0,0x8(%esp)
f010272f:	f0 
f0102730:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0102737:	00 
f0102738:	c7 04 24 fc 45 10 f0 	movl   $0xf01045fc,(%esp)
f010273f:	e8 50 d9 ff ff       	call   f0100094 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0102744:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010274b:	00 
f010274c:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
f0102753:	00 
	return (void *)(pa + KERNBASE);
f0102754:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102759:	89 04 24             	mov    %eax,(%esp)
f010275c:	e8 e0 13 00 00       	call   f0103b41 <memset>
	page_free(pp0);
f0102761:	89 34 24             	mov    %esi,(%esp)
f0102764:	e8 0d ea ff ff       	call   f0101176 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0102769:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0102770:	00 
f0102771:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0102778:	00 
f0102779:	a1 88 89 11 f0       	mov    0xf0118988,%eax
f010277e:	89 04 24             	mov    %eax,(%esp)
f0102781:	e8 28 ea ff ff       	call   f01011ae <pgdir_walk>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102786:	89 f2                	mov    %esi,%edx
f0102788:	2b 15 8c 89 11 f0    	sub    0xf011898c,%edx
f010278e:	c1 fa 03             	sar    $0x3,%edx
f0102791:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102794:	89 d0                	mov    %edx,%eax
f0102796:	c1 e8 0c             	shr    $0xc,%eax
f0102799:	3b 05 84 89 11 f0    	cmp    0xf0118984,%eax
f010279f:	72 20                	jb     f01027c1 <mem_init+0x1397>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01027a1:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01027a5:	c7 44 24 08 c0 48 10 	movl   $0xf01048c0,0x8(%esp)
f01027ac:	f0 
f01027ad:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f01027b4:	00 
f01027b5:	c7 04 24 fc 45 10 f0 	movl   $0xf01045fc,(%esp)
f01027bc:	e8 d3 d8 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f01027c1:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f01027c7:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f01027ca:	f6 82 00 00 00 f0 01 	testb  $0x1,-0x10000000(%edx)
f01027d1:	75 11                	jne    f01027e4 <mem_init+0x13ba>
f01027d3:	8d 82 04 00 00 f0    	lea    -0xffffffc(%edx),%eax
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f01027d9:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f01027df:	f6 00 01             	testb  $0x1,(%eax)
f01027e2:	74 24                	je     f0102808 <mem_init+0x13de>
f01027e4:	c7 44 24 0c 5e 48 10 	movl   $0xf010485e,0xc(%esp)
f01027eb:	f0 
f01027ec:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f01027f3:	f0 
f01027f4:	c7 44 24 04 66 03 00 	movl   $0x366,0x4(%esp)
f01027fb:	00 
f01027fc:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f0102803:	e8 8c d8 ff ff       	call   f0100094 <_panic>
f0102808:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f010280b:	39 d0                	cmp    %edx,%eax
f010280d:	75 d0                	jne    f01027df <mem_init+0x13b5>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f010280f:	a1 88 89 11 f0       	mov    0xf0118988,%eax
f0102814:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f010281a:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// give free list back
	page_free_list = fl;
f0102820:	8b 4d d0             	mov    -0x30(%ebp),%ecx
f0102823:	89 0d 60 85 11 f0    	mov    %ecx,0xf0118560

	// free the pages we took
	page_free(pp0);
f0102829:	89 34 24             	mov    %esi,(%esp)
f010282c:	e8 45 e9 ff ff       	call   f0101176 <page_free>
	page_free(pp1);
f0102831:	89 3c 24             	mov    %edi,(%esp)
f0102834:	e8 3d e9 ff ff       	call   f0101176 <page_free>
	page_free(pp2);
f0102839:	89 1c 24             	mov    %ebx,(%esp)
f010283c:	e8 35 e9 ff ff       	call   f0101176 <page_free>

	cprintf("check_page() succeeded!\n");
f0102841:	c7 04 24 75 48 10 f0 	movl   $0xf0104875,(%esp)
f0102848:	e8 31 07 00 00       	call   f0102f7e <cprintf>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f010284d:	8b 1d 88 89 11 f0    	mov    0xf0118988,%ebx

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0102853:	a1 84 89 11 f0       	mov    0xf0118984,%eax
f0102858:	8d 3c c5 ff 0f 00 00 	lea    0xfff(,%eax,8),%edi
	for (i = 0; i < n; i += PGSIZE) {
f010285f:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
f0102865:	0f 84 8d 00 00 00    	je     f01028f8 <mem_init+0x14ce>
f010286b:	be 00 00 00 00       	mov    $0x0,%esi
		cprintf("%d", i);
f0102870:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102874:	c7 04 24 1f 50 10 f0 	movl   $0xf010501f,(%esp)
f010287b:	e8 fe 06 00 00       	call   f0102f7e <cprintf>
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0102880:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE) {
		cprintf("%d", i);
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102886:	89 d8                	mov    %ebx,%eax
f0102888:	e8 8b e3 ff ff       	call   f0100c18 <check_va2pa>
f010288d:	8b 15 8c 89 11 f0    	mov    0xf011898c,%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102893:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0102899:	77 20                	ja     f01028bb <mem_init+0x1491>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010289b:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010289f:	c7 44 24 08 a8 49 10 	movl   $0xf01049a8,0x8(%esp)
f01028a6:	f0 
f01028a7:	c7 44 24 04 a6 02 00 	movl   $0x2a6,0x4(%esp)
f01028ae:	00 
f01028af:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f01028b6:	e8 d9 d7 ff ff       	call   f0100094 <_panic>
f01028bb:	8d 94 32 00 00 00 10 	lea    0x10000000(%edx,%esi,1),%edx
f01028c2:	39 d0                	cmp    %edx,%eax
f01028c4:	74 24                	je     f01028ea <mem_init+0x14c0>
f01028c6:	c7 44 24 0c 48 4e 10 	movl   $0xf0104e48,0xc(%esp)
f01028cd:	f0 
f01028ce:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f01028d5:	f0 
f01028d6:	c7 44 24 04 a6 02 00 	movl   $0x2a6,0x4(%esp)
f01028dd:	00 
f01028de:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f01028e5:	e8 aa d7 ff ff       	call   f0100094 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE) {
f01028ea:	81 c6 00 10 00 00    	add    $0x1000,%esi
f01028f0:	39 f7                	cmp    %esi,%edi
f01028f2:	0f 87 78 ff ff ff    	ja     f0102870 <mem_init+0x1446>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
	}


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01028f8:	a1 84 89 11 f0       	mov    0xf0118984,%eax
f01028fd:	c1 e0 0c             	shl    $0xc,%eax
f0102900:	85 c0                	test   %eax,%eax
f0102902:	74 4c                	je     f0102950 <mem_init+0x1526>
f0102904:	be 00 00 00 00       	mov    $0x0,%esi
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0102909:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
	}


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f010290f:	89 d8                	mov    %ebx,%eax
f0102911:	e8 02 e3 ff ff       	call   f0100c18 <check_va2pa>
f0102916:	39 c6                	cmp    %eax,%esi
f0102918:	74 24                	je     f010293e <mem_init+0x1514>
f010291a:	c7 44 24 0c 7c 4e 10 	movl   $0xf0104e7c,0xc(%esp)
f0102921:	f0 
f0102922:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f0102929:	f0 
f010292a:	c7 44 24 04 ac 02 00 	movl   $0x2ac,0x4(%esp)
f0102931:	00 
f0102932:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f0102939:	e8 56 d7 ff ff       	call   f0100094 <_panic>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
	}


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f010293e:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102944:	a1 84 89 11 f0       	mov    0xf0118984,%eax
f0102949:	c1 e0 0c             	shl    $0xc,%eax
f010294c:	39 c6                	cmp    %eax,%esi
f010294e:	72 b9                	jb     f0102909 <mem_init+0x14df>
f0102950:	be 00 80 ff ef       	mov    $0xefff8000,%esi
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102955:	bf 00 e0 10 f0       	mov    $0xf010e000,%edi
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f010295a:	89 f2                	mov    %esi,%edx
f010295c:	89 d8                	mov    %ebx,%eax
f010295e:	e8 b5 e2 ff ff       	call   f0100c18 <check_va2pa>
f0102963:	81 ff ff ff ff ef    	cmp    $0xefffffff,%edi
f0102969:	77 24                	ja     f010298f <mem_init+0x1565>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f010296b:	c7 44 24 0c 00 e0 10 	movl   $0xf010e000,0xc(%esp)
f0102972:	f0 
f0102973:	c7 44 24 08 a8 49 10 	movl   $0xf01049a8,0x8(%esp)
f010297a:	f0 
f010297b:	c7 44 24 04 b0 02 00 	movl   $0x2b0,0x4(%esp)
f0102982:	00 
f0102983:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f010298a:	e8 05 d7 ff ff       	call   f0100094 <_panic>
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f010298f:	8d 96 00 60 11 10    	lea    0x10116000(%esi),%edx
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102995:	39 d0                	cmp    %edx,%eax
f0102997:	74 24                	je     f01029bd <mem_init+0x1593>
f0102999:	c7 44 24 0c a4 4e 10 	movl   $0xf0104ea4,0xc(%esp)
f01029a0:	f0 
f01029a1:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f01029a8:	f0 
f01029a9:	c7 44 24 04 b0 02 00 	movl   $0x2b0,0x4(%esp)
f01029b0:	00 
f01029b1:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f01029b8:	e8 d7 d6 ff ff       	call   f0100094 <_panic>
f01029bd:	81 c6 00 10 00 00    	add    $0x1000,%esi
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f01029c3:	81 fe 00 00 00 f0    	cmp    $0xf0000000,%esi
f01029c9:	75 8f                	jne    f010295a <mem_init+0x1530>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f01029cb:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f01029d0:	89 d8                	mov    %ebx,%eax
f01029d2:	e8 41 e2 ff ff       	call   f0100c18 <check_va2pa>
f01029d7:	83 f8 ff             	cmp    $0xffffffff,%eax
f01029da:	74 24                	je     f0102a00 <mem_init+0x15d6>
f01029dc:	c7 44 24 0c ec 4e 10 	movl   $0xf0104eec,0xc(%esp)
f01029e3:	f0 
f01029e4:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f01029eb:	f0 
f01029ec:	c7 44 24 04 b1 02 00 	movl   $0x2b1,0x4(%esp)
f01029f3:	00 
f01029f4:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f01029fb:	e8 94 d6 ff ff       	call   f0100094 <_panic>
f0102a00:	b8 00 00 00 00       	mov    $0x0,%eax

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f0102a05:	ba 01 00 00 00       	mov    $0x1,%edx
f0102a0a:	8d 88 44 fc ff ff    	lea    -0x3bc(%eax),%ecx
f0102a10:	83 f9 03             	cmp    $0x3,%ecx
f0102a13:	77 39                	ja     f0102a4e <mem_init+0x1624>
f0102a15:	89 d6                	mov    %edx,%esi
f0102a17:	d3 e6                	shl    %cl,%esi
f0102a19:	89 f1                	mov    %esi,%ecx
f0102a1b:	f6 c1 0b             	test   $0xb,%cl
f0102a1e:	74 2e                	je     f0102a4e <mem_init+0x1624>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
f0102a20:	f6 04 83 01          	testb  $0x1,(%ebx,%eax,4)
f0102a24:	0f 85 aa 00 00 00    	jne    f0102ad4 <mem_init+0x16aa>
f0102a2a:	c7 44 24 0c 8e 48 10 	movl   $0xf010488e,0xc(%esp)
f0102a31:	f0 
f0102a32:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f0102a39:	f0 
f0102a3a:	c7 44 24 04 b9 02 00 	movl   $0x2b9,0x4(%esp)
f0102a41:	00 
f0102a42:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f0102a49:	e8 46 d6 ff ff       	call   f0100094 <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f0102a4e:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102a53:	76 55                	jbe    f0102aaa <mem_init+0x1680>
				assert(pgdir[i] & PTE_P);
f0102a55:	8b 0c 83             	mov    (%ebx,%eax,4),%ecx
f0102a58:	f6 c1 01             	test   $0x1,%cl
f0102a5b:	75 24                	jne    f0102a81 <mem_init+0x1657>
f0102a5d:	c7 44 24 0c 8e 48 10 	movl   $0xf010488e,0xc(%esp)
f0102a64:	f0 
f0102a65:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f0102a6c:	f0 
f0102a6d:	c7 44 24 04 bd 02 00 	movl   $0x2bd,0x4(%esp)
f0102a74:	00 
f0102a75:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f0102a7c:	e8 13 d6 ff ff       	call   f0100094 <_panic>
				assert(pgdir[i] & PTE_W);
f0102a81:	f6 c1 02             	test   $0x2,%cl
f0102a84:	75 4e                	jne    f0102ad4 <mem_init+0x16aa>
f0102a86:	c7 44 24 0c 9f 48 10 	movl   $0xf010489f,0xc(%esp)
f0102a8d:	f0 
f0102a8e:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f0102a95:	f0 
f0102a96:	c7 44 24 04 be 02 00 	movl   $0x2be,0x4(%esp)
f0102a9d:	00 
f0102a9e:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f0102aa5:	e8 ea d5 ff ff       	call   f0100094 <_panic>
			} else
				assert(pgdir[i] == 0);
f0102aaa:	83 3c 83 00          	cmpl   $0x0,(%ebx,%eax,4)
f0102aae:	74 24                	je     f0102ad4 <mem_init+0x16aa>
f0102ab0:	c7 44 24 0c b0 48 10 	movl   $0xf01048b0,0xc(%esp)
f0102ab7:	f0 
f0102ab8:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f0102abf:	f0 
f0102ac0:	c7 44 24 04 c0 02 00 	movl   $0x2c0,0x4(%esp)
f0102ac7:	00 
f0102ac8:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f0102acf:	e8 c0 d5 ff ff       	call   f0100094 <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0102ad4:	83 c0 01             	add    $0x1,%eax
f0102ad7:	3d 00 04 00 00       	cmp    $0x400,%eax
f0102adc:	0f 85 28 ff ff ff    	jne    f0102a0a <mem_init+0x15e0>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f0102ae2:	c7 04 24 1c 4f 10 f0 	movl   $0xf0104f1c,(%esp)
f0102ae9:	e8 90 04 00 00       	call   f0102f7e <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f0102aee:	a1 88 89 11 f0       	mov    0xf0118988,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102af3:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102af8:	77 20                	ja     f0102b1a <mem_init+0x16f0>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102afa:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102afe:	c7 44 24 08 a8 49 10 	movl   $0xf01049a8,0x8(%esp)
f0102b05:	f0 
f0102b06:	c7 44 24 04 d2 00 00 	movl   $0xd2,0x4(%esp)
f0102b0d:	00 
f0102b0e:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f0102b15:	e8 7a d5 ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0102b1a:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0102b1f:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f0102b22:	b8 00 00 00 00       	mov    $0x0,%eax
f0102b27:	e8 ad e1 ff ff       	call   f0100cd9 <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f0102b2c:	0f 20 c0             	mov    %cr0,%eax

	// entry.S set the really important flags in cr0 (including enabling
	// paging).  Here we configure the rest of the flags that we care about.
	cr0 = rcr0();
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_MP;
f0102b2f:	0d 23 00 05 80       	or     $0x80050023,%eax
	cr0 &= ~(CR0_TS|CR0_EM);
f0102b34:	83 e0 f3             	and    $0xfffffff3,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f0102b37:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102b3a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102b41:	e8 af e5 ff ff       	call   f01010f5 <page_alloc>
f0102b46:	89 c6                	mov    %eax,%esi
f0102b48:	85 c0                	test   %eax,%eax
f0102b4a:	75 24                	jne    f0102b70 <mem_init+0x1746>
f0102b4c:	c7 44 24 0c c9 46 10 	movl   $0xf01046c9,0xc(%esp)
f0102b53:	f0 
f0102b54:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f0102b5b:	f0 
f0102b5c:	c7 44 24 04 81 03 00 	movl   $0x381,0x4(%esp)
f0102b63:	00 
f0102b64:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f0102b6b:	e8 24 d5 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f0102b70:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102b77:	e8 79 e5 ff ff       	call   f01010f5 <page_alloc>
f0102b7c:	89 c7                	mov    %eax,%edi
f0102b7e:	85 c0                	test   %eax,%eax
f0102b80:	75 24                	jne    f0102ba6 <mem_init+0x177c>
f0102b82:	c7 44 24 0c df 46 10 	movl   $0xf01046df,0xc(%esp)
f0102b89:	f0 
f0102b8a:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f0102b91:	f0 
f0102b92:	c7 44 24 04 82 03 00 	movl   $0x382,0x4(%esp)
f0102b99:	00 
f0102b9a:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f0102ba1:	e8 ee d4 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0102ba6:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102bad:	e8 43 e5 ff ff       	call   f01010f5 <page_alloc>
f0102bb2:	89 c3                	mov    %eax,%ebx
f0102bb4:	85 c0                	test   %eax,%eax
f0102bb6:	75 24                	jne    f0102bdc <mem_init+0x17b2>
f0102bb8:	c7 44 24 0c f5 46 10 	movl   $0xf01046f5,0xc(%esp)
f0102bbf:	f0 
f0102bc0:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f0102bc7:	f0 
f0102bc8:	c7 44 24 04 83 03 00 	movl   $0x383,0x4(%esp)
f0102bcf:	00 
f0102bd0:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f0102bd7:	e8 b8 d4 ff ff       	call   f0100094 <_panic>
	page_free(pp0);
f0102bdc:	89 34 24             	mov    %esi,(%esp)
f0102bdf:	e8 92 e5 ff ff       	call   f0101176 <page_free>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102be4:	89 f8                	mov    %edi,%eax
f0102be6:	2b 05 8c 89 11 f0    	sub    0xf011898c,%eax
f0102bec:	c1 f8 03             	sar    $0x3,%eax
f0102bef:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102bf2:	89 c2                	mov    %eax,%edx
f0102bf4:	c1 ea 0c             	shr    $0xc,%edx
f0102bf7:	3b 15 84 89 11 f0    	cmp    0xf0118984,%edx
f0102bfd:	72 20                	jb     f0102c1f <mem_init+0x17f5>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102bff:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102c03:	c7 44 24 08 c0 48 10 	movl   $0xf01048c0,0x8(%esp)
f0102c0a:	f0 
f0102c0b:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0102c12:	00 
f0102c13:	c7 04 24 fc 45 10 f0 	movl   $0xf01045fc,(%esp)
f0102c1a:	e8 75 d4 ff ff       	call   f0100094 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f0102c1f:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102c26:	00 
f0102c27:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0102c2e:	00 
	return (void *)(pa + KERNBASE);
f0102c2f:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102c34:	89 04 24             	mov    %eax,(%esp)
f0102c37:	e8 05 0f 00 00       	call   f0103b41 <memset>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102c3c:	89 d8                	mov    %ebx,%eax
f0102c3e:	2b 05 8c 89 11 f0    	sub    0xf011898c,%eax
f0102c44:	c1 f8 03             	sar    $0x3,%eax
f0102c47:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102c4a:	89 c2                	mov    %eax,%edx
f0102c4c:	c1 ea 0c             	shr    $0xc,%edx
f0102c4f:	3b 15 84 89 11 f0    	cmp    0xf0118984,%edx
f0102c55:	72 20                	jb     f0102c77 <mem_init+0x184d>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102c57:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102c5b:	c7 44 24 08 c0 48 10 	movl   $0xf01048c0,0x8(%esp)
f0102c62:	f0 
f0102c63:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0102c6a:	00 
f0102c6b:	c7 04 24 fc 45 10 f0 	movl   $0xf01045fc,(%esp)
f0102c72:	e8 1d d4 ff ff       	call   f0100094 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f0102c77:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102c7e:	00 
f0102c7f:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f0102c86:	00 
	return (void *)(pa + KERNBASE);
f0102c87:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102c8c:	89 04 24             	mov    %eax,(%esp)
f0102c8f:	e8 ad 0e 00 00       	call   f0103b41 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102c94:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102c9b:	00 
f0102c9c:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102ca3:	00 
f0102ca4:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0102ca8:	a1 88 89 11 f0       	mov    0xf0118988,%eax
f0102cad:	89 04 24             	mov    %eax,(%esp)
f0102cb0:	e8 93 e6 ff ff       	call   f0101348 <page_insert>
	assert(pp1->pp_ref == 1);
f0102cb5:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102cba:	74 24                	je     f0102ce0 <mem_init+0x18b6>
f0102cbc:	c7 44 24 0c c6 47 10 	movl   $0xf01047c6,0xc(%esp)
f0102cc3:	f0 
f0102cc4:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f0102ccb:	f0 
f0102ccc:	c7 44 24 04 88 03 00 	movl   $0x388,0x4(%esp)
f0102cd3:	00 
f0102cd4:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f0102cdb:	e8 b4 d3 ff ff       	call   f0100094 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102ce0:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102ce7:	01 01 01 
f0102cea:	74 24                	je     f0102d10 <mem_init+0x18e6>
f0102cec:	c7 44 24 0c 3c 4f 10 	movl   $0xf0104f3c,0xc(%esp)
f0102cf3:	f0 
f0102cf4:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f0102cfb:	f0 
f0102cfc:	c7 44 24 04 89 03 00 	movl   $0x389,0x4(%esp)
f0102d03:	00 
f0102d04:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f0102d0b:	e8 84 d3 ff ff       	call   f0100094 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102d10:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102d17:	00 
f0102d18:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102d1f:	00 
f0102d20:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102d24:	a1 88 89 11 f0       	mov    0xf0118988,%eax
f0102d29:	89 04 24             	mov    %eax,(%esp)
f0102d2c:	e8 17 e6 ff ff       	call   f0101348 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102d31:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102d38:	02 02 02 
f0102d3b:	74 24                	je     f0102d61 <mem_init+0x1937>
f0102d3d:	c7 44 24 0c 60 4f 10 	movl   $0xf0104f60,0xc(%esp)
f0102d44:	f0 
f0102d45:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f0102d4c:	f0 
f0102d4d:	c7 44 24 04 8b 03 00 	movl   $0x38b,0x4(%esp)
f0102d54:	00 
f0102d55:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f0102d5c:	e8 33 d3 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0102d61:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102d66:	74 24                	je     f0102d8c <mem_init+0x1962>
f0102d68:	c7 44 24 0c e8 47 10 	movl   $0xf01047e8,0xc(%esp)
f0102d6f:	f0 
f0102d70:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f0102d77:	f0 
f0102d78:	c7 44 24 04 8c 03 00 	movl   $0x38c,0x4(%esp)
f0102d7f:	00 
f0102d80:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f0102d87:	e8 08 d3 ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 0);
f0102d8c:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102d91:	74 24                	je     f0102db7 <mem_init+0x198d>
f0102d93:	c7 44 24 0c 35 48 10 	movl   $0xf0104835,0xc(%esp)
f0102d9a:	f0 
f0102d9b:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f0102da2:	f0 
f0102da3:	c7 44 24 04 8d 03 00 	movl   $0x38d,0x4(%esp)
f0102daa:	00 
f0102dab:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f0102db2:	e8 dd d2 ff ff       	call   f0100094 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102db7:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102dbe:	03 03 03 
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102dc1:	89 d8                	mov    %ebx,%eax
f0102dc3:	2b 05 8c 89 11 f0    	sub    0xf011898c,%eax
f0102dc9:	c1 f8 03             	sar    $0x3,%eax
f0102dcc:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102dcf:	89 c2                	mov    %eax,%edx
f0102dd1:	c1 ea 0c             	shr    $0xc,%edx
f0102dd4:	3b 15 84 89 11 f0    	cmp    0xf0118984,%edx
f0102dda:	72 20                	jb     f0102dfc <mem_init+0x19d2>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102ddc:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102de0:	c7 44 24 08 c0 48 10 	movl   $0xf01048c0,0x8(%esp)
f0102de7:	f0 
f0102de8:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0102def:	00 
f0102df0:	c7 04 24 fc 45 10 f0 	movl   $0xf01045fc,(%esp)
f0102df7:	e8 98 d2 ff ff       	call   f0100094 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102dfc:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102e03:	03 03 03 
f0102e06:	74 24                	je     f0102e2c <mem_init+0x1a02>
f0102e08:	c7 44 24 0c 84 4f 10 	movl   $0xf0104f84,0xc(%esp)
f0102e0f:	f0 
f0102e10:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f0102e17:	f0 
f0102e18:	c7 44 24 04 8f 03 00 	movl   $0x38f,0x4(%esp)
f0102e1f:	00 
f0102e20:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f0102e27:	e8 68 d2 ff ff       	call   f0100094 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102e2c:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102e33:	00 
f0102e34:	a1 88 89 11 f0       	mov    0xf0118988,%eax
f0102e39:	89 04 24             	mov    %eax,(%esp)
f0102e3c:	e8 c9 e4 ff ff       	call   f010130a <page_remove>
	assert(pp2->pp_ref == 0);
f0102e41:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102e46:	74 24                	je     f0102e6c <mem_init+0x1a42>
f0102e48:	c7 44 24 0c 20 48 10 	movl   $0xf0104820,0xc(%esp)
f0102e4f:	f0 
f0102e50:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f0102e57:	f0 
f0102e58:	c7 44 24 04 91 03 00 	movl   $0x391,0x4(%esp)
f0102e5f:	00 
f0102e60:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f0102e67:	e8 28 d2 ff ff       	call   f0100094 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102e6c:	a1 88 89 11 f0       	mov    0xf0118988,%eax
f0102e71:	8b 08                	mov    (%eax),%ecx
f0102e73:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102e79:	89 f2                	mov    %esi,%edx
f0102e7b:	2b 15 8c 89 11 f0    	sub    0xf011898c,%edx
f0102e81:	c1 fa 03             	sar    $0x3,%edx
f0102e84:	c1 e2 0c             	shl    $0xc,%edx
f0102e87:	39 d1                	cmp    %edx,%ecx
f0102e89:	74 24                	je     f0102eaf <mem_init+0x1a85>
f0102e8b:	c7 44 24 0c 00 4b 10 	movl   $0xf0104b00,0xc(%esp)
f0102e92:	f0 
f0102e93:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f0102e9a:	f0 
f0102e9b:	c7 44 24 04 94 03 00 	movl   $0x394,0x4(%esp)
f0102ea2:	00 
f0102ea3:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f0102eaa:	e8 e5 d1 ff ff       	call   f0100094 <_panic>
	kern_pgdir[0] = 0;
f0102eaf:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f0102eb5:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102eba:	74 24                	je     f0102ee0 <mem_init+0x1ab6>
f0102ebc:	c7 44 24 0c d7 47 10 	movl   $0xf01047d7,0xc(%esp)
f0102ec3:	f0 
f0102ec4:	c7 44 24 08 16 46 10 	movl   $0xf0104616,0x8(%esp)
f0102ecb:	f0 
f0102ecc:	c7 44 24 04 96 03 00 	movl   $0x396,0x4(%esp)
f0102ed3:	00 
f0102ed4:	c7 04 24 f0 45 10 f0 	movl   $0xf01045f0,(%esp)
f0102edb:	e8 b4 d1 ff ff       	call   f0100094 <_panic>
	pp0->pp_ref = 0;
f0102ee0:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// free the pages we took
	page_free(pp0);
f0102ee6:	89 34 24             	mov    %esi,(%esp)
f0102ee9:	e8 88 e2 ff ff       	call   f0101176 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102eee:	c7 04 24 b0 4f 10 f0 	movl   $0xf0104fb0,(%esp)
f0102ef5:	e8 84 00 00 00       	call   f0102f7e <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0102efa:	83 c4 3c             	add    $0x3c,%esp
f0102efd:	5b                   	pop    %ebx
f0102efe:	5e                   	pop    %esi
f0102eff:	5f                   	pop    %edi
f0102f00:	5d                   	pop    %ebp
f0102f01:	c3                   	ret    

f0102f02 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0102f02:	55                   	push   %ebp
f0102f03:	89 e5                	mov    %esp,%ebp
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0102f05:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102f08:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f0102f0b:	5d                   	pop    %ebp
f0102f0c:	c3                   	ret    
f0102f0d:	00 00                	add    %al,(%eax)
	...

f0102f10 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102f10:	55                   	push   %ebp
f0102f11:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102f13:	ba 70 00 00 00       	mov    $0x70,%edx
f0102f18:	8b 45 08             	mov    0x8(%ebp),%eax
f0102f1b:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102f1c:	b2 71                	mov    $0x71,%dl
f0102f1e:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0102f1f:	0f b6 c0             	movzbl %al,%eax
}
f0102f22:	5d                   	pop    %ebp
f0102f23:	c3                   	ret    

f0102f24 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102f24:	55                   	push   %ebp
f0102f25:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102f27:	ba 70 00 00 00       	mov    $0x70,%edx
f0102f2c:	8b 45 08             	mov    0x8(%ebp),%eax
f0102f2f:	ee                   	out    %al,(%dx)
f0102f30:	b2 71                	mov    $0x71,%dl
f0102f32:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102f35:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0102f36:	5d                   	pop    %ebp
f0102f37:	c3                   	ret    

f0102f38 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0102f38:	55                   	push   %ebp
f0102f39:	89 e5                	mov    %esp,%ebp
f0102f3b:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f0102f3e:	8b 45 08             	mov    0x8(%ebp),%eax
f0102f41:	89 04 24             	mov    %eax,(%esp)
f0102f44:	e8 b0 d6 ff ff       	call   f01005f9 <cputchar>
	*cnt++;
}
f0102f49:	c9                   	leave  
f0102f4a:	c3                   	ret    

f0102f4b <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0102f4b:	55                   	push   %ebp
f0102f4c:	89 e5                	mov    %esp,%ebp
f0102f4e:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f0102f51:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0102f58:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102f5b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102f5f:	8b 45 08             	mov    0x8(%ebp),%eax
f0102f62:	89 44 24 08          	mov    %eax,0x8(%esp)
f0102f66:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0102f69:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102f6d:	c7 04 24 38 2f 10 f0 	movl   $0xf0102f38,(%esp)
f0102f74:	e8 c1 04 00 00       	call   f010343a <vprintfmt>
	return cnt;
}
f0102f79:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0102f7c:	c9                   	leave  
f0102f7d:	c3                   	ret    

f0102f7e <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0102f7e:	55                   	push   %ebp
f0102f7f:	89 e5                	mov    %esp,%ebp
f0102f81:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0102f84:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0102f87:	89 44 24 04          	mov    %eax,0x4(%esp)
f0102f8b:	8b 45 08             	mov    0x8(%ebp),%eax
f0102f8e:	89 04 24             	mov    %eax,(%esp)
f0102f91:	e8 b5 ff ff ff       	call   f0102f4b <vcprintf>
	va_end(ap);

	return cnt;
}
f0102f96:	c9                   	leave  
f0102f97:	c3                   	ret    

f0102f98 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0102f98:	55                   	push   %ebp
f0102f99:	89 e5                	mov    %esp,%ebp
f0102f9b:	57                   	push   %edi
f0102f9c:	56                   	push   %esi
f0102f9d:	53                   	push   %ebx
f0102f9e:	83 ec 10             	sub    $0x10,%esp
f0102fa1:	89 c3                	mov    %eax,%ebx
f0102fa3:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0102fa6:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0102fa9:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f0102fac:	8b 0a                	mov    (%edx),%ecx
f0102fae:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0102fb1:	8b 00                	mov    (%eax),%eax
f0102fb3:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0102fb6:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)

	while (l <= r) {
f0102fbd:	eb 77                	jmp    f0103036 <stab_binsearch+0x9e>
		int true_m = (l + r) / 2, m = true_m;
f0102fbf:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0102fc2:	01 c8                	add    %ecx,%eax
f0102fc4:	bf 02 00 00 00       	mov    $0x2,%edi
f0102fc9:	99                   	cltd   
f0102fca:	f7 ff                	idiv   %edi
f0102fcc:	89 c2                	mov    %eax,%edx

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102fce:	eb 01                	jmp    f0102fd1 <stab_binsearch+0x39>
			m--;
f0102fd0:	4a                   	dec    %edx

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102fd1:	39 ca                	cmp    %ecx,%edx
f0102fd3:	7c 1d                	jl     f0102ff2 <stab_binsearch+0x5a>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0102fd5:	6b fa 0c             	imul   $0xc,%edx,%edi

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0102fd8:	0f b6 7c 3b 04       	movzbl 0x4(%ebx,%edi,1),%edi
f0102fdd:	39 f7                	cmp    %esi,%edi
f0102fdf:	75 ef                	jne    f0102fd0 <stab_binsearch+0x38>
f0102fe1:	89 55 ec             	mov    %edx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0102fe4:	6b fa 0c             	imul   $0xc,%edx,%edi
f0102fe7:	8b 7c 3b 08          	mov    0x8(%ebx,%edi,1),%edi
f0102feb:	3b 7d 0c             	cmp    0xc(%ebp),%edi
f0102fee:	73 18                	jae    f0103008 <stab_binsearch+0x70>
f0102ff0:	eb 05                	jmp    f0102ff7 <stab_binsearch+0x5f>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0102ff2:	8d 48 01             	lea    0x1(%eax),%ecx
			continue;
f0102ff5:	eb 3f                	jmp    f0103036 <stab_binsearch+0x9e>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0102ff7:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0102ffa:	89 11                	mov    %edx,(%ecx)
			l = true_m + 1;
f0102ffc:	8d 48 01             	lea    0x1(%eax),%ecx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0102fff:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0103006:	eb 2e                	jmp    f0103036 <stab_binsearch+0x9e>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0103008:	3b 7d 0c             	cmp    0xc(%ebp),%edi
f010300b:	76 15                	jbe    f0103022 <stab_binsearch+0x8a>
			*region_right = m - 1;
f010300d:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0103010:	4f                   	dec    %edi
f0103011:	89 7d f0             	mov    %edi,-0x10(%ebp)
f0103014:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103017:	89 38                	mov    %edi,(%eax)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0103019:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0103020:	eb 14                	jmp    f0103036 <stab_binsearch+0x9e>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0103022:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0103025:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0103028:	89 39                	mov    %edi,(%ecx)
			l = m;
			addr++;
f010302a:	ff 45 0c             	incl   0xc(%ebp)
f010302d:	89 d1                	mov    %edx,%ecx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f010302f:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0103036:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
f0103039:	7e 84                	jle    f0102fbf <stab_binsearch+0x27>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f010303b:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f010303f:	75 0d                	jne    f010304e <stab_binsearch+0xb6>
		*region_right = *region_left - 1;
f0103041:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0103044:	8b 02                	mov    (%edx),%eax
f0103046:	48                   	dec    %eax
f0103047:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f010304a:	89 01                	mov    %eax,(%ecx)
f010304c:	eb 22                	jmp    f0103070 <stab_binsearch+0xd8>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010304e:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0103051:	8b 01                	mov    (%ecx),%eax
		     l > *region_left && stabs[l].n_type != type;
f0103053:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0103056:	8b 0a                	mov    (%edx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103058:	eb 01                	jmp    f010305b <stab_binsearch+0xc3>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f010305a:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010305b:	39 c1                	cmp    %eax,%ecx
f010305d:	7d 0c                	jge    f010306b <stab_binsearch+0xd3>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f010305f:	6b d0 0c             	imul   $0xc,%eax,%edx
	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
		     l > *region_left && stabs[l].n_type != type;
f0103062:	0f b6 54 13 04       	movzbl 0x4(%ebx,%edx,1),%edx
f0103067:	39 f2                	cmp    %esi,%edx
f0103069:	75 ef                	jne    f010305a <stab_binsearch+0xc2>
		     l--)
			/* do nothing */;
		*region_left = l;
f010306b:	8b 55 e8             	mov    -0x18(%ebp),%edx
f010306e:	89 02                	mov    %eax,(%edx)
	}
}
f0103070:	83 c4 10             	add    $0x10,%esp
f0103073:	5b                   	pop    %ebx
f0103074:	5e                   	pop    %esi
f0103075:	5f                   	pop    %edi
f0103076:	5d                   	pop    %ebp
f0103077:	c3                   	ret    

f0103078 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0103078:	55                   	push   %ebp
f0103079:	89 e5                	mov    %esp,%ebp
f010307b:	83 ec 58             	sub    $0x58,%esp
f010307e:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0103081:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0103084:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0103087:	8b 75 08             	mov    0x8(%ebp),%esi
f010308a:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f010308d:	c7 03 dc 4f 10 f0    	movl   $0xf0104fdc,(%ebx)
	info->eip_line = 0;
f0103093:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f010309a:	c7 43 08 dc 4f 10 f0 	movl   $0xf0104fdc,0x8(%ebx)
	info->eip_fn_namelen = 9;
f01030a1:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f01030a8:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f01030ab:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f01030b2:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f01030b8:	76 12                	jbe    f01030cc <debuginfo_eip+0x54>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01030ba:	b8 69 d4 10 f0       	mov    $0xf010d469,%eax
f01030bf:	3d f5 b5 10 f0       	cmp    $0xf010b5f5,%eax
f01030c4:	0f 86 f1 01 00 00    	jbe    f01032bb <debuginfo_eip+0x243>
f01030ca:	eb 1c                	jmp    f01030e8 <debuginfo_eip+0x70>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f01030cc:	c7 44 24 08 e6 4f 10 	movl   $0xf0104fe6,0x8(%esp)
f01030d3:	f0 
f01030d4:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f01030db:	00 
f01030dc:	c7 04 24 f3 4f 10 f0 	movl   $0xf0104ff3,(%esp)
f01030e3:	e8 ac cf ff ff       	call   f0100094 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f01030e8:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01030ed:	80 3d 68 d4 10 f0 00 	cmpb   $0x0,0xf010d468
f01030f4:	0f 85 cd 01 00 00    	jne    f01032c7 <debuginfo_eip+0x24f>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f01030fa:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0103101:	b8 f4 b5 10 f0       	mov    $0xf010b5f4,%eax
f0103106:	2d 10 52 10 f0       	sub    $0xf0105210,%eax
f010310b:	c1 f8 02             	sar    $0x2,%eax
f010310e:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0103114:	83 e8 01             	sub    $0x1,%eax
f0103117:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f010311a:	89 74 24 04          	mov    %esi,0x4(%esp)
f010311e:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0103125:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0103128:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f010312b:	b8 10 52 10 f0       	mov    $0xf0105210,%eax
f0103130:	e8 63 fe ff ff       	call   f0102f98 <stab_binsearch>
	if (lfile == 0)
f0103135:	8b 55 e4             	mov    -0x1c(%ebp),%edx
		return -1;
f0103138:	b8 ff ff ff ff       	mov    $0xffffffff,%eax

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
f010313d:	85 d2                	test   %edx,%edx
f010313f:	0f 84 82 01 00 00    	je     f01032c7 <debuginfo_eip+0x24f>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0103145:	89 55 dc             	mov    %edx,-0x24(%ebp)
	rfun = rfile;
f0103148:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010314b:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f010314e:	89 74 24 04          	mov    %esi,0x4(%esp)
f0103152:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0103159:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f010315c:	8d 55 dc             	lea    -0x24(%ebp),%edx
f010315f:	b8 10 52 10 f0       	mov    $0xf0105210,%eax
f0103164:	e8 2f fe ff ff       	call   f0102f98 <stab_binsearch>

	if (lfun <= rfun) {
f0103169:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010316c:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010316f:	39 d0                	cmp    %edx,%eax
f0103171:	7f 3d                	jg     f01031b0 <debuginfo_eip+0x138>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0103173:	6b c8 0c             	imul   $0xc,%eax,%ecx
f0103176:	8d b9 10 52 10 f0    	lea    -0xfefadf0(%ecx),%edi
f010317c:	89 7d c0             	mov    %edi,-0x40(%ebp)
f010317f:	8b 89 10 52 10 f0    	mov    -0xfefadf0(%ecx),%ecx
f0103185:	bf 69 d4 10 f0       	mov    $0xf010d469,%edi
f010318a:	81 ef f5 b5 10 f0    	sub    $0xf010b5f5,%edi
f0103190:	39 f9                	cmp    %edi,%ecx
f0103192:	73 09                	jae    f010319d <debuginfo_eip+0x125>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0103194:	81 c1 f5 b5 10 f0    	add    $0xf010b5f5,%ecx
f010319a:	89 4b 08             	mov    %ecx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f010319d:	8b 7d c0             	mov    -0x40(%ebp),%edi
f01031a0:	8b 4f 08             	mov    0x8(%edi),%ecx
f01031a3:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f01031a6:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f01031a8:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f01031ab:	89 55 d0             	mov    %edx,-0x30(%ebp)
f01031ae:	eb 0f                	jmp    f01031bf <debuginfo_eip+0x147>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f01031b0:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f01031b3:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01031b6:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f01031b9:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01031bc:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f01031bf:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f01031c6:	00 
f01031c7:	8b 43 08             	mov    0x8(%ebx),%eax
f01031ca:	89 04 24             	mov    %eax,(%esp)
f01031cd:	e8 48 09 00 00       	call   f0103b1a <strfind>
f01031d2:	2b 43 08             	sub    0x8(%ebx),%eax
f01031d5:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f01031d8:	89 74 24 04          	mov    %esi,0x4(%esp)
f01031dc:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f01031e3:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f01031e6:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f01031e9:	b8 10 52 10 f0       	mov    $0xf0105210,%eax
f01031ee:	e8 a5 fd ff ff       	call   f0102f98 <stab_binsearch>
	if (lline <= rline) {
f01031f3:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01031f6:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f01031f9:	7f 0f                	jg     f010320a <debuginfo_eip+0x192>
		info->eip_line = stabs[lline].n_desc;
f01031fb:	6b c0 0c             	imul   $0xc,%eax,%eax
f01031fe:	0f b7 80 16 52 10 f0 	movzwl -0xfefadea(%eax),%eax
f0103205:	89 43 04             	mov    %eax,0x4(%ebx)
f0103208:	eb 07                	jmp    f0103211 <debuginfo_eip+0x199>
	} else {
		info->eip_line = -1;
f010320a:	c7 43 04 ff ff ff ff 	movl   $0xffffffff,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0103211:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0103214:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0103217:	39 c8                	cmp    %ecx,%eax
f0103219:	7c 5f                	jl     f010327a <debuginfo_eip+0x202>
	       && stabs[lline].n_type != N_SOL
f010321b:	89 c2                	mov    %eax,%edx
f010321d:	6b f0 0c             	imul   $0xc,%eax,%esi
f0103220:	80 be 14 52 10 f0 84 	cmpb   $0x84,-0xfefadec(%esi)
f0103227:	75 18                	jne    f0103241 <debuginfo_eip+0x1c9>
f0103229:	eb 30                	jmp    f010325b <debuginfo_eip+0x1e3>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f010322b:	83 e8 01             	sub    $0x1,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f010322e:	39 c1                	cmp    %eax,%ecx
f0103230:	7f 48                	jg     f010327a <debuginfo_eip+0x202>
	       && stabs[lline].n_type != N_SOL
f0103232:	89 c2                	mov    %eax,%edx
f0103234:	8d 34 40             	lea    (%eax,%eax,2),%esi
f0103237:	80 3c b5 14 52 10 f0 	cmpb   $0x84,-0xfefadec(,%esi,4)
f010323e:	84 
f010323f:	74 1a                	je     f010325b <debuginfo_eip+0x1e3>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0103241:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0103244:	8d 14 95 10 52 10 f0 	lea    -0xfefadf0(,%edx,4),%edx
f010324b:	80 7a 04 64          	cmpb   $0x64,0x4(%edx)
f010324f:	75 da                	jne    f010322b <debuginfo_eip+0x1b3>
f0103251:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f0103255:	74 d4                	je     f010322b <debuginfo_eip+0x1b3>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0103257:	39 c8                	cmp    %ecx,%eax
f0103259:	7c 1f                	jl     f010327a <debuginfo_eip+0x202>
f010325b:	6b c0 0c             	imul   $0xc,%eax,%eax
f010325e:	8b 80 10 52 10 f0    	mov    -0xfefadf0(%eax),%eax
f0103264:	ba 69 d4 10 f0       	mov    $0xf010d469,%edx
f0103269:	81 ea f5 b5 10 f0    	sub    $0xf010b5f5,%edx
f010326f:	39 d0                	cmp    %edx,%eax
f0103271:	73 07                	jae    f010327a <debuginfo_eip+0x202>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0103273:	05 f5 b5 10 f0       	add    $0xf010b5f5,%eax
f0103278:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f010327a:	8b 55 dc             	mov    -0x24(%ebp),%edx
f010327d:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103280:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103285:	39 ca                	cmp    %ecx,%edx
f0103287:	7d 3e                	jge    f01032c7 <debuginfo_eip+0x24f>
		for (lline = lfun + 1;
f0103289:	83 c2 01             	add    $0x1,%edx
f010328c:	39 d1                	cmp    %edx,%ecx
f010328e:	7e 37                	jle    f01032c7 <debuginfo_eip+0x24f>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0103290:	6b f2 0c             	imul   $0xc,%edx,%esi
f0103293:	80 be 14 52 10 f0 a0 	cmpb   $0xa0,-0xfefadec(%esi)
f010329a:	75 2b                	jne    f01032c7 <debuginfo_eip+0x24f>
		     lline++)
			info->eip_fn_narg++;
f010329c:	83 43 14 01          	addl   $0x1,0x14(%ebx)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f01032a0:	83 c2 01             	add    $0x1,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f01032a3:	39 d1                	cmp    %edx,%ecx
f01032a5:	7e 1b                	jle    f01032c2 <debuginfo_eip+0x24a>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f01032a7:	8d 04 52             	lea    (%edx,%edx,2),%eax
f01032aa:	80 3c 85 14 52 10 f0 	cmpb   $0xa0,-0xfefadec(,%eax,4)
f01032b1:	a0 
f01032b2:	74 e8                	je     f010329c <debuginfo_eip+0x224>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01032b4:	b8 00 00 00 00       	mov    $0x0,%eax
f01032b9:	eb 0c                	jmp    f01032c7 <debuginfo_eip+0x24f>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f01032bb:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01032c0:	eb 05                	jmp    f01032c7 <debuginfo_eip+0x24f>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01032c2:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01032c7:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f01032ca:	8b 75 f8             	mov    -0x8(%ebp),%esi
f01032cd:	8b 7d fc             	mov    -0x4(%ebp),%edi
f01032d0:	89 ec                	mov    %ebp,%esp
f01032d2:	5d                   	pop    %ebp
f01032d3:	c3                   	ret    
	...

f01032e0 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f01032e0:	55                   	push   %ebp
f01032e1:	89 e5                	mov    %esp,%ebp
f01032e3:	57                   	push   %edi
f01032e4:	56                   	push   %esi
f01032e5:	53                   	push   %ebx
f01032e6:	83 ec 3c             	sub    $0x3c,%esp
f01032e9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01032ec:	89 d7                	mov    %edx,%edi
f01032ee:	8b 45 08             	mov    0x8(%ebp),%eax
f01032f1:	89 45 dc             	mov    %eax,-0x24(%ebp)
f01032f4:	8b 45 0c             	mov    0xc(%ebp),%eax
f01032f7:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01032fa:	8b 5d 14             	mov    0x14(%ebp),%ebx
f01032fd:	8b 75 18             	mov    0x18(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0103300:	b8 00 00 00 00       	mov    $0x0,%eax
f0103305:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0103308:	72 11                	jb     f010331b <printnum+0x3b>
f010330a:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010330d:	39 45 10             	cmp    %eax,0x10(%ebp)
f0103310:	76 09                	jbe    f010331b <printnum+0x3b>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0103312:	83 eb 01             	sub    $0x1,%ebx
f0103315:	85 db                	test   %ebx,%ebx
f0103317:	7f 51                	jg     f010336a <printnum+0x8a>
f0103319:	eb 5e                	jmp    f0103379 <printnum+0x99>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
f010331b:	89 74 24 10          	mov    %esi,0x10(%esp)
f010331f:	83 eb 01             	sub    $0x1,%ebx
f0103322:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0103326:	8b 45 10             	mov    0x10(%ebp),%eax
f0103329:	89 44 24 08          	mov    %eax,0x8(%esp)
f010332d:	8b 5c 24 08          	mov    0x8(%esp),%ebx
f0103331:	8b 74 24 0c          	mov    0xc(%esp),%esi
f0103335:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f010333c:	00 
f010333d:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103340:	89 04 24             	mov    %eax,(%esp)
f0103343:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103346:	89 44 24 04          	mov    %eax,0x4(%esp)
f010334a:	e8 41 0a 00 00       	call   f0103d90 <__udivdi3>
f010334f:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0103353:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0103357:	89 04 24             	mov    %eax,(%esp)
f010335a:	89 54 24 04          	mov    %edx,0x4(%esp)
f010335e:	89 fa                	mov    %edi,%edx
f0103360:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103363:	e8 78 ff ff ff       	call   f01032e0 <printnum>
f0103368:	eb 0f                	jmp    f0103379 <printnum+0x99>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f010336a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010336e:	89 34 24             	mov    %esi,(%esp)
f0103371:	ff 55 e4             	call   *-0x1c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0103374:	83 eb 01             	sub    $0x1,%ebx
f0103377:	75 f1                	jne    f010336a <printnum+0x8a>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0103379:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010337d:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0103381:	8b 45 10             	mov    0x10(%ebp),%eax
f0103384:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103388:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f010338f:	00 
f0103390:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103393:	89 04 24             	mov    %eax,(%esp)
f0103396:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103399:	89 44 24 04          	mov    %eax,0x4(%esp)
f010339d:	e8 1e 0b 00 00       	call   f0103ec0 <__umoddi3>
f01033a2:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01033a6:	0f be 80 01 50 10 f0 	movsbl -0xfefafff(%eax),%eax
f01033ad:	89 04 24             	mov    %eax,(%esp)
f01033b0:	ff 55 e4             	call   *-0x1c(%ebp)
}
f01033b3:	83 c4 3c             	add    $0x3c,%esp
f01033b6:	5b                   	pop    %ebx
f01033b7:	5e                   	pop    %esi
f01033b8:	5f                   	pop    %edi
f01033b9:	5d                   	pop    %ebp
f01033ba:	c3                   	ret    

f01033bb <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f01033bb:	55                   	push   %ebp
f01033bc:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f01033be:	83 fa 01             	cmp    $0x1,%edx
f01033c1:	7e 0e                	jle    f01033d1 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f01033c3:	8b 10                	mov    (%eax),%edx
f01033c5:	8d 4a 08             	lea    0x8(%edx),%ecx
f01033c8:	89 08                	mov    %ecx,(%eax)
f01033ca:	8b 02                	mov    (%edx),%eax
f01033cc:	8b 52 04             	mov    0x4(%edx),%edx
f01033cf:	eb 22                	jmp    f01033f3 <getuint+0x38>
	else if (lflag)
f01033d1:	85 d2                	test   %edx,%edx
f01033d3:	74 10                	je     f01033e5 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f01033d5:	8b 10                	mov    (%eax),%edx
f01033d7:	8d 4a 04             	lea    0x4(%edx),%ecx
f01033da:	89 08                	mov    %ecx,(%eax)
f01033dc:	8b 02                	mov    (%edx),%eax
f01033de:	ba 00 00 00 00       	mov    $0x0,%edx
f01033e3:	eb 0e                	jmp    f01033f3 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f01033e5:	8b 10                	mov    (%eax),%edx
f01033e7:	8d 4a 04             	lea    0x4(%edx),%ecx
f01033ea:	89 08                	mov    %ecx,(%eax)
f01033ec:	8b 02                	mov    (%edx),%eax
f01033ee:	ba 00 00 00 00       	mov    $0x0,%edx
}
f01033f3:	5d                   	pop    %ebp
f01033f4:	c3                   	ret    

f01033f5 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f01033f5:	55                   	push   %ebp
f01033f6:	89 e5                	mov    %esp,%ebp
f01033f8:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f01033fb:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f01033ff:	8b 10                	mov    (%eax),%edx
f0103401:	3b 50 04             	cmp    0x4(%eax),%edx
f0103404:	73 0a                	jae    f0103410 <sprintputch+0x1b>
		*b->buf++ = ch;
f0103406:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103409:	88 0a                	mov    %cl,(%edx)
f010340b:	83 c2 01             	add    $0x1,%edx
f010340e:	89 10                	mov    %edx,(%eax)
}
f0103410:	5d                   	pop    %ebp
f0103411:	c3                   	ret    

f0103412 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0103412:	55                   	push   %ebp
f0103413:	89 e5                	mov    %esp,%ebp
f0103415:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f0103418:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f010341b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010341f:	8b 45 10             	mov    0x10(%ebp),%eax
f0103422:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103426:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103429:	89 44 24 04          	mov    %eax,0x4(%esp)
f010342d:	8b 45 08             	mov    0x8(%ebp),%eax
f0103430:	89 04 24             	mov    %eax,(%esp)
f0103433:	e8 02 00 00 00       	call   f010343a <vprintfmt>
	va_end(ap);
}
f0103438:	c9                   	leave  
f0103439:	c3                   	ret    

f010343a <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f010343a:	55                   	push   %ebp
f010343b:	89 e5                	mov    %esp,%ebp
f010343d:	57                   	push   %edi
f010343e:	56                   	push   %esi
f010343f:	53                   	push   %ebx
f0103440:	83 ec 4c             	sub    $0x4c,%esp
f0103443:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103446:	8b 75 10             	mov    0x10(%ebp),%esi
f0103449:	eb 12                	jmp    f010345d <vprintfmt+0x23>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f010344b:	85 c0                	test   %eax,%eax
f010344d:	0f 84 a9 03 00 00    	je     f01037fc <vprintfmt+0x3c2>
				return;
			putch(ch, putdat);
f0103453:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103457:	89 04 24             	mov    %eax,(%esp)
f010345a:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f010345d:	0f b6 06             	movzbl (%esi),%eax
f0103460:	83 c6 01             	add    $0x1,%esi
f0103463:	83 f8 25             	cmp    $0x25,%eax
f0103466:	75 e3                	jne    f010344b <vprintfmt+0x11>
f0103468:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
f010346c:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
f0103473:	bf ff ff ff ff       	mov    $0xffffffff,%edi
f0103478:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
f010347f:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103484:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0103487:	eb 2b                	jmp    f01034b4 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103489:	8b 75 e0             	mov    -0x20(%ebp),%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f010348c:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
f0103490:	eb 22                	jmp    f01034b4 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103492:	8b 75 e0             	mov    -0x20(%ebp),%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0103495:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
f0103499:	eb 19                	jmp    f01034b4 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010349b:	8b 75 e0             	mov    -0x20(%ebp),%esi
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
f010349e:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f01034a5:	eb 0d                	jmp    f01034b4 <vprintfmt+0x7a>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f01034a7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01034aa:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01034ad:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01034b4:	0f b6 06             	movzbl (%esi),%eax
f01034b7:	0f b6 d0             	movzbl %al,%edx
f01034ba:	8d 7e 01             	lea    0x1(%esi),%edi
f01034bd:	89 7d e0             	mov    %edi,-0x20(%ebp)
f01034c0:	83 e8 23             	sub    $0x23,%eax
f01034c3:	3c 55                	cmp    $0x55,%al
f01034c5:	0f 87 0b 03 00 00    	ja     f01037d6 <vprintfmt+0x39c>
f01034cb:	0f b6 c0             	movzbl %al,%eax
f01034ce:	ff 24 85 8c 50 10 f0 	jmp    *-0xfefaf74(,%eax,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f01034d5:	83 ea 30             	sub    $0x30,%edx
f01034d8:	89 55 d4             	mov    %edx,-0x2c(%ebp)
				ch = *fmt;
f01034db:	0f be 46 01          	movsbl 0x1(%esi),%eax
				if (ch < '0' || ch > '9')
f01034df:	8d 50 d0             	lea    -0x30(%eax),%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01034e2:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
f01034e5:	83 fa 09             	cmp    $0x9,%edx
f01034e8:	77 4a                	ja     f0103534 <vprintfmt+0xfa>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01034ea:	8b 7d d4             	mov    -0x2c(%ebp),%edi
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f01034ed:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
f01034f0:	8d 14 bf             	lea    (%edi,%edi,4),%edx
f01034f3:	8d 7c 50 d0          	lea    -0x30(%eax,%edx,2),%edi
				ch = *fmt;
f01034f7:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f01034fa:	8d 50 d0             	lea    -0x30(%eax),%edx
f01034fd:	83 fa 09             	cmp    $0x9,%edx
f0103500:	76 eb                	jbe    f01034ed <vprintfmt+0xb3>
f0103502:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0103505:	eb 2d                	jmp    f0103534 <vprintfmt+0xfa>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0103507:	8b 45 14             	mov    0x14(%ebp),%eax
f010350a:	8d 50 04             	lea    0x4(%eax),%edx
f010350d:	89 55 14             	mov    %edx,0x14(%ebp)
f0103510:	8b 00                	mov    (%eax),%eax
f0103512:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103515:	8b 75 e0             	mov    -0x20(%ebp),%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0103518:	eb 1a                	jmp    f0103534 <vprintfmt+0xfa>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010351a:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case '*':
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
f010351d:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0103521:	79 91                	jns    f01034b4 <vprintfmt+0x7a>
f0103523:	e9 73 ff ff ff       	jmp    f010349b <vprintfmt+0x61>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103528:	8b 75 e0             	mov    -0x20(%ebp),%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f010352b:	c7 45 dc 01 00 00 00 	movl   $0x1,-0x24(%ebp)
			goto reswitch;
f0103532:	eb 80                	jmp    f01034b4 <vprintfmt+0x7a>

		process_precision:
			if (width < 0)
f0103534:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0103538:	0f 89 76 ff ff ff    	jns    f01034b4 <vprintfmt+0x7a>
f010353e:	e9 64 ff ff ff       	jmp    f01034a7 <vprintfmt+0x6d>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0103543:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103546:	8b 75 e0             	mov    -0x20(%ebp),%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0103549:	e9 66 ff ff ff       	jmp    f01034b4 <vprintfmt+0x7a>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f010354e:	8b 45 14             	mov    0x14(%ebp),%eax
f0103551:	8d 50 04             	lea    0x4(%eax),%edx
f0103554:	89 55 14             	mov    %edx,0x14(%ebp)
f0103557:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010355b:	8b 00                	mov    (%eax),%eax
f010355d:	89 04 24             	mov    %eax,(%esp)
f0103560:	ff 55 08             	call   *0x8(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103563:	8b 75 e0             	mov    -0x20(%ebp),%esi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0103566:	e9 f2 fe ff ff       	jmp    f010345d <vprintfmt+0x23>

		// error message
		case 'e':
			err = va_arg(ap, int);
f010356b:	8b 45 14             	mov    0x14(%ebp),%eax
f010356e:	8d 50 04             	lea    0x4(%eax),%edx
f0103571:	89 55 14             	mov    %edx,0x14(%ebp)
f0103574:	8b 00                	mov    (%eax),%eax
f0103576:	89 c2                	mov    %eax,%edx
f0103578:	c1 fa 1f             	sar    $0x1f,%edx
f010357b:	31 d0                	xor    %edx,%eax
f010357d:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f010357f:	83 f8 06             	cmp    $0x6,%eax
f0103582:	7f 0b                	jg     f010358f <vprintfmt+0x155>
f0103584:	8b 14 85 e4 51 10 f0 	mov    -0xfefae1c(,%eax,4),%edx
f010358b:	85 d2                	test   %edx,%edx
f010358d:	75 23                	jne    f01035b2 <vprintfmt+0x178>
				printfmt(putch, putdat, "error %d", err);
f010358f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103593:	c7 44 24 08 19 50 10 	movl   $0xf0105019,0x8(%esp)
f010359a:	f0 
f010359b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010359f:	8b 7d 08             	mov    0x8(%ebp),%edi
f01035a2:	89 3c 24             	mov    %edi,(%esp)
f01035a5:	e8 68 fe ff ff       	call   f0103412 <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01035aa:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f01035ad:	e9 ab fe ff ff       	jmp    f010345d <vprintfmt+0x23>
			else
				printfmt(putch, putdat, "%s", p);
f01035b2:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01035b6:	c7 44 24 08 28 46 10 	movl   $0xf0104628,0x8(%esp)
f01035bd:	f0 
f01035be:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01035c2:	8b 7d 08             	mov    0x8(%ebp),%edi
f01035c5:	89 3c 24             	mov    %edi,(%esp)
f01035c8:	e8 45 fe ff ff       	call   f0103412 <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01035cd:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01035d0:	e9 88 fe ff ff       	jmp    f010345d <vprintfmt+0x23>
f01035d5:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01035d8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01035db:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f01035de:	8b 45 14             	mov    0x14(%ebp),%eax
f01035e1:	8d 50 04             	lea    0x4(%eax),%edx
f01035e4:	89 55 14             	mov    %edx,0x14(%ebp)
f01035e7:	8b 30                	mov    (%eax),%esi
				p = "(null)";
f01035e9:	85 f6                	test   %esi,%esi
f01035eb:	ba 12 50 10 f0       	mov    $0xf0105012,%edx
f01035f0:	0f 44 f2             	cmove  %edx,%esi
			if (width > 0 && padc != '-')
f01035f3:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f01035f7:	7e 06                	jle    f01035ff <vprintfmt+0x1c5>
f01035f9:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
f01035fd:	75 10                	jne    f010360f <vprintfmt+0x1d5>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01035ff:	0f be 06             	movsbl (%esi),%eax
f0103602:	83 c6 01             	add    $0x1,%esi
f0103605:	85 c0                	test   %eax,%eax
f0103607:	0f 85 86 00 00 00    	jne    f0103693 <vprintfmt+0x259>
f010360d:	eb 76                	jmp    f0103685 <vprintfmt+0x24b>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010360f:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103613:	89 34 24             	mov    %esi,(%esp)
f0103616:	e8 60 03 00 00       	call   f010397b <strnlen>
f010361b:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f010361e:	29 c2                	sub    %eax,%edx
f0103620:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0103623:	85 d2                	test   %edx,%edx
f0103625:	7e d8                	jle    f01035ff <vprintfmt+0x1c5>
					putch(padc, putdat);
f0103627:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
f010362b:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f010362e:	89 d6                	mov    %edx,%esi
f0103630:	89 7d d0             	mov    %edi,-0x30(%ebp)
f0103633:	89 c7                	mov    %eax,%edi
f0103635:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103639:	89 3c 24             	mov    %edi,(%esp)
f010363c:	ff 55 08             	call   *0x8(%ebp)
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010363f:	83 ee 01             	sub    $0x1,%esi
f0103642:	75 f1                	jne    f0103635 <vprintfmt+0x1fb>
f0103644:	89 75 e4             	mov    %esi,-0x1c(%ebp)
f0103647:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f010364a:	8b 7d d0             	mov    -0x30(%ebp),%edi
f010364d:	eb b0                	jmp    f01035ff <vprintfmt+0x1c5>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f010364f:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0103653:	74 18                	je     f010366d <vprintfmt+0x233>
f0103655:	8d 50 e0             	lea    -0x20(%eax),%edx
f0103658:	83 fa 5e             	cmp    $0x5e,%edx
f010365b:	76 10                	jbe    f010366d <vprintfmt+0x233>
					putch('?', putdat);
f010365d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103661:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0103668:	ff 55 08             	call   *0x8(%ebp)
f010366b:	eb 0a                	jmp    f0103677 <vprintfmt+0x23d>
				else
					putch(ch, putdat);
f010366d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103671:	89 04 24             	mov    %eax,(%esp)
f0103674:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0103677:	83 6d e4 01          	subl   $0x1,-0x1c(%ebp)
f010367b:	0f be 06             	movsbl (%esi),%eax
f010367e:	83 c6 01             	add    $0x1,%esi
f0103681:	85 c0                	test   %eax,%eax
f0103683:	75 0e                	jne    f0103693 <vprintfmt+0x259>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103685:	8b 75 e0             	mov    -0x20(%ebp),%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0103688:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f010368c:	7f 16                	jg     f01036a4 <vprintfmt+0x26a>
f010368e:	e9 ca fd ff ff       	jmp    f010345d <vprintfmt+0x23>
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0103693:	85 ff                	test   %edi,%edi
f0103695:	78 b8                	js     f010364f <vprintfmt+0x215>
f0103697:	83 ef 01             	sub    $0x1,%edi
f010369a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01036a0:	79 ad                	jns    f010364f <vprintfmt+0x215>
f01036a2:	eb e1                	jmp    f0103685 <vprintfmt+0x24b>
f01036a4:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01036a7:	8b 7d 08             	mov    0x8(%ebp),%edi
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f01036aa:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01036ae:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f01036b5:	ff d7                	call   *%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f01036b7:	83 ee 01             	sub    $0x1,%esi
f01036ba:	75 ee                	jne    f01036aa <vprintfmt+0x270>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01036bc:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01036bf:	e9 99 fd ff ff       	jmp    f010345d <vprintfmt+0x23>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f01036c4:	83 f9 01             	cmp    $0x1,%ecx
f01036c7:	7e 10                	jle    f01036d9 <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f01036c9:	8b 45 14             	mov    0x14(%ebp),%eax
f01036cc:	8d 50 08             	lea    0x8(%eax),%edx
f01036cf:	89 55 14             	mov    %edx,0x14(%ebp)
f01036d2:	8b 30                	mov    (%eax),%esi
f01036d4:	8b 78 04             	mov    0x4(%eax),%edi
f01036d7:	eb 26                	jmp    f01036ff <vprintfmt+0x2c5>
	else if (lflag)
f01036d9:	85 c9                	test   %ecx,%ecx
f01036db:	74 12                	je     f01036ef <vprintfmt+0x2b5>
		return va_arg(*ap, long);
f01036dd:	8b 45 14             	mov    0x14(%ebp),%eax
f01036e0:	8d 50 04             	lea    0x4(%eax),%edx
f01036e3:	89 55 14             	mov    %edx,0x14(%ebp)
f01036e6:	8b 30                	mov    (%eax),%esi
f01036e8:	89 f7                	mov    %esi,%edi
f01036ea:	c1 ff 1f             	sar    $0x1f,%edi
f01036ed:	eb 10                	jmp    f01036ff <vprintfmt+0x2c5>
	else
		return va_arg(*ap, int);
f01036ef:	8b 45 14             	mov    0x14(%ebp),%eax
f01036f2:	8d 50 04             	lea    0x4(%eax),%edx
f01036f5:	89 55 14             	mov    %edx,0x14(%ebp)
f01036f8:	8b 30                	mov    (%eax),%esi
f01036fa:	89 f7                	mov    %esi,%edi
f01036fc:	c1 ff 1f             	sar    $0x1f,%edi
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f01036ff:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0103704:	85 ff                	test   %edi,%edi
f0103706:	0f 89 8c 00 00 00    	jns    f0103798 <vprintfmt+0x35e>
				putch('-', putdat);
f010370c:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103710:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f0103717:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f010371a:	f7 de                	neg    %esi
f010371c:	83 d7 00             	adc    $0x0,%edi
f010371f:	f7 df                	neg    %edi
			}
			base = 10;
f0103721:	b8 0a 00 00 00       	mov    $0xa,%eax
f0103726:	eb 70                	jmp    f0103798 <vprintfmt+0x35e>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0103728:	89 ca                	mov    %ecx,%edx
f010372a:	8d 45 14             	lea    0x14(%ebp),%eax
f010372d:	e8 89 fc ff ff       	call   f01033bb <getuint>
f0103732:	89 c6                	mov    %eax,%esi
f0103734:	89 d7                	mov    %edx,%edi
			base = 10;
f0103736:	b8 0a 00 00 00       	mov    $0xa,%eax
			goto number;
f010373b:	eb 5b                	jmp    f0103798 <vprintfmt+0x35e>
			// Replace this with your code.
			//putch('0', putdat);
			//putch('X', putdat);
			//putch('X', putdat);
			//break;
			num = getuint(&ap, lflag);
f010373d:	89 ca                	mov    %ecx,%edx
f010373f:	8d 45 14             	lea    0x14(%ebp),%eax
f0103742:	e8 74 fc ff ff       	call   f01033bb <getuint>
f0103747:	89 c6                	mov    %eax,%esi
f0103749:	89 d7                	mov    %edx,%edi
			base = 8;
f010374b:	b8 08 00 00 00       	mov    $0x8,%eax
			goto number;
f0103750:	eb 46                	jmp    f0103798 <vprintfmt+0x35e>
		// pointer
		case 'p':
			putch('0', putdat);
f0103752:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103756:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f010375d:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f0103760:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103764:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f010376b:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f010376e:	8b 45 14             	mov    0x14(%ebp),%eax
f0103771:	8d 50 04             	lea    0x4(%eax),%edx
f0103774:	89 55 14             	mov    %edx,0x14(%ebp)
			goto number;
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0103777:	8b 30                	mov    (%eax),%esi
f0103779:	bf 00 00 00 00       	mov    $0x0,%edi
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f010377e:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f0103783:	eb 13                	jmp    f0103798 <vprintfmt+0x35e>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0103785:	89 ca                	mov    %ecx,%edx
f0103787:	8d 45 14             	lea    0x14(%ebp),%eax
f010378a:	e8 2c fc ff ff       	call   f01033bb <getuint>
f010378f:	89 c6                	mov    %eax,%esi
f0103791:	89 d7                	mov    %edx,%edi
			base = 16;
f0103793:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f0103798:	0f be 55 d8          	movsbl -0x28(%ebp),%edx
f010379c:	89 54 24 10          	mov    %edx,0x10(%esp)
f01037a0:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01037a3:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01037a7:	89 44 24 08          	mov    %eax,0x8(%esp)
f01037ab:	89 34 24             	mov    %esi,(%esp)
f01037ae:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01037b2:	89 da                	mov    %ebx,%edx
f01037b4:	8b 45 08             	mov    0x8(%ebp),%eax
f01037b7:	e8 24 fb ff ff       	call   f01032e0 <printnum>
			break;
f01037bc:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01037bf:	e9 99 fc ff ff       	jmp    f010345d <vprintfmt+0x23>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f01037c4:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01037c8:	89 14 24             	mov    %edx,(%esp)
f01037cb:	ff 55 08             	call   *0x8(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01037ce:	8b 75 e0             	mov    -0x20(%ebp),%esi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f01037d1:	e9 87 fc ff ff       	jmp    f010345d <vprintfmt+0x23>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f01037d6:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01037da:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f01037e1:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f01037e4:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
f01037e8:	0f 84 6f fc ff ff    	je     f010345d <vprintfmt+0x23>
f01037ee:	83 ee 01             	sub    $0x1,%esi
f01037f1:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
f01037f5:	75 f7                	jne    f01037ee <vprintfmt+0x3b4>
f01037f7:	e9 61 fc ff ff       	jmp    f010345d <vprintfmt+0x23>
				/* do nothing */;
			break;
		}
	}
}
f01037fc:	83 c4 4c             	add    $0x4c,%esp
f01037ff:	5b                   	pop    %ebx
f0103800:	5e                   	pop    %esi
f0103801:	5f                   	pop    %edi
f0103802:	5d                   	pop    %ebp
f0103803:	c3                   	ret    

f0103804 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0103804:	55                   	push   %ebp
f0103805:	89 e5                	mov    %esp,%ebp
f0103807:	83 ec 28             	sub    $0x28,%esp
f010380a:	8b 45 08             	mov    0x8(%ebp),%eax
f010380d:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0103810:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0103813:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0103817:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f010381a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0103821:	85 c0                	test   %eax,%eax
f0103823:	74 30                	je     f0103855 <vsnprintf+0x51>
f0103825:	85 d2                	test   %edx,%edx
f0103827:	7e 2c                	jle    f0103855 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0103829:	8b 45 14             	mov    0x14(%ebp),%eax
f010382c:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103830:	8b 45 10             	mov    0x10(%ebp),%eax
f0103833:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103837:	8d 45 ec             	lea    -0x14(%ebp),%eax
f010383a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010383e:	c7 04 24 f5 33 10 f0 	movl   $0xf01033f5,(%esp)
f0103845:	e8 f0 fb ff ff       	call   f010343a <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f010384a:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010384d:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0103850:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103853:	eb 05                	jmp    f010385a <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0103855:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f010385a:	c9                   	leave  
f010385b:	c3                   	ret    

f010385c <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010385c:	55                   	push   %ebp
f010385d:	89 e5                	mov    %esp,%ebp
f010385f:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0103862:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0103865:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103869:	8b 45 10             	mov    0x10(%ebp),%eax
f010386c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103870:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103873:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103877:	8b 45 08             	mov    0x8(%ebp),%eax
f010387a:	89 04 24             	mov    %eax,(%esp)
f010387d:	e8 82 ff ff ff       	call   f0103804 <vsnprintf>
	va_end(ap);

	return rc;
}
f0103882:	c9                   	leave  
f0103883:	c3                   	ret    
	...

f0103890 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0103890:	55                   	push   %ebp
f0103891:	89 e5                	mov    %esp,%ebp
f0103893:	57                   	push   %edi
f0103894:	56                   	push   %esi
f0103895:	53                   	push   %ebx
f0103896:	83 ec 1c             	sub    $0x1c,%esp
f0103899:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010389c:	85 c0                	test   %eax,%eax
f010389e:	74 10                	je     f01038b0 <readline+0x20>
		cprintf("%s", prompt);
f01038a0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01038a4:	c7 04 24 28 46 10 f0 	movl   $0xf0104628,(%esp)
f01038ab:	e8 ce f6 ff ff       	call   f0102f7e <cprintf>

	i = 0;
	echoing = iscons(0);
f01038b0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01038b7:	e8 5e cd ff ff       	call   f010061a <iscons>
f01038bc:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f01038be:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f01038c3:	e8 41 cd ff ff       	call   f0100609 <getchar>
f01038c8:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01038ca:	85 c0                	test   %eax,%eax
f01038cc:	79 17                	jns    f01038e5 <readline+0x55>
			cprintf("read error: %e\n", c);
f01038ce:	89 44 24 04          	mov    %eax,0x4(%esp)
f01038d2:	c7 04 24 00 52 10 f0 	movl   $0xf0105200,(%esp)
f01038d9:	e8 a0 f6 ff ff       	call   f0102f7e <cprintf>
			return NULL;
f01038de:	b8 00 00 00 00       	mov    $0x0,%eax
f01038e3:	eb 6d                	jmp    f0103952 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01038e5:	83 f8 08             	cmp    $0x8,%eax
f01038e8:	74 05                	je     f01038ef <readline+0x5f>
f01038ea:	83 f8 7f             	cmp    $0x7f,%eax
f01038ed:	75 19                	jne    f0103908 <readline+0x78>
f01038ef:	85 f6                	test   %esi,%esi
f01038f1:	7e 15                	jle    f0103908 <readline+0x78>
			if (echoing)
f01038f3:	85 ff                	test   %edi,%edi
f01038f5:	74 0c                	je     f0103903 <readline+0x73>
				cputchar('\b');
f01038f7:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f01038fe:	e8 f6 cc ff ff       	call   f01005f9 <cputchar>
			i--;
f0103903:	83 ee 01             	sub    $0x1,%esi
f0103906:	eb bb                	jmp    f01038c3 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0103908:	83 fb 1f             	cmp    $0x1f,%ebx
f010390b:	7e 1f                	jle    f010392c <readline+0x9c>
f010390d:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0103913:	7f 17                	jg     f010392c <readline+0x9c>
			if (echoing)
f0103915:	85 ff                	test   %edi,%edi
f0103917:	74 08                	je     f0103921 <readline+0x91>
				cputchar(c);
f0103919:	89 1c 24             	mov    %ebx,(%esp)
f010391c:	e8 d8 cc ff ff       	call   f01005f9 <cputchar>
			buf[i++] = c;
f0103921:	88 9e 80 85 11 f0    	mov    %bl,-0xfee7a80(%esi)
f0103927:	83 c6 01             	add    $0x1,%esi
f010392a:	eb 97                	jmp    f01038c3 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f010392c:	83 fb 0a             	cmp    $0xa,%ebx
f010392f:	74 05                	je     f0103936 <readline+0xa6>
f0103931:	83 fb 0d             	cmp    $0xd,%ebx
f0103934:	75 8d                	jne    f01038c3 <readline+0x33>
			if (echoing)
f0103936:	85 ff                	test   %edi,%edi
f0103938:	74 0c                	je     f0103946 <readline+0xb6>
				cputchar('\n');
f010393a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0103941:	e8 b3 cc ff ff       	call   f01005f9 <cputchar>
			buf[i] = 0;
f0103946:	c6 86 80 85 11 f0 00 	movb   $0x0,-0xfee7a80(%esi)
			return buf;
f010394d:	b8 80 85 11 f0       	mov    $0xf0118580,%eax
		}
	}
}
f0103952:	83 c4 1c             	add    $0x1c,%esp
f0103955:	5b                   	pop    %ebx
f0103956:	5e                   	pop    %esi
f0103957:	5f                   	pop    %edi
f0103958:	5d                   	pop    %ebp
f0103959:	c3                   	ret    
f010395a:	00 00                	add    %al,(%eax)
f010395c:	00 00                	add    %al,(%eax)
	...

f0103960 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0103960:	55                   	push   %ebp
f0103961:	89 e5                	mov    %esp,%ebp
f0103963:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0103966:	b8 00 00 00 00       	mov    $0x0,%eax
f010396b:	80 3a 00             	cmpb   $0x0,(%edx)
f010396e:	74 09                	je     f0103979 <strlen+0x19>
		n++;
f0103970:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0103973:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0103977:	75 f7                	jne    f0103970 <strlen+0x10>
		n++;
	return n;
}
f0103979:	5d                   	pop    %ebp
f010397a:	c3                   	ret    

f010397b <strnlen>:

int
strnlen(const char *s, size_t size)
{
f010397b:	55                   	push   %ebp
f010397c:	89 e5                	mov    %esp,%ebp
f010397e:	53                   	push   %ebx
f010397f:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103982:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103985:	b8 00 00 00 00       	mov    $0x0,%eax
f010398a:	85 c9                	test   %ecx,%ecx
f010398c:	74 1a                	je     f01039a8 <strnlen+0x2d>
f010398e:	80 3b 00             	cmpb   $0x0,(%ebx)
f0103991:	74 15                	je     f01039a8 <strnlen+0x2d>
f0103993:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
f0103998:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010399a:	39 ca                	cmp    %ecx,%edx
f010399c:	74 0a                	je     f01039a8 <strnlen+0x2d>
f010399e:	83 c2 01             	add    $0x1,%edx
f01039a1:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
f01039a6:	75 f0                	jne    f0103998 <strnlen+0x1d>
		n++;
	return n;
}
f01039a8:	5b                   	pop    %ebx
f01039a9:	5d                   	pop    %ebp
f01039aa:	c3                   	ret    

f01039ab <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01039ab:	55                   	push   %ebp
f01039ac:	89 e5                	mov    %esp,%ebp
f01039ae:	53                   	push   %ebx
f01039af:	8b 45 08             	mov    0x8(%ebp),%eax
f01039b2:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01039b5:	ba 00 00 00 00       	mov    $0x0,%edx
f01039ba:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f01039be:	88 0c 10             	mov    %cl,(%eax,%edx,1)
f01039c1:	83 c2 01             	add    $0x1,%edx
f01039c4:	84 c9                	test   %cl,%cl
f01039c6:	75 f2                	jne    f01039ba <strcpy+0xf>
		/* do nothing */;
	return ret;
}
f01039c8:	5b                   	pop    %ebx
f01039c9:	5d                   	pop    %ebp
f01039ca:	c3                   	ret    

f01039cb <strcat>:

char *
strcat(char *dst, const char *src)
{
f01039cb:	55                   	push   %ebp
f01039cc:	89 e5                	mov    %esp,%ebp
f01039ce:	53                   	push   %ebx
f01039cf:	83 ec 08             	sub    $0x8,%esp
f01039d2:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01039d5:	89 1c 24             	mov    %ebx,(%esp)
f01039d8:	e8 83 ff ff ff       	call   f0103960 <strlen>
	strcpy(dst + len, src);
f01039dd:	8b 55 0c             	mov    0xc(%ebp),%edx
f01039e0:	89 54 24 04          	mov    %edx,0x4(%esp)
f01039e4:	01 d8                	add    %ebx,%eax
f01039e6:	89 04 24             	mov    %eax,(%esp)
f01039e9:	e8 bd ff ff ff       	call   f01039ab <strcpy>
	return dst;
}
f01039ee:	89 d8                	mov    %ebx,%eax
f01039f0:	83 c4 08             	add    $0x8,%esp
f01039f3:	5b                   	pop    %ebx
f01039f4:	5d                   	pop    %ebp
f01039f5:	c3                   	ret    

f01039f6 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01039f6:	55                   	push   %ebp
f01039f7:	89 e5                	mov    %esp,%ebp
f01039f9:	56                   	push   %esi
f01039fa:	53                   	push   %ebx
f01039fb:	8b 45 08             	mov    0x8(%ebp),%eax
f01039fe:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103a01:	8b 75 10             	mov    0x10(%ebp),%esi
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103a04:	85 f6                	test   %esi,%esi
f0103a06:	74 18                	je     f0103a20 <strncpy+0x2a>
f0103a08:	b9 00 00 00 00       	mov    $0x0,%ecx
		*dst++ = *src;
f0103a0d:	0f b6 1a             	movzbl (%edx),%ebx
f0103a10:	88 1c 08             	mov    %bl,(%eax,%ecx,1)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0103a13:	80 3a 01             	cmpb   $0x1,(%edx)
f0103a16:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103a19:	83 c1 01             	add    $0x1,%ecx
f0103a1c:	39 f1                	cmp    %esi,%ecx
f0103a1e:	75 ed                	jne    f0103a0d <strncpy+0x17>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0103a20:	5b                   	pop    %ebx
f0103a21:	5e                   	pop    %esi
f0103a22:	5d                   	pop    %ebp
f0103a23:	c3                   	ret    

f0103a24 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0103a24:	55                   	push   %ebp
f0103a25:	89 e5                	mov    %esp,%ebp
f0103a27:	57                   	push   %edi
f0103a28:	56                   	push   %esi
f0103a29:	53                   	push   %ebx
f0103a2a:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103a2d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103a30:	8b 75 10             	mov    0x10(%ebp),%esi
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0103a33:	89 f8                	mov    %edi,%eax
f0103a35:	85 f6                	test   %esi,%esi
f0103a37:	74 2b                	je     f0103a64 <strlcpy+0x40>
		while (--size > 0 && *src != '\0')
f0103a39:	83 fe 01             	cmp    $0x1,%esi
f0103a3c:	74 23                	je     f0103a61 <strlcpy+0x3d>
f0103a3e:	0f b6 0b             	movzbl (%ebx),%ecx
f0103a41:	84 c9                	test   %cl,%cl
f0103a43:	74 1c                	je     f0103a61 <strlcpy+0x3d>
	}
	return ret;
}

size_t
strlcpy(char *dst, const char *src, size_t size)
f0103a45:	83 ee 02             	sub    $0x2,%esi
f0103a48:	ba 00 00 00 00       	mov    $0x0,%edx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0103a4d:	88 08                	mov    %cl,(%eax)
f0103a4f:	83 c0 01             	add    $0x1,%eax
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0103a52:	39 f2                	cmp    %esi,%edx
f0103a54:	74 0b                	je     f0103a61 <strlcpy+0x3d>
f0103a56:	83 c2 01             	add    $0x1,%edx
f0103a59:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f0103a5d:	84 c9                	test   %cl,%cl
f0103a5f:	75 ec                	jne    f0103a4d <strlcpy+0x29>
			*dst++ = *src++;
		*dst = '\0';
f0103a61:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0103a64:	29 f8                	sub    %edi,%eax
}
f0103a66:	5b                   	pop    %ebx
f0103a67:	5e                   	pop    %esi
f0103a68:	5f                   	pop    %edi
f0103a69:	5d                   	pop    %ebp
f0103a6a:	c3                   	ret    

f0103a6b <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0103a6b:	55                   	push   %ebp
f0103a6c:	89 e5                	mov    %esp,%ebp
f0103a6e:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103a71:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0103a74:	0f b6 01             	movzbl (%ecx),%eax
f0103a77:	84 c0                	test   %al,%al
f0103a79:	74 16                	je     f0103a91 <strcmp+0x26>
f0103a7b:	3a 02                	cmp    (%edx),%al
f0103a7d:	75 12                	jne    f0103a91 <strcmp+0x26>
		p++, q++;
f0103a7f:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0103a82:	0f b6 41 01          	movzbl 0x1(%ecx),%eax
f0103a86:	84 c0                	test   %al,%al
f0103a88:	74 07                	je     f0103a91 <strcmp+0x26>
f0103a8a:	83 c1 01             	add    $0x1,%ecx
f0103a8d:	3a 02                	cmp    (%edx),%al
f0103a8f:	74 ee                	je     f0103a7f <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0103a91:	0f b6 c0             	movzbl %al,%eax
f0103a94:	0f b6 12             	movzbl (%edx),%edx
f0103a97:	29 d0                	sub    %edx,%eax
}
f0103a99:	5d                   	pop    %ebp
f0103a9a:	c3                   	ret    

f0103a9b <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0103a9b:	55                   	push   %ebp
f0103a9c:	89 e5                	mov    %esp,%ebp
f0103a9e:	53                   	push   %ebx
f0103a9f:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103aa2:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103aa5:	8b 55 10             	mov    0x10(%ebp),%edx
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0103aa8:	b8 00 00 00 00       	mov    $0x0,%eax
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0103aad:	85 d2                	test   %edx,%edx
f0103aaf:	74 28                	je     f0103ad9 <strncmp+0x3e>
f0103ab1:	0f b6 01             	movzbl (%ecx),%eax
f0103ab4:	84 c0                	test   %al,%al
f0103ab6:	74 24                	je     f0103adc <strncmp+0x41>
f0103ab8:	3a 03                	cmp    (%ebx),%al
f0103aba:	75 20                	jne    f0103adc <strncmp+0x41>
f0103abc:	83 ea 01             	sub    $0x1,%edx
f0103abf:	74 13                	je     f0103ad4 <strncmp+0x39>
		n--, p++, q++;
f0103ac1:	83 c1 01             	add    $0x1,%ecx
f0103ac4:	83 c3 01             	add    $0x1,%ebx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0103ac7:	0f b6 01             	movzbl (%ecx),%eax
f0103aca:	84 c0                	test   %al,%al
f0103acc:	74 0e                	je     f0103adc <strncmp+0x41>
f0103ace:	3a 03                	cmp    (%ebx),%al
f0103ad0:	74 ea                	je     f0103abc <strncmp+0x21>
f0103ad2:	eb 08                	jmp    f0103adc <strncmp+0x41>
		n--, p++, q++;
	if (n == 0)
		return 0;
f0103ad4:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0103ad9:	5b                   	pop    %ebx
f0103ada:	5d                   	pop    %ebp
f0103adb:	c3                   	ret    
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0103adc:	0f b6 01             	movzbl (%ecx),%eax
f0103adf:	0f b6 13             	movzbl (%ebx),%edx
f0103ae2:	29 d0                	sub    %edx,%eax
f0103ae4:	eb f3                	jmp    f0103ad9 <strncmp+0x3e>

f0103ae6 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0103ae6:	55                   	push   %ebp
f0103ae7:	89 e5                	mov    %esp,%ebp
f0103ae9:	8b 45 08             	mov    0x8(%ebp),%eax
f0103aec:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103af0:	0f b6 10             	movzbl (%eax),%edx
f0103af3:	84 d2                	test   %dl,%dl
f0103af5:	74 1c                	je     f0103b13 <strchr+0x2d>
		if (*s == c)
f0103af7:	38 ca                	cmp    %cl,%dl
f0103af9:	75 09                	jne    f0103b04 <strchr+0x1e>
f0103afb:	eb 1b                	jmp    f0103b18 <strchr+0x32>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0103afd:	83 c0 01             	add    $0x1,%eax
		if (*s == c)
f0103b00:	38 ca                	cmp    %cl,%dl
f0103b02:	74 14                	je     f0103b18 <strchr+0x32>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0103b04:	0f b6 50 01          	movzbl 0x1(%eax),%edx
f0103b08:	84 d2                	test   %dl,%dl
f0103b0a:	75 f1                	jne    f0103afd <strchr+0x17>
		if (*s == c)
			return (char *) s;
	return 0;
f0103b0c:	b8 00 00 00 00       	mov    $0x0,%eax
f0103b11:	eb 05                	jmp    f0103b18 <strchr+0x32>
f0103b13:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103b18:	5d                   	pop    %ebp
f0103b19:	c3                   	ret    

f0103b1a <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0103b1a:	55                   	push   %ebp
f0103b1b:	89 e5                	mov    %esp,%ebp
f0103b1d:	8b 45 08             	mov    0x8(%ebp),%eax
f0103b20:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103b24:	0f b6 10             	movzbl (%eax),%edx
f0103b27:	84 d2                	test   %dl,%dl
f0103b29:	74 14                	je     f0103b3f <strfind+0x25>
		if (*s == c)
f0103b2b:	38 ca                	cmp    %cl,%dl
f0103b2d:	75 06                	jne    f0103b35 <strfind+0x1b>
f0103b2f:	eb 0e                	jmp    f0103b3f <strfind+0x25>
f0103b31:	38 ca                	cmp    %cl,%dl
f0103b33:	74 0a                	je     f0103b3f <strfind+0x25>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f0103b35:	83 c0 01             	add    $0x1,%eax
f0103b38:	0f b6 10             	movzbl (%eax),%edx
f0103b3b:	84 d2                	test   %dl,%dl
f0103b3d:	75 f2                	jne    f0103b31 <strfind+0x17>
		if (*s == c)
			break;
	return (char *) s;
}
f0103b3f:	5d                   	pop    %ebp
f0103b40:	c3                   	ret    

f0103b41 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0103b41:	55                   	push   %ebp
f0103b42:	89 e5                	mov    %esp,%ebp
f0103b44:	83 ec 0c             	sub    $0xc,%esp
f0103b47:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0103b4a:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0103b4d:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0103b50:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103b53:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103b56:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0103b59:	85 c9                	test   %ecx,%ecx
f0103b5b:	74 30                	je     f0103b8d <memset+0x4c>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0103b5d:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0103b63:	75 25                	jne    f0103b8a <memset+0x49>
f0103b65:	f6 c1 03             	test   $0x3,%cl
f0103b68:	75 20                	jne    f0103b8a <memset+0x49>
		c &= 0xFF;
f0103b6a:	0f b6 d0             	movzbl %al,%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0103b6d:	89 d3                	mov    %edx,%ebx
f0103b6f:	c1 e3 08             	shl    $0x8,%ebx
f0103b72:	89 d6                	mov    %edx,%esi
f0103b74:	c1 e6 18             	shl    $0x18,%esi
f0103b77:	89 d0                	mov    %edx,%eax
f0103b79:	c1 e0 10             	shl    $0x10,%eax
f0103b7c:	09 f0                	or     %esi,%eax
f0103b7e:	09 d0                	or     %edx,%eax
f0103b80:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0103b82:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f0103b85:	fc                   	cld    
f0103b86:	f3 ab                	rep stos %eax,%es:(%edi)
f0103b88:	eb 03                	jmp    f0103b8d <memset+0x4c>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0103b8a:	fc                   	cld    
f0103b8b:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0103b8d:	89 f8                	mov    %edi,%eax
f0103b8f:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0103b92:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0103b95:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0103b98:	89 ec                	mov    %ebp,%esp
f0103b9a:	5d                   	pop    %ebp
f0103b9b:	c3                   	ret    

f0103b9c <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0103b9c:	55                   	push   %ebp
f0103b9d:	89 e5                	mov    %esp,%ebp
f0103b9f:	83 ec 08             	sub    $0x8,%esp
f0103ba2:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0103ba5:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0103ba8:	8b 45 08             	mov    0x8(%ebp),%eax
f0103bab:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103bae:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0103bb1:	39 c6                	cmp    %eax,%esi
f0103bb3:	73 36                	jae    f0103beb <memmove+0x4f>
f0103bb5:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0103bb8:	39 d0                	cmp    %edx,%eax
f0103bba:	73 2f                	jae    f0103beb <memmove+0x4f>
		s += n;
		d += n;
f0103bbc:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103bbf:	f6 c2 03             	test   $0x3,%dl
f0103bc2:	75 1b                	jne    f0103bdf <memmove+0x43>
f0103bc4:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0103bca:	75 13                	jne    f0103bdf <memmove+0x43>
f0103bcc:	f6 c1 03             	test   $0x3,%cl
f0103bcf:	75 0e                	jne    f0103bdf <memmove+0x43>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0103bd1:	83 ef 04             	sub    $0x4,%edi
f0103bd4:	8d 72 fc             	lea    -0x4(%edx),%esi
f0103bd7:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f0103bda:	fd                   	std    
f0103bdb:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103bdd:	eb 09                	jmp    f0103be8 <memmove+0x4c>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0103bdf:	83 ef 01             	sub    $0x1,%edi
f0103be2:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0103be5:	fd                   	std    
f0103be6:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0103be8:	fc                   	cld    
f0103be9:	eb 20                	jmp    f0103c0b <memmove+0x6f>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103beb:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0103bf1:	75 13                	jne    f0103c06 <memmove+0x6a>
f0103bf3:	a8 03                	test   $0x3,%al
f0103bf5:	75 0f                	jne    f0103c06 <memmove+0x6a>
f0103bf7:	f6 c1 03             	test   $0x3,%cl
f0103bfa:	75 0a                	jne    f0103c06 <memmove+0x6a>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0103bfc:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f0103bff:	89 c7                	mov    %eax,%edi
f0103c01:	fc                   	cld    
f0103c02:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103c04:	eb 05                	jmp    f0103c0b <memmove+0x6f>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0103c06:	89 c7                	mov    %eax,%edi
f0103c08:	fc                   	cld    
f0103c09:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0103c0b:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0103c0e:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0103c11:	89 ec                	mov    %ebp,%esp
f0103c13:	5d                   	pop    %ebp
f0103c14:	c3                   	ret    

f0103c15 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0103c15:	55                   	push   %ebp
f0103c16:	89 e5                	mov    %esp,%ebp
f0103c18:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0103c1b:	8b 45 10             	mov    0x10(%ebp),%eax
f0103c1e:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103c22:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103c25:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103c29:	8b 45 08             	mov    0x8(%ebp),%eax
f0103c2c:	89 04 24             	mov    %eax,(%esp)
f0103c2f:	e8 68 ff ff ff       	call   f0103b9c <memmove>
}
f0103c34:	c9                   	leave  
f0103c35:	c3                   	ret    

f0103c36 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0103c36:	55                   	push   %ebp
f0103c37:	89 e5                	mov    %esp,%ebp
f0103c39:	57                   	push   %edi
f0103c3a:	56                   	push   %esi
f0103c3b:	53                   	push   %ebx
f0103c3c:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103c3f:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103c42:	8b 7d 10             	mov    0x10(%ebp),%edi
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0103c45:	b8 00 00 00 00       	mov    $0x0,%eax
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103c4a:	85 ff                	test   %edi,%edi
f0103c4c:	74 37                	je     f0103c85 <memcmp+0x4f>
		if (*s1 != *s2)
f0103c4e:	0f b6 03             	movzbl (%ebx),%eax
f0103c51:	0f b6 0e             	movzbl (%esi),%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103c54:	83 ef 01             	sub    $0x1,%edi
f0103c57:	ba 00 00 00 00       	mov    $0x0,%edx
		if (*s1 != *s2)
f0103c5c:	38 c8                	cmp    %cl,%al
f0103c5e:	74 1c                	je     f0103c7c <memcmp+0x46>
f0103c60:	eb 10                	jmp    f0103c72 <memcmp+0x3c>
f0103c62:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
f0103c67:	83 c2 01             	add    $0x1,%edx
f0103c6a:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
f0103c6e:	38 c8                	cmp    %cl,%al
f0103c70:	74 0a                	je     f0103c7c <memcmp+0x46>
			return (int) *s1 - (int) *s2;
f0103c72:	0f b6 c0             	movzbl %al,%eax
f0103c75:	0f b6 c9             	movzbl %cl,%ecx
f0103c78:	29 c8                	sub    %ecx,%eax
f0103c7a:	eb 09                	jmp    f0103c85 <memcmp+0x4f>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103c7c:	39 fa                	cmp    %edi,%edx
f0103c7e:	75 e2                	jne    f0103c62 <memcmp+0x2c>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0103c80:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103c85:	5b                   	pop    %ebx
f0103c86:	5e                   	pop    %esi
f0103c87:	5f                   	pop    %edi
f0103c88:	5d                   	pop    %ebp
f0103c89:	c3                   	ret    

f0103c8a <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0103c8a:	55                   	push   %ebp
f0103c8b:	89 e5                	mov    %esp,%ebp
f0103c8d:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0103c90:	89 c2                	mov    %eax,%edx
f0103c92:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0103c95:	39 d0                	cmp    %edx,%eax
f0103c97:	73 19                	jae    f0103cb2 <memfind+0x28>
		if (*(const unsigned char *) s == (unsigned char) c)
f0103c99:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
f0103c9d:	38 08                	cmp    %cl,(%eax)
f0103c9f:	75 06                	jne    f0103ca7 <memfind+0x1d>
f0103ca1:	eb 0f                	jmp    f0103cb2 <memfind+0x28>
f0103ca3:	38 08                	cmp    %cl,(%eax)
f0103ca5:	74 0b                	je     f0103cb2 <memfind+0x28>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0103ca7:	83 c0 01             	add    $0x1,%eax
f0103caa:	39 d0                	cmp    %edx,%eax
f0103cac:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103cb0:	75 f1                	jne    f0103ca3 <memfind+0x19>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0103cb2:	5d                   	pop    %ebp
f0103cb3:	c3                   	ret    

f0103cb4 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0103cb4:	55                   	push   %ebp
f0103cb5:	89 e5                	mov    %esp,%ebp
f0103cb7:	57                   	push   %edi
f0103cb8:	56                   	push   %esi
f0103cb9:	53                   	push   %ebx
f0103cba:	8b 55 08             	mov    0x8(%ebp),%edx
f0103cbd:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103cc0:	0f b6 02             	movzbl (%edx),%eax
f0103cc3:	3c 20                	cmp    $0x20,%al
f0103cc5:	74 04                	je     f0103ccb <strtol+0x17>
f0103cc7:	3c 09                	cmp    $0x9,%al
f0103cc9:	75 0e                	jne    f0103cd9 <strtol+0x25>
		s++;
f0103ccb:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103cce:	0f b6 02             	movzbl (%edx),%eax
f0103cd1:	3c 20                	cmp    $0x20,%al
f0103cd3:	74 f6                	je     f0103ccb <strtol+0x17>
f0103cd5:	3c 09                	cmp    $0x9,%al
f0103cd7:	74 f2                	je     f0103ccb <strtol+0x17>
		s++;

	// plus/minus sign
	if (*s == '+')
f0103cd9:	3c 2b                	cmp    $0x2b,%al
f0103cdb:	75 0a                	jne    f0103ce7 <strtol+0x33>
		s++;
f0103cdd:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0103ce0:	bf 00 00 00 00       	mov    $0x0,%edi
f0103ce5:	eb 10                	jmp    f0103cf7 <strtol+0x43>
f0103ce7:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0103cec:	3c 2d                	cmp    $0x2d,%al
f0103cee:	75 07                	jne    f0103cf7 <strtol+0x43>
		s++, neg = 1;
f0103cf0:	83 c2 01             	add    $0x1,%edx
f0103cf3:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103cf7:	85 db                	test   %ebx,%ebx
f0103cf9:	0f 94 c0             	sete   %al
f0103cfc:	74 05                	je     f0103d03 <strtol+0x4f>
f0103cfe:	83 fb 10             	cmp    $0x10,%ebx
f0103d01:	75 15                	jne    f0103d18 <strtol+0x64>
f0103d03:	80 3a 30             	cmpb   $0x30,(%edx)
f0103d06:	75 10                	jne    f0103d18 <strtol+0x64>
f0103d08:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0103d0c:	75 0a                	jne    f0103d18 <strtol+0x64>
		s += 2, base = 16;
f0103d0e:	83 c2 02             	add    $0x2,%edx
f0103d11:	bb 10 00 00 00       	mov    $0x10,%ebx
f0103d16:	eb 13                	jmp    f0103d2b <strtol+0x77>
	else if (base == 0 && s[0] == '0')
f0103d18:	84 c0                	test   %al,%al
f0103d1a:	74 0f                	je     f0103d2b <strtol+0x77>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0103d1c:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0103d21:	80 3a 30             	cmpb   $0x30,(%edx)
f0103d24:	75 05                	jne    f0103d2b <strtol+0x77>
		s++, base = 8;
f0103d26:	83 c2 01             	add    $0x1,%edx
f0103d29:	b3 08                	mov    $0x8,%bl
	else if (base == 0)
		base = 10;
f0103d2b:	b8 00 00 00 00       	mov    $0x0,%eax
f0103d30:	89 de                	mov    %ebx,%esi

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0103d32:	0f b6 0a             	movzbl (%edx),%ecx
f0103d35:	8d 59 d0             	lea    -0x30(%ecx),%ebx
f0103d38:	80 fb 09             	cmp    $0x9,%bl
f0103d3b:	77 08                	ja     f0103d45 <strtol+0x91>
			dig = *s - '0';
f0103d3d:	0f be c9             	movsbl %cl,%ecx
f0103d40:	83 e9 30             	sub    $0x30,%ecx
f0103d43:	eb 1e                	jmp    f0103d63 <strtol+0xaf>
		else if (*s >= 'a' && *s <= 'z')
f0103d45:	8d 59 9f             	lea    -0x61(%ecx),%ebx
f0103d48:	80 fb 19             	cmp    $0x19,%bl
f0103d4b:	77 08                	ja     f0103d55 <strtol+0xa1>
			dig = *s - 'a' + 10;
f0103d4d:	0f be c9             	movsbl %cl,%ecx
f0103d50:	83 e9 57             	sub    $0x57,%ecx
f0103d53:	eb 0e                	jmp    f0103d63 <strtol+0xaf>
		else if (*s >= 'A' && *s <= 'Z')
f0103d55:	8d 59 bf             	lea    -0x41(%ecx),%ebx
f0103d58:	80 fb 19             	cmp    $0x19,%bl
f0103d5b:	77 14                	ja     f0103d71 <strtol+0xbd>
			dig = *s - 'A' + 10;
f0103d5d:	0f be c9             	movsbl %cl,%ecx
f0103d60:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0103d63:	39 f1                	cmp    %esi,%ecx
f0103d65:	7d 0e                	jge    f0103d75 <strtol+0xc1>
			break;
		s++, val = (val * base) + dig;
f0103d67:	83 c2 01             	add    $0x1,%edx
f0103d6a:	0f af c6             	imul   %esi,%eax
f0103d6d:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
f0103d6f:	eb c1                	jmp    f0103d32 <strtol+0x7e>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
f0103d71:	89 c1                	mov    %eax,%ecx
f0103d73:	eb 02                	jmp    f0103d77 <strtol+0xc3>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0103d75:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
f0103d77:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0103d7b:	74 05                	je     f0103d82 <strtol+0xce>
		*endptr = (char *) s;
f0103d7d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103d80:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
f0103d82:	89 ca                	mov    %ecx,%edx
f0103d84:	f7 da                	neg    %edx
f0103d86:	85 ff                	test   %edi,%edi
f0103d88:	0f 45 c2             	cmovne %edx,%eax
}
f0103d8b:	5b                   	pop    %ebx
f0103d8c:	5e                   	pop    %esi
f0103d8d:	5f                   	pop    %edi
f0103d8e:	5d                   	pop    %ebp
f0103d8f:	c3                   	ret    

f0103d90 <__udivdi3>:
f0103d90:	83 ec 1c             	sub    $0x1c,%esp
f0103d93:	89 7c 24 14          	mov    %edi,0x14(%esp)
f0103d97:	8b 7c 24 2c          	mov    0x2c(%esp),%edi
f0103d9b:	8b 44 24 20          	mov    0x20(%esp),%eax
f0103d9f:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0103da3:	89 74 24 10          	mov    %esi,0x10(%esp)
f0103da7:	8b 74 24 24          	mov    0x24(%esp),%esi
f0103dab:	85 ff                	test   %edi,%edi
f0103dad:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f0103db1:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103db5:	89 cd                	mov    %ecx,%ebp
f0103db7:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103dbb:	75 33                	jne    f0103df0 <__udivdi3+0x60>
f0103dbd:	39 f1                	cmp    %esi,%ecx
f0103dbf:	77 57                	ja     f0103e18 <__udivdi3+0x88>
f0103dc1:	85 c9                	test   %ecx,%ecx
f0103dc3:	75 0b                	jne    f0103dd0 <__udivdi3+0x40>
f0103dc5:	b8 01 00 00 00       	mov    $0x1,%eax
f0103dca:	31 d2                	xor    %edx,%edx
f0103dcc:	f7 f1                	div    %ecx
f0103dce:	89 c1                	mov    %eax,%ecx
f0103dd0:	89 f0                	mov    %esi,%eax
f0103dd2:	31 d2                	xor    %edx,%edx
f0103dd4:	f7 f1                	div    %ecx
f0103dd6:	89 c6                	mov    %eax,%esi
f0103dd8:	8b 44 24 04          	mov    0x4(%esp),%eax
f0103ddc:	f7 f1                	div    %ecx
f0103dde:	89 f2                	mov    %esi,%edx
f0103de0:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103de4:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103de8:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103dec:	83 c4 1c             	add    $0x1c,%esp
f0103def:	c3                   	ret    
f0103df0:	31 d2                	xor    %edx,%edx
f0103df2:	31 c0                	xor    %eax,%eax
f0103df4:	39 f7                	cmp    %esi,%edi
f0103df6:	77 e8                	ja     f0103de0 <__udivdi3+0x50>
f0103df8:	0f bd cf             	bsr    %edi,%ecx
f0103dfb:	83 f1 1f             	xor    $0x1f,%ecx
f0103dfe:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0103e02:	75 2c                	jne    f0103e30 <__udivdi3+0xa0>
f0103e04:	3b 6c 24 08          	cmp    0x8(%esp),%ebp
f0103e08:	76 04                	jbe    f0103e0e <__udivdi3+0x7e>
f0103e0a:	39 f7                	cmp    %esi,%edi
f0103e0c:	73 d2                	jae    f0103de0 <__udivdi3+0x50>
f0103e0e:	31 d2                	xor    %edx,%edx
f0103e10:	b8 01 00 00 00       	mov    $0x1,%eax
f0103e15:	eb c9                	jmp    f0103de0 <__udivdi3+0x50>
f0103e17:	90                   	nop
f0103e18:	89 f2                	mov    %esi,%edx
f0103e1a:	f7 f1                	div    %ecx
f0103e1c:	31 d2                	xor    %edx,%edx
f0103e1e:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103e22:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103e26:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103e2a:	83 c4 1c             	add    $0x1c,%esp
f0103e2d:	c3                   	ret    
f0103e2e:	66 90                	xchg   %ax,%ax
f0103e30:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103e35:	b8 20 00 00 00       	mov    $0x20,%eax
f0103e3a:	89 ea                	mov    %ebp,%edx
f0103e3c:	2b 44 24 04          	sub    0x4(%esp),%eax
f0103e40:	d3 e7                	shl    %cl,%edi
f0103e42:	89 c1                	mov    %eax,%ecx
f0103e44:	d3 ea                	shr    %cl,%edx
f0103e46:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103e4b:	09 fa                	or     %edi,%edx
f0103e4d:	89 f7                	mov    %esi,%edi
f0103e4f:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103e53:	89 f2                	mov    %esi,%edx
f0103e55:	8b 74 24 08          	mov    0x8(%esp),%esi
f0103e59:	d3 e5                	shl    %cl,%ebp
f0103e5b:	89 c1                	mov    %eax,%ecx
f0103e5d:	d3 ef                	shr    %cl,%edi
f0103e5f:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103e64:	d3 e2                	shl    %cl,%edx
f0103e66:	89 c1                	mov    %eax,%ecx
f0103e68:	d3 ee                	shr    %cl,%esi
f0103e6a:	09 d6                	or     %edx,%esi
f0103e6c:	89 fa                	mov    %edi,%edx
f0103e6e:	89 f0                	mov    %esi,%eax
f0103e70:	f7 74 24 0c          	divl   0xc(%esp)
f0103e74:	89 d7                	mov    %edx,%edi
f0103e76:	89 c6                	mov    %eax,%esi
f0103e78:	f7 e5                	mul    %ebp
f0103e7a:	39 d7                	cmp    %edx,%edi
f0103e7c:	72 22                	jb     f0103ea0 <__udivdi3+0x110>
f0103e7e:	8b 6c 24 08          	mov    0x8(%esp),%ebp
f0103e82:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103e87:	d3 e5                	shl    %cl,%ebp
f0103e89:	39 c5                	cmp    %eax,%ebp
f0103e8b:	73 04                	jae    f0103e91 <__udivdi3+0x101>
f0103e8d:	39 d7                	cmp    %edx,%edi
f0103e8f:	74 0f                	je     f0103ea0 <__udivdi3+0x110>
f0103e91:	89 f0                	mov    %esi,%eax
f0103e93:	31 d2                	xor    %edx,%edx
f0103e95:	e9 46 ff ff ff       	jmp    f0103de0 <__udivdi3+0x50>
f0103e9a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103ea0:	8d 46 ff             	lea    -0x1(%esi),%eax
f0103ea3:	31 d2                	xor    %edx,%edx
f0103ea5:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103ea9:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103ead:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103eb1:	83 c4 1c             	add    $0x1c,%esp
f0103eb4:	c3                   	ret    
	...

f0103ec0 <__umoddi3>:
f0103ec0:	83 ec 1c             	sub    $0x1c,%esp
f0103ec3:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f0103ec7:	8b 6c 24 2c          	mov    0x2c(%esp),%ebp
f0103ecb:	8b 44 24 20          	mov    0x20(%esp),%eax
f0103ecf:	89 74 24 10          	mov    %esi,0x10(%esp)
f0103ed3:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0103ed7:	8b 74 24 24          	mov    0x24(%esp),%esi
f0103edb:	85 ed                	test   %ebp,%ebp
f0103edd:	89 7c 24 14          	mov    %edi,0x14(%esp)
f0103ee1:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103ee5:	89 cf                	mov    %ecx,%edi
f0103ee7:	89 04 24             	mov    %eax,(%esp)
f0103eea:	89 f2                	mov    %esi,%edx
f0103eec:	75 1a                	jne    f0103f08 <__umoddi3+0x48>
f0103eee:	39 f1                	cmp    %esi,%ecx
f0103ef0:	76 4e                	jbe    f0103f40 <__umoddi3+0x80>
f0103ef2:	f7 f1                	div    %ecx
f0103ef4:	89 d0                	mov    %edx,%eax
f0103ef6:	31 d2                	xor    %edx,%edx
f0103ef8:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103efc:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103f00:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103f04:	83 c4 1c             	add    $0x1c,%esp
f0103f07:	c3                   	ret    
f0103f08:	39 f5                	cmp    %esi,%ebp
f0103f0a:	77 54                	ja     f0103f60 <__umoddi3+0xa0>
f0103f0c:	0f bd c5             	bsr    %ebp,%eax
f0103f0f:	83 f0 1f             	xor    $0x1f,%eax
f0103f12:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103f16:	75 60                	jne    f0103f78 <__umoddi3+0xb8>
f0103f18:	3b 0c 24             	cmp    (%esp),%ecx
f0103f1b:	0f 87 07 01 00 00    	ja     f0104028 <__umoddi3+0x168>
f0103f21:	89 f2                	mov    %esi,%edx
f0103f23:	8b 34 24             	mov    (%esp),%esi
f0103f26:	29 ce                	sub    %ecx,%esi
f0103f28:	19 ea                	sbb    %ebp,%edx
f0103f2a:	89 34 24             	mov    %esi,(%esp)
f0103f2d:	8b 04 24             	mov    (%esp),%eax
f0103f30:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103f34:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103f38:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103f3c:	83 c4 1c             	add    $0x1c,%esp
f0103f3f:	c3                   	ret    
f0103f40:	85 c9                	test   %ecx,%ecx
f0103f42:	75 0b                	jne    f0103f4f <__umoddi3+0x8f>
f0103f44:	b8 01 00 00 00       	mov    $0x1,%eax
f0103f49:	31 d2                	xor    %edx,%edx
f0103f4b:	f7 f1                	div    %ecx
f0103f4d:	89 c1                	mov    %eax,%ecx
f0103f4f:	89 f0                	mov    %esi,%eax
f0103f51:	31 d2                	xor    %edx,%edx
f0103f53:	f7 f1                	div    %ecx
f0103f55:	8b 04 24             	mov    (%esp),%eax
f0103f58:	f7 f1                	div    %ecx
f0103f5a:	eb 98                	jmp    f0103ef4 <__umoddi3+0x34>
f0103f5c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103f60:	89 f2                	mov    %esi,%edx
f0103f62:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103f66:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103f6a:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103f6e:	83 c4 1c             	add    $0x1c,%esp
f0103f71:	c3                   	ret    
f0103f72:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103f78:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103f7d:	89 e8                	mov    %ebp,%eax
f0103f7f:	bd 20 00 00 00       	mov    $0x20,%ebp
f0103f84:	2b 6c 24 04          	sub    0x4(%esp),%ebp
f0103f88:	89 fa                	mov    %edi,%edx
f0103f8a:	d3 e0                	shl    %cl,%eax
f0103f8c:	89 e9                	mov    %ebp,%ecx
f0103f8e:	d3 ea                	shr    %cl,%edx
f0103f90:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103f95:	09 c2                	or     %eax,%edx
f0103f97:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103f9b:	89 14 24             	mov    %edx,(%esp)
f0103f9e:	89 f2                	mov    %esi,%edx
f0103fa0:	d3 e7                	shl    %cl,%edi
f0103fa2:	89 e9                	mov    %ebp,%ecx
f0103fa4:	d3 ea                	shr    %cl,%edx
f0103fa6:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103fab:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0103faf:	d3 e6                	shl    %cl,%esi
f0103fb1:	89 e9                	mov    %ebp,%ecx
f0103fb3:	d3 e8                	shr    %cl,%eax
f0103fb5:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103fba:	09 f0                	or     %esi,%eax
f0103fbc:	8b 74 24 08          	mov    0x8(%esp),%esi
f0103fc0:	f7 34 24             	divl   (%esp)
f0103fc3:	d3 e6                	shl    %cl,%esi
f0103fc5:	89 74 24 08          	mov    %esi,0x8(%esp)
f0103fc9:	89 d6                	mov    %edx,%esi
f0103fcb:	f7 e7                	mul    %edi
f0103fcd:	39 d6                	cmp    %edx,%esi
f0103fcf:	89 c1                	mov    %eax,%ecx
f0103fd1:	89 d7                	mov    %edx,%edi
f0103fd3:	72 3f                	jb     f0104014 <__umoddi3+0x154>
f0103fd5:	39 44 24 08          	cmp    %eax,0x8(%esp)
f0103fd9:	72 35                	jb     f0104010 <__umoddi3+0x150>
f0103fdb:	8b 44 24 08          	mov    0x8(%esp),%eax
f0103fdf:	29 c8                	sub    %ecx,%eax
f0103fe1:	19 fe                	sbb    %edi,%esi
f0103fe3:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103fe8:	89 f2                	mov    %esi,%edx
f0103fea:	d3 e8                	shr    %cl,%eax
f0103fec:	89 e9                	mov    %ebp,%ecx
f0103fee:	d3 e2                	shl    %cl,%edx
f0103ff0:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103ff5:	09 d0                	or     %edx,%eax
f0103ff7:	89 f2                	mov    %esi,%edx
f0103ff9:	d3 ea                	shr    %cl,%edx
f0103ffb:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103fff:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0104003:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0104007:	83 c4 1c             	add    $0x1c,%esp
f010400a:	c3                   	ret    
f010400b:	90                   	nop
f010400c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104010:	39 d6                	cmp    %edx,%esi
f0104012:	75 c7                	jne    f0103fdb <__umoddi3+0x11b>
f0104014:	89 d7                	mov    %edx,%edi
f0104016:	89 c1                	mov    %eax,%ecx
f0104018:	2b 4c 24 0c          	sub    0xc(%esp),%ecx
f010401c:	1b 3c 24             	sbb    (%esp),%edi
f010401f:	eb ba                	jmp    f0103fdb <__umoddi3+0x11b>
f0104021:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0104028:	39 f5                	cmp    %esi,%ebp
f010402a:	0f 82 f1 fe ff ff    	jb     f0103f21 <__umoddi3+0x61>
f0104030:	e9 f8 fe ff ff       	jmp    f0103f2d <__umoddi3+0x6d>
