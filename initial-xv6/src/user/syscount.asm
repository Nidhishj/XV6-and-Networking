
user/_syscount:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:
#include "kernel/stat.h"
#include "user/user.h"


int main(int argc, char *argv[])
{
   0:	7115                	addi	sp,sp,-224
   2:	ed86                	sd	ra,216(sp)
   4:	e9a2                	sd	s0,208(sp)
   6:	e5a6                	sd	s1,200(sp)
   8:	e1ca                	sd	s2,192(sp)
   a:	1180                	addi	s0,sp,224
   c:	892e                	mv	s2,a1
    char *syscalls[] = {
   e:	00001797          	auipc	a5,0x1
  12:	9e278793          	addi	a5,a5,-1566 # 9f0 <malloc+0x1e6>
  16:	f2840713          	addi	a4,s0,-216
  1a:	00001597          	auipc	a1,0x1
  1e:	a7658593          	addi	a1,a1,-1418 # a90 <malloc+0x286>
  22:	0007b883          	ld	a7,0(a5)
  26:	0087b803          	ld	a6,8(a5)
  2a:	6b90                	ld	a2,16(a5)
  2c:	6f94                	ld	a3,24(a5)
  2e:	01173023          	sd	a7,0(a4)
  32:	01073423          	sd	a6,8(a4)
  36:	eb10                	sd	a2,16(a4)
  38:	ef14                	sd	a3,24(a4)
  3a:	02078793          	addi	a5,a5,32
  3e:	02070713          	addi	a4,a4,32
  42:	feb790e3          	bne	a5,a1,22 <main+0x22>
  46:	6390                	ld	a2,0(a5)
  48:	6794                	ld	a3,8(a5)
  4a:	6b9c                	ld	a5,16(a5)
  4c:	e310                	sd	a2,0(a4)
  4e:	e714                	sd	a3,8(a4)
  50:	eb1c                	sd	a5,16(a4)
    "mkdir",
    "close",//20
    "waitx",
    "getSysCount"//22
    };
    if(argc<3)
  52:	4789                	li	a5,2
  54:	06a7dd63          	bge	a5,a0,ce <main+0xce>
    //     if(argv[i])
    //     printf("%s",argv[i]);
    //     else
    //     printf("NULL");
    // }
    int p  = fork();
  58:	00000097          	auipc	ra,0x0
  5c:	34c080e7          	jalr	844(ra) # 3a4 <fork>
  60:	84aa                	mv	s1,a0
    if(p<0)
  62:	08054063          	bltz	a0,e2 <main+0xe2>
    {
        printf("fork");
        return -1;
    }
    else if(p==0)
  66:	c941                	beqz	a0,f6 <main+0xf6>
     printf("Exec failed");
     exit(1);
    }
    else
    {
        wait(0);
  68:	4501                	li	a0,0
  6a:	00000097          	auipc	ra,0x0
  6e:	34a080e7          	jalr	842(ra) # 3b4 <wait>
        int l = atoi(argv[1]); 
  72:	00893503          	ld	a0,8(s2)
  76:	00000097          	auipc	ra,0x0
  7a:	23a080e7          	jalr	570(ra) # 2b0 <atoi>
        int k = -1 ;
        while (l)
  7e:	c14d                	beqz	a0,120 <main+0x120>
        int k = -1 ;
  80:	57fd                	li	a5,-1
        {
            l/=2;
  82:	01f5571b          	srliw	a4,a0,0x1f
  86:	9d39                	addw	a0,a0,a4
  88:	4015551b          	sraiw	a0,a0,0x1
            k++;
  8c:	2785                	addiw	a5,a5,1
        while (l)
  8e:	f975                	bnez	a0,82 <main+0x82>
        }   
        printf("PID %d called %s %d times.\n",p,syscalls[k-1],getSysCount(k-1));    
  90:	fff7851b          	addiw	a0,a5,-1
  94:	00351793          	slli	a5,a0,0x3
  98:	fe040713          	addi	a4,s0,-32
  9c:	97ba                	add	a5,a5,a4
  9e:	f487b903          	ld	s2,-184(a5)
  a2:	00000097          	auipc	ra,0x0
  a6:	3b2080e7          	jalr	946(ra) # 454 <getSysCount>
  aa:	86aa                	mv	a3,a0
  ac:	864a                	mv	a2,s2
  ae:	85a6                	mv	a1,s1
  b0:	00001517          	auipc	a0,0x1
  b4:	92050513          	addi	a0,a0,-1760 # 9d0 <malloc+0x1c6>
  b8:	00000097          	auipc	ra,0x0
  bc:	694080e7          	jalr	1684(ra) # 74c <printf>
    }
    return 0;
  c0:	4501                	li	a0,0
}
  c2:	60ee                	ld	ra,216(sp)
  c4:	644e                	ld	s0,208(sp)
  c6:	64ae                	ld	s1,200(sp)
  c8:	690e                	ld	s2,192(sp)
  ca:	612d                	addi	sp,sp,224
  cc:	8082                	ret
        printf("Invalid Format\n");
  ce:	00001517          	auipc	a0,0x1
  d2:	8e250513          	addi	a0,a0,-1822 # 9b0 <malloc+0x1a6>
  d6:	00000097          	auipc	ra,0x0
  da:	676080e7          	jalr	1654(ra) # 74c <printf>
        return -1;
  de:	557d                	li	a0,-1
  e0:	b7cd                	j	c2 <main+0xc2>
        printf("fork");
  e2:	00001517          	auipc	a0,0x1
  e6:	80e50513          	addi	a0,a0,-2034 # 8f0 <malloc+0xe6>
  ea:	00000097          	auipc	ra,0x0
  ee:	662080e7          	jalr	1634(ra) # 74c <printf>
        return -1;
  f2:	557d                	li	a0,-1
  f4:	b7f9                	j	c2 <main+0xc2>
     exec(argv[2],argv+2);
  f6:	01090593          	addi	a1,s2,16
  fa:	01093503          	ld	a0,16(s2)
  fe:	00000097          	auipc	ra,0x0
 102:	2e6080e7          	jalr	742(ra) # 3e4 <exec>
     printf("Exec failed");
 106:	00001517          	auipc	a0,0x1
 10a:	8ba50513          	addi	a0,a0,-1862 # 9c0 <malloc+0x1b6>
 10e:	00000097          	auipc	ra,0x0
 112:	63e080e7          	jalr	1598(ra) # 74c <printf>
     exit(1);
 116:	4505                	li	a0,1
 118:	00000097          	auipc	ra,0x0
 11c:	294080e7          	jalr	660(ra) # 3ac <exit>
        int k = -1 ;
 120:	57fd                	li	a5,-1
 122:	b7bd                	j	90 <main+0x90>

