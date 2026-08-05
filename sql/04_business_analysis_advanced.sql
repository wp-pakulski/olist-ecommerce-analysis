-- ============================================================
-- Analiza biznesowa zaawansowana — segmentacja, progi SLA, problem sellers
-- Zakres: wszystkie metryki liczone na zamówieniach delivered
-- (jedyny celowy wyjątek: analiza anulacji, zapytanie 4).
-- ============================================================

-- 1. Segmentacja sprzedawców ABC (Pareto)
-- PYTANIE: Czy reguła Pareto (80/20) potwierdza się wśród sprzedawców?
-- WNIOSEK: Top 20% sprzedawców = 82.3% przychodu (z 2 970 sprzedawców
--          z dostarczonymi zamówieniami) — Pareto potwierdzone!
--          Rekomendacja: dedykowany opiekun dla segmentu A, automatyzacja obsługi dla C.

with seller_revenue as (
	select
		s.seller_id as sprzedawca
		,sum(oi.price) as przychod
		,ntile(5) OVER(order by sum(oi.price) desc) as segment
	from order_items oi
	join sellers s on s.seller_id = oi.seller_id
	join orders o on o.order_id = oi.order_id
	where o.order_status = 'delivered'
	group by s.seller_id
)
select 
	segment
	,count(*) as liczba_sprzedawcow
	,round(sum(przychod), 2) as przychod_grupy
	,round(sum(przychod) * 100.0 / (select sum(przychod) from seller_revenue), 1) as przychod_pct
from seller_revenue
group by segment
order by segment;

-- 2. Rating per przedział czasu dostawy
-- PYTANIE: Jak dokładnie czas dostawy wpływa na ocenę? Gdzie jest próg bólu?
-- WNIOSEK: ≤7 dni: 4.41★ | 8-14: 4.29★ | 15-21: 4.10★ | 22-30: 3.49★ | >30: 2.18★.
--          Rating spada monotonicznie, ale próg krytyczny jest po 21 dniach:
--          do 21 dni ocena trzyma się >= 4.1, w przedziale 22-30 załamuje się do 3.49.
--          Rekomendacja: twarde SLA max 21 dni (poniżej progu bólu),
--          cel operacyjny 14 dni (utrzymanie ratingu ~4.3).
SELECT
	CASE
		when delivery_days <= 7 then '1. do 7 dni'
		when delivery_days <= 14 then '2. 8-14 dni'
		when delivery_days <= 21 then '3. 15-21 dni'
		when delivery_days <= 30 then '4. 22-30 dni'
		ELSE  '5. ponad 30 dni'
	END as delivery_group
	,count(*) as liczba_zamowien
	,round(avg(r.review_score), 2) as avg_rating
from orders o
join reviews r on o.order_id = r.order_id
where o.order_status = 'delivered'
	and delivery_days is not NULL
group by delivery_group
order by delivery_group;

-- 3. RFM-like analiza klientów
-- PYTANIE: Jak wyglądają segmenty klientów wg wartości (Recency, Frequency, Monetary)?
-- WNIOSEK: Frequency ~1.0 we WSZYSTKICH segmentach — nawet najlepsi klienci kupują
--          praktycznie raz. Potwierdza problem retencji z zapytania 02/6.
--          Segmentacja RFM ma ograniczoną wartość przy tak niskiej powtarzalności.
  
with rfm as(
	select
		c.customer_unique_id
		,max(o.order_purchase_timestamp) as recency
		,count(distinct o.order_id) as frequency
		,round(sum(oi.price), 2) as monetary
	from customers c
	join orders o on o.customer_id = c.customer_id
	join order_items oi on o.order_id = oi.order_id
	where o.order_status = 'delivered'
	group by c.customer_unique_id
),
segmented as(
	select
	customer_unique_id
	,frequency
	,monetary
	,ntile(4) over(order by monetary desc) as segment
	from rfm
)
SELECT 
	segment
	,count(*) as liczba_klientow
	,round(avg(frequency), 2) as avg_frequency
	,round(avg(monetary), 2) as avg_monetary
