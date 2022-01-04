; 10 SYS (4096):REM @c64cosmin 2022

*=$0801

        BYTE    $20, $08, $0A, $00, $9E, $20, $28,  $34, $30, $39, $36, $29, $3a, $8f, $20, $40, $43, $36, $34, $43, $4F, $53, $4D, $49, $4E, $20, $32, $30, $32, $32, $00, $00, $00

*=$2000
incbin  "dino.spt", 1, 1

joystick2 = $dc00
spriteEnable = $d015
sprite0P = $07f8
sprite0X = $d000
sprite0Y = $d001
sprite0C = $d027

*=$1000
init    ldx #$ff
        stx spriteEnable
        ldx #$80
        stx sprite0P
        ldx #1
        stx sprite0C
        ldx #128
        stx sprite0X
loop    ldx #0
raster  cmp $d012
        bne raster
        
        inc $d020
        ;logic
joyu_up lda joystick2
        and #$1
        cmp #$0
        bne joy_dw
        dec sprite0Y
joy_dw  lda joystick2
        and #$2
        cmp #$0
        bne joy_lf
        inc sprite0Y
joy_lf  lda joystick2
        and #$4
        cmp #$0
        bne joy_rg
        dec sprite0X
joy_rg  lda joystick2
        and #$8
        cmp #$0
        bne joy_x
        inc sprite0X 
joy_x   
        ;logic
        dec $d020

        jmp loop