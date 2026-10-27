# Postilla: spec funcional

O que o app faz e como se comporta. Esta spec cobre só funcionalidades; aparência, tokens e componentes ficam no design system ([design/](design/)). Cada requisito tem um id (`OFF-03`) para ser citado em tasks e revisões.

Documentos relacionados:
- [dictionary.md](dictionary.md): campos do verbete e transformações.
- [dictionary-pipeline.md](dictionary-pipeline.md): como o dicionário é gerado e publicado.
- [design/content.md](design/content.md): textos de exemplo (catálogo, história, verbetes).
- [propostas/revisao-treino.md](propostas/revisao-treino.md) e [propostas/revisao-treino-decisoes.md](propostas/revisao-treino-decisoes.md): desenho completo da Revisão e do Treino (catálogo de padrões, regras de nota, carga) e as decisões que o fecharam.

---

## 1. Offline-first

Primeiro requisito do app. Toda funcionalidade funciona sem conexão, sempre, inclusive na primeira abertura. A rede só serve para receber versões novas do conteúdo, e o app nunca depende dela.

### Princípios

| Id | Requisito |
|---|---|
| OFF-01 | Nenhuma tela, ação ou estado depende de rede. O app não tem estado "Sem conexão". |
| OFF-02 | Todo o conteúdo (histórias, traduções, dicionário) vem embutido no app e fica no aparelho. |
| OFF-03 | Todos os dados do usuário ficam só no aparelho. Não há conta, login nem servidor de usuário na v1. |
| OFF-04 | Escritas são locais e imediatas: salvar uma palavra, avançar na leitura ou mudar um ajuste grava na hora, sem fila nem "sincroniza depois". |
| OFF-05 | A falta de rede nunca aparece como erro. Uma atualização que falha é tentada de novo depois, em silêncio. |

### Conteúdo embutido

| Id | Requisito |
|---|---|
| OFF-10 | O pacote do app traz uma versão inicial do conteúdo, comprimida (~15 MB, quase tudo do dicionário). |
| OFF-11 | Na primeira abertura, o app descompacta o conteúdo no armazenamento local (~90 MB). Isso acontece sem rede e mostra um estado "Preparando o dicionário" enquanto dura. |
| OFF-12 | Se faltar espaço para descompactar, o app informa quanto espaço é necessário e tenta de novo quando o usuário pedir. |
| OFF-13 | Dicionário e histórias têm versões próprias (SemVer, ARQ-12). Ajustes › Sobre mostra as duas e a data do dump do Wiktionary: "Dicionário 2.1.0 (Wikizionario de 01/10/2026) · Histórias 1.4.2". |

### Atualização de conteúdo

| Id | Requisito |
|---|---|
| OFF-20 | Ao abrir o app com rede, ele consulta o manifesto de conteúdo, no máximo uma vez por dia. |
| OFF-21 | Se houver versão nova, ela é baixada em segundo plano, por qualquer rede (Wi‑Fi ou celular), e o app confere o sha256. |
| OFF-22 | A versão nova é aplicada de forma atômica: ou entra inteira, ou o app continua com a anterior. Um download interrompido ou corrompido é descartado. |
| OFF-23 | A troca nunca acontece com uma história ou verbete aberto. A versão nova vale a partir da próxima abertura do app. |
| OFF-24 | A atualização não pede confirmação. Quando a versão aplicada traz histórias novas, a primeira abertura da Biblioteca mostra um aviso único, que some sozinho ("3 histórias novas"). As histórias novas não têm selo nem seção própria e entram na ordem do BIB-04. Sem histórias novas, não aparece aviso. |

### Dados do usuário

| Id | Requisito |
|---|---|
| OFF-30 | Dados guardados no aparelho: progresso por história, histórias concluídas, última história aberta, histórico de verbetes, palavras e expressões salvas (com a classe do verbete e a frase de origem), ajustes de leitura, Imersão, proporção da tradução, dicas de primeiro uso já vistas, respostas da Revisão e do Treino (REV-17, inclusive as palavras que já sei), Ajustes › Revisão e os temas tirados da Revisão. |
| OFF-31 | Cada registro tem id estável e data de criação e alteração, para permitir sync numa versão futura sem migração de modelo. |
| OFF-32 | Dados do usuário nunca se perdem por causa de atualização de conteúdo: |
| | • uma palavra salva guarda um resumo próprio (lema, classe, história de origem) e continua na lista mesmo se o verbete mudar ou sair do dicionário. Se o verbete sair, tocar na palavra abre a busca com o lema e o "Você quis dizer" (DIC-11); |
| | • o progresso aponta para história + parágrafo. Se o texto da história mudar, o progresso vai para o parágrafo mais próximo que ainda existe; |
| | • as respostas da Revisão e do Treino apontam para o lema e para o id do padrão, que nunca muda (ARQ-86). Um verbete ou padrão que sai do conteúdo tira os cartões dele da Revisão, e as respostas ficam (REV-18). |
| OFF-33 | Apagar o app apaga os dados. O backup do sistema (iCloud/Google) pode restaurá-los, mas o app não depende dele. |
| OFF-34 | Há quatro bancos separados no aparelho: dados do usuário, histórias, dicionário e log do app (ARQ-70). Só o banco do usuário é exportado e importado (AJU-05). Atualizar o conteúdo nunca toca o banco do usuário. |

### Pronúncia

| Id | Requisito |
|---|---|
| OFF-40 | "Ouvir pronúncia" usa a voz de italiano do sistema (TTS, `it-IT`), que funciona offline. |
| OFF-41 | Se o aparelho não tiver voz italiana, o botão fica desativado, com uma explicação de como instalar a voz nos ajustes do sistema. |

### O que isso muda no design atual

