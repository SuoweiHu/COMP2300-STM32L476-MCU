.syntax unified
@ ======================= INTERFACE ======================
.global init_sound, calculate_delta, calculate_delta_2dec, play_sound, play_xx_for_yy, play_pitchArray


@ ==================== IMPLEMENTATION ======================
.type init_sound, %function
init_sound:
  @ This function is going to be used to setup perpheral 
  @ devices with the help of init
  push {lr}             @ Save Link Register
  push {r4-r11}         @ Save Callee-save Registers
  bl init
  bl BSP_AUDIO_Buffer   @ TODO: un-Comment this when you finish debug !
  pop {r4-r11}
  pop {lr}
  bx lr
.size init_sound, .-init_sound

.type calculate_delta, %function
calculate_delta:
  @ DEPRECATED!
  @ (Used calculate_delta_2dec instead)
  @ ======================================================
  @ This function is going to take the input of a frequency 
  @ stoed in r0 and retrun the amount of delta (triangle)
  
  @ PARAMETER:
  @     R0: Desired Frequency 
  @ RETRUN:
  @     R0: Quotient  of "Amplitude_Range * Desired_Freq * 2 / (Audio_Freq)"
  @     R1: Remainder of "Amplitude_Range * Desired_Freq * 2 / (Audio_Freq)"


  push {lr}     @ Save Link Register
  push {r4-r11} @ Save Callee-save Registers

  @ Use Equation:
  @      2 * Amplitude_Range/(Board_Freq / Desired_Freq)
  @ or = Amplitude_Range * Desired_Freq * 2 / (Board_Freq)
  @ or = Amplitude_Range * Desired_Freq / (Board_Freq/2)

  @ e.g (2*(32767*2+1)*440/48000-1201)*48000

  @ Calculation of divisor 
  ldr r4, =AMP_TOP @ Amplitude max
  ldr r5, =AMP_BOT @ Amplitude min
  sub r5, r4, r5   @ Amplitude range 
  @ -
  ldr r6, =HEADPHONE_FREQUENCY  @ Board Freq (Headphone)
  @ -
  mov r4, r0       @ Desired Freq in r4
  mul r7, r4, r5   @ Amplitude_Range * Desired_Freq
  lsl r7, #1       @ Amplitude_Range * Desired_Freq * 2
  udiv r8, r7, r6  @ Amplitude_Range * Desired_Freq * 2 / Board_Freq
  @ -
  mov r0, r8       @ Move the result to r0

  @ Calculation of remainder 
  mul r4, r8, r6   @ Board_Freq * Quotient in r4
  sub r9, r7, r4   @ Amplitude_Range * Desired_Freq * 2 - Quotient * Board_freq
  @ -
  mov r1, r9       @ Move the result to r1

  pop {r4-r11}  @ Restore Callee-save Registers
  pop {lr}      @ Restore Link Register
  bx lr
.size calculate_delta, .-calculate_delta

