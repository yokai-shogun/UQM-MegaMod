; Script generated by the HM NIS Edit Script Wizard.

Var PACKAGEDIR
Var UQMARGS
Var MAKEICON
Var UQMUSERDATA

; HM NIS Edit Wizard helper defines
!define PRODUCT_NAME "The Ur-Quan Masters"
!define PRODUCT_VERSION "0.8.0"
!define PRODUCT_WEB_SITE "http://sc2.sourceforge.net"
!define PRODUCT_DIR_REGKEY "Software\Microsoft\Windows\CurrentVersion\App Paths\uqm.exe"
!define PRODUCT_UNINST_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}"
!define PRODUCT_UNINST_ROOT_KEY "HKLM"
!define PRODUCT_STARTMENU_REGVAL "NSIS:StartMenuDir"

; The INSTALLER_VERSION is a suffix to the version number for installer patches or to mark
; alpha/beta/release candidate status. In normal releases it is the empty string.
!define INSTALLER_VERSION "b"

; UQM Package definitions
!include "packages.nsh"

; MUI 1.67 compatible ------
!include "MUI.nsh"

; Start using macros for block structure
!include "LogicLib.nsh"


; MUI Settings
!define MUI_ABORTWARNING
!define MUI_ICON "${NSISDIR}\Contrib\Graphics\Icons\win-install.ico"
!define MUI_UNICON "${NSISDIR}\Contrib\Graphics\Icons\win-uninstall.ico"
!define MUI_WELCOMEFINISHPAGE_BITMAP "orzshofixti.bmp"
!define MUI_HEADERIMAGE
!define MUI_HEADERIMAGE_BITMAP "ultron.bmp"
!define MUI_HEADERIMAGE_RIGHT

; UAC support
RequestExecutionLevel admin

; Welcome page
!insertmacro MUI_PAGE_WELCOME
; License page
!define MUI_LICENSEPAGE_BUTTON "Install"
!define MUI_LICENSEPAGE_TEXT_BOTTOM "Press the Install button to continue."
!insertmacro MUI_PAGE_LICENSE "COPYING.txt"
; Components page
!define MUI_COMPONENTSPAGE_TEXT_COMPLIST "You can preconfigure the options to mimic the original platforms by selecting those install types.  Note that more complete installs will need to download more packages."
!insertmacro MUI_PAGE_COMPONENTS
; Directory page
!insertmacro MUI_PAGE_DIRECTORY
; Package Dictory
!define MUI_PAGE_HEADER_TEXT "Choose Package Location"
!define MUI_PAGE_HEADER_SUBTEXT "Choose the folder that holds packages that have already been downloaded."
!define MUI_DIRECTORYPAGE_TEXT_TOP "Setup will look for already-downloaded content packages in the following folder.  To copy them from a different folder, click Browse and select another folder.  If you are doing a net install, leave this field alone. Click Next to continue."
!define MUI_DIRECTORYPAGE_TEXT_DESTINATION "Source Folder"
!define MUI_DIRECTORYPAGE_VARIABLE $PACKAGEDIR
!define MUI_DIRECTORYPAGE_VERIFYONLEAVE
!insertmacro MUI_PAGE_DIRECTORY
; Start menu page
var ICONS_GROUP
!define MUI_STARTMENUPAGE_NODISABLE
!define MUI_STARTMENUPAGE_DEFAULTFOLDER "Games\The Ur-Quan Masters"
!define MUI_STARTMENUPAGE_REGISTRY_ROOT "${PRODUCT_UNINST_ROOT_KEY}"
!define MUI_STARTMENUPAGE_REGISTRY_KEY "${PRODUCT_UNINST_KEY}"
!define MUI_STARTMENUPAGE_REGISTRY_VALUENAME "${PRODUCT_STARTMENU_REGVAL}"
!insertmacro MUI_PAGE_STARTMENU Application $ICONS_GROUP
; Instfiles page
!insertmacro MUI_PAGE_INSTFILES
; Finish page
!define MUI_FINISHPAGE_RUN_NOTCHECKED
!define MUI_FINISHPAGE_NOREBOOTSUPPORT
!define MUI_FINISHPAGE_SHOWREADME "$INSTDIR\README.txt"
!define MUI_FINISHPAGE_RUN "$INSTDIR\uqm.exe"
!define MUI_FINISHPAGE_RUN_PARAMETERS $UQMARGS
!insertmacro MUI_PAGE_FINISH