Os books foram desenhados com o dicionário online. As correções estão em [12. O que muda nos books](#12-o-que-muda-nos-books).

---

## 2. Navegação

| Id | Requisito |
|---|---|
| NAV-01 | Quatro abas: Biblioteca · Dicionário · Revisão · Ajustes. O nome da aba Revisão segue Imersão › Navegação (IT: *Ripasso*). |
| NAV-02 | O Leitor não é aba. Ele é empilhado a partir da Biblioteca, em tela cheia e sem barra de abas. |
| NAV-03 | O verbete aberto do Leitor é empilhado como página inteira, sem barra de abas. O verbete aberto da aba Dicionário é empilhado dentro da aba, com a barra visível. O dicionário nunca abre em folha ou modal. |
| NAV-04 | O voltar tem o nome da tela anterior ("Voltar à história", "Voltar a finestrino", "Voltar ao Dicionário"). Funcionam o chevron, o gesto de borda e o botão voltar do sistema. |
| NAV-05 | Voltar do Leitor preserva rolagem, busca e filtros da Biblioteca. |
| NAV-06 | Tocar de novo na aba ativa: na Biblioteca, rola ao topo; no Dicionário e na Revisão, volta à raiz. |
| NAV-07 | Na aba Revisão, as páginas de tema e de regra do Treino são empilhadas dentro da aba, com a barra visível. A sessão (Revisão ou Treino) é empilhada em tela cheia, sem barra de abas, como o Leitor. O verbete, a regra e o trecho da história abertos de dentro da sessão também são empilhados sem barra. O voltar segue o NAV-04: "Voltar à Revisão", "Voltar a Plural", "Voltar ao cartão". |

## 3. Biblioteca

| Id | Requisito |
|---|---|
| BIB-01 | Catálogo de histórias com título e subtítulo (sempre em italiano, nunca traduzidos), nível (A1–B2), gênero, duração e estado. |
| BIB-02 | Estados da história: nova, em andamento (com linha de progresso e %) ou concluída ("Lida"). A história fica concluída quando o bloco de fim (LEI-10) entra na tela. Não existe botão "Marcar como lida". Reabrir uma concluída pelo card mantém "Lida". Só "Recomeçar do início" (LEI-09) volta a história para em andamento, em 0%. |
| BIB-03 | Card "Continuar lendo" com a última história aberta que ainda está em andamento. Uma história concluída nunca ocupa o card. Sem história em andamento, o card some. Ele também some quando há busca ou filtro. |
| BIB-04 | Ordem fixa: Continuar lendo → todas as histórias (por nível de A1 a B2; no mesmo nível, da mais curta para a mais longa) → concluídas no fim. Não há ordenação manual. |
| BIB-05 | Filtros em chips, em dois grupos (Nível e Gênero): "ou" dentro do grupo, "e" entre grupos. "Limpar filtros" no cabeçalho da lista. |
| BIB-06 | A busca procura em título, subtítulo e gênero, sem diferenciar acento nem maiúscula, e o resultado muda a cada letra. Busca e filtros se somam. O gênero aparece e é buscado na língua de Imersão › Navegação (AJU-02). |
| BIB-07 | Com busca ou filtro, aparece uma lista única, "Resultados", na ordem em andamento → novas → concluídas. |
| BIB-08 | Estados vazios: busca sem resultado oferece "Limpar busca"; filtros sem resultado oferecem "Limpar filtros". A contagem de resultados é anunciada. |
| BIB-09 | Tocar num card abre o Leitor. Uma história em andamento abre no último parágrafo lido; nova e concluída abrem no início. |
| BIB-10 | Sem pressão longa no card: sem prévia, sem menu de contexto, sem deslizar para apagar. |

## 4. Leitor

| Id | Requisito |
|---|---|
| LEI-01 | Texto só em italiano, com app bar compacta (voltar, título, Aa, Mais opções) e doca (linha de progresso, "N% lido", "Mostrar tradução"). |
| LEI-02 | Tocar numa palavra grifa a palavra e empilha o verbete do lema. Elisões (l'aria, c'è) são um alvo só. Pontuação não responde. Uma palavra sem verbete (nome próprio, palavra fora do dicionário) é grifada e mostra um aviso rápido: "Sem verbete no dicionário". Se a forma levar a mais de um lema ou classe ("porta": porta sostantivo ou portare), empilha uma página curta de escolha, com uma linha por lema e classe. Não há anotação de lema no conteúdo. |
| LEI-03 | Pressão longa (500 ms) seleciona uma expressão. O usuário arrasta para estender a seleção palavra a palavra, dentro do parágrafo, e ao soltar a expressão abre no dicionário. |
| LEI-04 | Nenhum gesto na história salva. Salvar só pelo marcador do verbete. |
| LEI-05 | Toque fora das palavras, pinça e toque duplo não têm efeito próprio (o toque duplo conta como um toque). |
| LEI-06 | Ao voltar do verbete, a rolagem é a mesma e a palavra continua grifada até o próximo toque ou a primeira rolagem. Palavras salvas aparecem com pontilhado. |
| LEI-07 | O progresso é salvo continuamente (história + parágrafo). Ao abrir um verbete, o app grava também o deslocamento dentro do parágrafo: se o sistema encerrar o app, a história reabre exatamente nesse ponto. O "N% lido" é igual na doca e no card: palavras dos parágrafos antes do atual (o que está no topo da tela) ÷ total de palavras, arredondado para baixo. Fica em no máximo 99% até a história ser concluída (BIB-02), quando vira 100%. |
| LEI-08 | Aa: tamanho do texto (5 passos), entrelinha (3 opções) e tema (Claro · Escuro · Sistema, vale para o app todo). As mudanças valem na hora e para todas as histórias. |
| LEI-09 | Mais opções: Recomeçar do início · Relatar erro no texto. "Relatar erro" abre o app de e-mail do sistema com destinatário (postilla@kaiodelphino.com), assunto e corpo preenchidos (história, parágrafo, trecho e versão do conteúdo). Sem rede, o e-mail fica na caixa de saída do sistema. |
| LEI-10 | Fim da história: contagem de palavras salvas nela (a linha some se for zero), link para Salvas, card "Próxima história" e "Voltar à biblioteca". Sem comemoração. A próxima é a primeira candidata desta ordem: 1) a continuação da obra, quando a história é parte de uma obra dividida; 2) a primeira não concluída do mesmo nível, na ordem do BIB-04; 3) a primeira não concluída do nível seguinte (nunca dois acima). Histórias em andamento também contam. Sem candidata, o card some. |
| LEI-11 | Dica de primeira leitura, exibida uma vez: "Toque numa palavra para abrir o dicionário." |
| LEI-12 | Teclado: ← → percorrem palavras, Enter abre o verbete, Esc volta. |

## 5. Leitor com tradução

| Id | Requisito |
|---|---|
| TRA-01 | Tela dividida na horizontal: italiano em cima, português embaixo. Proporções 50/50 (padrão), 65/35 e fechada. O italiano nunca fica com menos de 50%. |
| TRA-02 | A última proporção aberta fica salva no aparelho. |
| TRA-03 | O divisor encaixa na proporção mais próxima ao soltar. Soltar com o italiano acima de 82% fecha a tradução. |
| TRA-04 | Toque na palavra italiana abre o dicionário. Toque fora da palavra marca a frase e o par dela em português. Toque no português marca a frase e o par em italiano, e nunca abre o dicionário. |
| TRA-05 | Uma frase ativa por vez. Tocar de novo nela desmarca. Se o par estiver fora da vista, a outra metade rola o mínimo para mostrá-lo. |
| TRA-06 | Pressão longa seleciona uma expressão limitada à frase. |
| TRA-07 | A rolagem das duas metades é sincronizada por parágrafo, liderada pela última metade que recebeu toque. A sincronia é recalculada ao mover o divisor, mudar o tamanho do texto ou girar o aparelho. |
| TRA-08 | Frases e parágrafos estão alinhados 1:1 entre italiano e português (exigência para o conteúdo). |
| TRA-09 | A tradução é sempre em português e está sempre disponível, qualquer que seja a Imersão. A área Glosas (AJU-02) vale só para a glosa do verbete. |

## 6. Dicionário

Campos, origem e transformações: [dictionary.md](dictionary.md).

| Id | Requisito |
|---|---|
| DIC-01 | Verbete monolíngue em italiano, sempre pelo lema: "si siede" abre sedersi. Plurais, formas conjugadas e formas com clítico levam ao lema. |
| DIC-02 | Seções em ordem fixa. Uma seção sem dado não aparece. Os rótulos das seções (Significati ↔ Significados) seguem Ajustes › Imersão › Dicionário (AJU-02). O conteúdo do verbete fica sempre em italiano. |
| DIC-03 | A glosa PT fica oculta e um toque revela ou esconde. Ela está sempre fechada ao abrir um verbete. Com Imersão › Glosas = Italiano, o verbete não mostra glosa. |
| DIC-04 | "Nella storia" mostra a frase da história com a palavra grifada. Tocar nela volta ao trecho. Nos verbos, mostra a forma usada. |
| DIC-05 | Conjugação: um tempo verbal por vez (Presente, Passato prossimo, Imperfetto, Futuro, Imperativo), com a forma usada na história destacada. O Imperativo é o 5º tempo, para o aluno achar no verbete o que treina (D11e; ver §11). |
| DIC-06 | As palavras de Sinonimi, Contrari, Parole derivate, Termini correlati, Alterati e Da non confondere con podem ser tocadas e empilham outro verbete. Todas essas seções entram na v1. A pilha tem até 20 verbetes, e cada um guarda a própria rolagem. |
| DIC-07 | Uma expressão abre como verbete. Se ela não tiver verbete próprio, empilha a mesma página de escolha do LEI-02, com uma linha para cada palavra da seleção que tem verbete. |
| DIC-08 | App bar do verbete: voltar, Ouvir pronúncia (OFF-40), marcador e Mais opções (copiar, compartilhar, voltar à história, fonte). |
| DIC-09 | Atribuição obrigatória em todo verbete, a mesma em todos: "Fonte: Wikizionario, Wiktionary, WikDict · CC BY-SA". |
| DIC-10 | Raiz da aba: busca e seletor `Histórico \| Salvas`. Mais opções: ordenar, limpar histórico. A raiz não tem cartão de Revisão: ele mora na aba Revisão (REV-01). |
| DIC-11 | Busca em italiano, com sugestões a cada letra. Encontra lemas e formas flexionadas. Aceita curingas (`?` para uma letra, `*` para várias). Sem resultado, mostra "Você quis dizer". |

