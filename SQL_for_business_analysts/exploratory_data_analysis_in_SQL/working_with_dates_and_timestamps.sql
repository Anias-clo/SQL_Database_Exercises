/*
Chapter 4 Date/time types and formats.

In this chapter we aggregate data/time data by hour, day, month,
or year and practice both constructing time series and finding gaps
in them.


Date/time Types and Formats

There are 3 main types of date/times
1. date
2. timestamp
3. interval

Dates contain the day, month, and year.
Dates are formatted, for example , YYYY-MM-DD 2023-22-11.

Timestamps contain the day, month, year, [12 or 24] hour, minute, and second.
Timestamps are formatted, for example, YYYY-MM-DD HH:MM:SS

Intervals represent time duration
Intervals are the result of subtracting two date/time values.
- Intervals will default to display the number of days and time.


Date/time Format Examples
1 pm on November 22, 2023

11/22/23 1:00
22/11/23 01:00:00
11/22/2023 1pm
November 1st, 2023 1pm
22, Nov 2023 1:00
11/22/23 01:00:00
11/22/23 13:00:00

ISO 8601 Universal Format
Date infomation starts from largest to smallest
YYYY-MM-DD HH:MM:SS

UTC and Timezones
UTC = Coordindate Universal Time
Timestamp with timezone:
YYYY-MM-DD HH:MM:SS+HH
2023-11-22 16:21:00+07

Date/time Components and Aggregation
Fields
- century: 2023-11-22 = century 21
- decade: 2023-11-22 = decade 202
- year, month, date
- hour, minute, second
- week
- dow: day of week, 0-6

Extracting Fields
-- functions to extract datetime fields
date_part('[date part to extract]', <date/timestamp field>)
EXTRACT(FIELD FROM timestamp)
- The EXTRACT function calls the date_part function when executed.

Generate Series
The GENERATE_SERIES function can be used to create date/time intervals between two timestamps
Syntax:
SELECT GENERATE_SERIES(FROM, TO, interval);
- FROM and TO must be timestamp datatypes

SELECT GENERATE_SERIES('2023-01-01',
                       '2023-01-15',
                       '2 days'::interval);

> Generates a series of dates with 2 day intervals between 01-01 and 01-15.
> The last interval will be less than or equal to the last timestamp specified

To get consistent values when using the GENERATE_SERIES function on dates, use the
beginning month or year.
> To correctly generate a series for the last day of each month, generate a series
using the beginning of each month, then subtract 1 day from the result

SELECT GENERATE_SERIES('2023-02-01',
                       '2024-01-01',
                       '1 month'::interval) - '1 day'::interval;

GENERATE_SERIES can also be used to find units of time with no observations.
To include units of time with no observations, generate a series of years/months/days
and then join the series to the original data to introduce missing rows for the missing
observations.

WITH hour_series AS (
    SELECT generate_series('2018-04-23 09:00:00',
                           '2018-04-23 14:00:00',
                           '1 hour'::interval) AS hours)

-- Count the date column to count non-NULL values
SELECT hours, COUNT(date)
FROM hour_series
LEFT JOIN sales ON hours=DATE_TRUNC('hour' date)
GROUP BY hours
ORDER BY hours;

Aggregation with Bins
WITH bins AS (
    SELECT generate_series('2018-04-23 09:00:00',
                           '2018-04-23 15:00:00',
                           '3 hours'::interval) AS lower,
           generate_series('2018-04-23 12:00:00',
                           '2018-04-23 18:00:00',
                           '3 hours'::interval) AS upper
)

SELECT lower, upper, COUNT(date)
FROM bins
LEFT JOIN sales ON date >= lower
               AND date < upper
GROUP BY lower, upper
ORDER BY lower;


Time Between Events
How to calculate the time between events when dates or timestamps are stored in the
same column?

LEAD and LAG
The LEAD and LAG function offsets the ordered values in a column by 1 row by default.
To get the difference between events, subtract the original value from the lead or lag values
- LEAD and LAG are Window functions.
- Window functions CANNOT be used inside aggregation functions

*/

------------------------------ EXERCISES -----------------------------------------
-- 1. ISO 8601. Select the date that confirms to the ISO 8601 standard
--2018-06-15 15:30:00


-- 2. Date comparisons
-- Count the number of 311 requests created on January 31,2017 by casting date_created 
-- to a date
SELECT COUNT(*)
FROM evanston311
WHERE date_created::date = '2017-01-31';

