
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
f0100055:	e8 5c 0c 00 00       	call   f0100cb6 <cprintf>
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
f0100082:	e8 02 07 00 00       	call   f0100789 <mon_backtrace>
	cprintf("leaving test_backtrace %d\n", x);
f0100087:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010008b:	c7 04 24 9c 1d 10 f0 	movl   $0xf0101d9c,(%esp)
f0100092:	e8 1f 0c 00 00       	call   f0100cb6 <cprintf>
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
f01000c0:	e8 ac 17 00 00       	call   f0101871 <memset>

	// Initialize the console.
	// Can't call cprintf until after we do this!
	cons_init();
f01000c5:	e8 8a 04 00 00       	call   f0100554 <cons_init>
	// Test the stack backtrace function (lab 1 only)
	test_backtrace(5);
f01000ca:	c7 04 24 05 00 00 00 	movl   $0x5,(%esp)
f01000d1:	e8 6a ff ff ff       	call   f0100040 <test_backtrace>

	// Drop into the kernel monitor.
	while (1)
		monitor(NULL);
f01000d6:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01000dd:	e8 10 0a 00 00       	call   f0100af2 <monitor>
f01000e2:	eb f2                	jmp    f01000d6 <i386_init+0x39>

f01000e4 <_panic>:
 * Panic is called on unresolvable fatal errors.
 * It prints "panic: mesg", and then enters the kernel monitor.
 */
void
_panic(const char *file, int line, const char *fmt,...)
{
f01000e4:	55                   	push   %ebp
f01000e5:	89 e5                	mov    %esp,%ebp
f01000e7:	56                   	push   %esi
f01000e8:	53                   	push   %ebx
f01000e9:	83 ec 10             	sub    $0x10,%esp
f01000ec:	8b 75 10             	mov    0x10(%ebp),%esi
	va_list ap;

	if (panicstr)
f01000ef:	83 3d 60 39 11 f0 00 	cmpl   $0x0,0xf0113960
f01000f6:	75 3d                	jne    f0100135 <_panic+0x51>
		goto dead;
	panicstr = fmt;
f01000f8:	89 35 60 39 11 f0    	mov    %esi,0xf0113960

	// Be extra sure that the machine is in as reasonable state
	__asm __volatile("cli; cld");
f01000fe:	fa                   	cli    
f01000ff:	fc                   	cld    

	va_start(ap, fmt);
f0100100:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel panic at %s:%d: ", file, line);
f0100103:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100106:	89 44 24 08          	mov    %eax,0x8(%esp)
f010010a:	8b 45 08             	mov    0x8(%ebp),%eax
f010010d:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100111:	c7 04 24 b7 1d 10 f0 	movl   $0xf0101db7,(%esp)
f0100118:	e8 99 0b 00 00       	call   f0100cb6 <cprintf>
	vcprintf(fmt, ap);
f010011d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100121:	89 34 24             	mov    %esi,(%esp)
f0100124:	e8 5a 0b 00 00       	call   f0100c83 <vcprintf>
	cprintf("\n");
f0100129:	c7 04 24 f3 1d 10 f0 	movl   $0xf0101df3,(%esp)
f0100130:	e8 81 0b 00 00       	call   f0100cb6 <cprintf>
	va_end(ap);

dead:
	/* break into the kernel monitor */
	while (1)
		monitor(NULL);
f0100135:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f010013c:	e8 b1 09 00 00       	call   f0100af2 <monitor>
f0100141:	eb f2                	jmp    f0100135 <_panic+0x51>

f0100143 <_warn>:
}

/* like panic, but don't */
void
_warn(const char *file, int line, const char *fmt,...)
{
f0100143:	55                   	push   %ebp
f0100144:	89 e5                	mov    %esp,%ebp
f0100146:	53                   	push   %ebx
f0100147:	83 ec 14             	sub    $0x14,%esp
	va_list ap;

	va_start(ap, fmt);
f010014a:	8d 5d 14             	lea    0x14(%ebp),%ebx
	cprintf("kernel warning at %s:%d: ", file, line);
f010014d:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100150:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100154:	8b 45 08             	mov    0x8(%ebp),%eax
f0100157:	89 44 24 04          	mov    %eax,0x4(%esp)
f010015b:	c7 04 24 cf 1d 10 f0 	movl   $0xf0101dcf,(%esp)
f0100162:	e8 4f 0b 00 00       	call   f0100cb6 <cprintf>
	vcprintf(fmt, ap);
f0100167:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010016b:	8b 45 10             	mov    0x10(%ebp),%eax
f010016e:	89 04 24             	mov    %eax,(%esp)
f0100171:	e8 0d 0b 00 00       	call   f0100c83 <vcprintf>
	cprintf("\n");
f0100176:	c7 04 24 f3 1d 10 f0 	movl   $0xf0101df3,(%esp)
f010017d:	e8 34 0b 00 00       	call   f0100cb6 <cprintf>
	va_end(ap);
}
f0100182:	83 c4 14             	add    $0x14,%esp
f0100185:	5b                   	pop    %ebx
f0100186:	5d                   	pop    %ebp
f0100187:	c3                   	ret    
	...

f0100190 <delay>:
static void cons_putc(int c);

// Stupid I/O delay routine necessitated by historical PC design flaws
static void
delay(void)
{
f0100190:	55                   	push   %ebp
f0100191:	89 e5                	mov    %esp,%ebp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100193:	ba 84 00 00 00       	mov    $0x84,%edx
f0100198:	ec                   	in     (%dx),%al
f0100199:	ec                   	in     (%dx),%al
f010019a:	ec                   	in     (%dx),%al
f010019b:	ec                   	in     (%dx),%al
	inb(0x84);
	inb(0x84);
	inb(0x84);
	inb(0x84);
}
f010019c:	5d                   	pop    %ebp
f010019d:	c3                   	ret    

f010019e <serial_proc_data>:

static bool serial_exists;

