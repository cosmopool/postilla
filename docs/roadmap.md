# Postilla: roadmap

Em que versão entra cada requisito. As specs ([functional-spec.md](functional-spec.md), [architecture.md](architecture.md), [dictionary.md](dictionary.md), [dictionary-pipeline.md](dictionary-pipeline.md)) continuam descrevendo o produto inteiro. Este documento diz a versão de cada id e como um requisito fica numa versão em que ainda falta parte do que ele cita.

Como ler:
- Um id listado numa versão entra como a spec o descreve, salvo a nota da tabela "Como fica".
- Quando a spec, a arquitetura ou uma decisão **Dn** diz "v1" ou "v1.1" sobre a Revisão e o Treino, a versão é a da Revisão, que agora é a v2. O "v1.1" do §10 da spec (índice de ocorrências, pré-ensino, link do verbete para o Treino) fica em [Depois](#depois).

---

## Decisões da v1

| Decisão | Data |
|---|---|
| A v1 tem Biblioteca, Leitor, Leitor com tradução, Dicionário e Ajustes, tudo offline. | 2026-10-26 |
| Saem da v1: Revisão e Treino (§7A, §7B); Histórico e Salvas (§7) e o pontilhado; progresso de leitura (LEI-07, BIB-02, BIB-03, Continuar lendo, estados da história); atualização de conteúdo pela rede (OFF-20..24, ARQ-20..26, manifesto); Relatar erro (LEI-09) e Enviar diagnóstico (AJU-06); pronúncia por TTS (OFF-40, OFF-41); Exportar e Importar (AJU-05); Compartilhar do verbete (DIC-08). | 2026-10-26 |
| Nenhum platform channel próprio na v1 (ARQ-73): nada do que fica pede o sistema. Exceção: o pacote `path_provider`, só para achar a pasta de suporte do app onde ficam os bancos. | 2026-10-27 |
| Barra com 3 abas: Biblioteca · Dicionário · Ajustes. | 2026-10-26 |
| O pipeline é escrito em Zig 0.17, com as dependências pelo package manager do Zig (ARQ-02). Fecha a D23. | 2026-10-26 |
| A etapa 5b do pipeline (traços de treino, `rule`, `drill`, `rules.toml`, Morph-it!) sai inteira até a v2. | 2026-10-26 |
| Frequência pelo NVdB (ARQ-64), só a faixa (1 fondamentale · 2 alto uso · 3 alta disponibilità): a lista não tem rank por palavra. A lista não tem licença de reuso (o PDF da Internazionale diz "Tutti i diritti riservati"); o dono decidiu usar assim mesmo. As faixas foram extraídas uma vez do PDF para `nvdb.tsv` no `postilla-content`. | 2026-10-27 |
| Glosa PT: WikDict it-pt + pivô pelo en.wiktionary (etapa 4 do pipeline). | 2026-10-26 |
| Um arquivo de correções só, lema + classe + campo → valor. | 2026-10-26 |
| `entry.data` em JSON. | 2026-10-26 |
| O Imperativo é o 5º tempo da Conjugação do verbete (DIC-05). | 2026-10-26 |
| Créditos em Ajustes › Sobre: Wikizionario, en.wiktionary, WikDict e NVdB (AJU-04). | 2026-10-26 |
| Linha de fonte fixa em todo verbete: "Fonte: Wikizionario, Wiktionary, WikDict · CC BY-SA" (DIC-09). | 2026-10-27 |
| O pacote embutido é comprimido com gzip -9 (ARQ-11). O zstd volta na v1.2. | 2026-10-26 |
| O lock do app aponta para `../postilla-content/out` (ARQ-14). Nada é publicado. | 2026-10-26 |
| Sem CI na v1: `dart analyze` e `flutter test` rodam na máquina (ARQ-94). | 2026-10-26 |
| O `appLog` só escreve no console (ARQ-70). O banco `log` volta com o Enviar diagnóstico. | 2026-10-26 |
| Cada história é um `.txt`: cabeçalho `chave: valor`, um bloco IT e um bloco PT, uma frase por linha, alinhadas entre os blocos. | 2026-10-26 |
| O Compartilhar do verbete entra na v1.1, com o Exportar: os dois usam a folha de compartilhar (ARQ-73). | 2026-10-27 |
| Duração da história (BIB-01) calculada pelas palavras, por nível: A1 60, A2 80, B1 100, B2 120 palavras/min, para cima. | 2026-10-27 |
| Ícones: os paths do Lucide (ISC) desenhados à mão com traço 1,5, sem pacote de ícones. | 2026-10-27 |
| O que os books não desenham: Leitor sem Mais opções; doca só com "Mostrar tradução", à direita; raiz do Dicionário com a busca e as duas dicas; "Sem verbete no dicionário" no toast padrão; página de escolha de lema como lista compacta (lema + classe); Mais opções do verbete numa folha (Copiar · Voltar à história · Fonte); Ajustes com Leitura, Imersão e Sobre. Num conflito entre books, vale o book da própria tela. | 2026-10-27 |

## Versões

| Versão | O que entra |
|---|---|
| v1 | Biblioteca, Leitor, Leitor com tradução, Dicionário (busca e verbete) e Ajustes (Leitura, Imersão, Sobre). Offline, com o conteúdo embutido. |
| v1.1 | Histórico e Salvas, pontilhado, progresso de leitura, Exportar e Importar, pronúncia (TTS), Relatar erro, Enviar diagnóstico e o banco `log`, Compartilhar do verbete, exclusão do backup (ARQ-79). Entram os platform channels. |
| v1.2 | Atualização de conteúdo pela rede, Releases, manifesto, zstd e CI. |
| v2 | Revisão e Treino, com a etapa 5b do pipeline. |
| Depois | O que a spec já adia da Revisão e do Treino (§10). |

---

## v1

### Spec funcional

| Área | Ids |
|---|---|
| Offline | OFF-01..04, OFF-10..13, OFF-30, OFF-31, OFF-33, OFF-34 |
| Navegação | NAV-01..06 |
| Biblioteca | BIB-01, BIB-04..10 |
| Leitor | LEI-01..06, LEI-08, LEI-10..12 |
| Leitor com tradução | TRA-01..09 |
| Dicionário | DIC-01..11 |
| Ajustes | AJU-01..04 |
| Acessibilidade | ACE-01..06 |

### Como fica na v1

| Id | Na v1 |
|---|---|
| OFF-04 | As únicas escritas são os ajustes e as dicas já vistas. |
| OFF-10 | Com gzip -9, o pacote tem ~21 MB, e não ~15 MB (ARQ-11). |
| OFF-30 | Só ajustes de leitura, Imersão, proporção da tradução e dicas de primeiro uso já vistas. |
| OFF-34 | Três bancos: `user`, `stories` e `dict`. O `log` entra na v1.1 (ARQ-70), e não há Exportar nem Importar. |
| NAV-01 | Três abas: Biblioteca · Dicionário · Ajustes. |
| NAV-06 | Tocar de novo na aba ativa: na Biblioteca, rola ao topo; no Dicionário, volta à raiz. |
| BIB-01 | O card não tem estado: título, subtítulo, nível, gênero e duração. |
| BIB-04 | Ordem fixa por nível, de A1 a B2, e no mesmo nível da mais curta para a mais longa. Sem Continuar lendo e sem concluídas no fim. |
| BIB-07 | "Resultados" segue a ordem do BIB-04. |
| BIB-09 | Toda história abre no início. |
| LEI-01 | App bar com voltar, título e Aa, sem Mais opções. Doca só com "Mostrar tradução", sem linha de progresso nem "N% lido". |
| LEI-04 | Nada salva: nenhum gesto na história, e o verbete não tem marcador (DIC-08). |
| LEI-06 | O grifo fica igual. Sem pontilhado. |
| LEI-10 | Fim da história com o card "Próxima história" e "Voltar à biblioteca", sem contagem de salvas nem link para Salvas. A próxima é a primeira candidata desta ordem: 1) a continuação da obra; 2) a próxima do mesmo nível, na ordem do BIB-04; 3) a primeira do nível seguinte (nunca dois acima). Sem candidata, o card some. |
| DIC-08 | App bar do verbete: voltar e Mais opções (Copiar · Voltar à história · Fonte). Sem marcador e sem Ouvir pronúncia. |
| DIC-10 | Raiz da aba só com a busca: sem `Histórico \| Salvas` e sem Mais opções. |
| ACE-02 | Sem a exceção da sessão: ao empilhar, o foco vai sempre para o voltar da página nova. |

