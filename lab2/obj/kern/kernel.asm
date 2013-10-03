
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
f0100046:	b8 90 39 11 f0       	mov    $0xf0113990,%eax
f010004b:	2d 20 33 11 f0       	sub    $0xf0113320,%eax
f0100050:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100054:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010005b:	00 
f010005c:	c7 04 24 20 33 11 f0 	movl   $0xf0113320,(%esp)
f0100063:	e8 a9 19 00 00       	call   f0101a11 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100068:	e8 97 04 00 00       	call   f0100504 <cons_init>
	cprintf("6828 decimal is %o octal!\n", 6828);
f010006d:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f0100074:	00 
f0100075:	c7 04 24 20 1f 10 f0 	movl   $0xf0101f20,(%esp)
f010007c:	e8 d1 0d 00 00       	call   f0100e52 <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100081:	e8 81 0b 00 00       	call   f0100c07 <mem_init>
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
f010009f:	83 3d 80 39 11 f0 00 	cmpl   $0x0,0xf0113980
f01000a6:	75 3d                	jne    f01000e5 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f01000a8:	89 35 80 39 11 f0    	mov    %esi,0xf0113980

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
f01000c1:	c7 04 24 3b 1f 10 f0 	movl   $0xf0101f3b,(%esp)
f01000c8:	e8 85 0d 00 00       	call   f0100e52 <cprintf>
	vcprintf(fmt, ap);
f01000cd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01000d1:	89 34 24             	mov    %esi,(%esp)
f01000d4:	e8 46 0d 00 00       	call   f0100e1f <vcprintf>
	cprintf("\n");
f01000d9:	c7 04 24 77 1f 10 f0 	movl   $0xf0101f77,(%esp)
f01000e0:	e8 6d 0d 00 00       	call   f0100e52 <cprintf>
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
f010010b:	c7 04 24 53 1f 10 f0 	movl   $0xf0101f53,(%esp)
f0100112:	e8 3b 0d 00 00       	call   f0100e52 <cprintf>
	vcprintf(fmt, ap);
f0100117:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010011b:	8b 45 10             	mov    0x10(%ebp),%eax
f010011e:	89 04 24             	mov    %eax,(%esp)
f0100121:	e8 f9 0c 00 00       	call   f0100e1f <vcprintf>
	cprintf("\n");
f0100126:	c7 04 24 77 1f 10 f0 	movl   $0xf0101f77,(%esp)
f010012d:	e8 20 0d 00 00       	call   f0100e52 <cprintf>
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
f0100179:	8b 15 44 35 11 f0    	mov    0xf0113544,%edx
f010017f:	88 82 40 33 11 f0    	mov    %al,-0xfeeccc0(%edx)
f0100185:	8d 42 01             	lea    0x1(%edx),%eax
		if (cons.wpos == CONSBUFSIZE)
f0100188:	3d 00 02 00 00       	cmp    $0x200,%eax
			cons.wpos = 0;
f010018d:	ba 00 00 00 00       	mov    $0x0,%edx
f0100192:	0f 44 c2             	cmove  %edx,%eax
f0100195:	a3 44 35 11 f0       	mov    %eax,0xf0113544
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
f010021c:	0f b7 15 00 30 11 f0 	movzwl 0xf0113000,%edx
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
f0100252:	0f b7 05 54 35 11 f0 	movzwl 0xf0113554,%eax
f0100259:	66 85 c0             	test   %ax,%ax
f010025c:	0f 84 e1 00 00 00    	je     f0100343 <cons_putc+0x19c>
			crt_pos--;
f0100262:	83 e8 01             	sub    $0x1,%eax
f0100265:	66 a3 54 35 11 f0    	mov    %ax,0xf0113554
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f010026b:	0f b7 c0             	movzwl %ax,%eax
f010026e:	b2 00                	mov    $0x0,%dl
f0100270:	83 ca 20             	or     $0x20,%edx
f0100273:	8b 0d 50 35 11 f0    	mov    0xf0113550,%ecx
f0100279:	66 89 14 41          	mov    %dx,(%ecx,%eax,2)
f010027d:	eb 77                	jmp    f01002f6 <cons_putc+0x14f>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f010027f:	66 83 05 54 35 11 f0 	addw   $0x50,0xf0113554
f0100286:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f0100287:	0f b7 05 54 35 11 f0 	movzwl 0xf0113554,%eax
f010028e:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f0100294:	c1 e8 16             	shr    $0x16,%eax
f0100297:	8d 04 80             	lea    (%eax,%eax,4),%eax
f010029a:	c1 e0 04             	shl    $0x4,%eax
f010029d:	66 a3 54 35 11 f0    	mov    %ax,0xf0113554
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
f01002d9:	0f b7 05 54 35 11 f0 	movzwl 0xf0113554,%eax
f01002e0:	0f b7 d8             	movzwl %ax,%ebx
f01002e3:	8b 0d 50 35 11 f0    	mov    0xf0113550,%ecx
f01002e9:	66 89 14 59          	mov    %dx,(%ecx,%ebx,2)
f01002ed:	83 c0 01             	add    $0x1,%eax
f01002f0:	66 a3 54 35 11 f0    	mov    %ax,0xf0113554
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f01002f6:	66 81 3d 54 35 11 f0 	cmpw   $0x7cf,0xf0113554
f01002fd:	cf 07 
f01002ff:	76 42                	jbe    f0100343 <cons_putc+0x19c>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100301:	a1 50 35 11 f0       	mov    0xf0113550,%eax
f0100306:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f010030d:	00 
f010030e:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100314:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100318:	89 04 24             	mov    %eax,(%esp)
f010031b:	e8 4c 17 00 00       	call   f0101a6c <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100320:	8b 15 50 35 11 f0    	mov    0xf0113550,%edx
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
f010033b:	66 83 2d 54 35 11 f0 	subw   $0x50,0xf0113554
f0100342:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100343:	8b 0d 4c 35 11 f0    	mov    0xf011354c,%ecx
f0100349:	b8 0e 00 00 00       	mov    $0xe,%eax
f010034e:	89 ca                	mov    %ecx,%edx
f0100350:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f0100351:	0f b7 35 54 35 11 f0 	movzwl 0xf0113554,%esi
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
f010039c:	83 0d 48 35 11 f0 40 	orl    $0x40,0xf0113548
		return 0;
f01003a3:	bb 00 00 00 00       	mov    $0x0,%ebx
f01003a8:	e9 c4 00 00 00       	jmp    f0100471 <kbd_proc_data+0xf8>
	} else if (data & 0x80) {
f01003ad:	84 c0                	test   %al,%al
f01003af:	79 37                	jns    f01003e8 <kbd_proc_data+0x6f>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f01003b1:	8b 0d 48 35 11 f0    	mov    0xf0113548,%ecx
f01003b7:	89 cb                	mov    %ecx,%ebx
f01003b9:	83 e3 40             	and    $0x40,%ebx
f01003bc:	83 e0 7f             	and    $0x7f,%eax
f01003bf:	85 db                	test   %ebx,%ebx
f01003c1:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f01003c4:	0f b6 d2             	movzbl %dl,%edx
f01003c7:	0f b6 82 a0 1f 10 f0 	movzbl -0xfefe060(%edx),%eax
f01003ce:	83 c8 40             	or     $0x40,%eax
f01003d1:	0f b6 c0             	movzbl %al,%eax
f01003d4:	f7 d0                	not    %eax
f01003d6:	21 c1                	and    %eax,%ecx
f01003d8:	89 0d 48 35 11 f0    	mov    %ecx,0xf0113548
		return 0;
f01003de:	bb 00 00 00 00       	mov    $0x0,%ebx
f01003e3:	e9 89 00 00 00       	jmp    f0100471 <kbd_proc_data+0xf8>
	} else if (shift & E0ESC) {
f01003e8:	8b 0d 48 35 11 f0    	mov    0xf0113548,%ecx
f01003ee:	f6 c1 40             	test   $0x40,%cl
f01003f1:	74 0e                	je     f0100401 <kbd_proc_data+0x88>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f01003f3:	89 c2                	mov    %eax,%edx
f01003f5:	83 ca 80             	or     $0xffffff80,%edx
		shift &= ~E0ESC;
f01003f8:	83 e1 bf             	and    $0xffffffbf,%ecx
f01003fb:	89 0d 48 35 11 f0    	mov    %ecx,0xf0113548
	}

	shift |= shiftcode[data];
f0100401:	0f b6 d2             	movzbl %dl,%edx
f0100404:	0f b6 82 a0 1f 10 f0 	movzbl -0xfefe060(%edx),%eax
f010040b:	0b 05 48 35 11 f0    	or     0xf0113548,%eax
	shift ^= togglecode[data];
f0100411:	0f b6 8a a0 20 10 f0 	movzbl -0xfefdf60(%edx),%ecx
f0100418:	31 c8                	xor    %ecx,%eax
f010041a:	a3 48 35 11 f0       	mov    %eax,0xf0113548

	c = charcode[shift & (CTL | SHIFT)][data];
f010041f:	89 c1                	mov    %eax,%ecx
f0100421:	83 e1 03             	and    $0x3,%ecx
f0100424:	8b 0c 8d a0 21 10 f0 	mov    -0xfefde60(,%ecx,4),%ecx
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
f010045a:	c7 04 24 6d 1f 10 f0 	movl   $0xf0101f6d,(%esp)
f0100461:	e8 ec 09 00 00       	call   f0100e52 <cprintf>
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
f010048c:	66 a3 00 30 11 f0    	mov    %ax,0xf0113000
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
f010049a:	80 3d 20 33 11 f0 00 	cmpb   $0x0,0xf0113320
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
f01004d1:	8b 15 40 35 11 f0    	mov    0xf0113540,%edx
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
f01004dc:	3b 15 44 35 11 f0    	cmp    0xf0113544,%edx
f01004e2:	74 1e                	je     f0100502 <cons_getc+0x41>
		c = cons.buf[cons.rpos++];
f01004e4:	0f b6 82 40 33 11 f0 	movzbl -0xfeeccc0(%edx),%eax
f01004eb:	83 c2 01             	add    $0x1,%edx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
f01004ee:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f01004f4:	b9 00 00 00 00       	mov    $0x0,%ecx
f01004f9:	0f 44 d1             	cmove  %ecx,%edx
f01004fc:	89 15 40 35 11 f0    	mov    %edx,0xf0113540
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
f010052a:	c7 05 4c 35 11 f0 b4 	movl   $0x3b4,0xf011354c
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
f0100542:	c7 05 4c 35 11 f0 d4 	movl   $0x3d4,0xf011354c
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
f0100551:	8b 0d 4c 35 11 f0    	mov    0xf011354c,%ecx
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
f0100576:	89 35 50 35 11 f0    	mov    %esi,0xf0113550

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f010057c:	0f b6 d8             	movzbl %al,%ebx
f010057f:	09 df                	or     %ebx,%edi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f0100581:	66 89 3d 54 35 11 f0 	mov    %di,0xf0113554
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
f01005d4:	a2 20 33 11 f0       	mov    %al,0xf0113320
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
f01005e5:	c7 04 24 79 1f 10 f0 	movl   $0xf0101f79,(%esp)
f01005ec:	e8 61 08 00 00       	call   f0100e52 <cprintf>
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
f0100636:	c7 04 24 b0 21 10 f0 	movl   $0xf01021b0,(%esp)
f010063d:	e8 10 08 00 00       	call   f0100e52 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100642:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f0100649:	00 
f010064a:	c7 04 24 b4 22 10 f0 	movl   $0xf01022b4,(%esp)
f0100651:	e8 fc 07 00 00       	call   f0100e52 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100656:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f010065d:	00 
f010065e:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f0100665:	f0 
f0100666:	c7 04 24 dc 22 10 f0 	movl   $0xf01022dc,(%esp)
f010066d:	e8 e0 07 00 00       	call   f0100e52 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100672:	c7 44 24 08 05 1f 10 	movl   $0x101f05,0x8(%esp)
f0100679:	00 
f010067a:	c7 44 24 04 05 1f 10 	movl   $0xf0101f05,0x4(%esp)
f0100681:	f0 
f0100682:	c7 04 24 00 23 10 f0 	movl   $0xf0102300,(%esp)
f0100689:	e8 c4 07 00 00       	call   f0100e52 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010068e:	c7 44 24 08 20 33 11 	movl   $0x113320,0x8(%esp)
f0100695:	00 
f0100696:	c7 44 24 04 20 33 11 	movl   $0xf0113320,0x4(%esp)
f010069d:	f0 
f010069e:	c7 04 24 24 23 10 f0 	movl   $0xf0102324,(%esp)
f01006a5:	e8 a8 07 00 00       	call   f0100e52 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006aa:	c7 44 24 08 90 39 11 	movl   $0x113990,0x8(%esp)
f01006b1:	00 
f01006b2:	c7 44 24 04 90 39 11 	movl   $0xf0113990,0x4(%esp)
f01006b9:	f0 
f01006ba:	c7 04 24 48 23 10 f0 	movl   $0xf0102348,(%esp)
f01006c1:	e8 8c 07 00 00       	call   f0100e52 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f01006c6:	b8 8f 3d 11 f0       	mov    $0xf0113d8f,%eax
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
f01006e7:	c7 04 24 6c 23 10 f0 	movl   $0xf010236c,(%esp)
f01006ee:	e8 5f 07 00 00       	call   f0100e52 <cprintf>
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
f0100706:	8b 83 a4 24 10 f0    	mov    -0xfefdb5c(%ebx),%eax
f010070c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100710:	8b 83 a0 24 10 f0    	mov    -0xfefdb60(%ebx),%eax
f0100716:	89 44 24 04          	mov    %eax,0x4(%esp)
f010071a:	c7 04 24 c9 21 10 f0 	movl   $0xf01021c9,(%esp)
f0100721:	e8 2c 07 00 00       	call   f0100e52 <cprintf>
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
f0100749:	c7 04 24 d2 21 10 f0 	movl   $0xf01021d2,(%esp)
f0100750:	e8 fd 06 00 00       	call   f0100e52 <cprintf>
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
f0100788:	c7 04 24 98 23 10 f0 	movl   $0xf0102398,(%esp)
f010078f:	e8 be 06 00 00       	call   f0100e52 <cprintf>
		struct Eipdebuginfo temp_debuginfo;
		debuginfo_eip((uintptr_t) eip, &temp_debuginfo);		
f0100794:	8d 45 d0             	lea    -0x30(%ebp),%eax
f0100797:	89 44 24 04          	mov    %eax,0x4(%esp)
f010079b:	89 3c 24             	mov    %edi,(%esp)
f010079e:	e8 a9 07 00 00       	call   f0100f4c <debuginfo_eip>
		cprintf("       %s:%d: ", temp_debuginfo.eip_file, temp_debuginfo.eip_line);