; Uninstaller pages
!define MUI_UNCONFIRMPAGE_TEXT_TOP "This program will now uninstall The Ur-Quan Masters entirely.  If you wish to preserve content or expansion packs, select Cancel now and back them up.  Otherwise, press Uninstall to continue."
!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

; Language files
!insertmacro MUI_LANGUAGE "English"

; MUI end ------

Name "${PRODUCT_NAME} ${PRODUCT_VERSION}"
OutFile "uqm-${PRODUCT_VERSION}${INSTALLER_VERSION}-installer.exe"
InstallDir "$PROGRAMFILES\The Ur-Quan Masters\"
InstallDirRegKey HKLM "${PRODUCT_DIR_REGKEY}" ""
ShowInstDetails show
ShowUnInstDetails show
AllowRootDirInstall true
DirText "" "" "" "Please select a folder."
InstType "Typical"
InstType "Minimal"
InstType "Mimic PC"
InstType "Mimic 3DO"
InstType "No Content"
InstType "All Expansions"

Function .onInit
  Push $0
  StrCpy $PACKAGEDIR $EXEDIR
  StrCpy $UQMARGS ""
  StrCpy $MAKEICON 0
  ReadEnvStr $0 APPDATA
  ${If} $0 == ""
    ReadEnvStr $0 USERPROFILE
    ${If} $0 == ""
      StrCpy $UQMUSERDATA "$INSTDIR\userdata\uqm"
    ${Else}
      ExpandEnvStrings $UQMUSERDATA "%USERPROFILE%\Application Data\uqm"
    ${EndIf}
  ${Else}
    ExpandEnvStrings $UQMUSERDATA "%APPDATA%\uqm"
  ${EndIf}
FunctionEnd

# To use:
# Push the file name.
# Push the installation location.
# It will install it from the Package Directory if necessary; otherwise it
# will download it to a temp file and install that.
Var DOWNLOADTARGET
Var MANDATORY
Var MD5SUM
Var DOWNLOADPATH
Function HandlePackage
  Exch $0 # File location
  Exch
  Exch $1 # File name
  Push $2
  Push $3
  StrCpy $R9 0 # failure count
  # Check to make sure the file wasn't already installed
  ${If} ${FileExists} "$0\$1"
    md5dll::GetFileMD5 "$0\$1"
    Pop $3
    ${If} $MD5SUM == $3
      MessageBox MB_ICONINFORMATION|MB_OK "The package $1 has already been installed."
      Goto PackageDone
    ${EndIf}
  ${EndIf}
  # It's not installed, so check if it's in the package dir.
  SetOutPath "$0"
  SetOverwrite ifdiff
  ${If} ${FileExists} "$PACKAGEDIR\$1"
    md5dll::GetFileMD5 "$PACKAGEDIR\$1"
    Pop $3
    ${If} $MD5SUM != $3
      MessageBox MB_ICONINFORMATION|MB_OKCANCEL "The file $PACKAGEDIR\$1 appears to be corrupt.  The expected MD5 sum was '$MD5SUM', but the actual MD5 sum was '$3'.  Press OK to attempt to download a fresh copy from the distribution site, or Cancel to skip the package." IDOK AttemptDownload IDCANCEL PackageDone
    ${EndIf}
    CopyFiles "$PACKAGEDIR\$1" "$0\$1"
    Goto PackageDone
  ${EndIf}
  # It's not in the package dir, but check if it's there but an over-helpful
  # browser stuck a .zip at the end
  ${If} ${FileExists} "$PACKAGEDIR\$1.zip"
    md5dll::GetFileMD5 "$PACKAGEDIR\$1.zip"
    Pop $3
    ${If} $MD5SUM != $3
      MessageBox MB_ICONINFORMATION|MB_OKCANCEL "The file $PACKAGEDIR\$1.zip appears to be corrupt.  The expected MD5 sum was '$MD5SUM', but the actual MD5 sum was '$3'.  Press OK to attempt to download a fresh copy from the distribution site, or Cancel to skip the package." IDOK AttemptDownload IDCANCEL PackageDone
    ${EndIf}
    CopyFiles "$PACKAGEDIR\$1.zip" "$0\$1"
    Goto PackageDone
  ${EndIf}

  # We're now in a loop of trying to download the file until the user gives
  # up. Since the only way to iterate through the loop more than once is to
  # have the user reply to a message box, this loop is still marked by a
  # label instead of being part of a Do/Loop macro.
