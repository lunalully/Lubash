#!/usr/bin/env bash
# Lubash v1.1 | Google Hacking File Finder
# Dependencias: bash, python3, wget. Consultas automatizadas dependem dos buscadores.
set -o pipefail

RESET=$'\033[0m'
ROXO=$'\033[1;35m'
CIANO=$'\033[1;36m'
VERDE=$'\033[1;32m'
AMARELO=$'\033[1;33m'
VERMELHO=$'\033[1;31m'

caixa() {
    local titulo="$1"
    printf '\n%s┌──────────────────────────────────────────────────────────┐%s\n' "$ROXO" "$RESET"
    printf '%s│%s %-56.56s %s│%s\n' "$ROXO" "$RESET" "$titulo" "$ROXO" "$RESET"
    printf '%s└──────────────────────────────────────────────────────────┘%s\n' "$ROXO" "$RESET"
}

spinner() {
    local pid="$1" mensagem="$2" frames='|/-\\' i=0 status
    if [[ -t 1 ]]; then
        while kill -0 "$pid" 2>/dev/null; do
            printf '\r%s[%s]%s %s' "$CIANO" "${frames:i++%${#frames}:1}" "$RESET" "$mensagem"
            sleep 0.14
        done
    fi
    wait "$pid"
    status=$?
    if [[ -t 1 ]]; then printf '\r\033[K'; fi
    return "$status"
}

for programa in wget python3; do
    if ! command -v "$programa" >/dev/null 2>&1; then
        printf '%s[ERRO]%s Falta instalar: %s\n' "$VERMELHO" "$RESET" "$programa"
        exit 1
    fi
done

if [[ -t 1 ]] && command -v clear >/dev/null; then clear; fi
printf '%s' "$ROXO"
cat <<'BANNER'
 _     _   _ ____    _    ____  _   _
| |   | | | | __ )  / \  / ___|| | | |
| |   | | | |  _ \ / _ \ \___ \| |_| |
| |___| |_| | |_) / ___ \ ___) |  _  |
|_____|\___/|____/_/   \_\____/|_| |_|
BANNER
printf '%s       GOOGLE HACKING  •  FILE FINDER  v1.1%s\n' "$CIANO" "$RESET"

caixa '01 • CONFIGURACAO DO ALVO'
read -r -p 'Digite o dominio (ex: exemplo.com): ' dominio
dominio="${dominio#http://}"
dominio="${dominio#https://}"
dominio="${dominio%%/*}"
dominio="${dominio%%:*}"
dominio="${dominio,,}"
dominio="${dominio#.}"
if [[ ! "$dominio" =~ ^([a-z0-9]([a-z0-9-]*[a-z0-9])?\.)+[a-z]{2,}$ ]]; then
    printf '%s[ERRO]%s Dominio invalido. Use exemplo.com (sem espacos).\n' "$VERMELHO" "$RESET"
    exit 1
fi

read -r -p 'Tipo de arquivo (pdf/txt/xml/doc/docx/docs/csv...): ' tipo
tipo="${tipo,,}"
tipo="${tipo#.}"
case "$tipo" in
    docs) extensoes=(doc docx) ;;
    pdf|txt|xml|doc|docx|csv|json|xls|xlsx|ppt|pptx|zip|odt|ods|rtf) extensoes=("$tipo") ;;
    *) printf '%s[ERRO]%s Extensao nao suportada.\n' "$VERMELHO" "$RESET"; exit 1 ;;
esac

pasta="Lubash_Resultados/$dominio/$tipo"
mkdir -p -- "$pasta/arquivos" "$pasta/diagnosticos" || exit 1
pasta="$(cd "$pasta" && pwd)"
tmp_dir="$(mktemp -d)" || exit 1
trap 'rm -rf -- "$tmp_dir"' EXIT
links="$pasta/links.txt"
: > "$links"

