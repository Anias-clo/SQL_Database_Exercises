/*
Chapter 2. Summarizing and aggregating numeric data

You'll build on functions like min and max to summarize numeric data in new ways.
Add average, variance, correlation, and percentile functions to your toolkit,
and learn how to truncate and round numeric values too.
Build complex queries and save your results by creating temporary tables.


Numeric types: integer

| Name                   | Storage Size | Description          | Range                                        |
|------------------------|--------------|----------------------|----------------------------------------------|
| integer or int or int4 | 4 bytes      | Typical choice       | -214783648 to +2147483647                    |
| smallint or int2       | 2 bytes      | small-range          | -32768 to +32767                             |
| bigint or int8         | 8 bytes      | large-range          | -9223372036854775808 to +9223372036844775808 |
| serial                 | 4 bytes      | auto-increment       | 1 to 2147483647                              |
| smallserial            | 2 bytes      | small auto-increment | 1 to 32767                                   |
| bigserial              | 8 bytes      | large auto-increment | 1 to 9223372036854775807                     |


Numeric types: decimal

| Name                   | Storage Size | Description                     | Range                                        |
|------------------------|--------------|---------------------------------|----------------------------------------------|
| decimal or numeric     | variable     | User-specified precision, exact | Up to 131072 digits before the decimal point |
|                        |              |                                 | up to 16383 digits after the decimal point   |
| real                   | 4 bytes      | Variable-precision inexact      | 6 decimal digits precision                   |
| double precision       | 8 bytes      | Variable-precision inexact      | 15 decimal digits precision                  |

Division
When you divide by integers, the result is truncated to return an integer.
When you divide an integer by a decimal/numeric value, a decimal/numeric value is returned.

Range: min and max
SELECT min(question_pct)
FROM stackoverflow;

SELECT max(question_pct)
FROM stackoverflow;

Average or Mean
SELECT avg(question_pct)
FROM stackoverflow;


Variance
Definition: A statistical measure of the amount of dispersion in a set of values.
- It tells you how far spread values are from their mean.
- Larger values indicate greater dispersion.
- Variance can be computed for a sample of data or for the population.
- Sample Variance divides by the number of values minus 1.

Population Variance
-------------------
SELECT VAR_POP(question_pct)
FROM stackoverflow;


Sample Variance
---------------
SELECT VAR_SAMP(question_pct)
FROM stackoverflow;

SELECT VARIANCE(question_pct)
FROM stackoverflow;


Standard Deviation
- Square root of the variance

Sample Standard Deviation
-------------------------
SELECT stddev_samp(question_pct)
FROM stackoverflow;

SELECT stddev(question_pct)
FROM stackoverflow;


Population Standard Deviation
-----------------------------
SELECT stddev_pop(question_pct)
FROM stackoverflow;


Round
SELECT round(42.1256,2);
Syntax round(COLUMN/Numeric Value, # of decimal places)


Summarize by group
-- Summarize by group with GROUP BY
SELECT tag
    ,min(question_pct)
    ,avg(question_pct)
    ,max(question_pct)
FROM stackoverflow
GROUP BY tag;


Exploring Distributions
Understanding the distribution of the data is crucial to finding outliers and anamolies

TRUNCATE
The TRUNCATE function accepts two arguements
- A numeric/decimal value
- A n precision

Examples
--------
TRUNC(42.1256, 2) -> 42.12
TRUNC(12345, -3) -> 12000


Truncating and grouping
What if you want to group numbers by the tens place?

SELECT trunc(unanswered_count, -1) AS trunc_un
      ,COUNT(*)
FROM stackoverflow
WHERE tag='amazon-ebs'
GROUP BY trunc_ua
ORDER BY trunc_ua;

| trunc_ua | count |
|----------|-------|
|       30 |    74 |
|       40 |   194 |
|       50 |   480 |


Generate Series
Allows you to create bins or additional groupings (5, 20, etc.)
-The end value is INCLUSIVE

SELECT generate_series(start, end, step);

Create bins: query
WITH bins AS (
        SELECT GENERATE_SERIES(30, 60, 5) AS lower
              ,GENERATE_SERIES(35, 65, 5) AS upper
), 
ebs AS (SELECT unanswered_count
        FROM stackoverflow
        WHERE tag = 'amazon-ebs'
)
SELECT lower
      ,upper
      ,COUNT(unanswered_count)
FROM bins
LEFT JOIN ebs ON unanswered_count >= lower
             AND unanswered_count < upper
GROUP BY lower, upper]
ORDER BY lower;


Correlation
Measures the relationship between two features
Correlation values can range from -1 to +1 where
-1 represents a strong negative linear relationship
+1 represents a strong positive linear relationship

Correlation Function
SELECT CORR(assets, equity)
FROM fortune500;


Median
The 50th percentile or midpoint in a sorted list of values

Percentile Function
PERCENTILE_DISC()
PERCENTILE_CONT()

SELECT PERCENTILE_DISC(percentile) WITHIN GROUP (ORDER BY column_name)
FROM table; -> Returns a value from column
-- percentile between 0 to 1

SELECT PERCENTILE_CONT(percentile) WITHIN GROUP (ORDER BY column_name)
FROM table; -> Returns an interpolated value: (m1 + m2) /2


Creating Temporary Tables
You need special permissions in a database to create or update tables
- Users have the ability to create temporary tables.
+ Temp table is viewable only to the user.
+ Available only for the duration of the session.

Syntax
Create Temp Table Syntax

CREATE TEMP TABLE new_tablename AS
SELECT column1, column2
FROM table;

Select Into Syntax
SELECT column1, column2
INTO TEMP TABLE new_tablename
FROM table;

-- Create a temp table with the top 10 fortune500 companies
CREATE TEMP TABLE top_companies AS
SELECT rank
      ,title
FROM fortune500
WHERE rank <= 10;


Insert into table
-- Add the top 20 companies to the table
INSERT INTO top_companies
SELECT rank
      ,title
FROM fortune500
WHERE rank BETWEEN 11 AND 20;


Delete (drop) table
DROP TABLE top_companies;
DROP TABLE IF EXISTS top_companies;;
*/

