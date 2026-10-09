# Pipeline do dicionário

Como gerar o banco SQLite do dicionário italiano. Os campos e as transformações estão em [dictionary.md](dictionary.md).

## Resumo

Um script baixa os dados do Wiktionary italiano e as fontes bilíngues da glosa PT, aplica as transformações, monta um banco SQLite e o comprime.

```
kaikki.org (JSONL do it.wiktionary) ─┐
dumps.wikimedia.org (wikitext)  ─────┤
WikDict (it-pt, en-pt)  ─────────────┼─► transformar ─► SQLite ─► comprimir
kaikki.org (JSONL do en.wiktionary) ─┘
```

## Fontes

As duas primeiras fontes vêm do mesmo dump mensal do it.wiktionary. O script deve usar a mesma data nas duas. As outras três só alimentam a Glosa PT e têm datas próprias.

| Fonte | Arquivo | Tamanho | Para quê |
|---|---|---|---|
| [kaikki.org](https://kaikki.org/itwiktionary/Italiano/index.html) | `kaikki.org-dictionary-Italiano.jsonl.gz` | 41 MB (478 MB descompactado), dump de 2026-10-01 | Quase tudo: verbetes já estruturados pelo [wiktextract](https://github.com/tatuylonen/wiktextract) |
| [dumps.wikimedia.org](https://dumps.wikimedia.org/itwiktionary/) | `itwiktionary-<data>-pages-articles.xml.bz2` | 71 MB, dump de 2026-10-01 | Só as seções Termini correlati, Alterati e Da non confondere con |
| [WikDict](https://download.wikdict.com/dictionaries/sqlite/2/) | `it-pt.sqlite3` | 3,6 MB, gerado em 2026-06-23 | Glosa PT: traduções italiano → português |
| [WikDict](https://download.wikdict.com/dictionaries/sqlite/2/) | `en-pt.sqlite3` | 12,9 MB, gerado em 2026-06-23 | Glosa PT: segundo passo do pivô pelo inglês |
| [kaikki.org](https://kaikki.org/dictionary/Italian/index.html) | `kaikki.org-dictionary-Italian.jsonl.gz` (en.wiktionary) | 76 MB (735 MB descompactado), dump de 2026-09-02 | Glosa PT: glosa em inglês de cada lema italiano, primeiro passo do pivô |

Por que o wikitext: o wiktextract junta Termini correlati, Varianti, Alterati e Da non confondere con no mesmo campo `related` e não marca de qual seção cada palavra veio (ver `LINKAGE_SECTIONS` em `extractor/it/section_titles.py`). Essas três seções são listas simples de links, então o script as lê direto do wikitext.

Por que o WikDict: ele monta dicionários bilíngues com as tabelas de tradução de vários Wiktionaries, via [DBnary](https://kaiko.getalp.org/about-dbnary/). Junta traduções diretas do it.wiktionary, reversas do pt.wiktionary e inferidas por outras línguas, e dá um `score` a cada par. Já vem em SQLite, com a classe de cada lema.

Por que o pivô pelo inglês: o WikDict it-pt, somado às traduções do próprio it.wiktionary, cobre 18% dos lemas e 62% do vocabulário de base (as ~7 mil palavras do NVdB, ver [dictionary.md](dictionary.md#glosa-pt)). O en.wiktionary tem 163 mil verbetes italianos, com glosas curtas em inglês ("finestrino: window"), e o WikDict en-pt traduz essas glosas ("window → janela"). Com o pivô, a cobertura sobe para 46% dos lemas e 95% do vocabulário de base.

O arquivo do en.wiktionary por língua está marcado como *deprecated* no kaikki.org. Se sair do ar, a alternativa é o JSONL bruto do en.wiktionary inteiro (3 GB comprimido), filtrado por `lang_code: "it"` durante o download.

## Etapas

### 1. Baixar

- Baixa os dois arquivos do it.wiktionary da data escolhida e a versão mais recente das outras três fontes.
- Guarda a data de cada fonte, as URLs e o sha256 de cada arquivo para gravar em `meta` (etapa 6).
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

### 4. Juntar a glosa PT

A junção é por lema + classe. Cada verbete pega a glosa da primeira fonte que tiver tradução, nesta ordem:

| # | Fonte | Junção | Filtro | Lemas cobertos¹ |
|---|---|---|---|---|
| 1 | `translations[]` com `lang_code: "pt"` (it.wiktionary) | Já está no verbete | — | 5,2% |
| 2 | WikDict `it-pt.sqlite3`, tabela `translation` | `written_rep` = lema. A classe sai de `lexentry` (`ita/binario__sost__1` → sostantivo) | `score` ≥ 10 | +13,1% |
| 3 | Pivô: en.wiktionary → WikDict `en-pt.sqlite3` | Lema + classe nos dois passos | `is_good = 1` no en-pt | +27,4% |
| | **Total** | | | **45,7%** |

¹ Porcentagem dos 75.590 lemas. Medido com o it.wiktionary de 2026-10-01, o WikDict de 2026-06-23 e o en.wiktionary de 2026-09-02.

**WikDict it-pt:**

- Classe: `sost` → noun, `verb` → verb, `agg` → adj, `avv` → adv.
- Linhas sem `lexentry` são só a tradução reversa do pt.wiktionary e não têm classe. Entram se o lema tiver uma classe só.
- Por que `score` ≥ 10: abaixo disso, a tradução foi inferida por uma única língua intermediária, sem confirmação, e erra muito ("biglietto → aquartelar", "specie → arrumar"). As linhas reversas (`score` 2, sem `lexentry`) ficam.
- Ordem: `score` e depois `importance`, decrescentes. `trans_list` separa as traduções com " | ".

**Pivô pelo en.wiktionary:**

- Só para substantivo, verbo, adjetivo e advérbio.
- Pega a primeira glosa das duas primeiras acepções do lema, sem o que estiver entre parênteses.
- Tenta a glosa inteira e depois cada parte separada por vírgula ou ponto e vírgula. Tira "to " dos verbos e o artigo dos substantivos.
- A primeira parte que existir no en-pt com a mesma classe dá a tradução: a primeira de `trans_list` na linha de maior `score`.

**Resultado:** até 3 traduções por verbete e a origem (`wikt`, `wikdict` ou `pivo-en`). Um lema sem tradução em nenhuma fonte fica sem glosa.

### 5. Transformar

Filtra, renomeia e converte os campos. As regras completas estão em [dictionary.md](dictionary.md#transformações).

### 6. Montar o SQLite

Esquema proposto:

```sql
CREATE TABLE meta  (key TEXT PRIMARY KEY, value TEXT);          -- versão, data, URL e sha256 de cada fonte, licença, atribuições
CREATE TABLE entry (id INTEGER PRIMARY KEY, word TEXT NOT NULL, pos TEXT NOT NULL, data TEXT NOT NULL);
CREATE TABLE form  (form TEXT NOT NULL, entry_id INTEGER NOT NULL REFERENCES entry(id));

CREATE INDEX entry_word ON entry(word);
CREATE INDEX form_form  ON form(form);
```

- **`entry`**: uma linha por lema e classe gramatical. "binario" substantivo e "binario" adjetivo são duas linhas. `data` guarda o verbete inteiro.
- **`form`**: forma → lema, com o id do lema em vez da string, o que economiza espaço. Recebe as formas da etapa 2 e também as formas das tabelas de conjugação, incluindo as com clítico ("si siede" → sedersi).
- **`meta`**: para cada fonte, a data, a URL, o sha256, a licença e a atribuição (ver [Licença](#licença)).
- **Ao final**: `VACUUM` para compactar o arquivo.

### 7. Comprimir

O arquivo `.db` é comprimido inteiro. Medição com uma versão provisória do corte (os números finais mudam um pouco):

| | Tamanho |
|---|---|
| SQLite sem compressão | ~90 MB |
| gzip -9 | ~21 MB |
| zstd -19 | ~15 MB |
| brotli -q 11 | ~13 MB |

## Licença

Todas as fontes vêm do Wiktionary e são CC BY-SA:

| Fonte | Licença | Atribuição |
|---|---|---|
| it.wiktionary (kaikki.org e dump) | CC BY-SA 4.0 | Wikizionario. O kaikki.org pede citação do wiktextract (Ylonen, LREC 2022). |
| WikDict it-pt e en-pt | CC BY-SA (o site cita a 4.0) | WikDict, e o DBnary, de onde vêm os dados (Sérasset, Semantic Web 2015) |
| en.wiktionary (kaikki.org) | CC BY-SA 4.0 | Wiktionary em inglês e wiktextract |

Com isso:

- O banco gerado é obra derivada e fica sob CC BY-SA. A tabela `meta` registra a licença e a atribuição de cada fonte.
- Hoje o app credita só o Wikizionario (DIC-09, AJU-04). Com a glosa PT de outras fontes, os créditos precisam citar também o WikDict e o Wiktionary em inglês.

## Decisões em aberto

| Decisão | Recomendação |
|---|---|
| Fonte da glosa PT. Alternativas medidas (lemas / vocabulário de base): WikDict it-pt só (18% / 62%); WikDict it-pt + pivô en.wiktionary (46% / 95%); as duas + pt.wiktionary (48% / 96%); Open Multilingual Wordnet, MultiWordNet + OpenWN-PT (27% / 84%, sem ordem de acepção); FreeDict ita-por (subconjunto antigo do WikDict). Descartadas: MUSE (CC BY-NC), Apertium ita-por (dicionário vazio, GPL), lexemas do Wikidata (~2 mil lemas com tradução). | WikDict it-pt + pivô en.wiktionary (etapa 4), com a origem de cada glosa marcada. |
| Erros e variante PT-PT nas glosas: sedersi → "estar sentado", serranda → "postigo"; as fontes misturam PT-BR e PT-PT ("comboio", "terramoto", "crónico") | Arquivo de correções (lema + classe → glosa) versionado com o script, começando pelas palavras do vocabulário de base |
| Formato da coluna `data` | JSON (fácil de depurar). MessagePack reduz o banco em ~14% e não muda o tamanho comprimido. |
| Algoritmo de compressão | — |
| Linguagem e local do script | — |
