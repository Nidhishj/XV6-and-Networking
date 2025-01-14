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
    socklen_t addr_len = sizeof(serv_addr);
    char buffer[BUFFER_SIZE] = {0};
    char message[BUFFER_SIZE] = {0};

    // Create socket
    if ((sock = socket(AF_INET, SOCK_DGRAM, 0)) < 0) {
        printf("\n Socket creation error \n");
        return -1;
    }

    // Set server address information
    serv_addr.sin_family = AF_INET;
    serv_addr.sin_addr.s_addr = inet_addr(argv[1]);  // Use the passed IP address
    serv_addr.sin_port = htons(PORT);

    // Send connection message
    char connect[100] = {0};
    strcpy(connect, "connect");
    sendto(sock, connect, strlen(connect), 0, (struct sockaddr*)&serv_addr, addr_len);

    while (1) 
    {
        // Clear buffer for receiving data
        memset(buffer, '\0', sizeof(buffer));

        // Receive data from server
        recvfrom(sock, buffer, sizeof(buffer), 0, (struct sockaddr*)&serv_addr, &addr_len);

        // Check for exit condition
        if (strstr(buffer, "exit"))
        {
            if (strlen(buffer) > 4)  // Check if there is additional data with "exit"
            {
                buffer[strlen(buffer)-4] = '\0';  // Trim "exit"
                printf("%s", buffer);
            }
            break;  // Exit the loop
        }

        // Print received message
        printf("%s", buffer);
        fflush(stdout);

        // Handle "Do you want to play?" prompt
        if (strstr(buffer, "Do"))
        {
            char arr[1000] = {0};
            fgets(arr, sizeof(arr), stdin);  // Get the player's response from stdin
            sendto(sock, arr, strlen(arr), 0, (struct sockaddr*)&serv_addr, addr_len);  // Send response
        }
        // Handle move input ("Your move" prompt)
        else if (strstr(buffer, "Your"))
        {
            int row, col;
            char input[100];

            // Get a valid move from the player
            while (1) {
                memset(input, '\0', sizeof(input));
                fgets(input, sizeof(input), stdin);

                if (sscanf(input, "%d %d", &row, &col) == 2) {
                    // Valid input (two numbers)
                    break;
                } else {
                    printf("Invalid input. Please enter two numbers (e.g., 1 2):");
                }
            }

            // Format and send the move to the server
            char arr[3] = {0};
            arr[0] = '0' + row;  // Convert the row number to a character
            arr[1] = '0' + col;  // Convert the column number to a character
            sendto(sock, arr, strlen(arr), 0, (struct sockaddr*)&serv_addr, addr_len);
        }
    }

    return 0;
}