f01007a3:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01007a6:	89 44 24 08          	mov    %eax,0x8(%esp)
f01007aa:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01007ad:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007b1:	c7 04 24 e3 21 10 f0 	movl   $0xf01021e3,(%esp)
f01007b8:	e8 95 06 00 00       	call   f0100e52 <cprintf>
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
f01007d3:	c7 04 24 f2 21 10 f0 	movl   $0xf01021f2,(%esp)
f01007da:	e8 73 06 00 00       	call   f0100e52 <cprintf>
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
f01007ee:	c7 04 24 f5 21 10 f0 	movl   $0xf01021f5,(%esp)
f01007f5:	e8 58 06 00 00       	call   f0100e52 <cprintf>
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
f0100826:	c7 44 24 04 fa 21 10 	movl   $0xf01021fa,0x4(%esp)
f010082d:	f0 
f010082e:	8b 46 08             	mov    0x8(%esi),%eax
f0100831:	89 04 24             	mov    %eax,(%esp)
f0100834:	e8 02 11 00 00       	call   f010193b <strcmp>
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
f0100846:	c7 44 24 04 fe 21 10 	movl   $0xf01021fe,0x4(%esp)
f010084d:	f0 
f010084e:	8b 46 08             	mov    0x8(%esi),%eax
f0100851:	89 04 24             	mov    %eax,(%esp)
f0100854:	e8 e2 10 00 00       	call   f010193b <strcmp>
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
f0100866:	c7 44 24 04 02 22 10 	movl   $0xf0102202,0x4(%esp)
f010086d:	f0 
f010086e:	8b 46 08             	mov    0x8(%esi),%eax
f0100871:	89 04 24             	mov    %eax,(%esp)
f0100874:	e8 c2 10 00 00       	call   f010193b <strcmp>
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
f0100886:	c7 44 24 04 06 22 10 	movl   $0xf0102206,0x4(%esp)
f010088d:	f0 
f010088e:	8b 46 08             	mov    0x8(%esi),%eax
f0100891:	89 04 24             	mov    %eax,(%esp)
f0100894:	e8 a2 10 00 00       	call   f010193b <strcmp>
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
f01008a6:	c7 44 24 04 0a 22 10 	movl   $0xf010220a,0x4(%esp)
f01008ad:	f0 
f01008ae:	8b 46 08             	mov    0x8(%esi),%eax
f01008b1:	89 04 24             	mov    %eax,(%esp)
f01008b4:	e8 82 10 00 00       	call   f010193b <strcmp>
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
f01008c6:	c7 44 24 04 0e 22 10 	movl   $0xf010220e,0x4(%esp)
f01008cd:	f0 
f01008ce:	8b 46 08             	mov    0x8(%esi),%eax
f01008d1:	89 04 24             	mov    %eax,(%esp)
f01008d4:	e8 62 10 00 00       	call   f010193b <strcmp>
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
f01008e2:	c7 44 24 04 12 22 10 	movl   $0xf0102212,0x4(%esp)
f01008e9:	f0 
f01008ea:	8b 46 08             	mov    0x8(%esi),%eax
f01008ed:	89 04 24             	mov    %eax,(%esp)
f01008f0:	e8 46 10 00 00       	call   f010193b <strcmp>
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
f01008fe:	c7 44 24 04 16 22 10 	movl   $0xf0102216,0x4(%esp)
f0100905:	f0 
f0100906:	8b 46 08             	mov    0x8(%esi),%eax
f0100909:	89 04 24             	mov    %eax,(%esp)
f010090c:	e8 2a 10 00 00       	call   f010193b <strcmp>
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
f010091a:	c7 44 24 04 1a 22 10 	movl   $0xf010221a,0x4(%esp)
f0100921:	f0 
f0100922:	8b 46 08             	mov    0x8(%esi),%eax
f0100925:	89 04 24             	mov    %eax,(%esp)
f0100928:	e8 0e 10 00 00       	call   f010193b <strcmp>
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
f0100936:	c7 44 24 04 1e 22 10 	movl   $0xf010221e,0x4(%esp)
f010093d:	f0 
f010093e:	8b 46 08             	mov    0x8(%esi),%eax
f0100941:	89 04 24             	mov    %eax,(%esp)
f0100944:	e8 f2 0f 00 00       	call   f010193b <strcmp>
			ch_color1=COLOR_CYN
f0100949:	83 f8 01             	cmp    $0x1,%eax
f010094c:	19 ff                	sbb    %edi,%edi
f010094e:	83 e7 04             	and    $0x4,%edi
f0100951:	83 c7 07             	add    $0x7,%edi
	else ch_color1=COLOR_WHT;
	if(strcmp(argv[1],"blk")==0)
f0100954:	c7 44 24 04 fa 21 10 	movl   $0xf01021fa,0x4(%esp)
f010095b:	f0 
f010095c:	8b 46 04             	mov    0x4(%esi),%eax
f010095f:	89 04 24             	mov    %eax,(%esp)
f0100962:	e8 d4 0f 00 00       	call   f010193b <strcmp>
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
f0100974:	c7 44 24 04 fe 21 10 	movl   $0xf01021fe,0x4(%esp)
f010097b:	f0 
f010097c:	8b 46 04             	mov    0x4(%esi),%eax
f010097f:	89 04 24             	mov    %eax,(%esp)
f0100982:	e8 b4 0f 00 00       	call   f010193b <strcmp>
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
f0100991:	c7 44 24 04 02 22 10 	movl   $0xf0102202,0x4(%esp)
f0100998:	f0 
f0100999:	8b 46 04             	mov    0x4(%esi),%eax
f010099c:	89 04 24             	mov    %eax,(%esp)
f010099f:	e8 97 0f 00 00       	call   f010193b <strcmp>
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
f01009ae:	c7 44 24 04 06 22 10 	movl   $0xf0102206,0x4(%esp)
f01009b5:	f0 
f01009b6:	8b 46 04             	mov    0x4(%esi),%eax
f01009b9:	89 04 24             	mov    %eax,(%esp)
f01009bc:	e8 7a 0f 00 00       	call   f010193b <strcmp>
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
f01009cb:	c7 44 24 04 0a 22 10 	movl   $0xf010220a,0x4(%esp)
f01009d2:	f0 
f01009d3:	8b 46 04             	mov    0x4(%esi),%eax
f01009d6:	89 04 24             	mov    %eax,(%esp)
f01009d9:	e8 5d 0f 00 00       	call   f010193b <strcmp>
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
f01009e8:	c7 44 24 04 0e 22 10 	movl   $0xf010220e,0x4(%esp)
f01009ef:	f0 
f01009f0:	8b 46 04             	mov    0x4(%esi),%eax
f01009f3:	89 04 24             	mov    %eax,(%esp)
f01009f6:	e8 40 0f 00 00       	call   f010193b <strcmp>
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
f0100a01:	c7 44 24 04 12 22 10 	movl   $0xf0102212,0x4(%esp)
f0100a08:	f0 
f0100a09:	8b 46 04             	mov    0x4(%esi),%eax
f0100a0c:	89 04 24             	mov    %eax,(%esp)
f0100a0f:	e8 27 0f 00 00       	call   f010193b <strcmp>
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
f0100a1a:	c7 44 24 04 16 22 10 	movl   $0xf0102216,0x4(%esp)
f0100a21:	f0 
f0100a22:	8b 46 04             	mov    0x4(%esi),%eax
f0100a25:	89 04 24             	mov    %eax,(%esp)
f0100a28:	e8 0e 0f 00 00       	call   f010193b <strcmp>
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
f0100a33:	c7 44 24 04 1a 22 10 	movl   $0xf010221a,0x4(%esp)
f0100a3a:	f0 
f0100a3b:	8b 46 04             	mov    0x4(%esi),%eax
f0100a3e:	89 04 24             	mov    %eax,(%esp)
f0100a41:	e8 f5 0e 00 00       	call   f010193b <strcmp>
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
f0100a4c:	c7 44 24 04 1e 22 10 	movl   $0xf010221e,0x4(%esp)
f0100a53:	f0 
f0100a54:	8b 46 04             	mov    0x4(%esi),%eax
f0100a57:	89 04 24             	mov    %eax,(%esp)
f0100a5a:	e8 dc 0e 00 00       	call   f010193b <strcmp>
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
f0100a84:	c7 04 24 cc 23 10 f0 	movl   $0xf01023cc,(%esp)
f0100a8b:	e8 c2 03 00 00       	call   f0100e52 <cprintf>
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
f0100aab:	c7 04 24 00 24 10 f0 	movl   $0xf0102400,(%esp)
f0100ab2:	e8 9b 03 00 00       	call   f0100e52 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100ab7:	c7 04 24 24 24 10 f0 	movl   $0xf0102424,(%esp)
f0100abe:	e8 8f 03 00 00       	call   f0100e52 <cprintf>
  //	cprintf("x %d, y %x, z %d\n", x, y, z);
//	unsigned int i = 0x00646c72;
//	cprintf("H%x Wo%s", 57616, &i);

	while (1) {
		buf = readline("K> ");
f0100ac3:	c7 04 24 22 22 10 f0 	movl   $0xf0102222,(%esp)
f0100aca:	e8 91 0c 00 00       	call   f0101760 <readline>
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
f0100af7:	c7 04 24 26 22 10 f0 	movl   $0xf0102226,(%esp)
f0100afe:	e8 b3 0e 00 00       	call   f01019b6 <strchr>
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
f0100b1a:	c7 04 24 2b 22 10 f0 	movl   $0xf010222b,(%esp)
f0100b21:	e8 2c 03 00 00       	call   f0100e52 <cprintf>
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
f0100b49:	c7 04 24 26 22 10 f0 	movl   $0xf0102226,(%esp)
f0100b50:	e8 61 0e 00 00       	call   f01019b6 <strchr>
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
f0100b6b:	bb a0 24 10 f0       	mov    $0xf01024a0,%ebx
f0100b70:	bf 00 00 00 00       	mov    $0x0,%edi
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100b75:	8b 03                	mov    (%ebx),%eax
f0100b77:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100b7b:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100b7e:	89 04 24             	mov    %eax,(%esp)
f0100b81:	e8 b5 0d 00 00       	call   f010193b <strcmp>
f0100b86:	85 c0                	test   %eax,%eax
f0100b88:	75 24                	jne    f0100bae <monitor+0x10c>
			return commands[i].func(argc, argv, tf);
f0100b8a:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f0100b8d:	8b 55 08             	mov    0x8(%ebp),%edx
f0100b90:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100b94:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100b97:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100b9b:	89 34 24             	mov    %esi,(%esp)
f0100b9e:	ff 14 85 a8 24 10 f0 	call   *-0xfefdb58(,%eax,4)
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
f0100bc0:	c7 04 24 48 22 10 f0 	movl   $0xf0102248,(%esp)
f0100bc7:	e8 86 02 00 00       	call   f0100e52 <cprintf>
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

f0100bdc <nvram_read>:
// Detect machine's physical memory setup.
// --------------------------------------------------------------

static int
nvram_read(int r)
{
f0100bdc:	55                   	push   %ebp
f0100bdd:	89 e5                	mov    %esp,%ebp
f0100bdf:	56                   	push   %esi
f0100be0:	53                   	push   %ebx
f0100be1:	83 ec 10             	sub    $0x10,%esp
f0100be4:	89 c3                	mov    %eax,%ebx
	return mc146818_read(r) | (mc146818_read(r + 1) << 8);
f0100be6:	89 04 24             	mov    %eax,(%esp)
f0100be9:	e8 f6 01 00 00       	call   f0100de4 <mc146818_read>
f0100bee:	89 c6                	mov    %eax,%esi
f0100bf0:	83 c3 01             	add    $0x1,%ebx
f0100bf3:	89 1c 24             	mov    %ebx,(%esp)
f0100bf6:	e8 e9 01 00 00       	call   f0100de4 <mc146818_read>
f0100bfb:	c1 e0 08             	shl    $0x8,%eax
f0100bfe:	09 f0                	or     %esi,%eax
}
f0100c00:	83 c4 10             	add    $0x10,%esp
f0100c03:	5b                   	pop    %ebx
f0100c04:	5e                   	pop    %esi
f0100c05:	5d                   	pop    %ebp
f0100c06:	c3                   	ret    

f0100c07 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0100c07:	55                   	push   %ebp
f0100c08:	89 e5                	mov    %esp,%ebp
f0100c0a:	83 ec 18             	sub    $0x18,%esp
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f0100c0d:	b8 15 00 00 00       	mov    $0x15,%eax
f0100c12:	e8 c5 ff ff ff       	call   f0100bdc <nvram_read>
f0100c17:	c1 e0 0a             	shl    $0xa,%eax
f0100c1a:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0100c20:	85 c0                	test   %eax,%eax
f0100c22:	0f 48 c2             	cmovs  %edx,%eax
f0100c25:	c1 f8 0c             	sar    $0xc,%eax
f0100c28:	a3 58 35 11 f0       	mov    %eax,0xf0113558
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f0100c2d:	b8 17 00 00 00       	mov    $0x17,%eax
f0100c32:	e8 a5 ff ff ff       	call   f0100bdc <nvram_read>
f0100c37:	c1 e0 0a             	shl    $0xa,%eax
f0100c3a:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0100c40:	85 c0                	test   %eax,%eax
f0100c42:	0f 48 c2             	cmovs  %edx,%eax
f0100c45:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f0100c48:	85 c0                	test   %eax,%eax
f0100c4a:	74 0e                	je     f0100c5a <mem_init+0x53>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f0100c4c:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f0100c52:	89 15 84 39 11 f0    	mov    %edx,0xf0113984
f0100c58:	eb 0c                	jmp    f0100c66 <mem_init+0x5f>
	else
		npages = npages_basemem;
f0100c5a:	8b 15 58 35 11 f0    	mov    0xf0113558,%edx
f0100c60:	89 15 84 39 11 f0    	mov    %edx,0xf0113984

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
		npages_extmem * PGSIZE / 1024);
f0100c66:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0100c69:	c1 e8 0a             	shr    $0xa,%eax
f0100c6c:	89 44 24 0c          	mov    %eax,0xc(%esp)
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
f0100c70:	a1 58 35 11 f0       	mov    0xf0113558,%eax
f0100c75:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0100c78:	c1 e8 0a             	shr    $0xa,%eax
f0100c7b:	89 44 24 08          	mov    %eax,0x8(%esp)
		npages * PGSIZE / 1024,
f0100c7f:	a1 84 39 11 f0       	mov    0xf0113984,%eax
f0100c84:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0100c87:	c1 e8 0a             	shr    $0xa,%eax
f0100c8a:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100c8e:	c7 04 24 d0 24 10 f0 	movl   $0xf01024d0,(%esp)
f0100c95:	e8 b8 01 00 00       	call   f0100e52 <cprintf>

	// Find out how much memory the machine has (npages & npages_basemem).
	i386_detect_memory();

	// Remove this line when you're ready to test this function.
	panic("mem_init: This function is not finished\n");
f0100c9a:	c7 44 24 08 0c 25 10 	movl   $0xf010250c,0x8(%esp)
f0100ca1:	f0 
f0100ca2:	c7 44 24 04 83 00 00 	movl   $0x83,0x4(%esp)
f0100ca9:	00 
f0100caa:	c7 04 24 38 25 10 f0 	movl   $0xf0102538,(%esp)
f0100cb1:	e8 de f3 ff ff       	call   f0100094 <_panic>

