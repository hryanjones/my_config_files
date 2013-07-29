# Because you're a bit forgetful
alias mv="mv -i"
alias cp="cp -i"
alias rm="rm -i"

# Color aliases
alias ls='ls --color=auto'
alias grep='grep --color=auto'

# useful for finding recently touched files/dirs in a directory
alias recent='ls -t | head -n'

alias vless='/usr/share/vim/vim73/macros/less.sh' #HOME
#alias vless='/apollo/env/EnvImprovement/share/vim/vim73/macros/less.sh' #WORK
alias ipython='ipython --noconfirm_exit'
#alias buscalo="find . -iname '*$1*'" #doesn't work in fish

# Helpful aliases (WORK)
alias Activate='sudo /apollo/bin/runCommand -a Activate -e'
alias Deactivate='sudo /apollo/bin/runCommand -a Deactivate -e'
alias runme_dashboard='/apollo/bin/env -e AWSDevSupportDashboard '
alias runme_awsscripts='/apollo/bin/env -e AWSDevSupportScripts '
alias runme_k2='/apollo/bin/env -e KumoKonsoleWebsite '
alias irb='/apollo/env/AWSDevSupportScripts/bin/irb --readline -r irb/completion'
alias br="/bin/env -i /apollo/env/SDETools/bin/brazil-runtime-exec"
alias epochToHuman="date -d @$1"

# SSH aliases (HOME)
alias ssh2kakyumaKange='ssh 192.168.1.12'
alias ssh2pdx='ssh -i ~/.ssh/hrjonesAtAmazonKey.pem ec2-user@pdx.hrjones.myinstance.com'
alias ssh2hrjones='ssh -p 2222 hrjones@localhost'

# SSH aliases (WORK)
alias ssh2pdx='ssh -i ~/.ssh/hrjonesAtAmazonKey.pem ec2-user@pdx.hrjones.myinstance.com'
alias ssh2hryanjones='ssh -R 2222:localhost:22 -L 5222:talk.google.com:5222 hryanjones@home.hryanjones.com'
alias ssh2vdc='ssh aws-dev-support-1002.vdc.amazon.com'
alias ssh2rhel='ssh hrjones-2.desktop.amazon.com'
alias sshto6001="ssh aws-dev-support-6001.iad6.amazon.com"
alias sshto6002="ssh aws-dev-support-6002.iad6.amazon.com"
alias sshto6003="ssh aws-dev-support-6003.iad6.amazon.com"
alias sshto6001="ssh aws-dev-support-6001.iad6.amazon.com"
alias sshto6002="ssh aws-dev-support-6002.iad6.amazon.com"
alias sshto6003="ssh aws-dev-support-6003.iad6.amazon.com"
alias ssh2vdc="ssh aws-dev-support-1002.vdc.amazon.com"
alias ssh2rhel="ssh hrjones-2.desktop.amazon.com"
alias ssh2hryanjones='ssh -R 2222:localhost:22 -L 5222:talk.google.com:5222 hryanjones@home.hryanjones.com'