------------------------------ EXERCISES -----------------------------------------

-- 1. Division
-- Compute the average revenue per employee for Fortune 500 companies by sector.
SELECT sector
    ,avg(revenues/employees::numeric) AS avg_rev_employee
FROM fortune500
GROUP BY sector
-- Use the column alias to order the results
ORDER BY avg_rev_employee;


-- 2. Explore with division
-- Divide unanswered_count by question_count
SELECT unanswered_count/question_count::numeric AS computed_pct, 
       -- What are you comparing the above quantity to?
       unanswered_pct
  FROM stackoverflow
 -- Select rows where question_count is not 0
 WHERE question_count != 0
 LIMIT 10;


 -- 3. Summarize numeric columns
 -- Summarize the profit column in the fortune500 table using the functions you've learned
 SELECT MIN(profits)
        ,AVG(profits)
        ,MAX(profits)
        ,STDDEV(profits)
FROM fortune500;

-- Now repeat step 1, but summarize profits by sector.
 SELECT sector
       ,MIN(profits)
       ,AVG(profits)
       ,MAX(profits)
       ,STDDEV(profits)
FROM fortune500
GROUP BY sector
ORDER BY avg;


-- 4. Summarize group statistics
/* Sometimes you want to understand how a value varies across groups.
For example, how does the maximum value per group vary across groups?
One way to do this is to compute group values in a subquery, and the summarize
the results of a subquery.

Compute the summary statistics of each tag
*/

SELECT STDDEV(maxval)
      ,MIN(maxval)
      ,MAX(maxval)
      ,AVG(maxval)
FROM (SELECT MAX(question_count) AS maxval
      FROM stackoverflow
      GROUP BY tag) AS max_results;


-- 5. Truncate
-- Use Truncate to examime the distributions of attributes of the Fortune 500 companies.
-- Find companies with 100,000+ employees
SELECT TRUNC(employees, -5) AS employee_bin
      ,COUNT(*)
FROM fortune500
GROUP BY employee_bin
ORDER BY employee_bin;

-- Find companies with less than 100,000 employees 
SELECT TRUNC(employees, -4) AS employee_bin
      ,COUNT(*)
FROM fortune500
WHERE employees < 100000
GROUP BY employee_bin
ORDER BY employee_bin;


-- 6. Generate Series
-- Summarize the distribution of the number of questions with the tag "dropbox"

-- Select the min and max question count values
SELECT MIN(question_count)
      ,MAX(question_count)
FROM stackoverflow
WHERE tag = 'dropbox';

