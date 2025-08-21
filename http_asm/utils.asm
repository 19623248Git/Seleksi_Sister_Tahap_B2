section .data
        temp_filename_prefix db 'tmp/upload-', 0
        prefix_len equ $ - temp_filename_prefix - 1
        temp_filename_suffix db '.tmp', 0
        suffix_len equ $ - temp_filename_suffix - 1

section .text
        ; -- CHANGED: Removed 'extern full_temp_path' to make this file self-contained.

        global integer_to_ascii
        global build_temp_filename

; Converts a 64-bit integer to a null-terminated ASCII string.
; Input:
;   RDI: The integer to convert (e.g., the PID).
;   RSI: A pointer to a buffer to store the resulting string.
; Output:
;   RAX: The length of the string (excluding the null terminator).
integer_to_ascii:
    mov rax, rdi
    mov r8, 0
    mov rcx, 10
.digit_loop:
    xor rdx, rdx
    div rcx
    add rdx, '0'
    push rdx
    inc r8
    test rax, rax
    jnz .digit_loop
    mov rax, r8
.reverse_loop:
    pop rcx
    mov [rsi], cl
    inc rsi
    dec r8
    jnz .reverse_loop
    mov byte [rsi], 0
    ret

; -- CHANGED: Updated function to accept destination buffer as an argument.
; Builds a unique temporary filename string.
; Input:
;   RDI: Pointer to the PID string (e.g., "12345").
;   RSI: Length of the PID string (e.g., 5).
;   RDX: Pointer to the destination buffer to build the path in.
build_temp_filename:
        push rdi ; Save PID string pointer
        push rsi ; Save PID string length
        
        mov rdi, rdx ; Set RDI to be the destination buffer for rep movsb

        ; -- 1. Copy the prefix --
        lea rsi, [temp_filename_prefix]
        mov rcx, prefix_len
        rep movsb

        ; -- 2. Copy the PID string --
        pop rcx ; Restore PID string length into RCX for the count
        pop rsi ; Restore PID string pointer into RSI for the source
        rep movsb

        ; -- 3. Copy the suffix --
        lea rsi, [temp_filename_suffix]
        mov rcx, suffix_len
        rep movsb

        ; -- 4. Add the null terminator --
        mov byte [rdi], 0

        ret
