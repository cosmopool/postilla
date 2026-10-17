# Dicionário: campos

Quais campos do Wiktionary italiano o Postilla usa, como cada um é transformado e quais ficam de fora, com o motivo. O processo de build está em [dictionary-pipeline.md](dictionary-pipeline.md). O layout do verbete está em [design/content.md](../design/content.md).

Fonte: JSONL do kaikki.org (wiktextract sobre o it.wiktionary). Três seções vêm direto do wikitext do dump. A Glosa PT usa também o WikDict e o en.wiktionary. Os traços de treino (gênero, artigo, plural, conjugação), que a Revisão e o Treino cobram, completam o it.wiktionary com o en.wiktionary e, se entrar, com o Morph-it! (ver [Traços de treino](#traços-de-treino)). Os números de cobertura são do dump de 2026-10-01 e contam a porcentagem dos 75.590 lemas que têm o campo.

## Seções do verbete

As seções seguem as do app Livio (`livio.pack.lang.it_IT`), que exibe as seções das páginas do it.wiktionary. A ordem nunca muda, e uma seção sem dado não aparece.

| # | Seção | Origem | Cobertura |
|---|---|---|---|
| 1 | Lemma e Classe | `word`, `pos`, `tags` + valência das `categories` | 100% |
| 2 | Flessione (plurale, femminile) | `forms[]` sem `source` | 47% |
| 3 | Sillabazione | `hyphenations[0].parts` | 82% |
| 4 | Pronuncia | `sounds[].ipa` | 58% |
| 5 | Glosa PT (oculta por padrão) | `translations[]` com `lang_code: "pt"`, WikDict it-pt e pivô pelo en.wiktionary | 46% (95% do vocabulário de base) |
| 6 | Significati | `senses[].glosses`, `examples[].text`, rótulos | 100% (exemplos 13%) |
| 7 | Coniugazione | `forms[]` com `source: "Appendice:Coniugazioni/..."` | 7,5% (os verbos) |
| 8 | Etimologia | `etymology_texts` | 89% |
| 9 | Sinonimi | `synonyms[]` | 42% |
| 10 | Contrari | `antonyms[]` | 25% |
| 11 | Parole derivate | `derived[]` | 21% |
| 12 | Termini correlati | wikitext `{{-rel-}}` | < 20%¹ |
| 13 | Alterati | wikitext `{{-alter-}}` | < 20%¹ |
| 14 | Da non confondere con | wikitext `{{-noconf-}}` | < 20%¹ |
| — | Nella storia | não vem do dicionário: o trecho sai da própria história | — |

¹ As três seções aparecem juntas em 20% dos lemas (campo `related` do wiktextract). A cobertura de cada uma só fica conhecida depois do parse do wikitext.

## Transformações

### Lemas e formas

- **Lemas e formas:** uma entrada cujos sentidos são todos `form_of`, ou que tem a tag `form-of`, não vira verbete. Cada palavra de `form_of[].word` alimenta a tabela `form` (forma → lema). A entrada com a tag e sem `form_of[]` ("siede") se liga ao lema pelas tabelas dele.
- **Formas das tabelas:** as formas da Flessione e da conjugação também entram em `form`, inclusive as com clítico. Assim "si siede" leva a sedersi, e não a sedere, e "binari" leva aos dois verbetes de binario.
- **Um verbete por classe:** "binario" substantivo e "binario" adjetivo são duas linhas.

### Classe

- `pos` vira o nome em italiano: `noun` → sostantivo, `verb` → verbo, `adj` → aggettivo, `adv` → avverbio, `name` → nome proprio, `phrase` → locuzione. As classes menores seguem o mesmo padrão: abbreviazione, locuzione avverbiale, locuzione prepositiva, prefisso, suffisso, affisso, interiezione, pronome, congiunzione, preposizione, articolo, numerale, particella, simbolo, carattere.
- `tags` de gênero e número vira `masculine` → maschile, `feminine` → femminile, `invariable` → invariabile.
- **Valência do verbo:** vem das `categories` da entrada, porque `tags` não traz essa informação (sedersi vem só com `reflexive`).

  | Categoria | Valor |
  |---|---|
  | Verbi transitivi_in_italiano | transitivo |
  | Verbi intransitivi_in_italiano | intransitivo |
  | Verbi intransitivi pronominali_in_italiano | intransitivo pronominale |
  | Verbi riflessivi_in_italiano | riflessivo |

- O auxiliar sai de `forms[]` com tag `auxiliary` (ausiliare: essere).

Resultado: "verbo intransitivo pronominale · ausiliare: essere".

### Flessione e Coniugazione

- De cada forma só ficam `form` e `tags`. Sai `source`. Os `raw_tags` saem da Flessione, mas passam a ser lidos na conjugação: eles dão modo e tempo onde as `tags` não bastam, inclusive o imperativo ([etapa 5b do pipeline](dictionary-pipeline.md#5b-traços-de-treino)).
- A primeira forma da conjugação ("sedere (coniugazione)", sem tags) é só o link para a tabela e é descartada.
- O pronome da conjugação (io, tu, lui/lei…) é derivado de pessoa + número (`first-person` + `singular` → io), não de `raw_tags`. A exceção é o imperativo, que só tem a tag `imperative`: a pessoa vem do `raw_tags` (tu, lui/lei, noi, voi, essi/esse).
- Os cinco tempos do DIC-05 saem das `tags` do indicativo: pessoa + número + `present` (1), `past` + `perfect` (2, passato prossimo), `imperfect` (3), `future` (4). O imperativo é o 5. Congiuntivo, condizionale e passato remoto vêm sem as tags de pessoa ou com outro tempo e ficam fora do `conj`, mas as formas entram em `form`. O "non parlare" da 2ª pessoa do imperativo fica na lista, como vem da tabela.
- As formas são agrupadas por modo e tempo para montar as tabelas (Indicativo presente, Passato prossimo, Imperfetto…). Se a seção passa a mostrar o imperativo como 5º tempo é uma decisão em aberto (ver [Decisões em aberto](#decisões-em-aberto)).

### Sillabazione e Pronuncia

- Usa só a primeira variante de `hyphenations`. As sílabas já vêm com o acento tônico marcado ("se | dér | si").
- Usa só o IPA de `sounds`. O áudio do botão de pronúncia vem do TTS do aparelho (ver campos não utilizados).

### Significati

- **Sentidos vazios:** são descartados quando estão na categoria "Pagine senza definizione - italiano" (9.389 sentidos) ou têm a tag `no-gloss`.
- **Exemplos:** fica só `examples[].text`.
- **Rótulos de registro e área:** saem de três campos e viram a abreviação italiana que o design system usa (ex.: estens., fig., colloq., letter., tecn.):

  | Campo | Exemplos de valor | Abreviação |
  |---|---|---|
  | `senses[].tags` (normalizado, em inglês) | figuratively, broadly, literary, rare, archaic, slang, pejorative, regional, vulgar | fig., estens., letter., raro, ant., gerg., spreg., region., volg. |
  | `senses[].raw_tags` (em italiano) | familiare, forestierismo, scherzoso, popolare, toscano | fam., forest., scherz., pop., tosc. |
  | `senses[].topics` (área) | medicine, chemistry, biology, economics | med., chim., biol., econ. |

  A tabela de mapeamento completa é fixa e fica no script. Um valor sem mapeamento vai para o log do build e não aparece no app.

### Glosa PT

- **Origem:** três fontes, nesta ordem. Cada verbete usa a primeira que tiver tradução (regras na [etapa 4 do pipeline](dictionary-pipeline.md#4-juntar-a-glosa-pt)):
  1. `translations[]` com `lang_code: "pt"` do próprio verbete;
  2. WikDict it-pt, com `score` ≥ 10;
  3. pivô: a glosa inglesa do lema no en.wiktionary ("finestrino: window"), traduzida pelo WikDict en-pt ("janela").
- **Junção:** por lema + classe.
- **Uma glosa por verbete, não por acepção.** Nenhuma fonte liga a tradução às acepções de Significati. O it.wiktionary e o WikDict só trazem o rótulo do quadro de tradução ("sostantivo (stazione)"), e o pivô usa as acepções do en.wiktionary.
- **Formato:** até 3 traduções, na ordem da fonte, e a origem (`wikt`, `wikdict` ou `pivo-en`).
- **Sem glosa:** a seção não aparece.
- **Licença:** todas as fontes são CC BY-SA. `meta` guarda licença e atribuição de cada uma (ver [Licença](dictionary-pipeline.md#licença)).

**Cobertura.** Medida com o it.wiktionary de 2026-10-01, o WikDict de 2026-06-23 e o en.wiktionary de 2026-09-02. O vocabulário de base é o [Nuovo vocabolario di base](https://www.internazionale.it/opinione/tullio-de-mauro/2016/12/23/il-nuovo-vocabolario-di-base-della-lingua-italiana) (De Mauro, 2016), usado como aproximação do vocabulário A1–B2.

| Recorte | Só it.wiktionary | Com WikDict | Com WikDict + pivô |
|---|---|---|---|
| 75.590 lemas | 5,2% | 18,3% | 45,7% |
| NVdB fondamentale (1.917 palavras) | 40% | 78% | 97% |
| NVdB alto uso (3.028) | 20% | 61% | 96% |
| NVdB alta disponibilità (2.073) | 14% | 49% | 91% |

- O pivô só cobre substantivo, verbo, adjetivo e advérbio. Por isso a maioria das 59 palavras fondamentali sem glosa é gramatical (gli, ma, senza, però, cui), e 98% das locuções e 92% dos nomes próprios ficam sem glosa.
- Teste com as palavras de [content.md](../design/content.md): finestrino → janela, biglietto → bilhete, binario → linha, via. Erram: sedersi → "estar sentado" e serranda → "postigo" (em PT-BR seria "porta de enrolar").
- As fontes misturam PT-BR e PT-PT ("comboio", "terramoto", "crónico"). O tratamento dos erros e da variante é uma decisão em aberto (ver [dictionary-pipeline.md](dictionary-pipeline.md#decisões-em-aberto)).

### Sinonimi e Contrari

- Fica `word`. Em `synonyms`, `tags`/`raw_tags` viram a nota entre parênteses, com o mesmo mapeamento de rótulos (ex.: "oblò (fig.)", "(di persona)").

### Termini correlati, Alterati, Da non confondere con

- Vêm do wikitext (etapa 3 do pipeline) e substituem o `related` do wiktextract.
- Em Alterati, o template da linha dá o tipo: `{{Dim}}` diminutivo, `{{Accr}}` accrescitivo, `{{Vezz}}` vezzeggiativo, `{{Pegg}}` peggiorativo.

## Traços de treino

Campos de `entry.data` que a Revisão e o Treino leem para montar e corrigir os exercícios de Artigo, Gênero, Plural, Preposições e dos tempos verbais (ARQ-87). São preenchidos na [etapa 5b do pipeline](dictionary-pipeline.md#5b-traços-de-treino), pela cadeia it.wiktionary → en.wiktionary → Morph-it! (D19). **Nada é gerado por regra:** um lema sem o dado em nenhuma fonte fica sem o campo e fora do padrão correspondente. A exceção é o artigo, que é a própria regra do `art.forma` aplicada ao gênero.

| Campo | Classe | O que é | De onde vem |
|---|---|---|---|
| `gender` | sostantivo | `m` ou `f` | `tags` do it.wiktionary (`masculine`, `feminine`) → en.wiktionary → Morph-it! |
| `article`, `article_indef`, `article_pl` | sostantivo | Artigo definido no singular, indefinido e definido no plural (`il` · `un` · `i`) | Calculado do `gender` e do som inicial (*lo* antes de s + consoante, z, gn, ps; *l'* antes de vogal; *il* no resto), com um arquivo de exceções para o que a escrita não resolve (*lo yogurt*, *gli dei*) |
| `plural` | sostantivo | Lista de plurais. Invariável: a própria palavra (`["città"]`). Incontável (*marzo*): sem o campo | `forms[]` com tag `plural` ou a tag `invariable` do it.wiktionary → en.wiktionary (sem o acento tônico, aceitando o feminino plural de *uova*, *braccia*) → Morph-it! |
| `plural_src` | sostantivo | Fonte do plural: `wikt` · `enwikt` · `morphit`. Não existe valor para plural gerado | Etapa 5b |
| `conj_class` | verbo | `group` (`are` · `ere` · `ire`), `isc`, `pronominal`, `aux` (`avere` · `essere`) | Terminação do infinitivo, formas do presente, infinitivo em -rsi e forma com tag `auxiliary` |
| `conj` | verbo | Lista plana `{ tense, person, forms }`. `tense`: 1 presente · 2 passato_prossimo · 3 imperfetto · 4 futuro · 5 imperativo. `person`: 1 io … 6 loro | Tabela do it.wiktionary (com os `raw_tags`) → en.wiktionary (pelas `tags`, sem o acento tônico) → Morph-it! |

```json
{ "word": "binario", "pos": "sostantivo", "gender": "m",
  "article": "il", "article_indef": "un", "article_pl": "i",
  "plural": ["binari"], "plural_src": "enwikt" }

{ "word": "finire", "pos": "verbo",
  "conj_class": { "group": "ire", "isc": true, "pronominal": false, "aux": "avere" },
  "conj": [ { "tense": 1, "person": 1, "forms": ["finisco"] },
            { "tense": 2, "person": 1, "forms": ["ho finito"] },
            { "tense": 5, "person": 2, "forms": ["finisci"] } ] }
```

- **Origem de gênero e conjugação:** a D19 marca só a do plural. `gender_src` e `conj_src` estão em aberto no [pipeline](dictionary-pipeline.md#decisões-em-aberto).
- **Cobertura:** dos substantivos do it.wiktionary sem plural nem marca de invariável, o en.wiktionary resolve 55% (5.807 de 10.464); dos sem gênero, 64% (2.772 de 4.348); dos verbos sem tabela, 59% (1.384 de 2.352). O que sobra é quase todo lixo ou palavra rara ([cobertura-enwiktionary.md](propostas/cobertura-enwiktionary.md)).
- **Divergência entre fontes** (*uomo*: "donne" no it.wiktionary × *uomini* no en.wiktionary) vai para o relatório do build e se resolve no arquivo de correções.
- O catálogo de padrões (`rule`) e o índice de quem é membro de qual padrão (`drill`) não fazem parte do verbete: estão no esquema da [etapa 6 do pipeline](dictionary-pipeline.md#6-montar-o-sqlite).

## Campos não utilizados

| Campo | Conteúdo | Tamanho² | Por quê |
|---|---|---|---|
| `categories` | categorias do MediaWiki ("Sostantivi in italiano") | 45 MB | Repete `pos` e `topics`. Só a valência do verbo é aproveitada, e vira campo próprio. |
| `senses[].categories` | área e registro por sentido ("Medicina-IT") | 6 MB | Repete `topics` e `raw_tags`. Só "Pagine senza definizione" é usada, como filtro. |
| `etymology_links` | links da etimologia | 30 MB | O verbete mostra a etimologia como texto. |
| `forms[].source`, `forms[].raw_tags` (fora da conjugação) | origem da tabela, rótulos brutos | 30 MB | Metadado do wiki. Pessoa e número já estão em `tags`. Na conjugação, os `raw_tags` passam a ser lidos para modo e tempo ([Traços de treino](#traços-de-treino)). |
| `senses[].id` | id interno da acepção | 23 MB | Não é exibido. |
| `translations[]` (outras línguas) | inglês, alemão, latim… | ~20 MB | O app é monolíngue com glosa em PT. |
| WikDict `sense`, `sense_num` | rótulo do quadro de tradução ("sostantivo (stazione)") | — | Não liga às acepções de Significati. A glosa é por verbete. |
| `pos_title` | "Sostantivo" | 8 MB | Repete `pos`. |
| `lang`, `lang_code` | sempre "Italiano" / "it" | 8 MB | Constante. |
| `related` (wiktextract) | correlati + varianti + alterati + non confondere misturados | 1,4 MB | Substituído pelo parse do wikitext, que separa as seções. |
| Varianti | formas antigas ou regionais ("fenestra") | — | Confunde quem está em A1–B2. |
| `proverbs` | Proverbi e modi di dire | 1 MB | Fora do escopo (5% de cobertura). |
| `hyponyms`, `hypernyms` | taxonomia ("cane → barboncino") | 0,7 MB | 2–5,5% de cobertura. Não ajuda na leitura. |
| `sounds[].mp3_url`, `ogg_url`, `wav_url`, `audio` | áudio gravado | 0,1 MB | Só 0,8% dos lemas têm. O app usa TTS, como o Livio. |
| `examples[].ref`, `translation`, `bold_*_offsets` | fonte e destaques do exemplo | 0,07 MB | Citazione está praticamente vazia (~0%). O destaque da palavra no exemplo é feito pelo app. |
| `notes` | Uso / Precisazioni | 0,02 MB | 87 lemas (0,1%). |
| Note / Riferimenti | bibliografia | — | O wiktextract não extrai, e não é útil para quem está lendo. |

² Tamanho no JSONL inteiro (501 MB), incluindo as formas flexionadas.

## Decisões em aberto

As do build (fontes, divergências, licenças) estão no [dictionary-pipeline.md](dictionary-pipeline.md#decisões-em-aberto).

| Decisão | Recomendação |
|---|---|
| Imperativo na Conjugação do verbete (DIC-05; proposta 12.2, item 13). O imperativo virou o 5º valor de `tense` (D11e) e é cobrado no Treino. Opções: (a) a seção Coniugazione mostra o imperativo como 5º tempo, depois dos 4 do DIC-05; (b) a seção fica com os 4 tempos, e o imperativo só existe no `conj` para a Revisão e o Treino. | (a): o aluno acha no verbete o que treina. Pede mudar o DIC-05 na spec funcional e o book do verbete. |
| O verbete mostra os traços vindos do en.wiktionary e do Morph-it!? Hoje a Flessione e a Coniugazione só têm o it.wiktionary. Opções: (a) as seções usam os campos da cadeia (`plural`, `conj`), e o verbete mostra o mesmo que o Treino cobra; (b) só o it.wiktionary, e os traços das outras fontes ficam para os exercícios. | (a): uma fonte de verdade para o aluno. Nas divergências, vale o que o pipeline decidir para o verbete (lá a recomendação é deixá-lo como está até o arquivo de correções). |
| Crédito no verbete (DIC-09). Ele diz "Fonte: Wikizionario · CC BY-SA", mas um plural ou uma tabela pode vir do en.wiktionary ou do Morph-it!. Opções: (a) crédito fixo com todas as fontes; (b) a fonte extra só no verbete que a usa. | (b), lendo `plural_src` e os `gender_src` e `conj_src` propostos no pipeline. |
