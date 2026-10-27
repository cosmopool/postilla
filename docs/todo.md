[x] retirar progresso? ele nao me parece algo tao importante assim e causa bastante problema com a logica
    → sai da v1 e entra na v1.1 (LEI-07, BIB-02, BIB-03; ver [roadmap.md](roadmap.md)).
[x] se continuar com o progresso de leitura, quebrar a historia em paragrafos (a ui nao precisa renderizar os paragrafor separados) para deixar mais facil de trackear o progresso.
    → os parágrafos vêm do formato-fonte: um `.txt` por história, com cabeçalho `chave: valor` e blocos IT e PT, uma frase por linha. O progresso aponta para o parágrafo (ARQ-37).
[x] paginar historia?
    → não: continua fora de escopo (§10 da spec, "Capítulos e páginas").
[x] pipeline tem que ser em C ou Zig (conflita com o ARQ-02, que diz Python; D23: decidir junto com o pipeline todo, e a etapa 5b de traços de treino segue o que for adotado. ver architecture.md seção 12 e dictionary-pipeline.md, decisões em aberto)
    → Zig 0.17, com as dependências pelo package manager do Zig (ARQ-02). Fecha a D23.
