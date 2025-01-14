#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"


int main(int argc, char *argv[])
{
    char *syscalls[] = {
    "fork",//0
    "exit",
    "wait",//2
    "pipe",
    "read",//4
    "kill",
    "exec",//6
    "fstat",
    "chdir",//8
    "dup",
    "getpid",//10
    "sbrk",
    "sleep",//12
    "uptime",
    "open",//14
    "write",
    "mknod",//16
    "unlink",
    "link",//18
    "mkdir",
    "close",//20
    "waitx",
    "getSysCount"//22
    };
    if(argc<3)
    {
        printf("Invalid Format\n");
        return -1;
    }
    // for(int i=0;i<argc;i++)
    // {
    //     if(argv[i])
    //     printf("%s",argv[i]);
    //     else
    //     printf("NULL");
    // }
    int p  = fork();
    if(p<0)
    {
        printf("fork");
        return -1;
    }
    else if(p==0)
    {
     exec(argv[2],argv+2);
     printf("Exec failed");
     exit(1);
    }
    else
    {
        wait(0);
        int l = atoi(argv[1]); 
        int k = -1 ;
        while (l)
        {
            l/=2;
            k++;
        }   
        printf("PID %d called %s %d times.\n",p,syscalls[k-1],getSysCount(k-1));    
    }
    return 0;
}
