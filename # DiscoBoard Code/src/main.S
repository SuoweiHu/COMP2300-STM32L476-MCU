.syntax unified

.global main

.type main, %function
main:
  bl init                              @ initialization of the sound peripherals
  bl BSP_AUDIO_Buffer                  @ remeber to comment it whild debugging
  LOOP:                                @ LOOP contains some demo functions ....
    @ ==============================================================================
    @ ========================  Demonstration Functions  ===========================
    @ ==============================================================================

    @ ============ ASCII NOTE TO PITCH =========== 
    @ Song: Uchiage Firework (UF)'s intro               (Very basic read array implementation)
    bl DEMO_UF_Array

    @ Song: Astronomia's Partial                        (Implmented with reading from special ASCII String)
    bl DEMO_AST_ASCII

    @ Song: Uchiage Firework (UF)'s partial             (Implemented with reading from special ASCII String)
    bl DEMO_UF_ASCII


    @ ======== MULTI NOTES HARMONEY DEMO ==========
    @ DEMO of playing 5 harmoic notes at a time       (Do not open this with other Demo)
    @ Fundamental 110hz, First harmonic 220hz, ... 330hz, ... 440hz, 550hz
    @ bl DEMO_FIVE_NOTES_AtATIME   

    @ DEMO of playing 10 harmonic notes at a time      (Do not open this with other Demo)     
    @ Fundamental 110hz, First harmonic 220hz, ... 330hz, .... ...., 1110
    bl DEMO_TEN_NOTES_AtATIME

    @ DEMO of "play multiple note at a time"            (CEG_OneNote, CEG_TwoNote, CEG_TreeNote)
    @ bl DEMO_MULTI_NOTES_ARRAY

    @ DEMO of using two harmonic note for the a song in part1: "Around the world"
    @ bl DEMO_ATW_MULTI_NOTES_ARRAY


    @ ========= SYNTH SADLY ===========
    @ Notes: Sounds Different Instrament                (Do not open this with other Demo)
    @ I mis-intrepreted the concept of ADSR, and thus created a wave 
    @ that is capable of changing its shape.... out of blue i created 
    @ this function just for a self-compliment. QAQ
    @ bl DEMO_PLAY_INSTRAMENTS 

    @ ==============================================================================
    @ ============================================================================== 
    
    b LOOP
.size main, .-main

.type DEMO_PLAY_INSTRAMENTS,%function
DEMO_PLAY_INSTRAMENTS:
  @ This is just a demo purpose function, for more detail,
  @ please check out the functions used interally
  push {lr}
  push {r4-r11}

  bl TEST_ADSR_TRIANGLE
  bl TEST_ADSR_DELAY
  bl TEST_ADSR_SAWTOOTH

  bl TEST_ADSR_DELAY
  bl TEST_ADSR_DELAY
  bl TEST_ADSR_DELAY

  bl TEST_ADSR_GUITAR
  bl TEST_ADSR_DELAY
  bl TEST_ADSR_ELECTRIC_GUITAR
  bl TEST_ADSR_DELAY
  bl TEST_ADSR_FLUTE

  bl TEST_ADSR_DELAY
  bl TEST_ADSR_DELAY
  bl TEST_ADSR_DELAY

  bl TEST_ADSR_DIGITAL_1
  bl TEST_ADSR_DELAY
  bl TEST_ADSR_DIGITAL_2
  bl TEST_ADSR_DELAY
  bl TEST_ADSR_DIGITAL_3

  pop {r4-r11}
  pop {lr}
  bx lr

.size DEMO_PLAY_INSTRAMENTS,.-DEMO_PLAY_INSTRAMENTS

