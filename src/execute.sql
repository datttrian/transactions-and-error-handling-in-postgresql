-- Begin a new transaction
BEGIN;

-- Update RCOP752 to true if RCON2365 is over 5000000
UPDATE ffiec_reci
SET RCONP752 = 'true'
WHERE RCON2365 > 5000000;

-- Commit the transaction
COMMIT;

-- Select a count of records now true
SELECT COUNT(RCONP752)
FROM ffiec_reci
WHERE RCONP752 = 'true';


-- Begin a new transaction
BEGIN;

-- Update FIELD48 flag status if US State Government deposits are held
UPDATE ffiec_reci
SET FIELD48 = 'US-STATE-GOV'
WHERE RCON2203 > 0;

-- Update FIELD48 flag status if Foreign deposits are held
UPDATE ffiec_reci
SET FIELD48 = 'FOREIGN'
WHERE RCON2236 > 0;

-- Update FIELD48 flag status if US State Government and Foreign deposits are held
UPDATE ffiec_reci
SET FIELD48 = 'BOTH'
WHERE RCON2203 > 0
AND RCON2236 > 0;

-- Commit the transaction
COMMIT;

-- Select a count of records where FIELD48 is now BOTH
SELECT COUNT(FIELD48)
FROM ffiec_reci
WHERE FIELD48 = 'BOTH';


-- Update records to indicate nontransactionals over 100,000,000
UPDATE ffiec_reci
SET FIELD48 = '1'
WHERE RCONB550 > 100000000;

-- Select a count of records where the flag field is not 1
SELECT COUNT(*)
FROM ffiec_reci
WHERE FIELD48 != '1' or FIELD48 is null;


-- Create a new transaction with an isolation level of repeatable read
START TRANSACTION ISOLATION LEVEL REPEATABLE READ;

-- Count of records over 100000000
SELECT COUNT(RCON2210)
FROM ffiec_reci
WHERE RCON2210 > 100000000;

-- Count of records over 100000000
SELECT COUNT(RCON2210)
FROM ffiec_reci
WHERE RCON2210 > 100000000;

-- Commit the transaction
COMMIT;


-- Create a new transaction with a serializiable isolation level
START TRANSACTION ISOLATION LEVEL SERIALIZABLE;

-- Update records with a 50% reduction if greater than 100000
UPDATE ffiec_reci
SET RCON0352 = RCON0352 * 0.5
WHERE RCON0352 > 100000;

-- Commit the transaction
COMMIT;

-- Select a count of records still over 100000
SELECT COUNT(RCON0352)
FROM ffiec_reci
WHERE RCON0352 > 100000;


-- Begin a new transaction
BEGIN;

-- Update RCONP752 to true if RCON2365 is over 5000
UPDATE ffiec_reci
SET RCONP752 = 'true'
WHERE RCON2365 > 5000;

-- Oops that was supposed to be 5000000 undo the statement
ROLLBACK;

-- Update RCOP752 to true if RCON2365 is over 5000000
UPDATE ffiec_reci
SET RCONP752 = 'true'
WHERE RCON2365 > 5000000;

-- Commit the transaction
COMMIT;

-- Select a count of records now true
SELECT COUNT(RCONP752)
FROM ffiec_reci
WHERE RCONP752 = 'true';



-- Begin a new transaction
BEGIN;

-- Update FIELD48 flag status if US State Government deposits are held
UPDATE ffiec_reci
SET FIELD48 = 'US-STATE-GOV'
WHERE RCON2203 > 0;

-- Update FIELD48 flag status if Foreign deposits are held
UPDATE ffiec_reci
SET FIELD48 = 'FOREIGN'
WHERE RCON2236 > 0;

-- Update FIELD48 flag status if US State Government and Foreign deposits are held
UPDATE ffiec_reci
SET FIELD48 = 'BOOTH'
WHERE RCON2236 > 0
AND RCON2203 > 0;

