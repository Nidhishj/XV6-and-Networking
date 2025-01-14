#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <arpa/inet.h>
#include <unistd.h>
#include <fcntl.h>
#include <sys/time.h>
#include <sys/select.h>

#define SERVER_IP "127.0.0.1" // Update this to your server's IP if needed
#define PORT 8080
#define BUFFER_SIZE 1024
#define CHUNK_SIZE 5
#define TIMEOUT_SEC 0.1

typedef struct message
{
    int num;
    int total;//implement this much better
    char arr[10];
} msg;

double time_diff(struct timeval start, struct timeval end) {
    double start_sec = start.tv_sec + start.tv_usec / 1000000.0;
    double end_sec = end.tv_sec + end.tv_usec / 1000000.0;
    return end_sec - start_sec;
}

void make_nonblocking(int sockfd)
{
    int flags = fcntl(sockfd, F_GETFL, 0);
    fcntl(sockfd, F_SETFL, flags | O_NONBLOCK);
    printf("CREATED");
}
int main(int argc, char* argv[])
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
    int sockfd;
    char buffer[BUFFER_SIZE];
    struct sockaddr_in server_addr;
    socklen_t addr_len = sizeof(server_addr);

    // Create socket
    if ((sockfd = socket(AF_INET, SOCK_DGRAM, 0)) < 0)
    {
        perror("socket creation failed");
        exit(EXIT_FAILURE);
    }

    memset(&server_addr, 0, sizeof(server_addr));
    // memset(&client_addr, 0, sizeof(client_addr));

    // Bind server address
    server_addr.sin_family = AF_INET;
    server_addr.sin_addr.s_addr = INADDR_ANY;
    server_addr.sin_port = htons(PORT);
    server_addr.sin_addr.s_addr=inet_addr(argv[1]);
    // Set socket to non-blocking mode
     char arr[100]={0};
    bzero(arr,100);
    // strcpy(arr,"connect");
    printf("sending\n");
    int n =sendto(sockfd, arr, strlen(arr), 0, (struct sockaddr*)&server_addr, addr_len);
    if (n < 0) {
    perror("[-]sendto error");
    close(sockfd);
    exit(1);
  }
  printf("SENT\n");
    make_nonblocking(sockfd);
    int k = 0;
    while (1)
    {
        if ((k % 2))
        {
            // means server will send message
            char data[4096] = {0};
            printf("MESSAGE: ");
            fgets(data,sizeof(data),stdin);
            data[strcspn(data, "\n")] = 0;
            msg chunks_arr[5000];
            int data_len = strlen(data);
            // int p = 0;
            int chunks = (data_len + CHUNK_SIZE - 1) / CHUNK_SIZE;
            struct timeval sent_times[chunks];
            for (int i = 0; i < chunks; i++)
            {
                int offset = i * CHUNK_SIZE;
                int length = (data_len - offset > CHUNK_SIZE) ? CHUNK_SIZE : data_len - offset;
                chunks_arr[i].num = i;
                chunks_arr[i].total=chunks;
                memset(chunks_arr[i].arr, '\0', CHUNK_SIZE + 2);
                gettimeofday(&sent_times[i],NULL);
                strncpy(chunks_arr[i].arr, &data[offset], length);
                // if(i%3==0)
                // continue;
                sendto(sockfd, &chunks_arr[i], sizeof(msg), 0, (const struct sockaddr *)&server_addr, addr_len);
                printf("Sent chunk %d: %.*s\n", i, length, &data[offset]);
                // p++;
            }
            //all messages sent now will check for acknowledgments
            fd_set readfds;
            struct timeval timeout;
            int ack_rec[chunks];
            memset(ack_rec,0,sizeof(ack_rec));
            int recv=0;
            while (1)
            {
                // Initialize the fd_set
                FD_ZERO(&readfds);
                FD_SET(sockfd, &readfds);
                timeout.tv_sec = TIMEOUT_SEC;
                timeout.tv_usec = 0;
                int activity = select(sockfd + 1, &readfds, NULL, NULL, &timeout);
                if (activity < 0)
                {
                    perror("select error");
                }
                else if (activity == 0)
                    // Timeout - no data received
                    // printf("Timeout - No data received.\n");
                {
                    // int lengt = (data_len - offset > CHUNK_SIZE) ? CHUNK_SIZE : data_len - offset;
                    if(recv==chunks)
                    break;
                    for(int i=0;i<chunks;i++)
                    {
                        if(!ack_rec[i])
                        {
                            struct timeval current_time;
                            // gettimeofday(&current_time, NULL);
                            gettimeofday(&current_time, NULL);
                            double time_elapsed = time_diff(sent_times[i], current_time);
                            if(time_elapsed<0.1)
                            continue;
                            int offset = i * CHUNK_SIZE;
                            int length = (data_len - offset > CHUNK_SIZE) ? CHUNK_SIZE : data_len - offset;
                                                        gettimeofday(&sent_times[i],NULL);

                            sendto(sockfd, &chunks_arr[i], sizeof(msg), 0, (const struct sockaddr *)&server_addr, addr_len);
                            printf("RETRANSMIT chunk %d: %.*s\n", i, length, &data[offset]);
                        }
                    }
                }
                else
                {

                    // Data is available on the socket
                    int q=0;
                    if (FD_ISSET(sockfd, &readfds))
                    {
                        
                        int len = recvfrom(sockfd, &q, sizeof(int), 0, (struct sockaddr *)&server_addr, &addr_len);
                        if (len > 0)
                        {
                            printf("ACK recieved : %d\n",q);
                            fflush(stdout);
                            if(!ack_rec[q])
                            recv++;
                            ack_rec[q]=1;
                        }
                        if(recv==chunks)
                        break;
                    }
                }

            }
            k++;
        }
        else
        {
            fd_set readfds;
            struct timeval timeout;
            // int timeout_count = 0; // Counter to track consecutive timeouts
            // means u will keep on reciving code
            msg received_msg;
            char full_message[4096] = {0}; // To hold the complete message
            int expected_chunks = 0;       // Number of expected chunks
            int received_chunks = 0;       // Keep track of chunks received
            int chunk_ids[5000] = {0};     // Track which chunks have been received
            while (1)
            {
                // Initialize the fd_set
                FD_ZERO(&readfds);
                FD_SET(sockfd, &readfds);
                timeout.tv_sec = TIMEOUT_SEC;
                timeout.tv_usec = 0;
                int activity = select(sockfd + 1, &readfds, NULL, NULL, &timeout);
                if (activity < 0)
                {
                    perror("select error");
                }
                else if (activity == 0)
                {
                    // Timeout - no data received
                    // printf("Timeout - No data received.\n");
                }
                else
                {

                    // Data is available on the socket
                    if (FD_ISSET(sockfd, &readfds))
                    {
                        memset(&received_msg,0,sizeof(received_chunks));
                        int len = recvfrom(sockfd, &received_msg, sizeof(msg), 0, (struct sockaddr *)&server_addr, &addr_len);
                        if (len > 0)
                        {
                            printf("Received chunk %d: %s\n", received_msg.num, received_msg.arr);

                            // Save the chunk in the correct place in the full_message
                            expected_chunks=received_msg.total;
                            int offset = received_msg.num * CHUNK_SIZE;
                            strncpy(&full_message[offset], received_msg.arr, CHUNK_SIZE);

                            // Mark the chunk as received
                            chunk_ids[received_msg.num] = 1;
                            received_chunks++;

                            // Send an ACK for the received chunk
                            sendto(sockfd, &received_msg.num, sizeof(int), 0, (struct sockaddr *)&server_addr, addr_len);
                            printf("ACK sent for chunk %d\n", received_msg.num);
                        }

                        // After receiving all expected chunks, print the full message
                        if (received_chunks == expected_chunks)
                        {
                            full_message[received_chunks * CHUNK_SIZE] = '\0'; // Null-terminate the string
                            printf("Complete message received: %s\n", full_message);
                            break;
                        }
                    }
                }
            }
            k++;
        }
    }
}
