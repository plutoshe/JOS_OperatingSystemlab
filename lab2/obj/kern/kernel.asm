
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
f0100046:	b8 70 39 11 f0       	mov    $0xf0113970,%eax
f010004b:	2d 20 33 11 f0       	sub    $0xf0113320,%eax
f0100050:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100054:	c7 44 24 04 00 00 00 	movl   $0x0,0x4(%esp)
f010005b:	00 
f010005c:	c7 04 24 20 33 11 f0 	movl   $0xf0113320,(%esp)
f0100063:	e8 09 19 00 00       	call   f0101971 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f0100068:	e8 97 04 00 00       	call   f0100504 <cons_init>
	cprintf("6828 decimal is %o octal!\n", 6828);
f010006d:	c7 44 24 04 ac 1a 00 	movl   $0x1aac,0x4(%esp)
f0100074:	00 
f0100075:	c7 04 24 80 1e 10 f0 	movl   $0xf0101e80,(%esp)
f010007c:	e8 39 0d 00 00       	call   f0100dba <cprintf>

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
f010009f:	83 3d 60 39 11 f0 00 	cmpl   $0x0,0xf0113960
f01000a6:	75 3d                	jne    f01000e5 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f01000a8:	89 35 60 39 11 f0    	mov    %esi,0xf0113960

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
f01000c1:	c7 04 24 9b 1e 10 f0 	movl   $0xf0101e9b,(%esp)
f01000c8:	e8 ed 0c 00 00       	call   f0100dba <cprintf>
	vcprintf(fmt, ap);
f01000cd:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01000d1:	89 34 24             	mov    %esi,(%esp)
f01000d4:	e8 ae 0c 00 00       	call   f0100d87 <vcprintf>
	cprintf("\n");
f01000d9:	c7 04 24 d7 1e 10 f0 	movl   $0xf0101ed7,(%esp)
f01000e0:	e8 d5 0c 00 00       	call   f0100dba <cprintf>
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
f010010b:	c7 04 24 b3 1e 10 f0 	movl   $0xf0101eb3,(%esp)
f0100112:	e8 a3 0c 00 00       	call   f0100dba <cprintf>
	vcprintf(fmt, ap);
f0100117:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010011b:	8b 45 10             	mov    0x10(%ebp),%eax
f010011e:	89 04 24             	mov    %eax,(%esp)
f0100121:	e8 61 0c 00 00       	call   f0100d87 <vcprintf>
	cprintf("\n");
f0100126:	c7 04 24 d7 1e 10 f0 	movl   $0xf0101ed7,(%esp)
f010012d:	e8 88 0c 00 00       	call   f0100dba <cprintf>
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
f010031b:	e8 ac 16 00 00       	call   f01019cc <memmove>
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
f01003c7:	0f b6 82 00 1f 10 f0 	movzbl -0xfefe100(%edx),%eax
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
f0100404:	0f b6 82 00 1f 10 f0 	movzbl -0xfefe100(%edx),%eax
f010040b:	0b 05 48 35 11 f0    	or     0xf0113548,%eax
	shift ^= togglecode[data];
f0100411:	0f b6 8a 00 20 10 f0 	movzbl -0xfefe000(%edx),%ecx
f0100418:	31 c8                	xor    %ecx,%eax
f010041a:	a3 48 35 11 f0       	mov    %eax,0xf0113548

	c = charcode[shift & (CTL | SHIFT)][data];
f010041f:	89 c1                	mov    %eax,%ecx
f0100421:	83 e1 03             	and    $0x3,%ecx
f0100424:	8b 0c 8d 00 21 10 f0 	mov    -0xfefdf00(,%ecx,4),%ecx
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
f010045a:	c7 04 24 cd 1e 10 f0 	movl   $0xf0101ecd,(%esp)
f0100461:	e8 54 09 00 00       	call   f0100dba <cprintf>
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
f01005e5:	c7 04 24 d9 1e 10 f0 	movl   $0xf0101ed9,(%esp)
f01005ec:	e8 c9 07 00 00       	call   f0100dba <cprintf>
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
f0100636:	c7 04 24 10 21 10 f0 	movl   $0xf0102110,(%esp)
f010063d:	e8 78 07 00 00       	call   f0100dba <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100642:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f0100649:	00 
f010064a:	c7 04 24 14 22 10 f0 	movl   $0xf0102214,(%esp)
f0100651:	e8 64 07 00 00       	call   f0100dba <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f0100656:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f010065d:	00 
f010065e:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f0100665:	f0 
f0100666:	c7 04 24 3c 22 10 f0 	movl   $0xf010223c,(%esp)
f010066d:	e8 48 07 00 00       	call   f0100dba <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f0100672:	c7 44 24 08 65 1e 10 	movl   $0x101e65,0x8(%esp)
f0100679:	00 
f010067a:	c7 44 24 04 65 1e 10 	movl   $0xf0101e65,0x4(%esp)
f0100681:	f0 
f0100682:	c7 04 24 60 22 10 f0 	movl   $0xf0102260,(%esp)
f0100689:	e8 2c 07 00 00       	call   f0100dba <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f010068e:	c7 44 24 08 20 33 11 	movl   $0x113320,0x8(%esp)
f0100695:	00 
f0100696:	c7 44 24 04 20 33 11 	movl   $0xf0113320,0x4(%esp)
f010069d:	f0 
f010069e:	c7 04 24 84 22 10 f0 	movl   $0xf0102284,(%esp)
f01006a5:	e8 10 07 00 00       	call   f0100dba <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006aa:	c7 44 24 08 70 39 11 	movl   $0x113970,0x8(%esp)
f01006b1:	00 
f01006b2:	c7 44 24 04 70 39 11 	movl   $0xf0113970,0x4(%esp)
f01006b9:	f0 
f01006ba:	c7 04 24 a8 22 10 f0 	movl   $0xf01022a8,(%esp)
f01006c1:	e8 f4 06 00 00       	call   f0100dba <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f01006c6:	b8 6f 3d 11 f0       	mov    $0xf0113d6f,%eax
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
f01006e7:	c7 04 24 cc 22 10 f0 	movl   $0xf01022cc,(%esp)
f01006ee:	e8 c7 06 00 00       	call   f0100dba <cprintf>
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
f0100706:	8b 83 04 24 10 f0    	mov    -0xfefdbfc(%ebx),%eax
f010070c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100710:	8b 83 00 24 10 f0    	mov    -0xfefdc00(%ebx),%eax
f0100716:	89 44 24 04          	mov    %eax,0x4(%esp)
f010071a:	c7 04 24 29 21 10 f0 	movl   $0xf0102129,(%esp)
f0100721:	e8 94 06 00 00       	call   f0100dba <cprintf>
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
f0100749:	c7 04 24 32 21 10 f0 	movl   $0xf0102132,(%esp)
f0100750:	e8 65 06 00 00       	call   f0100dba <cprintf>
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
f0100788:	c7 04 24 f8 22 10 f0 	movl   $0xf01022f8,(%esp)
f010078f:	e8 26 06 00 00       	call   f0100dba <cprintf>
		struct Eipdebuginfo temp_debuginfo;
		debuginfo_eip((uintptr_t) eip, &temp_debuginfo);		
f0100794:	8d 45 d0             	lea    -0x30(%ebp),%eax
f0100797:	89 44 24 04          	mov    %eax,0x4(%esp)
f010079b:	89 3c 24             	mov    %edi,(%esp)
f010079e:	e8 11 07 00 00       	call   f0100eb4 <debuginfo_eip>
		cprintf("       %s:%d: ", temp_debuginfo.eip_file, temp_debuginfo.eip_line);
f01007a3:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01007a6:	89 44 24 08          	mov    %eax,0x8(%esp)
f01007aa:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01007ad:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007b1:	c7 04 24 43 21 10 f0 	movl   $0xf0102143,(%esp)
f01007b8:	e8 fd 05 00 00       	call   f0100dba <cprintf>
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
f01007d3:	c7 04 24 52 21 10 f0 	movl   $0xf0102152,(%esp)
f01007da:	e8 db 05 00 00       	call   f0100dba <cprintf>
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
f01007ee:	c7 04 24 55 21 10 f0 	movl   $0xf0102155,(%esp)
f01007f5:	e8 c0 05 00 00       	call   f0100dba <cprintf>
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
f0100826:	c7 44 24 04 5a 21 10 	movl   $0xf010215a,0x4(%esp)
f010082d:	f0 
f010082e:	8b 46 08             	mov    0x8(%esi),%eax
f0100831:	89 04 24             	mov    %eax,(%esp)
f0100834:	e8 62 10 00 00       	call   f010189b <strcmp>
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
f0100846:	c7 44 24 04 5e 21 10 	movl   $0xf010215e,0x4(%esp)
f010084d:	f0 
f010084e:	8b 46 08             	mov    0x8(%esi),%eax
f0100851:	89 04 24             	mov    %eax,(%esp)
f0100854:	e8 42 10 00 00       	call   f010189b <strcmp>
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
f0100866:	c7 44 24 04 62 21 10 	movl   $0xf0102162,0x4(%esp)
f010086d:	f0 
f010086e:	8b 46 08             	mov    0x8(%esi),%eax
f0100871:	89 04 24             	mov    %eax,(%esp)
f0100874:	e8 22 10 00 00       	call   f010189b <strcmp>
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
f0100886:	c7 44 24 04 66 21 10 	movl   $0xf0102166,0x4(%esp)
f010088d:	f0 
f010088e:	8b 46 08             	mov    0x8(%esi),%eax
f0100891:	89 04 24             	mov    %eax,(%esp)
f0100894:	e8 02 10 00 00       	call   f010189b <strcmp>
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
f01008a6:	c7 44 24 04 6a 21 10 	movl   $0xf010216a,0x4(%esp)
f01008ad:	f0 
f01008ae:	8b 46 08             	mov    0x8(%esi),%eax
f01008b1:	89 04 24             	mov    %eax,(%esp)
f01008b4:	e8 e2 0f 00 00       	call   f010189b <strcmp>
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
f01008c6:	c7 44 24 04 6e 21 10 	movl   $0xf010216e,0x4(%esp)
f01008cd:	f0 
f01008ce:	8b 46 08             	mov    0x8(%esi),%eax
f01008d1:	89 04 24             	mov    %eax,(%esp)
f01008d4:	e8 c2 0f 00 00       	call   f010189b <strcmp>
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
f01008e2:	c7 44 24 04 72 21 10 	movl   $0xf0102172,0x4(%esp)
f01008e9:	f0 
f01008ea:	8b 46 08             	mov    0x8(%esi),%eax
f01008ed:	89 04 24             	mov    %eax,(%esp)
f01008f0:	e8 a6 0f 00 00       	call   f010189b <strcmp>
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
f01008fe:	c7 44 24 04 76 21 10 	movl   $0xf0102176,0x4(%esp)
f0100905:	f0 
f0100906:	8b 46 08             	mov    0x8(%esi),%eax
f0100909:	89 04 24             	mov    %eax,(%esp)
f010090c:	e8 8a 0f 00 00       	call   f010189b <strcmp>
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
f010091a:	c7 44 24 04 7a 21 10 	movl   $0xf010217a,0x4(%esp)
f0100921:	f0 
f0100922:	8b 46 08             	mov    0x8(%esi),%eax
f0100925:	89 04 24             	mov    %eax,(%esp)
f0100928:	e8 6e 0f 00 00       	call   f010189b <strcmp>
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
f0100936:	c7 44 24 04 7e 21 10 	movl   $0xf010217e,0x4(%esp)
f010093d:	f0 
f010093e:	8b 46 08             	mov    0x8(%esi),%eax
f0100941:	89 04 24             	mov    %eax,(%esp)
f0100944:	e8 52 0f 00 00       	call   f010189b <strcmp>
			ch_color1=COLOR_CYN
f0100949:	83 f8 01             	cmp    $0x1,%eax
f010094c:	19 ff                	sbb    %edi,%edi
f010094e:	83 e7 04             	and    $0x4,%edi
f0100951:	83 c7 07             	add    $0x7,%edi
	else ch_color1=COLOR_WHT;
	if(strcmp(argv[1],"blk")==0)
f0100954:	c7 44 24 04 5a 21 10 	movl   $0xf010215a,0x4(%esp)
f010095b:	f0 
f010095c:	8b 46 04             	mov    0x4(%esi),%eax
f010095f:	89 04 24             	mov    %eax,(%esp)
f0100962:	e8 34 0f 00 00       	call   f010189b <strcmp>
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
f0100974:	c7 44 24 04 5e 21 10 	movl   $0xf010215e,0x4(%esp)
f010097b:	f0 
f010097c:	8b 46 04             	mov    0x4(%esi),%eax
f010097f:	89 04 24             	mov    %eax,(%esp)
f0100982:	e8 14 0f 00 00       	call   f010189b <strcmp>
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
f0100991:	c7 44 24 04 62 21 10 	movl   $0xf0102162,0x4(%esp)
f0100998:	f0 
f0100999:	8b 46 04             	mov    0x4(%esi),%eax
f010099c:	89 04 24             	mov    %eax,(%esp)
f010099f:	e8 f7 0e 00 00       	call   f010189b <strcmp>
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
f01009ae:	c7 44 24 04 66 21 10 	movl   $0xf0102166,0x4(%esp)
f01009b5:	f0 
f01009b6:	8b 46 04             	mov    0x4(%esi),%eax
f01009b9:	89 04 24             	mov    %eax,(%esp)
f01009bc:	e8 da 0e 00 00       	call   f010189b <strcmp>
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
f01009cb:	c7 44 24 04 6a 21 10 	movl   $0xf010216a,0x4(%esp)
f01009d2:	f0 
f01009d3:	8b 46 04             	mov    0x4(%esi),%eax
f01009d6:	89 04 24             	mov    %eax,(%esp)
f01009d9:	e8 bd 0e 00 00       	call   f010189b <strcmp>
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
f01009e8:	c7 44 24 04 6e 21 10 	movl   $0xf010216e,0x4(%esp)
f01009ef:	f0 
f01009f0:	8b 46 04             	mov    0x4(%esi),%eax
f01009f3:	89 04 24             	mov    %eax,(%esp)
f01009f6:	e8 a0 0e 00 00       	call   f010189b <strcmp>
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
f0100a01:	c7 44 24 04 72 21 10 	movl   $0xf0102172,0x4(%esp)
f0100a08:	f0 
f0100a09:	8b 46 04             	mov    0x4(%esi),%eax
f0100a0c:	89 04 24             	mov    %eax,(%esp)
f0100a0f:	e8 87 0e 00 00       	call   f010189b <strcmp>
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
f0100a1a:	c7 44 24 04 76 21 10 	movl   $0xf0102176,0x4(%esp)
f0100a21:	f0 
f0100a22:	8b 46 04             	mov    0x4(%esi),%eax
f0100a25:	89 04 24             	mov    %eax,(%esp)
f0100a28:	e8 6e 0e 00 00       	call   f010189b <strcmp>
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
f0100a33:	c7 44 24 04 7a 21 10 	movl   $0xf010217a,0x4(%esp)
f0100a3a:	f0 
f0100a3b:	8b 46 04             	mov    0x4(%esi),%eax
f0100a3e:	89 04 24             	mov    %eax,(%esp)
f0100a41:	e8 55 0e 00 00       	call   f010189b <strcmp>
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
f0100a4c:	c7 44 24 04 7e 21 10 	movl   $0xf010217e,0x4(%esp)
f0100a53:	f0 
f0100a54:	8b 46 04             	mov    0x4(%esi),%eax
f0100a57:	89 04 24             	mov    %eax,(%esp)
f0100a5a:	e8 3c 0e 00 00       	call   f010189b <strcmp>
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
f0100a84:	c7 04 24 2c 23 10 f0 	movl   $0xf010232c,(%esp)
f0100a8b:	e8 2a 03 00 00       	call   f0100dba <cprintf>
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
f0100aab:	c7 04 24 60 23 10 f0 	movl   $0xf0102360,(%esp)
f0100ab2:	e8 03 03 00 00       	call   f0100dba <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100ab7:	c7 04 24 84 23 10 f0 	movl   $0xf0102384,(%esp)
f0100abe:	e8 f7 02 00 00       	call   f0100dba <cprintf>
  //	cprintf("x %d, y %x, z %d\n", x, y, z);
