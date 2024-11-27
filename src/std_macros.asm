STDIN  = 0
STDOUT = 1
STDERR = 2

macro syscall0 op {
    mov rax, op
    syscall
}

macro syscall1 op, arg0 {
    mov rdi, arg0
    mov rax, op
    syscall
}

macro syscall2 op, arg0, arg1 {
    mov rdi, arg0
    mov rsi, arg1
    mov rax, op
    syscall
}

macro syscall3 op, arg0, arg1, arg2 {
    mov rdi, arg0
    mov rsi, arg1
    mov rdx, arg2
    mov rax, op
    syscall
}

macro syscall4 op, arg0, arg1, arg2, arg3 {
    mov rdi, arg0
    mov rsi, arg1
    mov rdx, arg2
    mov r10, arg3
    mov rax, op
    syscall
}

macro read fd, buf, count {
    syscall3 0, fd, buf, count
}

macro write fd, buf, count {
    syscall3 1, fd, buf, count
}

macro open filename, flags, mode {
    syscall3 2, filename, flags, mode
}

macro close fd {
    syscall1 3, fd
}

macro fstat fd, statbuf {
    syscall2 5, fd, statbuf
}

macro rt_sigaction fd, act, oldact, sigsetsize = 8 { ; sizeof(sigset_t) = 8
    syscall4 13, fd, act, oldact, sigsetsize
}

macro socket domain, type, protocol {
    syscall3 41, domain, type, protocol
}

macro accept sockfd, addr, addrlen {
    syscall3 43, sockfd, addr, addrlen
}

macro shutdown sockfd, how {
    syscall2 48, sockfd, how
}

macro bind sockfd, sockaddr, addrlen {
    syscall3 49, sockfd, sockaddr, addrlen
}

macro listen sockfd, backlog {
    syscall2 50, sockfd, backlog
}

macro exit exit_code {
    syscall1 60, exit_code
}