## 7. Histórico e Salvas

| Id | Requisito |
|---|---|
| SAL-01 | Todo verbete aberto entra no Histórico, agrupado por dia, com lema, classe e origem. A origem é a história, ou "Revisão" para o verbete aberto numa sessão da Revisão ou do Treino (D29). O dia vira às 4h, o mesmo dia da Revisão (ARQ-84). Cada dia tem uma linha por verbete: reabrir move a linha para o topo do dia e atualiza a origem. O Histórico não tem limite. "Limpar histórico" pede confirmação num diálogo e não afeta Salvas. |
| SAL-02 | Salvar e remover só pelo marcador (no verbete e nas linhas das listas). Um aviso confirma: "Salva em Dicionário › Salvas" ou "Removida das Salvas". A palavra é salva pelo lema (ARQ-35): salvar "binario" substantivo deixa salvo também "binario" adjetivo, e remover num remove dos dois. A classe do verbete onde a palavra foi salva só decide quais cartões ela gera na Revisão (REV-03). |
| SAL-03 | Uma expressão com verbete próprio é salva como uma entrada só. |
| SAL-04 | Salvas tem duas ordenações: Mais recentes (padrão) e A–Z. A escolha fica salva no aparelho. O Histórico não tem ordenação: é sempre por dia, do mais recente para o mais antigo, e só a aba Salvas mostra "Ordenar". Estado vazio: "Nenhuma palavra salva ainda". |
| SAL-05 | Uma palavra salva aparece com pontilhado no Leitor e nas listas de palavras relacionadas. No Leitor, toda forma do lema é pontilhada ("serrande" com "serranda" salva). Uma forma de mais de um lema é pontilhada se qualquer um deles estiver salvo (ARQ-54). |

## 7A. Revisão

Revisão espaçada das palavras do aluno e da gramática A1, na aba Revisão (NAV-01). Desenho completo, catálogo de padrões e regras de nota: [propostas/revisao-treino.md](propostas/revisao-treino.md). Decisões (citadas como **Dn**): [propostas/revisao-treino-decisoes.md](propostas/revisao-treino-decisoes.md). Telas: [book-revisao.html](design/book-revisao.html).

Termos usados nesta seção e na 7B:
- **Cartão:** uma lembrança agendada pelo FSRS. O **cartão de palavra** cobra uma palavra num exercício (*binario* · Palavra; *uomo* · Plural). O **cartão de padrão** cobra uma regra, e a palavra muda a cada vez (Plural · -co, -go).
- **Padrão:** uma regularidade do catálogo, com id, nível, regra em PT e IT, exemplos e membros. Um padrão `regra` é um cartão de padrão. Num padrão `lista`, cada membro tem o seu cartão de palavra.
- **Tema** e **regra:** para o aluno, "Plural" é um tema e "-co, -go" é uma regra dele.
- **Palavras do aluno:** as Salvas e as palavras do NVdB que a Revisão já apresentou.

### Entrada e conteúdo

| Id | Requisito |
|---|---|
| REV-01 | A Revisão começa pelo cartão "Revisão de hoje", no topo da raiz da aba Revisão, acima da lista do Treino (TRE-01). Quatro estados: |
| | • com cartões: "Revisão de hoje · 20 cartões · 5 palavras novas". Tocar empilha a sessão (NAV-07); |
| | • interrompida: "Continuar revisão · 9 de 20 · +1". Tocar retoma; |
| | • nada vencido, inclusive depois de terminar: "Nada para revisar agora · Próxima revisão amanhã, 9 cartões." Não é link; |
| | • Origem = Só salvas e nenhuma salva: "Nada para revisar ainda · Salve palavras no Dicionário para elas entrarem aqui." Não é link. |
| REV-02 | Palavras novas vêm primeiro das Salvas, da mais antiga para a mais nova, e depois do NVdB, por frequência, faixa por faixa. Ajustes › Revisão › Origem pode limitar a "Só salvas" (AJU-07). Uma palavra sem glosa PT entra pelo exercício Palavra com lacuna (REV-15). Uma palavra do NVdB sem glosa fica de fora, porque na v1 ela não tem frase de origem (D13, D18). |
| REV-03 | Salvar torna o lema fonte de cartões só na classe do verbete onde ele foi salvo: salvar "binario" substantivo não gera cartões de "binario" adjetivo. A salva continua por lema (SAL-02, D12). Remover das Salvas tira os cartões da Revisão e guarda as respostas; salvar de novo retoma de onde parou. Uma expressão salva gera só o cartão Palavra. |
| REV-04 | Nove exercícios: Palavra (ver a glosa e escrever a palavra, PT→IT), Gênero, Artigo, Conjugação, Plural, Preposição, Adjetivo (concordância), Possessivo e Piacere. A Conjugação cobra três tempos: Presente, Passato prossimo e Imperativo (com o negativo do *tu*). O catálogo da v1 tem 30 padrões A1 em 9 temas (proposta, seção 2.2). Regras do catálogo: |
| | • Gênero é escolha de 2 opções pelo som (*il · la*, *lo · la*; antes de vogal, *un · un'*, porque *l'* esconde o gênero), só para nomes cujo gênero a terminação não diz. A forma do artigo é um cartão de padrão digitado (D15); |
| | • todos os outros exercícios de forma são digitados. Adjetivo, Possessivo e Piacere usam itens escritos à mão no catálogo (*le chiavi ___ (nuovo)*), e não frases geradas; |
| | • verbo regular nunca ganha cartão próprio: *parlare* aparece só como palavra do cartão de padrão do Presente em -are; |
| | • no cartão de padrão, o rótulo diz a regra (`PLURAL · -co, -go`). Num membro de `lista`, o rótulo é só o tema (`PLURAL`), porque "Irregulares" já seria uma dica; |
| | • a palavra da vez num cartão de padrão é o membro que o aluno errou na última vez, se faz mais de 1 dia; senão, o usado há mais tempo. Primeiro as palavras do aluno, depois o NVdB. Nunca a mesma duas vezes seguidas. |
| | Não há ajuste por exercício nem por tempo verbal: um tema sai da Revisão pela página do tema (TRE-08). |
| REV-05 | Palavra nova é apresentada antes da primeira cobrança: lema, artigo, glosa, definição e áudio, com "Já sei" e "Aprender". A primeira pergunta (Palavra) vem 3 cartões depois. "Já sei" (na apresentação ou em Mais opções) tira a palavra da Revisão e a põe em Ajustes › Revisão › Palavras que já sei (AJU-07). Um aviso com ação confirma: "*chiave* não vai mais para a revisão. Desfazer", por 6 s; o tempo para enquanto o aviso tem foco. |

