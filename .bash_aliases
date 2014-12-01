# Because you're a bit forgetful
alias mv="mv -i"
alias cp="cp -i"
alias rm="rm -i"

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
alias ssh2pdx='autossh -L 5222:talk.google.com:5222 -L 6667:irc.freenode.net:6667 -L 5223:chat.facebook.com:5222 pdx.hrjones.myinstance.com'
alias ssh2host='ssh hrjones-host.aka.amazon.com'
alias ssh2rhel='ssh hrjones-2.desktop.amazon.com'
