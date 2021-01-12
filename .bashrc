### Divers 
# Activer "**"
shopt -s globstar

function unix_to_date() {
        date -d @"$1"
}

### Historique

HISTCONTROL=ignoredups:ignorespace # ne pas conserver les doublons et les lignes vides dans l'historique
HISTIGNORE="ls:[bf]g:cd_*:history*" # ne pas conserver des commandes précises dans l'historique (à configurer)
HISTSIZE=1000000 # augmenter la taille maximale de l'historique pour conserver toutes ses commandes

### aliases
alias ..='cd ..'
alias ai='sudo aptitude install' # ou le gestionnaire de paquet de votre distribution
alias c2p='xclip -o -selection clipboard | xclip' # passe les données de la sélection X primaire (copiées avec CTRL-C) vers le presse-papier (clic-roulette) @todo
alias dl='youtube-dl -i --audio-format mp3 --extract-audio -o '\''%(title)s.%(ext)s'\''' # télécharger une vidéo sur youtube et la convertir en mp3
alias dt='dmesg | tail' # voir les derniers messages du noyau
alias e='emacs -nw' # ouvrir un fichier avec emacs dans le terminal
alias get_cert_fingerprint='openssl x509 -noout -fingerprint -in' # extraire l'empreinte d'un certificat
alias get_ssh_fingerprint='awk '\''{print $2}'\'' /etc/ssh/ssh_host_ecdsa_key.pub | base64 -d | sha256sum -b | awk '\''{print }'\'' | xxd -r -p | base64' # obtenir l'empreinte du serveur SSH de la machine en cours
alias jprint='python -mjson.tool' # afficher un fichier JSON de manière lisible
alias maj='. ~/.bashrc' # recharger bashrc (dont les alias) après une modification
alias p8='ping 8.8.8.8' # pour les tests réseau
alias random_pass='< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c8 ; echo' # générer un mot de passe aléatoire
alias se='sudoedit' # éditer un fichier root sans faire tourner son éditeur en root
alias sus='systemctl suspend' # mettre la machine en veille
alias unixtime='date +%s' # obtenir le timestamp unix actuel
alias zkill='kill -9 $(jobs -lp)' # tuer les jobs en arrière-plan (utiles si bloqués)
# fautes courantes (à compléter)
alias gf='fg'
alias gti='git' # etc.
# latest (pour inputrc)
alias latest='/bin/ls -t -1 -d * | head -n 1'


### Prompt
nb_jobs() {
    nb_jobs=$(jobs -s | wc -l)
    if [ "$nb_jobs" -gt 0 ]
    then
        echo -n "[$nb_jobs]"
    fi
}
# Définition des couleurs et de la graisse
couleur=31
col="\033[01;${couleur}m"
white='\033[00m'
grey='\033[01;90m'
bold="$(tput bold)"
normal="$(tput sgr0)"
# On récupère le code de retour de la commande précédente pour afficher un smiley triste en cas d'erreur
smiley() {
    RC=$?
    [[ ${RC} == 0 ]] && echo -e ':)' || echo -e ':('
}
# Et si on affichait une caractère différent en fin de prompt si on est en SSH sur une machine distante ?
ssh_case() {
    if [ ! -z "${SSH_CLIENT}" ]
    then
        echo -e "♡"
    else
        echo -e "♥"
    fi
}
# La définition finale du prompt
PS1="$col\u$white:$col\w$grey\$(nb_jobs)$white$bold\$(smiley)$normal$white\$(ssh_case) "

### Couleurs
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
    alias diff='diff --color=auto'
fi

# Couleurs pour less, utilisé notamment par man
man() {
    LESS_TERMCAP_md=$'\e[01;31m' \
    LESS_TERMCAP_me=$'\e[0m' \
    LESS_TERMCAP_se=$'\e[0m' \
    LESS_TERMCAP_so=$'\e[01;44;33m' \
    LESS_TERMCAP_ue=$'\e[0m' \
    LESS_TERMCAP_us=$'\e[01;32m' \
    command man "$@"
}


### Complétion (bidouillage)
# Cette partie détaille des solutions pour corriger la complétion de commandes remplacées par des aliases

