# Postilla: spec de arquitetura

Como o app e o pipeline de conteúdo são construídos. O comportamento está na [spec funcional](functional-spec.md), e esta spec só diz como implementá-lo. Cada decisão tem um id (`ARQ-03`) e um motivo curto.

Documentos relacionados:
- [functional-spec.md](functional-spec.md): o que o app faz.
- [dictionary.md](dictionary.md): campos do verbete e transformações.
- [dictionary-pipeline.md](dictionary-pipeline.md): como o dicionário é gerado.

---

## 1. Visão geral

| Id | Decisão | Motivo |
|---|---|---|
| ARQ-01 | O app é feito em Flutter, para iOS e Android. | Uma base de código para as duas plataformas que a spec funcional pede. |
| ARQ-02 | O pipeline de conteúdo é escrito em Zig (0.17). SQLite e zstd entram como fontes C pelo `build.zig.zon`, com hash fixo. | O pipeline lê o JSONL do kaikki.org já extraído e não roda o wiktextract, então não depende de Python. Um binário só, sem runtime e sem dependência instalada na máquina (D23). |
| ARQ-03 | Dois repositórios: `postilla` (app Flutter e docs do app) e `postilla-content` (pipeline e fontes das histórias). `postilla-content` fica aninhado em `postilla/content/`, com git próprio, e o `.gitignore` do app o ignora. | App e conteúdo têm ciclos de release separados. O app recebe conteúdo novo sem versão nova na loja. |
| ARQ-04 | `postilla-content` é público. | Os pacotes ficam nas Releases dele, e o app baixa sem token. |
| ARQ-05 | Os pacotes de conteúdo são publicados como GitHub Releases de `postilla-content`. | Sem custo e no mesmo lugar do código que gera os pacotes. |
| ARQ-06 | A URL do manifesto embutida no app é `https://postilla.kaiodelphino.com/content/manifest.json`. O manifesto é servido pelo GitHub Pages de `postilla-content`, com esse domínio configurado, e as URLs dos pacotes dentro dele apontam direto para as Releases. | Trocar de host não exige versão nova do app: só a URL do manifesto fica embutida. Um domínio não aponta por CNAME para um arquivo de Release, então o manifesto fica no Pages. O `/content` deixa a raiz livre para um site do app. |
| ARQ-07 | `postilla-content` define o contrato entre os repositórios: esquema dos bancos de conteúdo e formato do manifesto. O app segue esse contrato. | Quem gera o dado documenta o formato. |
| ARQ-08 | [dictionary.md](dictionary.md) e [dictionary-pipeline.md](dictionary-pipeline.md) mudam para `postilla-content`. | A doc fica junto do código que ela descreve. |

```
postilla-content (público)                     postilla
  pipeline (Zig)                                 app (Flutter)
  fontes das histórias          Releases           conteúdo embutido
  contrato (esquema, manifesto) ─────────► manifesto ─► atualização (seção 3)
                                     domínio próprio
```

## 2. Pacotes de conteúdo

| Id | Decisão | Motivo |
|---|---|---|
| ARQ-10 | Dois pacotes, com versões independentes: `dict` (dicionário) e `stories` (histórias e traduções). | Uma história nova não baixa os ~15 MB do dicionário. |
| ARQ-11 | Cada pacote é um único arquivo SQLite comprimido com zstd -19 (`dict-2.1.0.db.zst`). Versão, fontes e licenças ficam na tabela `meta` do próprio banco. | zstd tem o melhor equilíbrio entre tamanho (~15 MB) e velocidade de descompressão. Um arquivo só simplifica download e verificação. |
| ARQ-12 | A versão de cada pacote é SemVer: major muda quando o esquema fica incompatível com apps antigos; minor, quando entra conteúdo novo (dump novo, histórias novas); patch, em correções pontuais (glosa errada, erro no texto). | O major diz ao app se ele consegue ler o pacote. |
| ARQ-13 | Cada build do app aceita um único major por pacote (ex.: `dict` 2.x, `stories` 1.x). Um pacote de outro major é ignorado, e o app continua com a versão que tem. | Regra simples, verificada sem consultar nada além da versão. |
| ARQ-14 | A versão inicial embutida (OFF-10) não fica no git. Um arquivo de lock no repo do app fixa versão e sha256 de cada pacote, e um script baixa os arquivos das Releases antes do `flutter build`. | Sem binários grandes no repositório do app. O lock deixa o build reproduzível. |
| ARQ-15 | Ajustes › Sobre (OFF-13) mostra a versão dos dois pacotes e a data do dump do Wiktionary, lida da `meta` do `dict`. | A data diz ao usuário de quando é o dicionário; o SemVer identifica o pacote num relato de erro. |

## 3. Atualização de conteúdo

Comportamento em OFF-20..24. Fluxo:

```
abrir o app ─► manifesto (≤ 1×/dia) ─► versão nova do major aceito? ─► baixar .zst (com retomada)
  ─► sha256 do .zst ─► descomprimir em preparação ─► sha256 do .db ─► pronto
próxima abertura ─► troca o ponteiro para a versão pronta ─► apaga a anterior
```

| Id | Decisão | Motivo |
|---|---|---|
| ARQ-20 | O manifesto é um JSON com só a última versão de cada pacote: versão, URL, tamanho, sha256 do `.zst` e sha256 do `.db`. | Formato mínimo. Um app de major antigo deixa de receber conteúdo até ser atualizado na loja (ARQ-13). |
| ARQ-21 | O manifesto não é assinado. A integridade vem do HTTPS e dos sha256. | O sha256 pega download corrompido. Proteger contra um manifesto trocado ficou fora da v1. |
| ARQ-22 | O download acontece só com o app aberto. Se for interrompido, a próxima abertura retoma de onde parou (HTTP Range). | Sem código nativo de download em segundo plano. A retomada evita baixar de novo os ~15 MB. |
| ARQ-23 | Logo após o download e a conferência do `.zst`, o app descomprime o pacote numa pasta de preparação e confere o sha256 do `.db`. Só então o pacote fica pronto. | A próxima abertura só troca um ponteiro, sem esperar descompressão. Custa ~90 MB a mais até a troca. |
| ARQ-24 | A troca (OFF-22, OFF-23) acontece na abertura seguinte, antes de abrir qualquer banco de conteúdo: o app aponta para a versão pronta e apaga a anterior na hora. | A troca é atômica e nunca acontece com história ou verbete aberto. Sem rollback. |
| ARQ-25 | Entre o conteúdo embutido numa versão nova do app e o já baixado, vale a maior versão do major que o app aceita. Se o app mudou de major, o baixado é apagado e vale o embutido. | Atualizar o app pela loja nunca faz o conteúdo voltar para uma versão mais antiga. |
| ARQ-26 | A `meta` do `stories` lista as histórias adicionadas em cada versão. Na troca, o app soma as adicionadas desde a versão que tinha e guarda o número para o aviso da Biblioteca (OFF-24). | O pacote diz o que é novo, sem o app guardar a lista de ids da versão anterior. |

