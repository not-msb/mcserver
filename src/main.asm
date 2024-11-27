format ELF64 executable
entry main

include "std_macros.asm"
include "socket.asm"

MAX_CONN = 32

segment readable executable
main:
    ; Initializing socket
    socket AF_INET, SOCK_STREAM, 0
    mov [socket_fd], rax

    bind   [socket_fd], server_addr, 16
    listen [socket_fd], MAX_CONN

    accept [socket_fd], client_addr, client_addrlen
    mov [conn_fd], rax
    ; done initialzing

    ; Reading requests and ignoring them lol
    read [conn_fd], resp_buffer, 16384
    mov [length], rax
    write STDOUT, resp_buffer, [length]

    read [conn_fd], resp_buffer, 16384
    mov [length], rax
    write STDOUT, resp_buffer, [length]
    ; done reading

    ; Opening response.json
    open filename, 0, 0
    mov [file_fd], rax

    fstat [file_fd], file_stat
    ; done opening

    ; Getting the length of the varint of the json-string length
    ; Very weird ik
    mov rcx, [writer.offset]
    mov rdi, writer
    mov rsi, qword [file_stat+48] ; offsetof(struct stat, st_size) = 48
    call writeVarInt

    sub [writer.offset], rcx
    mov rcx, [writer.offset]
    mov [writer.offset], 0
    ; done getting the length

    ; Writing the full prefix now
    mov rdi, writer
    mov rsi, qword [file_stat+48]   ; st_size
    add rsi, rcx                    ; json-length length
    add rsi, 1                      ; packet ID length
    call writeVarInt

    mov rdi, writer
    mov rsi, 0  ; packet ID
    call writeVarInt

    mov rdi, writer
    mov rsi, qword [file_stat+48]
    call writeVarInt
    ; done writing the full prefix

    ; Writing the json now
    mov rsi, resp_buffer
    add rsi, [writer.offset]
    read [file_fd], rsi, qword [file_stat+48]
    ; done writing the json

    ; Sending response
    mov rdx, [writer.offset]
    add rdx, qword [file_stat+48]
    write [conn_fd], resp_buffer, rdx
    ; done sending

    read [conn_fd], resp_buffer, 16384
    mov [length], rax
    write [conn_fd], resp_buffer, [length]

    ;write STDOUT, newline, 1

    close [file_fd]

    ; Correctly closing the socket
    shutdown [socket_fd], SHUT_RDWR
.emptySocketRead:
    read [conn_fd], resp_buffer, 16384
    cmp rax, 0
    jne .emptySocketRead

    close [conn_fd]
    close [socket_fd]
    ; done closing

    exit 0


struc Reader buffer, offset {
    .buffer dq buffer ; []const u8
    .offset dq offset ; usize
}

struc Writer buffer, offset {
    .buffer dq buffer ; []u8
    .offset dq offset ; usize
}

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

;macro wrapperCall2 function {
;    macro function arg0, arg1 \{
;        mov rdi, arg0
;        mov rsi, arg0
;        call function
;    \}
;}

segment readable writable
socket_fd rq 1
conn_fd rq 1
file_fd rq 1

length rq 1

filename db "response.json"
file_stat rb 144

client_addr rb 16
client_addrlen dq 16
server_addr sockaddr_in AF_INET, 36895, 0 ; 8080 & INADDR_ANY
;server_addr sockaddr_in AF_INET, 16415, 0 ; 8000 & INADDR_ANY

resp_buffer rb 16384

reader Reader resp_buffer, 0
writer Writer resp_buffer, 0