.type DEMO_FIVE_NOTES_AtATIME,%function
DEMO_FIVE_NOTES_AtATIME:
  @ This is just a demo purpose function, for more detail,
  @ please check out the functions used interally

  push {lr}
  push {r4-r11}

  mov r0, #0  
  mov r4, #0
  ldr r1, =WAVEs_DATA 
  
  push {r0-r3}
  mov r0, #11001
  bl get_wave_pos
  add r4, r0
  pop {r0-r3}

  add r1, r1, #16
  push {r0-r3}
  ldr r0, =#22001
  bl get_wave_pos
  add r4, r0
  mov r0, #2
  sdiv r4, r4, r0
  pop {r0-r3}

  add r1, r1, #16
  push {r0-r3}
  ldr r0, =#33001
  bl get_wave_pos
  add r4, r0
  mov r0, #2
  sdiv r4, r4, r0
  pop {r0-r3}

  add r1, r1, #16
  push {r0-r3}
  ldr r0, =#44001
  bl get_wave_pos
  add r4, r0
  mov r0, #2
  sdiv r4, r4, r0
  pop {r0-r3}

  add r1, r1, #16
  push {r0-r3}
  ldr r0, =#550001
  bl get_wave_pos
  add r4, r0
  mov r0, #2
  sdiv r4, r4, r0
  pop {r0-r3}

  

  mov r0,r4
  bl BSP_AUDIO_OUT_Play_Sample
  
  pop {r4-r11}
  pop {lr}
  bx lr
.size DEMO_FIVE_NOTES_AtATIME,.-DEMO_FIVE_NOTES_AtATIME

.type DEMO_TEN_NOTES_AtATIME,%function
DEMO_TEN_NOTES_AtATIME:
  @ This is just a demo purpose function, for more detail,
  @ please check out the functions used interally

  push {lr}
  push {r4-r11}

  mov r0, #0  
  mov r4, #0
  ldr r1, =WAVEs_DATA 
  
  push {r0-r3}
  mov r0, #11001
  bl get_wave_pos
  add r4, r0
  pop {r0-r3}

  add r1, r1, #16
  push {r0-r3}
  ldr r0, =#22001
  bl get_wave_pos
  add r4, r0
  mov r0, #2
  sdiv r4, r4, r0
  pop {r0-r3}

  add r1, r1, #16
  push {r0-r3}
  ldr r0, =#33001
  bl get_wave_pos
  add r4, r0
  mov r0, #2
  sdiv r4, r4, r0
  pop {r0-r3}

  add r1, r1, #16
  push {r0-r3}
  ldr r0, =#44001
  bl get_wave_pos
  add r4, r0
  mov r0, #2
  udiv r4, r4, r0
  pop {r0-r3}

  add r1, r1, #16
  push {r0-r3}
  ldr r0, =#55001
  bl get_wave_pos
  add r4, r0
  mov r0, #2
  udiv r4, r4, r0
  pop {r0-r3}

  add r1, r1, #16
  push {r0-r3}
  ldr r0, =#66001
  bl get_wave_pos
  add r4, r0
  mov r0, #2
  udiv r4, r4, r0
  pop {r0-r3}

  add r1, r1, #16
  push {r0-r3}
  ldr r0, =#774001
  bl get_wave_pos
  add r4, r0
  mov r0, #2
  udiv r4, r4, r0
  pop {r0-r3}

  add r1, r1, #16
  push {r0-r3}
  ldr r0, =#88001
  bl get_wave_pos
  add r4, r0
  mov r0, #2
  udiv r4, r4, r0
  pop {r0-r3}

  add r1, r1, #16
  push {r0-r3}
  ldr r0, =#99001
  bl get_wave_pos
  add r4, r0
  mov r0, #2
  udiv r4, r4, r0
  pop {r0-r3}

  add r1, r1, #16
  push {r0-r3}
  ldr r0, =#111001
  bl get_wave_pos
  add r4, r0
  mov r0, #2
  udiv r4, r4, r0
  pop {r0-r3}

  mov r0,r4
  bl BSP_AUDIO_OUT_Play_Sample
  
  pop {r4-r11}
  pop {lr}
  bx lr
.size DEMO_TEN_NOTES_AtATIME,.-DEMO_TEN_NOTES_AtATIME

.type DEMO_UF_Array.%function
DEMO_UF_Array:
  @ This is just a demo purpose function, for more detail,
  @ please check out the functions used interally
  push {lr}
  ldr r0, =PitchArray_UF_Intro
  bl play_pitchArray 
  ldr r0, =PitchArray_UF_Intro
  bl play_pitchArray 
  pop {lr}
  bx lr
.size DEMO_UF_Array,.-DEMO_UF_Array

.type DEMO_UF_ASCII.%function
DEMO_UF_ASCII:
  @ This is just a demo purpose function, for more detail,
  @ please check out the functions used interally
  push {lr}
  ldr r0, =PitchArray_UF_Half
  bl readNoteArray 
  pop {lr}
  bx lr