### Agendamento e sessão

| Id | Requisito |
|---|---|
| REV-06 | Agendamento pelo FSRS-6, como no Anki (D2, ARQ-82): |
| | • toda resposta no formato do próprio cartão, de qualquer porta (Revisão, voltas, reforço, Treino), atualiza estabilidade e dificuldade. As respostas do mesmo dia passam pela fórmula de curto prazo. O lapso conta só no primeiro erro do dia de um cartão em revisão; |
| | • notas: Errado e Não sei → Again. Quase, ou certo com dica → Hard. Certo → Good. Não há botão Fácil: a nota sai da correção, sem pedir avaliação ao aluno; |
| | • desbloqueio: os cartões de forma de uma palavra (Gênero, membro de `lista`) só entram depois que o cartão Palavra dela é acertado num dia posterior ao da apresentação. Um membro de `lista` só entra depois que a Revisão apresentou o padrão dele (REV-23); |
| | • ordem do lote: vencidos do de menor retenção para o de maior; novos intercalados, 1 a cada 4; exercícios diferentes se alternam quando há escolha. Dois cartões da mesma palavra nunca no mesmo lote, exceto a apresentação e a primeira cobrança; |
| | • tocar no Leitor numa palavra em revisão só abre o verbete e não afeta o agendamento (D27). |
| REV-12 | Cada resposta é gravada na hora (OFF-04). Fechar a sessão (chevron, gesto de borda ou voltar do sistema) não pede confirmação. O que faltou continua vencido, e o cartão do dia mostra "Continuar revisão" (REV-01). |
| REV-16 | Sem gamificação (§10): nada de sequência de dias, pontos, metas ou comemoração. O fim da Revisão mostra só: "20 cartões revisados", "Certos 15 · Quase 2 · Errados 3", as palavras novas do dia ("5 palavras novas: chiave, giornale…"), o padrão mais fraco com o link para treiná-lo (TRE-07), "Mais 34 vencidos." (só se sobrou) e os botões "Continuar" e "Voltar à Revisão". |
| REV-20 | Limites (D7): lote de 20 cartões, com o reforço incluído. Por dia, até 5 palavras novas (0 · 3 · 5 · 10 em AJU-07), 2 formas novas (Gênero e membros de `lista`) e 1 padrão novo. Com mais de 60 vencidos no início da sessão, nada novo entra naquele dia. Vencidos não têm limite. As cotas contam só o que a Revisão criou: o Treino nunca gasta cota. Depois de 20, o fim do lote oferece "Continuar" ou parar, e o que ficou continua vencido. Os números dependem da nova simulação (§11). |
| REV-21 | Contador "N de M · +K". M é o tamanho do lote e não cresce. N avança quando um cartão aparece pela primeira vez (a apresentação também avança). K é a soma das voltas pendentes com as palavras novas que esperam a primeira cobrança. O leitor de tela lê "Cartão 4 de 20, mais 1 para repetir". Um cartão errado volta depois de pelo menos 3 outros, no máximo 2 vezes por sessão; depois, fica para amanhã (D21). As voltas contam no FSRS (REV-06) e sobrevivem ao encerramento do app. |
| REV-22 | Reforço (D8): um bloco por dia com 3 itens do padrão mais fraco (TRE-07), no primeiro lote, depois do 10º cartão, dentro dos 20. Sem padrão mais fraco, não há bloco. O bloco começa com uma linha de transição, sem tela nova: "Reforço: plural em -co, -go · 3 cartões" e "Continuar". A regra curta aparece antes só se o aluno errou alguma das 3 últimas respostas daquele padrão. São 3 palavras diferentes; num padrão `lista`, só membros que o aluno já tem em cartão. O reforço nunca cria cartão, e as respostas contam no FSRS. |
| REV-23 | Padrão novo (D4): a Revisão apresenta até 1 por dia, o próximo do catálogo na ordem do *Dai! 1*, com nível menor ou igual ao nível de leitura e com pelo menos um membro entre as palavras do aluno. Nível de leitura é o mais alto entre as histórias em andamento ou lidas, A1 sem nenhuma; na v1 todo o catálogo é A1, e o filtro não corta nada (D32). Padrão `regra`: a página da regra (2 a 3 frases e a tabela de exemplos) com "Continuar"; a primeira pergunta, digitada, vem 3 cartões depois e cria o cartão. Padrão `lista`: só a página da regra; dali em diante, os membros que são palavras do aluno podem entrar pela cota de forma. Um tema tirado da Revisão (TRE-08) não apresenta padrões. |

### Pergunta e correção

