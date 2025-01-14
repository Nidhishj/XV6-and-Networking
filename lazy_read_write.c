#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <pthread.h>
#include <unistd.h>
#include <time.h>

#define MAX_REQUEST 100007

typedef struct {
    int request_id;
    int user_id;
    int file_id;
    int operation;
    int request_time;
} Request;

char* YELLOW="\033[1;33m";
char* RESET="\033[0m";
char* RED = "\033[1;31m";
char* GREEN = "\033[1;32m";
char* WHITE = "\033[1;37m";
char* PINK = "\033[1;35m";

typedef struct RequestNode {
    Request request;
    struct RequestNode *next;
} RequestNode;

typedef struct {
    RequestNode *front;
    RequestNode *rear;
    pthread_mutex_t queue_lock;
} RequestQueue;

typedef struct {
    int file_id;
    int is_deleted;
    int active_readers;
    int active_writers;
    pthread_mutex_t file_lock;
    RequestQueue request_queue_read;
    RequestQueue request_queue_write;
    RequestQueue request_queue_delete;
}File;

Request requests[MAX_REQUEST];
File* files;  


int compare_requests(const void *a, const void *b) {
    Request *reqA = (Request *)a;
    Request *reqB = (Request *)b;

    // Compare by request_time
    if (reqA->request_time != reqB->request_time) {
        return reqA->request_time - reqB->request_time;
    }

    // If request_time is the same, compare by operation priority (lower value = higher priority)
    
    return reqA->operation - reqB->operation;
}

int r,w,d,n,c,T;
int start_time;
void enqueue(RequestQueue *queue, Request request) {
    RequestNode *new_node = (RequestNode *)malloc(sizeof(RequestNode));
    new_node->request = request;
    new_node->next = NULL;
    pthread_mutex_lock(&queue->queue_lock);
    if (queue->rear == NULL) {
        queue->front = queue->rear = new_node;
    } else {
        queue->rear->next = new_node;
        queue->rear = new_node;
    }
    pthread_mutex_unlock(&queue->queue_lock);
}

Request dequeue(RequestQueue *queue) {
    pthread_mutex_lock(&queue->queue_lock);
    if (queue->front == NULL) {
        pthread_mutex_unlock(&queue->queue_lock);
        return (Request){-1, -1, -1, -1}; // Return an invalid request
    }
    RequestNode *temp = queue->front;
    Request request = temp->request;
    queue->front = queue->front->next;
    if (queue->front == NULL) {
        queue->rear = NULL;
    }
    free(temp);
    pthread_mutex_unlock(&queue->queue_lock);
    return request;
}


void remove_invalid_requests(RequestQueue *queue, int timeout) {
    pthread_mutex_lock(&queue->queue_lock);
    time_t current_time =   (int)time(NULL);
    current_time-=start_time;
    while (queue->front != NULL) {
        RequestNode *front_node = queue->front;
        Request request = front_node->request;
        
        // Check if the request has timed out
        if (current_time - request.request_time >= timeout) {
            // printf("%sUser %d canceled the request due to no response at %d seconds%s\n", RED, request.user_id, current_time, RESET);

            // Remove the node from the front of the queue
            queue->front = queue->front->next;
            if (queue->front == NULL) {
                queue->rear = NULL; // If the queue is now empty, update rear
            }
            free(front_node);
        } else {
            // If the front node hasn't timed out, no need to check further
            break;
        }
    }

    pthread_mutex_unlock(&queue->queue_lock);
}