f0100cb6 <page_init>:
// allocator functions below to allocate and deallocate physical
// memory via the page_free_list.
//
void
page_init(void)
{
f0100cb6:	55                   	push   %ebp
f0100cb7:	89 e5                	mov    %esp,%ebp
f0100cb9:	56                   	push   %esi
f0100cba:	53                   	push   %ebx
	// Initialize nextfree if this is the first time.
	// 'end' is a magic symbol automatically generated by the linker,
	// which points to the end of the kernel's bss segment:
	// the first virtual address that the linker did *not* assign
	// to any kernel code or global variables.
	if (!nextfree) {
f0100cbb:	83 3d 60 35 11 f0 00 	cmpl   $0x0,0xf0113560
f0100cc2:	75 0f                	jne    f0100cd3 <page_init+0x1d>
		extern char end[];
		nextfree = ROUNDUP((char *) end, PGSIZE);
f0100cc4:	b8 8f 49 11 f0       	mov    $0xf011498f,%eax
f0100cc9:	25 00 f0 ff ff       	and    $0xfffff000,%eax
f0100cce:	a3 60 35 11 f0       	mov    %eax,0xf0113560
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	size_t low = IOPHYSMEM;	
	size_t top = (size_t)boot_alloc(0);
f0100cd3:	8b 35 60 35 11 f0    	mov    0xf0113560,%esi
	for (i = 0; i < npages; i++) {
f0100cd9:	83 3d 84 39 11 f0 00 	cmpl   $0x0,0xf0113984
f0100ce0:	75 43                	jne    f0100d25 <page_init+0x6f>
f0100ce2:	eb 64                	jmp    f0100d48 <page_init+0x92>
		pages[i].pp_ref = 0;
f0100ce4:	8d 0c c5 00 00 00 00 	lea    0x0(,%eax,8),%ecx
f0100ceb:	8b 15 8c 39 11 f0    	mov    0xf011398c,%edx
f0100cf1:	66 c7 44 0a 04 00 00 	movw   $0x0,0x4(%edx,%ecx,1)
		pages[i].pp_link = page_free_list;
f0100cf8:	89 1c c2             	mov    %ebx,(%edx,%eax,8)
		if (i == 0) continue;
f0100cfb:	85 c0                	test   %eax,%eax
f0100cfd:	74 13                	je     f0100d12 <page_init+0x5c>
		if (i >= PTX(low) && i < PTX(top)) continue; 
f0100cff:	3d 9f 00 00 00       	cmp    $0x9f,%eax
f0100d04:	76 04                	jbe    f0100d0a <page_init+0x54>
f0100d06:	39 c6                	cmp    %eax,%esi
f0100d08:	77 08                	ja     f0100d12 <page_init+0x5c>
		page_free_list = &pages[i];
f0100d0a:	89 cb                	mov    %ecx,%ebx
f0100d0c:	03 1d 8c 39 11 f0    	add    0xf011398c,%ebx
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	size_t low = IOPHYSMEM;	
	size_t top = (size_t)boot_alloc(0);
	for (i = 0; i < npages; i++) {
f0100d12:	83 c0 01             	add    $0x1,%eax
f0100d15:	39 05 84 39 11 f0    	cmp    %eax,0xf0113984
f0100d1b:	77 c7                	ja     f0100ce4 <page_init+0x2e>
f0100d1d:	89 1d 5c 35 11 f0    	mov    %ebx,0xf011355c
f0100d23:	eb 23                	jmp    f0100d48 <page_init+0x92>
		pages[i].pp_ref = 0;
f0100d25:	a1 8c 39 11 f0       	mov    0xf011398c,%eax
f0100d2a:	66 c7 40 04 00 00    	movw   $0x0,0x4(%eax)
		pages[i].pp_link = page_free_list;
f0100d30:	8b 1d 5c 35 11 f0    	mov    0xf011355c,%ebx
f0100d36:	89 18                	mov    %ebx,(%eax)
		if (i == 0) continue;
		if (i >= PTX(low) && i < PTX(top)) continue; 
f0100d38:	c1 ee 0c             	shr    $0xc,%esi
f0100d3b:	81 e6 ff 03 00 00    	and    $0x3ff,%esi
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	size_t low = IOPHYSMEM;	
	size_t top = (size_t)boot_alloc(0);
	for (i = 0; i < npages; i++) {
f0100d41:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d46:	eb ca                	jmp    f0100d12 <page_init+0x5c>
		pages[i].pp_link = page_free_list;
		if (i == 0) continue;
		if (i >= PTX(low) && i < PTX(top)) continue; 
		page_free_list = &pages[i];
	}
}
f0100d48:	5b                   	pop    %ebx
f0100d49:	5e                   	pop    %esi
f0100d4a:	5d                   	pop    %ebp
f0100d4b:	c3                   	ret    

f0100d4c <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100d4c:	55                   	push   %ebp
f0100d4d:	89 e5                	mov    %esp,%ebp
f0100d4f:	83 ec 18             	sub    $0x18,%esp
	// Fill this function in
	if (alloc_flags & ALLOC_ZERO) memset(page_free_list, 0, PGSIZE);
f0100d52:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f0100d56:	74 1d                	je     f0100d75 <page_alloc+0x29>
f0100d58:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0100d5f:	00 
f0100d60:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0100d67:	00 
f0100d68:	a1 5c 35 11 f0       	mov    0xf011355c,%eax
f0100d6d:	89 04 24             	mov    %eax,(%esp)
f0100d70:	e8 9c 0c 00 00       	call   f0101a11 <memset>
	return (struct PageInfo*)page_free_list;
	return 0;
}
f0100d75:	a1 5c 35 11 f0       	mov    0xf011355c,%eax
f0100d7a:	c9                   	leave  
f0100d7b:	c3                   	ret    

f0100d7c <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100d7c:	55                   	push   %ebp
f0100d7d:	89 e5                	mov    %esp,%ebp
f0100d7f:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	pp->pp_link = page_free_list;
f0100d82:	8b 15 5c 35 11 f0    	mov    0xf011355c,%edx
f0100d88:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f0100d8a:	a3 5c 35 11 f0       	mov    %eax,0xf011355c
}
f0100d8f:	5d                   	pop    %ebp
f0100d90:	c3                   	ret    

f0100d91 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0100d91:	55                   	push   %ebp
f0100d92:	89 e5                	mov    %esp,%ebp
f0100d94:	83 ec 04             	sub    $0x4,%esp
f0100d97:	8b 45 08             	mov    0x8(%ebp),%eax
	if (--pp->pp_ref == 0)
f0100d9a:	0f b7 50 04          	movzwl 0x4(%eax),%edx
f0100d9e:	83 ea 01             	sub    $0x1,%edx
f0100da1:	66 89 50 04          	mov    %dx,0x4(%eax)
f0100da5:	66 85 d2             	test   %dx,%dx
f0100da8:	75 08                	jne    f0100db2 <page_decref+0x21>
		page_free(pp);
f0100daa:	89 04 24             	mov    %eax,(%esp)
f0100dad:	e8 ca ff ff ff       	call   f0100d7c <page_free>
}
f0100db2:	c9                   	leave  
f0100db3:	c3                   	ret    

f0100db4 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100db4:	55                   	push   %ebp
f0100db5:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return NULL;
}
f0100db7:	b8 00 00 00 00       	mov    $0x0,%eax
f0100dbc:	5d                   	pop    %ebp
f0100dbd:	c3                   	ret    

f0100dbe <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f0100dbe:	55                   	push   %ebp
f0100dbf:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return 0;
}
f0100dc1:	b8 00 00 00 00       	mov    $0x0,%eax
f0100dc6:	5d                   	pop    %ebp
f0100dc7:	c3                   	ret    

f0100dc8 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0100dc8:	55                   	push   %ebp
f0100dc9:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return NULL;
}
f0100dcb:	b8 00 00 00 00       	mov    $0x0,%eax
f0100dd0:	5d                   	pop    %ebp
f0100dd1:	c3                   	ret    

f0100dd2 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0100dd2:	55                   	push   %ebp
f0100dd3:	89 e5                	mov    %esp,%ebp
	// Fill this function in
}
f0100dd5:	5d                   	pop    %ebp
f0100dd6:	c3                   	ret    

f0100dd7 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0100dd7:	55                   	push   %ebp
f0100dd8:	89 e5                	mov    %esp,%ebp
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0100dda:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100ddd:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f0100de0:	5d                   	pop    %ebp
f0100de1:	c3                   	ret    
	...

f0100de4 <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0100de4:	55                   	push   %ebp
f0100de5:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100de7:	ba 70 00 00 00       	mov    $0x70,%edx
f0100dec:	8b 45 08             	mov    0x8(%ebp),%eax
f0100def:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100df0:	b2 71                	mov    $0x71,%dl
f0100df2:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0100df3:	0f b6 c0             	movzbl %al,%eax
}
f0100df6:	5d                   	pop    %ebp
f0100df7:	c3                   	ret    

f0100df8 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0100df8:	55                   	push   %ebp
f0100df9:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100dfb:	ba 70 00 00 00       	mov    $0x70,%edx
f0100e00:	8b 45 08             	mov    0x8(%ebp),%eax
f0100e03:	ee                   	out    %al,(%dx)
f0100e04:	b2 71                	mov    $0x71,%dl
f0100e06:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100e09:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0100e0a:	5d                   	pop    %ebp
f0100e0b:	c3                   	ret    

f0100e0c <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100e0c:	55                   	push   %ebp
f0100e0d:	89 e5                	mov    %esp,%ebp
f0100e0f:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f0100e12:	8b 45 08             	mov    0x8(%ebp),%eax
f0100e15:	89 04 24             	mov    %eax,(%esp)
f0100e18:	e8 dc f7 ff ff       	call   f01005f9 <cputchar>
	*cnt++;
}
f0100e1d:	c9                   	leave  
f0100e1e:	c3                   	ret    

f0100e1f <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0100e1f:	55                   	push   %ebp
f0100e20:	89 e5                	mov    %esp,%ebp
f0100e22:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f0100e25:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100e2c:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100e2f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100e33:	8b 45 08             	mov    0x8(%ebp),%eax
f0100e36:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100e3a:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100e3d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100e41:	c7 04 24 0c 0e 10 f0 	movl   $0xf0100e0c,(%esp)
f0100e48:	e8 bd 04 00 00       	call   f010130a <vprintfmt>
	return cnt;
}
f0100e4d:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100e50:	c9                   	leave  
f0100e51:	c3                   	ret    

f0100e52 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0100e52:	55                   	push   %ebp
f0100e53:	89 e5                	mov    %esp,%ebp
f0100e55:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0100e58:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0100e5b:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100e5f:	8b 45 08             	mov    0x8(%ebp),%eax
f0100e62:	89 04 24             	mov    %eax,(%esp)
f0100e65:	e8 b5 ff ff ff       	call   f0100e1f <vcprintf>
	va_end(ap);

	return cnt;
}
f0100e6a:	c9                   	leave  
f0100e6b:	c3                   	ret    

f0100e6c <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100e6c:	55                   	push   %ebp
f0100e6d:	89 e5                	mov    %esp,%ebp
f0100e6f:	57                   	push   %edi
f0100e70:	56                   	push   %esi
f0100e71:	53                   	push   %ebx
f0100e72:	83 ec 10             	sub    $0x10,%esp
f0100e75:	89 c3                	mov    %eax,%ebx
f0100e77:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0100e7a:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0100e7d:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100e80:	8b 0a                	mov    (%edx),%ecx
f0100e82:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100e85:	8b 00                	mov    (%eax),%eax
f0100e87:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100e8a:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)

	while (l <= r) {
f0100e91:	eb 77                	jmp    f0100f0a <stab_binsearch+0x9e>
		int true_m = (l + r) / 2, m = true_m;
f0100e93:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100e96:	01 c8                	add    %ecx,%eax
f0100e98:	bf 02 00 00 00       	mov    $0x2,%edi
f0100e9d:	99                   	cltd   
f0100e9e:	f7 ff                	idiv   %edi
f0100ea0:	89 c2                	mov    %eax,%edx

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100ea2:	eb 01                	jmp    f0100ea5 <stab_binsearch+0x39>
			m--;
f0100ea4:	4a                   	dec    %edx

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100ea5:	39 ca                	cmp    %ecx,%edx
f0100ea7:	7c 1d                	jl     f0100ec6 <stab_binsearch+0x5a>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0100ea9:	6b fa 0c             	imul   $0xc,%edx,%edi

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100eac:	0f b6 7c 3b 04       	movzbl 0x4(%ebx,%edi,1),%edi
f0100eb1:	39 f7                	cmp    %esi,%edi
f0100eb3:	75 ef                	jne    f0100ea4 <stab_binsearch+0x38>
f0100eb5:	89 55 ec             	mov    %edx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100eb8:	6b fa 0c             	imul   $0xc,%edx,%edi
f0100ebb:	8b 7c 3b 08          	mov    0x8(%ebx,%edi,1),%edi
f0100ebf:	3b 7d 0c             	cmp    0xc(%ebp),%edi
f0100ec2:	73 18                	jae    f0100edc <stab_binsearch+0x70>
f0100ec4:	eb 05                	jmp    f0100ecb <stab_binsearch+0x5f>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0100ec6:	8d 48 01             	lea    0x1(%eax),%ecx
			continue;
f0100ec9:	eb 3f                	jmp    f0100f0a <stab_binsearch+0x9e>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0100ecb:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0100ece:	89 11                	mov    %edx,(%ecx)
			l = true_m + 1;
f0100ed0:	8d 48 01             	lea    0x1(%eax),%ecx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100ed3:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100eda:	eb 2e                	jmp    f0100f0a <stab_binsearch+0x9e>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0100edc:	3b 7d 0c             	cmp    0xc(%ebp),%edi
f0100edf:	76 15                	jbe    f0100ef6 <stab_binsearch+0x8a>
			*region_right = m - 1;
f0100ee1:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0100ee4:	4f                   	dec    %edi
f0100ee5:	89 7d f0             	mov    %edi,-0x10(%ebp)
f0100ee8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100eeb:	89 38                	mov    %edi,(%eax)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100eed:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100ef4:	eb 14                	jmp    f0100f0a <stab_binsearch+0x9e>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100ef6:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0100ef9:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0100efc:	89 39                	mov    %edi,(%ecx)
			l = m;
			addr++;
f0100efe:	ff 45 0c             	incl   0xc(%ebp)
f0100f01:	89 d1                	mov    %edx,%ecx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100f03:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0100f0a:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
f0100f0d:	7e 84                	jle    f0100e93 <stab_binsearch+0x27>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100f0f:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0100f13:	75 0d                	jne    f0100f22 <stab_binsearch+0xb6>
		*region_right = *region_left - 1;
f0100f15:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100f18:	8b 02                	mov    (%edx),%eax
f0100f1a:	48                   	dec    %eax
f0100f1b:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100f1e:	89 01                	mov    %eax,(%ecx)
f0100f20:	eb 22                	jmp    f0100f44 <stab_binsearch+0xd8>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100f22:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100f25:	8b 01                	mov    (%ecx),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100f27:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100f2a:	8b 0a                	mov    (%edx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100f2c:	eb 01                	jmp    f0100f2f <stab_binsearch+0xc3>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100f2e:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100f2f:	39 c1                	cmp    %eax,%ecx
f0100f31:	7d 0c                	jge    f0100f3f <stab_binsearch+0xd3>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0100f33:	6b d0 0c             	imul   $0xc,%eax,%edx
	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
		     l > *region_left && stabs[l].n_type != type;
f0100f36:	0f b6 54 13 04       	movzbl 0x4(%ebx,%edx,1),%edx
f0100f3b:	39 f2                	cmp    %esi,%edx
f0100f3d:	75 ef                	jne    f0100f2e <stab_binsearch+0xc2>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100f3f:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100f42:	89 02                	mov    %eax,(%edx)
	}
}
f0100f44:	83 c4 10             	add    $0x10,%esp
f0100f47:	5b                   	pop    %ebx
f0100f48:	5e                   	pop    %esi
f0100f49:	5f                   	pop    %edi
f0100f4a:	5d                   	pop    %ebp
f0100f4b:	c3                   	ret    

f0100f4c <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100f4c:	55                   	push   %ebp
f0100f4d:	89 e5                	mov    %esp,%ebp
f0100f4f:	83 ec 58             	sub    $0x58,%esp
f0100f52:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0100f55:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0100f58:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0100f5b:	8b 75 08             	mov    0x8(%ebp),%esi
f0100f5e:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100f61:	c7 03 44 25 10 f0    	movl   $0xf0102544,(%ebx)
	info->eip_line = 0;
f0100f67:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100f6e:	c7 43 08 44 25 10 f0 	movl   $0xf0102544,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100f75:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100f7c:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100f7f:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100f86:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100f8c:	76 12                	jbe    f0100fa0 <debuginfo_eip+0x54>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100f8e:	b8 bf 8c 10 f0       	mov    $0xf0108cbf,%eax
f0100f93:	3d 0d 70 10 f0       	cmp    $0xf010700d,%eax
f0100f98:	0f 86 f1 01 00 00    	jbe    f010118f <debuginfo_eip+0x243>
f0100f9e:	eb 1c                	jmp    f0100fbc <debuginfo_eip+0x70>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100fa0:	c7 44 24 08 4e 25 10 	movl   $0xf010254e,0x8(%esp)
f0100fa7:	f0 
f0100fa8:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0100faf:	00 
f0100fb0:	c7 04 24 5b 25 10 f0 	movl   $0xf010255b,(%esp)
f0100fb7:	e8 d8 f0 ff ff       	call   f0100094 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100fbc:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100fc1:	80 3d be 8c 10 f0 00 	cmpb   $0x0,0xf0108cbe
f0100fc8:	0f 85 cd 01 00 00    	jne    f010119b <debuginfo_eip+0x24f>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100fce:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100fd5:	b8 0c 70 10 f0       	mov    $0xf010700c,%eax
f0100fda:	2d 7c 27 10 f0       	sub    $0xf010277c,%eax
f0100fdf:	c1 f8 02             	sar    $0x2,%eax
f0100fe2:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100fe8:	83 e8 01             	sub    $0x1,%eax
f0100feb:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100fee:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100ff2:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0100ff9:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100ffc:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100fff:	b8 7c 27 10 f0       	mov    $0xf010277c,%eax
f0101004:	e8 63 fe ff ff       	call   f0100e6c <stab_binsearch>
	if (lfile == 0)