-- Undo the mistake
ROLLBACK; 

-- Select a count of records that are booth (it should be 0)
SELECT COUNT(FIELD48)
FROM ffiec_reci
WHERE FIELD48 = 'BOOTH';


BEGIN;

-- Set the flag to indicate that they hold MMDAs where more than $5 million
UPDATE ffiec_reci 
SET FIELD48 = 'MMDA' 
WHERE RCON6810 > 5000000;

-- Set a savepoint
SAVEPOINT mmda_flag_set;

-- Rollback the whole transaction
ROLLBACK;

COMMIT;


BEGIN;

-- Update FIELD48 to indicate a positive MMDA when more than 6 million.
UPDATE ffiec_reci SET FIELD48 = 'MMDA+' WHERE RCON6810 > 6000000;

-- Set a savepoint
SAVEPOINT mmdaplus_flag_set;

-- Mistakenly set the flag to MMDA+ where the value is greater than 5 million
UPDATE ffiec_reci set FIELD48 = 'MMDA+' where RCON6810 > 5000000;

-- Roll back to savepoint
ROLLBACK TO mmdaplus_flag_set;

COMMIT;

-- Select count of records where the flag is MMDA+
SELECT count(FIELD48) from ffiec_reci where FIELD48 = 'MMDA+';

BEGIN;

-- Update FIELD48 to indicate a positive maturity rating when less than 2 million of maturing deposits.
UPDATE ffiec_reci 
SET FIELD48 = 'mature+' 
WHERE RCONHK07 + RCONHK12 + RCONHK08 + RCONHK13 < 2000000;

-- Set a savepoint
SAVEPOINT matureplus_flag_set;

-- Update FIELD48 to indicate a negative maturity rating when between 2 and 10 million
UPDATE ffiec_reci 
SET FIELD48 = 'mature-' 
WHERE RCONHK07 + RCONHK12 + RCONHK08 + RCONHK13 BETWEEN 2000000 AND 10000000;

-- Set a savepoint
SAVEPOINT matureminus_flag_set;

-- Update FIELD48 to indicate a double negative maturity rating when more than 10 million
UPDATE ffiec_reci 
SET FIELD48 = 'mature--' 
WHERE RCONHK07 + RCONHK12 + RCONHK08 + RCONHK13 > 10000000;

COMMIT;

-- Count the records where FIELD48 is a positive indicator
SELECT count(FIELD48) 
FROM ffiec_reci 
WHERE FIELD48 = 'mature+';


BEGIN;

-- Update FIELD48 to indicate a positive maturity rathing when less than 500 thousand.
UPDATE ffiec_reci 
SET FIELD48 = 'mature+' 
WHERE RCONHK12 + RCONHK13 < 500000;

-- Set a savepoint
SAVEPOINT matureplus_flag_set;

-- Update FIELD48 to indicate a negative maturity rathing when between 500 thousand and 1 million.
UPDATE ffiec_reci 
SET FIELD48 = 'mature-' 
WHERE RCONHK12 + RCONHK13 BETWEEN 500000 AND 1000000;

-- Set a savepoint
SAVEPOINT matureminus_flag_set;

-- Accidentailly update FIELD48 to indicate a double negative maturity rating when more than 100K
UPDATE ffiec_reci 
SET FIELD48 = 'mature--' 
WHERE RCONHK12 + RCONHK13 > 100000;

-- Rollback to before the last mistake
ROLLBACK TO matureminus_flag_set;

-- Select count of records with a double negative indicator
SELECT count(FIELD48) 
from ffiec_reci 
WHERE FIELD48 = 'mature--';



-- Create a new transaction with a repeatable read isolation level
START TRANSACTION ISOLATION LEVEL REPEATABLE READ;

-- Update records for banks that allow consumer deposit accounts
UPDATE ffiec_reci 
SET FIELD48 = 100 
WHERE RCONP752 = 'true';

