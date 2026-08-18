# Business Conclusions — Olist E-commerce Analysis

> Analiza danych brazylijskiego marketplace Olist (~99 tys. zamówień, 2016–2018).
> Szukałem dźwigni wzrostu i ryzyk operacyjnych, a potem przekładałem je na rekomendacje,
> które da się zmierzyć.

---

## 1. Kontekst i cel

Olist łączy małych i średnich sprzedawców z klientami największych brazylijskich platform
e-commerce, biorąc na siebie logistykę i płatności. Dane obejmują 9 powiązanych tabel
(zamówienia, pozycje, płatności, recenzje, sprzedawcy, klienci, produkty, geolokalizacja)
i około 99 tys. zamówień z lat 2016–2018.

**Zakres ustaliłem, zanim policzyłem cokolwiek.** Wszystkie metryki liczę na zamówieniach
o statusie `delivered`: 96 478 z 99 441, czyli 97% wolumenu. Tak samo w notebookach, w SQL-u
i w dashboardzie. Jedyny świadomy wyjątek to analiza anulacji w `sql/04`, która z definicji
potrzebuje wszystkich statusów.

Nie jest to formalność. Kiedy raz policzyłem satysfakcję na wszystkich recenzjach zamiast na
dostarczonych, średnia ocena wyszła 4,09 zamiast 4,16 i nic w kodzie nie zaprotestowało.
Rating sprzedawcy liczę na poziomie zamówienia: jedna recenzja to jeden głos, niezależnie od
tego, ile pozycji sprzedawca miał w koszyku.

Pytanie, na które odpowiadam: **co napędza przychód marketplace i co realnie zagraża jego
skalowaniu — po stronie retencji klientów i po stronie jakości sprzedawców?** Chodziło mi
o wskazanie dźwigni, na które platforma może wpłynąć operacyjnie, a nie o opisanie danych.

---

## 2. Kluczowe wnioski (Executive Summary)

- **Przychód całkowity:** 13 221 498 BRL | **Zamówienia:** 96 478 | **AOV:** 137,04 BRL (mediana 86,57 BRL)
- **Pareto sprzedawców:** top 20% generuje **82,3%** przychodu (z 2 970 sprzedawców z dostarczonymi zamówieniami)
- **Retencja:** wraca tylko **3,0%** klientów (2 801 z 93 358 unikalnych)
- **Dostawa a satysfakcja:** do 7 dni **4,41★**, powyżej 30 dni **2,18★**
- **Terminowość:** **91,9%** zamówień na czas, średni czas dostawy 12,1 dnia (mediana 10)

Olist bardzo dobrze pozyskuje klientów i sprzedaje im raz. Terminowość jest wysoka, AOV zdrowe,
a przychód ma wyraźnego lidera w postaci top 20% sprzedawców. Problem leży gdzie indziej.

Retencja praktycznie nie istnieje, więc każdy złoty przychodu wymaga dokupienia kolejnego
klienta. Jakość obsługi zależy od dwóch rzeczy, nad którymi platforma panuje tylko częściowo:
czasu dostawy i długiego ogona słabych sprzedawców. Wzrost jest realny, ale kupowany, nie
budowany.

---

## 3. Analiza szczegółowa

### 3a. Sprzedaż i sezonowość

Szczyt sprzedaży wypada na Black Friday w listopadzie 2017, z wyraźnym skokiem miesiąc do
miesiąca (`sql/03`). Trzy najmocniejsze kategorie przychodowo:

1. health_beauty — 1 233 132 BRL (479 sprzedawców)
2. watches_gifts — 1 166 177 BRL (95 sprzedawców)
3. bed_bath_table — 1 023 435 BRL (189 sprzedawców)

Dwie czołowe kategorie mają niemal identyczny przychód i zupełnie różną strukturę rynku. To
było pierwsze miejsce, w którym liczby zmusiły mnie do zmiany zdania: patrząc tylko na ranking
przychodu, wyglądały na ten sam typ biznesu.

`health_beauty` jest rozdrobniona — 479 sprzedawców, średnio około 2 574 BRL na sprzedawcę.
Taki rynek jest konkurencyjny i odporny na odejście pojedynczego gracza, ale trudno w nim
pilnować jakości. `watches_gifts` jest skoncentrowana: 95 sprzedawców, średnio około 12 275 BRL,
czyli mniej więcej 4,8 raza więcej na głowę. Wysoka efektywność, ale i realne ryzyko zależności.

Wniosek praktyczny: te dwie kategorie potrzebują innych strategii utrzymania sprzedawcy.
W pierwszej liczy się standaryzacja jakości, w drugiej opieka nad kluczowymi partnerami.

