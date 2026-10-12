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

Os três bancos de OFF-34: `user` (dados do usuário), `stories` e `dict`. O esquema de `stories` e `dict` é definido em `postilla-content` (ARQ-07).

| Id | Decisão | Motivo |
|---|---|---|
| ARQ-30 | O app acessa o SQLite pelo pacote `sqlite3` (FFI), com SQL escrito à mão. | Sem geração de código e sem camada entre o app e o SQL. |
| ARQ-31 | Todas as consultas, nos três bancos, rodam num isolate dedicado. A UI recebe os resultados por mensagem. | O `sqlite3` é síncrono. Fora do isolate da UI, uma consulta lenta não trava a tela. |
| ARQ-32 | O esquema do `user` evolui por scripts SQL numerados (`001.sql`, `002.sql`…). `PRAGMA user_version` guarda o último aplicado, e cada script roda numa transação. Só para frente. | Migração explícita e fácil de revisar. |
| ARQ-33 | Todo registro do `user` tem `id` UUID v7, `created_at`, `updated_at` e `deleted_at`. As datas são inteiros em ms desde a epoch, em UTC. | Ids únicos entre aparelhos e datas comparáveis permitem sync futuro sem migração de modelo (OFF-31). |
| ARQ-34 | Remover uma palavra salva ou limpar o histórico preenche `deleted_at`, e as listas filtram essas linhas. | O sync futuro sabe o que foi removido. |
| ARQ-35 | O `user` aponta para o verbete pela chave natural lema + classe (`"binario"`, `"sostantivo"`), nunca pelo `entry.id`. | O `entry.id` muda a cada build do `dict`. Lema + classe sobrevive às versões, e um verbete que saiu cai no OFF-32. |
| ARQ-36 | Cada história tem um UUID escrito na fonte, que nunca muda. Progresso, salvas e histórico apontam para esse UUID. | Renomear ou corrigir a história não quebra o vínculo. |
| ARQ-37 | O progresso aponta para o parágrafo pela posição. Se a história encolher, o progresso vai para o último parágrafo que existe (OFF-32). O deslocamento dentro do parágrafo (LEI-07) é o índice do primeiro caractere visível. | Posição é o mais simples. O índice de caractere sobrevive a mudanças de tamanho do texto e rotação. Uma edição no meio da história desloca o progresso, e isso foi aceito. |
| ARQ-38 | Os ajustes ficam numa tabela chave-valor do `user`. | Entram no Exportar/Importar (AJU-05) e no sync futuro. |
| ARQ-39 | `dict` e `stories` são abertos só para leitura (`mode=ro&immutable=1`). | Sem WAL nem lock, e nenhuma escrita acidental no conteúdo. |

Tabelas do `user` (além das colunas do ARQ-33):

| Tabela | Campos | Requisitos |
|---|---|---|
| `progress` | `story_id`, `paragraph` (posição), `offset` (caractere), `status` (andamento \| lida), `last_opened_at`. Sem linha, a história é nova. | BIB-02, BIB-03, LEI-07 |
| `history` | `day` (data local), `lemma`, `pos`, `story_id`. Única por `day` + `lemma` + `pos`. | SAL-01 |
| `saved` | `lemma`, `pos`, resumo (classe, história de origem), `story_id`. | SAL-02, OFF-32, LEI-10 |
| `setting` | `key`, `value` (JSON): leitura, Imersão, proporção da tradução, ordenação das Salvas, dicas vistas, aviso de histórias novas. | OFF-30, ARQ-26 |

## 5. App Flutter

## 6. Leitor

## 7. Dicionário

## 8. Integrações do sistema

## 9. Pipeline

## 10. Build, CI e testes

## 11. Decisões em aberto
