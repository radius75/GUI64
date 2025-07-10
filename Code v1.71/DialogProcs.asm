;-------------------------------------------------
; Dialog procs
;
NewFileDlgProc  jsr StdWndProc
                lda wndParam
                cmp #EC_LBTNRELEASE
                bne ++
                ; Button released
                jsr IsInCurControl
                bne +
                rts
+               lda ControlID
                pha
                +SelectControl 3
                pla
                cmp #ID_BTN_OK
                bne check_cancel
                ; Pressed "OK" in New File dialog
                lda ControlHilIndex
                bne +
                ; It's a directory
                jsr CreateDirectory
                lda error_code
                beq kill
                jmp ShowDiskError
+               ; It's an image
                jsr CreateImageFile
                ;lda error_code
                ;beq kill
                ;jmp ShowDiskError
kill            jsr KillDialog
                jmp ShowDirectory
check_cancel    cmp #ID_BTN_CANCEL
                bne +++
                ; Pressed "Cancel" in New File dialog
                jmp CloseDlg
                ;
++              cmp #EC_LBTNPRESS
                bne +++
                ; Button pressed (only process ListBox)
                jsr IsInCurControl
                beq +++
                lda ControlIndex
                cmp #3
                bne +++
                ; Pressed in Images ListBox
                ; Adjust size of edit box
                jsr ClearImageStr
                lda ControlHilIndex
                sta dummy
                +SelectControl 1
                ldx dummy
                bmi +++
                bne +
                lda #21
                sta ControlWidth
                lda #0
                ldx #16
                jsr SetCarretInfo
                jmp ++
+               lda #15
                sta ControlWidth
                lda #0
                ldx #12
                jsr SetCarretInfo
++              jsr UpdateControl
                ; Place file extension string
                ldx dummy
                inx
                txa
                asl
                asl
                tax
                dex
                ldy #3
-               lda Str_NewFile_Imgs,x
                sta Ctrl_NF_ImgType,y
                dex
                dey
                bpl -
                jsr PaintCurWindow
                jsr WindowToScreen
+++             rts

DevNoDlgProc    jsr StdWndProc
                lda wndParam
                cmp #EC_LBTNRELEASE
                bne +++
                jsr IsInCurControl
                beq +++
                lda ControlID
                cmp #ID_BTN_OK
                bne +++
                ; Pressed "OK" in device number dialog
                +SelectControl 1
                ldx ControlIndex+CTRLSTRUCT_DIGIT_HI
                lda TimesTen,x
                sta dummy
                lda ControlIndex+CTRLSTRUCT_DIGIT_LO
                clc
                adc dummy
                sta dummy
                ;
                cmp CurDeviceNo
                beq ++
;                ldx CurDeviceInd
;                txa
;                and #%00000001
;                eor #%00000001
;                tay
;                lda dummy
;                cmp DeviceNumbers,y
;                bne +
;                ; Device numbers equal
;                jsr KillDialog
;                +ShowMessage <Str_Mess_SameDev, >Str_Mess_SameDev
;                rts
;+               ; Device numbers not equal
                ldx CurDeviceInd
                stx old_dev_ind
                sta DeviceNumbers,x
                jsr CloseDlg
                ldx old_dev_ind
                inx
                stx Param
                jsr IsWndTypePresent
                beq +++
                stx Param
                lda CurrentWindow
                sta old_cur_wnd
                jsr DeactivateWnd
                jsr SelectWindow
                jsr ShowDirectory
                lda GameMode
                bmi +
                lda old_cur_wnd
                sta CurrentWindow
+               jmp PaintTaskbar
++              jmp CloseDlg
+++             rts

TimesTen        !byte 0,10,20
old_dev_ind     !byte 0
old_cur_wnd     !byte 0

DiskInfoDlgProc jmp MessageDlgProc

CopyFileDlgProc jmp StdWndProc
                ;jsr StdWndProc
;                lda wndParam
;                cmp #EC_LBTNRELEASE
;                bne ++
;                jsr IsInCurControl
;                beq ++
;                lda ControlType
;                cmp #CT_BUTTON
;                beq +
;                rts
;+               jmp CloseDlg

FormatDlgProc   jsr StdWndProc
                lda wndParam
                cmp #EC_LBTNRELEASE
                beq +
                cmp #EC_KEYPRESS
                bne +++
                lda actkey
                cmp #$fc; return
                bne +++
                jmp format_ok
+               jsr IsInCurControl
                beq +++
                lda ControlID
                cmp #ID_BTN_OK
                bne ++
format_ok       ; "OK" pressed
                jsr FormatDisk
                jsr KillCurWindow
                jsr RepaintAll
                lda #GM_NORMAL
                sta GameMode
                lda error_code
                beq +
                jsr InstallIRQ
                jmp ShowDiskError
+               jmp ShowDirectory
++              cmp #ID_BTN_CANCEL
                bne +++
                ; "Cancel" pressed
                jmp CloseDlg
+++             rts

RenameDlgProc   jsr StdWndProc
                lda wndParam
                cmp #EC_LBTNRELEASE
                beq +
                cmp #EC_KEYPRESS
                bne ++++
                lda actkey
                cmp #$fc; return
                bne ++++
                jmp rename_ok
+               ; LBTNRELEASE
                jsr IsInCurControl
                beq ++++
                lda ControlID
                cmp #ID_BTN_OK
                bne +++
rename_ok       ; "OK" pressed
                lda WindowBitsEx
                and #BIT_EX_WND_ISDISK
                bne ++
                ; Rename file
                jsr RenameFile
                jmp after
++              ; Rename disk
                jsr RenameDisk
                lda error_code
                beq after
                ; Error rename disk
                jsr KillDialog
                jsr InstallIRQ
                jmp ShowDiskError
after           jsr KillDialog
                jmp ShowDirectory
+++             cmp #ID_BTN_CANCEL
                bne ++++
                jmp CloseDlg
++++            rts

KillDialog      jsr KillCurWindow
                jsr RepaintAll
                lda #GM_NORMAL
                sta GameMode
                rts

MessageDlgProc  jsr StdWndProc
                lda wndParam
                cmp #EC_LBTNRELEASE
                bne ++
                jsr IsInCurControl
                beq ++
                lda ControlID
                cmp #ID_BTN_OK
                bne ++
CloseDlg        jsr KillDialog
                jsr PaintTaskbar
++              rts

ClockDlgProc    jsr StdWndProc
                lda wndParam
                cmp #EC_LBTNRELEASE
                bne +
                jsr IsInCurControl
                beq +
                lda ControlID
                cmp #ID_BTN_SET
                bne +
                ; Pressed "Set" in clock dialog
                +SelectControl 0
                lda ControlIndex+CTRLSTRUCT_DIGIT_HI
                sta Clock
                lda ControlIndex+CTRLSTRUCT_DIGIT_LO
                sta Clock+1
                +SelectControl 1
                lda ControlIndex+CTRLSTRUCT_DIGIT_HI
                sta Clock+2
                lda ControlIndex+CTRLSTRUCT_DIGIT_LO
                sta Clock+3
                jsr SetTOD
                jmp CloseDlg
+               rts

YesNoDlgProc    jsr StdWndProc
                lda wndParam
                cmp #EC_LBTNRELEASE
                bne +++
                jsr IsInCurControl
                beq +++
                lda ControlID
                cmp #ID_BTN_YES
                bne +
                ; Clicked on "Yes"
                lda #1
                jmp ++
+               cmp #ID_BTN_NO
                bne +++
                ; Clicked on "No"
                lda #0
++              sta DialogResult
                jsr CloseDlg
                jmp (ModalAddress)
+++             rts