AttemptDownload:
  GetTempFileName $DOWNLOADTARGET
  Delete $DOWNLOADTARGET
  CreateDirectory $DOWNLOADTARGET
  inetc::get "https://downloads.sourceforge.net/project/sc2/$DOWNLOADPATH$1" "$DOWNLOADTARGET/$1" /END
  Pop $2
  ${If} $2 == "OK"
    # Download completed. Confirm the MD5 sum is OK.
    md5dll::GetFileMD5 "$DOWNLOADTARGET\$1"
    Pop $3
    ${If} $MD5SUM != $3
      ${If} $MANDATORY != 0
        StrCpy $3 "THIS IS A MANDATORY PACKAGE.  Without this package, $(^Name) will NOT run."
      ${Else}
        StrCpy $3 "This is an optional package.  $(^Name) will still run, but some content will not be available."
      ${EndIf}
      MessageBox MB_ICONEXCLAMATION|MB_YESNO "The downloaded file $1 doesn't match the internal MD5 sum.  This probably means the download was corrupt.  $3  Do you want to retry from a different mirror?  (Select NO to install the downloaded package anyway - for instance, if you know that the content pack was upgraded or modified since.)" IDYES AttemptDownload
    ${EndIf}
    CopyFiles "$DOWNLOADTARGET\$1" "$0\$1"
  ${Else}
    ${If} $2 == "Cancelled"
      StrCpy $2 "Download was canceled by user."
    ${Else}
      StrCpy $2 "Could not install the package $1 due to the following error: $\"$2$\"."
    ${EndIf}
    ${If} $MANDATORY != 0
      StrCpy $3 "THIS IS A MANDATORY PACKAGE.  Without this package, $(^Name) will NOT run."
    ${Else}
      StrCpy $3 "This is an optional package.  $(^Name) will still run, but some content will not be available."
    ${EndIf}
    MessageBox MB_ICONEXCLAMATION|MB_YESNO "$2  $3  Do you want to retry from a different mirror?" IDYES AttemptDownload
  ${EndIf}
  RmDir /r $DOWNLOADTARGET
PackageDone:
  Pop $3
  Pop $2
  Pop $1
  Pop $0
FunctionEnd

# Usage:
# Push the file name, preferrably a full path.
# Push the string to be appended
# Any errors during appending will be ignored.
Function AppendToFile
  Exch $0 # string to append
  Exch
  Exch $1 # File name
  Push $2 # using $2 for file handle
  FileOpen $2 $1 a
  ${Unless} ${Errors}
    FileSeek $2 0 END  # seek to end
    FileWrite $2 $0
    FileClose $2
  ${EndUnless}
  Pop $2
  Pop $1
  Pop $0
FunctionEnd

Function EnableRemixes
  # If there are errors pending AppendToFile will fail
  ClearErrors
  Push "$UQMUSERDATA\uqm.cfg"
  Push "remixmusic = BOOLEAN:true$\r$\n"
  Call AppendToFile
  ClearErrors