f0101009:	8b 55 e4             	mov    -0x1c(%ebp),%edx
		return -1;
f010100c:	b8 ff ff ff ff       	mov    $0xffffffff,%eax

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
f0101011:	85 d2                	test   %edx,%edx
f0101013:	0f 84 82 01 00 00    	je     f010119b <debuginfo_eip+0x24f>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0101019:	89 55 dc             	mov    %edx,-0x24(%ebp)
	rfun = rfile;
f010101c:	8b 45 e0             	mov    -0x20(%ebp),%eax
f010101f:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0101022:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101026:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f010102d:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0101030:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0101033:	b8 7c 27 10 f0       	mov    $0xf010277c,%eax
f0101038:	e8 2f fe ff ff       	call   f0100e6c <stab_binsearch>

	if (lfun <= rfun) {
f010103d:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0101040:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0101043:	39 d0                	cmp    %edx,%eax
f0101045:	7f 3d                	jg     f0101084 <debuginfo_eip+0x138>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0101047:	6b c8 0c             	imul   $0xc,%eax,%ecx
f010104a:	8d b9 7c 27 10 f0    	lea    -0xfefd884(%ecx),%edi
f0101050:	89 7d c0             	mov    %edi,-0x40(%ebp)
f0101053:	8b 89 7c 27 10 f0    	mov    -0xfefd884(%ecx),%ecx
f0101059:	bf bf 8c 10 f0       	mov    $0xf0108cbf,%edi
f010105e:	81 ef 0d 70 10 f0    	sub    $0xf010700d,%edi
f0101064:	39 f9                	cmp    %edi,%ecx
f0101066:	73 09                	jae    f0101071 <debuginfo_eip+0x125>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0101068:	81 c1 0d 70 10 f0    	add    $0xf010700d,%ecx
f010106e:	89 4b 08             	mov    %ecx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0101071:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0101074:	8b 4f 08             	mov    0x8(%edi),%ecx
f0101077:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f010107a:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f010107c:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f010107f:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0101082:	eb 0f                	jmp    f0101093 <debuginfo_eip+0x147>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0101084:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0101087:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010108a:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f010108d:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101090:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0101093:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f010109a:	00 
f010109b:	8b 43 08             	mov    0x8(%ebx),%eax
f010109e:	89 04 24             	mov    %eax,(%esp)
f01010a1:	e8 44 09 00 00       	call   f01019ea <strfind>
f01010a6:	2b 43 08             	sub    0x8(%ebx),%eax
f01010a9:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f01010ac:	89 74 24 04          	mov    %esi,0x4(%esp)
f01010b0:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f01010b7:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f01010ba:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f01010bd:	b8 7c 27 10 f0       	mov    $0xf010277c,%eax
f01010c2:	e8 a5 fd ff ff       	call   f0100e6c <stab_binsearch>
	if (lline <= rline) {
f01010c7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01010ca:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f01010cd:	7f 0f                	jg     f01010de <debuginfo_eip+0x192>
		info->eip_line = stabs[lline].n_desc;
f01010cf:	6b c0 0c             	imul   $0xc,%eax,%eax
f01010d2:	0f b7 80 82 27 10 f0 	movzwl -0xfefd87e(%eax),%eax
f01010d9:	89 43 04             	mov    %eax,0x4(%ebx)
f01010dc:	eb 07                	jmp    f01010e5 <debuginfo_eip+0x199>
	} else {
		info->eip_line = -1;
f01010de:	c7 43 04 ff ff ff ff 	movl   $0xffffffff,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01010e5:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01010e8:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f01010eb:	39 c8                	cmp    %ecx,%eax
f01010ed:	7c 5f                	jl     f010114e <debuginfo_eip+0x202>
	       && stabs[lline].n_type != N_SOL
f01010ef:	89 c2                	mov    %eax,%edx
f01010f1:	6b f0 0c             	imul   $0xc,%eax,%esi
f01010f4:	80 be 80 27 10 f0 84 	cmpb   $0x84,-0xfefd880(%esi)
f01010fb:	75 18                	jne    f0101115 <debuginfo_eip+0x1c9>
f01010fd:	eb 30                	jmp    f010112f <debuginfo_eip+0x1e3>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f01010ff:	83 e8 01             	sub    $0x1,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0101102:	39 c1                	cmp    %eax,%ecx
f0101104:	7f 48                	jg     f010114e <debuginfo_eip+0x202>
	       && stabs[lline].n_type != N_SOL
f0101106:	89 c2                	mov    %eax,%edx
f0101108:	8d 34 40             	lea    (%eax,%eax,2),%esi
f010110b:	80 3c b5 80 27 10 f0 	cmpb   $0x84,-0xfefd880(,%esi,4)
f0101112:	84 
f0101113:	74 1a                	je     f010112f <debuginfo_eip+0x1e3>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0101115:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0101118:	8d 14 95 7c 27 10 f0 	lea    -0xfefd884(,%edx,4),%edx
f010111f:	80 7a 04 64          	cmpb   $0x64,0x4(%edx)
f0101123:	75 da                	jne    f01010ff <debuginfo_eip+0x1b3>
f0101125:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f0101129:	74 d4                	je     f01010ff <debuginfo_eip+0x1b3>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f010112b:	39 c8                	cmp    %ecx,%eax
f010112d:	7c 1f                	jl     f010114e <debuginfo_eip+0x202>
f010112f:	6b c0 0c             	imul   $0xc,%eax,%eax
f0101132:	8b 80 7c 27 10 f0    	mov    -0xfefd884(%eax),%eax
f0101138:	ba bf 8c 10 f0       	mov    $0xf0108cbf,%edx
f010113d:	81 ea 0d 70 10 f0    	sub    $0xf010700d,%edx
f0101143:	39 d0                	cmp    %edx,%eax
f0101145:	73 07                	jae    f010114e <debuginfo_eip+0x202>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0101147:	05 0d 70 10 f0       	add    $0xf010700d,%eax
f010114c:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f010114e:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0101151:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0101154:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0101159:	39 ca                	cmp    %ecx,%edx
f010115b:	7d 3e                	jge    f010119b <debuginfo_eip+0x24f>
		for (lline = lfun + 1;
f010115d:	83 c2 01             	add    $0x1,%edx
f0101160:	39 d1                	cmp    %edx,%ecx
f0101162:	7e 37                	jle    f010119b <debuginfo_eip+0x24f>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0101164:	6b f2 0c             	imul   $0xc,%edx,%esi
f0101167:	80 be 80 27 10 f0 a0 	cmpb   $0xa0,-0xfefd880(%esi)
f010116e:	75 2b                	jne    f010119b <debuginfo_eip+0x24f>
		     lline++)
			info->eip_fn_narg++;
f0101170:	83 43 14 01          	addl   $0x1,0x14(%ebx)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0101174:	83 c2 01             	add    $0x1,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0101177:	39 d1                	cmp    %edx,%ecx
f0101179:	7e 1b                	jle    f0101196 <debuginfo_eip+0x24a>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f010117b:	8d 04 52             	lea    (%edx,%edx,2),%eax
f010117e:	80 3c 85 80 27 10 f0 	cmpb   $0xa0,-0xfefd880(,%eax,4)
f0101185:	a0 
f0101186:	74 e8                	je     f0101170 <debuginfo_eip+0x224>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0101188:	b8 00 00 00 00       	mov    $0x0,%eax
f010118d:	eb 0c                	jmp    f010119b <debuginfo_eip+0x24f>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f010118f:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0101194:	eb 05                	jmp    f010119b <debuginfo_eip+0x24f>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0101196:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010119b:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f010119e:	8b 75 f8             	mov    -0x8(%ebp),%esi
f01011a1:	8b 7d fc             	mov    -0x4(%ebp),%edi
f01011a4:	89 ec                	mov    %ebp,%esp
f01011a6:	5d                   	pop    %ebp
f01011a7:	c3                   	ret    
	...

f01011b0 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f01011b0:	55                   	push   %ebp
f01011b1:	89 e5                	mov    %esp,%ebp
f01011b3:	57                   	push   %edi
f01011b4:	56                   	push   %esi
f01011b5:	53                   	push   %ebx
f01011b6:	83 ec 3c             	sub    $0x3c,%esp
f01011b9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01011bc:	89 d7                	mov    %edx,%edi
f01011be:	8b 45 08             	mov    0x8(%ebp),%eax
f01011c1:	89 45 dc             	mov    %eax,-0x24(%ebp)
f01011c4:	8b 45 0c             	mov    0xc(%ebp),%eax
f01011c7:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01011ca:	8b 5d 14             	mov    0x14(%ebp),%ebx
f01011cd:	8b 75 18             	mov    0x18(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f01011d0:	b8 00 00 00 00       	mov    $0x0,%eax
f01011d5:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f01011d8:	72 11                	jb     f01011eb <printnum+0x3b>
f01011da:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01011dd:	39 45 10             	cmp    %eax,0x10(%ebp)
f01011e0:	76 09                	jbe    f01011eb <printnum+0x3b>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f01011e2:	83 eb 01             	sub    $0x1,%ebx
f01011e5:	85 db                	test   %ebx,%ebx
f01011e7:	7f 51                	jg     f010123a <printnum+0x8a>
f01011e9:	eb 5e                	jmp    f0101249 <printnum+0x99>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
f01011eb:	89 74 24 10          	mov    %esi,0x10(%esp)
f01011ef:	83 eb 01             	sub    $0x1,%ebx
f01011f2:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f01011f6:	8b 45 10             	mov    0x10(%ebp),%eax
f01011f9:	89 44 24 08          	mov    %eax,0x8(%esp)
f01011fd:	8b 5c 24 08          	mov    0x8(%esp),%ebx
f0101201:	8b 74 24 0c          	mov    0xc(%esp),%esi
f0101205:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f010120c:	00 
f010120d:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0101210:	89 04 24             	mov    %eax,(%esp)
f0101213:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101216:	89 44 24 04          	mov    %eax,0x4(%esp)
f010121a:	e8 41 0a 00 00       	call   f0101c60 <__udivdi3>
f010121f:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0101223:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0101227:	89 04 24             	mov    %eax,(%esp)
f010122a:	89 54 24 04          	mov    %edx,0x4(%esp)
f010122e:	89 fa                	mov    %edi,%edx
f0101230:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101233:	e8 78 ff ff ff       	call   f01011b0 <printnum>
f0101238:	eb 0f                	jmp    f0101249 <printnum+0x99>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f010123a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010123e:	89 34 24             	mov    %esi,(%esp)
f0101241:	ff 55 e4             	call   *-0x1c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0101244:	83 eb 01             	sub    $0x1,%ebx
f0101247:	75 f1                	jne    f010123a <printnum+0x8a>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0101249:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010124d:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0101251:	8b 45 10             	mov    0x10(%ebp),%eax
f0101254:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101258:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f010125f:	00 
f0101260:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0101263:	89 04 24             	mov    %eax,(%esp)
f0101266:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101269:	89 44 24 04          	mov    %eax,0x4(%esp)
f010126d:	e8 1e 0b 00 00       	call   f0101d90 <__umoddi3>
f0101272:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101276:	0f be 80 69 25 10 f0 	movsbl -0xfefda97(%eax),%eax
f010127d:	89 04 24             	mov    %eax,(%esp)
f0101280:	ff 55 e4             	call   *-0x1c(%ebp)
}
f0101283:	83 c4 3c             	add    $0x3c,%esp
f0101286:	5b                   	pop    %ebx
f0101287:	5e                   	pop    %esi
f0101288:	5f                   	pop    %edi
f0101289:	5d                   	pop    %ebp
f010128a:	c3                   	ret    

f010128b <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f010128b:	55                   	push   %ebp
f010128c:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f010128e:	83 fa 01             	cmp    $0x1,%edx
f0101291:	7e 0e                	jle    f01012a1 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0101293:	8b 10                	mov    (%eax),%edx
f0101295:	8d 4a 08             	lea    0x8(%edx),%ecx
f0101298:	89 08                	mov    %ecx,(%eax)
f010129a:	8b 02                	mov    (%edx),%eax
f010129c:	8b 52 04             	mov    0x4(%edx),%edx
f010129f:	eb 22                	jmp    f01012c3 <getuint+0x38>
	else if (lflag)
f01012a1:	85 d2                	test   %edx,%edx
f01012a3:	74 10                	je     f01012b5 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f01012a5:	8b 10                	mov    (%eax),%edx
f01012a7:	8d 4a 04             	lea    0x4(%edx),%ecx
f01012aa:	89 08                	mov    %ecx,(%eax)
f01012ac:	8b 02                	mov    (%edx),%eax
f01012ae:	ba 00 00 00 00       	mov    $0x0,%edx
f01012b3:	eb 0e                	jmp    f01012c3 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f01012b5:	8b 10                	mov    (%eax),%edx
f01012b7:	8d 4a 04             	lea    0x4(%edx),%ecx
f01012ba:	89 08                	mov    %ecx,(%eax)
f01012bc:	8b 02                	mov    (%edx),%eax
f01012be:	ba 00 00 00 00       	mov    $0x0,%edx
}
f01012c3:	5d                   	pop    %ebp
f01012c4:	c3                   	ret    

f01012c5 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f01012c5:	55                   	push   %ebp
f01012c6:	89 e5                	mov    %esp,%ebp
f01012c8:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f01012cb:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f01012cf:	8b 10                	mov    (%eax),%edx
f01012d1:	3b 50 04             	cmp    0x4(%eax),%edx
f01012d4:	73 0a                	jae    f01012e0 <sprintputch+0x1b>
		*b->buf++ = ch;
f01012d6:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01012d9:	88 0a                	mov    %cl,(%edx)
f01012db:	83 c2 01             	add    $0x1,%edx
f01012de:	89 10                	mov    %edx,(%eax)
}
f01012e0:	5d                   	pop    %ebp
f01012e1:	c3                   	ret    

f01012e2 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f01012e2:	55                   	push   %ebp
f01012e3:	89 e5                	mov    %esp,%ebp
f01012e5:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f01012e8:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f01012eb:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01012ef:	8b 45 10             	mov    0x10(%ebp),%eax
f01012f2:	89 44 24 08          	mov    %eax,0x8(%esp)
f01012f6:	8b 45 0c             	mov    0xc(%ebp),%eax
f01012f9:	89 44 24 04          	mov    %eax,0x4(%esp)
f01012fd:	8b 45 08             	mov    0x8(%ebp),%eax
f0101300:	89 04 24             	mov    %eax,(%esp)
f0101303:	e8 02 00 00 00       	call   f010130a <vprintfmt>
	va_end(ap);
}
f0101308:	c9                   	leave  
f0101309:	c3                   	ret    

f010130a <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f010130a:	55                   	push   %ebp
f010130b:	89 e5                	mov    %esp,%ebp
f010130d:	57                   	push   %edi
f010130e:	56                   	push   %esi
f010130f:	53                   	push   %ebx
f0101310:	83 ec 4c             	sub    $0x4c,%esp
f0101313:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101316:	8b 75 10             	mov    0x10(%ebp),%esi
f0101319:	eb 12                	jmp    f010132d <vprintfmt+0x23>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f010131b:	85 c0                	test   %eax,%eax
f010131d:	0f 84 a9 03 00 00    	je     f01016cc <vprintfmt+0x3c2>
				return;
			putch(ch, putdat);