## 4. Bancos no aparelho

Os bancos de OFF-34: `user` (dados do usuário), `stories`, `dict` e `log` (ARQ-70). O esquema de `stories` e `dict` é definido em `postilla-content` (ARQ-07).

| Id | Decisão | Motivo |
|---|---|---|
| ARQ-30 | O app acessa o SQLite pelo pacote `sqlite3` (FFI), com SQL escrito à mão. | Sem geração de código e sem camada entre o app e o SQL. |
| ARQ-31 | Todas as consultas, em todos os bancos, rodam num isolate dedicado. A UI recebe os resultados por mensagem. | O `sqlite3` é síncrono. Fora do isolate da UI, uma consulta lenta não trava a tela. |
| ARQ-32 | O esquema do `user` evolui por scripts SQL numerados (`001.sql`, `002.sql`…). `PRAGMA user_version` guarda o último aplicado, e cada script roda numa transação. Só para frente. | Migração explícita e fácil de revisar. |
| ARQ-33 | Todo registro do `user` tem `id` UUID v7, `created_at`, `updated_at` e `deleted_at`. As datas são inteiros em ms desde a epoch, em UTC. A `answer` tem as mesmas colunas, mas só recebe inserções: nela `updated_at` é sempre igual a `created_at`, e `deleted_at` é sempre 0 (ARQ-80). O dia local (`answer.day`, `history.day`) não é data em ms: é o `localDay` do ARQ-84. | Ids únicos entre aparelhos e datas comparáveis permitem sync futuro sem migração de modelo (OFF-31). |
| ARQ-34 | Remover uma palavra salva ou limpar o histórico preenche `deleted_at`, e as listas filtram essas linhas. Nenhum dos dois toca em `answer`: a palavra removida sai da Revisão pelo filtro do ARQ-83, e as respostas dela ficam no log (REV-03). | O sync futuro sabe o que foi removido. Remover não apaga o que o aluno já respondeu. |
| ARQ-35 | O `user` nunca aponta para o `entry.id`. Uma palavra salva é pelo lema, como texto (`"serranda"`), e guarda também a classe do verbete onde foi salva (`saved.pos`), que só decide quais cartões a salva gera (D12). O histórico aponta para o verbete por lema + classe (`"binario"`, `"sostantivo"`). As respostas apontam para lema + classe e para o `rule.id` (ARQ-86). | O `entry.id` muda a cada build do `dict`, e o lema sobrevive às versões. Fora do Leitor o app não conhece a forma tocada, então a salva é pelo lema. Salvar "binario" marca como salvos os dois verbetes de "binario" (substantivo e adjetivo), mas só a classe salva vira cartão (P05). O histórico tem uma linha por verbete (SAL-01), então guarda a classe. Um verbete que saiu do `dict` cai no OFF-32. |
| ARQ-36 | Cada história tem um UUID escrito na fonte, que nunca muda. Progresso, salvas e histórico apontam para esse UUID. | Renomear ou corrigir a história não quebra o vínculo. |
| ARQ-37 | O progresso aponta para o parágrafo pela posição. Se a história encolher, o progresso vai para o último parágrafo que existe (OFF-32). O deslocamento dentro do parágrafo (LEI-07) é o índice do primeiro caractere visível. | Posição é o mais simples. O índice de caractere sobrevive a mudanças de tamanho do texto e rotação. Uma edição no meio da história desloca o progresso, e isso foi aceito. |
| ARQ-38 | Os ajustes ficam numa tabela chave-valor do `user`. Os temas tirados da Revisão também são ajuste, não coluna de cartão (ARQ-83). | Entram no Exportar/Importar (AJU-05) e no sync futuro. |
| ARQ-39 | `dict` e `stories` são abertos só para leitura (`mode=ro&immutable=1`). | Sem WAL nem lock, e nenhuma escrita acidental no conteúdo. |

Tabelas do `user` (além das colunas do ARQ-33):

| Tabela | Campos | Requisitos |
|---|---|---|
| `progress` | `story_id`, `paragraph` (posição), `offset` (caractere), `status` (andamento \| lida), `last_opened_at`. Sem linha, a história é nova. | BIB-02, BIB-03, LEI-07 |
| `history` | `day` (`localDay`, virada às 4h, ARQ-84), `lemma`, `pos`, `story_id` (`''` fora de história), `origin` (0 história ou busca · 1 Revisão; em aberto, seção 12). Única por `day` + `lemma` + `pos`. | SAL-01, D29, D30 |
| `saved` | `lemma` (texto, chave única), `pos` (classe do verbete onde salvou: só ela gera cartões, D12), resumo (classe, história de origem), `story_id`, `paragraph` e `sentence` (posições da frase de origem; também abrem a página do trecho, D22), `form` (forma tocada; `''` = sem frase de origem, como na salva pela busca). | SAL-02, OFF-32, LEI-10, REV-03 |
| `answer` | O log de respostas da Revisão e do Treino, só de inserções (ARQ-80). Colunas na tabela abaixo. | REV-17, TRE-05 |
| `setting` | `key`, `value` (JSON): leitura, Imersão, proporção da tradução, ordenação das Salvas, dicas vistas, aviso de histórias novas, Ajustes › Revisão (palavras novas por dia, origem) e temas tirados da Revisão. | OFF-30, ARQ-26, AJU-07 |

Colunas de `answer`, além das do ARQ-33. Toda coluna é `NOT NULL`, e o zero (`0` ou `''`) quer dizer "não há".

