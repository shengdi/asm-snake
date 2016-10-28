; 16 bits, starting at 0x7C00.
BITS 16
ORG 0x7C00

BSS             EQU 0x504     ; The byte at 0x500 is also used, so align on next dword bound.
BSS_SIZE        EQU 938

SNAKE_DIRECTION EQU BSS       ; 16 bytes.
SNAKE_START     EQU BSS + 16  ; 2 bytes.
SNAKE_END       EQU BSS + 18
OFFSET          EQU BSS + 32  ; 2 bytes.
STACK           EQU BSS + 38  ; 4 bytes reserved in beginning, 400 bytes.

LEFT_SCANCODE   EQU 75
RIGHT_SCANCODE  EQU 77

UP_SCANCODE     EQU 72
DOWN_SCANCODE   EQU 80

CPU 686

; Entry point.
;     cs:ip -> linear address 0x7C00.
start:
    jmp 0x0000:.CS_flush                    ; Some BIOS' may load us at 0x0000:0x7C00, while others at 0x07C0:0x0000.

    .CS_flush:
        ; Set up segments.
        xor bx, bx

        ; Stack.
        mov ss, bx
        mov sp, start
    
        mov ds, bx
        mov es, bx

    ; Clear direction flag.
    cld

    ; Clear BSS
    mov di, BSS
    mov cx, BSS_SIZE
    xor ax, ax
    rep stosb

    ; Set to mode 0x03, or 80x25 text mode (ah is zero from above).
    mov al, 0x03
    int 0x10

    ; Hide the hardware cursor.               
    mov ch, 0x26
    mov al, 0x03                ; Some BIOS crash without this.
    inc ah
    int 0x10

    mov ax, 0xB800
    mov es, ax

    ; White spaces on black background.
    xor di, di
    mov cx, 80*25
    mov ax, 0x0F00
    rep stosw

    .borders:
        mov si, STACK
        mov eax, 0x41414141
        xor ecx, ecx

    ;top border
    mov cx, 10
    .border_top:
        mov dword [si], eax 
        add si, 4
        loop .border_top

    
    .borders_init:
        mov byte [si + 39], al
        mov byte [si], al

        add si, 40
        cmp si, STACK + 920
        jbe .borders_init

    mov cx, 10
    .border_btm:
        mov dword [si], eax 
        add si, 4
        loop .border_btm

    ;for snake linked list
    ;1-up 2-down 3-left 4-right
    .init_snake:
        mov si, STACK
        add si, 480+20
        mov byte [si], 0x44 
        inc si
        mov byte [si], 0x44 
        inc si
        mov byte [si], 0x44 
        inc si
        mov byte [si], 0x44 
        inc si
        mov byte [si], 0x44 
        mov word [SNAKE_START], 504
        ;mov bx, SNAKE_END
        mov word [SNAKE_END], 500
        mov byte [SNAKE_DIRECTION], 0x44

    ; Cleared dx implies "load new tetramino".
    xor dl, dl
    mov si, OFFSET

    sti
    .event_loop:
        mov bx, [0x046C]
        add bx, 2           ; Wait for 2 PIT ticks.

        .busy_loop:
            cmp [0x046C], bx
            jne .busy_loop


    .input:
        mov ah, 0x01
        int 0x16

        ;If no keystroke continue in same direction
        jz .move_snake

        ;Clear keyboard buffer.
        xor ah, ah
        int 0x16

    .move_snake:
        ;Move head up one position
        mov si, STACK
        mov bx, [SNAKE_START]
        ;Move start to next position
        ;Depending on input
        

        .left:
            cmp ah, LEFT_SCANCODE
            jne .right

            sub bx, 1
            add si, bx
            mov byte [si], 0x44
            mov [SNAKE_START], bx
            jmp .delete_tail

    .delete_tail
        ;Move tail down one position
        mov si, STACK
        mov bx, [SNAKE_END]
        add si, bx
        mov byte dl, [si]
        mov byte [si], 0

        ;Move end to next position
        .next_up:
            cmp dl, 0x41
            jne .next_down
            sub bx, 40
            mov [SNAKE_END], bx
            jmp .draw_stack

        .next_down:
            cmp dl, 0x42
            jne .next_left
            add bx, 40
            mov [SNAKE_END], bx
            jmp .draw_stack

        .next_left:
            cmp dl, 0x43
            jne .next_right
            sub bx, 1
            mov [SNAKE_END], bx
            jmp .draw_stack

        .next_right:
            cmp dl, 0x44
            jne .draw_stack
            add bx, 1
            mov [SNAKE_END], bx

    .draw_stack:
        mov si, STACK
        mov di, 0
        
        .loop_stack_lines:
            mov cx, 40
            .stack_line:
                lodsb

                stosb
                inc di
                stosb
                inc di

                loop .stack_line
            cmp di, (25*160)
            jb .loop_stack_lines

    jmp .event_loop


; IT'S A SECRET TO EVERYBODY.
db "ShNoXgSo"

; Padding.
times 510 - ($ - $$)            db 0

BIOS_signature:
    dw 0xAA55

