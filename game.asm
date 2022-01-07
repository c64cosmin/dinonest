defm copyBytes
                lda #</1
                sta $fb
                lda #>/1
                sta $fc
                lda #</2
                sta $fd
                lda #>/2
                sta $fe
                lda #</3
                sta $03
                lda #>/3
                sta $04
                ldx #0
                ldy #0
                jsr copy
endm
defm debug
                ldx /1
                txa
                sta $02
                lda #$80
                and $02
                lsr
                lsr
                lsr
                lsr
                lsr
                lsr
                lsr
                sta 1024
                txa
                sta $02
                lda #$40
                and $02
                lsr
                lsr
                lsr
                lsr
                lsr
                lsr
                sta 1025
                txa
                sta $02
                lda #$20
                and $02
                lsr
                lsr
                lsr
                lsr
                lsr
                sta 1026
                txa
                sta $02
                lda #$10
                and $02
                lsr
                lsr
                lsr
                lsr
                sta 1027
                txa
                sta $02
                lda #$08
                and $02
                lsr
                lsr
                lsr
                sta 1028
                txa
                sta $02
                lda #$04
                and $02
                lsr
                lsr
                sta 1029
                txa
                sta $02
                lda #$02
                and $02
                lsr
                sta 1030
                txa
                sta $02
                lda #$01
                and $02
                sta 1031
endm
;setsprite nr,x,y,c,spr
defm setsprite
                ldx #/1
                lda #/4
                sta $d027,X
                lda #/5
                sta $07f8,X
                txa
                rol A
                tax
                lda #/2
                sta $d000,X
                lda #/3
                sta $d001,X
endm

joystick = $dc00
spriteEnable = $d015
sprite0P = $07f8
sprite0X = $d000
sprite0Y = $d001
sprite0C = $d027
sprite1P = $07f9
sprite1X = $d002
sprite1Y = $d003
sprite1C = $d028

directionUp     = 1
directionDown   = 2
directionLeft   = 4
directionRight  = 8
dinoMoveSpeed = 16
spriteDinoRight = $80
spriteDinoLeft = $88
fruitBerry = $A0

; 10 SYS (4096):REM @c64cosmin 2022

*=$0801

        BYTE    $20, $08, $0A, $00, $9E, $20, $28,  $34, $30, $39, $36, $29, $3a, $8f, $20, $40, $43, $36, $34, $43, $4F, $53, $4D, $49, $4E, $20, $32, $30, $32, $32, $00, $00, $00

*=$2000
incbin "sprite.spt"     , 1, 40, true
*=$3000
incbin "tiles.cst", 0, 255
*=$4000
incbin "levels.sdd", 1, 1
*=$5000
dinoX             byte 0
dinoY             byte 0
dinoState         byte 0
dinoMoveIncrement byte 0
dinoAnim          byte 0
dinoSprite        byte spriteDinoRight
dummy0            byte 0
dummy1            byte 0

*=$6000
instancePointer     byte 0

*=$1000
init            ldx #$ff
                stx spriteEnable
                lda #0
                sta sprite0C
                lda #13
                sta sprite1C
                setsprite 2, $b8, $82, 0, $A0
                setsprite 3, $b8, $82, 3, $A4
                setsprite 4, $78, $82, 0, $A1
                setsprite 5, $78, $82, 10, $A5
                ;setsprite 6, $38, $A2, 0, $A3
                ;setsprite 7, $38, $A2, 9, $A7
                ;setsprite 3, $d8, $a2, 0, $A2
                ;setsprite 4, $d8, $a2, 10, $A6
                ldx #24
                stx $d016
                ldx #$1c
                stx $d018
                ldx #0
                stx $d020
                ldx #5
                stx $d021
                ldx #0
                stx $d022
                ldx #9
                stx $d023

                copyBytes $4000, $d800, $03e8
                copyBytes $43e8, $0400, $03e8
                copyBytes $5000, $5008, $0008

