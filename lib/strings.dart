// Textos de interface, uma classe por área da Imersão que tem texto (ARQ-46).
// Ao mudar a Imersão, o app troca os globais e então notifica os Settings.
// A área Glosas não tem texto: só decide se a glosa aparece.

/// Navegação: abas e títulos de página.
abstract class NavStrings {
  String get library;
  String get dictionary;
  String get settings;
  String get immersion;
  String get reading;
  String get about;
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
}

/// Rótulos e botões: tudo que não é aba, título nem seção do verbete.
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
  String get version;
  String get dictionaryContent;
  String get storiesContent;
  String get credits;
  String get preparingDictionary;
  String noSpace(int mb);
  String get tryAgain;
  String get contentFailed;
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
  String get noStoryForFilters => 'Nada com esses filtros. Tire um chip ou limpe todos.';
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
  String get version => 'Versão do app';
  @override
  String get dictionaryContent => 'Dicionário';
  @override
  String get storiesContent => 'Histórias';
  @override
  String get credits => 'Créditos';
  @override
  String get preparingDictionary => 'Preparando o dicionário';
  @override
  String noSpace(int mb) => 'Falta espaço no aparelho. O dicionário precisa de $mb MB livres.';
  @override
  String get tryAgain => 'Tentar de novo';
  @override
  String get contentFailed => 'Não foi possível preparar o dicionário.';
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
  String get noStoryForFilters => 'Niente con questi filtri. Togline uno o toglili tutti.';
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
  String get version => 'Versione dell’app';
  @override
  String get dictionaryContent => 'Dizionario';
  @override
  String get storiesContent => 'Storie';
  @override
  String get credits => 'Crediti';
  @override
  String get preparingDictionary => 'Preparazione del dizionario';
  @override
  String noSpace(int mb) => 'Manca spazio sul dispositivo. Il dizionario richiede $mb MB liberi.';
  @override
  String get tryAgain => 'Riprova';
  @override
  String get contentFailed => 'Impossibile preparare il dizionario.';
}

/// Dicionário: rótulos das seções do verbete (DIC-02).
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