| Coluna | O que guarda |
|---|---|
| `at` | Instante da resposta (ms, UTC), o que vale para o FSRS. Uma linha com `replaces` herda o `at` da substituída (seção 12) |
| `day` | `localDay` da resposta (ARQ-84): `20261016` |
| `replaces` | Id da linha que esta substitui (ARQ-80) |
| `kind` | 0 cartão de palavra · 1 cartão de padrão |
| `rule` | `kind` 1: o cartão; `kind` 0: o padrão do membro; `''` na Palavra |
| `lemma`, `pos` | `kind` 0: a palavra do cartão; `kind` 1: a palavra da vez |
| `skill`, `tense`, `person` | Enums fixos do ARQ-86. `tense`: 1 presente · 2 passato_prossimo · 3 imperfetto · 4 futuro · 5 imperativo |
| `cue` | Item curado: a pergunta da linha do `drill` (`le chiavi ___`) |
| `format` | 0 digitado · 1 escolha |
| `verdict` | 1 intro · 2 known · 3 void · 4 wrong · 5 dontKnow · 6 almost · 7 ok |
| `reason`, `hinted` | Motivo do aviso, do Quase ou do Errado; se usou a dica |
| `mode` | 1 Revisão · 2 Treino. Só para as cotas e para auditoria: nenhuma regra do FSRS olha a porta |
| `origin` | Só na `intro` de palavra: 1 salvas · 2 NVdB |
| `typed`, `elapsed_ms` | O que foi digitado (até 64 caracteres) e o tempo até responder |

- **Chave do cartão:** `kind` 1 → `rule`; `kind` 0 → `lemma·pos·skill·tense`. Em Dart, um `extension type CardKey` (ARQ-47). O `cue` não entra na chave.
- **Índices:** `(kind, rule, lemma, pos, skill, tense, at)` para a dobra por cartão, `(day)` para as cotas e `(replaces)` parcial, só onde não é `''`.
- **Tamanho:** com 100 respostas por dia, ~36 mil linhas e ~3,5 MB por ano (seção 12).
- O book da Revisão previa `review_card`, `review_log`, `known_word` e `word_image`. Nenhuma entra: o estado sai do log (ARQ-81), "Já sei" é uma linha `known` e as imagens ficaram para depois da v1 (D24).

## 5. App Flutter

O código do app e do pipeline segue os Core Principles do [AGENTS.md](../AGENTS.md). As convenções de nome de lá não valem aqui (ARQ-95). As decisões abaixo dizem como alguns deles viram escolhas concretas.

| Id | Decisão | Motivo |
|---|---|---|
| ARQ-40 | Não há camadas entre a tela e o SQL. O módulo `db` tem uma função por consulta (`dbSavedList`, `dbProgressSet`…), que manda o SQL ao isolate (ARQ-31) e devolve structs. A tela chama essas funções direto. Não há repository, use case nem interface. | Menos código e menos conceitos. Dá para seguir uma ação da tela até o SQL no debugger. |
| ARQ-41 | O estado de cada tela fica no `State` do próprio `StatefulWidget`. Uma classe de estado separada só aparece onde dividir estado entre telas for necessário, caso a caso. | O Flutter já dá o `State`, então nenhum conceito novo por tela. |
| ARQ-42 | Os ajustes que valem para o app todo (tema, leitura, Imersão) ficam num struct imutável `Settings`, num `ValueNotifier<Settings>` na raiz, exposto por `InheritedNotifier`. Mudar um ajuste grava no `db` e troca o valor. | Um estado global só, com o que o Flutter já tem. Tema e Imersão mudam na hora (LEI-08, AJU-03). |
| ARQ-43 | Depois de desempilhar uma tela, a tela que ficou embaixo relê as salvas (`await` do push). Não há conjunto de salvas global. | Uma consulta indexada resolve o SAL-05, sem estado compartilhado para manter igual ao banco. |
| ARQ-44 | A navegação é feita à mão: um `IndexedStack` com um `Navigator` por aba, e o `Navigator` raiz para o Leitor, o verbete do Leitor e a sessão de Revisão ou Treino em tela cheia. O voltar do Android passa pelo `NavigatorPopHandler`. | Sem pacote e sem tabela de rotas. O push leva direto ao widget, com argumentos tipados. O app não tem deep links. |
| ARQ-45 | Uma pasta por tela (`library/`, `reader/`, `dictionary/`, `review/`, `settings/`), mais `db/` e `ui/` (componentes do design system). A Revisão e o Treino dividem `review/`, porque usam o mesmo gerador e a mesma correção. | Quem mexe numa tela acha tudo dela numa pasta só. |
| ARQ-46 | Os textos de interface seguem o padrão abstract class + uma classe por língua + global trocável, com uma classe por área da Imersão que tem texto: `NavStrings nav`, `UiStrings ui` e `DictStrings dict`, cada uma com versão `Portuguese` e `Italian`. Quando a Imersão muda, o app troca os globais e então notifica o `ValueNotifier<Settings>`. A área Glosas não tem texto: ela só decide se a glosa aparece. Nomes e textos das regras não são classe: vêm do `dict` em PT e IT (`rule.name_*`, `rule.text_*`), e o app escolhe a coluna pela área Rótulos e botões (D14). | Sem geração de código. O compilador impede usar um texto da área errada. |
| ARQ-47 | Ids e unidades têm tipos distintos, feitos com `extension type` (`StoryId`, `ParagraphIndex`, `CharOffset`, `WordKey`…). | O compilador impede misturar um `StoryId` com uma `String` qualquer, sem alocação em runtime. |
| ARQ-48 | A linha do SQLite e o JSON do verbete (`entry.data`) viram struct no isolate do banco, que manda os structs prontos para a UI. | Parse na borda: a UI nunca vê linha crua nem JSON, e o parse do verbete não pesa no isolate da UI. |
| ARQ-49 | Uma função do `db` nunca devolve `null` nem lança exceção. Se não acha nada ou falha, devolve o valor zero: um sentinela const (`Story.nil`, `Entry.nil`) ou uma lista vazia. A falha vai para o log (ARQ-70). | Quem chama tem um caminho só, sem `if (x == null)` nem `try/catch` na tela. |

