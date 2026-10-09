; Noo — Windows installer (NSIS 3, Unicode).
;
; Built by scripts/build_windows.py, which assembles the distribution directory
; and generates the file list this script installs and removes:
;
;   makensis /DVERSION=1.2.12 /DSOURCE_DIR=<dist dir> /DFILES_NSH=<files.nsh>
;            /DOUTFILE=<setup.exe> installer\windows\noo.nsi
;
; Per-user install, no elevation: the default target is
; %LOCALAPPDATA%\Programs\Noo, the Start Menu shortcut is the same
; %APPDATA%\...\Start Menu\Programs\Noo.lnk the app creates for itself when run
; from a ZIP (platform/app_registration.dart), so the two never duplicate.
;
; The user's databases live in Documents\noo and are never touched — not on
; upgrade, not on uninstall.

Unicode true
ManifestDPIAware true
SetCompressor /SOLID lzma
RequestExecutionLevel user

!ifndef VERSION
  !error "Pass /DVERSION=x.y.z"
!endif
!ifndef SOURCE_DIR
  !error "Pass /DSOURCE_DIR=<distribution directory>"
!endif
!ifndef FILES_NSH
  !error "Pass /DFILES_NSH=<generated file list>"
!endif
!ifndef OUTFILE
  !define OUTFILE "noo-${VERSION}-windows-x64-setup.exe"
!endif

!define APP_NAME      "Noo"
!define APP_EXE       "noo.exe"
!define PUBLISHER     "lab517.io"
!define APP_URL       "https://github.com/lab517io/noo"
!define UNINST_EXE    "uninstall.exe"
!define UNINST_KEY    "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}"
!define SETTINGS_KEY  "Software\lab517\${APP_NAME}"
!define PROGID        "Noo.Database"

!include "MUI2.nsh"
!include "x64.nsh"
!include "WinVer.nsh"
!include "FileFunc.nsh"
!include "LogicLib.nsh"
!include "${FILES_NSH}"

Name "${APP_NAME}"
OutFile "${OUTFILE}"
InstallDir "$LOCALAPPDATA\Programs\${APP_NAME}"
InstallDirRegKey HKCU "${SETTINGS_KEY}" "InstallDir"
BrandingText "${APP_NAME} ${VERSION}"

VIProductVersion "${VERSION}.0"
VIAddVersionKey "ProductName"     "${APP_NAME}"
VIAddVersionKey "ProductVersion"  "${VERSION}"
VIAddVersionKey "FileVersion"     "${VERSION}"
VIAddVersionKey "FileDescription" "${APP_NAME} Setup"
VIAddVersionKey "CompanyName"     "${PUBLISHER}"
VIAddVersionKey "LegalCopyright"  "Copyright (C) 2026 ${PUBLISHER}"

!define MUI_ICON   "..\..\client\windows\runner\resources\app_icon.ico"
!define MUI_UNICON "..\..\client\windows\runner\resources\app_icon.ico"
!define MUI_ABORTWARNING
!define MUI_COMPONENTSPAGE_SMALLDESC

!define MUI_FINISHPAGE_RUN "$INSTDIR\${APP_EXE}"
!define MUI_FINISHPAGE_RUN_TEXT "Launch ${APP_NAME}"

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "..\..\LICENSE"
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

!insertmacro MUI_LANGUAGE "English"

; A running noo.exe cannot be overwritten or deleted. Opening the image for
; writing fails exactly when it is in use, so that is the test — no process
; plugin needed. Used by both the installer and the uninstaller.
!macro WAIT_FOR_APP_EXIT
  ${If} ${FileExists} "$INSTDIR\${APP_EXE}"
    retry:
    ClearErrors
    FileOpen $0 "$INSTDIR\${APP_EXE}" a
    ${If} ${Errors}
      MessageBox MB_RETRYCANCEL|MB_ICONEXCLAMATION \
        "${APP_NAME} is running.$\r$\n$\r$\nClose it and press Retry to continue." \
        /SD IDCANCEL IDRETRY retry
      Abort
    ${EndIf}
    FileClose $0
  ${EndIf}
!macroend

Function .onInit
  ${IfNot} ${RunningX64}
    MessageBox MB_OK|MB_ICONSTOP "${APP_NAME} requires 64-bit Windows." /SD IDOK
    Abort
  ${EndIf}
  ${IfNot} ${AtLeastWin10}
    MessageBox MB_OK|MB_ICONSTOP "${APP_NAME} requires Windows 10 or later." /SD IDOK
    Abort
  ${EndIf}
  SetRegView 64
FunctionEnd

Function un.onInit
  SetRegView 64
FunctionEnd