FunctionEnd

SectionGroup "!UQM" SECGRP01
  Section "Executable" SEC01
    SectionIn 1 2 3 4 5 6 RO
    SetOutPath "$INSTDIR"
    SetOverwrite try
    File "AUTHORS.txt"
    File "COPYING.txt"
    File "Manual.txt"
    File "README.txt"
    File "README-SDL.txt"
    File "WhatsNew.txt"
!include "dlls.nsi"

    SetOutPath $UQMUSERDATA
    SetOverwrite try
    File "uqm-pc.cfg"
    File "uqm-3do.cfg"

    # Delete old content
    Delete "$INSTDIR\content\packages\uqm-0.3-3domusic.zip"
    Delete "$INSTDIR\content\packages\uqm-0.3-voice.zip"
    Delete "$INSTDIR\content\packages\uqm-0.3-content.zip"
    Delete "$INSTDIR\content\packages\uqm-0.4.0-3domusic.uqm"
    Delete "$INSTDIR\content\packages\uqm-0.4.0-voice.uqm"
    Delete "$INSTDIR\content\packages\uqm-0.4.0-content.uqm"
    Delete "$INSTDIR\content\packages\uqm-0.5.0-3domusic.uqm"
    Delete "$INSTDIR\content\packages\uqm-0.5.0-voice.uqm"
    Delete "$INSTDIR\content\packages\uqm-0.5.0-content.uqm"
    Delete "$INSTDIR\content\packages\uqm-0.6.0-3domusic.uqm"
    Delete "$INSTDIR\content\packages\uqm-0.6.0-voice.uqm"
    Delete "$INSTDIR\content\packages\uqm-0.6.0-content.uqm"
    Delete "$INSTDIR\content\packages\uqm-0.7.0-3domusic.uqm"
    Delete "$INSTDIR\content\packages\uqm-0.7.0-voice.uqm"
    Delete "$INSTDIR\content\packages\uqm-0.7.0-content.uqm"
    # and in a case of manual install and overly helpful browsers
    Delete "$INSTDIR\content\packages\uqm-0.7.0-3domusic.uqm.zip"
    Delete "$INSTDIR\content\packages\uqm-0.7.0-voice.uqm.zip"
    Delete "$INSTDIR\content\packages\uqm-0.7.0-content.uqm.zip"

  ; Shortcuts
    !insertmacro MUI_STARTMENU_WRITE_BEGIN Application
    !insertmacro MUI_STARTMENU_WRITE_END
  SectionEnd

  Section "Core Data" SEC02
    SectionIn 1 2 3 4 6
    CreateDirectory "$INSTDIR\content\addons"
    SetOutPath "$INSTDIR\content"
    SetOverwrite ifnewer
    AddSize ${PKG_CONTENT_SIZE}
    StrCpy $MANDATORY 1
    StrCpy $MD5SUM "${PKG_CONTENT_MD5SUM}"
    File "..\..\content\version"
    StrCpy $DOWNLOADPATH "UQM/0.8/"
    Push "${PKG_CONTENT_FILE}"
    Push "$INSTDIR\content\packages"
    Call HandlePackage

    ; Shortcuts
    !insertmacro MUI_STARTMENU_WRITE_BEGIN Application
    !insertmacro MUI_STARTMENU_WRITE_END
  SectionEnd

  Section "Desktop Icon" SECICON
    SectionIn 1 2 3 4 5 6
    StrCpy $MAKEICON 1
  SectionEnd
SectionGroupEnd

