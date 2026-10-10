```text
 _     _   _ ____    _    ____  _   _
| |   | | | | __ )  / \  / ___|| | | |
| |   | | | |  _ \ / _ \ \___ \| |_| |
| |___| |_| | |_) / ___ \ ___) |  _  |
|_____|\___/|____/_/   \_\____/|_| |_|

       GOOGLE HACKING  •  FILE FINDER  v1.1
```

# LUBASH

**Google Hacking File Finder | Reconnaissance & OSINT**

O Lubash é uma ferramenta de reconhecimento desenvolvida em Bash, com apoio de Python, para automatizar a identificação e o download de arquivos públicos indexados por mecanismos de busca.

A ideia surgiu de algo simples: usar Google Dorks para localizar arquivos em determinados domínios sem precisar realizar as mesmas pesquisas e downloads manualmente toda vez.

O que começou como um pequeno comando utilizando Lynx, grep e wget acabou se tornando uma ferramenta interativa, com interface no terminal, suporte a diferentes extensões e organização automática dos resultados.

## Como funciona?

O Lubash utiliza operadores de busca conhecidos como Google Dorks para identificar arquivos associados a um domínio.

Por exemplo:

`site:exemplo.com filetype:pdf`

Essa consulta procura documentos PDF indexados no domínio informado.

A ferramenta automatiza esse processo, extrai os links encontrados, elimina resultados duplicados e tenta realizar o download dos arquivos.

O Lubash consulta primeiro o Google. Caso não encontre links válidos, utiliza Bing RSS e DuckDuckGo como fontes alternativas.

Tudo isso diretamente pelo terminal, sem precisar modificar o código para cada pesquisa.

## Funcionalidades

- Busca interativa por domínio e extensão.
- Google Dorks utilizando os operadores `site:` e `filetype:`.
- Suporte a diferentes formatos de arquivos.
- Consultas ao Google, Bing RSS e DuckDuckGo.
- Identificação e tratamento de links de redirecionamento.
- Filtragem de resultados pelo domínio e seus subdomínios.
- Remoção de URLs duplicadas.
- Download automatizado utilizando Wget.
- Interface CLI colorida com caixas e animações de carregamento.
- Organização dos arquivos por domínio e extensão.
- Registro de links encontrados e downloads com falha.
- Arquivos de diagnóstico para analisar respostas dos buscadores.
- Importação de URLs a partir de arquivos HTML ou TXT quando a busca automática não retorna resultados.

## Extensões suportadas

| Tipo                 | Extensão                      |
| -------------------- | ----------------------------- |
| Documentos           | PDF, DOC, DOCX, TXT, RTF, ODT |
| Planilhas            | XLS, XLSX, CSV, ODS           |
| Apresentações        | PPT, PPTX                     |
| Dados                | JSON, XML                     |
| Arquivos compactados | ZIP                           |

A opção `docs` realiza pesquisas por `.doc` e `.docx`.

## Instalação

O Lubash foi desenvolvido para ambientes Linux.

**Dependências:**

- Bash
- Python 3
- Wget

Em distribuições baseadas em Arch Linux:

```bash
sudo pacman -S python wget
```

Em distribuições baseadas em Debian ou Ubuntu:

```bash
sudo apt install python3 wget
```

Clone o repositório:

```bash
git clone https://github.com/lunalully/Lubash.git
cd Lubash
```

Dê permissão de execução:

```bash
chmod +x lubash.sh
```

Execute:

```bash
./lubash.sh
```

## Utilização

Ao executar o Lubash, a ferramenta apresenta sua interface e solicita as informações necessárias.

**1. Informe o domínio**

```text
Digite o dominio (ex: exemplo.com): exemplo.com
```

**2. Escolha o tipo de arquivo**

```text
Tipo de arquivo (pdf/txt/xml/doc/docx/docs/csv...): pdf
```

**3. Aguarde a pesquisa**

O Lubash constrói automaticamente a consulta:

```text
site:exemplo.com filetype:pdf
```

Em seguida, realiza as buscas e apresenta a quantidade de links válidos encontrados em cada fonte consultada.

**4. Download dos arquivos**

