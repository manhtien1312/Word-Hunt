data segment
    seed    dw  2332h
    rndnum  dw  0  
    
    line        db  0
    column      db  0
    page_number db  0   
    
    word_1  db  "ROBERTO$"
    word_2  db  "HOUSE$"
    word_3  db  "SCHOOL$"
    word_4  db  "COMPUTER$"
    word_5  db  "FRIEND$"
    
    word_ptr        dw  6 dup(?)
    num_of_word     dw  0
    
    file_in_path    db  "C:\dictionary.txt", 0
    file_path       db  "C:\wordHunt.txt", 0
    file_handle     dw  ?
    file_ex_msg     db  "File Exception$"
    not_found_msg   db  "File not found: C:\emu8086\vdrive\C\dictionary.txt$"
    
    buffer      db  3000 dup(?)
    buffer_size dw  ?
ends

stack segment
    dw      128   dup(0)
ends

code segment
start:
    ; set segment registers:
    mov     ax, data
    mov     ds, ax
    mov     es, ax

main_loop:
    ; initialize, set word pointer for each word               
    ;call    set_word_ptr ; uncomment this and delete below line to disable reading word from file
    call get_word
    
    ; print a board in original size of screen 80x25 with random characters
    call    print_board
    
    mov     cx, num_of_word ; number of word to print  
    mov     si, 0 ; index for word_ptr  
    mov     di, 0 ; word direction
    word_print_loop:
        ; get start column index for horizontal direction
        mov     dh, 30
        mov     al, 00011111b ; AL = 31 to ensure that "and AL, DL"
        call    sort_number   ; get number between 0 and 30 
        
        ; get a number <= 30 first columns and multuply by 2, the word will be printed from even column <= 60
        ; num of col is 80 => we will not get overflow unless word's length is > 20   
        mov     al, dl
        mov     bl, 2
        mul     bl
        mov     dl, al
        mov     column, dl
                      
        ; get start line index for verticle direction
        mov     dh, 14 ; num of row is 24 so that we will not get overflow unless word's length is > 10       
        mov     al, 00011111b
        call    sort_number ; get a number x: 0 <= x <= 14
        mov     line, dl              
                          
        ; print              
        call    print_word
        xor     di, 00000001b ; change direction : if DI is 0->1 else 1->0
        add     si, 2 ; move to next word
        loop    word_print_loop
    
    ; check if stop program or create new board
    call    end_check 
    call    clear_screen
    jmp     main_loop  
            
fim:           
    mov     ax, 4c00h ; exit to operating system.
    int     21h

; get a number between 0 and DH; store in DL
sort_number:
    call    random
    mov     dl, byte ptr rndnum ; use byte ptr because rndnum is dw = 2 bytes    
    and     dl, al
    cmp     dl, dh
    jg      sort_number ; if greater than DH => get other number
    
    ret

print_word: ; print word stored in SI; DI:0 = vertical, DI:1 = horizontal    
    pushf
    push    ax
    push    dx
    push    si
    push    di

    call    set_cursor
    mov     si, word_ptr[si]
    do_print_word:            
        mov     ax, ds:[si]
        cmp     al, "$" ; if see '$' => end of word => stop printing
        je      end_print_word
        call    print_custon_character   
        inc     si
            
        cmp     di, 0    
        je      inc_line ; direction is vertical => move to next line
        cmp     di, 1
        je      inc_column 
        return_check_position:
        call    set_cursor 
        
        ; if direction is horizontal, print blank space    
        cmp     di, 1
        je      print_blank_space
               
        return_print_blank_space:
        jmp     do_print_word
    
    end_print_word: 
    pop     di
    pop     si
    pop     dx
    pop     ax
    popf
    ret 
              
    inc_line:
        inc     line
        jmp     return_check_position
    
    inc_column:
        inc     column        
        jmp     return_check_position 
        
    print_blank_space:
        mov     al, " "      
        call    print_custon_character
        inc     column
        call    set_cursor
        jmp     return_print_blank_space
    
 
