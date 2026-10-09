# Postilla: spec funcional

O que o app faz e como se comporta. Esta spec cobre só funcionalidades; aparência, tokens e componentes ficam no design system ([design/](../design/)). Cada requisito tem um id (`OFF-03`) para ser citado em tasks e revisões.

Documentos relacionados:
- [dictionary.md](dictionary.md): campos do verbete e transformações.
- [dictionary-pipeline.md](dictionary-pipeline.md): como o dicionário é gerado e publicado.
- [design/content.md](../design/content.md): textos de exemplo (catálogo, história, verbetes).

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
| OFF-13 | O conteúdo tem uma versão (a data do dump do Wiktionary, mais a versão do catálogo de histórias). Ajustes › Sobre mostra essa versão. |

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
| OFF-30 | Dados guardados no aparelho: progresso por história, histórias concluídas, última história aberta, histórico de verbetes, palavras e expressões salvas, ajustes de leitura, Imersão, proporção da tradução e dicas de primeiro uso já vistas. |
| OFF-31 | Cada registro tem id estável e data de criação e alteração, para permitir sync numa versão futura sem migração de modelo. |
| OFF-32 | Dados do usuário nunca se perdem por causa de atualização de conteúdo: |
| | • uma palavra salva guarda um resumo próprio (lema, classe, história de origem) e continua na lista mesmo se o verbete mudar ou sair do dicionário. Se o verbete sair, tocar na palavra abre a busca com o lema e o "Você quis dizer" (DIC-11); |
| | • o progresso aponta para história + parágrafo. Se o texto da história mudar, o progresso vai para o parágrafo mais próximo que ainda existe. |
| OFF-33 | Apagar o app apaga os dados. O backup do sistema (iCloud/Google) pode restaurá-los, mas o app não depende dele. |
| OFF-34 | Há três bancos separados no aparelho: dados do usuário, histórias e dicionário. Só o banco do usuário é exportado e importado (AJU-05). Atualizar o conteúdo nunca toca o banco do usuário. |

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
| NAV-01 | Três abas: Biblioteca · Dicionário · Ajustes. |
| NAV-02 | O Leitor não é aba. Ele é empilhado a partir da Biblioteca, em tela cheia e sem barra de abas. |
| NAV-03 | O verbete aberto do Leitor é empilhado como página inteira, sem barra de abas. O verbete aberto da aba Dicionário é empilhado dentro da aba, com a barra visível. O dicionário nunca abre em folha ou modal. |
| NAV-04 | O voltar tem o nome da tela anterior ("Voltar à história", "Voltar a finestrino", "Voltar ao Dicionário"). Funcionam o chevron, o gesto de borda e o botão voltar do sistema. |
| NAV-05 | Voltar do Leitor preserva rolagem, busca e filtros da Biblioteca. |
| NAV-06 | Tocar de novo na aba ativa: na Biblioteca, rola ao topo; no Dicionário, volta à raiz. |

## 3. Biblioteca

| Id | Requisito |
|---|---|
| BIB-01 | Catálogo de histórias com título e subtítulo (sempre em italiano, nunca traduzidos), nível (A1–B2), gênero, duração e estado. |
| BIB-02 | Estados da história: nova, em andamento (com linha de progresso e %) ou concluída ("Lida"). A história fica concluída quando o bloco de fim (LEI-10) entra na tela. Não existe botão "Marcar como lida". Reabrir uma concluída pelo card mantém "Lida". Só "Recomeçar do início" (LEI-09) volta a história para em andamento, em 0%. |
| BIB-03 | Card "Continuar lendo" com a última história aberta que ainda está em andamento. Uma história concluída nunca ocupa o card. Sem história em andamento, o card some. Ele também some quando há busca ou filtro. |
| BIB-04 | Ordem fixa: Continuar lendo → todas as histórias (por nível de A1 a B2; no mesmo nível, da mais curta para a mais longa) → concluídas no fim. Não há ordenação manual. |
| BIB-05 | Filtros em chips, em dois grupos (Nível e Gênero): "ou" dentro do grupo, "e" entre grupos. "Limpar filtros" no cabeçalho da lista. |
| BIB-06 | A busca procura em título, subtítulo e gênero, sem diferenciar acento nem maiúscula, e o resultado muda a cada letra. Busca e filtros se somam. |
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
| DIC-05 | Conjugação: um tempo verbal por vez (Presente, Passato prossimo, Imperfetto, Futuro), com a forma usada na história destacada. |
| DIC-06 | As palavras de Sinonimi, Contrari, Parole derivate, Termini correlati, Alterati e Da non confondere con podem ser tocadas e empilham outro verbete. Todas essas seções entram na v1. A pilha tem até 20 verbetes, e cada um guarda a própria rolagem. |
| DIC-07 | Uma expressão abre como verbete. Se ela não tiver verbete próprio, empilha a mesma página de escolha do LEI-02, com uma linha para cada palavra da seleção que tem verbete. |
| DIC-08 | App bar do verbete: voltar, Ouvir pronúncia (OFF-40), marcador e Mais opções (copiar, compartilhar, voltar à história, fonte). |
| DIC-09 | Atribuição obrigatória em todo verbete: "Fonte: Wikizionario · CC BY-SA". |
| DIC-10 | Raiz da aba: busca e seletor `Histórico \| Salvas`. Mais opções: ordenar, limpar histórico. |
| DIC-11 | Busca em italiano, com sugestões a cada letra. Encontra lemas e formas flexionadas. Aceita curingas (`?` para uma letra, `*` para várias). Sem resultado, mostra "Você quis dizer". |

