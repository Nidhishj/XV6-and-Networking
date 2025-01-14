
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	a6010113          	addi	sp,sp,-1440 # 80008a60 <stack0>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
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
    80000056:	8ce70713          	addi	a4,a4,-1842 # 80008920 <timer_scratch>
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
    80000068:	2bc78793          	addi	a5,a5,700 # 80006320 <timervec>
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
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd965f>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	dca78793          	addi	a5,a5,-566 # 80000e78 <main>
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
    80000130:	6f8080e7          	jalr	1784(ra) # 80002824 <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	780080e7          	jalr	1920(ra) # 800008bc <uartputc>
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
    80000164:	7159                	addi	sp,sp,-112
    80000166:	f486                	sd	ra,104(sp)
    80000168:	f0a2                	sd	s0,96(sp)
    8000016a:	eca6                	sd	s1,88(sp)
    8000016c:	e8ca                	sd	s2,80(sp)
    8000016e:	e4ce                	sd	s3,72(sp)
    80000170:	e0d2                	sd	s4,64(sp)
    80000172:	fc56                	sd	s5,56(sp)
    80000174:	f85a                	sd	s6,48(sp)
    80000176:	f45e                	sd	s7,40(sp)
    80000178:	f062                	sd	s8,32(sp)
    8000017a:	ec66                	sd	s9,24(sp)
    8000017c:	e86a                	sd	s10,16(sp)
    8000017e:	1880                	addi	s0,sp,112
    80000180:	8aaa                	mv	s5,a0
    80000182:	8a2e                	mv	s4,a1
    80000184:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000186:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018a:	00011517          	auipc	a0,0x11
    8000018e:	8d650513          	addi	a0,a0,-1834 # 80010a60 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a44080e7          	jalr	-1468(ra) # 80000bd6 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	8c648493          	addi	s1,s1,-1850 # 80010a60 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	95690913          	addi	s2,s2,-1706 # 80010af8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001aa:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001ae:	4ca9                	li	s9,10
  while(n > 0){
    800001b0:	07305b63          	blez	s3,80000226 <consoleread+0xc2>
    while(cons.r == cons.w){
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71763          	bne	a4,a5,800001ea <consoleread+0x86>
      if(killed(myproc())){
    800001c0:	00002097          	auipc	ra,0x2
    800001c4:	952080e7          	jalr	-1710(ra) # 80001b12 <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	482080e7          	jalr	1154(ra) # 8000264a <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	1ac080e7          	jalr	428(ra) # 80002382 <sleep>
    while(cons.r == cons.w){
    800001de:	0984a783          	lw	a5,152(s1)
    800001e2:	09c4a703          	lw	a4,156(s1)
    800001e6:	fcf70de3          	beq	a4,a5,800001c0 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ea:	0017871b          	addiw	a4,a5,1
    800001ee:	08e4ac23          	sw	a4,152(s1)
    800001f2:	07f7f713          	andi	a4,a5,127
    800001f6:	9726                	add	a4,a4,s1
    800001f8:	01874703          	lbu	a4,24(a4)
    800001fc:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    80000200:	077d0563          	beq	s10,s7,8000026a <consoleread+0x106>
    cbuf = c;
    80000204:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000208:	4685                	li	a3,1
    8000020a:	f9f40613          	addi	a2,s0,-97
    8000020e:	85d2                	mv	a1,s4
    80000210:	8556                	mv	a0,s5
    80000212:	00002097          	auipc	ra,0x2
    80000216:	5bc080e7          	jalr	1468(ra) # 800027ce <either_copyout>
    8000021a:	01850663          	beq	a0,s8,80000226 <consoleread+0xc2>
    dst++;
    8000021e:	0a05                	addi	s4,s4,1
    --n;
    80000220:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    80000222:	f99d17e3          	bne	s10,s9,800001b0 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000226:	00011517          	auipc	a0,0x11
    8000022a:	83a50513          	addi	a0,a0,-1990 # 80010a60 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	a5c080e7          	jalr	-1444(ra) # 80000c8a <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	82450513          	addi	a0,a0,-2012 # 80010a60 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	a46080e7          	jalr	-1466(ra) # 80000c8a <release>
        return -1;
    8000024c:	557d                	li	a0,-1
}
    8000024e:	70a6                	ld	ra,104(sp)
    80000250:	7406                	ld	s0,96(sp)
    80000252:	64e6                	ld	s1,88(sp)
    80000254:	6946                	ld	s2,80(sp)
    80000256:	69a6                	ld	s3,72(sp)
    80000258:	6a06                	ld	s4,64(sp)
    8000025a:	7ae2                	ld	s5,56(sp)
    8000025c:	7b42                	ld	s6,48(sp)
    8000025e:	7ba2                	ld	s7,40(sp)
    80000260:	7c02                	ld	s8,32(sp)
    80000262:	6ce2                	ld	s9,24(sp)
    80000264:	6d42                	ld	s10,16(sp)
    80000266:	6165                	addi	sp,sp,112
    80000268:	8082                	ret
      if(n < target){
    8000026a:	0009871b          	sext.w	a4,s3
    8000026e:	fb677ce3          	bgeu	a4,s6,80000226 <consoleread+0xc2>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	88f72323          	sw	a5,-1914(a4) # 80010af8 <cons+0x98>
    8000027a:	b775                	j	80000226 <consoleread+0xc2>

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
    80000290:	55e080e7          	jalr	1374(ra) # 800007ea <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	54c080e7          	jalr	1356(ra) # 800007ea <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	540080e7          	jalr	1344(ra) # 800007ea <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	536080e7          	jalr	1334(ra) # 800007ea <uartputc_sync>
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
    800002cc:	00010517          	auipc	a0,0x10
    800002d0:	79450513          	addi	a0,a0,1940 # 80010a60 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	902080e7          	jalr	-1790(ra) # 80000bd6 <acquire>

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
    800002f6:	588080e7          	jalr	1416(ra) # 8000287a <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00010517          	auipc	a0,0x10
    800002fe:	76650513          	addi	a0,a0,1894 # 80010a60 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	988080e7          	jalr	-1656(ra) # 80000c8a <release>
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
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000031e:	00010717          	auipc	a4,0x10
    80000322:	74270713          	addi	a4,a4,1858 # 80010a60 <cons>
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
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000348:	00010797          	auipc	a5,0x10
    8000034c:	71878793          	addi	a5,a5,1816 # 80010a60 <cons>
    80000350:	0a07a683          	lw	a3,160(a5)
    80000354:	0016871b          	addiw	a4,a3,1
    80000358:	0007061b          	sext.w	a2,a4
    8000035c:	0ae7a023          	sw	a4,160(a5)
    80000360:	07f6f693          	andi	a3,a3,127
    80000364:	97b6                	add	a5,a5,a3
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00010797          	auipc	a5,0x10
    8000037a:	7827a783          	lw	a5,1922(a5) # 80010af8 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00010717          	auipc	a4,0x10
    8000038e:	6d670713          	addi	a4,a4,1750 # 80010a60 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00010497          	auipc	s1,0x10
    8000039e:	6c648493          	addi	s1,s1,1734 # 80010a60 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
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
    800003d6:	00010717          	auipc	a4,0x10
    800003da:	68a70713          	addi	a4,a4,1674 # 80010a60 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00010717          	auipc	a4,0x10
    800003f0:	70f72a23          	sw	a5,1812(a4) # 80010b00 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000412:	00010797          	auipc	a5,0x10
    80000416:	64e78793          	addi	a5,a5,1614 # 80010a60 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00010797          	auipc	a5,0x10
    8000043a:	6cc7a323          	sw	a2,1734(a5) # 80010afc <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00010517          	auipc	a0,0x10
    80000442:	6ba50513          	addi	a0,a0,1722 # 80010af8 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	fa0080e7          	jalr	-96(ra) # 800023e6 <wakeup>
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
    80000460:	00010517          	auipc	a0,0x10
    80000464:	60050513          	addi	a0,a0,1536 # 80010a60 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6de080e7          	jalr	1758(ra) # 80000b46 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32a080e7          	jalr	810(ra) # 8000079a <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00024797          	auipc	a5,0x24
    8000047c:	b9078793          	addi	a5,a5,-1136 # 80024008 <devsw>
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
    8000054a:	00010797          	auipc	a5,0x10
    8000054e:	5c07ab23          	sw	zero,1494(a5) # 80010b20 <pr+0x18>
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
    8000057e:	00008717          	auipc	a4,0x8
    80000582:	36f72123          	sw	a5,866(a4) # 800088e0 <panicked>
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
    800005ba:	00010d97          	auipc	s11,0x10
    800005be:	566dad83          	lw	s11,1382(s11) # 80010b20 <pr+0x18>
  if(locking)
    800005c2:	020d9b63          	bnez	s11,800005f8 <printf+0x70>
  if (fmt == 0)
    800005c6:	040a0263          	beqz	s4,8000060a <printf+0x82>
  va_start(ap, fmt);
    800005ca:	00840793          	addi	a5,s0,8
    800005ce:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d2:	000a4503          	lbu	a0,0(s4)
    800005d6:	14050f63          	beqz	a0,80000734 <printf+0x1ac>
    800005da:	4981                	li	s3,0
    if(c != '%'){
    800005dc:	02500a93          	li	s5,37
    switch(c){
    800005e0:	07000b93          	li	s7,112
  consputc('x');
    800005e4:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e6:	00008b17          	auipc	s6,0x8
    800005ea:	a5ab0b13          	addi	s6,s6,-1446 # 80008040 <digits>
    switch(c){
    800005ee:	07300c93          	li	s9,115
    800005f2:	06400c13          	li	s8,100
    800005f6:	a82d                	j	80000630 <printf+0xa8>
    acquire(&pr.lock);
    800005f8:	00010517          	auipc	a0,0x10
    800005fc:	51050513          	addi	a0,a0,1296 # 80010b08 <pr>
    80000600:	00000097          	auipc	ra,0x0
    80000604:	5d6080e7          	jalr	1494(ra) # 80000bd6 <acquire>
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
    80000622:	2985                	addiw	s3,s3,1
    80000624:	013a07b3          	add	a5,s4,s3
    80000628:	0007c503          	lbu	a0,0(a5)
    8000062c:	10050463          	beqz	a0,80000734 <printf+0x1ac>
    if(c != '%'){
    80000630:	ff5515e3          	bne	a0,s5,8000061a <printf+0x92>
    c = fmt[++i] & 0xff;
    80000634:	2985                	addiw	s3,s3,1
    80000636:	013a07b3          	add	a5,s4,s3
    8000063a:	0007c783          	lbu	a5,0(a5)
    8000063e:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000642:	cbed                	beqz	a5,80000734 <printf+0x1ac>
    switch(c){
    80000644:	05778a63          	beq	a5,s7,80000698 <printf+0x110>
    80000648:	02fbf663          	bgeu	s7,a5,80000674 <printf+0xec>
    8000064c:	09978863          	beq	a5,s9,800006dc <printf+0x154>
    80000650:	07800713          	li	a4,120
    80000654:	0ce79563          	bne	a5,a4,8000071e <printf+0x196>
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
    80000674:	09578f63          	beq	a5,s5,80000712 <printf+0x18a>
    80000678:	0b879363          	bne	a5,s8,8000071e <printf+0x196>
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
    800006a4:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006a8:	03000513          	li	a0,48
    800006ac:	00000097          	auipc	ra,0x0
    800006b0:	bd0080e7          	jalr	-1072(ra) # 8000027c <consputc>
  consputc('x');
    800006b4:	07800513          	li	a0,120
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bc4080e7          	jalr	-1084(ra) # 8000027c <consputc>
    800006c0:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c2:	03c95793          	srli	a5,s2,0x3c
    800006c6:	97da                	add	a5,a5,s6
    800006c8:	0007c503          	lbu	a0,0(a5)
    800006cc:	00000097          	auipc	ra,0x0
    800006d0:	bb0080e7          	jalr	-1104(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d4:	0912                	slli	s2,s2,0x4
    800006d6:	34fd                	addiw	s1,s1,-1
    800006d8:	f4ed                	bnez	s1,800006c2 <printf+0x13a>
    800006da:	b7a1                	j	80000622 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006dc:	f8843783          	ld	a5,-120(s0)
    800006e0:	00878713          	addi	a4,a5,8
    800006e4:	f8e43423          	sd	a4,-120(s0)
    800006e8:	6384                	ld	s1,0(a5)
    800006ea:	cc89                	beqz	s1,80000704 <printf+0x17c>
      for(; *s; s++)
    800006ec:	0004c503          	lbu	a0,0(s1)
    800006f0:	d90d                	beqz	a0,80000622 <printf+0x9a>
        consputc(*s);
    800006f2:	00000097          	auipc	ra,0x0
    800006f6:	b8a080e7          	jalr	-1142(ra) # 8000027c <consputc>
      for(; *s; s++)
    800006fa:	0485                	addi	s1,s1,1
    800006fc:	0004c503          	lbu	a0,0(s1)
    80000700:	f96d                	bnez	a0,800006f2 <printf+0x16a>
    80000702:	b705                	j	80000622 <printf+0x9a>
        s = "(null)";
    80000704:	00008497          	auipc	s1,0x8
    80000708:	91c48493          	addi	s1,s1,-1764 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000070c:	02800513          	li	a0,40
    80000710:	b7cd                	j	800006f2 <printf+0x16a>
      consputc('%');
    80000712:	8556                	mv	a0,s5
    80000714:	00000097          	auipc	ra,0x0
    80000718:	b68080e7          	jalr	-1176(ra) # 8000027c <consputc>
      break;
    8000071c:	b719                	j	80000622 <printf+0x9a>
      consputc('%');
    8000071e:	8556                	mv	a0,s5
    80000720:	00000097          	auipc	ra,0x0
    80000724:	b5c080e7          	jalr	-1188(ra) # 8000027c <consputc>
      consputc(c);
    80000728:	8526                	mv	a0,s1
    8000072a:	00000097          	auipc	ra,0x0
    8000072e:	b52080e7          	jalr	-1198(ra) # 8000027c <consputc>
      break;
    80000732:	bdc5                	j	80000622 <printf+0x9a>
  if(locking)
    80000734:	020d9163          	bnez	s11,80000756 <printf+0x1ce>
}
    80000738:	70e6                	ld	ra,120(sp)
    8000073a:	7446                	ld	s0,112(sp)
    8000073c:	74a6                	ld	s1,104(sp)
    8000073e:	7906                	ld	s2,96(sp)
    80000740:	69e6                	ld	s3,88(sp)
    80000742:	6a46                	ld	s4,80(sp)
    80000744:	6aa6                	ld	s5,72(sp)
    80000746:	6b06                	ld	s6,64(sp)
    80000748:	7be2                	ld	s7,56(sp)
    8000074a:	7c42                	ld	s8,48(sp)
    8000074c:	7ca2                	ld	s9,40(sp)
    8000074e:	7d02                	ld	s10,32(sp)
    80000750:	6de2                	ld	s11,24(sp)
    80000752:	6129                	addi	sp,sp,192
    80000754:	8082                	ret
    release(&pr.lock);
    80000756:	00010517          	auipc	a0,0x10
    8000075a:	3b250513          	addi	a0,a0,946 # 80010b08 <pr>
    8000075e:	00000097          	auipc	ra,0x0
    80000762:	52c080e7          	jalr	1324(ra) # 80000c8a <release>
}
    80000766:	bfc9                	j	80000738 <printf+0x1b0>

0000000080000768 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000768:	1101                	addi	sp,sp,-32
    8000076a:	ec06                	sd	ra,24(sp)
    8000076c:	e822                	sd	s0,16(sp)
    8000076e:	e426                	sd	s1,8(sp)
    80000770:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000772:	00010497          	auipc	s1,0x10
    80000776:	39648493          	addi	s1,s1,918 # 80010b08 <pr>
    8000077a:	00008597          	auipc	a1,0x8
    8000077e:	8be58593          	addi	a1,a1,-1858 # 80008038 <etext+0x38>
    80000782:	8526                	mv	a0,s1
    80000784:	00000097          	auipc	ra,0x0
    80000788:	3c2080e7          	jalr	962(ra) # 80000b46 <initlock>
  pr.locking = 1;
    8000078c:	4785                	li	a5,1
    8000078e:	cc9c                	sw	a5,24(s1)
}
    80000790:	60e2                	ld	ra,24(sp)
    80000792:	6442                	ld	s0,16(sp)
    80000794:	64a2                	ld	s1,8(sp)
    80000796:	6105                	addi	sp,sp,32
    80000798:	8082                	ret

000000008000079a <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000079a:	1141                	addi	sp,sp,-16
    8000079c:	e406                	sd	ra,8(sp)
    8000079e:	e022                	sd	s0,0(sp)
    800007a0:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a2:	100007b7          	lui	a5,0x10000
    800007a6:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007aa:	f8000713          	li	a4,-128
    800007ae:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b2:	470d                	li	a4,3
    800007b4:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007b8:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007bc:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c0:	469d                	li	a3,7
    800007c2:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c6:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007ca:	00008597          	auipc	a1,0x8
    800007ce:	88e58593          	addi	a1,a1,-1906 # 80008058 <digits+0x18>
    800007d2:	00010517          	auipc	a0,0x10
    800007d6:	35650513          	addi	a0,a0,854 # 80010b28 <uart_tx_lock>
    800007da:	00000097          	auipc	ra,0x0
    800007de:	36c080e7          	jalr	876(ra) # 80000b46 <initlock>
}
    800007e2:	60a2                	ld	ra,8(sp)
    800007e4:	6402                	ld	s0,0(sp)
    800007e6:	0141                	addi	sp,sp,16
    800007e8:	8082                	ret

00000000800007ea <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007ea:	1101                	addi	sp,sp,-32
    800007ec:	ec06                	sd	ra,24(sp)
    800007ee:	e822                	sd	s0,16(sp)
    800007f0:	e426                	sd	s1,8(sp)
    800007f2:	1000                	addi	s0,sp,32
    800007f4:	84aa                	mv	s1,a0
  push_off();
    800007f6:	00000097          	auipc	ra,0x0
    800007fa:	394080e7          	jalr	916(ra) # 80000b8a <push_off>

  if(panicked){
    800007fe:	00008797          	auipc	a5,0x8
    80000802:	0e27a783          	lw	a5,226(a5) # 800088e0 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000806:	10000737          	lui	a4,0x10000
  if(panicked){
    8000080a:	c391                	beqz	a5,8000080e <uartputc_sync+0x24>
    for(;;)
    8000080c:	a001                	j	8000080c <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080e:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000812:	0207f793          	andi	a5,a5,32
    80000816:	dfe5                	beqz	a5,8000080e <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000818:	0ff4f513          	andi	a0,s1,255
    8000081c:	100007b7          	lui	a5,0x10000
    80000820:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000824:	00000097          	auipc	ra,0x0
    80000828:	406080e7          	jalr	1030(ra) # 80000c2a <pop_off>
}
    8000082c:	60e2                	ld	ra,24(sp)
    8000082e:	6442                	ld	s0,16(sp)
    80000830:	64a2                	ld	s1,8(sp)
    80000832:	6105                	addi	sp,sp,32
    80000834:	8082                	ret

0000000080000836 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000836:	00008797          	auipc	a5,0x8
    8000083a:	0b27b783          	ld	a5,178(a5) # 800088e8 <uart_tx_r>
    8000083e:	00008717          	auipc	a4,0x8
    80000842:	0b273703          	ld	a4,178(a4) # 800088f0 <uart_tx_w>
    80000846:	06f70a63          	beq	a4,a5,800008ba <uartstart+0x84>
{
    8000084a:	7139                	addi	sp,sp,-64
    8000084c:	fc06                	sd	ra,56(sp)
    8000084e:	f822                	sd	s0,48(sp)
    80000850:	f426                	sd	s1,40(sp)
    80000852:	f04a                	sd	s2,32(sp)
    80000854:	ec4e                	sd	s3,24(sp)
    80000856:	e852                	sd	s4,16(sp)
    80000858:	e456                	sd	s5,8(sp)
    8000085a:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000085c:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000860:	00010a17          	auipc	s4,0x10
    80000864:	2c8a0a13          	addi	s4,s4,712 # 80010b28 <uart_tx_lock>
    uart_tx_r += 1;
    80000868:	00008497          	auipc	s1,0x8
    8000086c:	08048493          	addi	s1,s1,128 # 800088e8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000870:	00008997          	auipc	s3,0x8
    80000874:	08098993          	addi	s3,s3,128 # 800088f0 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000878:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000087c:	02077713          	andi	a4,a4,32
    80000880:	c705                	beqz	a4,800008a8 <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000882:	01f7f713          	andi	a4,a5,31
    80000886:	9752                	add	a4,a4,s4
    80000888:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000088c:	0785                	addi	a5,a5,1
    8000088e:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000890:	8526                	mv	a0,s1
    80000892:	00002097          	auipc	ra,0x2
    80000896:	b54080e7          	jalr	-1196(ra) # 800023e6 <wakeup>
    
    WriteReg(THR, c);
    8000089a:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    8000089e:	609c                	ld	a5,0(s1)
    800008a0:	0009b703          	ld	a4,0(s3)
    800008a4:	fcf71ae3          	bne	a4,a5,80000878 <uartstart+0x42>
  }
}
    800008a8:	70e2                	ld	ra,56(sp)
    800008aa:	7442                	ld	s0,48(sp)
    800008ac:	74a2                	ld	s1,40(sp)
    800008ae:	7902                	ld	s2,32(sp)
    800008b0:	69e2                	ld	s3,24(sp)
    800008b2:	6a42                	ld	s4,16(sp)
    800008b4:	6aa2                	ld	s5,8(sp)
    800008b6:	6121                	addi	sp,sp,64
    800008b8:	8082                	ret
    800008ba:	8082                	ret

00000000800008bc <uartputc>:
{
    800008bc:	7179                	addi	sp,sp,-48
    800008be:	f406                	sd	ra,40(sp)
    800008c0:	f022                	sd	s0,32(sp)
    800008c2:	ec26                	sd	s1,24(sp)
    800008c4:	e84a                	sd	s2,16(sp)
    800008c6:	e44e                	sd	s3,8(sp)
    800008c8:	e052                	sd	s4,0(sp)
    800008ca:	1800                	addi	s0,sp,48
    800008cc:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008ce:	00010517          	auipc	a0,0x10
    800008d2:	25a50513          	addi	a0,a0,602 # 80010b28 <uart_tx_lock>
    800008d6:	00000097          	auipc	ra,0x0
    800008da:	300080e7          	jalr	768(ra) # 80000bd6 <acquire>
  if(panicked){
    800008de:	00008797          	auipc	a5,0x8
    800008e2:	0027a783          	lw	a5,2(a5) # 800088e0 <panicked>
    800008e6:	e7c9                	bnez	a5,80000970 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008e8:	00008717          	auipc	a4,0x8
    800008ec:	00873703          	ld	a4,8(a4) # 800088f0 <uart_tx_w>
    800008f0:	00008797          	auipc	a5,0x8
    800008f4:	ff87b783          	ld	a5,-8(a5) # 800088e8 <uart_tx_r>
    800008f8:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fc:	00010997          	auipc	s3,0x10
    80000900:	22c98993          	addi	s3,s3,556 # 80010b28 <uart_tx_lock>
    80000904:	00008497          	auipc	s1,0x8
    80000908:	fe448493          	addi	s1,s1,-28 # 800088e8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090c:	00008917          	auipc	s2,0x8
    80000910:	fe490913          	addi	s2,s2,-28 # 800088f0 <uart_tx_w>
    80000914:	00e79f63          	bne	a5,a4,80000932 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    80000918:	85ce                	mv	a1,s3
    8000091a:	8526                	mv	a0,s1
    8000091c:	00002097          	auipc	ra,0x2
    80000920:	a66080e7          	jalr	-1434(ra) # 80002382 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000924:	00093703          	ld	a4,0(s2)
    80000928:	609c                	ld	a5,0(s1)
    8000092a:	02078793          	addi	a5,a5,32
    8000092e:	fee785e3          	beq	a5,a4,80000918 <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000932:	00010497          	auipc	s1,0x10
    80000936:	1f648493          	addi	s1,s1,502 # 80010b28 <uart_tx_lock>
    8000093a:	01f77793          	andi	a5,a4,31
    8000093e:	97a6                	add	a5,a5,s1
    80000940:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000944:	0705                	addi	a4,a4,1
    80000946:	00008797          	auipc	a5,0x8
    8000094a:	fae7b523          	sd	a4,-86(a5) # 800088f0 <uart_tx_w>
  uartstart();
    8000094e:	00000097          	auipc	ra,0x0
    80000952:	ee8080e7          	jalr	-280(ra) # 80000836 <uartstart>
  release(&uart_tx_lock);
    80000956:	8526                	mv	a0,s1
    80000958:	00000097          	auipc	ra,0x0
    8000095c:	332080e7          	jalr	818(ra) # 80000c8a <release>
}
    80000960:	70a2                	ld	ra,40(sp)
    80000962:	7402                	ld	s0,32(sp)
    80000964:	64e2                	ld	s1,24(sp)
    80000966:	6942                	ld	s2,16(sp)
    80000968:	69a2                	ld	s3,8(sp)
    8000096a:	6a02                	ld	s4,0(sp)
    8000096c:	6145                	addi	sp,sp,48
    8000096e:	8082                	ret
    for(;;)
    80000970:	a001                	j	80000970 <uartputc+0xb4>

0000000080000972 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000972:	1141                	addi	sp,sp,-16
    80000974:	e422                	sd	s0,8(sp)
    80000976:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000978:	100007b7          	lui	a5,0x10000
    8000097c:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000980:	8b85                	andi	a5,a5,1
    80000982:	cb91                	beqz	a5,80000996 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000984:	100007b7          	lui	a5,0x10000
    80000988:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000098c:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    80000990:	6422                	ld	s0,8(sp)
    80000992:	0141                	addi	sp,sp,16
    80000994:	8082                	ret
    return -1;
    80000996:	557d                	li	a0,-1
    80000998:	bfe5                	j	80000990 <uartgetc+0x1e>

000000008000099a <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    8000099a:	1101                	addi	sp,sp,-32
    8000099c:	ec06                	sd	ra,24(sp)
    8000099e:	e822                	sd	s0,16(sp)
    800009a0:	e426                	sd	s1,8(sp)
    800009a2:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009a4:	54fd                	li	s1,-1
    800009a6:	a029                	j	800009b0 <uartintr+0x16>
      break;
    consoleintr(c);
    800009a8:	00000097          	auipc	ra,0x0
    800009ac:	916080e7          	jalr	-1770(ra) # 800002be <consoleintr>
    int c = uartgetc();
    800009b0:	00000097          	auipc	ra,0x0
    800009b4:	fc2080e7          	jalr	-62(ra) # 80000972 <uartgetc>
    if(c == -1)
    800009b8:	fe9518e3          	bne	a0,s1,800009a8 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009bc:	00010497          	auipc	s1,0x10
    800009c0:	16c48493          	addi	s1,s1,364 # 80010b28 <uart_tx_lock>
    800009c4:	8526                	mv	a0,s1
    800009c6:	00000097          	auipc	ra,0x0
    800009ca:	210080e7          	jalr	528(ra) # 80000bd6 <acquire>
  uartstart();
    800009ce:	00000097          	auipc	ra,0x0
    800009d2:	e68080e7          	jalr	-408(ra) # 80000836 <uartstart>
  release(&uart_tx_lock);
    800009d6:	8526                	mv	a0,s1
    800009d8:	00000097          	auipc	ra,0x0
    800009dc:	2b2080e7          	jalr	690(ra) # 80000c8a <release>
}
    800009e0:	60e2                	ld	ra,24(sp)
    800009e2:	6442                	ld	s0,16(sp)
    800009e4:	64a2                	ld	s1,8(sp)
    800009e6:	6105                	addi	sp,sp,32
    800009e8:	8082                	ret

00000000800009ea <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009ea:	1101                	addi	sp,sp,-32
    800009ec:	ec06                	sd	ra,24(sp)
    800009ee:	e822                	sd	s0,16(sp)
    800009f0:	e426                	sd	s1,8(sp)
    800009f2:	e04a                	sd	s2,0(sp)
    800009f4:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009f6:	03451793          	slli	a5,a0,0x34
    800009fa:	ebb9                	bnez	a5,80000a50 <kfree+0x66>
    800009fc:	84aa                	mv	s1,a0
    800009fe:	00024797          	auipc	a5,0x24
    80000a02:	7a278793          	addi	a5,a5,1954 # 800251a0 <end>
    80000a06:	04f56563          	bltu	a0,a5,80000a50 <kfree+0x66>
    80000a0a:	47c5                	li	a5,17
    80000a0c:	07ee                	slli	a5,a5,0x1b
    80000a0e:	04f57163          	bgeu	a0,a5,80000a50 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a12:	6605                	lui	a2,0x1
    80000a14:	4585                	li	a1,1
    80000a16:	00000097          	auipc	ra,0x0
    80000a1a:	2bc080e7          	jalr	700(ra) # 80000cd2 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a1e:	00010917          	auipc	s2,0x10
    80000a22:	14290913          	addi	s2,s2,322 # 80010b60 <kmem>
    80000a26:	854a                	mv	a0,s2
    80000a28:	00000097          	auipc	ra,0x0
    80000a2c:	1ae080e7          	jalr	430(ra) # 80000bd6 <acquire>
  r->next = kmem.freelist;
    80000a30:	01893783          	ld	a5,24(s2)
    80000a34:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a36:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a3a:	854a                	mv	a0,s2
    80000a3c:	00000097          	auipc	ra,0x0
    80000a40:	24e080e7          	jalr	590(ra) # 80000c8a <release>
}
    80000a44:	60e2                	ld	ra,24(sp)
    80000a46:	6442                	ld	s0,16(sp)
    80000a48:	64a2                	ld	s1,8(sp)
    80000a4a:	6902                	ld	s2,0(sp)
    80000a4c:	6105                	addi	sp,sp,32
    80000a4e:	8082                	ret
    panic("kfree");
    80000a50:	00007517          	auipc	a0,0x7
    80000a54:	61050513          	addi	a0,a0,1552 # 80008060 <digits+0x20>
    80000a58:	00000097          	auipc	ra,0x0
    80000a5c:	ae6080e7          	jalr	-1306(ra) # 8000053e <panic>

0000000080000a60 <freerange>:
{
    80000a60:	7179                	addi	sp,sp,-48
    80000a62:	f406                	sd	ra,40(sp)
    80000a64:	f022                	sd	s0,32(sp)
    80000a66:	ec26                	sd	s1,24(sp)
    80000a68:	e84a                	sd	s2,16(sp)
    80000a6a:	e44e                	sd	s3,8(sp)
    80000a6c:	e052                	sd	s4,0(sp)
    80000a6e:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a70:	6785                	lui	a5,0x1
    80000a72:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a76:	94aa                	add	s1,s1,a0
    80000a78:	757d                	lui	a0,0xfffff
    80000a7a:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a7c:	94be                	add	s1,s1,a5
    80000a7e:	0095ee63          	bltu	a1,s1,80000a9a <freerange+0x3a>
    80000a82:	892e                	mv	s2,a1
    kfree(p);
    80000a84:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a86:	6985                	lui	s3,0x1
    kfree(p);
    80000a88:	01448533          	add	a0,s1,s4
    80000a8c:	00000097          	auipc	ra,0x0
    80000a90:	f5e080e7          	jalr	-162(ra) # 800009ea <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	94ce                	add	s1,s1,s3
    80000a96:	fe9979e3          	bgeu	s2,s1,80000a88 <freerange+0x28>
}
    80000a9a:	70a2                	ld	ra,40(sp)
    80000a9c:	7402                	ld	s0,32(sp)
    80000a9e:	64e2                	ld	s1,24(sp)
    80000aa0:	6942                	ld	s2,16(sp)
    80000aa2:	69a2                	ld	s3,8(sp)
    80000aa4:	6a02                	ld	s4,0(sp)
    80000aa6:	6145                	addi	sp,sp,48
    80000aa8:	8082                	ret

0000000080000aaa <kinit>:
{
    80000aaa:	1141                	addi	sp,sp,-16
    80000aac:	e406                	sd	ra,8(sp)
    80000aae:	e022                	sd	s0,0(sp)
    80000ab0:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ab2:	00007597          	auipc	a1,0x7
    80000ab6:	5b658593          	addi	a1,a1,1462 # 80008068 <digits+0x28>
    80000aba:	00010517          	auipc	a0,0x10
    80000abe:	0a650513          	addi	a0,a0,166 # 80010b60 <kmem>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	084080e7          	jalr	132(ra) # 80000b46 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aca:	45c5                	li	a1,17
    80000acc:	05ee                	slli	a1,a1,0x1b
    80000ace:	00024517          	auipc	a0,0x24
    80000ad2:	6d250513          	addi	a0,a0,1746 # 800251a0 <end>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	f8a080e7          	jalr	-118(ra) # 80000a60 <freerange>
}
    80000ade:	60a2                	ld	ra,8(sp)
    80000ae0:	6402                	ld	s0,0(sp)
    80000ae2:	0141                	addi	sp,sp,16
    80000ae4:	8082                	ret

0000000080000ae6 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae6:	1101                	addi	sp,sp,-32
    80000ae8:	ec06                	sd	ra,24(sp)
    80000aea:	e822                	sd	s0,16(sp)
    80000aec:	e426                	sd	s1,8(sp)
    80000aee:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000af0:	00010497          	auipc	s1,0x10
    80000af4:	07048493          	addi	s1,s1,112 # 80010b60 <kmem>
    80000af8:	8526                	mv	a0,s1
    80000afa:	00000097          	auipc	ra,0x0
    80000afe:	0dc080e7          	jalr	220(ra) # 80000bd6 <acquire>
  r = kmem.freelist;
    80000b02:	6c84                	ld	s1,24(s1)
  if(r)
    80000b04:	c885                	beqz	s1,80000b34 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b06:	609c                	ld	a5,0(s1)
    80000b08:	00010517          	auipc	a0,0x10
    80000b0c:	05850513          	addi	a0,a0,88 # 80010b60 <kmem>
    80000b10:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b12:	00000097          	auipc	ra,0x0
    80000b16:	178080e7          	jalr	376(ra) # 80000c8a <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b1a:	6605                	lui	a2,0x1
    80000b1c:	4595                	li	a1,5
    80000b1e:	8526                	mv	a0,s1
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	1b2080e7          	jalr	434(ra) # 80000cd2 <memset>
  return (void*)r;
}
    80000b28:	8526                	mv	a0,s1
    80000b2a:	60e2                	ld	ra,24(sp)
    80000b2c:	6442                	ld	s0,16(sp)
    80000b2e:	64a2                	ld	s1,8(sp)
    80000b30:	6105                	addi	sp,sp,32
    80000b32:	8082                	ret
  release(&kmem.lock);
    80000b34:	00010517          	auipc	a0,0x10
    80000b38:	02c50513          	addi	a0,a0,44 # 80010b60 <kmem>
    80000b3c:	00000097          	auipc	ra,0x0
    80000b40:	14e080e7          	jalr	334(ra) # 80000c8a <release>
  if(r)
    80000b44:	b7d5                	j	80000b28 <kalloc+0x42>

0000000080000b46 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b46:	1141                	addi	sp,sp,-16
    80000b48:	e422                	sd	s0,8(sp)
    80000b4a:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b4c:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b4e:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b52:	00053823          	sd	zero,16(a0)
}
    80000b56:	6422                	ld	s0,8(sp)
    80000b58:	0141                	addi	sp,sp,16
    80000b5a:	8082                	ret

0000000080000b5c <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b5c:	411c                	lw	a5,0(a0)
    80000b5e:	e399                	bnez	a5,80000b64 <holding+0x8>
    80000b60:	4501                	li	a0,0
  return r;
}
    80000b62:	8082                	ret
{
    80000b64:	1101                	addi	sp,sp,-32
    80000b66:	ec06                	sd	ra,24(sp)
    80000b68:	e822                	sd	s0,16(sp)
    80000b6a:	e426                	sd	s1,8(sp)
    80000b6c:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b6e:	6904                	ld	s1,16(a0)
    80000b70:	00001097          	auipc	ra,0x1
    80000b74:	f86080e7          	jalr	-122(ra) # 80001af6 <mycpu>
    80000b78:	40a48533          	sub	a0,s1,a0
    80000b7c:	00153513          	seqz	a0,a0
}
    80000b80:	60e2                	ld	ra,24(sp)
    80000b82:	6442                	ld	s0,16(sp)
    80000b84:	64a2                	ld	s1,8(sp)
    80000b86:	6105                	addi	sp,sp,32
    80000b88:	8082                	ret

0000000080000b8a <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b8a:	1101                	addi	sp,sp,-32
    80000b8c:	ec06                	sd	ra,24(sp)
    80000b8e:	e822                	sd	s0,16(sp)
    80000b90:	e426                	sd	s1,8(sp)
    80000b92:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b94:	100024f3          	csrr	s1,sstatus
    80000b98:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b9c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b9e:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000ba2:	00001097          	auipc	ra,0x1
    80000ba6:	f54080e7          	jalr	-172(ra) # 80001af6 <mycpu>
    80000baa:	5d3c                	lw	a5,120(a0)
    80000bac:	cf89                	beqz	a5,80000bc6 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bae:	00001097          	auipc	ra,0x1
    80000bb2:	f48080e7          	jalr	-184(ra) # 80001af6 <mycpu>
    80000bb6:	5d3c                	lw	a5,120(a0)
    80000bb8:	2785                	addiw	a5,a5,1
    80000bba:	dd3c                	sw	a5,120(a0)
}
    80000bbc:	60e2                	ld	ra,24(sp)
    80000bbe:	6442                	ld	s0,16(sp)
    80000bc0:	64a2                	ld	s1,8(sp)
    80000bc2:	6105                	addi	sp,sp,32
    80000bc4:	8082                	ret
    mycpu()->intena = old;
    80000bc6:	00001097          	auipc	ra,0x1
    80000bca:	f30080e7          	jalr	-208(ra) # 80001af6 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bce:	8085                	srli	s1,s1,0x1
    80000bd0:	8885                	andi	s1,s1,1
    80000bd2:	dd64                	sw	s1,124(a0)
    80000bd4:	bfe9                	j	80000bae <push_off+0x24>

0000000080000bd6 <acquire>:
{
    80000bd6:	1101                	addi	sp,sp,-32
    80000bd8:	ec06                	sd	ra,24(sp)
    80000bda:	e822                	sd	s0,16(sp)
    80000bdc:	e426                	sd	s1,8(sp)
    80000bde:	1000                	addi	s0,sp,32
    80000be0:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000be2:	00000097          	auipc	ra,0x0
    80000be6:	fa8080e7          	jalr	-88(ra) # 80000b8a <push_off>
  if(holding(lk))
    80000bea:	8526                	mv	a0,s1
    80000bec:	00000097          	auipc	ra,0x0
    80000bf0:	f70080e7          	jalr	-144(ra) # 80000b5c <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf4:	4705                	li	a4,1
  if(holding(lk))
    80000bf6:	e115                	bnez	a0,80000c1a <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf8:	87ba                	mv	a5,a4
    80000bfa:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bfe:	2781                	sext.w	a5,a5
    80000c00:	ffe5                	bnez	a5,80000bf8 <acquire+0x22>
  __sync_synchronize();
    80000c02:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c06:	00001097          	auipc	ra,0x1
    80000c0a:	ef0080e7          	jalr	-272(ra) # 80001af6 <mycpu>
    80000c0e:	e888                	sd	a0,16(s1)
}
    80000c10:	60e2                	ld	ra,24(sp)
    80000c12:	6442                	ld	s0,16(sp)
    80000c14:	64a2                	ld	s1,8(sp)
    80000c16:	6105                	addi	sp,sp,32
    80000c18:	8082                	ret
    panic("acquire");
    80000c1a:	00007517          	auipc	a0,0x7
    80000c1e:	45650513          	addi	a0,a0,1110 # 80008070 <digits+0x30>
    80000c22:	00000097          	auipc	ra,0x0
    80000c26:	91c080e7          	jalr	-1764(ra) # 8000053e <panic>

0000000080000c2a <pop_off>:

void
pop_off(void)
{
    80000c2a:	1141                	addi	sp,sp,-16
    80000c2c:	e406                	sd	ra,8(sp)
    80000c2e:	e022                	sd	s0,0(sp)
    80000c30:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c32:	00001097          	auipc	ra,0x1
    80000c36:	ec4080e7          	jalr	-316(ra) # 80001af6 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c3a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c3e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c40:	e78d                	bnez	a5,80000c6a <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c42:	5d3c                	lw	a5,120(a0)
    80000c44:	02f05b63          	blez	a5,80000c7a <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c48:	37fd                	addiw	a5,a5,-1
    80000c4a:	0007871b          	sext.w	a4,a5
    80000c4e:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c50:	eb09                	bnez	a4,80000c62 <pop_off+0x38>
    80000c52:	5d7c                	lw	a5,124(a0)
    80000c54:	c799                	beqz	a5,80000c62 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c56:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c5a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c5e:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c62:	60a2                	ld	ra,8(sp)
    80000c64:	6402                	ld	s0,0(sp)
    80000c66:	0141                	addi	sp,sp,16
    80000c68:	8082                	ret
    panic("pop_off - interruptible");
    80000c6a:	00007517          	auipc	a0,0x7
    80000c6e:	40e50513          	addi	a0,a0,1038 # 80008078 <digits+0x38>
    80000c72:	00000097          	auipc	ra,0x0
    80000c76:	8cc080e7          	jalr	-1844(ra) # 8000053e <panic>
    panic("pop_off");
    80000c7a:	00007517          	auipc	a0,0x7
    80000c7e:	41650513          	addi	a0,a0,1046 # 80008090 <digits+0x50>
    80000c82:	00000097          	auipc	ra,0x0
    80000c86:	8bc080e7          	jalr	-1860(ra) # 8000053e <panic>

0000000080000c8a <release>:
{
    80000c8a:	1101                	addi	sp,sp,-32
    80000c8c:	ec06                	sd	ra,24(sp)
    80000c8e:	e822                	sd	s0,16(sp)
    80000c90:	e426                	sd	s1,8(sp)
    80000c92:	1000                	addi	s0,sp,32
    80000c94:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c96:	00000097          	auipc	ra,0x0
    80000c9a:	ec6080e7          	jalr	-314(ra) # 80000b5c <holding>
    80000c9e:	c115                	beqz	a0,80000cc2 <release+0x38>
  lk->cpu = 0;
    80000ca0:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000ca4:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca8:	0f50000f          	fence	iorw,ow
    80000cac:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cb0:	00000097          	auipc	ra,0x0
    80000cb4:	f7a080e7          	jalr	-134(ra) # 80000c2a <pop_off>
}
    80000cb8:	60e2                	ld	ra,24(sp)
    80000cba:	6442                	ld	s0,16(sp)
    80000cbc:	64a2                	ld	s1,8(sp)
    80000cbe:	6105                	addi	sp,sp,32
    80000cc0:	8082                	ret
    panic("release");
    80000cc2:	00007517          	auipc	a0,0x7
    80000cc6:	3d650513          	addi	a0,a0,982 # 80008098 <digits+0x58>
    80000cca:	00000097          	auipc	ra,0x0
    80000cce:	874080e7          	jalr	-1932(ra) # 8000053e <panic>

0000000080000cd2 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cd2:	1141                	addi	sp,sp,-16
    80000cd4:	e422                	sd	s0,8(sp)
    80000cd6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd8:	ca19                	beqz	a2,80000cee <memset+0x1c>
    80000cda:	87aa                	mv	a5,a0
    80000cdc:	1602                	slli	a2,a2,0x20
    80000cde:	9201                	srli	a2,a2,0x20
    80000ce0:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000ce4:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000ce8:	0785                	addi	a5,a5,1
    80000cea:	fee79de3          	bne	a5,a4,80000ce4 <memset+0x12>
  }
  return dst;
}
    80000cee:	6422                	ld	s0,8(sp)
    80000cf0:	0141                	addi	sp,sp,16
    80000cf2:	8082                	ret

0000000080000cf4 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cf4:	1141                	addi	sp,sp,-16
    80000cf6:	e422                	sd	s0,8(sp)
    80000cf8:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cfa:	ca05                	beqz	a2,80000d2a <memcmp+0x36>
    80000cfc:	fff6069b          	addiw	a3,a2,-1
    80000d00:	1682                	slli	a3,a3,0x20
    80000d02:	9281                	srli	a3,a3,0x20
    80000d04:	0685                	addi	a3,a3,1
    80000d06:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d08:	00054783          	lbu	a5,0(a0)
    80000d0c:	0005c703          	lbu	a4,0(a1)
    80000d10:	00e79863          	bne	a5,a4,80000d20 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d14:	0505                	addi	a0,a0,1
    80000d16:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d18:	fed518e3          	bne	a0,a3,80000d08 <memcmp+0x14>
  }

  return 0;
    80000d1c:	4501                	li	a0,0
    80000d1e:	a019                	j	80000d24 <memcmp+0x30>
      return *s1 - *s2;
    80000d20:	40e7853b          	subw	a0,a5,a4
}
    80000d24:	6422                	ld	s0,8(sp)
    80000d26:	0141                	addi	sp,sp,16
    80000d28:	8082                	ret
  return 0;
    80000d2a:	4501                	li	a0,0
    80000d2c:	bfe5                	j	80000d24 <memcmp+0x30>

0000000080000d2e <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d2e:	1141                	addi	sp,sp,-16
    80000d30:	e422                	sd	s0,8(sp)
    80000d32:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d34:	c205                	beqz	a2,80000d54 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d36:	02a5e263          	bltu	a1,a0,80000d5a <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d3a:	1602                	slli	a2,a2,0x20
    80000d3c:	9201                	srli	a2,a2,0x20
    80000d3e:	00c587b3          	add	a5,a1,a2
{
    80000d42:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d44:	0585                	addi	a1,a1,1
    80000d46:	0705                	addi	a4,a4,1
    80000d48:	fff5c683          	lbu	a3,-1(a1)
    80000d4c:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d50:	fef59ae3          	bne	a1,a5,80000d44 <memmove+0x16>

  return dst;
}
    80000d54:	6422                	ld	s0,8(sp)
    80000d56:	0141                	addi	sp,sp,16
    80000d58:	8082                	ret
  if(s < d && s + n > d){
    80000d5a:	02061693          	slli	a3,a2,0x20
    80000d5e:	9281                	srli	a3,a3,0x20
    80000d60:	00d58733          	add	a4,a1,a3
    80000d64:	fce57be3          	bgeu	a0,a4,80000d3a <memmove+0xc>
    d += n;
    80000d68:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d6a:	fff6079b          	addiw	a5,a2,-1
    80000d6e:	1782                	slli	a5,a5,0x20
    80000d70:	9381                	srli	a5,a5,0x20
    80000d72:	fff7c793          	not	a5,a5
    80000d76:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d78:	177d                	addi	a4,a4,-1
    80000d7a:	16fd                	addi	a3,a3,-1
    80000d7c:	00074603          	lbu	a2,0(a4)
    80000d80:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d84:	fee79ae3          	bne	a5,a4,80000d78 <memmove+0x4a>
    80000d88:	b7f1                	j	80000d54 <memmove+0x26>

0000000080000d8a <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d8a:	1141                	addi	sp,sp,-16
    80000d8c:	e406                	sd	ra,8(sp)
    80000d8e:	e022                	sd	s0,0(sp)
    80000d90:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d92:	00000097          	auipc	ra,0x0
    80000d96:	f9c080e7          	jalr	-100(ra) # 80000d2e <memmove>
}
    80000d9a:	60a2                	ld	ra,8(sp)
    80000d9c:	6402                	ld	s0,0(sp)
    80000d9e:	0141                	addi	sp,sp,16
    80000da0:	8082                	ret

0000000080000da2 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000da2:	1141                	addi	sp,sp,-16
    80000da4:	e422                	sd	s0,8(sp)
    80000da6:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000da8:	ce11                	beqz	a2,80000dc4 <strncmp+0x22>
    80000daa:	00054783          	lbu	a5,0(a0)
    80000dae:	cf89                	beqz	a5,80000dc8 <strncmp+0x26>
    80000db0:	0005c703          	lbu	a4,0(a1)
    80000db4:	00f71a63          	bne	a4,a5,80000dc8 <strncmp+0x26>
    n--, p++, q++;
    80000db8:	367d                	addiw	a2,a2,-1
    80000dba:	0505                	addi	a0,a0,1
    80000dbc:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dbe:	f675                	bnez	a2,80000daa <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dc0:	4501                	li	a0,0
    80000dc2:	a809                	j	80000dd4 <strncmp+0x32>
    80000dc4:	4501                	li	a0,0
    80000dc6:	a039                	j	80000dd4 <strncmp+0x32>
  if(n == 0)
    80000dc8:	ca09                	beqz	a2,80000dda <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dca:	00054503          	lbu	a0,0(a0)
    80000dce:	0005c783          	lbu	a5,0(a1)
    80000dd2:	9d1d                	subw	a0,a0,a5
}
    80000dd4:	6422                	ld	s0,8(sp)
    80000dd6:	0141                	addi	sp,sp,16
    80000dd8:	8082                	ret
    return 0;
    80000dda:	4501                	li	a0,0
    80000ddc:	bfe5                	j	80000dd4 <strncmp+0x32>

0000000080000dde <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dde:	1141                	addi	sp,sp,-16
    80000de0:	e422                	sd	s0,8(sp)
    80000de2:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000de4:	872a                	mv	a4,a0
    80000de6:	8832                	mv	a6,a2
    80000de8:	367d                	addiw	a2,a2,-1
    80000dea:	01005963          	blez	a6,80000dfc <strncpy+0x1e>
    80000dee:	0705                	addi	a4,a4,1
    80000df0:	0005c783          	lbu	a5,0(a1)
    80000df4:	fef70fa3          	sb	a5,-1(a4)
    80000df8:	0585                	addi	a1,a1,1
    80000dfa:	f7f5                	bnez	a5,80000de6 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000dfc:	86ba                	mv	a3,a4
    80000dfe:	00c05c63          	blez	a2,80000e16 <strncpy+0x38>
    *s++ = 0;
    80000e02:	0685                	addi	a3,a3,1
    80000e04:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e08:	fff6c793          	not	a5,a3
    80000e0c:	9fb9                	addw	a5,a5,a4
    80000e0e:	010787bb          	addw	a5,a5,a6
    80000e12:	fef048e3          	bgtz	a5,80000e02 <strncpy+0x24>
  return os;
}
    80000e16:	6422                	ld	s0,8(sp)
    80000e18:	0141                	addi	sp,sp,16
    80000e1a:	8082                	ret

0000000080000e1c <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e1c:	1141                	addi	sp,sp,-16
    80000e1e:	e422                	sd	s0,8(sp)
    80000e20:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e22:	02c05363          	blez	a2,80000e48 <safestrcpy+0x2c>
    80000e26:	fff6069b          	addiw	a3,a2,-1
    80000e2a:	1682                	slli	a3,a3,0x20
    80000e2c:	9281                	srli	a3,a3,0x20
    80000e2e:	96ae                	add	a3,a3,a1
    80000e30:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e32:	00d58963          	beq	a1,a3,80000e44 <safestrcpy+0x28>
    80000e36:	0585                	addi	a1,a1,1
    80000e38:	0785                	addi	a5,a5,1
    80000e3a:	fff5c703          	lbu	a4,-1(a1)
    80000e3e:	fee78fa3          	sb	a4,-1(a5)
    80000e42:	fb65                	bnez	a4,80000e32 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e44:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e48:	6422                	ld	s0,8(sp)
    80000e4a:	0141                	addi	sp,sp,16
    80000e4c:	8082                	ret

0000000080000e4e <strlen>:

int
strlen(const char *s)
{
    80000e4e:	1141                	addi	sp,sp,-16
    80000e50:	e422                	sd	s0,8(sp)
    80000e52:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e54:	00054783          	lbu	a5,0(a0)
    80000e58:	cf91                	beqz	a5,80000e74 <strlen+0x26>
    80000e5a:	0505                	addi	a0,a0,1
    80000e5c:	87aa                	mv	a5,a0
    80000e5e:	4685                	li	a3,1
    80000e60:	9e89                	subw	a3,a3,a0
    80000e62:	00f6853b          	addw	a0,a3,a5
    80000e66:	0785                	addi	a5,a5,1
    80000e68:	fff7c703          	lbu	a4,-1(a5)
    80000e6c:	fb7d                	bnez	a4,80000e62 <strlen+0x14>
    ;
  return n;
}
    80000e6e:	6422                	ld	s0,8(sp)
    80000e70:	0141                	addi	sp,sp,16
    80000e72:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e74:	4501                	li	a0,0
    80000e76:	bfe5                	j	80000e6e <strlen+0x20>

0000000080000e78 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e78:	1141                	addi	sp,sp,-16
    80000e7a:	e406                	sd	ra,8(sp)
    80000e7c:	e022                	sd	s0,0(sp)
    80000e7e:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e80:	00001097          	auipc	ra,0x1
    80000e84:	c66080e7          	jalr	-922(ra) # 80001ae6 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e88:	00008717          	auipc	a4,0x8
    80000e8c:	a7070713          	addi	a4,a4,-1424 # 800088f8 <started>
  if(cpuid() == 0){
    80000e90:	c139                	beqz	a0,80000ed6 <main+0x5e>
    while(started == 0)
    80000e92:	431c                	lw	a5,0(a4)
    80000e94:	2781                	sext.w	a5,a5
    80000e96:	dff5                	beqz	a5,80000e92 <main+0x1a>
      ;
    __sync_synchronize();
    80000e98:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e9c:	00001097          	auipc	ra,0x1
    80000ea0:	c4a080e7          	jalr	-950(ra) # 80001ae6 <cpuid>
    80000ea4:	85aa                	mv	a1,a0
    80000ea6:	00007517          	auipc	a0,0x7
    80000eaa:	21250513          	addi	a0,a0,530 # 800080b8 <digits+0x78>
    80000eae:	fffff097          	auipc	ra,0xfffff
    80000eb2:	6da080e7          	jalr	1754(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80000eb6:	00000097          	auipc	ra,0x0
    80000eba:	0d8080e7          	jalr	216(ra) # 80000f8e <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ebe:	00002097          	auipc	ra,0x2
    80000ec2:	ca6080e7          	jalr	-858(ra) # 80002b64 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec6:	00005097          	auipc	ra,0x5
    80000eca:	49a080e7          	jalr	1178(ra) # 80006360 <plicinithart>
  }

  scheduler();        
    80000ece:	00001097          	auipc	ra,0x1
    80000ed2:	22a080e7          	jalr	554(ra) # 800020f8 <scheduler>
    consoleinit();
    80000ed6:	fffff097          	auipc	ra,0xfffff
    80000eda:	57a080e7          	jalr	1402(ra) # 80000450 <consoleinit>
    printfinit();
    80000ede:	00000097          	auipc	ra,0x0
    80000ee2:	88a080e7          	jalr	-1910(ra) # 80000768 <printfinit>
    printf("\n");
    80000ee6:	00007517          	auipc	a0,0x7
    80000eea:	1e250513          	addi	a0,a0,482 # 800080c8 <digits+0x88>
    80000eee:	fffff097          	auipc	ra,0xfffff
    80000ef2:	69a080e7          	jalr	1690(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80000ef6:	00007517          	auipc	a0,0x7
    80000efa:	1aa50513          	addi	a0,a0,426 # 800080a0 <digits+0x60>
    80000efe:	fffff097          	auipc	ra,0xfffff
    80000f02:	68a080e7          	jalr	1674(ra) # 80000588 <printf>
    printf("\n");
    80000f06:	00007517          	auipc	a0,0x7
    80000f0a:	1c250513          	addi	a0,a0,450 # 800080c8 <digits+0x88>
    80000f0e:	fffff097          	auipc	ra,0xfffff
    80000f12:	67a080e7          	jalr	1658(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80000f16:	00000097          	auipc	ra,0x0
    80000f1a:	b94080e7          	jalr	-1132(ra) # 80000aaa <kinit>
    kvminit();       // create kernel page table
    80000f1e:	00000097          	auipc	ra,0x0
    80000f22:	326080e7          	jalr	806(ra) # 80001244 <kvminit>
    kvminithart();   // turn on paging
    80000f26:	00000097          	auipc	ra,0x0
    80000f2a:	068080e7          	jalr	104(ra) # 80000f8e <kvminithart>
    procinit();      // process table
    80000f2e:	00001097          	auipc	ra,0x1
    80000f32:	9ce080e7          	jalr	-1586(ra) # 800018fc <procinit>
    trapinit();      // trap vectors
    80000f36:	00002097          	auipc	ra,0x2
    80000f3a:	c06080e7          	jalr	-1018(ra) # 80002b3c <trapinit>
    trapinithart();  // install kernel trap vector
    80000f3e:	00002097          	auipc	ra,0x2
    80000f42:	c26080e7          	jalr	-986(ra) # 80002b64 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f46:	00005097          	auipc	ra,0x5
    80000f4a:	404080e7          	jalr	1028(ra) # 8000634a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f4e:	00005097          	auipc	ra,0x5
    80000f52:	412080e7          	jalr	1042(ra) # 80006360 <plicinithart>
    binit();         // buffer cache
    80000f56:	00002097          	auipc	ra,0x2
    80000f5a:	5b8080e7          	jalr	1464(ra) # 8000350e <binit>
    iinit();         // inode table
    80000f5e:	00003097          	auipc	ra,0x3
    80000f62:	c5c080e7          	jalr	-932(ra) # 80003bba <iinit>
    fileinit();      // file table
    80000f66:	00004097          	auipc	ra,0x4
    80000f6a:	bfa080e7          	jalr	-1030(ra) # 80004b60 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f6e:	00005097          	auipc	ra,0x5
    80000f72:	4fa080e7          	jalr	1274(ra) # 80006468 <virtio_disk_init>
    userinit();      // first user process
    80000f76:	00001097          	auipc	ra,0x1
    80000f7a:	ed2080e7          	jalr	-302(ra) # 80001e48 <userinit>
    __sync_synchronize();
    80000f7e:	0ff0000f          	fence
    started = 1;
    80000f82:	4785                	li	a5,1
    80000f84:	00008717          	auipc	a4,0x8
    80000f88:	96f72a23          	sw	a5,-1676(a4) # 800088f8 <started>
    80000f8c:	b789                	j	80000ece <main+0x56>

0000000080000f8e <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f8e:	1141                	addi	sp,sp,-16
    80000f90:	e422                	sd	s0,8(sp)
    80000f92:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000f94:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000f98:	00008797          	auipc	a5,0x8
    80000f9c:	9687b783          	ld	a5,-1688(a5) # 80008900 <kernel_pagetable>
    80000fa0:	83b1                	srli	a5,a5,0xc
    80000fa2:	577d                	li	a4,-1
    80000fa4:	177e                	slli	a4,a4,0x3f
    80000fa6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fa8:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000fac:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000fb0:	6422                	ld	s0,8(sp)
    80000fb2:	0141                	addi	sp,sp,16
    80000fb4:	8082                	ret

0000000080000fb6 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fb6:	7139                	addi	sp,sp,-64
    80000fb8:	fc06                	sd	ra,56(sp)
    80000fba:	f822                	sd	s0,48(sp)
    80000fbc:	f426                	sd	s1,40(sp)
    80000fbe:	f04a                	sd	s2,32(sp)
    80000fc0:	ec4e                	sd	s3,24(sp)
    80000fc2:	e852                	sd	s4,16(sp)
    80000fc4:	e456                	sd	s5,8(sp)
    80000fc6:	e05a                	sd	s6,0(sp)
    80000fc8:	0080                	addi	s0,sp,64
    80000fca:	84aa                	mv	s1,a0
    80000fcc:	89ae                	mv	s3,a1
    80000fce:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fd0:	57fd                	li	a5,-1
    80000fd2:	83e9                	srli	a5,a5,0x1a
    80000fd4:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fd6:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fd8:	04b7f263          	bgeu	a5,a1,8000101c <walk+0x66>
    panic("walk");
    80000fdc:	00007517          	auipc	a0,0x7
    80000fe0:	0f450513          	addi	a0,a0,244 # 800080d0 <digits+0x90>
    80000fe4:	fffff097          	auipc	ra,0xfffff
    80000fe8:	55a080e7          	jalr	1370(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fec:	060a8663          	beqz	s5,80001058 <walk+0xa2>
    80000ff0:	00000097          	auipc	ra,0x0
    80000ff4:	af6080e7          	jalr	-1290(ra) # 80000ae6 <kalloc>
    80000ff8:	84aa                	mv	s1,a0
    80000ffa:	c529                	beqz	a0,80001044 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000ffc:	6605                	lui	a2,0x1
    80000ffe:	4581                	li	a1,0
    80001000:	00000097          	auipc	ra,0x0
    80001004:	cd2080e7          	jalr	-814(ra) # 80000cd2 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001008:	00c4d793          	srli	a5,s1,0xc
    8000100c:	07aa                	slli	a5,a5,0xa
    8000100e:	0017e793          	ori	a5,a5,1
    80001012:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001016:	3a5d                	addiw	s4,s4,-9
    80001018:	036a0063          	beq	s4,s6,80001038 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000101c:	0149d933          	srl	s2,s3,s4
    80001020:	1ff97913          	andi	s2,s2,511
    80001024:	090e                	slli	s2,s2,0x3
    80001026:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001028:	00093483          	ld	s1,0(s2)
    8000102c:	0014f793          	andi	a5,s1,1
    80001030:	dfd5                	beqz	a5,80000fec <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001032:	80a9                	srli	s1,s1,0xa
    80001034:	04b2                	slli	s1,s1,0xc
    80001036:	b7c5                	j	80001016 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001038:	00c9d513          	srli	a0,s3,0xc
    8000103c:	1ff57513          	andi	a0,a0,511
    80001040:	050e                	slli	a0,a0,0x3
    80001042:	9526                	add	a0,a0,s1
}
    80001044:	70e2                	ld	ra,56(sp)
    80001046:	7442                	ld	s0,48(sp)
    80001048:	74a2                	ld	s1,40(sp)
    8000104a:	7902                	ld	s2,32(sp)
    8000104c:	69e2                	ld	s3,24(sp)
    8000104e:	6a42                	ld	s4,16(sp)
    80001050:	6aa2                	ld	s5,8(sp)
    80001052:	6b02                	ld	s6,0(sp)
    80001054:	6121                	addi	sp,sp,64
    80001056:	8082                	ret
        return 0;
    80001058:	4501                	li	a0,0
    8000105a:	b7ed                	j	80001044 <walk+0x8e>

000000008000105c <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000105c:	57fd                	li	a5,-1
    8000105e:	83e9                	srli	a5,a5,0x1a
    80001060:	00b7f463          	bgeu	a5,a1,80001068 <walkaddr+0xc>
    return 0;
    80001064:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001066:	8082                	ret
{
    80001068:	1141                	addi	sp,sp,-16
    8000106a:	e406                	sd	ra,8(sp)
    8000106c:	e022                	sd	s0,0(sp)
    8000106e:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001070:	4601                	li	a2,0
    80001072:	00000097          	auipc	ra,0x0
    80001076:	f44080e7          	jalr	-188(ra) # 80000fb6 <walk>
  if(pte == 0)
    8000107a:	c105                	beqz	a0,8000109a <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000107c:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000107e:	0117f693          	andi	a3,a5,17
    80001082:	4745                	li	a4,17
    return 0;
    80001084:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001086:	00e68663          	beq	a3,a4,80001092 <walkaddr+0x36>
}
    8000108a:	60a2                	ld	ra,8(sp)
    8000108c:	6402                	ld	s0,0(sp)
    8000108e:	0141                	addi	sp,sp,16
    80001090:	8082                	ret
  pa = PTE2PA(*pte);
    80001092:	00a7d513          	srli	a0,a5,0xa
    80001096:	0532                	slli	a0,a0,0xc
  return pa;
    80001098:	bfcd                	j	8000108a <walkaddr+0x2e>
    return 0;
    8000109a:	4501                	li	a0,0
    8000109c:	b7fd                	j	8000108a <walkaddr+0x2e>

000000008000109e <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000109e:	715d                	addi	sp,sp,-80
    800010a0:	e486                	sd	ra,72(sp)
    800010a2:	e0a2                	sd	s0,64(sp)
    800010a4:	fc26                	sd	s1,56(sp)
    800010a6:	f84a                	sd	s2,48(sp)
    800010a8:	f44e                	sd	s3,40(sp)
    800010aa:	f052                	sd	s4,32(sp)
    800010ac:	ec56                	sd	s5,24(sp)
    800010ae:	e85a                	sd	s6,16(sp)
    800010b0:	e45e                	sd	s7,8(sp)
    800010b2:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010b4:	c639                	beqz	a2,80001102 <mappages+0x64>
    800010b6:	8aaa                	mv	s5,a0
    800010b8:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010ba:	77fd                	lui	a5,0xfffff
    800010bc:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    800010c0:	15fd                	addi	a1,a1,-1
    800010c2:	00c589b3          	add	s3,a1,a2
    800010c6:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800010ca:	8952                	mv	s2,s4
    800010cc:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010d0:	6b85                	lui	s7,0x1
    800010d2:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010d6:	4605                	li	a2,1
    800010d8:	85ca                	mv	a1,s2
    800010da:	8556                	mv	a0,s5
    800010dc:	00000097          	auipc	ra,0x0
    800010e0:	eda080e7          	jalr	-294(ra) # 80000fb6 <walk>
    800010e4:	cd1d                	beqz	a0,80001122 <mappages+0x84>
    if(*pte & PTE_V)
    800010e6:	611c                	ld	a5,0(a0)
    800010e8:	8b85                	andi	a5,a5,1
    800010ea:	e785                	bnez	a5,80001112 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010ec:	80b1                	srli	s1,s1,0xc
    800010ee:	04aa                	slli	s1,s1,0xa
    800010f0:	0164e4b3          	or	s1,s1,s6
    800010f4:	0014e493          	ori	s1,s1,1
    800010f8:	e104                	sd	s1,0(a0)
    if(a == last)
    800010fa:	05390063          	beq	s2,s3,8000113a <mappages+0x9c>
    a += PGSIZE;
    800010fe:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001100:	bfc9                	j	800010d2 <mappages+0x34>
    panic("mappages: size");
    80001102:	00007517          	auipc	a0,0x7
    80001106:	fd650513          	addi	a0,a0,-42 # 800080d8 <digits+0x98>
    8000110a:	fffff097          	auipc	ra,0xfffff
    8000110e:	434080e7          	jalr	1076(ra) # 8000053e <panic>
      panic("mappages: remap");
    80001112:	00007517          	auipc	a0,0x7
    80001116:	fd650513          	addi	a0,a0,-42 # 800080e8 <digits+0xa8>
    8000111a:	fffff097          	auipc	ra,0xfffff
    8000111e:	424080e7          	jalr	1060(ra) # 8000053e <panic>
      return -1;
    80001122:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001124:	60a6                	ld	ra,72(sp)
    80001126:	6406                	ld	s0,64(sp)
    80001128:	74e2                	ld	s1,56(sp)
    8000112a:	7942                	ld	s2,48(sp)
    8000112c:	79a2                	ld	s3,40(sp)
    8000112e:	7a02                	ld	s4,32(sp)
    80001130:	6ae2                	ld	s5,24(sp)
    80001132:	6b42                	ld	s6,16(sp)
    80001134:	6ba2                	ld	s7,8(sp)
    80001136:	6161                	addi	sp,sp,80
    80001138:	8082                	ret
  return 0;
    8000113a:	4501                	li	a0,0
    8000113c:	b7e5                	j	80001124 <mappages+0x86>

000000008000113e <kvmmap>:
{
    8000113e:	1141                	addi	sp,sp,-16
    80001140:	e406                	sd	ra,8(sp)
    80001142:	e022                	sd	s0,0(sp)
    80001144:	0800                	addi	s0,sp,16
    80001146:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001148:	86b2                	mv	a3,a2
    8000114a:	863e                	mv	a2,a5
    8000114c:	00000097          	auipc	ra,0x0
    80001150:	f52080e7          	jalr	-174(ra) # 8000109e <mappages>
    80001154:	e509                	bnez	a0,8000115e <kvmmap+0x20>
}
    80001156:	60a2                	ld	ra,8(sp)
    80001158:	6402                	ld	s0,0(sp)
    8000115a:	0141                	addi	sp,sp,16
    8000115c:	8082                	ret
    panic("kvmmap");
    8000115e:	00007517          	auipc	a0,0x7
    80001162:	f9a50513          	addi	a0,a0,-102 # 800080f8 <digits+0xb8>
    80001166:	fffff097          	auipc	ra,0xfffff
    8000116a:	3d8080e7          	jalr	984(ra) # 8000053e <panic>

000000008000116e <kvmmake>:
{
    8000116e:	1101                	addi	sp,sp,-32
    80001170:	ec06                	sd	ra,24(sp)
    80001172:	e822                	sd	s0,16(sp)
    80001174:	e426                	sd	s1,8(sp)
    80001176:	e04a                	sd	s2,0(sp)
    80001178:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000117a:	00000097          	auipc	ra,0x0
    8000117e:	96c080e7          	jalr	-1684(ra) # 80000ae6 <kalloc>
    80001182:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001184:	6605                	lui	a2,0x1
    80001186:	4581                	li	a1,0
    80001188:	00000097          	auipc	ra,0x0
    8000118c:	b4a080e7          	jalr	-1206(ra) # 80000cd2 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001190:	4719                	li	a4,6
    80001192:	6685                	lui	a3,0x1
    80001194:	10000637          	lui	a2,0x10000
    80001198:	100005b7          	lui	a1,0x10000
    8000119c:	8526                	mv	a0,s1
    8000119e:	00000097          	auipc	ra,0x0
    800011a2:	fa0080e7          	jalr	-96(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011a6:	4719                	li	a4,6
    800011a8:	6685                	lui	a3,0x1
    800011aa:	10001637          	lui	a2,0x10001
    800011ae:	100015b7          	lui	a1,0x10001
    800011b2:	8526                	mv	a0,s1
    800011b4:	00000097          	auipc	ra,0x0
    800011b8:	f8a080e7          	jalr	-118(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011bc:	4719                	li	a4,6
    800011be:	004006b7          	lui	a3,0x400
    800011c2:	0c000637          	lui	a2,0xc000
    800011c6:	0c0005b7          	lui	a1,0xc000
    800011ca:	8526                	mv	a0,s1
    800011cc:	00000097          	auipc	ra,0x0
    800011d0:	f72080e7          	jalr	-142(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011d4:	00007917          	auipc	s2,0x7
    800011d8:	e2c90913          	addi	s2,s2,-468 # 80008000 <etext>
    800011dc:	4729                	li	a4,10
    800011de:	80007697          	auipc	a3,0x80007
    800011e2:	e2268693          	addi	a3,a3,-478 # 8000 <_entry-0x7fff8000>
    800011e6:	4605                	li	a2,1
    800011e8:	067e                	slli	a2,a2,0x1f
    800011ea:	85b2                	mv	a1,a2
    800011ec:	8526                	mv	a0,s1
    800011ee:	00000097          	auipc	ra,0x0
    800011f2:	f50080e7          	jalr	-176(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011f6:	4719                	li	a4,6
    800011f8:	46c5                	li	a3,17
    800011fa:	06ee                	slli	a3,a3,0x1b
    800011fc:	412686b3          	sub	a3,a3,s2
    80001200:	864a                	mv	a2,s2
    80001202:	85ca                	mv	a1,s2
    80001204:	8526                	mv	a0,s1
    80001206:	00000097          	auipc	ra,0x0
    8000120a:	f38080e7          	jalr	-200(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000120e:	4729                	li	a4,10
    80001210:	6685                	lui	a3,0x1
    80001212:	00006617          	auipc	a2,0x6
    80001216:	dee60613          	addi	a2,a2,-530 # 80007000 <_trampoline>
    8000121a:	040005b7          	lui	a1,0x4000
    8000121e:	15fd                	addi	a1,a1,-1
    80001220:	05b2                	slli	a1,a1,0xc
    80001222:	8526                	mv	a0,s1
    80001224:	00000097          	auipc	ra,0x0
    80001228:	f1a080e7          	jalr	-230(ra) # 8000113e <kvmmap>
  proc_mapstacks(kpgtbl);
    8000122c:	8526                	mv	a0,s1
    8000122e:	00000097          	auipc	ra,0x0
    80001232:	638080e7          	jalr	1592(ra) # 80001866 <proc_mapstacks>
}
    80001236:	8526                	mv	a0,s1
    80001238:	60e2                	ld	ra,24(sp)
    8000123a:	6442                	ld	s0,16(sp)
    8000123c:	64a2                	ld	s1,8(sp)
    8000123e:	6902                	ld	s2,0(sp)
    80001240:	6105                	addi	sp,sp,32
    80001242:	8082                	ret

0000000080001244 <kvminit>:
{
    80001244:	1141                	addi	sp,sp,-16
    80001246:	e406                	sd	ra,8(sp)
    80001248:	e022                	sd	s0,0(sp)
    8000124a:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000124c:	00000097          	auipc	ra,0x0
    80001250:	f22080e7          	jalr	-222(ra) # 8000116e <kvmmake>
    80001254:	00007797          	auipc	a5,0x7
    80001258:	6aa7b623          	sd	a0,1708(a5) # 80008900 <kernel_pagetable>
}
    8000125c:	60a2                	ld	ra,8(sp)
    8000125e:	6402                	ld	s0,0(sp)
    80001260:	0141                	addi	sp,sp,16
    80001262:	8082                	ret

0000000080001264 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001264:	715d                	addi	sp,sp,-80
    80001266:	e486                	sd	ra,72(sp)
    80001268:	e0a2                	sd	s0,64(sp)
    8000126a:	fc26                	sd	s1,56(sp)
    8000126c:	f84a                	sd	s2,48(sp)
    8000126e:	f44e                	sd	s3,40(sp)
    80001270:	f052                	sd	s4,32(sp)
    80001272:	ec56                	sd	s5,24(sp)
    80001274:	e85a                	sd	s6,16(sp)
    80001276:	e45e                	sd	s7,8(sp)
    80001278:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000127a:	03459793          	slli	a5,a1,0x34
    8000127e:	e795                	bnez	a5,800012aa <uvmunmap+0x46>
    80001280:	8a2a                	mv	s4,a0
    80001282:	892e                	mv	s2,a1
    80001284:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001286:	0632                	slli	a2,a2,0xc
    80001288:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000128c:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000128e:	6b05                	lui	s6,0x1
    80001290:	0735e263          	bltu	a1,s3,800012f4 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001294:	60a6                	ld	ra,72(sp)
    80001296:	6406                	ld	s0,64(sp)
    80001298:	74e2                	ld	s1,56(sp)
    8000129a:	7942                	ld	s2,48(sp)
    8000129c:	79a2                	ld	s3,40(sp)
    8000129e:	7a02                	ld	s4,32(sp)
    800012a0:	6ae2                	ld	s5,24(sp)
    800012a2:	6b42                	ld	s6,16(sp)
    800012a4:	6ba2                	ld	s7,8(sp)
    800012a6:	6161                	addi	sp,sp,80
    800012a8:	8082                	ret
    panic("uvmunmap: not aligned");
    800012aa:	00007517          	auipc	a0,0x7
    800012ae:	e5650513          	addi	a0,a0,-426 # 80008100 <digits+0xc0>
    800012b2:	fffff097          	auipc	ra,0xfffff
    800012b6:	28c080e7          	jalr	652(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    800012ba:	00007517          	auipc	a0,0x7
    800012be:	e5e50513          	addi	a0,a0,-418 # 80008118 <digits+0xd8>
    800012c2:	fffff097          	auipc	ra,0xfffff
    800012c6:	27c080e7          	jalr	636(ra) # 8000053e <panic>
      panic("uvmunmap: not mapped");
    800012ca:	00007517          	auipc	a0,0x7
    800012ce:	e5e50513          	addi	a0,a0,-418 # 80008128 <digits+0xe8>
    800012d2:	fffff097          	auipc	ra,0xfffff
    800012d6:	26c080e7          	jalr	620(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    800012da:	00007517          	auipc	a0,0x7
    800012de:	e6650513          	addi	a0,a0,-410 # 80008140 <digits+0x100>
    800012e2:	fffff097          	auipc	ra,0xfffff
    800012e6:	25c080e7          	jalr	604(ra) # 8000053e <panic>
    *pte = 0;
    800012ea:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012ee:	995a                	add	s2,s2,s6
    800012f0:	fb3972e3          	bgeu	s2,s3,80001294 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012f4:	4601                	li	a2,0
    800012f6:	85ca                	mv	a1,s2
    800012f8:	8552                	mv	a0,s4
    800012fa:	00000097          	auipc	ra,0x0
    800012fe:	cbc080e7          	jalr	-836(ra) # 80000fb6 <walk>
    80001302:	84aa                	mv	s1,a0
    80001304:	d95d                	beqz	a0,800012ba <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001306:	6108                	ld	a0,0(a0)
    80001308:	00157793          	andi	a5,a0,1
    8000130c:	dfdd                	beqz	a5,800012ca <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000130e:	3ff57793          	andi	a5,a0,1023
    80001312:	fd7784e3          	beq	a5,s7,800012da <uvmunmap+0x76>
    if(do_free){
    80001316:	fc0a8ae3          	beqz	s5,800012ea <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    8000131a:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    8000131c:	0532                	slli	a0,a0,0xc
    8000131e:	fffff097          	auipc	ra,0xfffff
    80001322:	6cc080e7          	jalr	1740(ra) # 800009ea <kfree>
    80001326:	b7d1                	j	800012ea <uvmunmap+0x86>

0000000080001328 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001328:	1101                	addi	sp,sp,-32
    8000132a:	ec06                	sd	ra,24(sp)
    8000132c:	e822                	sd	s0,16(sp)
    8000132e:	e426                	sd	s1,8(sp)
    80001330:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001332:	fffff097          	auipc	ra,0xfffff
    80001336:	7b4080e7          	jalr	1972(ra) # 80000ae6 <kalloc>
    8000133a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000133c:	c519                	beqz	a0,8000134a <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000133e:	6605                	lui	a2,0x1
    80001340:	4581                	li	a1,0
    80001342:	00000097          	auipc	ra,0x0
    80001346:	990080e7          	jalr	-1648(ra) # 80000cd2 <memset>
  return pagetable;
}
    8000134a:	8526                	mv	a0,s1
    8000134c:	60e2                	ld	ra,24(sp)
    8000134e:	6442                	ld	s0,16(sp)
    80001350:	64a2                	ld	s1,8(sp)
    80001352:	6105                	addi	sp,sp,32
    80001354:	8082                	ret

0000000080001356 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001356:	7179                	addi	sp,sp,-48
    80001358:	f406                	sd	ra,40(sp)
    8000135a:	f022                	sd	s0,32(sp)
    8000135c:	ec26                	sd	s1,24(sp)
    8000135e:	e84a                	sd	s2,16(sp)
    80001360:	e44e                	sd	s3,8(sp)
    80001362:	e052                	sd	s4,0(sp)
    80001364:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001366:	6785                	lui	a5,0x1
    80001368:	04f67863          	bgeu	a2,a5,800013b8 <uvmfirst+0x62>
    8000136c:	8a2a                	mv	s4,a0
    8000136e:	89ae                	mv	s3,a1
    80001370:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    80001372:	fffff097          	auipc	ra,0xfffff
    80001376:	774080e7          	jalr	1908(ra) # 80000ae6 <kalloc>
    8000137a:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000137c:	6605                	lui	a2,0x1
    8000137e:	4581                	li	a1,0
    80001380:	00000097          	auipc	ra,0x0
    80001384:	952080e7          	jalr	-1710(ra) # 80000cd2 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001388:	4779                	li	a4,30
    8000138a:	86ca                	mv	a3,s2
    8000138c:	6605                	lui	a2,0x1
    8000138e:	4581                	li	a1,0
    80001390:	8552                	mv	a0,s4
    80001392:	00000097          	auipc	ra,0x0
    80001396:	d0c080e7          	jalr	-756(ra) # 8000109e <mappages>
  memmove(mem, src, sz);
    8000139a:	8626                	mv	a2,s1
    8000139c:	85ce                	mv	a1,s3
    8000139e:	854a                	mv	a0,s2
    800013a0:	00000097          	auipc	ra,0x0
    800013a4:	98e080e7          	jalr	-1650(ra) # 80000d2e <memmove>
}
    800013a8:	70a2                	ld	ra,40(sp)
    800013aa:	7402                	ld	s0,32(sp)
    800013ac:	64e2                	ld	s1,24(sp)
    800013ae:	6942                	ld	s2,16(sp)
    800013b0:	69a2                	ld	s3,8(sp)
    800013b2:	6a02                	ld	s4,0(sp)
    800013b4:	6145                	addi	sp,sp,48
    800013b6:	8082                	ret
    panic("uvmfirst: more than a page");
    800013b8:	00007517          	auipc	a0,0x7
    800013bc:	da050513          	addi	a0,a0,-608 # 80008158 <digits+0x118>
    800013c0:	fffff097          	auipc	ra,0xfffff
    800013c4:	17e080e7          	jalr	382(ra) # 8000053e <panic>

00000000800013c8 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013c8:	1101                	addi	sp,sp,-32
    800013ca:	ec06                	sd	ra,24(sp)
    800013cc:	e822                	sd	s0,16(sp)
    800013ce:	e426                	sd	s1,8(sp)
    800013d0:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013d2:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013d4:	00b67d63          	bgeu	a2,a1,800013ee <uvmdealloc+0x26>
    800013d8:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013da:	6785                	lui	a5,0x1
    800013dc:	17fd                	addi	a5,a5,-1
    800013de:	00f60733          	add	a4,a2,a5
    800013e2:	767d                	lui	a2,0xfffff
    800013e4:	8f71                	and	a4,a4,a2
    800013e6:	97ae                	add	a5,a5,a1
    800013e8:	8ff1                	and	a5,a5,a2
    800013ea:	00f76863          	bltu	a4,a5,800013fa <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013ee:	8526                	mv	a0,s1
    800013f0:	60e2                	ld	ra,24(sp)
    800013f2:	6442                	ld	s0,16(sp)
    800013f4:	64a2                	ld	s1,8(sp)
    800013f6:	6105                	addi	sp,sp,32
    800013f8:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013fa:	8f99                	sub	a5,a5,a4
    800013fc:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013fe:	4685                	li	a3,1
    80001400:	0007861b          	sext.w	a2,a5
    80001404:	85ba                	mv	a1,a4
    80001406:	00000097          	auipc	ra,0x0
    8000140a:	e5e080e7          	jalr	-418(ra) # 80001264 <uvmunmap>
    8000140e:	b7c5                	j	800013ee <uvmdealloc+0x26>

0000000080001410 <uvmalloc>:
  if(newsz < oldsz)
    80001410:	0ab66563          	bltu	a2,a1,800014ba <uvmalloc+0xaa>
{
    80001414:	7139                	addi	sp,sp,-64
    80001416:	fc06                	sd	ra,56(sp)
    80001418:	f822                	sd	s0,48(sp)
    8000141a:	f426                	sd	s1,40(sp)
    8000141c:	f04a                	sd	s2,32(sp)
    8000141e:	ec4e                	sd	s3,24(sp)
    80001420:	e852                	sd	s4,16(sp)
    80001422:	e456                	sd	s5,8(sp)
    80001424:	e05a                	sd	s6,0(sp)
    80001426:	0080                	addi	s0,sp,64
    80001428:	8aaa                	mv	s5,a0
    8000142a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000142c:	6985                	lui	s3,0x1
    8000142e:	19fd                	addi	s3,s3,-1
    80001430:	95ce                	add	a1,a1,s3
    80001432:	79fd                	lui	s3,0xfffff
    80001434:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001438:	08c9f363          	bgeu	s3,a2,800014be <uvmalloc+0xae>
    8000143c:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000143e:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    80001442:	fffff097          	auipc	ra,0xfffff
    80001446:	6a4080e7          	jalr	1700(ra) # 80000ae6 <kalloc>
    8000144a:	84aa                	mv	s1,a0
    if(mem == 0){
    8000144c:	c51d                	beqz	a0,8000147a <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    8000144e:	6605                	lui	a2,0x1
    80001450:	4581                	li	a1,0
    80001452:	00000097          	auipc	ra,0x0
    80001456:	880080e7          	jalr	-1920(ra) # 80000cd2 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000145a:	875a                	mv	a4,s6
    8000145c:	86a6                	mv	a3,s1
    8000145e:	6605                	lui	a2,0x1
    80001460:	85ca                	mv	a1,s2
    80001462:	8556                	mv	a0,s5
    80001464:	00000097          	auipc	ra,0x0
    80001468:	c3a080e7          	jalr	-966(ra) # 8000109e <mappages>
    8000146c:	e90d                	bnez	a0,8000149e <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000146e:	6785                	lui	a5,0x1
    80001470:	993e                	add	s2,s2,a5
    80001472:	fd4968e3          	bltu	s2,s4,80001442 <uvmalloc+0x32>
  return newsz;
    80001476:	8552                	mv	a0,s4
    80001478:	a809                	j	8000148a <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    8000147a:	864e                	mv	a2,s3
    8000147c:	85ca                	mv	a1,s2
    8000147e:	8556                	mv	a0,s5
    80001480:	00000097          	auipc	ra,0x0
    80001484:	f48080e7          	jalr	-184(ra) # 800013c8 <uvmdealloc>
      return 0;
    80001488:	4501                	li	a0,0
}
    8000148a:	70e2                	ld	ra,56(sp)
    8000148c:	7442                	ld	s0,48(sp)
    8000148e:	74a2                	ld	s1,40(sp)
    80001490:	7902                	ld	s2,32(sp)
    80001492:	69e2                	ld	s3,24(sp)
    80001494:	6a42                	ld	s4,16(sp)
    80001496:	6aa2                	ld	s5,8(sp)
    80001498:	6b02                	ld	s6,0(sp)
    8000149a:	6121                	addi	sp,sp,64
    8000149c:	8082                	ret
      kfree(mem);
    8000149e:	8526                	mv	a0,s1
    800014a0:	fffff097          	auipc	ra,0xfffff
    800014a4:	54a080e7          	jalr	1354(ra) # 800009ea <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014a8:	864e                	mv	a2,s3
    800014aa:	85ca                	mv	a1,s2
    800014ac:	8556                	mv	a0,s5
    800014ae:	00000097          	auipc	ra,0x0
    800014b2:	f1a080e7          	jalr	-230(ra) # 800013c8 <uvmdealloc>
      return 0;
    800014b6:	4501                	li	a0,0
    800014b8:	bfc9                	j	8000148a <uvmalloc+0x7a>
    return oldsz;
    800014ba:	852e                	mv	a0,a1
}
    800014bc:	8082                	ret
  return newsz;
    800014be:	8532                	mv	a0,a2
    800014c0:	b7e9                	j	8000148a <uvmalloc+0x7a>

00000000800014c2 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014c2:	7179                	addi	sp,sp,-48
    800014c4:	f406                	sd	ra,40(sp)
    800014c6:	f022                	sd	s0,32(sp)
    800014c8:	ec26                	sd	s1,24(sp)
    800014ca:	e84a                	sd	s2,16(sp)
    800014cc:	e44e                	sd	s3,8(sp)
    800014ce:	e052                	sd	s4,0(sp)
    800014d0:	1800                	addi	s0,sp,48
    800014d2:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014d4:	84aa                	mv	s1,a0
    800014d6:	6905                	lui	s2,0x1
    800014d8:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014da:	4985                	li	s3,1
    800014dc:	a821                	j	800014f4 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014de:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800014e0:	0532                	slli	a0,a0,0xc
    800014e2:	00000097          	auipc	ra,0x0
    800014e6:	fe0080e7          	jalr	-32(ra) # 800014c2 <freewalk>
      pagetable[i] = 0;
    800014ea:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014ee:	04a1                	addi	s1,s1,8
    800014f0:	03248163          	beq	s1,s2,80001512 <freewalk+0x50>
    pte_t pte = pagetable[i];
    800014f4:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014f6:	00f57793          	andi	a5,a0,15
    800014fa:	ff3782e3          	beq	a5,s3,800014de <freewalk+0x1c>
    } else if(pte & PTE_V){
    800014fe:	8905                	andi	a0,a0,1
    80001500:	d57d                	beqz	a0,800014ee <freewalk+0x2c>
      panic("freewalk: leaf");
    80001502:	00007517          	auipc	a0,0x7
    80001506:	c7650513          	addi	a0,a0,-906 # 80008178 <digits+0x138>
    8000150a:	fffff097          	auipc	ra,0xfffff
    8000150e:	034080e7          	jalr	52(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    80001512:	8552                	mv	a0,s4
    80001514:	fffff097          	auipc	ra,0xfffff
    80001518:	4d6080e7          	jalr	1238(ra) # 800009ea <kfree>
}
    8000151c:	70a2                	ld	ra,40(sp)
    8000151e:	7402                	ld	s0,32(sp)
    80001520:	64e2                	ld	s1,24(sp)
    80001522:	6942                	ld	s2,16(sp)
    80001524:	69a2                	ld	s3,8(sp)
    80001526:	6a02                	ld	s4,0(sp)
    80001528:	6145                	addi	sp,sp,48
    8000152a:	8082                	ret

000000008000152c <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000152c:	1101                	addi	sp,sp,-32
    8000152e:	ec06                	sd	ra,24(sp)
    80001530:	e822                	sd	s0,16(sp)
    80001532:	e426                	sd	s1,8(sp)
    80001534:	1000                	addi	s0,sp,32
    80001536:	84aa                	mv	s1,a0
  if(sz > 0)
    80001538:	e999                	bnez	a1,8000154e <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000153a:	8526                	mv	a0,s1
    8000153c:	00000097          	auipc	ra,0x0
    80001540:	f86080e7          	jalr	-122(ra) # 800014c2 <freewalk>
}
    80001544:	60e2                	ld	ra,24(sp)
    80001546:	6442                	ld	s0,16(sp)
    80001548:	64a2                	ld	s1,8(sp)
    8000154a:	6105                	addi	sp,sp,32
    8000154c:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000154e:	6605                	lui	a2,0x1
    80001550:	167d                	addi	a2,a2,-1
    80001552:	962e                	add	a2,a2,a1
    80001554:	4685                	li	a3,1
    80001556:	8231                	srli	a2,a2,0xc
    80001558:	4581                	li	a1,0
    8000155a:	00000097          	auipc	ra,0x0
    8000155e:	d0a080e7          	jalr	-758(ra) # 80001264 <uvmunmap>
    80001562:	bfe1                	j	8000153a <uvmfree+0xe>

0000000080001564 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001564:	c679                	beqz	a2,80001632 <uvmcopy+0xce>
{
    80001566:	715d                	addi	sp,sp,-80
    80001568:	e486                	sd	ra,72(sp)
    8000156a:	e0a2                	sd	s0,64(sp)
    8000156c:	fc26                	sd	s1,56(sp)
    8000156e:	f84a                	sd	s2,48(sp)
    80001570:	f44e                	sd	s3,40(sp)
    80001572:	f052                	sd	s4,32(sp)
    80001574:	ec56                	sd	s5,24(sp)
    80001576:	e85a                	sd	s6,16(sp)
    80001578:	e45e                	sd	s7,8(sp)
    8000157a:	0880                	addi	s0,sp,80
    8000157c:	8b2a                	mv	s6,a0
    8000157e:	8aae                	mv	s5,a1
    80001580:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001582:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001584:	4601                	li	a2,0
    80001586:	85ce                	mv	a1,s3
    80001588:	855a                	mv	a0,s6
    8000158a:	00000097          	auipc	ra,0x0
    8000158e:	a2c080e7          	jalr	-1492(ra) # 80000fb6 <walk>
    80001592:	c531                	beqz	a0,800015de <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001594:	6118                	ld	a4,0(a0)
    80001596:	00177793          	andi	a5,a4,1
    8000159a:	cbb1                	beqz	a5,800015ee <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    8000159c:	00a75593          	srli	a1,a4,0xa
    800015a0:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015a4:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015a8:	fffff097          	auipc	ra,0xfffff
    800015ac:	53e080e7          	jalr	1342(ra) # 80000ae6 <kalloc>
    800015b0:	892a                	mv	s2,a0
    800015b2:	c939                	beqz	a0,80001608 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015b4:	6605                	lui	a2,0x1
    800015b6:	85de                	mv	a1,s7
    800015b8:	fffff097          	auipc	ra,0xfffff
    800015bc:	776080e7          	jalr	1910(ra) # 80000d2e <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015c0:	8726                	mv	a4,s1
    800015c2:	86ca                	mv	a3,s2
    800015c4:	6605                	lui	a2,0x1
    800015c6:	85ce                	mv	a1,s3
    800015c8:	8556                	mv	a0,s5
    800015ca:	00000097          	auipc	ra,0x0
    800015ce:	ad4080e7          	jalr	-1324(ra) # 8000109e <mappages>
    800015d2:	e515                	bnez	a0,800015fe <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015d4:	6785                	lui	a5,0x1
    800015d6:	99be                	add	s3,s3,a5
    800015d8:	fb49e6e3          	bltu	s3,s4,80001584 <uvmcopy+0x20>
    800015dc:	a081                	j	8000161c <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015de:	00007517          	auipc	a0,0x7
    800015e2:	baa50513          	addi	a0,a0,-1110 # 80008188 <digits+0x148>
    800015e6:	fffff097          	auipc	ra,0xfffff
    800015ea:	f58080e7          	jalr	-168(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    800015ee:	00007517          	auipc	a0,0x7
    800015f2:	bba50513          	addi	a0,a0,-1094 # 800081a8 <digits+0x168>
    800015f6:	fffff097          	auipc	ra,0xfffff
    800015fa:	f48080e7          	jalr	-184(ra) # 8000053e <panic>
      kfree(mem);
    800015fe:	854a                	mv	a0,s2
    80001600:	fffff097          	auipc	ra,0xfffff
    80001604:	3ea080e7          	jalr	1002(ra) # 800009ea <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001608:	4685                	li	a3,1
    8000160a:	00c9d613          	srli	a2,s3,0xc
    8000160e:	4581                	li	a1,0
    80001610:	8556                	mv	a0,s5
    80001612:	00000097          	auipc	ra,0x0
    80001616:	c52080e7          	jalr	-942(ra) # 80001264 <uvmunmap>
  return -1;
    8000161a:	557d                	li	a0,-1
}
    8000161c:	60a6                	ld	ra,72(sp)
    8000161e:	6406                	ld	s0,64(sp)
    80001620:	74e2                	ld	s1,56(sp)
    80001622:	7942                	ld	s2,48(sp)
    80001624:	79a2                	ld	s3,40(sp)
    80001626:	7a02                	ld	s4,32(sp)
    80001628:	6ae2                	ld	s5,24(sp)
    8000162a:	6b42                	ld	s6,16(sp)
    8000162c:	6ba2                	ld	s7,8(sp)
    8000162e:	6161                	addi	sp,sp,80
    80001630:	8082                	ret
  return 0;
    80001632:	4501                	li	a0,0
}
    80001634:	8082                	ret

0000000080001636 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001636:	1141                	addi	sp,sp,-16
    80001638:	e406                	sd	ra,8(sp)
    8000163a:	e022                	sd	s0,0(sp)
    8000163c:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000163e:	4601                	li	a2,0
    80001640:	00000097          	auipc	ra,0x0
    80001644:	976080e7          	jalr	-1674(ra) # 80000fb6 <walk>
  if(pte == 0)
    80001648:	c901                	beqz	a0,80001658 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000164a:	611c                	ld	a5,0(a0)
    8000164c:	9bbd                	andi	a5,a5,-17
    8000164e:	e11c                	sd	a5,0(a0)
}
    80001650:	60a2                	ld	ra,8(sp)
    80001652:	6402                	ld	s0,0(sp)
    80001654:	0141                	addi	sp,sp,16
    80001656:	8082                	ret
    panic("uvmclear");
    80001658:	00007517          	auipc	a0,0x7
    8000165c:	b7050513          	addi	a0,a0,-1168 # 800081c8 <digits+0x188>
    80001660:	fffff097          	auipc	ra,0xfffff
    80001664:	ede080e7          	jalr	-290(ra) # 8000053e <panic>

0000000080001668 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001668:	c6bd                	beqz	a3,800016d6 <copyout+0x6e>
{
    8000166a:	715d                	addi	sp,sp,-80
    8000166c:	e486                	sd	ra,72(sp)
    8000166e:	e0a2                	sd	s0,64(sp)
    80001670:	fc26                	sd	s1,56(sp)
    80001672:	f84a                	sd	s2,48(sp)
    80001674:	f44e                	sd	s3,40(sp)
    80001676:	f052                	sd	s4,32(sp)
    80001678:	ec56                	sd	s5,24(sp)
    8000167a:	e85a                	sd	s6,16(sp)
    8000167c:	e45e                	sd	s7,8(sp)
    8000167e:	e062                	sd	s8,0(sp)
    80001680:	0880                	addi	s0,sp,80
    80001682:	8b2a                	mv	s6,a0
    80001684:	8c2e                	mv	s8,a1
    80001686:	8a32                	mv	s4,a2
    80001688:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000168a:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    8000168c:	6a85                	lui	s5,0x1
    8000168e:	a015                	j	800016b2 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001690:	9562                	add	a0,a0,s8
    80001692:	0004861b          	sext.w	a2,s1
    80001696:	85d2                	mv	a1,s4
    80001698:	41250533          	sub	a0,a0,s2
    8000169c:	fffff097          	auipc	ra,0xfffff
    800016a0:	692080e7          	jalr	1682(ra) # 80000d2e <memmove>

    len -= n;
    800016a4:	409989b3          	sub	s3,s3,s1
    src += n;
    800016a8:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016aa:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016ae:	02098263          	beqz	s3,800016d2 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016b2:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016b6:	85ca                	mv	a1,s2
    800016b8:	855a                	mv	a0,s6
    800016ba:	00000097          	auipc	ra,0x0
    800016be:	9a2080e7          	jalr	-1630(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800016c2:	cd01                	beqz	a0,800016da <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016c4:	418904b3          	sub	s1,s2,s8
    800016c8:	94d6                	add	s1,s1,s5
    if(n > len)
    800016ca:	fc99f3e3          	bgeu	s3,s1,80001690 <copyout+0x28>
    800016ce:	84ce                	mv	s1,s3
    800016d0:	b7c1                	j	80001690 <copyout+0x28>
  }
  return 0;
    800016d2:	4501                	li	a0,0
    800016d4:	a021                	j	800016dc <copyout+0x74>
    800016d6:	4501                	li	a0,0
}
    800016d8:	8082                	ret
      return -1;
    800016da:	557d                	li	a0,-1
}
    800016dc:	60a6                	ld	ra,72(sp)
    800016de:	6406                	ld	s0,64(sp)
    800016e0:	74e2                	ld	s1,56(sp)
    800016e2:	7942                	ld	s2,48(sp)
    800016e4:	79a2                	ld	s3,40(sp)
    800016e6:	7a02                	ld	s4,32(sp)
    800016e8:	6ae2                	ld	s5,24(sp)
    800016ea:	6b42                	ld	s6,16(sp)
    800016ec:	6ba2                	ld	s7,8(sp)
    800016ee:	6c02                	ld	s8,0(sp)
    800016f0:	6161                	addi	sp,sp,80
    800016f2:	8082                	ret

00000000800016f4 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016f4:	caa5                	beqz	a3,80001764 <copyin+0x70>
{
    800016f6:	715d                	addi	sp,sp,-80
    800016f8:	e486                	sd	ra,72(sp)
    800016fa:	e0a2                	sd	s0,64(sp)
    800016fc:	fc26                	sd	s1,56(sp)
    800016fe:	f84a                	sd	s2,48(sp)
    80001700:	f44e                	sd	s3,40(sp)
    80001702:	f052                	sd	s4,32(sp)
    80001704:	ec56                	sd	s5,24(sp)
    80001706:	e85a                	sd	s6,16(sp)
    80001708:	e45e                	sd	s7,8(sp)
    8000170a:	e062                	sd	s8,0(sp)
    8000170c:	0880                	addi	s0,sp,80
    8000170e:	8b2a                	mv	s6,a0
    80001710:	8a2e                	mv	s4,a1
    80001712:	8c32                	mv	s8,a2
    80001714:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001716:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001718:	6a85                	lui	s5,0x1
    8000171a:	a01d                	j	80001740 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000171c:	018505b3          	add	a1,a0,s8
    80001720:	0004861b          	sext.w	a2,s1
    80001724:	412585b3          	sub	a1,a1,s2
    80001728:	8552                	mv	a0,s4
    8000172a:	fffff097          	auipc	ra,0xfffff
    8000172e:	604080e7          	jalr	1540(ra) # 80000d2e <memmove>

    len -= n;
    80001732:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001736:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001738:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000173c:	02098263          	beqz	s3,80001760 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001740:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001744:	85ca                	mv	a1,s2
    80001746:	855a                	mv	a0,s6
    80001748:	00000097          	auipc	ra,0x0
    8000174c:	914080e7          	jalr	-1772(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    80001750:	cd01                	beqz	a0,80001768 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001752:	418904b3          	sub	s1,s2,s8
    80001756:	94d6                	add	s1,s1,s5
    if(n > len)
    80001758:	fc99f2e3          	bgeu	s3,s1,8000171c <copyin+0x28>
    8000175c:	84ce                	mv	s1,s3
    8000175e:	bf7d                	j	8000171c <copyin+0x28>
  }
  return 0;
    80001760:	4501                	li	a0,0
    80001762:	a021                	j	8000176a <copyin+0x76>
    80001764:	4501                	li	a0,0
}
    80001766:	8082                	ret
      return -1;
    80001768:	557d                	li	a0,-1
}
    8000176a:	60a6                	ld	ra,72(sp)
    8000176c:	6406                	ld	s0,64(sp)
    8000176e:	74e2                	ld	s1,56(sp)
    80001770:	7942                	ld	s2,48(sp)
    80001772:	79a2                	ld	s3,40(sp)
    80001774:	7a02                	ld	s4,32(sp)
    80001776:	6ae2                	ld	s5,24(sp)
    80001778:	6b42                	ld	s6,16(sp)
    8000177a:	6ba2                	ld	s7,8(sp)
    8000177c:	6c02                	ld	s8,0(sp)
    8000177e:	6161                	addi	sp,sp,80
    80001780:	8082                	ret

0000000080001782 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001782:	c6c5                	beqz	a3,8000182a <copyinstr+0xa8>
{
    80001784:	715d                	addi	sp,sp,-80
    80001786:	e486                	sd	ra,72(sp)
    80001788:	e0a2                	sd	s0,64(sp)
    8000178a:	fc26                	sd	s1,56(sp)
    8000178c:	f84a                	sd	s2,48(sp)
    8000178e:	f44e                	sd	s3,40(sp)
    80001790:	f052                	sd	s4,32(sp)
    80001792:	ec56                	sd	s5,24(sp)
    80001794:	e85a                	sd	s6,16(sp)
    80001796:	e45e                	sd	s7,8(sp)
    80001798:	0880                	addi	s0,sp,80
    8000179a:	8a2a                	mv	s4,a0
    8000179c:	8b2e                	mv	s6,a1
    8000179e:	8bb2                	mv	s7,a2
    800017a0:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017a2:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017a4:	6985                	lui	s3,0x1
    800017a6:	a035                	j	800017d2 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017a8:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017ac:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017ae:	0017b793          	seqz	a5,a5
    800017b2:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017b6:	60a6                	ld	ra,72(sp)
    800017b8:	6406                	ld	s0,64(sp)
    800017ba:	74e2                	ld	s1,56(sp)
    800017bc:	7942                	ld	s2,48(sp)
    800017be:	79a2                	ld	s3,40(sp)
    800017c0:	7a02                	ld	s4,32(sp)
    800017c2:	6ae2                	ld	s5,24(sp)
    800017c4:	6b42                	ld	s6,16(sp)
    800017c6:	6ba2                	ld	s7,8(sp)
    800017c8:	6161                	addi	sp,sp,80
    800017ca:	8082                	ret
    srcva = va0 + PGSIZE;
    800017cc:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d0:	c8a9                	beqz	s1,80001822 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017d2:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017d6:	85ca                	mv	a1,s2
    800017d8:	8552                	mv	a0,s4
    800017da:	00000097          	auipc	ra,0x0
    800017de:	882080e7          	jalr	-1918(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800017e2:	c131                	beqz	a0,80001826 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017e4:	41790833          	sub	a6,s2,s7
    800017e8:	984e                	add	a6,a6,s3
    if(n > max)
    800017ea:	0104f363          	bgeu	s1,a6,800017f0 <copyinstr+0x6e>
    800017ee:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f0:	955e                	add	a0,a0,s7
    800017f2:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017f6:	fc080be3          	beqz	a6,800017cc <copyinstr+0x4a>
    800017fa:	985a                	add	a6,a6,s6
    800017fc:	87da                	mv	a5,s6
      if(*p == '\0'){
    800017fe:	41650633          	sub	a2,a0,s6
    80001802:	14fd                	addi	s1,s1,-1
    80001804:	9b26                	add	s6,s6,s1
    80001806:	00f60733          	add	a4,a2,a5
    8000180a:	00074703          	lbu	a4,0(a4)
    8000180e:	df49                	beqz	a4,800017a8 <copyinstr+0x26>
        *dst = *p;
    80001810:	00e78023          	sb	a4,0(a5)
      --max;
    80001814:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001818:	0785                	addi	a5,a5,1
    while(n > 0){
    8000181a:	ff0796e3          	bne	a5,a6,80001806 <copyinstr+0x84>
      dst++;
    8000181e:	8b42                	mv	s6,a6
    80001820:	b775                	j	800017cc <copyinstr+0x4a>
    80001822:	4781                	li	a5,0
    80001824:	b769                	j	800017ae <copyinstr+0x2c>
      return -1;
    80001826:	557d                	li	a0,-1
    80001828:	b779                	j	800017b6 <copyinstr+0x34>
  int got_null = 0;
    8000182a:	4781                	li	a5,0
  if(got_null){
    8000182c:	0017b793          	seqz	a5,a5
    80001830:	40f00533          	neg	a0,a5
}
    80001834:	8082                	ret

0000000080001836 <lcg_random>:

unsigned int seed = 2139124; // Automatic seed generation

// Function to generate a pseudo-random number
unsigned int lcg_random()
{
    80001836:	1141                	addi	sp,sp,-16
    80001838:	e422                	sd	s0,8(sp)
    8000183a:	0800                	addi	s0,sp,16
  // if (seed == 0)
  // {
  //   // seed = (unsigned int)r_time(0); // Automatically initialize the seed with the current time
  // }
  seed = (A * seed + C) % M;
    8000183c:	00007717          	auipc	a4,0x7
    80001840:	04870713          	addi	a4,a4,72 # 80008884 <seed>
    80001844:	4308                	lw	a0,0(a4)
    80001846:	6336a7b7          	lui	a5,0x6336a
    8000184a:	39d7879b          	addiw	a5,a5,925
    8000184e:	02f5053b          	mulw	a0,a0,a5
    80001852:	3c6ef7b7          	lui	a5,0x3c6ef
    80001856:	35f7879b          	addiw	a5,a5,863
    8000185a:	9d3d                	addw	a0,a0,a5
    8000185c:	c308                	sw	a0,0(a4)
  return seed;
}
    8000185e:	2501                	sext.w	a0,a0
    80001860:	6422                	ld	s0,8(sp)
    80001862:	0141                	addi	sp,sp,16
    80001864:	8082                	ret

0000000080001866 <proc_mapstacks>:

void proc_mapstacks(pagetable_t kpgtbl)
{
    80001866:	7139                	addi	sp,sp,-64
    80001868:	fc06                	sd	ra,56(sp)
    8000186a:	f822                	sd	s0,48(sp)
    8000186c:	f426                	sd	s1,40(sp)
    8000186e:	f04a                	sd	s2,32(sp)
    80001870:	ec4e                	sd	s3,24(sp)
    80001872:	e852                	sd	s4,16(sp)
    80001874:	e456                	sd	s5,8(sp)
    80001876:	e05a                	sd	s6,0(sp)
    80001878:	0080                	addi	s0,sp,64
    8000187a:	89aa                	mv	s3,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    8000187c:	00010497          	auipc	s1,0x10
    80001880:	f4448493          	addi	s1,s1,-188 # 800117c0 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    80001884:	8b26                	mv	s6,s1
    80001886:	00006a97          	auipc	s5,0x6
    8000188a:	77aa8a93          	addi	s5,s5,1914 # 80008000 <etext>
    8000188e:	04000937          	lui	s2,0x4000
    80001892:	197d                	addi	s2,s2,-1
    80001894:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001896:	00018a17          	auipc	s4,0x18
    8000189a:	52aa0a13          	addi	s4,s4,1322 # 80019dc0 <tickslock>
    char *pa = kalloc();
    8000189e:	fffff097          	auipc	ra,0xfffff
    800018a2:	248080e7          	jalr	584(ra) # 80000ae6 <kalloc>
    800018a6:	862a                	mv	a2,a0
    if (pa == 0)
    800018a8:	c131                	beqz	a0,800018ec <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    800018aa:	416485b3          	sub	a1,s1,s6
    800018ae:	858d                	srai	a1,a1,0x3
    800018b0:	000ab783          	ld	a5,0(s5)
    800018b4:	02f585b3          	mul	a1,a1,a5
    800018b8:	2585                	addiw	a1,a1,1
    800018ba:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800018be:	4719                	li	a4,6
    800018c0:	6685                	lui	a3,0x1
    800018c2:	40b905b3          	sub	a1,s2,a1
    800018c6:	854e                	mv	a0,s3
    800018c8:	00000097          	auipc	ra,0x0
    800018cc:	876080e7          	jalr	-1930(ra) # 8000113e <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    800018d0:	21848493          	addi	s1,s1,536
    800018d4:	fd4495e3          	bne	s1,s4,8000189e <proc_mapstacks+0x38>
  }
}
    800018d8:	70e2                	ld	ra,56(sp)
    800018da:	7442                	ld	s0,48(sp)
    800018dc:	74a2                	ld	s1,40(sp)
    800018de:	7902                	ld	s2,32(sp)
    800018e0:	69e2                	ld	s3,24(sp)
    800018e2:	6a42                	ld	s4,16(sp)
    800018e4:	6aa2                	ld	s5,8(sp)
    800018e6:	6b02                	ld	s6,0(sp)
    800018e8:	6121                	addi	sp,sp,64
    800018ea:	8082                	ret
      panic("kalloc");
    800018ec:	00007517          	auipc	a0,0x7
    800018f0:	8ec50513          	addi	a0,a0,-1812 # 800081d8 <digits+0x198>
    800018f4:	fffff097          	auipc	ra,0xfffff
    800018f8:	c4a080e7          	jalr	-950(ra) # 8000053e <panic>

00000000800018fc <procinit>:

// initialize the proc table.
void procinit(void)
{
    800018fc:	7139                	addi	sp,sp,-64
    800018fe:	fc06                	sd	ra,56(sp)
    80001900:	f822                	sd	s0,48(sp)
    80001902:	f426                	sd	s1,40(sp)
    80001904:	f04a                	sd	s2,32(sp)
    80001906:	ec4e                	sd	s3,24(sp)
    80001908:	e852                	sd	s4,16(sp)
    8000190a:	e456                	sd	s5,8(sp)
    8000190c:	e05a                	sd	s6,0(sp)
    8000190e:	0080                	addi	s0,sp,64
  struct proc *p;

  initlock(&pid_lock, "nextpid");
    80001910:	00007597          	auipc	a1,0x7
    80001914:	8d058593          	addi	a1,a1,-1840 # 800081e0 <digits+0x1a0>
    80001918:	0000f517          	auipc	a0,0xf
    8000191c:	26850513          	addi	a0,a0,616 # 80010b80 <pid_lock>
    80001920:	fffff097          	auipc	ra,0xfffff
    80001924:	226080e7          	jalr	550(ra) # 80000b46 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001928:	00007597          	auipc	a1,0x7
    8000192c:	8c058593          	addi	a1,a1,-1856 # 800081e8 <digits+0x1a8>
    80001930:	0000f517          	auipc	a0,0xf
    80001934:	26850513          	addi	a0,a0,616 # 80010b98 <wait_lock>
    80001938:	fffff097          	auipc	ra,0xfffff
    8000193c:	20e080e7          	jalr	526(ra) # 80000b46 <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    80001940:	00010497          	auipc	s1,0x10
    80001944:	e8048493          	addi	s1,s1,-384 # 800117c0 <proc>
  {
    initlock(&p->lock, "proc");
    80001948:	00007b17          	auipc	s6,0x7
    8000194c:	8b0b0b13          	addi	s6,s6,-1872 # 800081f8 <digits+0x1b8>
    p->state = UNUSED;
    p->kstack = KSTACK((int)(p - proc));
    80001950:	8aa6                	mv	s5,s1
    80001952:	00006a17          	auipc	s4,0x6
    80001956:	6aea0a13          	addi	s4,s4,1710 # 80008000 <etext>
    8000195a:	04000937          	lui	s2,0x4000
    8000195e:	197d                	addi	s2,s2,-1
    80001960:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001962:	00018997          	auipc	s3,0x18
    80001966:	45e98993          	addi	s3,s3,1118 # 80019dc0 <tickslock>
    initlock(&p->lock, "proc");
    8000196a:	85da                	mv	a1,s6
    8000196c:	8526                	mv	a0,s1
    8000196e:	fffff097          	auipc	ra,0xfffff
    80001972:	1d8080e7          	jalr	472(ra) # 80000b46 <initlock>
    p->state = UNUSED;
    80001976:	0004ac23          	sw	zero,24(s1)
    p->kstack = KSTACK((int)(p - proc));
    8000197a:	415487b3          	sub	a5,s1,s5
    8000197e:	878d                	srai	a5,a5,0x3
    80001980:	000a3703          	ld	a4,0(s4)
    80001984:	02e787b3          	mul	a5,a5,a4
    80001988:	2785                	addiw	a5,a5,1
    8000198a:	00d7979b          	slliw	a5,a5,0xd
    8000198e:	40f907b3          	sub	a5,s2,a5
    80001992:	e0bc                	sd	a5,64(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    80001994:	21848493          	addi	s1,s1,536
    80001998:	fd3499e3          	bne	s1,s3,8000196a <procinit+0x6e>
  }
}
    8000199c:	70e2                	ld	ra,56(sp)
    8000199e:	7442                	ld	s0,48(sp)
    800019a0:	74a2                	ld	s1,40(sp)
    800019a2:	7902                	ld	s2,32(sp)
    800019a4:	69e2                	ld	s3,24(sp)
    800019a6:	6a42                	ld	s4,16(sp)
    800019a8:	6aa2                	ld	s5,8(sp)
    800019aa:	6b02                	ld	s6,0(sp)
    800019ac:	6121                	addi	sp,sp,64
    800019ae:	8082                	ret

00000000800019b0 <enqueue>:

void enqueue(struct proc* p)
{
  if(p->state != RUNNABLE)
    800019b0:	4d18                	lw	a4,24(a0)
    800019b2:	478d                	li	a5,3
    800019b4:	08f71163          	bne	a4,a5,80001a36 <enqueue+0x86>
  return;
  int priority = p->priority;
    800019b8:	20852603          	lw	a2,520(a0)

    // Check if the process is already in the queue
    for (int i = 0; i <NPROC ; i++) {
    800019bc:	00961713          	slli	a4,a2,0x9
    800019c0:	0000f797          	auipc	a5,0xf
    800019c4:	60078793          	addi	a5,a5,1536 # 80010fc0 <mlfq>
    800019c8:	97ba                	add	a5,a5,a4
    800019ca:	0000f697          	auipc	a3,0xf
    800019ce:	7f668693          	addi	a3,a3,2038 # 800111c0 <mlfq+0x200>
    800019d2:	96ba                	add	a3,a3,a4
        if (mlfq[priority][i] == p) {
    800019d4:	6398                	ld	a4,0(a5)
    800019d6:	06a70063          	beq	a4,a0,80001a36 <enqueue+0x86>
    for (int i = 0; i <NPROC ; i++) {
    800019da:	07a1                	addi	a5,a5,8
    800019dc:	fed79ce3          	bne	a5,a3,800019d4 <enqueue+0x24>
            return;  // Process is already in the queue, no need to add it again
        }
    }
     if (queue_sizes[priority] < NPROC) {
    800019e0:	00261713          	slli	a4,a2,0x2
    800019e4:	0000f797          	auipc	a5,0xf
    800019e8:	19c78793          	addi	a5,a5,412 # 80010b80 <pid_lock>
    800019ec:	97ba                	add	a5,a5,a4
    800019ee:	5b9c                	lw	a5,48(a5)
    800019f0:	03f00713          	li	a4,63
    800019f4:	02f74563          	blt	a4,a5,80001a1e <enqueue+0x6e>
        mlfq[priority][queue_sizes[priority]] = p;  // Add process at the end
    800019f8:	00661713          	slli	a4,a2,0x6
    800019fc:	973e                	add	a4,a4,a5
    800019fe:	070e                	slli	a4,a4,0x3
    80001a00:	0000f697          	auipc	a3,0xf
    80001a04:	5c068693          	addi	a3,a3,1472 # 80010fc0 <mlfq>
    80001a08:	9736                	add	a4,a4,a3
    80001a0a:	e308                	sd	a0,0(a4)
        queue_sizes[priority]++;  
    80001a0c:	060a                	slli	a2,a2,0x2
    80001a0e:	0000f717          	auipc	a4,0xf
    80001a12:	17270713          	addi	a4,a4,370 # 80010b80 <pid_lock>
    80001a16:	963a                	add	a2,a2,a4
    80001a18:	2785                	addiw	a5,a5,1
    80001a1a:	da1c                	sw	a5,48(a2)
        return;// Increment the size of the queue
    80001a1c:	8082                	ret
{
    80001a1e:	1141                	addi	sp,sp,-16
    80001a20:	e406                	sd	ra,8(sp)
    80001a22:	e022                	sd	s0,0(sp)
    80001a24:	0800                	addi	s0,sp,16
    } else {
        panic("Queue overflow");  // Handle overflow
    80001a26:	00006517          	auipc	a0,0x6
    80001a2a:	7da50513          	addi	a0,a0,2010 # 80008200 <digits+0x1c0>
    80001a2e:	fffff097          	auipc	ra,0xfffff
    80001a32:	b10080e7          	jalr	-1264(ra) # 8000053e <panic>
    80001a36:	8082                	ret

0000000080001a38 <dequeue>:
    }
}

void dequeue(struct proc* p)
{
    80001a38:	1141                	addi	sp,sp,-16
    80001a3a:	e422                	sd	s0,8(sp)
    80001a3c:	0800                	addi	s0,sp,16
   int priority = p->priority;
    80001a3e:	20852583          	lw	a1,520(a0)
  for(int i=0;i<queue_sizes[priority];i++)
    80001a42:	00259713          	slli	a4,a1,0x2
    80001a46:	0000f797          	auipc	a5,0xf
    80001a4a:	13a78793          	addi	a5,a5,314 # 80010b80 <pid_lock>
    80001a4e:	97ba                	add	a5,a5,a4
    80001a50:	5b90                	lw	a2,48(a5)
    80001a52:	08c05763          	blez	a2,80001ae0 <dequeue+0xa8>
    80001a56:	00959793          	slli	a5,a1,0x9
    80001a5a:	0000f717          	auipc	a4,0xf
    80001a5e:	56670713          	addi	a4,a4,1382 # 80010fc0 <mlfq>
    80001a62:	97ba                	add	a5,a5,a4
    80001a64:	4701                	li	a4,0
  {
    if(mlfq[priority][i]==p)
    80001a66:	6394                	ld	a3,0(a5)
    80001a68:	00a68763          	beq	a3,a0,80001a76 <dequeue+0x3e>
  for(int i=0;i<queue_sizes[priority];i++)
    80001a6c:	2705                	addiw	a4,a4,1
    80001a6e:	07a1                	addi	a5,a5,8
    80001a70:	fec71be3          	bne	a4,a2,80001a66 <dequeue+0x2e>
    80001a74:	a0b5                	j	80001ae0 <dequeue+0xa8>
    {
      //this bro found remove
      for(int j=i+1;j<queue_sizes[priority];j++)
    80001a76:	0017079b          	addiw	a5,a4,1
    80001a7a:	02c7de63          	bge	a5,a2,80001ab6 <dequeue+0x7e>
    80001a7e:	00659513          	slli	a0,a1,0x6
    80001a82:	953a                	add	a0,a0,a4
    80001a84:	00351793          	slli	a5,a0,0x3
    80001a88:	0000f697          	auipc	a3,0xf
    80001a8c:	53868693          	addi	a3,a3,1336 # 80010fc0 <mlfq>
    80001a90:	97b6                	add	a5,a5,a3
    80001a92:	ffe6069b          	addiw	a3,a2,-2
    80001a96:	40e6873b          	subw	a4,a3,a4
    80001a9a:	1702                	slli	a4,a4,0x20
    80001a9c:	9301                	srli	a4,a4,0x20
    80001a9e:	972a                	add	a4,a4,a0
    80001aa0:	070e                	slli	a4,a4,0x3
    80001aa2:	0000f697          	auipc	a3,0xf
    80001aa6:	52668693          	addi	a3,a3,1318 # 80010fc8 <mlfq+0x8>
    80001aaa:	9736                	add	a4,a4,a3
      {
        mlfq[priority][j-1]=mlfq[priority][j];
    80001aac:	6794                	ld	a3,8(a5)
    80001aae:	e394                	sd	a3,0(a5)
      for(int j=i+1;j<queue_sizes[priority];j++)
    80001ab0:	07a1                	addi	a5,a5,8
    80001ab2:	fee79de3          	bne	a5,a4,80001aac <dequeue+0x74>
      }
      mlfq[priority][queue_sizes[priority]-1]=0;
    80001ab6:	367d                	addiw	a2,a2,-1
    80001ab8:	0006071b          	sext.w	a4,a2
    80001abc:	00659793          	slli	a5,a1,0x6
    80001ac0:	97ba                	add	a5,a5,a4
    80001ac2:	078e                	slli	a5,a5,0x3
    80001ac4:	0000f717          	auipc	a4,0xf
    80001ac8:	4fc70713          	addi	a4,a4,1276 # 80010fc0 <mlfq>
    80001acc:	97ba                	add	a5,a5,a4
    80001ace:	0007b023          	sd	zero,0(a5)
      queue_sizes[priority]--;
    80001ad2:	058a                	slli	a1,a1,0x2
    80001ad4:	0000f797          	auipc	a5,0xf
    80001ad8:	0ac78793          	addi	a5,a5,172 # 80010b80 <pid_lock>
    80001adc:	95be                	add	a1,a1,a5
    80001ade:	d990                	sw	a2,48(a1)
      return;
    }
  }
}
    80001ae0:	6422                	ld	s0,8(sp)
    80001ae2:	0141                	addi	sp,sp,16
    80001ae4:	8082                	ret

0000000080001ae6 <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    80001ae6:	1141                	addi	sp,sp,-16
    80001ae8:	e422                	sd	s0,8(sp)
    80001aea:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001aec:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001aee:	2501                	sext.w	a0,a0
    80001af0:	6422                	ld	s0,8(sp)
    80001af2:	0141                	addi	sp,sp,16
    80001af4:	8082                	ret

0000000080001af6 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    80001af6:	1141                	addi	sp,sp,-16
    80001af8:	e422                	sd	s0,8(sp)
    80001afa:	0800                	addi	s0,sp,16
    80001afc:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001afe:	2781                	sext.w	a5,a5
    80001b00:	079e                	slli	a5,a5,0x7
  return c;
}
    80001b02:	0000f517          	auipc	a0,0xf
    80001b06:	0be50513          	addi	a0,a0,190 # 80010bc0 <cpus>
    80001b0a:	953e                	add	a0,a0,a5
    80001b0c:	6422                	ld	s0,8(sp)
    80001b0e:	0141                	addi	sp,sp,16
    80001b10:	8082                	ret

0000000080001b12 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    80001b12:	1101                	addi	sp,sp,-32
    80001b14:	ec06                	sd	ra,24(sp)
    80001b16:	e822                	sd	s0,16(sp)
    80001b18:	e426                	sd	s1,8(sp)
    80001b1a:	1000                	addi	s0,sp,32
  push_off();
    80001b1c:	fffff097          	auipc	ra,0xfffff
    80001b20:	06e080e7          	jalr	110(ra) # 80000b8a <push_off>
    80001b24:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001b26:	2781                	sext.w	a5,a5
    80001b28:	079e                	slli	a5,a5,0x7
    80001b2a:	0000f717          	auipc	a4,0xf
    80001b2e:	05670713          	addi	a4,a4,86 # 80010b80 <pid_lock>
    80001b32:	97ba                	add	a5,a5,a4
    80001b34:	63a4                	ld	s1,64(a5)
  pop_off();
    80001b36:	fffff097          	auipc	ra,0xfffff
    80001b3a:	0f4080e7          	jalr	244(ra) # 80000c2a <pop_off>
  return p;
}
    80001b3e:	8526                	mv	a0,s1
    80001b40:	60e2                	ld	ra,24(sp)
    80001b42:	6442                	ld	s0,16(sp)
    80001b44:	64a2                	ld	s1,8(sp)
    80001b46:	6105                	addi	sp,sp,32
    80001b48:	8082                	ret

0000000080001b4a <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    80001b4a:	1141                	addi	sp,sp,-16
    80001b4c:	e406                	sd	ra,8(sp)
    80001b4e:	e022                	sd	s0,0(sp)
    80001b50:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001b52:	00000097          	auipc	ra,0x0
    80001b56:	fc0080e7          	jalr	-64(ra) # 80001b12 <myproc>
    80001b5a:	fffff097          	auipc	ra,0xfffff
    80001b5e:	130080e7          	jalr	304(ra) # 80000c8a <release>

  if (first)
    80001b62:	00007797          	auipc	a5,0x7
    80001b66:	d1e7a783          	lw	a5,-738(a5) # 80008880 <first.1>
    80001b6a:	eb89                	bnez	a5,80001b7c <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001b6c:	00001097          	auipc	ra,0x1
    80001b70:	010080e7          	jalr	16(ra) # 80002b7c <usertrapret>
}
    80001b74:	60a2                	ld	ra,8(sp)
    80001b76:	6402                	ld	s0,0(sp)
    80001b78:	0141                	addi	sp,sp,16
    80001b7a:	8082                	ret
    first = 0;
    80001b7c:	00007797          	auipc	a5,0x7
    80001b80:	d007a223          	sw	zero,-764(a5) # 80008880 <first.1>
    fsinit(ROOTDEV);
    80001b84:	4505                	li	a0,1
    80001b86:	00002097          	auipc	ra,0x2
    80001b8a:	fb4080e7          	jalr	-76(ra) # 80003b3a <fsinit>
    80001b8e:	bff9                	j	80001b6c <forkret+0x22>

0000000080001b90 <allocpid>:
{
    80001b90:	1101                	addi	sp,sp,-32
    80001b92:	ec06                	sd	ra,24(sp)
    80001b94:	e822                	sd	s0,16(sp)
    80001b96:	e426                	sd	s1,8(sp)
    80001b98:	e04a                	sd	s2,0(sp)
    80001b9a:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001b9c:	0000f917          	auipc	s2,0xf
    80001ba0:	fe490913          	addi	s2,s2,-28 # 80010b80 <pid_lock>
    80001ba4:	854a                	mv	a0,s2
    80001ba6:	fffff097          	auipc	ra,0xfffff
    80001baa:	030080e7          	jalr	48(ra) # 80000bd6 <acquire>
  pid = nextpid;
    80001bae:	00007797          	auipc	a5,0x7
    80001bb2:	cda78793          	addi	a5,a5,-806 # 80008888 <nextpid>
    80001bb6:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001bb8:	0014871b          	addiw	a4,s1,1
    80001bbc:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001bbe:	854a                	mv	a0,s2
    80001bc0:	fffff097          	auipc	ra,0xfffff
    80001bc4:	0ca080e7          	jalr	202(ra) # 80000c8a <release>
}
    80001bc8:	8526                	mv	a0,s1
    80001bca:	60e2                	ld	ra,24(sp)
    80001bcc:	6442                	ld	s0,16(sp)
    80001bce:	64a2                	ld	s1,8(sp)
    80001bd0:	6902                	ld	s2,0(sp)
    80001bd2:	6105                	addi	sp,sp,32
    80001bd4:	8082                	ret

0000000080001bd6 <proc_pagetable>:
{
    80001bd6:	1101                	addi	sp,sp,-32
    80001bd8:	ec06                	sd	ra,24(sp)
    80001bda:	e822                	sd	s0,16(sp)
    80001bdc:	e426                	sd	s1,8(sp)
    80001bde:	e04a                	sd	s2,0(sp)
    80001be0:	1000                	addi	s0,sp,32
    80001be2:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001be4:	fffff097          	auipc	ra,0xfffff
    80001be8:	744080e7          	jalr	1860(ra) # 80001328 <uvmcreate>
    80001bec:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001bee:	c121                	beqz	a0,80001c2e <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001bf0:	4729                	li	a4,10
    80001bf2:	00005697          	auipc	a3,0x5
    80001bf6:	40e68693          	addi	a3,a3,1038 # 80007000 <_trampoline>
    80001bfa:	6605                	lui	a2,0x1
    80001bfc:	040005b7          	lui	a1,0x4000
    80001c00:	15fd                	addi	a1,a1,-1
    80001c02:	05b2                	slli	a1,a1,0xc
    80001c04:	fffff097          	auipc	ra,0xfffff
    80001c08:	49a080e7          	jalr	1178(ra) # 8000109e <mappages>
    80001c0c:	02054863          	bltz	a0,80001c3c <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001c10:	4719                	li	a4,6
    80001c12:	05893683          	ld	a3,88(s2)
    80001c16:	6605                	lui	a2,0x1
    80001c18:	020005b7          	lui	a1,0x2000
    80001c1c:	15fd                	addi	a1,a1,-1
    80001c1e:	05b6                	slli	a1,a1,0xd
    80001c20:	8526                	mv	a0,s1
    80001c22:	fffff097          	auipc	ra,0xfffff
    80001c26:	47c080e7          	jalr	1148(ra) # 8000109e <mappages>
    80001c2a:	02054163          	bltz	a0,80001c4c <proc_pagetable+0x76>
}
    80001c2e:	8526                	mv	a0,s1
    80001c30:	60e2                	ld	ra,24(sp)
    80001c32:	6442                	ld	s0,16(sp)
    80001c34:	64a2                	ld	s1,8(sp)
    80001c36:	6902                	ld	s2,0(sp)
    80001c38:	6105                	addi	sp,sp,32
    80001c3a:	8082                	ret
    uvmfree(pagetable, 0);
    80001c3c:	4581                	li	a1,0
    80001c3e:	8526                	mv	a0,s1
    80001c40:	00000097          	auipc	ra,0x0
    80001c44:	8ec080e7          	jalr	-1812(ra) # 8000152c <uvmfree>
    return 0;
    80001c48:	4481                	li	s1,0
    80001c4a:	b7d5                	j	80001c2e <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c4c:	4681                	li	a3,0
    80001c4e:	4605                	li	a2,1
    80001c50:	040005b7          	lui	a1,0x4000
    80001c54:	15fd                	addi	a1,a1,-1
    80001c56:	05b2                	slli	a1,a1,0xc
    80001c58:	8526                	mv	a0,s1
    80001c5a:	fffff097          	auipc	ra,0xfffff
    80001c5e:	60a080e7          	jalr	1546(ra) # 80001264 <uvmunmap>
    uvmfree(pagetable, 0);
    80001c62:	4581                	li	a1,0
    80001c64:	8526                	mv	a0,s1
    80001c66:	00000097          	auipc	ra,0x0
    80001c6a:	8c6080e7          	jalr	-1850(ra) # 8000152c <uvmfree>
    return 0;
    80001c6e:	4481                	li	s1,0
    80001c70:	bf7d                	j	80001c2e <proc_pagetable+0x58>

0000000080001c72 <proc_freepagetable>:
{
    80001c72:	1101                	addi	sp,sp,-32
    80001c74:	ec06                	sd	ra,24(sp)
    80001c76:	e822                	sd	s0,16(sp)
    80001c78:	e426                	sd	s1,8(sp)
    80001c7a:	e04a                	sd	s2,0(sp)
    80001c7c:	1000                	addi	s0,sp,32
    80001c7e:	84aa                	mv	s1,a0
    80001c80:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c82:	4681                	li	a3,0
    80001c84:	4605                	li	a2,1
    80001c86:	040005b7          	lui	a1,0x4000
    80001c8a:	15fd                	addi	a1,a1,-1
    80001c8c:	05b2                	slli	a1,a1,0xc
    80001c8e:	fffff097          	auipc	ra,0xfffff
    80001c92:	5d6080e7          	jalr	1494(ra) # 80001264 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001c96:	4681                	li	a3,0
    80001c98:	4605                	li	a2,1
    80001c9a:	020005b7          	lui	a1,0x2000
    80001c9e:	15fd                	addi	a1,a1,-1
    80001ca0:	05b6                	slli	a1,a1,0xd
    80001ca2:	8526                	mv	a0,s1
    80001ca4:	fffff097          	auipc	ra,0xfffff
    80001ca8:	5c0080e7          	jalr	1472(ra) # 80001264 <uvmunmap>
  uvmfree(pagetable, sz);
    80001cac:	85ca                	mv	a1,s2
    80001cae:	8526                	mv	a0,s1
    80001cb0:	00000097          	auipc	ra,0x0
    80001cb4:	87c080e7          	jalr	-1924(ra) # 8000152c <uvmfree>
}
    80001cb8:	60e2                	ld	ra,24(sp)
    80001cba:	6442                	ld	s0,16(sp)
    80001cbc:	64a2                	ld	s1,8(sp)
    80001cbe:	6902                	ld	s2,0(sp)
    80001cc0:	6105                	addi	sp,sp,32
    80001cc2:	8082                	ret

0000000080001cc4 <freeproc>:
{
    80001cc4:	1101                	addi	sp,sp,-32
    80001cc6:	ec06                	sd	ra,24(sp)
    80001cc8:	e822                	sd	s0,16(sp)
    80001cca:	e426                	sd	s1,8(sp)
    80001ccc:	1000                	addi	s0,sp,32
    80001cce:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001cd0:	6d28                	ld	a0,88(a0)
    80001cd2:	c509                	beqz	a0,80001cdc <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001cd4:	fffff097          	auipc	ra,0xfffff
    80001cd8:	d16080e7          	jalr	-746(ra) # 800009ea <kfree>
  p->trapframe = 0;
    80001cdc:	0404bc23          	sd	zero,88(s1)
  if (p->pagetable)
    80001ce0:	68a8                	ld	a0,80(s1)
    80001ce2:	c511                	beqz	a0,80001cee <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001ce4:	64ac                	ld	a1,72(s1)
    80001ce6:	00000097          	auipc	ra,0x0
    80001cea:	f8c080e7          	jalr	-116(ra) # 80001c72 <proc_freepagetable>
  p->pagetable = 0;
    80001cee:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001cf2:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001cf6:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001cfa:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001cfe:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001d02:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001d06:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001d0a:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001d0e:	0004ac23          	sw	zero,24(s1)
  for (int i = 0; i < NSYSCALLS; i++)
    80001d12:	17448793          	addi	a5,s1,372
    80001d16:	1e848713          	addi	a4,s1,488
    p->syscall_count[i] = 0;
    80001d1a:	0007a023          	sw	zero,0(a5)
  for (int i = 0; i < NSYSCALLS; i++)
    80001d1e:	0791                	addi	a5,a5,4
    80001d20:	fee79de3          	bne	a5,a4,80001d1a <freeproc+0x56>
}
    80001d24:	60e2                	ld	ra,24(sp)
    80001d26:	6442                	ld	s0,16(sp)
    80001d28:	64a2                	ld	s1,8(sp)
    80001d2a:	6105                	addi	sp,sp,32
    80001d2c:	8082                	ret

0000000080001d2e <allocproc>:
{
    80001d2e:	7179                	addi	sp,sp,-48
    80001d30:	f406                	sd	ra,40(sp)
    80001d32:	f022                	sd	s0,32(sp)
    80001d34:	ec26                	sd	s1,24(sp)
    80001d36:	e84a                	sd	s2,16(sp)
    80001d38:	e44e                	sd	s3,8(sp)
    80001d3a:	1800                	addi	s0,sp,48
  for (p = proc; p < &proc[NPROC]; p++)
    80001d3c:	00010497          	auipc	s1,0x10
    80001d40:	a8448493          	addi	s1,s1,-1404 # 800117c0 <proc>
    80001d44:	00018997          	auipc	s3,0x18
    80001d48:	07c98993          	addi	s3,s3,124 # 80019dc0 <tickslock>
    acquire(&p->lock);
    80001d4c:	8526                	mv	a0,s1
    80001d4e:	fffff097          	auipc	ra,0xfffff
    80001d52:	e88080e7          	jalr	-376(ra) # 80000bd6 <acquire>
    if (p->state == UNUSED)
    80001d56:	4c9c                	lw	a5,24(s1)
    80001d58:	cf81                	beqz	a5,80001d70 <allocproc+0x42>
      release(&p->lock);
    80001d5a:	8526                	mv	a0,s1
    80001d5c:	fffff097          	auipc	ra,0xfffff
    80001d60:	f2e080e7          	jalr	-210(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001d64:	21848493          	addi	s1,s1,536
    80001d68:	ff3492e3          	bne	s1,s3,80001d4c <allocproc+0x1e>
  return 0;
    80001d6c:	4481                	li	s1,0
    80001d6e:	a869                	j	80001e08 <allocproc+0xda>
  p->pid = allocpid();
    80001d70:	00000097          	auipc	ra,0x0
    80001d74:	e20080e7          	jalr	-480(ra) # 80001b90 <allocpid>
    80001d78:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001d7a:	4785                	li	a5,1
    80001d7c:	cc9c                	sw	a5,24(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001d7e:	fffff097          	auipc	ra,0xfffff
    80001d82:	d68080e7          	jalr	-664(ra) # 80000ae6 <kalloc>
    80001d86:	89aa                	mv	s3,a0
    80001d88:	eca8                	sd	a0,88(s1)
    80001d8a:	c559                	beqz	a0,80001e18 <allocproc+0xea>
  p->pagetable = proc_pagetable(p);
    80001d8c:	8526                	mv	a0,s1
    80001d8e:	00000097          	auipc	ra,0x0
    80001d92:	e48080e7          	jalr	-440(ra) # 80001bd6 <proc_pagetable>
    80001d96:	89aa                	mv	s3,a0
    80001d98:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001d9a:	c959                	beqz	a0,80001e30 <allocproc+0x102>
  memset(&p->context, 0, sizeof(p->context));
    80001d9c:	07000613          	li	a2,112
    80001da0:	4581                	li	a1,0
    80001da2:	06048513          	addi	a0,s1,96
    80001da6:	fffff097          	auipc	ra,0xfffff
    80001daa:	f2c080e7          	jalr	-212(ra) # 80000cd2 <memset>
  p->context.ra = (uint64)forkret;
    80001dae:	00000797          	auipc	a5,0x0
    80001db2:	d9c78793          	addi	a5,a5,-612 # 80001b4a <forkret>
    80001db6:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001db8:	60bc                	ld	a5,64(s1)
    80001dba:	6705                	lui	a4,0x1
    80001dbc:	97ba                	add	a5,a5,a4
    80001dbe:	f4bc                	sd	a5,104(s1)
  p->rtime = 0;
    80001dc0:	1604a423          	sw	zero,360(s1)
  p->etime = 0;
    80001dc4:	1604a823          	sw	zero,368(s1)
  p->ctime = ticks;
    80001dc8:	00007797          	auipc	a5,0x7
    80001dcc:	b487a783          	lw	a5,-1208(a5) # 80008910 <ticks>
    80001dd0:	16f4a623          	sw	a5,364(s1)
  for (int i = 0; i < NSYSCALLS; i++)
    80001dd4:	17448793          	addi	a5,s1,372
    80001dd8:	1e848713          	addi	a4,s1,488
    p->syscall_count[i] = 0;
    80001ddc:	0007a023          	sw	zero,0(a5)
  for (int i = 0; i < NSYSCALLS; i++)
    80001de0:	0791                	addi	a5,a5,4
    80001de2:	fee79de3          	bne	a5,a4,80001ddc <allocproc+0xae>
  p->alarmticks = 0;
    80001de6:	1e04a423          	sw	zero,488(s1)
  p->tickcounter = 0;
    80001dea:	1e04a623          	sw	zero,492(s1)
  p->handler = 0;
    80001dee:	1e04b823          	sd	zero,496(s1)
  p->alarm=0;
    80001df2:	2004a023          	sw	zero,512(s1)
  p->tickets = 1; // initally all will have 1
    80001df6:	4785                	li	a5,1
    80001df8:	20f4a223          	sw	a5,516(s1)
  p->priority=0;
    80001dfc:	2004a423          	sw	zero,520(s1)
  p->ticks_used = 0;
    80001e00:	2004a623          	sw	zero,524(s1)
  p->time_slice = 1;  
    80001e04:	20f4a823          	sw	a5,528(s1)
}
    80001e08:	8526                	mv	a0,s1
    80001e0a:	70a2                	ld	ra,40(sp)
    80001e0c:	7402                	ld	s0,32(sp)
    80001e0e:	64e2                	ld	s1,24(sp)
    80001e10:	6942                	ld	s2,16(sp)
    80001e12:	69a2                	ld	s3,8(sp)
    80001e14:	6145                	addi	sp,sp,48
    80001e16:	8082                	ret
    freeproc(p);
    80001e18:	8526                	mv	a0,s1
    80001e1a:	00000097          	auipc	ra,0x0
    80001e1e:	eaa080e7          	jalr	-342(ra) # 80001cc4 <freeproc>
    release(&p->lock);
    80001e22:	8526                	mv	a0,s1
    80001e24:	fffff097          	auipc	ra,0xfffff
    80001e28:	e66080e7          	jalr	-410(ra) # 80000c8a <release>
    return 0;
    80001e2c:	84ce                	mv	s1,s3
    80001e2e:	bfe9                	j	80001e08 <allocproc+0xda>
    freeproc(p);
    80001e30:	8526                	mv	a0,s1
    80001e32:	00000097          	auipc	ra,0x0
    80001e36:	e92080e7          	jalr	-366(ra) # 80001cc4 <freeproc>
    release(&p->lock);
    80001e3a:	8526                	mv	a0,s1
    80001e3c:	fffff097          	auipc	ra,0xfffff
    80001e40:	e4e080e7          	jalr	-434(ra) # 80000c8a <release>
    return 0;
    80001e44:	84ce                	mv	s1,s3
    80001e46:	b7c9                	j	80001e08 <allocproc+0xda>

0000000080001e48 <userinit>:
{
    80001e48:	1101                	addi	sp,sp,-32
    80001e4a:	ec06                	sd	ra,24(sp)
    80001e4c:	e822                	sd	s0,16(sp)
    80001e4e:	e426                	sd	s1,8(sp)
    80001e50:	1000                	addi	s0,sp,32
  p = allocproc();
    80001e52:	00000097          	auipc	ra,0x0
    80001e56:	edc080e7          	jalr	-292(ra) # 80001d2e <allocproc>
    80001e5a:	84aa                	mv	s1,a0
  initproc = p;
    80001e5c:	00007797          	auipc	a5,0x7
    80001e60:	aaa7b623          	sd	a0,-1364(a5) # 80008908 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001e64:	03400613          	li	a2,52
    80001e68:	00007597          	auipc	a1,0x7
    80001e6c:	a2858593          	addi	a1,a1,-1496 # 80008890 <initcode>
    80001e70:	6928                	ld	a0,80(a0)
    80001e72:	fffff097          	auipc	ra,0xfffff
    80001e76:	4e4080e7          	jalr	1252(ra) # 80001356 <uvmfirst>
  p->sz = PGSIZE;
    80001e7a:	6785                	lui	a5,0x1
    80001e7c:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001e7e:	6cb8                	ld	a4,88(s1)
    80001e80:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001e84:	6cb8                	ld	a4,88(s1)
    80001e86:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001e88:	4641                	li	a2,16
    80001e8a:	00006597          	auipc	a1,0x6
    80001e8e:	38658593          	addi	a1,a1,902 # 80008210 <digits+0x1d0>
    80001e92:	15848513          	addi	a0,s1,344
    80001e96:	fffff097          	auipc	ra,0xfffff
    80001e9a:	f86080e7          	jalr	-122(ra) # 80000e1c <safestrcpy>
  p->cwd = namei("/");
    80001e9e:	00006517          	auipc	a0,0x6
    80001ea2:	38250513          	addi	a0,a0,898 # 80008220 <digits+0x1e0>
    80001ea6:	00002097          	auipc	ra,0x2
    80001eaa:	6b6080e7          	jalr	1718(ra) # 8000455c <namei>
    80001eae:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001eb2:	478d                	li	a5,3
    80001eb4:	cc9c                	sw	a5,24(s1)
  enqueue(p);
    80001eb6:	8526                	mv	a0,s1
    80001eb8:	00000097          	auipc	ra,0x0
    80001ebc:	af8080e7          	jalr	-1288(ra) # 800019b0 <enqueue>
  release(&p->lock);
    80001ec0:	8526                	mv	a0,s1
    80001ec2:	fffff097          	auipc	ra,0xfffff
    80001ec6:	dc8080e7          	jalr	-568(ra) # 80000c8a <release>
}
    80001eca:	60e2                	ld	ra,24(sp)
    80001ecc:	6442                	ld	s0,16(sp)
    80001ece:	64a2                	ld	s1,8(sp)
    80001ed0:	6105                	addi	sp,sp,32
    80001ed2:	8082                	ret

0000000080001ed4 <growproc>:
{
    80001ed4:	1101                	addi	sp,sp,-32
    80001ed6:	ec06                	sd	ra,24(sp)
    80001ed8:	e822                	sd	s0,16(sp)
    80001eda:	e426                	sd	s1,8(sp)
    80001edc:	e04a                	sd	s2,0(sp)
    80001ede:	1000                	addi	s0,sp,32
    80001ee0:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001ee2:	00000097          	auipc	ra,0x0
    80001ee6:	c30080e7          	jalr	-976(ra) # 80001b12 <myproc>
    80001eea:	84aa                	mv	s1,a0
  sz = p->sz;
    80001eec:	652c                	ld	a1,72(a0)
  if (n > 0)
    80001eee:	01204c63          	bgtz	s2,80001f06 <growproc+0x32>
  else if (n < 0)
    80001ef2:	02094663          	bltz	s2,80001f1e <growproc+0x4a>
  p->sz = sz;
    80001ef6:	e4ac                	sd	a1,72(s1)
  return 0;
    80001ef8:	4501                	li	a0,0
}
    80001efa:	60e2                	ld	ra,24(sp)
    80001efc:	6442                	ld	s0,16(sp)
    80001efe:	64a2                	ld	s1,8(sp)
    80001f00:	6902                	ld	s2,0(sp)
    80001f02:	6105                	addi	sp,sp,32
    80001f04:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001f06:	4691                	li	a3,4
    80001f08:	00b90633          	add	a2,s2,a1
    80001f0c:	6928                	ld	a0,80(a0)
    80001f0e:	fffff097          	auipc	ra,0xfffff
    80001f12:	502080e7          	jalr	1282(ra) # 80001410 <uvmalloc>
    80001f16:	85aa                	mv	a1,a0
    80001f18:	fd79                	bnez	a0,80001ef6 <growproc+0x22>
      return -1;
    80001f1a:	557d                	li	a0,-1
    80001f1c:	bff9                	j	80001efa <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001f1e:	00b90633          	add	a2,s2,a1
    80001f22:	6928                	ld	a0,80(a0)
    80001f24:	fffff097          	auipc	ra,0xfffff
    80001f28:	4a4080e7          	jalr	1188(ra) # 800013c8 <uvmdealloc>
    80001f2c:	85aa                	mv	a1,a0
    80001f2e:	b7e1                	j	80001ef6 <growproc+0x22>

0000000080001f30 <fork>:
{
    80001f30:	7139                	addi	sp,sp,-64
    80001f32:	fc06                	sd	ra,56(sp)
    80001f34:	f822                	sd	s0,48(sp)
    80001f36:	f426                	sd	s1,40(sp)
    80001f38:	f04a                	sd	s2,32(sp)
    80001f3a:	ec4e                	sd	s3,24(sp)
    80001f3c:	e852                	sd	s4,16(sp)
    80001f3e:	e456                	sd	s5,8(sp)
    80001f40:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001f42:	00000097          	auipc	ra,0x0
    80001f46:	bd0080e7          	jalr	-1072(ra) # 80001b12 <myproc>
    80001f4a:	8aaa                	mv	s5,a0
  if ((np = allocproc()) == 0)
    80001f4c:	00000097          	auipc	ra,0x0
    80001f50:	de2080e7          	jalr	-542(ra) # 80001d2e <allocproc>
    80001f54:	12050563          	beqz	a0,8000207e <fork+0x14e>
    80001f58:	89aa                	mv	s3,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001f5a:	048ab603          	ld	a2,72(s5)
    80001f5e:	692c                	ld	a1,80(a0)
    80001f60:	050ab503          	ld	a0,80(s5)
    80001f64:	fffff097          	auipc	ra,0xfffff
    80001f68:	600080e7          	jalr	1536(ra) # 80001564 <uvmcopy>
    80001f6c:	04054863          	bltz	a0,80001fbc <fork+0x8c>
  np->sz = p->sz;
    80001f70:	048ab783          	ld	a5,72(s5)
    80001f74:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80001f78:	058ab683          	ld	a3,88(s5)
    80001f7c:	87b6                	mv	a5,a3
    80001f7e:	0589b703          	ld	a4,88(s3)
    80001f82:	12068693          	addi	a3,a3,288
    80001f86:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001f8a:	6788                	ld	a0,8(a5)
    80001f8c:	6b8c                	ld	a1,16(a5)
    80001f8e:	6f90                	ld	a2,24(a5)
    80001f90:	01073023          	sd	a6,0(a4)
    80001f94:	e708                	sd	a0,8(a4)
    80001f96:	eb0c                	sd	a1,16(a4)
    80001f98:	ef10                	sd	a2,24(a4)
    80001f9a:	02078793          	addi	a5,a5,32
    80001f9e:	02070713          	addi	a4,a4,32
    80001fa2:	fed792e3          	bne	a5,a3,80001f86 <fork+0x56>
  np->trapframe->a0 = 0;
    80001fa6:	0589b783          	ld	a5,88(s3)
    80001faa:	0607b823          	sd	zero,112(a5)
  for (i = 0; i < NOFILE; i++)
    80001fae:	0d0a8493          	addi	s1,s5,208
    80001fb2:	0d098913          	addi	s2,s3,208
    80001fb6:	150a8a13          	addi	s4,s5,336
    80001fba:	a00d                	j	80001fdc <fork+0xac>
    freeproc(np);
    80001fbc:	854e                	mv	a0,s3
    80001fbe:	00000097          	auipc	ra,0x0
    80001fc2:	d06080e7          	jalr	-762(ra) # 80001cc4 <freeproc>
    release(&np->lock);
    80001fc6:	854e                	mv	a0,s3
    80001fc8:	fffff097          	auipc	ra,0xfffff
    80001fcc:	cc2080e7          	jalr	-830(ra) # 80000c8a <release>
    return -1;
    80001fd0:	597d                	li	s2,-1
    80001fd2:	a861                	j	8000206a <fork+0x13a>
  for (i = 0; i < NOFILE; i++)
    80001fd4:	04a1                	addi	s1,s1,8
    80001fd6:	0921                	addi	s2,s2,8
    80001fd8:	01448b63          	beq	s1,s4,80001fee <fork+0xbe>
    if (p->ofile[i])
    80001fdc:	6088                	ld	a0,0(s1)
    80001fde:	d97d                	beqz	a0,80001fd4 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001fe0:	00003097          	auipc	ra,0x3
    80001fe4:	c12080e7          	jalr	-1006(ra) # 80004bf2 <filedup>
    80001fe8:	00a93023          	sd	a0,0(s2)
    80001fec:	b7e5                	j	80001fd4 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001fee:	150ab503          	ld	a0,336(s5)
    80001ff2:	00002097          	auipc	ra,0x2
    80001ff6:	d86080e7          	jalr	-634(ra) # 80003d78 <idup>
    80001ffa:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001ffe:	4641                	li	a2,16
    80002000:	158a8593          	addi	a1,s5,344
    80002004:	15898513          	addi	a0,s3,344
    80002008:	fffff097          	auipc	ra,0xfffff
    8000200c:	e14080e7          	jalr	-492(ra) # 80000e1c <safestrcpy>
  pid = np->pid;
    80002010:	0309a903          	lw	s2,48(s3)
  release(&np->lock);
    80002014:	854e                	mv	a0,s3
    80002016:	fffff097          	auipc	ra,0xfffff
    8000201a:	c74080e7          	jalr	-908(ra) # 80000c8a <release>
  acquire(&wait_lock);
    8000201e:	0000f497          	auipc	s1,0xf
    80002022:	b7a48493          	addi	s1,s1,-1158 # 80010b98 <wait_lock>
    80002026:	8526                	mv	a0,s1
    80002028:	fffff097          	auipc	ra,0xfffff
    8000202c:	bae080e7          	jalr	-1106(ra) # 80000bd6 <acquire>
  np->parent = p;
    80002030:	0359bc23          	sd	s5,56(s3)
  np->tickets=p->tickets;
    80002034:	204aa783          	lw	a5,516(s5)
    80002038:	20f9a223          	sw	a5,516(s3)
  release(&wait_lock);
    8000203c:	8526                	mv	a0,s1
    8000203e:	fffff097          	auipc	ra,0xfffff
    80002042:	c4c080e7          	jalr	-948(ra) # 80000c8a <release>
  acquire(&np->lock);
    80002046:	854e                	mv	a0,s3
    80002048:	fffff097          	auipc	ra,0xfffff
    8000204c:	b8e080e7          	jalr	-1138(ra) # 80000bd6 <acquire>
  np->state = RUNNABLE;
    80002050:	478d                	li	a5,3
    80002052:	00f9ac23          	sw	a5,24(s3)
  enqueue(np);
    80002056:	854e                	mv	a0,s3
    80002058:	00000097          	auipc	ra,0x0
    8000205c:	958080e7          	jalr	-1704(ra) # 800019b0 <enqueue>
  release(&np->lock);
    80002060:	854e                	mv	a0,s3
    80002062:	fffff097          	auipc	ra,0xfffff
    80002066:	c28080e7          	jalr	-984(ra) # 80000c8a <release>
}
    8000206a:	854a                	mv	a0,s2
    8000206c:	70e2                	ld	ra,56(sp)
    8000206e:	7442                	ld	s0,48(sp)
    80002070:	74a2                	ld	s1,40(sp)
    80002072:	7902                	ld	s2,32(sp)
    80002074:	69e2                	ld	s3,24(sp)
    80002076:	6a42                	ld	s4,16(sp)
    80002078:	6aa2                	ld	s5,8(sp)
    8000207a:	6121                	addi	sp,sp,64
    8000207c:	8082                	ret
    return -1;
    8000207e:	597d                	li	s2,-1
    80002080:	b7ed                	j	8000206a <fork+0x13a>

0000000080002082 <priority_boost>:
void priority_boost(void) {
    80002082:	7179                	addi	sp,sp,-48
    80002084:	f406                	sd	ra,40(sp)
    80002086:	f022                	sd	s0,32(sp)
    80002088:	ec26                	sd	s1,24(sp)
    8000208a:	e84a                	sd	s2,16(sp)
    8000208c:	e44e                	sd	s3,8(sp)
    8000208e:	e052                	sd	s4,0(sp)
    80002090:	1800                	addi	s0,sp,48
    for (p = proc; p<&proc[NPROC]; p++) {
    80002092:	0000f497          	auipc	s1,0xf
    80002096:	72e48493          	addi	s1,s1,1838 # 800117c0 <proc>
        if (p->priority!=0&&p->state == RUNNABLE) {
    8000209a:	498d                	li	s3,3
            p->time_slice = time_slices[0];
    8000209c:	00006a17          	auipc	s4,0x6
    800020a0:	7f4a0a13          	addi	s4,s4,2036 # 80008890 <initcode>
    for (p = proc; p<&proc[NPROC]; p++) {
    800020a4:	00018917          	auipc	s2,0x18
    800020a8:	d1c90913          	addi	s2,s2,-740 # 80019dc0 <tickslock>
    800020ac:	a029                	j	800020b6 <priority_boost+0x34>
    800020ae:	21848493          	addi	s1,s1,536
    800020b2:	03248b63          	beq	s1,s2,800020e8 <priority_boost+0x66>
        if (p->priority!=0&&p->state == RUNNABLE) {
    800020b6:	2084a783          	lw	a5,520(s1)
    800020ba:	dbf5                	beqz	a5,800020ae <priority_boost+0x2c>
    800020bc:	4c9c                	lw	a5,24(s1)
    800020be:	ff3798e3          	bne	a5,s3,800020ae <priority_boost+0x2c>
          dequeue(p);
    800020c2:	8526                	mv	a0,s1
    800020c4:	00000097          	auipc	ra,0x0
    800020c8:	974080e7          	jalr	-1676(ra) # 80001a38 <dequeue>
            p->priority = 0;
    800020cc:	2004a423          	sw	zero,520(s1)
            p->time_slice = time_slices[0];
    800020d0:	038a2783          	lw	a5,56(s4)
    800020d4:	20f4a823          	sw	a5,528(s1)
            p->ticks_used = 0;
    800020d8:	2004a623          	sw	zero,524(s1)
          enqueue(p);
    800020dc:	8526                	mv	a0,s1
    800020de:	00000097          	auipc	ra,0x0
    800020e2:	8d2080e7          	jalr	-1838(ra) # 800019b0 <enqueue>
    800020e6:	b7e1                	j	800020ae <priority_boost+0x2c>
}
    800020e8:	70a2                	ld	ra,40(sp)
    800020ea:	7402                	ld	s0,32(sp)
    800020ec:	64e2                	ld	s1,24(sp)
    800020ee:	6942                	ld	s2,16(sp)
    800020f0:	69a2                	ld	s3,8(sp)
    800020f2:	6a02                	ld	s4,0(sp)
    800020f4:	6145                	addi	sp,sp,48
    800020f6:	8082                	ret

00000000800020f8 <scheduler>:
{
    800020f8:	715d                	addi	sp,sp,-80
    800020fa:	e486                	sd	ra,72(sp)
    800020fc:	e0a2                	sd	s0,64(sp)
    800020fe:	fc26                	sd	s1,56(sp)
    80002100:	f84a                	sd	s2,48(sp)
    80002102:	f44e                	sd	s3,40(sp)
    80002104:	f052                	sd	s4,32(sp)
    80002106:	ec56                	sd	s5,24(sp)
    80002108:	e85a                	sd	s6,16(sp)
    8000210a:	e45e                	sd	s7,8(sp)
    8000210c:	0880                	addi	s0,sp,80
    8000210e:	8792                	mv	a5,tp
  int id = r_tp();
    80002110:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002112:	00779b13          	slli	s6,a5,0x7
    80002116:	0000f717          	auipc	a4,0xf
    8000211a:	a6a70713          	addi	a4,a4,-1430 # 80010b80 <pid_lock>
    8000211e:	975a                	add	a4,a4,s6
    80002120:	04073023          	sd	zero,64(a4)
      swtch(&c->context,&p->context);
    80002124:	0000f717          	auipc	a4,0xf
    80002128:	aa470713          	addi	a4,a4,-1372 # 80010bc8 <cpus+0x8>
    8000212c:	9b3a                	add	s6,s6,a4
    if (ticks % 48 == 0) {    priority_boost();
    8000212e:	00006997          	auipc	s3,0x6
    80002132:	7e298993          	addi	s3,s3,2018 # 80008910 <ticks>
    for (highest_queue = 0; highest_queue < NQUEUES; highest_queue++) {
    80002136:	4901                	li	s2,0
    80002138:	4491                	li	s1,4
    p = mlfq[highest_queue][0];
    8000213a:	0000fa17          	auipc	s4,0xf
    8000213e:	e86a0a13          	addi	s4,s4,-378 # 80010fc0 <mlfq>
      c->proc = p;
    80002142:	079e                	slli	a5,a5,0x7
    80002144:	0000fa97          	auipc	s5,0xf
    80002148:	a3ca8a93          	addi	s5,s5,-1476 # 80010b80 <pid_lock>
    8000214c:	9abe                	add	s5,s5,a5
    8000214e:	a091                	j	80002192 <scheduler+0x9a>
    if (ticks % 48 == 0) {    priority_boost();
    80002150:	00000097          	auipc	ra,0x0
    80002154:	f32080e7          	jalr	-206(ra) # 80002082 <priority_boost>
    80002158:	a891                	j	800021ac <scheduler+0xb4>
    if (highest_queue == NQUEUES)
    8000215a:	02978e63          	beq	a5,s1,80002196 <scheduler+0x9e>
    p = mlfq[highest_queue][0];
    8000215e:	07a6                	slli	a5,a5,0x9
    80002160:	97d2                	add	a5,a5,s4
    80002162:	0007bb83          	ld	s7,0(a5)
    acquire(&p->lock);
    80002166:	855e                	mv	a0,s7
    80002168:	fffff097          	auipc	ra,0xfffff
    8000216c:	a6e080e7          	jalr	-1426(ra) # 80000bd6 <acquire>
    if(p->state==RUNNABLE)
    80002170:	018ba703          	lw	a4,24(s7) # fffffffffffff018 <end+0xffffffff7ffd9e78>
    80002174:	478d                	li	a5,3
    80002176:	04f70863          	beq	a4,a5,800021c6 <scheduler+0xce>
      dequeue(p);
    8000217a:	855e                	mv	a0,s7
    8000217c:	00000097          	auipc	ra,0x0
    80002180:	8bc080e7          	jalr	-1860(ra) # 80001a38 <dequeue>
      p->ticks_used=0;
    80002184:	200ba623          	sw	zero,524(s7)
    release(&p->lock);
    80002188:	855e                	mv	a0,s7
    8000218a:	fffff097          	auipc	ra,0xfffff
    8000218e:	b00080e7          	jalr	-1280(ra) # 80000c8a <release>
    if (ticks % 48 == 0) {    priority_boost();
    80002192:	03000b93          	li	s7,48
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002196:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000219a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000219e:	10079073          	csrw	sstatus,a5
    800021a2:	0009a783          	lw	a5,0(s3)
    800021a6:	0377f7bb          	remuw	a5,a5,s7
    800021aa:	d3dd                	beqz	a5,80002150 <scheduler+0x58>
    for (highest_queue = 0; highest_queue < NQUEUES; highest_queue++) {
    800021ac:	0000f717          	auipc	a4,0xf
    800021b0:	a0470713          	addi	a4,a4,-1532 # 80010bb0 <queue_sizes>
    800021b4:	87ca                	mv	a5,s2
            if (queue_sizes[highest_queue] > 0)
    800021b6:	4314                	lw	a3,0(a4)
    800021b8:	fad041e3          	bgtz	a3,8000215a <scheduler+0x62>
    for (highest_queue = 0; highest_queue < NQUEUES; highest_queue++) {
    800021bc:	2785                	addiw	a5,a5,1
    800021be:	0711                	addi	a4,a4,4
    800021c0:	fe979be3          	bne	a5,s1,800021b6 <scheduler+0xbe>
    800021c4:	bfc9                	j	80002196 <scheduler+0x9e>
      p->state=RUNNING;
    800021c6:	009bac23          	sw	s1,24(s7)
      c->proc = p;
    800021ca:	057ab023          	sd	s7,64(s5)
      swtch(&c->context,&p->context);
    800021ce:	060b8593          	addi	a1,s7,96
    800021d2:	855a                	mv	a0,s6
    800021d4:	00001097          	auipc	ra,0x1
    800021d8:	8fe080e7          	jalr	-1794(ra) # 80002ad2 <swtch>
      c->proc=0;
    800021dc:	040ab023          	sd	zero,64(s5)
    p->ticks_used++;
    800021e0:	20cba783          	lw	a5,524(s7)
    800021e4:	2785                	addiw	a5,a5,1
    800021e6:	0007871b          	sext.w	a4,a5
    800021ea:	20fba623          	sw	a5,524(s7)
    if (p->ticks_used >= p->time_slice) {
    800021ee:	210ba783          	lw	a5,528(s7)
    800021f2:	04f74f63          	blt	a4,a5,80002250 <scheduler+0x158>
      if (p->priority < 3) {
    800021f6:	208ba703          	lw	a4,520(s7)
    800021fa:	4789                	li	a5,2
    800021fc:	02e7cf63          	blt	a5,a4,8000223a <scheduler+0x142>
        dequeue(p);
    80002200:	855e                	mv	a0,s7
    80002202:	00000097          	auipc	ra,0x0
    80002206:	836080e7          	jalr	-1994(ra) # 80001a38 <dequeue>
          p->priority++;
    8000220a:	208ba783          	lw	a5,520(s7)
    8000220e:	2785                	addiw	a5,a5,1
    80002210:	0007871b          	sext.w	a4,a5
    80002214:	20fba423          	sw	a5,520(s7)
          p->time_slice = time_slices[p->priority]; // Update the new time slice
    80002218:	070a                	slli	a4,a4,0x2
    8000221a:	00006797          	auipc	a5,0x6
    8000221e:	67678793          	addi	a5,a5,1654 # 80008890 <initcode>
    80002222:	97ba                	add	a5,a5,a4
    80002224:	5f9c                	lw	a5,56(a5)
    80002226:	20fba823          	sw	a5,528(s7)
          enqueue(p);
    8000222a:	855e                	mv	a0,s7
    8000222c:	fffff097          	auipc	ra,0xfffff
    80002230:	784080e7          	jalr	1924(ra) # 800019b0 <enqueue>
      p->ticks_used = 0;
    80002234:	200ba623          	sw	zero,524(s7)
    80002238:	bf81                	j	80002188 <scheduler+0x90>
          dequeue(p);
    8000223a:	855e                	mv	a0,s7
    8000223c:	fffff097          	auipc	ra,0xfffff
    80002240:	7fc080e7          	jalr	2044(ra) # 80001a38 <dequeue>
          enqueue(p);//basically when p->priority == 3//still we have to enqueue deuque it
    80002244:	855e                	mv	a0,s7
    80002246:	fffff097          	auipc	ra,0xfffff
    8000224a:	76a080e7          	jalr	1898(ra) # 800019b0 <enqueue>
    8000224e:	b7dd                	j	80002234 <scheduler+0x13c>
        dequeue(p);
    80002250:	855e                	mv	a0,s7
    80002252:	fffff097          	auipc	ra,0xfffff
    80002256:	7e6080e7          	jalr	2022(ra) # 80001a38 <dequeue>
          enqueue(p);
    8000225a:	855e                	mv	a0,s7
    8000225c:	fffff097          	auipc	ra,0xfffff
    80002260:	754080e7          	jalr	1876(ra) # 800019b0 <enqueue>
       release(&p->lock);//slice consume nhi ha 
    80002264:	855e                	mv	a0,s7
    80002266:	fffff097          	auipc	ra,0xfffff
    8000226a:	a24080e7          	jalr	-1500(ra) # 80000c8a <release>
       continue;
    8000226e:	b715                	j	80002192 <scheduler+0x9a>

0000000080002270 <sched>:
{
    80002270:	7179                	addi	sp,sp,-48
    80002272:	f406                	sd	ra,40(sp)
    80002274:	f022                	sd	s0,32(sp)
    80002276:	ec26                	sd	s1,24(sp)
    80002278:	e84a                	sd	s2,16(sp)
    8000227a:	e44e                	sd	s3,8(sp)
    8000227c:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000227e:	00000097          	auipc	ra,0x0
    80002282:	894080e7          	jalr	-1900(ra) # 80001b12 <myproc>
    80002286:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    80002288:	fffff097          	auipc	ra,0xfffff
    8000228c:	8d4080e7          	jalr	-1836(ra) # 80000b5c <holding>
    80002290:	c93d                	beqz	a0,80002306 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002292:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    80002294:	2781                	sext.w	a5,a5
    80002296:	079e                	slli	a5,a5,0x7
    80002298:	0000f717          	auipc	a4,0xf
    8000229c:	8e870713          	addi	a4,a4,-1816 # 80010b80 <pid_lock>
    800022a0:	97ba                	add	a5,a5,a4
    800022a2:	0b87a703          	lw	a4,184(a5)
    800022a6:	4785                	li	a5,1
    800022a8:	06f71763          	bne	a4,a5,80002316 <sched+0xa6>
  if (p->state == RUNNING)
    800022ac:	4c98                	lw	a4,24(s1)
    800022ae:	4791                	li	a5,4
    800022b0:	06f70b63          	beq	a4,a5,80002326 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800022b4:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800022b8:	8b89                	andi	a5,a5,2
  if (intr_get())
    800022ba:	efb5                	bnez	a5,80002336 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800022bc:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800022be:	0000f917          	auipc	s2,0xf
    800022c2:	8c290913          	addi	s2,s2,-1854 # 80010b80 <pid_lock>
    800022c6:	2781                	sext.w	a5,a5
    800022c8:	079e                	slli	a5,a5,0x7
    800022ca:	97ca                	add	a5,a5,s2
    800022cc:	0bc7a983          	lw	s3,188(a5)
    800022d0:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800022d2:	2781                	sext.w	a5,a5
    800022d4:	079e                	slli	a5,a5,0x7
    800022d6:	0000f597          	auipc	a1,0xf
    800022da:	8f258593          	addi	a1,a1,-1806 # 80010bc8 <cpus+0x8>
    800022de:	95be                	add	a1,a1,a5
    800022e0:	06048513          	addi	a0,s1,96
    800022e4:	00000097          	auipc	ra,0x0
    800022e8:	7ee080e7          	jalr	2030(ra) # 80002ad2 <swtch>
    800022ec:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800022ee:	2781                	sext.w	a5,a5
    800022f0:	079e                	slli	a5,a5,0x7
    800022f2:	97ca                	add	a5,a5,s2
    800022f4:	0b37ae23          	sw	s3,188(a5)
}
    800022f8:	70a2                	ld	ra,40(sp)
    800022fa:	7402                	ld	s0,32(sp)
    800022fc:	64e2                	ld	s1,24(sp)
    800022fe:	6942                	ld	s2,16(sp)
    80002300:	69a2                	ld	s3,8(sp)
    80002302:	6145                	addi	sp,sp,48
    80002304:	8082                	ret
    panic("sched p->lock");
    80002306:	00006517          	auipc	a0,0x6
    8000230a:	f2250513          	addi	a0,a0,-222 # 80008228 <digits+0x1e8>
    8000230e:	ffffe097          	auipc	ra,0xffffe
    80002312:	230080e7          	jalr	560(ra) # 8000053e <panic>
    panic("sched locks");
    80002316:	00006517          	auipc	a0,0x6
    8000231a:	f2250513          	addi	a0,a0,-222 # 80008238 <digits+0x1f8>
    8000231e:	ffffe097          	auipc	ra,0xffffe
    80002322:	220080e7          	jalr	544(ra) # 8000053e <panic>
    panic("sched running");
    80002326:	00006517          	auipc	a0,0x6
    8000232a:	f2250513          	addi	a0,a0,-222 # 80008248 <digits+0x208>
    8000232e:	ffffe097          	auipc	ra,0xffffe
    80002332:	210080e7          	jalr	528(ra) # 8000053e <panic>
    panic("sched interruptible");
    80002336:	00006517          	auipc	a0,0x6
    8000233a:	f2250513          	addi	a0,a0,-222 # 80008258 <digits+0x218>
    8000233e:	ffffe097          	auipc	ra,0xffffe
    80002342:	200080e7          	jalr	512(ra) # 8000053e <panic>

0000000080002346 <yield>:
{
    80002346:	1101                	addi	sp,sp,-32
    80002348:	ec06                	sd	ra,24(sp)
    8000234a:	e822                	sd	s0,16(sp)
    8000234c:	e426                	sd	s1,8(sp)
    8000234e:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002350:	fffff097          	auipc	ra,0xfffff
    80002354:	7c2080e7          	jalr	1986(ra) # 80001b12 <myproc>
    80002358:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000235a:	fffff097          	auipc	ra,0xfffff
    8000235e:	87c080e7          	jalr	-1924(ra) # 80000bd6 <acquire>
  p->state = RUNNABLE;
    80002362:	478d                	li	a5,3
    80002364:	cc9c                	sw	a5,24(s1)
  sched();
    80002366:	00000097          	auipc	ra,0x0
    8000236a:	f0a080e7          	jalr	-246(ra) # 80002270 <sched>
  release(&p->lock);
    8000236e:	8526                	mv	a0,s1
    80002370:	fffff097          	auipc	ra,0xfffff
    80002374:	91a080e7          	jalr	-1766(ra) # 80000c8a <release>
}
    80002378:	60e2                	ld	ra,24(sp)
    8000237a:	6442                	ld	s0,16(sp)
    8000237c:	64a2                	ld	s1,8(sp)
    8000237e:	6105                	addi	sp,sp,32
    80002380:	8082                	ret

0000000080002382 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    80002382:	7179                	addi	sp,sp,-48
    80002384:	f406                	sd	ra,40(sp)
    80002386:	f022                	sd	s0,32(sp)
    80002388:	ec26                	sd	s1,24(sp)
    8000238a:	e84a                	sd	s2,16(sp)
    8000238c:	e44e                	sd	s3,8(sp)
    8000238e:	1800                	addi	s0,sp,48
    80002390:	89aa                	mv	s3,a0
    80002392:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002394:	fffff097          	auipc	ra,0xfffff
    80002398:	77e080e7          	jalr	1918(ra) # 80001b12 <myproc>
    8000239c:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    8000239e:	fffff097          	auipc	ra,0xfffff
    800023a2:	838080e7          	jalr	-1992(ra) # 80000bd6 <acquire>
  release(lk);
    800023a6:	854a                	mv	a0,s2
    800023a8:	fffff097          	auipc	ra,0xfffff
    800023ac:	8e2080e7          	jalr	-1822(ra) # 80000c8a <release>

  // Go to sleep.
  p->chan = chan;
    800023b0:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800023b4:	4789                	li	a5,2
    800023b6:	cc9c                	sw	a5,24(s1)

  sched();
    800023b8:	00000097          	auipc	ra,0x0
    800023bc:	eb8080e7          	jalr	-328(ra) # 80002270 <sched>

  // Tidy up.
  p->chan = 0;
    800023c0:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800023c4:	8526                	mv	a0,s1
    800023c6:	fffff097          	auipc	ra,0xfffff
    800023ca:	8c4080e7          	jalr	-1852(ra) # 80000c8a <release>
  acquire(lk);
    800023ce:	854a                	mv	a0,s2
    800023d0:	fffff097          	auipc	ra,0xfffff
    800023d4:	806080e7          	jalr	-2042(ra) # 80000bd6 <acquire>
}
    800023d8:	70a2                	ld	ra,40(sp)
    800023da:	7402                	ld	s0,32(sp)
    800023dc:	64e2                	ld	s1,24(sp)
    800023de:	6942                	ld	s2,16(sp)
    800023e0:	69a2                	ld	s3,8(sp)
    800023e2:	6145                	addi	sp,sp,48
    800023e4:	8082                	ret

00000000800023e6 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    800023e6:	7139                	addi	sp,sp,-64
    800023e8:	fc06                	sd	ra,56(sp)
    800023ea:	f822                	sd	s0,48(sp)
    800023ec:	f426                	sd	s1,40(sp)
    800023ee:	f04a                	sd	s2,32(sp)
    800023f0:	ec4e                	sd	s3,24(sp)
    800023f2:	e852                	sd	s4,16(sp)
    800023f4:	e456                	sd	s5,8(sp)
    800023f6:	0080                	addi	s0,sp,64
    800023f8:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800023fa:	0000f497          	auipc	s1,0xf
    800023fe:	3c648493          	addi	s1,s1,966 # 800117c0 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    80002402:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    80002404:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    80002406:	00018917          	auipc	s2,0x18
    8000240a:	9ba90913          	addi	s2,s2,-1606 # 80019dc0 <tickslock>
    8000240e:	a811                	j	80002422 <wakeup+0x3c>
        enqueue(p);
      }
      release(&p->lock);
    80002410:	8526                	mv	a0,s1
    80002412:	fffff097          	auipc	ra,0xfffff
    80002416:	878080e7          	jalr	-1928(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    8000241a:	21848493          	addi	s1,s1,536
    8000241e:	03248b63          	beq	s1,s2,80002454 <wakeup+0x6e>
    if (p != myproc())
    80002422:	fffff097          	auipc	ra,0xfffff
    80002426:	6f0080e7          	jalr	1776(ra) # 80001b12 <myproc>
    8000242a:	fea488e3          	beq	s1,a0,8000241a <wakeup+0x34>
      acquire(&p->lock);
    8000242e:	8526                	mv	a0,s1
    80002430:	ffffe097          	auipc	ra,0xffffe
    80002434:	7a6080e7          	jalr	1958(ra) # 80000bd6 <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    80002438:	4c9c                	lw	a5,24(s1)
    8000243a:	fd379be3          	bne	a5,s3,80002410 <wakeup+0x2a>
    8000243e:	709c                	ld	a5,32(s1)
    80002440:	fd4798e3          	bne	a5,s4,80002410 <wakeup+0x2a>
        p->state = RUNNABLE;
    80002444:	0154ac23          	sw	s5,24(s1)
        enqueue(p);
    80002448:	8526                	mv	a0,s1
    8000244a:	fffff097          	auipc	ra,0xfffff
    8000244e:	566080e7          	jalr	1382(ra) # 800019b0 <enqueue>
    80002452:	bf7d                	j	80002410 <wakeup+0x2a>
    }
  }
}
    80002454:	70e2                	ld	ra,56(sp)
    80002456:	7442                	ld	s0,48(sp)
    80002458:	74a2                	ld	s1,40(sp)
    8000245a:	7902                	ld	s2,32(sp)
    8000245c:	69e2                	ld	s3,24(sp)
    8000245e:	6a42                	ld	s4,16(sp)
    80002460:	6aa2                	ld	s5,8(sp)
    80002462:	6121                	addi	sp,sp,64
    80002464:	8082                	ret

0000000080002466 <reparent>:
{
    80002466:	7179                	addi	sp,sp,-48
    80002468:	f406                	sd	ra,40(sp)
    8000246a:	f022                	sd	s0,32(sp)
    8000246c:	ec26                	sd	s1,24(sp)
    8000246e:	e84a                	sd	s2,16(sp)
    80002470:	e44e                	sd	s3,8(sp)
    80002472:	e052                	sd	s4,0(sp)
    80002474:	1800                	addi	s0,sp,48
    80002476:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    80002478:	0000f497          	auipc	s1,0xf
    8000247c:	34848493          	addi	s1,s1,840 # 800117c0 <proc>
      pp->parent = initproc;
    80002480:	00006a17          	auipc	s4,0x6
    80002484:	488a0a13          	addi	s4,s4,1160 # 80008908 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    80002488:	00018997          	auipc	s3,0x18
    8000248c:	93898993          	addi	s3,s3,-1736 # 80019dc0 <tickslock>
    80002490:	a029                	j	8000249a <reparent+0x34>
    80002492:	21848493          	addi	s1,s1,536
    80002496:	01348d63          	beq	s1,s3,800024b0 <reparent+0x4a>
    if (pp->parent == p)
    8000249a:	7c9c                	ld	a5,56(s1)
    8000249c:	ff279be3          	bne	a5,s2,80002492 <reparent+0x2c>
      pp->parent = initproc;
    800024a0:	000a3503          	ld	a0,0(s4)
    800024a4:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800024a6:	00000097          	auipc	ra,0x0
    800024aa:	f40080e7          	jalr	-192(ra) # 800023e6 <wakeup>
    800024ae:	b7d5                	j	80002492 <reparent+0x2c>
}
    800024b0:	70a2                	ld	ra,40(sp)
    800024b2:	7402                	ld	s0,32(sp)
    800024b4:	64e2                	ld	s1,24(sp)
    800024b6:	6942                	ld	s2,16(sp)
    800024b8:	69a2                	ld	s3,8(sp)
    800024ba:	6a02                	ld	s4,0(sp)
    800024bc:	6145                	addi	sp,sp,48
    800024be:	8082                	ret

00000000800024c0 <exit>:
{
    800024c0:	7179                	addi	sp,sp,-48
    800024c2:	f406                	sd	ra,40(sp)
    800024c4:	f022                	sd	s0,32(sp)
    800024c6:	ec26                	sd	s1,24(sp)
    800024c8:	e84a                	sd	s2,16(sp)
    800024ca:	e44e                	sd	s3,8(sp)
    800024cc:	e052                	sd	s4,0(sp)
    800024ce:	1800                	addi	s0,sp,48
    800024d0:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800024d2:	fffff097          	auipc	ra,0xfffff
    800024d6:	640080e7          	jalr	1600(ra) # 80001b12 <myproc>
    800024da:	89aa                	mv	s3,a0
  if (p == initproc)
    800024dc:	00006797          	auipc	a5,0x6
    800024e0:	42c7b783          	ld	a5,1068(a5) # 80008908 <initproc>
    800024e4:	0d050493          	addi	s1,a0,208
    800024e8:	15050913          	addi	s2,a0,336
    800024ec:	02a79363          	bne	a5,a0,80002512 <exit+0x52>
    panic("init exiting");
    800024f0:	00006517          	auipc	a0,0x6
    800024f4:	d8050513          	addi	a0,a0,-640 # 80008270 <digits+0x230>
    800024f8:	ffffe097          	auipc	ra,0xffffe
    800024fc:	046080e7          	jalr	70(ra) # 8000053e <panic>
      fileclose(f);
    80002500:	00002097          	auipc	ra,0x2
    80002504:	744080e7          	jalr	1860(ra) # 80004c44 <fileclose>
      p->ofile[fd] = 0;
    80002508:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    8000250c:	04a1                	addi	s1,s1,8
    8000250e:	01248563          	beq	s1,s2,80002518 <exit+0x58>
    if (p->ofile[fd])
    80002512:	6088                	ld	a0,0(s1)
    80002514:	f575                	bnez	a0,80002500 <exit+0x40>
    80002516:	bfdd                	j	8000250c <exit+0x4c>
  begin_op();
    80002518:	00002097          	auipc	ra,0x2
    8000251c:	260080e7          	jalr	608(ra) # 80004778 <begin_op>
  iput(p->cwd);
    80002520:	1509b503          	ld	a0,336(s3)
    80002524:	00002097          	auipc	ra,0x2
    80002528:	a4c080e7          	jalr	-1460(ra) # 80003f70 <iput>
  end_op();
    8000252c:	00002097          	auipc	ra,0x2
    80002530:	2cc080e7          	jalr	716(ra) # 800047f8 <end_op>
  p->cwd = 0;
    80002534:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002538:	0000e497          	auipc	s1,0xe
    8000253c:	66048493          	addi	s1,s1,1632 # 80010b98 <wait_lock>
    80002540:	8526                	mv	a0,s1
    80002542:	ffffe097          	auipc	ra,0xffffe
    80002546:	694080e7          	jalr	1684(ra) # 80000bd6 <acquire>
  reparent(p);
    8000254a:	854e                	mv	a0,s3
    8000254c:	00000097          	auipc	ra,0x0
    80002550:	f1a080e7          	jalr	-230(ra) # 80002466 <reparent>
  wakeup(p->parent);
    80002554:	0389b503          	ld	a0,56(s3)
    80002558:	00000097          	auipc	ra,0x0
    8000255c:	e8e080e7          	jalr	-370(ra) # 800023e6 <wakeup>
  acquire(&p->lock);
    80002560:	854e                	mv	a0,s3
    80002562:	ffffe097          	auipc	ra,0xffffe
    80002566:	674080e7          	jalr	1652(ra) # 80000bd6 <acquire>
  p->xstate = status;
    8000256a:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    8000256e:	4795                	li	a5,5
    80002570:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    80002574:	00006797          	auipc	a5,0x6
    80002578:	39c7a783          	lw	a5,924(a5) # 80008910 <ticks>
    8000257c:	16f9a823          	sw	a5,368(s3)
  release(&wait_lock);
    80002580:	8526                	mv	a0,s1
    80002582:	ffffe097          	auipc	ra,0xffffe
    80002586:	708080e7          	jalr	1800(ra) # 80000c8a <release>
  sched();
    8000258a:	00000097          	auipc	ra,0x0
    8000258e:	ce6080e7          	jalr	-794(ra) # 80002270 <sched>
  panic("zombie exit");
    80002592:	00006517          	auipc	a0,0x6
    80002596:	cee50513          	addi	a0,a0,-786 # 80008280 <digits+0x240>
    8000259a:	ffffe097          	auipc	ra,0xffffe
    8000259e:	fa4080e7          	jalr	-92(ra) # 8000053e <panic>

00000000800025a2 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    800025a2:	7179                	addi	sp,sp,-48
    800025a4:	f406                	sd	ra,40(sp)
    800025a6:	f022                	sd	s0,32(sp)
    800025a8:	ec26                	sd	s1,24(sp)
    800025aa:	e84a                	sd	s2,16(sp)
    800025ac:	e44e                	sd	s3,8(sp)
    800025ae:	1800                	addi	s0,sp,48
    800025b0:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800025b2:	0000f497          	auipc	s1,0xf
    800025b6:	20e48493          	addi	s1,s1,526 # 800117c0 <proc>
    800025ba:	00018997          	auipc	s3,0x18
    800025be:	80698993          	addi	s3,s3,-2042 # 80019dc0 <tickslock>
  {
    acquire(&p->lock);
    800025c2:	8526                	mv	a0,s1
    800025c4:	ffffe097          	auipc	ra,0xffffe
    800025c8:	612080e7          	jalr	1554(ra) # 80000bd6 <acquire>
    if (p->pid == pid)
    800025cc:	589c                	lw	a5,48(s1)
    800025ce:	01278d63          	beq	a5,s2,800025e8 <kill+0x46>
        enqueue(p);
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800025d2:	8526                	mv	a0,s1
    800025d4:	ffffe097          	auipc	ra,0xffffe
    800025d8:	6b6080e7          	jalr	1718(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800025dc:	21848493          	addi	s1,s1,536
    800025e0:	ff3491e3          	bne	s1,s3,800025c2 <kill+0x20>
  }
  return -1;
    800025e4:	557d                	li	a0,-1
    800025e6:	a829                	j	80002600 <kill+0x5e>
      p->killed = 1;
    800025e8:	4785                	li	a5,1
    800025ea:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    800025ec:	4c98                	lw	a4,24(s1)
    800025ee:	4789                	li	a5,2
    800025f0:	00f70f63          	beq	a4,a5,8000260e <kill+0x6c>
      release(&p->lock);
    800025f4:	8526                	mv	a0,s1
    800025f6:	ffffe097          	auipc	ra,0xffffe
    800025fa:	694080e7          	jalr	1684(ra) # 80000c8a <release>
      return 0;
    800025fe:	4501                	li	a0,0
}
    80002600:	70a2                	ld	ra,40(sp)
    80002602:	7402                	ld	s0,32(sp)
    80002604:	64e2                	ld	s1,24(sp)
    80002606:	6942                	ld	s2,16(sp)
    80002608:	69a2                	ld	s3,8(sp)
    8000260a:	6145                	addi	sp,sp,48
    8000260c:	8082                	ret
        p->state = RUNNABLE;
    8000260e:	478d                	li	a5,3
    80002610:	cc9c                	sw	a5,24(s1)
        enqueue(p);
    80002612:	8526                	mv	a0,s1
    80002614:	fffff097          	auipc	ra,0xfffff
    80002618:	39c080e7          	jalr	924(ra) # 800019b0 <enqueue>
    8000261c:	bfe1                	j	800025f4 <kill+0x52>

000000008000261e <setkilled>:

void setkilled(struct proc *p)
{
    8000261e:	1101                	addi	sp,sp,-32
    80002620:	ec06                	sd	ra,24(sp)
    80002622:	e822                	sd	s0,16(sp)
    80002624:	e426                	sd	s1,8(sp)
    80002626:	1000                	addi	s0,sp,32
    80002628:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000262a:	ffffe097          	auipc	ra,0xffffe
    8000262e:	5ac080e7          	jalr	1452(ra) # 80000bd6 <acquire>
  p->killed = 1;
    80002632:	4785                	li	a5,1
    80002634:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    80002636:	8526                	mv	a0,s1
    80002638:	ffffe097          	auipc	ra,0xffffe
    8000263c:	652080e7          	jalr	1618(ra) # 80000c8a <release>
}
    80002640:	60e2                	ld	ra,24(sp)
    80002642:	6442                	ld	s0,16(sp)
    80002644:	64a2                	ld	s1,8(sp)
    80002646:	6105                	addi	sp,sp,32
    80002648:	8082                	ret

000000008000264a <killed>:

int killed(struct proc *p)
{
    8000264a:	1101                	addi	sp,sp,-32
    8000264c:	ec06                	sd	ra,24(sp)
    8000264e:	e822                	sd	s0,16(sp)
    80002650:	e426                	sd	s1,8(sp)
    80002652:	e04a                	sd	s2,0(sp)
    80002654:	1000                	addi	s0,sp,32
    80002656:	84aa                	mv	s1,a0
  int k;

  acquire(&p->lock);
    80002658:	ffffe097          	auipc	ra,0xffffe
    8000265c:	57e080e7          	jalr	1406(ra) # 80000bd6 <acquire>
  k = p->killed;
    80002660:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002664:	8526                	mv	a0,s1
    80002666:	ffffe097          	auipc	ra,0xffffe
    8000266a:	624080e7          	jalr	1572(ra) # 80000c8a <release>
  return k;
}
    8000266e:	854a                	mv	a0,s2
    80002670:	60e2                	ld	ra,24(sp)
    80002672:	6442                	ld	s0,16(sp)
    80002674:	64a2                	ld	s1,8(sp)
    80002676:	6902                	ld	s2,0(sp)
    80002678:	6105                	addi	sp,sp,32
    8000267a:	8082                	ret

000000008000267c <wait>:
{
    8000267c:	715d                	addi	sp,sp,-80
    8000267e:	e486                	sd	ra,72(sp)
    80002680:	e0a2                	sd	s0,64(sp)
    80002682:	fc26                	sd	s1,56(sp)
    80002684:	f84a                	sd	s2,48(sp)
    80002686:	f44e                	sd	s3,40(sp)
    80002688:	f052                	sd	s4,32(sp)
    8000268a:	ec56                	sd	s5,24(sp)
    8000268c:	e85a                	sd	s6,16(sp)
    8000268e:	e45e                	sd	s7,8(sp)
    80002690:	e062                	sd	s8,0(sp)
    80002692:	0880                	addi	s0,sp,80
    80002694:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002696:	fffff097          	auipc	ra,0xfffff
    8000269a:	47c080e7          	jalr	1148(ra) # 80001b12 <myproc>
    8000269e:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800026a0:	0000e517          	auipc	a0,0xe
    800026a4:	4f850513          	addi	a0,a0,1272 # 80010b98 <wait_lock>
    800026a8:	ffffe097          	auipc	ra,0xffffe
    800026ac:	52e080e7          	jalr	1326(ra) # 80000bd6 <acquire>
    havekids = 0;
    800026b0:	4b81                	li	s7,0
        if (pp->state == ZOMBIE)
    800026b2:	4a15                	li	s4,5
        havekids = 1;
    800026b4:	4a85                	li	s5,1
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800026b6:	00017997          	auipc	s3,0x17
    800026ba:	70a98993          	addi	s3,s3,1802 # 80019dc0 <tickslock>
    sleep(p, &wait_lock); // DOC: wait-sleep
    800026be:	0000ec17          	auipc	s8,0xe
    800026c2:	4dac0c13          	addi	s8,s8,1242 # 80010b98 <wait_lock>
    havekids = 0;
    800026c6:	875e                	mv	a4,s7
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800026c8:	0000f497          	auipc	s1,0xf
    800026cc:	0f848493          	addi	s1,s1,248 # 800117c0 <proc>
    800026d0:	a849                	j	80002762 <wait+0xe6>
          pid = pp->pid;
    800026d2:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    800026d6:	040b1763          	bnez	s6,80002724 <wait+0xa8>
          for (int i = 0; i < NSYSCALLS; i++)
    800026da:	17448613          	addi	a2,s1,372
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800026de:	4701                	li	a4,0
          for (int i = 0; i < NSYSCALLS; i++)
    800026e0:	4575                	li	a0,29
            pp->parent->syscall_count[i] += pp->syscall_count[i];
    800026e2:	00271693          	slli	a3,a4,0x2
    800026e6:	7c9c                	ld	a5,56(s1)
    800026e8:	97b6                	add	a5,a5,a3
    800026ea:	1747a683          	lw	a3,372(a5)
    800026ee:	420c                	lw	a1,0(a2)
    800026f0:	9ead                	addw	a3,a3,a1
    800026f2:	16d7aa23          	sw	a3,372(a5)
          for (int i = 0; i < NSYSCALLS; i++)
    800026f6:	2705                	addiw	a4,a4,1
    800026f8:	0611                	addi	a2,a2,4
    800026fa:	fea714e3          	bne	a4,a0,800026e2 <wait+0x66>
          freeproc(pp);
    800026fe:	8526                	mv	a0,s1
    80002700:	fffff097          	auipc	ra,0xfffff
    80002704:	5c4080e7          	jalr	1476(ra) # 80001cc4 <freeproc>
          release(&pp->lock);
    80002708:	8526                	mv	a0,s1
    8000270a:	ffffe097          	auipc	ra,0xffffe
    8000270e:	580080e7          	jalr	1408(ra) # 80000c8a <release>
          release(&wait_lock);
    80002712:	0000e517          	auipc	a0,0xe
    80002716:	48650513          	addi	a0,a0,1158 # 80010b98 <wait_lock>
    8000271a:	ffffe097          	auipc	ra,0xffffe
    8000271e:	570080e7          	jalr	1392(ra) # 80000c8a <release>
          return pid;
    80002722:	a051                	j	800027a6 <wait+0x12a>
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002724:	4691                	li	a3,4
    80002726:	02c48613          	addi	a2,s1,44
    8000272a:	85da                	mv	a1,s6
    8000272c:	05093503          	ld	a0,80(s2)
    80002730:	fffff097          	auipc	ra,0xfffff
    80002734:	f38080e7          	jalr	-200(ra) # 80001668 <copyout>
    80002738:	fa0551e3          	bgez	a0,800026da <wait+0x5e>
            release(&pp->lock);
    8000273c:	8526                	mv	a0,s1
    8000273e:	ffffe097          	auipc	ra,0xffffe
    80002742:	54c080e7          	jalr	1356(ra) # 80000c8a <release>
            release(&wait_lock);
    80002746:	0000e517          	auipc	a0,0xe
    8000274a:	45250513          	addi	a0,a0,1106 # 80010b98 <wait_lock>
    8000274e:	ffffe097          	auipc	ra,0xffffe
    80002752:	53c080e7          	jalr	1340(ra) # 80000c8a <release>
            return -1;
    80002756:	59fd                	li	s3,-1
    80002758:	a0b9                	j	800027a6 <wait+0x12a>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    8000275a:	21848493          	addi	s1,s1,536
    8000275e:	03348463          	beq	s1,s3,80002786 <wait+0x10a>
      if (pp->parent == p)
    80002762:	7c9c                	ld	a5,56(s1)
    80002764:	ff279be3          	bne	a5,s2,8000275a <wait+0xde>
        acquire(&pp->lock);
    80002768:	8526                	mv	a0,s1
    8000276a:	ffffe097          	auipc	ra,0xffffe
    8000276e:	46c080e7          	jalr	1132(ra) # 80000bd6 <acquire>
        if (pp->state == ZOMBIE)
    80002772:	4c9c                	lw	a5,24(s1)
    80002774:	f5478fe3          	beq	a5,s4,800026d2 <wait+0x56>
        release(&pp->lock);
    80002778:	8526                	mv	a0,s1
    8000277a:	ffffe097          	auipc	ra,0xffffe
    8000277e:	510080e7          	jalr	1296(ra) # 80000c8a <release>
        havekids = 1;
    80002782:	8756                	mv	a4,s5
    80002784:	bfd9                	j	8000275a <wait+0xde>
    if (!havekids || killed(p))
    80002786:	c719                	beqz	a4,80002794 <wait+0x118>
    80002788:	854a                	mv	a0,s2
    8000278a:	00000097          	auipc	ra,0x0
    8000278e:	ec0080e7          	jalr	-320(ra) # 8000264a <killed>
    80002792:	c51d                	beqz	a0,800027c0 <wait+0x144>
      release(&wait_lock);
    80002794:	0000e517          	auipc	a0,0xe
    80002798:	40450513          	addi	a0,a0,1028 # 80010b98 <wait_lock>
    8000279c:	ffffe097          	auipc	ra,0xffffe
    800027a0:	4ee080e7          	jalr	1262(ra) # 80000c8a <release>
      return -1;
    800027a4:	59fd                	li	s3,-1
}
    800027a6:	854e                	mv	a0,s3
    800027a8:	60a6                	ld	ra,72(sp)
    800027aa:	6406                	ld	s0,64(sp)
    800027ac:	74e2                	ld	s1,56(sp)
    800027ae:	7942                	ld	s2,48(sp)
    800027b0:	79a2                	ld	s3,40(sp)
    800027b2:	7a02                	ld	s4,32(sp)
    800027b4:	6ae2                	ld	s5,24(sp)
    800027b6:	6b42                	ld	s6,16(sp)
    800027b8:	6ba2                	ld	s7,8(sp)
    800027ba:	6c02                	ld	s8,0(sp)
    800027bc:	6161                	addi	sp,sp,80
    800027be:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    800027c0:	85e2                	mv	a1,s8
    800027c2:	854a                	mv	a0,s2
    800027c4:	00000097          	auipc	ra,0x0
    800027c8:	bbe080e7          	jalr	-1090(ra) # 80002382 <sleep>
    havekids = 0;
    800027cc:	bded                	j	800026c6 <wait+0x4a>

00000000800027ce <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800027ce:	7179                	addi	sp,sp,-48
    800027d0:	f406                	sd	ra,40(sp)
    800027d2:	f022                	sd	s0,32(sp)
    800027d4:	ec26                	sd	s1,24(sp)
    800027d6:	e84a                	sd	s2,16(sp)
    800027d8:	e44e                	sd	s3,8(sp)
    800027da:	e052                	sd	s4,0(sp)
    800027dc:	1800                	addi	s0,sp,48
    800027de:	84aa                	mv	s1,a0
    800027e0:	892e                	mv	s2,a1
    800027e2:	89b2                	mv	s3,a2
    800027e4:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800027e6:	fffff097          	auipc	ra,0xfffff
    800027ea:	32c080e7          	jalr	812(ra) # 80001b12 <myproc>
  if (user_dst)
    800027ee:	c08d                	beqz	s1,80002810 <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    800027f0:	86d2                	mv	a3,s4
    800027f2:	864e                	mv	a2,s3
    800027f4:	85ca                	mv	a1,s2
    800027f6:	6928                	ld	a0,80(a0)
    800027f8:	fffff097          	auipc	ra,0xfffff
    800027fc:	e70080e7          	jalr	-400(ra) # 80001668 <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002800:	70a2                	ld	ra,40(sp)
    80002802:	7402                	ld	s0,32(sp)
    80002804:	64e2                	ld	s1,24(sp)
    80002806:	6942                	ld	s2,16(sp)
    80002808:	69a2                	ld	s3,8(sp)
    8000280a:	6a02                	ld	s4,0(sp)
    8000280c:	6145                	addi	sp,sp,48
    8000280e:	8082                	ret
    memmove((char *)dst, src, len);
    80002810:	000a061b          	sext.w	a2,s4
    80002814:	85ce                	mv	a1,s3
    80002816:	854a                	mv	a0,s2
    80002818:	ffffe097          	auipc	ra,0xffffe
    8000281c:	516080e7          	jalr	1302(ra) # 80000d2e <memmove>
    return 0;
    80002820:	8526                	mv	a0,s1
    80002822:	bff9                	j	80002800 <either_copyout+0x32>

0000000080002824 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002824:	7179                	addi	sp,sp,-48
    80002826:	f406                	sd	ra,40(sp)
    80002828:	f022                	sd	s0,32(sp)
    8000282a:	ec26                	sd	s1,24(sp)
    8000282c:	e84a                	sd	s2,16(sp)
    8000282e:	e44e                	sd	s3,8(sp)
    80002830:	e052                	sd	s4,0(sp)
    80002832:	1800                	addi	s0,sp,48
    80002834:	892a                	mv	s2,a0
    80002836:	84ae                	mv	s1,a1
    80002838:	89b2                	mv	s3,a2
    8000283a:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000283c:	fffff097          	auipc	ra,0xfffff
    80002840:	2d6080e7          	jalr	726(ra) # 80001b12 <myproc>
  if (user_src)
    80002844:	c08d                	beqz	s1,80002866 <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    80002846:	86d2                	mv	a3,s4
    80002848:	864e                	mv	a2,s3
    8000284a:	85ca                	mv	a1,s2
    8000284c:	6928                	ld	a0,80(a0)
    8000284e:	fffff097          	auipc	ra,0xfffff
    80002852:	ea6080e7          	jalr	-346(ra) # 800016f4 <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    80002856:	70a2                	ld	ra,40(sp)
    80002858:	7402                	ld	s0,32(sp)
    8000285a:	64e2                	ld	s1,24(sp)
    8000285c:	6942                	ld	s2,16(sp)
    8000285e:	69a2                	ld	s3,8(sp)
    80002860:	6a02                	ld	s4,0(sp)
    80002862:	6145                	addi	sp,sp,48
    80002864:	8082                	ret
    memmove(dst, (char *)src, len);
    80002866:	000a061b          	sext.w	a2,s4
    8000286a:	85ce                	mv	a1,s3
    8000286c:	854a                	mv	a0,s2
    8000286e:	ffffe097          	auipc	ra,0xffffe
    80002872:	4c0080e7          	jalr	1216(ra) # 80000d2e <memmove>
    return 0;
    80002876:	8526                	mv	a0,s1
    80002878:	bff9                	j	80002856 <either_copyin+0x32>

000000008000287a <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    8000287a:	715d                	addi	sp,sp,-80
    8000287c:	e486                	sd	ra,72(sp)
    8000287e:	e0a2                	sd	s0,64(sp)
    80002880:	fc26                	sd	s1,56(sp)
    80002882:	f84a                	sd	s2,48(sp)
    80002884:	f44e                	sd	s3,40(sp)
    80002886:	f052                	sd	s4,32(sp)
    80002888:	ec56                	sd	s5,24(sp)
    8000288a:	e85a                	sd	s6,16(sp)
    8000288c:	e45e                	sd	s7,8(sp)
    8000288e:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    80002890:	00006517          	auipc	a0,0x6
    80002894:	83850513          	addi	a0,a0,-1992 # 800080c8 <digits+0x88>
    80002898:	ffffe097          	auipc	ra,0xffffe
    8000289c:	cf0080e7          	jalr	-784(ra) # 80000588 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    800028a0:	0000f497          	auipc	s1,0xf
    800028a4:	07848493          	addi	s1,s1,120 # 80011918 <proc+0x158>
    800028a8:	00017917          	auipc	s2,0x17
    800028ac:	67090913          	addi	s2,s2,1648 # 80019f18 <bcache+0x140>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028b0:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800028b2:	00006997          	auipc	s3,0x6
    800028b6:	9de98993          	addi	s3,s3,-1570 # 80008290 <digits+0x250>
    printf("%d %s %s", p->pid, state, p->name);
    800028ba:	00006a97          	auipc	s5,0x6
    800028be:	9dea8a93          	addi	s5,s5,-1570 # 80008298 <digits+0x258>
    printf("\n");
    800028c2:	00006a17          	auipc	s4,0x6
    800028c6:	806a0a13          	addi	s4,s4,-2042 # 800080c8 <digits+0x88>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028ca:	00006b97          	auipc	s7,0x6
    800028ce:	a0eb8b93          	addi	s7,s7,-1522 # 800082d8 <states.0>
    800028d2:	a00d                	j	800028f4 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800028d4:	ed86a583          	lw	a1,-296(a3)
    800028d8:	8556                	mv	a0,s5
    800028da:	ffffe097          	auipc	ra,0xffffe
    800028de:	cae080e7          	jalr	-850(ra) # 80000588 <printf>
    printf("\n");
    800028e2:	8552                	mv	a0,s4
    800028e4:	ffffe097          	auipc	ra,0xffffe
    800028e8:	ca4080e7          	jalr	-860(ra) # 80000588 <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    800028ec:	21848493          	addi	s1,s1,536
    800028f0:	03248163          	beq	s1,s2,80002912 <procdump+0x98>
    if (p->state == UNUSED)
    800028f4:	86a6                	mv	a3,s1
    800028f6:	ec04a783          	lw	a5,-320(s1)
    800028fa:	dbed                	beqz	a5,800028ec <procdump+0x72>
      state = "???";
    800028fc:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028fe:	fcfb6be3          	bltu	s6,a5,800028d4 <procdump+0x5a>
    80002902:	1782                	slli	a5,a5,0x20
    80002904:	9381                	srli	a5,a5,0x20
    80002906:	078e                	slli	a5,a5,0x3
    80002908:	97de                	add	a5,a5,s7
    8000290a:	6390                	ld	a2,0(a5)
    8000290c:	f661                	bnez	a2,800028d4 <procdump+0x5a>
      state = "???";
    8000290e:	864e                	mv	a2,s3
    80002910:	b7d1                	j	800028d4 <procdump+0x5a>
  }
}
    80002912:	60a6                	ld	ra,72(sp)
    80002914:	6406                	ld	s0,64(sp)
    80002916:	74e2                	ld	s1,56(sp)
    80002918:	7942                	ld	s2,48(sp)
    8000291a:	79a2                	ld	s3,40(sp)
    8000291c:	7a02                	ld	s4,32(sp)
    8000291e:	6ae2                	ld	s5,24(sp)
    80002920:	6b42                	ld	s6,16(sp)
    80002922:	6ba2                	ld	s7,8(sp)
    80002924:	6161                	addi	sp,sp,80
    80002926:	8082                	ret

0000000080002928 <waitx>:

// waitx
int waitx(uint64 addr, uint *wtime, uint *rtime)
{
    80002928:	711d                	addi	sp,sp,-96
    8000292a:	ec86                	sd	ra,88(sp)
    8000292c:	e8a2                	sd	s0,80(sp)
    8000292e:	e4a6                	sd	s1,72(sp)
    80002930:	e0ca                	sd	s2,64(sp)
    80002932:	fc4e                	sd	s3,56(sp)
    80002934:	f852                	sd	s4,48(sp)
    80002936:	f456                	sd	s5,40(sp)
    80002938:	f05a                	sd	s6,32(sp)
    8000293a:	ec5e                	sd	s7,24(sp)
    8000293c:	e862                	sd	s8,16(sp)
    8000293e:	e466                	sd	s9,8(sp)
    80002940:	e06a                	sd	s10,0(sp)
    80002942:	1080                	addi	s0,sp,96
    80002944:	8b2a                	mv	s6,a0
    80002946:	8bae                	mv	s7,a1
    80002948:	8c32                	mv	s8,a2
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();
    8000294a:	fffff097          	auipc	ra,0xfffff
    8000294e:	1c8080e7          	jalr	456(ra) # 80001b12 <myproc>
    80002952:	892a                	mv	s2,a0

  acquire(&wait_lock);
    80002954:	0000e517          	auipc	a0,0xe
    80002958:	24450513          	addi	a0,a0,580 # 80010b98 <wait_lock>
    8000295c:	ffffe097          	auipc	ra,0xffffe
    80002960:	27a080e7          	jalr	634(ra) # 80000bd6 <acquire>

  for (;;)
  {
    // Scan through table looking for exited children.
    havekids = 0;
    80002964:	4c81                	li	s9,0
      {
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if (np->state == ZOMBIE)
    80002966:	4a15                	li	s4,5
        havekids = 1;
    80002968:	4a85                	li	s5,1
    for (np = proc; np < &proc[NPROC]; np++)
    8000296a:	00017997          	auipc	s3,0x17
    8000296e:	45698993          	addi	s3,s3,1110 # 80019dc0 <tickslock>
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002972:	0000ed17          	auipc	s10,0xe
    80002976:	226d0d13          	addi	s10,s10,550 # 80010b98 <wait_lock>
    havekids = 0;
    8000297a:	8766                	mv	a4,s9
    for (np = proc; np < &proc[NPROC]; np++)
    8000297c:	0000f497          	auipc	s1,0xf
    80002980:	e4448493          	addi	s1,s1,-444 # 800117c0 <proc>
    80002984:	a059                	j	80002a0a <waitx+0xe2>
          pid = np->pid;
    80002986:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;
    8000298a:	1684a703          	lw	a4,360(s1)
    8000298e:	00ec2023          	sw	a4,0(s8)
          *wtime = np->etime - np->ctime - np->rtime;
    80002992:	16c4a783          	lw	a5,364(s1)
    80002996:	9f3d                	addw	a4,a4,a5
    80002998:	1704a783          	lw	a5,368(s1)
    8000299c:	9f99                	subw	a5,a5,a4
    8000299e:	00fba023          	sw	a5,0(s7)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800029a2:	000b0e63          	beqz	s6,800029be <waitx+0x96>
    800029a6:	4691                	li	a3,4
    800029a8:	02c48613          	addi	a2,s1,44
    800029ac:	85da                	mv	a1,s6
    800029ae:	05093503          	ld	a0,80(s2)
    800029b2:	fffff097          	auipc	ra,0xfffff
    800029b6:	cb6080e7          	jalr	-842(ra) # 80001668 <copyout>
    800029ba:	02054563          	bltz	a0,800029e4 <waitx+0xbc>
          freeproc(np);
    800029be:	8526                	mv	a0,s1
    800029c0:	fffff097          	auipc	ra,0xfffff
    800029c4:	304080e7          	jalr	772(ra) # 80001cc4 <freeproc>
          release(&np->lock);
    800029c8:	8526                	mv	a0,s1
    800029ca:	ffffe097          	auipc	ra,0xffffe
    800029ce:	2c0080e7          	jalr	704(ra) # 80000c8a <release>
          release(&wait_lock);
    800029d2:	0000e517          	auipc	a0,0xe
    800029d6:	1c650513          	addi	a0,a0,454 # 80010b98 <wait_lock>
    800029da:	ffffe097          	auipc	ra,0xffffe
    800029de:	2b0080e7          	jalr	688(ra) # 80000c8a <release>
          return pid;
    800029e2:	a09d                	j	80002a48 <waitx+0x120>
            release(&np->lock);
    800029e4:	8526                	mv	a0,s1
    800029e6:	ffffe097          	auipc	ra,0xffffe
    800029ea:	2a4080e7          	jalr	676(ra) # 80000c8a <release>
            release(&wait_lock);
    800029ee:	0000e517          	auipc	a0,0xe
    800029f2:	1aa50513          	addi	a0,a0,426 # 80010b98 <wait_lock>
    800029f6:	ffffe097          	auipc	ra,0xffffe
    800029fa:	294080e7          	jalr	660(ra) # 80000c8a <release>
            return -1;
    800029fe:	59fd                	li	s3,-1
    80002a00:	a0a1                	j	80002a48 <waitx+0x120>
    for (np = proc; np < &proc[NPROC]; np++)
    80002a02:	21848493          	addi	s1,s1,536
    80002a06:	03348463          	beq	s1,s3,80002a2e <waitx+0x106>
      if (np->parent == p)
    80002a0a:	7c9c                	ld	a5,56(s1)
    80002a0c:	ff279be3          	bne	a5,s2,80002a02 <waitx+0xda>
        acquire(&np->lock);
    80002a10:	8526                	mv	a0,s1
    80002a12:	ffffe097          	auipc	ra,0xffffe
    80002a16:	1c4080e7          	jalr	452(ra) # 80000bd6 <acquire>
        if (np->state == ZOMBIE)
    80002a1a:	4c9c                	lw	a5,24(s1)
    80002a1c:	f74785e3          	beq	a5,s4,80002986 <waitx+0x5e>
        release(&np->lock);
    80002a20:	8526                	mv	a0,s1
    80002a22:	ffffe097          	auipc	ra,0xffffe
    80002a26:	268080e7          	jalr	616(ra) # 80000c8a <release>
        havekids = 1;
    80002a2a:	8756                	mv	a4,s5
    80002a2c:	bfd9                	j	80002a02 <waitx+0xda>
    if (!havekids || p->killed)
    80002a2e:	c701                	beqz	a4,80002a36 <waitx+0x10e>
    80002a30:	02892783          	lw	a5,40(s2)
    80002a34:	cb8d                	beqz	a5,80002a66 <waitx+0x13e>
      release(&wait_lock);
    80002a36:	0000e517          	auipc	a0,0xe
    80002a3a:	16250513          	addi	a0,a0,354 # 80010b98 <wait_lock>
    80002a3e:	ffffe097          	auipc	ra,0xffffe
    80002a42:	24c080e7          	jalr	588(ra) # 80000c8a <release>
      return -1;
    80002a46:	59fd                	li	s3,-1
  }
}
    80002a48:	854e                	mv	a0,s3
    80002a4a:	60e6                	ld	ra,88(sp)
    80002a4c:	6446                	ld	s0,80(sp)
    80002a4e:	64a6                	ld	s1,72(sp)
    80002a50:	6906                	ld	s2,64(sp)
    80002a52:	79e2                	ld	s3,56(sp)
    80002a54:	7a42                	ld	s4,48(sp)
    80002a56:	7aa2                	ld	s5,40(sp)
    80002a58:	7b02                	ld	s6,32(sp)
    80002a5a:	6be2                	ld	s7,24(sp)
    80002a5c:	6c42                	ld	s8,16(sp)
    80002a5e:	6ca2                	ld	s9,8(sp)
    80002a60:	6d02                	ld	s10,0(sp)
    80002a62:	6125                	addi	sp,sp,96
    80002a64:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002a66:	85ea                	mv	a1,s10
    80002a68:	854a                	mv	a0,s2
    80002a6a:	00000097          	auipc	ra,0x0
    80002a6e:	918080e7          	jalr	-1768(ra) # 80002382 <sleep>
    havekids = 0;
    80002a72:	b721                	j	8000297a <waitx+0x52>

0000000080002a74 <update_time>:

void update_time()
{
    80002a74:	7179                	addi	sp,sp,-48
    80002a76:	f406                	sd	ra,40(sp)
    80002a78:	f022                	sd	s0,32(sp)
    80002a7a:	ec26                	sd	s1,24(sp)
    80002a7c:	e84a                	sd	s2,16(sp)
    80002a7e:	e44e                	sd	s3,8(sp)
    80002a80:	1800                	addi	s0,sp,48
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
    80002a82:	0000f497          	auipc	s1,0xf
    80002a86:	d3e48493          	addi	s1,s1,-706 # 800117c0 <proc>
  {
    acquire(&p->lock);
    if (p->state == RUNNING)
    80002a8a:	4991                	li	s3,4
  for (p = proc; p < &proc[NPROC]; p++)
    80002a8c:	00017917          	auipc	s2,0x17
    80002a90:	33490913          	addi	s2,s2,820 # 80019dc0 <tickslock>
    80002a94:	a811                	j	80002aa8 <update_time+0x34>
    {
      p->rtime++;
    }
    release(&p->lock);
    80002a96:	8526                	mv	a0,s1
    80002a98:	ffffe097          	auipc	ra,0xffffe
    80002a9c:	1f2080e7          	jalr	498(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002aa0:	21848493          	addi	s1,s1,536
    80002aa4:	03248063          	beq	s1,s2,80002ac4 <update_time+0x50>
    acquire(&p->lock);
    80002aa8:	8526                	mv	a0,s1
    80002aaa:	ffffe097          	auipc	ra,0xffffe
    80002aae:	12c080e7          	jalr	300(ra) # 80000bd6 <acquire>
    if (p->state == RUNNING)
    80002ab2:	4c9c                	lw	a5,24(s1)
    80002ab4:	ff3791e3          	bne	a5,s3,80002a96 <update_time+0x22>
      p->rtime++;
    80002ab8:	1684a783          	lw	a5,360(s1)
    80002abc:	2785                	addiw	a5,a5,1
    80002abe:	16f4a423          	sw	a5,360(s1)
    80002ac2:	bfd1                	j	80002a96 <update_time+0x22>
  }
}
    80002ac4:	70a2                	ld	ra,40(sp)
    80002ac6:	7402                	ld	s0,32(sp)
    80002ac8:	64e2                	ld	s1,24(sp)
    80002aca:	6942                	ld	s2,16(sp)
    80002acc:	69a2                	ld	s3,8(sp)
    80002ace:	6145                	addi	sp,sp,48
    80002ad0:	8082                	ret

0000000080002ad2 <swtch>:
    80002ad2:	00153023          	sd	ra,0(a0)
    80002ad6:	00253423          	sd	sp,8(a0)
    80002ada:	e900                	sd	s0,16(a0)
    80002adc:	ed04                	sd	s1,24(a0)
    80002ade:	03253023          	sd	s2,32(a0)
    80002ae2:	03353423          	sd	s3,40(a0)
    80002ae6:	03453823          	sd	s4,48(a0)
    80002aea:	03553c23          	sd	s5,56(a0)
    80002aee:	05653023          	sd	s6,64(a0)
    80002af2:	05753423          	sd	s7,72(a0)
    80002af6:	05853823          	sd	s8,80(a0)
    80002afa:	05953c23          	sd	s9,88(a0)
    80002afe:	07a53023          	sd	s10,96(a0)
    80002b02:	07b53423          	sd	s11,104(a0)
    80002b06:	0005b083          	ld	ra,0(a1)
    80002b0a:	0085b103          	ld	sp,8(a1)
    80002b0e:	6980                	ld	s0,16(a1)
    80002b10:	6d84                	ld	s1,24(a1)
    80002b12:	0205b903          	ld	s2,32(a1)
    80002b16:	0285b983          	ld	s3,40(a1)
    80002b1a:	0305ba03          	ld	s4,48(a1)
    80002b1e:	0385ba83          	ld	s5,56(a1)
    80002b22:	0405bb03          	ld	s6,64(a1)
    80002b26:	0485bb83          	ld	s7,72(a1)
    80002b2a:	0505bc03          	ld	s8,80(a1)
    80002b2e:	0585bc83          	ld	s9,88(a1)
    80002b32:	0605bd03          	ld	s10,96(a1)
    80002b36:	0685bd83          	ld	s11,104(a1)
    80002b3a:	8082                	ret

0000000080002b3c <trapinit>:
void kernelvec();

extern int devintr();

void trapinit(void)
{
    80002b3c:	1141                	addi	sp,sp,-16
    80002b3e:	e406                	sd	ra,8(sp)
    80002b40:	e022                	sd	s0,0(sp)
    80002b42:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002b44:	00005597          	auipc	a1,0x5
    80002b48:	7c458593          	addi	a1,a1,1988 # 80008308 <states.0+0x30>
    80002b4c:	00017517          	auipc	a0,0x17
    80002b50:	27450513          	addi	a0,a0,628 # 80019dc0 <tickslock>
    80002b54:	ffffe097          	auipc	ra,0xffffe
    80002b58:	ff2080e7          	jalr	-14(ra) # 80000b46 <initlock>
}
    80002b5c:	60a2                	ld	ra,8(sp)
    80002b5e:	6402                	ld	s0,0(sp)
    80002b60:	0141                	addi	sp,sp,16
    80002b62:	8082                	ret

0000000080002b64 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    80002b64:	1141                	addi	sp,sp,-16
    80002b66:	e422                	sd	s0,8(sp)
    80002b68:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b6a:	00003797          	auipc	a5,0x3
    80002b6e:	72678793          	addi	a5,a5,1830 # 80006290 <kernelvec>
    80002b72:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002b76:	6422                	ld	s0,8(sp)
    80002b78:	0141                	addi	sp,sp,16
    80002b7a:	8082                	ret

0000000080002b7c <usertrapret>:
}
//
// return to user space
//
void usertrapret(void)
{
    80002b7c:	1141                	addi	sp,sp,-16
    80002b7e:	e406                	sd	ra,8(sp)
    80002b80:	e022                	sd	s0,0(sp)
    80002b82:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002b84:	fffff097          	auipc	ra,0xfffff
    80002b88:	f8e080e7          	jalr	-114(ra) # 80001b12 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b8c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002b90:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b92:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002b96:	00004617          	auipc	a2,0x4
    80002b9a:	46a60613          	addi	a2,a2,1130 # 80007000 <_trampoline>
    80002b9e:	00004697          	auipc	a3,0x4
    80002ba2:	46268693          	addi	a3,a3,1122 # 80007000 <_trampoline>
    80002ba6:	8e91                	sub	a3,a3,a2
    80002ba8:	040007b7          	lui	a5,0x4000
    80002bac:	17fd                	addi	a5,a5,-1
    80002bae:	07b2                	slli	a5,a5,0xc
    80002bb0:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002bb2:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002bb6:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002bb8:	180026f3          	csrr	a3,satp
    80002bbc:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002bbe:	6d38                	ld	a4,88(a0)
    80002bc0:	6134                	ld	a3,64(a0)
    80002bc2:	6585                	lui	a1,0x1
    80002bc4:	96ae                	add	a3,a3,a1
    80002bc6:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002bc8:	6d38                	ld	a4,88(a0)
    80002bca:	00000697          	auipc	a3,0x0
    80002bce:	13e68693          	addi	a3,a3,318 # 80002d08 <usertrap>
    80002bd2:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    80002bd4:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002bd6:	8692                	mv	a3,tp
    80002bd8:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bda:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002bde:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002be2:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002be6:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002bea:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002bec:	6f18                	ld	a4,24(a4)
    80002bee:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002bf2:	6928                	ld	a0,80(a0)
    80002bf4:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002bf6:	00004717          	auipc	a4,0x4
    80002bfa:	4a670713          	addi	a4,a4,1190 # 8000709c <userret>
    80002bfe:	8f11                	sub	a4,a4,a2
    80002c00:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002c02:	577d                	li	a4,-1
    80002c04:	177e                	slli	a4,a4,0x3f
    80002c06:	8d59                	or	a0,a0,a4
    80002c08:	9782                	jalr	a5
}
    80002c0a:	60a2                	ld	ra,8(sp)
    80002c0c:	6402                	ld	s0,0(sp)
    80002c0e:	0141                	addi	sp,sp,16
    80002c10:	8082                	ret

0000000080002c12 <clockintr>:
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void clockintr()
{
    80002c12:	1101                	addi	sp,sp,-32
    80002c14:	ec06                	sd	ra,24(sp)
    80002c16:	e822                	sd	s0,16(sp)
    80002c18:	e426                	sd	s1,8(sp)
    80002c1a:	e04a                	sd	s2,0(sp)
    80002c1c:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002c1e:	00017917          	auipc	s2,0x17
    80002c22:	1a290913          	addi	s2,s2,418 # 80019dc0 <tickslock>
    80002c26:	854a                	mv	a0,s2
    80002c28:	ffffe097          	auipc	ra,0xffffe
    80002c2c:	fae080e7          	jalr	-82(ra) # 80000bd6 <acquire>
  ticks++;
    80002c30:	00006497          	auipc	s1,0x6
    80002c34:	ce048493          	addi	s1,s1,-800 # 80008910 <ticks>
    80002c38:	409c                	lw	a5,0(s1)
    80002c3a:	2785                	addiw	a5,a5,1
    80002c3c:	c09c                	sw	a5,0(s1)
  update_time();
    80002c3e:	00000097          	auipc	ra,0x0
    80002c42:	e36080e7          	jalr	-458(ra) # 80002a74 <update_time>
  //   // {
  //   //   p->wtime++;
  //   // }
  //   release(&p->lock);
  // }
  wakeup(&ticks);
    80002c46:	8526                	mv	a0,s1
    80002c48:	fffff097          	auipc	ra,0xfffff
    80002c4c:	79e080e7          	jalr	1950(ra) # 800023e6 <wakeup>
  release(&tickslock);
    80002c50:	854a                	mv	a0,s2
    80002c52:	ffffe097          	auipc	ra,0xffffe
    80002c56:	038080e7          	jalr	56(ra) # 80000c8a <release>
}
    80002c5a:	60e2                	ld	ra,24(sp)
    80002c5c:	6442                	ld	s0,16(sp)
    80002c5e:	64a2                	ld	s1,8(sp)
    80002c60:	6902                	ld	s2,0(sp)
    80002c62:	6105                	addi	sp,sp,32
    80002c64:	8082                	ret

0000000080002c66 <devintr>:
// and handle it.
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int devintr()
{
    80002c66:	1101                	addi	sp,sp,-32
    80002c68:	ec06                	sd	ra,24(sp)
    80002c6a:	e822                	sd	s0,16(sp)
    80002c6c:	e426                	sd	s1,8(sp)
    80002c6e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c70:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if ((scause & 0x8000000000000000L) &&
    80002c74:	00074d63          	bltz	a4,80002c8e <devintr+0x28>
    if (irq)
      plic_complete(irq);

    return 1;
  }
  else if (scause == 0x8000000000000001L)
    80002c78:	57fd                	li	a5,-1
    80002c7a:	17fe                	slli	a5,a5,0x3f
    80002c7c:	0785                	addi	a5,a5,1

    return 2;
  }
  else
  {
    return 0;
    80002c7e:	4501                	li	a0,0
  else if (scause == 0x8000000000000001L)
    80002c80:	06f70363          	beq	a4,a5,80002ce6 <devintr+0x80>
  }
}
    80002c84:	60e2                	ld	ra,24(sp)
    80002c86:	6442                	ld	s0,16(sp)
    80002c88:	64a2                	ld	s1,8(sp)
    80002c8a:	6105                	addi	sp,sp,32
    80002c8c:	8082                	ret
      (scause & 0xff) == 9)
    80002c8e:	0ff77793          	andi	a5,a4,255
  if ((scause & 0x8000000000000000L) &&
    80002c92:	46a5                	li	a3,9
    80002c94:	fed792e3          	bne	a5,a3,80002c78 <devintr+0x12>
    int irq = plic_claim();
    80002c98:	00003097          	auipc	ra,0x3
    80002c9c:	700080e7          	jalr	1792(ra) # 80006398 <plic_claim>
    80002ca0:	84aa                	mv	s1,a0
    if (irq == UART0_IRQ)
    80002ca2:	47a9                	li	a5,10
    80002ca4:	02f50763          	beq	a0,a5,80002cd2 <devintr+0x6c>
    else if (irq == VIRTIO0_IRQ)
    80002ca8:	4785                	li	a5,1
    80002caa:	02f50963          	beq	a0,a5,80002cdc <devintr+0x76>
    return 1;
    80002cae:	4505                	li	a0,1
    else if (irq)
    80002cb0:	d8f1                	beqz	s1,80002c84 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002cb2:	85a6                	mv	a1,s1
    80002cb4:	00005517          	auipc	a0,0x5
    80002cb8:	65c50513          	addi	a0,a0,1628 # 80008310 <states.0+0x38>
    80002cbc:	ffffe097          	auipc	ra,0xffffe
    80002cc0:	8cc080e7          	jalr	-1844(ra) # 80000588 <printf>
      plic_complete(irq);
    80002cc4:	8526                	mv	a0,s1
    80002cc6:	00003097          	auipc	ra,0x3
    80002cca:	6f6080e7          	jalr	1782(ra) # 800063bc <plic_complete>
    return 1;
    80002cce:	4505                	li	a0,1
    80002cd0:	bf55                	j	80002c84 <devintr+0x1e>
      uartintr();
    80002cd2:	ffffe097          	auipc	ra,0xffffe
    80002cd6:	cc8080e7          	jalr	-824(ra) # 8000099a <uartintr>
    80002cda:	b7ed                	j	80002cc4 <devintr+0x5e>
      virtio_disk_intr();
    80002cdc:	00004097          	auipc	ra,0x4
    80002ce0:	bac080e7          	jalr	-1108(ra) # 80006888 <virtio_disk_intr>
    80002ce4:	b7c5                	j	80002cc4 <devintr+0x5e>
    if (cpuid() == 0)
    80002ce6:	fffff097          	auipc	ra,0xfffff
    80002cea:	e00080e7          	jalr	-512(ra) # 80001ae6 <cpuid>
    80002cee:	c901                	beqz	a0,80002cfe <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002cf0:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002cf4:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002cf6:	14479073          	csrw	sip,a5
    return 2;
    80002cfa:	4509                	li	a0,2
    80002cfc:	b761                	j	80002c84 <devintr+0x1e>
      clockintr();
    80002cfe:	00000097          	auipc	ra,0x0
    80002d02:	f14080e7          	jalr	-236(ra) # 80002c12 <clockintr>
    80002d06:	b7ed                	j	80002cf0 <devintr+0x8a>

0000000080002d08 <usertrap>:
{
    80002d08:	1101                	addi	sp,sp,-32
    80002d0a:	ec06                	sd	ra,24(sp)
    80002d0c:	e822                	sd	s0,16(sp)
    80002d0e:	e426                	sd	s1,8(sp)
    80002d10:	e04a                	sd	s2,0(sp)
    80002d12:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002d14:	100027f3          	csrr	a5,sstatus
  if ((r_sstatus() & SSTATUS_SPP) != 0)
    80002d18:	1007f793          	andi	a5,a5,256
    80002d1c:	ebad                	bnez	a5,80002d8e <usertrap+0x86>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002d1e:	00003797          	auipc	a5,0x3
    80002d22:	57278793          	addi	a5,a5,1394 # 80006290 <kernelvec>
    80002d26:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002d2a:	fffff097          	auipc	ra,0xfffff
    80002d2e:	de8080e7          	jalr	-536(ra) # 80001b12 <myproc>
    80002d32:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002d34:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d36:	14102773          	csrr	a4,sepc
    80002d3a:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002d3c:	14202773          	csrr	a4,scause
  if (r_scause() == 8)
    80002d40:	47a1                	li	a5,8
    80002d42:	04f70e63          	beq	a4,a5,80002d9e <usertrap+0x96>
  else if ((which_dev = devintr()) != 0)
    80002d46:	00000097          	auipc	ra,0x0
    80002d4a:	f20080e7          	jalr	-224(ra) # 80002c66 <devintr>
    80002d4e:	892a                	mv	s2,a0
    80002d50:	c569                	beqz	a0,80002e1a <usertrap+0x112>
    if (which_dev == 2)
    80002d52:	4789                	li	a5,2
    80002d54:	06f51963          	bne	a0,a5,80002dc6 <usertrap+0xbe>
          if(p->alarm)
    80002d58:	2004a783          	lw	a5,512(s1)
    80002d5c:	cf91                	beqz	a5,80002d78 <usertrap+0x70>
            p->tickcounter++;
    80002d5e:	1ec4a783          	lw	a5,492(s1)
    80002d62:	2785                	addiw	a5,a5,1
    80002d64:	0007871b          	sext.w	a4,a5
    80002d68:	1ef4a623          	sw	a5,492(s1)
            if(p->alarmticks>0&&p->tickcounter>=p->alarmticks)
    80002d6c:	1e84a783          	lw	a5,488(s1)
    80002d70:	00f05463          	blez	a5,80002d78 <usertrap+0x70>
    80002d74:	06f75f63          	bge	a4,a5,80002df2 <usertrap+0xea>
    if (killed(p))
    80002d78:	8526                	mv	a0,s1
    80002d7a:	00000097          	auipc	ra,0x0
    80002d7e:	8d0080e7          	jalr	-1840(ra) # 8000264a <killed>
    80002d82:	e175                	bnez	a0,80002e66 <usertrap+0x15e>
      yield();
    80002d84:	fffff097          	auipc	ra,0xfffff
    80002d88:	5c2080e7          	jalr	1474(ra) # 80002346 <yield>
    80002d8c:	a099                	j	80002dd2 <usertrap+0xca>
    panic("usertrap: not from user mode");
    80002d8e:	00005517          	auipc	a0,0x5
    80002d92:	5a250513          	addi	a0,a0,1442 # 80008330 <states.0+0x58>
    80002d96:	ffffd097          	auipc	ra,0xffffd
    80002d9a:	7a8080e7          	jalr	1960(ra) # 8000053e <panic>
    if (killed(p))
    80002d9e:	00000097          	auipc	ra,0x0
    80002da2:	8ac080e7          	jalr	-1876(ra) # 8000264a <killed>
    80002da6:	e121                	bnez	a0,80002de6 <usertrap+0xde>
    p->trapframe->epc += 4;
    80002da8:	6cb8                	ld	a4,88(s1)
    80002daa:	6f1c                	ld	a5,24(a4)
    80002dac:	0791                	addi	a5,a5,4
    80002dae:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002db0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002db4:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002db8:	10079073          	csrw	sstatus,a5
    syscall();
    80002dbc:	00000097          	auipc	ra,0x0
    80002dc0:	300080e7          	jalr	768(ra) # 800030bc <syscall>
  int which_dev = 0;
    80002dc4:	4901                	li	s2,0
    if (killed(p))
    80002dc6:	8526                	mv	a0,s1
    80002dc8:	00000097          	auipc	ra,0x0
    80002dcc:	882080e7          	jalr	-1918(ra) # 8000264a <killed>
    80002dd0:	e151                	bnez	a0,80002e54 <usertrap+0x14c>
    usertrapret();
    80002dd2:	00000097          	auipc	ra,0x0
    80002dd6:	daa080e7          	jalr	-598(ra) # 80002b7c <usertrapret>
}
    80002dda:	60e2                	ld	ra,24(sp)
    80002ddc:	6442                	ld	s0,16(sp)
    80002dde:	64a2                	ld	s1,8(sp)
    80002de0:	6902                	ld	s2,0(sp)
    80002de2:	6105                	addi	sp,sp,32
    80002de4:	8082                	ret
      exit(-1);
    80002de6:	557d                	li	a0,-1
    80002de8:	fffff097          	auipc	ra,0xfffff
    80002dec:	6d8080e7          	jalr	1752(ra) # 800024c0 <exit>
    80002df0:	bf65                	j	80002da8 <usertrap+0xa0>
              p->alarm=0;
    80002df2:	2004a023          	sw	zero,512(s1)
              struct trapframe* temp = kalloc();
    80002df6:	ffffe097          	auipc	ra,0xffffe
    80002dfa:	cf0080e7          	jalr	-784(ra) # 80000ae6 <kalloc>
    80002dfe:	892a                	mv	s2,a0
              memmove(temp,p->trapframe,PGSIZE);
    80002e00:	6605                	lui	a2,0x1
    80002e02:	6cac                	ld	a1,88(s1)
    80002e04:	ffffe097          	auipc	ra,0xffffe
    80002e08:	f2a080e7          	jalr	-214(ra) # 80000d2e <memmove>
              p->savedtf=temp;
    80002e0c:	1f24bc23          	sd	s2,504(s1)
              p->trapframe->epc=p->handler;
    80002e10:	6cbc                	ld	a5,88(s1)
    80002e12:	1f04b703          	ld	a4,496(s1)
    80002e16:	ef98                	sd	a4,24(a5)
    80002e18:	b785                	j	80002d78 <usertrap+0x70>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e1a:	142025f3          	csrr	a1,scause
        printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002e1e:	5890                	lw	a2,48(s1)
    80002e20:	00005517          	auipc	a0,0x5
    80002e24:	53050513          	addi	a0,a0,1328 # 80008350 <states.0+0x78>
    80002e28:	ffffd097          	auipc	ra,0xffffd
    80002e2c:	760080e7          	jalr	1888(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e30:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002e34:	14302673          	csrr	a2,stval
        printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002e38:	00005517          	auipc	a0,0x5
    80002e3c:	54850513          	addi	a0,a0,1352 # 80008380 <states.0+0xa8>
    80002e40:	ffffd097          	auipc	ra,0xffffd
    80002e44:	748080e7          	jalr	1864(ra) # 80000588 <printf>
        setkilled(p);
    80002e48:	8526                	mv	a0,s1
    80002e4a:	fffff097          	auipc	ra,0xfffff
    80002e4e:	7d4080e7          	jalr	2004(ra) # 8000261e <setkilled>
    80002e52:	bf95                	j	80002dc6 <usertrap+0xbe>
        exit(-1);
    80002e54:	557d                	li	a0,-1
    80002e56:	fffff097          	auipc	ra,0xfffff
    80002e5a:	66a080e7          	jalr	1642(ra) # 800024c0 <exit>
    if (which_dev == 2)
    80002e5e:	4789                	li	a5,2
    80002e60:	f6f919e3          	bne	s2,a5,80002dd2 <usertrap+0xca>
    80002e64:	b705                	j	80002d84 <usertrap+0x7c>
        exit(-1);
    80002e66:	557d                	li	a0,-1
    80002e68:	fffff097          	auipc	ra,0xfffff
    80002e6c:	658080e7          	jalr	1624(ra) # 800024c0 <exit>
    if (which_dev == 2)
    80002e70:	bf11                	j	80002d84 <usertrap+0x7c>

0000000080002e72 <kerneltrap>:
{
    80002e72:	7179                	addi	sp,sp,-48
    80002e74:	f406                	sd	ra,40(sp)
    80002e76:	f022                	sd	s0,32(sp)
    80002e78:	ec26                	sd	s1,24(sp)
    80002e7a:	e84a                	sd	s2,16(sp)
    80002e7c:	e44e                	sd	s3,8(sp)
    80002e7e:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002e80:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e84:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002e88:	142029f3          	csrr	s3,scause
  if ((sstatus & SSTATUS_SPP) == 0)
    80002e8c:	1004f793          	andi	a5,s1,256
    80002e90:	cb85                	beqz	a5,80002ec0 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002e92:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002e96:	8b89                	andi	a5,a5,2
  if (intr_get() != 0)
    80002e98:	ef85                	bnez	a5,80002ed0 <kerneltrap+0x5e>
  if ((which_dev = devintr()) == 0)
    80002e9a:	00000097          	auipc	ra,0x0
    80002e9e:	dcc080e7          	jalr	-564(ra) # 80002c66 <devintr>
    80002ea2:	cd1d                	beqz	a0,80002ee0 <kerneltrap+0x6e>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002ea4:	4789                	li	a5,2
    80002ea6:	06f50a63          	beq	a0,a5,80002f1a <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002eaa:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002eae:	10049073          	csrw	sstatus,s1
}
    80002eb2:	70a2                	ld	ra,40(sp)
    80002eb4:	7402                	ld	s0,32(sp)
    80002eb6:	64e2                	ld	s1,24(sp)
    80002eb8:	6942                	ld	s2,16(sp)
    80002eba:	69a2                	ld	s3,8(sp)
    80002ebc:	6145                	addi	sp,sp,48
    80002ebe:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002ec0:	00005517          	auipc	a0,0x5
    80002ec4:	4e050513          	addi	a0,a0,1248 # 800083a0 <states.0+0xc8>
    80002ec8:	ffffd097          	auipc	ra,0xffffd
    80002ecc:	676080e7          	jalr	1654(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002ed0:	00005517          	auipc	a0,0x5
    80002ed4:	4f850513          	addi	a0,a0,1272 # 800083c8 <states.0+0xf0>
    80002ed8:	ffffd097          	auipc	ra,0xffffd
    80002edc:	666080e7          	jalr	1638(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002ee0:	85ce                	mv	a1,s3
    80002ee2:	00005517          	auipc	a0,0x5
    80002ee6:	50650513          	addi	a0,a0,1286 # 800083e8 <states.0+0x110>
    80002eea:	ffffd097          	auipc	ra,0xffffd
    80002eee:	69e080e7          	jalr	1694(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ef2:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002ef6:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002efa:	00005517          	auipc	a0,0x5
    80002efe:	4fe50513          	addi	a0,a0,1278 # 800083f8 <states.0+0x120>
    80002f02:	ffffd097          	auipc	ra,0xffffd
    80002f06:	686080e7          	jalr	1670(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002f0a:	00005517          	auipc	a0,0x5
    80002f0e:	50650513          	addi	a0,a0,1286 # 80008410 <states.0+0x138>
    80002f12:	ffffd097          	auipc	ra,0xffffd
    80002f16:	62c080e7          	jalr	1580(ra) # 8000053e <panic>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002f1a:	fffff097          	auipc	ra,0xfffff
    80002f1e:	bf8080e7          	jalr	-1032(ra) # 80001b12 <myproc>
    80002f22:	d541                	beqz	a0,80002eaa <kerneltrap+0x38>
    80002f24:	fffff097          	auipc	ra,0xfffff
    80002f28:	bee080e7          	jalr	-1042(ra) # 80001b12 <myproc>
    80002f2c:	4d18                	lw	a4,24(a0)
    80002f2e:	4791                	li	a5,4
    80002f30:	f6f71de3          	bne	a4,a5,80002eaa <kerneltrap+0x38>
    yield();
    80002f34:	fffff097          	auipc	ra,0xfffff
    80002f38:	412080e7          	jalr	1042(ra) # 80002346 <yield>
    80002f3c:	b7bd                	j	80002eaa <kerneltrap+0x38>

0000000080002f3e <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002f3e:	1101                	addi	sp,sp,-32
    80002f40:	ec06                	sd	ra,24(sp)
    80002f42:	e822                	sd	s0,16(sp)
    80002f44:	e426                	sd	s1,8(sp)
    80002f46:	1000                	addi	s0,sp,32
    80002f48:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002f4a:	fffff097          	auipc	ra,0xfffff
    80002f4e:	bc8080e7          	jalr	-1080(ra) # 80001b12 <myproc>
  switch (n) {
    80002f52:	4795                	li	a5,5
    80002f54:	0497e163          	bltu	a5,s1,80002f96 <argraw+0x58>
    80002f58:	048a                	slli	s1,s1,0x2
    80002f5a:	00005717          	auipc	a4,0x5
    80002f5e:	4ee70713          	addi	a4,a4,1262 # 80008448 <states.0+0x170>
    80002f62:	94ba                	add	s1,s1,a4
    80002f64:	409c                	lw	a5,0(s1)
    80002f66:	97ba                	add	a5,a5,a4
    80002f68:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002f6a:	6d3c                	ld	a5,88(a0)
    80002f6c:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002f6e:	60e2                	ld	ra,24(sp)
    80002f70:	6442                	ld	s0,16(sp)
    80002f72:	64a2                	ld	s1,8(sp)
    80002f74:	6105                	addi	sp,sp,32
    80002f76:	8082                	ret
    return p->trapframe->a1;
    80002f78:	6d3c                	ld	a5,88(a0)
    80002f7a:	7fa8                	ld	a0,120(a5)
    80002f7c:	bfcd                	j	80002f6e <argraw+0x30>
    return p->trapframe->a2;
    80002f7e:	6d3c                	ld	a5,88(a0)
    80002f80:	63c8                	ld	a0,128(a5)
    80002f82:	b7f5                	j	80002f6e <argraw+0x30>
    return p->trapframe->a3;
    80002f84:	6d3c                	ld	a5,88(a0)
    80002f86:	67c8                	ld	a0,136(a5)
    80002f88:	b7dd                	j	80002f6e <argraw+0x30>
    return p->trapframe->a4;
    80002f8a:	6d3c                	ld	a5,88(a0)
    80002f8c:	6bc8                	ld	a0,144(a5)
    80002f8e:	b7c5                	j	80002f6e <argraw+0x30>
    return p->trapframe->a5;
    80002f90:	6d3c                	ld	a5,88(a0)
    80002f92:	6fc8                	ld	a0,152(a5)
    80002f94:	bfe9                	j	80002f6e <argraw+0x30>
  panic("argraw");
    80002f96:	00005517          	auipc	a0,0x5
    80002f9a:	48a50513          	addi	a0,a0,1162 # 80008420 <states.0+0x148>
    80002f9e:	ffffd097          	auipc	ra,0xffffd
    80002fa2:	5a0080e7          	jalr	1440(ra) # 8000053e <panic>

0000000080002fa6 <fetchaddr>:
{
    80002fa6:	1101                	addi	sp,sp,-32
    80002fa8:	ec06                	sd	ra,24(sp)
    80002faa:	e822                	sd	s0,16(sp)
    80002fac:	e426                	sd	s1,8(sp)
    80002fae:	e04a                	sd	s2,0(sp)
    80002fb0:	1000                	addi	s0,sp,32
    80002fb2:	84aa                	mv	s1,a0
    80002fb4:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002fb6:	fffff097          	auipc	ra,0xfffff
    80002fba:	b5c080e7          	jalr	-1188(ra) # 80001b12 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002fbe:	653c                	ld	a5,72(a0)
    80002fc0:	02f4f863          	bgeu	s1,a5,80002ff0 <fetchaddr+0x4a>
    80002fc4:	00848713          	addi	a4,s1,8
    80002fc8:	02e7e663          	bltu	a5,a4,80002ff4 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002fcc:	46a1                	li	a3,8
    80002fce:	8626                	mv	a2,s1
    80002fd0:	85ca                	mv	a1,s2
    80002fd2:	6928                	ld	a0,80(a0)
    80002fd4:	ffffe097          	auipc	ra,0xffffe
    80002fd8:	720080e7          	jalr	1824(ra) # 800016f4 <copyin>
    80002fdc:	00a03533          	snez	a0,a0
    80002fe0:	40a00533          	neg	a0,a0
}
    80002fe4:	60e2                	ld	ra,24(sp)
    80002fe6:	6442                	ld	s0,16(sp)
    80002fe8:	64a2                	ld	s1,8(sp)
    80002fea:	6902                	ld	s2,0(sp)
    80002fec:	6105                	addi	sp,sp,32
    80002fee:	8082                	ret
    return -1;
    80002ff0:	557d                	li	a0,-1
    80002ff2:	bfcd                	j	80002fe4 <fetchaddr+0x3e>
    80002ff4:	557d                	li	a0,-1
    80002ff6:	b7fd                	j	80002fe4 <fetchaddr+0x3e>

0000000080002ff8 <fetchstr>:
{
    80002ff8:	7179                	addi	sp,sp,-48
    80002ffa:	f406                	sd	ra,40(sp)
    80002ffc:	f022                	sd	s0,32(sp)
    80002ffe:	ec26                	sd	s1,24(sp)
    80003000:	e84a                	sd	s2,16(sp)
    80003002:	e44e                	sd	s3,8(sp)
    80003004:	1800                	addi	s0,sp,48
    80003006:	892a                	mv	s2,a0
    80003008:	84ae                	mv	s1,a1
    8000300a:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    8000300c:	fffff097          	auipc	ra,0xfffff
    80003010:	b06080e7          	jalr	-1274(ra) # 80001b12 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80003014:	86ce                	mv	a3,s3
    80003016:	864a                	mv	a2,s2
    80003018:	85a6                	mv	a1,s1
    8000301a:	6928                	ld	a0,80(a0)
    8000301c:	ffffe097          	auipc	ra,0xffffe
    80003020:	766080e7          	jalr	1894(ra) # 80001782 <copyinstr>
    80003024:	00054e63          	bltz	a0,80003040 <fetchstr+0x48>
  return strlen(buf);
    80003028:	8526                	mv	a0,s1
    8000302a:	ffffe097          	auipc	ra,0xffffe
    8000302e:	e24080e7          	jalr	-476(ra) # 80000e4e <strlen>
}
    80003032:	70a2                	ld	ra,40(sp)
    80003034:	7402                	ld	s0,32(sp)
    80003036:	64e2                	ld	s1,24(sp)
    80003038:	6942                	ld	s2,16(sp)
    8000303a:	69a2                	ld	s3,8(sp)
    8000303c:	6145                	addi	sp,sp,48
    8000303e:	8082                	ret
    return -1;
    80003040:	557d                	li	a0,-1
    80003042:	bfc5                	j	80003032 <fetchstr+0x3a>

0000000080003044 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80003044:	1101                	addi	sp,sp,-32
    80003046:	ec06                	sd	ra,24(sp)
    80003048:	e822                	sd	s0,16(sp)
    8000304a:	e426                	sd	s1,8(sp)
    8000304c:	1000                	addi	s0,sp,32
    8000304e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003050:	00000097          	auipc	ra,0x0
    80003054:	eee080e7          	jalr	-274(ra) # 80002f3e <argraw>
    80003058:	c088                	sw	a0,0(s1)
}
    8000305a:	60e2                	ld	ra,24(sp)
    8000305c:	6442                	ld	s0,16(sp)
    8000305e:	64a2                	ld	s1,8(sp)
    80003060:	6105                	addi	sp,sp,32
    80003062:	8082                	ret

0000000080003064 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80003064:	1101                	addi	sp,sp,-32
    80003066:	ec06                	sd	ra,24(sp)
    80003068:	e822                	sd	s0,16(sp)
    8000306a:	e426                	sd	s1,8(sp)
    8000306c:	1000                	addi	s0,sp,32
    8000306e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003070:	00000097          	auipc	ra,0x0
    80003074:	ece080e7          	jalr	-306(ra) # 80002f3e <argraw>
    80003078:	e088                	sd	a0,0(s1)
}
    8000307a:	60e2                	ld	ra,24(sp)
    8000307c:	6442                	ld	s0,16(sp)
    8000307e:	64a2                	ld	s1,8(sp)
    80003080:	6105                	addi	sp,sp,32
    80003082:	8082                	ret

0000000080003084 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80003084:	7179                	addi	sp,sp,-48
    80003086:	f406                	sd	ra,40(sp)
    80003088:	f022                	sd	s0,32(sp)
    8000308a:	ec26                	sd	s1,24(sp)
    8000308c:	e84a                	sd	s2,16(sp)
    8000308e:	1800                	addi	s0,sp,48
    80003090:	84ae                	mv	s1,a1
    80003092:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80003094:	fd840593          	addi	a1,s0,-40
    80003098:	00000097          	auipc	ra,0x0
    8000309c:	fcc080e7          	jalr	-52(ra) # 80003064 <argaddr>
  return fetchstr(addr, buf, max);
    800030a0:	864a                	mv	a2,s2
    800030a2:	85a6                	mv	a1,s1
    800030a4:	fd843503          	ld	a0,-40(s0)
    800030a8:	00000097          	auipc	ra,0x0
    800030ac:	f50080e7          	jalr	-176(ra) # 80002ff8 <fetchstr>
}
    800030b0:	70a2                	ld	ra,40(sp)
    800030b2:	7402                	ld	s0,32(sp)
    800030b4:	64e2                	ld	s1,24(sp)
    800030b6:	6942                	ld	s2,16(sp)
    800030b8:	6145                	addi	sp,sp,48
    800030ba:	8082                	ret

00000000800030bc <syscall>:
[SYS_settickets] sys_settickets,
};

void
syscall(void)
{
    800030bc:	1101                	addi	sp,sp,-32
    800030be:	ec06                	sd	ra,24(sp)
    800030c0:	e822                	sd	s0,16(sp)
    800030c2:	e426                	sd	s1,8(sp)
    800030c4:	e04a                	sd	s2,0(sp)
    800030c6:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    800030c8:	fffff097          	auipc	ra,0xfffff
    800030cc:	a4a080e7          	jalr	-1462(ra) # 80001b12 <myproc>
    800030d0:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    800030d2:	05853903          	ld	s2,88(a0)
    800030d6:	0a893783          	ld	a5,168(s2)
    800030da:	0007869b          	sext.w	a3,a5
  // printf("%d\n",num);
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    800030de:	37fd                	addiw	a5,a5,-1
    800030e0:	4765                	li	a4,25
    800030e2:	02f76763          	bltu	a4,a5,80003110 <syscall+0x54>
    800030e6:	00369713          	slli	a4,a3,0x3
    800030ea:	00005797          	auipc	a5,0x5
    800030ee:	37678793          	addi	a5,a5,886 # 80008460 <syscalls>
    800030f2:	97ba                	add	a5,a5,a4
    800030f4:	6398                	ld	a4,0(a5)
    800030f6:	cf09                	beqz	a4,80003110 <syscall+0x54>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->syscall_count[num-1]++;
    800030f8:	068a                	slli	a3,a3,0x2
    800030fa:	00d504b3          	add	s1,a0,a3
    800030fe:	1704a783          	lw	a5,368(s1)
    80003102:	2785                	addiw	a5,a5,1
    80003104:	16f4a823          	sw	a5,368(s1)
    p->trapframe->a0 = syscalls[num]();
    80003108:	9702                	jalr	a4
    8000310a:	06a93823          	sd	a0,112(s2)
    8000310e:	a839                	j	8000312c <syscall+0x70>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80003110:	15848613          	addi	a2,s1,344
    80003114:	588c                	lw	a1,48(s1)
    80003116:	00005517          	auipc	a0,0x5
    8000311a:	31250513          	addi	a0,a0,786 # 80008428 <states.0+0x150>
    8000311e:	ffffd097          	auipc	ra,0xffffd
    80003122:	46a080e7          	jalr	1130(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003126:	6cbc                	ld	a5,88(s1)
    80003128:	577d                	li	a4,-1
    8000312a:	fbb8                	sd	a4,112(a5)
  }
}
    8000312c:	60e2                	ld	ra,24(sp)
    8000312e:	6442                	ld	s0,16(sp)
    80003130:	64a2                	ld	s1,8(sp)
    80003132:	6902                	ld	s2,0(sp)
    80003134:	6105                	addi	sp,sp,32
    80003136:	8082                	ret

0000000080003138 <argptr>:
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "proc.h"

int argptr(int n, void **pp, int size) {
    80003138:	7139                	addi	sp,sp,-64
    8000313a:	fc06                	sd	ra,56(sp)
    8000313c:	f822                	sd	s0,48(sp)
    8000313e:	f426                	sd	s1,40(sp)
    80003140:	f04a                	sd	s2,32(sp)
    80003142:	ec4e                	sd	s3,24(sp)
    80003144:	0080                	addi	s0,sp,64
    80003146:	84aa                	mv	s1,a0
    80003148:	89ae                	mv	s3,a1
    8000314a:	8932                	mv	s2,a2
    uint64 addr;
    argint(n, (int*)&addr);
    8000314c:	fc840593          	addi	a1,s0,-56
    80003150:	00000097          	auipc	ra,0x0
    80003154:	ef4080e7          	jalr	-268(ra) # 80003044 <argint>
    if(n<0)
    80003158:	0204c063          	bltz	s1,80003178 <argptr+0x40>
    return -1;
    if (size < 0)
    8000315c:	02094063          	bltz	s2,8000317c <argptr+0x44>
        return -1; // Check bounds
    *pp = (void *)addr; // Set the pointer
    80003160:	fc843783          	ld	a5,-56(s0)
    80003164:	00f9b023          	sd	a5,0(s3)
    return 0;
    80003168:	4501                	li	a0,0
}
    8000316a:	70e2                	ld	ra,56(sp)
    8000316c:	7442                	ld	s0,48(sp)
    8000316e:	74a2                	ld	s1,40(sp)
    80003170:	7902                	ld	s2,32(sp)
    80003172:	69e2                	ld	s3,24(sp)
    80003174:	6121                	addi	sp,sp,64
    80003176:	8082                	ret
    return -1;
    80003178:	557d                	li	a0,-1
    8000317a:	bfc5                	j	8000316a <argptr+0x32>
        return -1; // Check bounds
    8000317c:	557d                	li	a0,-1
    8000317e:	b7f5                	j	8000316a <argptr+0x32>

0000000080003180 <sys_exit>:

uint64
sys_exit(void)
{
    80003180:	1101                	addi	sp,sp,-32
    80003182:	ec06                	sd	ra,24(sp)
    80003184:	e822                	sd	s0,16(sp)
    80003186:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80003188:	fec40593          	addi	a1,s0,-20
    8000318c:	4501                	li	a0,0
    8000318e:	00000097          	auipc	ra,0x0
    80003192:	eb6080e7          	jalr	-330(ra) # 80003044 <argint>
  exit(n);
    80003196:	fec42503          	lw	a0,-20(s0)
    8000319a:	fffff097          	auipc	ra,0xfffff
    8000319e:	326080e7          	jalr	806(ra) # 800024c0 <exit>
  return 0; // not reached
}
    800031a2:	4501                	li	a0,0
    800031a4:	60e2                	ld	ra,24(sp)
    800031a6:	6442                	ld	s0,16(sp)
    800031a8:	6105                	addi	sp,sp,32
    800031aa:	8082                	ret

00000000800031ac <sys_getpid>:

uint64
sys_getpid(void)
{
    800031ac:	1141                	addi	sp,sp,-16
    800031ae:	e406                	sd	ra,8(sp)
    800031b0:	e022                	sd	s0,0(sp)
    800031b2:	0800                	addi	s0,sp,16
  return myproc()->pid;
    800031b4:	fffff097          	auipc	ra,0xfffff
    800031b8:	95e080e7          	jalr	-1698(ra) # 80001b12 <myproc>
}
    800031bc:	5908                	lw	a0,48(a0)
    800031be:	60a2                	ld	ra,8(sp)
    800031c0:	6402                	ld	s0,0(sp)
    800031c2:	0141                	addi	sp,sp,16
    800031c4:	8082                	ret

00000000800031c6 <sys_fork>:

uint64
sys_fork(void)
{
    800031c6:	1141                	addi	sp,sp,-16
    800031c8:	e406                	sd	ra,8(sp)
    800031ca:	e022                	sd	s0,0(sp)
    800031cc:	0800                	addi	s0,sp,16
  return fork();
    800031ce:	fffff097          	auipc	ra,0xfffff
    800031d2:	d62080e7          	jalr	-670(ra) # 80001f30 <fork>
}
    800031d6:	60a2                	ld	ra,8(sp)
    800031d8:	6402                	ld	s0,0(sp)
    800031da:	0141                	addi	sp,sp,16
    800031dc:	8082                	ret

00000000800031de <sys_wait>:

uint64
sys_wait(void)
{
    800031de:	1101                	addi	sp,sp,-32
    800031e0:	ec06                	sd	ra,24(sp)
    800031e2:	e822                	sd	s0,16(sp)
    800031e4:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    800031e6:	fe840593          	addi	a1,s0,-24
    800031ea:	4501                	li	a0,0
    800031ec:	00000097          	auipc	ra,0x0
    800031f0:	e78080e7          	jalr	-392(ra) # 80003064 <argaddr>
  return wait(p);
    800031f4:	fe843503          	ld	a0,-24(s0)
    800031f8:	fffff097          	auipc	ra,0xfffff
    800031fc:	484080e7          	jalr	1156(ra) # 8000267c <wait>
}
    80003200:	60e2                	ld	ra,24(sp)
    80003202:	6442                	ld	s0,16(sp)
    80003204:	6105                	addi	sp,sp,32
    80003206:	8082                	ret

0000000080003208 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003208:	7179                	addi	sp,sp,-48
    8000320a:	f406                	sd	ra,40(sp)
    8000320c:	f022                	sd	s0,32(sp)
    8000320e:	ec26                	sd	s1,24(sp)
    80003210:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80003212:	fdc40593          	addi	a1,s0,-36
    80003216:	4501                	li	a0,0
    80003218:	00000097          	auipc	ra,0x0
    8000321c:	e2c080e7          	jalr	-468(ra) # 80003044 <argint>
  addr = myproc()->sz;
    80003220:	fffff097          	auipc	ra,0xfffff
    80003224:	8f2080e7          	jalr	-1806(ra) # 80001b12 <myproc>
    80003228:	6524                	ld	s1,72(a0)
  if (growproc(n) < 0)
    8000322a:	fdc42503          	lw	a0,-36(s0)
    8000322e:	fffff097          	auipc	ra,0xfffff
    80003232:	ca6080e7          	jalr	-858(ra) # 80001ed4 <growproc>
    80003236:	00054863          	bltz	a0,80003246 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    8000323a:	8526                	mv	a0,s1
    8000323c:	70a2                	ld	ra,40(sp)
    8000323e:	7402                	ld	s0,32(sp)
    80003240:	64e2                	ld	s1,24(sp)
    80003242:	6145                	addi	sp,sp,48
    80003244:	8082                	ret
    return -1;
    80003246:	54fd                	li	s1,-1
    80003248:	bfcd                	j	8000323a <sys_sbrk+0x32>

000000008000324a <sys_sleep>:

uint64
sys_sleep(void)
{
    8000324a:	7139                	addi	sp,sp,-64
    8000324c:	fc06                	sd	ra,56(sp)
    8000324e:	f822                	sd	s0,48(sp)
    80003250:	f426                	sd	s1,40(sp)
    80003252:	f04a                	sd	s2,32(sp)
    80003254:	ec4e                	sd	s3,24(sp)
    80003256:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80003258:	fcc40593          	addi	a1,s0,-52
    8000325c:	4501                	li	a0,0
    8000325e:	00000097          	auipc	ra,0x0
    80003262:	de6080e7          	jalr	-538(ra) # 80003044 <argint>
  acquire(&tickslock);
    80003266:	00017517          	auipc	a0,0x17
    8000326a:	b5a50513          	addi	a0,a0,-1190 # 80019dc0 <tickslock>
    8000326e:	ffffe097          	auipc	ra,0xffffe
    80003272:	968080e7          	jalr	-1688(ra) # 80000bd6 <acquire>
  ticks0 = ticks;
    80003276:	00005917          	auipc	s2,0x5
    8000327a:	69a92903          	lw	s2,1690(s2) # 80008910 <ticks>
  while (ticks - ticks0 < n)
    8000327e:	fcc42783          	lw	a5,-52(s0)
    80003282:	cf9d                	beqz	a5,800032c0 <sys_sleep+0x76>
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003284:	00017997          	auipc	s3,0x17
    80003288:	b3c98993          	addi	s3,s3,-1220 # 80019dc0 <tickslock>
    8000328c:	00005497          	auipc	s1,0x5
    80003290:	68448493          	addi	s1,s1,1668 # 80008910 <ticks>
    if (killed(myproc()))
    80003294:	fffff097          	auipc	ra,0xfffff
    80003298:	87e080e7          	jalr	-1922(ra) # 80001b12 <myproc>
    8000329c:	fffff097          	auipc	ra,0xfffff
    800032a0:	3ae080e7          	jalr	942(ra) # 8000264a <killed>
    800032a4:	ed15                	bnez	a0,800032e0 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    800032a6:	85ce                	mv	a1,s3
    800032a8:	8526                	mv	a0,s1
    800032aa:	fffff097          	auipc	ra,0xfffff
    800032ae:	0d8080e7          	jalr	216(ra) # 80002382 <sleep>
  while (ticks - ticks0 < n)
    800032b2:	409c                	lw	a5,0(s1)
    800032b4:	412787bb          	subw	a5,a5,s2
    800032b8:	fcc42703          	lw	a4,-52(s0)
    800032bc:	fce7ece3          	bltu	a5,a4,80003294 <sys_sleep+0x4a>
  }
  release(&tickslock);
    800032c0:	00017517          	auipc	a0,0x17
    800032c4:	b0050513          	addi	a0,a0,-1280 # 80019dc0 <tickslock>
    800032c8:	ffffe097          	auipc	ra,0xffffe
    800032cc:	9c2080e7          	jalr	-1598(ra) # 80000c8a <release>
  return 0;
    800032d0:	4501                	li	a0,0
}
    800032d2:	70e2                	ld	ra,56(sp)
    800032d4:	7442                	ld	s0,48(sp)
    800032d6:	74a2                	ld	s1,40(sp)
    800032d8:	7902                	ld	s2,32(sp)
    800032da:	69e2                	ld	s3,24(sp)
    800032dc:	6121                	addi	sp,sp,64
    800032de:	8082                	ret
      release(&tickslock);
    800032e0:	00017517          	auipc	a0,0x17
    800032e4:	ae050513          	addi	a0,a0,-1312 # 80019dc0 <tickslock>
    800032e8:	ffffe097          	auipc	ra,0xffffe
    800032ec:	9a2080e7          	jalr	-1630(ra) # 80000c8a <release>
      return -1;
    800032f0:	557d                	li	a0,-1
    800032f2:	b7c5                	j	800032d2 <sys_sleep+0x88>

00000000800032f4 <sys_kill>:

uint64
sys_kill(void)
{
    800032f4:	1101                	addi	sp,sp,-32
    800032f6:	ec06                	sd	ra,24(sp)
    800032f8:	e822                	sd	s0,16(sp)
    800032fa:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    800032fc:	fec40593          	addi	a1,s0,-20
    80003300:	4501                	li	a0,0
    80003302:	00000097          	auipc	ra,0x0
    80003306:	d42080e7          	jalr	-702(ra) # 80003044 <argint>
  return kill(pid);
    8000330a:	fec42503          	lw	a0,-20(s0)
    8000330e:	fffff097          	auipc	ra,0xfffff
    80003312:	294080e7          	jalr	660(ra) # 800025a2 <kill>
}
    80003316:	60e2                	ld	ra,24(sp)
    80003318:	6442                	ld	s0,16(sp)
    8000331a:	6105                	addi	sp,sp,32
    8000331c:	8082                	ret

000000008000331e <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    8000331e:	1101                	addi	sp,sp,-32
    80003320:	ec06                	sd	ra,24(sp)
    80003322:	e822                	sd	s0,16(sp)
    80003324:	e426                	sd	s1,8(sp)
    80003326:	1000                	addi	s0,sp,32
  uint xticks;
  acquire(&tickslock);
    80003328:	00017517          	auipc	a0,0x17
    8000332c:	a9850513          	addi	a0,a0,-1384 # 80019dc0 <tickslock>
    80003330:	ffffe097          	auipc	ra,0xffffe
    80003334:	8a6080e7          	jalr	-1882(ra) # 80000bd6 <acquire>
  xticks = ticks;
    80003338:	00005497          	auipc	s1,0x5
    8000333c:	5d84a483          	lw	s1,1496(s1) # 80008910 <ticks>
  release(&tickslock);
    80003340:	00017517          	auipc	a0,0x17
    80003344:	a8050513          	addi	a0,a0,-1408 # 80019dc0 <tickslock>
    80003348:	ffffe097          	auipc	ra,0xffffe
    8000334c:	942080e7          	jalr	-1726(ra) # 80000c8a <release>
  return xticks;
}
    80003350:	02049513          	slli	a0,s1,0x20
    80003354:	9101                	srli	a0,a0,0x20
    80003356:	60e2                	ld	ra,24(sp)
    80003358:	6442                	ld	s0,16(sp)
    8000335a:	64a2                	ld	s1,8(sp)
    8000335c:	6105                	addi	sp,sp,32
    8000335e:	8082                	ret

0000000080003360 <sys_waitx>:

uint64
sys_waitx(void)
{
    80003360:	7139                	addi	sp,sp,-64
    80003362:	fc06                	sd	ra,56(sp)
    80003364:	f822                	sd	s0,48(sp)
    80003366:	f426                	sd	s1,40(sp)
    80003368:	f04a                	sd	s2,32(sp)
    8000336a:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
    8000336c:	fd840593          	addi	a1,s0,-40
    80003370:	4501                	li	a0,0
    80003372:	00000097          	auipc	ra,0x0
    80003376:	cf2080e7          	jalr	-782(ra) # 80003064 <argaddr>
  argaddr(1, &addr1); // user virtual memory
    8000337a:	fd040593          	addi	a1,s0,-48
    8000337e:	4505                	li	a0,1
    80003380:	00000097          	auipc	ra,0x0
    80003384:	ce4080e7          	jalr	-796(ra) # 80003064 <argaddr>
  argaddr(2, &addr2);
    80003388:	fc840593          	addi	a1,s0,-56
    8000338c:	4509                	li	a0,2
    8000338e:	00000097          	auipc	ra,0x0
    80003392:	cd6080e7          	jalr	-810(ra) # 80003064 <argaddr>
  int ret = waitx(addr, &wtime, &rtime);
    80003396:	fc040613          	addi	a2,s0,-64
    8000339a:	fc440593          	addi	a1,s0,-60
    8000339e:	fd843503          	ld	a0,-40(s0)
    800033a2:	fffff097          	auipc	ra,0xfffff
    800033a6:	586080e7          	jalr	1414(ra) # 80002928 <waitx>
    800033aa:	892a                	mv	s2,a0
  struct proc *p = myproc();
    800033ac:	ffffe097          	auipc	ra,0xffffe
    800033b0:	766080e7          	jalr	1894(ra) # 80001b12 <myproc>
    800033b4:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    800033b6:	4691                	li	a3,4
    800033b8:	fc440613          	addi	a2,s0,-60
    800033bc:	fd043583          	ld	a1,-48(s0)
    800033c0:	6928                	ld	a0,80(a0)
    800033c2:	ffffe097          	auipc	ra,0xffffe
    800033c6:	2a6080e7          	jalr	678(ra) # 80001668 <copyout>
    return -1;
    800033ca:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    800033cc:	00054f63          	bltz	a0,800033ea <sys_waitx+0x8a>
  if (copyout(p->pagetable, addr2, (char *)&rtime, sizeof(int)) < 0)
    800033d0:	4691                	li	a3,4
    800033d2:	fc040613          	addi	a2,s0,-64
    800033d6:	fc843583          	ld	a1,-56(s0)
    800033da:	68a8                	ld	a0,80(s1)
    800033dc:	ffffe097          	auipc	ra,0xffffe
    800033e0:	28c080e7          	jalr	652(ra) # 80001668 <copyout>
    800033e4:	00054a63          	bltz	a0,800033f8 <sys_waitx+0x98>
    return -1;
  return ret;
    800033e8:	87ca                	mv	a5,s2
}
    800033ea:	853e                	mv	a0,a5
    800033ec:	70e2                	ld	ra,56(sp)
    800033ee:	7442                	ld	s0,48(sp)
    800033f0:	74a2                	ld	s1,40(sp)
    800033f2:	7902                	ld	s2,32(sp)
    800033f4:	6121                	addi	sp,sp,64
    800033f6:	8082                	ret
    return -1;
    800033f8:	57fd                	li	a5,-1
    800033fa:	bfc5                	j	800033ea <sys_waitx+0x8a>

00000000800033fc <sys_getSysCount>:

uint64
sys_getSysCount(void)
{
    800033fc:	1101                	addi	sp,sp,-32
    800033fe:	ec06                	sd	ra,24(sp)
    80003400:	e822                	sd	s0,16(sp)
    80003402:	1000                	addi	s0,sp,32
  int k;
  argint(0,&k);
    80003404:	fec40593          	addi	a1,s0,-20
    80003408:	4501                	li	a0,0
    8000340a:	00000097          	auipc	ra,0x0
    8000340e:	c3a080e7          	jalr	-966(ra) # 80003044 <argint>
  struct proc *p = myproc();
    80003412:	ffffe097          	auipc	ra,0xffffe
    80003416:	700080e7          	jalr	1792(ra) # 80001b12 <myproc>
  return p->syscall_count[k];
    8000341a:	fec42783          	lw	a5,-20(s0)
    8000341e:	05c78793          	addi	a5,a5,92
    80003422:	078a                	slli	a5,a5,0x2
    80003424:	97aa                	add	a5,a5,a0
} 
    80003426:	43c8                	lw	a0,4(a5)
    80003428:	60e2                	ld	ra,24(sp)
    8000342a:	6442                	ld	s0,16(sp)
    8000342c:	6105                	addi	sp,sp,32
    8000342e:	8082                	ret

0000000080003430 <sys_sigalarm>:

uint64
sys_sigalarm(void)
{
    80003430:	1101                	addi	sp,sp,-32
    80003432:	ec06                	sd	ra,24(sp)
    80003434:	e822                	sd	s0,16(sp)
    80003436:	1000                	addi	s0,sp,32
  int interval;
  uint64 addr;

  argint(0, &interval);
    80003438:	fec40593          	addi	a1,s0,-20
    8000343c:	4501                	li	a0,0
    8000343e:	00000097          	auipc	ra,0x0
    80003442:	c06080e7          	jalr	-1018(ra) # 80003044 <argint>
    if(interval<0)
    80003446:	fec42783          	lw	a5,-20(s0)
    return -1;
    8000344a:	557d                	li	a0,-1
    if(interval<0)
    8000344c:	0207c963          	bltz	a5,8000347e <sys_sigalarm+0x4e>
  argaddr(1,&addr);
    80003450:	fe040593          	addi	a1,s0,-32
    80003454:	4505                	li	a0,1
    80003456:	00000097          	auipc	ra,0x0
    8000345a:	c0e080e7          	jalr	-1010(ra) # 80003064 <argaddr>

  struct proc *p = myproc();
    8000345e:	ffffe097          	auipc	ra,0xffffe
    80003462:	6b4080e7          	jalr	1716(ra) # 80001b12 <myproc>
  p->alarm=1;//means that we have called sigalarm so u start checking 
    80003466:	4785                	li	a5,1
    80003468:	20f52023          	sw	a5,512(a0)
  p->alarmticks = interval;
    8000346c:	fec42783          	lw	a5,-20(s0)
    80003470:	1ef52423          	sw	a5,488(a0)
  p->handler = addr;
    80003474:	fe043783          	ld	a5,-32(s0)
    80003478:	1ef53823          	sd	a5,496(a0)
  return 0;
    8000347c:	4501                	li	a0,0
}
    8000347e:	60e2                	ld	ra,24(sp)
    80003480:	6442                	ld	s0,16(sp)
    80003482:	6105                	addi	sp,sp,32
    80003484:	8082                	ret

0000000080003486 <sys_sigreturn>:

uint64
sys_sigreturn(void)
{
    80003486:	1101                	addi	sp,sp,-32
    80003488:	ec06                	sd	ra,24(sp)
    8000348a:	e822                	sd	s0,16(sp)
    8000348c:	e426                	sd	s1,8(sp)
    8000348e:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80003490:	ffffe097          	auipc	ra,0xffffe
    80003494:	682080e7          	jalr	1666(ra) # 80001b12 <myproc>
    80003498:	84aa                	mv	s1,a0
  memmove(p->trapframe,p->savedtf,PGSIZE);
    8000349a:	6605                	lui	a2,0x1
    8000349c:	1f853583          	ld	a1,504(a0)
    800034a0:	6d28                	ld	a0,88(a0)
    800034a2:	ffffe097          	auipc	ra,0xffffe
    800034a6:	88c080e7          	jalr	-1908(ra) # 80000d2e <memmove>
  kfree(p->savedtf);
    800034aa:	1f84b503          	ld	a0,504(s1)
    800034ae:	ffffd097          	auipc	ra,0xffffd
    800034b2:	53c080e7          	jalr	1340(ra) # 800009ea <kfree>
  p->tickcounter=0;
    800034b6:	1e04a623          	sw	zero,492(s1)
  p->alarm=1;
    800034ba:	4785                	li	a5,1
    800034bc:	20f4a023          	sw	a5,512(s1)
  usertrapret();  
    800034c0:	fffff097          	auipc	ra,0xfffff
    800034c4:	6bc080e7          	jalr	1724(ra) # 80002b7c <usertrapret>
  return 0;
}
    800034c8:	4501                	li	a0,0
    800034ca:	60e2                	ld	ra,24(sp)
    800034cc:	6442                	ld	s0,16(sp)
    800034ce:	64a2                	ld	s1,8(sp)
    800034d0:	6105                	addi	sp,sp,32
    800034d2:	8082                	ret

00000000800034d4 <sys_settickets>:

uint64
sys_settickets(void)
{
    800034d4:	1101                	addi	sp,sp,-32
    800034d6:	ec06                	sd	ra,24(sp)
    800034d8:	e822                	sd	s0,16(sp)
    800034da:	1000                	addi	s0,sp,32
  int k ;
  argint(0,&k);
    800034dc:	fec40593          	addi	a1,s0,-20
    800034e0:	4501                	li	a0,0
    800034e2:	00000097          	auipc	ra,0x0
    800034e6:	b62080e7          	jalr	-1182(ra) # 80003044 <argint>
  if(k<=0)
    800034ea:	fec42783          	lw	a5,-20(s0)
  return 0;
    800034ee:	4501                	li	a0,0
  if(k<=0)
    800034f0:	00f05b63          	blez	a5,80003506 <sys_settickets+0x32>
  struct proc *p = myproc();
    800034f4:	ffffe097          	auipc	ra,0xffffe
    800034f8:	61e080e7          	jalr	1566(ra) # 80001b12 <myproc>
  p->tickets=k;
    800034fc:	fec42783          	lw	a5,-20(s0)
    80003500:	20f52223          	sw	a5,516(a0)
  return 1;
    80003504:	4505                	li	a0,1
    80003506:	60e2                	ld	ra,24(sp)
    80003508:	6442                	ld	s0,16(sp)
    8000350a:	6105                	addi	sp,sp,32
    8000350c:	8082                	ret

000000008000350e <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000350e:	7179                	addi	sp,sp,-48
    80003510:	f406                	sd	ra,40(sp)
    80003512:	f022                	sd	s0,32(sp)
    80003514:	ec26                	sd	s1,24(sp)
    80003516:	e84a                	sd	s2,16(sp)
    80003518:	e44e                	sd	s3,8(sp)
    8000351a:	e052                	sd	s4,0(sp)
    8000351c:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000351e:	00005597          	auipc	a1,0x5
    80003522:	01a58593          	addi	a1,a1,26 # 80008538 <syscalls+0xd8>
    80003526:	00017517          	auipc	a0,0x17
    8000352a:	8b250513          	addi	a0,a0,-1870 # 80019dd8 <bcache>
    8000352e:	ffffd097          	auipc	ra,0xffffd
    80003532:	618080e7          	jalr	1560(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003536:	0001f797          	auipc	a5,0x1f
    8000353a:	8a278793          	addi	a5,a5,-1886 # 80021dd8 <bcache+0x8000>
    8000353e:	0001f717          	auipc	a4,0x1f
    80003542:	b0270713          	addi	a4,a4,-1278 # 80022040 <bcache+0x8268>
    80003546:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000354a:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000354e:	00017497          	auipc	s1,0x17
    80003552:	8a248493          	addi	s1,s1,-1886 # 80019df0 <bcache+0x18>
    b->next = bcache.head.next;
    80003556:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003558:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000355a:	00005a17          	auipc	s4,0x5
    8000355e:	fe6a0a13          	addi	s4,s4,-26 # 80008540 <syscalls+0xe0>
    b->next = bcache.head.next;
    80003562:	2b893783          	ld	a5,696(s2)
    80003566:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003568:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000356c:	85d2                	mv	a1,s4
    8000356e:	01048513          	addi	a0,s1,16
    80003572:	00001097          	auipc	ra,0x1
    80003576:	4c4080e7          	jalr	1220(ra) # 80004a36 <initsleeplock>
    bcache.head.next->prev = b;
    8000357a:	2b893783          	ld	a5,696(s2)
    8000357e:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003580:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003584:	45848493          	addi	s1,s1,1112
    80003588:	fd349de3          	bne	s1,s3,80003562 <binit+0x54>
  }
}
    8000358c:	70a2                	ld	ra,40(sp)
    8000358e:	7402                	ld	s0,32(sp)
    80003590:	64e2                	ld	s1,24(sp)
    80003592:	6942                	ld	s2,16(sp)
    80003594:	69a2                	ld	s3,8(sp)
    80003596:	6a02                	ld	s4,0(sp)
    80003598:	6145                	addi	sp,sp,48
    8000359a:	8082                	ret

000000008000359c <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    8000359c:	7179                	addi	sp,sp,-48
    8000359e:	f406                	sd	ra,40(sp)
    800035a0:	f022                	sd	s0,32(sp)
    800035a2:	ec26                	sd	s1,24(sp)
    800035a4:	e84a                	sd	s2,16(sp)
    800035a6:	e44e                	sd	s3,8(sp)
    800035a8:	1800                	addi	s0,sp,48
    800035aa:	892a                	mv	s2,a0
    800035ac:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    800035ae:	00017517          	auipc	a0,0x17
    800035b2:	82a50513          	addi	a0,a0,-2006 # 80019dd8 <bcache>
    800035b6:	ffffd097          	auipc	ra,0xffffd
    800035ba:	620080e7          	jalr	1568(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800035be:	0001f497          	auipc	s1,0x1f
    800035c2:	ad24b483          	ld	s1,-1326(s1) # 80022090 <bcache+0x82b8>
    800035c6:	0001f797          	auipc	a5,0x1f
    800035ca:	a7a78793          	addi	a5,a5,-1414 # 80022040 <bcache+0x8268>
    800035ce:	02f48f63          	beq	s1,a5,8000360c <bread+0x70>
    800035d2:	873e                	mv	a4,a5
    800035d4:	a021                	j	800035dc <bread+0x40>
    800035d6:	68a4                	ld	s1,80(s1)
    800035d8:	02e48a63          	beq	s1,a4,8000360c <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800035dc:	449c                	lw	a5,8(s1)
    800035de:	ff279ce3          	bne	a5,s2,800035d6 <bread+0x3a>
    800035e2:	44dc                	lw	a5,12(s1)
    800035e4:	ff3799e3          	bne	a5,s3,800035d6 <bread+0x3a>
      b->refcnt++;
    800035e8:	40bc                	lw	a5,64(s1)
    800035ea:	2785                	addiw	a5,a5,1
    800035ec:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800035ee:	00016517          	auipc	a0,0x16
    800035f2:	7ea50513          	addi	a0,a0,2026 # 80019dd8 <bcache>
    800035f6:	ffffd097          	auipc	ra,0xffffd
    800035fa:	694080e7          	jalr	1684(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    800035fe:	01048513          	addi	a0,s1,16
    80003602:	00001097          	auipc	ra,0x1
    80003606:	46e080e7          	jalr	1134(ra) # 80004a70 <acquiresleep>
      return b;
    8000360a:	a8b9                	j	80003668 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000360c:	0001f497          	auipc	s1,0x1f
    80003610:	a7c4b483          	ld	s1,-1412(s1) # 80022088 <bcache+0x82b0>
    80003614:	0001f797          	auipc	a5,0x1f
    80003618:	a2c78793          	addi	a5,a5,-1492 # 80022040 <bcache+0x8268>
    8000361c:	00f48863          	beq	s1,a5,8000362c <bread+0x90>
    80003620:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003622:	40bc                	lw	a5,64(s1)
    80003624:	cf81                	beqz	a5,8000363c <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003626:	64a4                	ld	s1,72(s1)
    80003628:	fee49de3          	bne	s1,a4,80003622 <bread+0x86>
  panic("bget: no buffers");
    8000362c:	00005517          	auipc	a0,0x5
    80003630:	f1c50513          	addi	a0,a0,-228 # 80008548 <syscalls+0xe8>
    80003634:	ffffd097          	auipc	ra,0xffffd
    80003638:	f0a080e7          	jalr	-246(ra) # 8000053e <panic>
      b->dev = dev;
    8000363c:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003640:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003644:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003648:	4785                	li	a5,1
    8000364a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000364c:	00016517          	auipc	a0,0x16
    80003650:	78c50513          	addi	a0,a0,1932 # 80019dd8 <bcache>
    80003654:	ffffd097          	auipc	ra,0xffffd
    80003658:	636080e7          	jalr	1590(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    8000365c:	01048513          	addi	a0,s1,16
    80003660:	00001097          	auipc	ra,0x1
    80003664:	410080e7          	jalr	1040(ra) # 80004a70 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003668:	409c                	lw	a5,0(s1)
    8000366a:	cb89                	beqz	a5,8000367c <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000366c:	8526                	mv	a0,s1
    8000366e:	70a2                	ld	ra,40(sp)
    80003670:	7402                	ld	s0,32(sp)
    80003672:	64e2                	ld	s1,24(sp)
    80003674:	6942                	ld	s2,16(sp)
    80003676:	69a2                	ld	s3,8(sp)
    80003678:	6145                	addi	sp,sp,48
    8000367a:	8082                	ret
    virtio_disk_rw(b, 0);
    8000367c:	4581                	li	a1,0
    8000367e:	8526                	mv	a0,s1
    80003680:	00003097          	auipc	ra,0x3
    80003684:	fd4080e7          	jalr	-44(ra) # 80006654 <virtio_disk_rw>
    b->valid = 1;
    80003688:	4785                	li	a5,1
    8000368a:	c09c                	sw	a5,0(s1)
  return b;
    8000368c:	b7c5                	j	8000366c <bread+0xd0>

000000008000368e <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000368e:	1101                	addi	sp,sp,-32
    80003690:	ec06                	sd	ra,24(sp)
    80003692:	e822                	sd	s0,16(sp)
    80003694:	e426                	sd	s1,8(sp)
    80003696:	1000                	addi	s0,sp,32
    80003698:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000369a:	0541                	addi	a0,a0,16
    8000369c:	00001097          	auipc	ra,0x1
    800036a0:	46e080e7          	jalr	1134(ra) # 80004b0a <holdingsleep>
    800036a4:	cd01                	beqz	a0,800036bc <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800036a6:	4585                	li	a1,1
    800036a8:	8526                	mv	a0,s1
    800036aa:	00003097          	auipc	ra,0x3
    800036ae:	faa080e7          	jalr	-86(ra) # 80006654 <virtio_disk_rw>
}
    800036b2:	60e2                	ld	ra,24(sp)
    800036b4:	6442                	ld	s0,16(sp)
    800036b6:	64a2                	ld	s1,8(sp)
    800036b8:	6105                	addi	sp,sp,32
    800036ba:	8082                	ret
    panic("bwrite");
    800036bc:	00005517          	auipc	a0,0x5
    800036c0:	ea450513          	addi	a0,a0,-348 # 80008560 <syscalls+0x100>
    800036c4:	ffffd097          	auipc	ra,0xffffd
    800036c8:	e7a080e7          	jalr	-390(ra) # 8000053e <panic>

00000000800036cc <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800036cc:	1101                	addi	sp,sp,-32
    800036ce:	ec06                	sd	ra,24(sp)
    800036d0:	e822                	sd	s0,16(sp)
    800036d2:	e426                	sd	s1,8(sp)
    800036d4:	e04a                	sd	s2,0(sp)
    800036d6:	1000                	addi	s0,sp,32
    800036d8:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800036da:	01050913          	addi	s2,a0,16
    800036de:	854a                	mv	a0,s2
    800036e0:	00001097          	auipc	ra,0x1
    800036e4:	42a080e7          	jalr	1066(ra) # 80004b0a <holdingsleep>
    800036e8:	c92d                	beqz	a0,8000375a <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800036ea:	854a                	mv	a0,s2
    800036ec:	00001097          	auipc	ra,0x1
    800036f0:	3da080e7          	jalr	986(ra) # 80004ac6 <releasesleep>

  acquire(&bcache.lock);
    800036f4:	00016517          	auipc	a0,0x16
    800036f8:	6e450513          	addi	a0,a0,1764 # 80019dd8 <bcache>
    800036fc:	ffffd097          	auipc	ra,0xffffd
    80003700:	4da080e7          	jalr	1242(ra) # 80000bd6 <acquire>
  b->refcnt--;
    80003704:	40bc                	lw	a5,64(s1)
    80003706:	37fd                	addiw	a5,a5,-1
    80003708:	0007871b          	sext.w	a4,a5
    8000370c:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000370e:	eb05                	bnez	a4,8000373e <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003710:	68bc                	ld	a5,80(s1)
    80003712:	64b8                	ld	a4,72(s1)
    80003714:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003716:	64bc                	ld	a5,72(s1)
    80003718:	68b8                	ld	a4,80(s1)
    8000371a:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000371c:	0001e797          	auipc	a5,0x1e
    80003720:	6bc78793          	addi	a5,a5,1724 # 80021dd8 <bcache+0x8000>
    80003724:	2b87b703          	ld	a4,696(a5)
    80003728:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000372a:	0001f717          	auipc	a4,0x1f
    8000372e:	91670713          	addi	a4,a4,-1770 # 80022040 <bcache+0x8268>
    80003732:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003734:	2b87b703          	ld	a4,696(a5)
    80003738:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000373a:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000373e:	00016517          	auipc	a0,0x16
    80003742:	69a50513          	addi	a0,a0,1690 # 80019dd8 <bcache>
    80003746:	ffffd097          	auipc	ra,0xffffd
    8000374a:	544080e7          	jalr	1348(ra) # 80000c8a <release>
}
    8000374e:	60e2                	ld	ra,24(sp)
    80003750:	6442                	ld	s0,16(sp)
    80003752:	64a2                	ld	s1,8(sp)
    80003754:	6902                	ld	s2,0(sp)
    80003756:	6105                	addi	sp,sp,32
    80003758:	8082                	ret
    panic("brelse");
    8000375a:	00005517          	auipc	a0,0x5
    8000375e:	e0e50513          	addi	a0,a0,-498 # 80008568 <syscalls+0x108>
    80003762:	ffffd097          	auipc	ra,0xffffd
    80003766:	ddc080e7          	jalr	-548(ra) # 8000053e <panic>

000000008000376a <bpin>:

void
bpin(struct buf *b) {
    8000376a:	1101                	addi	sp,sp,-32
    8000376c:	ec06                	sd	ra,24(sp)
    8000376e:	e822                	sd	s0,16(sp)
    80003770:	e426                	sd	s1,8(sp)
    80003772:	1000                	addi	s0,sp,32
    80003774:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003776:	00016517          	auipc	a0,0x16
    8000377a:	66250513          	addi	a0,a0,1634 # 80019dd8 <bcache>
    8000377e:	ffffd097          	auipc	ra,0xffffd
    80003782:	458080e7          	jalr	1112(ra) # 80000bd6 <acquire>
  b->refcnt++;
    80003786:	40bc                	lw	a5,64(s1)
    80003788:	2785                	addiw	a5,a5,1
    8000378a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000378c:	00016517          	auipc	a0,0x16
    80003790:	64c50513          	addi	a0,a0,1612 # 80019dd8 <bcache>
    80003794:	ffffd097          	auipc	ra,0xffffd
    80003798:	4f6080e7          	jalr	1270(ra) # 80000c8a <release>
}
    8000379c:	60e2                	ld	ra,24(sp)
    8000379e:	6442                	ld	s0,16(sp)
    800037a0:	64a2                	ld	s1,8(sp)
    800037a2:	6105                	addi	sp,sp,32
    800037a4:	8082                	ret

00000000800037a6 <bunpin>:

void
bunpin(struct buf *b) {
    800037a6:	1101                	addi	sp,sp,-32
    800037a8:	ec06                	sd	ra,24(sp)
    800037aa:	e822                	sd	s0,16(sp)
    800037ac:	e426                	sd	s1,8(sp)
    800037ae:	1000                	addi	s0,sp,32
    800037b0:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800037b2:	00016517          	auipc	a0,0x16
    800037b6:	62650513          	addi	a0,a0,1574 # 80019dd8 <bcache>
    800037ba:	ffffd097          	auipc	ra,0xffffd
    800037be:	41c080e7          	jalr	1052(ra) # 80000bd6 <acquire>
  b->refcnt--;
    800037c2:	40bc                	lw	a5,64(s1)
    800037c4:	37fd                	addiw	a5,a5,-1
    800037c6:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800037c8:	00016517          	auipc	a0,0x16
    800037cc:	61050513          	addi	a0,a0,1552 # 80019dd8 <bcache>
    800037d0:	ffffd097          	auipc	ra,0xffffd
    800037d4:	4ba080e7          	jalr	1210(ra) # 80000c8a <release>
}
    800037d8:	60e2                	ld	ra,24(sp)
    800037da:	6442                	ld	s0,16(sp)
    800037dc:	64a2                	ld	s1,8(sp)
    800037de:	6105                	addi	sp,sp,32
    800037e0:	8082                	ret

00000000800037e2 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800037e2:	1101                	addi	sp,sp,-32
    800037e4:	ec06                	sd	ra,24(sp)
    800037e6:	e822                	sd	s0,16(sp)
    800037e8:	e426                	sd	s1,8(sp)
    800037ea:	e04a                	sd	s2,0(sp)
    800037ec:	1000                	addi	s0,sp,32
    800037ee:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800037f0:	00d5d59b          	srliw	a1,a1,0xd
    800037f4:	0001f797          	auipc	a5,0x1f
    800037f8:	cc07a783          	lw	a5,-832(a5) # 800224b4 <sb+0x1c>
    800037fc:	9dbd                	addw	a1,a1,a5
    800037fe:	00000097          	auipc	ra,0x0
    80003802:	d9e080e7          	jalr	-610(ra) # 8000359c <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003806:	0074f713          	andi	a4,s1,7
    8000380a:	4785                	li	a5,1
    8000380c:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003810:	14ce                	slli	s1,s1,0x33
    80003812:	90d9                	srli	s1,s1,0x36
    80003814:	00950733          	add	a4,a0,s1
    80003818:	05874703          	lbu	a4,88(a4)
    8000381c:	00e7f6b3          	and	a3,a5,a4
    80003820:	c69d                	beqz	a3,8000384e <bfree+0x6c>
    80003822:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003824:	94aa                	add	s1,s1,a0
    80003826:	fff7c793          	not	a5,a5
    8000382a:	8ff9                	and	a5,a5,a4
    8000382c:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003830:	00001097          	auipc	ra,0x1
    80003834:	120080e7          	jalr	288(ra) # 80004950 <log_write>
  brelse(bp);
    80003838:	854a                	mv	a0,s2
    8000383a:	00000097          	auipc	ra,0x0
    8000383e:	e92080e7          	jalr	-366(ra) # 800036cc <brelse>
}
    80003842:	60e2                	ld	ra,24(sp)
    80003844:	6442                	ld	s0,16(sp)
    80003846:	64a2                	ld	s1,8(sp)
    80003848:	6902                	ld	s2,0(sp)
    8000384a:	6105                	addi	sp,sp,32
    8000384c:	8082                	ret
    panic("freeing free block");
    8000384e:	00005517          	auipc	a0,0x5
    80003852:	d2250513          	addi	a0,a0,-734 # 80008570 <syscalls+0x110>
    80003856:	ffffd097          	auipc	ra,0xffffd
    8000385a:	ce8080e7          	jalr	-792(ra) # 8000053e <panic>

000000008000385e <balloc>:
{
    8000385e:	711d                	addi	sp,sp,-96
    80003860:	ec86                	sd	ra,88(sp)
    80003862:	e8a2                	sd	s0,80(sp)
    80003864:	e4a6                	sd	s1,72(sp)
    80003866:	e0ca                	sd	s2,64(sp)
    80003868:	fc4e                	sd	s3,56(sp)
    8000386a:	f852                	sd	s4,48(sp)
    8000386c:	f456                	sd	s5,40(sp)
    8000386e:	f05a                	sd	s6,32(sp)
    80003870:	ec5e                	sd	s7,24(sp)
    80003872:	e862                	sd	s8,16(sp)
    80003874:	e466                	sd	s9,8(sp)
    80003876:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003878:	0001f797          	auipc	a5,0x1f
    8000387c:	c247a783          	lw	a5,-988(a5) # 8002249c <sb+0x4>
    80003880:	10078163          	beqz	a5,80003982 <balloc+0x124>
    80003884:	8baa                	mv	s7,a0
    80003886:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003888:	0001fb17          	auipc	s6,0x1f
    8000388c:	c10b0b13          	addi	s6,s6,-1008 # 80022498 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003890:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003892:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003894:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003896:	6c89                	lui	s9,0x2
    80003898:	a061                	j	80003920 <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000389a:	974a                	add	a4,a4,s2
    8000389c:	8fd5                	or	a5,a5,a3
    8000389e:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800038a2:	854a                	mv	a0,s2
    800038a4:	00001097          	auipc	ra,0x1
    800038a8:	0ac080e7          	jalr	172(ra) # 80004950 <log_write>
        brelse(bp);
    800038ac:	854a                	mv	a0,s2
    800038ae:	00000097          	auipc	ra,0x0
    800038b2:	e1e080e7          	jalr	-482(ra) # 800036cc <brelse>
  bp = bread(dev, bno);
    800038b6:	85a6                	mv	a1,s1
    800038b8:	855e                	mv	a0,s7
    800038ba:	00000097          	auipc	ra,0x0
    800038be:	ce2080e7          	jalr	-798(ra) # 8000359c <bread>
    800038c2:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800038c4:	40000613          	li	a2,1024
    800038c8:	4581                	li	a1,0
    800038ca:	05850513          	addi	a0,a0,88
    800038ce:	ffffd097          	auipc	ra,0xffffd
    800038d2:	404080e7          	jalr	1028(ra) # 80000cd2 <memset>
  log_write(bp);
    800038d6:	854a                	mv	a0,s2
    800038d8:	00001097          	auipc	ra,0x1
    800038dc:	078080e7          	jalr	120(ra) # 80004950 <log_write>
  brelse(bp);
    800038e0:	854a                	mv	a0,s2
    800038e2:	00000097          	auipc	ra,0x0
    800038e6:	dea080e7          	jalr	-534(ra) # 800036cc <brelse>
}
    800038ea:	8526                	mv	a0,s1
    800038ec:	60e6                	ld	ra,88(sp)
    800038ee:	6446                	ld	s0,80(sp)
    800038f0:	64a6                	ld	s1,72(sp)
    800038f2:	6906                	ld	s2,64(sp)
    800038f4:	79e2                	ld	s3,56(sp)
    800038f6:	7a42                	ld	s4,48(sp)
    800038f8:	7aa2                	ld	s5,40(sp)
    800038fa:	7b02                	ld	s6,32(sp)
    800038fc:	6be2                	ld	s7,24(sp)
    800038fe:	6c42                	ld	s8,16(sp)
    80003900:	6ca2                	ld	s9,8(sp)
    80003902:	6125                	addi	sp,sp,96
    80003904:	8082                	ret
    brelse(bp);
    80003906:	854a                	mv	a0,s2
    80003908:	00000097          	auipc	ra,0x0
    8000390c:	dc4080e7          	jalr	-572(ra) # 800036cc <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003910:	015c87bb          	addw	a5,s9,s5
    80003914:	00078a9b          	sext.w	s5,a5
    80003918:	004b2703          	lw	a4,4(s6)
    8000391c:	06eaf363          	bgeu	s5,a4,80003982 <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    80003920:	41fad79b          	sraiw	a5,s5,0x1f
    80003924:	0137d79b          	srliw	a5,a5,0x13
    80003928:	015787bb          	addw	a5,a5,s5
    8000392c:	40d7d79b          	sraiw	a5,a5,0xd
    80003930:	01cb2583          	lw	a1,28(s6)
    80003934:	9dbd                	addw	a1,a1,a5
    80003936:	855e                	mv	a0,s7
    80003938:	00000097          	auipc	ra,0x0
    8000393c:	c64080e7          	jalr	-924(ra) # 8000359c <bread>
    80003940:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003942:	004b2503          	lw	a0,4(s6)
    80003946:	000a849b          	sext.w	s1,s5
    8000394a:	8662                	mv	a2,s8
    8000394c:	faa4fde3          	bgeu	s1,a0,80003906 <balloc+0xa8>
      m = 1 << (bi % 8);
    80003950:	41f6579b          	sraiw	a5,a2,0x1f
    80003954:	01d7d69b          	srliw	a3,a5,0x1d
    80003958:	00c6873b          	addw	a4,a3,a2
    8000395c:	00777793          	andi	a5,a4,7
    80003960:	9f95                	subw	a5,a5,a3
    80003962:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003966:	4037571b          	sraiw	a4,a4,0x3
    8000396a:	00e906b3          	add	a3,s2,a4
    8000396e:	0586c683          	lbu	a3,88(a3)
    80003972:	00d7f5b3          	and	a1,a5,a3
    80003976:	d195                	beqz	a1,8000389a <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003978:	2605                	addiw	a2,a2,1
    8000397a:	2485                	addiw	s1,s1,1
    8000397c:	fd4618e3          	bne	a2,s4,8000394c <balloc+0xee>
    80003980:	b759                	j	80003906 <balloc+0xa8>
  printf("balloc: out of blocks\n");
    80003982:	00005517          	auipc	a0,0x5
    80003986:	c0650513          	addi	a0,a0,-1018 # 80008588 <syscalls+0x128>
    8000398a:	ffffd097          	auipc	ra,0xffffd
    8000398e:	bfe080e7          	jalr	-1026(ra) # 80000588 <printf>
  return 0;
    80003992:	4481                	li	s1,0
    80003994:	bf99                	j	800038ea <balloc+0x8c>

0000000080003996 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003996:	7179                	addi	sp,sp,-48
    80003998:	f406                	sd	ra,40(sp)
    8000399a:	f022                	sd	s0,32(sp)
    8000399c:	ec26                	sd	s1,24(sp)
    8000399e:	e84a                	sd	s2,16(sp)
    800039a0:	e44e                	sd	s3,8(sp)
    800039a2:	e052                	sd	s4,0(sp)
    800039a4:	1800                	addi	s0,sp,48
    800039a6:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800039a8:	47ad                	li	a5,11
    800039aa:	02b7e763          	bltu	a5,a1,800039d8 <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    800039ae:	02059493          	slli	s1,a1,0x20
    800039b2:	9081                	srli	s1,s1,0x20
    800039b4:	048a                	slli	s1,s1,0x2
    800039b6:	94aa                	add	s1,s1,a0
    800039b8:	0504a903          	lw	s2,80(s1)
    800039bc:	06091e63          	bnez	s2,80003a38 <bmap+0xa2>
      addr = balloc(ip->dev);
    800039c0:	4108                	lw	a0,0(a0)
    800039c2:	00000097          	auipc	ra,0x0
    800039c6:	e9c080e7          	jalr	-356(ra) # 8000385e <balloc>
    800039ca:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800039ce:	06090563          	beqz	s2,80003a38 <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    800039d2:	0524a823          	sw	s2,80(s1)
    800039d6:	a08d                	j	80003a38 <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    800039d8:	ff45849b          	addiw	s1,a1,-12
    800039dc:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800039e0:	0ff00793          	li	a5,255
    800039e4:	08e7e563          	bltu	a5,a4,80003a6e <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    800039e8:	08052903          	lw	s2,128(a0)
    800039ec:	00091d63          	bnez	s2,80003a06 <bmap+0x70>
      addr = balloc(ip->dev);
    800039f0:	4108                	lw	a0,0(a0)
    800039f2:	00000097          	auipc	ra,0x0
    800039f6:	e6c080e7          	jalr	-404(ra) # 8000385e <balloc>
    800039fa:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800039fe:	02090d63          	beqz	s2,80003a38 <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003a02:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003a06:	85ca                	mv	a1,s2
    80003a08:	0009a503          	lw	a0,0(s3)
    80003a0c:	00000097          	auipc	ra,0x0
    80003a10:	b90080e7          	jalr	-1136(ra) # 8000359c <bread>
    80003a14:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003a16:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003a1a:	02049593          	slli	a1,s1,0x20
    80003a1e:	9181                	srli	a1,a1,0x20
    80003a20:	058a                	slli	a1,a1,0x2
    80003a22:	00b784b3          	add	s1,a5,a1
    80003a26:	0004a903          	lw	s2,0(s1)
    80003a2a:	02090063          	beqz	s2,80003a4a <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003a2e:	8552                	mv	a0,s4
    80003a30:	00000097          	auipc	ra,0x0
    80003a34:	c9c080e7          	jalr	-868(ra) # 800036cc <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003a38:	854a                	mv	a0,s2
    80003a3a:	70a2                	ld	ra,40(sp)
    80003a3c:	7402                	ld	s0,32(sp)
    80003a3e:	64e2                	ld	s1,24(sp)
    80003a40:	6942                	ld	s2,16(sp)
    80003a42:	69a2                	ld	s3,8(sp)
    80003a44:	6a02                	ld	s4,0(sp)
    80003a46:	6145                	addi	sp,sp,48
    80003a48:	8082                	ret
      addr = balloc(ip->dev);
    80003a4a:	0009a503          	lw	a0,0(s3)
    80003a4e:	00000097          	auipc	ra,0x0
    80003a52:	e10080e7          	jalr	-496(ra) # 8000385e <balloc>
    80003a56:	0005091b          	sext.w	s2,a0
      if(addr){
    80003a5a:	fc090ae3          	beqz	s2,80003a2e <bmap+0x98>
        a[bn] = addr;
    80003a5e:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003a62:	8552                	mv	a0,s4
    80003a64:	00001097          	auipc	ra,0x1
    80003a68:	eec080e7          	jalr	-276(ra) # 80004950 <log_write>
    80003a6c:	b7c9                	j	80003a2e <bmap+0x98>
  panic("bmap: out of range");
    80003a6e:	00005517          	auipc	a0,0x5
    80003a72:	b3250513          	addi	a0,a0,-1230 # 800085a0 <syscalls+0x140>
    80003a76:	ffffd097          	auipc	ra,0xffffd
    80003a7a:	ac8080e7          	jalr	-1336(ra) # 8000053e <panic>

0000000080003a7e <iget>:
{
    80003a7e:	7179                	addi	sp,sp,-48
    80003a80:	f406                	sd	ra,40(sp)
    80003a82:	f022                	sd	s0,32(sp)
    80003a84:	ec26                	sd	s1,24(sp)
    80003a86:	e84a                	sd	s2,16(sp)
    80003a88:	e44e                	sd	s3,8(sp)
    80003a8a:	e052                	sd	s4,0(sp)
    80003a8c:	1800                	addi	s0,sp,48
    80003a8e:	89aa                	mv	s3,a0
    80003a90:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003a92:	0001f517          	auipc	a0,0x1f
    80003a96:	a2650513          	addi	a0,a0,-1498 # 800224b8 <itable>
    80003a9a:	ffffd097          	auipc	ra,0xffffd
    80003a9e:	13c080e7          	jalr	316(ra) # 80000bd6 <acquire>
  empty = 0;
    80003aa2:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003aa4:	0001f497          	auipc	s1,0x1f
    80003aa8:	a2c48493          	addi	s1,s1,-1492 # 800224d0 <itable+0x18>
    80003aac:	00020697          	auipc	a3,0x20
    80003ab0:	4b468693          	addi	a3,a3,1204 # 80023f60 <log>
    80003ab4:	a039                	j	80003ac2 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003ab6:	02090b63          	beqz	s2,80003aec <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003aba:	08848493          	addi	s1,s1,136
    80003abe:	02d48a63          	beq	s1,a3,80003af2 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003ac2:	449c                	lw	a5,8(s1)
    80003ac4:	fef059e3          	blez	a5,80003ab6 <iget+0x38>
    80003ac8:	4098                	lw	a4,0(s1)
    80003aca:	ff3716e3          	bne	a4,s3,80003ab6 <iget+0x38>
    80003ace:	40d8                	lw	a4,4(s1)
    80003ad0:	ff4713e3          	bne	a4,s4,80003ab6 <iget+0x38>
      ip->ref++;
    80003ad4:	2785                	addiw	a5,a5,1
    80003ad6:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003ad8:	0001f517          	auipc	a0,0x1f
    80003adc:	9e050513          	addi	a0,a0,-1568 # 800224b8 <itable>
    80003ae0:	ffffd097          	auipc	ra,0xffffd
    80003ae4:	1aa080e7          	jalr	426(ra) # 80000c8a <release>
      return ip;
    80003ae8:	8926                	mv	s2,s1
    80003aea:	a03d                	j	80003b18 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003aec:	f7f9                	bnez	a5,80003aba <iget+0x3c>
    80003aee:	8926                	mv	s2,s1
    80003af0:	b7e9                	j	80003aba <iget+0x3c>
  if(empty == 0)
    80003af2:	02090c63          	beqz	s2,80003b2a <iget+0xac>
  ip->dev = dev;
    80003af6:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003afa:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003afe:	4785                	li	a5,1
    80003b00:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003b04:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003b08:	0001f517          	auipc	a0,0x1f
    80003b0c:	9b050513          	addi	a0,a0,-1616 # 800224b8 <itable>
    80003b10:	ffffd097          	auipc	ra,0xffffd
    80003b14:	17a080e7          	jalr	378(ra) # 80000c8a <release>
}
    80003b18:	854a                	mv	a0,s2
    80003b1a:	70a2                	ld	ra,40(sp)
    80003b1c:	7402                	ld	s0,32(sp)
    80003b1e:	64e2                	ld	s1,24(sp)
    80003b20:	6942                	ld	s2,16(sp)
    80003b22:	69a2                	ld	s3,8(sp)
    80003b24:	6a02                	ld	s4,0(sp)
    80003b26:	6145                	addi	sp,sp,48
    80003b28:	8082                	ret
    panic("iget: no inodes");
    80003b2a:	00005517          	auipc	a0,0x5
    80003b2e:	a8e50513          	addi	a0,a0,-1394 # 800085b8 <syscalls+0x158>
    80003b32:	ffffd097          	auipc	ra,0xffffd
    80003b36:	a0c080e7          	jalr	-1524(ra) # 8000053e <panic>

0000000080003b3a <fsinit>:
fsinit(int dev) {
    80003b3a:	7179                	addi	sp,sp,-48
    80003b3c:	f406                	sd	ra,40(sp)
    80003b3e:	f022                	sd	s0,32(sp)
    80003b40:	ec26                	sd	s1,24(sp)
    80003b42:	e84a                	sd	s2,16(sp)
    80003b44:	e44e                	sd	s3,8(sp)
    80003b46:	1800                	addi	s0,sp,48
    80003b48:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003b4a:	4585                	li	a1,1
    80003b4c:	00000097          	auipc	ra,0x0
    80003b50:	a50080e7          	jalr	-1456(ra) # 8000359c <bread>
    80003b54:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003b56:	0001f997          	auipc	s3,0x1f
    80003b5a:	94298993          	addi	s3,s3,-1726 # 80022498 <sb>
    80003b5e:	02000613          	li	a2,32
    80003b62:	05850593          	addi	a1,a0,88
    80003b66:	854e                	mv	a0,s3
    80003b68:	ffffd097          	auipc	ra,0xffffd
    80003b6c:	1c6080e7          	jalr	454(ra) # 80000d2e <memmove>
  brelse(bp);
    80003b70:	8526                	mv	a0,s1
    80003b72:	00000097          	auipc	ra,0x0
    80003b76:	b5a080e7          	jalr	-1190(ra) # 800036cc <brelse>
  if(sb.magic != FSMAGIC)
    80003b7a:	0009a703          	lw	a4,0(s3)
    80003b7e:	102037b7          	lui	a5,0x10203
    80003b82:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003b86:	02f71263          	bne	a4,a5,80003baa <fsinit+0x70>
  initlog(dev, &sb);
    80003b8a:	0001f597          	auipc	a1,0x1f
    80003b8e:	90e58593          	addi	a1,a1,-1778 # 80022498 <sb>
    80003b92:	854a                	mv	a0,s2
    80003b94:	00001097          	auipc	ra,0x1
    80003b98:	b40080e7          	jalr	-1216(ra) # 800046d4 <initlog>
}
    80003b9c:	70a2                	ld	ra,40(sp)
    80003b9e:	7402                	ld	s0,32(sp)
    80003ba0:	64e2                	ld	s1,24(sp)
    80003ba2:	6942                	ld	s2,16(sp)
    80003ba4:	69a2                	ld	s3,8(sp)
    80003ba6:	6145                	addi	sp,sp,48
    80003ba8:	8082                	ret
    panic("invalid file system");
    80003baa:	00005517          	auipc	a0,0x5
    80003bae:	a1e50513          	addi	a0,a0,-1506 # 800085c8 <syscalls+0x168>
    80003bb2:	ffffd097          	auipc	ra,0xffffd
    80003bb6:	98c080e7          	jalr	-1652(ra) # 8000053e <panic>

0000000080003bba <iinit>:
{
    80003bba:	7179                	addi	sp,sp,-48
    80003bbc:	f406                	sd	ra,40(sp)
    80003bbe:	f022                	sd	s0,32(sp)
    80003bc0:	ec26                	sd	s1,24(sp)
    80003bc2:	e84a                	sd	s2,16(sp)
    80003bc4:	e44e                	sd	s3,8(sp)
    80003bc6:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003bc8:	00005597          	auipc	a1,0x5
    80003bcc:	a1858593          	addi	a1,a1,-1512 # 800085e0 <syscalls+0x180>
    80003bd0:	0001f517          	auipc	a0,0x1f
    80003bd4:	8e850513          	addi	a0,a0,-1816 # 800224b8 <itable>
    80003bd8:	ffffd097          	auipc	ra,0xffffd
    80003bdc:	f6e080e7          	jalr	-146(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003be0:	0001f497          	auipc	s1,0x1f
    80003be4:	90048493          	addi	s1,s1,-1792 # 800224e0 <itable+0x28>
    80003be8:	00020997          	auipc	s3,0x20
    80003bec:	38898993          	addi	s3,s3,904 # 80023f70 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003bf0:	00005917          	auipc	s2,0x5
    80003bf4:	9f890913          	addi	s2,s2,-1544 # 800085e8 <syscalls+0x188>
    80003bf8:	85ca                	mv	a1,s2
    80003bfa:	8526                	mv	a0,s1
    80003bfc:	00001097          	auipc	ra,0x1
    80003c00:	e3a080e7          	jalr	-454(ra) # 80004a36 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003c04:	08848493          	addi	s1,s1,136
    80003c08:	ff3498e3          	bne	s1,s3,80003bf8 <iinit+0x3e>
}
    80003c0c:	70a2                	ld	ra,40(sp)
    80003c0e:	7402                	ld	s0,32(sp)
    80003c10:	64e2                	ld	s1,24(sp)
    80003c12:	6942                	ld	s2,16(sp)
    80003c14:	69a2                	ld	s3,8(sp)
    80003c16:	6145                	addi	sp,sp,48
    80003c18:	8082                	ret

0000000080003c1a <ialloc>:
{
    80003c1a:	715d                	addi	sp,sp,-80
    80003c1c:	e486                	sd	ra,72(sp)
    80003c1e:	e0a2                	sd	s0,64(sp)
    80003c20:	fc26                	sd	s1,56(sp)
    80003c22:	f84a                	sd	s2,48(sp)
    80003c24:	f44e                	sd	s3,40(sp)
    80003c26:	f052                	sd	s4,32(sp)
    80003c28:	ec56                	sd	s5,24(sp)
    80003c2a:	e85a                	sd	s6,16(sp)
    80003c2c:	e45e                	sd	s7,8(sp)
    80003c2e:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003c30:	0001f717          	auipc	a4,0x1f
    80003c34:	87472703          	lw	a4,-1932(a4) # 800224a4 <sb+0xc>
    80003c38:	4785                	li	a5,1
    80003c3a:	04e7fa63          	bgeu	a5,a4,80003c8e <ialloc+0x74>
    80003c3e:	8aaa                	mv	s5,a0
    80003c40:	8bae                	mv	s7,a1
    80003c42:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003c44:	0001fa17          	auipc	s4,0x1f
    80003c48:	854a0a13          	addi	s4,s4,-1964 # 80022498 <sb>
    80003c4c:	00048b1b          	sext.w	s6,s1
    80003c50:	0044d793          	srli	a5,s1,0x4
    80003c54:	018a2583          	lw	a1,24(s4)
    80003c58:	9dbd                	addw	a1,a1,a5
    80003c5a:	8556                	mv	a0,s5
    80003c5c:	00000097          	auipc	ra,0x0
    80003c60:	940080e7          	jalr	-1728(ra) # 8000359c <bread>
    80003c64:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003c66:	05850993          	addi	s3,a0,88
    80003c6a:	00f4f793          	andi	a5,s1,15
    80003c6e:	079a                	slli	a5,a5,0x6
    80003c70:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003c72:	00099783          	lh	a5,0(s3)
    80003c76:	c3a1                	beqz	a5,80003cb6 <ialloc+0x9c>
    brelse(bp);
    80003c78:	00000097          	auipc	ra,0x0
    80003c7c:	a54080e7          	jalr	-1452(ra) # 800036cc <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003c80:	0485                	addi	s1,s1,1
    80003c82:	00ca2703          	lw	a4,12(s4)
    80003c86:	0004879b          	sext.w	a5,s1
    80003c8a:	fce7e1e3          	bltu	a5,a4,80003c4c <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003c8e:	00005517          	auipc	a0,0x5
    80003c92:	96250513          	addi	a0,a0,-1694 # 800085f0 <syscalls+0x190>
    80003c96:	ffffd097          	auipc	ra,0xffffd
    80003c9a:	8f2080e7          	jalr	-1806(ra) # 80000588 <printf>
  return 0;
    80003c9e:	4501                	li	a0,0
}
    80003ca0:	60a6                	ld	ra,72(sp)
    80003ca2:	6406                	ld	s0,64(sp)
    80003ca4:	74e2                	ld	s1,56(sp)
    80003ca6:	7942                	ld	s2,48(sp)
    80003ca8:	79a2                	ld	s3,40(sp)
    80003caa:	7a02                	ld	s4,32(sp)
    80003cac:	6ae2                	ld	s5,24(sp)
    80003cae:	6b42                	ld	s6,16(sp)
    80003cb0:	6ba2                	ld	s7,8(sp)
    80003cb2:	6161                	addi	sp,sp,80
    80003cb4:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80003cb6:	04000613          	li	a2,64
    80003cba:	4581                	li	a1,0
    80003cbc:	854e                	mv	a0,s3
    80003cbe:	ffffd097          	auipc	ra,0xffffd
    80003cc2:	014080e7          	jalr	20(ra) # 80000cd2 <memset>
      dip->type = type;
    80003cc6:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003cca:	854a                	mv	a0,s2
    80003ccc:	00001097          	auipc	ra,0x1
    80003cd0:	c84080e7          	jalr	-892(ra) # 80004950 <log_write>
      brelse(bp);
    80003cd4:	854a                	mv	a0,s2
    80003cd6:	00000097          	auipc	ra,0x0
    80003cda:	9f6080e7          	jalr	-1546(ra) # 800036cc <brelse>
      return iget(dev, inum);
    80003cde:	85da                	mv	a1,s6
    80003ce0:	8556                	mv	a0,s5
    80003ce2:	00000097          	auipc	ra,0x0
    80003ce6:	d9c080e7          	jalr	-612(ra) # 80003a7e <iget>
    80003cea:	bf5d                	j	80003ca0 <ialloc+0x86>

0000000080003cec <iupdate>:
{
    80003cec:	1101                	addi	sp,sp,-32
    80003cee:	ec06                	sd	ra,24(sp)
    80003cf0:	e822                	sd	s0,16(sp)
    80003cf2:	e426                	sd	s1,8(sp)
    80003cf4:	e04a                	sd	s2,0(sp)
    80003cf6:	1000                	addi	s0,sp,32
    80003cf8:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003cfa:	415c                	lw	a5,4(a0)
    80003cfc:	0047d79b          	srliw	a5,a5,0x4
    80003d00:	0001e597          	auipc	a1,0x1e
    80003d04:	7b05a583          	lw	a1,1968(a1) # 800224b0 <sb+0x18>
    80003d08:	9dbd                	addw	a1,a1,a5
    80003d0a:	4108                	lw	a0,0(a0)
    80003d0c:	00000097          	auipc	ra,0x0
    80003d10:	890080e7          	jalr	-1904(ra) # 8000359c <bread>
    80003d14:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003d16:	05850793          	addi	a5,a0,88
    80003d1a:	40c8                	lw	a0,4(s1)
    80003d1c:	893d                	andi	a0,a0,15
    80003d1e:	051a                	slli	a0,a0,0x6
    80003d20:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003d22:	04449703          	lh	a4,68(s1)
    80003d26:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003d2a:	04649703          	lh	a4,70(s1)
    80003d2e:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003d32:	04849703          	lh	a4,72(s1)
    80003d36:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003d3a:	04a49703          	lh	a4,74(s1)
    80003d3e:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003d42:	44f8                	lw	a4,76(s1)
    80003d44:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003d46:	03400613          	li	a2,52
    80003d4a:	05048593          	addi	a1,s1,80
    80003d4e:	0531                	addi	a0,a0,12
    80003d50:	ffffd097          	auipc	ra,0xffffd
    80003d54:	fde080e7          	jalr	-34(ra) # 80000d2e <memmove>
  log_write(bp);
    80003d58:	854a                	mv	a0,s2
    80003d5a:	00001097          	auipc	ra,0x1
    80003d5e:	bf6080e7          	jalr	-1034(ra) # 80004950 <log_write>
  brelse(bp);
    80003d62:	854a                	mv	a0,s2
    80003d64:	00000097          	auipc	ra,0x0
    80003d68:	968080e7          	jalr	-1688(ra) # 800036cc <brelse>
}
    80003d6c:	60e2                	ld	ra,24(sp)
    80003d6e:	6442                	ld	s0,16(sp)
    80003d70:	64a2                	ld	s1,8(sp)
    80003d72:	6902                	ld	s2,0(sp)
    80003d74:	6105                	addi	sp,sp,32
    80003d76:	8082                	ret

0000000080003d78 <idup>:
{
    80003d78:	1101                	addi	sp,sp,-32
    80003d7a:	ec06                	sd	ra,24(sp)
    80003d7c:	e822                	sd	s0,16(sp)
    80003d7e:	e426                	sd	s1,8(sp)
    80003d80:	1000                	addi	s0,sp,32
    80003d82:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003d84:	0001e517          	auipc	a0,0x1e
    80003d88:	73450513          	addi	a0,a0,1844 # 800224b8 <itable>
    80003d8c:	ffffd097          	auipc	ra,0xffffd
    80003d90:	e4a080e7          	jalr	-438(ra) # 80000bd6 <acquire>
  ip->ref++;
    80003d94:	449c                	lw	a5,8(s1)
    80003d96:	2785                	addiw	a5,a5,1
    80003d98:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003d9a:	0001e517          	auipc	a0,0x1e
    80003d9e:	71e50513          	addi	a0,a0,1822 # 800224b8 <itable>
    80003da2:	ffffd097          	auipc	ra,0xffffd
    80003da6:	ee8080e7          	jalr	-280(ra) # 80000c8a <release>
}
    80003daa:	8526                	mv	a0,s1
    80003dac:	60e2                	ld	ra,24(sp)
    80003dae:	6442                	ld	s0,16(sp)
    80003db0:	64a2                	ld	s1,8(sp)
    80003db2:	6105                	addi	sp,sp,32
    80003db4:	8082                	ret

0000000080003db6 <ilock>:
{
    80003db6:	1101                	addi	sp,sp,-32
    80003db8:	ec06                	sd	ra,24(sp)
    80003dba:	e822                	sd	s0,16(sp)
    80003dbc:	e426                	sd	s1,8(sp)
    80003dbe:	e04a                	sd	s2,0(sp)
    80003dc0:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003dc2:	c115                	beqz	a0,80003de6 <ilock+0x30>
    80003dc4:	84aa                	mv	s1,a0
    80003dc6:	451c                	lw	a5,8(a0)
    80003dc8:	00f05f63          	blez	a5,80003de6 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003dcc:	0541                	addi	a0,a0,16
    80003dce:	00001097          	auipc	ra,0x1
    80003dd2:	ca2080e7          	jalr	-862(ra) # 80004a70 <acquiresleep>
  if(ip->valid == 0){
    80003dd6:	40bc                	lw	a5,64(s1)
    80003dd8:	cf99                	beqz	a5,80003df6 <ilock+0x40>
}
    80003dda:	60e2                	ld	ra,24(sp)
    80003ddc:	6442                	ld	s0,16(sp)
    80003dde:	64a2                	ld	s1,8(sp)
    80003de0:	6902                	ld	s2,0(sp)
    80003de2:	6105                	addi	sp,sp,32
    80003de4:	8082                	ret
    panic("ilock");
    80003de6:	00005517          	auipc	a0,0x5
    80003dea:	82250513          	addi	a0,a0,-2014 # 80008608 <syscalls+0x1a8>
    80003dee:	ffffc097          	auipc	ra,0xffffc
    80003df2:	750080e7          	jalr	1872(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003df6:	40dc                	lw	a5,4(s1)
    80003df8:	0047d79b          	srliw	a5,a5,0x4
    80003dfc:	0001e597          	auipc	a1,0x1e
    80003e00:	6b45a583          	lw	a1,1716(a1) # 800224b0 <sb+0x18>
    80003e04:	9dbd                	addw	a1,a1,a5
    80003e06:	4088                	lw	a0,0(s1)
    80003e08:	fffff097          	auipc	ra,0xfffff
    80003e0c:	794080e7          	jalr	1940(ra) # 8000359c <bread>
    80003e10:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003e12:	05850593          	addi	a1,a0,88
    80003e16:	40dc                	lw	a5,4(s1)
    80003e18:	8bbd                	andi	a5,a5,15
    80003e1a:	079a                	slli	a5,a5,0x6
    80003e1c:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003e1e:	00059783          	lh	a5,0(a1)
    80003e22:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003e26:	00259783          	lh	a5,2(a1)
    80003e2a:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003e2e:	00459783          	lh	a5,4(a1)
    80003e32:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003e36:	00659783          	lh	a5,6(a1)
    80003e3a:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003e3e:	459c                	lw	a5,8(a1)
    80003e40:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003e42:	03400613          	li	a2,52
    80003e46:	05b1                	addi	a1,a1,12
    80003e48:	05048513          	addi	a0,s1,80
    80003e4c:	ffffd097          	auipc	ra,0xffffd
    80003e50:	ee2080e7          	jalr	-286(ra) # 80000d2e <memmove>
    brelse(bp);
    80003e54:	854a                	mv	a0,s2
    80003e56:	00000097          	auipc	ra,0x0
    80003e5a:	876080e7          	jalr	-1930(ra) # 800036cc <brelse>
    ip->valid = 1;
    80003e5e:	4785                	li	a5,1
    80003e60:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003e62:	04449783          	lh	a5,68(s1)
    80003e66:	fbb5                	bnez	a5,80003dda <ilock+0x24>
      panic("ilock: no type");
    80003e68:	00004517          	auipc	a0,0x4
    80003e6c:	7a850513          	addi	a0,a0,1960 # 80008610 <syscalls+0x1b0>
    80003e70:	ffffc097          	auipc	ra,0xffffc
    80003e74:	6ce080e7          	jalr	1742(ra) # 8000053e <panic>

0000000080003e78 <iunlock>:
{
    80003e78:	1101                	addi	sp,sp,-32
    80003e7a:	ec06                	sd	ra,24(sp)
    80003e7c:	e822                	sd	s0,16(sp)
    80003e7e:	e426                	sd	s1,8(sp)
    80003e80:	e04a                	sd	s2,0(sp)
    80003e82:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003e84:	c905                	beqz	a0,80003eb4 <iunlock+0x3c>
    80003e86:	84aa                	mv	s1,a0
    80003e88:	01050913          	addi	s2,a0,16
    80003e8c:	854a                	mv	a0,s2
    80003e8e:	00001097          	auipc	ra,0x1
    80003e92:	c7c080e7          	jalr	-900(ra) # 80004b0a <holdingsleep>
    80003e96:	cd19                	beqz	a0,80003eb4 <iunlock+0x3c>
    80003e98:	449c                	lw	a5,8(s1)
    80003e9a:	00f05d63          	blez	a5,80003eb4 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003e9e:	854a                	mv	a0,s2
    80003ea0:	00001097          	auipc	ra,0x1
    80003ea4:	c26080e7          	jalr	-986(ra) # 80004ac6 <releasesleep>
}
    80003ea8:	60e2                	ld	ra,24(sp)
    80003eaa:	6442                	ld	s0,16(sp)
    80003eac:	64a2                	ld	s1,8(sp)
    80003eae:	6902                	ld	s2,0(sp)
    80003eb0:	6105                	addi	sp,sp,32
    80003eb2:	8082                	ret
    panic("iunlock");
    80003eb4:	00004517          	auipc	a0,0x4
    80003eb8:	76c50513          	addi	a0,a0,1900 # 80008620 <syscalls+0x1c0>
    80003ebc:	ffffc097          	auipc	ra,0xffffc
    80003ec0:	682080e7          	jalr	1666(ra) # 8000053e <panic>

0000000080003ec4 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003ec4:	7179                	addi	sp,sp,-48
    80003ec6:	f406                	sd	ra,40(sp)
    80003ec8:	f022                	sd	s0,32(sp)
    80003eca:	ec26                	sd	s1,24(sp)
    80003ecc:	e84a                	sd	s2,16(sp)
    80003ece:	e44e                	sd	s3,8(sp)
    80003ed0:	e052                	sd	s4,0(sp)
    80003ed2:	1800                	addi	s0,sp,48
    80003ed4:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003ed6:	05050493          	addi	s1,a0,80
    80003eda:	08050913          	addi	s2,a0,128
    80003ede:	a021                	j	80003ee6 <itrunc+0x22>
    80003ee0:	0491                	addi	s1,s1,4
    80003ee2:	01248d63          	beq	s1,s2,80003efc <itrunc+0x38>
    if(ip->addrs[i]){
    80003ee6:	408c                	lw	a1,0(s1)
    80003ee8:	dde5                	beqz	a1,80003ee0 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003eea:	0009a503          	lw	a0,0(s3)
    80003eee:	00000097          	auipc	ra,0x0
    80003ef2:	8f4080e7          	jalr	-1804(ra) # 800037e2 <bfree>
      ip->addrs[i] = 0;
    80003ef6:	0004a023          	sw	zero,0(s1)
    80003efa:	b7dd                	j	80003ee0 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003efc:	0809a583          	lw	a1,128(s3)
    80003f00:	e185                	bnez	a1,80003f20 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003f02:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003f06:	854e                	mv	a0,s3
    80003f08:	00000097          	auipc	ra,0x0
    80003f0c:	de4080e7          	jalr	-540(ra) # 80003cec <iupdate>
}
    80003f10:	70a2                	ld	ra,40(sp)
    80003f12:	7402                	ld	s0,32(sp)
    80003f14:	64e2                	ld	s1,24(sp)
    80003f16:	6942                	ld	s2,16(sp)
    80003f18:	69a2                	ld	s3,8(sp)
    80003f1a:	6a02                	ld	s4,0(sp)
    80003f1c:	6145                	addi	sp,sp,48
    80003f1e:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003f20:	0009a503          	lw	a0,0(s3)
    80003f24:	fffff097          	auipc	ra,0xfffff
    80003f28:	678080e7          	jalr	1656(ra) # 8000359c <bread>
    80003f2c:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003f2e:	05850493          	addi	s1,a0,88
    80003f32:	45850913          	addi	s2,a0,1112
    80003f36:	a021                	j	80003f3e <itrunc+0x7a>
    80003f38:	0491                	addi	s1,s1,4
    80003f3a:	01248b63          	beq	s1,s2,80003f50 <itrunc+0x8c>
      if(a[j])
    80003f3e:	408c                	lw	a1,0(s1)
    80003f40:	dde5                	beqz	a1,80003f38 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003f42:	0009a503          	lw	a0,0(s3)
    80003f46:	00000097          	auipc	ra,0x0
    80003f4a:	89c080e7          	jalr	-1892(ra) # 800037e2 <bfree>
    80003f4e:	b7ed                	j	80003f38 <itrunc+0x74>
    brelse(bp);
    80003f50:	8552                	mv	a0,s4
    80003f52:	fffff097          	auipc	ra,0xfffff
    80003f56:	77a080e7          	jalr	1914(ra) # 800036cc <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003f5a:	0809a583          	lw	a1,128(s3)
    80003f5e:	0009a503          	lw	a0,0(s3)
    80003f62:	00000097          	auipc	ra,0x0
    80003f66:	880080e7          	jalr	-1920(ra) # 800037e2 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003f6a:	0809a023          	sw	zero,128(s3)
    80003f6e:	bf51                	j	80003f02 <itrunc+0x3e>

0000000080003f70 <iput>:
{
    80003f70:	1101                	addi	sp,sp,-32
    80003f72:	ec06                	sd	ra,24(sp)
    80003f74:	e822                	sd	s0,16(sp)
    80003f76:	e426                	sd	s1,8(sp)
    80003f78:	e04a                	sd	s2,0(sp)
    80003f7a:	1000                	addi	s0,sp,32
    80003f7c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003f7e:	0001e517          	auipc	a0,0x1e
    80003f82:	53a50513          	addi	a0,a0,1338 # 800224b8 <itable>
    80003f86:	ffffd097          	auipc	ra,0xffffd
    80003f8a:	c50080e7          	jalr	-944(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003f8e:	4498                	lw	a4,8(s1)
    80003f90:	4785                	li	a5,1
    80003f92:	02f70363          	beq	a4,a5,80003fb8 <iput+0x48>
  ip->ref--;
    80003f96:	449c                	lw	a5,8(s1)
    80003f98:	37fd                	addiw	a5,a5,-1
    80003f9a:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003f9c:	0001e517          	auipc	a0,0x1e
    80003fa0:	51c50513          	addi	a0,a0,1308 # 800224b8 <itable>
    80003fa4:	ffffd097          	auipc	ra,0xffffd
    80003fa8:	ce6080e7          	jalr	-794(ra) # 80000c8a <release>
}
    80003fac:	60e2                	ld	ra,24(sp)
    80003fae:	6442                	ld	s0,16(sp)
    80003fb0:	64a2                	ld	s1,8(sp)
    80003fb2:	6902                	ld	s2,0(sp)
    80003fb4:	6105                	addi	sp,sp,32
    80003fb6:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003fb8:	40bc                	lw	a5,64(s1)
    80003fba:	dff1                	beqz	a5,80003f96 <iput+0x26>
    80003fbc:	04a49783          	lh	a5,74(s1)
    80003fc0:	fbf9                	bnez	a5,80003f96 <iput+0x26>
    acquiresleep(&ip->lock);
    80003fc2:	01048913          	addi	s2,s1,16
    80003fc6:	854a                	mv	a0,s2
    80003fc8:	00001097          	auipc	ra,0x1
    80003fcc:	aa8080e7          	jalr	-1368(ra) # 80004a70 <acquiresleep>
    release(&itable.lock);
    80003fd0:	0001e517          	auipc	a0,0x1e
    80003fd4:	4e850513          	addi	a0,a0,1256 # 800224b8 <itable>
    80003fd8:	ffffd097          	auipc	ra,0xffffd
    80003fdc:	cb2080e7          	jalr	-846(ra) # 80000c8a <release>
    itrunc(ip);
    80003fe0:	8526                	mv	a0,s1
    80003fe2:	00000097          	auipc	ra,0x0
    80003fe6:	ee2080e7          	jalr	-286(ra) # 80003ec4 <itrunc>
    ip->type = 0;
    80003fea:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003fee:	8526                	mv	a0,s1
    80003ff0:	00000097          	auipc	ra,0x0
    80003ff4:	cfc080e7          	jalr	-772(ra) # 80003cec <iupdate>
    ip->valid = 0;
    80003ff8:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003ffc:	854a                	mv	a0,s2
    80003ffe:	00001097          	auipc	ra,0x1
    80004002:	ac8080e7          	jalr	-1336(ra) # 80004ac6 <releasesleep>
    acquire(&itable.lock);
    80004006:	0001e517          	auipc	a0,0x1e
    8000400a:	4b250513          	addi	a0,a0,1202 # 800224b8 <itable>
    8000400e:	ffffd097          	auipc	ra,0xffffd
    80004012:	bc8080e7          	jalr	-1080(ra) # 80000bd6 <acquire>
    80004016:	b741                	j	80003f96 <iput+0x26>

0000000080004018 <iunlockput>:
{
    80004018:	1101                	addi	sp,sp,-32
    8000401a:	ec06                	sd	ra,24(sp)
    8000401c:	e822                	sd	s0,16(sp)
    8000401e:	e426                	sd	s1,8(sp)
    80004020:	1000                	addi	s0,sp,32
    80004022:	84aa                	mv	s1,a0
  iunlock(ip);
    80004024:	00000097          	auipc	ra,0x0
    80004028:	e54080e7          	jalr	-428(ra) # 80003e78 <iunlock>
  iput(ip);
    8000402c:	8526                	mv	a0,s1
    8000402e:	00000097          	auipc	ra,0x0
    80004032:	f42080e7          	jalr	-190(ra) # 80003f70 <iput>
}
    80004036:	60e2                	ld	ra,24(sp)
    80004038:	6442                	ld	s0,16(sp)
    8000403a:	64a2                	ld	s1,8(sp)
    8000403c:	6105                	addi	sp,sp,32
    8000403e:	8082                	ret

0000000080004040 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80004040:	1141                	addi	sp,sp,-16
    80004042:	e422                	sd	s0,8(sp)
    80004044:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80004046:	411c                	lw	a5,0(a0)
    80004048:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    8000404a:	415c                	lw	a5,4(a0)
    8000404c:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    8000404e:	04451783          	lh	a5,68(a0)
    80004052:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80004056:	04a51783          	lh	a5,74(a0)
    8000405a:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    8000405e:	04c56783          	lwu	a5,76(a0)
    80004062:	e99c                	sd	a5,16(a1)
}
    80004064:	6422                	ld	s0,8(sp)
    80004066:	0141                	addi	sp,sp,16
    80004068:	8082                	ret

000000008000406a <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000406a:	457c                	lw	a5,76(a0)
    8000406c:	0ed7e963          	bltu	a5,a3,8000415e <readi+0xf4>
{
    80004070:	7159                	addi	sp,sp,-112
    80004072:	f486                	sd	ra,104(sp)
    80004074:	f0a2                	sd	s0,96(sp)
    80004076:	eca6                	sd	s1,88(sp)
    80004078:	e8ca                	sd	s2,80(sp)
    8000407a:	e4ce                	sd	s3,72(sp)
    8000407c:	e0d2                	sd	s4,64(sp)
    8000407e:	fc56                	sd	s5,56(sp)
    80004080:	f85a                	sd	s6,48(sp)
    80004082:	f45e                	sd	s7,40(sp)
    80004084:	f062                	sd	s8,32(sp)
    80004086:	ec66                	sd	s9,24(sp)
    80004088:	e86a                	sd	s10,16(sp)
    8000408a:	e46e                	sd	s11,8(sp)
    8000408c:	1880                	addi	s0,sp,112
    8000408e:	8b2a                	mv	s6,a0
    80004090:	8bae                	mv	s7,a1
    80004092:	8a32                	mv	s4,a2
    80004094:	84b6                	mv	s1,a3
    80004096:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80004098:	9f35                	addw	a4,a4,a3
    return 0;
    8000409a:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    8000409c:	0ad76063          	bltu	a4,a3,8000413c <readi+0xd2>
  if(off + n > ip->size)
    800040a0:	00e7f463          	bgeu	a5,a4,800040a8 <readi+0x3e>
    n = ip->size - off;
    800040a4:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800040a8:	0a0a8963          	beqz	s5,8000415a <readi+0xf0>
    800040ac:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    800040ae:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800040b2:	5c7d                	li	s8,-1
    800040b4:	a82d                	j	800040ee <readi+0x84>
    800040b6:	020d1d93          	slli	s11,s10,0x20
    800040ba:	020ddd93          	srli	s11,s11,0x20
    800040be:	05890793          	addi	a5,s2,88
    800040c2:	86ee                	mv	a3,s11
    800040c4:	963e                	add	a2,a2,a5
    800040c6:	85d2                	mv	a1,s4
    800040c8:	855e                	mv	a0,s7
    800040ca:	ffffe097          	auipc	ra,0xffffe
    800040ce:	704080e7          	jalr	1796(ra) # 800027ce <either_copyout>
    800040d2:	05850d63          	beq	a0,s8,8000412c <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    800040d6:	854a                	mv	a0,s2
    800040d8:	fffff097          	auipc	ra,0xfffff
    800040dc:	5f4080e7          	jalr	1524(ra) # 800036cc <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800040e0:	013d09bb          	addw	s3,s10,s3
    800040e4:	009d04bb          	addw	s1,s10,s1
    800040e8:	9a6e                	add	s4,s4,s11
    800040ea:	0559f763          	bgeu	s3,s5,80004138 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    800040ee:	00a4d59b          	srliw	a1,s1,0xa
    800040f2:	855a                	mv	a0,s6
    800040f4:	00000097          	auipc	ra,0x0
    800040f8:	8a2080e7          	jalr	-1886(ra) # 80003996 <bmap>
    800040fc:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80004100:	cd85                	beqz	a1,80004138 <readi+0xce>
    bp = bread(ip->dev, addr);
    80004102:	000b2503          	lw	a0,0(s6)
    80004106:	fffff097          	auipc	ra,0xfffff
    8000410a:	496080e7          	jalr	1174(ra) # 8000359c <bread>
    8000410e:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004110:	3ff4f613          	andi	a2,s1,1023
    80004114:	40cc87bb          	subw	a5,s9,a2
    80004118:	413a873b          	subw	a4,s5,s3
    8000411c:	8d3e                	mv	s10,a5
    8000411e:	2781                	sext.w	a5,a5
    80004120:	0007069b          	sext.w	a3,a4
    80004124:	f8f6f9e3          	bgeu	a3,a5,800040b6 <readi+0x4c>
    80004128:	8d3a                	mv	s10,a4
    8000412a:	b771                	j	800040b6 <readi+0x4c>
      brelse(bp);
    8000412c:	854a                	mv	a0,s2
    8000412e:	fffff097          	auipc	ra,0xfffff
    80004132:	59e080e7          	jalr	1438(ra) # 800036cc <brelse>
      tot = -1;
    80004136:	59fd                	li	s3,-1
  }
  return tot;
    80004138:	0009851b          	sext.w	a0,s3
}
    8000413c:	70a6                	ld	ra,104(sp)
    8000413e:	7406                	ld	s0,96(sp)
    80004140:	64e6                	ld	s1,88(sp)
    80004142:	6946                	ld	s2,80(sp)
    80004144:	69a6                	ld	s3,72(sp)
    80004146:	6a06                	ld	s4,64(sp)
    80004148:	7ae2                	ld	s5,56(sp)
    8000414a:	7b42                	ld	s6,48(sp)
    8000414c:	7ba2                	ld	s7,40(sp)
    8000414e:	7c02                	ld	s8,32(sp)
    80004150:	6ce2                	ld	s9,24(sp)
    80004152:	6d42                	ld	s10,16(sp)
    80004154:	6da2                	ld	s11,8(sp)
    80004156:	6165                	addi	sp,sp,112
    80004158:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000415a:	89d6                	mv	s3,s5
    8000415c:	bff1                	j	80004138 <readi+0xce>
    return 0;
    8000415e:	4501                	li	a0,0
}
    80004160:	8082                	ret

0000000080004162 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004162:	457c                	lw	a5,76(a0)
    80004164:	10d7e863          	bltu	a5,a3,80004274 <writei+0x112>
{
    80004168:	7159                	addi	sp,sp,-112
    8000416a:	f486                	sd	ra,104(sp)
    8000416c:	f0a2                	sd	s0,96(sp)
    8000416e:	eca6                	sd	s1,88(sp)
    80004170:	e8ca                	sd	s2,80(sp)
    80004172:	e4ce                	sd	s3,72(sp)
    80004174:	e0d2                	sd	s4,64(sp)
    80004176:	fc56                	sd	s5,56(sp)
    80004178:	f85a                	sd	s6,48(sp)
    8000417a:	f45e                	sd	s7,40(sp)
    8000417c:	f062                	sd	s8,32(sp)
    8000417e:	ec66                	sd	s9,24(sp)
    80004180:	e86a                	sd	s10,16(sp)
    80004182:	e46e                	sd	s11,8(sp)
    80004184:	1880                	addi	s0,sp,112
    80004186:	8aaa                	mv	s5,a0
    80004188:	8bae                	mv	s7,a1
    8000418a:	8a32                	mv	s4,a2
    8000418c:	8936                	mv	s2,a3
    8000418e:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80004190:	00e687bb          	addw	a5,a3,a4
    80004194:	0ed7e263          	bltu	a5,a3,80004278 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80004198:	00043737          	lui	a4,0x43
    8000419c:	0ef76063          	bltu	a4,a5,8000427c <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800041a0:	0c0b0863          	beqz	s6,80004270 <writei+0x10e>
    800041a4:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    800041a6:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800041aa:	5c7d                	li	s8,-1
    800041ac:	a091                	j	800041f0 <writei+0x8e>
    800041ae:	020d1d93          	slli	s11,s10,0x20
    800041b2:	020ddd93          	srli	s11,s11,0x20
    800041b6:	05848793          	addi	a5,s1,88
    800041ba:	86ee                	mv	a3,s11
    800041bc:	8652                	mv	a2,s4
    800041be:	85de                	mv	a1,s7
    800041c0:	953e                	add	a0,a0,a5
    800041c2:	ffffe097          	auipc	ra,0xffffe
    800041c6:	662080e7          	jalr	1634(ra) # 80002824 <either_copyin>
    800041ca:	07850263          	beq	a0,s8,8000422e <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    800041ce:	8526                	mv	a0,s1
    800041d0:	00000097          	auipc	ra,0x0
    800041d4:	780080e7          	jalr	1920(ra) # 80004950 <log_write>
    brelse(bp);
    800041d8:	8526                	mv	a0,s1
    800041da:	fffff097          	auipc	ra,0xfffff
    800041de:	4f2080e7          	jalr	1266(ra) # 800036cc <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800041e2:	013d09bb          	addw	s3,s10,s3
    800041e6:	012d093b          	addw	s2,s10,s2
    800041ea:	9a6e                	add	s4,s4,s11
    800041ec:	0569f663          	bgeu	s3,s6,80004238 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    800041f0:	00a9559b          	srliw	a1,s2,0xa
    800041f4:	8556                	mv	a0,s5
    800041f6:	fffff097          	auipc	ra,0xfffff
    800041fa:	7a0080e7          	jalr	1952(ra) # 80003996 <bmap>
    800041fe:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80004202:	c99d                	beqz	a1,80004238 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80004204:	000aa503          	lw	a0,0(s5)
    80004208:	fffff097          	auipc	ra,0xfffff
    8000420c:	394080e7          	jalr	916(ra) # 8000359c <bread>
    80004210:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004212:	3ff97513          	andi	a0,s2,1023
    80004216:	40ac87bb          	subw	a5,s9,a0
    8000421a:	413b073b          	subw	a4,s6,s3
    8000421e:	8d3e                	mv	s10,a5
    80004220:	2781                	sext.w	a5,a5
    80004222:	0007069b          	sext.w	a3,a4
    80004226:	f8f6f4e3          	bgeu	a3,a5,800041ae <writei+0x4c>
    8000422a:	8d3a                	mv	s10,a4
    8000422c:	b749                	j	800041ae <writei+0x4c>
      brelse(bp);
    8000422e:	8526                	mv	a0,s1
    80004230:	fffff097          	auipc	ra,0xfffff
    80004234:	49c080e7          	jalr	1180(ra) # 800036cc <brelse>
  }

  if(off > ip->size)
    80004238:	04caa783          	lw	a5,76(s5)
    8000423c:	0127f463          	bgeu	a5,s2,80004244 <writei+0xe2>
    ip->size = off;
    80004240:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80004244:	8556                	mv	a0,s5
    80004246:	00000097          	auipc	ra,0x0
    8000424a:	aa6080e7          	jalr	-1370(ra) # 80003cec <iupdate>

  return tot;
    8000424e:	0009851b          	sext.w	a0,s3
}
    80004252:	70a6                	ld	ra,104(sp)
    80004254:	7406                	ld	s0,96(sp)
    80004256:	64e6                	ld	s1,88(sp)
    80004258:	6946                	ld	s2,80(sp)
    8000425a:	69a6                	ld	s3,72(sp)
    8000425c:	6a06                	ld	s4,64(sp)
    8000425e:	7ae2                	ld	s5,56(sp)
    80004260:	7b42                	ld	s6,48(sp)
    80004262:	7ba2                	ld	s7,40(sp)
    80004264:	7c02                	ld	s8,32(sp)
    80004266:	6ce2                	ld	s9,24(sp)
    80004268:	6d42                	ld	s10,16(sp)
    8000426a:	6da2                	ld	s11,8(sp)
    8000426c:	6165                	addi	sp,sp,112
    8000426e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004270:	89da                	mv	s3,s6
    80004272:	bfc9                	j	80004244 <writei+0xe2>
    return -1;
    80004274:	557d                	li	a0,-1
}
    80004276:	8082                	ret
    return -1;
    80004278:	557d                	li	a0,-1
    8000427a:	bfe1                	j	80004252 <writei+0xf0>
    return -1;
    8000427c:	557d                	li	a0,-1
    8000427e:	bfd1                	j	80004252 <writei+0xf0>

0000000080004280 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004280:	1141                	addi	sp,sp,-16
    80004282:	e406                	sd	ra,8(sp)
    80004284:	e022                	sd	s0,0(sp)
    80004286:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004288:	4639                	li	a2,14
    8000428a:	ffffd097          	auipc	ra,0xffffd
    8000428e:	b18080e7          	jalr	-1256(ra) # 80000da2 <strncmp>
}
    80004292:	60a2                	ld	ra,8(sp)
    80004294:	6402                	ld	s0,0(sp)
    80004296:	0141                	addi	sp,sp,16
    80004298:	8082                	ret

000000008000429a <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    8000429a:	7139                	addi	sp,sp,-64
    8000429c:	fc06                	sd	ra,56(sp)
    8000429e:	f822                	sd	s0,48(sp)
    800042a0:	f426                	sd	s1,40(sp)
    800042a2:	f04a                	sd	s2,32(sp)
    800042a4:	ec4e                	sd	s3,24(sp)
    800042a6:	e852                	sd	s4,16(sp)
    800042a8:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800042aa:	04451703          	lh	a4,68(a0)
    800042ae:	4785                	li	a5,1
    800042b0:	00f71a63          	bne	a4,a5,800042c4 <dirlookup+0x2a>
    800042b4:	892a                	mv	s2,a0
    800042b6:	89ae                	mv	s3,a1
    800042b8:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800042ba:	457c                	lw	a5,76(a0)
    800042bc:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800042be:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800042c0:	e79d                	bnez	a5,800042ee <dirlookup+0x54>
    800042c2:	a8a5                	j	8000433a <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800042c4:	00004517          	auipc	a0,0x4
    800042c8:	36450513          	addi	a0,a0,868 # 80008628 <syscalls+0x1c8>
    800042cc:	ffffc097          	auipc	ra,0xffffc
    800042d0:	272080e7          	jalr	626(ra) # 8000053e <panic>
      panic("dirlookup read");
    800042d4:	00004517          	auipc	a0,0x4
    800042d8:	36c50513          	addi	a0,a0,876 # 80008640 <syscalls+0x1e0>
    800042dc:	ffffc097          	auipc	ra,0xffffc
    800042e0:	262080e7          	jalr	610(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800042e4:	24c1                	addiw	s1,s1,16
    800042e6:	04c92783          	lw	a5,76(s2)
    800042ea:	04f4f763          	bgeu	s1,a5,80004338 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800042ee:	4741                	li	a4,16
    800042f0:	86a6                	mv	a3,s1
    800042f2:	fc040613          	addi	a2,s0,-64
    800042f6:	4581                	li	a1,0
    800042f8:	854a                	mv	a0,s2
    800042fa:	00000097          	auipc	ra,0x0
    800042fe:	d70080e7          	jalr	-656(ra) # 8000406a <readi>
    80004302:	47c1                	li	a5,16
    80004304:	fcf518e3          	bne	a0,a5,800042d4 <dirlookup+0x3a>
    if(de.inum == 0)
    80004308:	fc045783          	lhu	a5,-64(s0)
    8000430c:	dfe1                	beqz	a5,800042e4 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    8000430e:	fc240593          	addi	a1,s0,-62
    80004312:	854e                	mv	a0,s3
    80004314:	00000097          	auipc	ra,0x0
    80004318:	f6c080e7          	jalr	-148(ra) # 80004280 <namecmp>
    8000431c:	f561                	bnez	a0,800042e4 <dirlookup+0x4a>
      if(poff)
    8000431e:	000a0463          	beqz	s4,80004326 <dirlookup+0x8c>
        *poff = off;
    80004322:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004326:	fc045583          	lhu	a1,-64(s0)
    8000432a:	00092503          	lw	a0,0(s2)
    8000432e:	fffff097          	auipc	ra,0xfffff
    80004332:	750080e7          	jalr	1872(ra) # 80003a7e <iget>
    80004336:	a011                	j	8000433a <dirlookup+0xa0>
  return 0;
    80004338:	4501                	li	a0,0
}
    8000433a:	70e2                	ld	ra,56(sp)
    8000433c:	7442                	ld	s0,48(sp)
    8000433e:	74a2                	ld	s1,40(sp)
    80004340:	7902                	ld	s2,32(sp)
    80004342:	69e2                	ld	s3,24(sp)
    80004344:	6a42                	ld	s4,16(sp)
    80004346:	6121                	addi	sp,sp,64
    80004348:	8082                	ret

000000008000434a <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    8000434a:	711d                	addi	sp,sp,-96
    8000434c:	ec86                	sd	ra,88(sp)
    8000434e:	e8a2                	sd	s0,80(sp)
    80004350:	e4a6                	sd	s1,72(sp)
    80004352:	e0ca                	sd	s2,64(sp)
    80004354:	fc4e                	sd	s3,56(sp)
    80004356:	f852                	sd	s4,48(sp)
    80004358:	f456                	sd	s5,40(sp)
    8000435a:	f05a                	sd	s6,32(sp)
    8000435c:	ec5e                	sd	s7,24(sp)
    8000435e:	e862                	sd	s8,16(sp)
    80004360:	e466                	sd	s9,8(sp)
    80004362:	1080                	addi	s0,sp,96
    80004364:	84aa                	mv	s1,a0
    80004366:	8aae                	mv	s5,a1
    80004368:	8a32                	mv	s4,a2
  struct inode *ip, *next;

  if(*path == '/')
    8000436a:	00054703          	lbu	a4,0(a0)
    8000436e:	02f00793          	li	a5,47
    80004372:	02f70363          	beq	a4,a5,80004398 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004376:	ffffd097          	auipc	ra,0xffffd
    8000437a:	79c080e7          	jalr	1948(ra) # 80001b12 <myproc>
    8000437e:	15053503          	ld	a0,336(a0)
    80004382:	00000097          	auipc	ra,0x0
    80004386:	9f6080e7          	jalr	-1546(ra) # 80003d78 <idup>
    8000438a:	89aa                	mv	s3,a0
  while(*path == '/')
    8000438c:	02f00913          	li	s2,47
  len = path - s;
    80004390:	4b01                	li	s6,0
  if(len >= DIRSIZ)
    80004392:	4c35                	li	s8,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004394:	4b85                	li	s7,1
    80004396:	a865                	j	8000444e <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80004398:	4585                	li	a1,1
    8000439a:	4505                	li	a0,1
    8000439c:	fffff097          	auipc	ra,0xfffff
    800043a0:	6e2080e7          	jalr	1762(ra) # 80003a7e <iget>
    800043a4:	89aa                	mv	s3,a0
    800043a6:	b7dd                	j	8000438c <namex+0x42>
      iunlockput(ip);
    800043a8:	854e                	mv	a0,s3
    800043aa:	00000097          	auipc	ra,0x0
    800043ae:	c6e080e7          	jalr	-914(ra) # 80004018 <iunlockput>
      return 0;
    800043b2:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800043b4:	854e                	mv	a0,s3
    800043b6:	60e6                	ld	ra,88(sp)
    800043b8:	6446                	ld	s0,80(sp)
    800043ba:	64a6                	ld	s1,72(sp)
    800043bc:	6906                	ld	s2,64(sp)
    800043be:	79e2                	ld	s3,56(sp)
    800043c0:	7a42                	ld	s4,48(sp)
    800043c2:	7aa2                	ld	s5,40(sp)
    800043c4:	7b02                	ld	s6,32(sp)
    800043c6:	6be2                	ld	s7,24(sp)
    800043c8:	6c42                	ld	s8,16(sp)
    800043ca:	6ca2                	ld	s9,8(sp)
    800043cc:	6125                	addi	sp,sp,96
    800043ce:	8082                	ret
      iunlock(ip);
    800043d0:	854e                	mv	a0,s3
    800043d2:	00000097          	auipc	ra,0x0
    800043d6:	aa6080e7          	jalr	-1370(ra) # 80003e78 <iunlock>
      return ip;
    800043da:	bfe9                	j	800043b4 <namex+0x6a>
      iunlockput(ip);
    800043dc:	854e                	mv	a0,s3
    800043de:	00000097          	auipc	ra,0x0
    800043e2:	c3a080e7          	jalr	-966(ra) # 80004018 <iunlockput>
      return 0;
    800043e6:	89e6                	mv	s3,s9
    800043e8:	b7f1                	j	800043b4 <namex+0x6a>
  len = path - s;
    800043ea:	40b48633          	sub	a2,s1,a1
    800043ee:	00060c9b          	sext.w	s9,a2
  if(len >= DIRSIZ)
    800043f2:	099c5463          	bge	s8,s9,8000447a <namex+0x130>
    memmove(name, s, DIRSIZ);
    800043f6:	4639                	li	a2,14
    800043f8:	8552                	mv	a0,s4
    800043fa:	ffffd097          	auipc	ra,0xffffd
    800043fe:	934080e7          	jalr	-1740(ra) # 80000d2e <memmove>
  while(*path == '/')
    80004402:	0004c783          	lbu	a5,0(s1)
    80004406:	01279763          	bne	a5,s2,80004414 <namex+0xca>
    path++;
    8000440a:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000440c:	0004c783          	lbu	a5,0(s1)
    80004410:	ff278de3          	beq	a5,s2,8000440a <namex+0xc0>
    ilock(ip);
    80004414:	854e                	mv	a0,s3
    80004416:	00000097          	auipc	ra,0x0
    8000441a:	9a0080e7          	jalr	-1632(ra) # 80003db6 <ilock>
    if(ip->type != T_DIR){
    8000441e:	04499783          	lh	a5,68(s3)
    80004422:	f97793e3          	bne	a5,s7,800043a8 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004426:	000a8563          	beqz	s5,80004430 <namex+0xe6>
    8000442a:	0004c783          	lbu	a5,0(s1)
    8000442e:	d3cd                	beqz	a5,800043d0 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004430:	865a                	mv	a2,s6
    80004432:	85d2                	mv	a1,s4
    80004434:	854e                	mv	a0,s3
    80004436:	00000097          	auipc	ra,0x0
    8000443a:	e64080e7          	jalr	-412(ra) # 8000429a <dirlookup>
    8000443e:	8caa                	mv	s9,a0
    80004440:	dd51                	beqz	a0,800043dc <namex+0x92>
    iunlockput(ip);
    80004442:	854e                	mv	a0,s3
    80004444:	00000097          	auipc	ra,0x0
    80004448:	bd4080e7          	jalr	-1068(ra) # 80004018 <iunlockput>
    ip = next;
    8000444c:	89e6                	mv	s3,s9
  while(*path == '/')
    8000444e:	0004c783          	lbu	a5,0(s1)
    80004452:	05279763          	bne	a5,s2,800044a0 <namex+0x156>
    path++;
    80004456:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004458:	0004c783          	lbu	a5,0(s1)
    8000445c:	ff278de3          	beq	a5,s2,80004456 <namex+0x10c>
  if(*path == 0)
    80004460:	c79d                	beqz	a5,8000448e <namex+0x144>
    path++;
    80004462:	85a6                	mv	a1,s1
  len = path - s;
    80004464:	8cda                	mv	s9,s6
    80004466:	865a                	mv	a2,s6
  while(*path != '/' && *path != 0)
    80004468:	01278963          	beq	a5,s2,8000447a <namex+0x130>
    8000446c:	dfbd                	beqz	a5,800043ea <namex+0xa0>
    path++;
    8000446e:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004470:	0004c783          	lbu	a5,0(s1)
    80004474:	ff279ce3          	bne	a5,s2,8000446c <namex+0x122>
    80004478:	bf8d                	j	800043ea <namex+0xa0>
    memmove(name, s, len);
    8000447a:	2601                	sext.w	a2,a2
    8000447c:	8552                	mv	a0,s4
    8000447e:	ffffd097          	auipc	ra,0xffffd
    80004482:	8b0080e7          	jalr	-1872(ra) # 80000d2e <memmove>
    name[len] = 0;
    80004486:	9cd2                	add	s9,s9,s4
    80004488:	000c8023          	sb	zero,0(s9) # 2000 <_entry-0x7fffe000>
    8000448c:	bf9d                	j	80004402 <namex+0xb8>
  if(nameiparent){
    8000448e:	f20a83e3          	beqz	s5,800043b4 <namex+0x6a>
    iput(ip);
    80004492:	854e                	mv	a0,s3
    80004494:	00000097          	auipc	ra,0x0
    80004498:	adc080e7          	jalr	-1316(ra) # 80003f70 <iput>
    return 0;
    8000449c:	4981                	li	s3,0
    8000449e:	bf19                	j	800043b4 <namex+0x6a>
  if(*path == 0)
    800044a0:	d7fd                	beqz	a5,8000448e <namex+0x144>
  while(*path != '/' && *path != 0)
    800044a2:	0004c783          	lbu	a5,0(s1)
    800044a6:	85a6                	mv	a1,s1
    800044a8:	b7d1                	j	8000446c <namex+0x122>

00000000800044aa <dirlink>:
{
    800044aa:	7139                	addi	sp,sp,-64
    800044ac:	fc06                	sd	ra,56(sp)
    800044ae:	f822                	sd	s0,48(sp)
    800044b0:	f426                	sd	s1,40(sp)
    800044b2:	f04a                	sd	s2,32(sp)
    800044b4:	ec4e                	sd	s3,24(sp)
    800044b6:	e852                	sd	s4,16(sp)
    800044b8:	0080                	addi	s0,sp,64
    800044ba:	892a                	mv	s2,a0
    800044bc:	8a2e                	mv	s4,a1
    800044be:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800044c0:	4601                	li	a2,0
    800044c2:	00000097          	auipc	ra,0x0
    800044c6:	dd8080e7          	jalr	-552(ra) # 8000429a <dirlookup>
    800044ca:	e93d                	bnez	a0,80004540 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800044cc:	04c92483          	lw	s1,76(s2)
    800044d0:	c49d                	beqz	s1,800044fe <dirlink+0x54>
    800044d2:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800044d4:	4741                	li	a4,16
    800044d6:	86a6                	mv	a3,s1
    800044d8:	fc040613          	addi	a2,s0,-64
    800044dc:	4581                	li	a1,0
    800044de:	854a                	mv	a0,s2
    800044e0:	00000097          	auipc	ra,0x0
    800044e4:	b8a080e7          	jalr	-1142(ra) # 8000406a <readi>
    800044e8:	47c1                	li	a5,16
    800044ea:	06f51163          	bne	a0,a5,8000454c <dirlink+0xa2>
    if(de.inum == 0)
    800044ee:	fc045783          	lhu	a5,-64(s0)
    800044f2:	c791                	beqz	a5,800044fe <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800044f4:	24c1                	addiw	s1,s1,16
    800044f6:	04c92783          	lw	a5,76(s2)
    800044fa:	fcf4ede3          	bltu	s1,a5,800044d4 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800044fe:	4639                	li	a2,14
    80004500:	85d2                	mv	a1,s4
    80004502:	fc240513          	addi	a0,s0,-62
    80004506:	ffffd097          	auipc	ra,0xffffd
    8000450a:	8d8080e7          	jalr	-1832(ra) # 80000dde <strncpy>
  de.inum = inum;
    8000450e:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004512:	4741                	li	a4,16
    80004514:	86a6                	mv	a3,s1
    80004516:	fc040613          	addi	a2,s0,-64
    8000451a:	4581                	li	a1,0
    8000451c:	854a                	mv	a0,s2
    8000451e:	00000097          	auipc	ra,0x0
    80004522:	c44080e7          	jalr	-956(ra) # 80004162 <writei>
    80004526:	1541                	addi	a0,a0,-16
    80004528:	00a03533          	snez	a0,a0
    8000452c:	40a00533          	neg	a0,a0
}
    80004530:	70e2                	ld	ra,56(sp)
    80004532:	7442                	ld	s0,48(sp)
    80004534:	74a2                	ld	s1,40(sp)
    80004536:	7902                	ld	s2,32(sp)
    80004538:	69e2                	ld	s3,24(sp)
    8000453a:	6a42                	ld	s4,16(sp)
    8000453c:	6121                	addi	sp,sp,64
    8000453e:	8082                	ret
    iput(ip);
    80004540:	00000097          	auipc	ra,0x0
    80004544:	a30080e7          	jalr	-1488(ra) # 80003f70 <iput>
    return -1;
    80004548:	557d                	li	a0,-1
    8000454a:	b7dd                	j	80004530 <dirlink+0x86>
      panic("dirlink read");
    8000454c:	00004517          	auipc	a0,0x4
    80004550:	10450513          	addi	a0,a0,260 # 80008650 <syscalls+0x1f0>
    80004554:	ffffc097          	auipc	ra,0xffffc
    80004558:	fea080e7          	jalr	-22(ra) # 8000053e <panic>

000000008000455c <namei>:

struct inode*
namei(char *path)
{
    8000455c:	1101                	addi	sp,sp,-32
    8000455e:	ec06                	sd	ra,24(sp)
    80004560:	e822                	sd	s0,16(sp)
    80004562:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004564:	fe040613          	addi	a2,s0,-32
    80004568:	4581                	li	a1,0
    8000456a:	00000097          	auipc	ra,0x0
    8000456e:	de0080e7          	jalr	-544(ra) # 8000434a <namex>
}
    80004572:	60e2                	ld	ra,24(sp)
    80004574:	6442                	ld	s0,16(sp)
    80004576:	6105                	addi	sp,sp,32
    80004578:	8082                	ret

000000008000457a <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000457a:	1141                	addi	sp,sp,-16
    8000457c:	e406                	sd	ra,8(sp)
    8000457e:	e022                	sd	s0,0(sp)
    80004580:	0800                	addi	s0,sp,16
    80004582:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004584:	4585                	li	a1,1
    80004586:	00000097          	auipc	ra,0x0
    8000458a:	dc4080e7          	jalr	-572(ra) # 8000434a <namex>
}
    8000458e:	60a2                	ld	ra,8(sp)
    80004590:	6402                	ld	s0,0(sp)
    80004592:	0141                	addi	sp,sp,16
    80004594:	8082                	ret

0000000080004596 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004596:	1101                	addi	sp,sp,-32
    80004598:	ec06                	sd	ra,24(sp)
    8000459a:	e822                	sd	s0,16(sp)
    8000459c:	e426                	sd	s1,8(sp)
    8000459e:	e04a                	sd	s2,0(sp)
    800045a0:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800045a2:	00020917          	auipc	s2,0x20
    800045a6:	9be90913          	addi	s2,s2,-1602 # 80023f60 <log>
    800045aa:	01892583          	lw	a1,24(s2)
    800045ae:	02892503          	lw	a0,40(s2)
    800045b2:	fffff097          	auipc	ra,0xfffff
    800045b6:	fea080e7          	jalr	-22(ra) # 8000359c <bread>
    800045ba:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800045bc:	02c92683          	lw	a3,44(s2)
    800045c0:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800045c2:	02d05763          	blez	a3,800045f0 <write_head+0x5a>
    800045c6:	00020797          	auipc	a5,0x20
    800045ca:	9ca78793          	addi	a5,a5,-1590 # 80023f90 <log+0x30>
    800045ce:	05c50713          	addi	a4,a0,92
    800045d2:	36fd                	addiw	a3,a3,-1
    800045d4:	1682                	slli	a3,a3,0x20
    800045d6:	9281                	srli	a3,a3,0x20
    800045d8:	068a                	slli	a3,a3,0x2
    800045da:	00020617          	auipc	a2,0x20
    800045de:	9ba60613          	addi	a2,a2,-1606 # 80023f94 <log+0x34>
    800045e2:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800045e4:	4390                	lw	a2,0(a5)
    800045e6:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800045e8:	0791                	addi	a5,a5,4
    800045ea:	0711                	addi	a4,a4,4
    800045ec:	fed79ce3          	bne	a5,a3,800045e4 <write_head+0x4e>
  }
  bwrite(buf);
    800045f0:	8526                	mv	a0,s1
    800045f2:	fffff097          	auipc	ra,0xfffff
    800045f6:	09c080e7          	jalr	156(ra) # 8000368e <bwrite>
  brelse(buf);
    800045fa:	8526                	mv	a0,s1
    800045fc:	fffff097          	auipc	ra,0xfffff
    80004600:	0d0080e7          	jalr	208(ra) # 800036cc <brelse>
}
    80004604:	60e2                	ld	ra,24(sp)
    80004606:	6442                	ld	s0,16(sp)
    80004608:	64a2                	ld	s1,8(sp)
    8000460a:	6902                	ld	s2,0(sp)
    8000460c:	6105                	addi	sp,sp,32
    8000460e:	8082                	ret

0000000080004610 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004610:	00020797          	auipc	a5,0x20
    80004614:	97c7a783          	lw	a5,-1668(a5) # 80023f8c <log+0x2c>
    80004618:	0af05d63          	blez	a5,800046d2 <install_trans+0xc2>
{
    8000461c:	7139                	addi	sp,sp,-64
    8000461e:	fc06                	sd	ra,56(sp)
    80004620:	f822                	sd	s0,48(sp)
    80004622:	f426                	sd	s1,40(sp)
    80004624:	f04a                	sd	s2,32(sp)
    80004626:	ec4e                	sd	s3,24(sp)
    80004628:	e852                	sd	s4,16(sp)
    8000462a:	e456                	sd	s5,8(sp)
    8000462c:	e05a                	sd	s6,0(sp)
    8000462e:	0080                	addi	s0,sp,64
    80004630:	8b2a                	mv	s6,a0
    80004632:	00020a97          	auipc	s5,0x20
    80004636:	95ea8a93          	addi	s5,s5,-1698 # 80023f90 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000463a:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000463c:	00020997          	auipc	s3,0x20
    80004640:	92498993          	addi	s3,s3,-1756 # 80023f60 <log>
    80004644:	a00d                	j	80004666 <install_trans+0x56>
    brelse(lbuf);
    80004646:	854a                	mv	a0,s2
    80004648:	fffff097          	auipc	ra,0xfffff
    8000464c:	084080e7          	jalr	132(ra) # 800036cc <brelse>
    brelse(dbuf);
    80004650:	8526                	mv	a0,s1
    80004652:	fffff097          	auipc	ra,0xfffff
    80004656:	07a080e7          	jalr	122(ra) # 800036cc <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000465a:	2a05                	addiw	s4,s4,1
    8000465c:	0a91                	addi	s5,s5,4
    8000465e:	02c9a783          	lw	a5,44(s3)
    80004662:	04fa5e63          	bge	s4,a5,800046be <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004666:	0189a583          	lw	a1,24(s3)
    8000466a:	014585bb          	addw	a1,a1,s4
    8000466e:	2585                	addiw	a1,a1,1
    80004670:	0289a503          	lw	a0,40(s3)
    80004674:	fffff097          	auipc	ra,0xfffff
    80004678:	f28080e7          	jalr	-216(ra) # 8000359c <bread>
    8000467c:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000467e:	000aa583          	lw	a1,0(s5)
    80004682:	0289a503          	lw	a0,40(s3)
    80004686:	fffff097          	auipc	ra,0xfffff
    8000468a:	f16080e7          	jalr	-234(ra) # 8000359c <bread>
    8000468e:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004690:	40000613          	li	a2,1024
    80004694:	05890593          	addi	a1,s2,88
    80004698:	05850513          	addi	a0,a0,88
    8000469c:	ffffc097          	auipc	ra,0xffffc
    800046a0:	692080e7          	jalr	1682(ra) # 80000d2e <memmove>
    bwrite(dbuf);  // write dst to disk
    800046a4:	8526                	mv	a0,s1
    800046a6:	fffff097          	auipc	ra,0xfffff
    800046aa:	fe8080e7          	jalr	-24(ra) # 8000368e <bwrite>
    if(recovering == 0)
    800046ae:	f80b1ce3          	bnez	s6,80004646 <install_trans+0x36>
      bunpin(dbuf);
    800046b2:	8526                	mv	a0,s1
    800046b4:	fffff097          	auipc	ra,0xfffff
    800046b8:	0f2080e7          	jalr	242(ra) # 800037a6 <bunpin>
    800046bc:	b769                	j	80004646 <install_trans+0x36>
}
    800046be:	70e2                	ld	ra,56(sp)
    800046c0:	7442                	ld	s0,48(sp)
    800046c2:	74a2                	ld	s1,40(sp)
    800046c4:	7902                	ld	s2,32(sp)
    800046c6:	69e2                	ld	s3,24(sp)
    800046c8:	6a42                	ld	s4,16(sp)
    800046ca:	6aa2                	ld	s5,8(sp)
    800046cc:	6b02                	ld	s6,0(sp)
    800046ce:	6121                	addi	sp,sp,64
    800046d0:	8082                	ret
    800046d2:	8082                	ret

00000000800046d4 <initlog>:
{
    800046d4:	7179                	addi	sp,sp,-48
    800046d6:	f406                	sd	ra,40(sp)
    800046d8:	f022                	sd	s0,32(sp)
    800046da:	ec26                	sd	s1,24(sp)
    800046dc:	e84a                	sd	s2,16(sp)
    800046de:	e44e                	sd	s3,8(sp)
    800046e0:	1800                	addi	s0,sp,48
    800046e2:	892a                	mv	s2,a0
    800046e4:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800046e6:	00020497          	auipc	s1,0x20
    800046ea:	87a48493          	addi	s1,s1,-1926 # 80023f60 <log>
    800046ee:	00004597          	auipc	a1,0x4
    800046f2:	f7258593          	addi	a1,a1,-142 # 80008660 <syscalls+0x200>
    800046f6:	8526                	mv	a0,s1
    800046f8:	ffffc097          	auipc	ra,0xffffc
    800046fc:	44e080e7          	jalr	1102(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    80004700:	0149a583          	lw	a1,20(s3)
    80004704:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004706:	0109a783          	lw	a5,16(s3)
    8000470a:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000470c:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004710:	854a                	mv	a0,s2
    80004712:	fffff097          	auipc	ra,0xfffff
    80004716:	e8a080e7          	jalr	-374(ra) # 8000359c <bread>
  log.lh.n = lh->n;
    8000471a:	4d34                	lw	a3,88(a0)
    8000471c:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000471e:	02d05563          	blez	a3,80004748 <initlog+0x74>
    80004722:	05c50793          	addi	a5,a0,92
    80004726:	00020717          	auipc	a4,0x20
    8000472a:	86a70713          	addi	a4,a4,-1942 # 80023f90 <log+0x30>
    8000472e:	36fd                	addiw	a3,a3,-1
    80004730:	1682                	slli	a3,a3,0x20
    80004732:	9281                	srli	a3,a3,0x20
    80004734:	068a                	slli	a3,a3,0x2
    80004736:	06050613          	addi	a2,a0,96
    8000473a:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    8000473c:	4390                	lw	a2,0(a5)
    8000473e:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004740:	0791                	addi	a5,a5,4
    80004742:	0711                	addi	a4,a4,4
    80004744:	fed79ce3          	bne	a5,a3,8000473c <initlog+0x68>
  brelse(buf);
    80004748:	fffff097          	auipc	ra,0xfffff
    8000474c:	f84080e7          	jalr	-124(ra) # 800036cc <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004750:	4505                	li	a0,1
    80004752:	00000097          	auipc	ra,0x0
    80004756:	ebe080e7          	jalr	-322(ra) # 80004610 <install_trans>
  log.lh.n = 0;
    8000475a:	00020797          	auipc	a5,0x20
    8000475e:	8207a923          	sw	zero,-1998(a5) # 80023f8c <log+0x2c>
  write_head(); // clear the log
    80004762:	00000097          	auipc	ra,0x0
    80004766:	e34080e7          	jalr	-460(ra) # 80004596 <write_head>
}
    8000476a:	70a2                	ld	ra,40(sp)
    8000476c:	7402                	ld	s0,32(sp)
    8000476e:	64e2                	ld	s1,24(sp)
    80004770:	6942                	ld	s2,16(sp)
    80004772:	69a2                	ld	s3,8(sp)
    80004774:	6145                	addi	sp,sp,48
    80004776:	8082                	ret

0000000080004778 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004778:	1101                	addi	sp,sp,-32
    8000477a:	ec06                	sd	ra,24(sp)
    8000477c:	e822                	sd	s0,16(sp)
    8000477e:	e426                	sd	s1,8(sp)
    80004780:	e04a                	sd	s2,0(sp)
    80004782:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004784:	0001f517          	auipc	a0,0x1f
    80004788:	7dc50513          	addi	a0,a0,2012 # 80023f60 <log>
    8000478c:	ffffc097          	auipc	ra,0xffffc
    80004790:	44a080e7          	jalr	1098(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    80004794:	0001f497          	auipc	s1,0x1f
    80004798:	7cc48493          	addi	s1,s1,1996 # 80023f60 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000479c:	4979                	li	s2,30
    8000479e:	a039                	j	800047ac <begin_op+0x34>
      sleep(&log, &log.lock);
    800047a0:	85a6                	mv	a1,s1
    800047a2:	8526                	mv	a0,s1
    800047a4:	ffffe097          	auipc	ra,0xffffe
    800047a8:	bde080e7          	jalr	-1058(ra) # 80002382 <sleep>
    if(log.committing){
    800047ac:	50dc                	lw	a5,36(s1)
    800047ae:	fbed                	bnez	a5,800047a0 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800047b0:	509c                	lw	a5,32(s1)
    800047b2:	0017871b          	addiw	a4,a5,1
    800047b6:	0007069b          	sext.w	a3,a4
    800047ba:	0027179b          	slliw	a5,a4,0x2
    800047be:	9fb9                	addw	a5,a5,a4
    800047c0:	0017979b          	slliw	a5,a5,0x1
    800047c4:	54d8                	lw	a4,44(s1)
    800047c6:	9fb9                	addw	a5,a5,a4
    800047c8:	00f95963          	bge	s2,a5,800047da <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800047cc:	85a6                	mv	a1,s1
    800047ce:	8526                	mv	a0,s1
    800047d0:	ffffe097          	auipc	ra,0xffffe
    800047d4:	bb2080e7          	jalr	-1102(ra) # 80002382 <sleep>
    800047d8:	bfd1                	j	800047ac <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800047da:	0001f517          	auipc	a0,0x1f
    800047de:	78650513          	addi	a0,a0,1926 # 80023f60 <log>
    800047e2:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800047e4:	ffffc097          	auipc	ra,0xffffc
    800047e8:	4a6080e7          	jalr	1190(ra) # 80000c8a <release>
      break;
    }
  }
}
    800047ec:	60e2                	ld	ra,24(sp)
    800047ee:	6442                	ld	s0,16(sp)
    800047f0:	64a2                	ld	s1,8(sp)
    800047f2:	6902                	ld	s2,0(sp)
    800047f4:	6105                	addi	sp,sp,32
    800047f6:	8082                	ret

00000000800047f8 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800047f8:	7139                	addi	sp,sp,-64
    800047fa:	fc06                	sd	ra,56(sp)
    800047fc:	f822                	sd	s0,48(sp)
    800047fe:	f426                	sd	s1,40(sp)
    80004800:	f04a                	sd	s2,32(sp)
    80004802:	ec4e                	sd	s3,24(sp)
    80004804:	e852                	sd	s4,16(sp)
    80004806:	e456                	sd	s5,8(sp)
    80004808:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000480a:	0001f497          	auipc	s1,0x1f
    8000480e:	75648493          	addi	s1,s1,1878 # 80023f60 <log>
    80004812:	8526                	mv	a0,s1
    80004814:	ffffc097          	auipc	ra,0xffffc
    80004818:	3c2080e7          	jalr	962(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    8000481c:	509c                	lw	a5,32(s1)
    8000481e:	37fd                	addiw	a5,a5,-1
    80004820:	0007891b          	sext.w	s2,a5
    80004824:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004826:	50dc                	lw	a5,36(s1)
    80004828:	e7b9                	bnez	a5,80004876 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000482a:	04091e63          	bnez	s2,80004886 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    8000482e:	0001f497          	auipc	s1,0x1f
    80004832:	73248493          	addi	s1,s1,1842 # 80023f60 <log>
    80004836:	4785                	li	a5,1
    80004838:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000483a:	8526                	mv	a0,s1
    8000483c:	ffffc097          	auipc	ra,0xffffc
    80004840:	44e080e7          	jalr	1102(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004844:	54dc                	lw	a5,44(s1)
    80004846:	06f04763          	bgtz	a5,800048b4 <end_op+0xbc>
    acquire(&log.lock);
    8000484a:	0001f497          	auipc	s1,0x1f
    8000484e:	71648493          	addi	s1,s1,1814 # 80023f60 <log>
    80004852:	8526                	mv	a0,s1
    80004854:	ffffc097          	auipc	ra,0xffffc
    80004858:	382080e7          	jalr	898(ra) # 80000bd6 <acquire>
    log.committing = 0;
    8000485c:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004860:	8526                	mv	a0,s1
    80004862:	ffffe097          	auipc	ra,0xffffe
    80004866:	b84080e7          	jalr	-1148(ra) # 800023e6 <wakeup>
    release(&log.lock);
    8000486a:	8526                	mv	a0,s1
    8000486c:	ffffc097          	auipc	ra,0xffffc
    80004870:	41e080e7          	jalr	1054(ra) # 80000c8a <release>
}
    80004874:	a03d                	j	800048a2 <end_op+0xaa>
    panic("log.committing");
    80004876:	00004517          	auipc	a0,0x4
    8000487a:	df250513          	addi	a0,a0,-526 # 80008668 <syscalls+0x208>
    8000487e:	ffffc097          	auipc	ra,0xffffc
    80004882:	cc0080e7          	jalr	-832(ra) # 8000053e <panic>
    wakeup(&log);
    80004886:	0001f497          	auipc	s1,0x1f
    8000488a:	6da48493          	addi	s1,s1,1754 # 80023f60 <log>
    8000488e:	8526                	mv	a0,s1
    80004890:	ffffe097          	auipc	ra,0xffffe
    80004894:	b56080e7          	jalr	-1194(ra) # 800023e6 <wakeup>
  release(&log.lock);
    80004898:	8526                	mv	a0,s1
    8000489a:	ffffc097          	auipc	ra,0xffffc
    8000489e:	3f0080e7          	jalr	1008(ra) # 80000c8a <release>
}
    800048a2:	70e2                	ld	ra,56(sp)
    800048a4:	7442                	ld	s0,48(sp)
    800048a6:	74a2                	ld	s1,40(sp)
    800048a8:	7902                	ld	s2,32(sp)
    800048aa:	69e2                	ld	s3,24(sp)
    800048ac:	6a42                	ld	s4,16(sp)
    800048ae:	6aa2                	ld	s5,8(sp)
    800048b0:	6121                	addi	sp,sp,64
    800048b2:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800048b4:	0001fa97          	auipc	s5,0x1f
    800048b8:	6dca8a93          	addi	s5,s5,1756 # 80023f90 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800048bc:	0001fa17          	auipc	s4,0x1f
    800048c0:	6a4a0a13          	addi	s4,s4,1700 # 80023f60 <log>
    800048c4:	018a2583          	lw	a1,24(s4)
    800048c8:	012585bb          	addw	a1,a1,s2
    800048cc:	2585                	addiw	a1,a1,1
    800048ce:	028a2503          	lw	a0,40(s4)
    800048d2:	fffff097          	auipc	ra,0xfffff
    800048d6:	cca080e7          	jalr	-822(ra) # 8000359c <bread>
    800048da:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800048dc:	000aa583          	lw	a1,0(s5)
    800048e0:	028a2503          	lw	a0,40(s4)
    800048e4:	fffff097          	auipc	ra,0xfffff
    800048e8:	cb8080e7          	jalr	-840(ra) # 8000359c <bread>
    800048ec:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800048ee:	40000613          	li	a2,1024
    800048f2:	05850593          	addi	a1,a0,88
    800048f6:	05848513          	addi	a0,s1,88
    800048fa:	ffffc097          	auipc	ra,0xffffc
    800048fe:	434080e7          	jalr	1076(ra) # 80000d2e <memmove>
    bwrite(to);  // write the log
    80004902:	8526                	mv	a0,s1
    80004904:	fffff097          	auipc	ra,0xfffff
    80004908:	d8a080e7          	jalr	-630(ra) # 8000368e <bwrite>
    brelse(from);
    8000490c:	854e                	mv	a0,s3
    8000490e:	fffff097          	auipc	ra,0xfffff
    80004912:	dbe080e7          	jalr	-578(ra) # 800036cc <brelse>
    brelse(to);
    80004916:	8526                	mv	a0,s1
    80004918:	fffff097          	auipc	ra,0xfffff
    8000491c:	db4080e7          	jalr	-588(ra) # 800036cc <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004920:	2905                	addiw	s2,s2,1
    80004922:	0a91                	addi	s5,s5,4
    80004924:	02ca2783          	lw	a5,44(s4)
    80004928:	f8f94ee3          	blt	s2,a5,800048c4 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000492c:	00000097          	auipc	ra,0x0
    80004930:	c6a080e7          	jalr	-918(ra) # 80004596 <write_head>
    install_trans(0); // Now install writes to home locations
    80004934:	4501                	li	a0,0
    80004936:	00000097          	auipc	ra,0x0
    8000493a:	cda080e7          	jalr	-806(ra) # 80004610 <install_trans>
    log.lh.n = 0;
    8000493e:	0001f797          	auipc	a5,0x1f
    80004942:	6407a723          	sw	zero,1614(a5) # 80023f8c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004946:	00000097          	auipc	ra,0x0
    8000494a:	c50080e7          	jalr	-944(ra) # 80004596 <write_head>
    8000494e:	bdf5                	j	8000484a <end_op+0x52>

0000000080004950 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004950:	1101                	addi	sp,sp,-32
    80004952:	ec06                	sd	ra,24(sp)
    80004954:	e822                	sd	s0,16(sp)
    80004956:	e426                	sd	s1,8(sp)
    80004958:	e04a                	sd	s2,0(sp)
    8000495a:	1000                	addi	s0,sp,32
    8000495c:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    8000495e:	0001f917          	auipc	s2,0x1f
    80004962:	60290913          	addi	s2,s2,1538 # 80023f60 <log>
    80004966:	854a                	mv	a0,s2
    80004968:	ffffc097          	auipc	ra,0xffffc
    8000496c:	26e080e7          	jalr	622(ra) # 80000bd6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004970:	02c92603          	lw	a2,44(s2)
    80004974:	47f5                	li	a5,29
    80004976:	06c7c563          	blt	a5,a2,800049e0 <log_write+0x90>
    8000497a:	0001f797          	auipc	a5,0x1f
    8000497e:	6027a783          	lw	a5,1538(a5) # 80023f7c <log+0x1c>
    80004982:	37fd                	addiw	a5,a5,-1
    80004984:	04f65e63          	bge	a2,a5,800049e0 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004988:	0001f797          	auipc	a5,0x1f
    8000498c:	5f87a783          	lw	a5,1528(a5) # 80023f80 <log+0x20>
    80004990:	06f05063          	blez	a5,800049f0 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004994:	4781                	li	a5,0
    80004996:	06c05563          	blez	a2,80004a00 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000499a:	44cc                	lw	a1,12(s1)
    8000499c:	0001f717          	auipc	a4,0x1f
    800049a0:	5f470713          	addi	a4,a4,1524 # 80023f90 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800049a4:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800049a6:	4314                	lw	a3,0(a4)
    800049a8:	04b68c63          	beq	a3,a1,80004a00 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800049ac:	2785                	addiw	a5,a5,1
    800049ae:	0711                	addi	a4,a4,4
    800049b0:	fef61be3          	bne	a2,a5,800049a6 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800049b4:	0621                	addi	a2,a2,8
    800049b6:	060a                	slli	a2,a2,0x2
    800049b8:	0001f797          	auipc	a5,0x1f
    800049bc:	5a878793          	addi	a5,a5,1448 # 80023f60 <log>
    800049c0:	963e                	add	a2,a2,a5
    800049c2:	44dc                	lw	a5,12(s1)
    800049c4:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800049c6:	8526                	mv	a0,s1
    800049c8:	fffff097          	auipc	ra,0xfffff
    800049cc:	da2080e7          	jalr	-606(ra) # 8000376a <bpin>
    log.lh.n++;
    800049d0:	0001f717          	auipc	a4,0x1f
    800049d4:	59070713          	addi	a4,a4,1424 # 80023f60 <log>
    800049d8:	575c                	lw	a5,44(a4)
    800049da:	2785                	addiw	a5,a5,1
    800049dc:	d75c                	sw	a5,44(a4)
    800049de:	a835                	j	80004a1a <log_write+0xca>
    panic("too big a transaction");
    800049e0:	00004517          	auipc	a0,0x4
    800049e4:	c9850513          	addi	a0,a0,-872 # 80008678 <syscalls+0x218>
    800049e8:	ffffc097          	auipc	ra,0xffffc
    800049ec:	b56080e7          	jalr	-1194(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    800049f0:	00004517          	auipc	a0,0x4
    800049f4:	ca050513          	addi	a0,a0,-864 # 80008690 <syscalls+0x230>
    800049f8:	ffffc097          	auipc	ra,0xffffc
    800049fc:	b46080e7          	jalr	-1210(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004a00:	00878713          	addi	a4,a5,8
    80004a04:	00271693          	slli	a3,a4,0x2
    80004a08:	0001f717          	auipc	a4,0x1f
    80004a0c:	55870713          	addi	a4,a4,1368 # 80023f60 <log>
    80004a10:	9736                	add	a4,a4,a3
    80004a12:	44d4                	lw	a3,12(s1)
    80004a14:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004a16:	faf608e3          	beq	a2,a5,800049c6 <log_write+0x76>
  }
  release(&log.lock);
    80004a1a:	0001f517          	auipc	a0,0x1f
    80004a1e:	54650513          	addi	a0,a0,1350 # 80023f60 <log>
    80004a22:	ffffc097          	auipc	ra,0xffffc
    80004a26:	268080e7          	jalr	616(ra) # 80000c8a <release>
}
    80004a2a:	60e2                	ld	ra,24(sp)
    80004a2c:	6442                	ld	s0,16(sp)
    80004a2e:	64a2                	ld	s1,8(sp)
    80004a30:	6902                	ld	s2,0(sp)
    80004a32:	6105                	addi	sp,sp,32
    80004a34:	8082                	ret

0000000080004a36 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004a36:	1101                	addi	sp,sp,-32
    80004a38:	ec06                	sd	ra,24(sp)
    80004a3a:	e822                	sd	s0,16(sp)
    80004a3c:	e426                	sd	s1,8(sp)
    80004a3e:	e04a                	sd	s2,0(sp)
    80004a40:	1000                	addi	s0,sp,32
    80004a42:	84aa                	mv	s1,a0
    80004a44:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004a46:	00004597          	auipc	a1,0x4
    80004a4a:	c6a58593          	addi	a1,a1,-918 # 800086b0 <syscalls+0x250>
    80004a4e:	0521                	addi	a0,a0,8
    80004a50:	ffffc097          	auipc	ra,0xffffc
    80004a54:	0f6080e7          	jalr	246(ra) # 80000b46 <initlock>
  lk->name = name;
    80004a58:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004a5c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004a60:	0204a423          	sw	zero,40(s1)
}
    80004a64:	60e2                	ld	ra,24(sp)
    80004a66:	6442                	ld	s0,16(sp)
    80004a68:	64a2                	ld	s1,8(sp)
    80004a6a:	6902                	ld	s2,0(sp)
    80004a6c:	6105                	addi	sp,sp,32
    80004a6e:	8082                	ret

0000000080004a70 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004a70:	1101                	addi	sp,sp,-32
    80004a72:	ec06                	sd	ra,24(sp)
    80004a74:	e822                	sd	s0,16(sp)
    80004a76:	e426                	sd	s1,8(sp)
    80004a78:	e04a                	sd	s2,0(sp)
    80004a7a:	1000                	addi	s0,sp,32
    80004a7c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004a7e:	00850913          	addi	s2,a0,8
    80004a82:	854a                	mv	a0,s2
    80004a84:	ffffc097          	auipc	ra,0xffffc
    80004a88:	152080e7          	jalr	338(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    80004a8c:	409c                	lw	a5,0(s1)
    80004a8e:	cb89                	beqz	a5,80004aa0 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004a90:	85ca                	mv	a1,s2
    80004a92:	8526                	mv	a0,s1
    80004a94:	ffffe097          	auipc	ra,0xffffe
    80004a98:	8ee080e7          	jalr	-1810(ra) # 80002382 <sleep>
  while (lk->locked) {
    80004a9c:	409c                	lw	a5,0(s1)
    80004a9e:	fbed                	bnez	a5,80004a90 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004aa0:	4785                	li	a5,1
    80004aa2:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004aa4:	ffffd097          	auipc	ra,0xffffd
    80004aa8:	06e080e7          	jalr	110(ra) # 80001b12 <myproc>
    80004aac:	591c                	lw	a5,48(a0)
    80004aae:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004ab0:	854a                	mv	a0,s2
    80004ab2:	ffffc097          	auipc	ra,0xffffc
    80004ab6:	1d8080e7          	jalr	472(ra) # 80000c8a <release>
}
    80004aba:	60e2                	ld	ra,24(sp)
    80004abc:	6442                	ld	s0,16(sp)
    80004abe:	64a2                	ld	s1,8(sp)
    80004ac0:	6902                	ld	s2,0(sp)
    80004ac2:	6105                	addi	sp,sp,32
    80004ac4:	8082                	ret

0000000080004ac6 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004ac6:	1101                	addi	sp,sp,-32
    80004ac8:	ec06                	sd	ra,24(sp)
    80004aca:	e822                	sd	s0,16(sp)
    80004acc:	e426                	sd	s1,8(sp)
    80004ace:	e04a                	sd	s2,0(sp)
    80004ad0:	1000                	addi	s0,sp,32
    80004ad2:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004ad4:	00850913          	addi	s2,a0,8
    80004ad8:	854a                	mv	a0,s2
    80004ada:	ffffc097          	auipc	ra,0xffffc
    80004ade:	0fc080e7          	jalr	252(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    80004ae2:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004ae6:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004aea:	8526                	mv	a0,s1
    80004aec:	ffffe097          	auipc	ra,0xffffe
    80004af0:	8fa080e7          	jalr	-1798(ra) # 800023e6 <wakeup>
  release(&lk->lk);
    80004af4:	854a                	mv	a0,s2
    80004af6:	ffffc097          	auipc	ra,0xffffc
    80004afa:	194080e7          	jalr	404(ra) # 80000c8a <release>
}
    80004afe:	60e2                	ld	ra,24(sp)
    80004b00:	6442                	ld	s0,16(sp)
    80004b02:	64a2                	ld	s1,8(sp)
    80004b04:	6902                	ld	s2,0(sp)
    80004b06:	6105                	addi	sp,sp,32
    80004b08:	8082                	ret

0000000080004b0a <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004b0a:	7179                	addi	sp,sp,-48
    80004b0c:	f406                	sd	ra,40(sp)
    80004b0e:	f022                	sd	s0,32(sp)
    80004b10:	ec26                	sd	s1,24(sp)
    80004b12:	e84a                	sd	s2,16(sp)
    80004b14:	e44e                	sd	s3,8(sp)
    80004b16:	1800                	addi	s0,sp,48
    80004b18:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004b1a:	00850913          	addi	s2,a0,8
    80004b1e:	854a                	mv	a0,s2
    80004b20:	ffffc097          	auipc	ra,0xffffc
    80004b24:	0b6080e7          	jalr	182(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004b28:	409c                	lw	a5,0(s1)
    80004b2a:	ef99                	bnez	a5,80004b48 <holdingsleep+0x3e>
    80004b2c:	4481                	li	s1,0
  release(&lk->lk);
    80004b2e:	854a                	mv	a0,s2
    80004b30:	ffffc097          	auipc	ra,0xffffc
    80004b34:	15a080e7          	jalr	346(ra) # 80000c8a <release>
  return r;
}
    80004b38:	8526                	mv	a0,s1
    80004b3a:	70a2                	ld	ra,40(sp)
    80004b3c:	7402                	ld	s0,32(sp)
    80004b3e:	64e2                	ld	s1,24(sp)
    80004b40:	6942                	ld	s2,16(sp)
    80004b42:	69a2                	ld	s3,8(sp)
    80004b44:	6145                	addi	sp,sp,48
    80004b46:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004b48:	0284a983          	lw	s3,40(s1)
    80004b4c:	ffffd097          	auipc	ra,0xffffd
    80004b50:	fc6080e7          	jalr	-58(ra) # 80001b12 <myproc>
    80004b54:	5904                	lw	s1,48(a0)
    80004b56:	413484b3          	sub	s1,s1,s3
    80004b5a:	0014b493          	seqz	s1,s1
    80004b5e:	bfc1                	j	80004b2e <holdingsleep+0x24>

0000000080004b60 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004b60:	1141                	addi	sp,sp,-16
    80004b62:	e406                	sd	ra,8(sp)
    80004b64:	e022                	sd	s0,0(sp)
    80004b66:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004b68:	00004597          	auipc	a1,0x4
    80004b6c:	b5858593          	addi	a1,a1,-1192 # 800086c0 <syscalls+0x260>
    80004b70:	0001f517          	auipc	a0,0x1f
    80004b74:	53850513          	addi	a0,a0,1336 # 800240a8 <ftable>
    80004b78:	ffffc097          	auipc	ra,0xffffc
    80004b7c:	fce080e7          	jalr	-50(ra) # 80000b46 <initlock>
}
    80004b80:	60a2                	ld	ra,8(sp)
    80004b82:	6402                	ld	s0,0(sp)
    80004b84:	0141                	addi	sp,sp,16
    80004b86:	8082                	ret

0000000080004b88 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004b88:	1101                	addi	sp,sp,-32
    80004b8a:	ec06                	sd	ra,24(sp)
    80004b8c:	e822                	sd	s0,16(sp)
    80004b8e:	e426                	sd	s1,8(sp)
    80004b90:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004b92:	0001f517          	auipc	a0,0x1f
    80004b96:	51650513          	addi	a0,a0,1302 # 800240a8 <ftable>
    80004b9a:	ffffc097          	auipc	ra,0xffffc
    80004b9e:	03c080e7          	jalr	60(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004ba2:	0001f497          	auipc	s1,0x1f
    80004ba6:	51e48493          	addi	s1,s1,1310 # 800240c0 <ftable+0x18>
    80004baa:	00020717          	auipc	a4,0x20
    80004bae:	4b670713          	addi	a4,a4,1206 # 80025060 <disk>
    if(f->ref == 0){
    80004bb2:	40dc                	lw	a5,4(s1)
    80004bb4:	cf99                	beqz	a5,80004bd2 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004bb6:	02848493          	addi	s1,s1,40
    80004bba:	fee49ce3          	bne	s1,a4,80004bb2 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004bbe:	0001f517          	auipc	a0,0x1f
    80004bc2:	4ea50513          	addi	a0,a0,1258 # 800240a8 <ftable>
    80004bc6:	ffffc097          	auipc	ra,0xffffc
    80004bca:	0c4080e7          	jalr	196(ra) # 80000c8a <release>
  return 0;
    80004bce:	4481                	li	s1,0
    80004bd0:	a819                	j	80004be6 <filealloc+0x5e>
      f->ref = 1;
    80004bd2:	4785                	li	a5,1
    80004bd4:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004bd6:	0001f517          	auipc	a0,0x1f
    80004bda:	4d250513          	addi	a0,a0,1234 # 800240a8 <ftable>
    80004bde:	ffffc097          	auipc	ra,0xffffc
    80004be2:	0ac080e7          	jalr	172(ra) # 80000c8a <release>
}
    80004be6:	8526                	mv	a0,s1
    80004be8:	60e2                	ld	ra,24(sp)
    80004bea:	6442                	ld	s0,16(sp)
    80004bec:	64a2                	ld	s1,8(sp)
    80004bee:	6105                	addi	sp,sp,32
    80004bf0:	8082                	ret

0000000080004bf2 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004bf2:	1101                	addi	sp,sp,-32
    80004bf4:	ec06                	sd	ra,24(sp)
    80004bf6:	e822                	sd	s0,16(sp)
    80004bf8:	e426                	sd	s1,8(sp)
    80004bfa:	1000                	addi	s0,sp,32
    80004bfc:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004bfe:	0001f517          	auipc	a0,0x1f
    80004c02:	4aa50513          	addi	a0,a0,1194 # 800240a8 <ftable>
    80004c06:	ffffc097          	auipc	ra,0xffffc
    80004c0a:	fd0080e7          	jalr	-48(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004c0e:	40dc                	lw	a5,4(s1)
    80004c10:	02f05263          	blez	a5,80004c34 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004c14:	2785                	addiw	a5,a5,1
    80004c16:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004c18:	0001f517          	auipc	a0,0x1f
    80004c1c:	49050513          	addi	a0,a0,1168 # 800240a8 <ftable>
    80004c20:	ffffc097          	auipc	ra,0xffffc
    80004c24:	06a080e7          	jalr	106(ra) # 80000c8a <release>
  return f;
}
    80004c28:	8526                	mv	a0,s1
    80004c2a:	60e2                	ld	ra,24(sp)
    80004c2c:	6442                	ld	s0,16(sp)
    80004c2e:	64a2                	ld	s1,8(sp)
    80004c30:	6105                	addi	sp,sp,32
    80004c32:	8082                	ret
    panic("filedup");
    80004c34:	00004517          	auipc	a0,0x4
    80004c38:	a9450513          	addi	a0,a0,-1388 # 800086c8 <syscalls+0x268>
    80004c3c:	ffffc097          	auipc	ra,0xffffc
    80004c40:	902080e7          	jalr	-1790(ra) # 8000053e <panic>

0000000080004c44 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004c44:	7139                	addi	sp,sp,-64
    80004c46:	fc06                	sd	ra,56(sp)
    80004c48:	f822                	sd	s0,48(sp)
    80004c4a:	f426                	sd	s1,40(sp)
    80004c4c:	f04a                	sd	s2,32(sp)
    80004c4e:	ec4e                	sd	s3,24(sp)
    80004c50:	e852                	sd	s4,16(sp)
    80004c52:	e456                	sd	s5,8(sp)
    80004c54:	0080                	addi	s0,sp,64
    80004c56:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004c58:	0001f517          	auipc	a0,0x1f
    80004c5c:	45050513          	addi	a0,a0,1104 # 800240a8 <ftable>
    80004c60:	ffffc097          	auipc	ra,0xffffc
    80004c64:	f76080e7          	jalr	-138(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004c68:	40dc                	lw	a5,4(s1)
    80004c6a:	06f05163          	blez	a5,80004ccc <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004c6e:	37fd                	addiw	a5,a5,-1
    80004c70:	0007871b          	sext.w	a4,a5
    80004c74:	c0dc                	sw	a5,4(s1)
    80004c76:	06e04363          	bgtz	a4,80004cdc <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004c7a:	0004a903          	lw	s2,0(s1)
    80004c7e:	0094ca83          	lbu	s5,9(s1)
    80004c82:	0104ba03          	ld	s4,16(s1)
    80004c86:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004c8a:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004c8e:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004c92:	0001f517          	auipc	a0,0x1f
    80004c96:	41650513          	addi	a0,a0,1046 # 800240a8 <ftable>
    80004c9a:	ffffc097          	auipc	ra,0xffffc
    80004c9e:	ff0080e7          	jalr	-16(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    80004ca2:	4785                	li	a5,1
    80004ca4:	04f90d63          	beq	s2,a5,80004cfe <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004ca8:	3979                	addiw	s2,s2,-2
    80004caa:	4785                	li	a5,1
    80004cac:	0527e063          	bltu	a5,s2,80004cec <fileclose+0xa8>
    begin_op();
    80004cb0:	00000097          	auipc	ra,0x0
    80004cb4:	ac8080e7          	jalr	-1336(ra) # 80004778 <begin_op>
    iput(ff.ip);
    80004cb8:	854e                	mv	a0,s3
    80004cba:	fffff097          	auipc	ra,0xfffff
    80004cbe:	2b6080e7          	jalr	694(ra) # 80003f70 <iput>
    end_op();
    80004cc2:	00000097          	auipc	ra,0x0
    80004cc6:	b36080e7          	jalr	-1226(ra) # 800047f8 <end_op>
    80004cca:	a00d                	j	80004cec <fileclose+0xa8>
    panic("fileclose");
    80004ccc:	00004517          	auipc	a0,0x4
    80004cd0:	a0450513          	addi	a0,a0,-1532 # 800086d0 <syscalls+0x270>
    80004cd4:	ffffc097          	auipc	ra,0xffffc
    80004cd8:	86a080e7          	jalr	-1942(ra) # 8000053e <panic>
    release(&ftable.lock);
    80004cdc:	0001f517          	auipc	a0,0x1f
    80004ce0:	3cc50513          	addi	a0,a0,972 # 800240a8 <ftable>
    80004ce4:	ffffc097          	auipc	ra,0xffffc
    80004ce8:	fa6080e7          	jalr	-90(ra) # 80000c8a <release>
  }
}
    80004cec:	70e2                	ld	ra,56(sp)
    80004cee:	7442                	ld	s0,48(sp)
    80004cf0:	74a2                	ld	s1,40(sp)
    80004cf2:	7902                	ld	s2,32(sp)
    80004cf4:	69e2                	ld	s3,24(sp)
    80004cf6:	6a42                	ld	s4,16(sp)
    80004cf8:	6aa2                	ld	s5,8(sp)
    80004cfa:	6121                	addi	sp,sp,64
    80004cfc:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004cfe:	85d6                	mv	a1,s5
    80004d00:	8552                	mv	a0,s4
    80004d02:	00000097          	auipc	ra,0x0
    80004d06:	34c080e7          	jalr	844(ra) # 8000504e <pipeclose>
    80004d0a:	b7cd                	j	80004cec <fileclose+0xa8>

0000000080004d0c <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004d0c:	715d                	addi	sp,sp,-80
    80004d0e:	e486                	sd	ra,72(sp)
    80004d10:	e0a2                	sd	s0,64(sp)
    80004d12:	fc26                	sd	s1,56(sp)
    80004d14:	f84a                	sd	s2,48(sp)
    80004d16:	f44e                	sd	s3,40(sp)
    80004d18:	0880                	addi	s0,sp,80
    80004d1a:	84aa                	mv	s1,a0
    80004d1c:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004d1e:	ffffd097          	auipc	ra,0xffffd
    80004d22:	df4080e7          	jalr	-524(ra) # 80001b12 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004d26:	409c                	lw	a5,0(s1)
    80004d28:	37f9                	addiw	a5,a5,-2
    80004d2a:	4705                	li	a4,1
    80004d2c:	04f76763          	bltu	a4,a5,80004d7a <filestat+0x6e>
    80004d30:	892a                	mv	s2,a0
    ilock(f->ip);
    80004d32:	6c88                	ld	a0,24(s1)
    80004d34:	fffff097          	auipc	ra,0xfffff
    80004d38:	082080e7          	jalr	130(ra) # 80003db6 <ilock>
    stati(f->ip, &st);
    80004d3c:	fb840593          	addi	a1,s0,-72
    80004d40:	6c88                	ld	a0,24(s1)
    80004d42:	fffff097          	auipc	ra,0xfffff
    80004d46:	2fe080e7          	jalr	766(ra) # 80004040 <stati>
    iunlock(f->ip);
    80004d4a:	6c88                	ld	a0,24(s1)
    80004d4c:	fffff097          	auipc	ra,0xfffff
    80004d50:	12c080e7          	jalr	300(ra) # 80003e78 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004d54:	46e1                	li	a3,24
    80004d56:	fb840613          	addi	a2,s0,-72
    80004d5a:	85ce                	mv	a1,s3
    80004d5c:	05093503          	ld	a0,80(s2)
    80004d60:	ffffd097          	auipc	ra,0xffffd
    80004d64:	908080e7          	jalr	-1784(ra) # 80001668 <copyout>
    80004d68:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004d6c:	60a6                	ld	ra,72(sp)
    80004d6e:	6406                	ld	s0,64(sp)
    80004d70:	74e2                	ld	s1,56(sp)
    80004d72:	7942                	ld	s2,48(sp)
    80004d74:	79a2                	ld	s3,40(sp)
    80004d76:	6161                	addi	sp,sp,80
    80004d78:	8082                	ret
  return -1;
    80004d7a:	557d                	li	a0,-1
    80004d7c:	bfc5                	j	80004d6c <filestat+0x60>

0000000080004d7e <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004d7e:	7179                	addi	sp,sp,-48
    80004d80:	f406                	sd	ra,40(sp)
    80004d82:	f022                	sd	s0,32(sp)
    80004d84:	ec26                	sd	s1,24(sp)
    80004d86:	e84a                	sd	s2,16(sp)
    80004d88:	e44e                	sd	s3,8(sp)
    80004d8a:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004d8c:	00854783          	lbu	a5,8(a0)
    80004d90:	c3d5                	beqz	a5,80004e34 <fileread+0xb6>
    80004d92:	84aa                	mv	s1,a0
    80004d94:	89ae                	mv	s3,a1
    80004d96:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004d98:	411c                	lw	a5,0(a0)
    80004d9a:	4705                	li	a4,1
    80004d9c:	04e78963          	beq	a5,a4,80004dee <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004da0:	470d                	li	a4,3
    80004da2:	04e78d63          	beq	a5,a4,80004dfc <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004da6:	4709                	li	a4,2
    80004da8:	06e79e63          	bne	a5,a4,80004e24 <fileread+0xa6>
    ilock(f->ip);
    80004dac:	6d08                	ld	a0,24(a0)
    80004dae:	fffff097          	auipc	ra,0xfffff
    80004db2:	008080e7          	jalr	8(ra) # 80003db6 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004db6:	874a                	mv	a4,s2
    80004db8:	5094                	lw	a3,32(s1)
    80004dba:	864e                	mv	a2,s3
    80004dbc:	4585                	li	a1,1
    80004dbe:	6c88                	ld	a0,24(s1)
    80004dc0:	fffff097          	auipc	ra,0xfffff
    80004dc4:	2aa080e7          	jalr	682(ra) # 8000406a <readi>
    80004dc8:	892a                	mv	s2,a0
    80004dca:	00a05563          	blez	a0,80004dd4 <fileread+0x56>
      f->off += r;
    80004dce:	509c                	lw	a5,32(s1)
    80004dd0:	9fa9                	addw	a5,a5,a0
    80004dd2:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004dd4:	6c88                	ld	a0,24(s1)
    80004dd6:	fffff097          	auipc	ra,0xfffff
    80004dda:	0a2080e7          	jalr	162(ra) # 80003e78 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004dde:	854a                	mv	a0,s2
    80004de0:	70a2                	ld	ra,40(sp)
    80004de2:	7402                	ld	s0,32(sp)
    80004de4:	64e2                	ld	s1,24(sp)
    80004de6:	6942                	ld	s2,16(sp)
    80004de8:	69a2                	ld	s3,8(sp)
    80004dea:	6145                	addi	sp,sp,48
    80004dec:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004dee:	6908                	ld	a0,16(a0)
    80004df0:	00000097          	auipc	ra,0x0
    80004df4:	3c6080e7          	jalr	966(ra) # 800051b6 <piperead>
    80004df8:	892a                	mv	s2,a0
    80004dfa:	b7d5                	j	80004dde <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004dfc:	02451783          	lh	a5,36(a0)
    80004e00:	03079693          	slli	a3,a5,0x30
    80004e04:	92c1                	srli	a3,a3,0x30
    80004e06:	4725                	li	a4,9
    80004e08:	02d76863          	bltu	a4,a3,80004e38 <fileread+0xba>
    80004e0c:	0792                	slli	a5,a5,0x4
    80004e0e:	0001f717          	auipc	a4,0x1f
    80004e12:	1fa70713          	addi	a4,a4,506 # 80024008 <devsw>
    80004e16:	97ba                	add	a5,a5,a4
    80004e18:	639c                	ld	a5,0(a5)
    80004e1a:	c38d                	beqz	a5,80004e3c <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004e1c:	4505                	li	a0,1
    80004e1e:	9782                	jalr	a5
    80004e20:	892a                	mv	s2,a0
    80004e22:	bf75                	j	80004dde <fileread+0x60>
    panic("fileread");
    80004e24:	00004517          	auipc	a0,0x4
    80004e28:	8bc50513          	addi	a0,a0,-1860 # 800086e0 <syscalls+0x280>
    80004e2c:	ffffb097          	auipc	ra,0xffffb
    80004e30:	712080e7          	jalr	1810(ra) # 8000053e <panic>
    return -1;
    80004e34:	597d                	li	s2,-1
    80004e36:	b765                	j	80004dde <fileread+0x60>
      return -1;
    80004e38:	597d                	li	s2,-1
    80004e3a:	b755                	j	80004dde <fileread+0x60>
    80004e3c:	597d                	li	s2,-1
    80004e3e:	b745                	j	80004dde <fileread+0x60>

0000000080004e40 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004e40:	715d                	addi	sp,sp,-80
    80004e42:	e486                	sd	ra,72(sp)
    80004e44:	e0a2                	sd	s0,64(sp)
    80004e46:	fc26                	sd	s1,56(sp)
    80004e48:	f84a                	sd	s2,48(sp)
    80004e4a:	f44e                	sd	s3,40(sp)
    80004e4c:	f052                	sd	s4,32(sp)
    80004e4e:	ec56                	sd	s5,24(sp)
    80004e50:	e85a                	sd	s6,16(sp)
    80004e52:	e45e                	sd	s7,8(sp)
    80004e54:	e062                	sd	s8,0(sp)
    80004e56:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004e58:	00954783          	lbu	a5,9(a0)
    80004e5c:	10078663          	beqz	a5,80004f68 <filewrite+0x128>
    80004e60:	892a                	mv	s2,a0
    80004e62:	8aae                	mv	s5,a1
    80004e64:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004e66:	411c                	lw	a5,0(a0)
    80004e68:	4705                	li	a4,1
    80004e6a:	02e78263          	beq	a5,a4,80004e8e <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004e6e:	470d                	li	a4,3
    80004e70:	02e78663          	beq	a5,a4,80004e9c <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004e74:	4709                	li	a4,2
    80004e76:	0ee79163          	bne	a5,a4,80004f58 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004e7a:	0ac05d63          	blez	a2,80004f34 <filewrite+0xf4>
    int i = 0;
    80004e7e:	4981                	li	s3,0
    80004e80:	6b05                	lui	s6,0x1
    80004e82:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004e86:	6b85                	lui	s7,0x1
    80004e88:	c00b8b9b          	addiw	s7,s7,-1024
    80004e8c:	a861                	j	80004f24 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004e8e:	6908                	ld	a0,16(a0)
    80004e90:	00000097          	auipc	ra,0x0
    80004e94:	22e080e7          	jalr	558(ra) # 800050be <pipewrite>
    80004e98:	8a2a                	mv	s4,a0
    80004e9a:	a045                	j	80004f3a <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004e9c:	02451783          	lh	a5,36(a0)
    80004ea0:	03079693          	slli	a3,a5,0x30
    80004ea4:	92c1                	srli	a3,a3,0x30
    80004ea6:	4725                	li	a4,9
    80004ea8:	0cd76263          	bltu	a4,a3,80004f6c <filewrite+0x12c>
    80004eac:	0792                	slli	a5,a5,0x4
    80004eae:	0001f717          	auipc	a4,0x1f
    80004eb2:	15a70713          	addi	a4,a4,346 # 80024008 <devsw>
    80004eb6:	97ba                	add	a5,a5,a4
    80004eb8:	679c                	ld	a5,8(a5)
    80004eba:	cbdd                	beqz	a5,80004f70 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004ebc:	4505                	li	a0,1
    80004ebe:	9782                	jalr	a5
    80004ec0:	8a2a                	mv	s4,a0
    80004ec2:	a8a5                	j	80004f3a <filewrite+0xfa>
    80004ec4:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004ec8:	00000097          	auipc	ra,0x0
    80004ecc:	8b0080e7          	jalr	-1872(ra) # 80004778 <begin_op>
      ilock(f->ip);
    80004ed0:	01893503          	ld	a0,24(s2)
    80004ed4:	fffff097          	auipc	ra,0xfffff
    80004ed8:	ee2080e7          	jalr	-286(ra) # 80003db6 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004edc:	8762                	mv	a4,s8
    80004ede:	02092683          	lw	a3,32(s2)
    80004ee2:	01598633          	add	a2,s3,s5
    80004ee6:	4585                	li	a1,1
    80004ee8:	01893503          	ld	a0,24(s2)
    80004eec:	fffff097          	auipc	ra,0xfffff
    80004ef0:	276080e7          	jalr	630(ra) # 80004162 <writei>
    80004ef4:	84aa                	mv	s1,a0
    80004ef6:	00a05763          	blez	a0,80004f04 <filewrite+0xc4>
        f->off += r;
    80004efa:	02092783          	lw	a5,32(s2)
    80004efe:	9fa9                	addw	a5,a5,a0
    80004f00:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004f04:	01893503          	ld	a0,24(s2)
    80004f08:	fffff097          	auipc	ra,0xfffff
    80004f0c:	f70080e7          	jalr	-144(ra) # 80003e78 <iunlock>
      end_op();
    80004f10:	00000097          	auipc	ra,0x0
    80004f14:	8e8080e7          	jalr	-1816(ra) # 800047f8 <end_op>

      if(r != n1){
    80004f18:	009c1f63          	bne	s8,s1,80004f36 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004f1c:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004f20:	0149db63          	bge	s3,s4,80004f36 <filewrite+0xf6>
      int n1 = n - i;
    80004f24:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004f28:	84be                	mv	s1,a5
    80004f2a:	2781                	sext.w	a5,a5
    80004f2c:	f8fb5ce3          	bge	s6,a5,80004ec4 <filewrite+0x84>
    80004f30:	84de                	mv	s1,s7
    80004f32:	bf49                	j	80004ec4 <filewrite+0x84>
    int i = 0;
    80004f34:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004f36:	013a1f63          	bne	s4,s3,80004f54 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004f3a:	8552                	mv	a0,s4
    80004f3c:	60a6                	ld	ra,72(sp)
    80004f3e:	6406                	ld	s0,64(sp)
    80004f40:	74e2                	ld	s1,56(sp)
    80004f42:	7942                	ld	s2,48(sp)
    80004f44:	79a2                	ld	s3,40(sp)
    80004f46:	7a02                	ld	s4,32(sp)
    80004f48:	6ae2                	ld	s5,24(sp)
    80004f4a:	6b42                	ld	s6,16(sp)
    80004f4c:	6ba2                	ld	s7,8(sp)
    80004f4e:	6c02                	ld	s8,0(sp)
    80004f50:	6161                	addi	sp,sp,80
    80004f52:	8082                	ret
    ret = (i == n ? n : -1);
    80004f54:	5a7d                	li	s4,-1
    80004f56:	b7d5                	j	80004f3a <filewrite+0xfa>
    panic("filewrite");
    80004f58:	00003517          	auipc	a0,0x3
    80004f5c:	79850513          	addi	a0,a0,1944 # 800086f0 <syscalls+0x290>
    80004f60:	ffffb097          	auipc	ra,0xffffb
    80004f64:	5de080e7          	jalr	1502(ra) # 8000053e <panic>
    return -1;
    80004f68:	5a7d                	li	s4,-1
    80004f6a:	bfc1                	j	80004f3a <filewrite+0xfa>
      return -1;
    80004f6c:	5a7d                	li	s4,-1
    80004f6e:	b7f1                	j	80004f3a <filewrite+0xfa>
    80004f70:	5a7d                	li	s4,-1
    80004f72:	b7e1                	j	80004f3a <filewrite+0xfa>

0000000080004f74 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004f74:	7179                	addi	sp,sp,-48
    80004f76:	f406                	sd	ra,40(sp)
    80004f78:	f022                	sd	s0,32(sp)
    80004f7a:	ec26                	sd	s1,24(sp)
    80004f7c:	e84a                	sd	s2,16(sp)
    80004f7e:	e44e                	sd	s3,8(sp)
    80004f80:	e052                	sd	s4,0(sp)
    80004f82:	1800                	addi	s0,sp,48
    80004f84:	84aa                	mv	s1,a0
    80004f86:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004f88:	0005b023          	sd	zero,0(a1)
    80004f8c:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004f90:	00000097          	auipc	ra,0x0
    80004f94:	bf8080e7          	jalr	-1032(ra) # 80004b88 <filealloc>
    80004f98:	e088                	sd	a0,0(s1)
    80004f9a:	c551                	beqz	a0,80005026 <pipealloc+0xb2>
    80004f9c:	00000097          	auipc	ra,0x0
    80004fa0:	bec080e7          	jalr	-1044(ra) # 80004b88 <filealloc>
    80004fa4:	00aa3023          	sd	a0,0(s4)
    80004fa8:	c92d                	beqz	a0,8000501a <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004faa:	ffffc097          	auipc	ra,0xffffc
    80004fae:	b3c080e7          	jalr	-1220(ra) # 80000ae6 <kalloc>
    80004fb2:	892a                	mv	s2,a0
    80004fb4:	c125                	beqz	a0,80005014 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004fb6:	4985                	li	s3,1
    80004fb8:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004fbc:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004fc0:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004fc4:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004fc8:	00003597          	auipc	a1,0x3
    80004fcc:	73858593          	addi	a1,a1,1848 # 80008700 <syscalls+0x2a0>
    80004fd0:	ffffc097          	auipc	ra,0xffffc
    80004fd4:	b76080e7          	jalr	-1162(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    80004fd8:	609c                	ld	a5,0(s1)
    80004fda:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004fde:	609c                	ld	a5,0(s1)
    80004fe0:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004fe4:	609c                	ld	a5,0(s1)
    80004fe6:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004fea:	609c                	ld	a5,0(s1)
    80004fec:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004ff0:	000a3783          	ld	a5,0(s4)
    80004ff4:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004ff8:	000a3783          	ld	a5,0(s4)
    80004ffc:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80005000:	000a3783          	ld	a5,0(s4)
    80005004:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80005008:	000a3783          	ld	a5,0(s4)
    8000500c:	0127b823          	sd	s2,16(a5)
  return 0;
    80005010:	4501                	li	a0,0
    80005012:	a025                	j	8000503a <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80005014:	6088                	ld	a0,0(s1)
    80005016:	e501                	bnez	a0,8000501e <pipealloc+0xaa>
    80005018:	a039                	j	80005026 <pipealloc+0xb2>
    8000501a:	6088                	ld	a0,0(s1)
    8000501c:	c51d                	beqz	a0,8000504a <pipealloc+0xd6>
    fileclose(*f0);
    8000501e:	00000097          	auipc	ra,0x0
    80005022:	c26080e7          	jalr	-986(ra) # 80004c44 <fileclose>
  if(*f1)
    80005026:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    8000502a:	557d                	li	a0,-1
  if(*f1)
    8000502c:	c799                	beqz	a5,8000503a <pipealloc+0xc6>
    fileclose(*f1);
    8000502e:	853e                	mv	a0,a5
    80005030:	00000097          	auipc	ra,0x0
    80005034:	c14080e7          	jalr	-1004(ra) # 80004c44 <fileclose>
  return -1;
    80005038:	557d                	li	a0,-1
}
    8000503a:	70a2                	ld	ra,40(sp)
    8000503c:	7402                	ld	s0,32(sp)
    8000503e:	64e2                	ld	s1,24(sp)
    80005040:	6942                	ld	s2,16(sp)
    80005042:	69a2                	ld	s3,8(sp)
    80005044:	6a02                	ld	s4,0(sp)
    80005046:	6145                	addi	sp,sp,48
    80005048:	8082                	ret
  return -1;
    8000504a:	557d                	li	a0,-1
    8000504c:	b7fd                	j	8000503a <pipealloc+0xc6>

000000008000504e <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    8000504e:	1101                	addi	sp,sp,-32
    80005050:	ec06                	sd	ra,24(sp)
    80005052:	e822                	sd	s0,16(sp)
    80005054:	e426                	sd	s1,8(sp)
    80005056:	e04a                	sd	s2,0(sp)
    80005058:	1000                	addi	s0,sp,32
    8000505a:	84aa                	mv	s1,a0
    8000505c:	892e                	mv	s2,a1
  acquire(&pi->lock);
    8000505e:	ffffc097          	auipc	ra,0xffffc
    80005062:	b78080e7          	jalr	-1160(ra) # 80000bd6 <acquire>
  if(writable){
    80005066:	02090d63          	beqz	s2,800050a0 <pipeclose+0x52>
    pi->writeopen = 0;
    8000506a:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    8000506e:	21848513          	addi	a0,s1,536
    80005072:	ffffd097          	auipc	ra,0xffffd
    80005076:	374080e7          	jalr	884(ra) # 800023e6 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    8000507a:	2204b783          	ld	a5,544(s1)
    8000507e:	eb95                	bnez	a5,800050b2 <pipeclose+0x64>
    release(&pi->lock);
    80005080:	8526                	mv	a0,s1
    80005082:	ffffc097          	auipc	ra,0xffffc
    80005086:	c08080e7          	jalr	-1016(ra) # 80000c8a <release>
    kfree((char*)pi);
    8000508a:	8526                	mv	a0,s1
    8000508c:	ffffc097          	auipc	ra,0xffffc
    80005090:	95e080e7          	jalr	-1698(ra) # 800009ea <kfree>
  } else
    release(&pi->lock);
}
    80005094:	60e2                	ld	ra,24(sp)
    80005096:	6442                	ld	s0,16(sp)
    80005098:	64a2                	ld	s1,8(sp)
    8000509a:	6902                	ld	s2,0(sp)
    8000509c:	6105                	addi	sp,sp,32
    8000509e:	8082                	ret
    pi->readopen = 0;
    800050a0:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800050a4:	21c48513          	addi	a0,s1,540
    800050a8:	ffffd097          	auipc	ra,0xffffd
    800050ac:	33e080e7          	jalr	830(ra) # 800023e6 <wakeup>
    800050b0:	b7e9                	j	8000507a <pipeclose+0x2c>
    release(&pi->lock);
    800050b2:	8526                	mv	a0,s1
    800050b4:	ffffc097          	auipc	ra,0xffffc
    800050b8:	bd6080e7          	jalr	-1066(ra) # 80000c8a <release>
}
    800050bc:	bfe1                	j	80005094 <pipeclose+0x46>

00000000800050be <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800050be:	711d                	addi	sp,sp,-96
    800050c0:	ec86                	sd	ra,88(sp)
    800050c2:	e8a2                	sd	s0,80(sp)
    800050c4:	e4a6                	sd	s1,72(sp)
    800050c6:	e0ca                	sd	s2,64(sp)
    800050c8:	fc4e                	sd	s3,56(sp)
    800050ca:	f852                	sd	s4,48(sp)
    800050cc:	f456                	sd	s5,40(sp)
    800050ce:	f05a                	sd	s6,32(sp)
    800050d0:	ec5e                	sd	s7,24(sp)
    800050d2:	e862                	sd	s8,16(sp)
    800050d4:	1080                	addi	s0,sp,96
    800050d6:	84aa                	mv	s1,a0
    800050d8:	8aae                	mv	s5,a1
    800050da:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    800050dc:	ffffd097          	auipc	ra,0xffffd
    800050e0:	a36080e7          	jalr	-1482(ra) # 80001b12 <myproc>
    800050e4:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    800050e6:	8526                	mv	a0,s1
    800050e8:	ffffc097          	auipc	ra,0xffffc
    800050ec:	aee080e7          	jalr	-1298(ra) # 80000bd6 <acquire>
  while(i < n){
    800050f0:	0b405663          	blez	s4,8000519c <pipewrite+0xde>
  int i = 0;
    800050f4:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800050f6:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    800050f8:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    800050fc:	21c48b93          	addi	s7,s1,540
    80005100:	a089                	j	80005142 <pipewrite+0x84>
      release(&pi->lock);
    80005102:	8526                	mv	a0,s1
    80005104:	ffffc097          	auipc	ra,0xffffc
    80005108:	b86080e7          	jalr	-1146(ra) # 80000c8a <release>
      return -1;
    8000510c:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    8000510e:	854a                	mv	a0,s2
    80005110:	60e6                	ld	ra,88(sp)
    80005112:	6446                	ld	s0,80(sp)
    80005114:	64a6                	ld	s1,72(sp)
    80005116:	6906                	ld	s2,64(sp)
    80005118:	79e2                	ld	s3,56(sp)
    8000511a:	7a42                	ld	s4,48(sp)
    8000511c:	7aa2                	ld	s5,40(sp)
    8000511e:	7b02                	ld	s6,32(sp)
    80005120:	6be2                	ld	s7,24(sp)
    80005122:	6c42                	ld	s8,16(sp)
    80005124:	6125                	addi	sp,sp,96
    80005126:	8082                	ret
      wakeup(&pi->nread);
    80005128:	8562                	mv	a0,s8
    8000512a:	ffffd097          	auipc	ra,0xffffd
    8000512e:	2bc080e7          	jalr	700(ra) # 800023e6 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80005132:	85a6                	mv	a1,s1
    80005134:	855e                	mv	a0,s7
    80005136:	ffffd097          	auipc	ra,0xffffd
    8000513a:	24c080e7          	jalr	588(ra) # 80002382 <sleep>
  while(i < n){
    8000513e:	07495063          	bge	s2,s4,8000519e <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80005142:	2204a783          	lw	a5,544(s1)
    80005146:	dfd5                	beqz	a5,80005102 <pipewrite+0x44>
    80005148:	854e                	mv	a0,s3
    8000514a:	ffffd097          	auipc	ra,0xffffd
    8000514e:	500080e7          	jalr	1280(ra) # 8000264a <killed>
    80005152:	f945                	bnez	a0,80005102 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80005154:	2184a783          	lw	a5,536(s1)
    80005158:	21c4a703          	lw	a4,540(s1)
    8000515c:	2007879b          	addiw	a5,a5,512
    80005160:	fcf704e3          	beq	a4,a5,80005128 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005164:	4685                	li	a3,1
    80005166:	01590633          	add	a2,s2,s5
    8000516a:	faf40593          	addi	a1,s0,-81
    8000516e:	0509b503          	ld	a0,80(s3)
    80005172:	ffffc097          	auipc	ra,0xffffc
    80005176:	582080e7          	jalr	1410(ra) # 800016f4 <copyin>
    8000517a:	03650263          	beq	a0,s6,8000519e <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    8000517e:	21c4a783          	lw	a5,540(s1)
    80005182:	0017871b          	addiw	a4,a5,1
    80005186:	20e4ae23          	sw	a4,540(s1)
    8000518a:	1ff7f793          	andi	a5,a5,511
    8000518e:	97a6                	add	a5,a5,s1
    80005190:	faf44703          	lbu	a4,-81(s0)
    80005194:	00e78c23          	sb	a4,24(a5)
      i++;
    80005198:	2905                	addiw	s2,s2,1
    8000519a:	b755                	j	8000513e <pipewrite+0x80>
  int i = 0;
    8000519c:	4901                	li	s2,0
  wakeup(&pi->nread);
    8000519e:	21848513          	addi	a0,s1,536
    800051a2:	ffffd097          	auipc	ra,0xffffd
    800051a6:	244080e7          	jalr	580(ra) # 800023e6 <wakeup>
  release(&pi->lock);
    800051aa:	8526                	mv	a0,s1
    800051ac:	ffffc097          	auipc	ra,0xffffc
    800051b0:	ade080e7          	jalr	-1314(ra) # 80000c8a <release>
  return i;
    800051b4:	bfa9                	j	8000510e <pipewrite+0x50>

00000000800051b6 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800051b6:	715d                	addi	sp,sp,-80
    800051b8:	e486                	sd	ra,72(sp)
    800051ba:	e0a2                	sd	s0,64(sp)
    800051bc:	fc26                	sd	s1,56(sp)
    800051be:	f84a                	sd	s2,48(sp)
    800051c0:	f44e                	sd	s3,40(sp)
    800051c2:	f052                	sd	s4,32(sp)
    800051c4:	ec56                	sd	s5,24(sp)
    800051c6:	e85a                	sd	s6,16(sp)
    800051c8:	0880                	addi	s0,sp,80
    800051ca:	84aa                	mv	s1,a0
    800051cc:	892e                	mv	s2,a1
    800051ce:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    800051d0:	ffffd097          	auipc	ra,0xffffd
    800051d4:	942080e7          	jalr	-1726(ra) # 80001b12 <myproc>
    800051d8:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    800051da:	8526                	mv	a0,s1
    800051dc:	ffffc097          	auipc	ra,0xffffc
    800051e0:	9fa080e7          	jalr	-1542(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800051e4:	2184a703          	lw	a4,536(s1)
    800051e8:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    800051ec:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    800051f0:	02f71763          	bne	a4,a5,8000521e <piperead+0x68>
    800051f4:	2244a783          	lw	a5,548(s1)
    800051f8:	c39d                	beqz	a5,8000521e <piperead+0x68>
    if(killed(pr)){
    800051fa:	8552                	mv	a0,s4
    800051fc:	ffffd097          	auipc	ra,0xffffd
    80005200:	44e080e7          	jalr	1102(ra) # 8000264a <killed>
    80005204:	e941                	bnez	a0,80005294 <piperead+0xde>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005206:	85a6                	mv	a1,s1
    80005208:	854e                	mv	a0,s3
    8000520a:	ffffd097          	auipc	ra,0xffffd
    8000520e:	178080e7          	jalr	376(ra) # 80002382 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005212:	2184a703          	lw	a4,536(s1)
    80005216:	21c4a783          	lw	a5,540(s1)
    8000521a:	fcf70de3          	beq	a4,a5,800051f4 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000521e:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005220:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005222:	05505363          	blez	s5,80005268 <piperead+0xb2>
    if(pi->nread == pi->nwrite)
    80005226:	2184a783          	lw	a5,536(s1)
    8000522a:	21c4a703          	lw	a4,540(s1)
    8000522e:	02f70d63          	beq	a4,a5,80005268 <piperead+0xb2>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005232:	0017871b          	addiw	a4,a5,1
    80005236:	20e4ac23          	sw	a4,536(s1)
    8000523a:	1ff7f793          	andi	a5,a5,511
    8000523e:	97a6                	add	a5,a5,s1
    80005240:	0187c783          	lbu	a5,24(a5)
    80005244:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005248:	4685                	li	a3,1
    8000524a:	fbf40613          	addi	a2,s0,-65
    8000524e:	85ca                	mv	a1,s2
    80005250:	050a3503          	ld	a0,80(s4)
    80005254:	ffffc097          	auipc	ra,0xffffc
    80005258:	414080e7          	jalr	1044(ra) # 80001668 <copyout>
    8000525c:	01650663          	beq	a0,s6,80005268 <piperead+0xb2>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005260:	2985                	addiw	s3,s3,1
    80005262:	0905                	addi	s2,s2,1
    80005264:	fd3a91e3          	bne	s5,s3,80005226 <piperead+0x70>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005268:	21c48513          	addi	a0,s1,540
    8000526c:	ffffd097          	auipc	ra,0xffffd
    80005270:	17a080e7          	jalr	378(ra) # 800023e6 <wakeup>
  release(&pi->lock);
    80005274:	8526                	mv	a0,s1
    80005276:	ffffc097          	auipc	ra,0xffffc
    8000527a:	a14080e7          	jalr	-1516(ra) # 80000c8a <release>
  return i;
}
    8000527e:	854e                	mv	a0,s3
    80005280:	60a6                	ld	ra,72(sp)
    80005282:	6406                	ld	s0,64(sp)
    80005284:	74e2                	ld	s1,56(sp)
    80005286:	7942                	ld	s2,48(sp)
    80005288:	79a2                	ld	s3,40(sp)
    8000528a:	7a02                	ld	s4,32(sp)
    8000528c:	6ae2                	ld	s5,24(sp)
    8000528e:	6b42                	ld	s6,16(sp)
    80005290:	6161                	addi	sp,sp,80
    80005292:	8082                	ret
      release(&pi->lock);
    80005294:	8526                	mv	a0,s1
    80005296:	ffffc097          	auipc	ra,0xffffc
    8000529a:	9f4080e7          	jalr	-1548(ra) # 80000c8a <release>
      return -1;
    8000529e:	59fd                	li	s3,-1
    800052a0:	bff9                	j	8000527e <piperead+0xc8>

00000000800052a2 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    800052a2:	1141                	addi	sp,sp,-16
    800052a4:	e422                	sd	s0,8(sp)
    800052a6:	0800                	addi	s0,sp,16
    800052a8:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    800052aa:	8905                	andi	a0,a0,1
    800052ac:	c111                	beqz	a0,800052b0 <flags2perm+0xe>
      perm = PTE_X;
    800052ae:	4521                	li	a0,8
    if(flags & 0x2)
    800052b0:	8b89                	andi	a5,a5,2
    800052b2:	c399                	beqz	a5,800052b8 <flags2perm+0x16>
      perm |= PTE_W;
    800052b4:	00456513          	ori	a0,a0,4
    return perm;
}
    800052b8:	6422                	ld	s0,8(sp)
    800052ba:	0141                	addi	sp,sp,16
    800052bc:	8082                	ret

00000000800052be <exec>:

int
exec(char *path, char **argv)
{
    800052be:	de010113          	addi	sp,sp,-544
    800052c2:	20113c23          	sd	ra,536(sp)
    800052c6:	20813823          	sd	s0,528(sp)
    800052ca:	20913423          	sd	s1,520(sp)
    800052ce:	21213023          	sd	s2,512(sp)
    800052d2:	ffce                	sd	s3,504(sp)
    800052d4:	fbd2                	sd	s4,496(sp)
    800052d6:	f7d6                	sd	s5,488(sp)
    800052d8:	f3da                	sd	s6,480(sp)
    800052da:	efde                	sd	s7,472(sp)
    800052dc:	ebe2                	sd	s8,464(sp)
    800052de:	e7e6                	sd	s9,456(sp)
    800052e0:	e3ea                	sd	s10,448(sp)
    800052e2:	ff6e                	sd	s11,440(sp)
    800052e4:	1400                	addi	s0,sp,544
    800052e6:	892a                	mv	s2,a0
    800052e8:	dea43423          	sd	a0,-536(s0)
    800052ec:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800052f0:	ffffd097          	auipc	ra,0xffffd
    800052f4:	822080e7          	jalr	-2014(ra) # 80001b12 <myproc>
    800052f8:	84aa                	mv	s1,a0

  begin_op();
    800052fa:	fffff097          	auipc	ra,0xfffff
    800052fe:	47e080e7          	jalr	1150(ra) # 80004778 <begin_op>

  if((ip = namei(path)) == 0){
    80005302:	854a                	mv	a0,s2
    80005304:	fffff097          	auipc	ra,0xfffff
    80005308:	258080e7          	jalr	600(ra) # 8000455c <namei>
    8000530c:	c93d                	beqz	a0,80005382 <exec+0xc4>
    8000530e:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005310:	fffff097          	auipc	ra,0xfffff
    80005314:	aa6080e7          	jalr	-1370(ra) # 80003db6 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005318:	04000713          	li	a4,64
    8000531c:	4681                	li	a3,0
    8000531e:	e5040613          	addi	a2,s0,-432
    80005322:	4581                	li	a1,0
    80005324:	8556                	mv	a0,s5
    80005326:	fffff097          	auipc	ra,0xfffff
    8000532a:	d44080e7          	jalr	-700(ra) # 8000406a <readi>
    8000532e:	04000793          	li	a5,64
    80005332:	00f51a63          	bne	a0,a5,80005346 <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80005336:	e5042703          	lw	a4,-432(s0)
    8000533a:	464c47b7          	lui	a5,0x464c4
    8000533e:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005342:	04f70663          	beq	a4,a5,8000538e <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005346:	8556                	mv	a0,s5
    80005348:	fffff097          	auipc	ra,0xfffff
    8000534c:	cd0080e7          	jalr	-816(ra) # 80004018 <iunlockput>
    end_op();
    80005350:	fffff097          	auipc	ra,0xfffff
    80005354:	4a8080e7          	jalr	1192(ra) # 800047f8 <end_op>
  }
  return -1;
    80005358:	557d                	li	a0,-1
}
    8000535a:	21813083          	ld	ra,536(sp)
    8000535e:	21013403          	ld	s0,528(sp)
    80005362:	20813483          	ld	s1,520(sp)
    80005366:	20013903          	ld	s2,512(sp)
    8000536a:	79fe                	ld	s3,504(sp)
    8000536c:	7a5e                	ld	s4,496(sp)
    8000536e:	7abe                	ld	s5,488(sp)
    80005370:	7b1e                	ld	s6,480(sp)
    80005372:	6bfe                	ld	s7,472(sp)
    80005374:	6c5e                	ld	s8,464(sp)
    80005376:	6cbe                	ld	s9,456(sp)
    80005378:	6d1e                	ld	s10,448(sp)
    8000537a:	7dfa                	ld	s11,440(sp)
    8000537c:	22010113          	addi	sp,sp,544
    80005380:	8082                	ret
    end_op();
    80005382:	fffff097          	auipc	ra,0xfffff
    80005386:	476080e7          	jalr	1142(ra) # 800047f8 <end_op>
    return -1;
    8000538a:	557d                	li	a0,-1
    8000538c:	b7f9                	j	8000535a <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    8000538e:	8526                	mv	a0,s1
    80005390:	ffffd097          	auipc	ra,0xffffd
    80005394:	846080e7          	jalr	-1978(ra) # 80001bd6 <proc_pagetable>
    80005398:	8b2a                	mv	s6,a0
    8000539a:	d555                	beqz	a0,80005346 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000539c:	e7042783          	lw	a5,-400(s0)
    800053a0:	e8845703          	lhu	a4,-376(s0)
    800053a4:	c735                	beqz	a4,80005410 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800053a6:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800053a8:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    800053ac:	6a05                	lui	s4,0x1
    800053ae:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    800053b2:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    800053b6:	6d85                	lui	s11,0x1
    800053b8:	7d7d                	lui	s10,0xfffff
    800053ba:	a481                	j	800055fa <exec+0x33c>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800053bc:	00003517          	auipc	a0,0x3
    800053c0:	34c50513          	addi	a0,a0,844 # 80008708 <syscalls+0x2a8>
    800053c4:	ffffb097          	auipc	ra,0xffffb
    800053c8:	17a080e7          	jalr	378(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800053cc:	874a                	mv	a4,s2
    800053ce:	009c86bb          	addw	a3,s9,s1
    800053d2:	4581                	li	a1,0
    800053d4:	8556                	mv	a0,s5
    800053d6:	fffff097          	auipc	ra,0xfffff
    800053da:	c94080e7          	jalr	-876(ra) # 8000406a <readi>
    800053de:	2501                	sext.w	a0,a0
    800053e0:	1aa91a63          	bne	s2,a0,80005594 <exec+0x2d6>
  for(i = 0; i < sz; i += PGSIZE){
    800053e4:	009d84bb          	addw	s1,s11,s1
    800053e8:	013d09bb          	addw	s3,s10,s3
    800053ec:	1f74f763          	bgeu	s1,s7,800055da <exec+0x31c>
    pa = walkaddr(pagetable, va + i);
    800053f0:	02049593          	slli	a1,s1,0x20
    800053f4:	9181                	srli	a1,a1,0x20
    800053f6:	95e2                	add	a1,a1,s8
    800053f8:	855a                	mv	a0,s6
    800053fa:	ffffc097          	auipc	ra,0xffffc
    800053fe:	c62080e7          	jalr	-926(ra) # 8000105c <walkaddr>
    80005402:	862a                	mv	a2,a0
    if(pa == 0)
    80005404:	dd45                	beqz	a0,800053bc <exec+0xfe>
      n = PGSIZE;
    80005406:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80005408:	fd49f2e3          	bgeu	s3,s4,800053cc <exec+0x10e>
      n = sz - i;
    8000540c:	894e                	mv	s2,s3
    8000540e:	bf7d                	j	800053cc <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005410:	4901                	li	s2,0
  iunlockput(ip);
    80005412:	8556                	mv	a0,s5
    80005414:	fffff097          	auipc	ra,0xfffff
    80005418:	c04080e7          	jalr	-1020(ra) # 80004018 <iunlockput>
  end_op();
    8000541c:	fffff097          	auipc	ra,0xfffff
    80005420:	3dc080e7          	jalr	988(ra) # 800047f8 <end_op>
  p = myproc();
    80005424:	ffffc097          	auipc	ra,0xffffc
    80005428:	6ee080e7          	jalr	1774(ra) # 80001b12 <myproc>
    8000542c:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    8000542e:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80005432:	6785                	lui	a5,0x1
    80005434:	17fd                	addi	a5,a5,-1
    80005436:	993e                	add	s2,s2,a5
    80005438:	77fd                	lui	a5,0xfffff
    8000543a:	00f977b3          	and	a5,s2,a5
    8000543e:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005442:	4691                	li	a3,4
    80005444:	6609                	lui	a2,0x2
    80005446:	963e                	add	a2,a2,a5
    80005448:	85be                	mv	a1,a5
    8000544a:	855a                	mv	a0,s6
    8000544c:	ffffc097          	auipc	ra,0xffffc
    80005450:	fc4080e7          	jalr	-60(ra) # 80001410 <uvmalloc>
    80005454:	8c2a                	mv	s8,a0
  ip = 0;
    80005456:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005458:	12050e63          	beqz	a0,80005594 <exec+0x2d6>
  uvmclear(pagetable, sz-2*PGSIZE);
    8000545c:	75f9                	lui	a1,0xffffe
    8000545e:	95aa                	add	a1,a1,a0
    80005460:	855a                	mv	a0,s6
    80005462:	ffffc097          	auipc	ra,0xffffc
    80005466:	1d4080e7          	jalr	468(ra) # 80001636 <uvmclear>
  stackbase = sp - PGSIZE;
    8000546a:	7afd                	lui	s5,0xfffff
    8000546c:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    8000546e:	df043783          	ld	a5,-528(s0)
    80005472:	6388                	ld	a0,0(a5)
    80005474:	c925                	beqz	a0,800054e4 <exec+0x226>
    80005476:	e9040993          	addi	s3,s0,-368
    8000547a:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    8000547e:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005480:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80005482:	ffffc097          	auipc	ra,0xffffc
    80005486:	9cc080e7          	jalr	-1588(ra) # 80000e4e <strlen>
    8000548a:	0015079b          	addiw	a5,a0,1
    8000548e:	40f90933          	sub	s2,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005492:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005496:	13596663          	bltu	s2,s5,800055c2 <exec+0x304>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    8000549a:	df043d83          	ld	s11,-528(s0)
    8000549e:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    800054a2:	8552                	mv	a0,s4
    800054a4:	ffffc097          	auipc	ra,0xffffc
    800054a8:	9aa080e7          	jalr	-1622(ra) # 80000e4e <strlen>
    800054ac:	0015069b          	addiw	a3,a0,1
    800054b0:	8652                	mv	a2,s4
    800054b2:	85ca                	mv	a1,s2
    800054b4:	855a                	mv	a0,s6
    800054b6:	ffffc097          	auipc	ra,0xffffc
    800054ba:	1b2080e7          	jalr	434(ra) # 80001668 <copyout>
    800054be:	10054663          	bltz	a0,800055ca <exec+0x30c>
    ustack[argc] = sp;
    800054c2:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800054c6:	0485                	addi	s1,s1,1
    800054c8:	008d8793          	addi	a5,s11,8
    800054cc:	def43823          	sd	a5,-528(s0)
    800054d0:	008db503          	ld	a0,8(s11)
    800054d4:	c911                	beqz	a0,800054e8 <exec+0x22a>
    if(argc >= MAXARG)
    800054d6:	09a1                	addi	s3,s3,8
    800054d8:	fb3c95e3          	bne	s9,s3,80005482 <exec+0x1c4>
  sz = sz1;
    800054dc:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800054e0:	4a81                	li	s5,0
    800054e2:	a84d                	j	80005594 <exec+0x2d6>
  sp = sz;
    800054e4:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800054e6:	4481                	li	s1,0
  ustack[argc] = 0;
    800054e8:	00349793          	slli	a5,s1,0x3
    800054ec:	f9040713          	addi	a4,s0,-112
    800054f0:	97ba                	add	a5,a5,a4
    800054f2:	f007b023          	sd	zero,-256(a5) # ffffffffffffef00 <end+0xffffffff7ffd9d60>
  sp -= (argc+1) * sizeof(uint64);
    800054f6:	00148693          	addi	a3,s1,1
    800054fa:	068e                	slli	a3,a3,0x3
    800054fc:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005500:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005504:	01597663          	bgeu	s2,s5,80005510 <exec+0x252>
  sz = sz1;
    80005508:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000550c:	4a81                	li	s5,0
    8000550e:	a059                	j	80005594 <exec+0x2d6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005510:	e9040613          	addi	a2,s0,-368
    80005514:	85ca                	mv	a1,s2
    80005516:	855a                	mv	a0,s6
    80005518:	ffffc097          	auipc	ra,0xffffc
    8000551c:	150080e7          	jalr	336(ra) # 80001668 <copyout>
    80005520:	0a054963          	bltz	a0,800055d2 <exec+0x314>
  p->trapframe->a1 = sp;
    80005524:	058bb783          	ld	a5,88(s7) # 1058 <_entry-0x7fffefa8>
    80005528:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000552c:	de843783          	ld	a5,-536(s0)
    80005530:	0007c703          	lbu	a4,0(a5)
    80005534:	cf11                	beqz	a4,80005550 <exec+0x292>
    80005536:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005538:	02f00693          	li	a3,47
    8000553c:	a039                	j	8000554a <exec+0x28c>
      last = s+1;
    8000553e:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80005542:	0785                	addi	a5,a5,1
    80005544:	fff7c703          	lbu	a4,-1(a5)
    80005548:	c701                	beqz	a4,80005550 <exec+0x292>
    if(*s == '/')
    8000554a:	fed71ce3          	bne	a4,a3,80005542 <exec+0x284>
    8000554e:	bfc5                	j	8000553e <exec+0x280>
  safestrcpy(p->name, last, sizeof(p->name));
    80005550:	4641                	li	a2,16
    80005552:	de843583          	ld	a1,-536(s0)
    80005556:	158b8513          	addi	a0,s7,344
    8000555a:	ffffc097          	auipc	ra,0xffffc
    8000555e:	8c2080e7          	jalr	-1854(ra) # 80000e1c <safestrcpy>
  oldpagetable = p->pagetable;
    80005562:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80005566:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    8000556a:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000556e:	058bb783          	ld	a5,88(s7)
    80005572:	e6843703          	ld	a4,-408(s0)
    80005576:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005578:	058bb783          	ld	a5,88(s7)
    8000557c:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005580:	85ea                	mv	a1,s10
    80005582:	ffffc097          	auipc	ra,0xffffc
    80005586:	6f0080e7          	jalr	1776(ra) # 80001c72 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000558a:	0004851b          	sext.w	a0,s1
    8000558e:	b3f1                	j	8000535a <exec+0x9c>
    80005590:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    80005594:	df843583          	ld	a1,-520(s0)
    80005598:	855a                	mv	a0,s6
    8000559a:	ffffc097          	auipc	ra,0xffffc
    8000559e:	6d8080e7          	jalr	1752(ra) # 80001c72 <proc_freepagetable>
  if(ip){
    800055a2:	da0a92e3          	bnez	s5,80005346 <exec+0x88>
  return -1;
    800055a6:	557d                	li	a0,-1
    800055a8:	bb4d                	j	8000535a <exec+0x9c>
    800055aa:	df243c23          	sd	s2,-520(s0)
    800055ae:	b7dd                	j	80005594 <exec+0x2d6>
    800055b0:	df243c23          	sd	s2,-520(s0)
    800055b4:	b7c5                	j	80005594 <exec+0x2d6>
    800055b6:	df243c23          	sd	s2,-520(s0)
    800055ba:	bfe9                	j	80005594 <exec+0x2d6>
    800055bc:	df243c23          	sd	s2,-520(s0)
    800055c0:	bfd1                	j	80005594 <exec+0x2d6>
  sz = sz1;
    800055c2:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800055c6:	4a81                	li	s5,0
    800055c8:	b7f1                	j	80005594 <exec+0x2d6>
  sz = sz1;
    800055ca:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800055ce:	4a81                	li	s5,0
    800055d0:	b7d1                	j	80005594 <exec+0x2d6>
  sz = sz1;
    800055d2:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800055d6:	4a81                	li	s5,0
    800055d8:	bf75                	j	80005594 <exec+0x2d6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800055da:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800055de:	e0843783          	ld	a5,-504(s0)
    800055e2:	0017869b          	addiw	a3,a5,1
    800055e6:	e0d43423          	sd	a3,-504(s0)
    800055ea:	e0043783          	ld	a5,-512(s0)
    800055ee:	0387879b          	addiw	a5,a5,56
    800055f2:	e8845703          	lhu	a4,-376(s0)
    800055f6:	e0e6dee3          	bge	a3,a4,80005412 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800055fa:	2781                	sext.w	a5,a5
    800055fc:	e0f43023          	sd	a5,-512(s0)
    80005600:	03800713          	li	a4,56
    80005604:	86be                	mv	a3,a5
    80005606:	e1840613          	addi	a2,s0,-488
    8000560a:	4581                	li	a1,0
    8000560c:	8556                	mv	a0,s5
    8000560e:	fffff097          	auipc	ra,0xfffff
    80005612:	a5c080e7          	jalr	-1444(ra) # 8000406a <readi>
    80005616:	03800793          	li	a5,56
    8000561a:	f6f51be3          	bne	a0,a5,80005590 <exec+0x2d2>
    if(ph.type != ELF_PROG_LOAD)
    8000561e:	e1842783          	lw	a5,-488(s0)
    80005622:	4705                	li	a4,1
    80005624:	fae79de3          	bne	a5,a4,800055de <exec+0x320>
    if(ph.memsz < ph.filesz)
    80005628:	e4043483          	ld	s1,-448(s0)
    8000562c:	e3843783          	ld	a5,-456(s0)
    80005630:	f6f4ede3          	bltu	s1,a5,800055aa <exec+0x2ec>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005634:	e2843783          	ld	a5,-472(s0)
    80005638:	94be                	add	s1,s1,a5
    8000563a:	f6f4ebe3          	bltu	s1,a5,800055b0 <exec+0x2f2>
    if(ph.vaddr % PGSIZE != 0)
    8000563e:	de043703          	ld	a4,-544(s0)
    80005642:	8ff9                	and	a5,a5,a4
    80005644:	fbad                	bnez	a5,800055b6 <exec+0x2f8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005646:	e1c42503          	lw	a0,-484(s0)
    8000564a:	00000097          	auipc	ra,0x0
    8000564e:	c58080e7          	jalr	-936(ra) # 800052a2 <flags2perm>
    80005652:	86aa                	mv	a3,a0
    80005654:	8626                	mv	a2,s1
    80005656:	85ca                	mv	a1,s2
    80005658:	855a                	mv	a0,s6
    8000565a:	ffffc097          	auipc	ra,0xffffc
    8000565e:	db6080e7          	jalr	-586(ra) # 80001410 <uvmalloc>
    80005662:	dea43c23          	sd	a0,-520(s0)
    80005666:	d939                	beqz	a0,800055bc <exec+0x2fe>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005668:	e2843c03          	ld	s8,-472(s0)
    8000566c:	e2042c83          	lw	s9,-480(s0)
    80005670:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005674:	f60b83e3          	beqz	s7,800055da <exec+0x31c>
    80005678:	89de                	mv	s3,s7
    8000567a:	4481                	li	s1,0
    8000567c:	bb95                	j	800053f0 <exec+0x132>

000000008000567e <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000567e:	7179                	addi	sp,sp,-48
    80005680:	f406                	sd	ra,40(sp)
    80005682:	f022                	sd	s0,32(sp)
    80005684:	ec26                	sd	s1,24(sp)
    80005686:	e84a                	sd	s2,16(sp)
    80005688:	1800                	addi	s0,sp,48
    8000568a:	892e                	mv	s2,a1
    8000568c:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    8000568e:	fdc40593          	addi	a1,s0,-36
    80005692:	ffffe097          	auipc	ra,0xffffe
    80005696:	9b2080e7          	jalr	-1614(ra) # 80003044 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000569a:	fdc42703          	lw	a4,-36(s0)
    8000569e:	47bd                	li	a5,15
    800056a0:	02e7eb63          	bltu	a5,a4,800056d6 <argfd+0x58>
    800056a4:	ffffc097          	auipc	ra,0xffffc
    800056a8:	46e080e7          	jalr	1134(ra) # 80001b12 <myproc>
    800056ac:	fdc42703          	lw	a4,-36(s0)
    800056b0:	01a70793          	addi	a5,a4,26
    800056b4:	078e                	slli	a5,a5,0x3
    800056b6:	953e                	add	a0,a0,a5
    800056b8:	611c                	ld	a5,0(a0)
    800056ba:	c385                	beqz	a5,800056da <argfd+0x5c>
    return -1;
  if(pfd)
    800056bc:	00090463          	beqz	s2,800056c4 <argfd+0x46>
    *pfd = fd;
    800056c0:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800056c4:	4501                	li	a0,0
  if(pf)
    800056c6:	c091                	beqz	s1,800056ca <argfd+0x4c>
    *pf = f;
    800056c8:	e09c                	sd	a5,0(s1)
}
    800056ca:	70a2                	ld	ra,40(sp)
    800056cc:	7402                	ld	s0,32(sp)
    800056ce:	64e2                	ld	s1,24(sp)
    800056d0:	6942                	ld	s2,16(sp)
    800056d2:	6145                	addi	sp,sp,48
    800056d4:	8082                	ret
    return -1;
    800056d6:	557d                	li	a0,-1
    800056d8:	bfcd                	j	800056ca <argfd+0x4c>
    800056da:	557d                	li	a0,-1
    800056dc:	b7fd                	j	800056ca <argfd+0x4c>

00000000800056de <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800056de:	1101                	addi	sp,sp,-32
    800056e0:	ec06                	sd	ra,24(sp)
    800056e2:	e822                	sd	s0,16(sp)
    800056e4:	e426                	sd	s1,8(sp)
    800056e6:	1000                	addi	s0,sp,32
    800056e8:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800056ea:	ffffc097          	auipc	ra,0xffffc
    800056ee:	428080e7          	jalr	1064(ra) # 80001b12 <myproc>
    800056f2:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800056f4:	0d050793          	addi	a5,a0,208
    800056f8:	4501                	li	a0,0
    800056fa:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800056fc:	6398                	ld	a4,0(a5)
    800056fe:	cb19                	beqz	a4,80005714 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005700:	2505                	addiw	a0,a0,1
    80005702:	07a1                	addi	a5,a5,8
    80005704:	fed51ce3          	bne	a0,a3,800056fc <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005708:	557d                	li	a0,-1
}
    8000570a:	60e2                	ld	ra,24(sp)
    8000570c:	6442                	ld	s0,16(sp)
    8000570e:	64a2                	ld	s1,8(sp)
    80005710:	6105                	addi	sp,sp,32
    80005712:	8082                	ret
      p->ofile[fd] = f;
    80005714:	01a50793          	addi	a5,a0,26
    80005718:	078e                	slli	a5,a5,0x3
    8000571a:	963e                	add	a2,a2,a5
    8000571c:	e204                	sd	s1,0(a2)
      return fd;
    8000571e:	b7f5                	j	8000570a <fdalloc+0x2c>

0000000080005720 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005720:	715d                	addi	sp,sp,-80
    80005722:	e486                	sd	ra,72(sp)
    80005724:	e0a2                	sd	s0,64(sp)
    80005726:	fc26                	sd	s1,56(sp)
    80005728:	f84a                	sd	s2,48(sp)
    8000572a:	f44e                	sd	s3,40(sp)
    8000572c:	f052                	sd	s4,32(sp)
    8000572e:	ec56                	sd	s5,24(sp)
    80005730:	e85a                	sd	s6,16(sp)
    80005732:	0880                	addi	s0,sp,80
    80005734:	8b2e                	mv	s6,a1
    80005736:	89b2                	mv	s3,a2
    80005738:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000573a:	fb040593          	addi	a1,s0,-80
    8000573e:	fffff097          	auipc	ra,0xfffff
    80005742:	e3c080e7          	jalr	-452(ra) # 8000457a <nameiparent>
    80005746:	84aa                	mv	s1,a0
    80005748:	14050f63          	beqz	a0,800058a6 <create+0x186>
    return 0;

  ilock(dp);
    8000574c:	ffffe097          	auipc	ra,0xffffe
    80005750:	66a080e7          	jalr	1642(ra) # 80003db6 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005754:	4601                	li	a2,0
    80005756:	fb040593          	addi	a1,s0,-80
    8000575a:	8526                	mv	a0,s1
    8000575c:	fffff097          	auipc	ra,0xfffff
    80005760:	b3e080e7          	jalr	-1218(ra) # 8000429a <dirlookup>
    80005764:	8aaa                	mv	s5,a0
    80005766:	c931                	beqz	a0,800057ba <create+0x9a>
    iunlockput(dp);
    80005768:	8526                	mv	a0,s1
    8000576a:	fffff097          	auipc	ra,0xfffff
    8000576e:	8ae080e7          	jalr	-1874(ra) # 80004018 <iunlockput>
    ilock(ip);
    80005772:	8556                	mv	a0,s5
    80005774:	ffffe097          	auipc	ra,0xffffe
    80005778:	642080e7          	jalr	1602(ra) # 80003db6 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000577c:	000b059b          	sext.w	a1,s6
    80005780:	4789                	li	a5,2
    80005782:	02f59563          	bne	a1,a5,800057ac <create+0x8c>
    80005786:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffd9ea4>
    8000578a:	37f9                	addiw	a5,a5,-2
    8000578c:	17c2                	slli	a5,a5,0x30
    8000578e:	93c1                	srli	a5,a5,0x30
    80005790:	4705                	li	a4,1
    80005792:	00f76d63          	bltu	a4,a5,800057ac <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005796:	8556                	mv	a0,s5
    80005798:	60a6                	ld	ra,72(sp)
    8000579a:	6406                	ld	s0,64(sp)
    8000579c:	74e2                	ld	s1,56(sp)
    8000579e:	7942                	ld	s2,48(sp)
    800057a0:	79a2                	ld	s3,40(sp)
    800057a2:	7a02                	ld	s4,32(sp)
    800057a4:	6ae2                	ld	s5,24(sp)
    800057a6:	6b42                	ld	s6,16(sp)
    800057a8:	6161                	addi	sp,sp,80
    800057aa:	8082                	ret
    iunlockput(ip);
    800057ac:	8556                	mv	a0,s5
    800057ae:	fffff097          	auipc	ra,0xfffff
    800057b2:	86a080e7          	jalr	-1942(ra) # 80004018 <iunlockput>
    return 0;
    800057b6:	4a81                	li	s5,0
    800057b8:	bff9                	j	80005796 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    800057ba:	85da                	mv	a1,s6
    800057bc:	4088                	lw	a0,0(s1)
    800057be:	ffffe097          	auipc	ra,0xffffe
    800057c2:	45c080e7          	jalr	1116(ra) # 80003c1a <ialloc>
    800057c6:	8a2a                	mv	s4,a0
    800057c8:	c539                	beqz	a0,80005816 <create+0xf6>
  ilock(ip);
    800057ca:	ffffe097          	auipc	ra,0xffffe
    800057ce:	5ec080e7          	jalr	1516(ra) # 80003db6 <ilock>
  ip->major = major;
    800057d2:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    800057d6:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    800057da:	4905                	li	s2,1
    800057dc:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    800057e0:	8552                	mv	a0,s4
    800057e2:	ffffe097          	auipc	ra,0xffffe
    800057e6:	50a080e7          	jalr	1290(ra) # 80003cec <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800057ea:	000b059b          	sext.w	a1,s6
    800057ee:	03258b63          	beq	a1,s2,80005824 <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    800057f2:	004a2603          	lw	a2,4(s4)
    800057f6:	fb040593          	addi	a1,s0,-80
    800057fa:	8526                	mv	a0,s1
    800057fc:	fffff097          	auipc	ra,0xfffff
    80005800:	cae080e7          	jalr	-850(ra) # 800044aa <dirlink>
    80005804:	06054f63          	bltz	a0,80005882 <create+0x162>
  iunlockput(dp);
    80005808:	8526                	mv	a0,s1
    8000580a:	fffff097          	auipc	ra,0xfffff
    8000580e:	80e080e7          	jalr	-2034(ra) # 80004018 <iunlockput>
  return ip;
    80005812:	8ad2                	mv	s5,s4
    80005814:	b749                	j	80005796 <create+0x76>
    iunlockput(dp);
    80005816:	8526                	mv	a0,s1
    80005818:	fffff097          	auipc	ra,0xfffff
    8000581c:	800080e7          	jalr	-2048(ra) # 80004018 <iunlockput>
    return 0;
    80005820:	8ad2                	mv	s5,s4
    80005822:	bf95                	j	80005796 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005824:	004a2603          	lw	a2,4(s4)
    80005828:	00003597          	auipc	a1,0x3
    8000582c:	f0058593          	addi	a1,a1,-256 # 80008728 <syscalls+0x2c8>
    80005830:	8552                	mv	a0,s4
    80005832:	fffff097          	auipc	ra,0xfffff
    80005836:	c78080e7          	jalr	-904(ra) # 800044aa <dirlink>
    8000583a:	04054463          	bltz	a0,80005882 <create+0x162>
    8000583e:	40d0                	lw	a2,4(s1)
    80005840:	00003597          	auipc	a1,0x3
    80005844:	ef058593          	addi	a1,a1,-272 # 80008730 <syscalls+0x2d0>
    80005848:	8552                	mv	a0,s4
    8000584a:	fffff097          	auipc	ra,0xfffff
    8000584e:	c60080e7          	jalr	-928(ra) # 800044aa <dirlink>
    80005852:	02054863          	bltz	a0,80005882 <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    80005856:	004a2603          	lw	a2,4(s4)
    8000585a:	fb040593          	addi	a1,s0,-80
    8000585e:	8526                	mv	a0,s1
    80005860:	fffff097          	auipc	ra,0xfffff
    80005864:	c4a080e7          	jalr	-950(ra) # 800044aa <dirlink>
    80005868:	00054d63          	bltz	a0,80005882 <create+0x162>
    dp->nlink++;  // for ".."
    8000586c:	04a4d783          	lhu	a5,74(s1)
    80005870:	2785                	addiw	a5,a5,1
    80005872:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005876:	8526                	mv	a0,s1
    80005878:	ffffe097          	auipc	ra,0xffffe
    8000587c:	474080e7          	jalr	1140(ra) # 80003cec <iupdate>
    80005880:	b761                	j	80005808 <create+0xe8>
  ip->nlink = 0;
    80005882:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005886:	8552                	mv	a0,s4
    80005888:	ffffe097          	auipc	ra,0xffffe
    8000588c:	464080e7          	jalr	1124(ra) # 80003cec <iupdate>
  iunlockput(ip);
    80005890:	8552                	mv	a0,s4
    80005892:	ffffe097          	auipc	ra,0xffffe
    80005896:	786080e7          	jalr	1926(ra) # 80004018 <iunlockput>
  iunlockput(dp);
    8000589a:	8526                	mv	a0,s1
    8000589c:	ffffe097          	auipc	ra,0xffffe
    800058a0:	77c080e7          	jalr	1916(ra) # 80004018 <iunlockput>
  return 0;
    800058a4:	bdcd                	j	80005796 <create+0x76>
    return 0;
    800058a6:	8aaa                	mv	s5,a0
    800058a8:	b5fd                	j	80005796 <create+0x76>

00000000800058aa <sys_dup>:
{
    800058aa:	7179                	addi	sp,sp,-48
    800058ac:	f406                	sd	ra,40(sp)
    800058ae:	f022                	sd	s0,32(sp)
    800058b0:	ec26                	sd	s1,24(sp)
    800058b2:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800058b4:	fd840613          	addi	a2,s0,-40
    800058b8:	4581                	li	a1,0
    800058ba:	4501                	li	a0,0
    800058bc:	00000097          	auipc	ra,0x0
    800058c0:	dc2080e7          	jalr	-574(ra) # 8000567e <argfd>
    return -1;
    800058c4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800058c6:	02054363          	bltz	a0,800058ec <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800058ca:	fd843503          	ld	a0,-40(s0)
    800058ce:	00000097          	auipc	ra,0x0
    800058d2:	e10080e7          	jalr	-496(ra) # 800056de <fdalloc>
    800058d6:	84aa                	mv	s1,a0
    return -1;
    800058d8:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800058da:	00054963          	bltz	a0,800058ec <sys_dup+0x42>
  filedup(f);
    800058de:	fd843503          	ld	a0,-40(s0)
    800058e2:	fffff097          	auipc	ra,0xfffff
    800058e6:	310080e7          	jalr	784(ra) # 80004bf2 <filedup>
  return fd;
    800058ea:	87a6                	mv	a5,s1
}
    800058ec:	853e                	mv	a0,a5
    800058ee:	70a2                	ld	ra,40(sp)
    800058f0:	7402                	ld	s0,32(sp)
    800058f2:	64e2                	ld	s1,24(sp)
    800058f4:	6145                	addi	sp,sp,48
    800058f6:	8082                	ret

00000000800058f8 <sys_read>:
{
    800058f8:	7179                	addi	sp,sp,-48
    800058fa:	f406                	sd	ra,40(sp)
    800058fc:	f022                	sd	s0,32(sp)
    800058fe:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005900:	fd840593          	addi	a1,s0,-40
    80005904:	4505                	li	a0,1
    80005906:	ffffd097          	auipc	ra,0xffffd
    8000590a:	75e080e7          	jalr	1886(ra) # 80003064 <argaddr>
  argint(2, &n);
    8000590e:	fe440593          	addi	a1,s0,-28
    80005912:	4509                	li	a0,2
    80005914:	ffffd097          	auipc	ra,0xffffd
    80005918:	730080e7          	jalr	1840(ra) # 80003044 <argint>
  if(argfd(0, 0, &f) < 0)
    8000591c:	fe840613          	addi	a2,s0,-24
    80005920:	4581                	li	a1,0
    80005922:	4501                	li	a0,0
    80005924:	00000097          	auipc	ra,0x0
    80005928:	d5a080e7          	jalr	-678(ra) # 8000567e <argfd>
    8000592c:	87aa                	mv	a5,a0
    return -1;
    8000592e:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005930:	0007cc63          	bltz	a5,80005948 <sys_read+0x50>
  return fileread(f, p, n);
    80005934:	fe442603          	lw	a2,-28(s0)
    80005938:	fd843583          	ld	a1,-40(s0)
    8000593c:	fe843503          	ld	a0,-24(s0)
    80005940:	fffff097          	auipc	ra,0xfffff
    80005944:	43e080e7          	jalr	1086(ra) # 80004d7e <fileread>
}
    80005948:	70a2                	ld	ra,40(sp)
    8000594a:	7402                	ld	s0,32(sp)
    8000594c:	6145                	addi	sp,sp,48
    8000594e:	8082                	ret

0000000080005950 <sys_write>:
{
    80005950:	7179                	addi	sp,sp,-48
    80005952:	f406                	sd	ra,40(sp)
    80005954:	f022                	sd	s0,32(sp)
    80005956:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005958:	fd840593          	addi	a1,s0,-40
    8000595c:	4505                	li	a0,1
    8000595e:	ffffd097          	auipc	ra,0xffffd
    80005962:	706080e7          	jalr	1798(ra) # 80003064 <argaddr>
  argint(2, &n);
    80005966:	fe440593          	addi	a1,s0,-28
    8000596a:	4509                	li	a0,2
    8000596c:	ffffd097          	auipc	ra,0xffffd
    80005970:	6d8080e7          	jalr	1752(ra) # 80003044 <argint>
  if(argfd(0, 0, &f) < 0)
    80005974:	fe840613          	addi	a2,s0,-24
    80005978:	4581                	li	a1,0
    8000597a:	4501                	li	a0,0
    8000597c:	00000097          	auipc	ra,0x0
    80005980:	d02080e7          	jalr	-766(ra) # 8000567e <argfd>
    80005984:	87aa                	mv	a5,a0
    return -1;
    80005986:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005988:	0007cc63          	bltz	a5,800059a0 <sys_write+0x50>
  return filewrite(f, p, n);
    8000598c:	fe442603          	lw	a2,-28(s0)
    80005990:	fd843583          	ld	a1,-40(s0)
    80005994:	fe843503          	ld	a0,-24(s0)
    80005998:	fffff097          	auipc	ra,0xfffff
    8000599c:	4a8080e7          	jalr	1192(ra) # 80004e40 <filewrite>
}
    800059a0:	70a2                	ld	ra,40(sp)
    800059a2:	7402                	ld	s0,32(sp)
    800059a4:	6145                	addi	sp,sp,48
    800059a6:	8082                	ret

00000000800059a8 <sys_close>:
{
    800059a8:	1101                	addi	sp,sp,-32
    800059aa:	ec06                	sd	ra,24(sp)
    800059ac:	e822                	sd	s0,16(sp)
    800059ae:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800059b0:	fe040613          	addi	a2,s0,-32
    800059b4:	fec40593          	addi	a1,s0,-20
    800059b8:	4501                	li	a0,0
    800059ba:	00000097          	auipc	ra,0x0
    800059be:	cc4080e7          	jalr	-828(ra) # 8000567e <argfd>
    return -1;
    800059c2:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800059c4:	02054463          	bltz	a0,800059ec <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800059c8:	ffffc097          	auipc	ra,0xffffc
    800059cc:	14a080e7          	jalr	330(ra) # 80001b12 <myproc>
    800059d0:	fec42783          	lw	a5,-20(s0)
    800059d4:	07e9                	addi	a5,a5,26
    800059d6:	078e                	slli	a5,a5,0x3
    800059d8:	97aa                	add	a5,a5,a0
    800059da:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800059de:	fe043503          	ld	a0,-32(s0)
    800059e2:	fffff097          	auipc	ra,0xfffff
    800059e6:	262080e7          	jalr	610(ra) # 80004c44 <fileclose>
  return 0;
    800059ea:	4781                	li	a5,0
}
    800059ec:	853e                	mv	a0,a5
    800059ee:	60e2                	ld	ra,24(sp)
    800059f0:	6442                	ld	s0,16(sp)
    800059f2:	6105                	addi	sp,sp,32
    800059f4:	8082                	ret

00000000800059f6 <sys_fstat>:
{
    800059f6:	1101                	addi	sp,sp,-32
    800059f8:	ec06                	sd	ra,24(sp)
    800059fa:	e822                	sd	s0,16(sp)
    800059fc:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    800059fe:	fe040593          	addi	a1,s0,-32
    80005a02:	4505                	li	a0,1
    80005a04:	ffffd097          	auipc	ra,0xffffd
    80005a08:	660080e7          	jalr	1632(ra) # 80003064 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005a0c:	fe840613          	addi	a2,s0,-24
    80005a10:	4581                	li	a1,0
    80005a12:	4501                	li	a0,0
    80005a14:	00000097          	auipc	ra,0x0
    80005a18:	c6a080e7          	jalr	-918(ra) # 8000567e <argfd>
    80005a1c:	87aa                	mv	a5,a0
    return -1;
    80005a1e:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005a20:	0007ca63          	bltz	a5,80005a34 <sys_fstat+0x3e>
  return filestat(f, st);
    80005a24:	fe043583          	ld	a1,-32(s0)
    80005a28:	fe843503          	ld	a0,-24(s0)
    80005a2c:	fffff097          	auipc	ra,0xfffff
    80005a30:	2e0080e7          	jalr	736(ra) # 80004d0c <filestat>
}
    80005a34:	60e2                	ld	ra,24(sp)
    80005a36:	6442                	ld	s0,16(sp)
    80005a38:	6105                	addi	sp,sp,32
    80005a3a:	8082                	ret

0000000080005a3c <sys_link>:
{
    80005a3c:	7169                	addi	sp,sp,-304
    80005a3e:	f606                	sd	ra,296(sp)
    80005a40:	f222                	sd	s0,288(sp)
    80005a42:	ee26                	sd	s1,280(sp)
    80005a44:	ea4a                	sd	s2,272(sp)
    80005a46:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005a48:	08000613          	li	a2,128
    80005a4c:	ed040593          	addi	a1,s0,-304
    80005a50:	4501                	li	a0,0
    80005a52:	ffffd097          	auipc	ra,0xffffd
    80005a56:	632080e7          	jalr	1586(ra) # 80003084 <argstr>
    return -1;
    80005a5a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005a5c:	10054e63          	bltz	a0,80005b78 <sys_link+0x13c>
    80005a60:	08000613          	li	a2,128
    80005a64:	f5040593          	addi	a1,s0,-176
    80005a68:	4505                	li	a0,1
    80005a6a:	ffffd097          	auipc	ra,0xffffd
    80005a6e:	61a080e7          	jalr	1562(ra) # 80003084 <argstr>
    return -1;
    80005a72:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005a74:	10054263          	bltz	a0,80005b78 <sys_link+0x13c>
  begin_op();
    80005a78:	fffff097          	auipc	ra,0xfffff
    80005a7c:	d00080e7          	jalr	-768(ra) # 80004778 <begin_op>
  if((ip = namei(old)) == 0){
    80005a80:	ed040513          	addi	a0,s0,-304
    80005a84:	fffff097          	auipc	ra,0xfffff
    80005a88:	ad8080e7          	jalr	-1320(ra) # 8000455c <namei>
    80005a8c:	84aa                	mv	s1,a0
    80005a8e:	c551                	beqz	a0,80005b1a <sys_link+0xde>
  ilock(ip);
    80005a90:	ffffe097          	auipc	ra,0xffffe
    80005a94:	326080e7          	jalr	806(ra) # 80003db6 <ilock>
  if(ip->type == T_DIR){
    80005a98:	04449703          	lh	a4,68(s1)
    80005a9c:	4785                	li	a5,1
    80005a9e:	08f70463          	beq	a4,a5,80005b26 <sys_link+0xea>
  ip->nlink++;
    80005aa2:	04a4d783          	lhu	a5,74(s1)
    80005aa6:	2785                	addiw	a5,a5,1
    80005aa8:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005aac:	8526                	mv	a0,s1
    80005aae:	ffffe097          	auipc	ra,0xffffe
    80005ab2:	23e080e7          	jalr	574(ra) # 80003cec <iupdate>
  iunlock(ip);
    80005ab6:	8526                	mv	a0,s1
    80005ab8:	ffffe097          	auipc	ra,0xffffe
    80005abc:	3c0080e7          	jalr	960(ra) # 80003e78 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005ac0:	fd040593          	addi	a1,s0,-48
    80005ac4:	f5040513          	addi	a0,s0,-176
    80005ac8:	fffff097          	auipc	ra,0xfffff
    80005acc:	ab2080e7          	jalr	-1358(ra) # 8000457a <nameiparent>
    80005ad0:	892a                	mv	s2,a0
    80005ad2:	c935                	beqz	a0,80005b46 <sys_link+0x10a>
  ilock(dp);
    80005ad4:	ffffe097          	auipc	ra,0xffffe
    80005ad8:	2e2080e7          	jalr	738(ra) # 80003db6 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005adc:	00092703          	lw	a4,0(s2)
    80005ae0:	409c                	lw	a5,0(s1)
    80005ae2:	04f71d63          	bne	a4,a5,80005b3c <sys_link+0x100>
    80005ae6:	40d0                	lw	a2,4(s1)
    80005ae8:	fd040593          	addi	a1,s0,-48
    80005aec:	854a                	mv	a0,s2
    80005aee:	fffff097          	auipc	ra,0xfffff
    80005af2:	9bc080e7          	jalr	-1604(ra) # 800044aa <dirlink>
    80005af6:	04054363          	bltz	a0,80005b3c <sys_link+0x100>
  iunlockput(dp);
    80005afa:	854a                	mv	a0,s2
    80005afc:	ffffe097          	auipc	ra,0xffffe
    80005b00:	51c080e7          	jalr	1308(ra) # 80004018 <iunlockput>
  iput(ip);
    80005b04:	8526                	mv	a0,s1
    80005b06:	ffffe097          	auipc	ra,0xffffe
    80005b0a:	46a080e7          	jalr	1130(ra) # 80003f70 <iput>
  end_op();
    80005b0e:	fffff097          	auipc	ra,0xfffff
    80005b12:	cea080e7          	jalr	-790(ra) # 800047f8 <end_op>
  return 0;
    80005b16:	4781                	li	a5,0
    80005b18:	a085                	j	80005b78 <sys_link+0x13c>
    end_op();
    80005b1a:	fffff097          	auipc	ra,0xfffff
    80005b1e:	cde080e7          	jalr	-802(ra) # 800047f8 <end_op>
    return -1;
    80005b22:	57fd                	li	a5,-1
    80005b24:	a891                	j	80005b78 <sys_link+0x13c>
    iunlockput(ip);
    80005b26:	8526                	mv	a0,s1
    80005b28:	ffffe097          	auipc	ra,0xffffe
    80005b2c:	4f0080e7          	jalr	1264(ra) # 80004018 <iunlockput>
    end_op();
    80005b30:	fffff097          	auipc	ra,0xfffff
    80005b34:	cc8080e7          	jalr	-824(ra) # 800047f8 <end_op>
    return -1;
    80005b38:	57fd                	li	a5,-1
    80005b3a:	a83d                	j	80005b78 <sys_link+0x13c>
    iunlockput(dp);
    80005b3c:	854a                	mv	a0,s2
    80005b3e:	ffffe097          	auipc	ra,0xffffe
    80005b42:	4da080e7          	jalr	1242(ra) # 80004018 <iunlockput>
  ilock(ip);
    80005b46:	8526                	mv	a0,s1
    80005b48:	ffffe097          	auipc	ra,0xffffe
    80005b4c:	26e080e7          	jalr	622(ra) # 80003db6 <ilock>
  ip->nlink--;
    80005b50:	04a4d783          	lhu	a5,74(s1)
    80005b54:	37fd                	addiw	a5,a5,-1
    80005b56:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005b5a:	8526                	mv	a0,s1
    80005b5c:	ffffe097          	auipc	ra,0xffffe
    80005b60:	190080e7          	jalr	400(ra) # 80003cec <iupdate>
  iunlockput(ip);
    80005b64:	8526                	mv	a0,s1
    80005b66:	ffffe097          	auipc	ra,0xffffe
    80005b6a:	4b2080e7          	jalr	1202(ra) # 80004018 <iunlockput>
  end_op();
    80005b6e:	fffff097          	auipc	ra,0xfffff
    80005b72:	c8a080e7          	jalr	-886(ra) # 800047f8 <end_op>
  return -1;
    80005b76:	57fd                	li	a5,-1
}
    80005b78:	853e                	mv	a0,a5
    80005b7a:	70b2                	ld	ra,296(sp)
    80005b7c:	7412                	ld	s0,288(sp)
    80005b7e:	64f2                	ld	s1,280(sp)
    80005b80:	6952                	ld	s2,272(sp)
    80005b82:	6155                	addi	sp,sp,304
    80005b84:	8082                	ret

0000000080005b86 <sys_unlink>:
{
    80005b86:	7151                	addi	sp,sp,-240
    80005b88:	f586                	sd	ra,232(sp)
    80005b8a:	f1a2                	sd	s0,224(sp)
    80005b8c:	eda6                	sd	s1,216(sp)
    80005b8e:	e9ca                	sd	s2,208(sp)
    80005b90:	e5ce                	sd	s3,200(sp)
    80005b92:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005b94:	08000613          	li	a2,128
    80005b98:	f3040593          	addi	a1,s0,-208
    80005b9c:	4501                	li	a0,0
    80005b9e:	ffffd097          	auipc	ra,0xffffd
    80005ba2:	4e6080e7          	jalr	1254(ra) # 80003084 <argstr>
    80005ba6:	18054163          	bltz	a0,80005d28 <sys_unlink+0x1a2>
  begin_op();
    80005baa:	fffff097          	auipc	ra,0xfffff
    80005bae:	bce080e7          	jalr	-1074(ra) # 80004778 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005bb2:	fb040593          	addi	a1,s0,-80
    80005bb6:	f3040513          	addi	a0,s0,-208
    80005bba:	fffff097          	auipc	ra,0xfffff
    80005bbe:	9c0080e7          	jalr	-1600(ra) # 8000457a <nameiparent>
    80005bc2:	84aa                	mv	s1,a0
    80005bc4:	c979                	beqz	a0,80005c9a <sys_unlink+0x114>
  ilock(dp);
    80005bc6:	ffffe097          	auipc	ra,0xffffe
    80005bca:	1f0080e7          	jalr	496(ra) # 80003db6 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005bce:	00003597          	auipc	a1,0x3
    80005bd2:	b5a58593          	addi	a1,a1,-1190 # 80008728 <syscalls+0x2c8>
    80005bd6:	fb040513          	addi	a0,s0,-80
    80005bda:	ffffe097          	auipc	ra,0xffffe
    80005bde:	6a6080e7          	jalr	1702(ra) # 80004280 <namecmp>
    80005be2:	14050a63          	beqz	a0,80005d36 <sys_unlink+0x1b0>
    80005be6:	00003597          	auipc	a1,0x3
    80005bea:	b4a58593          	addi	a1,a1,-1206 # 80008730 <syscalls+0x2d0>
    80005bee:	fb040513          	addi	a0,s0,-80
    80005bf2:	ffffe097          	auipc	ra,0xffffe
    80005bf6:	68e080e7          	jalr	1678(ra) # 80004280 <namecmp>
    80005bfa:	12050e63          	beqz	a0,80005d36 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005bfe:	f2c40613          	addi	a2,s0,-212
    80005c02:	fb040593          	addi	a1,s0,-80
    80005c06:	8526                	mv	a0,s1
    80005c08:	ffffe097          	auipc	ra,0xffffe
    80005c0c:	692080e7          	jalr	1682(ra) # 8000429a <dirlookup>
    80005c10:	892a                	mv	s2,a0
    80005c12:	12050263          	beqz	a0,80005d36 <sys_unlink+0x1b0>
  ilock(ip);
    80005c16:	ffffe097          	auipc	ra,0xffffe
    80005c1a:	1a0080e7          	jalr	416(ra) # 80003db6 <ilock>
  if(ip->nlink < 1)
    80005c1e:	04a91783          	lh	a5,74(s2)
    80005c22:	08f05263          	blez	a5,80005ca6 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005c26:	04491703          	lh	a4,68(s2)
    80005c2a:	4785                	li	a5,1
    80005c2c:	08f70563          	beq	a4,a5,80005cb6 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005c30:	4641                	li	a2,16
    80005c32:	4581                	li	a1,0
    80005c34:	fc040513          	addi	a0,s0,-64
    80005c38:	ffffb097          	auipc	ra,0xffffb
    80005c3c:	09a080e7          	jalr	154(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005c40:	4741                	li	a4,16
    80005c42:	f2c42683          	lw	a3,-212(s0)
    80005c46:	fc040613          	addi	a2,s0,-64
    80005c4a:	4581                	li	a1,0
    80005c4c:	8526                	mv	a0,s1
    80005c4e:	ffffe097          	auipc	ra,0xffffe
    80005c52:	514080e7          	jalr	1300(ra) # 80004162 <writei>
    80005c56:	47c1                	li	a5,16
    80005c58:	0af51563          	bne	a0,a5,80005d02 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005c5c:	04491703          	lh	a4,68(s2)
    80005c60:	4785                	li	a5,1
    80005c62:	0af70863          	beq	a4,a5,80005d12 <sys_unlink+0x18c>
  iunlockput(dp);
    80005c66:	8526                	mv	a0,s1
    80005c68:	ffffe097          	auipc	ra,0xffffe
    80005c6c:	3b0080e7          	jalr	944(ra) # 80004018 <iunlockput>
  ip->nlink--;
    80005c70:	04a95783          	lhu	a5,74(s2)
    80005c74:	37fd                	addiw	a5,a5,-1
    80005c76:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005c7a:	854a                	mv	a0,s2
    80005c7c:	ffffe097          	auipc	ra,0xffffe
    80005c80:	070080e7          	jalr	112(ra) # 80003cec <iupdate>
  iunlockput(ip);
    80005c84:	854a                	mv	a0,s2
    80005c86:	ffffe097          	auipc	ra,0xffffe
    80005c8a:	392080e7          	jalr	914(ra) # 80004018 <iunlockput>
  end_op();
    80005c8e:	fffff097          	auipc	ra,0xfffff
    80005c92:	b6a080e7          	jalr	-1174(ra) # 800047f8 <end_op>
  return 0;
    80005c96:	4501                	li	a0,0
    80005c98:	a84d                	j	80005d4a <sys_unlink+0x1c4>
    end_op();
    80005c9a:	fffff097          	auipc	ra,0xfffff
    80005c9e:	b5e080e7          	jalr	-1186(ra) # 800047f8 <end_op>
    return -1;
    80005ca2:	557d                	li	a0,-1
    80005ca4:	a05d                	j	80005d4a <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005ca6:	00003517          	auipc	a0,0x3
    80005caa:	a9250513          	addi	a0,a0,-1390 # 80008738 <syscalls+0x2d8>
    80005cae:	ffffb097          	auipc	ra,0xffffb
    80005cb2:	890080e7          	jalr	-1904(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005cb6:	04c92703          	lw	a4,76(s2)
    80005cba:	02000793          	li	a5,32
    80005cbe:	f6e7f9e3          	bgeu	a5,a4,80005c30 <sys_unlink+0xaa>
    80005cc2:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005cc6:	4741                	li	a4,16
    80005cc8:	86ce                	mv	a3,s3
    80005cca:	f1840613          	addi	a2,s0,-232
    80005cce:	4581                	li	a1,0
    80005cd0:	854a                	mv	a0,s2
    80005cd2:	ffffe097          	auipc	ra,0xffffe
    80005cd6:	398080e7          	jalr	920(ra) # 8000406a <readi>
    80005cda:	47c1                	li	a5,16
    80005cdc:	00f51b63          	bne	a0,a5,80005cf2 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005ce0:	f1845783          	lhu	a5,-232(s0)
    80005ce4:	e7a1                	bnez	a5,80005d2c <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005ce6:	29c1                	addiw	s3,s3,16
    80005ce8:	04c92783          	lw	a5,76(s2)
    80005cec:	fcf9ede3          	bltu	s3,a5,80005cc6 <sys_unlink+0x140>
    80005cf0:	b781                	j	80005c30 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005cf2:	00003517          	auipc	a0,0x3
    80005cf6:	a5e50513          	addi	a0,a0,-1442 # 80008750 <syscalls+0x2f0>
    80005cfa:	ffffb097          	auipc	ra,0xffffb
    80005cfe:	844080e7          	jalr	-1980(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005d02:	00003517          	auipc	a0,0x3
    80005d06:	a6650513          	addi	a0,a0,-1434 # 80008768 <syscalls+0x308>
    80005d0a:	ffffb097          	auipc	ra,0xffffb
    80005d0e:	834080e7          	jalr	-1996(ra) # 8000053e <panic>
    dp->nlink--;
    80005d12:	04a4d783          	lhu	a5,74(s1)
    80005d16:	37fd                	addiw	a5,a5,-1
    80005d18:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005d1c:	8526                	mv	a0,s1
    80005d1e:	ffffe097          	auipc	ra,0xffffe
    80005d22:	fce080e7          	jalr	-50(ra) # 80003cec <iupdate>
    80005d26:	b781                	j	80005c66 <sys_unlink+0xe0>
    return -1;
    80005d28:	557d                	li	a0,-1
    80005d2a:	a005                	j	80005d4a <sys_unlink+0x1c4>
    iunlockput(ip);
    80005d2c:	854a                	mv	a0,s2
    80005d2e:	ffffe097          	auipc	ra,0xffffe
    80005d32:	2ea080e7          	jalr	746(ra) # 80004018 <iunlockput>
  iunlockput(dp);
    80005d36:	8526                	mv	a0,s1
    80005d38:	ffffe097          	auipc	ra,0xffffe
    80005d3c:	2e0080e7          	jalr	736(ra) # 80004018 <iunlockput>
  end_op();
    80005d40:	fffff097          	auipc	ra,0xfffff
    80005d44:	ab8080e7          	jalr	-1352(ra) # 800047f8 <end_op>
  return -1;
    80005d48:	557d                	li	a0,-1
}
    80005d4a:	70ae                	ld	ra,232(sp)
    80005d4c:	740e                	ld	s0,224(sp)
    80005d4e:	64ee                	ld	s1,216(sp)
    80005d50:	694e                	ld	s2,208(sp)
    80005d52:	69ae                	ld	s3,200(sp)
    80005d54:	616d                	addi	sp,sp,240
    80005d56:	8082                	ret

0000000080005d58 <sys_open>:

uint64
sys_open(void)
{
    80005d58:	7131                	addi	sp,sp,-192
    80005d5a:	fd06                	sd	ra,184(sp)
    80005d5c:	f922                	sd	s0,176(sp)
    80005d5e:	f526                	sd	s1,168(sp)
    80005d60:	f14a                	sd	s2,160(sp)
    80005d62:	ed4e                	sd	s3,152(sp)
    80005d64:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005d66:	f4c40593          	addi	a1,s0,-180
    80005d6a:	4505                	li	a0,1
    80005d6c:	ffffd097          	auipc	ra,0xffffd
    80005d70:	2d8080e7          	jalr	728(ra) # 80003044 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005d74:	08000613          	li	a2,128
    80005d78:	f5040593          	addi	a1,s0,-176
    80005d7c:	4501                	li	a0,0
    80005d7e:	ffffd097          	auipc	ra,0xffffd
    80005d82:	306080e7          	jalr	774(ra) # 80003084 <argstr>
    80005d86:	87aa                	mv	a5,a0
    return -1;
    80005d88:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005d8a:	0a07c963          	bltz	a5,80005e3c <sys_open+0xe4>

  begin_op();
    80005d8e:	fffff097          	auipc	ra,0xfffff
    80005d92:	9ea080e7          	jalr	-1558(ra) # 80004778 <begin_op>

  if(omode & O_CREATE){
    80005d96:	f4c42783          	lw	a5,-180(s0)
    80005d9a:	2007f793          	andi	a5,a5,512
    80005d9e:	cfc5                	beqz	a5,80005e56 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005da0:	4681                	li	a3,0
    80005da2:	4601                	li	a2,0
    80005da4:	4589                	li	a1,2
    80005da6:	f5040513          	addi	a0,s0,-176
    80005daa:	00000097          	auipc	ra,0x0
    80005dae:	976080e7          	jalr	-1674(ra) # 80005720 <create>
    80005db2:	84aa                	mv	s1,a0
    if(ip == 0){
    80005db4:	c959                	beqz	a0,80005e4a <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005db6:	04449703          	lh	a4,68(s1)
    80005dba:	478d                	li	a5,3
    80005dbc:	00f71763          	bne	a4,a5,80005dca <sys_open+0x72>
    80005dc0:	0464d703          	lhu	a4,70(s1)
    80005dc4:	47a5                	li	a5,9
    80005dc6:	0ce7ed63          	bltu	a5,a4,80005ea0 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005dca:	fffff097          	auipc	ra,0xfffff
    80005dce:	dbe080e7          	jalr	-578(ra) # 80004b88 <filealloc>
    80005dd2:	89aa                	mv	s3,a0
    80005dd4:	10050363          	beqz	a0,80005eda <sys_open+0x182>
    80005dd8:	00000097          	auipc	ra,0x0
    80005ddc:	906080e7          	jalr	-1786(ra) # 800056de <fdalloc>
    80005de0:	892a                	mv	s2,a0
    80005de2:	0e054763          	bltz	a0,80005ed0 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005de6:	04449703          	lh	a4,68(s1)
    80005dea:	478d                	li	a5,3
    80005dec:	0cf70563          	beq	a4,a5,80005eb6 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005df0:	4789                	li	a5,2
    80005df2:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005df6:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005dfa:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005dfe:	f4c42783          	lw	a5,-180(s0)
    80005e02:	0017c713          	xori	a4,a5,1
    80005e06:	8b05                	andi	a4,a4,1
    80005e08:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005e0c:	0037f713          	andi	a4,a5,3
    80005e10:	00e03733          	snez	a4,a4
    80005e14:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005e18:	4007f793          	andi	a5,a5,1024
    80005e1c:	c791                	beqz	a5,80005e28 <sys_open+0xd0>
    80005e1e:	04449703          	lh	a4,68(s1)
    80005e22:	4789                	li	a5,2
    80005e24:	0af70063          	beq	a4,a5,80005ec4 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005e28:	8526                	mv	a0,s1
    80005e2a:	ffffe097          	auipc	ra,0xffffe
    80005e2e:	04e080e7          	jalr	78(ra) # 80003e78 <iunlock>
  end_op();
    80005e32:	fffff097          	auipc	ra,0xfffff
    80005e36:	9c6080e7          	jalr	-1594(ra) # 800047f8 <end_op>

  return fd;
    80005e3a:	854a                	mv	a0,s2
}
    80005e3c:	70ea                	ld	ra,184(sp)
    80005e3e:	744a                	ld	s0,176(sp)
    80005e40:	74aa                	ld	s1,168(sp)
    80005e42:	790a                	ld	s2,160(sp)
    80005e44:	69ea                	ld	s3,152(sp)
    80005e46:	6129                	addi	sp,sp,192
    80005e48:	8082                	ret
      end_op();
    80005e4a:	fffff097          	auipc	ra,0xfffff
    80005e4e:	9ae080e7          	jalr	-1618(ra) # 800047f8 <end_op>
      return -1;
    80005e52:	557d                	li	a0,-1
    80005e54:	b7e5                	j	80005e3c <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005e56:	f5040513          	addi	a0,s0,-176
    80005e5a:	ffffe097          	auipc	ra,0xffffe
    80005e5e:	702080e7          	jalr	1794(ra) # 8000455c <namei>
    80005e62:	84aa                	mv	s1,a0
    80005e64:	c905                	beqz	a0,80005e94 <sys_open+0x13c>
    ilock(ip);
    80005e66:	ffffe097          	auipc	ra,0xffffe
    80005e6a:	f50080e7          	jalr	-176(ra) # 80003db6 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005e6e:	04449703          	lh	a4,68(s1)
    80005e72:	4785                	li	a5,1
    80005e74:	f4f711e3          	bne	a4,a5,80005db6 <sys_open+0x5e>
    80005e78:	f4c42783          	lw	a5,-180(s0)
    80005e7c:	d7b9                	beqz	a5,80005dca <sys_open+0x72>
      iunlockput(ip);
    80005e7e:	8526                	mv	a0,s1
    80005e80:	ffffe097          	auipc	ra,0xffffe
    80005e84:	198080e7          	jalr	408(ra) # 80004018 <iunlockput>
      end_op();
    80005e88:	fffff097          	auipc	ra,0xfffff
    80005e8c:	970080e7          	jalr	-1680(ra) # 800047f8 <end_op>
      return -1;
    80005e90:	557d                	li	a0,-1
    80005e92:	b76d                	j	80005e3c <sys_open+0xe4>
      end_op();
    80005e94:	fffff097          	auipc	ra,0xfffff
    80005e98:	964080e7          	jalr	-1692(ra) # 800047f8 <end_op>
      return -1;
    80005e9c:	557d                	li	a0,-1
    80005e9e:	bf79                	j	80005e3c <sys_open+0xe4>
    iunlockput(ip);
    80005ea0:	8526                	mv	a0,s1
    80005ea2:	ffffe097          	auipc	ra,0xffffe
    80005ea6:	176080e7          	jalr	374(ra) # 80004018 <iunlockput>
    end_op();
    80005eaa:	fffff097          	auipc	ra,0xfffff
    80005eae:	94e080e7          	jalr	-1714(ra) # 800047f8 <end_op>
    return -1;
    80005eb2:	557d                	li	a0,-1
    80005eb4:	b761                	j	80005e3c <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005eb6:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005eba:	04649783          	lh	a5,70(s1)
    80005ebe:	02f99223          	sh	a5,36(s3)
    80005ec2:	bf25                	j	80005dfa <sys_open+0xa2>
    itrunc(ip);
    80005ec4:	8526                	mv	a0,s1
    80005ec6:	ffffe097          	auipc	ra,0xffffe
    80005eca:	ffe080e7          	jalr	-2(ra) # 80003ec4 <itrunc>
    80005ece:	bfa9                	j	80005e28 <sys_open+0xd0>
      fileclose(f);
    80005ed0:	854e                	mv	a0,s3
    80005ed2:	fffff097          	auipc	ra,0xfffff
    80005ed6:	d72080e7          	jalr	-654(ra) # 80004c44 <fileclose>
    iunlockput(ip);
    80005eda:	8526                	mv	a0,s1
    80005edc:	ffffe097          	auipc	ra,0xffffe
    80005ee0:	13c080e7          	jalr	316(ra) # 80004018 <iunlockput>
    end_op();
    80005ee4:	fffff097          	auipc	ra,0xfffff
    80005ee8:	914080e7          	jalr	-1772(ra) # 800047f8 <end_op>
    return -1;
    80005eec:	557d                	li	a0,-1
    80005eee:	b7b9                	j	80005e3c <sys_open+0xe4>

0000000080005ef0 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005ef0:	7175                	addi	sp,sp,-144
    80005ef2:	e506                	sd	ra,136(sp)
    80005ef4:	e122                	sd	s0,128(sp)
    80005ef6:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005ef8:	fffff097          	auipc	ra,0xfffff
    80005efc:	880080e7          	jalr	-1920(ra) # 80004778 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005f00:	08000613          	li	a2,128
    80005f04:	f7040593          	addi	a1,s0,-144
    80005f08:	4501                	li	a0,0
    80005f0a:	ffffd097          	auipc	ra,0xffffd
    80005f0e:	17a080e7          	jalr	378(ra) # 80003084 <argstr>
    80005f12:	02054963          	bltz	a0,80005f44 <sys_mkdir+0x54>
    80005f16:	4681                	li	a3,0
    80005f18:	4601                	li	a2,0
    80005f1a:	4585                	li	a1,1
    80005f1c:	f7040513          	addi	a0,s0,-144
    80005f20:	00000097          	auipc	ra,0x0
    80005f24:	800080e7          	jalr	-2048(ra) # 80005720 <create>
    80005f28:	cd11                	beqz	a0,80005f44 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005f2a:	ffffe097          	auipc	ra,0xffffe
    80005f2e:	0ee080e7          	jalr	238(ra) # 80004018 <iunlockput>
  end_op();
    80005f32:	fffff097          	auipc	ra,0xfffff
    80005f36:	8c6080e7          	jalr	-1850(ra) # 800047f8 <end_op>
  return 0;
    80005f3a:	4501                	li	a0,0
}
    80005f3c:	60aa                	ld	ra,136(sp)
    80005f3e:	640a                	ld	s0,128(sp)
    80005f40:	6149                	addi	sp,sp,144
    80005f42:	8082                	ret
    end_op();
    80005f44:	fffff097          	auipc	ra,0xfffff
    80005f48:	8b4080e7          	jalr	-1868(ra) # 800047f8 <end_op>
    return -1;
    80005f4c:	557d                	li	a0,-1
    80005f4e:	b7fd                	j	80005f3c <sys_mkdir+0x4c>

0000000080005f50 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005f50:	7135                	addi	sp,sp,-160
    80005f52:	ed06                	sd	ra,152(sp)
    80005f54:	e922                	sd	s0,144(sp)
    80005f56:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005f58:	fffff097          	auipc	ra,0xfffff
    80005f5c:	820080e7          	jalr	-2016(ra) # 80004778 <begin_op>
  argint(1, &major);
    80005f60:	f6c40593          	addi	a1,s0,-148
    80005f64:	4505                	li	a0,1
    80005f66:	ffffd097          	auipc	ra,0xffffd
    80005f6a:	0de080e7          	jalr	222(ra) # 80003044 <argint>
  argint(2, &minor);
    80005f6e:	f6840593          	addi	a1,s0,-152
    80005f72:	4509                	li	a0,2
    80005f74:	ffffd097          	auipc	ra,0xffffd
    80005f78:	0d0080e7          	jalr	208(ra) # 80003044 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005f7c:	08000613          	li	a2,128
    80005f80:	f7040593          	addi	a1,s0,-144
    80005f84:	4501                	li	a0,0
    80005f86:	ffffd097          	auipc	ra,0xffffd
    80005f8a:	0fe080e7          	jalr	254(ra) # 80003084 <argstr>
    80005f8e:	02054b63          	bltz	a0,80005fc4 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005f92:	f6841683          	lh	a3,-152(s0)
    80005f96:	f6c41603          	lh	a2,-148(s0)
    80005f9a:	458d                	li	a1,3
    80005f9c:	f7040513          	addi	a0,s0,-144
    80005fa0:	fffff097          	auipc	ra,0xfffff
    80005fa4:	780080e7          	jalr	1920(ra) # 80005720 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005fa8:	cd11                	beqz	a0,80005fc4 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005faa:	ffffe097          	auipc	ra,0xffffe
    80005fae:	06e080e7          	jalr	110(ra) # 80004018 <iunlockput>
  end_op();
    80005fb2:	fffff097          	auipc	ra,0xfffff
    80005fb6:	846080e7          	jalr	-1978(ra) # 800047f8 <end_op>
  return 0;
    80005fba:	4501                	li	a0,0
}
    80005fbc:	60ea                	ld	ra,152(sp)
    80005fbe:	644a                	ld	s0,144(sp)
    80005fc0:	610d                	addi	sp,sp,160
    80005fc2:	8082                	ret
    end_op();
    80005fc4:	fffff097          	auipc	ra,0xfffff
    80005fc8:	834080e7          	jalr	-1996(ra) # 800047f8 <end_op>
    return -1;
    80005fcc:	557d                	li	a0,-1
    80005fce:	b7fd                	j	80005fbc <sys_mknod+0x6c>

0000000080005fd0 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005fd0:	7135                	addi	sp,sp,-160
    80005fd2:	ed06                	sd	ra,152(sp)
    80005fd4:	e922                	sd	s0,144(sp)
    80005fd6:	e526                	sd	s1,136(sp)
    80005fd8:	e14a                	sd	s2,128(sp)
    80005fda:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005fdc:	ffffc097          	auipc	ra,0xffffc
    80005fe0:	b36080e7          	jalr	-1226(ra) # 80001b12 <myproc>
    80005fe4:	892a                	mv	s2,a0
  
  begin_op();
    80005fe6:	ffffe097          	auipc	ra,0xffffe
    80005fea:	792080e7          	jalr	1938(ra) # 80004778 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005fee:	08000613          	li	a2,128
    80005ff2:	f6040593          	addi	a1,s0,-160
    80005ff6:	4501                	li	a0,0
    80005ff8:	ffffd097          	auipc	ra,0xffffd
    80005ffc:	08c080e7          	jalr	140(ra) # 80003084 <argstr>
    80006000:	04054b63          	bltz	a0,80006056 <sys_chdir+0x86>
    80006004:	f6040513          	addi	a0,s0,-160
    80006008:	ffffe097          	auipc	ra,0xffffe
    8000600c:	554080e7          	jalr	1364(ra) # 8000455c <namei>
    80006010:	84aa                	mv	s1,a0
    80006012:	c131                	beqz	a0,80006056 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80006014:	ffffe097          	auipc	ra,0xffffe
    80006018:	da2080e7          	jalr	-606(ra) # 80003db6 <ilock>
  if(ip->type != T_DIR){
    8000601c:	04449703          	lh	a4,68(s1)
    80006020:	4785                	li	a5,1
    80006022:	04f71063          	bne	a4,a5,80006062 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80006026:	8526                	mv	a0,s1
    80006028:	ffffe097          	auipc	ra,0xffffe
    8000602c:	e50080e7          	jalr	-432(ra) # 80003e78 <iunlock>
  iput(p->cwd);
    80006030:	15093503          	ld	a0,336(s2)
    80006034:	ffffe097          	auipc	ra,0xffffe
    80006038:	f3c080e7          	jalr	-196(ra) # 80003f70 <iput>
  end_op();
    8000603c:	ffffe097          	auipc	ra,0xffffe
    80006040:	7bc080e7          	jalr	1980(ra) # 800047f8 <end_op>
  p->cwd = ip;
    80006044:	14993823          	sd	s1,336(s2)
  return 0;
    80006048:	4501                	li	a0,0
}
    8000604a:	60ea                	ld	ra,152(sp)
    8000604c:	644a                	ld	s0,144(sp)
    8000604e:	64aa                	ld	s1,136(sp)
    80006050:	690a                	ld	s2,128(sp)
    80006052:	610d                	addi	sp,sp,160
    80006054:	8082                	ret
    end_op();
    80006056:	ffffe097          	auipc	ra,0xffffe
    8000605a:	7a2080e7          	jalr	1954(ra) # 800047f8 <end_op>
    return -1;
    8000605e:	557d                	li	a0,-1
    80006060:	b7ed                	j	8000604a <sys_chdir+0x7a>
    iunlockput(ip);
    80006062:	8526                	mv	a0,s1
    80006064:	ffffe097          	auipc	ra,0xffffe
    80006068:	fb4080e7          	jalr	-76(ra) # 80004018 <iunlockput>
    end_op();
    8000606c:	ffffe097          	auipc	ra,0xffffe
    80006070:	78c080e7          	jalr	1932(ra) # 800047f8 <end_op>
    return -1;
    80006074:	557d                	li	a0,-1
    80006076:	bfd1                	j	8000604a <sys_chdir+0x7a>

0000000080006078 <sys_exec>:

uint64
sys_exec(void)
{
    80006078:	7145                	addi	sp,sp,-464
    8000607a:	e786                	sd	ra,456(sp)
    8000607c:	e3a2                	sd	s0,448(sp)
    8000607e:	ff26                	sd	s1,440(sp)
    80006080:	fb4a                	sd	s2,432(sp)
    80006082:	f74e                	sd	s3,424(sp)
    80006084:	f352                	sd	s4,416(sp)
    80006086:	ef56                	sd	s5,408(sp)
    80006088:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    8000608a:	e3840593          	addi	a1,s0,-456
    8000608e:	4505                	li	a0,1
    80006090:	ffffd097          	auipc	ra,0xffffd
    80006094:	fd4080e7          	jalr	-44(ra) # 80003064 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80006098:	08000613          	li	a2,128
    8000609c:	f4040593          	addi	a1,s0,-192
    800060a0:	4501                	li	a0,0
    800060a2:	ffffd097          	auipc	ra,0xffffd
    800060a6:	fe2080e7          	jalr	-30(ra) # 80003084 <argstr>
    800060aa:	87aa                	mv	a5,a0
    return -1;
    800060ac:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    800060ae:	0c07c263          	bltz	a5,80006172 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    800060b2:	10000613          	li	a2,256
    800060b6:	4581                	li	a1,0
    800060b8:	e4040513          	addi	a0,s0,-448
    800060bc:	ffffb097          	auipc	ra,0xffffb
    800060c0:	c16080e7          	jalr	-1002(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800060c4:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800060c8:	89a6                	mv	s3,s1
    800060ca:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800060cc:	02000a13          	li	s4,32
    800060d0:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800060d4:	00391793          	slli	a5,s2,0x3
    800060d8:	e3040593          	addi	a1,s0,-464
    800060dc:	e3843503          	ld	a0,-456(s0)
    800060e0:	953e                	add	a0,a0,a5
    800060e2:	ffffd097          	auipc	ra,0xffffd
    800060e6:	ec4080e7          	jalr	-316(ra) # 80002fa6 <fetchaddr>
    800060ea:	02054a63          	bltz	a0,8000611e <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    800060ee:	e3043783          	ld	a5,-464(s0)
    800060f2:	c3b9                	beqz	a5,80006138 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    800060f4:	ffffb097          	auipc	ra,0xffffb
    800060f8:	9f2080e7          	jalr	-1550(ra) # 80000ae6 <kalloc>
    800060fc:	85aa                	mv	a1,a0
    800060fe:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80006102:	cd11                	beqz	a0,8000611e <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80006104:	6605                	lui	a2,0x1
    80006106:	e3043503          	ld	a0,-464(s0)
    8000610a:	ffffd097          	auipc	ra,0xffffd
    8000610e:	eee080e7          	jalr	-274(ra) # 80002ff8 <fetchstr>
    80006112:	00054663          	bltz	a0,8000611e <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80006116:	0905                	addi	s2,s2,1
    80006118:	09a1                	addi	s3,s3,8
    8000611a:	fb491be3          	bne	s2,s4,800060d0 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000611e:	10048913          	addi	s2,s1,256
    80006122:	6088                	ld	a0,0(s1)
    80006124:	c531                	beqz	a0,80006170 <sys_exec+0xf8>
    kfree(argv[i]);
    80006126:	ffffb097          	auipc	ra,0xffffb
    8000612a:	8c4080e7          	jalr	-1852(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000612e:	04a1                	addi	s1,s1,8
    80006130:	ff2499e3          	bne	s1,s2,80006122 <sys_exec+0xaa>
  return -1;
    80006134:	557d                	li	a0,-1
    80006136:	a835                	j	80006172 <sys_exec+0xfa>
      argv[i] = 0;
    80006138:	0a8e                	slli	s5,s5,0x3
    8000613a:	fc040793          	addi	a5,s0,-64
    8000613e:	9abe                	add	s5,s5,a5
    80006140:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80006144:	e4040593          	addi	a1,s0,-448
    80006148:	f4040513          	addi	a0,s0,-192
    8000614c:	fffff097          	auipc	ra,0xfffff
    80006150:	172080e7          	jalr	370(ra) # 800052be <exec>
    80006154:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006156:	10048993          	addi	s3,s1,256
    8000615a:	6088                	ld	a0,0(s1)
    8000615c:	c901                	beqz	a0,8000616c <sys_exec+0xf4>
    kfree(argv[i]);
    8000615e:	ffffb097          	auipc	ra,0xffffb
    80006162:	88c080e7          	jalr	-1908(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006166:	04a1                	addi	s1,s1,8
    80006168:	ff3499e3          	bne	s1,s3,8000615a <sys_exec+0xe2>
  return ret;
    8000616c:	854a                	mv	a0,s2
    8000616e:	a011                	j	80006172 <sys_exec+0xfa>
  return -1;
    80006170:	557d                	li	a0,-1
}
    80006172:	60be                	ld	ra,456(sp)
    80006174:	641e                	ld	s0,448(sp)
    80006176:	74fa                	ld	s1,440(sp)
    80006178:	795a                	ld	s2,432(sp)
    8000617a:	79ba                	ld	s3,424(sp)
    8000617c:	7a1a                	ld	s4,416(sp)
    8000617e:	6afa                	ld	s5,408(sp)
    80006180:	6179                	addi	sp,sp,464
    80006182:	8082                	ret

0000000080006184 <sys_pipe>:

uint64
sys_pipe(void)
{
    80006184:	7139                	addi	sp,sp,-64
    80006186:	fc06                	sd	ra,56(sp)
    80006188:	f822                	sd	s0,48(sp)
    8000618a:	f426                	sd	s1,40(sp)
    8000618c:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    8000618e:	ffffc097          	auipc	ra,0xffffc
    80006192:	984080e7          	jalr	-1660(ra) # 80001b12 <myproc>
    80006196:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80006198:	fd840593          	addi	a1,s0,-40
    8000619c:	4501                	li	a0,0
    8000619e:	ffffd097          	auipc	ra,0xffffd
    800061a2:	ec6080e7          	jalr	-314(ra) # 80003064 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    800061a6:	fc840593          	addi	a1,s0,-56
    800061aa:	fd040513          	addi	a0,s0,-48
    800061ae:	fffff097          	auipc	ra,0xfffff
    800061b2:	dc6080e7          	jalr	-570(ra) # 80004f74 <pipealloc>
    return -1;
    800061b6:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800061b8:	0c054463          	bltz	a0,80006280 <sys_pipe+0xfc>
  fd0 = -1;
    800061bc:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800061c0:	fd043503          	ld	a0,-48(s0)
    800061c4:	fffff097          	auipc	ra,0xfffff
    800061c8:	51a080e7          	jalr	1306(ra) # 800056de <fdalloc>
    800061cc:	fca42223          	sw	a0,-60(s0)
    800061d0:	08054b63          	bltz	a0,80006266 <sys_pipe+0xe2>
    800061d4:	fc843503          	ld	a0,-56(s0)
    800061d8:	fffff097          	auipc	ra,0xfffff
    800061dc:	506080e7          	jalr	1286(ra) # 800056de <fdalloc>
    800061e0:	fca42023          	sw	a0,-64(s0)
    800061e4:	06054863          	bltz	a0,80006254 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800061e8:	4691                	li	a3,4
    800061ea:	fc440613          	addi	a2,s0,-60
    800061ee:	fd843583          	ld	a1,-40(s0)
    800061f2:	68a8                	ld	a0,80(s1)
    800061f4:	ffffb097          	auipc	ra,0xffffb
    800061f8:	474080e7          	jalr	1140(ra) # 80001668 <copyout>
    800061fc:	02054063          	bltz	a0,8000621c <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006200:	4691                	li	a3,4
    80006202:	fc040613          	addi	a2,s0,-64
    80006206:	fd843583          	ld	a1,-40(s0)
    8000620a:	0591                	addi	a1,a1,4
    8000620c:	68a8                	ld	a0,80(s1)
    8000620e:	ffffb097          	auipc	ra,0xffffb
    80006212:	45a080e7          	jalr	1114(ra) # 80001668 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006216:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006218:	06055463          	bgez	a0,80006280 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    8000621c:	fc442783          	lw	a5,-60(s0)
    80006220:	07e9                	addi	a5,a5,26
    80006222:	078e                	slli	a5,a5,0x3
    80006224:	97a6                	add	a5,a5,s1
    80006226:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    8000622a:	fc042503          	lw	a0,-64(s0)
    8000622e:	0569                	addi	a0,a0,26
    80006230:	050e                	slli	a0,a0,0x3
    80006232:	94aa                	add	s1,s1,a0
    80006234:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80006238:	fd043503          	ld	a0,-48(s0)
    8000623c:	fffff097          	auipc	ra,0xfffff
    80006240:	a08080e7          	jalr	-1528(ra) # 80004c44 <fileclose>
    fileclose(wf);
    80006244:	fc843503          	ld	a0,-56(s0)
    80006248:	fffff097          	auipc	ra,0xfffff
    8000624c:	9fc080e7          	jalr	-1540(ra) # 80004c44 <fileclose>
    return -1;
    80006250:	57fd                	li	a5,-1
    80006252:	a03d                	j	80006280 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80006254:	fc442783          	lw	a5,-60(s0)
    80006258:	0007c763          	bltz	a5,80006266 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    8000625c:	07e9                	addi	a5,a5,26
    8000625e:	078e                	slli	a5,a5,0x3
    80006260:	94be                	add	s1,s1,a5
    80006262:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80006266:	fd043503          	ld	a0,-48(s0)
    8000626a:	fffff097          	auipc	ra,0xfffff
    8000626e:	9da080e7          	jalr	-1574(ra) # 80004c44 <fileclose>
    fileclose(wf);
    80006272:	fc843503          	ld	a0,-56(s0)
    80006276:	fffff097          	auipc	ra,0xfffff
    8000627a:	9ce080e7          	jalr	-1586(ra) # 80004c44 <fileclose>
    return -1;
    8000627e:	57fd                	li	a5,-1
}
    80006280:	853e                	mv	a0,a5
    80006282:	70e2                	ld	ra,56(sp)
    80006284:	7442                	ld	s0,48(sp)
    80006286:	74a2                	ld	s1,40(sp)
    80006288:	6121                	addi	sp,sp,64
    8000628a:	8082                	ret
    8000628c:	0000                	unimp
	...

0000000080006290 <kernelvec>:
    80006290:	7111                	addi	sp,sp,-256
    80006292:	e006                	sd	ra,0(sp)
    80006294:	e40a                	sd	sp,8(sp)
    80006296:	e80e                	sd	gp,16(sp)
    80006298:	ec12                	sd	tp,24(sp)
    8000629a:	f016                	sd	t0,32(sp)
    8000629c:	f41a                	sd	t1,40(sp)
    8000629e:	f81e                	sd	t2,48(sp)
    800062a0:	fc22                	sd	s0,56(sp)
    800062a2:	e0a6                	sd	s1,64(sp)
    800062a4:	e4aa                	sd	a0,72(sp)
    800062a6:	e8ae                	sd	a1,80(sp)
    800062a8:	ecb2                	sd	a2,88(sp)
    800062aa:	f0b6                	sd	a3,96(sp)
    800062ac:	f4ba                	sd	a4,104(sp)
    800062ae:	f8be                	sd	a5,112(sp)
    800062b0:	fcc2                	sd	a6,120(sp)
    800062b2:	e146                	sd	a7,128(sp)
    800062b4:	e54a                	sd	s2,136(sp)
    800062b6:	e94e                	sd	s3,144(sp)
    800062b8:	ed52                	sd	s4,152(sp)
    800062ba:	f156                	sd	s5,160(sp)
    800062bc:	f55a                	sd	s6,168(sp)
    800062be:	f95e                	sd	s7,176(sp)
    800062c0:	fd62                	sd	s8,184(sp)
    800062c2:	e1e6                	sd	s9,192(sp)
    800062c4:	e5ea                	sd	s10,200(sp)
    800062c6:	e9ee                	sd	s11,208(sp)
    800062c8:	edf2                	sd	t3,216(sp)
    800062ca:	f1f6                	sd	t4,224(sp)
    800062cc:	f5fa                	sd	t5,232(sp)
    800062ce:	f9fe                	sd	t6,240(sp)
    800062d0:	ba3fc0ef          	jal	ra,80002e72 <kerneltrap>
    800062d4:	6082                	ld	ra,0(sp)
    800062d6:	6122                	ld	sp,8(sp)
    800062d8:	61c2                	ld	gp,16(sp)
    800062da:	7282                	ld	t0,32(sp)
    800062dc:	7322                	ld	t1,40(sp)
    800062de:	73c2                	ld	t2,48(sp)
    800062e0:	7462                	ld	s0,56(sp)
    800062e2:	6486                	ld	s1,64(sp)
    800062e4:	6526                	ld	a0,72(sp)
    800062e6:	65c6                	ld	a1,80(sp)
    800062e8:	6666                	ld	a2,88(sp)
    800062ea:	7686                	ld	a3,96(sp)
    800062ec:	7726                	ld	a4,104(sp)
    800062ee:	77c6                	ld	a5,112(sp)
    800062f0:	7866                	ld	a6,120(sp)
    800062f2:	688a                	ld	a7,128(sp)
    800062f4:	692a                	ld	s2,136(sp)
    800062f6:	69ca                	ld	s3,144(sp)
    800062f8:	6a6a                	ld	s4,152(sp)
    800062fa:	7a8a                	ld	s5,160(sp)
    800062fc:	7b2a                	ld	s6,168(sp)
    800062fe:	7bca                	ld	s7,176(sp)
    80006300:	7c6a                	ld	s8,184(sp)
    80006302:	6c8e                	ld	s9,192(sp)
    80006304:	6d2e                	ld	s10,200(sp)
    80006306:	6dce                	ld	s11,208(sp)
    80006308:	6e6e                	ld	t3,216(sp)
    8000630a:	7e8e                	ld	t4,224(sp)
    8000630c:	7f2e                	ld	t5,232(sp)
    8000630e:	7fce                	ld	t6,240(sp)
    80006310:	6111                	addi	sp,sp,256
    80006312:	10200073          	sret
    80006316:	00000013          	nop
    8000631a:	00000013          	nop
    8000631e:	0001                	nop

0000000080006320 <timervec>:
    80006320:	34051573          	csrrw	a0,mscratch,a0
    80006324:	e10c                	sd	a1,0(a0)
    80006326:	e510                	sd	a2,8(a0)
    80006328:	e914                	sd	a3,16(a0)
    8000632a:	6d0c                	ld	a1,24(a0)
    8000632c:	7110                	ld	a2,32(a0)
    8000632e:	6194                	ld	a3,0(a1)
    80006330:	96b2                	add	a3,a3,a2
    80006332:	e194                	sd	a3,0(a1)
    80006334:	4589                	li	a1,2
    80006336:	14459073          	csrw	sip,a1
    8000633a:	6914                	ld	a3,16(a0)
    8000633c:	6510                	ld	a2,8(a0)
    8000633e:	610c                	ld	a1,0(a0)
    80006340:	34051573          	csrrw	a0,mscratch,a0
    80006344:	30200073          	mret
	...

000000008000634a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000634a:	1141                	addi	sp,sp,-16
    8000634c:	e422                	sd	s0,8(sp)
    8000634e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006350:	0c0007b7          	lui	a5,0xc000
    80006354:	4705                	li	a4,1
    80006356:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006358:	c3d8                	sw	a4,4(a5)
}
    8000635a:	6422                	ld	s0,8(sp)
    8000635c:	0141                	addi	sp,sp,16
    8000635e:	8082                	ret

0000000080006360 <plicinithart>:

void
plicinithart(void)
{
    80006360:	1141                	addi	sp,sp,-16
    80006362:	e406                	sd	ra,8(sp)
    80006364:	e022                	sd	s0,0(sp)
    80006366:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006368:	ffffb097          	auipc	ra,0xffffb
    8000636c:	77e080e7          	jalr	1918(ra) # 80001ae6 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006370:	0085171b          	slliw	a4,a0,0x8
    80006374:	0c0027b7          	lui	a5,0xc002
    80006378:	97ba                	add	a5,a5,a4
    8000637a:	40200713          	li	a4,1026
    8000637e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006382:	00d5151b          	slliw	a0,a0,0xd
    80006386:	0c2017b7          	lui	a5,0xc201
    8000638a:	953e                	add	a0,a0,a5
    8000638c:	00052023          	sw	zero,0(a0)
}
    80006390:	60a2                	ld	ra,8(sp)
    80006392:	6402                	ld	s0,0(sp)
    80006394:	0141                	addi	sp,sp,16
    80006396:	8082                	ret

0000000080006398 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006398:	1141                	addi	sp,sp,-16
    8000639a:	e406                	sd	ra,8(sp)
    8000639c:	e022                	sd	s0,0(sp)
    8000639e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800063a0:	ffffb097          	auipc	ra,0xffffb
    800063a4:	746080e7          	jalr	1862(ra) # 80001ae6 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800063a8:	00d5179b          	slliw	a5,a0,0xd
    800063ac:	0c201537          	lui	a0,0xc201
    800063b0:	953e                	add	a0,a0,a5
  return irq;
}
    800063b2:	4148                	lw	a0,4(a0)
    800063b4:	60a2                	ld	ra,8(sp)
    800063b6:	6402                	ld	s0,0(sp)
    800063b8:	0141                	addi	sp,sp,16
    800063ba:	8082                	ret

00000000800063bc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800063bc:	1101                	addi	sp,sp,-32
    800063be:	ec06                	sd	ra,24(sp)
    800063c0:	e822                	sd	s0,16(sp)
    800063c2:	e426                	sd	s1,8(sp)
    800063c4:	1000                	addi	s0,sp,32
    800063c6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800063c8:	ffffb097          	auipc	ra,0xffffb
    800063cc:	71e080e7          	jalr	1822(ra) # 80001ae6 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800063d0:	00d5151b          	slliw	a0,a0,0xd
    800063d4:	0c2017b7          	lui	a5,0xc201
    800063d8:	97aa                	add	a5,a5,a0
    800063da:	c3c4                	sw	s1,4(a5)
}
    800063dc:	60e2                	ld	ra,24(sp)
    800063de:	6442                	ld	s0,16(sp)
    800063e0:	64a2                	ld	s1,8(sp)
    800063e2:	6105                	addi	sp,sp,32
    800063e4:	8082                	ret

00000000800063e6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800063e6:	1141                	addi	sp,sp,-16
    800063e8:	e406                	sd	ra,8(sp)
    800063ea:	e022                	sd	s0,0(sp)
    800063ec:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800063ee:	479d                	li	a5,7
    800063f0:	04a7cc63          	blt	a5,a0,80006448 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    800063f4:	0001f797          	auipc	a5,0x1f
    800063f8:	c6c78793          	addi	a5,a5,-916 # 80025060 <disk>
    800063fc:	97aa                	add	a5,a5,a0
    800063fe:	0187c783          	lbu	a5,24(a5)
    80006402:	ebb9                	bnez	a5,80006458 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006404:	00451613          	slli	a2,a0,0x4
    80006408:	0001f797          	auipc	a5,0x1f
    8000640c:	c5878793          	addi	a5,a5,-936 # 80025060 <disk>
    80006410:	6394                	ld	a3,0(a5)
    80006412:	96b2                	add	a3,a3,a2
    80006414:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80006418:	6398                	ld	a4,0(a5)
    8000641a:	9732                	add	a4,a4,a2
    8000641c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80006420:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80006424:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80006428:	953e                	add	a0,a0,a5
    8000642a:	4785                	li	a5,1
    8000642c:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    80006430:	0001f517          	auipc	a0,0x1f
    80006434:	c4850513          	addi	a0,a0,-952 # 80025078 <disk+0x18>
    80006438:	ffffc097          	auipc	ra,0xffffc
    8000643c:	fae080e7          	jalr	-82(ra) # 800023e6 <wakeup>
}
    80006440:	60a2                	ld	ra,8(sp)
    80006442:	6402                	ld	s0,0(sp)
    80006444:	0141                	addi	sp,sp,16
    80006446:	8082                	ret
    panic("free_desc 1");
    80006448:	00002517          	auipc	a0,0x2
    8000644c:	33050513          	addi	a0,a0,816 # 80008778 <syscalls+0x318>
    80006450:	ffffa097          	auipc	ra,0xffffa
    80006454:	0ee080e7          	jalr	238(ra) # 8000053e <panic>
    panic("free_desc 2");
    80006458:	00002517          	auipc	a0,0x2
    8000645c:	33050513          	addi	a0,a0,816 # 80008788 <syscalls+0x328>
    80006460:	ffffa097          	auipc	ra,0xffffa
    80006464:	0de080e7          	jalr	222(ra) # 8000053e <panic>

0000000080006468 <virtio_disk_init>:
{
    80006468:	1101                	addi	sp,sp,-32
    8000646a:	ec06                	sd	ra,24(sp)
    8000646c:	e822                	sd	s0,16(sp)
    8000646e:	e426                	sd	s1,8(sp)
    80006470:	e04a                	sd	s2,0(sp)
    80006472:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006474:	00002597          	auipc	a1,0x2
    80006478:	32458593          	addi	a1,a1,804 # 80008798 <syscalls+0x338>
    8000647c:	0001f517          	auipc	a0,0x1f
    80006480:	d0c50513          	addi	a0,a0,-756 # 80025188 <disk+0x128>
    80006484:	ffffa097          	auipc	ra,0xffffa
    80006488:	6c2080e7          	jalr	1730(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000648c:	100017b7          	lui	a5,0x10001
    80006490:	4398                	lw	a4,0(a5)
    80006492:	2701                	sext.w	a4,a4
    80006494:	747277b7          	lui	a5,0x74727
    80006498:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000649c:	14f71c63          	bne	a4,a5,800065f4 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800064a0:	100017b7          	lui	a5,0x10001
    800064a4:	43dc                	lw	a5,4(a5)
    800064a6:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800064a8:	4709                	li	a4,2
    800064aa:	14e79563          	bne	a5,a4,800065f4 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800064ae:	100017b7          	lui	a5,0x10001
    800064b2:	479c                	lw	a5,8(a5)
    800064b4:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800064b6:	12e79f63          	bne	a5,a4,800065f4 <virtio_disk_init+0x18c>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800064ba:	100017b7          	lui	a5,0x10001
    800064be:	47d8                	lw	a4,12(a5)
    800064c0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800064c2:	554d47b7          	lui	a5,0x554d4
    800064c6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800064ca:	12f71563          	bne	a4,a5,800065f4 <virtio_disk_init+0x18c>
  *R(VIRTIO_MMIO_STATUS) = status;
    800064ce:	100017b7          	lui	a5,0x10001
    800064d2:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    800064d6:	4705                	li	a4,1
    800064d8:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800064da:	470d                	li	a4,3
    800064dc:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800064de:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800064e0:	c7ffe737          	lui	a4,0xc7ffe
    800064e4:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd95bf>
    800064e8:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800064ea:	2701                	sext.w	a4,a4
    800064ec:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800064ee:	472d                	li	a4,11
    800064f0:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    800064f2:	5bbc                	lw	a5,112(a5)
    800064f4:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    800064f8:	8ba1                	andi	a5,a5,8
    800064fa:	10078563          	beqz	a5,80006604 <virtio_disk_init+0x19c>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800064fe:	100017b7          	lui	a5,0x10001
    80006502:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006506:	43fc                	lw	a5,68(a5)
    80006508:	2781                	sext.w	a5,a5
    8000650a:	10079563          	bnez	a5,80006614 <virtio_disk_init+0x1ac>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000650e:	100017b7          	lui	a5,0x10001
    80006512:	5bdc                	lw	a5,52(a5)
    80006514:	2781                	sext.w	a5,a5
  if(max == 0)
    80006516:	10078763          	beqz	a5,80006624 <virtio_disk_init+0x1bc>
  if(max < NUM)
    8000651a:	471d                	li	a4,7
    8000651c:	10f77c63          	bgeu	a4,a5,80006634 <virtio_disk_init+0x1cc>
  disk.desc = kalloc();
    80006520:	ffffa097          	auipc	ra,0xffffa
    80006524:	5c6080e7          	jalr	1478(ra) # 80000ae6 <kalloc>
    80006528:	0001f497          	auipc	s1,0x1f
    8000652c:	b3848493          	addi	s1,s1,-1224 # 80025060 <disk>
    80006530:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006532:	ffffa097          	auipc	ra,0xffffa
    80006536:	5b4080e7          	jalr	1460(ra) # 80000ae6 <kalloc>
    8000653a:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000653c:	ffffa097          	auipc	ra,0xffffa
    80006540:	5aa080e7          	jalr	1450(ra) # 80000ae6 <kalloc>
    80006544:	87aa                	mv	a5,a0
    80006546:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006548:	6088                	ld	a0,0(s1)
    8000654a:	cd6d                	beqz	a0,80006644 <virtio_disk_init+0x1dc>
    8000654c:	0001f717          	auipc	a4,0x1f
    80006550:	b1c73703          	ld	a4,-1252(a4) # 80025068 <disk+0x8>
    80006554:	cb65                	beqz	a4,80006644 <virtio_disk_init+0x1dc>
    80006556:	c7fd                	beqz	a5,80006644 <virtio_disk_init+0x1dc>
  memset(disk.desc, 0, PGSIZE);
    80006558:	6605                	lui	a2,0x1
    8000655a:	4581                	li	a1,0
    8000655c:	ffffa097          	auipc	ra,0xffffa
    80006560:	776080e7          	jalr	1910(ra) # 80000cd2 <memset>
  memset(disk.avail, 0, PGSIZE);
    80006564:	0001f497          	auipc	s1,0x1f
    80006568:	afc48493          	addi	s1,s1,-1284 # 80025060 <disk>
    8000656c:	6605                	lui	a2,0x1
    8000656e:	4581                	li	a1,0
    80006570:	6488                	ld	a0,8(s1)
    80006572:	ffffa097          	auipc	ra,0xffffa
    80006576:	760080e7          	jalr	1888(ra) # 80000cd2 <memset>
  memset(disk.used, 0, PGSIZE);
    8000657a:	6605                	lui	a2,0x1
    8000657c:	4581                	li	a1,0
    8000657e:	6888                	ld	a0,16(s1)
    80006580:	ffffa097          	auipc	ra,0xffffa
    80006584:	752080e7          	jalr	1874(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006588:	100017b7          	lui	a5,0x10001
    8000658c:	4721                	li	a4,8
    8000658e:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80006590:	4098                	lw	a4,0(s1)
    80006592:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006596:	40d8                	lw	a4,4(s1)
    80006598:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000659c:	6498                	ld	a4,8(s1)
    8000659e:	0007069b          	sext.w	a3,a4
    800065a2:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    800065a6:	9701                	srai	a4,a4,0x20
    800065a8:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    800065ac:	6898                	ld	a4,16(s1)
    800065ae:	0007069b          	sext.w	a3,a4
    800065b2:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    800065b6:	9701                	srai	a4,a4,0x20
    800065b8:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    800065bc:	4705                	li	a4,1
    800065be:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    800065c0:	00e48c23          	sb	a4,24(s1)
    800065c4:	00e48ca3          	sb	a4,25(s1)
    800065c8:	00e48d23          	sb	a4,26(s1)
    800065cc:	00e48da3          	sb	a4,27(s1)
    800065d0:	00e48e23          	sb	a4,28(s1)
    800065d4:	00e48ea3          	sb	a4,29(s1)
    800065d8:	00e48f23          	sb	a4,30(s1)
    800065dc:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    800065e0:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    800065e4:	0727a823          	sw	s2,112(a5)
}
    800065e8:	60e2                	ld	ra,24(sp)
    800065ea:	6442                	ld	s0,16(sp)
    800065ec:	64a2                	ld	s1,8(sp)
    800065ee:	6902                	ld	s2,0(sp)
    800065f0:	6105                	addi	sp,sp,32
    800065f2:	8082                	ret
    panic("could not find virtio disk");
    800065f4:	00002517          	auipc	a0,0x2
    800065f8:	1b450513          	addi	a0,a0,436 # 800087a8 <syscalls+0x348>
    800065fc:	ffffa097          	auipc	ra,0xffffa
    80006600:	f42080e7          	jalr	-190(ra) # 8000053e <panic>
    panic("virtio disk FEATURES_OK unset");
    80006604:	00002517          	auipc	a0,0x2
    80006608:	1c450513          	addi	a0,a0,452 # 800087c8 <syscalls+0x368>
    8000660c:	ffffa097          	auipc	ra,0xffffa
    80006610:	f32080e7          	jalr	-206(ra) # 8000053e <panic>
    panic("virtio disk should not be ready");
    80006614:	00002517          	auipc	a0,0x2
    80006618:	1d450513          	addi	a0,a0,468 # 800087e8 <syscalls+0x388>
    8000661c:	ffffa097          	auipc	ra,0xffffa
    80006620:	f22080e7          	jalr	-222(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006624:	00002517          	auipc	a0,0x2
    80006628:	1e450513          	addi	a0,a0,484 # 80008808 <syscalls+0x3a8>
    8000662c:	ffffa097          	auipc	ra,0xffffa
    80006630:	f12080e7          	jalr	-238(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006634:	00002517          	auipc	a0,0x2
    80006638:	1f450513          	addi	a0,a0,500 # 80008828 <syscalls+0x3c8>
    8000663c:	ffffa097          	auipc	ra,0xffffa
    80006640:	f02080e7          	jalr	-254(ra) # 8000053e <panic>
    panic("virtio disk kalloc");
    80006644:	00002517          	auipc	a0,0x2
    80006648:	20450513          	addi	a0,a0,516 # 80008848 <syscalls+0x3e8>
    8000664c:	ffffa097          	auipc	ra,0xffffa
    80006650:	ef2080e7          	jalr	-270(ra) # 8000053e <panic>

0000000080006654 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006654:	7119                	addi	sp,sp,-128
    80006656:	fc86                	sd	ra,120(sp)
    80006658:	f8a2                	sd	s0,112(sp)
    8000665a:	f4a6                	sd	s1,104(sp)
    8000665c:	f0ca                	sd	s2,96(sp)
    8000665e:	ecce                	sd	s3,88(sp)
    80006660:	e8d2                	sd	s4,80(sp)
    80006662:	e4d6                	sd	s5,72(sp)
    80006664:	e0da                	sd	s6,64(sp)
    80006666:	fc5e                	sd	s7,56(sp)
    80006668:	f862                	sd	s8,48(sp)
    8000666a:	f466                	sd	s9,40(sp)
    8000666c:	f06a                	sd	s10,32(sp)
    8000666e:	ec6e                	sd	s11,24(sp)
    80006670:	0100                	addi	s0,sp,128
    80006672:	8aaa                	mv	s5,a0
    80006674:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006676:	00c52d03          	lw	s10,12(a0)
    8000667a:	001d1d1b          	slliw	s10,s10,0x1
    8000667e:	1d02                	slli	s10,s10,0x20
    80006680:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    80006684:	0001f517          	auipc	a0,0x1f
    80006688:	b0450513          	addi	a0,a0,-1276 # 80025188 <disk+0x128>
    8000668c:	ffffa097          	auipc	ra,0xffffa
    80006690:	54a080e7          	jalr	1354(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    80006694:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006696:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006698:	0001fb97          	auipc	s7,0x1f
    8000669c:	9c8b8b93          	addi	s7,s7,-1592 # 80025060 <disk>
  for(int i = 0; i < 3; i++){
    800066a0:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800066a2:	0001fc97          	auipc	s9,0x1f
    800066a6:	ae6c8c93          	addi	s9,s9,-1306 # 80025188 <disk+0x128>
    800066aa:	a08d                	j	8000670c <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    800066ac:	00fb8733          	add	a4,s7,a5
    800066b0:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    800066b4:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    800066b6:	0207c563          	bltz	a5,800066e0 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    800066ba:	2905                	addiw	s2,s2,1
    800066bc:	0611                	addi	a2,a2,4
    800066be:	05690c63          	beq	s2,s6,80006716 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    800066c2:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    800066c4:	0001f717          	auipc	a4,0x1f
    800066c8:	99c70713          	addi	a4,a4,-1636 # 80025060 <disk>
    800066cc:	87ce                	mv	a5,s3
    if(disk.free[i]){
    800066ce:	01874683          	lbu	a3,24(a4)
    800066d2:	fee9                	bnez	a3,800066ac <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    800066d4:	2785                	addiw	a5,a5,1
    800066d6:	0705                	addi	a4,a4,1
    800066d8:	fe979be3          	bne	a5,s1,800066ce <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    800066dc:	57fd                	li	a5,-1
    800066de:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    800066e0:	01205d63          	blez	s2,800066fa <virtio_disk_rw+0xa6>
    800066e4:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    800066e6:	000a2503          	lw	a0,0(s4)
    800066ea:	00000097          	auipc	ra,0x0
    800066ee:	cfc080e7          	jalr	-772(ra) # 800063e6 <free_desc>
      for(int j = 0; j < i; j++)
    800066f2:	2d85                	addiw	s11,s11,1
    800066f4:	0a11                	addi	s4,s4,4
    800066f6:	ffb918e3          	bne	s2,s11,800066e6 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    800066fa:	85e6                	mv	a1,s9
    800066fc:	0001f517          	auipc	a0,0x1f
    80006700:	97c50513          	addi	a0,a0,-1668 # 80025078 <disk+0x18>
    80006704:	ffffc097          	auipc	ra,0xffffc
    80006708:	c7e080e7          	jalr	-898(ra) # 80002382 <sleep>
  for(int i = 0; i < 3; i++){
    8000670c:	f8040a13          	addi	s4,s0,-128
{
    80006710:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006712:	894e                	mv	s2,s3
    80006714:	b77d                	j	800066c2 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006716:	f8042583          	lw	a1,-128(s0)
    8000671a:	00a58793          	addi	a5,a1,10
    8000671e:	0792                	slli	a5,a5,0x4

  if(write)
    80006720:	0001f617          	auipc	a2,0x1f
    80006724:	94060613          	addi	a2,a2,-1728 # 80025060 <disk>
    80006728:	00f60733          	add	a4,a2,a5
    8000672c:	018036b3          	snez	a3,s8
    80006730:	c714                	sw	a3,8(a4)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006732:	00072623          	sw	zero,12(a4)
  buf0->sector = sector;
    80006736:	01a73823          	sd	s10,16(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    8000673a:	f6078693          	addi	a3,a5,-160
    8000673e:	6218                	ld	a4,0(a2)
    80006740:	9736                	add	a4,a4,a3
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006742:	00878513          	addi	a0,a5,8
    80006746:	9532                	add	a0,a0,a2
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006748:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    8000674a:	6208                	ld	a0,0(a2)
    8000674c:	96aa                	add	a3,a3,a0
    8000674e:	4741                	li	a4,16
    80006750:	c698                	sw	a4,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006752:	4705                	li	a4,1
    80006754:	00e69623          	sh	a4,12(a3)
  disk.desc[idx[0]].next = idx[1];
    80006758:	f8442703          	lw	a4,-124(s0)
    8000675c:	00e69723          	sh	a4,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006760:	0712                	slli	a4,a4,0x4
    80006762:	953a                	add	a0,a0,a4
    80006764:	058a8693          	addi	a3,s5,88
    80006768:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    8000676a:	6208                	ld	a0,0(a2)
    8000676c:	972a                	add	a4,a4,a0
    8000676e:	40000693          	li	a3,1024
    80006772:	c714                	sw	a3,8(a4)
  if(write)
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006774:	001c3c13          	seqz	s8,s8
    80006778:	0c06                	slli	s8,s8,0x1
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000677a:	001c6c13          	ori	s8,s8,1
    8000677e:	01871623          	sh	s8,12(a4)
  disk.desc[idx[1]].next = idx[2];
    80006782:	f8842603          	lw	a2,-120(s0)
    80006786:	00c71723          	sh	a2,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    8000678a:	0001f697          	auipc	a3,0x1f
    8000678e:	8d668693          	addi	a3,a3,-1834 # 80025060 <disk>
    80006792:	00258713          	addi	a4,a1,2
    80006796:	0712                	slli	a4,a4,0x4
    80006798:	9736                	add	a4,a4,a3
    8000679a:	587d                	li	a6,-1
    8000679c:	01070823          	sb	a6,16(a4)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800067a0:	0612                	slli	a2,a2,0x4
    800067a2:	9532                	add	a0,a0,a2
    800067a4:	f9078793          	addi	a5,a5,-112
    800067a8:	97b6                	add	a5,a5,a3
    800067aa:	e11c                	sd	a5,0(a0)
  disk.desc[idx[2]].len = 1;
    800067ac:	629c                	ld	a5,0(a3)
    800067ae:	97b2                	add	a5,a5,a2
    800067b0:	4605                	li	a2,1
    800067b2:	c790                	sw	a2,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800067b4:	4509                	li	a0,2
    800067b6:	00a79623          	sh	a0,12(a5)
  disk.desc[idx[2]].next = 0;
    800067ba:	00079723          	sh	zero,14(a5)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800067be:	00caa223          	sw	a2,4(s5)
  disk.info[idx[0]].b = b;
    800067c2:	01573423          	sd	s5,8(a4)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800067c6:	6698                	ld	a4,8(a3)
    800067c8:	00275783          	lhu	a5,2(a4)
    800067cc:	8b9d                	andi	a5,a5,7
    800067ce:	0786                	slli	a5,a5,0x1
    800067d0:	97ba                	add	a5,a5,a4
    800067d2:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    800067d6:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800067da:	6698                	ld	a4,8(a3)
    800067dc:	00275783          	lhu	a5,2(a4)
    800067e0:	2785                	addiw	a5,a5,1
    800067e2:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800067e6:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800067ea:	100017b7          	lui	a5,0x10001
    800067ee:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800067f2:	004aa783          	lw	a5,4(s5)
    800067f6:	02c79163          	bne	a5,a2,80006818 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    800067fa:	0001f917          	auipc	s2,0x1f
    800067fe:	98e90913          	addi	s2,s2,-1650 # 80025188 <disk+0x128>
  while(b->disk == 1) {
    80006802:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006804:	85ca                	mv	a1,s2
    80006806:	8556                	mv	a0,s5
    80006808:	ffffc097          	auipc	ra,0xffffc
    8000680c:	b7a080e7          	jalr	-1158(ra) # 80002382 <sleep>
  while(b->disk == 1) {
    80006810:	004aa783          	lw	a5,4(s5)
    80006814:	fe9788e3          	beq	a5,s1,80006804 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006818:	f8042903          	lw	s2,-128(s0)
    8000681c:	00290793          	addi	a5,s2,2
    80006820:	00479713          	slli	a4,a5,0x4
    80006824:	0001f797          	auipc	a5,0x1f
    80006828:	83c78793          	addi	a5,a5,-1988 # 80025060 <disk>
    8000682c:	97ba                	add	a5,a5,a4
    8000682e:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    80006832:	0001f997          	auipc	s3,0x1f
    80006836:	82e98993          	addi	s3,s3,-2002 # 80025060 <disk>
    8000683a:	00491713          	slli	a4,s2,0x4
    8000683e:	0009b783          	ld	a5,0(s3)
    80006842:	97ba                	add	a5,a5,a4
    80006844:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006848:	854a                	mv	a0,s2
    8000684a:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000684e:	00000097          	auipc	ra,0x0
    80006852:	b98080e7          	jalr	-1128(ra) # 800063e6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006856:	8885                	andi	s1,s1,1
    80006858:	f0ed                	bnez	s1,8000683a <virtio_disk_rw+0x1e6>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000685a:	0001f517          	auipc	a0,0x1f
    8000685e:	92e50513          	addi	a0,a0,-1746 # 80025188 <disk+0x128>
    80006862:	ffffa097          	auipc	ra,0xffffa
    80006866:	428080e7          	jalr	1064(ra) # 80000c8a <release>
}
    8000686a:	70e6                	ld	ra,120(sp)
    8000686c:	7446                	ld	s0,112(sp)
    8000686e:	74a6                	ld	s1,104(sp)
    80006870:	7906                	ld	s2,96(sp)
    80006872:	69e6                	ld	s3,88(sp)
    80006874:	6a46                	ld	s4,80(sp)
    80006876:	6aa6                	ld	s5,72(sp)
    80006878:	6b06                	ld	s6,64(sp)
    8000687a:	7be2                	ld	s7,56(sp)
    8000687c:	7c42                	ld	s8,48(sp)
    8000687e:	7ca2                	ld	s9,40(sp)
    80006880:	7d02                	ld	s10,32(sp)
    80006882:	6de2                	ld	s11,24(sp)
    80006884:	6109                	addi	sp,sp,128
    80006886:	8082                	ret

0000000080006888 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006888:	1101                	addi	sp,sp,-32
    8000688a:	ec06                	sd	ra,24(sp)
    8000688c:	e822                	sd	s0,16(sp)
    8000688e:	e426                	sd	s1,8(sp)
    80006890:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006892:	0001e497          	auipc	s1,0x1e
    80006896:	7ce48493          	addi	s1,s1,1998 # 80025060 <disk>
    8000689a:	0001f517          	auipc	a0,0x1f
    8000689e:	8ee50513          	addi	a0,a0,-1810 # 80025188 <disk+0x128>
    800068a2:	ffffa097          	auipc	ra,0xffffa
    800068a6:	334080e7          	jalr	820(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800068aa:	10001737          	lui	a4,0x10001
    800068ae:	533c                	lw	a5,96(a4)
    800068b0:	8b8d                	andi	a5,a5,3
    800068b2:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800068b4:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800068b8:	689c                	ld	a5,16(s1)
    800068ba:	0204d703          	lhu	a4,32(s1)
    800068be:	0027d783          	lhu	a5,2(a5)
    800068c2:	04f70863          	beq	a4,a5,80006912 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    800068c6:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800068ca:	6898                	ld	a4,16(s1)
    800068cc:	0204d783          	lhu	a5,32(s1)
    800068d0:	8b9d                	andi	a5,a5,7
    800068d2:	078e                	slli	a5,a5,0x3
    800068d4:	97ba                	add	a5,a5,a4
    800068d6:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800068d8:	00278713          	addi	a4,a5,2
    800068dc:	0712                	slli	a4,a4,0x4
    800068de:	9726                	add	a4,a4,s1
    800068e0:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    800068e4:	e721                	bnez	a4,8000692c <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800068e6:	0789                	addi	a5,a5,2
    800068e8:	0792                	slli	a5,a5,0x4
    800068ea:	97a6                	add	a5,a5,s1
    800068ec:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    800068ee:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800068f2:	ffffc097          	auipc	ra,0xffffc
    800068f6:	af4080e7          	jalr	-1292(ra) # 800023e6 <wakeup>

    disk.used_idx += 1;
    800068fa:	0204d783          	lhu	a5,32(s1)
    800068fe:	2785                	addiw	a5,a5,1
    80006900:	17c2                	slli	a5,a5,0x30
    80006902:	93c1                	srli	a5,a5,0x30
    80006904:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006908:	6898                	ld	a4,16(s1)
    8000690a:	00275703          	lhu	a4,2(a4)
    8000690e:	faf71ce3          	bne	a4,a5,800068c6 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80006912:	0001f517          	auipc	a0,0x1f
    80006916:	87650513          	addi	a0,a0,-1930 # 80025188 <disk+0x128>
    8000691a:	ffffa097          	auipc	ra,0xffffa
    8000691e:	370080e7          	jalr	880(ra) # 80000c8a <release>
}
    80006922:	60e2                	ld	ra,24(sp)
    80006924:	6442                	ld	s0,16(sp)
    80006926:	64a2                	ld	s1,8(sp)
    80006928:	6105                	addi	sp,sp,32
    8000692a:	8082                	ret
      panic("virtio_disk_intr status");
    8000692c:	00002517          	auipc	a0,0x2
    80006930:	f3450513          	addi	a0,a0,-204 # 80008860 <syscalls+0x400>
    80006934:	ffffa097          	auipc	ra,0xffffa
    80006938:	c0a080e7          	jalr	-1014(ra) # 8000053e <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