0000000000000124 <_main>:
//
// wrapper so that it's OK if main() does not call exit().
//
void
_main()
{
 124:	1141                	addi	sp,sp,-16
 126:	e406                	sd	ra,8(sp)
 128:	e022                	sd	s0,0(sp)
 12a:	0800                	addi	s0,sp,16
  extern int main();
  main();
 12c:	00000097          	auipc	ra,0x0
 130:	ed4080e7          	jalr	-300(ra) # 0 <main>
  exit(0);
 134:	4501                	li	a0,0
 136:	00000097          	auipc	ra,0x0
 13a:	276080e7          	jalr	630(ra) # 3ac <exit>

000000000000013e <strcpy>:
}

char*
strcpy(char *s, const char *t)
{
 13e:	1141                	addi	sp,sp,-16
 140:	e422                	sd	s0,8(sp)
 142:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 144:	87aa                	mv	a5,a0
 146:	0585                	addi	a1,a1,1
 148:	0785                	addi	a5,a5,1
 14a:	fff5c703          	lbu	a4,-1(a1)
 14e:	fee78fa3          	sb	a4,-1(a5)
 152:	fb75                	bnez	a4,146 <strcpy+0x8>
    ;
  return os;
}
 154:	6422                	ld	s0,8(sp)
 156:	0141                	addi	sp,sp,16
 158:	8082                	ret

000000000000015a <strcmp>:

int
strcmp(const char *p, const char *q)
{
 15a:	1141                	addi	sp,sp,-16
 15c:	e422                	sd	s0,8(sp)
 15e:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 160:	00054783          	lbu	a5,0(a0)
 164:	cb91                	beqz	a5,178 <strcmp+0x1e>
 166:	0005c703          	lbu	a4,0(a1)
 16a:	00f71763          	bne	a4,a5,178 <strcmp+0x1e>
    p++, q++;
 16e:	0505                	addi	a0,a0,1
 170:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 172:	00054783          	lbu	a5,0(a0)
 176:	fbe5                	bnez	a5,166 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 178:	0005c503          	lbu	a0,0(a1)
}
 17c:	40a7853b          	subw	a0,a5,a0
 180:	6422                	ld	s0,8(sp)
 182:	0141                	addi	sp,sp,16
 184:	8082                	ret

0000000000000186 <strlen>:

uint
strlen(const char *s)
{
 186:	1141                	addi	sp,sp,-16
 188:	e422                	sd	s0,8(sp)
 18a:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 18c:	00054783          	lbu	a5,0(a0)
 190:	cf91                	beqz	a5,1ac <strlen+0x26>
 192:	0505                	addi	a0,a0,1
 194:	87aa                	mv	a5,a0
 196:	4685                	li	a3,1
 198:	9e89                	subw	a3,a3,a0
 19a:	00f6853b          	addw	a0,a3,a5
 19e:	0785                	addi	a5,a5,1
 1a0:	fff7c703          	lbu	a4,-1(a5)
 1a4:	fb7d                	bnez	a4,19a <strlen+0x14>
    ;
  return n;
}
 1a6:	6422                	ld	s0,8(sp)
 1a8:	0141                	addi	sp,sp,16
 1aa:	8082                	ret
  for(n = 0; s[n]; n++)
 1ac:	4501                	li	a0,0
 1ae:	bfe5                	j	1a6 <strlen+0x20>

00000000000001b0 <memset>:

void*
memset(void *dst, int c, uint n)
{
 1b0:	1141                	addi	sp,sp,-16
 1b2:	e422                	sd	s0,8(sp)
 1b4:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 1b6:	ca19                	beqz	a2,1cc <memset+0x1c>
 1b8:	87aa                	mv	a5,a0
 1ba:	1602                	slli	a2,a2,0x20
 1bc:	9201                	srli	a2,a2,0x20
 1be:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 1c2:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 1c6:	0785                	addi	a5,a5,1
 1c8:	fee79de3          	bne	a5,a4,1c2 <memset+0x12>
  }
  return dst;
}
 1cc:	6422                	ld	s0,8(sp)
 1ce:	0141                	addi	sp,sp,16
 1d0:	8082                	ret

00000000000001d2 <strchr>:

char*
strchr(const char *s, char c)
{
 1d2:	1141                	addi	sp,sp,-16
 1d4:	e422                	sd	s0,8(sp)
 1d6:	0800                	addi	s0,sp,16
  for(; *s; s++)
 1d8:	00054783          	lbu	a5,0(a0)
 1dc:	cb99                	beqz	a5,1f2 <strchr+0x20>
    if(*s == c)
 1de:	00f58763          	beq	a1,a5,1ec <strchr+0x1a>
  for(; *s; s++)
 1e2:	0505                	addi	a0,a0,1
 1e4:	00054783          	lbu	a5,0(a0)
 1e8:	fbfd                	bnez	a5,1de <strchr+0xc>
      return (char*)s;
  return 0;
 1ea:	4501                	li	a0,0
}
 1ec:	6422                	ld	s0,8(sp)
 1ee:	0141                	addi	sp,sp,16
 1f0:	8082                	ret
  return 0;
 1f2:	4501                	li	a0,0
 1f4:	bfe5                	j	1ec <strchr+0x1a>

00000000000001f6 <gets>:

