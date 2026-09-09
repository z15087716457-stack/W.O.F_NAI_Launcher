!include "MUI2.nsh"
!include "LogicLib.nsh"

!ifndef VERSION
  !define VERSION "0.0.0"
!endif

!ifndef SOURCE_DIR
  !define SOURCE_DIR "..\..\build\windows\x64\runner\Release"
!endif

!ifndef OUT_FILE
  !define OUT_FILE "NAI_Launcher_Windows_Setup.exe"
!endif

!ifndef INSTALL_DIR
  !define INSTALL_DIR "$LOCALAPPDATA\Programs\Aaalice NAI Launcher"
!endif

!ifndef APP_NAME
  !define APP_NAME "Aaalice NAI Launcher"
!endif

!ifndef APP_EXE
  !define APP_EXE "nai_launcher.exe"
!endif

!ifndef PUBLISHER
  !define PUBLISHER "Aaalice"
!endif

!ifndef UNINSTALL_KEY
  !define UNINSTALL_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\Aaalice NAI Launcher"
!endif

!ifndef PROCESS_QUERY_ACCESS
  !define PROCESS_QUERY_ACCESS 0x00001000
!endif

Name "${APP_NAME}"
OutFile "${OUT_FILE}"
InstallDir "${INSTALL_DIR}"
InstallDirRegKey HKCU "${UNINSTALL_KEY}" "InstallLocation"
RequestExecutionLevel user
SetCompressor /SOLID lzma
Unicode true

!define /math PROCESS_PATH_BUFFER_BYTES ${NSIS_MAX_STRLEN} * 2
!define PROCESS_ENTRY_SIZE 556

!define MUI_ABORTWARNING
!define MUI_FINISHPAGE_RUN "$INSTDIR\${APP_EXE}"
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES
!insertmacro MUI_LANGUAGE "SimpChinese"
!insertmacro MUI_LANGUAGE "English"

LangString AppRunningPrompt ${LANG_SIMPCHINESE} "检测到 ${APP_NAME} 仍在运行（关闭窗口可能只是缩到托盘）。安装程序将关闭应用后继续，是否现在关闭？"
LangString AppRunningPrompt ${LANG_ENGLISH} "${APP_NAME} is still running (closing its window may only hide it to the tray). Close it and continue setup?"
LangString AppCloseFailed ${LANG_SIMPCHINESE} "无法关闭正在运行的 ${APP_NAME}。请从系统托盘退出应用后重试。"
LangString AppCloseFailed ${LANG_ENGLISH} "Unable to close ${APP_NAME}. Exit it from the system tray and try again."
LangString AppInspectionFailed ${LANG_SIMPCHINESE} "无法确认正在运行的 ${APP_NAME} 是否来自当前安装目录，且安装目录内的 ${APP_EXE} 当前被占用。请从系统托盘退出应用后重试；若仍失败，可右键「开始」按钮以管理员身份运行终端，执行 taskkill /IM ${APP_EXE} /T /F 后重试。详情见安装目录下 install_diagnostics.log。"
LangString AppInspectionFailed ${LANG_ENGLISH} "Setup could not verify whether a running ${APP_NAME} belongs to this installation, and ${APP_EXE} in the installation folder is currently locked. Exit the app from the system tray and try again; if it still fails, run $\"taskkill /IM ${APP_EXE} /T /F$\" in a terminal opened as administrator and retry. See install_diagnostics.log in the installation folder for details."

Var TargetProcessId
Var ProcessInspectionFailed
Var ProcessInspectionStage
Var ProcessInspectionLastError
Var InspectionSuspectPid
Var ProbeAllowsInstall
Var ProbeLastError

