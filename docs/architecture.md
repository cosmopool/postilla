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
| ARQ-02 | O pipeline de conteúdo é escrito em Python. | O wiktextract e as ferramentas de parse do wikitext são Python. |
| ARQ-03 | Dois repositórios: `postilla` (app Flutter e docs do app) e `postilla-content` (pipeline e fontes das histórias). | App e conteúdo têm ciclos de release separados. O app recebe conteúdo novo sem versão nova na loja. |
| ARQ-04 | `postilla-content` é público. | Os pacotes ficam nas Releases dele, e o app baixa sem token. |
| ARQ-05 | Os pacotes de conteúdo são publicados como GitHub Releases de `postilla-content`. | Sem custo e no mesmo lugar do código que gera os pacotes. |
| ARQ-06 | A URL do manifesto embutida no app usa um domínio próprio, que aponta para o GitHub. | Trocar de host não exige versão nova do app. |
| ARQ-07 | `postilla-content` define o contrato entre os repositórios: esquema dos bancos de conteúdo e formato do manifesto. O app segue esse contrato. | Quem gera o dado documenta o formato. |
| ARQ-08 | [dictionary.md](dictionary.md) e [dictionary-pipeline.md](dictionary-pipeline.md) mudam para `postilla-content`. | A doc fica junto do código que ela descreve. |

