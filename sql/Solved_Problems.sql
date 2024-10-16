
----------------------------------------------------------------------------------------------
--                                20 Advanced Business Problems							    --
----------------------------------------------------------------------------------------------

/*
1. Top Selling Products
Query the top 10 products by total sales value.
Challenge: Include product name, total quantity sold, and total sales value.
*/

--  Altering table by adding new column

ALTER TABLE order_items
ADD COLUMN total_sales FLOAT;

-- Updating column with values (quantity * price_per_unit)

UPDATE order_items
SET total_sales = quantity * price_per_unit;

SELECT 
	oi.product_id as "Product_ID", 
	p.product_name as "Product", 
	ROUND(SUM(oi.total_sales)::numeric, 2) AS "Total Sales",
	COUNT(o.order_id) AS "Total Orders"
FROM 
	order_items AS oi
JOIN
	orders AS o
ON 
	oi.order_id = o.order_id
JOIN
	products AS p
ON 
	oi.product_id = p.product_id
GROUP BY 
	oi.product_id, p.product_name
ORDER BY 
	"Total Sales" DESC
LIMIT 10;

/*
2. Revenue by Category
Calculate total revenue generated by each product category.
Challenge: Include the percentage contribution of each category to total revenue.
*/

SELECT 
    c.category_id AS "Category_ID",
    c.category_name AS "Category",
    ROUND(SUM(oi.total_sales)::numeric,2) AS "Total Sales",
    ROUND((SUM(oi.total_sales) / (SELECT SUM(total_sales) FROM order_items) * 100)::numeric, 2) AS "Total Contribution (%)"
FROM
    order_items AS oi
JOIN 
    products AS p
ON	
    oi.product_id = p.product_id
LEFT JOIN
    category AS c
ON
    p.category_id = c.category_id
GROUP BY 
    c.category_id, c.category_name
ORDER BY
    "Total Sales" DESC;

/*
3. Average Order Value (AOV)
Compute the average order value for each customer.
Challenge: Include only customers with more than 5 orders.
*/

SELECT
    c.customer_id as "Customer_ID",
    CONCAT(c.first_name, ' ', c.last_name) AS "Name",
	COUNT(o.order_id) AS "Orders",
    ROUND((SUM(oi.total_sales) / COUNT(o.order_id))::numeric,2) AS "AOV"
FROM 
    customers AS c
JOIN 
    orders AS o
ON 
    c.customer_id = o.customer_id
JOIN 
    order_items AS oi
ON 
    o.order_id = oi.order_id
GROUP BY 
    c.customer_id, c.first_name, c.last_name
HAVING 
    COUNT(o.order_id) > 5
ORDER BY 
    "AOV" DESC;

/*
4. Monthly Sales Trend
Query monthly total sales over the past year.
Challenge: Display the sales trend, grouping by month, return current_month sale, last month sale!
*/

SELECT
    "Year",
    "Month",
    "Total Sales" AS "Current Month Sale",
    LAG("Total Sales", 1) OVER (ORDER BY "Year", "Month") AS "Last Month Sale"
FROM
(
    SELECT 
        EXTRACT(MONTH FROM o.order_date) AS "Month",
        EXTRACT(YEAR FROM o.order_date) AS "Year",
        ROUND(SUM(oi.total_sales)::NUMERIC, 2) AS "Total Sales"
    FROM 
        orders o
    JOIN
        order_items oi
    ON
        oi.order_id = o.order_id
    WHERE
        o.order_date >= CURRENT_DATE - INTERVAL '1 year' -- Get data from the last year
    GROUP BY 
        "Year", "Month"
    ORDER BY 
        "Year", "Month"
) AS "Sales Summary";

/*
5. Customers with No Purchases
Find customers who have registered but never placed an order.
Challenge: List customer details and the time since their registration.
*/

-- Approach 1: Using a subquery to exclude customers with orders
SELECT * 
FROM 
    customers
WHERE 
    customer_id NOT IN (
        SELECT DISTINCT customer_id 
        FROM orders
    );

-- Approach 2: Using a LEFT JOIN to find customers without orders
SELECT * 
FROM
    customers AS c
