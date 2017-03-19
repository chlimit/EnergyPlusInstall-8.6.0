; CPack install script designed for a nmake build

;--------------------------------
; You must define these values

  !define VERSION "8.6.0-3eed2f7901"
  !define PATCH  "0"
  !define INST_DIR "E:/PersonalProject/EnergyPlus8.6.0/Project/InstallPack/EnergyPlus-8.6.0-3eed2f7901-Windows-x86_64"

;--------------------------------
;Variables

  Var MUI_TEMP
  Var STARTMENU_FOLDER
  Var SV_ALLUSERS
  Var START_MENU
  Var DO_NOT_ADD_TO_PATH
  Var ADD_TO_PATH_ALL_USERS
  Var ADD_TO_PATH_CURRENT_USER
  Var INSTALL_DESKTOP
  Var IS_DEFAULT_INSTALLDIR
;--------------------------------
;Include Modern UI

  !include "MUI.nsh"

  ;Default installation folder
  InstallDir "C:\EnergyPlusV8-6-0"

;--------------------------------
;General

  ;Name and file
  Name "EnergyPlusV8-6-0"
  OutFile "E:/PersonalProject/EnergyPlus8.6.0/Project/InstallPack/EnergyPlus-8.6.0-3eed2f7901-Windows-x86_64.exe"

  ;Set compression
  SetCompressor lzma

  ;Require administrator access
  RequestExecutionLevel admin

  
    !define MUI_STARTMENUPAGE_DEFAULTFOLDER "EnergyPlusV8-6-0 Programs"
    !include "LogicLib.nsh"
    !include "x64.nsh"
  

  !include Sections.nsh

;--- Component support macros: ---
; The code for the add/remove functionality is from:
;   http://nsis.sourceforge.net/Add/Remove_Functionality
; It has been modified slightly and extended to provide
; inter-component dependencies.
Var AR_SecFlags
Var AR_RegFlags


; Loads the "selected" flag for the section named SecName into the
; variable VarName.
!macro LoadSectionSelectedIntoVar SecName VarName
 SectionGetFlags ${${SecName}} $${VarName}
 IntOp $${VarName} $${VarName} & ${SF_SELECTED}  ;Turn off all other bits
!macroend

; Loads the value of a variable... can we get around this?
!macro LoadVar VarName
  IntOp $R0 0 + $${VarName}
!macroend

; Sets the value of a variable
!macro StoreVar VarName IntValue
  IntOp $${VarName} 0 + ${IntValue}
!macroend

!macro InitSection SecName
  ;  This macro reads component installed flag from the registry and
  ;changes checked state of the section on the components page.
  ;Input: section index constant name specified in Section command.

  ClearErrors
  ;Reading component status from registry
  ReadRegDWORD $AR_RegFlags HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\EnergyPlus 8.6.0-3eed2f7901\Components\${SecName}" "Installed"
  IfErrors "default_${SecName}"
    ;Status will stay default if registry value not found
    ;(component was never installed)
  IntOp $AR_RegFlags $AR_RegFlags & ${SF_SELECTED} ;Turn off all other bits
  SectionGetFlags ${${SecName}} $AR_SecFlags  ;Reading default section flags
  IntOp $AR_SecFlags $AR_SecFlags & 0xFFFE  ;Turn lowest (enabled) bit off
  IntOp $AR_SecFlags $AR_RegFlags | $AR_SecFlags      ;Change lowest bit

  ; Note whether this component was installed before
  !insertmacro StoreVar ${SecName}_was_installed $AR_RegFlags
  IntOp $R0 $AR_RegFlags & $AR_RegFlags

  ;Writing modified flags
  SectionSetFlags ${${SecName}} $AR_SecFlags

 "default_${SecName}:"
 !insertmacro LoadSectionSelectedIntoVar ${SecName} ${SecName}_selected
!macroend

!macro FinishSection SecName
  ;  This macro reads section flag set by user and removes the section
  ;if it is not selected.
  ;Then it writes component installed flag to registry
  ;Input: section index constant name specified in Section command.

  SectionGetFlags ${${SecName}} $AR_SecFlags  ;Reading section flags
  ;Checking lowest bit:
  IntOp $AR_SecFlags $AR_SecFlags & ${SF_SELECTED}
  IntCmp $AR_SecFlags 1 "leave_${SecName}"
    ;Section is not selected:
    ;Calling Section uninstall macro and writing zero installed flag
    !insertmacro "Remove_${${SecName}}"
    WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\EnergyPlus 8.6.0-3eed2f7901\Components\${SecName}" \
  "Installed" 0
    Goto "exit_${SecName}"

 "leave_${SecName}:"
    ;Section is selected:
    WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\EnergyPlus 8.6.0-3eed2f7901\Components\${SecName}" \
  "Installed" 1

 "exit_${SecName}:"
!macroend

!macro RemoveSection_CPack SecName
  ;  This macro is used to call section's Remove_... macro
  ;from the uninstaller.
  ;Input: section index constant name specified in Section command.

  !insertmacro "Remove_${${SecName}}"
!macroend

; Determine whether the selection of SecName changed
!macro MaybeSelectionChanged SecName
  !insertmacro LoadVar ${SecName}_selected
  SectionGetFlags ${${SecName}} $R1
  IntOp $R1 $R1 & ${SF_SELECTED} ;Turn off all other bits

  ; See if the status has changed:
  IntCmp $R0 $R1 "${SecName}_unchanged"
  !insertmacro LoadSectionSelectedIntoVar ${SecName} ${SecName}_selected

  IntCmp $R1 ${SF_SELECTED} "${SecName}_was_selected"
  !insertmacro "Deselect_required_by_${SecName}"
  goto "${SecName}_unchanged"

  "${SecName}_was_selected:"
  !insertmacro "Select_${SecName}_depends"

  "${SecName}_unchanged:"
!macroend
;--- End of Add/Remove macros ---

;--------------------------------
;Interface Settings

  !define MUI_HEADERIMAGE
  !define MUI_ABORTWARNING

;----------------------------------------
; based upon a script of "Written by KiCHiK 2003-01-18 05:57:02"
;----------------------------------------
!verbose 3
!include "WinMessages.NSH"
!verbose 4
;====================================================
; get_NT_environment
;     Returns: the selected environment
;     Output : head of the stack
;====================================================
!macro select_NT_profile UN
Function ${UN}select_NT_profile
   StrCmp $ADD_TO_PATH_ALL_USERS "1" 0 environment_single
      DetailPrint "Selected environment for all users"
      Push "all"
      Return
   environment_single:
      DetailPrint "Selected environment for current user only."
      Push "current"
      Return
FunctionEnd
!macroend
!insertmacro select_NT_profile ""
!insertmacro select_NT_profile "un."
;----------------------------------------------------
!define NT_current_env 'HKCU "Environment"'
!define NT_all_env     'HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment"'

!ifndef WriteEnvStr_RegKey
  !ifdef ALL_USERS
    !define WriteEnvStr_RegKey \
       'HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment"'
  !else
    !define WriteEnvStr_RegKey 'HKCU "Environment"'
  !endif
!endif

; AddToPath - Adds the given dir to the search path.
;        Input - head of the stack
;        Note - Win9x systems requires reboot

Function AddToPath
  Exch $0
  Push $1
  Push $2
  Push $3

  # don't add if the path doesn't exist
  IfFileExists "$0\*.*" "" AddToPath_done

  ReadEnvStr $1 PATH
  ; if the path is too long for a NSIS variable NSIS will return a 0
  ; length string.  If we find that, then warn and skip any path
  ; modification as it will trash the existing path.
  StrLen $2 $1
  IntCmp $2 0 CheckPathLength_ShowPathWarning CheckPathLength_Done CheckPathLength_Done
    CheckPathLength_ShowPathWarning:
    Messagebox MB_OK|MB_ICONEXCLAMATION "Warning! PATH too long installer unable to modify PATH!"
    Goto AddToPath_done
  CheckPathLength_Done:
  Push "$1;"
  Push "$0;"
  Call StrStr
  Pop $2
  StrCmp $2 "" "" AddToPath_done
  Push "$1;"
  Push "$0\;"
  Call StrStr
  Pop $2
  StrCmp $2 "" "" AddToPath_done
  GetFullPathName /SHORT $3 $0
  Push "$1;"
  Push "$3;"
  Call StrStr
  Pop $2
  StrCmp $2 "" "" AddToPath_done
  Push "$1;"
  Push "$3\;"
  Call StrStr
  Pop $2
  StrCmp $2 "" "" AddToPath_done

  Call IsNT
  Pop $1
  StrCmp $1 1 AddToPath_NT
    ; Not on NT
    StrCpy $1 $WINDIR 2
    FileOpen $1 "$1\autoexec.bat" a
    FileSeek $1 -1 END
    FileReadByte $1 $2
    IntCmp $2 26 0 +2 +2 # DOS EOF
      FileSeek $1 -1 END # write over EOF
    FileWrite $1 "$\r$\nSET PATH=%PATH%;$3$\r$\n"
    FileClose $1
    SetRebootFlag true
    Goto AddToPath_done

  AddToPath_NT:
    StrCmp $ADD_TO_PATH_ALL_USERS "1" ReadAllKey
      ReadRegStr $1 ${NT_current_env} "PATH"
      Goto DoTrim
    ReadAllKey:
      ReadRegStr $1 ${NT_all_env} "PATH"
    DoTrim:
    StrCmp $1 "" AddToPath_NTdoIt
      Push $1
      Call Trim
      Pop $1
      StrCpy $0 "$1;$0"
    AddToPath_NTdoIt:
      StrCmp $ADD_TO_PATH_ALL_USERS "1" WriteAllKey
        WriteRegExpandStr ${NT_current_env} "PATH" $0
        Goto DoSend
      WriteAllKey:
        WriteRegExpandStr ${NT_all_env} "PATH" $0
      DoSend:
      SendMessage ${HWND_BROADCAST} ${WM_WININICHANGE} 0 "STR:Environment" /TIMEOUT=5000

  AddToPath_done:
    Pop $3
    Pop $2
    Pop $1
    Pop $0
FunctionEnd


; RemoveFromPath - Remove a given dir from the path
;     Input: head of the stack

Function un.RemoveFromPath
  Exch $0
  Push $1
  Push $2
  Push $3
  Push $4
  Push $5
  Push $6

  IntFmt $6 "%c" 26 # DOS EOF

  Call un.IsNT
  Pop $1
  StrCmp $1 1 unRemoveFromPath_NT
    ; Not on NT
    StrCpy $1 $WINDIR 2
    FileOpen $1 "$1\autoexec.bat" r
    GetTempFileName $4
    FileOpen $2 $4 w
    GetFullPathName /SHORT $0 $0
    StrCpy $0 "SET PATH=%PATH%;$0"
    Goto unRemoveFromPath_dosLoop

    unRemoveFromPath_dosLoop:
      FileRead $1 $3
      StrCpy $5 $3 1 -1 # read last char
      StrCmp $5 $6 0 +2 # if DOS EOF
        StrCpy $3 $3 -1 # remove DOS EOF so we can compare
      StrCmp $3 "$0$\r$\n" unRemoveFromPath_dosLoopRemoveLine
      StrCmp $3 "$0$\n" unRemoveFromPath_dosLoopRemoveLine
      StrCmp $3 "$0" unRemoveFromPath_dosLoopRemoveLine
      StrCmp $3 "" unRemoveFromPath_dosLoopEnd
      FileWrite $2 $3
      Goto unRemoveFromPath_dosLoop
      unRemoveFromPath_dosLoopRemoveLine:
        SetRebootFlag true
        Goto unRemoveFromPath_dosLoop

    unRemoveFromPath_dosLoopEnd:
      FileClose $2
      FileClose $1
      StrCpy $1 $WINDIR 2
      Delete "$1\autoexec.bat"
      CopyFiles /SILENT $4 "$1\autoexec.bat"
      Delete $4
      Goto unRemoveFromPath_done

  unRemoveFromPath_NT:
    StrCmp $ADD_TO_PATH_ALL_USERS "1" unReadAllKey
      ReadRegStr $1 ${NT_current_env} "PATH"
      Goto unDoTrim
    unReadAllKey:
      ReadRegStr $1 ${NT_all_env} "PATH"
    unDoTrim:
    StrCpy $5 $1 1 -1 # copy last char
    StrCmp $5 ";" +2 # if last char != ;
      StrCpy $1 "$1;" # append ;
    Push $1
    Push "$0;"
    Call un.StrStr ; Find `$0;` in $1
    Pop $2 ; pos of our dir
    StrCmp $2 "" unRemoveFromPath_done
      ; else, it is in path
      # $0 - path to add
      # $1 - path var
      StrLen $3 "$0;"
      StrLen $4 $2
      StrCpy $5 $1 -$4 # $5 is now the part before the path to remove
      StrCpy $6 $2 "" $3 # $6 is now the part after the path to remove
      StrCpy $3 $5$6

      StrCpy $5 $3 1 -1 # copy last char
      StrCmp $5 ";" 0 +2 # if last char == ;
        StrCpy $3 $3 -1 # remove last char

      StrCmp $ADD_TO_PATH_ALL_USERS "1" unWriteAllKey
        WriteRegExpandStr ${NT_current_env} "PATH" $3
        Goto unDoSend
      unWriteAllKey:
        WriteRegExpandStr ${NT_all_env} "PATH" $3
      unDoSend:
      SendMessage ${HWND_BROADCAST} ${WM_WININICHANGE} 0 "STR:Environment" /TIMEOUT=5000

  unRemoveFromPath_done:
    Pop $6
    Pop $5
    Pop $4
    Pop $3
    Pop $2
    Pop $1
    Pop $0
FunctionEnd

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
; Uninstall sutff
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

###########################################
#            Utility Functions            #
###########################################

;====================================================
; IsNT - Returns 1 if the current system is NT, 0
;        otherwise.
;     Output: head of the stack
;====================================================
; IsNT
; no input
; output, top of the stack = 1 if NT or 0 if not
;
; Usage:
;   Call IsNT
;   Pop $R0
;  ($R0 at this point is 1 or 0)

!macro IsNT un
Function ${un}IsNT
  Push $0
  ReadRegStr $0 HKLM "SOFTWARE\Microsoft\Windows NT\CurrentVersion" CurrentVersion
  StrCmp $0 "" 0 IsNT_yes
  ; we are not NT.
  Pop $0
  Push 0
  Return

  IsNT_yes:
    ; NT!!!
    Pop $0
    Push 1
FunctionEnd
!macroend
!insertmacro IsNT ""
!insertmacro IsNT "un."

; StrStr
; input, top of stack = string to search for
;        top of stack-1 = string to search in
; output, top of stack (replaces with the portion of the string remaining)
; modifies no other variables.
;
; Usage:
;   Push "this is a long ass string"
;   Push "ass"
;   Call StrStr
;   Pop $R0
;  ($R0 at this point is "ass string")

!macro StrStr un
Function ${un}StrStr
Exch $R1 ; st=haystack,old$R1, $R1=needle
  Exch    ; st=old$R1,haystack
  Exch $R2 ; st=old$R1,old$R2, $R2=haystack
  Push $R3
  Push $R4
  Push $R5
  StrLen $R3 $R1
  StrCpy $R4 0
  ; $R1=needle
  ; $R2=haystack
  ; $R3=len(needle)
  ; $R4=cnt
  ; $R5=tmp
  loop:
    StrCpy $R5 $R2 $R3 $R4
    StrCmp $R5 $R1 done
    StrCmp $R5 "" done
    IntOp $R4 $R4 + 1
    Goto loop
done:
  StrCpy $R1 $R2 "" $R4
  Pop $R5
  Pop $R4
  Pop $R3
  Pop $R2
  Exch $R1
FunctionEnd
!macroend
!insertmacro StrStr ""
!insertmacro StrStr "un."

Function Trim ; Added by Pelaca
	Exch $R1
	Push $R2
Loop:
	StrCpy $R2 "$R1" 1 -1
	StrCmp "$R2" " " RTrim
	StrCmp "$R2" "$\n" RTrim
	StrCmp "$R2" "$\r" RTrim
	StrCmp "$R2" ";" RTrim
	GoTo Done
RTrim:
	StrCpy $R1 "$R1" -1
	Goto Loop
Done:
	Pop $R2
	Exch $R1
FunctionEnd

Function ConditionalAddToRegisty
  Pop $0
  Pop $1
  StrCmp "$0" "" ConditionalAddToRegisty_EmptyString
    WriteRegStr SHCTX "Software\Microsoft\Windows\CurrentVersion\Uninstall\EnergyPlus 8.6.0-3eed2f7901" \
    "$1" "$0"
    ;MessageBox MB_OK "Set Registry: '$1' to '$0'"
    DetailPrint "Set install registry entry: '$1' to '$0'"
  ConditionalAddToRegisty_EmptyString:
FunctionEnd

;--------------------------------

!ifdef CPACK_USES_DOWNLOAD
Function DownloadFile
    IfFileExists $INSTDIR\* +2
    CreateDirectory $INSTDIR
    Pop $0

    ; Skip if already downloaded
    IfFileExists $INSTDIR\$0 0 +2
    Return

    StrCpy $1 ""

  try_again:
    NSISdl::download "$1/$0" "$INSTDIR\$0"

    Pop $1
    StrCmp $1 "success" success
    StrCmp $1 "Cancelled" cancel
    MessageBox MB_OK "Download failed: $1"
  cancel:
    Return
  success:
FunctionEnd
!endif

;--------------------------------
; Installation types


;--------------------------------
; Component sections


;--------------------------------
; Define some macro setting for the gui







