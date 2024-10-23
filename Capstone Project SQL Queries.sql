--ÜRÜN-KATEGORİ ANALİZİ
--Kategori bazlı satış performansı, net gelir, kargo maliyeti ve toplam indirim analizi

WITH product_category AS(
	SELECT
	    c.category_name,
		description,
	    SUM(od.quantity) AS total_quantity_sold,
		ROUND(SUM(od.quantity * od.unit_price * (1 - od.discount))) AS total_net_revenue,
	    ROUND(SUM(o.freight)) AS total_shipping_cost,
	    ROUND(SUM(od.quantity * od.unit_price * od.discount)) AS total_discount_applied
	FROM orders o
	JOIN 
	    order_details od ON o.order_id = od.order_id
	JOIN 
	    products p ON od.product_id = p.product_id
	JOIN 
	    categories c ON p.category_id = c.category_id
	GROUP BY
		c.category_id, c.category_name
	)
	SELECT
		category_name,
		description,
	    total_quantity_sold,
		total_net_revenue,
	    total_shipping_cost,
	    total_discount_applied,
		total_net_revenue - total_shipping_cost as net_profit
	FROM product_category
	ORDER BY net_profit DESC;

--TEDARİKÇİ ANALİZİ
--Hangi tedarikçiden gelen ürünler daha çok satış getirmiş?
--NET_PROFITE GÖRE TEDARİKÇİ SIRALAMASI

SELECT 
	s.company_name as supplier_name,
	s.country,
	COUNT(o.order_id) AS total_orders,
	ROUND(SUM(od.quantity * od.unit_price)) AS total_sales_amount,
	ROUND(SUM(od.quantity * od.unit_price * (1 - od.discount))) AS total_net_revenue
FROM suppliers s
JOIN 
	products p ON s.supplier_id = p.supplier_id
JOIN 
	order_details od ON p.product_id = od.product_id
JOIN
	orders o ON od.order_id = o.order_id
GROUP BY 
	s.company_name, s.country
ORDER BY 
	total_orders DESC;

--------------------------------------------------------------------
--AVG_UNIT_PRICE FOR ALL PRODUCTS

SELECT
	company_name,
    country,
	product_name,
	ROUND(AVG(od.unit_price)) avg_unit_price
FROM suppliers s
JOIN 
	products p ON s.supplier_id = p.supplier_id
JOIN 
	order_details od ON p.product_id = od.product_id
JOIN
	orders o ON od.order_id = o.order_id
GROUP BY 1,2,3
ORDER BY 2;

---------------------------------------------------------------
--ÇALIŞAN ANALİZİ
--İnsan kaynakları tarafından her çalışanın kategori bazında toplam satış performansını değerlendirmemiz istendi. 
--Verilen indirimleri göz önünde bulundurularak, çalışan bazında net satış miktarını hesaplayıp en yüksek net satış gerçekleştiren çalışanları tespit edebiliriz.

SELECT
	e.employee_id,
    CONCAT(e.first_name, ' ', e.last_name) AS employee_name,
    COUNT(o.order_id) AS total_orders,
    ROUND(SUM(od.quantity * od.unit_price * (1 - od.discount))) AS total_net_sales_amount
FROM employees e
JOIN 
	orders o ON e.employee_id = o.employee_id
JOIN 
	order_details od ON o.order_id = od.order_id
GROUP BY 
	e.employee_id, employee_name
ORDER BY 4 DESC;


SELECT
	category_name,
    CONCAT(e.first_name, ' ', e.last_name) AS employee_name,
    COUNT(o.order_id) AS total_orders,
    ROUND(SUM(od.quantity * od.unit_price * (1 - od.discount))) AS total_net_sales_amount,
    ROUND(SUM(od.quantity * od.discount)) AS total_discount
FROM employees e
JOIN 
	orders o ON e.employee_id = o.employee_id
JOIN 
	order_details od ON o.order_id = od.order_id
JOIN 
	products p ON od.product_id = p.product_id
JOIN 
	categories c ON p.category_id = c.category_id
GROUP BY 
	employee_name, category_name
ORDER BY 4 DESC;

-------------------------------------------------------------

