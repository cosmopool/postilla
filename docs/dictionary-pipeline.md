# Pipeline do dicionário

Como gerar o banco SQLite do dicionário italiano. Os campos e as transformações estão em [dictionary.md](dictionary.md).

## Resumo

Um programa em Zig 0.17 (ARQ-02) baixa os dados do Wiktionary italiano, as fontes bilíngues da glosa PT e o NVdB, aplica as transformações, monta um banco SQLite e o comprime. Na v2, a etapa 5b acrescenta os traços de treino (plural, gênero, conjugação) e classifica as palavras nos padrões da Revisão e do Treino. A versão de cada parte está no [roadmap](roadmap.md).

```
kaikki.org (JSONL do it.wiktionary) ──┐
dumps.wikimedia.org (wikitext)  ──────┤
WikDict (it-pt, en-pt)  ──────────────┤
kaikki.org (JSONL do en.wiktionary) ──┼─► transformar ─► traços de treino ─► SQLite ─► comprimir
NVdB ─────────────────────────────────┤                         │ (5b, v2)
correções ────────────────────────────┤                         └─► relatório de divergências (v2)
Morph-it!, rules.toml, exceções (v2) ─┘
```

## Fontes

As duas primeiras fontes vêm do mesmo dump mensal do it.wiktionary. O script deve usar a mesma data nas duas. As outras têm datas próprias. O WikDict só alimenta a Glosa PT; o en.wiktionary alimenta a Glosa PT e, na v2, os traços de treino; o Morph-it! só os traços de treino (v2).

