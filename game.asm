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

joystick2 = $dc00
spriteEnable = $d015
sprite0P = $07f8
sprite0X = $d000
sprite0Y = $d001
sprite0C = $d027
sprite1P = $07f9
sprite1X = $d002
sprite1Y = $d003
sprite1C = $d028

playerMoveSpeed = 16
spriteDinoRight = $80
spriteDinoLeft = $88

; 10 SYS (4096):REM @c64cosmin 2022

*=$0801

        BYTE    $20, $08, $0A, $00, $9E, $20, $28,  $34, $30, $39, $36, $29, $3a, $8f, $20, $40, $43, $36, $34, $43, $4F, $53, $4D, $49, $4E, $20, $32, $30, $32, $32, $00, $00, $00

*=$2000
incbin "dino.spt"     , 1, 16, true
*=$2400
incbin "dinocolor.spt", 1, 16, true
*=$3000
incbin "tiles.cst", 0, 255
*=$4000
incbin "levels.sdd", 1, 1
*=$5000
playerX             byte 0
playerY             byte 0
playerState         byte 0
playerMoveIncrement byte 0
playerAnim          byte 0
playerSprite        byte spriteDinoRight

*=$1000
init            ldx #$3
                stx spriteEnable
                ldx #0
                stx sprite0C
                ldx #13
                stx sprite1C
                ldx #5
                stx $d021
                ldx #0
                stx $d020
                ldx #$1c
                stx $d018

                copyBytes $4000, $d800, $03e8
                copyBytes $43e8, $0400, $03e8

loop            lda #$fb
raster          cmp $d012
                bne raster
                
                inc $d020
                ;logic
joy_moved       lda joystick2
                eor #$f         ;xor joy state
                and #$f
                cmp #0
                beq player_update ;joy is not moved
                lda playerState ;check if player is not moving
                and #$f         ;if player not moving
                cmp #$0
                bne player_update ;if player not moving then slide
player_slide_up lda joystick2
                and #$1
                cmp #$0
                bne player_slide_dw
                lda #$1
                ora playerState
                sta playerState
                lda #playerMoveSpeed
                sta playerMoveIncrement
                jmp player_update
player_slide_dw lda joystick2
                and #$2
                cmp #$0
                bne player_slide_lf
                lda #$2
                ora playerState
                sta playerState
                lda #playerMoveSpeed
                sta playerMoveIncrement
                jmp player_update
player_slide_lf lda joystick2
                and #$4
                cmp #$0
                bne player_slide_rg
                lda #$4
                ora playerState
                sta playerState
                lda #playerMoveSpeed
                sta playerMoveIncrement
                jmp player_update
player_slide_rg lda joystick2
                and #$8
                cmp #$0
                bne player_update
                lda #$8
                ora playerState
                sta playerState
                lda #playerMoveSpeed
                sta playerMoveIncrement
player_update
                lda playerMoveIncrement
                cmp #0
                bne player_move
                jmp player_draw
player_move     lda playerState
                and #$f
                inc playerAnim
player_move_up  cmp #$1
                bne player_move_dw
                dec playerY
player_move_dw  cmp #$2
                bne player_move_lf
                inc playerY
player_move_lf  cmp #$4
                bne player_move_rg
                dec playerX
                ldx #spriteDinoLeft
                stx playerSprite
player_move_rg  cmp #$8
                bne player_move_dec
                inc playerX
                ldx #spriteDinoRight
                stx playerSprite
player_move_dec dec playerMoveIncrement
                lda playerMoveIncrement
                cmp #0
                bne player_draw
                lda playerState
                and #$f0        ;clear player direction state
                sta playerState
player_draw     lda playerAnim  ;animate walk 
                lsr A           ; divide by 2
                and #$7
                clc
                adc playerSprite
                sta sprite0P
                clc
                adc #$10
                sta sprite1P
                lda playerX     ; player draw to sprite
                clc
                adc #$18        ; offsetX
                sta sprite0X
                sta sprite1X
                lda playerY
                clc
                adc #$31        ; offsetY
                sta sprite0Y
                sta sprite1Y
                ;logic
                lda #0
                sta $d020
                jmp loop

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