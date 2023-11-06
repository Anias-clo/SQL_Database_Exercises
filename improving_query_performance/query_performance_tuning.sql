/*
Chapter 4. Query Performance Tuning
Students are introduced to how STATISTICS TIME, STATISTICS IO, indexes,
and executions plans can be used in SQL Server to help analyze and tune
query performance.

-------------------------------- NOTES ------------------------------------------

Time Statistics

$ SQL Server Execution Times
- CPU time: time taken by server processors to process the query
- Elapsed time: total duration of the query, execution -> results

SET STATISTICS TIME ON
...
SQL QUERY
...

To turn off STATISTICS TIME run the command
SET STATISTICS TIME OFF

$ Elapsed time vs. CPU time
Elapsed time
- May be variable when analyzing query time statistics
- Time best time statistics measure for the fastest running query

CPU time
- Little variation when analyzing query time statistics
- May not be a useful measure if server processors are running in parallel


$ Page read statistics

Table data pages
- All data, in memory or on disk, is stored in 8 kilobyte size "pages"
- One page can store many rows or one value could span multiple pages
- A page can only belong to one table
- SQL Server works with pages cached in memory
- If a page is not cached in memory it is read from disk and cached in memory


STATISTICS IO in SSMS
SET STATISTICS IO ON


Logical reads
- Number of 8 kilobyte pages read per table
- More pages = Slower query performance


Indexes
What is an index?
- Structure to improve speed of accessing data from a table
- Used to locate data quickly without having to scan the entire table
- Useful for improving performance of queries with filter conditions
- Applied to table columns and can be added at anytime
- Typically added by a database administrator
- Two types of indexes are Clustered and Non-clustered Indexes

$ Clustered and Non-clustered indexes
Clustered Index
- Analogy: Dictionary
- Table data pages are ordered by the column(s) with the index
- Only one clustered index allowed per table
- Speeds up search operations

Non-clustered Index
- Analogy: Textbook with an index at the back
- Structure contains an ordered layer of index pointers to unordered table data pages
- A table can have more than one non-clustered index
- Improves insert and update operations


$ Clustered index: B-tree structure

ROOT NODE:
    A G O W

BRANCH NODES:
    A B E F     G H J K     O P S T

PAGE NODES:
        Page 1          Page 2          Page 3
    Index Column    Index Column    Index Column
    A | ...        E | ...          I | ...
    B | ...        F | ...          J | ...

- PAGE NODES contain the 8 kilobyte pages where the data is stored


$ Example of Clustered index using the Customers table

SELECT *
FROM Customers
WHERE CustomerID = "PARIS"

ROOT NODE:  OLDWO WOLZA

BRANCH NODES:
    ALFKI BONAP DRACD FISSA     OCEAN OLDWO QUICK WOLZA

PAGE NODES:
    Page 1                      Page 2
CustomerID | ...            CustomerID | ...
ALFKI | ...                 OCEAN | ...
ANATR | ...                 PARIS | ...


$ Clustered index: Example

SET STATISTICS IO ON

SELECT *
FROM PlayerStats
WHERE Team = 'OKC'

PlayerStats table with no index
    Table 'PlayerStats'. ..., logical reads 12, ...

PlayerStats table with clustered index on Team
    Table 'PlayerStats'. ..., logical reads 2, ...

- The fewer logical reads a query performs, the faster it runs.


Execution Plans
- When a query is submitted to a database engine, after passing syntax, table, and data checks
it is passed to an Optimization Phase.

$ Optimization Phase
- Evaluates several execution plans to determine which one will return results at the lowest cost
- Costs include: Processor Usage, memory usage, and data pages read
- The Optimization Phase selects the best execution plan and passes it to the Execution Engine
  to process the query

$ Information from execution plans
- Interpreting Execution plans help us determine
    1. If indexes were used
    2. The types of joins used
    Location and relative costs of:
    3. If and where filter conditions
    4. Sorting
    5. Aggregations

!!! Any issue with a query should be immediately apparent in an execution plan
    which makes it an excellent tool for troubleshooting query performance

$ Estimated execution plan in SSMS
- To display an execution plan in SSMS click the icon with 3 boxes and directional arrows
  or press (Ctrl + L)
- The execution plan is displayed at the bottom of the screen

$ Operator statistics
- Each icon in an execution paln represents an operator that is used to perform a specific task
- Hovering over an operator provides detailed statistics of the task used in the query

$ Reading execution plans
- Read from right to left, as indicated by the direction of the arrows between operators
- The width of each arrow reflects how much data was passed from one operator to the next

$ Index example
- If a table has a clustered index, it will display in the execution plan

$ Sort operator example: UNION vs. UNION ALL
- UNION performs a DISTINCT SORT while UNION ALL does not
- Internal sorting is often required when using an operator in a query that checks for
  and removes duplicate rows

$ The same execution plan?
- Different queries can return the same execution plan


Query performance tuning: Final Notes
- In the real world, it's not uncommon to work with large complex queries that run for ten
  minutes, one hour or more
- Query statistics, indexes, and execution plans are all advanced topics - Continue learning
- Don't rely on one tool or command for query performance tuning. They can often complement one another.
*/