void* perform_request(void* arg)
{
    Request request = *(Request *)arg;
    File *file = &files[request.file_id];
            if(request.operation == 2) {
            // Delete operation
            int current=((int)time(NULL))-start_time;
            pthread_mutex_lock(&file->file_lock);
                if (file->is_deleted) {
                    printf("%sLAZY has declined the request of User %d at %d seconds because an invalid/deleted file was requested%s\n",
                        WHITE, request.user_id, current, RESET);
                    pthread_mutex_unlock(&file->file_lock);
                    return NULL;
                }
            pthread_mutex_unlock(&file->file_lock);
            enqueue(&file->request_queue_delete,request);
            int queued = 0; 
            // printf("%d",file->request_queue_delete.front->request.request_id);
            while(1) {
                if(queued==0)
                {
                    sleep(1);
                    queued=1;
                }
                else
                {sleep(0.5);}
                int current_time = ((int)time(NULL)) - start_time;
                if(current_time >= request.request_time + T) {
                    printf("%sUser %d canceled the request due to no response at %d seconds%s\n", 
                        RED, request.user_id, current_time, RESET);
                            
                    return NULL;
                }
                
                pthread_mutex_lock(&file->file_lock);
                if (file->is_deleted) {
                    printf("%sLAZY has declined the request of User %d at %d seconds because an invalid/deleted file was requested%s\n",
                        WHITE, request.user_id, current_time, RESET);
                    pthread_mutex_unlock(&file->file_lock);
                    return NULL;
                }
                remove_invalid_requests(&file->request_queue_read, T);
                remove_invalid_requests(&file->request_queue_write, T);
                remove_invalid_requests(&file->request_queue_delete,T);
                // printf(" front %d\n",file->request_queue_delete.front->request.request_id);
                pthread_mutex_lock(&file->request_queue_read.queue_lock);
                pthread_mutex_lock(&file->request_queue_write.queue_lock);
                pthread_mutex_lock(&file->request_queue_delete.queue_lock);
                if (file->active_readers == 0 && file->active_writers == 0 && 
                    (file->request_queue_read.front == NULL||file->request_queue_read.front->request.request_time==current_time||file->request_queue_delete.front->request.request_time<file->request_queue_read.front->request.request_time)
                    &&(file->request_queue_write.front == NULL||file->request_queue_write.front->request.request_time==current_time||file->request_queue_write.front->request.request_time>file->request_queue_delete.front->request.request_time)&&
                    file->request_queue_delete.front->request.request_id == request.request_id) {
                    file->is_deleted = 1;
                    printf("%sLAZY has taken up the request of User %d at %d seconds%s\n",
                        PINK, request.user_id, current_time, RESET);
                    pthread_mutex_unlock(&file->request_queue_delete.queue_lock);
                        // dequeue(&file->request_queue_delete);
                    pthread_mutex_unlock(&file->request_queue_write.queue_lock);
                    pthread_mutex_unlock(&file->request_queue_read.queue_lock);
                    pthread_mutex_unlock(&file->file_lock); 
                    sleep(d);
                    
                    current_time = (int)time(NULL) - start_time;
                    printf("%sThe request for User %d was completed at %d seconds%s\n", 
                        GREEN, request.user_id, current_time, RESET);

                    return NULL;
                }
                pthread_mutex_unlock(&file->request_queue_delete.queue_lock);
                pthread_mutex_unlock(&file->request_queue_read.queue_lock);
                pthread_mutex_unlock(&file->request_queue_write.queue_lock);
                pthread_mutex_unlock(&file->file_lock); 
            }   
        }
    else if(request.operation == 1) {
        // Write operation
        int current=((int)time(NULL))-start_time;
        pthread_mutex_lock(&file->file_lock);
            if (file->is_deleted) {
                printf("%sLAZY has declined the request of User %d at %d seconds because an invalid/deleted file was requested%s\n",
                    WHITE, request.user_id, current, RESET);
                pthread_mutex_unlock(&file->file_lock);
                return NULL;
            }
        pthread_mutex_unlock(&file->file_lock);
        int queued = 0; 
        enqueue(&file->request_queue_write, request);
        while(1) {
            sleep(1);
            //  if(queued==0)
            // {
            //     enqueue(&file->request_queue_delete,request);
            //     queued=1;
            // }
            int current_time = ((int)time(NULL)) - start_time;    
            if(current_time >= request.request_time + T) {
                printf("%sUser %d canceled the request due to no response at %d seconds%s\n",
                    RED, request.user_id, current_time, RESET);
                return NULL;
            }
            
            pthread_mutex_lock(&file->file_lock);
            if(file->is_deleted) {
                printf("%sLAZY has declined the request of User %d at %d seconds because an invalid/deleted file was requested%s\n",
                    WHITE, request.user_id, current_time, RESET);
                pthread_mutex_unlock(&file->file_lock);
                return NULL;
            }
            
            remove_invalid_requests(&file->request_queue_write, T);
            pthread_mutex_lock(&file->request_queue_write.queue_lock);
            if (file->request_queue_write.front != NULL &&
                file->request_queue_write.front->request.request_id == request.request_id &&
                file->active_writers == 0 && file->active_readers + file->active_writers < c) {
                file->active_writers++;
                    
                pthread_mutex_unlock(&file->request_queue_write.queue_lock);
                                dequeue(&file->request_queue_write);
                pthread_mutex_unlock(&file->file_lock);
                
                printf("%sLAZY has taken up the request of User %d at %d seconds%s\n", 
                    PINK, request.user_id, current_time, RESET);
                sleep(w);
                
                current_time = (int)time(NULL) - start_time;
                printf("%sThe request for User %d was completed at %d seconds%s\n", 
                    GREEN, request.user_id, current_time, RESET);

                pthread_mutex_lock(&file->file_lock);
                file->active_writers--;
                pthread_mutex_unlock(&file->file_lock);
                return NULL;
            }   
            pthread_mutex_unlock(&file->request_queue_write.queue_lock);
            pthread_mutex_unlock(&file->file_lock);
        }
    }
    else {
        // Read operation
        // printf("hi WE READING %d",request.request_id);
        // printf("%d\n",file->request_queue.front->request.request_id);
        int current=((int)time(NULL))-start_time;
        pthread_mutex_lock(&file->file_lock);
            if (file->is_deleted) {
                printf("%sLAZY has declined the request of User %d at %d seconds because an invalid/deleted file was requested%s\n",
                    WHITE, request.user_id, current, RESET);
                pthread_mutex_unlock(&file->file_lock);
                return NULL;
            }
        pthread_mutex_unlock(&file->file_lock);
                enqueue(&file->request_queue_read, request);
            // int queued=0;
        while(1) {
            sleep(1);
            // if(queued==0)
            // {
            //     enqueue(&file->request_queue_delete,request);
            //     queued=1;
            // }
            // printf("YES SLEPT %d\n",request.request_id);
            int current_time = ((int)time(NULL)) - start_time;
            
            if(current_time >= request.request_time + T) {
                printf("%sUser %d canceled the request due to no response at %d seconds%s\n",
                    RED, request.user_id, current_time, RESET);
                return NULL;
            }
            
            pthread_mutex_lock(&file->file_lock);
            if(file->is_deleted) {
                printf("%sLAZY has declined the request of User %d at %d seconds because an invalid/deleted file was requested%s\n",
                    WHITE, request.user_id, current_time, RESET);
                pthread_mutex_unlock(&file->file_lock);
                return NULL;
            }
            
            remove_invalid_requests(&file->request_queue_read, T);
            pthread_mutex_lock(&file->request_queue_read.queue_lock);
            // printf(" hmm %d\n",file->request_queue.front->request.request_id); 
            if (file->request_queue_read.front != NULL &&
                file->request_queue_read.front->request.request_id == request.request_id &&
                file->active_readers + file->active_writers < c) {
                file->active_readers++;
                pthread_mutex_unlock(&file->request_queue_read.queue_lock);
                                dequeue(&file->request_queue_read);
                pthread_mutex_unlock(&file->file_lock);
                
                printf("%sLAZY has taken up the request of User %d at %d seconds%s\n", 
                    PINK, request.user_id, current_time, RESET);
                sleep(r);
                
                current_time = (int)time(NULL) - start_time;
                printf("%sThe request for User %d was completed at %d seconds%s\n", 
                    GREEN, request.user_id, current_time, RESET);

                pthread_mutex_lock(&file->file_lock);
                file->active_readers--;  // Fixed: was decreasing writers instead of readers

                pthread_mutex_unlock(&file->file_lock);
                return NULL;
            }
            pthread_mutex_unlock(&file->request_queue_read.queue_lock);
            pthread_mutex_unlock(&file->file_lock);
        }
    }
}

