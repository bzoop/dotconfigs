##########################
#### completion control
##########################
## completion stuff
zstyle ':compinstall' filename '$HOME/.zshrc'

zcachedir="$HOME/.cache/zsh"
[[ -d "$zcachedir" ]] || mkdir -p "$zcachedir"

() {
    setopt local_options extendedglob
    autoload -Uz compinit
    local zcompf="$1/zcompdump"
    # use a separate file to determine when to regenerate, as compinit doesn't
    # always need to modify the compdump
    local zcompf_a="${zcompf}.augur"

    # use glob qualifiers (#q)
    # http://zsh.sourceforge.net/Doc/Release/Expansion.html#Glob-Qualifiers
    # N -> NULL_GLOB
    # . -> plain files
    # m[Mwhms][-|+]n -> modification time qualifiers
    if [[ -e "$zcompf_a" && -f "$zcompf_a"(#qN.mh-24) ]]; then
        compinit -C -d "$zcompf"
    else
        compinit -d "$zcompf"
        touch "$zcompf_a"
    fi

    # complete dot files
    #_comp_options+=(globdots)

    # if zcompdump exists (and is non-zero), and is older than the .zwc file,
    # then regenerate
    if [[ -s "$zcompf" && (! -s "${zcompf}.zwc" || "$zcompf" -nt "${zcompf}.zwc") ]]; then
        # since file is mapped, it might be mapped right now (current shells), so
        # rename it then make a new one
        [[ -e "$zcompf.zwc" ]] && mv -f "$zcompf.zwc" "$zcompf.zwc.old"
        # compile it mapped, so multiple shells can share it (total mem reduction)
        # run in background
        zcompile -M "$zcompf" &!
    fi
} "$zcachedir"

zcompcdir="$zcachedir/zcompcache"
[[ -d "$zcompcdir" ]] || mkdir -p "$zcompcdir"

zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$zcompcdir"
unset zcompcdir
unset zcachedir

# Use menu completion
#zstyle ':completion:*' menu select
zstyle ':completion:*' menu 'select=4'

# simple matcher first, then case insensitive match
zstyle ':completion:*' matcher-list \
    '' 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

# Don't try parent path completion if the directories exist
zstyle ':completion:*' accept-exact-dirs true

# This way you tell zsh comp to take the first part of the path to be
# exact, and to avoid partial globs. Now path completions became nearly
# immediate.
zstyle ':completion:*' accept-exact '*(N)'

# Always use menu selection for `cd -`
zstyle ':completion:*:*:cd:*:directory-stack' force-list always
zstyle ':completion:*:*:cd:*:directory-stack' menu yes select

# Verbose completion results
zstyle ':completion:*' verbose true

# Don't complete hosts from /etc/hosts
zstyle ':completion:*' hosts
# or users
zstyle ':completion:*' users

# group results by category
#zstyle ':completion:*' group-name ''

# Use ls-colors for path completions
() {
     local LS_COLORS='no=00:fi=00:ca=00:di=36:ln=35:pi=33:so=36:bd=40;33;01:cd=40;33;01:or=35:mi=41;30;01:ex=31:*.tar=01;31:*.tgz=01;31:*.arj=01;31:*.taz=01;31:*.lzh=01;31:*.zip=01;31:*.z=01;31:*.Z=01;31:*.gz=01;31:*.bz2=01;31:*.bz=01;31:*.tz=01;31:*.rpm=01;31:*.cpio=01;31:'
	zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}
}

# list dirs first
zstyle ':completion:*' list-dirs-first true
zstyle ':completion:*' single-ignored show

# output format
#zstyle ':completion:*:descriptions' format '%U%B%d%b%u'
zstyle ':completion:*:descriptions' format '.: %d :.'
zstyle ':completion:*:corrections' format '%U%F{green}%d (errors: %e)%f%u'
zstyle ':completion:*:warnings' format '%F{202}%Bno matches for: %F{214}%d%b'

# Dont complete uninteresting stuff unless we really want to.
zstyle ':completion:*:functions' ignored-patterns '(_*|pre(cmd|exec)|TRAP*)'
zstyle ':completion:*:*:*:users' ignored-patterns '_*'

## Better SSH/Rsync/SCP Autocomplete
# disable users in ssh tab completion
zstyle ':completion:*:*:ssh:*:my-accounts' off
#zstyle ':completion:*:(ssh|scp|sftp|rsync):*' tag-order 'hosts:-host:host hosts:-domain:domain hosts:-ipaddr:ip\ address *'
#zstyle ':completion:*:(scp|sftp|rsync):*' group-order users files all-files hosts-domain hosts-host hosts-ipaddr
#zstyle ':completion:*:ssh:*' group-order users hosts-domain hosts-host hosts-ipaddr
# disable ip addr completions as well
zstyle ':completion:*:(ssh|scp|sftp|rsync):*' tag-order 'hosts:-host:host hosts:-domain:domain'
zstyle ':completion:*:(scp|sftp|rsync):*' group-order files other-files hosts-domain hosts-host
zstyle ':completion:*:ssh:*' group-order hosts-domain hosts-host
zstyle ':completion:*:(ssh|scp|sftp|rsync):*:hosts-host' ignored-patterns '*(.|:)*' loopback ip6-loopback localhost ip6-localhost broadcasthost
zstyle ':completion:*:(ssh|scp|sftp|rsync):*:hosts-domain' ignored-patterns '<->.<->.<->.<->' '^[-[:alnum:]]##(.[-[:alnum:]]##)##' '*@*'
zstyle ':completion:*:(ssh|scp|sftp|rsync):*:hosts-ipaddr' ignored-patterns '^(<->.<->.<->.<->|(|::)([[:xdigit:].]##:(#c,2))##(|%*))' '127.0.0.<->' '255.255.255.255' '::1' 'fe80::*'