alias z='zathura'
# compléter des lecteurs de pdf avec les fichiers pdf et les répertoires seulement
complete -f -X '!*.[pP][dD][fF]' -o plusdirs evince zathura z

# aptitude
# Source: https://gist.github.com/Stebalien/5632764
_aptitude_all()
{
    local cur dashoptions
    COMPREPLY=()
    cur=`_get_cword`
    dashoptions='-S -u -i -h --help --version -s --simulate -d \
--download-only -P --prompt -y --assume-yes -F \
--display-format -O --sort -w --width -f -r -g \
--with-recommends --with-suggests -R -G \
--without-recommends --without-suggests -t \
--target-release -V --show-versions -D --show-deps\
-Z -v --verbose --purge-unused'
    if [[ "$cur" == -* ]]; then
	COMPREPLY=( $( compgen -W "$dashoptions" -- $cur ) )
    else
	COMPREPLY=( $( apt-cache pkgnames $cur 2> /dev/null ) )
    fi
    return 0
}

_aptitude_installed()
{
    local cur dashoptions
    COMPREPLY=()
    cur=`_get_cword`
    dashoptions='-S -u -i -h --help --version -s --simulate -d \
--download-only -P --prompt -y --assume-yes -F \
--display-format -O --sort -w --width -f -r -g \
--with-recommends --with-suggests -R -G \
--without-recommends --without-suggests -t \
--target-release -V --show-versions -D --show-deps\
-Z -v --verbose --purge-unused'
    if [[ "$cur" == -* ]]; then
	COMPREPLY=( $( compgen -W "$dashoptions" -- $cur ) )
    else
	COMPREPLY=( $( _comp_dpkg_installed_packages $cur ) )
    fi
    return 0
}

# les alias à auto-compléter
alias as='sudo aptitude show'
alias ai='sudo aptitude install'
alias asearch='sudo aptitude search'

# installation de la complétion
complete -F _aptitude_all $default ai
complete -F _aptitude_all $default as
complete -F _aptitude_all $default asearch
# complete -F _aptitude_installed $default uninst

# pacman
# (adapté à partir de l'exemple d'aptitude)
_pacman_all()
{
    local cur dashoptions
    COMPREPLY=()
    cur=`_get_cword`
    dashoptions='-S -u -i -h --help --version -s --simulate -d \
--download-only -P --prompt -y --assume-yes -F \
--display-format -O --sort -w --width -f -r -g \
--with-recommends --with-suggests -R -G \
--without-recommends --without-suggests -t \
--target-release -V --show-versions -D --show-deps\
-Z -v --verbose --purge-unused'
    if [[ "$cur" == -* ]]; then
	COMPREPLY=( $( compgen -W "$dashoptions" -- $cur ) )
    else
	COMPREPLY=( $( pacman -Slq | grep ^$cur 2> /dev/null ) )
    fi
    return 0
}

alias pi='sudo pacman -S'
alias pss='pacman -Ss'

complete -F _pacman_all $default pi
complete -F _pacman_all $default pss

# systemctl
alias ssr='sudo systemctl restart'
alias sss='sudo systemctl status'
alias ssp='sudo systemctl stop'

# On charge les fonctions dans le fichier source de complétion pour systemctl
source /usr/share/bash-completion/completions/systemctl
# On recrée manuellement certaines fonctions
_systemctl_status()
{
        comps=$( __get_non_template_units --system "${COMP_WORDS[1]}" )
        compopt -o filenames
        COMPREPLY=( $(compgen -o filenames -W '$comps') )
        return 0
}

_systemctl_restart()
{
        comps=$( __get_restartable_units --system "${COMP_WORDS[1]}" )
        compopt -o filenames
        COMPREPLY=( $(compgen -o filenames -W '$comps') )
        return 0
}

_systemctl_stop()
{
        comps=$( __get_stoppable_units --system "${COMP_WORDS[1]}" )
        compopt -o filenames
        COMPREPLY=( $(compgen -o filenames -W '$comps') )
        return 0
}

complete -F _systemctl_restart ssr
complete -F _systemctl_status sss
complete -F _systemctl_stop ssp