.size DEMO_UF_ASCII,.-DEMO_UF_ASCII

.type DEMO_AST_ASCII.%function
DEMO_AST_ASCII:
  @ This is just a demo purpose function, for more detail,
  @ please check out the functions used interally
  push {lr}
  ldr r0, =PitchArray_AST
  bl readNoteArray 
  pop {lr}
  bx lr
.size DEMO_AST_ASCII,.-DEMO_AST_ASCII

.type DEMO_MULTI_NOTES_ARRAY.%function
DEMO_MULTI_NOTES_ARRAY:
  @ This is just a demo purpose function, for more detail,
  @ please check out the functions used interally
  push {lr}
  ldr r0, =PitchesArray_CEG_DATA
  bl play_pitchArrayNotes
  pop {lr}
  bx lr
.size DEMO_MULTI_NOTES_ARRAY,.-DEMO_MULTI_NOTES_ARRAY

.type DEMO_ATW_MULTI_NOTES_ARRAY.%function
DEMO_ATW_MULTI_NOTES_ARRAY:
  @ This is just a demo purpose function, for more detail,
  @ please check out the functions used interally
  push {lr}
  ldr r0, =PitchesArray_ATD_DATA
  bl play_pitchArrayNotes
  ldr r0, =PitchesArray_ATD_DATA
  bl play_pitchArrayNotes
  pop {lr}
  bx lr
.size DEMO_ATW_MULTI_NOTES_ARRAY,.-DEMO_ATW_MULTI_NOTES_ARRAY

.data
PitchesArray_ATD_DATA:
  .word 38
  .word 250
  .word 2
  .word Pitch_ATD_A
  .word Pitch_ATD_A_H
  .word 250
  .word 0
  .word 250
  .word 2
  .word Pitch_ATD_A
  .word Pitch_ATD_A_H
  .word 250
  .word 0
  .word 250
  .word 2
  .word Pitch_ATD_A
  .word Pitch_ATD_A_H
  .word 250
  .word 0
  .word 250
  .word 2
  .word Pitch_ATD_A
  .word Pitch_ATD_A_H
  .word 250
  .word 0

  .word 250
  .word 2
  .word Pitch_ATD_C
  .word Pitch_ATD_C_H
  .word 250
  .word 0
  .word 250
  .word 2
  .word Pitch_ATD_C
  .word Pitch_ATD_C_H
  .word 250
  .word 0
  .word 250
  .word 2
  .word Pitch_ATD_C
  .word Pitch_ATD_C_H
  .word 250
  .word 0
  .word 250
  .word 2
  .word Pitch_ATD_C
  .word Pitch_ATD_C_H

  .word 250
  .word 2
  .word Pitch_ATD_D
  .word Pitch_ATD_D_H

  .word 250
  .word 2
  .word Pitch_ATD_E
  .word Pitch_ATD_E_H
  .word 250
  .word 0
  .word 250
  .word 2
  .word Pitch_ATD_E
  .word Pitch_ATD_E_H
  .word 250
  .word 0
  .word 250
  .word 2
  .word Pitch_ATD_E
  .word Pitch_ATD_E_H
  .word 250
  .word 0
  .word 250
  .word 2
  .word Pitch_ATD_E
  .word Pitch_ATD_E_H
  .word 250
  .word 0

  .word 125
  .word 2
  .word Pitch_ATD_F_Special
  .word Pitch_ATD_F_Special_H
  .word 125
  .word 0

  .word 125
  .word 2
  .word Pitch_ATD_E
  .word Pitch_ATD_E_H
  .word 125
  .word 0

  .word 125
  .word 2
  .word Pitch_ATD_D
  .word Pitch_ATD_D_H
  .word 125
  .word 0

  .word 125
  .word 2
  .word Pitch_ATD_C
  .word Pitch_ATD_C_H
  .word 125
  .word 0

  .word 125
  .word 2
  .word Pitch_ATD_B
  .word Pitch_ATD_B_H
  .word 125
  .word 0

  .word 125
  .word 2
  .word Pitch_ATD_A
  .word Pitch_ATD_A_H
  .word 125
  .word 0
  .word 250
  .word 2
  .word Pitch_ATD_G
  .word Pitch_ATD_G_H
  .word 250
  .word 2
  .word Pitch_ATD_A
  .word Pitch_ATD_A_H


