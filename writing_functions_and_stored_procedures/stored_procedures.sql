/* Chapter 3 Stored Procedures
Subtitle: Writing Functions and Stored Procedures in SQL Server

Learn how to create, update, and execute stored procedures.
Investigate the differences between stored procedures and user defined functions,
including appropriate scenarios for each.

-------------------------------- NOTES ------------------------------------------

STORED PROCEDURES

$ What is a stored procedure?
    Stored Procedures are called "SP's" for short.

    Routines that:
    - Accept input parameters
    - Perform actions (EXECUTE, SELECT, INSERT, UPDATE, DELETE)
    - Return status (success or failure)
    - Return output parameters


$ Why use stored procedures?
    - Reduce execution time
    - Can reduce network traffic
    - Allow for modular programming, like User Defined Functions (udfs)
    - Improved Security. Help prevent SQL injection attacks.
        - SQL injection attacks are a hacking technique where SQL
          statements are injected into a database.


$ What do SP's and UDF's Have in Common?
    - Accept input parameters
    - Perform an action


$ What's the difference?

    UDFs or User Defined Functions
    - Must return value
        - Table value is allowed
    - Embedded SELECT execute allowed
    - No output parameters
    - No INSERT, UPDATE, DELETE
    - Cannot execute Stored Procedures
    - No Error Handling

    SP's or Stored Procedures
    - Return value optional
        - Cannot return table-valued result
    - Cannot embed in SELECT to execute
    - Return output parameters & status
    - INSERT, UPDATE, DELETE allowed
    - Can execute functions & SPs from within a Stored Procedure
    - Error Handling with TRY...CATCH


$ CREATE PROCEDURE with OUTPUT parameter

    - Each stored procedure name must be unique across the schema
      including user defined functions.
    
    Stored Procedure Syntax
        CREATE PROCEDURE dbo.cuspGetRideHrsOneDay
            @DateParm date,
            @RideHrsOut numeric OUTPUT
        AS
        ...

    Line 1 is the schema, followed by the stored procedure name.
    Lines 2-3 are parameters with their corresponding data types.
    Line 3 OUTPUT keyword indicates it should be returned as output.
    Parameters in a Stored Procedure do not need to be enclosed in parenthesis,
    like in UDF's.


$ CREATE PROCEDURE with OUTPUT parameter Pt. 2

    CREATE PROCEDURE dbo.cuspGetRideHrsOneDay
        @DateParm date,
        @RideHrsOut numeric OUTPUT
    AS
    SET NOCOUNT ON
    BEGIN
    SELECT
        @RideHrsOut = SUM(
            DATEDIFF(second, PickupDate, DropoffDate)
        )/ 3600
    FROM YellowTripData
    WHERE CONVERT(date, PickupDate) = @DateParm
    RETURN
    END;

    - Line 5, SET NOCOUNT ON, prevents SQL from returning the number of rows affected by the
    stored procedure to the caller.
        - It is a best practice to include this line.
        - If an application is expected the number of rows affected by the change to be
          returned from a Stored Procedure, it will cause an error if Line 5 is excluded.


$ Output Parameters vs. Return Values

    Output parameters
    - Can be any data type
    - Can declare multiple per Stored Procedure
    - Cannot be table-valued parameters

    Return value
    - Used to indicate success or failure
    - Integer data type only
    - 0 indicates success and non-zero indicates failure.


$ Oh C.R.U.D! (Create, Read, Update, Delete)

$ Why use Stored Procedures for CRUD?

    - Applications can use N-Tier architecture, which utilizes various logical layers
      seperating:

        N-Tier Architecture
        Top down, sequential and circular
        -------------------
        Presentation Layer
        Business Logic Layer
        Data Access Layer
        Data Source

        - Stored Procedures exist in the Data Source, the Data Access Layer only needs
          to execute them.

    - Decouples SQL code from other application layers
    - Improved security
    - Performance
        - The SQL Server query optimizer creates an execution plan
          when a stored procedure is first executed.
        - Cached for future use.


$ Let's EXECute

$ Ways to EXECute
    - No output parameter or return value
    - Store return value
    - With output parameter
    - With output parameter and store return value
    - Store result set

    1. No output parameter or return value

        EXEC dbo.cusp_TripSummaryUpdate
            @TripDate = '1/5/2017'
            @TripHours = '300'


    2. With return value

        DECLARE @ReturnValue as int

        EXEC @ReturnValue = dbo.cusp_TripSummaryUpdate
            @TripDate = '1/5/2017'
            @TripHours = 300

        SELECT @ReturnValue as ReturnValue


    3. With OUTPUT parameter

        DECLARE @RideHrs as numeric(18,0)

        EXEC dbo.cuspSumRideHrsOneDay
            @DateParm = '1/5/2017'
            @RideHrsOut = @RideHrs Output
        
        SELECT @RideHrs as TotalRideHours


    4. With return value & output parameter

        DECLARE @ReturnValue as int
        DECLARE @RowCount as int

        EXEC @ReturnValue =
            dbo.cusp_TripSummaryDelete
            @TripDate = '1/5/2017',
            @RowCountOut = @RowCount OUTPUT

        SELECT @ReturnValue as ReturnValue,
            @RowCount as RowCount


$ EXEC & store result set

    DECLARE @TripSummaryResultSet as TABLE(
        TripDate date,
        TripHours numeric(18,0)
    )
    INSERT INTO @TripSummaryResultSet
    EXEC cusp_TripSummaryRead @TripDate = '1/5/2017'
    SELECT * FROM @TripSummaryResultSet


$ TRY & CATCH those errors!

$ To Handle Errors or Not

    What is error handling?
    - Anticipation, detection and resolution of errors
    - Maintains normal flow of execution
    - Integrated into initial design

    What happens without error handling?
    - Sudden shut down or halts execution
    - Generic error messages without helpful context are provided


$ Let's TRY

    ALTER PROCEDURE dbo.cusp_TripSummaryCreate
        @TripDate nvarchar(30),
        @RideHrs numeric,
        @ErrorMsg nvarchar(max) = null OUTPUT

    AS
    BEGIN
        BEGIN TRY
            INSERT INTO TripSummary (Date, TripHours)
            VALUES (@TripDate, @RideHrs)
        END TRY
        BEGIN CATCH
            SET @ErrorMsg = 'Error_Num: ' +
            CAST (ERROR_NUMBER() AS varchar) +
            ' Error_Sev: ' +
            CAST(ERROR_SEVERITY() AS varchar) +
            ' Error_Msg: ' + ERROR_MESSAGE()
        END CATCH
    END


$ Show me the ERROR...



$ THROW vs RAISERROR

    THROW
    - Introduced in SQL Server 2012
    - Simple & easy to use
    - Statements following will NOT be executed

    RAISERROR
    - Introduced in SQL Server 7.0
    - Generates new error and cannot acess details of original error
    - Statements following can be executed


    - SQL Server cannot convert a string to a DateTime type
*/
------------------------------ EXERCISES -----------------------------------------