## 7. Histórico e Salvas

| Id | Requisito |
|---|---|
| SAL-01 | Todo verbete aberto entra no Histórico, agrupado por dia, com lema, classe e história de origem. Cada dia tem uma linha por verbete: reabrir move a linha para o topo do dia e atualiza a história de origem. O Histórico não tem limite. "Limpar histórico" pede confirmação num diálogo e não afeta Salvas. |
| SAL-02 | Salvar e remover só pelo marcador (no verbete e nas linhas das listas). Um aviso confirma: "Salva em Dicionário › Salvas" ou "Removida das Salvas". |
| SAL-03 | Uma expressão com verbete próprio é salva como uma entrada só. |
| SAL-04 | Salvas tem duas ordenações: Mais recentes (padrão) e A–Z. A escolha fica salva no aparelho. O Histórico não tem ordenação: é sempre por dia, do mais recente para o mais antigo, e só a aba Salvas mostra "Ordenar". Estado vazio: "Nenhuma palavra salva ainda". |
| SAL-05 | Uma palavra salva aparece com pontilhado no Leitor e nas listas de palavras relacionadas. |

## 8. Ajustes

O book de Ajustes ainda não existe (`book-ajustes.html` está previsto). Por enquanto, o que está definido:

| Id | Requisito |
|---|---|
| AJU-01 | **Leitura:** tamanho do texto, entrelinha e tema (os mesmos da folha Aa do Leitor). |
| AJU-02 | **Imersão:** quatro áreas, cada uma em Português ou Italiano: Navegação, Rótulos e botões, Dicionário, Glosas. Cada área vale para o app todo, sem exceção: o app bar, os botões e os avisos do Dicionário seguem "Rótulos e botões". |
| AJU-03 | Predefinições de Imersão: Iniciante (tudo em português, padrão), Intermediário (dicionário em italiano), Imersão total (tudo em italiano). Qualquer outra combinação é Personalizado. Efeito imediato. Não há onboarding: o app começa em Iniciante sem perguntar, e o usuário muda em Ajustes › Imersão. |
| AJU-04 | **Sobre:** versão do app, versão do conteúdo (OFF-13) e créditos (Wiktionary CC BY-SA, wiktextract). |
| AJU-05 | **Dados:** Exportar e Importar o banco do usuário como um arquivo, pela folha de compartilhar e pelo seletor de arquivos do sistema. O arquivo não inclui histórias nem dicionário. Importar substitui os dados atuais: o app pede confirmação e guarda antes uma cópia automática dos dados atuais, para poder desfazer. |

## 9. Acessibilidade

| Id | Requisito |
|---|---|
| ACE-01 | Com movimento reduzido, as transições ficam instantâneas e as mudanças de estado continuam. |
| ACE-02 | Foco: ao empilhar, vai para o voltar da página nova. Ao desempilhar, volta ao elemento de origem. |
| ACE-03 | No Leitor, o leitor de tela lê por parágrafo. Cada palavra é um botão, navegável pelo rotor de palavras. |
| ACE-04 | Cada metade da tela dividida declara o idioma (`it` / `pt-BR`), para a voz do leitor de tela trocar de língua. |
| ACE-05 | Contagens, estados e mudanças são anunciados. Nenhum estado depende só de cor. |
| ACE-06 | Alvos de toque de 44pt, com a exceção documentada das palavras na coluna de leitura (linhas de 34pt). |

## 10. Fora de escopo

- Conta, login, sync entre aparelhos e qualquer servidor de usuário (v1).
- Gamificação: sequência de dias, XP, troféus, metas e comemorações.
- Áudio da história (narração).
- Busca do Dicionário em português (busca reversa PT → IT).
- Zoom por pinça, ordenação manual da Biblioteca, prévia ou menu de contexto nos cards.
- Capítulos e páginas. Cada história é um texto corrido. Uma obra longa vira várias histórias no catálogo ("Pinocchio, capitolo primo", "capitolo secondo"…).

## 11. Em aberto

Conflitos entre os books do design e definições que faltam.

| # | Tema | Conflito ou lacuna |
|---|---|---|
| 11 | Glosa PT | Decidido: o pipeline baixa um dicionário italiano → português e preenche a glosa a partir dele. Falta escolher a fonte (ver [dictionary-pipeline.md](dictionary-pipeline.md#decisões-em-aberto)). |

## 12. O que muda nos books

Divergências entre os books do design e esta spec. A spec vale. Os books serão corrigidos na próxima rodada de design.

### Todos os books

- **Offline (OFF-01, OFF-41):** saem os estados "Sem conexão", "sincroniza depois", "desativado offline" e as mensagens que falam em conexão.
- **Estados novos:** "Preparando o dicionário" (OFF-11), espaço insuficiente (OFF-12), voz italiana ausente (OFF-41), aviso de histórias novas (OFF-24).

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

### book-biblioteca.html

- **Imersão (AJU-02):** a área "Glosas e tradução" vira "Glosas". Sai o "em aberto" sobre a tradução dividida.
- **Continuar lendo (BIB-03):** mostra a última história em andamento, nunca uma concluída.

### identity.html

- **Capítulos:** saem "Capítulo 2 de 6", "Página 1 de 6" e "Fim do capítulo 1. Continuar no capítulo 2?" (fora de escopo).

### Book de Ajustes (a criar)

- Incluir Dados: Exportar e Importar (AJU-05). Imersão sem onboarding (AJU-03).