//	unsigned int i = 0x00646c72;
//	cprintf("H%x Wo%s", 57616, &i);

	while (1) {
		buf = readline("K> ");
f0100ac3:	c7 04 24 82 21 10 f0 	movl   $0xf0102182,(%esp)
f0100aca:	e8 f1 0b 00 00       	call   f01016c0 <readline>
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
f0100af7:	c7 04 24 86 21 10 f0 	movl   $0xf0102186,(%esp)
f0100afe:	e8 13 0e 00 00       	call   f0101916 <strchr>
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
f0100b1a:	c7 04 24 8b 21 10 f0 	movl   $0xf010218b,(%esp)
f0100b21:	e8 94 02 00 00       	call   f0100dba <cprintf>
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
f0100b49:	c7 04 24 86 21 10 f0 	movl   $0xf0102186,(%esp)
f0100b50:	e8 c1 0d 00 00       	call   f0101916 <strchr>
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
f0100b6b:	bb 00 24 10 f0       	mov    $0xf0102400,%ebx
f0100b70:	bf 00 00 00 00       	mov    $0x0,%edi
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100b75:	8b 03                	mov    (%ebx),%eax
f0100b77:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100b7b:	8b 45 a8             	mov    -0x58(%ebp),%eax
f0100b7e:	89 04 24             	mov    %eax,(%esp)
f0100b81:	e8 15 0d 00 00       	call   f010189b <strcmp>
f0100b86:	85 c0                	test   %eax,%eax
f0100b88:	75 24                	jne    f0100bae <monitor+0x10c>
			return commands[i].func(argc, argv, tf);
f0100b8a:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f0100b8d:	8b 55 08             	mov    0x8(%ebp),%edx
f0100b90:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100b94:	8d 55 a8             	lea    -0x58(%ebp),%edx
f0100b97:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100b9b:	89 34 24             	mov    %esi,(%esp)
f0100b9e:	ff 14 85 08 24 10 f0 	call   *-0xfefdbf8(,%eax,4)
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
f0100bc0:	c7 04 24 a8 21 10 f0 	movl   $0xf01021a8,(%esp)
f0100bc7:	e8 ee 01 00 00       	call   f0100dba <cprintf>
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
f0100be9:	e8 5e 01 00 00       	call   f0100d4c <mc146818_read>
f0100bee:	89 c6                	mov    %eax,%esi
f0100bf0:	83 c3 01             	add    $0x1,%ebx
f0100bf3:	89 1c 24             	mov    %ebx,(%esp)
f0100bf6:	e8 51 01 00 00       	call   f0100d4c <mc146818_read>
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
f0100c52:	89 15 64 39 11 f0    	mov    %edx,0xf0113964
f0100c58:	eb 0c                	jmp    f0100c66 <mem_init+0x5f>
	else
		npages = npages_basemem;
f0100c5a:	8b 15 58 35 11 f0    	mov    0xf0113558,%edx
f0100c60:	89 15 64 39 11 f0    	mov    %edx,0xf0113964

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
f0100c7f:	a1 64 39 11 f0       	mov    0xf0113964,%eax
f0100c84:	c1 e0 0c             	shl    $0xc,%eax
	if (npages_extmem)
		npages = (EXTPHYSMEM / PGSIZE) + npages_extmem;
	else
		npages = npages_basemem;

	cprintf("Physical memory: %uK available, base = %uK, extended = %uK\n",
f0100c87:	c1 e8 0a             	shr    $0xa,%eax
f0100c8a:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100c8e:	c7 04 24 30 24 10 f0 	movl   $0xf0102430,(%esp)
f0100c95:	e8 20 01 00 00       	call   f0100dba <cprintf>

	// Find out how much memory the machine has (npages & npages_basemem).
	i386_detect_memory();

	// Remove this line when you're ready to test this function.
	panic("mem_init: This function is not finished\n");
f0100c9a:	c7 44 24 08 6c 24 10 	movl   $0xf010246c,0x8(%esp)
f0100ca1:	f0 
f0100ca2:	c7 44 24 04 7c 00 00 	movl   $0x7c,0x4(%esp)
f0100ca9:	00 
f0100caa:	c7 04 24 98 24 10 f0 	movl   $0xf0102498,(%esp)
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
f0100cb9:	53                   	push   %ebx
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	for (i = 0; i < npages; i++) {
f0100cba:	83 3d 64 39 11 f0 00 	cmpl   $0x0,0xf0113964
f0100cc1:	74 3b                	je     f0100cfe <page_init+0x48>
f0100cc3:	8b 1d 5c 35 11 f0    	mov    0xf011355c,%ebx
f0100cc9:	b8 00 00 00 00       	mov    $0x0,%eax
		pages[i].pp_ref = 0;
f0100cce:	8d 14 c5 00 00 00 00 	lea    0x0(,%eax,8),%edx
f0100cd5:	89 d1                	mov    %edx,%ecx
f0100cd7:	03 0d 6c 39 11 f0    	add    0xf011396c,%ecx
f0100cdd:	66 c7 41 04 00 00    	movw   $0x0,0x4(%ecx)
		pages[i].pp_link = page_free_list;
f0100ce3:	89 19                	mov    %ebx,(%ecx)
		page_free_list = &pages[i];
f0100ce5:	89 d3                	mov    %edx,%ebx
f0100ce7:	03 1d 6c 39 11 f0    	add    0xf011396c,%ebx
	//
	// Change the code to reflect this.
	// NB: DO NOT actually touch the physical memory corresponding to
	// free pages!
	size_t i;
	for (i = 0; i < npages; i++) {
f0100ced:	83 c0 01             	add    $0x1,%eax
f0100cf0:	39 05 64 39 11 f0    	cmp    %eax,0xf0113964
f0100cf6:	77 d6                	ja     f0100cce <page_init+0x18>
f0100cf8:	89 1d 5c 35 11 f0    	mov    %ebx,0xf011355c
		pages[i].pp_ref = 0;
		pages[i].pp_link = page_free_list;
		page_free_list = &pages[i];
	}
}
f0100cfe:	5b                   	pop    %ebx
f0100cff:	5d                   	pop    %ebp
f0100d00:	c3                   	ret    

f0100d01 <page_alloc>:
// Returns NULL if out of free memory.
//
// Hint: use page2kva and memset
struct PageInfo *
page_alloc(int alloc_flags)
{
f0100d01:	55                   	push   %ebp
f0100d02:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return 0;
}
f0100d04:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d09:	5d                   	pop    %ebp
f0100d0a:	c3                   	ret    

f0100d0b <page_free>:
// Return a page to the free list.
// (This function should only be called when pp->pp_ref reaches 0.)
//
void
page_free(struct PageInfo *pp)
{
f0100d0b:	55                   	push   %ebp
f0100d0c:	89 e5                	mov    %esp,%ebp
	// Fill this function in
}
f0100d0e:	5d                   	pop    %ebp
f0100d0f:	c3                   	ret    

f0100d10 <page_decref>:
// Decrement the reference count on a page,
// freeing it if there are no more refs.
//
void
page_decref(struct PageInfo* pp)
{
f0100d10:	55                   	push   %ebp
f0100d11:	89 e5                	mov    %esp,%ebp
f0100d13:	8b 45 08             	mov    0x8(%ebp),%eax
	if (--pp->pp_ref == 0)
f0100d16:	66 83 68 04 01       	subw   $0x1,0x4(%eax)
		page_free(pp);
}
f0100d1b:	5d                   	pop    %ebp
f0100d1c:	c3                   	ret    

f0100d1d <pgdir_walk>:
// Hint 3: look at inc/mmu.h for useful macros that mainipulate page
// table and page directory entries.
//
pte_t *
pgdir_walk(pde_t *pgdir, const void *va, int create)
{
f0100d1d:	55                   	push   %ebp
f0100d1e:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return NULL;
}
f0100d20:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d25:	5d                   	pop    %ebp
f0100d26:	c3                   	ret    

f0100d27 <page_insert>:
// Hint: The TA solution is implemented using pgdir_walk, page_remove,
// and page2pa.
//
int
page_insert(pde_t *pgdir, struct PageInfo *pp, void *va, int perm)
{
f0100d27:	55                   	push   %ebp
f0100d28:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return 0;
}
f0100d2a:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d2f:	5d                   	pop    %ebp
f0100d30:	c3                   	ret    

f0100d31 <page_lookup>:
//
// Hint: the TA solution uses pgdir_walk and pa2page.
//
struct PageInfo *
page_lookup(pde_t *pgdir, void *va, pte_t **pte_store)
{
f0100d31:	55                   	push   %ebp
f0100d32:	89 e5                	mov    %esp,%ebp
	// Fill this function in
	return NULL;
}
f0100d34:	b8 00 00 00 00       	mov    $0x0,%eax
f0100d39:	5d                   	pop    %ebp
f0100d3a:	c3                   	ret    

f0100d3b <page_remove>:
// Hint: The TA solution is implemented using page_lookup,
// 	tlb_invalidate, and page_decref.
//
void
page_remove(pde_t *pgdir, void *va)
{
f0100d3b:	55                   	push   %ebp
f0100d3c:	89 e5                	mov    %esp,%ebp
	// Fill this function in
}
f0100d3e:	5d                   	pop    %ebp
f0100d3f:	c3                   	ret    

f0100d40 <tlb_invalidate>:
// Invalidate a TLB entry, but only if the page tables being
// edited are the ones currently in use by the processor.
//
void
tlb_invalidate(pde_t *pgdir, void *va)
{
f0100d40:	55                   	push   %ebp
f0100d41:	89 e5                	mov    %esp,%ebp
}

static __inline void
invlpg(void *addr)
{
	__asm __volatile("invlpg (%0)" : : "r" (addr) : "memory");
f0100d43:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100d46:	0f 01 38             	invlpg (%eax)
	// Flush the entry only if we're modifying the current address space.
	// For now, there is only one address space, so always invalidate.
	invlpg(va);
}
f0100d49:	5d                   	pop    %ebp
f0100d4a:	c3                   	ret    
	...

f0100d4c <mc146818_read>:
#include <kern/kclock.h>


unsigned
mc146818_read(unsigned reg)
{
f0100d4c:	55                   	push   %ebp
f0100d4d:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100d4f:	ba 70 00 00 00       	mov    $0x70,%edx
f0100d54:	8b 45 08             	mov    0x8(%ebp),%eax
f0100d57:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100d58:	b2 71                	mov    $0x71,%dl
f0100d5a:	ec                   	in     (%dx),%al
	outb(IO_RTC, reg);
	return inb(IO_RTC+1);
f0100d5b:	0f b6 c0             	movzbl %al,%eax
}
f0100d5e:	5d                   	pop    %ebp
f0100d5f:	c3                   	ret    

f0100d60 <mc146818_write>:

void
mc146818_write(unsigned reg, unsigned datum)
{
f0100d60:	55                   	push   %ebp
f0100d61:	89 e5                	mov    %esp,%ebp
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100d63:	ba 70 00 00 00       	mov    $0x70,%edx
f0100d68:	8b 45 08             	mov    0x8(%ebp),%eax
f0100d6b:	ee                   	out    %al,(%dx)
f0100d6c:	b2 71                	mov    $0x71,%dl
f0100d6e:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100d71:	ee                   	out    %al,(%dx)
	outb(IO_RTC, reg);
	outb(IO_RTC+1, datum);
}
f0100d72:	5d                   	pop    %ebp
f0100d73:	c3                   	ret    

f0100d74 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100d74:	55                   	push   %ebp
f0100d75:	89 e5                	mov    %esp,%ebp
f0100d77:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f0100d7a:	8b 45 08             	mov    0x8(%ebp),%eax
f0100d7d:	89 04 24             	mov    %eax,(%esp)
f0100d80:	e8 74 f8 ff ff       	call   f01005f9 <cputchar>
	*cnt++;
}
f0100d85:	c9                   	leave  
f0100d86:	c3                   	ret    

f0100d87 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0100d87:	55                   	push   %ebp
f0100d88:	89 e5                	mov    %esp,%ebp
f0100d8a:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f0100d8d:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100d94:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100d97:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100d9b:	8b 45 08             	mov    0x8(%ebp),%eax
f0100d9e:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100da2:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100da5:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100da9:	c7 04 24 74 0d 10 f0 	movl   $0xf0100d74,(%esp)
f0100db0:	e8 b5 04 00 00       	call   f010126a <vprintfmt>
	return cnt;
}
f0100db5:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100db8:	c9                   	leave  
f0100db9:	c3                   	ret    