end_check:
    call    export_board
      
    pushf
    push    ax
    
    mov     ah, 1
    int     21h
    ; if enter 'e' => terminate. Otherwise, create new board 
    cmp     al, "E"
    je      fim
    cmp     al, "e"
    je      fim
    
    pop     ax
    popf
    ret       
       
clear_screen:   ; clear everything from screen, get and set video mode 
    pushf
    push    ax
    
    mov     ah, 0fh
    int     10h   
    mov     ah, 0
    int     10h
    
    pop     ax
    popf
    ret
 
set_word_ptr:
    ; use 0,2,4,... index because word_ptr is dw = 2 bytes
    mov     word_ptr[0], offset word_1
    mov     word_ptr[2], offset word_2
    mov     word_ptr[4], offset word_3
    mov     word_ptr[6], offset word_4
    mov     word_ptr[8], offset word_5
    ret 
 
; print content stored in AL       
print_custon_character:   
    pushf
    push    ax
    push    bx
    push    cx

    mov     ah, 09h
    mov     bh, page_number   
    mov     bl, 10 ; color: light green
    mov     cx, 1 ; number of times to print
    int     10h 
    
    pop     cx
    pop     bx
    pop     ax
    popf
    ret
    
; print board with all random character
print_board:
    pushf
    push    cx
    push    dx

    mov     cx, 24 * 40 ; 24 lines x 40 characters/line
    
    print_board_loop:
    ; get new random letter
    call    random
    mov     dl, byte ptr rndnum    
    and     dl, 00011111b
    add     dl, "A"
    
    ; check if is letter
    cmp     dl, "A"
    jl      print_board_loop
    cmp     dl, "Z"
    jg      print_board_loop   
    
    ; print letter and space   
    call    print_character     
    mov     dl, " "        
    call    print_character
    
    loop    print_board_loop 
    
    pop     dx
    pop     cx
    popf        
    ret
    
; print character stored in DL 
print_character: 
    pushf
    push    ax
    
    mov     ah, 2
    int     21h     
    
    pop     ax
    popf
    ret
                   
; get random number and store in rndnum                 
random:
    pushf    
    push    ax
    push    cx
	push    dx
	
	; get system time: CH = hour, CL = minute, DH = second, DL = milisecond
	mov     ah, 2ch
	int     21h
		
	mov     ax, seed ; ax = seed
	
	add     al, dh

	mov     dx, 8405h ; dx = 8405h
	mul     dx ; mul (8405h * seed) into dword dx:ax

	cmp     ax, seed
	jnz     gotseed ; if new seed = old seed, alter seed. Otherwise, jump to gotseed
	mov     ah, dl
	inc     ax
    
    gotseed:
	mov     seed, ax ; we have a new seed, so store it
	mov     ax, dx ; al = random number
	mov     rndnum, ax  
	
	pop     dx    
	pop     cx
	pop     ax  
	popf
    ret
      
      
set_cursor:
    pushf
    push    ax
    push    bx
    push    dx
                  
    mov     ah, 2
    mov     bh, page_number
    mov     dh, line
    mov     dl, column
    int     10h
    
    pop     dx
    pop     bx
    pop     ax
    popf    
    ret         
ends




; ================= MO RONG: DOC TU FILE, GHI RA FILE ====================

export_board proc
    pushf
    pusha
    
    ; create file wordHunt.txt at ...\emu8086\vdrive\C
    mov     cx, 0 ; file mode: normal
    lea     dx, file_path
    call    create_file
    
    ; write to file
    ;   1. save all chars from screen (24 rows x 40 cols) into buffer
    call    fill_in_buffer 
    ;   2. save from buffer to file
    mov     ah, 40h
    mov     bx, file_handle
    mov     cx, buffer_size ; num of bytes to write
    lea     dx, buffer ; start location/address to write  
    int     21h 
    
    ; close file
    call    close_file
    
    finish_export:
    popa
    popf
    ret
export_board endp