;--------------------------------
;Pages
  !insertmacro MUI_PAGE_WELCOME

  !insertmacro MUI_PAGE_LICENSE "E:/PersonalProject/EnergyPlus8.6.0/Project/EnergyPlus/LICENSE.txt"
  Page custom InstallOptionsPage
  !insertmacro MUI_PAGE_DIRECTORY

  ;Start Menu Folder Page Configuration
  !define MUI_STARTMENUPAGE_REGISTRY_ROOT "SHCTX"
  !define MUI_STARTMENUPAGE_REGISTRY_KEY "Software\US Department of Energy\EnergyPlus 8.6.0-3eed2f7901"
  !define MUI_STARTMENUPAGE_REGISTRY_VALUENAME "Start Menu Folder"
  !insertmacro MUI_PAGE_STARTMENU Application $STARTMENU_FOLDER

  
    !define MUI_FINISHPAGE_RUN
    !define MUI_FINISHPAGE_SHOWREADME_NOTCHECKED
    !define MUI_FINISHPAGE_SHOWREADME "$INSTDIR\readme.html"
    !define MUI_FINISHPAGE_RUN_NOTCHECKED
    !define MUI_FINISHPAGE_RUN_TEXT "Associate *.idf, *.imf, and *.epg files with EP-Launch"
    !define MUI_FINISHPAGE_RUN_FUNCTION "AssociateFiles"

    Function AssociateFiles
      WriteRegStr HKCR ".idf" "" "EP-Launch.idf"
      WriteRegStr HKCR "EP-Launch.idf" "" `EnergyPlus Input Data File`
      WriteRegStr HKCR "EP-Launch.idf\shell" "" "open"
      WriteRegStr HKCR "EP-Launch.idf\shell\open" "" `Open with EP-Launch`
      WriteRegStr HKCR "EP-Launch.idf\shell\open\command" "" `$INSTDIR\EP-Launch.exe %1`
      WriteRegStr HKCR ".imf" "" "EP-Launch.imf"
      WriteRegStr HKCR "EP-Launch.imf" "" `EnergyPlus Input Macro File`
      WriteRegStr HKCR "EP-Launch.imf\shell" "" "open"
      WriteRegStr HKCR "EP-Launch.imf\shell\open" "" `Open with EP-Launch`
      WriteRegStr HKCR "EP-Launch.imf\shell\open\command" "" `$INSTDIR\EP-Launch.exe %1`
      WriteRegStr HKCR ".epg" "" "EP-Launch.epg"
      WriteRegStr HKCR "EP-Launch.epg" "" `EnergyPlus Group File`
      WriteRegStr HKCR "EP-Launch.epg\shell" "" "open"
      WriteRegStr HKCR "EP-Launch.epg\shell\open" "" `Open with EP-Launch`
      WriteRegStr HKCR "EP-Launch.epg\shell\open\command" "" `$INSTDIR\EP-Launch.exe %1`
      WriteRegStr HKCR ".ddy" "" "IDFEditor.ddy"
      WriteRegStr HKCR "IDFEditor.ddy" "" `Location and Design Day Data`
      WriteRegStr HKCR "IDFEditor.ddy\shell" "" "open"
      WriteRegStr HKCR "IDFEditor.ddy\shell\open" "" `Open with IDFEditor`
      WriteRegStr HKCR "IDFEditor.ddy\shell\open\command" "" `$INSTDIR\PreProcess\IDFEditor\IDFEditor.exe %1`
      WriteRegStr HKCR ".expidf" "" "IDFEditor.expidf"
      WriteRegStr HKCR "IDFEditor.expidf" "" `EnergyPlus Expand Objects Input Data File`
      WriteRegStr HKCR "IDFEditor.expidf\shell" "" "open"
      WriteRegStr HKCR "IDFEditor.expidf\shell\open" "" `Open with IDFEditor`
      WriteRegStr HKCR "IDFEditor.expidf\shell\open\command" "" `$INSTDIR\PreProcess\IDFEditor\IDFEditor.exe %1`
    FunctionEnd
  

  !insertmacro MUI_PAGE_INSTFILES
  !insertmacro MUI_PAGE_FINISH

  !insertmacro MUI_UNPAGE_CONFIRM
  !insertmacro MUI_UNPAGE_INSTFILES

;--------------------------------
;Languages

  !insertmacro MUI_LANGUAGE "English" ;first language is the default language
  !insertmacro MUI_LANGUAGE "Albanian"
  !insertmacro MUI_LANGUAGE "Arabic"
  !insertmacro MUI_LANGUAGE "Basque"
  !insertmacro MUI_LANGUAGE "Belarusian"
  !insertmacro MUI_LANGUAGE "Bosnian"
  !insertmacro MUI_LANGUAGE "Breton"
  !insertmacro MUI_LANGUAGE "Bulgarian"
  !insertmacro MUI_LANGUAGE "Croatian"
  !insertmacro MUI_LANGUAGE "Czech"
  !insertmacro MUI_LANGUAGE "Danish"
  !insertmacro MUI_LANGUAGE "Dutch"
  !insertmacro MUI_LANGUAGE "Estonian"
  !insertmacro MUI_LANGUAGE "Farsi"
  !insertmacro MUI_LANGUAGE "Finnish"
  !insertmacro MUI_LANGUAGE "French"
  !insertmacro MUI_LANGUAGE "German"
  !insertmacro MUI_LANGUAGE "Greek"
  !insertmacro MUI_LANGUAGE "Hebrew"
  !insertmacro MUI_LANGUAGE "Hungarian"
  !insertmacro MUI_LANGUAGE "Icelandic"
  !insertmacro MUI_LANGUAGE "Indonesian"
  !insertmacro MUI_LANGUAGE "Irish"
  !insertmacro MUI_LANGUAGE "Italian"
  !insertmacro MUI_LANGUAGE "Japanese"
  !insertmacro MUI_LANGUAGE "Korean"
  !insertmacro MUI_LANGUAGE "Kurdish"
  !insertmacro MUI_LANGUAGE "Latvian"
  !insertmacro MUI_LANGUAGE "Lithuanian"
  !insertmacro MUI_LANGUAGE "Luxembourgish"
  !insertmacro MUI_LANGUAGE "Macedonian"
  !insertmacro MUI_LANGUAGE "Malay"
  !insertmacro MUI_LANGUAGE "Mongolian"
  !insertmacro MUI_LANGUAGE "Norwegian"
  !insertmacro MUI_LANGUAGE "Polish"
  !insertmacro MUI_LANGUAGE "Portuguese"
  !insertmacro MUI_LANGUAGE "PortugueseBR"
  !insertmacro MUI_LANGUAGE "Romanian"
  !insertmacro MUI_LANGUAGE "Russian"
  !insertmacro MUI_LANGUAGE "Serbian"
  !insertmacro MUI_LANGUAGE "SerbianLatin"
  !insertmacro MUI_LANGUAGE "SimpChinese"
  !insertmacro MUI_LANGUAGE "Slovak"
  !insertmacro MUI_LANGUAGE "Slovenian"
  !insertmacro MUI_LANGUAGE "Spanish"
  !insertmacro MUI_LANGUAGE "Swedish"
  !insertmacro MUI_LANGUAGE "Thai"
  !insertmacro MUI_LANGUAGE "TradChinese"
  !insertmacro MUI_LANGUAGE "Turkish"
  !insertmacro MUI_LANGUAGE "Ukrainian"
  !insertmacro MUI_LANGUAGE "Welsh"


;--------------------------------
;Reserve Files

  ;These files should be inserted before other files in the data block
  ;Keep these lines before any File command
  ;Only for solid compression (by default, solid compression is enabled for BZIP2 and LZMA)

  ReserveFile "NSIS.InstallOptions.ini"
  !insertmacro MUI_RESERVEFILE_INSTALLOPTIONS

;--------------------------------
;Installer Sections

Section "-Core installation"
  ;Use the entire tree produced by the INSTALL target.  Keep the
  ;list of directories here in sync with the RMDir commands below.
  SetOutPath "$INSTDIR"
  
  File /r "${INST_DIR}\*.*"

  ;Store installation folder
  WriteRegStr SHCTX "Software\US Department of Energy\EnergyPlus 8.6.0-3eed2f7901" "" $INSTDIR

  ;Create uninstaller
  WriteUninstaller "$INSTDIR\Uninstall.exe"
  Push "DisplayName"
  Push "EnergyPlus 8.6.0-3eed2f7901"
  Call ConditionalAddToRegisty
  Push "DisplayVersion"
  Push "8.6.0-3eed2f7901"
  Call ConditionalAddToRegisty
  Push "Publisher"
  Push "US Department of Energy"
  Call ConditionalAddToRegisty
  Push "UninstallString"
  Push "$INSTDIR\Uninstall.exe"
  Call ConditionalAddToRegisty
  Push "NoRepair"
  Push "1"
  Call ConditionalAddToRegisty

  !ifdef CPACK_NSIS_ADD_REMOVE
  ;Create add/remove functionality
  Push "ModifyPath"
  Push "$INSTDIR\AddRemove.exe"
  Call ConditionalAddToRegisty
  !else
  Push "NoModify"
  Push "1"
  Call ConditionalAddToRegisty
  !endif

  ; Optional registration
  Push "DisplayIcon"
  Push "$INSTDIR\"
  Call ConditionalAddToRegisty
  Push "HelpLink"
  Push ""
  Call ConditionalAddToRegisty
  Push "URLInfoAbout"
  Push ""
  Call ConditionalAddToRegisty
  Push "Contact"
  Push ""
  Call ConditionalAddToRegisty
  !insertmacro MUI_INSTALLOPTIONS_READ $INSTALL_DESKTOP "NSIS.InstallOptions.ini" "Field 5" "State"
  !insertmacro MUI_STARTMENU_WRITE_BEGIN Application

  ;Create shortcuts
  CreateDirectory "$SMPROGRAMS\$STARTMENU_FOLDER"
  CreateShortCut "$SMPROGRAMS\$STARTMENU_FOLDER\EnergyPlus Documentation.lnk" "$INSTDIR\Documentation\index.html"
  CreateShortCut "$SMPROGRAMS\$STARTMENU_FOLDER\EP-Compare.lnk" "$INSTDIR\PostProcess\EP-Compare\EP-Compare.exe"
  CreateShortCut "$SMPROGRAMS\$STARTMENU_FOLDER\EPDrawGUI.lnk" "$INSTDIR\PreProcess\EPDraw\EPDrawGUI.exe"
  CreateShortCut "$SMPROGRAMS\$STARTMENU_FOLDER\EP-Launch.lnk" "$INSTDIR\EP-Launch.exe"
  CreateShortCut "$SMPROGRAMS\$STARTMENU_FOLDER\Example Files Summary Spreadsheet.lnk" "$INSTDIR\ExampleFiles\ExampleFiles.xls"
  CreateShortCut "$SMPROGRAMS\$STARTMENU_FOLDER\ExampleFiles Link to Objects.lnk" "$INSTDIR\ExampleFiles\ExampleFiles-ObjectsLink.xls"
  CreateShortCut "$SMPROGRAMS\$STARTMENU_FOLDER\IDFEditor.lnk" "$INSTDIR\PreProcess\IDFEditor\IDFEditor.exe"
  CreateShortCut "$SMPROGRAMS\$STARTMENU_FOLDER\IDFVersionUpdater.lnk" "$INSTDIR\PreProcess\IDFVersionUpdater\IDFVersionUpdater.exe"
  CreateShortCut "$SMPROGRAMS\$STARTMENU_FOLDER\Readme Notes.lnk" "$INSTDIR\readme.html"
  CreateShortCut "$SMPROGRAMS\$STARTMENU_FOLDER\Weather Statistics and Conversions.lnk" "$INSTDIR\PreProcess\WeatherConverter\Weather.exe"


  CreateShortCut "$SMPROGRAMS\$STARTMENU_FOLDER\Uninstall.lnk" "$INSTDIR\Uninstall.exe"

  ;Read a value from an InstallOptions INI file
  !insertmacro MUI_INSTALLOPTIONS_READ $DO_NOT_ADD_TO_PATH "NSIS.InstallOptions.ini" "Field 2" "State"
  !insertmacro MUI_INSTALLOPTIONS_READ $ADD_TO_PATH_ALL_USERS "NSIS.InstallOptions.ini" "Field 3" "State"
  !insertmacro MUI_INSTALLOPTIONS_READ $ADD_TO_PATH_CURRENT_USER "NSIS.InstallOptions.ini" "Field 4" "State"

  ; Write special uninstall registry entries
  Push "StartMenu"
  Push "$STARTMENU_FOLDER"
  Call ConditionalAddToRegisty
  Push "DoNotAddToPath"
  Push "$DO_NOT_ADD_TO_PATH"
  Call ConditionalAddToRegisty
  Push "AddToPathAllUsers"
  Push "$ADD_TO_PATH_ALL_USERS"
  Call ConditionalAddToRegisty
  Push "AddToPathCurrentUser"
  Push "$ADD_TO_PATH_CURRENT_USER"
  Call ConditionalAddToRegisty
  Push "InstallToDesktop"
  Push "$INSTALL_DESKTOP"
  Call ConditionalAddToRegisty

  !insertmacro MUI_STARTMENU_WRITE_END


    WriteRegStr HKEY_CURRENT_USER "Software\VB and VBA Program Settings\EP-Launch\UpdateCheck" "AutoCheck" "True"
    WriteRegStr HKEY_CURRENT_USER "Software\VB and VBA Program Settings\EP-Launch\UpdateCheck" "CheckURL" "http://nrel.github.io/EnergyPlus/epupdate.htm"
    StrCpy $0 "#8.6.0-3eed2f7901"
    WriteRegStr HKEY_CURRENT_USER "Software\VB and VBA Program Settings\EP-Launch\UpdateCheck" "LastAnchor" $0
    ${If} ${RunningX64}
      ${IfNot} ${FileExists} "$WINDIR\SysWOW64\MSCOMCTL.OCX"
        CopyFiles "$INSTDIR\temp\MSCOMCTL.OCX" "$WINDIR\SysWOW64\MSCOMCTL.OCX"
        RegDLL "$WINDIR\SysWOW64\MSCOMCTL.OCX"
      ${EndIf}

      ${IfNot} ${FileExists} "$WINDIR\SysWOW64\ComDlg32.OCX"
        CopyFiles "$INSTDIR\temp\ComDlg32.OCX" "$WINDIR\SysWOW64\ComDlg32.OCX"
        RegDLL "$WINDIR\SysWOW64\ComDlg32.OCX"
      ${EndIf}

      ${IfNot} ${FileExists} "$WINDIR\SysWOW64\Msvcrtd.dll"
      	CopyFiles "$INSTDIR\temp\Msvcrtd.dll" "$WINDIR\SysWOW64\Msvcrtd.dll"
      ${EndIf}

      ${IfNot} ${FileExists} "$WINDIR\SysWOW64\Dforrt.dll"
      	CopyFiles "$INSTDIR\temp\Dforrt.dll" "$WINDIR\SysWOW64\Dforrt.dll"
      ${EndIf}

      ${IfNot} ${FileExists} "$WINDIR\SysWOW64\Gswdll32.dll"
      	CopyFiles "$INSTDIR\temp\Gswdll32.dll" "$WINDIR\SysWOW64\Gswdll32.dll"
      ${EndIf}

      ${IfNot} ${FileExists} "$WINDIR\SysWOW64\Gsw32.exe"
      	CopyFiles "$INSTDIR\temp\Gsw32.exe" "$WINDIR\SysWOW64\Gsw32.exe"
      ${EndIf}

      ${IfNot} ${FileExists} "$WINDIR\SysWOW64\Graph32.ocx"
      	CopyFiles "$INSTDIR\temp\Graph32.ocx" "$WINDIR\SysWOW64\Graph32.ocx"
      	RegDLL "$WINDIR\SysWOW64\Graph32.ocx"
      ${EndIf}

      ${IfNot} ${FileExists} "$WINDIR\SysWOW64\MSINET.OCX"
      	CopyFiles "$INSTDIR\temp\MSINET.OCX" "$WINDIR\SysWOW64\MSINET.OCX"
      	RegDLL "$WINDIR\SysWOW64\MSINET.OCX"
      ${EndIf}

      ${IfNot} ${FileExists} "$WINDIR\SysWOW64\Vsflex7L.ocx"
      	CopyFiles "$INSTDIR\temp\Vsflex7L.ocx" "$WINDIR\SysWOW64\Vsflex7L.ocx"
      	RegDLL "$WINDIR\SysWOW64\Vsflex7L.ocx"
      ${EndIf}

      ${IfNot} ${FileExists} "$WINDIR\SysWOW64\Msflxgrd.ocx"
      	CopyFiles "$INSTDIR\temp\Msflxgrd.ocx" "$WINDIR\SysWOW64\Msflxgrd.ocx"
      	RegDLL "$WINDIR\SysWOW64\Msflxgrd.ocx"
      ${EndIf}
    ${Else}
      ${IfNot} ${FileExists} "$WINDIR\System32\MSCOMCTL.OCX"
        CopyFiles "$INSTDIR\temp\MSCOMCTL.OCX" "$WINDIR\System32\MSCOMCTL.OCX"
        RegDLL "$WINDIR\System32\MSCOMCTL.OCX"
      ${EndIf}

      ${IfNot} ${FileExists} "$WINDIR\System32\ComDlg32.OCX"
        CopyFiles "$INSTDIR\temp\ComDlg32.OCX" "$WINDIR\System32\ComDlg32.OCX"
        RegDLL "$WINDIR\System32\ComDlg32.OCX"
      ${EndIf}

      ${IfNot} ${FileExists} "$WINDIR\System32\Msvcrtd.dll"
      	CopyFiles "$INSTDIR\temp\Msvcrtd.dll" "$WINDIR\System32\Msvcrtd.dll"
      ${EndIf}

      ${IfNot} ${FileExists} "$WINDIR\System32\Dforrt.dll"
      	CopyFiles "$INSTDIR\temp\Dforrt.dll" "$WINDIR\System32\Dforrt.dll"
      ${EndIf}

      ${IfNot} ${FileExists} "$WINDIR\System32\Gswdll32.dll"
      	CopyFiles "$INSTDIR\temp\Gswdll32.dll" "$WINDIR\System32\Gswdll32.dll"
      ${EndIf}

      ${IfNot} ${FileExists} "$WINDIR\System32\Gsw32.exe"
      	CopyFiles "$INSTDIR\temp\Gsw32.exe" "$WINDIR\System32\Gsw32.exe"
      ${EndIf}

      ${IfNot} ${FileExists} "$WINDIR\System32\Graph32.ocx"
      	CopyFiles "$INSTDIR\temp\Graph32.ocx" "$WINDIR\System32\Graph32.ocx"
      	RegDLL "$WINDIR\System32\Graph32.ocx"
      ${EndIf}

      ${IfNot} ${FileExists} "$WINDIR\System32\MSINET.OCX"
      	CopyFiles "$INSTDIR\temp\MSINET.OCX" "$WINDIR\System32\MSINET.OCX"
      	RegDLL "$WINDIR\System32\MSINET.OCX"
      ${EndIf}

      ${IfNot} ${FileExists} "$WINDIR\System32\Vsflex7L.ocx"
      	CopyFiles "$INSTDIR\temp\Vsflex7L.ocx" "$WINDIR\System32\Vsflex7L.ocx"
      	RegDLL "$WINDIR\System32\Vsflex7L.ocx"
      ${EndIf}

      ${IfNot} ${FileExists} "$WINDIR\System32\Msflxgrd.ocx"
      	CopyFiles "$INSTDIR\temp\Msflxgrd.ocx" "$WINDIR\System32\Msflxgrd.ocx"
      	RegDLL "$WINDIR\System32\Msflxgrd.ocx"
      ${EndIf}
    ${EndIf}
    RMDir /r $INSTDIR\temp
  

