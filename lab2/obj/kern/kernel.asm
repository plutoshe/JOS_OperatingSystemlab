
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
f0100063:	e8 99 3b 00 00       	call   f0103c01 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100068:	e8 97 04 00 00       	call   f0100504 <cons_init>
	cprintf("6828 decimal is %o octal!\n", 6828);
f010006d:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f0100074:	00 
f0100075:	c7 04 24 00 41 10 f0 	movl   $0xf0104100,(%esp)
f010007c:	e8 c9 2f 00 00       	call   f010304a <cprintf>

	// Lab 2 memory management initialization functions
	mem_init();
f0100081:	e8 e2 13 00 00       	call   f0101468 <mem_init>
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
f01000c1:	c7 04 24 1b 41 10 f0 	movl   $0xf010411b,(%esp)
f01000c8:	e8 7d 2f 00 00       	call   f010304a <cprintf>
	vcprintf(fmt, ap);
f01000cd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01000d1:	89 34 24             	mov    %esi,(%esp)
f01000d4:	e8 3e 2f 00 00       	call   f0103017 <vcprintf>
	cprintf("\n");
f01000d9:	c7 04 24 64 50 10 f0 	movl   $0xf0105064,(%esp)
f01000e0:	e8 65 2f 00 00       	call   f010304a <cprintf>
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
f010010b:	c7 04 24 33 41 10 f0 	movl   $0xf0104133,(%esp)
f0100112:	e8 33 2f 00 00       	call   f010304a <cprintf>
	vcprintf(fmt, ap);
f0100117:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010011b:	8b 45 10             	mov    0x10(%ebp),%eax
f010011e:	89 04 24             	mov    %eax,(%esp)
f0100121:	e8 f1 2e 00 00       	call   f0103017 <vcprintf>
	cprintf("\n");
f0100126:	c7 04 24 64 50 10 f0 	movl   $0xf0105064,(%esp)
f010012d:	e8 18 2f 00 00       	call   f010304a <cprintf>
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
f010031b:	e8 3c 39 00 00       	call   f0103c5c <memmove>
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
f01003c7:	0f b6 82 80 41 10 f0 	movzbl -0xfefbe80(%edx),%eax
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
f0100404:	0f b6 82 80 41 10 f0 	movzbl -0xfefbe80(%edx),%eax
f010040b:	0b 05 48 85 11 f0    	or     0xf0118548,%eax
	shift ^= togglecode[data];
f0100411:	0f b6 8a 80 42 10 f0 	movzbl -0xfefbd80(%edx),%ecx
f0100418:	31 c8                	xor    %ecx,%eax
f010041a:	a3 48 85 11 f0       	mov    %eax,0xf0118548

	c = charcode[shift & (CTL | SHIFT)][data];
f010041f:	89 c1                	mov    %eax,%ecx
f0100421:	83 e1 03             	and    $0x3,%ecx
f0100424:	8b 0c 8d 80 43 10 f0 	mov    -0xfefbc80(,%ecx,4),%ecx
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
f010045a:	c7 04 24 4d 41 10 f0 	movl   $0xf010414d,(%esp)
f0100461:	e8 e4 2b 00 00       	call   f010304a <cprintf>
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
f01005e5:	c7 04 24 59 41 10 f0 	movl   $0xf0104159,(%esp)
f01005ec:	e8 59 2a 00 00       	call   f010304a <cprintf>
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
f0100636:	c7 04 24 90 43 10 f0 	movl   $0xf0104390,(%esp)
f010063d:	e8 08 2a 00 00       	call   f010304a <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100642:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f0100649:	00 
f010064a:	c7 04 24 94 44 10 f0 	movl   $0xf0104494,(%esp)
f0100651:	e8 f4 29 00 00       	call   f010304a <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100656:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f010065d:	00 
f010065e:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f0100665:	f0 
f0100666:	c7 04 24 bc 44 10 f0 	movl   $0xf01044bc,(%esp)
f010066d:	e8 d8 29 00 00       	call   f010304a <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100672:	c7 44 24 08 f5 40 10 	movl   $0x1040f5,0x8(%esp)
f0100679:	00 
f010067a:	c7 44 24 04 f5 40 10 	movl   $0xf01040f5,0x4(%esp)
f0100681:	f0 
f0100682:	c7 04 24 e0 44 10 f0 	movl   $0xf01044e0,(%esp)
f0100689:	e8 bc 29 00 00       	call   f010304a <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010068e:	c7 44 24 08 20 83 11 	movl   $0x118320,0x8(%esp)
f0100695:	00 
f0100696:	c7 44 24 04 20 83 11 	movl   $0xf0118320,0x4(%esp)
f010069d:	f0 
f010069e:	c7 04 24 04 45 10 f0 	movl   $0xf0104504,(%esp)
f01006a5:	e8 a0 29 00 00       	call   f010304a <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006aa:	c7 44 24 08 90 89 11 	movl   $0x118990,0x8(%esp)
f01006b1:	00 
f01006b2:	c7 44 24 04 90 89 11 	movl   $0xf0118990,0x4(%esp)
f01006b9:	f0 
f01006ba:	c7 04 24 28 45 10 f0 	movl   $0xf0104528,(%esp)
f01006c1:	e8 84 29 00 00       	call   f010304a <cprintf>
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
f01006e7:	c7 04 24 4c 45 10 f0 	movl   $0xf010454c,(%esp)
f01006ee:	e8 57 29 00 00       	call   f010304a <cprintf>
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
f0100706:	8b 83 84 46 10 f0    	mov    -0xfefb97c(%ebx),%eax
f010070c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100710:	8b 83 80 46 10 f0    	mov    -0xfefb980(%ebx),%eax
f0100716:	89 44 24 04          	mov    %eax,0x4(%esp)
f010071a:	c7 04 24 a9 43 10 f0 	movl   $0xf01043a9,(%esp)
f0100721:	e8 24 29 00 00       	call   f010304a <cprintf>
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
f0100749:	c7 04 24 b2 43 10 f0 	movl   $0xf01043b2,(%esp)
f0100750:	e8 f5 28 00 00       	call   f010304a <cprintf>
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
f0100788:	c7 04 24 78 45 10 f0 	movl   $0xf0104578,(%esp)
f010078f:	e8 b6 28 00 00       	call   f010304a <cprintf>
		struct Eipdebuginfo temp_debuginfo;
		debuginfo_eip((uintptr_t) eip, &temp_debuginfo);		
f0100794:	8d 45 d0             	lea    -0x30(%ebp),%eax
f0100797:	89 44 24 04          	mov    %eax,0x4(%esp)
f010079b:	89 3c 24             	mov    %edi,(%esp)
f010079e:	e8 a1 29 00 00       	call   f0103144 <debuginfo_eip>
		cprintf("       %s:%d: ", temp_debuginfo.eip_file, temp_debuginfo.eip_line);
f01007a3:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01007a6:	89 44 24 08          	mov    %eax,0x8(%esp)
f01007aa:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01007ad:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007b1:	c7 04 24 c3 43 10 f0 	movl   $0xf01043c3,(%esp)
f01007b8:	e8 8d 28 00 00       	call   f010304a <cprintf>
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
f01007d3:	c7 04 24 d2 43 10 f0 	movl   $0xf01043d2,(%esp)
f01007da:	e8 6b 28 00 00       	call   f010304a <cprintf>
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
f01007ee:	c7 04 24 d5 43 10 f0 	movl   $0xf01043d5,(%esp)
f01007f5:	e8 50 28 00 00       	call   f010304a <cprintf>
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
f0100826:	c7 44 24 04 da 43 10 	movl   $0xf01043da,0x4(%esp)
f010082d:	f0 
f010082e:	8b 46 08             	mov    0x8(%esi),%eax
f0100831:	89 04 24             	mov    %eax,(%esp)
f0100834:	e8 f2 32 00 00       	call   f0103b2b <strcmp>
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
f0100846:	c7 44 24 04 de 43 10 	movl   $0xf01043de,0x4(%esp)
f010084d:	f0 
f010084e:	8b 46 08             	mov    0x8(%esi),%eax
f0100851:	89 04 24             	mov    %eax,(%esp)
f0100854:	e8 d2 32 00 00       	call   f0103b2b <strcmp>
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
f0100866:	c7 44 24 04 e2 43 10 	movl   $0xf01043e2,0x4(%esp)
f010086d:	f0 
f010086e:	8b 46 08             	mov    0x8(%esi),%eax
f0100871:	89 04 24             	mov    %eax,(%esp)
f0100874:	e8 b2 32 00 00       	call   f0103b2b <strcmp>
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
f0100886:	c7 44 24 04 e6 43 10 	movl   $0xf01043e6,0x4(%esp)
f010088d:	f0 
f010088e:	8b 46 08             	mov    0x8(%esi),%eax
f0100891:	89 04 24             	mov    %eax,(%esp)
f0100894:	e8 92 32 00 00       	call   f0103b2b <strcmp>
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
f01008a6:	c7 44 24 04 ea 43 10 	movl   $0xf01043ea,0x4(%esp)
f01008ad:	f0 
f01008ae:	8b 46 08             	mov    0x8(%esi),%eax
f01008b1:	89 04 24             	mov    %eax,(%esp)
f01008b4:	e8 72 32 00 00       	call   f0103b2b <strcmp>
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
f01008c6:	c7 44 24 04 ee 43 10 	movl   $0xf01043ee,0x4(%esp)
f01008cd:	f0 
f01008ce:	8b 46 08             	mov    0x8(%esi),%eax
f01008d1:	89 04 24             	mov    %eax,(%esp)
f01008d4:	e8 52 32 00 00       	call   f0103b2b <strcmp>
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
f01008e2:	c7 44 24 04 f2 43 10 	movl   $0xf01043f2,0x4(%esp)
f01008e9:	f0 
f01008ea:	8b 46 08             	mov    0x8(%esi),%eax
f01008ed:	89 04 24             	mov    %eax,(%esp)
f01008f0:	e8 36 32 00 00       	call   f0103b2b <strcmp>
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
f01008fe:	c7 44 24 04 f6 43 10 	movl   $0xf01043f6,0x4(%esp)
f0100905:	f0 
f0100906:	8b 46 08             	mov    0x8(%esi),%eax
f0100909:	89 04 24             	mov    %eax,(%esp)
f010090c:	e8 1a 32 00 00       	call   f0103b2b <strcmp>
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
f010091a:	c7 44 24 04 fa 43 10 	movl   $0xf01043fa,0x4(%esp)
f0100921:	f0 
f0100922:	8b 46 08             	mov    0x8(%esi),%eax
f0100925:	89 04 24             	mov    %eax,(%esp)
f0100928:	e8 fe 31 00 00       	call   f0103b2b <strcmp>
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
f0100936:	c7 44 24 04 fe 43 10 	movl   $0xf01043fe,0x4(%esp)
f010093d:	f0 
f010093e:	8b 46 08             	mov    0x8(%esi),%eax
f0100941:	89 04 24             	mov    %eax,(%esp)
f0100944:	e8 e2 31 00 00       	call   f0103b2b <strcmp>
			ch_color1=COLOR_CYN
f0100949:	83 f8 01             	cmp    $0x1,%eax
f010094c:	19 ff                	sbb    %edi,%edi
f010094e:	83 e7 04             	and    $0x4,%edi
f0100951:	83 c7 07             	add    $0x7,%edi
	else ch_color1=COLOR_WHT;
	if(strcmp(argv[1],"blk")==0)
f0100954:	c7 44 24 04 da 43 10 	movl   $0xf01043da,0x4(%esp)
f010095b:	f0 
f010095c:	8b 46 04             	mov    0x4(%esi),%eax
f010095f:	89 04 24             	mov    %eax,(%esp)
f0100962:	e8 c4 31 00 00       	call   f0103b2b <strcmp>
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
f0100974:	c7 44 24 04 de 43 10 	movl   $0xf01043de,0x4(%esp)
f010097b:	f0 
f010097c:	8b 46 04             	mov    0x4(%esi),%eax
f010097f:	89 04 24             	mov    %eax,(%esp)
f0100982:	e8 a4 31 00 00       	call   f0103b2b <strcmp>
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
f0100991:	c7 44 24 04 e2 43 10 	movl   $0xf01043e2,0x4(%esp)
f0100998:	f0 
f0100999:	8b 46 04             	mov    0x4(%esi),%eax
f010099c:	89 04 24             	mov    %eax,(%esp)
f010099f:	e8 87 31 00 00       	call   f0103b2b <strcmp>
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
f01009ae:	c7 44 24 04 e6 43 10 	movl   $0xf01043e6,0x4(%esp)
f01009b5:	f0 
f01009b6:	8b 46 04             	mov    0x4(%esi),%eax
f01009b9:	89 04 24             	mov    %eax,(%esp)
f01009bc:	e8 6a 31 00 00       	call   f0103b2b <strcmp>
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
f01009cb:	c7 44 24 04 ea 43 10 	movl   $0xf01043ea,0x4(%esp)
f01009d2:	f0 
f01009d3:	8b 46 04             	mov    0x4(%esi),%eax
f01009d6:	89 04 24             	mov    %eax,(%esp)
f01009d9:	e8 4d 31 00 00       	call   f0103b2b <strcmp>
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
f01009e8:	c7 44 24 04 ee 43 10 	movl   $0xf01043ee,0x4(%esp)
f01009ef:	f0 
f01009f0:	8b 46 04             	mov    0x4(%esi),%eax
f01009f3:	89 04 24             	mov    %eax,(%esp)
f01009f6:	e8 30 31 00 00       	call   f0103b2b <strcmp>
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
f0100a01:	c7 44 24 04 f2 43 10 	movl   $0xf01043f2,0x4(%esp)
f0100a08:	f0 
f0100a09:	8b 46 04             	mov    0x4(%esi),%eax
f0100a0c:	89 04 24             	mov    %eax,(%esp)
f0100a0f:	e8 17 31 00 00       	call   f0103b2b <strcmp>
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
f0100a1a:	c7 44 24 04 f6 43 10 	movl   $0xf01043f6,0x4(%esp)
f0100a21:	f0 
f0100a22:	8b 46 04             	mov    0x4(%esi),%eax
f0100a25:	89 04 24             	mov    %eax,(%esp)
f0100a28:	e8 fe 30 00 00       	call   f0103b2b <strcmp>
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
f0100a33:	c7 44 24 04 fa 43 10 	movl   $0xf01043fa,0x4(%esp)
f0100a3a:	f0 
f0100a3b:	8b 46 04             	mov    0x4(%esi),%eax
f0100a3e:	89 04 24             	mov    %eax,(%esp)
f0100a41:	e8 e5 30 00 00       	call   f0103b2b <strcmp>
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
f0100a4c:	c7 44 24 04 fe 43 10 	movl   $0xf01043fe,0x4(%esp)
f0100a53:	f0 
f0100a54:	8b 46 04             	mov    0x4(%esi),%eax
f0100a57:	89 04 24             	mov    %eax,(%esp)
f0100a5a:	e8 cc 30 00 00       	call   f0103b2b <strcmp>
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
f0100a84:	c7 04 24 ac 45 10 f0 	movl   $0xf01045ac,(%esp)
f0100a8b:	e8 ba 25 00 00       	call   f010304a <cprintf>
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
f0100aab:	c7 04 24 e0 45 10 f0 	movl   $0xf01045e0,(%esp)
f0100ab2:	e8 93 25 00 00       	call   f010304a <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100ab7:	c7 04 24 04 46 10 f0 	movl   $0xf0104604,(%esp)
f0100abe:	e8 87 25 00 00       	call   f010304a <cprintf>
  //	cprintf("x %d, y %x, z %d\n", x, y, z);
//	unsigned int i = 0x00646c72;
//	cprintf("H%x Wo%s", 57616, &i);

	while (1) {
		buf = readline("K> ");
f0100ac3:	c7 04 24 02 44 10 f0 	movl   $0xf0104402,(%esp)
f0100aca:	e8 81 2e 00 00       	call   f0103950 <readline>
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
f0100af7:	c7 04 24 06 44 10 f0 	movl   $0xf0104406,(%esp)
f0100afe:	e8 a3 30 00 00       	call   f0103ba6 <strchr>
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
f0100b1a:	c7 04 24 0b 44 10 f0 	movl   $0xf010440b,(%esp)
f0100b21:	e8 24 25 00 00       	call   f010304a <cprintf>
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
f0100b49:	c7 04 24 06 44 10 f0 	movl   $0xf0104406,(%esp)
f0100b50:	e8 51 30 00 00       	call   f0103ba6 <strchr>
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
f0100b6b:	bb 80 46 10 f0       	mov    $0xf0104680,%ebx
f0100b70:	bf 00 00 00 00       	mov    $0x0,%edi
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100b75:	8b 03                	mov    (%ebx),%eax
f0100b77:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100b7b:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100b7e:	89 04 24             	mov    %eax,(%esp)
f0100b81:	e8 a5 2f 00 00       	call   f0103b2b <strcmp>
f0100b86:	85 c0                	test   %eax,%eax
f0100b88:	75 24                	jne    f0100bae <monitor+0x10c>
			return commands[i].func(argc, argv, tf);
f0100b8a:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f0100b8d:	8b 55 08             	mov    0x8(%ebp),%edx
f0100b90:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100b94:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100b97:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100b9b:	89 34 24             	mov    %esi,(%esp)
f0100b9e:	ff 14 85 88 46 10 f0 	call   *-0xfefb978(,%eax,4)
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
f0100bc0:	c7 04 24 28 44 10 f0 	movl   $0xf0104428,(%esp)
f0100bc7:	e8 7e 24 00 00       	call   f010304a <cprintf>
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
//	cprintf("!");
	pte_t *p;
	//cprintf("!");
	pgdir = &pgdir[PDX(va)];
f0100c1e:	89 d1                	mov    %edx,%ecx
f0100c20:	c1 e9 16             	shr    $0x16,%ecx
	if (!(*pgdir & PTE_P))
f0100c23:	8b 0c 88             	mov    (%eax,%ecx,4),%ecx
		return ~0;
f0100c26:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
{
//	cprintf("!");
	pte_t *p;
	//cprintf("!");
	pgdir = &pgdir[PDX(va)];
	if (!(*pgdir & PTE_P))
f0100c2b:	f6 c1 01             	test   $0x1,%cl
f0100c2e:	74 57                	je     f0100c87 <check_va2pa+0x6f>
		return ~0;
 //	cprintf("!");	
	p = (pte_t*) KADDR(PTE_ADDR(*pgdir));
f0100c30:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0100c36:	89 c8                	mov    %ecx,%eax
f0100c38:	c1 e8 0c             	shr    $0xc,%eax
f0100c3b:	3b 05 84 89 11 f0    	cmp    0xf0118984,%eax
f0100c41:	72 20                	jb     f0100c63 <check_va2pa+0x4b>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100c43:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f0100c47:	c7 44 24 08 b0 46 10 	movl   $0xf01046b0,0x8(%esp)
f0100c4e:	f0 
f0100c4f:	c7 44 24 04 d7 02 00 	movl   $0x2d7,0x4(%esp)
f0100c56:	00 
f0100c57:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
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
f0100c9a:	e8 3d 23 00 00       	call   f0102fdc <mc146818_read>
f0100c9f:	89 c6                	mov    %eax,%esi
f0100ca1:	83 c3 01             	add    $0x1,%ebx
f0100ca4:	89 1c 24             	mov    %ebx,(%esp)
f0100ca7:	e8 30 23 00 00       	call   f0102fdc <mc146818_read>
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
f0100cd1:	8b 1d 60 85 11 f0    	mov    0xf0118560,%ebx
f0100cd7:	85 db                	test   %ebx,%ebx
f0100cd9:	75 1c                	jne    f0100cf7 <check_page_free_list+0x3c>
		panic("'page_free_list' is a null pointer!");
f0100cdb:	c7 44 24 08 d4 46 10 	movl   $0xf01046d4,0x8(%esp)
f0100ce2:	f0 
f0100ce3:	c7 44 24 04 17 02 00 	movl   $0x217,0x4(%esp)
f0100cea:	00 
f0100ceb:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
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
f0100d09:	2b 05 8c 89 11 f0    	sub    0xf011898c,%eax
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
f0100d41:	89 1d 60 85 11 f0    	mov    %ebx,0xf0118560
	}

	// if there's a page that shouldn't be on the free list,
	// try to make sure it eventually causes trouble.
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0100d47:	85 db                	test   %ebx,%ebx
f0100d49:	74 67                	je     f0100db2 <check_page_free_list+0xf7>
f0100d4b:	89 d8                	mov    %ebx,%eax
f0100d4d:	2b 05 8c 89 11 f0    	sub    0xf011898c,%eax
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
f0100d67:	3b 15 84 89 11 f0    	cmp    0xf0118984,%edx
f0100d6d:	72 20                	jb     f0100d8f <check_page_free_list+0xd4>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0100d6f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100d73:	c7 44 24 08 b0 46 10 	movl   $0xf01046b0,0x8(%esp)
f0100d7a:	f0 
f0100d7b:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100d82:	00 
f0100d83:	c7 04 24 d8 4d 10 f0 	movl   $0xf0104dd8,(%esp)
f0100d8a:	e8 05 f3 ff ff       	call   f0100094 <_panic>
			memset(page2kva(pp), 0x97, 128);
f0100d8f:	c7 44 24 08 80 00 00 	movl   $0x80,0x8(%esp)
f0100d96:	00 
f0100d97:	c7 44 24 04 97 00 00 	movl   $0x97,0x4(%esp)
f0100d9e:	00 
	return (void *)(pa + KERNBASE);
f0100d9f:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0100da4:	89 04 24             	mov    %eax,(%esp)
f0100da7:	e8 55 2e 00 00       	call   f0103c01 <memset>
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
f0100dbf:	8b 15 60 85 11 f0    	mov    0xf0118560,%edx
f0100dc5:	85 d2                	test   %edx,%edx
f0100dc7:	0f 84 f6 01 00 00    	je     f0100fc3 <check_page_free_list+0x308>
		// check that we didn't corrupt the free list itself
		assert(pp >= pages);
f0100dcd:	8b 1d 8c 89 11 f0    	mov    0xf011898c,%ebx
f0100dd3:	39 da                	cmp    %ebx,%edx
f0100dd5:	72 4d                	jb     f0100e24 <check_page_free_list+0x169>
		assert(pp < pages + npages);
f0100dd7:	a1 84 89 11 f0       	mov    0xf0118984,%eax
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
f0100e24:	c7 44 24 0c e6 4d 10 	movl   $0xf0104de6,0xc(%esp)
f0100e2b:	f0 
f0100e2c:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f0100e33:	f0 
f0100e34:	c7 44 24 04 31 02 00 	movl   $0x231,0x4(%esp)
f0100e3b:	00 
f0100e3c:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f0100e43:	e8 4c f2 ff ff       	call   f0100094 <_panic>
		assert(pp < pages + npages);
f0100e48:	3b 55 d4             	cmp    -0x2c(%ebp),%edx
f0100e4b:	72 24                	jb     f0100e71 <check_page_free_list+0x1b6>
f0100e4d:	c7 44 24 0c 07 4e 10 	movl   $0xf0104e07,0xc(%esp)
f0100e54:	f0 
f0100e55:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f0100e5c:	f0 
f0100e5d:	c7 44 24 04 32 02 00 	movl   $0x232,0x4(%esp)
f0100e64:	00 
f0100e65:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f0100e6c:	e8 23 f2 ff ff       	call   f0100094 <_panic>
		assert(((char *) pp - (char *) pages) % sizeof(*pp) == 0);
f0100e71:	89 d0                	mov    %edx,%eax
f0100e73:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0100e76:	a8 07                	test   $0x7,%al
f0100e78:	74 24                	je     f0100e9e <check_page_free_list+0x1e3>
f0100e7a:	c7 44 24 0c f8 46 10 	movl   $0xf01046f8,0xc(%esp)
f0100e81:	f0 
f0100e82:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f0100e89:	f0 
f0100e8a:	c7 44 24 04 33 02 00 	movl   $0x233,0x4(%esp)
f0100e91:	00 
f0100e92:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f0100e99:	e8 f6 f1 ff ff       	call   f0100094 <_panic>
f0100e9e:	c1 f8 03             	sar    $0x3,%eax
f0100ea1:	c1 e0 0c             	shl    $0xc,%eax

		// check a few pages that shouldn't be on the free list
		assert(page2pa(pp) != 0);
f0100ea4:	85 c0                	test   %eax,%eax
f0100ea6:	75 24                	jne    f0100ecc <check_page_free_list+0x211>
f0100ea8:	c7 44 24 0c 1b 4e 10 	movl   $0xf0104e1b,0xc(%esp)
f0100eaf:	f0 
f0100eb0:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f0100eb7:	f0 
f0100eb8:	c7 44 24 04 36 02 00 	movl   $0x236,0x4(%esp)
f0100ebf:	00 
f0100ec0:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f0100ec7:	e8 c8 f1 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != IOPHYSMEM);
f0100ecc:	3d 00 00 0a 00       	cmp    $0xa0000,%eax
f0100ed1:	75 24                	jne    f0100ef7 <check_page_free_list+0x23c>
f0100ed3:	c7 44 24 0c 2c 4e 10 	movl   $0xf0104e2c,0xc(%esp)
f0100eda:	f0 
f0100edb:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f0100ee2:	f0 
f0100ee3:	c7 44 24 04 37 02 00 	movl   $0x237,0x4(%esp)
f0100eea:	00 
f0100eeb:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f0100ef2:	e8 9d f1 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM - PGSIZE);
f0100ef7:	3d 00 f0 0f 00       	cmp    $0xff000,%eax
f0100efc:	75 24                	jne    f0100f22 <check_page_free_list+0x267>
f0100efe:	c7 44 24 0c 2c 47 10 	movl   $0xf010472c,0xc(%esp)
f0100f05:	f0 
f0100f06:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f0100f0d:	f0 
f0100f0e:	c7 44 24 04 38 02 00 	movl   $0x238,0x4(%esp)
f0100f15:	00 
f0100f16:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f0100f1d:	e8 72 f1 ff ff       	call   f0100094 <_panic>
		assert(page2pa(pp) != EXTPHYSMEM);
f0100f22:	3d 00 00 10 00       	cmp    $0x100000,%eax
f0100f27:	75 24                	jne    f0100f4d <check_page_free_list+0x292>
f0100f29:	c7 44 24 0c 45 4e 10 	movl   $0xf0104e45,0xc(%esp)
f0100f30:	f0 
f0100f31:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f0100f38:	f0 
f0100f39:	c7 44 24 04 39 02 00 	movl   $0x239,0x4(%esp)
f0100f40:	00 
f0100f41:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
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
f0100f62:	c7 44 24 08 b0 46 10 	movl   $0xf01046b0,0x8(%esp)
f0100f69:	f0 
f0100f6a:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0100f71:	00 
f0100f72:	c7 04 24 d8 4d 10 f0 	movl   $0xf0104dd8,(%esp)
f0100f79:	e8 16 f1 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0100f7e:	81 e9 00 00 00 10    	sub    $0x10000000,%ecx
f0100f84:	39 4d c8             	cmp    %ecx,-0x38(%ebp)
f0100f87:	76 29                	jbe    f0100fb2 <check_page_free_list+0x2f7>
f0100f89:	c7 44 24 0c 50 47 10 	movl   $0xf0104750,0xc(%esp)
f0100f90:	f0 
f0100f91:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f0100f98:	f0 
f0100f99:	c7 44 24 04 3a 02 00 	movl   $0x23a,0x4(%esp)
f0100fa0:	00 
f0100fa1:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
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
f0100fc3:	c7 44 24 0c 5f 4e 10 	movl   $0xf0104e5f,0xc(%esp)
f0100fca:	f0 
f0100fcb:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f0100fd2:	f0 
f0100fd3:	c7 44 24 04 42 02 00 	movl   $0x242,0x4(%esp)
f0100fda:	00 
f0100fdb:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f0100fe2:	e8 ad f0 ff ff       	call   f0100094 <_panic>
	assert(nfree_extmem > 0);
f0100fe7:	85 f6                	test   %esi,%esi
f0100fe9:	7f 24                	jg     f010100f <check_page_free_list+0x354>
f0100feb:	c7 44 24 0c 71 4e 10 	movl   $0xf0104e71,0xc(%esp)
f0100ff2:	f0 
f0100ff3:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f0100ffa:	f0 
f0100ffb:	c7 44 24 04 43 02 00 	movl   $0x243,0x4(%esp)
f0101002:	00 
f0101003:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
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
f0101034:	c7 44 24 08 98 47 10 	movl   $0xf0104798,0x8(%esp)
f010103b:	f0 
f010103c:	c7 44 24 04 05 01 00 	movl   $0x105,0x4(%esp)
f0101043:	00 
f0101044:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f010104b:	e8 44 f0 ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0101050:	8d 98 00 00 00 10    	lea    0x10000000(%eax),%ebx
f0101056:	c1 eb 0c             	shr    $0xc,%ebx
//	cprintf("00");
	page_free_list = NULL;