SectionGroup /e "3DO Content" SECGRP02
  Section "Music" SEC03
    SectionIn 1 4 6
    AddSize ${PKG_3DOMUSIC_SIZE}
    StrCpy $MANDATORY 0
    StrCpy $MD5SUM "${PKG_3DOMUSIC_MD5SUM}"
    StrCpy $DOWNLOADPATH "UQM/0.8/"
    Push "${PKG_3DOMUSIC_FILE}"
    Push "$INSTDIR\content\addons"
    Call HandlePackage
  ; Shortcuts
    !insertmacro MUI_STARTMENU_WRITE_BEGIN Application
    !insertmacro MUI_STARTMENU_WRITE_END
  SectionEnd

  Section "Voiceovers" SEC04
    SectionIn 1 4 6
    AddSize ${PKG_VOICE_SIZE}
    StrCpy $MANDATORY 0
    StrCpy $MD5SUM "${PKG_VOICE_MD5SUM}"
    StrCpy $DOWNLOADPATH "UQM/0.8/"
    Push "${PKG_VOICE_FILE}"
    Push "$INSTDIR\content\addons"
    Call HandlePackage
  ; Shortcuts
    !insertmacro MUI_STARTMENU_WRITE_BEGIN Application
    !insertmacro MUI_STARTMENU_WRITE_END
  SectionEnd
SectionGroupEnd

SectionGroup "Modern Remixes" SECGRP03
  Section "Pack 1" SEC05
    SectionIn 6
    AddSize ${PKG_REMIX1_SIZE}
    StrCpy $MANDATORY 0
    StrCpy $MD5SUM "${PKG_REMIX1_MD5SUM}"
    StrCpy $DOWNLOADPATH "UQM%20Remix%20Packs/UQM%20Remix%20Pack%201/"
    Push "${PKG_REMIX1_FILE}"
    Push "$INSTDIR\content\addons"
    Call HandlePackage
    Call EnableRemixes
  ; Shortcuts
    !insertmacro MUI_STARTMENU_WRITE_BEGIN Application
    !insertmacro MUI_STARTMENU_WRITE_END
  SectionEnd

  Section "Pack 2" SEC06
    SectionIn 6
    AddSize ${PKG_REMIX2_SIZE}
    StrCpy $MANDATORY 0
    StrCpy $MD5SUM "${PKG_REMIX2_MD5SUM}"
    StrCpy $DOWNLOADPATH "UQM%20Remix%20Packs/UQM%20Remix%20Pack%202/"
    Push "${PKG_REMIX2_FILE}"
    Push "$INSTDIR\content\addons"
    Call HandlePackage
    Call EnableRemixes
  ; Shortcuts
    !insertmacro MUI_STARTMENU_WRITE_BEGIN Application
    !insertmacro MUI_STARTMENU_WRITE_END
  SectionEnd

  Section "Pack 3" SEC07
    SectionIn 6
    AddSize ${PKG_REMIX3_SIZE}
    StrCpy $MANDATORY 0
    StrCpy $MD5SUM "${PKG_REMIX3_MD5SUM}"
    StrCpy $DOWNLOADPATH "UQM%20Remix%20Packs/UQM%20Remix%20Pack%203/"
    Push "${PKG_REMIX3_FILE}"
    Push "$INSTDIR\content\addons"
    Call HandlePackage
    Call EnableRemixes
  ; Shortcuts
    !insertmacro MUI_STARTMENU_WRITE_BEGIN Application
    !insertmacro MUI_STARTMENU_WRITE_END
  SectionEnd

  Section "Pack 4" SEC08
    SectionIn 6
    AddSize ${PKG_REMIX4_SIZE}
    StrCpy $MANDATORY 0
    StrCpy $MD5SUM "${PKG_REMIX4_MD5SUM}"
    StrCpy $DOWNLOADPATH "UQM%20Remix%20Packs/UQM%20Remix%20Pack%204/"
    Push "${PKG_REMIX4_FILE}"
    Push "$INSTDIR\content\addons"
    Call HandlePackage
    Call EnableRemixes
  ; Shortcuts
    !insertmacro MUI_STARTMENU_WRITE_BEGIN Application
    !insertmacro MUI_STARTMENU_WRITE_END
  SectionEnd
SectionGroupEnd