-- Update records for banks that do not allow consumer deposit accounts
UPDATE ffiec_reci 
SET FIELD48 = 50 
WHERE RCONP752 = 'false';

-- Commit the transaction
COMMIT;


-- Create a new transaction with a repeatable read isolation level
START TRANSACTION ISOLATION LEVEL REPEATABLE READ;

-- Update records with a 35% reduction if greater than 1000000000
UPDATE ffiec_reci 
SET RCON2203 = CAST(RCON2203 AS FLOAT) * .65 
WHERE CAST(RCON2203 AS FLOAT) > 1000000000;

SAVEPOINT million;

-- Update records with a 25% reduction if greater than 500000000
UPDATE ffiec_reci 
SET RCON2203 = CAST(RCON2203 AS FLOAT) * .75 
WHERE CAST(RCON2203 AS FLOAT) > 500000000;

SAVEPOINT five_hundred;

-- Update records with a 13% reduction if greater than 300000000
UPDATE ffiec_reci 
SET RCON2203 = CAST(RCON2203 AS FLOAT) * .87 
WHERE CAST(RCON2203 AS FLOAT) > 300000000;

SAVEPOINT three_hundred;

-- Commit the transaction
COMMIT;

-- Select SUM the RCON2203 field
SELECT SUM(CAST(RCON2203 AS FLOAT)) 
FROM ffiec_reci 


-- Create a DO $$ function
DO $$ 
-- BEGIN a transaction block
BEGIN 
	INSERT INTO patients (a1c, glucose, fasting, created_on) 
    VALUES (5.8, 89, TRUE, '37-03-2020 01:15:54');
-- Add an EXCEPTION                                                         
EXCEPTION 
-- For all all other type of errors
WHEN others THEN 
	INSERT INTO errors (msg, detail) 
	VALUES ('failed to insert', 'bad date');
END;
-- Make sure to specify the language
$$ language 'plpgsql';

-- Select all the errors recorded
SELECT * FROM errors;


-- Add a DO function
DO $$ 
-- BEGIN a transaction block
BEGIN 
    INSERT INTO patients (a1c, glucose, fasting) 
    values (20, 89, TRUE);

-- Add an EXCEPTION                   
EXCEPTION 
-- Catch all exception types
WHEN others THEN
    INSERT INTO errors (msg, detail, context) VALUES 
  (
    'failed to insert', 
    'This a1c value is higher than clinically accepted norms.', 
    'a1c is typically less than 14'
  );
END;
-- Make sure to specify the language
$$ language 'plpgsql';

-- Select all the errors recorded
SELECT * FROM errors;


-- Make a DO function
DO $$
-- Open a transaction block
BEGIN
    -- Open a nested block
    BEGIN
    	INSERT INTO patients (a1c, glucose, fasting) 
        VALUES (5.6, 93, TRUE), (6.3, 111, TRUE),(4.7, 65, TRUE);
    -- Catch all exception types
    EXCEPTION WHEN others THEN
    	INSERT INTO errors (msg) VALUES ('failed to insert');
    -- End nested block
    END;
    -- Begin the second nested block
	BEGIN
    	UPDATE patients SET fasting = 'true' WHERE id=1;
    -- Catch all exception types
    EXCEPTION WHEN others THEN
    	INSERT INTO errors (msg) VALUES ('Inserted string into boolean.');
    -- End the second nested block
    END;
-- END the outer block
END;
$$ language 'plpgsql';
SELECT * FROM errors;


-- Make a DO function
DO $$
-- Open a transaction block
BEGIN
    INSERT INTO patients (a1c, glucose, fasting) 
    VALUES (7.5, null, TRUE);
-- Catch an Exception                                                               
EXCEPTION
	-- Make it catch not_null_constraint exception types
    WHEN not_null_violation THEN
    -- Insert the proper msg and detail
       INSERT INTO errors (msg, detail) 
       VALUES ('failed to insert', 'Glucose can not be null.');
END$$;
                                                                     