### Arquitetura

| Área | Ids |
|---|---|
| Visão geral | ARQ-01..03, ARQ-07, ARQ-08 |
| Pacotes | ARQ-10..12, ARQ-14, ARQ-15 |
| Bancos | ARQ-30..33, ARQ-36, ARQ-38, ARQ-39 |
| App | ARQ-40..42, ARQ-44..49 |
| Leitor | ARQ-50..53, ARQ-56 |
| Dicionário | ARQ-60..66 |
| Diagnóstico | ARQ-70 |
| Testes | ARQ-90..93, ARQ-95 |

| Id | Na v1 |
|---|---|
| ARQ-11 | O pacote embutido é `dict-<versão>.db.gz` e `stories-<versão>.db.gz`, com gzip -9. |
| ARQ-14 | O lock fixa versão e sha256 dos arquivos em `../postilla-content/out`, e o script copia de lá. |
| ARQ-33, tabelas do `user` | O `user` só tem `setting`: leitura, Imersão, proporção da tradução e dicas vistas. `progress`, `history` e `saved` entram na v1.1; `answer`, na v2. |
| ARQ-38 | Sem temas tirados da Revisão. |
| ARQ-44 | Três `Navigator` de aba. O raiz só empilha o Leitor e o verbete do Leitor. |
| ARQ-45 | Sem a pasta `review/`. |
| ARQ-49, ARQ-70 | A falha vai para o console. Sem o banco `log`. |
| ARQ-51, ARQ-53 | Sem pontilhado. Os lemas do lote servem só ao toque. |
| ARQ-64 | Só a faixa do NVdB, para as sugestões da busca e o "Você quis dizer". Sem rank dentro da faixa. |
| ARQ-93 | Os pacotes dos testes vêm do lock local (ARQ-14). |
| ARQ-94 | Sem CI. `dart analyze` e `flutter test` rodam na máquina. |

