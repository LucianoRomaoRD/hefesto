#/bin/bash

#General vars
_CDIR="$(pwd)"
_GITDIR="${_CDIR}/.git"

#Colors
_RED="\e[31m"
_GREEN="\e[32m"
_YELLOW="\e[33m"
_BOLD='\e[1m'
_RESET='\e[0m'
_ERROR="${_BOLD}${_RED}[!]${_RESET}"
_WARN="${_BOLD}${_YELLOW}[*]${_RESET}"

#Log dir
_LOG="${HOME}/hefesto.log"

help() {
    echo -e "\n${_BOLD} Argumentos obrigátorios ${_RESET}
    -d domino               - Domínio que deve ter o cluster criado
    -n subnetwork_name      - Nome da subnetwork criada no hostproject
    -env stg|prd            - Ambiente o qual deve ter o cluster criado.
    "
    exit 99
}

logger() {
    echo -e "${1}"
    echo -e "$(date +'%d-%m-%Y %H:%M:%S')  ${1}" >> ${_LOG}
}

#basic validations
if [[ ! -d ${_GITDIR} ]]
then
    logger "${_ERROR} Você deve executar o script em um diretório de repositório."
    exit 1
fi

if [[ -z $(grep -ri 'tf-projects' ${_GITDIR}/config 2>/dev/null) ]]
then
    logger "${_ERROR} Esse script pode ser executado apenas no repostório ${_BOLD}tf-projects${_RESET}."
    exit 1
fi

if [[ ! -d ${_CDIR}/domains/template_dominio/rd-template-prd-01 ]]
then
    logger "${_ERROR} Diretório de templates não localizado, por favor, verifique."
    exit 1
fi

if [[ $# == 0 ]]
then
    help
fi

#Opts validations
while getopts "d:n:h:e": opt; do
    case ${opt} in
        d) domain=${OPTARG} ;;
        n) network=${OPTARG} ;;
        e) env=$(echo ${OPTARG} | tr '[:upper:]' '[:lower:]');;
        h) help ;;
        *) help
    esac

done

#Post options validations
if [[ -z $(echo ${env} | egrep -i 'stg|prd') ]]
then
    logger "${_ERROR} tipo de ambiente inválido. Ambiente repassado ${_YELLOW}${env:-NULL}${_RESET}"
    help
fi

if [[ ! -d ${_CDIR}/domains/${domain} ]]
then
    logger "${_ERROR} O projeto do domínio ${_BOLD}${domain}${_RESET} parece não existir, por favor, verifique!"
    exit 3
fi

if [[ ! -d ${_CDIR}/domains/${domain}/rd-${domain}-${env}-01 ]]
then
    logger "${_ERROR} O projeto  de ${_BOLD}${env}${_RESET} do domínio ${_BOLD}${domain}${_RESET} parece não existir, por favor, verifique!"
    exit 3
fi

#Starting actions

if [[ -f ${_CDIR}/domains/${domain}/rd-${domain}-${env}-01/gke.tf ]]
then
    logger "O arquivo gke.tf já existe para o domínio ${domain}-${env}"
    read -p  "gke.tf já existe, deseja remover o mesmo? (S/N)" opt
    

    if [[ $(echo ${opt} | grep -i s) ]]
    then
        logger "Movendo ${_CDIR}/domains/${domain}/rd-${domain}-${env}-01/gke.tf"
        cp -pv ${_CDIR}/domains/${domain}/rd-${domain}-${env}-01/gke.tf{,-$(date +'%d%m%Y%H%M%S')} | tee -a ${_LOG}

    else
        exit 0
    fi
fi

logger "${_WARN} Copiando o arquivo gke.tf"
cp -pv ${_CDIR}/domains/template_dominio/rd-template-prd-01/gke.tf ${_CDIR}/domains/${domain}/rd-${domain}-${env}-01/gke.tf | tee -a ${_LOG}