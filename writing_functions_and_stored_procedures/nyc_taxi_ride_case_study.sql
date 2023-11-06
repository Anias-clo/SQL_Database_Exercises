/*
$ Taxi Ride Business Problem
	1. EU Private equity firm seeking investment opportunity in US Transportation
	2. What is the average fare per distance, ride count & total ride time
	   for each NYC borough on each day of the week?
	3. Which pickup locations within the borough should be scheduled for each of the driver shifts?


$ Essential EDA
	* EDA Conclusions could greatly affect how business decisions are implemented using your queries.
	- Distributed transactional datasets can contain impossible scenarios due to data collection
	  callibration problems.
	  	- Future dates
		- End dates before start dates

	SELECT *
	FROM CapitalBikeShare
	WHERE
		StartDate > GetDate()
		OR EndDate > GetDate()
		OR StartDate > EndDate;


$ Data Imputation
	- Divide by zero error when calculating Avg Fare/TripDistance
	- EDA uncovers hundreds of TaxiRide trip records within Trip Distance = 0
	- Data Imputation methods to resolve
		- Mean
		- Hot Deck
		- Omission

$ Mean Imputation
	- Replace a missing value in a column with mean.
	- Doesn't change the mean value.
	- Increases correlations with other columns.

	--------------------------------------------------------------------
	1. Create a Stored Procedure to impute duration values equal to 0 with
	   the mean duration.
	--------------------------------------------------------------------
	CREATE PROCEDURE dbo.ImputeDurMean
	AS
	BEGIN
	--------------------------------------------------------------------
	2. Create a variable named '@AvgTripDuration' of type float to store
	   the average duration.
	--------------------------------------------------------------------
	DECLARE @AvgTripDuration AS float

	--------------------------------------------------------------------
	3. Store the calculation of AVG(Duration) to '@AvgTripDuration' using
	   all non-zero values.
	--------------------------------------------------------------------
	SELECT @AvgTripDuration = AVG(Duration)
	FROM CapitalBikeShare
	WHERE Duration > 0

	--------------------------------------------------------------------
	4. Use the stored mean duration to update zeros with the mean duration
	   in the taxi dataset.
	--------------------------------------------------------------------
	UPDATE CapitalBikeShare
	SET Duration = @AvgTripDuration
	WHERE Duration = 0
	END;


$ Hot Deck Imputation
	- Missing value set to randomly selected value from the dataset.
	- TABLESAMPLE clause FROM clause

	CREATE FUNCTION dbo.GetDurHotDeck()
	RETURNS decimal (18,4)
	AS BEGIN
	RETURN (SELECT TOP 1 Duration
	FROM CapitalBikeShare
	TABLESAMPLE (1000 rows)
	WHERE Duration > 0)
	END

	--------------------------------------------------------------------
						Implement Hot Deck Imputation
	Inside of the CASE statement, each time SQL encounters a zero in the
	duration column, the function 'dbo.GetDurHotDeck()' is called and replaces
	the zero with the mean taxi trip duration.

	Replacing zero values using a function DOES NOT affect the underlying data.
	--------------------------------------------------------------------
	SELECT
		StartDate,
		"TripDuration" = CASE WHEN DURATION > 0 THEN Duration
								ELSE dbo.GetDurHotDeck() END
	FROM CapitalBikeShare;

$ Omission
	- Excluding records where the duration is 0.

When selecting an imputation technique consider:
- The dataset size
- The analysis goals
- The data distribution
- The data's relationship to other columns.
- Imputation creates bias in a dataset.


$ Case Study User Defined Functions (UDF's)

	- Create a function to convert miles to kilometers
	- Create a function to convert the taxi fare into another currency, given the exchange rate.

	Conversion UDF's
	
		1. Distance Conversion

		CREATE FUNCTION dbo.ConvertMileToMeter (@miles NUMERIC(18, 2))
		RETURNS NUMERIC(18, 2)
		AS
		BEGIN
		RETURN (SELECT @miles * 1609.34)
		END;
		
		2. Currency Conversion

		CREATE FUNCTION dbo.ConvertCurrency (@Currency NUMERIC(18,2) @ExchangeRate NUMERIC(18,2))
		RETURNS NUMERIC(18,2)
		AS
		BEGIN
		RETURN (SELECT @ExchangeRate * @Currency)
		END;


$ Testing UDF's To Find Errors
	- Testing UDF's is an essential step when creating functions.

	To illustrate this point, let's implement the ConvertMileToMeter function without specifying
	precision in input and return value.

		CREATE FUNCTION dbo.ConvertMileToMeter(@mile NUMERIC)
		RETURNS NUMERIC
		AS BEGIN RETURN
		(SELECT @mile * 1609.34)
		END;

	When the function is tested, we find that SQL returns whole numbers instead of a floats. This
	is the default behavior of SQL. Since precision matters, let's update the function to correct
	the error. 
	
	Using the ALTER keyword allows us to change how our function works.

		ALTER FUNCTION dbo.ConvertMileToMeter (@mile NUMERIC(18, 2))
		RETURNS NUMERIC(18, 2)
		AS BEGIN RETURN
		(SELECT @mile * 1609.34)
		END;


$ What about Shifts?
	- Optimal Taxi Driver Shifts

	- Create a function that accepts an hour and returns the shift number for each
	  taxi driver/record.
	
	CREATE FUNCTION dbo.GetShift (@Hour int)
	RETURNS INT
	AS BEGIN
	RETURN (CASE
		WHEN @Hour >= 0 AND @Hour < 9 THEN 1
		WHEN @Hour >= 9 AND @Hour < 18 THEN 2
		WHEN @Hour >= 18 AND @Hour < 24 THEN 3
		END)
	END;


$ Formatting Tools

	$ Before Formatting
	- SQL will automatically order 

	SELECT
		DATENAME(WEEKDAY, StartDate) AS 'DayOfWeek',
		SUM(Duration) AS TotalDuration
	FROM CapitalBikeShare
	GROUP BY DATENAME(WEEKDAY, StartDate)
	ORDER BY DATENAME(WEEKDAY, StartDate)




EXERCISES
*/

