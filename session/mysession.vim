let SessionLoad = 1
let s:so_save = &g:so | let s:siso_save = &g:siso | setg so=0 siso=0 | setl so=-1 siso=-1
let v:this_session=expand("<sfile>:p")
silent only
silent tabonly
cd ~/Documents/TOTVS/tcloud-api
if expand('%') == '' && !&modified && line('$') <= 1 && getline(1) == ''
  let s:wipebuf = bufnr('%')
endif
let s:shortmess_save = &shortmess
if &shortmess =~ 'A'
  set shortmess=aoOA
else
  set shortmess=aoO
endif
badd +0 src/stepfunction/intera_zone_provisioning/src/intera_zone_create_database.py
argglobal
%argdel
edit src/stepfunction/intera_zone_provisioning/src/intera_zone_create_database.py
tcd ~/Documents/TOTVS/tcloud-api
argglobal
setlocal fdm=manual
setlocal fde=0
setlocal fmr={{{,}}}
setlocal fdi=#
setlocal fdl=99
setlocal fml=1
setlocal fdn=20
setlocal fen
silent! normal! zE
13,14fold
21,22fold
35,40fold
41,46fold
52,53fold
55,57fold
54,57fold
48,57fold
31,71fold
25,73fold
80,82fold
90,91fold
76,97fold
112,114fold
111,114fold
115,116fold
100,116fold
122,124fold
129,131fold
128,131fold
132,133fold
119,133fold
139,141fold
146,148fold
145,148fold
149,150fold
136,150fold
153,161fold
176,178fold
191,192fold
194,195fold
197,198fold
200,201fold
203,204fold
206,207fold
221,222fold
179,222fold
164,225fold
230,232fold
234,235fold
229,236fold
228,238fold
248,249fold
246,249fold
257,260fold
254,264fold
269,271fold
272,273fold
274,275fold
266,275fold
241,275fold
let &fdl = &fdl
let s:l = 1 - ((0 * winheight(0) + 21) / 43)
if s:l < 1 | let s:l = 1 | endif
keepjumps exe s:l
normal! zt
keepjumps 1
normal! 0
tabnext 1
if exists('s:wipebuf') && len(win_findbuf(s:wipebuf)) == 0 && getbufvar(s:wipebuf, '&buftype') isnot# 'terminal'
  silent exe 'bwipe ' . s:wipebuf
endif
unlet! s:wipebuf
set winheight=1 winwidth=20
let &shortmess = s:shortmess_save
let s:sx = expand("<sfile>:p:r")."x.vim"
if filereadable(s:sx)
  exe "source " . fnameescape(s:sx)
endif
let &g:so = s:so_save | let &g:siso = s:siso_save
nohlsearch
doautoall SessionLoadPost
unlet SessionLoad
" vim: set ft=vim :
