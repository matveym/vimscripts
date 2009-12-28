""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""
function! s:Is_Session_Active()
    " If nothing entered on session connection prompt then g:screen_sessionname is empty
    if !exists("g:screen_sessionname") || !exists("g:screen_windowname") || len(g:screen_sessionname) == 0
        return 0
    endif
    let session = system("screen -ls | grep " . g:screen_sessionname . " | awk '/Attached/ {print $1}'")
    return len(session)
endfunction

function! Send_to_Screen(text)
  if !s:Is_Session_Active()
    call Screen_Vars()
  end

  let selection = split(a:text, "\\n", 1)
  let selection = insert(selection, "# -*- coding: UTF-8 -*-")
  
  call writefile(selection, "/tmp/jython.buf")

  echo system("screen -S " . g:screen_sessionname . " -p " . g:screen_windowname . " -X stuff 'execfile(\"/tmp/jython.buf\")\n'")
endfunction

function! Screen_Session_Names_Complete(A,L,P)
  return Screen_Session_Names()
endfunction

function! Screen_Session_Names()
  return system("screen -ls | grep python | awk '/Attached/ {print $1}'")
endfunction

function! Screen_Vars()
  " if !exists("g:screen_sessionname") || !exists("g:screen_windowname")
  "   let g:screen_sessionname = ""
  "   let g:screen_windowname = "0"
  " end

  " if there is a single python session - just use it
  let sessions = split(Screen_Session_Names(), "\\n")
  if len(sessions) == 1
    let g:screen_sessionname = sessions[0]
    return
  endif

  let g:screen_sessionname = input("session name: ", "", "custom,Screen_Session_Names_Complete")
  " let g:screen_windowname = input("window name: ", g:screen_windowname)
endfunction

""""""""""""""""""""""""""""""""""""""""""""""""""""""""""""

vmap <localleader>r "ry :call Send_to_Screen(@r)<CR>
nmap <localleader>r vip<localleader>r
"
"nmap <C-c>v :call Screen_Vars()<CR>