Caso encontre resultados, a ferramenta inicia o download dos arquivos e apresenta o progresso no terminal.

Ao finalizar, um resumo informa o número de links encontrados, downloads concluídos, falhas e o diretório onde os arquivos foram armazenados.

## Organização dos resultados

Os resultados são armazenados automaticamente na pasta `Lubash_Resultados`, criada no diretório de execução.

Exemplo de estrutura:

```text
Lubash_Resultados/
└── exemplo.com/
    └── pdf/
        ├── arquivos/
        │   ├── documento1.pdf
        │   └── documento2.pdf
        ├── diagnosticos/
        │   └── google_pdf.html
        └── links.txt
```

O diretório `arquivos/` contém os downloads.

O arquivo `links.txt` registra as URLs encontradas.

O diretório `diagnosticos/` armazena respostas dos mecanismos de busca para facilitar a identificação de bloqueios ou problemas na extração dos resultados.

Quando ocorrem falhas de download, o Lubash também registra as URLs em `falhas.txt`.

## E quando a busca não encontra nada?

Mecanismos de busca podem limitar consultas automatizadas, solicitar CAPTCHA ou entregar páginas diferentes das exibidas em um navegador convencional.

Por isso, encontrar zero arquivos pelo Lubash não significa necessariamente que nenhum documento esteja indexado.

Quando isso acontece, a ferramenta oferece uma alternativa:

1. Abrir a consulta apresentada pelo Lubash no navegador.
2. Salvar a página de resultados em HTML ou copiar URLs para um arquivo TXT.
3. Informar o caminho desse arquivo quando solicitado.
4. Deixar o Lubash extrair e validar os links para continuar o processo de download.

Essa opção ajuda quando os buscadores impedem a extração automatizada.

## Aplicações em segurança ofensiva

O Lubash pode auxiliar na fase de reconhecimento passivo de testes de intrusão autorizados.

Arquivos públicos indexados podem revelar informações úteis para o entendimento da superfície de exposição de uma organização, como documentos antigos, metadados, arquivos de configuração indevidamente publicados e informações sobre tecnologias utilizadas.

A ferramenta não explora vulnerabilidades, não realiza autenticação e não garante a identificação de informações sensíveis.

Seu objetivo é facilitar a localização e a coleta de arquivos publicamente acessíveis, que podem ser analisados posteriormente pelo profissional responsável pelo teste.

## Limitações

O funcionamento depende da disponibilidade dos mecanismos de busca e das restrições impostas por eles.

Algumas limitações importantes:

- Resultados podem variar entre buscas manuais e automatizadas.
- CAPTCHA, bloqueios HTTP e limitações de tráfego podem impedir consultas.
- Arquivos não indexados pelos buscadores podem não ser encontrados.
- Links identificados podem estar indisponíveis ou exigir autenticação.
- Nem todo arquivo listado será necessariamente baixado com sucesso.

O Lubash não utiliza técnicas para contornar CAPTCHA ou mecanismos de proteção dos buscadores.

## Uso responsável

O Lubash foi criado com foco em estudos de cybersecurity, OSINT e reconhecimento em ambientes autorizados.

Utilize a ferramenta respeitando as permissões dos sistemas analisados, as regras dos serviços consultados e a legislação aplicável.

Arquivos encontrados não devem ser considerados automaticamente autorizados para acesso, armazenamento ou divulgação apenas por estarem indexados.

## Tecnologias utilizadas

**Bash:** interface interativa, execução e organização dos downloads.

**Python 3:** processamento das respostas dos buscadores, extração, normalização e validação das URLs.

**Wget:** download dos arquivos encontrados.

## Licença

Este projeto está licenciado sob a [GNU Affero General Public License v3.0](LICENSE).

## Sobre o projeto

O Lubash nasceu da vontade de transformar tarefas repetitivas de reconhecimento em ferramentas simples que possam ser executadas diretamente pelo terminal.

Sem precisar decorar comandos enormes ou alterar o código a cada pesquisa.

A proposta é manter uma ferramenta leve, acessível e útil para quem estuda ou trabalha com segurança ofensiva.

**LUBASH v1.1 | Google Hacking File Finder**

Desenvolvido por Luna Ferreira Reges.
