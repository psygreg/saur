#!/bin/bash
####SAUR - Superlight AUR Installer by Psygreg
#create temp folder
TEST="$(mktemp -d -t saurXXXXXX)"
TEMP="$(mktemp -d -t saurXXXXXX)"
REMOVE=false
PACMAN_ONLY=false
FLATPAK_ONLY=false
AUR_ONLY=false
MODCONFIRM=false
MODUPDATE=false
MODSEARCH=false
RED='\033[1;31m'
NC='\033[0m'
CYAN='\033[1;36m'
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
	#en-US
    if [ "$ulang" == "en" ]; then
        msgfail="${RED}Package not found.${NC}"
        msginit="${CYAN}Package found on AUR! Would you like to install?${NC}"
        msgpacman="${CYAN}Package found on Pacman! Would you like to install?${NC}"
        msgroot="${RED}Do not run Saur as root.${NC}"
        pacfail="${RED}Package not found in official/multilib repositories.${NC}"
        flatoff="${RED}You haven't installed flatpak.${NC} To install it run 'saur flatpak'"
        flatfail="${RED}Package not found on Flathub.${NC}"
        notpacman="${RED}This package is not installed.${NC}"
        aurfound="${CYAN}was found in the AUR.${NC}"
        usage() {
            echo -e "saur ${RED}[-h] [-r]${NC} <package-name>"
            echo "saur <package-name>"
            echo -e "${RED}-r${NC}    Removes the specified package"
            echo -e "${RED}-h${NC}    Displays this message"
            echo -e "${RED}-p${NC}    Search only from official/multilib repositories"
            echo -e "${RED}-f${NC}    Search only from Flathub"
            echo -e "${RED}-a${NC}    Search only from AUR"
            echo -e "${RED}-u${NC}    Update or reinstall the specified package" 
            echo -e "${RED}-[p][f][a]y${NC}    Presumes all confirmed"
            echo -e "${RED}-s[p][f][a]${NC}    Searches if the specified package is available, without installing"
        }
    #pt-BR
    elif [ "$ulang" == "pt" ]; then
        msgfail="${RED}Pacote não encontrado.${NC}"
        msginit="${CYAN}Pacote encontrado no AUR! Gostaria de instalar?${NC}"
        msgpacman="${CYAN}Pacote encontrado no Pacman! Gostaria de instalar?${NC}"
        msgroot="${RED}Não execute Saur como root.${NC}"
        pacfail="${RED}Pacote não encontrado nos repositórios oficial/multilib.${NC}"
        flatoff="${RED}Você não tem flatpak instalado.${NC} Para instalar use 'saur flatpak'"
        flatfail="${RED}Pacote não encontrado no Flathub.${NC}"
        notpacman="${RED}Este pacote não está instalado.${NC}"
        aurfound="${CYAN}foi encontrado no AUR.${NC}"
        usage() {
            echo -e "saur ${RED}[-h] [-r]${NC} <nome-do-pacote>"
            echo "saur <nome-do-pacote>"
            echo -e "${RED}-r${NC}    Remove o pacote especificado"
            echo -e "${RED}-h${NC}    Exibe esta mensagem"
            echo -e "${RED}-p${NC}    Busca somente nos repositórios oficial/multilib"
            echo -e "${RED}-f${NC}    Busca somente no Flathub"
            echo -e "${RED}-a${NC}    Busca somente no AUR"
            echo -e "${RED}-u${NC}    Atualiza ou reinstala o pacote especificado"
            echo -e "${RED}-[p][f][a]y${NC}    Presume todos confirmados"
            echo -e "${RED}-s[p][f][a]${NC}    Procura se o pacote especificado está disponível, sem instalar"
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
	    echo -e "$msgpacman"
	    select yn in "Yes" "No"; do
            case $yn in
                Yes ) 
                    sudo pacman -S --needed --noconfirm "$1";
                    exit 0;;
                No)
                    break;;
            esac
        done
    else
        echo -e "$pacfail"
    fi
}
#for -y flag
pacman_confirm() {
	if pacman -Si "$1" &> /dev/null; then
	    sudo pacman -S --needed --noconfirm "$1"
	else
	    echo -e "$pacfail"
	fi
}
##check if repo exists in Flathub
flat_check() {
	if pacman -Qs flatpak > /dev/null; then
	    if flatpak search "$1" | grep -q "$1"; then
	        flatpak install "$1"
	    else
	        echo -e "$flatfail"
	    fi
	else
	    echo -e "$flatoff"
	fi
}
#for -y flag
flat_confirm() {
    if pacman -Qs flatpak > /dev/null; then
	    if flatpak search "$1" | grep -q "$1"; then
	        flatpak install -y --noninteractive "$1"
	    else
	        echo -e "$flatfail"
	    fi
	else
	    echo -e "$flatoff"
	fi
}
##check if repo exists in the AUR
aur_check() {
    if git clone "$REPO_URL" "$TEST" &> /dev/null; then
        echo -e "$msginit"
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
        echo -e "$msgfail"
    fi
}
#for -y flag
aur_confirm() {
    if git clone "$REPO_URL" "$TEST" &> /dev/null; then
        make_func
    else
        echo -e "$msgfail"
    fi
}
#cleanup
cleanup() {
    rm -rf "$TEMP" 
    rm -rf "$TEST"
}
#remove function
saur_rm() {
	if pacman -Qs "$1" > /dev/null; then
        sudo pacman -R "$1"
    elif pacman -Qs flatpak > /dev/null; then
        if flatpak list --app | grep -q "$1"; then
            flatpak remove "$1"
        fi
    else
        echo -e "$notpacman"
    fi
}
#update funcion
saur_upd() {
	if pacman -Qs "$1" > /dev/null; then
	    pacman_confirm	
        sudo pacman -R "$1"
        aur_confirm
    elif flatpak list --app | grep -q "$1"; then
        flatpak update "$1"
    else
        echo -e "$notpacman"
    fi
}
#search functions
pacman_src() {
	if pacman -Si "$1" &> /dev/null; then
	    pacman -Si "$1"
	    exit 0
	else
	    echo -e "$pacfail"
	fi
}
flat_src() {
	if flatpak search "$1" | grep -q "$1"; then
	    flatpak search "$1"
	    exit 0
	else
	    echo -e "$flatfail"
	fi
}
aur_src() {
	if git clone "$REPO_URL" "$TEMP" &> /dev/null; then
	    echo "'$1' $aurfound"
	else
	    echo -e "$msgfail"
	fi
} 
##SCRIPT RUN START
#get language
get_lang
lmesg
#root checker
if (( ! UID )); then
	echo -e "$msgroot"
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
    for pkg in "$@"; do ##CHECAR EXITS E MOVÊ-LOS PARA FORA DAS FUNÇÕES SE NÃO FOREM ERROS
        REPO_URL="https://aur.archlinux.org/${pkg}.git"
        if [ "$REMOVE" == true ]; then
            saur_rm "$pkg"
        elif [ "$MODUPDATE" == true ]; then
            saur_upd "$PACKAGE"
        elif [ "$MODCONFIRM" == true ]; then
            if [ "$PACMAN_ONLY" == true ]; then
                pacman_confirm "$pkg"
            elif [ "$FLATPAK_ONLY" == true ]; then
                flat_confirm "$pkg"
            elif [ "$AUR_ONLY" == true ]; then
                aur_confirm "$pkg"
            else
                pacman_confirm "$pkg"
                flat_confirm "$pkg"
                aur_confirm "$pkg"
            fi
        elif [ "$MODSEARCH" == true ]; then
            if [ "$PACMAN_ONLY" == true ]; then
                pacman_src "$pkg"
            elif [ "$FLATPAK_ONLY" == true ]; then
                flat_src "$pkg"
			elif [ "$AUR_ONLY" == true ]; then
				aur_src "$pkg"
			else
				pacman_src "$pkg"
				flat_src "$pkg"
				aur_src "$pkg"
			fi
		elif [ "$PACMAN_ONLY" == true ]; then
			pacman_check "$pkg"
		elif [ "$FLATPAK_ONLY" == true ]; then
			flat_check "$pkg"
		elif [ "$AUR_ONLY" == true ]; then
			aur_check "$pkg"
		else
			pacman_check "$pkg"
			flat_check "$pkg"
			aur_check "$pkg"
		fi
	done
	exit 0
fi
