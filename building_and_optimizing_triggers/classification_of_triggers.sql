/*
Chapter 2. Classification of Triggers

Learn about different types of SQL Server triggers: AFTER triggers (DML), INSTEAD OF triggers (DML),
DDL triggers, and LOGON triggers/

$ AFTER triggers (DML)

    An AFTER trigger is used for DML (Data Manipulation Language) statements to perform one or more actions.
    - The actions inside of a trigger are performed only after the DML event is finished.
    - Used with INSERT, UPDATE, and DELETE statements for tables or views.


$ AFTER trigger prerequisites
    - Table or view needed for DML statements
    - A trigger must be attached to a database object
    
    CRAETE TRIGGER TrackRetiredProducts
    ON Products
    AFTER DELETE
    AS
        INSERT INTO RetiredProducts (Product, Measure)
        SELECT Product, Measure
        FROM deleted;


$ "inserted" and  "deleted" Tables
    - Special tables used by DML triggers
    - Created automatically by SQL Server
    
    | Special Table | INSERT   | UPDATE       | DELETE       |
    | ------------- | -------- | ------------ | ------------ |
    | inserted      | new rows | new rows     |      N/A     |
    | deleted       |    N/A   | updated rows | removed rows |


$ The complete AFTER trigger

    - The deleted table holds the records removed from the Products table.
    - The deleted table's records can be inserted into another table for record keeping purposes.

    CREATE TRIGGER TrackRetiredProducts
    ON Products
    AFTER DELETE
    AS
        INSERT INTO RetiredProducts (Product, Measure)
        SELECT Product, Measure
        FROM deleted;


$ INSTEAD OF triggers (DML)

    - INSTEAD OF triggers can only used for Data Manipulation Language statements: INSERT, UPDATE, DELETE
    
    $ Definition and Properties
    
        - An INSTEAD OF trigger will perform an additional set of actions when fired, in place of the event that
          fired the trigger.
        - The event that fires an INSTEAD OF type trigger is NOT run.


$ INSTEAD OF trigger prerequisites

    For the example, the "Orders" table that holds details of the orders placed by
    the Fresh Fruit Delivery company's customers

    The trigger that is created should prevent updates to existing entries in this table.
    - Ensures that orders cannot be modified.


$ INSTEAD OF trigger definition

    CREATE TRIGGER PreventOrdersUpdate
    ON Orders
    INSTEAD OF UPDATE
    AS
        RAISERROR ('Updates on "Orders" table are not permitted.
                    Place a new order to add new products', 16, 1);


$ Data Definition Language (DDL) Triggers

    !!!!!!!!!!  IMPORTANT  !!!!!!!!!!!!!!

    Data Manipulation Language Triggers
    - Events associated with DML statements INSERT, UPDATE, DELETE
    - Used with AFTER or INSTEAD OF
    - Attach to tables or views
    - "inserted" and "deleted" special tables

    Data Definition Language Triggers
    - Events associated with DDL statements CREATE, ALTER, DROP
    - Only used with the AFTER statement
    - Attached to databases or servers
    - No special tables


$ AFTER and FOR

    AFTER = FOR
    - The AFTER and FOR keywords in SQL Server return the same results.
    * To reduce confusion, the FOR keyword is used in DDL triggers. The AFTER keyword is used for DML triggers.


$ DDL trigger definition
    - DDL triggers are tied to the database level.

    CREATE TRIGGER TrackTableChanges
    ON DATABASE
    FOR CREATE_TABLE,
        ALTER_TABLE,
        DROP_TABLE
    AS
        INSERT INTO TablesChangeLog (EventData, ChangedBy)
        VALUES (EVENTDATA(), USER);


$ Preventing the triggering events for DML triggers

    CREATE TRIGGER PreventTableDeletion
    ON DATABASE
    FOR DROP_TABLE
    AS
        RAISERROR('You are not allowed to remove tables from this database.', 16, 1)
        ROLLBACK;


$ LOGON Triggers

    - Performs a set of actions when fired.
    - The actions are performed for LOGON events.
    - AFTER authentication phase, but BEFORE the session is created.


$ LOGON trigger prerequisties

    - Trigger firing event -> LOGON
    - Description of the trigger -> Audit Successful / failed logons to the server
    - Trigger name -> LogonAudit


$ LOGON Trigger Definition

    A LOGON Trigger can only be attached at the SERVER LEVEL.

    
    CREATE TRIGGER LogonAudit
    ON ALL SERVER WITH EXECUTE AS 'sa'
    FOR LOGON
    AS
        INSERT INTO ServerLogonLog
            (LoginName, LoginDate, SessionID, SourceIPAddress)
        SELECT ORIGINAL_LOGIN(), GETDATE(), @@SPID, client_net_address
        FROM SYS.DM_EXEC_CONNECTIONS WHERE session_id = @@SPID;

    - 'sa' is a built-in administrator account that has full permissions on the server running it.


EXERCISES
*/

