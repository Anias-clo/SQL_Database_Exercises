/*
Chapter 3. Exploring Categorical Data and Unstructured Text

Text, or character, data can get messy, but you'll learn how to deal with inconsistencies
in case, spacing, and delimiters. Learn how to use a temporary table to recode messy categorical
data to standardized values you can count and aggregate. Extract new variables form unstructured
text as you explore help requests submitted to the city of Evanston, IL.


$ Character data types and common issues

PostgreSQL character types

character(n) or char(n)
- fixed length, n, where in is the maximum number of characters
- characters that are less than n are filled with trailing spaces.
  these spaces are ignored in comparisons, ex. 'a  ' 'a'='a'

charcter varying(n) or varchar(n)
- variable length up to a maxiumum of n

text or varchar
- store strings of unlimited length


Types of text data

Categorical variables are short strings of text with values that are repeated
across multiple rows.
- Finite set of values

| Category Examples | Category Variables                |
|-------------------|-----------------------------------|
| Weekdays          | MON, TUE, WED THU, FRI, SAT, SUN  |
| Colors            | Blue, red, green, yellow, orange  |
| Tesla's           | Model 3, Model Y, Model X, Model S|

Unstructured text
- Textual data that does not adhere to a specific format or organization.
- Examples of unstructured text are responses to open-ended questions, product reviews,
  email, social media posts, articles, blogs, chat logs, and documents written in free form.
- It contains sentences, paragraphs, irregular grammar or syntax.
- Lacks a standardized representation.


Grouping and counting
SELECT category, -- Categorical variable
    COUNT(*) -- Counts for each category
FROM product -- table
GROUP BY category -- Categorical variable
ORDER BY category; -- Order by categorical variable

- Ordering grouped categories helps us determine if there are duplicates or
  other errors in the data.

Alphabetical order
ORDER BY
' ' < 'A' < 'a'

Common issues
Case matters
'apple' != 'Apple'

Spaces count
' apple' != 'apple
'' != '             '

Empty strings are not null
' ' != NULL

Punctuation differences
'to-do' != 'to--do'


$ Cases and Spaces
A common way to handle inconsistencies in strings/text is to use the LOWER or UPPER functions
- LOWER() converts all characters in a string to lowercase
- UPPER() converts all characters in a string to uppercase
- Using these functions makes comparisons case-insensitive.

The LIKE operator matches strings that are similar to the provided argument.

SELECT *
FROM fruit
WHERE fav_fruit LIKE '%apple%';

The query above will return fruits that contain the string 'apple'.
- This includes any spaces, characters, or numbers before and after the string 'apple'

SELECT *
FROM fruit
-- ILIKE for case insensitive
WHERE fav_fruit ILIKE '%apple%';

- The query above returns fruits that contain 'apple' regardless of upper OR lowercasing
- ILIKE queries take longer to run than LIKE queries
- Doublecheck the returned data when using the % wildcard.


$ Trimming spaces
TRIM removes spaces before and after a string
- TRIM or BTRIM removes spaces from both ends of a string
- RTRIM removes spaces from the right end of a string
- LTRIM removes spaces from the left end of a string

The TRIM function only removes white spaces characters.


$ Trimming other values
- I'm using the trim function to remove characters provided in the second argument.
SELECT trim('Wow!', '!'); -> Wow
SELECT trim('Wow!', '!wW'); -> o

$ Combining functions
SELECT TRIM(LOWER('Wow!'), '!w');

$ Splitting and Concatenating text

Substring
left() -- selects characters starting from the left of the string
right() - selects characters starting from the right of the string

SELECT left('apple', 2),
       right('apple',2)
>>> ap | le

Selecting characters from the middle of a string
Syntax -> SELECT substring(string FROM start FOR length);
          SELECT substring(string,start position, end position)

SELECT substring('apple' FROM 2 FOR 3),
    substring('apple', 2, 3);
>>> pple | pple


How to split string based on a delimiter
def: a characters, such as a comma, that separates strings of text.
- The delimiter can be a single character, such as a comma, or a string of characters.

split_part(string, delimiter, part[1 -> len(string)]);

SELECT split_part('This, sentence, is split into multiple parts', ',',3);
>>> is split into multiple parts

SELECT split_part('the moon the stars the planets the aliens', ' the ', 4)
>>> aliens

Concatenating text
- joins all strings that are passed as arguments
SELECT concat('e','ar','th'); > 'earth'
SELECT 'e' || 'ar' || 'th'; > 'earth
SELECT concat('e',NULL,'th'); > 'eth'
SELECT 'e' || NULL || 'th'; > 'eth'


$ Strategies for multiple transformations


*/

------------------------------ EXERCISES -----------------------------------------

-- 1. Count the categories
-- How many rows does each priority level have?
SELECT priority,
    COUNT(*)
FROM evanston311
GROUP BY priority;
-- LOW, MEDIUM, HIGH, NONE

-- Find values of zip that appear in at least 100 rows
-- Return the count of each zip that meets this criteria
SELECT zip,
    COUNT(*)
FROM evanston311
GROUP BY zip
HAVING COUNT(*) >= 100 ;