f0101323:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101327:	89 04 24             	mov    %eax,(%esp)
f010132a:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f010132d:	0f b6 06             	movzbl (%esi),%eax
f0101330:	83 c6 01             	add    $0x1,%esi
f0101333:	83 f8 25             	cmp    $0x25,%eax
f0101336:	75 e3                	jne    f010131b <vprintfmt+0x11>
f0101338:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
f010133c:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
f0101343:	bf ff ff ff ff       	mov    $0xffffffff,%edi
f0101348:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
f010134f:	b9 00 00 00 00       	mov    $0x0,%ecx
f0101354:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0101357:	eb 2b                	jmp    f0101384 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101359:	8b 75 e0             	mov    -0x20(%ebp),%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f010135c:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
f0101360:	eb 22                	jmp    f0101384 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101362:	8b 75 e0             	mov    -0x20(%ebp),%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0101365:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
f0101369:	eb 19                	jmp    f0101384 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010136b:	8b 75 e0             	mov    -0x20(%ebp),%esi
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
f010136e:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f0101375:	eb 0d                	jmp    f0101384 <vprintfmt+0x7a>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f0101377:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010137a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010137d:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101384:	0f b6 06             	movzbl (%esi),%eax
f0101387:	0f b6 d0             	movzbl %al,%edx
f010138a:	8d 7e 01             	lea    0x1(%esi),%edi
f010138d:	89 7d e0             	mov    %edi,-0x20(%ebp)
f0101390:	83 e8 23             	sub    $0x23,%eax
f0101393:	3c 55                	cmp    $0x55,%al
f0101395:	0f 87 0b 03 00 00    	ja     f01016a6 <vprintfmt+0x39c>
f010139b:	0f b6 c0             	movzbl %al,%eax
f010139e:	ff 24 85 f8 25 10 f0 	jmp    *-0xfefda08(,%eax,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f01013a5:	83 ea 30             	sub    $0x30,%edx
f01013a8:	89 55 d4             	mov    %edx,-0x2c(%ebp)
				ch = *fmt;
f01013ab:	0f be 46 01          	movsbl 0x1(%esi),%eax
				if (ch < '0' || ch > '9')
f01013af:	8d 50 d0             	lea    -0x30(%eax),%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01013b2:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
f01013b5:	83 fa 09             	cmp    $0x9,%edx
f01013b8:	77 4a                	ja     f0101404 <vprintfmt+0xfa>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01013ba:	8b 7d d4             	mov    -0x2c(%ebp),%edi
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f01013bd:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
f01013c0:	8d 14 bf             	lea    (%edi,%edi,4),%edx
f01013c3:	8d 7c 50 d0          	lea    -0x30(%eax,%edx,2),%edi
				ch = *fmt;
f01013c7:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f01013ca:	8d 50 d0             	lea    -0x30(%eax),%edx
f01013cd:	83 fa 09             	cmp    $0x9,%edx
f01013d0:	76 eb                	jbe    f01013bd <vprintfmt+0xb3>
f01013d2:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f01013d5:	eb 2d                	jmp    f0101404 <vprintfmt+0xfa>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f01013d7:	8b 45 14             	mov    0x14(%ebp),%eax
f01013da:	8d 50 04             	lea    0x4(%eax),%edx
f01013dd:	89 55 14             	mov    %edx,0x14(%ebp)
f01013e0:	8b 00                	mov    (%eax),%eax
f01013e2:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01013e5:	8b 75 e0             	mov    -0x20(%ebp),%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f01013e8:	eb 1a                	jmp    f0101404 <vprintfmt+0xfa>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01013ea:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case '*':
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
f01013ed:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01013f1:	79 91                	jns    f0101384 <vprintfmt+0x7a>
f01013f3:	e9 73 ff ff ff       	jmp    f010136b <vprintfmt+0x61>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01013f8:	8b 75 e0             	mov    -0x20(%ebp),%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f01013fb:	c7 45 dc 01 00 00 00 	movl   $0x1,-0x24(%ebp)
			goto reswitch;
f0101402:	eb 80                	jmp    f0101384 <vprintfmt+0x7a>

		process_precision:
			if (width < 0)
f0101404:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0101408:	0f 89 76 ff ff ff    	jns    f0101384 <vprintfmt+0x7a>
f010140e:	e9 64 ff ff ff       	jmp    f0101377 <vprintfmt+0x6d>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0101413:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101416:	8b 75 e0             	mov    -0x20(%ebp),%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0101419:	e9 66 ff ff ff       	jmp    f0101384 <vprintfmt+0x7a>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f010141e:	8b 45 14             	mov    0x14(%ebp),%eax
f0101421:	8d 50 04             	lea    0x4(%eax),%edx
f0101424:	89 55 14             	mov    %edx,0x14(%ebp)
f0101427:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010142b:	8b 00                	mov    (%eax),%eax
f010142d:	89 04 24             	mov    %eax,(%esp)
f0101430:	ff 55 08             	call   *0x8(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101433:	8b 75 e0             	mov    -0x20(%ebp),%esi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0101436:	e9 f2 fe ff ff       	jmp    f010132d <vprintfmt+0x23>

		// error message
		case 'e':
			err = va_arg(ap, int);
f010143b:	8b 45 14             	mov    0x14(%ebp),%eax
f010143e:	8d 50 04             	lea    0x4(%eax),%edx
f0101441:	89 55 14             	mov    %edx,0x14(%ebp)
f0101444:	8b 00                	mov    (%eax),%eax
f0101446:	89 c2                	mov    %eax,%edx
f0101448:	c1 fa 1f             	sar    $0x1f,%edx
f010144b:	31 d0                	xor    %edx,%eax
f010144d:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f010144f:	83 f8 06             	cmp    $0x6,%eax
f0101452:	7f 0b                	jg     f010145f <vprintfmt+0x155>
f0101454:	8b 14 85 50 27 10 f0 	mov    -0xfefd8b0(,%eax,4),%edx
f010145b:	85 d2                	test   %edx,%edx
f010145d:	75 23                	jne    f0101482 <vprintfmt+0x178>
				printfmt(putch, putdat, "error %d", err);
f010145f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101463:	c7 44 24 08 81 25 10 	movl   $0xf0102581,0x8(%esp)
f010146a:	f0 
f010146b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010146f:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101472:	89 3c 24             	mov    %edi,(%esp)
f0101475:	e8 68 fe ff ff       	call   f01012e2 <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010147a:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f010147d:	e9 ab fe ff ff       	jmp    f010132d <vprintfmt+0x23>
			else
				printfmt(putch, putdat, "%s", p);
f0101482:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101486:	c7 44 24 08 8a 25 10 	movl   $0xf010258a,0x8(%esp)
f010148d:	f0 
f010148e:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101492:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101495:	89 3c 24             	mov    %edi,(%esp)
f0101498:	e8 45 fe ff ff       	call   f01012e2 <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010149d:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01014a0:	e9 88 fe ff ff       	jmp    f010132d <vprintfmt+0x23>
f01014a5:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01014a8:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01014ab:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f01014ae:	8b 45 14             	mov    0x14(%ebp),%eax
f01014b1:	8d 50 04             	lea    0x4(%eax),%edx
f01014b4:	89 55 14             	mov    %edx,0x14(%ebp)
f01014b7:	8b 30                	mov    (%eax),%esi
				p = "(null)";
f01014b9:	85 f6                	test   %esi,%esi
f01014bb:	ba 7a 25 10 f0       	mov    $0xf010257a,%edx
f01014c0:	0f 44 f2             	cmove  %edx,%esi
			if (width > 0 && padc != '-')
f01014c3:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f01014c7:	7e 06                	jle    f01014cf <vprintfmt+0x1c5>
f01014c9:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
f01014cd:	75 10                	jne    f01014df <vprintfmt+0x1d5>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01014cf:	0f be 06             	movsbl (%esi),%eax
f01014d2:	83 c6 01             	add    $0x1,%esi
f01014d5:	85 c0                	test   %eax,%eax
f01014d7:	0f 85 86 00 00 00    	jne    f0101563 <vprintfmt+0x259>
f01014dd:	eb 76                	jmp    f0101555 <vprintfmt+0x24b>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01014df:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01014e3:	89 34 24             	mov    %esi,(%esp)
f01014e6:	e8 60 03 00 00       	call   f010184b <strnlen>
f01014eb:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01014ee:	29 c2                	sub    %eax,%edx
f01014f0:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01014f3:	85 d2                	test   %edx,%edx
f01014f5:	7e d8                	jle    f01014cf <vprintfmt+0x1c5>
					putch(padc, putdat);
f01014f7:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
f01014fb:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f01014fe:	89 d6                	mov    %edx,%esi
f0101500:	89 7d d0             	mov    %edi,-0x30(%ebp)
f0101503:	89 c7                	mov    %eax,%edi
f0101505:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101509:	89 3c 24             	mov    %edi,(%esp)
f010150c:	ff 55 08             	call   *0x8(%ebp)
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010150f:	83 ee 01             	sub    $0x1,%esi
f0101512:	75 f1                	jne    f0101505 <vprintfmt+0x1fb>
f0101514:	89 75 e4             	mov    %esi,-0x1c(%ebp)
f0101517:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f010151a:	8b 7d d0             	mov    -0x30(%ebp),%edi
f010151d:	eb b0                	jmp    f01014cf <vprintfmt+0x1c5>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f010151f:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0101523:	74 18                	je     f010153d <vprintfmt+0x233>
f0101525:	8d 50 e0             	lea    -0x20(%eax),%edx
f0101528:	83 fa 5e             	cmp    $0x5e,%edx
f010152b:	76 10                	jbe    f010153d <vprintfmt+0x233>
					putch('?', putdat);
f010152d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101531:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0101538:	ff 55 08             	call   *0x8(%ebp)
f010153b:	eb 0a                	jmp    f0101547 <vprintfmt+0x23d>
				else
					putch(ch, putdat);
f010153d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101541:	89 04 24             	mov    %eax,(%esp)
f0101544:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101547:	83 6d e4 01          	subl   $0x1,-0x1c(%ebp)
f010154b:	0f be 06             	movsbl (%esi),%eax
f010154e:	83 c6 01             	add    $0x1,%esi
f0101551:	85 c0                	test   %eax,%eax
f0101553:	75 0e                	jne    f0101563 <vprintfmt+0x259>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101555:	8b 75 e0             	mov    -0x20(%ebp),%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101558:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f010155c:	7f 16                	jg     f0101574 <vprintfmt+0x26a>
f010155e:	e9 ca fd ff ff       	jmp    f010132d <vprintfmt+0x23>
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0101563:	85 ff                	test   %edi,%edi
f0101565:	78 b8                	js     f010151f <vprintfmt+0x215>
f0101567:	83 ef 01             	sub    $0x1,%edi
f010156a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101570:	79 ad                	jns    f010151f <vprintfmt+0x215>
f0101572:	eb e1                	jmp    f0101555 <vprintfmt+0x24b>
f0101574:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0101577:	8b 7d 08             	mov    0x8(%ebp),%edi
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f010157a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010157e:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0101585:	ff d7                	call   *%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0101587:	83 ee 01             	sub    $0x1,%esi
f010158a:	75 ee                	jne    f010157a <vprintfmt+0x270>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010158c:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010158f:	e9 99 fd ff ff       	jmp    f010132d <vprintfmt+0x23>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0101594:	83 f9 01             	cmp    $0x1,%ecx
f0101597:	7e 10                	jle    f01015a9 <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f0101599:	8b 45 14             	mov    0x14(%ebp),%eax
f010159c:	8d 50 08             	lea    0x8(%eax),%edx
f010159f:	89 55 14             	mov    %edx,0x14(%ebp)
f01015a2:	8b 30                	mov    (%eax),%esi
f01015a4:	8b 78 04             	mov    0x4(%eax),%edi
f01015a7:	eb 26                	jmp    f01015cf <vprintfmt+0x2c5>
	else if (lflag)
f01015a9:	85 c9                	test   %ecx,%ecx
f01015ab:	74 12                	je     f01015bf <vprintfmt+0x2b5>
		return va_arg(*ap, long);
f01015ad:	8b 45 14             	mov    0x14(%ebp),%eax
f01015b0:	8d 50 04             	lea    0x4(%eax),%edx
f01015b3:	89 55 14             	mov    %edx,0x14(%ebp)
f01015b6:	8b 30                	mov    (%eax),%esi
f01015b8:	89 f7                	mov    %esi,%edi
f01015ba:	c1 ff 1f             	sar    $0x1f,%edi
f01015bd:	eb 10                	jmp    f01015cf <vprintfmt+0x2c5>
	else
		return va_arg(*ap, int);
f01015bf:	8b 45 14             	mov    0x14(%ebp),%eax
f01015c2:	8d 50 04             	lea    0x4(%eax),%edx
f01015c5:	89 55 14             	mov    %edx,0x14(%ebp)
f01015c8:	8b 30                	mov    (%eax),%esi
f01015ca:	89 f7                	mov    %esi,%edi
f01015cc:	c1 ff 1f             	sar    $0x1f,%edi
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f01015cf:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f01015d4:	85 ff                	test   %edi,%edi
f01015d6:	0f 89 8c 00 00 00    	jns    f0101668 <vprintfmt+0x35e>
				putch('-', putdat);
f01015dc:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01015e0:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f01015e7:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f01015ea:	f7 de                	neg    %esi
f01015ec:	83 d7 00             	adc    $0x0,%edi
f01015ef:	f7 df                	neg    %edi
			}
			base = 10;
f01015f1:	b8 0a 00 00 00       	mov    $0xa,%eax
f01015f6:	eb 70                	jmp    f0101668 <vprintfmt+0x35e>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f01015f8:	89 ca                	mov    %ecx,%edx
f01015fa:	8d 45 14             	lea    0x14(%ebp),%eax
f01015fd:	e8 89 fc ff ff       	call   f010128b <getuint>
f0101602:	89 c6                	mov    %eax,%esi
f0101604:	89 d7                	mov    %edx,%edi
			base = 10;
f0101606:	b8 0a 00 00 00       	mov    $0xa,%eax
			goto number;
f010160b:	eb 5b                	jmp    f0101668 <vprintfmt+0x35e>
			// Replace this with your code.
			//putch('0', putdat);
			//putch('X', putdat);
			//putch('X', putdat);
			//break;
			num = getuint(&ap, lflag);
f010160d:	89 ca                	mov    %ecx,%edx
f010160f:	8d 45 14             	lea    0x14(%ebp),%eax
f0101612:	e8 74 fc ff ff       	call   f010128b <getuint>
f0101617:	89 c6                	mov    %eax,%esi
f0101619:	89 d7                	mov    %edx,%edi
			base = 8;
f010161b:	b8 08 00 00 00       	mov    $0x8,%eax
			goto number;
f0101620:	eb 46                	jmp    f0101668 <vprintfmt+0x35e>
		// pointer
		case 'p':
			putch('0', putdat);
f0101622:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101626:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f010162d:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f0101630:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101634:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f010163b:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f010163e:	8b 45 14             	mov    0x14(%ebp),%eax
f0101641:	8d 50 04             	lea    0x4(%eax),%edx
f0101644:	89 55 14             	mov    %edx,0x14(%ebp)
			goto number;
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0101647:	8b 30                	mov    (%eax),%esi
f0101649:	bf 00 00 00 00       	mov    $0x0,%edi
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f010164e:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f0101653:	eb 13                	jmp    f0101668 <vprintfmt+0x35e>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0101655:	89 ca                	mov    %ecx,%edx
f0101657:	8d 45 14             	lea    0x14(%ebp),%eax
f010165a:	e8 2c fc ff ff       	call   f010128b <getuint>
f010165f:	89 c6                	mov    %eax,%esi
f0101661:	89 d7                	mov    %edx,%edi
			base = 16;
f0101663:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f0101668:	0f be 55 d8          	movsbl -0x28(%ebp),%edx
f010166c:	89 54 24 10          	mov    %edx,0x10(%esp)
f0101670:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0101673:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101677:	89 44 24 08          	mov    %eax,0x8(%esp)
f010167b:	89 34 24             	mov    %esi,(%esp)
f010167e:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101682:	89 da                	mov    %ebx,%edx
f0101684:	8b 45 08             	mov    0x8(%ebp),%eax
f0101687:	e8 24 fb ff ff       	call   f01011b0 <printnum>
			break;
f010168c:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010168f:	e9 99 fc ff ff       	jmp    f010132d <vprintfmt+0x23>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0101694:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101698:	89 14 24             	mov    %edx,(%esp)
f010169b:	ff 55 08             	call   *0x8(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010169e:	8b 75 e0             	mov    -0x20(%ebp),%esi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f01016a1:	e9 87 fc ff ff       	jmp    f010132d <vprintfmt+0x23>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f01016a6:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01016aa:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f01016b1:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f01016b4:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
f01016b8:	0f 84 6f fc ff ff    	je     f010132d <vprintfmt+0x23>
f01016be:	83 ee 01             	sub    $0x1,%esi
f01016c1:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
f01016c5:	75 f7                	jne    f01016be <vprintfmt+0x3b4>
f01016c7:	e9 61 fc ff ff       	jmp    f010132d <vprintfmt+0x23>
				/* do nothing */;
			break;
		}
	}
}
f01016cc:	83 c4 4c             	add    $0x4c,%esp
f01016cf:	5b                   	pop    %ebx
f01016d0:	5e                   	pop    %esi
f01016d1:	5f                   	pop    %edi
f01016d2:	5d                   	pop    %ebp
f01016d3:	c3                   	ret    

