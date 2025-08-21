; To assemble and link this file:
; nasm -f elf64 -o server.o server.asm
; ld -o server server.o

section .data
        socket_address:
                dw 2                    ; sin_family: AF_INET (IPv4)
                dw 0x901F               ; sin_port: 8080 (0x1F90), byte-swapped.
        sin_addr: dd 0x00000000          ; sin_addr: INADDR_ANY (0.0.0.0)
        sin_zero: dq 0                   ; 8 bytes of padding.
        saddress_len equ $ - socket_address

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
        
        ; HTTP Responses and Headers
        http_200_ok db 'HTTP/1.1 200 OK', 0x0d, 0x0a
        http_200_len equ $ - http_200_ok
        http_404_not_found db 'HTTP/1.1 404 Not Found', 0x0d, 0x0a, 'Content-Type: text/plain', 0x0d, 0x0a, 'Content-Length: 9', 0x0d, 0x0a, 0x0d, 0x0a, 'Not Found'
        http_404_len equ $ - http_404_not_found
        http_400_bad_request db 'HTTP/1.1 400 Bad Request', 0x0d, 0x0a, 'Content-Type: text/plain', 0x0d, 0x0a, 'Content-Length: 11', 0x0d, 0x0a, 0x0d, 0x0a, 'Bad Request'
        http_400_len equ $ - http_400_bad_request
        http_501_not_implemented db 'HTTP/1.1 501 Not Implemented', 0x0d, 0x0a, 'Content-Type: text/plain', 0x0d, 0x0a, 'Content-Length: 15', 0x0d, 0x0a, 0x0d, 0x0a, 'Not Implemented'
        http_501_len equ $ - http_501_not_implemented

        content_type_header db 'Content-Type: '
        content_type_header_len equ $ - content_type_header
        content_length_header db 'Content-Length: '
        content_length_header_len equ $ - content_length_header
        
        crlf db 0x0d, 0x0a
        crlf_len equ $ - crlf

        ; MIME Types
        content_type_html db 'text/html'
        content_type_html_len equ $ - content_type_html
        content_type_css db 'text/css'
        content_type_css_len equ $ - content_type_css
        content_type_js db 'application/javascript'
        content_type_js_len equ $ - content_type_js
        content_type_png db 'image/png'
        content_type_png_len equ $ - content_type_png
        content_type_jpg db 'image/jpeg'
        content_type_jpg_len equ $ - content_type_jpg
        content_type_default db 'application/octet-stream'
        content_type_default_len equ $ - content_type_default

        ; File paths
        base_path db 'app'
        base_path_len equ $ - base_path
        root_path db 'app/index.html'
        root_path_len equ $ - root_path

        ; Endpoint
        endpoint_post db 'api/glry'
        endpoint_post_len equ $ - endpoint_post

section .bss
        socket_fd: resq 1
        client_fd: resq 1
        file_fd: resq 1
        file_size: resq 1
        
        request_buffer: resb 8192 ; Buffer for incoming requests
        req_buff_len equ $ - request_buffer
        
        file_path: resb 256
        
        stat_buf: resb 144
        
        header_buffer: resb 1024
        
section .text
        global _start

%macro append_to_header 2
    lea rsi, [%1]
    mov rcx, %2
    rep movsb
%endmacro

_start:
        ; Standard server setup: socket, setsockopt, bind, listen
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
        ; Accept connections and fork
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
        ; --- CHILD PROCESS: Request Router ---
        mov rax, 3
        mov rdi, [socket_fd]
        syscall
        
        ; Read the incoming request
        mov rax, 0
        mov rdi, [client_fd]
        lea rsi, [request_buffer]
        mov rdx, req_buff_len
        syscall
        mov r12, rax ; r12 holds bytes read

        ; Print the request to the console for logging
        mov rax, 1
        mov rdi, 1
        lea rsi, [request_buffer]
        mov rdx, r12
        syscall
        mov rax, 1
        mov rdi, 1
        lea rsi, [crlf]
        mov rdx, crlf_len
        syscall

        ; Check for different HTTP methods
        cmp dword [request_buffer], 'GET '
        je .handle_get
        
        cmp dword [request_buffer], 'POST'
        jne .check_put
        cmp byte [request_buffer+4], ' '
        je .handle_post

.check_put:
        cmp dword [request_buffer], 'PUT '
        je .handle_put
        
.check_delete:
        cmp dword [request_buffer], 'DELE'
        jne .handle_not_implemented
        cmp word [request_buffer+4], 'TE'
        jne .handle_not_implemented
        cmp byte [request_buffer+6], ' '
        je .handle_delete

        ; If the method is not recognized, jump to the not implemented handler
        jmp .handle_not_implemented

; ===================================================================
; Request Handlers
; ===================================================================
.handle_get:
        call .find_request_path
        jc .send_400_bad_request
        call .sanitize_and_build_path
        jc .send_400_bad_request
        call .prepare_and_send_response
        jmp .exit_client_success

.handle_post:
        


.handle_put:

.handle_delete:
        
.handle_not_implemented:
        call .send_501_not_implemented
        jmp .exit_client_success

; ===================================================================
; Subroutines for Parsing & File Handling
; ===================================================================
.find_request_path:
    lea rsi, [request_buffer]
.find_first_space:
    cmp byte [rsi], ' '
    je .found_first_space
    cmp byte [rsi], 0
    je .path_parse_error
    inc rsi
    jmp .find_first_space
