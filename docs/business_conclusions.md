# Business Conclusions — Olist E-commerce Analysis

> Analiza danych brazylijskiego marketplace Olist (~99 tys. zamówień, 2016–2018).
> Cel: zidentyfikować dźwignie wzrostu i ryzyka operacyjne, oraz przełożyć je na
> konkretne, mierzalne rekomendacje biznesowe.

---

## 1. Kontekst i cel

Olist to brazylijski marketplace, który łączy małych i średnich sprzedawców z klientami
głównych platform e-commerce, obsługując logistykę i płatności jako warstwa pośrednia.
Analiza obejmuje 9 powiązanych tabel (zamówienia, pozycje, płatności, recenzje, sprzedawcy,
klienci, produkty, geolokalizacja), ~99 tys. zamówień z lat 2016–2018 dla rynku brazylijskiego.

**Definicja zakresu:** wszystkie metryki w tym dokumencie liczone są na zamówieniach
o statusie `delivered` (96 478 z 99 441, tj. 97% wolumenu) — spójnie z notebookami,
zapytaniami SQL i dashboardem Power BI. Jedyny wyjątek: analiza anulacji (`sql/04`),
która z definicji wymaga wszystkich statusów. Rating sprzedawcy liczony jest na poziomie
zamówienia (1 recenzja = 1 głos), nie pozycji koszyka.

Pytanie biznesowe: **Co napędza przychód marketplace i co realnie zagraża jego skalowaniu —
po stronie retencji klientów i jakości sprzedawców?** Celem nie jest opis danych, lecz wskazanie
dźwigni, na które platforma może wpłynąć operacyjnie.

---

## 2. Kluczowe wnioski (Executive Summary)

Najważniejsze liczby z analizy:

- **Przychód całkowity:** 13 221 498 BRL | **Zamówienia:** 96 478 | **AOV:** 137,04 BRL (mediana 86,57 BRL)
- **Pareto sprzedawców:** top 20% sprzedawców generuje **82,3%** przychodu (z 2 970 sprzedawców z dostarczonymi zamówieniami)
- **Retencja:** tylko **3,0%** klientów wraca (2 801 z 93 358 unikalnych)
- **Dostawa ↔ satysfakcja:** dostawa ≤7 dni = **4,41★**, dostawa >30 dni = **2,18★**
- **Terminowość:** **91,9%** zamówień dostarczonych na czas (śr. czas dostawy 12,1 dnia, mediana 10)

**Wniosek syntetyczny:** Olist to sprawna maszyna do *pozyskiwania* i *sprzedaży* — wysoka
terminowość, zdrowe AOV i jasny lider przychodu (top 20% sprzedawców = 82,3% obrotu). Ale model
stoi na dwóch słabych filarach: **retencja praktycznie nie istnieje (3,0%)**, więc każdy złoty
przychodu wymaga ciągłego dokupywania nowych klientów, a **jakość obsługi jest zakładnikiem
dwóch zmiennych** — czasu dostawy i długiego ogona słabych sprzedawców. Wzrost jest realny, ale
dziś *kupowany*, a nie *budowany*.

---

## 3. Analiza szczegółowa

### 3a. Sprzedaż i sezonowość
- Szczyt sprzedaży: **Black Friday, listopad 2017** (wyraźny skok MoM — `sql/03`)
- Top kategorie wg przychodu całkowitego:
  1. health_beauty — 1 233 132 BRL (479 sprzedawców)
  2. watches_gifts — 1 166 177 BRL (95 sprzedawców)
  3. bed_bath_table — 1 023 435 BRL (189 sprzedawców)

**Wniosek:** Dwie czołowe kategorie mają zbliżony przychód, ale **przeciwną strukturę rynku**.
`health_beauty` jest rozdrobniona (479 sprzedawców, śr. ~2 574 BRL/sprzedawca) — to rynek
konkurencyjny, odporny na utratę pojedynczego gracza, ale trudny do zarządzania jakościowo.
`watches_gifts` jest skoncentrowana (95 sprzedawców, śr. ~12 275 BRL, ~4,8× więcej) — wysoka
efektywność, ale ryzyko zależności: odejście kilku kluczowych sprzedawców uderza wprost w przychód.
Implikacja: te dwie kategorie wymagają **różnych strategii retencji sprzedawcy** — w pierwszej
liczy się standaryzacja jakości, w drugiej account management kluczowych partnerów.

