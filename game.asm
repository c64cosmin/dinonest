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

screenChars = $0400
colorRam = $d800
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

logicMapAddr = $6000

randomByte      = $D41B
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
incbin "levels.sdd", 1, 2

*=$5000
dinoX             byte 96
dinoXHi           byte 0
dinoY             byte 64
dinoMapAddr       byte 0
dinoState         byte 0
dinoMoveIncrement byte 0
dinoAnim          byte 0
dinoSprite        byte spriteDinoRight
dinoColor         byte 13

qdinoX             byte 112
qdinoXHi           byte 0
qdinoY             byte 64
qdinoMapAddr       byte 0
qdinoState         byte 0
qdinoMoveIncrement byte 0
qdinoAnim          byte 0
qdinoSprite        byte spriteDinoRight
qdinoSpriteColor   byte 10

qqdinoX             byte 128
qqdinoXHi           byte 0
qqdinoY             byte 64
qqdinoMapAddr       byte 0
qqdinoState         byte 0
qqdinoMoveIncrement byte 0
qqdinoAnim          byte 0
qqdinoSprite        byte spriteDinoRight
qqdinoSpriteColor   byte 7

qqqdinoX             byte 144
qqqdinoXHi           byte 0
qqqdinoY             byte 64
qqqdinoMapAddr       byte 0
qqqdinoState         byte 0
qqqdinoMoveIncrement byte 0
qqqdinoAnim          byte 0
qqqdinoSprite        byte spriteDinoRight
qqqdinoSpriteColor   byte 14

*=$1000
init            ldx #$ff
                stx spriteEnable
                ldx #$17
                stx $d011
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

                ;random generator
                LDA #$6F
                LDY #$81
                LDX #$FF
                STA $D413
                STY $D412
                STX $D40E
                STX $D40F
                STX $D414

                lda #0
                sta $06

                ldx #0
                jsr load_map

loop            lda #$fb
raster          cmp $d012
                bne raster      ;wait for raster
                
                inc $d020
                ;logic
                ldx #0          ;joystick 2
                jsr joy_moved   ;load joystate in $02
                ldx #0          ;pointer to player
                ldy #0
                sty $04         ;player draw to sprite 0,1
                jsr dino_update ;dino update

                ;ldx #1
                ;jsr joy_moved

                jsr random_control
                ldx #9
                ldy #2
                sty $04
                jsr dino_update

                jsr random_control
                ldx #18
                ldy #4
                sty $04
                jsr dino_update

                jsr random_control
                ldx #27
                ldy #6
                sty $04
                jsr dino_update

                ;logic
                lda #0
                sta $d020

                ;jsr dbg_map

                jmp loop

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;load map
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;register X to map index

load_map        txa
                cmp #0
                bne load_map_1
                copyBytes $4000, $d800, $03e8   ;map 0
                copyBytes $47d0, $0400, $03e8
                jmp logical_map
load_map_1      cmp #1
                bne load_map_2
                copyBytes $43e8, $d800, $03e8   ;map 1
                copyBytes $4bb8, $0400, $03e8
load_map_2
logical_map     lda #0
                sta $02                 ;i = 0; i < 240
                sta $03                 ;j = 0

                lda #<screenChars
                sta $05
                lda #>screenChars
                sta $06                 ;pointer to screen chars
loop_logic_map  lda #0
                ldx $02
                sta logicMapAddr,X
                ldx #0
                lda ($05,X)
                and #$60                ;solid tile %x11xxxxx
                cmp #$60
                bne skip_set_solid
                lda #1
                ldx $02
                sta logicMapAddr,X

skip_set_solid  lda #2                  ;pointer += 2
                clc
                adc $05
                sta $05
                lda #0
                adc $06
                sta $06                 ;increment with carry pointer $05,$06

                inc $03                 ;j+=2
                inc $03
                lda $03
                cmp #40
                bne skip_j40            ;if j==40; pointer+=40
                lda #40
                clc
                adc $05
                sta $05
                lda #0
                adc $06
                sta $06
                lda #0
                sta $03                 ;j=0
skip_j40
                inc $02                 ;i++
                lda $02
                cmp #240
                bne loop_logic_map      ;reached end of logical map i < 240
                rts
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;debug map
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

dbg_map         lda #0
                sta $02                 ;i = 0; i < 240
                sta $03                 ;j = 0

                lda #<screenChars
                sta $05
                lda #>screenChars
                sta $06                 ;pointer to screen chars

                lda #<colorRam
                sta $fb
                lda #>colorRam
                sta $fc                 ;pointer to screen chars
                                
loop_dbg_map    ldx $02
                lda logicMapAddr,X
                ldx #0
                sta ($fb,X)
                lda #1
                sta ($05,X)
                
                lda #2                  ;pointer += 2
                clc
                adc $05
                sta $05
                lda #0
                adc $06
                sta $06                 ;increment with carry pointer $05,$06
                lda #2
                clc
                adc $fb
                sta $fb
                lda #0
                adc $fc
                sta $fc                 ;increment with carry pointer $05,$06

                inc $03                 ;j+=2
                inc $03
                lda $03
                cmp #40
                bne skip_dbg_j40        ;if j==40; pointer+=40
                lda #40
                clc
                adc $05
                sta $05
                lda #0
                adc $06
                sta $06
                lda #40
                clc
                adc $fb
                sta $fb
                lda #0
                adc $fc
                sta $fc
                lda #0
                sta $03                 ;j=0