-- 1. Use EDA to find impossible scenarios
SELECT
	-- PickupDate is after today
	COUNT (CASE WHEN PickupDate > GETDATE() THEN 1 END) AS 'FuturePickup',
    -- DropOffDate is after today
	COUNT (CASE WHEN DropOffDate > GETDATE() THEN 1 END) AS 'FutureDropOff',
    -- PickupDate is after DropOffDate
	COUNT (CASE WHEN PickupDate > DropOffDate THEN 1 END) AS 'PickupBeforeDropoff',
    -- TripDistance is 0
	COUNT (CASE WHEN TripDistance = 0 THEN 1 END) AS 'ZeroTripDistance'  
FROM YellowTripData;


/*
2. Mean Imputation
	Create a stored procedure that will apply mean imputation to the YellowTripData
	records with an incorrect TripDistance of zero. The average trip distance variable
	should have a percision of 18 and 4 decimal places.
*/
CREATE PROCEDURE dbo.cuspImputeTripDistanceMean
AS
BEGIN
	-- Specify @AvgTripDistance variable
	DECLARE @AvgTripDistance AS numeric (18,4)

	-- Calculate the average trip distance
	SELECT @AvgTripDistance = AVG(TripDistance) 
	FROM YellowTripData
	-- Only include trip distances greater than 0
	WHERE TripDistance > 0

	-- Update the records where trip distance is 0
	UPDATE YellowTripData
	SET TripDistance =  @AvgTripDistance
	WHERE TripDistance = 0
END;


/*
3. Hot Deck Imputation
	Create a function named dbo.GetTripDistanceHotDeck() that returns a TripDistance
	value via Hot Deck methodology. TripDistance should have a precision of 18 and 4
	decimal places.
*/
-- Create the function
CREATE FUNCTION dbo.GetTripDistanceHotDeck()
-- Specify return data type
RETURNS NUMERIC(18,4)
AS 
BEGIN
RETURN
	-- Select the first TripDistance value
	(SELECT TOP 1 TripDistance
	FROM YellowTripData
    -- Sample 1000 records
	TABLESAMPLE(1000 rows)
    -- Only include records where TripDistance is > 0
	WHERE TripDistance > 0)
END;

