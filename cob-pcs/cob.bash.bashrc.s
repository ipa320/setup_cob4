function parse_git_branch () {
  git branch 2> /dev/null | sed -e '/^[^*]/d' -e 's/* \(.*\)/ (\1)/'
}

function get_search_domain () {
  grep search /etc/resolv.conf | sed -e "s/search //"
}

# set color fo all users
PS1='${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h.$(get_search_domain).$ROBOT_ENV\[\033[00m\]:\[\033[01;34m\]\w\[\033[0;33m\]$(parse_git_branch)\[\033[0m\]\$ '
