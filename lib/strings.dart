// UI text, one class per Immersion area that has text (ARQ-46).
// When Immersion changes, the app swaps the globals and then notifies Settings.
// The Glosses area has no text: it only decides whether the gloss shows.

/// Navigation: tabs and page titles.
abstract class NavStrings {
  String get library;
  String get dictionary;
  String get settings;
  String get immersion;
  String get reading;
  String get about;
  // slice 1
  String get otherGenre;
  // slice 4
  String get languages;
}

class NavPortuguese implements NavStrings {
  @override
  String get library => 'Biblioteca';
  @override
  String get dictionary => 'Dicionário';
  @override
  String get settings => 'Ajustes';
  @override
  String get immersion => 'Imersão';
  @override
  String get reading => 'Leitura';
  @override
  String get about => 'Sobre';
  // slice 1
  @override
  String get otherGenre => 'Outros';
  // slice 4
  @override
  String get languages => 'Idiomas';
}

class NavItalian implements NavStrings {
  @override
  String get library => 'Biblioteca';
  @override
  String get dictionary => 'Dizionario';
  @override
  String get settings => 'Impostazioni';
  @override
  String get immersion => 'Immersione';
  @override
  String get reading => 'Lettura';
  @override
  String get about => 'Informazioni';
  // slice 1
  @override
  String get otherGenre => 'Altro';
  // slice 4
  @override
  String get languages => 'Lingue';
}

/// Labels and buttons: everything that is not a tab, title or entry section.
abstract class UiStrings {
  String get back;
  String backTo(String place);
  String get backToLibrary;
  String get backToStory;
  String get backToDictionary;
  String get backToSettings;
  String get searchStories;
  String get clearSearch;
  String get level;
  String get genre;
  String get allStories;
  String get results;
  String get clearFilters;
  String storiesCount(int n);
  String get noStoryFound;
  String noStoryForQuery(String q);
  String get noStoryForFilters;
  String minutes(int n);
  String get readingSettings;
  String get textSize;
  String get decreaseText;
  String get increaseText;
  String sizeNofM(int n, int m);
  String get lineSpacing;
  String get compact;
  String get standard;
  String get loose;
  String get theme;
  String get light;
  String get dark;
  String get system;
  String get close;
  String get closeReading;
  String get showTranslation;
  String get hideTranslation;
  String get translationOpened;
  String get translationClosed;
  String get italian;
  String get portuguese;
  String get splitHandle;
  String splitValue(int it);
  String get firstReadHint;
  String get firstSplitHint;
  String get noEntry;
  String get endOfStory;
  String get nextStory;
  String get startReading;
  String get chooseEntry;
  String get moreOptions;
  String get copy;
  String get copied;
  String get source;
  String get showGloss;
  String get glossPrefix;
  String get searchItalian;
  String get cancel;
  String get suggestions;
  String get hintForms;
  String get hintWildcards;
  String noEntryFor(String q);
  String get checkSpelling;
  String get didYouMean;
  String get inTheStory;
  String paragraphN(int n);
  String get presets;
  String get beginner;
  String get intermediate;
  String get fullImmersion;
  String get beginnerSummary;
  String get intermediateSummary;
  String get fullImmersionSummary;
  String customSummary(int n);
  String get byArea;
  String get areaNav;
  String get areaNavHint;
  String get areaUi;
  String get areaDict;
  String get areaDictHint;
  String get areaGloss;
  String get custom;
  String get dictionaryContent;
  String get storiesContent;
  // slice 4
  String get learning;
  String get translationsIn;
  String get languagesNote;
  String get appLabel;
  String versionN(String v);
  String wikiDump(String date);
  String storiesOnDevice(int n);
  String syncCursor(int n);
  String get creditsText;
  String get preparingDictionary;
  String noSpace(int mb);
  String get tryAgain;
  String get contentFailed;
  // slice 1
  String get noTranslation;
  String get arrivedNow;
  String narration(int ms);
  String moreTags(int n);
  // slice 3
  String get adapted;
  String get colText;
  String get publicDomain;
  String get colReading;
  String get colVocabulary;
  String get nvdbSource;
  String get colTranslation;
  String get noNativeYet;
  String get noNativeWhy;
  String get noTranslationHint;
  String get readError;
  String get readErrorText;
  String get waitNativeTitle;
  String get waitNativeText;
  String get waitStoryTitle;
  String get waitStoryText;
  String get readWithoutTranslation;
  String license(String name);
  String coverage(int pct);
  String formLeadsTo(int n);