/*
4. CREATE FUNCTIONs
	Create three functions to help solve the business case:

	1. Convert distance from miles to kilometers.
	2. Convert currency based on exchange rate parameter.
	3. Identify the driver shift based on the hour parameter value passed.
*/

	-- 1. Create the function to convert miles to kilometers.
	CREATE FUNCTION dbo.ConvertMileToKm (@Miles NUMERIC(18,2))
	-- Specify return data type
	RETURNS NUMERIC(18,2)
	AS
	BEGIN
	RETURN
		-- Convert Miles to Kilometers
		(SELECT @Miles * 1.609)
	END;

	-- 2. Create the function to convert the dollar to a foreign currency, given the exchange rate.
	CREATE FUNCTION dbo.ConvertDollar
		-- Specify @DollarAmt parameter
		(@DollarAmt NUMERIC(18,2),
		-- Specify ExchangeRate parameter
		@ExchangeRate NUMERIC(18,2))
	-- Specify return data type
	RETURNS NUMERIC(18,2)
	AS
	BEGIN
	RETURN
		-- Multiply @ExchangeRate and @DollarAmt
		(SELECT @ExchangeRate * @DollarAmt)
	END;

	-- 3. Create the function to idenify the drivers' shift, given the hour.
	CREATE FUNCTION dbo.GetShiftNumber (@Hour integer)
	-- Specify return data type
	RETURNS INT
	AS
	BEGIN
	RETURN
		-- 12am (0) to 9am (9) shift
		(CASE WHEN @Hour >= 0 AND @Hour < 9 THEN 1
			-- 9am (9) to 5pm (17) shift
			WHEN @Hour >= 9 AND @Hour < 17 THEN 2
			-- 5pm (17) to 12am (24) shift
			WHEN @Hour >= 17 AND @Hour < 24 THEN 3 END)
	END;


/*
5. Test FUNCTIONs
	Test the three functions created in the previous exercise.
*/
SELECT
	-- Select the first 100 records of PickupDate
	TOP 100 PickupDate,
    -- Determine the shift value of PickupDate
	dbo.GetShiftNumber(DATENAME(HOUR, PickupDate)) AS 'Shift',
    -- Select FareAmount
	FareAmount,
    -- Convert FareAmount to Euro
	dbo.ConvertDollar(FareAmount, 0.87) AS 'FareinEuro',
    -- Select TripDistance
	TripDistance,
    -- Convert TripDistance to kilometers
	dbo.ConvertMiletoKm(TripDistance) AS 'TripDistanceinKM'
FROM YellowTripData
-- Only include records for the 2nd shift
WHERE dbo.GetShiftNumber(DATENAME(HOUR, PickupDate)) = 2;


/*
6. Logical Weekdays with Hot Deck

Calculate Total Fare Amount per Total Distance for each day of week.
If the TripDistance is zero use the Hot Deck imputation function you created
earlier in the chapter.
*/
SELECT
    -- Select the pickup day of week
	DATENAME(weekday, PickupDate) as DayofWeek,
    -- Calculate TotalAmount per TripDistance
	CAST(AVG(TotalAmount/
            -- Select TripDistance if it's more than 0
			CASE WHEN TripDistance > 0 THEN TripDistance
                 -- Use GetTripDistanceHotDeck()
     			 ELSE dbo.GetTripDistanceHotDeck() END) as decimal(10,2)) as 'AvgFare'
FROM YellowTripData
GROUP BY DATENAME(weekday, PickupDate)
-- Order by the PickupDate day of week
ORDER BY
     CASE WHEN DATENAME(weekday, PickupDate) = 'Monday' THEN 1
         WHEN DATENAME(weekday, PickupDate) = 'Tuesday' THEN 2
         WHEN DATENAME(weekday, PickupDate) = 'Wednesday' THEN 3
         WHEN DATENAME(weekday, PickupDate) = 'Thursday' THEN 4
         WHEN DATENAME(weekday, PickupDate) = 'Friday' THEN 5
         WHEN DATENAME(weekday, PickupDate) = 'Saturday' THEN 6
         WHEN DATENAME(weekday, PickupDate) = 'Sunday' THEN 7
END ASC;