f0100dba <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0100dba:	55                   	push   %ebp
f0100dbb:	89 e5                	mov    %esp,%ebp
f0100dbd:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0100dc0:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0100dc3:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100dc7:	8b 45 08             	mov    0x8(%ebp),%eax
f0100dca:	89 04 24             	mov    %eax,(%esp)
f0100dcd:	e8 b5 ff ff ff       	call   f0100d87 <vcprintf>
	va_end(ap);

	return cnt;
}
f0100dd2:	c9                   	leave  
f0100dd3:	c3                   	ret    

f0100dd4 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100dd4:	55                   	push   %ebp
f0100dd5:	89 e5                	mov    %esp,%ebp
f0100dd7:	57                   	push   %edi
f0100dd8:	56                   	push   %esi
f0100dd9:	53                   	push   %ebx
f0100dda:	83 ec 10             	sub    $0x10,%esp
f0100ddd:	89 c3                	mov    %eax,%ebx
f0100ddf:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0100de2:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0100de5:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100de8:	8b 0a                	mov    (%edx),%ecx
f0100dea:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100ded:	8b 00                	mov    (%eax),%eax
f0100def:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100df2:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)

	while (l <= r) {
f0100df9:	eb 77                	jmp    f0100e72 <stab_binsearch+0x9e>
		int true_m = (l + r) / 2, m = true_m;
f0100dfb:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100dfe:	01 c8                	add    %ecx,%eax
f0100e00:	bf 02 00 00 00       	mov    $0x2,%edi
f0100e05:	99                   	cltd   
f0100e06:	f7 ff                	idiv   %edi
f0100e08:	89 c2                	mov    %eax,%edx

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100e0a:	eb 01                	jmp    f0100e0d <stab_binsearch+0x39>
			m--;
f0100e0c:	4a                   	dec    %edx

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100e0d:	39 ca                	cmp    %ecx,%edx
f0100e0f:	7c 1d                	jl     f0100e2e <stab_binsearch+0x5a>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0100e11:	6b fa 0c             	imul   $0xc,%edx,%edi

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100e14:	0f b6 7c 3b 04       	movzbl 0x4(%ebx,%edi,1),%edi
f0100e19:	39 f7                	cmp    %esi,%edi
f0100e1b:	75 ef                	jne    f0100e0c <stab_binsearch+0x38>
f0100e1d:	89 55 ec             	mov    %edx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100e20:	6b fa 0c             	imul   $0xc,%edx,%edi
f0100e23:	8b 7c 3b 08          	mov    0x8(%ebx,%edi,1),%edi
f0100e27:	3b 7d 0c             	cmp    0xc(%ebp),%edi
f0100e2a:	73 18                	jae    f0100e44 <stab_binsearch+0x70>
f0100e2c:	eb 05                	jmp    f0100e33 <stab_binsearch+0x5f>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0100e2e:	8d 48 01             	lea    0x1(%eax),%ecx
			continue;
f0100e31:	eb 3f                	jmp    f0100e72 <stab_binsearch+0x9e>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0100e33:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0100e36:	89 11                	mov    %edx,(%ecx)
			l = true_m + 1;
f0100e38:	8d 48 01             	lea    0x1(%eax),%ecx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100e3b:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100e42:	eb 2e                	jmp    f0100e72 <stab_binsearch+0x9e>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0100e44:	3b 7d 0c             	cmp    0xc(%ebp),%edi
f0100e47:	76 15                	jbe    f0100e5e <stab_binsearch+0x8a>
			*region_right = m - 1;
f0100e49:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0100e4c:	4f                   	dec    %edi
f0100e4d:	89 7d f0             	mov    %edi,-0x10(%ebp)
f0100e50:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100e53:	89 38                	mov    %edi,(%eax)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100e55:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100e5c:	eb 14                	jmp    f0100e72 <stab_binsearch+0x9e>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100e5e:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0100e61:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0100e64:	89 39                	mov    %edi,(%ecx)
			l = m;
			addr++;
f0100e66:	ff 45 0c             	incl   0xc(%ebp)
f0100e69:	89 d1                	mov    %edx,%ecx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100e6b:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0100e72:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
f0100e75:	7e 84                	jle    f0100dfb <stab_binsearch+0x27>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100e77:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0100e7b:	75 0d                	jne    f0100e8a <stab_binsearch+0xb6>
		*region_right = *region_left - 1;
f0100e7d:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100e80:	8b 02                	mov    (%edx),%eax
f0100e82:	48                   	dec    %eax
f0100e83:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100e86:	89 01                	mov    %eax,(%ecx)
f0100e88:	eb 22                	jmp    f0100eac <stab_binsearch+0xd8>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100e8a:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100e8d:	8b 01                	mov    (%ecx),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100e8f:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100e92:	8b 0a                	mov    (%edx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100e94:	eb 01                	jmp    f0100e97 <stab_binsearch+0xc3>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100e96:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100e97:	39 c1                	cmp    %eax,%ecx
f0100e99:	7d 0c                	jge    f0100ea7 <stab_binsearch+0xd3>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0100e9b:	6b d0 0c             	imul   $0xc,%eax,%edx
	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
		     l > *region_left && stabs[l].n_type != type;
f0100e9e:	0f b6 54 13 04       	movzbl 0x4(%ebx,%edx,1),%edx
f0100ea3:	39 f2                	cmp    %esi,%edx
f0100ea5:	75 ef                	jne    f0100e96 <stab_binsearch+0xc2>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100ea7:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100eaa:	89 02                	mov    %eax,(%edx)
	}
}
f0100eac:	83 c4 10             	add    $0x10,%esp
f0100eaf:	5b                   	pop    %ebx
f0100eb0:	5e                   	pop    %esi
f0100eb1:	5f                   	pop    %edi
f0100eb2:	5d                   	pop    %ebp
f0100eb3:	c3                   	ret    

f0100eb4 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100eb4:	55                   	push   %ebp
f0100eb5:	89 e5                	mov    %esp,%ebp
f0100eb7:	83 ec 58             	sub    $0x58,%esp
f0100eba:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0100ebd:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0100ec0:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0100ec3:	8b 75 08             	mov    0x8(%ebp),%esi
f0100ec6:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100ec9:	c7 03 a4 24 10 f0    	movl   $0xf01024a4,(%ebx)
	info->eip_line = 0;
f0100ecf:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100ed6:	c7 43 08 a4 24 10 f0 	movl   $0xf01024a4,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100edd:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100ee4:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100ee7:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100eee:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100ef4:	76 12                	jbe    f0100f08 <debuginfo_eip+0x54>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100ef6:	b8 24 8b 10 f0       	mov    $0xf0108b24,%eax
f0100efb:	3d 89 6e 10 f0       	cmp    $0xf0106e89,%eax
f0100f00:	0f 86 f1 01 00 00    	jbe    f01010f7 <debuginfo_eip+0x243>
f0100f06:	eb 1c                	jmp    f0100f24 <debuginfo_eip+0x70>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100f08:	c7 44 24 08 ae 24 10 	movl   $0xf01024ae,0x8(%esp)
f0100f0f:	f0 
f0100f10:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0100f17:	00 
f0100f18:	c7 04 24 bb 24 10 f0 	movl   $0xf01024bb,(%esp)
f0100f1f:	e8 70 f1 ff ff       	call   f0100094 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100f24:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100f29:	80 3d 23 8b 10 f0 00 	cmpb   $0x0,0xf0108b23
f0100f30:	0f 85 cd 01 00 00    	jne    f0101103 <debuginfo_eip+0x24f>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100f36:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100f3d:	b8 88 6e 10 f0       	mov    $0xf0106e88,%eax
f0100f42:	2d dc 26 10 f0       	sub    $0xf01026dc,%eax
f0100f47:	c1 f8 02             	sar    $0x2,%eax
f0100f4a:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100f50:	83 e8 01             	sub    $0x1,%eax
f0100f53:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100f56:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100f5a:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0100f61:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100f64:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100f67:	b8 dc 26 10 f0       	mov    $0xf01026dc,%eax
f0100f6c:	e8 63 fe ff ff       	call   f0100dd4 <stab_binsearch>
	if (lfile == 0)
f0100f71:	8b 55 e4             	mov    -0x1c(%ebp),%edx
		return -1;
f0100f74:	b8 ff ff ff ff       	mov    $0xffffffff,%eax

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
f0100f79:	85 d2                	test   %edx,%edx
f0100f7b:	0f 84 82 01 00 00    	je     f0101103 <debuginfo_eip+0x24f>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100f81:	89 55 dc             	mov    %edx,-0x24(%ebp)
	rfun = rfile;
