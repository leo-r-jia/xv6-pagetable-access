#include "types.h"
#include "riscv.h"
#include "defs.h"
#include "date.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "proc.h"


uint64
sys_exit(void)
{
  int n;
  if(argint(0, &n) < 0)
    return -1;
  exit(n);
  return 0;  // not reached
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
  if(argaddr(0, &p) < 0)
    return -1;
  return wait(p);
}

uint64
sys_sbrk(void)
{
  int addr;
  int n;

  if(argint(0, &n) < 0)
    return -1;
  addr = myproc()->sz;
  if(growproc(n) < 0)
    return -1;
  return addr;
}

uint64
sys_sleep(void)
{
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    return -1;
  acquire(&tickslock);
  ticks0 = ticks;
  while(ticks - ticks0 < n){
    if(myproc()->killed){
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

  if(argint(0, &pid) < 0)
    return -1;
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
sys_pageAccess(void)
{
  // Get the three function arguments from the pageAccess() system call
  uint64 usrpage_ptr;  // First argument - pointer to user space address
  int npages;          // Second argument - the number of pages to examine
  uint64 usraddr;      // Third argument - pointer to the bitmap

  argaddr(0, &usrpage_ptr);
  argint(1, &npages);
  argaddr(2, &usraddr);

  struct proc* p = myproc();

  pte_t * pte;
  int bitmap = 0;

  for(int i=0; i<npages;i++) {
    pte = walk(p->pagetable, usrpage_ptr, 0);
    if(*pte & PTE_A) {
      *pte &= ~(PTE_A);
      bitmap |= (1 << i);
    }
    usrpage_ptr += PGSIZE;
  }

  if(copyout(p->pagetable, usraddr, (char*)&bitmap, sizeof(bitmap))<0) {
    return -1;
  }
  // Return the bitmap pointer to the user program
  copyout(p->pagetable, usraddr, (char*)&bitmap, sizeof(bitmap));
  return 0;
}
