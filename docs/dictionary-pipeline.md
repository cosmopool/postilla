# Pipeline do dicionário

Como gerar o banco SQLite do dicionário italiano. Os campos e as transformações estão em [dictionary.md](dictionary.md).

## Resumo

Um script baixa os dados do Wiktionary italiano, aplica as transformações, monta um banco SQLite e o comprime.

```
kaikki.org (JSONL do it.wiktionary) ─┐
                                     ├─► transformar ─► SQLite ─► comprimir
dumps.wikimedia.org (wikitext)  ─────┘
```

## Fontes

As duas fontes vêm do mesmo dump mensal do it.wiktionary. O script deve usar a mesma data nas duas.

| Fonte | Arquivo | Tamanho (dump de 2026-10-01) | Para quê |
|---|---|---|---|
| [kaikki.org](https://kaikki.org/itwiktionary/Italiano/index.html) | `kaikki.org-dictionary-Italiano.jsonl.gz` | 41 MB (478 MB descompactado) | Quase tudo: verbetes já estruturados pelo [wiktextract](https://github.com/tatuylonen/wiktextract) |
| [dumps.wikimedia.org](https://dumps.wikimedia.org/itwiktionary/) | `itwiktionary-<data>-pages-articles.xml.bz2` | 71 MB | Só as seções Termini correlati, Alterati e Da non confondere con |

Por que duas fontes: o wiktextract junta Termini correlati, Varianti, Alterati e Da non confondere con no mesmo campo `related` e não marca de qual seção cada palavra veio (ver `LINKAGE_SECTIONS` em `extractor/it/section_titles.py`). Essas três seções são listas simples de links, então o script as lê direto do wikitext.

## Etapas

### 1. Baixar

- Baixa os dois arquivos da data escolhida.
- Guarda a data do dump, as URLs e o sha256 de cada arquivo para gravar em `meta` (etapa 5).
- Os arquivos brutos ficam fora do controle de versão (`data/`).

### 2. Separar lemas e formas

O JSONL tem 560.689 entradas. 485 mil delas (86%) são formas flexionadas: todos os sentidos são `form_of`/`alt_of` ("siede → sedere").

- **Lemas** (75.590): viram verbetes.
- **Formas**: não viram verbete. Alimentam o índice forma → lema.

### 3. Extrair seções do wikitext

Para cada página com seção `{{-it-}}`, o script lê as seções:

| Template | Título exibido | Campo |
|---|---|---|
| `{{-rel-}}` | Termini correlati | `related` |
| `{{-alter-}}` | Alterati | `altered`, com o tipo vindo de `{{Dim}}`, `{{Accr}}`, `{{Vezz}}`, `{{Pegg}}` |
| `{{-noconf-}}` | Da non confondere con | `confusables` |

Cada linha `* ... [[palavra]] ...` vira um item. O resultado é unido ao lema pelo título da página. O `related` do wiktextract é descartado.

### 4. Transformar

Filtra, renomeia e converte os campos. As regras completas estão em [dictionary.md](dictionary.md#transformações).

### 5. Montar o SQLite

Esquema proposto:

```sql
CREATE TABLE meta  (key TEXT PRIMARY KEY, value TEXT);          -- versão, data do dump, sha256 das fontes, licença
CREATE TABLE entry (id INTEGER PRIMARY KEY, word TEXT NOT NULL, pos TEXT NOT NULL, data TEXT NOT NULL);
CREATE TABLE form  (form TEXT NOT NULL, entry_id INTEGER NOT NULL REFERENCES entry(id));

CREATE INDEX entry_word ON entry(word);
CREATE INDEX form_form  ON form(form);
```

- **`entry`**: uma linha por lema e classe gramatical. "binario" substantivo e "binario" adjetivo são duas linhas. `data` guarda o verbete inteiro.
- **`form`**: forma → lema, com o id do lema em vez da string, o que economiza espaço. Recebe as formas da etapa 2 e também as formas das tabelas de conjugação, incluindo as com clítico ("si siede" → sedersi).
- **Ao final**: `VACUUM` para compactar o arquivo.

### 6. Comprimir

O arquivo `.db` é comprimido inteiro. Medição com uma versão provisória do corte (os números finais mudam um pouco):

| | Tamanho |
|---|---|
| SQLite sem compressão | ~90 MB |
| gzip -9 | ~21 MB |
| zstd -19 | ~15 MB |
| brotli -q 11 | ~13 MB |

## Licença

O conteúdo do Wiktionary é CC BY-SA. Com isso:

- O banco gerado é obra derivada e fica sob a mesma licença. A tabela `meta` registra a licença e a atribuição ao Wiktionary.
- O kaikki.org pede citação do wiktextract (Ylonen, LREC 2022).

## Decisões em aberto

| Decisão | Recomendação |
|---|---|
| Glosa PT: só 5% dos lemas têm tradução para o português | Gerar as que faltam no build e marcar a origem de cada glosa |
| Formato da coluna `data` | JSON (fácil de depurar). MessagePack reduz o banco em ~14% e não muda o tamanho comprimido. |
| Algoritmo de compressão | — |
| Linguagem e local do script | — |