### 3b. Sprzedawcy — koncentracja i jakość

Top 20% sprzedawców odpowiada za 82,3% przychodu. Jednocześnie **343 sprzedawców, czyli około
11,6% z 2 965 ocenionych**, ma rating poniżej 3,5. Rating liczę na poziomie zamówienia i tylko
na zamówieniach dostarczonych.

Najciekawszy przypadek to kategoria office_furniture. Jeden sprzedawca robi 64% jej przychodu
przy 970 zamówieniach i ratingu 3,49, więc samym wolumenem wyznacza ocenę całej kategorii.
Tymczasem sprzedawca numer dwa, przy 122 zamówieniach, trzyma 4,25.

Ta para liczb jest ważniejsza, niż wygląda. Gdyby słaba ocena wynikała z charakteru produktu,
oba sklepy miałyby podobny rating. Skoro nie mają, **problem jest operacyjny, nie produktowy** —
a to znaczy, że da się go naprawić.

Platforma ma tu dwa różne zagrożenia naraz. Słaba jakość ogona psuje reputację całego
marketplace, bo klient ocenia „Olist", a nie konkretnego sprzedawcę. Do tego pojedynczy
dominator potrafi zaniżyć ocenę całej kategorii. Kontrola jakości musi więc działać na dwóch
poziomach: bramka wejścia dla ogona i celowana interwencja u dużych, ale słabych sprzedawców.

### 3c. Klienci i retencja

93 358 unikalnych klientów, repeat rate **3,0%**, około 1,03 zamówienia na klienta.

To najpoważniejszy problem strukturalny w całej analizie i jedyna liczba, którą sprawdzałem
trzy razy, bo wydawała mi się zbyt niska. Jest poprawna.

Praktycznie każdy klient jest jednorazowy. Koszt pozyskania ponosi się raz i nie ma go z czego
zamortyzować, bo wartość życiowa klienta jest niemal równa jednemu AOV, czyli około 137 BRL.
W zdrowym marketplace LTV powinno być wielokrotnością CAC. Tutaj relacja jest niebezpiecznie
blisko granicy opłacalności.

Konsekwencja jest prosta: wzrost przychodu zależy całkowicie od ciągłych wydatków
marketingowych. Kiedy budżet akwizycji spada, przychód spada razem z nim. Retencja nie jest
w tym modelu miłym dodatkiem, tylko warunkiem rentowności.

### 3d. Dostawa i logistyka

Średni czas dostawy to 12,1 dnia (mediana 10), terminowość 91,9%. Geograficznie: São Paulo
8,3 dnia, a stany północne AP 26,7 i AM 26,0 dnia, czyli mniej więcej trzy razy wolniej.

Rating w zależności od czasu dostawy:

| Czas dostawy | Rating |
|---|---|
| ≤ 7 dni | 4,41★ |
| 8–14 dni | 4,29★ |
| 15–21 dni | 4,10★ |
| 22–30 dni | 3,49★ |
| > 30 dni | 2,18★ |

Czas dostawy jest najsilniejszym pojedynczym driverem satysfakcji w tych danych. Różnica
między dostawą do 7 dni a powyżej 30 to spadek o ponad 2,2 gwiazdki.

Ważniejszy jest jednak kształt tego spadku, bo nie jest liniowy. Do 21 dni rating trzyma się
na poziomie co najmniej 4,1. Załamanie przychodzi dopiero w przedziale 22–30 dni, gdzie spada
do 3,49. **Próg bólu klienta leży przy trzech tygodniach, nie przy dwóch** — początkowo
zakładałem 14 dni i musiałem tę tezę poprawić, gdy zobaczyłem, że przedział 15–21 dni wciąż
daje 4,10.

Geografia mówi, gdzie jest dźwignia. To nie jest problem całej platformy, tylko kilku stanów
Północy. Poprawa nie wymaga więc przebudowy sieci, a celowanej interwencji w wąskim,
zidentyfikowanym regionie. To znacznie tańsze i szybsze.

### 3e. Wzorce czasowe

Zakupy koncentrują się w dni robocze w paśmie 10–17, ze szczytem o 16:00 (najwyższa pojedyncza
komórka heatmapy to wtorek 14:00). Niedziela ma najniższą aktywność dzienną, ale najwyższy
udział wieczoru: **38% zamówień między 18 a 22**, wobec 26–31% w pozostałe dni.

