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
*/

------------------------------ EXERCISES -----------------------------------------

-- 1. 