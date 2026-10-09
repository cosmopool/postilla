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

As escolhas marcadas com *(padrão)* seguem a prática comum e não foram discutidas. Revise-as.

| Id | Requisito |
|---|---|
| OFF-20 | Ao abrir o app com rede, ele consulta o manifesto de conteúdo, no máximo uma vez por dia *(padrão)*. |
| OFF-21 | Se houver versão nova, ela é baixada em segundo plano, por qualquer rede *(padrão)*, e o app confere o sha256. |
| OFF-22 | A versão nova é aplicada de forma atômica: ou entra inteira, ou o app continua com a anterior. Um download interrompido ou corrompido é descartado. |
| OFF-23 | A troca nunca acontece com uma história ou verbete aberto. A versão nova vale a partir da próxima abertura do app *(padrão)*. |
| OFF-24 | A atualização não pede confirmação nem mostra aviso *(padrão)*. |

### Dados do usuário

| Id | Requisito |
|---|---|
| OFF-30 | Dados guardados no aparelho: progresso por história, histórias concluídas, última história aberta, histórico de verbetes, palavras e expressões salvas, ajustes de leitura, Imersão, proporção da tradução e dicas de primeiro uso já vistas. |
| OFF-31 | Cada registro tem id estável e data de criação e alteração, para permitir sync numa versão futura sem migração de modelo. |
| OFF-32 | Dados do usuário nunca se perdem por causa de atualização de conteúdo *(padrão)*: |
| | • uma palavra salva guarda um resumo próprio (lema, classe, história de origem) e continua na lista mesmo se o verbete mudar ou sair do dicionário; |
| | • o progresso aponta para história + parágrafo. Se o texto da história mudar, o progresso vai para o parágrafo mais próximo que ainda existe. |
| OFF-33 | Apagar o app apaga os dados. O backup do sistema (iCloud/Google) pode restaurá-los, mas o app não depende dele. |

### Pronúncia

| Id | Requisito |
|---|---|
| OFF-40 | "Ouvir pronúncia" usa a voz de italiano do sistema (TTS, `it-IT`), que funciona offline. |
| OFF-41 | Se o aparelho não tiver voz italiana, o botão fica desativado, com uma explicação de como instalar a voz nos ajustes do sistema. |

### O que isso muda no design atual

Os books do design foram desenhados com o dicionário online. Precisam de revisão:

- **Dicionário:** saem os estados "Sem conexão" do verbete e da raiz da aba ("O verbete completo abre quando a conexão voltar…", "Histórico e Salvas funcionam offline. O resto abre quando a conexão voltar.").
- **Marcador:** sai o "sincroniza depois".
- **Áudio:** sai o "desativado offline". O botão só fica desativado sem voz italiana (OFF-41).
- **Leitor:**
  - "Não foi possível carregar a história. Verifique a conexão…" vira um erro de leitura local, sem falar em conexão;
  - o estado "Carregando" da tradução tende a sumir, porque a tradução é local.
- **Estados novos:** "Preparando o dicionário" (OFF-11), espaço insuficiente (OFF-12), voz italiana ausente (OFF-41).

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
| BIB-02 | Estados da história: nova, em andamento (com linha de progresso e %) ou concluída ("Lida"). |
| BIB-03 | Card "Continuar lendo" com a última história aberta. Some quando há busca ou filtro. |
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
| LEI-01 | Texto só em italiano, com app bar compacta (voltar, título, Aa, Mais opções) e doca (progresso, tempo restante, "Mostrar tradução"). |
| LEI-02 | Tocar numa palavra grifa a palavra e empilha o verbete do lema. Elisões (l'aria, c'è) são um alvo só. Pontuação não responde. |
| LEI-03 | Pressão longa (500 ms) seleciona uma expressão. O usuário arrasta para estender a seleção palavra a palavra, dentro do parágrafo, e ao soltar a expressão abre no dicionário. |
| LEI-04 | Nenhum gesto na história salva. Salvar só pelo marcador do verbete. |
| LEI-05 | Toque fora das palavras, pinça e toque duplo não têm efeito próprio (o toque duplo conta como um toque). |
| LEI-06 | Ao voltar do verbete, a rolagem é a mesma e a palavra continua grifada. Palavras salvas aparecem com pontilhado. |
| LEI-07 | O progresso é salvo continuamente (história + parágrafo). O tempo restante é arredondado para cima ("Menos de 1 min" abaixo de 1). |
| LEI-08 | Aa: tamanho do texto (5 passos), entrelinha (3 opções) e tema (Claro · Escuro · Sistema, vale para o app todo). As mudanças valem na hora e para todas as histórias. |
| LEI-09 | Mais opções: Guardar para depois · Recomeçar do início · Relatar erro no texto. |
| LEI-10 | Fim da história: contagem de palavras salvas nela (a linha some se for zero), link para Salvas, card "Próxima história" (mesmo nível ou o seguinte, nunca dois acima) e "Voltar à biblioteca". Sem comemoração. |
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

## 6. Dicionário

Campos, origem e transformações: [dictionary.md](dictionary.md).