--MÜŞTERİ ANALİZİ
--En çok sipariş veren müşteriler (Top customers by orders) Hangi müşteriler en çok sipariş vermiş?
--Bu analizi yaparken customers, orders ve order_details tablolarını kullanarak, sipariş adedine göre sıralama yapabilirsin.

SELECT 
	c.customer_id,
	c.company_name,
	c.country,
	SUM(od.quantity) AS total_quantity_sold,
	COUNT(distinct o.order_id) AS total_orders,
	ROUND(SUM(od.quantity * od.unit_price * (1 - od.discount))) AS total_order_value
FROM customers c
JOIN 
	orders o ON c.customer_id = o.customer_id
JOIN
	order_details od ON o.order_id = od.order_id
JOIN products as p
		on od.product_id = p.product_id
WHERE p.discontinued=0	
GROUP BY 1,2,3
ORDER BY 
	total_order_value DESC
LIMIT 10;
	
-----------------------------------------
--CUSTOMERS by categories

WITH customer_cat_sales AS (
    SELECT
        o.customer_id,
        cat.category_name,
        SUM(od.quantity) AS total_quantity_sold,
        ROW_NUMBER() OVER (PARTITION BY cat.category_name ORDER BY SUM(od.quantity) DESC) AS rn
    FROM orders o
    JOIN order_details od ON o.order_id = od.order_id
    JOIN products p ON od.product_id = p.product_id
    JOIN categories cat ON p.category_id = cat.category_id
    WHERE p.discontinued = 0
    GROUP BY o.customer_id, cat.category_name
)
SELECT 
	customer_id, 
	category_name, 
	total_quantity_sold
FROM customer_cat_sales
WHERE rn <= 3
ORDER BY category_name, total_quantity_sold DESC;

----------------------------------------------------------
--TARİH ANALİZİ

SELECT 
	DISTINCT TO_CHAR(order_date, 'YYYY-MM') AS year_month
FROM orders
order by 1 ---BUNUN SONUCU 96 YILINDA 7-8-9-10-11-12 AYLARI VAR
		     			 --97 YILINDA BÜTÜN AYLAR VAR
						 --98 YILINDA 1-2-3-4-5 AYLARI VAR !!!!
 
----------------------------------------

--KARGO ANALİZİ
--Sipariş bazlı aylık ortalama kargo maliyeti

select
	shipper_id,
	company_name,
	round(avg(freight)) as avg_shipping_cost,
	count(order_id) total_orders,
	round(avg(shipped_date - order_date)) as avg_delivery_day,
	round(avg(required_date - order_date)) as avg_required_day
from shippers s
join orders o on s.shipper_id = o.ship_via
group by 1,2
order by 1

-----------------------------------------------	
--BÖLGE ANALİZİ (REGION_DESC)
select
	region_description,
	count(distinct o.order_id) as total_orders,
	round(sum(od.quantity)) as total_quantity_sold,
	round(sum(od.unit_price * od.quantity * (1 - od.discount))) AS total_net_revenue,
	round(avg(shipped_date - order_date)) as avg_delivery_day,
	round(avg(freight)) as avg_shipping_cost
from orders o
join order_details od ON o.order_id = od.order_id
join employees e ON o.employee_id = e.employee_id
join employeeterritories et ON e.employee_id = et.employee_id
join territories t ON et.territory_id = t.territory_id
join region r ON t.region_id = r.region_id
group by 1
order by 4 desc

-----------------------------------------
--BÖLGE ANALİZİ (COUNTRY)
select
	ship_country,
	count(distinct o.order_id) as total_orders,
	round(sum(od.quantity)) as total_quantity_sold,
	round(sum(od.unit_price * od.quantity * (1 - od.discount))) AS total_net_revenue,
	round(avg(shipped_date - order_date)) as avg_delivery_day,
	round(avg(freight)) as avg_shipping_cost
from orders o
join order_details od ON o.order_id = od.order_id
join employees e ON o.employee_id = e.employee_id
join employeeterritories et ON e.employee_id = et.employee_id
join territories t ON et.territory_id = t.territory_id
join region r ON t.region_id = r.region_id
group by 1
order by 4 desc