### 3b. Sprzedawcy — koncentracja i jakość
- **Pareto:** top 20% sprzedawców = 82,3% przychodu
- **Problem sellers** (rating < 3,5): **343 sprzedawców (~11,6% z 2 965 ocenionych)** —
  rating liczony na poziomie zamówienia, tylko zamówienia dostarczone
- Przykład office_furniture: jeden dominator (64% przychodu kategorii, rating 3,49 przy
  970 zamówieniach) wolumenem wyznacza ocenę całej kategorii, mimo że sprzedawca #2
  (122 zamówienia) utrzymuje rating 4,25

**Wniosek:** Mamy klasyczny konflikt **koncentracji przychodu vs rozproszenia ryzyka**. Przychód
jest skupiony w wąskiej grupie (Pareto), ale problem jakościowy siedzi w długim ogonie — ponad
co dziesiąty sprzedawca ma rating < 3,5. Dla platformy to podwójne zagrożenie: (1) słaba jakość
ogona psuje reputację całego marketplace (klient ocenia „Olist", nie konkretnego sprzedawcę),
a (2) pojedynczy dominator może zaniżyć ocenę całej kategorii (jak office_furniture) — przy czym
przykład sprzedawcy #2 z tej samej kategorii (rating 4,25) dowodzi, że problem jest operacyjny,
nie produktowy. To znaczy, że jakość trzeba kontrolować **na dwóch poziomach**: bramka wejścia
dla ogona i interwencja celowana w kluczowych, ale słabych sprzedawców.

### 3c. Klienci i retencja
- **93 358** unikalnych klientów, repeat rate **3,0%**, częstotliwość ~1,03 zamówienia/klient

**Wniosek:** To najpoważniejszy strukturalny problem biznesu. Repeat rate 3,0% oznacza, że
praktycznie każdy klient to klient **jednorazowy** — średnio 1,03 zamówienia na osobę. Ekonomicznie:
koszt pozyskania klienta (CAC) jest ponoszony raz, ale **nie ma go z czego zamortyzować**, bo
wartość życiowa klienta (LTV) niemal równa się jednemu AOV (~137 BRL). W zdrowym marketplace LTV
powinno być wielokrotnością CAC — tutaj relacja LTV/CAC jest niebezpiecznie blisko granicy
opłacalności. Konsekwencja: wzrost przychodu jest **całkowicie zależny od ciągłych wydatków
marketingowych**; gdy budżet akwizycji spadnie, przychód spada razem z nim. Retencja nie jest tu
„miłym dodatkiem" — to warunek rentowności w dłuższym horyzoncie.

### 3d. Dostawa i logistyka
- Śr. czas dostawy: **12,1 dnia** (mediana 10) | On-Time: **91,9%**
- Geografia: **SP 8,3 dnia** (najszybciej) vs **AP 26,7 / AM 26,0 dnia** (~3× różnica)
- Rating per czas dostawy: ≤7 dni → 4,41★ | 8–14 → 4,29★ | 15–21 → 4,10★ | 22–30 → 3,49★ | >30 → 2,18★

**Wniosek:** Czas dostawy to **najsilniejszy pojedynczy driver satysfakcji** w danych — różnica
między dostawą ≤7 dni a >30 dni to spadek z 4,41★ do 2,18★, czyli ponad 2,2 gwiazdki. Co istotne,
spadek nie jest liniowy: do 21 dni rating trzyma się ≥4,1, a **załamanie następuje w przedziale
22–30 dni (3,49★)** — próg bólu klienta leży przy ~3 tygodniach, nie przy 2. A ponieważ
satysfakcja przekłada się na reputację marketplace i (pośrednio) na retencję, logistyka łączy oba
główne problemy biznesu. Geografia pokazuje, gdzie leży dźwignia: SP (8,3 dnia) vs AP/AM (~26–27
dni, ~3× wolniej) — to nie jest problem „całej platformy", lecz **kilku stanów Północy**. Oznacza
to, że poprawa nie wymaga rewolucji w całej sieci, a celowanej interwencji logistycznej w wąskim,
zidentyfikowanym regionie — to dużo tańsze i szybsze do wdrożenia.

### 3e. Wzorce czasowe (heatmapa)
- Peak: dni robocze, pasmo 10–17; najlepsza godzina zagregowana: **16:00**
  (najwyższa pojedyncza komórka: wtorek 14:00)
- Niedziela: najniższa aktywność dzienna, ale najwyższy udział wieczoru —
  **38% zamówień pada w godz. 18–22** (vs 26–31% w pozostałe dni)

**Wniosek:** Aktywność zakupowa koncentruje się w dni robocze w paśmie 10–17 (szczyt 16:00) —
to naturalne okno na **kampanie konwersyjne i remarketing**, gdy intencja zakupowa jest najwyższa.
Niedziela ma najniższą aktywność dzienną, ale najwyższy udział wieczoru (38% zamówień w godz.
18–22) — to okno raczej pod **budowanie zaangażowania i kampanie świadomościowe** (przeglądanie,
newsletter, push „zaplanuj zakup"), nie pod twardy performance. Praktycznie: harmonogram
push/e-mail powinien być różnicowany dniem tygodnia, a nie jednolity.

---

## 4. Rekomendacje biznesowe

> Zasada: każda rekomendacja MUSI wynikać z konkretnej liczby powyżej.

1. **SLA dostawy: twardy limit 21 dni, cel operacyjny 14 dni** — bo rating trzyma się ≥4,1
   do 21 dni, po czym załamuje się do 3,49★ (22–30 dni) i 2,18★ (>30 dni). Priorytet dla stanów
   Północy (AP 26,7 / AM 26,0 dnia, ~3× wolniej niż SP). Cel mierzalny: skrócić medianę dostawy
   w AP/AM/AL poniżej 18 dni w 2 kwartały (np. przez hub regionalny lub renegocjację stawek
   kuriera dla regionu), co według zależności rating↔czas powinno podnieść tamtejszy rating
   o ~0,6–1 gwiazdkę.

2. **Quality gate / onboarding dla małych sprzedawców** — bo **343 sprzedawców (~11,6%)** ma
   rating < 3,5, głównie w długim ogonie. Wprowadzić próg wejścia (np. okres próbny z monitoringiem
   pierwszych 20 zamówień) oraz automatyczny alert, gdy rating sprzedawcy spadnie < 3,5. Cel: obniżyć
   udział problem sellers z 11,6% do < 8% w rok, bez zatrzymywania napływu nowych sprzedawców.

3. **Program lojalnościowy / retencyjny** — bo retencja 3,0% oznacza, że biznes płaci CAC za
   praktycznie jednorazowych klientów, a LTV ≈ jednemu AOV. Nawet niewielka poprawa repeat rate
   (np. z 3,0% do 6%) podwaja zamortyzowaną wartość klienta. Konkretnie: trigger post-purchase
   (kupon na 2. zakup w kategorii komplementarnej w 30 dni od dostawy), warunkowany pozytywną
   recenzją — sprzęga retencję z jakością.

4. **Program naprawczy dla dominujących, ale słabych sprzedawców** — celowana interwencja dla
   przypadków typu office_furniture (jeden gracz 64% przychodu kategorii, rating 3,49) oraz listy
   35 sprzedawców z `sql/04` (revenue >10k BRL i rating < 3,5 lub >15% spóźnień, najgorszy: 21,5k BRL
   / rating 1,93 / 64% spóźnień). Cel mierzalny: rating > 4,0 i spóźnienia < 8% w 2 kwartały, pod
   rygorem obniżenia widoczności w wynikach wyszukiwania platformy.

---

## 5. Ograniczenia analizy

- Dane historyczne 2016–2018, rynek brazylijski — wnioski mogą nie przenosić się 1:1
- ~1,4% pozycji bez sklasyfikowanej kategorii ('unknown' + 2 kategorie bez tłumaczenia)
- Metryka `# Seller Orders` przeszacowana przy zamówieniach multi-seller (jedno
  zamówienie liczone u każdego sprzedawcy)
- Rating sprzedawcy liczony jako średnia recenzji per zamówienie — przy zamówieniach
  multi-seller jedna recenzja jest przypisywana do każdego sprzedawcy w koszyku, co może
  zaszumiać ocenę pojedynczego sprzedawcy (recenzja dotyczy całego doświadczenia, nie jednej pozycji)
- Brak danych o kosztach (CAC, marża, prowizja Olist), więc wnioski o rentowności retencji
  (LTV/CAC) są kierunkowe, nie policzone — to hipoteza do potwierdzenia danymi finansowymi
- Repeat rate liczony po `customer_unique_id` na zamówieniach dostarczonych; klienci, którzy
  wrócili po oknie danych (po 2018) są niewidoczni — faktyczna retencja długoterminowa może
  być nieco wyższa

---

*Źródła liczb: `sql/02`, `sql/03`, `sql/04`, `notebooks/03_kpi_analysis.ipynb`,
`notebooks/04_visualizations.ipynb`. Wszystkie wartości liczone w zakresie zamówień
`delivered` i zweryfikowane na `data/olist.db` (03.07.2026).*