```
Navigator raiz
 ├─ Shell: IndexedStack + barra de abas
 │   ├─ Navigator Biblioteca
 │   ├─ Navigator Dicionário   (verbetes da aba, até 20, DIC-06)
 │   ├─ Navigator Revisão      (raiz → tema → regra, D5)
 │   └─ Navigator Ajustes
 ├─ Leitor                     (push no raiz, sem barra)
 ├─ Verbete do Leitor          (push no raiz, sem barra)
 └─ Sessão (Revisão ou Treino) (push no raiz, sem barra)
     ├─ Verbete da sessão      (entra no Histórico com origem Revisão, D29)
     ├─ Regra da sessão        (sem "Treinar")
     └─ Trecho da história     (só o parágrafo, sem o Leitor; não grava progresso, D22)
```

```dart
NavStrings  nav  = NavPortuguese();
UiStrings   ui   = UiPortuguese();
DictStrings dict = DictPortuguese();

Text(nav.library)
Text(dict.synonyms)   // Sinonimi | Sinônimos
```

## 6. Leitor

| Id | Decisão | Motivo |
|---|---|---|
| ARQ-50 | O pipeline divide o texto em palavras e frases e grava no `stories`, por parágrafo, o início e o fim de cada palavra e de cada frase, em italiano e em português. Elisões (l'aria, c'è) são uma palavra só. O app só lê esses spans. | Um tokenizador só, no pipeline, testado no build. As contagens de palavras do LEI-07 e os pares de frase do TRA-08 saem prontos. |
| ARQ-51 | Cada parágrafo é um `RenderBox` próprio com um `TextPainter`. Ele faz o layout, guarda o retângulo de cada palavra num array, resolve o toque e o arrasto da seleção pelo retângulo mais próximo (caixa ampliada), pinta grifo, frase marcada e pontilhado, e cria um nó de semântica por palavra. | O Leitor é o centro do app: o que importa fica grande e num lugar só. Sem widget nem recognizer por palavra, e a semântica fica sob controle (ACE-03, ACE-04). |
| ARQ-52 | Todos os parágrafos fazem layout ao abrir a história, numa coluna não preguiçosa. O topo de cada parágrafo fica num array. | Com histórias de até ~2.000 palavras, o custo é aceitável. Progresso (LEI-07), restaurar a posição (ARQ-37) e sincronizar a tela dividida (TRA-07) viram busca binária nesse array. |
| ARQ-53 | Ao abrir a história, o app resolve em lote forma → lema: uma consulta no `dict` com as formas distintas da história. Os lemas ficam num array paralelo aos spans de palavra e servem ao toque (LEI-02) e ao pontilhado (SAL-05). | Uma consulta só por história. O `stories` não depende da versão do `dict`, e o conteúdo continua sem anotação de lema (LEI-02). |
| ARQ-54 | Uma palavra ganha pontilhado quando qualquer um dos lemas da forma está salvo. Com "serranda" salva, "serrande" é pontilhada. Com "portare" salvo, todo "porta" do texto é pontilhado, mesmo quando é o substantivo. | Sem anotação de lema, o app não sabe o sentido da palavra no texto. A regra nunca deixa de pontilhar uma palavra salva, e aceita pontilhar a mais nas formas ambíguas. |
| ARQ-55 | O progresso é gravado quando a rolagem para, ao empilhar um verbete e quando o app vai para segundo plano. | Poucas escritas e nenhuma durante o gesto. Cobre o LEI-07, inclusive o sistema encerrar o app com um verbete aberto. |
| ARQ-56 | Na tela dividida (TRA-07), a metade que lidera informa o parágrafo do topo e a fração dele já rolada. A outra metade rola para o mesmo parágrafo e a mesma fração. | Acompanha suave dentro do parágrafo, mesmo com italiano e português de alturas diferentes. |

## 7. Dicionário

| Id | Decisão | Motivo |
|---|---|---|
| ARQ-60 | O toque procura só a palavra tocada. Em "si siede", tocar em "siede" abre *sedere*. *sedersi* abre pela expressão (pressionar e arrastar sobre "si siede", LEI-03) ou pela busca. | Uma regra só para o toque, sem olhar a palavra vizinha. |
| ARQ-61 | Uma elisão é procurada primeiro inteira e depois só a parte após o apóstrofo. "c'è" acha a locução, se o `dict` tiver, e senão vai para "è" → *essere*. "l'aria" não existe inteira e vai para "aria". | Acha locuções com elisão quando existem e cai na palavra principal quando não. Tudo no lote do ARQ-53. |
| ARQ-62 | Uma forma é procurada como está escrita e, sem resultado, em minúsculas. "Bologna" acha o nome próprio, e "Il" no início da frase vai para "il". Se as duas existirem ("Rosa" e "rosa"), vale a escrita exata. | Nomes próprios do `dict` têm maiúscula, e a palavra no início da frase também. |
| ARQ-63 | A busca (DIC-11) ignora acento e maiúscula: "citta" acha "città". O `dict` tem uma coluna normalizada (minúscula, sem acento), com índice, em `entry.word` e em `form.form`. A busca consulta as duas tabelas e junta os resultados. | O teclado em português nem sempre tem à e ù à mão. |
| ARQ-64 | As sugestões vêm nesta ordem: igual ao digitado, depois por frequência (NVdB: fondamentale → alto uso → alta disponibilità → resto), depois alfabética. O `dict` grava em cada `entry` esse rank e a faixa do NVdB (0 fora · 1 fondamentale · 2 alto uso · 3 alta disponibilità). | "casa" e "caso" sobem antes de "casella". A Revisão usa a faixa para saber o que é "das mais comuns" e o rank para a ordem das palavras novas do NVdB (D26); o Treino, para as palavras de fora do aluno. O rank sozinho não diz onde o NVdB acaba. |
| ARQ-65 | Os curingas (`?` uma letra, `*` várias) viram um `GLOB` sobre a coluna normalizada. | O `GLOB` do SQLite já usa esses dois curingas. |
| ARQ-66 | O "Você quis dizer" usa uma trie dos lemas normalizados, percorrida com as linhas da distância OSA (`osa()`, ARQ-85: Levenshtein em que trocar duas letras vizinhas conta 1 edição) e podada acima de 2 edições. A OSA guarda a linha anterior e a de antes dela. Os candidatos são ordenados por distância e depois pelo rank do ARQ-64. A trie é montada no isolate do banco no primeiro uso e fica em memória até o app fechar. | Sem dado novo no `dict` e sem extensão no SQLite. Pega até dois erros em qualquer posição, e *finsetrino* para *finestrino* conta um erro só. Uma distância só no app, a mesma da correção. Abrir o app não paga a montagem. |