| Id | Requisito |
|---|---|
| REV-07 | Correção automática (ARQ-85). A nota mede só o alvo do cartão: um erro fora do alvo é mostrado, e a nota fica (D6). Regras (proposta, seção 3.2): |
| | • erro fora do alvo é Certo com aviso: *è arrivato* com sujeito *lei* → "Certo. Com *lei*: *è arrivata*."; |
| | • no Palavra, qualquer forma do lema vale: *serrande* → "Certo. A palavra no dicionário é *serranda*."; |
| | • o artigo é opcional em toda resposta com substantivo e, se vier, é conferido. Artigo errado é Certo com aviso ("O artigo é *i*: *binario* é masculino."). No Possessivo, o artigo é o alvo; |
| | • acento: no Palavra, falta de acento é Certo com aviso ("Falta o acento: *città*."); num cartão de forma, é Quase. O apóstrofo do imperativo (*va'*) conta como acento. Um acento que muda a palavra (*e*/*è*, *da*/*dà*) é Errado; |
| | • outro lema com a mesma glosa (*finestra*, pedido *finestrino*) não leva nota: "Também é janela. Aqui, a palavra é outra." O cartão volta no fim da sessão com a primeira letra, e essa resposta tem nota normal; |
| | • uma letra diferente, com 6 letras ou mais, é Quase só no Palavra. Num cartão de forma, é Errado (*amichi*, *binarii*); |
| | • escolha (Gênero, escolha de forma do Treino): certo é Good; errado ou Não sei, Again. Não há Quase; |
| | • Não sei é Again. Pular não grava nada. |
| | Por exercício: na Conjugação, o pronome sujeito é opcional e o do verbo pronominal é obrigatório (*siede* para *si siede* é Errado); formas alternativas da tabela valem (*va'* e *vai*). No passato prossimo com *essere*, auxiliar trocado é Errado (*ho arrivato*) e qualquer terminação do particípio vale, com aviso se o sujeito pede outra (§11). No imperativo negativo do *tu*, só *non* + infinito. Adjetivo e Piacere aceitam só a lacuna ou a frase inteira; Possessivo aceita com ou sem o nome (*mia* ou *mia madre*). O campo desliga autocorreção, sugestão e maiúscula automática do teclado. |
| REV-08 | Com o campo ativo, uma barra de acentos (à è é ì ò ù) fica sobre o teclado. Cada tecla tem nome acessível ("e com acento grave"). |
| REV-09 | Dica ("Mostrar dica", sem ícone). No Palavra: a frase da história com lacuna; sem frase, ou quando a frase já é a pergunta, a primeira letra. Nos cartões de forma: a regra numa linha, sem a resposta ("-co, -go: ganha h."). Nas escolhas, não há dica. Usar a dica limita a nota a Quase (Hard, D20). |
| REV-15 | Imersão. Numa palavra sem glosa PT, ou com Imersão › Glosas = Italiano, o Palavra pergunta pela frase de origem com lacuna, com a frase PT alinhada como pista; sem frase, pela primeira definição de Significati com lacuna (D13; ver §11). O lema e as palavras que começam com as mesmas 5 letras viram lacuna. Rótulos, botões, instruções, vereditos, avisos, nomes de tema e de regra e os textos das regras seguem Imersão › Rótulos e botões (D14). Os nomes "Revisão" (*Ripasso*) e "Treino" (*Allenamento*) e os títulos das páginas seguem Navegação. Nomes dos tempos, pessoa, classe, *Piacere* e as perguntas dos itens escritos à mão ficam sempre em italiano, como no verbete. |
| REV-25 | Botão único: com o campo vazio, "Não sei"; com texto, "Conferir"; na resposta, "Continuar", no mesmo lugar. Nunca dois botões lado a lado. Nas escolhas, a barra mostra só "Não sei". O campo não tem placeholder e cresce com o texto. Teclado: Enter confere; na resposta, Enter é ignorado por 500 ms e depois vale Continuar; Esc volta; nas escolhas, 1 e 2 escolhem a opção. O teclado desce ao conferir e sobe no próximo cartão digitado. |

### Resposta

| Id | Requisito |
|---|---|
| REV-10 | A resposta mostra, nesta ordem: o veredito, com o desfazer (REV-11); quando o cartão volta, com o porquê (REV-24); a palavra com artigo e o botão de ouvir; classe e IPA; a glosa (pílula fechada, que não aparece com Glosas = Italiano); a forma; a regra aplicada à palavra ("*medico* é exceção: *medici*.") com "Ver a regra ›"; Na história (REV-26); "Continuar". A pergunta encolhe numa linha, e na resposta errada a letra que difere fica sublinhada. Na escolha, a opção tocada ganha ✓ ou ✕ e a certa fica marcada. No cartão de padrão, "Volta em 4 dias" vira "A regra volta em 4 dias", porque a palavra vai ser outra. A nota já está gravada quando a resposta aparece. O áudio toca só pelo botão, nunca sozinho (OFF-40, OFF-41, D33). |
| REV-11 | Em Errado e Quase, "Contar como certa" fica na linha do veredito e troca a nota para Certo, recalculando o intervalo. Tocado, vira "Contada como certa." e "Desfazer". Não sei não tem desfazer: o botão só existe com o campo vazio. |
| REV-13 | Mais opções muda entre pergunta e resposta. Na pergunta: Pular cartão (vai para o fim do lote, sem gravar nada) · Já sei esta palavra (só no exercício Palavra, só na Revisão) · Relatar erro no cartão. Na resposta: Abrir verbete (empilha, SAL-01) · Já sei esta palavra · Relatar erro no cartão. Não há verbete antes de responder. "Relatar erro no cartão" abre o e-mail como o LEI-09. |
| REV-24 | Por que este cartão (D17): uma linha na resposta, ao lado de "Volta em…", e no fim da sessão; nunca na pergunta, onde seria uma dica. Textos: "Errou há pouco", "Palavra nova · das salvas", "Palavra nova · das mais comuns", "Regra nova". O vencido normal não tem linha, e o reforço é dito uma vez, na linha de transição (REV-22). |
| REV-26 | Na história (D22). Quando a palavra tem frase de origem (a frase gravada ao salvar no Leitor), a resposta mostra a frase com a forma grifada e "Ver o trecho ›". O link empilha uma página só com o parágrafo da frase, com o título e o nível da história e a forma salva grifada, sem o Leitor, sem barra e sem doca. Abrir a página não grava progresso, conclusão nem última história aberta. "Voltar ao cartão" devolve à resposta, com o foco no link. Na v1, palavras do NVdB e palavras salvas pela busca não têm frase (D18). |

### Dados e acessibilidade

| Id | Requisito |
|---|---|
| REV-14 | Removido: imagens no cartão foram adiadas para depois da v1 (D24, §10). O id não é reusado. |
| REV-17 | As respostas da Revisão e do Treino ficam num log só de inserções no banco do usuário (OFF-30, ARQ-80). Nenhuma resposta muda nem é apagada: "Contar como certa", "Desfazer" e "Já sei" são linhas novas. Estado do cartão, ponto fraco, cotas e voltas são calculados a partir do log (ARQ-81), e nada disso é gravado. O log vai junto no Exportar (AJU-05). |
| REV-18 | Pergunta e resposta saem do dicionário na hora do cartão, então uma atualização de conteúdo vale no próximo cartão. Se o verbete ou o padrão sair do conteúdo, os cartões dele saem da Revisão, as respostas ficam e a palavra continua em Salvas (OFF-32). Um cartão só está ativo se a fonte existe, o lema não está em "Já sei" e o tema está na Revisão (ARQ-83). |
| REV-19 | Acessibilidade da sessão: |
| | • ao abrir um cartão digitado, o foco vai para o campo, com um nome acessível que junta instrução, pergunta e pista ("Escreva o plural. il medico, sostantivo maschile, singolare."). Numa escolha, vai para o grupo de opções, com o nome da pergunta; |
| | • depois de conferir, o foco vai para o veredito (focável, sem `role="status"`), lido numa frase só ("Não é essa. A resposta é i medici."); |
| | • na apresentação, o foco vai para o lema; na transição do reforço, para a linha; no fim, para o título. Ao voltar de uma página empilhada, para o link que a abriu (ACE-02); |
| | • o campo tem `lang="it"`. A lacuna é lida como "lacuna", o IPA fica fora do leitor de tela e o estado tem sempre ícone e texto (ACE-05). Texto grande: ACE-07. Movimento reduzido: ACE-01. |

## 7B. Treino

O Treino é a Revisão com o aluno escolhendo o assunto: os mesmos cartões, a mesma correção e o mesmo log de respostas. Fica na raiz da aba Revisão, abaixo do cartão do dia.

| Id | Requisito |
|---|---|
| TRE-01 | A seção "Treino" lista 9 temas numa lista só, sem grupos, na ordem em que o *Dai! 1* os apresenta (D35): Artigo · Presente · Plural · Preposições · Adjetivos · Possessivos · Piacere · Passato prossimo · Imperativo. Cada linha mostra exemplos ("il, lo, la, l'") ou o estado do tema (TRE-07). A ordem nunca muda. Tocar empilha a página do tema (NAV-07). Os nomes dos tempos e de *Piacere* ficam sempre em italiano. |
| TRE-02 | Página do tema: um texto curto, a lista das regras do tema (com exemplo ou estado em cada linha) e "Treinar \<tema\>", que mistura as regras. Página da regra: o texto (2 a 3 frases), a tabela de exemplos e "Treinar só esta regra". Um padrão com poucos membros (*uomo → uomini*) não ganha página e aparece só como linha do tema (§11). Caminhos: tema › Treinar (2 toques); tema › regra › Treinar só esta regra (3 toques); fim da Revisão › "Treinar -co, -go" (1 toque). "Ver a regra", aberto de dentro de uma sessão, mostra a mesma página sem o botão "Treinar". |
| TRE-03 | Rodada de 10 itens, em sequência fixa (D16): |
| | • na primeira vez num padrão (nenhuma resposta): a página da regra, que não conta como item, e 2 itens de escolha de forma (*il parco* → *parchi* · *parci*); |
| | • o resto, até 10, é forma digitada. Em "só esta regra", 1 item em cada 3 é do padrão vizinho (*parchi* × *treni*). No tema inteiro, os padrões são sorteados com peso igual ao ponto fraco, com no máximo um padrão nunca visto por rodada. Num padrão `lista`, os itens são os membros, com os vencidos primeiro; |
| | • erro: a resposta mostra a regra aplicada à palavra ("*medico* é exceção: o plural é *medici*"), e o item volta 2 itens depois, no máximo 2 vezes, fora dos 10. O contador mostra "4 de 10 · +1"; |
| | • sem fases, sem limiares e sem critério de "firme por hoje". |
| TRE-04 | Palavras da rodada: primeiro as palavras do aluno que são membros do padrão; depois o NVdB, por frequência. Quando a palavra não é do aluno e Glosas = Português, a glosa aparece na pergunta (*il parco* · parque). Nos itens escritos à mão (Adjetivos, Possessivos, Piacere), primeiro os que usam um lema do aluno. Cada palavra aparece uma vez por rodada. |
| TRE-05 | As respostas do Treino contam no FSRS como as da Revisão (REV-06, D2). A escolha de forma não conta: só alimenta o ponto fraco, com metade do peso (D2b). O Treino só cria cartões de padrão (a primeira resposta digitada de um padrão nunca visto cria o cartão) e cartões de membros de `lista` que são palavras do aluno, que entram na Revisão quando desbloqueados (D9). Uma palavra do NVdB treinada nunca vira cartão de Palavra. O Treino não gasta as cotas do REV-20. Correção, dica, botão único, desfazer, Mais opções e foco são os da Revisão (REV-07..11, REV-13, REV-19, REV-25), sem "Já sei esta palavra". |
| TRE-06 | Fim da rodada: tema e regra ("PLURAL · -co, -go"), "10 cartões · Certos 7 · Quase 1 · Errados 2", uma linha por erro ("amico: você escreveu amichi · amici") e, só em "só esta regra", "A regra volta na Revisão em 3 dias." Botões: "Voltar a \<tema\>" e "Treinar de novo". Na resposta de cada item não há "Volta em…": a ligação com a Revisão é só a linha do fim. |
| TRE-07 | Ponto fraco: calculado por padrão, a partir das respostas de qualquer porta (ARQ-89). Para o aluno, aparece só em texto e só na exceção (D10): "Você tem errado -co, -go" na linha do tema ou da regra; "Ainda não treinado" ou "Ainda não treinada" sem nenhuma resposta; a transição do reforço (REV-22); o fim da Revisão ("Você tem errado plural em -co, -go." e "Treinar -co, -go ›"). Sem número, barra, porcentagem, cor, ícone de nível, "Firme" ou "dominado". A lista não muda de ordem com o desempenho. Vocabulário não tem ponto fraco na v1: o FSRS já traz de volta a palavra errada (D25). |
| TRE-08 | Página do tema › Mais opções: "Tirar da Revisão" (ou "Pôr na Revisão", se tirado) · Relatar erro. Tirar faz os cartões do tema sumirem da Revisão (as respostas ficam) e impede que padrões novos dele sejam apresentados. O Treino do tema continua disponível. É o único jeito de tirar gramática da Revisão (AJU-07). |
| TRE-09 | Sem gamificação (REV-16, §10). |

## 8. Ajustes

O book de Ajustes ainda não existe (`book-ajustes.html` está previsto). Por enquanto, o que está definido:

| Id | Requisito |
|---|---|
| AJU-01 | **Leitura:** tamanho do texto, entrelinha e tema (os mesmos da folha Aa do Leitor). |
| AJU-02 | **Imersão:** quatro áreas, cada uma em Português ou Italiano: Navegação, Rótulos e botões, Dicionário, Glosas. Cada área vale para o app todo, sem exceção: o app bar, os botões e os avisos do Dicionário seguem "Rótulos e botões". |
| AJU-03 | Predefinições de Imersão: Iniciante (tudo em português, padrão), Intermediário (dicionário em italiano), Imersão total (tudo em italiano). Qualquer outra combinação é Personalizado. Efeito imediato. Não há onboarding: o app começa em Iniciante sem perguntar, e o usuário muda em Ajustes › Imersão. |
| AJU-04 | **Sobre:** versão do app, versão do conteúdo (OFF-13) e créditos (Wikizionario, en.wiktionary e WikDict, CC BY-SA; NVdB, De Mauro 2016; wiktextract e kaikki). Morph-it! entra nos créditos se entrar no pipeline (§11). |
| AJU-05 | **Dados:** Exportar e Importar o banco do usuário como um arquivo, pela folha de compartilhar e pelo seletor de arquivos do sistema. O arquivo não inclui histórias nem dicionário. Importar substitui os dados atuais: o app pede confirmação e guarda antes uma cópia automática dos dados atuais, para poder desfazer. |
| AJU-06 | **Sobre › Enviar diagnóstico:** abre o app de e-mail do sistema com destinatário (postilla@kaiodelphino.com), assunto, corpo preenchido (versões do app e do conteúdo) e o log dos últimos 30 dias anexado (ARQ-70..72). Nada sai do aparelho sem o usuário enviar o e-mail. |
| AJU-07 | **Revisão:** três itens (D34). Palavras novas por dia: 0 · 3 · 5 · 10, padrão 5 (REV-20). Origem: Só salvas · Salvas e mais comuns, padrão Salvas e mais comuns (REV-02). Palavras que já sei: as palavras tiradas por "Já sei" (REV-05), e cada uma pode voltar para a Revisão. Não há ajuste por exercício, por tempo verbal, de produção nem de áudio. Um tema sai da Revisão só pela página do tema (TRE-08). |

## 9. Acessibilidade

| Id | Requisito |
|---|---|
| ACE-01 | Com movimento reduzido, as transições ficam instantâneas e as mudanças de estado continuam. |
| ACE-02 | Foco: ao empilhar, vai para o voltar da página nova, exceto na sessão da Revisão e do Treino (REV-19). Ao desempilhar, volta ao elemento de origem. |
| ACE-03 | No Leitor, o leitor de tela lê por parágrafo. Cada palavra é um botão, navegável pelo rotor de palavras. |
| ACE-04 | Cada metade da tela dividida declara o idioma (`it` / `pt-BR`), para a voz do leitor de tela trocar de língua. |
| ACE-05 | Contagens, estados e mudanças são anunciados. Nenhum estado depende só de cor. |
| ACE-06 | Alvos de toque de 44pt, com a exceção documentada das palavras na coluna de leitura (linhas de 34pt). |
| ACE-07 | Texto grande: na Revisão e no Treino, o campo de resposta tem altura mínima de 44pt e cresce com o texto. Vereditos e resultados quebram a linha, sem reticências, e as palavras não se partem. |

## 10. Fora de escopo

- Conta, login, sync entre aparelhos e qualquer servidor de usuário (v1).
- Gamificação: sequência de dias, XP, troféus, metas e comemorações.
- Áudio da história (narração).
- Busca do Dicionário em português (busca reversa PT → IT).
- Zoom por pinça, ordenação manual da Biblioteca, prévia ou menu de contexto nos cards.
- Capítulos e páginas. Cada história é um texto corrido. Uma obra longa vira várias histórias no catálogo ("Pinocchio, capitolo primo", "capitolo secondo"…).
- Revisão e Treino, adiados para depois da v1:
  - imagens no cartão, da galeria ou da câmera (o antigo REV-14, D24);
  - índice de ocorrências: frases de contexto além da frase gravada ao salvar, inclusive de histórias não lidas do mesmo nível (v1.1, D18, D31). Conjugação e preposição em frase dependem dele;
  - pré-ensino das palavras da próxima história (v1.1, D26);
  - link do verbete (Flessione, Coniugazione) para o Treino (v1.1);
  - conteúdo acima do A1 (D11, D11c, D11e): imperfetto e futuro no Treino, passato remoto e "reconhecer a forma" (*disse* → *dire*, D28), condizionale, congiuntivo, plurais em -ma e -cia/-gia, plural -ci/-gi pela tônica, plurais irregulares além de *uomo*, concordância do particípio com *essere*, pronomes clíticos, imperativo com pronome, *c'è/ci sono*, *questo/quello*, *non… mai*; voltam com o conteúdo A2 e B1. Treinar acima do nível de leitura volta a ser decisão nessa hora (D32);
  - tratamento próprio para a palavra que cai em Again repetidamente: na v1, só o FSRS (D25).
- Na Revisão e no Treino, também fora: exercício de reconhecer (IT→PT, escolha de sentido) e o ajuste "Produção" (D3, D34); áudio automático e ajuste para ele (D33); estado de domínio ("Firme", níveis, barras) e lista reordenada pelo erro (D10); abrir a história no Leitor a partir de um cartão, ou um "Leitor em consulta" (D22: a sessão mostra só o trecho, REV-26).

## 11. Em aberto

Conflitos entre os books do design e definições que faltam. Quando a spec já segue uma recomendação, o requisito diz "ver §11", e a decisão final pode mudá-lo.

| # | Tema | Conflito ou lacuna |
|---|---|---|
| 11 | Glosa PT | Decidido: o pipeline baixa um dicionário italiano → português e preenche a glosa a partir dele. Fonte: WikDict it-pt + pivô pelo en.wiktionary (2026-10-26, ver [dictionary-pipeline.md](dictionary-pipeline.md#decisões-em-aberto)). |
| 12 | Carga da Revisão (REV-20, D7) | Os números (5 palavras, 2 formas, 1 padrão, freio a 60, lote de 20) vieram de uma simulação em FSRS-4.5 com outro desenho. Falta refazê-la em FSRS-6 com toda resposta contando (D2), só escrever (D3), cartões de padrão, reforço e Treino (proposta, seção 9.3). **Recomendação:** a spec fica com esses números até a simulação, e eles só fecham depois dela. |
| 13 | Catálogo de padrões (REV-04, D11b) | O catálogo de 30 padrões (ordem, membros) volta para aprovação. Dentro dele: a) "frequente" no `gen.lista` e no `gen.sufixo` não tem fonte; b) combinações do `prep.art`: as 9 da pesquisa (*al, alla, allo, del, della, nel, nella, sul, dal*) ou as 5 preposições com *il, la, l', i, le*. **Recomendação:** aprovar como está, com a) NVdB *fondamentale* e b) as 5 preposições com *il, la, l', i, le*, deixando *lo* e *gli* para o A2. |
| 14 | *amico* e *medico* (REV-04) | Exceção nomeada dentro do cartão de padrão `pl.co_go`, ou cartão de palavra próprio (leitura literal da D1, "cartão de palavra só para exceções")? **Recomendação:** dentro do padrão: *amici* × *amichi* é a decisão que a regra treina. |
| 15 | Gênero no FSRS (REV-06) | A D2 fala em resposta "digitada", mas o Gênero é escolha e é o formato do próprio cartão. Opções: conta, pela regra "no formato do cartão"; ou não conta, e o Gênero fica sem agendamento. **Recomendação:** conta. A spec já está assim. |
| 16 | Ordem dos padrões novos (REV-23, D4) | A "ordem do catálogo" intercala temas pela unidade do *Dai! 1* (coluna Ordem da proposta) ou apresenta tema por tema? **Recomendação:** intercalando. A spec já está assim. |
| 17 | Membros de `lista` (REV-06) | Um membro (*fatto*) pode entrar pela cota de forma antes de a Revisão apresentar o padrão dele? **Recomendação:** não, só depois. A spec já está assim. |
| 18 | Ritmo dos padrões (REV-23) | Com 1 padrão por dia e o filtro de nível sem efeito (D32), o passato prossimo e o imperativo chegam por volta do 25º dia de Revisão, qualquer que seja a leitura. Opções: aceitar; 1 padrão a cada 2 dias; amarrar ao número de histórias lidas. **Recomendação:** aceitar na v1 e olhar com dados de uso. |
| 19 | Filtro de nível (REV-23) | Sem efeito na v1, porque todo o catálogo é A1 (D32). Opções: implementar já ou só quando entrar conteúdo A2. **Recomendação:** só com o A2 (um codepath a menos). O requisito fica escrito. |
| 20 | Particípio com *essere* (REV-07) | Terminação do particípio que não concorda com o sujeito (*è arrivato* com *lei*): Certo com aviso ou Certo sem aviso? **Recomendação:** com aviso (mostra sem cobrar). A spec já está assim. |
| 21 | Página do trecho (REV-26, D22) | Ela mostra a tradução do parágrafo? Tocar numa palavra abre o verbete? Há "Abrir a história"? **Recomendação:** nada disso na v1: a página só lembra o contexto. |
| 22 | Glosas = Italiano no Palavra (REV-15) | A proposta usa a frase de origem com lacuna e a frase PT alinhada como pista também com Glosas = Italiano, mas a frase PT entrega o sentido que essa Imersão esconde. Opções: a) manter a pista PT (a tradução é sempre PT, TRA-09); b) com Glosas = Italiano, a primeira definição IT com lacuna (como no book atual), e a frase IT com lacuna como dica; c) só a frase IT com lacuna. **Recomendação:** b. A frase PT fica só para a palavra sem glosa com Glosas = Português. Por enquanto, a spec segue a proposta (a). |
| 23 | Imperativo no verbete (DIC-05) | A D11e põe o imperativo como 5º tempo da Conjugação, mas a proposta (12.2, item 13) ainda pergunta se o verbete o mostra. A spec segue a D11e. **Recomendação:** manter. |
| 24 | Créditos e atribuição (AJU-04, DIC-09) | Decidido (2026-10-26 e 2026-10-27): o AJU-04 credita Wikizionario, en.wiktionary, WikDict e NVdB, e o DIC-09 é uma linha fixa, "Fonte: Wikizionario, Wiktionary, WikDict · CC BY-SA". Fica o Morph-it!, que depende de confirmar a licença (CC BY-SA 2.0 ou LGPL) e de medir quanto ele acrescenta depois do en.wiktionary (D19). **Recomendação:** medir antes de pôr o Morph-it! no pipeline e deixá-lo fora se não acrescentar palavras de A1 a B1. Se entrar, entra no AJU-04 e na linha do DIC-09. |
| 25 | Padrão sem página própria (TRE-02) | A proposta diz que um padrão com menos de 10 membros não ganha página. Isso pega o `imper.lista` (9 membros), além do `pl.lista` (1). Opções: limiar menor (menos de 3 membros); só o `pl.lista`; manter 10. **Recomendação:** menos de 3 membros. |
| 26 | Origem do verbete aberto no Treino (SAL-01) | A D29 dá a origem "Revisão" ao verbete aberto na sessão. Num verbete aberto no Treino, a origem é "Revisão" ou "Treino"? **Recomendação:** "Revisão", o nome da aba: uma origem só. A spec já está assim. |
| 27 | Tema fora da Revisão (TRE-08) | Como a lista do Treino mostra que um tema foi tirado da Revisão? Opções: o texto "Fora da Revisão" na linha do tema, no lugar dos exemplos; nada, só o item de Mais opções. **Recomendação:** o texto na linha. É uma exceção, como as da D10. |
| 28 | Mais opções na raiz da aba Revisão | O desenho da proposta põe "⋯" na raiz da aba, sem dizer o que há nele. Opções: atalho para Ajustes › Revisão; sem Mais opções. **Recomendação:** sem Mais opções na raiz. |
| 29 | Aviso com Desfazer nas Salvas (SAL-02) | O aviso com ação do "Já sei" (REV-05) também serviria para "Removida das Salvas. Desfazer" (pedido 2 da proposta ao design system). **Recomendação:** sim, com o mesmo componente e o mesmo tempo de 6 s. |

