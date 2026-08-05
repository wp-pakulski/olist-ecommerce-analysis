-- ============================================================
-- Analiza biznesowa — trendy przychodu, płatności, logistyka, retencja
-- Zakres: metryki liczone na zamówieniach delivered.
-- ============================================================

-- 1. Przychody miesięczne
-- PYTANIE: Jak wygląda trend przychodów? Czy platforma rośnie?
-- WNIOSEK: Wzrost od Q4 2016 do szczytu XI 2017 (Black Friday), potem stabilizacja w 2018.
--          Anomalia: brak danych za XI 2016 (0 zamówień przy 324 w październiku) — luka w danych.

select strftime('%Y-%m', o.order_purchase_timestamp) as miesiac, sum(oi.price)
from orders o
inner join order_items oi
	on o.order_id = oi.order_id
where o.order_status = 'delivered'
group by miesiac
order by miesiac;

-- Weryfikacja anomalii Q4 2016:
 select strftime('%Y-%m', order_purchase_timestamp) as miesiac, COUNT(*) as liczba
 from orders
 where strftime('%Y-%m', order_purchase_timestamp) in ('2016-09', '2016-10', '2016-11', '2016-12')
 group by miesiac
 order by miesiac;

-- 2. Top 10 kategorii po przychodzie
-- PYTANIE: Które kategorie generują największy przychód?
-- WNIOSEK: health_beauty #1 (1.23M BRL), bed_bath_table #3. Uwaga: top wg sztuk ≠ top wg przychodu
--          (bed_bath_table #1 wg ilości, ale #3 wg wartości — niższa średnia cena).

select t.product_category_name_english as kategoria, round(sum(oi.price), 2) as przychod
from products p 
inner join order_items oi
 on p.product_id = oi.product_id
inner join orders o
	on o.order_id = oi.order_id
inner join translations t 
	on t.product_category_name = p.product_category_name 
where o.order_status = 'delivered'
group by kategoria 
order by przychod desc
limit 10;

-- 3. Metody płatności z udziałem %
-- PYTANIE: Jak klienci płacą? Która metoda dominuje?
-- WNIOSEK: credit_card 73%, boleto 19%. Karta kredytowa zdecydowanie dominuje.
--          Boleto (przelew bankowy) to specyfika Brazylii — analogia do BLIK w PL.

select p.payment_type, count(*) as liczba, round(count(*) * 100.0 / (select count(*) from payments), 2) as udzial_pct
from payments p
group by p.payment_type
order by liczba desc;

-- 4. Średni czas dostawy per stan
-- PYTANIE: Gdzie są wąskie gardła logistyczne?
-- WNIOSEK: SP 8.3 dni vs RR 29 dni. Czas dostawy zależy od odległości od centrum
--          logistycznego w São Paulo. Rekomendacja: hub logistyczny w regionie Norte.

select c.customer_state as stan, round(avg(o.delivery_days), 1) as sredni_czas_dostawy
from customers c
inner join orders o
	on o.customer_id = c.customer_id
where o.order_status = 'delivered'
group by stan
order by sredni_czas_dostawy asc;

-- 5. Rating vs czas dostawy
-- PYTANIE: Czy czas dostawy wpływa na satysfakcję klientów?
-- WNIOSEK: Rating 5★ = 10.2 dni, rating 1★ = 20.8 dni — silna korelacja!
--          Każdy dodatkowy dzień dostawy obniża satysfakcję. Zamówienia z ratingiem 1
--          czekały 2x dłużej niż te z ratingiem 5. Kluczowy insight dla operacji.

select avg(r.review_score) as rating , avg(o.delivery_days) as sredni_czas_dostawy, count(*) as liczba_opinii
from reviews r
inner join orders o
	on r.order_id = o.order_id
where o.order_status = 'delivered'
group by r.review_score
order by r.review_score;

-- 6. Retencja klientów
-- PYTANIE: Ilu klientów wraca na platformę? Czy budujemy lojalność?
-- WNIOSEK: Tylko 3% klientów wraca (2801 z 93k). Platforma działa jak "one-shot" —
--          klienci kupują raz i nie wracają. To największe wyzwanie biznesowe Olist.
--          Rekomendacja: program lojalnościowy, email marketing po 30/60/90 dniach.

select
count(distinct customer_unique_id) as wszyscy_klienci
,count(distinct case when zamowienia > 1 then customer_unique_id end) as powracajacy
,round(count(distinct case when zamowienia > 1 then customer_unique_id end) * 100.0 / count(distinct customer_unique_id), 2) as pct_powracajacych
from (
select c.customer_unique_id, count(o.order_id) as zamowienia
from customers c
join orders o on c.customer_id = o.customer_id
where o.order_status = 'delivered'
group by c.customer_unique_id
);

-- Lista powracających klientów (weryfikacja):
  SELECT customer_unique_id, COUNT(order_id) as zamowienia
  FROM customers c
  JOIN orders o ON c.customer_id = o.customer_id
  WHERE o.order_status = 'delivered'
  GROUP BY customer_unique_id
  ORDER BY zamowienia DESC
  LIMIT 2803;