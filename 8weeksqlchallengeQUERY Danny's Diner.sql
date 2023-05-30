create database dannys_diner;
	create table sales (
    customer_id varchar(1),
    order_date date,
    product_id int);
    insert into sales (customer_id, order_date, product_id) values
    ("A",	"2021-01-01",	1),
    ("A",	"2021-01-01",	2),
    ("A",	"2021-01-07",	2),
    ("A",	"2021-01-10",	3),
    ("A",	"2021-01-11",	3),
    ("A",	"2021-01-11",	3),
    ("B",	"2021-01-01",	2),
    ("B",	"2021-01-02",	2),
    ("B",	"2021-01-04",	1),
    ("B",	"2021-01-11",	1),
    ("B",	"2021-01-16",	3),
    ("B",	"2021-02-01",	3),
    ("C",	"2021-01-01",	3),
    ("C",	"2021-01-01",	3),
    ("C",	"2021-01-07",	3);
    
    create table menu
    (
    product_id int,
    product_name varchar(225),
    price int
    );
    insert into menu(product_id, product_name, price) values
    (1,	"sushi",10),
    (2,	"curry",15),
    (3,	"ramen",12);
    
    create table members
    (customer_id int,
    join_date date
    );
    
    ALTER TABLE members
    modify customer_id varchar(1);
    
    insert into members(customer_id, join_date) values
    ("A",	"2021-01-07"),
    ("B",	"2021-01-09");
    
#What is the total amount each customer spent at the restaurant?
select customer_id, sum(price) as total_amount_spent
from sales join menu on sales.product_id = menu.product_id
group by customer_id;
    
#How many days has each customer visited the restaurant?
select customer_id, count(distinct order_date) as days_visited
from sales
group by customer_id;
    
#What was the first item from the menu purchased by each customer?
select customer_id, product_name, min(order_date) as first_date
from sales join menu on sales.product_id = menu.product_id
group by customer_id;
    
#What is the most purchased item on the menu and how many times was it purchased by all customers?
select product_name, count(sales.product_id) as no_oforders, menu.product_id as product_id
from sales left join menu on sales.product_id = menu.product_id
group by product_name
order by no_oforders desc
limit 1;
    
#Which item was the most popular for each customer?
with most_popular as(
select customer_id, menu.product_name as product_name, sales.product_id as product_id, count(sales.product_id) as total
from sales left join menu on sales.product_id = menu.product_id
group by customer_id, product_id
order by customer_id, total desc)
select customer_id, product_name, max(total) as no_of_purchases
FROM most_popular
group by customer_id;
    
#Which item was purchased first by the customer after they became a member?
with after_member as
(select members.customer_id, members.join_date, menu.product_name, sales.order_date, sales.product_id
FROM sales JOIN members ON sales.customer_id = members.customer_id JOIN menu ON menu.product_id = sales.product_id
WHERE sales.order_date > members.join_date)
Select MIN(order_date) as date_after_member, customer_id, product_name FROM after_member GROUP BY customer_id;
    
#Which item was purchased just before the customer became a member?
with before_member as
(select members.customer_id, members.join_date, menu.product_name, sales.order_date, sales.product_id
FROM sales JOIN members ON sales.customer_id = members.customer_id JOIN menu ON menu.product_id = sales.product_id
WHERE sales.order_date < members.join_date)
Select MAX(order_date) as date_before_member, customer_id, product_name FROM before_member GROUP BY customer_id;
    
#What is the total items and amount spent for each member before they became a member?
with before_member as
(select members.customer_id, members.join_date, menu.product_name, menu.price, sales.order_date, sales.product_id
FROM sales JOIN members ON sales.customer_id = members.customer_id JOIN menu ON menu.product_id = sales.product_id
WHERE sales.order_date < members.join_date)
Select customer_id, count(order_date) as total_items, sum(price) as total_amount_spent
FROM before_member GROUP BY customer_id;
    
#If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT sales.customer_id, sum(case when product_name = 'sushi' then price*20 else price*20 end) AS total_points
FROM Sales JOIN Menu on sales.product_id = menu.product_id
GROUP BY customer_id;

#In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
SELECT sales.customer_id as customer,
sum(case when menu.product_name = 'sushi' then menu.price*20 when sales.order_date >= members.join_date AND sales.order_date < DATE_ADD(members.join_date, INTERVAL 1 WEEK) then menu.price*20 else price * 10 end) 
as points_in_january
FROM sales Left JOIN menu ON sales.product_id = menu.product_id left join members on sales.customer_id = members.customer_id
WHERE sales.order_date >= '2021-01-01' AND sales.order_date < '2021-02-01'
GROUP BY sales.customer_id;

#Join tables and add a new column to identify orders by members. BONUS question
SELECT sales.customer_id, sales.order_date, menu.product_name, menu.price, 
case when sales.order_date >= members.join_date then 'Y' else 'N' end as members
FROM sales join menu on sales.product_id = menu.product_id join members on sales.customer_id = members.customer_id
order by sales.customer_id, sales.order_date, menu.product_name;

#Rank products for each customer based on date ordered. BONUS question
SELECT sales.customer_id, sales.order_date, menu.product_name, menu.price, 
case when sales.order_date >= members.join_date then 'Y' else 'N' end as members, 
case when (case when sales.order_date >= members.join_date then 'Y' else 'N' end) = 'N' then null else dense_rank() over(partition by sales.customer_id, (case when sales.order_date >= members.join_date then 'Y' else 'N' end) order by sales.order_date)  end as "ranking"
FROM sales join menu on sales.product_id = menu.product_id join members on sales.customer_id = members.customer_id
order by sales.customer_id, sales.order_date, menu.product_name;