!macro DefineProcessFunctions Prefix Mode
Function ${Prefix}FindInstalledAppProcess
  Push $R0
  Push $R1
  Push $R2
  Push $R3
  Push $R4
  Push $R5
  Push $R6
  Push $R7
  Push $R8
  Push $R9

  StrCpy $TargetProcessId "0"
  StrCpy $ProcessInspectionFailed "0"
  StrCpy $ProcessInspectionStage ""
  StrCpy $ProcessInspectionLastError ""
  StrCpy $InspectionSuspectPid ""
  ClearErrors
  GetFullPathName $R9 "$INSTDIR\${APP_EXE}"
  IfErrors find_process_snapshot_failed

  System::Call 'kernel32::CreateToolhelp32Snapshot(i 0x00000002, i 0) p .R0'
  StrCmp $R0 "-1" find_process_snapshot_failed
  StrCmp $R0 "0" find_process_snapshot_failed

  System::Call '*(i ${PROCESS_ENTRY_SIZE}, i, i, p, i, i, i, i, i, &w260) p .R1'
  StrCmp $R1 "0" find_process_enumeration_failed
  System::Call 'kernel32::Process32FirstW(p R0, p R1) i .R2 ?e'
  Pop $R3
  StrCmp $R2 "0" find_process_enumeration_done

find_process_loop:
  System::Call '*$R1(i, i, i .R4, p, i, i, i, i, i, &w260 .R8)'
  System::Call 'kernel32::lstrcmpiW(w R8, w "${APP_EXE}") i .R3'
  StrCmp $R3 "0" 0 find_process_next

  System::Call 'kernel32::OpenProcess(i ${PROCESS_QUERY_ACCESS}, i 0, i R4) p .R5 ?e'
  Pop $ProcessInspectionLastError
  StrCpy $InspectionSuspectPid $R4
  StrCmp $R5 "0" find_process_inspection_failed
  System::Alloc ${PROCESS_PATH_BUFFER_BYTES}
  Pop $R6
  StrCmp $R6 "0" find_process_close_failed_handle
  StrCpy $R7 ${NSIS_MAX_STRLEN}
  System::Call 'kernel32::QueryFullProcessImageNameW(p R5, i 0, p R6, *i R7) i .R8 ?e'
  Pop $ProcessInspectionLastError
  System::Call 'kernel32::CloseHandle(p R5)'
  StrCmp $R8 "0" find_process_free_path_failed
  System::Call '*$R6(&w${NSIS_MAX_STRLEN} .R7)'
  System::Call 'kernel32::lstrcmpiW(w R7, w R9) i .R8'
  StrCmp $R8 "0" find_process_found

  System::Free $R6

find_process_next:
  System::Call 'kernel32::Process32NextW(p R0, p R1) i .R2 ?e'
  Pop $R3
  StrCmp $R2 "0" find_process_enumeration_done find_process_loop

find_process_enumeration_done:
  StrCmp $R3 "18" find_process_cleanup
  Goto find_process_inspection_failed

find_process_found:
  System::Free $R6
  StrCpy $TargetProcessId $R4
  Goto find_process_cleanup

find_process_free_path_failed:
  System::Free $R6
  Goto find_process_inspection_failed

find_process_close_failed_handle:
  System::Call 'kernel32::CloseHandle(p R5)'

find_process_inspection_failed:
  StrCpy $ProcessInspectionFailed "1"
  StrCpy $ProcessInspectionStage "query"

find_process_cleanup:
  System::Free $R1
  System::Call 'kernel32::CloseHandle(p R0)'
  Goto find_process_done

find_process_enumeration_failed:
  StrCpy $ProcessInspectionFailed "1"
  StrCpy $ProcessInspectionStage "enumeration"
  System::Call 'kernel32::CloseHandle(p R0)'
  Goto find_process_done

find_process_snapshot_failed:
  StrCpy $ProcessInspectionFailed "1"
  StrCpy $ProcessInspectionStage "snapshot"

find_process_done:
  Pop $R9
  Pop $R8
  Pop $R7
  Pop $R6
  Pop $R5
  Pop $R4
  Pop $R3
  Pop $R2
  Pop $R1
  Pop $R0
FunctionEnd

Function ${Prefix}EnsureAppClosed
  Call ${Prefix}FindInstalledAppProcess
  StrCmp $ProcessInspectionFailed "1" process_inspection_failed
  StrCmp $TargetProcessId "0" app_closed

  IfSilent close_app 0
  MessageBox MB_ICONEXCLAMATION|MB_OKCANCEL "$(AppRunningPrompt)" IDOK close_app IDCANCEL cancel_install