## 12. O que muda nos books

Divergências entre os books do design e esta spec. A spec vale. Os books serão corrigidos na próxima rodada de design.

### Todos os books

- **Offline (OFF-01, OFF-41):** saem os estados "Sem conexão", "sincroniza depois", "desativado offline" e as mensagens que falam em conexão.
- **Estados novos:** "Preparando o dicionário" (OFF-11), espaço insuficiente (OFF-12), voz italiana ausente (OFF-41), aviso de histórias novas (OFF-24).
- **Barra de abas (NAV-01):** quatro abas, Biblioteca · Dicionário · Revisão · Ajustes, com um ícone novo para Revisão (fora da lista atual do `components-shared.md`). Vale para todo book que desenha a barra: book-biblioteca, book-dicionario, book-revisao e identity.

### book-leitor.html

- **Doca (LEI-01, LEI-07):** "N min restantes", "Menos de 1 min" e "Concluída" viram linha de progresso + "N% lido". O cálculo por rolagem (`p >= 0.99`) vira o cálculo por palavras.
- **Grifo (LEI-06):** sai a duração de 1,5 s. O grifo fica até o próximo toque ou a primeira rolagem.
- **Mais opções (LEI-09):** sai "Guardar para depois". "Relatar erro" abre o e-mail.
- **Conclusão (BIB-02):** a história fica concluída quando o bloco de fim entra na tela.
- **Próxima história (LEI-10):** a regra passa a ser continuação → mesmo nível → nível seguinte, e o card some sem candidata.
- **Palavra sem verbete e lema ambíguo (LEI-02):** faltam o aviso "Sem verbete no dicionário" e a página de escolha.
- **Erro de leitura:** "Verifique a conexão…" vira um erro local. O "Carregando" da tradução sai.