Te dwa okna nadają się do czegoś innego. Pasmo robocze to naturalny czas na kampanie
konwersyjne i remarketing, bo intencja zakupowa jest wtedy najwyższa. Niedzielny wieczór lepiej
wykorzystać na budowanie zaangażowania: przeglądanie, newsletter, przypomnienie o zaplanowanym
zakupie. Wniosek operacyjny: harmonogram push i e-maili powinien różnić się dniem tygodnia,
a nie być jednolity.

---

## 4. Rekomendacje biznesowe

Trzymałem się jednej zasady: każda rekomendacja musi wynikać z konkretnej liczby powyżej.
Jeśli nie potrafiłem jej wskazać, rekomendacja wypadała.

**1. SLA dostawy: twardy limit 21 dni, cel operacyjny 14 dni.**
Rating trzyma się co najmniej 4,1 do 21 dni, a potem spada do 3,49 (22–30 dni) i 2,18
(powyżej 30). Priorytet dla stanów Północy, gdzie AP ma 26,7 a AM 26,0 dnia. Cel mierzalny:
skrócić medianę dostawy w AP, AM i AL poniżej 18 dni w dwa kwartały, na przykład przez hub
regionalny albo renegocjację stawek kuriera dla regionu. Zgodnie z zależnością rating do czasu
powinno to podnieść tamtejszą ocenę o mniej więcej 0,6 do 1 gwiazdki.

**2. Quality gate przy wejściu dla małych sprzedawców.**
343 sprzedawców (11,6%) ma rating poniżej 3,5, w większości w długim ogonie. Proponuję okres
próbny z monitoringiem pierwszych 20 zamówień oraz automatyczny alert, gdy rating spadnie
poniżej 3,5. Cel: zejść z 11,6% do poniżej 8% w rok, bez hamowania napływu nowych sprzedawców.

**3. Program retencyjny.**
Retencja 3,0% oznacza, że firma płaci CAC za klientów jednorazowych, a LTV równa się mniej
więcej jednemu AOV. Nawet niewielka poprawa, z 3,0% do 6%, podwaja zamortyzowaną wartość
klienta. Konkretnie: kupon na drugi zakup w kategorii komplementarnej, ważny 30 dni od dostawy
i wydawany po pozytywnej recenzji. Sprzęga to retencję z jakością zamiast traktować je osobno.

**4. Program naprawczy dla dużych, ale słabych sprzedawców.**
Dotyczy przypadków takich jak office_furniture (64% przychodu kategorii przy ratingu 3,49) oraz
listy 35 sprzedawców z `sql/04`, którzy mają przychód powyżej 10 tys. BRL i rating poniżej 3,5
albo ponad 15% spóźnień. Najgorszy z nich: 21,5 tys. BRL przychodu, rating 1,93 i 64% spóźnień.
Cel: rating powyżej 4,0 i spóźnienia poniżej 8% w dwa kwartały, pod rygorem obniżenia
widoczności w wyszukiwarce platformy.

---

## 5. Ograniczenia analizy

Kilka rzeczy, o których trzeba pamiętać, czytając powyższe liczby.

Dane są historyczne (Brazylia, 2016–2018), więc opisują ten rynek i ten okres, a nie
e-commerce w ogóle. Około 1,4% pozycji nie ma sklasyfikowanej kategorii ('unknown' plus dwie
kategorie bez tłumaczenia).

Metryka `# Seller Orders` jest zawyżona przy zamówieniach z wieloma sprzedawcami, bo jedno
zamówienie liczy się u każdego z nich. Z tego samego powodu rating sprzedawcy bywa zaszumiony:
recenzja dotyczy całego doświadczenia zakupowego, a przypisuje się ją każdemu sprzedawcy
w koszyku. Nie da się więc zawsze wskazać, kto odpowiada za złą ocenę.

Nie mam danych kosztowych — ani CAC, ani marży, ani prowizji Olista. Wszystko, co piszę
o rentowności retencji i relacji LTV do CAC, jest więc kierunkowe. To hipoteza do potwierdzenia
danymi finansowymi, nie policzony wynik.

Repeat rate liczę po `customer_unique_id` na zamówieniach dostarczonych. Klienci, którzy wrócili
po zamknięciu okna danych, czyli po 2018 roku, są niewidoczni. Faktyczna retencja długoterminowa
może być nieco wyższa niż 3,0%.

---

*Źródła liczb: `sql/02`, `sql/03`, `sql/04`, `notebooks/03_kpi_analysis.ipynb`,
`notebooks/04_visualizations.ipynb`. Wszystkie wartości liczone w zakresie zamówień
`delivered` i zweryfikowane na `data/olist.db` (03.07.2026).*
