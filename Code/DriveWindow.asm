; Creates a drive wnd with type in A
CreateDriveWnd  cmp #WT_DRIVE_8
                bne +
                +CreateWindowByData <Wnd_Drive8, >Wnd_Drive8
                lda res
                beq +++
                lda #8
                jmp ++
+               +CreateWindowByData <Wnd_Drive9, >Wnd_Drive9
                lda res
                beq +++
                lda #9
++              ;
                sta DeviceNumber
                +AddControl <Ctrl_Drv_Menubar, >Ctrl_Drv_Menubar
                +ControlSetStringList <Str_DriveMenubar, >Str_DriveMenubar, 2
                +MenubarAddMenuList <DriveMenus, >DriveMenus
                ;
                +AddControl <Ctrl_Drv_FLB, >Ctrl_Drv_FLB
                lda #BIT_CTRL_ISMAXIMIZED
                sta ControlBits
                +ControlSetColorVal CL_WHITE
                lda DeviceNumber
                sec
                sbc #8
                tax
                lda ControlOnHeap
                sta FileListBoxesLo,x
                lda ControlOnHeap+1
                sta FileListBoxesHi,x
+++             rts

; Needs wndParam filled with exit code
DriveWndProc    jsr StdWndProc
                ;
                lda wndParam+1
                beq DriveWnd_NM
                bmi DriveWnd_DM
                ; In menu mode
                lda wndParam
                cmp #EC_LBTNPRESS
                bne ++
                ; Mouse btn pressed in MM
                jsr IsInCurMenu
                lda res
                beq ++
                lda CurMenuID
                cmp #ID_MENU_DISK
                beq +
                ; Clicked in File menu
                jsr FileMenuClicked
                rts
+               ; Clicked in Disk menu
                jsr DiskMenuClicked
++              rts
DriveWnd_DM     rts
DriveWnd_NM     lda wndParam
                cmp #EC_DBLCLICK
                bne +
                +SelectControl 1
                jsr IsInCurControl
                lda res
                beq +
                jsr GetMousePosInWnd
                ldx MousePosInWndX
                inx
                cpx ControlWidth
                beq +
                ldx MousePosInWndY
                beq +
                inx
                cpx ControlHeight
                bcs +
                lda #EC_RUNFILE
                sta exit_code
+               rts

FileMenuClicked lda CurMenuItem
                cmp #ID_MI_FILECUT
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
+               cmp #ID_MI_FILERUN
                bne +
                ; Clicked on "Run"
                lda #EC_RUNFILE
                sta exit_code
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
                jsr ShowDirectory
                rts
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

ThrowSpaceError +ShowMessage <Str_Mess_NoSpace, >Str_Mess_NoSpace
                rts

ActionPasteFile lda CanCopy
                bne +
                rts
+               jsr GetDeviceNumber
                lda DeviceNumber
                sta DiskToCopyTo
                cmp DiskToCopyFrom
                bne +
                +ShowMessage <Str_Mess_NoSameDisk, >Str_Mess_NoSameDisk
                rts
+               lda DiskToCopyFrom
                cmp #8
                bne +
                ; From 8 to 9
                lda BlocksFreeHexLo+1
                sta dummy
                lda BlocksFreeHexHi+1
                sta dummy+1
                jmp ++
+               ; From 9 to 8
                lda BlocksFreeHexLo
                sta dummy
                lda BlocksFreeHexHi
                sta dummy+1
++              ; Check if there is enough space on disk
                lda dummy+1
                cmp FileSizeHex+1
                bcc ThrowSpaceError
                bne ++
                lda dummy
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
                lda #0
                sta WindowAttribute
                jsr UpdateWindow
                jsr bttr
                jmp InstallIRQ
+               lda IsCut
                beq ++
                lda DiskToCopyFrom
                sta DeviceNumber
                jsr deletefile
                lda DeviceNumber
                sec
                sbc #8
                tax
                lda StringListDrvLo,x
                sta $fb
                lda StringListDrvHi,x
                sta $fc
                stx dummy
                jsr LoadDir
                jsr ManipulStrList
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
                jsr ShowDirectory
                rts

bttr            lda #0
                sta CanCopy
                sta IsCut
                lda #GM_NORMAL
                sta GameMode
                rts

ActionCopyFile  lda #0
                sta CanCopy
                sta IsCut
                +SelectControl 1
                lda ControlHilIndex
                cmp ControlNumStr
                bcs +
                jsr GetFileName
                ; Get first letter of file type
                ldy #18
                lda ($fb),y
                sta write_appendix+1
                ;
                jsr GetDeviceNumber
                lda DeviceNumber
                sta DiskToCopyFrom
                lda #1
                sta CanCopy
+               rts

ActionRenamDisk jsr GetDeviceNumber
                lda DeviceNumber
                sec
                sbc #8
                tax
                lda Str_Title_DrvLo,x
                sta $fb
                lda Str_Title_DrvHi,x
                sta $fc
                lda #2
                jsr AddToFB
                ;+AddValToFB 2
                ldy #15
-               lda ($fb),y
                sta Str_FileName,y
                dey
                bpl -
                lda #0
                jsr ShowRenameDlg
                rts

ActionRenamFile +SelectControl 1
                lda ControlHilIndex
                cmp ControlNumStr
                bcs ++
                jsr GetFileName
                lda #1
                jsr ShowRenameDlg
++              rts

ActionDelete    +SelectControl 1
                lda ControlHilIndex
                cmp ControlNumStr
                bcs ++
                jsr GetDeviceNumber
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
                rts
+               jsr ShowDirectory
++              rts