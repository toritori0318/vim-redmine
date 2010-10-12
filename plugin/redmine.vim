if exists("g:redmine_loaded") && g:redmine_loaded
    finish
endif
let g:redmine_loaded = 1
if !exists('g:redmine_pl_bin')
    let g:redmine_pl_bin = 'perl ~/.vim/ext/redmine.pl'
endif
if !exists('g:redmine_auth_site')
    let g:redmine_auth_site = 'http://localhost:3000'
endif
if !exists('g:redmine_auth_user')
    let g:redmine_auth_user = ''
endif
if !exists('g:redmine_auth_pass')
    let g:redmine_auth_pass = ''
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

function! RedmineCreateCommand(args, mode)
    let s:cmd = [g:redmine_pl_bin]
    if !empty(a:args)
       call add(s:cmd, '--condition='''. a:args .'''')
    endif
    if !empty(a:mode)
       call add(s:cmd, '--mode='''. a:mode .'''')
    endif
    if !empty(g:redmine_auth_site)
       call add(s:cmd, '--site='. g:redmine_auth_site )
    endif
    if !empty(g:redmine_auth_user)
       call add(s:cmd, '--user='. g:redmine_auth_user )
    endif
    if !empty(g:redmine_auth_pass)
       call add(s:cmd, '--pass='. g:redmine_auth_pass )
    endif
    if !empty(g:redmine_auth_key)
       call add(s:cmd, '--key='. g:redmine_auth_key )
    endif
    return s:cmd
endfunc
function! RedmineSearchTicket(args)
    echo join(RedmineCreateCommand(a:args, 'i'),' ')
    let s:getissue = system( join(RedmineCreateCommand(a:args, 'i'),' ') )
    echo s:getissue
    if s:getissue =~ 'With HTTP Status' " get error
        return
    endif

    let s:pkey = input("input issue id:")
    if s:pkey != "" && s:pkey =~ '^\d*$'
        let s:site_path = g:redmine_auth_site .'/issues/'.s:pkey
        let s:ret = system(g:redmine_browser. ' '. s:site_path)
    else
        echoh None
    endif
    return
endfunc
function! RedmineSearchProject(input_flg)
    echo join(RedmineCreateCommand('', 'p'))
    let s:getproject = system( join(RedmineCreateCommand('', 'p'),' ') )
    echo s:getproject
    if s:getproject =~ 'With HTTP Status' " get error
        return
    endif

    if a:input_flg == 1 
        let s:pkey = input("input project id:")
        if s:pkey != "" && s:pkey =~ '^\d*$'
            return s:pkey
        endif
    endif
    return
endfunc
function! RedmineViewAllTicket()
    call RedmineSearchTicket('')
endfunc

function! RedmineViewMyTicket()
    let cond_author = RedmineConditionAuthor(g:redmine_author_id)
    call RedmineSearchTicket(cond_author)
endfunc

function! RedmineViewMyProjectTicket()
    let cond_author = RedmineConditionAuthor(g:redmine_author_id)
    if !empty(g:redmine_project_id)
        let cond_project = RedmineConditionProject(g:redmine_project_id)
        call RedmineSearchTicket(join([cond_project, cond_author], '&'))
    else 
        let project_id = RedmineSearchProject(1)
        if !empty(project_id)
            let cond_project = RedmineConditionProject(project_id)
            call RedmineSearchTicket(join([cond_project, cond_author], '&'))
        endif
    endif
endfunc

function! RedmineEditTicket()
    return
endfunc

function! RedmineConditionAuthor(args)
    if !empty(a:args)
        return 'author_id=' . a:args
    endif
endfunc
function! RedmineConditionProject(args)
    if !empty(a:args)
        return 'project_id=' . a:args
    endif
endfunc