SectionEnd

Section "-Add to path"
  Push $INSTDIR\bin
  StrCmp "" "ON" 0 doNotAddToPath
  StrCmp $DO_NOT_ADD_TO_PATH "1" doNotAddToPath 0
    Call AddToPath
  doNotAddToPath:
SectionEnd

;--------------------------------
; Create custom pages
Function InstallOptionsPage
  !insertmacro MUI_HEADER_TEXT "Install Options" "Choose options for installing EnergyPlusV8-6-0"
  !insertmacro MUI_INSTALLOPTIONS_DISPLAY "NSIS.InstallOptions.ini"

FunctionEnd

;--------------------------------
; determine admin versus local install
Function un.onInit

  ClearErrors
  UserInfo::GetName
  IfErrors noLM
  Pop $0
  UserInfo::GetAccountType
  Pop $1
  StrCmp $1 "Admin" 0 +3
    SetShellVarContext all
    ;MessageBox MB_OK 'User "$0" is in the Admin group'
    Goto done
  StrCmp $1 "Power" 0 +3
    SetShellVarContext all
    ;MessageBox MB_OK 'User "$0" is in the Power Users group'
    Goto done

  noLM:
    ;Get installation folder from registry if available

  done:

FunctionEnd

;--- Add/Remove callback functions: ---
!macro SectionList MacroName
  ;This macro used to perform operation on multiple sections.
  ;List all of your components in following manner here.

!macroend

Section -FinishComponents
  ;Removes unselected components and writes component status to registry
  !insertmacro SectionList "FinishSection"

!ifdef CPACK_NSIS_ADD_REMOVE
  ; Get the name of the installer executable
  System::Call 'kernel32::GetModuleFileNameA(i 0, t .R0, i 1024) i r1'
  StrCpy $R3 $R0

  ; Strip off the last 13 characters, to see if we have AddRemove.exe
  StrLen $R1 $R0
  IntOp $R1 $R0 - 13
  StrCpy $R2 $R0 13 $R1
  StrCmp $R2 "AddRemove.exe" addremove_installed

  ; We're not running AddRemove.exe, so install it
  CopyFiles $R3 $INSTDIR\AddRemove.exe

  addremove_installed:
!endif
SectionEnd
;--- End of Add/Remove callback functions ---

;--------------------------------
; Component dependencies
Function .onSelChange
  !insertmacro SectionList MaybeSelectionChanged
FunctionEnd

;--------------------------------
;Uninstaller Section

