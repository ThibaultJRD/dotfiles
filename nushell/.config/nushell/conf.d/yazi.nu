# ==============================================================================
# Yazi File Manager Integration
# ==============================================================================
# Changes the shell directory to the last browsed location when quitting yazi

def --env y [...args] {
  let tmp = (mktemp -t "yazi-cwd.XXXXXX")
  yazi ...$args --cwd-file $tmp
  let cwd = (open $tmp)
  if $cwd != "" and $cwd != $env.PWD {
    cd $cwd
  }
  rm -f $tmp
}
