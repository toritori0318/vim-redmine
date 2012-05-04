if exists("g:redmine_loaded") && g:redmine_loaded
    finish
endif
let g:redmine_loaded = 1
if !exists('g:redmine_auth_site')
    let g:redmine_auth_site = 'http://localhost:3000'
endif
if !exists('g:redmine_auth_key')
    let g:redmine_auth_key = ''
endif
if !exists('g:redmine_browser')
    let g:redmine_browser = 'open -a Firefox'
    "let g:redmine_browser = 'C:\Program Files\Mozilla Firefox\firefox.exe'
endif
if !exists('g:redmine_author_id')
    let g:redmine_author_id = ''
endif
if !exists('g:redmine_project_id')
    let g:redmine_project_id = ''
endif
if !exists('g:redmine_project_id_remember') " if zero, ask project_id everytime when add a ticket.
    let g:redmine_project_id_remember = '1'
endif
if !exists('g:redmine_temporary_dir')
    let g:redmine_temporary_dir = $HOME . '/.redmine-vim'
endif
if !isdirectory(g:redmine_temporary_dir)
    call mkdir(g:redmine_temporary_dir, 'p')
endif

command RedmineViewAllTicket :call RedmineViewAllTicket()
command RedmineViewMyTicket :call RedmineViewMyTicket()
command RedmineViewMyProjectTicket :call RedmineViewMyProjectTicket()
command -nargs=* RedmineSearchTicket :call RedmineSearchTicket(<f-args>)
command -nargs=* RedmineSearchProject :call RedmineSearchProject(0)
command -nargs=* RedmineEditTicket :call RedmineEditTicket(<f-args>)
command -nargs=* RedmineViewTicket :call RedmineViewTicket(<f-args>)
command -nargs=* RedmineAddTicket :call RedmineAddTicket(<f-args>)
command -nargs=* RedmineAddTicketWithDiscription :call RedmineAddTicketWithDiscription(<f-args>)

function! RedmineSearchTicket(args)
    let stat = RedmineAPIIssueList(a:args)
    if !stat 
        echo 'issue not found'
        return 0
    endif

    let s:pkey = input("input issue id: ")
    if s:pkey != "" && s:pkey =~ '^\d*$'
        let s:site_path = g:redmine_auth_site .'/issues/'.s:pkey
        let s:ret = system(g:redmine_browser. ' '. s:site_path)
    else
        echoh None
    endif
    return 1
endfunc
function! RedmineAPIIssueList(args)
    let url = RedmineCreateCommand('issue_list', '', a:args)
    let ret = webapi#http#get(url)
    if ret.content == ' '
        return 0
    endif

    let num = 0
    let dom = webapi#xml#parse(ret.content)
    for elem in dom.findAll("issue")
      echo "#" . elem.find("id").value() . ' ' . elem.find("description").value()
      let num += 1
    endfor
    return num
endfunc
function! RedmineSearchProject(input_flg)
    let stat = RedmineAPIProjects()
    if !stat
        echo 'project not found'
        return 0
    endif

    if a:input_flg == 1 
        let s:pkey = input("input project id: ")
        if s:pkey != "" && s:pkey =~ '^\d*$'
            return s:pkey
        endif
    endif
    return 1
endfunc
function! RedmineAPIProjects()
    let url = RedmineCreateCommand('project_list','','')
    let ret = webapi#http#get(url)
    if ret.content == ' '
        return 0
    endif

    let num = 0
    let dom = webapi#xml#parse(ret.content)
    for elem in dom.findAll("project")
      echo "#" . elem.find("id").value() . ' ' . elem.find("name").value()
      let num += 1
    endfor
    return num
endfunc
function! RedmineViewAllTicket()
    call RedmineSearchTicket('')
endfunc

function! RedmineViewMyTicket()
    call RedmineSearchTicket({'author_id' : g:redmine_author_id})
endfunc

function! RedmineViewTicket(id)
    let url = RedmineCreateCommand('issue_list', a:id, {'include' : 'journals'})
    let ret = webapi#http#get(url)
    if ret.content == ' '
        return 0
    endif

    let num = 0
    let dom = webapi#xml#parse(ret.content)
    echo "#" . dom.find("id").value() . ' ' . dom.find("subject").value()
    echo "\n"
    echo dom.find("description").value()
    echo "\n"
    echo "--\n"
    for elem in dom.findAll("journal")
      echo elem.find("user").attr.name . ' ' . elem.find("created_on").value()
      echo elem.find("notes").value()
      echo "--\n"
    endfor
    return num
endfunc