Section "Uninstall"
  ReadRegStr $START_MENU SHCTX \
   "Software\Microsoft\Windows\CurrentVersion\Uninstall\EnergyPlus 8.6.0-3eed2f7901" "StartMenu"
  ;MessageBox MB_OK "Start menu is in: $START_MENU"
  ReadRegStr $DO_NOT_ADD_TO_PATH SHCTX \
    "Software\Microsoft\Windows\CurrentVersion\Uninstall\EnergyPlus 8.6.0-3eed2f7901" "DoNotAddToPath"
  ReadRegStr $ADD_TO_PATH_ALL_USERS SHCTX \
    "Software\Microsoft\Windows\CurrentVersion\Uninstall\EnergyPlus 8.6.0-3eed2f7901" "AddToPathAllUsers"
  ReadRegStr $ADD_TO_PATH_CURRENT_USER SHCTX \
    "Software\Microsoft\Windows\CurrentVersion\Uninstall\EnergyPlus 8.6.0-3eed2f7901" "AddToPathCurrentUser"
  ;MessageBox MB_OK "Add to path: $DO_NOT_ADD_TO_PATH all users: $ADD_TO_PATH_ALL_USERS"
  ReadRegStr $INSTALL_DESKTOP SHCTX \
    "Software\Microsoft\Windows\CurrentVersion\Uninstall\EnergyPlus 8.6.0-3eed2f7901" "InstallToDesktop"
  ;MessageBox MB_OK "Install to desktop: $INSTALL_DESKTOP "


    MessageBox MB_YESNO|MB_ICONEXCLAMATION "The installer copied the following files to the system directory during installation:$\r$\n$\r$\nMSCOMCTL.OCX$\r$\nComDlg32.OCX$\r$\nMsvcrtd.dll$\r$\nDforrt.dll$\r$\nGswdll32.dll$\r$\nGsw32.exe$\r$\nGraph32.ocx$\r$\nMSINET.OCX$\r$\nVsflex7L.ocx$\r$\nMsflxgrd.ocx$\r$\n$\r$\nThese files may be in use by other programs. Click Yes to remove these files. If you are unsure, click No." IDYES true IDNO false
    true:
      ${If} ${RunningX64}
        UnRegDLL "$WINDIR\SysWOW64\MSCOMCTL.OCX"
        UnRegDLL "$WINDIR\SysWOW64\ComDlg32.OCX"
        UnRegDLL "$WINDIR\SysWOW64\Graph32.ocx"
        UnRegDLL "$WINDIR\SysWOW64\MSINET.OCX"
        UnRegDLL "$WINDIR\SysWOW64\Vsflex7L.ocx"
        UnRegDLL "$WINDIR\SysWOW64\Msflxgrd.ocx"
        Delete "$WINDIR\SysWOW64\MSCOMCTL.OCX"
        Delete "$WINDIR\SysWOW64\ComDlg32.OCX"
        Delete "$WINDIR\SysWOW64\Msvcrtd.dll"
        Delete "$WINDIR\SysWOW64\Dforrt.dll"
        Delete "$WINDIR\SysWOW64\Gswdll32.dll"
        Delete "$WINDIR\SysWOW64\Gsw32.exe"
        Delete "$WINDIR\SysWOW64\Graph32.ocx"
        Delete "$WINDIR\SysWOW64\MSINET.OCX"
        Delete "$WINDIR\SysWOW64\Vsflex7L.ocx"
        Delete "$WINDIR\SysWOW64\Msflxgrd.ocx"
      ${Else}
        UnRegDLL "$WINDIR\System32\MSCOMCTL.OCX"
        UnRegDLL "$WINDIR\System32\ComDlg32.OCX"
        UnRegDLL "$WINDIR\System32\Graph32.ocx"
        UnRegDLL "$WINDIR\System32\MSINET.OCX"
        UnRegDLL "$WINDIR\System32\Vsflex7L.ocx"
        UnRegDLL "$WINDIR\System32\Msflxgrd.ocx"
        Delete "$WINDIR\System32\MSCOMCTL.OCX"
        Delete "$WINDIR\System32\ComDlg32.OCX"
        Delete "$WINDIR\System32\Msvcrtd.dll"
        Delete "$WINDIR\System32\Dforrt.dll"
        Delete "$WINDIR\System32\Gswdll32.dll"
        Delete "$WINDIR\System32\Gsw32.exe"
        Delete "$WINDIR\System32\Graph32.ocx"
        Delete "$WINDIR\System32\MSINET.OCX"
        Delete "$WINDIR\System32\Vsflex7L.ocx"
        Delete "$WINDIR\System32\Msflxgrd.ocx"
      ${EndIf}
      Goto next
    false:
      MessageBox MB_OK "Files will not be removed."
    next:
  

  ;Remove files we installed.
  ;Keep the list of directories here in sync with the File commands above.
  Delete "$INSTDIR\Bugreprt.txt"
  Delete "$INSTDIR\changelog.html"
  Delete "$INSTDIR\DataSets"
  Delete "$INSTDIR\DataSets\AirCooledChiller.idf"
  Delete "$INSTDIR\DataSets\ASHRAE_2005_HOF_Materials.idf"
  Delete "$INSTDIR\DataSets\Boilers.idf"
  Delete "$INSTDIR\DataSets\California_Title_24-2008.idf"
  Delete "$INSTDIR\DataSets\Chillers.idf"
  Delete "$INSTDIR\DataSets\CompositeWallConstructions.idf"
  Delete "$INSTDIR\DataSets\DXCoolingCoil.idf"
  Delete "$INSTDIR\DataSets\ElectricGenerators.idf"
  Delete "$INSTDIR\DataSets\ElectricityUSAEnvironmentalImpactFactors.idf"
  Delete "$INSTDIR\DataSets\ElectronicEnthalpyEconomizerCurves.idf"
  Delete "$INSTDIR\DataSets\ExhaustFiredChiller.idf"
  Delete "$INSTDIR\DataSets\FluidPropertiesRefData.idf"
  Delete "$INSTDIR\DataSets\FMUs"
  Delete "$INSTDIR\DataSets\FMUs\MoistAir.fmu"
  Delete "$INSTDIR\DataSets\FMUs\ShadingController.fmu"
  Delete "$INSTDIR\DataSets\FossilFuelEnvironmentalImpactFactors.idf"
  Delete "$INSTDIR\DataSets\GLHERefData.idf"
  Delete "$INSTDIR\DataSets\GlycolPropertiesRefData.idf"
  Delete "$INSTDIR\DataSets\LCCusePriceEscalationDataSet2011.idf"
  Delete "$INSTDIR\DataSets\LCCusePriceEscalationDataSet2012.idf"
  Delete "$INSTDIR\DataSets\LCCusePriceEscalationDataSet2013.idf"
  Delete "$INSTDIR\DataSets\LCCusePriceEscalationDataSet2014.idf"
  Delete "$INSTDIR\DataSets\LCCusePriceEscalationDataSet2015.idf"
  Delete "$INSTDIR\DataSets\MoistureMaterials.idf"
  Delete "$INSTDIR\DataSets\PerfCurves.idf"
  Delete "$INSTDIR\DataSets\PrecipitationSchedulesUSA.idf"
  Delete "$INSTDIR\DataSets\RefrigerationCasesDataSet.idf"
  Delete "$INSTDIR\DataSets\RefrigerationCompressorCurves.idf"
  Delete "$INSTDIR\DataSets\ResidentialACsAndHPsPerfCurves.idf"
  Delete "$INSTDIR\DataSets\RooftopPackagedHeatPump.idf"
  Delete "$INSTDIR\DataSets\SandiaPVdata.idf"
  Delete "$INSTDIR\DataSets\Schedules.idf"
  Delete "$INSTDIR\DataSets\SolarCollectors.idf"
  Delete "$INSTDIR\DataSets\StandardReports.idf"
  Delete "$INSTDIR\DataSets\SurfaceColorSchemes.idf"
  Delete "$INSTDIR\DataSets\TDV"
  Delete "$INSTDIR\DataSets\TDV\TDV_2008_kBtu_CTZ06.csv"
  Delete "$INSTDIR\DataSets\TDV\TDV_read_me.txt"
  Delete "$INSTDIR\DataSets\USHolidays-DST.idf"
  Delete "$INSTDIR\DataSets\Window5DataFile.dat"
  Delete "$INSTDIR\DataSets\WindowBlindMaterials.idf"
  Delete "$INSTDIR\DataSets\WindowConstructs.idf"
  Delete "$INSTDIR\DataSets\WindowGasMaterials.idf"
  Delete "$INSTDIR\DataSets\WindowGlassMaterials.idf"
  Delete "$INSTDIR\DataSets\WindowScreenMaterials.idf"
  Delete "$INSTDIR\DataSets\WindowShadeMaterials.idf"
  Delete "$INSTDIR\Energy+.idd"
  Delete "$INSTDIR\energyplus.exe"
  Delete "$INSTDIR\energyplusapi.dll"
  Delete "$INSTDIR\energyplusapi.lib"
  Delete "$INSTDIR\EP-Launch.exe"
  Delete "$INSTDIR\ep.gif"
  Delete "$INSTDIR\Epl-run.bat"
  Delete "$INSTDIR\EPMacro.exe"
  Delete "$INSTDIR\ExampleFiles"
  Delete "$INSTDIR\ExampleFiles\1ZoneDataCenterCRAC_wPumpedDXCoolingCoil.idf"
  Delete "$INSTDIR\ExampleFiles\1ZoneEvapCooler.idf"
  Delete "$INSTDIR\ExampleFiles\1ZoneParameterAspect.idf"
  Delete "$INSTDIR\ExampleFiles\1ZoneUncontrolled.idf"
  Delete "$INSTDIR\ExampleFiles\1ZoneUncontrolled.rvi"
  Delete "$INSTDIR\ExampleFiles\1ZoneUncontrolled3SurfaceZone.idf"
  Delete "$INSTDIR\ExampleFiles\1ZoneUncontrolledCondFDWithVariableKat24C.idf"
  Delete "$INSTDIR\ExampleFiles\1ZoneUncontrolledCondFDWithVariableKat24C.rvi"
  Delete "$INSTDIR\ExampleFiles\1ZoneUncontrolledFourAlgorithms.idf"
  Delete "$INSTDIR\ExampleFiles\1ZoneUncontrolledResLayers.idf"
  Delete "$INSTDIR\ExampleFiles\1ZoneUncontrolled_DD2009.idf"
  Delete "$INSTDIR\ExampleFiles\1ZoneUncontrolled_DDChanges.idf"
  Delete "$INSTDIR\ExampleFiles\1ZoneUncontrolled_DDChanges.rvi"
  Delete "$INSTDIR\ExampleFiles\1ZoneUncontrolled_FCfactor_Slab_UGWall.idf"
  Delete "$INSTDIR\ExampleFiles\1ZoneUncontrolled_OtherEquipmentWithFuel.idf"
  Delete "$INSTDIR\ExampleFiles\1ZoneUncontrolled_win_1.idf"
  Delete "$INSTDIR\ExampleFiles\1ZoneUncontrolled_win_1.rvi"
  Delete "$INSTDIR\ExampleFiles\1ZoneUncontrolled_win_2.idf"
  Delete "$INSTDIR\ExampleFiles\1ZoneUncontrolled_win_2.rvi"
  Delete "$INSTDIR\ExampleFiles\1ZoneWith14ControlledHeat-CoolPanels.idf"
  Delete "$INSTDIR\ExampleFiles\2ZoneDataCenterHVAC_wEconomizer.idf"
  Delete "$INSTDIR\ExampleFiles\4ZoneWithShading_Simple_1.idf"
  Delete "$INSTDIR\ExampleFiles\4ZoneWithShading_Simple_2.idf"
  Delete "$INSTDIR\ExampleFiles\5ZoneAirCooled.idf"
  Delete "$INSTDIR\ExampleFiles\5ZoneAirCooled.rvi"
  Delete "$INSTDIR\ExampleFiles\5ZoneAirCooledConvCoef.idf"
  Delete "$INSTDIR\ExampleFiles\5ZoneAirCooledConvCoef.rvi"
  Delete "$INSTDIR\ExampleFiles\5ZoneAirCooledConvCoefPIU.idf"
  Delete "$INSTDIR\ExampleFiles\5ZoneAirCooledDemandLimiting.idf"
  Delete "$INSTDIR\ExampleFiles\5ZoneAirCooledDemandLimiting_FixedRateVentilation.idf"
  Delete "$INSTDIR\ExampleFiles\5ZoneAirCooledDemandLimiting_ReductionRatioVentilation.idf"
  Delete "$INSTDIR\ExampleFiles\5ZoneAirCooledWithCoupledInGradeSlab.idf"
  Delete "$INSTDIR\ExampleFiles\5ZoneAirCooledWithSlab.idf"
  Delete "$INSTDIR\ExampleFiles\5ZoneAirCooled_UniformLoading.idf"
  Delete "$INSTDIR\ExampleFiles\5ZoneAirCooled_VRPSizing.idf"
  Delete "$INSTDIR\ExampleFiles\5ZoneAirCooled_VRPSizing_MaxZd.idf"
  Delete "$INSTDIR\ExampleFiles\5ZoneAirCooled_ZoneAirMassFlowBalance.idf"
  Delete "$INSTDIR\ExampleFiles\5ZoneAirCooled_ZoneAirMassFlowBalance_Pressurized.idf"
  Delete "$INSTDIR\ExampleFiles\5ZoneAutoDXVAV.idf"
  Delete "$INSTDIR\ExampleFiles\5ZoneAutoDXVAV.rvi"
  Delete "$INSTDIR\ExampleFiles\5ZoneBoilerOutsideAirReset.idf"
  Delete "$INSTDIR\ExampleFiles\5ZoneBranchSupplyPumps.idf"
  Delete "$INSTDIR\ExampleFiles\5ZoneCAVtoVAVWarmestTempFlow.idf"
  Delete "$INSTDIR\ExampleFiles\5ZoneCAV_MaxTemp.idf"
  Delete "$INSTDIR\ExampleFiles\5ZoneCoolBeam.idf"
  Delete "$INSTDIR\ExampleFiles\5ZoneCoolingPanelBaseboard.idf"
  Delete "$INSTDIR\ExampleFiles\5ZoneCoolingPanelBaseboardAuto.idf"
  Delete "$INSTDIR\ExampleFiles\5ZoneCoolingPanelBaseboardTotalLoad.idf"
  Delete "$INSTDIR\ExampleFiles\5ZoneCoolingPanelBaseboardVarOff.idf"
  Delete "$INSTDIR\ExampleFiles\5ZoneCostEst.idf"
  Delete "$INSTDIR\ExampleFiles\5ZoneDDCycOnAny.idf"
  Delete "$INSTDIR\ExampleFiles\5ZoneDDCycOnAny.rvi"
  Delete "$INSTDIR\ExampleFiles\5ZoneDDCycOnOne.idf"
  Delete "$INSTDIR\ExampleFiles\5ZoneDDCycOnOne.rvi"
  Delete "$INSTDIR\ExampleFiles\5ZoneDesignInputCoolingCoil.idf"
  Delete "$INSTDIR\ExampleFiles\5ZoneDetailedIceStorage.idf"
  Delete "$INSTDIR\ExampleFiles\5ZoneDetailedIceStorage.rvi"
  Delete "$INSTDIR\ExampleFiles\5ZoneDetailedIceStorage2.idf"
  Delete "$INSTDIR\ExampleFiles\5ZoneDetailedIceStorage2.rvi"
  Delete "$INSTDIR\ExampleFiles\5ZoneDetailedIceStorageCubicLinear.idf"
  Delete "$INSTDIR\ExampleFiles\5ZoneDetailedIceStorageCubicLinear.rvi"
  Delete "$INSTDIR\ExampleFiles\5ZoneDetailedIceStorageSimpleCtrl.idf"
  Delete "$INSTDIR\ExampleFiles\5ZoneEconomicsTariffAndLifeCycleCosts.idf"
  Delete "$INSTDIR\ExampleFiles\5ZoneElectricBaseboard.idf"
  Delete "$INSTDIR\ExampleFiles\5ZoneEndUses.idf"
  Delete "$INSTDIR\ExampleFiles\5ZoneEngChill.idf"
  Delete "$INSTDIR\ExampleFiles\5ZoneEngChill.rvi"
  Delete "$INSTDIR\ExampleFiles\5ZoneFanCoilDOASCool.idf"
  Delete "$INSTDIR\ExampleFiles\5ZoneFanCoilDOAS_ERVOnAirLoopMainBranch.idf"
  Delete "$INSTDIR\ExampleFiles\5ZoneFanCoilDOAS_HumidifierOnOASystem.idf"
  Delete "$INSTDIR\ExampleFiles\5ZoneFPIU.idf"
  Delete "$INSTDIR\ExampleFiles\5ZoneGeometryTransform.idf"
  Delete "$INSTDIR\ExampleFiles\5ZoneIceStorage.idf"
  Delete "$INSTDIR\ExampleFiles\5ZoneIceStorage.rvi"
  Delete "$INSTDIR\ExampleFiles\5ZoneNightVent1.idf"
  Delete "$INSTDIR\ExampleFiles\5ZoneNightVent2.idf"
  Delete "$INSTDIR\ExampleFiles\5ZoneNightVent3.idf"
  Delete "$INSTDIR\ExampleFiles\5ZoneReturnFan.idf"
  Delete "$INSTDIR\ExampleFiles\5ZoneReturnFan.rvi"
  Delete "$INSTDIR\ExampleFiles\5ZoneSteamBaseboard.idf"
  Delete "$INSTDIR\ExampleFiles\5ZoneSupRetPlenRAB.idf"
  Delete "$INSTDIR\ExampleFiles\5ZoneSupRetPlenVSATU.idf"
  Delete "$INSTDIR\ExampleFiles\5ZoneSupRetPlenVSATU.rvi"
  Delete "$INSTDIR\ExampleFiles\5ZoneSwimmingPool.idf"
  Delete "$INSTDIR\ExampleFiles\5ZoneTDV.idf"
  Delete "$INSTDIR\ExampleFiles\5ZoneVAV-ChilledWaterStorage-Mixed.idf"
  Delete "$INSTDIR\ExampleFiles\5ZoneVAV-ChilledWaterStorage-Mixed_DCV_MaxZd.idf"
  Delete "$INSTDIR\ExampleFiles\5ZoneVAV-ChilledWaterStorage-Mixed_DCV_MultiPath.idf"
  Delete "$INSTDIR\ExampleFiles\5ZoneVAV-ChilledWaterStorage-Stratified.idf"
  Delete "$INSTDIR\ExampleFiles\5ZoneVAV-Pri-SecLoop.idf"
  Delete "$INSTDIR\ExampleFiles\5ZoneVAV-Pri-SecLoop.mvi"
  Delete "$INSTDIR\ExampleFiles\5ZoneVAV-Pri-SecLoop.rvi"
  Delete "$INSTDIR\ExampleFiles\5ZoneWarmest.idf"
  Delete "$INSTDIR\ExampleFiles\5ZoneWarmest.rvi"
  Delete "$INSTDIR\ExampleFiles\5ZoneWarmestMultDDSizBypass.idf"
  Delete "$INSTDIR\ExampleFiles\5ZoneWarmestMultDDSizOnOff.idf"
  Delete "$INSTDIR\ExampleFiles\5ZoneWarmestMultDDSizVAV.idf"
  Delete "$INSTDIR\ExampleFiles\5ZoneWarmestMultDDSizVT.idf"
  Delete "$INSTDIR\ExampleFiles\5ZoneWarmestVFD.idf"
  Delete "$INSTDIR\ExampleFiles\5ZoneWarmestVFD_FCMAuto.idf"
  Delete "$INSTDIR\ExampleFiles\5ZoneWaterCooled_Baseboard.idf"
  Delete "$INSTDIR\ExampleFiles\5ZoneWaterCooled_BaseboardScalableSizing.idf"
  Delete "$INSTDIR\ExampleFiles\5ZoneWaterCooled_GasFiredSteamHumidifier.idf"
  Delete "$INSTDIR\ExampleFiles\5ZoneWaterCooled_HighRHControl.idf"
  Delete "$INSTDIR\ExampleFiles\5ZoneWaterCooled_HighRHControl.rvi"
  Delete "$INSTDIR\ExampleFiles\5ZoneWaterCooled_MultizoneAverageRHControl.idf"
  Delete "$INSTDIR\ExampleFiles\5ZoneWaterCooled_MultizoneMinMaxRHControl.idf"
  Delete "$INSTDIR\ExampleFiles\5ZoneWaterLoopHeatPump.idf"
  Delete "$INSTDIR\ExampleFiles\5ZoneWaterSystems.idf"
  Delete "$INSTDIR\ExampleFiles\5ZoneWLHPPlantLoopTower.idf"
  Delete "$INSTDIR\ExampleFiles\5Zone_Transformer.idf"
  Delete "$INSTDIR\ExampleFiles\AbsorptionChiller.idf"
  Delete "$INSTDIR\ExampleFiles\AbsorptionChiller.rvi"
  Delete "$INSTDIR\ExampleFiles\AbsorptionChiller_Macro.imf"
  Delete "$INSTDIR\ExampleFiles\ActiveTrombeWall.idf"
  Delete "$INSTDIR\ExampleFiles\ActiveTrombeWall.rvi"
  Delete "$INSTDIR\ExampleFiles\AdvancedOutput"
  Delete "$INSTDIR\ExampleFiles\AdvancedOutput\ExerciseOutput1 Instructions.pdf"
  Delete "$INSTDIR\ExampleFiles\AdvancedOutput\ExerciseOutput1-CustomCSV.bat"
  Delete "$INSTDIR\ExampleFiles\AdvancedOutput\ExerciseOutput1-EquipmentConsumption.rvi"
  Delete "$INSTDIR\ExampleFiles\AdvancedOutput\ExerciseOutput1-ExternalEnvironment.rvi"
  Delete "$INSTDIR\ExampleFiles\AdvancedOutput\ExerciseOutput1.idf"
  Delete "$INSTDIR\ExampleFiles\AdvancedOutput\ExerciseOutput1A-Loads-Solution.rvi"
  Delete "$INSTDIR\ExampleFiles\AdvancedOutput\ExerciseOutput1A-Solution.idf"
  Delete "$INSTDIR\ExampleFiles\AdvancedOutput\ExerciseOutput1B-EnergyEndUse-Solution.mvi"
  Delete "$INSTDIR\ExampleFiles\AirCooledElectricChiller.idf"
  Delete "$INSTDIR\ExampleFiles\AirCooledElectricChiller.rvi"
  Delete "$INSTDIR\ExampleFiles\AirEconomizerFaults_RefBldgLargeOfficeNew2004_Chicago.idf"
  Delete "$INSTDIR\ExampleFiles\AirEconomizerWithMaxMinOAFractions.idf"
  Delete "$INSTDIR\ExampleFiles\AirflowNetwork3zVent.idf"
  Delete "$INSTDIR\ExampleFiles\AirflowNetwork3zVent.rvi"
  Delete "$INSTDIR\ExampleFiles\AirflowNetwork3zVentAutoWPC.idf"
  Delete "$INSTDIR\ExampleFiles\AirflowNetworkOccupantVentilationControl.idf"
  Delete "$INSTDIR\ExampleFiles\AirflowNetwork_Multizone_HorizontalOpening.idf"
  Delete "$INSTDIR\ExampleFiles\AirflowNetwork_MultiZone_House.idf"
  Delete "$INSTDIR\ExampleFiles\AirflowNetwork_MultiZone_House_OvercoolDehumid.idf"
  Delete "$INSTDIR\ExampleFiles\AirflowNetwork_MultiZone_House_TwoSpeed.idf"
  Delete "$INSTDIR\ExampleFiles\AirflowNetwork_MultiZone_SmallOffice.idf"
  Delete "$INSTDIR\ExampleFiles\AirflowNetwork_MultiZone_SmallOffice_CoilHXAssistedDX.idf"
  Delete "$INSTDIR\ExampleFiles\AirflowNetwork_MultiZone_SmallOffice_GenericContam.idf"
  Delete "$INSTDIR\ExampleFiles\AirflowNetwork_MultiZone_SmallOffice_HeatRecoveryHXSL.idf"
  Delete "$INSTDIR\ExampleFiles\AirflowNetwork_MultiZone_SmallOffice_VAV.idf"
  Delete "$INSTDIR\ExampleFiles\AirflowNetwork_PressureControl.idf"
  Delete "$INSTDIR\ExampleFiles\AirflowNetwork_Simple_House.idf"
  Delete "$INSTDIR\ExampleFiles\AirflowNetwork_Simple_House.rvi"
  Delete "$INSTDIR\ExampleFiles\AirflowNetwork_Simple_SmallOffice.idf"
  Delete "$INSTDIR\ExampleFiles\AirflowNetwork_Simple_SmallOffice.rvi"
  Delete "$INSTDIR\ExampleFiles\AirflowWindowsAndBetweenGlassBlinds.idf"
  Delete "$INSTDIR\ExampleFiles\AirflowWindowsAndBetweenGlassShades.idf"
  Delete "$INSTDIR\ExampleFiles\ASIHPMixedTank.idf"
  Delete "$INSTDIR\ExampleFiles\BaseBoardElectric.idf"
  Delete "$INSTDIR\ExampleFiles\BasicsFiles"
  Delete "$INSTDIR\ExampleFiles\BasicsFiles\AdultEducationCenter.idf"
  Delete "$INSTDIR\ExampleFiles\BasicsFiles\Exercise1A.idf"
  Delete "$INSTDIR\ExampleFiles\BasicsFiles\Exercise1B-Solution.idf"
  Delete "$INSTDIR\ExampleFiles\BasicsFiles\Exercise1C-Solution.idf"
  Delete "$INSTDIR\ExampleFiles\BasicsFiles\Exercise1D-Solution.idf"
  Delete "$INSTDIR\ExampleFiles\BasicsFiles\Exercise2.idf"
  Delete "$INSTDIR\ExampleFiles\BasicsFiles\Exercise2A-Solution.idf"
  Delete "$INSTDIR\ExampleFiles\BasicsFiles\Exercise2B-Solution.idf"
  Delete "$INSTDIR\ExampleFiles\BasicsFiles\Exercise2C-Solution.idf"
  Delete "$INSTDIR\ExampleFiles\CentralChillerHeaterSystem_Cooling_Heating.idf"
  Delete "$INSTDIR\ExampleFiles\CentralChillerHeaterSystem_Simultaneous_Cooling_Heating.idf"
  Delete "$INSTDIR\ExampleFiles\ChangeoverBypassVAV.idf"
  Delete "$INSTDIR\ExampleFiles\ChangeoverBypassVAV_MaxTemp.idf"
  Delete "$INSTDIR\ExampleFiles\ChillerPartLoadCurve_RefBldgLargeOfficeNew2004_Chicago.idf"
  Delete "$INSTDIR\ExampleFiles\CmplxGlz_Daylighting_SouthVB45deg.idf"
  Delete "$INSTDIR\ExampleFiles\CmplxGlz_MeasuredDeflectionAndShading.idf"
  Delete "$INSTDIR\ExampleFiles\CmplxGlz_SchedSurfGains.idf"
  Delete "$INSTDIR\ExampleFiles\CmplxGlz_SingleZone_Deflection.idf"
  Delete "$INSTDIR\ExampleFiles\CmplxGlz_SingleZone_DoubleClearAir.idf"
  Delete "$INSTDIR\ExampleFiles\CmplxGlz_SingleZone_Vacuum.idf"
  Delete "$INSTDIR\ExampleFiles\CmplxGlz_SmOff_IntExtShading.idf"
  Delete "$INSTDIR\ExampleFiles\CoilWaterDesuperheating.idf"
  Delete "$INSTDIR\ExampleFiles\CommonPipe_Pri-Sec.idf"
  Delete "$INSTDIR\ExampleFiles\CompSetPtControl.idf"
  Delete "$INSTDIR\ExampleFiles\CondFD1ZonePurchAirAutoSizeWithPCM.idf"
  Delete "$INSTDIR\ExampleFiles\CondFD1ZonePurchAirAutoSizeWithPCM.rvi"
  Delete "$INSTDIR\ExampleFiles\Convection.idf"
  Delete "$INSTDIR\ExampleFiles\ConvectionAdaptiveSmallOffice.idf"
  Delete "$INSTDIR\ExampleFiles\CoolingCoilFreezingPrevention.idf"
  Delete "$INSTDIR\ExampleFiles\CoolingTower.idf"
  Delete "$INSTDIR\ExampleFiles\CoolingTower.rvi"
  Delete "$INSTDIR\ExampleFiles\CoolingTowerDryBulbRangeOp.idf"
  Delete "$INSTDIR\ExampleFiles\CoolingTowerDryBulbRangeOp.rvi"
  Delete "$INSTDIR\ExampleFiles\CoolingTowerNomCap.idf"
  Delete "$INSTDIR\ExampleFiles\CoolingTowerNomCap.rvi"
  Delete "$INSTDIR\ExampleFiles\CoolingTowerRHRangeOp.idf"
  Delete "$INSTDIR\ExampleFiles\CoolingTowerRHRangeOp.rvi"
  Delete "$INSTDIR\ExampleFiles\CoolingTowerWetBulbRangeOp.idf"
  Delete "$INSTDIR\ExampleFiles\CoolingTowerWetBulbRangeOp.rvi"
  Delete "$INSTDIR\ExampleFiles\CoolingTowerWithDBDeltaTempOp.idf"
  Delete "$INSTDIR\ExampleFiles\CoolingTowerWithDBDeltaTempOp.rvi"
  Delete "$INSTDIR\ExampleFiles\CoolingTowerWithWBDeltaTempOp.idf"
  Delete "$INSTDIR\ExampleFiles\CoolingTower_FluidBypass.idf"
  Delete "$INSTDIR\ExampleFiles\CoolingTower_FluidBypass.rvi"
  Delete "$INSTDIR\ExampleFiles\CoolingTower_MerkelVariableSpeed.idf"
  Delete "$INSTDIR\ExampleFiles\CoolingTower_SingleSpeed_MultiCell.idf"
  Delete "$INSTDIR\ExampleFiles\CoolingTower_TwoSpeed.idf"
  Delete "$INSTDIR\ExampleFiles\CoolingTower_TwoSpeed.rvi"
  Delete "$INSTDIR\ExampleFiles\CoolingTower_TwoSpeed_CondEntTempReset.idf"
  Delete "$INSTDIR\ExampleFiles\CoolingTower_TwoSpeed_MultiCell.idf"
  Delete "$INSTDIR\ExampleFiles\CoolingTower_VariableSpeed.idf"
  Delete "$INSTDIR\ExampleFiles\CoolingTower_VariableSpeed_CondEntTempReset.idf"
  Delete "$INSTDIR\ExampleFiles\CoolingTower_VariableSpeed_CondEntTempReset_MultipleTowers.idf"
  Delete "$INSTDIR\ExampleFiles\CoolingTower_VariableSpeed_IdealCondEntTempSetpoint.idf"
  Delete "$INSTDIR\ExampleFiles\CoolingTower_VariableSpeed_IdealCondEntTempSetpoint_MultipleTowers.idf"
  Delete "$INSTDIR\ExampleFiles\CoolingTower_VariableSpeed_MultiCell.idf"
  Delete "$INSTDIR\ExampleFiles\CooltowerSimpleTest.idf"
  Delete "$INSTDIR\ExampleFiles\CooltowerSimpleTestwithVentilation.idf"
  Delete "$INSTDIR\ExampleFiles\CrossVent_1Zone_AirflowNetwork.idf"
  Delete "$INSTDIR\ExampleFiles\CrossVent_1Zone_AirflowNetwork_with2CrossflowJets.idf"
  Delete "$INSTDIR\ExampleFiles\CustomSolarVisibleSpectrum_RefBldgSmallOfficeNew2004_Chicago.idf"
  Delete "$INSTDIR\ExampleFiles\CVRhMinHum.idf"
  Delete "$INSTDIR\ExampleFiles\CVRhMinHum.rvi"
  Delete "$INSTDIR\ExampleFiles\DaylightingDeviceShelf.idf"
  Delete "$INSTDIR\ExampleFiles\DaylightingDeviceShelf.rvi"
  Delete "$INSTDIR\ExampleFiles\DaylightingDeviceTubular.idf"
  Delete "$INSTDIR\ExampleFiles\DaylightingDeviceTubular.rvi"
  Delete "$INSTDIR\ExampleFiles\DDAutoSize.idf"
  Delete "$INSTDIR\ExampleFiles\DDAutoSize.rvi"
  Delete "$INSTDIR\ExampleFiles\defaultall.rvi"
  Delete "$INSTDIR\ExampleFiles\DElight-Detailed-Comparison.idf"
  Delete "$INSTDIR\ExampleFiles\DElightCFSLightShelf.idf"
  Delete "$INSTDIR\ExampleFiles\DElightCFSWindow.idf"
  Delete "$INSTDIR\ExampleFiles\DesiccantCVRh.idf"
  Delete "$INSTDIR\ExampleFiles\DesiccantCVRh.rvi"
  Delete "$INSTDIR\ExampleFiles\DesiccantCVRhZoneRHCtrl.idf"
  Delete "$INSTDIR\ExampleFiles\DesiccantCVRhZoneRHCtrl.rvi"
  Delete "$INSTDIR\ExampleFiles\DesiccantCVRhZoneRHCtrl_AddedAutosize.idf"
  Delete "$INSTDIR\ExampleFiles\DesiccantDehumidifierWithCompanionCoil.idf"
  Delete "$INSTDIR\ExampleFiles\DirectIndirectEvapCoolers.idf"
  Delete "$INSTDIR\ExampleFiles\DirectIndirectEvapCoolersVSAS.idf"
  Delete "$INSTDIR\ExampleFiles\DisplacementVent_1ZoneOffice.idf"
  Delete "$INSTDIR\ExampleFiles\DisplacementVent_Nat_AirflowNetwork.idf"
  Delete "$INSTDIR\ExampleFiles\DisplacementVent_Nat_AirflowNetwork_AdaptiveComfort.idf"
  Delete "$INSTDIR\ExampleFiles\DisplacementVent_VAV.idf"
  Delete "$INSTDIR\ExampleFiles\DOASDualDuctSchool.idf"
  Delete "$INSTDIR\ExampleFiles\DOASDXCOIL_wADPBFMethod.idf"
  Delete "$INSTDIR\ExampleFiles\DOASDXCOIL_wADPBFMethod.rvi"
  Delete "$INSTDIR\ExampleFiles\DOAToFanCoilInlet.idf"
  Delete "$INSTDIR\ExampleFiles\DOAToFanCoilSupply.idf"
  Delete "$INSTDIR\ExampleFiles\DOAToPTAC.idf"
  Delete "$INSTDIR\ExampleFiles\DOAToPTHP.idf"
  Delete "$INSTDIR\ExampleFiles\DOAToUnitarySystem.idf"
  Delete "$INSTDIR\ExampleFiles\DOAToVRF.idf"
  Delete "$INSTDIR\ExampleFiles\DOAToWaterToAirHPInlet.idf"
  Delete "$INSTDIR\ExampleFiles\DOAToWaterToAirHPSupply.idf"
  Delete "$INSTDIR\ExampleFiles\DualDuctConstVolDamper.idf"
  Delete "$INSTDIR\ExampleFiles\DualDuctConstVolDamper.rvi"
  Delete "$INSTDIR\ExampleFiles\DualDuctConstVolGasHC.idf"
  Delete "$INSTDIR\ExampleFiles\DualDuctConstVolGasHC.rvi"
  Delete "$INSTDIR\ExampleFiles\DualDuctVarVolDamper.idf"
  Delete "$INSTDIR\ExampleFiles\DualDuctVarVolDamper.rvi"
  Delete "$INSTDIR\ExampleFiles\DualDuctWaterCoils.idf"
  Delete "$INSTDIR\ExampleFiles\DualDuctWaterCoils.rvi"
  Delete "$INSTDIR\ExampleFiles\DXCoilSystemAuto.idf"
  Delete "$INSTDIR\ExampleFiles\DynamicClothing.idf"
  Delete "$INSTDIR\ExampleFiles\EarthTubeSimpleTest.idf"
  Delete "$INSTDIR\ExampleFiles\EarthTubeSimpleTest.rvi"
  Delete "$INSTDIR\ExampleFiles\EcoroofOrlando.idf"
  Delete "$INSTDIR\ExampleFiles\ElectricChiller.idf"
  Delete "$INSTDIR\ExampleFiles\ElectricChiller.rvi"
  Delete "$INSTDIR\ExampleFiles\ElectricEIRChiller.idf"
  Delete "$INSTDIR\ExampleFiles\emall.list"
  Delete "$INSTDIR\ExampleFiles\EMPD5ZoneWaterCooled_HighRHControl.idf"
  Delete "$INSTDIR\ExampleFiles\EMSAirflowNetworkOpeningControlByHumidity.idf"
  Delete "$INSTDIR\ExampleFiles\EMSConstantVolumePurchasedAir.idf"
  Delete "$INSTDIR\ExampleFiles\EMSCurveOverride_PackagedTerminalHeatPump.idf"
  Delete "$INSTDIR\ExampleFiles\EMSCustomOutputVariable.idf"
  Delete "$INSTDIR\ExampleFiles\EMSCustomSchedule.idf"
  Delete "$INSTDIR\ExampleFiles\EMSDemandManager_LargeOffice.idf"
  Delete "$INSTDIR\ExampleFiles\EMSDiscreteAirSystemSizes.idf"
  Delete "$INSTDIR\ExampleFiles\EMSPlantLoopOverrideControl.idf"
  Delete "$INSTDIR\ExampleFiles\EMSPlantOperation_largeOff.idf"
  Delete "$INSTDIR\ExampleFiles\EMSReplaceTraditionalManagers_LargeOffice.idf"
  Delete "$INSTDIR\ExampleFiles\EMSTestMathAndKill.idf"
  Delete "$INSTDIR\ExampleFiles\EMSThermochromicWindow.idf"
  Delete "$INSTDIR\ExampleFiles\EMSUserDefined5ZoneAirCooled.idf"
  Delete "$INSTDIR\ExampleFiles\EMSUserDefinedWindACAuto.idf"
  Delete "$INSTDIR\ExampleFiles\EMSWindowShadeControl.idf"
  Delete "$INSTDIR\ExampleFiles\EngineChiller.idf"
  Delete "$INSTDIR\ExampleFiles\EngineChiller.rvi"
  Delete "$INSTDIR\ExampleFiles\EquivalentLayerWindow.idf"
  Delete "$INSTDIR\ExampleFiles\EvaporativeFluidCooler.idf"
  Delete "$INSTDIR\ExampleFiles\EvaporativeFluidCooler.rvi"
  Delete "$INSTDIR\ExampleFiles\EvaporativeFluidCooler_TwoSpeed.idf"
  Delete "$INSTDIR\ExampleFiles\ExampleFiles-ObjectsLink.html"
  Delete "$INSTDIR\ExampleFiles\ExampleFiles.html"
  Delete "$INSTDIR\ExampleFiles\ExhFiredAbsorptionChiller.idf"
  Delete "$INSTDIR\ExampleFiles\ExteriorLightsAndEq.idf"
  Delete "$INSTDIR\ExampleFiles\FanCoilAutoSize.idf"
  Delete "$INSTDIR\ExampleFiles\FanCoilAutoSize.rvi"
  Delete "$INSTDIR\ExampleFiles\FanCoilAutoSizeScalableSizing.idf"
  Delete "$INSTDIR\ExampleFiles\FanCoilAutoSize_MultiSpeedFan.idf"
  Delete "$INSTDIR\ExampleFiles\FanCoil_HybridVent_VentSch.idf"
  Delete "$INSTDIR\ExampleFiles\Fault_FoulingAirFilter_RefBldgMediumOfficeNew2004.idf"
  Delete "$INSTDIR\ExampleFiles\Fault_HumidistatOffset_Supermarket.idf"
  Delete "$INSTDIR\ExampleFiles\Fault_HumidistatOffset_ThermostatOffset_Supermarket.idf"
  Delete "$INSTDIR\ExampleFiles\Fault_ThermostatOffset_RefBldgMediumOfficeNew2004.idf"
  Delete "$INSTDIR\ExampleFiles\Flr_Rf_8Sides.idf"
  Delete "$INSTDIR\ExampleFiles\FluidCooler.idf"
  Delete "$INSTDIR\ExampleFiles\FluidCooler.rvi"
  Delete "$INSTDIR\ExampleFiles\FluidCoolerTwoSpeed.idf"
  Delete "$INSTDIR\ExampleFiles\FourPipeBeamLargeOffice.idf"
  Delete "$INSTDIR\ExampleFiles\FreeCoolingChiller.idf"
  Delete "$INSTDIR\ExampleFiles\Furnace.idf"
  Delete "$INSTDIR\ExampleFiles\Furnace.rvi"
  Delete "$INSTDIR\ExampleFiles\FurnaceFuelOil.idf"
  Delete "$INSTDIR\ExampleFiles\FurnacePLRHeatingCoil.idf"
  Delete "$INSTDIR\ExampleFiles\FurnaceWithDXSystem.idf"
  Delete "$INSTDIR\ExampleFiles\FurnaceWithDXSystem.rvi"
  Delete "$INSTDIR\ExampleFiles\FurnaceWithDXSystemComfortControl.idf"
  Delete "$INSTDIR\ExampleFiles\FurnaceWithDXSystemRHcontrol.idf"
  Delete "$INSTDIR\ExampleFiles\FurnaceWithDXSystemRHcontrol_cyclingfan.idf"
  Delete "$INSTDIR\ExampleFiles\FurnaceWithDXSystem_CoolingHXAssisted.idf"
  Delete "$INSTDIR\ExampleFiles\FurnaceWithDXSystem_CoolingHXAssisted.rvi"
  Delete "$INSTDIR\ExampleFiles\gasAbsorptionChillerHeater.idf"
  Delete "$INSTDIR\ExampleFiles\GasTurbChiller.idf"
  Delete "$INSTDIR\ExampleFiles\GasTurbChiller.rvi"
  Delete "$INSTDIR\ExampleFiles\Generators.idf"
  Delete "$INSTDIR\ExampleFiles\Generators.rvi"
  Delete "$INSTDIR\ExampleFiles\GeneratorswithPV.idf"
  Delete "$INSTDIR\ExampleFiles\Generators_Transformer.idf"
  Delete "$INSTDIR\ExampleFiles\GeneratorwithWindTurbine.idf"
  Delete "$INSTDIR\ExampleFiles\GeometryTest.idf"
  Delete "$INSTDIR\ExampleFiles\GeometryTest.rvi"
  Delete "$INSTDIR\ExampleFiles\GroundTempOSCCompactSched.idf"
  Delete "$INSTDIR\ExampleFiles\GSHP-GLHE.idf"
  Delete "$INSTDIR\ExampleFiles\GSHP-GLHE.rvi"
  Delete "$INSTDIR\ExampleFiles\GSHP-Slinky.idf"
  Delete "$INSTDIR\ExampleFiles\GSHPSimple-GLHE.idf"
  Delete "$INSTDIR\ExampleFiles\GSHPSimple-GLHE.rvi"
  Delete "$INSTDIR\ExampleFiles\HAMT_DailyProfileReport.idf"
  Delete "$INSTDIR\ExampleFiles\HAMT_HourlyProfileReport.idf"
  Delete "$INSTDIR\ExampleFiles\HeaderedPumpsConSpeed.idf"
  Delete "$INSTDIR\ExampleFiles\HeaderedPumpsVarSpeed.idf"
  Delete "$INSTDIR\ExampleFiles\HeatPump.idf"
  Delete "$INSTDIR\ExampleFiles\HeatPump.rvi"
  Delete "$INSTDIR\ExampleFiles\HeatPumpAirToAirWithRHcontrol.idf"
  Delete "$INSTDIR\ExampleFiles\HeatPumpAuto.idf"
  Delete "$INSTDIR\ExampleFiles\HeatPumpAuto.rvi"
  Delete "$INSTDIR\ExampleFiles\HeatPumpCycFanWithEcono.idf"
  Delete "$INSTDIR\ExampleFiles\HeatPumpCycFanWithEcono.rvi"
  Delete "$INSTDIR\ExampleFiles\HeatPumpIAQP_DCV.idf"
  Delete "$INSTDIR\ExampleFiles\HeatPumpIAQP_GenericContamControl.idf"
  Delete "$INSTDIR\ExampleFiles\HeatPumpProportionalControl_DCV.idf"
  Delete "$INSTDIR\ExampleFiles\HeatPumpSecondaryCoil.idf"
  Delete "$INSTDIR\ExampleFiles\HeatPumpSimpleDCV.idf"
  Delete "$INSTDIR\ExampleFiles\HeatPumpSimpleDCV.rvi"
  Delete "$INSTDIR\ExampleFiles\HeatPumpVRP_DCV.idf"
  Delete "$INSTDIR\ExampleFiles\HeatPumpVSAS.idf"
  Delete "$INSTDIR\ExampleFiles\HeatPumpWaterHeater.idf"
  Delete "$INSTDIR\ExampleFiles\HeatPumpWaterHeater.rvi"
  Delete "$INSTDIR\ExampleFiles\HeatPumpWaterHeaterStratified.idf"
  Delete "$INSTDIR\ExampleFiles\HeatPumpWaterHeaterStratified.rvi"
  Delete "$INSTDIR\ExampleFiles\HeatPumpWaterToAir.idf"
  Delete "$INSTDIR\ExampleFiles\HeatPumpWaterToAirEquationFit.idf"
  Delete "$INSTDIR\ExampleFiles\HeatPumpWaterToAirWithAntifreezeAndLatentModel.idf"
  Delete "$INSTDIR\ExampleFiles\HeatPumpWaterToAirWithAntifreezeAndLatentModel2.idf"
  Delete "$INSTDIR\ExampleFiles\HeatPumpWaterToAirWithRHControl.idf"
  Delete "$INSTDIR\ExampleFiles\HeatPumpwithBiquadraticCurves.idf"
  Delete "$INSTDIR\ExampleFiles\HeatRecoveryElectricChiller.idf"
  Delete "$INSTDIR\ExampleFiles\HeatRecoveryPlantLoop.idf"
  Delete "$INSTDIR\ExampleFiles\HeatRecoverywithStorageTank.idf"
  Delete "$INSTDIR\ExampleFiles\HospitalBaseline.idf"
  Delete "$INSTDIR\ExampleFiles\HospitalBaselineReheatReportEMS.idf"
  Delete "$INSTDIR\ExampleFiles\HospitalLowEnergy.idf"
  Delete "$INSTDIR\ExampleFiles\HPAirToAir_wSolarCollectorHWCoil.idf"
  Delete "$INSTDIR\ExampleFiles\HP_wICSSolarCollector.idf"
  Delete "$INSTDIR\ExampleFiles\HVAC3Zone-IntGains-Def.imf"
  Delete "$INSTDIR\ExampleFiles\HVAC3ZoneChillerSpec.imf"
  Delete "$INSTDIR\ExampleFiles\HVAC3ZoneGeometry.imf"
  Delete "$INSTDIR\ExampleFiles\HVAC3ZoneMat-Const.imf"
  Delete "$INSTDIR\ExampleFiles\HVACStandAloneERV_Economizer.idf"
  Delete "$INSTDIR\ExampleFiles\HVACStandAloneERV_Economizer.rvi"
  Delete "$INSTDIR\ExampleFiles\HVACTemplate-5ZoneBaseboardHeat.idf"
  Delete "$INSTDIR\ExampleFiles\HVACTemplate-5ZoneBaseboardHeat.mvi"
  Delete "$INSTDIR\ExampleFiles\HVACTemplate-5ZoneBaseboardHeat.rvi"
  Delete "$INSTDIR\ExampleFiles\HVACTemplate-5ZoneConstantVolumeChillerBoiler.idf"
  Delete "$INSTDIR\ExampleFiles\HVACTemplate-5ZoneConstantVolumeChillerBoiler.mvi"
  Delete "$INSTDIR\ExampleFiles\HVACTemplate-5ZoneConstantVolumeChillerBoiler.rvi"
  Delete "$INSTDIR\ExampleFiles\HVACTemplate-5ZoneDualDuct.idf"
  Delete "$INSTDIR\ExampleFiles\HVACTemplate-5ZoneDualDuct.mvi"
  Delete "$INSTDIR\ExampleFiles\HVACTemplate-5ZoneDualDuct.rvi"
  Delete "$INSTDIR\ExampleFiles\HVACTemplate-5ZoneFanCoil-DOAS.idf"
  Delete "$INSTDIR\ExampleFiles\HVACTemplate-5ZoneFanCoil.idf"
  Delete "$INSTDIR\ExampleFiles\HVACTemplate-5ZoneFanCoil.mvi"
  Delete "$INSTDIR\ExampleFiles\HVACTemplate-5ZoneFanCoil.rvi"
  Delete "$INSTDIR\ExampleFiles\HVACTemplate-5ZoneFurnaceDX.idf"
  Delete "$INSTDIR\ExampleFiles\HVACTemplate-5ZoneFurnaceDX.mvi"
  Delete "$INSTDIR\ExampleFiles\HVACTemplate-5ZoneFurnaceDX.rvi"
  Delete "$INSTDIR\ExampleFiles\HVACTemplate-5ZonePackagedVAV.idf"
  Delete "$INSTDIR\ExampleFiles\HVACTemplate-5ZonePTAC-DOAS.idf"
  Delete "$INSTDIR\ExampleFiles\HVACTemplate-5ZonePTAC.idf"
  Delete "$INSTDIR\ExampleFiles\HVACTemplate-5ZonePTHP.idf"
  Delete "$INSTDIR\ExampleFiles\HVACTemplate-5ZonePurchAir.idf"
  Delete "$INSTDIR\ExampleFiles\HVACTemplate-5ZonePurchAir.mvi"
  Delete "$INSTDIR\ExampleFiles\HVACTemplate-5ZonePurchAir.rvi"
  Delete "$INSTDIR\ExampleFiles\HVACTemplate-5ZoneUnitaryHeatPump.idf"
  Delete "$INSTDIR\ExampleFiles\HVACTemplate-5ZoneUnitarySystem.idf"
  Delete "$INSTDIR\ExampleFiles\HVACTemplate-5ZoneUnitarySystem.mvi"
  Delete "$INSTDIR\ExampleFiles\HVACTemplate-5ZoneUnitarySystem.rvi"
  Delete "$INSTDIR\ExampleFiles\HVACTemplate-5ZoneVAVFanPowered.idf"
  Delete "$INSTDIR\ExampleFiles\HVACTemplate-5ZoneVAVFanPowered.mvi"
  Delete "$INSTDIR\ExampleFiles\HVACTemplate-5ZoneVAVFanPowered.rvi"
  Delete "$INSTDIR\ExampleFiles\HVACTemplate-5ZoneVAVWaterCooled-ObjectReference.idf"
  Delete "$INSTDIR\ExampleFiles\HVACTemplate-5ZoneVAVWaterCooled-ObjectReference.mvi"
  Delete "$INSTDIR\ExampleFiles\HVACTemplate-5ZoneVAVWaterCooled-ObjectReference.rvi"
  Delete "$INSTDIR\ExampleFiles\HVACTemplate-5ZoneVAVWaterCooled.idf"
  Delete "$INSTDIR\ExampleFiles\HVACTemplate-5ZoneVAVWaterCooled.mvi"
  Delete "$INSTDIR\ExampleFiles\HVACTemplate-5ZoneVAVWaterCooled.rvi"
  Delete "$INSTDIR\ExampleFiles\HVACTemplate-5ZoneVRF.idf"
  Delete "$INSTDIR\ExampleFiles\HVACTemplate-5ZoneVRF.mvi"
  Delete "$INSTDIR\ExampleFiles\HVACTemplate-5ZoneVRF.rvi"
  Delete "$INSTDIR\ExampleFiles\HVACTemplate-5ZoneWaterToAirHeatPumpTowerBoiler.idf"
  Delete "$INSTDIR\ExampleFiles\HybridVentilationControl.idf"
  Delete "$INSTDIR\ExampleFiles\HybridVentilationControlGlobalSimple.idf"
  Delete "$INSTDIR\ExampleFiles\IceStorage-Parallel.idf"
  Delete "$INSTDIR\ExampleFiles\IceStorage-Series-ChillerDownstream.idf"
  Delete "$INSTDIR\ExampleFiles\IceStorage-Series-ChillerUpstream.idf"
  Delete "$INSTDIR\ExampleFiles\IndEvapCoolerRTUoffice.idf"
  Delete "$INSTDIR\ExampleFiles\IndirectAbsorptionChiller.idf"
  Delete "$INSTDIR\ExampleFiles\LBuilding-G000.idf"
  Delete "$INSTDIR\ExampleFiles\LBuilding-G090.idf"
  Delete "$INSTDIR\ExampleFiles\LBuilding-G180.idf"
  Delete "$INSTDIR\ExampleFiles\LBuilding-G270.idf"
  Delete "$INSTDIR\ExampleFiles\LBuildingAppGRotPar.idf"
  Delete "$INSTDIR\ExampleFiles\LgOffVAV.idf"
  Delete "$INSTDIR\ExampleFiles\LgOffVAV.rvi"
  Delete "$INSTDIR\ExampleFiles\LgOffVAVusingBasement.idf"
  Delete "$INSTDIR\ExampleFiles\LookupTables.idf"
  Delete "$INSTDIR\ExampleFiles\LrgOff_GridStorageDemandLeveling.idf"
  Delete "$INSTDIR\ExampleFiles\LrgOff_GridStorageEMSSmoothing.idf"
  Delete "$INSTDIR\ExampleFiles\LrgOff_GridStorageScheduled.idf"
  Delete "$INSTDIR\ExampleFiles\MicroCogeneration.idf"
  Delete "$INSTDIR\ExampleFiles\Minimal.idf"
  Delete "$INSTDIR\ExampleFiles\MovableExtInsulationSimple.idf"
  Delete "$INSTDIR\ExampleFiles\MovableExtInsulationSimple.rvi"
  Delete "$INSTDIR\ExampleFiles\MovableIntInsulationLights.idf"
  Delete "$INSTDIR\ExampleFiles\MovableIntInsulationLightsLowE.idf"
  Delete "$INSTDIR\ExampleFiles\MovableIntInsulationSimple.idf"
  Delete "$INSTDIR\ExampleFiles\MovableIntInsulationSimple.rvi"
  Delete "$INSTDIR\ExampleFiles\MultiSpeedACFurnace.idf"
  Delete "$INSTDIR\ExampleFiles\MultispeedHeatPump.idf"
  Delete "$INSTDIR\ExampleFiles\MultiSpeedHP_StagedThermostat.idf"
  Delete "$INSTDIR\ExampleFiles\MultiStory.idf"
  Delete "$INSTDIR\ExampleFiles\MultiStory.rvi"
  Delete "$INSTDIR\ExampleFiles\Mundt_System_Always_On.idf"
  Delete "$INSTDIR\ExampleFiles\Mundt_System_On_During_the_Day.idf"
  Delete "$INSTDIR\ExampleFiles\OptimalStart_RefBldgLargeOfficeNew2004_Chicago.idf"
  Delete "$INSTDIR\ExampleFiles\OutdoorAirUnit.idf"
  Delete "$INSTDIR\ExampleFiles\OutdoorAirUnitwithAirloopHVAC.idf"
  Delete "$INSTDIR\ExampleFiles\PackagedTerminalAirConditioner.idf"
  Delete "$INSTDIR\ExampleFiles\PackagedTerminalAirConditionerVSAS.idf"
  Delete "$INSTDIR\ExampleFiles\PackagedTerminalHeatPump.idf"
  Delete "$INSTDIR\ExampleFiles\PackagedTerminalHeatPumpVSAS.idf"
  Delete "$INSTDIR\ExampleFiles\ParametricInsulation-5ZoneAirCooled.idf"
  Delete "$INSTDIR\ExampleFiles\PassiveTrombeWall.idf"
  Delete "$INSTDIR\ExampleFiles\PassiveTrombeWall.rvi"
  Delete "$INSTDIR\ExampleFiles\PipeHeatTransfer_Outair.idf"
  Delete "$INSTDIR\ExampleFiles\PipeHeatTransfer_Outair.rvi"
  Delete "$INSTDIR\ExampleFiles\PipeHeatTransfer_Schedule.idf"
  Delete "$INSTDIR\ExampleFiles\PipeHeatTransfer_Schedule.rvi"
  Delete "$INSTDIR\ExampleFiles\PipeHeatTransfer_Underground.idf"
  Delete "$INSTDIR\ExampleFiles\PipeHeatTransfer_Underground.rvi"
  Delete "$INSTDIR\ExampleFiles\PipeHeatTransfer_Zone.idf"
  Delete "$INSTDIR\ExampleFiles\PipeHeatTransfer_Zone.rvi"
  Delete "$INSTDIR\ExampleFiles\PipingSystem_Underground_FHX.idf"
  Delete "$INSTDIR\ExampleFiles\PipingSystem_Underground_TwoPipe.idf"
  Delete "$INSTDIR\ExampleFiles\PipingSystem_Underground_TwoPipe_FD_GroundTemps.idf"
  Delete "$INSTDIR\ExampleFiles\PipingSystem_Underground_TwoPipe_Xing_GroundTemps.idf"
  Delete "$INSTDIR\ExampleFiles\PIUAuto.idf"
  Delete "$INSTDIR\ExampleFiles\PIUAuto.rvi"
  Delete "$INSTDIR\ExampleFiles\PlantApplicationsGuide_Example1.idf"
  Delete "$INSTDIR\ExampleFiles\PlantApplicationsGuide_Example2.idf"
  Delete "$INSTDIR\ExampleFiles\PlantApplicationsGuide_Example3.idf"
  Delete "$INSTDIR\ExampleFiles\PlantComponentTemperatureSource.idf"
  Delete "$INSTDIR\ExampleFiles\PlantHorizontalGroundHX.idf"
  Delete "$INSTDIR\ExampleFiles\PlantLoadProfile.idf"
  Delete "$INSTDIR\ExampleFiles\PlantLoadProfile.rvi"
  Delete "$INSTDIR\ExampleFiles\PlantLoadProfileCoolingReturnReset.idf"
  Delete "$INSTDIR\ExampleFiles\PlantLoadProfileCoolingReturnResetLookup.idf"
  Delete "$INSTDIR\ExampleFiles\PlantLoadProfile_AutosizedDistrictHeating.idf"
  Delete "$INSTDIR\ExampleFiles\PlantLoopChainCooling.idf"
  Delete "$INSTDIR\ExampleFiles\PlantLoopChainDeadband.idf"
  Delete "$INSTDIR\ExampleFiles\PlantLoopChainDualDeadband.idf"
  Delete "$INSTDIR\ExampleFiles\PlantLoopChainHeating.idf"
  Delete "$INSTDIR\ExampleFiles\PlantPressureDrop.idf"
  Delete "$INSTDIR\ExampleFiles\PlantPressure_PumpCurve.idf"
  Delete "$INSTDIR\ExampleFiles\PlantPressure_VFD_Scheduled.idf"
  Delete "$INSTDIR\ExampleFiles\PlateHeatExchanger.idf"
  Delete "$INSTDIR\ExampleFiles\PlateHeatExchanger.rvi"
  Delete "$INSTDIR\ExampleFiles\Plenum.idf"
  Delete "$INSTDIR\ExampleFiles\Plenum.rvi"
  Delete "$INSTDIR\ExampleFiles\PlenumwithRetAirHeatGain.idf"
  Delete "$INSTDIR\ExampleFiles\PlenumwithRetAirHeatGain.rvi"
  Delete "$INSTDIR\ExampleFiles\PondGroundHeatExchanger.idf"
  Delete "$INSTDIR\ExampleFiles\PurchAirTables.idf"
  Delete "$INSTDIR\ExampleFiles\PurchAirTables_SQL.idf"
  Delete "$INSTDIR\ExampleFiles\PurchAirTables_wAnnual.idf"
  Delete "$INSTDIR\ExampleFiles\PurchAirWindowBlind.idf"
  Delete "$INSTDIR\ExampleFiles\PurchAirWindowBlind_BlockBeamSolar.idf"
  Delete "$INSTDIR\ExampleFiles\PurchAirWithDaylighting.idf"
  Delete "$INSTDIR\ExampleFiles\PurchAirWithDaylighting.rvi"
  Delete "$INSTDIR\ExampleFiles\PurchAirWithDaylightingAngleFac.idf"
  Delete "$INSTDIR\ExampleFiles\PurchAirWithDaylightingAngleFac.rvi"
  Delete "$INSTDIR\ExampleFiles\PurchAirWithDoubleFacadeDaylighting.idf"
  Delete "$INSTDIR\ExampleFiles\QTFtest.idf"
  Delete "$INSTDIR\ExampleFiles\QTFtest.rvi"
  Delete "$INSTDIR\ExampleFiles\RadHiTempElecTermReheat.idf"
  Delete "$INSTDIR\ExampleFiles\RadHiTempElecTermReheat.rvi"
  Delete "$INSTDIR\ExampleFiles\RadHiTempGasCtrlOpt.idf"
  Delete "$INSTDIR\ExampleFiles\RadHiTempGasCtrlOpt.rvi"
  Delete "$INSTDIR\ExampleFiles\RadHiTempGasTermReheat.idf"
  Delete "$INSTDIR\ExampleFiles\RadHiTempGasTermReheat.rvi"
  Delete "$INSTDIR\ExampleFiles\RadLoHydrHeatCoolAuto.idf"
  Delete "$INSTDIR\ExampleFiles\RadLoHydrHeatCoolAuto.rvi"
  Delete "$INSTDIR\ExampleFiles\RadLoHydrHeatCoolAutoCondFD.idf"
  Delete "$INSTDIR\ExampleFiles\RadLoHydrHeatCoolAutoCondFD.rvi"
  Delete "$INSTDIR\ExampleFiles\RadLoTempCFloHeatCool.idf"
  Delete "$INSTDIR\ExampleFiles\RadLoTempCFloHeatCool.rvi"
  Delete "$INSTDIR\ExampleFiles\RadLoTempCFloHeatCoolCondFD.idf"
  Delete "$INSTDIR\ExampleFiles\RadLoTempCFloHeatCool_AddedAutosizing.idf"
  Delete "$INSTDIR\ExampleFiles\RadLoTempCFloTermReheat.idf"
  Delete "$INSTDIR\ExampleFiles\RadLoTempCFloTermReheat.rvi"
  Delete "$INSTDIR\ExampleFiles\RadLoTempElecTermReheat.idf"
  Delete "$INSTDIR\ExampleFiles\RadLoTempElecTermReheat.rvi"
  Delete "$INSTDIR\ExampleFiles\RadLoTempElecTermReheatCondFD.idf"
  Delete "$INSTDIR\ExampleFiles\RadLoTempHydrCoolTower.idf"
  Delete "$INSTDIR\ExampleFiles\RadLoTempHydrCoolTower.rvi"
  Delete "$INSTDIR\ExampleFiles\RadLoTempHydrCoolTowerCondFD.idf"
  Delete "$INSTDIR\ExampleFiles\RadLoTempHydrCtrlOpt.idf"
  Delete "$INSTDIR\ExampleFiles\RadLoTempHydrCtrlOpt.rvi"
  Delete "$INSTDIR\ExampleFiles\RadLoTempHydrCtrlOpt2.idf"
  Delete "$INSTDIR\ExampleFiles\RadLoTempHydrCtrlOpt2.rvi"
  Delete "$INSTDIR\ExampleFiles\RadLoTempHydrHeatCool.idf"
  Delete "$INSTDIR\ExampleFiles\RadLoTempHydrHeatCool.rvi"
  Delete "$INSTDIR\ExampleFiles\RadLoTempHydrHeatCool2D.idf"
  Delete "$INSTDIR\ExampleFiles\RadLoTempHydrHeatCool2D.rvi"
  Delete "$INSTDIR\ExampleFiles\RadLoTempHydrHeatCoolDry.idf"
  Delete "$INSTDIR\ExampleFiles\RadLoTempHydrHeatCoolDry.rvi"
  Delete "$INSTDIR\ExampleFiles\RadLoTempHydrHeatCoolDryCondFD.idf"
  Delete "$INSTDIR\ExampleFiles\RadLoTempHydrInterMulti.idf"
  Delete "$INSTDIR\ExampleFiles\RadLoTempHydrInterMulti.rvi"
  Delete "$INSTDIR\ExampleFiles\RadLoTempHydrMulti10.idf"
  Delete "$INSTDIR\ExampleFiles\RadLoTempHydrMulti10.rvi"
  Delete "$INSTDIR\ExampleFiles\RadLoTempHydrTermReheat.idf"
  Delete "$INSTDIR\ExampleFiles\RadLoTempHydrTermReheat.rvi"
  Delete "$INSTDIR\ExampleFiles\RefBldgFullServiceRestaurantNew2004_Chicago.idf"
  Delete "$INSTDIR\ExampleFiles\RefBldgHospitalNew2004_Chicago.idf"
  Delete "$INSTDIR\ExampleFiles\RefBldgLargeHotelNew2004_Chicago.idf"
  Delete "$INSTDIR\ExampleFiles\RefBldgLargeOfficeNew2004_Chicago-ReturnReset.idf"
  Delete "$INSTDIR\ExampleFiles\RefBldgLargeOfficeNew2004_Chicago.idf"
  Delete "$INSTDIR\ExampleFiles\RefBldgMediumOfficeNew2004_Chicago.idf"
  Delete "$INSTDIR\ExampleFiles\RefBldgMidriseApartmentNew2004_Chicago.idf"
  Delete "$INSTDIR\ExampleFiles\RefBldgOutPatientNew2004_Chicago.idf"
  Delete "$INSTDIR\ExampleFiles\RefBldgPrimarySchoolNew2004_Chicago.idf"
  Delete "$INSTDIR\ExampleFiles\RefBldgQuickServiceRestaurantNew2004_Chicago.idf"
  Delete "$INSTDIR\ExampleFiles\RefBldgSecondarySchoolNew2004_Chicago.idf"
  Delete "$INSTDIR\ExampleFiles\RefBldgSmallHotelNew2004_Chicago.idf"
  Delete "$INSTDIR\ExampleFiles\RefBldgSmallOfficeNew2004_Chicago.idf"
  Delete "$INSTDIR\ExampleFiles\RefBldgStand-aloneRetailNew2004_Chicago.idf"
  Delete "$INSTDIR\ExampleFiles\RefBldgStripMallNew2004_Chicago.idf"
  Delete "$INSTDIR\ExampleFiles\RefBldgSuperMarketNew2004_Chicago.idf"
  Delete "$INSTDIR\ExampleFiles\RefBldgWarehouseNew2004_Chicago.idf"
  Delete "$INSTDIR\ExampleFiles\ReflectiveAdjacentBuilding.idf"
  Delete "$INSTDIR\ExampleFiles\RefMedOffVAVAllDefVRP.idf"
  Delete "$INSTDIR\ExampleFiles\RefrigeratedWarehouse.idf"
  Delete "$INSTDIR\ExampleFiles\RefrigeratedWarehouse.rvi"
  Delete "$INSTDIR\ExampleFiles\ReliefIndEvapCoolerRTUoffice.idf"
  Delete "$INSTDIR\ExampleFiles\ReportDaylightFactors.idf"
  Delete "$INSTDIR\ExampleFiles\RetailPackagedTESCoil.idf"
  Delete "$INSTDIR\ExampleFiles\RoomAirflowNetwork.idf"
  Delete "$INSTDIR\ExampleFiles\SeriesActiveBranch.idf"
  Delete "$INSTDIR\ExampleFiles\ShopWithPVandBattery.idf"
  Delete "$INSTDIR\ExampleFiles\ShopWithPVandStorage.idf"
  Delete "$INSTDIR\ExampleFiles\ShopWithSimplePVT.idf"
  Delete "$INSTDIR\ExampleFiles\SingleFamilyHouse_TwoSpeed_ZoneAirBalance.idf"
  Delete "$INSTDIR\ExampleFiles\SmOffPSZ-MultiModeDX.idf"
  Delete "$INSTDIR\ExampleFiles\SmOffPSZ-MultiModeDX.rvi"
  Delete "$INSTDIR\ExampleFiles\SmOffPSZ.idf"
  Delete "$INSTDIR\ExampleFiles\SmOffPSZ.rvi"
  Delete "$INSTDIR\ExampleFiles\SmOffPSZ_OnOffStagedControl.idf"
  Delete "$INSTDIR\ExampleFiles\SolarCollectorFlatPlateWater.idf"
  Delete "$INSTDIR\ExampleFiles\SolarCollectorFlatPlateWater.rvi"
  Delete "$INSTDIR\ExampleFiles\SolarShadingTest.idf"
  Delete "$INSTDIR\ExampleFiles\SolarShadingTest.rvi"
  Delete "$INSTDIR\ExampleFiles\SolarShadingTest_SQL.idf"
  Delete "$INSTDIR\ExampleFiles\SolarShadingTest_SQL.rvi"
  Delete "$INSTDIR\ExampleFiles\StackedZonesWithInterzoneIRTLayers.idf"
  Delete "$INSTDIR\ExampleFiles\SteamSystemAutoSize.idf"
  Delete "$INSTDIR\ExampleFiles\StormWindow.idf"
  Delete "$INSTDIR\ExampleFiles\StripMallZoneEvapCooler.idf"
  Delete "$INSTDIR\ExampleFiles\StripMallZoneEvapCoolerAutosized.idf"
  Delete "$INSTDIR\ExampleFiles\Supermarket.idf"
  Delete "$INSTDIR\ExampleFiles\SuperMarketDetailed_DesuperHeatingCoil.idf"
  Delete "$INSTDIR\ExampleFiles\SupermarketSecondary.idf"
  Delete "$INSTDIR\ExampleFiles\SupermarketSecondary.rvi"
  Delete "$INSTDIR\ExampleFiles\SupermarketSubCoolersVariableSuction.idf"
  Delete "$INSTDIR\ExampleFiles\SupermarketTranscriticalCO2.idf"
  Delete "$INSTDIR\ExampleFiles\SupermarketTwoStageFlashIntercooler.idf"
  Delete "$INSTDIR\ExampleFiles\SupermarketTwoStageShellCoilIntercooler.idf"
  Delete "$INSTDIR\ExampleFiles\Supermarket_CascadeCond.idf"
  Delete "$INSTDIR\ExampleFiles\SuperMarket_DesuperHeatingCoil.idf"
  Delete "$INSTDIR\ExampleFiles\Supermarket_Detailed.idf"
  Delete "$INSTDIR\ExampleFiles\SuperMarket_DetailedEvapCondenser.idf"
  Delete "$INSTDIR\ExampleFiles\SuperMarket_DetailedWaterCondenser.idf"
  Delete "$INSTDIR\ExampleFiles\SuperMarket_EvapCondenser.idf"
  Delete "$INSTDIR\ExampleFiles\Supermarket_SharedAirCondenser.idf"
  Delete "$INSTDIR\ExampleFiles\SuperMarket_SharedEvapCondenser.idf"
  Delete "$INSTDIR\ExampleFiles\SuperMarket_WaterCondenser.idf"
  Delete "$INSTDIR\ExampleFiles\SupplyPlenumVAV.idf"
  Delete "$INSTDIR\ExampleFiles\SupplyPlenumVAV.rvi"
  Delete "$INSTDIR\ExampleFiles\SurfaceGroundHeatExchanger.idf"
  Delete "$INSTDIR\ExampleFiles\SurfaceTest.idf"
  Delete "$INSTDIR\ExampleFiles\SurfaceTest.rvi"
  Delete "$INSTDIR\ExampleFiles\TermReheat.idf"
  Delete "$INSTDIR\ExampleFiles\TermReheat.rvi"
  Delete "$INSTDIR\ExampleFiles\TermReheatPri-SecLoop.idf"
  Delete "$INSTDIR\ExampleFiles\TermReheatScheduledPump.idf"
  Delete "$INSTDIR\ExampleFiles\TermReheatSurfTC.idf"
  Delete "$INSTDIR\ExampleFiles\TermReheatSurfTC.rvi"
  Delete "$INSTDIR\ExampleFiles\TermReheatZoneExh.idf"
  Delete "$INSTDIR\ExampleFiles\TermReheatZoneExh.rvi"
  Delete "$INSTDIR\ExampleFiles\TermRhDualSetpointWithDB.idf"
  Delete "$INSTDIR\ExampleFiles\TermRhDualSetpointWithDB.rvi"
  Delete "$INSTDIR\ExampleFiles\TermRHDXSystem.idf"
  Delete "$INSTDIR\ExampleFiles\TermRHDXSystem.rvi"
  Delete "$INSTDIR\ExampleFiles\TermRHGasElecCoils.idf"
  Delete "$INSTDIR\ExampleFiles\TermRHGasElecCoils.rvi"
  Delete "$INSTDIR\ExampleFiles\TermRhGenericOAHeatRecMinExh.idf"
  Delete "$INSTDIR\ExampleFiles\TermRhGenericOAHeatRecMinExh.rvi"
  Delete "$INSTDIR\ExampleFiles\TermRhGenericOAHeatRecPreheat.idf"
  Delete "$INSTDIR\ExampleFiles\TermRhGenericOAHeatRecPreheat.rvi"
  Delete "$INSTDIR\ExampleFiles\TermRhSingleHeatCoolNoDB.idf"
  Delete "$INSTDIR\ExampleFiles\TermRhSingleHeatCoolNoDB.rvi"
  Delete "$INSTDIR\ExampleFiles\ThermalChimneyTest.idf"
  Delete "$INSTDIR\ExampleFiles\ThermochromicWindow.idf"
  Delete "$INSTDIR\ExampleFiles\TransparentInsulationSimple.idf"
  Delete "$INSTDIR\ExampleFiles\TransparentInsulationSimple.rvi"
  Delete "$INSTDIR\ExampleFiles\TranspiredCollectors.idf"
  Delete "$INSTDIR\ExampleFiles\TRHConstFlowChillerOneBranch.idf"
  Delete "$INSTDIR\ExampleFiles\TRHConstFlowChillerOneBranch.rvi"
  Delete "$INSTDIR\ExampleFiles\TRHEvapCoolerOAStaged.idf"
  Delete "$INSTDIR\ExampleFiles\TRHEvapCoolerOAStaged.rvi"
  Delete "$INSTDIR\ExampleFiles\TRHEvapCoolerOAStagedWetCoil.idf"
  Delete "$INSTDIR\ExampleFiles\TwoWayCommonPipe_Pri-Sec.idf"
  Delete "$INSTDIR\ExampleFiles\UnitarySystem_5ZoneWaterLoopHeatPump.idf"
  Delete "$INSTDIR\ExampleFiles\UnitarySystem_DXCoilSystemAuto.idf"
  Delete "$INSTDIR\ExampleFiles\UnitarySystem_FurnaceWithDXSystemRHcontrol.idf"
  Delete "$INSTDIR\ExampleFiles\UnitarySystem_HeatPumpAuto.idf"
  Delete "$INSTDIR\ExampleFiles\UnitarySystem_MultiSpeedCoils_SingleMode.idf"
  Delete "$INSTDIR\ExampleFiles\UnitarySystem_VSHeatPumpWaterToAirEquationFit.idf"
  Delete "$INSTDIR\ExampleFiles\UnitarySystem_WaterCoils_wMultiSpeedFan.idf"
  Delete "$INSTDIR\ExampleFiles\UnitHeater.idf"
  Delete "$INSTDIR\ExampleFiles\UnitHeater.rvi"
  Delete "$INSTDIR\ExampleFiles\UnitHeaterAuto.idf"
  Delete "$INSTDIR\ExampleFiles\UnitHeaterAuto.rvi"
  Delete "$INSTDIR\ExampleFiles\UnitHeaterGasElec.idf"
  Delete "$INSTDIR\ExampleFiles\UnitHeaterGasElec.rvi"
  Delete "$INSTDIR\ExampleFiles\UnitVent5Zone.idf"
  Delete "$INSTDIR\ExampleFiles\UnitVent5ZoneAuto.idf"
  Delete "$INSTDIR\ExampleFiles\UnitVent5ZoneFixedOANoCoilOpt.idf"
  Delete "$INSTDIR\ExampleFiles\UserDefinedRoomAirPatterns.idf"
  Delete "$INSTDIR\ExampleFiles\UserInputViewFactorFile-LshapedZone.idf"
  Delete "$INSTDIR\ExampleFiles\VariableRefrigerantFlow_5Zone.idf"
  Delete "$INSTDIR\ExampleFiles\VariableRefrigerantFlow_FluidTCtrl_5Zone.idf"
  Delete "$INSTDIR\ExampleFiles\VariableRefrigerantFlow_FluidTCtrl_HR_5Zone.idf"
  Delete "$INSTDIR\ExampleFiles\VAVSingleDuctConstFlowBoiler.idf"
  Delete "$INSTDIR\ExampleFiles\VAVSingleDuctReheat.idf"
  Delete "$INSTDIR\ExampleFiles\VAVSingleDuctReheat.rvi"
  Delete "$INSTDIR\ExampleFiles\VAVSingleDuctReheatBaseboard.idf"
  Delete "$INSTDIR\ExampleFiles\VAVSingleDuctReheatNoReheat.idf"
  Delete "$INSTDIR\ExampleFiles\VAVSingleDuctReheat_DualMax.idf"
  Delete "$INSTDIR\ExampleFiles\VAVSingleDuctReheat_MaxSAT_ReverseActing.idf"
  Delete "$INSTDIR\ExampleFiles\VAVSingleDuctVarFlowBoiler.idf"
  Delete "$INSTDIR\ExampleFiles\VentilatedSlab.idf"
  Delete "$INSTDIR\ExampleFiles\VentilatedSlab_SeriesSlabs.idf"
  Delete "$INSTDIR\ExampleFiles\VentilationSimpleTest.idf"
  Delete "$INSTDIR\ExampleFiles\VentilationSimpleTest.rvi"
  Delete "$INSTDIR\ExampleFiles\VSDXCoilSystemAuto.idf"
  Delete "$INSTDIR\ExampleFiles\VSHeatPumpWaterHeater.idf"
  Delete "$INSTDIR\ExampleFiles\VSHeatPumpWaterToAirEquationFit.idf"
  Delete "$INSTDIR\ExampleFiles\VSHeatPumpWaterToAirWithRHControl.idf"
  Delete "$INSTDIR\ExampleFiles\VSWaterHeaterHeatPumpStratifiedTank.idf"
  Delete "$INSTDIR\ExampleFiles\WaterHeaterDHWPlantLoop.idf"
  Delete "$INSTDIR\ExampleFiles\WaterHeaterHeatPumpStratifiedTank.idf"
  Delete "$INSTDIR\ExampleFiles\WaterHeaterHeatPumpWrappedCondenser.idf"
  Delete "$INSTDIR\ExampleFiles\WaterHeaterStandAlone.idf"
  Delete "$INSTDIR\ExampleFiles\WaterSideEconomizer_Integrated.idf"
  Delete "$INSTDIR\ExampleFiles\WaterSideEconomizer_NonIntegrated.idf"
  Delete "$INSTDIR\ExampleFiles\WeatherTimeBins.idf"
  Delete "$INSTDIR\ExampleFiles\WindACAuto.idf"
  Delete "$INSTDIR\ExampleFiles\WindACAuto.rvi"
  Delete "$INSTDIR\ExampleFiles\WindACRHControl.idf"
  Delete "$INSTDIR\ExampleFiles\WindACRHControl.rvi"
  Delete "$INSTDIR\ExampleFiles\WindowTests.idf"
  Delete "$INSTDIR\ExampleFiles\WindowTests.rvi"
  Delete "$INSTDIR\ExampleFiles\WindowTestsSimple.idf"
  Delete "$INSTDIR\ExampleFiles\WindowTestsSimple.rvi"
  Delete "$INSTDIR\ExampleFiles\ZoneCoupledGroundHTBasement.idf"
  Delete "$INSTDIR\ExampleFiles\ZoneCoupledGroundHTSlabInGrade.idf"
  Delete "$INSTDIR\ExampleFiles\ZoneCoupledGroundHTSlabOnGrade.idf"
  Delete "$INSTDIR\ExampleFiles\ZoneSysAvailManager.idf"
  Delete "$INSTDIR\ExampleFiles\ZoneVSWSHP_wDOAS.idf"
  Delete "$INSTDIR\ExampleFiles\ZoneWSHP_wDOAS.idf"
  Delete "$INSTDIR\LICENSE.txt"
  Delete "$INSTDIR\MacroDataSets"
  Delete "$INSTDIR\MacroDataSets\Locations-DesignDays.xls"
  Delete "$INSTDIR\MacroDataSets\SandiaPVdata.imf"
  Delete "$INSTDIR\MacroDataSets\SolarCollectors.imf"
  Delete "$INSTDIR\MacroDataSets\UtilityTariffObjects.imf"
  Delete "$INSTDIR\msvcp140.dll"
  Delete "$INSTDIR\OutputChanges8-5-0-to-8-6-0.md"
  Delete "$INSTDIR\PostProcess"
  Delete "$INSTDIR\PostProcess\CSVproc.exe"
  Delete "$INSTDIR\PostProcess\EP-Compare"
  Delete "$INSTDIR\PostProcess\EP-Compare\EP-Compare Libs"
  Delete "$INSTDIR\PostProcess\EP-Compare\EP-Compare Libs\Appearance Pak.dll"
  Delete "$INSTDIR\PostProcess\EP-Compare\EP-Compare Libs\EHInterfaces5001.dll"
  Delete "$INSTDIR\PostProcess\EP-Compare\EP-Compare Libs\EHObjectArray5001.dll"
  Delete "$INSTDIR\PostProcess\EP-Compare\EP-Compare Libs\EHObjectCollection5001.dll"
  Delete "$INSTDIR\PostProcess\EP-Compare\EP-Compare Libs\EHTreeView4301.DLL"
  Delete "$INSTDIR\PostProcess\EP-Compare\EP-Compare Libs\MBSChartDirector5Plugin16042.dll"
  Delete "$INSTDIR\PostProcess\EP-Compare\EP-Compare.exe"
  Delete "$INSTDIR\PostProcess\EP-Compare\GraphHints.csv"
  Delete "$INSTDIR\PostProcess\RunReadESO.bat"
  Delete "$INSTDIR\PreProcess"
  Delete "$INSTDIR\PreProcess\CalcSoilSurfTemp"
  Delete "$INSTDIR\PreProcess\CalcSoilSurfTemp\RunCalcSoilSurfTemp.bat"
  Delete "$INSTDIR\PreProcess\CoeffConv"
  Delete "$INSTDIR\PreProcess\CoeffConv\CoeffCheck.exe"
  Delete "$INSTDIR\PreProcess\CoeffConv\CoeffCheckExample.cci"
  Delete "$INSTDIR\PreProcess\CoeffConv\CoeffConv.exe"
  Delete "$INSTDIR\PreProcess\CoeffConv\CoeffConvExample.coi"
  Delete "$INSTDIR\PreProcess\CoeffConv\EPL-Check.BAT"
  Delete "$INSTDIR\PreProcess\CoeffConv\EPL-Conv.BAT"
  Delete "$INSTDIR\PreProcess\CoeffConv\ReadMe.txt"
  Delete "$INSTDIR\PreProcess\EPDraw"
  Delete "$INSTDIR\PreProcess\EPDraw\EPDrawGUI Libs"
  Delete "$INSTDIR\PreProcess\EPDraw\EPDrawGUI Libs\Appearance Pak.dll"
  Delete "$INSTDIR\PreProcess\EPDraw\EPDrawGUI Libs\Shell.dll"
  Delete "$INSTDIR\PreProcess\EPDraw\EPDrawGUI.exe"
  Delete "$INSTDIR\PreProcess\EPDraw\EPlusDrw.dll"
  Delete "$INSTDIR\PreProcess\EPDraw\libifcoremd.dll"
  Delete "$INSTDIR\PreProcess\EPDraw\libifportmd.dll"
  Delete "$INSTDIR\PreProcess\EPDraw\libmmd.dll"
  Delete "$INSTDIR\PreProcess\EPDraw\svml_dispmd.dll"
  Delete "$INSTDIR\PreProcess\FMUParser"
  Delete "$INSTDIR\PreProcess\FMUParser\parser.exe"
  Delete "$INSTDIR\PreProcess\GrndTempCalc"
  Delete "$INSTDIR\PreProcess\GrndTempCalc\basementexample.audit"
  Delete "$INSTDIR\PreProcess\GrndTempCalc\basementexample.csv"
  Delete "$INSTDIR\PreProcess\GrndTempCalc\BasementExample.idf"
  Delete "$INSTDIR\PreProcess\GrndTempCalc\basementexample.out"
  Delete "$INSTDIR\PreProcess\GrndTempCalc\basementexample_out.idf"
  Delete "$INSTDIR\PreProcess\GrndTempCalc\RunBasement.bat"
  Delete "$INSTDIR\PreProcess\GrndTempCalc\RunSlab.bat"
  Delete "$INSTDIR\PreProcess\GrndTempCalc\slabexample.ger"
  Delete "$INSTDIR\PreProcess\GrndTempCalc\slabexample.gtp"
  Delete "$INSTDIR\PreProcess\GrndTempCalc\SlabExample.idf"
  Delete "$INSTDIR\PreProcess\HVACCurveFitTool"
  Delete "$INSTDIR\PreProcess\HVACCurveFitTool\CurveFitTool.xlsm"
  Delete "$INSTDIR\PreProcess\HVACCurveFitTool\IceStorageCurveFitTool.xlsm"
  Delete "$INSTDIR\PreProcess\IDFEditor"
  Delete "$INSTDIR\PreProcess\IDFEditor\IDFEditor.exe"
  Delete "$INSTDIR\PreProcess\IDFVersionUpdater"
  Delete "$INSTDIR\PreProcess\IDFVersionUpdater\IDFVersionUpdater Libs"
  Delete "$INSTDIR\PreProcess\IDFVersionUpdater\IDFVersionUpdater Libs\Appearance Pak.dll"
  Delete "$INSTDIR\PreProcess\IDFVersionUpdater\IDFVersionUpdater Libs\msvcp120.dll"
  Delete "$INSTDIR\PreProcess\IDFVersionUpdater\IDFVersionUpdater Libs\msvcr120.dll"
  Delete "$INSTDIR\PreProcess\IDFVersionUpdater\IDFVersionUpdater Libs\RBGUIFramework.dll"
  Delete "$INSTDIR\PreProcess\IDFVersionUpdater\IDFVersionUpdater Libs\Shell.dll"
  Delete "$INSTDIR\PreProcess\IDFVersionUpdater\IDFVersionUpdater.exe"
  Delete "$INSTDIR\PreProcess\IDFVersionUpdater\Report Variables 8-5-0 to 8-6-0.csv"
  Delete "$INSTDIR\PreProcess\IDFVersionUpdater\V7-2-0-Energy+.idd"
  Delete "$INSTDIR\PreProcess\IDFVersionUpdater\V8-0-0-Energy+.idd"
  Delete "$INSTDIR\PreProcess\IDFVersionUpdater\V8-1-0-Energy+.idd"
  Delete "$INSTDIR\PreProcess\IDFVersionUpdater\V8-2-0-Energy+.idd"
  Delete "$INSTDIR\PreProcess\IDFVersionUpdater\V8-3-0-Energy+.idd"
  Delete "$INSTDIR\PreProcess\IDFVersionUpdater\V8-4-0-Energy+.idd"
  Delete "$INSTDIR\PreProcess\IDFVersionUpdater\V8-5-0-Energy+.idd"
  Delete "$INSTDIR\PreProcess\IDFVersionUpdater\V8-6-0-Energy+.idd"
  Delete "$INSTDIR\PreProcess\ParametricPreProcessor"
  Delete "$INSTDIR\PreProcess\ParametricPreProcessor\RunParam.bat"
  Delete "$INSTDIR\PreProcess\ViewFactorCalculation"
  Delete "$INSTDIR\PreProcess\ViewFactorCalculation\readme.txt"
  Delete "$INSTDIR\PreProcess\ViewFactorCalculation\View3D.exe"
  Delete "$INSTDIR\PreProcess\ViewFactorCalculation\View3D32.pdf"
  Delete "$INSTDIR\PreProcess\ViewFactorCalculation\ViewFactorInterface.xls"
  Delete "$INSTDIR\PreProcess\WeatherConverter"
  Delete "$INSTDIR\PreProcess\WeatherConverter\Abbreviations.csv"
  Delete "$INSTDIR\PreProcess\WeatherConverter\ASHRAE_2013_Monthly_DesignConditions.csv"
  Delete "$INSTDIR\PreProcess\WeatherConverter\ASHRAE_2013_OtherMonthly_DesignConditions.csv"
  Delete "$INSTDIR\PreProcess\WeatherConverter\ASHRAE_2013_Yearly_DesignConditions.csv"
  Delete "$INSTDIR\PreProcess\WeatherConverter\Cal Climate Zone Lat Long data.csv"
  Delete "$INSTDIR\PreProcess\WeatherConverter\CountryCodes.txt"
  Delete "$INSTDIR\PreProcess\WeatherConverter\EPlusWth.dll"
  Delete "$INSTDIR\PreProcess\WeatherConverter\libifcoremd.dll"
  Delete "$INSTDIR\PreProcess\WeatherConverter\libifportmd.dll"
  Delete "$INSTDIR\PreProcess\WeatherConverter\libmmd.dll"
  Delete "$INSTDIR\PreProcess\WeatherConverter\svml_dispmd.dll"
  Delete "$INSTDIR\PreProcess\WeatherConverter\TimeZoneCodes.txt"
  Delete "$INSTDIR\PreProcess\WeatherConverter\WBANLocations.csv"
  Delete "$INSTDIR\PreProcess\WeatherConverter\Weather.exe"
  Delete "$INSTDIR\readme.html"
  Delete "$INSTDIR\Rules8-5-0-to-8-6-0.xls"
  Delete "$INSTDIR\RunDirMulti.bat"
  Delete "$INSTDIR\RunEP.ico"
  Delete "$INSTDIR\Runep.pif"
  Delete "$INSTDIR\RunEPlus.bat"
  Delete "$INSTDIR\RunReadESO.bat"
  Delete "$INSTDIR\SetupOutputVariables.csv"
  Delete "$INSTDIR\temp"
  Delete "$INSTDIR\temp\ComDlg32.OCX"
  Delete "$INSTDIR\temp\Dforrt.dll"
  Delete "$INSTDIR\temp\Graph32.ocx"
  Delete "$INSTDIR\temp\Gsw32.exe"
  Delete "$INSTDIR\temp\Gswdll32.dll"
  Delete "$INSTDIR\temp\MSCOMCTL.OCX"
  Delete "$INSTDIR\temp\Msflxgrd.ocx"
  Delete "$INSTDIR\temp\MSINET.OCX"
  Delete "$INSTDIR\temp\Msvcrtd.dll"
  Delete "$INSTDIR\temp\Vsflex7L.ocx"
  Delete "$INSTDIR\vcruntime140.dll"
  Delete "$INSTDIR\WeatherData"
  Delete "$INSTDIR\WeatherData\USA_CA_San.Francisco.Intl.AP.724940_TMY3.ddy"
  Delete "$INSTDIR\WeatherData\USA_CA_San.Francisco.Intl.AP.724940_TMY3.epw"
  Delete "$INSTDIR\WeatherData\USA_CA_San.Francisco.Intl.AP.724940_TMY3.stat"
  Delete "$INSTDIR\WeatherData\USA_CO_Golden-NREL.724666_TMY3.ddy"
  Delete "$INSTDIR\WeatherData\USA_CO_Golden-NREL.724666_TMY3.epw"
  Delete "$INSTDIR\WeatherData\USA_CO_Golden-NREL.724666_TMY3.stat"
  Delete "$INSTDIR\WeatherData\USA_FL_Tampa.Intl.AP.722110_TMY3.ddy"
  Delete "$INSTDIR\WeatherData\USA_FL_Tampa.Intl.AP.722110_TMY3.epw"
  Delete "$INSTDIR\WeatherData\USA_FL_Tampa.Intl.AP.722110_TMY3.stat"
  Delete "$INSTDIR\WeatherData\USA_IL_Chicago-OHare.Intl.AP.725300_TMY3.ddy"
  Delete "$INSTDIR\WeatherData\USA_IL_Chicago-OHare.Intl.AP.725300_TMY3.epw"
  Delete "$INSTDIR\WeatherData\USA_IL_Chicago-OHare.Intl.AP.725300_TMY3.stat"
  Delete "$INSTDIR\WeatherData\USA_VA_Sterling-Washington.Dulles.Intl.AP.724030_TMY3.ddy"
  Delete "$INSTDIR\WeatherData\USA_VA_Sterling-Washington.Dulles.Intl.AP.724030_TMY3.epw"
  Delete "$INSTDIR\WeatherData\USA_VA_Sterling-Washington.Dulles.Intl.AP.724030_TMY3.stat"

  RMDir "$INSTDIR\DataSets\FMUs"
  RMDir "$INSTDIR\DataSets\TDV"
  RMDir "$INSTDIR\DataSets"
  RMDir "$INSTDIR\ExampleFiles\AdvancedOutput"
  RMDir "$INSTDIR\ExampleFiles\BasicsFiles"
  RMDir "$INSTDIR\ExampleFiles"
  RMDir "$INSTDIR\MacroDataSets"
  RMDir "$INSTDIR\PostProcess\EP-Compare\EP-Compare Libs"
  RMDir "$INSTDIR\PostProcess\EP-Compare"
  RMDir "$INSTDIR\PostProcess"
  RMDir "$INSTDIR\PreProcess\CalcSoilSurfTemp"
  RMDir "$INSTDIR\PreProcess\CoeffConv"
  RMDir "$INSTDIR\PreProcess\EPDraw\EPDrawGUI Libs"
  RMDir "$INSTDIR\PreProcess\EPDraw"
  RMDir "$INSTDIR\PreProcess\FMUParser"
  RMDir "$INSTDIR\PreProcess\GrndTempCalc"
  RMDir "$INSTDIR\PreProcess\HVACCurveFitTool"
  RMDir "$INSTDIR\PreProcess\IDFEditor"
  RMDir "$INSTDIR\PreProcess\IDFVersionUpdater\IDFVersionUpdater Libs"
  RMDir "$INSTDIR\PreProcess\IDFVersionUpdater"
  RMDir "$INSTDIR\PreProcess\ParametricPreProcessor"
  RMDir "$INSTDIR\PreProcess\ViewFactorCalculation"
  RMDir "$INSTDIR\PreProcess\WeatherConverter"
  RMDir "$INSTDIR\PreProcess"
  RMDir "$INSTDIR\temp"
  RMDir "$INSTDIR\WeatherData"


