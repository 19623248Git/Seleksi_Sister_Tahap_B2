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
        socket_err_msg db 'Error: Could not create socket.', 0x0a, 0
        socket_err_len equ $ - socket_err_msg
        bind_err_msg db 'Error: Could not bind to port 8080.', 0x0a, 0
        bind_err_len equ $ - bind_err_msg
        listen_err_msg db 'Error: Could not listen on socket.', 0x0a, 0
        listen_err_len equ $ - listen_err_msg
        accept_err_msg db 'Error: Could not accept new connection.', 0x0a, 0
        accept_err_len equ $ - accept_err_msg
        fork_err_msg db 'Error: Could not fork new process.', 0x0a, 0
        fork_err_len equ $ - fork_err_msg

        ; Method messages for logging/debugging
        post_msg db 'processing post request.', 0x0a, 0
        post_len equ $ - post_msg
        
        finished_writing_msg db 'Finished writing.', 0x0a, 0
        finished_writing_msg_len equ $ - finished_writing_msg

        ; Header and separator definitions for parsing
        expect_header db 'Expect: 100-continue'
        expect_header_len equ $ - expect_header
        crlf_separator db 0x0d, 0x0a, 0x0d, 0x0a
        crlf_separator_len equ $ - crlf_separator

        ; -- ADDED: Prefix for the final file destination --
        app_dir_prefix db 'app/img/', 0
        app_dir_prefix_len equ $ - app_dir_prefix - 1

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
        ; -- ADDED: BSS variables for final file handling --
        parsed_filename: resb 256
        filename_len: resq 1
        final_filepath: resb 256
        file_copy_buffer: resb 8192

section .text
        extern memmem
        extern find_content_length_value
        extern strtoll
        extern integer_to_ascii
        extern build_temp_filename
        extern find_boundary_value
        extern find_filename_value

        global _start
        
_start:
        ; ... (socket, setsockopt, bind, listen setup) ...
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
        mov eax, dword [request_buffer]
        cmp eax, "POST"
        je .handle_post
        jmp .handle_bad_request

.handle_post:
        mov rax, 1
        mov rdi, 1
        lea rsi, [post_msg]
        mov rdx, post_len
        syscall

        lea rdi, [request_buffer]
        mov rsi, r12
        call find_boundary_value
        cmp rax, 0
        je .handle_bad_request

        lea rdi, [boundary_string + 2]
        mov rsi, rax
        mov rcx, rdx
        rep movsb
        mov word [boundary_string], '--'
        add rdx, 2
        mov [boundary_len], rdx

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

        ; -- REVISED LOGIC for 100-continue --
        ; Find end of main headers in the initial packet
        lea rdi, [request_buffer]
        mov rsi, r12
        lea rdx, [crlf_separator]
        mov rcx, crlf_separator_len
        call memmem
        cmp rax, 0
        je .handle_bad_request
        
        add rax, crlf_separator_len
        mov r9, rax ; r9 = pointer to start of potential body
        
        lea rdi, [request_buffer]
        sub rax, rdi ; rax = size of headers
        mov r10, r12
        sub r10, rax ; r10 = size of body in initial buffer
        
        cmp r10, 0
        jne .process_first_body_chunk ; If body exists, process it

        ; If we are here, it was a 100-continue request with no body.
        ; Read the first chunk of the body now.
        mov rax, 0
        mov rdi, [client_fd]
        lea rsi, [request_buffer]
        mov rdx, req_buff_len
        syscall
        mov r12, rax ; r12 now holds the size of this new chunk
        lea r9, [request_buffer] ; The "body" is the whole new chunk
        mov r10, r12 ; The "body size" is the whole new chunk size

.process_first_body_chunk:
        ; At this point, r9 points to the data to process, and r10 is its size.
        
        ; 1. Find filename within this first body chunk
        mov rdi, r9
        mov rsi, r10
        call find_filename_value
        cmp rax, 0
        je .handle_bad_request
        mov [filename_len], rdx
        lea rdi, [parsed_filename]
        mov rsi, rax
        mov rcx, rdx
        rep movsb
        mov byte [rdi], 0

        ; 2. Find the end of the part headers within this chunk
        mov rdi, r9
        mov rsi, r10
        lea rdx, [crlf_separator]
        mov rcx, crlf_separator_len
        call memmem
        cmp rax, 0
        je .handle_bad_request

        ; 3. Calculate and write the first piece of file data
        add rax, crlf_separator_len
        mov rsi, rax ; rsi = pointer to file data
        
        lea rdi, [r9]
        sub rax, rdi ; rax = size of part headers
        mov rdx, r10
        sub rdx, rax ; rdx = size of file data

        mov rdi, r15
        mov rax, 1
        syscall

        ; 4. Initialize the total bytes counter and jump to the loop
        mov r14, r10
        jmp .upload_loop

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
        mov r12, rax
        add r14, r12

        lea rdi, [request_buffer]
        mov rsi, r12
        lea rdx, [boundary_string]
        mov rcx, [boundary_len]
        call memmem
        cmp rax, 0
        je .no_boundary_in_chunk

.boundary_in_chunk:
        lea rsi, [request_buffer]
        mov rdx, rax
        sub rdx, rsi
        sub rdx, 2
        mov rdi, r15
        mov rax, 1
        syscall
        jmp .upload_finished

.no_boundary_in_chunk:
        lea rsi, [request_buffer]
        mov rdx, r12
        mov rdi, r15
        mov rax, 1
        syscall
        jmp .upload_loop

.upload_finished:
        mov rax, 3
        mov rdi, r15
        syscall

        lea rdx, [final_filepath]
        mov rsi, [filename_len]
        lea rdi, [parsed_filename]
        call build_final_filepath

        mov rax, 82
        lea rdi, [full_temp_path]
        lea rsi, [final_filepath]
        syscall
        
        mov rax, 1
        mov rdi, [client_fd]
        lea rsi, [http_201_response]
        mov rdx, http_201_len
        syscall
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

build_final_filepath:
        push rdi
        push rsi
        mov rdi, rdx

        lea rsi, [app_dir_prefix]
        mov rcx, app_dir_prefix_len
        rep movsb

        pop rcx
        pop rsi
        rep movsb

        mov byte [rdi], 0
        ret
