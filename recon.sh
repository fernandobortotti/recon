#!/bin/bash

# enum.sh - Script de automação para Recon em Bug Bounty
# Autor: Bortotti
# Versão: 1.2 (17/06/2025)

# =============================
# Tratamento de Sinais
trap 'echo -e "\n[!] Execução interrompida."; exit 1' INT

# =============================
# Cores
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
RESET="\e[0m"

# =============================
# Diretórios de saída
OUTPUT_DIR="output_$RANDOM"
mkdir -p "$OUTPUT_DIR"
cd "$OUTPUT_DIR" || exit

# =============================
# Detectar Distribuição Linux
detect_distro() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo "$ID"
    else
        echo "unknown"
    fi
}

DISTRO=$(detect_distro)
echo -e "${YELLOW}[*] Distribuição detectada: $DISTRO${RESET}"

# =============================
# Checar dependências
REQUIRED_TOOLS=(
    findomain assetfinder subfinder httpx haktrails
    naabu github-search katana anew waybackurls
    gauplus subjs paramspider gf mantra grep tee sort
)

check_dependencies() {
    MISSING=()
    for tool in "${REQUIRED_TOOLS[@]}"; do
        if ! command -v "$tool" &>/dev/null; then
            MISSING+=("$tool")
        fi
    done

    if [ ${#MISSING[@]} -ne 0 ]; then
        echo -e "${RED}[!] As seguintes ferramentas estão faltando:${RESET}"
        for tool in "${MISSING[@]}"; do
            echo -e "${YELLOW} - $tool${RESET}"
        done
        echo -e "${GREEN}[*] Instale-as antes de executar. Exemplo:${RESET}"
        case $DISTRO in
            debian|ubuntu)
                echo "sudo apt install <tool>"
                ;;
            arch)
                echo "sudo pacman -S <tool>"
                ;;
            fedora)
                echo "sudo dnf install <tool>"
                ;;
            opensuse*|suse)
                echo "sudo zypper install <tool>"
                ;;
            *)
                echo "Use o gerenciador de pacotes da sua distro."
                ;;
        esac
        exit 1
    fi
}

check_dependencies

# =============================
# Ler Token do GitHub Search
file_token="$HOME/ferramentasPentest/github-search/token"
if [[ ! -f "$file_token" ]]; then
    echo -e "${RED}[!] Token do GitHub não encontrado em $file_token${RESET}"
    exit 1
fi
token=$(head -n 1 "$file_token")
if [[ -z "$token" ]]; then
    echo -e "${RED}[!] Token do GitHub está vazio.${RESET}"
    exit 1
fi

# =============================
# Processa entrada
while getopts "d:" opt; do
    case $opt in
        d) dominio_alvo="$OPTARG" ;;
        *) echo "Uso: $0 -d dominio_alvo"; exit 1 ;;
    esac
done

if [[ -z "$dominio_alvo" ]]; then
    echo -e "${RED}[!] Erro: domínio não informado.${RESET}"
    echo "Uso: $0 -d dominio.com"
    exit 1
fi

echo -e "${GREEN}[*] Iniciando Recon para: $dominio_alvo${RESET}"

# =============================
# Funções de Recon

enum_subs() {
    echo -e "${YELLOW}[*] Enumerando subdomínios...${RESET}"
    subfinder -d "$dominio_alvo" -all -o sub_subfinder.txt &
    findomain --output -q -t "$dominio_alvo" > sub_findomain.txt &
    assetfinder -subs-only "$dominio_alvo" > sub_assetfinder.txt &
    echo "$dominio_alvo" | haktrails subdomains > sub_haktrails.txt &
    source ~/ambientes_virtuais_ferramentas/github-search/pythonVirtual/bin/activate && \
        python3 ~/ferramentasPentest/github-search/github-subdomains.py -t "$token" -d "$dominio_alvo" > sub_github.txt &
    wait
    cat sub_*.txt | sort -u > subdomains_all.txt
}

check_alive() {
    echo -e "${YELLOW}[*] Verificando domínios ativos...${RESET}"
    naabu -passive -l subdomains_all.txt -o naabu_passive.txt
    httpx -l naabu_passive.txt --silent -o urls_alive.txt
}

collect_urls() {
    echo -e "${YELLOW}[*] Coletando URLs com Katana, Waybackurls e Gaup...${RESET}"
    katana -u naabu_passive.txt -headless | sort -u | anew katana_urls.txt
    cat subdomains_all.txt | waybackurls | anew waybackurls_urls.txt
    cat naabu_passive.txt | gauplus | subjs | grep -E '\.js(on)?' | sort -u > js_files.txt
}

param_discovery() {
    echo -e "${YELLOW}[*] Descobrindo parâmetros e arquivos sensíveis...${RESET}"
    source ~/ambientes_virtuais_ferramentas/github-search/pythonVirtual/bin/activate
    paramspider -l urls_alive.txt -o paramspider_output
    cat katana_urls.txt waybackurls_urls.txt js_files.txt paramspider_output/* | sort -u > full_urls.txt

    grep -E "\.txt|\.log|\.cache|\.secret|\.db|\.backup|\.yml|\.json|\.gz|\.rar|\.zip|\.config" full_urls.txt > sensitive_files.txt
    grep -E "\.js$" full_urls.txt | anew js_files_final.txt
    cat js_files_final.txt | grep https | mantra > mantra_output.txt
}

gf_patterns() {
    echo -e "${YELLOW}[*] Buscando parâmetros interessantes com GF...${RESET}"
    grep -vE '\.(woff|css|png|svg|jpg|woff2|jpeg|gif|js)$' full_urls.txt | anew filtered_urls.txt
    cat filtered_urls.txt | gf xss | anew params_xss.txt
    cat filtered_urls.txt | gf redirect | anew params_redirect.txt
    cat filtered_urls.txt | gf ssrf | anew params_ssrf.txt
}

# =============================
# Execução

enum_subs
check_alive
collect_urls
param_discovery
gf_patterns

echo -e "${GREEN}[✔] Recon finalizado! Saída salva em ${OUTPUT_DIR}${RESET}"
