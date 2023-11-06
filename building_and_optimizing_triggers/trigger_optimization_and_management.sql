/*
Chapter 4. Trigger Optimization and Management
Learn to delete and modify triggers. Acquiant yourself with the way trigger management is done.
Learn how to investigate problematic triggers in practice.


$ Deleting Triggers

    Deleting Table and View Triggers

        DROP TRIGGER PreventNewDiscounts;


    Deleting Database Triggers

        DROP TRIGGER PreventNewDiscounts
        ON DATABASE;


    Deleting Server Triggers

        DROP TRIGGER DisallowLinkedServers
        ON ALL SERVER;
    

$ Disabling Triggers

    Disabiling Triggers on a Table

        DISABLE TRIGGER PreventNewDiscounts
        ON Discounts;


    Disabiling Triggers on a Table

        DISABLE TRIGGER PreventViewModifications
        ON DATABASE;


    Disabiling Triggers on a Server

        DISABLE TRIGGER DisallowLinkedServers
        ON ALL SERVER;


$ Enabling Triggers

    Enabling a Trigger on a Table

        ENABLE TRIGGER PreventNewDiscounts
        ON Discounts;


    Enabling a Trigger on a Database

        ENABLE TRIGGER PreventViewsModifications
        ON DATABASE;


    Enabiling a Trigger on a Server

        ENABLE TRIGGER DisallowLinkedServers
        ON ALL SERVER;    


$ Altering Triggers

    CREATE TRIGGER PreventDiscountsDelete
    ON Discounts
    INSTEAD OF DELETE
    AS
        PRINT 'You are not allowed to data from the Discounts table.';

    - Add the word "remove" to the message displayed to the user.

    ALTER TRIGGER PreventDiscountsDelete
    ON Discounts
    INSTEAD OF DELETE
    AS
        PRINT 'You are not allowed to remove data from the Discounts table.';


$ Trigger Management

    Queries to return Trigger info on a table/view
        SELECT * FROM sys.triggers;
        SELECT * FROM sys.trigger_events

    Queries to return Trigger info on the Server
        SELECT * FROM sys.server_triggers;
        SELECT * FROM sys.server_trigger_events;

    Query to return Trigger event type
        SELECT * FROM sys.trigger_event_types;


$ Trigger Management in Practice

    SELECT t.name AS TriggerName,
           t.parent_class_desc AS TriggerType,
           te.type_desc AS EventName,
           o.name AS AttachedTo,
           o.type_desc AS ObjectType
    FROM sys.triggers AS t
    INNER JOIN sys.trigger_events AS te ON te.object_id = t.object_id
    LEFT OUTER JOIN sys.objects AS o ON o.object_id = t.parent_id;


$ Troubleshooting Triggers

    You can track trigger executions using

        SELECT * FROM sys.dm_exec_trigger_stats;


$ Identifying triggers attached to a Table

    SELECT name AS TableName,
        object_id AS TableID
    FROM sys.objects
    WHERE name = 'Products';


EXERCISES
*/

-- 1. Removing Unwanted Triggers
-- Remove the trigger
DROP TRIGGER PreventNewDiscounts;

-- Remove the database trigger
DROP TRIGGER PreventTableDeletion
ON DATABASE;

-- Remove the server trigger
DROP TRIGGER DisallowLinkedServers
ON ALL SERVER;


-- 2. Modifying a trigger's definition
-- Fix the typo in the trigger message
ALTER TRIGGER PreventDiscountsDelete
ON Discounts
INSTEAD OF DELETE
AS
	PRINT 'You are not allowed to remove data from the Discounts table.';


-- 3. Disabiling a Trigger
-- Pause the trigger execution
DISABLE TRIGGER PreventOrdersUpdate
ON Orders;


-- 4. Re-enabling a Disabled Trigger
-- Resume the trigger execution
ENABLE TRIGGER PreventOrdersUpdate
ON Orders;


-- 5. Managing Existing Triggers
-- Get the disabled triggers
SELECT name,
	   object_id,
	   parent_class_desc
FROM sys.triggers
WHERE is_disabled = 1;

-- Check for unchanged server triggers
SELECT *
FROM sys.server_triggers
WHERE create_date = modify_date;

-- Get the database triggers
SELECT *
FROM sys.triggers
WHERE parent_class_desc = 'DATABASE';


-- 6. Keeping track of Trigger Executions
-- Modify the trigger to add new functionality
ALTER TRIGGER PreventOrdersUpdate
ON Orders
-- Prevent any row changes
INSTEAD OF UPDATE
AS
	-- Keep history of trigger executions
	INSERT INTO TriggerAudit (TriggerName, ExecutionDate)
	SELECT 'PreventOrdersUpdate', 
           GETDATE();

	RAISERROR ('Updates on "Orders" table are not permitted.
                Place a new order to add new products.', 16, 1);


-- 7. Identifying Problematic Triggers
-- Get the table ID
SELECT object_id AS TableID
FROM sys.objects
WHERE name = 'Orders';

-- Get the trigger name
SELECT t.name AS TriggerName
FROM sys.objects AS o
-- Join with the triggers table
INNER JOIN sys.triggers AS t ON t.parent_id = o.object_id
WHERE o.name = 'Orders';

SELECT t.name AS TriggerName
FROM sys.objects AS o
INNER JOIN sys.triggers AS t ON t.parent_id = o.object_id
-- Get the trigger events
INNER JOIN sys.trigger_events AS te ON te.object_id = t.object_id
WHERE o.name = 'Orders'
-- Filter for triggers reacting to new rows
AND te.type_desc = 'UPDATE';

SELECT t.name AS TriggerName,
	   OBJECT_DEFINITION(t.object_id) AS TriggerDefinition
FROM sys.objects AS o
INNER JOIN sys.triggers AS t ON t.parent_id = o.object_id
INNER JOIN sys.trigger_events AS te ON te.object_id = t.object_id
WHERE o.name = 'Orders'
AND te.type_desc = 'UPDATE';