| Id | Requisito |
|---|---|
| DIC-01 | Verbete monolíngue em italiano, sempre pelo lema: "si siede" abre sedersi. Plurais, formas conjugadas e formas com clítico levam ao lema. |
| DIC-02 | Seções em ordem fixa. Uma seção sem dado não aparece. |
| DIC-03 | A glosa PT fica oculta e um toque revela ou esconde. Ela está sempre fechada ao abrir um verbete. |
| DIC-04 | "Nella storia" mostra a frase da história com a palavra grifada. Tocar nela volta ao trecho. Nos verbos, mostra a forma usada. |
| DIC-05 | Conjugação: um tempo verbal por vez (Presente, Passato prossimo, Imperfetto, Futuro), com a forma usada na história destacada. |
| DIC-06 | Sinônimos, contrários e demais palavras relacionadas podem ser tocados e empilham outro verbete. A pilha tem até 20 verbetes, e cada um guarda a própria rolagem. |
| DIC-07 | Uma expressão abre como verbete. Se ela não tiver verbete próprio, abre o da palavra-chave com a expressão destacada. |
| DIC-08 | App bar do verbete: voltar, Ouvir pronúncia (OFF-40), marcador e Mais opções (copiar, compartilhar, voltar à história, fonte). |
| DIC-09 | Atribuição obrigatória em todo verbete: "Fonte: Wikizionario · CC BY-SA". |
| DIC-10 | Raiz da aba: busca e seletor `Histórico \| Salvas`. Mais opções: ordenar, limpar histórico. |
| DIC-11 | Busca em italiano, com sugestões a cada letra. Encontra lemas e formas flexionadas. Aceita curingas (`?` para uma letra, `*` para várias). Sem resultado, mostra "Você quis dizer". |

## 7. Histórico e Salvas

| Id | Requisito |
|---|---|
| SAL-01 | Todo verbete aberto entra no Histórico, agrupado por dia, com lema, classe e história de origem. |
| SAL-02 | Salvar e remover só pelo marcador (no verbete e nas linhas das listas). Um aviso confirma: "Salva em Dicionário › Salvas" ou "Removida das Salvas". |
| SAL-03 | Uma expressão é salva como uma entrada só. |
| SAL-04 | Salvas mostra as mais recentes primeiro. Estado vazio: "Nenhuma palavra salva ainda". |
| SAL-05 | Uma palavra salva aparece com pontilhado no Leitor e nas listas de palavras relacionadas. |

## 8. Ajustes

O book de Ajustes ainda não existe (`book-ajustes.html` está previsto). Por enquanto, o que está definido:

| Id | Requisito |
|---|---|
| AJU-01 | **Leitura:** tamanho do texto, entrelinha e tema (os mesmos da folha Aa do Leitor). |
| AJU-02 | **Imersão:** quatro áreas, cada uma em Português ou Italiano: Navegação, Rótulos e botões, Dicionário, Glosas e tradução. |
| AJU-03 | Predefinições de Imersão: Iniciante (tudo em português, padrão), Intermediário (dicionário em italiano), Imersão total (tudo em italiano). Qualquer outra combinação é Personalizado. Efeito imediato. |
| AJU-04 | **Sobre:** versão do app, versão do conteúdo (OFF-13) e créditos (Wiktionary CC BY-SA, wiktextract). |

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
- Zoom por pinça, ordenação manual da Biblioteca, prévia ou menu de contexto nos cards.

## 11. Em aberto

Conflitos entre os books do design e definições que faltam.

| # | Tema | Conflito ou lacuna |
|---|---|---|
| 1 | Grifo ao voltar do verbete | Leitor: dura 1,5 s. Dicionário: fica até o próximo toque. |
| 2 | Posição ao abrir o verbete | Leitor: não salva nem restaura a posição. Dicionário: grava história, parágrafo e deslocamento. |
| 3 | Idioma padrão do dicionário | Dicionário: italiano. Biblioteca: Iniciante (tudo em português) é o padrão. |
| 4 | Botões e app bar | Dicionário: sempre em português. Imersão: "Rótulos e botões" podem ficar em italiano. |
| 5 | O que a doca mostra | "N min restantes", "N% lido" ou "Página 1 de 6". |
| 6 | Quando a história conta como concluída | Indefinido (o protótipo usa 99% de rolagem). |
| 7 | "Guardar para depois" | Está no menu do Leitor, sem definição. |
| 8 | Tradução dividida com Glosas = Italiano | Explicitamente em aberto no book da Biblioteca. |
| 9 | Nome da seção | "Parole correlate" (design) ou "Termini correlati" (Wiktionary/Livio). |
| 10 | Seções novas no verbete | Parole derivate, Alterati e Da non confondere con ainda não estão no design. |
| 11 | Glosa PT | Só 5% dos lemas têm. Como preencher o resto (ver [dictionary-pipeline.md](dictionary-pipeline.md#decisões-em-aberto)). |
| 12 | "Relatar erro no texto" | Sem servidor (OFF-03), falta definir para onde vai o relato. |
| 13 | Capítulos e páginas | identity.html usa capítulos e páginas; os outros books, não. |