f01016d4 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01016d4:	55                   	push   %ebp
f01016d5:	89 e5                	mov    %esp,%ebp
f01016d7:	83 ec 28             	sub    $0x28,%esp
f01016da:	8b 45 08             	mov    0x8(%ebp),%eax
f01016dd:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01016e0:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01016e3:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01016e7:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01016ea:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01016f1:	85 c0                	test   %eax,%eax
f01016f3:	74 30                	je     f0101725 <vsnprintf+0x51>
f01016f5:	85 d2                	test   %edx,%edx
f01016f7:	7e 2c                	jle    f0101725 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01016f9:	8b 45 14             	mov    0x14(%ebp),%eax
f01016fc:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101700:	8b 45 10             	mov    0x10(%ebp),%eax
f0101703:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101707:	8d 45 ec             	lea    -0x14(%ebp),%eax
f010170a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010170e:	c7 04 24 c5 12 10 f0 	movl   $0xf01012c5,(%esp)
f0101715:	e8 f0 fb ff ff       	call   f010130a <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f010171a:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010171d:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0101720:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101723:	eb 05                	jmp    f010172a <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0101725:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f010172a:	c9                   	leave  
f010172b:	c3                   	ret    

f010172c <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010172c:	55                   	push   %ebp
f010172d:	89 e5                	mov    %esp,%ebp
f010172f:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0101732:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0101735:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101739:	8b 45 10             	mov    0x10(%ebp),%eax
f010173c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101740:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101743:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101747:	8b 45 08             	mov    0x8(%ebp),%eax
f010174a:	89 04 24             	mov    %eax,(%esp)
f010174d:	e8 82 ff ff ff       	call   f01016d4 <vsnprintf>
	va_end(ap);

	return rc;
}
f0101752:	c9                   	leave  
f0101753:	c3                   	ret    
	...

f0101760 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0101760:	55                   	push   %ebp
f0101761:	89 e5                	mov    %esp,%ebp
f0101763:	57                   	push   %edi
f0101764:	56                   	push   %esi
f0101765:	53                   	push   %ebx
f0101766:	83 ec 1c             	sub    $0x1c,%esp
f0101769:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010176c:	85 c0                	test   %eax,%eax
f010176e:	74 10                	je     f0101780 <readline+0x20>
		cprintf("%s", prompt);
f0101770:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101774:	c7 04 24 8a 25 10 f0 	movl   $0xf010258a,(%esp)
f010177b:	e8 d2 f6 ff ff       	call   f0100e52 <cprintf>

	i = 0;
	echoing = iscons(0);
f0101780:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101787:	e8 8e ee ff ff       	call   f010061a <iscons>
f010178c:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010178e:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0101793:	e8 71 ee ff ff       	call   f0100609 <getchar>
f0101798:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010179a:	85 c0                	test   %eax,%eax
f010179c:	79 17                	jns    f01017b5 <readline+0x55>
			cprintf("read error: %e\n", c);
f010179e:	89 44 24 04          	mov    %eax,0x4(%esp)
f01017a2:	c7 04 24 6c 27 10 f0 	movl   $0xf010276c,(%esp)
f01017a9:	e8 a4 f6 ff ff       	call   f0100e52 <cprintf>
			return NULL;
f01017ae:	b8 00 00 00 00       	mov    $0x0,%eax
f01017b3:	eb 6d                	jmp    f0101822 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01017b5:	83 f8 08             	cmp    $0x8,%eax
f01017b8:	74 05                	je     f01017bf <readline+0x5f>
f01017ba:	83 f8 7f             	cmp    $0x7f,%eax
f01017bd:	75 19                	jne    f01017d8 <readline+0x78>
f01017bf:	85 f6                	test   %esi,%esi
f01017c1:	7e 15                	jle    f01017d8 <readline+0x78>
			if (echoing)
f01017c3:	85 ff                	test   %edi,%edi
f01017c5:	74 0c                	je     f01017d3 <readline+0x73>
				cputchar('\b');
f01017c7:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f01017ce:	e8 26 ee ff ff       	call   f01005f9 <cputchar>
			i--;
f01017d3:	83 ee 01             	sub    $0x1,%esi
f01017d6:	eb bb                	jmp    f0101793 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01017d8:	83 fb 1f             	cmp    $0x1f,%ebx
f01017db:	7e 1f                	jle    f01017fc <readline+0x9c>
f01017dd:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01017e3:	7f 17                	jg     f01017fc <readline+0x9c>
			if (echoing)
f01017e5:	85 ff                	test   %edi,%edi
f01017e7:	74 08                	je     f01017f1 <readline+0x91>
				cputchar(c);
f01017e9:	89 1c 24             	mov    %ebx,(%esp)
f01017ec:	e8 08 ee ff ff       	call   f01005f9 <cputchar>
			buf[i++] = c;
f01017f1:	88 9e 80 35 11 f0    	mov    %bl,-0xfeeca80(%esi)
f01017f7:	83 c6 01             	add    $0x1,%esi
f01017fa:	eb 97                	jmp    f0101793 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f01017fc:	83 fb 0a             	cmp    $0xa,%ebx
f01017ff:	74 05                	je     f0101806 <readline+0xa6>
f0101801:	83 fb 0d             	cmp    $0xd,%ebx
f0101804:	75 8d                	jne    f0101793 <readline+0x33>
			if (echoing)
f0101806:	85 ff                	test   %edi,%edi
f0101808:	74 0c                	je     f0101816 <readline+0xb6>
				cputchar('\n');
f010180a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0101811:	e8 e3 ed ff ff       	call   f01005f9 <cputchar>
			buf[i] = 0;
f0101816:	c6 86 80 35 11 f0 00 	movb   $0x0,-0xfeeca80(%esi)
			return buf;
f010181d:	b8 80 35 11 f0       	mov    $0xf0113580,%eax
		}
	}
}
f0101822:	83 c4 1c             	add    $0x1c,%esp
f0101825:	5b                   	pop    %ebx
f0101826:	5e                   	pop    %esi
f0101827:	5f                   	pop    %edi
f0101828:	5d                   	pop    %ebp
f0101829:	c3                   	ret    
f010182a:	00 00                	add    %al,(%eax)
f010182c:	00 00                	add    %al,(%eax)
	...

f0101830 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0101830:	55                   	push   %ebp
f0101831:	89 e5                	mov    %esp,%ebp
f0101833:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0101836:	b8 00 00 00 00       	mov    $0x0,%eax
f010183b:	80 3a 00             	cmpb   $0x0,(%edx)
f010183e:	74 09                	je     f0101849 <strlen+0x19>
		n++;
f0101840:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0101843:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0101847:	75 f7                	jne    f0101840 <strlen+0x10>
		n++;
	return n;
}
f0101849:	5d                   	pop    %ebp
f010184a:	c3                   	ret    

f010184b <strnlen>:

int
strnlen(const char *s, size_t size)
{
f010184b:	55                   	push   %ebp
f010184c:	89 e5                	mov    %esp,%ebp
f010184e:	53                   	push   %ebx
f010184f:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0101852:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0101855:	b8 00 00 00 00       	mov    $0x0,%eax
f010185a:	85 c9                	test   %ecx,%ecx
f010185c:	74 1a                	je     f0101878 <strnlen+0x2d>
f010185e:	80 3b 00             	cmpb   $0x0,(%ebx)
f0101861:	74 15                	je     f0101878 <strnlen+0x2d>
f0101863:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
f0101868:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f010186a:	39 ca                	cmp    %ecx,%edx
f010186c:	74 0a                	je     f0101878 <strnlen+0x2d>
f010186e:	83 c2 01             	add    $0x1,%edx
f0101871:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
f0101876:	75 f0                	jne    f0101868 <strnlen+0x1d>
		n++;
	return n;
}
f0101878:	5b                   	pop    %ebx
f0101879:	5d                   	pop    %ebp
f010187a:	c3                   	ret    

f010187b <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f010187b:	55                   	push   %ebp
f010187c:	89 e5                	mov    %esp,%ebp
f010187e:	53                   	push   %ebx
f010187f:	8b 45 08             	mov    0x8(%ebp),%eax
f0101882:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0101885:	ba 00 00 00 00       	mov    $0x0,%edx
f010188a:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f010188e:	88 0c 10             	mov    %cl,(%eax,%edx,1)
f0101891:	83 c2 01             	add    $0x1,%edx
f0101894:	84 c9                	test   %cl,%cl
f0101896:	75 f2                	jne    f010188a <strcpy+0xf>
		/* do nothing */;
	return ret;
}
f0101898:	5b                   	pop    %ebx
f0101899:	5d                   	pop    %ebp
f010189a:	c3                   	ret    

f010189b <strcat>:

char *
strcat(char *dst, const char *src)
{
f010189b:	55                   	push   %ebp
f010189c:	89 e5                	mov    %esp,%ebp
f010189e:	53                   	push   %ebx
f010189f:	83 ec 08             	sub    $0x8,%esp
f01018a2:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f01018a5:	89 1c 24             	mov    %ebx,(%esp)
f01018a8:	e8 83 ff ff ff       	call   f0101830 <strlen>
	strcpy(dst + len, src);
f01018ad:	8b 55 0c             	mov    0xc(%ebp),%edx
f01018b0:	89 54 24 04          	mov    %edx,0x4(%esp)
f01018b4:	01 d8                	add    %ebx,%eax
f01018b6:	89 04 24             	mov    %eax,(%esp)
f01018b9:	e8 bd ff ff ff       	call   f010187b <strcpy>
	return dst;
}
f01018be:	89 d8                	mov    %ebx,%eax
f01018c0:	83 c4 08             	add    $0x8,%esp
f01018c3:	5b                   	pop    %ebx
f01018c4:	5d                   	pop    %ebp
f01018c5:	c3                   	ret    

f01018c6 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f01018c6:	55                   	push   %ebp
f01018c7:	89 e5                	mov    %esp,%ebp
f01018c9:	56                   	push   %esi
f01018ca:	53                   	push   %ebx
f01018cb:	8b 45 08             	mov    0x8(%ebp),%eax
f01018ce:	8b 55 0c             	mov    0xc(%ebp),%edx
f01018d1:	8b 75 10             	mov    0x10(%ebp),%esi
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01018d4:	85 f6                	test   %esi,%esi
f01018d6:	74 18                	je     f01018f0 <strncpy+0x2a>
f01018d8:	b9 00 00 00 00       	mov    $0x0,%ecx
		*dst++ = *src;
f01018dd:	0f b6 1a             	movzbl (%edx),%ebx
f01018e0:	88 1c 08             	mov    %bl,(%eax,%ecx,1)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f01018e3:	80 3a 01             	cmpb   $0x1,(%edx)
f01018e6:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f01018e9:	83 c1 01             	add    $0x1,%ecx
f01018ec:	39 f1                	cmp    %esi,%ecx
f01018ee:	75 ed                	jne    f01018dd <strncpy+0x17>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f01018f0:	5b                   	pop    %ebx
f01018f1:	5e                   	pop    %esi
f01018f2:	5d                   	pop    %ebp
f01018f3:	c3                   	ret    

f01018f4 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f01018f4:	55                   	push   %ebp
f01018f5:	89 e5                	mov    %esp,%ebp
f01018f7:	57                   	push   %edi
f01018f8:	56                   	push   %esi
f01018f9:	53                   	push   %ebx
f01018fa:	8b 7d 08             	mov    0x8(%ebp),%edi
f01018fd:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101900:	8b 75 10             	mov    0x10(%ebp),%esi
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0101903:	89 f8                	mov    %edi,%eax
f0101905:	85 f6                	test   %esi,%esi
f0101907:	74 2b                	je     f0101934 <strlcpy+0x40>
		while (--size > 0 && *src != '\0')
f0101909:	83 fe 01             	cmp    $0x1,%esi
f010190c:	74 23                	je     f0101931 <strlcpy+0x3d>
f010190e:	0f b6 0b             	movzbl (%ebx),%ecx
f0101911:	84 c9                	test   %cl,%cl
f0101913:	74 1c                	je     f0101931 <strlcpy+0x3d>
	}
	return ret;
}

size_t
strlcpy(char *dst, const char *src, size_t size)
f0101915:	83 ee 02             	sub    $0x2,%esi
f0101918:	ba 00 00 00 00       	mov    $0x0,%edx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f010191d:	88 08                	mov    %cl,(%eax)
f010191f:	83 c0 01             	add    $0x1,%eax
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0101922:	39 f2                	cmp    %esi,%edx
f0101924:	74 0b                	je     f0101931 <strlcpy+0x3d>
f0101926:	83 c2 01             	add    $0x1,%edx
f0101929:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f010192d:	84 c9                	test   %cl,%cl
f010192f:	75 ec                	jne    f010191d <strlcpy+0x29>
			*dst++ = *src++;
		*dst = '\0';
f0101931:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0101934:	29 f8                	sub    %edi,%eax
}
f0101936:	5b                   	pop    %ebx
f0101937:	5e                   	pop    %esi
f0101938:	5f                   	pop    %edi
f0101939:	5d                   	pop    %ebp
f010193a:	c3                   	ret    

f010193b <strcmp>:

int
strcmp(const char *p, const char *q)
{
f010193b:	55                   	push   %ebp
f010193c:	89 e5                	mov    %esp,%ebp
f010193e:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101941:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0101944:	0f b6 01             	movzbl (%ecx),%eax
f0101947:	84 c0                	test   %al,%al
f0101949:	74 16                	je     f0101961 <strcmp+0x26>
f010194b:	3a 02                	cmp    (%edx),%al
f010194d:	75 12                	jne    f0101961 <strcmp+0x26>
		p++, q++;
f010194f:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0101952:	0f b6 41 01          	movzbl 0x1(%ecx),%eax
f0101956:	84 c0                	test   %al,%al
f0101958:	74 07                	je     f0101961 <strcmp+0x26>
f010195a:	83 c1 01             	add    $0x1,%ecx
f010195d:	3a 02                	cmp    (%edx),%al
f010195f:	74 ee                	je     f010194f <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0101961:	0f b6 c0             	movzbl %al,%eax
f0101964:	0f b6 12             	movzbl (%edx),%edx
f0101967:	29 d0                	sub    %edx,%eax
}
f0101969:	5d                   	pop    %ebp
f010196a:	c3                   	ret    