int main()
{
    scanf("%d %d %d\n", &r, &w, &d);
    scanf("%d %d %d\n", &n, &c, &T);
    files = (File *)malloc((n+1) * sizeof(File));
    if(files==NULL)
    {
        printf("Memory allocation failed\n");
        return 0;
    }
    for(int i=0; i<n; i++) {
        files[i].file_id = i;
        files[i].is_deleted = 0;
        files[i].active_readers = 0;
        files[i].active_writers = 0;
        pthread_mutex_init(&files[i].file_lock, NULL);
        files[i].request_queue_read.front = files[i].request_queue_read.rear = NULL;
        files[i].request_queue_write.front = files[i].request_queue_write.rear = NULL;
        files[i].request_queue_delete.front = files[i].request_queue_delete.rear = NULL;
        pthread_mutex_init(&files[i].request_queue_read.queue_lock, NULL);
        pthread_mutex_init(&files[i].request_queue_write.queue_lock, NULL);
        pthread_mutex_init(&files[i].request_queue_delete.queue_lock, NULL);
    }
    int num_requests = 0;
    while(1)
    {
        char arr[1000];
        memset(arr,'\0',sizeof(arr));
        scanf("%[^\n]%*c",arr);
        if(strcmp(arr,"STOP")==0)
        break;
        char *token = strtok(arr, " ");
        requests[num_requests].request_id = num_requests;
        requests[num_requests].user_id = atoi(token);
        if(requests[num_requests].user_id<=0)
        {
            printf("INVALID INPUT\n");
            continue;
        }
        token = strtok(NULL, " ");
        requests[num_requests].file_id = atoi(token);
        if(requests[num_requests].file_id<=0||requests[num_requests].file_id>n)
        {
            printf("INVALID INPUT\n");
            continue;
        }
        token = strtok(NULL, " ");
        if(strcmp(token, "READ") == 0)
            requests[num_requests].operation = 0;
        else if(strcmp(token, "WRITE") == 0)
            requests[num_requests].operation = 1;
        else if(strcmp(token, "DELETE") == 0)
            requests[num_requests].operation = 2;
        else
        {
            printf("INVALID INPUT WILL NOT BE CONSIDERED\n");
            continue;
        }
        token = strtok(NULL, " ");
        int k = atoi(token);
        if(k<0)
        {
            printf("INVALID TIME WOULD NOT BE TAKEN\n");
            continue;
        }
        requests[num_requests].request_time = atoi(token);
        // printf("%d\n",requests[num_requests].request_time);
        num_requests++;
    }
    printf("LAZY has woken up!\n");
    pthread_t threads[num_requests];
    qsort(requests, num_requests, sizeof(Request), compare_requests);
    start_time=(int)time(NULL);
    sleep(requests[0].request_time);
        for (int i = 0; i < num_requests; i++) {

        char* arr[] = {"READ", "WRITE", "DELETE"};
        printf("%sUser %d has made the request for performing %s on file %d at %d seconds%s\n",
            YELLOW, requests[i].user_id, arr[requests[i].operation], 
            requests[i].file_id, requests[i].request_time, RESET);

        pthread_create(&threads[i], NULL, perform_request, (void*)&requests[i]);
        if(i<num_requests-1)
        sleep(requests[i+1].request_time-requests[i].request_time);
    }

    for(int i=0;i<num_requests;i++)
    {
        pthread_join(threads[i], NULL);
    }
    free(files);
      printf("LAZY has gone to sleep!\n");
return 0;
}