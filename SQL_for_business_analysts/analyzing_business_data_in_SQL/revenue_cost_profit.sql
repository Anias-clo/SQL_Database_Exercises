/*
Chapter 1. Revenue, cost, and profit
Profit is one of the first things people use to assess a company's success.
In this chapter, you'll learn how to calculate revenue and cost, and then combine
the two calculations using Common Table Expressions to calculate profit.

-------------------------------- NOTES ------------------------------------------

Introduction and revenue
$ Revenue, cost, and profit
- Profit: The money a company makes minus the money it spends.
- Revenue: The money a company makes
- Cost: The money a company spends

Profit = Revenue - Cost

Example Company: Delivr
$ Calculating revenue
- Three burgers @ $5 each
- Two sandwiches @ $3 each

3 x $5 + 2 x $3 = $21

Revenue Formula: Multiply each meal's price times its ordered quantity, then sum the results

$ Working with dates

DATE_TRUNC(date_part, date)

- Given a date part and a date, DATE_TRUNC returns the first day of the date nearest to
  the date part
- DATE_PART outputs a Timestamp and NOT a date, you must cast it to a DATE data type to drop Time data.
*/

------------------------------ EXERCISES -----------------------------------------

-- 1. Revenue per customer
/*
A customer calls to verify the total amount she paid through the app. Her calculated amount is $271.
Help the support team answer her question using SQL
*/
-- Calculate revenue
SELECT SUM(meals.meal_price * orders.order_quantity) AS revenue
FROM meals
JOIN orders ON meals.meal_id = orders.meal_id
-- Keep only the records of customer ID 15
WHERE orders.user_id = 15;


-- 2. Revenue per week
/*
Delivr's first full month of operations was June 2018. At launch the marketing team ran an ad campaign
on popular food channels on TV, with the number of ads increasing each week through the end of the month.
The Head of Marketing asks you to help her assess that campaign's success.

Get the revenue per week for each week in June and check whether there's any consistent growth in revenue.
*/
SELECT DATE_TRUNC('week', order_date) :: DATE AS delivr_week,
       -- Calculate revenue
       SUM(meals.meal_price * orders.order_quantity) AS revenue
  FROM meals
  JOIN orders ON meals.meal_id = orders.meal_id
-- Keep only the records in June 2018
WHERE order_date BETWEEN '06-01-2018' AND '06-30-2018'
GROUP BY delivr_week
ORDER BY delivr_week ASC;