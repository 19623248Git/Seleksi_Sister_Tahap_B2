section .data
        ; This is the sockaddr_in structure for binding to an IP and port.
        socket_address:
                dw 2                    ; sin_family: AF_INET (IPv4)
                dw 0x901F               ; sin_port: 8080 (0x1F90), stored byte-swapped (big-endian).
        sin_addr: dd 0x00000000          ; sin_addr: INADDR_ANY (bind to any available IP 0.0.0.0)
        sin_zero: dq 0                   ; 8 bytes of padding, must be zero.

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

        ; Method messages for logging/debugging
        get_msg db 'processing get request.', 0x0a
        get_len equ $ - get_msg
        post_msg db 'processing post request.', 0x0a, 0
        post_len equ $ - post_msg
        put_msg db 'processing put request.', 0x0a
        put_len equ $ - put_msg
        delete_msg db 'processing delete request.', 0x0a
        delete_len equ $ - delete_msg
        
        finished_writing_msg db 'Finished writing.', 0x0a
        finished_writing_msg_len equ $ - finished_writing_msg

        ; -- ADDED BACK: Debug messages --
        boundary_found_msg db 'Boundary found in chunk!', 0x0a
        boundary_found_len equ $ - boundary_found_msg
        boundary_debug_msg db 'Parsed boundary: [', 0
        boundary_debug_msg_len equ $ - boundary_debug_msg - 1
        boundary_debug_suffix db ']', 0x0a, 0
        boundary_debug_suffix_len equ $ - boundary_debug_suffix - 1
        boundary_len_msg db 'Boundary length: ', 0
        boundary_len_msg_len equ $ - boundary_len_msg - 1
        newline db 0x0a

        ; Endpoint definitions
        endpoint_gallery db '/gallery', 0
        endpoint_gallery_len equ $ - endpoint_gallery

        ; Header and separator definitions for parsing
        expect_header db 'Expect: 100-continue'
        expect_header_len equ $ - expect_header
        crlf_separator db 0x0d, 0x0a, 0x0d, 0x0a
        crlf_separator_len equ $ - crlf_separator

        ; HTTP Responses
        continue_response db 'HTTP/1.1 100 Continue', 0x0d, 0x0a, 0x0d, 0x0a
        continue_response_len equ $ - continue_response

        http_201_response db 'HTTP/1.1 201 Created', 0x0d, 0x0a, 'Content-Length: 0', 0x0d, 0x0a, 0x0d, 0x0a
        http_201_len equ $ - http_201_response

        http_400_response:
                db 'HTTP/1.1 400 Bad Request', 0x0d, 0x0a
                db 'Content-Type: text/html', 0x0d, 0x0a
                db 'Content-Length: 50', 0x0d, 0x0a
                db 'Connection: close', 0x0d, 0x0a
                db 0x0d, 0x0a  ; Blank line
                db '<html><body><h1>400 Bad Request</h1></body></html>'
        http_400_len equ $ - http_400_response

section .bss
        request_buffer: resb 8192
        req_buff_len equ $ - request_buffer
        socket_fd: resq 1
        client_fd: resq 1
        end_pointer: resq 1
        full_temp_path: resb 256
        pid_string_buffer: resb 20
        boundary_string: resb 256
        boundary_len: resq 1

section .text
        extern memmem
        extern find_content_length_value
        extern strtoll
        extern integer_to_ascii
        extern build_temp_filename
        extern find_boundary_value

        global _start
        
_start:
        ; ... (socket, setsockopt, bind, listen) ...
        mov rax, 41
        mov rdi, 2
        mov rsi, 1
        mov rdx, 0
        syscall
        mov [socket_fd], rax
        cmp rax, -1
        je .socket_error
        mov rax, 54
        mov rdi, [socket_fd]
        mov rsi, 1
        mov rdx, 2
        lea r10, [socket_on]
        mov r8, 4
        syscall
        mov rax, 49
        mov rdi, [socket_fd]
        lea rsi, [socket_address]
        mov rdx, saddress_len
        syscall
        cmp rax, 0
        jne .bind_error
        mov rax, 50
        mov rdi, [socket_fd]
        mov rsi, 128
        syscall
        cmp rax, 0
        jne .listen_error

