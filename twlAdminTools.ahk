#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
#Warn  ; Enable warnings to assist with detecting common errors.
SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
CoordMode, Mouse, Relative ; THIS SETS THE "MouseMove" RELATIVE TO THE ACTIVE WINDOW.

; = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = = ;

;;;; METHODS ;;;;
CloseAllADWindows(){
    While, WinExist("ahk_exe mmc.exe"){
        WinClose, ahk_exe mmc.exe
    }
    ; Ctrl+Win+F4 to close desktop.
    SendInput ^#{F4}
}

CreateNewDesktop(){     ; TODO: #5 Check if currenly in new desktop.
    SendInput ^#{d}
    Sleep, 100
}

; Start script when WindowsKey and NumPad1 are pressed.
#Numpad1::

; Close all open AD Windows.
CloseAllADWindows()

; Create new desktop.
CreateNewDesktop()

; Display InputBox that requires user input and display the message below.
InputBox, inputADUsername, Reset Domain User's Password, Please enter a Username that you want to change the password of:, , 300, 150, , , , ,
if (ErrorLevel){
    MsgBox, CANCEL was pressed.`nClosing system.
    CloseAllADWindows()
    return
}
else{
    ; Launch AD and wait until that window is active.
    Run "dsa.msc"
    WinWait, Active Directory Users and Computers

    ; Move mouse to click on DOMAIN.
    MouseMove, 40, 130
    MouseClick,

    ; Move mouse to FIND button.
    MouseMove, 382, 66
    MouseClick,
    Sleep, 500
    
    ; Move mouse to click on name field and input ADUsers Name.
    MouseMove, 119, 135
    MouseClick,
    Send %inputADUsername%
    Sleep, 100
    Send, {enter}

    ; Move mouse to SEARCHED USER.
    MouseMove, 20, 348
    Sleep, 150
    MouseClick

    ; Ask user if this is the correct ADUser to edit.
    InputBox, isCorrectADUser , IS THE USER CORRECT?, Is this the correct user you wish to edit? (Y or N), , 200, 200, , , , , 

    if (isCorrectADUser == "y" or "Y" or ""){
        ; Display InputBox that requres user input asking for new password.
        InputBox, inputADPassword, ENTER NEW PASSWORD, What is the new password you would like to set for the user?, , 300, 150, , , , ,
        if (ErrorLevel){    ; TODO: #4 Get rid of nested IfEsle
            MsgBox, CANCEL was pressed.`nClosing system.
            CloseAllADWindows()
            return
        }
        else{
            ; Rightclick and move mouse to CHANGE PASSWORD.
            Sleep, 500
            MouseClick, Right
            MouseMove, 36, 484
            MouseClick,
            Sleep, 150
            
            ; Enter the new password.
            Send, %inputADPassword%
            Sleep, 150
            Send, {tab}
            Sleep, 150
            Send, %inputADPassword%
            Sleep, 150
            Send, {enter}
            Sleep, 300

            ; Copy inputADPassword to Clipboard.
            Clipboard = %inputADPassword%

            ; TODO: #3 Check for if password set was a success.

            ; Display MsgBox confirming password change.
            MsgBox, , SUCCESS!, The pasword for User: %inputADUsername% has been reset!`nNow closing all open AD Windows.`n`PASSWORD RESET TO %inputADPassword%.`nTHE PASSWORD HAS BEEN COPPIED TO YOUR CLIPBOARD.
            CloseAllADWindows()
            return
        }        
    }
    else{
        MsgBox, YOU SELECTED NO OR SOME OTHER OPTION. STOPPING NOW!!!!`nCLOSING AD...

        CloseAllADWindows()
        return
    }
}
return