PitchesArray_CEG_DATA:
  SIZE: .word 24    @ Number of beats
  @ Single note at a time
  NOTEs_DUR_DATA_1_l_ONE:
    .word 250
    .word 1
    .word LOWER_C
  NOTEs_DUR_DATA_2_l_ONE:
    .word 250
    .word 1
    .word LOWER_E
  NOTEs_DUR_DATA_3_l_ONE:
    .word 250
    .word 1
    .word LOWER_G
  NOTEs_DUR_DATA_1_c_ONE:
    .word 250
    .word 1
    .word CENTER_C
  NOTEs_DUR_DATA_2_c_ONE:
    .word 250
    .word 1
    .word CENTER_E
  NOTEs_DUR_DATA_3_c_ONE:
    .word 250
    .word 1
    .word CENTER_G
  NOTEs_DUR_DATA_1_h_ONE:
    .word 250
    .word 1
    .word HIGHER_C
  NOTEs_DUR_DATA_2_h_ONE:
    .word 250
    .word 1
    .word HIGHER_E
  NOTEs_DUR_DATA_3_h_ONE:
    .word 250
    .word 1
    .word HIGHER_G

  @ Two notes at a time
  NOTEs_DUR_DATA_1_l_TWO:
    .word 250       @ Duration
    .word 2         @ Number of noe
    .word CENTER_C  @ First note 
    .word LOWER_C   @ Second note

  NOTEs_DUR_DATA_2_l_TWO:
    .word 250
    .word 2
    .word CENTER_E
    .word LOWER_E
  NOTEs_DUR_DATA_3_l_TWO:
    .word 250
    .word 2
    .word CENTER_G
    .word LOWER_G

  NOTEs_DUR_DATA_1_c_TWO:
    .word 250
    .word 2
    .word LOWER_C
    .word HIGHER_C
  NOTEs_DUR_DATA_2_c_TWO:
    .word 250
    .word 2
    .word LOWER_E
    .word HIGHER_E
  NOTEs_DUR_DATA_3_c_TWO:
    .word 250
    .word 2
    .word LOWER_G
    .word HIGHER_G

  NOTEs_DUR_DATA_1_h_TWO:
    .word 250
    .word 2
    .word CENTER_C
    .word HIGHER_C
  NOTEs_DUR_DATA_2_h_TWO:
    .word 250
    .word 2
    .word CENTER_E
    .word HIGHER_E
  NOTEs_DUR_DATA_3_h_TWO:
    .word 250
    .word 2
    .word CENTER_G
    .word HIGHER_G
  @ Three notes at a time
  NOTEs_DUR_DATA_1_THREE_1:
    .word 250
    .word 3
    .word LOWER_C
    .word CENTER_C
    .word HIGHER_C
  NOTEs_DUR_DATA_2_THREE_1:
    .word 250
    .word 3
    .word LOWER_E
    .word CENTER_E
    .word HIGHER_E
  NOTEs_DUR_DATA_3_THREE_1:
    .word 250
    .word 3
    .word LOWER_G
    .word CENTER_G
    .word HIGHER_G
  NOTEs_DUR_DATA_1_THREE_2:
      .word 250
      .word 3
      .word LOWER_C
      .word CENTER_C
      .word HIGHER_C
    NOTEs_DUR_DATA_2_THREE:
      .word 250
      .word 3
      .word LOWER_E
      .word CENTER_E
      .word HIGHER_E
    NOTEs_DUR_DATA_3_THREE:
      .word 250
      .word 3
      .word LOWER_G
      .word CENTER_G
      .word HIGHER_G
  NOTEs_DUR_DATA_2_THREE_2:
      .word 250
      .word 3
      .word LOWER_C
      .word CENTER_C
      .word HIGHER_C
  NOTEs_DUR_DATA_3_THREE_2:
    .word 250
    .word 3
    .word LOWER_E
    .word CENTER_E
    .word HIGHER_E


