# Cobertura: o en.wiktionary preenche o que falta no it.wiktionary?

Medido em 2026-10-16 para a decisão D19 ([revisao-treino-decisoes.md](revisao-treino-decisoes.md)).

**Fontes:**

- it.wiktionary: `kaikki.org-dictionary-Italiano.jsonl`, dump de 2026-10-01.
- en.wiktionary: `kaikki.org-dictionary-Italian.jsonl.gz`, baixado em 2026-10-16 (sha256 `3c0f2de5…bffb4f`).

**Método:**

- **Lemas:** contados por palavra, sem repetir. Entradas só de "forma de" ficam de fora.
- **"Sem plural":** substantivo sem forma com tag `plural` e sem a marca `invariable`.
- **Formas do en.wiktionary:** vêm com o acento tônico marcado (*pàrlo*, *finìsco*). Antes de comparar, removi o acento de toda vogal que não é a última da palavra.

## Plural

| | Substantivos |
|---|---|
| Substantivos no it.wiktionary | 36.860 |
| Sem plural nem marca de invariável | **10.464** |
| → o en.wiktionary dá o plural | 4.841 (46%) |
| → o en.wiktionary diz que é invariável | 846 (8%) |
| → o en.wiktionary diz que é incontável (*marzo*) | 120 (1%) |
| **Resolvidos pelo en.wiktionary** | **5.807 (55%)** |
| Continuam sem: o lema não existe no en.wiktionary | 3.860 |
| Continuam sem: existe, mas sem plural | 797 |

**O que sobra é quase todo lixo ou palavra rara** (amostra aleatória de 40):

- formas flexionadas registradas como lema: *colpi*, *foglie*, *feci*, *tenaglie*, *penitenziari*, *Ebrei*;
- locuções: *strato acquifero*, *isolamento elettrico*;
- nomes de família da taxonomia: *Solanacee*, *Loganiacee*;
- termos técnicos: *gigasiemens*, *vinilacetilene*.

Nenhuma palavra de uso básico apareceu na amostra.

**Concordância.** Nos 20.315 substantivos que têm plural nas duas fontes, elas concordam em 20.018 (98,5%). Muitas das 297 divergências são erros de digitação do it.wiktionary que o en.wiktionary corrige (*pirolfile*, *carrrettieri*, *scalpccii*). Outras são plurais duplos legítimos (*riso*: *risa* × *risi*; *budello*: *budella* × *budelli*).

**Palavras comuns conferidas uma a uma (40 palavras):**

| Palavra | O que acontece |
|---|---|
| *casa* | O en.wiktionary resolve: *case* |
| *marzo* | Incontável no en.wiktionary, então fica fora do Plural |
| *uomo* | O it.wiktionary lista **"donne"** como plural. É um erro, e o en.wiktionary dá só *uomini* |
| *uovo*, *braccio* | O en.wiktionary tem o plural, mas o meu filtro descartou as formas marcadas como feminino plural (*uova*, *braccia*). O pipeline precisa aceitar esse caso |
| *latte*, *fame*, *sete* | O it.wiktionary diz invariável e o en.wiktionary dá *latti*, *fami*, *seti*. São substantivos de massa, que quase não se usam no plural |
| As outras 32 | As duas fontes concordam |

## Gênero

| | Substantivos |
|---|---|
| Sem gênero no it.wiktionary | 4.348 |
| O en.wiktionary dá o gênero | 2.772 (64%) |

## Conjugação

| | Verbos |
|---|---|
| Verbos no it.wiktionary | 7.606 |
| Sem tabela de conjugação | 2.352 |
| O en.wiktionary tem tabela | 1.384 (59%) |

**O que sobra:**

- formas flexionadas registradas como verbo: *presento*, *offriamo*, *potranno*, *vedete*;
- palavras de outra classe marcadas como verbo: *sutura*, *affetto*, *divorzio*;
- pronominais sem tabela própria (*incupirsi*, *fossilizzarsi*, *cuocersi*). Esses podem herdar a tabela do verbo base (*cuocere* + *si*).

## Conclusão

- O en.wiktionary resolve 55% dos plurais que faltam, 64% dos gêneros e 59% das conjugações.
- O que ele não resolve é quase todo entrada que não deveria ser lema ou palavra que um aluno A1–B1 não vê.
- Ele também corrige erros do it.wiktionary.
- Ainda não medido: a cobertura dentro do NVdB (falta a lista no disco) e quanto o Morph-it! acrescentaria ao que sobra.