-- Count the number of 311 requests created on Febuary 29, 2016 using >= and < operators.
SELECT COUNT(*)
FROM evanston311
WHERE date_created::date >= '2016-02-29'
    AND date_created::date < '2016-03-01';

-- Count the number of requests created on March 13, 2017 specify the upper bound
-- by adding 1 to the lower bound
SELECT COUNT(*)
FROM evanston311
WHERE date_created::date >= '2017-03-13'
    AND date_created::date < '2017-03-13'::date + 1;


-- 3. Date Arithmetic
-- Subtract the minimum and maximum date_created dates to find the interval
SELECT MAX(date_created) - MIN(date_created)
FROM evanston311; 

-- Using NOW(), find out how old the most recent 311 request was created.
SELECT NOW() - MAX(date_created)
FROM evanston311;

-- Add 100 days to the current timestamp
SELECT NOW() + '100 days'::interval;

-- Select the current timestamp and the current timestamp plus 5 minutes.
SELECT NOW(), NOW() + '5 minutes'::interval;


-- 4. Completion time by Category
-- Which 311 category takes the longest to complete
SELECT category,
       AVG(date_completed - date_created) AS completion_time
FROM evanston311
GROUP BY category
ORDER BY completion_time DESC;


-- 5. How many requests are created in each of the 12 months during 2016-2017
SELECT date_part('month', date_created) AS month,
    COUNT(*)
FROM evanston311
WHERE date_created::date BETWEEN '2016-01-01'
    AND '2017-12-31'
GROUP BY date_part('month', date_created);

-- What is the most common hour of the day for request to be created?
SELECT date_part('hour', date_created) AS hour,
       COUNT(*)
FROM evanston311
GROUP BY hour
ORDER BY 2 DESC
LIMIT 1;

-- During what hours are requests usually completed? Count requests completed by hour.
SELECT date_part('hour', date_completed) AS hour,
       COUNT(*)
FROM evanston311
GROUP BY date_part('hour', date_completed)
ORDER BY hour;


-- 6. Variation by Day of Week
SELECT TO_CHAR(date_created, 'day') AS day,
       AVG(date_completed - date_created) AS duration
FROM evanston311
GROUP BY TO_CHAR(date_created, 'day'), EXTRACT(DOW FROM date_created)
ORDER BY EXTRACT(DOW FROM date_created);


-- 7. Date Truncation
SELECT DATE_TRUNC('month', day) AS month,
       -- Calculate the average number of requests per day in each month
       AVG(count)
FROM ( -- Count the number of requests created per day
    SELECT DATE_TRUNC('day', date_created) AS day,
             COUNT(*) AS count
      FROM evanston311
      GROUP BY day) AS daily_count
GROUP BY month
ORDER BY month;


-- 8. Find Missing Dates
-- Are there any days in the Evanston 311 data where no requests were created?
SELECT day
FROM (SELECT GENERATE_SERIES(MIN(date_created),
                             MAX(date_created),
                             '1 day'::interval)::date AS day
      FROM evanston311) AS all_dates
WHERE day NOT IN (
    SELECT date_created::date
    FROM evanston311
);


-- 9. Custom Aggregation Periods
-- Find the median number of Evanston 311 requests per day in each six month period
-- from 2016-01-01 to 2018-06-30.

-- Step 1. Create the lower and upper bins
SELECT GENERATE_SERIES('2016-01-01',
                       '2018-01-01',
                       '6 months'::interval) AS lower,
       GENERATE_SERIES('2016-07-01',
                       '2018-07-01',
                       '6 months'::interval) AS upper;

-- Step 2. Counnt the number of requests created per day.
-- Include days with no requests by joining evanston311 to a daily series
-- from 2016-01-01 to 2018-06-30.
SELECT day, COUNT(date_created) AS count
FROM (
    SELECT GENERATE_SERIES('2016-01-01',
                           '2018-06-30',
                           '1 day'::interval)::date AS day) AS daily_series
LEFT JOIN evanston311
ON day = date_created::DATE
GROUP BY day;

-- Step 3. Assign each daily count to a single 6 month bin by joining bins to daily counts
-- Bins from Step 1
WITH bins AS (
	 SELECT generate_series('2016-01-01',
                            '2018-01-01',
                            '6 months'::interval) AS lower,
            generate_series('2016-07-01',
                            '2018-07-01',
                            '6 months'::interval) AS upper),
