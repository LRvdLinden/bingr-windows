# Changelog · Windows

Alle versies van Bingr voor Windows (installer voor Windows 10 en 11). De app toont de webspeler van bingr.online: verbeteringen daaraan staan bij de website op [bingr.online/changelog](https://bingr.online/changelog/). iPhone, iPad, Apple TV en Mac: [iptv-ios-appletv](https://github.com/LRvdLinden/iptv-ios-appletv/blob/main/CHANGELOG.md) · Android en Samsung TV: [bingr-android](https://github.com/LRvdLinden/bingr-android/blob/main/CHANGELOG.md).

Per build, ingedeeld per apparaatsoort: **Nieuw**, **Verbeterd** en **Opgelost**.

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