LEFT JOIN
    orders AS o
ON
    o.customer_id = c.customer_id
WHERE 
    o.order_date IS NULL;

/*
6. Least-Selling Categories by State
Identify the least-selling product category for each state.
Challenge: Include the total sales for that category within each state.
*/

WITH Ranking_Table AS (
    SELECT  
        c.state AS "State", 
        ct.category_name AS "Category", 
        ROUND(SUM(oi.total_sales)::NUMERIC, 2) AS "Total Sales",
        RANK() OVER (PARTITION BY c.state ORDER BY ROUND(SUM(oi.total_sales)::NUMERIC, 2) ASC) AS "Rank"
    FROM
        customers c
    JOIN
        orders o ON c.customer_id = o.customer_id
    JOIN	
        order_items oi ON o.order_id = oi.order_id
    JOIN 
        products p ON oi.product_id = p.product_id
    JOIN	
        category ct ON p.category_id = ct.category_id
    GROUP BY
        c.state, ct.category_name
)

SELECT "State", "Category", "Total Sales" 
FROM Ranking_Table 
WHERE "Rank" = 1;

/*
7. Customer Lifetime Value (CLTV)
Calculate the total value of orders placed by each customer over their lifetime.
Challenge: Rank customers based on their CLTV.
*/

SELECT
    c.customer_id AS "Customer_ID",
    CONCAT(c.first_name, ' ', c.last_name) AS "Name",
    ROUND(SUM(oi.total_sales)::NUMERIC, 2) AS "CLTV",
    DENSE_RANK() OVER (ORDER BY ROUND(SUM(oi.total_sales)::NUMERIC, 2) DESC) AS "Rank"
FROM
    customers c
JOIN
    orders o ON c.customer_id = o.customer_id
JOIN
    order_items oi ON o.order_id = oi.order_id
GROUP BY
    c.customer_id, c.first_name, c.last_name;

/*
8. Inventory Stock Alerts
Query products with stock levels below a certain threshold (e.g., less than 10 units).
Challenge: Include last restock date and warehouse information.
*/

SELECT 
	i.inventory_id AS "Inventory ID",
	p.product_name AS "Product",
	i.stock AS "Current Stock Left",
	i.last_stock_date AS "Last Stock Date",
	i.warehouse_id AS "Warehouse ID"
FROM 
    inventory i
JOIN 
    products p ON i.product_id = p.product_id
WHERE 
    i.stock < 10
ORDER BY 
    i.stock DESC;

/*
9. Shipping Delays
Identify orders where the shipping date is later than 3 days after the order date.
Challenge: Include customer, order details, and delivery provider.
*/

SELECT 
    c.*,
    o.*,
    sh.shipping_providers,
    sh.shipping_date - o.order_date AS "Delivery Days"
FROM 
    customers c
JOIN
    orders o ON c.customer_id = o.customer_id
JOIN 
    shipping sh ON o.order_id = sh.order_id
WHERE 
    sh.shipping_date - o.order_date > 3;

/*
10. Payment Success Rate 
Calculate the percentage of successful payments across all orders.
Challenge: Include breakdowns by payment status (e.g., failed, pending).
*/

SELECT 
    p.payment_status AS "Payment Status",
    COUNT(*) AS "Count",
    ROUND((COUNT(*)::NUMERIC / (SELECT COUNT(*) FROM payments)::NUMERIC) * 100, 2) AS "Breakdown (%)"
FROM 
    orders o
JOIN 
    payments p ON o.order_id = p.order_id
GROUP BY 
    p.payment_status;

/*
11. Top Performing Sellers
Find the top 5 sellers based on total sales value.
Challenge: Include both successful and failed orders, and display their percentage of successful orders.
*/

