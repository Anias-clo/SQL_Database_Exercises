
/*
Chapter 2

Filtering and Data Interrogation

This chapter introduces filtering with WHERE and HAVING
and some best practices for how (and how not) to use these keywords.
Next, it explains the methods used to interrogate data and the effects
these may have on performance. Finally, the chapter goes over the roles of
DISTINCT() and UNION in removing duplicates and their potential
effects on performance. 


-------------------------------- NOTES ------------------------------------------

How WHERE works
     - WHERE is used in a query to filter out rows from a data source
       specified in the FROM statement.
     - Only the rows that meet the criteria of the WHERE statement are
       extracted from the data source.


WHERE processing order
     - WHERE is processed before SELECT. When aliasing columns, the WHERE
       statement does not recognized the aliased column.


Using a sub-query
     - Aliased columns are recognized by the WHERE statement if
       it is contained in a sub-query. The sub-query creates the aliased
       column first. When the outer query accesses the new data source,
       the new column is recognized in the WHERE statement.


Calculations on columns
     - Calculations can be used as a filter in the WHERE statement. The WHERE statement
       evaluates the calculated filter against every row. The more data, the more processing
       time is required to run the query.
     - Avoid complex calculations in the WHERE statement.
     - If possible, avoid using functions in the WHERE statement.


Best Practice: Make your query as simple as possible, while still getting
               what you want.


Filtering with HAVING

     HAVING processing order
     1. FROM
     2. WHERE
     3. HAVING
     4. SELECT

     - The WHERE statement is used to filter individual rows. The HAVING
       statement is used to filter groups of rows.

Row filtering with HAVING
     - WHERE is more efficient to filter individual or ungrouped rows
       because filtering takes place before grouping or summing.


Aggregating by group
     - HAVING is generally used to apply a numeric aggregate filter on grouped rows.


Interrogation after SELECT
Processing order after SELECT
     1. FROM
     2. ON
     3. JOIN
     4. WHERE
     5. GROUP BY
     6. HAVING
     7. SELECT
     8. DISTINCT
     9. ORDER BY
     10. TOP


All in a JOIN
- SELECT * in joins returns duplicates of joining columns.
- SELECT * can increase the processing time of a query.


Rows at the TOP and Percentage at the TOP
- TOP is used in the SELECT statement to limit the number of rows returned.
- If used in conjunction with PERCENT, a portion of the rows will be returned.


There is no top or bottom
- TOP returns the top rows of a query. To return the bottom rows of a query, use the ORDER BY
  statement with DESC
- ORDER BY slows performance of a query. If a data set requires sorting before analysis use Python.


Managing Duplicates
- Duplicate rows can be the result of a poorly designed database, query, or both.
- Duplicate rows can be the result of appending one table to another


Removing duplicates with DISTINCT()
SELECT DISTINCT(Name)
FROM Employees


Remove duplicates with UNION
- The UNION append keyword returns unique rows.


To keep duplicates use UNION ALL

*/
------------------------------ EXERCISES -----------------------------------------


-- 1. Column does not exist
-- First query
SELECT PlayerName, 
    Team, 
    Position,
    (DRebound+ORebound)/CAST(GamesPlayed AS numeric) AS AvgRebounds
FROM PlayerStats
-- This query will raise an error because the WHERE statement
-- does not recognize the aliased column.
WHERE AvgRebounds >= 12;


-- Second query
-- Return NBA players who have an average total rebound greater
-- than or equal to 12.

-- Add the new column to the select statement
SELECT PlayerName, 
       Team, 
       Position, 
       AvgRebounds -- Add the new column
FROM
     -- Sub-query starts here                             
	(SELECT 
      PlayerName, 
      Team, 
      Position,
      -- Calculate average total rebounds
     (ORebound+DRebound)/CAST(GamesPlayed AS numeric) AS AvgRebounds
	 FROM PlayerStats) tr
WHERE AvgRebounds >= 12; -- Filter records


-- 2. Functions in WHERE
-- Return the data for all NBA players who went to college in Louisiana
SELECT PlayerName, 
      Country,
      College, 
      DraftYear, 
      DraftNumber 
FROM Players 
WHERE College LIKE 'Louisiana%';


-- 3. Row filtering with HAVING
SELECT Country, COUNT(*) CountOfPlayers 
FROM Players
GROUP BY Country
HAVING Country 
    IN ('Argentina','Brazil','Dominican Republic'
        ,'Puerto Rico');

-- Rewrite the query using a WHERE statement
SELECT Country, COUNT(*) CountOfPlayers
FROM Players
-- Add the filter condition
WHERE Country
-- Fill in the missing countries
	IN ('Brazil','Argentina','Dominican Republic'
        ,'Puerto Rico')
GROUP BY Country;


-- 4. Filtering with WHERE and HAVING
SELECT Team, 
	SUM(TotalPoints) AS TotalPFPoints
FROM PlayerStats
-- Filter for only rows with power forwards
WHERE Position = 'PF'
GROUP BY Team
-- Filter for total points greater than 3000
HAVING SUM(TotalPoints) > 3000;


-- 5. Removing Duplicates with DISTINCT()
SELECT Team, 
    SUM(TotalPoints) AS TotalCPoints
FROM PlayerStats
WHERE Position = 'C'
GROUP BY Team
HAVING SUM(TotalPoints) > 2500;


SELECT DISTINCT(NearestPop),-- Remove duplicate city
		Country
FROM Earthquakes
WHERE magnitude >= 8 -- Add filter condition 
	AND NearestPop IS NOT NULL
ORDER BY NearestPop;


SELECT NearestPop, 
       Country, 
       COUNT(NearestPop) NumEarthquakes -- Number of cities
FROM Earthquakes
WHERE Magnitude >= 8
	AND Country IS NOT NULL
GROUP BY NearestPop, Country -- Group columns
ORDER BY NumEarthquakes DESC;


-- UNION and UNION ALL
SELECT CityName AS NearCityName, -- City name column
	   CountryCode
FROM Cities

UNION -- Append queries

SELECT Capital AS NearCityName, -- Nation capital column
       Code2 AS CountryCode
FROM Nations;


SELECT CityName AS NearCityName,
	   CountryCode
FROM Cities

UNION ALL -- Append queries

SELECT Capital AS NearCityName,
       Code2 AS CountryCode  -- Country code column
FROM Nations;