Section -ShortcutsAndIcons
  SetOutPath $INSTDIR
  !insertmacro MUI_STARTMENU_WRITE_BEGIN Application
    CreateDirectory "$SMPROGRAMS\$ICONS_GROUP"
    CreateShortCut "$SMPROGRAMS\$ICONS_GROUP\The Ur-Quan Masters.lnk" "$INSTDIR\uqm.exe" $UQMARGS
    CreateShortCut "$SMPROGRAMS\$ICONS_GROUP\UQM (Safe Mode).lnk" "$INSTDIR\uqm.exe" "-x --safe"
    CreateShortCut "$SMPROGRAMS\$ICONS_GROUP\UQM (Safe OpenGL).lnk" "$INSTDIR\uqm.exe" "-o --safe"
    CreateDirectory "$SMPROGRAMS\$ICONS_GROUP\Documentation"
    CreateShortCut "$SMPROGRAMS\$ICONS_GROUP\Documentation\AUTHORS.lnk" "$INSTDIR\AUTHORS.txt"
    CreateShortCut "$SMPROGRAMS\$ICONS_GROUP\Documentation\COPYING.lnk" "$INSTDIR\COPYING.txt"
    CreateShortCut "$SMPROGRAMS\$ICONS_GROUP\Documentation\Manual.lnk" "$INSTDIR\Manual.txt"
    CreateShortCut "$SMPROGRAMS\$ICONS_GROUP\Documentation\README.lnk" "$INSTDIR\README.txt"
    CreateShortCut "$SMPROGRAMS\$ICONS_GROUP\Documentation\WhatsNew.lnk" "$INSTDIR\WhatsNew.txt"
    CreateShortCut "$SMPROGRAMS\$ICONS_GROUP\Keyboard Test.lnk" "$INSTDIR\keyjam.exe"
    CreateShortCut "$SMPROGRAMS\$ICONS_GROUP\Saved Games.lnk" "$UQMUSERDATA\save"
    ${If} $MAKEICON = 1
      CreateShortCut "$DESKTOP\The Ur-Quan Masters.lnk" "$INSTDIR\uqm.exe" $UQMARGS
    ${EndIf}
    CreateShortCut "$SMPROGRAMS\$ICONS_GROUP\Uninstall.lnk" "$INSTDIR\uninst.exe"
  !insertmacro MUI_STARTMENU_WRITE_END
SectionEnd

Section -Set3DOConfig
  SectionIn 4
  !insertmacro MUI_STARTMENU_WRITE_BEGIN Application
    SetOutPath $UQMUSERDATA
    Delete "uqm.cfg"
    CopyFiles "$UQMUSERDATA\uqm-3do.cfg" "$UQMUSERDATA\uqm.cfg"
  !insertmacro MUI_STARTMENU_WRITE_END
SectionEnd

Section -SetPCConfig
  SectionIn 3
  !insertmacro MUI_STARTMENU_WRITE_BEGIN Application
    SetOutPath $UQMUSERDATA
    Delete "uqm.cfg"
    CopyFiles "$UQMUSERDATA\uqm-pc.cfg" "$UQMUSERDATA\uqm.cfg"
  !insertmacro MUI_STARTMENU_WRITE_END
SectionEnd

Section -SetRemixConfig
  !insertmacro MUI_STARTMENU_WRITE_BEGIN Application
  !insertmacro MUI_STARTMENU_WRITE_END
SectionEnd

Section -Post
  WriteUninstaller "$INSTDIR\uninst.exe"
  WriteRegStr HKLM "${PRODUCT_DIR_REGKEY}" "" "$INSTDIR\uqm.exe"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayName" "$(^Name)"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "UninstallString" "$INSTDIR\uninst.exe"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayIcon" "$INSTDIR\uqm.exe"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "DisplayVersion" "${PRODUCT_VERSION}"
  WriteRegStr ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}" "URLInfoAbout" "${PRODUCT_WEB_SITE}"