.type calculate_delta_2dec, %function
calculate_delta_2dec:
  @ This function inherit the knolege from calculate_delta, which
  @ is to preserve both divisor and remainder for division, and later 
  @ in the caller function of calculate_delta_2dec, will accumulate 
  @ this remainder, and when reaches certian threshold, will increment
  @ the delta by 1 (there by acheiving the more precise approximating
  @ of the calculation)

  @ PARAMETER:
  @     R0: Desired Frequency * 100 (such that 2 more deciaml are preserved)
  @ RETRUN:
  @     R0: Quotient  of "Amplitude_Range * Desired_Freq * 2 / (Audio_Freq)"
  @     R1: Remainder of "Amplitude_Range * Desired_Freq * 2 / (Audio_Freq)"

  push {lr}     @ Save Link Register
  push {r4-r11} @ Save Callee-save Registers
  
  push {r0}
  mov r1, #100
  udiv r0, r0, r1                 @ Desired Frequency (Rounded)  -- Decimal processed after line: ==RESULT: Quotient==
  ldr r4, =AMP_TOP                @ Amplitude max
  ldr r5, =AMP_BOT                @ Amplitude min
  sub r5, r4, r5                  @ Amplitude range 
  ldr r6, =HEADPHONE_FREQUENCY    @ AudioJack Frequency
  mov r4, r0                      @ Desired Freuqncy
  mul r7, r4, r5                  @ Amplitude_Range * Desired Freuqncy
  lsl r7, #1                      @ Amplitude_Range * Desired Freuqncy * 2
  udiv r8, r7, r6                 @ Amplitude_Range * Desired Freuqncy * 2 / AudioJack Frequency
  push {r0}
  mov r0, r8                      @ ==RESULT: Quotient==

  mul r4, r8, r6                  @ AudioJack Frequency * Quotient in r4
  sub r9, r7, r4                  @ Amplitude_Range * Desired Freuqncy * 2 - Quotient * AudioJack Frequency
  mov r4, #100
  pop {r1}
  mul r1, r1, r4                  @ Desired Frequency (Rounded) * 100
  pop {r4}                        @ Desired Freuqncy * 100
  sub r4, r4, r1                  @ Desired Freuqncy Decials * 100 || or ||  Desired Freuqncy * 100 - Desired Frequency (Rounded) * 100
  mov r1, #100                                       
  udiv r5, r5, r1                 @ Amplitude range /100    
  mul r4, r4, r5                  
  lsl r4, #1                      @ Amplitude range * Desired Freuqncy Decials * 2
  add r9, r9, r4
  mov r1, r9                      @ ==RESULT: Remainder==

  pop {r4-r11}  @ Restore Callee-save Registers
  pop {lr}      @ Restore Link Register
  bx lr
.size calculate_delta_2dec, .-calculate_delta_2dec