-- Use GENERATE_SERIES() to create bins of size 50 from 2200 to 3100
SELECT GENERATE_SERIES(2200,3500,50) AS lower
      ,GENERATE_SERIES(2250,3100,50) AS upper;

-- Put it all together
WITH bins AS (SELECT GENERATE_SERIES(2200,3050,50) AS lower
                    ,GENERATE_SERIES(2250,3100,50) AS upper),
dropbox AS (
      SELECT question_count
      FROM stackoverflow
      WHERE tag='dropbox'
)

SELECT lower
      ,upper
      ,COUNT(question_count)
FROM bins
LEFT JOIN dropbox ON question_count >= lower
                  AND question_count < upper
GROUP BY lower, upper
ORDER BY lower;


-- 7. Correlation
-- What's the relationship between a company's revenue and its other financial attributes?
SELECT CORR(revenues, profits) AS rev_profits
      ,CORR(revenues, assets) AS rev_assets
      ,CORR(revenues, equity) AS rev_equity
FROM fortune500;


-- 8. Mean and Median
-- What are the average and median assets of Fortune500 companies by sector?
SELECT sector
      ,AVG(assets) AS mean
      ,PERCENTILE_DISC(0.5) WITHIN GROUP (ORDER BY assets) AS median
FROM fortune500
ORDER BY mean;


-- 9. Create a temp table
-- Find the Fortune 500 companies that have profits
-- in the top 20% for their sector.

DROP TABLE IF EXISTS profit80;

CREATE TEMP TABLE profit80 AS
      SELECT sector
            ,PERCENTILE_DISC(.8) WITHIN GROUP (ORDER BY profits) AS pct 80
      FROM fortune500
      GROUP BY sector;

SELECT *
FROM profit80;

-- Find all companies that have profits greater than the 80th percentile in their sector

SELECT title
      ,A.sector
      ,profits
      ,profits/pct80 AS ratio
FROM fortune500 AS A
LEFT JOIN profit80 AS B ON A.sector = B.sector
WHERE profits > pct80;


-- 10. Create a temp table to simplify a query
-- Find the first time a tag was used in stackoverflow
DROP TABLE IF EXISTS startdates;

CREATE TEMP TABLE startdates AS
SELECT tag
      ,MIN(date) AS mindate
FROM stackoverflow
GROUP BY tag;

SELECT so_min.tag,
      mindate,
      -- Select question count on the min and max days
      so_min.question_count AS min_date_question_count,
      so_max.question_count AS max_date_question_count,
      -- Compute the change in question count (max - min)
      so_max.question_count - so_min.question_count AS change,
FROM startdates
      INNER JOIN stackoverflow AS so_min
            ON startdates.tag = so_min.tag
            AND startdates.mindate = so_min.date
      INNER JOIN stackoverflow AS so_max
            ON startdates.tag = so_max.tag
            AND so_max.date = '2018-09-25';


-- 10. Create a temp table to simplify a query
-- Find the first time a tag was used in stackoverflow
DROP TABLE IF EXISTS correlations;

CREATE TEMP TABLE correlations AS
SELECT 'profits'::varchar AS measure,


-- 11. Insert into a temp table
DROP TABLE IF EXISTS correlations;

CREATE TEMP TABLE correlations AS
-- Query below creates a single row
SELECT 'profits'::varchar AS measure,
      CORR(profits, profits) AS profits,
      CORR(profits, profits_change) AS profits_change,
      CORR(profits, revenues_change) AS revenues_change,
FROM fortune500;

-- Add a row for profits_change
INSERT INTO correlations
SELECT 'profits_change'::varchar AS measure,
      CORR(profits_change, profits) AS profits,
      CORR(profits_change, profits_change) AS profits_change,
      CORR(profits_change, revenues_change) AS revenues_change
FROM fortune500;

-- Add a row for revenues_change
INSERT INTO correlations
SELECT 'revenues_change'::varchar AS measure,
      CORR(revenues_change, profits) AS profits,
      CORR(revenues_change, profits_change) AS profits_change,
      CORR(revenues_change, revenues_change) AS revenues_change
FROM fortune500;

-- Select each column, rounding the correlations
SELECT measure,
      ROUND(profits::numeric,2) AS profits,
      ROUND(profits_change::numeric,2) AS profits_change,
      ROUND(revenues_change::numeric,2) AS revenues_change
FROM correlations;