f0101059:	c7 05 60 85 11 f0 00 	movl   $0x0,0xf0118560
f0101060:	00 00 00 
	for (i = 0; i < npages; i++) {
f0101063:	83 3d 84 89 11 f0 00 	cmpl   $0x0,0xf0118984
f010106a:	74 64                	je     f01010d0 <page_init+0xb9>
f010106c:	b8 00 00 00 00       	mov    $0x0,%eax
f0101071:	ba 00 00 00 00       	mov    $0x0,%edx
		if (i == 0 || (i >= low && i < top)){
f0101076:	85 d2                	test   %edx,%edx
f0101078:	74 0c                	je     f0101086 <page_init+0x6f>
f010107a:	81 fa 9f 00 00 00    	cmp    $0x9f,%edx
f0101080:	76 1f                	jbe    f01010a1 <page_init+0x8a>
f0101082:	39 da                	cmp    %ebx,%edx
f0101084:	73 1b                	jae    f01010a1 <page_init+0x8a>
			pages[i].pp_ref = 1;
f0101086:	8d 0c d5 00 00 00 00 	lea    0x0(,%edx,8),%ecx
f010108d:	03 0d 8c 89 11 f0    	add    0xf011898c,%ecx
f0101093:	66 c7 41 04 01 00    	movw   $0x1,0x4(%ecx)
			pages[i].pp_link = NULL;
f0101099:	c7 01 00 00 00 00    	movl   $0x0,(%ecx)
			continue;
f010109f:	eb 1f                	jmp    f01010c0 <page_init+0xa9>
		}
		pages[i].pp_ref = 0;
f01010a1:	8d 0c d5 00 00 00 00 	lea    0x0(,%edx,8),%ecx
f01010a8:	8b 35 8c 89 11 f0    	mov    0xf011898c,%esi
f01010ae:	66 c7 44 0e 04 00 00 	movw   $0x0,0x4(%esi,%ecx,1)
	//	cprintf("%d\n", i);
		pages[i].pp_link = page_free_list;
f01010b5:	89 04 d6             	mov    %eax,(%esi,%edx,8)
		page_free_list = &pages[i];
f01010b8:	89 c8                	mov    %ecx,%eax
f01010ba:	03 05 8c 89 11 f0    	add    0xf011898c,%eax
	size_t i;
	size_t low = IOPHYSMEM / PGSIZE;	
	size_t top = (PADDR(boot_alloc(0))) / PGSIZE;
//	cprintf("00");
	page_free_list = NULL;
	for (i = 0; i < npages; i++) {
f01010c0:	83 c2 01             	add    $0x1,%edx
f01010c3:	39 15 84 89 11 f0    	cmp    %edx,0xf0118984
f01010c9:	77 ab                	ja     f0101076 <page_init+0x5f>
f01010cb:	a3 60 85 11 f0       	mov    %eax,0xf0118560
		pages[i].pp_ref = 0;
	//	cprintf("%d\n", i);
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
}
f01010d0:	83 c4 10             	add    $0x10,%esp
f01010d3:	5b                   	pop    %ebx
f01010d4:	5e                   	pop    %esi
f01010d5:	5d                   	pop    %ebp
f01010d6:	c3                   	ret    

f01010d7 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f01010d7:	55                   	push   %ebp
f01010d8:	89 e5                	mov    %esp,%ebp
f01010da:	83 ec 18             	sub    $0x18,%esp
	// Fill this function in
	if (page_free_list != NULL) {
f01010dd:	a1 60 85 11 f0       	mov    0xf0118560,%eax
f01010e2:	85 c0                	test   %eax,%eax
f01010e4:	74 6b                	je     f0101151 <page_alloc+0x7a>
		if (alloc_flags & ALLOC_ZERO) {
f01010e6:	f6 45 08 01          	testb  $0x1,0x8(%ebp)
f01010ea:	74 56                	je     f0101142 <page_alloc+0x6b>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01010ec:	2b 05 8c 89 11 f0    	sub    0xf011898c,%eax
f01010f2:	c1 f8 03             	sar    $0x3,%eax
f01010f5:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01010f8:	89 c2                	mov    %eax,%edx
f01010fa:	c1 ea 0c             	shr    $0xc,%edx
f01010fd:	3b 15 84 89 11 f0    	cmp    0xf0118984,%edx
f0101103:	72 20                	jb     f0101125 <page_alloc+0x4e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101105:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101109:	c7 44 24 08 b0 46 10 	movl   $0xf01046b0,0x8(%esp)
f0101110:	f0 
f0101111:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0101118:	00 
f0101119:	c7 04 24 d8 4d 10 f0 	movl   $0xf0104dd8,(%esp)
f0101120:	e8 6f ef ff ff       	call   f0100094 <_panic>
//			cprintf("\n````!!!");
			memset(page2kva(page_free_list), 0, PGSIZE);
f0101125:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010112c:	00 
f010112d:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101134:	00 
	return (void *)(pa + KERNBASE);
f0101135:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010113a:	89 04 24             	mov    %eax,(%esp)
f010113d:	e8 bf 2a 00 00       	call   f0103c01 <memset>
		}
		struct PageInfo* temp = page_free_list;
f0101142:	a1 60 85 11 f0       	mov    0xf0118560,%eax
		page_free_list = page_free_list->pp_link;
f0101147:	8b 10                	mov    (%eax),%edx
f0101149:	89 15 60 85 11 f0    	mov    %edx,0xf0118560
//		return (struct PageInfo*) page_free_list;
		return temp;
f010114f:	eb 05                	jmp    f0101156 <page_alloc+0x7f>
	}
	return NULL;
f0101151:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101156:	c9                   	leave  
f0101157:	c3                   	ret    

f0101158 <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0101158:	55                   	push   %ebp
f0101159:	89 e5                	mov    %esp,%ebp
f010115b:	8b 45 08             	mov    0x8(%ebp),%eax
	// Fill this function in
	pp->pp_link = page_free_list;
f010115e:	8b 15 60 85 11 f0    	mov    0xf0118560,%edx
f0101164:	89 10                	mov    %edx,(%eax)
	page_free_list = pp;
f0101166:	a3 60 85 11 f0       	mov    %eax,0xf0118560
}
f010116b:	5d                   	pop    %ebp
f010116c:	c3                   	ret    

f010116d <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f010116d:	55                   	push   %ebp
f010116e:	89 e5                	mov    %esp,%ebp
f0101170:	83 ec 04             	sub    $0x4,%esp
f0101173:	8b 45 08             	mov    0x8(%ebp),%eax
	if (--pp->pp_ref == 0)
f0101176:	0f b7 50 04          	movzwl 0x4(%eax),%edx
f010117a:	83 ea 01             	sub    $0x1,%edx
f010117d:	66 89 50 04          	mov    %dx,0x4(%eax)
f0101181:	66 85 d2             	test   %dx,%dx
f0101184:	75 08                	jne    f010118e <page_decref+0x21>
		page_free(pp);
f0101186:	89 04 24             	mov    %eax,(%esp)
f0101189:	e8 ca ff ff ff       	call   f0101158 <page_free>
}
f010118e:	c9                   	leave  
f010118f:	c3                   	ret    

f0101190 <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0101190:	55                   	push   %ebp
f0101191:	89 e5                	mov    %esp,%ebp
f0101193:	56                   	push   %esi
f0101194:	53                   	push   %ebx
f0101195:	83 ec 10             	sub    $0x10,%esp
f0101198:	8b 75 0c             	mov    0xc(%ebp),%esi
	// Fill this function in
	bool exist = false;
	pte_t *ptdir;
	if	(pgdir[PDX(va)] & PTE_P) {
f010119b:	89 f3                	mov    %esi,%ebx
f010119d:	c1 eb 16             	shr    $0x16,%ebx
f01011a0:	c1 e3 02             	shl    $0x2,%ebx
f01011a3:	03 5d 08             	add    0x8(%ebp),%ebx
f01011a6:	8b 03                	mov    (%ebx),%eax
f01011a8:	a8 01                	test   $0x1,%al
f01011aa:	74 47                	je     f01011f3 <pgdir_walk+0x63>
//		pte_t * ptdir = (pte_t*) (PGNUM(*(pgdir + PDX(va))) << PGSHIFT);
		ptdir = (pte_t*) KADDR(PTE_ADDR(pgdir[PDX(va)]));
f01011ac:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01011b1:	89 c2                	mov    %eax,%edx
f01011b3:	c1 ea 0c             	shr    $0xc,%edx
f01011b6:	3b 15 84 89 11 f0    	cmp    0xf0118984,%edx
f01011bc:	72 20                	jb     f01011de <pgdir_walk+0x4e>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01011be:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01011c2:	c7 44 24 08 b0 46 10 	movl   $0xf01046b0,0x8(%esp)
f01011c9:	f0 
f01011ca:	c7 44 24 04 64 01 00 	movl   $0x164,0x4(%esp)
f01011d1:	00 
f01011d2:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f01011d9:	e8 b6 ee ff ff       	call   f0100094 <_panic>
//		pgdir[PDX(va)];
//		cprintf("%d", va);
		return ptdir + PTX(va);
f01011de:	c1 ee 0a             	shr    $0xa,%esi
f01011e1:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f01011e7:	8d 84 30 00 00 00 f0 	lea    -0x10000000(%eax,%esi,1),%eax
f01011ee:	e9 85 00 00 00       	jmp    f0101278 <pgdir_walk+0xe8>
	} else {
		if (create) {
f01011f3:	83 7d 10 00          	cmpl   $0x0,0x10(%ebp)
f01011f7:	74 73                	je     f010126c <pgdir_walk+0xdc>
			struct PageInfo * temp = page_alloc(ALLOC_ZERO);
f01011f9:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101200:	e8 d2 fe ff ff       	call   f01010d7 <page_alloc>
			if (temp == NULL) return NULL;
f0101205:	85 c0                	test   %eax,%eax
f0101207:	74 6a                	je     f0101273 <pgdir_walk+0xe3>
			temp->pp_ref++;
f0101209:	66 83 40 04 01       	addw   $0x1,0x4(%eax)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010120e:	89 c2                	mov    %eax,%edx
f0101210:	2b 15 8c 89 11 f0    	sub    0xf011898c,%edx
f0101216:	c1 fa 03             	sar    $0x3,%edx
f0101219:	c1 e2 0c             	shl    $0xc,%edx
			pgdir[PDX(va)] = page2pa(temp) | PTE_P | PTE_U | PTE_W;
f010121c:	83 ca 07             	or     $0x7,%edx
f010121f:	89 13                	mov    %edx,(%ebx)
f0101221:	2b 05 8c 89 11 f0    	sub    0xf011898c,%eax
f0101227:	c1 f8 03             	sar    $0x3,%eax
f010122a:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010122d:	89 c2                	mov    %eax,%edx
f010122f:	c1 ea 0c             	shr    $0xc,%edx
f0101232:	3b 15 84 89 11 f0    	cmp    0xf0118984,%edx
f0101238:	72 20                	jb     f010125a <pgdir_walk+0xca>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f010123a:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010123e:	c7 44 24 08 b0 46 10 	movl   $0xf01046b0,0x8(%esp)
f0101245:	f0 
f0101246:	c7 44 24 04 6e 01 00 	movl   $0x16e,0x4(%esp)
f010124d:	00 
f010124e:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f0101255:	e8 3a ee ff ff       	call   f0100094 <_panic>
			ptdir = (pte_t*) KADDR(page2pa(temp));
			return ptdir + PTX(va);
f010125a:	c1 ee 0a             	shr    $0xa,%esi
f010125d:	81 e6 fc 0f 00 00    	and    $0xffc,%esi
f0101263:	8d 84 30 00 00 00 f0 	lea    -0x10000000(%eax,%esi,1),%eax
f010126a:	eb 0c                	jmp    f0101278 <pgdir_walk+0xe8>
		} else return NULL;
f010126c:	b8 00 00 00 00       	mov    $0x0,%eax
f0101271:	eb 05                	jmp    f0101278 <pgdir_walk+0xe8>
//		cprintf("%d", va);
		return ptdir + PTX(va);
	} else {
		if (create) {
			struct PageInfo * temp = page_alloc(ALLOC_ZERO);
			if (temp == NULL) return NULL;
f0101273:	b8 00 00 00 00       	mov    $0x0,%eax
			return ptdir + PTX(va);
		} else return NULL;
	}
	//temp + PTXSHIFT(va)
	return NULL;
}
f0101278:	83 c4 10             	add    $0x10,%esp
f010127b:	5b                   	pop    %ebx
f010127c:	5e                   	pop    %esi
f010127d:	5d                   	pop    %ebp
f010127e:	c3                   	ret    

f010127f <boot_map_region>:
// mapped pages.
// 
// Hint: the TA solution uses pgdir_walk
static void
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
f010127f:	55                   	push   %ebp
f0101280:	89 e5                	mov    %esp,%ebp
f0101282:	57                   	push   %edi
f0101283:	56                   	push   %esi
f0101284:	53                   	push   %ebx
f0101285:	83 ec 2c             	sub    $0x2c,%esp
f0101288:	89 c7                	mov    %eax,%edi
f010128a:	89 d3                	mov    %edx,%ebx
f010128c:	8b 75 08             	mov    0x8(%ebp),%esi
	// Fill this function in
	uintptr_t end = va + size;
f010128f:	01 d1                	add    %edx,%ecx
f0101291:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
	pte_t* now;
	for (;va != end; va += PGSIZE, pa += PGSIZE) {
f0101294:	39 ca                	cmp    %ecx,%edx
f0101296:	74 5b                	je     f01012f3 <boot_map_region+0x74>
		now = pgdir_walk(pgdir, (void*)va, true);
		if (now == NULL)
			panic("stopped");
		*now = PTE_ADDR(pa) | perm | PTE_P;
f0101298:	8b 45 0c             	mov    0xc(%ebp),%eax
f010129b:	83 c8 01             	or     $0x1,%eax
f010129e:	89 45 e0             	mov    %eax,-0x20(%ebp)
{
	// Fill this function in
	uintptr_t end = va + size;
	pte_t* now;
	for (;va != end; va += PGSIZE, pa += PGSIZE) {
		now = pgdir_walk(pgdir, (void*)va, true);
f01012a1:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f01012a8:	00 
f01012a9:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01012ad:	89 3c 24             	mov    %edi,(%esp)
f01012b0:	e8 db fe ff ff       	call   f0101190 <pgdir_walk>
		if (now == NULL)
f01012b5:	85 c0                	test   %eax,%eax
f01012b7:	75 1c                	jne    f01012d5 <boot_map_region+0x56>
			panic("stopped");
f01012b9:	c7 44 24 08 82 4e 10 	movl   $0xf0104e82,0x8(%esp)
f01012c0:	f0 
f01012c1:	c7 44 24 04 89 01 00 	movl   $0x189,0x4(%esp)
f01012c8:	00 
f01012c9:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f01012d0:	e8 bf ed ff ff       	call   f0100094 <_panic>
		*now = PTE_ADDR(pa) | perm | PTE_P;
f01012d5:	89 f2                	mov    %esi,%edx
f01012d7:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01012dd:	0b 55 e0             	or     -0x20(%ebp),%edx
f01012e0:	89 10                	mov    %edx,(%eax)
boot_map_region(pde_t *pgdir, uintptr_t va, size_t size, physaddr_t pa, int perm)
{
	// Fill this function in
	uintptr_t end = va + size;
	pte_t* now;
	for (;va != end; va += PGSIZE, pa += PGSIZE) {
f01012e2:	81 c3 00 10 00 00    	add    $0x1000,%ebx
f01012e8:	81 c6 00 10 00 00    	add    $0x1000,%esi
f01012ee:	39 5d e4             	cmp    %ebx,-0x1c(%ebp)
f01012f1:	75 ae                	jne    f01012a1 <boot_map_region+0x22>
		now = pgdir_walk(pgdir, (void*)va, true);
		if (now == NULL)
			panic("stopped");
		*now = PTE_ADDR(pa) | perm | PTE_P;
	}
}
f01012f3:	83 c4 2c             	add    $0x2c,%esp
f01012f6:	5b                   	pop    %ebx
f01012f7:	5e                   	pop    %esi
f01012f8:	5f                   	pop    %edi
f01012f9:	5d                   	pop    %ebp
f01012fa:	c3                   	ret    

f01012fb <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f01012fb:	55                   	push   %ebp
f01012fc:	89 e5                	mov    %esp,%ebp
f01012fe:	53                   	push   %ebx
f01012ff:	83 ec 14             	sub    $0x14,%esp
f0101302:	8b 5d 10             	mov    0x10(%ebp),%ebx
	// Fill this function in
	pte_t* now = pgdir_walk(pgdir, va, 0);
f0101305:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f010130c:	00 
f010130d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101310:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101314:	8b 45 08             	mov    0x8(%ebp),%eax
f0101317:	89 04 24             	mov    %eax,(%esp)
f010131a:	e8 71 fe ff ff       	call   f0101190 <pgdir_walk>
	if (now != NULL) {
f010131f:	85 c0                	test   %eax,%eax
f0101321:	74 3a                	je     f010135d <page_lookup+0x62>
		if (pte_store != NULL) {
f0101323:	85 db                	test   %ebx,%ebx
f0101325:	74 02                	je     f0101329 <page_lookup+0x2e>
			*pte_store = now;
f0101327:	89 03                	mov    %eax,(%ebx)
		}
		return pa2page(PTE_ADDR(*now));
f0101329:	8b 00                	mov    (%eax),%eax
}

static inline struct PageInfo*
pa2page(physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f010132b:	c1 e8 0c             	shr    $0xc,%eax
f010132e:	3b 05 84 89 11 f0    	cmp    0xf0118984,%eax
f0101334:	72 1c                	jb     f0101352 <page_lookup+0x57>
		panic("pa2page called with invalid pa");
f0101336:	c7 44 24 08 bc 47 10 	movl   $0xf01047bc,0x8(%esp)
f010133d:	f0 
f010133e:	c7 44 24 04 4b 00 00 	movl   $0x4b,0x4(%esp)
f0101345:	00 
f0101346:	c7 04 24 d8 4d 10 f0 	movl   $0xf0104dd8,(%esp)
f010134d:	e8 42 ed ff ff       	call   f0100094 <_panic>
	return &pages[PGNUM(pa)];
f0101352:	c1 e0 03             	shl    $0x3,%eax
f0101355:	03 05 8c 89 11 f0    	add    0xf011898c,%eax
f010135b:	eb 05                	jmp    f0101362 <page_lookup+0x67>
	}
	return NULL;
f010135d:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101362:	83 c4 14             	add    $0x14,%esp
f0101365:	5b                   	pop    %ebx
f0101366:	5d                   	pop    %ebp
f0101367:	c3                   	ret    

f0101368 <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0101368:	55                   	push   %ebp
f0101369:	89 e5                	mov    %esp,%ebp
f010136b:	83 ec 28             	sub    $0x28,%esp
	// Fill this function in
//	if (pgdir & PTE_P == 1) {
	pte_t* now;	
	struct PageInfo* temp = page_lookup(pgdir, va, &now);
f010136e:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0101371:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101375:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101378:	89 44 24 04          	mov    %eax,0x4(%esp)
f010137c:	8b 45 08             	mov    0x8(%ebp),%eax
f010137f:	89 04 24             	mov    %eax,(%esp)
f0101382:	e8 74 ff ff ff       	call   f01012fb <page_lookup>
	if (temp != NULL) {
f0101387:	85 c0                	test   %eax,%eax
f0101389:	74 19                	je     f01013a4 <page_remove+0x3c>
//		cprintf("%d", now);
		if (*now & PTE_P) {
f010138b:	8b 55 f4             	mov    -0xc(%ebp),%edx
f010138e:	f6 02 01             	testb  $0x1,(%edx)
f0101391:	74 08                	je     f010139b <page_remove+0x33>
//			cprintf("subtraction finish!");
			page_decref(temp);
f0101393:	89 04 24             	mov    %eax,(%esp)
f0101396:	e8 d2 fd ff ff       	call   f010116d <page_decref>
		}
		//page_decref(temp);
	//}
		*now = 0;
f010139b:	8b 45 f4             	mov    -0xc(%ebp),%eax
f010139e:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	}

}
f01013a4:	c9                   	leave  
f01013a5:	c3                   	ret    

f01013a6 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa隐式声明函数‘page_walk’.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f01013a6:	55                   	push   %ebp
f01013a7:	89 e5                	mov    %esp,%ebp
f01013a9:	83 ec 28             	sub    $0x28,%esp
f01013ac:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f01013af:	89 75 f8             	mov    %esi,-0x8(%ebp)
f01013b2:	89 7d fc             	mov    %edi,-0x4(%ebp)
f01013b5:	8b 75 0c             	mov    0xc(%ebp),%esi
f01013b8:	8b 7d 10             	mov    0x10(%ebp),%edi
	// Fill this function in
	pte_t* now = pgdir_walk(pgdir, va, 0);
f01013bb:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01013c2:	00 
f01013c3:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01013c7:	8b 45 08             	mov    0x8(%ebp),%eax
f01013ca:	89 04 24             	mov    %eax,(%esp)
f01013cd:	e8 be fd ff ff       	call   f0101190 <pgdir_walk>
f01013d2:	89 c3                	mov    %eax,%ebx
	if ((now != NULL) && (*now & PTE_P)) {
f01013d4:	85 c0                	test   %eax,%eax
f01013d6:	74 3f                	je     f0101417 <page_insert+0x71>
f01013d8:	8b 00                	mov    (%eax),%eax
f01013da:	a8 01                	test   $0x1,%al
f01013dc:	74 5b                	je     f0101439 <page_insert+0x93>
		//cprintf("!");
//		PageInfo* now_page = (PageInfo*) pa2page(PTE_ADDR(now) + PGOFF(va));
//		page_remove(now_page);
		if (PTE_ADDR(*now) == page2pa(pp)) {
f01013de:	25 00 f0 ff ff       	and    $0xfffff000,%eax
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01013e3:	89 f2                	mov    %esi,%edx
f01013e5:	2b 15 8c 89 11 f0    	sub    0xf011898c,%edx
f01013eb:	c1 fa 03             	sar    $0x3,%edx
f01013ee:	c1 e2 0c             	shl    $0xc,%edx
f01013f1:	39 d0                	cmp    %edx,%eax
f01013f3:	75 11                	jne    f0101406 <page_insert+0x60>
			*now = PTE_ADDR(page2pa(pp)) | perm | PTE_P;
f01013f5:	8b 55 14             	mov    0x14(%ebp),%edx
f01013f8:	83 ca 01             	or     $0x1,%edx
f01013fb:	09 d0                	or     %edx,%eax
f01013fd:	89 03                	mov    %eax,(%ebx)
			return 0;
f01013ff:	b8 00 00 00 00       	mov    $0x0,%eax
f0101404:	eb 55                	jmp    f010145b <page_insert+0xb5>
		}
//		cprintf("%d\n", *now);
		page_remove(pgdir, va);
f0101406:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010140a:	8b 45 08             	mov    0x8(%ebp),%eax
f010140d:	89 04 24             	mov    %eax,(%esp)
f0101410:	e8 53 ff ff ff       	call   f0101368 <page_remove>
f0101415:	eb 22                	jmp    f0101439 <page_insert+0x93>
	}
	if (now == NULL) now = pgdir_walk(pgdir, va, 1);
f0101417:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f010141e:	00 
f010141f:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101423:	8b 45 08             	mov    0x8(%ebp),%eax
f0101426:	89 04 24             	mov    %eax,(%esp)
f0101429:	e8 62 fd ff ff       	call   f0101190 <pgdir_walk>
f010142e:	89 c3                	mov    %eax,%ebx
	if (now == NULL) return -E_NO_MEM;
f0101430:	b8 fc ff ff ff       	mov    $0xfffffffc,%eax
f0101435:	85 db                	test   %ebx,%ebx
f0101437:	74 22                	je     f010145b <page_insert+0xb5>
	*now = PTE_ADDR(page2pa(pp)) | perm | PTE_P;
f0101439:	8b 45 14             	mov    0x14(%ebp),%eax
f010143c:	83 c8 01             	or     $0x1,%eax
f010143f:	89 f2                	mov    %esi,%edx
f0101441:	2b 15 8c 89 11 f0    	sub    0xf011898c,%edx
f0101447:	c1 fa 03             	sar    $0x3,%edx
f010144a:	c1 e2 0c             	shl    $0xc,%edx
f010144d:	09 d0                	or     %edx,%eax
f010144f:	89 03                	mov    %eax,(%ebx)
	pp->pp_ref++;
f0101451:	66 83 46 04 01       	addw   $0x1,0x4(%esi)
	return 0;
f0101456:	b8 00 00 00 00       	mov    $0x0,%eax
}
f010145b:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f010145e:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0101461:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0101464:	89 ec                	mov    %ebp,%esp
f0101466:	5d                   	pop    %ebp
f0101467:	c3                   	ret    

f0101468 <mem_init>:
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
{
f0101468:	55                   	push   %ebp
f0101469:	89 e5                	mov    %esp,%ebp
f010146b:	57                   	push   %edi
f010146c:	56                   	push   %esi
f010146d:	53                   	push   %ebx
f010146e:	83 ec 3c             	sub    $0x3c,%esp
{
	size_t npages_extmem;

	// Use CMOS calls to measure available base & extended memory.
	// (CMOS calls return results in kilobytes.)
	npages_basemem = (nvram_read(NVRAM_BASELO) * 1024) / PGSIZE;
f0101471:	b8 15 00 00 00       	mov    $0x15,%eax
f0101476:	e8 0e f8 ff ff       	call   f0100c89 <nvram_read>
f010147b:	c1 e0 0a             	shl    $0xa,%eax
f010147e:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f0101484:	85 c0                	test   %eax,%eax
f0101486:	0f 48 c2             	cmovs  %edx,%eax
f0101489:	c1 f8 0c             	sar    $0xc,%eax
f010148c:	a3 58 85 11 f0       	mov    %eax,0xf0118558
	npages_extmem = (nvram_read(NVRAM_EXTLO) * 1024) / PGSIZE;
f0101491:	b8 17 00 00 00       	mov    $0x17,%eax
f0101496:	e8 ee f7 ff ff       	call   f0100c89 <nvram_read>
f010149b:	c1 e0 0a             	shl    $0xa,%eax
f010149e:	8d 90 ff 0f 00 00    	lea    0xfff(%eax),%edx
f01014a4:	85 c0                	test   %eax,%eax
f01014a6:	0f 48 c2             	cmovs  %edx,%eax
f01014a9:	c1 f8 0c             	sar    $0xc,%eax

	// Calculate the number of physical pages available in both base
	// and extended memory.
	if (npages_extmem)
f01014ac:	85 c0                	test   %eax,%eax
f01014ae:	74 0e                	je     f01014be <mem_init+0x56>
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
f01014b0:	8d 90 00 01 00 00    	lea    0x100(%eax),%edx
f01014b6:	89 15 84 89 11 f0    	mov    %edx,0xf0118984
f01014bc:	eb 0c                	jmp    f01014ca <mem_init+0x62>
	else
		npages = npages_basemem;
f01014be:	8b 15 58 85 11 f0    	mov    0xf0118558,%edx
f01014c4:	89 15 84 89 11 f0    	mov    %edx,0xf0118984

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
		npages_extmem * PGSIZE / 1024);
f01014ca:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01014cd:	c1 e8 0a             	shr    $0xa,%eax
f01014d0:	89 44 24 0c          	mov    %eax,0xc(%esp)
		npages * PGSIZE / 1024,
		npages_basemem * PGSIZE / 1024,
f01014d4:	a1 58 85 11 f0       	mov    0xf0118558,%eax
f01014d9:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01014dc:	c1 e8 0a             	shr    $0xa,%eax
f01014df:	89 44 24 08          	mov    %eax,0x8(%esp)
		npages * PGSIZE / 1024,
f01014e3:	a1 84 89 11 f0       	mov    0xf0118984,%eax
f01014e8:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f01014eb:	c1 e8 0a             	shr    $0xa,%eax
f01014ee:	89 44 24 04          	mov    %eax,0x4(%esp)
f01014f2:	c7 04 24 dc 47 10 f0 	movl   $0xf01047dc,(%esp)
f01014f9:	e8 4c 1b 00 00       	call   f010304a <cprintf>
	// Remove this line when you're ready to test this function.
//	panic("mem_init: This function is not finished\n");

	//////////////////////////////////////////////////////////////////////
	// create initial page directory.
	kern_pgdir = (pde_t *) boot_alloc(PGSIZE);
f01014fe:	b8 00 10 00 00       	mov    $0x1000,%eax
f0101503:	e8 d4 f6 ff ff       	call   f0100bdc <boot_alloc>
f0101508:	a3 88 89 11 f0       	mov    %eax,0xf0118988
	memset(kern_pgdir, 0, PGSIZE);
f010150d:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101514:	00 
f0101515:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010151c:	00 
f010151d:	89 04 24             	mov    %eax,(%esp)
f0101520:	e8 dc 26 00 00       	call   f0103c01 <memset>
	// a virtual page table at virtual address UVPT.
	// (For now, you don't have understand the greater purpose of the
	// following line.)

	// Permissions: kernel R, user R
	kern_pgdir[PDX(UVPT)] = PADDR(kern_pgdir) | PTE_U | PTE_P;
f0101525:	a1 88 89 11 f0       	mov    0xf0118988,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010152a:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f010152f:	77 20                	ja     f0101551 <mem_init+0xe9>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0101531:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101535:	c7 44 24 08 98 47 10 	movl   $0xf0104798,0x8(%esp)
f010153c:	f0 
f010153d:	c7 44 24 04 91 00 00 	movl   $0x91,0x4(%esp)
f0101544:	00 
f0101545:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f010154c:	e8 43 eb ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0101551:	8d 90 00 00 00 10    	lea    0x10000000(%eax),%edx
f0101557:	83 ca 05             	or     $0x5,%edx
f010155a:	89 90 f4 0e 00 00    	mov    %edx,0xef4(%eax)
	// Allocate an array of npages 'struct PageInfo's and store it in 'pages'.
	// The kernel uses this array to keep track of physical pages: for
	// each physical page, there is a corresponding struct PageInfo in this
	// array.  'npages' is the number of physical pages in memory.
	// Your code goes here:
	pages = (struct PageInfo*) boot_alloc(npages * sizeof(struct PageInfo));
f0101560:	a1 84 89 11 f0       	mov    0xf0118984,%eax
f0101565:	c1 e0 03             	shl    $0x3,%eax
f0101568:	e8 6f f6 ff ff       	call   f0100bdc <boot_alloc>
f010156d:	a3 8c 89 11 f0       	mov    %eax,0xf011898c
	// Now that we've allocated the initial kernel data structures, we set
	// up the list of free physical pages. Once we've done so, all further
	// memory management will go through the page_* functions. In
	// particular, we can now map memory using boot_map_region
	// or page_insert
	page_init();
f0101572:	e8 a0 fa ff ff       	call   f0101017 <page_init>
	//cprintf("!!!");

	check_page_free_list(1);
f0101577:	b8 01 00 00 00       	mov    $0x1,%eax
f010157c:	e8 3a f7 ff ff       	call   f0100cbb <check_page_free_list>
	int nfree;
	struct PageInfo *fl;
	char *c;
	int i;

	if (!pages)
f0101581:	83 3d 8c 89 11 f0 00 	cmpl   $0x0,0xf011898c
f0101588:	75 1c                	jne    f01015a6 <mem_init+0x13e>
		panic("'pages' is a null pointer!");
f010158a:	c7 44 24 08 8a 4e 10 	movl   $0xf0104e8a,0x8(%esp)
f0101591:	f0 
f0101592:	c7 44 24 04 54 02 00 	movl   $0x254,0x4(%esp)
f0101599:	00 
f010159a:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f01015a1:	e8 ee ea ff ff       	call   f0100094 <_panic>

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01015a6:	a1 60 85 11 f0       	mov    0xf0118560,%eax
f01015ab:	bb 00 00 00 00       	mov    $0x0,%ebx
f01015b0:	85 c0                	test   %eax,%eax
f01015b2:	74 09                	je     f01015bd <mem_init+0x155>
		++nfree;
f01015b4:	83 c3 01             	add    $0x1,%ebx

	if (!pages)
		panic("'pages' is a null pointer!");

	// check number of free pages
	for (pp = page_free_list, nfree = 0; pp; pp = pp->pp_link)
f01015b7:	8b 00                	mov    (%eax),%eax
f01015b9:	85 c0                	test   %eax,%eax
f01015bb:	75 f7                	jne    f01015b4 <mem_init+0x14c>
		++nfree;

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01015bd:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01015c4:	e8 0e fb ff ff       	call   f01010d7 <page_alloc>
f01015c9:	89 c6                	mov    %eax,%esi
f01015cb:	85 c0                	test   %eax,%eax
f01015cd:	75 24                	jne    f01015f3 <mem_init+0x18b>
f01015cf:	c7 44 24 0c a5 4e 10 	movl   $0xf0104ea5,0xc(%esp)
f01015d6:	f0 
f01015d7:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f01015de:	f0 
f01015df:	c7 44 24 04 5c 02 00 	movl   $0x25c,0x4(%esp)
f01015e6:	00 
f01015e7:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f01015ee:	e8 a1 ea ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f01015f3:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01015fa:	e8 d8 fa ff ff       	call   f01010d7 <page_alloc>
f01015ff:	89 c7                	mov    %eax,%edi
f0101601:	85 c0                	test   %eax,%eax
f0101603:	75 24                	jne    f0101629 <mem_init+0x1c1>
f0101605:	c7 44 24 0c bb 4e 10 	movl   $0xf0104ebb,0xc(%esp)
f010160c:	f0 
f010160d:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f0101614:	f0 
f0101615:	c7 44 24 04 5d 02 00 	movl   $0x25d,0x4(%esp)
f010161c:	00 
f010161d:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f0101624:	e8 6b ea ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0101629:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101630:	e8 a2 fa ff ff       	call   f01010d7 <page_alloc>
f0101635:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101638:	85 c0                	test   %eax,%eax
f010163a:	75 24                	jne    f0101660 <mem_init+0x1f8>
f010163c:	c7 44 24 0c d1 4e 10 	movl   $0xf0104ed1,0xc(%esp)
f0101643:	f0 
f0101644:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f010164b:	f0 
f010164c:	c7 44 24 04 5e 02 00 	movl   $0x25e,0x4(%esp)
f0101653:	00 
f0101654:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f010165b:	e8 34 ea ff ff       	call   f0100094 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101660:	39 fe                	cmp    %edi,%esi
f0101662:	75 24                	jne    f0101688 <mem_init+0x220>
f0101664:	c7 44 24 0c e7 4e 10 	movl   $0xf0104ee7,0xc(%esp)
f010166b:	f0 
f010166c:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f0101673:	f0 
f0101674:	c7 44 24 04 61 02 00 	movl   $0x261,0x4(%esp)
f010167b:	00 
f010167c:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f0101683:	e8 0c ea ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101688:	3b 7d d4             	cmp    -0x2c(%ebp),%edi
f010168b:	74 05                	je     f0101692 <mem_init+0x22a>
f010168d:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f0101690:	75 24                	jne    f01016b6 <mem_init+0x24e>
f0101692:	c7 44 24 0c 18 48 10 	movl   $0xf0104818,0xc(%esp)
f0101699:	f0 
f010169a:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f01016a1:	f0 
f01016a2:	c7 44 24 04 62 02 00 	movl   $0x262,0x4(%esp)
f01016a9:	00 
f01016aa:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f01016b1:	e8 de e9 ff ff       	call   f0100094 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01016b6:	8b 15 8c 89 11 f0    	mov    0xf011898c,%edx
	assert(page2pa(pp0) < npages*PGSIZE);
f01016bc:	a1 84 89 11 f0       	mov    0xf0118984,%eax
f01016c1:	c1 e0 0c             	shl    $0xc,%eax
f01016c4:	89 f1                	mov    %esi,%ecx
f01016c6:	29 d1                	sub    %edx,%ecx
f01016c8:	c1 f9 03             	sar    $0x3,%ecx
f01016cb:	c1 e1 0c             	shl    $0xc,%ecx
f01016ce:	39 c1                	cmp    %eax,%ecx
f01016d0:	72 24                	jb     f01016f6 <mem_init+0x28e>
f01016d2:	c7 44 24 0c f9 4e 10 	movl   $0xf0104ef9,0xc(%esp)
f01016d9:	f0 
f01016da:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f01016e1:	f0 
f01016e2:	c7 44 24 04 63 02 00 	movl   $0x263,0x4(%esp)
f01016e9:	00 
f01016ea:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f01016f1:	e8 9e e9 ff ff       	call   f0100094 <_panic>
f01016f6:	89 f9                	mov    %edi,%ecx
f01016f8:	29 d1                	sub    %edx,%ecx
f01016fa:	c1 f9 03             	sar    $0x3,%ecx
f01016fd:	c1 e1 0c             	shl    $0xc,%ecx
	assert(page2pa(pp1) < npages*PGSIZE);
f0101700:	39 c8                	cmp    %ecx,%eax
f0101702:	77 24                	ja     f0101728 <mem_init+0x2c0>
f0101704:	c7 44 24 0c 16 4f 10 	movl   $0xf0104f16,0xc(%esp)
f010170b:	f0 
f010170c:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f0101713:	f0 
f0101714:	c7 44 24 04 64 02 00 	movl   $0x264,0x4(%esp)
f010171b:	00 
f010171c:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f0101723:	e8 6c e9 ff ff       	call   f0100094 <_panic>
f0101728:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f010172b:	29 d1                	sub    %edx,%ecx
f010172d:	89 ca                	mov    %ecx,%edx
f010172f:	c1 fa 03             	sar    $0x3,%edx
f0101732:	c1 e2 0c             	shl    $0xc,%edx
	assert(page2pa(pp2) < npages*PGSIZE);
f0101735:	39 d0                	cmp    %edx,%eax
f0101737:	77 24                	ja     f010175d <mem_init+0x2f5>
f0101739:	c7 44 24 0c 33 4f 10 	movl   $0xf0104f33,0xc(%esp)
f0101740:	f0 
f0101741:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f0101748:	f0 
f0101749:	c7 44 24 04 65 02 00 	movl   $0x265,0x4(%esp)
f0101750:	00 
f0101751:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f0101758:	e8 37 e9 ff ff       	call   f0100094 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f010175d:	a1 60 85 11 f0       	mov    0xf0118560,%eax
f0101762:	89 45 d0             	mov    %eax,-0x30(%ebp)
	page_free_list = 0;
f0101765:	c7 05 60 85 11 f0 00 	movl   $0x0,0xf0118560
f010176c:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f010176f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101776:	e8 5c f9 ff ff       	call   f01010d7 <page_alloc>
f010177b:	85 c0                	test   %eax,%eax
f010177d:	74 24                	je     f01017a3 <mem_init+0x33b>
f010177f:	c7 44 24 0c 50 4f 10 	movl   $0xf0104f50,0xc(%esp)
f0101786:	f0 
f0101787:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f010178e:	f0 
f010178f:	c7 44 24 04 6c 02 00 	movl   $0x26c,0x4(%esp)
f0101796:	00 
f0101797:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f010179e:	e8 f1 e8 ff ff       	call   f0100094 <_panic>

	// free and re-allocate?
	page_free(pp0);
f01017a3:	89 34 24             	mov    %esi,(%esp)
f01017a6:	e8 ad f9 ff ff       	call   f0101158 <page_free>
	page_free(pp1);
f01017ab:	89 3c 24             	mov    %edi,(%esp)
f01017ae:	e8 a5 f9 ff ff       	call   f0101158 <page_free>
	page_free(pp2);
f01017b3:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01017b6:	89 04 24             	mov    %eax,(%esp)
f01017b9:	e8 9a f9 ff ff       	call   f0101158 <page_free>
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f01017be:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01017c5:	e8 0d f9 ff ff       	call   f01010d7 <page_alloc>
f01017ca:	89 c6                	mov    %eax,%esi
f01017cc:	85 c0                	test   %eax,%eax
f01017ce:	75 24                	jne    f01017f4 <mem_init+0x38c>
f01017d0:	c7 44 24 0c a5 4e 10 	movl   $0xf0104ea5,0xc(%esp)
f01017d7:	f0 
f01017d8:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f01017df:	f0 
f01017e0:	c7 44 24 04 73 02 00 	movl   $0x273,0x4(%esp)
f01017e7:	00 
f01017e8:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f01017ef:	e8 a0 e8 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f01017f4:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01017fb:	e8 d7 f8 ff ff       	call   f01010d7 <page_alloc>
f0101800:	89 c7                	mov    %eax,%edi
f0101802:	85 c0                	test   %eax,%eax
f0101804:	75 24                	jne    f010182a <mem_init+0x3c2>
f0101806:	c7 44 24 0c bb 4e 10 	movl   $0xf0104ebb,0xc(%esp)
f010180d:	f0 
f010180e:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f0101815:	f0 
f0101816:	c7 44 24 04 74 02 00 	movl   $0x274,0x4(%esp)
f010181d:	00 
f010181e:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f0101825:	e8 6a e8 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f010182a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101831:	e8 a1 f8 ff ff       	call   f01010d7 <page_alloc>
f0101836:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f0101839:	85 c0                	test   %eax,%eax
f010183b:	75 24                	jne    f0101861 <mem_init+0x3f9>
f010183d:	c7 44 24 0c d1 4e 10 	movl   $0xf0104ed1,0xc(%esp)
f0101844:	f0 
f0101845:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f010184c:	f0 
f010184d:	c7 44 24 04 75 02 00 	movl   $0x275,0x4(%esp)
f0101854:	00 
f0101855:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f010185c:	e8 33 e8 ff ff       	call   f0100094 <_panic>
	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101861:	39 fe                	cmp    %edi,%esi
f0101863:	75 24                	jne    f0101889 <mem_init+0x421>
f0101865:	c7 44 24 0c e7 4e 10 	movl   $0xf0104ee7,0xc(%esp)
f010186c:	f0 
f010186d:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f0101874:	f0 
f0101875:	c7 44 24 04 77 02 00 	movl   $0x277,0x4(%esp)
f010187c:	00 
f010187d:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f0101884:	e8 0b e8 ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101889:	3b 7d d4             	cmp    -0x2c(%ebp),%edi
f010188c:	74 05                	je     f0101893 <mem_init+0x42b>
f010188e:	3b 75 d4             	cmp    -0x2c(%ebp),%esi
f0101891:	75 24                	jne    f01018b7 <mem_init+0x44f>
f0101893:	c7 44 24 0c 18 48 10 	movl   $0xf0104818,0xc(%esp)
f010189a:	f0 
f010189b:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f01018a2:	f0 
f01018a3:	c7 44 24 04 78 02 00 	movl   $0x278,0x4(%esp)
f01018aa:	00 
f01018ab:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f01018b2:	e8 dd e7 ff ff       	call   f0100094 <_panic>
	assert(!page_alloc(0));
f01018b7:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01018be:	e8 14 f8 ff ff       	call   f01010d7 <page_alloc>
f01018c3:	85 c0                	test   %eax,%eax
f01018c5:	74 24                	je     f01018eb <mem_init+0x483>
f01018c7:	c7 44 24 0c 50 4f 10 	movl   $0xf0104f50,0xc(%esp)
f01018ce:	f0 
f01018cf:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f01018d6:	f0 
f01018d7:	c7 44 24 04 79 02 00 	movl   $0x279,0x4(%esp)
f01018de:	00 
f01018df:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f01018e6:	e8 a9 e7 ff ff       	call   f0100094 <_panic>
f01018eb:	89 f0                	mov    %esi,%eax
f01018ed:	2b 05 8c 89 11 f0    	sub    0xf011898c,%eax
f01018f3:	c1 f8 03             	sar    $0x3,%eax
f01018f6:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01018f9:	89 c2                	mov    %eax,%edx
f01018fb:	c1 ea 0c             	shr    $0xc,%edx
f01018fe:	3b 15 84 89 11 f0    	cmp    0xf0118984,%edx
f0101904:	72 20                	jb     f0101926 <mem_init+0x4be>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101906:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010190a:	c7 44 24 08 b0 46 10 	movl   $0xf01046b0,0x8(%esp)
f0101911:	f0 
f0101912:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0101919:	00 
f010191a:	c7 04 24 d8 4d 10 f0 	movl   $0xf0104dd8,(%esp)
f0101921:	e8 6e e7 ff ff       	call   f0100094 <_panic>

	// test flags
	memset(page2kva(pp0), 1, PGSIZE);
f0101926:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010192d:	00 
f010192e:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0101935:	00 
	return (void *)(pa + KERNBASE);
f0101936:	2d 00 00 00 10       	sub    $0x10000000,%eax
f010193b:	89 04 24             	mov    %eax,(%esp)
f010193e:	e8 be 22 00 00       	call   f0103c01 <memset>
	page_free(pp0);
f0101943:	89 34 24             	mov    %esi,(%esp)
f0101946:	e8 0d f8 ff ff       	call   f0101158 <page_free>
	assert((pp = page_alloc(ALLOC_ZERO)));
f010194b:	c7 04 24 01 00 00 00 	movl   $0x1,(%esp)
f0101952:	e8 80 f7 ff ff       	call   f01010d7 <page_alloc>
f0101957:	85 c0                	test   %eax,%eax
f0101959:	75 24                	jne    f010197f <mem_init+0x517>
f010195b:	c7 44 24 0c 5f 4f 10 	movl   $0xf0104f5f,0xc(%esp)
f0101962:	f0 
f0101963:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f010196a:	f0 
f010196b:	c7 44 24 04 7e 02 00 	movl   $0x27e,0x4(%esp)
f0101972:	00 
f0101973:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f010197a:	e8 15 e7 ff ff       	call   f0100094 <_panic>
	assert(pp && pp0 == pp);
f010197f:	39 c6                	cmp    %eax,%esi
f0101981:	74 24                	je     f01019a7 <mem_init+0x53f>
f0101983:	c7 44 24 0c 7d 4f 10 	movl   $0xf0104f7d,0xc(%esp)
f010198a:	f0 
f010198b:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f0101992:	f0 
f0101993:	c7 44 24 04 7f 02 00 	movl   $0x27f,0x4(%esp)
f010199a:	00 
f010199b:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f01019a2:	e8 ed e6 ff ff       	call   f0100094 <_panic>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01019a7:	89 f2                	mov    %esi,%edx
f01019a9:	2b 15 8c 89 11 f0    	sub    0xf011898c,%edx
f01019af:	c1 fa 03             	sar    $0x3,%edx
f01019b2:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01019b5:	89 d0                	mov    %edx,%eax
f01019b7:	c1 e8 0c             	shr    $0xc,%eax
f01019ba:	3b 05 84 89 11 f0    	cmp    0xf0118984,%eax
f01019c0:	72 20                	jb     f01019e2 <mem_init+0x57a>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01019c2:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01019c6:	c7 44 24 08 b0 46 10 	movl   $0xf01046b0,0x8(%esp)
f01019cd:	f0 
f01019ce:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f01019d5:	00 
f01019d6:	c7 04 24 d8 4d 10 f0 	movl   $0xf0104dd8,(%esp)
f01019dd:	e8 b2 e6 ff ff       	call   f0100094 <_panic>
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++) 
		assert(c[i] == 0);
f01019e2:	80 ba 00 00 00 f0 00 	cmpb   $0x0,-0x10000000(%edx)
f01019e9:	75 11                	jne    f01019fc <mem_init+0x594>
f01019eb:	8d 82 01 00 00 f0    	lea    -0xfffffff(%edx),%eax
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f01019f1:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++) 
		assert(c[i] == 0);