.type play_sound, %function
play_sound:
  @ This function take the input of (Desired Frequency * 100) in r0, (such that the 2 decimal will be included) 
  
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
  @ RETRUN:
  @     R0: The position of the point (for later BSP_AUDIO_OUT_Play_Sample) 
  
  
  push {lr}
  push {r4-r11}
  
  @ ==================================================================
  @ If the "Input Frequency" in r0 changes, then re-initialize the wave
  @ ==================================================================
  push {r0}
  bl calculate_delta_2dec   @ calculate Desired frequency's delta (already in r0 with 2dec included)
  ldr r4, =WAVE_DELTA       @ load the previous delta 
  ldr r4, [r4]    
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
    ldr r4, =WAVE_STATE     @ reset wave steate (go up/down)
    ldr r5, [r4]  
    mov r5, 0x00000000
    str r5, [r4]
    ldr r4, =WAVE_DELTA     @ reset wave delta
    ldr r5, [r4]
    mov r5, r0
    str r5, [r4]
    ldr r4, =WAVE_ACCUMUL   @ reset wave accumularotr (records the remainder)
    ldr r5, [r4]
    mov r5, #0
    str r5, [r4]
  ResetWave_End:
    nop
  pop {r0}
  @ ==================================================================
  
  @ ==================================================================
  @ If the Accumulator for remainder reaches the Audio Jack Freqnecy value which
  @ is also the divisor of the equation: "Amplitude_Range * Desired_Freq * 2 / (Audio_Freq)"
  @ then reset the accumulator and delta +1 (this for decimal issues)
  @ ==================================================================
  ldr r4, =WAVE_DELTA           @ load the delta
  ldr r4, [r4]
  ldr r5, =WAVE_ACCUMUL         @ load the accumularot (sum of remainder for making up the decimal issue)
  ldr r5, [r5]

  ldr r6, =HEADPHONE_FREQUENCY  @ reset accumulartor and add 1 to delta 
  cmp r5, r6                    @ if total remainder >= 48000 
  bge ResetRemainder
  b ResetRemainder_end
  ResetRemainder:
    add r4, #1                  @ add delta by 1
    ldr r5, =WAVE_ACCUMUL 
    mov r6, #0
    ldr r6, [r5]
  ResetRemainder_end:
    nop
  @ ==================================================================

  
  @ ==================================================================
  @ Add or Minus delta/ quotient of equation to existing value
  @ ==================================================================
  ldr r9, =WAVE_STATE
  ldr r9, [r9]
  cmp r9, #0
  beq DownwardSlope @ condiional branch on state (go up / down)
  b UpwardSlope

  UpwardSlope:
    @ in this part the delta will be added to the current value
    ldr r9, =WAVE_POSITION  @ add delta to the existing value
    ldr r10, [r9]
    add r10, r10, r4
    ldr r8, =AMP_TOP        
    cmp r10, r8             @ change state and snap to top amplitude if reached top
    bgt  ReachedTop
    b ReachedTop_end
    ReachedTop:
      mov r10, r8      
      mov r4, #0
      ldr r3, =WAVE_STATE   @ set state to downward slope (so in next iteration it will go down)
      str r4, [r3]         
      ldr r3, =WAVE_ACCUMUL @ reset the accumulator
      str r4, [r3]         

    ReachedTop_end:
      nop
    str r10, [r9]           @ store the value of position back to where it came from

    bl calculate_delta      @ now add the remainder to the accumulator
    ldr r4, =WAVE_ACCUMUL
    ldr r5, [r4] 
    add r5, r5, r1
    str r5, [r4]

    b End_Slope
    
  DownwardSlope:
    @ in this part the delta will be subtracted from the current value 
    ldr r9, =WAVE_POSITION  @ sub delta to the existing value
    ldr r10, [r9]
    sub r10, r10, r4
    ldr r8, =AMP_BOT        
    cmp r10, r8             @ change state and snap to top amplitude if reached top
    blt ReachedBot
    b ReachedBot_end
    ReachedBot:
      mov r10, r8      
      mov r4, #1
      ldr r3, =WAVE_STATE   @ set state to downward slope (so in next iteration it will go down)
      str r4, [r3]         
      ldr r3, =WAVE_ACCUMUL @ reset the accumulator
      str r4, [r3]         

    ReachedBot_end:
      nop
    str r10, [r9]           @ store the value of position back to where it came from

    bl calculate_delta      @ now add the remainder to the accumulator
    ldr r4, =WAVE_ACCUMUL
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
    bl BSP_AUDIO_OUT_Play_Sample
  @ ==================================================================
  

  pop {r4-r11}
  pop {lr}
  bx lr
.size play_sound, .-play_sound

