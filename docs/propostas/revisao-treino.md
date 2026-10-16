# Revisão e Treino: proposta unificada

**Versão 2, com as decisões de 2026-10-16.**

Proposta para a nova Revisão do Postilla, com o Treino. Ela junta três propostas (pedagogia, UX e sistema) e o parecer de um juiz que as comparou, e responde aos problemas do relatório "A Revisão em quatro óticas" (citados como **P01**…**P12**; os médios e baixos aparecem pelo título). Parte do `book-revisao.html` atual, da spec funcional, da arquitetura e do `dictionary.md`.

Esta versão incorpora as 36 decisões do dono do produto e os desdobramentos D2b e D11b–e, registrados em [revisao-treino-decisoes.md](revisao-treino-decisoes.md). Quando o texto cita **Dn**, é a decisão tomada. O que as decisões cortaram saiu do texto e está listado na seção 11. O que ainda falta decidir está na seção 12.2.

O catálogo de padrões (seção 2) foi reclassificado pelas referências A1 de [a1-referencias.md](a1-referencias.md) e volta para aprovação (D11b). Se aprovada, a proposta vira o próximo `book-revisao` (desenho) e, depois, requisitos `REV-`, `TRE-` e `ARQ-` na spec (seção 13).

---

## 1. Em uma frase

**O Treino é a Revisão com o aluno escolhendo o assunto. Os dois usam os mesmos cartões, a mesma correção e o mesmo log de respostas, e a Revisão usa esse log para insistir no que o aluno mais erra.**

### Modelo mental: um log, um gerador, duas portas

```
            dict (conteúdo)                         user (aluno)
  entry ── verbete + traços (artigo, plural, conj)    saved  ── lema + classe + frase de origem
  drill ── membros de cada padrão + itens curados     answer ── log só de inserções (a fonte da verdade)
  rule  ── catálogo de padrões (rules.toml, PT/IT)         │
     │                                                     ▼
     └──────────► gerador de exercício ◄──── dobra do log (estado FSRS, fraqueza, cotas)
                         │
          ┌──────────────┴──────────────┐
      porta REVISÃO                 porta TREINO
      o app escolhe:                o aluno escolhe:
      vencidos, novos,              um tema (Plural)
      reforço do mais fraco         ou uma regra (-co, -go)
                         │
                  correção ─► INSERT em answer
```

- **Um log:** toda resposta, de qualquer porta, vira uma linha em `answer`. Estado do cartão, fraqueza e cotas são calculados a partir dele, e nada disso fica gravado (P08).
- **Um gerador e uma correção:** uma função monta o exercício e outra o corrige, nas duas portas.
- **Duas portas:** só muda quem escolhe os cartões. As respostas das duas contam igual no FSRS (D2).

### Conceitos

| Para quem | Conceito | O que é | Novo? |
|---|---|---|---|
| Código | **Cartão** | Uma lembrança agendada pelo FSRS. Há dois tipos: o **cartão de palavra** (*binario* · Palavra) e o **cartão de padrão** (`pl.co_go`), em que a regra é a lembrança e a palavra muda a cada vez | O cartão já existia; o de padrão é novo |
| Código | **Padrão** | Uma regularidade com id, nível, regra em PT e IT, exemplos e membros. É do tipo `regra` (vira cartão de padrão) ou `lista` (cada membro tem o seu cartão de palavra) | Sim |
| Código | **Resposta** | Uma linha de `answer` | Substitui `review_card` + `review_log` |
| Aluno | Revisão · Treino · tema · regra | "Plural" é um tema; "-co, -go" é uma regra dentro dele | Treino, tema e regra |

"Habilidade" não é um conceito: é só o campo `skill` (um enum). Não existem "domínio", "nível do tema", "faceta" nem estado "Firme".

**Por que existe o cartão de padrão (D1).** Quem esquece que *-co* vira *-chi* esquece isso para *parco*, *banco* e *bosco* ao mesmo tempo. Um cartão por palavra multiplicaria a carga e mediria vocabulário e regra misturados. O book já faz isso na Conjugação ("um cartão por verbo e tempo, a pessoa muda"); aqui a ideia sobe um nível. Uma exceção (*uomo → uomini*) é uma lembrança própria e ganha cartão de palavra. Os ids de padrão são só de acréscimo.

---

## 2. Habilidades e padrões da v1

### 2.1 Habilidades (o enum `skill`)

| `skill` | Tema para o aluno | O que mede | Exemplo |
|---|---|---|---|
| 1 `scrivere` | Palavra | Ver a glosa e escrever a palavra (PT→IT) | "janela (de trem)" → *finestrino* |
| 2 `genere` | Artigo | Gênero que a terminação não diz | ___ *pane* → *il* |
| 3 `articolo` | Artigo | Forma do artigo, que é regra de som | ___ *zaino* → *lo*; ___ *amica* (indef.) → *un'* |
| 4 `coniugazione` | Presente · Passato prossimo · Imperativo | Uma forma do verbo, em 3 dos 5 tempos de `tense` | *finire* · *loro* → *finiscono*; *parlare* · *tu* · negativo → *non parlare* |
| 5 `plurale` | Plural | Plural do substantivo | *il parco* → *parchi* |
| 6 `preposizione` | Preposições | Preposição + artigo, isolada | *di + il treno* → *del treno* |
| 7 `accordo` | Adjetivos | A forma do adjetivo que concorda com o nome | *le chiavi* ___ (*nuovo*) → *nuove* |
| 8 `possessivo` | Possessivos | Possessivo e artigo, que concordam com a coisa possuída | ___ *madre* (*io*) → *mia madre* |
| 9 `piacere` | Piacere | *piace* × *piacciono* e o pronome indireto | *Mi* ___ *i libri* → *piacciono* |

- Sai o `riconoscere` (D3): palavra só se cobra escrevendo.
- `accordo`, `possessivo` e `piacere` são novos (D11e). O imperativo não é `skill` novo: é o 5º valor de `tense`, além dos 4 do DIC-05 (D11e).
- `tense`: 1 presente · 2 passato_prossimo · 3 imperfetto · 4 futuro · 5 imperativo. A v1 cobra só 1, 2 e 5; 3 e 4 existem para o verbete.
- O enum foi renumerado porque nada foi publicado. Depois da v1, os valores só ganham acréscimos.

### 2.2 Catálogo: 30 padrões em 9 temas

`regra` = um cartão de padrão; a palavra muda a cada revisão. `lista` = um cartão por palavra membro; o padrão só agrupa os membros, para a fraqueza e para o Treino. São 30 ids: 25 `regra` e 5 `lista`. Todos são A1 pelo critério "o que os livros A1 apresentam", com peso no *Dai! 1* (D11, D11c). `rule.level` continua no contrato para quando entrar A2.

A coluna **Ordem** é o `rule.position`: a ordem em que a Revisão apresenta os padrões (D4). Ela segue as unidades do *Dai! 1*, intercalando temas. Os padrões sem fonte no *Dai! 1* ficam ao lado do vizinho mais próximo. Os temas estão na ordem da lista do Treino (D35, seção 7.2).

| Tema | Ordem | Id | Tipo | Fonte | Regra (resumo) | Exemplos e membros |
|---|---|---|---|---|---|---|
| **Artigo** | 1 | `gen.lista` | lista | Dai! u0 | Gênero dos nomes em -e frequentes, que a terminação não diz | il pane, la chiave, la notte, il mare |
| | 2 | `gen.sufixo` | regra | sem fonte direta (D11d) | -ione, -tà femininos; -ore masculino; só palavras frequentes | la stazione, la città, il colore |
| | 3 | `art.forma` | regra | Dai! u1–3 | *lo/gli/uno* antes de s + consoante, z, gn, ps; *l'* antes de vogal; *il/i/un* no resto; feminino *la/le/una/l'/un'* | lo zaino, gli studenti, l'amico, un'amica |
| **Presente** | 4 | `pres.are` | regra | Dai! u1–2 | Desinências de -are | parlo, parli, parliamo |
| | 5 | `pres.lista` | lista | Dai! u1–8 | Irregulares frequentes, com os modais (D11e) | sono, ho, sto, faccio, vado, esco, vengo, voglio, posso, devo, so, do, dico, bevo |
| | 6 | `pres.ere` | regra | Dai! u2 | Desinências de -ere | prendo, prendi, prendono |
| | 10 | `pres.isc` | regra | Dai! u3, u5 | -isc- em io, tu, lui, loro | finisco, finiscono |
| | 21 | `pres.ire` | regra | Dai! u5 | Desinências de -ire | dormo, dormite |
| | 22 | `pres.rifl` | regra | Dai! u5 | Pronome antes do verbo | mi alzo, si chiama |
| | 23 | `pres.care_gare` | regra | AlD u3, Arr u6 | Antes de i entra h | cerchi, paghiamo |
| | 24 | `pres.ciare_giare` | regra | sem fonte direta (D11d) | O i do radical cai antes de i; só *mangiare*, *cominciare*, *viaggiare* | mangi, cominciamo, viaggi |
| **Plural** | 7 | `pl.base` | regra | Dai! u2 | -o → -i, -a → -e, -e → -i | libro → libri, casa → case |
| | 8 | `pl.invar` | regra | Profilo A1, AlD u7 | Não muda: vogal tônica final, consoante final, abreviação | la città → le città, il bar → i bar, la foto → le foto |
| | 9 | `pl.lista` | lista | Profilo A1 | Irregular | uomo → uomini (único membro na v1) |
| | 14 | `pl.ca_ga` | regra | Dai! u3 | -ca/-ga → -che/-ghe | amica → amiche, banca → banche |
| | 15 | `pl.co_go` | regra | Dai! u3 (parcial, D11c) | -co/-go → -chi/-ghi. Exceções nomeadas: *amici*, *medici* | parco → parchi, lago → laghi, amico → amici, medico → medici |
| | 16 | `pl.io` | regra | sem fonte direta (D11d) | -io → -i; com ì tônico → -ii; só palavras frequentes | negozio → negozi, binario → binari, zio → zii |
| **Preposições** | 11 | `prep.art` | regra | Dai! u3 (parcial, D11c) | a, da, di, in, su + artigo, nas combinações frequentes; di → de-, in → ne- | al, alla, all', del, nella, sul, dai |
| **Adjetivos** | 12 | `agg.o` | regra | Dai! u3–4 | Adjetivo de 4 formas: -o, -a, -i, -e, como o nome | la casa nuova, i libri nuovi, le chiavi nuove |
| | 13 | `agg.e` | regra | Dai! u3–4 | Adjetivo de 2 formas: -e no singular, -i no plural | la casa grande, le chiavi grandi |
| **Possessivos** | 17 | `poss.forma` | regra | Dai! u4 | O possessivo concorda com a coisa, não com o dono, e vem com artigo | la mia casa, i miei libri, la sua borsa (de lui) |
| | 18 | `poss.famiglia` | regra | Dai! u4 | Parente no singular: sem artigo. No plural e com *loro*: com artigo | mia madre, tuo fratello, i miei fratelli, la loro madre |
| **Piacere** | 19 | `piac.numero` | regra | Dai! u4 | *piace* com singular ou infinitivo; *piacciono* com plural | mi piace il caffè, mi piace leggere, mi piacciono i libri |
| | 20 | `piac.pronome` | regra | Dai! u4 | a me → mi, a te → ti, a lui → gli, a lei → le, a noi → ci, a voi → vi, a loro → gli | le piace, gli piacciono |
| **Passato prossimo** | 25 | `pp.avere` | regra | Dai! u7 | avere + -ato/-uto/-ito | ho parlato, ho venduto, ho dormito |
| | 26 | `pp.essere` | regra | Dai! u7 (parcial, D11c) | essere + particípio; cobra só a escolha do auxiliar, não a concordância | sono arrivato, è partita |
| | 27 | `pp.lista` | lista | Dai! u7 (parcial, D11c) | Particípios irregulares frequentes | fatto, detto, preso, visto, messo, stato, venuto, scritto, letto, aperto |
| **Imperativo** | 28 | `imper.base` | regra | Dai! u8 | tu: -are → a forma de *lui* no presente (*parla*); -ere/-ire → a de *tu* (*prendi*, *finisci*). voi: a de *voi* no presente | parla, prendi, finisci, parlate |
| | 29 | `imper.neg` | regra | Dai! u8 | Negativo do tu: *non* + infinito | non parlare, non prendere |
| | 30 | `imper.lista` | lista | Dai! u8 | Irregulares frequentes | va'/vai, fa'/fai, da'/dai, sta'/stai, di', sii, abbi, siate, abbiate |

