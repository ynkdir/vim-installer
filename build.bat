REM Build MSI Vim Installer
REM
REM Requirements:
REM   Windows Installer XML (WiX) toolset
REM     http://wix.sourceforge.net/
REM 
REM Usage:
REM   build.bat vim [extra]
REM
REM   vim      Vim directory.  You need to build Vim before calling this script.
REM   extra    Extra directory contains extra files such as iconv.dll, ...etc.

setlocal

if %1x == x (
  echo usage: build.bat vim [extra]
  goto :EOF
)

set VIM=%~f1
set EXTRA=%~f2

if defined WIX set PATH=%PATH%;%WIX%\bin

REM ----------------------------------------------------------------------------
REM COPY VIM FILES
REM ----------------------------------------------------------------------------

robocopy /MIR %VIM%\runtime dist
for %%i in (%VIM%\src\po\*.mo) do (
mkdir dist\lang\%%~ni\LC_MESSAGES
copy %%i dist\lang\%%~ni\LC_MESSAGES\vim.mo
)
copy %VIM%\src\vim.exe dist
copy %VIM%\src\gvim.exe dist
copy %VIM%\src\vimrun.exe dist
copy %VIM%\src\xxd\xxd.exe dist
copy %VIM%\src\tee\tee.exe dist
copy %VIM%\src\GvimExt\gvimext.dll dist
copy %VIM%\src\VisVim\VisVim.dll dist
copy %VIM%\src\VisVim\README_VisVim.txt dist
copy %VIM%\vimtutor.bat dist
copy %VIM%\README.txt dist
copy %VIM%\src\vim.pdb dist
copy %VIM%\src\gvim.pdb dist

REM ----------------------------------------------------------------------------
REM COPY EXTRA FILES
REM ----------------------------------------------------------------------------

if %EXTRA%x == x goto EXTRAEND
if exist %EXTRA% robocopy /E %EXTRA% dist
:EXTRAEND

REM ----------------------------------------------------------------------------
REM VIMLICENSE.RTF
REM ----------------------------------------------------------------------------

copy %VIM%\runtime\doc\uganda.txt vimlicense.rtf

REM cd vim\runtime\doc && make uganda.nsis.txt
%VIM%\src\vim -u NONE ^
  -c "%%s/[ 	]*\*[-a-zA-Z0-9.]*\*//g" ^
  -c "%%s/vim:tw=78://" ^
  -c "g/$/if getline(line('.')) == getline(line('.') + 1) | delete _ | endif" ^
  -c "wq!" ^
  vimlicense.rtf

REM convert to rtf
%VIM%\src\vim -u NONE ^
  -c "%%s/$/\\par/" ^
  -c "%%s/\t\+/\=repeat('\tab', len(submatch(0))) . ' '/g" ^
  -c "0put='{\rtf1\ansi\deff0{\fonttbl{\f0\fnil\fcharset1 Arial;}}\f0\fs16'" ^
  -c "$put='}'" ^
  -c "wq!" ^
  vimlicense.rtf

REM ----------------------------------------------------------------------------
REM BUILD MSI INSTALLER
REM ----------------------------------------------------------------------------

REM [Automation Interface Reference]
REM http://msdn.microsoft.com/en-us/library/aa367810.aspx
REM [Multi-Language MSI Packages without Setup.exe Launcher]
REM http://www.installsite.org/pages/en/msi/articles/embeddedlang/index.htm

%VIM%\src\vim -u versiondump.vim
call version.bat

if %VER_ARCH% == win64 (
  set CANDLE_64BIT_FLAG=-darch=x64 -arch x64
) else (
  set CANDLE_64BIT_FLAG=
)

set SRCS=vim.wxs filelist.wxs
set OBJS=vim.wixobj filelist.wixobj
set TARGET=vim-%VER_NAME%.msi

REM Exclude special files from heat.  These are specified in vim.wxs.
move dist\gvim.exe .
move dist\gvimext.dll .
move dist\VisVim.dll .
move dist\README_VisVim.txt .

heat dir dist -nologo -dr INSTALLDIR -cg MainFiles -ag -srd -sfrag -sreg -var var.dist -out filelist.wxs

move gvim.exe dist
move gvimext.dll dist
move VisVim.dll dist
move README_VisVim.txt dist

candle.exe -nologo -ddist=dist -dlang=1033 -dcodepage=1252 %CANDLE_64BIT_FLAG% %SRCS%
light.exe -nologo -ext WixUIExtension -cultures:en-us -loc loc_en-us.wxl -out %TARGET% %OBJS%

REM Japanese
candle.exe -nologo -ddist=dist -dlang=1041 -dcodepage=932 %CANDLE_64BIT_FLAG% %SRCS%
light.exe -nologo -ext WixUIExtension -cultures:ja-jp -loc loc_ja-jp.wxl -out ja-jp.msi %OBJS%
torch.exe -nologo -p -t language %TARGET% ja-jp.msi -out ja-jp.mst
cscript //nologo msiscripts\WiSubStg.vbs %TARGET% ja-jp.mst 1041
cscript //nologo msiscripts\WiLangId.vbs %TARGET% Package 1033,1041

