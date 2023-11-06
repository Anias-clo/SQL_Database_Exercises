/*
Chapter 3. Known Limitations of Triggers
Find out known limitations of triggers, as well as common use cases for AFTER triggers (DML),
INSTEAD OF triggers (DML) and DDL triggers.


$ Advantages of Triggers 

    - Used for database integrity.
    - Enforce business rules directly in the database.
    - Control on which statements are allowed in the database.
    - Implementation of complex business logic triggered by a single event.
    - Simple way to audit databases and user actions.


$ Disadvantages of Triggers

    - Difficult to view and detect.
    - Invisible to client applications or when debugging code.
    - Hard to follow their logic when troubleshooting.
    - Can become an overhead on the server and make it run slower.


$ Finding Server-Level triggers

    SELECT * FROM sys.server_triggers;

$ Finding database and table triggers

    SELECT * FROM sys.triggers;

    - The type of the trigger (database or table) can be determined from the "parent_class_desc" column.

    columns returned
    ----------------
    name: the name of the trigger
    parent_class_desc: indicates the level of the trigger; OBJECT_OR_COLUMN, DATABASE
    create_date: YYYY-MM-DD
    is_disabled: boolean
    is_instead_of_trigger: boolean


$ Viewing a trigger definition

    1. Use a SQL GUI and right-click on the trigger name.

    2. SQL System Views

        SELECT definition
        FROM sys.sql_modules
        WHERE object_id = OBJECT_ID ('PreventOrdersUpdate'); 

    3. Use the OBJECT_DEFINITION FUNCTION

        SELECT OBJECT_DEFINITION (OBJECT_ID ('PreventOrdersUpdate'));

    4. Use the "sp_helptext" Stored Procedure

        EXECUTE sp_helpptext @objname = "PreventOrdersUpdate";


$ Triggers Best Practice

    - Well-documented database design
    - Simple logic in trigger design
    - Avoid overusing triggers


$ Use cases for AFTER triggers (DML)

    - Store historical data in other tables.
    
    Example table name "CustomerHistory"
    - Keep track of any changes to a customers information.


$ Keeping a History of row changes

    CREATE TRIGGER CopyCustomersToHistory
    ON Customers
    AFTER INSERT, UPDATE
    AS
        INSERT INTO CustomersHistory (Customer, ContractID, Address, PhoneNo)
        SELECT Customer, ContractID, Address, PhoneNo, GETDATE()
        FROM inserted;


$ Table Auditing Using Triggers

    CREATE TRIGGER OrderAudit
    ON Orders
    AFTER INSERT, UPDATE, DELETE
    AS
        DECLARE @Insert BIT = 0, @Delete BIT = 0;
        IF EXISTS (SELECT * FROM inserted) SET @Insert = 1;
        IF EXISTS (SELECT * FROM deleted) SET @Delete = 1;
        INSERT INTO [TableAudit] ([TableName], [EventType], [UserAccount], [EventDate])
        SELECT 'Orders' AS [TableName],
            CASE WHEN @Insert = 1 AND @Delete = 0 THEN 'INSERT'
                WHEN @Insert = 1 AND @Delete = 1 THEN 'UPDATE'
                WHEN @Insert = 0 and @Delete = 1 THEN 'DELETE'
                END AS [Event],
            ORIGINAL_LOGIN(),
            GETDATE();


$ Notifying the Sales Department When Orders are Placed

    CREATE TRIGGER NewOrderNotification
    ON Orders
    AFTER INSERT
    AS
        EXECUTE SendNotification @RecipientEmail = 'sales@freshfruit.com',
                                    @EmailSubject = 'New order placed',
                                    @EmailBody = 'A new order was just placed.';


$ Use cases for INSTEAD OF triggers (Data Manipulation Language - DML)

    General use of INSTEAD OF triggers
    - prevent operations from happening
    - control database statements
    - Enforce data integrity


    Triggers that prevent changes

    CREATE TRIGGER PreventProductChanges
    ON Products
    INSTEAD OF UPDATE
    AS
        RAISERROR ('Updates of products are not permitted. Contact the database administrator if a change is needed', 16, 1);


    Triggers that prevent and notify

    CREATE TRIGGER PreventCustomersRemoval
    ON Customers
    INSTEAD OF DELETE
    AS
        DECLARE @EmailBodyText NVARCHAR(50) = (SELECT 'User "' + ORIGINAL_LOGIN() + '" tried to remove a customer from the database.');
        RAISERROR ('Customer entries are not subject to removal.', 16, 1);

        EXECUTE SendNotification @RecipientEmail = 'admin@freshfruit.com',
                                @EmailSubject = 'Suspicious database behavior',
                                @EmailBody = @EmailBodyText;


    Triggers with conditional logic

    CREATE TRIGGER ConfirmStock
    ON Orders
    INSTEAD OF INSERT
    AS
        IF EXISTS (SELECT * FROM products AS p
                    INNER JOIN inserted AS i ON i.Product = p.Product
                    WHERE p.Quantity < i.Quantity)
            RAISERROR("You cannot place orders when there is no product stock.", 16, 1);
        ELSE
            INSERT INTO dbo.Orders (Customer, Product, Quantity, OrderDate, TotalAmount)
            SELECT Customer, Product, Quantity, OrderDate, TotalAmount
            FROM inserted;


    Triggers with conditional logic

    INSERT > TRIGGER > Y/N
                          > Y > INSERT
                          > N > ERROR


$ Use cases for DDL Triggers

    DDL trigger capabilities
    - Database level and Server level


    Preventing Server Changes

    CREATE TRIGGER PreventDatabaseDelete
    ON ALL SERVER
    FOR DROP_DATABASE
    AS
        PRINT 'You are not allowed to remove existing databases.;
        ROLLBACK;



EXERCISES
*/

