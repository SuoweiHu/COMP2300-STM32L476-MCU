.syntax unified

@ ======================= INTERFACE ======================
.global G_SCORE_CENTER_A       @ Center C for G-Score 


@ ==================== IMPLEMENTATION ======================
.macro frequency frequency_with_2dec x
    .word \frequency_with_2dec
.endm 

@ pitch table 
G_SCORE_PITCH_TABLE:
    frequency 6540 @ 36 C. 
    frequency 6929 @ 37 C#
    frequency 7341 @ 38 D.
    frequency 7778 @ 39 D#
    frequency 8240 @ 40 E.
    frequency 0     
    frequency 8730 @ 41 F.
    frequency 9249 @ 42 F#`
    frequency 9799 @ 43 G.
    frequency 10382 @ 44 G#
    G_SCORE_LOWER_LOWER_A:  frequency 11000 @ 45 A.
    frequency 11654 @ 46 A#
    frequency 12347 @ 47 B.
    frequency 0
    frequency 13081 @ 48 C. (lower c)
    frequency 13859 @ 49 C#
    frequency 14683 @ 50 D.
    frequency 15556 @ 51 D#
    frequency 16481 @ 52 E.
    frequency 0     @ Placeholder
    frequency 17461 @ 53 F.
    frequency 18499 @ 54 F#
    frequency 19599 @ 55 G.
    frequency 20765 @ 56 G#
    G_SCORE_LOWER_A:  frequency 22000 @ 57 A.
    frequency 23308 @ 58 A#
    frequency 24694 @ 59 B.
    frequency 0
    frequency 26162 @ 60 C. (center c)
    frequency 27718 @ 61 C#
    frequency 29366 @ 62 D.
    frequency 31112 @ 63 D#
    frequency 32962 @ 64 E.
    frequency 0   
    frequency 34922 @ 65 F.
    frequency 36999 @ 66 F#
    frequency 39199 @ 67 G.
    frequency 41530 @ 68 G#
    G_SCORE_CENTER_A: frequency 44000 @ 69 A.
    frequency 46616 @ 70 A#
    frequency 49388 @ 71 B.
    frequency 0
    frequency 52325 @ 72 C.
    frequency 55436 @ 73 C#
    frequency 58732 @ 74 D.
    frequency 62225 @ 75 D#
    frequency 65925 @ 76 E.
    frequency 0
    frequency 69845 @ 77 F.
    frequency 73998 @ 78 F#
    frequency 78399 @ 79 G.
    frequency 83060 @ 80 G#
    G_SCORE_HIGHER_A: frequency 88000 @ 81 A.
    frequency 93232 @ 82 A#
    frequency 98776 @ 83 B.
    frequency 0
    frequency 104650 @ 84 C.
    frequency 100873 @ 85 C# 
    frequency 117465 @ 86 D.
    frequency 124450 @ 87 D#
    frequency 0
    frequency 131851 @ 88 E.
    frequency 139691 @ 89 F.
    frequency 147997 @ 90 F#
    frequency 156798 @ 91 G.
    frequency 166121 @ 92 G#


