# Revisão e Treino: decisões

Decisões do dono do produto sobre a proposta [revisao-treino.md](revisao-treino.md), na ordem da seção 12.

| # | Decisão | Escolha | Data |
|---|---|---|---|
| D1 | Unidade de memória da regra | Cartão de padrão por regra (a palavra muda a cada vez); cartão de palavra só para exceções. Ids de padrão só de acréscimo. | 2026-10-16 |
| D2 | O Treino conta para o agendamento? | Igual ao Anki com FSRS-6: toda resposta digitada, de qualquer porta (Revisão, voltas, reforço, Treino), atualiza S e D; as do mesmo dia passam pela fórmula de estabilidade de curto prazo. O contador de lapsos sobe só no primeiro erro do dia de um cartão em revisão. Não usa a regra "só a primeira resposta do dia". | 2026-10-16 |
| D2b | Escolha de forma de 2 opções (formato E) conta no FSRS? | Não. Só alimenta o ponto fraco. | 2026-10-16 |
| D3 | Como uma palavra nova começa a ser cobrada | Só escrever (PT→IT digitado), como no book atual. Sai o formato A (escolha de sentido IT→PT) e a cota "escrever 2/dia"; palavra nova entra direto como `scrivere`. Palavra sem glosa usa a lacuna na frase ou na definição (formato B). Afeta D7 (simulação) e D13. | 2026-10-16 |
| D4 | Como a gramática entra na Revisão | A Revisão apresenta até 1 padrão novo por dia, na ordem do catálogo, com nível ≤ nível de leitura e com membro entre as palavras do aluno. "Tirar da Revisão" na página do tema. | 2026-10-16 |
| D5 | Onde mora | 4ª aba "Revisão" (Biblioteca · Dicionário · Revisão · Ajustes), com o cartão "Revisão de hoje" e a lista de temas do Treino na raiz. Muda NAV-01, a barra de abas dos books e pede ícone novo. | 2026-10-16 |
| D6 | Nota fora do alvo | Certo com aviso (Good): artigo errado, forma flexionada no `scrivere`, acento faltando no `scrivere`. Sinônimo (G5) sem nota, volta com a primeira letra. Acento num cartão de forma é Quase (Hard). | 2026-10-16 |
| D7 | Carga padrão | 5 palavras novas/dia (Ajustes: 0 · 3 · 5 · 10), 2 formas novas, 1 padrão novo, freio com mais de 60 vencidos, lotes de 20. Números a confirmar refazendo a simulação em FSRS-6 com D2 e D3. | 2026-10-16 |
| D8 | Reforço dentro da Revisão | 1 bloco de 3 itens do padrão mais fraco por dia, no primeiro lote, depois do 10º cartão, dentro dos 20. Linha de transição "Reforço: …"; regra curta antes só se errou alguma das 3 últimas. Não cria cartões; as respostas contam no FSRS (D2). | 2026-10-16 |
| D9 | Treino cria cartões? | Só cartões de padrão (a 1ª resposta digitada de um padrão nunca visto cria o cartão) e de membros de `lista` que são palavras do aluno. Palavra do NVdB treinada nunca vira cartão de Palavra. | 2026-10-16 |
| D10 | Estado do padrão para o aluno | Só texto, na exceção ("Você tem errado -co, -go", "Ainda não treinado"); sem número, barra, cor ou "Firme"; ordem fixa. | 2026-10-16 |
| D11 | Habilidades e conteúdo da v1 | Só conteúdo pertinente ao A1. | 2026-10-16 |
| D11b | O que é A1 | Seguir referências: o livro *Dai! 1* e outras (programas e livros A1 de italiano para estrangeiros). O catálogo é reclassificado por elas; a lista final volta para aprovação. | 2026-10-16 |
| D12 | Cartões gerados por uma salva | `saved` ganha `pos` (classe do verbete onde salvou); só essa classe gera cartões. A salva continua por lema. | 2026-10-16 |
| D13 | Palavra sem glosa PT | Escrever com lacuna: com frase de origem, a frase IT com lacuna e a frase PT alinhada como pista; sem frase, a primeira definição IT com lacuna. Palavra do NVdB sem glosa e sem frase fica fora. | 2026-10-16 |
| D14 | Textos das regras | Tabela `rule` do `dict`, escrita à mão em `rules.toml` (postilla-content), em PT e IT; segue a área Rótulos e botões da Imersão. | 2026-10-16 |
| D15 | Gênero e Artigo | Separados. Gênero: escolha de 2 opções pelo som (il · la; un · un' antes de vogal), só para gênero imprevisível. Forma do artigo: cartão de padrão digitado (`art.forma`). | 2026-10-16 |
| D16 | Rodada do Treino | 10 itens em sequência fixa: na 1ª vez, a regra e 2 escolhas de forma (fora do FSRS, D2b); o resto digitado, com 1 a cada 3 do vizinho em "só esta regra". Erro volta 2 itens depois, até 2 vezes, fora dos 10. | 2026-10-16 |
| D17 | Linha do "por que este cartão" | Na resposta (ao lado de "Volta em…") e no fim da sessão; nunca na pergunta. | 2026-10-16 |
| D18 | Frases além da salva (índice de ocorrências) | v1.1. Na v1, só a frase gravada ao salvar; NVdB e salvas pela busca ficam sem trecho. | 2026-10-16 |
| D19 | Dados de plural, gênero e conjugação que faltam | Cadeia de fontes: it.wiktionary → en.wiktionary (kaikki, já no pipeline) → Morph-it!. Origem marcada (`plural_src`: `wikt`, `enwikt`, `morphit`); divergências vão para um relatório. Nada gerado por regra. Pendente: confirmar a licença do Morph-it! (CC BY-SA 2.0 / LGPL) e medir quanto ele acrescenta. Medição do en.wiktionary em [cobertura-enwiktionary.md](cobertura-enwiktionary.md). | 2026-10-16 |
| D20 | Dica nos cartões de forma | Sim: a regra numa linha, sem a resposta; limita a nota a Hard (G7). | 2026-10-16 |
| D21 | Voltas por cartão numa sessão | Até 2, depois de pelo menos 3 outros cartões; depois fica para amanhã. | 2026-10-16 |
| D22 | "Na história" durante a Revisão | Página empilhada só com o trecho (o parágrafo), sem o Leitor. Não toca no progresso de leitura; o "Leitor em consulta" (LEI-13 candidato) sai da proposta. | 2026-10-16 |
| D23 | Linguagem do pipeline (ARQ-02 Python × todo.md C/Zig) | Decidir junto com o pipeline todo; a etapa nova segue o que for adotado. A proposta só registra o conflito. | 2026-10-16 |
| D11c | Critério de "A1" | O que os livros A1 apresentam, com peso no *Dai! 1* (não o "já dominado" do Profilo). Entram: art.forma, gen.lista (nomes em -e frequentes; *il problema* e *la mano* ficam A2), pl.base, pl.invar, pl.ca_ga, pl.co_go parcial (-chi/-ghi; *amici*, *medici* como exceções), uomo → uomini, pres.are/ere/ire, pres.isc, pres.care_gare, pres.rifl, pres.lista, pp.avere, pp.essere só a escolha do auxiliar (sem cobrar concordância), pp.lista com particípios frequentes, prep.art nas combinações frequentes. Ficam fora: pl.ma, pl.cia_gia, resto de pl.lista, imperfetto, futuro. Pesquisa em [a1-referencias.md](a1-referencias.md). | 2026-10-16 |
| D11d | Padrões sem fonte A1 direta | Entram os três, restritos a palavras frequentes: pres.ciare_giare (mangiare, cominciare, viaggiare), pl.io (zio/zii, negozio/negozi, binario/binari), gen.sufixo (-ione, -tà fem.; -ore masc.). | 2026-10-16 |
| D11e | Tópicos A1 fora do catálogo | Entram: concordância do adjetivo (pares curados em `rules.toml`), possessivos (com a regra do artigo com parentesco; lista curada), piace/piacciono com pronome indireto, imperativo tu/voi (com o negativo do tu). Modais entram como membros de pres.lista. Ficam fora por ora: c'è/ci sono, questo/quello, non…mai. Pede novos `skill` e padrões no catálogo; o imperativo passa a ser um 5º tempo/modo na Conjugação, além dos 4 do DIC-05. | 2026-10-16 |
| D24 | Imagens no cartão | Adiadas para depois da v1; o REV-14 sai. | 2026-10-16 |
| D25 | Palavras que caem em Again repetidamente | Só o FSRS na v1; revisitar com dados de uso. | 2026-10-16 |
| D26 | Pré-ensino da próxima história | v1.1, junto com o índice de ocorrências (D18). Na v1: Salvas, depois NVdB por frequência. | 2026-10-16 |
| D27 | Toque no Leitor numa palavra em revisão | Não afeta o agendamento; só abre o verbete. | 2026-10-16 |
| D28 | Passato remoto e "reconhecer forma" (disse → dire) | Fora da v1, como consequência da D11/D11c (não são A1). Voltam com as histórias B1. | 2026-10-16 |
| D29 | Verbete aberto da sessão no Histórico | Entra, com origem "Revisão" no lugar do nome da história (SAL-01 sem exceção). | 2026-10-16 |
| D30 | Virada do dia | 4h nos dois (Revisão e Histórico), uma `localDay` só. | 2026-10-16 |
| D31 | Frase de contexto de história não lida | Pode, se a história é do mesmo nível. Só vale a partir da v1.1, com o índice de ocorrências (D18); na v1 há só a frase da salva. | 2026-10-16 |
| D32 | Treino acima do nível de leitura | Sem efeito na v1: todo o catálogo é A1 (D11). Volta a ser decisão quando entrar conteúdo A2. | 2026-10-16 |
| D33 | Áudio automático | Desligado, sem ajuste; só toca no botão de ouvir. | 2026-10-16 |
| D34 | Ajustes › Revisão | 3 itens: Palavras novas por dia (0 · 3 · 5 · 10), Origem (Só salvas · Salvas e mais comuns), Palavras que já sei. Sai o "Produção liga/desliga" (D3). Tirar tema da Revisão só pela página do tema. | 2026-10-16 |
| D35 | Lista do Treino | Uma lista só, sem grupos, na ordem em que o *Dai! 1* apresenta os tópicos. Temas da v1: Artigo, Plural, Adjetivos (concordância), Possessivos, Preposições, Presente, Passato prossimo, Imperativo, Piacere. A ordem exata sai do índice do *Dai! 1* ([a1-referencias.md](a1-referencias.md)). | 2026-10-16 |
| D36 | Nomes | Aba "Revisão" (IT: *Ripasso*), seção "Treino" (IT: *Allenamento*). | 2026-10-16 |

## Pendências abertas pelas decisões

- **D7:** refazer a simulação de carga em FSRS-6 com D2 (toda resposta conta, lapso 1×/dia), D3 (só escrever), cartão de padrão, reforço e Treino.
- **D19:** confirmar a licença do Morph-it! e medir quanto ele acrescenta depois do en.wiktionary.
- **D11c–D11e:** atualizar o catálogo de padrões e o enum `skill` (concordância, possessivos, piacere, imperativo; níveis A1; ordem do *Dai! 1*).
- **D22:** desenhar a página "só o trecho"; o LEI-13 candidato sai.