| Fonte | Arquivo | Tamanho | Para quê |
|---|---|---|---|
| [kaikki.org](https://kaikki.org/itwiktionary/Italiano/index.html) | `kaikki.org-dictionary-Italiano.jsonl.gz` | 41 MB (478 MB descompactado), dump de 2026-10-01 | Quase tudo: verbetes já estruturados pelo [wiktextract](https://github.com/tatuylonen/wiktextract) |
| [dumps.wikimedia.org](https://dumps.wikimedia.org/itwiktionary/) | `itwiktionary-<data>-pages-articles.xml.bz2` | 71 MB, dump de 2026-10-01 | Só as seções Termini correlati, Alterati e Da non confondere con |
| [WikDict](https://download.wikdict.com/dictionaries/sqlite/2/) | `it-pt.sqlite3` | 3,6 MB, gerado em 2026-06-23 | Glosa PT: traduções italiano → português |
| [WikDict](https://download.wikdict.com/dictionaries/sqlite/2/) | `en-pt.sqlite3` | 12,9 MB, gerado em 2026-06-23 | Glosa PT: segundo passo do pivô pelo inglês |
| [kaikki.org](https://kaikki.org/dictionary/Italian/index.html) | `kaikki.org-dictionary-Italian.jsonl.gz` (en.wiktionary) | 76 MB (735 MB descompactado), dump de 2026-09-02. A medição dos traços usou o arquivo baixado em 2026-10-16 (sha256 `3c0f2de5…bffb4f`) | Glosa PT: glosa em inglês de cada lema italiano, primeiro passo do pivô. Traços de treino (v2): plural, gênero e conjugação que faltam no it.wiktionary (etapa 5b) |
| Morph-it! | Lista forma → lema + traços morfológicos (arquivo e tamanho a confirmar) | — | Traços de treino (v2): terceira fonte, depois das duas wikis. Entra só se a licença for confirmada e a medição mostrar ganho (D19) |
| NVdB (De Mauro, 2016) | A definir: a lista ainda não está no disco | — | Rank e faixa de frequência de cada `entry` (ARQ-64); na v2, corte "frequente" de `gen.lista` e `gen.sufixo` |

Arquivos escritos à mão, versionados com o script em `postilla-content`:

| Arquivo | Para quê |
|---|---|
| `rules.toml` | Catálogo de padrões da Revisão e do Treino (D14): ids, textos em PT e IT, exemplos, listas fechadas de membros do A1, itens curados e lista de parentesco (etapa 5b, v2) |
| Exceções de artigo | Substantivos cujo artigo não sai do som escrito (*lo yogurt*, *il whisky*, *gli dei*) (etapa 5b, v2) |
| Correções | Um arquivo só: lema + classe + campo → valor certo. Na v1, para a glosa (*serranda* → "postigo"); na v2, também para os traços (*uomo*: plural *uomini*, não "donne") |

Por que o wikitext: o wiktextract junta Termini correlati, Varianti, Alterati e Da non confondere con no mesmo campo `related` e não marca de qual seção cada palavra veio (ver `LINKAGE_SECTIONS` em `extractor/it/section_titles.py`). Essas três seções são listas simples de links, então o script as lê direto do wikitext.

Por que o WikDict: ele monta dicionários bilíngues com as tabelas de tradução de vários Wiktionaries, via [DBnary](https://kaiko.getalp.org/about-dbnary/). Junta traduções diretas do it.wiktionary, reversas do pt.wiktionary e inferidas por outras línguas, e dá um `score` a cada par. Já vem em SQLite, com a classe de cada lema.

Por que o pivô pelo inglês: o WikDict it-pt, somado às traduções do próprio it.wiktionary, cobre 18% dos lemas e 62% do vocabulário de base (as ~7 mil palavras do NVdB, ver [dictionary.md](dictionary.md#glosa-pt)). O en.wiktionary tem 163 mil verbetes italianos, com glosas curtas em inglês ("finestrino: window"), e o WikDict en-pt traduz essas glosas ("window → janela"). Com o pivô, a cobertura sobe para 46% dos lemas e 95% do vocabulário de base.

O arquivo do en.wiktionary por língua está marcado como *deprecated* no kaikki.org. Se sair do ar, a alternativa é o JSONL bruto do en.wiktionary inteiro (3 GB comprimido), filtrado por `lang_code: "it"` durante o download.

## Etapas

### 1. Baixar

- Baixa os dois arquivos do it.wiktionary da data escolhida e a versão mais recente das outras fontes.
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

A Coniugazione do verbete mostra o Imperativo como 5º tempo já na v1 (DIC-05). Onde as `tags` não dão o modo e o tempo de uma forma, os `raw_tags` são lidos nesta etapa (ver as decisões em aberto).

### 5b. Traços de treino

**v2.** A etapa inteira sai da v1 e entra com a Revisão e o Treino ([roadmap](roadmap.md)).

Preenche em `entry.data` os campos que a Revisão e o Treino cobram (plural, gênero, artigo, conjugação), classifica cada palavra nos padrões do catálogo e monta as tabelas `rule` e `drill` (ARQ-86, ARQ-87). Os campos estão em [dictionary.md](dictionary.md#traços-de-treino).

**Cadeia de fontes (D19).** Para plural, gênero e conjugação, cada lema usa a primeira fonte que tiver o dado, nesta ordem:

1. it.wiktionary (o próprio verbete);
2. en.wiktionary (o mesmo JSONL do pivô da glosa, junção por lema + classe);
3. Morph-it!, se entrar.

**Nada é gerado por regra.** Um lema sem o dado em nenhuma fonte fica sem ele e não entra no padrão correspondente. A origem do plural fica em `plural_src` (`wikt`, `enwikt`, `morphit`); não existe valor para plural gerado.

**Normalização das formas do en.wiktionary.** Elas vêm com o acento tônico marcado (*pàrlo*, *finìsco*). Antes de comparar ou gravar, o script tira o acento de toda vogal que não está no fim da palavra, em cada palavra de uma forma composta (*pàrlo* → *parlo*, *finìsco* → *finisco*; *città* fica). As formas marcadas como feminino plural (*uova*, *braccia*) contam como plural do lema masculino.

**Plural.**

- it.wiktionary: as formas de `forms[]` com tag `plural`. Com a tag `invariable`, o plural é a própria palavra.
- en.wiktionary: o plural, depois da normalização. "Invariável" dá a própria palavra; "incontável" (*marzo*) deixa o lema sem plural e fora do Plural.
- Plurais duplos legítimos (*riso*: *risa* × *risi*) ficam todos na lista, na ordem da fonte.

**Gênero e artigo.**

- Gênero: tags `masculine`/`feminine` do it.wiktionary, depois o en.wiktionary, depois o Morph-it!.
- Artigo (`article`, `article_indef`, `article_pl`): sai do gênero e do som inicial, pela própria regra do `art.forma` (*lo/gli/uno* antes de s + consoante, z, gn, ps; *l'* antes de vogal; *il/i/un* no resto; feminino *la/le/una/l'/un'*). Não é dado que falta, então não fere a D19. Os casos que o som escrito não resolve vêm do arquivo de exceções.

**Conjugação.**

- it.wiktionary: as formas com `source: "Appendice:Coniugazioni/..."`, com o modo e o tempo da etapa 5, que já lê os `raw_tags` onde as `tags` normalizadas não bastam, inclusive o imperativo (ver [dictionary.md](dictionary.md#flessione-e-coniugazione)).
- en.wiktionary: as formas pelas `tags` (pessoa, número, modo, tempo), depois da normalização.
- Resultado: `conj` plano (`tense`, `person`, `forms`), com `tense` 1 presente · 2 passato_prossimo · 3 imperfetto · 4 futuro · 5 imperativo, e `conj_class` (`group` pela terminação do infinitivo, `isc` pelas formas do presente, `pronominal` pelo infinitivo em -rsi, `aux` pela forma com tag `auxiliary`).

**Classificação nos padrões.** Para cada substantivo e para cada verbo × tempo, o script calcula o que cada regra do catálogo produziria e compara com a forma do dicionário. Isso só classifica e nunca preenche:

- A palavra cai no padrão cuja regra produz a forma do dicionário, pela precedência `lista > isc > grafia > rifl > base` no presente, `lista > essere > avere` no passato prossimo e `lista > base` no imperativo afirmativo. Todo verbo com imperativo ganha também uma linha de `imper.neg`.
- As exceções nomeadas no texto da regra (*amici*, *medici* no `pl.co_go`) vêm do `rules.toml` e ficam no padrão.
- Uma palavra cuja forma não bate com nenhuma regra e não está em nenhuma lista fica fora do `drill` e vai para o relatório (*tecnico* → *tecnici*: pede a regra da tônica, que é A2).
- **Corte do A1:** nos padrões restritos (`pres.ciare_giare`, `pl.io`, `pp.lista`, `imper.lista`, `pl.lista`), só entram os membros da lista fechada do `rules.toml`. Em `gen.lista` e `gen.sufixo`, o corte é por frequência no NVdB (ver as decisões em aberto). Os membros de `prep.art` são os substantivos de `art.forma` cujo artigo cai numa combinação frequente.

**`rules.toml` → `rule` e `drill`.**

- Cada padrão do `rules.toml` vira uma linha de `rule`: `id`, `skill`, `type`, `level`, `position` (ordem do *Dai! 1*), `neighbor`, nomes e textos em PT e IT, `examples` (linhas "lema certo errado", que formam a tabela da página da regra e os pares da escolha de forma) e `retired`.
- Os itens curados de `accordo`, `possessivo` e `piacere` (pergunta, lema, resposta, forma errada) viram linhas de `drill` com `cue` e `answer`. A lista de parentesco do `poss.famiglia` também fica no `rules.toml`.
- **Conferências:** o "certo" de cada exemplo e de cada item curado é comparado com o dicionário (gênero e número do nome, forma do adjetivo, forma do verbo); o que não bate vai para o relatório. O build **falha** se um `id` da versão publicada anterior sumir do `rules.toml`: um padrão que sai fica com `retired = 1` (ARQ-86), porque o id é a chave do histórico do aluno.
- O tamanho do `drill` (~145 mil linhas, estimado com o catálogo antigo e o plural gerado) precisa ser recontado com o catálogo A1.

**Relatório de divergências.** Um arquivo de texto por build, fora do pacote, revisado à mão. Lista:

- lemas em que as fontes discordam, com o valor de cada uma (*uomo*: "donne" no it.wiktionary × *uomini* no en.wiktionary; *latte*, *fame*, *sete*: invariáveis no it.wiktionary × *latti*, *fami*, *seti* no en.wiktionary);
- palavras que nenhuma regra classifica;
- exemplos e itens curados do `rules.toml` que não batem com o dicionário.

O que o relatório aponta se resolve no arquivo de correções, e não no código.

**Cobertura medida** (2026-10-16, em [cobertura-enwiktionary.md](propostas/cobertura-enwiktionary.md); it.wiktionary de 2026-10-01 contra en.wiktionary baixado em 2026-10-16, lemas sem repetir e sem as entradas só de "forma de"):

| Dado | Falta no it.wiktionary | O en.wiktionary resolve | Sobra |
|---|---|---|---|
| Plural | 10.464 de 36.860 substantivos sem plural nem marca de invariável | 5.807 (55%): 4.841 plurais, 846 invariáveis, 120 incontáveis | 3.860 sem o lema no en.wiktionary e 797 sem plural. Quase tudo lixo ou raro: formas flexionadas registradas como lema, locuções, taxonomia, termos técnicos |
| Gênero | 4.348 substantivos | 2.772 (64%) | — |
| Conjugação | 2.352 de 7.606 verbos sem tabela | 1.384 (59%) | Formas flexionadas registradas como verbo, palavras de outra classe, pronominais sem tabela própria (*cuocersi*) |

- **Concordância:** nos 20.315 substantivos com plural nas duas fontes, elas concordam em 20.018 (98,5%). Muitas das 297 divergências são erros de digitação do it.wiktionary que o en.wiktionary corrige (*pirolfile*, *carrrettieri*, *scalpccii*); outras são plurais duplos legítimos.
- **40 palavras comuns conferidas uma a uma:** 32 batem; *casa* → *case* vem do en.wiktionary; *marzo* é incontável; *uomo* tem "donne" no it.wiktionary; *uovo* e *braccio* pedem a regra do feminino plural; *latte*, *fame*, *sete* vão para o relatório.
- **Falta medir:** a cobertura dentro do NVdB, quanto o Morph-it! acrescenta ao que sobra, o imperativo nas tabelas, a distribuição por padrão com o catálogo A1 e o tamanho do `drill`.

### 6. Montar o SQLite

Esquema proposto:

```sql
CREATE TABLE meta  (key TEXT PRIMARY KEY, value TEXT);          -- versão, data, URL e sha256 de cada fonte, licença, atribuições
CREATE TABLE entry (id INTEGER PRIMARY KEY, word TEXT NOT NULL, pos TEXT NOT NULL, data TEXT NOT NULL);
CREATE TABLE form  (form TEXT NOT NULL, entry_id INTEGER NOT NULL REFERENCES entry(id));

CREATE INDEX entry_word ON entry(word);
CREATE INDEX form_form  ON form(form);

CREATE TABLE rule (                       -- de rules.toml (etapa 5b, v2)
  id        TEXT    PRIMARY KEY,          -- 'pl.co_go'; só acréscimo, nunca renomeado (ARQ-86)
  skill     INTEGER NOT NULL,
  type      INTEGER NOT NULL,             -- 1 regra (cartão de padrão) · 2 lista
  level     INTEGER NOT NULL,             -- 1 A1 · 2 A2 …; na v2, todos 1
  position  INTEGER NOT NULL,             -- ordem do Dai! 1
  neighbor  TEXT    NOT NULL DEFAULT '',  -- padrão vizinho para misturar no Treino
  name_pt   TEXT    NOT NULL,
  name_it   TEXT    NOT NULL,
  text_pt   TEXT    NOT NULL,             -- até 3 frases; '{lemma}' e '{answer}' para a frase da resposta
  text_it   TEXT    NOT NULL,
  examples  TEXT    NOT NULL,             -- linhas 'lema certo errado'
  retired   INTEGER NOT NULL DEFAULT 0    -- 1 = saiu do catálogo
);

CREATE TABLE drill (                      -- quem é membro de qual padrão (ARQ-87; v2)
  entry_id INTEGER NOT NULL REFERENCES entry(id),
  skill    INTEGER NOT NULL,
  tense    INTEGER NOT NULL DEFAULT 0,
  rule     TEXT    NOT NULL REFERENCES rule(id),
  cue      TEXT    NOT NULL DEFAULT '',   -- item curado: a pergunta ('___ madre (io)')
  answer   TEXT    NOT NULL DEFAULT ''    -- item curado: a resposta; nos outros, vem de entry.data
);
CREATE INDEX drill_rule  ON drill(rule, skill, tense);
CREATE INDEX drill_entry ON drill(entry_id);
```

- **`entry`**: uma linha por lema e classe gramatical. "binario" substantivo e "binario" adjetivo são duas linhas. `data` guarda o verbete inteiro.
- **`form`**: forma → lema, com o id do lema em vez da string, o que economiza espaço. Recebe as formas da etapa 2 e também as formas das tabelas de conjugação, incluindo as com clítico ("si siede" → sedersi).
- **`rule`** e **`drill`** (v2): o catálogo de padrões e o índice de pertinência da etapa 5b. Uma linha de `drill` por substantivo × skill (`genere`, `articolo`, `plurale`, `preposizione`), por verbo × tempo (mais uma de `imper.neg`) e por item curado.
- **`meta`**: para cada fonte, a data, a URL, o sha256, a licença e a atribuição (ver [Licença](#licença)).
- A coluna normalizada (ARQ-63) e o rank e a faixa do NVdB (ARQ-64) também são pedidos do app, ainda fora deste esquema.
- **Ao final**: `VACUUM` para compactar o arquivo.

### 7. Comprimir

O arquivo `.db` é comprimido inteiro. Na v1, com gzip -9 (`.db.gz`); o zstd -19 entra na v1.2 (ARQ-11). Medição com uma versão provisória do corte (os números finais mudam um pouco):

| | Tamanho |
|---|---|
| SQLite sem compressão | ~90 MB |
| gzip -9 | ~21 MB |
| zstd -19 | ~15 MB |
| brotli -q 11 | ~13 MB |

## Licença

As fontes do Wiktionary e do WikDict são CC BY-SA. O Morph-it! e o NVdB ainda precisam ter a licença confirmada:

| Fonte | Licença | Atribuição | Usada em |
|---|---|---|---|
| it.wiktionary (kaikki.org e dump) | CC BY-SA 4.0 | Wikizionario. O kaikki.org pede citação do wiktextract (Ylonen, LREC 2022). | Tudo |
| WikDict it-pt e en-pt | CC BY-SA (o site cita a 4.0) | WikDict, e o DBnary, de onde vêm os dados (Sérasset, Semantic Web 2015) | Glosa PT |
| en.wiktionary (kaikki.org) | CC BY-SA 4.0 | Wiktionary em inglês e wiktextract | Glosa PT (pivô) e traços de treino |
| Morph-it! | CC BY-SA 2.0 / LGPL, **a confirmar** (D19) | Morph-it!, de Eros Zanchetta e Marco Baroni (Universidade de Bolonha), a confirmar | Traços de treino, se entrar (v2) |
| NVdB | **A confirmar** | Tullio De Mauro, *Nuovo vocabolario di base della lingua italiana* (2016) | Rank e faixa de frequência |
| `rules.toml`, exceções, correções | As do `postilla-content` | — | Catálogo, artigo e correções |

Com isso:

- O banco gerado é obra derivada e fica sob CC BY-SA. A tabela `meta` registra a licença e a atribuição de cada fonte.
- Se a licença do Morph-it! for a CC BY-SA 2.0, ela permite distribuir a obra derivada sob uma versão posterior com os mesmos elementos, o que é compatível com a 4.0 das wikis. Isso precisa ser conferido no texto da licença publicado com o arquivo.
- Ajustes › Sobre (AJU-04) credita o Wikizionario, o en.wiktionary, o WikDict e o NVdB. Todo verbete diz "Fonte: Wikizionario, Wiktionary, WikDict · CC BY-SA" (DIC-09). Se o Morph-it! entrar (v2), entra nos dois.

## Decisões em aberto

### Decididas

| Decisão | Escolha | Data |
|---|---|---|
| Fonte da glosa PT. Alternativas medidas (lemas / vocabulário de base): WikDict it-pt só (18% / 62%); WikDict it-pt + pivô en.wiktionary (46% / 95%); as duas + pt.wiktionary (48% / 96%); Open Multilingual Wordnet, MultiWordNet + OpenWN-PT (27% / 84%, sem ordem de acepção); FreeDict ita-por (subconjunto antigo do WikDict). Descartadas: MUSE (CC BY-NC), Apertium ita-por (dicionário vazio, GPL), lexemas do Wikidata (~2 mil lemas com tradução). | WikDict it-pt + pivô en.wiktionary (etapa 4), com a origem de cada glosa marcada. | 2026-10-26 |
| Erros e variante PT-PT nas glosas: sedersi → "estar sentado", serranda → "postigo"; as fontes misturam PT-BR e PT-PT ("comboio", "terramoto", "crónico") | Arquivo de correções versionado com o programa, começando pelas palavras do vocabulário de base. | 2026-10-26 |
| Um arquivo de correções ou dois | Um arquivo só, lema + classe + campo → valor, para glosa e, na v2, traços. | 2026-10-26 |
| Formato da coluna `data` | JSON (fácil de depurar). MessagePack reduz o banco em ~14% e não muda o tamanho comprimido. | 2026-10-26 |
| Algoritmo de compressão | gzip -9 na v1; zstd -19 na v1.2 (ARQ-11). | 2026-10-26 |
| Linguagem e local do programa (D23) | Zig 0.17, com as dependências pelo package manager do Zig (ARQ-02), em `postilla-content` (ARQ-03). A saída fica em `out/`, e o lock do app aponta para lá na v1 (ARQ-14). | 2026-10-26 |
| Rank de frequência | NVdB (ARQ-64). A licença continua em aberto (abaixo). | 2026-10-26 |
| Créditos (proposta 12.2, item 14) | AJU-04: Wikizionario, en.wiktionary, WikDict e NVdB. DIC-09: "Fonte: Wikizionario, Wiktionary, WikDict · CC BY-SA", fixo em todo verbete. O Morph-it! entra nos dois se entrar (v2). | 2026-10-27 |

### Em aberto na v1

| Decisão | Recomendação |
|---|---|
| Fonte e licença do NVdB | O rank (ARQ-64) depende dele, e a lista não está no disco. Recomendação: obter a lista publicada por De Mauro (2016) e confirmar a licença antes de gravar o rank no `dict`. Na v2, medir também a cobertura dos traços dentro dela. |
| Leitura dos `raw_tags` da conjugação | O Imperativo do verbete (DIC-05) depende dela na v1. Quais rótulos dos `raw_tags` dão modo, tempo e imperativo não está conferido no dump, e o imperativo nas tabelas não foi medido. Recomendação: medir antes de fechar o formato da Coniugazione. |

### Da etapa 5b (v2)

| Decisão | Recomendação |
|---|---|
| Morph-it! como 3ª fonte (D19) | Confirmar a licença (CC BY-SA 2.0 / LGPL) e medir quanto ele acrescenta depois do en.wiktionary. Se não acrescentar palavra de A1–B1, ficar só com as duas wikis. |
| Origem do gênero e da conjugação (proposta 12.2, item 9) | A D19 marca só a origem do plural. Recomendação: `gender_src` e `conj_src`, com os mesmos valores do `plural_src`. |
| Valor na divergência entre fontes (proposta 12.2, item 10) | *uomo* → "donne" no it.wiktionary. Opções: (a) vale a ordem da cadeia (it.wiktionary); (b) vale o en.wiktionary quando ele discorda; (c) o membro fica fora do `drill` até o arquivo de correções resolver, e o verbete fica como está. Recomendação: (c), e começar o arquivo de correções pelas palavras do NVdB que aparecerem no relatório. |
| Pronominais sem tabela (proposta 12.2, item 11) | *cuocersi* pode herdar a tabela de *cuocere* + *si*? É derivação, e a D19 diz "nada gerado por regra". Recomendação: não na v2; ficam sem conjugação. |
| Imperativo negativo (proposta 12.2, item 12) | A resposta do `imper.neg` é *non* + infinito, a única do `drill` que não vem do dicionário. Recomendação: aceitar, porque é a regra inteira, sem exceção, e o infinitivo é o próprio lema. |
| Passato prossimo sem tabela composta | O Morph-it! tem só formas simples, e não está medido se o en.wiktionary traz as formas compostas. Opções: (a) compor auxiliar + particípio quando os dois vêm de fonte; (b) só aceitar a forma composta pronta. Recomendação: (a), pelo mesmo motivo do `imper.neg`: auxiliar + particípio é a definição do tempo, não uma regra de forma. Medir antes. |
| Corte "frequente" (proposta 12.2, item 3) | `gen.lista` e `gen.sufixo` só com palavras frequentes, mas a D11c e a D11d não dão a fonte. Recomendação: NVdB *fondamentale*. |
| Combinações do `prep.art` (proposta 12.2, item 4) | A pesquisa sugere *al, alla, allo, del, della, nel, nella, sul, dal*. Recomendação: as 5 preposições com *il, la, l', i, le*; *lo* e *gli* ficam para o A2. |
| Substantivo com os dois gêneros | *il/la cantante*, *il/la fine* (com sentidos diferentes): a escolha de Gênero não tem uma resposta. Recomendação: fora de `gen.lista` e `gen.sufixo`; continuam nos outros padrões. |
