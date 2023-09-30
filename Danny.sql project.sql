CREATE DATABASE dannys_diner;


CREATE TABLE sales (

  customer_id VARCHAR(1),

  order_date DATE,

  product_id INTEGER

);

INSERT INTO sales

  (customer_id, order_date, product_id) 
  

VALUES

  ('A', '2021-01-01', '1'),

  ('A', '2021-01-01', '2'),

  ('A', '2021-01-07', '2'),

  ('A', '2021-01-10', '3'),

  ('A', '2021-01-11', '3'),

  ('A', '2021-01-11', '3'),

  ('B', '2021-01-01', '2'),

  ('B', '2021-01-02', '2'),

  ('B', '2021-01-04', '1'),

  ('B', '2021-01-11', '1'),

  ('B', '2021-01-16', '3'),

  ('B', '2021-02-01', '3'),

  ('C', '2021-01-01', '3'),

  ('C', '2021-01-01', '3'),

  ('C', '2021-01-07', '3');

 

CREATE TABLE menu (

  product_id INTEGER,

  product_name VARCHAR(5),

  price INTEGER

);

INSERT INTO menu

  (product_id, product_name, price)

VALUES

  ('1', 'sushi', '10'),

  ('2', 'curry', '15'),

  ('3', 'ramen', '12');

  

CREATE TABLE members (

  customer_id VARCHAR(1),

  join_date DATE

);

INSERT INTO members

  (customer_id, join_date)

VALUES

  ('A', '2021-01-07'),

  ('B', '2021-01-09');

-- 1. What is the total amount each customer spent at the restaurant?

SELECT customer_id, 

    SUM(price) AS Total_amount

FROM sales S LEFT JOIN menu M 

ON S.product_id = M.product_id

GROUP BY customer_id;

-- 2. How many days has each customer visited the restaurant?

SELECT customer_id, 

    COUNT(DISTINCT order_date) AS no_of_days

FROM sales

GROUP BY customer_id;

-- 3. What was the first item from the menu purchased by each customer?

WITH cte AS (SELECT *, ROW_NUMBER() OVER(PARTITION BY customer_id ORDER BY order_date) AS cust_rank 

FROM sales LEFT JOIN menu USING(product_id))

SELECT customer_id, product_name FROM cte WHERE cust_rank = 1;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT 
product_name, count(*) no_of_sales 

FROM sales s LEFT JOIN menu m 

ON s.product_id = m.product_id 
GROUP BY product_name
ORDER BY no_of_sales DESC

LIMIT 1;

-- 5. Which item was the most popular for each customer?

SELECT customer_id, 

    product_name, 

    count(*) AS no_of_purchase

FROM sales s 

LEFT JOIN menu m on s.product_id = m.product_id

GROUP BY customer_id, product_name

ORDER BY no_of_purchase DESC, customer_id DESC

LIMIT 3;

-- 6. Which item was purchased first by the customer after they became a member?

WITH  cte AS (SELECT 
s.customer_id, 
product_name, 
order_date,
ROW_NUMBER()
OVER(PARTITION BY 
s.customer_id ORDER BY order_date) AS cust_rnk 
FROM sales s JOIN members m ON s.customer_id = m.customer_id 
LEFT JOIN menu me 
ON s.product_id = me.product_id
WHERE s.order_date >= m.join_date)

SELECT 
customer_id, 
product_name

FROM cte

WHERE cust_rnk = 1;

-- 7. Which item was purchased just before the customer became a member? 

WITH cte AS 

(SELECT 

s.customer_id, 

product_name, 

s.order_date,

RANK() OVER(PARTITION BY s.customer_id ORDER BY s.order_date DESC) AS customer_rnk

FROM sales s JOIN members m 

USING (customer_id)

LEFT JOIN menu me 

USING (product_id)

WHERE s.order_date < m.join_date)

SELECT 
customer_id, 

product_name

FROM cte

WHERE customer_rnk = 1;

-- 8. What is the total items and amount spent for each member before they became a member?

SELECT 

customer_id,

COUNT(*) AS orders, 

SUM(price) AS amount_spent 

FROM sales s jOIN members m USING(customer_id) 

LEFT JOIN menu USING(product_id) 

WHERE s.order_date < m.join_date

GROUP BY customer_id;

-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier -

-- how many points would each customer have?

SELECT customer_id, 

SUM(CASE WHEN product_name = 'sushi' THEN 20*price ELSE 10*price 

END) AS point_accrued

FROM sales s LEFT JOIN menu USING (product_id) 

GROUP BY customer_id;

WITH cte AS (SELECT *, 

CASE WHEN product_name = 'sushi' THEN 20*price ELSE 10*price 

END AS point_accrued

FROM sales s LEFT JOIN menu USING (product_id))

SELECT customer_id, SUM(point_accrued) AS points

FROM cte

GROUP BY customer_id;

SELECT customer_id, SUM(point_accrued) 

FROM (SELECT *, 

CASE WHEN product_name = 'sushi' THEN 20*price ELSE 10*price 

END AS point_accrued

FROM sales s LEFT JOIN menu USING (product_id)) A

GROUP BY customer_id;

-- 10. In the first week after a customer joins the program (including their join date) they earn 

-- 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

WITH cte AS (
  SELECT s.customer_id,  -- specify the table alias here
    CASE 
      WHEN s.order_date BETWEEN m.join_date AND m.join_date + INTERVAL '7 DAY'
        THEN 20 * menu.price 
      ELSE 10 * menu.price 
    END AS points
  FROM sales s 
  JOIN members m ON s.customer_id = m.customer_id 
  LEFT JOIN menu ON s.product_id = menu.product_id
  WHERE s.order_date >= m.join_date AND EXTRACT(MONTH FROM s.order_date) = 1
)
SELECT customer_id, SUM(points) AS points 
FROM cte
GROUP BY customer_id;