-- Daily counts from Step 2
     daily_counts AS (
     SELECT day, count(date_created) AS count
       FROM (SELECT generate_series('2016-01-01',
                                    '2018-06-30',
                                    '1 day'::interval)::date AS day) AS daily_series
            LEFT JOIN evanston311
            ON day = date_created::date
      GROUP BY day)
-- Select bin bounds 
SELECT lower, 
       upper, 
       -- Compute median of count for each bin
       percentile_disc(0.5) WITHIN GROUP (ORDER BY count) AS median
  -- Join bins and daily_counts
  FROM bins
       LEFT JOIN daily_counts
       -- Where the day is between the bin bounds
       ON day >= lower
          AND day < upper
 -- Group by bin bounds
 GROUP BY lower, upper
 ORDER BY lower;


 -- 10. Monthly Average with Missing Dates
 -- Find the average number of 311 requests created per day for each month of the data.
 WITH all_days AS (
        SELECT GENERATE_SERIES('2016-01-01',
                           '2018-06-30',
                           '1 day'::interval) AS date),
      daily_count AS (
        SELECT DATE_TRUNC('day', date_created) AS day,
               COUNT(*) AS count
        FROM evanston311
        GROUP BY day)
SELECT DATE_TRUNC('month', date) AS month,
       AVG(COALESCE(count, 0)) AS average
FROM all_days
LEFT JOIN daily_count ON all_days.date = daily_count.day
GROUP BY month
ORDER BY month;


-- 11. Longest Gap
-- What is the longest time between 311 requests submitted?
-- Compute the gaps
WITH request_gaps AS (
        SELECT date_created,
               -- lead or lag
               lag(date_created) OVER (ORDER BY date_created) AS previous,
               -- compute gap as date_created minus lead or lag
               date_created - lag(date_created) OVER (ORDER BY date_created) AS gap
          FROM evanston311)
-- Select the row with the maximum gap
SELECT *
  FROM request_gaps
-- Subquery to select maximum gap from request_gaps
 WHERE gap = (SELECT MAX(gap)
                FROM request_gaps);


-- 12. Rats Service Calls
-- Calculate the distribution of the number of days to complete a rat service request
-- Truncate the time to complete requests to the day
SELECT DATE_TRUNC('day', date_completed - date_created) AS completion_time,
-- Count requests with each truncated time
       COUNT(*)
  FROM evanston311
-- Where category is rats
 WHERE category = 'Rodents- Rats'
-- Group and order by the variable of interest
 GROUP BY completion_time
 ORDER BY COUNT(*) DESC;

-- Compute average completion time per category excluding the longest 5% of requests (outliers)
SELECT category, 
       -- Compute average completion time per category
       AVG(date_completed - date_created) AS avg_completion_time
  FROM evanston311
-- Where completion time is less than the 95th percentile value
 WHERE date_completed - date_created < 
-- Compute the 95th percentile of completion time in a subquery
         (SELECT percentile_disc(0.95) WITHIN GROUP (ORDER BY date_completed - date_created)
            FROM evanston311)
 GROUP BY category
-- Order the results
 ORDER BY avg_completion_time DESC;

 -- Calculate the correlation between average completion time and monthly requests.
 SELECT CORR(avg_completion, count)
 FROM (
    SELECT DATE_TRUNC('month', date_created) AS month,
           AVG(EXTRACT(epoch FROM date_completed - date_created)) AS avg_completion,
           COUNT(*) AS count
    FROM evanston311
    WHERE category='Rodents- Rats'
    GROUP BY month) AS monthly_avgs;

-- Select the number of requests created an number of requests completed per month
WITH created AS (
        SELECT DATE_TRUNC('month', date_created) AS month,
               COUNT(*) AS created_count
        FROM evanston311
        WHERE category = 'Rodents- Rats'
        GROUP BY month),
     completed AS (
        SELECT DATE_TRUNC('month', date_completed) AS month,
               COUNT(*) AS completed_count
        FROM evanston311
        WHERE category = 'Rodents- Rats'
        GROUP BY month)
SELECT created.month,
       created_count,
       completed_count
FROM created
INNER JOIN completed ON created.month = completed.month
ORDER BY created.month;