f0100f84:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100f87:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100f8a:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100f8e:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0100f95:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100f98:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100f9b:	b8 dc 26 10 f0       	mov    $0xf01026dc,%eax
f0100fa0:	e8 2f fe ff ff       	call   f0100dd4 <stab_binsearch>

	if (lfun <= rfun) {
f0100fa5:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100fa8:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100fab:	39 d0                	cmp    %edx,%eax
f0100fad:	7f 3d                	jg     f0100fec <debuginfo_eip+0x138>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100faf:	6b c8 0c             	imul   $0xc,%eax,%ecx
f0100fb2:	8d b9 dc 26 10 f0    	lea    -0xfefd924(%ecx),%edi
f0100fb8:	89 7d c0             	mov    %edi,-0x40(%ebp)
f0100fbb:	8b 89 dc 26 10 f0    	mov    -0xfefd924(%ecx),%ecx
f0100fc1:	bf 24 8b 10 f0       	mov    $0xf0108b24,%edi
f0100fc6:	81 ef 89 6e 10 f0    	sub    $0xf0106e89,%edi
f0100fcc:	39 f9                	cmp    %edi,%ecx
f0100fce:	73 09                	jae    f0100fd9 <debuginfo_eip+0x125>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100fd0:	81 c1 89 6e 10 f0    	add    $0xf0106e89,%ecx
f0100fd6:	89 4b 08             	mov    %ecx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100fd9:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0100fdc:	8b 4f 08             	mov    0x8(%edi),%ecx
f0100fdf:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0100fe2:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0100fe4:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0100fe7:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0100fea:	eb 0f                	jmp    f0100ffb <debuginfo_eip+0x147>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100fec:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100fef:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100ff2:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0100ff5:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100ff8:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100ffb:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0101002:	00 
f0101003:	8b 43 08             	mov    0x8(%ebx),%eax
f0101006:	89 04 24             	mov    %eax,(%esp)
f0101009:	e8 3c 09 00 00       	call   f010194a <strfind>
f010100e:	2b 43 08             	sub    0x8(%ebx),%eax
f0101011:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0101014:	89 74 24 04          	mov    %esi,0x4(%esp)
f0101018:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f010101f:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0101022:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0101025:	b8 dc 26 10 f0       	mov    $0xf01026dc,%eax
f010102a:	e8 a5 fd ff ff       	call   f0100dd4 <stab_binsearch>
	if (lline <= rline) {
f010102f:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101032:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0101035:	7f 0f                	jg     f0101046 <debuginfo_eip+0x192>
		info->eip_line = stabs[lline].n_desc;
f0101037:	6b c0 0c             	imul   $0xc,%eax,%eax
f010103a:	0f b7 80 e2 26 10 f0 	movzwl -0xfefd91e(%eax),%eax
f0101041:	89 43 04             	mov    %eax,0x4(%ebx)
f0101044:	eb 07                	jmp    f010104d <debuginfo_eip+0x199>
	} else {
		info->eip_line = -1;
f0101046:	c7 43 04 ff ff ff ff 	movl   $0xffffffff,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f010104d:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0101050:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0101053:	39 c8                	cmp    %ecx,%eax
f0101055:	7c 5f                	jl     f01010b6 <debuginfo_eip+0x202>
	       && stabs[lline].n_type != N_SOL
f0101057:	89 c2                	mov    %eax,%edx
f0101059:	6b f0 0c             	imul   $0xc,%eax,%esi
f010105c:	80 be e0 26 10 f0 84 	cmpb   $0x84,-0xfefd920(%esi)
f0101063:	75 18                	jne    f010107d <debuginfo_eip+0x1c9>
f0101065:	eb 30                	jmp    f0101097 <debuginfo_eip+0x1e3>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0101067:	83 e8 01             	sub    $0x1,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f010106a:	39 c1                	cmp    %eax,%ecx
f010106c:	7f 48                	jg     f01010b6 <debuginfo_eip+0x202>
	       && stabs[lline].n_type != N_SOL
f010106e:	89 c2                	mov    %eax,%edx
f0101070:	8d 34 40             	lea    (%eax,%eax,2),%esi
f0101073:	80 3c b5 e0 26 10 f0 	cmpb   $0x84,-0xfefd920(,%esi,4)
f010107a:	84 
f010107b:	74 1a                	je     f0101097 <debuginfo_eip+0x1e3>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f010107d:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0101080:	8d 14 95 dc 26 10 f0 	lea    -0xfefd924(,%edx,4),%edx
f0101087:	80 7a 04 64          	cmpb   $0x64,0x4(%edx)
f010108b:	75 da                	jne    f0101067 <debuginfo_eip+0x1b3>
f010108d:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f0101091:	74 d4                	je     f0101067 <debuginfo_eip+0x1b3>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0101093:	39 c8                	cmp    %ecx,%eax
f0101095:	7c 1f                	jl     f01010b6 <debuginfo_eip+0x202>
f0101097:	6b c0 0c             	imul   $0xc,%eax,%eax
f010109a:	8b 80 dc 26 10 f0    	mov    -0xfefd924(%eax),%eax
f01010a0:	ba 24 8b 10 f0       	mov    $0xf0108b24,%edx
f01010a5:	81 ea 89 6e 10 f0    	sub    $0xf0106e89,%edx
f01010ab:	39 d0                	cmp    %edx,%eax
f01010ad:	73 07                	jae    f01010b6 <debuginfo_eip+0x202>
		info->eip_file = stabstr + stabs[lline].n_strx;
f01010af:	05 89 6e 10 f0       	add    $0xf0106e89,%eax
f01010b4:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01010b6:	8b 55 dc             	mov    -0x24(%ebp),%edx
f01010b9:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01010bc:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f01010c1:	39 ca                	cmp    %ecx,%edx
f01010c3:	7d 3e                	jge    f0101103 <debuginfo_eip+0x24f>
		for (lline = lfun + 1;
f01010c5:	83 c2 01             	add    $0x1,%edx
f01010c8:	39 d1                	cmp    %edx,%ecx
f01010ca:	7e 37                	jle    f0101103 <debuginfo_eip+0x24f>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f01010cc:	6b f2 0c             	imul   $0xc,%edx,%esi
f01010cf:	80 be e0 26 10 f0 a0 	cmpb   $0xa0,-0xfefd920(%esi)
f01010d6:	75 2b                	jne    f0101103 <debuginfo_eip+0x24f>
		     lline++)
			info->eip_fn_narg++;
f01010d8:	83 43 14 01          	addl   $0x1,0x14(%ebx)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f01010dc:	83 c2 01             	add    $0x1,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f01010df:	39 d1                	cmp    %edx,%ecx
f01010e1:	7e 1b                	jle    f01010fe <debuginfo_eip+0x24a>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f01010e3:	8d 04 52             	lea    (%edx,%edx,2),%eax
f01010e6:	80 3c 85 e0 26 10 f0 	cmpb   $0xa0,-0xfefd920(,%eax,4)
f01010ed:	a0 
f01010ee:	74 e8                	je     f01010d8 <debuginfo_eip+0x224>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01010f0:	b8 00 00 00 00       	mov    $0x0,%eax
f01010f5:	eb 0c                	jmp    f0101103 <debuginfo_eip+0x24f>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f01010f7:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f01010fc:	eb 05                	jmp    f0101103 <debuginfo_eip+0x24f>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f01010fe:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101103:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0101106:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0101109:	8b 7d fc             	mov    -0x4(%ebp),%edi
f010110c:	89 ec                	mov    %ebp,%esp
f010110e:	5d                   	pop    %ebp
f010110f:	c3                   	ret    

f0101110 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0101110:	55                   	push   %ebp
f0101111:	89 e5                	mov    %esp,%ebp
f0101113:	57                   	push   %edi
f0101114:	56                   	push   %esi
f0101115:	53                   	push   %ebx
f0101116:	83 ec 3c             	sub    $0x3c,%esp
f0101119:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010111c:	89 d7                	mov    %edx,%edi
f010111e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101121:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0101124:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101127:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010112a:	8b 5d 14             	mov    0x14(%ebp),%ebx
f010112d:	8b 75 18             	mov    0x18(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0101130:	b8 00 00 00 00       	mov    $0x0,%eax
f0101135:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0101138:	72 11                	jb     f010114b <printnum+0x3b>
f010113a:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010113d:	39 45 10             	cmp    %eax,0x10(%ebp)
f0101140:	76 09                	jbe    f010114b <printnum+0x3b>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0101142:	83 eb 01             	sub    $0x1,%ebx
f0101145:	85 db                	test   %ebx,%ebx
f0101147:	7f 51                	jg     f010119a <printnum+0x8a>
f0101149:	eb 5e                	jmp    f01011a9 <printnum+0x99>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
f010114b:	89 74 24 10          	mov    %esi,0x10(%esp)
f010114f:	83 eb 01             	sub    $0x1,%ebx
f0101152:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0101156:	8b 45 10             	mov    0x10(%ebp),%eax
f0101159:	89 44 24 08          	mov    %eax,0x8(%esp)
f010115d:	8b 5c 24 08          	mov    0x8(%esp),%ebx
f0101161:	8b 74 24 0c          	mov    0xc(%esp),%esi
f0101165:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f010116c:	00 
f010116d:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0101170:	89 04 24             	mov    %eax,(%esp)
f0101173:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101176:	89 44 24 04          	mov    %eax,0x4(%esp)
f010117a:	e8 41 0a 00 00       	call   f0101bc0 <__udivdi3>
f010117f:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0101183:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0101187:	89 04 24             	mov    %eax,(%esp)
f010118a:	89 54 24 04          	mov    %edx,0x4(%esp)
f010118e:	89 fa                	mov    %edi,%edx
f0101190:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101193:	e8 78 ff ff ff       	call   f0101110 <printnum>
f0101198:	eb 0f                	jmp    f01011a9 <printnum+0x99>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f010119a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010119e:	89 34 24             	mov    %esi,(%esp)
f01011a1:	ff 55 e4             	call   *-0x1c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f01011a4:	83 eb 01             	sub    $0x1,%ebx
f01011a7:	75 f1                	jne    f010119a <printnum+0x8a>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f01011a9:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01011ad:	8b 7c 24 04          	mov    0x4(%esp),%edi
f01011b1:	8b 45 10             	mov    0x10(%ebp),%eax
f01011b4:	89 44 24 08          	mov    %eax,0x8(%esp)
f01011b8:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f01011bf:	00 
f01011c0:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01011c3:	89 04 24             	mov    %eax,(%esp)
f01011c6:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01011c9:	89 44 24 04          	mov    %eax,0x4(%esp)
f01011cd:	e8 1e 0b 00 00       	call   f0101cf0 <__umoddi3>
f01011d2:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01011d6:	0f be 80 c9 24 10 f0 	movsbl -0xfefdb37(%eax),%eax
f01011dd:	89 04 24             	mov    %eax,(%esp)
f01011e0:	ff 55 e4             	call   *-0x1c(%ebp)
}
f01011e3:	83 c4 3c             	add    $0x3c,%esp
f01011e6:	5b                   	pop    %ebx
f01011e7:	5e                   	pop    %esi
f01011e8:	5f                   	pop    %edi
f01011e9:	5d                   	pop    %ebp
f01011ea:	c3                   	ret    

f01011eb <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f01011eb:	55                   	push   %ebp
f01011ec:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f01011ee:	83 fa 01             	cmp    $0x1,%edx
f01011f1:	7e 0e                	jle    f0101201 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f01011f3:	8b 10                	mov    (%eax),%edx
f01011f5:	8d 4a 08             	lea    0x8(%edx),%ecx
f01011f8:	89 08                	mov    %ecx,(%eax)
f01011fa:	8b 02                	mov    (%edx),%eax
f01011fc:	8b 52 04             	mov    0x4(%edx),%edx
f01011ff:	eb 22                	jmp    f0101223 <getuint+0x38>
	else if (lflag)
f0101201:	85 d2                	test   %edx,%edx
f0101203:	74 10                	je     f0101215 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0101205:	8b 10                	mov    (%eax),%edx
f0101207:	8d 4a 04             	lea    0x4(%edx),%ecx
f010120a:	89 08                	mov    %ecx,(%eax)
f010120c:	8b 02                	mov    (%edx),%eax
f010120e:	ba 00 00 00 00       	mov    $0x0,%edx
f0101213:	eb 0e                	jmp    f0101223 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0101215:	8b 10                	mov    (%eax),%edx
f0101217:	8d 4a 04             	lea    0x4(%edx),%ecx
f010121a:	89 08                	mov    %ecx,(%eax)
f010121c:	8b 02                	mov    (%edx),%eax
f010121e:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0101223:	5d                   	pop    %ebp
f0101224:	c3                   	ret    

f0101225 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0101225:	55                   	push   %ebp
f0101226:	89 e5                	mov    %esp,%ebp
f0101228:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f010122b:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f010122f:	8b 10                	mov    (%eax),%edx
f0101231:	3b 50 04             	cmp    0x4(%eax),%edx
f0101234:	73 0a                	jae    f0101240 <sprintputch+0x1b>
		*b->buf++ = ch;
f0101236:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101239:	88 0a                	mov    %cl,(%edx)
f010123b:	83 c2 01             	add    $0x1,%edx
f010123e:	89 10                	mov    %edx,(%eax)
}
f0101240:	5d                   	pop    %ebp
f0101241:	c3                   	ret    

f0101242 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0101242:	55                   	push   %ebp
f0101243:	89 e5                	mov    %esp,%ebp
f0101245:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f0101248:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f010124b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010124f:	8b 45 10             	mov    0x10(%ebp),%eax
f0101252:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101256:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101259:	89 44 24 04          	mov    %eax,0x4(%esp)
f010125d:	8b 45 08             	mov    0x8(%ebp),%eax
f0101260:	89 04 24             	mov    %eax,(%esp)
f0101263:	e8 02 00 00 00       	call   f010126a <vprintfmt>
	va_end(ap);
}
f0101268:	c9                   	leave  
f0101269:	c3                   	ret    

f010126a <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f010126a:	55                   	push   %ebp
f010126b:	89 e5                	mov    %esp,%ebp
f010126d:	57                   	push   %edi
f010126e:	56                   	push   %esi
f010126f:	53                   	push   %ebx
f0101270:	83 ec 4c             	sub    $0x4c,%esp
f0101273:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101276:	8b 75 10             	mov    0x10(%ebp),%esi
f0101279:	eb 12                	jmp    f010128d <vprintfmt+0x23>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f010127b:	85 c0                	test   %eax,%eax
f010127d:	0f 84 a9 03 00 00    	je     f010162c <vprintfmt+0x3c2>
				return;
			putch(ch, putdat);
