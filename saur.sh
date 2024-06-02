#!/bin/bash
###SAUR - Superlight AUR Installer by Psygreg
#create temp folder
TEMP="$(mktemp -d)"
REMOVE=false
##FUNCTIONS
#-h
usage() {
  echo "saur [-h] [-r] <repository-name>"
  echo "saur <repository-name>"
  echo "-r    Removes the specified repository"
  echo "-h    Displays this message"
  echo "-s    Searches if the specified repository is available"
  exit 1
}
#get language from OS
get_lang() {
    local lang="${LANG:0:2}"
    local available=("pt" "en")

    if [[ " ${available[*]} " == *"$lang"* ]]; then
        ulang="$lang"
    else
        ulang="en"
    fi
}
#messages
lmesg() {
    if [ "$ulang" == "en" ]; then
        msgfail="Repository not found."
        msginit="Package found on AUR! Would you like to install?"
        msgpacman="Package found on Pacman! Would you like to install?"
        msgroot="Do not run Saur as root."
    elif [ "$ulang" == "pt" ]; then
        msgfail="Repositório não encontrado."
        msginit="Pacote encontrado no AUR! Gostaria de instalar?"
        msgpacman="Pacote encontrado no Pacman! Gostaria de instalar?"
        msgroot="Não execute Saur como root."
    fi
}
#build and install
make_func() {
    git clone "$REPO_URL" "$TEMP"
    cd "$TEMP" || exit 5
    makepkg -si
}
#check if repo exists in official/multilib
pacman_check() {
	if pacman -Si "$1" &> /dev/null; then
	    echo "$msgpacman"
	    select yn in "Yes" "No"; do
            case $yn in
                Yes ) 
                    pacman -S --needed "$1";
                    exit 0;;
                No)
                    break;;
            esac
        done
    fi
}
#check if repo exists in Flathub
flat_check() {
	if pacman -Qs flatpak > /dev/null; then
	    if flatpak search "$1" | grep -q "$1"; then
	        flatpak install "$1"
	        exit 0
	    fi
	fi
}
#check if repo exists in the AUR
aur_check() {
    if git clone "$REPO_URL" "$TEMP" &> /dev/null; then
        echo "$msginit"
        select yn in "Yes" "No"; do
            case $yn in
                Yes ) 
                    make_func;
                    exit 0;;
                No)
                    exit 0;;
            esac
        done
    else
        echo "$msgfail"
        exit 4
    fi
}
#cleanup
cleanup() {
    rm -rf "$TEMP"
}
#remove
saur_rm() {
    sudo pacman -R "$1"
    exit 0
}
##SCRIPT RUN START
#get language
get_lang
lmesg
#root checker
if (( ! UID )); then
	echo "$msgroot"
	exit 2
else
    #saur command
    if [ $# -lt 1 ]; then
        sudo pacman -Syu
        if pacman -Qs flatpak > /dev/null; then
            flatpak update
        fi
        if command -v timeshift &> /dev/null; then
            sudo timeshift --create --comments "Saur Update" --tags W
        fi
        exit 0
    fi
    fi
    #set trap to cleanup on exit
    trap cleanup EXIT
    #get options
    while getopts "hr" opt; do
        case ${opt} in
            h )
                usage;;
            r )
                REMOVE=true;;
            \? )
                usage;;
        esac
    done
    shift $((OPTIND -1))
    if [ -z "$1" ]; then
        usage
    fi
    #remove hook
    if [ "$REMOVE" == true ]; then
        saur_rm "$1"
    else
        #install
        REPO_URL="https://aur.archlinux.org/${1}.git"
        pacman_check "$1"
        flat_check "$1"
        aur_check "$1"
    fi
fi
