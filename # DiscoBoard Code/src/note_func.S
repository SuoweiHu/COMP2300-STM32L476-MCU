.syntax unified
@ ======================= INTERFACE ======================
.global char_offset, note_offset, hash_offset, readNoteArray


@ ==================== IMPLEMENTATION ======================
.type char_offset, %function
char_offset:
  @ this function is going to take a register containing assci string, 
  @ and return the offset of the 1st char to ascii value A(41) in R0
  @ (e.g r0=B, B:42->A:41, then will return 42-41=1)

  @ Note that it is lowest character in bits that it cares
  @ in the r0: say r0 = DCBA, then 'A' will be treated as
  @ the cahracter

  push {lr}
  push {r4-r11}

  @ reset the unrequired bits in r0
  lsl r0, 24
  lsr r0, 24

  @ compare it to A (41)
  mov r5, #0x00000041

  @ find offset from A
  sub r0, r0, r5

  pop {r4-r11}
  pop {lr}
  bx lr
.size char_offset,.-char_offset

.type note_offset, %function
note_offset:
  @ this function is going to take a register containing assci string, 
  @ and return the 2nd char's corresponding value in int:
  @     h ->  1 * span of A->NextA (high)
  @     c ->  0      (center)
  @     l -> -1 * span of A->NextA (low)

  @ Note that it is highest character in bits that it cares
  @ in the r0: say r0 = lChA, then 'h' will be treated as the note
  @ shift character

  @ PARAM:
  @     R0: note containing offset char(e.g AhXX)
  @ RETRUN:
  @     R0: offset in byte from center c 

  push {lr}
  push {r4-r11}

  @ reset the unrequired bits in r0
  lsr r0, 24

  @ compare it to h (68)
  mov r6, #14           @ note offset
  mov r5, #0x00000068
  cmp r5, r0
  beq end_note_offset_comparison

  @ compare it to c (63)
  mov r6, #0            @ note offset
  mov r5, #0x00000063
  cmp r5, r0
  beq end_note_offset_comparison

  @ compare it to l (6c)
  mov r7, #1
  mov r6, #0
  sub r7, r6, r7
  mov r6, #14
  mul r6, r7, r6        @ note offset
  mov r5, #0x0000006c
  cmp r5, r0
  beq end_note_offset_comparison

  @ compare it to s (73)
  mov r7, #1
  mov r6, #0
  sub r7, r6, r7
  mov r6, #28
  mul r6, r7, r6        @ note offset
  mov r5, #0x00000073
  cmp r5, r0
  beq end_note_offset_comparison

  @ otherwise
  mov r6, #0           
  beq end_note_offset_comparison

  end_note_offset_comparison:
    mov r0, r6          @ stored note offset in r0

  pop {r4-r11}
  pop {lr}
  bx lr
.size note_offset,.-note_offset

