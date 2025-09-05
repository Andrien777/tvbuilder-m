;--------------------------------
; Custom defines
  !define NAME "TVBuilder-M"

!include "MUI2.nsh"
!include "logiclib.nsh"
!define APPFILE "tvbuilder-m.exe"
!define VERSION "1.3.0"
!define SLUG "${NAME} v${VERSION}"


;--------------------------------
; General

  Name "${NAME}"
  OutFile "${NAME} Setup.exe"
  InstallDir "$PROGRAMFILES\${NAME}"
  RequestExecutionLevel admin
 # define installation directory

!define MUI_ICON "ui\tvb_logo.ico"
!define MUI_HEADERIMAGE
!define MUI_WELCOMEPAGE_TITLE "${NAME} Setup"

;--------------------------------
; Pages
  
  ; Installer pages
  !insertmacro MUI_PAGE_WELCOME
  !insertmacro MUI_PAGE_LICENSE ".\LICENSE"
  !insertmacro MUI_PAGE_DIRECTORY
  !insertmacro MUI_PAGE_INSTFILES
  !insertmacro MUI_PAGE_FINISH

  ; Uninstaller pages
  !insertmacro MUI_UNPAGE_CONFIRM
  !insertmacro MUI_UNPAGE_INSTFILES
  
  ; Set UI language
  !insertmacro MUI_LANGUAGE "Russian"

;--------------------------------
; Section - Install App

  Section "-hidden app"
    SectionIn RO
    SetOutPath "$INSTDIR"
    File ${APPFILE}

    SetOutPath "$INSTDIR\bin" ; Include libraries
    File ".\bin\*.*" 

    SetOutPath "$INSTDIR\doc"
    File /r ".\doc\*.*"  ; Include docs

    SetOutPath "$INSTDIR"

    WriteUninstaller "$INSTDIR\Uninstall.exe"
  SectionEnd

;--------------------------------
; Section - Shortcut

  Section "Desktop Shortcut" DeskShort
    CreateShortCut "$DESKTOP\${NAME}.lnk" "$INSTDIR\${APPFILE}"
    CreateDirectory "$SMPROGRAMS\TVBuilder"
    CreateShortcut "$SMPROGRAMS\TVBuilder\Uninstall.lnk" "$INSTDIR\Uninstall.exe"
    CreateShortcut "$SMPROGRAMS\TVBuilder\${NAME}.lnk" "$INSTDIR\${APPFILE}"
  SectionEnd

  
  Function un.RMDirUP
    !define RMDirUP '!insertmacro RMDirUPCall'

    !macro RMDirUPCall _PATH
          push '${_PATH}'
          Call un.RMDirUP
    !macroend

    ; $0 - current folder
    ClearErrors

    Exch $0
    ;DetailPrint "ASDF - $0\.."
    RMDir "$0\.."

    IfErrors Skip
    ${RMDirUP} "$0\.."
    Skip:

    Pop $0

  FunctionEnd

  ;--------------------------------
; Section - Uninstaller

Section "Uninstall"

  ;Delete Shortcut
  Delete "$DESKTOP\${NAME}.lnk"
  Delete "$SMPROGRAMS\TVBuilder\Uninstall.lnk"
  Delete "$SMPROGRAMS\TVBuilder\${NAME}.lnk"
  RMdir "$SMPROGRAMS\TVBuilder"

  ;Delete Uninstall
  Delete "$INSTDIR\Uninstall.exe"

  ;Delete Folder
  RMDir /r "$INSTDIR"
  ${RMDirUP} "$INSTDIR"

SectionEnd