PitchArray_UF_Intro:
  @ This is the array for the song:
  @    Uchiage Firework (UF) 's intro part

  @ Length of the array
  .word 16               

  .word Pitch_UF_G_HASH     @ Pitch 
  .word SEC_QUART_ONE       @ Duration

  .word Pitch_UF_A_HASH    
  .word SEC_QUART_ONE

  .word Pitch_UF_C_HASH    
  .word SEC_QUART_ONE

  .word Pitch_UF_F_HASH    
  .word SEC_QUART_ONE
  
  .word Pitch_UF_G_HASH    
  .word SEC_QUART_ONE
  
  .word Pitch_UF_A_HASH    
  .word SEC_QUART_ONE
  
  .word Pitch_UF_C_HASH    
  .word SEC_QUART_ONE
  
  .word Pitch_UF_F_HASH    
  .word SEC_QUART_ONE
  
  .word Pitch_UF_G_HASH    
  .word SEC_QUART_ONE
  
  .word Pitch_UF_A_HASH    
  .word SEC_QUART_ONE
  
  .word Pitch_UF_C_HASH    
  .word SEC_QUART_ONE
  
  .word Pitch_UF_D_HASH    
  .word SEC_QUART_ONE
  
  .word Pitch_UF_G_HASH    
  .word SEC_QUART_ONE
  
  .word Pitch_UF_A_HASH    
  .word SEC_QUART_ONE
  
  .word Pitch_UF_D_HASH_LOWER    
  .word SEC_QUART_ONE
  
  .word Pitch_UF_F_HASH    
  .word SEC_QUART_ONE

PitchArray_UF_Half: 
  .word 226
  @ This is the array for the song:
  @    Uchiage Firework (UF)

  .ascii "G#blA#bcC#bcF#bl" @ 32
  .ascii "G#blA#bcC#bcF#bl"
  .ascii "G#blA#bcC#bcD#bc"
  .ascii "G#blA#bcD#blF#bl"
  .ascii "G#blA#bcC#bcF#bl"
  .ascii "G#blA#bcC#bcF#bl"
  .ascii "G#blA#bcC#bcD#bc"
  .ascii "G#blA#bcD#blF#bl"

  .ascii "G#bsA#blC#blF#bs" @ 32
  .ascii "G#bsA#blC#blF#bs"
  .ascii "G#bsA#blC#blD#bl"
  .ascii "G#bsA#blD#bsF#bs"
  .ascii "G#bsA#blC#blF#bs" 
  .ascii "G#bsA#blC#blF#bs"
  .ascii "G#bsA#blC#blD#bl"
  .ascii "G#bsA#blD#bsF#bs"

  .ascii "D#dlF#blG#dlE#bl" @ 23
  .ascii "C#blB#blA#blC#bl"
  .ascii "F#dlF#dlF#blE#bl"
  .ascii "D#dlF#dlE#blC#bl"
  .ascii "C#dlC#dlC#dlC#dl"
  .ascii "C#dlA#blC#bl"

  .ascii "D#dlF#blG#dlE#bl" @ 23
  .ascii "C#blB#blA#blC#bl"
  .ascii "F#dlF#dlF#blE#bl"
  .ascii "D#dlF#dlE#blD#bl"
  .ascii "C#blD#blD#dlD#dl"
  .ascii "D#dlD#blE#bl"

  .ascii "F#dlF#blE#blD#bl"@ 27
  .ascii "E#blF#dlF#blE#bl"
  .ascii "D#blE#blF#blE#bl"
  .ascii "C#blD#bl"
  .ascii "C#blF#bsF#bsD#bl"
  .ascii "C#blF#bsG#bsA#bl"
  .ascii "A#dlA#dlA#dlD#bl"
  .ascii "E#bl"

  .ascii "F#dlF#dlE#blD#bl" @ 27
  .ascii "E#blF#dlF#blE#bl"
  .ascii "D#blE#blF#blG#bl"
  .ascii "A#bcB#bc"
  .ascii "B#bcF#blF#blA#bl"
  .ascii "G#blF#blF#dlF#dl"
  .ascii "F#dlF#dlA#bcC#bc"
  .ascii "A#bc"

  .ascii "G#blF#blD#blF#bl" @ 31
  .ascii "G#dlA#bcC#bcA#bc"
  .ascii "G#blF#blD#blF#dl"
  .ascii "F#dlA#bcC#bcA#bc"
  .ascii "G#dlA#bcC#b2C#bc"
  .ascii "D#bcC#bcB#bcA#bc"
  .ascii "~~b~~~b~~~b~A#bc"
  .ascii "C#bcA#bc"

  .ascii "G#blF#blD#blF#bl" @ 31 
  .ascii "G#dlA#bcC#bcA#bc"
  .ascii "G#blF#blD#blF#dl"
  .ascii "F#dlE#bl"
  .ascii "D#dlG#dlE#blD#bl"
  .ascii "E#dlE#blF#bl"