f010196b <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f010196b:	55                   	push   %ebp
f010196c:	89 e5                	mov    %esp,%ebp
f010196e:	53                   	push   %ebx
f010196f:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101972:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101975:	8b 55 10             	mov    0x10(%ebp),%edx
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0101978:	b8 00 00 00 00       	mov    $0x0,%eax
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f010197d:	85 d2                	test   %edx,%edx
f010197f:	74 28                	je     f01019a9 <strncmp+0x3e>
f0101981:	0f b6 01             	movzbl (%ecx),%eax
f0101984:	84 c0                	test   %al,%al
f0101986:	74 24                	je     f01019ac <strncmp+0x41>
f0101988:	3a 03                	cmp    (%ebx),%al
f010198a:	75 20                	jne    f01019ac <strncmp+0x41>
f010198c:	83 ea 01             	sub    $0x1,%edx
f010198f:	74 13                	je     f01019a4 <strncmp+0x39>
		n--, p++, q++;
f0101991:	83 c1 01             	add    $0x1,%ecx
f0101994:	83 c3 01             	add    $0x1,%ebx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0101997:	0f b6 01             	movzbl (%ecx),%eax
f010199a:	84 c0                	test   %al,%al
f010199c:	74 0e                	je     f01019ac <strncmp+0x41>
f010199e:	3a 03                	cmp    (%ebx),%al
f01019a0:	74 ea                	je     f010198c <strncmp+0x21>
f01019a2:	eb 08                	jmp    f01019ac <strncmp+0x41>
		n--, p++, q++;
	if (n == 0)
		return 0;
f01019a4:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f01019a9:	5b                   	pop    %ebx
f01019aa:	5d                   	pop    %ebp
f01019ab:	c3                   	ret    
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f01019ac:	0f b6 01             	movzbl (%ecx),%eax
f01019af:	0f b6 13             	movzbl (%ebx),%edx
f01019b2:	29 d0                	sub    %edx,%eax
f01019b4:	eb f3                	jmp    f01019a9 <strncmp+0x3e>

f01019b6 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f01019b6:	55                   	push   %ebp
f01019b7:	89 e5                	mov    %esp,%ebp
f01019b9:	8b 45 08             	mov    0x8(%ebp),%eax
f01019bc:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01019c0:	0f b6 10             	movzbl (%eax),%edx
f01019c3:	84 d2                	test   %dl,%dl
f01019c5:	74 1c                	je     f01019e3 <strchr+0x2d>
		if (*s == c)
f01019c7:	38 ca                	cmp    %cl,%dl
f01019c9:	75 09                	jne    f01019d4 <strchr+0x1e>
f01019cb:	eb 1b                	jmp    f01019e8 <strchr+0x32>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01019cd:	83 c0 01             	add    $0x1,%eax
		if (*s == c)
f01019d0:	38 ca                	cmp    %cl,%dl
f01019d2:	74 14                	je     f01019e8 <strchr+0x32>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f01019d4:	0f b6 50 01          	movzbl 0x1(%eax),%edx
f01019d8:	84 d2                	test   %dl,%dl
f01019da:	75 f1                	jne    f01019cd <strchr+0x17>
		if (*s == c)
			return (char *) s;
	return 0;
f01019dc:	b8 00 00 00 00       	mov    $0x0,%eax
f01019e1:	eb 05                	jmp    f01019e8 <strchr+0x32>
f01019e3:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01019e8:	5d                   	pop    %ebp
f01019e9:	c3                   	ret    

f01019ea <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f01019ea:	55                   	push   %ebp
f01019eb:	89 e5                	mov    %esp,%ebp
f01019ed:	8b 45 08             	mov    0x8(%ebp),%eax
f01019f0:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f01019f4:	0f b6 10             	movzbl (%eax),%edx
f01019f7:	84 d2                	test   %dl,%dl
f01019f9:	74 14                	je     f0101a0f <strfind+0x25>
		if (*s == c)
f01019fb:	38 ca                	cmp    %cl,%dl
f01019fd:	75 06                	jne    f0101a05 <strfind+0x1b>
f01019ff:	eb 0e                	jmp    f0101a0f <strfind+0x25>
f0101a01:	38 ca                	cmp    %cl,%dl
f0101a03:	74 0a                	je     f0101a0f <strfind+0x25>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f0101a05:	83 c0 01             	add    $0x1,%eax
f0101a08:	0f b6 10             	movzbl (%eax),%edx
f0101a0b:	84 d2                	test   %dl,%dl
f0101a0d:	75 f2                	jne    f0101a01 <strfind+0x17>
		if (*s == c)
			break;
	return (char *) s;
}
f0101a0f:	5d                   	pop    %ebp
f0101a10:	c3                   	ret    

f0101a11 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0101a11:	55                   	push   %ebp
f0101a12:	89 e5                	mov    %esp,%ebp
f0101a14:	83 ec 0c             	sub    $0xc,%esp
f0101a17:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0101a1a:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0101a1d:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0101a20:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101a23:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101a26:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0101a29:	85 c9                	test   %ecx,%ecx
f0101a2b:	74 30                	je     f0101a5d <memset+0x4c>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0101a2d:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0101a33:	75 25                	jne    f0101a5a <memset+0x49>
f0101a35:	f6 c1 03             	test   $0x3,%cl
f0101a38:	75 20                	jne    f0101a5a <memset+0x49>
		c &= 0xFF;
f0101a3a:	0f b6 d0             	movzbl %al,%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0101a3d:	89 d3                	mov    %edx,%ebx
f0101a3f:	c1 e3 08             	shl    $0x8,%ebx
f0101a42:	89 d6                	mov    %edx,%esi
f0101a44:	c1 e6 18             	shl    $0x18,%esi
f0101a47:	89 d0                	mov    %edx,%eax
f0101a49:	c1 e0 10             	shl    $0x10,%eax
f0101a4c:	09 f0                	or     %esi,%eax
f0101a4e:	09 d0                	or     %edx,%eax
f0101a50:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0101a52:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f0101a55:	fc                   	cld    
f0101a56:	f3 ab                	rep stos %eax,%es:(%edi)
f0101a58:	eb 03                	jmp    f0101a5d <memset+0x4c>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0101a5a:	fc                   	cld    
f0101a5b:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0101a5d:	89 f8                	mov    %edi,%eax
f0101a5f:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0101a62:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0101a65:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0101a68:	89 ec                	mov    %ebp,%esp
f0101a6a:	5d                   	pop    %ebp
f0101a6b:	c3                   	ret    

f0101a6c <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0101a6c:	55                   	push   %ebp
f0101a6d:	89 e5                	mov    %esp,%ebp
f0101a6f:	83 ec 08             	sub    $0x8,%esp
f0101a72:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0101a75:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0101a78:	8b 45 08             	mov    0x8(%ebp),%eax
f0101a7b:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101a7e:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0101a81:	39 c6                	cmp    %eax,%esi
f0101a83:	73 36                	jae    f0101abb <memmove+0x4f>
f0101a85:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0101a88:	39 d0                	cmp    %edx,%eax
f0101a8a:	73 2f                	jae    f0101abb <memmove+0x4f>
		s += n;
		d += n;
f0101a8c:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101a8f:	f6 c2 03             	test   $0x3,%dl
f0101a92:	75 1b                	jne    f0101aaf <memmove+0x43>
f0101a94:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0101a9a:	75 13                	jne    f0101aaf <memmove+0x43>
f0101a9c:	f6 c1 03             	test   $0x3,%cl
f0101a9f:	75 0e                	jne    f0101aaf <memmove+0x43>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0101aa1:	83 ef 04             	sub    $0x4,%edi
f0101aa4:	8d 72 fc             	lea    -0x4(%edx),%esi
f0101aa7:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f0101aaa:	fd                   	std    
f0101aab:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101aad:	eb 09                	jmp    f0101ab8 <memmove+0x4c>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0101aaf:	83 ef 01             	sub    $0x1,%edi
f0101ab2:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0101ab5:	fd                   	std    
f0101ab6:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0101ab8:	fc                   	cld    
f0101ab9:	eb 20                	jmp    f0101adb <memmove+0x6f>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101abb:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0101ac1:	75 13                	jne    f0101ad6 <memmove+0x6a>
f0101ac3:	a8 03                	test   $0x3,%al
f0101ac5:	75 0f                	jne    f0101ad6 <memmove+0x6a>
f0101ac7:	f6 c1 03             	test   $0x3,%cl
f0101aca:	75 0a                	jne    f0101ad6 <memmove+0x6a>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0101acc:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f0101acf:	89 c7                	mov    %eax,%edi
f0101ad1:	fc                   	cld    
f0101ad2:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101ad4:	eb 05                	jmp    f0101adb <memmove+0x6f>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0101ad6:	89 c7                	mov    %eax,%edi
f0101ad8:	fc                   	cld    
f0101ad9:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0101adb:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0101ade:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0101ae1:	89 ec                	mov    %ebp,%esp
f0101ae3:	5d                   	pop    %ebp
f0101ae4:	c3                   	ret    

f0101ae5 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0101ae5:	55                   	push   %ebp
f0101ae6:	89 e5                	mov    %esp,%ebp
f0101ae8:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0101aeb:	8b 45 10             	mov    0x10(%ebp),%eax
f0101aee:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101af2:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101af5:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101af9:	8b 45 08             	mov    0x8(%ebp),%eax
f0101afc:	89 04 24             	mov    %eax,(%esp)
f0101aff:	e8 68 ff ff ff       	call   f0101a6c <memmove>
}
f0101b04:	c9                   	leave  
f0101b05:	c3                   	ret    

f0101b06 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0101b06:	55                   	push   %ebp
f0101b07:	89 e5                	mov    %esp,%ebp
f0101b09:	57                   	push   %edi
f0101b0a:	56                   	push   %esi
f0101b0b:	53                   	push   %ebx
f0101b0c:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0101b0f:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101b12:	8b 7d 10             	mov    0x10(%ebp),%edi
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0101b15:	b8 00 00 00 00       	mov    $0x0,%eax
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101b1a:	85 ff                	test   %edi,%edi
f0101b1c:	74 37                	je     f0101b55 <memcmp+0x4f>
		if (*s1 != *s2)
f0101b1e:	0f b6 03             	movzbl (%ebx),%eax
f0101b21:	0f b6 0e             	movzbl (%esi),%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101b24:	83 ef 01             	sub    $0x1,%edi
f0101b27:	ba 00 00 00 00       	mov    $0x0,%edx
		if (*s1 != *s2)
f0101b2c:	38 c8                	cmp    %cl,%al
f0101b2e:	74 1c                	je     f0101b4c <memcmp+0x46>
f0101b30:	eb 10                	jmp    f0101b42 <memcmp+0x3c>
f0101b32:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
f0101b37:	83 c2 01             	add    $0x1,%edx
f0101b3a:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
f0101b3e:	38 c8                	cmp    %cl,%al
f0101b40:	74 0a                	je     f0101b4c <memcmp+0x46>
			return (int) *s1 - (int) *s2;
f0101b42:	0f b6 c0             	movzbl %al,%eax
f0101b45:	0f b6 c9             	movzbl %cl,%ecx
f0101b48:	29 c8                	sub    %ecx,%eax
f0101b4a:	eb 09                	jmp    f0101b55 <memcmp+0x4f>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101b4c:	39 fa                	cmp    %edi,%edx
f0101b4e:	75 e2                	jne    f0101b32 <memcmp+0x2c>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0101b50:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101b55:	5b                   	pop    %ebx
f0101b56:	5e                   	pop    %esi
f0101b57:	5f                   	pop    %edi
f0101b58:	5d                   	pop    %ebp
f0101b59:	c3                   	ret    

f0101b5a <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0101b5a:	55                   	push   %ebp
f0101b5b:	89 e5                	mov    %esp,%ebp
f0101b5d:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0101b60:	89 c2                	mov    %eax,%edx
f0101b62:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0101b65:	39 d0                	cmp    %edx,%eax
f0101b67:	73 19                	jae    f0101b82 <memfind+0x28>
		if (*(const unsigned char *) s == (unsigned char) c)
f0101b69:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
f0101b6d:	38 08                	cmp    %cl,(%eax)
f0101b6f:	75 06                	jne    f0101b77 <memfind+0x1d>
f0101b71:	eb 0f                	jmp    f0101b82 <memfind+0x28>
f0101b73:	38 08                	cmp    %cl,(%eax)
f0101b75:	74 0b                	je     f0101b82 <memfind+0x28>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0101b77:	83 c0 01             	add    $0x1,%eax
f0101b7a:	39 d0                	cmp    %edx,%eax
f0101b7c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101b80:	75 f1                	jne    f0101b73 <memfind+0x19>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0101b82:	5d                   	pop    %ebp
f0101b83:	c3                   	ret    

f0101b84 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0101b84:	55                   	push   %ebp
f0101b85:	89 e5                	mov    %esp,%ebp
f0101b87:	57                   	push   %edi
f0101b88:	56                   	push   %esi
f0101b89:	53                   	push   %ebx
f0101b8a:	8b 55 08             	mov    0x8(%ebp),%edx
f0101b8d:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101b90:	0f b6 02             	movzbl (%edx),%eax
f0101b93:	3c 20                	cmp    $0x20,%al
f0101b95:	74 04                	je     f0101b9b <strtol+0x17>
f0101b97:	3c 09                	cmp    $0x9,%al
f0101b99:	75 0e                	jne    f0101ba9 <strtol+0x25>
		s++;
f0101b9b:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101b9e:	0f b6 02             	movzbl (%edx),%eax
f0101ba1:	3c 20                	cmp    $0x20,%al
f0101ba3:	74 f6                	je     f0101b9b <strtol+0x17>
f0101ba5:	3c 09                	cmp    $0x9,%al
f0101ba7:	74 f2                	je     f0101b9b <strtol+0x17>
		s++;

	// plus/minus sign
	if (*s == '+')
f0101ba9:	3c 2b                	cmp    $0x2b,%al
f0101bab:	75 0a                	jne    f0101bb7 <strtol+0x33>
		s++;
f0101bad:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0101bb0:	bf 00 00 00 00       	mov    $0x0,%edi
f0101bb5:	eb 10                	jmp    f0101bc7 <strtol+0x43>
f0101bb7:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0101bbc:	3c 2d                	cmp    $0x2d,%al
f0101bbe:	75 07                	jne    f0101bc7 <strtol+0x43>
		s++, neg = 1;
f0101bc0:	83 c2 01             	add    $0x1,%edx
f0101bc3:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0101bc7:	85 db                	test   %ebx,%ebx
f0101bc9:	0f 94 c0             	sete   %al
f0101bcc:	74 05                	je     f0101bd3 <strtol+0x4f>
f0101bce:	83 fb 10             	cmp    $0x10,%ebx
f0101bd1:	75 15                	jne    f0101be8 <strtol+0x64>
f0101bd3:	80 3a 30             	cmpb   $0x30,(%edx)
f0101bd6:	75 10                	jne    f0101be8 <strtol+0x64>
f0101bd8:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0101bdc:	75 0a                	jne    f0101be8 <strtol+0x64>
		s += 2, base = 16;
f0101bde:	83 c2 02             	add    $0x2,%edx
f0101be1:	bb 10 00 00 00       	mov    $0x10,%ebx
f0101be6:	eb 13                	jmp    f0101bfb <strtol+0x77>
	else if (base == 0 && s[0] == '0')
f0101be8:	84 c0                	test   %al,%al
f0101bea:	74 0f                	je     f0101bfb <strtol+0x77>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0101bec:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101bf1:	80 3a 30             	cmpb   $0x30,(%edx)
f0101bf4:	75 05                	jne    f0101bfb <strtol+0x77>
		s++, base = 8;
f0101bf6:	83 c2 01             	add    $0x1,%edx
f0101bf9:	b3 08                	mov    $0x8,%bl
	else if (base == 0)
		base = 10;
f0101bfb:	b8 00 00 00 00       	mov    $0x0,%eax
f0101c00:	89 de                	mov    %ebx,%esi

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0101c02:	0f b6 0a             	movzbl (%edx),%ecx
f0101c05:	8d 59 d0             	lea    -0x30(%ecx),%ebx
f0101c08:	80 fb 09             	cmp    $0x9,%bl
f0101c0b:	77 08                	ja     f0101c15 <strtol+0x91>
			dig = *s - '0';