f01019f7:	80 38 00             	cmpb   $0x0,(%eax)
f01019fa:	74 24                	je     f0101a20 <mem_init+0x5b8>
f01019fc:	c7 44 24 0c 8d 4f 10 	movl   $0xf0104f8d,0xc(%esp)
f0101a03:	f0 
f0101a04:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f0101a0b:	f0 
f0101a0c:	c7 44 24 04 82 02 00 	movl   $0x282,0x4(%esp)
f0101a13:	00 
f0101a14:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f0101a1b:	e8 74 e6 ff ff       	call   f0100094 <_panic>
f0101a20:	83 c0 01             	add    $0x1,%eax
	memset(page2kva(pp0), 1, PGSIZE);
	page_free(pp0);
	assert((pp = page_alloc(ALLOC_ZERO)));
	assert(pp && pp0 == pp);
	c = page2kva(pp);
	for (i = 0; i < PGSIZE; i++) 
f0101a23:	39 d0                	cmp    %edx,%eax
f0101a25:	75 d0                	jne    f01019f7 <mem_init+0x58f>
		assert(c[i] == 0);

	// give free list back
	page_free_list = fl;
f0101a27:	8b 55 d0             	mov    -0x30(%ebp),%edx
f0101a2a:	89 15 60 85 11 f0    	mov    %edx,0xf0118560

	// free the pages we took
	page_free(pp0);
f0101a30:	89 34 24             	mov    %esi,(%esp)
f0101a33:	e8 20 f7 ff ff       	call   f0101158 <page_free>
	page_free(pp1);
f0101a38:	89 3c 24             	mov    %edi,(%esp)
f0101a3b:	e8 18 f7 ff ff       	call   f0101158 <page_free>
	page_free(pp2);
f0101a40:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101a43:	89 04 24             	mov    %eax,(%esp)
f0101a46:	e8 0d f7 ff ff       	call   f0101158 <page_free>

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101a4b:	a1 60 85 11 f0       	mov    0xf0118560,%eax
f0101a50:	85 c0                	test   %eax,%eax
f0101a52:	74 09                	je     f0101a5d <mem_init+0x5f5>
		--nfree;
f0101a54:	83 eb 01             	sub    $0x1,%ebx
	page_free(pp0);
	page_free(pp1);
	page_free(pp2);

	// number of free pages should be the same
	for (pp = page_free_list; pp; pp = pp->pp_link)
f0101a57:	8b 00                	mov    (%eax),%eax
f0101a59:	85 c0                	test   %eax,%eax
f0101a5b:	75 f7                	jne    f0101a54 <mem_init+0x5ec>
		--nfree;
	assert(nfree == 0);
f0101a5d:	85 db                	test   %ebx,%ebx
f0101a5f:	74 24                	je     f0101a85 <mem_init+0x61d>
f0101a61:	c7 44 24 0c 97 4f 10 	movl   $0xf0104f97,0xc(%esp)
f0101a68:	f0 
f0101a69:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f0101a70:	f0 
f0101a71:	c7 44 24 04 8f 02 00 	movl   $0x28f,0x4(%esp)
f0101a78:	00 
f0101a79:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f0101a80:	e8 0f e6 ff ff       	call   f0100094 <_panic>

	cprintf("check_page_alloc() succeeded!\n");
f0101a85:	c7 04 24 38 48 10 f0 	movl   $0xf0104838,(%esp)
f0101a8c:	e8 b9 15 00 00       	call   f010304a <cprintf>
	int i;
	extern pde_t entry_pgdir[];

	// should be able to allocate three pages
	pp0 = pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0101a91:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101a98:	e8 3a f6 ff ff       	call   f01010d7 <page_alloc>
f0101a9d:	89 c6                	mov    %eax,%esi
f0101a9f:	85 c0                	test   %eax,%eax
f0101aa1:	75 24                	jne    f0101ac7 <mem_init+0x65f>
f0101aa3:	c7 44 24 0c a5 4e 10 	movl   $0xf0104ea5,0xc(%esp)
f0101aaa:	f0 
f0101aab:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f0101ab2:	f0 
f0101ab3:	c7 44 24 04 eb 02 00 	movl   $0x2eb,0x4(%esp)
f0101aba:	00 
f0101abb:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f0101ac2:	e8 cd e5 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f0101ac7:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101ace:	e8 04 f6 ff ff       	call   f01010d7 <page_alloc>
f0101ad3:	89 c7                	mov    %eax,%edi
f0101ad5:	85 c0                	test   %eax,%eax
f0101ad7:	75 24                	jne    f0101afd <mem_init+0x695>
f0101ad9:	c7 44 24 0c bb 4e 10 	movl   $0xf0104ebb,0xc(%esp)
f0101ae0:	f0 
f0101ae1:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f0101ae8:	f0 
f0101ae9:	c7 44 24 04 ec 02 00 	movl   $0x2ec,0x4(%esp)
f0101af0:	00 
f0101af1:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f0101af8:	e8 97 e5 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0101afd:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101b04:	e8 ce f5 ff ff       	call   f01010d7 <page_alloc>
f0101b09:	89 c3                	mov    %eax,%ebx
f0101b0b:	85 c0                	test   %eax,%eax
f0101b0d:	75 24                	jne    f0101b33 <mem_init+0x6cb>
f0101b0f:	c7 44 24 0c d1 4e 10 	movl   $0xf0104ed1,0xc(%esp)
f0101b16:	f0 
f0101b17:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f0101b1e:	f0 
f0101b1f:	c7 44 24 04 ed 02 00 	movl   $0x2ed,0x4(%esp)
f0101b26:	00 
f0101b27:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f0101b2e:	e8 61 e5 ff ff       	call   f0100094 <_panic>

	assert(pp0);
	assert(pp1 && pp1 != pp0);
f0101b33:	39 fe                	cmp    %edi,%esi
f0101b35:	75 24                	jne    f0101b5b <mem_init+0x6f3>
f0101b37:	c7 44 24 0c e7 4e 10 	movl   $0xf0104ee7,0xc(%esp)
f0101b3e:	f0 
f0101b3f:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f0101b46:	f0 
f0101b47:	c7 44 24 04 f0 02 00 	movl   $0x2f0,0x4(%esp)
f0101b4e:	00 
f0101b4f:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f0101b56:	e8 39 e5 ff ff       	call   f0100094 <_panic>
	assert(pp2 && pp2 != pp1 && pp2 != pp0);
f0101b5b:	39 c7                	cmp    %eax,%edi
f0101b5d:	74 04                	je     f0101b63 <mem_init+0x6fb>
f0101b5f:	39 c6                	cmp    %eax,%esi
f0101b61:	75 24                	jne    f0101b87 <mem_init+0x71f>
f0101b63:	c7 44 24 0c 18 48 10 	movl   $0xf0104818,0xc(%esp)
f0101b6a:	f0 
f0101b6b:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f0101b72:	f0 
f0101b73:	c7 44 24 04 f1 02 00 	movl   $0x2f1,0x4(%esp)
f0101b7a:	00 
f0101b7b:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f0101b82:	e8 0d e5 ff ff       	call   f0100094 <_panic>

	// temporarily steal the rest of the free pages
	fl = page_free_list;
f0101b87:	8b 15 60 85 11 f0    	mov    0xf0118560,%edx
f0101b8d:	89 55 cc             	mov    %edx,-0x34(%ebp)
	page_free_list = 0;
f0101b90:	c7 05 60 85 11 f0 00 	movl   $0x0,0xf0118560
f0101b97:	00 00 00 

	// should be no free memory
	assert(!page_alloc(0));
f0101b9a:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101ba1:	e8 31 f5 ff ff       	call   f01010d7 <page_alloc>
f0101ba6:	85 c0                	test   %eax,%eax
f0101ba8:	74 24                	je     f0101bce <mem_init+0x766>
f0101baa:	c7 44 24 0c 50 4f 10 	movl   $0xf0104f50,0xc(%esp)
f0101bb1:	f0 
f0101bb2:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f0101bb9:	f0 
f0101bba:	c7 44 24 04 f8 02 00 	movl   $0x2f8,0x4(%esp)
f0101bc1:	00 
f0101bc2:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f0101bc9:	e8 c6 e4 ff ff       	call   f0100094 <_panic>

	// there is no page allocated at address 0
	assert(page_lookup(kern_pgdir, (void *) 0x0, &ptep) == NULL);
f0101bce:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0101bd1:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101bd5:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f0101bdc:	00 
f0101bdd:	a1 88 89 11 f0       	mov    0xf0118988,%eax
f0101be2:	89 04 24             	mov    %eax,(%esp)
f0101be5:	e8 11 f7 ff ff       	call   f01012fb <page_lookup>
f0101bea:	85 c0                	test   %eax,%eax
f0101bec:	74 24                	je     f0101c12 <mem_init+0x7aa>
f0101bee:	c7 44 24 0c 58 48 10 	movl   $0xf0104858,0xc(%esp)
f0101bf5:	f0 
f0101bf6:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f0101bfd:	f0 
f0101bfe:	c7 44 24 04 fb 02 00 	movl   $0x2fb,0x4(%esp)
f0101c05:	00 
f0101c06:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f0101c0d:	e8 82 e4 ff ff       	call   f0100094 <_panic>

	// there is no free memory, so we can't allocate a page table
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) < 0);
f0101c12:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101c19:	00 
f0101c1a:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101c21:	00 
f0101c22:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101c26:	a1 88 89 11 f0       	mov    0xf0118988,%eax
f0101c2b:	89 04 24             	mov    %eax,(%esp)
f0101c2e:	e8 73 f7 ff ff       	call   f01013a6 <page_insert>
f0101c33:	85 c0                	test   %eax,%eax
f0101c35:	78 24                	js     f0101c5b <mem_init+0x7f3>
f0101c37:	c7 44 24 0c 90 48 10 	movl   $0xf0104890,0xc(%esp)
f0101c3e:	f0 
f0101c3f:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f0101c46:	f0 
f0101c47:	c7 44 24 04 fe 02 00 	movl   $0x2fe,0x4(%esp)
f0101c4e:	00 
f0101c4f:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f0101c56:	e8 39 e4 ff ff       	call   f0100094 <_panic>

	// free pp0 and try again: pp0 should be used for page table
	page_free(pp0);
f0101c5b:	89 34 24             	mov    %esi,(%esp)
f0101c5e:	e8 f5 f4 ff ff       	call   f0101158 <page_free>
	assert(page_insert(kern_pgdir, pp1, 0x0, PTE_W) == 0);
f0101c63:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101c6a:	00 
f0101c6b:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101c72:	00 
f0101c73:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101c77:	a1 88 89 11 f0       	mov    0xf0118988,%eax
f0101c7c:	89 04 24             	mov    %eax,(%esp)
f0101c7f:	e8 22 f7 ff ff       	call   f01013a6 <page_insert>
f0101c84:	85 c0                	test   %eax,%eax
f0101c86:	74 24                	je     f0101cac <mem_init+0x844>
f0101c88:	c7 44 24 0c c0 48 10 	movl   $0xf01048c0,0xc(%esp)
f0101c8f:	f0 
f0101c90:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f0101c97:	f0 
f0101c98:	c7 44 24 04 02 03 00 	movl   $0x302,0x4(%esp)
f0101c9f:	00 
f0101ca0:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f0101ca7:	e8 e8 e3 ff ff       	call   f0100094 <_panic>
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0101cac:	8b 0d 88 89 11 f0    	mov    0xf0118988,%ecx
f0101cb2:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0101cb5:	a1 8c 89 11 f0       	mov    0xf011898c,%eax
f0101cba:	89 45 d0             	mov    %eax,-0x30(%ebp)
f0101cbd:	8b 11                	mov    (%ecx),%edx
f0101cbf:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f0101cc5:	89 f0                	mov    %esi,%eax
f0101cc7:	2b 45 d0             	sub    -0x30(%ebp),%eax
f0101cca:	c1 f8 03             	sar    $0x3,%eax
f0101ccd:	c1 e0 0c             	shl    $0xc,%eax
f0101cd0:	39 c2                	cmp    %eax,%edx
f0101cd2:	74 24                	je     f0101cf8 <mem_init+0x890>
f0101cd4:	c7 44 24 0c f0 48 10 	movl   $0xf01048f0,0xc(%esp)
f0101cdb:	f0 
f0101cdc:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f0101ce3:	f0 
f0101ce4:	c7 44 24 04 03 03 00 	movl   $0x303,0x4(%esp)
f0101ceb:	00 
f0101cec:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f0101cf3:	e8 9c e3 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, 0x0) == page2pa(pp1));
f0101cf8:	ba 00 00 00 00       	mov    $0x0,%edx
f0101cfd:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101d00:	e8 13 ef ff ff       	call   f0100c18 <check_va2pa>
f0101d05:	89 fa                	mov    %edi,%edx
f0101d07:	2b 55 d0             	sub    -0x30(%ebp),%edx
f0101d0a:	c1 fa 03             	sar    $0x3,%edx
f0101d0d:	c1 e2 0c             	shl    $0xc,%edx
f0101d10:	39 d0                	cmp    %edx,%eax
f0101d12:	74 24                	je     f0101d38 <mem_init+0x8d0>
f0101d14:	c7 44 24 0c 18 49 10 	movl   $0xf0104918,0xc(%esp)
f0101d1b:	f0 
f0101d1c:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f0101d23:	f0 
f0101d24:	c7 44 24 04 04 03 00 	movl   $0x304,0x4(%esp)
f0101d2b:	00 
f0101d2c:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f0101d33:	e8 5c e3 ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 1);
f0101d38:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0101d3d:	74 24                	je     f0101d63 <mem_init+0x8fb>
f0101d3f:	c7 44 24 0c a2 4f 10 	movl   $0xf0104fa2,0xc(%esp)
f0101d46:	f0 
f0101d47:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f0101d4e:	f0 
f0101d4f:	c7 44 24 04 05 03 00 	movl   $0x305,0x4(%esp)
f0101d56:	00 
f0101d57:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f0101d5e:	e8 31 e3 ff ff       	call   f0100094 <_panic>
	assert(pp0->pp_ref == 1);
f0101d63:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0101d68:	74 24                	je     f0101d8e <mem_init+0x926>
f0101d6a:	c7 44 24 0c b3 4f 10 	movl   $0xf0104fb3,0xc(%esp)
f0101d71:	f0 
f0101d72:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f0101d79:	f0 
f0101d7a:	c7 44 24 04 06 03 00 	movl   $0x306,0x4(%esp)
f0101d81:	00 
f0101d82:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f0101d89:	e8 06 e3 ff ff       	call   f0100094 <_panic>

	// should be able to map pp2 at PGSIZE because pp0 is already allocated for page table
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101d8e:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101d95:	00 
f0101d96:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101d9d:	00 
f0101d9e:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101da2:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f0101da5:	89 14 24             	mov    %edx,(%esp)
f0101da8:	e8 f9 f5 ff ff       	call   f01013a6 <page_insert>
f0101dad:	85 c0                	test   %eax,%eax
f0101daf:	74 24                	je     f0101dd5 <mem_init+0x96d>
f0101db1:	c7 44 24 0c 48 49 10 	movl   $0xf0104948,0xc(%esp)
f0101db8:	f0 
f0101db9:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f0101dc0:	f0 
f0101dc1:	c7 44 24 04 09 03 00 	movl   $0x309,0x4(%esp)
f0101dc8:	00 
f0101dc9:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f0101dd0:	e8 bf e2 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101dd5:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101dda:	a1 88 89 11 f0       	mov    0xf0118988,%eax
f0101ddf:	e8 34 ee ff ff       	call   f0100c18 <check_va2pa>
f0101de4:	89 da                	mov    %ebx,%edx
f0101de6:	2b 15 8c 89 11 f0    	sub    0xf011898c,%edx
f0101dec:	c1 fa 03             	sar    $0x3,%edx
f0101def:	c1 e2 0c             	shl    $0xc,%edx
f0101df2:	39 d0                	cmp    %edx,%eax
f0101df4:	74 24                	je     f0101e1a <mem_init+0x9b2>
f0101df6:	c7 44 24 0c 84 49 10 	movl   $0xf0104984,0xc(%esp)
f0101dfd:	f0 
f0101dfe:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f0101e05:	f0 
f0101e06:	c7 44 24 04 0a 03 00 	movl   $0x30a,0x4(%esp)
f0101e0d:	00 
f0101e0e:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f0101e15:	e8 7a e2 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101e1a:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101e1f:	74 24                	je     f0101e45 <mem_init+0x9dd>
f0101e21:	c7 44 24 0c c4 4f 10 	movl   $0xf0104fc4,0xc(%esp)
f0101e28:	f0 
f0101e29:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f0101e30:	f0 
f0101e31:	c7 44 24 04 0b 03 00 	movl   $0x30b,0x4(%esp)
f0101e38:	00 
f0101e39:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f0101e40:	e8 4f e2 ff ff       	call   f0100094 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f0101e45:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101e4c:	e8 86 f2 ff ff       	call   f01010d7 <page_alloc>
f0101e51:	85 c0                	test   %eax,%eax
f0101e53:	74 24                	je     f0101e79 <mem_init+0xa11>
f0101e55:	c7 44 24 0c 50 4f 10 	movl   $0xf0104f50,0xc(%esp)
f0101e5c:	f0 
f0101e5d:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f0101e64:	f0 
f0101e65:	c7 44 24 04 0e 03 00 	movl   $0x30e,0x4(%esp)
f0101e6c:	00 
f0101e6d:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f0101e74:	e8 1b e2 ff ff       	call   f0100094 <_panic>

	// should be able to map pp2 at PGSIZE because it's already there
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f0101e79:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0101e80:	00 
f0101e81:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101e88:	00 
f0101e89:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101e8d:	a1 88 89 11 f0       	mov    0xf0118988,%eax
f0101e92:	89 04 24             	mov    %eax,(%esp)
f0101e95:	e8 0c f5 ff ff       	call   f01013a6 <page_insert>
f0101e9a:	85 c0                	test   %eax,%eax
f0101e9c:	74 24                	je     f0101ec2 <mem_init+0xa5a>
f0101e9e:	c7 44 24 0c 48 49 10 	movl   $0xf0104948,0xc(%esp)
f0101ea5:	f0 
f0101ea6:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f0101ead:	f0 
f0101eae:	c7 44 24 04 11 03 00 	movl   $0x311,0x4(%esp)
f0101eb5:	00 
f0101eb6:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f0101ebd:	e8 d2 e1 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0101ec2:	ba 00 10 00 00       	mov    $0x1000,%edx
f0101ec7:	a1 88 89 11 f0       	mov    0xf0118988,%eax
f0101ecc:	e8 47 ed ff ff       	call   f0100c18 <check_va2pa>
f0101ed1:	89 da                	mov    %ebx,%edx
f0101ed3:	2b 15 8c 89 11 f0    	sub    0xf011898c,%edx
f0101ed9:	c1 fa 03             	sar    $0x3,%edx
f0101edc:	c1 e2 0c             	shl    $0xc,%edx
f0101edf:	39 d0                	cmp    %edx,%eax
f0101ee1:	74 24                	je     f0101f07 <mem_init+0xa9f>
f0101ee3:	c7 44 24 0c 84 49 10 	movl   $0xf0104984,0xc(%esp)
f0101eea:	f0 
f0101eeb:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f0101ef2:	f0 
f0101ef3:	c7 44 24 04 12 03 00 	movl   $0x312,0x4(%esp)
f0101efa:	00 
f0101efb:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f0101f02:	e8 8d e1 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0101f07:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0101f0c:	74 24                	je     f0101f32 <mem_init+0xaca>
f0101f0e:	c7 44 24 0c c4 4f 10 	movl   $0xf0104fc4,0xc(%esp)
f0101f15:	f0 
f0101f16:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f0101f1d:	f0 
f0101f1e:	c7 44 24 04 13 03 00 	movl   $0x313,0x4(%esp)
f0101f25:	00 
f0101f26:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f0101f2d:	e8 62 e1 ff ff       	call   f0100094 <_panic>

	// pp2 should NOT be on the free list
	// could happen in ref counts are handled sloppily in page_insert
	assert(!page_alloc(0));