; get chars from screen and store into buffer
fill_in_buffer proc
    pushf
    push    ax
    push    di
    
    mov     line, 0
    mov     di, offset buffer ; pointer to iterate through buffer
    mov     buffer_size, 0
    
    get_screen_loop:    
        mov column, 0
        get_screen_line:
            call    set_cursor
            ; get char at current position save to DL
            call    read_char_screen
            ; store char at DL into buffer
            call    write_char_buffer
            inc     column; go to next column
            cmp     column, 80 ; get 80 characters each line = original size of screen
            jl      get_screen_line
        
        ; write more break line at the end of line
        mov     dl, 0Ah
        call    write_char_buffer
            
        inc     line ; go to next line
        cmp     line, 24 ; we will traverse all 24 rows
        jl      get_screen_loop
    
    pop     di
    pop     ax    
    popf
    ret
fill_in_buffer endp

; write char in DL to buffer
write_char_buffer proc
    mov     [di], dl ; write char in DL to buffer
    inc     buffer_size
    inc     di ; move to next index in buffer
    ret
write_char_buffer endp

; read char at cur position of cursor save to DL
read_char_screen proc
    push    ax
    push    bx
    
    mov     ah, 8
    mov     bh, page_number
    int     10h
    mov     dl, al
    
    pop     bx
    pop     ax
    ret
read_char_screen endp

; get word from dictionary.txt and make word_ptr array
get_word proc
    pusha
    pushf
    ; open file
    mov     al, 0 ; open for reading only
    lea     dx, file_in_path
    call    open_file
    
    ; read file to buffer
    call    read_file_to_buffer
    
    ; make word_ptr
    call    make_word_ptr_from_buffer
    
    ; close file
    call    close_file
    jmp     end_get_word
        
    end_get_word:
    popf
    popa
    ret
get_word endp

; set word pointer with chars in buffer read from file
make_word_ptr_from_buffer proc
    pushf
    push    ax
    push    cx
    push    di
    push    si
    
    mov     cx, 5 ; max number of word
    mov     si, offset buffer   ; iterate through buffer
    mov     di, offset word_ptr ; iterate through word_ptr array
    mov     [di], offset buffer
    make_word_ptr:
        ; read char from buffer to AL & check if is end of line character (0Dh)
        mov     al, [si]
        cmp     al, 0Dh
        je      complete_word
        ; if is '#' or 00 => all word were added
        cmp     al, '#'
        je      finish_make_ptr
        cmp     al, 00h
        je      finish_make_ptr
        inc     si ; go to next char in buffer
        jmp     skip
        
        complete_word:
            ; mark end of word
            mov     [si], '$'
            ; add word ptr
            add     si, 2 ; skip 2 char 0Dh & 0Ah
            add     di, 2
            mov     [di], si ; add next ptr
            inc     num_of_word
            dec     cx
        
        skip:
        cmp     cx, 0
        jne     make_word_ptr
        
    finish_make_ptr:
    
    popf
    pop     si
    pop     di
    pop     cx
    pop     ax
    ret    
make_word_ptr_from_buffer endp

; create file with path saved in DX and attribute in CX
create_file proc
    pushf
    push    ax
    
    mov     ah, 3ch
    int     21h
    jc      file_ex_err
    mov     file_handle, ax
    
    pop     ax
    popf
    ret
create_file endp

; open file with patht saved in DX and mode in AL
open_file proc
    pushf
    push    ax
    
    mov     ah, 3dh
    int     21h
    jc      file_not_found_err
    mov     file_handle, ax
    
    pop     ax
    popf
    ret
open_file endp

; read file and save to buffer
read_file_to_buffer proc
    pushf
    pusha
    
    mov     ah, 3fh
    mov     bx, file_handle
    mov     cx, 3000
    lea     dx, buffer
    int     21h
    jc      file_ex_err
    
    popa
    popf
    ret
read_file_to_buffer endp    

close_file proc
    pushf
    push    ax
    push    bx
    
    mov     ah, 3eh
    mov     bx, file_handle
    int     21h
    jc      file_ex_err
    
    pop     bx
    pop     ax
    popf
    ret
close_file endp
    
file_not_found_err:
    mov     ah, 9
    lea     dx, not_found_msg
    int     21h
    ret
        
file_ex_err:
    mov     ah, 9
    lea     dx, file_ex_msg
    int     21h
    ret

end start