command! -complete=customlist,s:GetFiles -nargs=1 G :call s:OpenFile('<args>')

function! s:SplitFilePath(path)
    let path_dict = {}
    let parts = split(a:path, "/") " TODO support Windows
    TAssert len(parts) > 0, a:path
    let path_dict['name'] = parts[len(parts) - 1]
    let path_dict['dir'] = ''
    if len(parts) > 1
        let path_dict['dir'] = join(parts[0 : len(parts) - 2], '/')
    endif
    return path_dict
endfunc

function! s:Strcmp(str1, str2)
    if a:str1 < a:str2
      return -1
    elseif a:str1 > a:str2
      return 1
    else
      return 0
    endif
endfunc
    
function! s:CompareFiles(file1, file2)
    if a:file1.name == a:file2.name
        return s:Strcmp(a:file1.dir, a:file2.dir)
    endif
    return s:Strcmp(a:file1.name, a:file2.name)
endfunc

function! s:JoinFilePath(file)
    if empty(a:file.dir)
        return a:file.name
    endif
    return printf("%s/%s", a:file.dir, a:file.name)
endfunc

function! s:OpenFile(filetext)
    let namedir = split(a:filetext)
    let absname = namedir[0]
    if len(namedir) == 2
       let dir = strpart(namedir[1], 1, len(namedir[1]) - 2) 
       let absname = printf("%s/%s", dir, absname)
    endif
    if !filereadable(absname)
        let absname = s:JoinFilePath(s:FindFiles(split(a:filetext)[0])[0])
    endif
    execute ':e ' . absname
endfunc

function! s:FileNameForExpr(expr)
    let args = split(a:expr, ',')
    if empty(args)
      return ''
    endif
    return args[0]
endfunc

function! s:DirNameForExpr(expr)
    let args = split(a:expr, ',')
    if empty(args) || len(args) != 2
      return ''
    endif
    return args[1]
endfunc

function! s:FindFilesForIname(expr, iname_mask)
    let args = split(a:expr, ',')
    if empty(args)
        let args = ['']
    endif
    let iname = printf(a:iname_mask, s:FileNameForExpr(a:expr))
    let out = system(printf("find . -iname '%s' -type f | grep -v 'pyc' | grep -v '\.class' | grep -v 'out'", iname))
    let files = map(split(out, "\n"), 'strpart(v:val, 2)')
    let files = map(files, 's:SplitFilePath(v:val)')
    let dir = s:DirNameForExpr(a:expr)
    if strlen(dir) > 0
        let files = filter(files, 'match(v:val.dir, dir) != -1')
    endif
    let files = sort(files, 's:CompareFiles')
    return files
endfunc

function! s:FindFiles(expr)
    let file = s:FileNameForExpr(a:expr)
    let files1 = s:FindFilesForIname(a:expr, '%s*')
    let files2 = filter(s:FindFilesForIname(a:expr, '*%s*'), 'match(v:val.name, file) != 0')
    return extend(files1, files2) "expr: 'event', event.html must be before 'add_event.html'
endfunc

function! s:GetFiles(ArgLead, CmdLine, CursorPos)
    let files = s:FindFiles(a:ArgLead)
    let strings = []
    for file in files
        let s = file.name
        if !empty(file.dir)
            let s = printf("%s (%s)", file.name, file.dir)
        endif
        call add(strings, s)
    endfor
    return strings
endfunc