f0101f32:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0101f39:	e8 99 f1 ff ff       	call   f01010d7 <page_alloc>
f0101f3e:	85 c0                	test   %eax,%eax
f0101f40:	74 24                	je     f0101f66 <mem_init+0xafe>
f0101f42:	c7 44 24 0c 50 4f 10 	movl   $0xf0104f50,0xc(%esp)
f0101f49:	f0 
f0101f4a:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f0101f51:	f0 
f0101f52:	c7 44 24 04 17 03 00 	movl   $0x317,0x4(%esp)
f0101f59:	00 
f0101f5a:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f0101f61:	e8 2e e1 ff ff       	call   f0100094 <_panic>

	// check that pgdir_walk returns a pointer to the pte
	ptep = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(PGSIZE)]));
f0101f66:	8b 15 88 89 11 f0    	mov    0xf0118988,%edx
f0101f6c:	8b 02                	mov    (%edx),%eax
f0101f6e:	25 00 f0 ff ff       	and    $0xfffff000,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0101f73:	89 c1                	mov    %eax,%ecx
f0101f75:	c1 e9 0c             	shr    $0xc,%ecx
f0101f78:	3b 0d 84 89 11 f0    	cmp    0xf0118984,%ecx
f0101f7e:	72 20                	jb     f0101fa0 <mem_init+0xb38>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0101f80:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101f84:	c7 44 24 08 b0 46 10 	movl   $0xf01046b0,0x8(%esp)
f0101f8b:	f0 
f0101f8c:	c7 44 24 04 1a 03 00 	movl   $0x31a,0x4(%esp)
f0101f93:	00 
f0101f94:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f0101f9b:	e8 f4 e0 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f0101fa0:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0101fa5:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	assert(pgdir_walk(kern_pgdir, (void*)PGSIZE, 0) == ptep+PTX(PGSIZE));
f0101fa8:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0101faf:	00 
f0101fb0:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0101fb7:	00 
f0101fb8:	89 14 24             	mov    %edx,(%esp)
f0101fbb:	e8 d0 f1 ff ff       	call   f0101190 <pgdir_walk>
f0101fc0:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0101fc3:	83 c2 04             	add    $0x4,%edx
f0101fc6:	39 d0                	cmp    %edx,%eax
f0101fc8:	74 24                	je     f0101fee <mem_init+0xb86>
f0101fca:	c7 44 24 0c b4 49 10 	movl   $0xf01049b4,0xc(%esp)
f0101fd1:	f0 
f0101fd2:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f0101fd9:	f0 
f0101fda:	c7 44 24 04 1b 03 00 	movl   $0x31b,0x4(%esp)
f0101fe1:	00 
f0101fe2:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f0101fe9:	e8 a6 e0 ff ff       	call   f0100094 <_panic>

	// should be able to change permissions too.
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W|PTE_U) == 0);
f0101fee:	c7 44 24 0c 06 00 00 	movl   $0x6,0xc(%esp)
f0101ff5:	00 
f0101ff6:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0101ffd:	00 
f0101ffe:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102002:	a1 88 89 11 f0       	mov    0xf0118988,%eax
f0102007:	89 04 24             	mov    %eax,(%esp)
f010200a:	e8 97 f3 ff ff       	call   f01013a6 <page_insert>
f010200f:	85 c0                	test   %eax,%eax
f0102011:	74 24                	je     f0102037 <mem_init+0xbcf>
f0102013:	c7 44 24 0c f4 49 10 	movl   $0xf01049f4,0xc(%esp)
f010201a:	f0 
f010201b:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f0102022:	f0 
f0102023:	c7 44 24 04 1e 03 00 	movl   $0x31e,0x4(%esp)
f010202a:	00 
f010202b:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f0102032:	e8 5d e0 ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp2));
f0102037:	8b 0d 88 89 11 f0    	mov    0xf0118988,%ecx
f010203d:	89 4d d4             	mov    %ecx,-0x2c(%ebp)
f0102040:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102045:	89 c8                	mov    %ecx,%eax
f0102047:	e8 cc eb ff ff       	call   f0100c18 <check_va2pa>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f010204c:	89 da                	mov    %ebx,%edx
f010204e:	2b 15 8c 89 11 f0    	sub    0xf011898c,%edx
f0102054:	c1 fa 03             	sar    $0x3,%edx
f0102057:	c1 e2 0c             	shl    $0xc,%edx
f010205a:	39 d0                	cmp    %edx,%eax
f010205c:	74 24                	je     f0102082 <mem_init+0xc1a>
f010205e:	c7 44 24 0c 84 49 10 	movl   $0xf0104984,0xc(%esp)
f0102065:	f0 
f0102066:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f010206d:	f0 
f010206e:	c7 44 24 04 1f 03 00 	movl   $0x31f,0x4(%esp)
f0102075:	00 
f0102076:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f010207d:	e8 12 e0 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0102082:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102087:	74 24                	je     f01020ad <mem_init+0xc45>
f0102089:	c7 44 24 0c c4 4f 10 	movl   $0xf0104fc4,0xc(%esp)
f0102090:	f0 
f0102091:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f0102098:	f0 
f0102099:	c7 44 24 04 20 03 00 	movl   $0x320,0x4(%esp)
f01020a0:	00 
f01020a1:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f01020a8:	e8 e7 df ff ff       	call   f0100094 <_panic>

	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U);
f01020ad:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01020b4:	00 
f01020b5:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01020bc:	00 
f01020bd:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01020c0:	89 04 24             	mov    %eax,(%esp)
f01020c3:	e8 c8 f0 ff ff       	call   f0101190 <pgdir_walk>
f01020c8:	f6 00 04             	testb  $0x4,(%eax)
f01020cb:	75 24                	jne    f01020f1 <mem_init+0xc89>
f01020cd:	c7 44 24 0c 34 4a 10 	movl   $0xf0104a34,0xc(%esp)
f01020d4:	f0 
f01020d5:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f01020dc:	f0 
f01020dd:	c7 44 24 04 22 03 00 	movl   $0x322,0x4(%esp)
f01020e4:	00 
f01020e5:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f01020ec:	e8 a3 df ff ff       	call   f0100094 <_panic>
	assert(kern_pgdir[0] & PTE_U);
f01020f1:	a1 88 89 11 f0       	mov    0xf0118988,%eax
f01020f6:	f6 00 04             	testb  $0x4,(%eax)
f01020f9:	75 24                	jne    f010211f <mem_init+0xcb7>
f01020fb:	c7 44 24 0c d5 4f 10 	movl   $0xf0104fd5,0xc(%esp)
f0102102:	f0 
f0102103:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f010210a:	f0 
f010210b:	c7 44 24 04 23 03 00 	movl   $0x323,0x4(%esp)
f0102112:	00 
f0102113:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f010211a:	e8 75 df ff ff       	call   f0100094 <_panic>

	// should be able to remap with fewer permissions
	assert(page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W) == 0);
f010211f:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102126:	00 
f0102127:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f010212e:	00 
f010212f:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102133:	89 04 24             	mov    %eax,(%esp)
f0102136:	e8 6b f2 ff ff       	call   f01013a6 <page_insert>
f010213b:	85 c0                	test   %eax,%eax
f010213d:	74 24                	je     f0102163 <mem_init+0xcfb>
f010213f:	c7 44 24 0c 48 49 10 	movl   $0xf0104948,0xc(%esp)
f0102146:	f0 
f0102147:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f010214e:	f0 
f010214f:	c7 44 24 04 26 03 00 	movl   $0x326,0x4(%esp)
f0102156:	00 
f0102157:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f010215e:	e8 31 df ff ff       	call   f0100094 <_panic>
	assert(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_W);
f0102163:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f010216a:	00 
f010216b:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102172:	00 
f0102173:	a1 88 89 11 f0       	mov    0xf0118988,%eax
f0102178:	89 04 24             	mov    %eax,(%esp)
f010217b:	e8 10 f0 ff ff       	call   f0101190 <pgdir_walk>
f0102180:	f6 00 02             	testb  $0x2,(%eax)
f0102183:	75 24                	jne    f01021a9 <mem_init+0xd41>
f0102185:	c7 44 24 0c 68 4a 10 	movl   $0xf0104a68,0xc(%esp)
f010218c:	f0 
f010218d:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f0102194:	f0 
f0102195:	c7 44 24 04 27 03 00 	movl   $0x327,0x4(%esp)
f010219c:	00 
f010219d:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f01021a4:	e8 eb de ff ff       	call   f0100094 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f01021a9:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f01021b0:	00 
f01021b1:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01021b8:	00 
f01021b9:	a1 88 89 11 f0       	mov    0xf0118988,%eax
f01021be:	89 04 24             	mov    %eax,(%esp)
f01021c1:	e8 ca ef ff ff       	call   f0101190 <pgdir_walk>
f01021c6:	f6 00 04             	testb  $0x4,(%eax)
f01021c9:	74 24                	je     f01021ef <mem_init+0xd87>
f01021cb:	c7 44 24 0c 9c 4a 10 	movl   $0xf0104a9c,0xc(%esp)
f01021d2:	f0 
f01021d3:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f01021da:	f0 
f01021db:	c7 44 24 04 28 03 00 	movl   $0x328,0x4(%esp)
f01021e2:	00 
f01021e3:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f01021ea:	e8 a5 de ff ff       	call   f0100094 <_panic>

	// should not be able to map at PTSIZE because need free page for page table
	assert(page_insert(kern_pgdir, pp0, (void*) PTSIZE, PTE_W) < 0);
f01021ef:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f01021f6:	00 
f01021f7:	c7 44 24 08 00 00 40 	movl   $0x400000,0x8(%esp)
f01021fe:	00 
f01021ff:	89 74 24 04          	mov    %esi,0x4(%esp)
f0102203:	a1 88 89 11 f0       	mov    0xf0118988,%eax
f0102208:	89 04 24             	mov    %eax,(%esp)
f010220b:	e8 96 f1 ff ff       	call   f01013a6 <page_insert>
f0102210:	85 c0                	test   %eax,%eax
f0102212:	78 24                	js     f0102238 <mem_init+0xdd0>
f0102214:	c7 44 24 0c d4 4a 10 	movl   $0xf0104ad4,0xc(%esp)
f010221b:	f0 
f010221c:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f0102223:	f0 
f0102224:	c7 44 24 04 2b 03 00 	movl   $0x32b,0x4(%esp)
f010222b:	00 
f010222c:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f0102233:	e8 5c de ff ff       	call   f0100094 <_panic>

	// insert pp1 at PGSIZE (replacing pp2)
//	cprintf("~~w");
	assert(page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W) == 0);
f0102238:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f010223f:	00 
f0102240:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102247:	00 
f0102248:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010224c:	a1 88 89 11 f0       	mov    0xf0118988,%eax
f0102251:	89 04 24             	mov    %eax,(%esp)
f0102254:	e8 4d f1 ff ff       	call   f01013a6 <page_insert>
f0102259:	85 c0                	test   %eax,%eax
f010225b:	74 24                	je     f0102281 <mem_init+0xe19>
f010225d:	c7 44 24 0c 0c 4b 10 	movl   $0xf0104b0c,0xc(%esp)
f0102264:	f0 
f0102265:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f010226c:	f0 
f010226d:	c7 44 24 04 2f 03 00 	movl   $0x32f,0x4(%esp)
f0102274:	00 
f0102275:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f010227c:	e8 13 de ff ff       	call   f0100094 <_panic>
	assert(!(*pgdir_walk(kern_pgdir, (void*) PGSIZE, 0) & PTE_U));
f0102281:	c7 44 24 08 00 00 00 	movl   $0x0,0x8(%esp)
f0102288:	00 
f0102289:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102290:	00 
f0102291:	a1 88 89 11 f0       	mov    0xf0118988,%eax
f0102296:	89 04 24             	mov    %eax,(%esp)
f0102299:	e8 f2 ee ff ff       	call   f0101190 <pgdir_walk>
f010229e:	f6 00 04             	testb  $0x4,(%eax)
f01022a1:	74 24                	je     f01022c7 <mem_init+0xe5f>
f01022a3:	c7 44 24 0c 9c 4a 10 	movl   $0xf0104a9c,0xc(%esp)
f01022aa:	f0 
f01022ab:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f01022b2:	f0 
f01022b3:	c7 44 24 04 30 03 00 	movl   $0x330,0x4(%esp)
f01022ba:	00 
f01022bb:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f01022c2:	e8 cd dd ff ff       	call   f0100094 <_panic>

	// should have pp1 at both 0 and PGSIZE, pp2 nowhere, ...
	assert(check_va2pa(kern_pgdir, 0) == page2pa(pp1));
f01022c7:	a1 88 89 11 f0       	mov    0xf0118988,%eax
f01022cc:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01022cf:	ba 00 00 00 00       	mov    $0x0,%edx
f01022d4:	e8 3f e9 ff ff       	call   f0100c18 <check_va2pa>
f01022d9:	89 45 d0             	mov    %eax,-0x30(%ebp)
f01022dc:	89 f8                	mov    %edi,%eax
f01022de:	2b 05 8c 89 11 f0    	sub    0xf011898c,%eax
f01022e4:	c1 f8 03             	sar    $0x3,%eax
f01022e7:	c1 e0 0c             	shl    $0xc,%eax
f01022ea:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f01022ed:	74 24                	je     f0102313 <mem_init+0xeab>
f01022ef:	c7 44 24 0c 48 4b 10 	movl   $0xf0104b48,0xc(%esp)
f01022f6:	f0 
f01022f7:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f01022fe:	f0 
f01022ff:	c7 44 24 04 33 03 00 	movl   $0x333,0x4(%esp)
f0102306:	00 
f0102307:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f010230e:	e8 81 dd ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f0102313:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102318:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010231b:	e8 f8 e8 ff ff       	call   f0100c18 <check_va2pa>
f0102320:	39 45 d0             	cmp    %eax,-0x30(%ebp)
f0102323:	74 24                	je     f0102349 <mem_init+0xee1>
f0102325:	c7 44 24 0c 74 4b 10 	movl   $0xf0104b74,0xc(%esp)
f010232c:	f0 
f010232d:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f0102334:	f0 
f0102335:	c7 44 24 04 34 03 00 	movl   $0x334,0x4(%esp)
f010233c:	00 
f010233d:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f0102344:	e8 4b dd ff ff       	call   f0100094 <_panic>
	// ... and ref counts should reflect this
//	cprintf("%d %d", pp1->pp_ref, pp2->pp_ref);
	assert(pp1->pp_ref == 2);
f0102349:	66 83 7f 04 02       	cmpw   $0x2,0x4(%edi)
f010234e:	74 24                	je     f0102374 <mem_init+0xf0c>
f0102350:	c7 44 24 0c eb 4f 10 	movl   $0xf0104feb,0xc(%esp)
f0102357:	f0 
f0102358:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f010235f:	f0 
f0102360:	c7 44 24 04 37 03 00 	movl   $0x337,0x4(%esp)
f0102367:	00 
f0102368:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f010236f:	e8 20 dd ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f0102374:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102379:	74 24                	je     f010239f <mem_init+0xf37>
f010237b:	c7 44 24 0c fc 4f 10 	movl   $0xf0104ffc,0xc(%esp)
f0102382:	f0 
f0102383:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f010238a:	f0 
f010238b:	c7 44 24 04 38 03 00 	movl   $0x338,0x4(%esp)
f0102392:	00 
f0102393:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f010239a:	e8 f5 dc ff ff       	call   f0100094 <_panic>

	// pp2 should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp2);
f010239f:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01023a6:	e8 2c ed ff ff       	call   f01010d7 <page_alloc>
f01023ab:	85 c0                	test   %eax,%eax
f01023ad:	74 04                	je     f01023b3 <mem_init+0xf4b>
f01023af:	39 c3                	cmp    %eax,%ebx
f01023b1:	74 24                	je     f01023d7 <mem_init+0xf6f>
f01023b3:	c7 44 24 0c a4 4b 10 	movl   $0xf0104ba4,0xc(%esp)
f01023ba:	f0 
f01023bb:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f01023c2:	f0 
f01023c3:	c7 44 24 04 3b 03 00 	movl   $0x33b,0x4(%esp)
f01023ca:	00 
f01023cb:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f01023d2:	e8 bd dc ff ff       	call   f0100094 <_panic>

	// unmapping pp1 at 0 should keep pp1 at PGSIZE
	page_remove(kern_pgdir, 0x0);
f01023d7:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01023de:	00 
f01023df:	a1 88 89 11 f0       	mov    0xf0118988,%eax
f01023e4:	89 04 24             	mov    %eax,(%esp)
f01023e7:	e8 7c ef ff ff       	call   f0101368 <page_remove>
//	cprintf("~~~");
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f01023ec:	8b 15 88 89 11 f0    	mov    0xf0118988,%edx
f01023f2:	89 55 d4             	mov    %edx,-0x2c(%ebp)
f01023f5:	ba 00 00 00 00       	mov    $0x0,%edx
f01023fa:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01023fd:	e8 16 e8 ff ff       	call   f0100c18 <check_va2pa>
f0102402:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102405:	74 24                	je     f010242b <mem_init+0xfc3>
f0102407:	c7 44 24 0c c8 4b 10 	movl   $0xf0104bc8,0xc(%esp)
f010240e:	f0 
f010240f:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f0102416:	f0 
f0102417:	c7 44 24 04 40 03 00 	movl   $0x340,0x4(%esp)
f010241e:	00 
f010241f:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f0102426:	e8 69 dc ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == page2pa(pp1));
f010242b:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102430:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0102433:	e8 e0 e7 ff ff       	call   f0100c18 <check_va2pa>
f0102438:	89 fa                	mov    %edi,%edx
f010243a:	2b 15 8c 89 11 f0    	sub    0xf011898c,%edx
f0102440:	c1 fa 03             	sar    $0x3,%edx
f0102443:	c1 e2 0c             	shl    $0xc,%edx
f0102446:	39 d0                	cmp    %edx,%eax
f0102448:	74 24                	je     f010246e <mem_init+0x1006>
f010244a:	c7 44 24 0c 74 4b 10 	movl   $0xf0104b74,0xc(%esp)
f0102451:	f0 
f0102452:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f0102459:	f0 
f010245a:	c7 44 24 04 41 03 00 	movl   $0x341,0x4(%esp)
f0102461:	00 
f0102462:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f0102469:	e8 26 dc ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 1);
f010246e:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102473:	74 24                	je     f0102499 <mem_init+0x1031>
f0102475:	c7 44 24 0c a2 4f 10 	movl   $0xf0104fa2,0xc(%esp)
f010247c:	f0 
f010247d:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f0102484:	f0 
f0102485:	c7 44 24 04 42 03 00 	movl   $0x342,0x4(%esp)
f010248c:	00 
f010248d:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f0102494:	e8 fb db ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f0102499:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f010249e:	74 24                	je     f01024c4 <mem_init+0x105c>
f01024a0:	c7 44 24 0c fc 4f 10 	movl   $0xf0104ffc,0xc(%esp)
f01024a7:	f0 
f01024a8:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f01024af:	f0 
f01024b0:	c7 44 24 04 43 03 00 	movl   $0x343,0x4(%esp)
f01024b7:	00 
f01024b8:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f01024bf:	e8 d0 db ff ff       	call   f0100094 <_panic>

	// unmapping pp1 at PGSIZE should free it
	page_remove(kern_pgdir, (void*) PGSIZE);
f01024c4:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f01024cb:	00 
f01024cc:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01024cf:	89 0c 24             	mov    %ecx,(%esp)
f01024d2:	e8 91 ee ff ff       	call   f0101368 <page_remove>
	assert(check_va2pa(kern_pgdir, 0x0) == ~0);
f01024d7:	a1 88 89 11 f0       	mov    0xf0118988,%eax
f01024dc:	89 45 d4             	mov    %eax,-0x2c(%ebp)
f01024df:	ba 00 00 00 00       	mov    $0x0,%edx
f01024e4:	e8 2f e7 ff ff       	call   f0100c18 <check_va2pa>
f01024e9:	83 f8 ff             	cmp    $0xffffffff,%eax
f01024ec:	74 24                	je     f0102512 <mem_init+0x10aa>
f01024ee:	c7 44 24 0c c8 4b 10 	movl   $0xf0104bc8,0xc(%esp)
f01024f5:	f0 
f01024f6:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f01024fd:	f0 
f01024fe:	c7 44 24 04 47 03 00 	movl   $0x347,0x4(%esp)
f0102505:	00 
f0102506:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f010250d:	e8 82 db ff ff       	call   f0100094 <_panic>
	assert(check_va2pa(kern_pgdir, PGSIZE) == ~0);
f0102512:	ba 00 10 00 00       	mov    $0x1000,%edx
f0102517:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010251a:	e8 f9 e6 ff ff       	call   f0100c18 <check_va2pa>
f010251f:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102522:	74 24                	je     f0102548 <mem_init+0x10e0>
f0102524:	c7 44 24 0c ec 4b 10 	movl   $0xf0104bec,0xc(%esp)
f010252b:	f0 
f010252c:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f0102533:	f0 
f0102534:	c7 44 24 04 48 03 00 	movl   $0x348,0x4(%esp)
f010253b:	00 
f010253c:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f0102543:	e8 4c db ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 0);
f0102548:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f010254d:	74 24                	je     f0102573 <mem_init+0x110b>
f010254f:	c7 44 24 0c 0d 50 10 	movl   $0xf010500d,0xc(%esp)
f0102556:	f0 
f0102557:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f010255e:	f0 
f010255f:	c7 44 24 04 49 03 00 	movl   $0x349,0x4(%esp)
f0102566:	00 
f0102567:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f010256e:	e8 21 db ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 0);
f0102573:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102578:	74 24                	je     f010259e <mem_init+0x1136>
f010257a:	c7 44 24 0c fc 4f 10 	movl   $0xf0104ffc,0xc(%esp)
f0102581:	f0 
f0102582:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f0102589:	f0 
f010258a:	c7 44 24 04 4a 03 00 	movl   $0x34a,0x4(%esp)
f0102591:	00 
f0102592:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f0102599:	e8 f6 da ff ff       	call   f0100094 <_panic>

	// so it should be returned by page_alloc
	assert((pp = page_alloc(0)) && pp == pp1);
f010259e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01025a5:	e8 2d eb ff ff       	call   f01010d7 <page_alloc>
f01025aa:	85 c0                	test   %eax,%eax
f01025ac:	74 04                	je     f01025b2 <mem_init+0x114a>
f01025ae:	39 c7                	cmp    %eax,%edi
f01025b0:	74 24                	je     f01025d6 <mem_init+0x116e>
f01025b2:	c7 44 24 0c 14 4c 10 	movl   $0xf0104c14,0xc(%esp)
f01025b9:	f0 
f01025ba:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f01025c1:	f0 
f01025c2:	c7 44 24 04 4d 03 00 	movl   $0x34d,0x4(%esp)
f01025c9:	00 
f01025ca:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f01025d1:	e8 be da ff ff       	call   f0100094 <_panic>

	// should be no free memory
	assert(!page_alloc(0));
f01025d6:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01025dd:	e8 f5 ea ff ff       	call   f01010d7 <page_alloc>
f01025e2:	85 c0                	test   %eax,%eax
f01025e4:	74 24                	je     f010260a <mem_init+0x11a2>
f01025e6:	c7 44 24 0c 50 4f 10 	movl   $0xf0104f50,0xc(%esp)
f01025ed:	f0 
f01025ee:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f01025f5:	f0 
f01025f6:	c7 44 24 04 50 03 00 	movl   $0x350,0x4(%esp)
f01025fd:	00 
f01025fe:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f0102605:	e8 8a da ff ff       	call   f0100094 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f010260a:	a1 88 89 11 f0       	mov    0xf0118988,%eax
f010260f:	8b 08                	mov    (%eax),%ecx
f0102611:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f0102617:	89 f2                	mov    %esi,%edx
f0102619:	2b 15 8c 89 11 f0    	sub    0xf011898c,%edx
f010261f:	c1 fa 03             	sar    $0x3,%edx
f0102622:	c1 e2 0c             	shl    $0xc,%edx
f0102625:	39 d1                	cmp    %edx,%ecx
f0102627:	74 24                	je     f010264d <mem_init+0x11e5>
f0102629:	c7 44 24 0c f0 48 10 	movl   $0xf01048f0,0xc(%esp)
f0102630:	f0 
f0102631:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f0102638:	f0 
f0102639:	c7 44 24 04 53 03 00 	movl   $0x353,0x4(%esp)
f0102640:	00 
f0102641:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f0102648:	e8 47 da ff ff       	call   f0100094 <_panic>
	kern_pgdir[0] = 0;
f010264d:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f0102653:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102658:	74 24                	je     f010267e <mem_init+0x1216>
f010265a:	c7 44 24 0c b3 4f 10 	movl   $0xf0104fb3,0xc(%esp)
f0102661:	f0 
f0102662:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f0102669:	f0 
f010266a:	c7 44 24 04 55 03 00 	movl   $0x355,0x4(%esp)
f0102671:	00 
f0102672:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f0102679:	e8 16 da ff ff       	call   f0100094 <_panic>
	pp0->pp_ref = 0;
f010267e:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// check pointer arithmetic in pgdir_walk
	page_free(pp0);
f0102684:	89 34 24             	mov    %esi,(%esp)
f0102687:	e8 cc ea ff ff       	call   f0101158 <page_free>
	va = (void*)(PGSIZE * NPDENTRIES + PGSIZE);
	ptep = pgdir_walk(kern_pgdir, va, 1);
f010268c:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f0102693:	00 
f0102694:	c7 44 24 04 00 10 40 	movl   $0x401000,0x4(%esp)
f010269b:	00 
f010269c:	a1 88 89 11 f0       	mov    0xf0118988,%eax
f01026a1:	89 04 24             	mov    %eax,(%esp)
f01026a4:	e8 e7 ea ff ff       	call   f0101190 <pgdir_walk>
f01026a9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	ptep1 = (pte_t *) KADDR(PTE_ADDR(kern_pgdir[PDX(va)]));
f01026ac:	8b 0d 88 89 11 f0    	mov    0xf0118988,%ecx
f01026b2:	8b 51 04             	mov    0x4(%ecx),%edx
f01026b5:	81 e2 00 f0 ff ff    	and    $0xfffff000,%edx
f01026bb:	89 55 d4             	mov    %edx,-0x2c(%ebp)
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01026be:	8b 15 84 89 11 f0    	mov    0xf0118984,%edx
f01026c4:	89 55 c8             	mov    %edx,-0x38(%ebp)
f01026c7:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01026ca:	c1 ea 0c             	shr    $0xc,%edx
f01026cd:	89 55 d0             	mov    %edx,-0x30(%ebp)
f01026d0:	8b 55 c8             	mov    -0x38(%ebp),%edx
f01026d3:	39 55 d0             	cmp    %edx,-0x30(%ebp)
f01026d6:	72 23                	jb     f01026fb <mem_init+0x1293>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01026d8:	8b 4d d4             	mov    -0x2c(%ebp),%ecx
f01026db:	89 4c 24 0c          	mov    %ecx,0xc(%esp)
f01026df:	c7 44 24 08 b0 46 10 	movl   $0xf01046b0,0x8(%esp)
f01026e6:	f0 
f01026e7:	c7 44 24 04 5c 03 00 	movl   $0x35c,0x4(%esp)
f01026ee:	00 
f01026ef:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f01026f6:	e8 99 d9 ff ff       	call   f0100094 <_panic>
	assert(ptep == ptep1 + PTX(va));
f01026fb:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01026fe:	81 ea fc ff ff 0f    	sub    $0xffffffc,%edx
f0102704:	39 d0                	cmp    %edx,%eax
f0102706:	74 24                	je     f010272c <mem_init+0x12c4>
f0102708:	c7 44 24 0c 1e 50 10 	movl   $0xf010501e,0xc(%esp)
f010270f:	f0 
f0102710:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f0102717:	f0 
f0102718:	c7 44 24 04 5d 03 00 	movl   $0x35d,0x4(%esp)
f010271f:	00 
f0102720:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f0102727:	e8 68 d9 ff ff       	call   f0100094 <_panic>
	kern_pgdir[PDX(va)] = 0;
f010272c:	c7 41 04 00 00 00 00 	movl   $0x0,0x4(%ecx)
	pp0->pp_ref = 0;
f0102733:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102739:	89 f0                	mov    %esi,%eax
f010273b:	2b 05 8c 89 11 f0    	sub    0xf011898c,%eax
f0102741:	c1 f8 03             	sar    $0x3,%eax
f0102744:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102747:	89 c1                	mov    %eax,%ecx
f0102749:	c1 e9 0c             	shr    $0xc,%ecx
f010274c:	39 4d c8             	cmp    %ecx,-0x38(%ebp)
f010274f:	77 20                	ja     f0102771 <mem_init+0x1309>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102751:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102755:	c7 44 24 08 b0 46 10 	movl   $0xf01046b0,0x8(%esp)
f010275c:	f0 
f010275d:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0102764:	00 
f0102765:	c7 04 24 d8 4d 10 f0 	movl   $0xf0104dd8,(%esp)
f010276c:	e8 23 d9 ff ff       	call   f0100094 <_panic>

	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
f0102771:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102778:	00 
f0102779:	c7 44 24 04 ff 00 00 	movl   $0xff,0x4(%esp)
f0102780:	00 
	return (void *)(pa + KERNBASE);
f0102781:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102786:	89 04 24             	mov    %eax,(%esp)
f0102789:	e8 73 14 00 00       	call   f0103c01 <memset>
	page_free(pp0);
f010278e:	89 34 24             	mov    %esi,(%esp)
f0102791:	e8 c2 e9 ff ff       	call   f0101158 <page_free>
	pgdir_walk(kern_pgdir, 0x0, 1);
f0102796:	c7 44 24 08 01 00 00 	movl   $0x1,0x8(%esp)
f010279d:	00 
f010279e:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f01027a5:	00 
f01027a6:	a1 88 89 11 f0       	mov    0xf0118988,%eax
f01027ab:	89 04 24             	mov    %eax,(%esp)
f01027ae:	e8 dd e9 ff ff       	call   f0101190 <pgdir_walk>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f01027b3:	89 f2                	mov    %esi,%edx
f01027b5:	2b 15 8c 89 11 f0    	sub    0xf011898c,%edx
f01027bb:	c1 fa 03             	sar    $0x3,%edx
f01027be:	c1 e2 0c             	shl    $0xc,%edx
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f01027c1:	89 d0                	mov    %edx,%eax
f01027c3:	c1 e8 0c             	shr    $0xc,%eax
f01027c6:	3b 05 84 89 11 f0    	cmp    0xf0118984,%eax
f01027cc:	72 20                	jb     f01027ee <mem_init+0x1386>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f01027ce:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01027d2:	c7 44 24 08 b0 46 10 	movl   $0xf01046b0,0x8(%esp)
f01027d9:	f0 
f01027da:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f01027e1:	00 
f01027e2:	c7 04 24 d8 4d 10 f0 	movl   $0xf0104dd8,(%esp)
f01027e9:	e8 a6 d8 ff ff       	call   f0100094 <_panic>
	return (void *)(pa + KERNBASE);
f01027ee:	8d 82 00 00 00 f0    	lea    -0x10000000(%edx),%eax
	ptep = (pte_t *) page2kva(pp0);
