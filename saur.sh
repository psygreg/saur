#!/bin/bash
####SAUR - Superlight AUR Installer by Psygreg
#create temp folder
TEMP="$(mktemp -d)"
REMOVE=false
PACMAN_ONLY=false
FLATPAK_ONLY=false
AUR_ONLY=false
MODCONFIRM=false
MODUPDATE=false
MODSEARCH=false
###FUNCTIONS
#-h
##get language from OS
get_lang() {
    local lang="${LANG:0:2}"
    local available=("pt" "en")

    if [[ " ${available[*]} " == *"$lang"* ]]; then
        ulang="$lang"
    else
        ulang="en"
    fi
}
#languages and messages
lmesg() {
    if [ "$ulang" == "en" ]; then
        msgfail="Package not found."
        msginit="Package found on AUR! Would you like to install?"
        msgpacman="Package found on Pacman! Would you like to install?"
        msgroot="Do not run Saur as root."
        pacfail="Package not found in official/multilib repositories."
        flatoff="You haven't installed flatpak. To install it run 'saur flatpak'"
        flatfail="Package not found on Flathub."
        notpacman="This package is not installed."
        aurfound="was found in the AUR."
        usage() {
            echo "saur [-h] [-r] <package-name>"
            echo "saur <package-name>"
            echo "-r    Removes the specified package"
            echo "-h    Displays this message"
            echo "-p    Search only from official/multilib repositories"
            echo "-f    Search only from Flathub"
            echo "-a    Search only from AUR"
            echo "-u    Update or reinstall the specified package" 
            echo "-[p][f][a]y    Presumes all confirmed"
            echo "-s[p][f][a]    Searches if the specified package is available, without installing" ##TODO
        }
    elif [ "$ulang" == "pt" ]; then
        msgfail="Pacote não encontrado."
        msginit="Pacote encontrado no AUR! Gostaria de instalar?"
        msgpacman="Pacote encontrado no Pacman! Gostaria de instalar?"
        msgroot="Não execute Saur como root."
        pacfail="Pacote não encontrado nos repositórios oficial/multilib."
        flatoff="Você não tem flatpak instalado. Para instalar use 'saur flatpak'"
        flatfail="Pacote não encontrado no Flathub."
        notpacman="Este pacote não está instalado."
        aurfound="foi encontrado no AUR."
        usage() {
            echo "saur [-h] [-r] <nome-do-pacote>"
            echo "saur <nome-do-pacote>"
            echo "-r    Remove o pacote especificado"
            echo "-h    Exibe esta mensagem"
            echo "-p    Busca somente nos repositórios oficial/multilib"
            echo "-f    Busca somente no Flathub"
            echo "-a    Busca somente no AUR"
            echo "-u    Atualiza ou reinstala o pacote especificado"
            echo "-[p][f][a]y    Presume todos confirmados"
            echo "-s[p][f][a]    Procura se o pacote especificado está disponível, sem instalar" ##TODO
        }
    fi
}
##build and install
make_func() {
    git clone "$REPO_URL" "$TEMP"
    cd "$TEMP" || exit 5
    makepkg -si
}
##check if repo exists in official/multilib
pacman_check() {
	if pacman -Si "$1" &> /dev/null; then
	    echo "$msgpacman"
	    select yn in "Yes" "No"; do
            case $yn in
                Yes ) 
                    pacman -S --needed --noconfirm "$1";
                    exit 0;;
                No)
                    break;;
            esac
        done
    else
        echo "$pacfail"
    fi
}
#for -y flag
pacman_confirm() {
	if pacman -Si "$1" &> /dev/null; then
	    pacman -S --needed --noconfirm "$1"
	    exit 0
	else
	    echo "$pacfail"
	fi
}
##check if repo exists in Flathub
flat_check() {
	if pacman -Qs flatpak > /dev/null; then
	    if flatpak search "$1" | grep -q "$1"; then
	        flatpak install "$1"
	        exit 0
	    else
	        echo "$flatfail"
	    fi
	else
	    echo "$flatoff"
	fi
}
#for -y flag
flat_confirm() {
    if pacman -Qs flatpak > /dev/null; then
	    if flatpak search "$1" | grep -q "$1"; then
	        flatpak install -y --noninteractive "$1"
	        exit 0
	    else
	        echo "$flatfail"
	    fi
	else
	    echo "$flatoff"
	fi
}
##check if repo exists in the AUR
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
#for -y flag
aur_confirm() {
    if git clone "$REPO_URL" "$TEMP" &> /dev/null; then
        make_func
        exit 0
    else
        echo "$msgfail"
    fi
}
#cleanup
cleanup() {
    rm -rf "$TEMP"
}
#remove function
saur_rm() {
	if pacman -Qs "$1" > /dev/null; then
        sudo pacman -R "$1"
        exit 0
    elif pacman -Qs flatpak > /dev/null; then
        if flatpak list --app | grep -q "$1"; then
            flatpak remove "$1"
            exit 0
        fi
    else
        echo "$notpacman"
        exit 4
    fi
}
#update funcion
saur_upd() {
	if pacman -Qs "$1" > /dev/null; then
	    pacman_confirm	
        sudo pacman -R "$1"
        aur_confirm
        exit 0
    elif flatpak list --app | grep -q "$1"; then
        flatpak update "$1"
        exit 0
    else
        echo "$notpacman"
        exit 4
    fi
}
#search functions
pacman_src() {
	if pacman -Si "$1" &> /dev/null; then
	    pacman -Si "$1"
	    exit 0
	else
	    echo "$pacfail"
	fi
}
flat_src() {
	if flatpak search "$1" | grep -q "$1"; then
	    flatpak search "$1"
	    exit 0
	else
	    echo "$flatfail"
	fi
}
aur_src() {
	if git clone "$REPO_URL" "$TEMP" &> /dev/null; then
	    echo "'$1' $aurfound"
	    exit 0
	else
	    echo "$msgfail"
	    exit 4
	fi
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
    #set trap to cleanup on exit
    trap cleanup EXIT
    #get options
    while getopts "yhrpfaus" opt; do ##FIX: NOT WORKING WITH DOUBLE-LETTER OPTS
        case ${opt} in
            h )
                usage;;
            r )
                REMOVE=true;;
            p )
                PACMAN_ONLY=true;;
            f ) 
                FLATPAK_ONLY=true;;
            a ) 
                AUR_ONLY=true;;
            y )  
                MODCONFIRM=true;;
            u ) 
                MODUPDATE=true;;
            s ) 
                MODSEARCH=true;;
            \? )
                usage;;
        esac
    done
    shift $((OPTIND -1))
    #get arguments
    for arg in "$@"; do
        case "$arg" in
			ay )
				AUR_ONLY=true
				MODCONFIRM=true;;
			fy )
				FLATPAK_ONLY=true
				MODCONFIRM=true;;
			py )
				PACMAN_ONLY=true
				MODCONFIRM=true;;
			sa )
				MODSEARCH=true
				AUR_ONLY=true;;
			sf )
				MODSEARCH=true
				FLATPAK_ONLY=true;;
			sp )
				MODSEARCH=true
				PACMAN_ONLY=true;;
		esac
	done
    if [ -z "$1" ]; then
        usage
    fi
    #options
    for PACKAGE in "$@"; do
        REPO_URL="https://aur.archlinux.org/${PACKAGE}.git"
        if [ "$REMOVE" == true ]; then
            saur_rm "$PACKAGE"
        elif [ "$MODUPDATE" == true ]; then
            saur_upd "$PACKAGE"
        elif [ "$MODCONFIRM" == true ]; then
            if [ "$PACMAN_ONLY" == true ]; then
                pacman_confirm "$PACKAGE"
                exit 4
            elif [ "$FLATPAK_ONLY" == true ]; then
                flat_confirm "$PACKAGE"
                exit 4
            elif [ "$AUR_ONLY" == true ]; then
                aur_confirm "$PACKAGE"
                exit 4
            else
                pacman_confirm "$PACKAGE"
                flat_confirm "$PACKAGE"
                aur_confirm "$PACKAGE"
                exit 4
            fi
        elif [ "$MODSEARCH" == true ]; then
            if [ "$PACMAN_ONLY" == true ]; then
                pacman_src "$PACKAGE"
                exit 4
            elif [ "$FLATPAK_ONLY" == true ]; then
                flat_src "$PACKAGE"
				exit 4
			elif [ "$AUR_ONLY" == true ]; then
				aur_src "$PACKAGE"
			else
				pacman_src "$PACKAGE"
				flat_src "$PACKAGE"
				aur_src "$PACKAGE"
			fi
		elif [ "$PACMAN_ONLY" == true ]; then
			pacman_check "$PACKAGE"
			exit 0
		elif [ "$FLATPAK_ONLY" == true ]; then
			flat_check "$PACKAGE"
			exit 0
		elif [ "$AUR_ONLY" == true ]; then
			aur_check "$PACKAGE"
		else
			pacman_check "$PACKAGE"
			flat_check "$PACKAGE"
			aur_check "$PACKAGE"
		fi
	done
fi