**Cinco regras do catálogo:**

- **Padrão definido pela entrada, não pela saída.** *amico* (→ *amici*) e *parco* (→ *parchi*) ficam ambos em `pl.co_go`, porque a dúvida real do aluno é *amici* ou *amichi*. Se cada saída tivesse o seu padrão, "treinar só esta regra" teria sempre a mesma resposta. No A1, a regra é só -chi/-ghi, e *amici* e *medici* vêm nomeadas no texto dela (D11c). As outras palavras em -co/-go com plural em -ci/-gi (*tecnico*, *psicologo*) ficam fora: pedem a regra da tônica, que é A2.
- **Padrões triviais** (`pl.base`, `pres.are`) **são cartões de padrão comuns**: 1 cartão cada, e é deles que vem o vizinho que obriga a decidir (*parchi* × *treni*). Nenhum verbo regular ganha cartão próprio.
- **Um verbo × tempo cai num padrão só**, pela precedência `lista > isc > grafia > rifl > base` no presente, `lista > essere > avere` no passato prossimo e `lista > base` no imperativo afirmativo. O `imper.neg` é a exceção: todo verbo com imperativo tem também uma linha nele.
- **As restrições do A1 ficam nos membros, não no texto da regra.** O `rules.toml` traz a lista fechada de membros dos padrões restritos (`pres.ciare_giare`, `pl.io`, `pp.lista`, `imper.lista`, `pl.lista`), e o pipeline só grava no `drill` o que está nela. Nos padrões "só frequentes" (`gen.lista`, `gen.sufixo`), o corte é por frequência (12.2).
- **Itens curados.** Os membros de `agg.*`, `poss.*` e `piac.*` não saem do dicionário: cada um é uma linha escrita à mão no `rules.toml` (D11e, seção 3.1), porque gerar pares nome + adjetivo dá frases sem sentido.

**Vizinho** (para misturar no Treino), na coluna `rule.neighbor`: `pl.co_go` ↔ `pl.base`, `pl.ca_ga` ↔ `pl.co_go`, `pl.io` ↔ `pl.base`, `pl.invar` ↔ `pl.base`, `pres.isc` ↔ `pres.ire`, `pres.care_gare` ↔ `pres.are`, `pres.ciare_giare` ↔ `pres.are`, `pp.essere` ↔ `pp.avere`, `gen.lista` ↔ `gen.sufixo`, `agg.o` ↔ `agg.e`, `poss.forma` ↔ `poss.famiglia`, `piac.numero` ↔ `piac.pronome`, `imper.neg` ↔ `imper.base`.

### 2.3 Fora da v1

| Fica de fora | Por quê |
|---|---|
| Imperfetto, futuro | Nenhum livro A1 apresenta (D11c) |
| `pl.ma` (*problema*), `pl.cia_gia` (*arancia*), plurais irregulares além de *uomo* (*uova*, *dita*, *mani*); *il problema* e *la mano* no Gênero | A2 ou acima (D11c) |
| Plural -ci/-gi pela tônica (*tecnico*, *psicologo*) | A2; no A1 só -chi/-ghi com *amici*, *medici* (D11c) |
| Concordância do particípio com *essere* | Não é cobrada no A1 (D11c; CILS A1) |
| Particípios irregulares fora da lista (*chiuso*, *risposto*) | Só os frequentes (D11c). O verbo fica sem cartão de passato prossimo |
| Combinações de preposição com *lo* e *gli* (*allo*, *negli*, *sugli*) | Proposta de corte das "combinações frequentes" (D11c); a lista volta para aprovação (12.2) |
| Adjetivos em -co/-go na concordância (*bianchi*, *simpatici*), invariáveis (*blu*), *bello* e *buono* antes do nome | Misturam a concordância com o Plural ou são B1; os itens curados os evitam |
| *c'è/ci sono*, *questo/quello*, *non… mai* | Fora por ora (D11e) |
| Pronomes clíticos (*lo vedo*), imperativo com pronome (*alzati*), passato prossimo dos pronominais (*mi sono alzato*) | Pedem transformar a frase, e a correção fica frágil. Os pronominais no presente (*mi alzo*) entram |
| Condizionale, congiuntivo | Não são A1; *vorrei* é vocabulário |
| Passato remoto e "reconhecer forma" (*disse → dire*) | Não são A1; voltam com as histórias B1 (D28) |
| Preposição em frase | Sem índice de ocorrências, não há frase de onde tirar; e gerar frase erra (*in stazione*, *a casa*) |
| Imagens no cartão | Adiadas para depois da v1 (D24) |

---

## 3. Exercícios e correção

### 3.1 Formatos

São quatro formatos. Cada cartão tem um formato próprio, e só as respostas nesse formato contam no FSRS (seção 6.4). Nas decisões, o "formato B" é o A daqui e o "formato E" é o D.

| Formato | Cartões | Pergunta | Resposta | Conta no FSRS |
|---|---|---|---|---|
| **A · Escrever a palavra** (PT→IT) | `scrivere` | Glosa PT + classe. Sem glosa (ou com Glosas = Italiano): a frase de origem com lacuna e a frase PT alinhada como pista; sem frase, a primeira definição IT com lacuna (D13) | Digitada | Sim. É a primeira e única cobrança da palavra (D3) |
| **B · Gênero** | `genere` (membros de `gen.lista`; cartão de padrão `gen.sufixo`) | "___ *pane*" | Toque em uma de 2 opções pelo som: *il · la*, *lo · la*; antes de vogal, *un · un'*, porque *l'* esconde o gênero (D15) | Sim: é o formato do próprio cartão |
| **C · Forma digitada** | `articolo`, `plurale`, `coniugazione`, `preposizione`, `accordo`, `possessivo`, `piacere` | *il parco* → plural · *capire* · *tu* · *di + il treno* · *le chiavi* ___ (*nuovo*) · ___ *madre* (*io*) · *Mi* ___ *i libri* | Digitada | Sim |
| **D · Escolha de forma** | Só no Treino, na primeira rodada de um padrão (D16) | *il parco* → *parchi* · *parci* | Toque em uma de 2 opções | Não (D2b): só alimenta o ponto fraco |

- **Pares do formato D.** Vêm curados no catálogo (`rule.examples`: linhas "lema certo errado", como `parco parchi parci`). As mesmas linhas formam a tabela da página da regra. Assim o app não tem código de distrator por padrão.
- **Itens curados** (`accordo`, `possessivo`, `piacere`). Cada item é uma linha do `rules.toml` com pergunta, lema, resposta e forma errada: `le chiavi ___ · nuovo · nuove · nuovi`, `___ madre (io) · madre · mia madre · la mia madre`, `Mi ___ i libri. · libro · piacciono · piace`, `(a lei) ___ piace il caffè. · caffè · le · gli`. O lema é a palavra que o item usa (o adjetivo, a coisa possuída, a coisa de que se gosta). O pipeline grava cada linha no `drill` (seção 8.2) e confere no dicionário o gênero e o número do nome e a forma do adjetivo. Divergência vai para o relatório (D19). A forma errada serve ao formato D. A lista de parentesco do `poss.famiglia` (*madre, padre, fratello, sorella, figlio, figlia, marito, moglie, zio, zia, nonno, nonna*) também fica no `rules.toml`; *mamma* e *papà* ficam fora dos itens, porque aceitam artigo.
- **Preposição.** Sempre isolada: *di + il treno* → *del treno* ou *del*. Os membros de `prep.art` são os substantivos de `art.forma` cujo artigo cai numa combinação frequente, gravados como linhas próprias no `drill`.
- **Na resposta, o rótulo do cartão de padrão diz a regra** (`PLURAL · -co, -go`). Num membro de `lista`, o rótulo é só `PLURAL`, porque "Irregulares" já seria uma dica.
- **Frase de contexto.** Na v1, a única frase é a gravada ao salvar; palavras do NVdB e salvas pela busca ficam sem frase (D18). Com o índice de ocorrências (v1.1), a frase pode vir de uma história não lida, se for do mesmo nível (D31).

### 3.2 Regras de nota

O princípio: **a nota mede só o alvo do cartão.** O erro fora do alvo é mostrado, mas a nota fica (D6).