static int
serial_proc_data(void)
{
f010019e:	55                   	push   %ebp
f010019f:	89 e5                	mov    %esp,%ebp
f01001a1:	ba fd 03 00 00       	mov    $0x3fd,%edx
f01001a6:	ec                   	in     (%dx),%al
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
f01001a7:	b9 ff ff ff ff       	mov    $0xffffffff,%ecx
static bool serial_exists;

static int
serial_proc_data(void)
{
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
f01001ac:	a8 01                	test   $0x1,%al
f01001ae:	74 06                	je     f01001b6 <serial_proc_data+0x18>
f01001b0:	b2 f8                	mov    $0xf8,%dl
f01001b2:	ec                   	in     (%dx),%al
		return -1;
	return inb(COM1+COM_RX);
f01001b3:	0f b6 c8             	movzbl %al,%ecx
}
f01001b6:	89 c8                	mov    %ecx,%eax
f01001b8:	5d                   	pop    %ebp
f01001b9:	c3                   	ret    

f01001ba <cons_intr>:

// called by device interrupt routines to feed input characters
// into the circular console input buffer.
static void
cons_intr(int (*proc)(void))
{
f01001ba:	55                   	push   %ebp
f01001bb:	89 e5                	mov    %esp,%ebp
f01001bd:	53                   	push   %ebx
f01001be:	83 ec 04             	sub    $0x4,%esp
f01001c1:	89 c3                	mov    %eax,%ebx
	int c;

	while ((c = (*proc)()) != -1) {
f01001c3:	eb 25                	jmp    f01001ea <cons_intr+0x30>
		if (c == 0)
f01001c5:	85 c0                	test   %eax,%eax
f01001c7:	74 21                	je     f01001ea <cons_intr+0x30>
			continue;
		cons.buf[cons.wpos++] = c;
f01001c9:	8b 15 44 35 11 f0    	mov    0xf0113544,%edx
f01001cf:	88 82 40 33 11 f0    	mov    %al,-0xfeeccc0(%edx)
f01001d5:	8d 42 01             	lea    0x1(%edx),%eax
		if (cons.wpos == CONSBUFSIZE)
f01001d8:	3d 00 02 00 00       	cmp    $0x200,%eax
			cons.wpos = 0;
f01001dd:	ba 00 00 00 00       	mov    $0x0,%edx
f01001e2:	0f 44 c2             	cmove  %edx,%eax
f01001e5:	a3 44 35 11 f0       	mov    %eax,0xf0113544
static void
cons_intr(int (*proc)(void))
{
	int c;

	while ((c = (*proc)()) != -1) {
f01001ea:	ff d3                	call   *%ebx
f01001ec:	83 f8 ff             	cmp    $0xffffffff,%eax
f01001ef:	75 d4                	jne    f01001c5 <cons_intr+0xb>
			continue;
		cons.buf[cons.wpos++] = c;
		if (cons.wpos == CONSBUFSIZE)
			cons.wpos = 0;
	}
}
f01001f1:	83 c4 04             	add    $0x4,%esp
f01001f4:	5b                   	pop    %ebx
f01001f5:	5d                   	pop    %ebp
f01001f6:	c3                   	ret    

f01001f7 <cons_putc>:
}

// output a character to the console
static void
cons_putc(int c)
{
f01001f7:	55                   	push   %ebp
f01001f8:	89 e5                	mov    %esp,%ebp
f01001fa:	57                   	push   %edi
f01001fb:	56                   	push   %esi
f01001fc:	53                   	push   %ebx
f01001fd:	83 ec 2c             	sub    $0x2c,%esp
f0100200:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f0100203:	ba fd 03 00 00       	mov    $0x3fd,%edx
f0100208:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f0100209:	a8 20                	test   $0x20,%al
f010020b:	75 1b                	jne    f0100228 <cons_putc+0x31>
f010020d:	bb 00 32 00 00       	mov    $0x3200,%ebx
f0100212:	be fd 03 00 00       	mov    $0x3fd,%esi
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
	     i++)
		delay();
f0100217:	e8 74 ff ff ff       	call   f0100190 <delay>
f010021c:	89 f2                	mov    %esi,%edx
f010021e:	ec                   	in     (%dx),%al
static void
serial_putc(int c)
{
	int i;

	for (i = 0;
f010021f:	a8 20                	test   $0x20,%al
f0100221:	75 05                	jne    f0100228 <cons_putc+0x31>
	     !(inb(COM1 + COM_LSR) & COM_LSR_TXRDY) && i < 12800;
f0100223:	83 eb 01             	sub    $0x1,%ebx
f0100226:	75 ef                	jne    f0100217 <cons_putc+0x20>
	     i++)
		delay();

	outb(COM1 + COM_TX, c);
f0100228:	0f b6 7d e4          	movzbl -0x1c(%ebp),%edi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f010022c:	ba f8 03 00 00       	mov    $0x3f8,%edx
f0100231:	89 f8                	mov    %edi,%eax
f0100233:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f0100234:	b2 79                	mov    $0x79,%dl
f0100236:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f0100237:	84 c0                	test   %al,%al
f0100239:	78 1b                	js     f0100256 <cons_putc+0x5f>
f010023b:	bb 00 32 00 00       	mov    $0x3200,%ebx
f0100240:	be 79 03 00 00       	mov    $0x379,%esi
		delay();
f0100245:	e8 46 ff ff ff       	call   f0100190 <delay>
f010024a:	89 f2                	mov    %esi,%edx
f010024c:	ec                   	in     (%dx),%al
static void
lpt_putc(int c)
{
	int i;

	for (i = 0; !(inb(0x378+1) & 0x80) && i < 12800; i++)
f010024d:	84 c0                	test   %al,%al
f010024f:	78 05                	js     f0100256 <cons_putc+0x5f>
f0100251:	83 eb 01             	sub    $0x1,%ebx
f0100254:	75 ef                	jne    f0100245 <cons_putc+0x4e>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f0100256:	ba 78 03 00 00       	mov    $0x378,%edx
f010025b:	89 f8                	mov    %edi,%eax
f010025d:	ee                   	out    %al,(%dx)
f010025e:	b2 7a                	mov    $0x7a,%dl
f0100260:	b8 0d 00 00 00       	mov    $0xd,%eax
f0100265:	ee                   	out    %al,(%dx)
f0100266:	b8 08 00 00 00       	mov    $0x8,%eax
f010026b:	ee                   	out    %al,(%dx)

static void
cga_putc(int c)
{
	// if no attribute given, then use black on white
	c = c + attribute_color;
f010026c:	0f b7 15 00 30 11 f0 	movzwl 0xf0113000,%edx
f0100273:	03 55 e4             	add    -0x1c(%ebp),%edx
	//if (!(c & ~0xFF))
	//	c |= 0x0700;

	switch (c & 0xff) {
f0100276:	0f b6 c2             	movzbl %dl,%eax
f0100279:	83 f8 09             	cmp    $0x9,%eax
f010027c:	74 77                	je     f01002f5 <cons_putc+0xfe>
f010027e:	83 f8 09             	cmp    $0x9,%eax
f0100281:	7f 0f                	jg     f0100292 <cons_putc+0x9b>
f0100283:	83 f8 08             	cmp    $0x8,%eax
f0100286:	0f 85 9d 00 00 00    	jne    f0100329 <cons_putc+0x132>
f010028c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0100290:	eb 10                	jmp    f01002a2 <cons_putc+0xab>
f0100292:	83 f8 0a             	cmp    $0xa,%eax
f0100295:	74 38                	je     f01002cf <cons_putc+0xd8>
f0100297:	83 f8 0d             	cmp    $0xd,%eax
f010029a:	0f 85 89 00 00 00    	jne    f0100329 <cons_putc+0x132>
f01002a0:	eb 35                	jmp    f01002d7 <cons_putc+0xe0>
	case '\b':
		if (crt_pos > 0) {
f01002a2:	0f b7 05 54 35 11 f0 	movzwl 0xf0113554,%eax
f01002a9:	66 85 c0             	test   %ax,%ax
f01002ac:	0f 84 e1 00 00 00    	je     f0100393 <cons_putc+0x19c>
			crt_pos--;
f01002b2:	83 e8 01             	sub    $0x1,%eax
f01002b5:	66 a3 54 35 11 f0    	mov    %ax,0xf0113554
			crt_buf[crt_pos] = (c & ~0xff) | ' ';
f01002bb:	0f b7 c0             	movzwl %ax,%eax
f01002be:	b2 00                	mov    $0x0,%dl
f01002c0:	83 ca 20             	or     $0x20,%edx
f01002c3:	8b 0d 50 35 11 f0    	mov    0xf0113550,%ecx
f01002c9:	66 89 14 41          	mov    %dx,(%ecx,%eax,2)
f01002cd:	eb 77                	jmp    f0100346 <cons_putc+0x14f>
		}
		break;
	case '\n':
		crt_pos += CRT_COLS;
f01002cf:	66 83 05 54 35 11 f0 	addw   $0x50,0xf0113554
f01002d6:	50 
		/* fallthru */
	case '\r':
		crt_pos -= (crt_pos % CRT_COLS);
f01002d7:	0f b7 05 54 35 11 f0 	movzwl 0xf0113554,%eax
f01002de:	69 c0 cd cc 00 00    	imul   $0xcccd,%eax,%eax
f01002e4:	c1 e8 16             	shr    $0x16,%eax
f01002e7:	8d 04 80             	lea    (%eax,%eax,4),%eax
f01002ea:	c1 e0 04             	shl    $0x4,%eax
f01002ed:	66 a3 54 35 11 f0    	mov    %ax,0xf0113554
f01002f3:	eb 51                	jmp    f0100346 <cons_putc+0x14f>
		break;
	case '\t':
		cons_putc(' ');
f01002f5:	b8 20 00 00 00       	mov    $0x20,%eax
f01002fa:	e8 f8 fe ff ff       	call   f01001f7 <cons_putc>
		cons_putc(' ');
f01002ff:	b8 20 00 00 00       	mov    $0x20,%eax
f0100304:	e8 ee fe ff ff       	call   f01001f7 <cons_putc>
		cons_putc(' ');
f0100309:	b8 20 00 00 00       	mov    $0x20,%eax
f010030e:	e8 e4 fe ff ff       	call   f01001f7 <cons_putc>
		cons_putc(' ');
f0100313:	b8 20 00 00 00       	mov    $0x20,%eax
f0100318:	e8 da fe ff ff       	call   f01001f7 <cons_putc>
		cons_putc(' ');
f010031d:	b8 20 00 00 00       	mov    $0x20,%eax
f0100322:	e8 d0 fe ff ff       	call   f01001f7 <cons_putc>
f0100327:	eb 1d                	jmp    f0100346 <cons_putc+0x14f>
		break;
	default:
		crt_buf[crt_pos++] = c;		/* write the character */
f0100329:	0f b7 05 54 35 11 f0 	movzwl 0xf0113554,%eax
f0100330:	0f b7 d8             	movzwl %ax,%ebx
f0100333:	8b 0d 50 35 11 f0    	mov    0xf0113550,%ecx
f0100339:	66 89 14 59          	mov    %dx,(%ecx,%ebx,2)
f010033d:	83 c0 01             	add    $0x1,%eax
f0100340:	66 a3 54 35 11 f0    	mov    %ax,0xf0113554
		break;
	}

	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
f0100346:	66 81 3d 54 35 11 f0 	cmpw   $0x7cf,0xf0113554
f010034d:	cf 07 
f010034f:	76 42                	jbe    f0100393 <cons_putc+0x19c>
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
f0100351:	a1 50 35 11 f0       	mov    0xf0113550,%eax
f0100356:	c7 44 24 08 00 0f 00 	movl   $0xf00,0x8(%esp)
f010035d:	00 
f010035e:	8d 90 a0 00 00 00    	lea    0xa0(%eax),%edx
f0100364:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100368:	89 04 24             	mov    %eax,(%esp)
f010036b:	e8 5c 15 00 00       	call   f01018cc <memmove>
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
			crt_buf[i] = 0x0700 | ' ';
f0100370:	8b 15 50 35 11 f0    	mov    0xf0113550,%edx
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100376:	b8 80 07 00 00       	mov    $0x780,%eax
			crt_buf[i] = 0x0700 | ' ';
f010037b:	66 c7 04 42 20 07    	movw   $0x720,(%edx,%eax,2)
	// What is the purpose of this?
	if (crt_pos >= CRT_SIZE) {
		int i;

		memmove(crt_buf, crt_buf + CRT_COLS, (CRT_SIZE - CRT_COLS) * sizeof(uint16_t));
		for (i = CRT_SIZE - CRT_COLS; i < CRT_SIZE; i++)
f0100381:	83 c0 01             	add    $0x1,%eax
f0100384:	3d d0 07 00 00       	cmp    $0x7d0,%eax
f0100389:	75 f0                	jne    f010037b <cons_putc+0x184>
			crt_buf[i] = 0x0700 | ' ';
		crt_pos -= CRT_COLS;
f010038b:	66 83 2d 54 35 11 f0 	subw   $0x50,0xf0113554
f0100392:	50 
	}

	/* move that little blinky thing */
	outb(addr_6845, 14);
f0100393:	8b 0d 4c 35 11 f0    	mov    0xf011354c,%ecx
f0100399:	b8 0e 00 00 00       	mov    $0xe,%eax
f010039e:	89 ca                	mov    %ecx,%edx
f01003a0:	ee                   	out    %al,(%dx)
	outb(addr_6845 + 1, crt_pos >> 8);
f01003a1:	0f b7 35 54 35 11 f0 	movzwl 0xf0113554,%esi
f01003a8:	8d 59 01             	lea    0x1(%ecx),%ebx
f01003ab:	89 f0                	mov    %esi,%eax
f01003ad:	66 c1 e8 08          	shr    $0x8,%ax
f01003b1:	89 da                	mov    %ebx,%edx
f01003b3:	ee                   	out    %al,(%dx)
f01003b4:	b8 0f 00 00 00       	mov    $0xf,%eax
f01003b9:	89 ca                	mov    %ecx,%edx
f01003bb:	ee                   	out    %al,(%dx)
f01003bc:	89 f0                	mov    %esi,%eax
f01003be:	89 da                	mov    %ebx,%edx
f01003c0:	ee                   	out    %al,(%dx)
cons_putc(int c)
{
	serial_putc(c);
	lpt_putc(c);
	cga_putc(c);
}
f01003c1:	83 c4 2c             	add    $0x2c,%esp
f01003c4:	5b                   	pop    %ebx
f01003c5:	5e                   	pop    %esi
f01003c6:	5f                   	pop    %edi
f01003c7:	5d                   	pop    %ebp
f01003c8:	c3                   	ret    

f01003c9 <kbd_proc_data>:
 * Get data from the keyboard.  If we finish a character, return it.  Else 0.
 * Return -1 if no data.
 */
static int
kbd_proc_data(void)
{
f01003c9:	55                   	push   %ebp
f01003ca:	89 e5                	mov    %esp,%ebp
f01003cc:	53                   	push   %ebx
f01003cd:	83 ec 14             	sub    $0x14,%esp

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01003d0:	ba 64 00 00 00       	mov    $0x64,%edx
f01003d5:	ec                   	in     (%dx),%al
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
		return -1;
f01003d6:	bb ff ff ff ff       	mov    $0xffffffff,%ebx
{
	int c;
	uint8_t data;
	static uint32_t shift;

	if ((inb(KBSTATP) & KBS_DIB) == 0)
f01003db:	a8 01                	test   $0x1,%al
f01003dd:	0f 84 de 00 00 00    	je     f01004c1 <kbd_proc_data+0xf8>
f01003e3:	b2 60                	mov    $0x60,%dl
f01003e5:	ec                   	in     (%dx),%al
f01003e6:	89 c2                	mov    %eax,%edx
		return -1;

	data = inb(KBDATAP);

	if (data == 0xE0) {
f01003e8:	3c e0                	cmp    $0xe0,%al
f01003ea:	75 11                	jne    f01003fd <kbd_proc_data+0x34>
		// E0 escape character
		shift |= E0ESC;
f01003ec:	83 0d 48 35 11 f0 40 	orl    $0x40,0xf0113548
		return 0;
f01003f3:	bb 00 00 00 00       	mov    $0x0,%ebx
f01003f8:	e9 c4 00 00 00       	jmp    f01004c1 <kbd_proc_data+0xf8>
	} else if (data & 0x80) {
f01003fd:	84 c0                	test   %al,%al
f01003ff:	79 37                	jns    f0100438 <kbd_proc_data+0x6f>
		// Key released
		data = (shift & E0ESC ? data : data & 0x7F);
f0100401:	8b 0d 48 35 11 f0    	mov    0xf0113548,%ecx
f0100407:	89 cb                	mov    %ecx,%ebx
f0100409:	83 e3 40             	and    $0x40,%ebx
f010040c:	83 e0 7f             	and    $0x7f,%eax
f010040f:	85 db                	test   %ebx,%ebx
f0100411:	0f 44 d0             	cmove  %eax,%edx
		shift &= ~(shiftcode[data] | E0ESC);
f0100414:	0f b6 d2             	movzbl %dl,%edx
f0100417:	0f b6 82 20 1e 10 f0 	movzbl -0xfefe1e0(%edx),%eax
f010041e:	83 c8 40             	or     $0x40,%eax
f0100421:	0f b6 c0             	movzbl %al,%eax
f0100424:	f7 d0                	not    %eax
f0100426:	21 c1                	and    %eax,%ecx
f0100428:	89 0d 48 35 11 f0    	mov    %ecx,0xf0113548
		return 0;
f010042e:	bb 00 00 00 00       	mov    $0x0,%ebx
f0100433:	e9 89 00 00 00       	jmp    f01004c1 <kbd_proc_data+0xf8>
	} else if (shift & E0ESC) {
f0100438:	8b 0d 48 35 11 f0    	mov    0xf0113548,%ecx
f010043e:	f6 c1 40             	test   $0x40,%cl
f0100441:	74 0e                	je     f0100451 <kbd_proc_data+0x88>
		// Last character was an E0 escape; or with 0x80
		data |= 0x80;
f0100443:	89 c2                	mov    %eax,%edx
f0100445:	83 ca 80             	or     $0xffffff80,%edx
		shift &= ~E0ESC;
f0100448:	83 e1 bf             	and    $0xffffffbf,%ecx
f010044b:	89 0d 48 35 11 f0    	mov    %ecx,0xf0113548
	}

	shift |= shiftcode[data];
f0100451:	0f b6 d2             	movzbl %dl,%edx
f0100454:	0f b6 82 20 1e 10 f0 	movzbl -0xfefe1e0(%edx),%eax
f010045b:	0b 05 48 35 11 f0    	or     0xf0113548,%eax
	shift ^= togglecode[data];
f0100461:	0f b6 8a 20 1f 10 f0 	movzbl -0xfefe0e0(%edx),%ecx
f0100468:	31 c8                	xor    %ecx,%eax
f010046a:	a3 48 35 11 f0       	mov    %eax,0xf0113548

	c = charcode[shift & (CTL | SHIFT)][data];
f010046f:	89 c1                	mov    %eax,%ecx
f0100471:	83 e1 03             	and    $0x3,%ecx
f0100474:	8b 0c 8d 20 20 10 f0 	mov    -0xfefdfe0(,%ecx,4),%ecx
f010047b:	0f b6 1c 11          	movzbl (%ecx,%edx,1),%ebx
	if (shift & CAPSLOCK) {
f010047f:	a8 08                	test   $0x8,%al
f0100481:	74 19                	je     f010049c <kbd_proc_data+0xd3>
		if ('a' <= c && c <= 'z')
f0100483:	8d 53 9f             	lea    -0x61(%ebx),%edx
f0100486:	83 fa 19             	cmp    $0x19,%edx
f0100489:	77 05                	ja     f0100490 <kbd_proc_data+0xc7>
			c += 'A' - 'a';
f010048b:	83 eb 20             	sub    $0x20,%ebx
f010048e:	eb 0c                	jmp    f010049c <kbd_proc_data+0xd3>
		else if ('A' <= c && c <= 'Z')
f0100490:	8d 4b bf             	lea    -0x41(%ebx),%ecx
			c += 'a' - 'A';
f0100493:	8d 53 20             	lea    0x20(%ebx),%edx
f0100496:	83 f9 19             	cmp    $0x19,%ecx
f0100499:	0f 46 da             	cmovbe %edx,%ebx
	}

	// Process special keys
	// Ctrl-Alt-Del: reboot
	if (!(~shift & (CTL | ALT)) && c == KEY_DEL) {
f010049c:	f7 d0                	not    %eax
f010049e:	a8 06                	test   $0x6,%al
f01004a0:	75 1f                	jne    f01004c1 <kbd_proc_data+0xf8>
f01004a2:	81 fb e9 00 00 00    	cmp    $0xe9,%ebx
f01004a8:	75 17                	jne    f01004c1 <kbd_proc_data+0xf8>
		cprintf("Rebooting!\n");
f01004aa:	c7 04 24 e9 1d 10 f0 	movl   $0xf0101de9,(%esp)
f01004b1:	e8 00 08 00 00       	call   f0100cb6 <cprintf>
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01004b6:	ba 92 00 00 00       	mov    $0x92,%edx
f01004bb:	b8 03 00 00 00       	mov    $0x3,%eax
f01004c0:	ee                   	out    %al,(%dx)
		outb(0x92, 0x3); // courtesy of Chris Frost
	}

	return c;
}
f01004c1:	89 d8                	mov    %ebx,%eax
f01004c3:	83 c4 14             	add    $0x14,%esp
f01004c6:	5b                   	pop    %ebx
f01004c7:	5d                   	pop    %ebp
f01004c8:	c3                   	ret    

f01004c9 <set_attribute_color>:
	if (!(inb(COM1+COM_LSR) & COM_LSR_DATA))
		return -1;
	return inb(COM1+COM_RX);
}

void set_attribute_color(uint16_t back, uint16_t fore) {
f01004c9:	55                   	push   %ebp
f01004ca:	89 e5                	mov    %esp,%ebp
	attribute_color = (back << 12) | (fore << 8);
f01004cc:	0f b7 55 0c          	movzwl 0xc(%ebp),%edx
f01004d0:	c1 e2 08             	shl    $0x8,%edx
f01004d3:	0f b7 45 08          	movzwl 0x8(%ebp),%eax
f01004d7:	c1 e0 0c             	shl    $0xc,%eax
f01004da:	09 d0                	or     %edx,%eax
f01004dc:	66 a3 00 30 11 f0    	mov    %ax,0xf0113000
}
f01004e2:	5d                   	pop    %ebp
f01004e3:	c3                   	ret    

f01004e4 <serial_intr>:

void
serial_intr(void)
{
f01004e4:	55                   	push   %ebp
f01004e5:	89 e5                	mov    %esp,%ebp
f01004e7:	83 ec 08             	sub    $0x8,%esp
	if (serial_exists)
f01004ea:	80 3d 20 33 11 f0 00 	cmpb   $0x0,0xf0113320
f01004f1:	74 0a                	je     f01004fd <serial_intr+0x19>
		cons_intr(serial_proc_data);
f01004f3:	b8 9e 01 10 f0       	mov    $0xf010019e,%eax
f01004f8:	e8 bd fc ff ff       	call   f01001ba <cons_intr>
}
f01004fd:	c9                   	leave  
f01004fe:	c3                   	ret    

f01004ff <kbd_intr>:
	return c;
}

void
kbd_intr(void)
{
f01004ff:	55                   	push   %ebp
f0100500:	89 e5                	mov    %esp,%ebp
f0100502:	83 ec 08             	sub    $0x8,%esp
	cons_intr(kbd_proc_data);
f0100505:	b8 c9 03 10 f0       	mov    $0xf01003c9,%eax
f010050a:	e8 ab fc ff ff       	call   f01001ba <cons_intr>
}
f010050f:	c9                   	leave  
f0100510:	c3                   	ret    

f0100511 <cons_getc>:
}

// return the next input character from the console, or 0 if none waiting
int
cons_getc(void)
{
f0100511:	55                   	push   %ebp
f0100512:	89 e5                	mov    %esp,%ebp
f0100514:	83 ec 08             	sub    $0x8,%esp
	int c;

	// poll for any pending input characters,
	// so that this function works even when interrupts are disabled
	// (e.g., when called from the kernel monitor).
	serial_intr();
f0100517:	e8 c8 ff ff ff       	call   f01004e4 <serial_intr>
	kbd_intr();
f010051c:	e8 de ff ff ff       	call   f01004ff <kbd_intr>

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f0100521:	8b 15 40 35 11 f0    	mov    0xf0113540,%edx
		c = cons.buf[cons.rpos++];
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
		return c;
	}
	return 0;
f0100527:	b8 00 00 00 00       	mov    $0x0,%eax
	// (e.g., when called from the kernel monitor).
	serial_intr();
	kbd_intr();

	// grab the next character from the input buffer.
	if (cons.rpos != cons.wpos) {
f010052c:	3b 15 44 35 11 f0    	cmp    0xf0113544,%edx
f0100532:	74 1e                	je     f0100552 <cons_getc+0x41>
		c = cons.buf[cons.rpos++];
f0100534:	0f b6 82 40 33 11 f0 	movzbl -0xfeeccc0(%edx),%eax
f010053b:	83 c2 01             	add    $0x1,%edx
		if (cons.rpos == CONSBUFSIZE)
			cons.rpos = 0;
f010053e:	81 fa 00 02 00 00    	cmp    $0x200,%edx
f0100544:	b9 00 00 00 00       	mov    $0x0,%ecx
f0100549:	0f 44 d1             	cmove  %ecx,%edx
f010054c:	89 15 40 35 11 f0    	mov    %edx,0xf0113540
		return c;
	}
	return 0;
}
f0100552:	c9                   	leave  
f0100553:	c3                   	ret    

f0100554 <cons_init>:
}

// initialize the console devices
void
cons_init(void)
{
f0100554:	55                   	push   %ebp
f0100555:	89 e5                	mov    %esp,%ebp
f0100557:	57                   	push   %edi
f0100558:	56                   	push   %esi
f0100559:	53                   	push   %ebx
f010055a:	83 ec 1c             	sub    $0x1c,%esp
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
f010055d:	0f b7 15 00 80 0b f0 	movzwl 0xf00b8000,%edx
	*cp = (uint16_t) 0xA55A;
f0100564:	66 c7 05 00 80 0b f0 	movw   $0xa55a,0xf00b8000
f010056b:	5a a5 
	if (*cp != 0xA55A) {
f010056d:	0f b7 05 00 80 0b f0 	movzwl 0xf00b8000,%eax
f0100574:	66 3d 5a a5          	cmp    $0xa55a,%ax
f0100578:	74 11                	je     f010058b <cons_init+0x37>
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
		addr_6845 = MONO_BASE;
f010057a:	c7 05 4c 35 11 f0 b4 	movl   $0x3b4,0xf011354c
f0100581:	03 00 00 

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
	was = *cp;
	*cp = (uint16_t) 0xA55A;
	if (*cp != 0xA55A) {
		cp = (uint16_t*) (KERNBASE + MONO_BUF);
f0100584:	be 00 00 0b f0       	mov    $0xf00b0000,%esi
f0100589:	eb 16                	jmp    f01005a1 <cons_init+0x4d>
		addr_6845 = MONO_BASE;
	} else {
		*cp = was;
f010058b:	66 89 15 00 80 0b f0 	mov    %dx,0xf00b8000
		addr_6845 = CGA_BASE;
f0100592:	c7 05 4c 35 11 f0 d4 	movl   $0x3d4,0xf011354c
f0100599:	03 00 00 
{
	volatile uint16_t *cp;
	uint16_t was;
	unsigned pos;

	cp = (uint16_t*) (KERNBASE + CGA_BUF);
f010059c:	be 00 80 0b f0       	mov    $0xf00b8000,%esi
		*cp = was;
		addr_6845 = CGA_BASE;
	}

	/* Extract cursor location */
	outb(addr_6845, 14);
f01005a1:	8b 0d 4c 35 11 f0    	mov    0xf011354c,%ecx
f01005a7:	b8 0e 00 00 00       	mov    $0xe,%eax
f01005ac:	89 ca                	mov    %ecx,%edx
f01005ae:	ee                   	out    %al,(%dx)
	pos = inb(addr_6845 + 1) << 8;
f01005af:	8d 59 01             	lea    0x1(%ecx),%ebx

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005b2:	89 da                	mov    %ebx,%edx
f01005b4:	ec                   	in     (%dx),%al
f01005b5:	0f b6 f8             	movzbl %al,%edi
f01005b8:	c1 e7 08             	shl    $0x8,%edi
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005bb:	b8 0f 00 00 00       	mov    $0xf,%eax
f01005c0:	89 ca                	mov    %ecx,%edx
f01005c2:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f01005c3:	89 da                	mov    %ebx,%edx
f01005c5:	ec                   	in     (%dx),%al
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);

	crt_buf = (uint16_t*) cp;
f01005c6:	89 35 50 35 11 f0    	mov    %esi,0xf0113550

	/* Extract cursor location */
	outb(addr_6845, 14);
	pos = inb(addr_6845 + 1) << 8;
	outb(addr_6845, 15);
	pos |= inb(addr_6845 + 1);
f01005cc:	0f b6 d8             	movzbl %al,%ebx
f01005cf:	09 df                	or     %ebx,%edi

	crt_buf = (uint16_t*) cp;
	crt_pos = pos;
f01005d1:	66 89 3d 54 35 11 f0 	mov    %di,0xf0113554
}

static __inline void
outb(int port, uint8_t data)
{
	__asm __volatile("outb %0,%w1" : : "a" (data), "d" (port));
f01005d8:	bb fa 03 00 00       	mov    $0x3fa,%ebx
f01005dd:	b8 00 00 00 00       	mov    $0x0,%eax
f01005e2:	89 da                	mov    %ebx,%edx
f01005e4:	ee                   	out    %al,(%dx)
f01005e5:	b2 fb                	mov    $0xfb,%dl
f01005e7:	b8 80 ff ff ff       	mov    $0xffffff80,%eax
f01005ec:	ee                   	out    %al,(%dx)
f01005ed:	b9 f8 03 00 00       	mov    $0x3f8,%ecx
f01005f2:	b8 0c 00 00 00       	mov    $0xc,%eax
f01005f7:	89 ca                	mov    %ecx,%edx
f01005f9:	ee                   	out    %al,(%dx)
f01005fa:	b2 f9                	mov    $0xf9,%dl
f01005fc:	b8 00 00 00 00       	mov    $0x0,%eax
f0100601:	ee                   	out    %al,(%dx)
f0100602:	b2 fb                	mov    $0xfb,%dl
f0100604:	b8 03 00 00 00       	mov    $0x3,%eax
f0100609:	ee                   	out    %al,(%dx)
f010060a:	b2 fc                	mov    $0xfc,%dl
f010060c:	b8 00 00 00 00       	mov    $0x0,%eax
f0100611:	ee                   	out    %al,(%dx)
f0100612:	b2 f9                	mov    $0xf9,%dl
f0100614:	b8 01 00 00 00       	mov    $0x1,%eax
f0100619:	ee                   	out    %al,(%dx)

static __inline uint8_t
inb(int port)
{
	uint8_t data;
	__asm __volatile("inb %w1,%0" : "=a" (data) : "d" (port));
f010061a:	b2 fd                	mov    $0xfd,%dl
f010061c:	ec                   	in     (%dx),%al
	// Enable rcv interrupts
	outb(COM1+COM_IER, COM_IER_RDI);

	// Clear any preexisting overrun indications and interrupts
	// Serial port doesn't exist if COM_LSR returns 0xFF
	serial_exists = (inb(COM1+COM_LSR) != 0xFF);
f010061d:	3c ff                	cmp    $0xff,%al
f010061f:	0f 95 c0             	setne  %al
f0100622:	89 c6                	mov    %eax,%esi
f0100624:	a2 20 33 11 f0       	mov    %al,0xf0113320
f0100629:	89 da                	mov    %ebx,%edx
f010062b:	ec                   	in     (%dx),%al
f010062c:	89 ca                	mov    %ecx,%edx
f010062e:	ec                   	in     (%dx),%al
{
	cga_init();
	kbd_init();
	serial_init();

	if (!serial_exists)
f010062f:	89 f0                	mov    %esi,%eax
f0100631:	84 c0                	test   %al,%al
f0100633:	75 0c                	jne    f0100641 <cons_init+0xed>
		cprintf("Serial port does not exist!\n");
f0100635:	c7 04 24 f5 1d 10 f0 	movl   $0xf0101df5,(%esp)
f010063c:	e8 75 06 00 00       	call   f0100cb6 <cprintf>
}
f0100641:	83 c4 1c             	add    $0x1c,%esp
f0100644:	5b                   	pop    %ebx
f0100645:	5e                   	pop    %esi
f0100646:	5f                   	pop    %edi
f0100647:	5d                   	pop    %ebp
f0100648:	c3                   	ret    

f0100649 <cputchar>:

// `High'-level console I/O.  Used by readline and cprintf.

void
cputchar(int c)
{
f0100649:	55                   	push   %ebp
f010064a:	89 e5                	mov    %esp,%ebp
f010064c:	83 ec 08             	sub    $0x8,%esp
	cons_putc(c);
f010064f:	8b 45 08             	mov    0x8(%ebp),%eax
f0100652:	e8 a0 fb ff ff       	call   f01001f7 <cons_putc>
}
f0100657:	c9                   	leave  
f0100658:	c3                   	ret    

f0100659 <getchar>:

int
getchar(void)
{
f0100659:	55                   	push   %ebp
f010065a:	89 e5                	mov    %esp,%ebp
f010065c:	83 ec 08             	sub    $0x8,%esp
	int c;

	while ((c = cons_getc()) == 0)
f010065f:	e8 ad fe ff ff       	call   f0100511 <cons_getc>
f0100664:	85 c0                	test   %eax,%eax
f0100666:	74 f7                	je     f010065f <getchar+0x6>
		/* do nothing */;
	return c;
}
f0100668:	c9                   	leave  
f0100669:	c3                   	ret    

f010066a <iscons>:

int
iscons(int fdnum)
{
f010066a:	55                   	push   %ebp
f010066b:	89 e5                	mov    %esp,%ebp
	// used by readline
	return 1;
}
f010066d:	b8 01 00 00 00       	mov    $0x1,%eax
f0100672:	5d                   	pop    %ebp
f0100673:	c3                   	ret    
	...

f0100680 <mon_kerninfo>:
	return 0;
}

int
mon_kerninfo(int argc, char **argv, struct Trapframe *tf)
{
f0100680:	55                   	push   %ebp
f0100681:	89 e5                	mov    %esp,%ebp
f0100683:	83 ec 18             	sub    $0x18,%esp
	extern char _start[], entry[], etext[], edata[], end[];

	cprintf("Special kernel symbols:\n");
f0100686:	c7 04 24 30 20 10 f0 	movl   $0xf0102030,(%esp)
f010068d:	e8 24 06 00 00       	call   f0100cb6 <cprintf>
	cprintf("  _start                  %08x (phys)\n", _start);
f0100692:	c7 44 24 04 0c 00 10 	movl   $0x10000c,0x4(%esp)
f0100699:	00 
f010069a:	c7 04 24 50 21 10 f0 	movl   $0xf0102150,(%esp)
f01006a1:	e8 10 06 00 00       	call   f0100cb6 <cprintf>
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
f01006a6:	c7 44 24 08 0c 00 10 	movl   $0x10000c,0x8(%esp)
f01006ad:	00 
f01006ae:	c7 44 24 04 0c 00 10 	movl   $0xf010000c,0x4(%esp)
f01006b5:	f0 
f01006b6:	c7 04 24 78 21 10 f0 	movl   $0xf0102178,(%esp)
f01006bd:	e8 f4 05 00 00       	call   f0100cb6 <cprintf>
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
f01006c2:	c7 44 24 08 65 1d 10 	movl   $0x101d65,0x8(%esp)
f01006c9:	00 
f01006ca:	c7 44 24 04 65 1d 10 	movl   $0xf0101d65,0x4(%esp)
f01006d1:	f0 
f01006d2:	c7 04 24 9c 21 10 f0 	movl   $0xf010219c,(%esp)
f01006d9:	e8 d8 05 00 00       	call   f0100cb6 <cprintf>
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
f01006de:	c7 44 24 08 20 33 11 	movl   $0x113320,0x8(%esp)
f01006e5:	00 
f01006e6:	c7 44 24 04 20 33 11 	movl   $0xf0113320,0x4(%esp)
f01006ed:	f0 
f01006ee:	c7 04 24 c0 21 10 f0 	movl   $0xf01021c0,(%esp)
f01006f5:	e8 bc 05 00 00       	call   f0100cb6 <cprintf>
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
f01006fa:	c7 44 24 08 64 39 11 	movl   $0x113964,0x8(%esp)
f0100701:	00 
f0100702:	c7 44 24 04 64 39 11 	movl   $0xf0113964,0x4(%esp)
f0100709:	f0 
f010070a:	c7 04 24 e4 21 10 f0 	movl   $0xf01021e4,(%esp)
f0100711:	e8 a0 05 00 00       	call   f0100cb6 <cprintf>
	cprintf("Kernel executable memory footprint: %dKB\n",
		ROUNDUP(end - entry, 1024) / 1024);
f0100716:	b8 63 3d 11 f0       	mov    $0xf0113d63,%eax
f010071b:	2d 0c 00 10 f0       	sub    $0xf010000c,%eax
f0100720:	25 00 fc ff ff       	and    $0xfffffc00,%eax
	cprintf("  _start                  %08x (phys)\n", _start);
	cprintf("  entry  %08x (virt)  %08x (phys)\n", entry, entry - KERNBASE);
	cprintf("  etext  %08x (virt)  %08x (phys)\n", etext, etext - KERNBASE);
	cprintf("  edata  %08x (virt)  %08x (phys)\n", edata, edata - KERNBASE);
	cprintf("  end    %08x (virt)  %08x (phys)\n", end, end - KERNBASE);
	cprintf("Kernel executable memory footprint: %dKB\n",
f0100725:	8d 90 ff 03 00 00    	lea    0x3ff(%eax),%edx
f010072b:	85 c0                	test   %eax,%eax
f010072d:	0f 48 c2             	cmovs  %edx,%eax
f0100730:	c1 f8 0a             	sar    $0xa,%eax
f0100733:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100737:	c7 04 24 08 22 10 f0 	movl   $0xf0102208,(%esp)
f010073e:	e8 73 05 00 00       	call   f0100cb6 <cprintf>
		ROUNDUP(end - entry, 1024) / 1024);
	return 0;
}
f0100743:	b8 00 00 00 00       	mov    $0x0,%eax
f0100748:	c9                   	leave  
f0100749:	c3                   	ret    

f010074a <mon_help>:

/***** Implementations of basic kernel monitor commands *****/

int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
f010074a:	55                   	push   %ebp
f010074b:	89 e5                	mov    %esp,%ebp
f010074d:	53                   	push   %ebx
f010074e:	83 ec 14             	sub    $0x14,%esp
f0100751:	bb 00 00 00 00       	mov    $0x0,%ebx
	int i;

	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
f0100756:	8b 83 44 23 10 f0    	mov    -0xfefdcbc(%ebx),%eax
f010075c:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100760:	8b 83 40 23 10 f0    	mov    -0xfefdcc0(%ebx),%eax
f0100766:	89 44 24 04          	mov    %eax,0x4(%esp)
f010076a:	c7 04 24 49 20 10 f0 	movl   $0xf0102049,(%esp)
f0100771:	e8 40 05 00 00       	call   f0100cb6 <cprintf>
f0100776:	83 c3 0c             	add    $0xc,%ebx
int
mon_help(int argc, char **argv, struct Trapframe *tf)
{
	int i;

	for (i = 0; i < NCOMMANDS; i++)
f0100779:	83 fb 30             	cmp    $0x30,%ebx
f010077c:	75 d8                	jne    f0100756 <mon_help+0xc>
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
	return 0;
}
f010077e:	b8 00 00 00 00       	mov    $0x0,%eax
f0100783:	83 c4 14             	add    $0x14,%esp
f0100786:	5b                   	pop    %ebx
f0100787:	5d                   	pop    %ebp
f0100788:	c3                   	ret    

f0100789 <mon_backtrace>:
	return 0;
}

int
mon_backtrace(int argc, char **argv, struct Trapframe *tf)
{
f0100789:	55                   	push   %ebp
f010078a:	89 e5                	mov    %esp,%ebp
f010078c:	57                   	push   %edi
f010078d:	56                   	push   %esi
f010078e:	53                   	push   %ebx
f010078f:	83 ec 4c             	sub    $0x4c,%esp

static __inline uint32_t
read_ebp(void)
{
	uint32_t ebp;
	__asm __volatile("movl %%ebp,%0" : "=r" (ebp));
f0100792:	89 eb                	mov    %ebp,%ebx
// Your code here.
//	cprintf("%08x", read_ebp());
	uint32_t *eip, *ebp;
	ebp = (uint32_t*) read_ebp();
f0100794:	89 de                	mov    %ebx,%esi
	eip = (uint32_t*) ebp[1];
f0100796:	8b 7b 04             	mov    0x4(%ebx),%edi
	cprintf("Stackbacktrace:\n");
f0100799:	c7 04 24 52 20 10 f0 	movl   $0xf0102052,(%esp)
f01007a0:	e8 11 05 00 00       	call   f0100cb6 <cprintf>
	while (ebp!=0) {
f01007a5:	85 db                	test   %ebx,%ebx
f01007a7:	0f 84 aa 00 00 00    	je     f0100857 <mon_backtrace+0xce>
		cprintf("ebp %08x eip %08x args %08x %08x %08x %08x %08x\n",ebp, eip, ebp[2] ,ebp[3], ebp[4], ebp[5] ,ebp[6]);
f01007ad:	8b 46 18             	mov    0x18(%esi),%eax
f01007b0:	89 44 24 1c          	mov    %eax,0x1c(%esp)
f01007b4:	8b 46 14             	mov    0x14(%esi),%eax
f01007b7:	89 44 24 18          	mov    %eax,0x18(%esp)
f01007bb:	8b 46 10             	mov    0x10(%esi),%eax
f01007be:	89 44 24 14          	mov    %eax,0x14(%esp)
f01007c2:	8b 46 0c             	mov    0xc(%esi),%eax
f01007c5:	89 44 24 10          	mov    %eax,0x10(%esp)
f01007c9:	8b 46 08             	mov    0x8(%esi),%eax
f01007cc:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01007d0:	89 7c 24 08          	mov    %edi,0x8(%esp)
f01007d4:	89 74 24 04          	mov    %esi,0x4(%esp)
f01007d8:	c7 04 24 34 22 10 f0 	movl   $0xf0102234,(%esp)
f01007df:	e8 d2 04 00 00       	call   f0100cb6 <cprintf>
		struct Eipdebuginfo temp_debuginfo;
		debuginfo_eip((uintptr_t) eip, &temp_debuginfo);		
f01007e4:	8d 45 d0             	lea    -0x30(%ebp),%eax
f01007e7:	89 44 24 04          	mov    %eax,0x4(%esp)
f01007eb:	89 3c 24             	mov    %edi,(%esp)
f01007ee:	e8 bd 05 00 00       	call   f0100db0 <debuginfo_eip>
		cprintf("       %s:%d: ", temp_debuginfo.eip_file, temp_debuginfo.eip_line);
f01007f3:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01007f6:	89 44 24 08          	mov    %eax,0x8(%esp)
f01007fa:	8b 45 d0             	mov    -0x30(%ebp),%eax
f01007fd:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100801:	c7 04 24 63 20 10 f0 	movl   $0xf0102063,(%esp)
f0100808:	e8 a9 04 00 00       	call   f0100cb6 <cprintf>
		uint32_t i = 0;// = temp_debuginfo.eip_fn_namelen;
		while  (i < temp_debuginfo.eip_fn_namelen){
f010080d:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0100811:	74 24                	je     f0100837 <mon_backtrace+0xae>
	while (ebp!=0) {
		cprintf("ebp %08x eip %08x args %08x %08x %08x %08x %08x\n",ebp, eip, ebp[2] ,ebp[3], ebp[4], ebp[5] ,ebp[6]);
		struct Eipdebuginfo temp_debuginfo;
		debuginfo_eip((uintptr_t) eip, &temp_debuginfo);		
		cprintf("       %s:%d: ", temp_debuginfo.eip_file, temp_debuginfo.eip_line);
		uint32_t i = 0;// = temp_debuginfo.eip_fn_namelen;
f0100813:	bb 00 00 00 00       	mov    $0x0,%ebx
		while  (i < temp_debuginfo.eip_fn_namelen){
			cprintf("%c", temp_debuginfo.eip_fn_name[i]);
f0100818:	8b 45 d8             	mov    -0x28(%ebp),%eax
f010081b:	0f be 04 18          	movsbl (%eax,%ebx,1),%eax
f010081f:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100823:	c7 04 24 72 20 10 f0 	movl   $0xf0102072,(%esp)
f010082a:	e8 87 04 00 00       	call   f0100cb6 <cprintf>
			i++;	
f010082f:	83 c3 01             	add    $0x1,%ebx
		cprintf("ebp %08x eip %08x args %08x %08x %08x %08x %08x\n",ebp, eip, ebp[2] ,ebp[3], ebp[4], ebp[5] ,ebp[6]);
		struct Eipdebuginfo temp_debuginfo;
		debuginfo_eip((uintptr_t) eip, &temp_debuginfo);		
		cprintf("       %s:%d: ", temp_debuginfo.eip_file, temp_debuginfo.eip_line);
		uint32_t i = 0;// = temp_debuginfo.eip_fn_namelen;
		while  (i < temp_debuginfo.eip_fn_namelen){
f0100832:	39 5d dc             	cmp    %ebx,-0x24(%ebp)
f0100835:	77 e1                	ja     f0100818 <mon_backtrace+0x8f>
		int p = (int)eip;
		int q = (int)temp_debuginfo.eip_fn_addr;
//	   	cprintf("          %08x+%08x  %08x %d \n", eip, temp_debuginfo.eip_fn_addr
//						,eip, (int)(eip) - (int)(temp_debuginfo.eip_fn_addr));
//					
		cprintf("+%x\n", p - q);
f0100837:	2b 7d e0             	sub    -0x20(%ebp),%edi
f010083a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010083e:	c7 04 24 75 20 10 f0 	movl   $0xf0102075,(%esp)
f0100845:	e8 6c 04 00 00       	call   f0100cb6 <cprintf>
		ebp=(uint32_t*)ebp[0];
f010084a:	8b 36                	mov    (%esi),%esi
		eip=(uint32_t*)ebp[1]; //21arg0=ebp[2];22arg1=ebp[3];23arg2=ebp[4];24arg3=ebp[5];25arg4=ebp[6];26}
f010084c:	8b 7e 04             	mov    0x4(%esi),%edi
//	cprintf("%08x", read_ebp());
	uint32_t *eip, *ebp;
	ebp = (uint32_t*) read_ebp();
	eip = (uint32_t*) ebp[1];
	cprintf("Stackbacktrace:\n");
	while (ebp!=0) {
f010084f:	85 f6                	test   %esi,%esi
f0100851:	0f 85 56 ff ff ff    	jne    f01007ad <mon_backtrace+0x24>
		eip=(uint32_t*)ebp[1]; //21arg0=ebp[2];22arg1=ebp[3];23arg2=ebp[4];24arg3=ebp[5];25arg4=ebp[6];26}
	}
	
//	cprintf("%d", read_esp());
	return 0;
}
f0100857:	b8 00 00 00 00       	mov    $0x0,%eax
f010085c:	83 c4 4c             	add    $0x4c,%esp
f010085f:	5b                   	pop    %ebx
f0100860:	5e                   	pop    %esi
f0100861:	5f                   	pop    %edi
f0100862:	5d                   	pop    %ebp
f0100863:	c3                   	ret    

f0100864 <mon_setcolor>:
	for (i = 0; i < NCOMMANDS; i++)
		cprintf("%s - %s\n", commands[i].name, commands[i].desc);
	return 0;
}

int mon_setcolor(int argc, char **argv, struct Trapframe *tf) {
f0100864:	55                   	push   %ebp
f0100865:	89 e5                	mov    %esp,%ebp
f0100867:	83 ec 28             	sub    $0x28,%esp
f010086a:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f010086d:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0100870:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0100873:	8b 75 0c             	mov    0xc(%ebp),%esi
	//argv
	uint16_t ch_color1, ch_color;
	if(strcmp(argv[2],"blk")==0)
f0100876:	c7 44 24 04 7a 20 10 	movl   $0xf010207a,0x4(%esp)
f010087d:	f0 
f010087e:	8b 46 08             	mov    0x8(%esi),%eax
f0100881:	89 04 24             	mov    %eax,(%esp)
f0100884:	e8 12 0f 00 00       	call   f010179b <strcmp>
			ch_color1=COLOR_BLK
f0100889:	bf 00 00 00 00       	mov    $0x0,%edi
}

int mon_setcolor(int argc, char **argv, struct Trapframe *tf) {
	//argv
	uint16_t ch_color1, ch_color;
	if(strcmp(argv[2],"blk")==0)
f010088e:	85 c0                	test   %eax,%eax
f0100890:	0f 84 0e 01 00 00    	je     f01009a4 <mon_setcolor+0x140>
			ch_color1=COLOR_BLK
	else if(strcmp(argv[2],"wht")==0)
f0100896:	c7 44 24 04 7e 20 10 	movl   $0xf010207e,0x4(%esp)
f010089d:	f0 
f010089e:	8b 46 08             	mov    0x8(%esi),%eax
f01008a1:	89 04 24             	mov    %eax,(%esp)
f01008a4:	e8 f2 0e 00 00       	call   f010179b <strcmp>
			ch_color1=COLOR_WHT
f01008a9:	bf 07 00 00 00       	mov    $0x7,%edi
int mon_setcolor(int argc, char **argv, struct Trapframe *tf) {
	//argv
	uint16_t ch_color1, ch_color;
	if(strcmp(argv[2],"blk")==0)
			ch_color1=COLOR_BLK
	else if(strcmp(argv[2],"wht")==0)
f01008ae:	85 c0                	test   %eax,%eax
f01008b0:	0f 84 ee 00 00 00    	je     f01009a4 <mon_setcolor+0x140>
			ch_color1=COLOR_WHT
	else if(strcmp(argv[2],"blu")==0)
f01008b6:	c7 44 24 04 82 20 10 	movl   $0xf0102082,0x4(%esp)
f01008bd:	f0 
f01008be:	8b 46 08             	mov    0x8(%esi),%eax
f01008c1:	89 04 24             	mov    %eax,(%esp)
f01008c4:	e8 d2 0e 00 00       	call   f010179b <strcmp>
			ch_color1=COLOR_BLU
f01008c9:	bf 01 00 00 00       	mov    $0x1,%edi
	uint16_t ch_color1, ch_color;
	if(strcmp(argv[2],"blk")==0)
			ch_color1=COLOR_BLK
	else if(strcmp(argv[2],"wht")==0)
			ch_color1=COLOR_WHT
	else if(strcmp(argv[2],"blu")==0)
f01008ce:	85 c0                	test   %eax,%eax
f01008d0:	0f 84 ce 00 00 00    	je     f01009a4 <mon_setcolor+0x140>
			ch_color1=COLOR_BLU
	else if(strcmp(argv[2],"grn")==0)
f01008d6:	c7 44 24 04 86 20 10 	movl   $0xf0102086,0x4(%esp)
f01008dd:	f0 
f01008de:	8b 46 08             	mov    0x8(%esi),%eax
f01008e1:	89 04 24             	mov    %eax,(%esp)
f01008e4:	e8 b2 0e 00 00       	call   f010179b <strcmp>
			ch_color1=COLOR_GRN
f01008e9:	bf 02 00 00 00       	mov    $0x2,%edi
			ch_color1=COLOR_BLK
	else if(strcmp(argv[2],"wht")==0)
			ch_color1=COLOR_WHT
	else if(strcmp(argv[2],"blu")==0)
			ch_color1=COLOR_BLU
	else if(strcmp(argv[2],"grn")==0)
f01008ee:	85 c0                	test   %eax,%eax
f01008f0:	0f 84 ae 00 00 00    	je     f01009a4 <mon_setcolor+0x140>
			ch_color1=COLOR_GRN
	else if(strcmp(argv[2],"red")==0)
f01008f6:	c7 44 24 04 8a 20 10 	movl   $0xf010208a,0x4(%esp)
f01008fd:	f0 
f01008fe:	8b 46 08             	mov    0x8(%esi),%eax
f0100901:	89 04 24             	mov    %eax,(%esp)
f0100904:	e8 92 0e 00 00       	call   f010179b <strcmp>
			ch_color1=COLOR_RED
f0100909:	bf 04 00 00 00       	mov    $0x4,%edi
			ch_color1=COLOR_WHT
	else if(strcmp(argv[2],"blu")==0)
			ch_color1=COLOR_BLU
	else if(strcmp(argv[2],"grn")==0)
			ch_color1=COLOR_GRN
	else if(strcmp(argv[2],"red")==0)
f010090e:	85 c0                	test   %eax,%eax
f0100910:	0f 84 8e 00 00 00    	je     f01009a4 <mon_setcolor+0x140>
			ch_color1=COLOR_RED
	else if(strcmp(argv[2],"gry")==0)
f0100916:	c7 44 24 04 8e 20 10 	movl   $0xf010208e,0x4(%esp)
f010091d:	f0 
f010091e:	8b 46 08             	mov    0x8(%esi),%eax
f0100921:	89 04 24             	mov    %eax,(%esp)
f0100924:	e8 72 0e 00 00       	call   f010179b <strcmp>
			ch_color1=COLOR_GRY
f0100929:	bf 08 00 00 00       	mov    $0x8,%edi
			ch_color1=COLOR_BLU
	else if(strcmp(argv[2],"grn")==0)
			ch_color1=COLOR_GRN
	else if(strcmp(argv[2],"red")==0)
			ch_color1=COLOR_RED
	else if(strcmp(argv[2],"gry")==0)
f010092e:	85 c0                	test   %eax,%eax
f0100930:	74 72                	je     f01009a4 <mon_setcolor+0x140>
			ch_color1=COLOR_GRY
	else if(strcmp(argv[2],"ylw")==0)
f0100932:	c7 44 24 04 92 20 10 	movl   $0xf0102092,0x4(%esp)
f0100939:	f0 
f010093a:	8b 46 08             	mov    0x8(%esi),%eax
f010093d:	89 04 24             	mov    %eax,(%esp)
f0100940:	e8 56 0e 00 00       	call   f010179b <strcmp>
			ch_color1=COLOR_YLW
f0100945:	bf 0f 00 00 00       	mov    $0xf,%edi
			ch_color1=COLOR_GRN
	else if(strcmp(argv[2],"red")==0)
			ch_color1=COLOR_RED
	else if(strcmp(argv[2],"gry")==0)
			ch_color1=COLOR_GRY
	else if(strcmp(argv[2],"ylw")==0)
f010094a:	85 c0                	test   %eax,%eax
f010094c:	74 56                	je     f01009a4 <mon_setcolor+0x140>
			ch_color1=COLOR_YLW
	else if(strcmp(argv[2],"org")==0)
f010094e:	c7 44 24 04 96 20 10 	movl   $0xf0102096,0x4(%esp)
f0100955:	f0 
f0100956:	8b 46 08             	mov    0x8(%esi),%eax
f0100959:	89 04 24             	mov    %eax,(%esp)
f010095c:	e8 3a 0e 00 00       	call   f010179b <strcmp>
			ch_color1=COLOR_ORG
f0100961:	bf 0c 00 00 00       	mov    $0xc,%edi
			ch_color1=COLOR_RED
	else if(strcmp(argv[2],"gry")==0)
			ch_color1=COLOR_GRY
	else if(strcmp(argv[2],"ylw")==0)
			ch_color1=COLOR_YLW
	else if(strcmp(argv[2],"org")==0)
f0100966:	85 c0                	test   %eax,%eax
f0100968:	74 3a                	je     f01009a4 <mon_setcolor+0x140>
			ch_color1=COLOR_ORG
	else if(strcmp(argv[2],"pur")==0)
f010096a:	c7 44 24 04 9a 20 10 	movl   $0xf010209a,0x4(%esp)
f0100971:	f0 
f0100972:	8b 46 08             	mov    0x8(%esi),%eax
f0100975:	89 04 24             	mov    %eax,(%esp)
f0100978:	e8 1e 0e 00 00       	call   f010179b <strcmp>
			ch_color1=COLOR_PUR
f010097d:	bf 06 00 00 00       	mov    $0x6,%edi
			ch_color1=COLOR_GRY
	else if(strcmp(argv[2],"ylw")==0)
			ch_color1=COLOR_YLW
	else if(strcmp(argv[2],"org")==0)
			ch_color1=COLOR_ORG
	else if(strcmp(argv[2],"pur")==0)
f0100982:	85 c0                	test   %eax,%eax
f0100984:	74 1e                	je     f01009a4 <mon_setcolor+0x140>
			ch_color1=COLOR_PUR
	else if(strcmp(argv[2],"cyn")==0)
f0100986:	c7 44 24 04 9e 20 10 	movl   $0xf010209e,0x4(%esp)
f010098d:	f0 
f010098e:	8b 46 08             	mov    0x8(%esi),%eax
f0100991:	89 04 24             	mov    %eax,(%esp)
f0100994:	e8 02 0e 00 00       	call   f010179b <strcmp>
			ch_color1=COLOR_CYN
f0100999:	83 f8 01             	cmp    $0x1,%eax
f010099c:	19 ff                	sbb    %edi,%edi
f010099e:	83 e7 04             	and    $0x4,%edi
f01009a1:	83 c7 07             	add    $0x7,%edi
	else ch_color1=COLOR_WHT;
	if(strcmp(argv[1],"blk")==0)
f01009a4:	c7 44 24 04 7a 20 10 	movl   $0xf010207a,0x4(%esp)
f01009ab:	f0 
f01009ac:	8b 46 04             	mov    0x4(%esi),%eax
f01009af:	89 04 24             	mov    %eax,(%esp)
f01009b2:	e8 e4 0d 00 00       	call   f010179b <strcmp>
			ch_color=COLOR_BLK
f01009b7:	bb 00 00 00 00       	mov    $0x0,%ebx
	else if(strcmp(argv[2],"pur")==0)
			ch_color1=COLOR_PUR
	else if(strcmp(argv[2],"cyn")==0)
			ch_color1=COLOR_CYN
	else ch_color1=COLOR_WHT;
	if(strcmp(argv[1],"blk")==0)
f01009bc:	85 c0                	test   %eax,%eax
f01009be:	0f 84 f6 00 00 00    	je     f0100aba <mon_setcolor+0x256>
			ch_color=COLOR_BLK
	else if(strcmp(argv[1],"wht")==0)
f01009c4:	c7 44 24 04 7e 20 10 	movl   $0xf010207e,0x4(%esp)
f01009cb:	f0 
f01009cc:	8b 46 04             	mov    0x4(%esi),%eax
f01009cf:	89 04 24             	mov    %eax,(%esp)
f01009d2:	e8 c4 0d 00 00       	call   f010179b <strcmp>
			ch_color=COLOR_WHT
f01009d7:	b3 07                	mov    $0x7,%bl
	else if(strcmp(argv[2],"cyn")==0)
			ch_color1=COLOR_CYN
	else ch_color1=COLOR_WHT;
	if(strcmp(argv[1],"blk")==0)
			ch_color=COLOR_BLK
	else if(strcmp(argv[1],"wht")==0)
f01009d9:	85 c0                	test   %eax,%eax
f01009db:	0f 84 d9 00 00 00    	je     f0100aba <mon_setcolor+0x256>
			ch_color=COLOR_WHT
	else if(strcmp(argv[1],"blu")==0)
f01009e1:	c7 44 24 04 82 20 10 	movl   $0xf0102082,0x4(%esp)
f01009e8:	f0 
f01009e9:	8b 46 04             	mov    0x4(%esi),%eax
f01009ec:	89 04 24             	mov    %eax,(%esp)
f01009ef:	e8 a7 0d 00 00       	call   f010179b <strcmp>
			ch_color=COLOR_BLU
f01009f4:	b3 01                	mov    $0x1,%bl
	else ch_color1=COLOR_WHT;
	if(strcmp(argv[1],"blk")==0)
			ch_color=COLOR_BLK
	else if(strcmp(argv[1],"wht")==0)
			ch_color=COLOR_WHT
	else if(strcmp(argv[1],"blu")==0)
f01009f6:	85 c0                	test   %eax,%eax
f01009f8:	0f 84 bc 00 00 00    	je     f0100aba <mon_setcolor+0x256>
			ch_color=COLOR_BLU
	else if(strcmp(argv[1],"grn")==0)
f01009fe:	c7 44 24 04 86 20 10 	movl   $0xf0102086,0x4(%esp)
f0100a05:	f0 
f0100a06:	8b 46 04             	mov    0x4(%esi),%eax
f0100a09:	89 04 24             	mov    %eax,(%esp)
f0100a0c:	e8 8a 0d 00 00       	call   f010179b <strcmp>
			ch_color=COLOR_GRN
f0100a11:	b3 02                	mov    $0x2,%bl
			ch_color=COLOR_BLK
	else if(strcmp(argv[1],"wht")==0)
			ch_color=COLOR_WHT
	else if(strcmp(argv[1],"blu")==0)
			ch_color=COLOR_BLU
	else if(strcmp(argv[1],"grn")==0)
f0100a13:	85 c0                	test   %eax,%eax
f0100a15:	0f 84 9f 00 00 00    	je     f0100aba <mon_setcolor+0x256>
			ch_color=COLOR_GRN
	else if(strcmp(argv[1],"red")==0)
f0100a1b:	c7 44 24 04 8a 20 10 	movl   $0xf010208a,0x4(%esp)
f0100a22:	f0 
f0100a23:	8b 46 04             	mov    0x4(%esi),%eax
f0100a26:	89 04 24             	mov    %eax,(%esp)
f0100a29:	e8 6d 0d 00 00       	call   f010179b <strcmp>
			ch_color=COLOR_RED
f0100a2e:	b3 04                	mov    $0x4,%bl
			ch_color=COLOR_WHT
	else if(strcmp(argv[1],"blu")==0)
			ch_color=COLOR_BLU
	else if(strcmp(argv[1],"grn")==0)
			ch_color=COLOR_GRN
	else if(strcmp(argv[1],"red")==0)
f0100a30:	85 c0                	test   %eax,%eax
f0100a32:	0f 84 82 00 00 00    	je     f0100aba <mon_setcolor+0x256>
			ch_color=COLOR_RED
	else if(strcmp(argv[1],"gry")==0)
f0100a38:	c7 44 24 04 8e 20 10 	movl   $0xf010208e,0x4(%esp)
f0100a3f:	f0 
f0100a40:	8b 46 04             	mov    0x4(%esi),%eax
f0100a43:	89 04 24             	mov    %eax,(%esp)
f0100a46:	e8 50 0d 00 00       	call   f010179b <strcmp>
			ch_color=COLOR_GRY
f0100a4b:	b3 08                	mov    $0x8,%bl
			ch_color=COLOR_BLU
	else if(strcmp(argv[1],"grn")==0)
			ch_color=COLOR_GRN
	else if(strcmp(argv[1],"red")==0)
			ch_color=COLOR_RED
	else if(strcmp(argv[1],"gry")==0)
f0100a4d:	85 c0                	test   %eax,%eax
f0100a4f:	74 69                	je     f0100aba <mon_setcolor+0x256>
			ch_color=COLOR_GRY
	else if(strcmp(argv[1],"ylw")==0)
f0100a51:	c7 44 24 04 92 20 10 	movl   $0xf0102092,0x4(%esp)
f0100a58:	f0 
f0100a59:	8b 46 04             	mov    0x4(%esi),%eax
f0100a5c:	89 04 24             	mov    %eax,(%esp)
f0100a5f:	e8 37 0d 00 00       	call   f010179b <strcmp>
			ch_color=COLOR_YLW
f0100a64:	b3 0f                	mov    $0xf,%bl
			ch_color=COLOR_GRN
	else if(strcmp(argv[1],"red")==0)
			ch_color=COLOR_RED
	else if(strcmp(argv[1],"gry")==0)
			ch_color=COLOR_GRY
	else if(strcmp(argv[1],"ylw")==0)
f0100a66:	85 c0                	test   %eax,%eax
f0100a68:	74 50                	je     f0100aba <mon_setcolor+0x256>
			ch_color=COLOR_YLW
	else if(strcmp(argv[1],"org")==0)
f0100a6a:	c7 44 24 04 96 20 10 	movl   $0xf0102096,0x4(%esp)
f0100a71:	f0 
f0100a72:	8b 46 04             	mov    0x4(%esi),%eax
f0100a75:	89 04 24             	mov    %eax,(%esp)
f0100a78:	e8 1e 0d 00 00       	call   f010179b <strcmp>
			ch_color=COLOR_ORG
f0100a7d:	b3 0c                	mov    $0xc,%bl
			ch_color=COLOR_RED
	else if(strcmp(argv[1],"gry")==0)
			ch_color=COLOR_GRY
	else if(strcmp(argv[1],"ylw")==0)
			ch_color=COLOR_YLW
	else if(strcmp(argv[1],"org")==0)
f0100a7f:	85 c0                	test   %eax,%eax
f0100a81:	74 37                	je     f0100aba <mon_setcolor+0x256>
			ch_color=COLOR_ORG
	else if(strcmp(argv[1],"pur")==0)
f0100a83:	c7 44 24 04 9a 20 10 	movl   $0xf010209a,0x4(%esp)
f0100a8a:	f0 
f0100a8b:	8b 46 04             	mov    0x4(%esi),%eax
f0100a8e:	89 04 24             	mov    %eax,(%esp)
f0100a91:	e8 05 0d 00 00       	call   f010179b <strcmp>
			ch_color=COLOR_PUR
f0100a96:	b3 06                	mov    $0x6,%bl
			ch_color=COLOR_GRY
	else if(strcmp(argv[1],"ylw")==0)
			ch_color=COLOR_YLW
	else if(strcmp(argv[1],"org")==0)
			ch_color=COLOR_ORG
	else if(strcmp(argv[1],"pur")==0)
f0100a98:	85 c0                	test   %eax,%eax
f0100a9a:	74 1e                	je     f0100aba <mon_setcolor+0x256>
			ch_color=COLOR_PUR
	else if(strcmp(argv[1],"cyn")==0)
f0100a9c:	c7 44 24 04 9e 20 10 	movl   $0xf010209e,0x4(%esp)
f0100aa3:	f0 
f0100aa4:	8b 46 04             	mov    0x4(%esi),%eax
f0100aa7:	89 04 24             	mov    %eax,(%esp)
f0100aaa:	e8 ec 0c 00 00       	call   f010179b <strcmp>
			ch_color=COLOR_CYN
f0100aaf:	83 f8 01             	cmp    $0x1,%eax
f0100ab2:	19 db                	sbb    %ebx,%ebx
f0100ab4:	83 e3 04             	and    $0x4,%ebx
f0100ab7:	83 c3 07             	add    $0x7,%ebx
	else ch_color=COLOR_WHT;
	set_attribute_color((uint64_t) ch_color, (uint64_t) ch_color1);
f0100aba:	0f b7 f7             	movzwl %di,%esi
f0100abd:	0f b7 db             	movzwl %bx,%ebx
f0100ac0:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100ac4:	89 1c 24             	mov    %ebx,(%esp)
f0100ac7:	e8 fd f9 ff ff       	call   f01004c9 <set_attribute_color>
	cprintf("console back-color :  %d \n        fore-color :  %d\n", ch_color, ch_color1);	
f0100acc:	89 74 24 08          	mov    %esi,0x8(%esp)
f0100ad0:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0100ad4:	c7 04 24 68 22 10 f0 	movl   $0xf0102268,(%esp)
f0100adb:	e8 d6 01 00 00       	call   f0100cb6 <cprintf>
	return 0;
}
f0100ae0:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ae5:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0100ae8:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0100aeb:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0100aee:	89 ec                	mov    %ebp,%esp
f0100af0:	5d                   	pop    %ebp
f0100af1:	c3                   	ret    

f0100af2 <monitor>:
	return 0;
}

void
monitor(struct Trapframe *tf)
{
f0100af2:	55                   	push   %ebp
f0100af3:	89 e5                	mov    %esp,%ebp
f0100af5:	57                   	push   %edi
f0100af6:	56                   	push   %esi
f0100af7:	53                   	push   %ebx
f0100af8:	83 ec 6c             	sub    $0x6c,%esp
	char *buf;

	cprintf("Welcome to the JOS kernel monitor!\n");
f0100afb:	c7 04 24 9c 22 10 f0 	movl   $0xf010229c,(%esp)
f0100b02:	e8 af 01 00 00       	call   f0100cb6 <cprintf>
	cprintf("Type 'help' for a list of commands.\n");
f0100b07:	c7 04 24 c0 22 10 f0 	movl   $0xf01022c0,(%esp)
f0100b0e:	e8 a3 01 00 00       	call   f0100cb6 <cprintf>
	int x = 1, y = 3, z = 4;
  	cprintf("x %d, y %x, z %d\n", x, y, z);
f0100b13:	c7 44 24 0c 04 00 00 	movl   $0x4,0xc(%esp)
f0100b1a:	00 
f0100b1b:	c7 44 24 08 03 00 00 	movl   $0x3,0x8(%esp)
f0100b22:	00 
f0100b23:	c7 44 24 04 01 00 00 	movl   $0x1,0x4(%esp)
f0100b2a:	00 
f0100b2b:	c7 04 24 a2 20 10 f0 	movl   $0xf01020a2,(%esp)
f0100b32:	e8 7f 01 00 00       	call   f0100cb6 <cprintf>
	unsigned int i = 0x00646c72;
f0100b37:	c7 45 e4 72 6c 64 00 	movl   $0x646c72,-0x1c(%ebp)
	cprintf("H%x Wo%s", 57616, &i);
f0100b3e:	8d 45 e4             	lea    -0x1c(%ebp),%eax
f0100b41:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100b45:	c7 44 24 04 10 e1 00 	movl   $0xe110,0x4(%esp)
f0100b4c:	00 
f0100b4d:	c7 04 24 b4 20 10 f0 	movl   $0xf01020b4,(%esp)
f0100b54:	e8 5d 01 00 00       	call   f0100cb6 <cprintf>

	while (1) {
		buf = readline("K> ");
f0100b59:	c7 04 24 bd 20 10 f0 	movl   $0xf01020bd,(%esp)
f0100b60:	e8 5b 0a 00 00       	call   f01015c0 <readline>
f0100b65:	89 c3                	mov    %eax,%ebx
		if (buf != NULL)
f0100b67:	85 c0                	test   %eax,%eax
f0100b69:	74 ee                	je     f0100b59 <monitor+0x67>
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
f0100b6b:	c7 45 a4 00 00 00 00 	movl   $0x0,-0x5c(%ebp)
	int argc;
	char *argv[MAXARGS];
	int i;

	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
f0100b72:	be 00 00 00 00       	mov    $0x0,%esi
f0100b77:	eb 06                	jmp    f0100b7f <monitor+0x8d>
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
			*buf++ = 0;
f0100b79:	c6 03 00             	movb   $0x0,(%ebx)
f0100b7c:	83 c3 01             	add    $0x1,%ebx
	// Parse the command buffer into whitespace-separated arguments
	argc = 0;
	argv[argc] = 0;
	while (1) {
		// gobble whitespace
		while (*buf && strchr(WHITESPACE, *buf))
f0100b7f:	0f b6 03             	movzbl (%ebx),%eax
f0100b82:	84 c0                	test   %al,%al
f0100b84:	74 6a                	je     f0100bf0 <monitor+0xfe>
f0100b86:	0f be c0             	movsbl %al,%eax
f0100b89:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100b8d:	c7 04 24 c1 20 10 f0 	movl   $0xf01020c1,(%esp)
f0100b94:	e8 7d 0c 00 00       	call   f0101816 <strchr>
f0100b99:	85 c0                	test   %eax,%eax
f0100b9b:	75 dc                	jne    f0100b79 <monitor+0x87>
			*buf++ = 0;
		if (*buf == 0)
f0100b9d:	80 3b 00             	cmpb   $0x0,(%ebx)
f0100ba0:	74 4e                	je     f0100bf0 <monitor+0xfe>
			break;

		// save and scan past next arg
		if (argc == MAXARGS-1) {
f0100ba2:	83 fe 0f             	cmp    $0xf,%esi
f0100ba5:	75 16                	jne    f0100bbd <monitor+0xcb>
			cprintf("Too many arguments (max %d)\n", MAXARGS);
f0100ba7:	c7 44 24 04 10 00 00 	movl   $0x10,0x4(%esp)
f0100bae:	00 
f0100baf:	c7 04 24 c6 20 10 f0 	movl   $0xf01020c6,(%esp)
f0100bb6:	e8 fb 00 00 00       	call   f0100cb6 <cprintf>
f0100bbb:	eb 9c                	jmp    f0100b59 <monitor+0x67>
			return 0;
		}
		argv[argc++] = buf;
f0100bbd:	89 5c b5 a4          	mov    %ebx,-0x5c(%ebp,%esi,4)
f0100bc1:	83 c6 01             	add    $0x1,%esi
		while (*buf && !strchr(WHITESPACE, *buf))
f0100bc4:	0f b6 03             	movzbl (%ebx),%eax
f0100bc7:	84 c0                	test   %al,%al
f0100bc9:	75 0c                	jne    f0100bd7 <monitor+0xe5>
f0100bcb:	eb b2                	jmp    f0100b7f <monitor+0x8d>
			buf++;
f0100bcd:	83 c3 01             	add    $0x1,%ebx
		if (argc == MAXARGS-1) {
			cprintf("Too many arguments (max %d)\n", MAXARGS);
			return 0;
		}
		argv[argc++] = buf;
		while (*buf && !strchr(WHITESPACE, *buf))
f0100bd0:	0f b6 03             	movzbl (%ebx),%eax
f0100bd3:	84 c0                	test   %al,%al
f0100bd5:	74 a8                	je     f0100b7f <monitor+0x8d>
f0100bd7:	0f be c0             	movsbl %al,%eax
f0100bda:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100bde:	c7 04 24 c1 20 10 f0 	movl   $0xf01020c1,(%esp)
f0100be5:	e8 2c 0c 00 00       	call   f0101816 <strchr>
f0100bea:	85 c0                	test   %eax,%eax
f0100bec:	74 df                	je     f0100bcd <monitor+0xdb>
f0100bee:	eb 8f                	jmp    f0100b7f <monitor+0x8d>
			buf++;
	}
	argv[argc] = 0;
f0100bf0:	c7 44 b5 a4 00 00 00 	movl   $0x0,-0x5c(%ebp,%esi,4)
f0100bf7:	00 

	// Lookup and invoke the command
	if (argc == 0)
f0100bf8:	85 f6                	test   %esi,%esi
f0100bfa:	0f 84 59 ff ff ff    	je     f0100b59 <monitor+0x67>
f0100c00:	bb 40 23 10 f0       	mov    $0xf0102340,%ebx
f0100c05:	bf 00 00 00 00       	mov    $0x0,%edi
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
		if (strcmp(argv[0], commands[i].name) == 0)
f0100c0a:	8b 03                	mov    (%ebx),%eax
f0100c0c:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100c10:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f0100c13:	89 04 24             	mov    %eax,(%esp)
f0100c16:	e8 80 0b 00 00       	call   f010179b <strcmp>
f0100c1b:	85 c0                	test   %eax,%eax
f0100c1d:	75 24                	jne    f0100c43 <monitor+0x151>
			return commands[i].func(argc, argv, tf);
f0100c1f:	8d 04 7f             	lea    (%edi,%edi,2),%eax
f0100c22:	8b 55 08             	mov    0x8(%ebp),%edx
f0100c25:	89 54 24 08          	mov    %edx,0x8(%esp)
f0100c29:	8d 55 a4             	lea    -0x5c(%ebp),%edx
f0100c2c:	89 54 24 04          	mov    %edx,0x4(%esp)
f0100c30:	89 34 24             	mov    %esi,(%esp)
f0100c33:	ff 14 85 48 23 10 f0 	call   *-0xfefdcb8(,%eax,4)
	cprintf("H%x Wo%s", 57616, &i);

	while (1) {
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
f0100c3a:	85 c0                	test   %eax,%eax
f0100c3c:	78 28                	js     f0100c66 <monitor+0x174>
f0100c3e:	e9 16 ff ff ff       	jmp    f0100b59 <monitor+0x67>
	argv[argc] = 0;

	// Lookup and invoke the command
	if (argc == 0)
		return 0;
	for (i = 0; i < NCOMMANDS; i++) {
f0100c43:	83 c7 01             	add    $0x1,%edi
f0100c46:	83 c3 0c             	add    $0xc,%ebx
f0100c49:	83 ff 04             	cmp    $0x4,%edi
f0100c4c:	75 bc                	jne    f0100c0a <monitor+0x118>
		if (strcmp(argv[0], commands[i].name) == 0)
			return commands[i].func(argc, argv, tf);
	}
	cprintf("Unknown command '%s'\n", argv[0]);
f0100c4e:	8b 45 a4             	mov    -0x5c(%ebp),%eax
f0100c51:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100c55:	c7 04 24 e3 20 10 f0 	movl   $0xf01020e3,(%esp)
f0100c5c:	e8 55 00 00 00       	call   f0100cb6 <cprintf>
f0100c61:	e9 f3 fe ff ff       	jmp    f0100b59 <monitor+0x67>
		buf = readline("K> ");
		if (buf != NULL)
			if (runcmd(buf, tf) < 0)
				break;
	}
}
f0100c66:	83 c4 6c             	add    $0x6c,%esp
f0100c69:	5b                   	pop    %ebx
f0100c6a:	5e                   	pop    %esi
f0100c6b:	5f                   	pop    %edi
f0100c6c:	5d                   	pop    %ebp
f0100c6d:	c3                   	ret    
	...

f0100c70 <putch>:
#include <inc/stdarg.h>


static void
putch(int ch, int *cnt)
{
f0100c70:	55                   	push   %ebp
f0100c71:	89 e5                	mov    %esp,%ebp
f0100c73:	83 ec 18             	sub    $0x18,%esp
	cputchar(ch);
f0100c76:	8b 45 08             	mov    0x8(%ebp),%eax
f0100c79:	89 04 24             	mov    %eax,(%esp)
f0100c7c:	e8 c8 f9 ff ff       	call   f0100649 <cputchar>
	*cnt++;
}
f0100c81:	c9                   	leave  
f0100c82:	c3                   	ret    

f0100c83 <vcprintf>:

int
vcprintf(const char *fmt, va_list ap)
{
f0100c83:	55                   	push   %ebp
f0100c84:	89 e5                	mov    %esp,%ebp
f0100c86:	83 ec 28             	sub    $0x28,%esp
	int cnt = 0;
f0100c89:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	vprintfmt((void*)putch, &cnt, fmt, ap);
f0100c90:	8b 45 0c             	mov    0xc(%ebp),%eax
f0100c93:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0100c97:	8b 45 08             	mov    0x8(%ebp),%eax
f0100c9a:	89 44 24 08          	mov    %eax,0x8(%esp)
f0100c9e:	8d 45 f4             	lea    -0xc(%ebp),%eax
f0100ca1:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100ca5:	c7 04 24 70 0c 10 f0 	movl   $0xf0100c70,(%esp)
f0100cac:	e8 b9 04 00 00       	call   f010116a <vprintfmt>
	return cnt;
}
f0100cb1:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0100cb4:	c9                   	leave  
f0100cb5:	c3                   	ret    

f0100cb6 <cprintf>:

int
cprintf(const char *fmt, ...)
{
f0100cb6:	55                   	push   %ebp
f0100cb7:	89 e5                	mov    %esp,%ebp
f0100cb9:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int cnt;

	va_start(ap, fmt);
f0100cbc:	8d 45 0c             	lea    0xc(%ebp),%eax
	cnt = vcprintf(fmt, ap);
f0100cbf:	89 44 24 04          	mov    %eax,0x4(%esp)
f0100cc3:	8b 45 08             	mov    0x8(%ebp),%eax
f0100cc6:	89 04 24             	mov    %eax,(%esp)
f0100cc9:	e8 b5 ff ff ff       	call   f0100c83 <vcprintf>
	va_end(ap);

	return cnt;
}
f0100cce:	c9                   	leave  
f0100ccf:	c3                   	ret    

f0100cd0 <stab_binsearch>:
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
f0100cd0:	55                   	push   %ebp
f0100cd1:	89 e5                	mov    %esp,%ebp
f0100cd3:	57                   	push   %edi
f0100cd4:	56                   	push   %esi
f0100cd5:	53                   	push   %ebx
f0100cd6:	83 ec 10             	sub    $0x10,%esp
f0100cd9:	89 c3                	mov    %eax,%ebx
f0100cdb:	89 55 e8             	mov    %edx,-0x18(%ebp)
f0100cde:	89 4d e4             	mov    %ecx,-0x1c(%ebp)
f0100ce1:	8b 75 08             	mov    0x8(%ebp),%esi
	int l = *region_left, r = *region_right, any_matches = 0;
f0100ce4:	8b 0a                	mov    (%edx),%ecx
f0100ce6:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100ce9:	8b 00                	mov    (%eax),%eax
f0100ceb:	89 45 f0             	mov    %eax,-0x10(%ebp)
f0100cee:	c7 45 ec 00 00 00 00 	movl   $0x0,-0x14(%ebp)

	while (l <= r) {
f0100cf5:	eb 77                	jmp    f0100d6e <stab_binsearch+0x9e>
		int true_m = (l + r) / 2, m = true_m;
f0100cf7:	8b 45 f0             	mov    -0x10(%ebp),%eax
f0100cfa:	01 c8                	add    %ecx,%eax
f0100cfc:	bf 02 00 00 00       	mov    $0x2,%edi
f0100d01:	99                   	cltd   
f0100d02:	f7 ff                	idiv   %edi
f0100d04:	89 c2                	mov    %eax,%edx

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100d06:	eb 01                	jmp    f0100d09 <stab_binsearch+0x39>
			m--;
f0100d08:	4a                   	dec    %edx

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100d09:	39 ca                	cmp    %ecx,%edx
f0100d0b:	7c 1d                	jl     f0100d2a <stab_binsearch+0x5a>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0100d0d:	6b fa 0c             	imul   $0xc,%edx,%edi

	while (l <= r) {
		int true_m = (l + r) / 2, m = true_m;

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
f0100d10:	0f b6 7c 3b 04       	movzbl 0x4(%ebx,%edi,1),%edi
f0100d15:	39 f7                	cmp    %esi,%edi
f0100d17:	75 ef                	jne    f0100d08 <stab_binsearch+0x38>
f0100d19:	89 55 ec             	mov    %edx,-0x14(%ebp)
			continue;
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
f0100d1c:	6b fa 0c             	imul   $0xc,%edx,%edi
f0100d1f:	8b 7c 3b 08          	mov    0x8(%ebx,%edi,1),%edi
f0100d23:	3b 7d 0c             	cmp    0xc(%ebp),%edi
f0100d26:	73 18                	jae    f0100d40 <stab_binsearch+0x70>
f0100d28:	eb 05                	jmp    f0100d2f <stab_binsearch+0x5f>

		// search for earliest stab with right type
		while (m >= l && stabs[m].n_type != type)
			m--;
		if (m < l) {	// no match in [l, m]
			l = true_m + 1;
f0100d2a:	8d 48 01             	lea    0x1(%eax),%ecx
			continue;
f0100d2d:	eb 3f                	jmp    f0100d6e <stab_binsearch+0x9e>
		}

		// actual binary search
		any_matches = 1;
		if (stabs[m].n_value < addr) {
			*region_left = m;
f0100d2f:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0100d32:	89 11                	mov    %edx,(%ecx)
			l = true_m + 1;
f0100d34:	8d 48 01             	lea    0x1(%eax),%ecx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100d37:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100d3e:	eb 2e                	jmp    f0100d6e <stab_binsearch+0x9e>
		if (stabs[m].n_value < addr) {
			*region_left = m;
			l = true_m + 1;
		} else if (stabs[m].n_value > addr) {
f0100d40:	3b 7d 0c             	cmp    0xc(%ebp),%edi
f0100d43:	76 15                	jbe    f0100d5a <stab_binsearch+0x8a>
			*region_right = m - 1;
f0100d45:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0100d48:	4f                   	dec    %edi
f0100d49:	89 7d f0             	mov    %edi,-0x10(%ebp)
f0100d4c:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100d4f:	89 38                	mov    %edi,(%eax)
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100d51:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
f0100d58:	eb 14                	jmp    f0100d6e <stab_binsearch+0x9e>
			*region_right = m - 1;
			r = m - 1;
		} else {
			// exact match for 'addr', but continue loop to find
			// *region_right
			*region_left = m;
f0100d5a:	8b 7d ec             	mov    -0x14(%ebp),%edi
f0100d5d:	8b 4d e8             	mov    -0x18(%ebp),%ecx
f0100d60:	89 39                	mov    %edi,(%ecx)
			l = m;
			addr++;
f0100d62:	ff 45 0c             	incl   0xc(%ebp)
f0100d65:	89 d1                	mov    %edx,%ecx
			l = true_m + 1;
			continue;
		}

		// actual binary search
		any_matches = 1;
f0100d67:	c7 45 ec 01 00 00 00 	movl   $0x1,-0x14(%ebp)
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
	       int type, uintptr_t addr)
{
	int l = *region_left, r = *region_right, any_matches = 0;

	while (l <= r) {
f0100d6e:	3b 4d f0             	cmp    -0x10(%ebp),%ecx
f0100d71:	7e 84                	jle    f0100cf7 <stab_binsearch+0x27>
			l = m;
			addr++;
		}
	}

	if (!any_matches)
f0100d73:	83 7d ec 00          	cmpl   $0x0,-0x14(%ebp)
f0100d77:	75 0d                	jne    f0100d86 <stab_binsearch+0xb6>
		*region_right = *region_left - 1;
f0100d79:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100d7c:	8b 02                	mov    (%edx),%eax
f0100d7e:	48                   	dec    %eax
f0100d7f:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100d82:	89 01                	mov    %eax,(%ecx)
f0100d84:	eb 22                	jmp    f0100da8 <stab_binsearch+0xd8>
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100d86:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100d89:	8b 01                	mov    (%ecx),%eax
		     l > *region_left && stabs[l].n_type != type;
f0100d8b:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100d8e:	8b 0a                	mov    (%edx),%ecx

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100d90:	eb 01                	jmp    f0100d93 <stab_binsearch+0xc3>
		     l > *region_left && stabs[l].n_type != type;
		     l--)
f0100d92:	48                   	dec    %eax

	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
f0100d93:	39 c1                	cmp    %eax,%ecx
f0100d95:	7d 0c                	jge    f0100da3 <stab_binsearch+0xd3>
//		left = 0, right = 657;
//		stab_binsearch(stabs, &left, &right, N_SO, 0xf0100184);
//	will exit setting left = 118, right = 554.
//
static void
stab_binsearch(const struct Stab *stabs, int *region_left, int *region_right,
f0100d97:	6b d0 0c             	imul   $0xc,%eax,%edx
	if (!any_matches)
		*region_right = *region_left - 1;
	else {
		// find rightmost region containing 'addr'
		for (l = *region_right;
		     l > *region_left && stabs[l].n_type != type;
f0100d9a:	0f b6 54 13 04       	movzbl 0x4(%ebx,%edx,1),%edx
f0100d9f:	39 f2                	cmp    %esi,%edx
f0100da1:	75 ef                	jne    f0100d92 <stab_binsearch+0xc2>
		     l--)
			/* do nothing */;
		*region_left = l;
f0100da3:	8b 55 e8             	mov    -0x18(%ebp),%edx
f0100da6:	89 02                	mov    %eax,(%edx)
	}
}
f0100da8:	83 c4 10             	add    $0x10,%esp
f0100dab:	5b                   	pop    %ebx
f0100dac:	5e                   	pop    %esi
f0100dad:	5f                   	pop    %edi
f0100dae:	5d                   	pop    %ebp
f0100daf:	c3                   	ret    

f0100db0 <debuginfo_eip>:
//	negative if not.  But even if it returns negative it has stored some
//	information into '*info'.
//
int
debuginfo_eip(uintptr_t addr, struct Eipdebuginfo *info)
{
f0100db0:	55                   	push   %ebp
f0100db1:	89 e5                	mov    %esp,%ebp
f0100db3:	83 ec 58             	sub    $0x58,%esp
f0100db6:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f0100db9:	89 75 f8             	mov    %esi,-0x8(%ebp)
f0100dbc:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0100dbf:	8b 75 08             	mov    0x8(%ebp),%esi
f0100dc2:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	const struct Stab *stabs, *stab_end;
	const char *stabstr, *stabstr_end;
	int lfile, rfile, lfun, rfun, lline, rline;

	// Initialize *info
	info->eip_file = "<unknown>";
f0100dc5:	c7 03 70 23 10 f0    	movl   $0xf0102370,(%ebx)
	info->eip_line = 0;
f0100dcb:	c7 43 04 00 00 00 00 	movl   $0x0,0x4(%ebx)
	info->eip_fn_name = "<unknown>";
f0100dd2:	c7 43 08 70 23 10 f0 	movl   $0xf0102370,0x8(%ebx)
	info->eip_fn_namelen = 9;
f0100dd9:	c7 43 0c 09 00 00 00 	movl   $0x9,0xc(%ebx)
	info->eip_fn_addr = addr;
f0100de0:	89 73 10             	mov    %esi,0x10(%ebx)
	info->eip_fn_narg = 0;
f0100de3:	c7 43 14 00 00 00 00 	movl   $0x0,0x14(%ebx)

	// Find the relevant set of stabs
	if (addr >= ULIM) {
f0100dea:	81 fe ff ff 7f ef    	cmp    $0xef7fffff,%esi
f0100df0:	76 12                	jbe    f0100e04 <debuginfo_eip+0x54>
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100df2:	b8 4c 80 10 f0       	mov    $0xf010804c,%eax
f0100df7:	3d 55 66 10 f0       	cmp    $0xf0106655,%eax
f0100dfc:	0f 86 f1 01 00 00    	jbe    f0100ff3 <debuginfo_eip+0x243>
f0100e02:	eb 1c                	jmp    f0100e20 <debuginfo_eip+0x70>
		stab_end = __STAB_END__;
		stabstr = __STABSTR_BEGIN__;
		stabstr_end = __STABSTR_END__;
	} else {
		// Can't search for user-level addresses yet!
  	        panic("User address");
f0100e04:	c7 44 24 08 7a 23 10 	movl   $0xf010237a,0x8(%esp)
f0100e0b:	f0 
f0100e0c:	c7 44 24 04 7f 00 00 	movl   $0x7f,0x4(%esp)
f0100e13:	00 
f0100e14:	c7 04 24 87 23 10 f0 	movl   $0xf0102387,(%esp)
f0100e1b:	e8 c4 f2 ff ff       	call   f01000e4 <_panic>
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100e20:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
		// Can't search for user-level addresses yet!
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
f0100e25:	80 3d 4b 80 10 f0 00 	cmpb   $0x0,0xf010804b
f0100e2c:	0f 85 cd 01 00 00    	jne    f0100fff <debuginfo_eip+0x24f>
	// 'eip'.  First, we find the basic source file containing 'eip'.
	// Then, we look in that source file for the function.  Then we look
	// for the line number.

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
f0100e32:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
	rfile = (stab_end - stabs) - 1;
f0100e39:	b8 54 66 10 f0       	mov    $0xf0106654,%eax
f0100e3e:	2d a4 25 10 f0       	sub    $0xf01025a4,%eax
f0100e43:	c1 f8 02             	sar    $0x2,%eax
f0100e46:	69 c0 ab aa aa aa    	imul   $0xaaaaaaab,%eax,%eax
f0100e4c:	83 e8 01             	sub    $0x1,%eax
f0100e4f:	89 45 e0             	mov    %eax,-0x20(%ebp)
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
f0100e52:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100e56:	c7 04 24 64 00 00 00 	movl   $0x64,(%esp)
f0100e5d:	8d 4d e0             	lea    -0x20(%ebp),%ecx
f0100e60:	8d 55 e4             	lea    -0x1c(%ebp),%edx
f0100e63:	b8 a4 25 10 f0       	mov    $0xf01025a4,%eax
f0100e68:	e8 63 fe ff ff       	call   f0100cd0 <stab_binsearch>
	if (lfile == 0)
f0100e6d:	8b 55 e4             	mov    -0x1c(%ebp),%edx
		return -1;
f0100e70:	b8 ff ff ff ff       	mov    $0xffffffff,%eax

	// Search the entire set of stabs for the source file (type N_SO).
	lfile = 0;
	rfile = (stab_end - stabs) - 1;
	stab_binsearch(stabs, &lfile, &rfile, N_SO, addr);
	if (lfile == 0)
f0100e75:	85 d2                	test   %edx,%edx
f0100e77:	0f 84 82 01 00 00    	je     f0100fff <debuginfo_eip+0x24f>
		return -1;

	// Search within that file's stabs for the function definition
	// (N_FUN).
	lfun = lfile;
f0100e7d:	89 55 dc             	mov    %edx,-0x24(%ebp)
	rfun = rfile;
f0100e80:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100e83:	89 45 d8             	mov    %eax,-0x28(%ebp)
	stab_binsearch(stabs, &lfun, &rfun, N_FUN, addr);
f0100e86:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100e8a:	c7 04 24 24 00 00 00 	movl   $0x24,(%esp)
f0100e91:	8d 4d d8             	lea    -0x28(%ebp),%ecx
f0100e94:	8d 55 dc             	lea    -0x24(%ebp),%edx
f0100e97:	b8 a4 25 10 f0       	mov    $0xf01025a4,%eax
f0100e9c:	e8 2f fe ff ff       	call   f0100cd0 <stab_binsearch>

	if (lfun <= rfun) {
f0100ea1:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0100ea4:	8b 55 d8             	mov    -0x28(%ebp),%edx
f0100ea7:	39 d0                	cmp    %edx,%eax
f0100ea9:	7f 3d                	jg     f0100ee8 <debuginfo_eip+0x138>
		// stabs[lfun] points to the function name
		// in the string table, but check bounds just in case.
		if (stabs[lfun].n_strx < stabstr_end - stabstr)
f0100eab:	6b c8 0c             	imul   $0xc,%eax,%ecx
f0100eae:	8d b9 a4 25 10 f0    	lea    -0xfefda5c(%ecx),%edi
f0100eb4:	89 7d c0             	mov    %edi,-0x40(%ebp)
f0100eb7:	8b 89 a4 25 10 f0    	mov    -0xfefda5c(%ecx),%ecx
f0100ebd:	bf 4c 80 10 f0       	mov    $0xf010804c,%edi
f0100ec2:	81 ef 55 66 10 f0    	sub    $0xf0106655,%edi
f0100ec8:	39 f9                	cmp    %edi,%ecx
f0100eca:	73 09                	jae    f0100ed5 <debuginfo_eip+0x125>
			info->eip_fn_name = stabstr + stabs[lfun].n_strx;
f0100ecc:	81 c1 55 66 10 f0    	add    $0xf0106655,%ecx
f0100ed2:	89 4b 08             	mov    %ecx,0x8(%ebx)
		info->eip_fn_addr = stabs[lfun].n_value;
f0100ed5:	8b 7d c0             	mov    -0x40(%ebp),%edi
f0100ed8:	8b 4f 08             	mov    0x8(%edi),%ecx
f0100edb:	89 4b 10             	mov    %ecx,0x10(%ebx)
		addr -= info->eip_fn_addr;
f0100ede:	29 ce                	sub    %ecx,%esi
		// Search within the function definition for the line number.
		lline = lfun;
f0100ee0:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfun;
f0100ee3:	89 55 d0             	mov    %edx,-0x30(%ebp)
f0100ee6:	eb 0f                	jmp    f0100ef7 <debuginfo_eip+0x147>
	} else {
		// Couldn't find function stab!  Maybe we're in an assembly
		// file.  Search the whole file for the line number.
		info->eip_fn_addr = addr;
f0100ee8:	89 73 10             	mov    %esi,0x10(%ebx)
		lline = lfile;
f0100eeb:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0100eee:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		rline = rfile;
f0100ef1:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0100ef4:	89 45 d0             	mov    %eax,-0x30(%ebp)
	}
	// Ignore stuff after the colon.
	info->eip_fn_namelen = strfind(info->eip_fn_name, ':') - info->eip_fn_name;
f0100ef7:	c7 44 24 04 3a 00 00 	movl   $0x3a,0x4(%esp)
f0100efe:	00 
f0100eff:	8b 43 08             	mov    0x8(%ebx),%eax
f0100f02:	89 04 24             	mov    %eax,(%esp)
f0100f05:	e8 40 09 00 00       	call   f010184a <strfind>
f0100f0a:	2b 43 08             	sub    0x8(%ebx),%eax
f0100f0d:	89 43 0c             	mov    %eax,0xc(%ebx)
	// Hint:
	//	There's a particular stabs type used for line numbers.
	//	Look at the STABS documentation and <inc/stab.h> to find
	//	which one.
	// Your code here.
	stab_binsearch(stabs, &lline, &rline, N_SLINE, addr);
f0100f10:	89 74 24 04          	mov    %esi,0x4(%esp)
f0100f14:	c7 04 24 44 00 00 00 	movl   $0x44,(%esp)
f0100f1b:	8d 4d d0             	lea    -0x30(%ebp),%ecx
f0100f1e:	8d 55 d4             	lea    -0x2c(%ebp),%edx
f0100f21:	b8 a4 25 10 f0       	mov    $0xf01025a4,%eax
f0100f26:	e8 a5 fd ff ff       	call   f0100cd0 <stab_binsearch>
	if (lline <= rline) {
f0100f2b:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100f2e:	3b 45 d0             	cmp    -0x30(%ebp),%eax
f0100f31:	7f 0f                	jg     f0100f42 <debuginfo_eip+0x192>
		info->eip_line = stabs[lline].n_desc;
f0100f33:	6b c0 0c             	imul   $0xc,%eax,%eax
f0100f36:	0f b7 80 aa 25 10 f0 	movzwl -0xfefda56(%eax),%eax
f0100f3d:	89 43 04             	mov    %eax,0x4(%ebx)
f0100f40:	eb 07                	jmp    f0100f49 <debuginfo_eip+0x199>
	} else {
		info->eip_line = -1;
f0100f42:	c7 43 04 ff ff ff ff 	movl   $0xffffffff,0x4(%ebx)
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100f49:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f0100f4c:	8b 4d e4             	mov    -0x1c(%ebp),%ecx
f0100f4f:	39 c8                	cmp    %ecx,%eax
f0100f51:	7c 5f                	jl     f0100fb2 <debuginfo_eip+0x202>
	       && stabs[lline].n_type != N_SOL
f0100f53:	89 c2                	mov    %eax,%edx
f0100f55:	6b f0 0c             	imul   $0xc,%eax,%esi
f0100f58:	80 be a8 25 10 f0 84 	cmpb   $0x84,-0xfefda58(%esi)
f0100f5f:	75 18                	jne    f0100f79 <debuginfo_eip+0x1c9>
f0100f61:	eb 30                	jmp    f0100f93 <debuginfo_eip+0x1e3>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
		lline--;
f0100f63:	83 e8 01             	sub    $0x1,%eax
	// Search backwards from the line number for the relevant filename
	// stab.
	// We can't just use the "lfile" stab because inlined functions
	// can interpolate code from a different file!
	// Such included source files use the N_SOL stab type.
	while (lline >= lfile
f0100f66:	39 c1                	cmp    %eax,%ecx
f0100f68:	7f 48                	jg     f0100fb2 <debuginfo_eip+0x202>
	       && stabs[lline].n_type != N_SOL
f0100f6a:	89 c2                	mov    %eax,%edx
f0100f6c:	8d 34 40             	lea    (%eax,%eax,2),%esi
f0100f6f:	80 3c b5 a8 25 10 f0 	cmpb   $0x84,-0xfefda58(,%esi,4)
f0100f76:	84 
f0100f77:	74 1a                	je     f0100f93 <debuginfo_eip+0x1e3>
	       && (stabs[lline].n_type != N_SO || !stabs[lline].n_value))
f0100f79:	8d 14 52             	lea    (%edx,%edx,2),%edx
f0100f7c:	8d 14 95 a4 25 10 f0 	lea    -0xfefda5c(,%edx,4),%edx
f0100f83:	80 7a 04 64          	cmpb   $0x64,0x4(%edx)
f0100f87:	75 da                	jne    f0100f63 <debuginfo_eip+0x1b3>
f0100f89:	83 7a 08 00          	cmpl   $0x0,0x8(%edx)
f0100f8d:	74 d4                	je     f0100f63 <debuginfo_eip+0x1b3>
		lline--;
	if (lline >= lfile && stabs[lline].n_strx < stabstr_end - stabstr)
f0100f8f:	39 c8                	cmp    %ecx,%eax
f0100f91:	7c 1f                	jl     f0100fb2 <debuginfo_eip+0x202>
f0100f93:	6b c0 0c             	imul   $0xc,%eax,%eax
f0100f96:	8b 80 a4 25 10 f0    	mov    -0xfefda5c(%eax),%eax
f0100f9c:	ba 4c 80 10 f0       	mov    $0xf010804c,%edx
f0100fa1:	81 ea 55 66 10 f0    	sub    $0xf0106655,%edx
f0100fa7:	39 d0                	cmp    %edx,%eax
f0100fa9:	73 07                	jae    f0100fb2 <debuginfo_eip+0x202>
		info->eip_file = stabstr + stabs[lline].n_strx;
f0100fab:	05 55 66 10 f0       	add    $0xf0106655,%eax
f0100fb0:	89 03                	mov    %eax,(%ebx)


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100fb2:	8b 55 dc             	mov    -0x24(%ebp),%edx
f0100fb5:	8b 4d d8             	mov    -0x28(%ebp),%ecx
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100fb8:	b8 00 00 00 00       	mov    $0x0,%eax
		info->eip_file = stabstr + stabs[lline].n_strx;


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
f0100fbd:	39 ca                	cmp    %ecx,%edx
f0100fbf:	7d 3e                	jge    f0100fff <debuginfo_eip+0x24f>
		for (lline = lfun + 1;
f0100fc1:	83 c2 01             	add    $0x1,%edx
f0100fc4:	39 d1                	cmp    %edx,%ecx
f0100fc6:	7e 37                	jle    f0100fff <debuginfo_eip+0x24f>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100fc8:	6b f2 0c             	imul   $0xc,%edx,%esi
f0100fcb:	80 be a8 25 10 f0 a0 	cmpb   $0xa0,-0xfefda58(%esi)
f0100fd2:	75 2b                	jne    f0100fff <debuginfo_eip+0x24f>
		     lline++)
			info->eip_fn_narg++;
f0100fd4:	83 43 14 01          	addl   $0x1,0x14(%ebx)
	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
f0100fd8:	83 c2 01             	add    $0x1,%edx


	// Set eip_fn_narg to the number of arguments taken by the function,
	// or 0 if there was no containing function.
	if (lfun < rfun)
		for (lline = lfun + 1;
f0100fdb:	39 d1                	cmp    %edx,%ecx
f0100fdd:	7e 1b                	jle    f0100ffa <debuginfo_eip+0x24a>
		     lline < rfun && stabs[lline].n_type == N_PSYM;
f0100fdf:	8d 04 52             	lea    (%edx,%edx,2),%eax
f0100fe2:	80 3c 85 a8 25 10 f0 	cmpb   $0xa0,-0xfefda58(,%eax,4)
f0100fe9:	a0 
f0100fea:	74 e8                	je     f0100fd4 <debuginfo_eip+0x224>
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100fec:	b8 00 00 00 00       	mov    $0x0,%eax
f0100ff1:	eb 0c                	jmp    f0100fff <debuginfo_eip+0x24f>
  	        panic("User address");
	}

	// String table validity checks
	if (stabstr_end <= stabstr || stabstr_end[-1] != 0)
		return -1;
f0100ff3:	b8 ff ff ff ff       	mov    $0xffffffff,%eax
f0100ff8:	eb 05                	jmp    f0100fff <debuginfo_eip+0x24f>
		for (lline = lfun + 1;
		     lline < rfun && stabs[lline].n_type == N_PSYM;
		     lline++)
			info->eip_fn_narg++;

	return 0;
f0100ffa:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0100fff:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f0101002:	8b 75 f8             	mov    -0x8(%ebp),%esi
f0101005:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0101008:	89 ec                	mov    %ebp,%esp
f010100a:	5d                   	pop    %ebp
f010100b:	c3                   	ret    
f010100c:	00 00                	add    %al,(%eax)
	...

f0101010 <printnum>:
 * using specified putch function and associated pointer putdat.
 */
static void
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
f0101010:	55                   	push   %ebp
f0101011:	89 e5                	mov    %esp,%ebp
f0101013:	57                   	push   %edi
f0101014:	56                   	push   %esi
f0101015:	53                   	push   %ebx
f0101016:	83 ec 3c             	sub    $0x3c,%esp
f0101019:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f010101c:	89 d7                	mov    %edx,%edi
f010101e:	8b 45 08             	mov    0x8(%ebp),%eax
f0101021:	89 45 dc             	mov    %eax,-0x24(%ebp)
f0101024:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101027:	89 45 e0             	mov    %eax,-0x20(%ebp)
f010102a:	8b 5d 14             	mov    0x14(%ebp),%ebx
f010102d:	8b 75 18             	mov    0x18(%ebp),%esi
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
f0101030:	b8 00 00 00 00       	mov    $0x0,%eax
f0101035:	3b 45 e0             	cmp    -0x20(%ebp),%eax
f0101038:	72 11                	jb     f010104b <printnum+0x3b>
f010103a:	8b 45 dc             	mov    -0x24(%ebp),%eax
f010103d:	39 45 10             	cmp    %eax,0x10(%ebp)
f0101040:	76 09                	jbe    f010104b <printnum+0x3b>
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f0101042:	83 eb 01             	sub    $0x1,%ebx
f0101045:	85 db                	test   %ebx,%ebx
f0101047:	7f 51                	jg     f010109a <printnum+0x8a>
f0101049:	eb 5e                	jmp    f01010a9 <printnum+0x99>
printnum(void (*putch)(int, void*), void *putdat,
	 unsigned long long num, unsigned base, int width, int padc)
{
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
f010104b:	89 74 24 10          	mov    %esi,0x10(%esp)
f010104f:	83 eb 01             	sub    $0x1,%ebx
f0101052:	89 5c 24 0c          	mov    %ebx,0xc(%esp)
f0101056:	8b 45 10             	mov    0x10(%ebp),%eax
f0101059:	89 44 24 08          	mov    %eax,0x8(%esp)
f010105d:	8b 5c 24 08          	mov    0x8(%esp),%ebx
f0101061:	8b 74 24 0c          	mov    0xc(%esp),%esi
f0101065:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f010106c:	00 
f010106d:	8b 45 dc             	mov    -0x24(%ebp),%eax
f0101070:	89 04 24             	mov    %eax,(%esp)
f0101073:	8b 45 e0             	mov    -0x20(%ebp),%eax
f0101076:	89 44 24 04          	mov    %eax,0x4(%esp)
f010107a:	e8 41 0a 00 00       	call   f0101ac0 <__udivdi3>
f010107f:	89 5c 24 08          	mov    %ebx,0x8(%esp)
f0101083:	89 74 24 0c          	mov    %esi,0xc(%esp)
f0101087:	89 04 24             	mov    %eax,(%esp)
f010108a:	89 54 24 04          	mov    %edx,0x4(%esp)
f010108e:	89 fa                	mov    %edi,%edx
f0101090:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f0101093:	e8 78 ff ff ff       	call   f0101010 <printnum>
f0101098:	eb 0f                	jmp    f01010a9 <printnum+0x99>
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
			putch(padc, putdat);
f010109a:	89 7c 24 04          	mov    %edi,0x4(%esp)
f010109e:	89 34 24             	mov    %esi,(%esp)
f01010a1:	ff 55 e4             	call   *-0x1c(%ebp)
	// first recursively print all preceding (more significant) digits
	if (num >= base) {
		printnum(putch, putdat, num / base, base, width - 1, padc);
	} else {
		// print any needed pad characters before first digit
		while (--width > 0)
f01010a4:	83 eb 01             	sub    $0x1,%ebx
f01010a7:	75 f1                	jne    f010109a <printnum+0x8a>
			putch(padc, putdat);
	}

	// then print this (the least significant) digit
	putch("0123456789abcdef"[num % base], putdat);
f01010a9:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01010ad:	8b 7c 24 04          	mov    0x4(%esp),%edi
f01010b1:	8b 45 10             	mov    0x10(%ebp),%eax
f01010b4:	89 44 24 08          	mov    %eax,0x8(%esp)
f01010b8:	c7 44 24 0c 00 00 00 	movl   $0x0,0xc(%esp)
f01010bf:	00 
f01010c0:	8b 45 dc             	mov    -0x24(%ebp),%eax
f01010c3:	89 04 24             	mov    %eax,(%esp)
f01010c6:	8b 45 e0             	mov    -0x20(%ebp),%eax
f01010c9:	89 44 24 04          	mov    %eax,0x4(%esp)
f01010cd:	e8 1e 0b 00 00       	call   f0101bf0 <__umoddi3>
f01010d2:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01010d6:	0f be 80 95 23 10 f0 	movsbl -0xfefdc6b(%eax),%eax
f01010dd:	89 04 24             	mov    %eax,(%esp)
f01010e0:	ff 55 e4             	call   *-0x1c(%ebp)
}
f01010e3:	83 c4 3c             	add    $0x3c,%esp
f01010e6:	5b                   	pop    %ebx
f01010e7:	5e                   	pop    %esi
f01010e8:	5f                   	pop    %edi
f01010e9:	5d                   	pop    %ebp
f01010ea:	c3                   	ret    

f01010eb <getuint>:

// Get an unsigned int of various possible sizes from a varargs list,
// depending on the lflag parameter.
static unsigned long long
getuint(va_list *ap, int lflag)
{
f01010eb:	55                   	push   %ebp
f01010ec:	89 e5                	mov    %esp,%ebp
	if (lflag >= 2)
f01010ee:	83 fa 01             	cmp    $0x1,%edx
f01010f1:	7e 0e                	jle    f0101101 <getuint+0x16>
		return va_arg(*ap, unsigned long long);
f01010f3:	8b 10                	mov    (%eax),%edx
f01010f5:	8d 4a 08             	lea    0x8(%edx),%ecx
f01010f8:	89 08                	mov    %ecx,(%eax)
f01010fa:	8b 02                	mov    (%edx),%eax
f01010fc:	8b 52 04             	mov    0x4(%edx),%edx
f01010ff:	eb 22                	jmp    f0101123 <getuint+0x38>
	else if (lflag)
f0101101:	85 d2                	test   %edx,%edx
f0101103:	74 10                	je     f0101115 <getuint+0x2a>
		return va_arg(*ap, unsigned long);
f0101105:	8b 10                	mov    (%eax),%edx
f0101107:	8d 4a 04             	lea    0x4(%edx),%ecx
f010110a:	89 08                	mov    %ecx,(%eax)
f010110c:	8b 02                	mov    (%edx),%eax
f010110e:	ba 00 00 00 00       	mov    $0x0,%edx
f0101113:	eb 0e                	jmp    f0101123 <getuint+0x38>
	else
		return va_arg(*ap, unsigned int);
f0101115:	8b 10                	mov    (%eax),%edx
f0101117:	8d 4a 04             	lea    0x4(%edx),%ecx
f010111a:	89 08                	mov    %ecx,(%eax)
f010111c:	8b 02                	mov    (%edx),%eax
f010111e:	ba 00 00 00 00       	mov    $0x0,%edx
}
f0101123:	5d                   	pop    %ebp
f0101124:	c3                   	ret    

f0101125 <sprintputch>:
	int cnt;
};

static void
sprintputch(int ch, struct sprintbuf *b)
{
f0101125:	55                   	push   %ebp
f0101126:	89 e5                	mov    %esp,%ebp
f0101128:	8b 45 0c             	mov    0xc(%ebp),%eax
	b->cnt++;
f010112b:	83 40 08 01          	addl   $0x1,0x8(%eax)
	if (b->buf < b->ebuf)
f010112f:	8b 10                	mov    (%eax),%edx
f0101131:	3b 50 04             	cmp    0x4(%eax),%edx
f0101134:	73 0a                	jae    f0101140 <sprintputch+0x1b>
		*b->buf++ = ch;
f0101136:	8b 4d 08             	mov    0x8(%ebp),%ecx
f0101139:	88 0a                	mov    %cl,(%edx)
f010113b:	83 c2 01             	add    $0x1,%edx
f010113e:	89 10                	mov    %edx,(%eax)
}
f0101140:	5d                   	pop    %ebp
f0101141:	c3                   	ret    

f0101142 <printfmt>:
	}
}

void
printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...)
{
f0101142:	55                   	push   %ebp
f0101143:	89 e5                	mov    %esp,%ebp
f0101145:	83 ec 18             	sub    $0x18,%esp
	va_list ap;

	va_start(ap, fmt);
f0101148:	8d 45 14             	lea    0x14(%ebp),%eax
	vprintfmt(putch, putdat, fmt, ap);
f010114b:	89 44 24 0c          	mov    %eax,0xc(%esp)
f010114f:	8b 45 10             	mov    0x10(%ebp),%eax
f0101152:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101156:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101159:	89 44 24 04          	mov    %eax,0x4(%esp)
f010115d:	8b 45 08             	mov    0x8(%ebp),%eax
f0101160:	89 04 24             	mov    %eax,(%esp)
f0101163:	e8 02 00 00 00       	call   f010116a <vprintfmt>
	va_end(ap);
}
f0101168:	c9                   	leave  
f0101169:	c3                   	ret    

f010116a <vprintfmt>:
// Main function to format and print a string.
void printfmt(void (*putch)(int, void*), void *putdat, const char *fmt, ...);

void
vprintfmt(void (*putch)(int, void*), void *putdat, const char *fmt, va_list ap)
{
f010116a:	55                   	push   %ebp
f010116b:	89 e5                	mov    %esp,%ebp
f010116d:	57                   	push   %edi
f010116e:	56                   	push   %esi
f010116f:	53                   	push   %ebx
f0101170:	83 ec 4c             	sub    $0x4c,%esp
f0101173:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101176:	8b 75 10             	mov    0x10(%ebp),%esi
f0101179:	eb 12                	jmp    f010118d <vprintfmt+0x23>
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
			if (ch == '\0')
f010117b:	85 c0                	test   %eax,%eax
f010117d:	0f 84 a9 03 00 00    	je     f010152c <vprintfmt+0x3c2>
				return;
			putch(ch, putdat);
f0101183:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101187:	89 04 24             	mov    %eax,(%esp)
f010118a:	ff 55 08             	call   *0x8(%ebp)
	unsigned long long num;
	int base, lflag, width, precision, altflag;
	char padc;

	while (1) {
		while ((ch = *(unsigned char *) fmt++) != '%') {
f010118d:	0f b6 06             	movzbl (%esi),%eax
f0101190:	83 c6 01             	add    $0x1,%esi
f0101193:	83 f8 25             	cmp    $0x25,%eax
f0101196:	75 e3                	jne    f010117b <vprintfmt+0x11>
f0101198:	c6 45 d8 20          	movb   $0x20,-0x28(%ebp)
f010119c:	c7 45 dc 00 00 00 00 	movl   $0x0,-0x24(%ebp)
f01011a3:	bf ff ff ff ff       	mov    $0xffffffff,%edi
f01011a8:	c7 45 e4 ff ff ff ff 	movl   $0xffffffff,-0x1c(%ebp)
f01011af:	b9 00 00 00 00       	mov    $0x0,%ecx
f01011b4:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f01011b7:	eb 2b                	jmp    f01011e4 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01011b9:	8b 75 e0             	mov    -0x20(%ebp),%esi

		// flag to pad on the right
		case '-':
			padc = '-';
f01011bc:	c6 45 d8 2d          	movb   $0x2d,-0x28(%ebp)
f01011c0:	eb 22                	jmp    f01011e4 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01011c2:	8b 75 e0             	mov    -0x20(%ebp),%esi
			padc = '-';
			goto reswitch;

		// flag to pad with 0's instead of spaces
		case '0':
			padc = '0';
f01011c5:	c6 45 d8 30          	movb   $0x30,-0x28(%ebp)
f01011c9:	eb 19                	jmp    f01011e4 <vprintfmt+0x7a>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01011cb:	8b 75 e0             	mov    -0x20(%ebp),%esi
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
				width = 0;
f01011ce:	c7 45 e4 00 00 00 00 	movl   $0x0,-0x1c(%ebp)
f01011d5:	eb 0d                	jmp    f01011e4 <vprintfmt+0x7a>
			altflag = 1;
			goto reswitch;

		process_precision:
			if (width < 0)
				width = precision, precision = -1;
f01011d7:	8b 45 d4             	mov    -0x2c(%ebp),%eax
f01011da:	89 45 e4             	mov    %eax,-0x1c(%ebp)
f01011dd:	c7 45 d4 ff ff ff ff 	movl   $0xffffffff,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01011e4:	0f b6 06             	movzbl (%esi),%eax
f01011e7:	0f b6 d0             	movzbl %al,%edx
f01011ea:	8d 7e 01             	lea    0x1(%esi),%edi
f01011ed:	89 7d e0             	mov    %edi,-0x20(%ebp)
f01011f0:	83 e8 23             	sub    $0x23,%eax
f01011f3:	3c 55                	cmp    $0x55,%al
f01011f5:	0f 87 0b 03 00 00    	ja     f0101506 <vprintfmt+0x39c>
f01011fb:	0f b6 c0             	movzbl %al,%eax
f01011fe:	ff 24 85 20 24 10 f0 	jmp    *-0xfefdbe0(,%eax,4)
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
f0101205:	83 ea 30             	sub    $0x30,%edx
f0101208:	89 55 d4             	mov    %edx,-0x2c(%ebp)
				ch = *fmt;
f010120b:	0f be 46 01          	movsbl 0x1(%esi),%eax
				if (ch < '0' || ch > '9')
f010120f:	8d 50 d0             	lea    -0x30(%eax),%edx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101212:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
				precision = precision * 10 + ch - '0';
				ch = *fmt;
				if (ch < '0' || ch > '9')
f0101215:	83 fa 09             	cmp    $0x9,%edx
f0101218:	77 4a                	ja     f0101264 <vprintfmt+0xfa>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010121a:	8b 7d d4             	mov    -0x2c(%ebp),%edi
		case '5':
		case '6':
		case '7':
		case '8':
		case '9':
			for (precision = 0; ; ++fmt) {
f010121d:	83 c6 01             	add    $0x1,%esi
				precision = precision * 10 + ch - '0';
f0101220:	8d 14 bf             	lea    (%edi,%edi,4),%edx
f0101223:	8d 7c 50 d0          	lea    -0x30(%eax,%edx,2),%edi
				ch = *fmt;
f0101227:	0f be 06             	movsbl (%esi),%eax
				if (ch < '0' || ch > '9')
f010122a:	8d 50 d0             	lea    -0x30(%eax),%edx
f010122d:	83 fa 09             	cmp    $0x9,%edx
f0101230:	76 eb                	jbe    f010121d <vprintfmt+0xb3>
f0101232:	89 7d d4             	mov    %edi,-0x2c(%ebp)
f0101235:	eb 2d                	jmp    f0101264 <vprintfmt+0xfa>
					break;
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
f0101237:	8b 45 14             	mov    0x14(%ebp),%eax
f010123a:	8d 50 04             	lea    0x4(%eax),%edx
f010123d:	89 55 14             	mov    %edx,0x14(%ebp)
f0101240:	8b 00                	mov    (%eax),%eax
f0101242:	89 45 d4             	mov    %eax,-0x2c(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101245:	8b 75 e0             	mov    -0x20(%ebp),%esi
			}
			goto process_precision;

		case '*':
			precision = va_arg(ap, int);
			goto process_precision;
f0101248:	eb 1a                	jmp    f0101264 <vprintfmt+0xfa>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f010124a:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case '*':
			precision = va_arg(ap, int);
			goto process_precision;

		case '.':
			if (width < 0)
f010124d:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0101251:	79 91                	jns    f01011e4 <vprintfmt+0x7a>
f0101253:	e9 73 ff ff ff       	jmp    f01011cb <vprintfmt+0x61>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101258:	8b 75 e0             	mov    -0x20(%ebp),%esi
			if (width < 0)
				width = 0;
			goto reswitch;

		case '#':
			altflag = 1;
f010125b:	c7 45 dc 01 00 00 00 	movl   $0x1,-0x24(%ebp)
			goto reswitch;
f0101262:	eb 80                	jmp    f01011e4 <vprintfmt+0x7a>

		process_precision:
			if (width < 0)
f0101264:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f0101268:	0f 89 76 ff ff ff    	jns    f01011e4 <vprintfmt+0x7a>
f010126e:	e9 64 ff ff ff       	jmp    f01011d7 <vprintfmt+0x6d>
				width = precision, precision = -1;
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
f0101273:	83 c1 01             	add    $0x1,%ecx
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101276:	8b 75 e0             	mov    -0x20(%ebp),%esi
			goto reswitch;

		// long flag (doubled for long long)
		case 'l':
			lflag++;
			goto reswitch;
f0101279:	e9 66 ff ff ff       	jmp    f01011e4 <vprintfmt+0x7a>

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
f010127e:	8b 45 14             	mov    0x14(%ebp),%eax
f0101281:	8d 50 04             	lea    0x4(%eax),%edx
f0101284:	89 55 14             	mov    %edx,0x14(%ebp)
f0101287:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010128b:	8b 00                	mov    (%eax),%eax
f010128d:	89 04 24             	mov    %eax,(%esp)
f0101290:	ff 55 08             	call   *0x8(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f0101293:	8b 75 e0             	mov    -0x20(%ebp),%esi
			goto reswitch;

		// character
		case 'c':
			putch(va_arg(ap, int), putdat);
			break;
f0101296:	e9 f2 fe ff ff       	jmp    f010118d <vprintfmt+0x23>

		// error message
		case 'e':
			err = va_arg(ap, int);
f010129b:	8b 45 14             	mov    0x14(%ebp),%eax
f010129e:	8d 50 04             	lea    0x4(%eax),%edx
f01012a1:	89 55 14             	mov    %edx,0x14(%ebp)
f01012a4:	8b 00                	mov    (%eax),%eax
f01012a6:	89 c2                	mov    %eax,%edx
f01012a8:	c1 fa 1f             	sar    $0x1f,%edx
f01012ab:	31 d0                	xor    %edx,%eax
f01012ad:	29 d0                	sub    %edx,%eax
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
f01012af:	83 f8 06             	cmp    $0x6,%eax
f01012b2:	7f 0b                	jg     f01012bf <vprintfmt+0x155>
f01012b4:	8b 14 85 78 25 10 f0 	mov    -0xfefda88(,%eax,4),%edx
f01012bb:	85 d2                	test   %edx,%edx
f01012bd:	75 23                	jne    f01012e2 <vprintfmt+0x178>
				printfmt(putch, putdat, "error %d", err);
f01012bf:	89 44 24 0c          	mov    %eax,0xc(%esp)
f01012c3:	c7 44 24 08 ad 23 10 	movl   $0xf01023ad,0x8(%esp)
f01012ca:	f0 
f01012cb:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01012cf:	8b 7d 08             	mov    0x8(%ebp),%edi
f01012d2:	89 3c 24             	mov    %edi,(%esp)
f01012d5:	e8 68 fe ff ff       	call   f0101142 <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01012da:	8b 75 e0             	mov    -0x20(%ebp),%esi
		case 'e':
			err = va_arg(ap, int);
			if (err < 0)
				err = -err;
			if (err >= MAXERROR || (p = error_string[err]) == NULL)
				printfmt(putch, putdat, "error %d", err);
f01012dd:	e9 ab fe ff ff       	jmp    f010118d <vprintfmt+0x23>
			else
				printfmt(putch, putdat, "%s", p);
f01012e2:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01012e6:	c7 44 24 08 ba 20 10 	movl   $0xf01020ba,0x8(%esp)
f01012ed:	f0 
f01012ee:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01012f2:	8b 7d 08             	mov    0x8(%ebp),%edi
f01012f5:	89 3c 24             	mov    %edi,(%esp)
f01012f8:	e8 45 fe ff ff       	call   f0101142 <printfmt>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01012fd:	8b 75 e0             	mov    -0x20(%ebp),%esi
f0101300:	e9 88 fe ff ff       	jmp    f010118d <vprintfmt+0x23>
f0101305:	8b 7d d4             	mov    -0x2c(%ebp),%edi
f0101308:	8b 45 e4             	mov    -0x1c(%ebp),%eax
f010130b:	89 45 d4             	mov    %eax,-0x2c(%ebp)
				printfmt(putch, putdat, "%s", p);
			break;

		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
f010130e:	8b 45 14             	mov    0x14(%ebp),%eax
f0101311:	8d 50 04             	lea    0x4(%eax),%edx
f0101314:	89 55 14             	mov    %edx,0x14(%ebp)
f0101317:	8b 30                	mov    (%eax),%esi
				p = "(null)";
f0101319:	85 f6                	test   %esi,%esi
f010131b:	ba a6 23 10 f0       	mov    $0xf01023a6,%edx
f0101320:	0f 44 f2             	cmove  %edx,%esi
			if (width > 0 && padc != '-')
f0101323:	83 7d d4 00          	cmpl   $0x0,-0x2c(%ebp)
f0101327:	7e 06                	jle    f010132f <vprintfmt+0x1c5>
f0101329:	80 7d d8 2d          	cmpb   $0x2d,-0x28(%ebp)
f010132d:	75 10                	jne    f010133f <vprintfmt+0x1d5>
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f010132f:	0f be 06             	movsbl (%esi),%eax
f0101332:	83 c6 01             	add    $0x1,%esi
f0101335:	85 c0                	test   %eax,%eax
f0101337:	0f 85 86 00 00 00    	jne    f01013c3 <vprintfmt+0x259>
f010133d:	eb 76                	jmp    f01013b5 <vprintfmt+0x24b>
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010133f:	89 7c 24 04          	mov    %edi,0x4(%esp)
f0101343:	89 34 24             	mov    %esi,(%esp)
f0101346:	e8 60 03 00 00       	call   f01016ab <strnlen>
f010134b:	8b 55 d4             	mov    -0x2c(%ebp),%edx
f010134e:	29 c2                	sub    %eax,%edx
f0101350:	89 55 e4             	mov    %edx,-0x1c(%ebp)
f0101353:	85 d2                	test   %edx,%edx
f0101355:	7e d8                	jle    f010132f <vprintfmt+0x1c5>
					putch(padc, putdat);
f0101357:	0f be 45 d8          	movsbl -0x28(%ebp),%eax
f010135b:	89 75 d4             	mov    %esi,-0x2c(%ebp)
f010135e:	89 d6                	mov    %edx,%esi
f0101360:	89 7d d0             	mov    %edi,-0x30(%ebp)
f0101363:	89 c7                	mov    %eax,%edi
f0101365:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101369:	89 3c 24             	mov    %edi,(%esp)
f010136c:	ff 55 08             	call   *0x8(%ebp)
		// string
		case 's':
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
f010136f:	83 ee 01             	sub    $0x1,%esi
f0101372:	75 f1                	jne    f0101365 <vprintfmt+0x1fb>
f0101374:	89 75 e4             	mov    %esi,-0x1c(%ebp)
f0101377:	8b 75 d4             	mov    -0x2c(%ebp),%esi
f010137a:	8b 7d d0             	mov    -0x30(%ebp),%edi
f010137d:	eb b0                	jmp    f010132f <vprintfmt+0x1c5>
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
f010137f:	83 7d dc 00          	cmpl   $0x0,-0x24(%ebp)
f0101383:	74 18                	je     f010139d <vprintfmt+0x233>
f0101385:	8d 50 e0             	lea    -0x20(%eax),%edx
f0101388:	83 fa 5e             	cmp    $0x5e,%edx
f010138b:	76 10                	jbe    f010139d <vprintfmt+0x233>
					putch('?', putdat);
f010138d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101391:	c7 04 24 3f 00 00 00 	movl   $0x3f,(%esp)
f0101398:	ff 55 08             	call   *0x8(%ebp)
f010139b:	eb 0a                	jmp    f01013a7 <vprintfmt+0x23d>
				else
					putch(ch, putdat);
f010139d:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01013a1:	89 04 24             	mov    %eax,(%esp)
f01013a4:	ff 55 08             	call   *0x8(%ebp)
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01013a7:	83 6d e4 01          	subl   $0x1,-0x1c(%ebp)
f01013ab:	0f be 06             	movsbl (%esi),%eax
f01013ae:	83 c6 01             	add    $0x1,%esi
f01013b1:	85 c0                	test   %eax,%eax
f01013b3:	75 0e                	jne    f01013c3 <vprintfmt+0x259>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01013b5:	8b 75 e0             	mov    -0x20(%ebp),%esi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f01013b8:	83 7d e4 00          	cmpl   $0x0,-0x1c(%ebp)
f01013bc:	7f 16                	jg     f01013d4 <vprintfmt+0x26a>
f01013be:	e9 ca fd ff ff       	jmp    f010118d <vprintfmt+0x23>
			if ((p = va_arg(ap, char *)) == NULL)
				p = "(null)";
			if (width > 0 && padc != '-')
				for (width -= strnlen(p, precision); width > 0; width--)
					putch(padc, putdat);
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
f01013c3:	85 ff                	test   %edi,%edi
f01013c5:	78 b8                	js     f010137f <vprintfmt+0x215>
f01013c7:	83 ef 01             	sub    $0x1,%edi
f01013ca:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f01013d0:	79 ad                	jns    f010137f <vprintfmt+0x215>
f01013d2:	eb e1                	jmp    f01013b5 <vprintfmt+0x24b>
f01013d4:	8b 75 e4             	mov    -0x1c(%ebp),%esi
f01013d7:	8b 7d 08             	mov    0x8(%ebp),%edi
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
				putch(' ', putdat);
f01013da:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01013de:	c7 04 24 20 00 00 00 	movl   $0x20,(%esp)
f01013e5:	ff d7                	call   *%edi
			for (; (ch = *p++) != '\0' && (precision < 0 || --precision >= 0); width--)
				if (altflag && (ch < ' ' || ch > '~'))
					putch('?', putdat);
				else
					putch(ch, putdat);
			for (; width > 0; width--)
f01013e7:	83 ee 01             	sub    $0x1,%esi
f01013ea:	75 ee                	jne    f01013da <vprintfmt+0x270>
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01013ec:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01013ef:	e9 99 fd ff ff       	jmp    f010118d <vprintfmt+0x23>
// Same as getuint but signed - can't use getuint
// because of sign extension
static long long
getint(va_list *ap, int lflag)
{
	if (lflag >= 2)
f01013f4:	83 f9 01             	cmp    $0x1,%ecx
f01013f7:	7e 10                	jle    f0101409 <vprintfmt+0x29f>
		return va_arg(*ap, long long);
f01013f9:	8b 45 14             	mov    0x14(%ebp),%eax
f01013fc:	8d 50 08             	lea    0x8(%eax),%edx
f01013ff:	89 55 14             	mov    %edx,0x14(%ebp)
f0101402:	8b 30                	mov    (%eax),%esi
f0101404:	8b 78 04             	mov    0x4(%eax),%edi
f0101407:	eb 26                	jmp    f010142f <vprintfmt+0x2c5>
	else if (lflag)
f0101409:	85 c9                	test   %ecx,%ecx
f010140b:	74 12                	je     f010141f <vprintfmt+0x2b5>
		return va_arg(*ap, long);
f010140d:	8b 45 14             	mov    0x14(%ebp),%eax
f0101410:	8d 50 04             	lea    0x4(%eax),%edx
f0101413:	89 55 14             	mov    %edx,0x14(%ebp)
f0101416:	8b 30                	mov    (%eax),%esi
f0101418:	89 f7                	mov    %esi,%edi
f010141a:	c1 ff 1f             	sar    $0x1f,%edi
f010141d:	eb 10                	jmp    f010142f <vprintfmt+0x2c5>
	else
		return va_arg(*ap, int);
f010141f:	8b 45 14             	mov    0x14(%ebp),%eax
f0101422:	8d 50 04             	lea    0x4(%eax),%edx
f0101425:	89 55 14             	mov    %edx,0x14(%ebp)
f0101428:	8b 30                	mov    (%eax),%esi
f010142a:	89 f7                	mov    %esi,%edi
f010142c:	c1 ff 1f             	sar    $0x1f,%edi
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
				putch('-', putdat);
				num = -(long long) num;
			}
			base = 10;
f010142f:	b8 0a 00 00 00       	mov    $0xa,%eax
			break;

		// (signed) decimal
		case 'd':
			num = getint(&ap, lflag);
			if ((long long) num < 0) {
f0101434:	85 ff                	test   %edi,%edi
f0101436:	0f 89 8c 00 00 00    	jns    f01014c8 <vprintfmt+0x35e>
				putch('-', putdat);
f010143c:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101440:	c7 04 24 2d 00 00 00 	movl   $0x2d,(%esp)
f0101447:	ff 55 08             	call   *0x8(%ebp)
				num = -(long long) num;
f010144a:	f7 de                	neg    %esi
f010144c:	83 d7 00             	adc    $0x0,%edi
f010144f:	f7 df                	neg    %edi
			}
			base = 10;
f0101451:	b8 0a 00 00 00       	mov    $0xa,%eax
f0101456:	eb 70                	jmp    f01014c8 <vprintfmt+0x35e>
			goto number;

		// unsigned decimal
		case 'u':
			num = getuint(&ap, lflag);
f0101458:	89 ca                	mov    %ecx,%edx
f010145a:	8d 45 14             	lea    0x14(%ebp),%eax
f010145d:	e8 89 fc ff ff       	call   f01010eb <getuint>
f0101462:	89 c6                	mov    %eax,%esi
f0101464:	89 d7                	mov    %edx,%edi
			base = 10;
f0101466:	b8 0a 00 00 00       	mov    $0xa,%eax
			goto number;
f010146b:	eb 5b                	jmp    f01014c8 <vprintfmt+0x35e>
			// Replace this with your code.
			//putch('0', putdat);
			//putch('X', putdat);
			//putch('X', putdat);
			//break;
			num = getuint(&ap, lflag);
f010146d:	89 ca                	mov    %ecx,%edx
f010146f:	8d 45 14             	lea    0x14(%ebp),%eax
f0101472:	e8 74 fc ff ff       	call   f01010eb <getuint>
f0101477:	89 c6                	mov    %eax,%esi
f0101479:	89 d7                	mov    %edx,%edi
			base = 8;
f010147b:	b8 08 00 00 00       	mov    $0x8,%eax
			goto number;
f0101480:	eb 46                	jmp    f01014c8 <vprintfmt+0x35e>
		// pointer
		case 'p':
			putch('0', putdat);
f0101482:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101486:	c7 04 24 30 00 00 00 	movl   $0x30,(%esp)
f010148d:	ff 55 08             	call   *0x8(%ebp)
			putch('x', putdat);
f0101490:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f0101494:	c7 04 24 78 00 00 00 	movl   $0x78,(%esp)
f010149b:	ff 55 08             	call   *0x8(%ebp)
			num = (unsigned long long)
				(uintptr_t) va_arg(ap, void *);
f010149e:	8b 45 14             	mov    0x14(%ebp),%eax
f01014a1:	8d 50 04             	lea    0x4(%eax),%edx
f01014a4:	89 55 14             	mov    %edx,0x14(%ebp)
			goto number;
		// pointer
		case 'p':
			putch('0', putdat);
			putch('x', putdat);
			num = (unsigned long long)
f01014a7:	8b 30                	mov    (%eax),%esi
f01014a9:	bf 00 00 00 00       	mov    $0x0,%edi
				(uintptr_t) va_arg(ap, void *);
			base = 16;
f01014ae:	b8 10 00 00 00       	mov    $0x10,%eax
			goto number;
f01014b3:	eb 13                	jmp    f01014c8 <vprintfmt+0x35e>

		// (unsigned) hexadecimal
		case 'x':
			num = getuint(&ap, lflag);
f01014b5:	89 ca                	mov    %ecx,%edx
f01014b7:	8d 45 14             	lea    0x14(%ebp),%eax
f01014ba:	e8 2c fc ff ff       	call   f01010eb <getuint>
f01014bf:	89 c6                	mov    %eax,%esi
f01014c1:	89 d7                	mov    %edx,%edi
			base = 16;
f01014c3:	b8 10 00 00 00       	mov    $0x10,%eax
		number:
			printnum(putch, putdat, num, base, width, padc);
f01014c8:	0f be 55 d8          	movsbl -0x28(%ebp),%edx
f01014cc:	89 54 24 10          	mov    %edx,0x10(%esp)
f01014d0:	8b 55 e4             	mov    -0x1c(%ebp),%edx
f01014d3:	89 54 24 0c          	mov    %edx,0xc(%esp)
f01014d7:	89 44 24 08          	mov    %eax,0x8(%esp)
f01014db:	89 34 24             	mov    %esi,(%esp)
f01014de:	89 7c 24 04          	mov    %edi,0x4(%esp)
f01014e2:	89 da                	mov    %ebx,%edx
f01014e4:	8b 45 08             	mov    0x8(%ebp),%eax
f01014e7:	e8 24 fb ff ff       	call   f0101010 <printnum>
			break;
f01014ec:	8b 75 e0             	mov    -0x20(%ebp),%esi
f01014ef:	e9 99 fc ff ff       	jmp    f010118d <vprintfmt+0x23>

		// escaped '%' character
		case '%':
			putch(ch, putdat);
f01014f4:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f01014f8:	89 14 24             	mov    %edx,(%esp)
f01014fb:	ff 55 08             	call   *0x8(%ebp)
		width = -1;
		precision = -1;
		lflag = 0;
		altflag = 0;
	reswitch:
		switch (ch = *(unsigned char *) fmt++) {
f01014fe:	8b 75 e0             	mov    -0x20(%ebp),%esi
			break;

		// escaped '%' character
		case '%':
			putch(ch, putdat);
			break;
f0101501:	e9 87 fc ff ff       	jmp    f010118d <vprintfmt+0x23>

		// unrecognized escape sequence - just print it literally
		default:
			putch('%', putdat);
f0101506:	89 5c 24 04          	mov    %ebx,0x4(%esp)
f010150a:	c7 04 24 25 00 00 00 	movl   $0x25,(%esp)
f0101511:	ff 55 08             	call   *0x8(%ebp)
			for (fmt--; fmt[-1] != '%'; fmt--)
f0101514:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
f0101518:	0f 84 6f fc ff ff    	je     f010118d <vprintfmt+0x23>
f010151e:	83 ee 01             	sub    $0x1,%esi
f0101521:	80 7e ff 25          	cmpb   $0x25,-0x1(%esi)
f0101525:	75 f7                	jne    f010151e <vprintfmt+0x3b4>
f0101527:	e9 61 fc ff ff       	jmp    f010118d <vprintfmt+0x23>
				/* do nothing */;
			break;
		}
	}
}
f010152c:	83 c4 4c             	add    $0x4c,%esp
f010152f:	5b                   	pop    %ebx
f0101530:	5e                   	pop    %esi
f0101531:	5f                   	pop    %edi
f0101532:	5d                   	pop    %ebp
f0101533:	c3                   	ret    

f0101534 <vsnprintf>:
		*b->buf++ = ch;
}

int
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
f0101534:	55                   	push   %ebp
f0101535:	89 e5                	mov    %esp,%ebp
f0101537:	83 ec 28             	sub    $0x28,%esp
f010153a:	8b 45 08             	mov    0x8(%ebp),%eax
f010153d:	8b 55 0c             	mov    0xc(%ebp),%edx
	struct sprintbuf b = {buf, buf+n-1, 0};
f0101540:	89 45 ec             	mov    %eax,-0x14(%ebp)
f0101543:	8d 4c 10 ff          	lea    -0x1(%eax,%edx,1),%ecx
f0101547:	89 4d f0             	mov    %ecx,-0x10(%ebp)
f010154a:	c7 45 f4 00 00 00 00 	movl   $0x0,-0xc(%ebp)

	if (buf == NULL || n < 1)
f0101551:	85 c0                	test   %eax,%eax
f0101553:	74 30                	je     f0101585 <vsnprintf+0x51>
f0101555:	85 d2                	test   %edx,%edx
f0101557:	7e 2c                	jle    f0101585 <vsnprintf+0x51>
		return -E_INVAL;

	// print the string to the buffer
	vprintfmt((void*)sprintputch, &b, fmt, ap);
f0101559:	8b 45 14             	mov    0x14(%ebp),%eax
f010155c:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101560:	8b 45 10             	mov    0x10(%ebp),%eax
f0101563:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101567:	8d 45 ec             	lea    -0x14(%ebp),%eax
f010156a:	89 44 24 04          	mov    %eax,0x4(%esp)
f010156e:	c7 04 24 25 11 10 f0 	movl   $0xf0101125,(%esp)
f0101575:	e8 f0 fb ff ff       	call   f010116a <vprintfmt>

	// null terminate the buffer
	*b.buf = '\0';
f010157a:	8b 45 ec             	mov    -0x14(%ebp),%eax
f010157d:	c6 00 00             	movb   $0x0,(%eax)

	return b.cnt;
f0101580:	8b 45 f4             	mov    -0xc(%ebp),%eax
f0101583:	eb 05                	jmp    f010158a <vsnprintf+0x56>
vsnprintf(char *buf, int n, const char *fmt, va_list ap)
{
	struct sprintbuf b = {buf, buf+n-1, 0};

	if (buf == NULL || n < 1)
		return -E_INVAL;
f0101585:	b8 fd ff ff ff       	mov    $0xfffffffd,%eax

	// null terminate the buffer
	*b.buf = '\0';

	return b.cnt;
}
f010158a:	c9                   	leave  
f010158b:	c3                   	ret    

f010158c <snprintf>:

int
snprintf(char *buf, int n, const char *fmt, ...)
{
f010158c:	55                   	push   %ebp
f010158d:	89 e5                	mov    %esp,%ebp
f010158f:	83 ec 18             	sub    $0x18,%esp
	va_list ap;
	int rc;

	va_start(ap, fmt);
f0101592:	8d 45 14             	lea    0x14(%ebp),%eax
	rc = vsnprintf(buf, n, fmt, ap);
f0101595:	89 44 24 0c          	mov    %eax,0xc(%esp)
f0101599:	8b 45 10             	mov    0x10(%ebp),%eax
f010159c:	89 44 24 08          	mov    %eax,0x8(%esp)
f01015a0:	8b 45 0c             	mov    0xc(%ebp),%eax
f01015a3:	89 44 24 04          	mov    %eax,0x4(%esp)
f01015a7:	8b 45 08             	mov    0x8(%ebp),%eax
f01015aa:	89 04 24             	mov    %eax,(%esp)
f01015ad:	e8 82 ff ff ff       	call   f0101534 <vsnprintf>
	va_end(ap);

	return rc;
}
f01015b2:	c9                   	leave  
f01015b3:	c3                   	ret    
	...

f01015c0 <readline>:
#define BUFLEN 1024
static char buf[BUFLEN];

char *
readline(const char *prompt)
{
f01015c0:	55                   	push   %ebp
f01015c1:	89 e5                	mov    %esp,%ebp
f01015c3:	57                   	push   %edi
f01015c4:	56                   	push   %esi
f01015c5:	53                   	push   %ebx
f01015c6:	83 ec 1c             	sub    $0x1c,%esp
f01015c9:	8b 45 08             	mov    0x8(%ebp),%eax
	int i, c, echoing;

	if (prompt != NULL)
f01015cc:	85 c0                	test   %eax,%eax
f01015ce:	74 10                	je     f01015e0 <readline+0x20>
		cprintf("%s", prompt);
f01015d0:	89 44 24 04          	mov    %eax,0x4(%esp)
f01015d4:	c7 04 24 ba 20 10 f0 	movl   $0xf01020ba,(%esp)
f01015db:	e8 d6 f6 ff ff       	call   f0100cb6 <cprintf>

	i = 0;
	echoing = iscons(0);
f01015e0:	c7 04 24 00 00 00 00 	movl   $0x0,(%esp)
f01015e7:	e8 7e f0 ff ff       	call   f010066a <iscons>
f01015ec:	89 c7                	mov    %eax,%edi
	int i, c, echoing;

	if (prompt != NULL)
		cprintf("%s", prompt);

	i = 0;
f01015ee:	be 00 00 00 00       	mov    $0x0,%esi
	echoing = iscons(0);
	while (1) {
		c = getchar();
f01015f3:	e8 61 f0 ff ff       	call   f0100659 <getchar>
f01015f8:	89 c3                	mov    %eax,%ebx
		if (c < 0) {
f01015fa:	85 c0                	test   %eax,%eax
f01015fc:	79 17                	jns    f0101615 <readline+0x55>
			cprintf("read error: %e\n", c);
f01015fe:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101602:	c7 04 24 94 25 10 f0 	movl   $0xf0102594,(%esp)
f0101609:	e8 a8 f6 ff ff       	call   f0100cb6 <cprintf>
			return NULL;
f010160e:	b8 00 00 00 00       	mov    $0x0,%eax
f0101613:	eb 6d                	jmp    f0101682 <readline+0xc2>
		} else if ((c == '\b' || c == '\x7f') && i > 0) {
f0101615:	83 f8 08             	cmp    $0x8,%eax
f0101618:	74 05                	je     f010161f <readline+0x5f>
f010161a:	83 f8 7f             	cmp    $0x7f,%eax
f010161d:	75 19                	jne    f0101638 <readline+0x78>
f010161f:	85 f6                	test   %esi,%esi
f0101621:	7e 15                	jle    f0101638 <readline+0x78>
			if (echoing)
f0101623:	85 ff                	test   %edi,%edi
f0101625:	74 0c                	je     f0101633 <readline+0x73>
				cputchar('\b');
f0101627:	c7 04 24 08 00 00 00 	movl   $0x8,(%esp)
f010162e:	e8 16 f0 ff ff       	call   f0100649 <cputchar>
			i--;
f0101633:	83 ee 01             	sub    $0x1,%esi
f0101636:	eb bb                	jmp    f01015f3 <readline+0x33>
		} else if (c >= ' ' && i < BUFLEN-1) {
f0101638:	83 fb 1f             	cmp    $0x1f,%ebx
f010163b:	7e 1f                	jle    f010165c <readline+0x9c>
f010163d:	81 fe fe 03 00 00    	cmp    $0x3fe,%esi
f0101643:	7f 17                	jg     f010165c <readline+0x9c>
			if (echoing)
f0101645:	85 ff                	test   %edi,%edi
f0101647:	74 08                	je     f0101651 <readline+0x91>
				cputchar(c);
f0101649:	89 1c 24             	mov    %ebx,(%esp)
f010164c:	e8 f8 ef ff ff       	call   f0100649 <cputchar>
			buf[i++] = c;
f0101651:	88 9e 60 35 11 f0    	mov    %bl,-0xfeecaa0(%esi)
f0101657:	83 c6 01             	add    $0x1,%esi
f010165a:	eb 97                	jmp    f01015f3 <readline+0x33>
		} else if (c == '\n' || c == '\r') {
f010165c:	83 fb 0a             	cmp    $0xa,%ebx
f010165f:	74 05                	je     f0101666 <readline+0xa6>
f0101661:	83 fb 0d             	cmp    $0xd,%ebx
f0101664:	75 8d                	jne    f01015f3 <readline+0x33>
			if (echoing)
f0101666:	85 ff                	test   %edi,%edi
f0101668:	74 0c                	je     f0101676 <readline+0xb6>
				cputchar('\n');
f010166a:	c7 04 24 0a 00 00 00 	movl   $0xa,(%esp)
f0101671:	e8 d3 ef ff ff       	call   f0100649 <cputchar>
			buf[i] = 0;
f0101676:	c6 86 60 35 11 f0 00 	movb   $0x0,-0xfeecaa0(%esi)
			return buf;
f010167d:	b8 60 35 11 f0       	mov    $0xf0113560,%eax
		}
	}
}
f0101682:	83 c4 1c             	add    $0x1c,%esp
f0101685:	5b                   	pop    %ebx
f0101686:	5e                   	pop    %esi
f0101687:	5f                   	pop    %edi
f0101688:	5d                   	pop    %ebp
f0101689:	c3                   	ret    
f010168a:	00 00                	add    %al,(%eax)
f010168c:	00 00                	add    %al,(%eax)
	...

f0101690 <strlen>:
// Primespipe runs 3x faster this way.
#define ASM 1

int
strlen(const char *s)
{
f0101690:	55                   	push   %ebp
f0101691:	89 e5                	mov    %esp,%ebp
f0101693:	8b 55 08             	mov    0x8(%ebp),%edx
	int n;

	for (n = 0; *s != '\0'; s++)
f0101696:	b8 00 00 00 00       	mov    $0x0,%eax
f010169b:	80 3a 00             	cmpb   $0x0,(%edx)
f010169e:	74 09                	je     f01016a9 <strlen+0x19>
		n++;
f01016a0:	83 c0 01             	add    $0x1,%eax
int
strlen(const char *s)
{
	int n;

	for (n = 0; *s != '\0'; s++)
f01016a3:	80 3c 02 00          	cmpb   $0x0,(%edx,%eax,1)
f01016a7:	75 f7                	jne    f01016a0 <strlen+0x10>
		n++;
	return n;
}
f01016a9:	5d                   	pop    %ebp
f01016aa:	c3                   	ret    

f01016ab <strnlen>:

int
strnlen(const char *s, size_t size)
{
f01016ab:	55                   	push   %ebp
f01016ac:	89 e5                	mov    %esp,%ebp
f01016ae:	53                   	push   %ebx
f01016af:	8b 5d 08             	mov    0x8(%ebp),%ebx
f01016b2:	8b 4d 0c             	mov    0xc(%ebp),%ecx
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01016b5:	b8 00 00 00 00       	mov    $0x0,%eax
f01016ba:	85 c9                	test   %ecx,%ecx
f01016bc:	74 1a                	je     f01016d8 <strnlen+0x2d>
f01016be:	80 3b 00             	cmpb   $0x0,(%ebx)
f01016c1:	74 15                	je     f01016d8 <strnlen+0x2d>
f01016c3:	ba 01 00 00 00       	mov    $0x1,%edx
		n++;
f01016c8:	89 d0                	mov    %edx,%eax
int
strnlen(const char *s, size_t size)
{
	int n;

	for (n = 0; size > 0 && *s != '\0'; s++, size--)
f01016ca:	39 ca                	cmp    %ecx,%edx
f01016cc:	74 0a                	je     f01016d8 <strnlen+0x2d>
f01016ce:	83 c2 01             	add    $0x1,%edx
f01016d1:	80 7c 13 ff 00       	cmpb   $0x0,-0x1(%ebx,%edx,1)
f01016d6:	75 f0                	jne    f01016c8 <strnlen+0x1d>
		n++;
	return n;
}
f01016d8:	5b                   	pop    %ebx
f01016d9:	5d                   	pop    %ebp
f01016da:	c3                   	ret    

f01016db <strcpy>:

char *
strcpy(char *dst, const char *src)
{
f01016db:	55                   	push   %ebp
f01016dc:	89 e5                	mov    %esp,%ebp
f01016de:	53                   	push   %ebx
f01016df:	8b 45 08             	mov    0x8(%ebp),%eax
f01016e2:	8b 5d 0c             	mov    0xc(%ebp),%ebx
	char *ret;

	ret = dst;
	while ((*dst++ = *src++) != '\0')
f01016e5:	ba 00 00 00 00       	mov    $0x0,%edx
f01016ea:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f01016ee:	88 0c 10             	mov    %cl,(%eax,%edx,1)
f01016f1:	83 c2 01             	add    $0x1,%edx
f01016f4:	84 c9                	test   %cl,%cl
f01016f6:	75 f2                	jne    f01016ea <strcpy+0xf>
		/* do nothing */;
	return ret;
}
f01016f8:	5b                   	pop    %ebx
f01016f9:	5d                   	pop    %ebp
f01016fa:	c3                   	ret    

f01016fb <strcat>:

char *
strcat(char *dst, const char *src)
{
f01016fb:	55                   	push   %ebp
f01016fc:	89 e5                	mov    %esp,%ebp
f01016fe:	53                   	push   %ebx
f01016ff:	83 ec 08             	sub    $0x8,%esp
f0101702:	8b 5d 08             	mov    0x8(%ebp),%ebx
	int len = strlen(dst);
f0101705:	89 1c 24             	mov    %ebx,(%esp)
f0101708:	e8 83 ff ff ff       	call   f0101690 <strlen>
	strcpy(dst + len, src);
f010170d:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101710:	89 54 24 04          	mov    %edx,0x4(%esp)
f0101714:	01 d8                	add    %ebx,%eax
f0101716:	89 04 24             	mov    %eax,(%esp)
f0101719:	e8 bd ff ff ff       	call   f01016db <strcpy>
	return dst;
}
f010171e:	89 d8                	mov    %ebx,%eax
f0101720:	83 c4 08             	add    $0x8,%esp
f0101723:	5b                   	pop    %ebx
f0101724:	5d                   	pop    %ebp
f0101725:	c3                   	ret    

f0101726 <strncpy>:

char *
strncpy(char *dst, const char *src, size_t size) {
f0101726:	55                   	push   %ebp
f0101727:	89 e5                	mov    %esp,%ebp
f0101729:	56                   	push   %esi
f010172a:	53                   	push   %ebx
f010172b:	8b 45 08             	mov    0x8(%ebp),%eax
f010172e:	8b 55 0c             	mov    0xc(%ebp),%edx
f0101731:	8b 75 10             	mov    0x10(%ebp),%esi
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101734:	85 f6                	test   %esi,%esi
f0101736:	74 18                	je     f0101750 <strncpy+0x2a>
f0101738:	b9 00 00 00 00       	mov    $0x0,%ecx
		*dst++ = *src;
f010173d:	0f b6 1a             	movzbl (%edx),%ebx
f0101740:	88 1c 08             	mov    %bl,(%eax,%ecx,1)
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
f0101743:	80 3a 01             	cmpb   $0x1,(%edx)
f0101746:	83 da ff             	sbb    $0xffffffff,%edx
strncpy(char *dst, const char *src, size_t size) {
	size_t i;
	char *ret;

	ret = dst;
	for (i = 0; i < size; i++) {
f0101749:	83 c1 01             	add    $0x1,%ecx
f010174c:	39 f1                	cmp    %esi,%ecx
f010174e:	75 ed                	jne    f010173d <strncpy+0x17>
		// If strlen(src) < size, null-pad 'dst' out to 'size' chars
		if (*src != '\0')
			src++;
	}
	return ret;
}
f0101750:	5b                   	pop    %ebx
f0101751:	5e                   	pop    %esi
f0101752:	5d                   	pop    %ebp
f0101753:	c3                   	ret    

f0101754 <strlcpy>:

size_t
strlcpy(char *dst, const char *src, size_t size)
{
f0101754:	55                   	push   %ebp
f0101755:	89 e5                	mov    %esp,%ebp
f0101757:	57                   	push   %edi
f0101758:	56                   	push   %esi
f0101759:	53                   	push   %ebx
f010175a:	8b 7d 08             	mov    0x8(%ebp),%edi
f010175d:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101760:	8b 75 10             	mov    0x10(%ebp),%esi
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
f0101763:	89 f8                	mov    %edi,%eax
f0101765:	85 f6                	test   %esi,%esi
f0101767:	74 2b                	je     f0101794 <strlcpy+0x40>
		while (--size > 0 && *src != '\0')
f0101769:	83 fe 01             	cmp    $0x1,%esi
f010176c:	74 23                	je     f0101791 <strlcpy+0x3d>
f010176e:	0f b6 0b             	movzbl (%ebx),%ecx
f0101771:	84 c9                	test   %cl,%cl
f0101773:	74 1c                	je     f0101791 <strlcpy+0x3d>
	}
	return ret;
}

size_t
strlcpy(char *dst, const char *src, size_t size)
f0101775:	83 ee 02             	sub    $0x2,%esi
f0101778:	ba 00 00 00 00       	mov    $0x0,%edx
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
			*dst++ = *src++;
f010177d:	88 08                	mov    %cl,(%eax)
f010177f:	83 c0 01             	add    $0x1,%eax
{
	char *dst_in;

	dst_in = dst;
	if (size > 0) {
		while (--size > 0 && *src != '\0')
f0101782:	39 f2                	cmp    %esi,%edx
f0101784:	74 0b                	je     f0101791 <strlcpy+0x3d>
f0101786:	83 c2 01             	add    $0x1,%edx
f0101789:	0f b6 0c 13          	movzbl (%ebx,%edx,1),%ecx
f010178d:	84 c9                	test   %cl,%cl
f010178f:	75 ec                	jne    f010177d <strlcpy+0x29>
			*dst++ = *src++;
		*dst = '\0';
f0101791:	c6 00 00             	movb   $0x0,(%eax)
	}
	return dst - dst_in;
f0101794:	29 f8                	sub    %edi,%eax
}
f0101796:	5b                   	pop    %ebx
f0101797:	5e                   	pop    %esi
f0101798:	5f                   	pop    %edi
f0101799:	5d                   	pop    %ebp
f010179a:	c3                   	ret    

f010179b <strcmp>:

int
strcmp(const char *p, const char *q)
{
f010179b:	55                   	push   %ebp
f010179c:	89 e5                	mov    %esp,%ebp
f010179e:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01017a1:	8b 55 0c             	mov    0xc(%ebp),%edx
	while (*p && *p == *q)
f01017a4:	0f b6 01             	movzbl (%ecx),%eax
f01017a7:	84 c0                	test   %al,%al
f01017a9:	74 16                	je     f01017c1 <strcmp+0x26>
f01017ab:	3a 02                	cmp    (%edx),%al
f01017ad:	75 12                	jne    f01017c1 <strcmp+0x26>
		p++, q++;
f01017af:	83 c2 01             	add    $0x1,%edx
}

int
strcmp(const char *p, const char *q)
{
	while (*p && *p == *q)
f01017b2:	0f b6 41 01          	movzbl 0x1(%ecx),%eax
f01017b6:	84 c0                	test   %al,%al
f01017b8:	74 07                	je     f01017c1 <strcmp+0x26>
f01017ba:	83 c1 01             	add    $0x1,%ecx
f01017bd:	3a 02                	cmp    (%edx),%al
f01017bf:	74 ee                	je     f01017af <strcmp+0x14>
		p++, q++;
	return (int) ((unsigned char) *p - (unsigned char) *q);
f01017c1:	0f b6 c0             	movzbl %al,%eax
f01017c4:	0f b6 12             	movzbl (%edx),%edx
f01017c7:	29 d0                	sub    %edx,%eax
}
f01017c9:	5d                   	pop    %ebp
f01017ca:	c3                   	ret    

f01017cb <strncmp>:

int
strncmp(const char *p, const char *q, size_t n)
{
f01017cb:	55                   	push   %ebp
f01017cc:	89 e5                	mov    %esp,%ebp
f01017ce:	53                   	push   %ebx
f01017cf:	8b 4d 08             	mov    0x8(%ebp),%ecx
f01017d2:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f01017d5:	8b 55 10             	mov    0x10(%ebp),%edx
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
f01017d8:	b8 00 00 00 00       	mov    $0x0,%eax
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01017dd:	85 d2                	test   %edx,%edx
f01017df:	74 28                	je     f0101809 <strncmp+0x3e>
f01017e1:	0f b6 01             	movzbl (%ecx),%eax
f01017e4:	84 c0                	test   %al,%al
f01017e6:	74 24                	je     f010180c <strncmp+0x41>
f01017e8:	3a 03                	cmp    (%ebx),%al
f01017ea:	75 20                	jne    f010180c <strncmp+0x41>
f01017ec:	83 ea 01             	sub    $0x1,%edx
f01017ef:	74 13                	je     f0101804 <strncmp+0x39>
		n--, p++, q++;
f01017f1:	83 c1 01             	add    $0x1,%ecx
f01017f4:	83 c3 01             	add    $0x1,%ebx
}

int
strncmp(const char *p, const char *q, size_t n)
{
	while (n > 0 && *p && *p == *q)
f01017f7:	0f b6 01             	movzbl (%ecx),%eax
f01017fa:	84 c0                	test   %al,%al
f01017fc:	74 0e                	je     f010180c <strncmp+0x41>
f01017fe:	3a 03                	cmp    (%ebx),%al
f0101800:	74 ea                	je     f01017ec <strncmp+0x21>
f0101802:	eb 08                	jmp    f010180c <strncmp+0x41>
		n--, p++, q++;
	if (n == 0)
		return 0;
f0101804:	b8 00 00 00 00       	mov    $0x0,%eax
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
}
f0101809:	5b                   	pop    %ebx
f010180a:	5d                   	pop    %ebp
f010180b:	c3                   	ret    
	while (n > 0 && *p && *p == *q)
		n--, p++, q++;
	if (n == 0)
		return 0;
	else
		return (int) ((unsigned char) *p - (unsigned char) *q);
f010180c:	0f b6 01             	movzbl (%ecx),%eax
f010180f:	0f b6 13             	movzbl (%ebx),%edx
f0101812:	29 d0                	sub    %edx,%eax
f0101814:	eb f3                	jmp    f0101809 <strncmp+0x3e>

f0101816 <strchr>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
f0101816:	55                   	push   %ebp
f0101817:	89 e5                	mov    %esp,%ebp
f0101819:	8b 45 08             	mov    0x8(%ebp),%eax
f010181c:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101820:	0f b6 10             	movzbl (%eax),%edx
f0101823:	84 d2                	test   %dl,%dl
f0101825:	74 1c                	je     f0101843 <strchr+0x2d>
		if (*s == c)
f0101827:	38 ca                	cmp    %cl,%dl
f0101829:	75 09                	jne    f0101834 <strchr+0x1e>
f010182b:	eb 1b                	jmp    f0101848 <strchr+0x32>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f010182d:	83 c0 01             	add    $0x1,%eax
		if (*s == c)
f0101830:	38 ca                	cmp    %cl,%dl
f0101832:	74 14                	je     f0101848 <strchr+0x32>
// Return a pointer to the first occurrence of 'c' in 's',
// or a null pointer if the string has no 'c'.
char *
strchr(const char *s, char c)
{
	for (; *s; s++)
f0101834:	0f b6 50 01          	movzbl 0x1(%eax),%edx
f0101838:	84 d2                	test   %dl,%dl
f010183a:	75 f1                	jne    f010182d <strchr+0x17>
		if (*s == c)
			return (char *) s;
	return 0;
f010183c:	b8 00 00 00 00       	mov    $0x0,%eax
f0101841:	eb 05                	jmp    f0101848 <strchr+0x32>
f0101843:	b8 00 00 00 00       	mov    $0x0,%eax
}
f0101848:	5d                   	pop    %ebp
f0101849:	c3                   	ret    

f010184a <strfind>:

// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
f010184a:	55                   	push   %ebp
f010184b:	89 e5                	mov    %esp,%ebp
f010184d:	8b 45 08             	mov    0x8(%ebp),%eax
f0101850:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
	for (; *s; s++)
f0101854:	0f b6 10             	movzbl (%eax),%edx
f0101857:	84 d2                	test   %dl,%dl
f0101859:	74 14                	je     f010186f <strfind+0x25>
		if (*s == c)
f010185b:	38 ca                	cmp    %cl,%dl
f010185d:	75 06                	jne    f0101865 <strfind+0x1b>
f010185f:	eb 0e                	jmp    f010186f <strfind+0x25>
f0101861:	38 ca                	cmp    %cl,%dl
f0101863:	74 0a                	je     f010186f <strfind+0x25>
// Return a pointer to the first occurrence of 'c' in 's',
// or a pointer to the string-ending null character if the string has no 'c'.
char *
strfind(const char *s, char c)
{
	for (; *s; s++)
f0101865:	83 c0 01             	add    $0x1,%eax
f0101868:	0f b6 10             	movzbl (%eax),%edx
f010186b:	84 d2                	test   %dl,%dl
f010186d:	75 f2                	jne    f0101861 <strfind+0x17>
		if (*s == c)
			break;
	return (char *) s;
}
f010186f:	5d                   	pop    %ebp
f0101870:	c3                   	ret    

f0101871 <memset>:

#if ASM
void *
memset(void *v, int c, size_t n)
{
f0101871:	55                   	push   %ebp
f0101872:	89 e5                	mov    %esp,%ebp
f0101874:	83 ec 0c             	sub    $0xc,%esp
f0101877:	89 5d f4             	mov    %ebx,-0xc(%ebp)
f010187a:	89 75 f8             	mov    %esi,-0x8(%ebp)
f010187d:	89 7d fc             	mov    %edi,-0x4(%ebp)
f0101880:	8b 7d 08             	mov    0x8(%ebp),%edi
f0101883:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101886:	8b 4d 10             	mov    0x10(%ebp),%ecx
	char *p;

	if (n == 0)
f0101889:	85 c9                	test   %ecx,%ecx
f010188b:	74 30                	je     f01018bd <memset+0x4c>
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
f010188d:	f7 c7 03 00 00 00    	test   $0x3,%edi
f0101893:	75 25                	jne    f01018ba <memset+0x49>
f0101895:	f6 c1 03             	test   $0x3,%cl
f0101898:	75 20                	jne    f01018ba <memset+0x49>
		c &= 0xFF;
f010189a:	0f b6 d0             	movzbl %al,%edx
		c = (c<<24)|(c<<16)|(c<<8)|c;
f010189d:	89 d3                	mov    %edx,%ebx
f010189f:	c1 e3 08             	shl    $0x8,%ebx
f01018a2:	89 d6                	mov    %edx,%esi
f01018a4:	c1 e6 18             	shl    $0x18,%esi
f01018a7:	89 d0                	mov    %edx,%eax
f01018a9:	c1 e0 10             	shl    $0x10,%eax
f01018ac:	09 f0                	or     %esi,%eax
f01018ae:	09 d0                	or     %edx,%eax
f01018b0:	09 d8                	or     %ebx,%eax
		asm volatile("cld; rep stosl\n"
			:: "D" (v), "a" (c), "c" (n/4)
f01018b2:	c1 e9 02             	shr    $0x2,%ecx
	if (n == 0)
		return v;
	if ((int)v%4 == 0 && n%4 == 0) {
		c &= 0xFF;
		c = (c<<24)|(c<<16)|(c<<8)|c;
		asm volatile("cld; rep stosl\n"
f01018b5:	fc                   	cld    
f01018b6:	f3 ab                	rep stos %eax,%es:(%edi)
f01018b8:	eb 03                	jmp    f01018bd <memset+0x4c>
			:: "D" (v), "a" (c), "c" (n/4)
			: "cc", "memory");
	} else
		asm volatile("cld; rep stosb\n"
f01018ba:	fc                   	cld    
f01018bb:	f3 aa                	rep stos %al,%es:(%edi)
			:: "D" (v), "a" (c), "c" (n)
			: "cc", "memory");
	return v;
}
f01018bd:	89 f8                	mov    %edi,%eax
f01018bf:	8b 5d f4             	mov    -0xc(%ebp),%ebx
f01018c2:	8b 75 f8             	mov    -0x8(%ebp),%esi
f01018c5:	8b 7d fc             	mov    -0x4(%ebp),%edi
f01018c8:	89 ec                	mov    %ebp,%esp
f01018ca:	5d                   	pop    %ebp
f01018cb:	c3                   	ret    

f01018cc <memmove>:

void *
memmove(void *dst, const void *src, size_t n)
{
f01018cc:	55                   	push   %ebp
f01018cd:	89 e5                	mov    %esp,%ebp
f01018cf:	83 ec 08             	sub    $0x8,%esp
f01018d2:	89 75 f8             	mov    %esi,-0x8(%ebp)
f01018d5:	89 7d fc             	mov    %edi,-0x4(%ebp)
f01018d8:	8b 45 08             	mov    0x8(%ebp),%eax
f01018db:	8b 75 0c             	mov    0xc(%ebp),%esi
f01018de:	8b 4d 10             	mov    0x10(%ebp),%ecx
	const char *s;
	char *d;

	s = src;
	d = dst;
	if (s < d && s + n > d) {
f01018e1:	39 c6                	cmp    %eax,%esi
f01018e3:	73 36                	jae    f010191b <memmove+0x4f>
f01018e5:	8d 14 0e             	lea    (%esi,%ecx,1),%edx
f01018e8:	39 d0                	cmp    %edx,%eax
f01018ea:	73 2f                	jae    f010191b <memmove+0x4f>
		s += n;
		d += n;
f01018ec:	8d 3c 08             	lea    (%eax,%ecx,1),%edi
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f01018ef:	f6 c2 03             	test   $0x3,%dl
f01018f2:	75 1b                	jne    f010190f <memmove+0x43>
f01018f4:	f7 c7 03 00 00 00    	test   $0x3,%edi
f01018fa:	75 13                	jne    f010190f <memmove+0x43>
f01018fc:	f6 c1 03             	test   $0x3,%cl
f01018ff:	75 0e                	jne    f010190f <memmove+0x43>
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
f0101901:	83 ef 04             	sub    $0x4,%edi
f0101904:	8d 72 fc             	lea    -0x4(%edx),%esi
f0101907:	c1 e9 02             	shr    $0x2,%ecx
	d = dst;
	if (s < d && s + n > d) {
		s += n;
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
f010190a:	fd                   	std    
f010190b:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f010190d:	eb 09                	jmp    f0101918 <memmove+0x4c>
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
f010190f:	83 ef 01             	sub    $0x1,%edi
f0101912:	8d 72 ff             	lea    -0x1(%edx),%esi
		d += n;
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("std; rep movsl\n"
				:: "D" (d-4), "S" (s-4), "c" (n/4) : "cc", "memory");
		else
			asm volatile("std; rep movsb\n"
f0101915:	fd                   	std    
f0101916:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
f0101918:	fc                   	cld    
f0101919:	eb 20                	jmp    f010193b <memmove+0x6f>
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
f010191b:	f7 c6 03 00 00 00    	test   $0x3,%esi
f0101921:	75 13                	jne    f0101936 <memmove+0x6a>
f0101923:	a8 03                	test   $0x3,%al
f0101925:	75 0f                	jne    f0101936 <memmove+0x6a>
f0101927:	f6 c1 03             	test   $0x3,%cl
f010192a:	75 0a                	jne    f0101936 <memmove+0x6a>
			asm volatile("cld; rep movsl\n"
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
f010192c:	c1 e9 02             	shr    $0x2,%ecx
				:: "D" (d-1), "S" (s-1), "c" (n) : "cc", "memory");
		// Some versions of GCC rely on DF being clear
		asm volatile("cld" ::: "cc");
	} else {
		if ((int)s%4 == 0 && (int)d%4 == 0 && n%4 == 0)
			asm volatile("cld; rep movsl\n"
f010192f:	89 c7                	mov    %eax,%edi
f0101931:	fc                   	cld    
f0101932:	f3 a5                	rep movsl %ds:(%esi),%es:(%edi)
f0101934:	eb 05                	jmp    f010193b <memmove+0x6f>
				:: "D" (d), "S" (s), "c" (n/4) : "cc", "memory");
		else
			asm volatile("cld; rep movsb\n"
f0101936:	89 c7                	mov    %eax,%edi
f0101938:	fc                   	cld    
f0101939:	f3 a4                	rep movsb %ds:(%esi),%es:(%edi)
				:: "D" (d), "S" (s), "c" (n) : "cc", "memory");
	}
	return dst;
}
f010193b:	8b 75 f8             	mov    -0x8(%ebp),%esi
f010193e:	8b 7d fc             	mov    -0x4(%ebp),%edi
f0101941:	89 ec                	mov    %ebp,%esp
f0101943:	5d                   	pop    %ebp
f0101944:	c3                   	ret    

f0101945 <memcpy>:
}
#endif

void *
memcpy(void *dst, const void *src, size_t n)
{
f0101945:	55                   	push   %ebp
f0101946:	89 e5                	mov    %esp,%ebp
f0101948:	83 ec 0c             	sub    $0xc,%esp
	return memmove(dst, src, n);
f010194b:	8b 45 10             	mov    0x10(%ebp),%eax
f010194e:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101952:	8b 45 0c             	mov    0xc(%ebp),%eax
f0101955:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101959:	8b 45 08             	mov    0x8(%ebp),%eax
f010195c:	89 04 24             	mov    %eax,(%esp)
f010195f:	e8 68 ff ff ff       	call   f01018cc <memmove>
}
f0101964:	c9                   	leave  
f0101965:	c3                   	ret    

f0101966 <memcmp>:

int
memcmp(const void *v1, const void *v2, size_t n)
{
f0101966:	55                   	push   %ebp
f0101967:	89 e5                	mov    %esp,%ebp
f0101969:	57                   	push   %edi
f010196a:	56                   	push   %esi
f010196b:	53                   	push   %ebx
f010196c:	8b 5d 08             	mov    0x8(%ebp),%ebx
f010196f:	8b 75 0c             	mov    0xc(%ebp),%esi
f0101972:	8b 7d 10             	mov    0x10(%ebp),%edi
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f0101975:	b8 00 00 00 00       	mov    $0x0,%eax
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f010197a:	85 ff                	test   %edi,%edi
f010197c:	74 37                	je     f01019b5 <memcmp+0x4f>
		if (*s1 != *s2)
f010197e:	0f b6 03             	movzbl (%ebx),%eax
f0101981:	0f b6 0e             	movzbl (%esi),%ecx
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f0101984:	83 ef 01             	sub    $0x1,%edi
f0101987:	ba 00 00 00 00       	mov    $0x0,%edx
		if (*s1 != *s2)
f010198c:	38 c8                	cmp    %cl,%al
f010198e:	74 1c                	je     f01019ac <memcmp+0x46>
f0101990:	eb 10                	jmp    f01019a2 <memcmp+0x3c>
f0101992:	0f b6 44 13 01       	movzbl 0x1(%ebx,%edx,1),%eax
f0101997:	83 c2 01             	add    $0x1,%edx
f010199a:	0f b6 0c 16          	movzbl (%esi,%edx,1),%ecx
f010199e:	38 c8                	cmp    %cl,%al
f01019a0:	74 0a                	je     f01019ac <memcmp+0x46>
			return (int) *s1 - (int) *s2;
f01019a2:	0f b6 c0             	movzbl %al,%eax
f01019a5:	0f b6 c9             	movzbl %cl,%ecx
f01019a8:	29 c8                	sub    %ecx,%eax
f01019aa:	eb 09                	jmp    f01019b5 <memcmp+0x4f>
memcmp(const void *v1, const void *v2, size_t n)
{
	const uint8_t *s1 = (const uint8_t *) v1;
	const uint8_t *s2 = (const uint8_t *) v2;

	while (n-- > 0) {
f01019ac:	39 fa                	cmp    %edi,%edx
f01019ae:	75 e2                	jne    f0101992 <memcmp+0x2c>
		if (*s1 != *s2)
			return (int) *s1 - (int) *s2;
		s1++, s2++;
	}

	return 0;
f01019b0:	b8 00 00 00 00       	mov    $0x0,%eax
}
f01019b5:	5b                   	pop    %ebx
f01019b6:	5e                   	pop    %esi
f01019b7:	5f                   	pop    %edi
f01019b8:	5d                   	pop    %ebp
f01019b9:	c3                   	ret    

f01019ba <memfind>:

void *
memfind(const void *s, int c, size_t n)
{
f01019ba:	55                   	push   %ebp
f01019bb:	89 e5                	mov    %esp,%ebp
f01019bd:	8b 45 08             	mov    0x8(%ebp),%eax
	const void *ends = (const char *) s + n;
f01019c0:	89 c2                	mov    %eax,%edx
f01019c2:	03 55 10             	add    0x10(%ebp),%edx
	for (; s < ends; s++)
f01019c5:	39 d0                	cmp    %edx,%eax
f01019c7:	73 19                	jae    f01019e2 <memfind+0x28>
		if (*(const unsigned char *) s == (unsigned char) c)
f01019c9:	0f b6 4d 0c          	movzbl 0xc(%ebp),%ecx
f01019cd:	38 08                	cmp    %cl,(%eax)
f01019cf:	75 06                	jne    f01019d7 <memfind+0x1d>
f01019d1:	eb 0f                	jmp    f01019e2 <memfind+0x28>
f01019d3:	38 08                	cmp    %cl,(%eax)
f01019d5:	74 0b                	je     f01019e2 <memfind+0x28>

void *
memfind(const void *s, int c, size_t n)
{
	const void *ends = (const char *) s + n;
	for (; s < ends; s++)
f01019d7:	83 c0 01             	add    $0x1,%eax
f01019da:	39 d0                	cmp    %edx,%eax
f01019dc:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f01019e0:	75 f1                	jne    f01019d3 <memfind+0x19>
		if (*(const unsigned char *) s == (unsigned char) c)
			break;
	return (void *) s;
}
f01019e2:	5d                   	pop    %ebp
f01019e3:	c3                   	ret    

f01019e4 <strtol>:

long
strtol(const char *s, char **endptr, int base)
{
f01019e4:	55                   	push   %ebp
f01019e5:	89 e5                	mov    %esp,%ebp
f01019e7:	57                   	push   %edi
f01019e8:	56                   	push   %esi
f01019e9:	53                   	push   %ebx
f01019ea:	8b 55 08             	mov    0x8(%ebp),%edx
f01019ed:	8b 5d 10             	mov    0x10(%ebp),%ebx
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01019f0:	0f b6 02             	movzbl (%edx),%eax
f01019f3:	3c 20                	cmp    $0x20,%al
f01019f5:	74 04                	je     f01019fb <strtol+0x17>
f01019f7:	3c 09                	cmp    $0x9,%al
f01019f9:	75 0e                	jne    f0101a09 <strtol+0x25>
		s++;
f01019fb:	83 c2 01             	add    $0x1,%edx
{
	int neg = 0;
	long val = 0;

	// gobble initial whitespace
	while (*s == ' ' || *s == '\t')
f01019fe:	0f b6 02             	movzbl (%edx),%eax
f0101a01:	3c 20                	cmp    $0x20,%al
f0101a03:	74 f6                	je     f01019fb <strtol+0x17>
f0101a05:	3c 09                	cmp    $0x9,%al
f0101a07:	74 f2                	je     f01019fb <strtol+0x17>
		s++;

	// plus/minus sign
	if (*s == '+')
f0101a09:	3c 2b                	cmp    $0x2b,%al
f0101a0b:	75 0a                	jne    f0101a17 <strtol+0x33>
		s++;
f0101a0d:	83 c2 01             	add    $0x1,%edx
}

long
strtol(const char *s, char **endptr, int base)
{
	int neg = 0;
f0101a10:	bf 00 00 00 00       	mov    $0x0,%edi
f0101a15:	eb 10                	jmp    f0101a27 <strtol+0x43>
f0101a17:	bf 00 00 00 00       	mov    $0x0,%edi
		s++;

	// plus/minus sign
	if (*s == '+')
		s++;
	else if (*s == '-')
f0101a1c:	3c 2d                	cmp    $0x2d,%al
f0101a1e:	75 07                	jne    f0101a27 <strtol+0x43>
		s++, neg = 1;
f0101a20:	83 c2 01             	add    $0x1,%edx
f0101a23:	66 bf 01 00          	mov    $0x1,%di

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
f0101a27:	85 db                	test   %ebx,%ebx
f0101a29:	0f 94 c0             	sete   %al
f0101a2c:	74 05                	je     f0101a33 <strtol+0x4f>
f0101a2e:	83 fb 10             	cmp    $0x10,%ebx
f0101a31:	75 15                	jne    f0101a48 <strtol+0x64>
f0101a33:	80 3a 30             	cmpb   $0x30,(%edx)
f0101a36:	75 10                	jne    f0101a48 <strtol+0x64>
f0101a38:	80 7a 01 78          	cmpb   $0x78,0x1(%edx)
f0101a3c:	75 0a                	jne    f0101a48 <strtol+0x64>
		s += 2, base = 16;
f0101a3e:	83 c2 02             	add    $0x2,%edx
f0101a41:	bb 10 00 00 00       	mov    $0x10,%ebx
f0101a46:	eb 13                	jmp    f0101a5b <strtol+0x77>
	else if (base == 0 && s[0] == '0')
f0101a48:	84 c0                	test   %al,%al
f0101a4a:	74 0f                	je     f0101a5b <strtol+0x77>
		s++, base = 8;
	else if (base == 0)
		base = 10;
f0101a4c:	bb 0a 00 00 00       	mov    $0xa,%ebx
		s++, neg = 1;

	// hex or octal base prefix
	if ((base == 0 || base == 16) && (s[0] == '0' && s[1] == 'x'))
		s += 2, base = 16;
	else if (base == 0 && s[0] == '0')
f0101a51:	80 3a 30             	cmpb   $0x30,(%edx)
f0101a54:	75 05                	jne    f0101a5b <strtol+0x77>
		s++, base = 8;
f0101a56:	83 c2 01             	add    $0x1,%edx
f0101a59:	b3 08                	mov    $0x8,%bl
	else if (base == 0)
		base = 10;
f0101a5b:	b8 00 00 00 00       	mov    $0x0,%eax
f0101a60:	89 de                	mov    %ebx,%esi

	// digits
	while (1) {
		int dig;

		if (*s >= '0' && *s <= '9')
f0101a62:	0f b6 0a             	movzbl (%edx),%ecx
f0101a65:	8d 59 d0             	lea    -0x30(%ecx),%ebx
f0101a68:	80 fb 09             	cmp    $0x9,%bl
f0101a6b:	77 08                	ja     f0101a75 <strtol+0x91>
			dig = *s - '0';
f0101a6d:	0f be c9             	movsbl %cl,%ecx
f0101a70:	83 e9 30             	sub    $0x30,%ecx
f0101a73:	eb 1e                	jmp    f0101a93 <strtol+0xaf>
		else if (*s >= 'a' && *s <= 'z')
f0101a75:	8d 59 9f             	lea    -0x61(%ecx),%ebx
f0101a78:	80 fb 19             	cmp    $0x19,%bl
f0101a7b:	77 08                	ja     f0101a85 <strtol+0xa1>
			dig = *s - 'a' + 10;
f0101a7d:	0f be c9             	movsbl %cl,%ecx
f0101a80:	83 e9 57             	sub    $0x57,%ecx
f0101a83:	eb 0e                	jmp    f0101a93 <strtol+0xaf>
		else if (*s >= 'A' && *s <= 'Z')
f0101a85:	8d 59 bf             	lea    -0x41(%ecx),%ebx
f0101a88:	80 fb 19             	cmp    $0x19,%bl
f0101a8b:	77 14                	ja     f0101aa1 <strtol+0xbd>
			dig = *s - 'A' + 10;
f0101a8d:	0f be c9             	movsbl %cl,%ecx
f0101a90:	83 e9 37             	sub    $0x37,%ecx
		else
			break;
		if (dig >= base)
f0101a93:	39 f1                	cmp    %esi,%ecx
f0101a95:	7d 0e                	jge    f0101aa5 <strtol+0xc1>
			break;
		s++, val = (val * base) + dig;
f0101a97:	83 c2 01             	add    $0x1,%edx
f0101a9a:	0f af c6             	imul   %esi,%eax
f0101a9d:	01 c8                	add    %ecx,%eax
		// we don't properly detect overflow!
	}
f0101a9f:	eb c1                	jmp    f0101a62 <strtol+0x7e>

		if (*s >= '0' && *s <= '9')
			dig = *s - '0';
		else if (*s >= 'a' && *s <= 'z')
			dig = *s - 'a' + 10;
		else if (*s >= 'A' && *s <= 'Z')
f0101aa1:	89 c1                	mov    %eax,%ecx
f0101aa3:	eb 02                	jmp    f0101aa7 <strtol+0xc3>
			dig = *s - 'A' + 10;
		else
			break;
		if (dig >= base)
f0101aa5:	89 c1                	mov    %eax,%ecx
			break;
		s++, val = (val * base) + dig;
		// we don't properly detect overflow!
	}

	if (endptr)
f0101aa7:	83 7d 0c 00          	cmpl   $0x0,0xc(%ebp)
f0101aab:	74 05                	je     f0101ab2 <strtol+0xce>
		*endptr = (char *) s;
f0101aad:	8b 5d 0c             	mov    0xc(%ebp),%ebx
f0101ab0:	89 13                	mov    %edx,(%ebx)
	return (neg ? -val : val);
f0101ab2:	89 ca                	mov    %ecx,%edx
f0101ab4:	f7 da                	neg    %edx
f0101ab6:	85 ff                	test   %edi,%edi
f0101ab8:	0f 45 c2             	cmovne %edx,%eax
}
f0101abb:	5b                   	pop    %ebx
f0101abc:	5e                   	pop    %esi
f0101abd:	5f                   	pop    %edi
f0101abe:	5d                   	pop    %ebp
f0101abf:	c3                   	ret    

f0101ac0 <__udivdi3>:
f0101ac0:	83 ec 1c             	sub    $0x1c,%esp
f0101ac3:	89 7c 24 14          	mov    %edi,0x14(%esp)
f0101ac7:	8b 7c 24 2c          	mov    0x2c(%esp),%edi
f0101acb:	8b 44 24 20          	mov    0x20(%esp),%eax
f0101acf:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0101ad3:	89 74 24 10          	mov    %esi,0x10(%esp)
f0101ad7:	8b 74 24 24          	mov    0x24(%esp),%esi
f0101adb:	85 ff                	test   %edi,%edi
f0101add:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f0101ae1:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101ae5:	89 cd                	mov    %ecx,%ebp
f0101ae7:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101aeb:	75 33                	jne    f0101b20 <__udivdi3+0x60>
f0101aed:	39 f1                	cmp    %esi,%ecx
f0101aef:	77 57                	ja     f0101b48 <__udivdi3+0x88>
f0101af1:	85 c9                	test   %ecx,%ecx
f0101af3:	75 0b                	jne    f0101b00 <__udivdi3+0x40>
f0101af5:	b8 01 00 00 00       	mov    $0x1,%eax
f0101afa:	31 d2                	xor    %edx,%edx
f0101afc:	f7 f1                	div    %ecx
f0101afe:	89 c1                	mov    %eax,%ecx
f0101b00:	89 f0                	mov    %esi,%eax
f0101b02:	31 d2                	xor    %edx,%edx
f0101b04:	f7 f1                	div    %ecx
f0101b06:	89 c6                	mov    %eax,%esi
f0101b08:	8b 44 24 04          	mov    0x4(%esp),%eax
f0101b0c:	f7 f1                	div    %ecx
f0101b0e:	89 f2                	mov    %esi,%edx
f0101b10:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101b14:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101b18:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101b1c:	83 c4 1c             	add    $0x1c,%esp
f0101b1f:	c3                   	ret    
f0101b20:	31 d2                	xor    %edx,%edx
f0101b22:	31 c0                	xor    %eax,%eax
f0101b24:	39 f7                	cmp    %esi,%edi
f0101b26:	77 e8                	ja     f0101b10 <__udivdi3+0x50>
f0101b28:	0f bd cf             	bsr    %edi,%ecx
f0101b2b:	83 f1 1f             	xor    $0x1f,%ecx
f0101b2e:	89 4c 24 04          	mov    %ecx,0x4(%esp)
f0101b32:	75 2c                	jne    f0101b60 <__udivdi3+0xa0>
f0101b34:	3b 6c 24 08          	cmp    0x8(%esp),%ebp
f0101b38:	76 04                	jbe    f0101b3e <__udivdi3+0x7e>
f0101b3a:	39 f7                	cmp    %esi,%edi
f0101b3c:	73 d2                	jae    f0101b10 <__udivdi3+0x50>
f0101b3e:	31 d2                	xor    %edx,%edx
f0101b40:	b8 01 00 00 00       	mov    $0x1,%eax
f0101b45:	eb c9                	jmp    f0101b10 <__udivdi3+0x50>
f0101b47:	90                   	nop
f0101b48:	89 f2                	mov    %esi,%edx
f0101b4a:	f7 f1                	div    %ecx
f0101b4c:	31 d2                	xor    %edx,%edx
f0101b4e:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101b52:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101b56:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101b5a:	83 c4 1c             	add    $0x1c,%esp
f0101b5d:	c3                   	ret    
f0101b5e:	66 90                	xchg   %ax,%ax
f0101b60:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101b65:	b8 20 00 00 00       	mov    $0x20,%eax
f0101b6a:	89 ea                	mov    %ebp,%edx
f0101b6c:	2b 44 24 04          	sub    0x4(%esp),%eax
f0101b70:	d3 e7                	shl    %cl,%edi
f0101b72:	89 c1                	mov    %eax,%ecx
f0101b74:	d3 ea                	shr    %cl,%edx
f0101b76:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101b7b:	09 fa                	or     %edi,%edx
f0101b7d:	89 f7                	mov    %esi,%edi
f0101b7f:	89 54 24 0c          	mov    %edx,0xc(%esp)
f0101b83:	89 f2                	mov    %esi,%edx
f0101b85:	8b 74 24 08          	mov    0x8(%esp),%esi
f0101b89:	d3 e5                	shl    %cl,%ebp
f0101b8b:	89 c1                	mov    %eax,%ecx
f0101b8d:	d3 ef                	shr    %cl,%edi
f0101b8f:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101b94:	d3 e2                	shl    %cl,%edx
f0101b96:	89 c1                	mov    %eax,%ecx
f0101b98:	d3 ee                	shr    %cl,%esi
f0101b9a:	09 d6                	or     %edx,%esi
f0101b9c:	89 fa                	mov    %edi,%edx
f0101b9e:	89 f0                	mov    %esi,%eax
f0101ba0:	f7 74 24 0c          	divl   0xc(%esp)
f0101ba4:	89 d7                	mov    %edx,%edi
f0101ba6:	89 c6                	mov    %eax,%esi
f0101ba8:	f7 e5                	mul    %ebp
f0101baa:	39 d7                	cmp    %edx,%edi
f0101bac:	72 22                	jb     f0101bd0 <__udivdi3+0x110>
f0101bae:	8b 6c 24 08          	mov    0x8(%esp),%ebp
f0101bb2:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101bb7:	d3 e5                	shl    %cl,%ebp
f0101bb9:	39 c5                	cmp    %eax,%ebp
f0101bbb:	73 04                	jae    f0101bc1 <__udivdi3+0x101>
f0101bbd:	39 d7                	cmp    %edx,%edi
f0101bbf:	74 0f                	je     f0101bd0 <__udivdi3+0x110>
f0101bc1:	89 f0                	mov    %esi,%eax
f0101bc3:	31 d2                	xor    %edx,%edx
f0101bc5:	e9 46 ff ff ff       	jmp    f0101b10 <__udivdi3+0x50>
f0101bca:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101bd0:	8d 46 ff             	lea    -0x1(%esi),%eax
f0101bd3:	31 d2                	xor    %edx,%edx
f0101bd5:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101bd9:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101bdd:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101be1:	83 c4 1c             	add    $0x1c,%esp
f0101be4:	c3                   	ret    
	...

f0101bf0 <__umoddi3>:
f0101bf0:	83 ec 1c             	sub    $0x1c,%esp
f0101bf3:	89 6c 24 18          	mov    %ebp,0x18(%esp)
f0101bf7:	8b 6c 24 2c          	mov    0x2c(%esp),%ebp
f0101bfb:	8b 44 24 20          	mov    0x20(%esp),%eax
f0101bff:	89 74 24 10          	mov    %esi,0x10(%esp)
f0101c03:	8b 4c 24 28          	mov    0x28(%esp),%ecx
f0101c07:	8b 74 24 24          	mov    0x24(%esp),%esi
f0101c0b:	85 ed                	test   %ebp,%ebp
f0101c0d:	89 7c 24 14          	mov    %edi,0x14(%esp)
f0101c11:	89 44 24 08          	mov    %eax,0x8(%esp)
f0101c15:	89 cf                	mov    %ecx,%edi
f0101c17:	89 04 24             	mov    %eax,(%esp)
f0101c1a:	89 f2                	mov    %esi,%edx
f0101c1c:	75 1a                	jne    f0101c38 <__umoddi3+0x48>
f0101c1e:	39 f1                	cmp    %esi,%ecx
f0101c20:	76 4e                	jbe    f0101c70 <__umoddi3+0x80>
f0101c22:	f7 f1                	div    %ecx
f0101c24:	89 d0                	mov    %edx,%eax
f0101c26:	31 d2                	xor    %edx,%edx
f0101c28:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101c2c:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101c30:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101c34:	83 c4 1c             	add    $0x1c,%esp
f0101c37:	c3                   	ret    
f0101c38:	39 f5                	cmp    %esi,%ebp
f0101c3a:	77 54                	ja     f0101c90 <__umoddi3+0xa0>
f0101c3c:	0f bd c5             	bsr    %ebp,%eax
f0101c3f:	83 f0 1f             	xor    $0x1f,%eax
f0101c42:	89 44 24 04          	mov    %eax,0x4(%esp)
f0101c46:	75 60                	jne    f0101ca8 <__umoddi3+0xb8>
f0101c48:	3b 0c 24             	cmp    (%esp),%ecx
f0101c4b:	0f 87 07 01 00 00    	ja     f0101d58 <__umoddi3+0x168>
f0101c51:	89 f2                	mov    %esi,%edx
f0101c53:	8b 34 24             	mov    (%esp),%esi
f0101c56:	29 ce                	sub    %ecx,%esi
f0101c58:	19 ea                	sbb    %ebp,%edx
f0101c5a:	89 34 24             	mov    %esi,(%esp)
f0101c5d:	8b 04 24             	mov    (%esp),%eax
f0101c60:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101c64:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101c68:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101c6c:	83 c4 1c             	add    $0x1c,%esp
f0101c6f:	c3                   	ret    
f0101c70:	85 c9                	test   %ecx,%ecx
f0101c72:	75 0b                	jne    f0101c7f <__umoddi3+0x8f>
f0101c74:	b8 01 00 00 00       	mov    $0x1,%eax
f0101c79:	31 d2                	xor    %edx,%edx
f0101c7b:	f7 f1                	div    %ecx
f0101c7d:	89 c1                	mov    %eax,%ecx
f0101c7f:	89 f0                	mov    %esi,%eax
f0101c81:	31 d2                	xor    %edx,%edx
f0101c83:	f7 f1                	div    %ecx
f0101c85:	8b 04 24             	mov    (%esp),%eax
f0101c88:	f7 f1                	div    %ecx
f0101c8a:	eb 98                	jmp    f0101c24 <__umoddi3+0x34>
f0101c8c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101c90:	89 f2                	mov    %esi,%edx
f0101c92:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101c96:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101c9a:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101c9e:	83 c4 1c             	add    $0x1c,%esp
f0101ca1:	c3                   	ret    
f0101ca2:	8d b6 00 00 00 00    	lea    0x0(%esi),%esi
f0101ca8:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101cad:	89 e8                	mov    %ebp,%eax
f0101caf:	bd 20 00 00 00       	mov    $0x20,%ebp
f0101cb4:	2b 6c 24 04          	sub    0x4(%esp),%ebp
f0101cb8:	89 fa                	mov    %edi,%edx
f0101cba:	d3 e0                	shl    %cl,%eax
f0101cbc:	89 e9                	mov    %ebp,%ecx
f0101cbe:	d3 ea                	shr    %cl,%edx
f0101cc0:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101cc5:	09 c2                	or     %eax,%edx
f0101cc7:	8b 44 24 08          	mov    0x8(%esp),%eax
f0101ccb:	89 14 24             	mov    %edx,(%esp)
f0101cce:	89 f2                	mov    %esi,%edx
f0101cd0:	d3 e7                	shl    %cl,%edi
f0101cd2:	89 e9                	mov    %ebp,%ecx
f0101cd4:	d3 ea                	shr    %cl,%edx
f0101cd6:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101cdb:	89 7c 24 0c          	mov    %edi,0xc(%esp)
f0101cdf:	d3 e6                	shl    %cl,%esi
f0101ce1:	89 e9                	mov    %ebp,%ecx
f0101ce3:	d3 e8                	shr    %cl,%eax
f0101ce5:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101cea:	09 f0                	or     %esi,%eax
f0101cec:	8b 74 24 08          	mov    0x8(%esp),%esi
f0101cf0:	f7 34 24             	divl   (%esp)
f0101cf3:	d3 e6                	shl    %cl,%esi
f0101cf5:	89 74 24 08          	mov    %esi,0x8(%esp)
f0101cf9:	89 d6                	mov    %edx,%esi
f0101cfb:	f7 e7                	mul    %edi
f0101cfd:	39 d6                	cmp    %edx,%esi
f0101cff:	89 c1                	mov    %eax,%ecx
f0101d01:	89 d7                	mov    %edx,%edi
f0101d03:	72 3f                	jb     f0101d44 <__umoddi3+0x154>
f0101d05:	39 44 24 08          	cmp    %eax,0x8(%esp)
f0101d09:	72 35                	jb     f0101d40 <__umoddi3+0x150>
f0101d0b:	8b 44 24 08          	mov    0x8(%esp),%eax
f0101d0f:	29 c8                	sub    %ecx,%eax
f0101d11:	19 fe                	sbb    %edi,%esi
f0101d13:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101d18:	89 f2                	mov    %esi,%edx
f0101d1a:	d3 e8                	shr    %cl,%eax
f0101d1c:	89 e9                	mov    %ebp,%ecx
f0101d1e:	d3 e2                	shl    %cl,%edx
f0101d20:	0f b6 4c 24 04       	movzbl 0x4(%esp),%ecx
f0101d25:	09 d0                	or     %edx,%eax
f0101d27:	89 f2                	mov    %esi,%edx
f0101d29:	d3 ea                	shr    %cl,%edx
f0101d2b:	8b 74 24 10          	mov    0x10(%esp),%esi
f0101d2f:	8b 7c 24 14          	mov    0x14(%esp),%edi
f0101d33:	8b 6c 24 18          	mov    0x18(%esp),%ebp
f0101d37:	83 c4 1c             	add    $0x1c,%esp
f0101d3a:	c3                   	ret    
f0101d3b:	90                   	nop
f0101d3c:	8d 74 26 00          	lea    0x0(%esi,%eiz,1),%esi
f0101d40:	39 d6                	cmp    %edx,%esi
f0101d42:	75 c7                	jne    f0101d0b <__umoddi3+0x11b>
f0101d44:	89 d7                	mov    %edx,%edi
f0101d46:	89 c1                	mov    %eax,%ecx
f0101d48:	2b 4c 24 0c          	sub    0xc(%esp),%ecx
f0101d4c:	1b 3c 24             	sbb    (%esp),%edi
f0101d4f:	eb ba                	jmp    f0101d0b <__umoddi3+0x11b>
f0101d51:	8d b4 26 00 00 00 00 	lea    0x0(%esi,%eiz,1),%esi
f0101d58:	39 f5                	cmp    %esi,%ebp
f0101d5a:	0f 82 f1 fe ff ff    	jb     f0101c51 <__umoddi3+0x61>
f0101d60:	e9 f8 fe ff ff       	jmp    f0101c5d <__umoddi3+0x6d>
