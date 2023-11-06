/*
Chapter 3 Sub-queries

-------------------------------- NOTES ------------------------------------------
A sub-query has its own SELECT statement
- Processes before outer queries
- Used as an input to the outer query
- Used to create a new column

Types of sub-queries

Uncorrelated sub-query
- Sub-query does not contain a reference to the outer query
- Sub-query can run independently of the outer query
- Used with WHERE and FROM

Correlated sub-query
- Sub-query contains a reference to the outer query
- Sub-query cannot run independently of the outer query


Presence and Absence
INTERSECT
- Returns data present in both tables

EXCEPT
- Returns data present only in the primary table


INTERSECT and EXCEPT
$ Advantages
- Great for data interrogation
- Remove duplicates from the returned results

$ Disadvantages
- The number and order of columns in the SELECT statement must be the same
  between queries.


Alternative Methods 1
$ EXISTS vs. IN
- EXISTS will stop searching the sub-query when the condition is TRUE
- IN collects all the results from a sub-query before passing to the outer query
- Consider using EXISTS instead of IN with a sub-query


$NOT IN and NULLs
- If a sub-query contains NULL values when using NOT IN, the query will return NULL
- The sub-query must have a WHERE column_name IS NOT NULL, if the column contains NULL values


INNER JOIN and exclusive LEFT OUTER JOIN
- INNER JOIN: checks for presence
- Exclusive LEFT OUTER JOIN: checks for absence

Advantage
- Results can contain any column, from all joined queries, in any order

Disadvantage
- Requirement to add the IS NULL WHERE filter condition with the exclusive LEFT OUTER JOIN


*/
------------------------------ EXERCISES -----------------------------------------

-- 1. Uncorrelated sub-query
SELECT UNStatisticalRegion,
       CountryName 
FROM Nations
WHERE Code2 -- Country code for outer query 
         IN (SELECT Country -- Country code for sub-query
             FROM Earthquakes
             WHERE depth >= 400 ) -- Depth filter
ORDER BY UNStatisticalRegion;


SELECT UNStatisticalRegion,
       CountryName,
       Code2
FROM Nations
WHERE Code2 -- Country code for outer query 
         IN (SELECT Country -- Country code for sub-query
             FROM Earthquakes
             WHERE Earthquakes.Country = Nations.Code2
             AND depth >= 400) -- Depth filter
ORDER BY UNStatisticalRegion;


-- 2. Correlated Sub-query
SELECT UNContinentRegion,
       CountryName, 
        (SELECT AVG(magnitude) -- Add average magnitude
        FROM Earthquakes e 
         	  -- Add country code reference
        WHERE n.Code2 = e.Country) AS AverageMagnitude 
FROM Nations n
ORDER BY UNContinentRegion DESC, 
         AverageMagnitude DESC;


-- 3. Sub-query vs INNER JOIN
SELECT
	n.CountryName,
	 (SELECT MAX(c.Pop2017) -- Add 2017 population column
	 FROM Cities AS c 
                       -- Outer query country code column
	 WHERE c.CountryCode = n.Code2) AS BiggestCity
FROM Nations AS n; -- Outer query table


SELECT n.CountryName, 
       c.BiggestCity 
FROM Nations AS n
INNER JOIN -- Join the Nations table and sub-query
    (SELECT CountryCode, 
     MAX(Pop2017) AS BiggestCity 
     FROM Cities
     GROUP BY CountryCode) AS c
ON n.Code2 = c.CountryCode; -- Add the joining columns


-- 4. INTERSECT
SELECT Capital
FROM Nations -- Table with capital cities

INTERSECT -- Add the operator to compare the two queries

SELECT NearestPop -- Add the city name column
FROM Earthquakes;


-- 5. EXCEPT
SELECT Code2 -- Add the country code column
FROM Nations

EXCEPT -- Add the operator to compare the two queries

SELECT Country 
FROM Earthquakes; -- Table with country codes


-- 6. Interrogating with INTERSECT
SELECT CountryName 
FROM Nations -- Table from Earthquakes database

INTERSECT -- Operator for the intersect between tables

SELECT Country
FROM Players; -- Table from NBA Season 2017-2018 database


-- 7. IN and EXISTS
-- First attempt
SELECT CountryName,
        Pop2017, -- 2017 country population
        Capital, -- Capital city	   
        WorldBankRegion
FROM Nations
WHERE Capital IN -- Add the operator to compare queries
        (SELECT NearestPop
        FROM Earthquakes);

-- Second attempt
SELECT CountryName,   
	   Capital,
       Pop2016, -- 2016 country population
       WorldBankRegion
FROM Nations AS n
WHERE EXISTS -- Add the operator to compare queries
	  (SELECT 1
	   FROM Earthquakes AS e
	   WHERE n.Capital = e.NearestPop); -- Columns being compared


-- 8. NOT IN and NOT EXISTS
SELECT WorldBankRegion,
       CountryName
FROM Nations
WHERE Code2 NOT IN -- Add the operator to compare queries
	(SELECT CountryCode -- Country code column
	 FROM Cities);

SELECT WorldBankRegion,
       CountryName,
	   Code2,
       Capital, -- Country capital column
	   Pop2017
FROM Nations AS n
WHERE NOT EXISTS -- Add the operator to compare queries
	(SELECT 1
	 FROM Cities AS c
	 WHERE n.Code2 = c.CountryCode); -- Columns being compared


-- 9. NOT IN with IS NOT NULL
SELECT WorldBankRegion,
       CountryName,
       Capital
FROM Nations
WHERE Capital NOT IN
	(SELECT NearestPop
     FROM Earthquakes
     WHERE NearestPop IS NOT NULL); -- filter condition


-- 10. INNER JOIN
-- Initial query
SELECT TeamName,
       TeamCode,
	   City
FROM Teams AS t -- Add table
WHERE EXISTS -- Operator to compare queries
      (SELECT 1
	  FROM Earthquakes AS e -- Add table
	  WHERE t.City = e.NearestPop);


-- Second query
SELECT t.TeamName,
       t.TeamCode,
	   t.City,
	   e.Date,
	   e.place, -- Place description
	   e.Country -- Country code
FROM Teams AS t
INNER JOIN Earthquakes AS e -- Operator to compare tables
	  ON t.City = e.NearestPop


-- 11. Exclusive LEFT OUTER JOIN
-- First attempt
SELECT c.CustomerID,
       c.CompanyName,
	   c.ContactName,
	   c.ContactTitle,
	   c.Phone 
FROM Customers c
LEFT OUTER JOIN Orders o -- Joining operator
	ON c.CustomerID = o.CustomerID -- Joining columns
WHERE c.Country = 'France';

-- Second attempt
SELECT c.CustomerID,
       c.CompanyName,
	   c.ContactName,
	   c.ContactTitle,
	   c.Phone 
FROM Customers c
LEFT OUTER JOIN Orders o
	ON c.CustomerID = o.CustomerID
WHERE c.Country = 'France'
	AND o.CustomerID IS NULL; -- Filter condition