### book-leitor-traducao.html

- **Tradução (TRA-09):** sempre em português, qualquer que seja a Imersão.
- Sai o "sincroniza".

### book-dicionario.html

- **Rótulos (DIC-02, AJU-02):** saem "padrão: italiano" e "Botões, avisos e o app bar ficam sempre em português". Tudo segue a Imersão.
- **Seções (DIC-06):** "Parole correlate" vira "Termini correlati". Entram Parole derivate, Alterati e Da non confondere con.
- **Glosa (DIC-03):** com Glosas = Italiano, a pílula não aparece.
- **Expressão (DIC-07):** sem verbete próprio, abre a página de escolha, e não o verbete da palavra-chave.
- **Raiz da aba (SAL-01, SAL-04):** "Ordenar" (Mais recentes · A–Z) só em Salvas. "Limpar histórico" com diálogo de confirmação. Histórico com uma linha por verbete por dia.
- Saem os estados "Sem conexão" do verbete e da raiz.
- **Conjugação (DIC-05):** entra o Imperativo como 5º tempo.
- **Histórico (SAL-01):** o verbete aberto numa sessão da Revisão ou do Treino tem origem "Revisão". O dia vira às 4h.

### book-biblioteca.html

- **Imersão (AJU-02):** a área "Glosas e tradução" vira "Glosas". Sai o "em aberto" sobre a tradução dividida.
- **Continuar lendo (BIB-03):** mostra a última história em andamento, nunca uma concluída.

