OnKeyPress      lda VisibleWindows
                beq back_to_ml
                lda #EC_KEYPRESS
                sta wndParam
                jmp JustPassOn

OnLongLBtnPress
OnScrollWheel   sta wndParam; EC_LLBTNPRESS / EC_SCROLLUP/DOWN
                lda GameMode
                cmp #GM_MENU
                beq back_to_ml
                jsr IsInCurWnd
                lda res
                beq back_to_ml
JustPassOn      lda #GM_NORMAL
                sta wndParam+1
                jmp (WindowProc)
back_to_ml      rts

OnDblClick      jsr OnLBtnPress
                lda GameMode
                beq +
                rts
+               ; Only processed in curr wnd and desktop
                jsr GetMouseInfo
                jsr IsInCurWnd
                lda res
                beq ++
                ; In current window
                jsr IsInTitleBar
                lda res
                bne +
                ; Not in title bar
                lda #EC_DBLCLICK
                sta wndParam
                lda #GM_NORMAL
                sta wndParam+1
                jmp (WindowProc)
+               ; Dbl clicked in title bar
                jsr IsInMinMaxClose
                lda res
                bne +
                lda WindowBits
                and #BIT_WND_CANMAXIMIZE
                beq +
                jsr MaximizeCurWnd
                jmp RepaintAll
++              ; Not in current window
                jsr WindowFromPos
                lda res
                cmp #$ff
                beq +
                ; in another wnd
                rts
+               ; Not in a window
                jsr IsInTaskbar
                lda res
                beq ++
                ; In taskbar
                lda MouseInfo
                cmp #34
                bcs +
                rts
+               ; In clock
                jsr ShowClockDialog
                rts
++              ; On desktop
                jsr IsInDrive8Icon
                lda res
                beq ++
                ; In drive 8
                lda #WT_DRIVE_8
                sta Param
                jsr IsWndTypePresent
                lda res
                bne driveWndExists
                jsr DeactivateWnd
                lda #WT_DRIVE_8
                jmp createDriveWnd
++              ; Not in drive 8
                jsr IsInDrive9Icon
                lda res
                bne +
                rts
+               ; In drive 9
                lda #WT_DRIVE_9
                sta Param
                jsr IsWndTypePresent
                lda res
                bne driveWndExists
                jsr DeactivateWnd
                lda #WT_DRIVE_9
createDriveWnd  jsr CreateDriveWnd
                lda res
                beq ++
                jsr ShowDirectory
                lda error_code
                beq +
                rts
+               lda num_files
                clc
                adc #4
                cmp #DRVWND_HEIGHT
                bcc +
                lda #DRVWND_HEIGHT
                jmp set_wh
+               cmp #7
                bcs set_wh
                lda #7
set_wh          sta WindowHeight
                ldx CurrentWindow
                sta WndDefHeight,x
                jsr UpdateWindow
                jmp RepaintAll
driveWndExists  ldy #WNDSTRUCT_HANDLE
                lda ($fb),y
                sta Param
                jsr SelectTopWindow
                jsr RestoreCurWnd
                jsr RepaintAll
                jsr PaintTaskbar
++              rts

;============================================= OnButtonPress
; Right Button------------------------------------------------
OnRBtnPress     jsr IsInCurWnd
                lda res
                beq +
                ;          
+               rts

; Left Button-------------------------------------------------
OnLBtnPress     jsr GetMouseInfo
                lda GameMode
                beq ClickInNormalMode
                bpl ClickInMM
                jmp ClickInDM

ClickInMM       jmp ClickInMenuMode
ClickInDM       jmp ClickInDlgMode

ClickInNormalMode
                lda #$ff
                sta PressedPoint
                sta PressedPoint+1
                jsr IsInStartBtn
                lda res
                beq +
                ; In Start button
                lda #1
                sta StartBtnPushed
                lda #GM_MENU
                sta GameMode
                jsr GenerateReservedForSM
                jsr InvertReserved_DT
                jmp PaintStartMenu
+               ; Not in Start button
                jsr IsInTaskbar
                lda res
                beq ++
                ; In task bar
                jsr IsInTaskBtns
                lda res
                bne +
                ; Not in task buttons
                rts
+               ; In task buttons
                jsr GetTaskBtnIndex
                ldx res
                bpl +
                rts
+               lda TaskBtnHandles,x
                sta Param
                cmp WndPriorityList
                bne +
                lda CurrentWindow
                bmi +
                jsr MinimizeCurWnd
                jsr RepaintAll
                jmp PaintTaskbar