loop            lda #$fb
raster          cmp $d012
                bne raster      ;wait for raster
                
                inc $d020
                ;logic
                ldx #0          ;joystick 2
                jsr joy_moved   ;load joystate in $02
                ldx #0          ;pointer to player
                jsr dino_update ;dino update

                ldx #1
                jsr joy_moved
                ldx #8
                jsr dino_update

                ;logic
                lda #0
                sta $d020
                jmp loop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;dino instance update
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;set register X to pointer
;;$02 controls movement of dino

dino_update     lda dinoMoveIncrement,X ;check if dino is not moving
                cmp #0
                bne dino_move           ;if dino is moving then move
                lda $02                 ;else check control
                and #$f                 ;for movement
                cmp #0                  ;is dino moved
                beq dino_draw           ;if there is no control skip
                lda #dinoMoveSpeed      ;else start animation
                sta dinoMoveIncrement,X
                lda dinoState,X         ;load state
                and #$f0                ;drop movement
                ora $02                 ;add control
                sta dinoState,X         ;store state
dino_move       inc dinoAnim,X
                lda dinoState,X
                and #$f
dino_move_up    cmp #directionUp
                bne dino_move_dw
                dec dinoY,X
dino_move_dw    cmp #directionDown
                bne dino_move_lf
                inc dinoY,X
dino_move_lf    cmp #directionLeft
                bne dino_move_rg
                dec dinoX,X
                lda #spriteDinoLeft
                sta dinoSprite,X
dino_move_rg    cmp #directionRight
                bne dino_move_dec
                inc dinoX,X
                lda #spriteDinoRight
                sta dinoSprite,X
dino_move_dec   dec dinoMoveIncrement,X
                lda dinoMoveIncrement,X
                cmp #0
                bne dino_draw
                lda dinoState,X
                and #$f0        ;clear dino direction state
                sta dinoState,X
dino_draw       lda dinoAnim,X  ;animate walk 
                lsr A           ; divide by 2
                and #$7
                clc
                adc dinoSprite,X
                sta sprite0P
                clc
                adc #$10
                sta sprite1P
                lda dinoX,X     ; player draw to sprite
                clc
                adc #$14        ; offsetX
                sta sprite0X
                sta sprite1X
                lda dinoY,X
                clc
                adc #$31        ; offsetY
                sta sprite0Y
                sta sprite1Y
                rts             ;return
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;joystick routine
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;copies only one direction from the joystick to $02
;;this can be used as direction control for one dino

                ;logic for joystick control
joy_moved       lda #0
                sta $02         ;reset state
                lda joystick,X
                eor #$f         ;xor joy state
                and #$f
                cmp #0
                bne joy_was_moved ;joy is moved
                rts               ;else return
joy_was_moved   lda joystick,X
                and #directionUp
                cmp #$0
                bne joy_dw
                lda #directionUp
                ora $02
                sta $02
                rts
joy_dw          lda joystick,X
                and #directionDown
                cmp #$0
                bne joy_lf
                lda #directionDown
                ora $02
                sta $02
                rts
joy_lf          lda joystick,X
                and #directionLeft
                cmp #$0
                bne joy_rg
                lda #directionLeft
                ora $02
                sta $02
                rts
joy_rg          lda joystick,X
                and #directionRight
                cmp #$0
                bne joy_return
                lda #directionRight
                ora $02
                sta $02
joy_return      rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;copy routine
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;copies bytes from $fb$fc to $fd$fe
;;number of bytes stored in $02$03

copy            lda ($fb),Y
                sta ($fd),Y
                lda $03         ;is low counter 0?
                cmp #0
                bne copy_dec_ctr
                lda $04         ;is high counter 0?
                cmp #0
                beq copy_end
                dec $04
copy_dec_ctr    dec $03         ;decrease counter
                iny             ;increase pointer
                tya
                cmp #0
                bne copy
                inc $fc
                inc $fe
                dex
                txa
                cmp #0
                bne copy
copy_end        rts
