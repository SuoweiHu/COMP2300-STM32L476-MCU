.syntax unified
@ ======================= INTERFACE ======================
.global get_wave_pos, play_multi_notes,play_xxS_for_yy, play_pitchArrayNotes
.global WAVEs_DATA, DEMO_1_NOTEs_DATA,DEMO_NOTEs_DUR_DATA_SLIENCE, DEMO_NOTE_DUR_DATA_COMBINED

@ ==================== IMPLEMENTATION ======================
.type get_wave_pos, %function
get_wave_pos:
  @ This function take the input of (Desired Frequency * 100) in r0, (such that the 2 decimal will be included) 
  @ and the base address of a wave data (a special data structure that contains 4 parts: WAVE_POSITION, 
  @ WAVE_DELTA, WAVE_STATE and WAVE_ACCUMULATOR)

  @ WAVE_DATA:   offset (base address in r2)
  @   WAVE_POSIT   [0]  @ the position of the line 
  @   WAVE_DELAT   [4]  @ the delta of line (the wave will reset if delta changes)
  @   WAVE_STATE   [8]  @ 0 if line's downward, 1 otherwise
  @   WAVE_ACCU    [12] @ the remainder of the division (will add 1 if reached 48000)
  
  @ It uses the calculate_delta_2dec to calcuate the Quotient of "Amplitude_Range * Desired_Freq * 2 / (Audio_Freq)",
  @ as well as the Remainder of the equation, the remainder is counted (using accumulartor stored at WAVE_ACCUMUL)
  @ then used to comapre with the divisor, once it become larger than the divior, the Quotient will get +1, and the
  @ counter/ accumulator (at WAVE_ACCUMUL) will reset. With this mechanism I can handle the decimals at a higher 
  @ degree of precision than the simple rounding up.

  @ The Quotient is used then as the delta of y of the point, which will be added/ subtracted to the current position
  @ of the point (stored at WAVE_POSITION) in each iteration. The new position is soted back, and retruned in r0
  @ (This value is later used to play the wave)

  @ PARAMETER:
  @     R0: Desired Freqency * 100
  @     R1: The base address of a certain wave data
  @ RETRUN:
  @     R0: The position of the point (for later BSP_AUDIO_OUT_Play_Sample) 
  
  
  push {lr}
  push {r4-r11}

  @ store the base address some where safre
  mov r7, r1
  
  @ ==================================================================
  @ If the "Input Frequency" in r0 changes, then re-initialize the wave
  @ ==================================================================
  push {r0}
  bl calculate_delta_2dec   @ calculate Desired frequency's delta (already in r0 with 2dec included)
  ldr r4, [r7,#4]           @  load the previous delta 
  cmp r4, r0
  bne ResetWave             
  b ResetWave_End
  ResetWave:
    @ (removed due to buzz issue) 
    @ ldr r4, =WAVE_POSITION  @ reset wave position 
    @ ldr r5, [r4]
    @ mov r5, 0x00007fff
    @ str r5, [r4]
    @ (removed due to buzz issue)
    mov r5, 0x00000000      @ reset wave steate (go up/down)
    str r5, [r7,#8]
    mov r5, r0              @ reset wave delta
    str r5, [r7,#4]
    mov r5, #0              @ reset wave accumularotr (records the remainder)
    str r5, [r7,#12]    
  ResetWave_End:
    nop
  pop {r0}
  @ ==================================================================
  
  @ ==================================================================
  @ If the Accumulator for remainder reaches the Audio Jack Freqnecy value which
  @ is also the divisor of the equation: "Amplitude_Range * Desired_Freq * 2 / (Audio_Freq)"
  @ then reset the accumulator and delta +1 (this for decimal issues)
  @ ==================================================================
  ldr r4, [r7,#4]               @ load the delta
  ldr r5, [r7,#12]              @ load the accumularot (sum of remainder for making up the decimal issue)

  ldr r6, =HEADPHONE_FREQUENCY  @ reset accumulartor and add 1 to delta 
  cmp r5, r6                    @ if total remainder >= 48000 
  bge ResetRemainder
  b ResetRemainder_end
  ResetRemainder:
    add r4, #1                  @ add delta by 1
    mov r6, #0
    ldr r6, [r7,#12]            @ reset accumulator
  ResetRemainder_end:
    nop
  @ ==================================================================

  
  @ ==================================================================
  @ Add or Minus delta/ quotient of equation to existing value
  @ ==================================================================
  ldr r9, [r7,#8]
  cmp r9, #0
  beq DownwardSlope @ condiional branch on state (go up / down)
  b UpwardSlope

  UpwardSlope:
    @ in this part the delta will be added to the current value
    mov r9, r7              @ add delta to the existing value
    ldr r10, [r9]
    add r10, r10, r4
    ldr r8, =AMP_TOP        
    cmp r10, r8             @ change state and snap to top amplitude if reached top
    bgt  ReachedTop
    b ReachedTop_end
    ReachedTop:
      mov r10, r8      
      mov r4, #0
      mov r3, r7            @ set state to downward slope (so in next iteration it will go down)
      add r3, r3, #8
      str r4, [r3]         
      mov r3, r7            @ reset the accumulator
      add r3, r3, #12
      str r4, [r3]         

    ReachedTop_end:
      nop
    str r10, [r9]           @ store the value of position back to where it came from

    bl calculate_delta      @ now add the remainder to the accumulator
    mov r4, r7
    add r4, #12
    ldr r5, [r4] 
    add r5, r5, r1
    str r5, [r4]

    b End_Slope
    
  DownwardSlope:
    @ in this part the delta will be subtracted from the current value 
    mov r9, r7              @ sub delta to the existing value
    ldr r10, [r9]
    sub r10, r10, r4
    ldr r8, =AMP_BOT        
    cmp r10, r8             @ change state and snap to top amplitude if reached top
    blt ReachedBot
    b ReachedBot_end
    ReachedBot:
      mov r10, r8      
      mov r4, #1
      mov r3, r7            @ set state to downward slope (so in next iteration it will go down)
      add r3, #8
      str r4, [r3]         
      mov r3, r7            @ reset the accumulator
      add r3, #12
      str r4, [r3]         

    ReachedBot_end:
      nop
    str r10, [r9]           @ store the value of position back to where it came from

    bl calculate_delta      @ now add the remainder to the accumulator
    mov r4,r7
    add r4,#12
    ldr r5, [r4] 
    add r5, r5, r1
    str r5, [r4]
  
    b End_Slope
  @ ==================================================================

  @ ==================================================================
  @ Play the wave
  @ ==================================================================
  End_Slope:
    mov r0, r10             @ make sound  
  @ ==================================================================
  pop {r4-r11}
  pop {lr}
  bx lr
.size get_wave_pos, .-get_wave_pos

.type play_multi_notes, %function 
play_multi_notes:
  @ This function will take the param of a NOTEs data 
  @ which is made of the following:

  @ NOTEs Data:
  @     NUMBER OF NOTES (e.g N>=1)
  @     NOTE_1 Frequency
  @     NOTE_2 Freuqency 
  @     .....
  @     NOTE_n Frequency

  @ PARAM:
  @    R0: The base address of a NOTEs Data 
  @    R1: The base address of a WAVE DATA 
  @ RETURN:
  @    R0: The Combined Position R0 (Also playing the sound)

  push {lr}
  push {r4-r11}

  ldr r7, [r0]        @ Load the number of notes (to play at the same time)
  add r0, #4          @ Move R5 to the address of the first note
  mov r4, #0          @ Clear R0's average accumulator

  cmp r7, #0          @ If being 0 then use 0 as r0 to play sound (a delay basically)
  beq endLoop_EachNote
  
  push {r0-r3}
  ldr r0, [r0]        @ Load this note
  bl get_wave_pos     @ Get this note's r0
  add r4, r0          @ add to average accumulator 
  pop {r0-r3} 
  add r0, #4          @ Next note
  add r1, r1, #16     @ Go to the next wave

  loop_EachNote:      @ For each note combine its R0 value to R4 (average)
    cmp r7, #1
    ble endLoop_EachNote

    push {r0-r3}
    ldr r0, [r0]        @ Load this note
    bl get_wave_pos     @ Get this note's r0
    mov r1, #2
    sdiv r4, r4, r1
    sdiv r0, r0, r1
    add r4, r0          @ add to average accumulator 
    pop {r0-r3} 
    add r0, #4          @ Next note
    add r1, r1, #16     @ Go to the next wave

    sub r7, r7, #1
    b loop_EachNote

  endLoop_EachNote:
    push {r0-r3}
    mov r0, r4      @ Now r0 contains the combined wave y position 
    bl BSP_AUDIO_OUT_Play_Sample 
    pop {r0-r3}

  
  pop {r4-r11}
  pop {lr}
  bx lr
.size play_multi_notes,.-play_multi_notes

.type play_xxS_for_yy, %function
play_xxS_for_yy:
  @ Ths funcction is going to take a NOTEs_DUR DATA's base 
  @ address and play the notes in it at a time with specified delay

  @ NOTEs_DUR DATA:
  @   DURATION IN MILLISEC
  @   NOTEs DATA:       NUMBER OF NOTE
  @                     NOTE 1's Freuqency
  @                     NOTE 2's Freuqency
  @                     .....
  @                     NOTE n's Freuqency

  @ PARAM:
  @   R0: the base address of NOTEs DUR DATA
  @ RETURN:
  @   N/A (play sound)

  push {lr}
  push {r4-r11}

  ldr r1, [r0]               @ Load duration in Mseconds 
  ldr r4, =HEADPHONE_FREQUENCY
  mov r5, #1000
  udiv r4, r4, r5            @ ITER_PER_SEC / 1000Ms 
  mul r1, r4, r1             @ ITER_PER_SEC * r1 Ms / 1000Ms
  add r0, 4                  @ Move address to the NOTEs Data 

  loop_play_xxS_for_yy:
      cmp r1, #1
      ble endloop_play_xxS_for_yy

      @ play sound
      push {r0-r3}
      ldr r1, =WAVEs_DATA
      bl play_multi_notes
      pop {r0-r3}

      sub r1, #1
      b loop_play_xxS_for_yy
  endloop_play_xxS_for_yy:
    pop {r4-r11}
    pop {lr}
    bx lr
.size play_xxS_for_yy,.-play_xxS_for_yy

.type play_pitchArrayNotes, %function
play_pitchArrayNotes:
  @ This function is going to take a Array containing NOTEs_DUR Data
  @ And play the notes (if multiple/one note is specified to play at the 
  @ same time it will play them/it, if none then it is trated as a delay)

  @ Example Array:
  @     SIZE ARRYA 
  @     NOTEs_DUR_1:
  @         DURATION
  @         NOTEs_DATA: SIZE NOTES
  @                     NOTE 1 Freq
  @                     NOTE 2 Freq
  @                     NOTE n Freq
  @     NOTEs_DUR_2: 
  @         .... 
  @     NOTEs_DUR_n: 
  @         ....
  
  
  @ This function is basially a mock of play_pitchArray, so intersted 
  @ for more detailed comment on how it works, please also check that as well


  push {lr}
  push {r4-r11} 
  ldr r4, [r0]    @ load the size of the array 
  add r0, 4       @ point to the first NOTEs_DUE Data

  loop_play_pitchArrayNotes:
    cmp r4, #1 
    blt endplay_pitchArrayNotes


    mov r9, #4
    ldr r10, [r0, #4]
    mul r10, r10, r9 
    add r10, #8

    push {r0-r3}
    bl play_xxS_for_yy
    pop {r0-r3}

    add r0, r0, r10

    sub r4, #1
    b loop_play_pitchArrayNotes

  endplay_pitchArrayNotes:
    nop  

  pop {r4-r11}
  pop {lr}
  bx lr
.size play_pitchArrayNotes,.-play_pitchArrayNotes

.data
DEMO_NOTEs_DUR_DATA_SLIENCE:
  .word 1000
  .word 0
DEMO_NOTE_DUR_DATA_COMBINED:
  .word 1000
  DEMO_1_NOTEs_DATA:
    .word 0x00000001
    .word 22000
    .word 44000
    .word 88000
    .word 176000
    .word 352000
WAVEs_DATA:
  @ This data struction is containing the parameter of the wave 
  @ (SOME VAR THAT HELPS THE "Play_Sound" FUNCTION)

  @ 1st wave 
  WAVE_DATA:
    WAVE_POSITION:  .word 0x00007fff  @ the position of the line
    WAVE_DELTA:     .word 0x00000000  @ the delta of line (the wave will reset if delta changes)
    WAVE_STATE:     .word 0x00000000  @ 0 if line's downward, 1 otherwise
    WAVE_ACCUMUL:   .word 0x00000000  @ the remainder of the division (will add 1 if reached 48000)
  @ 2nd wave 
  .word 0x00007fff
  .word 0x00000000
  .word 0x00000000
  .word 0x00000000
  @ 3rd wave 
  .word 0x00007fff
  .word 0x00000000
  .word 0x00000000
  .word 0x00000000
  @ 4th wave 
  .word 0x00007fff
  .word 0x00000000
  .word 0x00000000
  .word 0x00000000
  @ 5th wave 
  .word 0x00007fff
  .word 0x00000000
  .word 0x00000000
  .word 0x00000000
  @ ...
  .word 0x00007fff
  .word 0x00000000
  .word 0x00000000
  .word 0x00000000
  @ ...
  .word 0x00007fff
  .word 0x00000000
  .word 0x00000000
  .word 0x00000000
  @ ...
  .word 0x00007fff
  .word 0x00000000
  .word 0x00000000
  .word 0x00000000
  @ ...
  .word 0x00007fff
  .word 0x00000000
  .word 0x00000000
  .word 0x00000000
  @ 10th wave 
  .word 0x00007fff
  .word 0x00000000
  .word 0x00000000
  .word 0x00000000
  @ 11th wave 
  .word 0x00007fff
  .word 0x00000000
  .word 0x00000000
  .word 0x00000000
  @ 12th wave 
  .word 0x00007fff
  .word 0x00000000
  .word 0x00000000
  .word 0x00000000
  @ 13th wave 
  .word 0x00007fff
  .word 0x00000000
  .word 0x00000000
  .word 0x00000000
  @ 14th wave 
  .word 0x00007fff
  .word 0x00000000
  .word 0x00000000
  .word 0x00000000
  @ 15th wave 
  .word 0x00007fff
  .word 0x00000000
  .word 0x00000000
  .word 0x00000000


  