O `dict` atual não tem a coluna normalizada (ARQ-63), o rank e a faixa do NVdB (ARQ-64), os traços de treino em `entry.data` nem as tabelas `rule` e `drill` (ARQ-86, ARQ-87). Todos são pedidos de mudança no contrato de `postilla-content` (ARQ-07), listados na seção 10.

## 8. Integrações do sistema

### Diagnóstico

| Id | Decisão | Motivo |
|---|---|---|
| ARQ-70 | O log do app (`appLog`) é gravado num quarto banco, `log`, separado do `user`. Ele não entra no Exportar/Importar (AJU-05) nem no backup do sistema. | Um `user` corrompido não leva o log junto, e o log não se mistura aos dados do usuário. |
| ARQ-71 | O `log` guarda os últimos 30 dias. As linhas mais antigas são apagadas ao gravar. | Cobre o intervalo comum entre um problema e o usuário decidir relatar. |
| ARQ-72 | O log só sai do aparelho se o usuário enviar: Ajustes › Sobre › Enviar diagnóstico (AJU-06) abre o e-mail do sistema com o `log` anexado. | Sem telemetria (OFF-03). O usuário vê o e-mail antes de enviar. |

### Sistema

| Id | Decisão | Motivo |
|---|---|---|
| ARQ-73 | Tudo que o app pede ao sistema passa por um platform channel próprio, em Swift e Kotlin: TTS, e-mail, folha de compartilhar e seletor de arquivos. Sem pacotes de plugin. | Um mecanismo só para o sistema, sem dependências, e cada chamada nativa fica visível no código. |
| ARQ-74 | A pronúncia (OFF-40) usa `AVSpeechSynthesizer` no iOS e `TextToSpeech` no Android, com voz `it-IT`. O canal lista as vozes com a marca de offline de cada sistema. Sem voz italiana offline, o botão fica desativado (OFF-41). | A voz do sistema funciona sem rede. |
| ARQ-75 | O e-mail do Relatar erro (LEI-09) e do Enviar diagnóstico (AJU-06) abre pelo canal: `MFMailComposeViewController` no iOS e `Intent.ACTION_SEND` com anexo por `FileProvider` no Android. No iOS sem conta no app Mail, o app avisa que precisa de um app de e-mail configurado. | Um link `mailto:` não anexa arquivo, e o diagnóstico precisa do anexo. Um mecanismo só para os dois e-mails. |
| ARQ-76 | O arquivo exportado (AJU-05) e o anexo do diagnóstico (ARQ-72) são gerados com `VACUUM INTO` num arquivo temporário, apagado depois de compartilhar. | Cópia consistente e compacta com o banco aberto, sem WAL pendente nem linhas apagadas. |
| ARQ-77 | O `user` grava um `PRAGMA application_id` fixo do Postilla. Ao importar, o app abre o arquivo só para leitura, confere o id, aceita `user_version` menor ou igual ao seu e roda as migrações que faltam (ARQ-32). Um arquivo de um app mais novo é recusado com aviso. | Recusa qualquer SQLite que não seja do Postilla e aceita exportações de versões antigas. |
| ARQ-78 | Antes de importar, o app guarda uma cópia do `user` atual (`VACUUM INTO`) na pasta do app. Fica só a última, substituída a cada importação. Desfazer troca o `user` por ela. | Cobre o desfazer do AJU-05 sem o espaço crescer. |
| ARQ-79 | Só o `user` entra no backup do sistema (OFF-33). `dict`, `stories`, a pasta de preparação, o `log` e a cópia de desfazer ficam fora (`NSURLIsExcludedFromBackupKey` no iOS, regras de backup no Android). | O conteúdo volta do pacote embutido, e o iCloud do usuário não recebe ~90 MB. O Auto Backup do Android tem limite de 25 MB. |

## 9. Revisão e Treino

Comportamento nos requisitos `REV-` e `TRE-` da spec funcional, a partir da [proposta de Revisão e Treino](propostas/revisao-treino.md) e das [decisões](propostas/revisao-treino-decisoes.md) (citadas como **Dn**). Um log, uma dobra, um gerador, uma correção e duas portas: na Revisão o app escolhe os cartões; no Treino, o aluno escolhe o tema.

```
dict (só leitura)                       user
  entry.data: artigo, plural, conj        saved ── lema + classe + frase de origem
  rule: catálogo de padrões               answer ── log só de inserções
  drill: membros e itens curados             │
     │                                       ▼
     └──► gerador de exercício ◄──── dobra do log no isolate (FSRS, fraqueza, cotas, voltas)
                  │
        porta Revisão · porta Treino
                  │
            grade() ─► INSERT em answer
```