f0101c0d:	0f be c9             	movsbl %cl,%ecx
f0101c10:	83 e9 30             	sub    $0x30,%ecx
f0101c13:	eb 1e                	jmp    f0101c33 <strtol+0xaf>
		else if (*s >= 'a' && *s <= 'z')
f0101c15:	8d 59 9f             	lea    -0x61(%ecx),%ebx
f0101c18:	80 fb 19             	cmp    $0x19,%bl
f0101c1b:	77 08                	ja     f0101c25 <strtol+0xa1>
			dig = *s - 'a' + 10;
f0101c1d:	0f be c9             	movsbl %cl,%ecx
f0101c20:	83 e9 57             	sub    $0x57,%ecx
f0101c23:	eb 0e                	jmp    f0101c33 <strtol+0xaf>
		else if (*s >= 'A' && *s <= 'Z')
f0101c25:	8d 59 bf             	lea    -0x41(%ecx),%ebx
f0101c28:	80 fb 19             	cmp    $0x19,%bl
f0101c2b:	77 14                	ja     f0101c41 <strtol+0xbd>
			dig = *s - 'A' + 10;
f0101c2d:	0f be c9             	movsbl %cl,%ecx
f0101c30:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0101c33:	39 f1                	cmp    %esi,%ecx
f0101c35:	7d 0e                	jge    f0101c45 <strtol+0xc1>
			break;
		s++, val = (val * base) + dig;
f0101c37:	83 c2 01             	add    $0x1,%edx
f0101c3a:	0f af c6             	imul   %esi,%eax
f0101c3d:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
f0101c3f:	eb c1                	jmp    f0101c02 <strtol+0x7e>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
f0101c41:	89 c1                	mov    %eax,%ecx
f0101c43:	eb 02                	jmp    f0101c47 <strtol+0xc3>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0101c45:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
f0101c47:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0101c4b:	74 05                	je     f0101c52 <strtol+0xce>
		*endptr = (char *) s;
f0101c4d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101c50:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
f0101c52:	89 ca                	mov    %ecx,%edx
f0101c54:	f7 da                	neg    %edx
f0101c56:	85 ff                	test   %edi,%edi
f0101c58:	0f 45 c2             	cmovne %edx,%eax
}
f0101c5b:	5b                   	pop    %ebx
f0101c5c:	5e                   	pop    %esi
f0101c5d:	5f                   	pop    %edi
f0101c5e:	5d                   	pop    %ebp
f0101c5f:	c3                   	ret    

f0101c60 <__udivdi3>:
f0101c60:	83 ec 1c             	sub    $0x1c,%esp
f0101c63:	89 7c 24 14          	mov    %edi,0x14(%esp)
f0101c67:	8b 7c 24 2c          	mov    0x2c(%esp),%edi
f0101c6b:	8b 44 24 20          	mov    0x20(%esp),%eax
f0101c6f:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0101c73:	89 74 24 10          	mov    %esi,0x10(%esp)
f0101c77:	8b 74 24 24          	mov    0x24(%esp),%esi
f0101c7b:	85 ff                	test   %edi,%edi
f0101c7d:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f0101c81:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101c85:	89 cd                	mov    %ecx,%ebp
f0101c87:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101c8b:	75 33                	jne    f0101cc0 <__udivdi3+0x60>
f0101c8d:	39 f1                	cmp    %esi,%ecx
f0101c8f:	77 57                	ja     f0101ce8 <__udivdi3+0x88>
f0101c91:	85 c9                	test   %ecx,%ecx
f0101c93:	75 0b                	jne    f0101ca0 <__udivdi3+0x40>
f0101c95:	b8 01 00 00 00       	mov    $0x1,%eax
f0101c9a:	31 d2                	xor    %edx,%edx
f0101c9c:	f7 f1                	div    %ecx
f0101c9e:	89 c1                	mov    %eax,%ecx
f0101ca0:	89 f0                	mov    %esi,%eax
f0101ca2:	31 d2                	xor    %edx,%edx
f0101ca4:	f7 f1                	div    %ecx
f0101ca6:	89 c6                	mov    %eax,%esi
f0101ca8:	8b 44 24 04          	mov    0x4(%esp),%eax
f0101cac:	f7 f1                	div    %ecx
f0101cae:	89 f2                	mov    %esi,%edx
f0101cb0:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101cb4:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101cb8:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101cbc:	83 c4 1c             	add    $0x1c,%esp
f0101cbf:	c3                   	ret    
f0101cc0:	31 d2                	xor    %edx,%edx
f0101cc2:	31 c0                	xor    %eax,%eax
f0101cc4:	39 f7                	cmp    %esi,%edi
f0101cc6:	77 e8                	ja     f0101cb0 <__udivdi3+0x50>
f0101cc8:	0f bd cf             	bsr    %edi,%ecx
f0101ccb:	83 f1 1f             	xor    $0x1f,%ecx
f0101cce:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0101cd2:	75 2c                	jne    f0101d00 <__udivdi3+0xa0>
f0101cd4:	3b 6c 24 08          	cmp    0x8(%esp),%ebp
f0101cd8:	76 04                	jbe    f0101cde <__udivdi3+0x7e>
f0101cda:	39 f7                	cmp    %esi,%edi
f0101cdc:	73 d2                	jae    f0101cb0 <__udivdi3+0x50>
f0101cde:	31 d2                	xor    %edx,%edx
f0101ce0:	b8 01 00 00 00       	mov    $0x1,%eax
f0101ce5:	eb c9                	jmp    f0101cb0 <__udivdi3+0x50>
f0101ce7:	90                   	nop
f0101ce8:	89 f2                	mov    %esi,%edx
f0101cea:	f7 f1                	div    %ecx
f0101cec:	31 d2                	xor    %edx,%edx
f0101cee:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101cf2:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101cf6:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101cfa:	83 c4 1c             	add    $0x1c,%esp
f0101cfd:	c3                   	ret    
f0101cfe:	66 90                	xchg   %ax,%ax
f0101d00:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101d05:	b8 20 00 00 00       	mov    $0x20,%eax
f0101d0a:	89 ea                	mov    %ebp,%edx
f0101d0c:	2b 44 24 04          	sub    0x4(%esp),%eax
f0101d10:	d3 e7                	shl    %cl,%edi
f0101d12:	89 c1                	mov    %eax,%ecx
f0101d14:	d3 ea                	shr    %cl,%edx
f0101d16:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101d1b:	09 fa                	or     %edi,%edx
f0101d1d:	89 f7                	mov    %esi,%edi
f0101d1f:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101d23:	89 f2                	mov    %esi,%edx
f0101d25:	8b 74 24 08          	mov    0x8(%esp),%esi
f0101d29:	d3 e5                	shl    %cl,%ebp
f0101d2b:	89 c1                	mov    %eax,%ecx
f0101d2d:	d3 ef                	shr    %cl,%edi
f0101d2f:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101d34:	d3 e2                	shl    %cl,%edx
f0101d36:	89 c1                	mov    %eax,%ecx
f0101d38:	d3 ee                	shr    %cl,%esi
f0101d3a:	09 d6                	or     %edx,%esi
f0101d3c:	89 fa                	mov    %edi,%edx
f0101d3e:	89 f0                	mov    %esi,%eax
f0101d40:	f7 74 24 0c          	divl   0xc(%esp)
f0101d44:	89 d7                	mov    %edx,%edi
f0101d46:	89 c6                	mov    %eax,%esi
f0101d48:	f7 e5                	mul    %ebp
f0101d4a:	39 d7                	cmp    %edx,%edi
f0101d4c:	72 22                	jb     f0101d70 <__udivdi3+0x110>
f0101d4e:	8b 6c 24 08          	mov    0x8(%esp),%ebp
f0101d52:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101d57:	d3 e5                	shl    %cl,%ebp
f0101d59:	39 c5                	cmp    %eax,%ebp
f0101d5b:	73 04                	jae    f0101d61 <__udivdi3+0x101>
f0101d5d:	39 d7                	cmp    %edx,%edi
f0101d5f:	74 0f                	je     f0101d70 <__udivdi3+0x110>
f0101d61:	89 f0                	mov    %esi,%eax
f0101d63:	31 d2                	xor    %edx,%edx
f0101d65:	e9 46 ff ff ff       	jmp    f0101cb0 <__udivdi3+0x50>
f0101d6a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101d70:	8d 46 ff             	lea    -0x1(%esi),%eax
f0101d73:	31 d2                	xor    %edx,%edx
f0101d75:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101d79:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101d7d:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101d81:	83 c4 1c             	add    $0x1c,%esp
f0101d84:	c3                   	ret    
	...

f0101d90 <__umoddi3>:
f0101d90:	83 ec 1c             	sub    $0x1c,%esp
f0101d93:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f0101d97:	8b 6c 24 2c          	mov    0x2c(%esp),%ebp
f0101d9b:	8b 44 24 20          	mov    0x20(%esp),%eax
f0101d9f:	89 74 24 10          	mov    %esi,0x10(%esp)
f0101da3:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0101da7:	8b 74 24 24          	mov    0x24(%esp),%esi
f0101dab:	85 ed                	test   %ebp,%ebp
f0101dad:	89 7c 24 14          	mov    %edi,0x14(%esp)
f0101db1:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101db5:	89 cf                	mov    %ecx,%edi
f0101db7:	89 04 24             	mov    %eax,(%esp)
f0101dba:	89 f2                	mov    %esi,%edx
f0101dbc:	75 1a                	jne    f0101dd8 <__umoddi3+0x48>
f0101dbe:	39 f1                	cmp    %esi,%ecx
f0101dc0:	76 4e                	jbe    f0101e10 <__umoddi3+0x80>
f0101dc2:	f7 f1                	div    %ecx
f0101dc4:	89 d0                	mov    %edx,%eax
f0101dc6:	31 d2                	xor    %edx,%edx
f0101dc8:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101dcc:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101dd0:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101dd4:	83 c4 1c             	add    $0x1c,%esp
f0101dd7:	c3                   	ret    
f0101dd8:	39 f5                	cmp    %esi,%ebp
f0101dda:	77 54                	ja     f0101e30 <__umoddi3+0xa0>
f0101ddc:	0f bd c5             	bsr    %ebp,%eax
f0101ddf:	83 f0 1f             	xor    $0x1f,%eax
f0101de2:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101de6:	75 60                	jne    f0101e48 <__umoddi3+0xb8>
f0101de8:	3b 0c 24             	cmp    (%esp),%ecx
f0101deb:	0f 87 07 01 00 00    	ja     f0101ef8 <__umoddi3+0x168>
f0101df1:	89 f2                	mov    %esi,%edx
f0101df3:	8b 34 24             	mov    (%esp),%esi
f0101df6:	29 ce                	sub    %ecx,%esi
f0101df8:	19 ea                	sbb    %ebp,%edx
f0101dfa:	89 34 24             	mov    %esi,(%esp)
f0101dfd:	8b 04 24             	mov    (%esp),%eax
f0101e00:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101e04:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101e08:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101e0c:	83 c4 1c             	add    $0x1c,%esp
f0101e0f:	c3                   	ret    
f0101e10:	85 c9                	test   %ecx,%ecx
f0101e12:	75 0b                	jne    f0101e1f <__umoddi3+0x8f>
f0101e14:	b8 01 00 00 00       	mov    $0x1,%eax
f0101e19:	31 d2                	xor    %edx,%edx
f0101e1b:	f7 f1                	div    %ecx
f0101e1d:	89 c1                	mov    %eax,%ecx
f0101e1f:	89 f0                	mov    %esi,%eax
f0101e21:	31 d2                	xor    %edx,%edx
f0101e23:	f7 f1                	div    %ecx
f0101e25:	8b 04 24             	mov    (%esp),%eax
f0101e28:	f7 f1                	div    %ecx
f0101e2a:	eb 98                	jmp    f0101dc4 <__umoddi3+0x34>
f0101e2c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101e30:	89 f2                	mov    %esi,%edx
f0101e32:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101e36:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101e3a:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101e3e:	83 c4 1c             	add    $0x1c,%esp
f0101e41:	c3                   	ret    
f0101e42:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101e48:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101e4d:	89 e8                	mov    %ebp,%eax
f0101e4f:	bd 20 00 00 00       	mov    $0x20,%ebp
f0101e54:	2b 6c 24 04          	sub    0x4(%esp),%ebp
f0101e58:	89 fa                	mov    %edi,%edx
f0101e5a:	d3 e0                	shl    %cl,%eax
f0101e5c:	89 e9                	mov    %ebp,%ecx
f0101e5e:	d3 ea                	shr    %cl,%edx
f0101e60:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101e65:	09 c2                	or     %eax,%edx
f0101e67:	8b 44 24 08          	mov    0x8(%esp),%eax
f0101e6b:	89 14 24             	mov    %edx,(%esp)
f0101e6e:	89 f2                	mov    %esi,%edx
f0101e70:	d3 e7                	shl    %cl,%edi
f0101e72:	89 e9                	mov    %ebp,%ecx
f0101e74:	d3 ea                	shr    %cl,%edx
f0101e76:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101e7b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101e7f:	d3 e6                	shl    %cl,%esi
f0101e81:	89 e9                	mov    %ebp,%ecx
f0101e83:	d3 e8                	shr    %cl,%eax
f0101e85:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101e8a:	09 f0                	or     %esi,%eax
f0101e8c:	8b 74 24 08          	mov    0x8(%esp),%esi
f0101e90:	f7 34 24             	divl   (%esp)
f0101e93:	d3 e6                	shl    %cl,%esi
f0101e95:	89 74 24 08          	mov    %esi,0x8(%esp)
f0101e99:	89 d6                	mov    %edx,%esi
f0101e9b:	f7 e7                	mul    %edi
f0101e9d:	39 d6                	cmp    %edx,%esi
f0101e9f:	89 c1                	mov    %eax,%ecx
f0101ea1:	89 d7                	mov    %edx,%edi
f0101ea3:	72 3f                	jb     f0101ee4 <__umoddi3+0x154>
f0101ea5:	39 44 24 08          	cmp    %eax,0x8(%esp)
f0101ea9:	72 35                	jb     f0101ee0 <__umoddi3+0x150>
f0101eab:	8b 44 24 08          	mov    0x8(%esp),%eax
f0101eaf:	29 c8                	sub    %ecx,%eax
f0101eb1:	19 fe                	sbb    %edi,%esi
f0101eb3:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101eb8:	89 f2                	mov    %esi,%edx
f0101eba:	d3 e8                	shr    %cl,%eax
f0101ebc:	89 e9                	mov    %ebp,%ecx
f0101ebe:	d3 e2                	shl    %cl,%edx
f0101ec0:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101ec5:	09 d0                	or     %edx,%eax
f0101ec7:	89 f2                	mov    %esi,%edx
f0101ec9:	d3 ea                	shr    %cl,%edx
f0101ecb:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101ecf:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101ed3:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101ed7:	83 c4 1c             	add    $0x1c,%esp
f0101eda:	c3                   	ret    
f0101edb:	90                   	nop
f0101edc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101ee0:	39 d6                	cmp    %edx,%esi
f0101ee2:	75 c7                	jne    f0101eab <__umoddi3+0x11b>
f0101ee4:	89 d7                	mov    %edx,%edi
f0101ee6:	89 c1                	mov    %eax,%ecx
f0101ee8:	2b 4c 24 0c          	sub    0xc(%esp),%ecx
f0101eec:	1b 3c 24             	sbb    (%esp),%edi
f0101eef:	eb ba                	jmp    f0101eab <__umoddi3+0x11b>
f0101ef1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101ef8:	39 f5                	cmp    %esi,%ebp
f0101efa:	0f 82 f1 fe ff ff    	jb     f0101df1 <__umoddi3+0x61>
f0101f00:	e9 f8 fe ff ff       	jmp    f0101dfd <__umoddi3+0x6d>
