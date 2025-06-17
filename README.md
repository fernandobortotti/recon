# 🕵 Recon Script – `enum.sh`

Automatize a enumeração de subdomínios, descoberta de endpoints e coleta de caminhos sensíveis em programas de Bug Bounty.

---

## 📌 Índice

1. [Sobre](#sobre)
2. [Pré-requisitos](#pré-requisitos)
3. [Instalação](#instalação)
4. [Uso](#uso)
5. [Como funciona](#como-funciona)
6. [Estrutura de saída](#estrutura-de-saída)
7. [Segurança](#segurança)
8. [Contribuições](#contribuições)
9. [Licença](#licença)

---

## Sobre

`enum.sh` realiza as seguintes tarefas:

* Enumeração de subdomínios com Subfinder, Findomain, Assetfinder, Haktrails, GitHub Search.
* Identificação de domínios ativos via Naabu + Httpx.
* Coleta de URLs via Katana, Waybackurls, Gauplus, Subjs.
* Análise de parâmetros com Paramspider e GF (`xss`, `redirect`, `ssrf`).
* Busca por arquivos sensíveis (`*.json`, `*.zip`, etc.) e JS com endpoints.

---

## Pré-requisitos

* Linux (Debian/Ubuntu, Arch, Fedora, openSUSE, etc.)
* As ferramentas abaixo devem estar instaladas (ou o script avisa):

```bash
findomain assetfinder subfinder httpx haktrails naabu katana \
waybackurls gauplus subjs paramspider gf mantra anew grep tee sort
```

* Token válido para `github-search` em:
  `~/$HOME/ferramentasPentest/github-search/token`

O script detecta automaticamente o pacote da sua distro e sugere comandos de instalação para dependências ausentes.

---

## Instalação

1. Clone o repositório:

   ```bash
   git clone https://github.com/fernandobortotti/recon.git
   cd Recon-Script
   ```

2. Dê permissão de execução:

   ```bash
   chmod +x enum.sh
   ```

---

## Uso

```bash
./enum.sh -d exemplo.com
```

* `-d`: domínio-alvo (obrigatório)
* Em caso de interrupção (`CTRL+C`), o script finaliza com segurança.

---

## Como funciona

1. **Detecta** distribuição Linux e verifica dependências.
2. **Lê** token do GitHub Search.
3. **Enumera subdomínios** com diversas ferramentas.
4. **Verifica domínios vivos** com Naabu + Httpx.
5. **Coleta URLs** via Katana, Waybackurls, Gauplus, Subjs.
6. **Descobre parâmetros** com Paramspider e GF.
7. **Aponta arquivos sensíveis**, endpoints JS e caminhos de interesse.

---

## Estrutura de saída

O script gera uma pasta `output_<random>` com:

```
subdomains_all.txt
naabu_passive.txt
urls_alive.txt
katana_urls.txt
waybackurls_urls.txt
js_files.txt
full_urls.txt
sensitive_files.txt
js_files_final.txt
mantra_output.txt
params_xss.txt
params_redirect.txt
params_ssrf.txt
```

Cada arquivo contém dados prontos para análise adicional.

---

## Segurança

* Não armazene chaves ou senhas no repositório — use variáveis de ambiente ou arquivos externos ([projectdiscovery.io][1], [github.com][2], [infosecwriteups.com][3], [github.com][4], [github.com][5]).
* Inclua um `SECURITY.md` com seu procedimento de divulgação responsável (reportes, tempo de resposta, escopo!).
* Utilize GitHub Secret Scanning e ferramentas como `git-secrets` ou `trufflehog` no pipeline ([prplbx.com][6], [gitprotect.io][7]).
* Aplique o princípio do menor privilégio em tokens e acesso ao repositório.

---

## Contribuições

Contribuições são bem-vindas! Preferências:

* Use **Issues** para discussões.
* Envie **Pull Requests** com mudanças claras (script modular, melhorias de logs, parcerias).
* Adicione testes quando possível e atualize `README.md` conforme necessário.

---

## Licença

Este projeto é distribuído sob a licença **MIT** — consulte o arquivo `LICENSE`.