f0101283:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101287:	89 04 24             	mov    %eax,(%esp)
f010128a:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f010128d:	0f b6 06             	movzbl (%esi),%eax
f0101290:	83 c6 01             	add    $0x1,%esi
f0101293:	83 f8 25             	cmp    $0x25,%eax
f0101296:	75 e3                	jne    f010127b <vprintfmt+0x11>
f0101298:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
f010129c:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
f01012a3:	bf ff ff ff ff       	mov    $0xffffffff,%edi
f01012a8:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
f01012af:	b9 00 00 00 00       	mov    $0x0,%ecx
f01012b4:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f01012b7:	eb 2b                	jmp    f01012e4 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01012b9:	8b 75 e0             	mov    -0x20(%ebp),%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f01012bc:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
f01012c0:	eb 22                	jmp    f01012e4 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01012c2:	8b 75 e0             	mov    -0x20(%ebp),%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f01012c5:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
f01012c9:	eb 19                	jmp    f01012e4 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01012cb:	8b 75 e0             	mov    -0x20(%ebp),%esi
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
f01012ce:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f01012d5:	eb 0d                	jmp    f01012e4 <vprintfmt+0x7a>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f01012d7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01012da:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01012dd:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01012e4:	0f b6 06             	movzbl (%esi),%eax
f01012e7:	0f b6 d0             	movzbl %al,%edx
f01012ea:	8d 7e 01             	lea    0x1(%esi),%edi
f01012ed:	89 7d e0             	mov    %edi,-0x20(%ebp)
f01012f0:	83 e8 23             	sub    $0x23,%eax
f01012f3:	3c 55                	cmp    $0x55,%al
f01012f5:	0f 87 0b 03 00 00    	ja     f0101606 <vprintfmt+0x39c>
f01012fb:	0f b6 c0             	movzbl %al,%eax
f01012fe:	ff 24 85 58 25 10 f0 	jmp    *-0xfefdaa8(,%eax,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0101305:	83 ea 30             	sub    $0x30,%edx
f0101308:	89 55 d4             	mov    %edx,-0x2c(%ebp)
				ch = *fmt;
f010130b:	0f be 46 01          	movsbl 0x1(%esi),%eax
				if (ch < '0' || ch > '9')
f010130f:	8d 50 d0             	lea    -0x30(%eax),%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101312:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
f0101315:	83 fa 09             	cmp    $0x9,%edx
f0101318:	77 4a                	ja     f0101364 <vprintfmt+0xfa>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010131a:	8b 7d d4             	mov    -0x2c(%ebp),%edi
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f010131d:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
f0101320:	8d 14 bf             	lea    (%edi,%edi,4),%edx
f0101323:	8d 7c 50 d0          	lea    -0x30(%eax,%edx,2),%edi
				ch = *fmt;
f0101327:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f010132a:	8d 50 d0             	lea    -0x30(%eax),%edx
f010132d:	83 fa 09             	cmp    $0x9,%edx
f0101330:	76 eb                	jbe    f010131d <vprintfmt+0xb3>
f0101332:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0101335:	eb 2d                	jmp    f0101364 <vprintfmt+0xfa>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0101337:	8b 45 14             	mov    0x14(%ebp),%eax
f010133a:	8d 50 04             	lea    0x4(%eax),%edx
f010133d:	89 55 14             	mov    %edx,0x14(%ebp)
f0101340:	8b 00                	mov    (%eax),%eax
f0101342:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101345:	8b 75 e0             	mov    -0x20(%ebp),%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0101348:	eb 1a                	jmp    f0101364 <vprintfmt+0xfa>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010134a:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case '*':
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
f010134d:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0101351:	79 91                	jns    f01012e4 <vprintfmt+0x7a>
f0101353:	e9 73 ff ff ff       	jmp    f01012cb <vprintfmt+0x61>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101358:	8b 75 e0             	mov    -0x20(%ebp),%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f010135b:	c7 45 dc 01 00 00 00 	movl   $0x1,-0x24(%ebp)
			goto reswitch;
f0101362:	eb 80                	jmp    f01012e4 <vprintfmt+0x7a>

		process_precision:
			if (width < 0)
f0101364:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0101368:	0f 89 76 ff ff ff    	jns    f01012e4 <vprintfmt+0x7a>
f010136e:	e9 64 ff ff ff       	jmp    f01012d7 <vprintfmt+0x6d>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0101373:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101376:	8b 75 e0             	mov    -0x20(%ebp),%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0101379:	e9 66 ff ff ff       	jmp    f01012e4 <vprintfmt+0x7a>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f010137e:	8b 45 14             	mov    0x14(%ebp),%eax
f0101381:	8d 50 04             	lea    0x4(%eax),%edx
f0101384:	89 55 14             	mov    %edx,0x14(%ebp)
f0101387:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010138b:	8b 00                	mov    (%eax),%eax
f010138d:	89 04 24             	mov    %eax,(%esp)
f0101390:	ff 55 08             	call   *0x8(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101393:	8b 75 e0             	mov    -0x20(%ebp),%esi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0101396:	e9 f2 fe ff ff       	jmp    f010128d <vprintfmt+0x23>

		// error message
		case 'e':
			err = va_arg(ap, int);
f010139b:	8b 45 14             	mov    0x14(%ebp),%eax
f010139e:	8d 50 04             	lea    0x4(%eax),%edx
f01013a1:	89 55 14             	mov    %edx,0x14(%ebp)
f01013a4:	8b 00                	mov    (%eax),%eax
f01013a6:	89 c2                	mov    %eax,%edx
f01013a8:	c1 fa 1f             	sar    $0x1f,%edx
f01013ab:	31 d0                	xor    %edx,%eax
f01013ad:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f01013af:	83 f8 06             	cmp    $0x6,%eax
f01013b2:	7f 0b                	jg     f01013bf <vprintfmt+0x155>
f01013b4:	8b 14 85 b0 26 10 f0 	mov    -0xfefd950(,%eax,4),%edx
f01013bb:	85 d2                	test   %edx,%edx
f01013bd:	75 23                	jne    f01013e2 <vprintfmt+0x178>
				printfmt(putch, putdat, "error %d", err);
f01013bf:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01013c3:	c7 44 24 08 e1 24 10 	movl   $0xf01024e1,0x8(%esp)
f01013ca:	f0 
f01013cb:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01013cf:	8b 7d 08             	mov    0x8(%ebp),%edi
f01013d2:	89 3c 24             	mov    %edi,(%esp)
f01013d5:	e8 68 fe ff ff       	call   f0101242 <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01013da:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f01013dd:	e9 ab fe ff ff       	jmp    f010128d <vprintfmt+0x23>
			else
				printfmt(putch, putdat, "%s", p);
f01013e2:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01013e6:	c7 44 24 08 ea 24 10 	movl   $0xf01024ea,0x8(%esp)
f01013ed:	f0 
f01013ee:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01013f2:	8b 7d 08             	mov    0x8(%ebp),%edi
f01013f5:	89 3c 24             	mov    %edi,(%esp)
f01013f8:	e8 45 fe ff ff       	call   f0101242 <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01013fd:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0101400:	e9 88 fe ff ff       	jmp    f010128d <vprintfmt+0x23>
f0101405:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0101408:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010140b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f010140e:	8b 45 14             	mov    0x14(%ebp),%eax
f0101411:	8d 50 04             	lea    0x4(%eax),%edx
f0101414:	89 55 14             	mov    %edx,0x14(%ebp)
f0101417:	8b 30                	mov    (%eax),%esi
				p = "(null)";
f0101419:	85 f6                	test   %esi,%esi
f010141b:	ba da 24 10 f0       	mov    $0xf01024da,%edx
f0101420:	0f 44 f2             	cmove  %edx,%esi
			if (width > 0 && padc != '-')
f0101423:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f0101427:	7e 06                	jle    f010142f <vprintfmt+0x1c5>
f0101429:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
f010142d:	75 10                	jne    f010143f <vprintfmt+0x1d5>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f010142f:	0f be 06             	movsbl (%esi),%eax
f0101432:	83 c6 01             	add    $0x1,%esi
f0101435:	85 c0                	test   %eax,%eax
f0101437:	0f 85 86 00 00 00    	jne    f01014c3 <vprintfmt+0x259>
f010143d:	eb 76                	jmp    f01014b5 <vprintfmt+0x24b>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010143f:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101443:	89 34 24             	mov    %esi,(%esp)
f0101446:	e8 60 03 00 00       	call   f01017ab <strnlen>
f010144b:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f010144e:	29 c2                	sub    %eax,%edx
f0101450:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0101453:	85 d2                	test   %edx,%edx
f0101455:	7e d8                	jle    f010142f <vprintfmt+0x1c5>
					putch(padc, putdat);
f0101457:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
f010145b:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f010145e:	89 d6                	mov    %edx,%esi
f0101460:	89 7d d0             	mov    %edi,-0x30(%ebp)
f0101463:	89 c7                	mov    %eax,%edi
f0101465:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101469:	89 3c 24             	mov    %edi,(%esp)
f010146c:	ff 55 08             	call   *0x8(%ebp)
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010146f:	83 ee 01             	sub    $0x1,%esi
f0101472:	75 f1                	jne    f0101465 <vprintfmt+0x1fb>
f0101474:	89 75 e4             	mov    %esi,-0x1c(%ebp)
f0101477:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f010147a:	8b 7d d0             	mov    -0x30(%ebp),%edi
f010147d:	eb b0                	jmp    f010142f <vprintfmt+0x1c5>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f010147f:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0101483:	74 18                	je     f010149d <vprintfmt+0x233>
f0101485:	8d 50 e0             	lea    -0x20(%eax),%edx
f0101488:	83 fa 5e             	cmp    $0x5e,%edx
f010148b:	76 10                	jbe    f010149d <vprintfmt+0x233>
					putch('?', putdat);
f010148d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101491:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0101498:	ff 55 08             	call   *0x8(%ebp)
f010149b:	eb 0a                	jmp    f01014a7 <vprintfmt+0x23d>
				else
					putch(ch, putdat);
f010149d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01014a1:	89 04 24             	mov    %eax,(%esp)
f01014a4:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01014a7:	83 6d e4 01          	subl   $0x1,-0x1c(%ebp)
f01014ab:	0f be 06             	movsbl (%esi),%eax
f01014ae:	83 c6 01             	add    $0x1,%esi
f01014b1:	85 c0                	test   %eax,%eax
f01014b3:	75 0e                	jne    f01014c3 <vprintfmt+0x259>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01014b5:	8b 75 e0             	mov    -0x20(%ebp),%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f01014b8:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01014bc:	7f 16                	jg     f01014d4 <vprintfmt+0x26a>
f01014be:	e9 ca fd ff ff       	jmp    f010128d <vprintfmt+0x23>
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01014c3:	85 ff                	test   %edi,%edi
f01014c5:	78 b8                	js     f010147f <vprintfmt+0x215>
f01014c7:	83 ef 01             	sub    $0x1,%edi
f01014ca:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01014d0:	79 ad                	jns    f010147f <vprintfmt+0x215>
f01014d2:	eb e1                	jmp    f01014b5 <vprintfmt+0x24b>
f01014d4:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01014d7:	8b 7d 08             	mov    0x8(%ebp),%edi
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f01014da:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01014de:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f01014e5:	ff d7                	call   *%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f01014e7:	83 ee 01             	sub    $0x1,%esi
f01014ea:	75 ee                	jne    f01014da <vprintfmt+0x270>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01014ec:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01014ef:	e9 99 fd ff ff       	jmp    f010128d <vprintfmt+0x23>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f01014f4:	83 f9 01             	cmp    $0x1,%ecx
f01014f7:	7e 10                	jle    f0101509 <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f01014f9:	8b 45 14             	mov    0x14(%ebp),%eax
f01014fc:	8d 50 08             	lea    0x8(%eax),%edx
f01014ff:	89 55 14             	mov    %edx,0x14(%ebp)
f0101502:	8b 30                	mov    (%eax),%esi
f0101504:	8b 78 04             	mov    0x4(%eax),%edi
f0101507:	eb 26                	jmp    f010152f <vprintfmt+0x2c5>
	else if (lflag)
f0101509:	85 c9                	test   %ecx,%ecx
f010150b:	74 12                	je     f010151f <vprintfmt+0x2b5>
		return va_arg(*ap, long);
f010150d:	8b 45 14             	mov    0x14(%ebp),%eax
f0101510:	8d 50 04             	lea    0x4(%eax),%edx
f0101513:	89 55 14             	mov    %edx,0x14(%ebp)
f0101516:	8b 30                	mov    (%eax),%esi
f0101518:	89 f7                	mov    %esi,%edi
f010151a:	c1 ff 1f             	sar    $0x1f,%edi
f010151d:	eb 10                	jmp    f010152f <vprintfmt+0x2c5>
	else
		return va_arg(*ap, int);
f010151f:	8b 45 14             	mov    0x14(%ebp),%eax
f0101522:	8d 50 04             	lea    0x4(%eax),%edx
f0101525:	89 55 14             	mov    %edx,0x14(%ebp)
f0101528:	8b 30                	mov    (%eax),%esi
f010152a:	89 f7                	mov    %esi,%edi
f010152c:	c1 ff 1f             	sar    $0x1f,%edi
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f010152f:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0101534:	85 ff                	test   %edi,%edi
f0101536:	0f 89 8c 00 00 00    	jns    f01015c8 <vprintfmt+0x35e>
				putch('-', putdat);
f010153c:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101540:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f0101547:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f010154a:	f7 de                	neg    %esi
f010154c:	83 d7 00             	adc    $0x0,%edi
f010154f:	f7 df                	neg    %edi
			}
			base = 10;
f0101551:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101556:	eb 70                	jmp    f01015c8 <vprintfmt+0x35e>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0101558:	89 ca                	mov    %ecx,%edx
f010155a:	8d 45 14             	lea    0x14(%ebp),%eax
f010155d:	e8 89 fc ff ff       	call   f01011eb <getuint>
f0101562:	89 c6                	mov    %eax,%esi
f0101564:	89 d7                	mov    %edx,%edi
			base = 10;
f0101566:	b8 0a 00 00 00       	mov    $0xa,%eax
			goto number;
f010156b:	eb 5b                	jmp    f01015c8 <vprintfmt+0x35e>
			// Replace this with your code.
			//putch('0', putdat);
			//putch('X', putdat);
			//putch('X', putdat);
			//break;
			num = getuint(&ap, lflag);
f010156d:	89 ca                	mov    %ecx,%edx
f010156f:	8d 45 14             	lea    0x14(%ebp),%eax
f0101572:	e8 74 fc ff ff       	call   f01011eb <getuint>
f0101577:	89 c6                	mov    %eax,%esi
f0101579:	89 d7                	mov    %edx,%edi
			base = 8;
f010157b:	b8 08 00 00 00       	mov    $0x8,%eax
			goto number;
f0101580:	eb 46                	jmp    f01015c8 <vprintfmt+0x35e>
		// pointer
		case 'p':
			putch('0', putdat);
f0101582:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101586:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f010158d:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f0101590:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101594:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f010159b:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f010159e:	8b 45 14             	mov    0x14(%ebp),%eax
f01015a1:	8d 50 04             	lea    0x4(%eax),%edx
f01015a4:	89 55 14             	mov    %edx,0x14(%ebp)
			goto number;
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f01015a7:	8b 30                	mov    (%eax),%esi
f01015a9:	bf 00 00 00 00       	mov    $0x0,%edi
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f01015ae:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f01015b3:	eb 13                	jmp    f01015c8 <vprintfmt+0x35e>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f01015b5:	89 ca                	mov    %ecx,%edx
f01015b7:	8d 45 14             	lea    0x14(%ebp),%eax
f01015ba:	e8 2c fc ff ff       	call   f01011eb <getuint>
f01015bf:	89 c6                	mov    %eax,%esi
f01015c1:	89 d7                	mov    %edx,%edi
			base = 16;
f01015c3:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f01015c8:	0f be 55 d8          	movsbl -0x28(%ebp),%edx
f01015cc:	89 54 24 10          	mov    %edx,0x10(%esp)
f01015d0:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01015d3:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01015d7:	89 44 24 08          	mov    %eax,0x8(%esp)
f01015db:	89 34 24             	mov    %esi,(%esp)
f01015de:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01015e2:	89 da                	mov    %ebx,%edx
f01015e4:	8b 45 08             	mov    0x8(%ebp),%eax
f01015e7:	e8 24 fb ff ff       	call   f0101110 <printnum>
			break;
f01015ec:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01015ef:	e9 99 fc ff ff       	jmp    f010128d <vprintfmt+0x23>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f01015f4:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01015f8:	89 14 24             	mov    %edx,(%esp)
f01015fb:	ff 55 08             	call   *0x8(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01015fe:	8b 75 e0             	mov    -0x20(%ebp),%esi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0101601:	e9 87 fc ff ff       	jmp    f010128d <vprintfmt+0x23>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0101606:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010160a:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0101611:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0101614:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
f0101618:	0f 84 6f fc ff ff    	je     f010128d <vprintfmt+0x23>
f010161e:	83 ee 01             	sub    $0x1,%esi
f0101621:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
f0101625:	75 f7                	jne    f010161e <vprintfmt+0x3b4>
f0101627:	e9 61 fc ff ff       	jmp    f010128d <vprintfmt+0x23>
				/* do nothing */;
			break;
		}
	}
}
f010162c:	83 c4 4c             	add    $0x4c,%esp
f010162f:	5b                   	pop    %ebx
f0101630:	5e                   	pop    %esi
f0101631:	5f                   	pop    %edi
f0101632:	5d                   	pop    %ebp
f0101633:	c3                   	ret    

f0101634 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0101634:	55                   	push   %ebp
f0101635:	89 e5                	mov    %esp,%ebp
f0101637:	83 ec 28             	sub    $0x28,%esp
f010163a:	8b 45 08             	mov    0x8(%ebp),%eax
f010163d:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0101640:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101643:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0101647:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f010164a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0101651:	85 c0                	test   %eax,%eax
f0101653:	74 30                	je     f0101685 <vsnprintf+0x51>
f0101655:	85 d2                	test   %edx,%edx
f0101657:	7e 2c                	jle    f0101685 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0101659:	8b 45 14             	mov    0x14(%ebp),%eax
f010165c:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101660:	8b 45 10             	mov    0x10(%ebp),%eax
f0101663:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101667:	8d 45 ec             	lea    -0x14(%ebp),%eax
f010166a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010166e:	c7 04 24 25 12 10 f0 	movl   $0xf0101225,(%esp)
f0101675:	e8 f0 fb ff ff       	call   f010126a <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f010167a:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010167d:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0101680:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101683:	eb 05                	jmp    f010168a <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0101685:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f010168a:	c9                   	leave  
f010168b:	c3                   	ret    

f010168c <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010168c:	55                   	push   %ebp
f010168d:	89 e5                	mov    %esp,%ebp
f010168f:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0101692:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0101695:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101699:	8b 45 10             	mov    0x10(%ebp),%eax
f010169c:	89 44 24 08          	mov    %eax,0x8(%esp)
f01016a0:	8b 45 0c             	mov    0xc(%ebp),%eax
f01016a3:	89 44 24 04          	mov    %eax,0x4(%esp)
f01016a7:	8b 45 08             	mov    0x8(%ebp),%eax
f01016aa:	89 04 24             	mov    %eax,(%esp)
f01016ad:	e8 82 ff ff ff       	call   f0101634 <vsnprintf>
	va_end(ap);

	return rc;
}
f01016b2:	c9                   	leave  
f01016b3:	c3                   	ret    
	...

f01016c0 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01016c0:	55                   	push   %ebp
f01016c1:	89 e5                	mov    %esp,%ebp
f01016c3:	57                   	push   %edi
f01016c4:	56                   	push   %esi
f01016c5:	53                   	push   %ebx
f01016c6:	83 ec 1c             	sub    $0x1c,%esp
f01016c9:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01016cc:	85 c0                	test   %eax,%eax
f01016ce:	74 10                	je     f01016e0 <readline+0x20>
		cprintf("%s", prompt);
f01016d0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01016d4:	c7 04 24 ea 24 10 f0 	movl   $0xf01024ea,(%esp)
f01016db:	e8 da f6 ff ff       	call   f0100dba <cprintf>

	i = 0;
	echoing = iscons(0);
f01016e0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01016e7:	e8 2e ef ff ff       	call   f010061a <iscons>
f01016ec:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f01016ee:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f01016f3:	e8 11 ef ff ff       	call   f0100609 <getchar>
f01016f8:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01016fa:	85 c0                	test   %eax,%eax
f01016fc:	79 17                	jns    f0101715 <readline+0x55>
			cprintf("read error: %e\n", c);
