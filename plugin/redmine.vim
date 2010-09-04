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

command RedmineViewAllTicket :call RedmineViewAllTicket()
command RedmineViewMyTicket :call RedmineViewMyTicket()
command -nargs=* RedmineSearchTicket :call RedmineSearchTicket(<f-args>)

function! RedmineSearchTicket(args)
    let s:cmd = [g:redmine_pl_bin]
    if !empty(a:args)
       call add(s:cmd, '--condition='''. a:args .'''')
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
    let s:getissue = system( join(s:cmd,' ') )
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
function! RedmineViewAllTicket()
    call RedmineSearchTicket('')
endfunc

function! RedmineViewMyTicket()
    let cond_author = RedmineConditionAuthor()
    call RedmineSearchTicket(cond_author)
endfunc

function! RedmineEditTicket()
    return
endfunc

function! RedmineConditionAuthor()
    if !empty(g:redmine_author_id)
        return 'author_id=' . g:redmine_author_id
    endif
endfunc