.main_loop:
        mov rax, 43
        mov rdi, [socket_fd]
        mov rsi, 0
        mov rdx, 0
        syscall
        mov [client_fd], rax
        cmp rax, -1
        je .accept_error
        mov rax, 57
        syscall
        cmp rax, 0
        jl .fork_error
        je .child_process
        mov rax, 3
        mov rdi, [client_fd]
        syscall
        jmp .main_loop

.child_process:
        mov rax, 3
        mov rdi, [socket_fd]
        syscall

        mov rax, 0
        mov rdi, [client_fd]
        lea rsi, [request_buffer]
        mov rdx, req_buff_len
        syscall
        mov r12, rax

        ; Handle "Expect: 100-continue"
        lea rdi, [request_buffer]
        mov rsi, r12
        lea rdx, [expect_header]
        mov rcx, expect_header_len
        call memmem
        cmp rax, 0
        je .skip_continue_response

        mov rax, 1
        mov rdi, [client_fd]
        lea rsi, [continue_response]
        mov rdx, continue_response_len
        syscall

.skip_continue_response:
        jmp .handle_request

.handle_request:
        mov rax, 1
        mov rdi, 1
        lea rsi, [request_buffer]
        mov rdx, r12
        syscall

        mov eax, dword [request_buffer]
        cmp eax, "GET "
        je .handle_get
        cmp eax, "POST"
        je .handle_post
        cmp eax, "PUT "
        je .handle_put
        cmp eax, "DELE"
        je .handle_delete
        jmp .handle_bad_request

.handle_get:
        mov rax, 1
        mov rdi, 1
        lea rsi, [get_msg]
        mov rdx, get_len
        syscall
        jmp .send_response

.handle_post:
        mov rax, 1
        mov rdi, 1
        lea rsi, [post_msg]
        mov rdx, post_len
        syscall

        lea rdi, [request_buffer]
        mov rsi, r12
        lea rdx, [endpoint_gallery]
        mov rcx, endpoint_gallery_len - 1
        call memmem
        cmp rax, 0
        je .handle_bad_request

        lea rdi, [request_buffer]
        mov rsi, r12
        call find_boundary_value
        cmp rax, 0
        je .handle_bad_request

        ; Prepend "--" to the boundary string for use in the body
        lea rdi, [boundary_string + 2]
        mov rsi, rax
        mov rcx, rdx
        rep movsb
        mov word [boundary_string], '--'
        add rdx, 2
        mov [boundary_len], rdx

        ; -- DEBUG: Print the parsed boundary and its length --
        push rax
        push rdi
        push rsi
        push rdx
        push rcx
        mov rax, 1
        mov rdi, 1
        lea rsi, [boundary_debug_msg]
        mov rdx, boundary_debug_msg_len
        syscall
        mov rax, 1
        mov rdi, 1
        lea rsi, [boundary_string]
        mov rdx, [boundary_len]
        syscall
        mov rax, 1
        mov rdi, 1
        lea rsi, [boundary_debug_suffix]
        mov rdx, boundary_debug_suffix_len
        syscall
        mov rax, 1
        mov rdi, 1
        lea rsi, [boundary_len_msg]
        mov rdx, boundary_len_msg_len
        syscall
        mov rdi, [boundary_len]
        lea rsi, [pid_string_buffer]
        call integer_to_ascii
        mov rdx, rax
        lea rsi, [pid_string_buffer]
        mov rdi, 1
        mov rax, 1
        syscall
        mov rax, 1
        mov rdi, 1
        lea rsi, [newline]
        mov rdx, 1
        syscall
        pop rcx
        pop rdx
        pop rsi
        pop rdi
        pop rax
        ; -- END DEBUG --

        lea rdi, [request_buffer]
        mov rsi, r12
        call find_content_length_value
        cmp rax, 0
        je .handle_bad_request

        mov rdi, rax
        lea rsi, [end_pointer]
        mov rdx, 10
        call strtoll
        mov r13, rax

        mov rax, 39
        syscall
        mov rdi, rax
        lea rsi, [pid_string_buffer]
        call integer_to_ascii
        lea rdx, [full_temp_path]
        mov rsi, rax
        lea rdi, [pid_string_buffer]
        call build_temp_filename

        mov rax, 2
        lea rdi, [full_temp_path]
        mov rsi, 65
        mov rdx, 0644o
        syscall
        mov r15, rax

        ; -- First chunk handling: skip part headers --
        mov rax, 0
        mov rdi, [client_fd]
        lea rsi, [request_buffer]
        mov rdx, req_buff_len
        syscall
        mov r12, rax ; r12 = size of first body chunk

        lea rdi, [request_buffer]
        mov rsi, r12
        lea rdx, [crlf_separator]
        mov rcx, crlf_separator_len
        call memmem
        cmp rax, 0
        je .handle_bad_request ; Part headers not found

        add rax, crlf_separator_len
        mov rsi, rax ; RSI = pointer to start of file data

        lea rdi, [request_buffer]
        sub rax, rdi ; RAX = size of headers in this chunk
        mov rdx, r12
        sub rdx, rax ; RDX = size of file data in this chunk

        mov rdi, r15
        mov rax, 1
        syscall

        mov r14, r12 ; Initialize total bytes counter with size of first chunk

 .upload_loop:
        cmp r14, r13
        jge .upload_finished

        mov rax, 0
        mov rdi, [client_fd]
        lea rsi, [request_buffer]
        mov rdx, req_buff_len
        syscall

        cmp rax, 0
        jle .upload_finished
        mov r12, rax ; r12 = current chunk size
        add r14, r12 ; Increment total counter immediately

        ; -- REWRITTEN LOGIC: Find boundary anywhere in the chunk --
        lea rdi, [request_buffer]
        mov rsi, r12
        lea rdx, [boundary_string]
        mov rcx, [boundary_len]
        call memmem

        cmp rax, 0
        je .no_boundary_in_chunk