!ifdef CPACK_NSIS_ADD_REMOVE
  ;Remove the add/remove program
  Delete "$INSTDIR\AddRemove.exe"
!endif

  ;Remove the uninstaller itself.
  Delete "$INSTDIR\Uninstall.exe"
  DeleteRegKey SHCTX "Software\Microsoft\Windows\CurrentVersion\Uninstall\EnergyPlus 8.6.0-3eed2f7901"

  ;Remove the installation directory if it is empty.
  RMDir "$INSTDIR"

  ; Remove the registry entries.
  DeleteRegKey SHCTX "Software\US Department of Energy\EnergyPlus 8.6.0-3eed2f7901"

  ; Removes all optional components
  !insertmacro SectionList "RemoveSection_CPack"

  !insertmacro MUI_STARTMENU_GETFOLDER Application $MUI_TEMP

  Delete "$SMPROGRAMS\$MUI_TEMP\Uninstall.lnk"
  Delete "$SMPROGRAMS\$MUI_TEMP\EnergyPlus Documentation.lnk"
  Delete "$SMPROGRAMS\$MUI_TEMP\EP-Compare.lnk"
  Delete "$SMPROGRAMS\$MUI_TEMP\EPDrawGUI.lnk"
  Delete "$SMPROGRAMS\$MUI_TEMP\EP-Launch.lnk"
  Delete "$SMPROGRAMS\$MUI_TEMP\Example Files Summary Spreadsheet.lnk"
  Delete "$SMPROGRAMS\$MUI_TEMP\ExampleFiles Link to Objects.lnk"
  Delete "$SMPROGRAMS\$MUI_TEMP\IDFEditor.lnk"
  Delete "$SMPROGRAMS\$MUI_TEMP\IDFVersionUpdater.lnk"
  Delete "$SMPROGRAMS\$MUI_TEMP\Readme Notes.lnk"
  Delete "$SMPROGRAMS\$MUI_TEMP\Weather Statistics and Conversions.lnk"



  ;Delete empty start menu parent diretories
  StrCpy $MUI_TEMP "$SMPROGRAMS\$MUI_TEMP"

  startMenuDeleteLoop:
    ClearErrors
    RMDir $MUI_TEMP
    GetFullPathName $MUI_TEMP "$MUI_TEMP\.."

    IfErrors startMenuDeleteLoopDone

    StrCmp "$MUI_TEMP" "$SMPROGRAMS" startMenuDeleteLoopDone startMenuDeleteLoop
  startMenuDeleteLoopDone:

  ; If the user changed the shortcut, then untinstall may not work. This should
  ; try to fix it.
  StrCpy $MUI_TEMP "$START_MENU"
  Delete "$SMPROGRAMS\$MUI_TEMP\Uninstall.lnk"


  ;Delete empty start menu parent diretories
  StrCpy $MUI_TEMP "$SMPROGRAMS\$MUI_TEMP"

  secondStartMenuDeleteLoop:
    ClearErrors
    RMDir $MUI_TEMP
    GetFullPathName $MUI_TEMP "$MUI_TEMP\.."

    IfErrors secondStartMenuDeleteLoopDone

    StrCmp "$MUI_TEMP" "$SMPROGRAMS" secondStartMenuDeleteLoopDone secondStartMenuDeleteLoop
  secondStartMenuDeleteLoopDone:

  DeleteRegKey /ifempty SHCTX "Software\US Department of Energy\EnergyPlus 8.6.0-3eed2f7901"

  Push $INSTDIR\bin
  StrCmp $DO_NOT_ADD_TO_PATH_ "1" doNotRemoveFromPath 0
    Call un.RemoveFromPath
  doNotRemoveFromPath:
SectionEnd

;--------------------------------
; determine admin versus local install
; Is install for "AllUsers" or "JustMe"?
; Default to "JustMe" - set to "AllUsers" if admin or on Win9x
; This function is used for the very first "custom page" of the installer.
; This custom page does not show up visibly, but it executes prior to the
; first visible page and sets up $INSTDIR properly...
; Choose different default installation folder based on SV_ALLUSERS...
; "Program Files" for AllUsers, "My Documents" for JustMe...

Function .onInit
  StrCmp "" "ON" 0 inst

  ReadRegStr $0 HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\EnergyPlus 8.6.0-3eed2f7901" "UninstallString"
  StrCmp $0 "" inst

  MessageBox MB_YESNOCANCEL|MB_ICONEXCLAMATION \
  "EnergyPlusV8-6-0 is already installed. $\n$\nDo you want to uninstall the old version before installing the new one?" \
  /SD IDYES IDYES uninst IDNO inst
  Abort

;Run the uninstaller
uninst:
  ClearErrors
  StrLen $2 "\Uninstall.exe"
  StrCpy $3 $0 -$2 # remove "\Uninstall.exe" from UninstallString to get path
  ExecWait '"$0" /S _?=$3' ;Do not copy the uninstaller to a temp file

  IfErrors uninst_failed inst
