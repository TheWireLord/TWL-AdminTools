#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
CoordMode, Mouse, Relative ; THIS SETS THE "MouseMove" SET RELATIVE TO THE ACTIVE WINDOW.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;           TODO:
; - Adjust window titles and design/size.
; - Error checking for InputBox.
; - Clean code by adding methods.
; - Loops for closing AD windows.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; START SCRIPT WHEN Window Key and Numpad 1 ARE PRESSED.
#Numpad1::

; Close AD Window(s).
WinClose, Active Directory Users and Computers, , , ,
WinClose, ahk_exe mmc.exe

; Display InputBox that requires user input and display the message below.
InputBox, inputADUsername, Reset Domain User's Password, Please enter a Username that you want to change the password of:, , 300, 150, , , , ,
if (ErrorLevel)

{
    MsgBox, CANCEL was pressed.`nClosing system.
    return
}
else
{
   ; Launch AD and wait until that window is active.
    Run "dsa.msc"
    WinWait, Active Directory Users and Computers

    ; Move mouse to click on DOMAIN.
    MouseMove, 40, 130
    MouseClick,

    ; Move mouse to FIND button and navigate to input ADUser's Name.
    MouseMove, 382, 66
    MouseClick,
    Sleep, 500
    Send %inputADUsername%
    Send, {enter}

    ; Move mouse to SEARCHED USER.
    MouseMove, 20, 348
    Sleep, 500
    MouseClick

    ; Ask user if this is the correct ADUser to edit.
    InputBox, isCorrectADUser , IS THE USER CORRECT?, Is this the correct user you wish to edit? (Y or N), , 200, 200, , , , , 

    If (isCorrectADUser == "y" or isCorrectADUser == "Y")
    {
        ; Display InputBox that requres user input asking for new password.
        InputBox, inputADPassword, ENTER NEW PASSWORD, What is the new password you would like to set for the user?, HIDE, 300, 150, , , , ,

        ; Rightclick and move mouse to CHANGE PASSWORD.
        Sleep, 500
        MouseClick, Right, , , , , ,
        MouseMove, 36, 484
        MouseClick,
        
        ; Enter the new password.
        Send, %inputADPassword%
        Send, {tab}
        Send, %inputADPassword%

        ;;; Send, {enter}


        ;;;;WinClose, ahk_exe mmc.exe
        ;;;;WinClose, ahk_exe mmc.exe

        ;;;MsgBox, , SUCCESS!, The pasword for User: %inputADUsername% has been reset!
        return
    }
    else
    {
        MsgBox, YOU SELECTED NO OR SOME OTHER OPTION. STOPPING NOW!!!!            
        MsgBox, CLOSING AD...
        WinClose, ahk_exe mmc.exe
        WinClose, ahk_exe mmc.exe
        return
    }
}
return