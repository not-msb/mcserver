AF_INET = 2
SOCK_STREAM = 1
SHUT_RDWR = 2

struc sockaddr_in family, port, addr {
    .sin_family dw family
    .sin_port   dw port
    .sin_addr   dd addr
    .sin_zeros  dq 0
}
