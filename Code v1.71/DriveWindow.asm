; Creates a drive wnd with type in A
CreateDriveWnd  cmp #WT_DRIVE_A
                bne +
                ; Drive A
                +CreateWindowByData <Wnd_DriveA, >Wnd_DriveA
                lda res
                bne ++
                rts
+               ; Drive B
                +CreateWindowByData <Wnd_DriveB, >Wnd_DriveB
                lda res
                beq +++
++              ;
                jsr GetCurDeviceInd
                +AddControl <Ctrl_Drv_Menubar, >Ctrl_Drv_Menubar
                +ControlSetStringList <Str_DriveMenubar, >Str_DriveMenubar, 3
                +MenubarAddMenuList <DriveMenubar, >DriveMenubar
                ;
                +AddControl <Ctrl_Drv_FLB, >Ctrl_Drv_FLB
                lda #BIT_CTRL_ISMAXIMIZED
                sta ControlBits
                ldx CurDeviceInd
                lda ControlOnHeap
                sta FileListBoxesLo,x
                lda ControlOnHeap+1
                sta FileListBoxesHi,x
                ;
                lda ControlBitsEx
                and #%01111111
                ora ShowFileSizes,x
                sta ControlBitsEx
                ;
                jsr UpdateWindow
                +ControlSetColorVal CL_WHITE
+++             rts

DriveWndProc    lda wndParam
                cmp #EC_LBTNPRESS
                bne +++
                lda wndParam+1
                bne +++
                jsr GetMousePosInWnd
                lda MousePosInWndY
                bpl +++
                jsr GetCurDeviceInd
                ldy #32
                lda ShowFileSizes,x
                beq +
                ldy #227
+               sty Menu_Drive_View+3
                ldy #32
                lda ShowLowerCase,x
                beq +
                ldy #227
+               sty Menu_Drive_View+15
                ;
+++             jsr StdWndProc
                ;
                lda wndParam+1
                beq DriveWnd_NM
                bmi +++
                ; In menu mode
                lda wndParam
                cmp #EC_LBTNPRESS
                bne +++
                ; Mouse btn pressed in MM
                jsr IsInCurMenu
                beq +++
                lda CurMenuID
                cmp #ID_MENU_DISK
                bne +
                jmp DiskMenuClicked
+               cmp #ID_MENU_FILE
                bne +
                jmp FileMenuClicked
+               jmp OptsMenuClicked
DriveWnd_NM     ; In normal mode
                lda wndParam
                cmp #EC_DBLCLICK
                bne ++
                ; Double clicked in normal mode
                +SelectControl 1
                jsr IsInCurControl
                beq +++
                jsr FLSB_GetMouseArea
                cpy #1
                bne +++
                jmp DblClickAction
++              cmp #EC_KEYPRESS
                bne +++
                ; Key pressed in normal mode
                lda actkey
                cmp #$fc
                bne +++
                ; Return pressed
                jmp DblClickAction
+++             rts

; Does the following:
; * Copies filename string of highlighted file in list view to Str_FileName
; * Copies file size to FileSizeHex
; * Copies file type to Str_FileType
; Expects: control FileListScrollBox selected
; Output:
; 1 (success) or 0 (error) in res
; string length is in Y
GetFile         lda #0
                sta res
                ; Get pointer to string list
                lda WindowType
                cmp #WT_DRIVE_A
                bne +
                lda #<STRING_LIST_DRIVEA
                sta $fb
                lda #>STRING_LIST_DRIVEA
                sta $fc
                jmp ++
+               lda #<STRING_LIST_DRIVEB
                sta $fb
                lda #>STRING_LIST_DRIVEB
                sta $fc
++              ; Find filename location (FBFC)
                ldx ControlHilIndex
                beq +
                cpx ControlNumStr
                bcs ++
-               lda #FILE_RECORD_LENGTH
                jsr AddToFB
                dex
                bne -
+               ; Copy file size to FileSizeHex
                ldy #0
                lda ($fb),y
                sta FileSizeHex
                iny
                lda ($fb),y
                sta FileSizeHex+1
                ; Get file type
                ldy #19
                lda ($fb),y
                sta Str_FileType
                ; Copy filename to Str_FileName
                lda #2
                jsr AddToFB
                ldy #$ff
-               iny
                lda ($fb),y
                beq +
                sta Str_FileName,y
                jmp -
+               sta Str_FileName,y
                lda #1
                sta res
++              rts