close_app:
  nsExec::ExecToLog '"$SYSDIR\taskkill.exe" /PID $TargetProcessId /T /F'
  Sleep 1000
  Call ${Prefix}FindInstalledAppProcess
  StrCmp $ProcessInspectionFailed "1" process_inspection_failed
  StrCmp $TargetProcessId "0" app_closed

  IfSilent silent_close_failed 0
  MessageBox MB_ICONSTOP|MB_OK "$(AppCloseFailed)"
  Abort

silent_close_failed:
  SetErrorLevel 2
  Quit

process_inspection_failed:
  ; 进程查询失败不再直接阻断：先探目标 exe 文件锁并落诊断，
  ; 能证明无占用（文件可写打开或不存在）则放行，真被锁住才阻断。
  Call ${Prefix}HandleInspectionFailure
  StrCmp $ProbeAllowsInstall "1" app_closed process_inspection_blocked

process_inspection_blocked:
  IfSilent silent_inspection_failed 0
  MessageBox MB_ICONSTOP|MB_OK "$(AppInspectionFailed)"
  Abort

silent_inspection_failed:
  SetErrorLevel 3
  Quit

cancel_install:
  Abort

app_closed:
FunctionEnd

; 探测 $INSTDIR\${APP_EXE} 是否被占用：
; 以 GENERIC_WRITE、共享模式 0、OPEN_EXISTING 打开——
; 打开成功=无进程占用映像，可安全覆盖；ERROR_FILE_NOT_FOUND=全新安装目录；
; ERROR_SHARING_VIOLATION/ERROR_ACCESS_DENIED=文件真被占用，仍阻断；
; 其余错误保守阻断（维持 fail-closed 语义，仅放开「证明无占用」场景）。
Function ${Prefix}HandleInspectionFailure
  Push $R0
  StrCpy $ProbeAllowsInstall "0"

  ; 全新安装目录可能尚不存在（SetOutPath 在 Section 后段才建目录），
  ; 先建目录再探锁，缺目录才不会误报 ERROR_PATH_NOT_FOUND
  CreateDirectory "$INSTDIR"

  System::Call 'kernel32::CreateFileW(w "$INSTDIR\${APP_EXE}", i 0x40000000, i 0, p 0, i 3, i 0x80, p 0) p .R0 ?e'
  Pop $ProbeLastError
  StrCmp $R0 "-1" 0 probe_unlocked
  StrCmp $ProbeLastError "2" probe_allow
  Goto probe_finish

probe_unlocked:
  System::Call 'kernel32::CloseHandle(p R0)'
probe_allow:
  StrCpy $ProbeAllowsInstall "1"

probe_finish:
  Call ${Prefix}WriteInspectionDiagnostic
  Pop $R0
FunctionEnd

; 把进程检查失败详情落到 $INSTDIR\install_diagnostics.log（追加，UTF-16），
; 供用户排查与上报：失败阶段、GetLastError、疑似 PID、探锁结果与最终裁决。
Function ${Prefix}WriteInspectionDiagnostic
  Push $R0
  Push $R1
  Push $0
  Push $1
  Push $2
  Push $3
  Push $4
  Push $5
  Push $6
  Push $7

  CreateDirectory "$INSTDIR"
  ClearErrors
  FileOpen $R0 "$INSTDIR\install_diagnostics.log" a
  IfErrors diag_done

  System::Alloc 16
  Pop $R1
  StrCmp $R1 "0" diag_no_time
  System::Call 'kernel32::GetLocalTime(p R1)'
  System::Call '*$R1(&i2 .r0, &i2 .r1, &i2 .r2, &i2 .r3, &i2 .r4, &i2 .r5, &i2 .r6, &i2 .r7)'
  System::Free $R1
  FileWrite $R0 "=== ${APP_NAME} ${VERSION} process check diagnostic ===$\r$\n"
  FileWrite $R0 "Time: $0-$1-$3 $4:$5:$6.$7$\r$\n"
  Goto diag_body