-- Find values of source that appear in at least 100 rows
-- Return the count of each source that meets this criteria
SELECT source,
    COUNT(*)
FROM evanston311
GROUP BY source
HAVING COUNT(*) >= 100;

-- Select the five most common values of street and the count of each
SELECT street,
    COUNT(*)
FROM evanston311
GROUP BY street
ORDER BY 2 DESC
LIMIT 5;


-- 2. Trimming
-- Trim digits 0-9, #, /, ., and spaces from the beginning and the end of street.
SELECT DISTINCT street,
    TRIM(street, '0123456789#/. ') AS cleaned_street
FROM evanston311
ORDER BY street;

-- In practice this method of removing street numbers would result in missing
-- street names/ incorrectly grouped street names ex. 15th street and 40th street.


-- 3. Exploring unstructured text
-- Count the number of services requests related to trash/garbage
SELECT COUNT(*)
FROM evanston311
WHERE description ILIKE '%trash%'
    OR description ILIKE '%garbage%';

-- Find all services categories related to Trash or Garbage
SELECT category
FROM evanston311
WHERE category LIKE '%Trash%'
    OR category LIKE '%Garbage%';

-- Find all service calls that mention trash/garbage in the description but the
-- category does not. This helps us identify potentially misclassed services requests.
SELECT COUNT(*)
FROM evanston311
WHERE (description ILIKE '%Trash%'
    OR description ILIKE '%Garbage%'
)
AND category NOT LIKE '%Trash%'
AND category NOT LIKE '%Garbage%';

-- Find the top 10 categories for service requests with a description about trash that
-- don't have a trash related category
SELECT category,
    COUNT(*)
FROM evanston311
WHERE (description ILIKE '%trash%'
    OR description ILIKE '%garbage%')
    AND category NOT LIKE '%Trash%'
    AND category NOT LIKE '%Garbage%'
GROUP BY category
ORDER BY 2 DESC
LIMIT 10;


-- 4. Concatenate strings
-- Concatenate house number and street to create a new value called address
-- trim white space from the start of the results
SELECT TRIM(CONCAT(house_num, ' ', street)) AS address
FROM evanston311;

-- Select the first word of the street value
SELECT split_part(street, ' ', 1) AS street_name,
    COUNT(*)
FROM evanston311
GROUP BY split_part(street, ' ', 1)
ORDER BY COUNT(*) DESC
LIMIT 20;

-- Shorten long strings
-- Select the first 50 chars of the description when length is greater than 50.
-- Return all descriptions that begin with the word I - Sentiment Analysis
SELECT CASE WHEN LENGTH(description, 50) THEN LEFT(description, 50) || '...'
       ELSE description
       END
FROM evanston311
WHERE description LIKE 'I %'
ORDER BY description;


-- 5. Create an "Other" category to group low frequency zip codes
SELECT CASE WHEN zipcount < 100 THEN 'other'
       ELSE zip
       END AS zip_recoded,
       SUM(zipcount) AS zipsum
FROM (SELECT zip, count(*) AS zipcount
      FROM evanston311
      GROUP BY zip) AS fullcounts
GROUP BY zip_recoded
ORDER BY zipsum DESC;

-- Group and recode values
-- Create a temp table called recode to store distinct, standardized category values.
DROP TABLE IF EXISTS recode;

CREATE TEMP TABLE recode AS 
    SELECT DISTINCT category,
           RTRIM(SPLIT_PART(category, '-', 1)) AS standardized
    FROM evanston311;

-- Next step
SELECT DISTINCT standardized
FROM recode
WHERE standardized LIKE 'Trash%Cart'
    OR standardized LIKE 'Snow%Removal%';

-- Update to group trash cart values
UPDATE recode
SET standardized='Trash Cart'
WHERE standardized LIKE 'Trash%Cart';

-- Update to group snow removal values
UPDATE recode
SET standardized='Snow Removal'
WHERE standardized LIKE 'Snow%Removal%';

-- Update to group unused/inactive values
UPDATE recode
SET standardized='UNUSED'
WHERE standardized IN ('THIS REQUEST IS INACTIVE...Trash Cart',
                       '(DO NOT USE) Water Bill',
                       'DO NOT USE Trash',
                       'NO LONGER IN USE');

SELECT standardized,
    COUNT(*)
FROM evanston311
LEFT JOIN recode ON evanston311.category = recode.category
GROUP BY standardized
ORDER BY COUNT DESC;


-- 6. Create a table with indicator variables
DROP TABLE IF EXISTS indicators;

-- Create the temp table
CREATE TEMP TABLE indicators AS
  SELECT id, 
         CAST (description LIKE '%@%' AS integer) AS email,
         CAST (description LIKE '%___-___-____%' AS integer) AS phone 
    FROM evanston311;

-- Select the column you'll group by
SELECT priority,
       -- Compute the proportion of rows with each indicator
       SUM(email)/COUNT(*)::NUMERIC AS email_prop, 
       SUM(phone)/COUNT(*)::NUMERIC AS phone_prop
  -- Tables to select from
  FROM evanston311
       LEFT JOIN indicators
       -- Joining condition
       ON evanston311.id=indicators.id
 -- What are you grouping by?
 GROUP BY priority;