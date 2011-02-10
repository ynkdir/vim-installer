REM Create Vim Installer
REM
REM Requirements:
REM   Visual C++
REM     http://www.microsoft.com/express/Windows/
REM   Windows Installer XML (WiX) toolset
REM     http://wix.sourceforge.net/
REM   Mercurial
REM     http://mercurial.selenic.com/

setlocal

call :MAIN
exit /b


:CONFIG
  SET wget=cscript //nologo scripts\httpget.js
  SET unzip=cscript //nologo scripts\unzip.js
  SET INTLDLL=intl.dll
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
  SET DEFINES=
  if "%INTLDLL%" neq "libintl.dll" (
    SET DEFINES=%DEFINES% -DGETTEXT_DLL=\\\"%INTLDLL%\\\"
  )
  REM SET DEFINES=%DEFINES% -DDYNAMIC_ICONV_DLL=\\\"iconv.dll\\\"
  REM SET DEFINES=%DEFINES% -DDYNAMIC_ICONV_DLL_ALT=\\\"libiconv.dll\\\"

  pushd vim\src
  nmake -f Make_mvc.mak USE_MSVCRT=1 FEATURES=HUGE MBYTE=yes "DEFINES=%DEFINES%"
  if exist vim.exe.manifest (
    mt -nologo -manifest vim.exe.manifest -outputresource:vim.exe;1
  )
  nmake -f Make_mvc.mak USE_MSVCRT=1 FEATURES=HUGE MBYTE=yes GUI=yes IME=yes OLE=yes "DEFINES=%DEFINES%"
  if exist gvim.exe.manifest (
    mt -nologo -manifest gvim.exe.manifest -outputresource:gvim.exe;1
  )
  popd

  REM WORKAROUND: compile gvimext with -MD and -DGETTEXT_DLL
  if "%INTLDLL%" neq "libintl.dll" (
    pushd vim\src\GvimExt
    ..\vim -u NONE ^
      -c "%%s/cvarsmt/cvarsdll/" ^
      -c "/!include <win32.mak>/" ^
      -c "put='cflags = $(cflags) -DGETTEXT_DLL=\\\\\"%INTLDLL\\\\\"'" ^
      -c "saveas! Makefile2" ^
      -c "quit" ^
      Makefile
    nmake -f Makefile2 clean
    nmake -f Makefile2
    popd
  )

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
    %wget% "http://ftp.gnome.org/pub/gnome/binaries/win32/dependencies/%archive1%"
  )
  if not exist %archive2% (
    %wget% "http://ftp.gnome.org/pub/gnome/binaries/win32/dependencies/%archive2%"
  )
  if not exist gettext (
    %unzip% -d gettext %archive1%
    %unzip% -d gettext %archive2%
  )
  exit /b


:ICONV
  rem set archive=libiconv-1.9.1.bin.woe32.zip
  set archive=win-iconv-dll_tml-20100912_win32.zip
  if not exist %archive% (
    %wget% "http://ftp.gnome.org/pub/gnome/binaries/win32/dependencies/%archive%"
  )
  if not exist iconv (
    %unzip% -d iconv %archive%
  )
  exit /b


:DIFF
  set archive=diffutils-3.0-win32.zip
  if not exist %archive% (
    %wget% "https://github.com/downloads/ynkdir/vim-installer/%archive%"
  )
  if not exist diff (
    %unzip% -d diff %archive%
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
  copy vim\src\GvimExt\gvimext.dll dist
  copy vim\src\VisVim\VisVim.dll dist
  copy vim\src\VisVim\README_VisVim.txt dist
  copy vim\vimtutor.bat dist
  copy vim\README.txt dist
  copy vim\src\vim.pdb dist
  copy vim\src\gvim.pdb dist
  copy diff\bin\diff.exe dist
  copy iconv\bin\iconv.dll dist
  copy gettext\bin\intl.dll dist
  exit /b


:VIMLICENSE
  REM cd vim\runtime\doc && make uganda.nsis.txt
  vim\src\vim -u NONE ^
    -c "%%s/[ 	]*\*[-a-zA-Z0-9.]*\*//g" ^
    -c "%%s/vim:tw=78://" ^
    -c "g/$/if getline(line('.')) == getline(line('.') + 1) | delete _ | endif" ^
    -c "saveas! vimlicense.rtf" ^
    -c "quit" ^
    vim\runtime\doc\uganda.txt
  REM convert to rtf
  vim\src\vim -u NONE ^
    -c "%%s/$/\\par/" ^
    -c "%%s/\t\+/\=repeat('\tab', len(submatch(0))) . ' '/g" ^
    -c "0put='{\rtf1\ansi\deff0{\fonttbl{\f0\fnil\fcharset1 Arial;}}\f0\fs16'" ^
    -c "join!" ^
    -c "$put='}'" ^
    -c "write!" ^
    -c "quit" ^
    vimlicense.rtf
  exit /b


:WIX
  REM [Automation Interface Reference]
  REM http://msdn.microsoft.com/en-us/library/aa367810%28v=VS.85%29.aspx
  REM [Multi-Language MSI Packages without Setup.exe Launcher]
  REM http://www.installsite.org/pages/en/msi/articles/embeddedlang/index.htm

  vim\src\vim -u versiondump.vim
  call version.bat

  SET SRCS=vim.wxs filelist.wxs
  SET OBJS=vim.wixobj filelist.wixobj
  SET TARGET=vim-%VER_NAME%.msi

  REM exclude special files from heat.
  move dist\gvim.exe .
  move dist\gvimext.dll .
  move dist\VisVim.dll .
  move dist\README_VisVim.txt .

  heat dir dist -nologo -dr INSTALLDIR -cg MainFiles -ag -srd -sfrag -sreg -var var.dist -out filelist.wxs

  move gvim.exe dist
  move gvimext.dll dist
  move VisVim.dll dist
  move README_VisVim.txt dist

  candle.exe -nologo -ddist=dist -dlang=1033 -dcodepage=1252 %SRCS%
  light.exe -nologo -ext WixUIExtension -cultures:en-us -loc loc_en-us.wxl -out %TARGET% -sw1076 %OBJS%

  candle.exe -nologo -ddist=dist -dlang=1041 -dcodepage=932 %SRCS%
  light.exe -nologo -ext WixUIExtension -cultures:ja-jp -loc loc_ja-jp.wxl -out ja-jp.msi -sw1076 %OBJS%
  torch.exe -nologo -p -t language %TARGET% ja-jp.msi -out ja-jp.mst

  cscript //nologo msiscripts\WiSubStg.vbs %TARGET% ja-jp.mst 1041
  cscript //nologo msiscripts\WiLangId.vbs %TARGET% Package 1033,1041

  exit /b


:MAIN
  call :CONFIG
  call :GETTEXT
  call :ICONV
  call :DIFF
  call :UPDATE
  call :COMPILE
  call :PO
  call :DIST
  call :VIMLICENSE
  call :WIX
  exit /b

