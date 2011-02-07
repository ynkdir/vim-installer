// http://msdn.microsoft.com/en-us/library/ms676152.aspx
// SaveOptionsEnum
var adSaveCreateNotExist = 1;
var adSaveCreateOverWrite = 2;

// http://msdn.microsoft.com/en-us/library/ms675277.aspx
// StreamTypeEnum
var adTypeBinary = 1;
var adTypeText = 2;

var USER_AGENT = "httpget.js/1.0";

function httpget(url, file) {
  var xhr;
  if (url.match(/^https?:/)) {
    // use ServerXMLHTTP for https
    xhr = new ActiveXObject("MSXML2.ServerXMLHTTP");
    // FIXME: required?
    //var SXH_SERVER_CERT_IGNORE_ALL_SERVER_ERRORS = 13056;
    //xhr.setOption(2, SXH_SERVER_CERT_IGNORE_ALL_SERVER_ERRORS);
  } else {
    // ServerXMLHTTP doesn't support ftp.
    xhr = new ActiveXObject("MSXML2.XMLHTTP.3.0");
  }
  xhr.open("GET", url, false);
  // For default user-agent, sourceforge's download url responds
  // download page instead of its content.
  xhr.setRequestHeader("User-Agent", USER_AGENT);
  xhr.send();
  if (xhr.readyState != 4) {
    throw new Error("REQUEST INCOMPLETE");
  }
  if (url.match(/^https?/) && xhr.status != 200) {
    throw new Error("HTTP STATUS: " + xhr.status);
  }

  var strm = new ActiveXObject("ADODB.Stream");
  strm.Type = adTypeBinary;
  strm.Open();
  strm.Write(xhr.responseBody);
  strm.SaveToFile(file, adSaveCreateOverWrite);
  strm.Close();
}

function filename(url) {
  url = url.replace(/[?#].*$/, "");
  if (url.match(/\/$/)) {
    return "index.html";
  }
  return url.match(/[^\/]+$/);
}

function usage() {
  WScript.Echo(
    "usage: httpget.js [options] url\n" +
    "  -O write documents to FILE.\n");
  WScript.Quit(1);
}

function main() {
  var args = WScript.Arguments;
  var url;
  var destfile = null;
  var i;
  for (i = 0; i < args.length; ++i) {
    if (args(i).match(/^(-O)$/)) {
      destfile = args(++i);
    } else if (args(i).match(/^(-h|--help)$/)) {
      usage();
    } else {
      break;
    }
  }
  if (i == args.length) {
    usage();
  }
  url = args(i);
  if (destfile === null) {
    destfile = filename(url);
  }
  httpget(url, destfile);
}

main();
