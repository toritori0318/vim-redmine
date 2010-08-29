if exists("g:redmine_loaded") && g:redmine_loaded
    finish
endif
let g:redmine_loaded = 1
if !exists('g:redmine_pl_bin')
    let g:redmine_pl_bin = 'perl ~/.vim/ext/redmine.pl'
endif
if !exists('g:redmine_author_id')
    let g:redmine_author_id = ''
endif

command RedmineViewAllTicket :call RedmineViewAllTicket()
command RedmineViewMyTicket  :call RedmineViewMyTicket()
command -nargs=* RedmineSearchTicket :call RedmineSearchTicket(<f-args>)

function! RedmineSearchTicket(args)
    let args = a:args
    let cmd = [g:redmine_pl_bin]
    if !empty(args)
       call add(cmd, '--condition='''. args .'''')
    endif
    echo join(cmd,' ')
    let optval = system( join(cmd,' ') )
    echo optval
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
    if exists('g:redmine_author_id') && !empty(g:redmine_author_id)
        return 'author_id=' . g:redmine_author_id
    endif
endfunc

