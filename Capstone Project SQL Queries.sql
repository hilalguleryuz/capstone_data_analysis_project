--PRODUCT-CATEGORY ANALYSIS
--Category-based sales performance, net income, shipping cost and total discount analysis

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
	
---------------------------------------------------------------
--SUPPLIER ANALYSIS
--Supplier ranking by net_profit

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

---------------------------------------------------------------
--EMPLOYEE ANALYSIS
--We were asked by human resources to evaluate the total sales performance of each employee by category.
--Considering the discounts given, we can calculate the net sales amount by employee and identify the employees who achieved the highest net sales.

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

---------------------------------------------------------------

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
--CUSTOMER ANALYSIS
--Top customers by orders which customers have placed the most orders?
--While performing this analysis, we can sort by order number using the customers, orders and order_details tables.

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
--Customer analysis by categories

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

----------------------------------------
--SHIPPING ANALYSIS
--Order based monthly average shipping cost

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
--REGION ANALYSIS

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
--Region analysis by countries
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