  // slice 2: Library facets, sheets, empty states and status line
  String get filters;
  String get tagFacet;
  String get levelOne;
  String get levelMany;
  String get genreOne;
  String get genreMany;
  String get tagOne;
  String get tagMany;
  String countOf(int n, String one, String many);
  String facetOneLabel(String facet, String value);
  String facetSeveral(String facet, int n);
  String facetSeveralLabel(String facet, int n);
  String get clear;
  String clearFacet(String one);
  String searchAmong(int n, String many);
  String get marked;
  String othersOf(String many);
  String zeroValues(int n, String one, String many);
  String zeroOf(int total);
  String zeroOfLabel(int total);
  String foundOf(int n, int total, String many);
  String sheetNote(List<String> facets, bool search);
  String noValueWith(String one, String q);
  String accentTip(String one);
  String seeStories(int n);
  String get otherGenre;
  String noneOfFiltered(int n, String q);
  String backToFiltered(int n);
  String showsWithQuery(int n, String q);
  String storiesOnDeviceLine(int n);
  String newStories(int n);
  String arrived(int n);
  String get unknownFormat;
}

class UiPortuguese implements UiStrings {
  @override
  String get back => 'Voltar';
  @override
  String backTo(String place) => 'Voltar a $place';
  @override
  String get backToLibrary => 'Voltar à biblioteca';
  @override
  String get backToStory => 'Voltar à história';
  @override
  String get backToDictionary => 'Voltar ao Dicionário';
  @override
  String get backToSettings => 'Voltar a Ajustes';
  @override
  String get searchStories => 'Buscar histórias';
  @override
  String get clearSearch => 'Limpar busca';
  @override
  String get level => 'Nível';
  @override
  String get genre => 'Gênero';
  @override
  String get allStories => 'Todas as histórias';
  @override
  String get results => 'Resultados';
  @override
  String get clearFilters => 'Limpar filtros';
  @override
  String storiesCount(int n) => n == 1 ? '1 história' : '$n histórias';
  @override
  String get noStoryFound => 'Nenhuma história encontrada';
  @override
  String noStoryForQuery(String q) => 'Nada com “$q”. Tente outra palavra.';
  @override
  String get noStoryForFilters => 'Nenhuma história do aparelho tem esses filtros agora.';
  @override
  String minutes(int n) => '$n min';
  @override
  String get readingSettings => 'Ajustes de leitura';
  @override
  String get textSize => 'Tamanho do texto';
  @override
  String get decreaseText => 'Diminuir texto';
  @override
  String get increaseText => 'Aumentar texto';
  @override
  String sizeNofM(int n, int m) => 'Tamanho $n de $m';
  @override
  String get lineSpacing => 'Entrelinha';
  @override
  String get compact => 'Compacta';
  @override
  String get standard => 'Padrão';
  @override
  String get loose => 'Ampla';
  @override
  String get theme => 'Tema';
  @override
  String get light => 'Claro';
  @override
  String get dark => 'Escuro';
  @override
  String get system => 'Sistema';
  @override
  String get close => 'Fechar';
  @override
  String get closeReading => 'Fechar ajustes';
  @override
  String get showTranslation => 'Mostrar tradução';
  @override
  String get hideTranslation => 'Ocultar tradução';
  @override
  String get translationOpened => 'Tradução aberta. Italiano em cima, português embaixo.';
  @override
  String get translationClosed => 'Tradução oculta.';
  @override
  String get italian => 'Italiano';
  @override
  String get portuguese => 'Português';
  @override
  String get splitHandle => 'Dividir italiano e português';
  @override
  String splitValue(int it) => 'Italiano $it%, português ${100 - it}%';
  @override
  String get firstReadHint => 'Toque numa palavra para abrir o dicionário.';
  @override
  String get firstSplitHint =>
      'Toque numa palavra para abrir o dicionário. Toque entre as palavras ou no português para ver a frase.';
  @override
  String get noEntry => 'Sem verbete no dicionário';
  @override
  String get endOfStory => 'Fim da história';
  @override
  String get nextStory => 'Próxima história';
  @override
  String get startReading => 'Começar a ler';
  @override
  String get chooseEntry => 'Qual verbete?';
  @override
  String get moreOptions => 'Mais opções';
  @override
  String get copy => 'Copiar';
  @override
  String get copied => 'Copiado';
  @override
  String get source => 'Fonte';
  @override
  String get showGloss => 'Mostrar tradução';
  @override
  String get glossPrefix => 'Tradução: ';
  @override
  String get searchItalian => 'Buscar em italiano';
  @override
  String get cancel => 'Cancelar';
  @override
  String get suggestions => 'Sugestões';
  @override
  String get hintForms => 'Formas da história levam ao lema: si siede abre sedersi.';
  @override
  String get hintWildcards => 'Use ? para uma letra e * para várias: fin*ino.';
  @override
  String noEntryFor(String q) => 'Nenhum verbete para “$q”';
  @override
  String get checkSpelling => 'Confira a grafia. Plurais e formas conjugadas também funcionam.';
  @override
  String get didYouMean => 'Você quis dizer';
  @override
  String get inTheStory => 'nella storia';
  @override
  String paragraphN(int n) => 'Parágrafo $n';
  @override
  String get presets => 'Predefinições';
  @override
  String get beginner => 'Iniciante';
  @override
  String get intermediate => 'Intermediário';
  @override
  String get fullImmersion => 'Imersão total';
  @override
  String get beginnerSummary => 'Tudo em português. Só a história fica em italiano.';
  @override
  String get intermediateSummary => 'Navegação em português, dicionário em italiano.';
  @override
  String get fullImmersionSummary => 'Tudo em italiano, inclusive abas e menus.';
  @override
  String customSummary(int n) => 'Personalizado · $n de 4 áreas em italiano.';
  @override
  String get byArea => 'Por área';
  @override
  String get areaNav => 'Navegação';
  @override
  String get areaNavHint => ' · abas e menus';
  @override
  String get areaUi => 'Rótulos e botões';
  @override
  String get areaDict => 'Dicionário';
  @override
  String get areaDictHint => ' · seções do verbete';
  @override
  String get areaGloss => 'Glosas';
  @override
  String get custom => 'Personalizado';
  @override
  String get dictionaryContent => 'Dicionário';
  @override
  String get storiesContent => 'Histórias';
  // slice 4
  @override
  String get learning => 'Aprendo';
  @override
  String get translationsIn => 'Traduções em';
  @override
  String get languagesNote =>
      'Ao trocar, as histórias no novo idioma são baixadas na próxima visita à Biblioteca. Você continua lendo enquanto isso.';
  @override
  String get appLabel => 'App';
  @override
  String versionN(String v) => 'Versão $v';
  @override
  String wikiDump(String date) => 'Wikizionario de $date';
  @override
  String storiesOnDevice(int n) => '$n no aparelho';
  @override
  String syncCursor(int n) => 'Sincronização $n';
  @override
  String get creditsText =>
      'Dicionário: Wikizionario, en.wiktionary e WikDict, CC BY-SA. Frequência: NVdB, De Mauro 2016. '
      'Extração: wiktextract e kaikki. Fontes Literata, Newsreader e Noto Serif (OFL). Ícones Lucide (ISC).';
  @override
  String get preparingDictionary => 'Preparando o dicionário';
  @override
  String noSpace(int mb) => 'Falta espaço no aparelho. O dicionário precisa de $mb MB livres.';
  @override
  String get tryAgain => 'Tentar de novo';
  @override
  String get contentFailed => 'Não foi possível preparar o dicionário.';
  // slice 1
  @override
  String get noTranslation => 'Sem tradução';
  @override
  String get arrivedNow => 'Chegou agora';
  @override
  String narration(int ms) => 'narração de ${ms ~/ 60000} min ${ms ~/ 1000 % 60} s';
  @override
  String moreTags(int n) => 'e mais $n';
  // slice 3
  @override
  String get adapted => 'adaptado';
  @override
  String get colText => 'Texto';
  @override
  String get publicDomain => 'Domínio público';
  @override
  String get colReading => 'Leitura';
  @override
  String get colVocabulary => 'Vocabulário';
  @override
  String get nvdbSource => 'Nuovo vocabolario di base, De Mauro (NVdB)';
  @override
  String get colTranslation => 'Tradução';
  @override
  String get noNativeYet => 'Ainda não existe em português';
  @override
  String get noNativeWhy => 'Esta história foi publicada antes das traduções em português.';
  @override
  String get noTranslationHint => 'Esta história ainda não tem tradução em português';
  @override
  String get readError => 'Não foi possível abrir esta história';
  @override
  String get readErrorText => 'Escolha outra na biblioteca.';
  @override
  String get waitNativeTitle => 'O português ainda está chegando';
  @override
  String get waitNativeText => 'Você trocou o idioma das traduções. O italiano desta história já está aqui; quando a tradução terminar de baixar, a história abre sozinha.';
  @override
  String get waitStoryTitle => 'Esta história ainda está chegando';
  @override
  String get waitStoryText => 'Você trocou de idioma. Quando os arquivos terminarem de baixar, ela abre sozinha.';
  @override
  String get readWithoutTranslation => 'Ler sem tradução';
  @override
  String license(String name) => 'Licença $name';
  @override
  String coverage(int pct) => '$pct% das palavras são do vocabulário básico';
  @override
  String formLeadsTo(int n) => 'Esta forma leva a ${n >= 2 && n <= 10 ? const ['duas', 'três', 'quatro', 'cinco', 'seis', 'sete', 'oito', 'nove', 'dez'][n - 2] : n} palavras.';