### Pipeline

- Etapas 1 a 7 do [dictionary-pipeline.md](dictionary-pipeline.md), sem a 5b.
- Fontes: kaikki.org do it.wiktionary, dump do it.wiktionary, WikDict it-pt e en-pt, kaikki.org do en.wiktionary (só o pivô da glosa) e NVdB.
- Arquivos escritos à mão: só o de correções.
- Saída em `out/`, comprimida com gzip -9. Nada é publicado.
- Da seção 10 da arquitetura, entra tudo, menos o que está na v1.2 e na v2 abaixo.

---

## v1.1

| Id | O que entra |
|---|---|
| OFF-32 | Salvas e progresso sobrevivem à atualização de conteúdo. |
| OFF-34 | O banco `log` e o Exportar e Importar do `user`. |
| OFF-40, OFF-41 | Ouvir pronúncia (TTS). |
| BIB-02, BIB-03 | Estados da história e Continuar lendo. |
| BIB-04, BIB-07, BIB-09 | A ordem com Continuar lendo e concluídas no fim; "Resultados" por estado; abrir no último parágrafo lido. |
| LEI-01 | Doca com progresso e "N% lido"; Mais opções. |
| LEI-04, LEI-06 | Salvar pelo marcador do verbete; pontilhado. |
| LEI-07 | Progresso de leitura. |
| LEI-09 | Recomeçar do início e Relatar erro no texto. |
| LEI-10 | Contagem de salvas e link para Salvas. A próxima história pula as concluídas. |
| DIC-08 | Marcador, Ouvir pronúncia e Compartilhar. |
| DIC-10 | Seletor `Histórico \| Salvas` e Mais opções. |
| SAL-01..05 | Histórico e Salvas, sem a origem "Revisão" (D29, v2). |
| AJU-05 | Exportar e Importar. |
| AJU-06 | Enviar diagnóstico. |
| ARQ-34, ARQ-35 | `saved` e `history`, sem a parte de `answer`. |
| ARQ-37, ARQ-55 | `progress`. |
| ARQ-43, ARQ-54 | Releitura das salvas e pontilhado. |
| ARQ-70..72 | Banco `log` e diagnóstico. |
| ARQ-73..78 | Platform channel: TTS, e-mail, folha de compartilhar, seletor de arquivos; Exportar e Importar. |
| ARQ-79 | `dict`, `stories` e `log` fora do backup do sistema. |
| ARQ-84 | Só o `history.day`, com a virada às 4h (D30). |

