; Changes directory of non disk drive device
; Requires:
;  * Str_FileName filled
ChangeDir       jsr FakeTaskbar
                lda #"C"
                sta FREEMEM
                lda #"D"
                sta FREEMEM+1
                lda #":"
                sta FREEMEM+2
                lda ControlHilIndex
                bne +
                lda #95; Left arrow
                sta FREEMEM+3
                jsr UninstallIRQ
                jsr Pause
                lda #4
                jmp DiskSendCommand
                ;
+               ldx #$ff
-               inx
                lda Str_FileName,x
                sta FREEMEM+3,x
                bne -
                lda #0
                sta error_code
                jsr UninstallIRQ
                txa
                clc
                adc #3
                jmp DiskSendCommand


; Creates a subdirectory in the current directory
; Requires Str_ImageEdit filled
CreateDirectory jsr FakeTaskbar
                lda #"M"
                sta FREEMEM
                lda #"D"
                sta FREEMEM+1
                lda #":"
                sta FREEMEM+2
                ;
                lda #<Str_ImageEdit
                sta $fd
                lda #>Str_ImageEdit
                sta $fe
                ldy #15
                jsr KillSpaces
                ;
                ldx #$ff
-               inx
                lda Str_ImageEdit,x
                sta FREEMEM+3,x
                bne -
                ;
                lda #0
                sta error_code
                jsr UninstallIRQ
                inx
                inx
                inx
                txa
                jmp DiskSendCommand
                rts

; Sizes of disk images (* indicates disks with error information)
; d64 : 174848 (minus one: 174847 = $02 AA FF -> FF AA 02)
; d64*: 175531 (minus one: 175530 = $02 AD AA -> AA AD 02)
; d71 : 349696 (minus one: 349695 = $05 55 FF -> FF 55 05)
; d71*: 351062 (minus one: 351061 = $05 5B 55 -> 55 5B 05)
; d81 : 819200 (minus one: 819199 = $0C 7F FF -> FF 7F 0C)
; dnp : multiple of 65536 (minus one: ?????? = $?? ?? ??)

ImageNameSuffix !pet ".xxx,p,w"
ImageName       !pet "0123456789ab.xxx,p,w"
Channel2Str     !pet "p",3,255,170,2
drive_data      !byte $ff, $aa, $02 ; d64
                !byte $ff, $55, $05 ; d71
                !byte $ff, $7f, $0c ; d81
                !byte $ff, $ff, $0f ; dnp: fixed size 1 00 00
createFile_cmd  !pet "x",0

; Creates an image file in the current directory
; Requires Str_ImageEdit and Ctrl_NF_ImgType filled
CreateImageFile lda #0
                sta error_code
                jsr FakeTaskbar
                jsr UninstallIRQ
                ; Prepare edit string
                lda #<Str_ImageEdit
                sta $fd
                lda #>Str_ImageEdit
                sta $fe
                ldy #11
                jsr KillSpaces
                ldx #3
-               lda Ctrl_NF_ImgType,x
                sta ImageNameSuffix,x
                dex
                bpl -
                ; Prepare ImageName
                ldx #$ff
-               inx
                lda Str_ImageEdit,x
                sta ImageName,x
                bne -
                ldy #0
-               lda ImageNameSuffix,y
                sta ImageName,x
                inx
                iny
                cpy #8
                bcc -
                lda #0
                sta ImageName,x
                ; open
                txa ; string length
                ldx #<ImageName
                ldy #>ImageName
                jsr SETNAM    ; call SETNAM
                lda #1   ; file number
                ldx CurDeviceNo
                ldy #3   ; secondary address
                jsr SETLFS
                jsr OPEN
                bcc +
                sta error_code
                jmp closem
                ; open2,8,15,"p"+chr$(3)+chr$(255)+chr$(170)+chr$(2) (for d64)
                ;
                ; Prepare Channel2Str
+               lda #<drive_data
                sta $fd
                lda #>drive_data
                sta $fe
                lda #3
                jsr SelectControl
                lda ControlHilIndex
                asl
                clc
                adc ControlHilIndex
                sec
                sbc #3
                jsr AddToFD
                ldy #2
-               lda ($fd),y
                sta Channel2Str+2,y
                dey
                bpl -
                ; open
                lda #5
                ldx #<Channel2Str
                ldy #>Channel2Str
                jsr SETNAM    ; call SETNAM
                lda #2   ; file number
                ldx CurDeviceNo
                ldy #15   ; secondary address
                jsr SETLFS
                jsr OPEN
                bcc +
                sta error_code
                jmp closem
+               ; Map BASIC in for STROUT
                lda #55
                sta $01
                ; print#1,"x"
                ldx #1
                jsr CHKOUT
                lda #<createFile_cmd
                ldy #>createFile_cmd
                jsr STROUT
                jsr CLRCHN
closem          ; close1
                lda #1
                jsr CLOSE
                lda #2
                jsr CLOSE
                ; Map BASIC out
                lda #53
                sta $01
                rts