-- 1. Tracking retired products
CREATE TRIGGER TrackRetiredProducts
ON Products
AFTER DELETE
AS
	INSERT INTO RetiredProducts (Product, Measure)
	SELECT Product, Measure
	FROM deleted;


-- 2. The TrackRetiredProducts trigger in action
-- Remove the products that will be retired
DELETE FROM Products
WHERE Product IN ('Cloudberry', 'Guava', 'Nance', 'Yuzu');

-- Verify the output of the history table
SELECT * FROM RetiredProducts;


/*
3. Praticing with AFTER triggers

Create three new triggers on some tables, with the follwing requirements:
    - Keep track of canceled orders (rows deleted from the `Orders` table). Their details will be kept in the table
      `CanceledOrders` upon removal.
    - Keep track of discount changes in the table `Discounts`. Both the old and the new values will be copied to the
      `DiscountHistory` table.
    - Send an email to the Sales team via the `SendEmailtoSales` stored procedure when a new order is placed.
*/
-- Create a new trigger for canceled orders
CREATE TRIGGER KeepCanceledOrders
ON Orders
AFTER DELETE
AS 
	INSERT INTO CanceledOrders
	SELECT * FROM deleted;


-- Create a new trigger to keep track of discounts
CREATE TRIGGER CustomerDiscountHistory
ON Discounts
AFTER UPDATE
AS
	-- Store old and new values into the `DiscountsHistory` table
	INSERT INTO DiscountsHistory (Customer, OldDiscount, NewDiscount, ChangeDate)
	SELECT i.Customer, d.Discount, i.Discount, GETDATE()
	FROM inserted AS i
	INNER JOIN deleted AS d ON i.Customer = d.Customer;


-- Notify the Sales team of new orders
CREATE TRIGGER NewOrderAlert
ON Orders
AFTER INSERT
AS
	EXECUTE SendEmailtoSales;


-- 4. Preventing changes to Orders
-- Create the trigger
CREATE TRIGGER PreventOrdersUpdate
ON Orders
INSTEAD OF UPDATE
AS
	RAISERROR ('Updates on "Orders" table are not permitted.
                Place a new order to add new products.', 16, 1);


-- 5. Creating the PreventNewDiscounts trigger
-- Create a new trigger
CREATE TRIGGER PreventNewDiscounts
ON Discounts
INSTEAD OF INSERT
AS
	RAISERROR ('You are not allowed to add discounts for existing customers.
                Contact the Sales Manager for more details.', 16, 1);


-- 6. Tracking table changes
-- Create the trigger to log table info
CREATE TRIGGER TrackTableChanges
ON DATABASE
FOR CREATE_TABLE,
	ALTER_TABLE,
	DROP_TABLE
AS
	INSERT INTO TablesChangeLog (EventData, ChangedBy)
    VALUES (EVENTDATA(), USER);


-- 7. Create the trigger to log table info
CREATE TRIGGER TrackTableChanges
ON DATABASE
FOR CREATE_TABLE,
	ALTER_TABLE,
	DROP_TABLE
AS
	INSERT INTO ___ (EventData, ChangedBy)
    VALUES (EVENTDATA(), USER);


-- 8. Preventing table deletion
-- Create the trigger to log table info
CREATE TRIGGER TrackTableChanges
ON DATABASE
FOR CREATE_TABLE,
	ALTER_TABLE,
	DROP_TABLE
AS
	INSERT INTO TablesChangeLog (EventData, ChangedBy)
    VALUES (EVENTDATA(), USER);


-- 9. Enhancing database security
-- Create a trigger firing when users log on to the server
CREATE TRIGGER LogonAudit
-- Use ALL SERVER to create a server-level trigger
ON ALL SERVER WITH EXECUTE AS 'sa'
-- The trigger should fire after a logon
AFTER LOGON
AS
	-- Save user details in the audit table
	INSERT INTO ServerLogonLog (LoginName, LoginDate, SessionID, SourceIPAddress)
	SELECT ORIGINAL_LOGIN(), GETDATE(), @@SPID, client_net_address
	FROM SYS.DM_EXEC_CONNECTIONS WHERE session_id = @@SPID;