Section "${APP_NAME}" SecApp
  SectionIn RO
  SetShellVarContext current

  !insertmacro WAIT_FOR_APP_EXIT

  ; An upgrade replaces Flutter's data directory wholesale, so assets a newer
  ; version no longer ships do not linger beside the ones it does.
  ${If} ${FileExists} "$INSTDIR\${UNINST_EXE}"
    RMDir /r "$INSTDIR\data"
  ${EndIf}

  !insertmacro NOO_INSTALL_FILES

  SetOutPath "$INSTDIR"
  WriteUninstaller "$INSTDIR\${UNINST_EXE}"

  CreateShortcut "$SMPROGRAMS\${APP_NAME}.lnk" "$INSTDIR\${APP_EXE}" "" \
    "$INSTDIR\${APP_EXE}" 0 SW_SHOWNORMAL "" "Tiny outliner with time tracking"

  WriteRegStr HKCU "${SETTINGS_KEY}" "InstallDir" "$INSTDIR"

  WriteRegStr   HKCU "${UNINST_KEY}" "DisplayName"          "${APP_NAME}"
  WriteRegStr   HKCU "${UNINST_KEY}" "DisplayVersion"       "${VERSION}"
  WriteRegStr   HKCU "${UNINST_KEY}" "Publisher"            "${PUBLISHER}"
  WriteRegStr   HKCU "${UNINST_KEY}" "URLInfoAbout"         "${APP_URL}"
  WriteRegStr   HKCU "${UNINST_KEY}" "DisplayIcon"          "$INSTDIR\${APP_EXE},0"
  WriteRegStr   HKCU "${UNINST_KEY}" "InstallLocation"      "$INSTDIR"
  WriteRegStr   HKCU "${UNINST_KEY}" "UninstallString"      '"$INSTDIR\${UNINST_EXE}"'
  WriteRegStr   HKCU "${UNINST_KEY}" "QuietUninstallString" '"$INSTDIR\${UNINST_EXE}" /S'
  WriteRegDWORD HKCU "${UNINST_KEY}" "NoModify" 1
  WriteRegDWORD HKCU "${UNINST_KEY}" "NoRepair" 1
  ${GetSize} "$INSTDIR" "/S=0K" $0 $1 $2
  IntFmt $0 "0x%08X" $0
  WriteRegDWORD HKCU "${UNINST_KEY}" "EstimatedSize" "$0"
SectionEnd

Section /o "Desktop shortcut" SecDesktop
  SetShellVarContext current
  CreateShortcut "$DESKTOP\${APP_NAME}.lnk" "$INSTDIR\${APP_EXE}" "" \
    "$INSTDIR\${APP_EXE}" 0 SW_SHOWNORMAL "" "Tiny outliner with time tracking"
SectionEnd

; The app opens the database named by its first argument (main.dart), and a
; second launch is forwarded to the running instance, so double-clicking a
; .noo file works whether or not Noo is already open.
Section "Open .noo files with ${APP_NAME}" SecAssoc
  WriteRegStr HKCU "Software\Classes\.noo" "" "${PROGID}"
  WriteRegStr HKCU "Software\Classes\${PROGID}" "" "${APP_NAME} database"
  WriteRegStr HKCU "Software\Classes\${PROGID}\DefaultIcon" "" "$INSTDIR\${APP_EXE},0"
  WriteRegStr HKCU "Software\Classes\${PROGID}\shell\open\command" "" '"$INSTDIR\${APP_EXE}" "%1"'
  System::Call 'shell32::SHChangeNotify(i 0x08000000, i 0, p 0, p 0)'
SectionEnd

!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
  !insertmacro MUI_DESCRIPTION_TEXT ${SecApp}     "The ${APP_NAME} application and a Start Menu shortcut."
  !insertmacro MUI_DESCRIPTION_TEXT ${SecDesktop} "Put a ${APP_NAME} shortcut on the desktop."
  !insertmacro MUI_DESCRIPTION_TEXT ${SecAssoc}   "Double-clicking a .noo database opens it in ${APP_NAME}."
!insertmacro MUI_FUNCTION_DESCRIPTION_END

Section "Uninstall"
  SetShellVarContext current

  !insertmacro WAIT_FOR_APP_EXIT

  ; Only what this installer put there — an install directory the user chose
  ; may hold other things, so nothing here is a wildcard except Flutter's own
  ; data directory.
  !insertmacro NOO_UNINSTALL_FILES
  RMDir /r "$INSTDIR\data"
  Delete "$INSTDIR\${UNINST_EXE}"
  RMDir "$INSTDIR"

  Delete "$SMPROGRAMS\${APP_NAME}.lnk"
  Delete "$DESKTOP\${APP_NAME}.lnk"

  ; Release .noo only if it still points at us.
  ReadRegStr $0 HKCU "Software\Classes\.noo" ""
  ${If} $0 == "${PROGID}"
    DeleteRegKey HKCU "Software\Classes\.noo"
  ${EndIf}
  DeleteRegKey HKCU "Software\Classes\${PROGID}"
  System::Call 'shell32::SHChangeNotify(i 0x08000000, i 0, p 0, p 0)'

  DeleteRegKey HKCU "${UNINST_KEY}"
  DeleteRegKey HKCU "${SETTINGS_KEY}"
  DeleteRegKey /ifempty HKCU "Software\lab517"
SectionEnd
