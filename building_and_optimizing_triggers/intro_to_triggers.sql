/*
Chapter 1. Introduction to Triggers
An introduction to the basic conepts of SQL Server triggers. Create your first trigger using
T-SQL code. Learn how triggers are used and what alternatives exist.

$ What is a trigger?
A special type of stored procedure that is automatically executed when events occur
that modifies data: INSERT, UPDATE, DELETE


$ Types of Trigger (T-SQL)
    Data Manipulation Language (DML) Triggers
    - INSERT
    - UPDATE
    - DELETE

    Data Definition Language (DDL) Triggers
    - CREATE
    - ALTER
    - DROP

    Logon Triggers
    - LOGON


$ Types of Trigger (based on behavior)

    AFTER Trigger
    - The original statement executes
    - Additional statements are triggered

    Examples of AFTER Triggers
    - Rebuild an index after a large insert
    - Notify the admin when data is updated


    INSTEAD OF Trigger
    - The original statement is prevented from execution
    - A replacement statement is executed instead

    Examples of use cases
    - Prevent insertions
    - Prevent updates
    - Prevent deletions
    - Prevent object modifications
    - Notify the administrator


$ Trigger definition (with AFTER)

    CREATE TRIGGER ProductsTrigger
    ON PRODUCTS
    AFTER INSERT
    AS
    PRINT('An insert of data was made to the products table')


$ AFTER V. INSTEAD OF TRIGGERS

    CREATE TRIGGER FirstAfterTrigger
    ON Table1
    AFTER UPDATE
    AS
    {trigger_actions};


    CREATE TRIGGER FirstInsteadOfTrigger
    ON Table2
    INSTEAD OF UPDATE
    AS
    {trigger_actions};

EXERCISES
*/

/*
1. Types of Triggers

Data Manipulation Language (DML) triggers are executed when a user or process tries
to modify data in a given table. A trigger can be fired in response to these statements.

What are the three DML statements that can be used to fire triggers?

DELETE, INSERT, UPDATE
*/

-- 2. Creating your first trigger
CREATE TRIGGER PreventDiscountDelete
ON Discounts
INSTEAD OF DELETE
AS
PRINT ('You are not allowed to delete data from the Discounts table.');


-- 3. Praciting creating triggers
CREATE TRIGGER OrdersUpdatedRows
ON Orders
AFTER UPDATE
AS
    INSERT INTO OrdersUpdate(OrderId, OrderDate, ModifyDate)
    SELECT OrderId, OrderDate, GETDATE()
    FROM inserted;


-- 4. Creating a trigger to keep track of data changes
CREATE TRIGGER ProductsNewItems
ON Products
AFTER INSERT
AS
    INSERT INTO ProductsHistory(Product, Price, Currency, FirstAdded)
    SELECT Product, Price, Currency, GETDATE()
    FROM inserted;