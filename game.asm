
joystick2 = $dc00
spriteEnable = $d015
sprite0P = $07f8
sprite0X = $d000
sprite0Y = $d001
sprite0C = $d027

playerMoveSpeed = 16

; 10 SYS (4096):REM @c64cosmin 2022

*=$0801

        BYTE    $20, $08, $0A, $00, $9E, $20, $28,  $34, $30, $39, $36, $29, $3a, $8f, $20, $40, $43, $36, $34, $43, $4F, $53, $4D, $49, $4E, $20, $32, $30, $32, $32, $00, $00, $00

*=$2000
incbin "sprites.spt", 1, 1
*=$2800
incbin "tiles.cst", 0, 64
*=$3000
incbin "levels.sdd", 1, 1
*=$4000
playerX             byte 0
playerY             byte 0
playerState         byte 0
playerMoveIncrement byte 0

*=$1000
init            ldx #$1
                stx spriteEnable
                ldx #$80
                stx sprite0P
                ldx #1
                stx sprite0C
                ldx #26
                stx $d018
                ldx #0
load            lda $33e8,X
                sta $0400,X
                inx 
                txa
                cmp #0
                bne load
loop            lda #0
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
player_move_up  cmp #$1
                bne player_move_dw
                dec playerY
player_move_dw  cmp #$2
                bne player_move_lf
                inc playerY
player_move_lf  cmp #$4
                bne player_move_rg
                dec playerX
player_move_rg  cmp #$8
                bne player_move_dec
                inc playerX
player_move_dec dec playerMoveIncrement
                lda playerMoveIncrement
                cmp #0
                bne player_draw
                lda playerState
                and #$f0        ;clear player direction state
                sta playerState
player_draw     lda playerX     ; player draw to sprite
                adc #$17        ; offsetX
                sta sprite0X
                lda playerY
                adc #$32        ; offsetY
                sta sprite0Y
                ;logic
                dec $d020

                jmp loop