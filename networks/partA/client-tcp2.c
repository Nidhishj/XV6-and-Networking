#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>

#define PORT 8080
#define BUFFER_SIZE 1024

char buffer[BUFFER_SIZE];
char message[BUFFER_SIZE];

int main(int argc,char* argv[])
{
    if(argc!=2&&argc!=1)
    {
        printf("Invalid\n");
        return -1;
    }
    if(argc==1)
    {
        argv[1]="127.0.0.1";
    }
    int sock = 0;
    struct sockaddr_in serv_addr;
    char buffer[BUFFER_SIZE] = {0};
    char message[BUFFER_SIZE] = {0};
    if ((sock = socket(AF_INET, SOCK_STREAM, 0)) < 0) {
        printf("\n Socket creation error \n");
        return -1;
    }
    serv_addr.sin_family = AF_INET;
    serv_addr.sin_port = htons(PORT);
    if (inet_pton(AF_INET, argv[1], &serv_addr.sin_addr) <= 0) {
        printf("\nInvalid address / Address not supported \n");
        return -1;
    }
    if (connect(sock, (struct sockaddr *)&serv_addr, sizeof(serv_addr)) < 0) {
        printf("\nConnection Failed \n");
        return -1;
    }
    // send(sock,"Hi",2,0);
    while (1) 
    {
        memset(buffer,'\0',sizeof(buffer));
        recv(sock,buffer,sizeof(buffer),0);
        if(strstr(buffer,"exit"))
        {
            if(strlen(buffer)>4)
            {
                buffer[strlen(buffer)-4]='\0';
                printf("%s",buffer);
            }
            break;
        }
        printf("%s",buffer);
        fflush(stdout);
        if(strstr(buffer,"Do"))
        {char arr[1000]={0};
        fgets(arr, sizeof(arr), stdin);
        send(sock,arr,strlen(arr),0);
        }         
        else if(strstr(buffer,"Your"))
        {
        int row,col;
        char input[100];
         while (1) {
            memset(input,'\0',sizeof(input));
                fgets(input, sizeof(input), stdin);
                if (sscanf(input, "%d %d", &row, &col) == 2) {
                    break;  // Valid input, break out of the loop
                } else {
                    printf("Invalid input. Please enter two numbers (e.g., 1 2):");
                }
            }
        char arr[3]={0};
        arr[0]='0'+row;
        arr[1]='0'+col;
        send(sock,arr,strlen(arr),0);
        }
    }
return 0;
}