function unzip(file, dir) {
  var fso = new ActiveXObject('Scripting.FileSystemObject');
  if (!fso.FolderExists(dir))
    fso.CreateFolder(dir);
  var shell = new ActiveXObject('Shell.Application');
  var dst = shell.NameSpace(fso.getFolder(dir).Path);
  var zip = shell.NameSpace(fso.getFile(file).Path);
  // http://msdn.microsoft.com/en-us/library/ms723207.aspx
  // 4: Do not display a progress dialog box.
  // 16: Click "Yes to All" in any dialog box displayed.
  dst.CopyHere(zip.Items(), 4 + 16);
}

function usage() {
  WScript.Echo(
    "usage: unzip.js [-d exdir] zipfile\n" +
    "  -d extract files into exdir");
  WScript.Quit(1);
}

function main() {
  var args = WScript.Arguments;
  var zipfile;
  var destdir = null;
  var i;
  for (i = 0; i < args.length; ++i) {
    if (args(i).match(/^(-d)$/)) {
      destdir = args(++i);
    } else if (args(i).match(/^(-h|--help)$/)) {
      usage();
    } else {
      break;
    }
  }
  if (i == args.length) {
    usage();
  }
  zipfile = args(i);
  if (destdir === null) {
    destdir = ".";
  }
  unzip(zipfile, destdir);
}

main();