| Id | Decisão | Motivo |
|---|---|---|
| ARQ-80 | As respostas ficam na tabela `answer` do `user`, só de inserções: nenhuma linha muda nem é apagada. "Contar como certa" grava `ok`, "Desfazer" grava `void` e "Já sei" grava `known` (desfeito por um `void`). A linha que corrige ou desfaz outra aponta para ela em `replaces` e herda o `at` e o `day` dela (seção 12). Uma linha é efetiva quando nenhuma linha efetiva a substitui: lido do mais novo para o mais antigo, um `void` anula a linha que substitui, e a anterior volta a valer. Pular e Ambíguo (G5) não gravam nada. | P08, P09. O log é a fonte da verdade, e o sync futuro só soma linhas, sem conflito de linha editada (OFF-31). Desfazer é um caso só: mais uma linha. |
| ARQ-81 | O estado é uma dobra do log, feita no isolate do banco (ARQ-31) e mantida em memória: estado FSRS de cada cartão (S, D, lapsos, vencimento), fraqueza de cada padrão (ARQ-89), cotas do dia, fila de voltas, palavras apresentadas e "Já sei". A dobra lê as linhas efetivas em ordem `(at, id)` ao abrir a Revisão ou o Treino. Uma resposta nova é aplicada só ao cartão dela; uma que substitui outra refaz o cartão a partir das linhas dele. Nada da dobra é gravado. | P08. Sem coluna mutável para manter igual ao log. Mudar o algoritmo ou a tabela de notas recalcula tudo, sem migração. A fila de voltas sai do log e sobrevive ao encerramento do app. Custo estimado em dezenas de ms, ~0,3 s com 5 anos de uso, a medir (seção 12). |
| ARQ-82 | O agendamento é o FSRS-6 (21 parâmetros) como no Anki. Toda resposta efetiva no formato do próprio cartão, de qualquer porta (Revisão, voltas, reforço, Treino), atualiza S e D: a primeira do dia é uma revisão normal, com os dias reais desde a anterior (antecipada, se o cartão não estava vencido); as outras do mesmo dia usam a fórmula de curto prazo do FSRS-6. A primeira resposta contada cria o cartão, com S e D iniciais (D9). O contador de lapsos sobe só no primeiro Again do dia de um cartão em revisão. O formato do cartão sai do `skill` (escolha no `genere`, digitado nos outros); a escolha de forma do Treino não entra (D2b), nem `intro`, `known` e `void`. A nota sai de `(verdict, reason, hinted, format)` por uma tabela no código. O intervalo é em dias inteiros, no mínimo 1, com o fuzz do Anki numa semente fixa (ARQ-88). | D2, D2b. Uma regra só, sem `if` por porta. Igual ao Anki, o comportamento é conhecido e dá para conferir contra a implementação de referência. A nota não é gravada, então mudar a tabela não pede migração. |
| ARQ-83 | Cartão ativo é um filtro, nunca uma coluna. Um cartão é ativo quando a fonte existe (palavra salva com `deleted_at = 0` e o `pos` do cartão, ou palavra do NVdB apresentada pela Revisão; padrão com alguma resposta e `rule.retired = 0`), o cartão existe no `dict` (`entry` ou linha de `drill`), o lema não está em "Já sei", o tema não foi tirado da Revisão (`setting`) e, só na porta Revisão, o cartão está desbloqueado. O `user` anexa o `dict` só para leitura (`ATTACH 'file:…?mode=ro&immutable=1'`) para juntar `saved` e `drill` numa consulta; o resto vem da dobra. | Suspender, remover e tirar tema não editam nem apagam resposta (OFF-34, REV-03). Um verbete ou padrão que sai do `dict` some da Revisão sozinho, como no OFF-32. Uma palavra do NVdB respondida só no Treino não passa na fonte e nunca vence na Revisão (D9). |
| ARQ-84 | Um dia só, o `localDay`: a data local do aparelho com a virada às 4h, como inteiro `AAAAMMDD` (`20261016`). Vale para `answer.day`, `history.day`, as cotas, o "mesmo dia" do FSRS e o vencimento (vencido = `due ≤ hoje`). É gravado no momento da linha e nunca recalculado: mudar de fuso não move respostas antigas. | D30. É a virada padrão do Anki: quem revisa à meia-noite não ganha um dia novo no meio da sessão. Um conceito de dia, não dois. |
| ARQ-85 | A correção é uma função só, `grade()`, nas duas portas: recebe o exercício e o que foi digitado ou tocado e devolve `verdict` e `reason`, pelas regras G1–G9 e pela tabela por skill da proposta. Ela roda no isolate do banco, porque o G2 e o G5 procuram o digitado no `dict` (forma → lema → glosa) e o G4 compara pela coluna normalizada (ARQ-63). A "uma letra diferente" do G6 é medida por `osa()`, a distância OSA, que o ARQ-66 também passa a usar. | Um gerador e uma correção para Revisão e Treino. Uma distância só no app: *finsetrino* é um erro, não dois. |
| ARQ-86 | O catálogo de padrões é a tabela `rule` do `dict`, gerada de `rules.toml` em `postilla-content` (D14). O `rule.id` (`pl.co_go`) é a chave do cartão de padrão: só de acréscimo, nunca renomeado nem removido. Um padrão que sai ganha `retired = 1`; um padrão dividido ganha ids novos, e o histórico recomeça neles. `position` é a ordem do *Dai! 1* em que a Revisão apresenta os padrões (D4) e a ordem dentro do tema. Os enums `skill`, `tense` (com o imperativo como 5) e `person` têm valores fixos depois da v1, com nomes em italiano, e só ganham acréscimos. | D1: renomear um id apagaria o histórico do aluno. O texto de uma regra se corrige num patch de conteúdo, sem versão nova do app e sem `switch` por padrão no código. |
| ARQ-87 | O `drill` é o índice de pertinência: uma linha por substantivo × skill (`genere`, `articolo`, `plurale`, `preposizione`), por verbo × tempo (mais uma de `imper.neg`) e por item curado, cada uma com o seu `rule`. Nos itens curados (`accordo`, `possessivo`, `piacere`), a linha traz a pergunta (`cue`) e a resposta (`answer`); nos outros, a resposta sai de `entry.data` (`plural`, `article*`, `conj`). O `user` nunca guarda `drill.entry_id` (ARQ-35): o cartão é `lemma·pos·skill·tense` ou o `rule.id`. | O gerador tem um caso por skill e lê os curados da própria linha. O app não decide quem é membro de qual padrão: o pipeline classifica uma vez, no build (seção 10). |
| ARQ-88 | Nenhuma escolha da seleção ou do gerador usa `Random`. Desempates do lote, palavra da vez, pessoa pedida, ordem das opções nas escolhas e sorteio ponderado do Treino saem de `fnv1a32` sobre a chave do cartão e o `localDay` (mais a posição do item, no Treino). O fuzz do FSRS usa `fnv1a32(cartão + reps)`. | O estado e o lote são função do log e do dia: o mesmo log no mesmo dia dá sempre o mesmo lote. Os testes (ARQ-90, ARQ-93) ficam reproduzíveis sem semente injetada. |
| ARQ-89 | A fraqueza de cada padrão é calculada na mesma dobra, pela fórmula abaixo. O alvo de um padrão são as respostas do cartão de padrão (`regra`) ou dos cartões dos membros (`lista`), de qualquer porta, inclusive a escolha de forma, com peso 0,5 (D2b). Vocabulário não tem fraqueza na v1 (D25). | A retenção do FSRS diz se o aluno lembra agora; a fraqueza diz quanto ele acerta. Um padrão revisado ontem tem retenção alta mesmo errando metade. Os limiares são premissas, a ajustar depois da simulação (seção 12). |