-- 1. CREATE PROCEDURE with OUTPUT
-- Create a Stored Procedure that returns the total ride hours for the date passed.

-- Create the stored procedure
CREATE PROCEDURE dbo.cuspSumRideHrsSingleDay
    -- Declare the input parameter
	@DateParm date,
    -- Declare the output parameter
	@RideHrsOut numeric OUTPUT
AS
-- Don't send the row count 
SET NOCOUNT ON
BEGIN
-- Assign the query result to @RideHrsOut
SELECT
	@RideHrsOut = SUM(DATEDIFF(second, StartDate, EndDate))/3600
FROM CapitalBikeShare
-- Cast StartDate as date and compare with @DateParm
WHERE CAST(StartDate AS date) = @DateParm
RETURN
END


/*
-- 2. Output Parameters vs. Return Values
Question:

Select the statement that is FALSE when ccomparing output parameters and return values.

1. Output parameters should be used to communicate errors to the calling application.
2. You can define multiple output parameters but only one return value.
3. Return values can only return integer data types.
4. Output parameters can't be table valued data types.

Selection 1 is FALSE, Return Values should be used to communicate errors to the calling
application.
*/


-- 3. Use Stored Procedure to INSERT values into a TABLE
-- CRUD Stored Procedure
-- Create a Stored Procedure named cusp_RideSummaryCreate into the dbo schema
-- To insert a record into the RideSummary table.

-- Create the stored procedure
CREATE PROCEDURE dbo.cusp_RideSummaryCreate 
    (@DateParm date, @RideHrsParm numeric)
AS
BEGIN
SET NOCOUNT ON
-- Insert into the Date and RideHours columns
INSERT INTO dbo.RideSummary(Date, RideHours)
-- Use values of @DateParm and @RideHrsParm
VALUES(@DateParm, @RideHrsParm) 

-- Select the record that was just inserted
SELECT
    -- Select Date column
	Date,
    -- Select RideHours column
    RideHours
FROM dbo.RideSummary
-- Check whether Date equals @DateParm
WHERE Date = @DateParm
END;