f01016fe:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101702:	c7 04 24 cc 26 10 f0 	movl   $0xf01026cc,(%esp)
f0101709:	e8 ac f6 ff ff       	call   f0100dba <cprintf>
			return NULL;
f010170e:	b8 00 00 00 00       	mov    $0x0,%eax
f0101713:	eb 6d                	jmp    f0101782 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101715:	83 f8 08             	cmp    $0x8,%eax
f0101718:	74 05                	je     f010171f <readline+0x5f>
f010171a:	83 f8 7f             	cmp    $0x7f,%eax
f010171d:	75 19                	jne    f0101738 <readline+0x78>
f010171f:	85 f6                	test   %esi,%esi
f0101721:	7e 15                	jle    f0101738 <readline+0x78>
			if (echoing)
f0101723:	85 ff                	test   %edi,%edi
f0101725:	74 0c                	je     f0101733 <readline+0x73>
				cputchar('\b');
f0101727:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f010172e:	e8 c6 ee ff ff       	call   f01005f9 <cputchar>
			i--;
f0101733:	83 ee 01             	sub    $0x1,%esi
f0101736:	eb bb                	jmp    f01016f3 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101738:	83 fb 1f             	cmp    $0x1f,%ebx
f010173b:	7e 1f                	jle    f010175c <readline+0x9c>
f010173d:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0101743:	7f 17                	jg     f010175c <readline+0x9c>
			if (echoing)
f0101745:	85 ff                	test   %edi,%edi
f0101747:	74 08                	je     f0101751 <readline+0x91>
				cputchar(c);
f0101749:	89 1c 24             	mov    %ebx,(%esp)
f010174c:	e8 a8 ee ff ff       	call   f01005f9 <cputchar>
			buf[i++] = c;
f0101751:	88 9e 60 35 11 f0    	mov    %bl,-0xfeecaa0(%esi)
f0101757:	83 c6 01             	add    $0x1,%esi
f010175a:	eb 97                	jmp    f01016f3 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f010175c:	83 fb 0a             	cmp    $0xa,%ebx
f010175f:	74 05                	je     f0101766 <readline+0xa6>
f0101761:	83 fb 0d             	cmp    $0xd,%ebx
f0101764:	75 8d                	jne    f01016f3 <readline+0x33>
			if (echoing)
f0101766:	85 ff                	test   %edi,%edi
f0101768:	74 0c                	je     f0101776 <readline+0xb6>
				cputchar('\n');
f010176a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0101771:	e8 83 ee ff ff       	call   f01005f9 <cputchar>
			buf[i] = 0;
f0101776:	c6 86 60 35 11 f0 00 	movb   $0x0,-0xfeecaa0(%esi)
			return buf;
f010177d:	b8 60 35 11 f0       	mov    $0xf0113560,%eax
		}
	}
}
f0101782:	83 c4 1c             	add    $0x1c,%esp
f0101785:	5b                   	pop    %ebx
f0101786:	5e                   	pop    %esi
f0101787:	5f                   	pop    %edi
f0101788:	5d                   	pop    %ebp
f0101789:	c3                   	ret    
f010178a:	00 00                	add    %al,(%eax)
f010178c:	00 00                	add    %al,(%eax)
	...

f0101790 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0101790:	55                   	push   %ebp
f0101791:	89 e5                	mov    %esp,%ebp
f0101793:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0101796:	b8 00 00 00 00       	mov    $0x0,%eax
f010179b:	80 3a 00             	cmpb   $0x0,(%edx)
f010179e:	74 09                	je     f01017a9 <strlen+0x19>
		n++;
f01017a0:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01017a3:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01017a7:	75 f7                	jne    f01017a0 <strlen+0x10>
		n++;
	return n;
}
f01017a9:	5d                   	pop    %ebp
f01017aa:	c3                   	ret    

f01017ab <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01017ab:	55                   	push   %ebp
f01017ac:	89 e5                	mov    %esp,%ebp
f01017ae:	53                   	push   %ebx
f01017af:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01017b2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01017b5:	b8 00 00 00 00       	mov    $0x0,%eax
f01017ba:	85 c9                	test   %ecx,%ecx
f01017bc:	74 1a                	je     f01017d8 <strnlen+0x2d>
f01017be:	80 3b 00             	cmpb   $0x0,(%ebx)
f01017c1:	74 15                	je     f01017d8 <strnlen+0x2d>
f01017c3:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
f01017c8:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01017ca:	39 ca                	cmp    %ecx,%edx
f01017cc:	74 0a                	je     f01017d8 <strnlen+0x2d>
f01017ce:	83 c2 01             	add    $0x1,%edx
f01017d1:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
f01017d6:	75 f0                	jne    f01017c8 <strnlen+0x1d>
		n++;
	return n;
}
f01017d8:	5b                   	pop    %ebx
f01017d9:	5d                   	pop    %ebp
f01017da:	c3                   	ret    

f01017db <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01017db:	55                   	push   %ebp
f01017dc:	89 e5                	mov    %esp,%ebp
f01017de:	53                   	push   %ebx
f01017df:	8b 45 08             	mov    0x8(%ebp),%eax
f01017e2:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01017e5:	ba 00 00 00 00       	mov    $0x0,%edx
f01017ea:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f01017ee:	88 0c 10             	mov    %cl,(%eax,%edx,1)
f01017f1:	83 c2 01             	add    $0x1,%edx
f01017f4:	84 c9                	test   %cl,%cl
f01017f6:	75 f2                	jne    f01017ea <strcpy+0xf>
		/* do nothing */;
	return ret;
}
f01017f8:	5b                   	pop    %ebx
f01017f9:	5d                   	pop    %ebp
f01017fa:	c3                   	ret    

f01017fb <strcat>:

char *
strcat(char *dst, const char *src)
{
f01017fb:	55                   	push   %ebp
f01017fc:	89 e5                	mov    %esp,%ebp
f01017fe:	53                   	push   %ebx
f01017ff:	83 ec 08             	sub    $0x8,%esp
f0101802:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0101805:	89 1c 24             	mov    %ebx,(%esp)
f0101808:	e8 83 ff ff ff       	call   f0101790 <strlen>
	strcpy(dst + len, src);
f010180d:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101810:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101814:	01 d8                	add    %ebx,%eax
f0101816:	89 04 24             	mov    %eax,(%esp)
f0101819:	e8 bd ff ff ff       	call   f01017db <strcpy>
	return dst;
}
f010181e:	89 d8                	mov    %ebx,%eax
f0101820:	83 c4 08             	add    $0x8,%esp
f0101823:	5b                   	pop    %ebx
f0101824:	5d                   	pop    %ebp
f0101825:	c3                   	ret    

f0101826 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0101826:	55                   	push   %ebp
f0101827:	89 e5                	mov    %esp,%ebp
f0101829:	56                   	push   %esi
f010182a:	53                   	push   %ebx
f010182b:	8b 45 08             	mov    0x8(%ebp),%eax
f010182e:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101831:	8b 75 10             	mov    0x10(%ebp),%esi
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101834:	85 f6                	test   %esi,%esi
f0101836:	74 18                	je     f0101850 <strncpy+0x2a>
f0101838:	b9 00 00 00 00       	mov    $0x0,%ecx
		*dst++ = *src;
f010183d:	0f b6 1a             	movzbl (%edx),%ebx
f0101840:	88 1c 08             	mov    %bl,(%eax,%ecx,1)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0101843:	80 3a 01             	cmpb   $0x1,(%edx)
f0101846:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101849:	83 c1 01             	add    $0x1,%ecx
f010184c:	39 f1                	cmp    %esi,%ecx
f010184e:	75 ed                	jne    f010183d <strncpy+0x17>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0101850:	5b                   	pop    %ebx
f0101851:	5e                   	pop    %esi
f0101852:	5d                   	pop    %ebp
f0101853:	c3                   	ret    

f0101854 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0101854:	55                   	push   %ebp
f0101855:	89 e5                	mov    %esp,%ebp
f0101857:	57                   	push   %edi
f0101858:	56                   	push   %esi
f0101859:	53                   	push   %ebx
f010185a:	8b 7d 08             	mov    0x8(%ebp),%edi
f010185d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101860:	8b 75 10             	mov    0x10(%ebp),%esi
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0101863:	89 f8                	mov    %edi,%eax
f0101865:	85 f6                	test   %esi,%esi
f0101867:	74 2b                	je     f0101894 <strlcpy+0x40>
		while (--size > 0 && *src != '\0')
f0101869:	83 fe 01             	cmp    $0x1,%esi
f010186c:	74 23                	je     f0101891 <strlcpy+0x3d>
f010186e:	0f b6 0b             	movzbl (%ebx),%ecx
f0101871:	84 c9                	test   %cl,%cl
f0101873:	74 1c                	je     f0101891 <strlcpy+0x3d>
	}
	return ret;
}

size_t
strlcpy(char *dst, const char *src, size_t size)
f0101875:	83 ee 02             	sub    $0x2,%esi
f0101878:	ba 00 00 00 00       	mov    $0x0,%edx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f010187d:	88 08                	mov    %cl,(%eax)
f010187f:	83 c0 01             	add    $0x1,%eax
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0101882:	39 f2                	cmp    %esi,%edx
f0101884:	74 0b                	je     f0101891 <strlcpy+0x3d>
f0101886:	83 c2 01             	add    $0x1,%edx
f0101889:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f010188d:	84 c9                	test   %cl,%cl
f010188f:	75 ec                	jne    f010187d <strlcpy+0x29>
			*dst++ = *src++;
		*dst = '\0';
f0101891:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0101894:	29 f8                	sub    %edi,%eax
}
f0101896:	5b                   	pop    %ebx
f0101897:	5e                   	pop    %esi
f0101898:	5f                   	pop    %edi
f0101899:	5d                   	pop    %ebp
f010189a:	c3                   	ret    

f010189b <strcmp>:

int
strcmp(const char *p, const char *q)
{
f010189b:	55                   	push   %ebp
f010189c:	89 e5                	mov    %esp,%ebp
f010189e:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01018a1:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01018a4:	0f b6 01             	movzbl (%ecx),%eax
f01018a7:	84 c0                	test   %al,%al
f01018a9:	74 16                	je     f01018c1 <strcmp+0x26>
f01018ab:	3a 02                	cmp    (%edx),%al
f01018ad:	75 12                	jne    f01018c1 <strcmp+0x26>
		p++, q++;
f01018af:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01018b2:	0f b6 41 01          	movzbl 0x1(%ecx),%eax
f01018b6:	84 c0                	test   %al,%al
f01018b8:	74 07                	je     f01018c1 <strcmp+0x26>
f01018ba:	83 c1 01             	add    $0x1,%ecx
f01018bd:	3a 02                	cmp    (%edx),%al
f01018bf:	74 ee                	je     f01018af <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01018c1:	0f b6 c0             	movzbl %al,%eax
f01018c4:	0f b6 12             	movzbl (%edx),%edx
f01018c7:	29 d0                	sub    %edx,%eax
}
f01018c9:	5d                   	pop    %ebp
f01018ca:	c3                   	ret    

f01018cb <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01018cb:	55                   	push   %ebp
f01018cc:	89 e5                	mov    %esp,%ebp
f01018ce:	53                   	push   %ebx
f01018cf:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01018d2:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01018d5:	8b 55 10             	mov    0x10(%ebp),%edx
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f01018d8:	b8 00 00 00 00       	mov    $0x0,%eax
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01018dd:	85 d2                	test   %edx,%edx
f01018df:	74 28                	je     f0101909 <strncmp+0x3e>
f01018e1:	0f b6 01             	movzbl (%ecx),%eax
f01018e4:	84 c0                	test   %al,%al
f01018e6:	74 24                	je     f010190c <strncmp+0x41>
f01018e8:	3a 03                	cmp    (%ebx),%al
f01018ea:	75 20                	jne    f010190c <strncmp+0x41>
f01018ec:	83 ea 01             	sub    $0x1,%edx
f01018ef:	74 13                	je     f0101904 <strncmp+0x39>
		n--, p++, q++;
f01018f1:	83 c1 01             	add    $0x1,%ecx
f01018f4:	83 c3 01             	add    $0x1,%ebx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01018f7:	0f b6 01             	movzbl (%ecx),%eax
f01018fa:	84 c0                	test   %al,%al
f01018fc:	74 0e                	je     f010190c <strncmp+0x41>
f01018fe:	3a 03                	cmp    (%ebx),%al
f0101900:	74 ea                	je     f01018ec <strncmp+0x21>
f0101902:	eb 08                	jmp    f010190c <strncmp+0x41>
		n--, p++, q++;
	if (n == 0)
		return 0;
f0101904:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0101909:	5b                   	pop    %ebx
f010190a:	5d                   	pop    %ebp
f010190b:	c3                   	ret    
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f010190c:	0f b6 01             	movzbl (%ecx),%eax
f010190f:	0f b6 13             	movzbl (%ebx),%edx
f0101912:	29 d0                	sub    %edx,%eax
f0101914:	eb f3                	jmp    f0101909 <strncmp+0x3e>

f0101916 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0101916:	55                   	push   %ebp
f0101917:	89 e5                	mov    %esp,%ebp
f0101919:	8b 45 08             	mov    0x8(%ebp),%eax
f010191c:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101920:	0f b6 10             	movzbl (%eax),%edx
f0101923:	84 d2                	test   %dl,%dl
f0101925:	74 1c                	je     f0101943 <strchr+0x2d>
		if (*s == c)
f0101927:	38 ca                	cmp    %cl,%dl
f0101929:	75 09                	jne    f0101934 <strchr+0x1e>
f010192b:	eb 1b                	jmp    f0101948 <strchr+0x32>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f010192d:	83 c0 01             	add    $0x1,%eax
		if (*s == c)
f0101930:	38 ca                	cmp    %cl,%dl
f0101932:	74 14                	je     f0101948 <strchr+0x32>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0101934:	0f b6 50 01          	movzbl 0x1(%eax),%edx
f0101938:	84 d2                	test   %dl,%dl
f010193a:	75 f1                	jne    f010192d <strchr+0x17>
		if (*s == c)
			return (char *) s;
	return 0;
f010193c:	b8 00 00 00 00       	mov    $0x0,%eax
f0101941:	eb 05                	jmp    f0101948 <strchr+0x32>
f0101943:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101948:	5d                   	pop    %ebp
f0101949:	c3                   	ret    

