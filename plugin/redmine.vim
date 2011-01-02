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

command RedmineViewAllTicket :call RedmineViewAllTicket()
command RedmineViewMyTicket :call RedmineViewMyTicket()
command RedmineViewMyProjectTicket :call RedmineViewMyProjectTicket()
command -nargs=* RedmineSearchTicket :call RedmineSearchTicket(<f-args>)
command -nargs=* RedmineSearchProject :call RedmineSearchProject(0)
command -nargs=* RedmineEditTicket :call RedmineEditTicket(<f-args>)

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
    let ret = http#get(url)
    if ret.content == ' '
        return 0
    endif

    let num = 0
    let dom = xml#parse(ret.content)
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
    let ret = http#get(url)
    if ret.content == ' '
        return 0
    endif

    let num = 0
    let dom = xml#parse(ret.content)
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
            let s:url .= 'issues.xml'
        elseif a:mode == 'project_list'
            let s:url .= 'projects.xml'
        elseif a:mode == 'issue_edit'
            let s:url .= 'issues/'. a:id .'.xml'
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
    let tx = a:text
    let tx = substitute(tx, '&', '\&amp;',  'g')
    let tx = substitute(tx, '<', '\&lt;',   'g')
    let tx = substitute(tx, '>', '\&gt;',   'g')
    let tx = substitute(tx, "'", '\&apos;', 'g')
    let tx = substitute(tx, '"', '\&quot;', 'g')
    let put_xml = '<issue><notes>'. tx .'</notes></issue>'
    echo put_xml
    let ret = http#post(url, put_xml, {'Content-Type' : 'text/xml'} , 'PUT')
endfunc

