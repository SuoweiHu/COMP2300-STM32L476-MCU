.syntax unified
@ I mis-interpreted the concept of ADSR so everything you are seeing 
@ here that's labeled as ADSR is actaully JUST A SYNTH 


@ ======================= INTERFACE ======================
@ Functions 
.global play_sound_adsr, playADSR_xx_for_yy,

@ Function Testting 
.global TEST_ADSR_GUITAR, TEST_ADSR_ELECTRIC_GUITAR, TEST_ADSR_FLUTE, TEST_ADSR

@ ADSR_WAVE_DATA 
.global TEST_ADSR_DELAY
.global TEST_ADSR_TRIANGLE, TEST_ADSR_SAWTOOTH
.global GUITAR_ADSR_WAVE_DATA, ELECTRIC_GUITAR_ADSR_WAVE_DATA, FLUTE_ADSR_WAVE_DATA
.global TEST_ADSR_DIGITAL_1, TEST_ADSR_DIGITAL_2, TEST_ADSR_DIGITAL_3

@ ================ FUNCTION IMPLEMENTATION ================
.type cal_delta_fromTo_within, %function
cal_delta_fromTo_within:
  @ This function will take input of two values of y (y0,y1), and the value of x delta (dx)
  @ return the absolute value of delta y in each x, i.e. return abs(y1-y0)/dx, as well as 
  @ the decimal part (was preserved by x10000)


  @ PARAMETER:
  @   R0: the from y-value 
  @   R1: the to y-value 
  @   R2: the delta x-value
  @ RETURN:
  @   R0: |y1-y0|/dx 
  @   R1: decimal part x10000
  push {lr}
  push {r4-r11}

  @ ======================================================
  @ Swap values of from and to if requird
  @ ======================================================
  SWAP_FROM_TO:
    cmp r0, r1 
    blt skip_swap_number
      mov r4, r1
      mov r1, r0
      mov r0, r4
    skip_swap_number:
      nop
  @ ======================================================
  
  @ ======================================================
  @ calcualte the difference ('s absolute value)
  @ ======================================================
  CAL_DIFF_DELTA:
    sub r4, r1, r0    @ (y_from - y_to)
    udiv r5, r4, r2   @ (y_from - y_to) / dx

    mul r6, r5, r2    
    sub r7, r4, r6    @ Remainder  

    mov r6, #10000
    mul r7, r7, r6    @ Remainder *10000
    udiv r8, r7, r2   @ Deciaml *10000 

    mov r1, r8
    mov r0, r5
  @ ======================================================

  pop {r4-r11}
  pop {lr}  
  bx lr
.size cal_delta_fromTo_within,.-cal_delta_fromTo_within

.type play_sound_adsr, %function
play_sound_adsr:
  @ this function is going to take the parameter of the desired frequency address 
  @ of a ADSR paramteer and a WAVE parameter, and play the sound of the wave that
  @ uses an amplitude envelope to change the shape of the notes

  @ PARAM:
  @   R0: The desired frequency
  @   R1: The base address of the WAVE parameter 
  @   R2: The base address of the ADSR parameter 
  @ RETRUN:
  @   R0: The wave position (y) and play the wave

  push {lr}
  push {r4-r11}

  mov r9, r0
  mov r10, r1
  mov r11, r2

  @ ======================================================
  @ check if the frequency has changed (reset wave if true)
  @ ======================================================
  ADSR_INIT:
    ldr r4, [r1]          @ load the freuqency on record 
    cmp r4, r0  
    beq skip_adsr_reset

    adsr_reset:
      push {r9-r11}

      str r0, [r1]        @ store the current frequency 

      mov r4, #0          @ reset the (ADSR) phase 
      str r4, [r1, 4]     

      ldr r4, =0xffff8000 @ reset the position to bottom
      str r4, [r1, 8] 

      ldr r4, =HEADPHONE_FREQUENCY
      udiv r5, r4, r0     @ Sample Points per period

      @ ========
      mov r11, #0         @ the recorder for the decimal

            
      ldr r4, [r2, #0]    @ A_PROPORTION in %%
      mul r6, r5, r4   
      mov r7, #10000       
      udiv r4, r6, r7  
      str r4, [r1, #12]   @ Attack points
      mul r7, r4, r7
      sub r8, r6, r7
      mov r7, #10000



      ldr r4, [r2, #4]    @ D_PROPORTION in %%
      mul r6, r5, r4  
      mov r7, #10000       
      udiv r4, r6, r7   
      str r4, [r1, #16]   @ Decay points
      mul r7, r4, r7
      sub r8, r6, r7
      mov r7, #10000


      ldr r4, [r2, #12]   @ R_PROPORTION in %%
      mul r6, r5, r4 
      mov r7, #10000       
      udiv r4, r6, r7    
      str r4, [r1, #24]   @ Release points
      mul r7, r4, r7
      sub r8, r6, r7
      mov r7, #10000


      ldr r4, [r2, #8]    @ S_PROPORTION in %%
      mul r4, r5, r4 
      mov r6, #10000       
      udiv r4, r4, r6
      udiv r11, r11, r6
      add r4, r4, r11
      str r4, [r1, #20]   @ Sustain points

      pop {r9-r11}

    skip_adsr_reset:
      ldr r2, [r2, 16]    @ load the sustain position (for later use in sustain_phase)
  @ ======================================================

  @ ======================================================
  @ Using the info in ADSR Wave to 'jump' to a one of the phase (ADSR)
  @ (some setup is done before jumping when a phase first starts)
  @ ======================================================
  ADSR_PHASE_JUMP:

    @ ========ATTACK========
    @ A init: 
    @   reset the position y back to bottom
    ldr r4, [r1, #4]   @ Load the phase value
    mov r5, #0
    cmp r4, r5
    bne skip_a_phase_init
      ldr r5, =0xffff8000
      str r5, [r1, #8]  @ set the starting value to be bottom
      add r4, #1
      str r4, [r1, #4]   @ store incremented phase index

      push {r0-r3}
      ldr r2, [r1, #12]  @ load the totoal number of potins
      @ add r2, r2, #1@ XXXXXXXX
      ldr r0, =0xffff8000
      ldr r1, =0x00007fff
      bl cal_delta_fromTo_within
      mov r4, r0
      pop {r0-r3}
      str r4, [r1, #28] @ store the delta
    skip_a_phase_init:
      nop

    @ A continue:
    @  check if the attack still have remaining potins
    ldr r4, [r1, #4]  
    mov r5, #1 
    cmp r4, r5
    bne skip_a_phase_cont
      ldr r5, [r1, #12]@ Load remaining Attack points
      cmp r5, #1
      bgt Attack_Phase
      add r4, #1
      str r4, [r1, #4]
    skip_a_phase_cont:
      nop

    @ ========DECAY=========
    @ D init
    ldr r4, [r1, 4]  
    mov r5, #2
    cmp r4, r5
    bne skip_d_phase_init
      ldr r5, =0x00007fff
      str r5, [r1, #8]
      add r4, #1
      str r4, [r1, #4]

      push {r0-r3}
      mov r3, r2
      ldr r2, [r1, #16]  
      @ add r2, r2, #1@ XXXXXXXX
      ldr r0, =0x00007fff
      mov r1, r3
      bl cal_delta_fromTo_within
      mov r4, r0
      pop {r0-r3}
      str r4, [r1, #28] 
      
    skip_d_phase_init:
      nop

    @ D continue 
    ldr r4, [r1, #4]   
    mov r5, #3 
    cmp r4, r5
    bne skip_d_phase_cont
      ldr r5, [r1, 16]@ Load remaining Decay points
      cmp r5, #1
      bgt Decay_Phase
      add r4, #1
      str r4, [r1, 4] 
    skip_d_phase_cont:
      nop

    @ =======SUSTAIN==========
    @ S init
    ldr r4, [r1, #4] 
    mov r5, #4
    cmp r4, r5
    bne skip_s_phase_init
      mov r5, r2
      str r5, [r1, #8]
      add r4, #1
      str r4, [r1, #4]

      push {r0-r3}
      mov r3, r2
      ldr r2, [r1, #20]  
      @ add r2, r2, #1@ XXXXXXXX
      mov r0, r3
      mov r1, r3
      bl cal_delta_fromTo_within
      mov r4, r0
      pop {r0-r3}
      str r4, [r1, #28] 
    skip_s_phase_init:
      nop

    @ S continue 
    ldr r4, [r1, 4]  
    mov r5, #5
    cmp r4, r5
    bne skip_s_phase_cont
      ldr r5, [r1, 20]@ Load remaining Sustian points
      cmp r5, #1
      bgt Sustain_Phase
      add r4, #1
      str r4, [r1, 4] 
    skip_s_phase_cont:
      nop

    @ =======Release==========
    @ R init
    ldr r4, [r1, 4]  
    mov r5, #6
    cmp r4, r5
    bne skip_r_phase_init
      mov r5, r2
      str r5, [r1, #8]
      add r4, #1
      str r4, [r1, 4]

      push {r0-r3}
      mov r3, r2
      ldr r2, [r1, #24]  
      @ add r2, r2, #1@ XXXXXXXX
      mov r0, r3
      ldr r1, =0xffff8000
      bl cal_delta_fromTo_within
      mov r4, r0
      pop {r0-r3}
      str r4, [r1, #28] 
    skip_r_phase_init:
      nop

    @ R continue 
    ldr r4, [r1, 4]  
    mov r5, #7 
    cmp r4, r5
    bne skip_r_phase_cont
      ldr r5, [r1, 24]@ Load remaining Release points
      cmp r5, #1
      bgt Release_Phase
      mov r4, #0
      mov r0, r9
      mov r1, r10
      mov r2, r11 
      b adsr_reset      
      str r4, [r1, 4] 
    skip_r_phase_cont:
      nop


  @ ====================================================

  @ ====================================================
  @ This is where the change of the postioon actually happens
  @ ====================================================
  ADSR_RUN_PHASE:
    Attack_Phase:
      ldr r6, [r1, #28] @ load the delta (will add/ minus)
      ldr r7, [r1, #8]  @ load the current position (y)
      add r7, r7, r6
      str r7, [r1, #8] 

      ldr r5, [r1, 12]  @ load the remaining points in attack
      sub r5, #1        @ decrement and store the number back
      str r5, [r1, 12]
      b End_Phase

    Decay_Phase:
      ldr r6, [r1, #28] 
      ldr r7, [r1, #8]  
      sub r7, r7, r6
      str r7, [r1, #8] 

      ldr r5, [r1, 16]
      sub r5, #1
      str r5, [r1, 16]
      b End_Phase

    Sustain_Phase:
      ldr r5, [r1, 20]
      sub r5, #1
      str r5, [r1, 20]
      b End_Phase

    Release_Phase:
      ldr r6, [r1, #28] 
      ldr r7, [r1, #8]  
      sub r7, r7, r6
      str r7, [r1, #8] 

      ldr r5, [r1, 24]
      sub r5, #1
      str r5, [r1, 24]
      b End_Phase

    End_Phase:
      ldr r0, [r1, #8]
      bl BSP_AUDIO_OUT_Play_Sample
  @ ====================================================
  
  pop {r4-r11}
  pop {lr}  
  bx lr
.size play_sound_adsr,.-play_sound_adsr

.type playADSR_xx_for_yy. %function
playADSR_xx_for_yy:
  @ This function will play a tone/pitch (wave of desired frequency), and the pitch have
  @ certain unique feature (uses an amplitude envelope to change the “shape” of the wave)
  @ the unique feature is decided by the passed in ADSR_WAVE data (/data structure), say
  @ if PIANO_ADSR_WAVE is given, it will play note that sounds likee piano instrament.

  @ or pause in silence if the desired frequency is passes IDLE (0xFFFFFFFF), 

  @ PARAMTER:
  @   R0: Desired Frequency * 100 or IDLE (if wish to delay)
  @   R1: Milli-seconds the sound will continue playing
  @   R2: Base parameter of ADSR_WAVE data (data structure)
  @ 
  @ RETRUN:
  @   N/A (Outcome is keep playing sound for a specified duration)

  push {lr}
  push {r4-r11}

  add r9, r2, #20     @ ADSR_WAVE_PARAM
  add r10, r9, #8     @ ADSR_WAVE_POSITION
  mov r11, r2         @ ADSR_PARAM

  @ ======================================================
  @ Calculate the iteration to stop (stores in r1)
  @ ======================================================
  CAL_ITER_TO_STOP_ADSR:
    ldr r4, =IDLE             
    cmp r4, r0
    bne playing_sound_state_ADSR          @ Check if frequency is idle

    not_playing_sound_state_ADSR:         @ if in idle: use board frequency
      ldr r4, =HEADPHONE_FREQUENCY        @ BOARD_FREQUENCY
      b end_playing_sound_state_ADSR

    playing_sound_state_ADSR:             @ if not in idle: use audio jack freuqency
      ldr r4, =HEADPHONE_FREQUENCY
      b end_playing_sound_state_ADSR

    end_playing_sound_state_ADSR:
      nop

    mov r5, #1000
    udiv r4, r4, r5                       @ ITER_PER_SEC / 1000Ms 
    mul r1, r4, r1                        @ ITER_PER_SEC * r1 Ms / 1000Ms
  @ ======================================================


  @ ======================================================
  @ Play sound for XX ms, or delay for XX ms
  @ ======================================================
  PLAY_SOUND_FOR_ITER_ADSR:
    Loop_playSoundFor_ADSR:
      cmp r1, #1
      blt endLoop_playSoundFor_ADSR       @ terminate if iteration reached

      ldr r4, =IDLE                       @ check if r0 == IDLE 
      cmp r4, r0                          @ @ if not then run "play_sound" function,
      beq skip_playSoundFor_ADSR          @ otherwise skip the function 
      
      playSoundFor_ADSR:
        @ play sound 
        push {r0-r3}
        mov r1, r9                        @ ADSR_WAVE_PARAM
        mov r2, r11                       @ ADSR_PARAM
        bl play_sound_adsr                @ Run play sound function
        pop {r0-r3}

      b end_skip_playSoundFor_ADSR

      skip_playSoundFor_ADSR:
        @ play with the same y 
        @ (rather than nothing, which will cause noise)
        push {lr}
        push {r0-r3}
        mov r0, r10                       @ Load and play ADSR_WAVE_POSITION
        bl BSP_AUDIO_OUT_Play_Sample  
        pop {r0-r3} 
        pop {lr}

      end_skip_playSoundFor_ADSR:
        nop

      sub r1, r1, #1                          @ change i
      b Loop_playSoundFor_ADSR

    endLoop_playSoundFor_ADSR:
      nop
  @ ======================================================



  pop {r4-r11}
  pop {lr}
  bx lr
.size playADSR_xx_for_yy,.-playADSR_xx_for_yy

@ ================== FUNCTION TESTING =====================

@ Macro ease for tests only
.macro TEST_ADSR_TONE frequency duation adsr_wave_data

  mov r0, \frequency
  mov r1, \duation
  ldr r2, =\adsr_wave_data
  bl playADSR_xx_for_yy
.endm 
.macro TEST_ADSR_DELAY duation adsr_wave_data
  ldr r0, =IDLE
  mov r1, \duation
  ldr r2, =\adsr_wave_data
  bl playADSR_xx_for_yy
.endm 

.type TEST_ADSR_DELAY. %function
TEST_ADSR_DELAY:
  push {lr}
  push {r4-r11}
  TEST_ADSR_DELAY #1100,ADSR_WAVE_DATA
  pop {r4-r11}
  pop {lr}
  bx lr
.size TEST_ADSR_DELAY,.-TEST_ADSR_DELAY

.type TEST_ADSR_GUITAR, %function
TEST_ADSR_GUITAR:
    push {lr}
    push {r4-r11}
    @TEST_ADSR_DELAY  #50,GUITAR_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #97,#200,GUITAR_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,GUITAR_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #110,#200,GUITAR_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,GUITAR_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #123,#200,GUITAR_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,GUITAR_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #131,#200,GUITAR_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,GUITAR_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #146,#200,GUITAR_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,GUITAR_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #165,#200,GUITAR_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,GUITAR_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #175,#200,GUITAR_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,GUITAR_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #196,#200,GUITAR_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,GUITAR_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #218,#200,GUITAR_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,GUITAR_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #241,#200,GUITAR_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,GUITAR_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #256,#200,GUITAR_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,GUITAR_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #286,#200,GUITAR_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,GUITAR_ADSR_WAVE_DATA

    @TEST_ADSR_DELAY  #50,GUITAR_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #286,#200,GUITAR_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,GUITAR_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #256,#200,GUITAR_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,GUITAR_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #241,#200,GUITAR_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,GUITAR_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #218,#200,GUITAR_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,GUITAR_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #196,#200,GUITAR_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,GUITAR_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #175,#200,GUITAR_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,GUITAR_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #165,#200,GUITAR_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,GUITAR_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #146,#200,GUITAR_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,GUITAR_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #131,#200,GUITAR_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,GUITAR_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #123,#200,GUITAR_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,GUITAR_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #110,#200,GUITAR_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,GUITAR_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #97,#200,GUITAR_ADSR_WAVE_DATA
    pop {r4-r11}
    pop {lr}
    bx lr
.size TEST_ADSR_GUITAR,.-TEST_ADSR_GUITAR

.type TEST_ADSR_ELECTRIC_GUITAR, %function
TEST_ADSR_ELECTRIC_GUITAR:
    push {lr}
    push {r4-r11}
    @TEST_ADSR_DELAY  #50,ELECTRIC_GUITAR_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #97,#200,ELECTRIC_GUITAR_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,ELECTRIC_GUITAR_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #110,#200,ELECTRIC_GUITAR_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,ELECTRIC_GUITAR_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #123,#200,ELECTRIC_GUITAR_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,ELECTRIC_GUITAR_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #131,#200,ELECTRIC_GUITAR_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,ELECTRIC_GUITAR_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #146,#200,ELECTRIC_GUITAR_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,ELECTRIC_GUITAR_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #165,#200,ELECTRIC_GUITAR_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,ELECTRIC_GUITAR_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #175,#200,ELECTRIC_GUITAR_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,ELECTRIC_GUITAR_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #196,#200,ELECTRIC_GUITAR_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,ELECTRIC_GUITAR_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #218,#200,ELECTRIC_GUITAR_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,ELECTRIC_GUITAR_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #241,#200,ELECTRIC_GUITAR_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,ELECTRIC_GUITAR_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #256,#200,ELECTRIC_GUITAR_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,ELECTRIC_GUITAR_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #286,#200,ELECTRIC_GUITAR_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,ELECTRIC_GUITAR_ADSR_WAVE_DATA

    @TEST_ADSR_DELAY  #50,ELECTRIC_GUITAR_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #286,#200,ELECTRIC_GUITAR_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,ELECTRIC_GUITAR_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #256,#200,ELECTRIC_GUITAR_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,ELECTRIC_GUITAR_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #241,#200,ELECTRIC_GUITAR_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,ELECTRIC_GUITAR_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #218,#200,ELECTRIC_GUITAR_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,ELECTRIC_GUITAR_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #196,#200,ELECTRIC_GUITAR_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,ELECTRIC_GUITAR_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #175,#200,ELECTRIC_GUITAR_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,ELECTRIC_GUITAR_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #165,#200,ELECTRIC_GUITAR_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,ELECTRIC_GUITAR_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #146,#200,ELECTRIC_GUITAR_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,ELECTRIC_GUITAR_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #131,#200,ELECTRIC_GUITAR_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,ELECTRIC_GUITAR_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #123,#200,ELECTRIC_GUITAR_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,ELECTRIC_GUITAR_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #110,#200,ELECTRIC_GUITAR_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,ELECTRIC_GUITAR_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #97,#200,ELECTRIC_GUITAR_ADSR_WAVE_DATA
    pop {r4-r11}
    pop {lr}
    bx lr
.size TEST_ADSR_ELECTRIC_GUITAR,.-TEST_ADSR_ELECTRIC_GUITAR

.type TEST_ADSR_FLUTE, %function
TEST_ADSR_FLUTE:
    push {lr}
    push {r4-r11}
    @TEST_ADSR_DELAY  #50,FLUTE_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #97,#200,FLUTE_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,FLUTE_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #110,#200,FLUTE_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,FLUTE_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #123,#200,FLUTE_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,FLUTE_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #131,#200,FLUTE_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,FLUTE_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #146,#200,FLUTE_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,FLUTE_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #165,#200,FLUTE_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,FLUTE_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #175,#200,FLUTE_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,FLUTE_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #196,#200,FLUTE_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,FLUTE_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #218,#200,FLUTE_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,FLUTE_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #241,#200,FLUTE_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,FLUTE_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #256,#200,FLUTE_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,FLUTE_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #286,#200,FLUTE_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,FLUTE_ADSR_WAVE_DATA

    @TEST_ADSR_DELAY  #50,FLUTE_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #286,#200,FLUTE_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,FLUTE_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #256,#200,FLUTE_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,FLUTE_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #241,#200,FLUTE_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,FLUTE_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #218,#200,FLUTE_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,FLUTE_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #196,#200,FLUTE_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,FLUTE_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #175,#200,FLUTE_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,FLUTE_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #165,#200,FLUTE_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,FLUTE_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #146,#200,FLUTE_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,FLUTE_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #131,#200,FLUTE_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,FLUTE_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #123,#200,FLUTE_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,FLUTE_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #110,#200,FLUTE_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,FLUTE_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #97,#200,FLUTE_ADSR_WAVE_DATA
    pop {r4-r11}
    pop {lr}
    bx lr
.size TEST_ADSR_FLUTE,.-TEST_ADSR_FLUTE

.type TEST_ADSR_SAWTOOTH, %function
TEST_ADSR_SAWTOOTH:
    push {lr}
    push {r4-r11}
    @TEST_ADSR_DELAY  #50,SAWTOOTH_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #97,#200,SAWTOOTH_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,SAWTOOTH_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #110,#200,SAWTOOTH_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,SAWTOOTH_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #123,#200,SAWTOOTH_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,SAWTOOTH_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #131,#200,SAWTOOTH_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,SAWTOOTH_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #146,#200,SAWTOOTH_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,SAWTOOTH_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #165,#200,SAWTOOTH_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,SAWTOOTH_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #175,#200,SAWTOOTH_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,SAWTOOTH_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #196,#200,SAWTOOTH_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,SAWTOOTH_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #218,#200,SAWTOOTH_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,SAWTOOTH_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #241,#200,SAWTOOTH_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,SAWTOOTH_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #256,#200,SAWTOOTH_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,SAWTOOTH_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #286,#200,SAWTOOTH_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,SAWTOOTH_ADSR_WAVE_DATA

    @TEST_ADSR_DELAY  #50,SAWTOOTH_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #286,#200,SAWTOOTH_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,SAWTOOTH_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #256,#200,SAWTOOTH_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,SAWTOOTH_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #241,#200,SAWTOOTH_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,SAWTOOTH_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #218,#200,SAWTOOTH_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,SAWTOOTH_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #196,#200,SAWTOOTH_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,SAWTOOTH_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #175,#200,SAWTOOTH_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,SAWTOOTH_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #165,#200,SAWTOOTH_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,SAWTOOTH_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #146,#200,SAWTOOTH_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,SAWTOOTH_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #131,#200,SAWTOOTH_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,SAWTOOTH_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #123,#200,SAWTOOTH_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,SAWTOOTH_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #110,#200,SAWTOOTH_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,SAWTOOTH_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #97,#200,SAWTOOTH_ADSR_WAVE_DATA
    pop {r4-r11}
    pop {lr}
    bx lr
.size TEST_ADSR_SAWTOOTH,.-TEST_ADSR_SAWTOOTH

.type TEST_ADSR_TRIANGLE, %function
TEST_ADSR_TRIANGLE:
    push {lr}
    push {r4-r11}
    @TEST_ADSR_DELAY  #50,TRIANGLE_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #97,#200,TRIANGLE_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,TRIANGLE_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #110,#200,TRIANGLE_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,TRIANGLE_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #123,#200,TRIANGLE_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,TRIANGLE_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #131,#200,TRIANGLE_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,TRIANGLE_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #146,#200,TRIANGLE_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,TRIANGLE_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #165,#200,TRIANGLE_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,TRIANGLE_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #175,#200,TRIANGLE_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,TRIANGLE_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #196,#200,TRIANGLE_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,TRIANGLE_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #218,#200,TRIANGLE_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,TRIANGLE_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #241,#200,TRIANGLE_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,TRIANGLE_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #256,#200,TRIANGLE_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,TRIANGLE_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #286,#200,TRIANGLE_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,TRIANGLE_ADSR_WAVE_DATA

    @TEST_ADSR_DELAY  #50,TRIANGLE_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #286,#200,TRIANGLE_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,TRIANGLE_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #256,#200,TRIANGLE_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,TRIANGLE_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #241,#200,TRIANGLE_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,TRIANGLE_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #218,#200,TRIANGLE_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,TRIANGLE_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #196,#200,TRIANGLE_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,TRIANGLE_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #175,#200,TRIANGLE_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,TRIANGLE_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #165,#200,TRIANGLE_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,TRIANGLE_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #146,#200,TRIANGLE_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,TRIANGLE_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #131,#200,TRIANGLE_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,TRIANGLE_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #123,#200,TRIANGLE_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,TRIANGLE_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #110,#200,TRIANGLE_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,TRIANGLE_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #97,#200,TRIANGLE_ADSR_WAVE_DATA
    pop {r4-r11}
    pop {lr}
    bx lr
.size TEST_ADSR_TRIANGLE,.-TEST_ADSR_TRIANGLE

.type TEST_ADSR_DIGITAL_1, %function
TEST_ADSR_DIGITAL_1:
    push {lr}
    push {r4-r11}
    @TEST_ADSR_DELAY  #50,DIGITAL_1_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #97,#200,DIGITAL_1_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,DIGITAL_1_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #110,#200,DIGITAL_1_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,DIGITAL_1_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #123,#200,DIGITAL_1_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,DIGITAL_1_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #131,#200,DIGITAL_1_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,DIGITAL_1_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #146,#200,DIGITAL_1_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,DIGITAL_1_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #165,#200,DIGITAL_1_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,DIGITAL_1_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #175,#200,DIGITAL_1_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,DIGITAL_1_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #196,#200,DIGITAL_1_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,DIGITAL_1_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #218,#200,DIGITAL_1_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,DIGITAL_1_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #241,#200,DIGITAL_1_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,DIGITAL_1_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #256,#200,DIGITAL_1_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,DIGITAL_1_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #286,#200,DIGITAL_1_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,DIGITAL_1_ADSR_WAVE_DATA

    @TEST_ADSR_DELAY  #50,DIGITAL_1_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #286,#200,DIGITAL_1_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,DIGITAL_1_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #256,#200,DIGITAL_1_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,DIGITAL_1_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #241,#200,DIGITAL_1_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,DIGITAL_1_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #218,#200,DIGITAL_1_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,DIGITAL_1_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #196,#200,DIGITAL_1_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,DIGITAL_1_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #175,#200,DIGITAL_1_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,DIGITAL_1_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #165,#200,DIGITAL_1_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,DIGITAL_1_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #146,#200,DIGITAL_1_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,DIGITAL_1_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #131,#200,DIGITAL_1_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,DIGITAL_1_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #123,#200,DIGITAL_1_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,DIGITAL_1_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #110,#200,DIGITAL_1_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,DIGITAL_1_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #97,#200,DIGITAL_1_ADSR_WAVE_DATA
    pop {r4-r11}
    pop {lr}
    bx lr
.size TEST_ADSR_DIGITAL_1,.-TEST_ADSR_DIGITAL_1

.type TEST_ADSR_DIGITAL_2, %function
TEST_ADSR_DIGITAL_2:
    push {lr}
    push {r4-r11}
    @TEST_ADSR_DELAY  #50,DIGITAL_2_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #97,#200,DIGITAL_2_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,DIGITAL_2_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #110,#200,DIGITAL_2_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,DIGITAL_2_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #123,#200,DIGITAL_2_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,DIGITAL_2_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #131,#200,DIGITAL_2_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,DIGITAL_2_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #146,#200,DIGITAL_2_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,DIGITAL_2_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #165,#200,DIGITAL_2_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,DIGITAL_2_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #175,#200,DIGITAL_2_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,DIGITAL_2_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #196,#200,DIGITAL_2_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,DIGITAL_2_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #218,#200,DIGITAL_2_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,DIGITAL_2_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #241,#200,DIGITAL_2_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,DIGITAL_2_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #256,#200,DIGITAL_2_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,DIGITAL_2_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #286,#200,DIGITAL_2_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,DIGITAL_2_ADSR_WAVE_DATA

    @TEST_ADSR_DELAY  #50,DIGITAL_2_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #286,#200,DIGITAL_2_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,DIGITAL_2_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #256,#200,DIGITAL_2_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,DIGITAL_2_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #241,#200,DIGITAL_2_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,DIGITAL_2_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #218,#200,DIGITAL_2_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,DIGITAL_2_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #196,#200,DIGITAL_2_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,DIGITAL_2_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #175,#200,DIGITAL_2_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,DIGITAL_2_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #165,#200,DIGITAL_2_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,DIGITAL_2_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #146,#200,DIGITAL_2_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,DIGITAL_2_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #131,#200,DIGITAL_2_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,DIGITAL_2_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #123,#200,DIGITAL_2_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,DIGITAL_2_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #110,#200,DIGITAL_2_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,DIGITAL_2_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #97,#200,DIGITAL_2_ADSR_WAVE_DATA
    pop {r4-r11}
    pop {lr}
    bx lr
.size TEST_ADSR_DIGITAL_2,.-TEST_ADSR_DIGITAL_2

.type TEST_ADSR_DIGITAL_3, %function
TEST_ADSR_DIGITAL_3:
    push {lr}
    push {r4-r11}
    @TEST_ADSR_DELAY  #50,DIGITAL_3_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #97,#200,DIGITAL_3_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,DIGITAL_3_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #110,#200,DIGITAL_3_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,DIGITAL_3_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #123,#200,DIGITAL_3_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,DIGITAL_3_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #131,#200,DIGITAL_3_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,DIGITAL_3_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #146,#200,DIGITAL_3_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,DIGITAL_3_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #165,#200,DIGITAL_3_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,DIGITAL_3_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #175,#200,DIGITAL_3_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,DIGITAL_3_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #196,#200,DIGITAL_3_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,DIGITAL_3_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #218,#200,DIGITAL_3_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,DIGITAL_3_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #241,#200,DIGITAL_3_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,DIGITAL_3_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #256,#200,DIGITAL_3_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,DIGITAL_3_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #286,#200,DIGITAL_3_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,DIGITAL_3_ADSR_WAVE_DATA

    @TEST_ADSR_DELAY  #50,DIGITAL_3_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #286,#200,DIGITAL_3_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,DIGITAL_3_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #256,#200,DIGITAL_3_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,DIGITAL_3_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #241,#200,DIGITAL_3_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,DIGITAL_3_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #218,#200,DIGITAL_3_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,DIGITAL_3_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #196,#200,DIGITAL_3_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,DIGITAL_3_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #175,#200,DIGITAL_3_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,DIGITAL_3_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #165,#200,DIGITAL_3_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,DIGITAL_3_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #146,#200,DIGITAL_3_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,DIGITAL_3_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #131,#200,DIGITAL_3_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,DIGITAL_3_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #123,#200,DIGITAL_3_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,DIGITAL_3_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #110,#200,DIGITAL_3_ADSR_WAVE_DATA
    @TEST_ADSR_DELAY  #50,DIGITAL_3_ADSR_WAVE_DATA
    TEST_ADSR_TONE   #97,#200,DIGITAL_3_ADSR_WAVE_DATA
    pop {r4-r11}
    pop {lr}
    bx lr
.size TEST_ADSR_DIGITAL_3,.-TEST_ADSR_DIGITAL_3



@ ================ ADSR DATA IMPLEMENTATION ================
.data 
GUITAR_ADSR_WAVE_DATA:
  @ this data strucure contains two parts:
  @     ADSR_PARAM
  @     ADSR_WAVE_PARAM
  @ with them you can play different waves that sounds like different 
  @ instrament, (it is "feeded" to function "playADSR_xx_for_yy")

  GUITAR_ADSR_PARAM:
    @ this data structure is for the Frequency Evelope, and is consists 
    @ of 5 part, first 4 values represnts the proportion of time given to each  
    @ part of the wave (ADSR), the last one represent the sustain value
    @ -
    @ Each of the following represent a part's (attack/decay/suistain/release)
    @ proportion among one pattern (format is in N%%, example 20% ---> 2000)
    A_PROP:   .word 0x000005dc @ [0] A Propotion
    D_PROP:   .word 0x00001770 @ [4] D Propotion
    S_PROP:   .word 0x00000000 @ [8] S Propotion
    R_PROP:   .word 0x000005dc @ [12] R Propotion
    @ -
    @ This will be the position of sustain (the flat line part)
    @ the value given must be in range from 0x8000 (min) to 0x7fff (max)
    S_POS:    .word 0x00001fff @ [16] S Position 

  ADSR_WAVE_PARAM:
    @ This data struction is containing the parameter of the adsr wave (amplitude envelope)
    ADSR_WAVE_FREQUENCY:  .word 0x00000000  @ [0]  the freuqency of the wave (will be setted when param is passed, use to detect if a change on frequency happens)
    ADSR_WAVE_PHASE:      .word 0x00000000  @ [4]  the phase the wave is at: A->0,1, D->2,3, S->4,5, R->6,7 (PREPARING TO INIT, WORKING ON IT)
    ADSR_WAVE_POSITION:   .word 0x00000000  @ [8]  the position of the line (initially at the bottom)
    A_REM_POINTS:         .word 0x00000000  @ [12] the point remaining to be 'drawn' in Attack (will be calculated in init)
    D_REM_POINTS:         .word 0x00000000  @ [16] the point remaining to be 'drawn' in Decay
    S_REM_POINTS:         .word 0x00000000  @ [20] the point remaining to be 'drwan' in Suistain
    R_REM_POINTS:         .word 0x00000000  @ [24] the point remaining to be 'drawn' in Release 
    ADSR_WAVE_DELTA:      .word 0x00000000  @ [28] the delta (each differs a little )

ELECTRIC_GUITAR_ADSR_WAVE_DATA:
    .word 0x000007d0  @ [0]  A Propotion
    .word 0x00000000  @ [4]  D Propotion
    .word 0x00001b58  @ [8]  S Propotion
    .word 0x000003e8  @ [12] R Propotion
    .word 0x00000fff  @ [16] S Position 
    .word 0x00000000  @ [20] Frequency
    .word 0x00000000  @ [24] Phase (A/D/S/R)
    .word 0x00000000  @ [28] Position/Y
    .word 0x00000000  @ [32] Remaining Points (A)
    .word 0x00000000  @ [36] Remaining Points (D)
    .word 0x00000000  @ [40] Remaining Points (S)
    .word 0x00000000  @ [44] Remaining Points (R)
    .word 0x00000000  @ [48] Delta Position/Y

FLUTE_ADSR_WAVE_DATA:
    .word 0x000003e8  @ [0]  A Propotion
    .word 0x000003e8  @ [4]  D Propotion
    .word 0x00001170  @ [8]  S Propotion
    .word 0x000007d0  @ [12] R Propotion
    .word 0x00004fff  @ [16] S Position 
    .word 0x00000000  @ [20] Frequency
    .word 0x00000000  @ [24] Phase (A/D/S/R)
    .word 0x00000000  @ [28] Position/Y
    .word 0x00000000  @ [32] Remaining Points (A)
    .word 0x00000000  @ [36] Remaining Points (D)
    .word 0x00000000  @ [40] Remaining Points (S)
    .word 0x00000000  @ [44] Remaining Points (R)
    .word 0x00000000  @ [48] Delta Position/Y

TRIANGLE_ADSR_WAVE_DATA:
    .word 0x00001388  @ [0]  A Propotion
    .word 0x00000000  @ [4]  D Propotion
    .word 0x00000000  @ [8]  S Propotion
    .word 0x00001388  @ [12] R Propotion
    .word 0x00007fff  @ [16] S Position 
    .word 0x00000000  @ [20] Frequency
    .word 0x00000000  @ [24] Phase (A/D/S/R)
    .word 0x00000000  @ [28] Position/Y
    .word 0x00000000  @ [32] Remaining Points (A)
    .word 0x00000000  @ [36] Remaining Points (D)
    .word 0x00000000  @ [40] Remaining Points (S)
    .word 0x00000000  @ [44] Remaining Points (R)
    .word 0x00000000  @ [48] Delta Position/Y

SAWTOOTH_ADSR_WAVE_DATA:
    .word 0x000026ac  @ [0]  A Propotion
    .word 0x00000000  @ [4]  D Propotion
    .word 0x00000000  @ [8]  S Propotion
    .word 0x00000064  @ [12] R Propotion
    .word 0x00007fff  @ [16] S Position 
    .word 0x00000000  @ [20] Frequency
    .word 0x00000000  @ [24] Phase (A/D/S/R)
    .word 0x00000000  @ [28] Position/Y
    .word 0x00000000  @ [32] Remaining Points (A)
    .word 0x00000000  @ [36] Remaining Points (D)
    .word 0x00000000  @ [40] Remaining Points (S)
    .word 0x00000000  @ [44] Remaining Points (R)
    .word 0x00000000  @ [48] Delta Position/Y

DIGITAL_1_ADSR_WAVE_DATA:
    .word 0x00001388  @ [0]  A Propotion
    .word 0x000001f4  @ [4]  D Propotion
    .word 0x00000fa0  @ [8]  S Propotion
    .word 0x000001f4  @ [12] R Propotion
    .word 0x00008700  @ [16] S Position 
    .word 0x00000000  @ [20] Frequency
    .word 0x00000000  @ [24] Phase (A/D/S/R)
    .word 0x00000000  @ [28] Position/Y
    .word 0x00000000  @ [32] Remaining Points (A)
    .word 0x00000000  @ [36] Remaining Points (D)
    .word 0x00000000  @ [40] Remaining Points (S)
    .word 0x00000000  @ [44] Remaining Points (R)
    .word 0x00000000  @ [48] Delta Position/Y


DIGITAL_2_ADSR_WAVE_DATA:
    .word 0x000003e8  @ [0]  A Propotion
    .word 0x00001388  @ [4]  D Propotion
    .word 0x00000000  @ [8]  S Propotion
    .word 0x00000fa0  @ [12] R Propotion
    .word 0x00008700  @ [16] S Position 
    .word 0x00000000  @ [20] Frequency
    .word 0x00000000  @ [24] Phase (A/D/S/R)
    .word 0x00000000  @ [28] Position/Y
    .word 0x00000000  @ [32] Remaining Points (A)
    .word 0x00000000  @ [36] Remaining Points (D)
    .word 0x00000000  @ [40] Remaining Points (S)
    .word 0x00000000  @ [44] Remaining Points (R)
    .word 0x00000000  @ [48] Delta Position/Y

DIGITAL_3_ADSR_WAVE_DATA:
    .word 0x00000fa0  @ [0]  A Propotion
    .word 0x00000bb8  @ [4]  D Propotion
    .word 0x000007d0  @ [8]  S Propotion
    .word 0x000003e8  @ [12] R Propotion
    .word 0x00008500  @ [16] S Position 
    .word 0x00000000  @ [20] Frequency
    .word 0x00000000  @ [24] Phase (A/D/S/R)
    .word 0x00000000  @ [28] Position/Y
    .word 0x00000000  @ [32] Remaining Points (A)
    .word 0x00000000  @ [36] Remaining Points (D)
    .word 0x00000000  @ [40] Remaining Points (S)
    .word 0x00000000  @ [44] Remaining Points (R)
    .word 0x00000000  @ [48] Delta Position/Y

ADSR_WAVE_DATA:
  @ this is for test and delay purpose
  .word 0x00000fa0  @ [0]  A Propotion
  .word 0x00000bb8  @ [4]  D Propotion
  .word 0x000007d0  @ [8]  S Propotion
  .word 0x000003e8  @ [12] R Propotion
  .word 0x00008500  @ [16] S Position 
  .word 0x00000000  @ [20] Frequency
  .word 0x00000000  @ [24] Phase (A/D/S/R)
  .word 0x00000000  @ [28] Position/Y
  .word 0x00000000  @ [32] Remaining Points (A)
  .word 0x00000000  @ [36] Remaining Points (D)
  .word 0x00000000  @ [40] Remaining Points (S)
  .word 0x00000000  @ [44] Remaining Points (R)
  .word 0x00000000  @ [48] Delta Position/Y

