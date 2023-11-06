/*
Chapter 1. 
Start exploring a database by identifying the tables and the foreign keys that
link them. Look for missing values, count the number of observations, and join
tables to understand how they're related. Learn about coalescing and casting data along the way. 


Database Client
- A database client is a program used to connect to, and work with a database.

Select a few rows

SELECT *
FROM table_name
LIMIT 5;

A few reminders

| Code                        | Note                                |
|-----------------------------|-------------------------------------|
| NULL                        | Missing                             |
| IS NULL, IS NOT NULL        | Don't use = NULL                    |
| count(*)                    | Number of rows                      |
| count(DISTINCT column_name) | Number of different non-NULL values |
| SELECT DISTINCT column_name | Distinct values, including NULL     |


The keys to the database
- The second stage of exploring a database is understanding the formal relationships
  between tables.

$ Foreign Keys
- Foreign keys are the formal way that database tables are linked together.
- A foreign key is a column that references a single, specific row in the database.
- The foreign key references a unique ID, called a primary key column in the referenced table.
  - Primary keys contain unique, non-NULL values
- Foreign key values are restricted to values in referenced column (Primary Key) or NULL.

$ Coalesce function
- Takes two or more values or columns as arguments.

COALESCE(value_1, value_2 [, ...])

- Operates row by row
- Returns the first non-NULL value in each row, checking the columns in the order they're
  supplied to the function.
- Useful for specifying a default or backup values when selecting a column that might contain
  NULL values.


Example: COALESCE function

SELECT *
FROM prices

| column_1 | column_2 |
|----------|----------|
|          |    10    |
|          |          |
|    22    |          |
|     3    |     4    |

SELECT COALESCE(column_1, column_2)
FROM prices;

| coalesce |
|----------|
|    10    |
|          |
|    22    |
|     3    |


Column Types and Contraints

$ Column constraints
- Foreign Key: value that exists in the referenced column, or NULL
- Primary Key: unique, not NULL
- Unique: values must all be different except for NULL
- Not null: NULL not allowed- Must have a value
- Check constraints: conditions on the values
  - column_1 > 0
  - column A > column B


$ Data types
- Each column in a database can only store 1 data type
- The data type of a column is shown in entity relationship diagrams

Common
- Numeric
- Character
- Date/Time
- Boolean

Special
- Arrays
- Monetary
- Binary
- Geometric
- Network Address
- XML
- JSON

$ Casting with CAST()
- Values can be converted temporarily from one type to another
  through a process called casting.

Format
-- With the CAST function
SELECT CAST (value AS new_type);

Example
-- Cast 3.7 as an integer
SELECT CAST(3.7 AS INT)

>>> 4

$ Casting with ::
- Known as double colon notation
- More concise way to CAST a column from one data type to another

Format
-- With :: notation
SELECT value::new_type;

Example
-- Cast 3.7 as an integer
SELECT 3.7::INTEGER;


*/

------------------------------ EXERCISES -----------------------------------------

-- 1. Join tables
SELECT company.name
-- Table(s) to select from
  FROM company
       INNER JOIN fortune500
       ON company.ticker=fortune500.ticker;


-- 2. Read an entity relationship diagram
-- Count the number of tags with each type
SELECT type, COUNT(type) AS count
  FROM tag_type
 -- To get the count for each type, what do you need to do?
GROUP BY type
 -- Order the results with the most common
 -- tag types listed first
 ORDER BY count DESC;

 -- Select the 3 columns desired
SELECT name, tag_type.tag, tag_type.type
  FROM company
  	   -- Join to the tag_company table
       INNER JOIN tag_company 
       ON company.id = tag_company.company_id
       -- Join to the tag_type table
       INNER JOIN tag_type
       ON tag_company.tag = tag_type.tag
  -- Filter to most common type
  WHERE type='cloud';


-- 3. COALESCE
-- Use coalesce
SELECT COALESCE(industry, sector, 'Unknown') AS industry2,
       -- Don't forget to count!
       COUNT(*) AS counts
  FROM fortune500
-- Group by what? (What are you counting by?)
 GROUP BY COALESCE(industry, sector, 'Unknown')
-- Order results to see most common first
 ORDER BY counts DESC
-- Limit results to get just the one value you want
 LIMIT 1;


-- 4. COALESCE with a self-join
SELECT company_original.name, title, rank
  -- Start with original company information
  FROM company AS company_original
       -- Join to another copy of company with parent
       -- company information
	   LEFT JOIN company AS company_parent
       ON company_original.parent_id = company_parent.id 
       -- Join to fortune500, only keep rows that match
       INNER JOIN fortune500 
       -- Use parent ticker if there is one, 
       -- otherwise original ticker
       ON coalesce(company_parent.ticker, 
                   company_original.ticker) = 
             fortune500.ticker
 -- For clarity, order by rank
 ORDER BY rank;


-- 5. Effects of casting
-- Select the original value
SELECT profits_change, 
	   -- Cast profits_change
       CAST(profits_change AS INTEGER) AS profits_change_int
  FROM fortune500;

-- Divide 10 by 3
SELECT 10/3, 
       -- Cast 10 as numeric and divide by 3
       10::numeric/3;

SELECT '3.2'::NUMERIC,
       '-123'::NUMERIC,
       '1e3'::NUMERIC,
       '1e-3'::NUMERIC,
       '02314'::NUMERIC,
       '0002'::NUMERIC;


-- 6. Summarize the distribution of numeric values
-- Select the count of each value of revenues_change
SELECT revenues_change, count(*)
  FROM fortune500
 GROUP BY revenues_change
 -- order by the values of revenues_change
 ORDER BY revenues_change;

-- Select the count of each revenues_change integer value
SELECT revenues_change::INTEGER, COUNT(*)
  FROM fortune500
 GROUP BY revenues_change::INTEGER
 -- order by the values of revenues_change
 ORDER BY revenues_change;

 -- Count rows of companies that increased revenue year over year
SELECT COUNT(*)
  FROM fortune500
 -- Where...
 WHERE revenues_change > 0;