### book-revisao.html

- **Lugar (NAV-01, REV-01, DIC-10):** o cartão "Revisão de hoje" sai da raiz do Dicionário e vai para a raiz da aba Revisão, acima da lista do Treino, com quatro estados (com cartões, interrompida, nada vencido, nenhuma salva).
- **Exercícios (REV-04):** nove exercícios. Entram Gênero (2 opções pelo som), Artigo como cartão de padrão digitado, Preposição, Adjetivo, Possessivo, Piacere e Imperativo (com o negativo); sai o Artigo de 4 opções. Cartão de padrão com o rótulo da regra. Verbo regular não tem cartão próprio. Conjugação só com Presente, Passato prossimo e Imperativo.
- **Ajustes › Revisão (AJU-07):** saem os chips de Exercícios e de Tempos da conjugação e a linha "Imagens". O "Por dia" de 0 · 5 · 10 · 15 · 20 (padrão 10) vira 0 · 3 · 5 · 10 (padrão 5). Ficam três itens. A barra da tela ganha a 4ª aba.
- **Imagens (REV-14):** saem a foto da galeria ou da câmera, a variante da pergunta com imagem e a contagem em Ajustes.
- **Agendamento (REV-06, REV-20):** FSRS-6 com toda resposta contando. Limites viram 5 palavras + 2 formas + 1 padrão por dia, freio a 60 vencidos e lotes de 20. A cota deixa de contar "cartões novos de qualquer tipo".
- **Correção (REV-07):** falta de acento no Palavra vira Certo com aviso; "Também é janela" fica sem nota; artigo opcional e conferido; erro fora do alvo é Certo com aviso.
- **Dica (REV-09):** existe também nos cartões de forma, com a regra numa linha.
- **Resposta (REV-10, REV-11, REV-24):** ordem nova; "Contar como certa" na linha do veredito, também em Quase, com "Desfazer"; linha do porquê; "A regra volta em…" no cartão de padrão.
- **Botão único (REV-25):** Não sei · Conferir · Continuar no mesmo lugar.
- **Contador e voltas (REV-21):** "N de M · +K", até 2 voltas por cartão.
- **Reforço e padrão novo (REV-22, REV-23):** a linha de transição do reforço; a página de regra nova e de padrão `lista`.
- **Na história (REV-26):** "Ver o trecho ›" empilha a página só com o parágrafo, em vez de abrir a história.
- **Mais opções (REV-13):** muda entre pergunta e resposta; "Abrir verbete" só na resposta.
- **"Já sei" (REV-05):** aviso com Desfazer.
- **Fim (REV-16):** contagens, palavras novas, padrão mais fraco com "Treinar…", vencidos que sobraram.
- **Acessibilidade (REV-19, ACE-07):** sai o `role="status"` do veredito. Depois de conferir, o foco vai para o veredito, e não para Continuar. Campo com nome acessível e altura que cresce.
- **Treino (TRE-01..09):** telas novas: lista de temas na raiz, página do tema, página da regra (com e sem "Treinar"), escolha de forma, rodada com "N de 10 · +K" e fim da rodada.
- **Dados (REV-17):** saem as tabelas de cartões e de imagens; as respostas viram um log só de inserções.
- **Pedidos ao design system (proposta, 7.4):** barra com 4 abas e ícone; aviso com ação; borda do campo com contraste de 3:1; "Mostrar dica" sem ícone; "Na história" e a página do trecho reusam o componente "Nella storia" do verbete.

### identity.html

- **Capítulos:** saem "Capítulo 2 de 6", "Página 1 de 6" e "Fim do capítulo 1. Continuar no capítulo 2?" (fora de escopo).

### Book de Ajustes (a criar)

- Incluir Dados: Exportar e Importar (AJU-05). Imersão sem onboarding (AJU-03).
- Incluir Revisão, com os três itens do AJU-07, e os créditos do en.wiktionary em Sobre (AJU-04).