```
para cada resposta efetiva com nota cujo alvo é o padrão p:
  w   = 0,5 ^ (idade_dias / 30)              -- idade em localDay; meia-vida de 30 dias
        × (0,5 se for escolha, 1 se for digitada)
  bad += w   se Again (Errado, Não sei)
  ok  += w   se Good ou Hard
  n   += 1

fraqueza(p) = (bad + 1) / (ok + bad + 4)      -- prior Beta(1, 3): 25% de erro sem dado
fraco(p)    = n >= 5  e  fraqueza(p) >= 0,35
mais fraco  = o fraco de maior fraqueza; desempate pela menor retenção do FSRS, depois pelo id
```

## 10. Pipeline

O pipeline, o formato-fonte das histórias e o contrato ficam em `postilla-content` (ARQ-07, ARQ-08). Esta seção só lista o que o app exige do conteúdo, com a decisão que pede cada item.

| Onde | O app exige | Pedido por |
|---|---|---|
| Pacotes | Um arquivo SQLite por pacote, comprimido com zstd -19 | ARQ-11 |
| Pacotes | Versão SemVer, com major = esquema incompatível | ARQ-12 |
| Manifesto | JSON com a última versão de cada pacote: versão, URL, tamanho, sha256 do `.zst` e sha256 do `.db` | ARQ-20 |
| `stories` | UUID fixo por história | ARQ-36 |
| `stories` | Título, subtítulo, nível, gênero, duração, obra e posição na obra | BIB-01, LEI-10 |
| `stories` | Nome de cada gênero em português e em italiano. O card, os filtros e a busca da Biblioteca (BIB-06) usam a língua da área Navegação da Imersão | AJU-02, BIB-05 |
| `stories` | Por parágrafo: texto em italiano e em português, spans de palavra e de frase nos dois, frases alinhadas 1:1 | ARQ-50, TRA-08 |
| `stories` | Contagem de palavras por parágrafo | ARQ-50, LEI-07 |
| `stories` | `meta` com as histórias adicionadas em cada versão | ARQ-26 |
| `dict` | `meta` com versão e data do dump do Wiktionary | ARQ-15 |
| `dict` | `entry.word` e `form.form` com a grafia original (maiúsculas e acentos) | ARQ-62 |
| `dict` | Coluna normalizada (minúscula, sem acento), com índice, em `entry.word` e em `form.form` | ARQ-63 |
| `dict` | Rank de frequência por `entry` (NVdB) | ARQ-64 |
| `dict` | Formas com clítico em `form` ("si siede" → *sedersi*) | ARQ-60, DIC-01 |
| `dict` | Faixa do NVdB por `entry` (0 fora · 1 fondamentale · 2 alto uso · 3 alta disponibilità) | ARQ-64, REV-02 |
| `dict` | Em `entry.data` dos substantivos: `gender`, `article`, `article_indef`, `article_pl`, `plural` (lista; invariável = a própria palavra) e `plural_src` (`wikt` · `enwikt` · `morphit`). Nada gerado por regra: sem fonte, o campo fica vazio. O artigo sai do gênero e do som inicial, com arquivo de exceções | ARQ-87, D15, D19 |
| `dict` | Em `entry.data` dos verbos: `conj_class` (`group`, `isc`, `pronominal`, `aux`) e `conj` plano (`tense`, `person`, `forms`), com o imperativo como `tense` 5 | ARQ-87, D11e |
| `dict` | Tabela `rule`, gerada de `rules.toml`: `id` só de acréscimo, `skill`, `type` (regra · lista), `level`, `position`, `neighbor`, `name_pt/it`, `text_pt/it`, `examples` (linhas "lema certo errado") e `retired` | ARQ-86, D1, D14 |
| `dict` | Tabela `drill`: `entry_id`, `skill`, `tense`, `rule`, e `cue` e `answer` nos itens curados. Membros cortados pelas listas A1 do `rules.toml` | ARQ-87, D11c |
| `dict` | Itens curados de `accordo`, `possessivo` e `piacere` e a lista de parentesco do `poss.famiglia`, escritos em `rules.toml` e conferidos contra o dicionário (gênero, número, forma do adjetivo) | ARQ-87, D11e |
| `dict` | `meta` com licença e atribuição das fontes novas (en.wiktionary para os traços; Morph-it!, se entrar) | AJU-04, D19 |
| Pipeline | Relatório de divergências entre as fontes a cada build, fora do pacote, para revisão à mão | D19 |
| Pipeline | O build falha se um `rule.id` da versão publicada anterior sumir do `rules.toml` | ARQ-86 |

## 11. Build, CI e testes

| Id | Decisão | Motivo |
|---|---|---|
| ARQ-90 | Os testes são de integração: começam pela UI (`flutter_test`, dirigindo os widgets) e usam SQLite real, um arquivo temporário por teste. Só as chamadas HTTP e os erros de IO são simulados. | Testa o app como ele roda, sem mock de camada interna, já que não há camadas (ARQ-40). |
| ARQ-91 | Teste unitário só para lógica pesada (ordenação da Biblioteca, trie do ARQ-66, `grade()` e `osa()`, FSRS-6 e a dobra do log, e afins). Cada uma também ganha um teste de integração que passa por ela. | O unitário cobre os casos difíceis da lógica. O de integração confere que ela funciona ligada ao resto. |
| ARQ-92 | Por enquanto não há teste ponta a ponta no aparelho (`integration_test`). | Rodar emulador ou aparelho no CI é lento e caro para a v1. |
| ARQ-93 | Os testes usam os mesmos `dict` e `stories` de produção, nas versões fixadas pelo lock do build (ARQ-14). Não há banco de conteúdo de teste. Atualizar o lock roda os testes contra o conteúdo novo, e o bump só entra com os testes passando. | Mockar o mínimo possível. O teste vê exatamente o dado que o usuário vê. |
| ARQ-94 | O CI do app roda no GitHub Actions, em Linux, a cada push e PR: baixa os pacotes do lock, roda `dart analyze` e `flutter test`. Build de loja fica fora do CI por enquanto. | Pega erro de análise e teste antes do merge, sem runner macOS. |
| ARQ-95 | O analisador usa o `flutter_lints` padrão, sem ajustes. Os nomes seguem o estilo Dart. | Sem regras próprias para manter. |