  // slice 2
  @override
  String get filters => 'Filtros';
  @override
  String get tagFacet => 'Tema';
  @override
  String get levelOne => 'nível';
  @override
  String get levelMany => 'níveis';
  @override
  String get genreOne => 'gênero';
  @override
  String get genreMany => 'gêneros';
  @override
  String get tagOne => 'tema';
  @override
  String get tagMany => 'temas';
  @override
  String countOf(int n, String one, String many) => '$n ${n == 1 ? one : many}';
  @override
  String facetOneLabel(String facet, String value) => '$facet: $value';
  @override
  String facetSeveral(String facet, int n) => '$facet · $n';
  @override
  String facetSeveralLabel(String facet, int n) => '$facet, $n selecionados';
  @override
  String get clear => 'Limpar';
  @override
  String clearFacet(String one) => 'Limpar $one';
  @override
  String searchAmong(int n, String many) => 'Buscar entre $n $many';
  @override
  String get marked => 'Marcados';
  @override
  String othersOf(String many) => 'Outros $many';
  @override
  String zeroValues(int n, String one, String many) => '${countOf(n, one, many)} sem histórias com esses filtros';
  @override
  String zeroOf(int total) => '0 de $total';
  @override
  String zeroOfLabel(int total) => '0 de $total histórias: nenhuma com os outros filtros';
  @override
  String foundOf(int n, int total, String many) => '$n de $total $many';
  @override
  String sheetNote(List<String> facets, bool search) {
    final parts = [
      if (facets.length == 1) 'o filtro de ${facets.first}',
      if (facets.length > 1) 'os filtros de ${facets.join(' e ')}',
      if (search) 'a busca',
    ];
    return 'Números contam ${parts.join(' e ')}.';
  }