# Extrator Python embutido: mantem a ferramenta em um UNICO arquivo .sh.
cat > "$tmp_dir/buscador.py" <<'PY'
import base64
import html
import re
import sys
import urllib.error
import urllib.parse
import urllib.request
import xml.etree.ElementTree as ET
from html.parser import HTMLParser
from pathlib import Path

UA = 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0 Safari/537.36'
HEADERS = {'User-Agent': UA, 'Accept-Language': 'pt-BR,pt;q=0.9,en;q=0.8'}
MAX_BYTES = 1_500_000

class Hrefs(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.urls = []

    def handle_starttag(self, tag, attrs):
        if tag not in ('a', 'link'):
            return
        for chave, valor in attrs:
            if chave == 'href' and valor:
                # Google frequentemente devolve /url?q=... em vez de URL absoluta.
                if valor.startswith('/url?'):
                    valor = 'https://www.google.com' + valor
                elif valor.startswith('/l/?'):
                    valor = 'https://duckduckgo.com' + valor
                elif valor.startswith('//'):
                    valor = 'https:' + valor
                self.urls.append(valor)


def desenrolar(url):
    """Normaliza redirecionamentos de buscadores sem seguir links inesperados."""
    url = html.unescape(url.strip()).replace('\\/', '/')
    for _ in range(3):
        try:
            parsed = urllib.parse.urlsplit(url)
            host = (parsed.hostname or '').lower()
        except ValueError:
            return ''
        query = urllib.parse.parse_qs(parsed.query)
        destino = None
        if (host == 'google.com' or host.endswith('.google.com')) and parsed.path == '/url':
            destino = (query.get('url') or query.get('q') or [None])[0]
        elif host.endswith('duckduckgo.com') and parsed.path.startswith('/l/'):
            destino = (query.get('uddg') or [None])[0]
        elif host.endswith('bing.com') and parsed.path.startswith('/ck/a'):
            valor = (query.get('u') or [None])[0]
            if valor and valor.startswith('a1'):
                try:
                    bruto = valor[2:]
                    destino = base64.urlsafe_b64decode(bruto + '=' * (-len(bruto) % 4)).decode('utf-8')
                except (ValueError, UnicodeDecodeError):
                    pass
        if not destino:
            break
        url = destino
    return urllib.parse.urldefrag(url)[0]


def destino_valido(url, dominio, extensoes):
    url = desenrolar(url)
    try:
        p = urllib.parse.urlsplit(url)
        host = (p.hostname or '').lower().rstrip('.')
    except ValueError:
        return None
    if p.scheme not in ('https', 'http'):
        return None
    if host != dominio and not host.endswith('.' + dominio):
        return None
    caminho = urllib.parse.unquote(p.path).lower()
    nome = caminho.rsplit('/', 1)[-1]
    nomes = [nome]
    qs = urllib.parse.parse_qs(p.query)
    for chave in ('file', 'filename', 'name', 'path'):
        nomes += [v.rsplit('/', 1)[-1].lower() for v in qs.get(chave, [])]
    if not any(any(n.endswith('.' + ext) for ext in extensoes) for n in nomes):
        return None
    return url


def extrair_urls(conteudo, formato):
    urls = []
    if formato == 'rss':
        try:
            raiz = ET.fromstring(conteudo)
            for item in raiz.iter():
                if item.tag.rsplit('}', 1)[-1] == 'item':
                    for elemento in item:
                        if elemento.tag.rsplit('}', 1)[-1] == 'link' and elemento.text:
                            urls.append(elemento.text.strip())
        except ET.ParseError:
            pass
    texto = conteudo.decode('utf-8', errors='replace')
    parser = Hrefs()
    if formato != 'rss':
        try:
            parser.feed(texto)
            urls.extend(parser.urls)
        except Exception:
            pass
    # Complemento: URLs expostas em HTML/JS e links copiados de resultados.
    texto = html.unescape(texto).replace('\\/', '/')
    urls.extend(re.findall(r'https?://[^\s<>"\'\\]+', texto))
    return [u.strip().rstrip(').,];') for u in urls]


def baixar_pagina(url):
    req = urllib.request.Request(url, headers=HEADERS)
    try:
        with urllib.request.urlopen(req, timeout=14) as response:
            return response.read(MAX_BYTES), response.geturl(), None
    except urllib.error.HTTPError as exc:
        try:
            body = exc.read(150_000)
        except Exception:
            body = b''
        return body, url, f'HTTP {exc.code}'
    except Exception as exc:
        return b'', url, f'{type(exc).__name__}: {exc}'


def bloqueado(nome, conteudo, url_final, erro):
    if erro and any(x in erro for x in ('HTTP 403', 'HTTP 429', 'HTTP 503')):
        return True
    if nome != 'Google':
        return False
    trecho = conteudo[:300_000].decode('utf-8', errors='replace').lower()
    return ('consent.google.' in url_final or '/sorry/' in url_final or
            'unusual traffic from your computer network' in trecho or
            'our systems have detected unusual traffic' in trecho or
            'before you continue to google' in trecho)


def pesquisa(dominio, extensao, diagnosticos):
    q = f'site:{dominio} filetype:{extensao}'
    q_esc = urllib.parse.urlencode({'q': q})
    urls = [
        ('Google', 'html', 'https://www.google.com/search?' + q_esc + '&num=50'),
        ('Bing RSS', 'rss', 'https://www.bing.com/search?format=rss&' + q_esc + '&count=50'),
        ('DuckDuckGo', 'html', 'https://html.duckduckgo.com/html/?' + q_esc),
    ]
    encontrados = set()
    for nome, formato, endereco in urls:
        corpo, url_final, erro = baixar_pagina(endereco)
        arquivo = diagnosticos / (nome.lower().replace(' ', '_') + '_' + extensao + ('.xml' if formato == 'rss' else '.html'))
        # Mantem evidencias para distinguir bloqueio de ausencia de resultados.
        arquivo.write_bytes(corpo)
        if bloqueado(nome, corpo, url_final, erro):
            print(f'{nome}: acesso automatizado bloqueado ({erro or "consentimento/CAPTCHA"}).')
            continue
        candidatos = extrair_urls(corpo, formato)
        novos = {u for c in candidatos if (u := destino_valido(c, dominio, {extensao}))}
        encontrados.update(novos)
        print(f'{nome}: {len(novos)} link(s) valido(s)' + (f' [{erro}]' if erro else ''))
        # As fontes alternativas so sao consultadas se a anterior nao trouxe arquivos.
        if encontrados:
            break
    return encontrados


def importar(arquivo, dominio, extensoes):
    conteudo = Path(arquivo).read_bytes()
    formato = 'rss' if arquivo.lower().endswith('.xml') else 'html'
    return sorted({u for c in extrair_urls(conteudo, formato)
                   if (u := destino_valido(c, dominio, extensoes))})


if __name__ == '__main__':
    acao = sys.argv[1]
    if acao == 'buscar':
        _, _, dominio, ext, diag, saida = sys.argv
        resultados = sorted(pesquisa(dominio, ext, Path(diag)))
        Path(saida).write_text('\n'.join(resultados) + ('\n' if resultados else ''), encoding='utf-8')
    elif acao == 'importar':
        _, _, dominio, exts, arquivo, saida = sys.argv
        resultados = importar(arquivo, dominio, set(exts.split(',')))
        Path(saida).write_text('\n'.join(resultados) + ('\n' if resultados else ''), encoding='utf-8')
    else:
        raise SystemExit('Acao desconhecida')
PY

caixa '02 • GOOGLE HACKING / BUSCA'
printf '%s[INFO]%s Google primeiro; Bing RSS e DuckDuckGo se nao houver links.\n' "$CIANO" "$RESET"
for ext in "${extensoes[@]}"; do
    printf '\n%sDork:%s site:%s filetype:%s\n' "$AMARELO" "$RESET" "$dominio" "$ext"
    python3 "$tmp_dir/buscador.py" buscar "$dominio" "$ext" "$pasta/diagnosticos" "$tmp_dir/links_$ext.txt" > "$tmp_dir/log_$ext.txt" 2>&1 &
    if spinner "$!" "Buscando .$ext nos buscadores"; then
        while IFS= read -r mensagem; do
            printf '  %s\n' "$mensagem"
        done < "$tmp_dir/log_$ext.txt"
        cat "$tmp_dir/links_$ext.txt" >> "$links"
    else
        printf '%s[ERRO]%s Falha no extrator .%s:\n' "$VERMELHO" "$RESET" "$ext"
        cat "$tmp_dir/log_$ext.txt"
    fi
done

sort -u "$links" -o "$links"
mapfile -t urls < "$links"
total="${#urls[@]}"
printf '\n%s[RESULTADO]%s %d link(s) encontrado(s).\n' "$CIANO" "$RESET" "$total"
printf 'Lista: %s\n' "$links"

if ((total == 0)); then
    printf '\n%s[AVISO]%s Resultado zero NAO significa que nao existem arquivos no Google.\n' "$AMARELO" "$RESET"
    printf 'Buscadores podem mostrar CAPTCHA, bloquear automacao ou devolver HTML incompleto.\n'
    printf 'Respostas salvas em: %s/diagnosticos\n' "$pasta"
    printf '\nAbra no navegador a busca:\n'
    python3 - "$dominio" "${extensoes[0]}" <<'PY'
import sys
from urllib.parse import urlencode
q = f'site:{sys.argv[1]} filetype:{sys.argv[2]}'
print('https://www.google.com/search?' + urlencode({'q': q}))
PY
    printf '\nOpcional: salve a pagina do Google como .html ou copie URLs para um .txt.\n'
    read -r -p 'Caminho para importar HTML/TXT (Enter para encerrar): ' arquivo_importado
    if [[ -n "$arquivo_importado" ]]; then
        arquivo_importado="${arquivo_importado/#\~/$HOME}"
        if [[ -f "$arquivo_importado" && -r "$arquivo_importado" ]]; then
            extensoes_csv="$(IFS=,; echo "${extensoes[*]}")"
            if python3 "$tmp_dir/buscador.py" importar "$dominio" "$extensoes_csv" "$arquivo_importado" "$links"; then
                mapfile -t urls < "$links"
                total="${#urls[@]}"
                printf '%s[IMPORTACAO]%s %d link(s) valido(s).\n' "$CIANO" "$RESET" "$total"
            else
                printf '%s[ERRO]%s Nao foi possivel importar o arquivo.\n' "$VERMELHO" "$RESET"
            fi
        else
            printf '%s[ERRO]%s Arquivo nao encontrado ou sem permissao.\n' "$VERMELHO" "$RESET"
        fi
    fi
fi

if ((total == 0)); then exit 0; fi

caixa '03 • DOWNLOAD DOS ARQUIVOS'
acertos=0
falhas=0
for i in "${!urls[@]}"; do
    url="${urls[i]}"
    wget -q -nc --content-disposition --trust-server-names --timeout=20 --tries=2 --max-redirect=5 \
        -P "$pasta/arquivos" -- "$url" > "$tmp_dir/wget_$i.log" 2>&1 &
    if spinner "$!" "Baixando $((i+1))/$total"; then
        ((acertos+=1))
        printf '%s[OK]%s %d/%d - %s\n' "$VERDE" "$RESET" "$((i+1))" "$total" "$url"
    else
        ((falhas+=1))
        printf '%s[FALHA]%s %d/%d - %s\n' "$VERMELHO" "$RESET" "$((i+1))" "$total" "$url"
        printf '%s\n' "$url" >> "$pasta/falhas.txt"
    fi
done

caixa '04 • RESUMO'
printf 'Dominio: %s\nLinks encontrados: %d\nDownloads OK: %d\nFalhas: %d\nArquivos: %s\n' \
    "$dominio" "$total" "$acertos" "$falhas" "$pasta/arquivos"