## 12. Decisões em aberto

A Revisão saiu daqui: a arquitetura dela está na seção 9 (ARQ-80…89). Ficam as pendências técnicas dela, da seção 12.2 da [proposta](propostas/revisao-treino.md), e as que apareceram ao escrever a seção 9. As pendências do conteúdo (fontes, divergências, licença do Morph-it!) estão nas decisões em aberto do [dictionary-pipeline.md](dictionary-pipeline.md#decisões-em-aberto).

| Tema | O que falta | Recomendação |
|---|---|---|
| Semântica do Leitor | O ACE-03 pede leitura por parágrafo e cada palavra como botão. Como o RenderBox (ARQ-51) monta os nós de semântica para atender os dois só se valida no aparelho, com VoiceOver e TalkBack. | — |
| Pedidos ao `postilla-content` | Os itens da seção 10 que o `dict` e o `stories` ainda não têm precisam ser aceitos lá: coluna normalizada (ARQ-63), rank e faixa do NVdB (ARQ-64), nomes de gênero em português e italiano, spans de palavra e frase (ARQ-50), histórias adicionadas por versão (ARQ-26), traços de treino em `entry.data`, `rule` e `drill` (ARQ-86, ARQ-87). | — |
| Números da carga e da fraqueza (D7) | Lote de 20, cotas 5 · 2 · 1, freio a 60, 2 voltas e os limiares do ARQ-89 (30 dias, Beta(1, 3), n ≥ 5, 0,35, peso 0,5) vêm de premissas. A simulação antiga era FSRS-4.5 com outro desenho e não vale. | Constantes num lugar só do código; fechar os números depois da simulação em FSRS-6 da proposta (9.3). |
| Parâmetros do FSRS-6 | "Igual ao Anki" (D2) não diz se os 21 parâmetros são os padrão ou otimizados por aluno, nem a retenção desejada. Opções: (a) parâmetros padrão e retenção 0,9 fixos; (b) otimizador no aparelho, a partir do log, depois de N respostas. | (a) na v1. O log guarda tudo, então o otimizador pode entrar depois e recalcular a dobra sem migração. |
| Passos de aprendizado do Anki | O Anki usa passos em minutos para cartão novo e para lapso. Aqui, as voltas da sessão (D21) fazem esse papel. Opções: (a) sem passos: intervalo em dias inteiros, mínimo 1, vencimento por `localDay`; (b) imitar os passos do Anki em minutos. | (a): é o que o ARQ-82 e o ARQ-84 descrevem, e a D21 já manda o cartão para amanhã depois de 2 voltas. |
| Conferir o "igual ao Anki" | Sem teste, o FSRS do app pode divergir do do Anki sem ninguém notar. | Teste unitário (ARQ-91) com vetores gerados pela implementação de referência (fsrs-rs ou py-fsrs): mesma sequência de notas e datas, mesmos S, D e intervalo. |
| Custo da dobra (ARQ-81) | Estimado, não medido. Opções se ficar lento: (a) aceitar; (b) cache derivado num arquivo à parte, descartável e fora do backup, como o `log`; (c) instantâneos do estado no `user`, o que volta ao P08. | Medir num Android simples com um log sintético de 5 anos. Se a abertura passar de ~200 ms, (b). |
| Tamanho do `answer` × backup | ~3,5 MB por ano com 100 respostas por dia. O Auto Backup do Android tem 25 MB (ARQ-79): um aluno assíduo passa do limite em ~6 anos. | Aceitar na v1. Se chegar perto, encurtar o `typed` ou compactar linhas antigas num arquivo à parte. |
| `at` da linha que substitui (ARQ-80) | A proposta tem `at` e `created_at`, mas não diz que valor o `at` de "Contar como certa" recebe. Opções: (a) herda o `at` e o `day` da linha substituída; (b) o instante da correção. | (a): a correção não muda quando o aluno respondeu, e é só por isso que `at` e `created_at` existem separados. |
| Cadeia de substituições (ARQ-80) | A proposta diz "efetiva é a linha que nenhuma outra substitui". Ao pé da letra, Errado ← Contar como certa ← Desfazer deixaria o Errado sem valer. | Efetiva é a linha que nenhuma linha **efetiva** substitui, lida da mais nova para a mais antiga. É o que o ARQ-80 descreve. |
| Retomar o lote interrompido | "Continuar revisão · 9 de 20 · +1" pede saber quais cartões eram do lote, e o log não diz isso. Opções: (a) o lote em andamento numa chave do `setting`, apagada no fim; (b) coluna `session` em `answer`; (c) remontar o lote pela dobra até o instante em que ele começou. | (a): é estado de tela, como o progresso do Leitor, e não pede coluna nova no log. |
| Virada das 4h no meio da sessão | Uma sessão que atravessa as 4h: de que dia são as cotas e as respostas? | Cada resposta grava o `localDay` do momento em que aconteceu. O lote montado continua igual; as cotas do dia novo valem a partir do próximo lote. |
| Filtro de nível (D4, D32) | Na v1 todo o catálogo é A1, e o filtro "nível ≤ nível de leitura" não corta nada (proposta 12.2, item 8). | Não implementar na v1: um codepath a menos. Entra junto com o conteúdo A2. |
| Trecho por posição (D22) | `saved.paragraph` e `saved.sentence` são posições, como o progresso (ARQ-37). Uma edição da história desloca o trecho. | A mesma regra do ARQ-37: sem o parágrafo, vale o último que existe. Se a `form` não está mais na frase, o parágrafo aparece sem grifo. |
| Origem "Revisão" no Histórico (D29) | O `history` só tem `story_id`. Opções: (a) coluna `history.origin` (0 história ou busca · 1 Revisão); (b) um `story_id` reservado. | (a): o `story_id` é um tipo próprio (ARQ-47) e não deve carregar valor especial. |
| Acento que muda a palavra (G4b) | *e* × *è*, *da* × *dà*, *la* × *là*. Opções: (a) lista fixa no código; (b) o digitado sem acento existe no `dict` como forma de outro lema. | (b), restrito às formas do NVdB, para *pero* (pereira, raro) não fazer *però* sem acento virar Errado. |
