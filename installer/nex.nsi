!include "MUI2.nsh"

!define APP_NAME "NEX"
!define APP_VERSION "0.1.0-alpha.13"
!define APP_PUBLISHER "NEX"
!define INSTALL_DIR "$PROGRAMFILES64\${APP_NAME}"
!define EXE_NAME "nex.exe"

Name "${APP_NAME}"
OutFile "NEX-Setup-${APP_VERSION}.exe"
InstallDir "${INSTALL_DIR}"
InstallDirRegKey HKLM "Software\${APP_NAME}" "InstallPath"
RequestExecutionLevel admin
SetCompressor /SOLID lzma
ShowInstDetails show
ShowUninstDetails show

; NSIS on Windows only accepts backslashes in File/Icon paths.
!define MUI_ABORTWARNING
!define MUI_ICON "setup\app_icon.ico"
!define MUI_UNICON "setup\app_icon.ico"
!define MUI_WELCOMEFINISHPAGE_BITMAP "setup\install-wizard.bmp"
!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_RIGHT
!define MUI_HEADERIMAGE_BITMAP "setup\install-header.bmp"

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_UNPAGE_FINISH

!insertmacro MUI_LANGUAGE "English"
!insertmacro MUI_LANGUAGE "SimpChinese"

Section "Main Files" SecMain
  SectionIn RO
  ; Flutter Windows output is x64, so the registry must use the 64-bit view.
  SetRegView 64
  SetOutPath "$INSTDIR"
  File /r "nex-windows\*"

  CreateShortCut "$DESKTOP\${APP_NAME}.lnk" "$INSTDIR\${EXE_NAME}" "" "$INSTDIR\app_icon.ico" 0
  CreateShortCut "$SMPROGRAMS\${APP_NAME}.lnk" "$INSTDIR\${EXE_NAME}" "" "$INSTDIR\app_icon.ico" 0

  ; Allow the UDP port used by LAN discovery (broadcast beacon).
  ; The installer runs elevated; scope the rule to private/domain profiles only.
  nsExec::ExecToLog 'netsh advfirewall firewall add rule name="NEX LAN Discovery" dir=in action=allow protocol=UDP localport=8618 profile=private,domain'
  Pop $0

  WriteRegStr HKLM "Software\${APP_NAME}" "InstallPath" "$INSTDIR"

  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "DisplayName" "${APP_NAME}"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "DisplayVersion" "${APP_VERSION}"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "Publisher" "${APP_PUBLISHER}"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "InstallLocation" "$INSTDIR"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "DisplayIcon" "$INSTDIR\app_icon.ico"
  WriteRegStr HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "UninstallString" '"$INSTDIR\uninstall.exe"'
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "NoModify" 1
  WriteRegDWORD HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}" "NoRepair" 1

  WriteUninstaller "$INSTDIR\uninstall.exe"
SectionEnd

Section "Uninstall"
  SetRegView 64
  nsExec::ExecToLog 'netsh advfirewall firewall delete rule name="NEX LAN Discovery"'
  Pop $0
  Delete "$INSTDIR\${EXE_NAME}"
  Delete "$INSTDIR\uninstall.exe"
  RMDir /r "$INSTDIR"
  Delete "$DESKTOP\${APP_NAME}.lnk"
  Delete "$SMPROGRAMS\${APP_NAME}.lnk"
  DeleteRegKey HKLM "Software\${APP_NAME}"
  DeleteRegKey HKLM "Software\Microsoft\Windows\CurrentVersion\Uninstall\${APP_NAME}"
SectionEnd