function! RedmineViewMyProjectTicket()
    let cond = {'author_id' : g:redmine_author_id}
    if !empty(g:redmine_project_id)
        let cond['project_id'] = g:redmine_project_id
        call RedmineSearchTicket(cond)
    else
        let project_id = RedmineSearchProject(1)
        if !empty(project_id)
            let cond['project_id'] = project_id
            call RedmineSearchTicket(cond)
        endif
    endif
endfunc

function! RedmineCreateCommand(mode, id, args)
    let s:url = g:redmine_auth_site . '/'
    if !empty(a:mode)
        if a:mode == 'issue_list'
            if !empty(a:id)
                let s:url .= 'issues/' . a:id . '.xml'
            else
                let s:url .= 'issues.xml'
            endif
        elseif a:mode == 'project_list'
            let s:url .= 'projects.xml'
        elseif a:mode == 'issue_edit'
            let s:url .= 'issues/'. a:id .'.xml'
        elseif a:mode == 'issue_add'
            let s:url .= 'issues.xml'
        endif
    endif
    let s:param = ['']
    if !empty(g:redmine_auth_key)
       call add(s:param, 'key='. g:redmine_auth_key )
    endif
    if !empty(a:args)
        for key in keys(a:args)
            call add(s:param, key . '='. a:args[key] )
        endfor
    endif
    return s:url . '?' . join(s:param, '&')
endfunc

function! RedmineEditTicket(issue_id, text)
    call RedmineAPIIssueEdit(a:issue_id, a:text)
    return
endfunc
function! RedmineAPIIssueEdit(issue_id, text)
    let url = RedmineCreateCommand('issue_edit', a:issue_id, '')
    let tx = iconv(a:text, &encoding, "utf-8")
    let tx = substitute(tx, '&', '\&amp;',  'g')
    let tx = substitute(tx, '<', '\&lt;',   'g')
    let tx = substitute(tx, '>', '\&gt;',   'g')
    let tx = substitute(tx, "'", '\&apos;', 'g')
    let tx = substitute(tx, '"', '\&quot;', 'g')
    let put_xml = '<issue><notes>'. tx .'</notes></issue>'
    echo put_xml
    let ret = webapi#http#post(url, put_xml, {'Content-Type' : 'text/xml'} , 'PUT')
endfunc

function! RedmineAddTicket(subject)
    " add ticket with only subject
    call s:setProjectId()

    call s:redmineAddTicketPost(a:subject, s:project_id, '')
endfunc

function! RedmineAddTicketWithDiscription(...)
    " add ticket with subject and discription(with tmp buffer)
    let l:subject = a:0 > 0 ? a:1 :''
    call s:setProjectId()

    " open tempbuffer
    call s:setupDiscriptionBuffer()
    call append(0, l:subject)
    autocmd BufWritePost <buffer> call s:redmineAddTicketWithDiscriptionWrite() | bdelete
endfunc

function! s:redmineAddTicketWithDiscriptionWrite()
    let l:subject = getline(1)
    let l:discription = join(getline(2, "$"),"\n")
    call s:redmineAddTicketPost(l:subject, s:project_id, l:discription)
endfunc

function! s:redmineAddTicketPost(subject, project_id, ...)
    let l:discription = a:0 > 0 ? a:1 : ''

    let url = RedmineCreateCommand('issue_add', '', '')
    let put_xml = '<issue>'
    let put_xml .= '<project_id>' . a:project_id . '</project_id>'
    let put_xml .= '<subject>'    . iconv(a:subject, &encoding, "utf-8") . '</subject>'
    if !empty(l:discription)
        let put_xml .= '<description>' . iconv(l:discription, &encoding, "utf-8") . '</description>'
    endif
    let put_xml .= '</issue>'
    let ret = webapi#http#post(url, put_xml, {'Content-Type' : 'text/xml'} , 'POST')
    echomsg ' Add ticket "' . a:subject . '" complete.'
endfunc

function! s:setProjectId()
    if !empty(g:redmine_project_id)
        let s:project_id = g:redmine_project_id
    else
        if !exists('s:project_id')
            let s:project_id = RedmineSearchProject(1)
        elseif (g:redmine_project_id_remember == 0)
            let s:project_id = RedmineSearchProject(1)
        endif
    endif
endfunc

function! s:setupDiscriptionBuffer()
    let bufnr = bufwinnr('redmine_discription')
    if bufnr > 0
        exec bufnr.'wincmd w'
    else
        exec 'below split '.g:redmine_temporary_dir.'/redmine_discription'
    endif
    setlocal modifiable
    setlocal noswapfile

    silent %delete _
endfunc