-- 1. Creating a report on existing triggers
-- Gather information about database triggers
SELECT name AS TriggerName,
	   parent_class_desc AS TriggerType,
	   create_date AS CreateDate,
	   modify_date AS LastModifiedDate,
	   is_disabled AS Disabled,
	   is_instead_of_trigger AS InsteadOfTrigger,
       -- Get the trigger definition by using a function
	   OBJECT_DEFINITION (object_id)
FROM sys.triggers
UNION ALL
-- Gather information about server triggers
SELECT name AS TriggerName,
	   parent_class_desc AS TriggerType,
	   create_date AS CreateDate,
	   modify_date AS LastModifiedDate,
	   is_disabled AS Disabled,
	   0 AS InsteadOfTrigger,
       -- Get the trigger definition by using a function
	   OBJECT_DEFINITION (object_id)
FROM sys.server_triggers
ORDER BY TriggerName;


-- 2. Keeping a history of row changes
-- Create a trigger to keep row history
CREATE TRIGGER CopyCustomersToHistory
ON Customers
-- Fire the trigger for new and updated rows
AFTER INSERT, UPDATE
AS
	INSERT INTO CustomersHistory (CustomerID, Customer, ContractID, ContractDate, Address, PhoneNo, Email, ChangeDate)
	SELECT CustomerID, Customer, ContractID, ContractDate, Address, PhoneNo, Email, GETDATE()
    -- Get info from the special table that keeps new rows
    FROM inserted;


-- 3. Table Auditing Using Triggers
-- Add a trigger that tracks table changes
CREATE TRIGGER OrdersAudit
ON Orders
AFTER INSERT, UPDATE, DELETE
AS
	DECLARE @Insert BIT = 0;
	DECLARE @Delete BIT = 0;
	IF EXISTS (SELECT * FROM inserted) SET @Insert = 1;
	IF EXISTS (SELECT * FROM deleted) SET @Delete = 1;
	INSERT INTO TablesAudit (TableName, EventType, UserAccount, EventDate)
	SELECT 'Orders' AS TableName
	       ,CASE WHEN @Insert = 1 AND @Delete = 0 THEN 'INSERT'
				 WHEN @Insert = 1 AND @Delete = 1 THEN 'UPDATE'
				 WHEN @Insert = 0 AND @Delete = 1 THEN 'DELETE'
				 END AS Event
		   ,ORIGINAL_LOGIN() AS UserAccount
		   ,GETDATE() AS EventDate;


-- 4. Preventing changes to Products
CREATE TRIGGER PreventProductChanges
ON Products
INSTEAD OF UPDATE
AS
    RAISERROR('Updates of products are not permitted. Contact the database administrator if a change is needed', 16, 1);


-- 5. Checking stock before placing orders
-- Create a new trigger to confirm stock before ordering
CREATE TRIGGER ConfirmStock
ON Orders
INSTEAD OF INSERT
AS
	IF EXISTS (SELECT *
			   FROM Products AS p
			   INNER JOIN inserted AS i ON i.Product = p.Product
			   WHERE p.Quantity < i.Quantity)
	BEGIN
		RAISERROR ('You cannot place orders when there is no stock for the order''s product.', 16, 1);
	END
	ELSE
	BEGIN
		INSERT INTO Orders (OrderID, Customer, Product, Price, Currency, Quantity, WithDiscount, Discount, OrderDate, TotalAmount, Dispatched)
		SELECT OrderID, Customer, Product, Price, Currency, Quantity, WithDiscount, Discount, OrderDate, TotalAmount, Dispatched FROM inserted;
	END;


-- 6. Database Auditing
-- Create a new trigger
CREATE TRIGGER DatabaseAudit
-- Attach the trigger at the database level
ON DATABASE
-- Fire the trigger for all tables/ views events
FOR DDL_TABLE_VIEW_EVENTS
AS
	INSERT INTO DatabaseAudit (EventType, DatabaseName, SchemaName, Object, ObjectType, UserAccount, Query, EventTime)
	SELECT EVENTDATA().value('(/EVENT_INSTANCE/EventType)[1]', 'NVARCHAR(50)') AS EventType
		  ,EVENTDATA().value('(/EVENT_INSTANCE/DatabaseName)[1]', 'NVARCHAR(50)') AS DatabaseName
		  ,EVENTDATA().value('(/EVENT_INSTANCE/SchemaName)[1]', 'NVARCHAR(50)') AS SchemaName
		  ,EVENTDATA().value('(/EVENT_INSTANCE/ObjectName)[1]', 'NVARCHAR(100)') AS Object
		  ,EVENTDATA().value('(/EVENT_INSTANCE/ObjectType)[1]', 'NVARCHAR(50)') AS ObjectType
		  ,EVENTDATA().value('(/EVENT_INSTANCE/LoginName)[1]', 'NVARCHAR(100)') AS UserAccount
		  ,EVENTDATA().value('(/EVENT_INSTANCE/TSQLCommand/CommandText)[1]', 'NVARCHAR(MAX)') AS Query
		  ,EVENTDATA().value('(/EVENT_INSTANCE/PostTime)[1]', 'DATETIME') AS EventTime;


-- 7. Preventing Server Changes
-- Create a trigger to prevent database deletion
CREATE TRIGGER PreventDatabaseDelete
-- Attach the trigger at the server level
ON ALL SERVER
FOR DROP_DATABASE
AS
   PRINT 'You are not allowed to remove existing databases.';
   ROLLBACK;