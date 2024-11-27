format ELF64
public main

include "std_macros.asm"
include "socket.asm"
include "signal.asm"

MAX_CONN = 32

section ".text" executable
main:
.initCtrlC:
    rt_sigaction SIGINT, act, 0

.initSocket:
    socket AF_INET, SOCK_STREAM, 0
    mov [server.socket], rax

    bind   [server.socket], server.address, 16
    listen [server.socket], MAX_CONN

.initFile:
    open response.name, 0, 0
    mov [response.fd], rax

    fstat [response.fd], response.stat
.acceptConnection:
    accept [server.socket], 0, 0
    mov [server.connection], rax

.ignoreRequests:
    read [server.connection], buffer, 16384
    read [server.connection], buffer, 16384

.calculateJsonLength:
    ; Getting the length of the varint of the json-string length
    ; Very weird ik
    mov rcx, [writer.offset]
    mov rdi, writer
    mov rsi, qword [response.stat+48] ; offsetof(struct stat, st_size) = 48
    call writeVarInt

    sub [writer.offset], rcx
    mov rcx, [writer.offset]
    mov [writer.offset], 0

.writeResponsePrefix:
    mov rdi, writer
    mov rsi, qword [response.stat+48]   ; st_size
    add rsi, rcx                    ; json-length length
    add rsi, 1                      ; packet ID length
    call writeVarInt

    mov rdi, writer
    mov rsi, 0  ; packet ID
    call writeVarInt

    mov rdi, writer
    mov rsi, qword [response.stat+48]
    call writeVarInt

.writeResponseBody:
    mov rsi, buffer
    add rsi, [writer.offset]
    read [response.fd], rsi, qword [response.stat+48]

.sendResponse:
    mov rdx, [writer.offset]
    add rdx, qword [response.stat+48]
    write [server.connection], buffer, rdx

.pingPongResponse:
    read [server.connection], buffer, 16384
    write [server.connection], buffer, rax

.redo:
    close [response.fd]
    ;close [server.connection]
    jmp .initFile

.closeSocket:
    close [response.fd]
    shutdown [server.socket], SHUT_RDWR
.emptySocketRead:
    read [server.connection], buffer, 16384
    cmp rax, 0
    jne .emptySocketRead

    close [server.connection]
    close [server.socket]

    exit 0

struc Reader buffer, offset {
    .buffer dq buffer ; []const u8
    .offset dq offset ; usize
}

struc Writer buffer, offset {
    .buffer dq buffer ; []u8
    .offset dq offset ; usize
}

; TODO: Remind yourself that readVarInt and writeVarInt are *BAD* implementations

; TODO TODO TODO: you need to use u32 dummy
; readVarInt(&Reader) u64
; rax, rcx, rdx, rdi, rsi
readVarInt:
; rax: value
; rcx: position
; rdx: currentByte

    xor rax, rax
    xor rcx, rcx
    mov rsi, [rdi]
    add rsi, [rdi+8]
.checkLast:
    movzx rdx, byte [rsi]
    cmp rdx, 0x80
    jl .last
.next:
    and rdx, 0x7f
    shl rdx, cl
    or rax, rdx

    add rsi, 1
    add rcx, 7
    jmp .checkLast
.last:
    and rdx, 0x7f
    shl rdx, cl
    or rax, rdx

    add rsi, 1
    sub rsi, [rdi]
    mov [rdi+8], rsi
    ret

; writeByte(&Writer, u8)
writeByte:
    mov rax, [rdi]
    add rax, [rdi+8]
    mov byte [rax], sil
    add qword [rdi+8], 1
    ret

; writeVarInt(&Writer, u32)
writeVarInt:
    cmp esi, 0x80
    jl .done
.next:
    mov edx, esi
    or esi, 0x80
    call writeByte
    mov esi, edx
    sar esi, 7
    jmp writeVarInt
.done:
    call writeByte
    ret

; testing function wrapper here
; will hopefully make my life easier

;macro wrapperCall2 function {
;    macro function arg0, arg1 \{
;        mov rdi, arg0
;        mov rsi, arg0
;        call function
;    \}
;}

; Yes the reserve instructions dont work
; I just use em here becauze im lazyyy
section ".data" writable
response:
    .name db "response.json", 0
    .stat rb 144
    .fd   rq 1

server:
    .address sockaddr_in AF_INET, 36895, 0 ; htons(8080) & INADDR_ANY
    ;.address sockaddr_in AF_INET, 16415, 0 ; htons(8000) & INADDR_ANY
    .socket     rq 1
    .connection rq 1

act sigaction main.closeSocket, ?, ?, ?
reader Reader buffer, 0
writer Writer buffer, 0

section ".bss" writable
buffer rb 16384