  @override
  String noValueWith(String one, String q) => 'Nenhum $one com “$q”.';
  @override
  String accentTip(String one) => 'Sem acento e sem maiúsculas: “sicilia” acha Sicília. A busca olha só os nomes de $one.';
  @override
  String seeStories(int n) => 'Ver ${storiesCount(n)}';
  @override
  String get otherGenre => 'Outros';
  @override
  String noneOfFiltered(int n, String q) =>
      n == 1 ? 'A história filtrada não fala de “$q”.' : 'Nenhuma das $n histórias filtradas fala de “$q”.';
  @override
  String backToFiltered(int n) => n == 1 ? 'Volta à história filtrada' : 'Volta às $n histórias filtradas';
  @override
  String showsWithQuery(int n, String q) => 'Mostra ${storiesCount(n)} com “$q”';
  @override
  String storiesOnDeviceLine(int n) => '${storiesCount(n)} no aparelho';
  @override
  String newStories(int n) => n == 1 ? '1 história nova' : '$n histórias novas';
  @override
  String arrived(int n) => n == 1 ? 'chegou' : 'chegaram';
  @override
  String get unknownFormat => 'Há histórias novas que esta versão do app não abre.';
}

class UiItalian implements UiStrings {
  @override
  String get back => 'Indietro';
  @override
  String backTo(String place) => 'Torna a $place';
  @override
  String get backToLibrary => 'Torna alla biblioteca';
  @override
  String get backToStory => 'Torna alla storia';
  @override
  String get backToDictionary => 'Torna al Dizionario';
  @override
  String get backToSettings => 'Torna alle Impostazioni';
  @override
  String get searchStories => 'Cerca storie';
  @override
  String get clearSearch => 'Cancella ricerca';
  @override
  String get level => 'Livello';
  @override
  String get genre => 'Genere';
  @override
  String get allStories => 'Tutte le storie';
  @override
  String get results => 'Risultati';
  @override
  String get clearFilters => 'Togli i filtri';
  @override
  String storiesCount(int n) => n == 1 ? '1 storia' : '$n storie';
  @override
  String get noStoryFound => 'Nessuna storia trovata';
  @override
  String noStoryForQuery(String q) => 'Niente con «$q». Prova un’altra parola.';
  @override
  String get noStoryForFilters => 'Nessuna storia sul dispositivo ha questi filtri ora.';
  @override
  String minutes(int n) => '$n min';
  @override
  String get readingSettings => 'Impostazioni di lettura';
  @override
  String get textSize => 'Dimensione del testo';
  @override
  String get decreaseText => 'Riduci il testo';
  @override
  String get increaseText => 'Ingrandisci il testo';
  @override
  String sizeNofM(int n, int m) => 'Dimensione $n di $m';
  @override
  String get lineSpacing => 'Interlinea';
  @override
  String get compact => 'Compatta';
  @override
  String get standard => 'Normale';
  @override
  String get loose => 'Ampia';
  @override
  String get theme => 'Tema';
  @override
  String get light => 'Chiaro';
  @override
  String get dark => 'Scuro';
  @override
  String get system => 'Sistema';
  @override
  String get close => 'Chiudi';
  @override
  String get closeReading => 'Chiudi le impostazioni';
  @override
  String get showTranslation => 'Mostra traduzione';
  @override
  String get hideTranslation => 'Nascondi traduzione';
  @override
  String get translationOpened => 'Traduzione aperta. Italiano sopra, portoghese sotto.';
  @override
  String get translationClosed => 'Traduzione nascosta.';
  @override
  String get italian => 'Italiano';
  @override
  String get portuguese => 'Portoghese';
  @override
  String get splitHandle => 'Dividi italiano e portoghese';
  @override
  String splitValue(int it) => 'Italiano $it%, portoghese ${100 - it}%';
  @override
  String get firstReadHint => 'Tocca una parola per aprire il dizionario.';
  @override
  String get firstSplitHint =>
      'Tocca una parola per aprire il dizionario. Tocca tra le parole o il portoghese per vedere la frase.';
  @override
  String get noEntry => 'Nessuna voce nel dizionario';
  @override
  String get endOfStory => 'Fine della storia';
  @override
  String get nextStory => 'Prossima storia';
  @override
  String get startReading => 'Inizia a leggere';
  @override
  String get chooseEntry => 'Quale voce?';
  @override
  String get moreOptions => 'Altre opzioni';
  @override
  String get copy => 'Copia';
  @override
  String get copied => 'Copiato';
  @override
  String get source => 'Fonte';
  @override
  String get showGloss => 'Mostra traduzione';
  @override
  String get glossPrefix => 'Traduzione: ';
  @override
  String get searchItalian => 'Cerca in italiano';
  @override
  String get cancel => 'Annulla';
  @override
  String get suggestions => 'Suggerimenti';
  @override
  String get hintForms => 'Le forme della storia portano al lemma: si siede apre sedersi.';
  @override
  String get hintWildcards => 'Usa ? per una lettera e * per più lettere: fin*ino.';
  @override
  String noEntryFor(String q) => 'Nessuna voce per «$q»';
  @override
  String get checkSpelling => 'Controlla l’ortografia. Funzionano anche plurali e forme coniugate.';
  @override
  String get didYouMean => 'Forse cercavi';
  @override
  String get inTheStory => 'nella storia';
  @override
  String paragraphN(int n) => 'Paragrafo $n';
  @override
  String get presets => 'Preimpostazioni';
  @override
  String get beginner => 'Principiante';
  @override
  String get intermediate => 'Intermedio';
  @override
  String get fullImmersion => 'Immersione totale';
  @override
  String get beginnerSummary => 'Tutto in portoghese. Solo la storia resta in italiano.';
  @override
  String get intermediateSummary => 'Navigazione in portoghese, dizionario in italiano.';
  @override
  String get fullImmersionSummary => 'Tutto in italiano, anche schede e menu.';
  @override
  String customSummary(int n) => 'Personalizzato · $n aree su 4 in italiano.';
  @override
  String get byArea => 'Per area';
  @override
  String get areaNav => 'Navigazione';
  @override
  String get areaNavHint => ' · schede e menu';
  @override
  String get areaUi => 'Etichette e pulsanti';
  @override
  String get areaDict => 'Dizionario';
  @override
  String get areaDictHint => ' · sezioni della voce';
  @override
  String get areaGloss => 'Glosse';
  @override
  String get custom => 'Personalizzato';
  @override
  String get dictionaryContent => 'Dizionario';
  @override
  String get storiesContent => 'Storie';
  // slice 4
  @override
  String get learning => 'Imparo';
  @override
  String get translationsIn => 'Traduzioni in';
  @override
  String get languagesNote =>
      'Cambiando, le storie nella nuova lingua si scaricano alla prossima visita alla Biblioteca. Intanto continui a leggere.';
  @override
  String get appLabel => 'App';
  @override
  String versionN(String v) => 'Versione $v';
  @override
  String wikiDump(String date) => 'Wikizionario del $date';
  @override
  String storiesOnDevice(int n) => '$n sul dispositivo';
  @override
  String syncCursor(int n) => 'Sincronizzazione $n';
  @override
  String get creditsText =>
      'Dizionario: Wikizionario, en.wiktionary e WikDict, CC BY-SA. Frequenza: NVdB, De Mauro 2016. '
      'Estrazione: wiktextract e kaikki. Font Literata, Newsreader e Noto Serif (OFL). Icone Lucide (ISC).';
  @override
  String get preparingDictionary => 'Preparazione del dizionario';
  @override
  String noSpace(int mb) => 'Manca spazio sul dispositivo. Il dizionario richiede $mb MB liberi.';
  @override
  String get tryAgain => 'Riprova';
  @override
  String get contentFailed => 'Impossibile preparare il dizionario.';
  // slice 1
  @override
  String get noTranslation => 'Senza traduzione';
  @override
  String get arrivedNow => 'Appena arrivata';
  @override
  String narration(int ms) => 'narrazione di ${ms ~/ 60000} min ${ms ~/ 1000 % 60} s';
  @override
  String moreTags(int n) => 'e altri $n';
  // slice 3
  @override
  String get adapted => 'adattato';
  @override
  String get colText => 'Testo';
  @override
  String get publicDomain => 'Pubblico dominio';
  @override
  String get colReading => 'Lettura';
  @override
  String get colVocabulary => 'Vocabolario';
  @override
  String get nvdbSource => 'Nuovo vocabolario di base, De Mauro (NVdB)';
  @override
  String get colTranslation => 'Traduzione';
  @override
  String get noNativeYet => 'Non esiste ancora in portoghese';
  @override
  String get noNativeWhy => 'Questa storia è stata pubblicata prima delle traduzioni in portoghese.';
  @override
  String get noTranslationHint => 'Questa storia non ha ancora una traduzione in portoghese';
  @override
  String get readError => 'Impossibile aprire questa storia';
  @override
  String get readErrorText => 'Scegline un’altra nella biblioteca.';
  @override
  String get waitNativeTitle => 'Il portoghese sta ancora arrivando';
  @override
  String get waitNativeText => 'Hai cambiato la lingua delle traduzioni. L’italiano di questa storia è già qui; quando la traduzione avrà finito di scaricarsi, la storia si aprirà da sola.';
  @override
  String get waitStoryTitle => 'Questa storia sta ancora arrivando';
  @override
  String get waitStoryText => 'Hai cambiato lingua. Quando i file avranno finito di scaricarsi, si aprirà da sola.';
  @override
  String get readWithoutTranslation => 'Leggi senza traduzione';
  @override
  String license(String name) => 'Licenza $name';
  @override
  String coverage(int pct) => 'Il $pct% delle parole è del vocabolario di base';
  @override
  String formLeadsTo(int n) => 'Questa forma porta a ${n >= 2 && n <= 10 ? const ['due', 'tre', 'quattro', 'cinque', 'sei', 'sette', 'otto', 'nove', 'dieci'][n - 2] : n} parole.';