+               lda Param
                jsr ChangeActiveWnd
                jmp RestoreCurWnd
++              ; Not in task bar
                jsr IsInCurWnd
                lda res
                beq +++
                ; In cur window
                jsr IsInTitleBar
                lda res
                beq ++
                ; In title bar
                jsr IsInMinMaxClose
                lda res
                beq +
                ; In min/max/close symbol
                lda MouseInfo
                sta PressedPoint
                lda MouseInfo+1
                sta PressedPoint+1
                rts
+               ; Not in min/max/close symbols
                lda WindowPosX
                sta OldPosX
                lda MouseInfo
                sta DragWndAnchorX
                lda #0
                sta DragType
                lda #1
                sta MayDragWnd
                rts
++              ; Not in title bar
                lda CurrentCursor
                cmp #CUR_DEFAULT
                beq +
                cmp #CUR_CARRET
                beq +
                lda MouseInfo
                sta DragWndAnchorX
                lda MouseInfo+1
                sta DragWndAnchorY
                lda #1
                sta DragType
                sta MayDragWnd
                rts
+               ; Not in title bar, no resize
                lda #EC_LBTNPRESS
                sta wndParam
                lda #GM_NORMAL
                sta wndParam+1
                jmp (WindowProc)
+++             ; Not in cur window
                jsr WindowFromPos
                lda res
                bmi +
                jsr IsWndVisible
                lda res
                beq +
                ldy #0
                lda ($fb),y
                jsr ChangeActiveWnd
                jmp ClickInNormalMode
+               rts
ChangeActiveWnd ; Not on desktop
                sta Param
                jsr DeactivateWnd
                jsr SelectTopWindow
                jsr PaintCurWindow
                jsr WindowToScreen
                jmp PaintTaskbar

ClickInMenuMode lda StartBtnPushed
                bne CloseStartMenu
                ; Start button not pushed
                lda #EC_LBTNPRESS
                sta wndParam
                lda #GM_MENU
                sta wndParam+1
                jmp (WindowProc)
CloseStartMenu  lda #0
                sta StartBtnPushed
                sta MayHighlight
                sta GameMode
                lda #$ff
                sta OldMenuItem
                jsr PaintStartMenu
                jsr RepaintAll
                jsr IsInStartMenu
                lda res
                beq +
                ; Clicked in StartMenu
                lda MenuItem
                bne ClickedOnReset
                ; Clicked on Settings
                lda #WT_SETTINGS
                sta Param
                jsr IsWndTypePresent
                lda res
                bne +
                jsr DeactivateWnd
                jsr CreateSettingsWindow
                jsr PaintCurWindow
                jsr WindowToScreen
                jsr PaintTaskbar
+               rts
ClickedOnReset  ; Clicked on Reset
                lda #<Str_Dlg_Reset
                sta $fd
                lda #>Str_Dlg_Reset
                sta $fe
                lda #<mod_res2
                sta ModalAddress
                lda #>mod_res2
                sta ModalAddress+1
                jsr ShowAreYouSureDlg
mod_res2        lda DialogResult
                cmp #1
                bne ++
                lda #EC_GAMEEXIT
                sta exit_code
++              rts

ClickInDlgMode  jsr IsInCurWnd
                lda res
                beq +
                jmp ClickInNormalMode
+               rts

;============================================= OnButtonRelease
; Right Button------------------------------------------------
OnRBtnRelease   rts
                

; Left Button-------------------------------------------------
OnLBtnRelease   lda MayDragWnd
                beq ++
                lda IsWndDragging
                beq +
                lda #0
                sta IsWndDragging
                sta MayDragWnd
                lda WindowFocCtrl
                jsr SelectControl
                rts
+               lda #0
                sta MayDragWnd
                rts
++              ; No drag
                lda ControlPressed
                beq +
                lda #EC_LBTNRELEASE
                sta wndParam
                lda #GM_NORMAL
                sta wndParam+1
                jmp (WindowProc)
+               jsr IsAtPressedPoint
                lda res
                bne +
                ; Not in pressed point
                rts
+               ; Is in pressed point
                jsr IsInTitleBar
                lda res
                beq +
                jsr IsInMinMaxClose
                lda res
                beq +++
                ; In max/close symbols
                cmp #3
                bne +
                ; In minimize symbol
                jsr MinimizeCurWnd
                jsr RepaintAll
                jsr PaintTaskbar
                rts