```
postilla-content (público)                     postilla
  pipeline (Python)                              app (Flutter)
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
| ARQ-33 | Todo registro do `user` tem `id` UUID v7, `created_at`, `updated_at` e `deleted_at`. As datas são inteiros em ms desde a epoch, em UTC. | Ids únicos entre aparelhos e datas comparáveis permitem sync futuro sem migração de modelo (OFF-31). |
| ARQ-34 | Remover uma palavra salva ou limpar o histórico preenche `deleted_at`, e as listas filtram essas linhas. | O sync futuro sabe o que foi removido. |
| ARQ-35 | O `user` nunca aponta para o `entry.id`. Uma palavra salva é só o lema, como texto (`"serranda"`), sem classe. O histórico aponta para o verbete por lema + classe (`"binario"`, `"sostantivo"`). | O `entry.id` muda a cada build do `dict`, e o lema sobrevive às versões. Fora do Leitor o app não conhece a forma tocada, então a salva é pelo lema. Salvar "binario" marca como salvos os dois verbetes de "binario" (substantivo e adjetivo). O histórico tem uma linha por verbete (SAL-01), então guarda a classe. Um verbete que saiu do `dict` cai no OFF-32. |
| ARQ-36 | Cada história tem um UUID escrito na fonte, que nunca muda. Progresso, salvas e histórico apontam para esse UUID. | Renomear ou corrigir a história não quebra o vínculo. |
| ARQ-37 | O progresso aponta para o parágrafo pela posição. Se a história encolher, o progresso vai para o último parágrafo que existe (OFF-32). O deslocamento dentro do parágrafo (LEI-07) é o índice do primeiro caractere visível. | Posição é o mais simples. O índice de caractere sobrevive a mudanças de tamanho do texto e rotação. Uma edição no meio da história desloca o progresso, e isso foi aceito. |
| ARQ-38 | Os ajustes ficam numa tabela chave-valor do `user`. | Entram no Exportar/Importar (AJU-05) e no sync futuro. |
| ARQ-39 | `dict` e `stories` são abertos só para leitura (`mode=ro&immutable=1`). | Sem WAL nem lock, e nenhuma escrita acidental no conteúdo. |

Tabelas do `user` (além das colunas do ARQ-33):

| Tabela | Campos | Requisitos |
|---|---|---|
| `progress` | `story_id`, `paragraph` (posição), `offset` (caractere), `status` (andamento \| lida), `last_opened_at`. Sem linha, a história é nova. | BIB-02, BIB-03, LEI-07 |
| `history` | `day` (data local), `lemma`, `pos`, `story_id`. Única por `day` + `lemma` + `pos`. | SAL-01 |
| `saved` | `lemma` (texto, chave), resumo (classe, história de origem), `story_id`. | SAL-02, OFF-32, LEI-10 |
| `setting` | `key`, `value` (JSON): leitura, Imersão, proporção da tradução, ordenação das Salvas, dicas vistas, aviso de histórias novas. | OFF-30, ARQ-26 |

## 5. App Flutter

O código do app e do pipeline segue os Core Principles do [AGENTS.md](../AGENTS.md). As convenções de nome de lá não valem aqui (ARQ-95). As decisões abaixo dizem como alguns deles viram escolhas concretas.

| Id | Decisão | Motivo |
|---|---|---|
| ARQ-40 | Não há camadas entre a tela e o SQL. O módulo `db` tem uma função por consulta (`dbSavedList`, `dbProgressSet`…), que manda o SQL ao isolate (ARQ-31) e devolve structs. A tela chama essas funções direto. Não há repository, use case nem interface. | Menos código e menos conceitos. Dá para seguir uma ação da tela até o SQL no debugger. |
| ARQ-41 | O estado de cada tela fica no `State` do próprio `StatefulWidget`. Uma classe de estado separada só aparece onde dividir estado entre telas for necessário, caso a caso. | O Flutter já dá o `State`, então nenhum conceito novo por tela. |
| ARQ-42 | Os ajustes que valem para o app todo (tema, leitura, Imersão) ficam num struct imutável `Settings`, num `ValueNotifier<Settings>` na raiz, exposto por `InheritedNotifier`. Mudar um ajuste grava no `db` e troca o valor. | Um estado global só, com o que o Flutter já tem. Tema e Imersão mudam na hora (LEI-08, AJU-03). |
| ARQ-43 | Depois de desempilhar uma tela, a tela que ficou embaixo relê as salvas (`await` do push). Não há conjunto de salvas global. | Uma consulta indexada resolve o SAL-05, sem estado compartilhado para manter igual ao banco. |
| ARQ-44 | A navegação é feita à mão: um `IndexedStack` com um `Navigator` por aba, e o `Navigator` raiz para o Leitor e o verbete do Leitor em tela cheia. O voltar do Android passa pelo `NavigatorPopHandler`. | Sem pacote e sem tabela de rotas. O push leva direto ao widget, com argumentos tipados. O app não tem deep links. |
| ARQ-45 | Uma pasta por tela (`library/`, `reader/`, `dictionary/`, `settings/`), mais `db/` e `ui/` (componentes do design system). | Quem mexe numa tela acha tudo dela numa pasta só. |
| ARQ-47 | Ids e unidades têm tipos distintos, feitos com `extension type` (`StoryId`, `ParagraphIndex`, `CharOffset`, `WordKey`…). | O compilador impede misturar um `StoryId` com uma `String` qualquer, sem alocação em runtime. |
| ARQ-48 | A linha do SQLite e o JSON do verbete (`entry.data`) viram struct no isolate do banco, que manda os structs prontos para a UI. | Parse na borda: a UI nunca vê linha crua nem JSON, e o parse do verbete não pesa no isolate da UI. |
| ARQ-49 | Uma função do `db` nunca devolve `null` nem lança exceção. Se não acha nada ou falha, devolve o valor zero: um sentinela const (`Story.nil`, `Entry.nil`) ou uma lista vazia. A falha vai para o log (ARQ-70). | Quem chama tem um caminho só, sem `if (x == null)` nem `try/catch` na tela. |
| ARQ-46 | Os textos de interface seguem o padrão abstract class + uma classe por língua + global trocável, com uma classe por área da Imersão que tem texto: `NavStrings nav`, `UiStrings ui` e `DictStrings dict`, cada uma com versão `Portuguese` e `Italian`. Quando a Imersão muda, o app troca os globais e então notifica o `ValueNotifier<Settings>`. A área Glosas não tem texto: ela só decide se a glosa aparece. | Sem geração de código. O compilador impede usar um texto da área errada. |

```
Navigator raiz
 ├─ Shell: IndexedStack + barra de abas
 │   ├─ Navigator Biblioteca
 │   ├─ Navigator Dicionário   (verbetes da aba, até 20, DIC-06)
 │   └─ Navigator Ajustes
 ├─ Leitor                     (push no raiz, sem barra)
 └─ Verbete do Leitor          (push no raiz, sem barra)
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
| ARQ-50 | O pipeline divide o texto em palavras e frases e grava no `stories`, por parágrafo, o início e o fim de cada palavra e de cada frase, em italiano e em português. Elisões (l'aria, c'è) são uma palavra só. O app só lê esses spans. | Um tokenizador só, em Python, testado no build. As contagens de palavras do LEI-07 e os pares de frase do TRA-08 saem prontos. |
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
| ARQ-64 | As sugestões vêm nesta ordem: igual ao digitado, depois por frequência (NVdB: fondamentale → alto uso → alta disponibilità → resto), depois alfabética. O `dict` grava esse rank em cada `entry`. | "casa" e "caso" sobem antes de "casella". A Revisão também vai usar o NVdB. |
| ARQ-65 | Os curingas (`?` uma letra, `*` várias) viram um `GLOB` sobre a coluna normalizada. | O `GLOB` do SQLite já usa esses dois curingas. |
| ARQ-66 | O "Você quis dizer" usa uma trie dos lemas normalizados, percorrida com a linha da distância de Levenshtein e podada acima de 2 edições. Os candidatos são ordenados por distância e depois pelo rank do ARQ-64. A trie é montada no isolate do banco no primeiro uso e fica em memória até o app fechar. | Sem dado novo no `dict` e sem extensão no SQLite. Pega até dois erros em qualquer posição. Abrir o app não paga a montagem. |

O `dict` atual não tem a coluna normalizada (ARQ-63) nem o rank (ARQ-64). Os dois são pedidos de mudança no contrato de `postilla-content` (ARQ-07).

## 8. Integrações do sistema

