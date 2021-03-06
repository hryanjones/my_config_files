# Use everything that we've got in .bash_aliases
. ~/.bash_aliases

set PATH_ADDITIONS_FILE ~/.shell_path_additions.txt
if ls $PATH_ADDITIONS_FILE >/dev/null ^/dev/null
  for P in (cat $PATH_ADDITIONS_FILE)
    if echo $P | grep -q "~" # stupid fish won't expand string
      set P (echo $HOME$P | sed -e 's/~//')
    end
    if ls $P >/dev/null ^/dev/null
      test $SHLVL -gt 2; and echo adding $P to the PATH # LVL 2 is user level, above that is scripts I think
      set -x PATH $PATH $P
    end
  end
end