char*
gets(char *buf, int max)
{
 1f6:	711d                	addi	sp,sp,-96
 1f8:	ec86                	sd	ra,88(sp)
 1fa:	e8a2                	sd	s0,80(sp)
 1fc:	e4a6                	sd	s1,72(sp)
 1fe:	e0ca                	sd	s2,64(sp)
 200:	fc4e                	sd	s3,56(sp)
 202:	f852                	sd	s4,48(sp)
 204:	f456                	sd	s5,40(sp)
 206:	f05a                	sd	s6,32(sp)
 208:	ec5e                	sd	s7,24(sp)
 20a:	1080                	addi	s0,sp,96
 20c:	8baa                	mv	s7,a0
 20e:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 210:	892a                	mv	s2,a0
 212:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 214:	4aa9                	li	s5,10
 216:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 218:	89a6                	mv	s3,s1
 21a:	2485                	addiw	s1,s1,1
 21c:	0344d863          	bge	s1,s4,24c <gets+0x56>
    cc = read(0, &c, 1);
 220:	4605                	li	a2,1
 222:	faf40593          	addi	a1,s0,-81
 226:	4501                	li	a0,0
 228:	00000097          	auipc	ra,0x0
 22c:	19c080e7          	jalr	412(ra) # 3c4 <read>
    if(cc < 1)
 230:	00a05e63          	blez	a0,24c <gets+0x56>
    buf[i++] = c;
 234:	faf44783          	lbu	a5,-81(s0)
 238:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 23c:	01578763          	beq	a5,s5,24a <gets+0x54>
 240:	0905                	addi	s2,s2,1
 242:	fd679be3          	bne	a5,s6,218 <gets+0x22>
  for(i=0; i+1 < max; ){
 246:	89a6                	mv	s3,s1
 248:	a011                	j	24c <gets+0x56>
 24a:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 24c:	99de                	add	s3,s3,s7
 24e:	00098023          	sb	zero,0(s3)
  return buf;
}
 252:	855e                	mv	a0,s7
 254:	60e6                	ld	ra,88(sp)
 256:	6446                	ld	s0,80(sp)
 258:	64a6                	ld	s1,72(sp)
 25a:	6906                	ld	s2,64(sp)
 25c:	79e2                	ld	s3,56(sp)
 25e:	7a42                	ld	s4,48(sp)
 260:	7aa2                	ld	s5,40(sp)
 262:	7b02                	ld	s6,32(sp)
 264:	6be2                	ld	s7,24(sp)
 266:	6125                	addi	sp,sp,96
 268:	8082                	ret

000000000000026a <stat>:

int
stat(const char *n, struct stat *st)
{
 26a:	1101                	addi	sp,sp,-32
 26c:	ec06                	sd	ra,24(sp)
 26e:	e822                	sd	s0,16(sp)
 270:	e426                	sd	s1,8(sp)
 272:	e04a                	sd	s2,0(sp)
 274:	1000                	addi	s0,sp,32
 276:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 278:	4581                	li	a1,0
 27a:	00000097          	auipc	ra,0x0
 27e:	172080e7          	jalr	370(ra) # 3ec <open>
  if(fd < 0)
 282:	02054563          	bltz	a0,2ac <stat+0x42>
 286:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 288:	85ca                	mv	a1,s2
 28a:	00000097          	auipc	ra,0x0
 28e:	17a080e7          	jalr	378(ra) # 404 <fstat>
 292:	892a                	mv	s2,a0
  close(fd);
 294:	8526                	mv	a0,s1
 296:	00000097          	auipc	ra,0x0
 29a:	13e080e7          	jalr	318(ra) # 3d4 <close>
  return r;
}
 29e:	854a                	mv	a0,s2
 2a0:	60e2                	ld	ra,24(sp)
 2a2:	6442                	ld	s0,16(sp)
 2a4:	64a2                	ld	s1,8(sp)
 2a6:	6902                	ld	s2,0(sp)
 2a8:	6105                	addi	sp,sp,32
 2aa:	8082                	ret
    return -1;
 2ac:	597d                	li	s2,-1
 2ae:	bfc5                	j	29e <stat+0x34>

00000000000002b0 <atoi>:

int
atoi(const char *s)
{
 2b0:	1141                	addi	sp,sp,-16
 2b2:	e422                	sd	s0,8(sp)
 2b4:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 2b6:	00054603          	lbu	a2,0(a0)
 2ba:	fd06079b          	addiw	a5,a2,-48
 2be:	0ff7f793          	andi	a5,a5,255
 2c2:	4725                	li	a4,9
 2c4:	02f76963          	bltu	a4,a5,2f6 <atoi+0x46>
 2c8:	86aa                	mv	a3,a0
  n = 0;
 2ca:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 2cc:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 2ce:	0685                	addi	a3,a3,1
 2d0:	0025179b          	slliw	a5,a0,0x2
 2d4:	9fa9                	addw	a5,a5,a0
 2d6:	0017979b          	slliw	a5,a5,0x1
 2da:	9fb1                	addw	a5,a5,a2
 2dc:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 2e0:	0006c603          	lbu	a2,0(a3)
 2e4:	fd06071b          	addiw	a4,a2,-48
 2e8:	0ff77713          	andi	a4,a4,255
 2ec:	fee5f1e3          	bgeu	a1,a4,2ce <atoi+0x1e>
  return n;
}
 2f0:	6422                	ld	s0,8(sp)
 2f2:	0141                	addi	sp,sp,16
 2f4:	8082                	ret
  n = 0;
 2f6:	4501                	li	a0,0
 2f8:	bfe5                	j	2f0 <atoi+0x40>

00000000000002fa <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 2fa:	1141                	addi	sp,sp,-16
 2fc:	e422                	sd	s0,8(sp)
 2fe:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 300:	02b57463          	bgeu	a0,a1,328 <memmove+0x2e>
    while(n-- > 0)
 304:	00c05f63          	blez	a2,322 <memmove+0x28>
 308:	1602                	slli	a2,a2,0x20
 30a:	9201                	srli	a2,a2,0x20
 30c:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 310:	872a                	mv	a4,a0
      *dst++ = *src++;
 312:	0585                	addi	a1,a1,1
 314:	0705                	addi	a4,a4,1
 316:	fff5c683          	lbu	a3,-1(a1)
 31a:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 31e:	fee79ae3          	bne	a5,a4,312 <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 322:	6422                	ld	s0,8(sp)
 324:	0141                	addi	sp,sp,16
 326:	8082                	ret
    dst += n;
 328:	00c50733          	add	a4,a0,a2
    src += n;
 32c:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 32e:	fec05ae3          	blez	a2,322 <memmove+0x28>
 332:	fff6079b          	addiw	a5,a2,-1
 336:	1782                	slli	a5,a5,0x20
 338:	9381                	srli	a5,a5,0x20
 33a:	fff7c793          	not	a5,a5
 33e:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 340:	15fd                	addi	a1,a1,-1
 342:	177d                	addi	a4,a4,-1
 344:	0005c683          	lbu	a3,0(a1)
 348:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 34c:	fee79ae3          	bne	a5,a4,340 <memmove+0x46>
 350:	bfc9                	j	322 <memmove+0x28>

0000000000000352 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 352:	1141                	addi	sp,sp,-16
 354:	e422                	sd	s0,8(sp)
 356:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 358:	ca05                	beqz	a2,388 <memcmp+0x36>
 35a:	fff6069b          	addiw	a3,a2,-1
 35e:	1682                	slli	a3,a3,0x20
 360:	9281                	srli	a3,a3,0x20
 362:	0685                	addi	a3,a3,1
 364:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 366:	00054783          	lbu	a5,0(a0)
 36a:	0005c703          	lbu	a4,0(a1)
 36e:	00e79863          	bne	a5,a4,37e <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 372:	0505                	addi	a0,a0,1
    p2++;
 374:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 376:	fed518e3          	bne	a0,a3,366 <memcmp+0x14>
  }
  return 0;
 37a:	4501                	li	a0,0
 37c:	a019                	j	382 <memcmp+0x30>
      return *p1 - *p2;
 37e:	40e7853b          	subw	a0,a5,a4
}
 382:	6422                	ld	s0,8(sp)
 384:	0141                	addi	sp,sp,16
 386:	8082                	ret
  return 0;
 388:	4501                	li	a0,0
 38a:	bfe5                	j	382 <memcmp+0x30>

