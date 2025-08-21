section .data
        ; This is the sockaddr_in structure for binding to an IP and port.
        socket_address:
                dw 2                    ; sin_family: AF_INET (IPv4)
                dw 0x901F               ; sin_port: 8080 (0x1F90), stored byte-swapped (big-endian).
        sin_addr: dd 0x00000000         ; sin_addr: INADDR_ANY (bind to any available IP 0.0.0.0)
        sin_zero: dq 0                  ; 8 bytes of padding, must be zero.

        ; Calculate the length of the structure automatically.
        saddress_len equ $ - socket_address

        ; variable of true for setsockopt.
        socket_on: dd 1

        ; Syscall Error Messages
        socket_err_msg db 'Error: Could not create socket.', 0x0a
        socket_err_len equ $ - socket_err_msg

        bind_err_msg db 'Error: Could not bind to port 8080.', 0x0a
        bind_err_len equ $ - bind_err_msg

        listen_err_msg db 'Error: Could not listen on socket.', 0x0a
        listen_err_len equ $ - listen_err_msg

        accept_err_msg db 'Error: Could not accept new connection.', 0x0a
        accept_err_len equ $ - accept_err_msg

        fork_err_msg db 'Error: Could not fork new process.', 0x0a
        fork_err_len equ $ - fork_err_msg

        ; Method prints in server

        get_msg db 'processing get request.', 0x0a
        get_len equ $ - get_msg

        post_msg db 'processing post request.', 0x0a
        post_len equ $ - post_msg

        put_msg db 'processing put request.', 0x0a
        put_len equ $ - put_msg

        delete_msg db 'processing delete request.', 0x0a
        delete_len equ $ - delete_msg

        bad_request_msg db 'Error: Bad Request.', 0x0a
        bad_request_len equ $ - bad_request_msg

section .bss
        socket_fd: resq 1       ; Reserve 8 bytes to store the listening socket's ID.
        client_fd: resq 1       ; Reserve 8 bytes to store a connected client's ID.