diag_no_time:
  FileWrite $R0 "=== ${APP_NAME} ${VERSION} process check diagnostic ===$\r$\n"
  FileWrite $R0 "Time: unavailable$\r$\n"

diag_body:
  FileWrite $R0 "Phase: ${Mode}$\r$\n"
  FileWrite $R0 "Stage: $ProcessInspectionStage$\r$\n"
  FileWrite $R0 "InspectionLastError: $ProcessInspectionLastError$\r$\n"
  FileWrite $R0 "SuspectPid: $InspectionSuspectPid$\r$\n"
  FileWrite $R0 "Probe: CreateFileW(GENERIC_WRITE, share=0, OPEN_EXISTING) on $INSTDIR\${APP_EXE}$\r$\n"
  FileWrite $R0 "ProbeLastError: $ProbeLastError$\r$\n"
  StrCmp $ProbeAllowsInstall "1" 0 diag_blocked
  FileWrite $R0 "Decision: proceed (target file not locked)$\r$\n"
  Goto diag_close

diag_blocked:
  FileWrite $R0 "Decision: blocked (target file locked or probe failed)$\r$\n"

diag_close:
  FileClose $R0

diag_done:
  Pop $7
  Pop $6
  Pop $5
  Pop $4
  Pop $3
  Pop $2
  Pop $1
  Pop $0
  Pop $R1
  Pop $R0
FunctionEnd
!macroend

!insertmacro DefineProcessFunctions "" "install"
!insertmacro DefineProcessFunctions "un." "uninstall"

Section "${APP_NAME}" SecMain
  SectionIn RO

  Call EnsureAppClosed
  SetOverwrite on
  SetOutPath "$INSTDIR"
  File /r "${SOURCE_DIR}\*.*"

  WriteUninstaller "$INSTDIR\Uninstall.exe"

  CreateDirectory "$SMPROGRAMS\${APP_NAME}"
  CreateShortCut "$SMPROGRAMS\${APP_NAME}\${APP_NAME}.lnk" "$INSTDIR\${APP_EXE}"
  CreateShortCut "$SMPROGRAMS\${APP_NAME}\Uninstall ${APP_NAME}.lnk" "$INSTDIR\Uninstall.exe"

  WriteRegStr HKCU "${UNINSTALL_KEY}" "DisplayName" "${APP_NAME}"
  WriteRegStr HKCU "${UNINSTALL_KEY}" "DisplayVersion" "${VERSION}"
  WriteRegStr HKCU "${UNINSTALL_KEY}" "Publisher" "${PUBLISHER}"
  WriteRegStr HKCU "${UNINSTALL_KEY}" "InstallLocation" "$INSTDIR"
  WriteRegStr HKCU "${UNINSTALL_KEY}" "DisplayIcon" "$INSTDIR\${APP_EXE}"
  WriteRegStr HKCU "${UNINSTALL_KEY}" "UninstallString" '"$INSTDIR\Uninstall.exe"'
  WriteRegStr HKCU "${UNINSTALL_KEY}" "QuietUninstallString" '"$INSTDIR\Uninstall.exe" /S'
  WriteRegDWORD HKCU "${UNINSTALL_KEY}" "NoModify" 1
  WriteRegDWORD HKCU "${UNINSTALL_KEY}" "NoRepair" 1
SectionEnd

Section "Desktop Shortcut" SecDesktop
  CreateShortCut "$DESKTOP\${APP_NAME}.lnk" "$INSTDIR\${APP_EXE}"
SectionEnd

Section "Uninstall"
  Call un.EnsureAppClosed

  Delete "$DESKTOP\${APP_NAME}.lnk"
  Delete "$SMPROGRAMS\${APP_NAME}\${APP_NAME}.lnk"
  Delete "$SMPROGRAMS\${APP_NAME}\Uninstall ${APP_NAME}.lnk"
  RMDir "$SMPROGRAMS\${APP_NAME}"

  DeleteRegKey HKCU "${UNINSTALL_KEY}"
  RMDir /r "$INSTDIR"
SectionEnd