  // slice 2
  @override
  String get filters => 'Filtri';
  @override
  String get tagFacet => 'Tema';
  @override
  String get levelOne => 'livello';
  @override
  String get levelMany => 'livelli';
  @override
  String get genreOne => 'genere';
  @override
  String get genreMany => 'generi';
  @override
  String get tagOne => 'tema';
  @override
  String get tagMany => 'temi';
  @override
  String countOf(int n, String one, String many) => '$n ${n == 1 ? one : many}';
  @override
  String facetOneLabel(String facet, String value) => '$facet: $value';
  @override
  String facetSeveral(String facet, int n) => '$facet · $n';
  @override
  String facetSeveralLabel(String facet, int n) => '$facet, $n selezionati';
  @override
  String get clear => 'Togli';
  @override
  String clearFacet(String one) => 'Togli $one';
  @override
  String searchAmong(int n, String many) => 'Cerca tra $n $many';
  @override
  String get marked => 'Selezionati';
  @override
  String othersOf(String many) => 'Altri $many';
  @override
  String zeroValues(int n, String one, String many) => '${countOf(n, one, many)} senza storie con questi filtri';
  @override
  String zeroOf(int total) => '0 su $total';
  @override
  String zeroOfLabel(int total) => '0 su $total storie: nessuna con gli altri filtri';
  @override
  String foundOf(int n, int total, String many) => '$n su $total $many';
  @override
  String sheetNote(List<String> facets, bool search) {
    final parts = [
      if (facets.length == 1) 'il filtro ${facets.first}',
      if (facets.length > 1) 'i filtri ${facets.join(' e ')}',
      if (search) 'la ricerca',
    ];
    return 'I numeri contano ${parts.join(' e ')}.';
  }