DblClickAction  jsr GetFile
                sty HasFileExt+1; self-modifying code below
                sty IsPRGExt+1; self-modifying code below
                sty IsValidFileExt+1; self-modifying code below
                jsr GetCurDeviceNo
                lda Str_FileType
                cmp #"S"; SEQ
                beq GoViewFile
                cmp #"U"; USR
                beq GoViewFile
                cmp #"R"; REL
                beq GoViewFile
                cmp #"D"; DEL
                beq +++
                cmp #"F"; folder
                bne ++
                ; It's a folder
                jsr ChangeDir
                lda #0
                jmp Thereafter
++              cmp #"P"; PRG
                bne +++
                ; It's a PRG file
                ldx CurDeviceInd
                lda IsDiskDrive,x
                bne ++; RUN
                ; It's not a disk drive
                lda IsDiskImage,x
                bne ++; RUN
                ; We're not in a disk image (hence in a directory)
                jsr HasFileExt
                beq ++; RUN
                jsr IsValidFileExt; .d64, .d71, .d81, .dnp
                bne +
                jsr IsPRGExt; .prg
                bne ++; RUN
                +ShowMessageJMP <Str_Mess_NoValidFileType, >Str_Mess_NoValidFileType
+               jsr ChangeDir
                lda #1
                jmp Thereafter
++              ; RUN if disk drive or if file has valid file ext
                lda #EC_RUNFILE
                sta exit_code
+++             rts

; Called after ChangeDir
; Requires value (0/1) in A
; A=0: Changed to folder
; A=1: Changed to disk image
Thereafter      ldx error_code
                beq +
                jmp ShowDiskError
+               ldx CurDeviceInd
                sta IsDiskImage,x
                jmp ShowDirectory

GoViewFile      jmp ActionViewFile

; Checks if there is a dot at the end of file name indicating a
; file extension of up to 4 chars
HasFileExt      ldy #$FF; Is filled in DblClickAction and is the fn string length
                dey
                dey
                bmi +
                ldx #3
-               lda Str_FileName,y
                cmp #"."
                beq ++
                dey
                dex
                bpl -
+               lda #0
                rts
++              lda #1
                rts

IsPRGExt        ldy #$FF; Is filled in DblClickAction and is the fn length
                dey
                lda Str_FileName,y
                cmp #$47 ;"g"
                beq +
                cmp #$67 ;"G"
                bne ++
+               dey
                lda Str_FileName,y
                cmp #$52 ;"r"
                beq +
                cmp #$72 ;"R"
                bne ++
+               dey
                lda Str_FileName,y
                cmp #$50 ;"p"
                beq +
                cmp #$70 ;"P"
                bne ++
+               lda #1
                rts
++              lda #0
                rts

; Decides on whether file name of PRG ends with ".d64", ".d71", ".d81", or ".dnp"
IsValidFileExt  ldy #$FF; Is filled in DblClickAction and is the fn length
                dey
                dey
                dey
                lda Str_FileName,y
                cmp #$44 ;"d"
                beq +
                cmp #$c4 ;"D"
                bne ++
+               iny
                ; Check for d64
                lda Str_FileName,y
                cmp #"6"
                bne +
                iny
                lda Str_FileName,y
                cmp #"4"
                bne ++
                jmp is_valid
+               ; Check for d71/d81
                iny
                lda Str_FileName,y
                cmp #"1"
                bne +
                dey
                lda Str_FileName,y
                cmp #"7"
                beq is_valid
                cmp #"8"
                bne ++
                jmp is_valid
+               ; Check for dnp
                cmp #"P"
                bne ++
                dey
                lda Str_FileName,y
                cmp #"N"
                bne ++
is_valid        lda #1
                rts
++              lda #0
                rts

OptsMenuClicked lda CurMenuItem
                cmp #ID_MI_SHOWSIZES
                bne +++
                ; Clicked on "Show Sizes"
                jsr GetCurDeviceInd
                +SelectControl 1
                lda ControlBitsEx
                eor #BIT_EX_CTRL_SHOWSIZES
                sta ControlBitsEx
                and #BIT_EX_CTRL_SHOWSIZES
                ldx CurDeviceInd
                sta ShowFileSizes,x
                ;
                jsr SetDrvWndWidth
-               jsr UpdateControl
                jmp RepaintAll
+++             cmp #ID_MI_LOWERCASE
                bne +
                ; Clicked on "Lower case"
                jsr GetCurDeviceInd
                +SelectControl 1
                lda ControlBitsEx
                eor #BIT_EX_CTRL_LOWERCASE
                sta ControlBitsEx
                and #BIT_EX_CTRL_LOWERCASE
                ldx CurDeviceInd
                sta ShowLowerCase,x
                jmp -
+               cmp #ID_MI_SORTBYNAME
                bne +
                ; Clicked on "Sort by name"
                jmp SortByName