000000000000038c <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 38c:	1141                	addi	sp,sp,-16
 38e:	e406                	sd	ra,8(sp)
 390:	e022                	sd	s0,0(sp)
 392:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 394:	00000097          	auipc	ra,0x0
 398:	f66080e7          	jalr	-154(ra) # 2fa <memmove>
}
 39c:	60a2                	ld	ra,8(sp)
 39e:	6402                	ld	s0,0(sp)
 3a0:	0141                	addi	sp,sp,16
 3a2:	8082                	ret

00000000000003a4 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 3a4:	4885                	li	a7,1
 ecall
 3a6:	00000073          	ecall
 ret
 3aa:	8082                	ret

00000000000003ac <exit>:
.global exit
exit:
 li a7, SYS_exit
 3ac:	4889                	li	a7,2
 ecall
 3ae:	00000073          	ecall
 ret
 3b2:	8082                	ret

00000000000003b4 <wait>:
.global wait
wait:
 li a7, SYS_wait
 3b4:	488d                	li	a7,3
 ecall
 3b6:	00000073          	ecall
 ret
 3ba:	8082                	ret

00000000000003bc <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 3bc:	4891                	li	a7,4
 ecall
 3be:	00000073          	ecall
 ret
 3c2:	8082                	ret

00000000000003c4 <read>:
.global read
read:
 li a7, SYS_read
 3c4:	4895                	li	a7,5
 ecall
 3c6:	00000073          	ecall
 ret
 3ca:	8082                	ret

00000000000003cc <write>:
.global write
write:
 li a7, SYS_write
 3cc:	48c1                	li	a7,16
 ecall
 3ce:	00000073          	ecall
 ret
 3d2:	8082                	ret

00000000000003d4 <close>:
.global close
close:
 li a7, SYS_close
 3d4:	48d5                	li	a7,21
 ecall
 3d6:	00000073          	ecall
 ret
 3da:	8082                	ret

00000000000003dc <kill>:
.global kill
kill:
 li a7, SYS_kill
 3dc:	4899                	li	a7,6
 ecall
 3de:	00000073          	ecall
 ret
 3e2:	8082                	ret

00000000000003e4 <exec>:
.global exec
exec:
 li a7, SYS_exec
 3e4:	489d                	li	a7,7
 ecall
 3e6:	00000073          	ecall
 ret
 3ea:	8082                	ret

00000000000003ec <open>:
.global open
open:
 li a7, SYS_open
 3ec:	48bd                	li	a7,15
 ecall
 3ee:	00000073          	ecall
 ret
 3f2:	8082                	ret

00000000000003f4 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 3f4:	48c5                	li	a7,17
 ecall
 3f6:	00000073          	ecall
 ret
 3fa:	8082                	ret

00000000000003fc <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 3fc:	48c9                	li	a7,18
 ecall
 3fe:	00000073          	ecall
 ret
 402:	8082                	ret

0000000000000404 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 404:	48a1                	li	a7,8
 ecall
 406:	00000073          	ecall
 ret
 40a:	8082                	ret

000000000000040c <link>:
.global link
link:
 li a7, SYS_link
 40c:	48cd                	li	a7,19
 ecall
 40e:	00000073          	ecall
 ret
 412:	8082                	ret

0000000000000414 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 414:	48d1                	li	a7,20
 ecall
 416:	00000073          	ecall
 ret
 41a:	8082                	ret

000000000000041c <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 41c:	48a5                	li	a7,9
 ecall
 41e:	00000073          	ecall
 ret
 422:	8082                	ret

0000000000000424 <dup>:
.global dup
dup:
 li a7, SYS_dup
 424:	48a9                	li	a7,10
 ecall
 426:	00000073          	ecall
 ret
 42a:	8082                	ret

000000000000042c <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 42c:	48ad                	li	a7,11
 ecall
 42e:	00000073          	ecall
 ret
 432:	8082                	ret