.boundary_in_chunk:
        ; -- DEBUG: Print message confirming boundary was found --
        push rax
        push rdi
        push rsi
        push rdx
        mov rax, 1
        mov rdi, 1
        lea rsi, [boundary_found_msg]
        mov rdx, boundary_found_len
        syscall
        pop rdx
        pop rsi
        pop rdi
        pop rax
        
        ; Boundary was found. This is the last chunk of file data.
        ; Calculate size of data to write (up to the CRLF before the boundary)
        lea rsi, [request_buffer]
        mov rdx, rax
        sub rdx, rsi ; RDX = size of data from buffer start to boundary
        sub rdx, 2   ; Exclude the preceding CRLF
        
        ; Write the final piece of file data
        mov rdi, r15
        mov rax, 1
        syscall
        jmp .upload_finished ; The upload is done

.no_boundary_in_chunk:
        ; This chunk is pure file data. Write the whole thing.
        lea rsi, [request_buffer]
        mov rdx, r12
        mov rdi, r15
        mov rax, 1
        syscall
        jmp .upload_loop ; Continue reading

.upload_finished:
        push rdi
        push rsi
        push rdx
        mov rax, 1
        mov rdi, 1
        lea rsi, [finished_writing_msg]
        mov rdx, finished_writing_msg_len
        syscall
        pop rdx
        pop rsi
        pop rdi

        mov rax, 3
        mov rdi, r15
        syscall

        mov rax, 1
        mov rdi, [client_fd]
        lea rsi, [http_201_response]
        mov rdx, http_201_len
        syscall
        jmp .exit_client_success

.handle_put:
        mov rax, 1
        mov rdi, 1
        lea rsi, [put_msg]
        mov rdx, put_len
        syscall
        jmp .send_response

.handle_delete:
        mov rax, 1
        mov rdi, 1
        lea rsi, [delete_msg]
        mov rdx, delete_len
        syscall
        jmp .send_response

.send_response:
        jmp .exit_client_success

.handle_bad_request:
        mov rax, 1
        mov rdi, [client_fd]
        lea rsi, [http_400_response]
        mov rdx, http_400_len
        syscall
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
        mov rax, 1
        mov rdi, 2
        syscall
        jmp .exit_failure

.exit_failure:
        mov rax, 60
        mov rdi, 1
        syscall

.exit_client_success:
        mov rax, 3
        mov rdi, [client_fd]
        syscall
        mov rax, 60
        xor rdi, rdi
        syscall