f010194a <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010194a:	55                   	push   %ebp
f010194b:	89 e5                	mov    %esp,%ebp
f010194d:	8b 45 08             	mov    0x8(%ebp),%eax
f0101950:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101954:	0f b6 10             	movzbl (%eax),%edx
f0101957:	84 d2                	test   %dl,%dl
f0101959:	74 14                	je     f010196f <strfind+0x25>
		if (*s == c)
f010195b:	38 ca                	cmp    %cl,%dl
f010195d:	75 06                	jne    f0101965 <strfind+0x1b>
f010195f:	eb 0e                	jmp    f010196f <strfind+0x25>
f0101961:	38 ca                	cmp    %cl,%dl
f0101963:	74 0a                	je     f010196f <strfind+0x25>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f0101965:	83 c0 01             	add    $0x1,%eax
f0101968:	0f b6 10             	movzbl (%eax),%edx
f010196b:	84 d2                	test   %dl,%dl
f010196d:	75 f2                	jne    f0101961 <strfind+0x17>
		if (*s == c)
			break;
	return (char *) s;
}
f010196f:	5d                   	pop    %ebp
f0101970:	c3                   	ret    

f0101971 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0101971:	55                   	push   %ebp
f0101972:	89 e5                	mov    %esp,%ebp
f0101974:	83 ec 0c             	sub    $0xc,%esp
f0101977:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f010197a:	89 75 f8             	mov    %esi,-0x8(%ebp)
f010197d:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0101980:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101983:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101986:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0101989:	85 c9                	test   %ecx,%ecx
f010198b:	74 30                	je     f01019bd <memset+0x4c>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f010198d:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0101993:	75 25                	jne    f01019ba <memset+0x49>
f0101995:	f6 c1 03             	test   $0x3,%cl
f0101998:	75 20                	jne    f01019ba <memset+0x49>
		c &= 0xFF;
f010199a:	0f b6 d0             	movzbl %al,%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f010199d:	89 d3                	mov    %edx,%ebx
f010199f:	c1 e3 08             	shl    $0x8,%ebx
f01019a2:	89 d6                	mov    %edx,%esi
f01019a4:	c1 e6 18             	shl    $0x18,%esi
f01019a7:	89 d0                	mov    %edx,%eax
f01019a9:	c1 e0 10             	shl    $0x10,%eax
f01019ac:	09 f0                	or     %esi,%eax
f01019ae:	09 d0                	or     %edx,%eax
f01019b0:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f01019b2:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f01019b5:	fc                   	cld    
f01019b6:	f3 ab                	rep stos %eax,%es:(%edi)
f01019b8:	eb 03                	jmp    f01019bd <memset+0x4c>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01019ba:	fc                   	cld    
f01019bb:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01019bd:	89 f8                	mov    %edi,%eax
f01019bf:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f01019c2:	8b 75 f8             	mov    -0x8(%ebp),%esi
f01019c5:	8b 7d fc             	mov    -0x4(%ebp),%edi
f01019c8:	89 ec                	mov    %ebp,%esp
f01019ca:	5d                   	pop    %ebp
f01019cb:	c3                   	ret    

f01019cc <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01019cc:	55                   	push   %ebp
f01019cd:	89 e5                	mov    %esp,%ebp
f01019cf:	83 ec 08             	sub    $0x8,%esp
f01019d2:	89 75 f8             	mov    %esi,-0x8(%ebp)
f01019d5:	89 7d fc             	mov    %edi,-0x4(%ebp)
f01019d8:	8b 45 08             	mov    0x8(%ebp),%eax
f01019db:	8b 75 0c             	mov    0xc(%ebp),%esi
f01019de:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01019e1:	39 c6                	cmp    %eax,%esi
f01019e3:	73 36                	jae    f0101a1b <memmove+0x4f>
f01019e5:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01019e8:	39 d0                	cmp    %edx,%eax
f01019ea:	73 2f                	jae    f0101a1b <memmove+0x4f>
		s += n;
		d += n;
f01019ec:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01019ef:	f6 c2 03             	test   $0x3,%dl
f01019f2:	75 1b                	jne    f0101a0f <memmove+0x43>
f01019f4:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01019fa:	75 13                	jne    f0101a0f <memmove+0x43>
f01019fc:	f6 c1 03             	test   $0x3,%cl
f01019ff:	75 0e                	jne    f0101a0f <memmove+0x43>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0101a01:	83 ef 04             	sub    $0x4,%edi
f0101a04:	8d 72 fc             	lea    -0x4(%edx),%esi
f0101a07:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f0101a0a:	fd                   	std    
f0101a0b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101a0d:	eb 09                	jmp    f0101a18 <memmove+0x4c>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f0101a0f:	83 ef 01             	sub    $0x1,%edi
f0101a12:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0101a15:	fd                   	std    
f0101a16:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0101a18:	fc                   	cld    
f0101a19:	eb 20                	jmp    f0101a3b <memmove+0x6f>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f0101a1b:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0101a21:	75 13                	jne    f0101a36 <memmove+0x6a>
f0101a23:	a8 03                	test   $0x3,%al
f0101a25:	75 0f                	jne    f0101a36 <memmove+0x6a>
f0101a27:	f6 c1 03             	test   $0x3,%cl
f0101a2a:	75 0a                	jne    f0101a36 <memmove+0x6a>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f0101a2c:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f0101a2f:	89 c7                	mov    %eax,%edi
f0101a31:	fc                   	cld    
f0101a32:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101a34:	eb 05                	jmp    f0101a3b <memmove+0x6f>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0101a36:	89 c7                	mov    %eax,%edi
f0101a38:	fc                   	cld    
f0101a39:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f0101a3b:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0101a3e:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0101a41:	89 ec                	mov    %ebp,%esp
f0101a43:	5d                   	pop    %ebp
f0101a44:	c3                   	ret    

f0101a45 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0101a45:	55                   	push   %ebp
f0101a46:	89 e5                	mov    %esp,%ebp
f0101a48:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f0101a4b:	8b 45 10             	mov    0x10(%ebp),%eax
f0101a4e:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101a52:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101a55:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101a59:	8b 45 08             	mov    0x8(%ebp),%eax
f0101a5c:	89 04 24             	mov    %eax,(%esp)
f0101a5f:	e8 68 ff ff ff       	call   f01019cc <memmove>
}
f0101a64:	c9                   	leave  
f0101a65:	c3                   	ret    

f0101a66 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0101a66:	55                   	push   %ebp
f0101a67:	89 e5                	mov    %esp,%ebp
f0101a69:	57                   	push   %edi
f0101a6a:	56                   	push   %esi
f0101a6b:	53                   	push   %ebx
f0101a6c:	8b 5d 08             	mov    0x8(%ebp),%ebx
f0101a6f:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101a72:	8b 7d 10             	mov    0x10(%ebp),%edi
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0101a75:	b8 00 00 00 00       	mov    $0x0,%eax
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101a7a:	85 ff                	test   %edi,%edi
f0101a7c:	74 37                	je     f0101ab5 <memcmp+0x4f>
		if (*s1 != *s2)
f0101a7e:	0f b6 03             	movzbl (%ebx),%eax
f0101a81:	0f b6 0e             	movzbl (%esi),%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101a84:	83 ef 01             	sub    $0x1,%edi
f0101a87:	ba 00 00 00 00       	mov    $0x0,%edx
		if (*s1 != *s2)
f0101a8c:	38 c8                	cmp    %cl,%al
f0101a8e:	74 1c                	je     f0101aac <memcmp+0x46>
f0101a90:	eb 10                	jmp    f0101aa2 <memcmp+0x3c>
f0101a92:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
f0101a97:	83 c2 01             	add    $0x1,%edx
f0101a9a:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
f0101a9e:	38 c8                	cmp    %cl,%al
f0101aa0:	74 0a                	je     f0101aac <memcmp+0x46>
			return (int) *s1 - (int) *s2;
f0101aa2:	0f b6 c0             	movzbl %al,%eax
f0101aa5:	0f b6 c9             	movzbl %cl,%ecx
f0101aa8:	29 c8                	sub    %ecx,%eax
f0101aaa:	eb 09                	jmp    f0101ab5 <memcmp+0x4f>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101aac:	39 fa                	cmp    %edi,%edx
f0101aae:	75 e2                	jne    f0101a92 <memcmp+0x2c>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0101ab0:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101ab5:	5b                   	pop    %ebx
f0101ab6:	5e                   	pop    %esi
f0101ab7:	5f                   	pop    %edi
f0101ab8:	5d                   	pop    %ebp
f0101ab9:	c3                   	ret    

f0101aba <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f0101aba:	55                   	push   %ebp
f0101abb:	89 e5                	mov    %esp,%ebp
f0101abd:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f0101ac0:	89 c2                	mov    %eax,%edx
f0101ac2:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f0101ac5:	39 d0                	cmp    %edx,%eax
f0101ac7:	73 19                	jae    f0101ae2 <memfind+0x28>
		if (*(const unsigned char *) s == (unsigned char) c)
f0101ac9:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
f0101acd:	38 08                	cmp    %cl,(%eax)
f0101acf:	75 06                	jne    f0101ad7 <memfind+0x1d>
f0101ad1:	eb 0f                	jmp    f0101ae2 <memfind+0x28>
f0101ad3:	38 08                	cmp    %cl,(%eax)
f0101ad5:	74 0b                	je     f0101ae2 <memfind+0x28>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f0101ad7:	83 c0 01             	add    $0x1,%eax
f0101ada:	39 d0                	cmp    %edx,%eax
f0101adc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101ae0:	75 f1                	jne    f0101ad3 <memfind+0x19>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f0101ae2:	5d                   	pop    %ebp
f0101ae3:	c3                   	ret    

f0101ae4 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f0101ae4:	55                   	push   %ebp
f0101ae5:	89 e5                	mov    %esp,%ebp
f0101ae7:	57                   	push   %edi
f0101ae8:	56                   	push   %esi
f0101ae9:	53                   	push   %ebx
f0101aea:	8b 55 08             	mov    0x8(%ebp),%edx
f0101aed:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101af0:	0f b6 02             	movzbl (%edx),%eax
f0101af3:	3c 20                	cmp    $0x20,%al
f0101af5:	74 04                	je     f0101afb <strtol+0x17>
f0101af7:	3c 09                	cmp    $0x9,%al
f0101af9:	75 0e                	jne    f0101b09 <strtol+0x25>
		s++;
f0101afb:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f0101afe:	0f b6 02             	movzbl (%edx),%eax
f0101b01:	3c 20                	cmp    $0x20,%al
f0101b03:	74 f6                	je     f0101afb <strtol+0x17>
f0101b05:	3c 09                	cmp    $0x9,%al
f0101b07:	74 f2                	je     f0101afb <strtol+0x17>
		s++;

	// plus/minus sign
	if (*s == '+')
f0101b09:	3c 2b                	cmp    $0x2b,%al
f0101b0b:	75 0a                	jne    f0101b17 <strtol+0x33>
		s++;
f0101b0d:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0101b10:	bf 00 00 00 00       	mov    $0x0,%edi
f0101b15:	eb 10                	jmp    f0101b27 <strtol+0x43>
f0101b17:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0101b1c:	3c 2d                	cmp    $0x2d,%al
f0101b1e:	75 07                	jne    f0101b27 <strtol+0x43>
		s++, neg = 1;
f0101b20:	83 c2 01             	add    $0x1,%edx
f0101b23:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0101b27:	85 db                	test   %ebx,%ebx
f0101b29:	0f 94 c0             	sete   %al
f0101b2c:	74 05                	je     f0101b33 <strtol+0x4f>
f0101b2e:	83 fb 10             	cmp    $0x10,%ebx
f0101b31:	75 15                	jne    f0101b48 <strtol+0x64>
f0101b33:	80 3a 30             	cmpb   $0x30,(%edx)
f0101b36:	75 10                	jne    f0101b48 <strtol+0x64>
f0101b38:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0101b3c:	75 0a                	jne    f0101b48 <strtol+0x64>
		s += 2, base = 16;
f0101b3e:	83 c2 02             	add    $0x2,%edx
f0101b41:	bb 10 00 00 00       	mov    $0x10,%ebx
f0101b46:	eb 13                	jmp    f0101b5b <strtol+0x77>
	else if (base == 0 && s[0] == '0')
f0101b48:	84 c0                	test   %al,%al
f0101b4a:	74 0f                	je     f0101b5b <strtol+0x77>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0101b4c:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101b51:	80 3a 30             	cmpb   $0x30,(%edx)
f0101b54:	75 05                	jne    f0101b5b <strtol+0x77>
		s++, base = 8;
f0101b56:	83 c2 01             	add    $0x1,%edx
f0101b59:	b3 08                	mov    $0x8,%bl
	else if (base == 0)
		base = 10;
f0101b5b:	b8 00 00 00 00       	mov    $0x0,%eax
f0101b60:	89 de                	mov    %ebx,%esi

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0101b62:	0f b6 0a             	movzbl (%edx),%ecx
f0101b65:	8d 59 d0             	lea    -0x30(%ecx),%ebx
f0101b68:	80 fb 09             	cmp    $0x9,%bl
f0101b6b:	77 08                	ja     f0101b75 <strtol+0x91>
			dig = *s - '0';
f0101b6d:	0f be c9             	movsbl %cl,%ecx
f0101b70:	83 e9 30             	sub    $0x30,%ecx
f0101b73:	eb 1e                	jmp    f0101b93 <strtol+0xaf>
		else if (*s >= 'a' && *s <= 'z')
f0101b75:	8d 59 9f             	lea    -0x61(%ecx),%ebx
f0101b78:	80 fb 19             	cmp    $0x19,%bl
f0101b7b:	77 08                	ja     f0101b85 <strtol+0xa1>
			dig = *s - 'a' + 10;
f0101b7d:	0f be c9             	movsbl %cl,%ecx
f0101b80:	83 e9 57             	sub    $0x57,%ecx
f0101b83:	eb 0e                	jmp    f0101b93 <strtol+0xaf>
		else if (*s >= 'A' && *s <= 'Z')
f0101b85:	8d 59 bf             	lea    -0x41(%ecx),%ebx
f0101b88:	80 fb 19             	cmp    $0x19,%bl
f0101b8b:	77 14                	ja     f0101ba1 <strtol+0xbd>
			dig = *s - 'A' + 10;
f0101b8d:	0f be c9             	movsbl %cl,%ecx
f0101b90:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0101b93:	39 f1                	cmp    %esi,%ecx
f0101b95:	7d 0e                	jge    f0101ba5 <strtol+0xc1>
			break;
		s++, val = (val * base) + dig;