uninst_failed:
  MessageBox MB_OK|MB_ICONSTOP "Uninstall failed."
  Abort


inst:
  ; Reads components status for registry
  !insertmacro SectionList "InitSection"

  ; check to see if /D has been used to change
  ; the install directory by comparing it to the
  ; install directory that is expected to be the
  ; default
  StrCpy $IS_DEFAULT_INSTALLDIR 0
  StrCmp "$INSTDIR" "C:\EnergyPlusV8-6-0" 0 +2
    StrCpy $IS_DEFAULT_INSTALLDIR 1

  StrCpy $SV_ALLUSERS "JustMe"
  ; if default install dir then change the default
  ; if it is installed for JustMe
  StrCmp "$IS_DEFAULT_INSTALLDIR" "1" 0 +2
    StrCpy $INSTDIR "$DOCUMENTS\EnergyPlusV8-6-0"

  ClearErrors
  UserInfo::GetName
  IfErrors noLM
  Pop $0
  UserInfo::GetAccountType
  Pop $1
  StrCmp $1 "Admin" 0 +4
    SetShellVarContext all
    ;MessageBox MB_OK 'User "$0" is in the Admin group'
    StrCpy $SV_ALLUSERS "AllUsers"
    Goto done
  StrCmp $1 "Power" 0 +4
    SetShellVarContext all
    ;MessageBox MB_OK 'User "$0" is in the Power Users group'
    StrCpy $SV_ALLUSERS "AllUsers"
    Goto done

  noLM:
    StrCpy $SV_ALLUSERS "AllUsers"
    ;Get installation folder from registry if available

  done:
  StrCmp $SV_ALLUSERS "AllUsers" 0 +3
    StrCmp "$IS_DEFAULT_INSTALLDIR" "1" 0 +2
      StrCpy $INSTDIR "C:\EnergyPlusV8-6-0"

  StrCmp "" "ON" 0 noOptionsPage
    !insertmacro MUI_INSTALLOPTIONS_EXTRACT "NSIS.InstallOptions.ini"

  noOptionsPage:
FunctionEnd
