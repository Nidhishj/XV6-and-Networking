#include "types.h"
#include "riscv.h"
#include "defs.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "proc.h"

int argptr(int n, void **pp, int size) {
    uint64 addr;
    argint(n, (int*)&addr);
    if(n<0)
    return -1;
    if (size < 0)
        return -1; // Check bounds
    *pp = (void *)addr; // Set the pointer
    return 0;
}

uint64
sys_exit(void)
{
  int n;
  argint(0, &n);
  exit(n);
  return 0; // not reached
}

uint64
sys_getpid(void)
{
  return myproc()->pid;
}

uint64
sys_fork(void)
{
  return fork();
}

uint64
sys_wait(void)
{
  uint64 p;
  argaddr(0, &p);
  return wait(p);
}

uint64
sys_sbrk(void)
{
  uint64 addr;
  int n;

  argint(0, &n);
  addr = myproc()->sz;
  if (growproc(n) < 0)
    return -1;
  return addr;
}

uint64
sys_sleep(void)
{
  int n;
  uint ticks0;

  argint(0, &n);
  acquire(&tickslock);
  ticks0 = ticks;
  while (ticks - ticks0 < n)
  {
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
  }
  release(&tickslock);
  return 0;
}

uint64
sys_kill(void)
{
  int pid;

  argint(0, &pid);
  return kill(pid);
}

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
  uint xticks;
  acquire(&tickslock);
  xticks = ticks;
  release(&tickslock);
  return xticks;
}

uint64
sys_waitx(void)
{
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
  argaddr(1, &addr1); // user virtual memory
  argaddr(2, &addr2);
  int ret = waitx(addr, &wtime, &rtime);
  struct proc *p = myproc();
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    return -1;
  if (copyout(p->pagetable, addr2, (char *)&rtime, sizeof(int)) < 0)
    return -1;
  return ret;
}

uint64
sys_getSysCount(void)
{
  int k;
  argint(0,&k);
  struct proc *p = myproc();
  return p->syscall_count[k];
} 

uint64
sys_sigalarm(void)
{
  int interval;
  uint64 addr;

  argint(0, &interval);
    if(interval<0)
    return -1;
  argaddr(1,&addr);

  struct proc *p = myproc();
  p->alarm=1;//means that we have called sigalarm so u start checking 
  p->alarmticks = interval;
  p->handler = addr;
  return 0;
}

uint64
sys_sigreturn(void)
{
  struct proc *p = myproc();
  memmove(p->trapframe,p->savedtf,PGSIZE);
  kfree(p->savedtf);
  p->tickcounter=0;
  p->alarm=1;
  usertrapret();  
  return 0;
}

uint64
sys_settickets(void)
{
  int k ;
  argint(0,&k);
  if(k<=0)
  return 0;
  struct proc *p = myproc();
  p->tickets=k;
  return 1;
}