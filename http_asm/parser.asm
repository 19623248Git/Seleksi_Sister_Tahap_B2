section .data
        content_length_key      db 'Content-Length:'
        content_length_key_len  equ $ - content_length_key
        content_type_key        db 'Content-Type: multipart/form-data'
        content_type_key_len    equ $ - content_type_key
        boundary_key            db 'boundary='
        boundary_key_len        equ $ - boundary_key

section .text
        extern memmem
        global find_content_length_value
        global find_boundary_value

; Input: RDI = pointer to headers buffer, RSI = length of the headers
; Output: RAX = pointer to the first digit of the value, or 0 if not found.
find_content_length_value:
        push rdi
        push rsi

        ; --- Step 1: Search for the "Content-Length:" key ---
        lea rdx, [content_length_key]
        mov rcx, content_length_key_len
        call memmem

        cmp rax, 0
        je .cl_not_found

        ; --- Step 2: Advance the pointer past the key ---
        add rax, content_length_key_len

        ; --- Step 3: Skip any whitespace ---
.skip_whitespace_loop:
        mov cl, byte [rax]
        cmp cl, ' '
        je .is_whitespace
        cmp cl, 0x09
        je .is_whitespace
        jmp .cl_found_value

.is_whitespace:
        inc rax
        jmp .skip_whitespace_loop

.cl_not_found:
        xor rax, rax
        jmp .cl_done

.cl_found_value:
        ; SUCCESS: RAX now holds the address of the first ASCII digit.

.cl_done:
        pop rsi
        pop rdi
        ret

; Input: RDI = pointer to headers buffer, RSI = length of the headers
; Output: RAX = pointer to boundary value, RDX = length of value. RAX=0 on failure.
find_boundary_value:
        push rdi
        push rsi
        push r12  ; Save a register for our use

        ; 1. Find "Content-Type: multipart/form-data"
        lea rdx, [content_type_key]
        mov rcx, content_type_key_len
        call memmem
        cmp rax, 0
        je .boundary_not_found

        ; 2. From there, find "boundary="
        mov rdi, rax ; Start searching from where "Content-Type" was found
        mov rsi, [rsp+8] ; Original header length
        sub rsi, rax
        add rsi, [rsp+16] ; Original header start pointer
        lea rdx, [boundary_key]
        mov rcx, boundary_key_len
        call memmem
        cmp rax, 0
        je .boundary_not_found

        ; 3. Move pointer past "boundary=" to the start of the actual value
        add rax, boundary_key_len
        mov r12, rax  ; r12 now holds the start of the boundary value

        ; 4. Find the end of the value (the next carriage return)
        mov rdi, r12
.find_cr_loop:
        cmp byte [rdi], 0x0d
        je .found_cr
        inc rdi
        ; TODO: Add a bounds check here to prevent scanning past the end of the buffer
        jmp .find_cr_loop

.found_cr:
        ; 5. Calculate the length and set return registers
        mov rdx, rdi
        sub rdx, r12  ; rdx = length
        mov rax, r12  ; rax = pointer to start of value
        jmp .boundary_done

.boundary_not_found:
        xor rax, rax
        xor rdx, rdx

.boundary_done:
        pop r12
        pop rsi
        pop rdi
        ret
