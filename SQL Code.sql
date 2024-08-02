-- Q1. What is the total amount each customer spent on Zomato?

SELECT userid AS customer, SUM(price) AS total_amount_spent
FROM product AS p
JOIN sales AS s
ON p.product_id = s.product_id
GROUP BY userid
ORDER BY userid

-- Q2. How many days did each customer visit Zomato?
	
SELECT userid AS customer, COUNT(created_date) AS no_of_days
FROM sales
GROUP BY userid
ORDER BY userid

-- Q3. What is the first product purchased by each customer?
	
WITH cte AS
	(SELECT *,
	row_number() OVER(PARTITION BY userid ORDER  BY created_date ASC) AS rw
	FROM sales)
SELECT userid AS customer, product_id 
FROM cte
WHERE rw= '1'

-- Q4. What is the most purchased item on the menu and how many times has it been purchased by each customer?
	
SELECT userid AS customer, COUNT(product_id) AS product_count
FROM sales
WHERE product_id IN (SELECT product_id
	                 FROM sales
	                 GROUP BY product_id
                     ORDER BY count(product_id) DESC
                     LIMIT 1)
GROUP BY userid

-- Q5. Which item is the most popular for each customer?
	
WITH cte AS
	(SELECT userid, product_id, COUNT(product_id) AS product_count
	FROM sales
	GROUP BY userid, product_id
	ORDER BY userid),
    cte1 AS
	(SELECT *,
	row_number() OVER(PARTITION BY userid ORDER BY product_count DESC) AS rw
	FROM cte)
SELECT userid AS customer, product_id
FROM cte1
WHERE rw= 1

-- Q6. Which was the first product purchased by the customers after becoming a gold member?

WITH cte AS
	(SELECT s.userid, created_date, product_id, gold_signup_date
	FROM sales AS s
	JOIN goldusers_signup AS gu
	ON s.userid = gu.userid
	WHERE created_date > gold_signup_date),
	cte1 AS
	(SELECT *,
	row_number() OVER(PARTITION BY userid ORDER BY created_date) AS rw
	FROM cte)
SELECT userid AS customer, product_id FROM cte1
WHERE rw=1

-- Q7. Which was the last product purchased before the customers became a gold member?

WITH cte AS
	(SELECT s.userid, created_date, product_id, gold_signup_date
	FROM sales AS s
	JOIN goldusers_signup AS gu
	ON s.userid = gu.userid
	WHERE created_date < gold_signup_date),
	cte1 AS
	(SELECT *,
	row_number() OVER(PARTITION BY userid ORDER BY created_date DESC) AS rw
	from cte)
SELECT userid AS customer, product_id FROM cte1
WHERE rw=1

-- Q8. What are the total orders and amount spent by each customer before they became a member?
	
SELECT s.userid, COUNT(*) AS total_orders, SUM(price) AS amount_spent
FROM sales AS s
JOIN product AS p
ON s.product_id = p.product_id
JOIN goldusers_signup AS gu
ON s.userid = gu.userid
WHERE created_date < gold_signup_date
GROUP BY s.userid

-- Q9. How many points has each customer accumulated through their purchases, considering that for product p1, every Rs.5 spent equals 1 point, for product p2, every Rs.10 spent equals 5 points, and for product p3, every Rs.5 spent equals 1 point?	
SELECT userid, SUM(points) AS total_points
FROM (WITH cte AS
	(SELECT userid, s.product_id, product_name, SUM(price) AS amount_spent
	FROM sales AS s
	JOIN product AS p
	ON s.product_id = p.product_id
	GROUP BY userid, s.product_id, product_name
	ORDER BY userid)
	SELECT *,
	CASE WHEN product_name = 'p1' THEN amount_spent/5*1
	WHEN product_name = 'p2' THEN amount_spent/10*5
	WHEN product_name = 'p3' THEN amount_spent/5*1
	END AS points
	FROM cte)
GROUP BY userid

-- Q10. Which product purchased by customer has generated highest points?

SELECT product_id, product_name, SUM(points) AS total_points
FROM (WITH cte AS
	(SELECT userid, s.product_id, product_name, sum(price) as amount_spent
	FROM sales AS s
	JOIN product AS p
	ON s.product_id = p.product_id
	GROUP BY userid, s.product_id, product_name
	ORDER BY userid)
	SELECT *,
	CASE WHEN product_name = 'p1' THEN amount_spent/5*1
	WHEN product_name = 'p2' THEN amount_spent/10*5
	WHEN product_name = 'p3' THEN amount_spent/5*1
	END AS points
	FROM cte)
GROUP BY product_id, product_name
ORDER BY total_points DESC
LIMIT 1

-- Q11. In the first year after a customer joins the gold program(including their joining date), they accumulate 5 Zomato points for every Rs.10 spent, regardless of their purchase. What was the total points earned by each customer during this period, and which customer earned more, Customer 1 or Customer 3?
	
WITH cte AS
(SELECT s.userid, EXTRACT(YEAR from created_date) AS year, SUM(price) AS amount_spent
FROM sales AS s
JOIN product AS p
ON s.product_id = p.product_id
JOIN goldusers_signup g
ON s.userid = g.userid
WHERE created_date BETWEEN gold_signup_date AND gold_signup_date + interval '1 year'
GROUP BY s.userid, created_date
ORDER BY userid)
SELECT userid, year, amount_spent, amount_spent/10*5 AS points FROM cte
ORDER BY points DESC

-- Q12. Rank all the transaction of the customers.
SELECT *,
rank() OVER(PARTITION BY userid ORDER BY created_date asc) AS rank
FROM sales
	
-- Q13. Rank all transactions made by gold members, and for non-gold members, indicate "N/A".

WITH cte AS
	(SELECT s.userid, created_date, gold_signup_date, product_id,
	CAST((CASE WHEN gold_signup_date IS NULL THEN 0 
	ELSE rank() OVER(PARTITION BY s.userid ORDER BY created_date ASC) END) AS varchar) AS rank
	FROM sales AS s
	LEFT JOIN goldusers_signup AS g
	ON s.userid = g.userid)
SELECT userid, created_date, product_id,
CASE WHEN rank= '0' THEN 'N/A' 
ELSE rank END AS rank
FROM cte
	