.found_first_space:
    inc rsi
    mov rdi, rsi
.find_second_space:
    cmp byte [rdi], ' '
    je .found_second_space
    cmp byte [rdi], 0
    je .path_parse_error
    inc rdi
    jmp .find_second_space
.found_second_space:
    clc
    ret
.path_parse_error:
    stc
    ret

.sanitize_and_build_path:
        mov r10, rsi 
.scan_dots:
        cmp r10, rdi
        jge .sanitization_ok 
        cmp word [r10], '..'
        je .sanitization_failed
        inc r10
        jmp .scan_dots
.sanitization_failed:
        stc 
        ret
.sanitization_ok:
        mov rcx, rdi
        sub rcx, rsi
        cmp rcx, 1
        jne .build_regular_path
        cmp byte [rsi], '/'
        jne .build_regular_path
        lea rsi, [root_path]
        mov rcx, root_path_len
        lea rdi, [file_path]
        rep movsb
        mov byte [rdi], 0 
        clc 
        ret
.build_regular_path:
        push rsi
        push rdi
        lea rdi, [file_path]
        lea rsi, [base_path]
        mov rcx, base_path_len
        rep movsb
        pop r10
        pop rsi
        mov rcx, r10
        sub rcx, rsi
        rep movsb
        mov byte [rdi], 0
        clc
        ret

.prepare_and_send_response:
        mov rax, 2
        lea rdi, [file_path]
        mov rsi, 0
        syscall
        cmp rax, 0
        jl .send_404_not_found
        mov [file_fd], rax
        mov rax, 5
        mov rdi, [file_fd]
        lea rsi, [stat_buf]
        syscall
        mov rax, [stat_buf + 48]
        mov [file_size], rax
        lea rdi, [header_buffer]
        append_to_header http_200_ok, http_200_len
        append_to_header content_type_header, content_type_header_len
        lea r11, [file_path]
.find_ext_loop:
        cmp byte [r11], '.'
        je .found_ext
        cmp byte [r11], 0
        je .no_ext
        inc r11
        jmp .find_ext_loop
.found_ext:
        inc r11
        cmp dword [r11], 'html'
        je .append_html
        cmp dword [r11], 'css'
        je .append_css
        cmp dword [r11], 'js'
        je .append_js
        cmp dword [r11], 'png'
        je .append_png
        cmp dword [r11], 'jpg'
        je .append_jpg
.no_ext:
.append_default:
        append_to_header content_type_default, content_type_default_len
        jmp .append_content_type_crlf
.append_html:
        append_to_header content_type_html, content_type_html_len
        jmp .append_content_type_crlf
.append_css:
        append_to_header content_type_css, content_type_css_len
        jmp .append_content_type_crlf
.append_js:
        append_to_header content_type_js, content_type_js_len
        jmp .append_content_type_crlf
.append_png:
        append_to_header content_type_png, content_type_png_len
        jmp .append_content_type_crlf
.append_jpg:
        append_to_header content_type_jpg, content_type_jpg_len
.append_content_type_crlf:
        append_to_header crlf, crlf_len
        append_to_header content_length_header, content_length_header_len
        mov rax, [file_size]
        call .itoa
        add rdi, rax
        append_to_header crlf, crlf_len
        append_to_header crlf, crlf_len
        lea rsi, [header_buffer]
        sub rdi, rsi
        mov rdx, rdi
        mov rax, 1
        mov rdi, [client_fd]
        lea rsi, [header_buffer]
        syscall
        mov rax, 40               
        mov rdi, [client_fd]      
        mov rsi, [file_fd]        
        mov rdx, 0                
        mov r10, [file_size]      
        syscall
        mov rax, 3
        mov rdi, [file_fd]
        syscall
        ret

; ===================================================================
; Generic Response Handlers
; ===================================================================
.send_404_not_found:
        mov rax, 1
        mov rdi, [client_fd]
        lea rsi, [http_404_not_found]
        mov rdx, http_404_len
        syscall
        jmp .exit_client_success
.send_400_bad_request:
        mov rax, 1
        mov rdi, [client_fd]
        lea rsi, [http_400_bad_request]
        mov rdx, http_400_len
        syscall
        jmp .exit_client_success
.send_501_not_implemented:
        mov rax, 1
        mov rdi, [client_fd]
        lea rsi, [http_501_not_implemented]
        mov rdx, http_501_len
        syscall
        jmp .exit_client_success

; ===================================================================
; System Error Handling & Exit Procedures
; ===================================================================
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
        mov rdi, 2 ; stderr
        syscall
        jmp .exit_failure
.exit_failure:
        mov rax, 60
        mov rdi, 1
        syscall
.exit_success:
        mov rax, 3
        mov rdi, [socket_fd]
        syscall
        mov rax, 60
        xor rdi, rdi
        syscall
.exit_client_success:
        mov rax, 3
        mov rdi, [client_fd]
        syscall
        mov rax, 60
        xor rdi, rdi
        syscall

; ===================================================================
; Helper Routines
; ===================================================================
.itoa:
        mov r8, rdi 
        mov rbx, 10 
        xor rcx, rcx 
.itoa_loop:
        xor rdx, rdx
        div rbx
        add rdx, '0'
        push rdx
        inc rcx
        cmp rax, 0
        jne .itoa_loop
.itoa_pop:
        pop rax
        mov [rdi], al
        inc rdi
        loop .itoa_pop
        mov rax, rcx
        ret
