function fish_prompt

  echo $POWERLINE_PATH" -------------"

  # if powershell exists us it!
  if ls ~/github/powerline-shell/powerline-shell.py ^ /dev/null > /dev/null
    ~/github/powerline-shell/powerline-shell.py $status --shell bare --colorized hostname
  else
  # if not fall back on previous shell
    set_color red
    echo "-------------------- "(date)" --------------------"
    set_color cyan
    printf '%s' (whoami)
    set_color normal
    printf ' at '

    set_color -o -u red
    printf '%s' (hostname|cut -d . -f 1)
    set_color normal
    printf ' in '

    set_color $fish_color_cwd
    printf '%s' (prompt_pwd)
    set_color normal

    # Line 2
    echo
    if test $VIRTUAL_ENV
        printf "(%s) " (set_color blue)(basename $VIRTUAL_ENV)(set_color normal)
    end
    printf '$ '
    set_color normal
  end
end
