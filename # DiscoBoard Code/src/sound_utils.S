.syntax unified

@ ======================= INTERFACE ======================

@ Frequencies 
.global BOARD_FREQUENCY         @ 80 MHZ / 4MHZ (Assingment/Lab)
.global HEADPHONE_FREQUENCY     @ 48 KHZ 

@ Amplitude Peak and Trough  
.global AMP_TOP                 @ 0x00007fff
.global AMP_BOT                 @ 0xffff8000

@ function play_xx_for will id as delay 
.global IDLE                    @ 0xffffffff

@ Duration in milli seconds
.global SEC_QUART_HALF          @  125 ms
.global SEC_QUART_ONE           @  250 ms
.global SEC_QUART_TWO           @  500 ms
.global SEC_QUART_THREE         @  750 ms
.global SEC_QUART_FOUR          @ 1000 ms
.global SEC_ONE_THIRD           @  333 ms
.global SEC_TWO_THIRD           @  667 ms


@ Pitch for song: Smoke On The Water (SOTW)
.global Pitch_SOTW_D            @ 293.66 HZ (29366 HZ/100)
.global Pitch_SOTW_F            @ 349.23 HZ
.global Pitch_SOTW_G            @ 392    HZ
.global Pitch_SOTW_G_Special    @ 415.30 HZ

@ Pitch for song: Smoke On The Water (SOTW)
.global Pitch_ATD_A            @ 110    HZ (29366 HZ/100)
.global Pitch_ATD_B            @ 123.47 HZ (29366 HZ/100)
.global Pitch_ATD_C            @ 130.81 HZ
.global Pitch_ATD_D            @ 146.83 HZ
.global Pitch_ATD_E            @ 164.81 HZ
.global Pitch_ATD_F_Special    @ 185    HZ
.global Pitch_ATD_G            @ 98     HZ

@ .global ADSR_C
@ .global ADSR_C      

@ Pitch for the song Uchiage Firework 
.global Pitch_UF_A_HASH        @ 466.16 HZ
.global Pitch_UF_C_HASH        @ 554.37 HZ
.global Pitch_UF_D_HASH        @ 622.25 HZ
.global Pitch_UF_F_HASH        @ 369.99 HZ
.global Pitch_UF_G_HASH        @ 415.30 HZ
.global Pitch_UF_D_HASH_LOWER  @ 311.12 HZ

@ Pitch for other demo
.global LOWER_C
.global LOWER_E
.global LOWER_G
.global CENTER_C
.global CENTER_E
.global CENTER_G
.global HIGHER_C
.global HIGHER_E
.global HIGHER_G

.global Pitch_ATD_A_H
.global Pitch_ATD_B_H
.global Pitch_ATD_C_H
.global Pitch_ATD_D_H
.global Pitch_ATD_E_H
.global Pitch_ATD_F_Special_H
.global Pitch_ATD_G_H

@ ==================== IMPLEMENTATION ======================
@ Implementations
.set BOARD_FREQUENCY,       0x007a1200 
.set HEADPHONE_FREQUENCY,   0x0000bb80 
.set AMP_TOP,               0x00007fff 
.set AMP_BOT,               0xffff8000 

.set IDLE,                  0xffffffff

@ a = SEC_QUART_HALF,  =1/8 second = 125  milli-second
@ b = SEC_QUART_ONE,   =1/4 second = 250  milli-second
@ c = SEC_ONE_THIRD,   =1/3 second = 333  milli-second
@ d = SEC_QUART_TWO,   =1/2 second = 500  milli-second
@ e = SEC_TWO_THIRD,   =2/3 second = 667  milli-second 
@ f = SEC_QUART_THREE, =3/4 second = 750  milli-second
@ g = SEC_QUART_FOUR,  =1/1 second = 1000 milli-second

.set SEC_ONE_THIRD,         0x0000014d
.set SEC_TWO_THIRD,         0x0000029b      
.set SEC_QUART_HALF,        0x0000007d
.set SEC_QUART_ONE,         0x000000fa
.set SEC_QUART_TWO,         0x000001f4
.set SEC_QUART_THREE,       0x000002ee
.set SEC_QUART_FOUR,        0x000003e8

.set Pitch_SOTW_D,          0x000072b6
.set Pitch_SOTW_F,          0x0000886b
.set Pitch_SOTW_G,          0x00009920
.set Pitch_SOTW_G_Special,  0x0000a23a

.set Pitch_ATD_A,           0x00002af8 @ 110    HZ (29366 HZ/100)
.set Pitch_ATD_B,           0x0000303b @ 123.47 HZ
.set Pitch_ATD_C,           0x00003319 @ 130.81 HZ
.set Pitch_ATD_D,           0x0000395b @ 146.83 HZ
.set Pitch_ATD_E,           0x00004061 @ 164.81 HZ
.set Pitch_ATD_F_Special,   0x00004844 @ 185    HZ
.set Pitch_ATD_G,           0x00002648 @ 98     HZ

.set Pitch_ATD_A_H,           22000
.set Pitch_ATD_B_H,           24694
.set Pitch_ATD_C_H,           26162
.set Pitch_ATD_D_H,           29366
.set Pitch_ATD_E_H,           32962
.set Pitch_ATD_F_Special_H,   36999
.set Pitch_ATD_G_H,           19599

.set Pitch_UF_A_HASH,       0x0000b618 @ 466.16 HZ   
.set Pitch_UF_C_HASH,       0x0000d88d @ 554.37 HZ
.set Pitch_UF_D_HASH,       0x0000f311 @ 622.25 HZ
.set Pitch_UF_D_HASH_LOWER, 0x00007988 @ 311.12 HZ
.set Pitch_UF_F_HASH,       0x00009087 @ 369.99 HZ
.set Pitch_UF_G_HASH,       0x0000a23a @ 415.30 HZ

.set LOWER_C, 13081
.set LOWER_E, 16481
.set LOWER_G, 19599
.set CENTER_C, 26162
.set CENTER_E, 32962
.set CENTER_G, 39199
.set HIGHER_C, 52325
.set HIGHER_E, 65925
.set HIGHER_G, 78399