/*
7. Format for Germany

Write a query to display the TotalDistance, TotalRideTime and TotalFare for each day
and NYC Borough. Display the date, distance, ride time, and fare totals for German culture.
*/
SELECT
    -- Cast PickupDate as a date and display as a German date
	FORMAT(CAST(PickupDate AS date), 'd', 'de-de') AS 'PickupDate',
	Zone.Borough,
    -- Display TotalDistance in the German format
	FORMAT(SUM(TripDistance), 'n', 'de-de') AS 'TotalDistance',
    -- Display TotalRideTime in the German format
	FORMAT(SUM(DATEDIFF(minute, PickupDate, DropoffDate)), 'n', 'de-de') AS 'TotalRideTime',
    -- Display TotalFare in German currency
	FORMAT(SUM(TotalAmount), 'c', 'de-de') AS 'TotalFare'
FROM YellowTripData
INNER JOIN TaxiZoneLookup AS Zone 
ON PULocationID = Zone.LocationID 
GROUP BY
	CAST(PickupDate as date),
    Zone.Borough 
ORDER BY
	CAST(PickupDate as date),
    Zone.Borough;


/*
8. NYC Borough statistics Stored Procedure
*/
CREATE OR ALTER PROCEDURE dbo.cuspBoroughRideStats
AS
BEGIN
SELECT
    -- Calculate the pickup weekday
	DATENAME(weekday, PickupDate) AS 'Weekday',
    -- Select the Borough
	Zone.Borough AS 'PickupBorough',
    -- Display AvgFarePerKM as German currency
	FORMAT(AVG(dbo.ConvertDollar(TotalAmount, .88)/dbo.ConvertMiletoKM(TripDistance)), 'c', 'de-de') AS 'AvgFarePerKM',
    -- Display RideCount in the German format
	FORMAT(COUNT(ID), 'n', 'de-de') AS 'RideCount',
    -- Display TotalRideMin in the German format
	FORMAT(SUM(DATEDIFF(SECOND, PickupDate, DropOffDate))/60, 'n', 'de-de') AS 'TotalRideMin'
FROM YellowTripData
INNER JOIN TaxiZoneLookup AS Zone 
ON PULocationID = Zone.LocationID
-- Only include records where TripDistance is greater than 0
WHERE TripDistance > 0
-- Group by pickup weekday and Borough
GROUP BY DATENAME(WEEKDAY, PickupDate), Zone.Borough
ORDER BY CASE WHEN DATENAME(WEEKDAY, PickupDate) = 'Monday' THEN 1
	     	  WHEN DATENAME(WEEKDAY, PickupDate) = 'Tuesday' THEN 2
              WHEN DATENAME(WEEKDAY, PickupDate) = 'Wednesday' THEN 3
              WHEN DATENAME(WEEKDAY, PickupDate) = 'Thursday' THEN 4
              WHEN DATENAME(WEEKDAY, PickupDate) = 'Friday' THEN 5
              WHEN DATENAME(WEEKDAY, PickupDate) = 'Saturday' THEN 6
              WHEN DATENAME(WEEKDAY, PickupDate) = 'Sunday' THEN 7 END,  
		 SUM(DATEDIFF(SECOND, PickupDate, DropOffDate))/60
DESC
END;


CREATE OR ALTER PROCEDURE dbo.cuspBoroughRideStats
AS
BEGIN
SELECT
    -- Calculate the pickup weekday
	DATENAME(weekday, PickupDate) AS 'Weekday',
    -- Select the Borough
	Zone.Borough AS 'PickupBorough',
    -- Display AvgFarePerKM as German currency
	FORMAT(AVG(dbo.ConvertDollar(TotalAmount, .88)/dbo.ConvertMiletoKM(TripDistance)), 'c', 'de-de') AS 'AvgFarePerKM',
    -- Display RideCount in the German format
	FORMAT(COUNT(ID), 'n', 'de-de') AS 'RideCount',
    -- Display TotalRideMin in the German format
	FORMAT(SUM(DATEDIFF(SECOND, PickupDate, DropOffDate))/60, 'n', 'de-de') AS 'TotalRideMin'
