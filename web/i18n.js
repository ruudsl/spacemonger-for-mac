// Lightweight i18n for the static landing page: auto-detects the browser
// language, offers a switcher, and remembers the choice. All 15 app languages.
(function () {
  "use strict";

  var LANGS = [
    ["en", "English"], ["nl", "Nederlands"], ["fr", "Français"], ["de", "Deutsch"],
    ["it", "Italiano"], ["pl", "Polski"], ["ru", "Русский"], ["es", "Español"],
    ["pt-PT", "Português"], ["sv", "Svenska"], ["tr", "Türkçe"], ["uk", "Українська"],
    ["zh-Hans", "简体中文"], ["zh-Hant", "繁體中文"], ["ja", "日本語"]
  ];

  var DICT = {
    en: {
      nav_features: "Features", nav_screenshots: "Screenshots", nav_download: "Download",
      hero_find: "Find it. ", hero_free: "Free it.",
      tagline: "See exactly what's filling your Mac's disk as an interactive <strong>sunburst</strong> or <strong>treemap</strong>, and reclaim the space — quickly and safely.",
      cta_download: "Download for macOS", cta_source: "View source",
      meta_default: "Free & open source · macOS 13+ · Apple Silicon & Intel",
      meta_latest: "Latest: v%v · Free & open source · macOS 13+ · Apple Silicon & Intel",
      os_hint: "Looks like you're not on a Mac — SpaceMonger is a macOS app.",
      shot_sunburst: "The sunburst map — ring size is proportional to on-disk usage.",
      shot_treemap: "Or a cushion-shaded treemap — switch layouts in one click.",
      features_title: "Everything you need to clean up your disk",
      f1_t: "🌅 Sunburst & treemap", f1_d: "Two interactive maps. Zoom in/out, hover for details, colour by folder, file type or depth.",
      f2_t: "⚡ Fast, concurrent scans", f2_d: "Multi-core measurement of real on-disk sizes, with live progress and cancel.",
      f3_t: "🗑️ The Collector", f3_d: "Drag files in, then move them all to the Trash at once. Safety stoppers protect system files.",
      f4_t: "🔒 System & hidden space", f4_d: "Full Disk Access flow, administrator scan, and local snapshot / purgeable cleanup.",
      f5_t: "🎯 Focus & filters", f5_d: "Highlight files by name, type or size. Exclude patterns like <code>node_modules</code>.",
      f6_t: "💾 Save & compare", f6_d: "Save scans, re-open them (incl. <code>.gpscan</code>), and diff two scans.",
      f7_t: "👁️ Quick Look & Open With", f7_d: "Preview with Space, reveal in Finder, copy path, open in any app.",
      f8_t: "🌍 15 languages", f8_d: "English, Nederlands, Deutsch, Français, 日本語, 简体中文 and more.",
      f9_t: "🛡️ Private by design", f9_d: "Reads only file metadata — names & sizes. Nothing leaves your Mac. No analytics.",
      dl_title: "Ready to reclaim some space?", dl_sub: "Free, open source, and notarized for macOS.",
      dl_fine: "Requires macOS 13 Ventura or newer. If the app is opened the first time and macOS warns it's from an unidentified developer, right-click the app ▸ <em>Open</em>.",
      foot_lic: "MIT licensed"
    },
    nl: {
      nav_features: "Functies", nav_screenshots: "Schermafbeeldingen", nav_download: "Download",
      hero_find: "Vind het. ", hero_free: "Maak het vrij.",
      tagline: "Zie precies wat de schijf van je Mac vult, als een interactieve <strong>sunburst</strong> of <strong>treemap</strong>, en win de ruimte terug — snel en veilig.",
      cta_download: "Download voor macOS", cta_source: "Broncode bekijken",
      meta_default: "Gratis & open source · macOS 13+ · Apple Silicon & Intel",
      meta_latest: "Nieuwste: v%v · Gratis & open source · macOS 13+ · Apple Silicon & Intel",
      os_hint: "Het lijkt erop dat je niet op een Mac zit — SpaceMonger is een macOS-app.",
      shot_sunburst: "De sunburst — de ringgrootte is evenredig aan het schijfgebruik.",
      shot_treemap: "Of een treemap met cushion-shading — wissel met één klik.",
      features_title: "Alles om je schijf op te ruimen",
      f1_t: "🌅 Sunburst & treemap", f1_d: "Twee interactieve kaarten. In-/uitzoomen, hover voor details, kleuren op map, bestandstype of diepte.",
      f2_t: "⚡ Snelle, parallelle scans", f2_d: "Multi-core meting van echte schijfgroottes, met live voortgang en annuleren.",
      f3_t: "🗑️ De verzamelaar", f3_d: "Sleep bestanden erin en verplaats ze in één keer naar de prullenmand. Beveiligingen beschermen systeembestanden.",
      f4_t: "🔒 Systeem- & verborgen ruimte", f4_d: "Full Disk Access-flow, beheerdersscan en opruimen van lokale momentopnamen / opschoonbare ruimte.",
      f5_t: "🎯 Focus & filters", f5_d: "Markeer bestanden op naam, type of grootte. Sluit patronen uit zoals <code>node_modules</code>.",
      f6_t: "💾 Bewaren & vergelijken", f6_d: "Bewaar scans, open ze opnieuw (incl. <code>.gpscan</code>) en vergelijk twee scans.",
      f7_t: "👁️ Snelle weergave & Open met", f7_d: "Voorvertonen met de spatiebalk, tonen in Finder, pad kopiëren, openen in elke app.",
      f8_t: "🌍 15 talen", f8_d: "Nederlands, English, Deutsch, Français, 日本語, 简体中文 en meer.",
      f9_t: "🛡️ Privacy by design", f9_d: "Leest alleen bestandsmetadata — namen & groottes. Niets verlaat je Mac. Geen analytics.",
      dl_title: "Klaar om ruimte terug te winnen?", dl_sub: "Gratis, open source en genotariseerd voor macOS.",
      dl_fine: "Vereist macOS 13 Ventura of nieuwer. Als de app de eerste keer wordt geopend en macOS waarschuwt dat hij van een niet-geïdentificeerde ontwikkelaar is: rechtsklik op de app ▸ <em>Open</em>.",
      foot_lic: "MIT-licentie"
    },
    fr: {
      nav_features: "Fonctions", nav_screenshots: "Captures", nav_download: "Télécharger",
      hero_find: "Trouvez-le. ", hero_free: "Libérez-le.",
      tagline: "Voyez exactement ce qui remplit le disque de votre Mac, sous forme de <strong>soleil</strong> ou de <strong>treemap</strong> interactif, et récupérez l'espace — rapidement et en toute sécurité.",
      cta_download: "Télécharger pour macOS", cta_source: "Voir le code",
      meta_default: "Gratuit & open source · macOS 13+ · Apple Silicon & Intel",
      meta_latest: "Dernière : v%v · Gratuit & open source · macOS 13+ · Apple Silicon & Intel",
      os_hint: "Vous ne semblez pas être sur un Mac — SpaceMonger est une app macOS.",
      shot_sunburst: "Le diagramme soleil — la taille des anneaux est proportionnelle à l'espace occupé.",
      shot_treemap: "Ou un treemap ombré — changez de vue en un clic.",
      features_title: "Tout pour nettoyer votre disque",
      f1_t: "🌅 Soleil & treemap", f1_d: "Deux cartes interactives. Zoom, survol pour les détails, couleur par dossier, type de fichier ou profondeur.",
      f2_t: "⚡ Analyses rapides et parallèles", f2_d: "Mesure multicœur des tailles réelles sur le disque, avec progression en direct et annulation.",
      f3_t: "🗑️ Le collecteur", f3_d: "Glissez des fichiers, puis placez-les tous dans la corbeille d'un coup. Des protections préservent les fichiers système.",
      f4_t: "🔒 Espace système & caché", f4_d: "Accès complet au disque, analyse administrateur, et nettoyage des instantanés locaux / de l'espace purgeable.",
      f5_t: "🎯 Focus & filtres", f5_d: "Mettez en évidence les fichiers par nom, type ou taille. Excluez des motifs comme <code>node_modules</code>.",
      f6_t: "💾 Enregistrer & comparer", f6_d: "Enregistrez des analyses, rouvrez-les (y compris <code>.gpscan</code>) et comparez-en deux.",
      f7_t: "👁️ Coup d'œil & Ouvrir avec", f7_d: "Aperçu avec Espace, afficher dans le Finder, copier le chemin, ouvrir dans n'importe quelle app.",
      f8_t: "🌍 15 langues", f8_d: "Français, English, Deutsch, Nederlands, 日本語, 简体中文 et plus.",
      f9_t: "🛡️ Confidentiel par conception", f9_d: "Ne lit que les métadonnées — noms & tailles. Rien ne quitte votre Mac. Aucune analyse.",
      dl_title: "Prêt à récupérer de l'espace ?", dl_sub: "Gratuit, open source et notarisé pour macOS.",
      dl_fine: "Nécessite macOS 13 Ventura ou ultérieur. Si l'app est ouverte pour la première fois et que macOS signale un développeur non identifié, faites un clic droit sur l'app ▸ <em>Ouvrir</em>.",
      foot_lic: "Sous licence MIT"
    },
    de: {
      nav_features: "Funktionen", nav_screenshots: "Screenshots", nav_download: "Laden",
      hero_find: "Finden. ", hero_free: "Freigeben.",
      tagline: "Sehen Sie genau, was die Festplatte Ihres Macs füllt — als interaktiver <strong>Sunburst</strong> oder <strong>Treemap</strong> — und gewinnen Sie den Platz zurück, schnell und sicher.",
      cta_download: "Für macOS laden", cta_source: "Quellcode ansehen",
      meta_default: "Kostenlos & Open Source · macOS 13+ · Apple Silicon & Intel",
      meta_latest: "Neueste: v%v · Kostenlos & Open Source · macOS 13+ · Apple Silicon & Intel",
      os_hint: "Sie scheinen nicht auf einem Mac zu sein — SpaceMonger ist eine macOS-App.",
      shot_sunburst: "Der Sunburst — die Ringgröße ist proportional zur Belegung.",
      shot_treemap: "Oder ein schattierter Treemap — Layout mit einem Klick wechseln.",
      features_title: "Alles, um Ihre Festplatte aufzuräumen",
      f1_t: "🌅 Sunburst & Treemap", f1_d: "Zwei interaktive Karten. Zoomen, Details beim Überfahren, Färben nach Ordner, Dateityp oder Tiefe.",
      f2_t: "⚡ Schnelle, parallele Scans", f2_d: "Mehrkern-Messung echter Belegung, mit Live-Fortschritt und Abbrechen.",
      f3_t: "🗑️ Der Sammler", f3_d: "Dateien hineinziehen und alle auf einmal in den Papierkorb legen. Schutzmechanismen bewahren Systemdateien.",
      f4_t: "🔒 System- & verborgener Speicher", f4_d: "Vollständiger Festplattenzugriff, Administrator-Scan und Bereinigen lokaler Schnappschüsse / bereinigbaren Speichers.",
      f5_t: "🎯 Fokus & Filter", f5_d: "Dateien nach Name, Typ oder Größe hervorheben. Muster wie <code>node_modules</code> ausschließen.",
      f6_t: "💾 Sichern & vergleichen", f6_d: "Scans sichern, erneut öffnen (auch <code>.gpscan</code>) und zwei Scans vergleichen.",
      f7_t: "👁️ Übersicht & Öffnen mit", f7_d: "Vorschau mit Leertaste, im Finder zeigen, Pfad kopieren, in jeder App öffnen.",
      f8_t: "🌍 15 Sprachen", f8_d: "Deutsch, English, Français, Nederlands, 日本語, 简体中文 und mehr.",
      f9_t: "🛡️ Datenschutz von Grund auf", f9_d: "Liest nur Metadaten — Namen & Größen. Nichts verlässt Ihren Mac. Keine Analyse.",
      dl_title: "Bereit, Platz zurückzugewinnen?", dl_sub: "Kostenlos, Open Source und für macOS notarisiert.",
      dl_fine: "Erfordert macOS 13 Ventura oder neuer. Wird die App zum ersten Mal geöffnet und macOS warnt vor einem nicht verifizierten Entwickler, klicken Sie mit der rechten Maustaste auf die App ▸ <em>Öffnen</em>.",
      foot_lic: "MIT-Lizenz"
    },
    it: {
      nav_features: "Funzioni", nav_screenshots: "Schermate", nav_download: "Scarica",
      hero_find: "Trovalo. ", hero_free: "Liberalo.",
      tagline: "Scopri esattamente cosa riempie il disco del tuo Mac, come <strong>sunburst</strong> o <strong>treemap</strong> interattivo, e recupera lo spazio — in modo rapido e sicuro.",
      cta_download: "Scarica per macOS", cta_source: "Vedi il codice",
      meta_default: "Gratuito & open source · macOS 13+ · Apple Silicon & Intel",
      meta_latest: "Ultima: v%v · Gratuito & open source · macOS 13+ · Apple Silicon & Intel",
      os_hint: "Non sembri essere su un Mac — SpaceMonger è un'app macOS.",
      shot_sunburst: "Il sunburst — la dimensione degli anelli è proporzionale allo spazio usato.",
      shot_treemap: "Oppure un treemap ombreggiato — cambia vista con un clic.",
      features_title: "Tutto per liberare il tuo disco",
      f1_t: "🌅 Sunburst & treemap", f1_d: "Due mappe interattive. Zoom, dettagli al passaggio, colore per cartella, tipo di file o profondità.",
      f2_t: "⚡ Analisi rapide e parallele", f2_d: "Misura multi-core delle dimensioni reali, con avanzamento in tempo reale e annulla.",
      f3_t: "🗑️ Il raccoglitore", f3_d: "Trascina i file e spostali tutti nel Cestino in una volta. Le protezioni salvaguardano i file di sistema.",
      f4_t: "🔒 Spazio di sistema & nascosto", f4_d: "Accesso completo al disco, analisi come amministratore e pulizia di snapshot locali / spazio eliminabile.",
      f5_t: "🎯 Fuoco & filtri", f5_d: "Evidenzia i file per nome, tipo o dimensione. Escludi pattern come <code>node_modules</code>.",
      f6_t: "💾 Salva & confronta", f6_d: "Salva le analisi, riaprile (anche <code>.gpscan</code>) e confrontane due.",
      f7_t: "👁️ Visualizzazione rapida & Apri con", f7_d: "Anteprima con Spazio, mostra nel Finder, copia percorso, apri in qualsiasi app.",
      f8_t: "🌍 15 lingue", f8_d: "Italiano, English, Deutsch, Français, 日本語, 简体中文 e altre.",
      f9_t: "🛡️ Privato per progettazione", f9_d: "Legge solo i metadati — nomi & dimensioni. Nulla lascia il tuo Mac. Nessuna analisi.",
      dl_title: "Pronto a recuperare spazio?", dl_sub: "Gratuito, open source e autenticato per macOS.",
      dl_fine: "Richiede macOS 13 Ventura o successivo. Se apri l'app per la prima volta e macOS avvisa che proviene da uno sviluppatore non identificato, fai clic con il tasto destro sull'app ▸ <em>Apri</em>.",
      foot_lic: "Licenza MIT"
    },
    pl: {
      nav_features: "Funkcje", nav_screenshots: "Zrzuty ekranu", nav_download: "Pobierz",
      hero_find: "Znajdź. ", hero_free: "Zwolnij.",
      tagline: "Zobacz dokładnie, co zapełnia dysk Twojego Maca, jako interaktywny <strong>sunburst</strong> lub <strong>treemap</strong>, i odzyskaj miejsce — szybko i bezpiecznie.",
      cta_download: "Pobierz na macOS", cta_source: "Zobacz kod",
      meta_default: "Darmowe & open source · macOS 13+ · Apple Silicon & Intel",
      meta_latest: "Najnowsza: v%v · Darmowe & open source · macOS 13+ · Apple Silicon & Intel",
      os_hint: "Wygląda na to, że nie jesteś na Macu — SpaceMonger to aplikacja macOS.",
      shot_sunburst: "Sunburst — rozmiar pierścieni jest proporcjonalny do zajętości.",
      shot_treemap: "Albo cieniowany treemap — przełącz widok jednym kliknięciem.",
      features_title: "Wszystko, by uporządkować dysk",
      f1_t: "🌅 Sunburst & treemap", f1_d: "Dwie interaktywne mapy. Powiększanie, szczegóły po najechaniu, kolor wg folderu, typu pliku lub głębokości.",
      f2_t: "⚡ Szybkie, równoległe skany", f2_d: "Wielordzeniowy pomiar rzeczywistych rozmiarów, z postępem na żywo i anulowaniem.",
      f3_t: "🗑️ Kolektor", f3_d: "Przeciągnij pliki i przenieś je wszystkie naraz do Kosza. Zabezpieczenia chronią pliki systemowe.",
      f4_t: "🔒 Miejsce systemowe & ukryte", f4_d: "Pełny dostęp do dysku, skan administratora oraz czyszczenie lokalnych migawek / miejsca do oczyszczenia.",
      f5_t: "🎯 Fokus & filtry", f5_d: "Wyróżniaj pliki wg nazwy, typu lub rozmiaru. Wykluczaj wzorce jak <code>node_modules</code>.",
      f6_t: "💾 Zapis & porównanie", f6_d: "Zapisuj skany, otwieraj je ponownie (też <code>.gpscan</code>) i porównuj dwa skany.",
      f7_t: "👁️ Szybki podgląd & Otwórz za pomocą", f7_d: "Podgląd Spacją, pokaż w Finderze, kopiuj ścieżkę, otwórz w dowolnej aplikacji.",
      f8_t: "🌍 15 języków", f8_d: "Polski, English, Deutsch, Français, 日本語, 简体中文 i więcej.",
      f9_t: "🛡️ Prywatność u podstaw", f9_d: "Czyta tylko metadane — nazwy & rozmiary. Nic nie opuszcza Twojego Maca. Bez analityki.",
      dl_title: "Gotów odzyskać miejsce?", dl_sub: "Darmowe, open source i notaryzowane dla macOS.",
      dl_fine: "Wymaga macOS 13 Ventura lub nowszego. Jeśli aplikacja jest otwierana po raz pierwszy, a macOS ostrzega o niezidentyfikowanym deweloperze, kliknij aplikację prawym przyciskiem ▸ <em>Otwórz</em>.",
      foot_lic: "Licencja MIT"
    },
    ru: {
      nav_features: "Возможности", nav_screenshots: "Скриншоты", nav_download: "Скачать",
      hero_find: "Найдите. ", hero_free: "Освободите.",
      tagline: "Узнайте точно, что заполняет диск вашего Mac, в виде интерактивного <strong>sunburst</strong> или <strong>treemap</strong>, и верните место — быстро и безопасно.",
      cta_download: "Скачать для macOS", cta_source: "Исходный код",
      meta_default: "Бесплатно & открытый код · macOS 13+ · Apple Silicon & Intel",
      meta_latest: "Последняя: v%v · Бесплатно & открытый код · macOS 13+ · Apple Silicon & Intel",
      os_hint: "Похоже, вы не на Mac — SpaceMonger это приложение для macOS.",
      shot_sunburst: "Sunburst — размер колец пропорционален занятому месту.",
      shot_treemap: "Или treemap с тенями — переключение одним щелчком.",
      features_title: "Всё, чтобы навести порядок на диске",
      f1_t: "🌅 Sunburst & treemap", f1_d: "Две интерактивные карты. Масштаб, детали при наведении, цвет по папке, типу файла или глубине.",
      f2_t: "⚡ Быстрые параллельные сканы", f2_d: "Многоядерное измерение реальных размеров, с прогрессом и отменой.",
      f3_t: "🗑️ Коллектор", f3_d: "Перетащите файлы и отправьте их все в Корзину разом. Защита оберегает системные файлы.",
      f4_t: "🔒 Системное & скрытое место", f4_d: "Полный доступ к диску, скан от администратора и очистка локальных снимков / очищаемого места.",
      f5_t: "🎯 Фокус & фильтры", f5_d: "Выделяйте файлы по имени, типу или размеру. Исключайте шаблоны вроде <code>node_modules</code>.",
      f6_t: "💾 Сохранение & сравнение", f6_d: "Сохраняйте сканы, открывайте их снова (в т.ч. <code>.gpscan</code>) и сравнивайте два скана.",
      f7_t: "👁️ Быстрый просмотр & Открыть в программе", f7_d: "Просмотр пробелом, показать в Finder, скопировать путь, открыть в любом приложении.",
      f8_t: "🌍 15 языков", f8_d: "Русский, English, Deutsch, Français, 日本語, 简体中文 и другие.",
      f9_t: "🛡️ Приватность по дизайну", f9_d: "Читает только метаданные — имена & размеры. Ничего не покидает ваш Mac. Без аналитики.",
      dl_title: "Готовы вернуть место?", dl_sub: "Бесплатно, открытый код и нотаризовано для macOS.",
      dl_fine: "Требуется macOS 13 Ventura или новее. Если приложение открывается впервые и macOS предупреждает о неустановленном разработчике, щёлкните по приложению правой кнопкой ▸ <em>Открыть</em>.",
      foot_lic: "Лицензия MIT"
    },
    es: {
      nav_features: "Funciones", nav_screenshots: "Capturas", nav_download: "Descargar",
      hero_find: "Encuéntralo. ", hero_free: "Libéralo.",
      tagline: "Ve exactamente qué llena el disco de tu Mac, como un <strong>sunburst</strong> o <strong>treemap</strong> interactivo, y recupera el espacio — de forma rápida y segura.",
      cta_download: "Descargar para macOS", cta_source: "Ver el código",
      meta_default: "Gratis & código abierto · macOS 13+ · Apple Silicon & Intel",
      meta_latest: "Última: v%v · Gratis & código abierto · macOS 13+ · Apple Silicon & Intel",
      os_hint: "Parece que no estás en un Mac — SpaceMonger es una app de macOS.",
      shot_sunburst: "El sunburst — el tamaño de los anillos es proporcional al espacio usado.",
      shot_treemap: "O un treemap sombreado — cambia de vista con un clic.",
      features_title: "Todo para limpiar tu disco",
      f1_t: "🌅 Sunburst & treemap", f1_d: "Dos mapas interactivos. Zoom, detalles al pasar, color por carpeta, tipo de archivo o profundidad.",
      f2_t: "⚡ Análisis rápidos y paralelos", f2_d: "Medición multinúcleo de tamaños reales, con progreso en directo y cancelar.",
      f3_t: "🗑️ El colector", f3_d: "Arrastra archivos y muévelos todos a la Papelera a la vez. Las protecciones cuidan los archivos del sistema.",
      f4_t: "🔒 Espacio del sistema & oculto", f4_d: "Acceso total al disco, análisis como administrador y limpieza de instantáneas locales / espacio purgable.",
      f5_t: "🎯 Foco & filtros", f5_d: "Resalta archivos por nombre, tipo o tamaño. Excluye patrones como <code>node_modules</code>.",
      f6_t: "💾 Guardar & comparar", f6_d: "Guarda análisis, reábrelos (incl. <code>.gpscan</code>) y compara dos análisis.",
      f7_t: "👁️ Vista rápida & Abrir con", f7_d: "Previsualiza con Espacio, muestra en el Finder, copia la ruta, abre en cualquier app.",
      f8_t: "🌍 15 idiomas", f8_d: "Español, English, Deutsch, Français, 日本語, 简体中文 y más.",
      f9_t: "🛡️ Privado por diseño", f9_d: "Solo lee metadatos — nombres & tamaños. Nada sale de tu Mac. Sin analíticas.",
      dl_title: "¿Listo para recuperar espacio?", dl_sub: "Gratis, código abierto y notarizado para macOS.",
      dl_fine: "Requiere macOS 13 Ventura o posterior. Si abres la app por primera vez y macOS avisa de un desarrollador no identificado, haz clic derecho en la app ▸ <em>Abrir</em>.",
      foot_lic: "Licencia MIT"
    },
    "pt-PT": {
      nav_features: "Funções", nav_screenshots: "Capturas", nav_download: "Transferir",
      hero_find: "Encontre. ", hero_free: "Liberte.",
      tagline: "Veja exatamente o que enche o disco do seu Mac, como um <strong>sunburst</strong> ou <strong>treemap</strong> interativo, e recupere o espaço — de forma rápida e segura.",
      cta_download: "Transferir para macOS", cta_source: "Ver o código",
      meta_default: "Gratuito & código aberto · macOS 13+ · Apple Silicon & Intel",
      meta_latest: "Mais recente: v%v · Gratuito & código aberto · macOS 13+ · Apple Silicon & Intel",
      os_hint: "Parece que não está num Mac — o SpaceMonger é uma app macOS.",
      shot_sunburst: "O sunburst — o tamanho dos anéis é proporcional ao espaço usado.",
      shot_treemap: "Ou um treemap sombreado — troque de vista com um clique.",
      features_title: "Tudo para limpar o seu disco",
      f1_t: "🌅 Sunburst & treemap", f1_d: "Dois mapas interativos. Zoom, detalhes ao passar, cor por pasta, tipo de ficheiro ou profundidade.",
      f2_t: "⚡ Análises rápidas e paralelas", f2_d: "Medição multinúcleo dos tamanhos reais, com progresso em direto e cancelar.",
      f3_t: "🗑️ O coletor", f3_d: "Arraste ficheiros e mova-os todos para o Lixo de uma vez. As proteções salvaguardam ficheiros do sistema.",
      f4_t: "🔒 Espaço de sistema & oculto", f4_d: "Acesso total ao disco, análise como administrador e limpeza de instantâneos locais / espaço purgável.",
      f5_t: "🎯 Foco & filtros", f5_d: "Realce ficheiros por nome, tipo ou tamanho. Exclua padrões como <code>node_modules</code>.",
      f6_t: "💾 Guardar & comparar", f6_d: "Guarde análises, reabra-as (incl. <code>.gpscan</code>) e compare duas análises.",
      f7_t: "👁️ Vista rápida & Abrir com", f7_d: "Pré-visualize com Espaço, mostre no Finder, copie o caminho, abra em qualquer app.",
      f8_t: "🌍 15 idiomas", f8_d: "Português, English, Deutsch, Français, 日本語, 简体中文 e mais.",
      f9_t: "🛡️ Privado por conceção", f9_d: "Lê apenas metadados — nomes & tamanhos. Nada sai do seu Mac. Sem análises.",
      dl_title: "Pronto para recuperar espaço?", dl_sub: "Gratuito, código aberto e autenticado para macOS.",
      dl_fine: "Requer macOS 13 Ventura ou posterior. Se abrir a app pela primeira vez e o macOS avisar sobre um programador não identificado, clique com o botão direito na app ▸ <em>Abrir</em>.",
      foot_lic: "Licença MIT"
    },
    sv: {
      nav_features: "Funktioner", nav_screenshots: "Skärmbilder", nav_download: "Hämta",
      hero_find: "Hitta det. ", hero_free: "Frigör det.",
      tagline: "Se exakt vad som fyller din Macs disk, som ett interaktivt <strong>sunburst</strong> eller <strong>treemap</strong>, och återta utrymmet — snabbt och säkert.",
      cta_download: "Hämta för macOS", cta_source: "Visa källkod",
      meta_default: "Gratis & öppen källkod · macOS 13+ · Apple Silicon & Intel",
      meta_latest: "Senaste: v%v · Gratis & öppen källkod · macOS 13+ · Apple Silicon & Intel",
      os_hint: "Du verkar inte vara på en Mac — SpaceMonger är en macOS-app.",
      shot_sunburst: "Sunburst — ringstorleken är proportionell mot använt utrymme.",
      shot_treemap: "Eller ett skuggat treemap — byt vy med ett klick.",
      features_title: "Allt för att rensa din disk",
      f1_t: "🌅 Sunburst & treemap", f1_d: "Två interaktiva kartor. Zooma, detaljer vid hovring, färg efter mapp, filtyp eller djup.",
      f2_t: "⚡ Snabba, parallella skanningar", f2_d: "Flerkärnig mätning av verkliga storlekar, med realtidsförlopp och avbryt.",
      f3_t: "🗑️ Samlaren", f3_d: "Dra in filer och flytta dem alla till papperskorgen på en gång. Skydd bevarar systemfiler.",
      f4_t: "🔒 System- & dolt utrymme", f4_d: "Fullständig diskåtkomst, administratörsskanning och rensning av lokala ögonblicksbilder / rensningsbart utrymme.",
      f5_t: "🎯 Fokus & filter", f5_d: "Markera filer efter namn, typ eller storlek. Uteslut mönster som <code>node_modules</code>.",
      f6_t: "💾 Spara & jämför", f6_d: "Spara skanningar, öppna dem igen (även <code>.gpscan</code>) och jämför två.",
      f7_t: "👁️ Snabbtitt & Öppna med", f7_d: "Förhandsvisa med blanksteg, visa i Finder, kopiera sökväg, öppna i valfri app.",
      f8_t: "🌍 15 språk", f8_d: "Svenska, English, Deutsch, Français, 日本語, 简体中文 med flera.",
      f9_t: "🛡️ Privat från grunden", f9_d: "Läser bara metadata — namn & storlek. Inget lämnar din Mac. Ingen analys.",
      dl_title: "Redo att återta utrymme?", dl_sub: "Gratis, öppen källkod och notariserad för macOS.",
      dl_fine: "Kräver macOS 13 Ventura eller senare. Om appen öppnas första gången och macOS varnar för en oidentifierad utvecklare, högerklicka på appen ▸ <em>Öppna</em>.",
      foot_lic: "MIT-licens"
    },
    tr: {
      nav_features: "Özellikler", nav_screenshots: "Ekran görüntüleri", nav_download: "İndir",
      hero_find: "Bul. ", hero_free: "Yer aç.",
      tagline: "Mac'inizin diskini neyin doldurduğunu etkileşimli bir <strong>sunburst</strong> veya <strong>treemap</strong> olarak görün ve alanı geri kazanın — hızlı ve güvenli.",
      cta_download: "macOS için indir", cta_source: "Kaynağı görüntüle",
      meta_default: "Ücretsiz & açık kaynak · macOS 13+ · Apple Silicon & Intel",
      meta_latest: "En son: v%v · Ücretsiz & açık kaynak · macOS 13+ · Apple Silicon & Intel",
      os_hint: "Mac'te değil gibisiniz — SpaceMonger bir macOS uygulamasıdır.",
      shot_sunburst: "Sunburst — halka boyutu kullanılan alanla orantılıdır.",
      shot_treemap: "Ya da gölgeli bir treemap — tek tıkla görünüm değiştirin.",
      features_title: "Diskinizi temizlemek için her şey",
      f1_t: "🌅 Sunburst & treemap", f1_d: "İki etkileşimli harita. Yakınlaştırma, üzerine gelince detay, klasöre, dosya türüne veya derinliğe göre renk.",
      f2_t: "⚡ Hızlı, paralel taramalar", f2_d: "Gerçek boyutların çok çekirdekli ölçümü, canlı ilerleme ve iptal ile.",
      f3_t: "🗑️ Toplayıcı", f3_d: "Dosyaları sürükleyin, hepsini bir kerede Çöp'e taşıyın. Korumalar sistem dosyalarını korur.",
      f4_t: "🔒 Sistem & gizli alan", f4_d: "Tam Disk Erişimi, yönetici taraması ve yerel anlık görüntü / temizlenebilir alan temizliği.",
      f5_t: "🎯 Odak & filtreler", f5_d: "Dosyaları ada, türe veya boyuta göre vurgulayın. <code>node_modules</code> gibi desenleri hariç tutun.",
      f6_t: "💾 Kaydet & karşılaştır", f6_d: "Taramaları kaydedin, yeniden açın (<code>.gpscan</code> dahil) ve iki taramayı karşılaştırın.",
      f7_t: "👁️ Hızlı Bakış & Birlikte Aç", f7_d: "Boşlukla önizleyin, Finder'da gösterin, yolu kopyalayın, herhangi bir uygulamada açın.",
      f8_t: "🌍 15 dil", f8_d: "Türkçe, English, Deutsch, Français, 日本語, 简体中文 ve daha fazlası.",
      f9_t: "🛡️ Tasarımdan gizli", f9_d: "Yalnızca meta verileri okur — ad & boyut. Hiçbir şey Mac'inizden çıkmaz. Analiz yok.",
      dl_title: "Yer açmaya hazır mısınız?", dl_sub: "Ücretsiz, açık kaynak ve macOS için onaylı.",
      dl_fine: "macOS 13 Ventura veya üzeri gerekir. Uygulama ilk kez açıldığında ve macOS kimliği doğrulanmamış bir geliştiriciden olduğunu bildirirse, uygulamaya sağ tıklayın ▸ <em>Aç</em>.",
      foot_lic: "MIT lisanslı"
    },
    uk: {
      nav_features: "Можливості", nav_screenshots: "Знімки екрана", nav_download: "Завантажити",
      hero_find: "Знайдіть. ", hero_free: "Звільніть.",
      tagline: "Дізнайтеся точно, що заповнює диск вашого Mac, як інтерактивний <strong>sunburst</strong> або <strong>treemap</strong>, і поверніть місце — швидко й безпечно.",
      cta_download: "Завантажити для macOS", cta_source: "Переглянути код",
      meta_default: "Безкоштовно & відкритий код · macOS 13+ · Apple Silicon & Intel",
      meta_latest: "Найновіша: v%v · Безкоштовно & відкритий код · macOS 13+ · Apple Silicon & Intel",
      os_hint: "Схоже, ви не на Mac — SpaceMonger це застосунок для macOS.",
      shot_sunburst: "Sunburst — розмір кілець пропорційний зайнятому місцю.",
      shot_treemap: "Або treemap із тінями — змінюйте вигляд одним кліком.",
      features_title: "Усе, щоб упорядкувати ваш диск",
      f1_t: "🌅 Sunburst & treemap", f1_d: "Дві інтерактивні карти. Масштаб, деталі при наведенні, колір за текою, типом файлу або глибиною.",
      f2_t: "⚡ Швидкі паралельні сканування", f2_d: "Багатоядерне вимірювання реальних розмірів, із прогресом і скасуванням.",
      f3_t: "🗑️ Колектор", f3_d: "Перетягніть файли й перемістіть їх усі в Кошик одразу. Захист береже системні файли.",
      f4_t: "🔒 Системний & прихований простір", f4_d: "Повний доступ до диска, сканування від адміністратора та очищення локальних знімків / місця для очищення.",
      f5_t: "🎯 Фокус & фільтри", f5_d: "Підсвічуйте файли за іменем, типом або розміром. Виключайте шаблони на кшталт <code>node_modules</code>.",
      f6_t: "💾 Збереження & порівняння", f6_d: "Зберігайте сканування, відкривайте їх знову (зокрема <code>.gpscan</code>) і порівнюйте два.",
      f7_t: "👁️ Швидкий перегляд & Відкрити у програмі", f7_d: "Перегляд пробілом, показати у Finder, копіювати шлях, відкрити в будь-якому застосунку.",
      f8_t: "🌍 15 мов", f8_d: "Українська, English, Deutsch, Français, 日本語, 简体中文 та інші.",
      f9_t: "🛡️ Приватність за задумом", f9_d: "Читає лише метадані — імена & розміри. Нічого не залишає ваш Mac. Без аналітики.",
      dl_title: "Готові повернути місце?", dl_sub: "Безкоштовно, відкритий код і нотаризовано для macOS.",
      dl_fine: "Потрібен macOS 13 Ventura або новіший. Якщо застосунок відкривається вперше і macOS попереджає про неідентифікованого розробника, клацніть застосунок правою кнопкою ▸ <em>Відкрити</em>.",
      foot_lic: "Ліцензія MIT"
    },
    "zh-Hans": {
      nav_features: "功能", nav_screenshots: "截图", nav_download: "下载",
      hero_find: "找到它。", hero_free: "释放它。",
      tagline: "以交互式<strong>旭日图</strong>或<strong>矩形树图</strong>准确查看是什么占满了 Mac 的磁盘，快速、安全地收回空间。",
      cta_download: "下载 macOS 版", cta_source: "查看源代码",
      meta_default: "免费 & 开源 · macOS 13+ · Apple 芯片 & Intel",
      meta_latest: "最新：v%v · 免费 & 开源 · macOS 13+ · Apple 芯片 & Intel",
      os_hint: "你似乎不在 Mac 上——SpaceMonger 是一款 macOS 应用。",
      shot_sunburst: "旭日图——环的大小与占用空间成正比。",
      shot_treemap: "或带阴影的矩形树图——一键切换视图。",
      features_title: "清理磁盘所需的一切",
      f1_t: "🌅 旭日图 & 矩形树图", f1_d: "两种交互式图表。缩放、悬停查看详情，按文件夹、文件类型或深度着色。",
      f2_t: "⚡ 快速并行扫描", f2_d: "多核测量真实占用大小，带实时进度与取消。",
      f3_t: "🗑️ 收集箱", f3_d: "拖入文件，一次性全部移到废纸篓。安全限制保护系统文件。",
      f4_t: "🔒 系统与隐藏空间", f4_d: "完全磁盘访问流程、管理员扫描，以及本地快照／可清除空间的清理。",
      f5_t: "🎯 聚焦与筛选", f5_d: "按名称、类型或大小高亮文件。排除诸如 <code>node_modules</code> 的模式。",
      f6_t: "💾 保存与比较", f6_d: "保存扫描、重新打开（含 <code>.gpscan</code>），并比较两次扫描。",
      f7_t: "👁️ 快速查看 & 打开方式", f7_d: "用空格预览、在访达中显示、拷贝路径、用任意应用打开。",
      f8_t: "🌍 15 种语言", f8_d: "简体中文、English、Deutsch、Français、日本語、繁體中文 等。",
      f9_t: "🛡️ 隐私优先设计", f9_d: "仅读取文件元数据——名称与大小。任何数据都不离开你的 Mac。无分析。",
      dl_title: "准备好收回空间了吗？", dl_sub: "免费、开源，并已为 macOS 公证。",
      dl_fine: "需要 macOS 13 Ventura 或更新版本。若首次打开应用且 macOS 提示来自身份不明的开发者，请右键点按应用 ▸ <em>打开</em>。",
      foot_lic: "MIT 许可"
    },
    "zh-Hant": {
      nav_features: "功能", nav_screenshots: "螢幕截圖", nav_download: "下載",
      hero_find: "找到它。", hero_free: "釋放它。",
      tagline: "以互動式<strong>旭日圖</strong>或<strong>矩形樹狀圖</strong>準確查看是什麼佔滿 Mac 的磁碟，快速、安全地收回空間。",
      cta_download: "下載 macOS 版", cta_source: "檢視原始碼",
      meta_default: "免費 & 開源 · macOS 13+ · Apple 晶片 & Intel",
      meta_latest: "最新：v%v · 免費 & 開源 · macOS 13+ · Apple 晶片 & Intel",
      os_hint: "你似乎不在 Mac 上——SpaceMonger 是一款 macOS App。",
      shot_sunburst: "旭日圖——環的大小與佔用空間成正比。",
      shot_treemap: "或帶陰影的矩形樹狀圖——一鍵切換檢視。",
      features_title: "清理磁碟所需的一切",
      f1_t: "🌅 旭日圖 & 矩形樹狀圖", f1_d: "兩種互動式圖表。縮放、停留查看細節，依檔案夾、檔案類型或深度上色。",
      f2_t: "⚡ 快速並行掃描", f2_d: "多核心測量真實佔用大小，含即時進度與取消。",
      f3_t: "🗑️ 收集箱", f3_d: "拖入檔案，一次全部移到垃圾桶。安全限制保護系統檔案。",
      f4_t: "🔒 系統與隱藏空間", f4_d: "完整磁碟取用權流程、管理者掃描，以及本機快照／可清除空間的清理。",
      f5_t: "🎯 聚焦與篩選", f5_d: "依名稱、類型或大小突顯檔案。排除像 <code>node_modules</code> 的樣式。",
      f6_t: "💾 儲存與比較", f6_d: "儲存掃描、重新開啟（含 <code>.gpscan</code>），並比較兩次掃描。",
      f7_t: "👁️ 快速查看 & 打開方式", f7_d: "用空白鍵預覽、在 Finder 中顯示、拷貝路徑、用任何 App 打開。",
      f8_t: "🌍 15 種語言", f8_d: "繁體中文、English、Deutsch、Français、日本語、简体中文 等。",
      f9_t: "🛡️ 隱私優先設計", f9_d: "僅讀取檔案中繼資料——名稱與大小。任何資料都不離開你的 Mac。無分析。",
      dl_title: "準備好收回空間了嗎？", dl_sub: "免費、開源，並已為 macOS 公證。",
      dl_fine: "需要 macOS 13 Ventura 或更新版本。若首次開啟 App 且 macOS 提示來自未識別的開發者，請右鍵點按 App ▸ <em>打開</em>。",
      foot_lic: "MIT 授權"
    },
    ja: {
      nav_features: "機能", nav_screenshots: "スクリーンショット", nav_download: "ダウンロード",
      hero_find: "見つけて。", hero_free: "空けよう。",
      tagline: "インタラクティブな<strong>サンバースト</strong>または<strong>ツリーマップ</strong>で、Mac のディスクを満たしているものを正確に把握し、容量を素早く安全に取り戻しましょう。",
      cta_download: "macOS 版をダウンロード", cta_source: "ソースを見る",
      meta_default: "無料 & オープンソース · macOS 13+ · Apple シリコン & Intel",
      meta_latest: "最新：v%v · 無料 & オープンソース · macOS 13+ · Apple シリコン & Intel",
      os_hint: "Mac ではないようです — SpaceMonger は macOS アプリです。",
      shot_sunburst: "サンバースト — リングの大きさは使用容量に比例します。",
      shot_treemap: "または陰影付きのツリーマップ — ワンクリックで切り替え。",
      features_title: "ディスクを片付けるためのすべて",
      f1_t: "🌅 サンバースト & ツリーマップ", f1_d: "2 つのインタラクティブなマップ。ズーム、ホバーで詳細、フォルダ・ファイルの種類・深さで色分け。",
      f2_t: "⚡ 高速・並列スキャン", f2_d: "実際の使用サイズをマルチコアで計測。リアルタイム進行と取り消し付き。",
      f3_t: "🗑️ コレクター", f3_d: "ファイルをドラッグして、まとめてゴミ箱へ。安全機構がシステムファイルを保護します。",
      f4_t: "🔒 システムと隠し領域", f4_d: "フルディスクアクセスの導線、管理者スキャン、ローカルスナップショット／パージ可能領域の整理。",
      f5_t: "🎯 フォーカスとフィルタ", f5_d: "名前・種類・サイズでファイルを強調。<code>node_modules</code> などのパターンを除外。",
      f6_t: "💾 保存と比較", f6_d: "スキャンを保存・再オープン（<code>.gpscan</code> も）し、2 つを比較。",
      f7_t: "👁️ クイックルック & このアプリで開く", f7_d: "スペースでプレビュー、Finder で表示、パスをコピー、任意のアプリで開く。",
      f8_t: "🌍 15 言語", f8_d: "日本語、English、Deutsch、Français、简体中文、繁體中文 ほか。",
      f9_t: "🛡️ プライバシー重視設計", f9_d: "読み取るのはメタデータ（名前とサイズ）のみ。データは Mac の外に出ません。解析なし。",
      dl_title: "容量を取り戻す準備はできましたか？", dl_sub: "無料・オープンソース、macOS 向けに公証済み。",
      dl_fine: "macOS 13 Ventura 以降が必要です。初回起動時に macOS が未確認の開発元と警告する場合は、アプリを右クリック ▸ <em>開く</em>。",
      foot_lic: "MIT ライセンス"
    }
  };

  // Extra strings added in the SEO/FAQ/conversion pass.
  var EXTRA = {
    en: { nav_faq: "FAQ", badge_oss: "Open source", whatsnew_title: "What's new", whatsnew_all: "All releases", faq_title: "Frequently asked questions", faq_q1: "Is SpaceMonger free?", faq_a1: "Yes — it's free and open source under the MIT license.", faq_q2: "Is it safe and notarized?", faq_a2: "Releases are signed and notarized by Apple. Deletions go to the Trash, and system files are protected.", faq_q3: "How do I open it the first time?", faq_a3: "If macOS warns about an unidentified developer, right-click the app and choose Open.", faq_q4: "What about my privacy?", faq_a4: "SpaceMonger reads only file names and sizes — never contents — and sends nothing off your Mac.", foot_releases: "Releases", foot_issues: "Report an issue", foot_privacy: "Privacy", doc_desc: "A free, native macOS disk-usage analyzer. Reclaim space — quickly and safely." },
    nl: { nav_faq: "FAQ", badge_oss: "Open source", whatsnew_title: "Wat is er nieuw", whatsnew_all: "Alle releases", faq_title: "Veelgestelde vragen", faq_q1: "Is SpaceMonger gratis?", faq_a1: "Ja — het is gratis en open source onder de MIT-licentie.", faq_q2: "Is het veilig en genotariseerd?", faq_a2: "Releases zijn door Apple ondertekend en genotariseerd. Verwijderingen gaan naar de prullenmand en systeembestanden zijn beschermd.", faq_q3: "Hoe open ik het de eerste keer?", faq_a3: "Als macOS waarschuwt voor een niet-geïdentificeerde ontwikkelaar: rechtsklik op de app en kies Open.", faq_q4: "Hoe zit het met mijn privacy?", faq_a4: "SpaceMonger leest alleen bestandsnamen en -groottes — nooit de inhoud — en stuurt niets buiten je Mac.", foot_releases: "Releases", foot_issues: "Probleem melden", foot_privacy: "Privacy", doc_desc: "Een gratis, native macOS disk-usage analyzer. Win ruimte terug — snel en veilig." },
    fr: { nav_faq: "FAQ", badge_oss: "Open source", whatsnew_title: "Nouveautés", whatsnew_all: "Toutes les versions", faq_title: "Questions fréquentes", faq_q1: "SpaceMonger est-il gratuit ?", faq_a1: "Oui — il est gratuit et open source sous licence MIT.", faq_q2: "Est-ce sûr et notarisé ?", faq_a2: "Les versions sont signées et notarisées par Apple. Les suppressions vont dans la corbeille et les fichiers système sont protégés.", faq_q3: "Comment l'ouvrir la première fois ?", faq_a3: "Si macOS signale un développeur non identifié, faites un clic droit sur l'app et choisissez Ouvrir.", faq_q4: "Qu'en est-il de ma vie privée ?", faq_a4: "SpaceMonger ne lit que les noms et tailles des fichiers — jamais le contenu — et n'envoie rien hors de votre Mac.", foot_releases: "Versions", foot_issues: "Signaler un problème", foot_privacy: "Confidentialité", doc_desc: "Un analyseur d'espace disque natif et gratuit pour macOS. Récupérez de l'espace — vite et en sécurité." },
    de: { nav_faq: "FAQ", badge_oss: "Open Source", whatsnew_title: "Neuigkeiten", whatsnew_all: "Alle Versionen", faq_title: "Häufige Fragen", faq_q1: "Ist SpaceMonger kostenlos?", faq_a1: "Ja — es ist kostenlos und Open Source unter der MIT-Lizenz.", faq_q2: "Ist es sicher und notarisiert?", faq_a2: "Versionen sind von Apple signiert und notarisiert. Gelöschtes landet im Papierkorb, Systemdateien sind geschützt.", faq_q3: "Wie öffne ich es zum ersten Mal?", faq_a3: "Warnt macOS vor einem nicht verifizierten Entwickler, klicken Sie mit der rechten Maustaste auf die App und wählen Öffnen.", faq_q4: "Was ist mit meiner Privatsphäre?", faq_a4: "SpaceMonger liest nur Dateinamen und -größen — nie Inhalte — und sendet nichts von Ihrem Mac.", foot_releases: "Versionen", foot_issues: "Problem melden", foot_privacy: "Datenschutz", doc_desc: "Ein kostenloser, nativer macOS-Speicheranalysator. Gewinnen Sie Platz zurück — schnell und sicher." },
    it: { nav_faq: "FAQ", badge_oss: "Open source", whatsnew_title: "Novità", whatsnew_all: "Tutte le versioni", faq_title: "Domande frequenti", faq_q1: "SpaceMonger è gratuito?", faq_a1: "Sì — è gratuito e open source con licenza MIT.", faq_q2: "È sicuro e autenticato?", faq_a2: "Le versioni sono firmate e autenticate da Apple. Le eliminazioni vanno nel Cestino e i file di sistema sono protetti.", faq_q3: "Come lo apro la prima volta?", faq_a3: "Se macOS avvisa di uno sviluppatore non identificato, fai clic con il tasto destro sull'app e scegli Apri.", faq_q4: "E la mia privacy?", faq_a4: "SpaceMonger legge solo nomi e dimensioni dei file — mai i contenuti — e non invia nulla fuori dal tuo Mac.", foot_releases: "Versioni", foot_issues: "Segnala un problema", foot_privacy: "Privacy", doc_desc: "Un analizzatore di spazio su disco nativo e gratuito per macOS. Recupera spazio — in modo rapido e sicuro." },
    pl: { nav_faq: "FAQ", badge_oss: "Open source", whatsnew_title: "Co nowego", whatsnew_all: "Wszystkie wydania", faq_title: "Najczęstsze pytania", faq_q1: "Czy SpaceMonger jest darmowy?", faq_a1: "Tak — jest darmowy i open source na licencji MIT.", faq_q2: "Czy jest bezpieczny i notaryzowany?", faq_a2: "Wydania są podpisane i notaryzowane przez Apple. Usunięte pliki trafiają do Kosza, a pliki systemowe są chronione.", faq_q3: "Jak otworzyć go za pierwszym razem?", faq_a3: "Jeśli macOS ostrzega o niezidentyfikowanym deweloperze, kliknij aplikację prawym przyciskiem i wybierz Otwórz.", faq_q4: "A co z moją prywatnością?", faq_a4: "SpaceMonger czyta tylko nazwy i rozmiary plików — nigdy zawartość — i nic nie wysyła poza Twojego Maca.", foot_releases: "Wydania", foot_issues: "Zgłoś problem", foot_privacy: "Prywatność", doc_desc: "Darmowy, natywny analizator miejsca na dysku dla macOS. Odzyskaj miejsce — szybko i bezpiecznie." },
    ru: { nav_faq: "Вопросы", badge_oss: "Открытый код", whatsnew_title: "Что нового", whatsnew_all: "Все выпуски", faq_title: "Частые вопросы", faq_q1: "SpaceMonger бесплатен?", faq_a1: "Да — он бесплатный и с открытым кодом под лицензией MIT.", faq_q2: "Это безопасно и нотаризовано?", faq_a2: "Выпуски подписаны и нотаризованы Apple. Удалённое попадает в Корзину, системные файлы защищены.", faq_q3: "Как открыть в первый раз?", faq_a3: "Если macOS предупреждает о неустановленном разработчике, щёлкните приложение правой кнопкой и выберите «Открыть».", faq_q4: "Как насчёт приватности?", faq_a4: "SpaceMonger читает только имена и размеры файлов — не содержимое — и ничего не отправляет за пределы вашего Mac.", foot_releases: "Выпуски", foot_issues: "Сообщить о проблеме", foot_privacy: "Конфиденциальность", doc_desc: "Бесплатный нативный анализатор места на диске для macOS. Верните место — быстро и безопасно." },
    es: { nav_faq: "FAQ", badge_oss: "Código abierto", whatsnew_title: "Novedades", whatsnew_all: "Todas las versiones", faq_title: "Preguntas frecuentes", faq_q1: "¿SpaceMonger es gratis?", faq_a1: "Sí — es gratis y de código abierto bajo licencia MIT.", faq_q2: "¿Es seguro y está notarizado?", faq_a2: "Las versiones están firmadas y notarizadas por Apple. Lo eliminado va a la Papelera y los archivos del sistema están protegidos.", faq_q3: "¿Cómo lo abro la primera vez?", faq_a3: "Si macOS avisa de un desarrollador no identificado, haz clic derecho en la app y elige Abrir.", faq_q4: "¿Y mi privacidad?", faq_a4: "SpaceMonger solo lee nombres y tamaños de archivos — nunca el contenido — y no envía nada fuera de tu Mac.", foot_releases: "Versiones", foot_issues: "Informar de un problema", foot_privacy: "Privacidad", doc_desc: "Un analizador de espacio en disco nativo y gratuito para macOS. Recupera espacio — rápido y seguro." },
    "pt-PT": { nav_faq: "FAQ", badge_oss: "Código aberto", whatsnew_title: "Novidades", whatsnew_all: "Todas as versões", faq_title: "Perguntas frequentes", faq_q1: "O SpaceMonger é gratuito?", faq_a1: "Sim — é gratuito e de código aberto sob a licença MIT.", faq_q2: "É seguro e autenticado?", faq_a2: "As versões são assinadas e autenticadas pela Apple. O que é eliminado vai para o Lixo e os ficheiros do sistema estão protegidos.", faq_q3: "Como o abro pela primeira vez?", faq_a3: "Se o macOS avisar sobre um programador não identificado, clique com o botão direito na app e escolha Abrir.", faq_q4: "E a minha privacidade?", faq_a4: "O SpaceMonger lê apenas nomes e tamanhos de ficheiros — nunca o conteúdo — e não envia nada para fora do seu Mac.", foot_releases: "Versões", foot_issues: "Reportar um problema", foot_privacy: "Privacidade", doc_desc: "Um analisador de espaço em disco nativo e gratuito para macOS. Recupere espaço — de forma rápida e segura." },
    sv: { nav_faq: "FAQ", badge_oss: "Öppen källkod", whatsnew_title: "Nyheter", whatsnew_all: "Alla versioner", faq_title: "Vanliga frågor", faq_q1: "Är SpaceMonger gratis?", faq_a1: "Ja — det är gratis och öppen källkod under MIT-licensen.", faq_q2: "Är det säkert och notariserat?", faq_a2: "Versioner är signerade och notariserade av Apple. Raderat hamnar i papperskorgen och systemfiler skyddas.", faq_q3: "Hur öppnar jag det första gången?", faq_a3: "Om macOS varnar för en oidentifierad utvecklare, högerklicka på appen och välj Öppna.", faq_q4: "Hur är det med min integritet?", faq_a4: "SpaceMonger läser bara filnamn och storlekar — aldrig innehåll — och skickar inget från din Mac.", foot_releases: "Versioner", foot_issues: "Rapportera ett problem", foot_privacy: "Integritet", doc_desc: "En gratis, inbyggd diskanalysator för macOS. Återta utrymme — snabbt och säkert." },
    tr: { nav_faq: "SSS", badge_oss: "Açık kaynak", whatsnew_title: "Yenilikler", whatsnew_all: "Tüm sürümler", faq_title: "Sıkça sorulan sorular", faq_q1: "SpaceMonger ücretsiz mi?", faq_a1: "Evet — MIT lisansı altında ücretsiz ve açık kaynaktır.", faq_q2: "Güvenli ve onaylı mı?", faq_a2: "Sürümler Apple tarafından imzalanır ve onaylanır. Silinenler Çöp'e gider, sistem dosyaları korunur.", faq_q3: "İlk kez nasıl açarım?", faq_a3: "macOS kimliği doğrulanmamış bir geliştiriciden olduğunu bildirirse, uygulamaya sağ tıklayın ve Aç'ı seçin.", faq_q4: "Gizliliğim ne olacak?", faq_a4: "SpaceMonger yalnızca dosya adlarını ve boyutlarını okur — içeriği asla — ve Mac'inizin dışına hiçbir şey göndermez.", foot_releases: "Sürümler", foot_issues: "Sorun bildir", foot_privacy: "Gizlilik", doc_desc: "macOS için ücretsiz, yerel bir disk kullanım analizcisi. Alanı geri kazanın — hızlı ve güvenli." },
    uk: { nav_faq: "Питання", badge_oss: "Відкритий код", whatsnew_title: "Що нового", whatsnew_all: "Усі випуски", faq_title: "Поширені запитання", faq_q1: "SpaceMonger безкоштовний?", faq_a1: "Так — він безкоштовний і з відкритим кодом за ліцензією MIT.", faq_q2: "Чи це безпечно й нотаризовано?", faq_a2: "Випуски підписані та нотаризовані Apple. Видалене потрапляє в Кошик, системні файли захищені.", faq_q3: "Як відкрити його вперше?", faq_a3: "Якщо macOS попереджає про неідентифікованого розробника, клацніть застосунок правою кнопкою та виберіть «Відкрити».", faq_q4: "А як щодо моєї приватності?", faq_a4: "SpaceMonger читає лише імена та розміри файлів — ніколи вміст — і нічого не надсилає за межі вашого Mac.", foot_releases: "Випуски", foot_issues: "Повідомити про проблему", foot_privacy: "Приватність", doc_desc: "Безкоштовний нативний аналізатор місця на диску для macOS. Поверніть місце — швидко й безпечно." },
    "zh-Hans": { nav_faq: "常见问题", badge_oss: "开源", whatsnew_title: "新功能", whatsnew_all: "所有版本", faq_title: "常见问题", faq_q1: "SpaceMonger 免费吗？", faq_a1: "是的——它在 MIT 许可下免费且开源。", faq_q2: "安全并已公证吗？", faq_a2: "版本由 Apple 签名并公证。删除的项目进入废纸篓，系统文件受保护。", faq_q3: "第一次如何打开？", faq_a3: "若 macOS 提示来自身份不明的开发者，请右键点按应用并选择“打开”。", faq_q4: "我的隐私如何？", faq_a4: "SpaceMonger 只读取文件名和大小——绝不读取内容——也不会把任何数据发送到你的 Mac 之外。", foot_releases: "版本", foot_issues: "报告问题", foot_privacy: "隐私", doc_desc: "一款免费的原生 macOS 磁盘用量分析器。快速、安全地收回空间。" },
    "zh-Hant": { nav_faq: "常見問題", badge_oss: "開源", whatsnew_title: "新功能", whatsnew_all: "所有版本", faq_title: "常見問題", faq_q1: "SpaceMonger 免費嗎？", faq_a1: "是的——它在 MIT 授權下免費且開源。", faq_q2: "安全並已公證嗎？", faq_a2: "版本由 Apple 簽署並公證。刪除的項目進入垃圾桶，系統檔案受保護。", faq_q3: "第一次如何開啟？", faq_a3: "若 macOS 提示來自未識別的開發者，請右鍵點按 App 並選擇「打開」。", faq_q4: "我的隱私如何？", faq_a4: "SpaceMonger 只讀取檔名與大小——絕不讀取內容——也不會把任何資料傳送到你的 Mac 之外。", foot_releases: "版本", foot_issues: "回報問題", foot_privacy: "隱私", doc_desc: "一款免費的原生 macOS 磁碟用量分析器。快速、安全地收回空間。" },
    ja: { nav_faq: "よくある質問", badge_oss: "オープンソース", whatsnew_title: "新機能", whatsnew_all: "すべてのリリース", faq_title: "よくある質問", faq_q1: "SpaceMonger は無料ですか？", faq_a1: "はい — MIT ライセンスの無料・オープンソースです。", faq_q2: "安全で公証済みですか？", faq_a2: "リリースは Apple により署名・公証されています。削除した項目はゴミ箱に入り、システムファイルは保護されます。", faq_q3: "初回はどう開きますか？", faq_a3: "macOS が未確認の開発元と警告する場合は、アプリを右クリックして「開く」を選びます。", faq_q4: "プライバシーは？", faq_a4: "SpaceMonger はファイル名とサイズのみを読み取り、内容は読み取りません。データを Mac の外に送信しません。", foot_releases: "リリース", foot_issues: "問題を報告", foot_privacy: "プライバシー", doc_desc: "無料のネイティブ macOS ディスク使用量アナライザー。容量を素早く安全に取り戻します。" }
  };

  // Conversion pass 2: stronger hero, free-badge, star CTA, comparison table.
  // hero_find / hero_free override the originals with a shorter benefit headline.
  var EXTRA2 = {
    en: { nav_compare: "Compare", hero_kicker: "Free disk-usage analyzer for macOS", hero_find: "Reclaim gigabytes. ", hero_free: "Free.", hero_free_badge: "100% free · Open source", star_cta: "Star on GitHub", compare_title: "SpaceMonger vs. paid alternatives", compare_sub: "Everything the paid apps do — and then some — without the price tag.", compare_col_them: "Paid apps", compare_price: "Price", compare_free: "Free", compare_langs: "Languages", compare_few: "A few", compare_oss: "Open source", compare_maps: "Sunburst & treemap", compare_cleanup: "Snapshot & purgeable cleanup", compare_collector: "Batch-to-Trash collector", compare_privacy: "No account, no analytics" },
    nl: { nav_compare: "Vergelijk", hero_kicker: "Gratis schijfanalyse voor macOS", hero_find: "Win gigabytes terug. ", hero_free: "Gratis.", hero_free_badge: "100% gratis · Open source", star_cta: "Ster op GitHub", compare_title: "SpaceMonger vs. betaalde alternatieven", compare_sub: "Alles wat de betaalde apps doen — en meer — zonder prijskaartje.", compare_col_them: "Betaalde apps", compare_price: "Prijs", compare_free: "Gratis", compare_langs: "Talen", compare_few: "Enkele", compare_oss: "Open source", compare_maps: "Sunburst & treemap", compare_cleanup: "Momentopname- & opschoonbare opruiming", compare_collector: "Verzamelaar naar prullenmand", compare_privacy: "Geen account, geen analytics" },
    fr: { nav_compare: "Comparer", hero_kicker: "Analyseur d'espace disque gratuit pour macOS", hero_find: "Récupérez des gigaoctets. ", hero_free: "Gratuit.", hero_free_badge: "100% gratuit · Open source", star_cta: "Étoile sur GitHub", compare_title: "SpaceMonger vs. alternatives payantes", compare_sub: "Tout ce que font les apps payantes — et plus — sans le prix.", compare_col_them: "Apps payantes", compare_price: "Prix", compare_free: "Gratuit", compare_langs: "Langues", compare_few: "Quelques-unes", compare_oss: "Open source", compare_maps: "Soleil & treemap", compare_cleanup: "Nettoyage instantanés & purgeable", compare_collector: "Collecteur vers la corbeille", compare_privacy: "Sans compte, sans analyse" },
    de: { nav_compare: "Vergleich", hero_kicker: "Kostenloser Speicheranalysator für macOS", hero_find: "Gigabyte zurückgewinnen. ", hero_free: "Kostenlos.", hero_free_badge: "100% kostenlos · Open Source", star_cta: "Auf GitHub favorisieren", compare_title: "SpaceMonger vs. kostenpflichtige Alternativen", compare_sub: "Alles, was die Bezahl-Apps können — und mehr — ohne Preisschild.", compare_col_them: "Bezahl-Apps", compare_price: "Preis", compare_free: "Kostenlos", compare_langs: "Sprachen", compare_few: "Wenige", compare_oss: "Open Source", compare_maps: "Sunburst & Treemap", compare_cleanup: "Schnappschuss- & purgeable-Bereinigung", compare_collector: "Sammler in den Papierkorb", compare_privacy: "Kein Konto, keine Analyse" },
    it: { nav_compare: "Confronta", hero_kicker: "Analizzatore di spazio su disco gratuito per macOS", hero_find: "Recupera gigabyte. ", hero_free: "Gratis.", hero_free_badge: "100% gratuito · Open source", star_cta: "Stella su GitHub", compare_title: "SpaceMonger vs. alternative a pagamento", compare_sub: "Tutto ciò che fanno le app a pagamento — e di più — senza il prezzo.", compare_col_them: "App a pagamento", compare_price: "Prezzo", compare_free: "Gratis", compare_langs: "Lingue", compare_few: "Alcune", compare_oss: "Open source", compare_maps: "Sunburst & treemap", compare_cleanup: "Pulizia snapshot & purgeable", compare_collector: "Raccoglitore verso il Cestino", compare_privacy: "Nessun account, nessuna analisi" },
    pl: { nav_compare: "Porównanie", hero_kicker: "Darmowy analizator miejsca na dysku dla macOS", hero_find: "Odzyskaj gigabajty. ", hero_free: "Za darmo.", hero_free_badge: "100% darmowe · Open source", star_cta: "Gwiazdka na GitHub", compare_title: "SpaceMonger vs. płatne alternatywy", compare_sub: "Wszystko, co robią płatne aplikacje — i więcej — bez ceny.", compare_col_them: "Płatne aplikacje", compare_price: "Cena", compare_free: "Za darmo", compare_langs: "Języki", compare_few: "Kilka", compare_oss: "Open source", compare_maps: "Sunburst & treemap", compare_cleanup: "Czyszczenie migawek & purgeable", compare_collector: "Kolektor do Kosza", compare_privacy: "Bez konta, bez analityki" },
    ru: { nav_compare: "Сравнение", hero_kicker: "Бесплатный анализатор диска для macOS", hero_find: "Верните гигабайты. ", hero_free: "Бесплатно.", hero_free_badge: "100% бесплатно · Открытый код", star_cta: "Звезда на GitHub", compare_title: "SpaceMonger против платных аналогов", compare_sub: "Всё, что умеют платные приложения — и даже больше — без ценника.", compare_col_them: "Платные приложения", compare_price: "Цена", compare_free: "Бесплатно", compare_langs: "Языки", compare_few: "Несколько", compare_oss: "Открытый код", compare_maps: "Sunburst & treemap", compare_cleanup: "Очистка снимков и очищаемого", compare_collector: "Коллектор в Корзину", compare_privacy: "Без аккаунта и аналитики" },
    es: { nav_compare: "Comparar", hero_kicker: "Analizador de espacio en disco gratis para macOS", hero_find: "Recupera gigabytes. ", hero_free: "Gratis.", hero_free_badge: "100% gratis · Código abierto", star_cta: "Estrella en GitHub", compare_title: "SpaceMonger vs. alternativas de pago", compare_sub: "Todo lo que hacen las apps de pago — y más — sin el precio.", compare_col_them: "Apps de pago", compare_price: "Precio", compare_free: "Gratis", compare_langs: "Idiomas", compare_few: "Pocos", compare_oss: "Código abierto", compare_maps: "Sunburst & treemap", compare_cleanup: "Limpieza de instantáneas y purgable", compare_collector: "Colector a la Papelera", compare_privacy: "Sin cuenta ni analíticas" },
    "pt-PT": { nav_compare: "Comparar", hero_kicker: "Analisador de espaço em disco gratuito para macOS", hero_find: "Recupere gigabytes. ", hero_free: "Grátis.", hero_free_badge: "100% gratuito · Código aberto", star_cta: "Estrela no GitHub", compare_title: "SpaceMonger vs. alternativas pagas", compare_sub: "Tudo o que as apps pagas fazem — e mais — sem o preço.", compare_col_them: "Apps pagas", compare_price: "Preço", compare_free: "Grátis", compare_langs: "Idiomas", compare_few: "Poucos", compare_oss: "Código aberto", compare_maps: "Sunburst & treemap", compare_cleanup: "Limpeza de instantâneos & purgável", compare_collector: "Coletor para o Lixo", compare_privacy: "Sem conta, sem análises" },
    sv: { nav_compare: "Jämför", hero_kicker: "Gratis diskanalysator för macOS", hero_find: "Återta gigabyte. ", hero_free: "Gratis.", hero_free_badge: "100% gratis · Öppen källkod", star_cta: "Stjärnmärk på GitHub", compare_title: "SpaceMonger vs. betalalternativ", compare_sub: "Allt betalapparna gör — och mer — utan prislappen.", compare_col_them: "Betalappar", compare_price: "Pris", compare_free: "Gratis", compare_langs: "Språk", compare_few: "Några", compare_oss: "Öppen källkod", compare_maps: "Sunburst & treemap", compare_cleanup: "Rensning av ögonblicksbilder & rensningsbart", compare_collector: "Samlare till papperskorgen", compare_privacy: "Inget konto, ingen analys" },
    tr: { nav_compare: "Karşılaştır", hero_kicker: "macOS için ücretsiz disk kullanım analizcisi", hero_find: "Gigabaytları geri kazanın. ", hero_free: "Ücretsiz.", hero_free_badge: "%100 ücretsiz · Açık kaynak", star_cta: "GitHub'da yıldız ver", compare_title: "SpaceMonger vs. ücretli alternatifler", compare_sub: "Ücretli uygulamaların yaptığı her şey — ve fazlası — fiyat etiketi olmadan.", compare_col_them: "Ücretli uygulamalar", compare_price: "Fiyat", compare_free: "Ücretsiz", compare_langs: "Diller", compare_few: "Birkaç", compare_oss: "Açık kaynak", compare_maps: "Sunburst & treemap", compare_cleanup: "Anlık görüntü & temizlenebilir temizliği", compare_collector: "Çöp'e toplu taşıyıcı", compare_privacy: "Hesap yok, analiz yok" },
    uk: { nav_compare: "Порівняння", hero_kicker: "Безкоштовний аналізатор диска для macOS", hero_find: "Поверніть гігабайти. ", hero_free: "Безкоштовно.", hero_free_badge: "100% безкоштовно · Відкритий код", star_cta: "Зірка на GitHub", compare_title: "SpaceMonger проти платних аналогів", compare_sub: "Усе, що вміють платні застосунки — і навіть більше — без цінника.", compare_col_them: "Платні застосунки", compare_price: "Ціна", compare_free: "Безкоштовно", compare_langs: "Мови", compare_few: "Кілька", compare_oss: "Відкритий код", compare_maps: "Sunburst & treemap", compare_cleanup: "Очищення знімків і очищуваного", compare_collector: "Колектор у Кошик", compare_privacy: "Без облікового запису та аналітики" },
    "zh-Hans": { nav_compare: "对比", hero_kicker: "macOS 免费磁盘用量分析器", hero_find: "找回数 GB 空间。", hero_free: "免费。", hero_free_badge: "100% 免费 · 开源", star_cta: "在 GitHub 加星", compare_title: "SpaceMonger 对比付费替代品", compare_sub: "付费应用能做的一切——甚至更多——无需付费。", compare_col_them: "付费应用", compare_price: "价格", compare_free: "免费", compare_langs: "语言", compare_few: "少数", compare_oss: "开源", compare_maps: "旭日图 & 矩形树图", compare_cleanup: "快照与可清除空间清理", compare_collector: "批量移入废纸篓收集箱", compare_privacy: "无账户、无分析" },
    "zh-Hant": { nav_compare: "對比", hero_kicker: "macOS 免費磁碟用量分析器", hero_find: "找回數 GB 空間。", hero_free: "免費。", hero_free_badge: "100% 免費 · 開源", star_cta: "在 GitHub 加星", compare_title: "SpaceMonger 對比付費替代品", compare_sub: "付費應用能做的一切——甚至更多——無需付費。", compare_col_them: "付費應用", compare_price: "價格", compare_free: "免費", compare_langs: "語言", compare_few: "少數", compare_oss: "開源", compare_maps: "旭日圖 & 矩形樹狀圖", compare_cleanup: "快照與可清除空間清理", compare_collector: "批次移入垃圾桶收集箱", compare_privacy: "無帳戶、無分析" },
    ja: { nav_compare: "比較", hero_kicker: "macOS 向け無料ディスク使用量アナライザー", hero_find: "ギガ単位で取り戻す。", hero_free: "無料。", hero_free_badge: "100% 無料 · オープンソース", star_cta: "GitHub でスター", compare_title: "SpaceMonger と有料の代替アプリ", compare_sub: "有料アプリができることすべて — それ以上を — 価格なしで。", compare_col_them: "有料アプリ", compare_price: "価格", compare_free: "無料", compare_langs: "言語", compare_few: "数言語", compare_oss: "オープンソース", compare_maps: "サンバースト & ツリーマップ", compare_cleanup: "スナップショット & パージ可能領域の整理", compare_collector: "まとめてゴミ箱へのコレクター", compare_privacy: "アカウント不要・解析なし" }
  };

  [EXTRA, EXTRA2].forEach(function (src) {
    Object.keys(src).forEach(function (c) {
      if (DICT[c]) for (var k in src[c]) DICT[c][k] = src[c][k];
    });
  });

  var current = "en";

  function t(key, lang) {
    var l = lang || current;
    var v = DICT[l] && DICT[l][key];
    if (v == null) v = DICT.en[key];
    return v == null ? key : v;
  }

  function renderMeta() {
    var m = document.getElementById("heroMeta");
    if (!m) return;
    var ver = window.__latest && window.__latest.version;
    m.textContent = ver ? t("meta_latest").replace("%v", ver) : t("meta_default");
  }

  function apply(lang) {
    if (!DICT[lang]) lang = "en";
    current = lang;
    document.documentElement.lang = lang;
    document.querySelectorAll("[data-i18n]").forEach(function (el) {
      el.textContent = t(el.getAttribute("data-i18n"), lang);
    });
    document.querySelectorAll("[data-i18n-html]").forEach(function (el) {
      el.innerHTML = t(el.getAttribute("data-i18n-html"), lang);
    });
    var sel = document.getElementById("langSelect");
    if (sel) sel.value = lang;
    document.title = "SpaceMonger — " + t("hero_find", lang).trim() + " " + t("hero_free", lang);
    var md = document.getElementById("metaDesc");
    if (md) md.setAttribute("content", t("doc_desc", lang));
    try {
      localStorage.setItem("sm_lang", lang);
      var u = new URL(window.location.href);
      u.searchParams.set("lang", lang);
      window.history.replaceState(null, "", u);
    } catch (e) {}
    renderMeta();
  }

  function detect() {
    try {
      var p = new URLSearchParams(window.location.search).get("lang");
      if (p && DICT[p]) return p;
    } catch (e) {}
    try {
      var saved = localStorage.getItem("sm_lang");
      if (saved && DICT[saved]) return saved;
    } catch (e) {}
    var cands = (navigator.languages && navigator.languages.length)
      ? navigator.languages : [navigator.language || "en"];
    var two = { en: "en", nl: "nl", fr: "fr", de: "de", it: "it", pl: "pl",
                ru: "ru", es: "es", sv: "sv", tr: "tr", uk: "uk", ja: "ja" };
    for (var i = 0; i < cands.length; i++) {
      var l = (cands[i] || "").toLowerCase();
      if (l.indexOf("zh") === 0) return /hant|tw|hk|mo/.test(l) ? "zh-Hant" : "zh-Hans";
      if (l.indexOf("pt") === 0) return "pt-PT";
      if (two[l.slice(0, 2)]) return two[l.slice(0, 2)];
    }
    return "en";
  }

  function init() {
    var sel = document.getElementById("langSelect");
    if (sel) {
      sel.innerHTML = LANGS.map(function (p) {
        return '<option value="' + p[0] + '">' + p[1] + "</option>";
      }).join("");
      sel.addEventListener("change", function (e) { apply(e.target.value); });
    }
    apply(detect());
  }

  window.SMI18N = { apply: apply, t: t, renderMeta: renderMeta };
  window.renderMeta = renderMeta;

  if (document.readyState === "loading") {
    document.addEventListener("DOMContentLoaded", init);
  } else {
    init();
  }
})();