SectionEnd

; Section descriptions
!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
  !insertmacro MUI_DESCRIPTION_TEXT ${SECGRP01} "The core executables and content libraries for The Ur-Quan Masters.  All elements in this section must be installed for the game to be playable."
  !insertmacro MUI_DESCRIPTION_TEXT ${SEC01} "Includes the main program, all subsidiary libraries, and basic documentation for The Ur-Quan Masters.  Required for play."
  !insertmacro MUI_DESCRIPTION_TEXT ${SEC02} "Graphics, sound, and the PC-edition music for The Ur-Quan Masters.  Required for play.  If this package is selected and not present in the packages directory, the installer will attempt to download it."
  !insertmacro MUI_DESCRIPTION_TEXT ${SECICON} "Adds a desktop icon linking directly to The Ur-Quan Masters."
  !insertmacro MUI_DESCRIPTION_TEXT ${SECGRP02} "Optional content packages containing music and sound unique to the 1993 3DO release."
  !insertmacro MUI_DESCRIPTION_TEXT ${SEC03} "Optional package which includes the remixed songs from the 3DO release.  If this package is selected and not present in the packages directory, the installer will attempt to download it."
  !insertmacro MUI_DESCRIPTION_TEXT ${SEC04} "Optional package containing the voiceovers from the 3DO release.  If this package is selected and not present in the packages directory, the installer will attempt to download it."
  !insertmacro MUI_DESCRIPTION_TEXT ${SECGRP03} "Optional content packages containing the official UQM remixes by The Precursors.  Selecting any element from this group will also enable the 'remix' addon by default in the starting configuration."
  !insertmacro MUI_DESCRIPTION_TEXT ${SEC05} `Ur-Quan Masters Remix Pack 1 - 'Super Melee!'  Optional add-on music package.  If this package is selected and not present in the packages directory, the installer will attempt to download it.`
  !insertmacro MUI_DESCRIPTION_TEXT ${SEC06} `Ur-Quan Masters Remix Pack 2 - 'Neutral Aliens - Don't Shoot!'  Optional add-on music package.  If this package is selected and not present in the packages directory, the installer will attempt to download it.`
  !insertmacro MUI_DESCRIPTION_TEXT ${SEC07} `Ur-Quan Masters Remix Pack 3 - 'The Ur-Quan Hierarchy.'  Optional add-on music package.  If this package is selected and not present in the packages directory, the installer will attempt to download it.`
  !insertmacro MUI_DESCRIPTION_TEXT ${SEC08} `Ur-Quan Masters Remix Pack 4 - 'The New Alliance of Free Stars.'  Optional add-on music package.  If this package is selected and not present in the packages directory, the installer will attempt to download it.`
!insertmacro MUI_FUNCTION_DESCRIPTION_END


Function un.onUninstSuccess
  HideWindow
  MessageBox MB_ICONINFORMATION|MB_OK "$(^Name) was successfully removed from your computer."
FunctionEnd

Function un.onInit
  MessageBox MB_ICONQUESTION|MB_YESNO|MB_DEFBUTTON2 "Are you sure you want to completely remove $(^Name) and all of its components?" IDYES +2
  Abort
FunctionEnd