FROM YellowTripData
INNER JOIN TaxiZoneLookup AS Zone 
ON PULocationID = Zone.LocationID
-- Only include records where TripDistance is greater than 0
WHERE TripDistance > 0
-- Group by pickup weekday and Borough
GROUP BY DATENAME(WEEKDAY, PickupDate), Zone.Borough
ORDER BY CASE WHEN DATENAME(WEEKDAY, PickupDate) = 'Monday' THEN 1
	     	  WHEN DATENAME(WEEKDAY, PickupDate) = 'Tuesday' THEN 2
              WHEN DATENAME(WEEKDAY, PickupDate) = 'Wednesday' THEN 3
              WHEN DATENAME(WEEKDAY, PickupDate) = 'Thursday' THEN 4
              WHEN DATENAME(WEEKDAY, PickupDate) = 'Friday' THEN 5
              WHEN DATENAME(WEEKDAY, PickupDate) = 'Saturday' THEN 6
              WHEN DATENAME(WEEKDAY, PickupDate) = 'Sunday' THEN 7 END,  
		 SUM(DATEDIFF(SECOND, PickupDate, DropOffDate))/60
DESC
END;


/*
9. NYC Borough statistics results
*/
-- Create SPResults
DECLARE @SPResults AS TABLE(
  	-- Create Weekday
	Weekday nvarchar(30),
    -- Create Borough
	Borough nvarchar(30),
    -- Create AvgFarePerKM
	AvgFarePerKM nvarchar(30),
    -- Create RideCount
	RideCount nvarchar(30),
    -- Create TotalRideMin
	TotalRideMin nvarchar(30))

-- Insert the results into @SPResults
INSERT INTO @SPResults
-- Execute the SP
EXECUTE dbo.cuspBoroughRideStats

-- Select all the records from @SPresults 
SELECT *
FROM @SPResults;


/*
10. Pickup Locations by Shift
*/
-- Create the stored procedure
CREATE PROCEDURE dbo.cuspPickupZoneShiftStats
	-- Specify @Borough parameter
	@Borough nvarchar(30)
AS
BEGIN
SELECT
	DATENAME(WEEKDAY, PickupDate) as 'Weekday',
    -- Calculate the shift number
	dbo.GetShiftNumber(DATEPART(HOUR, PickupDate)) as 'Shift',
	Zone.Zone as 'Zone',
	FORMAT(AVG(dbo.ConvertDollar(TotalAmount, .77)/dbo.ConvertMiletoKM(TripDistance)), 'c', 'de-de') AS 'AvgFarePerKM',
	FORMAT(COUNT (ID),'n', 'de-de') as 'RideCount',
	FORMAT(SUM(DATEDIFF(SECOND, PickupDate, DropOffDate))/60, 'n', 'de-de') as 'TotalRideMin'
FROM YellowTripData
INNER JOIN TaxiZoneLookup as Zone on PULocationID = Zone.LocationID 
WHERE
	dbo.ConvertMiletoKM(TripDistance) > 0 AND
	Zone.Borough = @Borough
GROUP BY
	DATENAME(WEEKDAY, PickupDate),
    -- Group by shift
	dbo.GetShiftNumber(DATEPART(HOUR, PickupDate)),  
	Zone.Zone
ORDER BY CASE WHEN DATENAME(WEEKDAY, PickupDate) = 'Monday' THEN 1
              WHEN DATENAME(WEEKDAY, PickupDate) = 'Tuesday' THEN 2
              WHEN DATENAME(WEEKDAY, PickupDate) = 'Wednesday' THEN 3
              WHEN DATENAME(WEEKDAY, PickupDate) = 'Thursday' THEN 4
              WHEN DATENAME(WEEKDAY, PickupDate) = 'Friday' THEN 5
              WHEN DATENAME(WEEKDAY, PickupDate) = 'Saturday' THEN 6
              WHEN DATENAME(WEEKDAY, PickupDate) = 'Sunday' THEN 7 END,
         -- Order by shift
         dbo.GetShiftNumber(DATEPART(HOUR, PickupDate)),
         SUM(DATEDIFF(SECOND, PickupDate, DropOffDate))/60 DESC
END;


/*
11. Pickup locations by shift results
*/
-- Create @Borough
DECLARE @Borough AS NVARCHAR(30) = 'Manhattan'
-- Execute the SP
EXEC dbo.cuspPickupZoneShiftStats
    -- Pass @Borough
	@Borough = @Borough;