f01027f4:	89 45 e4             	mov    %eax,-0x1c(%ebp)
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f01027f7:	f6 82 00 00 00 f0 01 	testb  $0x1,-0x10000000(%edx)
f01027fe:	75 11                	jne    f0102811 <mem_init+0x13a9>
f0102800:	8d 82 04 00 00 f0    	lea    -0xffffffc(%edx),%eax
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0102806:	81 ea 00 f0 ff 0f    	sub    $0xffff000,%edx
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
		assert((ptep[i] & PTE_P) == 0);
f010280c:	f6 00 01             	testb  $0x1,(%eax)
f010280f:	74 24                	je     f0102835 <mem_init+0x13cd>
f0102811:	c7 44 24 0c 36 50 10 	movl   $0xf0105036,0xc(%esp)
f0102818:	f0 
f0102819:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f0102820:	f0 
f0102821:	c7 44 24 04 67 03 00 	movl   $0x367,0x4(%esp)
f0102828:	00 
f0102829:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f0102830:	e8 5f d8 ff ff       	call   f0100094 <_panic>
f0102835:	83 c0 04             	add    $0x4,%eax
	// check that new page tables get cleared
	memset(page2kva(pp0), 0xFF, PGSIZE);
	page_free(pp0);
	pgdir_walk(kern_pgdir, 0x0, 1);
	ptep = (pte_t *) page2kva(pp0);
	for(i=0; i<NPTENTRIES; i++)
f0102838:	39 d0                	cmp    %edx,%eax
f010283a:	75 d0                	jne    f010280c <mem_init+0x13a4>
		assert((ptep[i] & PTE_P) == 0);
	kern_pgdir[0] = 0;
f010283c:	a1 88 89 11 f0       	mov    0xf0118988,%eax
f0102841:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	pp0->pp_ref = 0;
f0102847:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// give free list back
	page_free_list = fl;
f010284d:	8b 4d cc             	mov    -0x34(%ebp),%ecx
f0102850:	89 0d 60 85 11 f0    	mov    %ecx,0xf0118560

	// free the pages we took
	page_free(pp0);
f0102856:	89 34 24             	mov    %esi,(%esp)
f0102859:	e8 fa e8 ff ff       	call   f0101158 <page_free>
	page_free(pp1);
f010285e:	89 3c 24             	mov    %edi,(%esp)
f0102861:	e8 f2 e8 ff ff       	call   f0101158 <page_free>
	page_free(pp2);
f0102866:	89 1c 24             	mov    %ebx,(%esp)
f0102869:	e8 ea e8 ff ff       	call   f0101158 <page_free>

	cprintf("check_page() succeeded!\n");
f010286e:	c7 04 24 4d 50 10 f0 	movl   $0xf010504d,(%esp)
f0102875:	e8 d0 07 00 00       	call   f010304a <cprintf>
	// Permissions:
	//    - the new image at UPAGES -- kernel R, user R
	//      (ie. perm = PTE_U | PTE_P)
	//    - pages itself -- kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, UPAGES, ROUNDUP(npages * sizeof(struct PageInfo), PGSIZE), PADDR(pages), PTE_U | PTE_P);
f010287a:	a1 8c 89 11 f0       	mov    0xf011898c,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f010287f:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102884:	77 20                	ja     f01028a6 <mem_init+0x143e>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102886:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010288a:	c7 44 24 08 98 47 10 	movl   $0xf0104798,0x8(%esp)
f0102891:	f0 
f0102892:	c7 44 24 04 b2 00 00 	movl   $0xb2,0x4(%esp)
f0102899:	00 
f010289a:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f01028a1:	e8 ee d7 ff ff       	call   f0100094 <_panic>
f01028a6:	8b 15 84 89 11 f0    	mov    0xf0118984,%edx
f01028ac:	8d 0c d5 ff 0f 00 00 	lea    0xfff(,%edx,8),%ecx
f01028b3:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
f01028b9:	c7 44 24 04 05 00 00 	movl   $0x5,0x4(%esp)
f01028c0:	00 
	return (physaddr_t)kva - KERNBASE;
f01028c1:	05 00 00 00 10       	add    $0x10000000,%eax
f01028c6:	89 04 24             	mov    %eax,(%esp)
f01028c9:	ba 00 00 00 ef       	mov    $0xef000000,%edx
f01028ce:	a1 88 89 11 f0       	mov    0xf0118988,%eax
f01028d3:	e8 a7 e9 ff ff       	call   f010127f <boot_map_region>
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f01028d8:	be 00 e0 10 f0       	mov    $0xf010e000,%esi
f01028dd:	81 fe ff ff ff ef    	cmp    $0xefffffff,%esi
f01028e3:	77 20                	ja     f0102905 <mem_init+0x149d>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f01028e5:	89 74 24 0c          	mov    %esi,0xc(%esp)
f01028e9:	c7 44 24 08 98 47 10 	movl   $0xf0104798,0x8(%esp)
f01028f0:	f0 
f01028f1:	c7 44 24 04 bf 00 00 	movl   $0xbf,0x4(%esp)
f01028f8:	00 
f01028f9:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f0102900:	e8 8f d7 ff ff       	call   f0100094 <_panic>
	//     * [KSTACKTOP-PTSIZE, KSTACKTOP-KSTKSIZE) -- not backed; so if
	//       the kernel overflows its stack, it will fault rather than
	//       overwrite memory.  Known as a "guard page".
	//     Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KSTACKTOP - KSTKSIZE, KSTKSIZE, PADDR(bootstack), PTE_W);
f0102905:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f010290c:	00 
f010290d:	c7 04 24 00 e0 10 00 	movl   $0x10e000,(%esp)
f0102914:	b9 00 80 00 00       	mov    $0x8000,%ecx
f0102919:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f010291e:	a1 88 89 11 f0       	mov    0xf0118988,%eax
f0102923:	e8 57 e9 ff ff       	call   f010127f <boot_map_region>
	//      the PA range [0, 2^32 - KERNBASE)
	// We might not have 2^32 - KERNBASE bytes of physical memory, but
	// we just set up the mapping anyway.
	// Permissions: kernel RW, user NONE
	// Your code goes here:
	boot_map_region(kern_pgdir, KERNBASE, /*(1 << 32)*/ - KERNBASE, 0, PTE_W); 
f0102928:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f010292f:	00 
f0102930:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102937:	b9 00 00 00 10       	mov    $0x10000000,%ecx
f010293c:	ba 00 00 00 f0       	mov    $0xf0000000,%edx
f0102941:	a1 88 89 11 f0       	mov    0xf0118988,%eax
f0102946:	e8 34 e9 ff ff       	call   f010127f <boot_map_region>
check_kern_pgdir(void)
{
	uint32_t i, n;
	pde_t *pgdir;

	pgdir = kern_pgdir;
f010294b:	8b 1d 88 89 11 f0    	mov    0xf0118988,%ebx

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
f0102951:	8b 35 84 89 11 f0    	mov    0xf0118984,%esi
f0102957:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f010295a:	8d 3c f5 ff 0f 00 00 	lea    0xfff(,%esi,8),%edi
	for (i = 0; i < n; i += PGSIZE) {
f0102961:	81 e7 00 f0 ff ff    	and    $0xfffff000,%edi
f0102967:	74 79                	je     f01029e2 <mem_init+0x157a>
f0102969:	be 00 00 00 00       	mov    $0x0,%esi
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f010296e:	8d 96 00 00 00 ef    	lea    -0x11000000(%esi),%edx
	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE) {
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
f0102974:	89 d8                	mov    %ebx,%eax
f0102976:	e8 9d e2 ff ff       	call   f0100c18 <check_va2pa>
f010297b:	8b 15 8c 89 11 f0    	mov    0xf011898c,%edx
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102981:	81 fa ff ff ff ef    	cmp    $0xefffffff,%edx
f0102987:	77 20                	ja     f01029a9 <mem_init+0x1541>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102989:	89 54 24 0c          	mov    %edx,0xc(%esp)
f010298d:	c7 44 24 08 98 47 10 	movl   $0xf0104798,0x8(%esp)
f0102994:	f0 
f0102995:	c7 44 24 04 a7 02 00 	movl   $0x2a7,0x4(%esp)
f010299c:	00 
f010299d:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f01029a4:	e8 eb d6 ff ff       	call   f0100094 <_panic>
f01029a9:	8d 94 32 00 00 00 10 	lea    0x10000000(%edx,%esi,1),%edx
f01029b0:	39 d0                	cmp    %edx,%eax
f01029b2:	74 24                	je     f01029d8 <mem_init+0x1570>
f01029b4:	c7 44 24 0c 38 4c 10 	movl   $0xf0104c38,0xc(%esp)
f01029bb:	f0 
f01029bc:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f01029c3:	f0 
f01029c4:	c7 44 24 04 a7 02 00 	movl   $0x2a7,0x4(%esp)
f01029cb:	00 
f01029cc:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f01029d3:	e8 bc d6 ff ff       	call   f0100094 <_panic>

	pgdir = kern_pgdir;

	// check pages array
	n = ROUNDUP(npages*sizeof(struct PageInfo), PGSIZE);
	for (i = 0; i < n; i += PGSIZE) {
f01029d8:	81 c6 00 10 00 00    	add    $0x1000,%esi
f01029de:	39 f7                	cmp    %esi,%edi
f01029e0:	77 8c                	ja     f010296e <mem_init+0x1506>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
	}


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f01029e2:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f01029e5:	c1 e7 0c             	shl    $0xc,%edi
f01029e8:	85 ff                	test   %edi,%edi
f01029ea:	74 44                	je     f0102a30 <mem_init+0x15c8>
f01029ec:	be 00 00 00 00       	mov    $0x0,%esi
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f01029f1:	8d 96 00 00 00 f0    	lea    -0x10000000(%esi),%edx
	}


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);
f01029f7:	89 d8                	mov    %ebx,%eax
f01029f9:	e8 1a e2 ff ff       	call   f0100c18 <check_va2pa>
f01029fe:	39 c6                	cmp    %eax,%esi
f0102a00:	74 24                	je     f0102a26 <mem_init+0x15be>
f0102a02:	c7 44 24 0c 6c 4c 10 	movl   $0xf0104c6c,0xc(%esp)
f0102a09:	f0 
f0102a0a:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f0102a11:	f0 
f0102a12:	c7 44 24 04 ad 02 00 	movl   $0x2ad,0x4(%esp)
f0102a19:	00 
f0102a1a:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f0102a21:	e8 6e d6 ff ff       	call   f0100094 <_panic>
		assert(check_va2pa(pgdir, UPAGES + i) == PADDR(pages) + i);
	}


	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
f0102a26:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102a2c:	39 fe                	cmp    %edi,%esi
f0102a2e:	72 c1                	jb     f01029f1 <mem_init+0x1589>
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102a30:	ba 00 80 ff ef       	mov    $0xefff8000,%edx
f0102a35:	89 d8                	mov    %ebx,%eax
f0102a37:	e8 dc e1 ff ff       	call   f0100c18 <check_va2pa>
f0102a3c:	be 00 90 ff ef       	mov    $0xefff9000,%esi
// will be setup later.
//
// From UTOP to ULIM, the user is allowed to read but not write.
// Above ULIM the user cannot read or write.
void
mem_init(void)
f0102a41:	bf 00 e0 10 f0       	mov    $0xf010e000,%edi
f0102a46:	81 c7 00 70 00 20    	add    $0x20007000,%edi
f0102a4c:	8d 14 37             	lea    (%edi,%esi,1),%edx
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102a4f:	39 c2                	cmp    %eax,%edx
f0102a51:	74 24                	je     f0102a77 <mem_init+0x160f>
f0102a53:	c7 44 24 0c 94 4c 10 	movl   $0xf0104c94,0xc(%esp)
f0102a5a:	f0 
f0102a5b:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f0102a62:	f0 
f0102a63:	c7 44 24 04 b1 02 00 	movl   $0x2b1,0x4(%esp)
f0102a6a:	00 
f0102a6b:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f0102a72:	e8 1d d6 ff ff       	call   f0100094 <_panic>
	// check phys mem
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
f0102a77:	81 fe 00 00 00 f0    	cmp    $0xf0000000,%esi
f0102a7d:	0f 85 37 05 00 00    	jne    f0102fba <mem_init+0x1b52>
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);
f0102a83:	ba 00 00 c0 ef       	mov    $0xefc00000,%edx
f0102a88:	89 d8                	mov    %ebx,%eax
f0102a8a:	e8 89 e1 ff ff       	call   f0100c18 <check_va2pa>
f0102a8f:	83 f8 ff             	cmp    $0xffffffff,%eax
f0102a92:	74 24                	je     f0102ab8 <mem_init+0x1650>
f0102a94:	c7 44 24 0c dc 4c 10 	movl   $0xf0104cdc,0xc(%esp)
f0102a9b:	f0 
f0102a9c:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f0102aa3:	f0 
f0102aa4:	c7 44 24 04 b2 02 00 	movl   $0x2b2,0x4(%esp)
f0102aab:	00 
f0102aac:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f0102ab3:	e8 dc d5 ff ff       	call   f0100094 <_panic>
f0102ab8:	b8 00 00 00 00       	mov    $0x0,%eax

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
		switch (i) {
f0102abd:	ba 01 00 00 00       	mov    $0x1,%edx
f0102ac2:	8d 88 44 fc ff ff    	lea    -0x3bc(%eax),%ecx
f0102ac8:	83 f9 03             	cmp    $0x3,%ecx
f0102acb:	77 39                	ja     f0102b06 <mem_init+0x169e>
f0102acd:	89 d6                	mov    %edx,%esi
f0102acf:	d3 e6                	shl    %cl,%esi
f0102ad1:	89 f1                	mov    %esi,%ecx
f0102ad3:	f6 c1 0b             	test   $0xb,%cl
f0102ad6:	74 2e                	je     f0102b06 <mem_init+0x169e>
		case PDX(UVPT):
		case PDX(KSTACKTOP-1):
		case PDX(UPAGES):
			assert(pgdir[i] & PTE_P);
f0102ad8:	f6 04 83 01          	testb  $0x1,(%ebx,%eax,4)
f0102adc:	0f 85 aa 00 00 00    	jne    f0102b8c <mem_init+0x1724>
f0102ae2:	c7 44 24 0c 66 50 10 	movl   $0xf0105066,0xc(%esp)
f0102ae9:	f0 
f0102aea:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f0102af1:	f0 
f0102af2:	c7 44 24 04 ba 02 00 	movl   $0x2ba,0x4(%esp)
f0102af9:	00 
f0102afa:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f0102b01:	e8 8e d5 ff ff       	call   f0100094 <_panic>
			break;
		default:
			if (i >= PDX(KERNBASE)) {
f0102b06:	3d bf 03 00 00       	cmp    $0x3bf,%eax
f0102b0b:	76 55                	jbe    f0102b62 <mem_init+0x16fa>
				assert(pgdir[i] & PTE_P);
f0102b0d:	8b 0c 83             	mov    (%ebx,%eax,4),%ecx
f0102b10:	f6 c1 01             	test   $0x1,%cl
f0102b13:	75 24                	jne    f0102b39 <mem_init+0x16d1>
f0102b15:	c7 44 24 0c 66 50 10 	movl   $0xf0105066,0xc(%esp)
f0102b1c:	f0 
f0102b1d:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f0102b24:	f0 
f0102b25:	c7 44 24 04 be 02 00 	movl   $0x2be,0x4(%esp)
f0102b2c:	00 
f0102b2d:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f0102b34:	e8 5b d5 ff ff       	call   f0100094 <_panic>
				assert(pgdir[i] & PTE_W);
f0102b39:	f6 c1 02             	test   $0x2,%cl
f0102b3c:	75 4e                	jne    f0102b8c <mem_init+0x1724>
f0102b3e:	c7 44 24 0c 77 50 10 	movl   $0xf0105077,0xc(%esp)
f0102b45:	f0 
f0102b46:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f0102b4d:	f0 
f0102b4e:	c7 44 24 04 bf 02 00 	movl   $0x2bf,0x4(%esp)
f0102b55:	00 
f0102b56:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f0102b5d:	e8 32 d5 ff ff       	call   f0100094 <_panic>
			} else
				assert(pgdir[i] == 0);
f0102b62:	83 3c 83 00          	cmpl   $0x0,(%ebx,%eax,4)
f0102b66:	74 24                	je     f0102b8c <mem_init+0x1724>
f0102b68:	c7 44 24 0c 88 50 10 	movl   $0xf0105088,0xc(%esp)
f0102b6f:	f0 
f0102b70:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f0102b77:	f0 
f0102b78:	c7 44 24 04 c1 02 00 	movl   $0x2c1,0x4(%esp)
f0102b7f:	00 
f0102b80:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f0102b87:	e8 08 d5 ff ff       	call   f0100094 <_panic>
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
	assert(check_va2pa(pgdir, KSTACKTOP - PTSIZE) == ~0);

	// check PDE permissions
	for (i = 0; i < NPDENTRIES; i++) {
f0102b8c:	83 c0 01             	add    $0x1,%eax
f0102b8f:	3d 00 04 00 00       	cmp    $0x400,%eax
f0102b94:	0f 85 28 ff ff ff    	jne    f0102ac2 <mem_init+0x165a>
			} else
				assert(pgdir[i] == 0);
			break;
		}
	}
	cprintf("check_kern_pgdir() succeeded!\n");
f0102b9a:	c7 04 24 0c 4d 10 f0 	movl   $0xf0104d0c,(%esp)
f0102ba1:	e8 a4 04 00 00       	call   f010304a <cprintf>
	// somewhere between KERNBASE and KERNBASE+4MB right now, which is
	// mapped the same way by both page tables.
	//
	// If the machine reboots at this point, you've probably set up your
	// kern_pgdir wrong.
	lcr3(PADDR(kern_pgdir));
f0102ba6:	a1 88 89 11 f0       	mov    0xf0118988,%eax
#define PADDR(kva) _paddr(__FILE__, __LINE__, kva)

static inline physaddr_t
_paddr(const char *file, int line, void *kva)
{
	if ((uint32_t)kva < KERNBASE)
f0102bab:	3d ff ff ff ef       	cmp    $0xefffffff,%eax
f0102bb0:	77 20                	ja     f0102bd2 <mem_init+0x176a>
		_panic(file, line, "PADDR called with invalid kva %08lx", kva);
f0102bb2:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102bb6:	c7 44 24 08 98 47 10 	movl   $0xf0104798,0x8(%esp)
f0102bbd:	f0 
f0102bbe:	c7 44 24 04 d4 00 00 	movl   $0xd4,0x4(%esp)
f0102bc5:	00 
f0102bc6:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f0102bcd:	e8 c2 d4 ff ff       	call   f0100094 <_panic>
	return (physaddr_t)kva - KERNBASE;
f0102bd2:	05 00 00 00 10       	add    $0x10000000,%eax
}

static __inline void
lcr3(uint32_t val)
{
	__asm __volatile("movl %0,%%cr3" : : "r" (val));
f0102bd7:	0f 22 d8             	mov    %eax,%cr3

	check_page_free_list(0);
f0102bda:	b8 00 00 00 00       	mov    $0x0,%eax
f0102bdf:	e8 d7 e0 ff ff       	call   f0100cbb <check_page_free_list>

static __inline uint32_t
rcr0(void)
{
	uint32_t val;
	__asm __volatile("movl %%cr0,%0" : "=r" (val));
f0102be4:	0f 20 c0             	mov    %cr0,%eax

	// entry.S set the really important flags in cr0 (including enabling
	// paging).  Here we configure the rest of the flags that we care about.
	cr0 = rcr0();
	cr0 |= CR0_PE|CR0_PG|CR0_AM|CR0_WP|CR0_NE|CR0_MP;
f0102be7:	0d 23 00 05 80       	or     $0x80050023,%eax
	cr0 &= ~(CR0_TS|CR0_EM);
f0102bec:	83 e0 f3             	and    $0xfffffff3,%eax
}

static __inline void
lcr0(uint32_t val)
{
	__asm __volatile("movl %0,%%cr0" : : "r" (val));
f0102bef:	0f 22 c0             	mov    %eax,%cr0
	uintptr_t va;
	int i;

	// check that we can read and write installed pages
	pp1 = pp2 = 0;
	assert((pp0 = page_alloc(0)));
f0102bf2:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102bf9:	e8 d9 e4 ff ff       	call   f01010d7 <page_alloc>
f0102bfe:	89 c6                	mov    %eax,%esi
f0102c00:	85 c0                	test   %eax,%eax
f0102c02:	75 24                	jne    f0102c28 <mem_init+0x17c0>
f0102c04:	c7 44 24 0c a5 4e 10 	movl   $0xf0104ea5,0xc(%esp)
f0102c0b:	f0 
f0102c0c:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f0102c13:	f0 
f0102c14:	c7 44 24 04 82 03 00 	movl   $0x382,0x4(%esp)
f0102c1b:	00 
f0102c1c:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f0102c23:	e8 6c d4 ff ff       	call   f0100094 <_panic>
	assert((pp1 = page_alloc(0)));
f0102c28:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102c2f:	e8 a3 e4 ff ff       	call   f01010d7 <page_alloc>
f0102c34:	89 c7                	mov    %eax,%edi
f0102c36:	85 c0                	test   %eax,%eax
f0102c38:	75 24                	jne    f0102c5e <mem_init+0x17f6>
f0102c3a:	c7 44 24 0c bb 4e 10 	movl   $0xf0104ebb,0xc(%esp)
f0102c41:	f0 
f0102c42:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f0102c49:	f0 
f0102c4a:	c7 44 24 04 83 03 00 	movl   $0x383,0x4(%esp)
f0102c51:	00 
f0102c52:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f0102c59:	e8 36 d4 ff ff       	call   f0100094 <_panic>
	assert((pp2 = page_alloc(0)));
f0102c5e:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0102c65:	e8 6d e4 ff ff       	call   f01010d7 <page_alloc>
f0102c6a:	89 c3                	mov    %eax,%ebx
f0102c6c:	85 c0                	test   %eax,%eax
f0102c6e:	75 24                	jne    f0102c94 <mem_init+0x182c>
f0102c70:	c7 44 24 0c d1 4e 10 	movl   $0xf0104ed1,0xc(%esp)
f0102c77:	f0 
f0102c78:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f0102c7f:	f0 
f0102c80:	c7 44 24 04 84 03 00 	movl   $0x384,0x4(%esp)
f0102c87:	00 
f0102c88:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f0102c8f:	e8 00 d4 ff ff       	call   f0100094 <_panic>
	page_free(pp0);
f0102c94:	89 34 24             	mov    %esi,(%esp)
f0102c97:	e8 bc e4 ff ff       	call   f0101158 <page_free>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102c9c:	89 f8                	mov    %edi,%eax
f0102c9e:	2b 05 8c 89 11 f0    	sub    0xf011898c,%eax
f0102ca4:	c1 f8 03             	sar    $0x3,%eax
f0102ca7:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102caa:	89 c2                	mov    %eax,%edx
f0102cac:	c1 ea 0c             	shr    $0xc,%edx
f0102caf:	3b 15 84 89 11 f0    	cmp    0xf0118984,%edx
f0102cb5:	72 20                	jb     f0102cd7 <mem_init+0x186f>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102cb7:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102cbb:	c7 44 24 08 b0 46 10 	movl   $0xf01046b0,0x8(%esp)
f0102cc2:	f0 
f0102cc3:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0102cca:	00 
f0102ccb:	c7 04 24 d8 4d 10 f0 	movl   $0xf0104dd8,(%esp)
f0102cd2:	e8 bd d3 ff ff       	call   f0100094 <_panic>
	memset(page2kva(pp1), 1, PGSIZE);
f0102cd7:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102cde:	00 
f0102cdf:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0102ce6:	00 
	return (void *)(pa + KERNBASE);
f0102ce7:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102cec:	89 04 24             	mov    %eax,(%esp)
f0102cef:	e8 0d 0f 00 00       	call   f0103c01 <memset>
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102cf4:	89 d8                	mov    %ebx,%eax
f0102cf6:	2b 05 8c 89 11 f0    	sub    0xf011898c,%eax
f0102cfc:	c1 f8 03             	sar    $0x3,%eax
f0102cff:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102d02:	89 c2                	mov    %eax,%edx
f0102d04:	c1 ea 0c             	shr    $0xc,%edx
f0102d07:	3b 15 84 89 11 f0    	cmp    0xf0118984,%edx
f0102d0d:	72 20                	jb     f0102d2f <mem_init+0x18c7>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102d0f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102d13:	c7 44 24 08 b0 46 10 	movl   $0xf01046b0,0x8(%esp)
f0102d1a:	f0 
f0102d1b:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0102d22:	00 
f0102d23:	c7 04 24 d8 4d 10 f0 	movl   $0xf0104dd8,(%esp)
f0102d2a:	e8 65 d3 ff ff       	call   f0100094 <_panic>
	memset(page2kva(pp2), 2, PGSIZE);
f0102d2f:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102d36:	00 
f0102d37:	c7 44 24 04 02 00 00 	movl   $0x2,0x4(%esp)
f0102d3e:	00 
	return (void *)(pa + KERNBASE);
f0102d3f:	2d 00 00 00 10       	sub    $0x10000000,%eax
f0102d44:	89 04 24             	mov    %eax,(%esp)
f0102d47:	e8 b5 0e 00 00       	call   f0103c01 <memset>
	page_insert(kern_pgdir, pp1, (void*) PGSIZE, PTE_W);
f0102d4c:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102d53:	00 
f0102d54:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102d5b:	00 
f0102d5c:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0102d60:	a1 88 89 11 f0       	mov    0xf0118988,%eax
f0102d65:	89 04 24             	mov    %eax,(%esp)
f0102d68:	e8 39 e6 ff ff       	call   f01013a6 <page_insert>
	assert(pp1->pp_ref == 1);
f0102d6d:	66 83 7f 04 01       	cmpw   $0x1,0x4(%edi)
f0102d72:	74 24                	je     f0102d98 <mem_init+0x1930>
f0102d74:	c7 44 24 0c a2 4f 10 	movl   $0xf0104fa2,0xc(%esp)
f0102d7b:	f0 
f0102d7c:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f0102d83:	f0 
f0102d84:	c7 44 24 04 89 03 00 	movl   $0x389,0x4(%esp)
f0102d8b:	00 
f0102d8c:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f0102d93:	e8 fc d2 ff ff       	call   f0100094 <_panic>
	assert(*(uint32_t *)PGSIZE == 0x01010101U);
f0102d98:	81 3d 00 10 00 00 01 	cmpl   $0x1010101,0x1000
f0102d9f:	01 01 01 
f0102da2:	74 24                	je     f0102dc8 <mem_init+0x1960>
f0102da4:	c7 44 24 0c 2c 4d 10 	movl   $0xf0104d2c,0xc(%esp)
f0102dab:	f0 
f0102dac:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f0102db3:	f0 
f0102db4:	c7 44 24 04 8a 03 00 	movl   $0x38a,0x4(%esp)
f0102dbb:	00 
f0102dbc:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f0102dc3:	e8 cc d2 ff ff       	call   f0100094 <_panic>
	page_insert(kern_pgdir, pp2, (void*) PGSIZE, PTE_W);
f0102dc8:	c7 44 24 0c 02 00 00 	movl   $0x2,0xc(%esp)
f0102dcf:	00 
f0102dd0:	c7 44 24 08 00 10 00 	movl   $0x1000,0x8(%esp)
f0102dd7:	00 
f0102dd8:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0102ddc:	a1 88 89 11 f0       	mov    0xf0118988,%eax
f0102de1:	89 04 24             	mov    %eax,(%esp)
f0102de4:	e8 bd e5 ff ff       	call   f01013a6 <page_insert>
	assert(*(uint32_t *)PGSIZE == 0x02020202U);
f0102de9:	81 3d 00 10 00 00 02 	cmpl   $0x2020202,0x1000
f0102df0:	02 02 02 
f0102df3:	74 24                	je     f0102e19 <mem_init+0x19b1>
f0102df5:	c7 44 24 0c 50 4d 10 	movl   $0xf0104d50,0xc(%esp)
f0102dfc:	f0 
f0102dfd:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f0102e04:	f0 
f0102e05:	c7 44 24 04 8c 03 00 	movl   $0x38c,0x4(%esp)
f0102e0c:	00 
f0102e0d:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f0102e14:	e8 7b d2 ff ff       	call   f0100094 <_panic>
	assert(pp2->pp_ref == 1);
f0102e19:	66 83 7b 04 01       	cmpw   $0x1,0x4(%ebx)
f0102e1e:	74 24                	je     f0102e44 <mem_init+0x19dc>
f0102e20:	c7 44 24 0c c4 4f 10 	movl   $0xf0104fc4,0xc(%esp)
f0102e27:	f0 
f0102e28:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f0102e2f:	f0 
f0102e30:	c7 44 24 04 8d 03 00 	movl   $0x38d,0x4(%esp)
f0102e37:	00 
f0102e38:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f0102e3f:	e8 50 d2 ff ff       	call   f0100094 <_panic>
	assert(pp1->pp_ref == 0);
f0102e44:	66 83 7f 04 00       	cmpw   $0x0,0x4(%edi)
f0102e49:	74 24                	je     f0102e6f <mem_init+0x1a07>
f0102e4b:	c7 44 24 0c 0d 50 10 	movl   $0xf010500d,0xc(%esp)
f0102e52:	f0 
f0102e53:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f0102e5a:	f0 
f0102e5b:	c7 44 24 04 8e 03 00 	movl   $0x38e,0x4(%esp)
f0102e62:	00 
f0102e63:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f0102e6a:	e8 25 d2 ff ff       	call   f0100094 <_panic>
	*(uint32_t *)PGSIZE = 0x03030303U;
f0102e6f:	c7 05 00 10 00 00 03 	movl   $0x3030303,0x1000
f0102e76:	03 03 03 
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102e79:	89 d8                	mov    %ebx,%eax
f0102e7b:	2b 05 8c 89 11 f0    	sub    0xf011898c,%eax
f0102e81:	c1 f8 03             	sar    $0x3,%eax
f0102e84:	c1 e0 0c             	shl    $0xc,%eax
#define KADDR(pa) _kaddr(__FILE__, __LINE__, pa)

static inline void*
_kaddr(const char *file, int line, physaddr_t pa)
{
	if (PGNUM(pa) >= npages)
f0102e87:	89 c2                	mov    %eax,%edx
f0102e89:	c1 ea 0c             	shr    $0xc,%edx
f0102e8c:	3b 15 84 89 11 f0    	cmp    0xf0118984,%edx
f0102e92:	72 20                	jb     f0102eb4 <mem_init+0x1a4c>
		_panic(file, line, "KADDR called with invalid pa %08lx", pa);
f0102e94:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0102e98:	c7 44 24 08 b0 46 10 	movl   $0xf01046b0,0x8(%esp)
f0102e9f:	f0 
f0102ea0:	c7 44 24 04 52 00 00 	movl   $0x52,0x4(%esp)
f0102ea7:	00 
f0102ea8:	c7 04 24 d8 4d 10 f0 	movl   $0xf0104dd8,(%esp)
f0102eaf:	e8 e0 d1 ff ff       	call   f0100094 <_panic>
	assert(*(uint32_t *)page2kva(pp2) == 0x03030303U);
f0102eb4:	81 b8 00 00 00 f0 03 	cmpl   $0x3030303,-0x10000000(%eax)
f0102ebb:	03 03 03 
f0102ebe:	74 24                	je     f0102ee4 <mem_init+0x1a7c>
f0102ec0:	c7 44 24 0c 74 4d 10 	movl   $0xf0104d74,0xc(%esp)
f0102ec7:	f0 
f0102ec8:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f0102ecf:	f0 
f0102ed0:	c7 44 24 04 90 03 00 	movl   $0x390,0x4(%esp)
f0102ed7:	00 
f0102ed8:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f0102edf:	e8 b0 d1 ff ff       	call   f0100094 <_panic>
	page_remove(kern_pgdir, (void*) PGSIZE);
f0102ee4:	c7 44 24 04 00 10 00 	movl   $0x1000,0x4(%esp)
f0102eeb:	00 
f0102eec:	a1 88 89 11 f0       	mov    0xf0118988,%eax
f0102ef1:	89 04 24             	mov    %eax,(%esp)
f0102ef4:	e8 6f e4 ff ff       	call   f0101368 <page_remove>
	assert(pp2->pp_ref == 0);
f0102ef9:	66 83 7b 04 00       	cmpw   $0x0,0x4(%ebx)
f0102efe:	74 24                	je     f0102f24 <mem_init+0x1abc>
f0102f00:	c7 44 24 0c fc 4f 10 	movl   $0xf0104ffc,0xc(%esp)
f0102f07:	f0 
f0102f08:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f0102f0f:	f0 
f0102f10:	c7 44 24 04 92 03 00 	movl   $0x392,0x4(%esp)
f0102f17:	00 
f0102f18:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f0102f1f:	e8 70 d1 ff ff       	call   f0100094 <_panic>

	// forcibly take pp0 back
	assert(PTE_ADDR(kern_pgdir[0]) == page2pa(pp0));
f0102f24:	a1 88 89 11 f0       	mov    0xf0118988,%eax
f0102f29:	8b 08                	mov    (%eax),%ecx
f0102f2b:	81 e1 00 f0 ff ff    	and    $0xfffff000,%ecx
void	tlb_invalidate(pde_t *pgdir, void *va);

static inline physaddr_t
page2pa(struct PageInfo *pp)
{
	return (pp - pages) << PGSHIFT;
f0102f31:	89 f2                	mov    %esi,%edx
f0102f33:	2b 15 8c 89 11 f0    	sub    0xf011898c,%edx
f0102f39:	c1 fa 03             	sar    $0x3,%edx
f0102f3c:	c1 e2 0c             	shl    $0xc,%edx
f0102f3f:	39 d1                	cmp    %edx,%ecx
f0102f41:	74 24                	je     f0102f67 <mem_init+0x1aff>
f0102f43:	c7 44 24 0c f0 48 10 	movl   $0xf01048f0,0xc(%esp)
f0102f4a:	f0 
f0102f4b:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f0102f52:	f0 
f0102f53:	c7 44 24 04 95 03 00 	movl   $0x395,0x4(%esp)
f0102f5a:	00 
f0102f5b:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f0102f62:	e8 2d d1 ff ff       	call   f0100094 <_panic>
	kern_pgdir[0] = 0;
f0102f67:	c7 00 00 00 00 00    	movl   $0x0,(%eax)
	assert(pp0->pp_ref == 1);
f0102f6d:	66 83 7e 04 01       	cmpw   $0x1,0x4(%esi)
f0102f72:	74 24                	je     f0102f98 <mem_init+0x1b30>
f0102f74:	c7 44 24 0c b3 4f 10 	movl   $0xf0104fb3,0xc(%esp)
f0102f7b:	f0 
f0102f7c:	c7 44 24 08 f2 4d 10 	movl   $0xf0104df2,0x8(%esp)
f0102f83:	f0 
f0102f84:	c7 44 24 04 97 03 00 	movl   $0x397,0x4(%esp)
f0102f8b:	00 
f0102f8c:	c7 04 24 cc 4d 10 f0 	movl   $0xf0104dcc,(%esp)
f0102f93:	e8 fc d0 ff ff       	call   f0100094 <_panic>
	pp0->pp_ref = 0;
f0102f98:	66 c7 46 04 00 00    	movw   $0x0,0x4(%esi)

	// free the pages we took
	page_free(pp0);
f0102f9e:	89 34 24             	mov    %esi,(%esp)
f0102fa1:	e8 b2 e1 ff ff       	call   f0101158 <page_free>

	cprintf("check_page_installed_pgdir() succeeded!\n");
f0102fa6:	c7 04 24 a0 4d 10 f0 	movl   $0xf0104da0,(%esp)
f0102fad:	e8 98 00 00 00       	call   f010304a <cprintf>
	cr0 &= ~(CR0_TS|CR0_EM);
	lcr0(cr0);

	// Some more checks, only possible after kern_pgdir is installed.
	check_page_installed_pgdir();
}
f0102fb2:	83 c4 3c             	add    $0x3c,%esp
f0102fb5:	5b                   	pop    %ebx
f0102fb6:	5e                   	pop    %esi
f0102fb7:	5f                   	pop    %edi
f0102fb8:	5d                   	pop    %ebp
f0102fb9:	c3                   	ret    
	for (i = 0; i < npages * PGSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KERNBASE + i) == i);

	// check kernel stack
	for (i = 0; i < KSTKSIZE; i += PGSIZE)
		assert(check_va2pa(pgdir, KSTACKTOP - KSTKSIZE + i) == PADDR(bootstack) + i);
f0102fba:	89 f2                	mov    %esi,%edx
f0102fbc:	89 d8                	mov    %ebx,%eax
f0102fbe:	e8 55 dc ff ff       	call   f0100c18 <check_va2pa>
f0102fc3:	81 c6 00 10 00 00    	add    $0x1000,%esi
f0102fc9:	e9 7e fa ff ff       	jmp    f0102a4c <mem_init+0x15e4>

f0102fce <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0102fce:	55                   	push   %ebp
f0102fcf:	89 e5                	mov    %esp,%ebp
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0102fd1:	8b 45 0c             	mov    0xc(%ebp),%eax
f0102fd4:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f0102fd7:	5d                   	pop    %ebp
f0102fd8:	c3                   	ret    
f0102fd9:	00 00                	add    %al,(%eax)
	...

f0102fdc <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0102fdc:	55                   	push   %ebp
f0102fdd:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102fdf:	ba 70 00 00 00       	mov    $0x70,%edx
f0102fe4:	8b 45 08             	mov    0x8(%ebp),%eax
f0102fe7:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0102fe8:	b2 71                	mov    $0x71,%dl
f0102fea:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0102feb:	0f b6 c0             	movzbl %al,%eax
}
f0102fee:	5d                   	pop    %ebp
f0102fef:	c3                   	ret    

f0102ff0 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0102ff0:	55                   	push   %ebp
f0102ff1:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0102ff3:	ba 70 00 00 00       	mov    $0x70,%edx
f0102ff8:	8b 45 08             	mov    0x8(%ebp),%eax
f0102ffb:	ee                   	out    %al,(%dx)
f0102ffc:	b2 71                	mov    $0x71,%dl
f0102ffe:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103001:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0103002:	5d                   	pop    %ebp
f0103003:	c3                   	ret    

f0103004 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0103004:	55                   	push   %ebp
f0103005:	89 e5                	mov    %esp,%ebp
f0103007:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f010300a:	8b 45 08             	mov    0x8(%ebp),%eax
f010300d:	89 04 24             	mov    %eax,(%esp)
f0103010:	e8 e4 d5 ff ff       	call   f01005f9 <cputchar>
	*cnt++;
}
f0103015:	c9                   	leave  
f0103016:	c3                   	ret    

