/*
Chapter 1 Introduction, Review and The Order of Things

Learn SQL code formatting, commenting, and aliasing together to make queries
easy to read and understand. Learn the query processing order in the database
versus the order of the SQL syntax in a query.


SQL is case insensitive. Be consistent.

    - Use UPPER CASE for all SQL syntax.
    - Create a new line for each major processing syntax: SELECT, FROM, WHERE
    - Indent Code
        - Sub-queries
        - ON statements
        - AND / OR conditions
    - Complete the query with a semi-colon (;)
    - Alias where required, using AS


Commenting Blocks

    Use /* * / to add a comment block to a SQL query.


Commenting Lines

    Use -- to comment out a single line of code or text.
        - inline comments


Query Order and Processing Order

    Syntax Order
    1. SELECT
    2. FROM
    3. WHERE
    4. ORDER BY

    Processing Order
    1. FROM
    2. WHERE
    3. SELECT
    4. ORDER BY

    Logical Processing Order
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

------------------------------ EXERCISES -----------------------------------------
*/
-- 1. Formatting - Player BMI
SELECT PlayerName,
    Country,
    ROUND(Weight_kg / SQUARE(Height_cm/100),2) AS BMI
FROM Players
WHERE Country = 'USA'
    OR Country = 'Canada'
ORDER BY BMI;


-- 2. Commenting Player BMI
/*
Returns the Body Mass Index (BMI) for all North American players
from the 2017-2018 NBA season
*/

SELECT PlayerName, Country,
    ROUND(Weight_kg/SQUARE(Height_cm/100),2) BMI 
FROM Players 
WHERE Country = 'USA'
    OR Country = 'Canada';
-- ORDER BY BMI;


-- 3. Commenting - how many Kiwis in the NBA?
-- Your friend's query
-- First attempt, contains errors and inconsistent formatting
/*
select PlayerName, p.Country,sum(ps.TotalPoints) 
AS TotalPoints  
FROM PlayerStats ps inner join Players On ps.PlayerName = p.PlayerName
WHERE p.Country = 'New Zeeland'
Group 
by PlayerName, Country
order by Country;
*/

-- Your query
-- Second attempt - errors corrected and formatting fixed

SELECT p.PlayerName, p.Country,
		SUM(ps.TotalPoints) AS TotalPoints  
FROM PlayerStats ps 
INNER JOIN Players p
	ON ps.PlayerName = p.PlayerName
WHERE p.Country = 'New Zealand'
GROUP BY p.PlayerName, p.Country;


-- 4. Aliasing Team BMI
SELECT Team, 
   ROUND(AVG(BMI),2) AS AvgTeamBMI -- Alias the new column
FROM PlayerStats AS ps -- Alias PlayerStats table
INNER JOIN
		(SELECT PlayerName, Country,
			Weight_kg/SQUARE(Height_cm/100) BMI
		 FROM Players) AS p -- Alias the sub-query
             -- Alias the joining columns
	ON ps.PlayerName = p.PlayerName 
GROUP BY Team
HAVING AVG(BMI) >= 25;


-- 5. Syntax Order - New Zealand earthquakes
/*
Returns earthquakes in New Zealand with a magnitude of 7.5 or more
*/
SELECT Date, Place, NearestPop, Magnitude
FROM Earthquakes
WHERE Country = 'NZ'
	AND Magnitude >= 7.5
ORDER BY Magnitude DESC;


-- 6. Syntax Order - Japan earthquakes
-- Your query
SELECT Date,
    Place,
    NearestPop,
    Magnitude
FROM Earthquakes
WHERE Country = 'JP'
    AND Magnitude >= 8
ORDER BY Magnitude DESC;


-- 7. Syntax Order - very large earthquakes
