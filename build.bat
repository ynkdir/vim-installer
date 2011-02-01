REM Create Vim Installer
REM
REM Requirements:
REM   Visual C++
REM     http://www.microsoft.com/express/Windows/
REM   Windows Installer XML (WiX) toolset
REM     http://wix.sourceforge.net/
REM   Mercurial
REM     http://mercurial.selenic.com/
REM   Wget
REM     http://www.gnu.org/software/wget/
REM   Unzip
REM     http://www.info-zip.org/UnZip.html
REM     ftp://ftp.info-zip.org/pub/infozip/win32/unz600xn.exe

setlocal

call :MAIN
exit /b


:CONFIG
  REM TODO
  exit /b


:UPDATE
  REM use "call hg" for hg.cmd
  if not exist vim (
    call hg clone https://vim.googlecode.com/hg/ vim
  )
  pushd vim
  call hg pull -uv
  popd
  exit /b


:COMPILE
  pushd vim\src
  nmake -f Make_mvc.mak USE_MSVCRT=1 FEATURES=HUGE MBYTE=yes
  if exist vim.exe.manifest (
    mt -nologo -manifest vim.exe.manifest -outputresource:vim.exe;1
  )
  nmake -f Make_mvc.mak USE_MSVCRT=1 FEATURES=HUGE MBYTE=yes GUI=yes IME=yes
  if exist gvim.exe.manifest (
    mt -nologo -manifest gvim.exe.manifest -outputresource:gvim.exe;1
  )
  popd
  exit /b


:PO
  pushd vim\src\po
  ..\vim -u NONE -c "g/^GETTEXT_PATH/s/.*/GETTEXT_PATH = ..\\..\\..\\gettext\\bin" -c "saveas! Make_mvc.mak2" -c "quit" Make_mvc.mak
  nmake -f Make_mvc.mak2
  popd
  exit /b


:GETTEXT
  set archive1=gettext-tools-dev_0.18.1.1-2_win32.zip
  set archive2=gettext-runtime_0.18.1.1-2_win32.zip
  if not exist %archive1% (
    wget "http://ftp.gnome.org/pub/gnome/binaries/win32/dependencies/%archive1%"
  )
  if not exist %archive2% (
    wget "http://ftp.gnome.org/pub/gnome/binaries/win32/dependencies/%archive2%"
  )
  if not exist gettext (
    unzip -d gettext %archive1%
    unzip -d gettext %archive2%
  )
  exit /b


:ICONV
  rem set archive=libiconv-1.9.1.bin.woe32.zip
  set archive=win-iconv-dll_tml-20100912_win32.zip
  if not exist %archive% (
    wget "http://ftp.gnome.org/pub/gnome/binaries/win32/dependencies/%archive%"
  )
  if not exist iconv (
    unzip -d iconv %archive%
  )
  exit /b


:DIST
  robocopy /MIR vim\runtime dist
  for %%i in (vim\src\po\*.mo) do (
    mkdir dist\lang\%%~ni\LC_MESSAGES
    copy %%i dist\lang\%%~ni\LC_MESSAGES\vim.mo
  )
  copy vim\src\vim.exe dist
  copy vim\src\gvim.exe dist
  copy vim\src\vimrun.exe dist
  copy vim\src\xxd\xxd.exe dist
  copy iconv\bin\iconv.dll dist
  REM TODO use -DGETTEXT_DLL=intl.dll, instead of rename.
  copy gettext\bin\intl.dll dist\libintl.dll
  exit /b


:WIX
  vim\src\vim -u versiondump.vim
  call version.bat
  heat dir dist -nologo -dr INSTALLDIR -cg MainFiles -ag -srd -sfrag -sreg -var var.dist -out filelist.wxs
  candle.exe -nologo -ddist=dist vim.wxs filelist.wxs MyWixUI_InstallDir.wxs ShortcutDlg.wxs
  light.exe -nologo -ext WixUIExtension -cultures:ja-jp -out vim-%VER_NAME%.msi -sw1076 vim.wixobj filelist.wixobj MyWixUI_InstallDir.wixobj ShortcutDlg.wixobj
  exit /b


:MAIN
  call :CONFIG
  call :GETTEXT
  call :ICONV
  call :UPDATE
  call :COMPILE
  call :PO
  call :DIST
  call :WIX
  exit /b