O `setting` ganha a ordenação das Salvas.

## v1.2

| Id | O que entra |
|---|---|
| OFF-05, OFF-20..24 | Atualização de conteúdo pela rede e o aviso de histórias novas. |
| ARQ-04..06 | `postilla-content` público, Releases e manifesto no domínio próprio. |
| ARQ-11 | zstd -19 no lugar do gzip -9. |
| ARQ-13 | Um major aceito por pacote. |
| ARQ-14 | O lock aponta para as Releases. |
| ARQ-20..26 | Manifesto, download, preparação e troca. |
| ARQ-94 | CI no GitHub Actions. |

Na seção 10 da arquitetura: o manifesto e a `meta` do `stories` com as histórias adicionadas. O `setting` ganha o aviso de histórias novas.

## v2

| Onde | O que entra |
|---|---|
| Spec funcional | §7A (REV-*) e §7B (TRE-*); NAV-01 com a 4ª aba; NAV-06 na aba Revisão; NAV-07; a origem "Revisão" do SAL-01 (D29); os cartões do SAL-02 (REV-03); as respostas no OFF-30 e no OFF-32; AJU-07; a exceção da sessão no ACE-02; ACE-07. |
| Arquitetura | ARQ-80..89; a parte de `answer` do ARQ-35; os temas tirados do ARQ-38; o resto do ARQ-84; a tabela `answer`; as pendências da Revisão na seção 12. |
| Pipeline | A etapa 5b: traços de treino, `rule`, `drill`, `rules.toml`, exceções de artigo, Morph-it! e relatório de divergências. Na seção 10 da arquitetura, as linhas de `entry.data`, `rule`, `drill`, itens curados, fontes novas, relatório e `rule.id`. As decisões em aberto da 5b no [dictionary-pipeline.md](dictionary-pipeline.md#decisões-em-aberto). |
| Decisões | D1–D10, D11, D11b–D11d, D12–D17, D19–D22, D25, D27, D29, D32–D36. Da D11e, só o Treino: o Imperativo no verbete já está na v1. |
| Em aberto | Os itens #12 a #23 e #25 a #29 do §11 da spec. |

## Depois

- O que o §10 da spec adia da Revisão e do Treino: imagens no cartão (D24); índice de ocorrências (D18, D31); pré-ensino da próxima história (D26); link do verbete para o Treino; conteúdo acima do A1 (D11, D28, D32); tratamento próprio da palavra que cai em Again repetidamente (D25).
- O resto do §10 continua fora de escopo, sem versão.
