
--Eksploracja danych (Olist dataset)


-- 1. Statusy zamówień
-- PYTANIE: Jaki jest rozkład statusów zamówień? Ile zamówień jest dostarczonych vs problematycznych?
-- WNIOSEK: 98.1% zamówień to delivered lub shipped — platforma działa stabilnie operacyjnie.
--          Canceled stanowi marginalny ułamek.
SELECT order_status, COUNT(order_id) AS liczba_zamowien
FROM orders
GROUP BY order_status
ORDER BY liczba_zamowien DESC;


-- 2-3. Jaki procent zamówień został dostarczony lub jest w drodze?
-- WNIOSEK: 98.1% — bardzo wysoki wskaźnik realizacji. Podzapytanie w WHERE liczy % względem całości.
SELECT COUNT(order_id) AS liczba_zamowien
FROM orders
WHERE order_status IN ('delivered', 'shipped');

SELECT ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM orders), 1) AS procent
FROM orders
WHERE order_status IN ('delivered', 'shipped');


-- 4. Statystyki cen produktów
-- PYTANIE: Jaki jest zakres i średnia cena produktów na platformie?
-- WNIOSEK: AVG 120 BRL, MIN 0.85, MAX 6735 — duży rozrzut cenowy.
SELECT
    ROUND(AVG(price), 2) AS srednia_cena,
    MIN(price)           AS min_cena,
    MAX(price)           AS max_cena
FROM order_items;


-- 5. Top 10 kategorii wg liczby sprzedanych sztuk
-- PYTANIE: Które kategorie produktów sprzedają się najczęściej?
-- WNIOSEK: bed_bath_table #1 z 11115 szt., dalej sports_leisure i furniture_decor.
--          Kategorie wyposażenia domu dominują na platformie.
SELECT
    t.product_category_name_english AS kategoria_produktu,
    COUNT(*)                        AS liczba_sprzedanych
FROM products pro
    INNER JOIN order_items oi ON oi.product_id = pro.product_id
    INNER JOIN translations t  ON t.product_category_name = pro.product_category_name
GROUP BY pro.product_category_name
ORDER BY liczba_sprzedanych DESC
LIMIT 10;


-- 6. Średni czas dostawy per stan
-- PYTANIE: Jak czas dostawy różni się geograficznie? Gdzie są wąskie gardła logistyczne?
-- WNIOSEK: SP ~9 dni vs RR ~29 dni — 3x różnica! Stany północne mają 
--  		dłuższe dostawy. Odległość od centrów logistycznych w São Paulo jest kluczowym czynnikiem.
SELECT
    c.customer_state,
    ROUND(AVG(JULIANDAY(order_delivered_customer_date) - JULIANDAY(order_purchase_timestamp))) AS avg_delivery_dni
FROM orders o
    INNER JOIN customers c ON c.customer_id = o.customer_id
WHERE o.order_delivered_customer_date IS NOT NULL
GROUP BY c.customer_state
ORDER BY avg_delivery_dni;


-- 7. Średni rating per kategoria produktu (z liczbą ocen)
-- PYTANIE: Które kategorie mają najniższą satysfakcję klientów?
-- WNIOSEK: office_furniture 3.49 przy 1687 zamówieniach — systemowy problem (duża próba).
--          security_and_services 2.5 ale tylko 2 zamówienia — statystycznie niewiarygodne.
--          Ważne: zawsze patrzeć na liczbę ocen, nie tylko średnią!
SELECT
    t.product_category_name_english AS kategoria,
    ROUND(AVG(r.review_score), 2)   AS srednia_ocena,
    COUNT(*)                        AS liczba_ocen
FROM translations t
    INNER JOIN products p    ON p.product_category_name = t.product_category_name
    INNER JOIN order_items oi ON oi.product_id = p.product_id
    INNER JOIN orders o       ON o.order_id = oi.order_id
    INNER JOIN reviews r      ON r.order_id = o.order_id
GROUP BY kategoria
ORDER BY srednia_ocena DESC;