| Id | Decisão | Motivo |
|---|---|---|
| ARQ-73 | Tudo que o app pede ao sistema passa por um platform channel próprio, em Swift e Kotlin: TTS, e-mail, folha de compartilhar e seletor de arquivos. Sem pacotes de plugin. | Um mecanismo só para o sistema, sem dependências, e cada chamada nativa fica visível no código. |
| ARQ-74 | A pronúncia (OFF-40) usa `AVSpeechSynthesizer` no iOS e `TextToSpeech` no Android, com voz `it-IT`. O canal lista as vozes com a marca de offline de cada sistema. Sem voz italiana offline, o botão fica desativado (OFF-41). | A voz do sistema funciona sem rede. |
| ARQ-75 | O e-mail do Relatar erro (LEI-09) e do Enviar diagnóstico (AJU-06) abre pelo canal: `MFMailComposeViewController` no iOS e `Intent.ACTION_SEND` com anexo por `FileProvider` no Android. No iOS sem conta no app Mail, o app avisa que precisa de um app de e-mail configurado. | Um link `mailto:` não anexa arquivo, e o diagnóstico precisa do anexo. Um mecanismo só para os dois e-mails. |
| ARQ-76 | O arquivo exportado (AJU-05) e o anexo do diagnóstico (ARQ-72) são gerados com `VACUUM INTO` num arquivo temporário, apagado depois de compartilhar. | Cópia consistente e compacta com o banco aberto, sem WAL pendente nem linhas apagadas. |
| ARQ-77 | O `user` grava um `PRAGMA application_id` fixo do Postilla. Ao importar, o app abre o arquivo só para leitura, confere o id, aceita `user_version` menor ou igual ao seu e roda as migrações que faltam (ARQ-32). Um arquivo de um app mais novo é recusado com aviso. | Recusa qualquer SQLite que não seja do Postilla e aceita exportações de versões antigas. |
| ARQ-78 | Antes de importar, o app guarda uma cópia do `user` atual (`VACUUM INTO`) na pasta do app. Fica só a última, substituída a cada importação. Desfazer troca o `user` por ela. | Cobre o desfazer do AJU-05 sem o espaço crescer. |
| ARQ-79 | Só o `user` entra no backup do sistema (OFF-33). `dict`, `stories`, a pasta de preparação, o `log` e a cópia de desfazer ficam fora (`NSURLIsExcludedFromBackupKey` no iOS, regras de backup no Android). | O conteúdo volta do pacote embutido, e o iCloud do usuário não recebe ~90 MB. O Auto Backup do Android tem limite de 25 MB. |

### Diagnóstico

| Id | Decisão | Motivo |
|---|---|---|
| ARQ-70 | O log do app (`appLog`) é gravado num quarto banco, `log`, separado do `user`. Ele não entra no Exportar/Importar (AJU-05) nem no backup do sistema. | Um `user` corrompido não leva o log junto, e o log não se mistura aos dados do usuário. |
| ARQ-71 | O `log` guarda os últimos 30 dias. As linhas mais antigas são apagadas ao gravar. | Cobre o intervalo comum entre um problema e o usuário decidir relatar. |
| ARQ-72 | O log só sai do aparelho se o usuário enviar: Ajustes › Sobre › Enviar diagnóstico (AJU-06) abre o e-mail do sistema com o `log` anexado. | Sem telemetria (OFF-03). O usuário vê o e-mail antes de enviar. |

## 9. Pipeline

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

## 10. Build, CI e testes

| Id | Decisão | Motivo |
|---|---|---|
| ARQ-90 | Os testes são de integração: começam pela UI (`flutter_test`, dirigindo os widgets) e usam SQLite real, um arquivo temporário por teste. Só as chamadas HTTP e os erros de IO são simulados. | Testa o app como ele roda, sem mock de camada interna, já que não há camadas (ARQ-40). |
| ARQ-91 | Teste unitário só para lógica pesada (ordenação da Biblioteca, trie do ARQ-66 e afins). Cada uma também ganha um teste de integração que passa por ela. | O unitário cobre os casos difíceis da lógica. O de integração confere que ela funciona ligada ao resto. |
| ARQ-92 | Por enquanto não há teste ponta a ponta no aparelho (`integration_test`). | Rodar emulador ou aparelho no CI é lento e caro para a v1. |
| ARQ-93 | Os testes usam os mesmos `dict` e `stories` de produção, nas versões fixadas pelo lock do build (ARQ-14). Não há banco de conteúdo de teste. Atualizar o lock roda os testes contra o conteúdo novo, e o bump só entra com os testes passando. | Mockar o mínimo possível. O teste vê exatamente o dado que o usuário vê. |
| ARQ-94 | O CI do app roda no GitHub Actions, em Linux, a cada push e PR: baixa os pacotes do lock, roda `dart analyze` e `flutter test`. Build de loja fica fora do CI por enquanto. | Pega erro de análise e teste antes do merge, sem runner macOS. |
| ARQ-95 | O analisador usa o `flutter_lints` padrão, sem ajustes. Os nomes seguem o estilo Dart. | Sem regras próprias para manter. |

## 11. Decisões em aberto
