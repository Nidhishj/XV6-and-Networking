## General 
```
XV6 report - report
```

## XV6
Details in the report file check from there 

#### To Run 
To run it do `make clean` then `make qemu SCHEDULER=LBS` (LBS for eg)

For MLFQ - MLFQ 


For RR - RR 

If nothing mentioned RR would be set as default.

Added files - user/syscount.c (for spec 1)


Number of CPU - 1 (initially can be changed)


## NETWORKING 

### PART A XO 

#### TCP IMPLEMENTATION 

Codes-
```
Server - server-tcp2.c
Client - client-tcp2.c
```

for diff ip - after making executable fro client give it is a input to ./a.out `IP` or else `127.0.0.1` would be taken if nothing is mentioned.

Note - there will be no message sending by server only exit is by either of client saying no when asked to play.
`Also even when clients connect for first time they are asked whether they want to play or not (reason for asking - they might have connected mistakenly)`

#### UDP IMPLEMENTATION 
Codes-
```
Server - udp_server_final.c
Client - udp_client_final.c
```

for diff ip - after making executable fro client give it is a input to ./a.out `IP` or else `127.0.0.1` would be taken if nothing is mentioned.

Note - there will be no message sending by server only exit is by either of client saying no when asked to play.

### PART B TCP WITH HELP OF UDP

```
Codes - 
server - fake_server.c
client - fake_client.c
```
Here two things are present server and client which send and recieve acknowledgments with the use of **NON BLOCKING SOCKETS**
for diff ip - after making executable fro client give it is a input to ./a.out `IP` or else `127.0.0.1` would be taken if nothing is mentioned.

Note - there is no exit message check something like that as it was not asked to be implemented so it should not incurr any penalty (_/\\_) (just press `Ctrl + C` 




### COW XV6 

This is another implementation of XV6 where Copy On Write was implemeneted in which a new process would not create new pages in memory untill and unless someone writes to it. (i.e -> A page is shared between different processes)


### LAZY READ WRITE 

This was a task where we are given input of the time to read , write and delete and the time at which different requests come to us. Where we have to stimulate the given instructions in real time along with some restrictions. This utilised the concepts of threads and locks.
