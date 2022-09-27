#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"  // prototype of pageAccess() system call should be defined here
int
main ()
{
#define PGSIZE 4096

char *buf;
unsigned int abits;
printf("Page access test starting\n");
buf = malloc(32 * PGSIZE);   // allocate 32 pages of physical memory
if (pageAccess(buf, 32, &abits) < 0)   // pageAccess() is the system call
{
printf("pageAccess failed\n");
free(buf);
exit(1);
}
// abits should now be zero since there was no read or write in buf yet.
// Read and write to several different pages here
// Change the page numbers and the number of pages to thoroughly test the system call
buf[PGSIZE * 1] += 1;
buf[PGSIZE * 2] += 1;
    buf[PGSIZE * 30] += 1;
    // Let pageAccess check the pages accessed in buf
    if (pageAccess(buf, 32, &abits) < 0)
    {
     printf("pageAccess failed\n");
     free(buf);
     exit(1);
    }
    if (abits != ((1 << 1) | (1 << 2) | (1 << 30)))
    {
     printf("Incorrect access bits set\n");
    } else {
     printf("pageAccess is working correctly\n");
    }
    free(buf);
    exit(0);
}
