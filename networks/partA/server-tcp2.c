#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <asm-generic/socket.h>
#include <netinet/in.h>

#define PORT 8080
#define BUFFER_SIZE 1024

#define ROWS 3
#define COLS 3

char board[ROWS][COLS];
int moves_count = 0;

void initialize_board() {
    for (int i = 0; i < ROWS; i++) {
        for (int j = 0; j < COLS; j++) {
            board[i][j] = ' ';
        }
    }
    moves_count = 0;
}

int check_winner(char symbol) {
    for (int i = 0; i < ROWS; i++) {
        if (board[i][0] == symbol && board[i][1] == symbol && board[i][2] == symbol) return 1;
        if (board[0][i] == symbol && board[1][i] == symbol && board[2][i] == symbol) return 1;
    }
    if (board[0][0] == symbol && board[1][1] == symbol && board[2][2] == symbol) return 1;
    if (board[0][2] == symbol && board[1][1] == symbol && board[2][0] == symbol) return 1;
    return 0;
}

int check_draw() {
    return moves_count == 9;
}

void send_board(int client1, int client2) {
    char board_str[1024] = "";
    strcat(board_str, "\n");
    for (int i = 0; i < ROWS; i++) {
        char temp[100];
        sprintf(temp, " %c | %c | %c \n", board[i][0], board[i][1], board[i][2]);
        strcat(board_str, temp);
        if (i < ROWS - 1) {
            strcat(board_str, "---|---|---\n");
        }
    }
    strcat(board_str, "\n");

    send(client1, board_str, strlen(board_str), 0);
    send(client2, board_str, strlen(board_str), 0);
}


char buffer[BUFFER_SIZE];
char message[BUFFER_SIZE];

int ask_play_again(int client) {
    memset(buffer,'\0',sizeof(buffer));
    memset(message,'\0',sizeof(message));
    strcpy(message,"Do you want to play? (yes/no): ");
    send(client,message,strlen(message), 0);
    recv(client,buffer,sizeof(buffer)-1,0);
    printf("%s",buffer);
    fflush(stdout);
    if(strstr(buffer,"yes"))
    return 1;
    else 
    return 0;   
}

int closed =0;

void handle_client(int client1, int client2) {
    int game_over = 0;
    int player_turn = 0;
    int p1=ask_play_again(client1);
    int p2=ask_play_again(client2);
    if(!(p1&&p2))
    {   char arr[100]={0};
        strcpy(arr,"OPPONENT DOES NOT WANT TO PLAY\n");
        if(p1&&!p2)
        {
            send(client1,arr,strlen(arr),0);
        }
        else if(!p1&&p2)
        {
            send(client2,arr,strlen(arr),0);
        }
        closed=1;
        return;}
    initialize_board();
    send_board(client1,client2);
    int k = 0;
    while (!game_over) {     
        memset(buffer,'\0',sizeof(buffer));   
        int current_player = player_turn == 0 ? client1 : client2;
        char symbol = player_turn == 0 ? 'X' : 'O';
        int row, col;
        while (1)
        {
            /* code */
        memset(buffer,'\0',sizeof(buffer));
        send(current_player, "Your move (row col): ", 21, 0);
        recv(current_player, buffer, 1024, 0);
        // printf("%s",buffer);
        row=buffer[0]-'0';
        col=buffer[1]-'0';
        printf("ROW COL = %d %d\n",row,col);
        fflush(stdout);
        if (row < 1 || row > 3 || col < 1 || col > 3 || board[row-1][col-1] != ' ') {
            send(current_player, "Invalid move. Try again.\n", 25, 0);
            continue;
        }
        else
        break;
        }
        board[row-1][col-1] = symbol;
        moves_count++;
        send_board(client1, client2);
        if (check_winner(symbol)) {
            char win_message[50];
            sprintf(win_message, "Player %d wins!\n", player_turn == 0 ? 1 : 2);
            send(client1, win_message, strlen(win_message), 0);
            send(client2, win_message, strlen(win_message), 0);
            game_over = 1;
        } else if (check_draw()) {
            send(client1, "It's a draw!\n", 13, 0);
            send(client2, "It's a draw!\n", 13, 0);
            game_over = 1;
        } else {
            player_turn = (player_turn + 1) % 2;
        }
    }
}

int main()
{
    int server_fd, client1,client2;
    struct sockaddr_in address;
    int addrlen = sizeof(address);
    int opt=1;
    if ((server_fd = socket(AF_INET, SOCK_STREAM, 0)) == 0) {
        perror("Socket failed");
        exit(EXIT_FAILURE);
    }
    if (setsockopt(server_fd, SOL_SOCKET, SO_REUSEADDR|SO_REUSEPORT, &opt, sizeof(opt))) {
        perror("setsockopt failed");
        close(server_fd);
        exit(EXIT_FAILURE);
    }
    address.sin_family = AF_INET;
    address.sin_addr.s_addr = INADDR_ANY;
    address.sin_port = htons(PORT);
    if (bind(server_fd, (struct sockaddr *)&address, sizeof(address)) < 0) {
        perror("Bind failed");
        close(server_fd);
        exit(EXIT_FAILURE);
    }
    // Listeconnections
    if (listen(server_fd, 3) < 0) {
        perror("Listen failed");
        close(server_fd);
        exit(EXIT_FAILURE);
    }
    if ((client1 = accept(server_fd, (struct sockaddr *)&address, (socklen_t *)&addrlen)) < 0) {
        perror("Accept failed");
        close(server_fd);
        exit(EXIT_FAILURE);
    }
    printf("PLAYER 1 CONNECTED\n");
    // recv(client1,buffer,sizeof(buffer),0);
    // printf("%s\n",buffer);
    fflush(stdout);
    if ((client2 = accept(server_fd, (struct sockaddr *)&address, (socklen_t *)&addrlen)) < 0) {
        perror("Accept failed");
        close(server_fd);
        exit(EXIT_FAILURE);
    }
    printf("PLAYER 2 CONNECTED\n");
    fflush(stdout);
    // strcpy(message,"HIGH\n");
    // int first_one=1;
    while (1)
    {
        memset(buffer,'\0',sizeof(buffer));
        memset(message,'\0',sizeof(message));
        // first_one=(first_one==1)? 0 : 1;
        handle_client(client1, client2);
        if(closed)
        {
            char arr_exit[100]="exit";
            send(client1,arr_exit,strlen(arr_exit),0);
            send(client2,arr_exit,strlen(arr_exit),0);
            break;
        }
    }
}
