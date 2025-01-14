#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <arpa/inet.h>

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

void send_board(int sockfd, struct sockaddr_in* client1, struct sockaddr_in* client2, socklen_t addr_len) {
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

    sendto(sockfd, board_str, strlen(board_str), 0, (struct sockaddr*)client1, addr_len);
    sendto(sockfd, board_str, strlen(board_str), 0, (struct sockaddr*)client2, addr_len);
}

char buffer[BUFFER_SIZE];
char message[BUFFER_SIZE];

int ask_play_again(int sockfd, struct sockaddr_in* client, socklen_t addr_len) {
    memset(buffer, '\0', sizeof(buffer));
    memset(message, '\0', sizeof(message));
    strcpy(message, "Do you want to play? (yes/no): ");
    sendto(sockfd, message, strlen(message), 0, (struct sockaddr*)client, addr_len);
    
    recvfrom(sockfd, buffer, sizeof(buffer), 0, (struct sockaddr*)client, &addr_len);
    
    if (strstr(buffer, "yes"))
        return 1;
    else
        return 0;
}

int closed = 0;

void handle_client(int sockfd, struct sockaddr_in* client1, struct sockaddr_in* client2, socklen_t addr_len) {
    int game_over = 0;
    int player_turn = 0;
    int p1 = ask_play_again(sockfd, client1, addr_len);
    int p2 = ask_play_again(sockfd, client2, addr_len);
    
    if (!(p1 && p2)) {
        char arr[100] = {0};
        strcpy(arr, "OPPONENT DOES NOT WANT TO PLAY\n");
        if (p1 && !p2) {
            sendto(sockfd, arr, strlen(arr), 0, (struct sockaddr*)client1, addr_len);
        } else if (!p1 && p2) {
            sendto(sockfd, arr, strlen(arr), 0, (struct sockaddr*)client2, addr_len);
        }
        closed = 1;
        return;
    }

    initialize_board();
    send_board(sockfd, client1, client2, addr_len);
    int k = 0;
    while (!game_over) {     
        memset(buffer, '\0', sizeof(buffer));   
        struct sockaddr_in* current_client = player_turn == 0 ? client1 : client2;
        char symbol = player_turn == 0 ? 'X' : 'O';
        int row, col;

        while (1) {
            memset(buffer, '\0', sizeof(buffer));
            sendto(sockfd, "Your move (row col): ", 21, 0, (struct sockaddr*)current_client, addr_len);
            recvfrom(sockfd, buffer, BUFFER_SIZE, 0, (struct sockaddr*)current_client, &addr_len);

            row = buffer[0] - '0';
            col = buffer[1] - '0';
            if (row < 1 || row > 3 || col < 1 || col > 3 || board[row-1][col-1] != ' ') {
                sendto(sockfd, "Invalid move. Try again.\n", 25, 0, (struct sockaddr*)current_client, addr_len);
                continue;
            } else
                break;
        }

        board[row-1][col-1] = symbol;
        moves_count++;
        send_board(sockfd, client1, client2, addr_len);

        if (check_winner(symbol)) {
            char win_message[50];
            sprintf(win_message, "Player %d wins!\n", player_turn == 0 ? 1 : 2);
            sendto(sockfd, win_message, strlen(win_message), 0, (struct sockaddr*)client1, addr_len);
            sendto(sockfd, win_message, strlen(win_message), 0, (struct sockaddr*)client2, addr_len);
            game_over = 1;
        } else if (check_draw()) {
            sendto(sockfd, "It's a draw!\n", 13, 0, (struct sockaddr*)client1, addr_len);
            sendto(sockfd, "It's a draw!\n", 13, 0, (struct sockaddr*)client2, addr_len);
            game_over = 1;
        } else {
            player_turn = (player_turn + 1) % 2;
        }
    }
}

int main() {
    int sockfd;
    struct sockaddr_in server_addr, client1, client2;
    socklen_t addr_len = sizeof(struct sockaddr_in);
    char buffer[BUFFER_SIZE] = {0};

    if ((sockfd = socket(AF_INET, SOCK_DGRAM, 0)) < 0) {
        perror("Socket creation failed");
        exit(EXIT_FAILURE);
    }

    memset(&server_addr, 0, sizeof(server_addr));
    server_addr.sin_family = AF_INET;
    server_addr.sin_addr.s_addr = INADDR_ANY;
    server_addr.sin_port = htons(PORT);

    if (bind(sockfd, (struct sockaddr*)&server_addr, sizeof(server_addr)) < 0) {
        perror("Bind failed");
        close(sockfd);
        exit(EXIT_FAILURE);
    }

    printf("Waiting for Player 1...\n");
    recvfrom(sockfd, buffer, BUFFER_SIZE, 0, (struct sockaddr*)&client1, &addr_len);
    printf("Player 1 connected!\n");

    printf("Waiting for Player 2...\n");
    recvfrom(sockfd, buffer, BUFFER_SIZE, 0, (struct sockaddr*)&client2, &addr_len);
    printf("Player 2 connected!\n");

    while (1) {
        handle_client(sockfd, &client1, &client2, addr_len);
        if (closed) {
            char brr[]="exit";
            sendto(sockfd,brr,strlen(brr),0,(struct sockaddr*)&client1,addr_len);
            sendto(sockfd,brr,strlen(brr),0,(struct sockaddr*)&client2,addr_len);
            break;
        }
    }

    close(sockfd);
    return 0;
}