WITH top_sellers AS 
(
    SELECT 
        s.seller_id,
        s.seller_name,
        ROUND(SUM(oi.total_sales)::numeric,2) AS "Total Sales"
    FROM 
        orders AS o
    JOIN 
        sellers AS s ON o.seller_id = s.seller_id
    JOIN 
        order_items AS oi ON oi.order_id = o.order_id
    GROUP BY 
        s.seller_id, s.seller_name
    ORDER BY 
        "Total Sales" DESC
    LIMIT 5
),
seller_order_status AS 
(
    SELECT
        o.seller_id,
        ts.seller_name,
        o.order_status,
        COUNT(*) AS "Total Orders"
    FROM 
        orders AS o
    JOIN 
        top_sellers AS ts ON ts.seller_id = o.seller_id
    WHERE 
        o.order_status NOT IN ('Inprogress', 'Returned')
    GROUP BY 
        o.seller_id, o.order_status, ts.seller_name
)

SELECT
    seller_id as "Seller ID",
    seller_name as "Name",
    SUM(CASE WHEN order_status = 'Completed' THEN "Total Orders" ELSE 0 END) AS "Completed Orders",
    SUM(CASE WHEN order_status = 'Cancelled' THEN "Total Orders" ELSE 0 END) AS "Cancelled Orders",
    SUM("Total Orders") AS "Total Orders",
    ROUND(SUM(CASE WHEN order_status = 'Completed' THEN "Total Orders" ELSE 0 END)::NUMERIC / 
          NULLIF(SUM("Total Orders")::NUMERIC, 0) * 100, 2) AS "Order Completion Rate"
FROM 
    seller_order_status
GROUP BY 
    "Seller ID", "Name"
ORDER BY 
    "Seller ID", "Name";

/*
12. Product Profit Margin
Calculate the profit margin for each product (difference between price and cost of goods sold).
Challenge: Rank products by their profit margin, showing highest to lowest.
*/

SELECT 
    product_id,
    product_name,
    "Profit Margin",
    DENSE_RANK() OVER(ORDER BY "Profit Margin" DESC) AS "Product Rank"
FROM
(
    SELECT
        p.product_id,
        p.product_name,
        ROUND((SUM(oi.total_sales - (p.cogs * oi.quantity)) / NULLIF(SUM(oi.total_sales), 0))::numeric * 100, 2) AS "Profit Margin"
    FROM 
        products AS p
    JOIN 
        order_items AS oi ON p.product_id = oi.product_id
    GROUP BY 
        p.product_id, 
        p.product_name
) AS subquery;

/*
13. Most Returned Products
Query the top 10 products by the number of returns.
Challenge: Display the return rate as a percentage of total units sold for each product.
*/

SELECT 
    p.product_id,
    p.product_name,
    COUNT(*) AS "Total Units Sold",
    SUM(CASE WHEN o.order_status = 'Returned' THEN 1 ELSE 0 END) AS "Total Returned",
    ROUND((SUM(CASE WHEN o.order_status = 'Returned' THEN 1 ELSE 0 END)::numeric / COUNT(*)::numeric * 100), 2) AS "Returned (%)"
FROM 
    order_items AS oi
JOIN 
    products AS p ON oi.product_id = p.product_id
JOIN 
    orders AS o ON o.order_id = oi.order_id
GROUP BY 
    p.product_id,
    p.product_name
ORDER BY 
    "Returned (%)" DESC
LIMIT 10;

/*
14. Orders Pending Shipment
Find orders that have been paid but are still pending shipment.
Challenge: Include order details, payment date, and customer information.
*/

SELECT
    c.customer_id AS "Customer ID",
	o.order_id AS "Order ID",
    CONCAT(c.first_name, ' ', c.last_name) AS "Name",
    c.state AS "State",
    o.order_date AS "Order Date",
    o.order_status AS "Order Status"
FROM 
    customers AS c
JOIN 
    orders AS o ON c.customer_id = o.customer_id
JOIN 
    payments AS p ON o.order_id = p.order_id
WHERE 
    o.order_status = 'Inprogress' 
    AND p.payment_status = 'Payment Successed';
 
/*
15. Inactive Sellers
Identify sellers who haven’t made any sales in the last 6 months.
Challenge: Show the last sale date and total sales from those sellers.
*/

WITH seller_not_sale_6_month AS (
    -- Sellers who have not made any sales in the last 6 months
    SELECT seller_id, seller_name
    FROM sellers
    WHERE seller_id NOT IN (
        SELECT DISTINCT seller_id 
        FROM orders 
        WHERE order_date >= CURRENT_DATE - INTERVAL '6 months'
    )
)

