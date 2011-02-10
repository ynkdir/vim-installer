let major = v:version / 100
let minor = v:version % 100
let patch = get(filter(range(1000), 'has("patch".v:val)'), -1, 0)

cd vim
let revision = str2nr(split(system('hg log -r tip'), ':')[1])
cd ..

redir => buf
silent version
redir END
let m = matchlist(buf, '\vVIM - Vi IMproved \d+\.\d+(.) BETA')
let beta = empty(m) ? '' : m[1]

let full = printf('%d.%d.%d.%d', major, minor, patch, revision)
let short = printf('%d.%d', major, minor)
let bit = has('win64') ? 'win64' : 'win32'

if beta == ""
  if patch == 0
    let name = printf('%d.%d-%s', major, minor, bit)
  else
    let name = printf('%d.%d.%03d-%s', major, minor, patch, bit)
  endif
else
  " FIXME
  let name = printf('%d.%d%s-r%d-%s', major, minor, beta, revision, bit)
endif

$put ='SET VER_FULL='.full
$put ='SET VER_SHORT='.short
$put ='SET VER_NAME='.name
write! version.bat
quit