-- Select all the errors recorded
SELECT * FROM errors;


-- Make a DO function
DO $$
-- Open a transaction block
BEGIN
    INSERT INTO patients (a1c, glucose, fasting) values (20, null, TRUE);
-- Catch an Exception                                                               
EXCEPTION
	-- Make it catch check_violation exception types
    WHEN check_violation THEN
    	-- Insert the proper msg and detail
       INSERT INTO errors (msg, detail)
       VALUES ('failed to insert', 'A1C is higher than clinically accepted norms.');
    -- Make it catch not_null_constraint exception types
    WHEN not_null_violation THEN
    	-- Insert the proper msg and detail
       INSERT INTO errors (msg, detail)
       VALUES ('failed to insert', 'Glucose can not be null.');
END$$;
                                                                     
-- Select all the errors recorded
SELECT * FROM errors;


DO $$ 
-- Declare our variables
DECLARE
   exc_message text;
   exc_detail text;
BEGIN 
    INSERT INTO patients (a1c, glucose, fasting) 
    values (20, 89, TRUE);
EXCEPTION 
WHEN others THEN
    -- Get the exception message and detail via stacked diagnostics
	GET STACKED DIAGNOSTICS 
    	exc_message = MESSAGE_TEXT,
        exc_detail = PG_EXCEPTION_DETAIL;
    -- Record the exception message and detail in the errors table
    INSERT INTO errors (msg, detail) VALUES (exc_message, exc_detail);
END;
$$ language 'plpgsql';

-- Select all the errors recorded
SELECT * FROM errors;


DO $$
DECLARE
   exc_message text;
   exc_details text;
   -- Declare a variable, exc_context to hold the exception context
   exc_context text;
BEGIN
    BEGIN
    	INSERT INTO patients (a1c, glucose, fasting) values (5.6, 93, TRUE),
        	(6.3, 111, TRUE),(4.7, 65, TRUE);
    EXCEPTION
        WHEN others THEN
        -- Store the exception context in exc_context
        GET STACKED DIAGNOSTICS exc_message = MESSAGE_TEXT,
                                exc_context = PG_EXCEPTION_CONTEXT;
        -- Record both the msg and the context
        INSERT INTO errors (msg, context) 
           VALUES (exc_message, exc_context);
    END;
	BEGIN
    	UPDATE patients set fasting = 'true' where id=1;
    EXCEPTION
        WHEN others THEN
        -- Store the exception detail in exc_details
        GET STACKED DIAGNOSTICS exc_message = MESSAGE_TEXT,
                                exc_details = PG_EXCEPTION_DETAIL;
        INSERT INTO errors (msg, detail) 
           VALUES (exc_message, exc_details);
    END;
END$$;
SELECT * FROM errors;


-- Define our function signature
CREATE OR REPLACE FUNCTION debug_statement(
  sql_stmt TEXT
)
-- Declare our return type
RETURNS BOOLEAN AS $$
    DECLARE
        exc_state   TEXT;
        exc_msg     TEXT;
        exc_detail  TEXT;
        exc_context TEXT;
    BEGIN
        BEGIN
            -- Execute the statement passed in
            EXECUTE sql_stmt;
        EXCEPTION WHEN others THEN
            GET STACKED DIAGNOSTICS
                exc_state   = RETURNED_SQLSTATE,
                exc_msg     = MESSAGE_TEXT,
                exc_detail  = PG_EXCEPTION_DETAIL,
                exc_context = PG_EXCEPTION_CONTEXT;
            INSERT into errors (msg, state, detail, context) values (exc_msg, exc_state, exc_detail, exc_context);
            -- Return True to indicate the statement was debugged
            RETURN True;
        END;
        -- Return False to indicate the statement was not debugged
        RETURN False;
    END;
$$ LANGUAGE plpgsql;
SELECT debug_statement('INSERT INTO patients (a1c, glucose, fasting) values (20, 89, TRUE);')