.type play_xx_for_yy. %function
play_xx_for_yy:
  @ This function will play a tone/pitch (wave of desired frequency)
  @ or pause in silence if the parameter passes IDLE.

  @ PARAMTER:
  @   R0: Desired Frequency * 100 or IDLE (if wish to delay)
  @   R1: Milli-seconds the sound will continue playing
  @ RETRUN:
  @   N/A (Outcome is keep playing sound for a specified duration)

  push {lr}
  push {r4-r11}

  @ ======================================================
  @ Calculate the iteration to stop (stores in r1)
  @ ======================================================
  ldr r4, =IDLE             
  cmp r4, r0
  bne playing_sound_state
  not_playing_sound_state:        @ if in idle: use board frequency
    ldr r4, =HEADPHONE_FREQUENCY@BOARD_FREQUENCY
    b end_playing_sound_state
  playing_sound_state:            @ if not in idle: use audio jack freuqency
    ldr r4, =HEADPHONE_FREQUENCY
    b end_playing_sound_state
  end_playing_sound_state:
    nop

  mov r5, #1000
  udiv r4, r4, r5            @ ITER_PER_SEC / 1000Ms 
  mul r1, r4, r1             @ ITER_PER_SEC * r1 Ms / 1000Ms
  @ ======================================================


  @ ======================================================
  @ Play sound for XX ms, or delay for XX ms
  @ ======================================================
  Loop_playSoundFor:
    cmp r1, #1
    blt endLoop_playSoundFor      @ terminate if iteration reached

    ldr r4, =IDLE                 @ check if r0 == IDLE 
    cmp r4, r0
    beq skip_playSoundFor         @ if not then run ""play_sound" function, otherwise skip it

    push {r0-r3}
    bl play_sound                 @ play sound with the help of previously defined function
    pop {r0-r3}

    b end_skip_playSoundFor

    skip_playSoundFor:
      
      ldr r4, =WAVE_POSITION     
      ldr r4, [r4]
      ldr r5, =0x00007fff
      cmp r4, r5
      beq continue_empty

      @ continue_wave:       @ keep the wave going if not at initial position just yet 
      @   push {r0-r3}       @ (it is later found that this will result in glitched sound)
      @   bl play_sound                 
      @   pop {r0-r3}
      @   b skip_continue

      continue_empty:        @ otherwise keep the r0 at a fixed dot
        push {lr}
        push {r0-r3}
        ldr r0, =WAVE_POSITION
        ldr r0, [r0]
        bl BSP_AUDIO_OUT_Play_Sample 
        pop {r0-r3} 
        pop {lr}

      skip_continue:
        nop

    end_skip_playSoundFor:
      nop

    sub r1, r1, #1                @ change i
    b Loop_playSoundFor

  endLoop_playSoundFor:
    nop
  @ ======================================================



  pop {r4-r11}
  pop {lr}
  bx lr
.size play_xx_for_yy,.-play_xx_for_yy

.type play_pitchArray, %function
play_pitchArray:
  @ This function is going take input of an PitchArray ('s address)
  @ and play the pitches with the proper delay using the data within
  @ the given PitchArray
  
  @ PARAMETER:
  @   R0: The base address of a PitchArray
  @ RETURN
  @   N/A (outcome is to play the pattern)

  @ Example:
  @   ldr r0, =PitchArray_SOTW
  @   bl play_pitchArray

  push {lr}        @ Link Register
  push {r4-r11}    @ Callee-save Register

  @ ======================================================
  @ Read the first element that gives the size of the pitch array
  @ ======================================================
  mov r10, r0       @ the base address of the array in r10
  ldr r8, [r10]     @ size of the array
  mov r9, 4         @ the load offset (will +8 in each iteration)
  @ ======================================================


  @ ======================================================
  @ Iterate over every item in the array and run "play_xx_for_yy" to play the corresponding pitch
  @ ======================================================
  loop_playPitchArray:
    cmp r8, #1                  @ stop if reached i (counter) the end 
    blt endloop_playPitchArray
    
    ldr r0, [r10, r9]           @ load "100xFrequency" part from the array (x100 is for the accuracy)
    add r9, #4
    ldr r1, [r10, r9]           @ load the "Duration" part from the array
    add r9, #4
    
    push {r0-r3}
    bl play_xx_for_yy           @ play sound using function in sound_func.S file
    pop {r0-r3}

    sub r8, #1                  @ decrement i (counter for the array)
    b loop_playPitchArray

  endloop_playPitchArray:
    nop
  @ ======================================================

  pop {r4-r11}
  pop {lr}
  bx lr
.size play_pitchArray,.-play_pitchArray

.data
WAVE_PARAM:
  @ This data struction is containing the parameter of the wave 
  @ (SOME VAR THAT HELPS THE "Play_Sound" FUNCTION)
  WAVE_POSITION:  .word 0x00007fff  @ the position of the line  
  WAVE_DELTA:     .word 0x00000000  @ the delta of line (the wave will reset if delta changes)
  WAVE_STATE:     .word 0x00000000  @ 0 if line's downward, 1 otherwise
  WAVE_ACCUMUL:   .word 0x00000000  @ the remainder of the division (will add 1 if reached 48000)