Section Uninstall
  !insertmacro MUI_STARTMENU_GETFOLDER "Application" $ICONS_GROUP
  Delete "$INSTDIR\uninst.exe"
  Delete "$INSTDIR\content\packages\addons\remix\uqm-remix-pack4.zip"
  Delete "$INSTDIR\content\packages\addons\remix\uqm-remix-pack3.zip"
  Delete "$INSTDIR\content\packages\addons\remix\uqm-remix-pack2.zip"
  Delete "$INSTDIR\content\packages\addons\remix\uqm-remix-pack1.zip"
  Delete "$INSTDIR\content\addons\uqm-remix-disc4.uqm"
  Delete "$INSTDIR\content\addons\uqm-remix-disc3.uqm"
  Delete "$INSTDIR\content\addons\uqm-remix-disc2.uqm"
  Delete "$INSTDIR\content\addons\uqm-remix-disc1.uqm"
  Delete "$INSTDIR\content\addons\${PKG_VOICE_FILE}"
  Delete "$INSTDIR\content\addons\${PKG_3DOMUSIC_FILE}"
  Delete "$INSTDIR\content\packages\${PKG_CONTENT_FILE}"
  Delete "$INSTDIR\content\version"
  Delete "$INSTDIR\zlib.dll"
  Delete "$INSTDIR\zlib1.dll"
  Delete "$INSTDIR\WhatsNew.txt"
  Delete "$INSTDIR\vorbisfile.dll"
  Delete "$INSTDIR\vorbis.dll"
  Delete "$INSTDIR\uqm.exe"
  Delete "$INSTDIR\keyjam.exe"
  Delete "$INSTDIR\SDL_gfx.dll"
  Delete "$INSTDIR\SDL_image.dll"
  Delete "$INSTDIR\SDL.dll"
  Delete "$INSTDIR\README.txt"
  Delete "$INSTDIR\README-SDL.txt"
  Delete "$INSTDIR\wrap_oal.dll"
  Delete "$INSTDIR\OpenAL32.dll"
  Delete "$INSTDIR\ogg.dll"
  Delete "$INSTDIR\Manual.txt"
  Delete "$INSTDIR\libpng13.dll"
  Delete "$INSTDIR\libpng12.dll"
  Delete "$INSTDIR\libpng12-0.dll"
  Delete "$INSTDIR\COPYING.txt"
  Delete "$INSTDIR\AUTHORS.txt"
  Delete "$INSTDIR\stderr.txt"

!include "undlls.nsi"

  Delete "$SMPROGRAMS\$ICONS_GROUP\Uninstall.lnk"
  Delete "$SMPROGRAMS\$ICONS_GROUP\Options Configuration.lnk"
  Delete "$SMPROGRAMS\$ICONS_GROUP\Key Configuration.lnk"
  Delete "$SMPROGRAMS\$ICONS_GROUP\Keyboard Test.lnk"
  Delete "$SMPROGRAMS\$ICONS_GROUP\Saved Games.lnk"
  Delete "$DESKTOP\The Ur-Quan Masters.lnk"
  Delete "$SMPROGRAMS\$ICONS_GROUP\The Ur-Quan Masters.lnk"
  Delete "$SMPROGRAMS\$ICONS_GROUP\UQM (Safe Mode).lnk"
  Delete "$SMPROGRAMS\$ICONS_GROUP\UQM (Safe OpenGL).lnk"
  Delete "$SMPROGRAMS\$ICONS_GROUP\Documentation\AUTHORS.lnk"
  Delete "$SMPROGRAMS\$ICONS_GROUP\Documentation\COPYING.lnk"
  Delete "$SMPROGRAMS\$ICONS_GROUP\Documentation\Manual.lnk"
  Delete "$SMPROGRAMS\$ICONS_GROUP\Documentation\README.lnk"
  Delete "$SMPROGRAMS\$ICONS_GROUP\Documentation\WhatsNew.lnk"

  RMDir "$SMPROGRAMS\$ICONS_GROUP\Documentation"
  RMDir "$SMPROGRAMS\$ICONS_GROUP"
  RMDir "$INSTDIR\content\addons"
  RMDir "$INSTDIR\content\packages\addons\remix"
  RMDir "$INSTDIR\content\packages\addons"
  RMDir "$INSTDIR\content\packages"
  RMDir "$INSTDIR\content"
  RMDir "$INSTDIR"

  DeleteRegKey ${PRODUCT_UNINST_ROOT_KEY} "${PRODUCT_UNINST_KEY}"
  DeleteRegKey HKLM "${PRODUCT_DIR_REGKEY}"
  SetAutoClose true
SectionEnd
