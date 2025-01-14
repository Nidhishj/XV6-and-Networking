// Physical memory allocator, for user processes,
// kernel stacks, page-table pages,
// and pipe buffers. Allocates whole 4096-byte pages.

#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "riscv.h"
#include "defs.h"

#define MAX_PHYS_PAGES (PHYSTOP-KERNBASE)/PGSIZE

int ref_count[MAX_PHYS_PAGES]={0};//this will hold how many are refering to a current physical page
struct spinlock ref_count_lock;

void freerange(void *pa_start, void *pa_end);

extern char end[]; // first address after kernel.
                   // defined by kernel.ld.

struct run {
  struct run *next;
};

struct {
  struct spinlock lock;
  struct run *freelist;
} kmem;

void
kinit()
{
  initlock(&kmem.lock, "kmem");
  freerange(end, (void*)PHYSTOP);
}

void
freerange(void *pa_start, void *pa_end)
{
  char *p;
  p = (char*)PGROUNDUP((uint64)pa_start);
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    {
      incref((uint64)p);
      kfree(p);
    }
}

void decref(uint64 pa)
{
  int page_index = (pa - KERNBASE) / PGSIZE; 
  acquire(&ref_count_lock);
  ref_count[page_index]--;
  release(&ref_count_lock);
}

uint64 ref_count_returner(uint64 pa)
{
  acquire(&ref_count_lock);
  int page_index = (pa - KERNBASE) / PGSIZE;
  int count =  ref_count[page_index];
  release(&ref_count_lock);
  return count;
}


void incref(uint64 pa)
{
  int page_index = (pa - KERNBASE)/PGSIZE;
  acquire(&ref_count_lock);
  ref_count[page_index]++;
  release(&ref_count_lock);
}

// Free the page of physical memory pointed at by pa,
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    panic("kfree");

  // Fill with junk to catch dangling refs.
  //will free only if the refernce count == 0  
  decref((uint64)pa);
  if(ref_count_returner((uint64)pa) > 0){
    return;
  }
  memset(pa, 1, PGSIZE);
  
  r = (struct run*)pa;
  
  acquire(&kmem.lock);
  r->next = kmem.freelist;
  kmem.freelist = r;
  release(&kmem.lock);
}

// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
  struct run *r;

  acquire(&kmem.lock);
  r = kmem.freelist;
  if(r)
    kmem.freelist = r->next;
  release(&kmem.lock);

  if(r)
   { memset((char*)r, 5, PGSIZE); // fill with junk
   incref((uint64)r);
   }
  return (void*)r;
}