SELECT 
    s.seller_id "Seller ID",
	s.seller_name as "Name",
    MAX(o.order_date) AS "Last Sale Date",
    COALESCE(SUM(oi.total_sales), 0) AS "Total Sales" 
FROM 
    seller_not_sale_6_month AS s
LEFT JOIN 
    orders AS o ON s.seller_id = o.seller_id
LEFT JOIN 
    order_items AS oi ON o.order_id = oi.order_id
GROUP BY 
    "Seller ID", "Name";

/*
16. IDENTITY customers into returning or new
if the customer has done more than 5 return categorize them as returning otherwise new
Challenge: List customers id, name, total orders, total returns
*/

SELECT
	"Name",
	"Total Orders",
	"Total Returns",
	CASE 
		WHEN "Total Returns" > 5 THEN 'Returning' 
		ELSE 'New' 
	END AS "Category"
FROM (
	SELECT
		CONCAT(c.first_name, ' ', c.last_name) AS "Name",
		COUNT(o.order_id) AS "Total Orders",
		SUM(CASE 
			WHEN o.order_status = 'Returned' THEN 1 
			ELSE 0  
		END) AS "Total Returns"
	FROM 
		customers AS c
	JOIN 
		orders AS o ON o.customer_id = c.customer_id
	GROUP BY 
		c.first_name, c.last_name
) AS subquery
ORDER BY  
	"Total Returns" DESC;

/*
17. Top 5 Customers by Orders in Each State
Identify the top 5 customers with the highest number of orders for each state.
Challenge: Include the number of orders and total sales for each customer.
*/

SELECT
	CONCAT(c.first_name, ' ', c.last_name) AS "Name",
	c.state AS "State",
	COUNT(o.order_id) AS "No. of Orders",
	ROUND(SUM(oi.total_sales)::numeric, 2) AS "Total Sales",
	DENSE_RANK() OVER(PARTITION BY c.state ORDER BY COUNT(o.order_id) DESC) AS "Rank"
FROM 
	orders AS o
JOIN 
	customers AS c ON c.customer_id = o.customer_id
JOIN 
	order_items AS oi ON o.order_id = oi.order_id
GROUP BY 
	c.first_name, c.last_name, c.state
ORDER BY 
	"State", "Rank";

/*
18. Revenue by Shipping Provider
Calculate the total revenue handled by each shipping provider.
Challenge: Include the total number of orders handled and the average delivery time for each provider.
*/

SELECT 
    s.shipping_providers AS "Shipment Providers",
    COUNT(o.order_id) AS "Orders Handled",
    ROUND(SUM(oi.total_sales)::numeric, 2) AS "Total Sales",
	-- Delivery date should fall somewhere between the shipping date and return date
    -- (s.shipping_date + (s.return_date - s.shipping_date)) AS "Delivery Date", 
    COALESCE(ROUND(AVG((s.shipping_date + (s.return_date - s.shipping_date) / 2) - s.shipping_date)::numeric, 2), 0) AS "Avg Delivery Time"
FROM 
    order_items AS oi
JOIN 
    orders AS o ON oi.order_id = o.order_id
JOIN 
    shipping AS s ON s.order_id = o.order_id
GROUP BY 
    s.shipping_providers;

/*
19. Top 10 product with highest decreasing revenue ratio compare to last year(2022) and current_year(2023)
Challenge: Return product_id, product_name, category_name, 2022 revenue and 2023 revenue decrease ratio at end Round the result
Note: Decrease ratio = cr-ls/ls* 100 (cs = current_year ls=last_year)
*/

WITH last_year_sale AS (
    SELECT 
        p.product_id,
        p.product_name,
        ROUND(SUM(oi.total_sales)::numeric, 2) AS revenue
    FROM
        products AS p
    JOIN 
        order_items AS oi ON p.product_id = oi.product_id
    JOIN 
        orders AS o ON oi.order_id = o.order_id
    WHERE 
        EXTRACT(YEAR FROM o.order_date) = 2022
    GROUP BY 
        p.product_id, p.product_name
),
current_year_sale AS (
    SELECT 
        p.product_id,
        p.product_name,
        ROUND(SUM(oi.total_sales)::numeric, 2) AS revenue
    FROM
        products AS p
    JOIN 
        order_items AS oi ON p.product_id = oi.product_id
    JOIN 
        orders AS o ON oi.order_id = o.order_id
    WHERE 
        EXTRACT(YEAR FROM o.order_date) = 2023
    GROUP BY 
        p.product_id, p.product_name
)