PitchArray_AST:
  @ This is the ascii score for the song:
  @     Astronomia (AST) 
  .word 192
  .ascii "A#bcA#bcA#bcA#bcD_bcD_bcD_bcD_bcC_bcC_bcC_bcC_bcF_bcF_bcF_bcF_bcG_bcG_bcG_bcG_bcG_bcG_bcG_bcG_bcG_bcG_bcG_bcG_bcC_bcA#bcA_bcF_blG_bl~~b~G_blD_bcC_bc~~b~A#bc~~b~A_bc~~b~A_bcA_bcC_bc~~b~A#bcA_bcG_bl~~b~G_blA#bhA_bhA#bhA_bhA#bhG_bl~~b~G_blA#bhA_bhA#bhA_bhA#bhG_bl~~b~G_blD_bcC_bc~~b~A#bc~~b~A_bc~~b~A_bcA_bcC_bc~~b~A#bcA_bcG_bl~~b~G_blA#bhA_bhA#bhA_bhA#bhG_bl~~b~G_blA#bhA_bhA#bhA_bhA#bh"
  .ascii "A#bcA#bcA#bcA#bcD_bcD_bcD_bcD_bcC_bcC_bcC_bcC_bcF_bcF_bcF_bcF_bcG_bcG_bcG_bcG_bcG_bcG_bcG_bcG_bcG_bcG_bcG_bcG_bcC_bcA#bcA_bcF_blG_bl~~b~G_blD_bcC_bc~~b~A#bc~~b~A_bc~~b~A_bcA_bcC_bc~~b~A#bcA_bcG_bl~~b~G_blA#bhA_bhA#bhA_bhA#bhG_bl~~b~G_blA#bhA_bhA#bhA_bhA#bhG_bl~~b~G_blD_bcC_bc~~b~A#bc~~b~A_bc~~b~A_bcA_bcC_bc~~b~A#bcA_bcG_bl~~b~G_blA#bhA_bhA#bhA_bhA#bhG_bl~~b~G_blA#bhA_bhA#bhA_bhA#bh"

  @ .ascii "A#bcA#bcA#bcA#bcD_bcD_bcD_bcD_bcC_bcC_bcC_bcC_bcF_bcF_bcF_bcF_bcG_bcG_bcG_bcG_bcG_bcG_bc"
  @ .ascii "G_bcG_bcC_bcA#bcA_bcF_blG_bl~~b~G_blD_bcC_bc~~b~A#bc~~b~A_bc~~b~A_bcA_bcC_bc~~b~A#bcA_bc"
  @ .ascii "G_bl~~b~G_blA#bhA_bhA#bhA_bhA#bhG_bl~~b~G_blA#bhA_bhA#bhA_bhA#bhG_bl~~b~G_blD_bcC_bc~~b~"
  @ .ascii "A#bc~~b~A_bc~~b~A_bcA_bcC_bc~~b~A#bcA_bcG_blG_blA#bhA_bhA#bhA_bhA#bhG_bl~~b~G_blA#bhA_bh"
  @ .ascii "A#bhA_bhA#bhA#bcA#bcA#bcA#bcD_bcD_bcD_bcD_bcC_bcC_bcC_bcC_bcF_bcF_bcF_bcF_bcG_bcG_bcG_bc"
  @ .ascii "G_bcG_bcG_bcG_bcG_bcC_bcA#bcA_bcF_blG_bl~~b~G_blD_bcC_bc~~b~A#bc~~b~A_bc~~b~A_bcA_bcC_bc"
  @ .ascii "~~b~A#bcA_bcG_bl~~b~G_blA#bhA_bhA#bhA_bhA#bh~~b~G_bl~~b~~~b~G_blA#bhA_bhA#bhA_bhA#bhG_bl"
  @ .ascii "G_blD_bcC_bc~~b~A#bcA_bc~~b~A_bcA_bcC_bc~~b~A#bcA_bcG_bl~~b~G_blA#bhA_bh~~b~A#bhA_bhA#bh"
  @ .ascii "G_bl~~b~G_blA#bhA_bhA#bhA_bhA#bh~~b~~~b~~~b~~~b~"