  @override
  String noValueWith(String one, String q) => 'Nessun $one con «$q».';
  @override
  String accentTip(String one) => 'Senza accenti né maiuscole: «sicilia» trova Sicilia. La ricerca guarda solo i nomi.';
  @override
  String seeStories(int n) => 'Mostra ${storiesCount(n)}';
  @override
  String get otherGenre => 'Altro';
  @override
  String noneOfFiltered(int n, String q) =>
      n == 1 ? 'La storia filtrata non parla di «$q».' : 'Nessuna delle $n storie filtrate parla di «$q».';
  @override
  String backToFiltered(int n) => n == 1 ? 'Torna alla storia filtrata' : 'Torna alle $n storie filtrate';
  @override
  String showsWithQuery(int n, String q) => 'Mostra ${storiesCount(n)} con «$q»';
  @override
  String storiesOnDeviceLine(int n) => '${storiesCount(n)} sul dispositivo';
  @override
  String newStories(int n) => n == 1 ? '1 storia nuova' : '$n storie nuove';
  @override
  String arrived(int n) => n == 1 ? 'è arrivata' : 'sono arrivate';
  @override
  String get unknownFormat => 'Ci sono storie nuove che questa versione dell’app non apre.';
}

/// Dictionary: labels of the entry sections (DIC-02).
abstract class DictStrings {
  String get meanings;
  String get inTheStory;
  String get inflection;
  String get conjugation;
  String get etymology;
  String get synonyms;
  String get antonyms;
  String get derived;
  String get related;
  String get altered;
  String get confusables;
  String get singular;
  String get plural;
  String get person;
  String get form;
  String get tense;
  String get indicative;
  String get imperative;
}