f0103017 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0103017:	55                   	push   %ebp
f0103018:	89 e5                	mov    %esp,%ebp
f010301a:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f010301d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0103024:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103027:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010302b:	8b 45 08             	mov    0x8(%ebp),%eax
f010302e:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103032:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0103035:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103039:	c7 04 24 04 30 10 f0 	movl   $0xf0103004,(%esp)
f0103040:	e8 b5 04 00 00       	call   f01034fa <vprintfmt>
	return cnt;
}
f0103045:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103048:	c9                   	leave  
f0103049:	c3                   	ret    

f010304a <cprintf>:

int
cprintf(const char *fmt, ...)
{
f010304a:	55                   	push   %ebp
f010304b:	89 e5                	mov    %esp,%ebp
f010304d:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0103050:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0103053:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103057:	8b 45 08             	mov    0x8(%ebp),%eax
f010305a:	89 04 24             	mov    %eax,(%esp)
f010305d:	e8 b5 ff ff ff       	call   f0103017 <vcprintf>
	va_end(ap);

	return cnt;
}
f0103062:	c9                   	leave  
f0103063:	c3                   	ret    

f0103064 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0103064:	55                   	push   %ebp
f0103065:	89 e5                	mov    %esp,%ebp
f0103067:	57                   	push   %edi
f0103068:	56                   	push   %esi
f0103069:	53                   	push   %ebx
f010306a:	83 ec 10             	sub    $0x10,%esp
f010306d:	89 c3                	mov    %eax,%ebx
f010306f:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0103072:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0103075:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f0103078:	8b 0a                	mov    (%edx),%ecx
f010307a:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010307d:	8b 00                	mov    (%eax),%eax
f010307f:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0103082:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)

	while (l <= r) {
f0103089:	eb 77                	jmp    f0103102 <stab_binsearch+0x9e>
		int true_m = (l + r) / 2, m = true_m;
f010308b:	8b 45 f0             	mov    -0x10(%ebp),%eax
f010308e:	01 c8                	add    %ecx,%eax
f0103090:	bf 02 00 00 00       	mov    $0x2,%edi
f0103095:	99                   	cltd   
f0103096:	f7 ff                	idiv   %edi
f0103098:	89 c2                	mov    %eax,%edx

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f010309a:	eb 01                	jmp    f010309d <stab_binsearch+0x39>
			m--;
f010309c:	4a                   	dec    %edx

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f010309d:	39 ca                	cmp    %ecx,%edx
f010309f:	7c 1d                	jl     f01030be <stab_binsearch+0x5a>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f01030a1:	6b fa 0c             	imul   $0xc,%edx,%edi

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f01030a4:	0f b6 7c 3b 04       	movzbl 0x4(%ebx,%edi,1),%edi
f01030a9:	39 f7                	cmp    %esi,%edi
f01030ab:	75 ef                	jne    f010309c <stab_binsearch+0x38>
f01030ad:	89 55 ec             	mov    %edx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f01030b0:	6b fa 0c             	imul   $0xc,%edx,%edi
f01030b3:	8b 7c 3b 08          	mov    0x8(%ebx,%edi,1),%edi
f01030b7:	3b 7d 0c             	cmp    0xc(%ebp),%edi
f01030ba:	73 18                	jae    f01030d4 <stab_binsearch+0x70>
f01030bc:	eb 05                	jmp    f01030c3 <stab_binsearch+0x5f>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f01030be:	8d 48 01             	lea    0x1(%eax),%ecx
			continue;
f01030c1:	eb 3f                	jmp    f0103102 <stab_binsearch+0x9e>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f01030c3:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f01030c6:	89 11                	mov    %edx,(%ecx)
			l = true_m + 1;
f01030c8:	8d 48 01             	lea    0x1(%eax),%ecx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01030cb:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f01030d2:	eb 2e                	jmp    f0103102 <stab_binsearch+0x9e>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f01030d4:	3b 7d 0c             	cmp    0xc(%ebp),%edi
f01030d7:	76 15                	jbe    f01030ee <stab_binsearch+0x8a>
			*region_right = m - 1;
f01030d9:	8b 7d ec             	mov    -0x14(%ebp),%edi
f01030dc:	4f                   	dec    %edi
f01030dd:	89 7d f0             	mov    %edi,-0x10(%ebp)
f01030e0:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f01030e3:	89 38                	mov    %edi,(%eax)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01030e5:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f01030ec:	eb 14                	jmp    f0103102 <stab_binsearch+0x9e>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f01030ee:	8b 7d ec             	mov    -0x14(%ebp),%edi
f01030f1:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f01030f4:	89 39                	mov    %edi,(%ecx)
			l = m;
			addr++;
f01030f6:	ff 45 0c             	incl   0xc(%ebp)
f01030f9:	89 d1                	mov    %edx,%ecx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f01030fb:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0103102:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
f0103105:	7e 84                	jle    f010308b <stab_binsearch+0x27>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0103107:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f010310b:	75 0d                	jne    f010311a <stab_binsearch+0xb6>
		*region_right = *region_left - 1;
f010310d:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0103110:	8b 02                	mov    (%edx),%eax
f0103112:	48                   	dec    %eax
f0103113:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0103116:	89 01                	mov    %eax,(%ecx)
f0103118:	eb 22                	jmp    f010313c <stab_binsearch+0xd8>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f010311a:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f010311d:	8b 01                	mov    (%ecx),%eax
		     l > *region_left && stabs[l].n_type != type;
f010311f:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0103122:	8b 0a                	mov    (%edx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103124:	eb 01                	jmp    f0103127 <stab_binsearch+0xc3>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0103126:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0103127:	39 c1                	cmp    %eax,%ecx
f0103129:	7d 0c                	jge    f0103137 <stab_binsearch+0xd3>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f010312b:	6b d0 0c             	imul   $0xc,%eax,%edx
	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
		     l > *region_left && stabs[l].n_type != type;
f010312e:	0f b6 54 13 04       	movzbl 0x4(%ebx,%edx,1),%edx
f0103133:	39 f2                	cmp    %esi,%edx
f0103135:	75 ef                	jne    f0103126 <stab_binsearch+0xc2>
		     l--)
			/* do nothing */;
		*region_left = l;
f0103137:	8b 55 e8             	mov    -0x18(%ebp),%edx
f010313a:	89 02                	mov    %eax,(%edx)
	}
}
f010313c:	83 c4 10             	add    $0x10,%esp
f010313f:	5b                   	pop    %ebx
f0103140:	5e                   	pop    %esi
f0103141:	5f                   	pop    %edi
f0103142:	5d                   	pop    %ebp
f0103143:	c3                   	ret    

f0103144 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0103144:	55                   	push   %ebp
f0103145:	89 e5                	mov    %esp,%ebp
f0103147:	83 ec 58             	sub    $0x58,%esp
f010314a:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f010314d:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0103150:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0103153:	8b 75 08             	mov    0x8(%ebp),%esi
f0103156:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0103159:	c7 03 96 50 10 f0    	movl   $0xf0105096,(%ebx)
	info->eip_line = 0;
f010315f:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0103166:	c7 43 08 96 50 10 f0 	movl   $0xf0105096,0x8(%ebx)
	info->eip_fn_namelen = 9;
f010316d:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0103174:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0103177:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f010317e:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0103184:	76 12                	jbe    f0103198 <debuginfo_eip+0x54>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0103186:	b8 11 d7 10 f0       	mov    $0xf010d711,%eax
f010318b:	3d 3d b8 10 f0       	cmp    $0xf010b83d,%eax
f0103190:	0f 86 f1 01 00 00    	jbe    f0103387 <debuginfo_eip+0x243>
f0103196:	eb 1c                	jmp    f01031b4 <debuginfo_eip+0x70>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0103198:	c7 44 24 08 a0 50 10 	movl   $0xf01050a0,0x8(%esp)
f010319f:	f0 
f01031a0:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f01031a7:	00 
f01031a8:	c7 04 24 ad 50 10 f0 	movl   $0xf01050ad,(%esp)
f01031af:	e8 e0 ce ff ff       	call   f0100094 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f01031b4:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f01031b9:	80 3d 10 d7 10 f0 00 	cmpb   $0x0,0xf010d710
f01031c0:	0f 85 cd 01 00 00    	jne    f0103393 <debuginfo_eip+0x24f>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f01031c6:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f01031cd:	b8 3c b8 10 f0       	mov    $0xf010b83c,%eax
f01031d2:	2d cc 52 10 f0       	sub    $0xf01052cc,%eax
f01031d7:	c1 f8 02             	sar    $0x2,%eax
f01031da:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f01031e0:	83 e8 01             	sub    $0x1,%eax
f01031e3:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f01031e6:	89 74 24 04          	mov    %esi,0x4(%esp)
f01031ea:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f01031f1:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f01031f4:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f01031f7:	b8 cc 52 10 f0       	mov    $0xf01052cc,%eax
f01031fc:	e8 63 fe ff ff       	call   f0103064 <stab_binsearch>
	if (lfile == 0)
f0103201:	8b 55 e4             	mov    -0x1c(%ebp),%edx
		return -1;
f0103204:	b8 ff ff ff ff       	mov    $0xffffffff,%eax

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
f0103209:	85 d2                	test   %edx,%edx
f010320b:	0f 84 82 01 00 00    	je     f0103393 <debuginfo_eip+0x24f>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0103211:	89 55 dc             	mov    %edx,-0x24(%ebp)
	rfun = rfile;
f0103214:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103217:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f010321a:	89 74 24 04          	mov    %esi,0x4(%esp)
f010321e:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0103225:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0103228:	8d 55 dc             	lea    -0x24(%ebp),%edx
f010322b:	b8 cc 52 10 f0       	mov    $0xf01052cc,%eax
f0103230:	e8 2f fe ff ff       	call   f0103064 <stab_binsearch>

	if (lfun <= rfun) {
f0103235:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103238:	8b 55 d8             	mov    -0x28(%ebp),%edx
f010323b:	39 d0                	cmp    %edx,%eax
f010323d:	7f 3d                	jg     f010327c <debuginfo_eip+0x138>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f010323f:	6b c8 0c             	imul   $0xc,%eax,%ecx
f0103242:	8d b9 cc 52 10 f0    	lea    -0xfefad34(%ecx),%edi
f0103248:	89 7d c0             	mov    %edi,-0x40(%ebp)
f010324b:	8b 89 cc 52 10 f0    	mov    -0xfefad34(%ecx),%ecx
f0103251:	bf 11 d7 10 f0       	mov    $0xf010d711,%edi
f0103256:	81 ef 3d b8 10 f0    	sub    $0xf010b83d,%edi
f010325c:	39 f9                	cmp    %edi,%ecx
f010325e:	73 09                	jae    f0103269 <debuginfo_eip+0x125>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0103260:	81 c1 3d b8 10 f0    	add    $0xf010b83d,%ecx
f0103266:	89 4b 08             	mov    %ecx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0103269:	8b 7d c0             	mov    -0x40(%ebp),%edi
f010326c:	8b 4f 08             	mov    0x8(%edi),%ecx
f010326f:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0103272:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0103274:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0103277:	89 55 d0             	mov    %edx,-0x30(%ebp)
f010327a:	eb 0f                	jmp    f010328b <debuginfo_eip+0x147>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f010327c:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f010327f:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103282:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0103285:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103288:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f010328b:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0103292:	00 
f0103293:	8b 43 08             	mov    0x8(%ebx),%eax
f0103296:	89 04 24             	mov    %eax,(%esp)
f0103299:	e8 3c 09 00 00       	call   f0103bda <strfind>
f010329e:	2b 43 08             	sub    0x8(%ebx),%eax
f01032a1:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f01032a4:	89 74 24 04          	mov    %esi,0x4(%esp)
f01032a8:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f01032af:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f01032b2:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f01032b5:	b8 cc 52 10 f0       	mov    $0xf01052cc,%eax
f01032ba:	e8 a5 fd ff ff       	call   f0103064 <stab_binsearch>
	if (lline <= rline) {
f01032bf:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01032c2:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f01032c5:	7f 0f                	jg     f01032d6 <debuginfo_eip+0x192>
		info->eip_line = stabs[lline].n_desc;
f01032c7:	6b c0 0c             	imul   $0xc,%eax,%eax
f01032ca:	0f b7 80 d2 52 10 f0 	movzwl -0xfefad2e(%eax),%eax
f01032d1:	89 43 04             	mov    %eax,0x4(%ebx)
f01032d4:	eb 07                	jmp    f01032dd <debuginfo_eip+0x199>
	} else {
		info->eip_line = -1;
f01032d6:	c7 43 04 ff ff ff ff 	movl   $0xffffffff,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01032dd:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01032e0:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f01032e3:	39 c8                	cmp    %ecx,%eax
f01032e5:	7c 5f                	jl     f0103346 <debuginfo_eip+0x202>
	       && stabs[lline].n_type != N_SOL
f01032e7:	89 c2                	mov    %eax,%edx
f01032e9:	6b f0 0c             	imul   $0xc,%eax,%esi
f01032ec:	80 be d0 52 10 f0 84 	cmpb   $0x84,-0xfefad30(%esi)
f01032f3:	75 18                	jne    f010330d <debuginfo_eip+0x1c9>
f01032f5:	eb 30                	jmp    f0103327 <debuginfo_eip+0x1e3>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f01032f7:	83 e8 01             	sub    $0x1,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f01032fa:	39 c1                	cmp    %eax,%ecx
f01032fc:	7f 48                	jg     f0103346 <debuginfo_eip+0x202>
	       && stabs[lline].n_type != N_SOL
f01032fe:	89 c2                	mov    %eax,%edx
f0103300:	8d 34 40             	lea    (%eax,%eax,2),%esi
f0103303:	80 3c b5 d0 52 10 f0 	cmpb   $0x84,-0xfefad30(,%esi,4)
f010330a:	84 
f010330b:	74 1a                	je     f0103327 <debuginfo_eip+0x1e3>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f010330d:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0103310:	8d 14 95 cc 52 10 f0 	lea    -0xfefad34(,%edx,4),%edx
f0103317:	80 7a 04 64          	cmpb   $0x64,0x4(%edx)
f010331b:	75 da                	jne    f01032f7 <debuginfo_eip+0x1b3>
f010331d:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f0103321:	74 d4                	je     f01032f7 <debuginfo_eip+0x1b3>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0103323:	39 c8                	cmp    %ecx,%eax
f0103325:	7c 1f                	jl     f0103346 <debuginfo_eip+0x202>
f0103327:	6b c0 0c             	imul   $0xc,%eax,%eax
f010332a:	8b 80 cc 52 10 f0    	mov    -0xfefad34(%eax),%eax
f0103330:	ba 11 d7 10 f0       	mov    $0xf010d711,%edx
f0103335:	81 ea 3d b8 10 f0    	sub    $0xf010b83d,%edx
f010333b:	39 d0                	cmp    %edx,%eax
f010333d:	73 07                	jae    f0103346 <debuginfo_eip+0x202>
		info->eip_file = stabstr + stabs[lline].n_strx;
f010333f:	05 3d b8 10 f0       	add    $0xf010b83d,%eax
f0103344:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103346:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0103349:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f010334c:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0103351:	39 ca                	cmp    %ecx,%edx
f0103353:	7d 3e                	jge    f0103393 <debuginfo_eip+0x24f>
		for (lline = lfun + 1;
f0103355:	83 c2 01             	add    $0x1,%edx
f0103358:	39 d1                	cmp    %edx,%ecx
f010335a:	7e 37                	jle    f0103393 <debuginfo_eip+0x24f>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f010335c:	6b f2 0c             	imul   $0xc,%edx,%esi
f010335f:	80 be d0 52 10 f0 a0 	cmpb   $0xa0,-0xfefad30(%esi)
f0103366:	75 2b                	jne    f0103393 <debuginfo_eip+0x24f>
		     lline++)
			info->eip_fn_narg++;
f0103368:	83 43 14 01          	addl   $0x1,0x14(%ebx)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f010336c:	83 c2 01             	add    $0x1,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f010336f:	39 d1                	cmp    %edx,%ecx
f0103371:	7e 1b                	jle    f010338e <debuginfo_eip+0x24a>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0103373:	8d 04 52             	lea    (%edx,%edx,2),%eax
f0103376:	80 3c 85 d0 52 10 f0 	cmpb   $0xa0,-0xfefad30(,%eax,4)
f010337d:	a0 
f010337e:	74 e8                	je     f0103368 <debuginfo_eip+0x224>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0103380:	b8 00 00 00 00       	mov    $0x0,%eax
f0103385:	eb 0c                	jmp    f0103393 <debuginfo_eip+0x24f>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0103387:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f010338c:	eb 05                	jmp    f0103393 <debuginfo_eip+0x24f>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f010338e:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103393:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0103396:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0103399:	8b 7d fc             	mov    -0x4(%ebp),%edi
f010339c:	89 ec                	mov    %ebp,%esp
f010339e:	5d                   	pop    %ebp
f010339f:	c3                   	ret    

f01033a0 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f01033a0:	55                   	push   %ebp
f01033a1:	89 e5                	mov    %esp,%ebp
f01033a3:	57                   	push   %edi
f01033a4:	56                   	push   %esi
f01033a5:	53                   	push   %ebx
f01033a6:	83 ec 3c             	sub    $0x3c,%esp
f01033a9:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01033ac:	89 d7                	mov    %edx,%edi
f01033ae:	8b 45 08             	mov    0x8(%ebp),%eax
f01033b1:	89 45 dc             	mov    %eax,-0x24(%ebp)
f01033b4:	8b 45 0c             	mov    0xc(%ebp),%eax
f01033b7:	89 45 e0             	mov    %eax,-0x20(%ebp)
f01033ba:	8b 5d 14             	mov    0x14(%ebp),%ebx
f01033bd:	8b 75 18             	mov    0x18(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f01033c0:	b8 00 00 00 00       	mov    $0x0,%eax
f01033c5:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f01033c8:	72 11                	jb     f01033db <printnum+0x3b>
f01033ca:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01033cd:	39 45 10             	cmp    %eax,0x10(%ebp)
f01033d0:	76 09                	jbe    f01033db <printnum+0x3b>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f01033d2:	83 eb 01             	sub    $0x1,%ebx
f01033d5:	85 db                	test   %ebx,%ebx
f01033d7:	7f 51                	jg     f010342a <printnum+0x8a>
f01033d9:	eb 5e                	jmp    f0103439 <printnum+0x99>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
f01033db:	89 74 24 10          	mov    %esi,0x10(%esp)
f01033df:	83 eb 01             	sub    $0x1,%ebx
f01033e2:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f01033e6:	8b 45 10             	mov    0x10(%ebp),%eax
f01033e9:	89 44 24 08          	mov    %eax,0x8(%esp)
f01033ed:	8b 5c 24 08          	mov    0x8(%esp),%ebx
f01033f1:	8b 74 24 0c          	mov    0xc(%esp),%esi
f01033f5:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f01033fc:	00 
f01033fd:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103400:	89 04 24             	mov    %eax,(%esp)
f0103403:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103406:	89 44 24 04          	mov    %eax,0x4(%esp)
f010340a:	e8 41 0a 00 00       	call   f0103e50 <__udivdi3>
f010340f:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0103413:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0103417:	89 04 24             	mov    %eax,(%esp)
f010341a:	89 54 24 04          	mov    %edx,0x4(%esp)
f010341e:	89 fa                	mov    %edi,%edx
f0103420:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0103423:	e8 78 ff ff ff       	call   f01033a0 <printnum>
f0103428:	eb 0f                	jmp    f0103439 <printnum+0x99>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f010342a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010342e:	89 34 24             	mov    %esi,(%esp)
f0103431:	ff 55 e4             	call   *-0x1c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0103434:	83 eb 01             	sub    $0x1,%ebx
f0103437:	75 f1                	jne    f010342a <printnum+0x8a>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f0103439:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010343d:	8b 7c 24 04          	mov    0x4(%esp),%edi
f0103441:	8b 45 10             	mov    0x10(%ebp),%eax
f0103444:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103448:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f010344f:	00 
f0103450:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0103453:	89 04 24             	mov    %eax,(%esp)
f0103456:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0103459:	89 44 24 04          	mov    %eax,0x4(%esp)
f010345d:	e8 1e 0b 00 00       	call   f0103f80 <__umoddi3>
f0103462:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103466:	0f be 80 bb 50 10 f0 	movsbl -0xfefaf45(%eax),%eax
f010346d:	89 04 24             	mov    %eax,(%esp)
f0103470:	ff 55 e4             	call   *-0x1c(%ebp)
}
f0103473:	83 c4 3c             	add    $0x3c,%esp
f0103476:	5b                   	pop    %ebx
f0103477:	5e                   	pop    %esi
f0103478:	5f                   	pop    %edi
f0103479:	5d                   	pop    %ebp
f010347a:	c3                   	ret    

f010347b <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f010347b:	55                   	push   %ebp
f010347c:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f010347e:	83 fa 01             	cmp    $0x1,%edx
f0103481:	7e 0e                	jle    f0103491 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f0103483:	8b 10                	mov    (%eax),%edx
f0103485:	8d 4a 08             	lea    0x8(%edx),%ecx
f0103488:	89 08                	mov    %ecx,(%eax)
f010348a:	8b 02                	mov    (%edx),%eax
f010348c:	8b 52 04             	mov    0x4(%edx),%edx
f010348f:	eb 22                	jmp    f01034b3 <getuint+0x38>
	else if (lflag)
f0103491:	85 d2                	test   %edx,%edx
f0103493:	74 10                	je     f01034a5 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0103495:	8b 10                	mov    (%eax),%edx
f0103497:	8d 4a 04             	lea    0x4(%edx),%ecx
f010349a:	89 08                	mov    %ecx,(%eax)
f010349c:	8b 02                	mov    (%edx),%eax
f010349e:	ba 00 00 00 00       	mov    $0x0,%edx
f01034a3:	eb 0e                	jmp    f01034b3 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f01034a5:	8b 10                	mov    (%eax),%edx
f01034a7:	8d 4a 04             	lea    0x4(%edx),%ecx
f01034aa:	89 08                	mov    %ecx,(%eax)
f01034ac:	8b 02                	mov    (%edx),%eax
f01034ae:	ba 00 00 00 00       	mov    $0x0,%edx
}
f01034b3:	5d                   	pop    %ebp
f01034b4:	c3                   	ret    

f01034b5 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f01034b5:	55                   	push   %ebp
f01034b6:	89 e5                	mov    %esp,%ebp
f01034b8:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f01034bb:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f01034bf:	8b 10                	mov    (%eax),%edx
f01034c1:	3b 50 04             	cmp    0x4(%eax),%edx
f01034c4:	73 0a                	jae    f01034d0 <sprintputch+0x1b>
		*b->buf++ = ch;
f01034c6:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01034c9:	88 0a                	mov    %cl,(%edx)
f01034cb:	83 c2 01             	add    $0x1,%edx
f01034ce:	89 10                	mov    %edx,(%eax)
}
f01034d0:	5d                   	pop    %ebp
f01034d1:	c3                   	ret    

f01034d2 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f01034d2:	55                   	push   %ebp
f01034d3:	89 e5                	mov    %esp,%ebp
f01034d5:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f01034d8:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f01034db:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01034df:	8b 45 10             	mov    0x10(%ebp),%eax
f01034e2:	89 44 24 08          	mov    %eax,0x8(%esp)
f01034e6:	8b 45 0c             	mov    0xc(%ebp),%eax
f01034e9:	89 44 24 04          	mov    %eax,0x4(%esp)
f01034ed:	8b 45 08             	mov    0x8(%ebp),%eax
f01034f0:	89 04 24             	mov    %eax,(%esp)
f01034f3:	e8 02 00 00 00       	call   f01034fa <vprintfmt>
	va_end(ap);
}
f01034f8:	c9                   	leave  
f01034f9:	c3                   	ret    

f01034fa <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f01034fa:	55                   	push   %ebp
f01034fb:	89 e5                	mov    %esp,%ebp
f01034fd:	57                   	push   %edi
f01034fe:	56                   	push   %esi
f01034ff:	53                   	push   %ebx
f0103500:	83 ec 4c             	sub    $0x4c,%esp
f0103503:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103506:	8b 75 10             	mov    0x10(%ebp),%esi
f0103509:	eb 12                	jmp    f010351d <vprintfmt+0x23>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f010350b:	85 c0                	test   %eax,%eax
f010350d:	0f 84 a9 03 00 00    	je     f01038bc <vprintfmt+0x3c2>
				return;
			putch(ch, putdat);