f0101b97:	83 c2 01             	add    $0x1,%edx
f0101b9a:	0f af c6             	imul   %esi,%eax
f0101b9d:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
f0101b9f:	eb c1                	jmp    f0101b62 <strtol+0x7e>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
f0101ba1:	89 c1                	mov    %eax,%ecx
f0101ba3:	eb 02                	jmp    f0101ba7 <strtol+0xc3>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0101ba5:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
f0101ba7:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0101bab:	74 05                	je     f0101bb2 <strtol+0xce>
		*endptr = (char *) s;
f0101bad:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101bb0:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
f0101bb2:	89 ca                	mov    %ecx,%edx
f0101bb4:	f7 da                	neg    %edx
f0101bb6:	85 ff                	test   %edi,%edi
f0101bb8:	0f 45 c2             	cmovne %edx,%eax
}
f0101bbb:	5b                   	pop    %ebx
f0101bbc:	5e                   	pop    %esi
f0101bbd:	5f                   	pop    %edi
f0101bbe:	5d                   	pop    %ebp
f0101bbf:	c3                   	ret    

f0101bc0 <__udivdi3>:
f0101bc0:	83 ec 1c             	sub    $0x1c,%esp
f0101bc3:	89 7c 24 14          	mov    %edi,0x14(%esp)
f0101bc7:	8b 7c 24 2c          	mov    0x2c(%esp),%edi
f0101bcb:	8b 44 24 20          	mov    0x20(%esp),%eax
f0101bcf:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0101bd3:	89 74 24 10          	mov    %esi,0x10(%esp)
f0101bd7:	8b 74 24 24          	mov    0x24(%esp),%esi
f0101bdb:	85 ff                	test   %edi,%edi
f0101bdd:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f0101be1:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101be5:	89 cd                	mov    %ecx,%ebp
f0101be7:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101beb:	75 33                	jne    f0101c20 <__udivdi3+0x60>
f0101bed:	39 f1                	cmp    %esi,%ecx
f0101bef:	77 57                	ja     f0101c48 <__udivdi3+0x88>
f0101bf1:	85 c9                	test   %ecx,%ecx
f0101bf3:	75 0b                	jne    f0101c00 <__udivdi3+0x40>
f0101bf5:	b8 01 00 00 00       	mov    $0x1,%eax
f0101bfa:	31 d2                	xor    %edx,%edx
f0101bfc:	f7 f1                	div    %ecx
f0101bfe:	89 c1                	mov    %eax,%ecx
f0101c00:	89 f0                	mov    %esi,%eax
f0101c02:	31 d2                	xor    %edx,%edx
f0101c04:	f7 f1                	div    %ecx
f0101c06:	89 c6                	mov    %eax,%esi
f0101c08:	8b 44 24 04          	mov    0x4(%esp),%eax
f0101c0c:	f7 f1                	div    %ecx
f0101c0e:	89 f2                	mov    %esi,%edx
f0101c10:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101c14:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101c18:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101c1c:	83 c4 1c             	add    $0x1c,%esp
f0101c1f:	c3                   	ret    
f0101c20:	31 d2                	xor    %edx,%edx
f0101c22:	31 c0                	xor    %eax,%eax
f0101c24:	39 f7                	cmp    %esi,%edi
f0101c26:	77 e8                	ja     f0101c10 <__udivdi3+0x50>
f0101c28:	0f bd cf             	bsr    %edi,%ecx
f0101c2b:	83 f1 1f             	xor    $0x1f,%ecx
f0101c2e:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0101c32:	75 2c                	jne    f0101c60 <__udivdi3+0xa0>
f0101c34:	3b 6c 24 08          	cmp    0x8(%esp),%ebp
f0101c38:	76 04                	jbe    f0101c3e <__udivdi3+0x7e>
f0101c3a:	39 f7                	cmp    %esi,%edi
f0101c3c:	73 d2                	jae    f0101c10 <__udivdi3+0x50>
f0101c3e:	31 d2                	xor    %edx,%edx
f0101c40:	b8 01 00 00 00       	mov    $0x1,%eax
f0101c45:	eb c9                	jmp    f0101c10 <__udivdi3+0x50>
f0101c47:	90                   	nop
f0101c48:	89 f2                	mov    %esi,%edx
f0101c4a:	f7 f1                	div    %ecx
f0101c4c:	31 d2                	xor    %edx,%edx
f0101c4e:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101c52:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101c56:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101c5a:	83 c4 1c             	add    $0x1c,%esp
f0101c5d:	c3                   	ret    
f0101c5e:	66 90                	xchg   %ax,%ax
f0101c60:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101c65:	b8 20 00 00 00       	mov    $0x20,%eax
f0101c6a:	89 ea                	mov    %ebp,%edx
f0101c6c:	2b 44 24 04          	sub    0x4(%esp),%eax
f0101c70:	d3 e7                	shl    %cl,%edi
f0101c72:	89 c1                	mov    %eax,%ecx
f0101c74:	d3 ea                	shr    %cl,%edx
f0101c76:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101c7b:	09 fa                	or     %edi,%edx
f0101c7d:	89 f7                	mov    %esi,%edi
f0101c7f:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101c83:	89 f2                	mov    %esi,%edx
f0101c85:	8b 74 24 08          	mov    0x8(%esp),%esi
f0101c89:	d3 e5                	shl    %cl,%ebp
f0101c8b:	89 c1                	mov    %eax,%ecx
f0101c8d:	d3 ef                	shr    %cl,%edi
f0101c8f:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101c94:	d3 e2                	shl    %cl,%edx
f0101c96:	89 c1                	mov    %eax,%ecx
f0101c98:	d3 ee                	shr    %cl,%esi
f0101c9a:	09 d6                	or     %edx,%esi
f0101c9c:	89 fa                	mov    %edi,%edx
f0101c9e:	89 f0                	mov    %esi,%eax
f0101ca0:	f7 74 24 0c          	divl   0xc(%esp)
f0101ca4:	89 d7                	mov    %edx,%edi
f0101ca6:	89 c6                	mov    %eax,%esi
f0101ca8:	f7 e5                	mul    %ebp
f0101caa:	39 d7                	cmp    %edx,%edi
f0101cac:	72 22                	jb     f0101cd0 <__udivdi3+0x110>
f0101cae:	8b 6c 24 08          	mov    0x8(%esp),%ebp
f0101cb2:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101cb7:	d3 e5                	shl    %cl,%ebp
f0101cb9:	39 c5                	cmp    %eax,%ebp
f0101cbb:	73 04                	jae    f0101cc1 <__udivdi3+0x101>
f0101cbd:	39 d7                	cmp    %edx,%edi
f0101cbf:	74 0f                	je     f0101cd0 <__udivdi3+0x110>
f0101cc1:	89 f0                	mov    %esi,%eax
f0101cc3:	31 d2                	xor    %edx,%edx
f0101cc5:	e9 46 ff ff ff       	jmp    f0101c10 <__udivdi3+0x50>
f0101cca:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101cd0:	8d 46 ff             	lea    -0x1(%esi),%eax
f0101cd3:	31 d2                	xor    %edx,%edx
f0101cd5:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101cd9:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101cdd:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101ce1:	83 c4 1c             	add    $0x1c,%esp
f0101ce4:	c3                   	ret    
	...

f0101cf0 <__umoddi3>:
f0101cf0:	83 ec 1c             	sub    $0x1c,%esp
f0101cf3:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f0101cf7:	8b 6c 24 2c          	mov    0x2c(%esp),%ebp
f0101cfb:	8b 44 24 20          	mov    0x20(%esp),%eax
f0101cff:	89 74 24 10          	mov    %esi,0x10(%esp)
f0101d03:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0101d07:	8b 74 24 24          	mov    0x24(%esp),%esi
f0101d0b:	85 ed                	test   %ebp,%ebp
f0101d0d:	89 7c 24 14          	mov    %edi,0x14(%esp)
f0101d11:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101d15:	89 cf                	mov    %ecx,%edi
f0101d17:	89 04 24             	mov    %eax,(%esp)
f0101d1a:	89 f2                	mov    %esi,%edx
f0101d1c:	75 1a                	jne    f0101d38 <__umoddi3+0x48>
f0101d1e:	39 f1                	cmp    %esi,%ecx
f0101d20:	76 4e                	jbe    f0101d70 <__umoddi3+0x80>
f0101d22:	f7 f1                	div    %ecx
f0101d24:	89 d0                	mov    %edx,%eax
f0101d26:	31 d2                	xor    %edx,%edx
f0101d28:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101d2c:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101d30:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101d34:	83 c4 1c             	add    $0x1c,%esp
f0101d37:	c3                   	ret    
f0101d38:	39 f5                	cmp    %esi,%ebp
f0101d3a:	77 54                	ja     f0101d90 <__umoddi3+0xa0>
f0101d3c:	0f bd c5             	bsr    %ebp,%eax
f0101d3f:	83 f0 1f             	xor    $0x1f,%eax
f0101d42:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101d46:	75 60                	jne    f0101da8 <__umoddi3+0xb8>
f0101d48:	3b 0c 24             	cmp    (%esp),%ecx
f0101d4b:	0f 87 07 01 00 00    	ja     f0101e58 <__umoddi3+0x168>
f0101d51:	89 f2                	mov    %esi,%edx
f0101d53:	8b 34 24             	mov    (%esp),%esi
f0101d56:	29 ce                	sub    %ecx,%esi
f0101d58:	19 ea                	sbb    %ebp,%edx
f0101d5a:	89 34 24             	mov    %esi,(%esp)
f0101d5d:	8b 04 24             	mov    (%esp),%eax
f0101d60:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101d64:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101d68:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101d6c:	83 c4 1c             	add    $0x1c,%esp
f0101d6f:	c3                   	ret    
f0101d70:	85 c9                	test   %ecx,%ecx
f0101d72:	75 0b                	jne    f0101d7f <__umoddi3+0x8f>
f0101d74:	b8 01 00 00 00       	mov    $0x1,%eax
f0101d79:	31 d2                	xor    %edx,%edx
f0101d7b:	f7 f1                	div    %ecx
f0101d7d:	89 c1                	mov    %eax,%ecx
f0101d7f:	89 f0                	mov    %esi,%eax
f0101d81:	31 d2                	xor    %edx,%edx
f0101d83:	f7 f1                	div    %ecx
f0101d85:	8b 04 24             	mov    (%esp),%eax
f0101d88:	f7 f1                	div    %ecx
f0101d8a:	eb 98                	jmp    f0101d24 <__umoddi3+0x34>
f0101d8c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101d90:	89 f2                	mov    %esi,%edx
f0101d92:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101d96:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101d9a:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101d9e:	83 c4 1c             	add    $0x1c,%esp
f0101da1:	c3                   	ret    
f0101da2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101da8:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101dad:	89 e8                	mov    %ebp,%eax
f0101daf:	bd 20 00 00 00       	mov    $0x20,%ebp
f0101db4:	2b 6c 24 04          	sub    0x4(%esp),%ebp
f0101db8:	89 fa                	mov    %edi,%edx
f0101dba:	d3 e0                	shl    %cl,%eax
f0101dbc:	89 e9                	mov    %ebp,%ecx
f0101dbe:	d3 ea                	shr    %cl,%edx
f0101dc0:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101dc5:	09 c2                	or     %eax,%edx
f0101dc7:	8b 44 24 08          	mov    0x8(%esp),%eax
f0101dcb:	89 14 24             	mov    %edx,(%esp)
f0101dce:	89 f2                	mov    %esi,%edx
f0101dd0:	d3 e7                	shl    %cl,%edi
f0101dd2:	89 e9                	mov    %ebp,%ecx
f0101dd4:	d3 ea                	shr    %cl,%edx
f0101dd6:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101ddb:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101ddf:	d3 e6                	shl    %cl,%esi
f0101de1:	89 e9                	mov    %ebp,%ecx
f0101de3:	d3 e8                	shr    %cl,%eax
f0101de5:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101dea:	09 f0                	or     %esi,%eax
f0101dec:	8b 74 24 08          	mov    0x8(%esp),%esi
f0101df0:	f7 34 24             	divl   (%esp)
f0101df3:	d3 e6                	shl    %cl,%esi
f0101df5:	89 74 24 08          	mov    %esi,0x8(%esp)
f0101df9:	89 d6                	mov    %edx,%esi
f0101dfb:	f7 e7                	mul    %edi
f0101dfd:	39 d6                	cmp    %edx,%esi
f0101dff:	89 c1                	mov    %eax,%ecx
f0101e01:	89 d7                	mov    %edx,%edi
f0101e03:	72 3f                	jb     f0101e44 <__umoddi3+0x154>
f0101e05:	39 44 24 08          	cmp    %eax,0x8(%esp)
f0101e09:	72 35                	jb     f0101e40 <__umoddi3+0x150>
f0101e0b:	8b 44 24 08          	mov    0x8(%esp),%eax
f0101e0f:	29 c8                	sub    %ecx,%eax
f0101e11:	19 fe                	sbb    %edi,%esi
f0101e13:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101e18:	89 f2                	mov    %esi,%edx
f0101e1a:	d3 e8                	shr    %cl,%eax
f0101e1c:	89 e9                	mov    %ebp,%ecx
f0101e1e:	d3 e2                	shl    %cl,%edx
f0101e20:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101e25:	09 d0                	or     %edx,%eax
f0101e27:	89 f2                	mov    %esi,%edx
f0101e29:	d3 ea                	shr    %cl,%edx
f0101e2b:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101e2f:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101e33:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101e37:	83 c4 1c             	add    $0x1c,%esp
f0101e3a:	c3                   	ret    
f0101e3b:	90                   	nop
f0101e3c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101e40:	39 d6                	cmp    %edx,%esi
f0101e42:	75 c7                	jne    f0101e0b <__umoddi3+0x11b>
f0101e44:	89 d7                	mov    %edx,%edi
f0101e46:	89 c1                	mov    %eax,%ecx
f0101e48:	2b 4c 24 0c          	sub    0xc(%esp),%ecx
f0101e4c:	1b 3c 24             	sbb    (%esp),%edi
f0101e4f:	eb ba                	jmp    f0101e0b <__umoddi3+0x11b>
f0101e51:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101e58:	39 f5                	cmp    %esi,%ebp
f0101e5a:	0f 82 f1 fe ff ff    	jb     f0101d51 <__umoddi3+0x61>
f0101e60:	e9 f8 fe ff ff       	jmp    f0101d5d <__umoddi3+0x6d>
