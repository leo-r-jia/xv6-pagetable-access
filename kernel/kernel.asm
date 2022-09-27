
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	8a013103          	ld	sp,-1888(sp) # 800088a0 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	fee70713          	addi	a4,a4,-18 # 80009040 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	c8c78793          	addi	a5,a5,-884 # 80005cf0 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	de078793          	addi	a5,a5,-544 # 80000e8e <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	41e080e7          	jalr	1054(ra) # 8000254a <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	78e080e7          	jalr	1934(ra) # 800008ca <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7119                	addi	sp,sp,-128
    80000166:	fc86                	sd	ra,120(sp)
    80000168:	f8a2                	sd	s0,112(sp)
    8000016a:	f4a6                	sd	s1,104(sp)
    8000016c:	f0ca                	sd	s2,96(sp)
    8000016e:	ecce                	sd	s3,88(sp)
    80000170:	e8d2                	sd	s4,80(sp)
    80000172:	e4d6                	sd	s5,72(sp)
    80000174:	e0da                	sd	s6,64(sp)
    80000176:	fc5e                	sd	s7,56(sp)
    80000178:	f862                	sd	s8,48(sp)
    8000017a:	f466                	sd	s9,40(sp)
    8000017c:	f06a                	sd	s10,32(sp)
    8000017e:	ec6e                	sd	s11,24(sp)
    80000180:	0100                	addi	s0,sp,128
    80000182:	8b2a                	mv	s6,a0
    80000184:	8aae                	mv	s5,a1
    80000186:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000188:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000018c:	00011517          	auipc	a0,0x11
    80000190:	ff450513          	addi	a0,a0,-12 # 80011180 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	a50080e7          	jalr	-1456(ra) # 80000be4 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	fe448493          	addi	s1,s1,-28 # 80011180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	07290913          	addi	s2,s2,114 # 80011218 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001ae:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b0:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b2:	4da9                	li	s11,10
  while(n > 0){
    800001b4:	07405863          	blez	s4,80000224 <consoleread+0xc0>
    while(cons.r == cons.w){
    800001b8:	0984a783          	lw	a5,152(s1)
    800001bc:	09c4a703          	lw	a4,156(s1)
    800001c0:	02f71463          	bne	a4,a5,800001e8 <consoleread+0x84>
      if(myproc()->killed){
    800001c4:	00002097          	auipc	ra,0x2
    800001c8:	8d0080e7          	jalr	-1840(ra) # 80001a94 <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	f7c080e7          	jalr	-132(ra) # 80002150 <sleep>
    while(cons.r == cons.w){
    800001dc:	0984a783          	lw	a5,152(s1)
    800001e0:	09c4a703          	lw	a4,156(s1)
    800001e4:	fef700e3          	beq	a4,a5,800001c4 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001e8:	0017871b          	addiw	a4,a5,1
    800001ec:	08e4ac23          	sw	a4,152(s1)
    800001f0:	07f7f713          	andi	a4,a5,127
    800001f4:	9726                	add	a4,a4,s1
    800001f6:	01874703          	lbu	a4,24(a4)
    800001fa:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    800001fe:	079c0663          	beq	s8,s9,8000026a <consoleread+0x106>
    cbuf = c;
    80000202:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000206:	4685                	li	a3,1
    80000208:	f8f40613          	addi	a2,s0,-113
    8000020c:	85d6                	mv	a1,s5
    8000020e:	855a                	mv	a0,s6
    80000210:	00002097          	auipc	ra,0x2
    80000214:	2e4080e7          	jalr	740(ra) # 800024f4 <either_copyout>
    80000218:	01a50663          	beq	a0,s10,80000224 <consoleread+0xc0>
    dst++;
    8000021c:	0a85                	addi	s5,s5,1
    --n;
    8000021e:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000220:	f9bc1ae3          	bne	s8,s11,800001b4 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000224:	00011517          	auipc	a0,0x11
    80000228:	f5c50513          	addi	a0,a0,-164 # 80011180 <cons>
    8000022c:	00001097          	auipc	ra,0x1
    80000230:	a6c080e7          	jalr	-1428(ra) # 80000c98 <release>

  return target - n;
    80000234:	414b853b          	subw	a0,s7,s4
    80000238:	a811                	j	8000024c <consoleread+0xe8>
        release(&cons.lock);
    8000023a:	00011517          	auipc	a0,0x11
    8000023e:	f4650513          	addi	a0,a0,-186 # 80011180 <cons>
    80000242:	00001097          	auipc	ra,0x1
    80000246:	a56080e7          	jalr	-1450(ra) # 80000c98 <release>
        return -1;
    8000024a:	557d                	li	a0,-1
}
    8000024c:	70e6                	ld	ra,120(sp)
    8000024e:	7446                	ld	s0,112(sp)
    80000250:	74a6                	ld	s1,104(sp)
    80000252:	7906                	ld	s2,96(sp)
    80000254:	69e6                	ld	s3,88(sp)
    80000256:	6a46                	ld	s4,80(sp)
    80000258:	6aa6                	ld	s5,72(sp)
    8000025a:	6b06                	ld	s6,64(sp)
    8000025c:	7be2                	ld	s7,56(sp)
    8000025e:	7c42                	ld	s8,48(sp)
    80000260:	7ca2                	ld	s9,40(sp)
    80000262:	7d02                	ld	s10,32(sp)
    80000264:	6de2                	ld	s11,24(sp)
    80000266:	6109                	addi	sp,sp,128
    80000268:	8082                	ret
      if(n < target){
    8000026a:	000a071b          	sext.w	a4,s4
    8000026e:	fb777be3          	bgeu	a4,s7,80000224 <consoleread+0xc0>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	faf72323          	sw	a5,-90(a4) # 80011218 <cons+0x98>
    8000027a:	b76d                	j	80000224 <consoleread+0xc0>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	564080e7          	jalr	1380(ra) # 800007f0 <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	552080e7          	jalr	1362(ra) # 800007f0 <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	546080e7          	jalr	1350(ra) # 800007f0 <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	53c080e7          	jalr	1340(ra) # 800007f0 <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00011517          	auipc	a0,0x11
    800002d0:	eb450513          	addi	a0,a0,-332 # 80011180 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	910080e7          	jalr	-1776(ra) # 80000be4 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	2ae080e7          	jalr	686(ra) # 800025a0 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	e8650513          	addi	a0,a0,-378 # 80011180 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	996080e7          	jalr	-1642(ra) # 80000c98 <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000031e:	00011717          	auipc	a4,0x11
    80000322:	e6270713          	addi	a4,a4,-414 # 80011180 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000348:	00011797          	auipc	a5,0x11
    8000034c:	e3878793          	addi	a5,a5,-456 # 80011180 <cons>
    80000350:	0a07a703          	lw	a4,160(a5)
    80000354:	0017069b          	addiw	a3,a4,1
    80000358:	0006861b          	sext.w	a2,a3
    8000035c:	0ad7a023          	sw	a3,160(a5)
    80000360:	07f77713          	andi	a4,a4,127
    80000364:	97ba                	add	a5,a5,a4
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00011797          	auipc	a5,0x11
    8000037a:	ea27a783          	lw	a5,-350(a5) # 80011218 <cons+0x98>
    8000037e:	0807879b          	addiw	a5,a5,128
    80000382:	f6f61ce3          	bne	a2,a5,800002fa <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000386:	863e                	mv	a2,a5
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	df670713          	addi	a4,a4,-522 # 80011180 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	de648493          	addi	s1,s1,-538 # 80011180 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00011717          	auipc	a4,0x11
    800003da:	daa70713          	addi	a4,a4,-598 # 80011180 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	e2f72a23          	sw	a5,-460(a4) # 80011220 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000412:	00011797          	auipc	a5,0x11
    80000416:	d6e78793          	addi	a5,a5,-658 # 80011180 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00011797          	auipc	a5,0x11
    8000043a:	dec7a323          	sw	a2,-538(a5) # 8001121c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00011517          	auipc	a0,0x11
    80000442:	dda50513          	addi	a0,a0,-550 # 80011218 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	e96080e7          	jalr	-362(ra) # 800022dc <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00011517          	auipc	a0,0x11
    80000464:	d2050513          	addi	a0,a0,-736 # 80011180 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6ec080e7          	jalr	1772(ra) # 80000b54 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	330080e7          	jalr	816(ra) # 800007a0 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00021797          	auipc	a5,0x21
    8000047c:	ea078793          	addi	a5,a5,-352 # 80021318 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7870713          	addi	a4,a4,-904 # 80000102 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054663          	bltz	a0,80000536 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088b63          	beqz	a7,800004fc <printint+0x60>
    buf[i++] = '-';
    800004ea:	fe040793          	addi	a5,s0,-32
    800004ee:	973e                	add	a4,a4,a5
    800004f0:	02d00793          	li	a5,45
    800004f4:	fef70823          	sb	a5,-16(a4)
    800004f8:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fc:	02e05763          	blez	a4,8000052a <printint+0x8e>
    80000500:	fd040793          	addi	a5,s0,-48
    80000504:	00e784b3          	add	s1,a5,a4
    80000508:	fff78913          	addi	s2,a5,-1
    8000050c:	993a                	add	s2,s2,a4
    8000050e:	377d                	addiw	a4,a4,-1
    80000510:	1702                	slli	a4,a4,0x20
    80000512:	9301                	srli	a4,a4,0x20
    80000514:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000518:	fff4c503          	lbu	a0,-1(s1)
    8000051c:	00000097          	auipc	ra,0x0
    80000520:	d60080e7          	jalr	-672(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000524:	14fd                	addi	s1,s1,-1
    80000526:	ff2499e3          	bne	s1,s2,80000518 <printint+0x7c>
}
    8000052a:	70a2                	ld	ra,40(sp)
    8000052c:	7402                	ld	s0,32(sp)
    8000052e:	64e2                	ld	s1,24(sp)
    80000530:	6942                	ld	s2,16(sp)
    80000532:	6145                	addi	sp,sp,48
    80000534:	8082                	ret
    x = -xx;
    80000536:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053a:	4885                	li	a7,1
    x = -xx;
    8000053c:	bf9d                	j	800004b2 <printint+0x16>

000000008000053e <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053e:	1101                	addi	sp,sp,-32
    80000540:	ec06                	sd	ra,24(sp)
    80000542:	e822                	sd	s0,16(sp)
    80000544:	e426                	sd	s1,8(sp)
    80000546:	1000                	addi	s0,sp,32
    80000548:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054a:	00011797          	auipc	a5,0x11
    8000054e:	ce07ab23          	sw	zero,-778(a5) # 80011240 <pr+0x18>
  printf("panic: ");
    80000552:	00008517          	auipc	a0,0x8
    80000556:	ac650513          	addi	a0,a0,-1338 # 80008018 <etext+0x18>
    8000055a:	00000097          	auipc	ra,0x0
    8000055e:	02e080e7          	jalr	46(ra) # 80000588 <printf>
  printf(s);
    80000562:	8526                	mv	a0,s1
    80000564:	00000097          	auipc	ra,0x0
    80000568:	024080e7          	jalr	36(ra) # 80000588 <printf>
  printf("\n");
    8000056c:	00008517          	auipc	a0,0x8
    80000570:	b5c50513          	addi	a0,a0,-1188 # 800080c8 <digits+0x88>
    80000574:	00000097          	auipc	ra,0x0
    80000578:	014080e7          	jalr	20(ra) # 80000588 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057c:	4785                	li	a5,1
    8000057e:	00009717          	auipc	a4,0x9
    80000582:	a8f72123          	sw	a5,-1406(a4) # 80009000 <panicked>
  for(;;)
    80000586:	a001                	j	80000586 <panic+0x48>

0000000080000588 <printf>:
{
    80000588:	7131                	addi	sp,sp,-192
    8000058a:	fc86                	sd	ra,120(sp)
    8000058c:	f8a2                	sd	s0,112(sp)
    8000058e:	f4a6                	sd	s1,104(sp)
    80000590:	f0ca                	sd	s2,96(sp)
    80000592:	ecce                	sd	s3,88(sp)
    80000594:	e8d2                	sd	s4,80(sp)
    80000596:	e4d6                	sd	s5,72(sp)
    80000598:	e0da                	sd	s6,64(sp)
    8000059a:	fc5e                	sd	s7,56(sp)
    8000059c:	f862                	sd	s8,48(sp)
    8000059e:	f466                	sd	s9,40(sp)
    800005a0:	f06a                	sd	s10,32(sp)
    800005a2:	ec6e                	sd	s11,24(sp)
    800005a4:	0100                	addi	s0,sp,128
    800005a6:	8a2a                	mv	s4,a0
    800005a8:	e40c                	sd	a1,8(s0)
    800005aa:	e810                	sd	a2,16(s0)
    800005ac:	ec14                	sd	a3,24(s0)
    800005ae:	f018                	sd	a4,32(s0)
    800005b0:	f41c                	sd	a5,40(s0)
    800005b2:	03043823          	sd	a6,48(s0)
    800005b6:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ba:	00011d97          	auipc	s11,0x11
    800005be:	c86dad83          	lw	s11,-890(s11) # 80011240 <pr+0x18>
  if(locking)
    800005c2:	020d9b63          	bnez	s11,800005f8 <printf+0x70>
  if (fmt == 0)
    800005c6:	040a0263          	beqz	s4,8000060a <printf+0x82>
  va_start(ap, fmt);
    800005ca:	00840793          	addi	a5,s0,8
    800005ce:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d2:	000a4503          	lbu	a0,0(s4)
    800005d6:	16050263          	beqz	a0,8000073a <printf+0x1b2>
    800005da:	4481                	li	s1,0
    if(c != '%'){
    800005dc:	02500a93          	li	s5,37
    switch(c){
    800005e0:	07000b13          	li	s6,112
  consputc('x');
    800005e4:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e6:	00008b97          	auipc	s7,0x8
    800005ea:	a5ab8b93          	addi	s7,s7,-1446 # 80008040 <digits>
    switch(c){
    800005ee:	07300c93          	li	s9,115
    800005f2:	06400c13          	li	s8,100
    800005f6:	a82d                	j	80000630 <printf+0xa8>
    acquire(&pr.lock);
    800005f8:	00011517          	auipc	a0,0x11
    800005fc:	c3050513          	addi	a0,a0,-976 # 80011228 <pr>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	5e4080e7          	jalr	1508(ra) # 80000be4 <acquire>
    80000608:	bf7d                	j	800005c6 <printf+0x3e>
    panic("null fmt");
    8000060a:	00008517          	auipc	a0,0x8
    8000060e:	a1e50513          	addi	a0,a0,-1506 # 80008028 <etext+0x28>
    80000612:	00000097          	auipc	ra,0x0
    80000616:	f2c080e7          	jalr	-212(ra) # 8000053e <panic>
      consputc(c);
    8000061a:	00000097          	auipc	ra,0x0
    8000061e:	c62080e7          	jalr	-926(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000622:	2485                	addiw	s1,s1,1
    80000624:	009a07b3          	add	a5,s4,s1
    80000628:	0007c503          	lbu	a0,0(a5)
    8000062c:	10050763          	beqz	a0,8000073a <printf+0x1b2>
    if(c != '%'){
    80000630:	ff5515e3          	bne	a0,s5,8000061a <printf+0x92>
    c = fmt[++i] & 0xff;
    80000634:	2485                	addiw	s1,s1,1
    80000636:	009a07b3          	add	a5,s4,s1
    8000063a:	0007c783          	lbu	a5,0(a5)
    8000063e:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000642:	cfe5                	beqz	a5,8000073a <printf+0x1b2>
    switch(c){
    80000644:	05678a63          	beq	a5,s6,80000698 <printf+0x110>
    80000648:	02fb7663          	bgeu	s6,a5,80000674 <printf+0xec>
    8000064c:	09978963          	beq	a5,s9,800006de <printf+0x156>
    80000650:	07800713          	li	a4,120
    80000654:	0ce79863          	bne	a5,a4,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    80000658:	f8843783          	ld	a5,-120(s0)
    8000065c:	00878713          	addi	a4,a5,8
    80000660:	f8e43423          	sd	a4,-120(s0)
    80000664:	4605                	li	a2,1
    80000666:	85ea                	mv	a1,s10
    80000668:	4388                	lw	a0,0(a5)
    8000066a:	00000097          	auipc	ra,0x0
    8000066e:	e32080e7          	jalr	-462(ra) # 8000049c <printint>
      break;
    80000672:	bf45                	j	80000622 <printf+0x9a>
    switch(c){
    80000674:	0b578263          	beq	a5,s5,80000718 <printf+0x190>
    80000678:	0b879663          	bne	a5,s8,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    8000067c:	f8843783          	ld	a5,-120(s0)
    80000680:	00878713          	addi	a4,a5,8
    80000684:	f8e43423          	sd	a4,-120(s0)
    80000688:	4605                	li	a2,1
    8000068a:	45a9                	li	a1,10
    8000068c:	4388                	lw	a0,0(a5)
    8000068e:	00000097          	auipc	ra,0x0
    80000692:	e0e080e7          	jalr	-498(ra) # 8000049c <printint>
      break;
    80000696:	b771                	j	80000622 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000698:	f8843783          	ld	a5,-120(s0)
    8000069c:	00878713          	addi	a4,a5,8
    800006a0:	f8e43423          	sd	a4,-120(s0)
    800006a4:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006a8:	03000513          	li	a0,48
    800006ac:	00000097          	auipc	ra,0x0
    800006b0:	bd0080e7          	jalr	-1072(ra) # 8000027c <consputc>
  consputc('x');
    800006b4:	07800513          	li	a0,120
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bc4080e7          	jalr	-1084(ra) # 8000027c <consputc>
    800006c0:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c2:	03c9d793          	srli	a5,s3,0x3c
    800006c6:	97de                	add	a5,a5,s7
    800006c8:	0007c503          	lbu	a0,0(a5)
    800006cc:	00000097          	auipc	ra,0x0
    800006d0:	bb0080e7          	jalr	-1104(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d4:	0992                	slli	s3,s3,0x4
    800006d6:	397d                	addiw	s2,s2,-1
    800006d8:	fe0915e3          	bnez	s2,800006c2 <printf+0x13a>
    800006dc:	b799                	j	80000622 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	0007b903          	ld	s2,0(a5)
    800006ee:	00090e63          	beqz	s2,8000070a <printf+0x182>
      for(; *s; s++)
    800006f2:	00094503          	lbu	a0,0(s2)
    800006f6:	d515                	beqz	a0,80000622 <printf+0x9a>
        consputc(*s);
    800006f8:	00000097          	auipc	ra,0x0
    800006fc:	b84080e7          	jalr	-1148(ra) # 8000027c <consputc>
      for(; *s; s++)
    80000700:	0905                	addi	s2,s2,1
    80000702:	00094503          	lbu	a0,0(s2)
    80000706:	f96d                	bnez	a0,800006f8 <printf+0x170>
    80000708:	bf29                	j	80000622 <printf+0x9a>
        s = "(null)";
    8000070a:	00008917          	auipc	s2,0x8
    8000070e:	91690913          	addi	s2,s2,-1770 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000712:	02800513          	li	a0,40
    80000716:	b7cd                	j	800006f8 <printf+0x170>
      consputc('%');
    80000718:	8556                	mv	a0,s5
    8000071a:	00000097          	auipc	ra,0x0
    8000071e:	b62080e7          	jalr	-1182(ra) # 8000027c <consputc>
      break;
    80000722:	b701                	j	80000622 <printf+0x9a>
      consputc('%');
    80000724:	8556                	mv	a0,s5
    80000726:	00000097          	auipc	ra,0x0
    8000072a:	b56080e7          	jalr	-1194(ra) # 8000027c <consputc>
      consputc(c);
    8000072e:	854a                	mv	a0,s2
    80000730:	00000097          	auipc	ra,0x0
    80000734:	b4c080e7          	jalr	-1204(ra) # 8000027c <consputc>
      break;
    80000738:	b5ed                	j	80000622 <printf+0x9a>
  if(locking)
    8000073a:	020d9163          	bnez	s11,8000075c <printf+0x1d4>
}
    8000073e:	70e6                	ld	ra,120(sp)
    80000740:	7446                	ld	s0,112(sp)
    80000742:	74a6                	ld	s1,104(sp)
    80000744:	7906                	ld	s2,96(sp)
    80000746:	69e6                	ld	s3,88(sp)
    80000748:	6a46                	ld	s4,80(sp)
    8000074a:	6aa6                	ld	s5,72(sp)
    8000074c:	6b06                	ld	s6,64(sp)
    8000074e:	7be2                	ld	s7,56(sp)
    80000750:	7c42                	ld	s8,48(sp)
    80000752:	7ca2                	ld	s9,40(sp)
    80000754:	7d02                	ld	s10,32(sp)
    80000756:	6de2                	ld	s11,24(sp)
    80000758:	6129                	addi	sp,sp,192
    8000075a:	8082                	ret
    release(&pr.lock);
    8000075c:	00011517          	auipc	a0,0x11
    80000760:	acc50513          	addi	a0,a0,-1332 # 80011228 <pr>
    80000764:	00000097          	auipc	ra,0x0
    80000768:	534080e7          	jalr	1332(ra) # 80000c98 <release>
}
    8000076c:	bfc9                	j	8000073e <printf+0x1b6>

000000008000076e <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076e:	1101                	addi	sp,sp,-32
    80000770:	ec06                	sd	ra,24(sp)
    80000772:	e822                	sd	s0,16(sp)
    80000774:	e426                	sd	s1,8(sp)
    80000776:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000778:	00011497          	auipc	s1,0x11
    8000077c:	ab048493          	addi	s1,s1,-1360 # 80011228 <pr>
    80000780:	00008597          	auipc	a1,0x8
    80000784:	8b858593          	addi	a1,a1,-1864 # 80008038 <etext+0x38>
    80000788:	8526                	mv	a0,s1
    8000078a:	00000097          	auipc	ra,0x0
    8000078e:	3ca080e7          	jalr	970(ra) # 80000b54 <initlock>
  pr.locking = 1;
    80000792:	4785                	li	a5,1
    80000794:	cc9c                	sw	a5,24(s1)
}
    80000796:	60e2                	ld	ra,24(sp)
    80000798:	6442                	ld	s0,16(sp)
    8000079a:	64a2                	ld	s1,8(sp)
    8000079c:	6105                	addi	sp,sp,32
    8000079e:	8082                	ret

00000000800007a0 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007a0:	1141                	addi	sp,sp,-16
    800007a2:	e406                	sd	ra,8(sp)
    800007a4:	e022                	sd	s0,0(sp)
    800007a6:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a8:	100007b7          	lui	a5,0x10000
    800007ac:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007b0:	f8000713          	li	a4,-128
    800007b4:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b8:	470d                	li	a4,3
    800007ba:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007be:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c2:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c6:	469d                	li	a3,7
    800007c8:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007cc:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007d0:	00008597          	auipc	a1,0x8
    800007d4:	88858593          	addi	a1,a1,-1912 # 80008058 <digits+0x18>
    800007d8:	00011517          	auipc	a0,0x11
    800007dc:	a7050513          	addi	a0,a0,-1424 # 80011248 <uart_tx_lock>
    800007e0:	00000097          	auipc	ra,0x0
    800007e4:	374080e7          	jalr	884(ra) # 80000b54 <initlock>
}
    800007e8:	60a2                	ld	ra,8(sp)
    800007ea:	6402                	ld	s0,0(sp)
    800007ec:	0141                	addi	sp,sp,16
    800007ee:	8082                	ret

00000000800007f0 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007f0:	1101                	addi	sp,sp,-32
    800007f2:	ec06                	sd	ra,24(sp)
    800007f4:	e822                	sd	s0,16(sp)
    800007f6:	e426                	sd	s1,8(sp)
    800007f8:	1000                	addi	s0,sp,32
    800007fa:	84aa                	mv	s1,a0
  push_off();
    800007fc:	00000097          	auipc	ra,0x0
    80000800:	39c080e7          	jalr	924(ra) # 80000b98 <push_off>

  if(panicked){
    80000804:	00008797          	auipc	a5,0x8
    80000808:	7fc7a783          	lw	a5,2044(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080c:	10000737          	lui	a4,0x10000
  if(panicked){
    80000810:	c391                	beqz	a5,80000814 <uartputc_sync+0x24>
    for(;;)
    80000812:	a001                	j	80000812 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000814:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000818:	0ff7f793          	andi	a5,a5,255
    8000081c:	0207f793          	andi	a5,a5,32
    80000820:	dbf5                	beqz	a5,80000814 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000822:	0ff4f793          	andi	a5,s1,255
    80000826:	10000737          	lui	a4,0x10000
    8000082a:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    8000082e:	00000097          	auipc	ra,0x0
    80000832:	40a080e7          	jalr	1034(ra) # 80000c38 <pop_off>
}
    80000836:	60e2                	ld	ra,24(sp)
    80000838:	6442                	ld	s0,16(sp)
    8000083a:	64a2                	ld	s1,8(sp)
    8000083c:	6105                	addi	sp,sp,32
    8000083e:	8082                	ret

0000000080000840 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000840:	00008717          	auipc	a4,0x8
    80000844:	7c873703          	ld	a4,1992(a4) # 80009008 <uart_tx_r>
    80000848:	00008797          	auipc	a5,0x8
    8000084c:	7c87b783          	ld	a5,1992(a5) # 80009010 <uart_tx_w>
    80000850:	06e78c63          	beq	a5,a4,800008c8 <uartstart+0x88>
{
    80000854:	7139                	addi	sp,sp,-64
    80000856:	fc06                	sd	ra,56(sp)
    80000858:	f822                	sd	s0,48(sp)
    8000085a:	f426                	sd	s1,40(sp)
    8000085c:	f04a                	sd	s2,32(sp)
    8000085e:	ec4e                	sd	s3,24(sp)
    80000860:	e852                	sd	s4,16(sp)
    80000862:	e456                	sd	s5,8(sp)
    80000864:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000866:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000086a:	00011a17          	auipc	s4,0x11
    8000086e:	9dea0a13          	addi	s4,s4,-1570 # 80011248 <uart_tx_lock>
    uart_tx_r += 1;
    80000872:	00008497          	auipc	s1,0x8
    80000876:	79648493          	addi	s1,s1,1942 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000087a:	00008997          	auipc	s3,0x8
    8000087e:	79698993          	addi	s3,s3,1942 # 80009010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000882:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000886:	0ff7f793          	andi	a5,a5,255
    8000088a:	0207f793          	andi	a5,a5,32
    8000088e:	c785                	beqz	a5,800008b6 <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000890:	01f77793          	andi	a5,a4,31
    80000894:	97d2                	add	a5,a5,s4
    80000896:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    8000089a:	0705                	addi	a4,a4,1
    8000089c:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000089e:	8526                	mv	a0,s1
    800008a0:	00002097          	auipc	ra,0x2
    800008a4:	a3c080e7          	jalr	-1476(ra) # 800022dc <wakeup>
    
    WriteReg(THR, c);
    800008a8:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008ac:	6098                	ld	a4,0(s1)
    800008ae:	0009b783          	ld	a5,0(s3)
    800008b2:	fce798e3          	bne	a5,a4,80000882 <uartstart+0x42>
  }
}
    800008b6:	70e2                	ld	ra,56(sp)
    800008b8:	7442                	ld	s0,48(sp)
    800008ba:	74a2                	ld	s1,40(sp)
    800008bc:	7902                	ld	s2,32(sp)
    800008be:	69e2                	ld	s3,24(sp)
    800008c0:	6a42                	ld	s4,16(sp)
    800008c2:	6aa2                	ld	s5,8(sp)
    800008c4:	6121                	addi	sp,sp,64
    800008c6:	8082                	ret
    800008c8:	8082                	ret

00000000800008ca <uartputc>:
{
    800008ca:	7179                	addi	sp,sp,-48
    800008cc:	f406                	sd	ra,40(sp)
    800008ce:	f022                	sd	s0,32(sp)
    800008d0:	ec26                	sd	s1,24(sp)
    800008d2:	e84a                	sd	s2,16(sp)
    800008d4:	e44e                	sd	s3,8(sp)
    800008d6:	e052                	sd	s4,0(sp)
    800008d8:	1800                	addi	s0,sp,48
    800008da:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008dc:	00011517          	auipc	a0,0x11
    800008e0:	96c50513          	addi	a0,a0,-1684 # 80011248 <uart_tx_lock>
    800008e4:	00000097          	auipc	ra,0x0
    800008e8:	300080e7          	jalr	768(ra) # 80000be4 <acquire>
  if(panicked){
    800008ec:	00008797          	auipc	a5,0x8
    800008f0:	7147a783          	lw	a5,1812(a5) # 80009000 <panicked>
    800008f4:	c391                	beqz	a5,800008f8 <uartputc+0x2e>
    for(;;)
    800008f6:	a001                	j	800008f6 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008f8:	00008797          	auipc	a5,0x8
    800008fc:	7187b783          	ld	a5,1816(a5) # 80009010 <uart_tx_w>
    80000900:	00008717          	auipc	a4,0x8
    80000904:	70873703          	ld	a4,1800(a4) # 80009008 <uart_tx_r>
    80000908:	02070713          	addi	a4,a4,32
    8000090c:	02f71b63          	bne	a4,a5,80000942 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00011a17          	auipc	s4,0x11
    80000914:	938a0a13          	addi	s4,s4,-1736 # 80011248 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	6f048493          	addi	s1,s1,1776 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	6f090913          	addi	s2,s2,1776 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000928:	85d2                	mv	a1,s4
    8000092a:	8526                	mv	a0,s1
    8000092c:	00002097          	auipc	ra,0x2
    80000930:	824080e7          	jalr	-2012(ra) # 80002150 <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000934:	00093783          	ld	a5,0(s2)
    80000938:	6098                	ld	a4,0(s1)
    8000093a:	02070713          	addi	a4,a4,32
    8000093e:	fef705e3          	beq	a4,a5,80000928 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000942:	00011497          	auipc	s1,0x11
    80000946:	90648493          	addi	s1,s1,-1786 # 80011248 <uart_tx_lock>
    8000094a:	01f7f713          	andi	a4,a5,31
    8000094e:	9726                	add	a4,a4,s1
    80000950:	01370c23          	sb	s3,24(a4)
      uart_tx_w += 1;
    80000954:	0785                	addi	a5,a5,1
    80000956:	00008717          	auipc	a4,0x8
    8000095a:	6af73d23          	sd	a5,1722(a4) # 80009010 <uart_tx_w>
      uartstart();
    8000095e:	00000097          	auipc	ra,0x0
    80000962:	ee2080e7          	jalr	-286(ra) # 80000840 <uartstart>
      release(&uart_tx_lock);
    80000966:	8526                	mv	a0,s1
    80000968:	00000097          	auipc	ra,0x0
    8000096c:	330080e7          	jalr	816(ra) # 80000c98 <release>
}
    80000970:	70a2                	ld	ra,40(sp)
    80000972:	7402                	ld	s0,32(sp)
    80000974:	64e2                	ld	s1,24(sp)
    80000976:	6942                	ld	s2,16(sp)
    80000978:	69a2                	ld	s3,8(sp)
    8000097a:	6a02                	ld	s4,0(sp)
    8000097c:	6145                	addi	sp,sp,48
    8000097e:	8082                	ret

0000000080000980 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000980:	1141                	addi	sp,sp,-16
    80000982:	e422                	sd	s0,8(sp)
    80000984:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000098e:	8b85                	andi	a5,a5,1
    80000990:	cb91                	beqz	a5,800009a4 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000992:	100007b7          	lui	a5,0x10000
    80000996:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000099a:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    8000099e:	6422                	ld	s0,8(sp)
    800009a0:	0141                	addi	sp,sp,16
    800009a2:	8082                	ret
    return -1;
    800009a4:	557d                	li	a0,-1
    800009a6:	bfe5                	j	8000099e <uartgetc+0x1e>

00000000800009a8 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009a8:	1101                	addi	sp,sp,-32
    800009aa:	ec06                	sd	ra,24(sp)
    800009ac:	e822                	sd	s0,16(sp)
    800009ae:	e426                	sd	s1,8(sp)
    800009b0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009b2:	54fd                	li	s1,-1
    int c = uartgetc();
    800009b4:	00000097          	auipc	ra,0x0
    800009b8:	fcc080e7          	jalr	-52(ra) # 80000980 <uartgetc>
    if(c == -1)
    800009bc:	00950763          	beq	a0,s1,800009ca <uartintr+0x22>
      break;
    consoleintr(c);
    800009c0:	00000097          	auipc	ra,0x0
    800009c4:	8fe080e7          	jalr	-1794(ra) # 800002be <consoleintr>
  while(1){
    800009c8:	b7f5                	j	800009b4 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ca:	00011497          	auipc	s1,0x11
    800009ce:	87e48493          	addi	s1,s1,-1922 # 80011248 <uart_tx_lock>
    800009d2:	8526                	mv	a0,s1
    800009d4:	00000097          	auipc	ra,0x0
    800009d8:	210080e7          	jalr	528(ra) # 80000be4 <acquire>
  uartstart();
    800009dc:	00000097          	auipc	ra,0x0
    800009e0:	e64080e7          	jalr	-412(ra) # 80000840 <uartstart>
  release(&uart_tx_lock);
    800009e4:	8526                	mv	a0,s1
    800009e6:	00000097          	auipc	ra,0x0
    800009ea:	2b2080e7          	jalr	690(ra) # 80000c98 <release>
}
    800009ee:	60e2                	ld	ra,24(sp)
    800009f0:	6442                	ld	s0,16(sp)
    800009f2:	64a2                	ld	s1,8(sp)
    800009f4:	6105                	addi	sp,sp,32
    800009f6:	8082                	ret

00000000800009f8 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009f8:	1101                	addi	sp,sp,-32
    800009fa:	ec06                	sd	ra,24(sp)
    800009fc:	e822                	sd	s0,16(sp)
    800009fe:	e426                	sd	s1,8(sp)
    80000a00:	e04a                	sd	s2,0(sp)
    80000a02:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a04:	03451793          	slli	a5,a0,0x34
    80000a08:	ebb9                	bnez	a5,80000a5e <kfree+0x66>
    80000a0a:	84aa                	mv	s1,a0
    80000a0c:	00025797          	auipc	a5,0x25
    80000a10:	5f478793          	addi	a5,a5,1524 # 80026000 <end>
    80000a14:	04f56563          	bltu	a0,a5,80000a5e <kfree+0x66>
    80000a18:	47c5                	li	a5,17
    80000a1a:	07ee                	slli	a5,a5,0x1b
    80000a1c:	04f57163          	bgeu	a0,a5,80000a5e <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a20:	6605                	lui	a2,0x1
    80000a22:	4585                	li	a1,1
    80000a24:	00000097          	auipc	ra,0x0
    80000a28:	2bc080e7          	jalr	700(ra) # 80000ce0 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a2c:	00011917          	auipc	s2,0x11
    80000a30:	85490913          	addi	s2,s2,-1964 # 80011280 <kmem>
    80000a34:	854a                	mv	a0,s2
    80000a36:	00000097          	auipc	ra,0x0
    80000a3a:	1ae080e7          	jalr	430(ra) # 80000be4 <acquire>
  r->next = kmem.freelist;
    80000a3e:	01893783          	ld	a5,24(s2)
    80000a42:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a44:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a48:	854a                	mv	a0,s2
    80000a4a:	00000097          	auipc	ra,0x0
    80000a4e:	24e080e7          	jalr	590(ra) # 80000c98 <release>
}
    80000a52:	60e2                	ld	ra,24(sp)
    80000a54:	6442                	ld	s0,16(sp)
    80000a56:	64a2                	ld	s1,8(sp)
    80000a58:	6902                	ld	s2,0(sp)
    80000a5a:	6105                	addi	sp,sp,32
    80000a5c:	8082                	ret
    panic("kfree");
    80000a5e:	00007517          	auipc	a0,0x7
    80000a62:	60250513          	addi	a0,a0,1538 # 80008060 <digits+0x20>
    80000a66:	00000097          	auipc	ra,0x0
    80000a6a:	ad8080e7          	jalr	-1320(ra) # 8000053e <panic>

0000000080000a6e <freerange>:
{
    80000a6e:	7179                	addi	sp,sp,-48
    80000a70:	f406                	sd	ra,40(sp)
    80000a72:	f022                	sd	s0,32(sp)
    80000a74:	ec26                	sd	s1,24(sp)
    80000a76:	e84a                	sd	s2,16(sp)
    80000a78:	e44e                	sd	s3,8(sp)
    80000a7a:	e052                	sd	s4,0(sp)
    80000a7c:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a7e:	6785                	lui	a5,0x1
    80000a80:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a84:	94aa                	add	s1,s1,a0
    80000a86:	757d                	lui	a0,0xfffff
    80000a88:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a8a:	94be                	add	s1,s1,a5
    80000a8c:	0095ee63          	bltu	a1,s1,80000aa8 <freerange+0x3a>
    80000a90:	892e                	mv	s2,a1
    kfree(p);
    80000a92:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	6985                	lui	s3,0x1
    kfree(p);
    80000a96:	01448533          	add	a0,s1,s4
    80000a9a:	00000097          	auipc	ra,0x0
    80000a9e:	f5e080e7          	jalr	-162(ra) # 800009f8 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aa2:	94ce                	add	s1,s1,s3
    80000aa4:	fe9979e3          	bgeu	s2,s1,80000a96 <freerange+0x28>
}
    80000aa8:	70a2                	ld	ra,40(sp)
    80000aaa:	7402                	ld	s0,32(sp)
    80000aac:	64e2                	ld	s1,24(sp)
    80000aae:	6942                	ld	s2,16(sp)
    80000ab0:	69a2                	ld	s3,8(sp)
    80000ab2:	6a02                	ld	s4,0(sp)
    80000ab4:	6145                	addi	sp,sp,48
    80000ab6:	8082                	ret

0000000080000ab8 <kinit>:
{
    80000ab8:	1141                	addi	sp,sp,-16
    80000aba:	e406                	sd	ra,8(sp)
    80000abc:	e022                	sd	s0,0(sp)
    80000abe:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ac0:	00007597          	auipc	a1,0x7
    80000ac4:	5a858593          	addi	a1,a1,1448 # 80008068 <digits+0x28>
    80000ac8:	00010517          	auipc	a0,0x10
    80000acc:	7b850513          	addi	a0,a0,1976 # 80011280 <kmem>
    80000ad0:	00000097          	auipc	ra,0x0
    80000ad4:	084080e7          	jalr	132(ra) # 80000b54 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000ad8:	45c5                	li	a1,17
    80000ada:	05ee                	slli	a1,a1,0x1b
    80000adc:	00025517          	auipc	a0,0x25
    80000ae0:	52450513          	addi	a0,a0,1316 # 80026000 <end>
    80000ae4:	00000097          	auipc	ra,0x0
    80000ae8:	f8a080e7          	jalr	-118(ra) # 80000a6e <freerange>
}
    80000aec:	60a2                	ld	ra,8(sp)
    80000aee:	6402                	ld	s0,0(sp)
    80000af0:	0141                	addi	sp,sp,16
    80000af2:	8082                	ret

0000000080000af4 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000af4:	1101                	addi	sp,sp,-32
    80000af6:	ec06                	sd	ra,24(sp)
    80000af8:	e822                	sd	s0,16(sp)
    80000afa:	e426                	sd	s1,8(sp)
    80000afc:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000afe:	00010497          	auipc	s1,0x10
    80000b02:	78248493          	addi	s1,s1,1922 # 80011280 <kmem>
    80000b06:	8526                	mv	a0,s1
    80000b08:	00000097          	auipc	ra,0x0
    80000b0c:	0dc080e7          	jalr	220(ra) # 80000be4 <acquire>
  r = kmem.freelist;
    80000b10:	6c84                	ld	s1,24(s1)
  if(r)
    80000b12:	c885                	beqz	s1,80000b42 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b14:	609c                	ld	a5,0(s1)
    80000b16:	00010517          	auipc	a0,0x10
    80000b1a:	76a50513          	addi	a0,a0,1898 # 80011280 <kmem>
    80000b1e:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	178080e7          	jalr	376(ra) # 80000c98 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b28:	6605                	lui	a2,0x1
    80000b2a:	4595                	li	a1,5
    80000b2c:	8526                	mv	a0,s1
    80000b2e:	00000097          	auipc	ra,0x0
    80000b32:	1b2080e7          	jalr	434(ra) # 80000ce0 <memset>
  return (void*)r;
}
    80000b36:	8526                	mv	a0,s1
    80000b38:	60e2                	ld	ra,24(sp)
    80000b3a:	6442                	ld	s0,16(sp)
    80000b3c:	64a2                	ld	s1,8(sp)
    80000b3e:	6105                	addi	sp,sp,32
    80000b40:	8082                	ret
  release(&kmem.lock);
    80000b42:	00010517          	auipc	a0,0x10
    80000b46:	73e50513          	addi	a0,a0,1854 # 80011280 <kmem>
    80000b4a:	00000097          	auipc	ra,0x0
    80000b4e:	14e080e7          	jalr	334(ra) # 80000c98 <release>
  if(r)
    80000b52:	b7d5                	j	80000b36 <kalloc+0x42>

0000000080000b54 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b54:	1141                	addi	sp,sp,-16
    80000b56:	e422                	sd	s0,8(sp)
    80000b58:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b5a:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b5c:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b60:	00053823          	sd	zero,16(a0)
}
    80000b64:	6422                	ld	s0,8(sp)
    80000b66:	0141                	addi	sp,sp,16
    80000b68:	8082                	ret

0000000080000b6a <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b6a:	411c                	lw	a5,0(a0)
    80000b6c:	e399                	bnez	a5,80000b72 <holding+0x8>
    80000b6e:	4501                	li	a0,0
  return r;
}
    80000b70:	8082                	ret
{
    80000b72:	1101                	addi	sp,sp,-32
    80000b74:	ec06                	sd	ra,24(sp)
    80000b76:	e822                	sd	s0,16(sp)
    80000b78:	e426                	sd	s1,8(sp)
    80000b7a:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b7c:	6904                	ld	s1,16(a0)
    80000b7e:	00001097          	auipc	ra,0x1
    80000b82:	efa080e7          	jalr	-262(ra) # 80001a78 <mycpu>
    80000b86:	40a48533          	sub	a0,s1,a0
    80000b8a:	00153513          	seqz	a0,a0
}
    80000b8e:	60e2                	ld	ra,24(sp)
    80000b90:	6442                	ld	s0,16(sp)
    80000b92:	64a2                	ld	s1,8(sp)
    80000b94:	6105                	addi	sp,sp,32
    80000b96:	8082                	ret

0000000080000b98 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b98:	1101                	addi	sp,sp,-32
    80000b9a:	ec06                	sd	ra,24(sp)
    80000b9c:	e822                	sd	s0,16(sp)
    80000b9e:	e426                	sd	s1,8(sp)
    80000ba0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ba2:	100024f3          	csrr	s1,sstatus
    80000ba6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000baa:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bac:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bb0:	00001097          	auipc	ra,0x1
    80000bb4:	ec8080e7          	jalr	-312(ra) # 80001a78 <mycpu>
    80000bb8:	5d3c                	lw	a5,120(a0)
    80000bba:	cf89                	beqz	a5,80000bd4 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bbc:	00001097          	auipc	ra,0x1
    80000bc0:	ebc080e7          	jalr	-324(ra) # 80001a78 <mycpu>
    80000bc4:	5d3c                	lw	a5,120(a0)
    80000bc6:	2785                	addiw	a5,a5,1
    80000bc8:	dd3c                	sw	a5,120(a0)
}
    80000bca:	60e2                	ld	ra,24(sp)
    80000bcc:	6442                	ld	s0,16(sp)
    80000bce:	64a2                	ld	s1,8(sp)
    80000bd0:	6105                	addi	sp,sp,32
    80000bd2:	8082                	ret
    mycpu()->intena = old;
    80000bd4:	00001097          	auipc	ra,0x1
    80000bd8:	ea4080e7          	jalr	-348(ra) # 80001a78 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bdc:	8085                	srli	s1,s1,0x1
    80000bde:	8885                	andi	s1,s1,1
    80000be0:	dd64                	sw	s1,124(a0)
    80000be2:	bfe9                	j	80000bbc <push_off+0x24>

0000000080000be4 <acquire>:
{
    80000be4:	1101                	addi	sp,sp,-32
    80000be6:	ec06                	sd	ra,24(sp)
    80000be8:	e822                	sd	s0,16(sp)
    80000bea:	e426                	sd	s1,8(sp)
    80000bec:	1000                	addi	s0,sp,32
    80000bee:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000bf0:	00000097          	auipc	ra,0x0
    80000bf4:	fa8080e7          	jalr	-88(ra) # 80000b98 <push_off>
  if(holding(lk))
    80000bf8:	8526                	mv	a0,s1
    80000bfa:	00000097          	auipc	ra,0x0
    80000bfe:	f70080e7          	jalr	-144(ra) # 80000b6a <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c02:	4705                	li	a4,1
  if(holding(lk))
    80000c04:	e115                	bnez	a0,80000c28 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c06:	87ba                	mv	a5,a4
    80000c08:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c0c:	2781                	sext.w	a5,a5
    80000c0e:	ffe5                	bnez	a5,80000c06 <acquire+0x22>
  __sync_synchronize();
    80000c10:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c14:	00001097          	auipc	ra,0x1
    80000c18:	e64080e7          	jalr	-412(ra) # 80001a78 <mycpu>
    80000c1c:	e888                	sd	a0,16(s1)
}
    80000c1e:	60e2                	ld	ra,24(sp)
    80000c20:	6442                	ld	s0,16(sp)
    80000c22:	64a2                	ld	s1,8(sp)
    80000c24:	6105                	addi	sp,sp,32
    80000c26:	8082                	ret
    panic("acquire");
    80000c28:	00007517          	auipc	a0,0x7
    80000c2c:	44850513          	addi	a0,a0,1096 # 80008070 <digits+0x30>
    80000c30:	00000097          	auipc	ra,0x0
    80000c34:	90e080e7          	jalr	-1778(ra) # 8000053e <panic>

0000000080000c38 <pop_off>:

void
pop_off(void)
{
    80000c38:	1141                	addi	sp,sp,-16
    80000c3a:	e406                	sd	ra,8(sp)
    80000c3c:	e022                	sd	s0,0(sp)
    80000c3e:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c40:	00001097          	auipc	ra,0x1
    80000c44:	e38080e7          	jalr	-456(ra) # 80001a78 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c48:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c4c:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c4e:	e78d                	bnez	a5,80000c78 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c50:	5d3c                	lw	a5,120(a0)
    80000c52:	02f05b63          	blez	a5,80000c88 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c56:	37fd                	addiw	a5,a5,-1
    80000c58:	0007871b          	sext.w	a4,a5
    80000c5c:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c5e:	eb09                	bnez	a4,80000c70 <pop_off+0x38>
    80000c60:	5d7c                	lw	a5,124(a0)
    80000c62:	c799                	beqz	a5,80000c70 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c64:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c68:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c6c:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c70:	60a2                	ld	ra,8(sp)
    80000c72:	6402                	ld	s0,0(sp)
    80000c74:	0141                	addi	sp,sp,16
    80000c76:	8082                	ret
    panic("pop_off - interruptible");
    80000c78:	00007517          	auipc	a0,0x7
    80000c7c:	40050513          	addi	a0,a0,1024 # 80008078 <digits+0x38>
    80000c80:	00000097          	auipc	ra,0x0
    80000c84:	8be080e7          	jalr	-1858(ra) # 8000053e <panic>
    panic("pop_off");
    80000c88:	00007517          	auipc	a0,0x7
    80000c8c:	40850513          	addi	a0,a0,1032 # 80008090 <digits+0x50>
    80000c90:	00000097          	auipc	ra,0x0
    80000c94:	8ae080e7          	jalr	-1874(ra) # 8000053e <panic>

0000000080000c98 <release>:
{
    80000c98:	1101                	addi	sp,sp,-32
    80000c9a:	ec06                	sd	ra,24(sp)
    80000c9c:	e822                	sd	s0,16(sp)
    80000c9e:	e426                	sd	s1,8(sp)
    80000ca0:	1000                	addi	s0,sp,32
    80000ca2:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000ca4:	00000097          	auipc	ra,0x0
    80000ca8:	ec6080e7          	jalr	-314(ra) # 80000b6a <holding>
    80000cac:	c115                	beqz	a0,80000cd0 <release+0x38>
  lk->cpu = 0;
    80000cae:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cb2:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cb6:	0f50000f          	fence	iorw,ow
    80000cba:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cbe:	00000097          	auipc	ra,0x0
    80000cc2:	f7a080e7          	jalr	-134(ra) # 80000c38 <pop_off>
}
    80000cc6:	60e2                	ld	ra,24(sp)
    80000cc8:	6442                	ld	s0,16(sp)
    80000cca:	64a2                	ld	s1,8(sp)
    80000ccc:	6105                	addi	sp,sp,32
    80000cce:	8082                	ret
    panic("release");
    80000cd0:	00007517          	auipc	a0,0x7
    80000cd4:	3c850513          	addi	a0,a0,968 # 80008098 <digits+0x58>
    80000cd8:	00000097          	auipc	ra,0x0
    80000cdc:	866080e7          	jalr	-1946(ra) # 8000053e <panic>

0000000080000ce0 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000ce0:	1141                	addi	sp,sp,-16
    80000ce2:	e422                	sd	s0,8(sp)
    80000ce4:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000ce6:	ce09                	beqz	a2,80000d00 <memset+0x20>
    80000ce8:	87aa                	mv	a5,a0
    80000cea:	fff6071b          	addiw	a4,a2,-1
    80000cee:	1702                	slli	a4,a4,0x20
    80000cf0:	9301                	srli	a4,a4,0x20
    80000cf2:	0705                	addi	a4,a4,1
    80000cf4:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000cf6:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000cfa:	0785                	addi	a5,a5,1
    80000cfc:	fee79de3          	bne	a5,a4,80000cf6 <memset+0x16>
  }
  return dst;
}
    80000d00:	6422                	ld	s0,8(sp)
    80000d02:	0141                	addi	sp,sp,16
    80000d04:	8082                	ret

0000000080000d06 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d06:	1141                	addi	sp,sp,-16
    80000d08:	e422                	sd	s0,8(sp)
    80000d0a:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d0c:	ca05                	beqz	a2,80000d3c <memcmp+0x36>
    80000d0e:	fff6069b          	addiw	a3,a2,-1
    80000d12:	1682                	slli	a3,a3,0x20
    80000d14:	9281                	srli	a3,a3,0x20
    80000d16:	0685                	addi	a3,a3,1
    80000d18:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d1a:	00054783          	lbu	a5,0(a0)
    80000d1e:	0005c703          	lbu	a4,0(a1)
    80000d22:	00e79863          	bne	a5,a4,80000d32 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d26:	0505                	addi	a0,a0,1
    80000d28:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d2a:	fed518e3          	bne	a0,a3,80000d1a <memcmp+0x14>
  }

  return 0;
    80000d2e:	4501                	li	a0,0
    80000d30:	a019                	j	80000d36 <memcmp+0x30>
      return *s1 - *s2;
    80000d32:	40e7853b          	subw	a0,a5,a4
}
    80000d36:	6422                	ld	s0,8(sp)
    80000d38:	0141                	addi	sp,sp,16
    80000d3a:	8082                	ret
  return 0;
    80000d3c:	4501                	li	a0,0
    80000d3e:	bfe5                	j	80000d36 <memcmp+0x30>

0000000080000d40 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d40:	1141                	addi	sp,sp,-16
    80000d42:	e422                	sd	s0,8(sp)
    80000d44:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d46:	ca0d                	beqz	a2,80000d78 <memmove+0x38>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d48:	00a5f963          	bgeu	a1,a0,80000d5a <memmove+0x1a>
    80000d4c:	02061693          	slli	a3,a2,0x20
    80000d50:	9281                	srli	a3,a3,0x20
    80000d52:	00d58733          	add	a4,a1,a3
    80000d56:	02e56463          	bltu	a0,a4,80000d7e <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d5a:	fff6079b          	addiw	a5,a2,-1
    80000d5e:	1782                	slli	a5,a5,0x20
    80000d60:	9381                	srli	a5,a5,0x20
    80000d62:	0785                	addi	a5,a5,1
    80000d64:	97ae                	add	a5,a5,a1
    80000d66:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d68:	0585                	addi	a1,a1,1
    80000d6a:	0705                	addi	a4,a4,1
    80000d6c:	fff5c683          	lbu	a3,-1(a1)
    80000d70:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d74:	fef59ae3          	bne	a1,a5,80000d68 <memmove+0x28>

  return dst;
}
    80000d78:	6422                	ld	s0,8(sp)
    80000d7a:	0141                	addi	sp,sp,16
    80000d7c:	8082                	ret
    d += n;
    80000d7e:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d80:	fff6079b          	addiw	a5,a2,-1
    80000d84:	1782                	slli	a5,a5,0x20
    80000d86:	9381                	srli	a5,a5,0x20
    80000d88:	fff7c793          	not	a5,a5
    80000d8c:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d8e:	177d                	addi	a4,a4,-1
    80000d90:	16fd                	addi	a3,a3,-1
    80000d92:	00074603          	lbu	a2,0(a4)
    80000d96:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d9a:	fef71ae3          	bne	a4,a5,80000d8e <memmove+0x4e>
    80000d9e:	bfe9                	j	80000d78 <memmove+0x38>

0000000080000da0 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000da0:	1141                	addi	sp,sp,-16
    80000da2:	e406                	sd	ra,8(sp)
    80000da4:	e022                	sd	s0,0(sp)
    80000da6:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000da8:	00000097          	auipc	ra,0x0
    80000dac:	f98080e7          	jalr	-104(ra) # 80000d40 <memmove>
}
    80000db0:	60a2                	ld	ra,8(sp)
    80000db2:	6402                	ld	s0,0(sp)
    80000db4:	0141                	addi	sp,sp,16
    80000db6:	8082                	ret

0000000080000db8 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000db8:	1141                	addi	sp,sp,-16
    80000dba:	e422                	sd	s0,8(sp)
    80000dbc:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dbe:	ce11                	beqz	a2,80000dda <strncmp+0x22>
    80000dc0:	00054783          	lbu	a5,0(a0)
    80000dc4:	cf89                	beqz	a5,80000dde <strncmp+0x26>
    80000dc6:	0005c703          	lbu	a4,0(a1)
    80000dca:	00f71a63          	bne	a4,a5,80000dde <strncmp+0x26>
    n--, p++, q++;
    80000dce:	367d                	addiw	a2,a2,-1
    80000dd0:	0505                	addi	a0,a0,1
    80000dd2:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dd4:	f675                	bnez	a2,80000dc0 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dd6:	4501                	li	a0,0
    80000dd8:	a809                	j	80000dea <strncmp+0x32>
    80000dda:	4501                	li	a0,0
    80000ddc:	a039                	j	80000dea <strncmp+0x32>
  if(n == 0)
    80000dde:	ca09                	beqz	a2,80000df0 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000de0:	00054503          	lbu	a0,0(a0)
    80000de4:	0005c783          	lbu	a5,0(a1)
    80000de8:	9d1d                	subw	a0,a0,a5
}
    80000dea:	6422                	ld	s0,8(sp)
    80000dec:	0141                	addi	sp,sp,16
    80000dee:	8082                	ret
    return 0;
    80000df0:	4501                	li	a0,0
    80000df2:	bfe5                	j	80000dea <strncmp+0x32>

0000000080000df4 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000df4:	1141                	addi	sp,sp,-16
    80000df6:	e422                	sd	s0,8(sp)
    80000df8:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000dfa:	872a                	mv	a4,a0
    80000dfc:	8832                	mv	a6,a2
    80000dfe:	367d                	addiw	a2,a2,-1
    80000e00:	01005963          	blez	a6,80000e12 <strncpy+0x1e>
    80000e04:	0705                	addi	a4,a4,1
    80000e06:	0005c783          	lbu	a5,0(a1)
    80000e0a:	fef70fa3          	sb	a5,-1(a4)
    80000e0e:	0585                	addi	a1,a1,1
    80000e10:	f7f5                	bnez	a5,80000dfc <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e12:	00c05d63          	blez	a2,80000e2c <strncpy+0x38>
    80000e16:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e18:	0685                	addi	a3,a3,1
    80000e1a:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e1e:	fff6c793          	not	a5,a3
    80000e22:	9fb9                	addw	a5,a5,a4
    80000e24:	010787bb          	addw	a5,a5,a6
    80000e28:	fef048e3          	bgtz	a5,80000e18 <strncpy+0x24>
  return os;
}
    80000e2c:	6422                	ld	s0,8(sp)
    80000e2e:	0141                	addi	sp,sp,16
    80000e30:	8082                	ret

0000000080000e32 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e32:	1141                	addi	sp,sp,-16
    80000e34:	e422                	sd	s0,8(sp)
    80000e36:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e38:	02c05363          	blez	a2,80000e5e <safestrcpy+0x2c>
    80000e3c:	fff6069b          	addiw	a3,a2,-1
    80000e40:	1682                	slli	a3,a3,0x20
    80000e42:	9281                	srli	a3,a3,0x20
    80000e44:	96ae                	add	a3,a3,a1
    80000e46:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e48:	00d58963          	beq	a1,a3,80000e5a <safestrcpy+0x28>
    80000e4c:	0585                	addi	a1,a1,1
    80000e4e:	0785                	addi	a5,a5,1
    80000e50:	fff5c703          	lbu	a4,-1(a1)
    80000e54:	fee78fa3          	sb	a4,-1(a5)
    80000e58:	fb65                	bnez	a4,80000e48 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e5a:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e5e:	6422                	ld	s0,8(sp)
    80000e60:	0141                	addi	sp,sp,16
    80000e62:	8082                	ret

0000000080000e64 <strlen>:

int
strlen(const char *s)
{
    80000e64:	1141                	addi	sp,sp,-16
    80000e66:	e422                	sd	s0,8(sp)
    80000e68:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e6a:	00054783          	lbu	a5,0(a0)
    80000e6e:	cf91                	beqz	a5,80000e8a <strlen+0x26>
    80000e70:	0505                	addi	a0,a0,1
    80000e72:	87aa                	mv	a5,a0
    80000e74:	4685                	li	a3,1
    80000e76:	9e89                	subw	a3,a3,a0
    80000e78:	00f6853b          	addw	a0,a3,a5
    80000e7c:	0785                	addi	a5,a5,1
    80000e7e:	fff7c703          	lbu	a4,-1(a5)
    80000e82:	fb7d                	bnez	a4,80000e78 <strlen+0x14>
    ;
  return n;
}
    80000e84:	6422                	ld	s0,8(sp)
    80000e86:	0141                	addi	sp,sp,16
    80000e88:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e8a:	4501                	li	a0,0
    80000e8c:	bfe5                	j	80000e84 <strlen+0x20>

0000000080000e8e <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e8e:	1141                	addi	sp,sp,-16
    80000e90:	e406                	sd	ra,8(sp)
    80000e92:	e022                	sd	s0,0(sp)
    80000e94:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e96:	00001097          	auipc	ra,0x1
    80000e9a:	bd2080e7          	jalr	-1070(ra) # 80001a68 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e9e:	00008717          	auipc	a4,0x8
    80000ea2:	17a70713          	addi	a4,a4,378 # 80009018 <started>
  if(cpuid() == 0){
    80000ea6:	c139                	beqz	a0,80000eec <main+0x5e>
    while(started == 0)
    80000ea8:	431c                	lw	a5,0(a4)
    80000eaa:	2781                	sext.w	a5,a5
    80000eac:	dff5                	beqz	a5,80000ea8 <main+0x1a>
      ;
    __sync_synchronize();
    80000eae:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000eb2:	00001097          	auipc	ra,0x1
    80000eb6:	bb6080e7          	jalr	-1098(ra) # 80001a68 <cpuid>
    80000eba:	85aa                	mv	a1,a0
    80000ebc:	00007517          	auipc	a0,0x7
    80000ec0:	1fc50513          	addi	a0,a0,508 # 800080b8 <digits+0x78>
    80000ec4:	fffff097          	auipc	ra,0xfffff
    80000ec8:	6c4080e7          	jalr	1732(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000ecc:	00000097          	auipc	ra,0x0
    80000ed0:	0d8080e7          	jalr	216(ra) # 80000fa4 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ed4:	00002097          	auipc	ra,0x2
    80000ed8:	80c080e7          	jalr	-2036(ra) # 800026e0 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000edc:	00005097          	auipc	ra,0x5
    80000ee0:	e54080e7          	jalr	-428(ra) # 80005d30 <plicinithart>
  }

  scheduler();        
    80000ee4:	00001097          	auipc	ra,0x1
    80000ee8:	0ba080e7          	jalr	186(ra) # 80001f9e <scheduler>
    consoleinit();
    80000eec:	fffff097          	auipc	ra,0xfffff
    80000ef0:	564080e7          	jalr	1380(ra) # 80000450 <consoleinit>
    printfinit();
    80000ef4:	00000097          	auipc	ra,0x0
    80000ef8:	87a080e7          	jalr	-1926(ra) # 8000076e <printfinit>
    printf("\n");
    80000efc:	00007517          	auipc	a0,0x7
    80000f00:	1cc50513          	addi	a0,a0,460 # 800080c8 <digits+0x88>
    80000f04:	fffff097          	auipc	ra,0xfffff
    80000f08:	684080e7          	jalr	1668(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000f0c:	00007517          	auipc	a0,0x7
    80000f10:	19450513          	addi	a0,a0,404 # 800080a0 <digits+0x60>
    80000f14:	fffff097          	auipc	ra,0xfffff
    80000f18:	674080e7          	jalr	1652(ra) # 80000588 <printf>
    printf("\n");
    80000f1c:	00007517          	auipc	a0,0x7
    80000f20:	1ac50513          	addi	a0,a0,428 # 800080c8 <digits+0x88>
    80000f24:	fffff097          	auipc	ra,0xfffff
    80000f28:	664080e7          	jalr	1636(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80000f2c:	00000097          	auipc	ra,0x0
    80000f30:	b8c080e7          	jalr	-1140(ra) # 80000ab8 <kinit>
    kvminit();       // create kernel page table
    80000f34:	00000097          	auipc	ra,0x0
    80000f38:	322080e7          	jalr	802(ra) # 80001256 <kvminit>
    kvminithart();   // turn on paging
    80000f3c:	00000097          	auipc	ra,0x0
    80000f40:	068080e7          	jalr	104(ra) # 80000fa4 <kvminithart>
    procinit();      // process table
    80000f44:	00001097          	auipc	ra,0x1
    80000f48:	a74080e7          	jalr	-1420(ra) # 800019b8 <procinit>
    trapinit();      // trap vectors
    80000f4c:	00001097          	auipc	ra,0x1
    80000f50:	76c080e7          	jalr	1900(ra) # 800026b8 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f54:	00001097          	auipc	ra,0x1
    80000f58:	78c080e7          	jalr	1932(ra) # 800026e0 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f5c:	00005097          	auipc	ra,0x5
    80000f60:	dbe080e7          	jalr	-578(ra) # 80005d1a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f64:	00005097          	auipc	ra,0x5
    80000f68:	dcc080e7          	jalr	-564(ra) # 80005d30 <plicinithart>
    binit();         // buffer cache
    80000f6c:	00002097          	auipc	ra,0x2
    80000f70:	f98080e7          	jalr	-104(ra) # 80002f04 <binit>
    iinit();         // inode table
    80000f74:	00002097          	auipc	ra,0x2
    80000f78:	628080e7          	jalr	1576(ra) # 8000359c <iinit>
    fileinit();      // file table
    80000f7c:	00003097          	auipc	ra,0x3
    80000f80:	5d2080e7          	jalr	1490(ra) # 8000454e <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f84:	00005097          	auipc	ra,0x5
    80000f88:	ece080e7          	jalr	-306(ra) # 80005e52 <virtio_disk_init>
    userinit();      // first user process
    80000f8c:	00001097          	auipc	ra,0x1
    80000f90:	de0080e7          	jalr	-544(ra) # 80001d6c <userinit>
    __sync_synchronize();
    80000f94:	0ff0000f          	fence
    started = 1;
    80000f98:	4785                	li	a5,1
    80000f9a:	00008717          	auipc	a4,0x8
    80000f9e:	06f72f23          	sw	a5,126(a4) # 80009018 <started>
    80000fa2:	b789                	j	80000ee4 <main+0x56>

0000000080000fa4 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fa4:	1141                	addi	sp,sp,-16
    80000fa6:	e422                	sd	s0,8(sp)
    80000fa8:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000faa:	00008797          	auipc	a5,0x8
    80000fae:	0767b783          	ld	a5,118(a5) # 80009020 <kernel_pagetable>
    80000fb2:	83b1                	srli	a5,a5,0xc
    80000fb4:	577d                	li	a4,-1
    80000fb6:	177e                	slli	a4,a4,0x3f
    80000fb8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fba:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fbe:	12000073          	sfence.vma
  sfence_vma();
}
    80000fc2:	6422                	ld	s0,8(sp)
    80000fc4:	0141                	addi	sp,sp,16
    80000fc6:	8082                	ret

0000000080000fc8 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fc8:	7139                	addi	sp,sp,-64
    80000fca:	fc06                	sd	ra,56(sp)
    80000fcc:	f822                	sd	s0,48(sp)
    80000fce:	f426                	sd	s1,40(sp)
    80000fd0:	f04a                	sd	s2,32(sp)
    80000fd2:	ec4e                	sd	s3,24(sp)
    80000fd4:	e852                	sd	s4,16(sp)
    80000fd6:	e456                	sd	s5,8(sp)
    80000fd8:	e05a                	sd	s6,0(sp)
    80000fda:	0080                	addi	s0,sp,64
    80000fdc:	84aa                	mv	s1,a0
    80000fde:	89ae                	mv	s3,a1
    80000fe0:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fe2:	57fd                	li	a5,-1
    80000fe4:	83e9                	srli	a5,a5,0x1a
    80000fe6:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fe8:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fea:	04b7f263          	bgeu	a5,a1,8000102e <walk+0x66>
    panic("walk");
    80000fee:	00007517          	auipc	a0,0x7
    80000ff2:	0e250513          	addi	a0,a0,226 # 800080d0 <digits+0x90>
    80000ff6:	fffff097          	auipc	ra,0xfffff
    80000ffa:	548080e7          	jalr	1352(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000ffe:	060a8663          	beqz	s5,8000106a <walk+0xa2>
    80001002:	00000097          	auipc	ra,0x0
    80001006:	af2080e7          	jalr	-1294(ra) # 80000af4 <kalloc>
    8000100a:	84aa                	mv	s1,a0
    8000100c:	c529                	beqz	a0,80001056 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000100e:	6605                	lui	a2,0x1
    80001010:	4581                	li	a1,0
    80001012:	00000097          	auipc	ra,0x0
    80001016:	cce080e7          	jalr	-818(ra) # 80000ce0 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000101a:	00c4d793          	srli	a5,s1,0xc
    8000101e:	07aa                	slli	a5,a5,0xa
    80001020:	0017e793          	ori	a5,a5,1
    80001024:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001028:	3a5d                	addiw	s4,s4,-9
    8000102a:	036a0063          	beq	s4,s6,8000104a <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000102e:	0149d933          	srl	s2,s3,s4
    80001032:	1ff97913          	andi	s2,s2,511
    80001036:	090e                	slli	s2,s2,0x3
    80001038:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000103a:	00093483          	ld	s1,0(s2)
    8000103e:	0014f793          	andi	a5,s1,1
    80001042:	dfd5                	beqz	a5,80000ffe <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001044:	80a9                	srli	s1,s1,0xa
    80001046:	04b2                	slli	s1,s1,0xc
    80001048:	b7c5                	j	80001028 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000104a:	00c9d513          	srli	a0,s3,0xc
    8000104e:	1ff57513          	andi	a0,a0,511
    80001052:	050e                	slli	a0,a0,0x3
    80001054:	9526                	add	a0,a0,s1
}
    80001056:	70e2                	ld	ra,56(sp)
    80001058:	7442                	ld	s0,48(sp)
    8000105a:	74a2                	ld	s1,40(sp)
    8000105c:	7902                	ld	s2,32(sp)
    8000105e:	69e2                	ld	s3,24(sp)
    80001060:	6a42                	ld	s4,16(sp)
    80001062:	6aa2                	ld	s5,8(sp)
    80001064:	6b02                	ld	s6,0(sp)
    80001066:	6121                	addi	sp,sp,64
    80001068:	8082                	ret
        return 0;
    8000106a:	4501                	li	a0,0
    8000106c:	b7ed                	j	80001056 <walk+0x8e>

000000008000106e <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000106e:	57fd                	li	a5,-1
    80001070:	83e9                	srli	a5,a5,0x1a
    80001072:	00b7f463          	bgeu	a5,a1,8000107a <walkaddr+0xc>
    return 0;
    80001076:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001078:	8082                	ret
{
    8000107a:	1141                	addi	sp,sp,-16
    8000107c:	e406                	sd	ra,8(sp)
    8000107e:	e022                	sd	s0,0(sp)
    80001080:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001082:	4601                	li	a2,0
    80001084:	00000097          	auipc	ra,0x0
    80001088:	f44080e7          	jalr	-188(ra) # 80000fc8 <walk>
  if(pte == 0)
    8000108c:	c105                	beqz	a0,800010ac <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000108e:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001090:	0117f693          	andi	a3,a5,17
    80001094:	4745                	li	a4,17
    return 0;
    80001096:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001098:	00e68663          	beq	a3,a4,800010a4 <walkaddr+0x36>
}
    8000109c:	60a2                	ld	ra,8(sp)
    8000109e:	6402                	ld	s0,0(sp)
    800010a0:	0141                	addi	sp,sp,16
    800010a2:	8082                	ret
  pa = PTE2PA(*pte);
    800010a4:	00a7d513          	srli	a0,a5,0xa
    800010a8:	0532                	slli	a0,a0,0xc
  return pa;
    800010aa:	bfcd                	j	8000109c <walkaddr+0x2e>
    return 0;
    800010ac:	4501                	li	a0,0
    800010ae:	b7fd                	j	8000109c <walkaddr+0x2e>

00000000800010b0 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010b0:	715d                	addi	sp,sp,-80
    800010b2:	e486                	sd	ra,72(sp)
    800010b4:	e0a2                	sd	s0,64(sp)
    800010b6:	fc26                	sd	s1,56(sp)
    800010b8:	f84a                	sd	s2,48(sp)
    800010ba:	f44e                	sd	s3,40(sp)
    800010bc:	f052                	sd	s4,32(sp)
    800010be:	ec56                	sd	s5,24(sp)
    800010c0:	e85a                	sd	s6,16(sp)
    800010c2:	e45e                	sd	s7,8(sp)
    800010c4:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010c6:	c205                	beqz	a2,800010e6 <mappages+0x36>
    800010c8:	8aaa                	mv	s5,a0
    800010ca:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010cc:	77fd                	lui	a5,0xfffff
    800010ce:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010d2:	15fd                	addi	a1,a1,-1
    800010d4:	00c589b3          	add	s3,a1,a2
    800010d8:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010dc:	8952                	mv	s2,s4
    800010de:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010e2:	6b85                	lui	s7,0x1
    800010e4:	a015                	j	80001108 <mappages+0x58>
    panic("mappages: size");
    800010e6:	00007517          	auipc	a0,0x7
    800010ea:	ff250513          	addi	a0,a0,-14 # 800080d8 <digits+0x98>
    800010ee:	fffff097          	auipc	ra,0xfffff
    800010f2:	450080e7          	jalr	1104(ra) # 8000053e <panic>
      panic("mappages: remap");
    800010f6:	00007517          	auipc	a0,0x7
    800010fa:	ff250513          	addi	a0,a0,-14 # 800080e8 <digits+0xa8>
    800010fe:	fffff097          	auipc	ra,0xfffff
    80001102:	440080e7          	jalr	1088(ra) # 8000053e <panic>
    a += PGSIZE;
    80001106:	995e                	add	s2,s2,s7
  for(;;){
    80001108:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000110c:	4605                	li	a2,1
    8000110e:	85ca                	mv	a1,s2
    80001110:	8556                	mv	a0,s5
    80001112:	00000097          	auipc	ra,0x0
    80001116:	eb6080e7          	jalr	-330(ra) # 80000fc8 <walk>
    8000111a:	cd19                	beqz	a0,80001138 <mappages+0x88>
    if(*pte & PTE_V)
    8000111c:	611c                	ld	a5,0(a0)
    8000111e:	8b85                	andi	a5,a5,1
    80001120:	fbf9                	bnez	a5,800010f6 <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001122:	80b1                	srli	s1,s1,0xc
    80001124:	04aa                	slli	s1,s1,0xa
    80001126:	0164e4b3          	or	s1,s1,s6
    8000112a:	0014e493          	ori	s1,s1,1
    8000112e:	e104                	sd	s1,0(a0)
    if(a == last)
    80001130:	fd391be3          	bne	s2,s3,80001106 <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    80001134:	4501                	li	a0,0
    80001136:	a011                	j	8000113a <mappages+0x8a>
      return -1;
    80001138:	557d                	li	a0,-1
}
    8000113a:	60a6                	ld	ra,72(sp)
    8000113c:	6406                	ld	s0,64(sp)
    8000113e:	74e2                	ld	s1,56(sp)
    80001140:	7942                	ld	s2,48(sp)
    80001142:	79a2                	ld	s3,40(sp)
    80001144:	7a02                	ld	s4,32(sp)
    80001146:	6ae2                	ld	s5,24(sp)
    80001148:	6b42                	ld	s6,16(sp)
    8000114a:	6ba2                	ld	s7,8(sp)
    8000114c:	6161                	addi	sp,sp,80
    8000114e:	8082                	ret

0000000080001150 <kvmmap>:
{
    80001150:	1141                	addi	sp,sp,-16
    80001152:	e406                	sd	ra,8(sp)
    80001154:	e022                	sd	s0,0(sp)
    80001156:	0800                	addi	s0,sp,16
    80001158:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000115a:	86b2                	mv	a3,a2
    8000115c:	863e                	mv	a2,a5
    8000115e:	00000097          	auipc	ra,0x0
    80001162:	f52080e7          	jalr	-174(ra) # 800010b0 <mappages>
    80001166:	e509                	bnez	a0,80001170 <kvmmap+0x20>
}
    80001168:	60a2                	ld	ra,8(sp)
    8000116a:	6402                	ld	s0,0(sp)
    8000116c:	0141                	addi	sp,sp,16
    8000116e:	8082                	ret
    panic("kvmmap");
    80001170:	00007517          	auipc	a0,0x7
    80001174:	f8850513          	addi	a0,a0,-120 # 800080f8 <digits+0xb8>
    80001178:	fffff097          	auipc	ra,0xfffff
    8000117c:	3c6080e7          	jalr	966(ra) # 8000053e <panic>

0000000080001180 <kvmmake>:
{
    80001180:	1101                	addi	sp,sp,-32
    80001182:	ec06                	sd	ra,24(sp)
    80001184:	e822                	sd	s0,16(sp)
    80001186:	e426                	sd	s1,8(sp)
    80001188:	e04a                	sd	s2,0(sp)
    8000118a:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000118c:	00000097          	auipc	ra,0x0
    80001190:	968080e7          	jalr	-1688(ra) # 80000af4 <kalloc>
    80001194:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001196:	6605                	lui	a2,0x1
    80001198:	4581                	li	a1,0
    8000119a:	00000097          	auipc	ra,0x0
    8000119e:	b46080e7          	jalr	-1210(ra) # 80000ce0 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011a2:	4719                	li	a4,6
    800011a4:	6685                	lui	a3,0x1
    800011a6:	10000637          	lui	a2,0x10000
    800011aa:	100005b7          	lui	a1,0x10000
    800011ae:	8526                	mv	a0,s1
    800011b0:	00000097          	auipc	ra,0x0
    800011b4:	fa0080e7          	jalr	-96(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011b8:	4719                	li	a4,6
    800011ba:	6685                	lui	a3,0x1
    800011bc:	10001637          	lui	a2,0x10001
    800011c0:	100015b7          	lui	a1,0x10001
    800011c4:	8526                	mv	a0,s1
    800011c6:	00000097          	auipc	ra,0x0
    800011ca:	f8a080e7          	jalr	-118(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011ce:	4719                	li	a4,6
    800011d0:	004006b7          	lui	a3,0x400
    800011d4:	0c000637          	lui	a2,0xc000
    800011d8:	0c0005b7          	lui	a1,0xc000
    800011dc:	8526                	mv	a0,s1
    800011de:	00000097          	auipc	ra,0x0
    800011e2:	f72080e7          	jalr	-142(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011e6:	00007917          	auipc	s2,0x7
    800011ea:	e1a90913          	addi	s2,s2,-486 # 80008000 <etext>
    800011ee:	4729                	li	a4,10
    800011f0:	80007697          	auipc	a3,0x80007
    800011f4:	e1068693          	addi	a3,a3,-496 # 8000 <_entry-0x7fff8000>
    800011f8:	4605                	li	a2,1
    800011fa:	067e                	slli	a2,a2,0x1f
    800011fc:	85b2                	mv	a1,a2
    800011fe:	8526                	mv	a0,s1
    80001200:	00000097          	auipc	ra,0x0
    80001204:	f50080e7          	jalr	-176(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001208:	4719                	li	a4,6
    8000120a:	46c5                	li	a3,17
    8000120c:	06ee                	slli	a3,a3,0x1b
    8000120e:	412686b3          	sub	a3,a3,s2
    80001212:	864a                	mv	a2,s2
    80001214:	85ca                	mv	a1,s2
    80001216:	8526                	mv	a0,s1
    80001218:	00000097          	auipc	ra,0x0
    8000121c:	f38080e7          	jalr	-200(ra) # 80001150 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001220:	4729                	li	a4,10
    80001222:	6685                	lui	a3,0x1
    80001224:	00006617          	auipc	a2,0x6
    80001228:	ddc60613          	addi	a2,a2,-548 # 80007000 <_trampoline>
    8000122c:	040005b7          	lui	a1,0x4000
    80001230:	15fd                	addi	a1,a1,-1
    80001232:	05b2                	slli	a1,a1,0xc
    80001234:	8526                	mv	a0,s1
    80001236:	00000097          	auipc	ra,0x0
    8000123a:	f1a080e7          	jalr	-230(ra) # 80001150 <kvmmap>
  proc_mapstacks(kpgtbl);
    8000123e:	8526                	mv	a0,s1
    80001240:	00000097          	auipc	ra,0x0
    80001244:	6e2080e7          	jalr	1762(ra) # 80001922 <proc_mapstacks>
}
    80001248:	8526                	mv	a0,s1
    8000124a:	60e2                	ld	ra,24(sp)
    8000124c:	6442                	ld	s0,16(sp)
    8000124e:	64a2                	ld	s1,8(sp)
    80001250:	6902                	ld	s2,0(sp)
    80001252:	6105                	addi	sp,sp,32
    80001254:	8082                	ret

0000000080001256 <kvminit>:
{
    80001256:	1141                	addi	sp,sp,-16
    80001258:	e406                	sd	ra,8(sp)
    8000125a:	e022                	sd	s0,0(sp)
    8000125c:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000125e:	00000097          	auipc	ra,0x0
    80001262:	f22080e7          	jalr	-222(ra) # 80001180 <kvmmake>
    80001266:	00008797          	auipc	a5,0x8
    8000126a:	daa7bd23          	sd	a0,-582(a5) # 80009020 <kernel_pagetable>
}
    8000126e:	60a2                	ld	ra,8(sp)
    80001270:	6402                	ld	s0,0(sp)
    80001272:	0141                	addi	sp,sp,16
    80001274:	8082                	ret

0000000080001276 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001276:	715d                	addi	sp,sp,-80
    80001278:	e486                	sd	ra,72(sp)
    8000127a:	e0a2                	sd	s0,64(sp)
    8000127c:	fc26                	sd	s1,56(sp)
    8000127e:	f84a                	sd	s2,48(sp)
    80001280:	f44e                	sd	s3,40(sp)
    80001282:	f052                	sd	s4,32(sp)
    80001284:	ec56                	sd	s5,24(sp)
    80001286:	e85a                	sd	s6,16(sp)
    80001288:	e45e                	sd	s7,8(sp)
    8000128a:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000128c:	03459793          	slli	a5,a1,0x34
    80001290:	e795                	bnez	a5,800012bc <uvmunmap+0x46>
    80001292:	8a2a                	mv	s4,a0
    80001294:	892e                	mv	s2,a1
    80001296:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001298:	0632                	slli	a2,a2,0xc
    8000129a:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000129e:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012a0:	6b05                	lui	s6,0x1
    800012a2:	0735e863          	bltu	a1,s3,80001312 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012a6:	60a6                	ld	ra,72(sp)
    800012a8:	6406                	ld	s0,64(sp)
    800012aa:	74e2                	ld	s1,56(sp)
    800012ac:	7942                	ld	s2,48(sp)
    800012ae:	79a2                	ld	s3,40(sp)
    800012b0:	7a02                	ld	s4,32(sp)
    800012b2:	6ae2                	ld	s5,24(sp)
    800012b4:	6b42                	ld	s6,16(sp)
    800012b6:	6ba2                	ld	s7,8(sp)
    800012b8:	6161                	addi	sp,sp,80
    800012ba:	8082                	ret
    panic("uvmunmap: not aligned");
    800012bc:	00007517          	auipc	a0,0x7
    800012c0:	e4450513          	addi	a0,a0,-444 # 80008100 <digits+0xc0>
    800012c4:	fffff097          	auipc	ra,0xfffff
    800012c8:	27a080e7          	jalr	634(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800012cc:	00007517          	auipc	a0,0x7
    800012d0:	e4c50513          	addi	a0,a0,-436 # 80008118 <digits+0xd8>
    800012d4:	fffff097          	auipc	ra,0xfffff
    800012d8:	26a080e7          	jalr	618(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    800012dc:	00007517          	auipc	a0,0x7
    800012e0:	e4c50513          	addi	a0,a0,-436 # 80008128 <digits+0xe8>
    800012e4:	fffff097          	auipc	ra,0xfffff
    800012e8:	25a080e7          	jalr	602(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    800012ec:	00007517          	auipc	a0,0x7
    800012f0:	e5450513          	addi	a0,a0,-428 # 80008140 <digits+0x100>
    800012f4:	fffff097          	auipc	ra,0xfffff
    800012f8:	24a080e7          	jalr	586(ra) # 8000053e <panic>
      uint64 pa = PTE2PA(*pte);
    800012fc:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800012fe:	0532                	slli	a0,a0,0xc
    80001300:	fffff097          	auipc	ra,0xfffff
    80001304:	6f8080e7          	jalr	1784(ra) # 800009f8 <kfree>
    *pte = 0;
    80001308:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000130c:	995a                	add	s2,s2,s6
    8000130e:	f9397ce3          	bgeu	s2,s3,800012a6 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001312:	4601                	li	a2,0
    80001314:	85ca                	mv	a1,s2
    80001316:	8552                	mv	a0,s4
    80001318:	00000097          	auipc	ra,0x0
    8000131c:	cb0080e7          	jalr	-848(ra) # 80000fc8 <walk>
    80001320:	84aa                	mv	s1,a0
    80001322:	d54d                	beqz	a0,800012cc <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001324:	6108                	ld	a0,0(a0)
    80001326:	00157793          	andi	a5,a0,1
    8000132a:	dbcd                	beqz	a5,800012dc <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000132c:	3ff57793          	andi	a5,a0,1023
    80001330:	fb778ee3          	beq	a5,s7,800012ec <uvmunmap+0x76>
    if(do_free){
    80001334:	fc0a8ae3          	beqz	s5,80001308 <uvmunmap+0x92>
    80001338:	b7d1                	j	800012fc <uvmunmap+0x86>

000000008000133a <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000133a:	1101                	addi	sp,sp,-32
    8000133c:	ec06                	sd	ra,24(sp)
    8000133e:	e822                	sd	s0,16(sp)
    80001340:	e426                	sd	s1,8(sp)
    80001342:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001344:	fffff097          	auipc	ra,0xfffff
    80001348:	7b0080e7          	jalr	1968(ra) # 80000af4 <kalloc>
    8000134c:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000134e:	c519                	beqz	a0,8000135c <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001350:	6605                	lui	a2,0x1
    80001352:	4581                	li	a1,0
    80001354:	00000097          	auipc	ra,0x0
    80001358:	98c080e7          	jalr	-1652(ra) # 80000ce0 <memset>
  return pagetable;
}
    8000135c:	8526                	mv	a0,s1
    8000135e:	60e2                	ld	ra,24(sp)
    80001360:	6442                	ld	s0,16(sp)
    80001362:	64a2                	ld	s1,8(sp)
    80001364:	6105                	addi	sp,sp,32
    80001366:	8082                	ret

0000000080001368 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001368:	7179                	addi	sp,sp,-48
    8000136a:	f406                	sd	ra,40(sp)
    8000136c:	f022                	sd	s0,32(sp)
    8000136e:	ec26                	sd	s1,24(sp)
    80001370:	e84a                	sd	s2,16(sp)
    80001372:	e44e                	sd	s3,8(sp)
    80001374:	e052                	sd	s4,0(sp)
    80001376:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001378:	6785                	lui	a5,0x1
    8000137a:	04f67863          	bgeu	a2,a5,800013ca <uvminit+0x62>
    8000137e:	8a2a                	mv	s4,a0
    80001380:	89ae                	mv	s3,a1
    80001382:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001384:	fffff097          	auipc	ra,0xfffff
    80001388:	770080e7          	jalr	1904(ra) # 80000af4 <kalloc>
    8000138c:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000138e:	6605                	lui	a2,0x1
    80001390:	4581                	li	a1,0
    80001392:	00000097          	auipc	ra,0x0
    80001396:	94e080e7          	jalr	-1714(ra) # 80000ce0 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000139a:	4779                	li	a4,30
    8000139c:	86ca                	mv	a3,s2
    8000139e:	6605                	lui	a2,0x1
    800013a0:	4581                	li	a1,0
    800013a2:	8552                	mv	a0,s4
    800013a4:	00000097          	auipc	ra,0x0
    800013a8:	d0c080e7          	jalr	-756(ra) # 800010b0 <mappages>
  memmove(mem, src, sz);
    800013ac:	8626                	mv	a2,s1
    800013ae:	85ce                	mv	a1,s3
    800013b0:	854a                	mv	a0,s2
    800013b2:	00000097          	auipc	ra,0x0
    800013b6:	98e080e7          	jalr	-1650(ra) # 80000d40 <memmove>
}
    800013ba:	70a2                	ld	ra,40(sp)
    800013bc:	7402                	ld	s0,32(sp)
    800013be:	64e2                	ld	s1,24(sp)
    800013c0:	6942                	ld	s2,16(sp)
    800013c2:	69a2                	ld	s3,8(sp)
    800013c4:	6a02                	ld	s4,0(sp)
    800013c6:	6145                	addi	sp,sp,48
    800013c8:	8082                	ret
    panic("inituvm: more than a page");
    800013ca:	00007517          	auipc	a0,0x7
    800013ce:	d8e50513          	addi	a0,a0,-626 # 80008158 <digits+0x118>
    800013d2:	fffff097          	auipc	ra,0xfffff
    800013d6:	16c080e7          	jalr	364(ra) # 8000053e <panic>

00000000800013da <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013da:	1101                	addi	sp,sp,-32
    800013dc:	ec06                	sd	ra,24(sp)
    800013de:	e822                	sd	s0,16(sp)
    800013e0:	e426                	sd	s1,8(sp)
    800013e2:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013e4:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013e6:	00b67d63          	bgeu	a2,a1,80001400 <uvmdealloc+0x26>
    800013ea:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013ec:	6785                	lui	a5,0x1
    800013ee:	17fd                	addi	a5,a5,-1
    800013f0:	00f60733          	add	a4,a2,a5
    800013f4:	767d                	lui	a2,0xfffff
    800013f6:	8f71                	and	a4,a4,a2
    800013f8:	97ae                	add	a5,a5,a1
    800013fa:	8ff1                	and	a5,a5,a2
    800013fc:	00f76863          	bltu	a4,a5,8000140c <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001400:	8526                	mv	a0,s1
    80001402:	60e2                	ld	ra,24(sp)
    80001404:	6442                	ld	s0,16(sp)
    80001406:	64a2                	ld	s1,8(sp)
    80001408:	6105                	addi	sp,sp,32
    8000140a:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000140c:	8f99                	sub	a5,a5,a4
    8000140e:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001410:	4685                	li	a3,1
    80001412:	0007861b          	sext.w	a2,a5
    80001416:	85ba                	mv	a1,a4
    80001418:	00000097          	auipc	ra,0x0
    8000141c:	e5e080e7          	jalr	-418(ra) # 80001276 <uvmunmap>
    80001420:	b7c5                	j	80001400 <uvmdealloc+0x26>

0000000080001422 <uvmalloc>:
  if(newsz < oldsz)
    80001422:	0ab66163          	bltu	a2,a1,800014c4 <uvmalloc+0xa2>
{
    80001426:	7139                	addi	sp,sp,-64
    80001428:	fc06                	sd	ra,56(sp)
    8000142a:	f822                	sd	s0,48(sp)
    8000142c:	f426                	sd	s1,40(sp)
    8000142e:	f04a                	sd	s2,32(sp)
    80001430:	ec4e                	sd	s3,24(sp)
    80001432:	e852                	sd	s4,16(sp)
    80001434:	e456                	sd	s5,8(sp)
    80001436:	0080                	addi	s0,sp,64
    80001438:	8aaa                	mv	s5,a0
    8000143a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000143c:	6985                	lui	s3,0x1
    8000143e:	19fd                	addi	s3,s3,-1
    80001440:	95ce                	add	a1,a1,s3
    80001442:	79fd                	lui	s3,0xfffff
    80001444:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001448:	08c9f063          	bgeu	s3,a2,800014c8 <uvmalloc+0xa6>
    8000144c:	894e                	mv	s2,s3
    mem = kalloc();
    8000144e:	fffff097          	auipc	ra,0xfffff
    80001452:	6a6080e7          	jalr	1702(ra) # 80000af4 <kalloc>
    80001456:	84aa                	mv	s1,a0
    if(mem == 0){
    80001458:	c51d                	beqz	a0,80001486 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000145a:	6605                	lui	a2,0x1
    8000145c:	4581                	li	a1,0
    8000145e:	00000097          	auipc	ra,0x0
    80001462:	882080e7          	jalr	-1918(ra) # 80000ce0 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001466:	4779                	li	a4,30
    80001468:	86a6                	mv	a3,s1
    8000146a:	6605                	lui	a2,0x1
    8000146c:	85ca                	mv	a1,s2
    8000146e:	8556                	mv	a0,s5
    80001470:	00000097          	auipc	ra,0x0
    80001474:	c40080e7          	jalr	-960(ra) # 800010b0 <mappages>
    80001478:	e905                	bnez	a0,800014a8 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000147a:	6785                	lui	a5,0x1
    8000147c:	993e                	add	s2,s2,a5
    8000147e:	fd4968e3          	bltu	s2,s4,8000144e <uvmalloc+0x2c>
  return newsz;
    80001482:	8552                	mv	a0,s4
    80001484:	a809                	j	80001496 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001486:	864e                	mv	a2,s3
    80001488:	85ca                	mv	a1,s2
    8000148a:	8556                	mv	a0,s5
    8000148c:	00000097          	auipc	ra,0x0
    80001490:	f4e080e7          	jalr	-178(ra) # 800013da <uvmdealloc>
      return 0;
    80001494:	4501                	li	a0,0
}
    80001496:	70e2                	ld	ra,56(sp)
    80001498:	7442                	ld	s0,48(sp)
    8000149a:	74a2                	ld	s1,40(sp)
    8000149c:	7902                	ld	s2,32(sp)
    8000149e:	69e2                	ld	s3,24(sp)
    800014a0:	6a42                	ld	s4,16(sp)
    800014a2:	6aa2                	ld	s5,8(sp)
    800014a4:	6121                	addi	sp,sp,64
    800014a6:	8082                	ret
      kfree(mem);
    800014a8:	8526                	mv	a0,s1
    800014aa:	fffff097          	auipc	ra,0xfffff
    800014ae:	54e080e7          	jalr	1358(ra) # 800009f8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014b2:	864e                	mv	a2,s3
    800014b4:	85ca                	mv	a1,s2
    800014b6:	8556                	mv	a0,s5
    800014b8:	00000097          	auipc	ra,0x0
    800014bc:	f22080e7          	jalr	-222(ra) # 800013da <uvmdealloc>
      return 0;
    800014c0:	4501                	li	a0,0
    800014c2:	bfd1                	j	80001496 <uvmalloc+0x74>
    return oldsz;
    800014c4:	852e                	mv	a0,a1
}
    800014c6:	8082                	ret
  return newsz;
    800014c8:	8532                	mv	a0,a2
    800014ca:	b7f1                	j	80001496 <uvmalloc+0x74>

00000000800014cc <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014cc:	7179                	addi	sp,sp,-48
    800014ce:	f406                	sd	ra,40(sp)
    800014d0:	f022                	sd	s0,32(sp)
    800014d2:	ec26                	sd	s1,24(sp)
    800014d4:	e84a                	sd	s2,16(sp)
    800014d6:	e44e                	sd	s3,8(sp)
    800014d8:	e052                	sd	s4,0(sp)
    800014da:	1800                	addi	s0,sp,48
    800014dc:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014de:	84aa                	mv	s1,a0
    800014e0:	6905                	lui	s2,0x1
    800014e2:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014e4:	4985                	li	s3,1
    800014e6:	a821                	j	800014fe <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014e8:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014ea:	0532                	slli	a0,a0,0xc
    800014ec:	00000097          	auipc	ra,0x0
    800014f0:	fe0080e7          	jalr	-32(ra) # 800014cc <freewalk>
      pagetable[i] = 0;
    800014f4:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014f8:	04a1                	addi	s1,s1,8
    800014fa:	03248163          	beq	s1,s2,8000151c <freewalk+0x50>
    pte_t pte = pagetable[i];
    800014fe:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001500:	00f57793          	andi	a5,a0,15
    80001504:	ff3782e3          	beq	a5,s3,800014e8 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001508:	8905                	andi	a0,a0,1
    8000150a:	d57d                	beqz	a0,800014f8 <freewalk+0x2c>
      panic("freewalk: leaf");
    8000150c:	00007517          	auipc	a0,0x7
    80001510:	c6c50513          	addi	a0,a0,-916 # 80008178 <digits+0x138>
    80001514:	fffff097          	auipc	ra,0xfffff
    80001518:	02a080e7          	jalr	42(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    8000151c:	8552                	mv	a0,s4
    8000151e:	fffff097          	auipc	ra,0xfffff
    80001522:	4da080e7          	jalr	1242(ra) # 800009f8 <kfree>
}
    80001526:	70a2                	ld	ra,40(sp)
    80001528:	7402                	ld	s0,32(sp)
    8000152a:	64e2                	ld	s1,24(sp)
    8000152c:	6942                	ld	s2,16(sp)
    8000152e:	69a2                	ld	s3,8(sp)
    80001530:	6a02                	ld	s4,0(sp)
    80001532:	6145                	addi	sp,sp,48
    80001534:	8082                	ret

0000000080001536 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001536:	1101                	addi	sp,sp,-32
    80001538:	ec06                	sd	ra,24(sp)
    8000153a:	e822                	sd	s0,16(sp)
    8000153c:	e426                	sd	s1,8(sp)
    8000153e:	1000                	addi	s0,sp,32
    80001540:	84aa                	mv	s1,a0
  if(sz > 0)
    80001542:	e999                	bnez	a1,80001558 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001544:	8526                	mv	a0,s1
    80001546:	00000097          	auipc	ra,0x0
    8000154a:	f86080e7          	jalr	-122(ra) # 800014cc <freewalk>
}
    8000154e:	60e2                	ld	ra,24(sp)
    80001550:	6442                	ld	s0,16(sp)
    80001552:	64a2                	ld	s1,8(sp)
    80001554:	6105                	addi	sp,sp,32
    80001556:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001558:	6605                	lui	a2,0x1
    8000155a:	167d                	addi	a2,a2,-1
    8000155c:	962e                	add	a2,a2,a1
    8000155e:	4685                	li	a3,1
    80001560:	8231                	srli	a2,a2,0xc
    80001562:	4581                	li	a1,0
    80001564:	00000097          	auipc	ra,0x0
    80001568:	d12080e7          	jalr	-750(ra) # 80001276 <uvmunmap>
    8000156c:	bfe1                	j	80001544 <uvmfree+0xe>

000000008000156e <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    8000156e:	c679                	beqz	a2,8000163c <uvmcopy+0xce>
{
    80001570:	715d                	addi	sp,sp,-80
    80001572:	e486                	sd	ra,72(sp)
    80001574:	e0a2                	sd	s0,64(sp)
    80001576:	fc26                	sd	s1,56(sp)
    80001578:	f84a                	sd	s2,48(sp)
    8000157a:	f44e                	sd	s3,40(sp)
    8000157c:	f052                	sd	s4,32(sp)
    8000157e:	ec56                	sd	s5,24(sp)
    80001580:	e85a                	sd	s6,16(sp)
    80001582:	e45e                	sd	s7,8(sp)
    80001584:	0880                	addi	s0,sp,80
    80001586:	8b2a                	mv	s6,a0
    80001588:	8aae                	mv	s5,a1
    8000158a:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000158c:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    8000158e:	4601                	li	a2,0
    80001590:	85ce                	mv	a1,s3
    80001592:	855a                	mv	a0,s6
    80001594:	00000097          	auipc	ra,0x0
    80001598:	a34080e7          	jalr	-1484(ra) # 80000fc8 <walk>
    8000159c:	c531                	beqz	a0,800015e8 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    8000159e:	6118                	ld	a4,0(a0)
    800015a0:	00177793          	andi	a5,a4,1
    800015a4:	cbb1                	beqz	a5,800015f8 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015a6:	00a75593          	srli	a1,a4,0xa
    800015aa:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015ae:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015b2:	fffff097          	auipc	ra,0xfffff
    800015b6:	542080e7          	jalr	1346(ra) # 80000af4 <kalloc>
    800015ba:	892a                	mv	s2,a0
    800015bc:	c939                	beqz	a0,80001612 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015be:	6605                	lui	a2,0x1
    800015c0:	85de                	mv	a1,s7
    800015c2:	fffff097          	auipc	ra,0xfffff
    800015c6:	77e080e7          	jalr	1918(ra) # 80000d40 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015ca:	8726                	mv	a4,s1
    800015cc:	86ca                	mv	a3,s2
    800015ce:	6605                	lui	a2,0x1
    800015d0:	85ce                	mv	a1,s3
    800015d2:	8556                	mv	a0,s5
    800015d4:	00000097          	auipc	ra,0x0
    800015d8:	adc080e7          	jalr	-1316(ra) # 800010b0 <mappages>
    800015dc:	e515                	bnez	a0,80001608 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015de:	6785                	lui	a5,0x1
    800015e0:	99be                	add	s3,s3,a5
    800015e2:	fb49e6e3          	bltu	s3,s4,8000158e <uvmcopy+0x20>
    800015e6:	a081                	j	80001626 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015e8:	00007517          	auipc	a0,0x7
    800015ec:	ba050513          	addi	a0,a0,-1120 # 80008188 <digits+0x148>
    800015f0:	fffff097          	auipc	ra,0xfffff
    800015f4:	f4e080e7          	jalr	-178(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    800015f8:	00007517          	auipc	a0,0x7
    800015fc:	bb050513          	addi	a0,a0,-1104 # 800081a8 <digits+0x168>
    80001600:	fffff097          	auipc	ra,0xfffff
    80001604:	f3e080e7          	jalr	-194(ra) # 8000053e <panic>
      kfree(mem);
    80001608:	854a                	mv	a0,s2
    8000160a:	fffff097          	auipc	ra,0xfffff
    8000160e:	3ee080e7          	jalr	1006(ra) # 800009f8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001612:	4685                	li	a3,1
    80001614:	00c9d613          	srli	a2,s3,0xc
    80001618:	4581                	li	a1,0
    8000161a:	8556                	mv	a0,s5
    8000161c:	00000097          	auipc	ra,0x0
    80001620:	c5a080e7          	jalr	-934(ra) # 80001276 <uvmunmap>
  return -1;
    80001624:	557d                	li	a0,-1
}
    80001626:	60a6                	ld	ra,72(sp)
    80001628:	6406                	ld	s0,64(sp)
    8000162a:	74e2                	ld	s1,56(sp)
    8000162c:	7942                	ld	s2,48(sp)
    8000162e:	79a2                	ld	s3,40(sp)
    80001630:	7a02                	ld	s4,32(sp)
    80001632:	6ae2                	ld	s5,24(sp)
    80001634:	6b42                	ld	s6,16(sp)
    80001636:	6ba2                	ld	s7,8(sp)
    80001638:	6161                	addi	sp,sp,80
    8000163a:	8082                	ret
  return 0;
    8000163c:	4501                	li	a0,0
}
    8000163e:	8082                	ret

0000000080001640 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001640:	1141                	addi	sp,sp,-16
    80001642:	e406                	sd	ra,8(sp)
    80001644:	e022                	sd	s0,0(sp)
    80001646:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001648:	4601                	li	a2,0
    8000164a:	00000097          	auipc	ra,0x0
    8000164e:	97e080e7          	jalr	-1666(ra) # 80000fc8 <walk>
  if(pte == 0)
    80001652:	c901                	beqz	a0,80001662 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001654:	611c                	ld	a5,0(a0)
    80001656:	9bbd                	andi	a5,a5,-17
    80001658:	e11c                	sd	a5,0(a0)
}
    8000165a:	60a2                	ld	ra,8(sp)
    8000165c:	6402                	ld	s0,0(sp)
    8000165e:	0141                	addi	sp,sp,16
    80001660:	8082                	ret
    panic("uvmclear");
    80001662:	00007517          	auipc	a0,0x7
    80001666:	b6650513          	addi	a0,a0,-1178 # 800081c8 <digits+0x188>
    8000166a:	fffff097          	auipc	ra,0xfffff
    8000166e:	ed4080e7          	jalr	-300(ra) # 8000053e <panic>

0000000080001672 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001672:	c6bd                	beqz	a3,800016e0 <copyout+0x6e>
{
    80001674:	715d                	addi	sp,sp,-80
    80001676:	e486                	sd	ra,72(sp)
    80001678:	e0a2                	sd	s0,64(sp)
    8000167a:	fc26                	sd	s1,56(sp)
    8000167c:	f84a                	sd	s2,48(sp)
    8000167e:	f44e                	sd	s3,40(sp)
    80001680:	f052                	sd	s4,32(sp)
    80001682:	ec56                	sd	s5,24(sp)
    80001684:	e85a                	sd	s6,16(sp)
    80001686:	e45e                	sd	s7,8(sp)
    80001688:	e062                	sd	s8,0(sp)
    8000168a:	0880                	addi	s0,sp,80
    8000168c:	8b2a                	mv	s6,a0
    8000168e:	8c2e                	mv	s8,a1
    80001690:	8a32                	mv	s4,a2
    80001692:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001694:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001696:	6a85                	lui	s5,0x1
    80001698:	a015                	j	800016bc <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000169a:	9562                	add	a0,a0,s8
    8000169c:	0004861b          	sext.w	a2,s1
    800016a0:	85d2                	mv	a1,s4
    800016a2:	41250533          	sub	a0,a0,s2
    800016a6:	fffff097          	auipc	ra,0xfffff
    800016aa:	69a080e7          	jalr	1690(ra) # 80000d40 <memmove>

    len -= n;
    800016ae:	409989b3          	sub	s3,s3,s1
    src += n;
    800016b2:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016b4:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016b8:	02098263          	beqz	s3,800016dc <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016bc:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016c0:	85ca                	mv	a1,s2
    800016c2:	855a                	mv	a0,s6
    800016c4:	00000097          	auipc	ra,0x0
    800016c8:	9aa080e7          	jalr	-1622(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    800016cc:	cd01                	beqz	a0,800016e4 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016ce:	418904b3          	sub	s1,s2,s8
    800016d2:	94d6                	add	s1,s1,s5
    if(n > len)
    800016d4:	fc99f3e3          	bgeu	s3,s1,8000169a <copyout+0x28>
    800016d8:	84ce                	mv	s1,s3
    800016da:	b7c1                	j	8000169a <copyout+0x28>
  }
  return 0;
    800016dc:	4501                	li	a0,0
    800016de:	a021                	j	800016e6 <copyout+0x74>
    800016e0:	4501                	li	a0,0
}
    800016e2:	8082                	ret
      return -1;
    800016e4:	557d                	li	a0,-1
}
    800016e6:	60a6                	ld	ra,72(sp)
    800016e8:	6406                	ld	s0,64(sp)
    800016ea:	74e2                	ld	s1,56(sp)
    800016ec:	7942                	ld	s2,48(sp)
    800016ee:	79a2                	ld	s3,40(sp)
    800016f0:	7a02                	ld	s4,32(sp)
    800016f2:	6ae2                	ld	s5,24(sp)
    800016f4:	6b42                	ld	s6,16(sp)
    800016f6:	6ba2                	ld	s7,8(sp)
    800016f8:	6c02                	ld	s8,0(sp)
    800016fa:	6161                	addi	sp,sp,80
    800016fc:	8082                	ret

00000000800016fe <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016fe:	c6bd                	beqz	a3,8000176c <copyin+0x6e>
{
    80001700:	715d                	addi	sp,sp,-80
    80001702:	e486                	sd	ra,72(sp)
    80001704:	e0a2                	sd	s0,64(sp)
    80001706:	fc26                	sd	s1,56(sp)
    80001708:	f84a                	sd	s2,48(sp)
    8000170a:	f44e                	sd	s3,40(sp)
    8000170c:	f052                	sd	s4,32(sp)
    8000170e:	ec56                	sd	s5,24(sp)
    80001710:	e85a                	sd	s6,16(sp)
    80001712:	e45e                	sd	s7,8(sp)
    80001714:	e062                	sd	s8,0(sp)
    80001716:	0880                	addi	s0,sp,80
    80001718:	8b2a                	mv	s6,a0
    8000171a:	8a2e                	mv	s4,a1
    8000171c:	8c32                	mv	s8,a2
    8000171e:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001720:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001722:	6a85                	lui	s5,0x1
    80001724:	a015                	j	80001748 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001726:	9562                	add	a0,a0,s8
    80001728:	0004861b          	sext.w	a2,s1
    8000172c:	412505b3          	sub	a1,a0,s2
    80001730:	8552                	mv	a0,s4
    80001732:	fffff097          	auipc	ra,0xfffff
    80001736:	60e080e7          	jalr	1550(ra) # 80000d40 <memmove>

    len -= n;
    8000173a:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000173e:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001740:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001744:	02098263          	beqz	s3,80001768 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    80001748:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000174c:	85ca                	mv	a1,s2
    8000174e:	855a                	mv	a0,s6
    80001750:	00000097          	auipc	ra,0x0
    80001754:	91e080e7          	jalr	-1762(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    80001758:	cd01                	beqz	a0,80001770 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    8000175a:	418904b3          	sub	s1,s2,s8
    8000175e:	94d6                	add	s1,s1,s5
    if(n > len)
    80001760:	fc99f3e3          	bgeu	s3,s1,80001726 <copyin+0x28>
    80001764:	84ce                	mv	s1,s3
    80001766:	b7c1                	j	80001726 <copyin+0x28>
  }
  return 0;
    80001768:	4501                	li	a0,0
    8000176a:	a021                	j	80001772 <copyin+0x74>
    8000176c:	4501                	li	a0,0
}
    8000176e:	8082                	ret
      return -1;
    80001770:	557d                	li	a0,-1
}
    80001772:	60a6                	ld	ra,72(sp)
    80001774:	6406                	ld	s0,64(sp)
    80001776:	74e2                	ld	s1,56(sp)
    80001778:	7942                	ld	s2,48(sp)
    8000177a:	79a2                	ld	s3,40(sp)
    8000177c:	7a02                	ld	s4,32(sp)
    8000177e:	6ae2                	ld	s5,24(sp)
    80001780:	6b42                	ld	s6,16(sp)
    80001782:	6ba2                	ld	s7,8(sp)
    80001784:	6c02                	ld	s8,0(sp)
    80001786:	6161                	addi	sp,sp,80
    80001788:	8082                	ret

000000008000178a <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000178a:	c6c5                	beqz	a3,80001832 <copyinstr+0xa8>
{
    8000178c:	715d                	addi	sp,sp,-80
    8000178e:	e486                	sd	ra,72(sp)
    80001790:	e0a2                	sd	s0,64(sp)
    80001792:	fc26                	sd	s1,56(sp)
    80001794:	f84a                	sd	s2,48(sp)
    80001796:	f44e                	sd	s3,40(sp)
    80001798:	f052                	sd	s4,32(sp)
    8000179a:	ec56                	sd	s5,24(sp)
    8000179c:	e85a                	sd	s6,16(sp)
    8000179e:	e45e                	sd	s7,8(sp)
    800017a0:	0880                	addi	s0,sp,80
    800017a2:	8a2a                	mv	s4,a0
    800017a4:	8b2e                	mv	s6,a1
    800017a6:	8bb2                	mv	s7,a2
    800017a8:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017aa:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017ac:	6985                	lui	s3,0x1
    800017ae:	a035                	j	800017da <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017b0:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017b4:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017b6:	0017b793          	seqz	a5,a5
    800017ba:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017be:	60a6                	ld	ra,72(sp)
    800017c0:	6406                	ld	s0,64(sp)
    800017c2:	74e2                	ld	s1,56(sp)
    800017c4:	7942                	ld	s2,48(sp)
    800017c6:	79a2                	ld	s3,40(sp)
    800017c8:	7a02                	ld	s4,32(sp)
    800017ca:	6ae2                	ld	s5,24(sp)
    800017cc:	6b42                	ld	s6,16(sp)
    800017ce:	6ba2                	ld	s7,8(sp)
    800017d0:	6161                	addi	sp,sp,80
    800017d2:	8082                	ret
    srcva = va0 + PGSIZE;
    800017d4:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d8:	c8a9                	beqz	s1,8000182a <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017da:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017de:	85ca                	mv	a1,s2
    800017e0:	8552                	mv	a0,s4
    800017e2:	00000097          	auipc	ra,0x0
    800017e6:	88c080e7          	jalr	-1908(ra) # 8000106e <walkaddr>
    if(pa0 == 0)
    800017ea:	c131                	beqz	a0,8000182e <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017ec:	41790833          	sub	a6,s2,s7
    800017f0:	984e                	add	a6,a6,s3
    if(n > max)
    800017f2:	0104f363          	bgeu	s1,a6,800017f8 <copyinstr+0x6e>
    800017f6:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f8:	955e                	add	a0,a0,s7
    800017fa:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017fe:	fc080be3          	beqz	a6,800017d4 <copyinstr+0x4a>
    80001802:	985a                	add	a6,a6,s6
    80001804:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001806:	41650633          	sub	a2,a0,s6
    8000180a:	14fd                	addi	s1,s1,-1
    8000180c:	9b26                	add	s6,s6,s1
    8000180e:	00f60733          	add	a4,a2,a5
    80001812:	00074703          	lbu	a4,0(a4)
    80001816:	df49                	beqz	a4,800017b0 <copyinstr+0x26>
        *dst = *p;
    80001818:	00e78023          	sb	a4,0(a5)
      --max;
    8000181c:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001820:	0785                	addi	a5,a5,1
    while(n > 0){
    80001822:	ff0796e3          	bne	a5,a6,8000180e <copyinstr+0x84>
      dst++;
    80001826:	8b42                	mv	s6,a6
    80001828:	b775                	j	800017d4 <copyinstr+0x4a>
    8000182a:	4781                	li	a5,0
    8000182c:	b769                	j	800017b6 <copyinstr+0x2c>
      return -1;
    8000182e:	557d                	li	a0,-1
    80001830:	b779                	j	800017be <copyinstr+0x34>
  int got_null = 0;
    80001832:	4781                	li	a5,0
  if(got_null){
    80001834:	0017b793          	seqz	a5,a5
    80001838:	40f00533          	neg	a0,a5
}
    8000183c:	8082                	ret

000000008000183e <ptableprint_level>:

void
ptableprint_level(pagetable_t pagetable, int level)
{
    8000183e:	7159                	addi	sp,sp,-112
    80001840:	f486                	sd	ra,104(sp)
    80001842:	f0a2                	sd	s0,96(sp)
    80001844:	eca6                	sd	s1,88(sp)
    80001846:	e8ca                	sd	s2,80(sp)
    80001848:	e4ce                	sd	s3,72(sp)
    8000184a:	e0d2                	sd	s4,64(sp)
    8000184c:	fc56                	sd	s5,56(sp)
    8000184e:	f85a                	sd	s6,48(sp)
    80001850:	f45e                	sd	s7,40(sp)
    80001852:	f062                	sd	s8,32(sp)
    80001854:	ec66                	sd	s9,24(sp)
    80001856:	e86a                	sd	s10,16(sp)
    80001858:	e46e                	sd	s11,8(sp)
    8000185a:	1880                	addi	s0,sp,112
    8000185c:	892e                	mv	s2,a1
  for(int i=0;i<512;i++) {
    8000185e:	8aaa                	mv	s5,a0
    80001860:	4a01                	li	s4,0

    if(!(pte & PTE_V)) continue;

    for(int j=0;j<level;j++) printf(".. ");

    printf("..%d: pte %p pa %p\n", i, pte, PTE2PA(pte));
    80001862:	00007c97          	auipc	s9,0x7
    80001866:	97ec8c93          	addi	s9,s9,-1666 # 800081e0 <digits+0x1a0>

    if(level==2) continue;
    8000186a:	4c09                	li	s8,2

    uint64 child = PTE2PA(pte);
    ptableprint_level((pagetable_t)child, level+1);
    8000186c:	00158d9b          	addiw	s11,a1,1
    for(int j=0;j<level;j++) printf(".. ");
    80001870:	4d01                	li	s10,0
    80001872:	00007997          	auipc	s3,0x7
    80001876:	96698993          	addi	s3,s3,-1690 # 800081d8 <digits+0x198>
  for(int i=0;i<512;i++) {
    8000187a:	20000b93          	li	s7,512
    8000187e:	a819                	j	80001894 <ptableprint_level+0x56>
    ptableprint_level((pagetable_t)child, level+1);
    80001880:	85ee                	mv	a1,s11
    80001882:	8526                	mv	a0,s1
    80001884:	00000097          	auipc	ra,0x0
    80001888:	fba080e7          	jalr	-70(ra) # 8000183e <ptableprint_level>
  for(int i=0;i<512;i++) {
    8000188c:	2a05                	addiw	s4,s4,1
    8000188e:	0aa1                	addi	s5,s5,8
    80001890:	057a0063          	beq	s4,s7,800018d0 <ptableprint_level+0x92>
    pte_t pte = pagetable[i];
    80001894:	000abb03          	ld	s6,0(s5) # fffffffffffff000 <end+0xffffffff7ffd9000>
    if(!(pte & PTE_V)) continue;
    80001898:	001b7793          	andi	a5,s6,1
    8000189c:	dbe5                	beqz	a5,8000188c <ptableprint_level+0x4e>
    for(int j=0;j<level;j++) printf(".. ");
    8000189e:	01205b63          	blez	s2,800018b4 <ptableprint_level+0x76>
    800018a2:	84ea                	mv	s1,s10
    800018a4:	854e                	mv	a0,s3
    800018a6:	fffff097          	auipc	ra,0xfffff
    800018aa:	ce2080e7          	jalr	-798(ra) # 80000588 <printf>
    800018ae:	2485                	addiw	s1,s1,1
    800018b0:	fe991ae3          	bne	s2,s1,800018a4 <ptableprint_level+0x66>
    printf("..%d: pte %p pa %p\n", i, pte, PTE2PA(pte));
    800018b4:	00ab5493          	srli	s1,s6,0xa
    800018b8:	04b2                	slli	s1,s1,0xc
    800018ba:	86a6                	mv	a3,s1
    800018bc:	865a                	mv	a2,s6
    800018be:	85d2                	mv	a1,s4
    800018c0:	8566                	mv	a0,s9
    800018c2:	fffff097          	auipc	ra,0xfffff
    800018c6:	cc6080e7          	jalr	-826(ra) # 80000588 <printf>
    if(level==2) continue;
    800018ca:	fb891be3          	bne	s2,s8,80001880 <ptableprint_level+0x42>
    800018ce:	bf7d                	j	8000188c <ptableprint_level+0x4e>
  }
}
    800018d0:	70a6                	ld	ra,104(sp)
    800018d2:	7406                	ld	s0,96(sp)
    800018d4:	64e6                	ld	s1,88(sp)
    800018d6:	6946                	ld	s2,80(sp)
    800018d8:	69a6                	ld	s3,72(sp)
    800018da:	6a06                	ld	s4,64(sp)
    800018dc:	7ae2                	ld	s5,56(sp)
    800018de:	7b42                	ld	s6,48(sp)
    800018e0:	7ba2                	ld	s7,40(sp)
    800018e2:	7c02                	ld	s8,32(sp)
    800018e4:	6ce2                	ld	s9,24(sp)
    800018e6:	6d42                	ld	s10,16(sp)
    800018e8:	6da2                	ld	s11,8(sp)
    800018ea:	6165                	addi	sp,sp,112
    800018ec:	8082                	ret

00000000800018ee <ptableprint>:

void
ptableprint(pagetable_t pagetable)
{
    800018ee:	1101                	addi	sp,sp,-32
    800018f0:	ec06                	sd	ra,24(sp)
    800018f2:	e822                	sd	s0,16(sp)
    800018f4:	e426                	sd	s1,8(sp)
    800018f6:	1000                	addi	s0,sp,32
    800018f8:	84aa                	mv	s1,a0
  printf("page table %p\n", pagetable);
    800018fa:	85aa                	mv	a1,a0
    800018fc:	00007517          	auipc	a0,0x7
    80001900:	8fc50513          	addi	a0,a0,-1796 # 800081f8 <digits+0x1b8>
    80001904:	fffff097          	auipc	ra,0xfffff
    80001908:	c84080e7          	jalr	-892(ra) # 80000588 <printf>

  ptableprint_level(pagetable, 0);
    8000190c:	4581                	li	a1,0
    8000190e:	8526                	mv	a0,s1
    80001910:	00000097          	auipc	ra,0x0
    80001914:	f2e080e7          	jalr	-210(ra) # 8000183e <ptableprint_level>
}
    80001918:	60e2                	ld	ra,24(sp)
    8000191a:	6442                	ld	s0,16(sp)
    8000191c:	64a2                	ld	s1,8(sp)
    8000191e:	6105                	addi	sp,sp,32
    80001920:	8082                	ret

0000000080001922 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80001922:	7139                	addi	sp,sp,-64
    80001924:	fc06                	sd	ra,56(sp)
    80001926:	f822                	sd	s0,48(sp)
    80001928:	f426                	sd	s1,40(sp)
    8000192a:	f04a                	sd	s2,32(sp)
    8000192c:	ec4e                	sd	s3,24(sp)
    8000192e:	e852                	sd	s4,16(sp)
    80001930:	e456                	sd	s5,8(sp)
    80001932:	e05a                	sd	s6,0(sp)
    80001934:	0080                	addi	s0,sp,64
    80001936:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001938:	00010497          	auipc	s1,0x10
    8000193c:	d9848493          	addi	s1,s1,-616 # 800116d0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001940:	8b26                	mv	s6,s1
    80001942:	00006a97          	auipc	s5,0x6
    80001946:	6bea8a93          	addi	s5,s5,1726 # 80008000 <etext>
    8000194a:	04000937          	lui	s2,0x4000
    8000194e:	197d                	addi	s2,s2,-1
    80001950:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001952:	00015a17          	auipc	s4,0x15
    80001956:	77ea0a13          	addi	s4,s4,1918 # 800170d0 <tickslock>
    char *pa = kalloc();
    8000195a:	fffff097          	auipc	ra,0xfffff
    8000195e:	19a080e7          	jalr	410(ra) # 80000af4 <kalloc>
    80001962:	862a                	mv	a2,a0
    if(pa == 0)
    80001964:	c131                	beqz	a0,800019a8 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001966:	416485b3          	sub	a1,s1,s6
    8000196a:	858d                	srai	a1,a1,0x3
    8000196c:	000ab783          	ld	a5,0(s5)
    80001970:	02f585b3          	mul	a1,a1,a5
    80001974:	2585                	addiw	a1,a1,1
    80001976:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    8000197a:	4719                	li	a4,6
    8000197c:	6685                	lui	a3,0x1
    8000197e:	40b905b3          	sub	a1,s2,a1
    80001982:	854e                	mv	a0,s3
    80001984:	fffff097          	auipc	ra,0xfffff
    80001988:	7cc080e7          	jalr	1996(ra) # 80001150 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000198c:	16848493          	addi	s1,s1,360
    80001990:	fd4495e3          	bne	s1,s4,8000195a <proc_mapstacks+0x38>
  }
}
    80001994:	70e2                	ld	ra,56(sp)
    80001996:	7442                	ld	s0,48(sp)
    80001998:	74a2                	ld	s1,40(sp)
    8000199a:	7902                	ld	s2,32(sp)
    8000199c:	69e2                	ld	s3,24(sp)
    8000199e:	6a42                	ld	s4,16(sp)
    800019a0:	6aa2                	ld	s5,8(sp)
    800019a2:	6b02                	ld	s6,0(sp)
    800019a4:	6121                	addi	sp,sp,64
    800019a6:	8082                	ret
      panic("kalloc");
    800019a8:	00007517          	auipc	a0,0x7
    800019ac:	86050513          	addi	a0,a0,-1952 # 80008208 <digits+0x1c8>
    800019b0:	fffff097          	auipc	ra,0xfffff
    800019b4:	b8e080e7          	jalr	-1138(ra) # 8000053e <panic>

00000000800019b8 <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    800019b8:	7139                	addi	sp,sp,-64
    800019ba:	fc06                	sd	ra,56(sp)
    800019bc:	f822                	sd	s0,48(sp)
    800019be:	f426                	sd	s1,40(sp)
    800019c0:	f04a                	sd	s2,32(sp)
    800019c2:	ec4e                	sd	s3,24(sp)
    800019c4:	e852                	sd	s4,16(sp)
    800019c6:	e456                	sd	s5,8(sp)
    800019c8:	e05a                	sd	s6,0(sp)
    800019ca:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800019cc:	00007597          	auipc	a1,0x7
    800019d0:	84458593          	addi	a1,a1,-1980 # 80008210 <digits+0x1d0>
    800019d4:	00010517          	auipc	a0,0x10
    800019d8:	8cc50513          	addi	a0,a0,-1844 # 800112a0 <pid_lock>
    800019dc:	fffff097          	auipc	ra,0xfffff
    800019e0:	178080e7          	jalr	376(ra) # 80000b54 <initlock>
  initlock(&wait_lock, "wait_lock");
    800019e4:	00007597          	auipc	a1,0x7
    800019e8:	83458593          	addi	a1,a1,-1996 # 80008218 <digits+0x1d8>
    800019ec:	00010517          	auipc	a0,0x10
    800019f0:	8cc50513          	addi	a0,a0,-1844 # 800112b8 <wait_lock>
    800019f4:	fffff097          	auipc	ra,0xfffff
    800019f8:	160080e7          	jalr	352(ra) # 80000b54 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    800019fc:	00010497          	auipc	s1,0x10
    80001a00:	cd448493          	addi	s1,s1,-812 # 800116d0 <proc>
      initlock(&p->lock, "proc");
    80001a04:	00007b17          	auipc	s6,0x7
    80001a08:	824b0b13          	addi	s6,s6,-2012 # 80008228 <digits+0x1e8>
      p->kstack = KSTACK((int) (p - proc));
    80001a0c:	8aa6                	mv	s5,s1
    80001a0e:	00006a17          	auipc	s4,0x6
    80001a12:	5f2a0a13          	addi	s4,s4,1522 # 80008000 <etext>
    80001a16:	04000937          	lui	s2,0x4000
    80001a1a:	197d                	addi	s2,s2,-1
    80001a1c:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a1e:	00015997          	auipc	s3,0x15
    80001a22:	6b298993          	addi	s3,s3,1714 # 800170d0 <tickslock>
      initlock(&p->lock, "proc");
    80001a26:	85da                	mv	a1,s6
    80001a28:	8526                	mv	a0,s1
    80001a2a:	fffff097          	auipc	ra,0xfffff
    80001a2e:	12a080e7          	jalr	298(ra) # 80000b54 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001a32:	415487b3          	sub	a5,s1,s5
    80001a36:	878d                	srai	a5,a5,0x3
    80001a38:	000a3703          	ld	a4,0(s4)
    80001a3c:	02e787b3          	mul	a5,a5,a4
    80001a40:	2785                	addiw	a5,a5,1
    80001a42:	00d7979b          	slliw	a5,a5,0xd
    80001a46:	40f907b3          	sub	a5,s2,a5
    80001a4a:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a4c:	16848493          	addi	s1,s1,360
    80001a50:	fd349be3          	bne	s1,s3,80001a26 <procinit+0x6e>
  }
}
    80001a54:	70e2                	ld	ra,56(sp)
    80001a56:	7442                	ld	s0,48(sp)
    80001a58:	74a2                	ld	s1,40(sp)
    80001a5a:	7902                	ld	s2,32(sp)
    80001a5c:	69e2                	ld	s3,24(sp)
    80001a5e:	6a42                	ld	s4,16(sp)
    80001a60:	6aa2                	ld	s5,8(sp)
    80001a62:	6b02                	ld	s6,0(sp)
    80001a64:	6121                	addi	sp,sp,64
    80001a66:	8082                	ret

0000000080001a68 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001a68:	1141                	addi	sp,sp,-16
    80001a6a:	e422                	sd	s0,8(sp)
    80001a6c:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001a6e:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001a70:	2501                	sext.w	a0,a0
    80001a72:	6422                	ld	s0,8(sp)
    80001a74:	0141                	addi	sp,sp,16
    80001a76:	8082                	ret

0000000080001a78 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001a78:	1141                	addi	sp,sp,-16
    80001a7a:	e422                	sd	s0,8(sp)
    80001a7c:	0800                	addi	s0,sp,16
    80001a7e:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001a80:	2781                	sext.w	a5,a5
    80001a82:	079e                	slli	a5,a5,0x7
  return c;
}
    80001a84:	00010517          	auipc	a0,0x10
    80001a88:	84c50513          	addi	a0,a0,-1972 # 800112d0 <cpus>
    80001a8c:	953e                	add	a0,a0,a5
    80001a8e:	6422                	ld	s0,8(sp)
    80001a90:	0141                	addi	sp,sp,16
    80001a92:	8082                	ret

0000000080001a94 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001a94:	1101                	addi	sp,sp,-32
    80001a96:	ec06                	sd	ra,24(sp)
    80001a98:	e822                	sd	s0,16(sp)
    80001a9a:	e426                	sd	s1,8(sp)
    80001a9c:	1000                	addi	s0,sp,32
  push_off();
    80001a9e:	fffff097          	auipc	ra,0xfffff
    80001aa2:	0fa080e7          	jalr	250(ra) # 80000b98 <push_off>
    80001aa6:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001aa8:	2781                	sext.w	a5,a5
    80001aaa:	079e                	slli	a5,a5,0x7
    80001aac:	0000f717          	auipc	a4,0xf
    80001ab0:	7f470713          	addi	a4,a4,2036 # 800112a0 <pid_lock>
    80001ab4:	97ba                	add	a5,a5,a4
    80001ab6:	7b84                	ld	s1,48(a5)
  pop_off();
    80001ab8:	fffff097          	auipc	ra,0xfffff
    80001abc:	180080e7          	jalr	384(ra) # 80000c38 <pop_off>
  return p;
}
    80001ac0:	8526                	mv	a0,s1
    80001ac2:	60e2                	ld	ra,24(sp)
    80001ac4:	6442                	ld	s0,16(sp)
    80001ac6:	64a2                	ld	s1,8(sp)
    80001ac8:	6105                	addi	sp,sp,32
    80001aca:	8082                	ret

0000000080001acc <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001acc:	1141                	addi	sp,sp,-16
    80001ace:	e406                	sd	ra,8(sp)
    80001ad0:	e022                	sd	s0,0(sp)
    80001ad2:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001ad4:	00000097          	auipc	ra,0x0
    80001ad8:	fc0080e7          	jalr	-64(ra) # 80001a94 <myproc>
    80001adc:	fffff097          	auipc	ra,0xfffff
    80001ae0:	1bc080e7          	jalr	444(ra) # 80000c98 <release>

  if (first) {
    80001ae4:	00007797          	auipc	a5,0x7
    80001ae8:	d6c7a783          	lw	a5,-660(a5) # 80008850 <first.1682>
    80001aec:	eb89                	bnez	a5,80001afe <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001aee:	00001097          	auipc	ra,0x1
    80001af2:	c0a080e7          	jalr	-1014(ra) # 800026f8 <usertrapret>
}
    80001af6:	60a2                	ld	ra,8(sp)
    80001af8:	6402                	ld	s0,0(sp)
    80001afa:	0141                	addi	sp,sp,16
    80001afc:	8082                	ret
    first = 0;
    80001afe:	00007797          	auipc	a5,0x7
    80001b02:	d407a923          	sw	zero,-686(a5) # 80008850 <first.1682>
    fsinit(ROOTDEV);
    80001b06:	4505                	li	a0,1
    80001b08:	00002097          	auipc	ra,0x2
    80001b0c:	a14080e7          	jalr	-1516(ra) # 8000351c <fsinit>
    80001b10:	bff9                	j	80001aee <forkret+0x22>

0000000080001b12 <allocpid>:
allocpid() {
    80001b12:	1101                	addi	sp,sp,-32
    80001b14:	ec06                	sd	ra,24(sp)
    80001b16:	e822                	sd	s0,16(sp)
    80001b18:	e426                	sd	s1,8(sp)
    80001b1a:	e04a                	sd	s2,0(sp)
    80001b1c:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001b1e:	0000f917          	auipc	s2,0xf
    80001b22:	78290913          	addi	s2,s2,1922 # 800112a0 <pid_lock>
    80001b26:	854a                	mv	a0,s2
    80001b28:	fffff097          	auipc	ra,0xfffff
    80001b2c:	0bc080e7          	jalr	188(ra) # 80000be4 <acquire>
  pid = nextpid;
    80001b30:	00007797          	auipc	a5,0x7
    80001b34:	d2478793          	addi	a5,a5,-732 # 80008854 <nextpid>
    80001b38:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001b3a:	0014871b          	addiw	a4,s1,1
    80001b3e:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001b40:	854a                	mv	a0,s2
    80001b42:	fffff097          	auipc	ra,0xfffff
    80001b46:	156080e7          	jalr	342(ra) # 80000c98 <release>
}
    80001b4a:	8526                	mv	a0,s1
    80001b4c:	60e2                	ld	ra,24(sp)
    80001b4e:	6442                	ld	s0,16(sp)
    80001b50:	64a2                	ld	s1,8(sp)
    80001b52:	6902                	ld	s2,0(sp)
    80001b54:	6105                	addi	sp,sp,32
    80001b56:	8082                	ret

0000000080001b58 <proc_pagetable>:
{
    80001b58:	1101                	addi	sp,sp,-32
    80001b5a:	ec06                	sd	ra,24(sp)
    80001b5c:	e822                	sd	s0,16(sp)
    80001b5e:	e426                	sd	s1,8(sp)
    80001b60:	e04a                	sd	s2,0(sp)
    80001b62:	1000                	addi	s0,sp,32
    80001b64:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001b66:	fffff097          	auipc	ra,0xfffff
    80001b6a:	7d4080e7          	jalr	2004(ra) # 8000133a <uvmcreate>
    80001b6e:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001b70:	c121                	beqz	a0,80001bb0 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001b72:	4729                	li	a4,10
    80001b74:	00005697          	auipc	a3,0x5
    80001b78:	48c68693          	addi	a3,a3,1164 # 80007000 <_trampoline>
    80001b7c:	6605                	lui	a2,0x1
    80001b7e:	040005b7          	lui	a1,0x4000
    80001b82:	15fd                	addi	a1,a1,-1
    80001b84:	05b2                	slli	a1,a1,0xc
    80001b86:	fffff097          	auipc	ra,0xfffff
    80001b8a:	52a080e7          	jalr	1322(ra) # 800010b0 <mappages>
    80001b8e:	02054863          	bltz	a0,80001bbe <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001b92:	4719                	li	a4,6
    80001b94:	05893683          	ld	a3,88(s2)
    80001b98:	6605                	lui	a2,0x1
    80001b9a:	020005b7          	lui	a1,0x2000
    80001b9e:	15fd                	addi	a1,a1,-1
    80001ba0:	05b6                	slli	a1,a1,0xd
    80001ba2:	8526                	mv	a0,s1
    80001ba4:	fffff097          	auipc	ra,0xfffff
    80001ba8:	50c080e7          	jalr	1292(ra) # 800010b0 <mappages>
    80001bac:	02054163          	bltz	a0,80001bce <proc_pagetable+0x76>
}
    80001bb0:	8526                	mv	a0,s1
    80001bb2:	60e2                	ld	ra,24(sp)
    80001bb4:	6442                	ld	s0,16(sp)
    80001bb6:	64a2                	ld	s1,8(sp)
    80001bb8:	6902                	ld	s2,0(sp)
    80001bba:	6105                	addi	sp,sp,32
    80001bbc:	8082                	ret
    uvmfree(pagetable, 0);
    80001bbe:	4581                	li	a1,0
    80001bc0:	8526                	mv	a0,s1
    80001bc2:	00000097          	auipc	ra,0x0
    80001bc6:	974080e7          	jalr	-1676(ra) # 80001536 <uvmfree>
    return 0;
    80001bca:	4481                	li	s1,0
    80001bcc:	b7d5                	j	80001bb0 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001bce:	4681                	li	a3,0
    80001bd0:	4605                	li	a2,1
    80001bd2:	040005b7          	lui	a1,0x4000
    80001bd6:	15fd                	addi	a1,a1,-1
    80001bd8:	05b2                	slli	a1,a1,0xc
    80001bda:	8526                	mv	a0,s1
    80001bdc:	fffff097          	auipc	ra,0xfffff
    80001be0:	69a080e7          	jalr	1690(ra) # 80001276 <uvmunmap>
    uvmfree(pagetable, 0);
    80001be4:	4581                	li	a1,0
    80001be6:	8526                	mv	a0,s1
    80001be8:	00000097          	auipc	ra,0x0
    80001bec:	94e080e7          	jalr	-1714(ra) # 80001536 <uvmfree>
    return 0;
    80001bf0:	4481                	li	s1,0
    80001bf2:	bf7d                	j	80001bb0 <proc_pagetable+0x58>

0000000080001bf4 <proc_freepagetable>:
{
    80001bf4:	1101                	addi	sp,sp,-32
    80001bf6:	ec06                	sd	ra,24(sp)
    80001bf8:	e822                	sd	s0,16(sp)
    80001bfa:	e426                	sd	s1,8(sp)
    80001bfc:	e04a                	sd	s2,0(sp)
    80001bfe:	1000                	addi	s0,sp,32
    80001c00:	84aa                	mv	s1,a0
    80001c02:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c04:	4681                	li	a3,0
    80001c06:	4605                	li	a2,1
    80001c08:	040005b7          	lui	a1,0x4000
    80001c0c:	15fd                	addi	a1,a1,-1
    80001c0e:	05b2                	slli	a1,a1,0xc
    80001c10:	fffff097          	auipc	ra,0xfffff
    80001c14:	666080e7          	jalr	1638(ra) # 80001276 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001c18:	4681                	li	a3,0
    80001c1a:	4605                	li	a2,1
    80001c1c:	020005b7          	lui	a1,0x2000
    80001c20:	15fd                	addi	a1,a1,-1
    80001c22:	05b6                	slli	a1,a1,0xd
    80001c24:	8526                	mv	a0,s1
    80001c26:	fffff097          	auipc	ra,0xfffff
    80001c2a:	650080e7          	jalr	1616(ra) # 80001276 <uvmunmap>
  uvmfree(pagetable, sz);
    80001c2e:	85ca                	mv	a1,s2
    80001c30:	8526                	mv	a0,s1
    80001c32:	00000097          	auipc	ra,0x0
    80001c36:	904080e7          	jalr	-1788(ra) # 80001536 <uvmfree>
}
    80001c3a:	60e2                	ld	ra,24(sp)
    80001c3c:	6442                	ld	s0,16(sp)
    80001c3e:	64a2                	ld	s1,8(sp)
    80001c40:	6902                	ld	s2,0(sp)
    80001c42:	6105                	addi	sp,sp,32
    80001c44:	8082                	ret

0000000080001c46 <freeproc>:
{
    80001c46:	1101                	addi	sp,sp,-32
    80001c48:	ec06                	sd	ra,24(sp)
    80001c4a:	e822                	sd	s0,16(sp)
    80001c4c:	e426                	sd	s1,8(sp)
    80001c4e:	1000                	addi	s0,sp,32
    80001c50:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001c52:	6d28                	ld	a0,88(a0)
    80001c54:	c509                	beqz	a0,80001c5e <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001c56:	fffff097          	auipc	ra,0xfffff
    80001c5a:	da2080e7          	jalr	-606(ra) # 800009f8 <kfree>
  p->trapframe = 0;
    80001c5e:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001c62:	68a8                	ld	a0,80(s1)
    80001c64:	c511                	beqz	a0,80001c70 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001c66:	64ac                	ld	a1,72(s1)
    80001c68:	00000097          	auipc	ra,0x0
    80001c6c:	f8c080e7          	jalr	-116(ra) # 80001bf4 <proc_freepagetable>
  p->pagetable = 0;
    80001c70:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001c74:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001c78:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001c7c:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001c80:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001c84:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001c88:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001c8c:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001c90:	0004ac23          	sw	zero,24(s1)
}
    80001c94:	60e2                	ld	ra,24(sp)
    80001c96:	6442                	ld	s0,16(sp)
    80001c98:	64a2                	ld	s1,8(sp)
    80001c9a:	6105                	addi	sp,sp,32
    80001c9c:	8082                	ret

0000000080001c9e <allocproc>:
{
    80001c9e:	1101                	addi	sp,sp,-32
    80001ca0:	ec06                	sd	ra,24(sp)
    80001ca2:	e822                	sd	s0,16(sp)
    80001ca4:	e426                	sd	s1,8(sp)
    80001ca6:	e04a                	sd	s2,0(sp)
    80001ca8:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001caa:	00010497          	auipc	s1,0x10
    80001cae:	a2648493          	addi	s1,s1,-1498 # 800116d0 <proc>
    80001cb2:	00015917          	auipc	s2,0x15
    80001cb6:	41e90913          	addi	s2,s2,1054 # 800170d0 <tickslock>
    acquire(&p->lock);
    80001cba:	8526                	mv	a0,s1
    80001cbc:	fffff097          	auipc	ra,0xfffff
    80001cc0:	f28080e7          	jalr	-216(ra) # 80000be4 <acquire>
    if(p->state == UNUSED) {
    80001cc4:	4c9c                	lw	a5,24(s1)
    80001cc6:	cf81                	beqz	a5,80001cde <allocproc+0x40>
      release(&p->lock);
    80001cc8:	8526                	mv	a0,s1
    80001cca:	fffff097          	auipc	ra,0xfffff
    80001cce:	fce080e7          	jalr	-50(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001cd2:	16848493          	addi	s1,s1,360
    80001cd6:	ff2492e3          	bne	s1,s2,80001cba <allocproc+0x1c>
  return 0;
    80001cda:	4481                	li	s1,0
    80001cdc:	a889                	j	80001d2e <allocproc+0x90>
  p->pid = allocpid();
    80001cde:	00000097          	auipc	ra,0x0
    80001ce2:	e34080e7          	jalr	-460(ra) # 80001b12 <allocpid>
    80001ce6:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001ce8:	4785                	li	a5,1
    80001cea:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001cec:	fffff097          	auipc	ra,0xfffff
    80001cf0:	e08080e7          	jalr	-504(ra) # 80000af4 <kalloc>
    80001cf4:	892a                	mv	s2,a0
    80001cf6:	eca8                	sd	a0,88(s1)
    80001cf8:	c131                	beqz	a0,80001d3c <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001cfa:	8526                	mv	a0,s1
    80001cfc:	00000097          	auipc	ra,0x0
    80001d00:	e5c080e7          	jalr	-420(ra) # 80001b58 <proc_pagetable>
    80001d04:	892a                	mv	s2,a0
    80001d06:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001d08:	c531                	beqz	a0,80001d54 <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001d0a:	07000613          	li	a2,112
    80001d0e:	4581                	li	a1,0
    80001d10:	06048513          	addi	a0,s1,96
    80001d14:	fffff097          	auipc	ra,0xfffff
    80001d18:	fcc080e7          	jalr	-52(ra) # 80000ce0 <memset>
  p->context.ra = (uint64)forkret;
    80001d1c:	00000797          	auipc	a5,0x0
    80001d20:	db078793          	addi	a5,a5,-592 # 80001acc <forkret>
    80001d24:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001d26:	60bc                	ld	a5,64(s1)
    80001d28:	6705                	lui	a4,0x1
    80001d2a:	97ba                	add	a5,a5,a4
    80001d2c:	f4bc                	sd	a5,104(s1)
}
    80001d2e:	8526                	mv	a0,s1
    80001d30:	60e2                	ld	ra,24(sp)
    80001d32:	6442                	ld	s0,16(sp)
    80001d34:	64a2                	ld	s1,8(sp)
    80001d36:	6902                	ld	s2,0(sp)
    80001d38:	6105                	addi	sp,sp,32
    80001d3a:	8082                	ret
    freeproc(p);
    80001d3c:	8526                	mv	a0,s1
    80001d3e:	00000097          	auipc	ra,0x0
    80001d42:	f08080e7          	jalr	-248(ra) # 80001c46 <freeproc>
    release(&p->lock);
    80001d46:	8526                	mv	a0,s1
    80001d48:	fffff097          	auipc	ra,0xfffff
    80001d4c:	f50080e7          	jalr	-176(ra) # 80000c98 <release>
    return 0;
    80001d50:	84ca                	mv	s1,s2
    80001d52:	bff1                	j	80001d2e <allocproc+0x90>
    freeproc(p);
    80001d54:	8526                	mv	a0,s1
    80001d56:	00000097          	auipc	ra,0x0
    80001d5a:	ef0080e7          	jalr	-272(ra) # 80001c46 <freeproc>
    release(&p->lock);
    80001d5e:	8526                	mv	a0,s1
    80001d60:	fffff097          	auipc	ra,0xfffff
    80001d64:	f38080e7          	jalr	-200(ra) # 80000c98 <release>
    return 0;
    80001d68:	84ca                	mv	s1,s2
    80001d6a:	b7d1                	j	80001d2e <allocproc+0x90>

0000000080001d6c <userinit>:
{
    80001d6c:	1101                	addi	sp,sp,-32
    80001d6e:	ec06                	sd	ra,24(sp)
    80001d70:	e822                	sd	s0,16(sp)
    80001d72:	e426                	sd	s1,8(sp)
    80001d74:	1000                	addi	s0,sp,32
  p = allocproc();
    80001d76:	00000097          	auipc	ra,0x0
    80001d7a:	f28080e7          	jalr	-216(ra) # 80001c9e <allocproc>
    80001d7e:	84aa                	mv	s1,a0
  initproc = p;
    80001d80:	00007797          	auipc	a5,0x7
    80001d84:	2aa7b423          	sd	a0,680(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001d88:	03400613          	li	a2,52
    80001d8c:	00007597          	auipc	a1,0x7
    80001d90:	ad458593          	addi	a1,a1,-1324 # 80008860 <initcode>
    80001d94:	6928                	ld	a0,80(a0)
    80001d96:	fffff097          	auipc	ra,0xfffff
    80001d9a:	5d2080e7          	jalr	1490(ra) # 80001368 <uvminit>
  p->sz = PGSIZE;
    80001d9e:	6785                	lui	a5,0x1
    80001da0:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001da2:	6cb8                	ld	a4,88(s1)
    80001da4:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001da8:	6cb8                	ld	a4,88(s1)
    80001daa:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001dac:	4641                	li	a2,16
    80001dae:	00006597          	auipc	a1,0x6
    80001db2:	48258593          	addi	a1,a1,1154 # 80008230 <digits+0x1f0>
    80001db6:	15848513          	addi	a0,s1,344
    80001dba:	fffff097          	auipc	ra,0xfffff
    80001dbe:	078080e7          	jalr	120(ra) # 80000e32 <safestrcpy>
  p->cwd = namei("/");
    80001dc2:	00006517          	auipc	a0,0x6
    80001dc6:	47e50513          	addi	a0,a0,1150 # 80008240 <digits+0x200>
    80001dca:	00002097          	auipc	ra,0x2
    80001dce:	180080e7          	jalr	384(ra) # 80003f4a <namei>
    80001dd2:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001dd6:	478d                	li	a5,3
    80001dd8:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001dda:	8526                	mv	a0,s1
    80001ddc:	fffff097          	auipc	ra,0xfffff
    80001de0:	ebc080e7          	jalr	-324(ra) # 80000c98 <release>
}
    80001de4:	60e2                	ld	ra,24(sp)
    80001de6:	6442                	ld	s0,16(sp)
    80001de8:	64a2                	ld	s1,8(sp)
    80001dea:	6105                	addi	sp,sp,32
    80001dec:	8082                	ret

0000000080001dee <growproc>:
{
    80001dee:	1101                	addi	sp,sp,-32
    80001df0:	ec06                	sd	ra,24(sp)
    80001df2:	e822                	sd	s0,16(sp)
    80001df4:	e426                	sd	s1,8(sp)
    80001df6:	e04a                	sd	s2,0(sp)
    80001df8:	1000                	addi	s0,sp,32
    80001dfa:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001dfc:	00000097          	auipc	ra,0x0
    80001e00:	c98080e7          	jalr	-872(ra) # 80001a94 <myproc>
    80001e04:	892a                	mv	s2,a0
  sz = p->sz;
    80001e06:	652c                	ld	a1,72(a0)
    80001e08:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001e0c:	00904f63          	bgtz	s1,80001e2a <growproc+0x3c>
  } else if(n < 0){
    80001e10:	0204cc63          	bltz	s1,80001e48 <growproc+0x5a>
  p->sz = sz;
    80001e14:	1602                	slli	a2,a2,0x20
    80001e16:	9201                	srli	a2,a2,0x20
    80001e18:	04c93423          	sd	a2,72(s2)
  return 0;
    80001e1c:	4501                	li	a0,0
}
    80001e1e:	60e2                	ld	ra,24(sp)
    80001e20:	6442                	ld	s0,16(sp)
    80001e22:	64a2                	ld	s1,8(sp)
    80001e24:	6902                	ld	s2,0(sp)
    80001e26:	6105                	addi	sp,sp,32
    80001e28:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001e2a:	9e25                	addw	a2,a2,s1
    80001e2c:	1602                	slli	a2,a2,0x20
    80001e2e:	9201                	srli	a2,a2,0x20
    80001e30:	1582                	slli	a1,a1,0x20
    80001e32:	9181                	srli	a1,a1,0x20
    80001e34:	6928                	ld	a0,80(a0)
    80001e36:	fffff097          	auipc	ra,0xfffff
    80001e3a:	5ec080e7          	jalr	1516(ra) # 80001422 <uvmalloc>
    80001e3e:	0005061b          	sext.w	a2,a0
    80001e42:	fa69                	bnez	a2,80001e14 <growproc+0x26>
      return -1;
    80001e44:	557d                	li	a0,-1
    80001e46:	bfe1                	j	80001e1e <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001e48:	9e25                	addw	a2,a2,s1
    80001e4a:	1602                	slli	a2,a2,0x20
    80001e4c:	9201                	srli	a2,a2,0x20
    80001e4e:	1582                	slli	a1,a1,0x20
    80001e50:	9181                	srli	a1,a1,0x20
    80001e52:	6928                	ld	a0,80(a0)
    80001e54:	fffff097          	auipc	ra,0xfffff
    80001e58:	586080e7          	jalr	1414(ra) # 800013da <uvmdealloc>
    80001e5c:	0005061b          	sext.w	a2,a0
    80001e60:	bf55                	j	80001e14 <growproc+0x26>

0000000080001e62 <fork>:
{
    80001e62:	7179                	addi	sp,sp,-48
    80001e64:	f406                	sd	ra,40(sp)
    80001e66:	f022                	sd	s0,32(sp)
    80001e68:	ec26                	sd	s1,24(sp)
    80001e6a:	e84a                	sd	s2,16(sp)
    80001e6c:	e44e                	sd	s3,8(sp)
    80001e6e:	e052                	sd	s4,0(sp)
    80001e70:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001e72:	00000097          	auipc	ra,0x0
    80001e76:	c22080e7          	jalr	-990(ra) # 80001a94 <myproc>
    80001e7a:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001e7c:	00000097          	auipc	ra,0x0
    80001e80:	e22080e7          	jalr	-478(ra) # 80001c9e <allocproc>
    80001e84:	10050b63          	beqz	a0,80001f9a <fork+0x138>
    80001e88:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001e8a:	04893603          	ld	a2,72(s2)
    80001e8e:	692c                	ld	a1,80(a0)
    80001e90:	05093503          	ld	a0,80(s2)
    80001e94:	fffff097          	auipc	ra,0xfffff
    80001e98:	6da080e7          	jalr	1754(ra) # 8000156e <uvmcopy>
    80001e9c:	04054663          	bltz	a0,80001ee8 <fork+0x86>
  np->sz = p->sz;
    80001ea0:	04893783          	ld	a5,72(s2)
    80001ea4:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001ea8:	05893683          	ld	a3,88(s2)
    80001eac:	87b6                	mv	a5,a3
    80001eae:	0589b703          	ld	a4,88(s3)
    80001eb2:	12068693          	addi	a3,a3,288
    80001eb6:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001eba:	6788                	ld	a0,8(a5)
    80001ebc:	6b8c                	ld	a1,16(a5)
    80001ebe:	6f90                	ld	a2,24(a5)
    80001ec0:	01073023          	sd	a6,0(a4)
    80001ec4:	e708                	sd	a0,8(a4)
    80001ec6:	eb0c                	sd	a1,16(a4)
    80001ec8:	ef10                	sd	a2,24(a4)
    80001eca:	02078793          	addi	a5,a5,32
    80001ece:	02070713          	addi	a4,a4,32
    80001ed2:	fed792e3          	bne	a5,a3,80001eb6 <fork+0x54>
  np->trapframe->a0 = 0;
    80001ed6:	0589b783          	ld	a5,88(s3)
    80001eda:	0607b823          	sd	zero,112(a5)
    80001ede:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001ee2:	15000a13          	li	s4,336
    80001ee6:	a03d                	j	80001f14 <fork+0xb2>
    freeproc(np);
    80001ee8:	854e                	mv	a0,s3
    80001eea:	00000097          	auipc	ra,0x0
    80001eee:	d5c080e7          	jalr	-676(ra) # 80001c46 <freeproc>
    release(&np->lock);
    80001ef2:	854e                	mv	a0,s3
    80001ef4:	fffff097          	auipc	ra,0xfffff
    80001ef8:	da4080e7          	jalr	-604(ra) # 80000c98 <release>
    return -1;
    80001efc:	5a7d                	li	s4,-1
    80001efe:	a069                	j	80001f88 <fork+0x126>
      np->ofile[i] = filedup(p->ofile[i]);
    80001f00:	00002097          	auipc	ra,0x2
    80001f04:	6e0080e7          	jalr	1760(ra) # 800045e0 <filedup>
    80001f08:	009987b3          	add	a5,s3,s1
    80001f0c:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001f0e:	04a1                	addi	s1,s1,8
    80001f10:	01448763          	beq	s1,s4,80001f1e <fork+0xbc>
    if(p->ofile[i])
    80001f14:	009907b3          	add	a5,s2,s1
    80001f18:	6388                	ld	a0,0(a5)
    80001f1a:	f17d                	bnez	a0,80001f00 <fork+0x9e>
    80001f1c:	bfcd                	j	80001f0e <fork+0xac>
  np->cwd = idup(p->cwd);
    80001f1e:	15093503          	ld	a0,336(s2)
    80001f22:	00002097          	auipc	ra,0x2
    80001f26:	834080e7          	jalr	-1996(ra) # 80003756 <idup>
    80001f2a:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001f2e:	4641                	li	a2,16
    80001f30:	15890593          	addi	a1,s2,344
    80001f34:	15898513          	addi	a0,s3,344
    80001f38:	fffff097          	auipc	ra,0xfffff
    80001f3c:	efa080e7          	jalr	-262(ra) # 80000e32 <safestrcpy>
  pid = np->pid;
    80001f40:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80001f44:	854e                	mv	a0,s3
    80001f46:	fffff097          	auipc	ra,0xfffff
    80001f4a:	d52080e7          	jalr	-686(ra) # 80000c98 <release>
  acquire(&wait_lock);
    80001f4e:	0000f497          	auipc	s1,0xf
    80001f52:	36a48493          	addi	s1,s1,874 # 800112b8 <wait_lock>
    80001f56:	8526                	mv	a0,s1
    80001f58:	fffff097          	auipc	ra,0xfffff
    80001f5c:	c8c080e7          	jalr	-884(ra) # 80000be4 <acquire>
  np->parent = p;
    80001f60:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    80001f64:	8526                	mv	a0,s1
    80001f66:	fffff097          	auipc	ra,0xfffff
    80001f6a:	d32080e7          	jalr	-718(ra) # 80000c98 <release>
  acquire(&np->lock);
    80001f6e:	854e                	mv	a0,s3
    80001f70:	fffff097          	auipc	ra,0xfffff
    80001f74:	c74080e7          	jalr	-908(ra) # 80000be4 <acquire>
  np->state = RUNNABLE;
    80001f78:	478d                	li	a5,3
    80001f7a:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001f7e:	854e                	mv	a0,s3
    80001f80:	fffff097          	auipc	ra,0xfffff
    80001f84:	d18080e7          	jalr	-744(ra) # 80000c98 <release>
}
    80001f88:	8552                	mv	a0,s4
    80001f8a:	70a2                	ld	ra,40(sp)
    80001f8c:	7402                	ld	s0,32(sp)
    80001f8e:	64e2                	ld	s1,24(sp)
    80001f90:	6942                	ld	s2,16(sp)
    80001f92:	69a2                	ld	s3,8(sp)
    80001f94:	6a02                	ld	s4,0(sp)
    80001f96:	6145                	addi	sp,sp,48
    80001f98:	8082                	ret
    return -1;
    80001f9a:	5a7d                	li	s4,-1
    80001f9c:	b7f5                	j	80001f88 <fork+0x126>

0000000080001f9e <scheduler>:
{
    80001f9e:	7139                	addi	sp,sp,-64
    80001fa0:	fc06                	sd	ra,56(sp)
    80001fa2:	f822                	sd	s0,48(sp)
    80001fa4:	f426                	sd	s1,40(sp)
    80001fa6:	f04a                	sd	s2,32(sp)
    80001fa8:	ec4e                	sd	s3,24(sp)
    80001faa:	e852                	sd	s4,16(sp)
    80001fac:	e456                	sd	s5,8(sp)
    80001fae:	e05a                	sd	s6,0(sp)
    80001fb0:	0080                	addi	s0,sp,64
    80001fb2:	8792                	mv	a5,tp
  int id = r_tp();
    80001fb4:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001fb6:	00779a93          	slli	s5,a5,0x7
    80001fba:	0000f717          	auipc	a4,0xf
    80001fbe:	2e670713          	addi	a4,a4,742 # 800112a0 <pid_lock>
    80001fc2:	9756                	add	a4,a4,s5
    80001fc4:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001fc8:	0000f717          	auipc	a4,0xf
    80001fcc:	31070713          	addi	a4,a4,784 # 800112d8 <cpus+0x8>
    80001fd0:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001fd2:	498d                	li	s3,3
        p->state = RUNNING;
    80001fd4:	4b11                	li	s6,4
        c->proc = p;
    80001fd6:	079e                	slli	a5,a5,0x7
    80001fd8:	0000fa17          	auipc	s4,0xf
    80001fdc:	2c8a0a13          	addi	s4,s4,712 # 800112a0 <pid_lock>
    80001fe0:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fe2:	00015917          	auipc	s2,0x15
    80001fe6:	0ee90913          	addi	s2,s2,238 # 800170d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fea:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001fee:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001ff2:	10079073          	csrw	sstatus,a5
    80001ff6:	0000f497          	auipc	s1,0xf
    80001ffa:	6da48493          	addi	s1,s1,1754 # 800116d0 <proc>
    80001ffe:	a03d                	j	8000202c <scheduler+0x8e>
        p->state = RUNNING;
    80002000:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80002004:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80002008:	06048593          	addi	a1,s1,96
    8000200c:	8556                	mv	a0,s5
    8000200e:	00000097          	auipc	ra,0x0
    80002012:	640080e7          	jalr	1600(ra) # 8000264e <swtch>
        c->proc = 0;
    80002016:	020a3823          	sd	zero,48(s4)
      release(&p->lock);
    8000201a:	8526                	mv	a0,s1
    8000201c:	fffff097          	auipc	ra,0xfffff
    80002020:	c7c080e7          	jalr	-900(ra) # 80000c98 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80002024:	16848493          	addi	s1,s1,360
    80002028:	fd2481e3          	beq	s1,s2,80001fea <scheduler+0x4c>
      acquire(&p->lock);
    8000202c:	8526                	mv	a0,s1
    8000202e:	fffff097          	auipc	ra,0xfffff
    80002032:	bb6080e7          	jalr	-1098(ra) # 80000be4 <acquire>
      if(p->state == RUNNABLE) {
    80002036:	4c9c                	lw	a5,24(s1)
    80002038:	ff3791e3          	bne	a5,s3,8000201a <scheduler+0x7c>
    8000203c:	b7d1                	j	80002000 <scheduler+0x62>

000000008000203e <sched>:
{
    8000203e:	7179                	addi	sp,sp,-48
    80002040:	f406                	sd	ra,40(sp)
    80002042:	f022                	sd	s0,32(sp)
    80002044:	ec26                	sd	s1,24(sp)
    80002046:	e84a                	sd	s2,16(sp)
    80002048:	e44e                	sd	s3,8(sp)
    8000204a:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000204c:	00000097          	auipc	ra,0x0
    80002050:	a48080e7          	jalr	-1464(ra) # 80001a94 <myproc>
    80002054:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002056:	fffff097          	auipc	ra,0xfffff
    8000205a:	b14080e7          	jalr	-1260(ra) # 80000b6a <holding>
    8000205e:	c93d                	beqz	a0,800020d4 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002060:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002062:	2781                	sext.w	a5,a5
    80002064:	079e                	slli	a5,a5,0x7
    80002066:	0000f717          	auipc	a4,0xf
    8000206a:	23a70713          	addi	a4,a4,570 # 800112a0 <pid_lock>
    8000206e:	97ba                	add	a5,a5,a4
    80002070:	0a87a703          	lw	a4,168(a5)
    80002074:	4785                	li	a5,1
    80002076:	06f71763          	bne	a4,a5,800020e4 <sched+0xa6>
  if(p->state == RUNNING)
    8000207a:	4c98                	lw	a4,24(s1)
    8000207c:	4791                	li	a5,4
    8000207e:	06f70b63          	beq	a4,a5,800020f4 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002082:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002086:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002088:	efb5                	bnez	a5,80002104 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000208a:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000208c:	0000f917          	auipc	s2,0xf
    80002090:	21490913          	addi	s2,s2,532 # 800112a0 <pid_lock>
    80002094:	2781                	sext.w	a5,a5
    80002096:	079e                	slli	a5,a5,0x7
    80002098:	97ca                	add	a5,a5,s2
    8000209a:	0ac7a983          	lw	s3,172(a5)
    8000209e:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800020a0:	2781                	sext.w	a5,a5
    800020a2:	079e                	slli	a5,a5,0x7
    800020a4:	0000f597          	auipc	a1,0xf
    800020a8:	23458593          	addi	a1,a1,564 # 800112d8 <cpus+0x8>
    800020ac:	95be                	add	a1,a1,a5
    800020ae:	06048513          	addi	a0,s1,96
    800020b2:	00000097          	auipc	ra,0x0
    800020b6:	59c080e7          	jalr	1436(ra) # 8000264e <swtch>
    800020ba:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800020bc:	2781                	sext.w	a5,a5
    800020be:	079e                	slli	a5,a5,0x7
    800020c0:	97ca                	add	a5,a5,s2
    800020c2:	0b37a623          	sw	s3,172(a5)
}
    800020c6:	70a2                	ld	ra,40(sp)
    800020c8:	7402                	ld	s0,32(sp)
    800020ca:	64e2                	ld	s1,24(sp)
    800020cc:	6942                	ld	s2,16(sp)
    800020ce:	69a2                	ld	s3,8(sp)
    800020d0:	6145                	addi	sp,sp,48
    800020d2:	8082                	ret
    panic("sched p->lock");
    800020d4:	00006517          	auipc	a0,0x6
    800020d8:	17450513          	addi	a0,a0,372 # 80008248 <digits+0x208>
    800020dc:	ffffe097          	auipc	ra,0xffffe
    800020e0:	462080e7          	jalr	1122(ra) # 8000053e <panic>
    panic("sched locks");
    800020e4:	00006517          	auipc	a0,0x6
    800020e8:	17450513          	addi	a0,a0,372 # 80008258 <digits+0x218>
    800020ec:	ffffe097          	auipc	ra,0xffffe
    800020f0:	452080e7          	jalr	1106(ra) # 8000053e <panic>
    panic("sched running");
    800020f4:	00006517          	auipc	a0,0x6
    800020f8:	17450513          	addi	a0,a0,372 # 80008268 <digits+0x228>
    800020fc:	ffffe097          	auipc	ra,0xffffe
    80002100:	442080e7          	jalr	1090(ra) # 8000053e <panic>
    panic("sched interruptible");
    80002104:	00006517          	auipc	a0,0x6
    80002108:	17450513          	addi	a0,a0,372 # 80008278 <digits+0x238>
    8000210c:	ffffe097          	auipc	ra,0xffffe
    80002110:	432080e7          	jalr	1074(ra) # 8000053e <panic>

0000000080002114 <yield>:
{
    80002114:	1101                	addi	sp,sp,-32
    80002116:	ec06                	sd	ra,24(sp)
    80002118:	e822                	sd	s0,16(sp)
    8000211a:	e426                	sd	s1,8(sp)
    8000211c:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000211e:	00000097          	auipc	ra,0x0
    80002122:	976080e7          	jalr	-1674(ra) # 80001a94 <myproc>
    80002126:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002128:	fffff097          	auipc	ra,0xfffff
    8000212c:	abc080e7          	jalr	-1348(ra) # 80000be4 <acquire>
  p->state = RUNNABLE;
    80002130:	478d                	li	a5,3
    80002132:	cc9c                	sw	a5,24(s1)
  sched();
    80002134:	00000097          	auipc	ra,0x0
    80002138:	f0a080e7          	jalr	-246(ra) # 8000203e <sched>
  release(&p->lock);
    8000213c:	8526                	mv	a0,s1
    8000213e:	fffff097          	auipc	ra,0xfffff
    80002142:	b5a080e7          	jalr	-1190(ra) # 80000c98 <release>
}
    80002146:	60e2                	ld	ra,24(sp)
    80002148:	6442                	ld	s0,16(sp)
    8000214a:	64a2                	ld	s1,8(sp)
    8000214c:	6105                	addi	sp,sp,32
    8000214e:	8082                	ret

0000000080002150 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002150:	7179                	addi	sp,sp,-48
    80002152:	f406                	sd	ra,40(sp)
    80002154:	f022                	sd	s0,32(sp)
    80002156:	ec26                	sd	s1,24(sp)
    80002158:	e84a                	sd	s2,16(sp)
    8000215a:	e44e                	sd	s3,8(sp)
    8000215c:	1800                	addi	s0,sp,48
    8000215e:	89aa                	mv	s3,a0
    80002160:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002162:	00000097          	auipc	ra,0x0
    80002166:	932080e7          	jalr	-1742(ra) # 80001a94 <myproc>
    8000216a:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    8000216c:	fffff097          	auipc	ra,0xfffff
    80002170:	a78080e7          	jalr	-1416(ra) # 80000be4 <acquire>
  release(lk);
    80002174:	854a                	mv	a0,s2
    80002176:	fffff097          	auipc	ra,0xfffff
    8000217a:	b22080e7          	jalr	-1246(ra) # 80000c98 <release>

  // Go to sleep.
  p->chan = chan;
    8000217e:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002182:	4789                	li	a5,2
    80002184:	cc9c                	sw	a5,24(s1)

  sched();
    80002186:	00000097          	auipc	ra,0x0
    8000218a:	eb8080e7          	jalr	-328(ra) # 8000203e <sched>

  // Tidy up.
  p->chan = 0;
    8000218e:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002192:	8526                	mv	a0,s1
    80002194:	fffff097          	auipc	ra,0xfffff
    80002198:	b04080e7          	jalr	-1276(ra) # 80000c98 <release>
  acquire(lk);
    8000219c:	854a                	mv	a0,s2
    8000219e:	fffff097          	auipc	ra,0xfffff
    800021a2:	a46080e7          	jalr	-1466(ra) # 80000be4 <acquire>
}
    800021a6:	70a2                	ld	ra,40(sp)
    800021a8:	7402                	ld	s0,32(sp)
    800021aa:	64e2                	ld	s1,24(sp)
    800021ac:	6942                	ld	s2,16(sp)
    800021ae:	69a2                	ld	s3,8(sp)
    800021b0:	6145                	addi	sp,sp,48
    800021b2:	8082                	ret

00000000800021b4 <wait>:
{
    800021b4:	715d                	addi	sp,sp,-80
    800021b6:	e486                	sd	ra,72(sp)
    800021b8:	e0a2                	sd	s0,64(sp)
    800021ba:	fc26                	sd	s1,56(sp)
    800021bc:	f84a                	sd	s2,48(sp)
    800021be:	f44e                	sd	s3,40(sp)
    800021c0:	f052                	sd	s4,32(sp)
    800021c2:	ec56                	sd	s5,24(sp)
    800021c4:	e85a                	sd	s6,16(sp)
    800021c6:	e45e                	sd	s7,8(sp)
    800021c8:	e062                	sd	s8,0(sp)
    800021ca:	0880                	addi	s0,sp,80
    800021cc:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800021ce:	00000097          	auipc	ra,0x0
    800021d2:	8c6080e7          	jalr	-1850(ra) # 80001a94 <myproc>
    800021d6:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800021d8:	0000f517          	auipc	a0,0xf
    800021dc:	0e050513          	addi	a0,a0,224 # 800112b8 <wait_lock>
    800021e0:	fffff097          	auipc	ra,0xfffff
    800021e4:	a04080e7          	jalr	-1532(ra) # 80000be4 <acquire>
    havekids = 0;
    800021e8:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800021ea:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    800021ec:	00015997          	auipc	s3,0x15
    800021f0:	ee498993          	addi	s3,s3,-284 # 800170d0 <tickslock>
        havekids = 1;
    800021f4:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800021f6:	0000fc17          	auipc	s8,0xf
    800021fa:	0c2c0c13          	addi	s8,s8,194 # 800112b8 <wait_lock>
    havekids = 0;
    800021fe:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002200:	0000f497          	auipc	s1,0xf
    80002204:	4d048493          	addi	s1,s1,1232 # 800116d0 <proc>
    80002208:	a0bd                	j	80002276 <wait+0xc2>
          pid = np->pid;
    8000220a:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    8000220e:	000b0e63          	beqz	s6,8000222a <wait+0x76>
    80002212:	4691                	li	a3,4
    80002214:	02c48613          	addi	a2,s1,44
    80002218:	85da                	mv	a1,s6
    8000221a:	05093503          	ld	a0,80(s2)
    8000221e:	fffff097          	auipc	ra,0xfffff
    80002222:	454080e7          	jalr	1108(ra) # 80001672 <copyout>
    80002226:	02054563          	bltz	a0,80002250 <wait+0x9c>
          freeproc(np);
    8000222a:	8526                	mv	a0,s1
    8000222c:	00000097          	auipc	ra,0x0
    80002230:	a1a080e7          	jalr	-1510(ra) # 80001c46 <freeproc>
          release(&np->lock);
    80002234:	8526                	mv	a0,s1
    80002236:	fffff097          	auipc	ra,0xfffff
    8000223a:	a62080e7          	jalr	-1438(ra) # 80000c98 <release>
          release(&wait_lock);
    8000223e:	0000f517          	auipc	a0,0xf
    80002242:	07a50513          	addi	a0,a0,122 # 800112b8 <wait_lock>
    80002246:	fffff097          	auipc	ra,0xfffff
    8000224a:	a52080e7          	jalr	-1454(ra) # 80000c98 <release>
          return pid;
    8000224e:	a09d                	j	800022b4 <wait+0x100>
            release(&np->lock);
    80002250:	8526                	mv	a0,s1
    80002252:	fffff097          	auipc	ra,0xfffff
    80002256:	a46080e7          	jalr	-1466(ra) # 80000c98 <release>
            release(&wait_lock);
    8000225a:	0000f517          	auipc	a0,0xf
    8000225e:	05e50513          	addi	a0,a0,94 # 800112b8 <wait_lock>
    80002262:	fffff097          	auipc	ra,0xfffff
    80002266:	a36080e7          	jalr	-1482(ra) # 80000c98 <release>
            return -1;
    8000226a:	59fd                	li	s3,-1
    8000226c:	a0a1                	j	800022b4 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    8000226e:	16848493          	addi	s1,s1,360
    80002272:	03348463          	beq	s1,s3,8000229a <wait+0xe6>
      if(np->parent == p){
    80002276:	7c9c                	ld	a5,56(s1)
    80002278:	ff279be3          	bne	a5,s2,8000226e <wait+0xba>
        acquire(&np->lock);
    8000227c:	8526                	mv	a0,s1
    8000227e:	fffff097          	auipc	ra,0xfffff
    80002282:	966080e7          	jalr	-1690(ra) # 80000be4 <acquire>
        if(np->state == ZOMBIE){
    80002286:	4c9c                	lw	a5,24(s1)
    80002288:	f94781e3          	beq	a5,s4,8000220a <wait+0x56>
        release(&np->lock);
    8000228c:	8526                	mv	a0,s1
    8000228e:	fffff097          	auipc	ra,0xfffff
    80002292:	a0a080e7          	jalr	-1526(ra) # 80000c98 <release>
        havekids = 1;
    80002296:	8756                	mv	a4,s5
    80002298:	bfd9                	j	8000226e <wait+0xba>
    if(!havekids || p->killed){
    8000229a:	c701                	beqz	a4,800022a2 <wait+0xee>
    8000229c:	02892783          	lw	a5,40(s2)
    800022a0:	c79d                	beqz	a5,800022ce <wait+0x11a>
      release(&wait_lock);
    800022a2:	0000f517          	auipc	a0,0xf
    800022a6:	01650513          	addi	a0,a0,22 # 800112b8 <wait_lock>
    800022aa:	fffff097          	auipc	ra,0xfffff
    800022ae:	9ee080e7          	jalr	-1554(ra) # 80000c98 <release>
      return -1;
    800022b2:	59fd                	li	s3,-1
}
    800022b4:	854e                	mv	a0,s3
    800022b6:	60a6                	ld	ra,72(sp)
    800022b8:	6406                	ld	s0,64(sp)
    800022ba:	74e2                	ld	s1,56(sp)
    800022bc:	7942                	ld	s2,48(sp)
    800022be:	79a2                	ld	s3,40(sp)
    800022c0:	7a02                	ld	s4,32(sp)
    800022c2:	6ae2                	ld	s5,24(sp)
    800022c4:	6b42                	ld	s6,16(sp)
    800022c6:	6ba2                	ld	s7,8(sp)
    800022c8:	6c02                	ld	s8,0(sp)
    800022ca:	6161                	addi	sp,sp,80
    800022cc:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800022ce:	85e2                	mv	a1,s8
    800022d0:	854a                	mv	a0,s2
    800022d2:	00000097          	auipc	ra,0x0
    800022d6:	e7e080e7          	jalr	-386(ra) # 80002150 <sleep>
    havekids = 0;
    800022da:	b715                	j	800021fe <wait+0x4a>

00000000800022dc <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800022dc:	7139                	addi	sp,sp,-64
    800022de:	fc06                	sd	ra,56(sp)
    800022e0:	f822                	sd	s0,48(sp)
    800022e2:	f426                	sd	s1,40(sp)
    800022e4:	f04a                	sd	s2,32(sp)
    800022e6:	ec4e                	sd	s3,24(sp)
    800022e8:	e852                	sd	s4,16(sp)
    800022ea:	e456                	sd	s5,8(sp)
    800022ec:	0080                	addi	s0,sp,64
    800022ee:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800022f0:	0000f497          	auipc	s1,0xf
    800022f4:	3e048493          	addi	s1,s1,992 # 800116d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    800022f8:	4989                	li	s3,2
        p->state = RUNNABLE;
    800022fa:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    800022fc:	00015917          	auipc	s2,0x15
    80002300:	dd490913          	addi	s2,s2,-556 # 800170d0 <tickslock>
    80002304:	a821                	j	8000231c <wakeup+0x40>
        p->state = RUNNABLE;
    80002306:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    8000230a:	8526                	mv	a0,s1
    8000230c:	fffff097          	auipc	ra,0xfffff
    80002310:	98c080e7          	jalr	-1652(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002314:	16848493          	addi	s1,s1,360
    80002318:	03248463          	beq	s1,s2,80002340 <wakeup+0x64>
    if(p != myproc()){
    8000231c:	fffff097          	auipc	ra,0xfffff
    80002320:	778080e7          	jalr	1912(ra) # 80001a94 <myproc>
    80002324:	fea488e3          	beq	s1,a0,80002314 <wakeup+0x38>
      acquire(&p->lock);
    80002328:	8526                	mv	a0,s1
    8000232a:	fffff097          	auipc	ra,0xfffff
    8000232e:	8ba080e7          	jalr	-1862(ra) # 80000be4 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002332:	4c9c                	lw	a5,24(s1)
    80002334:	fd379be3          	bne	a5,s3,8000230a <wakeup+0x2e>
    80002338:	709c                	ld	a5,32(s1)
    8000233a:	fd4798e3          	bne	a5,s4,8000230a <wakeup+0x2e>
    8000233e:	b7e1                	j	80002306 <wakeup+0x2a>
    }
  }
}
    80002340:	70e2                	ld	ra,56(sp)
    80002342:	7442                	ld	s0,48(sp)
    80002344:	74a2                	ld	s1,40(sp)
    80002346:	7902                	ld	s2,32(sp)
    80002348:	69e2                	ld	s3,24(sp)
    8000234a:	6a42                	ld	s4,16(sp)
    8000234c:	6aa2                	ld	s5,8(sp)
    8000234e:	6121                	addi	sp,sp,64
    80002350:	8082                	ret

0000000080002352 <reparent>:
{
    80002352:	7179                	addi	sp,sp,-48
    80002354:	f406                	sd	ra,40(sp)
    80002356:	f022                	sd	s0,32(sp)
    80002358:	ec26                	sd	s1,24(sp)
    8000235a:	e84a                	sd	s2,16(sp)
    8000235c:	e44e                	sd	s3,8(sp)
    8000235e:	e052                	sd	s4,0(sp)
    80002360:	1800                	addi	s0,sp,48
    80002362:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002364:	0000f497          	auipc	s1,0xf
    80002368:	36c48493          	addi	s1,s1,876 # 800116d0 <proc>
      pp->parent = initproc;
    8000236c:	00007a17          	auipc	s4,0x7
    80002370:	cbca0a13          	addi	s4,s4,-836 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002374:	00015997          	auipc	s3,0x15
    80002378:	d5c98993          	addi	s3,s3,-676 # 800170d0 <tickslock>
    8000237c:	a029                	j	80002386 <reparent+0x34>
    8000237e:	16848493          	addi	s1,s1,360
    80002382:	01348d63          	beq	s1,s3,8000239c <reparent+0x4a>
    if(pp->parent == p){
    80002386:	7c9c                	ld	a5,56(s1)
    80002388:	ff279be3          	bne	a5,s2,8000237e <reparent+0x2c>
      pp->parent = initproc;
    8000238c:	000a3503          	ld	a0,0(s4)
    80002390:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002392:	00000097          	auipc	ra,0x0
    80002396:	f4a080e7          	jalr	-182(ra) # 800022dc <wakeup>
    8000239a:	b7d5                	j	8000237e <reparent+0x2c>
}
    8000239c:	70a2                	ld	ra,40(sp)
    8000239e:	7402                	ld	s0,32(sp)
    800023a0:	64e2                	ld	s1,24(sp)
    800023a2:	6942                	ld	s2,16(sp)
    800023a4:	69a2                	ld	s3,8(sp)
    800023a6:	6a02                	ld	s4,0(sp)
    800023a8:	6145                	addi	sp,sp,48
    800023aa:	8082                	ret

00000000800023ac <exit>:
{
    800023ac:	7179                	addi	sp,sp,-48
    800023ae:	f406                	sd	ra,40(sp)
    800023b0:	f022                	sd	s0,32(sp)
    800023b2:	ec26                	sd	s1,24(sp)
    800023b4:	e84a                	sd	s2,16(sp)
    800023b6:	e44e                	sd	s3,8(sp)
    800023b8:	e052                	sd	s4,0(sp)
    800023ba:	1800                	addi	s0,sp,48
    800023bc:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800023be:	fffff097          	auipc	ra,0xfffff
    800023c2:	6d6080e7          	jalr	1750(ra) # 80001a94 <myproc>
    800023c6:	89aa                	mv	s3,a0
  if(p == initproc)
    800023c8:	00007797          	auipc	a5,0x7
    800023cc:	c607b783          	ld	a5,-928(a5) # 80009028 <initproc>
    800023d0:	0d050493          	addi	s1,a0,208
    800023d4:	15050913          	addi	s2,a0,336
    800023d8:	02a79363          	bne	a5,a0,800023fe <exit+0x52>
    panic("init exiting");
    800023dc:	00006517          	auipc	a0,0x6
    800023e0:	eb450513          	addi	a0,a0,-332 # 80008290 <digits+0x250>
    800023e4:	ffffe097          	auipc	ra,0xffffe
    800023e8:	15a080e7          	jalr	346(ra) # 8000053e <panic>
      fileclose(f);
    800023ec:	00002097          	auipc	ra,0x2
    800023f0:	246080e7          	jalr	582(ra) # 80004632 <fileclose>
      p->ofile[fd] = 0;
    800023f4:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800023f8:	04a1                	addi	s1,s1,8
    800023fa:	01248563          	beq	s1,s2,80002404 <exit+0x58>
    if(p->ofile[fd]){
    800023fe:	6088                	ld	a0,0(s1)
    80002400:	f575                	bnez	a0,800023ec <exit+0x40>
    80002402:	bfdd                	j	800023f8 <exit+0x4c>
  begin_op();
    80002404:	00002097          	auipc	ra,0x2
    80002408:	d62080e7          	jalr	-670(ra) # 80004166 <begin_op>
  iput(p->cwd);
    8000240c:	1509b503          	ld	a0,336(s3)
    80002410:	00001097          	auipc	ra,0x1
    80002414:	53e080e7          	jalr	1342(ra) # 8000394e <iput>
  end_op();
    80002418:	00002097          	auipc	ra,0x2
    8000241c:	dce080e7          	jalr	-562(ra) # 800041e6 <end_op>
  p->cwd = 0;
    80002420:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002424:	0000f497          	auipc	s1,0xf
    80002428:	e9448493          	addi	s1,s1,-364 # 800112b8 <wait_lock>
    8000242c:	8526                	mv	a0,s1
    8000242e:	ffffe097          	auipc	ra,0xffffe
    80002432:	7b6080e7          	jalr	1974(ra) # 80000be4 <acquire>
  reparent(p);
    80002436:	854e                	mv	a0,s3
    80002438:	00000097          	auipc	ra,0x0
    8000243c:	f1a080e7          	jalr	-230(ra) # 80002352 <reparent>
  wakeup(p->parent);
    80002440:	0389b503          	ld	a0,56(s3)
    80002444:	00000097          	auipc	ra,0x0
    80002448:	e98080e7          	jalr	-360(ra) # 800022dc <wakeup>
  acquire(&p->lock);
    8000244c:	854e                	mv	a0,s3
    8000244e:	ffffe097          	auipc	ra,0xffffe
    80002452:	796080e7          	jalr	1942(ra) # 80000be4 <acquire>
  p->xstate = status;
    80002456:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    8000245a:	4795                	li	a5,5
    8000245c:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002460:	8526                	mv	a0,s1
    80002462:	fffff097          	auipc	ra,0xfffff
    80002466:	836080e7          	jalr	-1994(ra) # 80000c98 <release>
  sched();
    8000246a:	00000097          	auipc	ra,0x0
    8000246e:	bd4080e7          	jalr	-1068(ra) # 8000203e <sched>
  panic("zombie exit");
    80002472:	00006517          	auipc	a0,0x6
    80002476:	e2e50513          	addi	a0,a0,-466 # 800082a0 <digits+0x260>
    8000247a:	ffffe097          	auipc	ra,0xffffe
    8000247e:	0c4080e7          	jalr	196(ra) # 8000053e <panic>

0000000080002482 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002482:	7179                	addi	sp,sp,-48
    80002484:	f406                	sd	ra,40(sp)
    80002486:	f022                	sd	s0,32(sp)
    80002488:	ec26                	sd	s1,24(sp)
    8000248a:	e84a                	sd	s2,16(sp)
    8000248c:	e44e                	sd	s3,8(sp)
    8000248e:	1800                	addi	s0,sp,48
    80002490:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002492:	0000f497          	auipc	s1,0xf
    80002496:	23e48493          	addi	s1,s1,574 # 800116d0 <proc>
    8000249a:	00015997          	auipc	s3,0x15
    8000249e:	c3698993          	addi	s3,s3,-970 # 800170d0 <tickslock>
    acquire(&p->lock);
    800024a2:	8526                	mv	a0,s1
    800024a4:	ffffe097          	auipc	ra,0xffffe
    800024a8:	740080e7          	jalr	1856(ra) # 80000be4 <acquire>
    if(p->pid == pid){
    800024ac:	589c                	lw	a5,48(s1)
    800024ae:	01278d63          	beq	a5,s2,800024c8 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800024b2:	8526                	mv	a0,s1
    800024b4:	ffffe097          	auipc	ra,0xffffe
    800024b8:	7e4080e7          	jalr	2020(ra) # 80000c98 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800024bc:	16848493          	addi	s1,s1,360
    800024c0:	ff3491e3          	bne	s1,s3,800024a2 <kill+0x20>
  }
  return -1;
    800024c4:	557d                	li	a0,-1
    800024c6:	a829                	j	800024e0 <kill+0x5e>
      p->killed = 1;
    800024c8:	4785                	li	a5,1
    800024ca:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800024cc:	4c98                	lw	a4,24(s1)
    800024ce:	4789                	li	a5,2
    800024d0:	00f70f63          	beq	a4,a5,800024ee <kill+0x6c>
      release(&p->lock);
    800024d4:	8526                	mv	a0,s1
    800024d6:	ffffe097          	auipc	ra,0xffffe
    800024da:	7c2080e7          	jalr	1986(ra) # 80000c98 <release>
      return 0;
    800024de:	4501                	li	a0,0
}
    800024e0:	70a2                	ld	ra,40(sp)
    800024e2:	7402                	ld	s0,32(sp)
    800024e4:	64e2                	ld	s1,24(sp)
    800024e6:	6942                	ld	s2,16(sp)
    800024e8:	69a2                	ld	s3,8(sp)
    800024ea:	6145                	addi	sp,sp,48
    800024ec:	8082                	ret
        p->state = RUNNABLE;
    800024ee:	478d                	li	a5,3
    800024f0:	cc9c                	sw	a5,24(s1)
    800024f2:	b7cd                	j	800024d4 <kill+0x52>

00000000800024f4 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800024f4:	7179                	addi	sp,sp,-48
    800024f6:	f406                	sd	ra,40(sp)
    800024f8:	f022                	sd	s0,32(sp)
    800024fa:	ec26                	sd	s1,24(sp)
    800024fc:	e84a                	sd	s2,16(sp)
    800024fe:	e44e                	sd	s3,8(sp)
    80002500:	e052                	sd	s4,0(sp)
    80002502:	1800                	addi	s0,sp,48
    80002504:	84aa                	mv	s1,a0
    80002506:	892e                	mv	s2,a1
    80002508:	89b2                	mv	s3,a2
    8000250a:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000250c:	fffff097          	auipc	ra,0xfffff
    80002510:	588080e7          	jalr	1416(ra) # 80001a94 <myproc>
  if(user_dst){
    80002514:	c08d                	beqz	s1,80002536 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002516:	86d2                	mv	a3,s4
    80002518:	864e                	mv	a2,s3
    8000251a:	85ca                	mv	a1,s2
    8000251c:	6928                	ld	a0,80(a0)
    8000251e:	fffff097          	auipc	ra,0xfffff
    80002522:	154080e7          	jalr	340(ra) # 80001672 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002526:	70a2                	ld	ra,40(sp)
    80002528:	7402                	ld	s0,32(sp)
    8000252a:	64e2                	ld	s1,24(sp)
    8000252c:	6942                	ld	s2,16(sp)
    8000252e:	69a2                	ld	s3,8(sp)
    80002530:	6a02                	ld	s4,0(sp)
    80002532:	6145                	addi	sp,sp,48
    80002534:	8082                	ret
    memmove((char *)dst, src, len);
    80002536:	000a061b          	sext.w	a2,s4
    8000253a:	85ce                	mv	a1,s3
    8000253c:	854a                	mv	a0,s2
    8000253e:	fffff097          	auipc	ra,0xfffff
    80002542:	802080e7          	jalr	-2046(ra) # 80000d40 <memmove>
    return 0;
    80002546:	8526                	mv	a0,s1
    80002548:	bff9                	j	80002526 <either_copyout+0x32>

000000008000254a <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000254a:	7179                	addi	sp,sp,-48
    8000254c:	f406                	sd	ra,40(sp)
    8000254e:	f022                	sd	s0,32(sp)
    80002550:	ec26                	sd	s1,24(sp)
    80002552:	e84a                	sd	s2,16(sp)
    80002554:	e44e                	sd	s3,8(sp)
    80002556:	e052                	sd	s4,0(sp)
    80002558:	1800                	addi	s0,sp,48
    8000255a:	892a                	mv	s2,a0
    8000255c:	84ae                	mv	s1,a1
    8000255e:	89b2                	mv	s3,a2
    80002560:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002562:	fffff097          	auipc	ra,0xfffff
    80002566:	532080e7          	jalr	1330(ra) # 80001a94 <myproc>
  if(user_src){
    8000256a:	c08d                	beqz	s1,8000258c <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    8000256c:	86d2                	mv	a3,s4
    8000256e:	864e                	mv	a2,s3
    80002570:	85ca                	mv	a1,s2
    80002572:	6928                	ld	a0,80(a0)
    80002574:	fffff097          	auipc	ra,0xfffff
    80002578:	18a080e7          	jalr	394(ra) # 800016fe <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    8000257c:	70a2                	ld	ra,40(sp)
    8000257e:	7402                	ld	s0,32(sp)
    80002580:	64e2                	ld	s1,24(sp)
    80002582:	6942                	ld	s2,16(sp)
    80002584:	69a2                	ld	s3,8(sp)
    80002586:	6a02                	ld	s4,0(sp)
    80002588:	6145                	addi	sp,sp,48
    8000258a:	8082                	ret
    memmove(dst, (char*)src, len);
    8000258c:	000a061b          	sext.w	a2,s4
    80002590:	85ce                	mv	a1,s3
    80002592:	854a                	mv	a0,s2
    80002594:	ffffe097          	auipc	ra,0xffffe
    80002598:	7ac080e7          	jalr	1964(ra) # 80000d40 <memmove>
    return 0;
    8000259c:	8526                	mv	a0,s1
    8000259e:	bff9                	j	8000257c <either_copyin+0x32>

00000000800025a0 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800025a0:	715d                	addi	sp,sp,-80
    800025a2:	e486                	sd	ra,72(sp)
    800025a4:	e0a2                	sd	s0,64(sp)
    800025a6:	fc26                	sd	s1,56(sp)
    800025a8:	f84a                	sd	s2,48(sp)
    800025aa:	f44e                	sd	s3,40(sp)
    800025ac:	f052                	sd	s4,32(sp)
    800025ae:	ec56                	sd	s5,24(sp)
    800025b0:	e85a                	sd	s6,16(sp)
    800025b2:	e45e                	sd	s7,8(sp)
    800025b4:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800025b6:	00006517          	auipc	a0,0x6
    800025ba:	b1250513          	addi	a0,a0,-1262 # 800080c8 <digits+0x88>
    800025be:	ffffe097          	auipc	ra,0xffffe
    800025c2:	fca080e7          	jalr	-54(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025c6:	0000f497          	auipc	s1,0xf
    800025ca:	26248493          	addi	s1,s1,610 # 80011828 <proc+0x158>
    800025ce:	00015917          	auipc	s2,0x15
    800025d2:	c5a90913          	addi	s2,s2,-934 # 80017228 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025d6:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800025d8:	00006997          	auipc	s3,0x6
    800025dc:	cd898993          	addi	s3,s3,-808 # 800082b0 <digits+0x270>
    printf("%d %s %s", p->pid, state, p->name);
    800025e0:	00006a97          	auipc	s5,0x6
    800025e4:	cd8a8a93          	addi	s5,s5,-808 # 800082b8 <digits+0x278>
    printf("\n");
    800025e8:	00006a17          	auipc	s4,0x6
    800025ec:	ae0a0a13          	addi	s4,s4,-1312 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025f0:	00006b97          	auipc	s7,0x6
    800025f4:	d00b8b93          	addi	s7,s7,-768 # 800082f0 <states.1719>
    800025f8:	a00d                	j	8000261a <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800025fa:	ed86a583          	lw	a1,-296(a3)
    800025fe:	8556                	mv	a0,s5
    80002600:	ffffe097          	auipc	ra,0xffffe
    80002604:	f88080e7          	jalr	-120(ra) # 80000588 <printf>
    printf("\n");
    80002608:	8552                	mv	a0,s4
    8000260a:	ffffe097          	auipc	ra,0xffffe
    8000260e:	f7e080e7          	jalr	-130(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002612:	16848493          	addi	s1,s1,360
    80002616:	03248163          	beq	s1,s2,80002638 <procdump+0x98>
    if(p->state == UNUSED)
    8000261a:	86a6                	mv	a3,s1
    8000261c:	ec04a783          	lw	a5,-320(s1)
    80002620:	dbed                	beqz	a5,80002612 <procdump+0x72>
      state = "???";
    80002622:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002624:	fcfb6be3          	bltu	s6,a5,800025fa <procdump+0x5a>
    80002628:	1782                	slli	a5,a5,0x20
    8000262a:	9381                	srli	a5,a5,0x20
    8000262c:	078e                	slli	a5,a5,0x3
    8000262e:	97de                	add	a5,a5,s7
    80002630:	6390                	ld	a2,0(a5)
    80002632:	f661                	bnez	a2,800025fa <procdump+0x5a>
      state = "???";
    80002634:	864e                	mv	a2,s3
    80002636:	b7d1                	j	800025fa <procdump+0x5a>
  }
}
    80002638:	60a6                	ld	ra,72(sp)
    8000263a:	6406                	ld	s0,64(sp)
    8000263c:	74e2                	ld	s1,56(sp)
    8000263e:	7942                	ld	s2,48(sp)
    80002640:	79a2                	ld	s3,40(sp)
    80002642:	7a02                	ld	s4,32(sp)
    80002644:	6ae2                	ld	s5,24(sp)
    80002646:	6b42                	ld	s6,16(sp)
    80002648:	6ba2                	ld	s7,8(sp)
    8000264a:	6161                	addi	sp,sp,80
    8000264c:	8082                	ret

000000008000264e <swtch>:
    8000264e:	00153023          	sd	ra,0(a0)
    80002652:	00253423          	sd	sp,8(a0)
    80002656:	e900                	sd	s0,16(a0)
    80002658:	ed04                	sd	s1,24(a0)
    8000265a:	03253023          	sd	s2,32(a0)
    8000265e:	03353423          	sd	s3,40(a0)
    80002662:	03453823          	sd	s4,48(a0)
    80002666:	03553c23          	sd	s5,56(a0)
    8000266a:	05653023          	sd	s6,64(a0)
    8000266e:	05753423          	sd	s7,72(a0)
    80002672:	05853823          	sd	s8,80(a0)
    80002676:	05953c23          	sd	s9,88(a0)
    8000267a:	07a53023          	sd	s10,96(a0)
    8000267e:	07b53423          	sd	s11,104(a0)
    80002682:	0005b083          	ld	ra,0(a1)
    80002686:	0085b103          	ld	sp,8(a1)
    8000268a:	6980                	ld	s0,16(a1)
    8000268c:	6d84                	ld	s1,24(a1)
    8000268e:	0205b903          	ld	s2,32(a1)
    80002692:	0285b983          	ld	s3,40(a1)
    80002696:	0305ba03          	ld	s4,48(a1)
    8000269a:	0385ba83          	ld	s5,56(a1)
    8000269e:	0405bb03          	ld	s6,64(a1)
    800026a2:	0485bb83          	ld	s7,72(a1)
    800026a6:	0505bc03          	ld	s8,80(a1)
    800026aa:	0585bc83          	ld	s9,88(a1)
    800026ae:	0605bd03          	ld	s10,96(a1)
    800026b2:	0685bd83          	ld	s11,104(a1)
    800026b6:	8082                	ret

00000000800026b8 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800026b8:	1141                	addi	sp,sp,-16
    800026ba:	e406                	sd	ra,8(sp)
    800026bc:	e022                	sd	s0,0(sp)
    800026be:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800026c0:	00006597          	auipc	a1,0x6
    800026c4:	c6058593          	addi	a1,a1,-928 # 80008320 <states.1719+0x30>
    800026c8:	00015517          	auipc	a0,0x15
    800026cc:	a0850513          	addi	a0,a0,-1528 # 800170d0 <tickslock>
    800026d0:	ffffe097          	auipc	ra,0xffffe
    800026d4:	484080e7          	jalr	1156(ra) # 80000b54 <initlock>
}
    800026d8:	60a2                	ld	ra,8(sp)
    800026da:	6402                	ld	s0,0(sp)
    800026dc:	0141                	addi	sp,sp,16
    800026de:	8082                	ret

00000000800026e0 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800026e0:	1141                	addi	sp,sp,-16
    800026e2:	e422                	sd	s0,8(sp)
    800026e4:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026e6:	00003797          	auipc	a5,0x3
    800026ea:	57a78793          	addi	a5,a5,1402 # 80005c60 <kernelvec>
    800026ee:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800026f2:	6422                	ld	s0,8(sp)
    800026f4:	0141                	addi	sp,sp,16
    800026f6:	8082                	ret

00000000800026f8 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800026f8:	1141                	addi	sp,sp,-16
    800026fa:	e406                	sd	ra,8(sp)
    800026fc:	e022                	sd	s0,0(sp)
    800026fe:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002700:	fffff097          	auipc	ra,0xfffff
    80002704:	394080e7          	jalr	916(ra) # 80001a94 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002708:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000270c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000270e:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002712:	00005617          	auipc	a2,0x5
    80002716:	8ee60613          	addi	a2,a2,-1810 # 80007000 <_trampoline>
    8000271a:	00005697          	auipc	a3,0x5
    8000271e:	8e668693          	addi	a3,a3,-1818 # 80007000 <_trampoline>
    80002722:	8e91                	sub	a3,a3,a2
    80002724:	040007b7          	lui	a5,0x4000
    80002728:	17fd                	addi	a5,a5,-1
    8000272a:	07b2                	slli	a5,a5,0xc
    8000272c:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000272e:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002732:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002734:	180026f3          	csrr	a3,satp
    80002738:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000273a:	6d38                	ld	a4,88(a0)
    8000273c:	6134                	ld	a3,64(a0)
    8000273e:	6585                	lui	a1,0x1
    80002740:	96ae                	add	a3,a3,a1
    80002742:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002744:	6d38                	ld	a4,88(a0)
    80002746:	00000697          	auipc	a3,0x0
    8000274a:	13868693          	addi	a3,a3,312 # 8000287e <usertrap>
    8000274e:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002750:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002752:	8692                	mv	a3,tp
    80002754:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002756:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000275a:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000275e:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002762:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002766:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002768:	6f18                	ld	a4,24(a4)
    8000276a:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    8000276e:	692c                	ld	a1,80(a0)
    80002770:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002772:	00005717          	auipc	a4,0x5
    80002776:	91e70713          	addi	a4,a4,-1762 # 80007090 <userret>
    8000277a:	8f11                	sub	a4,a4,a2
    8000277c:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    8000277e:	577d                	li	a4,-1
    80002780:	177e                	slli	a4,a4,0x3f
    80002782:	8dd9                	or	a1,a1,a4
    80002784:	02000537          	lui	a0,0x2000
    80002788:	157d                	addi	a0,a0,-1
    8000278a:	0536                	slli	a0,a0,0xd
    8000278c:	9782                	jalr	a5
}
    8000278e:	60a2                	ld	ra,8(sp)
    80002790:	6402                	ld	s0,0(sp)
    80002792:	0141                	addi	sp,sp,16
    80002794:	8082                	ret

0000000080002796 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002796:	1101                	addi	sp,sp,-32
    80002798:	ec06                	sd	ra,24(sp)
    8000279a:	e822                	sd	s0,16(sp)
    8000279c:	e426                	sd	s1,8(sp)
    8000279e:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800027a0:	00015497          	auipc	s1,0x15
    800027a4:	93048493          	addi	s1,s1,-1744 # 800170d0 <tickslock>
    800027a8:	8526                	mv	a0,s1
    800027aa:	ffffe097          	auipc	ra,0xffffe
    800027ae:	43a080e7          	jalr	1082(ra) # 80000be4 <acquire>
  ticks++;
    800027b2:	00007517          	auipc	a0,0x7
    800027b6:	87e50513          	addi	a0,a0,-1922 # 80009030 <ticks>
    800027ba:	411c                	lw	a5,0(a0)
    800027bc:	2785                	addiw	a5,a5,1
    800027be:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800027c0:	00000097          	auipc	ra,0x0
    800027c4:	b1c080e7          	jalr	-1252(ra) # 800022dc <wakeup>
  release(&tickslock);
    800027c8:	8526                	mv	a0,s1
    800027ca:	ffffe097          	auipc	ra,0xffffe
    800027ce:	4ce080e7          	jalr	1230(ra) # 80000c98 <release>
}
    800027d2:	60e2                	ld	ra,24(sp)
    800027d4:	6442                	ld	s0,16(sp)
    800027d6:	64a2                	ld	s1,8(sp)
    800027d8:	6105                	addi	sp,sp,32
    800027da:	8082                	ret

00000000800027dc <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800027dc:	1101                	addi	sp,sp,-32
    800027de:	ec06                	sd	ra,24(sp)
    800027e0:	e822                	sd	s0,16(sp)
    800027e2:	e426                	sd	s1,8(sp)
    800027e4:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800027e6:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800027ea:	00074d63          	bltz	a4,80002804 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800027ee:	57fd                	li	a5,-1
    800027f0:	17fe                	slli	a5,a5,0x3f
    800027f2:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800027f4:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800027f6:	06f70363          	beq	a4,a5,8000285c <devintr+0x80>
  }
}
    800027fa:	60e2                	ld	ra,24(sp)
    800027fc:	6442                	ld	s0,16(sp)
    800027fe:	64a2                	ld	s1,8(sp)
    80002800:	6105                	addi	sp,sp,32
    80002802:	8082                	ret
     (scause & 0xff) == 9){
    80002804:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002808:	46a5                	li	a3,9
    8000280a:	fed792e3          	bne	a5,a3,800027ee <devintr+0x12>
    int irq = plic_claim();
    8000280e:	00003097          	auipc	ra,0x3
    80002812:	55a080e7          	jalr	1370(ra) # 80005d68 <plic_claim>
    80002816:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002818:	47a9                	li	a5,10
    8000281a:	02f50763          	beq	a0,a5,80002848 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    8000281e:	4785                	li	a5,1
    80002820:	02f50963          	beq	a0,a5,80002852 <devintr+0x76>
    return 1;
    80002824:	4505                	li	a0,1
    } else if(irq){
    80002826:	d8f1                	beqz	s1,800027fa <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002828:	85a6                	mv	a1,s1
    8000282a:	00006517          	auipc	a0,0x6
    8000282e:	afe50513          	addi	a0,a0,-1282 # 80008328 <states.1719+0x38>
    80002832:	ffffe097          	auipc	ra,0xffffe
    80002836:	d56080e7          	jalr	-682(ra) # 80000588 <printf>
      plic_complete(irq);
    8000283a:	8526                	mv	a0,s1
    8000283c:	00003097          	auipc	ra,0x3
    80002840:	550080e7          	jalr	1360(ra) # 80005d8c <plic_complete>
    return 1;
    80002844:	4505                	li	a0,1
    80002846:	bf55                	j	800027fa <devintr+0x1e>
      uartintr();
    80002848:	ffffe097          	auipc	ra,0xffffe
    8000284c:	160080e7          	jalr	352(ra) # 800009a8 <uartintr>
    80002850:	b7ed                	j	8000283a <devintr+0x5e>
      virtio_disk_intr();
    80002852:	00004097          	auipc	ra,0x4
    80002856:	a1a080e7          	jalr	-1510(ra) # 8000626c <virtio_disk_intr>
    8000285a:	b7c5                	j	8000283a <devintr+0x5e>
    if(cpuid() == 0){
    8000285c:	fffff097          	auipc	ra,0xfffff
    80002860:	20c080e7          	jalr	524(ra) # 80001a68 <cpuid>
    80002864:	c901                	beqz	a0,80002874 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002866:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    8000286a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    8000286c:	14479073          	csrw	sip,a5
    return 2;
    80002870:	4509                	li	a0,2
    80002872:	b761                	j	800027fa <devintr+0x1e>
      clockintr();
    80002874:	00000097          	auipc	ra,0x0
    80002878:	f22080e7          	jalr	-222(ra) # 80002796 <clockintr>
    8000287c:	b7ed                	j	80002866 <devintr+0x8a>

000000008000287e <usertrap>:
{
    8000287e:	1101                	addi	sp,sp,-32
    80002880:	ec06                	sd	ra,24(sp)
    80002882:	e822                	sd	s0,16(sp)
    80002884:	e426                	sd	s1,8(sp)
    80002886:	e04a                	sd	s2,0(sp)
    80002888:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000288a:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    8000288e:	1007f793          	andi	a5,a5,256
    80002892:	e3ad                	bnez	a5,800028f4 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002894:	00003797          	auipc	a5,0x3
    80002898:	3cc78793          	addi	a5,a5,972 # 80005c60 <kernelvec>
    8000289c:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800028a0:	fffff097          	auipc	ra,0xfffff
    800028a4:	1f4080e7          	jalr	500(ra) # 80001a94 <myproc>
    800028a8:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800028aa:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028ac:	14102773          	csrr	a4,sepc
    800028b0:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028b2:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800028b6:	47a1                	li	a5,8
    800028b8:	04f71c63          	bne	a4,a5,80002910 <usertrap+0x92>
    if(p->killed)
    800028bc:	551c                	lw	a5,40(a0)
    800028be:	e3b9                	bnez	a5,80002904 <usertrap+0x86>
    p->trapframe->epc += 4;
    800028c0:	6cb8                	ld	a4,88(s1)
    800028c2:	6f1c                	ld	a5,24(a4)
    800028c4:	0791                	addi	a5,a5,4
    800028c6:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028c8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800028cc:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028d0:	10079073          	csrw	sstatus,a5
    syscall();
    800028d4:	00000097          	auipc	ra,0x0
    800028d8:	2e0080e7          	jalr	736(ra) # 80002bb4 <syscall>
  if(p->killed)
    800028dc:	549c                	lw	a5,40(s1)
    800028de:	ebc1                	bnez	a5,8000296e <usertrap+0xf0>
  usertrapret();
    800028e0:	00000097          	auipc	ra,0x0
    800028e4:	e18080e7          	jalr	-488(ra) # 800026f8 <usertrapret>
}
    800028e8:	60e2                	ld	ra,24(sp)
    800028ea:	6442                	ld	s0,16(sp)
    800028ec:	64a2                	ld	s1,8(sp)
    800028ee:	6902                	ld	s2,0(sp)
    800028f0:	6105                	addi	sp,sp,32
    800028f2:	8082                	ret
    panic("usertrap: not from user mode");
    800028f4:	00006517          	auipc	a0,0x6
    800028f8:	a5450513          	addi	a0,a0,-1452 # 80008348 <states.1719+0x58>
    800028fc:	ffffe097          	auipc	ra,0xffffe
    80002900:	c42080e7          	jalr	-958(ra) # 8000053e <panic>
      exit(-1);
    80002904:	557d                	li	a0,-1
    80002906:	00000097          	auipc	ra,0x0
    8000290a:	aa6080e7          	jalr	-1370(ra) # 800023ac <exit>
    8000290e:	bf4d                	j	800028c0 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002910:	00000097          	auipc	ra,0x0
    80002914:	ecc080e7          	jalr	-308(ra) # 800027dc <devintr>
    80002918:	892a                	mv	s2,a0
    8000291a:	c501                	beqz	a0,80002922 <usertrap+0xa4>
  if(p->killed)
    8000291c:	549c                	lw	a5,40(s1)
    8000291e:	c3a1                	beqz	a5,8000295e <usertrap+0xe0>
    80002920:	a815                	j	80002954 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002922:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002926:	5890                	lw	a2,48(s1)
    80002928:	00006517          	auipc	a0,0x6
    8000292c:	a4050513          	addi	a0,a0,-1472 # 80008368 <states.1719+0x78>
    80002930:	ffffe097          	auipc	ra,0xffffe
    80002934:	c58080e7          	jalr	-936(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002938:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000293c:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002940:	00006517          	auipc	a0,0x6
    80002944:	a5850513          	addi	a0,a0,-1448 # 80008398 <states.1719+0xa8>
    80002948:	ffffe097          	auipc	ra,0xffffe
    8000294c:	c40080e7          	jalr	-960(ra) # 80000588 <printf>
    p->killed = 1;
    80002950:	4785                	li	a5,1
    80002952:	d49c                	sw	a5,40(s1)
    exit(-1);
    80002954:	557d                	li	a0,-1
    80002956:	00000097          	auipc	ra,0x0
    8000295a:	a56080e7          	jalr	-1450(ra) # 800023ac <exit>
  if(which_dev == 2)
    8000295e:	4789                	li	a5,2
    80002960:	f8f910e3          	bne	s2,a5,800028e0 <usertrap+0x62>
    yield();
    80002964:	fffff097          	auipc	ra,0xfffff
    80002968:	7b0080e7          	jalr	1968(ra) # 80002114 <yield>
    8000296c:	bf95                	j	800028e0 <usertrap+0x62>
  int which_dev = 0;
    8000296e:	4901                	li	s2,0
    80002970:	b7d5                	j	80002954 <usertrap+0xd6>

0000000080002972 <kerneltrap>:
{
    80002972:	7179                	addi	sp,sp,-48
    80002974:	f406                	sd	ra,40(sp)
    80002976:	f022                	sd	s0,32(sp)
    80002978:	ec26                	sd	s1,24(sp)
    8000297a:	e84a                	sd	s2,16(sp)
    8000297c:	e44e                	sd	s3,8(sp)
    8000297e:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002980:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002984:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002988:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    8000298c:	1004f793          	andi	a5,s1,256
    80002990:	cb85                	beqz	a5,800029c0 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002992:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002996:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002998:	ef85                	bnez	a5,800029d0 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    8000299a:	00000097          	auipc	ra,0x0
    8000299e:	e42080e7          	jalr	-446(ra) # 800027dc <devintr>
    800029a2:	cd1d                	beqz	a0,800029e0 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800029a4:	4789                	li	a5,2
    800029a6:	06f50a63          	beq	a0,a5,80002a1a <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800029aa:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029ae:	10049073          	csrw	sstatus,s1
}
    800029b2:	70a2                	ld	ra,40(sp)
    800029b4:	7402                	ld	s0,32(sp)
    800029b6:	64e2                	ld	s1,24(sp)
    800029b8:	6942                	ld	s2,16(sp)
    800029ba:	69a2                	ld	s3,8(sp)
    800029bc:	6145                	addi	sp,sp,48
    800029be:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800029c0:	00006517          	auipc	a0,0x6
    800029c4:	9f850513          	addi	a0,a0,-1544 # 800083b8 <states.1719+0xc8>
    800029c8:	ffffe097          	auipc	ra,0xffffe
    800029cc:	b76080e7          	jalr	-1162(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    800029d0:	00006517          	auipc	a0,0x6
    800029d4:	a1050513          	addi	a0,a0,-1520 # 800083e0 <states.1719+0xf0>
    800029d8:	ffffe097          	auipc	ra,0xffffe
    800029dc:	b66080e7          	jalr	-1178(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    800029e0:	85ce                	mv	a1,s3
    800029e2:	00006517          	auipc	a0,0x6
    800029e6:	a1e50513          	addi	a0,a0,-1506 # 80008400 <states.1719+0x110>
    800029ea:	ffffe097          	auipc	ra,0xffffe
    800029ee:	b9e080e7          	jalr	-1122(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029f2:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800029f6:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    800029fa:	00006517          	auipc	a0,0x6
    800029fe:	a1650513          	addi	a0,a0,-1514 # 80008410 <states.1719+0x120>
    80002a02:	ffffe097          	auipc	ra,0xffffe
    80002a06:	b86080e7          	jalr	-1146(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002a0a:	00006517          	auipc	a0,0x6
    80002a0e:	a1e50513          	addi	a0,a0,-1506 # 80008428 <states.1719+0x138>
    80002a12:	ffffe097          	auipc	ra,0xffffe
    80002a16:	b2c080e7          	jalr	-1236(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a1a:	fffff097          	auipc	ra,0xfffff
    80002a1e:	07a080e7          	jalr	122(ra) # 80001a94 <myproc>
    80002a22:	d541                	beqz	a0,800029aa <kerneltrap+0x38>
    80002a24:	fffff097          	auipc	ra,0xfffff
    80002a28:	070080e7          	jalr	112(ra) # 80001a94 <myproc>
    80002a2c:	4d18                	lw	a4,24(a0)
    80002a2e:	4791                	li	a5,4
    80002a30:	f6f71de3          	bne	a4,a5,800029aa <kerneltrap+0x38>
    yield();
    80002a34:	fffff097          	auipc	ra,0xfffff
    80002a38:	6e0080e7          	jalr	1760(ra) # 80002114 <yield>
    80002a3c:	b7bd                	j	800029aa <kerneltrap+0x38>

0000000080002a3e <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002a3e:	1101                	addi	sp,sp,-32
    80002a40:	ec06                	sd	ra,24(sp)
    80002a42:	e822                	sd	s0,16(sp)
    80002a44:	e426                	sd	s1,8(sp)
    80002a46:	1000                	addi	s0,sp,32
    80002a48:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002a4a:	fffff097          	auipc	ra,0xfffff
    80002a4e:	04a080e7          	jalr	74(ra) # 80001a94 <myproc>
  switch (n) {
    80002a52:	4795                	li	a5,5
    80002a54:	0497e163          	bltu	a5,s1,80002a96 <argraw+0x58>
    80002a58:	048a                	slli	s1,s1,0x2
    80002a5a:	00006717          	auipc	a4,0x6
    80002a5e:	a0670713          	addi	a4,a4,-1530 # 80008460 <states.1719+0x170>
    80002a62:	94ba                	add	s1,s1,a4
    80002a64:	409c                	lw	a5,0(s1)
    80002a66:	97ba                	add	a5,a5,a4
    80002a68:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002a6a:	6d3c                	ld	a5,88(a0)
    80002a6c:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002a6e:	60e2                	ld	ra,24(sp)
    80002a70:	6442                	ld	s0,16(sp)
    80002a72:	64a2                	ld	s1,8(sp)
    80002a74:	6105                	addi	sp,sp,32
    80002a76:	8082                	ret
    return p->trapframe->a1;
    80002a78:	6d3c                	ld	a5,88(a0)
    80002a7a:	7fa8                	ld	a0,120(a5)
    80002a7c:	bfcd                	j	80002a6e <argraw+0x30>
    return p->trapframe->a2;
    80002a7e:	6d3c                	ld	a5,88(a0)
    80002a80:	63c8                	ld	a0,128(a5)
    80002a82:	b7f5                	j	80002a6e <argraw+0x30>
    return p->trapframe->a3;
    80002a84:	6d3c                	ld	a5,88(a0)
    80002a86:	67c8                	ld	a0,136(a5)
    80002a88:	b7dd                	j	80002a6e <argraw+0x30>
    return p->trapframe->a4;
    80002a8a:	6d3c                	ld	a5,88(a0)
    80002a8c:	6bc8                	ld	a0,144(a5)
    80002a8e:	b7c5                	j	80002a6e <argraw+0x30>
    return p->trapframe->a5;
    80002a90:	6d3c                	ld	a5,88(a0)
    80002a92:	6fc8                	ld	a0,152(a5)
    80002a94:	bfe9                	j	80002a6e <argraw+0x30>
  panic("argraw");
    80002a96:	00006517          	auipc	a0,0x6
    80002a9a:	9a250513          	addi	a0,a0,-1630 # 80008438 <states.1719+0x148>
    80002a9e:	ffffe097          	auipc	ra,0xffffe
    80002aa2:	aa0080e7          	jalr	-1376(ra) # 8000053e <panic>

0000000080002aa6 <fetchaddr>:
{
    80002aa6:	1101                	addi	sp,sp,-32
    80002aa8:	ec06                	sd	ra,24(sp)
    80002aaa:	e822                	sd	s0,16(sp)
    80002aac:	e426                	sd	s1,8(sp)
    80002aae:	e04a                	sd	s2,0(sp)
    80002ab0:	1000                	addi	s0,sp,32
    80002ab2:	84aa                	mv	s1,a0
    80002ab4:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002ab6:	fffff097          	auipc	ra,0xfffff
    80002aba:	fde080e7          	jalr	-34(ra) # 80001a94 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002abe:	653c                	ld	a5,72(a0)
    80002ac0:	02f4f863          	bgeu	s1,a5,80002af0 <fetchaddr+0x4a>
    80002ac4:	00848713          	addi	a4,s1,8
    80002ac8:	02e7e663          	bltu	a5,a4,80002af4 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002acc:	46a1                	li	a3,8
    80002ace:	8626                	mv	a2,s1
    80002ad0:	85ca                	mv	a1,s2
    80002ad2:	6928                	ld	a0,80(a0)
    80002ad4:	fffff097          	auipc	ra,0xfffff
    80002ad8:	c2a080e7          	jalr	-982(ra) # 800016fe <copyin>
    80002adc:	00a03533          	snez	a0,a0
    80002ae0:	40a00533          	neg	a0,a0
}
    80002ae4:	60e2                	ld	ra,24(sp)
    80002ae6:	6442                	ld	s0,16(sp)
    80002ae8:	64a2                	ld	s1,8(sp)
    80002aea:	6902                	ld	s2,0(sp)
    80002aec:	6105                	addi	sp,sp,32
    80002aee:	8082                	ret
    return -1;
    80002af0:	557d                	li	a0,-1
    80002af2:	bfcd                	j	80002ae4 <fetchaddr+0x3e>
    80002af4:	557d                	li	a0,-1
    80002af6:	b7fd                	j	80002ae4 <fetchaddr+0x3e>

0000000080002af8 <fetchstr>:
{
    80002af8:	7179                	addi	sp,sp,-48
    80002afa:	f406                	sd	ra,40(sp)
    80002afc:	f022                	sd	s0,32(sp)
    80002afe:	ec26                	sd	s1,24(sp)
    80002b00:	e84a                	sd	s2,16(sp)
    80002b02:	e44e                	sd	s3,8(sp)
    80002b04:	1800                	addi	s0,sp,48
    80002b06:	892a                	mv	s2,a0
    80002b08:	84ae                	mv	s1,a1
    80002b0a:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002b0c:	fffff097          	auipc	ra,0xfffff
    80002b10:	f88080e7          	jalr	-120(ra) # 80001a94 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002b14:	86ce                	mv	a3,s3
    80002b16:	864a                	mv	a2,s2
    80002b18:	85a6                	mv	a1,s1
    80002b1a:	6928                	ld	a0,80(a0)
    80002b1c:	fffff097          	auipc	ra,0xfffff
    80002b20:	c6e080e7          	jalr	-914(ra) # 8000178a <copyinstr>
  if(err < 0)
    80002b24:	00054763          	bltz	a0,80002b32 <fetchstr+0x3a>
  return strlen(buf);
    80002b28:	8526                	mv	a0,s1
    80002b2a:	ffffe097          	auipc	ra,0xffffe
    80002b2e:	33a080e7          	jalr	826(ra) # 80000e64 <strlen>
}
    80002b32:	70a2                	ld	ra,40(sp)
    80002b34:	7402                	ld	s0,32(sp)
    80002b36:	64e2                	ld	s1,24(sp)
    80002b38:	6942                	ld	s2,16(sp)
    80002b3a:	69a2                	ld	s3,8(sp)
    80002b3c:	6145                	addi	sp,sp,48
    80002b3e:	8082                	ret

0000000080002b40 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002b40:	1101                	addi	sp,sp,-32
    80002b42:	ec06                	sd	ra,24(sp)
    80002b44:	e822                	sd	s0,16(sp)
    80002b46:	e426                	sd	s1,8(sp)
    80002b48:	1000                	addi	s0,sp,32
    80002b4a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b4c:	00000097          	auipc	ra,0x0
    80002b50:	ef2080e7          	jalr	-270(ra) # 80002a3e <argraw>
    80002b54:	c088                	sw	a0,0(s1)
  return 0;
}
    80002b56:	4501                	li	a0,0
    80002b58:	60e2                	ld	ra,24(sp)
    80002b5a:	6442                	ld	s0,16(sp)
    80002b5c:	64a2                	ld	s1,8(sp)
    80002b5e:	6105                	addi	sp,sp,32
    80002b60:	8082                	ret

0000000080002b62 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002b62:	1101                	addi	sp,sp,-32
    80002b64:	ec06                	sd	ra,24(sp)
    80002b66:	e822                	sd	s0,16(sp)
    80002b68:	e426                	sd	s1,8(sp)
    80002b6a:	1000                	addi	s0,sp,32
    80002b6c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b6e:	00000097          	auipc	ra,0x0
    80002b72:	ed0080e7          	jalr	-304(ra) # 80002a3e <argraw>
    80002b76:	e088                	sd	a0,0(s1)
  return 0;
}
    80002b78:	4501                	li	a0,0
    80002b7a:	60e2                	ld	ra,24(sp)
    80002b7c:	6442                	ld	s0,16(sp)
    80002b7e:	64a2                	ld	s1,8(sp)
    80002b80:	6105                	addi	sp,sp,32
    80002b82:	8082                	ret

0000000080002b84 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002b84:	1101                	addi	sp,sp,-32
    80002b86:	ec06                	sd	ra,24(sp)
    80002b88:	e822                	sd	s0,16(sp)
    80002b8a:	e426                	sd	s1,8(sp)
    80002b8c:	e04a                	sd	s2,0(sp)
    80002b8e:	1000                	addi	s0,sp,32
    80002b90:	84ae                	mv	s1,a1
    80002b92:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002b94:	00000097          	auipc	ra,0x0
    80002b98:	eaa080e7          	jalr	-342(ra) # 80002a3e <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002b9c:	864a                	mv	a2,s2
    80002b9e:	85a6                	mv	a1,s1
    80002ba0:	00000097          	auipc	ra,0x0
    80002ba4:	f58080e7          	jalr	-168(ra) # 80002af8 <fetchstr>
}
    80002ba8:	60e2                	ld	ra,24(sp)
    80002baa:	6442                	ld	s0,16(sp)
    80002bac:	64a2                	ld	s1,8(sp)
    80002bae:	6902                	ld	s2,0(sp)
    80002bb0:	6105                	addi	sp,sp,32
    80002bb2:	8082                	ret

0000000080002bb4 <syscall>:
[SYS_pageAccess] sys_pageAccess,
};

void
syscall(void)
{
    80002bb4:	1101                	addi	sp,sp,-32
    80002bb6:	ec06                	sd	ra,24(sp)
    80002bb8:	e822                	sd	s0,16(sp)
    80002bba:	e426                	sd	s1,8(sp)
    80002bbc:	e04a                	sd	s2,0(sp)
    80002bbe:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002bc0:	fffff097          	auipc	ra,0xfffff
    80002bc4:	ed4080e7          	jalr	-300(ra) # 80001a94 <myproc>
    80002bc8:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002bca:	05853903          	ld	s2,88(a0)
    80002bce:	0a893783          	ld	a5,168(s2)
    80002bd2:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002bd6:	37fd                	addiw	a5,a5,-1
    80002bd8:	4755                	li	a4,21
    80002bda:	00f76f63          	bltu	a4,a5,80002bf8 <syscall+0x44>
    80002bde:	00369713          	slli	a4,a3,0x3
    80002be2:	00006797          	auipc	a5,0x6
    80002be6:	89678793          	addi	a5,a5,-1898 # 80008478 <syscalls>
    80002bea:	97ba                	add	a5,a5,a4
    80002bec:	639c                	ld	a5,0(a5)
    80002bee:	c789                	beqz	a5,80002bf8 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002bf0:	9782                	jalr	a5
    80002bf2:	06a93823          	sd	a0,112(s2)
    80002bf6:	a839                	j	80002c14 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002bf8:	15848613          	addi	a2,s1,344
    80002bfc:	588c                	lw	a1,48(s1)
    80002bfe:	00006517          	auipc	a0,0x6
    80002c02:	84250513          	addi	a0,a0,-1982 # 80008440 <states.1719+0x150>
    80002c06:	ffffe097          	auipc	ra,0xffffe
    80002c0a:	982080e7          	jalr	-1662(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002c0e:	6cbc                	ld	a5,88(s1)
    80002c10:	577d                	li	a4,-1
    80002c12:	fbb8                	sd	a4,112(a5)
  }
}
    80002c14:	60e2                	ld	ra,24(sp)
    80002c16:	6442                	ld	s0,16(sp)
    80002c18:	64a2                	ld	s1,8(sp)
    80002c1a:	6902                	ld	s2,0(sp)
    80002c1c:	6105                	addi	sp,sp,32
    80002c1e:	8082                	ret

0000000080002c20 <sys_exit>:
#include "proc.h"


uint64
sys_exit(void)
{
    80002c20:	1101                	addi	sp,sp,-32
    80002c22:	ec06                	sd	ra,24(sp)
    80002c24:	e822                	sd	s0,16(sp)
    80002c26:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002c28:	fec40593          	addi	a1,s0,-20
    80002c2c:	4501                	li	a0,0
    80002c2e:	00000097          	auipc	ra,0x0
    80002c32:	f12080e7          	jalr	-238(ra) # 80002b40 <argint>
    return -1;
    80002c36:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002c38:	00054963          	bltz	a0,80002c4a <sys_exit+0x2a>
  exit(n);
    80002c3c:	fec42503          	lw	a0,-20(s0)
    80002c40:	fffff097          	auipc	ra,0xfffff
    80002c44:	76c080e7          	jalr	1900(ra) # 800023ac <exit>
  return 0;  // not reached
    80002c48:	4781                	li	a5,0
}
    80002c4a:	853e                	mv	a0,a5
    80002c4c:	60e2                	ld	ra,24(sp)
    80002c4e:	6442                	ld	s0,16(sp)
    80002c50:	6105                	addi	sp,sp,32
    80002c52:	8082                	ret

0000000080002c54 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002c54:	1141                	addi	sp,sp,-16
    80002c56:	e406                	sd	ra,8(sp)
    80002c58:	e022                	sd	s0,0(sp)
    80002c5a:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002c5c:	fffff097          	auipc	ra,0xfffff
    80002c60:	e38080e7          	jalr	-456(ra) # 80001a94 <myproc>
}
    80002c64:	5908                	lw	a0,48(a0)
    80002c66:	60a2                	ld	ra,8(sp)
    80002c68:	6402                	ld	s0,0(sp)
    80002c6a:	0141                	addi	sp,sp,16
    80002c6c:	8082                	ret

0000000080002c6e <sys_fork>:

uint64
sys_fork(void)
{
    80002c6e:	1141                	addi	sp,sp,-16
    80002c70:	e406                	sd	ra,8(sp)
    80002c72:	e022                	sd	s0,0(sp)
    80002c74:	0800                	addi	s0,sp,16
  return fork();
    80002c76:	fffff097          	auipc	ra,0xfffff
    80002c7a:	1ec080e7          	jalr	492(ra) # 80001e62 <fork>
}
    80002c7e:	60a2                	ld	ra,8(sp)
    80002c80:	6402                	ld	s0,0(sp)
    80002c82:	0141                	addi	sp,sp,16
    80002c84:	8082                	ret

0000000080002c86 <sys_wait>:

uint64
sys_wait(void)
{
    80002c86:	1101                	addi	sp,sp,-32
    80002c88:	ec06                	sd	ra,24(sp)
    80002c8a:	e822                	sd	s0,16(sp)
    80002c8c:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002c8e:	fe840593          	addi	a1,s0,-24
    80002c92:	4501                	li	a0,0
    80002c94:	00000097          	auipc	ra,0x0
    80002c98:	ece080e7          	jalr	-306(ra) # 80002b62 <argaddr>
    80002c9c:	87aa                	mv	a5,a0
    return -1;
    80002c9e:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002ca0:	0007c863          	bltz	a5,80002cb0 <sys_wait+0x2a>
  return wait(p);
    80002ca4:	fe843503          	ld	a0,-24(s0)
    80002ca8:	fffff097          	auipc	ra,0xfffff
    80002cac:	50c080e7          	jalr	1292(ra) # 800021b4 <wait>
}
    80002cb0:	60e2                	ld	ra,24(sp)
    80002cb2:	6442                	ld	s0,16(sp)
    80002cb4:	6105                	addi	sp,sp,32
    80002cb6:	8082                	ret

0000000080002cb8 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002cb8:	7179                	addi	sp,sp,-48
    80002cba:	f406                	sd	ra,40(sp)
    80002cbc:	f022                	sd	s0,32(sp)
    80002cbe:	ec26                	sd	s1,24(sp)
    80002cc0:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002cc2:	fdc40593          	addi	a1,s0,-36
    80002cc6:	4501                	li	a0,0
    80002cc8:	00000097          	auipc	ra,0x0
    80002ccc:	e78080e7          	jalr	-392(ra) # 80002b40 <argint>
    80002cd0:	87aa                	mv	a5,a0
    return -1;
    80002cd2:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002cd4:	0207c063          	bltz	a5,80002cf4 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002cd8:	fffff097          	auipc	ra,0xfffff
    80002cdc:	dbc080e7          	jalr	-580(ra) # 80001a94 <myproc>
    80002ce0:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002ce2:	fdc42503          	lw	a0,-36(s0)
    80002ce6:	fffff097          	auipc	ra,0xfffff
    80002cea:	108080e7          	jalr	264(ra) # 80001dee <growproc>
    80002cee:	00054863          	bltz	a0,80002cfe <sys_sbrk+0x46>
    return -1;
  return addr;
    80002cf2:	8526                	mv	a0,s1
}
    80002cf4:	70a2                	ld	ra,40(sp)
    80002cf6:	7402                	ld	s0,32(sp)
    80002cf8:	64e2                	ld	s1,24(sp)
    80002cfa:	6145                	addi	sp,sp,48
    80002cfc:	8082                	ret
    return -1;
    80002cfe:	557d                	li	a0,-1
    80002d00:	bfd5                	j	80002cf4 <sys_sbrk+0x3c>

0000000080002d02 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002d02:	7139                	addi	sp,sp,-64
    80002d04:	fc06                	sd	ra,56(sp)
    80002d06:	f822                	sd	s0,48(sp)
    80002d08:	f426                	sd	s1,40(sp)
    80002d0a:	f04a                	sd	s2,32(sp)
    80002d0c:	ec4e                	sd	s3,24(sp)
    80002d0e:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002d10:	fcc40593          	addi	a1,s0,-52
    80002d14:	4501                	li	a0,0
    80002d16:	00000097          	auipc	ra,0x0
    80002d1a:	e2a080e7          	jalr	-470(ra) # 80002b40 <argint>
    return -1;
    80002d1e:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002d20:	06054563          	bltz	a0,80002d8a <sys_sleep+0x88>
  acquire(&tickslock);
    80002d24:	00014517          	auipc	a0,0x14
    80002d28:	3ac50513          	addi	a0,a0,940 # 800170d0 <tickslock>
    80002d2c:	ffffe097          	auipc	ra,0xffffe
    80002d30:	eb8080e7          	jalr	-328(ra) # 80000be4 <acquire>
  ticks0 = ticks;
    80002d34:	00006917          	auipc	s2,0x6
    80002d38:	2fc92903          	lw	s2,764(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80002d3c:	fcc42783          	lw	a5,-52(s0)
    80002d40:	cf85                	beqz	a5,80002d78 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002d42:	00014997          	auipc	s3,0x14
    80002d46:	38e98993          	addi	s3,s3,910 # 800170d0 <tickslock>
    80002d4a:	00006497          	auipc	s1,0x6
    80002d4e:	2e648493          	addi	s1,s1,742 # 80009030 <ticks>
    if(myproc()->killed){
    80002d52:	fffff097          	auipc	ra,0xfffff
    80002d56:	d42080e7          	jalr	-702(ra) # 80001a94 <myproc>
    80002d5a:	551c                	lw	a5,40(a0)
    80002d5c:	ef9d                	bnez	a5,80002d9a <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002d5e:	85ce                	mv	a1,s3
    80002d60:	8526                	mv	a0,s1
    80002d62:	fffff097          	auipc	ra,0xfffff
    80002d66:	3ee080e7          	jalr	1006(ra) # 80002150 <sleep>
  while(ticks - ticks0 < n){
    80002d6a:	409c                	lw	a5,0(s1)
    80002d6c:	412787bb          	subw	a5,a5,s2
    80002d70:	fcc42703          	lw	a4,-52(s0)
    80002d74:	fce7efe3          	bltu	a5,a4,80002d52 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002d78:	00014517          	auipc	a0,0x14
    80002d7c:	35850513          	addi	a0,a0,856 # 800170d0 <tickslock>
    80002d80:	ffffe097          	auipc	ra,0xffffe
    80002d84:	f18080e7          	jalr	-232(ra) # 80000c98 <release>
  return 0;
    80002d88:	4781                	li	a5,0
}
    80002d8a:	853e                	mv	a0,a5
    80002d8c:	70e2                	ld	ra,56(sp)
    80002d8e:	7442                	ld	s0,48(sp)
    80002d90:	74a2                	ld	s1,40(sp)
    80002d92:	7902                	ld	s2,32(sp)
    80002d94:	69e2                	ld	s3,24(sp)
    80002d96:	6121                	addi	sp,sp,64
    80002d98:	8082                	ret
      release(&tickslock);
    80002d9a:	00014517          	auipc	a0,0x14
    80002d9e:	33650513          	addi	a0,a0,822 # 800170d0 <tickslock>
    80002da2:	ffffe097          	auipc	ra,0xffffe
    80002da6:	ef6080e7          	jalr	-266(ra) # 80000c98 <release>
      return -1;
    80002daa:	57fd                	li	a5,-1
    80002dac:	bff9                	j	80002d8a <sys_sleep+0x88>

0000000080002dae <sys_kill>:

uint64
sys_kill(void)
{
    80002dae:	1101                	addi	sp,sp,-32
    80002db0:	ec06                	sd	ra,24(sp)
    80002db2:	e822                	sd	s0,16(sp)
    80002db4:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002db6:	fec40593          	addi	a1,s0,-20
    80002dba:	4501                	li	a0,0
    80002dbc:	00000097          	auipc	ra,0x0
    80002dc0:	d84080e7          	jalr	-636(ra) # 80002b40 <argint>
    80002dc4:	87aa                	mv	a5,a0
    return -1;
    80002dc6:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002dc8:	0007c863          	bltz	a5,80002dd8 <sys_kill+0x2a>
  return kill(pid);
    80002dcc:	fec42503          	lw	a0,-20(s0)
    80002dd0:	fffff097          	auipc	ra,0xfffff
    80002dd4:	6b2080e7          	jalr	1714(ra) # 80002482 <kill>
}
    80002dd8:	60e2                	ld	ra,24(sp)
    80002dda:	6442                	ld	s0,16(sp)
    80002ddc:	6105                	addi	sp,sp,32
    80002dde:	8082                	ret

0000000080002de0 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002de0:	1101                	addi	sp,sp,-32
    80002de2:	ec06                	sd	ra,24(sp)
    80002de4:	e822                	sd	s0,16(sp)
    80002de6:	e426                	sd	s1,8(sp)
    80002de8:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002dea:	00014517          	auipc	a0,0x14
    80002dee:	2e650513          	addi	a0,a0,742 # 800170d0 <tickslock>
    80002df2:	ffffe097          	auipc	ra,0xffffe
    80002df6:	df2080e7          	jalr	-526(ra) # 80000be4 <acquire>
  xticks = ticks;
    80002dfa:	00006497          	auipc	s1,0x6
    80002dfe:	2364a483          	lw	s1,566(s1) # 80009030 <ticks>
  release(&tickslock);
    80002e02:	00014517          	auipc	a0,0x14
    80002e06:	2ce50513          	addi	a0,a0,718 # 800170d0 <tickslock>
    80002e0a:	ffffe097          	auipc	ra,0xffffe
    80002e0e:	e8e080e7          	jalr	-370(ra) # 80000c98 <release>
  return xticks;
}
    80002e12:	02049513          	slli	a0,s1,0x20
    80002e16:	9101                	srli	a0,a0,0x20
    80002e18:	60e2                	ld	ra,24(sp)
    80002e1a:	6442                	ld	s0,16(sp)
    80002e1c:	64a2                	ld	s1,8(sp)
    80002e1e:	6105                	addi	sp,sp,32
    80002e20:	8082                	ret

0000000080002e22 <sys_pageAccess>:

uint64
sys_pageAccess(void)
{
    80002e22:	715d                	addi	sp,sp,-80
    80002e24:	e486                	sd	ra,72(sp)
    80002e26:	e0a2                	sd	s0,64(sp)
    80002e28:	fc26                	sd	s1,56(sp)
    80002e2a:	f84a                	sd	s2,48(sp)
    80002e2c:	f44e                	sd	s3,40(sp)
    80002e2e:	f052                	sd	s4,32(sp)
    80002e30:	0880                	addi	s0,sp,80
  // Get the three function arguments from the pageAccess() system call
  uint64 usrpage_ptr;  // First argument - pointer to user space address
  int npages;          // Second argument - the number of pages to examine
  uint64 usraddr;      // Third argument - pointer to the bitmap

  argaddr(0, &usrpage_ptr);
    80002e32:	fc840593          	addi	a1,s0,-56
    80002e36:	4501                	li	a0,0
    80002e38:	00000097          	auipc	ra,0x0
    80002e3c:	d2a080e7          	jalr	-726(ra) # 80002b62 <argaddr>
  argint(1, &npages);
    80002e40:	fc440593          	addi	a1,s0,-60
    80002e44:	4505                	li	a0,1
    80002e46:	00000097          	auipc	ra,0x0
    80002e4a:	cfa080e7          	jalr	-774(ra) # 80002b40 <argint>
  argaddr(2, &usraddr);
    80002e4e:	fb840593          	addi	a1,s0,-72
    80002e52:	4509                	li	a0,2
    80002e54:	00000097          	auipc	ra,0x0
    80002e58:	d0e080e7          	jalr	-754(ra) # 80002b62 <argaddr>

  struct proc* p = myproc();
    80002e5c:	fffff097          	auipc	ra,0xfffff
    80002e60:	c38080e7          	jalr	-968(ra) # 80001a94 <myproc>
    80002e64:	892a                	mv	s2,a0

  pte_t * pte;
  int bitmap = 0;
    80002e66:	fa042a23          	sw	zero,-76(s0)

  for(int i=0; i<npages;i++) {
    80002e6a:	fc442783          	lw	a5,-60(s0)
    80002e6e:	04f05863          	blez	a5,80002ebe <sys_pageAccess+0x9c>
    80002e72:	4481                	li	s1,0
    pte = walk(p->pagetable, usrpage_ptr, 0);
    if(*pte & PTE_A) {
      *pte &= ~(PTE_A);
      bitmap |= (1 << i);
    80002e74:	4a05                	li	s4,1
    }
    usrpage_ptr += PGSIZE;
    80002e76:	6985                	lui	s3,0x1
    80002e78:	a819                	j	80002e8e <sys_pageAccess+0x6c>
    80002e7a:	fc843783          	ld	a5,-56(s0)
    80002e7e:	97ce                	add	a5,a5,s3
    80002e80:	fcf43423          	sd	a5,-56(s0)
  for(int i=0; i<npages;i++) {
    80002e84:	2485                	addiw	s1,s1,1
    80002e86:	fc442783          	lw	a5,-60(s0)
    80002e8a:	02f4da63          	bge	s1,a5,80002ebe <sys_pageAccess+0x9c>
    pte = walk(p->pagetable, usrpage_ptr, 0);
    80002e8e:	4601                	li	a2,0
    80002e90:	fc843583          	ld	a1,-56(s0)
    80002e94:	05093503          	ld	a0,80(s2)
    80002e98:	ffffe097          	auipc	ra,0xffffe
    80002e9c:	130080e7          	jalr	304(ra) # 80000fc8 <walk>
    if(*pte & PTE_A) {
    80002ea0:	611c                	ld	a5,0(a0)
    80002ea2:	0407f713          	andi	a4,a5,64
    80002ea6:	db71                	beqz	a4,80002e7a <sys_pageAccess+0x58>
      *pte &= ~(PTE_A);
    80002ea8:	fbf7f793          	andi	a5,a5,-65
    80002eac:	e11c                	sd	a5,0(a0)
      bitmap |= (1 << i);
    80002eae:	009a17bb          	sllw	a5,s4,s1
    80002eb2:	fb442703          	lw	a4,-76(s0)
    80002eb6:	8fd9                	or	a5,a5,a4
    80002eb8:	faf42a23          	sw	a5,-76(s0)
    80002ebc:	bf7d                	j	80002e7a <sys_pageAccess+0x58>
  }

  if(copyout(p->pagetable, usraddr, (char*)&bitmap, sizeof(bitmap))<0) {
    80002ebe:	4691                	li	a3,4
    80002ec0:	fb440613          	addi	a2,s0,-76
    80002ec4:	fb843583          	ld	a1,-72(s0)
    80002ec8:	05093503          	ld	a0,80(s2)
    80002ecc:	ffffe097          	auipc	ra,0xffffe
    80002ed0:	7a6080e7          	jalr	1958(ra) # 80001672 <copyout>
    return -1;
    80002ed4:	57fd                	li	a5,-1
  if(copyout(p->pagetable, usraddr, (char*)&bitmap, sizeof(bitmap))<0) {
    80002ed6:	00054e63          	bltz	a0,80002ef2 <sys_pageAccess+0xd0>
  }
  // Return the bitmap pointer to the user program
  copyout(p->pagetable, usraddr, (char*)&bitmap, sizeof(bitmap));
    80002eda:	4691                	li	a3,4
    80002edc:	fb440613          	addi	a2,s0,-76
    80002ee0:	fb843583          	ld	a1,-72(s0)
    80002ee4:	05093503          	ld	a0,80(s2)
    80002ee8:	ffffe097          	auipc	ra,0xffffe
    80002eec:	78a080e7          	jalr	1930(ra) # 80001672 <copyout>
  return 0;
    80002ef0:	4781                	li	a5,0
}
    80002ef2:	853e                	mv	a0,a5
    80002ef4:	60a6                	ld	ra,72(sp)
    80002ef6:	6406                	ld	s0,64(sp)
    80002ef8:	74e2                	ld	s1,56(sp)
    80002efa:	7942                	ld	s2,48(sp)
    80002efc:	79a2                	ld	s3,40(sp)
    80002efe:	7a02                	ld	s4,32(sp)
    80002f00:	6161                	addi	sp,sp,80
    80002f02:	8082                	ret

0000000080002f04 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002f04:	7179                	addi	sp,sp,-48
    80002f06:	f406                	sd	ra,40(sp)
    80002f08:	f022                	sd	s0,32(sp)
    80002f0a:	ec26                	sd	s1,24(sp)
    80002f0c:	e84a                	sd	s2,16(sp)
    80002f0e:	e44e                	sd	s3,8(sp)
    80002f10:	e052                	sd	s4,0(sp)
    80002f12:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002f14:	00005597          	auipc	a1,0x5
    80002f18:	61c58593          	addi	a1,a1,1564 # 80008530 <syscalls+0xb8>
    80002f1c:	00014517          	auipc	a0,0x14
    80002f20:	1cc50513          	addi	a0,a0,460 # 800170e8 <bcache>
    80002f24:	ffffe097          	auipc	ra,0xffffe
    80002f28:	c30080e7          	jalr	-976(ra) # 80000b54 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002f2c:	0001c797          	auipc	a5,0x1c
    80002f30:	1bc78793          	addi	a5,a5,444 # 8001f0e8 <bcache+0x8000>
    80002f34:	0001c717          	auipc	a4,0x1c
    80002f38:	41c70713          	addi	a4,a4,1052 # 8001f350 <bcache+0x8268>
    80002f3c:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002f40:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f44:	00014497          	auipc	s1,0x14
    80002f48:	1bc48493          	addi	s1,s1,444 # 80017100 <bcache+0x18>
    b->next = bcache.head.next;
    80002f4c:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002f4e:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002f50:	00005a17          	auipc	s4,0x5
    80002f54:	5e8a0a13          	addi	s4,s4,1512 # 80008538 <syscalls+0xc0>
    b->next = bcache.head.next;
    80002f58:	2b893783          	ld	a5,696(s2)
    80002f5c:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002f5e:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002f62:	85d2                	mv	a1,s4
    80002f64:	01048513          	addi	a0,s1,16
    80002f68:	00001097          	auipc	ra,0x1
    80002f6c:	4bc080e7          	jalr	1212(ra) # 80004424 <initsleeplock>
    bcache.head.next->prev = b;
    80002f70:	2b893783          	ld	a5,696(s2)
    80002f74:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002f76:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f7a:	45848493          	addi	s1,s1,1112
    80002f7e:	fd349de3          	bne	s1,s3,80002f58 <binit+0x54>
  }
}
    80002f82:	70a2                	ld	ra,40(sp)
    80002f84:	7402                	ld	s0,32(sp)
    80002f86:	64e2                	ld	s1,24(sp)
    80002f88:	6942                	ld	s2,16(sp)
    80002f8a:	69a2                	ld	s3,8(sp)
    80002f8c:	6a02                	ld	s4,0(sp)
    80002f8e:	6145                	addi	sp,sp,48
    80002f90:	8082                	ret

0000000080002f92 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002f92:	7179                	addi	sp,sp,-48
    80002f94:	f406                	sd	ra,40(sp)
    80002f96:	f022                	sd	s0,32(sp)
    80002f98:	ec26                	sd	s1,24(sp)
    80002f9a:	e84a                	sd	s2,16(sp)
    80002f9c:	e44e                	sd	s3,8(sp)
    80002f9e:	1800                	addi	s0,sp,48
    80002fa0:	89aa                	mv	s3,a0
    80002fa2:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80002fa4:	00014517          	auipc	a0,0x14
    80002fa8:	14450513          	addi	a0,a0,324 # 800170e8 <bcache>
    80002fac:	ffffe097          	auipc	ra,0xffffe
    80002fb0:	c38080e7          	jalr	-968(ra) # 80000be4 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002fb4:	0001c497          	auipc	s1,0x1c
    80002fb8:	3ec4b483          	ld	s1,1004(s1) # 8001f3a0 <bcache+0x82b8>
    80002fbc:	0001c797          	auipc	a5,0x1c
    80002fc0:	39478793          	addi	a5,a5,916 # 8001f350 <bcache+0x8268>
    80002fc4:	02f48f63          	beq	s1,a5,80003002 <bread+0x70>
    80002fc8:	873e                	mv	a4,a5
    80002fca:	a021                	j	80002fd2 <bread+0x40>
    80002fcc:	68a4                	ld	s1,80(s1)
    80002fce:	02e48a63          	beq	s1,a4,80003002 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002fd2:	449c                	lw	a5,8(s1)
    80002fd4:	ff379ce3          	bne	a5,s3,80002fcc <bread+0x3a>
    80002fd8:	44dc                	lw	a5,12(s1)
    80002fda:	ff2799e3          	bne	a5,s2,80002fcc <bread+0x3a>
      b->refcnt++;
    80002fde:	40bc                	lw	a5,64(s1)
    80002fe0:	2785                	addiw	a5,a5,1
    80002fe2:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002fe4:	00014517          	auipc	a0,0x14
    80002fe8:	10450513          	addi	a0,a0,260 # 800170e8 <bcache>
    80002fec:	ffffe097          	auipc	ra,0xffffe
    80002ff0:	cac080e7          	jalr	-852(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80002ff4:	01048513          	addi	a0,s1,16
    80002ff8:	00001097          	auipc	ra,0x1
    80002ffc:	466080e7          	jalr	1126(ra) # 8000445e <acquiresleep>
      return b;
    80003000:	a8b9                	j	8000305e <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003002:	0001c497          	auipc	s1,0x1c
    80003006:	3964b483          	ld	s1,918(s1) # 8001f398 <bcache+0x82b0>
    8000300a:	0001c797          	auipc	a5,0x1c
    8000300e:	34678793          	addi	a5,a5,838 # 8001f350 <bcache+0x8268>
    80003012:	00f48863          	beq	s1,a5,80003022 <bread+0x90>
    80003016:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003018:	40bc                	lw	a5,64(s1)
    8000301a:	cf81                	beqz	a5,80003032 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000301c:	64a4                	ld	s1,72(s1)
    8000301e:	fee49de3          	bne	s1,a4,80003018 <bread+0x86>
  panic("bget: no buffers");
    80003022:	00005517          	auipc	a0,0x5
    80003026:	51e50513          	addi	a0,a0,1310 # 80008540 <syscalls+0xc8>
    8000302a:	ffffd097          	auipc	ra,0xffffd
    8000302e:	514080e7          	jalr	1300(ra) # 8000053e <panic>
      b->dev = dev;
    80003032:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003036:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    8000303a:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    8000303e:	4785                	li	a5,1
    80003040:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003042:	00014517          	auipc	a0,0x14
    80003046:	0a650513          	addi	a0,a0,166 # 800170e8 <bcache>
    8000304a:	ffffe097          	auipc	ra,0xffffe
    8000304e:	c4e080e7          	jalr	-946(ra) # 80000c98 <release>
      acquiresleep(&b->lock);
    80003052:	01048513          	addi	a0,s1,16
    80003056:	00001097          	auipc	ra,0x1
    8000305a:	408080e7          	jalr	1032(ra) # 8000445e <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    8000305e:	409c                	lw	a5,0(s1)
    80003060:	cb89                	beqz	a5,80003072 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003062:	8526                	mv	a0,s1
    80003064:	70a2                	ld	ra,40(sp)
    80003066:	7402                	ld	s0,32(sp)
    80003068:	64e2                	ld	s1,24(sp)
    8000306a:	6942                	ld	s2,16(sp)
    8000306c:	69a2                	ld	s3,8(sp)
    8000306e:	6145                	addi	sp,sp,48
    80003070:	8082                	ret
    virtio_disk_rw(b, 0);
    80003072:	4581                	li	a1,0
    80003074:	8526                	mv	a0,s1
    80003076:	00003097          	auipc	ra,0x3
    8000307a:	f20080e7          	jalr	-224(ra) # 80005f96 <virtio_disk_rw>
    b->valid = 1;
    8000307e:	4785                	li	a5,1
    80003080:	c09c                	sw	a5,0(s1)
  return b;
    80003082:	b7c5                	j	80003062 <bread+0xd0>

0000000080003084 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003084:	1101                	addi	sp,sp,-32
    80003086:	ec06                	sd	ra,24(sp)
    80003088:	e822                	sd	s0,16(sp)
    8000308a:	e426                	sd	s1,8(sp)
    8000308c:	1000                	addi	s0,sp,32
    8000308e:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003090:	0541                	addi	a0,a0,16
    80003092:	00001097          	auipc	ra,0x1
    80003096:	466080e7          	jalr	1126(ra) # 800044f8 <holdingsleep>
    8000309a:	cd01                	beqz	a0,800030b2 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000309c:	4585                	li	a1,1
    8000309e:	8526                	mv	a0,s1
    800030a0:	00003097          	auipc	ra,0x3
    800030a4:	ef6080e7          	jalr	-266(ra) # 80005f96 <virtio_disk_rw>
}
    800030a8:	60e2                	ld	ra,24(sp)
    800030aa:	6442                	ld	s0,16(sp)
    800030ac:	64a2                	ld	s1,8(sp)
    800030ae:	6105                	addi	sp,sp,32
    800030b0:	8082                	ret
    panic("bwrite");
    800030b2:	00005517          	auipc	a0,0x5
    800030b6:	4a650513          	addi	a0,a0,1190 # 80008558 <syscalls+0xe0>
    800030ba:	ffffd097          	auipc	ra,0xffffd
    800030be:	484080e7          	jalr	1156(ra) # 8000053e <panic>

00000000800030c2 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800030c2:	1101                	addi	sp,sp,-32
    800030c4:	ec06                	sd	ra,24(sp)
    800030c6:	e822                	sd	s0,16(sp)
    800030c8:	e426                	sd	s1,8(sp)
    800030ca:	e04a                	sd	s2,0(sp)
    800030cc:	1000                	addi	s0,sp,32
    800030ce:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800030d0:	01050913          	addi	s2,a0,16
    800030d4:	854a                	mv	a0,s2
    800030d6:	00001097          	auipc	ra,0x1
    800030da:	422080e7          	jalr	1058(ra) # 800044f8 <holdingsleep>
    800030de:	c92d                	beqz	a0,80003150 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800030e0:	854a                	mv	a0,s2
    800030e2:	00001097          	auipc	ra,0x1
    800030e6:	3d2080e7          	jalr	978(ra) # 800044b4 <releasesleep>

  acquire(&bcache.lock);
    800030ea:	00014517          	auipc	a0,0x14
    800030ee:	ffe50513          	addi	a0,a0,-2 # 800170e8 <bcache>
    800030f2:	ffffe097          	auipc	ra,0xffffe
    800030f6:	af2080e7          	jalr	-1294(ra) # 80000be4 <acquire>
  b->refcnt--;
    800030fa:	40bc                	lw	a5,64(s1)
    800030fc:	37fd                	addiw	a5,a5,-1
    800030fe:	0007871b          	sext.w	a4,a5
    80003102:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003104:	eb05                	bnez	a4,80003134 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003106:	68bc                	ld	a5,80(s1)
    80003108:	64b8                	ld	a4,72(s1)
    8000310a:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000310c:	64bc                	ld	a5,72(s1)
    8000310e:	68b8                	ld	a4,80(s1)
    80003110:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003112:	0001c797          	auipc	a5,0x1c
    80003116:	fd678793          	addi	a5,a5,-42 # 8001f0e8 <bcache+0x8000>
    8000311a:	2b87b703          	ld	a4,696(a5)
    8000311e:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003120:	0001c717          	auipc	a4,0x1c
    80003124:	23070713          	addi	a4,a4,560 # 8001f350 <bcache+0x8268>
    80003128:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000312a:	2b87b703          	ld	a4,696(a5)
    8000312e:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003130:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003134:	00014517          	auipc	a0,0x14
    80003138:	fb450513          	addi	a0,a0,-76 # 800170e8 <bcache>
    8000313c:	ffffe097          	auipc	ra,0xffffe
    80003140:	b5c080e7          	jalr	-1188(ra) # 80000c98 <release>
}
    80003144:	60e2                	ld	ra,24(sp)
    80003146:	6442                	ld	s0,16(sp)
    80003148:	64a2                	ld	s1,8(sp)
    8000314a:	6902                	ld	s2,0(sp)
    8000314c:	6105                	addi	sp,sp,32
    8000314e:	8082                	ret
    panic("brelse");
    80003150:	00005517          	auipc	a0,0x5
    80003154:	41050513          	addi	a0,a0,1040 # 80008560 <syscalls+0xe8>
    80003158:	ffffd097          	auipc	ra,0xffffd
    8000315c:	3e6080e7          	jalr	998(ra) # 8000053e <panic>

0000000080003160 <bpin>:

void
bpin(struct buf *b) {
    80003160:	1101                	addi	sp,sp,-32
    80003162:	ec06                	sd	ra,24(sp)
    80003164:	e822                	sd	s0,16(sp)
    80003166:	e426                	sd	s1,8(sp)
    80003168:	1000                	addi	s0,sp,32
    8000316a:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000316c:	00014517          	auipc	a0,0x14
    80003170:	f7c50513          	addi	a0,a0,-132 # 800170e8 <bcache>
    80003174:	ffffe097          	auipc	ra,0xffffe
    80003178:	a70080e7          	jalr	-1424(ra) # 80000be4 <acquire>
  b->refcnt++;
    8000317c:	40bc                	lw	a5,64(s1)
    8000317e:	2785                	addiw	a5,a5,1
    80003180:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003182:	00014517          	auipc	a0,0x14
    80003186:	f6650513          	addi	a0,a0,-154 # 800170e8 <bcache>
    8000318a:	ffffe097          	auipc	ra,0xffffe
    8000318e:	b0e080e7          	jalr	-1266(ra) # 80000c98 <release>
}
    80003192:	60e2                	ld	ra,24(sp)
    80003194:	6442                	ld	s0,16(sp)
    80003196:	64a2                	ld	s1,8(sp)
    80003198:	6105                	addi	sp,sp,32
    8000319a:	8082                	ret

000000008000319c <bunpin>:

void
bunpin(struct buf *b) {
    8000319c:	1101                	addi	sp,sp,-32
    8000319e:	ec06                	sd	ra,24(sp)
    800031a0:	e822                	sd	s0,16(sp)
    800031a2:	e426                	sd	s1,8(sp)
    800031a4:	1000                	addi	s0,sp,32
    800031a6:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800031a8:	00014517          	auipc	a0,0x14
    800031ac:	f4050513          	addi	a0,a0,-192 # 800170e8 <bcache>
    800031b0:	ffffe097          	auipc	ra,0xffffe
    800031b4:	a34080e7          	jalr	-1484(ra) # 80000be4 <acquire>
  b->refcnt--;
    800031b8:	40bc                	lw	a5,64(s1)
    800031ba:	37fd                	addiw	a5,a5,-1
    800031bc:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800031be:	00014517          	auipc	a0,0x14
    800031c2:	f2a50513          	addi	a0,a0,-214 # 800170e8 <bcache>
    800031c6:	ffffe097          	auipc	ra,0xffffe
    800031ca:	ad2080e7          	jalr	-1326(ra) # 80000c98 <release>
}
    800031ce:	60e2                	ld	ra,24(sp)
    800031d0:	6442                	ld	s0,16(sp)
    800031d2:	64a2                	ld	s1,8(sp)
    800031d4:	6105                	addi	sp,sp,32
    800031d6:	8082                	ret

00000000800031d8 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800031d8:	1101                	addi	sp,sp,-32
    800031da:	ec06                	sd	ra,24(sp)
    800031dc:	e822                	sd	s0,16(sp)
    800031de:	e426                	sd	s1,8(sp)
    800031e0:	e04a                	sd	s2,0(sp)
    800031e2:	1000                	addi	s0,sp,32
    800031e4:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800031e6:	00d5d59b          	srliw	a1,a1,0xd
    800031ea:	0001c797          	auipc	a5,0x1c
    800031ee:	5da7a783          	lw	a5,1498(a5) # 8001f7c4 <sb+0x1c>
    800031f2:	9dbd                	addw	a1,a1,a5
    800031f4:	00000097          	auipc	ra,0x0
    800031f8:	d9e080e7          	jalr	-610(ra) # 80002f92 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800031fc:	0074f713          	andi	a4,s1,7
    80003200:	4785                	li	a5,1
    80003202:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003206:	14ce                	slli	s1,s1,0x33
    80003208:	90d9                	srli	s1,s1,0x36
    8000320a:	00950733          	add	a4,a0,s1
    8000320e:	05874703          	lbu	a4,88(a4)
    80003212:	00e7f6b3          	and	a3,a5,a4
    80003216:	c69d                	beqz	a3,80003244 <bfree+0x6c>
    80003218:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000321a:	94aa                	add	s1,s1,a0
    8000321c:	fff7c793          	not	a5,a5
    80003220:	8ff9                	and	a5,a5,a4
    80003222:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003226:	00001097          	auipc	ra,0x1
    8000322a:	118080e7          	jalr	280(ra) # 8000433e <log_write>
  brelse(bp);
    8000322e:	854a                	mv	a0,s2
    80003230:	00000097          	auipc	ra,0x0
    80003234:	e92080e7          	jalr	-366(ra) # 800030c2 <brelse>
}
    80003238:	60e2                	ld	ra,24(sp)
    8000323a:	6442                	ld	s0,16(sp)
    8000323c:	64a2                	ld	s1,8(sp)
    8000323e:	6902                	ld	s2,0(sp)
    80003240:	6105                	addi	sp,sp,32
    80003242:	8082                	ret
    panic("freeing free block");
    80003244:	00005517          	auipc	a0,0x5
    80003248:	32450513          	addi	a0,a0,804 # 80008568 <syscalls+0xf0>
    8000324c:	ffffd097          	auipc	ra,0xffffd
    80003250:	2f2080e7          	jalr	754(ra) # 8000053e <panic>

0000000080003254 <balloc>:
{
    80003254:	711d                	addi	sp,sp,-96
    80003256:	ec86                	sd	ra,88(sp)
    80003258:	e8a2                	sd	s0,80(sp)
    8000325a:	e4a6                	sd	s1,72(sp)
    8000325c:	e0ca                	sd	s2,64(sp)
    8000325e:	fc4e                	sd	s3,56(sp)
    80003260:	f852                	sd	s4,48(sp)
    80003262:	f456                	sd	s5,40(sp)
    80003264:	f05a                	sd	s6,32(sp)
    80003266:	ec5e                	sd	s7,24(sp)
    80003268:	e862                	sd	s8,16(sp)
    8000326a:	e466                	sd	s9,8(sp)
    8000326c:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000326e:	0001c797          	auipc	a5,0x1c
    80003272:	53e7a783          	lw	a5,1342(a5) # 8001f7ac <sb+0x4>
    80003276:	cbd1                	beqz	a5,8000330a <balloc+0xb6>
    80003278:	8baa                	mv	s7,a0
    8000327a:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000327c:	0001cb17          	auipc	s6,0x1c
    80003280:	52cb0b13          	addi	s6,s6,1324 # 8001f7a8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003284:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003286:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003288:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000328a:	6c89                	lui	s9,0x2
    8000328c:	a831                	j	800032a8 <balloc+0x54>
    brelse(bp);
    8000328e:	854a                	mv	a0,s2
    80003290:	00000097          	auipc	ra,0x0
    80003294:	e32080e7          	jalr	-462(ra) # 800030c2 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003298:	015c87bb          	addw	a5,s9,s5
    8000329c:	00078a9b          	sext.w	s5,a5
    800032a0:	004b2703          	lw	a4,4(s6)
    800032a4:	06eaf363          	bgeu	s5,a4,8000330a <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800032a8:	41fad79b          	sraiw	a5,s5,0x1f
    800032ac:	0137d79b          	srliw	a5,a5,0x13
    800032b0:	015787bb          	addw	a5,a5,s5
    800032b4:	40d7d79b          	sraiw	a5,a5,0xd
    800032b8:	01cb2583          	lw	a1,28(s6)
    800032bc:	9dbd                	addw	a1,a1,a5
    800032be:	855e                	mv	a0,s7
    800032c0:	00000097          	auipc	ra,0x0
    800032c4:	cd2080e7          	jalr	-814(ra) # 80002f92 <bread>
    800032c8:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032ca:	004b2503          	lw	a0,4(s6)
    800032ce:	000a849b          	sext.w	s1,s5
    800032d2:	8662                	mv	a2,s8
    800032d4:	faa4fde3          	bgeu	s1,a0,8000328e <balloc+0x3a>
      m = 1 << (bi % 8);
    800032d8:	41f6579b          	sraiw	a5,a2,0x1f
    800032dc:	01d7d69b          	srliw	a3,a5,0x1d
    800032e0:	00c6873b          	addw	a4,a3,a2
    800032e4:	00777793          	andi	a5,a4,7
    800032e8:	9f95                	subw	a5,a5,a3
    800032ea:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800032ee:	4037571b          	sraiw	a4,a4,0x3
    800032f2:	00e906b3          	add	a3,s2,a4
    800032f6:	0586c683          	lbu	a3,88(a3)
    800032fa:	00d7f5b3          	and	a1,a5,a3
    800032fe:	cd91                	beqz	a1,8000331a <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003300:	2605                	addiw	a2,a2,1
    80003302:	2485                	addiw	s1,s1,1
    80003304:	fd4618e3          	bne	a2,s4,800032d4 <balloc+0x80>
    80003308:	b759                	j	8000328e <balloc+0x3a>
  panic("balloc: out of blocks");
    8000330a:	00005517          	auipc	a0,0x5
    8000330e:	27650513          	addi	a0,a0,630 # 80008580 <syscalls+0x108>
    80003312:	ffffd097          	auipc	ra,0xffffd
    80003316:	22c080e7          	jalr	556(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000331a:	974a                	add	a4,a4,s2
    8000331c:	8fd5                	or	a5,a5,a3
    8000331e:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003322:	854a                	mv	a0,s2
    80003324:	00001097          	auipc	ra,0x1
    80003328:	01a080e7          	jalr	26(ra) # 8000433e <log_write>
        brelse(bp);
    8000332c:	854a                	mv	a0,s2
    8000332e:	00000097          	auipc	ra,0x0
    80003332:	d94080e7          	jalr	-620(ra) # 800030c2 <brelse>
  bp = bread(dev, bno);
    80003336:	85a6                	mv	a1,s1
    80003338:	855e                	mv	a0,s7
    8000333a:	00000097          	auipc	ra,0x0
    8000333e:	c58080e7          	jalr	-936(ra) # 80002f92 <bread>
    80003342:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003344:	40000613          	li	a2,1024
    80003348:	4581                	li	a1,0
    8000334a:	05850513          	addi	a0,a0,88
    8000334e:	ffffe097          	auipc	ra,0xffffe
    80003352:	992080e7          	jalr	-1646(ra) # 80000ce0 <memset>
  log_write(bp);
    80003356:	854a                	mv	a0,s2
    80003358:	00001097          	auipc	ra,0x1
    8000335c:	fe6080e7          	jalr	-26(ra) # 8000433e <log_write>
  brelse(bp);
    80003360:	854a                	mv	a0,s2
    80003362:	00000097          	auipc	ra,0x0
    80003366:	d60080e7          	jalr	-672(ra) # 800030c2 <brelse>
}
    8000336a:	8526                	mv	a0,s1
    8000336c:	60e6                	ld	ra,88(sp)
    8000336e:	6446                	ld	s0,80(sp)
    80003370:	64a6                	ld	s1,72(sp)
    80003372:	6906                	ld	s2,64(sp)
    80003374:	79e2                	ld	s3,56(sp)
    80003376:	7a42                	ld	s4,48(sp)
    80003378:	7aa2                	ld	s5,40(sp)
    8000337a:	7b02                	ld	s6,32(sp)
    8000337c:	6be2                	ld	s7,24(sp)
    8000337e:	6c42                	ld	s8,16(sp)
    80003380:	6ca2                	ld	s9,8(sp)
    80003382:	6125                	addi	sp,sp,96
    80003384:	8082                	ret

0000000080003386 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003386:	7179                	addi	sp,sp,-48
    80003388:	f406                	sd	ra,40(sp)
    8000338a:	f022                	sd	s0,32(sp)
    8000338c:	ec26                	sd	s1,24(sp)
    8000338e:	e84a                	sd	s2,16(sp)
    80003390:	e44e                	sd	s3,8(sp)
    80003392:	e052                	sd	s4,0(sp)
    80003394:	1800                	addi	s0,sp,48
    80003396:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003398:	47ad                	li	a5,11
    8000339a:	04b7fe63          	bgeu	a5,a1,800033f6 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    8000339e:	ff45849b          	addiw	s1,a1,-12
    800033a2:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800033a6:	0ff00793          	li	a5,255
    800033aa:	0ae7e363          	bltu	a5,a4,80003450 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800033ae:	08052583          	lw	a1,128(a0)
    800033b2:	c5ad                	beqz	a1,8000341c <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800033b4:	00092503          	lw	a0,0(s2)
    800033b8:	00000097          	auipc	ra,0x0
    800033bc:	bda080e7          	jalr	-1062(ra) # 80002f92 <bread>
    800033c0:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800033c2:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800033c6:	02049593          	slli	a1,s1,0x20
    800033ca:	9181                	srli	a1,a1,0x20
    800033cc:	058a                	slli	a1,a1,0x2
    800033ce:	00b784b3          	add	s1,a5,a1
    800033d2:	0004a983          	lw	s3,0(s1)
    800033d6:	04098d63          	beqz	s3,80003430 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800033da:	8552                	mv	a0,s4
    800033dc:	00000097          	auipc	ra,0x0
    800033e0:	ce6080e7          	jalr	-794(ra) # 800030c2 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800033e4:	854e                	mv	a0,s3
    800033e6:	70a2                	ld	ra,40(sp)
    800033e8:	7402                	ld	s0,32(sp)
    800033ea:	64e2                	ld	s1,24(sp)
    800033ec:	6942                	ld	s2,16(sp)
    800033ee:	69a2                	ld	s3,8(sp)
    800033f0:	6a02                	ld	s4,0(sp)
    800033f2:	6145                	addi	sp,sp,48
    800033f4:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800033f6:	02059493          	slli	s1,a1,0x20
    800033fa:	9081                	srli	s1,s1,0x20
    800033fc:	048a                	slli	s1,s1,0x2
    800033fe:	94aa                	add	s1,s1,a0
    80003400:	0504a983          	lw	s3,80(s1)
    80003404:	fe0990e3          	bnez	s3,800033e4 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003408:	4108                	lw	a0,0(a0)
    8000340a:	00000097          	auipc	ra,0x0
    8000340e:	e4a080e7          	jalr	-438(ra) # 80003254 <balloc>
    80003412:	0005099b          	sext.w	s3,a0
    80003416:	0534a823          	sw	s3,80(s1)
    8000341a:	b7e9                	j	800033e4 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    8000341c:	4108                	lw	a0,0(a0)
    8000341e:	00000097          	auipc	ra,0x0
    80003422:	e36080e7          	jalr	-458(ra) # 80003254 <balloc>
    80003426:	0005059b          	sext.w	a1,a0
    8000342a:	08b92023          	sw	a1,128(s2)
    8000342e:	b759                	j	800033b4 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003430:	00092503          	lw	a0,0(s2)
    80003434:	00000097          	auipc	ra,0x0
    80003438:	e20080e7          	jalr	-480(ra) # 80003254 <balloc>
    8000343c:	0005099b          	sext.w	s3,a0
    80003440:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003444:	8552                	mv	a0,s4
    80003446:	00001097          	auipc	ra,0x1
    8000344a:	ef8080e7          	jalr	-264(ra) # 8000433e <log_write>
    8000344e:	b771                	j	800033da <bmap+0x54>
  panic("bmap: out of range");
    80003450:	00005517          	auipc	a0,0x5
    80003454:	14850513          	addi	a0,a0,328 # 80008598 <syscalls+0x120>
    80003458:	ffffd097          	auipc	ra,0xffffd
    8000345c:	0e6080e7          	jalr	230(ra) # 8000053e <panic>

0000000080003460 <iget>:
{
    80003460:	7179                	addi	sp,sp,-48
    80003462:	f406                	sd	ra,40(sp)
    80003464:	f022                	sd	s0,32(sp)
    80003466:	ec26                	sd	s1,24(sp)
    80003468:	e84a                	sd	s2,16(sp)
    8000346a:	e44e                	sd	s3,8(sp)
    8000346c:	e052                	sd	s4,0(sp)
    8000346e:	1800                	addi	s0,sp,48
    80003470:	89aa                	mv	s3,a0
    80003472:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003474:	0001c517          	auipc	a0,0x1c
    80003478:	35450513          	addi	a0,a0,852 # 8001f7c8 <itable>
    8000347c:	ffffd097          	auipc	ra,0xffffd
    80003480:	768080e7          	jalr	1896(ra) # 80000be4 <acquire>
  empty = 0;
    80003484:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003486:	0001c497          	auipc	s1,0x1c
    8000348a:	35a48493          	addi	s1,s1,858 # 8001f7e0 <itable+0x18>
    8000348e:	0001e697          	auipc	a3,0x1e
    80003492:	de268693          	addi	a3,a3,-542 # 80021270 <log>
    80003496:	a039                	j	800034a4 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003498:	02090b63          	beqz	s2,800034ce <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000349c:	08848493          	addi	s1,s1,136
    800034a0:	02d48a63          	beq	s1,a3,800034d4 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800034a4:	449c                	lw	a5,8(s1)
    800034a6:	fef059e3          	blez	a5,80003498 <iget+0x38>
    800034aa:	4098                	lw	a4,0(s1)
    800034ac:	ff3716e3          	bne	a4,s3,80003498 <iget+0x38>
    800034b0:	40d8                	lw	a4,4(s1)
    800034b2:	ff4713e3          	bne	a4,s4,80003498 <iget+0x38>
      ip->ref++;
    800034b6:	2785                	addiw	a5,a5,1
    800034b8:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800034ba:	0001c517          	auipc	a0,0x1c
    800034be:	30e50513          	addi	a0,a0,782 # 8001f7c8 <itable>
    800034c2:	ffffd097          	auipc	ra,0xffffd
    800034c6:	7d6080e7          	jalr	2006(ra) # 80000c98 <release>
      return ip;
    800034ca:	8926                	mv	s2,s1
    800034cc:	a03d                	j	800034fa <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800034ce:	f7f9                	bnez	a5,8000349c <iget+0x3c>
    800034d0:	8926                	mv	s2,s1
    800034d2:	b7e9                	j	8000349c <iget+0x3c>
  if(empty == 0)
    800034d4:	02090c63          	beqz	s2,8000350c <iget+0xac>
  ip->dev = dev;
    800034d8:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800034dc:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800034e0:	4785                	li	a5,1
    800034e2:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800034e6:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800034ea:	0001c517          	auipc	a0,0x1c
    800034ee:	2de50513          	addi	a0,a0,734 # 8001f7c8 <itable>
    800034f2:	ffffd097          	auipc	ra,0xffffd
    800034f6:	7a6080e7          	jalr	1958(ra) # 80000c98 <release>
}
    800034fa:	854a                	mv	a0,s2
    800034fc:	70a2                	ld	ra,40(sp)
    800034fe:	7402                	ld	s0,32(sp)
    80003500:	64e2                	ld	s1,24(sp)
    80003502:	6942                	ld	s2,16(sp)
    80003504:	69a2                	ld	s3,8(sp)
    80003506:	6a02                	ld	s4,0(sp)
    80003508:	6145                	addi	sp,sp,48
    8000350a:	8082                	ret
    panic("iget: no inodes");
    8000350c:	00005517          	auipc	a0,0x5
    80003510:	0a450513          	addi	a0,a0,164 # 800085b0 <syscalls+0x138>
    80003514:	ffffd097          	auipc	ra,0xffffd
    80003518:	02a080e7          	jalr	42(ra) # 8000053e <panic>

000000008000351c <fsinit>:
fsinit(int dev) {
    8000351c:	7179                	addi	sp,sp,-48
    8000351e:	f406                	sd	ra,40(sp)
    80003520:	f022                	sd	s0,32(sp)
    80003522:	ec26                	sd	s1,24(sp)
    80003524:	e84a                	sd	s2,16(sp)
    80003526:	e44e                	sd	s3,8(sp)
    80003528:	1800                	addi	s0,sp,48
    8000352a:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000352c:	4585                	li	a1,1
    8000352e:	00000097          	auipc	ra,0x0
    80003532:	a64080e7          	jalr	-1436(ra) # 80002f92 <bread>
    80003536:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003538:	0001c997          	auipc	s3,0x1c
    8000353c:	27098993          	addi	s3,s3,624 # 8001f7a8 <sb>
    80003540:	02000613          	li	a2,32
    80003544:	05850593          	addi	a1,a0,88
    80003548:	854e                	mv	a0,s3
    8000354a:	ffffd097          	auipc	ra,0xffffd
    8000354e:	7f6080e7          	jalr	2038(ra) # 80000d40 <memmove>
  brelse(bp);
    80003552:	8526                	mv	a0,s1
    80003554:	00000097          	auipc	ra,0x0
    80003558:	b6e080e7          	jalr	-1170(ra) # 800030c2 <brelse>
  if(sb.magic != FSMAGIC)
    8000355c:	0009a703          	lw	a4,0(s3)
    80003560:	102037b7          	lui	a5,0x10203
    80003564:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003568:	02f71263          	bne	a4,a5,8000358c <fsinit+0x70>
  initlog(dev, &sb);
    8000356c:	0001c597          	auipc	a1,0x1c
    80003570:	23c58593          	addi	a1,a1,572 # 8001f7a8 <sb>
    80003574:	854a                	mv	a0,s2
    80003576:	00001097          	auipc	ra,0x1
    8000357a:	b4c080e7          	jalr	-1204(ra) # 800040c2 <initlog>
}
    8000357e:	70a2                	ld	ra,40(sp)
    80003580:	7402                	ld	s0,32(sp)
    80003582:	64e2                	ld	s1,24(sp)
    80003584:	6942                	ld	s2,16(sp)
    80003586:	69a2                	ld	s3,8(sp)
    80003588:	6145                	addi	sp,sp,48
    8000358a:	8082                	ret
    panic("invalid file system");
    8000358c:	00005517          	auipc	a0,0x5
    80003590:	03450513          	addi	a0,a0,52 # 800085c0 <syscalls+0x148>
    80003594:	ffffd097          	auipc	ra,0xffffd
    80003598:	faa080e7          	jalr	-86(ra) # 8000053e <panic>

000000008000359c <iinit>:
{
    8000359c:	7179                	addi	sp,sp,-48
    8000359e:	f406                	sd	ra,40(sp)
    800035a0:	f022                	sd	s0,32(sp)
    800035a2:	ec26                	sd	s1,24(sp)
    800035a4:	e84a                	sd	s2,16(sp)
    800035a6:	e44e                	sd	s3,8(sp)
    800035a8:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800035aa:	00005597          	auipc	a1,0x5
    800035ae:	02e58593          	addi	a1,a1,46 # 800085d8 <syscalls+0x160>
    800035b2:	0001c517          	auipc	a0,0x1c
    800035b6:	21650513          	addi	a0,a0,534 # 8001f7c8 <itable>
    800035ba:	ffffd097          	auipc	ra,0xffffd
    800035be:	59a080e7          	jalr	1434(ra) # 80000b54 <initlock>
  for(i = 0; i < NINODE; i++) {
    800035c2:	0001c497          	auipc	s1,0x1c
    800035c6:	22e48493          	addi	s1,s1,558 # 8001f7f0 <itable+0x28>
    800035ca:	0001e997          	auipc	s3,0x1e
    800035ce:	cb698993          	addi	s3,s3,-842 # 80021280 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800035d2:	00005917          	auipc	s2,0x5
    800035d6:	00e90913          	addi	s2,s2,14 # 800085e0 <syscalls+0x168>
    800035da:	85ca                	mv	a1,s2
    800035dc:	8526                	mv	a0,s1
    800035de:	00001097          	auipc	ra,0x1
    800035e2:	e46080e7          	jalr	-442(ra) # 80004424 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800035e6:	08848493          	addi	s1,s1,136
    800035ea:	ff3498e3          	bne	s1,s3,800035da <iinit+0x3e>
}
    800035ee:	70a2                	ld	ra,40(sp)
    800035f0:	7402                	ld	s0,32(sp)
    800035f2:	64e2                	ld	s1,24(sp)
    800035f4:	6942                	ld	s2,16(sp)
    800035f6:	69a2                	ld	s3,8(sp)
    800035f8:	6145                	addi	sp,sp,48
    800035fa:	8082                	ret

00000000800035fc <ialloc>:
{
    800035fc:	715d                	addi	sp,sp,-80
    800035fe:	e486                	sd	ra,72(sp)
    80003600:	e0a2                	sd	s0,64(sp)
    80003602:	fc26                	sd	s1,56(sp)
    80003604:	f84a                	sd	s2,48(sp)
    80003606:	f44e                	sd	s3,40(sp)
    80003608:	f052                	sd	s4,32(sp)
    8000360a:	ec56                	sd	s5,24(sp)
    8000360c:	e85a                	sd	s6,16(sp)
    8000360e:	e45e                	sd	s7,8(sp)
    80003610:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003612:	0001c717          	auipc	a4,0x1c
    80003616:	1a272703          	lw	a4,418(a4) # 8001f7b4 <sb+0xc>
    8000361a:	4785                	li	a5,1
    8000361c:	04e7fa63          	bgeu	a5,a4,80003670 <ialloc+0x74>
    80003620:	8aaa                	mv	s5,a0
    80003622:	8bae                	mv	s7,a1
    80003624:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003626:	0001ca17          	auipc	s4,0x1c
    8000362a:	182a0a13          	addi	s4,s4,386 # 8001f7a8 <sb>
    8000362e:	00048b1b          	sext.w	s6,s1
    80003632:	0044d593          	srli	a1,s1,0x4
    80003636:	018a2783          	lw	a5,24(s4)
    8000363a:	9dbd                	addw	a1,a1,a5
    8000363c:	8556                	mv	a0,s5
    8000363e:	00000097          	auipc	ra,0x0
    80003642:	954080e7          	jalr	-1708(ra) # 80002f92 <bread>
    80003646:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003648:	05850993          	addi	s3,a0,88
    8000364c:	00f4f793          	andi	a5,s1,15
    80003650:	079a                	slli	a5,a5,0x6
    80003652:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003654:	00099783          	lh	a5,0(s3)
    80003658:	c785                	beqz	a5,80003680 <ialloc+0x84>
    brelse(bp);
    8000365a:	00000097          	auipc	ra,0x0
    8000365e:	a68080e7          	jalr	-1432(ra) # 800030c2 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003662:	0485                	addi	s1,s1,1
    80003664:	00ca2703          	lw	a4,12(s4)
    80003668:	0004879b          	sext.w	a5,s1
    8000366c:	fce7e1e3          	bltu	a5,a4,8000362e <ialloc+0x32>
  panic("ialloc: no inodes");
    80003670:	00005517          	auipc	a0,0x5
    80003674:	f7850513          	addi	a0,a0,-136 # 800085e8 <syscalls+0x170>
    80003678:	ffffd097          	auipc	ra,0xffffd
    8000367c:	ec6080e7          	jalr	-314(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003680:	04000613          	li	a2,64
    80003684:	4581                	li	a1,0
    80003686:	854e                	mv	a0,s3
    80003688:	ffffd097          	auipc	ra,0xffffd
    8000368c:	658080e7          	jalr	1624(ra) # 80000ce0 <memset>
      dip->type = type;
    80003690:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003694:	854a                	mv	a0,s2
    80003696:	00001097          	auipc	ra,0x1
    8000369a:	ca8080e7          	jalr	-856(ra) # 8000433e <log_write>
      brelse(bp);
    8000369e:	854a                	mv	a0,s2
    800036a0:	00000097          	auipc	ra,0x0
    800036a4:	a22080e7          	jalr	-1502(ra) # 800030c2 <brelse>
      return iget(dev, inum);
    800036a8:	85da                	mv	a1,s6
    800036aa:	8556                	mv	a0,s5
    800036ac:	00000097          	auipc	ra,0x0
    800036b0:	db4080e7          	jalr	-588(ra) # 80003460 <iget>
}
    800036b4:	60a6                	ld	ra,72(sp)
    800036b6:	6406                	ld	s0,64(sp)
    800036b8:	74e2                	ld	s1,56(sp)
    800036ba:	7942                	ld	s2,48(sp)
    800036bc:	79a2                	ld	s3,40(sp)
    800036be:	7a02                	ld	s4,32(sp)
    800036c0:	6ae2                	ld	s5,24(sp)
    800036c2:	6b42                	ld	s6,16(sp)
    800036c4:	6ba2                	ld	s7,8(sp)
    800036c6:	6161                	addi	sp,sp,80
    800036c8:	8082                	ret

00000000800036ca <iupdate>:
{
    800036ca:	1101                	addi	sp,sp,-32
    800036cc:	ec06                	sd	ra,24(sp)
    800036ce:	e822                	sd	s0,16(sp)
    800036d0:	e426                	sd	s1,8(sp)
    800036d2:	e04a                	sd	s2,0(sp)
    800036d4:	1000                	addi	s0,sp,32
    800036d6:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800036d8:	415c                	lw	a5,4(a0)
    800036da:	0047d79b          	srliw	a5,a5,0x4
    800036de:	0001c597          	auipc	a1,0x1c
    800036e2:	0e25a583          	lw	a1,226(a1) # 8001f7c0 <sb+0x18>
    800036e6:	9dbd                	addw	a1,a1,a5
    800036e8:	4108                	lw	a0,0(a0)
    800036ea:	00000097          	auipc	ra,0x0
    800036ee:	8a8080e7          	jalr	-1880(ra) # 80002f92 <bread>
    800036f2:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800036f4:	05850793          	addi	a5,a0,88
    800036f8:	40c8                	lw	a0,4(s1)
    800036fa:	893d                	andi	a0,a0,15
    800036fc:	051a                	slli	a0,a0,0x6
    800036fe:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003700:	04449703          	lh	a4,68(s1)
    80003704:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003708:	04649703          	lh	a4,70(s1)
    8000370c:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003710:	04849703          	lh	a4,72(s1)
    80003714:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003718:	04a49703          	lh	a4,74(s1)
    8000371c:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003720:	44f8                	lw	a4,76(s1)
    80003722:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003724:	03400613          	li	a2,52
    80003728:	05048593          	addi	a1,s1,80
    8000372c:	0531                	addi	a0,a0,12
    8000372e:	ffffd097          	auipc	ra,0xffffd
    80003732:	612080e7          	jalr	1554(ra) # 80000d40 <memmove>
  log_write(bp);
    80003736:	854a                	mv	a0,s2
    80003738:	00001097          	auipc	ra,0x1
    8000373c:	c06080e7          	jalr	-1018(ra) # 8000433e <log_write>
  brelse(bp);
    80003740:	854a                	mv	a0,s2
    80003742:	00000097          	auipc	ra,0x0
    80003746:	980080e7          	jalr	-1664(ra) # 800030c2 <brelse>
}
    8000374a:	60e2                	ld	ra,24(sp)
    8000374c:	6442                	ld	s0,16(sp)
    8000374e:	64a2                	ld	s1,8(sp)
    80003750:	6902                	ld	s2,0(sp)
    80003752:	6105                	addi	sp,sp,32
    80003754:	8082                	ret

0000000080003756 <idup>:
{
    80003756:	1101                	addi	sp,sp,-32
    80003758:	ec06                	sd	ra,24(sp)
    8000375a:	e822                	sd	s0,16(sp)
    8000375c:	e426                	sd	s1,8(sp)
    8000375e:	1000                	addi	s0,sp,32
    80003760:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003762:	0001c517          	auipc	a0,0x1c
    80003766:	06650513          	addi	a0,a0,102 # 8001f7c8 <itable>
    8000376a:	ffffd097          	auipc	ra,0xffffd
    8000376e:	47a080e7          	jalr	1146(ra) # 80000be4 <acquire>
  ip->ref++;
    80003772:	449c                	lw	a5,8(s1)
    80003774:	2785                	addiw	a5,a5,1
    80003776:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003778:	0001c517          	auipc	a0,0x1c
    8000377c:	05050513          	addi	a0,a0,80 # 8001f7c8 <itable>
    80003780:	ffffd097          	auipc	ra,0xffffd
    80003784:	518080e7          	jalr	1304(ra) # 80000c98 <release>
}
    80003788:	8526                	mv	a0,s1
    8000378a:	60e2                	ld	ra,24(sp)
    8000378c:	6442                	ld	s0,16(sp)
    8000378e:	64a2                	ld	s1,8(sp)
    80003790:	6105                	addi	sp,sp,32
    80003792:	8082                	ret

0000000080003794 <ilock>:
{
    80003794:	1101                	addi	sp,sp,-32
    80003796:	ec06                	sd	ra,24(sp)
    80003798:	e822                	sd	s0,16(sp)
    8000379a:	e426                	sd	s1,8(sp)
    8000379c:	e04a                	sd	s2,0(sp)
    8000379e:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800037a0:	c115                	beqz	a0,800037c4 <ilock+0x30>
    800037a2:	84aa                	mv	s1,a0
    800037a4:	451c                	lw	a5,8(a0)
    800037a6:	00f05f63          	blez	a5,800037c4 <ilock+0x30>
  acquiresleep(&ip->lock);
    800037aa:	0541                	addi	a0,a0,16
    800037ac:	00001097          	auipc	ra,0x1
    800037b0:	cb2080e7          	jalr	-846(ra) # 8000445e <acquiresleep>
  if(ip->valid == 0){
    800037b4:	40bc                	lw	a5,64(s1)
    800037b6:	cf99                	beqz	a5,800037d4 <ilock+0x40>
}
    800037b8:	60e2                	ld	ra,24(sp)
    800037ba:	6442                	ld	s0,16(sp)
    800037bc:	64a2                	ld	s1,8(sp)
    800037be:	6902                	ld	s2,0(sp)
    800037c0:	6105                	addi	sp,sp,32
    800037c2:	8082                	ret
    panic("ilock");
    800037c4:	00005517          	auipc	a0,0x5
    800037c8:	e3c50513          	addi	a0,a0,-452 # 80008600 <syscalls+0x188>
    800037cc:	ffffd097          	auipc	ra,0xffffd
    800037d0:	d72080e7          	jalr	-654(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800037d4:	40dc                	lw	a5,4(s1)
    800037d6:	0047d79b          	srliw	a5,a5,0x4
    800037da:	0001c597          	auipc	a1,0x1c
    800037de:	fe65a583          	lw	a1,-26(a1) # 8001f7c0 <sb+0x18>
    800037e2:	9dbd                	addw	a1,a1,a5
    800037e4:	4088                	lw	a0,0(s1)
    800037e6:	fffff097          	auipc	ra,0xfffff
    800037ea:	7ac080e7          	jalr	1964(ra) # 80002f92 <bread>
    800037ee:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800037f0:	05850593          	addi	a1,a0,88
    800037f4:	40dc                	lw	a5,4(s1)
    800037f6:	8bbd                	andi	a5,a5,15
    800037f8:	079a                	slli	a5,a5,0x6
    800037fa:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800037fc:	00059783          	lh	a5,0(a1)
    80003800:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003804:	00259783          	lh	a5,2(a1)
    80003808:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    8000380c:	00459783          	lh	a5,4(a1)
    80003810:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003814:	00659783          	lh	a5,6(a1)
    80003818:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    8000381c:	459c                	lw	a5,8(a1)
    8000381e:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003820:	03400613          	li	a2,52
    80003824:	05b1                	addi	a1,a1,12
    80003826:	05048513          	addi	a0,s1,80
    8000382a:	ffffd097          	auipc	ra,0xffffd
    8000382e:	516080e7          	jalr	1302(ra) # 80000d40 <memmove>
    brelse(bp);
    80003832:	854a                	mv	a0,s2
    80003834:	00000097          	auipc	ra,0x0
    80003838:	88e080e7          	jalr	-1906(ra) # 800030c2 <brelse>
    ip->valid = 1;
    8000383c:	4785                	li	a5,1
    8000383e:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003840:	04449783          	lh	a5,68(s1)
    80003844:	fbb5                	bnez	a5,800037b8 <ilock+0x24>
      panic("ilock: no type");
    80003846:	00005517          	auipc	a0,0x5
    8000384a:	dc250513          	addi	a0,a0,-574 # 80008608 <syscalls+0x190>
    8000384e:	ffffd097          	auipc	ra,0xffffd
    80003852:	cf0080e7          	jalr	-784(ra) # 8000053e <panic>

0000000080003856 <iunlock>:
{
    80003856:	1101                	addi	sp,sp,-32
    80003858:	ec06                	sd	ra,24(sp)
    8000385a:	e822                	sd	s0,16(sp)
    8000385c:	e426                	sd	s1,8(sp)
    8000385e:	e04a                	sd	s2,0(sp)
    80003860:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003862:	c905                	beqz	a0,80003892 <iunlock+0x3c>
    80003864:	84aa                	mv	s1,a0
    80003866:	01050913          	addi	s2,a0,16
    8000386a:	854a                	mv	a0,s2
    8000386c:	00001097          	auipc	ra,0x1
    80003870:	c8c080e7          	jalr	-884(ra) # 800044f8 <holdingsleep>
    80003874:	cd19                	beqz	a0,80003892 <iunlock+0x3c>
    80003876:	449c                	lw	a5,8(s1)
    80003878:	00f05d63          	blez	a5,80003892 <iunlock+0x3c>
  releasesleep(&ip->lock);
    8000387c:	854a                	mv	a0,s2
    8000387e:	00001097          	auipc	ra,0x1
    80003882:	c36080e7          	jalr	-970(ra) # 800044b4 <releasesleep>
}
    80003886:	60e2                	ld	ra,24(sp)
    80003888:	6442                	ld	s0,16(sp)
    8000388a:	64a2                	ld	s1,8(sp)
    8000388c:	6902                	ld	s2,0(sp)
    8000388e:	6105                	addi	sp,sp,32
    80003890:	8082                	ret
    panic("iunlock");
    80003892:	00005517          	auipc	a0,0x5
    80003896:	d8650513          	addi	a0,a0,-634 # 80008618 <syscalls+0x1a0>
    8000389a:	ffffd097          	auipc	ra,0xffffd
    8000389e:	ca4080e7          	jalr	-860(ra) # 8000053e <panic>

00000000800038a2 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800038a2:	7179                	addi	sp,sp,-48
    800038a4:	f406                	sd	ra,40(sp)
    800038a6:	f022                	sd	s0,32(sp)
    800038a8:	ec26                	sd	s1,24(sp)
    800038aa:	e84a                	sd	s2,16(sp)
    800038ac:	e44e                	sd	s3,8(sp)
    800038ae:	e052                	sd	s4,0(sp)
    800038b0:	1800                	addi	s0,sp,48
    800038b2:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800038b4:	05050493          	addi	s1,a0,80
    800038b8:	08050913          	addi	s2,a0,128
    800038bc:	a021                	j	800038c4 <itrunc+0x22>
    800038be:	0491                	addi	s1,s1,4
    800038c0:	01248d63          	beq	s1,s2,800038da <itrunc+0x38>
    if(ip->addrs[i]){
    800038c4:	408c                	lw	a1,0(s1)
    800038c6:	dde5                	beqz	a1,800038be <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800038c8:	0009a503          	lw	a0,0(s3)
    800038cc:	00000097          	auipc	ra,0x0
    800038d0:	90c080e7          	jalr	-1780(ra) # 800031d8 <bfree>
      ip->addrs[i] = 0;
    800038d4:	0004a023          	sw	zero,0(s1)
    800038d8:	b7dd                	j	800038be <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800038da:	0809a583          	lw	a1,128(s3)
    800038de:	e185                	bnez	a1,800038fe <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800038e0:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800038e4:	854e                	mv	a0,s3
    800038e6:	00000097          	auipc	ra,0x0
    800038ea:	de4080e7          	jalr	-540(ra) # 800036ca <iupdate>
}
    800038ee:	70a2                	ld	ra,40(sp)
    800038f0:	7402                	ld	s0,32(sp)
    800038f2:	64e2                	ld	s1,24(sp)
    800038f4:	6942                	ld	s2,16(sp)
    800038f6:	69a2                	ld	s3,8(sp)
    800038f8:	6a02                	ld	s4,0(sp)
    800038fa:	6145                	addi	sp,sp,48
    800038fc:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800038fe:	0009a503          	lw	a0,0(s3)
    80003902:	fffff097          	auipc	ra,0xfffff
    80003906:	690080e7          	jalr	1680(ra) # 80002f92 <bread>
    8000390a:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    8000390c:	05850493          	addi	s1,a0,88
    80003910:	45850913          	addi	s2,a0,1112
    80003914:	a811                	j	80003928 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003916:	0009a503          	lw	a0,0(s3)
    8000391a:	00000097          	auipc	ra,0x0
    8000391e:	8be080e7          	jalr	-1858(ra) # 800031d8 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003922:	0491                	addi	s1,s1,4
    80003924:	01248563          	beq	s1,s2,8000392e <itrunc+0x8c>
      if(a[j])
    80003928:	408c                	lw	a1,0(s1)
    8000392a:	dde5                	beqz	a1,80003922 <itrunc+0x80>
    8000392c:	b7ed                	j	80003916 <itrunc+0x74>
    brelse(bp);
    8000392e:	8552                	mv	a0,s4
    80003930:	fffff097          	auipc	ra,0xfffff
    80003934:	792080e7          	jalr	1938(ra) # 800030c2 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003938:	0809a583          	lw	a1,128(s3)
    8000393c:	0009a503          	lw	a0,0(s3)
    80003940:	00000097          	auipc	ra,0x0
    80003944:	898080e7          	jalr	-1896(ra) # 800031d8 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003948:	0809a023          	sw	zero,128(s3)
    8000394c:	bf51                	j	800038e0 <itrunc+0x3e>

000000008000394e <iput>:
{
    8000394e:	1101                	addi	sp,sp,-32
    80003950:	ec06                	sd	ra,24(sp)
    80003952:	e822                	sd	s0,16(sp)
    80003954:	e426                	sd	s1,8(sp)
    80003956:	e04a                	sd	s2,0(sp)
    80003958:	1000                	addi	s0,sp,32
    8000395a:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000395c:	0001c517          	auipc	a0,0x1c
    80003960:	e6c50513          	addi	a0,a0,-404 # 8001f7c8 <itable>
    80003964:	ffffd097          	auipc	ra,0xffffd
    80003968:	280080e7          	jalr	640(ra) # 80000be4 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000396c:	4498                	lw	a4,8(s1)
    8000396e:	4785                	li	a5,1
    80003970:	02f70363          	beq	a4,a5,80003996 <iput+0x48>
  ip->ref--;
    80003974:	449c                	lw	a5,8(s1)
    80003976:	37fd                	addiw	a5,a5,-1
    80003978:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000397a:	0001c517          	auipc	a0,0x1c
    8000397e:	e4e50513          	addi	a0,a0,-434 # 8001f7c8 <itable>
    80003982:	ffffd097          	auipc	ra,0xffffd
    80003986:	316080e7          	jalr	790(ra) # 80000c98 <release>
}
    8000398a:	60e2                	ld	ra,24(sp)
    8000398c:	6442                	ld	s0,16(sp)
    8000398e:	64a2                	ld	s1,8(sp)
    80003990:	6902                	ld	s2,0(sp)
    80003992:	6105                	addi	sp,sp,32
    80003994:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003996:	40bc                	lw	a5,64(s1)
    80003998:	dff1                	beqz	a5,80003974 <iput+0x26>
    8000399a:	04a49783          	lh	a5,74(s1)
    8000399e:	fbf9                	bnez	a5,80003974 <iput+0x26>
    acquiresleep(&ip->lock);
    800039a0:	01048913          	addi	s2,s1,16
    800039a4:	854a                	mv	a0,s2
    800039a6:	00001097          	auipc	ra,0x1
    800039aa:	ab8080e7          	jalr	-1352(ra) # 8000445e <acquiresleep>
    release(&itable.lock);
    800039ae:	0001c517          	auipc	a0,0x1c
    800039b2:	e1a50513          	addi	a0,a0,-486 # 8001f7c8 <itable>
    800039b6:	ffffd097          	auipc	ra,0xffffd
    800039ba:	2e2080e7          	jalr	738(ra) # 80000c98 <release>
    itrunc(ip);
    800039be:	8526                	mv	a0,s1
    800039c0:	00000097          	auipc	ra,0x0
    800039c4:	ee2080e7          	jalr	-286(ra) # 800038a2 <itrunc>
    ip->type = 0;
    800039c8:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800039cc:	8526                	mv	a0,s1
    800039ce:	00000097          	auipc	ra,0x0
    800039d2:	cfc080e7          	jalr	-772(ra) # 800036ca <iupdate>
    ip->valid = 0;
    800039d6:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800039da:	854a                	mv	a0,s2
    800039dc:	00001097          	auipc	ra,0x1
    800039e0:	ad8080e7          	jalr	-1320(ra) # 800044b4 <releasesleep>
    acquire(&itable.lock);
    800039e4:	0001c517          	auipc	a0,0x1c
    800039e8:	de450513          	addi	a0,a0,-540 # 8001f7c8 <itable>
    800039ec:	ffffd097          	auipc	ra,0xffffd
    800039f0:	1f8080e7          	jalr	504(ra) # 80000be4 <acquire>
    800039f4:	b741                	j	80003974 <iput+0x26>

00000000800039f6 <iunlockput>:
{
    800039f6:	1101                	addi	sp,sp,-32
    800039f8:	ec06                	sd	ra,24(sp)
    800039fa:	e822                	sd	s0,16(sp)
    800039fc:	e426                	sd	s1,8(sp)
    800039fe:	1000                	addi	s0,sp,32
    80003a00:	84aa                	mv	s1,a0
  iunlock(ip);
    80003a02:	00000097          	auipc	ra,0x0
    80003a06:	e54080e7          	jalr	-428(ra) # 80003856 <iunlock>
  iput(ip);
    80003a0a:	8526                	mv	a0,s1
    80003a0c:	00000097          	auipc	ra,0x0
    80003a10:	f42080e7          	jalr	-190(ra) # 8000394e <iput>
}
    80003a14:	60e2                	ld	ra,24(sp)
    80003a16:	6442                	ld	s0,16(sp)
    80003a18:	64a2                	ld	s1,8(sp)
    80003a1a:	6105                	addi	sp,sp,32
    80003a1c:	8082                	ret

0000000080003a1e <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003a1e:	1141                	addi	sp,sp,-16
    80003a20:	e422                	sd	s0,8(sp)
    80003a22:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003a24:	411c                	lw	a5,0(a0)
    80003a26:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003a28:	415c                	lw	a5,4(a0)
    80003a2a:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003a2c:	04451783          	lh	a5,68(a0)
    80003a30:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003a34:	04a51783          	lh	a5,74(a0)
    80003a38:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003a3c:	04c56783          	lwu	a5,76(a0)
    80003a40:	e99c                	sd	a5,16(a1)
}
    80003a42:	6422                	ld	s0,8(sp)
    80003a44:	0141                	addi	sp,sp,16
    80003a46:	8082                	ret

0000000080003a48 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a48:	457c                	lw	a5,76(a0)
    80003a4a:	0ed7e963          	bltu	a5,a3,80003b3c <readi+0xf4>
{
    80003a4e:	7159                	addi	sp,sp,-112
    80003a50:	f486                	sd	ra,104(sp)
    80003a52:	f0a2                	sd	s0,96(sp)
    80003a54:	eca6                	sd	s1,88(sp)
    80003a56:	e8ca                	sd	s2,80(sp)
    80003a58:	e4ce                	sd	s3,72(sp)
    80003a5a:	e0d2                	sd	s4,64(sp)
    80003a5c:	fc56                	sd	s5,56(sp)
    80003a5e:	f85a                	sd	s6,48(sp)
    80003a60:	f45e                	sd	s7,40(sp)
    80003a62:	f062                	sd	s8,32(sp)
    80003a64:	ec66                	sd	s9,24(sp)
    80003a66:	e86a                	sd	s10,16(sp)
    80003a68:	e46e                	sd	s11,8(sp)
    80003a6a:	1880                	addi	s0,sp,112
    80003a6c:	8baa                	mv	s7,a0
    80003a6e:	8c2e                	mv	s8,a1
    80003a70:	8ab2                	mv	s5,a2
    80003a72:	84b6                	mv	s1,a3
    80003a74:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003a76:	9f35                	addw	a4,a4,a3
    return 0;
    80003a78:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003a7a:	0ad76063          	bltu	a4,a3,80003b1a <readi+0xd2>
  if(off + n > ip->size)
    80003a7e:	00e7f463          	bgeu	a5,a4,80003a86 <readi+0x3e>
    n = ip->size - off;
    80003a82:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a86:	0a0b0963          	beqz	s6,80003b38 <readi+0xf0>
    80003a8a:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a8c:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003a90:	5cfd                	li	s9,-1
    80003a92:	a82d                	j	80003acc <readi+0x84>
    80003a94:	020a1d93          	slli	s11,s4,0x20
    80003a98:	020ddd93          	srli	s11,s11,0x20
    80003a9c:	05890613          	addi	a2,s2,88
    80003aa0:	86ee                	mv	a3,s11
    80003aa2:	963a                	add	a2,a2,a4
    80003aa4:	85d6                	mv	a1,s5
    80003aa6:	8562                	mv	a0,s8
    80003aa8:	fffff097          	auipc	ra,0xfffff
    80003aac:	a4c080e7          	jalr	-1460(ra) # 800024f4 <either_copyout>
    80003ab0:	05950d63          	beq	a0,s9,80003b0a <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003ab4:	854a                	mv	a0,s2
    80003ab6:	fffff097          	auipc	ra,0xfffff
    80003aba:	60c080e7          	jalr	1548(ra) # 800030c2 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003abe:	013a09bb          	addw	s3,s4,s3
    80003ac2:	009a04bb          	addw	s1,s4,s1
    80003ac6:	9aee                	add	s5,s5,s11
    80003ac8:	0569f763          	bgeu	s3,s6,80003b16 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003acc:	000ba903          	lw	s2,0(s7)
    80003ad0:	00a4d59b          	srliw	a1,s1,0xa
    80003ad4:	855e                	mv	a0,s7
    80003ad6:	00000097          	auipc	ra,0x0
    80003ada:	8b0080e7          	jalr	-1872(ra) # 80003386 <bmap>
    80003ade:	0005059b          	sext.w	a1,a0
    80003ae2:	854a                	mv	a0,s2
    80003ae4:	fffff097          	auipc	ra,0xfffff
    80003ae8:	4ae080e7          	jalr	1198(ra) # 80002f92 <bread>
    80003aec:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003aee:	3ff4f713          	andi	a4,s1,1023
    80003af2:	40ed07bb          	subw	a5,s10,a4
    80003af6:	413b06bb          	subw	a3,s6,s3
    80003afa:	8a3e                	mv	s4,a5
    80003afc:	2781                	sext.w	a5,a5
    80003afe:	0006861b          	sext.w	a2,a3
    80003b02:	f8f679e3          	bgeu	a2,a5,80003a94 <readi+0x4c>
    80003b06:	8a36                	mv	s4,a3
    80003b08:	b771                	j	80003a94 <readi+0x4c>
      brelse(bp);
    80003b0a:	854a                	mv	a0,s2
    80003b0c:	fffff097          	auipc	ra,0xfffff
    80003b10:	5b6080e7          	jalr	1462(ra) # 800030c2 <brelse>
      tot = -1;
    80003b14:	59fd                	li	s3,-1
  }
  return tot;
    80003b16:	0009851b          	sext.w	a0,s3
}
    80003b1a:	70a6                	ld	ra,104(sp)
    80003b1c:	7406                	ld	s0,96(sp)
    80003b1e:	64e6                	ld	s1,88(sp)
    80003b20:	6946                	ld	s2,80(sp)
    80003b22:	69a6                	ld	s3,72(sp)
    80003b24:	6a06                	ld	s4,64(sp)
    80003b26:	7ae2                	ld	s5,56(sp)
    80003b28:	7b42                	ld	s6,48(sp)
    80003b2a:	7ba2                	ld	s7,40(sp)
    80003b2c:	7c02                	ld	s8,32(sp)
    80003b2e:	6ce2                	ld	s9,24(sp)
    80003b30:	6d42                	ld	s10,16(sp)
    80003b32:	6da2                	ld	s11,8(sp)
    80003b34:	6165                	addi	sp,sp,112
    80003b36:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b38:	89da                	mv	s3,s6
    80003b3a:	bff1                	j	80003b16 <readi+0xce>
    return 0;
    80003b3c:	4501                	li	a0,0
}
    80003b3e:	8082                	ret

0000000080003b40 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b40:	457c                	lw	a5,76(a0)
    80003b42:	10d7e863          	bltu	a5,a3,80003c52 <writei+0x112>
{
    80003b46:	7159                	addi	sp,sp,-112
    80003b48:	f486                	sd	ra,104(sp)
    80003b4a:	f0a2                	sd	s0,96(sp)
    80003b4c:	eca6                	sd	s1,88(sp)
    80003b4e:	e8ca                	sd	s2,80(sp)
    80003b50:	e4ce                	sd	s3,72(sp)
    80003b52:	e0d2                	sd	s4,64(sp)
    80003b54:	fc56                	sd	s5,56(sp)
    80003b56:	f85a                	sd	s6,48(sp)
    80003b58:	f45e                	sd	s7,40(sp)
    80003b5a:	f062                	sd	s8,32(sp)
    80003b5c:	ec66                	sd	s9,24(sp)
    80003b5e:	e86a                	sd	s10,16(sp)
    80003b60:	e46e                	sd	s11,8(sp)
    80003b62:	1880                	addi	s0,sp,112
    80003b64:	8b2a                	mv	s6,a0
    80003b66:	8c2e                	mv	s8,a1
    80003b68:	8ab2                	mv	s5,a2
    80003b6a:	8936                	mv	s2,a3
    80003b6c:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003b6e:	00e687bb          	addw	a5,a3,a4
    80003b72:	0ed7e263          	bltu	a5,a3,80003c56 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003b76:	00043737          	lui	a4,0x43
    80003b7a:	0ef76063          	bltu	a4,a5,80003c5a <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b7e:	0c0b8863          	beqz	s7,80003c4e <writei+0x10e>
    80003b82:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b84:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003b88:	5cfd                	li	s9,-1
    80003b8a:	a091                	j	80003bce <writei+0x8e>
    80003b8c:	02099d93          	slli	s11,s3,0x20
    80003b90:	020ddd93          	srli	s11,s11,0x20
    80003b94:	05848513          	addi	a0,s1,88
    80003b98:	86ee                	mv	a3,s11
    80003b9a:	8656                	mv	a2,s5
    80003b9c:	85e2                	mv	a1,s8
    80003b9e:	953a                	add	a0,a0,a4
    80003ba0:	fffff097          	auipc	ra,0xfffff
    80003ba4:	9aa080e7          	jalr	-1622(ra) # 8000254a <either_copyin>
    80003ba8:	07950263          	beq	a0,s9,80003c0c <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003bac:	8526                	mv	a0,s1
    80003bae:	00000097          	auipc	ra,0x0
    80003bb2:	790080e7          	jalr	1936(ra) # 8000433e <log_write>
    brelse(bp);
    80003bb6:	8526                	mv	a0,s1
    80003bb8:	fffff097          	auipc	ra,0xfffff
    80003bbc:	50a080e7          	jalr	1290(ra) # 800030c2 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003bc0:	01498a3b          	addw	s4,s3,s4
    80003bc4:	0129893b          	addw	s2,s3,s2
    80003bc8:	9aee                	add	s5,s5,s11
    80003bca:	057a7663          	bgeu	s4,s7,80003c16 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003bce:	000b2483          	lw	s1,0(s6)
    80003bd2:	00a9559b          	srliw	a1,s2,0xa
    80003bd6:	855a                	mv	a0,s6
    80003bd8:	fffff097          	auipc	ra,0xfffff
    80003bdc:	7ae080e7          	jalr	1966(ra) # 80003386 <bmap>
    80003be0:	0005059b          	sext.w	a1,a0
    80003be4:	8526                	mv	a0,s1
    80003be6:	fffff097          	auipc	ra,0xfffff
    80003bea:	3ac080e7          	jalr	940(ra) # 80002f92 <bread>
    80003bee:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bf0:	3ff97713          	andi	a4,s2,1023
    80003bf4:	40ed07bb          	subw	a5,s10,a4
    80003bf8:	414b86bb          	subw	a3,s7,s4
    80003bfc:	89be                	mv	s3,a5
    80003bfe:	2781                	sext.w	a5,a5
    80003c00:	0006861b          	sext.w	a2,a3
    80003c04:	f8f674e3          	bgeu	a2,a5,80003b8c <writei+0x4c>
    80003c08:	89b6                	mv	s3,a3
    80003c0a:	b749                	j	80003b8c <writei+0x4c>
      brelse(bp);
    80003c0c:	8526                	mv	a0,s1
    80003c0e:	fffff097          	auipc	ra,0xfffff
    80003c12:	4b4080e7          	jalr	1204(ra) # 800030c2 <brelse>
  }

  if(off > ip->size)
    80003c16:	04cb2783          	lw	a5,76(s6)
    80003c1a:	0127f463          	bgeu	a5,s2,80003c22 <writei+0xe2>
    ip->size = off;
    80003c1e:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003c22:	855a                	mv	a0,s6
    80003c24:	00000097          	auipc	ra,0x0
    80003c28:	aa6080e7          	jalr	-1370(ra) # 800036ca <iupdate>

  return tot;
    80003c2c:	000a051b          	sext.w	a0,s4
}
    80003c30:	70a6                	ld	ra,104(sp)
    80003c32:	7406                	ld	s0,96(sp)
    80003c34:	64e6                	ld	s1,88(sp)
    80003c36:	6946                	ld	s2,80(sp)
    80003c38:	69a6                	ld	s3,72(sp)
    80003c3a:	6a06                	ld	s4,64(sp)
    80003c3c:	7ae2                	ld	s5,56(sp)
    80003c3e:	7b42                	ld	s6,48(sp)
    80003c40:	7ba2                	ld	s7,40(sp)
    80003c42:	7c02                	ld	s8,32(sp)
    80003c44:	6ce2                	ld	s9,24(sp)
    80003c46:	6d42                	ld	s10,16(sp)
    80003c48:	6da2                	ld	s11,8(sp)
    80003c4a:	6165                	addi	sp,sp,112
    80003c4c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c4e:	8a5e                	mv	s4,s7
    80003c50:	bfc9                	j	80003c22 <writei+0xe2>
    return -1;
    80003c52:	557d                	li	a0,-1
}
    80003c54:	8082                	ret
    return -1;
    80003c56:	557d                	li	a0,-1
    80003c58:	bfe1                	j	80003c30 <writei+0xf0>
    return -1;
    80003c5a:	557d                	li	a0,-1
    80003c5c:	bfd1                	j	80003c30 <writei+0xf0>

0000000080003c5e <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003c5e:	1141                	addi	sp,sp,-16
    80003c60:	e406                	sd	ra,8(sp)
    80003c62:	e022                	sd	s0,0(sp)
    80003c64:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003c66:	4639                	li	a2,14
    80003c68:	ffffd097          	auipc	ra,0xffffd
    80003c6c:	150080e7          	jalr	336(ra) # 80000db8 <strncmp>
}
    80003c70:	60a2                	ld	ra,8(sp)
    80003c72:	6402                	ld	s0,0(sp)
    80003c74:	0141                	addi	sp,sp,16
    80003c76:	8082                	ret

0000000080003c78 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003c78:	7139                	addi	sp,sp,-64
    80003c7a:	fc06                	sd	ra,56(sp)
    80003c7c:	f822                	sd	s0,48(sp)
    80003c7e:	f426                	sd	s1,40(sp)
    80003c80:	f04a                	sd	s2,32(sp)
    80003c82:	ec4e                	sd	s3,24(sp)
    80003c84:	e852                	sd	s4,16(sp)
    80003c86:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003c88:	04451703          	lh	a4,68(a0)
    80003c8c:	4785                	li	a5,1
    80003c8e:	00f71a63          	bne	a4,a5,80003ca2 <dirlookup+0x2a>
    80003c92:	892a                	mv	s2,a0
    80003c94:	89ae                	mv	s3,a1
    80003c96:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c98:	457c                	lw	a5,76(a0)
    80003c9a:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003c9c:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c9e:	e79d                	bnez	a5,80003ccc <dirlookup+0x54>
    80003ca0:	a8a5                	j	80003d18 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003ca2:	00005517          	auipc	a0,0x5
    80003ca6:	97e50513          	addi	a0,a0,-1666 # 80008620 <syscalls+0x1a8>
    80003caa:	ffffd097          	auipc	ra,0xffffd
    80003cae:	894080e7          	jalr	-1900(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003cb2:	00005517          	auipc	a0,0x5
    80003cb6:	98650513          	addi	a0,a0,-1658 # 80008638 <syscalls+0x1c0>
    80003cba:	ffffd097          	auipc	ra,0xffffd
    80003cbe:	884080e7          	jalr	-1916(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cc2:	24c1                	addiw	s1,s1,16
    80003cc4:	04c92783          	lw	a5,76(s2)
    80003cc8:	04f4f763          	bgeu	s1,a5,80003d16 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ccc:	4741                	li	a4,16
    80003cce:	86a6                	mv	a3,s1
    80003cd0:	fc040613          	addi	a2,s0,-64
    80003cd4:	4581                	li	a1,0
    80003cd6:	854a                	mv	a0,s2
    80003cd8:	00000097          	auipc	ra,0x0
    80003cdc:	d70080e7          	jalr	-656(ra) # 80003a48 <readi>
    80003ce0:	47c1                	li	a5,16
    80003ce2:	fcf518e3          	bne	a0,a5,80003cb2 <dirlookup+0x3a>
    if(de.inum == 0)
    80003ce6:	fc045783          	lhu	a5,-64(s0)
    80003cea:	dfe1                	beqz	a5,80003cc2 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003cec:	fc240593          	addi	a1,s0,-62
    80003cf0:	854e                	mv	a0,s3
    80003cf2:	00000097          	auipc	ra,0x0
    80003cf6:	f6c080e7          	jalr	-148(ra) # 80003c5e <namecmp>
    80003cfa:	f561                	bnez	a0,80003cc2 <dirlookup+0x4a>
      if(poff)
    80003cfc:	000a0463          	beqz	s4,80003d04 <dirlookup+0x8c>
        *poff = off;
    80003d00:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003d04:	fc045583          	lhu	a1,-64(s0)
    80003d08:	00092503          	lw	a0,0(s2)
    80003d0c:	fffff097          	auipc	ra,0xfffff
    80003d10:	754080e7          	jalr	1876(ra) # 80003460 <iget>
    80003d14:	a011                	j	80003d18 <dirlookup+0xa0>
  return 0;
    80003d16:	4501                	li	a0,0
}
    80003d18:	70e2                	ld	ra,56(sp)
    80003d1a:	7442                	ld	s0,48(sp)
    80003d1c:	74a2                	ld	s1,40(sp)
    80003d1e:	7902                	ld	s2,32(sp)
    80003d20:	69e2                	ld	s3,24(sp)
    80003d22:	6a42                	ld	s4,16(sp)
    80003d24:	6121                	addi	sp,sp,64
    80003d26:	8082                	ret

0000000080003d28 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003d28:	711d                	addi	sp,sp,-96
    80003d2a:	ec86                	sd	ra,88(sp)
    80003d2c:	e8a2                	sd	s0,80(sp)
    80003d2e:	e4a6                	sd	s1,72(sp)
    80003d30:	e0ca                	sd	s2,64(sp)
    80003d32:	fc4e                	sd	s3,56(sp)
    80003d34:	f852                	sd	s4,48(sp)
    80003d36:	f456                	sd	s5,40(sp)
    80003d38:	f05a                	sd	s6,32(sp)
    80003d3a:	ec5e                	sd	s7,24(sp)
    80003d3c:	e862                	sd	s8,16(sp)
    80003d3e:	e466                	sd	s9,8(sp)
    80003d40:	1080                	addi	s0,sp,96
    80003d42:	84aa                	mv	s1,a0
    80003d44:	8b2e                	mv	s6,a1
    80003d46:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003d48:	00054703          	lbu	a4,0(a0)
    80003d4c:	02f00793          	li	a5,47
    80003d50:	02f70363          	beq	a4,a5,80003d76 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003d54:	ffffe097          	auipc	ra,0xffffe
    80003d58:	d40080e7          	jalr	-704(ra) # 80001a94 <myproc>
    80003d5c:	15053503          	ld	a0,336(a0)
    80003d60:	00000097          	auipc	ra,0x0
    80003d64:	9f6080e7          	jalr	-1546(ra) # 80003756 <idup>
    80003d68:	89aa                	mv	s3,a0
  while(*path == '/')
    80003d6a:	02f00913          	li	s2,47
  len = path - s;
    80003d6e:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003d70:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003d72:	4c05                	li	s8,1
    80003d74:	a865                	j	80003e2c <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003d76:	4585                	li	a1,1
    80003d78:	4505                	li	a0,1
    80003d7a:	fffff097          	auipc	ra,0xfffff
    80003d7e:	6e6080e7          	jalr	1766(ra) # 80003460 <iget>
    80003d82:	89aa                	mv	s3,a0
    80003d84:	b7dd                	j	80003d6a <namex+0x42>
      iunlockput(ip);
    80003d86:	854e                	mv	a0,s3
    80003d88:	00000097          	auipc	ra,0x0
    80003d8c:	c6e080e7          	jalr	-914(ra) # 800039f6 <iunlockput>
      return 0;
    80003d90:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003d92:	854e                	mv	a0,s3
    80003d94:	60e6                	ld	ra,88(sp)
    80003d96:	6446                	ld	s0,80(sp)
    80003d98:	64a6                	ld	s1,72(sp)
    80003d9a:	6906                	ld	s2,64(sp)
    80003d9c:	79e2                	ld	s3,56(sp)
    80003d9e:	7a42                	ld	s4,48(sp)
    80003da0:	7aa2                	ld	s5,40(sp)
    80003da2:	7b02                	ld	s6,32(sp)
    80003da4:	6be2                	ld	s7,24(sp)
    80003da6:	6c42                	ld	s8,16(sp)
    80003da8:	6ca2                	ld	s9,8(sp)
    80003daa:	6125                	addi	sp,sp,96
    80003dac:	8082                	ret
      iunlock(ip);
    80003dae:	854e                	mv	a0,s3
    80003db0:	00000097          	auipc	ra,0x0
    80003db4:	aa6080e7          	jalr	-1370(ra) # 80003856 <iunlock>
      return ip;
    80003db8:	bfe9                	j	80003d92 <namex+0x6a>
      iunlockput(ip);
    80003dba:	854e                	mv	a0,s3
    80003dbc:	00000097          	auipc	ra,0x0
    80003dc0:	c3a080e7          	jalr	-966(ra) # 800039f6 <iunlockput>
      return 0;
    80003dc4:	89d2                	mv	s3,s4
    80003dc6:	b7f1                	j	80003d92 <namex+0x6a>
  len = path - s;
    80003dc8:	40b48633          	sub	a2,s1,a1
    80003dcc:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003dd0:	094cd463          	bge	s9,s4,80003e58 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003dd4:	4639                	li	a2,14
    80003dd6:	8556                	mv	a0,s5
    80003dd8:	ffffd097          	auipc	ra,0xffffd
    80003ddc:	f68080e7          	jalr	-152(ra) # 80000d40 <memmove>
  while(*path == '/')
    80003de0:	0004c783          	lbu	a5,0(s1)
    80003de4:	01279763          	bne	a5,s2,80003df2 <namex+0xca>
    path++;
    80003de8:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003dea:	0004c783          	lbu	a5,0(s1)
    80003dee:	ff278de3          	beq	a5,s2,80003de8 <namex+0xc0>
    ilock(ip);
    80003df2:	854e                	mv	a0,s3
    80003df4:	00000097          	auipc	ra,0x0
    80003df8:	9a0080e7          	jalr	-1632(ra) # 80003794 <ilock>
    if(ip->type != T_DIR){
    80003dfc:	04499783          	lh	a5,68(s3)
    80003e00:	f98793e3          	bne	a5,s8,80003d86 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003e04:	000b0563          	beqz	s6,80003e0e <namex+0xe6>
    80003e08:	0004c783          	lbu	a5,0(s1)
    80003e0c:	d3cd                	beqz	a5,80003dae <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003e0e:	865e                	mv	a2,s7
    80003e10:	85d6                	mv	a1,s5
    80003e12:	854e                	mv	a0,s3
    80003e14:	00000097          	auipc	ra,0x0
    80003e18:	e64080e7          	jalr	-412(ra) # 80003c78 <dirlookup>
    80003e1c:	8a2a                	mv	s4,a0
    80003e1e:	dd51                	beqz	a0,80003dba <namex+0x92>
    iunlockput(ip);
    80003e20:	854e                	mv	a0,s3
    80003e22:	00000097          	auipc	ra,0x0
    80003e26:	bd4080e7          	jalr	-1068(ra) # 800039f6 <iunlockput>
    ip = next;
    80003e2a:	89d2                	mv	s3,s4
  while(*path == '/')
    80003e2c:	0004c783          	lbu	a5,0(s1)
    80003e30:	05279763          	bne	a5,s2,80003e7e <namex+0x156>
    path++;
    80003e34:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e36:	0004c783          	lbu	a5,0(s1)
    80003e3a:	ff278de3          	beq	a5,s2,80003e34 <namex+0x10c>
  if(*path == 0)
    80003e3e:	c79d                	beqz	a5,80003e6c <namex+0x144>
    path++;
    80003e40:	85a6                	mv	a1,s1
  len = path - s;
    80003e42:	8a5e                	mv	s4,s7
    80003e44:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003e46:	01278963          	beq	a5,s2,80003e58 <namex+0x130>
    80003e4a:	dfbd                	beqz	a5,80003dc8 <namex+0xa0>
    path++;
    80003e4c:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003e4e:	0004c783          	lbu	a5,0(s1)
    80003e52:	ff279ce3          	bne	a5,s2,80003e4a <namex+0x122>
    80003e56:	bf8d                	j	80003dc8 <namex+0xa0>
    memmove(name, s, len);
    80003e58:	2601                	sext.w	a2,a2
    80003e5a:	8556                	mv	a0,s5
    80003e5c:	ffffd097          	auipc	ra,0xffffd
    80003e60:	ee4080e7          	jalr	-284(ra) # 80000d40 <memmove>
    name[len] = 0;
    80003e64:	9a56                	add	s4,s4,s5
    80003e66:	000a0023          	sb	zero,0(s4)
    80003e6a:	bf9d                	j	80003de0 <namex+0xb8>
  if(nameiparent){
    80003e6c:	f20b03e3          	beqz	s6,80003d92 <namex+0x6a>
    iput(ip);
    80003e70:	854e                	mv	a0,s3
    80003e72:	00000097          	auipc	ra,0x0
    80003e76:	adc080e7          	jalr	-1316(ra) # 8000394e <iput>
    return 0;
    80003e7a:	4981                	li	s3,0
    80003e7c:	bf19                	j	80003d92 <namex+0x6a>
  if(*path == 0)
    80003e7e:	d7fd                	beqz	a5,80003e6c <namex+0x144>
  while(*path != '/' && *path != 0)
    80003e80:	0004c783          	lbu	a5,0(s1)
    80003e84:	85a6                	mv	a1,s1
    80003e86:	b7d1                	j	80003e4a <namex+0x122>

0000000080003e88 <dirlink>:
{
    80003e88:	7139                	addi	sp,sp,-64
    80003e8a:	fc06                	sd	ra,56(sp)
    80003e8c:	f822                	sd	s0,48(sp)
    80003e8e:	f426                	sd	s1,40(sp)
    80003e90:	f04a                	sd	s2,32(sp)
    80003e92:	ec4e                	sd	s3,24(sp)
    80003e94:	e852                	sd	s4,16(sp)
    80003e96:	0080                	addi	s0,sp,64
    80003e98:	892a                	mv	s2,a0
    80003e9a:	8a2e                	mv	s4,a1
    80003e9c:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003e9e:	4601                	li	a2,0
    80003ea0:	00000097          	auipc	ra,0x0
    80003ea4:	dd8080e7          	jalr	-552(ra) # 80003c78 <dirlookup>
    80003ea8:	e93d                	bnez	a0,80003f1e <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003eaa:	04c92483          	lw	s1,76(s2)
    80003eae:	c49d                	beqz	s1,80003edc <dirlink+0x54>
    80003eb0:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003eb2:	4741                	li	a4,16
    80003eb4:	86a6                	mv	a3,s1
    80003eb6:	fc040613          	addi	a2,s0,-64
    80003eba:	4581                	li	a1,0
    80003ebc:	854a                	mv	a0,s2
    80003ebe:	00000097          	auipc	ra,0x0
    80003ec2:	b8a080e7          	jalr	-1142(ra) # 80003a48 <readi>
    80003ec6:	47c1                	li	a5,16
    80003ec8:	06f51163          	bne	a0,a5,80003f2a <dirlink+0xa2>
    if(de.inum == 0)
    80003ecc:	fc045783          	lhu	a5,-64(s0)
    80003ed0:	c791                	beqz	a5,80003edc <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ed2:	24c1                	addiw	s1,s1,16
    80003ed4:	04c92783          	lw	a5,76(s2)
    80003ed8:	fcf4ede3          	bltu	s1,a5,80003eb2 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003edc:	4639                	li	a2,14
    80003ede:	85d2                	mv	a1,s4
    80003ee0:	fc240513          	addi	a0,s0,-62
    80003ee4:	ffffd097          	auipc	ra,0xffffd
    80003ee8:	f10080e7          	jalr	-240(ra) # 80000df4 <strncpy>
  de.inum = inum;
    80003eec:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ef0:	4741                	li	a4,16
    80003ef2:	86a6                	mv	a3,s1
    80003ef4:	fc040613          	addi	a2,s0,-64
    80003ef8:	4581                	li	a1,0
    80003efa:	854a                	mv	a0,s2
    80003efc:	00000097          	auipc	ra,0x0
    80003f00:	c44080e7          	jalr	-956(ra) # 80003b40 <writei>
    80003f04:	872a                	mv	a4,a0
    80003f06:	47c1                	li	a5,16
  return 0;
    80003f08:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f0a:	02f71863          	bne	a4,a5,80003f3a <dirlink+0xb2>
}
    80003f0e:	70e2                	ld	ra,56(sp)
    80003f10:	7442                	ld	s0,48(sp)
    80003f12:	74a2                	ld	s1,40(sp)
    80003f14:	7902                	ld	s2,32(sp)
    80003f16:	69e2                	ld	s3,24(sp)
    80003f18:	6a42                	ld	s4,16(sp)
    80003f1a:	6121                	addi	sp,sp,64
    80003f1c:	8082                	ret
    iput(ip);
    80003f1e:	00000097          	auipc	ra,0x0
    80003f22:	a30080e7          	jalr	-1488(ra) # 8000394e <iput>
    return -1;
    80003f26:	557d                	li	a0,-1
    80003f28:	b7dd                	j	80003f0e <dirlink+0x86>
      panic("dirlink read");
    80003f2a:	00004517          	auipc	a0,0x4
    80003f2e:	71e50513          	addi	a0,a0,1822 # 80008648 <syscalls+0x1d0>
    80003f32:	ffffc097          	auipc	ra,0xffffc
    80003f36:	60c080e7          	jalr	1548(ra) # 8000053e <panic>
    panic("dirlink");
    80003f3a:	00005517          	auipc	a0,0x5
    80003f3e:	81e50513          	addi	a0,a0,-2018 # 80008758 <syscalls+0x2e0>
    80003f42:	ffffc097          	auipc	ra,0xffffc
    80003f46:	5fc080e7          	jalr	1532(ra) # 8000053e <panic>

0000000080003f4a <namei>:

struct inode*
namei(char *path)
{
    80003f4a:	1101                	addi	sp,sp,-32
    80003f4c:	ec06                	sd	ra,24(sp)
    80003f4e:	e822                	sd	s0,16(sp)
    80003f50:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003f52:	fe040613          	addi	a2,s0,-32
    80003f56:	4581                	li	a1,0
    80003f58:	00000097          	auipc	ra,0x0
    80003f5c:	dd0080e7          	jalr	-560(ra) # 80003d28 <namex>
}
    80003f60:	60e2                	ld	ra,24(sp)
    80003f62:	6442                	ld	s0,16(sp)
    80003f64:	6105                	addi	sp,sp,32
    80003f66:	8082                	ret

0000000080003f68 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003f68:	1141                	addi	sp,sp,-16
    80003f6a:	e406                	sd	ra,8(sp)
    80003f6c:	e022                	sd	s0,0(sp)
    80003f6e:	0800                	addi	s0,sp,16
    80003f70:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003f72:	4585                	li	a1,1
    80003f74:	00000097          	auipc	ra,0x0
    80003f78:	db4080e7          	jalr	-588(ra) # 80003d28 <namex>
}
    80003f7c:	60a2                	ld	ra,8(sp)
    80003f7e:	6402                	ld	s0,0(sp)
    80003f80:	0141                	addi	sp,sp,16
    80003f82:	8082                	ret

0000000080003f84 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003f84:	1101                	addi	sp,sp,-32
    80003f86:	ec06                	sd	ra,24(sp)
    80003f88:	e822                	sd	s0,16(sp)
    80003f8a:	e426                	sd	s1,8(sp)
    80003f8c:	e04a                	sd	s2,0(sp)
    80003f8e:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003f90:	0001d917          	auipc	s2,0x1d
    80003f94:	2e090913          	addi	s2,s2,736 # 80021270 <log>
    80003f98:	01892583          	lw	a1,24(s2)
    80003f9c:	02892503          	lw	a0,40(s2)
    80003fa0:	fffff097          	auipc	ra,0xfffff
    80003fa4:	ff2080e7          	jalr	-14(ra) # 80002f92 <bread>
    80003fa8:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003faa:	02c92683          	lw	a3,44(s2)
    80003fae:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003fb0:	02d05763          	blez	a3,80003fde <write_head+0x5a>
    80003fb4:	0001d797          	auipc	a5,0x1d
    80003fb8:	2ec78793          	addi	a5,a5,748 # 800212a0 <log+0x30>
    80003fbc:	05c50713          	addi	a4,a0,92
    80003fc0:	36fd                	addiw	a3,a3,-1
    80003fc2:	1682                	slli	a3,a3,0x20
    80003fc4:	9281                	srli	a3,a3,0x20
    80003fc6:	068a                	slli	a3,a3,0x2
    80003fc8:	0001d617          	auipc	a2,0x1d
    80003fcc:	2dc60613          	addi	a2,a2,732 # 800212a4 <log+0x34>
    80003fd0:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003fd2:	4390                	lw	a2,0(a5)
    80003fd4:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003fd6:	0791                	addi	a5,a5,4
    80003fd8:	0711                	addi	a4,a4,4
    80003fda:	fed79ce3          	bne	a5,a3,80003fd2 <write_head+0x4e>
  }
  bwrite(buf);
    80003fde:	8526                	mv	a0,s1
    80003fe0:	fffff097          	auipc	ra,0xfffff
    80003fe4:	0a4080e7          	jalr	164(ra) # 80003084 <bwrite>
  brelse(buf);
    80003fe8:	8526                	mv	a0,s1
    80003fea:	fffff097          	auipc	ra,0xfffff
    80003fee:	0d8080e7          	jalr	216(ra) # 800030c2 <brelse>
}
    80003ff2:	60e2                	ld	ra,24(sp)
    80003ff4:	6442                	ld	s0,16(sp)
    80003ff6:	64a2                	ld	s1,8(sp)
    80003ff8:	6902                	ld	s2,0(sp)
    80003ffa:	6105                	addi	sp,sp,32
    80003ffc:	8082                	ret

0000000080003ffe <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003ffe:	0001d797          	auipc	a5,0x1d
    80004002:	29e7a783          	lw	a5,670(a5) # 8002129c <log+0x2c>
    80004006:	0af05d63          	blez	a5,800040c0 <install_trans+0xc2>
{
    8000400a:	7139                	addi	sp,sp,-64
    8000400c:	fc06                	sd	ra,56(sp)
    8000400e:	f822                	sd	s0,48(sp)
    80004010:	f426                	sd	s1,40(sp)
    80004012:	f04a                	sd	s2,32(sp)
    80004014:	ec4e                	sd	s3,24(sp)
    80004016:	e852                	sd	s4,16(sp)
    80004018:	e456                	sd	s5,8(sp)
    8000401a:	e05a                	sd	s6,0(sp)
    8000401c:	0080                	addi	s0,sp,64
    8000401e:	8b2a                	mv	s6,a0
    80004020:	0001da97          	auipc	s5,0x1d
    80004024:	280a8a93          	addi	s5,s5,640 # 800212a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004028:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000402a:	0001d997          	auipc	s3,0x1d
    8000402e:	24698993          	addi	s3,s3,582 # 80021270 <log>
    80004032:	a035                	j	8000405e <install_trans+0x60>
      bunpin(dbuf);
    80004034:	8526                	mv	a0,s1
    80004036:	fffff097          	auipc	ra,0xfffff
    8000403a:	166080e7          	jalr	358(ra) # 8000319c <bunpin>
    brelse(lbuf);
    8000403e:	854a                	mv	a0,s2
    80004040:	fffff097          	auipc	ra,0xfffff
    80004044:	082080e7          	jalr	130(ra) # 800030c2 <brelse>
    brelse(dbuf);
    80004048:	8526                	mv	a0,s1
    8000404a:	fffff097          	auipc	ra,0xfffff
    8000404e:	078080e7          	jalr	120(ra) # 800030c2 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004052:	2a05                	addiw	s4,s4,1
    80004054:	0a91                	addi	s5,s5,4
    80004056:	02c9a783          	lw	a5,44(s3)
    8000405a:	04fa5963          	bge	s4,a5,800040ac <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000405e:	0189a583          	lw	a1,24(s3)
    80004062:	014585bb          	addw	a1,a1,s4
    80004066:	2585                	addiw	a1,a1,1
    80004068:	0289a503          	lw	a0,40(s3)
    8000406c:	fffff097          	auipc	ra,0xfffff
    80004070:	f26080e7          	jalr	-218(ra) # 80002f92 <bread>
    80004074:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004076:	000aa583          	lw	a1,0(s5)
    8000407a:	0289a503          	lw	a0,40(s3)
    8000407e:	fffff097          	auipc	ra,0xfffff
    80004082:	f14080e7          	jalr	-236(ra) # 80002f92 <bread>
    80004086:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004088:	40000613          	li	a2,1024
    8000408c:	05890593          	addi	a1,s2,88
    80004090:	05850513          	addi	a0,a0,88
    80004094:	ffffd097          	auipc	ra,0xffffd
    80004098:	cac080e7          	jalr	-852(ra) # 80000d40 <memmove>
    bwrite(dbuf);  // write dst to disk
    8000409c:	8526                	mv	a0,s1
    8000409e:	fffff097          	auipc	ra,0xfffff
    800040a2:	fe6080e7          	jalr	-26(ra) # 80003084 <bwrite>
    if(recovering == 0)
    800040a6:	f80b1ce3          	bnez	s6,8000403e <install_trans+0x40>
    800040aa:	b769                	j	80004034 <install_trans+0x36>
}
    800040ac:	70e2                	ld	ra,56(sp)
    800040ae:	7442                	ld	s0,48(sp)
    800040b0:	74a2                	ld	s1,40(sp)
    800040b2:	7902                	ld	s2,32(sp)
    800040b4:	69e2                	ld	s3,24(sp)
    800040b6:	6a42                	ld	s4,16(sp)
    800040b8:	6aa2                	ld	s5,8(sp)
    800040ba:	6b02                	ld	s6,0(sp)
    800040bc:	6121                	addi	sp,sp,64
    800040be:	8082                	ret
    800040c0:	8082                	ret

00000000800040c2 <initlog>:
{
    800040c2:	7179                	addi	sp,sp,-48
    800040c4:	f406                	sd	ra,40(sp)
    800040c6:	f022                	sd	s0,32(sp)
    800040c8:	ec26                	sd	s1,24(sp)
    800040ca:	e84a                	sd	s2,16(sp)
    800040cc:	e44e                	sd	s3,8(sp)
    800040ce:	1800                	addi	s0,sp,48
    800040d0:	892a                	mv	s2,a0
    800040d2:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800040d4:	0001d497          	auipc	s1,0x1d
    800040d8:	19c48493          	addi	s1,s1,412 # 80021270 <log>
    800040dc:	00004597          	auipc	a1,0x4
    800040e0:	57c58593          	addi	a1,a1,1404 # 80008658 <syscalls+0x1e0>
    800040e4:	8526                	mv	a0,s1
    800040e6:	ffffd097          	auipc	ra,0xffffd
    800040ea:	a6e080e7          	jalr	-1426(ra) # 80000b54 <initlock>
  log.start = sb->logstart;
    800040ee:	0149a583          	lw	a1,20(s3)
    800040f2:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800040f4:	0109a783          	lw	a5,16(s3)
    800040f8:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800040fa:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800040fe:	854a                	mv	a0,s2
    80004100:	fffff097          	auipc	ra,0xfffff
    80004104:	e92080e7          	jalr	-366(ra) # 80002f92 <bread>
  log.lh.n = lh->n;
    80004108:	4d3c                	lw	a5,88(a0)
    8000410a:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000410c:	02f05563          	blez	a5,80004136 <initlog+0x74>
    80004110:	05c50713          	addi	a4,a0,92
    80004114:	0001d697          	auipc	a3,0x1d
    80004118:	18c68693          	addi	a3,a3,396 # 800212a0 <log+0x30>
    8000411c:	37fd                	addiw	a5,a5,-1
    8000411e:	1782                	slli	a5,a5,0x20
    80004120:	9381                	srli	a5,a5,0x20
    80004122:	078a                	slli	a5,a5,0x2
    80004124:	06050613          	addi	a2,a0,96
    80004128:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    8000412a:	4310                	lw	a2,0(a4)
    8000412c:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    8000412e:	0711                	addi	a4,a4,4
    80004130:	0691                	addi	a3,a3,4
    80004132:	fef71ce3          	bne	a4,a5,8000412a <initlog+0x68>
  brelse(buf);
    80004136:	fffff097          	auipc	ra,0xfffff
    8000413a:	f8c080e7          	jalr	-116(ra) # 800030c2 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000413e:	4505                	li	a0,1
    80004140:	00000097          	auipc	ra,0x0
    80004144:	ebe080e7          	jalr	-322(ra) # 80003ffe <install_trans>
  log.lh.n = 0;
    80004148:	0001d797          	auipc	a5,0x1d
    8000414c:	1407aa23          	sw	zero,340(a5) # 8002129c <log+0x2c>
  write_head(); // clear the log
    80004150:	00000097          	auipc	ra,0x0
    80004154:	e34080e7          	jalr	-460(ra) # 80003f84 <write_head>
}
    80004158:	70a2                	ld	ra,40(sp)
    8000415a:	7402                	ld	s0,32(sp)
    8000415c:	64e2                	ld	s1,24(sp)
    8000415e:	6942                	ld	s2,16(sp)
    80004160:	69a2                	ld	s3,8(sp)
    80004162:	6145                	addi	sp,sp,48
    80004164:	8082                	ret

0000000080004166 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004166:	1101                	addi	sp,sp,-32
    80004168:	ec06                	sd	ra,24(sp)
    8000416a:	e822                	sd	s0,16(sp)
    8000416c:	e426                	sd	s1,8(sp)
    8000416e:	e04a                	sd	s2,0(sp)
    80004170:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004172:	0001d517          	auipc	a0,0x1d
    80004176:	0fe50513          	addi	a0,a0,254 # 80021270 <log>
    8000417a:	ffffd097          	auipc	ra,0xffffd
    8000417e:	a6a080e7          	jalr	-1430(ra) # 80000be4 <acquire>
  while(1){
    if(log.committing){
    80004182:	0001d497          	auipc	s1,0x1d
    80004186:	0ee48493          	addi	s1,s1,238 # 80021270 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000418a:	4979                	li	s2,30
    8000418c:	a039                	j	8000419a <begin_op+0x34>
      sleep(&log, &log.lock);
    8000418e:	85a6                	mv	a1,s1
    80004190:	8526                	mv	a0,s1
    80004192:	ffffe097          	auipc	ra,0xffffe
    80004196:	fbe080e7          	jalr	-66(ra) # 80002150 <sleep>
    if(log.committing){
    8000419a:	50dc                	lw	a5,36(s1)
    8000419c:	fbed                	bnez	a5,8000418e <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000419e:	509c                	lw	a5,32(s1)
    800041a0:	0017871b          	addiw	a4,a5,1
    800041a4:	0007069b          	sext.w	a3,a4
    800041a8:	0027179b          	slliw	a5,a4,0x2
    800041ac:	9fb9                	addw	a5,a5,a4
    800041ae:	0017979b          	slliw	a5,a5,0x1
    800041b2:	54d8                	lw	a4,44(s1)
    800041b4:	9fb9                	addw	a5,a5,a4
    800041b6:	00f95963          	bge	s2,a5,800041c8 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800041ba:	85a6                	mv	a1,s1
    800041bc:	8526                	mv	a0,s1
    800041be:	ffffe097          	auipc	ra,0xffffe
    800041c2:	f92080e7          	jalr	-110(ra) # 80002150 <sleep>
    800041c6:	bfd1                	j	8000419a <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800041c8:	0001d517          	auipc	a0,0x1d
    800041cc:	0a850513          	addi	a0,a0,168 # 80021270 <log>
    800041d0:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800041d2:	ffffd097          	auipc	ra,0xffffd
    800041d6:	ac6080e7          	jalr	-1338(ra) # 80000c98 <release>
      break;
    }
  }
}
    800041da:	60e2                	ld	ra,24(sp)
    800041dc:	6442                	ld	s0,16(sp)
    800041de:	64a2                	ld	s1,8(sp)
    800041e0:	6902                	ld	s2,0(sp)
    800041e2:	6105                	addi	sp,sp,32
    800041e4:	8082                	ret

00000000800041e6 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800041e6:	7139                	addi	sp,sp,-64
    800041e8:	fc06                	sd	ra,56(sp)
    800041ea:	f822                	sd	s0,48(sp)
    800041ec:	f426                	sd	s1,40(sp)
    800041ee:	f04a                	sd	s2,32(sp)
    800041f0:	ec4e                	sd	s3,24(sp)
    800041f2:	e852                	sd	s4,16(sp)
    800041f4:	e456                	sd	s5,8(sp)
    800041f6:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800041f8:	0001d497          	auipc	s1,0x1d
    800041fc:	07848493          	addi	s1,s1,120 # 80021270 <log>
    80004200:	8526                	mv	a0,s1
    80004202:	ffffd097          	auipc	ra,0xffffd
    80004206:	9e2080e7          	jalr	-1566(ra) # 80000be4 <acquire>
  log.outstanding -= 1;
    8000420a:	509c                	lw	a5,32(s1)
    8000420c:	37fd                	addiw	a5,a5,-1
    8000420e:	0007891b          	sext.w	s2,a5
    80004212:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004214:	50dc                	lw	a5,36(s1)
    80004216:	efb9                	bnez	a5,80004274 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004218:	06091663          	bnez	s2,80004284 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    8000421c:	0001d497          	auipc	s1,0x1d
    80004220:	05448493          	addi	s1,s1,84 # 80021270 <log>
    80004224:	4785                	li	a5,1
    80004226:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004228:	8526                	mv	a0,s1
    8000422a:	ffffd097          	auipc	ra,0xffffd
    8000422e:	a6e080e7          	jalr	-1426(ra) # 80000c98 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004232:	54dc                	lw	a5,44(s1)
    80004234:	06f04763          	bgtz	a5,800042a2 <end_op+0xbc>
    acquire(&log.lock);
    80004238:	0001d497          	auipc	s1,0x1d
    8000423c:	03848493          	addi	s1,s1,56 # 80021270 <log>
    80004240:	8526                	mv	a0,s1
    80004242:	ffffd097          	auipc	ra,0xffffd
    80004246:	9a2080e7          	jalr	-1630(ra) # 80000be4 <acquire>
    log.committing = 0;
    8000424a:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000424e:	8526                	mv	a0,s1
    80004250:	ffffe097          	auipc	ra,0xffffe
    80004254:	08c080e7          	jalr	140(ra) # 800022dc <wakeup>
    release(&log.lock);
    80004258:	8526                	mv	a0,s1
    8000425a:	ffffd097          	auipc	ra,0xffffd
    8000425e:	a3e080e7          	jalr	-1474(ra) # 80000c98 <release>
}
    80004262:	70e2                	ld	ra,56(sp)
    80004264:	7442                	ld	s0,48(sp)
    80004266:	74a2                	ld	s1,40(sp)
    80004268:	7902                	ld	s2,32(sp)
    8000426a:	69e2                	ld	s3,24(sp)
    8000426c:	6a42                	ld	s4,16(sp)
    8000426e:	6aa2                	ld	s5,8(sp)
    80004270:	6121                	addi	sp,sp,64
    80004272:	8082                	ret
    panic("log.committing");
    80004274:	00004517          	auipc	a0,0x4
    80004278:	3ec50513          	addi	a0,a0,1004 # 80008660 <syscalls+0x1e8>
    8000427c:	ffffc097          	auipc	ra,0xffffc
    80004280:	2c2080e7          	jalr	706(ra) # 8000053e <panic>
    wakeup(&log);
    80004284:	0001d497          	auipc	s1,0x1d
    80004288:	fec48493          	addi	s1,s1,-20 # 80021270 <log>
    8000428c:	8526                	mv	a0,s1
    8000428e:	ffffe097          	auipc	ra,0xffffe
    80004292:	04e080e7          	jalr	78(ra) # 800022dc <wakeup>
  release(&log.lock);
    80004296:	8526                	mv	a0,s1
    80004298:	ffffd097          	auipc	ra,0xffffd
    8000429c:	a00080e7          	jalr	-1536(ra) # 80000c98 <release>
  if(do_commit){
    800042a0:	b7c9                	j	80004262 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042a2:	0001da97          	auipc	s5,0x1d
    800042a6:	ffea8a93          	addi	s5,s5,-2 # 800212a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800042aa:	0001da17          	auipc	s4,0x1d
    800042ae:	fc6a0a13          	addi	s4,s4,-58 # 80021270 <log>
    800042b2:	018a2583          	lw	a1,24(s4)
    800042b6:	012585bb          	addw	a1,a1,s2
    800042ba:	2585                	addiw	a1,a1,1
    800042bc:	028a2503          	lw	a0,40(s4)
    800042c0:	fffff097          	auipc	ra,0xfffff
    800042c4:	cd2080e7          	jalr	-814(ra) # 80002f92 <bread>
    800042c8:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800042ca:	000aa583          	lw	a1,0(s5)
    800042ce:	028a2503          	lw	a0,40(s4)
    800042d2:	fffff097          	auipc	ra,0xfffff
    800042d6:	cc0080e7          	jalr	-832(ra) # 80002f92 <bread>
    800042da:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800042dc:	40000613          	li	a2,1024
    800042e0:	05850593          	addi	a1,a0,88
    800042e4:	05848513          	addi	a0,s1,88
    800042e8:	ffffd097          	auipc	ra,0xffffd
    800042ec:	a58080e7          	jalr	-1448(ra) # 80000d40 <memmove>
    bwrite(to);  // write the log
    800042f0:	8526                	mv	a0,s1
    800042f2:	fffff097          	auipc	ra,0xfffff
    800042f6:	d92080e7          	jalr	-622(ra) # 80003084 <bwrite>
    brelse(from);
    800042fa:	854e                	mv	a0,s3
    800042fc:	fffff097          	auipc	ra,0xfffff
    80004300:	dc6080e7          	jalr	-570(ra) # 800030c2 <brelse>
    brelse(to);
    80004304:	8526                	mv	a0,s1
    80004306:	fffff097          	auipc	ra,0xfffff
    8000430a:	dbc080e7          	jalr	-580(ra) # 800030c2 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000430e:	2905                	addiw	s2,s2,1
    80004310:	0a91                	addi	s5,s5,4
    80004312:	02ca2783          	lw	a5,44(s4)
    80004316:	f8f94ee3          	blt	s2,a5,800042b2 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000431a:	00000097          	auipc	ra,0x0
    8000431e:	c6a080e7          	jalr	-918(ra) # 80003f84 <write_head>
    install_trans(0); // Now install writes to home locations
    80004322:	4501                	li	a0,0
    80004324:	00000097          	auipc	ra,0x0
    80004328:	cda080e7          	jalr	-806(ra) # 80003ffe <install_trans>
    log.lh.n = 0;
    8000432c:	0001d797          	auipc	a5,0x1d
    80004330:	f607a823          	sw	zero,-144(a5) # 8002129c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004334:	00000097          	auipc	ra,0x0
    80004338:	c50080e7          	jalr	-944(ra) # 80003f84 <write_head>
    8000433c:	bdf5                	j	80004238 <end_op+0x52>

000000008000433e <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000433e:	1101                	addi	sp,sp,-32
    80004340:	ec06                	sd	ra,24(sp)
    80004342:	e822                	sd	s0,16(sp)
    80004344:	e426                	sd	s1,8(sp)
    80004346:	e04a                	sd	s2,0(sp)
    80004348:	1000                	addi	s0,sp,32
    8000434a:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    8000434c:	0001d917          	auipc	s2,0x1d
    80004350:	f2490913          	addi	s2,s2,-220 # 80021270 <log>
    80004354:	854a                	mv	a0,s2
    80004356:	ffffd097          	auipc	ra,0xffffd
    8000435a:	88e080e7          	jalr	-1906(ra) # 80000be4 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000435e:	02c92603          	lw	a2,44(s2)
    80004362:	47f5                	li	a5,29
    80004364:	06c7c563          	blt	a5,a2,800043ce <log_write+0x90>
    80004368:	0001d797          	auipc	a5,0x1d
    8000436c:	f247a783          	lw	a5,-220(a5) # 8002128c <log+0x1c>
    80004370:	37fd                	addiw	a5,a5,-1
    80004372:	04f65e63          	bge	a2,a5,800043ce <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004376:	0001d797          	auipc	a5,0x1d
    8000437a:	f1a7a783          	lw	a5,-230(a5) # 80021290 <log+0x20>
    8000437e:	06f05063          	blez	a5,800043de <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004382:	4781                	li	a5,0
    80004384:	06c05563          	blez	a2,800043ee <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004388:	44cc                	lw	a1,12(s1)
    8000438a:	0001d717          	auipc	a4,0x1d
    8000438e:	f1670713          	addi	a4,a4,-234 # 800212a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004392:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004394:	4314                	lw	a3,0(a4)
    80004396:	04b68c63          	beq	a3,a1,800043ee <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000439a:	2785                	addiw	a5,a5,1
    8000439c:	0711                	addi	a4,a4,4
    8000439e:	fef61be3          	bne	a2,a5,80004394 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800043a2:	0621                	addi	a2,a2,8
    800043a4:	060a                	slli	a2,a2,0x2
    800043a6:	0001d797          	auipc	a5,0x1d
    800043aa:	eca78793          	addi	a5,a5,-310 # 80021270 <log>
    800043ae:	963e                	add	a2,a2,a5
    800043b0:	44dc                	lw	a5,12(s1)
    800043b2:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800043b4:	8526                	mv	a0,s1
    800043b6:	fffff097          	auipc	ra,0xfffff
    800043ba:	daa080e7          	jalr	-598(ra) # 80003160 <bpin>
    log.lh.n++;
    800043be:	0001d717          	auipc	a4,0x1d
    800043c2:	eb270713          	addi	a4,a4,-334 # 80021270 <log>
    800043c6:	575c                	lw	a5,44(a4)
    800043c8:	2785                	addiw	a5,a5,1
    800043ca:	d75c                	sw	a5,44(a4)
    800043cc:	a835                	j	80004408 <log_write+0xca>
    panic("too big a transaction");
    800043ce:	00004517          	auipc	a0,0x4
    800043d2:	2a250513          	addi	a0,a0,674 # 80008670 <syscalls+0x1f8>
    800043d6:	ffffc097          	auipc	ra,0xffffc
    800043da:	168080e7          	jalr	360(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    800043de:	00004517          	auipc	a0,0x4
    800043e2:	2aa50513          	addi	a0,a0,682 # 80008688 <syscalls+0x210>
    800043e6:	ffffc097          	auipc	ra,0xffffc
    800043ea:	158080e7          	jalr	344(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    800043ee:	00878713          	addi	a4,a5,8
    800043f2:	00271693          	slli	a3,a4,0x2
    800043f6:	0001d717          	auipc	a4,0x1d
    800043fa:	e7a70713          	addi	a4,a4,-390 # 80021270 <log>
    800043fe:	9736                	add	a4,a4,a3
    80004400:	44d4                	lw	a3,12(s1)
    80004402:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004404:	faf608e3          	beq	a2,a5,800043b4 <log_write+0x76>
  }
  release(&log.lock);
    80004408:	0001d517          	auipc	a0,0x1d
    8000440c:	e6850513          	addi	a0,a0,-408 # 80021270 <log>
    80004410:	ffffd097          	auipc	ra,0xffffd
    80004414:	888080e7          	jalr	-1912(ra) # 80000c98 <release>
}
    80004418:	60e2                	ld	ra,24(sp)
    8000441a:	6442                	ld	s0,16(sp)
    8000441c:	64a2                	ld	s1,8(sp)
    8000441e:	6902                	ld	s2,0(sp)
    80004420:	6105                	addi	sp,sp,32
    80004422:	8082                	ret

0000000080004424 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004424:	1101                	addi	sp,sp,-32
    80004426:	ec06                	sd	ra,24(sp)
    80004428:	e822                	sd	s0,16(sp)
    8000442a:	e426                	sd	s1,8(sp)
    8000442c:	e04a                	sd	s2,0(sp)
    8000442e:	1000                	addi	s0,sp,32
    80004430:	84aa                	mv	s1,a0
    80004432:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004434:	00004597          	auipc	a1,0x4
    80004438:	27458593          	addi	a1,a1,628 # 800086a8 <syscalls+0x230>
    8000443c:	0521                	addi	a0,a0,8
    8000443e:	ffffc097          	auipc	ra,0xffffc
    80004442:	716080e7          	jalr	1814(ra) # 80000b54 <initlock>
  lk->name = name;
    80004446:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000444a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000444e:	0204a423          	sw	zero,40(s1)
}
    80004452:	60e2                	ld	ra,24(sp)
    80004454:	6442                	ld	s0,16(sp)
    80004456:	64a2                	ld	s1,8(sp)
    80004458:	6902                	ld	s2,0(sp)
    8000445a:	6105                	addi	sp,sp,32
    8000445c:	8082                	ret

000000008000445e <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000445e:	1101                	addi	sp,sp,-32
    80004460:	ec06                	sd	ra,24(sp)
    80004462:	e822                	sd	s0,16(sp)
    80004464:	e426                	sd	s1,8(sp)
    80004466:	e04a                	sd	s2,0(sp)
    80004468:	1000                	addi	s0,sp,32
    8000446a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000446c:	00850913          	addi	s2,a0,8
    80004470:	854a                	mv	a0,s2
    80004472:	ffffc097          	auipc	ra,0xffffc
    80004476:	772080e7          	jalr	1906(ra) # 80000be4 <acquire>
  while (lk->locked) {
    8000447a:	409c                	lw	a5,0(s1)
    8000447c:	cb89                	beqz	a5,8000448e <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000447e:	85ca                	mv	a1,s2
    80004480:	8526                	mv	a0,s1
    80004482:	ffffe097          	auipc	ra,0xffffe
    80004486:	cce080e7          	jalr	-818(ra) # 80002150 <sleep>
  while (lk->locked) {
    8000448a:	409c                	lw	a5,0(s1)
    8000448c:	fbed                	bnez	a5,8000447e <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000448e:	4785                	li	a5,1
    80004490:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004492:	ffffd097          	auipc	ra,0xffffd
    80004496:	602080e7          	jalr	1538(ra) # 80001a94 <myproc>
    8000449a:	591c                	lw	a5,48(a0)
    8000449c:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000449e:	854a                	mv	a0,s2
    800044a0:	ffffc097          	auipc	ra,0xffffc
    800044a4:	7f8080e7          	jalr	2040(ra) # 80000c98 <release>
}
    800044a8:	60e2                	ld	ra,24(sp)
    800044aa:	6442                	ld	s0,16(sp)
    800044ac:	64a2                	ld	s1,8(sp)
    800044ae:	6902                	ld	s2,0(sp)
    800044b0:	6105                	addi	sp,sp,32
    800044b2:	8082                	ret

00000000800044b4 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800044b4:	1101                	addi	sp,sp,-32
    800044b6:	ec06                	sd	ra,24(sp)
    800044b8:	e822                	sd	s0,16(sp)
    800044ba:	e426                	sd	s1,8(sp)
    800044bc:	e04a                	sd	s2,0(sp)
    800044be:	1000                	addi	s0,sp,32
    800044c0:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800044c2:	00850913          	addi	s2,a0,8
    800044c6:	854a                	mv	a0,s2
    800044c8:	ffffc097          	auipc	ra,0xffffc
    800044cc:	71c080e7          	jalr	1820(ra) # 80000be4 <acquire>
  lk->locked = 0;
    800044d0:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800044d4:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800044d8:	8526                	mv	a0,s1
    800044da:	ffffe097          	auipc	ra,0xffffe
    800044de:	e02080e7          	jalr	-510(ra) # 800022dc <wakeup>
  release(&lk->lk);
    800044e2:	854a                	mv	a0,s2
    800044e4:	ffffc097          	auipc	ra,0xffffc
    800044e8:	7b4080e7          	jalr	1972(ra) # 80000c98 <release>
}
    800044ec:	60e2                	ld	ra,24(sp)
    800044ee:	6442                	ld	s0,16(sp)
    800044f0:	64a2                	ld	s1,8(sp)
    800044f2:	6902                	ld	s2,0(sp)
    800044f4:	6105                	addi	sp,sp,32
    800044f6:	8082                	ret

00000000800044f8 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800044f8:	7179                	addi	sp,sp,-48
    800044fa:	f406                	sd	ra,40(sp)
    800044fc:	f022                	sd	s0,32(sp)
    800044fe:	ec26                	sd	s1,24(sp)
    80004500:	e84a                	sd	s2,16(sp)
    80004502:	e44e                	sd	s3,8(sp)
    80004504:	1800                	addi	s0,sp,48
    80004506:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004508:	00850913          	addi	s2,a0,8
    8000450c:	854a                	mv	a0,s2
    8000450e:	ffffc097          	auipc	ra,0xffffc
    80004512:	6d6080e7          	jalr	1750(ra) # 80000be4 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004516:	409c                	lw	a5,0(s1)
    80004518:	ef99                	bnez	a5,80004536 <holdingsleep+0x3e>
    8000451a:	4481                	li	s1,0
  release(&lk->lk);
    8000451c:	854a                	mv	a0,s2
    8000451e:	ffffc097          	auipc	ra,0xffffc
    80004522:	77a080e7          	jalr	1914(ra) # 80000c98 <release>
  return r;
}
    80004526:	8526                	mv	a0,s1
    80004528:	70a2                	ld	ra,40(sp)
    8000452a:	7402                	ld	s0,32(sp)
    8000452c:	64e2                	ld	s1,24(sp)
    8000452e:	6942                	ld	s2,16(sp)
    80004530:	69a2                	ld	s3,8(sp)
    80004532:	6145                	addi	sp,sp,48
    80004534:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004536:	0284a983          	lw	s3,40(s1)
    8000453a:	ffffd097          	auipc	ra,0xffffd
    8000453e:	55a080e7          	jalr	1370(ra) # 80001a94 <myproc>
    80004542:	5904                	lw	s1,48(a0)
    80004544:	413484b3          	sub	s1,s1,s3
    80004548:	0014b493          	seqz	s1,s1
    8000454c:	bfc1                	j	8000451c <holdingsleep+0x24>

000000008000454e <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000454e:	1141                	addi	sp,sp,-16
    80004550:	e406                	sd	ra,8(sp)
    80004552:	e022                	sd	s0,0(sp)
    80004554:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004556:	00004597          	auipc	a1,0x4
    8000455a:	16258593          	addi	a1,a1,354 # 800086b8 <syscalls+0x240>
    8000455e:	0001d517          	auipc	a0,0x1d
    80004562:	e5a50513          	addi	a0,a0,-422 # 800213b8 <ftable>
    80004566:	ffffc097          	auipc	ra,0xffffc
    8000456a:	5ee080e7          	jalr	1518(ra) # 80000b54 <initlock>
}
    8000456e:	60a2                	ld	ra,8(sp)
    80004570:	6402                	ld	s0,0(sp)
    80004572:	0141                	addi	sp,sp,16
    80004574:	8082                	ret

0000000080004576 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004576:	1101                	addi	sp,sp,-32
    80004578:	ec06                	sd	ra,24(sp)
    8000457a:	e822                	sd	s0,16(sp)
    8000457c:	e426                	sd	s1,8(sp)
    8000457e:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004580:	0001d517          	auipc	a0,0x1d
    80004584:	e3850513          	addi	a0,a0,-456 # 800213b8 <ftable>
    80004588:	ffffc097          	auipc	ra,0xffffc
    8000458c:	65c080e7          	jalr	1628(ra) # 80000be4 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004590:	0001d497          	auipc	s1,0x1d
    80004594:	e4048493          	addi	s1,s1,-448 # 800213d0 <ftable+0x18>
    80004598:	0001e717          	auipc	a4,0x1e
    8000459c:	dd870713          	addi	a4,a4,-552 # 80022370 <ftable+0xfb8>
    if(f->ref == 0){
    800045a0:	40dc                	lw	a5,4(s1)
    800045a2:	cf99                	beqz	a5,800045c0 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800045a4:	02848493          	addi	s1,s1,40
    800045a8:	fee49ce3          	bne	s1,a4,800045a0 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800045ac:	0001d517          	auipc	a0,0x1d
    800045b0:	e0c50513          	addi	a0,a0,-500 # 800213b8 <ftable>
    800045b4:	ffffc097          	auipc	ra,0xffffc
    800045b8:	6e4080e7          	jalr	1764(ra) # 80000c98 <release>
  return 0;
    800045bc:	4481                	li	s1,0
    800045be:	a819                	j	800045d4 <filealloc+0x5e>
      f->ref = 1;
    800045c0:	4785                	li	a5,1
    800045c2:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800045c4:	0001d517          	auipc	a0,0x1d
    800045c8:	df450513          	addi	a0,a0,-524 # 800213b8 <ftable>
    800045cc:	ffffc097          	auipc	ra,0xffffc
    800045d0:	6cc080e7          	jalr	1740(ra) # 80000c98 <release>
}
    800045d4:	8526                	mv	a0,s1
    800045d6:	60e2                	ld	ra,24(sp)
    800045d8:	6442                	ld	s0,16(sp)
    800045da:	64a2                	ld	s1,8(sp)
    800045dc:	6105                	addi	sp,sp,32
    800045de:	8082                	ret

00000000800045e0 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800045e0:	1101                	addi	sp,sp,-32
    800045e2:	ec06                	sd	ra,24(sp)
    800045e4:	e822                	sd	s0,16(sp)
    800045e6:	e426                	sd	s1,8(sp)
    800045e8:	1000                	addi	s0,sp,32
    800045ea:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800045ec:	0001d517          	auipc	a0,0x1d
    800045f0:	dcc50513          	addi	a0,a0,-564 # 800213b8 <ftable>
    800045f4:	ffffc097          	auipc	ra,0xffffc
    800045f8:	5f0080e7          	jalr	1520(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    800045fc:	40dc                	lw	a5,4(s1)
    800045fe:	02f05263          	blez	a5,80004622 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004602:	2785                	addiw	a5,a5,1
    80004604:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004606:	0001d517          	auipc	a0,0x1d
    8000460a:	db250513          	addi	a0,a0,-590 # 800213b8 <ftable>
    8000460e:	ffffc097          	auipc	ra,0xffffc
    80004612:	68a080e7          	jalr	1674(ra) # 80000c98 <release>
  return f;
}
    80004616:	8526                	mv	a0,s1
    80004618:	60e2                	ld	ra,24(sp)
    8000461a:	6442                	ld	s0,16(sp)
    8000461c:	64a2                	ld	s1,8(sp)
    8000461e:	6105                	addi	sp,sp,32
    80004620:	8082                	ret
    panic("filedup");
    80004622:	00004517          	auipc	a0,0x4
    80004626:	09e50513          	addi	a0,a0,158 # 800086c0 <syscalls+0x248>
    8000462a:	ffffc097          	auipc	ra,0xffffc
    8000462e:	f14080e7          	jalr	-236(ra) # 8000053e <panic>

0000000080004632 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004632:	7139                	addi	sp,sp,-64
    80004634:	fc06                	sd	ra,56(sp)
    80004636:	f822                	sd	s0,48(sp)
    80004638:	f426                	sd	s1,40(sp)
    8000463a:	f04a                	sd	s2,32(sp)
    8000463c:	ec4e                	sd	s3,24(sp)
    8000463e:	e852                	sd	s4,16(sp)
    80004640:	e456                	sd	s5,8(sp)
    80004642:	0080                	addi	s0,sp,64
    80004644:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004646:	0001d517          	auipc	a0,0x1d
    8000464a:	d7250513          	addi	a0,a0,-654 # 800213b8 <ftable>
    8000464e:	ffffc097          	auipc	ra,0xffffc
    80004652:	596080e7          	jalr	1430(ra) # 80000be4 <acquire>
  if(f->ref < 1)
    80004656:	40dc                	lw	a5,4(s1)
    80004658:	06f05163          	blez	a5,800046ba <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000465c:	37fd                	addiw	a5,a5,-1
    8000465e:	0007871b          	sext.w	a4,a5
    80004662:	c0dc                	sw	a5,4(s1)
    80004664:	06e04363          	bgtz	a4,800046ca <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004668:	0004a903          	lw	s2,0(s1)
    8000466c:	0094ca83          	lbu	s5,9(s1)
    80004670:	0104ba03          	ld	s4,16(s1)
    80004674:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004678:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000467c:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004680:	0001d517          	auipc	a0,0x1d
    80004684:	d3850513          	addi	a0,a0,-712 # 800213b8 <ftable>
    80004688:	ffffc097          	auipc	ra,0xffffc
    8000468c:	610080e7          	jalr	1552(ra) # 80000c98 <release>

  if(ff.type == FD_PIPE){
    80004690:	4785                	li	a5,1
    80004692:	04f90d63          	beq	s2,a5,800046ec <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004696:	3979                	addiw	s2,s2,-2
    80004698:	4785                	li	a5,1
    8000469a:	0527e063          	bltu	a5,s2,800046da <fileclose+0xa8>
    begin_op();
    8000469e:	00000097          	auipc	ra,0x0
    800046a2:	ac8080e7          	jalr	-1336(ra) # 80004166 <begin_op>
    iput(ff.ip);
    800046a6:	854e                	mv	a0,s3
    800046a8:	fffff097          	auipc	ra,0xfffff
    800046ac:	2a6080e7          	jalr	678(ra) # 8000394e <iput>
    end_op();
    800046b0:	00000097          	auipc	ra,0x0
    800046b4:	b36080e7          	jalr	-1226(ra) # 800041e6 <end_op>
    800046b8:	a00d                	j	800046da <fileclose+0xa8>
    panic("fileclose");
    800046ba:	00004517          	auipc	a0,0x4
    800046be:	00e50513          	addi	a0,a0,14 # 800086c8 <syscalls+0x250>
    800046c2:	ffffc097          	auipc	ra,0xffffc
    800046c6:	e7c080e7          	jalr	-388(ra) # 8000053e <panic>
    release(&ftable.lock);
    800046ca:	0001d517          	auipc	a0,0x1d
    800046ce:	cee50513          	addi	a0,a0,-786 # 800213b8 <ftable>
    800046d2:	ffffc097          	auipc	ra,0xffffc
    800046d6:	5c6080e7          	jalr	1478(ra) # 80000c98 <release>
  }
}
    800046da:	70e2                	ld	ra,56(sp)
    800046dc:	7442                	ld	s0,48(sp)
    800046de:	74a2                	ld	s1,40(sp)
    800046e0:	7902                	ld	s2,32(sp)
    800046e2:	69e2                	ld	s3,24(sp)
    800046e4:	6a42                	ld	s4,16(sp)
    800046e6:	6aa2                	ld	s5,8(sp)
    800046e8:	6121                	addi	sp,sp,64
    800046ea:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800046ec:	85d6                	mv	a1,s5
    800046ee:	8552                	mv	a0,s4
    800046f0:	00000097          	auipc	ra,0x0
    800046f4:	34c080e7          	jalr	844(ra) # 80004a3c <pipeclose>
    800046f8:	b7cd                	j	800046da <fileclose+0xa8>

00000000800046fa <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800046fa:	715d                	addi	sp,sp,-80
    800046fc:	e486                	sd	ra,72(sp)
    800046fe:	e0a2                	sd	s0,64(sp)
    80004700:	fc26                	sd	s1,56(sp)
    80004702:	f84a                	sd	s2,48(sp)
    80004704:	f44e                	sd	s3,40(sp)
    80004706:	0880                	addi	s0,sp,80
    80004708:	84aa                	mv	s1,a0
    8000470a:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000470c:	ffffd097          	auipc	ra,0xffffd
    80004710:	388080e7          	jalr	904(ra) # 80001a94 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004714:	409c                	lw	a5,0(s1)
    80004716:	37f9                	addiw	a5,a5,-2
    80004718:	4705                	li	a4,1
    8000471a:	04f76763          	bltu	a4,a5,80004768 <filestat+0x6e>
    8000471e:	892a                	mv	s2,a0
    ilock(f->ip);
    80004720:	6c88                	ld	a0,24(s1)
    80004722:	fffff097          	auipc	ra,0xfffff
    80004726:	072080e7          	jalr	114(ra) # 80003794 <ilock>
    stati(f->ip, &st);
    8000472a:	fb840593          	addi	a1,s0,-72
    8000472e:	6c88                	ld	a0,24(s1)
    80004730:	fffff097          	auipc	ra,0xfffff
    80004734:	2ee080e7          	jalr	750(ra) # 80003a1e <stati>
    iunlock(f->ip);
    80004738:	6c88                	ld	a0,24(s1)
    8000473a:	fffff097          	auipc	ra,0xfffff
    8000473e:	11c080e7          	jalr	284(ra) # 80003856 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004742:	46e1                	li	a3,24
    80004744:	fb840613          	addi	a2,s0,-72
    80004748:	85ce                	mv	a1,s3
    8000474a:	05093503          	ld	a0,80(s2)
    8000474e:	ffffd097          	auipc	ra,0xffffd
    80004752:	f24080e7          	jalr	-220(ra) # 80001672 <copyout>
    80004756:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000475a:	60a6                	ld	ra,72(sp)
    8000475c:	6406                	ld	s0,64(sp)
    8000475e:	74e2                	ld	s1,56(sp)
    80004760:	7942                	ld	s2,48(sp)
    80004762:	79a2                	ld	s3,40(sp)
    80004764:	6161                	addi	sp,sp,80
    80004766:	8082                	ret
  return -1;
    80004768:	557d                	li	a0,-1
    8000476a:	bfc5                	j	8000475a <filestat+0x60>

000000008000476c <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000476c:	7179                	addi	sp,sp,-48
    8000476e:	f406                	sd	ra,40(sp)
    80004770:	f022                	sd	s0,32(sp)
    80004772:	ec26                	sd	s1,24(sp)
    80004774:	e84a                	sd	s2,16(sp)
    80004776:	e44e                	sd	s3,8(sp)
    80004778:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000477a:	00854783          	lbu	a5,8(a0)
    8000477e:	c3d5                	beqz	a5,80004822 <fileread+0xb6>
    80004780:	84aa                	mv	s1,a0
    80004782:	89ae                	mv	s3,a1
    80004784:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004786:	411c                	lw	a5,0(a0)
    80004788:	4705                	li	a4,1
    8000478a:	04e78963          	beq	a5,a4,800047dc <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000478e:	470d                	li	a4,3
    80004790:	04e78d63          	beq	a5,a4,800047ea <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004794:	4709                	li	a4,2
    80004796:	06e79e63          	bne	a5,a4,80004812 <fileread+0xa6>
    ilock(f->ip);
    8000479a:	6d08                	ld	a0,24(a0)
    8000479c:	fffff097          	auipc	ra,0xfffff
    800047a0:	ff8080e7          	jalr	-8(ra) # 80003794 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800047a4:	874a                	mv	a4,s2
    800047a6:	5094                	lw	a3,32(s1)
    800047a8:	864e                	mv	a2,s3
    800047aa:	4585                	li	a1,1
    800047ac:	6c88                	ld	a0,24(s1)
    800047ae:	fffff097          	auipc	ra,0xfffff
    800047b2:	29a080e7          	jalr	666(ra) # 80003a48 <readi>
    800047b6:	892a                	mv	s2,a0
    800047b8:	00a05563          	blez	a0,800047c2 <fileread+0x56>
      f->off += r;
    800047bc:	509c                	lw	a5,32(s1)
    800047be:	9fa9                	addw	a5,a5,a0
    800047c0:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800047c2:	6c88                	ld	a0,24(s1)
    800047c4:	fffff097          	auipc	ra,0xfffff
    800047c8:	092080e7          	jalr	146(ra) # 80003856 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800047cc:	854a                	mv	a0,s2
    800047ce:	70a2                	ld	ra,40(sp)
    800047d0:	7402                	ld	s0,32(sp)
    800047d2:	64e2                	ld	s1,24(sp)
    800047d4:	6942                	ld	s2,16(sp)
    800047d6:	69a2                	ld	s3,8(sp)
    800047d8:	6145                	addi	sp,sp,48
    800047da:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800047dc:	6908                	ld	a0,16(a0)
    800047de:	00000097          	auipc	ra,0x0
    800047e2:	3c8080e7          	jalr	968(ra) # 80004ba6 <piperead>
    800047e6:	892a                	mv	s2,a0
    800047e8:	b7d5                	j	800047cc <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800047ea:	02451783          	lh	a5,36(a0)
    800047ee:	03079693          	slli	a3,a5,0x30
    800047f2:	92c1                	srli	a3,a3,0x30
    800047f4:	4725                	li	a4,9
    800047f6:	02d76863          	bltu	a4,a3,80004826 <fileread+0xba>
    800047fa:	0792                	slli	a5,a5,0x4
    800047fc:	0001d717          	auipc	a4,0x1d
    80004800:	b1c70713          	addi	a4,a4,-1252 # 80021318 <devsw>
    80004804:	97ba                	add	a5,a5,a4
    80004806:	639c                	ld	a5,0(a5)
    80004808:	c38d                	beqz	a5,8000482a <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    8000480a:	4505                	li	a0,1
    8000480c:	9782                	jalr	a5
    8000480e:	892a                	mv	s2,a0
    80004810:	bf75                	j	800047cc <fileread+0x60>
    panic("fileread");
    80004812:	00004517          	auipc	a0,0x4
    80004816:	ec650513          	addi	a0,a0,-314 # 800086d8 <syscalls+0x260>
    8000481a:	ffffc097          	auipc	ra,0xffffc
    8000481e:	d24080e7          	jalr	-732(ra) # 8000053e <panic>
    return -1;
    80004822:	597d                	li	s2,-1
    80004824:	b765                	j	800047cc <fileread+0x60>
      return -1;
    80004826:	597d                	li	s2,-1
    80004828:	b755                	j	800047cc <fileread+0x60>
    8000482a:	597d                	li	s2,-1
    8000482c:	b745                	j	800047cc <fileread+0x60>

000000008000482e <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    8000482e:	715d                	addi	sp,sp,-80
    80004830:	e486                	sd	ra,72(sp)
    80004832:	e0a2                	sd	s0,64(sp)
    80004834:	fc26                	sd	s1,56(sp)
    80004836:	f84a                	sd	s2,48(sp)
    80004838:	f44e                	sd	s3,40(sp)
    8000483a:	f052                	sd	s4,32(sp)
    8000483c:	ec56                	sd	s5,24(sp)
    8000483e:	e85a                	sd	s6,16(sp)
    80004840:	e45e                	sd	s7,8(sp)
    80004842:	e062                	sd	s8,0(sp)
    80004844:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004846:	00954783          	lbu	a5,9(a0)
    8000484a:	10078663          	beqz	a5,80004956 <filewrite+0x128>
    8000484e:	892a                	mv	s2,a0
    80004850:	8aae                	mv	s5,a1
    80004852:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004854:	411c                	lw	a5,0(a0)
    80004856:	4705                	li	a4,1
    80004858:	02e78263          	beq	a5,a4,8000487c <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000485c:	470d                	li	a4,3
    8000485e:	02e78663          	beq	a5,a4,8000488a <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004862:	4709                	li	a4,2
    80004864:	0ee79163          	bne	a5,a4,80004946 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004868:	0ac05d63          	blez	a2,80004922 <filewrite+0xf4>
    int i = 0;
    8000486c:	4981                	li	s3,0
    8000486e:	6b05                	lui	s6,0x1
    80004870:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004874:	6b85                	lui	s7,0x1
    80004876:	c00b8b9b          	addiw	s7,s7,-1024
    8000487a:	a861                	j	80004912 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    8000487c:	6908                	ld	a0,16(a0)
    8000487e:	00000097          	auipc	ra,0x0
    80004882:	22e080e7          	jalr	558(ra) # 80004aac <pipewrite>
    80004886:	8a2a                	mv	s4,a0
    80004888:	a045                	j	80004928 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    8000488a:	02451783          	lh	a5,36(a0)
    8000488e:	03079693          	slli	a3,a5,0x30
    80004892:	92c1                	srli	a3,a3,0x30
    80004894:	4725                	li	a4,9
    80004896:	0cd76263          	bltu	a4,a3,8000495a <filewrite+0x12c>
    8000489a:	0792                	slli	a5,a5,0x4
    8000489c:	0001d717          	auipc	a4,0x1d
    800048a0:	a7c70713          	addi	a4,a4,-1412 # 80021318 <devsw>
    800048a4:	97ba                	add	a5,a5,a4
    800048a6:	679c                	ld	a5,8(a5)
    800048a8:	cbdd                	beqz	a5,8000495e <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800048aa:	4505                	li	a0,1
    800048ac:	9782                	jalr	a5
    800048ae:	8a2a                	mv	s4,a0
    800048b0:	a8a5                	j	80004928 <filewrite+0xfa>
    800048b2:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800048b6:	00000097          	auipc	ra,0x0
    800048ba:	8b0080e7          	jalr	-1872(ra) # 80004166 <begin_op>
      ilock(f->ip);
    800048be:	01893503          	ld	a0,24(s2)
    800048c2:	fffff097          	auipc	ra,0xfffff
    800048c6:	ed2080e7          	jalr	-302(ra) # 80003794 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800048ca:	8762                	mv	a4,s8
    800048cc:	02092683          	lw	a3,32(s2)
    800048d0:	01598633          	add	a2,s3,s5
    800048d4:	4585                	li	a1,1
    800048d6:	01893503          	ld	a0,24(s2)
    800048da:	fffff097          	auipc	ra,0xfffff
    800048de:	266080e7          	jalr	614(ra) # 80003b40 <writei>
    800048e2:	84aa                	mv	s1,a0
    800048e4:	00a05763          	blez	a0,800048f2 <filewrite+0xc4>
        f->off += r;
    800048e8:	02092783          	lw	a5,32(s2)
    800048ec:	9fa9                	addw	a5,a5,a0
    800048ee:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800048f2:	01893503          	ld	a0,24(s2)
    800048f6:	fffff097          	auipc	ra,0xfffff
    800048fa:	f60080e7          	jalr	-160(ra) # 80003856 <iunlock>
      end_op();
    800048fe:	00000097          	auipc	ra,0x0
    80004902:	8e8080e7          	jalr	-1816(ra) # 800041e6 <end_op>

      if(r != n1){
    80004906:	009c1f63          	bne	s8,s1,80004924 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    8000490a:	013489bb          	addw	s3,s1,s3
    while(i < n){
    8000490e:	0149db63          	bge	s3,s4,80004924 <filewrite+0xf6>
      int n1 = n - i;
    80004912:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004916:	84be                	mv	s1,a5
    80004918:	2781                	sext.w	a5,a5
    8000491a:	f8fb5ce3          	bge	s6,a5,800048b2 <filewrite+0x84>
    8000491e:	84de                	mv	s1,s7
    80004920:	bf49                	j	800048b2 <filewrite+0x84>
    int i = 0;
    80004922:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004924:	013a1f63          	bne	s4,s3,80004942 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004928:	8552                	mv	a0,s4
    8000492a:	60a6                	ld	ra,72(sp)
    8000492c:	6406                	ld	s0,64(sp)
    8000492e:	74e2                	ld	s1,56(sp)
    80004930:	7942                	ld	s2,48(sp)
    80004932:	79a2                	ld	s3,40(sp)
    80004934:	7a02                	ld	s4,32(sp)
    80004936:	6ae2                	ld	s5,24(sp)
    80004938:	6b42                	ld	s6,16(sp)
    8000493a:	6ba2                	ld	s7,8(sp)
    8000493c:	6c02                	ld	s8,0(sp)
    8000493e:	6161                	addi	sp,sp,80
    80004940:	8082                	ret
    ret = (i == n ? n : -1);
    80004942:	5a7d                	li	s4,-1
    80004944:	b7d5                	j	80004928 <filewrite+0xfa>
    panic("filewrite");
    80004946:	00004517          	auipc	a0,0x4
    8000494a:	da250513          	addi	a0,a0,-606 # 800086e8 <syscalls+0x270>
    8000494e:	ffffc097          	auipc	ra,0xffffc
    80004952:	bf0080e7          	jalr	-1040(ra) # 8000053e <panic>
    return -1;
    80004956:	5a7d                	li	s4,-1
    80004958:	bfc1                	j	80004928 <filewrite+0xfa>
      return -1;
    8000495a:	5a7d                	li	s4,-1
    8000495c:	b7f1                	j	80004928 <filewrite+0xfa>
    8000495e:	5a7d                	li	s4,-1
    80004960:	b7e1                	j	80004928 <filewrite+0xfa>

0000000080004962 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004962:	7179                	addi	sp,sp,-48
    80004964:	f406                	sd	ra,40(sp)
    80004966:	f022                	sd	s0,32(sp)
    80004968:	ec26                	sd	s1,24(sp)
    8000496a:	e84a                	sd	s2,16(sp)
    8000496c:	e44e                	sd	s3,8(sp)
    8000496e:	e052                	sd	s4,0(sp)
    80004970:	1800                	addi	s0,sp,48
    80004972:	84aa                	mv	s1,a0
    80004974:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004976:	0005b023          	sd	zero,0(a1)
    8000497a:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    8000497e:	00000097          	auipc	ra,0x0
    80004982:	bf8080e7          	jalr	-1032(ra) # 80004576 <filealloc>
    80004986:	e088                	sd	a0,0(s1)
    80004988:	c551                	beqz	a0,80004a14 <pipealloc+0xb2>
    8000498a:	00000097          	auipc	ra,0x0
    8000498e:	bec080e7          	jalr	-1044(ra) # 80004576 <filealloc>
    80004992:	00aa3023          	sd	a0,0(s4)
    80004996:	c92d                	beqz	a0,80004a08 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004998:	ffffc097          	auipc	ra,0xffffc
    8000499c:	15c080e7          	jalr	348(ra) # 80000af4 <kalloc>
    800049a0:	892a                	mv	s2,a0
    800049a2:	c125                	beqz	a0,80004a02 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800049a4:	4985                	li	s3,1
    800049a6:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800049aa:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800049ae:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800049b2:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800049b6:	00004597          	auipc	a1,0x4
    800049ba:	d4258593          	addi	a1,a1,-702 # 800086f8 <syscalls+0x280>
    800049be:	ffffc097          	auipc	ra,0xffffc
    800049c2:	196080e7          	jalr	406(ra) # 80000b54 <initlock>
  (*f0)->type = FD_PIPE;
    800049c6:	609c                	ld	a5,0(s1)
    800049c8:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800049cc:	609c                	ld	a5,0(s1)
    800049ce:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800049d2:	609c                	ld	a5,0(s1)
    800049d4:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800049d8:	609c                	ld	a5,0(s1)
    800049da:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800049de:	000a3783          	ld	a5,0(s4)
    800049e2:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800049e6:	000a3783          	ld	a5,0(s4)
    800049ea:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800049ee:	000a3783          	ld	a5,0(s4)
    800049f2:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800049f6:	000a3783          	ld	a5,0(s4)
    800049fa:	0127b823          	sd	s2,16(a5)
  return 0;
    800049fe:	4501                	li	a0,0
    80004a00:	a025                	j	80004a28 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004a02:	6088                	ld	a0,0(s1)
    80004a04:	e501                	bnez	a0,80004a0c <pipealloc+0xaa>
    80004a06:	a039                	j	80004a14 <pipealloc+0xb2>
    80004a08:	6088                	ld	a0,0(s1)
    80004a0a:	c51d                	beqz	a0,80004a38 <pipealloc+0xd6>
    fileclose(*f0);
    80004a0c:	00000097          	auipc	ra,0x0
    80004a10:	c26080e7          	jalr	-986(ra) # 80004632 <fileclose>
  if(*f1)
    80004a14:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004a18:	557d                	li	a0,-1
  if(*f1)
    80004a1a:	c799                	beqz	a5,80004a28 <pipealloc+0xc6>
    fileclose(*f1);
    80004a1c:	853e                	mv	a0,a5
    80004a1e:	00000097          	auipc	ra,0x0
    80004a22:	c14080e7          	jalr	-1004(ra) # 80004632 <fileclose>
  return -1;
    80004a26:	557d                	li	a0,-1
}
    80004a28:	70a2                	ld	ra,40(sp)
    80004a2a:	7402                	ld	s0,32(sp)
    80004a2c:	64e2                	ld	s1,24(sp)
    80004a2e:	6942                	ld	s2,16(sp)
    80004a30:	69a2                	ld	s3,8(sp)
    80004a32:	6a02                	ld	s4,0(sp)
    80004a34:	6145                	addi	sp,sp,48
    80004a36:	8082                	ret
  return -1;
    80004a38:	557d                	li	a0,-1
    80004a3a:	b7fd                	j	80004a28 <pipealloc+0xc6>

0000000080004a3c <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004a3c:	1101                	addi	sp,sp,-32
    80004a3e:	ec06                	sd	ra,24(sp)
    80004a40:	e822                	sd	s0,16(sp)
    80004a42:	e426                	sd	s1,8(sp)
    80004a44:	e04a                	sd	s2,0(sp)
    80004a46:	1000                	addi	s0,sp,32
    80004a48:	84aa                	mv	s1,a0
    80004a4a:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004a4c:	ffffc097          	auipc	ra,0xffffc
    80004a50:	198080e7          	jalr	408(ra) # 80000be4 <acquire>
  if(writable){
    80004a54:	02090d63          	beqz	s2,80004a8e <pipeclose+0x52>
    pi->writeopen = 0;
    80004a58:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004a5c:	21848513          	addi	a0,s1,536
    80004a60:	ffffe097          	auipc	ra,0xffffe
    80004a64:	87c080e7          	jalr	-1924(ra) # 800022dc <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004a68:	2204b783          	ld	a5,544(s1)
    80004a6c:	eb95                	bnez	a5,80004aa0 <pipeclose+0x64>
    release(&pi->lock);
    80004a6e:	8526                	mv	a0,s1
    80004a70:	ffffc097          	auipc	ra,0xffffc
    80004a74:	228080e7          	jalr	552(ra) # 80000c98 <release>
    kfree((char*)pi);
    80004a78:	8526                	mv	a0,s1
    80004a7a:	ffffc097          	auipc	ra,0xffffc
    80004a7e:	f7e080e7          	jalr	-130(ra) # 800009f8 <kfree>
  } else
    release(&pi->lock);
}
    80004a82:	60e2                	ld	ra,24(sp)
    80004a84:	6442                	ld	s0,16(sp)
    80004a86:	64a2                	ld	s1,8(sp)
    80004a88:	6902                	ld	s2,0(sp)
    80004a8a:	6105                	addi	sp,sp,32
    80004a8c:	8082                	ret
    pi->readopen = 0;
    80004a8e:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004a92:	21c48513          	addi	a0,s1,540
    80004a96:	ffffe097          	auipc	ra,0xffffe
    80004a9a:	846080e7          	jalr	-1978(ra) # 800022dc <wakeup>
    80004a9e:	b7e9                	j	80004a68 <pipeclose+0x2c>
    release(&pi->lock);
    80004aa0:	8526                	mv	a0,s1
    80004aa2:	ffffc097          	auipc	ra,0xffffc
    80004aa6:	1f6080e7          	jalr	502(ra) # 80000c98 <release>
}
    80004aaa:	bfe1                	j	80004a82 <pipeclose+0x46>

0000000080004aac <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004aac:	7159                	addi	sp,sp,-112
    80004aae:	f486                	sd	ra,104(sp)
    80004ab0:	f0a2                	sd	s0,96(sp)
    80004ab2:	eca6                	sd	s1,88(sp)
    80004ab4:	e8ca                	sd	s2,80(sp)
    80004ab6:	e4ce                	sd	s3,72(sp)
    80004ab8:	e0d2                	sd	s4,64(sp)
    80004aba:	fc56                	sd	s5,56(sp)
    80004abc:	f85a                	sd	s6,48(sp)
    80004abe:	f45e                	sd	s7,40(sp)
    80004ac0:	f062                	sd	s8,32(sp)
    80004ac2:	ec66                	sd	s9,24(sp)
    80004ac4:	1880                	addi	s0,sp,112
    80004ac6:	84aa                	mv	s1,a0
    80004ac8:	8aae                	mv	s5,a1
    80004aca:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004acc:	ffffd097          	auipc	ra,0xffffd
    80004ad0:	fc8080e7          	jalr	-56(ra) # 80001a94 <myproc>
    80004ad4:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004ad6:	8526                	mv	a0,s1
    80004ad8:	ffffc097          	auipc	ra,0xffffc
    80004adc:	10c080e7          	jalr	268(ra) # 80000be4 <acquire>
  while(i < n){
    80004ae0:	0d405163          	blez	s4,80004ba2 <pipewrite+0xf6>
    80004ae4:	8ba6                	mv	s7,s1
  int i = 0;
    80004ae6:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ae8:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004aea:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004aee:	21c48c13          	addi	s8,s1,540
    80004af2:	a08d                	j	80004b54 <pipewrite+0xa8>
      release(&pi->lock);
    80004af4:	8526                	mv	a0,s1
    80004af6:	ffffc097          	auipc	ra,0xffffc
    80004afa:	1a2080e7          	jalr	418(ra) # 80000c98 <release>
      return -1;
    80004afe:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004b00:	854a                	mv	a0,s2
    80004b02:	70a6                	ld	ra,104(sp)
    80004b04:	7406                	ld	s0,96(sp)
    80004b06:	64e6                	ld	s1,88(sp)
    80004b08:	6946                	ld	s2,80(sp)
    80004b0a:	69a6                	ld	s3,72(sp)
    80004b0c:	6a06                	ld	s4,64(sp)
    80004b0e:	7ae2                	ld	s5,56(sp)
    80004b10:	7b42                	ld	s6,48(sp)
    80004b12:	7ba2                	ld	s7,40(sp)
    80004b14:	7c02                	ld	s8,32(sp)
    80004b16:	6ce2                	ld	s9,24(sp)
    80004b18:	6165                	addi	sp,sp,112
    80004b1a:	8082                	ret
      wakeup(&pi->nread);
    80004b1c:	8566                	mv	a0,s9
    80004b1e:	ffffd097          	auipc	ra,0xffffd
    80004b22:	7be080e7          	jalr	1982(ra) # 800022dc <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004b26:	85de                	mv	a1,s7
    80004b28:	8562                	mv	a0,s8
    80004b2a:	ffffd097          	auipc	ra,0xffffd
    80004b2e:	626080e7          	jalr	1574(ra) # 80002150 <sleep>
    80004b32:	a839                	j	80004b50 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004b34:	21c4a783          	lw	a5,540(s1)
    80004b38:	0017871b          	addiw	a4,a5,1
    80004b3c:	20e4ae23          	sw	a4,540(s1)
    80004b40:	1ff7f793          	andi	a5,a5,511
    80004b44:	97a6                	add	a5,a5,s1
    80004b46:	f9f44703          	lbu	a4,-97(s0)
    80004b4a:	00e78c23          	sb	a4,24(a5)
      i++;
    80004b4e:	2905                	addiw	s2,s2,1
  while(i < n){
    80004b50:	03495d63          	bge	s2,s4,80004b8a <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004b54:	2204a783          	lw	a5,544(s1)
    80004b58:	dfd1                	beqz	a5,80004af4 <pipewrite+0x48>
    80004b5a:	0289a783          	lw	a5,40(s3)
    80004b5e:	fbd9                	bnez	a5,80004af4 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004b60:	2184a783          	lw	a5,536(s1)
    80004b64:	21c4a703          	lw	a4,540(s1)
    80004b68:	2007879b          	addiw	a5,a5,512
    80004b6c:	faf708e3          	beq	a4,a5,80004b1c <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b70:	4685                	li	a3,1
    80004b72:	01590633          	add	a2,s2,s5
    80004b76:	f9f40593          	addi	a1,s0,-97
    80004b7a:	0509b503          	ld	a0,80(s3)
    80004b7e:	ffffd097          	auipc	ra,0xffffd
    80004b82:	b80080e7          	jalr	-1152(ra) # 800016fe <copyin>
    80004b86:	fb6517e3          	bne	a0,s6,80004b34 <pipewrite+0x88>
  wakeup(&pi->nread);
    80004b8a:	21848513          	addi	a0,s1,536
    80004b8e:	ffffd097          	auipc	ra,0xffffd
    80004b92:	74e080e7          	jalr	1870(ra) # 800022dc <wakeup>
  release(&pi->lock);
    80004b96:	8526                	mv	a0,s1
    80004b98:	ffffc097          	auipc	ra,0xffffc
    80004b9c:	100080e7          	jalr	256(ra) # 80000c98 <release>
  return i;
    80004ba0:	b785                	j	80004b00 <pipewrite+0x54>
  int i = 0;
    80004ba2:	4901                	li	s2,0
    80004ba4:	b7dd                	j	80004b8a <pipewrite+0xde>

0000000080004ba6 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004ba6:	715d                	addi	sp,sp,-80
    80004ba8:	e486                	sd	ra,72(sp)
    80004baa:	e0a2                	sd	s0,64(sp)
    80004bac:	fc26                	sd	s1,56(sp)
    80004bae:	f84a                	sd	s2,48(sp)
    80004bb0:	f44e                	sd	s3,40(sp)
    80004bb2:	f052                	sd	s4,32(sp)
    80004bb4:	ec56                	sd	s5,24(sp)
    80004bb6:	e85a                	sd	s6,16(sp)
    80004bb8:	0880                	addi	s0,sp,80
    80004bba:	84aa                	mv	s1,a0
    80004bbc:	892e                	mv	s2,a1
    80004bbe:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004bc0:	ffffd097          	auipc	ra,0xffffd
    80004bc4:	ed4080e7          	jalr	-300(ra) # 80001a94 <myproc>
    80004bc8:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004bca:	8b26                	mv	s6,s1
    80004bcc:	8526                	mv	a0,s1
    80004bce:	ffffc097          	auipc	ra,0xffffc
    80004bd2:	016080e7          	jalr	22(ra) # 80000be4 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004bd6:	2184a703          	lw	a4,536(s1)
    80004bda:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004bde:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004be2:	02f71463          	bne	a4,a5,80004c0a <piperead+0x64>
    80004be6:	2244a783          	lw	a5,548(s1)
    80004bea:	c385                	beqz	a5,80004c0a <piperead+0x64>
    if(pr->killed){
    80004bec:	028a2783          	lw	a5,40(s4)
    80004bf0:	ebc1                	bnez	a5,80004c80 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004bf2:	85da                	mv	a1,s6
    80004bf4:	854e                	mv	a0,s3
    80004bf6:	ffffd097          	auipc	ra,0xffffd
    80004bfa:	55a080e7          	jalr	1370(ra) # 80002150 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004bfe:	2184a703          	lw	a4,536(s1)
    80004c02:	21c4a783          	lw	a5,540(s1)
    80004c06:	fef700e3          	beq	a4,a5,80004be6 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c0a:	09505263          	blez	s5,80004c8e <piperead+0xe8>
    80004c0e:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c10:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004c12:	2184a783          	lw	a5,536(s1)
    80004c16:	21c4a703          	lw	a4,540(s1)
    80004c1a:	02f70d63          	beq	a4,a5,80004c54 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004c1e:	0017871b          	addiw	a4,a5,1
    80004c22:	20e4ac23          	sw	a4,536(s1)
    80004c26:	1ff7f793          	andi	a5,a5,511
    80004c2a:	97a6                	add	a5,a5,s1
    80004c2c:	0187c783          	lbu	a5,24(a5)
    80004c30:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c34:	4685                	li	a3,1
    80004c36:	fbf40613          	addi	a2,s0,-65
    80004c3a:	85ca                	mv	a1,s2
    80004c3c:	050a3503          	ld	a0,80(s4)
    80004c40:	ffffd097          	auipc	ra,0xffffd
    80004c44:	a32080e7          	jalr	-1486(ra) # 80001672 <copyout>
    80004c48:	01650663          	beq	a0,s6,80004c54 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c4c:	2985                	addiw	s3,s3,1
    80004c4e:	0905                	addi	s2,s2,1
    80004c50:	fd3a91e3          	bne	s5,s3,80004c12 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004c54:	21c48513          	addi	a0,s1,540
    80004c58:	ffffd097          	auipc	ra,0xffffd
    80004c5c:	684080e7          	jalr	1668(ra) # 800022dc <wakeup>
  release(&pi->lock);
    80004c60:	8526                	mv	a0,s1
    80004c62:	ffffc097          	auipc	ra,0xffffc
    80004c66:	036080e7          	jalr	54(ra) # 80000c98 <release>
  return i;
}
    80004c6a:	854e                	mv	a0,s3
    80004c6c:	60a6                	ld	ra,72(sp)
    80004c6e:	6406                	ld	s0,64(sp)
    80004c70:	74e2                	ld	s1,56(sp)
    80004c72:	7942                	ld	s2,48(sp)
    80004c74:	79a2                	ld	s3,40(sp)
    80004c76:	7a02                	ld	s4,32(sp)
    80004c78:	6ae2                	ld	s5,24(sp)
    80004c7a:	6b42                	ld	s6,16(sp)
    80004c7c:	6161                	addi	sp,sp,80
    80004c7e:	8082                	ret
      release(&pi->lock);
    80004c80:	8526                	mv	a0,s1
    80004c82:	ffffc097          	auipc	ra,0xffffc
    80004c86:	016080e7          	jalr	22(ra) # 80000c98 <release>
      return -1;
    80004c8a:	59fd                	li	s3,-1
    80004c8c:	bff9                	j	80004c6a <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c8e:	4981                	li	s3,0
    80004c90:	b7d1                	j	80004c54 <piperead+0xae>

0000000080004c92 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004c92:	df010113          	addi	sp,sp,-528
    80004c96:	20113423          	sd	ra,520(sp)
    80004c9a:	20813023          	sd	s0,512(sp)
    80004c9e:	ffa6                	sd	s1,504(sp)
    80004ca0:	fbca                	sd	s2,496(sp)
    80004ca2:	f7ce                	sd	s3,488(sp)
    80004ca4:	f3d2                	sd	s4,480(sp)
    80004ca6:	efd6                	sd	s5,472(sp)
    80004ca8:	ebda                	sd	s6,464(sp)
    80004caa:	e7de                	sd	s7,456(sp)
    80004cac:	e3e2                	sd	s8,448(sp)
    80004cae:	ff66                	sd	s9,440(sp)
    80004cb0:	fb6a                	sd	s10,432(sp)
    80004cb2:	f76e                	sd	s11,424(sp)
    80004cb4:	0c00                	addi	s0,sp,528
    80004cb6:	84aa                	mv	s1,a0
    80004cb8:	dea43c23          	sd	a0,-520(s0)
    80004cbc:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004cc0:	ffffd097          	auipc	ra,0xffffd
    80004cc4:	dd4080e7          	jalr	-556(ra) # 80001a94 <myproc>
    80004cc8:	892a                	mv	s2,a0

  begin_op();
    80004cca:	fffff097          	auipc	ra,0xfffff
    80004cce:	49c080e7          	jalr	1180(ra) # 80004166 <begin_op>

  if((ip = namei(path)) == 0){
    80004cd2:	8526                	mv	a0,s1
    80004cd4:	fffff097          	auipc	ra,0xfffff
    80004cd8:	276080e7          	jalr	630(ra) # 80003f4a <namei>
    80004cdc:	c92d                	beqz	a0,80004d4e <exec+0xbc>
    80004cde:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004ce0:	fffff097          	auipc	ra,0xfffff
    80004ce4:	ab4080e7          	jalr	-1356(ra) # 80003794 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004ce8:	04000713          	li	a4,64
    80004cec:	4681                	li	a3,0
    80004cee:	e5040613          	addi	a2,s0,-432
    80004cf2:	4581                	li	a1,0
    80004cf4:	8526                	mv	a0,s1
    80004cf6:	fffff097          	auipc	ra,0xfffff
    80004cfa:	d52080e7          	jalr	-686(ra) # 80003a48 <readi>
    80004cfe:	04000793          	li	a5,64
    80004d02:	00f51a63          	bne	a0,a5,80004d16 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004d06:	e5042703          	lw	a4,-432(s0)
    80004d0a:	464c47b7          	lui	a5,0x464c4
    80004d0e:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004d12:	04f70463          	beq	a4,a5,80004d5a <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004d16:	8526                	mv	a0,s1
    80004d18:	fffff097          	auipc	ra,0xfffff
    80004d1c:	cde080e7          	jalr	-802(ra) # 800039f6 <iunlockput>
    end_op();
    80004d20:	fffff097          	auipc	ra,0xfffff
    80004d24:	4c6080e7          	jalr	1222(ra) # 800041e6 <end_op>
  }
  return -1;
    80004d28:	557d                	li	a0,-1
}
    80004d2a:	20813083          	ld	ra,520(sp)
    80004d2e:	20013403          	ld	s0,512(sp)
    80004d32:	74fe                	ld	s1,504(sp)
    80004d34:	795e                	ld	s2,496(sp)
    80004d36:	79be                	ld	s3,488(sp)
    80004d38:	7a1e                	ld	s4,480(sp)
    80004d3a:	6afe                	ld	s5,472(sp)
    80004d3c:	6b5e                	ld	s6,464(sp)
    80004d3e:	6bbe                	ld	s7,456(sp)
    80004d40:	6c1e                	ld	s8,448(sp)
    80004d42:	7cfa                	ld	s9,440(sp)
    80004d44:	7d5a                	ld	s10,432(sp)
    80004d46:	7dba                	ld	s11,424(sp)
    80004d48:	21010113          	addi	sp,sp,528
    80004d4c:	8082                	ret
    end_op();
    80004d4e:	fffff097          	auipc	ra,0xfffff
    80004d52:	498080e7          	jalr	1176(ra) # 800041e6 <end_op>
    return -1;
    80004d56:	557d                	li	a0,-1
    80004d58:	bfc9                	j	80004d2a <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004d5a:	854a                	mv	a0,s2
    80004d5c:	ffffd097          	auipc	ra,0xffffd
    80004d60:	dfc080e7          	jalr	-516(ra) # 80001b58 <proc_pagetable>
    80004d64:	8baa                	mv	s7,a0
    80004d66:	d945                	beqz	a0,80004d16 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d68:	e7042983          	lw	s3,-400(s0)
    80004d6c:	e8845783          	lhu	a5,-376(s0)
    80004d70:	c7ad                	beqz	a5,80004dda <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004d72:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d74:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80004d76:	6c85                	lui	s9,0x1
    80004d78:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004d7c:	def43823          	sd	a5,-528(s0)
    80004d80:	ac1d                	j	80004fb6 <exec+0x324>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004d82:	00004517          	auipc	a0,0x4
    80004d86:	97e50513          	addi	a0,a0,-1666 # 80008700 <syscalls+0x288>
    80004d8a:	ffffb097          	auipc	ra,0xffffb
    80004d8e:	7b4080e7          	jalr	1972(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004d92:	8756                	mv	a4,s5
    80004d94:	012d86bb          	addw	a3,s11,s2
    80004d98:	4581                	li	a1,0
    80004d9a:	8526                	mv	a0,s1
    80004d9c:	fffff097          	auipc	ra,0xfffff
    80004da0:	cac080e7          	jalr	-852(ra) # 80003a48 <readi>
    80004da4:	2501                	sext.w	a0,a0
    80004da6:	1aaa9f63          	bne	s5,a0,80004f64 <exec+0x2d2>
  for(i = 0; i < sz; i += PGSIZE){
    80004daa:	6785                	lui	a5,0x1
    80004dac:	0127893b          	addw	s2,a5,s2
    80004db0:	77fd                	lui	a5,0xfffff
    80004db2:	01478a3b          	addw	s4,a5,s4
    80004db6:	1f897763          	bgeu	s2,s8,80004fa4 <exec+0x312>
    pa = walkaddr(pagetable, va + i);
    80004dba:	02091593          	slli	a1,s2,0x20
    80004dbe:	9181                	srli	a1,a1,0x20
    80004dc0:	95ea                	add	a1,a1,s10
    80004dc2:	855e                	mv	a0,s7
    80004dc4:	ffffc097          	auipc	ra,0xffffc
    80004dc8:	2aa080e7          	jalr	682(ra) # 8000106e <walkaddr>
    80004dcc:	862a                	mv	a2,a0
    if(pa == 0)
    80004dce:	d955                	beqz	a0,80004d82 <exec+0xf0>
      n = PGSIZE;
    80004dd0:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004dd2:	fd9a70e3          	bgeu	s4,s9,80004d92 <exec+0x100>
      n = sz - i;
    80004dd6:	8ad2                	mv	s5,s4
    80004dd8:	bf6d                	j	80004d92 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004dda:	4901                	li	s2,0
  iunlockput(ip);
    80004ddc:	8526                	mv	a0,s1
    80004dde:	fffff097          	auipc	ra,0xfffff
    80004de2:	c18080e7          	jalr	-1000(ra) # 800039f6 <iunlockput>
  end_op();
    80004de6:	fffff097          	auipc	ra,0xfffff
    80004dea:	400080e7          	jalr	1024(ra) # 800041e6 <end_op>
  p = myproc();
    80004dee:	ffffd097          	auipc	ra,0xffffd
    80004df2:	ca6080e7          	jalr	-858(ra) # 80001a94 <myproc>
    80004df6:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004df8:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004dfc:	6785                	lui	a5,0x1
    80004dfe:	17fd                	addi	a5,a5,-1
    80004e00:	993e                	add	s2,s2,a5
    80004e02:	757d                	lui	a0,0xfffff
    80004e04:	00a977b3          	and	a5,s2,a0
    80004e08:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004e0c:	6609                	lui	a2,0x2
    80004e0e:	963e                	add	a2,a2,a5
    80004e10:	85be                	mv	a1,a5
    80004e12:	855e                	mv	a0,s7
    80004e14:	ffffc097          	auipc	ra,0xffffc
    80004e18:	60e080e7          	jalr	1550(ra) # 80001422 <uvmalloc>
    80004e1c:	8b2a                	mv	s6,a0
  ip = 0;
    80004e1e:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004e20:	14050263          	beqz	a0,80004f64 <exec+0x2d2>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004e24:	75f9                	lui	a1,0xffffe
    80004e26:	95aa                	add	a1,a1,a0
    80004e28:	855e                	mv	a0,s7
    80004e2a:	ffffd097          	auipc	ra,0xffffd
    80004e2e:	816080e7          	jalr	-2026(ra) # 80001640 <uvmclear>
  stackbase = sp - PGSIZE;
    80004e32:	7c7d                	lui	s8,0xfffff
    80004e34:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004e36:	e0043783          	ld	a5,-512(s0)
    80004e3a:	6388                	ld	a0,0(a5)
    80004e3c:	c535                	beqz	a0,80004ea8 <exec+0x216>
    80004e3e:	e9040993          	addi	s3,s0,-368
    80004e42:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004e46:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004e48:	ffffc097          	auipc	ra,0xffffc
    80004e4c:	01c080e7          	jalr	28(ra) # 80000e64 <strlen>
    80004e50:	2505                	addiw	a0,a0,1
    80004e52:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004e56:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004e5a:	13896963          	bltu	s2,s8,80004f8c <exec+0x2fa>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004e5e:	e0043d83          	ld	s11,-512(s0)
    80004e62:	000dba03          	ld	s4,0(s11)
    80004e66:	8552                	mv	a0,s4
    80004e68:	ffffc097          	auipc	ra,0xffffc
    80004e6c:	ffc080e7          	jalr	-4(ra) # 80000e64 <strlen>
    80004e70:	0015069b          	addiw	a3,a0,1
    80004e74:	8652                	mv	a2,s4
    80004e76:	85ca                	mv	a1,s2
    80004e78:	855e                	mv	a0,s7
    80004e7a:	ffffc097          	auipc	ra,0xffffc
    80004e7e:	7f8080e7          	jalr	2040(ra) # 80001672 <copyout>
    80004e82:	10054963          	bltz	a0,80004f94 <exec+0x302>
    ustack[argc] = sp;
    80004e86:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004e8a:	0485                	addi	s1,s1,1
    80004e8c:	008d8793          	addi	a5,s11,8
    80004e90:	e0f43023          	sd	a5,-512(s0)
    80004e94:	008db503          	ld	a0,8(s11)
    80004e98:	c911                	beqz	a0,80004eac <exec+0x21a>
    if(argc >= MAXARG)
    80004e9a:	09a1                	addi	s3,s3,8
    80004e9c:	fb3c96e3          	bne	s9,s3,80004e48 <exec+0x1b6>
  sz = sz1;
    80004ea0:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004ea4:	4481                	li	s1,0
    80004ea6:	a87d                	j	80004f64 <exec+0x2d2>
  sp = sz;
    80004ea8:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004eaa:	4481                	li	s1,0
  ustack[argc] = 0;
    80004eac:	00349793          	slli	a5,s1,0x3
    80004eb0:	f9040713          	addi	a4,s0,-112
    80004eb4:	97ba                	add	a5,a5,a4
    80004eb6:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80004eba:	00148693          	addi	a3,s1,1
    80004ebe:	068e                	slli	a3,a3,0x3
    80004ec0:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004ec4:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004ec8:	01897663          	bgeu	s2,s8,80004ed4 <exec+0x242>
  sz = sz1;
    80004ecc:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004ed0:	4481                	li	s1,0
    80004ed2:	a849                	j	80004f64 <exec+0x2d2>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004ed4:	e9040613          	addi	a2,s0,-368
    80004ed8:	85ca                	mv	a1,s2
    80004eda:	855e                	mv	a0,s7
    80004edc:	ffffc097          	auipc	ra,0xffffc
    80004ee0:	796080e7          	jalr	1942(ra) # 80001672 <copyout>
    80004ee4:	0a054c63          	bltz	a0,80004f9c <exec+0x30a>
  p->trapframe->a1 = sp;
    80004ee8:	058ab783          	ld	a5,88(s5)
    80004eec:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004ef0:	df843783          	ld	a5,-520(s0)
    80004ef4:	0007c703          	lbu	a4,0(a5)
    80004ef8:	cf11                	beqz	a4,80004f14 <exec+0x282>
    80004efa:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004efc:	02f00693          	li	a3,47
    80004f00:	a039                	j	80004f0e <exec+0x27c>
      last = s+1;
    80004f02:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80004f06:	0785                	addi	a5,a5,1
    80004f08:	fff7c703          	lbu	a4,-1(a5)
    80004f0c:	c701                	beqz	a4,80004f14 <exec+0x282>
    if(*s == '/')
    80004f0e:	fed71ce3          	bne	a4,a3,80004f06 <exec+0x274>
    80004f12:	bfc5                	j	80004f02 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80004f14:	4641                	li	a2,16
    80004f16:	df843583          	ld	a1,-520(s0)
    80004f1a:	158a8513          	addi	a0,s5,344
    80004f1e:	ffffc097          	auipc	ra,0xffffc
    80004f22:	f14080e7          	jalr	-236(ra) # 80000e32 <safestrcpy>
  oldpagetable = p->pagetable;
    80004f26:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004f2a:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80004f2e:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004f32:	058ab783          	ld	a5,88(s5)
    80004f36:	e6843703          	ld	a4,-408(s0)
    80004f3a:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004f3c:	058ab783          	ld	a5,88(s5)
    80004f40:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004f44:	85ea                	mv	a1,s10
    80004f46:	ffffd097          	auipc	ra,0xffffd
    80004f4a:	cae080e7          	jalr	-850(ra) # 80001bf4 <proc_freepagetable>
  ptableprint(p->pagetable);
    80004f4e:	050ab503          	ld	a0,80(s5)
    80004f52:	ffffd097          	auipc	ra,0xffffd
    80004f56:	99c080e7          	jalr	-1636(ra) # 800018ee <ptableprint>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004f5a:	0004851b          	sext.w	a0,s1
    80004f5e:	b3f1                	j	80004d2a <exec+0x98>
    80004f60:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004f64:	e0843583          	ld	a1,-504(s0)
    80004f68:	855e                	mv	a0,s7
    80004f6a:	ffffd097          	auipc	ra,0xffffd
    80004f6e:	c8a080e7          	jalr	-886(ra) # 80001bf4 <proc_freepagetable>
  if(ip){
    80004f72:	da0492e3          	bnez	s1,80004d16 <exec+0x84>
  return -1;
    80004f76:	557d                	li	a0,-1
    80004f78:	bb4d                	j	80004d2a <exec+0x98>
    80004f7a:	e1243423          	sd	s2,-504(s0)
    80004f7e:	b7dd                	j	80004f64 <exec+0x2d2>
    80004f80:	e1243423          	sd	s2,-504(s0)
    80004f84:	b7c5                	j	80004f64 <exec+0x2d2>
    80004f86:	e1243423          	sd	s2,-504(s0)
    80004f8a:	bfe9                	j	80004f64 <exec+0x2d2>
  sz = sz1;
    80004f8c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f90:	4481                	li	s1,0
    80004f92:	bfc9                	j	80004f64 <exec+0x2d2>
  sz = sz1;
    80004f94:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f98:	4481                	li	s1,0
    80004f9a:	b7e9                	j	80004f64 <exec+0x2d2>
  sz = sz1;
    80004f9c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fa0:	4481                	li	s1,0
    80004fa2:	b7c9                	j	80004f64 <exec+0x2d2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004fa4:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004fa8:	2b05                	addiw	s6,s6,1
    80004faa:	0389899b          	addiw	s3,s3,56
    80004fae:	e8845783          	lhu	a5,-376(s0)
    80004fb2:	e2fb55e3          	bge	s6,a5,80004ddc <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004fb6:	2981                	sext.w	s3,s3
    80004fb8:	03800713          	li	a4,56
    80004fbc:	86ce                	mv	a3,s3
    80004fbe:	e1840613          	addi	a2,s0,-488
    80004fc2:	4581                	li	a1,0
    80004fc4:	8526                	mv	a0,s1
    80004fc6:	fffff097          	auipc	ra,0xfffff
    80004fca:	a82080e7          	jalr	-1406(ra) # 80003a48 <readi>
    80004fce:	03800793          	li	a5,56
    80004fd2:	f8f517e3          	bne	a0,a5,80004f60 <exec+0x2ce>
    if(ph.type != ELF_PROG_LOAD)
    80004fd6:	e1842783          	lw	a5,-488(s0)
    80004fda:	4705                	li	a4,1
    80004fdc:	fce796e3          	bne	a5,a4,80004fa8 <exec+0x316>
    if(ph.memsz < ph.filesz)
    80004fe0:	e4043603          	ld	a2,-448(s0)
    80004fe4:	e3843783          	ld	a5,-456(s0)
    80004fe8:	f8f669e3          	bltu	a2,a5,80004f7a <exec+0x2e8>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004fec:	e2843783          	ld	a5,-472(s0)
    80004ff0:	963e                	add	a2,a2,a5
    80004ff2:	f8f667e3          	bltu	a2,a5,80004f80 <exec+0x2ee>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004ff6:	85ca                	mv	a1,s2
    80004ff8:	855e                	mv	a0,s7
    80004ffa:	ffffc097          	auipc	ra,0xffffc
    80004ffe:	428080e7          	jalr	1064(ra) # 80001422 <uvmalloc>
    80005002:	e0a43423          	sd	a0,-504(s0)
    80005006:	d141                	beqz	a0,80004f86 <exec+0x2f4>
    if((ph.vaddr % PGSIZE) != 0)
    80005008:	e2843d03          	ld	s10,-472(s0)
    8000500c:	df043783          	ld	a5,-528(s0)
    80005010:	00fd77b3          	and	a5,s10,a5
    80005014:	fba1                	bnez	a5,80004f64 <exec+0x2d2>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005016:	e2042d83          	lw	s11,-480(s0)
    8000501a:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000501e:	f80c03e3          	beqz	s8,80004fa4 <exec+0x312>
    80005022:	8a62                	mv	s4,s8
    80005024:	4901                	li	s2,0
    80005026:	bb51                	j	80004dba <exec+0x128>

0000000080005028 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005028:	7179                	addi	sp,sp,-48
    8000502a:	f406                	sd	ra,40(sp)
    8000502c:	f022                	sd	s0,32(sp)
    8000502e:	ec26                	sd	s1,24(sp)
    80005030:	e84a                	sd	s2,16(sp)
    80005032:	1800                	addi	s0,sp,48
    80005034:	892e                	mv	s2,a1
    80005036:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005038:	fdc40593          	addi	a1,s0,-36
    8000503c:	ffffe097          	auipc	ra,0xffffe
    80005040:	b04080e7          	jalr	-1276(ra) # 80002b40 <argint>
    80005044:	04054063          	bltz	a0,80005084 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005048:	fdc42703          	lw	a4,-36(s0)
    8000504c:	47bd                	li	a5,15
    8000504e:	02e7ed63          	bltu	a5,a4,80005088 <argfd+0x60>
    80005052:	ffffd097          	auipc	ra,0xffffd
    80005056:	a42080e7          	jalr	-1470(ra) # 80001a94 <myproc>
    8000505a:	fdc42703          	lw	a4,-36(s0)
    8000505e:	01a70793          	addi	a5,a4,26
    80005062:	078e                	slli	a5,a5,0x3
    80005064:	953e                	add	a0,a0,a5
    80005066:	611c                	ld	a5,0(a0)
    80005068:	c395                	beqz	a5,8000508c <argfd+0x64>
    return -1;
  if(pfd)
    8000506a:	00090463          	beqz	s2,80005072 <argfd+0x4a>
    *pfd = fd;
    8000506e:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005072:	4501                	li	a0,0
  if(pf)
    80005074:	c091                	beqz	s1,80005078 <argfd+0x50>
    *pf = f;
    80005076:	e09c                	sd	a5,0(s1)
}
    80005078:	70a2                	ld	ra,40(sp)
    8000507a:	7402                	ld	s0,32(sp)
    8000507c:	64e2                	ld	s1,24(sp)
    8000507e:	6942                	ld	s2,16(sp)
    80005080:	6145                	addi	sp,sp,48
    80005082:	8082                	ret
    return -1;
    80005084:	557d                	li	a0,-1
    80005086:	bfcd                	j	80005078 <argfd+0x50>
    return -1;
    80005088:	557d                	li	a0,-1
    8000508a:	b7fd                	j	80005078 <argfd+0x50>
    8000508c:	557d                	li	a0,-1
    8000508e:	b7ed                	j	80005078 <argfd+0x50>

0000000080005090 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005090:	1101                	addi	sp,sp,-32
    80005092:	ec06                	sd	ra,24(sp)
    80005094:	e822                	sd	s0,16(sp)
    80005096:	e426                	sd	s1,8(sp)
    80005098:	1000                	addi	s0,sp,32
    8000509a:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000509c:	ffffd097          	auipc	ra,0xffffd
    800050a0:	9f8080e7          	jalr	-1544(ra) # 80001a94 <myproc>
    800050a4:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800050a6:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    800050aa:	4501                	li	a0,0
    800050ac:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800050ae:	6398                	ld	a4,0(a5)
    800050b0:	cb19                	beqz	a4,800050c6 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800050b2:	2505                	addiw	a0,a0,1
    800050b4:	07a1                	addi	a5,a5,8
    800050b6:	fed51ce3          	bne	a0,a3,800050ae <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800050ba:	557d                	li	a0,-1
}
    800050bc:	60e2                	ld	ra,24(sp)
    800050be:	6442                	ld	s0,16(sp)
    800050c0:	64a2                	ld	s1,8(sp)
    800050c2:	6105                	addi	sp,sp,32
    800050c4:	8082                	ret
      p->ofile[fd] = f;
    800050c6:	01a50793          	addi	a5,a0,26
    800050ca:	078e                	slli	a5,a5,0x3
    800050cc:	963e                	add	a2,a2,a5
    800050ce:	e204                	sd	s1,0(a2)
      return fd;
    800050d0:	b7f5                	j	800050bc <fdalloc+0x2c>

00000000800050d2 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800050d2:	715d                	addi	sp,sp,-80
    800050d4:	e486                	sd	ra,72(sp)
    800050d6:	e0a2                	sd	s0,64(sp)
    800050d8:	fc26                	sd	s1,56(sp)
    800050da:	f84a                	sd	s2,48(sp)
    800050dc:	f44e                	sd	s3,40(sp)
    800050de:	f052                	sd	s4,32(sp)
    800050e0:	ec56                	sd	s5,24(sp)
    800050e2:	0880                	addi	s0,sp,80
    800050e4:	89ae                	mv	s3,a1
    800050e6:	8ab2                	mv	s5,a2
    800050e8:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800050ea:	fb040593          	addi	a1,s0,-80
    800050ee:	fffff097          	auipc	ra,0xfffff
    800050f2:	e7a080e7          	jalr	-390(ra) # 80003f68 <nameiparent>
    800050f6:	892a                	mv	s2,a0
    800050f8:	12050f63          	beqz	a0,80005236 <create+0x164>
    return 0;

  ilock(dp);
    800050fc:	ffffe097          	auipc	ra,0xffffe
    80005100:	698080e7          	jalr	1688(ra) # 80003794 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005104:	4601                	li	a2,0
    80005106:	fb040593          	addi	a1,s0,-80
    8000510a:	854a                	mv	a0,s2
    8000510c:	fffff097          	auipc	ra,0xfffff
    80005110:	b6c080e7          	jalr	-1172(ra) # 80003c78 <dirlookup>
    80005114:	84aa                	mv	s1,a0
    80005116:	c921                	beqz	a0,80005166 <create+0x94>
    iunlockput(dp);
    80005118:	854a                	mv	a0,s2
    8000511a:	fffff097          	auipc	ra,0xfffff
    8000511e:	8dc080e7          	jalr	-1828(ra) # 800039f6 <iunlockput>
    ilock(ip);
    80005122:	8526                	mv	a0,s1
    80005124:	ffffe097          	auipc	ra,0xffffe
    80005128:	670080e7          	jalr	1648(ra) # 80003794 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000512c:	2981                	sext.w	s3,s3
    8000512e:	4789                	li	a5,2
    80005130:	02f99463          	bne	s3,a5,80005158 <create+0x86>
    80005134:	0444d783          	lhu	a5,68(s1)
    80005138:	37f9                	addiw	a5,a5,-2
    8000513a:	17c2                	slli	a5,a5,0x30
    8000513c:	93c1                	srli	a5,a5,0x30
    8000513e:	4705                	li	a4,1
    80005140:	00f76c63          	bltu	a4,a5,80005158 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005144:	8526                	mv	a0,s1
    80005146:	60a6                	ld	ra,72(sp)
    80005148:	6406                	ld	s0,64(sp)
    8000514a:	74e2                	ld	s1,56(sp)
    8000514c:	7942                	ld	s2,48(sp)
    8000514e:	79a2                	ld	s3,40(sp)
    80005150:	7a02                	ld	s4,32(sp)
    80005152:	6ae2                	ld	s5,24(sp)
    80005154:	6161                	addi	sp,sp,80
    80005156:	8082                	ret
    iunlockput(ip);
    80005158:	8526                	mv	a0,s1
    8000515a:	fffff097          	auipc	ra,0xfffff
    8000515e:	89c080e7          	jalr	-1892(ra) # 800039f6 <iunlockput>
    return 0;
    80005162:	4481                	li	s1,0
    80005164:	b7c5                	j	80005144 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005166:	85ce                	mv	a1,s3
    80005168:	00092503          	lw	a0,0(s2)
    8000516c:	ffffe097          	auipc	ra,0xffffe
    80005170:	490080e7          	jalr	1168(ra) # 800035fc <ialloc>
    80005174:	84aa                	mv	s1,a0
    80005176:	c529                	beqz	a0,800051c0 <create+0xee>
  ilock(ip);
    80005178:	ffffe097          	auipc	ra,0xffffe
    8000517c:	61c080e7          	jalr	1564(ra) # 80003794 <ilock>
  ip->major = major;
    80005180:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005184:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005188:	4785                	li	a5,1
    8000518a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000518e:	8526                	mv	a0,s1
    80005190:	ffffe097          	auipc	ra,0xffffe
    80005194:	53a080e7          	jalr	1338(ra) # 800036ca <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005198:	2981                	sext.w	s3,s3
    8000519a:	4785                	li	a5,1
    8000519c:	02f98a63          	beq	s3,a5,800051d0 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800051a0:	40d0                	lw	a2,4(s1)
    800051a2:	fb040593          	addi	a1,s0,-80
    800051a6:	854a                	mv	a0,s2
    800051a8:	fffff097          	auipc	ra,0xfffff
    800051ac:	ce0080e7          	jalr	-800(ra) # 80003e88 <dirlink>
    800051b0:	06054b63          	bltz	a0,80005226 <create+0x154>
  iunlockput(dp);
    800051b4:	854a                	mv	a0,s2
    800051b6:	fffff097          	auipc	ra,0xfffff
    800051ba:	840080e7          	jalr	-1984(ra) # 800039f6 <iunlockput>
  return ip;
    800051be:	b759                	j	80005144 <create+0x72>
    panic("create: ialloc");
    800051c0:	00003517          	auipc	a0,0x3
    800051c4:	56050513          	addi	a0,a0,1376 # 80008720 <syscalls+0x2a8>
    800051c8:	ffffb097          	auipc	ra,0xffffb
    800051cc:	376080e7          	jalr	886(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    800051d0:	04a95783          	lhu	a5,74(s2)
    800051d4:	2785                	addiw	a5,a5,1
    800051d6:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800051da:	854a                	mv	a0,s2
    800051dc:	ffffe097          	auipc	ra,0xffffe
    800051e0:	4ee080e7          	jalr	1262(ra) # 800036ca <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800051e4:	40d0                	lw	a2,4(s1)
    800051e6:	00003597          	auipc	a1,0x3
    800051ea:	54a58593          	addi	a1,a1,1354 # 80008730 <syscalls+0x2b8>
    800051ee:	8526                	mv	a0,s1
    800051f0:	fffff097          	auipc	ra,0xfffff
    800051f4:	c98080e7          	jalr	-872(ra) # 80003e88 <dirlink>
    800051f8:	00054f63          	bltz	a0,80005216 <create+0x144>
    800051fc:	00492603          	lw	a2,4(s2)
    80005200:	00003597          	auipc	a1,0x3
    80005204:	53858593          	addi	a1,a1,1336 # 80008738 <syscalls+0x2c0>
    80005208:	8526                	mv	a0,s1
    8000520a:	fffff097          	auipc	ra,0xfffff
    8000520e:	c7e080e7          	jalr	-898(ra) # 80003e88 <dirlink>
    80005212:	f80557e3          	bgez	a0,800051a0 <create+0xce>
      panic("create dots");
    80005216:	00003517          	auipc	a0,0x3
    8000521a:	52a50513          	addi	a0,a0,1322 # 80008740 <syscalls+0x2c8>
    8000521e:	ffffb097          	auipc	ra,0xffffb
    80005222:	320080e7          	jalr	800(ra) # 8000053e <panic>
    panic("create: dirlink");
    80005226:	00003517          	auipc	a0,0x3
    8000522a:	52a50513          	addi	a0,a0,1322 # 80008750 <syscalls+0x2d8>
    8000522e:	ffffb097          	auipc	ra,0xffffb
    80005232:	310080e7          	jalr	784(ra) # 8000053e <panic>
    return 0;
    80005236:	84aa                	mv	s1,a0
    80005238:	b731                	j	80005144 <create+0x72>

000000008000523a <sys_dup>:
{
    8000523a:	7179                	addi	sp,sp,-48
    8000523c:	f406                	sd	ra,40(sp)
    8000523e:	f022                	sd	s0,32(sp)
    80005240:	ec26                	sd	s1,24(sp)
    80005242:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005244:	fd840613          	addi	a2,s0,-40
    80005248:	4581                	li	a1,0
    8000524a:	4501                	li	a0,0
    8000524c:	00000097          	auipc	ra,0x0
    80005250:	ddc080e7          	jalr	-548(ra) # 80005028 <argfd>
    return -1;
    80005254:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005256:	02054363          	bltz	a0,8000527c <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000525a:	fd843503          	ld	a0,-40(s0)
    8000525e:	00000097          	auipc	ra,0x0
    80005262:	e32080e7          	jalr	-462(ra) # 80005090 <fdalloc>
    80005266:	84aa                	mv	s1,a0
    return -1;
    80005268:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000526a:	00054963          	bltz	a0,8000527c <sys_dup+0x42>
  filedup(f);
    8000526e:	fd843503          	ld	a0,-40(s0)
    80005272:	fffff097          	auipc	ra,0xfffff
    80005276:	36e080e7          	jalr	878(ra) # 800045e0 <filedup>
  return fd;
    8000527a:	87a6                	mv	a5,s1
}
    8000527c:	853e                	mv	a0,a5
    8000527e:	70a2                	ld	ra,40(sp)
    80005280:	7402                	ld	s0,32(sp)
    80005282:	64e2                	ld	s1,24(sp)
    80005284:	6145                	addi	sp,sp,48
    80005286:	8082                	ret

0000000080005288 <sys_read>:
{
    80005288:	7179                	addi	sp,sp,-48
    8000528a:	f406                	sd	ra,40(sp)
    8000528c:	f022                	sd	s0,32(sp)
    8000528e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005290:	fe840613          	addi	a2,s0,-24
    80005294:	4581                	li	a1,0
    80005296:	4501                	li	a0,0
    80005298:	00000097          	auipc	ra,0x0
    8000529c:	d90080e7          	jalr	-624(ra) # 80005028 <argfd>
    return -1;
    800052a0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052a2:	04054163          	bltz	a0,800052e4 <sys_read+0x5c>
    800052a6:	fe440593          	addi	a1,s0,-28
    800052aa:	4509                	li	a0,2
    800052ac:	ffffe097          	auipc	ra,0xffffe
    800052b0:	894080e7          	jalr	-1900(ra) # 80002b40 <argint>
    return -1;
    800052b4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052b6:	02054763          	bltz	a0,800052e4 <sys_read+0x5c>
    800052ba:	fd840593          	addi	a1,s0,-40
    800052be:	4505                	li	a0,1
    800052c0:	ffffe097          	auipc	ra,0xffffe
    800052c4:	8a2080e7          	jalr	-1886(ra) # 80002b62 <argaddr>
    return -1;
    800052c8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052ca:	00054d63          	bltz	a0,800052e4 <sys_read+0x5c>
  return fileread(f, p, n);
    800052ce:	fe442603          	lw	a2,-28(s0)
    800052d2:	fd843583          	ld	a1,-40(s0)
    800052d6:	fe843503          	ld	a0,-24(s0)
    800052da:	fffff097          	auipc	ra,0xfffff
    800052de:	492080e7          	jalr	1170(ra) # 8000476c <fileread>
    800052e2:	87aa                	mv	a5,a0
}
    800052e4:	853e                	mv	a0,a5
    800052e6:	70a2                	ld	ra,40(sp)
    800052e8:	7402                	ld	s0,32(sp)
    800052ea:	6145                	addi	sp,sp,48
    800052ec:	8082                	ret

00000000800052ee <sys_write>:
{
    800052ee:	7179                	addi	sp,sp,-48
    800052f0:	f406                	sd	ra,40(sp)
    800052f2:	f022                	sd	s0,32(sp)
    800052f4:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052f6:	fe840613          	addi	a2,s0,-24
    800052fa:	4581                	li	a1,0
    800052fc:	4501                	li	a0,0
    800052fe:	00000097          	auipc	ra,0x0
    80005302:	d2a080e7          	jalr	-726(ra) # 80005028 <argfd>
    return -1;
    80005306:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005308:	04054163          	bltz	a0,8000534a <sys_write+0x5c>
    8000530c:	fe440593          	addi	a1,s0,-28
    80005310:	4509                	li	a0,2
    80005312:	ffffe097          	auipc	ra,0xffffe
    80005316:	82e080e7          	jalr	-2002(ra) # 80002b40 <argint>
    return -1;
    8000531a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000531c:	02054763          	bltz	a0,8000534a <sys_write+0x5c>
    80005320:	fd840593          	addi	a1,s0,-40
    80005324:	4505                	li	a0,1
    80005326:	ffffe097          	auipc	ra,0xffffe
    8000532a:	83c080e7          	jalr	-1988(ra) # 80002b62 <argaddr>
    return -1;
    8000532e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005330:	00054d63          	bltz	a0,8000534a <sys_write+0x5c>
  return filewrite(f, p, n);
    80005334:	fe442603          	lw	a2,-28(s0)
    80005338:	fd843583          	ld	a1,-40(s0)
    8000533c:	fe843503          	ld	a0,-24(s0)
    80005340:	fffff097          	auipc	ra,0xfffff
    80005344:	4ee080e7          	jalr	1262(ra) # 8000482e <filewrite>
    80005348:	87aa                	mv	a5,a0
}
    8000534a:	853e                	mv	a0,a5
    8000534c:	70a2                	ld	ra,40(sp)
    8000534e:	7402                	ld	s0,32(sp)
    80005350:	6145                	addi	sp,sp,48
    80005352:	8082                	ret

0000000080005354 <sys_close>:
{
    80005354:	1101                	addi	sp,sp,-32
    80005356:	ec06                	sd	ra,24(sp)
    80005358:	e822                	sd	s0,16(sp)
    8000535a:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000535c:	fe040613          	addi	a2,s0,-32
    80005360:	fec40593          	addi	a1,s0,-20
    80005364:	4501                	li	a0,0
    80005366:	00000097          	auipc	ra,0x0
    8000536a:	cc2080e7          	jalr	-830(ra) # 80005028 <argfd>
    return -1;
    8000536e:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005370:	02054463          	bltz	a0,80005398 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005374:	ffffc097          	auipc	ra,0xffffc
    80005378:	720080e7          	jalr	1824(ra) # 80001a94 <myproc>
    8000537c:	fec42783          	lw	a5,-20(s0)
    80005380:	07e9                	addi	a5,a5,26
    80005382:	078e                	slli	a5,a5,0x3
    80005384:	97aa                	add	a5,a5,a0
    80005386:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    8000538a:	fe043503          	ld	a0,-32(s0)
    8000538e:	fffff097          	auipc	ra,0xfffff
    80005392:	2a4080e7          	jalr	676(ra) # 80004632 <fileclose>
  return 0;
    80005396:	4781                	li	a5,0
}
    80005398:	853e                	mv	a0,a5
    8000539a:	60e2                	ld	ra,24(sp)
    8000539c:	6442                	ld	s0,16(sp)
    8000539e:	6105                	addi	sp,sp,32
    800053a0:	8082                	ret

00000000800053a2 <sys_fstat>:
{
    800053a2:	1101                	addi	sp,sp,-32
    800053a4:	ec06                	sd	ra,24(sp)
    800053a6:	e822                	sd	s0,16(sp)
    800053a8:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800053aa:	fe840613          	addi	a2,s0,-24
    800053ae:	4581                	li	a1,0
    800053b0:	4501                	li	a0,0
    800053b2:	00000097          	auipc	ra,0x0
    800053b6:	c76080e7          	jalr	-906(ra) # 80005028 <argfd>
    return -1;
    800053ba:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800053bc:	02054563          	bltz	a0,800053e6 <sys_fstat+0x44>
    800053c0:	fe040593          	addi	a1,s0,-32
    800053c4:	4505                	li	a0,1
    800053c6:	ffffd097          	auipc	ra,0xffffd
    800053ca:	79c080e7          	jalr	1948(ra) # 80002b62 <argaddr>
    return -1;
    800053ce:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800053d0:	00054b63          	bltz	a0,800053e6 <sys_fstat+0x44>
  return filestat(f, st);
    800053d4:	fe043583          	ld	a1,-32(s0)
    800053d8:	fe843503          	ld	a0,-24(s0)
    800053dc:	fffff097          	auipc	ra,0xfffff
    800053e0:	31e080e7          	jalr	798(ra) # 800046fa <filestat>
    800053e4:	87aa                	mv	a5,a0
}
    800053e6:	853e                	mv	a0,a5
    800053e8:	60e2                	ld	ra,24(sp)
    800053ea:	6442                	ld	s0,16(sp)
    800053ec:	6105                	addi	sp,sp,32
    800053ee:	8082                	ret

00000000800053f0 <sys_link>:
{
    800053f0:	7169                	addi	sp,sp,-304
    800053f2:	f606                	sd	ra,296(sp)
    800053f4:	f222                	sd	s0,288(sp)
    800053f6:	ee26                	sd	s1,280(sp)
    800053f8:	ea4a                	sd	s2,272(sp)
    800053fa:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053fc:	08000613          	li	a2,128
    80005400:	ed040593          	addi	a1,s0,-304
    80005404:	4501                	li	a0,0
    80005406:	ffffd097          	auipc	ra,0xffffd
    8000540a:	77e080e7          	jalr	1918(ra) # 80002b84 <argstr>
    return -1;
    8000540e:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005410:	10054e63          	bltz	a0,8000552c <sys_link+0x13c>
    80005414:	08000613          	li	a2,128
    80005418:	f5040593          	addi	a1,s0,-176
    8000541c:	4505                	li	a0,1
    8000541e:	ffffd097          	auipc	ra,0xffffd
    80005422:	766080e7          	jalr	1894(ra) # 80002b84 <argstr>
    return -1;
    80005426:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005428:	10054263          	bltz	a0,8000552c <sys_link+0x13c>
  begin_op();
    8000542c:	fffff097          	auipc	ra,0xfffff
    80005430:	d3a080e7          	jalr	-710(ra) # 80004166 <begin_op>
  if((ip = namei(old)) == 0){
    80005434:	ed040513          	addi	a0,s0,-304
    80005438:	fffff097          	auipc	ra,0xfffff
    8000543c:	b12080e7          	jalr	-1262(ra) # 80003f4a <namei>
    80005440:	84aa                	mv	s1,a0
    80005442:	c551                	beqz	a0,800054ce <sys_link+0xde>
  ilock(ip);
    80005444:	ffffe097          	auipc	ra,0xffffe
    80005448:	350080e7          	jalr	848(ra) # 80003794 <ilock>
  if(ip->type == T_DIR){
    8000544c:	04449703          	lh	a4,68(s1)
    80005450:	4785                	li	a5,1
    80005452:	08f70463          	beq	a4,a5,800054da <sys_link+0xea>
  ip->nlink++;
    80005456:	04a4d783          	lhu	a5,74(s1)
    8000545a:	2785                	addiw	a5,a5,1
    8000545c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005460:	8526                	mv	a0,s1
    80005462:	ffffe097          	auipc	ra,0xffffe
    80005466:	268080e7          	jalr	616(ra) # 800036ca <iupdate>
  iunlock(ip);
    8000546a:	8526                	mv	a0,s1
    8000546c:	ffffe097          	auipc	ra,0xffffe
    80005470:	3ea080e7          	jalr	1002(ra) # 80003856 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005474:	fd040593          	addi	a1,s0,-48
    80005478:	f5040513          	addi	a0,s0,-176
    8000547c:	fffff097          	auipc	ra,0xfffff
    80005480:	aec080e7          	jalr	-1300(ra) # 80003f68 <nameiparent>
    80005484:	892a                	mv	s2,a0
    80005486:	c935                	beqz	a0,800054fa <sys_link+0x10a>
  ilock(dp);
    80005488:	ffffe097          	auipc	ra,0xffffe
    8000548c:	30c080e7          	jalr	780(ra) # 80003794 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005490:	00092703          	lw	a4,0(s2)
    80005494:	409c                	lw	a5,0(s1)
    80005496:	04f71d63          	bne	a4,a5,800054f0 <sys_link+0x100>
    8000549a:	40d0                	lw	a2,4(s1)
    8000549c:	fd040593          	addi	a1,s0,-48
    800054a0:	854a                	mv	a0,s2
    800054a2:	fffff097          	auipc	ra,0xfffff
    800054a6:	9e6080e7          	jalr	-1562(ra) # 80003e88 <dirlink>
    800054aa:	04054363          	bltz	a0,800054f0 <sys_link+0x100>
  iunlockput(dp);
    800054ae:	854a                	mv	a0,s2
    800054b0:	ffffe097          	auipc	ra,0xffffe
    800054b4:	546080e7          	jalr	1350(ra) # 800039f6 <iunlockput>
  iput(ip);
    800054b8:	8526                	mv	a0,s1
    800054ba:	ffffe097          	auipc	ra,0xffffe
    800054be:	494080e7          	jalr	1172(ra) # 8000394e <iput>
  end_op();
    800054c2:	fffff097          	auipc	ra,0xfffff
    800054c6:	d24080e7          	jalr	-732(ra) # 800041e6 <end_op>
  return 0;
    800054ca:	4781                	li	a5,0
    800054cc:	a085                	j	8000552c <sys_link+0x13c>
    end_op();
    800054ce:	fffff097          	auipc	ra,0xfffff
    800054d2:	d18080e7          	jalr	-744(ra) # 800041e6 <end_op>
    return -1;
    800054d6:	57fd                	li	a5,-1
    800054d8:	a891                	j	8000552c <sys_link+0x13c>
    iunlockput(ip);
    800054da:	8526                	mv	a0,s1
    800054dc:	ffffe097          	auipc	ra,0xffffe
    800054e0:	51a080e7          	jalr	1306(ra) # 800039f6 <iunlockput>
    end_op();
    800054e4:	fffff097          	auipc	ra,0xfffff
    800054e8:	d02080e7          	jalr	-766(ra) # 800041e6 <end_op>
    return -1;
    800054ec:	57fd                	li	a5,-1
    800054ee:	a83d                	j	8000552c <sys_link+0x13c>
    iunlockput(dp);
    800054f0:	854a                	mv	a0,s2
    800054f2:	ffffe097          	auipc	ra,0xffffe
    800054f6:	504080e7          	jalr	1284(ra) # 800039f6 <iunlockput>
  ilock(ip);
    800054fa:	8526                	mv	a0,s1
    800054fc:	ffffe097          	auipc	ra,0xffffe
    80005500:	298080e7          	jalr	664(ra) # 80003794 <ilock>
  ip->nlink--;
    80005504:	04a4d783          	lhu	a5,74(s1)
    80005508:	37fd                	addiw	a5,a5,-1
    8000550a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000550e:	8526                	mv	a0,s1
    80005510:	ffffe097          	auipc	ra,0xffffe
    80005514:	1ba080e7          	jalr	442(ra) # 800036ca <iupdate>
  iunlockput(ip);
    80005518:	8526                	mv	a0,s1
    8000551a:	ffffe097          	auipc	ra,0xffffe
    8000551e:	4dc080e7          	jalr	1244(ra) # 800039f6 <iunlockput>
  end_op();
    80005522:	fffff097          	auipc	ra,0xfffff
    80005526:	cc4080e7          	jalr	-828(ra) # 800041e6 <end_op>
  return -1;
    8000552a:	57fd                	li	a5,-1
}
    8000552c:	853e                	mv	a0,a5
    8000552e:	70b2                	ld	ra,296(sp)
    80005530:	7412                	ld	s0,288(sp)
    80005532:	64f2                	ld	s1,280(sp)
    80005534:	6952                	ld	s2,272(sp)
    80005536:	6155                	addi	sp,sp,304
    80005538:	8082                	ret

000000008000553a <sys_unlink>:
{
    8000553a:	7151                	addi	sp,sp,-240
    8000553c:	f586                	sd	ra,232(sp)
    8000553e:	f1a2                	sd	s0,224(sp)
    80005540:	eda6                	sd	s1,216(sp)
    80005542:	e9ca                	sd	s2,208(sp)
    80005544:	e5ce                	sd	s3,200(sp)
    80005546:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005548:	08000613          	li	a2,128
    8000554c:	f3040593          	addi	a1,s0,-208
    80005550:	4501                	li	a0,0
    80005552:	ffffd097          	auipc	ra,0xffffd
    80005556:	632080e7          	jalr	1586(ra) # 80002b84 <argstr>
    8000555a:	18054163          	bltz	a0,800056dc <sys_unlink+0x1a2>
  begin_op();
    8000555e:	fffff097          	auipc	ra,0xfffff
    80005562:	c08080e7          	jalr	-1016(ra) # 80004166 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005566:	fb040593          	addi	a1,s0,-80
    8000556a:	f3040513          	addi	a0,s0,-208
    8000556e:	fffff097          	auipc	ra,0xfffff
    80005572:	9fa080e7          	jalr	-1542(ra) # 80003f68 <nameiparent>
    80005576:	84aa                	mv	s1,a0
    80005578:	c979                	beqz	a0,8000564e <sys_unlink+0x114>
  ilock(dp);
    8000557a:	ffffe097          	auipc	ra,0xffffe
    8000557e:	21a080e7          	jalr	538(ra) # 80003794 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005582:	00003597          	auipc	a1,0x3
    80005586:	1ae58593          	addi	a1,a1,430 # 80008730 <syscalls+0x2b8>
    8000558a:	fb040513          	addi	a0,s0,-80
    8000558e:	ffffe097          	auipc	ra,0xffffe
    80005592:	6d0080e7          	jalr	1744(ra) # 80003c5e <namecmp>
    80005596:	14050a63          	beqz	a0,800056ea <sys_unlink+0x1b0>
    8000559a:	00003597          	auipc	a1,0x3
    8000559e:	19e58593          	addi	a1,a1,414 # 80008738 <syscalls+0x2c0>
    800055a2:	fb040513          	addi	a0,s0,-80
    800055a6:	ffffe097          	auipc	ra,0xffffe
    800055aa:	6b8080e7          	jalr	1720(ra) # 80003c5e <namecmp>
    800055ae:	12050e63          	beqz	a0,800056ea <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800055b2:	f2c40613          	addi	a2,s0,-212
    800055b6:	fb040593          	addi	a1,s0,-80
    800055ba:	8526                	mv	a0,s1
    800055bc:	ffffe097          	auipc	ra,0xffffe
    800055c0:	6bc080e7          	jalr	1724(ra) # 80003c78 <dirlookup>
    800055c4:	892a                	mv	s2,a0
    800055c6:	12050263          	beqz	a0,800056ea <sys_unlink+0x1b0>
  ilock(ip);
    800055ca:	ffffe097          	auipc	ra,0xffffe
    800055ce:	1ca080e7          	jalr	458(ra) # 80003794 <ilock>
  if(ip->nlink < 1)
    800055d2:	04a91783          	lh	a5,74(s2)
    800055d6:	08f05263          	blez	a5,8000565a <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800055da:	04491703          	lh	a4,68(s2)
    800055de:	4785                	li	a5,1
    800055e0:	08f70563          	beq	a4,a5,8000566a <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800055e4:	4641                	li	a2,16
    800055e6:	4581                	li	a1,0
    800055e8:	fc040513          	addi	a0,s0,-64
    800055ec:	ffffb097          	auipc	ra,0xffffb
    800055f0:	6f4080e7          	jalr	1780(ra) # 80000ce0 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800055f4:	4741                	li	a4,16
    800055f6:	f2c42683          	lw	a3,-212(s0)
    800055fa:	fc040613          	addi	a2,s0,-64
    800055fe:	4581                	li	a1,0
    80005600:	8526                	mv	a0,s1
    80005602:	ffffe097          	auipc	ra,0xffffe
    80005606:	53e080e7          	jalr	1342(ra) # 80003b40 <writei>
    8000560a:	47c1                	li	a5,16
    8000560c:	0af51563          	bne	a0,a5,800056b6 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005610:	04491703          	lh	a4,68(s2)
    80005614:	4785                	li	a5,1
    80005616:	0af70863          	beq	a4,a5,800056c6 <sys_unlink+0x18c>
  iunlockput(dp);
    8000561a:	8526                	mv	a0,s1
    8000561c:	ffffe097          	auipc	ra,0xffffe
    80005620:	3da080e7          	jalr	986(ra) # 800039f6 <iunlockput>
  ip->nlink--;
    80005624:	04a95783          	lhu	a5,74(s2)
    80005628:	37fd                	addiw	a5,a5,-1
    8000562a:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000562e:	854a                	mv	a0,s2
    80005630:	ffffe097          	auipc	ra,0xffffe
    80005634:	09a080e7          	jalr	154(ra) # 800036ca <iupdate>
  iunlockput(ip);
    80005638:	854a                	mv	a0,s2
    8000563a:	ffffe097          	auipc	ra,0xffffe
    8000563e:	3bc080e7          	jalr	956(ra) # 800039f6 <iunlockput>
  end_op();
    80005642:	fffff097          	auipc	ra,0xfffff
    80005646:	ba4080e7          	jalr	-1116(ra) # 800041e6 <end_op>
  return 0;
    8000564a:	4501                	li	a0,0
    8000564c:	a84d                	j	800056fe <sys_unlink+0x1c4>
    end_op();
    8000564e:	fffff097          	auipc	ra,0xfffff
    80005652:	b98080e7          	jalr	-1128(ra) # 800041e6 <end_op>
    return -1;
    80005656:	557d                	li	a0,-1
    80005658:	a05d                	j	800056fe <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000565a:	00003517          	auipc	a0,0x3
    8000565e:	10650513          	addi	a0,a0,262 # 80008760 <syscalls+0x2e8>
    80005662:	ffffb097          	auipc	ra,0xffffb
    80005666:	edc080e7          	jalr	-292(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000566a:	04c92703          	lw	a4,76(s2)
    8000566e:	02000793          	li	a5,32
    80005672:	f6e7f9e3          	bgeu	a5,a4,800055e4 <sys_unlink+0xaa>
    80005676:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000567a:	4741                	li	a4,16
    8000567c:	86ce                	mv	a3,s3
    8000567e:	f1840613          	addi	a2,s0,-232
    80005682:	4581                	li	a1,0
    80005684:	854a                	mv	a0,s2
    80005686:	ffffe097          	auipc	ra,0xffffe
    8000568a:	3c2080e7          	jalr	962(ra) # 80003a48 <readi>
    8000568e:	47c1                	li	a5,16
    80005690:	00f51b63          	bne	a0,a5,800056a6 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005694:	f1845783          	lhu	a5,-232(s0)
    80005698:	e7a1                	bnez	a5,800056e0 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000569a:	29c1                	addiw	s3,s3,16
    8000569c:	04c92783          	lw	a5,76(s2)
    800056a0:	fcf9ede3          	bltu	s3,a5,8000567a <sys_unlink+0x140>
    800056a4:	b781                	j	800055e4 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800056a6:	00003517          	auipc	a0,0x3
    800056aa:	0d250513          	addi	a0,a0,210 # 80008778 <syscalls+0x300>
    800056ae:	ffffb097          	auipc	ra,0xffffb
    800056b2:	e90080e7          	jalr	-368(ra) # 8000053e <panic>
    panic("unlink: writei");
    800056b6:	00003517          	auipc	a0,0x3
    800056ba:	0da50513          	addi	a0,a0,218 # 80008790 <syscalls+0x318>
    800056be:	ffffb097          	auipc	ra,0xffffb
    800056c2:	e80080e7          	jalr	-384(ra) # 8000053e <panic>
    dp->nlink--;
    800056c6:	04a4d783          	lhu	a5,74(s1)
    800056ca:	37fd                	addiw	a5,a5,-1
    800056cc:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800056d0:	8526                	mv	a0,s1
    800056d2:	ffffe097          	auipc	ra,0xffffe
    800056d6:	ff8080e7          	jalr	-8(ra) # 800036ca <iupdate>
    800056da:	b781                	j	8000561a <sys_unlink+0xe0>
    return -1;
    800056dc:	557d                	li	a0,-1
    800056de:	a005                	j	800056fe <sys_unlink+0x1c4>
    iunlockput(ip);
    800056e0:	854a                	mv	a0,s2
    800056e2:	ffffe097          	auipc	ra,0xffffe
    800056e6:	314080e7          	jalr	788(ra) # 800039f6 <iunlockput>
  iunlockput(dp);
    800056ea:	8526                	mv	a0,s1
    800056ec:	ffffe097          	auipc	ra,0xffffe
    800056f0:	30a080e7          	jalr	778(ra) # 800039f6 <iunlockput>
  end_op();
    800056f4:	fffff097          	auipc	ra,0xfffff
    800056f8:	af2080e7          	jalr	-1294(ra) # 800041e6 <end_op>
  return -1;
    800056fc:	557d                	li	a0,-1
}
    800056fe:	70ae                	ld	ra,232(sp)
    80005700:	740e                	ld	s0,224(sp)
    80005702:	64ee                	ld	s1,216(sp)
    80005704:	694e                	ld	s2,208(sp)
    80005706:	69ae                	ld	s3,200(sp)
    80005708:	616d                	addi	sp,sp,240
    8000570a:	8082                	ret

000000008000570c <sys_open>:

uint64
sys_open(void)
{
    8000570c:	7131                	addi	sp,sp,-192
    8000570e:	fd06                	sd	ra,184(sp)
    80005710:	f922                	sd	s0,176(sp)
    80005712:	f526                	sd	s1,168(sp)
    80005714:	f14a                	sd	s2,160(sp)
    80005716:	ed4e                	sd	s3,152(sp)
    80005718:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000571a:	08000613          	li	a2,128
    8000571e:	f5040593          	addi	a1,s0,-176
    80005722:	4501                	li	a0,0
    80005724:	ffffd097          	auipc	ra,0xffffd
    80005728:	460080e7          	jalr	1120(ra) # 80002b84 <argstr>
    return -1;
    8000572c:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000572e:	0c054163          	bltz	a0,800057f0 <sys_open+0xe4>
    80005732:	f4c40593          	addi	a1,s0,-180
    80005736:	4505                	li	a0,1
    80005738:	ffffd097          	auipc	ra,0xffffd
    8000573c:	408080e7          	jalr	1032(ra) # 80002b40 <argint>
    80005740:	0a054863          	bltz	a0,800057f0 <sys_open+0xe4>

  begin_op();
    80005744:	fffff097          	auipc	ra,0xfffff
    80005748:	a22080e7          	jalr	-1502(ra) # 80004166 <begin_op>

  if(omode & O_CREATE){
    8000574c:	f4c42783          	lw	a5,-180(s0)
    80005750:	2007f793          	andi	a5,a5,512
    80005754:	cbdd                	beqz	a5,8000580a <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005756:	4681                	li	a3,0
    80005758:	4601                	li	a2,0
    8000575a:	4589                	li	a1,2
    8000575c:	f5040513          	addi	a0,s0,-176
    80005760:	00000097          	auipc	ra,0x0
    80005764:	972080e7          	jalr	-1678(ra) # 800050d2 <create>
    80005768:	892a                	mv	s2,a0
    if(ip == 0){
    8000576a:	c959                	beqz	a0,80005800 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000576c:	04491703          	lh	a4,68(s2)
    80005770:	478d                	li	a5,3
    80005772:	00f71763          	bne	a4,a5,80005780 <sys_open+0x74>
    80005776:	04695703          	lhu	a4,70(s2)
    8000577a:	47a5                	li	a5,9
    8000577c:	0ce7ec63          	bltu	a5,a4,80005854 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005780:	fffff097          	auipc	ra,0xfffff
    80005784:	df6080e7          	jalr	-522(ra) # 80004576 <filealloc>
    80005788:	89aa                	mv	s3,a0
    8000578a:	10050263          	beqz	a0,8000588e <sys_open+0x182>
    8000578e:	00000097          	auipc	ra,0x0
    80005792:	902080e7          	jalr	-1790(ra) # 80005090 <fdalloc>
    80005796:	84aa                	mv	s1,a0
    80005798:	0e054663          	bltz	a0,80005884 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    8000579c:	04491703          	lh	a4,68(s2)
    800057a0:	478d                	li	a5,3
    800057a2:	0cf70463          	beq	a4,a5,8000586a <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800057a6:	4789                	li	a5,2
    800057a8:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800057ac:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800057b0:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800057b4:	f4c42783          	lw	a5,-180(s0)
    800057b8:	0017c713          	xori	a4,a5,1
    800057bc:	8b05                	andi	a4,a4,1
    800057be:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800057c2:	0037f713          	andi	a4,a5,3
    800057c6:	00e03733          	snez	a4,a4
    800057ca:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800057ce:	4007f793          	andi	a5,a5,1024
    800057d2:	c791                	beqz	a5,800057de <sys_open+0xd2>
    800057d4:	04491703          	lh	a4,68(s2)
    800057d8:	4789                	li	a5,2
    800057da:	08f70f63          	beq	a4,a5,80005878 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800057de:	854a                	mv	a0,s2
    800057e0:	ffffe097          	auipc	ra,0xffffe
    800057e4:	076080e7          	jalr	118(ra) # 80003856 <iunlock>
  end_op();
    800057e8:	fffff097          	auipc	ra,0xfffff
    800057ec:	9fe080e7          	jalr	-1538(ra) # 800041e6 <end_op>

  return fd;
}
    800057f0:	8526                	mv	a0,s1
    800057f2:	70ea                	ld	ra,184(sp)
    800057f4:	744a                	ld	s0,176(sp)
    800057f6:	74aa                	ld	s1,168(sp)
    800057f8:	790a                	ld	s2,160(sp)
    800057fa:	69ea                	ld	s3,152(sp)
    800057fc:	6129                	addi	sp,sp,192
    800057fe:	8082                	ret
      end_op();
    80005800:	fffff097          	auipc	ra,0xfffff
    80005804:	9e6080e7          	jalr	-1562(ra) # 800041e6 <end_op>
      return -1;
    80005808:	b7e5                	j	800057f0 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    8000580a:	f5040513          	addi	a0,s0,-176
    8000580e:	ffffe097          	auipc	ra,0xffffe
    80005812:	73c080e7          	jalr	1852(ra) # 80003f4a <namei>
    80005816:	892a                	mv	s2,a0
    80005818:	c905                	beqz	a0,80005848 <sys_open+0x13c>
    ilock(ip);
    8000581a:	ffffe097          	auipc	ra,0xffffe
    8000581e:	f7a080e7          	jalr	-134(ra) # 80003794 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005822:	04491703          	lh	a4,68(s2)
    80005826:	4785                	li	a5,1
    80005828:	f4f712e3          	bne	a4,a5,8000576c <sys_open+0x60>
    8000582c:	f4c42783          	lw	a5,-180(s0)
    80005830:	dba1                	beqz	a5,80005780 <sys_open+0x74>
      iunlockput(ip);
    80005832:	854a                	mv	a0,s2
    80005834:	ffffe097          	auipc	ra,0xffffe
    80005838:	1c2080e7          	jalr	450(ra) # 800039f6 <iunlockput>
      end_op();
    8000583c:	fffff097          	auipc	ra,0xfffff
    80005840:	9aa080e7          	jalr	-1622(ra) # 800041e6 <end_op>
      return -1;
    80005844:	54fd                	li	s1,-1
    80005846:	b76d                	j	800057f0 <sys_open+0xe4>
      end_op();
    80005848:	fffff097          	auipc	ra,0xfffff
    8000584c:	99e080e7          	jalr	-1634(ra) # 800041e6 <end_op>
      return -1;
    80005850:	54fd                	li	s1,-1
    80005852:	bf79                	j	800057f0 <sys_open+0xe4>
    iunlockput(ip);
    80005854:	854a                	mv	a0,s2
    80005856:	ffffe097          	auipc	ra,0xffffe
    8000585a:	1a0080e7          	jalr	416(ra) # 800039f6 <iunlockput>
    end_op();
    8000585e:	fffff097          	auipc	ra,0xfffff
    80005862:	988080e7          	jalr	-1656(ra) # 800041e6 <end_op>
    return -1;
    80005866:	54fd                	li	s1,-1
    80005868:	b761                	j	800057f0 <sys_open+0xe4>
    f->type = FD_DEVICE;
    8000586a:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    8000586e:	04691783          	lh	a5,70(s2)
    80005872:	02f99223          	sh	a5,36(s3)
    80005876:	bf2d                	j	800057b0 <sys_open+0xa4>
    itrunc(ip);
    80005878:	854a                	mv	a0,s2
    8000587a:	ffffe097          	auipc	ra,0xffffe
    8000587e:	028080e7          	jalr	40(ra) # 800038a2 <itrunc>
    80005882:	bfb1                	j	800057de <sys_open+0xd2>
      fileclose(f);
    80005884:	854e                	mv	a0,s3
    80005886:	fffff097          	auipc	ra,0xfffff
    8000588a:	dac080e7          	jalr	-596(ra) # 80004632 <fileclose>
    iunlockput(ip);
    8000588e:	854a                	mv	a0,s2
    80005890:	ffffe097          	auipc	ra,0xffffe
    80005894:	166080e7          	jalr	358(ra) # 800039f6 <iunlockput>
    end_op();
    80005898:	fffff097          	auipc	ra,0xfffff
    8000589c:	94e080e7          	jalr	-1714(ra) # 800041e6 <end_op>
    return -1;
    800058a0:	54fd                	li	s1,-1
    800058a2:	b7b9                	j	800057f0 <sys_open+0xe4>

00000000800058a4 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800058a4:	7175                	addi	sp,sp,-144
    800058a6:	e506                	sd	ra,136(sp)
    800058a8:	e122                	sd	s0,128(sp)
    800058aa:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800058ac:	fffff097          	auipc	ra,0xfffff
    800058b0:	8ba080e7          	jalr	-1862(ra) # 80004166 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800058b4:	08000613          	li	a2,128
    800058b8:	f7040593          	addi	a1,s0,-144
    800058bc:	4501                	li	a0,0
    800058be:	ffffd097          	auipc	ra,0xffffd
    800058c2:	2c6080e7          	jalr	710(ra) # 80002b84 <argstr>
    800058c6:	02054963          	bltz	a0,800058f8 <sys_mkdir+0x54>
    800058ca:	4681                	li	a3,0
    800058cc:	4601                	li	a2,0
    800058ce:	4585                	li	a1,1
    800058d0:	f7040513          	addi	a0,s0,-144
    800058d4:	fffff097          	auipc	ra,0xfffff
    800058d8:	7fe080e7          	jalr	2046(ra) # 800050d2 <create>
    800058dc:	cd11                	beqz	a0,800058f8 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800058de:	ffffe097          	auipc	ra,0xffffe
    800058e2:	118080e7          	jalr	280(ra) # 800039f6 <iunlockput>
  end_op();
    800058e6:	fffff097          	auipc	ra,0xfffff
    800058ea:	900080e7          	jalr	-1792(ra) # 800041e6 <end_op>
  return 0;
    800058ee:	4501                	li	a0,0
}
    800058f0:	60aa                	ld	ra,136(sp)
    800058f2:	640a                	ld	s0,128(sp)
    800058f4:	6149                	addi	sp,sp,144
    800058f6:	8082                	ret
    end_op();
    800058f8:	fffff097          	auipc	ra,0xfffff
    800058fc:	8ee080e7          	jalr	-1810(ra) # 800041e6 <end_op>
    return -1;
    80005900:	557d                	li	a0,-1
    80005902:	b7fd                	j	800058f0 <sys_mkdir+0x4c>

0000000080005904 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005904:	7135                	addi	sp,sp,-160
    80005906:	ed06                	sd	ra,152(sp)
    80005908:	e922                	sd	s0,144(sp)
    8000590a:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    8000590c:	fffff097          	auipc	ra,0xfffff
    80005910:	85a080e7          	jalr	-1958(ra) # 80004166 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005914:	08000613          	li	a2,128
    80005918:	f7040593          	addi	a1,s0,-144
    8000591c:	4501                	li	a0,0
    8000591e:	ffffd097          	auipc	ra,0xffffd
    80005922:	266080e7          	jalr	614(ra) # 80002b84 <argstr>
    80005926:	04054a63          	bltz	a0,8000597a <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    8000592a:	f6c40593          	addi	a1,s0,-148
    8000592e:	4505                	li	a0,1
    80005930:	ffffd097          	auipc	ra,0xffffd
    80005934:	210080e7          	jalr	528(ra) # 80002b40 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005938:	04054163          	bltz	a0,8000597a <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    8000593c:	f6840593          	addi	a1,s0,-152
    80005940:	4509                	li	a0,2
    80005942:	ffffd097          	auipc	ra,0xffffd
    80005946:	1fe080e7          	jalr	510(ra) # 80002b40 <argint>
     argint(1, &major) < 0 ||
    8000594a:	02054863          	bltz	a0,8000597a <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    8000594e:	f6841683          	lh	a3,-152(s0)
    80005952:	f6c41603          	lh	a2,-148(s0)
    80005956:	458d                	li	a1,3
    80005958:	f7040513          	addi	a0,s0,-144
    8000595c:	fffff097          	auipc	ra,0xfffff
    80005960:	776080e7          	jalr	1910(ra) # 800050d2 <create>
     argint(2, &minor) < 0 ||
    80005964:	c919                	beqz	a0,8000597a <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005966:	ffffe097          	auipc	ra,0xffffe
    8000596a:	090080e7          	jalr	144(ra) # 800039f6 <iunlockput>
  end_op();
    8000596e:	fffff097          	auipc	ra,0xfffff
    80005972:	878080e7          	jalr	-1928(ra) # 800041e6 <end_op>
  return 0;
    80005976:	4501                	li	a0,0
    80005978:	a031                	j	80005984 <sys_mknod+0x80>
    end_op();
    8000597a:	fffff097          	auipc	ra,0xfffff
    8000597e:	86c080e7          	jalr	-1940(ra) # 800041e6 <end_op>
    return -1;
    80005982:	557d                	li	a0,-1
}
    80005984:	60ea                	ld	ra,152(sp)
    80005986:	644a                	ld	s0,144(sp)
    80005988:	610d                	addi	sp,sp,160
    8000598a:	8082                	ret

000000008000598c <sys_chdir>:

uint64
sys_chdir(void)
{
    8000598c:	7135                	addi	sp,sp,-160
    8000598e:	ed06                	sd	ra,152(sp)
    80005990:	e922                	sd	s0,144(sp)
    80005992:	e526                	sd	s1,136(sp)
    80005994:	e14a                	sd	s2,128(sp)
    80005996:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005998:	ffffc097          	auipc	ra,0xffffc
    8000599c:	0fc080e7          	jalr	252(ra) # 80001a94 <myproc>
    800059a0:	892a                	mv	s2,a0
  
  begin_op();
    800059a2:	ffffe097          	auipc	ra,0xffffe
    800059a6:	7c4080e7          	jalr	1988(ra) # 80004166 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800059aa:	08000613          	li	a2,128
    800059ae:	f6040593          	addi	a1,s0,-160
    800059b2:	4501                	li	a0,0
    800059b4:	ffffd097          	auipc	ra,0xffffd
    800059b8:	1d0080e7          	jalr	464(ra) # 80002b84 <argstr>
    800059bc:	04054b63          	bltz	a0,80005a12 <sys_chdir+0x86>
    800059c0:	f6040513          	addi	a0,s0,-160
    800059c4:	ffffe097          	auipc	ra,0xffffe
    800059c8:	586080e7          	jalr	1414(ra) # 80003f4a <namei>
    800059cc:	84aa                	mv	s1,a0
    800059ce:	c131                	beqz	a0,80005a12 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800059d0:	ffffe097          	auipc	ra,0xffffe
    800059d4:	dc4080e7          	jalr	-572(ra) # 80003794 <ilock>
  if(ip->type != T_DIR){
    800059d8:	04449703          	lh	a4,68(s1)
    800059dc:	4785                	li	a5,1
    800059de:	04f71063          	bne	a4,a5,80005a1e <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800059e2:	8526                	mv	a0,s1
    800059e4:	ffffe097          	auipc	ra,0xffffe
    800059e8:	e72080e7          	jalr	-398(ra) # 80003856 <iunlock>
  iput(p->cwd);
    800059ec:	15093503          	ld	a0,336(s2)
    800059f0:	ffffe097          	auipc	ra,0xffffe
    800059f4:	f5e080e7          	jalr	-162(ra) # 8000394e <iput>
  end_op();
    800059f8:	ffffe097          	auipc	ra,0xffffe
    800059fc:	7ee080e7          	jalr	2030(ra) # 800041e6 <end_op>
  p->cwd = ip;
    80005a00:	14993823          	sd	s1,336(s2)
  return 0;
    80005a04:	4501                	li	a0,0
}
    80005a06:	60ea                	ld	ra,152(sp)
    80005a08:	644a                	ld	s0,144(sp)
    80005a0a:	64aa                	ld	s1,136(sp)
    80005a0c:	690a                	ld	s2,128(sp)
    80005a0e:	610d                	addi	sp,sp,160
    80005a10:	8082                	ret
    end_op();
    80005a12:	ffffe097          	auipc	ra,0xffffe
    80005a16:	7d4080e7          	jalr	2004(ra) # 800041e6 <end_op>
    return -1;
    80005a1a:	557d                	li	a0,-1
    80005a1c:	b7ed                	j	80005a06 <sys_chdir+0x7a>
    iunlockput(ip);
    80005a1e:	8526                	mv	a0,s1
    80005a20:	ffffe097          	auipc	ra,0xffffe
    80005a24:	fd6080e7          	jalr	-42(ra) # 800039f6 <iunlockput>
    end_op();
    80005a28:	ffffe097          	auipc	ra,0xffffe
    80005a2c:	7be080e7          	jalr	1982(ra) # 800041e6 <end_op>
    return -1;
    80005a30:	557d                	li	a0,-1
    80005a32:	bfd1                	j	80005a06 <sys_chdir+0x7a>

0000000080005a34 <sys_exec>:

uint64
sys_exec(void)
{
    80005a34:	7145                	addi	sp,sp,-464
    80005a36:	e786                	sd	ra,456(sp)
    80005a38:	e3a2                	sd	s0,448(sp)
    80005a3a:	ff26                	sd	s1,440(sp)
    80005a3c:	fb4a                	sd	s2,432(sp)
    80005a3e:	f74e                	sd	s3,424(sp)
    80005a40:	f352                	sd	s4,416(sp)
    80005a42:	ef56                	sd	s5,408(sp)
    80005a44:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005a46:	08000613          	li	a2,128
    80005a4a:	f4040593          	addi	a1,s0,-192
    80005a4e:	4501                	li	a0,0
    80005a50:	ffffd097          	auipc	ra,0xffffd
    80005a54:	134080e7          	jalr	308(ra) # 80002b84 <argstr>
    return -1;
    80005a58:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005a5a:	0c054a63          	bltz	a0,80005b2e <sys_exec+0xfa>
    80005a5e:	e3840593          	addi	a1,s0,-456
    80005a62:	4505                	li	a0,1
    80005a64:	ffffd097          	auipc	ra,0xffffd
    80005a68:	0fe080e7          	jalr	254(ra) # 80002b62 <argaddr>
    80005a6c:	0c054163          	bltz	a0,80005b2e <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005a70:	10000613          	li	a2,256
    80005a74:	4581                	li	a1,0
    80005a76:	e4040513          	addi	a0,s0,-448
    80005a7a:	ffffb097          	auipc	ra,0xffffb
    80005a7e:	266080e7          	jalr	614(ra) # 80000ce0 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005a82:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005a86:	89a6                	mv	s3,s1
    80005a88:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005a8a:	02000a13          	li	s4,32
    80005a8e:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005a92:	00391513          	slli	a0,s2,0x3
    80005a96:	e3040593          	addi	a1,s0,-464
    80005a9a:	e3843783          	ld	a5,-456(s0)
    80005a9e:	953e                	add	a0,a0,a5
    80005aa0:	ffffd097          	auipc	ra,0xffffd
    80005aa4:	006080e7          	jalr	6(ra) # 80002aa6 <fetchaddr>
    80005aa8:	02054a63          	bltz	a0,80005adc <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005aac:	e3043783          	ld	a5,-464(s0)
    80005ab0:	c3b9                	beqz	a5,80005af6 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005ab2:	ffffb097          	auipc	ra,0xffffb
    80005ab6:	042080e7          	jalr	66(ra) # 80000af4 <kalloc>
    80005aba:	85aa                	mv	a1,a0
    80005abc:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005ac0:	cd11                	beqz	a0,80005adc <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005ac2:	6605                	lui	a2,0x1
    80005ac4:	e3043503          	ld	a0,-464(s0)
    80005ac8:	ffffd097          	auipc	ra,0xffffd
    80005acc:	030080e7          	jalr	48(ra) # 80002af8 <fetchstr>
    80005ad0:	00054663          	bltz	a0,80005adc <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005ad4:	0905                	addi	s2,s2,1
    80005ad6:	09a1                	addi	s3,s3,8
    80005ad8:	fb491be3          	bne	s2,s4,80005a8e <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005adc:	10048913          	addi	s2,s1,256
    80005ae0:	6088                	ld	a0,0(s1)
    80005ae2:	c529                	beqz	a0,80005b2c <sys_exec+0xf8>
    kfree(argv[i]);
    80005ae4:	ffffb097          	auipc	ra,0xffffb
    80005ae8:	f14080e7          	jalr	-236(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005aec:	04a1                	addi	s1,s1,8
    80005aee:	ff2499e3          	bne	s1,s2,80005ae0 <sys_exec+0xac>
  return -1;
    80005af2:	597d                	li	s2,-1
    80005af4:	a82d                	j	80005b2e <sys_exec+0xfa>
      argv[i] = 0;
    80005af6:	0a8e                	slli	s5,s5,0x3
    80005af8:	fc040793          	addi	a5,s0,-64
    80005afc:	9abe                	add	s5,s5,a5
    80005afe:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005b02:	e4040593          	addi	a1,s0,-448
    80005b06:	f4040513          	addi	a0,s0,-192
    80005b0a:	fffff097          	auipc	ra,0xfffff
    80005b0e:	188080e7          	jalr	392(ra) # 80004c92 <exec>
    80005b12:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b14:	10048993          	addi	s3,s1,256
    80005b18:	6088                	ld	a0,0(s1)
    80005b1a:	c911                	beqz	a0,80005b2e <sys_exec+0xfa>
    kfree(argv[i]);
    80005b1c:	ffffb097          	auipc	ra,0xffffb
    80005b20:	edc080e7          	jalr	-292(ra) # 800009f8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b24:	04a1                	addi	s1,s1,8
    80005b26:	ff3499e3          	bne	s1,s3,80005b18 <sys_exec+0xe4>
    80005b2a:	a011                	j	80005b2e <sys_exec+0xfa>
  return -1;
    80005b2c:	597d                	li	s2,-1
}
    80005b2e:	854a                	mv	a0,s2
    80005b30:	60be                	ld	ra,456(sp)
    80005b32:	641e                	ld	s0,448(sp)
    80005b34:	74fa                	ld	s1,440(sp)
    80005b36:	795a                	ld	s2,432(sp)
    80005b38:	79ba                	ld	s3,424(sp)
    80005b3a:	7a1a                	ld	s4,416(sp)
    80005b3c:	6afa                	ld	s5,408(sp)
    80005b3e:	6179                	addi	sp,sp,464
    80005b40:	8082                	ret

0000000080005b42 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005b42:	7139                	addi	sp,sp,-64
    80005b44:	fc06                	sd	ra,56(sp)
    80005b46:	f822                	sd	s0,48(sp)
    80005b48:	f426                	sd	s1,40(sp)
    80005b4a:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005b4c:	ffffc097          	auipc	ra,0xffffc
    80005b50:	f48080e7          	jalr	-184(ra) # 80001a94 <myproc>
    80005b54:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005b56:	fd840593          	addi	a1,s0,-40
    80005b5a:	4501                	li	a0,0
    80005b5c:	ffffd097          	auipc	ra,0xffffd
    80005b60:	006080e7          	jalr	6(ra) # 80002b62 <argaddr>
    return -1;
    80005b64:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005b66:	0e054063          	bltz	a0,80005c46 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005b6a:	fc840593          	addi	a1,s0,-56
    80005b6e:	fd040513          	addi	a0,s0,-48
    80005b72:	fffff097          	auipc	ra,0xfffff
    80005b76:	df0080e7          	jalr	-528(ra) # 80004962 <pipealloc>
    return -1;
    80005b7a:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005b7c:	0c054563          	bltz	a0,80005c46 <sys_pipe+0x104>
  fd0 = -1;
    80005b80:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005b84:	fd043503          	ld	a0,-48(s0)
    80005b88:	fffff097          	auipc	ra,0xfffff
    80005b8c:	508080e7          	jalr	1288(ra) # 80005090 <fdalloc>
    80005b90:	fca42223          	sw	a0,-60(s0)
    80005b94:	08054c63          	bltz	a0,80005c2c <sys_pipe+0xea>
    80005b98:	fc843503          	ld	a0,-56(s0)
    80005b9c:	fffff097          	auipc	ra,0xfffff
    80005ba0:	4f4080e7          	jalr	1268(ra) # 80005090 <fdalloc>
    80005ba4:	fca42023          	sw	a0,-64(s0)
    80005ba8:	06054863          	bltz	a0,80005c18 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005bac:	4691                	li	a3,4
    80005bae:	fc440613          	addi	a2,s0,-60
    80005bb2:	fd843583          	ld	a1,-40(s0)
    80005bb6:	68a8                	ld	a0,80(s1)
    80005bb8:	ffffc097          	auipc	ra,0xffffc
    80005bbc:	aba080e7          	jalr	-1350(ra) # 80001672 <copyout>
    80005bc0:	02054063          	bltz	a0,80005be0 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005bc4:	4691                	li	a3,4
    80005bc6:	fc040613          	addi	a2,s0,-64
    80005bca:	fd843583          	ld	a1,-40(s0)
    80005bce:	0591                	addi	a1,a1,4
    80005bd0:	68a8                	ld	a0,80(s1)
    80005bd2:	ffffc097          	auipc	ra,0xffffc
    80005bd6:	aa0080e7          	jalr	-1376(ra) # 80001672 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005bda:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005bdc:	06055563          	bgez	a0,80005c46 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005be0:	fc442783          	lw	a5,-60(s0)
    80005be4:	07e9                	addi	a5,a5,26
    80005be6:	078e                	slli	a5,a5,0x3
    80005be8:	97a6                	add	a5,a5,s1
    80005bea:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005bee:	fc042503          	lw	a0,-64(s0)
    80005bf2:	0569                	addi	a0,a0,26
    80005bf4:	050e                	slli	a0,a0,0x3
    80005bf6:	9526                	add	a0,a0,s1
    80005bf8:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005bfc:	fd043503          	ld	a0,-48(s0)
    80005c00:	fffff097          	auipc	ra,0xfffff
    80005c04:	a32080e7          	jalr	-1486(ra) # 80004632 <fileclose>
    fileclose(wf);
    80005c08:	fc843503          	ld	a0,-56(s0)
    80005c0c:	fffff097          	auipc	ra,0xfffff
    80005c10:	a26080e7          	jalr	-1498(ra) # 80004632 <fileclose>
    return -1;
    80005c14:	57fd                	li	a5,-1
    80005c16:	a805                	j	80005c46 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005c18:	fc442783          	lw	a5,-60(s0)
    80005c1c:	0007c863          	bltz	a5,80005c2c <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005c20:	01a78513          	addi	a0,a5,26
    80005c24:	050e                	slli	a0,a0,0x3
    80005c26:	9526                	add	a0,a0,s1
    80005c28:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005c2c:	fd043503          	ld	a0,-48(s0)
    80005c30:	fffff097          	auipc	ra,0xfffff
    80005c34:	a02080e7          	jalr	-1534(ra) # 80004632 <fileclose>
    fileclose(wf);
    80005c38:	fc843503          	ld	a0,-56(s0)
    80005c3c:	fffff097          	auipc	ra,0xfffff
    80005c40:	9f6080e7          	jalr	-1546(ra) # 80004632 <fileclose>
    return -1;
    80005c44:	57fd                	li	a5,-1
}
    80005c46:	853e                	mv	a0,a5
    80005c48:	70e2                	ld	ra,56(sp)
    80005c4a:	7442                	ld	s0,48(sp)
    80005c4c:	74a2                	ld	s1,40(sp)
    80005c4e:	6121                	addi	sp,sp,64
    80005c50:	8082                	ret
	...

0000000080005c60 <kernelvec>:
    80005c60:	7111                	addi	sp,sp,-256
    80005c62:	e006                	sd	ra,0(sp)
    80005c64:	e40a                	sd	sp,8(sp)
    80005c66:	e80e                	sd	gp,16(sp)
    80005c68:	ec12                	sd	tp,24(sp)
    80005c6a:	f016                	sd	t0,32(sp)
    80005c6c:	f41a                	sd	t1,40(sp)
    80005c6e:	f81e                	sd	t2,48(sp)
    80005c70:	fc22                	sd	s0,56(sp)
    80005c72:	e0a6                	sd	s1,64(sp)
    80005c74:	e4aa                	sd	a0,72(sp)
    80005c76:	e8ae                	sd	a1,80(sp)
    80005c78:	ecb2                	sd	a2,88(sp)
    80005c7a:	f0b6                	sd	a3,96(sp)
    80005c7c:	f4ba                	sd	a4,104(sp)
    80005c7e:	f8be                	sd	a5,112(sp)
    80005c80:	fcc2                	sd	a6,120(sp)
    80005c82:	e146                	sd	a7,128(sp)
    80005c84:	e54a                	sd	s2,136(sp)
    80005c86:	e94e                	sd	s3,144(sp)
    80005c88:	ed52                	sd	s4,152(sp)
    80005c8a:	f156                	sd	s5,160(sp)
    80005c8c:	f55a                	sd	s6,168(sp)
    80005c8e:	f95e                	sd	s7,176(sp)
    80005c90:	fd62                	sd	s8,184(sp)
    80005c92:	e1e6                	sd	s9,192(sp)
    80005c94:	e5ea                	sd	s10,200(sp)
    80005c96:	e9ee                	sd	s11,208(sp)
    80005c98:	edf2                	sd	t3,216(sp)
    80005c9a:	f1f6                	sd	t4,224(sp)
    80005c9c:	f5fa                	sd	t5,232(sp)
    80005c9e:	f9fe                	sd	t6,240(sp)
    80005ca0:	cd3fc0ef          	jal	ra,80002972 <kerneltrap>
    80005ca4:	6082                	ld	ra,0(sp)
    80005ca6:	6122                	ld	sp,8(sp)
    80005ca8:	61c2                	ld	gp,16(sp)
    80005caa:	7282                	ld	t0,32(sp)
    80005cac:	7322                	ld	t1,40(sp)
    80005cae:	73c2                	ld	t2,48(sp)
    80005cb0:	7462                	ld	s0,56(sp)
    80005cb2:	6486                	ld	s1,64(sp)
    80005cb4:	6526                	ld	a0,72(sp)
    80005cb6:	65c6                	ld	a1,80(sp)
    80005cb8:	6666                	ld	a2,88(sp)
    80005cba:	7686                	ld	a3,96(sp)
    80005cbc:	7726                	ld	a4,104(sp)
    80005cbe:	77c6                	ld	a5,112(sp)
    80005cc0:	7866                	ld	a6,120(sp)
    80005cc2:	688a                	ld	a7,128(sp)
    80005cc4:	692a                	ld	s2,136(sp)
    80005cc6:	69ca                	ld	s3,144(sp)
    80005cc8:	6a6a                	ld	s4,152(sp)
    80005cca:	7a8a                	ld	s5,160(sp)
    80005ccc:	7b2a                	ld	s6,168(sp)
    80005cce:	7bca                	ld	s7,176(sp)
    80005cd0:	7c6a                	ld	s8,184(sp)
    80005cd2:	6c8e                	ld	s9,192(sp)
    80005cd4:	6d2e                	ld	s10,200(sp)
    80005cd6:	6dce                	ld	s11,208(sp)
    80005cd8:	6e6e                	ld	t3,216(sp)
    80005cda:	7e8e                	ld	t4,224(sp)
    80005cdc:	7f2e                	ld	t5,232(sp)
    80005cde:	7fce                	ld	t6,240(sp)
    80005ce0:	6111                	addi	sp,sp,256
    80005ce2:	10200073          	sret
    80005ce6:	00000013          	nop
    80005cea:	00000013          	nop
    80005cee:	0001                	nop

0000000080005cf0 <timervec>:
    80005cf0:	34051573          	csrrw	a0,mscratch,a0
    80005cf4:	e10c                	sd	a1,0(a0)
    80005cf6:	e510                	sd	a2,8(a0)
    80005cf8:	e914                	sd	a3,16(a0)
    80005cfa:	6d0c                	ld	a1,24(a0)
    80005cfc:	7110                	ld	a2,32(a0)
    80005cfe:	6194                	ld	a3,0(a1)
    80005d00:	96b2                	add	a3,a3,a2
    80005d02:	e194                	sd	a3,0(a1)
    80005d04:	4589                	li	a1,2
    80005d06:	14459073          	csrw	sip,a1
    80005d0a:	6914                	ld	a3,16(a0)
    80005d0c:	6510                	ld	a2,8(a0)
    80005d0e:	610c                	ld	a1,0(a0)
    80005d10:	34051573          	csrrw	a0,mscratch,a0
    80005d14:	30200073          	mret
	...

0000000080005d1a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005d1a:	1141                	addi	sp,sp,-16
    80005d1c:	e422                	sd	s0,8(sp)
    80005d1e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005d20:	0c0007b7          	lui	a5,0xc000
    80005d24:	4705                	li	a4,1
    80005d26:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005d28:	c3d8                	sw	a4,4(a5)
}
    80005d2a:	6422                	ld	s0,8(sp)
    80005d2c:	0141                	addi	sp,sp,16
    80005d2e:	8082                	ret

0000000080005d30 <plicinithart>:

void
plicinithart(void)
{
    80005d30:	1141                	addi	sp,sp,-16
    80005d32:	e406                	sd	ra,8(sp)
    80005d34:	e022                	sd	s0,0(sp)
    80005d36:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d38:	ffffc097          	auipc	ra,0xffffc
    80005d3c:	d30080e7          	jalr	-720(ra) # 80001a68 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005d40:	0085171b          	slliw	a4,a0,0x8
    80005d44:	0c0027b7          	lui	a5,0xc002
    80005d48:	97ba                	add	a5,a5,a4
    80005d4a:	40200713          	li	a4,1026
    80005d4e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005d52:	00d5151b          	slliw	a0,a0,0xd
    80005d56:	0c2017b7          	lui	a5,0xc201
    80005d5a:	953e                	add	a0,a0,a5
    80005d5c:	00052023          	sw	zero,0(a0)
}
    80005d60:	60a2                	ld	ra,8(sp)
    80005d62:	6402                	ld	s0,0(sp)
    80005d64:	0141                	addi	sp,sp,16
    80005d66:	8082                	ret

0000000080005d68 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005d68:	1141                	addi	sp,sp,-16
    80005d6a:	e406                	sd	ra,8(sp)
    80005d6c:	e022                	sd	s0,0(sp)
    80005d6e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d70:	ffffc097          	auipc	ra,0xffffc
    80005d74:	cf8080e7          	jalr	-776(ra) # 80001a68 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005d78:	00d5179b          	slliw	a5,a0,0xd
    80005d7c:	0c201537          	lui	a0,0xc201
    80005d80:	953e                	add	a0,a0,a5
  return irq;
}
    80005d82:	4148                	lw	a0,4(a0)
    80005d84:	60a2                	ld	ra,8(sp)
    80005d86:	6402                	ld	s0,0(sp)
    80005d88:	0141                	addi	sp,sp,16
    80005d8a:	8082                	ret

0000000080005d8c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005d8c:	1101                	addi	sp,sp,-32
    80005d8e:	ec06                	sd	ra,24(sp)
    80005d90:	e822                	sd	s0,16(sp)
    80005d92:	e426                	sd	s1,8(sp)
    80005d94:	1000                	addi	s0,sp,32
    80005d96:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005d98:	ffffc097          	auipc	ra,0xffffc
    80005d9c:	cd0080e7          	jalr	-816(ra) # 80001a68 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005da0:	00d5151b          	slliw	a0,a0,0xd
    80005da4:	0c2017b7          	lui	a5,0xc201
    80005da8:	97aa                	add	a5,a5,a0
    80005daa:	c3c4                	sw	s1,4(a5)
}
    80005dac:	60e2                	ld	ra,24(sp)
    80005dae:	6442                	ld	s0,16(sp)
    80005db0:	64a2                	ld	s1,8(sp)
    80005db2:	6105                	addi	sp,sp,32
    80005db4:	8082                	ret

0000000080005db6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005db6:	1141                	addi	sp,sp,-16
    80005db8:	e406                	sd	ra,8(sp)
    80005dba:	e022                	sd	s0,0(sp)
    80005dbc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005dbe:	479d                	li	a5,7
    80005dc0:	06a7c963          	blt	a5,a0,80005e32 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80005dc4:	0001d797          	auipc	a5,0x1d
    80005dc8:	23c78793          	addi	a5,a5,572 # 80023000 <disk>
    80005dcc:	00a78733          	add	a4,a5,a0
    80005dd0:	6789                	lui	a5,0x2
    80005dd2:	97ba                	add	a5,a5,a4
    80005dd4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005dd8:	e7ad                	bnez	a5,80005e42 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005dda:	00451793          	slli	a5,a0,0x4
    80005dde:	0001f717          	auipc	a4,0x1f
    80005de2:	22270713          	addi	a4,a4,546 # 80025000 <disk+0x2000>
    80005de6:	6314                	ld	a3,0(a4)
    80005de8:	96be                	add	a3,a3,a5
    80005dea:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80005dee:	6314                	ld	a3,0(a4)
    80005df0:	96be                	add	a3,a3,a5
    80005df2:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80005df6:	6314                	ld	a3,0(a4)
    80005df8:	96be                	add	a3,a3,a5
    80005dfa:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    80005dfe:	6318                	ld	a4,0(a4)
    80005e00:	97ba                	add	a5,a5,a4
    80005e02:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80005e06:	0001d797          	auipc	a5,0x1d
    80005e0a:	1fa78793          	addi	a5,a5,506 # 80023000 <disk>
    80005e0e:	97aa                	add	a5,a5,a0
    80005e10:	6509                	lui	a0,0x2
    80005e12:	953e                	add	a0,a0,a5
    80005e14:	4785                	li	a5,1
    80005e16:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005e1a:	0001f517          	auipc	a0,0x1f
    80005e1e:	1fe50513          	addi	a0,a0,510 # 80025018 <disk+0x2018>
    80005e22:	ffffc097          	auipc	ra,0xffffc
    80005e26:	4ba080e7          	jalr	1210(ra) # 800022dc <wakeup>
}
    80005e2a:	60a2                	ld	ra,8(sp)
    80005e2c:	6402                	ld	s0,0(sp)
    80005e2e:	0141                	addi	sp,sp,16
    80005e30:	8082                	ret
    panic("free_desc 1");
    80005e32:	00003517          	auipc	a0,0x3
    80005e36:	96e50513          	addi	a0,a0,-1682 # 800087a0 <syscalls+0x328>
    80005e3a:	ffffa097          	auipc	ra,0xffffa
    80005e3e:	704080e7          	jalr	1796(ra) # 8000053e <panic>
    panic("free_desc 2");
    80005e42:	00003517          	auipc	a0,0x3
    80005e46:	96e50513          	addi	a0,a0,-1682 # 800087b0 <syscalls+0x338>
    80005e4a:	ffffa097          	auipc	ra,0xffffa
    80005e4e:	6f4080e7          	jalr	1780(ra) # 8000053e <panic>

0000000080005e52 <virtio_disk_init>:
{
    80005e52:	1101                	addi	sp,sp,-32
    80005e54:	ec06                	sd	ra,24(sp)
    80005e56:	e822                	sd	s0,16(sp)
    80005e58:	e426                	sd	s1,8(sp)
    80005e5a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005e5c:	00003597          	auipc	a1,0x3
    80005e60:	96458593          	addi	a1,a1,-1692 # 800087c0 <syscalls+0x348>
    80005e64:	0001f517          	auipc	a0,0x1f
    80005e68:	2c450513          	addi	a0,a0,708 # 80025128 <disk+0x2128>
    80005e6c:	ffffb097          	auipc	ra,0xffffb
    80005e70:	ce8080e7          	jalr	-792(ra) # 80000b54 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e74:	100017b7          	lui	a5,0x10001
    80005e78:	4398                	lw	a4,0(a5)
    80005e7a:	2701                	sext.w	a4,a4
    80005e7c:	747277b7          	lui	a5,0x74727
    80005e80:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005e84:	0ef71163          	bne	a4,a5,80005f66 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005e88:	100017b7          	lui	a5,0x10001
    80005e8c:	43dc                	lw	a5,4(a5)
    80005e8e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e90:	4705                	li	a4,1
    80005e92:	0ce79a63          	bne	a5,a4,80005f66 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e96:	100017b7          	lui	a5,0x10001
    80005e9a:	479c                	lw	a5,8(a5)
    80005e9c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005e9e:	4709                	li	a4,2
    80005ea0:	0ce79363          	bne	a5,a4,80005f66 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005ea4:	100017b7          	lui	a5,0x10001
    80005ea8:	47d8                	lw	a4,12(a5)
    80005eaa:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005eac:	554d47b7          	lui	a5,0x554d4
    80005eb0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005eb4:	0af71963          	bne	a4,a5,80005f66 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005eb8:	100017b7          	lui	a5,0x10001
    80005ebc:	4705                	li	a4,1
    80005ebe:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ec0:	470d                	li	a4,3
    80005ec2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005ec4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005ec6:	c7ffe737          	lui	a4,0xc7ffe
    80005eca:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005ece:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005ed0:	2701                	sext.w	a4,a4
    80005ed2:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ed4:	472d                	li	a4,11
    80005ed6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ed8:	473d                	li	a4,15
    80005eda:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005edc:	6705                	lui	a4,0x1
    80005ede:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005ee0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005ee4:	5bdc                	lw	a5,52(a5)
    80005ee6:	2781                	sext.w	a5,a5
  if(max == 0)
    80005ee8:	c7d9                	beqz	a5,80005f76 <virtio_disk_init+0x124>
  if(max < NUM)
    80005eea:	471d                	li	a4,7
    80005eec:	08f77d63          	bgeu	a4,a5,80005f86 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005ef0:	100014b7          	lui	s1,0x10001
    80005ef4:	47a1                	li	a5,8
    80005ef6:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005ef8:	6609                	lui	a2,0x2
    80005efa:	4581                	li	a1,0
    80005efc:	0001d517          	auipc	a0,0x1d
    80005f00:	10450513          	addi	a0,a0,260 # 80023000 <disk>
    80005f04:	ffffb097          	auipc	ra,0xffffb
    80005f08:	ddc080e7          	jalr	-548(ra) # 80000ce0 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005f0c:	0001d717          	auipc	a4,0x1d
    80005f10:	0f470713          	addi	a4,a4,244 # 80023000 <disk>
    80005f14:	00c75793          	srli	a5,a4,0xc
    80005f18:	2781                	sext.w	a5,a5
    80005f1a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    80005f1c:	0001f797          	auipc	a5,0x1f
    80005f20:	0e478793          	addi	a5,a5,228 # 80025000 <disk+0x2000>
    80005f24:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80005f26:	0001d717          	auipc	a4,0x1d
    80005f2a:	15a70713          	addi	a4,a4,346 # 80023080 <disk+0x80>
    80005f2e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80005f30:	0001e717          	auipc	a4,0x1e
    80005f34:	0d070713          	addi	a4,a4,208 # 80024000 <disk+0x1000>
    80005f38:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005f3a:	4705                	li	a4,1
    80005f3c:	00e78c23          	sb	a4,24(a5)
    80005f40:	00e78ca3          	sb	a4,25(a5)
    80005f44:	00e78d23          	sb	a4,26(a5)
    80005f48:	00e78da3          	sb	a4,27(a5)
    80005f4c:	00e78e23          	sb	a4,28(a5)
    80005f50:	00e78ea3          	sb	a4,29(a5)
    80005f54:	00e78f23          	sb	a4,30(a5)
    80005f58:	00e78fa3          	sb	a4,31(a5)
}
    80005f5c:	60e2                	ld	ra,24(sp)
    80005f5e:	6442                	ld	s0,16(sp)
    80005f60:	64a2                	ld	s1,8(sp)
    80005f62:	6105                	addi	sp,sp,32
    80005f64:	8082                	ret
    panic("could not find virtio disk");
    80005f66:	00003517          	auipc	a0,0x3
    80005f6a:	86a50513          	addi	a0,a0,-1942 # 800087d0 <syscalls+0x358>
    80005f6e:	ffffa097          	auipc	ra,0xffffa
    80005f72:	5d0080e7          	jalr	1488(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80005f76:	00003517          	auipc	a0,0x3
    80005f7a:	87a50513          	addi	a0,a0,-1926 # 800087f0 <syscalls+0x378>
    80005f7e:	ffffa097          	auipc	ra,0xffffa
    80005f82:	5c0080e7          	jalr	1472(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80005f86:	00003517          	auipc	a0,0x3
    80005f8a:	88a50513          	addi	a0,a0,-1910 # 80008810 <syscalls+0x398>
    80005f8e:	ffffa097          	auipc	ra,0xffffa
    80005f92:	5b0080e7          	jalr	1456(ra) # 8000053e <panic>

0000000080005f96 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005f96:	7159                	addi	sp,sp,-112
    80005f98:	f486                	sd	ra,104(sp)
    80005f9a:	f0a2                	sd	s0,96(sp)
    80005f9c:	eca6                	sd	s1,88(sp)
    80005f9e:	e8ca                	sd	s2,80(sp)
    80005fa0:	e4ce                	sd	s3,72(sp)
    80005fa2:	e0d2                	sd	s4,64(sp)
    80005fa4:	fc56                	sd	s5,56(sp)
    80005fa6:	f85a                	sd	s6,48(sp)
    80005fa8:	f45e                	sd	s7,40(sp)
    80005faa:	f062                	sd	s8,32(sp)
    80005fac:	ec66                	sd	s9,24(sp)
    80005fae:	e86a                	sd	s10,16(sp)
    80005fb0:	1880                	addi	s0,sp,112
    80005fb2:	892a                	mv	s2,a0
    80005fb4:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005fb6:	00c52c83          	lw	s9,12(a0)
    80005fba:	001c9c9b          	slliw	s9,s9,0x1
    80005fbe:	1c82                	slli	s9,s9,0x20
    80005fc0:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005fc4:	0001f517          	auipc	a0,0x1f
    80005fc8:	16450513          	addi	a0,a0,356 # 80025128 <disk+0x2128>
    80005fcc:	ffffb097          	auipc	ra,0xffffb
    80005fd0:	c18080e7          	jalr	-1000(ra) # 80000be4 <acquire>
  for(int i = 0; i < 3; i++){
    80005fd4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005fd6:	4c21                	li	s8,8
      disk.free[i] = 0;
    80005fd8:	0001db97          	auipc	s7,0x1d
    80005fdc:	028b8b93          	addi	s7,s7,40 # 80023000 <disk>
    80005fe0:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80005fe2:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80005fe4:	8a4e                	mv	s4,s3
    80005fe6:	a051                	j	8000606a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80005fe8:	00fb86b3          	add	a3,s7,a5
    80005fec:	96da                	add	a3,a3,s6
    80005fee:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80005ff2:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80005ff4:	0207c563          	bltz	a5,8000601e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80005ff8:	2485                	addiw	s1,s1,1
    80005ffa:	0711                	addi	a4,a4,4
    80005ffc:	25548063          	beq	s1,s5,8000623c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006000:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006002:	0001f697          	auipc	a3,0x1f
    80006006:	01668693          	addi	a3,a3,22 # 80025018 <disk+0x2018>
    8000600a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000600c:	0006c583          	lbu	a1,0(a3)
    80006010:	fde1                	bnez	a1,80005fe8 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006012:	2785                	addiw	a5,a5,1
    80006014:	0685                	addi	a3,a3,1
    80006016:	ff879be3          	bne	a5,s8,8000600c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000601a:	57fd                	li	a5,-1
    8000601c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000601e:	02905a63          	blez	s1,80006052 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006022:	f9042503          	lw	a0,-112(s0)
    80006026:	00000097          	auipc	ra,0x0
    8000602a:	d90080e7          	jalr	-624(ra) # 80005db6 <free_desc>
      for(int j = 0; j < i; j++)
    8000602e:	4785                	li	a5,1
    80006030:	0297d163          	bge	a5,s1,80006052 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006034:	f9442503          	lw	a0,-108(s0)
    80006038:	00000097          	auipc	ra,0x0
    8000603c:	d7e080e7          	jalr	-642(ra) # 80005db6 <free_desc>
      for(int j = 0; j < i; j++)
    80006040:	4789                	li	a5,2
    80006042:	0097d863          	bge	a5,s1,80006052 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006046:	f9842503          	lw	a0,-104(s0)
    8000604a:	00000097          	auipc	ra,0x0
    8000604e:	d6c080e7          	jalr	-660(ra) # 80005db6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006052:	0001f597          	auipc	a1,0x1f
    80006056:	0d658593          	addi	a1,a1,214 # 80025128 <disk+0x2128>
    8000605a:	0001f517          	auipc	a0,0x1f
    8000605e:	fbe50513          	addi	a0,a0,-66 # 80025018 <disk+0x2018>
    80006062:	ffffc097          	auipc	ra,0xffffc
    80006066:	0ee080e7          	jalr	238(ra) # 80002150 <sleep>
  for(int i = 0; i < 3; i++){
    8000606a:	f9040713          	addi	a4,s0,-112
    8000606e:	84ce                	mv	s1,s3
    80006070:	bf41                	j	80006000 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006072:	20058713          	addi	a4,a1,512
    80006076:	00471693          	slli	a3,a4,0x4
    8000607a:	0001d717          	auipc	a4,0x1d
    8000607e:	f8670713          	addi	a4,a4,-122 # 80023000 <disk>
    80006082:	9736                	add	a4,a4,a3
    80006084:	4685                	li	a3,1
    80006086:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000608a:	20058713          	addi	a4,a1,512
    8000608e:	00471693          	slli	a3,a4,0x4
    80006092:	0001d717          	auipc	a4,0x1d
    80006096:	f6e70713          	addi	a4,a4,-146 # 80023000 <disk>
    8000609a:	9736                	add	a4,a4,a3
    8000609c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    800060a0:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800060a4:	7679                	lui	a2,0xffffe
    800060a6:	963e                	add	a2,a2,a5
    800060a8:	0001f697          	auipc	a3,0x1f
    800060ac:	f5868693          	addi	a3,a3,-168 # 80025000 <disk+0x2000>
    800060b0:	6298                	ld	a4,0(a3)
    800060b2:	9732                	add	a4,a4,a2
    800060b4:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800060b6:	6298                	ld	a4,0(a3)
    800060b8:	9732                	add	a4,a4,a2
    800060ba:	4541                	li	a0,16
    800060bc:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800060be:	6298                	ld	a4,0(a3)
    800060c0:	9732                	add	a4,a4,a2
    800060c2:	4505                	li	a0,1
    800060c4:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    800060c8:	f9442703          	lw	a4,-108(s0)
    800060cc:	6288                	ld	a0,0(a3)
    800060ce:	962a                	add	a2,a2,a0
    800060d0:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    800060d4:	0712                	slli	a4,a4,0x4
    800060d6:	6290                	ld	a2,0(a3)
    800060d8:	963a                	add	a2,a2,a4
    800060da:	05890513          	addi	a0,s2,88
    800060de:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    800060e0:	6294                	ld	a3,0(a3)
    800060e2:	96ba                	add	a3,a3,a4
    800060e4:	40000613          	li	a2,1024
    800060e8:	c690                	sw	a2,8(a3)
  if(write)
    800060ea:	140d0063          	beqz	s10,8000622a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800060ee:	0001f697          	auipc	a3,0x1f
    800060f2:	f126b683          	ld	a3,-238(a3) # 80025000 <disk+0x2000>
    800060f6:	96ba                	add	a3,a3,a4
    800060f8:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800060fc:	0001d817          	auipc	a6,0x1d
    80006100:	f0480813          	addi	a6,a6,-252 # 80023000 <disk>
    80006104:	0001f517          	auipc	a0,0x1f
    80006108:	efc50513          	addi	a0,a0,-260 # 80025000 <disk+0x2000>
    8000610c:	6114                	ld	a3,0(a0)
    8000610e:	96ba                	add	a3,a3,a4
    80006110:	00c6d603          	lhu	a2,12(a3)
    80006114:	00166613          	ori	a2,a2,1
    80006118:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000611c:	f9842683          	lw	a3,-104(s0)
    80006120:	6110                	ld	a2,0(a0)
    80006122:	9732                	add	a4,a4,a2
    80006124:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006128:	20058613          	addi	a2,a1,512
    8000612c:	0612                	slli	a2,a2,0x4
    8000612e:	9642                	add	a2,a2,a6
    80006130:	577d                	li	a4,-1
    80006132:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006136:	00469713          	slli	a4,a3,0x4
    8000613a:	6114                	ld	a3,0(a0)
    8000613c:	96ba                	add	a3,a3,a4
    8000613e:	03078793          	addi	a5,a5,48
    80006142:	97c2                	add	a5,a5,a6
    80006144:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006146:	611c                	ld	a5,0(a0)
    80006148:	97ba                	add	a5,a5,a4
    8000614a:	4685                	li	a3,1
    8000614c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000614e:	611c                	ld	a5,0(a0)
    80006150:	97ba                	add	a5,a5,a4
    80006152:	4809                	li	a6,2
    80006154:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006158:	611c                	ld	a5,0(a0)
    8000615a:	973e                	add	a4,a4,a5
    8000615c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006160:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006164:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006168:	6518                	ld	a4,8(a0)
    8000616a:	00275783          	lhu	a5,2(a4)
    8000616e:	8b9d                	andi	a5,a5,7
    80006170:	0786                	slli	a5,a5,0x1
    80006172:	97ba                	add	a5,a5,a4
    80006174:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006178:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000617c:	6518                	ld	a4,8(a0)
    8000617e:	00275783          	lhu	a5,2(a4)
    80006182:	2785                	addiw	a5,a5,1
    80006184:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006188:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000618c:	100017b7          	lui	a5,0x10001
    80006190:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006194:	00492703          	lw	a4,4(s2)
    80006198:	4785                	li	a5,1
    8000619a:	02f71163          	bne	a4,a5,800061bc <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000619e:	0001f997          	auipc	s3,0x1f
    800061a2:	f8a98993          	addi	s3,s3,-118 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    800061a6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800061a8:	85ce                	mv	a1,s3
    800061aa:	854a                	mv	a0,s2
    800061ac:	ffffc097          	auipc	ra,0xffffc
    800061b0:	fa4080e7          	jalr	-92(ra) # 80002150 <sleep>
  while(b->disk == 1) {
    800061b4:	00492783          	lw	a5,4(s2)
    800061b8:	fe9788e3          	beq	a5,s1,800061a8 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    800061bc:	f9042903          	lw	s2,-112(s0)
    800061c0:	20090793          	addi	a5,s2,512
    800061c4:	00479713          	slli	a4,a5,0x4
    800061c8:	0001d797          	auipc	a5,0x1d
    800061cc:	e3878793          	addi	a5,a5,-456 # 80023000 <disk>
    800061d0:	97ba                	add	a5,a5,a4
    800061d2:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800061d6:	0001f997          	auipc	s3,0x1f
    800061da:	e2a98993          	addi	s3,s3,-470 # 80025000 <disk+0x2000>
    800061de:	00491713          	slli	a4,s2,0x4
    800061e2:	0009b783          	ld	a5,0(s3)
    800061e6:	97ba                	add	a5,a5,a4
    800061e8:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800061ec:	854a                	mv	a0,s2
    800061ee:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800061f2:	00000097          	auipc	ra,0x0
    800061f6:	bc4080e7          	jalr	-1084(ra) # 80005db6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800061fa:	8885                	andi	s1,s1,1
    800061fc:	f0ed                	bnez	s1,800061de <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800061fe:	0001f517          	auipc	a0,0x1f
    80006202:	f2a50513          	addi	a0,a0,-214 # 80025128 <disk+0x2128>
    80006206:	ffffb097          	auipc	ra,0xffffb
    8000620a:	a92080e7          	jalr	-1390(ra) # 80000c98 <release>
}
    8000620e:	70a6                	ld	ra,104(sp)
    80006210:	7406                	ld	s0,96(sp)
    80006212:	64e6                	ld	s1,88(sp)
    80006214:	6946                	ld	s2,80(sp)
    80006216:	69a6                	ld	s3,72(sp)
    80006218:	6a06                	ld	s4,64(sp)
    8000621a:	7ae2                	ld	s5,56(sp)
    8000621c:	7b42                	ld	s6,48(sp)
    8000621e:	7ba2                	ld	s7,40(sp)
    80006220:	7c02                	ld	s8,32(sp)
    80006222:	6ce2                	ld	s9,24(sp)
    80006224:	6d42                	ld	s10,16(sp)
    80006226:	6165                	addi	sp,sp,112
    80006228:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000622a:	0001f697          	auipc	a3,0x1f
    8000622e:	dd66b683          	ld	a3,-554(a3) # 80025000 <disk+0x2000>
    80006232:	96ba                	add	a3,a3,a4
    80006234:	4609                	li	a2,2
    80006236:	00c69623          	sh	a2,12(a3)
    8000623a:	b5c9                	j	800060fc <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000623c:	f9042583          	lw	a1,-112(s0)
    80006240:	20058793          	addi	a5,a1,512
    80006244:	0792                	slli	a5,a5,0x4
    80006246:	0001d517          	auipc	a0,0x1d
    8000624a:	e6250513          	addi	a0,a0,-414 # 800230a8 <disk+0xa8>
    8000624e:	953e                	add	a0,a0,a5
  if(write)
    80006250:	e20d11e3          	bnez	s10,80006072 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006254:	20058713          	addi	a4,a1,512
    80006258:	00471693          	slli	a3,a4,0x4
    8000625c:	0001d717          	auipc	a4,0x1d
    80006260:	da470713          	addi	a4,a4,-604 # 80023000 <disk>
    80006264:	9736                	add	a4,a4,a3
    80006266:	0a072423          	sw	zero,168(a4)
    8000626a:	b505                	j	8000608a <virtio_disk_rw+0xf4>

000000008000626c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000626c:	1101                	addi	sp,sp,-32
    8000626e:	ec06                	sd	ra,24(sp)
    80006270:	e822                	sd	s0,16(sp)
    80006272:	e426                	sd	s1,8(sp)
    80006274:	e04a                	sd	s2,0(sp)
    80006276:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006278:	0001f517          	auipc	a0,0x1f
    8000627c:	eb050513          	addi	a0,a0,-336 # 80025128 <disk+0x2128>
    80006280:	ffffb097          	auipc	ra,0xffffb
    80006284:	964080e7          	jalr	-1692(ra) # 80000be4 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006288:	10001737          	lui	a4,0x10001
    8000628c:	533c                	lw	a5,96(a4)
    8000628e:	8b8d                	andi	a5,a5,3
    80006290:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006292:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006296:	0001f797          	auipc	a5,0x1f
    8000629a:	d6a78793          	addi	a5,a5,-662 # 80025000 <disk+0x2000>
    8000629e:	6b94                	ld	a3,16(a5)
    800062a0:	0207d703          	lhu	a4,32(a5)
    800062a4:	0026d783          	lhu	a5,2(a3)
    800062a8:	06f70163          	beq	a4,a5,8000630a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800062ac:	0001d917          	auipc	s2,0x1d
    800062b0:	d5490913          	addi	s2,s2,-684 # 80023000 <disk>
    800062b4:	0001f497          	auipc	s1,0x1f
    800062b8:	d4c48493          	addi	s1,s1,-692 # 80025000 <disk+0x2000>
    __sync_synchronize();
    800062bc:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800062c0:	6898                	ld	a4,16(s1)
    800062c2:	0204d783          	lhu	a5,32(s1)
    800062c6:	8b9d                	andi	a5,a5,7
    800062c8:	078e                	slli	a5,a5,0x3
    800062ca:	97ba                	add	a5,a5,a4
    800062cc:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800062ce:	20078713          	addi	a4,a5,512
    800062d2:	0712                	slli	a4,a4,0x4
    800062d4:	974a                	add	a4,a4,s2
    800062d6:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    800062da:	e731                	bnez	a4,80006326 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800062dc:	20078793          	addi	a5,a5,512
    800062e0:	0792                	slli	a5,a5,0x4
    800062e2:	97ca                	add	a5,a5,s2
    800062e4:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    800062e6:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800062ea:	ffffc097          	auipc	ra,0xffffc
    800062ee:	ff2080e7          	jalr	-14(ra) # 800022dc <wakeup>

    disk.used_idx += 1;
    800062f2:	0204d783          	lhu	a5,32(s1)
    800062f6:	2785                	addiw	a5,a5,1
    800062f8:	17c2                	slli	a5,a5,0x30
    800062fa:	93c1                	srli	a5,a5,0x30
    800062fc:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006300:	6898                	ld	a4,16(s1)
    80006302:	00275703          	lhu	a4,2(a4)
    80006306:	faf71be3          	bne	a4,a5,800062bc <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000630a:	0001f517          	auipc	a0,0x1f
    8000630e:	e1e50513          	addi	a0,a0,-482 # 80025128 <disk+0x2128>
    80006312:	ffffb097          	auipc	ra,0xffffb
    80006316:	986080e7          	jalr	-1658(ra) # 80000c98 <release>
}
    8000631a:	60e2                	ld	ra,24(sp)
    8000631c:	6442                	ld	s0,16(sp)
    8000631e:	64a2                	ld	s1,8(sp)
    80006320:	6902                	ld	s2,0(sp)
    80006322:	6105                	addi	sp,sp,32
    80006324:	8082                	ret
      panic("virtio_disk_intr status");
    80006326:	00002517          	auipc	a0,0x2
    8000632a:	50a50513          	addi	a0,a0,1290 # 80008830 <syscalls+0x3b8>
    8000632e:	ffffa097          	auipc	ra,0xffffa
    80006332:	210080e7          	jalr	528(ra) # 8000053e <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