f0103513:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103517:	89 04 24             	mov    %eax,(%esp)
f010351a:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f010351d:	0f b6 06             	movzbl (%esi),%eax
f0103520:	83 c6 01             	add    $0x1,%esi
f0103523:	83 f8 25             	cmp    $0x25,%eax
f0103526:	75 e3                	jne    f010350b <vprintfmt+0x11>
f0103528:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
f010352c:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
f0103533:	bf ff ff ff ff       	mov    $0xffffffff,%edi
f0103538:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
f010353f:	b9 00 00 00 00       	mov    $0x0,%ecx
f0103544:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0103547:	eb 2b                	jmp    f0103574 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103549:	8b 75 e0             	mov    -0x20(%ebp),%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f010354c:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
f0103550:	eb 22                	jmp    f0103574 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103552:	8b 75 e0             	mov    -0x20(%ebp),%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f0103555:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
f0103559:	eb 19                	jmp    f0103574 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010355b:	8b 75 e0             	mov    -0x20(%ebp),%esi
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
f010355e:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f0103565:	eb 0d                	jmp    f0103574 <vprintfmt+0x7a>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f0103567:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f010356a:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010356d:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103574:	0f b6 06             	movzbl (%esi),%eax
f0103577:	0f b6 d0             	movzbl %al,%edx
f010357a:	8d 7e 01             	lea    0x1(%esi),%edi
f010357d:	89 7d e0             	mov    %edi,-0x20(%ebp)
f0103580:	83 e8 23             	sub    $0x23,%eax
f0103583:	3c 55                	cmp    $0x55,%al
f0103585:	0f 87 0b 03 00 00    	ja     f0103896 <vprintfmt+0x39c>
f010358b:	0f b6 c0             	movzbl %al,%eax
f010358e:	ff 24 85 48 51 10 f0 	jmp    *-0xfefaeb8(,%eax,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0103595:	83 ea 30             	sub    $0x30,%edx
f0103598:	89 55 d4             	mov    %edx,-0x2c(%ebp)
				ch = *fmt;
f010359b:	0f be 46 01          	movsbl 0x1(%esi),%eax
				if (ch < '0' || ch > '9')
f010359f:	8d 50 d0             	lea    -0x30(%eax),%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01035a2:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
f01035a5:	83 fa 09             	cmp    $0x9,%edx
f01035a8:	77 4a                	ja     f01035f4 <vprintfmt+0xfa>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01035aa:	8b 7d d4             	mov    -0x2c(%ebp),%edi
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f01035ad:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
f01035b0:	8d 14 bf             	lea    (%edi,%edi,4),%edx
f01035b3:	8d 7c 50 d0          	lea    -0x30(%eax,%edx,2),%edi
				ch = *fmt;
f01035b7:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f01035ba:	8d 50 d0             	lea    -0x30(%eax),%edx
f01035bd:	83 fa 09             	cmp    $0x9,%edx
f01035c0:	76 eb                	jbe    f01035ad <vprintfmt+0xb3>
f01035c2:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f01035c5:	eb 2d                	jmp    f01035f4 <vprintfmt+0xfa>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f01035c7:	8b 45 14             	mov    0x14(%ebp),%eax
f01035ca:	8d 50 04             	lea    0x4(%eax),%edx
f01035cd:	89 55 14             	mov    %edx,0x14(%ebp)
f01035d0:	8b 00                	mov    (%eax),%eax
f01035d2:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01035d5:	8b 75 e0             	mov    -0x20(%ebp),%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f01035d8:	eb 1a                	jmp    f01035f4 <vprintfmt+0xfa>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01035da:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case '*':
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
f01035dd:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01035e1:	79 91                	jns    f0103574 <vprintfmt+0x7a>
f01035e3:	e9 73 ff ff ff       	jmp    f010355b <vprintfmt+0x61>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01035e8:	8b 75 e0             	mov    -0x20(%ebp),%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f01035eb:	c7 45 dc 01 00 00 00 	movl   $0x1,-0x24(%ebp)
			goto reswitch;
f01035f2:	eb 80                	jmp    f0103574 <vprintfmt+0x7a>

		process_precision:
			if (width < 0)
f01035f4:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01035f8:	0f 89 76 ff ff ff    	jns    f0103574 <vprintfmt+0x7a>
f01035fe:	e9 64 ff ff ff       	jmp    f0103567 <vprintfmt+0x6d>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0103603:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103606:	8b 75 e0             	mov    -0x20(%ebp),%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0103609:	e9 66 ff ff ff       	jmp    f0103574 <vprintfmt+0x7a>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f010360e:	8b 45 14             	mov    0x14(%ebp),%eax
f0103611:	8d 50 04             	lea    0x4(%eax),%edx
f0103614:	89 55 14             	mov    %edx,0x14(%ebp)
f0103617:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010361b:	8b 00                	mov    (%eax),%eax
f010361d:	89 04 24             	mov    %eax,(%esp)
f0103620:	ff 55 08             	call   *0x8(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103623:	8b 75 e0             	mov    -0x20(%ebp),%esi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0103626:	e9 f2 fe ff ff       	jmp    f010351d <vprintfmt+0x23>

		// error message
		case 'e':
			err = va_arg(ap, int);
f010362b:	8b 45 14             	mov    0x14(%ebp),%eax
f010362e:	8d 50 04             	lea    0x4(%eax),%edx
f0103631:	89 55 14             	mov    %edx,0x14(%ebp)
f0103634:	8b 00                	mov    (%eax),%eax
f0103636:	89 c2                	mov    %eax,%edx
f0103638:	c1 fa 1f             	sar    $0x1f,%edx
f010363b:	31 d0                	xor    %edx,%eax
f010363d:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f010363f:	83 f8 06             	cmp    $0x6,%eax
f0103642:	7f 0b                	jg     f010364f <vprintfmt+0x155>
f0103644:	8b 14 85 a0 52 10 f0 	mov    -0xfefad60(,%eax,4),%edx
f010364b:	85 d2                	test   %edx,%edx
f010364d:	75 23                	jne    f0103672 <vprintfmt+0x178>
				printfmt(putch, putdat, "error %d", err);
f010364f:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103653:	c7 44 24 08 d3 50 10 	movl   $0xf01050d3,0x8(%esp)
f010365a:	f0 
f010365b:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010365f:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103662:	89 3c 24             	mov    %edi,(%esp)
f0103665:	e8 68 fe ff ff       	call   f01034d2 <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010366a:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f010366d:	e9 ab fe ff ff       	jmp    f010351d <vprintfmt+0x23>
			else
				printfmt(putch, putdat, "%s", p);
f0103672:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103676:	c7 44 24 08 04 4e 10 	movl   $0xf0104e04,0x8(%esp)
f010367d:	f0 
f010367e:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103682:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103685:	89 3c 24             	mov    %edi,(%esp)
f0103688:	e8 45 fe ff ff       	call   f01034d2 <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010368d:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0103690:	e9 88 fe ff ff       	jmp    f010351d <vprintfmt+0x23>
f0103695:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0103698:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010369b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f010369e:	8b 45 14             	mov    0x14(%ebp),%eax
f01036a1:	8d 50 04             	lea    0x4(%eax),%edx
f01036a4:	89 55 14             	mov    %edx,0x14(%ebp)
f01036a7:	8b 30                	mov    (%eax),%esi
				p = "(null)";
f01036a9:	85 f6                	test   %esi,%esi
f01036ab:	ba cc 50 10 f0       	mov    $0xf01050cc,%edx
f01036b0:	0f 44 f2             	cmove  %edx,%esi
			if (width > 0 && padc != '-')
f01036b3:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f01036b7:	7e 06                	jle    f01036bf <vprintfmt+0x1c5>
f01036b9:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
f01036bd:	75 10                	jne    f01036cf <vprintfmt+0x1d5>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01036bf:	0f be 06             	movsbl (%esi),%eax
f01036c2:	83 c6 01             	add    $0x1,%esi
f01036c5:	85 c0                	test   %eax,%eax
f01036c7:	0f 85 86 00 00 00    	jne    f0103753 <vprintfmt+0x259>
f01036cd:	eb 76                	jmp    f0103745 <vprintfmt+0x24b>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01036cf:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01036d3:	89 34 24             	mov    %esi,(%esp)
f01036d6:	e8 60 03 00 00       	call   f0103a3b <strnlen>
f01036db:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f01036de:	29 c2                	sub    %eax,%edx
f01036e0:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f01036e3:	85 d2                	test   %edx,%edx
f01036e5:	7e d8                	jle    f01036bf <vprintfmt+0x1c5>
					putch(padc, putdat);
f01036e7:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
f01036eb:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f01036ee:	89 d6                	mov    %edx,%esi
f01036f0:	89 7d d0             	mov    %edi,-0x30(%ebp)
f01036f3:	89 c7                	mov    %eax,%edi
f01036f5:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01036f9:	89 3c 24             	mov    %edi,(%esp)
f01036fc:	ff 55 08             	call   *0x8(%ebp)
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f01036ff:	83 ee 01             	sub    $0x1,%esi
f0103702:	75 f1                	jne    f01036f5 <vprintfmt+0x1fb>
f0103704:	89 75 e4             	mov    %esi,-0x1c(%ebp)
f0103707:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f010370a:	8b 7d d0             	mov    -0x30(%ebp),%edi
f010370d:	eb b0                	jmp    f01036bf <vprintfmt+0x1c5>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f010370f:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0103713:	74 18                	je     f010372d <vprintfmt+0x233>
f0103715:	8d 50 e0             	lea    -0x20(%eax),%edx
f0103718:	83 fa 5e             	cmp    $0x5e,%edx
f010371b:	76 10                	jbe    f010372d <vprintfmt+0x233>
					putch('?', putdat);
f010371d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103721:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0103728:	ff 55 08             	call   *0x8(%ebp)
f010372b:	eb 0a                	jmp    f0103737 <vprintfmt+0x23d>
				else
					putch(ch, putdat);
f010372d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103731:	89 04 24             	mov    %eax,(%esp)
f0103734:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0103737:	83 6d e4 01          	subl   $0x1,-0x1c(%ebp)
f010373b:	0f be 06             	movsbl (%esi),%eax
f010373e:	83 c6 01             	add    $0x1,%esi
f0103741:	85 c0                	test   %eax,%eax
f0103743:	75 0e                	jne    f0103753 <vprintfmt+0x259>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0103745:	8b 75 e0             	mov    -0x20(%ebp),%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0103748:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f010374c:	7f 16                	jg     f0103764 <vprintfmt+0x26a>
f010374e:	e9 ca fd ff ff       	jmp    f010351d <vprintfmt+0x23>
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f0103753:	85 ff                	test   %edi,%edi
f0103755:	78 b8                	js     f010370f <vprintfmt+0x215>
f0103757:	83 ef 01             	sub    $0x1,%edi
f010375a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103760:	79 ad                	jns    f010370f <vprintfmt+0x215>
f0103762:	eb e1                	jmp    f0103745 <vprintfmt+0x24b>
f0103764:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f0103767:	8b 7d 08             	mov    0x8(%ebp),%edi
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f010376a:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010376e:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f0103775:	ff d7                	call   *%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f0103777:	83 ee 01             	sub    $0x1,%esi
f010377a:	75 ee                	jne    f010376a <vprintfmt+0x270>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010377c:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010377f:	e9 99 fd ff ff       	jmp    f010351d <vprintfmt+0x23>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f0103784:	83 f9 01             	cmp    $0x1,%ecx
f0103787:	7e 10                	jle    f0103799 <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f0103789:	8b 45 14             	mov    0x14(%ebp),%eax
f010378c:	8d 50 08             	lea    0x8(%eax),%edx
f010378f:	89 55 14             	mov    %edx,0x14(%ebp)
f0103792:	8b 30                	mov    (%eax),%esi
f0103794:	8b 78 04             	mov    0x4(%eax),%edi
f0103797:	eb 26                	jmp    f01037bf <vprintfmt+0x2c5>
	else if (lflag)
f0103799:	85 c9                	test   %ecx,%ecx
f010379b:	74 12                	je     f01037af <vprintfmt+0x2b5>
		return va_arg(*ap, long);
f010379d:	8b 45 14             	mov    0x14(%ebp),%eax
f01037a0:	8d 50 04             	lea    0x4(%eax),%edx
f01037a3:	89 55 14             	mov    %edx,0x14(%ebp)
f01037a6:	8b 30                	mov    (%eax),%esi
f01037a8:	89 f7                	mov    %esi,%edi
f01037aa:	c1 ff 1f             	sar    $0x1f,%edi
f01037ad:	eb 10                	jmp    f01037bf <vprintfmt+0x2c5>
	else
		return va_arg(*ap, int);
f01037af:	8b 45 14             	mov    0x14(%ebp),%eax
f01037b2:	8d 50 04             	lea    0x4(%eax),%edx
f01037b5:	89 55 14             	mov    %edx,0x14(%ebp)
f01037b8:	8b 30                	mov    (%eax),%esi
f01037ba:	89 f7                	mov    %esi,%edi
f01037bc:	c1 ff 1f             	sar    $0x1f,%edi
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f01037bf:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f01037c4:	85 ff                	test   %edi,%edi
f01037c6:	0f 89 8c 00 00 00    	jns    f0103858 <vprintfmt+0x35e>
				putch('-', putdat);
f01037cc:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01037d0:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f01037d7:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f01037da:	f7 de                	neg    %esi
f01037dc:	83 d7 00             	adc    $0x0,%edi
f01037df:	f7 df                	neg    %edi
			}
			base = 10;
f01037e1:	b8 0a 00 00 00       	mov    $0xa,%eax
f01037e6:	eb 70                	jmp    f0103858 <vprintfmt+0x35e>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f01037e8:	89 ca                	mov    %ecx,%edx
f01037ea:	8d 45 14             	lea    0x14(%ebp),%eax
f01037ed:	e8 89 fc ff ff       	call   f010347b <getuint>
f01037f2:	89 c6                	mov    %eax,%esi
f01037f4:	89 d7                	mov    %edx,%edi
			base = 10;
f01037f6:	b8 0a 00 00 00       	mov    $0xa,%eax
			goto number;
f01037fb:	eb 5b                	jmp    f0103858 <vprintfmt+0x35e>
			// Replace this with your code.
			//putch('0', putdat);
			//putch('X', putdat);
			//putch('X', putdat);
			//break;
			num = getuint(&ap, lflag);
f01037fd:	89 ca                	mov    %ecx,%edx
f01037ff:	8d 45 14             	lea    0x14(%ebp),%eax
f0103802:	e8 74 fc ff ff       	call   f010347b <getuint>
f0103807:	89 c6                	mov    %eax,%esi
f0103809:	89 d7                	mov    %edx,%edi
			base = 8;
f010380b:	b8 08 00 00 00       	mov    $0x8,%eax
			goto number;
f0103810:	eb 46                	jmp    f0103858 <vprintfmt+0x35e>
		// pointer
		case 'p':
			putch('0', putdat);
f0103812:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103816:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f010381d:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f0103820:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103824:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f010382b:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f010382e:	8b 45 14             	mov    0x14(%ebp),%eax
f0103831:	8d 50 04             	lea    0x4(%eax),%edx
f0103834:	89 55 14             	mov    %edx,0x14(%ebp)
			goto number;
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f0103837:	8b 30                	mov    (%eax),%esi
f0103839:	bf 00 00 00 00       	mov    $0x0,%edi
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f010383e:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f0103843:	eb 13                	jmp    f0103858 <vprintfmt+0x35e>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f0103845:	89 ca                	mov    %ecx,%edx
f0103847:	8d 45 14             	lea    0x14(%ebp),%eax
f010384a:	e8 2c fc ff ff       	call   f010347b <getuint>
f010384f:	89 c6                	mov    %eax,%esi
f0103851:	89 d7                	mov    %edx,%edi
			base = 16;
f0103853:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f0103858:	0f be 55 d8          	movsbl -0x28(%ebp),%edx
f010385c:	89 54 24 10          	mov    %edx,0x10(%esp)
f0103860:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f0103863:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103867:	89 44 24 08          	mov    %eax,0x8(%esp)
f010386b:	89 34 24             	mov    %esi,(%esp)
f010386e:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0103872:	89 da                	mov    %ebx,%edx
f0103874:	8b 45 08             	mov    0x8(%ebp),%eax
f0103877:	e8 24 fb ff ff       	call   f01033a0 <printnum>
			break;
f010387c:	8b 75 e0             	mov    -0x20(%ebp),%esi
f010387f:	e9 99 fc ff ff       	jmp    f010351d <vprintfmt+0x23>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f0103884:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0103888:	89 14 24             	mov    %edx,(%esp)
f010388b:	ff 55 08             	call   *0x8(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010388e:	8b 75 e0             	mov    -0x20(%ebp),%esi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0103891:	e9 87 fc ff ff       	jmp    f010351d <vprintfmt+0x23>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0103896:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010389a:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f01038a1:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f01038a4:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
f01038a8:	0f 84 6f fc ff ff    	je     f010351d <vprintfmt+0x23>
f01038ae:	83 ee 01             	sub    $0x1,%esi
f01038b1:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
f01038b5:	75 f7                	jne    f01038ae <vprintfmt+0x3b4>
f01038b7:	e9 61 fc ff ff       	jmp    f010351d <vprintfmt+0x23>
				/* do nothing */;
			break;
		}
	}
}
f01038bc:	83 c4 4c             	add    $0x4c,%esp
f01038bf:	5b                   	pop    %ebx
f01038c0:	5e                   	pop    %esi
f01038c1:	5f                   	pop    %edi
f01038c2:	5d                   	pop    %ebp
f01038c3:	c3                   	ret    

f01038c4 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f01038c4:	55                   	push   %ebp
f01038c5:	89 e5                	mov    %esp,%ebp
f01038c7:	83 ec 28             	sub    $0x28,%esp
f01038ca:	8b 45 08             	mov    0x8(%ebp),%eax
f01038cd:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f01038d0:	89 45 ec             	mov    %eax,-0x14(%ebp)
f01038d3:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f01038d7:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f01038da:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f01038e1:	85 c0                	test   %eax,%eax
f01038e3:	74 30                	je     f0103915 <vsnprintf+0x51>
f01038e5:	85 d2                	test   %edx,%edx
f01038e7:	7e 2c                	jle    f0103915 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f01038e9:	8b 45 14             	mov    0x14(%ebp),%eax
f01038ec:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01038f0:	8b 45 10             	mov    0x10(%ebp),%eax
f01038f3:	89 44 24 08          	mov    %eax,0x8(%esp)
f01038f7:	8d 45 ec             	lea    -0x14(%ebp),%eax
f01038fa:	89 44 24 04          	mov    %eax,0x4(%esp)
f01038fe:	c7 04 24 b5 34 10 f0 	movl   $0xf01034b5,(%esp)
f0103905:	e8 f0 fb ff ff       	call   f01034fa <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f010390a:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010390d:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0103910:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0103913:	eb 05                	jmp    f010391a <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0103915:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f010391a:	c9                   	leave  
f010391b:	c3                   	ret    

f010391c <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010391c:	55                   	push   %ebp
f010391d:	89 e5                	mov    %esp,%ebp
f010391f:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0103922:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0103925:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0103929:	8b 45 10             	mov    0x10(%ebp),%eax
f010392c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103930:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103933:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103937:	8b 45 08             	mov    0x8(%ebp),%eax
f010393a:	89 04 24             	mov    %eax,(%esp)
f010393d:	e8 82 ff ff ff       	call   f01038c4 <vsnprintf>
	va_end(ap);

	return rc;
}
f0103942:	c9                   	leave  
f0103943:	c3                   	ret    
	...

f0103950 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f0103950:	55                   	push   %ebp
f0103951:	89 e5                	mov    %esp,%ebp
f0103953:	57                   	push   %edi
f0103954:	56                   	push   %esi
f0103955:	53                   	push   %ebx
f0103956:	83 ec 1c             	sub    $0x1c,%esp
f0103959:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f010395c:	85 c0                	test   %eax,%eax
f010395e:	74 10                	je     f0103970 <readline+0x20>
		cprintf("%s", prompt);
f0103960:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103964:	c7 04 24 04 4e 10 f0 	movl   $0xf0104e04,(%esp)
f010396b:	e8 da f6 ff ff       	call   f010304a <cprintf>

	i = 0;
	echoing = iscons(0);
f0103970:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f0103977:	e8 9e cc ff ff       	call   f010061a <iscons>
f010397c:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f010397e:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f0103983:	e8 81 cc ff ff       	call   f0100609 <getchar>
f0103988:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f010398a:	85 c0                	test   %eax,%eax
f010398c:	79 17                	jns    f01039a5 <readline+0x55>
			cprintf("read error: %e\n", c);
f010398e:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103992:	c7 04 24 bc 52 10 f0 	movl   $0xf01052bc,(%esp)
f0103999:	e8 ac f6 ff ff       	call   f010304a <cprintf>
			return NULL;
f010399e:	b8 00 00 00 00       	mov    $0x0,%eax
f01039a3:	eb 6d                	jmp    f0103a12 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f01039a5:	83 f8 08             	cmp    $0x8,%eax
f01039a8:	74 05                	je     f01039af <readline+0x5f>
f01039aa:	83 f8 7f             	cmp    $0x7f,%eax
f01039ad:	75 19                	jne    f01039c8 <readline+0x78>
f01039af:	85 f6                	test   %esi,%esi
f01039b1:	7e 15                	jle    f01039c8 <readline+0x78>
			if (echoing)
f01039b3:	85 ff                	test   %edi,%edi
f01039b5:	74 0c                	je     f01039c3 <readline+0x73>
				cputchar('\b');
f01039b7:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f01039be:	e8 36 cc ff ff       	call   f01005f9 <cputchar>
			i--;
f01039c3:	83 ee 01             	sub    $0x1,%esi
f01039c6:	eb bb                	jmp    f0103983 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f01039c8:	83 fb 1f             	cmp    $0x1f,%ebx
f01039cb:	7e 1f                	jle    f01039ec <readline+0x9c>
f01039cd:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f01039d3:	7f 17                	jg     f01039ec <readline+0x9c>
			if (echoing)
f01039d5:	85 ff                	test   %edi,%edi
f01039d7:	74 08                	je     f01039e1 <readline+0x91>
				cputchar(c);
f01039d9:	89 1c 24             	mov    %ebx,(%esp)
f01039dc:	e8 18 cc ff ff       	call   f01005f9 <cputchar>
			buf[i++] = c;
f01039e1:	88 9e 80 85 11 f0    	mov    %bl,-0xfee7a80(%esi)
f01039e7:	83 c6 01             	add    $0x1,%esi
f01039ea:	eb 97                	jmp    f0103983 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f01039ec:	83 fb 0a             	cmp    $0xa,%ebx
f01039ef:	74 05                	je     f01039f6 <readline+0xa6>
f01039f1:	83 fb 0d             	cmp    $0xd,%ebx
f01039f4:	75 8d                	jne    f0103983 <readline+0x33>
			if (echoing)
f01039f6:	85 ff                	test   %edi,%edi
f01039f8:	74 0c                	je     f0103a06 <readline+0xb6>
				cputchar('\n');
f01039fa:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0103a01:	e8 f3 cb ff ff       	call   f01005f9 <cputchar>
			buf[i] = 0;
f0103a06:	c6 86 80 85 11 f0 00 	movb   $0x0,-0xfee7a80(%esi)
			return buf;
f0103a0d:	b8 80 85 11 f0       	mov    $0xf0118580,%eax
		}
	}
}
f0103a12:	83 c4 1c             	add    $0x1c,%esp
f0103a15:	5b                   	pop    %ebx
f0103a16:	5e                   	pop    %esi
f0103a17:	5f                   	pop    %edi
f0103a18:	5d                   	pop    %ebp
f0103a19:	c3                   	ret    
f0103a1a:	00 00                	add    %al,(%eax)
f0103a1c:	00 00                	add    %al,(%eax)
	...

f0103a20 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0103a20:	55                   	push   %ebp
f0103a21:	89 e5                	mov    %esp,%ebp
f0103a23:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0103a26:	b8 00 00 00 00       	mov    $0x0,%eax
f0103a2b:	80 3a 00             	cmpb   $0x0,(%edx)
f0103a2e:	74 09                	je     f0103a39 <strlen+0x19>
		n++;
f0103a30:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f0103a33:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f0103a37:	75 f7                	jne    f0103a30 <strlen+0x10>
		n++;
	return n;
}
f0103a39:	5d                   	pop    %ebp
f0103a3a:	c3                   	ret    

f0103a3b <strnlen>:

int
strnlen(const char *s, size_t size)
{
f0103a3b:	55                   	push   %ebp
f0103a3c:	89 e5                	mov    %esp,%ebp
f0103a3e:	53                   	push   %ebx
f0103a3f:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103a42:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103a45:	b8 00 00 00 00       	mov    $0x0,%eax
f0103a4a:	85 c9                	test   %ecx,%ecx
f0103a4c:	74 1a                	je     f0103a68 <strnlen+0x2d>
f0103a4e:	80 3b 00             	cmpb   $0x0,(%ebx)
f0103a51:	74 15                	je     f0103a68 <strnlen+0x2d>
f0103a53:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
f0103a58:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f0103a5a:	39 ca                	cmp    %ecx,%edx
f0103a5c:	74 0a                	je     f0103a68 <strnlen+0x2d>
f0103a5e:	83 c2 01             	add    $0x1,%edx
f0103a61:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
f0103a66:	75 f0                	jne    f0103a58 <strnlen+0x1d>
		n++;
	return n;
}
f0103a68:	5b                   	pop    %ebx
f0103a69:	5d                   	pop    %ebp
f0103a6a:	c3                   	ret    

f0103a6b <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f0103a6b:	55                   	push   %ebp
f0103a6c:	89 e5                	mov    %esp,%ebp
f0103a6e:	53                   	push   %ebx
f0103a6f:	8b 45 08             	mov    0x8(%ebp),%eax
f0103a72:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f0103a75:	ba 00 00 00 00       	mov    $0x0,%edx
f0103a7a:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f0103a7e:	88 0c 10             	mov    %cl,(%eax,%edx,1)
f0103a81:	83 c2 01             	add    $0x1,%edx
f0103a84:	84 c9                	test   %cl,%cl
f0103a86:	75 f2                	jne    f0103a7a <strcpy+0xf>
		/* do nothing */;
	return ret;
}
f0103a88:	5b                   	pop    %ebx
f0103a89:	5d                   	pop    %ebp
f0103a8a:	c3                   	ret    

f0103a8b <strcat>:

char *
strcat(char *dst, const char *src)
{
f0103a8b:	55                   	push   %ebp
f0103a8c:	89 e5                	mov    %esp,%ebp
f0103a8e:	53                   	push   %ebx
f0103a8f:	83 ec 08             	sub    $0x8,%esp
f0103a92:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0103a95:	89 1c 24             	mov    %ebx,(%esp)
f0103a98:	e8 83 ff ff ff       	call   f0103a20 <strlen>
	strcpy(dst + len, src);
f0103a9d:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103aa0:	89 54 24 04          	mov    %edx,0x4(%esp)
f0103aa4:	01 d8                	add    %ebx,%eax
f0103aa6:	89 04 24             	mov    %eax,(%esp)
f0103aa9:	e8 bd ff ff ff       	call   f0103a6b <strcpy>
	return dst;
}
f0103aae:	89 d8                	mov    %ebx,%eax
f0103ab0:	83 c4 08             	add    $0x8,%esp
f0103ab3:	5b                   	pop    %ebx
f0103ab4:	5d                   	pop    %ebp
f0103ab5:	c3                   	ret    

f0103ab6 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0103ab6:	55                   	push   %ebp
f0103ab7:	89 e5                	mov    %esp,%ebp
f0103ab9:	56                   	push   %esi
f0103aba:	53                   	push   %ebx
f0103abb:	8b 45 08             	mov    0x8(%ebp),%eax
f0103abe:	8b 55 0c             	mov    0xc(%ebp),%edx
f0103ac1:	8b 75 10             	mov    0x10(%ebp),%esi
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103ac4:	85 f6                	test   %esi,%esi
f0103ac6:	74 18                	je     f0103ae0 <strncpy+0x2a>
f0103ac8:	b9 00 00 00 00       	mov    $0x0,%ecx
		*dst++ = *src;
f0103acd:	0f b6 1a             	movzbl (%edx),%ebx
f0103ad0:	88 1c 08             	mov    %bl,(%eax,%ecx,1)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0103ad3:	80 3a 01             	cmpb   $0x1,(%edx)
f0103ad6:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0103ad9:	83 c1 01             	add    $0x1,%ecx
f0103adc:	39 f1                	cmp    %esi,%ecx
f0103ade:	75 ed                	jne    f0103acd <strncpy+0x17>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0103ae0:	5b                   	pop    %ebx
f0103ae1:	5e                   	pop    %esi
f0103ae2:	5d                   	pop    %ebp
f0103ae3:	c3                   	ret    

f0103ae4 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0103ae4:	55                   	push   %ebp
f0103ae5:	89 e5                	mov    %esp,%ebp
f0103ae7:	57                   	push   %edi
f0103ae8:	56                   	push   %esi
f0103ae9:	53                   	push   %ebx
f0103aea:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103aed:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103af0:	8b 75 10             	mov    0x10(%ebp),%esi
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0103af3:	89 f8                	mov    %edi,%eax
f0103af5:	85 f6                	test   %esi,%esi
f0103af7:	74 2b                	je     f0103b24 <strlcpy+0x40>
		while (--size > 0 && *src != '\0')
f0103af9:	83 fe 01             	cmp    $0x1,%esi
f0103afc:	74 23                	je     f0103b21 <strlcpy+0x3d>
f0103afe:	0f b6 0b             	movzbl (%ebx),%ecx
f0103b01:	84 c9                	test   %cl,%cl
f0103b03:	74 1c                	je     f0103b21 <strlcpy+0x3d>
	}
	return ret;
}

size_t
strlcpy(char *dst, const char *src, size_t size)
f0103b05:	83 ee 02             	sub    $0x2,%esi
f0103b08:	ba 00 00 00 00       	mov    $0x0,%edx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f0103b0d:	88 08                	mov    %cl,(%eax)
f0103b0f:	83 c0 01             	add    $0x1,%eax
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0103b12:	39 f2                	cmp    %esi,%edx
f0103b14:	74 0b                	je     f0103b21 <strlcpy+0x3d>
f0103b16:	83 c2 01             	add    $0x1,%edx
f0103b19:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f0103b1d:	84 c9                	test   %cl,%cl
f0103b1f:	75 ec                	jne    f0103b0d <strlcpy+0x29>
			*dst++ = *src++;
		*dst = '\0';
f0103b21:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0103b24:	29 f8                	sub    %edi,%eax
}
f0103b26:	5b                   	pop    %ebx
f0103b27:	5e                   	pop    %esi
f0103b28:	5f                   	pop    %edi
f0103b29:	5d                   	pop    %ebp
f0103b2a:	c3                   	ret    

f0103b2b <strcmp>:

int
strcmp(const char *p, const char *q)
{
f0103b2b:	55                   	push   %ebp
f0103b2c:	89 e5                	mov    %esp,%ebp
f0103b2e:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103b31:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f0103b34:	0f b6 01             	movzbl (%ecx),%eax
f0103b37:	84 c0                	test   %al,%al
f0103b39:	74 16                	je     f0103b51 <strcmp+0x26>
f0103b3b:	3a 02                	cmp    (%edx),%al
f0103b3d:	75 12                	jne    f0103b51 <strcmp+0x26>
		p++, q++;
f0103b3f:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f0103b42:	0f b6 41 01          	movzbl 0x1(%ecx),%eax
f0103b46:	84 c0                	test   %al,%al
f0103b48:	74 07                	je     f0103b51 <strcmp+0x26>
f0103b4a:	83 c1 01             	add    $0x1,%ecx
f0103b4d:	3a 02                	cmp    (%edx),%al
f0103b4f:	74 ee                	je     f0103b3f <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f0103b51:	0f b6 c0             	movzbl %al,%eax
f0103b54:	0f b6 12             	movzbl (%edx),%edx
f0103b57:	29 d0                	sub    %edx,%eax
}
f0103b59:	5d                   	pop    %ebp
f0103b5a:	c3                   	ret    

f0103b5b <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f0103b5b:	55                   	push   %ebp
f0103b5c:	89 e5                	mov    %esp,%ebp
f0103b5e:	53                   	push   %ebx
f0103b5f:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0103b62:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103b65:	8b 55 10             	mov    0x10(%ebp),%edx
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f0103b68:	b8 00 00 00 00       	mov    $0x0,%eax
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0103b6d:	85 d2                	test   %edx,%edx
f0103b6f:	74 28                	je     f0103b99 <strncmp+0x3e>
f0103b71:	0f b6 01             	movzbl (%ecx),%eax
f0103b74:	84 c0                	test   %al,%al
f0103b76:	74 24                	je     f0103b9c <strncmp+0x41>
f0103b78:	3a 03                	cmp    (%ebx),%al
f0103b7a:	75 20                	jne    f0103b9c <strncmp+0x41>
f0103b7c:	83 ea 01             	sub    $0x1,%edx
f0103b7f:	74 13                	je     f0103b94 <strncmp+0x39>
		n--, p++, q++;