------------------------------ EXERCISES -----------------------------------------

-- 1. STATISTICS TIME in queries
SET STATISTICS TIME ON -- Turn the time command on

-- Query 1
SELECT * 
FROM Teams
-- Sub-query 1
WHERE City IN -- Sub-query filter operator
      (SELECT CityName 
       FROM Cities) -- Table from Earthquakes database
-- Sub-query 2
   AND City IN -- Sub-query filter operator
	   (SELECT CityName 
	    FROM Cities
		WHERE CountryCode IN ('US','CA'))
-- Sub-query 3
    AND City IN -- Sub-query filter operator
        (SELECT CityName 
         FROM Cities
	     WHERE Pop2017 >2000000);

-- Query 2
SELECT * 
FROM Teams AS t
WHERE EXISTS -- Sub-query filter operator
	(SELECT 1 
     FROM Cities AS c
     WHERE t.City = c.CityName -- Columns being compared
        AND c.CountryCode IN ('US','CA')
          AND c.Pop2017 > 2000000);

SET STATISTICS TIME OFF -- Turn the time command off


-- 2. STATISTICS IO: Example 1
SET STATISTICS IO ON -- Turn the IO command on

-- Example 1
SELECT CustomerID,
       CompanyName,
       (SELECT COUNT(*) 
	    FROM Orders AS o -- Add table
		WHERE c.CustomerID = o.CustomerID) CountOrders
FROM Customers AS c
WHERE CustomerID IN -- Add filter operator
       (SELECT CustomerID 
	    FROM Orders 
		WHERE ShipCity IN
            ('Berlin','Bern','Bruxelles','Helsinki',
			'Lisboa','Madrid','Paris','London'));

-- Example 2
SELECT c.CustomerID,
       c.CompanyName,
       COUNT(o.CustomerID)
FROM Customers AS c
INNER JOIN Orders AS o -- Join operator
    ON c.CustomerID = o.CustomerID
WHERE o.ShipCity IN -- Shipping destination column
     ('Berlin','Bern','Bruxelles','Helsinki',
	 'Lisboa','Madrid','Paris','London')
GROUP BY c.CustomerID,
         c.CompanyName;

SET STATISTICS IO OFF -- Turn the IO command off


-- 3. Clustered index
-- Query 1
SELECT *
FROM Cities
WHERE CountryCode = 'RU' -- Russia's Country code
		OR CountryCode = 'CN' -- China's Country code

-- Query 2
SELECT *
FROM Cities
WHERE CountryCode IN ('JM','NZ') -- Jamiaca and New Zeland Country codes
-- Query 2 performs faster because the CountryCode column is indexed


-- 4. Sort operator in execution plans
SELECT CityName AS NearCityName,
	   CountryCode
FROM Cities

UNION -- Append queries

SELECT Capital AS NearCityName,
       Code2 AS CountryCode
FROM Nations;