.type hash_offset. %function 
hash_offset:
    @ this function is going to return 1 if the second character 
    @ of the note is a hash (e.g G#) is it is return 1, 0 otherwise 
    push {lr}
    push {r4-r11}

    @ remove thre unwanted parts
    lsl r0, 16
    lsr r0, 16
    lsr r0, 8
    mov r4, #0

    @ compare it to # (23)
    mov r5, #0x00000023
    cmp r0, r5
    bne end_hash_offset_
        mov r4, #1
    end_hash_offset_:
        mov r0, r4

    pop {r4-r11}
    pop {lr}
    bx lr 
.size hash_offset,.-hash_offset

.type extact_time. %function 
extact_time:
    @ this function is going extact time from a register that 
    @ contains 4 character, the time character will be on the 3rd 
    @ character:

    @ char    time (sec)
    @ a   ->   1/8 
    @ b   ->   1/4 
    @ c   ->   1/3 
    @ d   ->   1/2
    @ e   ->   2/3
    @ f   ->   3/4
    @ g   ->   1/1  

    push {lr}
    push {r4-r11}

    @ remove thre unwanted parts
    lsl r0, 8
    lsr r0, 8
    lsr r0, 16

    @ compare it to a (61)
    ldr r6, =SEC_QUART_HALF
    mov r5, #0x00000061
    cmp r5, r0
    beq end_extact_time_comparison

    @ compare it to b
    ldr r6, =SEC_QUART_ONE
    mov r5, #0x00000062
    cmp r5, r0
    beq end_extact_time_comparison

    @ compare it to c
    ldr r6, =SEC_ONE_THIRD
    mov r5, #0x00000063
    cmp r5, r0
    beq end_extact_time_comparison

    @ compare it to d
    ldr r6, =SEC_QUART_TWO
    mov r5, #0x00000064
    cmp r5, r0
    beq end_extact_time_comparison

    @ compare it to e
    ldr r6, =SEC_TWO_THIRD
    mov r5, #0x00000065
    cmp r5, r0
    beq end_extact_time_comparison

    @ compare it to f
    ldr r6, =SEC_QUART_THREE
    mov r5, #0x00000066
    cmp r5, r0
    beq end_extact_time_comparison

    @ compare it to g
    mov r6, #1000      @ 1000 ms
    mov r5, #0x00000067
    cmp r5, r0
    beq end_extact_time_comparison

    end_extact_time_comparison:
        mov r0, r6

    pop {r4-r11}
    pop {lr}
    bx lr 
.size extact_time,.-extact_time

.type readNoteArray, %function
readNoteArray:
    push {lr}
    push {r4-r11}
    
    mov r10, r0     @ the base address in r10
    mov r9, 4       @ the load offset (index where upto basically)
    ldr r8, [r10]   @ the size of the array 

    loop_readNoteArray:
        cmp r8, #1
        blt endloop_readNoteArray

        ldr r0, [r10, r9]   @ load the characters to r0
        add r9, #4

        mov r4, #0          @ initialize the final note offset
        
        push {r0-r3}
        bl note_offset
        add r4, r4, r0      @ add the offset causeed by h/l/c
        pop {r0-r3}

        push {r0-r3}
        bl char_offset
        mov r1, #2
        mul r0, r0, r1
        add r4, r4, r0      @ add the offset causeed by different note (A/B/C/...)
        pop {r0-r3}

        push {r0-r3}
        bl hash_offset
        add r4, r4, r0      @ add the offset causeed by hash (A/A#; C/C#)
        pop {r0-r3}

        push {r0-r3}
        bl extact_time
        mov r11, r0          @ extract the time 
        pop {r0-r3}

        @ now in the r4 will be the offset in bytes from center A
        ldr r0, =G_SCORE_CENTER_A
        mov r5, #4
        mul r4, r4, r5

        cmp r4, #0x000000c7        @ if inputted inproper ascii char, use silence
        bgt use_silience_freq
        push {r5}
        ldr r5, =#0xfffffe71
        cmp r4, r5                 @ if inputted inproper ascii char, use silence
        pop {r5}
        blt use_silience_freq
        
        use_sound_freq: 
            ldr r0, [r0, r4]    @ frequency now in r0
            mov r1, r11         @ duration now in r1
            b end_use_freq
        use_silience_freq:
            ldr r0, =IDLE       @ frequency is now as IDLE (the play_xx_for_yy will use silence)
            mov r1, r11         @ duration now in r1
            b end_use_freq
        end_use_freq:
            nop
        

        push {r0-r3}
        bl play_xx_for_yy   @ use r0 and r1 to play wave
        pop {r0-r3}

        push {r0-r3}
        ldr r0, =IDLE
        mov r1, #10
        bl play_xx_for_yy
        pop {r0-r3}

        sub r8, #1                 
        b loop_readNoteArray
    endloop_readNoteArray:
        nop

    pop {r4-r11}
    pop {lr}
    bx lr
.size readNoteArray,.-readNoteArray