-- 4. Use Stored Procedure to UPDATE
-- Create a stored procedure named cuspRideSummaryUpdate into the dbo schema
-- that will update an existing record in the RideSummary table.

-- Create the stored procedure
CREATE PROCEDURE dbo.cuspRideSummaryUpdate
	-- Specify @Date input parameter
	(@Date Date,
     -- Specify @RideHrs input parameter
     @RideHrs numeric(18,0))
AS
BEGIN
SET NOCOUNT ON
-- Update RideSummary
UPDATE RideSummary
-- Set
SET
	Date = @Date,
    RideHours = @RideHrs
-- Include records where Date equals @Date
WHERE Date = @Date
END;


-- 5. Use Stored Procedure to DELETE
-- Create a stored procedure named cuspRideSummaryDelete into the dbo schema
-- that will delete an existing record in the RideSummary table and RETURN
-- the number of rows affected via output parameter.

CREATE PROCEDURE dbo.cuspRideSummaryDelete
     @Dateparm Date,
     @RowCountOut int OUTPUT
AS
BEGIN
DELETE FROM dbo.RideSummary
WHERE Date = @DateParm
SET @RowCountOut = @@ROWCOUNT
RETURN
END;


-- 6. EXECUTE with OUTPUT parameter
-- Create @RideHrs
DECLARE @RideHrs AS numeric(18,0)
-- Execute the stored procedure
EXEC dbo.cuspSumRideHrsSingleDay
    -- Pass the input parameter
	@DateParm = '3/1/2018',
    -- Store the output in @RideHrs
	@RideHrsOut = @RideHrs OUTPUT

-- Select @RideHrs
SELECT @RideHrs AS RideHours


-- 7. EXECUTE with return value
-- Create @ReturnStatus
DECLARE @ReturnStatus AS int
-- Execute the SP, storing the result in @ReturnStatus
EXEC @ReturnStatus = dbo.cuspRideSummaryUpdate
    -- Specify @DateParm
	@DateParm = '3/1/2018',
    -- Specify @RideHrs
	@RideHrs = 300

-- Select the columns of interest
SELECT
	@ReturnStatus AS ReturnStatus,
    Date,
    RideHours
FROM RideSummary
WHERE Date = '3/1/2018';


-- 8. EXECUTE with OUTPUT & return value
-- Create @ReturnStatus
DECLARE @ReturnStatus AS int
-- Create @RowCount
DECLARE @RowCount AS int

-- Execute the SP, storing the result in @ReturnStatus
EXEC @ReturnStatus = dbo.cuspRideSummaryDelete 
    -- Specify @DateParm
	@DateParm = '3/1/2018',
    -- Specify RowCountOut
	@RowCountOut = @RowCount OUTPUT

-- Select the columns of interest
SELECT
	@ReturnStatus AS ReturnStatus,
    @RowCount as 'RowCount';


-- 9. Your very own TRY... CATCH
-- Alter the stored procedure
CREATE OR ALTER PROCEDURE dbo.cuspRideSummaryDelete
	-- (Incorrectly) specify @DateParm
	@DateParm nvarchar(30),
    -- Specify @Error
	@Error nvarchar(max) = NULL OUTPUT
AS
SET NOCOUNT ON
BEGIN
  -- Start of the TRY block
  BEGIN TRY
  	  -- Delete
      DELETE FROM RideSummary
      WHERE Date = @DateParm
  -- End of the TRY block
  END TRY
  -- Start of the CATCH block
  BEGIN CATCH
		SET @Error = 
		'Error_Number: '+ CAST(ERROR_NUMBER() AS VARCHAR) +
		'Error_Severity: '+ CAST(ERROR_SEVERITY() AS VARCHAR) +
		'Error_State: ' + CAST(ERROR_STATE() AS VARCHAR) + 
		'Error_Message: ' + ERROR_MESSAGE() + 
		'Error_Line: ' + CAST(ERROR_LINE() AS VARCHAR)
  -- End of the CATCH block
  END CATCH
END;


-- 10 . CATCH an error
-- Create @ReturnCode
DECLARE @ReturnCode int
-- Create @ErrorOut
DECLARE @ErrorOut nvarchar(max)
-- Execute the SP, storing the result in @ReturnCode
EXECUTE @ReturnCode = dbo.cuspRideSummaryDelete
    -- Specify @DateParm
	@DateParm = '1/32/2018',
    -- Assign @ErrorOut to @Error
	@Error = @ErrorOut OUTPUT
-- Select @ReturnCode and @ErrorOut
SELECT
	@ReturnCode AS ReturnCode,
    @ErrorOut AS ErrorMessage;