section .text
        global _start
        
        _start:
        ; int socket(int domain, int type, int protocol);
        mov rax, 41             ; syscall socket
        mov rdi, 2              ; domain: AF_INET
        mov rsi, 1              ; type: SOCK_STREAM
        mov rdx, 0              ; protocol: 0
        syscall
        mov [socket_fd], rax    ; Save the returned file descriptor
        cmp rax, -1             ; Check for error (-1)
        je .socket_error

        ; int setsockopt(int sockfd, int level, int optname, const void *optval, socklen_t optlen);
        mov rax, 54             ; syscall setsockopt
        mov rdi, [socket_fd]    ; sockfd: our socket
        mov rsi, 1              ; level: SOL_SOCKET
        mov rdx, 2              ; optname: SO_REUSEADDR
        lea r10, [socket_on]    ; *optval: pointer to a variable with value 1
        mov r8, 4               ; optlen: size of the option value (a 4-byte integer)
        syscall

        ; int bind(int sockfd, const struct sockaddr *addr, socklen_t addrlen);
        mov rax, 49             ; syscall bind
        mov rdi, [socket_fd]    ; sockfd
        lea rsi, [socket_address] ; *addr
        mov rdx, saddress_len   ; addrlen
        syscall
        cmp rax, 0              ; Check for error (non-zero)
        jne .bind_error

        ; int listen(int sockfd, int backlog);
        mov rax, 50             ; syscall listen
        mov rdi, [socket_fd]    ; sockfd
        mov rsi, 128            ; backlog: max pending connections
        syscall
        cmp rax, 0              ; Check for error (non-zero)
        jne .listen_error

        .main_loop:
        ; int accept(int sockfd, struct sockaddr *addr, socklen_t *addrlen);
        mov rax, 43             ; syscall accept
        mov rdi, [socket_fd]    ; sockfd (the original listening socket)
        mov rsi, 0              ; *addr (NULL, accept everybody)
        mov rdx, 0              ; *addrlen (NULL)
        syscall
        mov [client_fd], rax    ; Save the NEW file descriptor for the client
        cmp rax, -1             ; Check for error (-1)
        je .accept_error

        ; pid_t fork(void);
        mov rax, 57             ; Syscall fork
        syscall
        cmp rax, 0
        jl .fork_error          ; Less than 0: an error occurred
        je .child_process       ; Equal to 0: we are the child process

        ; parent process:  close the client socket, let the client process handle it
        ; int close(int fd)
        mov rax, 3              ; syscall close
        mov rdi, [client_fd]
        syscall
        jmp .main_loop          ; Go back and wait for the next connection

        .child_process:
        ; --- CHILD PROCESS ---
        ; child process: handle the request.
        ; close the listening socket, child won't accept new connections.
        mov rax, 3
        mov rdi, [socket_fd]
        syscall

        ; ssize_t read(int fd, void *buf, size_t count);
        mov rax, 0                  ; Syscall #0 for read()
        mov rdi, [client_fd]        ; Arg 1 (fd): The client's socket descriptor
        lea rsi, [request_buffer]   ; Arg 2 (*buf): Pointer to our buffer
        mov rdx, req_buff_len       ; Arg 3 (count): Max bytes to read
        syscall

        ; get the first 4 bytes of the request buffer
        mov eax, dword [request_buffer]

        ; GET
        cmp eax, "GET "
        je .handle_get

        ; POST
        cmp eax, "POST"
        je .handle_post

        ; PUT
        cmp eax, "PUT "
        je .handle_put

        ; DELETE
        ; check the first 4 letters: "DELE"
        cmp eax, "DELE"
        je .handle_delete

        ; unsupported method if not found
        jmp .handle_bad_request

        .handle_get:
        mov rdx, get_msg
        mov rax, 1
        mov rdi, 1
        syscall
        ; TODO: Add code to find and serve a file.
        jmp .send_response

        .handle_post:
        mov rdx, post_msg
        mov rax, 1
        mov rdi, 1
        syscall
        ; TODO: Add code to read the request body and process the data.
        jmp .send_response

        .handle_put:
        mov rdx, put_msg
        mov rax, 1
        mov rdi, 1
        syscall
        ; TODO: Add code to replace a resource with data from the request body.
        jmp .send_response

        .handle_delete:
        mov rdx, delete_msg
        mov rax, 1
        mov rdi, 1
        syscall
        ; TODO: Add code to delete a resource.
        jmp .send_response

        .handle_bad_request:
        mov rdx, bad_request_msg
        mov rax, 1
        mov rdi, 1
        syscall
        ; TODO: Add code to prepare a "400 Bad Request" or "501 Not Implemented" response.
        jmp .send_response

        .send_response:
        ; This is where you would call write() to send the prepared HTTP response.
        ; For now, we'll just continue to the cleanup code.

        jmp .exit_client_success

        .socket_error:
        lea rsi, [socket_err_msg]
        mov rdx, socket_err_len
        jmp .print_error

        .bind_error:
        lea rsi, [bind_err_msg]
        mov rdx, bind_err_len
        jmp .print_error

        .listen_error:
        lea rsi, [listen_err_msg]
        mov rdx, listen_err_len
        jmp .print_error

        .accept_error:
        lea rsi, [accept_err_msg]
        mov rdx, accept_err_len
        jmp .print_error

        .fork_error:
        lea rsi, [fork_err_msg]
        mov rdx, fork_err_len
        jmp .print_error

        .print_error:
        ; This block prints the error message pointed to by RSI
        mov rax, 1              ; syscall write
        mov rdi, 2              ; file descriptor: stderr
        syscall
        jmp .exit_failure       ; After printing, exit with an error code

        .exit_failure:
        ; This block exits the program with a non-zero status code
        mov rax, 60             ; syscall exit
        mov rdi, 1              ; Exit code 1 (error)
        syscall

        .exit_success:
        ; Cleanly close the main listening socket before exiting
        mov rax, 3              ; syscall close
        mov rdi, [socket_fd]
        syscall

        mov rax, 60             ; syscall exit
        xor rdi, rdi            ; Exit code 0 (success)
        syscall

        .exit_client_success:
        ; Cleanly close the client socket before exiting
        mov rax, 3              ; syscall close
        mov rdi, [client_fd]
        syscall

        mov rax, 60             ; syscall exit
        xor rdi, rdi            ; Exit code 0 (success)
        syscall