from segmented
group by segment 
order by segment;

-- 4. Anulacje per kategoria
-- PYTANIE: Które kategorie mają najwyższy % anulacji? Czy to problem produktu czy sprzedawcy?
-- NOTA: celowo BEZ filtra delivered — % anulacji z definicji wymaga wszystkich statusów.
-- WNIOSEK: DVD/Blu-ray 3.13%, musical_instruments 1.62%. Ogólny % anulacji niski,
--          ale warto monitorować kategorie powyżej 2% — mogą wskazywać na problemy z opisem
--          produktu lub niezgodność oczekiwań.

select
	t.product_category_name_english as category
	,count(*) as total_orders
	,sum(case when o.order_status = 'canceled' then 1 else 0 end) as canceled
	,round(sum(case when o.order_status = 'canceled' then 1 else 0 end) * 100.0 / count(*), 2) as cancel_pct
from orders o 
join order_items oi on o.order_id = oi.order_id 
join products p on oi.product_id = p.product_id 
join translations t on p.product_category_name = t.product_category_name 
group by category 
having canceled > 0
order by cancel_pct desc
limit 15;


-- 5. Sprzedawcy z wysokim przychodem ale problemami
-- PYTANIE: Którzy kluczowi sprzedawcy wymagają interwencji (dobry przychód, zła jakość)?
-- NOTA METODOLOGICZNA: rating i % spóźnień liczone na poziomie zamówienia
--          (DISTINCT seller x order), nie pozycji — inaczej zamówienia wielopozycyjne
--          zawyżałyby licznik (jedna recenzja/spóźnienie liczone kilka razy).
-- WNIOSEK: 35 sprzedawców z revenue >10k BRL i ratingiem <3.5 lub >15% spóźnień.
--          Najgorszy przypadek: seller b1b394 — 21.5k BRL, rating 1.93, 64% spóźnień.
--          Rekomendacja: lista do action planu dla zespołu operations.

with seller_orders as (
	select distinct
		oi.seller_id as sprzedawca
		,o.order_id
		,r.review_score
		,(o.order_delivered_customer_date > o.order_estimated_delivery_date) as is_late
	from order_items oi
	join orders o on o.order_id = oi.order_id
	join reviews r on r.order_id = o.order_id
	where o.order_status = 'delivered'
),
seller_revenue as (
	select oi.seller_id as sprzedawca, sum(oi.price) as revenue
	from order_items oi
	join orders o on o.order_id = oi.order_id
	where o.order_status = 'delivered'
	group by oi.seller_id
),
seller_stats as (
	select
		so.sprzedawca
		,sr.revenue
		,round(avg(so.review_score), 2) as avg_rating
		,count(*) as liczba_zamowien
		,round(avg(so.is_late) * 100.0, 1) as late_pct
	from seller_orders so
	join seller_revenue sr on sr.sprzedawca = so.sprzedawca
	group by so.sprzedawca
)
select * from seller_stats
where revenue > 10000
	and (avg_rating < 3.5 OR late_pct > 15)
order by revenue desc;

-- 6. Wzorce zakupowe — dzień tygodnia x godzina (dane do heatmapy Python)
-- PYTANIE: Kiedy klienci najczęściej składają zamówienia?
-- WNIOSEK: Wyniki do wizualizacji w Pythonie (heatmapa matplotlib/seaborn).
--          96k zamówień = statystycznie wiarygodna próba dla wzorców tygodniowych.
--          Uwaga: dane obejmują ~2 lata — sezonowość roczną traktować ostrożnie.

SELECT 
	strftime('%w', o.order_purchase_timestamp) as day_of_week
	,strftime('%H', o.order_purchase_timestamp) as hour
	,count(*) as orders_count
from orders o
where o.order_status = 'delivered'
group by day_of_week, hour
order by day_of_week, hour