+               cmp #2
                bne ++
                ; In maximize symbol
                lda WindowBits
                and #BIT_WND_ISMAXIMIZED
                beq +
                jsr CurWnd_SetDefSize
                jmp rep
+               jsr MaximizeCurWnd
rep             jsr RepaintAll
                rts
++              ; In close symbol
                jsr KillCurWindow
                jsr RepaintAll
                jsr PaintTaskbar
                lda #GM_NORMAL
                sta GameMode
                rts
+++             ; Not in max/close symbols
                rts

;============================================= OnMouseMove
MovInMenuModeP  jmp MovInMenuMode

OnMouseMove     jsr GetMouseInfo
                lda GameMode
                beq MovInNrmDlgMode
                bpl MovInMenuModeP

MovInNrmDlgMode ; Moved in normal AND Dlg mode
                lda bFirePressed
                bne +
                lda IsLBtnPressed
                beq ++
                ; Mouse button is pressed
+               lda ControlPressed
                beq +
Jmp_StdWnd      lda #EC_MOUSEMOVE
                sta wndParam
                lda #GM_NORMAL
                sta wndParam+1
                jmp (WindowProc)
+               lda MayDragWnd
                beq +
                lda #1
                sta IsWndDragging
                jsr Drag
+               rts
++              ; Mouse button NOT pressed
                jsr IsInCurWnd
                lda res
                beq ++
                ; Moved in cur wnd
                lda WindowBits
                and #BIT_WND_RESIZABLE
                beq ++
                ; Check if in lower right corner
                lda WindowPosX
                clc
                adc WindowWidth
                tax
                dex
                cpx MouseInfo
                bne ++
                lda WindowPosY
                clc
                adc WindowHeight
                tax
                dex
                cpx MouseInfo+1
                bne ++
                ; Is in lower right corner
                ldx WindowBits
                txa
                and #BIT_WND_FIXEDWIDTH
                beq +
                +SetCursor CUR_RESIZENS
                rts
+               txa
                and #BIT_WND_FIXEDHEIGHT
                beq +
                +SetCursor CUR_RESIZEWE
                rts
+               +SetCursor CUR_RESIZENWSE
                rts
++              ; Not in lower right corner
                +SetCursor CUR_DEFAULT
                lda VisibleWindows
                beq +
                jmp Jmp_StdWnd
+               rts

MovInMenuMode   lda StartBtnPushed
                bne +
                ; Is in menu mode of cur wnd
                lda #EC_MOUSEMOVE
                sta wndParam
                lda #GM_MENU
                sta wndParam+1
                jmp (WindowProc)
+               ; Start Button pushed
                jsr IsInStartMenu
                lda res
                bne +
                lda #0
                sta MayHighlight
                lda #$ff
                sta OldMenuItem
                jsr PaintStartMenu
                rts
+               ; Get y-coord of upper beam
                lda #22
                sec
                sbc #StartMenuHeight
                ; Upper y-coord of StartMenu (Scr coords)
                asl
                asl
                asl
                clc
                adc #54
                sta dummy
                ;
                lda MouseInfo+3
                sec
                sbc dummy
                lsr
                lsr
                lsr
                lsr
                sta MenuItem
                ; Result should be 0 or 1
                cmp #StartMenuItems
                bcc +
                lda OldMenuItem
                sta MenuItem
                rts
                ;
+               cmp OldMenuItem
                bne +
                rts
                ;
+               sta OldMenuItem
                ; Paint Startmenu and the chars in DT_Reserved
                jsr PaintStartMenu
                lda #22
                sec
                sbc #StartMenuHeight
                sta dummy
                inc dummy
                lda MenuItem
                asl
                clc
                adc dummy
                tax
                lda ScrTabLo,x
                sta $fb
                lda ScrTabHi,x
                sta $fc
                lda #1
                jsr AddToFB
                ;+AddValToFB 1
                lda $fb
                sta $02
                lda $fc
                clc
                adc #>CLRMEM_MINUS_SCRMEM
                sta $03
                ;
                lda #0
                sta MayHighlight
                lda MenuItem
                asl
                asl
                asl
                clc
                adc #DT_Reserved_Char
                tax
                ldy #0
-               txa
                sta ($fb),y
                lda #1
                sta ($02),y
                inx
                iny
                cpy #8
                bcc -
                lda #1
                sta MayHighlight
                rts