SELECT
    cs.product_id AS "Product ID",
    cs.product_name AS "Name",
    ls.revenue AS "Last Year Revenue",
    cs.revenue AS "Current Year Revenue",
    (ls.revenue - cs.revenue) AS "Revenue Difference",
    ROUND(((ls.revenue - cs.revenue) / ls.revenue) * 100, 2) AS "Revenue Decrease Ratio"
FROM 
    last_year_sale AS ls
JOIN 
    current_year_sale AS cs ON ls.product_id = cs.product_id
WHERE 
    ls.revenue > cs.revenue 
ORDER BY 
    "Revenue Decrease Ratio" DESC
LIMIT 10;


/*
20.Final Task
-- Store Procedure
create a function as soon as the product is sold the the same quantity should reduced from inventory table
after adding any sales records it should update the stock in the inventory table based on the product and qty purchased
-- 
*/

SELECT * FROM products;

SELECT * FROM orders --where order_id = 24001;

SELECT * FROM order_items where order_item_id= 24001;

SELECT * FROM inventory where product_id = 38; -- Stock = 91

ALTER TABLE order_items
RENAME COLUMN order_item TO order_item_id;


CREATE OR REPLACE PROCEDURE process_order_and_update_inventory 
(
    p_order_id INT,         -- Order ID provided for the new order
    p_customer_id INT,      -- Customer ID associated with the order
    p_seller_id INT,        -- Seller ID associated with the order
    p_order_item_id INT,    -- Unique Order Item ID for each product in the order
    p_product_id INT,       -- Product ID of the item being ordered
    p_quantity INT          -- Quantity of the product being ordered
)
LANGUAGE plpgsql
AS $$

DECLARE 
    -- Variables to store product details and stock check result
    v_count INT;           
    v_price FLOAT;          
    v_product VARCHAR(50);  

BEGIN
    -- Retrieve product name and price based on the provided product ID
    SELECT 
        price, 
        product_name
    INTO
        v_price, 
        v_product
    FROM products
    WHERE product_id = p_product_id;
    
    -- Check inventory for product availability with the required quantity
    SELECT 
        COUNT(*) 
    INTO
        v_count
    FROM inventory
    WHERE 
        product_id = p_product_id   -- Check for the specified product
        AND stock >= p_quantity;    -- Ensure available stock is equal to or greater than the ordered quantity
        
    -- If sufficient stock is available, proceed with order and update inventory
    IF v_count > 0 THEN
        
		-- Insert the new order details into the 'orders' table
        INSERT INTO orders(order_id, order_date, customer_id, seller_id)
        VALUES
        (p_order_id, CURRENT_DATE, p_customer_id, p_seller_id);

        -- Insert product details into the 'order_items' table, calculating total sales
        INSERT INTO order_items(order_item_id, order_id, product_id, quantity, price_per_unit, total_sales)
        VALUES
        (p_order_item_id, p_order_id, p_product_id, p_quantity, v_price, v_price * p_quantity);

        -- Update the 'inventory' table to reduce stock by the ordered quantity
        UPDATE inventory
        SET stock = stock - p_quantity
        WHERE product_id = p_product_id;
        
        -- Display a success message indicating the product sale has been recorded and stock updated
        RAISE NOTICE 'Thank you, the product % sale has been added and inventory stock has been updated.', v_product; 
    ELSE
        -- If stock is insufficient, display a message indicating the product is unavailable
        RAISE NOTICE 'Unfortunately, the product: % is not available', v_product;
    END IF;

END;
$$;


call process_order_and_update_inventory (24001, 10 , 3, 24007, 38, 11);


SELECT * FROM inventory where product_id = 38;
SELECT * FROM orders where order_id = 24001;
SELECT * FROM order_items where order_item_id = 2400;