0000000000000434 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 434:	48b1                	li	a7,12
 ecall
 436:	00000073          	ecall
 ret
 43a:	8082                	ret

000000000000043c <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 43c:	48b5                	li	a7,13
 ecall
 43e:	00000073          	ecall
 ret
 442:	8082                	ret

0000000000000444 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 444:	48b9                	li	a7,14
 ecall
 446:	00000073          	ecall
 ret
 44a:	8082                	ret

000000000000044c <waitx>:
.global waitx
waitx:
 li a7, SYS_waitx
 44c:	48d9                	li	a7,22
 ecall
 44e:	00000073          	ecall
 ret
 452:	8082                	ret

0000000000000454 <getSysCount>:
.global getSysCount
getSysCount:
 li a7, SYS_getSysCount
 454:	48dd                	li	a7,23
 ecall
 456:	00000073          	ecall
 ret
 45a:	8082                	ret

000000000000045c <sigalarm>:
.global sigalarm
sigalarm:
 li a7, SYS_sigalarm
 45c:	48e1                	li	a7,24
 ecall
 45e:	00000073          	ecall
 ret
 462:	8082                	ret

0000000000000464 <sigreturn>:
.global sigreturn
sigreturn:
 li a7, SYS_sigreturn
 464:	48e5                	li	a7,25
 ecall
 466:	00000073          	ecall
 ret
 46a:	8082                	ret

000000000000046c <settickets>:
.global settickets
settickets:
 li a7, SYS_settickets
 46c:	48e9                	li	a7,26
 ecall
 46e:	00000073          	ecall
 ret
 472:	8082                	ret

0000000000000474 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 474:	1101                	addi	sp,sp,-32
 476:	ec06                	sd	ra,24(sp)
 478:	e822                	sd	s0,16(sp)
 47a:	1000                	addi	s0,sp,32
 47c:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 480:	4605                	li	a2,1
 482:	fef40593          	addi	a1,s0,-17
 486:	00000097          	auipc	ra,0x0
 48a:	f46080e7          	jalr	-186(ra) # 3cc <write>
}
 48e:	60e2                	ld	ra,24(sp)
 490:	6442                	ld	s0,16(sp)
 492:	6105                	addi	sp,sp,32
 494:	8082                	ret

0000000000000496 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 496:	7139                	addi	sp,sp,-64
 498:	fc06                	sd	ra,56(sp)
 49a:	f822                	sd	s0,48(sp)
 49c:	f426                	sd	s1,40(sp)
 49e:	f04a                	sd	s2,32(sp)
 4a0:	ec4e                	sd	s3,24(sp)
 4a2:	0080                	addi	s0,sp,64
 4a4:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 4a6:	c299                	beqz	a3,4ac <printint+0x16>
 4a8:	0805c863          	bltz	a1,538 <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 4ac:	2581                	sext.w	a1,a1
  neg = 0;
 4ae:	4881                	li	a7,0
 4b0:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 4b4:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 4b6:	2601                	sext.w	a2,a2
 4b8:	00000517          	auipc	a0,0x0
 4bc:	5f850513          	addi	a0,a0,1528 # ab0 <digits>
 4c0:	883a                	mv	a6,a4
 4c2:	2705                	addiw	a4,a4,1
 4c4:	02c5f7bb          	remuw	a5,a1,a2
 4c8:	1782                	slli	a5,a5,0x20
 4ca:	9381                	srli	a5,a5,0x20
 4cc:	97aa                	add	a5,a5,a0
 4ce:	0007c783          	lbu	a5,0(a5)
 4d2:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 4d6:	0005879b          	sext.w	a5,a1
 4da:	02c5d5bb          	divuw	a1,a1,a2
 4de:	0685                	addi	a3,a3,1
 4e0:	fec7f0e3          	bgeu	a5,a2,4c0 <printint+0x2a>
  if(neg)
 4e4:	00088b63          	beqz	a7,4fa <printint+0x64>
    buf[i++] = '-';
 4e8:	fd040793          	addi	a5,s0,-48
 4ec:	973e                	add	a4,a4,a5
 4ee:	02d00793          	li	a5,45
 4f2:	fef70823          	sb	a5,-16(a4)
 4f6:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 4fa:	02e05863          	blez	a4,52a <printint+0x94>
 4fe:	fc040793          	addi	a5,s0,-64
 502:	00e78933          	add	s2,a5,a4
 506:	fff78993          	addi	s3,a5,-1
 50a:	99ba                	add	s3,s3,a4
 50c:	377d                	addiw	a4,a4,-1
 50e:	1702                	slli	a4,a4,0x20
 510:	9301                	srli	a4,a4,0x20
 512:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 516:	fff94583          	lbu	a1,-1(s2)
 51a:	8526                	mv	a0,s1
 51c:	00000097          	auipc	ra,0x0
 520:	f58080e7          	jalr	-168(ra) # 474 <putc>
  while(--i >= 0)
 524:	197d                	addi	s2,s2,-1
 526:	ff3918e3          	bne	s2,s3,516 <printint+0x80>
}
 52a:	70e2                	ld	ra,56(sp)
 52c:	7442                	ld	s0,48(sp)
 52e:	74a2                	ld	s1,40(sp)
 530:	7902                	ld	s2,32(sp)
 532:	69e2                	ld	s3,24(sp)
 534:	6121                	addi	sp,sp,64
 536:	8082                	ret
    x = -xx;
 538:	40b005bb          	negw	a1,a1
    neg = 1;
 53c:	4885                	li	a7,1
    x = -xx;
 53e:	bf8d                	j	4b0 <printint+0x1a>