+               cmp #ID_MI_SORTBYTYPE
                bne +
                ; Clicked on "Sort by type"
                jmp SortByType
+               cmp #ID_MI_SORTBYSIZE
                bne +
                ; Clicked on "Sort by size"
                jmp SortBySize
+               cmp #ID_MI_GUI64INFO
                bne +
                ;Clicked on "GUI64 Info"
                +ShowMessage <Str_Mess_GUI64, >Str_Mess_GUI64
+               rts

; Sorts folders and files by name
SortByName      rts

; Sorts files by size
SortBySize      rts

; Sorts files by type (P,S,U,R,D)
SortByType      jsr GetCurDeviceInd
                ldy CurDeviceInd
                lda StringListDrvLo,y
                sta $fb
                lda StringListDrvHi,y
                sta $fc
                ldx #0
                lda IsDiskDrive,y
                bne +
                ; No disk drive --> jump over folders
                ldy #(FILE_RECORD_LENGTH-1)
-               lda ($fb),y
                cmp #$46 ; "F" folder
                bne +
                lda #FILE_RECORD_LENGTH
                jsr AddToFB
                inx
                jmp -
+               stx dummy; no of folders
                lda $fb
                sta $fd
                lda $fc
                sta $fe
                ; Find number of files
                lda #1
                jsr SelectControl
                lda $fd
                sta $fb
                lda $fe
                sta $fc
                lda ControlNumStr
                sec
                sbc dummy
                sta dummy; no of files
                tax
                beq +++; Leave if no files to sort
                ; Build list at FREEMEM
                ldx #0
                ldy #(FILE_RECORD_LENGTH-1)
-               lda ($fb),y
                sta FREEMEM,x
                lda #FILE_RECORD_LENGTH
                jsr AddToFB
                inx
                cpx dummy
                bcc -
                ; Sort list at FREEMEM
                jmp *
+++             rts

SetDrvWndWidth  jsr GetCurDeviceInd
                ldx CurDeviceInd
                lda #20
                ldy ShowFileSizes,x
                bne ++
                ldy Max_Fn_Len_Plus2,x
                cpy #18
                bcc +
--              lda #21
-
+               sta WindowWidth
                ldx CurrentWindow
                sta WndDefWidth,x
                jmp CorrectWinPosX
++              ldy Max_Fn_Len_Plus2,x
                cpy #13
                bcc -
                beq --
                tya
                clc
                adc #8
                sta WindowWidth
                ldx CurrentWindow
                sta WndDefWidth,x
CorrectWinPosX  ; Possibly correct WindowPosX after setting WindowWidth
                clc
                adc WindowPosX
                cmp #41
                bcc +
                lda #40
                sec
                sbc WindowWidth
                sta WindowPosX
+               jmp UpdateWindow

FileMenuClicked lda CurMenuItem
                cmp #ID_MI_FILENEW
                bne +
                ; Clicked on "New"
                jmp ActionNewFile
+               cmp #ID_MI_FILECUT
                bne ++
                ; Clicked on "Cut"
                jsr ActionCopyFile
                lda CanCopy
                beq +
                sta IsCut
+               rts
++              cmp #ID_MI_FILECOPY
                bne +
                ; Clicked on "Copy"
                jmp ActionCopyFile
+               cmp #ID_MI_FILEPASTE
                bne +
                ; Clicked on "Paste"
                jmp ActionPasteFile
+               cmp #ID_MI_FILEDELETE
                bne +
                ; Clicked on "Delete"
                jmp ActionDelete
+               cmp #ID_MI_FILERENAME
                bne +
                ; Clicked on "Rename"
                jmp ActionRenamFile
+               cmp #ID_MI_FILEVIEW
                bne +
                ; Clicked on "View"
                jmp ActionViewFile
+               cmp #ID_MI_FILEBOOT
                bne +
                ; Clicked on "Boot"
                lda #EC_BOOTFILE
                sta exit_code
+               rts

DiskMenuClicked lda CurMenuItem
                cmp #ID_MI_DISKREFRESH
                bne +
                ; Clicked on "Refresh"
                jmp ShowDirectory
+               cmp #ID_MI_DEVICENO
                bne +
                ; Clicked on "Device No"
                jmp ShowDeviceNoDlg
+               cmp #ID_MI_DISKINFO
                bne +
                ; Clicked on "Info"
                jmp ShowDiskInfoDlg
+               cmp #ID_MI_DISKFORMAT
                bne +
                ; Clicked on "Format"
                jmp ShowFormatDlg
+               cmp #ID_MI_DISKRENAME
                bne +
                ; Clicked on "Rename"
                jmp ActionRenamDisk