skip_dbg_j40
                inc $02                 ;i++
                lda $02
                cmp #240
                bne loop_dbg_map        ;reached end of logical map i < 240
                rts

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;dino instance update
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;register X to pointer
;;$04 is sprite ID
;;$02 controls movement of dino

dino_update     lda dinoMoveIncrement,X ;check if dino is not moving
                cmp #0
                bne dino_move           ;if dino is moving then move
                lda $02                 ;else check control
                and #$f                 ;for movement
                cmp #0                  ;is dino moved
                beq dino_draw           ;if there is no control skip
                                        ;else look for collision

                lda dinoState,X         ;load state
                and #$f0                ;drop movement
                ora $02                 ;add control
                sta dinoState,X         ;store state

                jsr dino_addr

                ldy $03
                lda logicMapAddr,Y      ;load map property
                cmp #0                  ;is tile free?
                bne dino_draw           ;if not cannot move

                lda #dinoMoveSpeed      ;else start animation
                sta dinoMoveIncrement,X
                ldy $03                 ;load front position
                lda #1
                sta logicMapAddr,Y      ;mark place as occupied

dino_move       jsr dino_mv_rtn

dino_move_dec   dec dinoMoveIncrement,X
                lda dinoMoveIncrement,X
                cmp #0
                bne dino_draw
                                        ;clean up positions on map
                lda #0
                ldy dinoMapAddr,X
                sta logicMapAddr,Y      ;clean current position

dino_draw       ldy $04
                lda dinoAnim,X          ;animate walk
                lsr A                   ; divide by 2
                and #$7
                clc
                adc dinoSprite,X
                sta sprite0P,Y
                clc
                adc #$10
                sta sprite1P,Y

                lda #0          ;black outline
                sta sprite0C,Y
                lda dinoColor,X
                sta sprite1C,Y  ;color outline

                tya
                asl A
                tay             ;multiply Y register with 2
                lda dinoY,X
                clc
                adc #$35        ; offsetY
                sta sprite0Y,Y
                sta sprite1Y,Y

                lda dinoX,X
                sta $03
                lda dinoXHi,X
                sta $04

                lda #$14        ; offsetX
                clc
                adc $03
                sta $03
                lda #0
                adc $04
                sta $04
                lda $03
                sta sprite0X,Y
                sta sprite1X,Y
                                ;high part of X position

                lda $04
                asl $04
                ora $04
                sta $04         ;double the bits in hi part
                lda #3
                sta $06         ;mask
                sty $05
                lsr $05         ;each dino has two sprites
                lsr $05         ;divide back Yreg with 2
                lda $05         ;sprite Xhi
                cmp #0
                beq dino_skip_xhi
dino_xhi        asl $04
                asl $04
                asl $06
                asl $06
                dec $05
                lda $05
                cmp #0
                bne dino_xhi
dino_skip_xhi   lda $06         ;mask
                eor #$ff        ;invert
                sta $06
                lda $d010
                and $06         ;remove bit
                sta $d010
                lda $04
                ora $d010       ;set bit
                sta $d010

                rts             ;return

dino_addr       lda dinoY,X             ;adr = ypos
                and #$f0
                lsr A
                lsr A                   ;divide by 4 (xpos/16 * 4)
                sta dinoMapAddr,X
                clc
                adc dinoMapAddr,X
                adc dinoMapAddr,X
                adc dinoMapAddr,X
                adc dinoMapAddr,X
                sta dinoMapAddr,X       ;adr = ypos*4*5 == (y*20)

                lda dinoX,X             ;xpos
                lsr A
                lsr A
                lsr A
                lsr A                   ;divide by 16
                clc
                adc dinoMapAddr,X
                sta dinoMapAddr,X
                lda dinoXHi,X
                cmp #0
                beq dino_addr_nohi
                lda #$10                ;0x100 shifted by 4 to right = 0x10
                clc
                adc dinoMapAddr,X
                sta dinoMapAddr,X
dino_addr_nohi  lda dinoMapAddr,X       ;adr = xpos + ypos*20
                sta $03                 ;also hold this for frontAddr

                lda dinoState,X
                and #$0f
dino_f_up       cmp #directionUp
                bne dino_f_dw
                lda $03
                sec
                sbc #20                 ;map width = 20
                sta $03
dino_f_dw       cmp #directionDown
                bne dino_f_lf
                lda $03
                clc
                adc #20                 ;map width = 20
                sta $03
dino_f_lf       cmp #directionLeft
                bne dino_f_rg
                dec $03
dino_f_rg       cmp #directionRight
                bne dino_f_end
                inc $03
dino_f_end      rts


dino_mv_rtn     inc dinoAnim,X
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
                lda dinoX,X
                sec
                sbc #1
                sta dinoX,X
                lda dinoXHi,X
                sbc #0
                sta dinoXHi,X
                lda #spriteDinoLeft
                sta dinoSprite,X
                jmp dino_move_skip
dino_move_rg    cmp #directionRight
                bne dino_move_skip
                lda #1
                clc
                adc dinoX,X
                sta dinoX,X
                lda #0
                adc dinoXHi,X
                sta dinoXHi,X
                lda #spriteDinoRight
                sta dinoSprite,X

dino_move_skip  rts
                                        ;end compute front position

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;random control routine
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;will return random direction control to $02

random_control  lda #1
                sta $02
                lda randomByte
                and #3
                cmp #0
                beq skip_random
shift_random    asl $02
                tax
                dex
                txa
                cmp #0
                bne shift_random
skip_random     rts

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