| # | Regra | Exemplo | Veredito → nota | Resolve |
|---|---|---|---|---|
| G1 | Erro fora do alvo não muda a nota | *è arrivato*, com sujeito *lei* | "Certo. Com *lei*: *è arrivata*." → Good | P01, médio "Hard para desvios" |
| G2 | No `scrivere`, qualquer forma do lema pedido vale | *serrande* para *serranda* | "Certo. A palavra no dicionário é *serranda*." → Good | P02 |
| G3 | O artigo é opcional em toda resposta com substantivo. Se vier, é conferido. **Exceção:** no Possessivo, o artigo é o alvo | *i binari* e *binari* → Certo; *le binari* → "Certo. O artigo é *i*: *binario* é masculino."; *l'amici* → "Certo. No plural, *l'* vira *gli*." | Good | P01 |
| G4 | Acento: no `scrivere` é ortografia; nos cartões de forma, é a própria forma. O apóstrofo do imperativo (*va'*) conta como acento | *citta* no `scrivere` → "Certo. Falta o acento: *città*."; *le citta* no Plural → "Quase. Falta o acento." | Good no `scrivere`; Hard na forma | médio "Hard" |
| G4b | Acento que muda a palavra (e/è, da/dà, la/là…) | *e*, pedido *è* | Errado → Again | — |
| G5 | Outro lema com a mesma glosa é ambiguidade da pista, não esquecimento | *finestra*, pedido *finestrino* | "Também é janela. Aqui, a palavra é outra." Sem nota; o cartão volta no fim da sessão com a primeira letra, e essa resposta tem nota normal | médio "Também é janela" |
| G6 | Uma letra diferente, com 6 letras ou mais, só no `scrivere` | *finestrno* | "Quase. Faltou uma letra." → Hard | — |
| G6b | Uma letra diferente num cartão de forma é o próprio erro | *binarii*, *amichi*, *nuovi* para *nuove* | Errado → Again | — |
| G7 | Dica limita a nota a Hard (D20) | — | Certo, com dica → Hard | — |
| G8 | Não sei → Again (`dontKnow`). Pular não grava nada | — | — | baixo "skip" |
| G9 | Escolha (B, D): certo → Good; errado ou Não sei → Again. Sem Hard | — | — | — |

O G5 não precisa de índice PT→IT: a correção já procura o que foi digitado (forma → lema → glosa) e compara as palavras das duas glosas.

**Por skill:**

| Skill | O que se digita | O que vale | Erros típicos |
|---|---|---|---|
| Conjugação | A forma | Pronome sujeito opcional (*loro finiscono*); pronome do pronominal obrigatório (*siede* para *si siede* é Errado); formas alternativas da tabela (*va'* e *vai*). A pessoa pedida é a pedida há mais tempo | — |
| Passato prossimo com *essere* | Auxiliar + particípio | Qualquer terminação do particípio; se o sujeito pede outra, Certo + aviso (G1). Auxiliar trocado é Errado | *ho arrivato* |
| Imperativo negativo | *non* + forma | Só *non* + infinito | *non parla* → "Não é essa. No negativo do *tu*: *non* + infinito." |
| Concordância | O adjetivo | O adjetivo sozinho ou a frase inteira (*le chiavi nuove*) | *nuovi*, *grande* no plural |
| Possessivo | Artigo + possessivo | Com ou sem o nome (*mia* × *mia madre*) | *la mia madre*, *mia casa*, *suo* para *sua sorella* |
| Piacere | O que falta na lacuna | Só a lacuna, ou a frase inteira | *piace i libri*; *gli* para *a lei* |

**Dica.** No `scrivere`, a frase de origem com lacuna ou, sem frase, a primeira letra (como o REV-09). Nos cartões de forma, a regra numa linha, sem a resposta ("-co, -go: ganha h.") (D20). Nas escolhas, não há dica.

### 3.3 Os problemas de Hard, Artigo e Conjugação

| Problema do relatório | Solução |
|---|---|
| Hard para desvios que não são esquecimento | G1, G4 e G5: acento no `scrivere` dá Good; sinônimo fica sem nota (D6) |
| O Artigo de 4 opções deixa chutar | Separado em dois: Gênero com 2 opções honestas, só onde a terminação não diz; forma do artigo como cartão de padrão digitado, `art.forma` (D15) |
| A Conjugação inclui verbos regulares | Verbo regular nunca ganha cartão. *parlare* aparece só como uma das palavras do cartão `pres.are` |
| A regra de plural é ingênua com -co/-go | `pl.co_go` definido pela entrada, com as exceções do A1 nomeadas; *amico* é pergunta, não exceção esquecida |

---

## 4. Modelo de ponto fraco

### 4.1 Como é medido

Uma fórmula, calculada por padrão na mesma dobra do log que calcula o FSRS:

```
para cada resposta efetiva com nota, cujo alvo é o padrão p:
  w   = 0,5 ^ (idade_dias / 30)              -- meia-vida de 30 dias
        × (0,5 se for escolha, 1 se for digitada)
  bad += w   se Again (Errado, Não sei)
  ok  += w   se Good ou Hard
  n   += 1

fraqueza(p) = (bad + 1) / (ok + bad + 4)      -- prior Beta(1, 3): 25% de erro esperado sem dado
fraco(p)    = n >= 5  e  fraqueza(p) >= 0,35
mais fraco  = o padrão fraco com maior fraqueza (desempate: menor retenção do FSRS, depois id)
```

- **Alvo de p:** as respostas do cartão de padrão (se `regra`) ou dos cartões dos membros (se `lista`), de qualquer porta. A escolha de forma (D), que não conta no FSRS, conta aqui com peso 0,5 (D2b).
- **Por que não só a retenção do FSRS:** ela diz se o aluno lembra agora. Um padrão revisado ontem tem retenção alta mesmo que o aluno erre metade das vezes. A fraqueza diz quanto ele acerta.
- Os limiares (30 dias, Beta(1, 3), n ≥ 5, 0,35, 0,5) são premissas técnicas, ajustáveis depois da nova simulação (seção 9).
- Vocabulário não tem medida de fraqueza na v1: o FSRS já traz de volta a palavra que o aluno erra (D25).

### 4.2 Como aparece para o aluno

Só texto, só na exceção (D10):

| Onde | Texto | Quando |
|---|---|---|
| Linha do tema ou da regra, no Treino | "Você tem errado -co, -go" | `fraco(p)` |
| Linha do tema ou da regra, no Treino | "Ainda não treinado" / "Ainda não treinada" | Nenhuma resposta |
| Linha de transição do reforço, na Revisão | "Reforço: plural em -co, -go · 3 cartões" | Bloco de reforço (5.4) |
| Fim da Revisão | "Você tem errado plural em -co, -go." + "Treinar -co, -go ›" | Existe um mais fraco |

Sem número, barra, porcentagem, cor, ícone de nível, "Firme" ou "dominado". A lista do Treino **não muda de ordem** com o desempenho: uma lista reordenada pelo erro vira placar (spec §10, REV-16).

---

## 5. Revisão

### 5.1 O que entra

| Fila | O que é | Cota por dia | Origem |
|---|---|---|---|
| Vencidos | Cartões ativos com `due ≤ agora`, do de menor retenção para o de maior | Sem cota | FSRS |
| Palavras novas | Apresentação + `scrivere`. Salvas da mais antiga para a mais nova, depois NVdB por frequência | 5 (Ajustes: 0 · 3 · 5 · 10) | REV-02, D3, D26 |
| Forma | Gênero e membros de `lista`, de palavras cujo `scrivere` foi acertado num dia depois da apresentação. Membros de `lista` só depois que a Revisão chegou ao padrão deles (5.2) | 2 | Desbloqueio do book |
| Padrão novo | O próximo do catálogo (por `position`), com nível ≤ nível de leitura e com um membro entre as palavras do aluno | 1 | D4 |
| Reforço | 3 itens do padrão mais fraco, num bloco | 1 bloco | D8 |

- **Palavras do aluno:** as salvas e as do NVdB que a Revisão já apresentou. Num item curado, vale o lema da linha (3.1).
- **Nível de leitura** = o nível mais alto entre as histórias em andamento ou lidas; A1 sem nenhuma. Na v1 todo o catálogo é A1, então esse filtro não corta nada (D32); ele passa a valer quando entrar conteúdo A2.
- **Freio:** com mais de 60 vencidos no início da sessão, não entra nada novo naquele dia.
- **Tirar da Revisão:** na página do tema (Mais opções). Os cartões do tema somem da Revisão (filtro) e nenhum padrão novo dele é apresentado. Saem os chips por tempo verbal do REV-04.
- **Cartão ativo** é um filtro, não uma coluna (resolve o "suspender fere OFF-34"):

```
ativo(c) = fonte(c)                  -- palavra: saved.deleted_at = 0 ou intro com origin = nvdb
                                     -- padrão: tem alguma resposta e rule.retired = 0
        && existe_no_dict(c)         -- entry ou linha de drill
        && !known(lemma)             -- "Já sei" efetivo
        && tema_na_revisao(c)        -- setting
        && desbloqueado(c)           -- só vale na porta Revisão
```

Uma palavra do NVdB respondida no Treino sem ter sido apresentada não passa em `fonte()`. Por isso ela nunca vence na Revisão, mas as respostas dela contam para a fraqueza.

### 5.2 Como a sessão é montada

```
montarLote(agora, hoje, dobra, cfg):                     -- determinístico: hash(cartão, hoje) desempata
  ativos    = cartões com ativo(c)
  voltas    = cartões com Again hoje e menos de 2 respostas depois dele      -- sai do log
  vencidos  = [c em ativos | c.due <= agora], por retenção crescente
  freio     = len(vencidos) > 60
  novos     = freio ? [] :
                palavras (5 − novasHoje) ++ forma (2 − formaHoje)
             ++ padrão (1 − padrãoHoje)                                      -- cotas da porta Revisão
  reforço   = mais_fraco existe e é o primeiro lote do dia ? 3 itens dele : []
  lote      = intercala(voltas depois de ≥ 3 cartões, vencidos, novos 1 a cada 4)
              regras: 2 cartões da mesma palavra nunca no mesmo lote (exceto apresentação + 1ª cobrança);
                      skills diferentes se alternam quando há escolha;
                      reforço entra depois do 10º cartão;
              corta em 20 (o reforço conta nos 20)
```

- **Lotes de 20.** Depois de 20, o fim do lote oferece "Continuar" ou parar. O que ficou continua vencido (REV-12). Nunca "1 de 412".
- **Apresentação.** Palavra nova: lema, artigo, glosa, definição, áudio; a primeira pergunta (`scrivere`) vem 3 cartões depois, como no book (D3). Padrão `regra` novo: a página da regra (2 a 3 frases, tabela de exemplos) e um botão "Continuar"; a primeira pergunta, digitada, vem 3 cartões depois e cria o cartão. Padrão `lista`: quando chega a vez dele, aparece a página da regra, sem pergunta, e dali em diante os membros que são palavras do aluno podem entrar pela cota de forma (12.2).
- **Palavra da vez num cartão de padrão:** o membro que o aluno errou na última vez, se faz mais de 1 dia; senão, o usado há mais tempo. Primeiro as palavras do aluno, depois o NVdB. Nunca a mesma duas vezes seguidas.
- **Erro:** o cartão volta depois de pelo menos 3 outros, no máximo 2 vezes (D21). Depois disso, fica para amanhã. As voltas contam no FSRS (D2). A fila de voltas sai do log, então sobrevive ao encerramento do app.
- **Cotas:** contam só cartões criados pela porta Revisão. O Treino nunca gasta cota.

### 5.3 "Por que este cartão"

Uma linha em `--type-small`, `--color-ink-muted`, **na resposta**, ao lado de "Volta em…", e nunca na pergunta, onde ela seria uma dica sem o teto de Hard (D17).

| Motivo | Texto |
|---|---|
| Errou nesta sessão | Errou há pouco |
| Palavra nova | Palavra nova · das salvas / das mais comuns |
| Padrão novo | Regra nova |
| Bloco de reforço | (dita uma vez, na linha de transição) |
| Vencido normal | (sem linha) |

No cartão de padrão, "Volta em 4 dias" vira "**A regra** volta em 4 dias", porque a palavra vai ser outra.

### 5.4 Reforço

- Um bloco por dia, no primeiro lote, depois do 10º cartão, dentro dos 20, só se existe um padrão mais fraco (D8).
- Uma linha de transição, sem tela nova: "Reforço: plural em -co, -go · 3 cartões".
- Três itens do padrão, com 3 palavras diferentes. Num padrão `regra`, o próprio cartão de padrão; num `lista`, só membros que o aluno já tem em cartão. **O reforço nunca cria cartão.**
- A regra curta aparece antes do bloco só se o aluno errou alguma das 3 últimas respostas daquele padrão.
- As respostas contam no FSRS como qualquer outra (D2, seção 6.4).

---

## 6. Treino

### 6.1 Entrada

| Caminho | Toques |
|---|---|
| Raiz da aba › tema › **Treinar plural** (mistura as regras do tema) | 2 |
| Raiz da aba › tema › regra › **Treinar só esta regra** | 3 |
| Fim da Revisão › **Treinar -co, -go** | 1 |

"Ver a regra", aberto de dentro de uma sessão, mostra a mesma página da regra sem o botão "Treinar", para não abrir uma sessão dentro de outra. Um padrão com menos de 10 membros (`pl.lista`) não ganha página própria e aparece só dentro do tema.

### 6.2 A rodada: 10 itens, sequência fixa (D16)

1. **Primeira vez no padrão** (nenhuma resposta): a apresentação da regra, que não conta como item. Depois, 2 itens de escolha de forma (formato D), que não contam no FSRS (D2b).
2. **O resto até 10:** forma digitada (C).
   - Em "só esta regra", 1 item em cada 3 é do padrão vizinho.
   - Em "tema inteiro", os padrões são sorteados com peso igual à fraqueza (0,25 para quem nunca foi visto), com **no máximo um padrão nunca visto por rodada**. Assim a rodada não vira seis apresentações seguidas.
3. **Erro:** a resposta mostra a regra aplicada à palavra ("*medico* é exceção: o plural é *medici*"). O item volta 2 itens depois, no máximo 2 vezes. As voltas não contam nos 10: "4 de 10 · +1".
4. **Palavras:** primeiro as do aluno que são membros do padrão; depois o NVdB por frequência, **com a glosa visível na pergunta** (*il parco* · parque) quando a palavra não é do aluno e Glosas = Português. Nos itens curados, primeiro os itens com lema do aluno. Uma palavra por rodada.
5. **Padrão `lista`:** os itens são os membros, com os vencidos primeiro.

Sem fases, sem limiares e sem critério de "firme por hoje".

### 6.3 Fim

```
PLURAL · -co, -go
10 cartões · Certos 7 · Quase 1 · Errados 2
amico: você escreveu amichi · amici
medico: você escreveu medichi · medici
A regra volta na Revisão em 3 dias.          ← só em "só esta regra"
[ Voltar a Plural ]  [ Treinar de novo ]
```

Sem comemoração (REV-16). Na resposta de cada item do Treino não há "Volta em…": a ligação com a Revisão é só esta linha no fim.

### 6.4 Como conta no FSRS (D2, D2b)

**Igual ao Anki com FSRS-6: toda resposta no formato do próprio cartão, de qualquer porta (Revisão, voltas, reforço, Treino), atualiza S e D.** As do mesmo dia passam pela fórmula de estabilidade de curto prazo. Não existe "só a primeira resposta do dia" nem resposta de "prática", com uma exceção: a escolha de forma do Treino.

| Caso | Efeito |
|---|---|
| Primeira resposta do dia de um cartão existente | Revisão normal do FSRS-6, com o tempo real desde a última (antecipada, se ele não estava vencido) |
| Outras respostas do mesmo dia (voltas, reforço, outra rodada, outra sessão) | Fórmula de curto prazo do FSRS-6: S e D mudam |
| Again | O contador de lapsos sobe só no primeiro erro do dia de um cartão em revisão. Na v1 ele só existe na dobra (D25) |
| Gênero (formato B) | Conta: a escolha é o formato do próprio cartão `genere` |
| Escolha de forma (formato D) | Não conta (D2b): é escolha num cartão digitado. Só alimenta a fraqueza |
| Padrão nunca visto | A primeira resposta digitada cria o cartão e dá S e D iniciais (D9) |
| Palavra do NVdB no Treino | Gera respostas, mas não vira cartão de Palavra (não passa em `fonte()`, D9) |
| Membro de `lista` que é palavra do aluno | Vira cartão de palavra; aparece na Revisão quando estiver desbloqueado (D9) |
| Cotas da Revisão | O Treino não gasta |

A regra continua sem `if` por porta: o formato do cartão sai do `skill` (escolha em `genere`, digitado nos demais), e a resposta conta se `answer.format` é o formato do cartão.

---

## 7. Navegação e telas

### 7.1 Onde mora

**4ª aba "Revisão"** (IT: *Ripasso*), com a seção "Treino" (IT: *Allenamento*) na raiz (D5, D36). A barra fica Biblioteca · Dicionário · Revisão · Ajustes. O cartão "Revisão de hoje" sai da raiz do Dicionário.

```
Navigator raiz
 ├─ Shell: IndexedStack + barra de abas
 │   ├─ Navigator Biblioteca
 │   ├─ Navigator Dicionário
 │   ├─ Navigator Revisão       raiz → tema → regra (com a barra)
 │   └─ Navigator Ajustes
 ├─ Leitor · Verbete do Leitor
 └─ Sessão (Revisão ou Treino, sem barra)
     ├─ Verbete da sessão       (push no raiz; entra no Histórico com origem "Revisão", D29)
     ├─ Regra da sessão         (sem "Treinar")
     └─ Trecho da história      (push no raiz; só o parágrafo, sem o Leitor; não toca no progresso, D22)
```

### 7.2 Telas

**Raiz da aba**

```
Revisão                                ⋯
┌──────────────────────────────────────┐
│ Revisão de hoje                    › │  .ui-hero--compact
│ 20 cartões · 5 palavras novas        │
└──────────────────────────────────────┘
TREINO
 Artigo                              ›   il, lo, la, l'
 Presente                            ›   parlo, prendo, dormo
 Plural                              ›   Você tem errado -co, -go
 Preposições                         ›   del, nella, alla
 Adjetivos                           ›   nuovo, nuova, nuovi
 Possessivos                         ›   la mia casa, mia madre
 Piacere                             ›   mi piace, mi piacciono
 Passato prossimo                    ›   Ainda não treinado
 Imperativo                          ›   parla, non parlare
──────────────────────────────────────
Biblioteca  Dicionário  Revisão  Ajustes
```

Uma lista só, sem grupos, na ordem em que o *Dai! 1* apresenta os temas (D35):

| Tema | Primeira unidade do *Dai! 1* | O que a unidade traz |
|---|---|---|
| Artigo | u0–1 | *il genere dei nomi*; *articoli determinativi singolari* |
| Presente | u1 | presente de *essere*, *avere*, *stare* e dos verbos em -are |
| Plural | u2 | *la formazione del plurale* |
| Preposições | u3 | *alcune preposizioni articolate* |
| Adjetivos | u3 | *aggettivi qualificativi*, depois das preposições na coluna do índice |
| Possessivos | u4 | *aggettivi possessivi* |
| Piacere | u4 | *il verbo piacere*, *pronomi indiretti*, depois dos possessivos |
| Passato prossimo | u7 | *il passato prossimo*, *i participi passati irregolari* |
| Imperativo | u8 | *l'imperativo* |

Todos os temas têm lugar no índice. Dois empates de unidade (Preposições × Adjetivos na u3, Possessivos × Piacere na u4) seguem a ordem da coluna GRAMMATICA do índice, que pode não ser a ordem das páginas. As Preposições do Treino são só as articuladas (u3); as simples (*a*, *in*, u2) não são treinadas. Os nomes dos tempos e de *Piacere* ficam sempre em italiano, como no verbete.

| Estado do cartão | Título | Linha | Toque |
|---|---|---|---|
| Com cartões | Revisão de hoje | 20 cartões · 5 palavras novas | Empilha a sessão |
| Interrompida | Continuar revisão | 9 de 20 · +1 | Retoma |
| Nada vencido (inclusive depois de terminar) | Nada para revisar agora | Próxima revisão amanhã, 9 cartões. | Não é link |
| Só salvas, nenhuma salva | Nada para revisar ainda | Salve palavras no Dicionário para elas entrarem aqui. | Não é link |

**Tema e regra** (empilhados na aba)

```
‹ Revisão              Plural    ⋯         ‹ Plural              -co, -go
Plural                                      PLURAL
O plural muda a última letra.               -co, -go
Quase sempre: -o → -i, -a → -e.             -co e -go ganham h no plural:
REGRAS                                      parco → parchi, lago → laghi.
 -o, -a, -e            ›                    Exceções: amico → amici,
 -co, -go              ›  Você tem errado   medico → medici.
 -ca, -ga              ›  amica → amiche    ┌ singolare ───── plurale ┐
 -io                   ›  zio → zii         │ il parco        i parchi│
 Invariáveis           ›  le città          │ il lago         i laghi │
 uomo → uomini                              └─────────────────────────┘
[      Treinar plural      ]                [   Treinar só esta regra   ]
Mais opções: Tirar da Revisão · Relatar erro
```

**Cartão de padrão, pergunta** (o mesmo layout serve para todo cartão digitado)

```
‹ Revisão                           ⋯
━━━━━━━━──────────────   4 de 20 · +1
PLURAL · -co, -go                       .ui-label: a regra é parte da pergunta
il medico                               --type-headword, lang="it"
sostantivo maschile · singolare
Escreva o plural.
┌────────────────────────────────────┐
│                                    │  sem placeholder; cresce com o texto
└────────────────────────────────────┘
Mostrar dica                            ghost, sem ícone
                          [  Não sei  ]   vazio: Não sei (secondary) · com texto: Conferir (primary)
 à  è  é  ì  ò  ù
```

**Concordância · Possessivo · Piacere · Imperativo** (só a parte que muda; o resto é o layout acima)

```
ADJETIVOS · -o, -a, -i, -e              POSSESSIVOS · parentesco
le chiavi ___                           ___ madre                  (io)
nuovo · aggettivo                       Escreva o possessivo, com o artigo
Escreva o adjetivo.                     se tiver.
→ nuove                                 → mia madre

PIACERE · piace, piacciono              IMPERATIVO · negativo
Mi ___ i libri.                         parlare
piacere                                 tu · negativo
Escreva o verbo.                        Escreva o imperativo.
→ piacciono                             → non parlare

PIACERE · pronome
(a lei) ___ piace il caffè.
Escreva o pronome.
→ le
```

**Gênero**

```
GÊNERO
___ pane
sostantivo
Escolha o artigo.
[   il   ]  [   la   ]                   2 opções pelo som; lo · la; antes de vogal: un · un'
                          [  Não sei  ]
```

**Resposta** (em todos os formatos)

```
PLURAL · il medico                      pergunta encolhida em uma linha
┌────────────────────────────────────┐
│ medichi                         ✕  │  a letra que difere sublinhada
└────────────────────────────────────┘
✕ Não é essa.     [Contar como certa]  desfazer na linha do veredito
A regra volta ainda nesta revisão · Errou há pouco
i medici                           <)
REGRA
medico é exceção: medici.   Ver a regra ›
NA HISTÓRIA                             (só se a palavra tem frase de origem; o grifo é o amarelo)
«… frase de origem …»   Ver o trecho ›
                        [  Continuar  ]  o mesmo lugar do Não sei/Conferir
```

Na escolha, a opção tocada ganha ✓ ou ✕, a opção certa fica marcada, e o resto da resposta é igual. A ordem é: veredito com desfazer → quando volta + porquê → palavra com artigo e áudio → classe e IPA → glosa (pílula fechada; não aparece com Glosas = Italiano) → forma → regra → Na história → links.

**Trecho da história** (D22)

```
‹ Voltar ao cartão
NA HISTÓRIA
Título da história · A1
… Il [binario] è quasi vuoto e l'aria       o parágrafo inteiro; a forma salva grifada
sa di caffè. …
```

Uma página empilhada só com o parágrafo da frase de origem, sem o Leitor, sem barra e sem doca. Abrir não grava progresso, conclusão nem última aberta. O que falta desenhar está em 12.2.

**Bloco de reforço** (dentro do lote, sem tela própria)

```
━━━━━━━━━━━━━──────────   11 de 20
Reforço: plural em -co, -go · 3 cartões        linha de transição, foco nela
(regra curta, só se errou alguma das 3 últimas)
[ Continuar ]
```

**Fim da Revisão**

```
REVISÃO DE HOJE
20 cartões revisados
Certos 15 · Quase 2 · Errados 3
5 palavras novas: chiave, giornale…
Você tem errado plural em -co, -go.  Treinar -co, -go ›
Mais 34 vencidos.                         (só se sobrou)
[ Continuar ]   [ Voltar à Revisão ]
```

### 7.3 Comportamentos

| Tema | Comportamento |
|---|---|
| **Botão único** | Campo vazio: "Não sei". Com texto: "Conferir". Nunca dois botões lado a lado. Nas escolhas, a barra mostra só "Não sei" |
| **Desfazer** | "Contar como certa" fica na linha do veredito em Errado e Quase; tocado, vira "Contada como certa." + "Desfazer". "Já sei" (apresentação ou Mais opções) mostra um aviso com ação: "*chiave* não vai mais para a revisão. Desfazer", por 6 s, e o tempo para enquanto o aviso tem foco. Não sei não tem desfazer: o botão só existe com o campo vazio. No log, são linhas novas com `replaces` (P09) |
| **Contador** | "N de M · +K". M é o tamanho do lote e não cresce. N avança quando um cartão aparece pela primeira vez (a apresentação já avança). K = voltas pendentes + palavras novas que esperam a 1ª cobrança. Leitor de tela: "Cartão 4 de 20, mais 1 para repetir" (P10) |
| **Navegação** | Chevron ‹ com destino ("Voltar à Revisão", "Voltar a Plural"), gesto de borda e voltar do Android fecham sem confirmação (NAV-04, REV-12) |
| **Mais opções** | Na pergunta: Pular cartão · Já sei esta palavra (só Palavra, só Revisão) · Relatar erro. Na resposta: Abrir verbete · Já sei esta palavra · Relatar erro. Sem verbete antes de responder |
| **Na história** | "Ver o trecho ›" empilha a página do trecho (D22). Voltar devolve à resposta, com o foco no link |
| **Teclado** | Desce ao conferir e sobe no próximo cartão digitado. Enter confere; a resposta ignora Enter por 500 ms e depois Enter é Continuar. Esc volta. Nas escolhas, 1 e 2 escolhem a opção. `enterkeyhint="go"` |
| **Foco** | Ao abrir um cartão digitado: o campo, com o nome acessível juntando instrução, pergunta e pista ("Escreva o plural. il medico, sostantivo maschile, singolare."). Escolha: o grupo de opções, com o nome da pergunta. Depois de conferir: o veredito (`tabindex="-1"`, sem `role="status"`), lido numa frase só ("Não é essa. A resposta é i medici."). Apresentação: o lema. Transição do reforço: a linha. Fim: o título. Ao voltar de um push: o link que abriu (ACE-02) |
| **Texto grande** | O campo tem altura mínima de 44 px e cresce. O resultado quebra a linha, sem reticências. Palavras não se partem |
| **Leitor de tela** | A lacuna é lida como "lacuna". Teclas de acento com `aria-label` ("e com acento grave"). IPA `aria-hidden`. "Sem resposta" em `lang="pt-BR"` |
| **Movimento** | Fade + 8 px (`--dur-fast`); instantâneo com movimento reduzido (ACE-01). Sem háptico. Sem áudio automático e sem ajuste para ele: só toca no botão de ouvir (D33) |

### 7.4 Amarelo e pedidos ao design system

| Tela | O único amarelo |
|---|---|
| Raiz, tema, regra | Traço da aba ativa |
| Pergunta (todos os formatos), apresentação, transição, fim | Nenhum |
| Resposta | Grifo em "Na história"; sem frase, nenhum |
| Trecho da história | Grifo na forma salva |

Pedidos ao brand lead, numa lista só:

1. `.ui-tabbar` com 4 abas e um ícone para Revisão. O `layers` sugerido não está na lista do `components-shared.md`.
2. Uma variante de `.ui-toast` com ação, que também serve ao SAL-02 ("Removida das Salvas. Desfazer").
3. A borda do campo em repouso precisa de 3:1. O `--color-rule-strong` atual dá 1,66:1 no claro e 1,91:1 no escuro, e já é o contorno do campo. Um token novo, ou `--color-ink-muted`.
4. "Mostrar dica" sem ícone (o `lightbulb` está fora da lista).
5. O bloco "Na história" da resposta e a página do trecho reusam o componente "Nella storia" do verbete, em vez de um `.rev-ctx` próprio.

### 7.5 Textos novos × Imersão × ARQ-46

| Texto | Área da Imersão | Classe |
|---|---|---|
| Aba "Revisão/Ripasso", seção "Treino/Allenamento", títulos das páginas | Navegação | `NavStrings` |
| Botões, instruções, vereditos, contador, porquê, avisos, fim | Rótulos e botões | `UiStrings` |
| Nomes de tema e de regra, textos de regra (`rule.name_*`, `rule.text_*`) | Rótulos e botões (D14) | Vêm do `dict` nos dois idiomas; o app escolhe a coluna pela área |
| Nomes dos tempos, pessoa, classe, perguntas dos itens curados, "(a lei)" | Sempre em italiano | — |
| Glosa na pílula | Área Glosas: com Italiano, a glosa some e o `scrivere` usa a lacuna | — |

---

## 8. Dados e pipeline

### 8.1 Banco `user`

Entram uma tabela (`answer`) e quatro colunas em `saved`. Saem `review_card`, `review_log`, `known_word` e `word_image` do book.

```sql
CREATE TABLE saved (
  id         TEXT    PRIMARY KEY,                -- UUID v7 (ARQ-33)
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,
  deleted_at INTEGER NOT NULL DEFAULT 0,
  lemma      TEXT    NOT NULL UNIQUE,            -- a salva continua por lema (ARQ-35, SAL-02)
  pos        TEXT    NOT NULL,                   -- classe do verbete onde salvou: só ela gera cartões (D12)
  story_id   TEXT    NOT NULL DEFAULT '',
  paragraph  INTEGER NOT NULL DEFAULT 0,         -- também abre a página do trecho (D22)
  sentence   INTEGER NOT NULL DEFAULT 0,
  form       TEXT    NOT NULL DEFAULT ''         -- forma tocada; '' = sem frase de origem
);

CREATE TABLE answer (                            -- só inserções; nenhuma linha muda ou é apagada
  id         TEXT    PRIMARY KEY,                -- UUID v7
  created_at INTEGER NOT NULL,
  updated_at INTEGER NOT NULL,                   -- sempre = created_at
  deleted_at INTEGER NOT NULL DEFAULT 0,         -- sempre 0
  at         INTEGER NOT NULL,                   -- ms UTC; o instante que vale para o FSRS
  day        INTEGER NOT NULL,                   -- localDay com virada às 4h: 20261016 (D30)
  replaces   TEXT    NOT NULL DEFAULT '',        -- linha que esta substitui; '' = nenhuma
  kind       INTEGER NOT NULL DEFAULT 0,         -- 0 cartão de palavra · 1 cartão de padrão
  rule       TEXT    NOT NULL DEFAULT '',        -- kind 1: o cartão; kind 0: o padrão do membro; '' na Palavra
  lemma      TEXT    NOT NULL,                   -- kind 0: a palavra do cartão; kind 1: a palavra da vez
  pos        TEXT    NOT NULL,
  skill      INTEGER NOT NULL,                   -- enum da seção 2.1
  tense      INTEGER NOT NULL DEFAULT 0,         -- 1 presente · 2 passato_prossimo · 3 imperfetto · 4 futuro · 5 imperativo
  person     INTEGER NOT NULL DEFAULT 0,         -- 1 io … 6 loro
  cue        TEXT    NOT NULL DEFAULT '',        -- item curado: a pergunta da linha ('le chiavi ___'); '' nos outros
  format     INTEGER NOT NULL DEFAULT 0,         -- 0 digitado · 1 escolha
  verdict    INTEGER NOT NULL,                   -- 1 intro · 2 known · 3 void · 4 wrong · 5 dontKnow · 6 almost · 7 ok
  reason     INTEGER NOT NULL DEFAULT 0,         -- motivo do aviso, do Quase ou do Errado
  hinted     INTEGER NOT NULL DEFAULT 0,
  mode       INTEGER NOT NULL,                   -- 1 revisão · 2 treino (só para as cotas e auditoria)
  origin     INTEGER NOT NULL DEFAULT 0,         -- só em intro de palavra: 1 salvas · 2 nvdb
  typed      TEXT    NOT NULL DEFAULT '',        -- até 64 caracteres
  elapsed_ms INTEGER NOT NULL DEFAULT 0
);
CREATE INDEX answer_card     ON answer(kind, rule, lemma, pos, skill, tense, at);
CREATE INDEX answer_day      ON answer(day);
CREATE INDEX answer_replaces ON answer(replaces) WHERE replaces <> '';
```

- **Chave do cartão:** `kind = 1` → `rule`; `kind = 0` → `lemma·pos·skill·tense`. Em Dart, um `extension type CardKey` (ARQ-47). O `cue` não entra na chave: ele só identifica o item da vez num cartão de padrão curado.
- **A nota não é gravada.** Ela sai de `(verdict, reason, hinted, format)` por uma tabela no código. Mudar a tabela recalcula tudo, sem migração.
- **Pular e Ambíguo (G5) não gravam linha.** "Contar como certa" grava `ok` com `replaces` = a errada. Desfazer grava `void` com `replaces`. "Já sei" grava `known`. As linhas efetivas são as que nenhuma outra substitui.
- **Dobra:** lê as linhas efetivas em ordem `(at, id)` no isolate do banco (ARQ-31), ao abrir a Revisão ou o Treino, e mantém em memória: o estado FSRS-6 de cada cartão (S, D, lapsos, estado), a fraqueza de cada padrão, as cotas do dia, a fila de voltas e o que já foi apresentado. Nada disso é gravado. Cada linha efetiva no formato do cartão passa pelo FSRS (6.4). O fuzz do intervalo usa semente fixa (`fnv1a32(card + reps)`), para o estado ser função do log.
- **Tamanho:** com 100 respostas por dia, ~36 mil linhas e ~3,5 MB por ano. Cabe no backup de 25 MB do Android (ARQ-79). O custo da dobra (dezenas de ms; ~0,3 s com 5 anos) é estimativa, **a medir**.
- **Migração:** sem app publicado, tudo entra no `001.sql`. Se a v1 sair sem a Revisão, o script é aditivo. Coluna nova é sempre `NOT NULL DEFAULT <zero>`, e o zero quer dizer "não há".
- O `user` anexa o `dict` só para leitura (`ATTACH … ?mode=ro&immutable=1`), para o filtro `ativo()` caber numa consulta.

### 8.2 Contrato do `dict` (pedido a `postilla-content`, ARQ-07)

**Campos novos em `entry.data`:**

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

`plural_src`: `wikt` · `enwikt` · `morphit` (D19). Não existe valor para plural gerado.

**Tabelas novas:**

```sql
CREATE TABLE rule (                       -- escrita à mão em postilla-content (rules.toml), D14
  id        TEXT    PRIMARY KEY,          -- 'pl.co_go'; só acréscimo, nunca renomeado
  skill     INTEGER NOT NULL,
  type      INTEGER NOT NULL,             -- 1 regra (cartão de padrão) · 2 lista
  level     INTEGER NOT NULL,             -- 1 A1 · 2 A2 …; na v1, todos 1
  position  INTEGER NOT NULL,             -- ordem do Dai! 1: no tema e na apresentação pela Revisão
  neighbor  TEXT    NOT NULL DEFAULT '',  -- padrão vizinho para misturar
  name_pt   TEXT    NOT NULL,             -- '-co, -go'
  name_it   TEXT    NOT NULL,
  text_pt   TEXT    NOT NULL,             -- até 3 frases; '{lemma}' e '{answer}' para a frase da resposta
  text_it   TEXT    NOT NULL,
  examples  TEXT    NOT NULL,             -- linhas 'lema certo errado': tabela da página e formato D
  retired   INTEGER NOT NULL DEFAULT 0    -- 1 = saiu do catálogo; o filtro ativo() ignora
);

CREATE TABLE drill (                      -- quem é membro de qual padrão
  entry_id INTEGER NOT NULL REFERENCES entry(id),
  skill    INTEGER NOT NULL,
  tense    INTEGER NOT NULL DEFAULT 0,
  rule     TEXT    NOT NULL REFERENCES rule(id),
  cue      TEXT    NOT NULL DEFAULT '',   -- item curado: a pergunta ('___ madre (io)')
  answer   TEXT    NOT NULL DEFAULT ''    -- item curado: a resposta; nos outros, ela vem de entry.data
);
CREATE INDEX drill_rule  ON drill(rule, skill, tense);
CREATE INDEX drill_entry ON drill(entry_id);
```

- Uma linha por substantivo × skill (`genere`, `articolo`, `plurale`, `preposizione`), por verbo × tempo (mais uma de `imper.neg`) e por item curado. O gerador já tem um caso por skill (a pergunta de plural não é a de conjugação); os três skills curados leem pergunta e resposta da própria linha.
- O tamanho do `drill` da v1 (~145 mil linhas) foi estimado com o catálogo antigo e o plural gerado. Com as restrições do A1, **recontar** no PR de `postilla-content`.
- **Ids estáveis.** Com cartão de padrão, o `rule.id` é a chave do FSRS: renomear um id apaga o histórico do aluno. Por isso o contrato diz que os ids são só de acréscimo (D1). Um padrão que sai fica com `retired = 1`, e um padrão dividido ganha ids novos (com o histórico do antigo recomeçando). Os enums `skill`, `tense` e `person` têm valores fixos depois da v1, em italiano, e nunca são reordenados.

### 8.3 O que é calculado onde

| Onde | O quê |
|---|---|
| Pipeline, etapa nova 5b "Traços de treino" | **Cadeia de fontes** para plural, gênero e conjugação: it.wiktionary → en.wiktionary (kaikki, já no pipeline) → Morph-it!, com a origem em `plural_src` e um relatório de divergências. **Nada é gerado por regra** (D19). Normalização das formas do en.wiktionary: tira o acento tônico de toda vogal que não é a última (*pàrlo* → *parlo*, *finìsco* → *finisco*) e aceita as formas marcadas como feminino plural (*uova*, *braccia*). **Artigo**: gênero + som inicial + arquivo de exceções (é a própria regra do `art.forma`, não dado que falta). `conj_class` a partir dos `raw_tags`, que hoje são descartados; `conj` plano, com o imperativo. **Classificação** de cada substantivo e de cada verbo × tempo num padrão: o pipeline calcula o que cada regra produziria e compara com o dicionário, só para classificar, nunca para preencher. Corte do A1 pelas listas do `rules.toml`. Cópia de `rules.toml` para `rule` e dos itens curados para `drill`, conferidos contra o dicionário |
| App, na hora da pergunta | Exercício, palavra da vez, pessoa, correção (`grade()` + `osa()`, a mesma distância do ARQ-66, que deixa de ser Levenshtein) |
| App, na dobra (memória) | Estado FSRS, fraqueza, cotas, fila de voltas, apresentados, "Já sei" |
| `setting` | Ajustes › Revisão e os temas tirados da Revisão |

A linguagem da etapa 5b segue o que for decidido para o pipeline inteiro: o ARQ-02 diz Python e o `todo.md` diz C ou Zig (D23).

### 8.4 Cobertura medida

Medição de 2026-10-16 para a D19, em [cobertura-enwiktionary.md](cobertura-enwiktionary.md): it.wiktionary (dump kaikki de 2026-10-01) contra en.wiktionary (kaikki, baixado em 2026-10-16), contando lemas sem repetir e sem as entradas só de "forma de".

| Dado | Falta no it.wiktionary | O en.wiktionary resolve | Sobra |
|---|---|---|---|
| Plural | 10.464 de 36.860 substantivos sem plural nem marca de invariável | 5.807 (55%): 4.841 plurais, 846 invariáveis, 120 incontáveis (*marzo*) | 3.860 sem o lema no en.wiktionary, 797 sem plural. Quase tudo lixo ou raro: formas flexionadas registradas como lema, locuções, taxonomia, termos técnicos |
| Gênero | 4.348 substantivos | 2.772 (64%) | — |
| Conjugação | 2.352 de 7.606 verbos sem tabela | 1.384 (59%) | Formas flexionadas registradas como verbo, palavras de outra classe, pronominais sem tabela própria (*cuocersi*) |
| Glosa PT (medição da v1) | 45,7% dos lemas têm; NVdB 97% · 96% · 91% | — | Sem glosa, o `scrivere` usa a lacuna (P04, D13) |

- **Concordância:** nos 20.315 substantivos com plural nas duas fontes, elas concordam em 20.018 (98,5%). Das 297 divergências, muitas são erros de digitação do it.wiktionary que o en.wiktionary corrige (*pirolfile*, *carrrettieri*); outras são plurais duplos legítimos (*riso*: *risa* × *risi*).
- **Conferidas uma a uma (40 palavras comuns):** *casa* → *case* pelo en.wiktionary; *marzo* é incontável e fica fora do Plural; o it.wiktionary dá **"donne"** como plural de *uomo*, e o en.wiktionary dá só *uomini*; *uovo* e *braccio* pedem a regra do feminino plural; *latte*, *fame*, *sete* são invariáveis no it.wiktionary e têm plural no en.wiktionary (substantivos de massa: vão para o relatório). As outras 32 batem.
- **A silabação não é mais necessária na v1:** o `pl.co_go` do A1 não usa a tônica.
- **O que falta medir:** a cobertura dentro do NVdB (a lista não está no disco); quanto o Morph-it! acrescenta; o imperativo nas tabelas; a distribuição por padrão com o catálogo A1; o tamanho do `drill`; o custo da dobra.

---

## 9. Carga

### 9.1 Números padrão (D7)

| Parâmetro | Valor | Onde muda |
|---|---|---|
| Palavras novas por dia | 5 | Ajustes: 0 · 3 · 5 · 10 |
| Forma nova por dia (Gênero, membros de `lista`) | 2 | Fixo |
| Padrão novo por dia | 1 | Fixo |
| Freio | Mais de 60 vencidos: nada novo no dia | Fixo |
| Lote | 20 cartões, com o reforço incluído | Fixo |
| Voltas por cartão por sessão | 2 (D21) | Fixo |
| Reforço | 1 bloco de 3 por dia (D8) | Fixo |
| Rodada do Treino | 10 itens, fora das cotas (D16) | Fixo |

Ajustes › Revisão fica com três itens: Palavras novas por dia (0 · 3 · 5 · 10), Origem (Só salvas · Salvas e mais comuns) e Palavras que já sei (D34). Tirar um tema da Revisão só pela página do tema.

### 9.2 A simulação antiga não vale

A tabela abaixo foi medida com **outro desenho**: FSRS-4.5, toda palavra começando pelo reconhecer (escolha), escrever com cota de 2 por dia e só a primeira resposta do dia contando. As decisões D2 e D3 trocaram as três coisas. Ela fica aqui só como registro; **nenhum número dela vale para a D7**.

| Cenário (FSRS-4.5, 180 dias, desenho da v1) | Respostas/dia (d81–90) | Min/dia (d81–90) | Min/dia (d171–180) | Palavras em 180 dias |
|---|---|---|---|---|
| 10 novas, sem cotas, sem freio (perto do book) | 142 | 23,6 | 34,6 e subindo | 1.800 |
| 5 novas, sem cotas, sem freio | 103 | 18,8 | 23,3 e subindo | 900 |
| 5 novas, cotas 2 + 2, sem freio | 75 | 11,6 | 15,5 e subindo | 900 |
| 5 novas, cotas 2 + 2, freio a 60 (proposta da v1) | 67 | 10,4 | 12,4, estável | 650 |
| 10 novas, cotas 2 + 2, freio a 60 | 71 | 11,8 | 12,5, estável | 800 |
| 5 novas, cotas 2 + 2, freio a 40 | 50 | 8,3 | 8,6, estável | 430 |
| Só reconhecer, sem produção, sem freio | 54 | 7,5 | 9,7 e subindo | 900 |

A conclusão de que as cotas separadas eram o maior ganho dependia da cota "escrever 2", que saiu (D3). A de que o freio segura o tempo precisa ser reconferida.

### 9.3 O que a simulação nova precisa cobrir antes de fechar a D7

Em FSRS-6 (os 21 parâmetros), com:

- [ ] toda resposta no formato do cartão atualizando S e D, com a fórmula de curto prazo no mesmo dia, e o lapso só no primeiro erro do dia (D2);
- [ ] toda palavra nova começando pelo `scrivere`, com o tempo de digitação (D3);
- [ ] 30 cartões de padrão, apresentados a 1 por dia, e o Gênero como escolha que conta;
- [ ] o bloco de reforço e as 2 voltas, que agora contam no FSRS;
- [ ] uma rodada de Treino por dia, num cenário à parte, medindo o efeito de ~8 respostas no mesmo dia num cartão de padrão sobre o S e o próximo vencimento;
- [ ] as quatro opções de palavras novas (0 · 3 · 5 · 10) com o freio a 60;
- [ ] o tempo do primeiro mês, que é onde o hábito se forma.

---

## 10. Como cada problema do relatório foi resolvido

| # | Problema | Solução | Seção |
|---|---|---|---|
| P01 | Plural ensina "i binari" e reprova | Artigo opcional e conferido; errado dá Certo + aviso; elisão normalizada (G3, D6) | 3.2 |
| P02 | Dica com a forma, correção pelo lema | Qualquer forma do lema vale no `scrivere` (G2, D6) | 3.2 |
| P03 | Só PT→IT | **Aceito pela D3:** só escrever, como no book. Sai o reconhecer | 2.1, 3.1 |
| P04 | Salvas sem glosa nunca viram cartão | `scrivere` com a frase de origem com lacuna e a frase PT como pista, ou a definição com lacuna; NVdB sem glosa e sem frase fica fora (D13) | 3.1 |
| P05 | Salva sem classe, cartão com classe | `saved.pos`: só a classe salva gera cartões; a salva continua por lema (D12) | 8.1 |
| P06 | "Na história" sem fonte | `saved.paragraph/sentence/form` e a página do trecho (D22); NVdB sem frase; índice de ocorrências na v1.1 (D18), com frase de história não lida do mesmo nível (D31) | 3.1, 7.2 |
| P07 | Dados que nenhum documento produz | Contrato: `entry.data` + `rule` + `drill`; cadeia it.wiktionary → en.wiktionary → Morph-it!, sem dado gerado (D19); etapa 5b | 8.2, 8.3 |
| P08 | Estado FSRS em colunas mutáveis | Log só de inserções + dobra; suspensão como filtro | 8.1, 5.1 |
| P09 | Desfazer escondido | Botão único; desfazer na linha do veredito; aviso com Desfazer; `replaces` | 7.3 |
| P10 | "N de 14" e voltas | "N de M · +K", até 2 voltas (D21), fila derivada do log | 5.2, 7.3 |
| P11 | Leitor de tela e texto grande | Foco no veredito, nome acessível do campo, campo que cresce; falta o token da borda | 7.3, 7.4 |
| P12 | Carga diária | 5 novas, forma 2, padrão 1, freio a 60, lotes de 20, Treino fora das cotas (D7); números a confirmar na simulação nova | 9 |
| — | Abrir a história sobrescreve o progresso | Página do trecho, sem o Leitor e sem gravar nada (D22) | 7.2 |
| — | Navegação da sessão (X, gesto, verbete) | Chevron, sem confirmação, verbete no raiz e no Histórico (D29) | 7.1, 7.3 |
| — | Abrir verbete antes de responder | Some do Mais opções na pergunta | 7.3 |
| — | Glosa aberta com Glosas = Italiano | Pílula fechada que some; tabela de textos × Imersão × ARQ-46 | 7.2, 7.5 |
| — | "Também é janela" exige índice | Busca de ida, sem índice, sem nota (G5) | 3.2 |
| — | Hard para desvios | G1, G4, G5 (D6) | 3.3 |
| — | Artigo de 4 opções; Conjugação com regulares | Gênero em 2 + `art.forma` (D15); regulares só em cartão de padrão | 3.3 |
| — | Imagens de 512 px no `user` | Adiadas; sai o REV-14 (D24) | 2.3 |
| — | O teclado sobe e desce | Botão no mesmo lugar, Enter com 500 ms | 7.3 |
| — | Acessibilidade e dois "dias" | Lacuna, acentos, IPA, `lang`; uma `localDay` com virada às 4h também no Histórico (D30) | 7.3, 8.1 |
| — | "skip" com dois sentidos | `dontKnow` grava; Pular não grava | 3.2, 8.1 |
| — | Nomes e design system | Enums em italiano; OSA nos dois lugares; "Nella storia" reusado; ícones pedidos (D36) | 7.4, 8 |
| — | -co/-go ingênuo | `pl.co_go` por entrada; no A1, -chi/-ghi com *amici*, *medici* nomeadas (D11c) | 2.2 |
| — | Textos | "Certo." com ponto; sem placeholder; `go`; a letra que difere sublinhada e nomeada | 7.2, 7.3 |

---

## 11. O que foi cortado e por quê

O critério é o do AGENTS.md: menos conceitos, menos codepaths, e o zero como valor válido.

**Cortado pelas decisões de 2026-10-16:**

| Cortado | Decisão | Por quê |
|---|---|---|
| `riconoscere`, formato de escolha de sentido (IT→PT), distratores, desbloqueio do escrever com estabilidade ≥ 10 dias, cota "escrever 2/dia" | D3 | Palavra só se cobra escrevendo, como no book |
| Ajuste "Produção liga/desliga" | D34 | Sem reconhecer, não há o que desligar |
| `.rev-opt` em largura total (pedido ao design system) | D3 | Era só da escolha de sentido |
| Regra "só a primeira resposta do dia mexe no FSRS"; respostas de "prática" | D2 | Toda resposta no formato do cartão conta, como no Anki |
| Leitor em consulta (LEI-13 candidato), flag que desligava as escritas do Leitor | D22 | A página do trecho não precisa do Leitor |
| Plural gerado por regra (`plural_src = regola`) | D19 | Cadeia de fontes; o que nenhuma fonte tem fica sem plural |
| Imperfetto, futuro (`imp.*`, `fut.*`), `pl.ma`, `pl.cia_gia`, resto de `pl.lista`, *il problema* e *la mano* no Gênero, -tù no `gen.sufixo` | D11c, D11d | Não são A1 pelo critério dos livros |
| Regra da tônica no -co/-go e a dependência da silabação | D11c | No A1, só -chi/-ghi com exceções nomeadas |
| Concordância do particípio no `pp.essere` | D11c | Só a escolha do auxiliar é A1 |
| Grupos "Substantivos · Verbos" na lista; ordem "da gramática" | D35 | Uma lista só, na ordem do *Dai! 1* |
| Imagens (REV-14) | D24 | Adiadas para depois da v1 |

**Cortado na unificação das três propostas (v1):**

| Cortado | De onde | Por quê |
|---|---|---|
| Padrão definido pela saída (`co_ci` × `co_chi`, `art.e_m` × `art.e_f`) | Sistema | "Só esta regra" teria sempre a mesma resposta. O classificador fica como teste interno do pipeline |
| Um item de forma por palavra; reforço que cria itens novos | Sistema | Multiplica a carga onde o aluno erra (volta o P12) |
| `due = at` depois de Again; 3 voltas | Sistema | Distorce o FSRS. A fila de voltas sai do log |
| `drill` por célula (~136 mil linhas de conjugação) | Sistema | A unidade do cartão é verbo × tempo. A comparação por célula fica no pipeline |
| `rule.trivial` (triviais fora da Revisão) | Sistema | O trivial custa 1 cartão e é o vizinho que obriga a decidir |
| Estados Não visto · Aprendendo · Firme e seus critérios | Pedagogia | "Firme" é rótulo de domínio (spec §10, REV-16); 5 limiares a mais |
| 4 fases com limiares e "5 acertos seguidos em 3 palavras" | Pedagogia | Uma sequência fixa de 10 itens faz o mesmo sem ramos |
| "O critério de fim cria o cartão com Good ou Again" | Pedagogia | A primeira resposta digitada já cria o cartão, como na Revisão |
| Pesos "fria/prática" e escolha de 4 × de 2; janela de 180 dias | Pedagogia | Um peso só (0,5 para escolha); o decaimento já esquece |
| Formatos R3 e R4; G8 (verbete conta como Não sei) | Pedagogia | Eram variantes da escolha de sentido, que saiu; o verbete some da pergunta |
| Alternância contrastiva na escolha da palavra | Pedagogia | O "membro errado da última vez" já traz o contraste que importa |
| Análise da próxima história; pré-ensino de palavras dela | Pedagogia | Pede classificar formas em tempo e pessoa na hora; v1.1 (D26) |
| Toque no Leitor antecipa o cartão | Pedagogia | Sinal ambíguo; obriga o Histórico a gravar a forma (D27) |
| Índice `occurrence` no `stories` | Pedagogia | Tabela nova no contrato que só serve às frases de contexto; v1.1 (D18) |
| Conjugação e preposição em frase | Pedagogia | Sem índice, só a frase salva serviria; v1.1 com o índice |
| Link do verbete (Flessione/Coniugazione) para o Treino | Pedagogia | Mexe em outro book; v1.1 |
| Textos de regra no app | Pedagogia | Ficam no `dict` (D14): o app não tem `switch` por padrão, e um erro se corrige num patch de conteúdo |
| Linha do porquê na pergunta | UX | Seria uma dica sem o teto de Hard (D17) |
| Chips por tema em Ajustes; ajuste por tempo (REV-04) | UX, book | Um caminho só: "Tirar da Revisão" no tema |
| "A Revisão só cobra temas treinados" | UX | Quem nunca abre o Treino nunca teria a parte mais fraca da gramática (D4) |
| Ajuste "Ler a resposta em voz alta" | UX | Sem pedido (D33) |

---

## 12. Decisões e pendências

### 12.1 Decisões tomadas

As 36 decisões e os desdobramentos estão em [revisao-treino-decisoes.md](revisao-treino-decisoes.md), que é a fonte da verdade. Resumo por área:

| Área | Decisões | O que ficou |
|---|---|---|
| Memória e FSRS | D1, D2, D2b, D25 | Cartão de padrão por regra; toda resposta no formato do cartão conta, como no Anki com FSRS-6; escolha de forma fora; só o FSRS para quem erra sempre |
| Palavra | D3, D12, D13, D27 | Só escrever; só a classe salva gera cartões; sem glosa, lacuna; toque no Leitor não agenda |
| Gramática | D4, D11, D11b–e, D15, D28, D32 | Só A1, pelos livros, com peso no *Dai! 1*; 30 padrões, 9 temas; 1 padrão novo por dia; Gênero e Artigo separados; passato remoto fora |
| Correção | D6, D20 | A nota mede só o alvo; dica limita a Hard |
| Sessão | D7, D8, D17, D21, D33 | 5 · 2 · 1, freio a 60, lotes de 20 (a confirmar na simulação); reforço de 3; porquê na resposta; 2 voltas; sem áudio automático |
| Treino | D9, D10, D16, D35 | Só cria cartões de padrão e de membros do aluno; estado só em texto; rodada de 10; lista na ordem do *Dai! 1* |
| Navegação | D5, D22, D29, D36 | 4ª aba Revisão/*Ripasso*, Treino/*Allenamento*; página do trecho; verbete da sessão no Histórico |
| Dados | D14, D18, D19, D23, D26, D30, D31 | Regras em `rules.toml`; índice e pré-ensino na v1.1; cadeia de fontes; linguagem com o pipeline; `localDay` às 4h; frase de história não lida do mesmo nível na v1.1 |
| Ajustes e adiados | D24, D34 | Imagens depois da v1; Ajustes com 3 itens |

### 12.2 Pendências

Cada uma vai ao dono do produto separadamente, com a recomendação.

**Abertas pelas decisões:**

| # | Pendência | Recomendação |
|---|---|---|
| D7 | Refazer a simulação de carga em FSRS-6 com o desenho decidido (9.3) | Fechar os números só depois dela |
| D19 | Confirmar a licença do Morph-it! (CC BY-SA 2.0 / LGPL) e medir quanto ele acrescenta depois do en.wiktionary | Medir antes de pôr no pipeline; se não acrescentar palavra de A1–B1, ficar só com as duas wikis |
| D11b | Aprovar o catálogo da seção 2 (30 padrões, ordem, membros) | Aprovar como está, com as pendências abaixo |
| D22 | Desenhar a página do trecho no book: mostra a tradução do parágrafo? Tocar numa palavra abre o verbete? Há "Abrir a história"? | Sem tradução, sem toque e sem link na v1: a página só lembra o contexto |
| D23 | Linguagem do pipeline | Decidir junto com o pipeline todo |

**Encontradas ao reescrever:**

| # | Pendência | Recomendação |
|---|---|---|
| 1 | A D2 diz "toda resposta **digitada**", mas o Gênero é escolha e é o formato do próprio cartão | Conta: a regra é "no formato do cartão" (6.4) |
| 2 | *amico* e *medico* no `pl.co_go`: exceção nomeada dentro do cartão de padrão (v1, D11c) ou cartão de palavra próprio (leitura literal da D1, "cartão de palavra só para exceções")? | Dentro do padrão: a dúvida *amici* × *amichi* é a decisão que a regra treina |
| 3 | "Frequente" (D11c, D11d) não tem fonte: vale para `gen.lista` e `gen.sufixo` | NVdB *fondamentale* |
| 4 | Combinações frequentes do `prep.art`: a pesquisa sugere *al, alla, allo, del, della, nel, nella, sul, dal* | As 5 preposições com *il, la, l', i, le*; *lo* e *gli* ficam para o A2 |
| 5 | Ordem de apresentação pela Revisão (D4): a "ordem do catálogo" é a do *Dai! 1* intercalando temas (coluna Ordem da 2.2) ou tema por tema? | Intercalando, pela unidade |
| 6 | Quando os membros de um padrão `lista` começam a entrar (*fatto* antes de o passato prossimo ser apresentado?) | Só depois que a Revisão chega à posição do padrão (5.2) |
| 7 | Ritmo: com 1 padrão por dia e o filtro de nível sem efeito (D32), o passato prossimo e o imperativo podem chegar já no 25º dia de Revisão, qualquer que seja a leitura | Aceitar na v1 e olhar com dados de uso; a alternativa é um ritmo menor que 1 por dia |
| 8 | O filtro de nível da D4 não tem efeito na v1 (D32) | Implementar só quando entrar A2 (um codepath a menos) |
| 9 | D19 marca a origem só do plural (`plural_src`). E gênero e conjugação vindos do en.wiktionary? | `gender_src` e `conj_src`, com os mesmos valores |
| 10 | Na divergência entre fontes (*uomo* → "donne" no it.wiktionary), que valor entra até o relatório ser revisto? | O membro fica fora do `drill` até um arquivo de correções resolver; o verbete fica como está |
| 11 | Pronominais sem tabela (*cuocersi*) podem herdar a do verbo base (*cuocere* + *si*)? É derivação, e a D19 diz "nada gerado por regra" | Não na v1; ficam sem conjugação |
| 12 | `imper.neg`: a resposta é *non* + infinito, a única forma do `drill` que não vem de dicionário | Aceitar: é a regra inteira, sem exceção |
| 13 | O imperativo vira o 5º tempo de `tense` (D11e). O verbete (DIC-05) passa a mostrar o imperativo? | Sim, para o aluno achar no verbete o que treina |
| 14 | Créditos (AJU-04): en.wiktionary e, se entrar, Morph-it! | Acrescentar |
| 15 | `pp.essere` sem cobrar concordância: terminação errada dá Certo com aviso ou Certo sem aviso? | Com aviso (G1): mostra sem cobrar |

---

## 13. Próximos passos

### 13.1 O que o book precisa desenhar

1. Raiz da aba Revisão, com os quatro estados do cartão do dia, a barra com 4 abas e os 9 temas.
2. Página do tema e página da regra (com e sem o botão "Treinar"; "Tirar da Revisão").
3. Gênero em 2 opções, nas três variantes de som.
4. Cartão de padrão digitado: Artigo, Presente, Plural, Preposição, Passato prossimo, Imperativo (com o negativo), com o rótulo da regra.
5. Cartões curados: Adjetivos, Possessivos (com e sem parentesco), Piacere (número e pronome).
6. Escrever a palavra: com glosa, com lacuna na frase e com lacuna na definição.
7. Resposta: Certo + aviso, Quase, Errado, Ambíguo (G5), escolha certa e errada; o desfazer na linha do veredito; a linha do porquê.
8. Apresentação de palavra nova, de regra nova e de padrão `lista`; escolha de forma (D) do Treino.
9. Bloco de reforço: a transição, com e sem a regra curta.
10. Contador "N de M · +K" em todos os estados; fim do lote com "Continuar".
11. Fim da Revisão e fim do Treino.
12. Aviso com Desfazer; página do trecho (D22).
13. Foco, ordem de leitura e textos acessíveis de cada tela; os textos PT e IT na tabela da Imersão (7.5).
14. Os pedidos ao brand lead (7.4).

### 13.2 O que a spec precisa ganhar

**Spec funcional**

| Id | Linha |
|---|---|
| NAV-01 · NAV-06 (mudam) | Quatro abas; tocar de novo em Revisão volta à raiz (D5) |
| REV-01 (muda) | O cartão "Revisão de hoje" mora na raiz da aba Revisão, com quatro estados |
| REV-02 (muda) | Novas: Salvas → NVdB por frequência; palavra sem glosa entra pelo `scrivere` com lacuna (D13) |
| REV-03 (muda) | Salvar torna o lema fonte só para a classe salva; remover tira da Revisão sem apagar respostas (D12) |
| REV-04 (muda) | Nove skills, cartão de palavra e cartão de padrão, catálogo de 30 padrões A1; sai o ajuste por tempo |
| REV-05 (muda) | "Já sei" com aviso e Desfazer |
| REV-06 (muda) | FSRS-6 como no Anki: toda resposta no formato do cartão atualiza S e D, curto prazo no mesmo dia, lapso só no 1º erro do dia; desbloqueio de forma depois do `scrivere` (D2, D3) |
| REV-07 (muda) | Correção pelas regras G1–G9 e pela tabela por skill |
| REV-09 (muda) | Dica também nos cartões de forma, limitada a Hard (D20) |
| REV-10 (muda) | Ordem da resposta; "A regra volta em…" no cartão de padrão |
| REV-11 (muda) | "Contar como certa" na linha do veredito |
| REV-13 (muda) | Mais opções muda entre pergunta e resposta |
| REV-14 (sai) | Imagens adiadas (D24) |
| REV-17 (muda) | Respostas num log só de inserções; o estado é calculado |
| REV-19 (muda) | Foco no veredito; nome acessível do campo |
| REV-20 (novo) | Limites: lote de 20, cotas 5 + 2 + 1, freio a 60 (D7) |
| REV-21 (novo) | Contador "N de M · +K" e até 2 voltas (D21) |
| REV-22 (novo) | Reforço: 1 bloco de 3 do padrão mais fraco por dia (D8) |
| REV-23 (novo) | Padrão novo pela Revisão: 1 por dia, na ordem do catálogo, com membro do aluno (D4) |
| REV-24 (novo) | Linha do porquê na resposta e no fim (D17) |
| REV-25 (novo) | Botão único Não sei/Conferir; teclado e Enter |
| REV-26 (novo) | "Na história" abre a página do trecho, sem o Leitor e sem tocar no progresso (D22) |
| TRE-01 | O Treino lista 9 temas numa lista só, na ordem do *Dai! 1*; cada tema lista as suas regras (D35) |
| TRE-02 | Treinar um tema inteiro ou uma regra só, em 2 ou 3 toques |
| TRE-03 | Rodada de 10 itens com a sequência fixa; erro volta 2 itens depois (D16) |
| TRE-04 | Itens: palavras do aluno, depois NVdB com a glosa visível |
| TRE-05 | Conta no FSRS como a Revisão; a escolha de forma não conta; só cria cartão de padrão e de membro do aluno; fora das cotas (D2, D2b, D9) |
| TRE-06 | Fim: contagens, erros e "A regra volta na Revisão em…" |
| TRE-07 | O ponto fraco aparece só em texto, na exceção, sem reordenar (D10) |
| TRE-08 | "Tirar da Revisão" / "Pôr na Revisão" na página do tema |
| TRE-09 | Sem gamificação (REV-16) |
| SAL-01 (muda) | Verbete aberto da sessão entra com origem "Revisão"; o dia vira às 4h (D29, D30) |
| AJU-07 (novo) | Ajustes › Revisão: os três itens da D34 |
| AJU-04 (muda, se aprovado) | Créditos do en.wiktionary e do Morph-it! (12.2) |
| DIC-05 (muda, se aprovado) | Conjugação com o imperativo como 5º tempo (12.2) |
| OFF-30 (muda) | Entram as respostas da Revisão e do Treino |

**Arquitetura** (ARQ-80…89 estão livres)

| Id | Linha |
|---|---|
| ARQ-80 | `answer` é só de inserções; correções e desfazer são linhas com `replaces` |
| ARQ-81 | O estado (FSRS, fraqueza, cotas, voltas) é uma dobra do log no isolate, mantida em memória |
| ARQ-82 | FSRS-6 como no Anki: toda resposta no formato do cartão atualiza S e D, com a fórmula de curto prazo no mesmo dia; lapso só no 1º erro do dia de um cartão em revisão; a escolha de forma não entra; fuzz com semente fixa |
| ARQ-83 | Cartão ativo é um filtro de consulta; o `user` anexa o `dict` só para leitura |
| ARQ-84 | Uma `localDay` com virada às 4h para Revisão e Histórico |
| ARQ-85 | `grade()` e `osa()`; o ARQ-66 passa a usar a OSA |
| ARQ-86 | Catálogo `rule` no `dict`, com ids só de acréscimo, `retired` e `position` na ordem do *Dai! 1* |
| ARQ-87 | `drill` como índice de pertinência por substantivo × skill, verbo × tempo e item curado (`cue`, `answer`) |
| ARQ-88 | Toda escolha da seleção e do gerador é determinística, por hash |
| ARQ-89 | Fraqueza por padrão: a fórmula da seção 4.1 |
| Seção 4 (muda) | `saved` com `pos`, `paragraph`, `sentence`, `form`; tabela `answer` com `cue` e `tense` 5 |
| Seção 9 (muda) | Pedidos ao conteúdo: campos de `entry.data` (com `plural_src` e o imperativo), `rule`, `drill`, itens curados em `rules.toml`, relatório de divergências |
| Seção 11 (muda) | "Revisão" sai das decisões em aberto |
| `dictionary.md` · `dictionary-pipeline.md` | Cadeia it.wiktionary → en.wiktionary → Morph-it!; normalização do acento tônico e do feminino plural; `raw_tags` da conjugação e o imperativo; etapa 5b; `rules.toml` com listas A1, lista de parentesco e itens curados; arquivo de exceções de artigo; relatório de divergências |