0000000000000540 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 540:	7119                	addi	sp,sp,-128
 542:	fc86                	sd	ra,120(sp)
 544:	f8a2                	sd	s0,112(sp)
 546:	f4a6                	sd	s1,104(sp)
 548:	f0ca                	sd	s2,96(sp)
 54a:	ecce                	sd	s3,88(sp)
 54c:	e8d2                	sd	s4,80(sp)
 54e:	e4d6                	sd	s5,72(sp)
 550:	e0da                	sd	s6,64(sp)
 552:	fc5e                	sd	s7,56(sp)
 554:	f862                	sd	s8,48(sp)
 556:	f466                	sd	s9,40(sp)
 558:	f06a                	sd	s10,32(sp)
 55a:	ec6e                	sd	s11,24(sp)
 55c:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 55e:	0005c903          	lbu	s2,0(a1)
 562:	18090f63          	beqz	s2,700 <vprintf+0x1c0>
 566:	8aaa                	mv	s5,a0
 568:	8b32                	mv	s6,a2
 56a:	00158493          	addi	s1,a1,1
  state = 0;
 56e:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 570:	02500a13          	li	s4,37
      if(c == 'd'){
 574:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 578:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 57c:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 580:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 584:	00000b97          	auipc	s7,0x0
 588:	52cb8b93          	addi	s7,s7,1324 # ab0 <digits>
 58c:	a839                	j	5aa <vprintf+0x6a>
        putc(fd, c);
 58e:	85ca                	mv	a1,s2
 590:	8556                	mv	a0,s5
 592:	00000097          	auipc	ra,0x0
 596:	ee2080e7          	jalr	-286(ra) # 474 <putc>
 59a:	a019                	j	5a0 <vprintf+0x60>
    } else if(state == '%'){
 59c:	01498f63          	beq	s3,s4,5ba <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 5a0:	0485                	addi	s1,s1,1
 5a2:	fff4c903          	lbu	s2,-1(s1)
 5a6:	14090d63          	beqz	s2,700 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 5aa:	0009079b          	sext.w	a5,s2
    if(state == 0){
 5ae:	fe0997e3          	bnez	s3,59c <vprintf+0x5c>
      if(c == '%'){
 5b2:	fd479ee3          	bne	a5,s4,58e <vprintf+0x4e>
        state = '%';
 5b6:	89be                	mv	s3,a5
 5b8:	b7e5                	j	5a0 <vprintf+0x60>
      if(c == 'd'){
 5ba:	05878063          	beq	a5,s8,5fa <vprintf+0xba>
      } else if(c == 'l') {
 5be:	05978c63          	beq	a5,s9,616 <vprintf+0xd6>
      } else if(c == 'x') {
 5c2:	07a78863          	beq	a5,s10,632 <vprintf+0xf2>
      } else if(c == 'p') {
 5c6:	09b78463          	beq	a5,s11,64e <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 5ca:	07300713          	li	a4,115
 5ce:	0ce78663          	beq	a5,a4,69a <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 5d2:	06300713          	li	a4,99
 5d6:	0ee78e63          	beq	a5,a4,6d2 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 5da:	11478863          	beq	a5,s4,6ea <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 5de:	85d2                	mv	a1,s4
 5e0:	8556                	mv	a0,s5
 5e2:	00000097          	auipc	ra,0x0
 5e6:	e92080e7          	jalr	-366(ra) # 474 <putc>
        putc(fd, c);
 5ea:	85ca                	mv	a1,s2
 5ec:	8556                	mv	a0,s5
 5ee:	00000097          	auipc	ra,0x0
 5f2:	e86080e7          	jalr	-378(ra) # 474 <putc>
      }
      state = 0;
 5f6:	4981                	li	s3,0
 5f8:	b765                	j	5a0 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 5fa:	008b0913          	addi	s2,s6,8
 5fe:	4685                	li	a3,1
 600:	4629                	li	a2,10
 602:	000b2583          	lw	a1,0(s6)
 606:	8556                	mv	a0,s5
 608:	00000097          	auipc	ra,0x0
 60c:	e8e080e7          	jalr	-370(ra) # 496 <printint>
 610:	8b4a                	mv	s6,s2
      state = 0;
 612:	4981                	li	s3,0
 614:	b771                	j	5a0 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 616:	008b0913          	addi	s2,s6,8
 61a:	4681                	li	a3,0
 61c:	4629                	li	a2,10
 61e:	000b2583          	lw	a1,0(s6)
 622:	8556                	mv	a0,s5
 624:	00000097          	auipc	ra,0x0
 628:	e72080e7          	jalr	-398(ra) # 496 <printint>
 62c:	8b4a                	mv	s6,s2
      state = 0;
 62e:	4981                	li	s3,0
 630:	bf85                	j	5a0 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 632:	008b0913          	addi	s2,s6,8
 636:	4681                	li	a3,0
 638:	4641                	li	a2,16
 63a:	000b2583          	lw	a1,0(s6)
 63e:	8556                	mv	a0,s5
 640:	00000097          	auipc	ra,0x0
 644:	e56080e7          	jalr	-426(ra) # 496 <printint>
 648:	8b4a                	mv	s6,s2
      state = 0;
 64a:	4981                	li	s3,0
 64c:	bf91                	j	5a0 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 64e:	008b0793          	addi	a5,s6,8
 652:	f8f43423          	sd	a5,-120(s0)
 656:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 65a:	03000593          	li	a1,48
 65e:	8556                	mv	a0,s5
 660:	00000097          	auipc	ra,0x0
 664:	e14080e7          	jalr	-492(ra) # 474 <putc>
  putc(fd, 'x');
 668:	85ea                	mv	a1,s10
 66a:	8556                	mv	a0,s5
 66c:	00000097          	auipc	ra,0x0
 670:	e08080e7          	jalr	-504(ra) # 474 <putc>
 674:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 676:	03c9d793          	srli	a5,s3,0x3c
 67a:	97de                	add	a5,a5,s7
 67c:	0007c583          	lbu	a1,0(a5)
 680:	8556                	mv	a0,s5
 682:	00000097          	auipc	ra,0x0
 686:	df2080e7          	jalr	-526(ra) # 474 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 68a:	0992                	slli	s3,s3,0x4
 68c:	397d                	addiw	s2,s2,-1
 68e:	fe0914e3          	bnez	s2,676 <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 692:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 696:	4981                	li	s3,0
 698:	b721                	j	5a0 <vprintf+0x60>
        s = va_arg(ap, char*);
 69a:	008b0993          	addi	s3,s6,8
 69e:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 6a2:	02090163          	beqz	s2,6c4 <vprintf+0x184>
        while(*s != 0){
 6a6:	00094583          	lbu	a1,0(s2)
 6aa:	c9a1                	beqz	a1,6fa <vprintf+0x1ba>
          putc(fd, *s);
 6ac:	8556                	mv	a0,s5
 6ae:	00000097          	auipc	ra,0x0
 6b2:	dc6080e7          	jalr	-570(ra) # 474 <putc>
          s++;
 6b6:	0905                	addi	s2,s2,1
        while(*s != 0){
 6b8:	00094583          	lbu	a1,0(s2)
 6bc:	f9e5                	bnez	a1,6ac <vprintf+0x16c>
        s = va_arg(ap, char*);
 6be:	8b4e                	mv	s6,s3
      state = 0;
 6c0:	4981                	li	s3,0
 6c2:	bdf9                	j	5a0 <vprintf+0x60>
          s = "(null)";
 6c4:	00000917          	auipc	s2,0x0
 6c8:	3e490913          	addi	s2,s2,996 # aa8 <malloc+0x29e>
        while(*s != 0){
 6cc:	02800593          	li	a1,40
 6d0:	bff1                	j	6ac <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 6d2:	008b0913          	addi	s2,s6,8
 6d6:	000b4583          	lbu	a1,0(s6)
 6da:	8556                	mv	a0,s5
 6dc:	00000097          	auipc	ra,0x0
 6e0:	d98080e7          	jalr	-616(ra) # 474 <putc>
 6e4:	8b4a                	mv	s6,s2
      state = 0;
 6e6:	4981                	li	s3,0
 6e8:	bd65                	j	5a0 <vprintf+0x60>
        putc(fd, c);
 6ea:	85d2                	mv	a1,s4
 6ec:	8556                	mv	a0,s5
 6ee:	00000097          	auipc	ra,0x0
 6f2:	d86080e7          	jalr	-634(ra) # 474 <putc>
      state = 0;
 6f6:	4981                	li	s3,0
 6f8:	b565                	j	5a0 <vprintf+0x60>
        s = va_arg(ap, char*);
 6fa:	8b4e                	mv	s6,s3
      state = 0;
 6fc:	4981                	li	s3,0
 6fe:	b54d                	j	5a0 <vprintf+0x60>
    }
  }
}
 700:	70e6                	ld	ra,120(sp)
 702:	7446                	ld	s0,112(sp)
 704:	74a6                	ld	s1,104(sp)
 706:	7906                	ld	s2,96(sp)
 708:	69e6                	ld	s3,88(sp)
 70a:	6a46                	ld	s4,80(sp)
 70c:	6aa6                	ld	s5,72(sp)
 70e:	6b06                	ld	s6,64(sp)
 710:	7be2                	ld	s7,56(sp)
 712:	7c42                	ld	s8,48(sp)
 714:	7ca2                	ld	s9,40(sp)
 716:	7d02                	ld	s10,32(sp)
 718:	6de2                	ld	s11,24(sp)
 71a:	6109                	addi	sp,sp,128
 71c:	8082                	ret

000000000000071e <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 71e:	715d                	addi	sp,sp,-80
 720:	ec06                	sd	ra,24(sp)
 722:	e822                	sd	s0,16(sp)
 724:	1000                	addi	s0,sp,32
 726:	e010                	sd	a2,0(s0)
 728:	e414                	sd	a3,8(s0)
 72a:	e818                	sd	a4,16(s0)
 72c:	ec1c                	sd	a5,24(s0)
 72e:	03043023          	sd	a6,32(s0)
 732:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 736:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 73a:	8622                	mv	a2,s0
 73c:	00000097          	auipc	ra,0x0
 740:	e04080e7          	jalr	-508(ra) # 540 <vprintf>
}
 744:	60e2                	ld	ra,24(sp)
 746:	6442                	ld	s0,16(sp)
 748:	6161                	addi	sp,sp,80
 74a:	8082                	ret

000000000000074c <printf>:

void
printf(const char *fmt, ...)
{
 74c:	711d                	addi	sp,sp,-96
 74e:	ec06                	sd	ra,24(sp)
 750:	e822                	sd	s0,16(sp)
 752:	1000                	addi	s0,sp,32
 754:	e40c                	sd	a1,8(s0)
 756:	e810                	sd	a2,16(s0)
 758:	ec14                	sd	a3,24(s0)
 75a:	f018                	sd	a4,32(s0)
 75c:	f41c                	sd	a5,40(s0)
 75e:	03043823          	sd	a6,48(s0)
 762:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 766:	00840613          	addi	a2,s0,8
 76a:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 76e:	85aa                	mv	a1,a0
 770:	4505                	li	a0,1
 772:	00000097          	auipc	ra,0x0
 776:	dce080e7          	jalr	-562(ra) # 540 <vprintf>
}
 77a:	60e2                	ld	ra,24(sp)
 77c:	6442                	ld	s0,16(sp)
 77e:	6125                	addi	sp,sp,96
 780:	8082                	ret

0000000000000782 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 782:	1141                	addi	sp,sp,-16
 784:	e422                	sd	s0,8(sp)
 786:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 788:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 78c:	00001797          	auipc	a5,0x1
 790:	8747b783          	ld	a5,-1932(a5) # 1000 <freep>
 794:	a805                	j	7c4 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 796:	4618                	lw	a4,8(a2)
 798:	9db9                	addw	a1,a1,a4
 79a:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 79e:	6398                	ld	a4,0(a5)
 7a0:	6318                	ld	a4,0(a4)
 7a2:	fee53823          	sd	a4,-16(a0)
 7a6:	a091                	j	7ea <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 7a8:	ff852703          	lw	a4,-8(a0)
 7ac:	9e39                	addw	a2,a2,a4
 7ae:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 7b0:	ff053703          	ld	a4,-16(a0)
 7b4:	e398                	sd	a4,0(a5)
 7b6:	a099                	j	7fc <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 7b8:	6398                	ld	a4,0(a5)
 7ba:	00e7e463          	bltu	a5,a4,7c2 <free+0x40>
 7be:	00e6ea63          	bltu	a3,a4,7d2 <free+0x50>
{
 7c2:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 7c4:	fed7fae3          	bgeu	a5,a3,7b8 <free+0x36>
 7c8:	6398                	ld	a4,0(a5)
 7ca:	00e6e463          	bltu	a3,a4,7d2 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 7ce:	fee7eae3          	bltu	a5,a4,7c2 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 7d2:	ff852583          	lw	a1,-8(a0)
 7d6:	6390                	ld	a2,0(a5)
 7d8:	02059713          	slli	a4,a1,0x20
 7dc:	9301                	srli	a4,a4,0x20
 7de:	0712                	slli	a4,a4,0x4
 7e0:	9736                	add	a4,a4,a3
 7e2:	fae60ae3          	beq	a2,a4,796 <free+0x14>
    bp->s.ptr = p->s.ptr;
 7e6:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 7ea:	4790                	lw	a2,8(a5)
 7ec:	02061713          	slli	a4,a2,0x20
 7f0:	9301                	srli	a4,a4,0x20
 7f2:	0712                	slli	a4,a4,0x4
 7f4:	973e                	add	a4,a4,a5
 7f6:	fae689e3          	beq	a3,a4,7a8 <free+0x26>
  } else
    p->s.ptr = bp;
 7fa:	e394                	sd	a3,0(a5)
  freep = p;
 7fc:	00001717          	auipc	a4,0x1
 800:	80f73223          	sd	a5,-2044(a4) # 1000 <freep>
}
 804:	6422                	ld	s0,8(sp)
 806:	0141                	addi	sp,sp,16
 808:	8082                	ret

000000000000080a <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 80a:	7139                	addi	sp,sp,-64
 80c:	fc06                	sd	ra,56(sp)
 80e:	f822                	sd	s0,48(sp)
 810:	f426                	sd	s1,40(sp)
 812:	f04a                	sd	s2,32(sp)
 814:	ec4e                	sd	s3,24(sp)
 816:	e852                	sd	s4,16(sp)
 818:	e456                	sd	s5,8(sp)
 81a:	e05a                	sd	s6,0(sp)
 81c:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 81e:	02051493          	slli	s1,a0,0x20
 822:	9081                	srli	s1,s1,0x20
 824:	04bd                	addi	s1,s1,15
 826:	8091                	srli	s1,s1,0x4
 828:	0014899b          	addiw	s3,s1,1
 82c:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 82e:	00000517          	auipc	a0,0x0
 832:	7d253503          	ld	a0,2002(a0) # 1000 <freep>
 836:	c515                	beqz	a0,862 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 838:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 83a:	4798                	lw	a4,8(a5)
 83c:	02977f63          	bgeu	a4,s1,87a <malloc+0x70>
 840:	8a4e                	mv	s4,s3
 842:	0009871b          	sext.w	a4,s3
 846:	6685                	lui	a3,0x1
 848:	00d77363          	bgeu	a4,a3,84e <malloc+0x44>
 84c:	6a05                	lui	s4,0x1
 84e:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 852:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 856:	00000917          	auipc	s2,0x0
 85a:	7aa90913          	addi	s2,s2,1962 # 1000 <freep>
  if(p == (char*)-1)
 85e:	5afd                	li	s5,-1
 860:	a88d                	j	8d2 <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 862:	00000797          	auipc	a5,0x0
 866:	7ae78793          	addi	a5,a5,1966 # 1010 <base>
 86a:	00000717          	auipc	a4,0x0
 86e:	78f73b23          	sd	a5,1942(a4) # 1000 <freep>
 872:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 874:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 878:	b7e1                	j	840 <malloc+0x36>
      if(p->s.size == nunits)
 87a:	02e48b63          	beq	s1,a4,8b0 <malloc+0xa6>
        p->s.size -= nunits;
 87e:	4137073b          	subw	a4,a4,s3
 882:	c798                	sw	a4,8(a5)
        p += p->s.size;
 884:	1702                	slli	a4,a4,0x20
 886:	9301                	srli	a4,a4,0x20
 888:	0712                	slli	a4,a4,0x4
 88a:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 88c:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 890:	00000717          	auipc	a4,0x0
 894:	76a73823          	sd	a0,1904(a4) # 1000 <freep>
      return (void*)(p + 1);
 898:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 89c:	70e2                	ld	ra,56(sp)
 89e:	7442                	ld	s0,48(sp)
 8a0:	74a2                	ld	s1,40(sp)
 8a2:	7902                	ld	s2,32(sp)
 8a4:	69e2                	ld	s3,24(sp)
 8a6:	6a42                	ld	s4,16(sp)
 8a8:	6aa2                	ld	s5,8(sp)
 8aa:	6b02                	ld	s6,0(sp)
 8ac:	6121                	addi	sp,sp,64
 8ae:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 8b0:	6398                	ld	a4,0(a5)
 8b2:	e118                	sd	a4,0(a0)
 8b4:	bff1                	j	890 <malloc+0x86>
  hp->s.size = nu;
 8b6:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 8ba:	0541                	addi	a0,a0,16
 8bc:	00000097          	auipc	ra,0x0
 8c0:	ec6080e7          	jalr	-314(ra) # 782 <free>
  return freep;
 8c4:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 8c8:	d971                	beqz	a0,89c <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 8ca:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 8cc:	4798                	lw	a4,8(a5)
 8ce:	fa9776e3          	bgeu	a4,s1,87a <malloc+0x70>
    if(p == freep)
 8d2:	00093703          	ld	a4,0(s2)
 8d6:	853e                	mv	a0,a5
 8d8:	fef719e3          	bne	a4,a5,8ca <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 8dc:	8552                	mv	a0,s4
 8de:	00000097          	auipc	ra,0x0
 8e2:	b56080e7          	jalr	-1194(ra) # 434 <sbrk>
  if(p == (char*)-1)
 8e6:	fd5518e3          	bne	a0,s5,8b6 <malloc+0xac>
        return 0;
 8ea:	4501                	li	a0,0
 8ec:	bf45                	j	89c <malloc+0x92>
