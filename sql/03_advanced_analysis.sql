-- 1. Top 3 sprzedawców per kategoria
-- PYTANIE: Kto dominuje w poszczególnych kategoriach? Czy rynek jest skoncentrowany?
--
-- WNIOSEK: Koncentracja silnie zależy od kategorii:
--          * watches_gifts — rynek zrównoważony: top 3 sprzedawców z porównywalnym
--            przychodem (160-199 tys. BRL każdy), brak dominatora — kategoria
--            odporna na odejście pojedynczego sprzedawcy.
--          * office_furniture — rynek skoncentrowany: lider z przychodem 171 606 BRL
--            i 64% udziału w kategorii.
--
-- INSIGHT (office_furniture): niski rating kategorii (3.49) to w dużej mierze problem
--          dominatora, który wolumenem wyznacza poziom całej kategorii.
--          Weryfikacja (delivered, rating na poziomie zamówienia):
--          * dominator (64% przychodu): 970 zamówień, rating 3.49, 10.0% spóźnień
--          * sprzedawca #2:             122 zamówienia, rating 4.25,  7.4% spóźnień
--          * sprzedawca #3:              72 zamówienia, rating 3.40,  5.6% spóźnień
--          Sprzedawca #2 dowodzi, że w tej kategorii da się utrzymać rating >4.2 —
--          problem nie jest strukturalny (typ produktu), tylko operacyjny.
--
-- REKOMENDACJA: dominatora nie można usunąć (64% przychodu kategorii), dlatego:
--          1) program naprawczy dla lidera z mierzalnym celem: rating > 4.0
--             i spóźnienia < 8% w ciągu 2 kwartałów (benchmark: sprzedawca #2),
--          2) równolegle dywersyfikacja ryzyka — pozyskanie 1-2 nowych
--             sprzedawców do kategorii.
--
-- NOTA TECHNICZNA: JOIN ze słownikiem tłumaczeń pokrywa 98.6% pozycji
--          (odpada 'unknown' + 2 kategorie bez tłumaczenia).

with seller_category_revenue as(
	select
		oi.seller_id
		,t.product_category_name_english as category
		,sum(oi.price) as revenue
	from order_items oi
	join orders o on o.order_id = oi.order_id
	join products p on oi.product_id = p.product_id
	join translations t on p.product_category_name = t.product_category_name
	where o.order_status = 'delivered'
	group by oi.seller_id, t.product_category_name_english
),
ranked as (
	SELECT 
		seller_id
		,category
		,ROUND(revenue, 2) as revenue
		,rank() over(partition by category order by revenue desc) as rank
	from seller_category_revenue 
)
select * from ranked 
where rank <= 3
order by category, rank;

SELECT
	ROUND(100.0 * SUM(CASE WHEN t.product_category_name IS NOT NULL THEN 1 END) / COUNT(*), 1) AS pct_matched
FROM order_items oi
  JOIN products p ON oi.product_id = p.product_id
  LEFT JOIN translations t ON p.product_category_name = t.product_category_name;

-- 2. Running total + MoM% change
-- PYTANIE: Jak rośnie skumulowany przychód i jaka jest dynamika miesiąc do miesiąca?
-- WNIOSEK: Black Friday 2017 — wyraźny skok MoM. LAG() pokazuje, że listopad 2017
--          miał największy wzrost procentowy. Stabilizacja w 2018.

WITH monthly AS (                                                                                                                                                                                          
     SELECT                                                                                                                                                                                                 
          strftime('%Y-%m', o.order_purchase_timestamp) AS month,                                                                                                                                            
          SUM(oi.price) AS monthly_revenue
     FROM order_items oi                                                                                                                                                                                    
     JOIN orders o ON oi.order_id = o.order_id                                                                                                                                                              
     WHERE o.order_status = 'delivered'                                                                                                                                                                     
     GROUP BY strftime('%Y-%m', o.order_purchase_timestamp)                                                                                                                                                 
)
SELECT                                                                                                                                                                                                     
      month,                          
      round(monthly_revenue, 2) as monthly_revenue,                        
      SUM(monthly_revenue) OVER(ORDER BY month) AS cumulative_revenue,
      ROUND((monthly_revenue - LAG(monthly_revenue) OVER(ORDER BY month))                                                                                                                                    
      	/ LAG(monthly_revenue) OVER(ORDER BY month) * 100, 1) AS mom_change_pct
FROM monthly
ORDER BY month;

-- 3. Kategorie z przychodem powyżej średniej
-- PYTANIE: Ile kategorii jest powyżej średniej? Jak bardzo rynek jest skoncentrowany?
-- WNIOSEK: 19 z 71 kategorii powyżej średniej (183 740 BRL) — koncentracja przychodu w ~27% kategorii.
with
category_revenue as(
	select
	t.product_category_name_english as kategoria
	, sum(oi.price) as revenue
	from order_items oi
	join orders o on o.order_id = oi.order_id
	join products p on oi.product_id = p.product_id
	join translations t on p.product_category_name = t.product_category_name
	where o.order_status = 'delivered'
	group BY  kategoria
),
avg_revenue as (
select avg(revenue) as avg_revenue from category_revenue
)
select 
	kategoria
	,revenue
	,round(avg_revenue, 2) as avg_revenue 
from category_revenue, avg_revenue 
where revenue > avg_revenue 
order by revenue desc;

-- 4. Analiza kohortowa — retencja klientów
-- PYTANIE: Które kohorty (miesiąc pierwszego zakupu) mają najlepszą retencję?
-- WNIOSEK: Retencja 3-4% w najlepszych miesiącach. Black Friday 2017 = 1.9% retencji —
--          potwierdzenie, że promocje przyciągają jednorazowych klientów, nie lojalnych.

with first_purchase as (
	select
		customer_unique_id
		,min(strftime('%Y-%m', o.order_purchase_timestamp)) as cohort_month
	from customers c
	join orders o on o.customer_id = c.customer_id
	where o.order_status = 'delivered'
	group by c.customer_unique_id
),
all_purchase as (
	select c.customer_unique_id
	,strftime('%Y-%m', o.order_purchase_timestamp) as purchase_month
from customers c
join orders o on o.customer_id = c.customer_id
where o.order_status = 'delivered'
)
select 
	fp.cohort_month
	,count(distinct fp.customer_unique_id) as cohort_size
	,count(distinct case
		when ap.purchase_month > fp.cohort_month
		then ap.customer_unique_id 
	end) as returned
	,round(count(distinct case
		when ap.purchase_month > fp.cohort_month
		then ap.customer_unique_id
	end) * 100.0 / count(distinct fp.customer_unique_id), 1) as retention_pct
from first_purchase fp
join all_purchase ap on fp.customer_unique_id = ap.customer_unique_id
group by fp.cohort_month
order by fp.cohort_month;