+               cmp #ID_MI_DISKCLOSE
                bne +
                ; Clicked on "Close"
                jsr KillCurWindow
                jsr RepaintAll
                jsr PaintTaskbar
+               rts

ActionViewFile  jsr GetCurDeviceNo
                +SelectControl 1
                lda ControlHilIndex
                cmp ControlNumStr
                bcs ++
                ; Read file from disk into buffer
                jsr GetFile
                jsr ReadFileToViewerBuf
                lda error_code
                beq +
                jmp ShowDiskError
+               jsr PaintTaskbar
                ; Show viewer window
                jsr CreateViewerWnd
                jsr RepaintAll
                jsr PaintTaskbar
++              rts

ThrowSpaceError +ShowMessage <Str_Mess_NoSpace, >Str_Mess_NoSpace
                rts

ActionPasteFile lda CanCopy
                bne +
                rts
+               jsr GetCurDeviceNo
                lda CurDeviceInd
                sta DiskToCopyTo+1
                lda CurDeviceNo
                sta DiskToCopyTo
                ;cmp DiskToCopyFrom
                ;bne +
                ;+ShowMessage <Str_Mess_NoSameDisk, >Str_Mess_NoSameDisk
                ;rts
;+               
                ; Check if there is enough space on disk
                ldx DiskToCopyTo+1
                lda BlocksFreeHexHi,x
                cmp FileSizeHex+1
                bcc ThrowSpaceError
                bne ++
                lda BlocksFreeHexLo,x
                cmp FileSizeHex
                bcc ThrowSpaceError
++              ; Do paste
                jsr ShowCopyFileDlg
                jsr CopyPasteFile
                jsr KillCurWindow; kills dialog
                lda error_code
                beq +
                ; Error
                jsr ShowDiskError
                +AddBitExToCurWnd BIT_EX_WND_ISERRMSG
                jsr bttr
                jmp InstallIRQ
+               lda IsCut
                beq ++
                lda DiskToCopyFrom
                sta CurDeviceNo
                jsr deletefile
                ldx DiskToCopyFrom+1
                lda StringListDrvLo,x
                sta $fb
                lda StringListDrvHi,x
                sta $fc
                stx dummy
                jsr LoadDir
                ldx dummy
                lda FileListBoxesLo,x
                sta $fb
                lda FileListBoxesHi,x
                sta $fc
                ldy #CTRLSTRUCT_NUMSTRINGS
                lda num_files
                sta ($fb),y
                jsr GetDiskValues
++              jsr bttr
                jsr RepaintAll
                jmp ShowDirectory

bttr            lda #0
                sta CanCopy
                sta IsCut
                lda #GM_NORMAL
                sta GameMode
                rts

ActionNewFile   jsr GetCurDeviceNo
                ldx CurDeviceInd
                lda IsDiskDrive,x
                bne +
                lda IsDiskImage,x
                bne +
                jmp ShowNewFileDlg
+               +ShowMessageJMP <Str_Mess_NoNew, >Str_Mess_NoNew

ActionCopyFile  lda #0
                sta CanCopy
                sta IsCut
                +SelectControl 1
                lda ControlHilIndex
                cmp ControlNumStr
                bcs +
                jsr GetFile
                lda Str_FileType
                sta write_appendix+1
                ;
                jsr GetCurDeviceNo
                lda CurDeviceNo
                sta DiskToCopyFrom
                lda CurDeviceInd
                sta DiskToCopyFrom+1
                lda #1
                sta CanCopy
+               rts

ActionRenamDisk jsr GetCurDeviceNo
                ldx CurDeviceInd
                lda Str_Title_DrvLo,x
                sta $fb
                lda Str_Title_DrvHi,x
                sta $fc
                ldy #15
-               lda ($fb),y
                sta Str_FileName,y
                dey
                bpl -
                lda #0
                jmp ShowRenameDlg

ActionRenamFile +SelectControl 1
                lda ControlHilIndex
                cmp ControlNumStr
                bcs ++
                jsr GetFile
                lda #1
                jsr ShowRenameDlg
++              rts

ActionDelete    +SelectControl 1
                lda ControlHilIndex
                cmp ControlNumStr
                bcs ++
                jsr GetCurDeviceNo
                lda #<Str_Dlg_Delete
                sta $fd
                lda #>Str_Dlg_Delete
                sta $fe
                lda #<mod_res1
                sta ModalAddress
                lda #>mod_res1
                sta ModalAddress+1
                jmp ShowAreYouSureDlg
mod_res1        lda DialogResult
                cmp #1
                bne ++
                jsr DeleteFile
                lda error_code
                beq +
                jmp ShowDiskError
+               jsr ShowDirectory
++              rts