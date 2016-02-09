# Because you're a bit forgetful
alias mv="mv -i"
alias cp="cp -i"
alias rm="rm -i"
alias tree="tree -C"
alias ding="eche -e \a"

# Color aliases
alias ls='ls --color=auto'
alias grep='grep --color=auto'

# useful for finding recently touched files/dirs in a directory
alias recent='ls -t | head -n'

alias ipython='ipython --no-confirm-exit'

# Helpful aliases (WORK)
alias irb='irb --readline -r irb/completion'

# SSH aliases (HOME)

# SSH aliases (WORK)
alias ssh2home='autossh -L 5222:talk.google.com:5222 hryanjones@home.hryanjones.com'
alias ssh2acc='ssh hrjones.aka.corp.amazon.com'