class DictPortuguese implements DictStrings {
  @override
  String get meanings => 'Significados';
  @override
  String get inTheStory => 'Na história';
  @override
  String get inflection => 'Flexão';
  @override
  String get conjugation => 'Conjugação';
  @override
  String get etymology => 'Etimologia';
  @override
  String get synonyms => 'Sinônimos';
  @override
  String get antonyms => 'Antônimos';
  @override
  String get derived => 'Palavras derivadas';
  @override
  String get related => 'Termos relacionados';
  @override
  String get altered => 'Alterados';
  @override
  String get confusables => 'Não confundir com';
  @override
  String get singular => 'singular';
  @override
  String get plural => 'plural';
  @override
  String get person => 'pessoa';
  @override
  String get form => 'forma';
  @override
  String get tense => 'Tempo verbal';
  @override
  String get indicative => 'Indicativo';
  @override
  String get imperative => 'Imperativo';
}

class DictItalian implements DictStrings {
  @override
  String get meanings => 'Significati';
  @override
  String get inTheStory => 'Nella storia';
  @override
  String get inflection => 'Flessione';
  @override
  String get conjugation => 'Coniugazione';
  @override
  String get etymology => 'Etimologia';
  @override
  String get synonyms => 'Sinonimi';
  @override
  String get antonyms => 'Contrari';
  @override
  String get derived => 'Parole derivate';
  @override
  String get related => 'Termini correlati';
  @override
  String get altered => 'Alterati';
  @override
  String get confusables => 'Da non confondere con';
  @override
  String get singular => 'singolare';
  @override
  String get plural => 'plurale';
  @override
  String get person => 'persona';
  @override
  String get form => 'forma';
  @override
  String get tense => 'Tempo verbale';
  @override
  String get indicative => 'Indicativo';
  @override
  String get imperative => 'Imperativo';
}

NavStrings nav = NavPortuguese();
UiStrings ui = UiPortuguese();
DictStrings dict = DictPortuguese();
