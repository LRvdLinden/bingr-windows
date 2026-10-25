# Changelog · Windows

Alle versies van Bingr voor Windows (installer voor Windows 10 en 11). De app toont de webspeler van bingr.online: verbeteringen daaraan staan bij de website op [bingr.online/changelog](https://bingr.online/changelog/). iPhone, iPad, Apple TV en Mac: [iptv-ios-appletv](https://github.com/LRvdLinden/iptv-ios-appletv/blob/main/CHANGELOG.md) · Android en Samsung TV: [bingr-android](https://github.com/LRvdLinden/bingr-android/blob/main/CHANGELOG.md).

Per build, ingedeeld per apparaatsoort: **Nieuw**, **Verbeterd** en **Opgelost**.

## Versie 1.0.1 · Build 150
_25 oktober 2026_

### Alle apps en de website

**Verbeterd**

- Categorieën met dezelfde naam worden één categorie, zonder dubbele titels en met de talen als label; aan- en uitzetten geldt voor alle bronnen tegelijk

**Opgelost**

- Taal-, land- en kwaliteitsaanduidingen zoals "| NL |", "MULTI / LINGO", "[EN]" of "4K" verdwijnen overal uit de namen van categorieën, en namen in hoofdletters krijgen nette hoofdletters
- Ontdek categorieën toont Netflix niet meer twee keer en toont de logo's van streamingdiensten weer

## Versie 1.0.1 · Build 149
_25 oktober 2026_

### Alle apps en de website

**Nieuw**

- Op Home een rij Ontdek categorieën met posters, een gekleurde balk en het logo van de streamingdienst

**Verbeterd**

- Zoeken vindt meer: losse woorden in elke volgorde, zonder accenten en voorvoegsels en met een kleine typefout

**Opgelost**

- Geen haperingen meer bij sync toepassen en bewaren: datums worden niet meer per item opnieuw opgemaakt

### iOS, iPadOS, tvOS, macOS, Windows en Website

**Verbeterd**

- Zoeken toont ook treffers uit verborgen categorieën, onderaan

### iOS, iPadOS, tvOS, macOS, Android, Android TV, Windows en Website

**Verbeterd**

- Zoeken doorzoekt ook de catalogi van Stremio-add-ons

### Android, Android TV, Samsung TV (Tizen), Windows, LG TV (webOS) en Website

**Verbeterd**

- Grote servers laden sneller en met veel minder geheugen; verborgen categorieën worden niet meer ingelezen

## Versie 1.0.1 · Build 148
_25 oktober 2026_

### Alle apps en de website

**Verbeterd**

- Een heel grote catalogus wordt in kleine stukjes ingelezen en toegepast, zodat de app blijft reageren en minder geheugen gebruikt
- Diagnose in de taal van de app, met de langste hapering, het bijwerken per server, geleverd naast zichtbaar en haperingen tijdens het afspelen

### Server

**Verbeterd**

- Een diagnose bij een supportvraag laat nu zien waar de app bij het starten en bijwerken op wacht, hoeveel van je catalogus verborgen is en of het afspelen haperde
- Mails van Bingr: de afbeelding staat niet meer in een donker kader en een afbeelding die niet laadt geeft geen groot leeg vlak meer

## Versie 1.0.1 · Build 147
_24 oktober 2026_

### Alle apps en de website

**Verbeterd**

- De startdiagnose toont bovenaan of de start goed, traag of vastgelopen was, met app-tijd los van wachten op jou en de vorige start
- Een diagnose naar support bevat altijd de startdiagnose van deze en de vorige start

### iOS, iPadOS, tvOS, macOS, Windows en Website

**Opgelost**

- Series en films van grote of trage Xtream-servers worden los van elkaar opgehaald, met meer tijd en een nieuwe poging; een trage serieslijst houdt films en zenders niet meer op

### iOS, iPadOS, tvOS, macOS, Android, Android TV, Samsung TV (Tizen), Windows en Website

**Nieuw**

- Een LG-tv staat in je apparatenlijst en bij Wie kijkt er nu als LG TV

**Verbeterd**

- Bij vastlopen legt de diagnose vast welke taak het was en of de app op de voorgrond stond
- De diagnose toont per server of zenders, films en series geleverd zijn, leeg waren, mislukten of allemaal verborgen zijn, plus de soort verbinding en de opslag als één totaal

**Opgelost**

- Na het starten loopt Bingr niet meer vast bij een grote bibliotheek: zwaar werk zoals sorteren, filteren, Mijn lijst, de tv-gids, opslaan en pincodes gebeurt op de achtergrond of in kleine stukjes

### Website en Server

**Verbeterd**

- Statuspagina: een mislukte build geeft niet meer meteen een grote storing; alleen de echte build telt, en pas na twee mislukte builds op rij (of na 2 uur) is het een storing

### Server

**Nieuw**

- De server kent de LG TV-app (webOS)

**Verbeterd**

- Support: de diagnose uit de app is uitgebreider en adressen en servernamen worden er beter uit gehaald

## Versie 1.0.1 · Build 146
_24 oktober 2026_

### Alle apps en de website

**Nieuw**

- Support in de app (Instellingen → Support): je tickets in Open, In behandeling en Gesloten bekijken, reageren, sluiten en een nieuw ticket maken, met een badge bij een nieuw antwoord
- Diagnose in Instellingen: startdiagnose en app-diagnose met je apparaat, systeem, netwerk, opslag en geheugen, zonder persoonsgegevens met één knop naar support te sturen
- Servers vernieuwen in het profielmenu, boven Wissel profiel

**Verbeterd**

- Instellingen opnieuw ingedeeld in tabs: Algemeen, Afspelen, Taal en ondertitels, Servers, Profielen en kinderslot, Account, Koppelingen, Support, Diagnose en Over
- De tv-gids wordt samen met je servers bijgewerkt; is hij verlopen, dan zie je een melding met Bijwerken
- Windows-apparaten heten Windows, met een eigen icoon, in de apparatenlijst en bij Wie kijkt er nu

### Alle apps, de website en de server

**Verbeterd**

- Pincodes worden alleen nog als beveiligde hash bewaard en gesynchroniseerd en zijn niet meer terug te lezen
- Profielen synchroniseren versleuteld via de Bingr-server

### iOS, iPadOS, macOS, Android, Windows en Website

**Nieuw**

- Pushmelding bij een antwoord van support; tikken opent het ticket

### Windows

**Verbeterd**

- De Windows-app meldt zich bij je account als Windows

### Windows en Website

**Verbeterd**

- Na 5 foute pincodes geldt ook in de webspeler een oplopende wachttijd

### Server

**Verbeterd**

- Kijkgeschiedenis, statistieken en supportberichten staan versleuteld opgeslagen

**Opgelost**

- Profielfoto's zijn beter afgeschermd per account

## Versie 1.0.1 · Build 145
_24 oktober 2026_

### Alle apps en de website

**Nieuw**

- Na het kiezen van een profiel vraagt Bingr of je je servers nu wilt bijwerken (Nu bijwerken of Later); je bewaarde lijst staat meteen klaar
- Nieuwe instelling Servers laden bij openen: Vragen, Altijd of Nooit, alleen handmatig (per apparaat)

**Verbeterd**

- Geen automatisch verversen op tijd meer: de vernieuwtermijn (elke dag, week enz.) is vervallen; je kiest zelf wanneer, of vernieuwt handmatig
- Bijwerken gaat één server tegelijk op de achtergrond, de open server eerst, en nooit tijdens het afspelen

## Versie 1.0.1 · Build 142
_23 oktober 2026_

### Alle apps en de website

**Verbeterd**

- Nieuw op Bingr staat op de plek van Nieuw toegevoegd, met Film of Serie op elke tegel
- Verder kijken toont de cover van de film of serie

**Opgelost**

- Titels die je na zoeken aan Mijn lijst toevoegt (ook van een andere server of een aanbeveling) staan er meteen in, ook op je andere apparaten

### Alle apps, de website en de server

**Verbeterd**

- Inloggen is beter beschermd tegen raden, met een duidelijke melding bij te veel pogingen
- Een nieuw wachtwoord moet minstens 8 tekens hebben

### Windows en Website

**Verbeterd**

- De webspeler is strenger beveiligd: alle scripts komen van Bingr zelf

### Website en Server

**Verbeterd**

- Een supportticket koppel je aan je account en is alleen voor jou zichtbaar

### Server

**Verbeterd**

- De webproxy werkt alleen nog voor je eigen servers, met limieten per account

## Versie 1.0.1 · Build 140
_23 oktober 2026_

### Windows

**Nieuw**

- Bingr voor Windows: Installeer Bingr op je Windows 10- of 11-pc en kijk je zenders, films en series in een eigen venster, met volledig scherm, mediatoetsen en je Bingr-account (inloggen met e-mail of koppelcode)

### Server

**Opgelost**

- Mails aan support@bingr.online worden weer altijd een ticket, ook als ze al gelezen waren; reacties komen in het bestaande ticket en niets wordt dubbel geïmporteerd