f0103b81:	83 c1 01             	add    $0x1,%ecx
f0103b84:	83 c3 01             	add    $0x1,%ebx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f0103b87:	0f b6 01             	movzbl (%ecx),%eax
f0103b8a:	84 c0                	test   %al,%al
f0103b8c:	74 0e                	je     f0103b9c <strncmp+0x41>
f0103b8e:	3a 03                	cmp    (%ebx),%al
f0103b90:	74 ea                	je     f0103b7c <strncmp+0x21>
f0103b92:	eb 08                	jmp    f0103b9c <strncmp+0x41>
		n--, p++, q++;
	if (n == 0)
		return 0;
f0103b94:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0103b99:	5b                   	pop    %ebx
f0103b9a:	5d                   	pop    %ebp
f0103b9b:	c3                   	ret    
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f0103b9c:	0f b6 01             	movzbl (%ecx),%eax
f0103b9f:	0f b6 13             	movzbl (%ebx),%edx
f0103ba2:	29 d0                	sub    %edx,%eax
f0103ba4:	eb f3                	jmp    f0103b99 <strncmp+0x3e>

f0103ba6 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0103ba6:	55                   	push   %ebp
f0103ba7:	89 e5                	mov    %esp,%ebp
f0103ba9:	8b 45 08             	mov    0x8(%ebp),%eax
f0103bac:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103bb0:	0f b6 10             	movzbl (%eax),%edx
f0103bb3:	84 d2                	test   %dl,%dl
f0103bb5:	74 1c                	je     f0103bd3 <strchr+0x2d>
		if (*s == c)
f0103bb7:	38 ca                	cmp    %cl,%dl
f0103bb9:	75 09                	jne    f0103bc4 <strchr+0x1e>
f0103bbb:	eb 1b                	jmp    f0103bd8 <strchr+0x32>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0103bbd:	83 c0 01             	add    $0x1,%eax
		if (*s == c)
f0103bc0:	38 ca                	cmp    %cl,%dl
f0103bc2:	74 14                	je     f0103bd8 <strchr+0x32>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0103bc4:	0f b6 50 01          	movzbl 0x1(%eax),%edx
f0103bc8:	84 d2                	test   %dl,%dl
f0103bca:	75 f1                	jne    f0103bbd <strchr+0x17>
		if (*s == c)
			return (char *) s;
	return 0;
f0103bcc:	b8 00 00 00 00       	mov    $0x0,%eax
f0103bd1:	eb 05                	jmp    f0103bd8 <strchr+0x32>
f0103bd3:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103bd8:	5d                   	pop    %ebp
f0103bd9:	c3                   	ret    

f0103bda <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f0103bda:	55                   	push   %ebp
f0103bdb:	89 e5                	mov    %esp,%ebp
f0103bdd:	8b 45 08             	mov    0x8(%ebp),%eax
f0103be0:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0103be4:	0f b6 10             	movzbl (%eax),%edx
f0103be7:	84 d2                	test   %dl,%dl
f0103be9:	74 14                	je     f0103bff <strfind+0x25>
		if (*s == c)
f0103beb:	38 ca                	cmp    %cl,%dl
f0103bed:	75 06                	jne    f0103bf5 <strfind+0x1b>
f0103bef:	eb 0e                	jmp    f0103bff <strfind+0x25>
f0103bf1:	38 ca                	cmp    %cl,%dl
f0103bf3:	74 0a                	je     f0103bff <strfind+0x25>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f0103bf5:	83 c0 01             	add    $0x1,%eax
f0103bf8:	0f b6 10             	movzbl (%eax),%edx
f0103bfb:	84 d2                	test   %dl,%dl
f0103bfd:	75 f2                	jne    f0103bf1 <strfind+0x17>
		if (*s == c)
			break;
	return (char *) s;
}
f0103bff:	5d                   	pop    %ebp
f0103c00:	c3                   	ret    

f0103c01 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0103c01:	55                   	push   %ebp
f0103c02:	89 e5                	mov    %esp,%ebp
f0103c04:	83 ec 0c             	sub    $0xc,%esp
f0103c07:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0103c0a:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0103c0d:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0103c10:	8b 7d 08             	mov    0x8(%ebp),%edi
f0103c13:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103c16:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0103c19:	85 c9                	test   %ecx,%ecx
f0103c1b:	74 30                	je     f0103c4d <memset+0x4c>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f0103c1d:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0103c23:	75 25                	jne    f0103c4a <memset+0x49>
f0103c25:	f6 c1 03             	test   $0x3,%cl
f0103c28:	75 20                	jne    f0103c4a <memset+0x49>
		c &= 0xFF;
f0103c2a:	0f b6 d0             	movzbl %al,%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f0103c2d:	89 d3                	mov    %edx,%ebx
f0103c2f:	c1 e3 08             	shl    $0x8,%ebx
f0103c32:	89 d6                	mov    %edx,%esi
f0103c34:	c1 e6 18             	shl    $0x18,%esi
f0103c37:	89 d0                	mov    %edx,%eax
f0103c39:	c1 e0 10             	shl    $0x10,%eax
f0103c3c:	09 f0                	or     %esi,%eax
f0103c3e:	09 d0                	or     %edx,%eax
f0103c40:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f0103c42:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f0103c45:	fc                   	cld    
f0103c46:	f3 ab                	rep stos %eax,%es:(%edi)
f0103c48:	eb 03                	jmp    f0103c4d <memset+0x4c>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f0103c4a:	fc                   	cld    
f0103c4b:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f0103c4d:	89 f8                	mov    %edi,%eax
f0103c4f:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0103c52:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0103c55:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0103c58:	89 ec                	mov    %ebp,%esp
f0103c5a:	5d                   	pop    %ebp
f0103c5b:	c3                   	ret    

f0103c5c <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f0103c5c:	55                   	push   %ebp
f0103c5d:	89 e5                	mov    %esp,%ebp
f0103c5f:	83 ec 08             	sub    $0x8,%esp
f0103c62:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0103c65:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0103c68:	8b 45 08             	mov    0x8(%ebp),%eax
f0103c6b:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103c6e:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f0103c71:	39 c6                	cmp    %eax,%esi
f0103c73:	73 36                	jae    f0103cab <memmove+0x4f>
f0103c75:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f0103c78:	39 d0                	cmp    %edx,%eax
f0103c7a:	73 2f                	jae    f0103cab <memmove+0x4f>
		s += n;
		d += n;
f0103c7c:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103c7f:	f6 c2 03             	test   $0x3,%dl
f0103c82:	75 1b                	jne    f0103c9f <memmove+0x43>
f0103c84:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0103c8a:	75 13                	jne    f0103c9f <memmove+0x43>
f0103c8c:	f6 c1 03             	test   $0x3,%cl
f0103c8f:	75 0e                	jne    f0103c9f <memmove+0x43>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0103c91:	83 ef 04             	sub    $0x4,%edi
f0103c94:	8d 72 fc             	lea    -0x4(%edx),%esi
f0103c97:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f0103c9a:	fd                   	std    
f0103c9b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103c9d:	eb 09                	jmp    f0103ca8 <memmove+0x4c>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0103c9f:	83 ef 01             	sub    $0x1,%edi
f0103ca2:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0103ca5:	fd                   	std    
f0103ca6:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0103ca8:	fc                   	cld    
f0103ca9:	eb 20                	jmp    f0103ccb <memmove+0x6f>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0103cab:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0103cb1:	75 13                	jne    f0103cc6 <memmove+0x6a>
f0103cb3:	a8 03                	test   $0x3,%al
f0103cb5:	75 0f                	jne    f0103cc6 <memmove+0x6a>
f0103cb7:	f6 c1 03             	test   $0x3,%cl
f0103cba:	75 0a                	jne    f0103cc6 <memmove+0x6a>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0103cbc:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f0103cbf:	89 c7                	mov    %eax,%edi
f0103cc1:	fc                   	cld    
f0103cc2:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0103cc4:	eb 05                	jmp    f0103ccb <memmove+0x6f>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0103cc6:	89 c7                	mov    %eax,%edi
f0103cc8:	fc                   	cld    
f0103cc9:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0103ccb:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0103cce:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0103cd1:	89 ec                	mov    %ebp,%esp
f0103cd3:	5d                   	pop    %ebp
f0103cd4:	c3                   	ret    

f0103cd5 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0103cd5:	55                   	push   %ebp
f0103cd6:	89 e5                	mov    %esp,%ebp
f0103cd8:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0103cdb:	8b 45 10             	mov    0x10(%ebp),%eax
f0103cde:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103ce2:	8b 45 0c             	mov    0xc(%ebp),%eax
f0103ce5:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103ce9:	8b 45 08             	mov    0x8(%ebp),%eax
f0103cec:	89 04 24             	mov    %eax,(%esp)
f0103cef:	e8 68 ff ff ff       	call   f0103c5c <memmove>
}
f0103cf4:	c9                   	leave  
f0103cf5:	c3                   	ret    

f0103cf6 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0103cf6:	55                   	push   %ebp
f0103cf7:	89 e5                	mov    %esp,%ebp
f0103cf9:	57                   	push   %edi
f0103cfa:	56                   	push   %esi
f0103cfb:	53                   	push   %ebx
f0103cfc:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0103cff:	8b 75 0c             	mov    0xc(%ebp),%esi
f0103d02:	8b 7d 10             	mov    0x10(%ebp),%edi
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0103d05:	b8 00 00 00 00       	mov    $0x0,%eax
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103d0a:	85 ff                	test   %edi,%edi
f0103d0c:	74 37                	je     f0103d45 <memcmp+0x4f>
		if (*s1 != *s2)
f0103d0e:	0f b6 03             	movzbl (%ebx),%eax
f0103d11:	0f b6 0e             	movzbl (%esi),%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103d14:	83 ef 01             	sub    $0x1,%edi
f0103d17:	ba 00 00 00 00       	mov    $0x0,%edx
		if (*s1 != *s2)
f0103d1c:	38 c8                	cmp    %cl,%al
f0103d1e:	74 1c                	je     f0103d3c <memcmp+0x46>
f0103d20:	eb 10                	jmp    f0103d32 <memcmp+0x3c>
f0103d22:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
f0103d27:	83 c2 01             	add    $0x1,%edx
f0103d2a:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
f0103d2e:	38 c8                	cmp    %cl,%al
f0103d30:	74 0a                	je     f0103d3c <memcmp+0x46>
			return (int) *s1 - (int) *s2;
f0103d32:	0f b6 c0             	movzbl %al,%eax
f0103d35:	0f b6 c9             	movzbl %cl,%ecx
f0103d38:	29 c8                	sub    %ecx,%eax
f0103d3a:	eb 09                	jmp    f0103d45 <memcmp+0x4f>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0103d3c:	39 fa                	cmp    %edi,%edx
f0103d3e:	75 e2                	jne    f0103d22 <memcmp+0x2c>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0103d40:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0103d45:	5b                   	pop    %ebx
f0103d46:	5e                   	pop    %esi
f0103d47:	5f                   	pop    %edi
f0103d48:	5d                   	pop    %ebp
f0103d49:	c3                   	ret    

f0103d4a <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0103d4a:	55                   	push   %ebp
f0103d4b:	89 e5                	mov    %esp,%ebp
f0103d4d:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0103d50:	89 c2                	mov    %eax,%edx
f0103d52:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0103d55:	39 d0                	cmp    %edx,%eax
f0103d57:	73 19                	jae    f0103d72 <memfind+0x28>
		if (*(const unsigned char *) s == (unsigned char) c)
f0103d59:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
f0103d5d:	38 08                	cmp    %cl,(%eax)
f0103d5f:	75 06                	jne    f0103d67 <memfind+0x1d>
f0103d61:	eb 0f                	jmp    f0103d72 <memfind+0x28>
f0103d63:	38 08                	cmp    %cl,(%eax)
f0103d65:	74 0b                	je     f0103d72 <memfind+0x28>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0103d67:	83 c0 01             	add    $0x1,%eax
f0103d6a:	39 d0                	cmp    %edx,%eax
f0103d6c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0103d70:	75 f1                	jne    f0103d63 <memfind+0x19>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0103d72:	5d                   	pop    %ebp
f0103d73:	c3                   	ret    

f0103d74 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0103d74:	55                   	push   %ebp
f0103d75:	89 e5                	mov    %esp,%ebp
f0103d77:	57                   	push   %edi
f0103d78:	56                   	push   %esi
f0103d79:	53                   	push   %ebx
f0103d7a:	8b 55 08             	mov    0x8(%ebp),%edx
f0103d7d:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103d80:	0f b6 02             	movzbl (%edx),%eax
f0103d83:	3c 20                	cmp    $0x20,%al
f0103d85:	74 04                	je     f0103d8b <strtol+0x17>
f0103d87:	3c 09                	cmp    $0x9,%al
f0103d89:	75 0e                	jne    f0103d99 <strtol+0x25>
		s++;
f0103d8b:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0103d8e:	0f b6 02             	movzbl (%edx),%eax
f0103d91:	3c 20                	cmp    $0x20,%al
f0103d93:	74 f6                	je     f0103d8b <strtol+0x17>
f0103d95:	3c 09                	cmp    $0x9,%al
f0103d97:	74 f2                	je     f0103d8b <strtol+0x17>
		s++;

	// plus/minus sign
	if (*s == '+')
f0103d99:	3c 2b                	cmp    $0x2b,%al
f0103d9b:	75 0a                	jne    f0103da7 <strtol+0x33>
		s++;
f0103d9d:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0103da0:	bf 00 00 00 00       	mov    $0x0,%edi
f0103da5:	eb 10                	jmp    f0103db7 <strtol+0x43>
f0103da7:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0103dac:	3c 2d                	cmp    $0x2d,%al
f0103dae:	75 07                	jne    f0103db7 <strtol+0x43>
		s++, neg = 1;
f0103db0:	83 c2 01             	add    $0x1,%edx
f0103db3:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0103db7:	85 db                	test   %ebx,%ebx
f0103db9:	0f 94 c0             	sete   %al
f0103dbc:	74 05                	je     f0103dc3 <strtol+0x4f>
f0103dbe:	83 fb 10             	cmp    $0x10,%ebx
f0103dc1:	75 15                	jne    f0103dd8 <strtol+0x64>
f0103dc3:	80 3a 30             	cmpb   $0x30,(%edx)
f0103dc6:	75 10                	jne    f0103dd8 <strtol+0x64>
f0103dc8:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0103dcc:	75 0a                	jne    f0103dd8 <strtol+0x64>
		s += 2, base = 16;
f0103dce:	83 c2 02             	add    $0x2,%edx
f0103dd1:	bb 10 00 00 00       	mov    $0x10,%ebx
f0103dd6:	eb 13                	jmp    f0103deb <strtol+0x77>
	else if (base == 0 && s[0] == '0')
f0103dd8:	84 c0                	test   %al,%al
f0103dda:	74 0f                	je     f0103deb <strtol+0x77>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0103ddc:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0103de1:	80 3a 30             	cmpb   $0x30,(%edx)
f0103de4:	75 05                	jne    f0103deb <strtol+0x77>
		s++, base = 8;
f0103de6:	83 c2 01             	add    $0x1,%edx
f0103de9:	b3 08                	mov    $0x8,%bl
	else if (base == 0)
		base = 10;
f0103deb:	b8 00 00 00 00       	mov    $0x0,%eax
f0103df0:	89 de                	mov    %ebx,%esi

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0103df2:	0f b6 0a             	movzbl (%edx),%ecx
f0103df5:	8d 59 d0             	lea    -0x30(%ecx),%ebx
f0103df8:	80 fb 09             	cmp    $0x9,%bl
f0103dfb:	77 08                	ja     f0103e05 <strtol+0x91>
			dig = *s - '0';
f0103dfd:	0f be c9             	movsbl %cl,%ecx
f0103e00:	83 e9 30             	sub    $0x30,%ecx
f0103e03:	eb 1e                	jmp    f0103e23 <strtol+0xaf>
		else if (*s >= 'a' && *s <= 'z')
f0103e05:	8d 59 9f             	lea    -0x61(%ecx),%ebx
f0103e08:	80 fb 19             	cmp    $0x19,%bl
f0103e0b:	77 08                	ja     f0103e15 <strtol+0xa1>
			dig = *s - 'a' + 10;
f0103e0d:	0f be c9             	movsbl %cl,%ecx
f0103e10:	83 e9 57             	sub    $0x57,%ecx
f0103e13:	eb 0e                	jmp    f0103e23 <strtol+0xaf>
		else if (*s >= 'A' && *s <= 'Z')
f0103e15:	8d 59 bf             	lea    -0x41(%ecx),%ebx
f0103e18:	80 fb 19             	cmp    $0x19,%bl
f0103e1b:	77 14                	ja     f0103e31 <strtol+0xbd>
			dig = *s - 'A' + 10;
f0103e1d:	0f be c9             	movsbl %cl,%ecx
f0103e20:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0103e23:	39 f1                	cmp    %esi,%ecx
f0103e25:	7d 0e                	jge    f0103e35 <strtol+0xc1>
			break;
		s++, val = (val * base) + dig;
f0103e27:	83 c2 01             	add    $0x1,%edx
f0103e2a:	0f af c6             	imul   %esi,%eax
f0103e2d:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
f0103e2f:	eb c1                	jmp    f0103df2 <strtol+0x7e>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
f0103e31:	89 c1                	mov    %eax,%ecx
f0103e33:	eb 02                	jmp    f0103e37 <strtol+0xc3>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0103e35:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
f0103e37:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0103e3b:	74 05                	je     f0103e42 <strtol+0xce>
		*endptr = (char *) s;
f0103e3d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0103e40:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
f0103e42:	89 ca                	mov    %ecx,%edx
f0103e44:	f7 da                	neg    %edx
f0103e46:	85 ff                	test   %edi,%edi
f0103e48:	0f 45 c2             	cmovne %edx,%eax
}
f0103e4b:	5b                   	pop    %ebx
f0103e4c:	5e                   	pop    %esi
f0103e4d:	5f                   	pop    %edi
f0103e4e:	5d                   	pop    %ebp
f0103e4f:	c3                   	ret    

f0103e50 <__udivdi3>:
f0103e50:	83 ec 1c             	sub    $0x1c,%esp
f0103e53:	89 7c 24 14          	mov    %edi,0x14(%esp)
f0103e57:	8b 7c 24 2c          	mov    0x2c(%esp),%edi
f0103e5b:	8b 44 24 20          	mov    0x20(%esp),%eax
f0103e5f:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0103e63:	89 74 24 10          	mov    %esi,0x10(%esp)
f0103e67:	8b 74 24 24          	mov    0x24(%esp),%esi
f0103e6b:	85 ff                	test   %edi,%edi
f0103e6d:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f0103e71:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103e75:	89 cd                	mov    %ecx,%ebp
f0103e77:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103e7b:	75 33                	jne    f0103eb0 <__udivdi3+0x60>
f0103e7d:	39 f1                	cmp    %esi,%ecx
f0103e7f:	77 57                	ja     f0103ed8 <__udivdi3+0x88>
f0103e81:	85 c9                	test   %ecx,%ecx
f0103e83:	75 0b                	jne    f0103e90 <__udivdi3+0x40>
f0103e85:	b8 01 00 00 00       	mov    $0x1,%eax
f0103e8a:	31 d2                	xor    %edx,%edx
f0103e8c:	f7 f1                	div    %ecx
f0103e8e:	89 c1                	mov    %eax,%ecx
f0103e90:	89 f0                	mov    %esi,%eax
f0103e92:	31 d2                	xor    %edx,%edx
f0103e94:	f7 f1                	div    %ecx
f0103e96:	89 c6                	mov    %eax,%esi
f0103e98:	8b 44 24 04          	mov    0x4(%esp),%eax
f0103e9c:	f7 f1                	div    %ecx
f0103e9e:	89 f2                	mov    %esi,%edx
f0103ea0:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103ea4:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103ea8:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103eac:	83 c4 1c             	add    $0x1c,%esp
f0103eaf:	c3                   	ret    
f0103eb0:	31 d2                	xor    %edx,%edx
f0103eb2:	31 c0                	xor    %eax,%eax
f0103eb4:	39 f7                	cmp    %esi,%edi
f0103eb6:	77 e8                	ja     f0103ea0 <__udivdi3+0x50>
f0103eb8:	0f bd cf             	bsr    %edi,%ecx
f0103ebb:	83 f1 1f             	xor    $0x1f,%ecx
f0103ebe:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0103ec2:	75 2c                	jne    f0103ef0 <__udivdi3+0xa0>
f0103ec4:	3b 6c 24 08          	cmp    0x8(%esp),%ebp
f0103ec8:	76 04                	jbe    f0103ece <__udivdi3+0x7e>
f0103eca:	39 f7                	cmp    %esi,%edi
f0103ecc:	73 d2                	jae    f0103ea0 <__udivdi3+0x50>
f0103ece:	31 d2                	xor    %edx,%edx
f0103ed0:	b8 01 00 00 00       	mov    $0x1,%eax
f0103ed5:	eb c9                	jmp    f0103ea0 <__udivdi3+0x50>
f0103ed7:	90                   	nop
f0103ed8:	89 f2                	mov    %esi,%edx
f0103eda:	f7 f1                	div    %ecx
f0103edc:	31 d2                	xor    %edx,%edx
f0103ede:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103ee2:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103ee6:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103eea:	83 c4 1c             	add    $0x1c,%esp
f0103eed:	c3                   	ret    
f0103eee:	66 90                	xchg   %ax,%ax
f0103ef0:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103ef5:	b8 20 00 00 00       	mov    $0x20,%eax
f0103efa:	89 ea                	mov    %ebp,%edx
f0103efc:	2b 44 24 04          	sub    0x4(%esp),%eax
f0103f00:	d3 e7                	shl    %cl,%edi
f0103f02:	89 c1                	mov    %eax,%ecx
f0103f04:	d3 ea                	shr    %cl,%edx
f0103f06:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103f0b:	09 fa                	or     %edi,%edx
f0103f0d:	89 f7                	mov    %esi,%edi
f0103f0f:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0103f13:	89 f2                	mov    %esi,%edx
f0103f15:	8b 74 24 08          	mov    0x8(%esp),%esi
f0103f19:	d3 e5                	shl    %cl,%ebp
f0103f1b:	89 c1                	mov    %eax,%ecx
f0103f1d:	d3 ef                	shr    %cl,%edi
f0103f1f:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103f24:	d3 e2                	shl    %cl,%edx
f0103f26:	89 c1                	mov    %eax,%ecx
f0103f28:	d3 ee                	shr    %cl,%esi
f0103f2a:	09 d6                	or     %edx,%esi
f0103f2c:	89 fa                	mov    %edi,%edx
f0103f2e:	89 f0                	mov    %esi,%eax
f0103f30:	f7 74 24 0c          	divl   0xc(%esp)
f0103f34:	89 d7                	mov    %edx,%edi
f0103f36:	89 c6                	mov    %eax,%esi
f0103f38:	f7 e5                	mul    %ebp
f0103f3a:	39 d7                	cmp    %edx,%edi
f0103f3c:	72 22                	jb     f0103f60 <__udivdi3+0x110>
f0103f3e:	8b 6c 24 08          	mov    0x8(%esp),%ebp
f0103f42:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0103f47:	d3 e5                	shl    %cl,%ebp
f0103f49:	39 c5                	cmp    %eax,%ebp
f0103f4b:	73 04                	jae    f0103f51 <__udivdi3+0x101>
f0103f4d:	39 d7                	cmp    %edx,%edi
f0103f4f:	74 0f                	je     f0103f60 <__udivdi3+0x110>
f0103f51:	89 f0                	mov    %esi,%eax
f0103f53:	31 d2                	xor    %edx,%edx
f0103f55:	e9 46 ff ff ff       	jmp    f0103ea0 <__udivdi3+0x50>
f0103f5a:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0103f60:	8d 46 ff             	lea    -0x1(%esi),%eax
f0103f63:	31 d2                	xor    %edx,%edx
f0103f65:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103f69:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103f6d:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103f71:	83 c4 1c             	add    $0x1c,%esp
f0103f74:	c3                   	ret    
	...

f0103f80 <__umoddi3>:
f0103f80:	83 ec 1c             	sub    $0x1c,%esp
f0103f83:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f0103f87:	8b 6c 24 2c          	mov    0x2c(%esp),%ebp
f0103f8b:	8b 44 24 20          	mov    0x20(%esp),%eax
f0103f8f:	89 74 24 10          	mov    %esi,0x10(%esp)
f0103f93:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0103f97:	8b 74 24 24          	mov    0x24(%esp),%esi
f0103f9b:	85 ed                	test   %ebp,%ebp
f0103f9d:	89 7c 24 14          	mov    %edi,0x14(%esp)
f0103fa1:	89 44 24 08          	mov    %eax,0x8(%esp)
f0103fa5:	89 cf                	mov    %ecx,%edi
f0103fa7:	89 04 24             	mov    %eax,(%esp)
f0103faa:	89 f2                	mov    %esi,%edx
f0103fac:	75 1a                	jne    f0103fc8 <__umoddi3+0x48>
f0103fae:	39 f1                	cmp    %esi,%ecx
f0103fb0:	76 4e                	jbe    f0104000 <__umoddi3+0x80>
f0103fb2:	f7 f1                	div    %ecx
f0103fb4:	89 d0                	mov    %edx,%eax
f0103fb6:	31 d2                	xor    %edx,%edx
f0103fb8:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103fbc:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103fc0:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103fc4:	83 c4 1c             	add    $0x1c,%esp
f0103fc7:	c3                   	ret    
f0103fc8:	39 f5                	cmp    %esi,%ebp
f0103fca:	77 54                	ja     f0104020 <__umoddi3+0xa0>
f0103fcc:	0f bd c5             	bsr    %ebp,%eax
f0103fcf:	83 f0 1f             	xor    $0x1f,%eax
f0103fd2:	89 44 24 04          	mov    %eax,0x4(%esp)
f0103fd6:	75 60                	jne    f0104038 <__umoddi3+0xb8>
f0103fd8:	3b 0c 24             	cmp    (%esp),%ecx
f0103fdb:	0f 87 07 01 00 00    	ja     f01040e8 <__umoddi3+0x168>
f0103fe1:	89 f2                	mov    %esi,%edx
f0103fe3:	8b 34 24             	mov    (%esp),%esi
f0103fe6:	29 ce                	sub    %ecx,%esi
f0103fe8:	19 ea                	sbb    %ebp,%edx
f0103fea:	89 34 24             	mov    %esi,(%esp)
f0103fed:	8b 04 24             	mov    (%esp),%eax
f0103ff0:	8b 74 24 10          	mov    0x10(%esp),%esi
f0103ff4:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0103ff8:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0103ffc:	83 c4 1c             	add    $0x1c,%esp
f0103fff:	c3                   	ret    
f0104000:	85 c9                	test   %ecx,%ecx
f0104002:	75 0b                	jne    f010400f <__umoddi3+0x8f>
f0104004:	b8 01 00 00 00       	mov    $0x1,%eax
f0104009:	31 d2                	xor    %edx,%edx
f010400b:	f7 f1                	div    %ecx
f010400d:	89 c1                	mov    %eax,%ecx
f010400f:	89 f0                	mov    %esi,%eax
f0104011:	31 d2                	xor    %edx,%edx
f0104013:	f7 f1                	div    %ecx
f0104015:	8b 04 24             	mov    (%esp),%eax
f0104018:	f7 f1                	div    %ecx
f010401a:	eb 98                	jmp    f0103fb4 <__umoddi3+0x34>
f010401c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0104020:	89 f2                	mov    %esi,%edx
f0104022:	8b 74 24 10          	mov    0x10(%esp),%esi
f0104026:	8b 7c 24 14          	mov    0x14(%esp),%edi
f010402a:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f010402e:	83 c4 1c             	add    $0x1c,%esp
f0104031:	c3                   	ret    
f0104032:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0104038:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f010403d:	89 e8                	mov    %ebp,%eax
f010403f:	bd 20 00 00 00       	mov    $0x20,%ebp
f0104044:	2b 6c 24 04          	sub    0x4(%esp),%ebp
f0104048:	89 fa                	mov    %edi,%edx
f010404a:	d3 e0                	shl    %cl,%eax
f010404c:	89 e9                	mov    %ebp,%ecx
f010404e:	d3 ea                	shr    %cl,%edx
f0104050:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0104055:	09 c2                	or     %eax,%edx
f0104057:	8b 44 24 08          	mov    0x8(%esp),%eax
f010405b:	89 14 24             	mov    %edx,(%esp)
f010405e:	89 f2                	mov    %esi,%edx
f0104060:	d3 e7                	shl    %cl,%edi
f0104062:	89 e9                	mov    %ebp,%ecx
f0104064:	d3 ea                	shr    %cl,%edx
f0104066:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f010406b:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f010406f:	d3 e6                	shl    %cl,%esi
f0104071:	89 e9                	mov    %ebp,%ecx
f0104073:	d3 e8                	shr    %cl,%eax
f0104075:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f010407a:	09 f0                	or     %esi,%eax
f010407c:	8b 74 24 08          	mov    0x8(%esp),%esi
f0104080:	f7 34 24             	divl   (%esp)
f0104083:	d3 e6                	shl    %cl,%esi
f0104085:	89 74 24 08          	mov    %esi,0x8(%esp)
f0104089:	89 d6                	mov    %edx,%esi
f010408b:	f7 e7                	mul    %edi
f010408d:	39 d6                	cmp    %edx,%esi
f010408f:	89 c1                	mov    %eax,%ecx
f0104091:	89 d7                	mov    %edx,%edi
f0104093:	72 3f                	jb     f01040d4 <__umoddi3+0x154>
f0104095:	39 44 24 08          	cmp    %eax,0x8(%esp)
f0104099:	72 35                	jb     f01040d0 <__umoddi3+0x150>
f010409b:	8b 44 24 08          	mov    0x8(%esp),%eax
f010409f:	29 c8                	sub    %ecx,%eax
f01040a1:	19 fe                	sbb    %edi,%esi
f01040a3:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f01040a8:	89 f2                	mov    %esi,%edx
f01040aa:	d3 e8                	shr    %cl,%eax
f01040ac:	89 e9                	mov    %ebp,%ecx
f01040ae:	d3 e2                	shl    %cl,%edx
f01040b0:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f01040b5:	09 d0                	or     %edx,%eax
f01040b7:	89 f2                	mov    %esi,%edx
f01040b9:	d3 ea                	shr    %cl,%edx
f01040bb:	8b 74 24 10          	mov    0x10(%esp),%esi
f01040bf:	8b 7c 24 14          	mov    0x14(%esp),%edi
f01040c3:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f01040c7:	83 c4 1c             	add    $0x1c,%esp
f01040ca:	c3                   	ret    
f01040cb:	90                   	nop
f01040cc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01040d0:	39 d6                	cmp    %edx,%esi
f01040d2:	75 c7                	jne    f010409b <__umoddi3+0x11b>
f01040d4:	89 d7                	mov    %edx,%edi
f01040d6:	89 c1                	mov    %eax,%ecx
f01040d8:	2b 4c 24 0c          	sub    0xc(%esp),%ecx
f01040dc:	1b 3c 24             	sbb    (%esp),%edi
f01040df:	eb ba                	jmp    f010409b <__umoddi3+0x11b>
f01040e1:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f01040e8:	39 f5                	cmp    %esi,%ebp
f01040ea:	0f 82 f1 fe ff ff    	jb     f0103fe1 <__umoddi3+0x61>
f01040f0:	e9 f8 fe ff ff       	jmp    f0103fed <__umoddi3+0x6d>
