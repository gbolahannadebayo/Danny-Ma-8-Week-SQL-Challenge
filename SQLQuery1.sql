			

-- 1. What is the total amount each customer spent at the restaurant?

SELECT
customer_id, sum(price) 
FROM dannys_diner.sales as s 
JOIN dannys_diner.menu as m
ON s.product_id = m.product_id
GROUP BY customer_id;

-- 2. How many days has each customer visited the restaurant?

SELECT
customer_id, COUNT (DISTINCT order_date) as "Num_of_Days"
FROM dannys_diner.sales
GROUP BY customer_id
ORDER BY 2 DESC;

-- 3. What was the first item from the menu purchased by each customer?

WITH ranked_lists AS (
SELECT
   customer_id, 
   DENSE_RANK () OVER (PARTITION BY customer_id ORDER BY s.order_date) as rank, product_name
FROM dannys_diner.sales as s
JOIN dannys_diner.menu as m
ON s.product_id = m.product_id
  )

SELECT customer_id, product_name
FROM ranked_lists
WHERE rank=1
GROUP BY customer_id, product_name

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?

SELECT
  	product_id,
    count(product_id)
FROM dannys_diner.sales
GROUP BY product_id;

-- 5. Which item was the most popular for each customer?

WITH CTE AS(
SELECT
customer_id, m.product_name, count(s.product_id) as popularity_count,
dense_rank() over (partition by customer_id order by count(s.product_id) DESC) as rank_of_popularity
from dannys_diner.sales as s
join dannys_diner.menu as m
on s.product_id = m.product_id
group by 1,2
)

SELECT customer_id, product_name, popularity_count
FROM CTE
where rank_of_popularity=1;

-- 6. Which item was purchased first by the customer after they became a member?

WITH CTE AS 
(
SELECT
s.customer_id, s.product_id,
dense_rank() over (partition by s.customer_id order by order_date) as purchases_made
from dannys_diner.sales as s
join dannys_diner.members as m
on s.customer_id = m.customer_id
where join_date <= order_date
)

SELECT customer_id, c.product_id, me.product_name
FROM CTE as c 
join dannys_diner.menu as me
on c.product_id = me.product_id
where purchases_made=1
order by customer_id ;

-- 7. Which item was purchased just before the customer became a member?

WITH CTE AS 
(
SELECT
s.customer_id, s.product_id,
dense_rank() over (partition by s.customer_id order by order_date DESC) as purchases_made
from dannys_diner.sales as s
join dannys_diner.members as m
on s.customer_id = m.customer_id
where join_date > order_date
)

SELECT customer_id, c.product_id, me.product_name
FROM CTE as c 
join dannys_diner.menu as me
on c.product_id = me.product_id
where purchases_made=1
order by customer_id ;

-- 8. What is the total items and amount spent for each member before they became a member?

SELECT
s.customer_id,  COUNT (DISTINCT s.product_id) as Total_Items, SUM(price)
from dannys_diner.sales as s
join dannys_diner.menu as m
on s.product_id = m.product_id
join dannys_diner.members as me
on s.customer_id = me.customer_id
where order_date < join_date
group by s.customer_id;

-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

WITH CTE AS 
(
  SELECT *,
CASE WHEN product_id = 1 THEN price *20
ELSE price * 10
END AS points 
FROM dannys_diner.menu
)

SELECT customer_id, sum(points)
FROM dannys_diner.sales as s
JOIN CTE as c
ON s.product_id = c.product_id
GROUP BY customer_id
ORDER BY customer_id;


-- BONUS QUESTIONS 
-- 1.)

SELECT s.customer_id, s.order_date, m.product_name, m.price,
CASE WHEN join_date <= order_date THEN 'Y'
WHEN join_date > order_date THEN 'N'
ELSE 'N' END AS members
FROM dannys_diner.sales as s
LEFT JOIN dannys_diner.menu as m
ON s.product_id = m.product_id
LEFT JOIN dannys_diner.members as me
ON s.customer_id = me.customer_id;

-- 2.)

WITH CTE AS
(
SELECT s.customer_id, s.order_date, m.product_name, m.price,
CASE WHEN join_date <= order_date THEN 'Y'
WHEN join_date > order_date THEN 'N'
ELSE 'N' END AS members
FROM dannys_diner.sales as s
LEFT JOIN dannys_diner.menu as m
ON s.product_id = m.product_id
LEFT JOIN dannys_diner.members as me
ON s.customer_id = me.customer_id
)

SELECT *, CASE WHEN members = 'N' THEN NULL 
ELSE
RANK() OVER (PARTITION BY customer_id, members ORDER BY order_date) END AS ranking
FROM CTE