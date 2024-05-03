# Transactions and Error Handling in PostgreSQL

## Getting to Know Transactions

### Making our first transaction

Now you're ready to build your first transaction. As mentioned in the
slides, you are working with data from the FFEIC, which is the
organization in the US that sets bank standards and reporting formats.
Recently they changed the rules for reporting if you provide consumer
deposit accounts to being true only if you have more than \$5,000,000 in
brokered deposits.

Let's use a transaction to make that update safely. The "Provides
Consumer Deposits" flag is in the `RCONP752` column and the brokered
deposits is in the `RCON2365` column.

**Instructions**

- `BEGIN` the transaction.
- Update the `RCONP752` field to be `'true'` where `RCON2365` is bigger
  than \$5,000,000.
- Close out the transaction with `COMMIT`.
- Select the count of rows where `RCONP752` is `'true'`.

**Answer**

```{python}
%%sql
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
```

### Multiple statement transactions

Now let's use multiple statements in a transaction to set a flag in
`FIELD48` based on if it holds US state government assets represented in
`RCON2203`, foreign assets represented in `RCON2236`, or both.

The values for `FIELD48` should be `'US-STATE-GOV'`, `'FOREIGN'`, or
`'BOTH'` respectively. Flag fields like this are common in government
data sets, and are great for categorizing records.

**Instructions**

- Begin a transaction.
- Build 3 update statements to detect each condition in the column and
  set the `FIELD48` flag to the proper value.
- End the transaction.
- Select a count of records where the flag is set to `'BOTH'`.

**Answer**

```{python}
%%sql
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
```

### Single statement transactions

Now you will work with a single statement transaction. Some types of
saving accounts hold money that cannot be withdrawn on demand for
individuals and corporations. The amount of the heldback money is stored
in the `RCONB550` field. These types of accounts promote bank stability
and generate dependable revenue for the financial institution via fees
and loan proceeds. Let's update `FIELD48` to be `'1'` for each of these
institutions to signify that they have this stability when it's over
\$100M.

**Instructions**

- Update the flag in `FIELD48` to be `'1'` when `RCONB550` is greater
  than \$100,000,000.
- Count the number of records where `FIELD48` is not `'1'`.

**Answer**

```{python}
%%sql
-- Update records to indicate nontransactionals over 100,000,000
UPDATE ffiec_reci
SET FIELD48 = '1'
WHERE RCONB550 > 100000000;

-- Select a count of records where the flag field is not 1
SELECT COUNT(*)
FROM ffiec_reci
WHERE FIELD48 != '1' or FIELD48 is null;
```

### Using an isolation level

As seen in the video, sometimes it's important to be able to select an
isolation level for an individual transaction. It's best to use
`START TRANSACTION` to do this which is an alias of `BEGIN TRANSACTION`
to make it clear something is different. You can specify an
`ISOLATION LEVEL` when starting the transaction.

Here we are going to use `REPEATABLE READ` which protects us from dirty
reads, nonrepeatable reads, and phantom reads. In the FFEIC data,
`RCON2210` is the demand deposits field, and tracks all outstanding
checking accounts, bank-issued checks and unposted credits. They can be
a liability to a bank if there was a funds rush for any reason. Let's
find all those banks with over \$100,000,000 in demand deposits.

**Instructions**

- Start a transaction with repeatable read.
- Select all the records with `RCON2210` over \$100,000,000 in demands
  deposits.
- Select all the records with `RCON2210` still over \$100,000,000 in
  demands deposits.
- Commit the transaction.

**Answer**

```{python}
%%sql
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
```

### Isolation levels and transactions

`SERIALIZABLE` is an isolation level that takes a snapshot of the record
when the first query or update statement is issued, and errors if the
data is altered in any way outside of the transaction. Note that the
transaction can do other work, such as declare variables, prior to the
first query.

You'll be using the FFIEC dataset again to work with data where the
annual change in savings deposits `RCON0352` is affected by a large
offset.

**Instructions**

- Start a transaction in `SERIALIZABLE` mode.
- Update all the the records where `RCON0352` is greater than 100,000
  with a 50% reduction.
- `COMMIT` the transaction.
- Select the count of the records still with an `RCON0352` greater than
  100,000.

**Answer**

```{python}
%%sql
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
```

## Rolling Back and Savepoints

### Using rollbacks

Recently the FFIEC changed the reporting requirement for bank's that
provide consumer deposit accounts if they have more than \$5,000,000 in
brokered deposits. Let's use a transaction to make that update safely.
The "Provides Consumer Deposits" flag is in the `RCONP752` column and
the amount of brokered deposits is in the `RCON2365` column.

**Instructions**

- BEGIN the transaction.
- Update the `RCONP752` field to be true if `RCON2365` \> 5000000.
- Undo the mistake.
- Update the `RCONP752` field to be `'true'` if `RCON2365` > 5000000 and end the transaction.
- Select the count of rows where `RCONP752` is `'true'`.

**Answer**

```{python}
%%sql
-- Begin a new transaction
BEGIN;

-- Update RCONP752 to true if RCON2365 is over 5000
UPDATE ffiec_reci
SET RCONP752 = 'true'
WHERE RCON2365 > 5000;

-- Oops that was supposed to be 5000000 undo the statement
ROLLBACK;
```

```{python}
%%sql
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
```

### Multistatement Rollbacks

Now let's use multiple statements in a transaction to set a flag in
`FIELD48` based on if it holds US state government assets represented in
`RCON2203`, foreign assets represented in `RCON2236`, or both. The
values for `FIELD48` should be `'US-STATE-GOV'`, `'FOREIGN'`, or
`'BOTH'` respectively. However, You've made a mistake in the statement
for both.

**Instructions**

- Build 3 update statements to detect each condition and set the flag.
- Undo the mistake of setting it to `'BOOTH'` instead of `'BOTH'` by
  rolling back the transaction.
- Select a count of records where the flag is set to `'BOOTH'`.

**Answer**

```{python}
%%sql
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
```

### Working with a single savepoint

Banks that carry large value in Money Market Deposit Accounts (MMDA) are
often resilient to downturns in the economy. In order to classify banks,
we'll use a flag field such as `FIELD48` to store information useful for
further processing. Let's flag banks with over 5000000.

**Instructions**

- Create a transaction.
- Update `FIELD48` to `MMDA` if `RCON6810` (MMDA value) is greater than
  `5000000`.
- Set a savepoint named `mmda_flag_set`.
- Rollback the whole transaction.

**Answer**

```{python}
%%sql
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
```

### Rolling back with a savepoint

Building upon the last exercise, it turns out that banks with more than
\$6 million in MMDAs are twice as likely to sustain during a downturn
than those with between \$5 and 6 million in that same asset class. Here
I've made a mistake in the sample code, and we need to rollback to the
save point to maintain data integrity.

**Instructions**

- Inside a transaction set `FIELD48` to `'MMDA+'` where `RCON6810` (MMDA
  amount) is greater than \$6 million.
- Set `mmdaplus_flag_set` as a savepoint.
- Set `FIELD48` to `'MMDA+'` where `RCON6810` (MMDA amount) is greater
  than \$5 million (this is a mistake).
- Undo back to `mmdaplus_flag_set`, end the transaction, and count the
  `'MMDA+'` records.

**Answer**

```{python}
%%sql
BEGIN;

-- Update FIELD48 to indicate a positive MMDA when more than $6 million.
UPDATE ffiec_reci SET FIELD48 = 'MMDA+' WHERE RCON6810 > 6000000;

-- Set a savepoint
SAVEPOINT mmdaplus_flag_set;

-- Mistakenly set the flag to MMDA+ where the value is greater than $5 million
UPDATE ffiec_reci set FIELD48 = 'MMDA+' where RCON6810 > 5000000;

-- Roll back to savepoint
ROLLBACK TO mmdaplus_flag_set;

COMMIT;

-- Select count of records where the flag is MMDA+
SELECT count(FIELD48) from ffiec_reci where FIELD48 = 'MMDA+';
```

### Multiple savepoints

A risky area for banks during a distressed market is the number of
maturing time deposits in the near future. It's highly likely that these
timed deposits will be withdrawn to make other financial moves by the
depositor. `RCONHK07 + RCONHK12` stores those maturing in the next three
months and `RCONHK08 + RCONHK13` stores those expiring between 3 and 12
months.

If the total amounts in these columns are higher than \$10 million it
can be a drag on available funds to cover withdrawals and would receive
a negative rating. Additionally, if there is less than \$2 million, it
has been shown to be a positive factor.

**Instructions**

- Within a transaction set `FIELD48` to `mature+` if total maturing
  deposits is less than \$2 million and set a savepoint
  `matureplus_flag_set`.
- Set `FIELD48` to `mature-` if total maturing deposits is between \$2
  million and \$10 million then set a savepoint `matureminus_flag_set`.
- Set `FIELD48` to `mature--` if total maturing deposits is greater than
  \$10 million.
- Count all the banks with a positive deposit maturity schedule.

**Answer**

```{python}
%%sql
BEGIN;

-- Update FIELD48 to indicate a positive maturity rating when less than $2 million of maturing deposits.
UPDATE ffiec_reci 
SET FIELD48 = 'mature+' 
WHERE RCONHK07 + RCONHK12 + RCONHK08 + RCONHK13 < 2000000;

-- Set a savepoint
SAVEPOINT matureplus_flag_set;

-- Update FIELD48 to indicate a negative maturity rating when between $2 and $10 million
UPDATE ffiec_reci 
SET FIELD48 = 'mature-' 
WHERE RCONHK07 + RCONHK12 + RCONHK08 + RCONHK13 BETWEEN 2000000 AND 10000000;

-- Set a savepoint
SAVEPOINT matureminus_flag_set;

-- Update FIELD48 to indicate a double negative maturity rating when more than $10 million
UPDATE ffiec_reci 
SET FIELD48 = 'mature--' 
WHERE RCONHK07 + RCONHK12 + RCONHK08 + RCONHK13 > 10000000;

COMMIT;

-- Count the records where FIELD48 is a positive indicator
SELECT count(FIELD48) 
FROM ffiec_reci 
WHERE FIELD48 = 'mature+';
```

### Savepoints and rolling back

Continuing to think about the amount of maturing time deposits in the
near future. The ones over 250K have the most impact on the outcomes
seen during the 2008 market.

`RCONHK12` (\>=250k) stores those maturing in the next three months and
`RCONHK13` (\>=250k) stores those expiring between 3 and 12 months. If
these are higher than \$1 million dollars it can cause a funds shortage
at a bank as these are typically larger customers of the bank who might
also pull other assets. Again, there is a positive factor if these are
less than \$500K.

I've made a few mistakes in my code by setting the wrong value for those
over \$500 thousand!

**Instructions**

- Within a transaction set `FIELD48` to `mature+` if total maturing
  deposits is less than \$500 thousand and set a savepoint
  `matureplus_flag_set`.
- Set `FIELD48` to `mature-` if total maturing deposits is between \$500
  thousand and \$1 million then set a savepoint `matureminus_flag_set`.
- Set `FIELD48` to `mature--` if total maturing deposits is greater than
  \$100 thousand (not \$1 million) - "accidentally" omitting a `0`.
- Undo back to just after we set the `mature-` records and count all the
  banks with a `mature--` deposit maturity schedule.

**Answer**

```{python}
%%sql
BEGIN;

-- Update FIELD48 to indicate a positive maturity rathing when less than $500 thousand.
UPDATE ffiec_reci 
SET FIELD48 = 'mature+' 
WHERE RCONHK12 + RCONHK13 < 500000;

-- Set a savepoint
SAVEPOINT matureplus_flag_set;

-- Update FIELD48 to indicate a negative maturity rathing when between $500 thousand and $1 million.
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
```

### Working with repeatable read

With the video in mind, let's do some hands on work with a repeatable
read transaction. We want to set a "stability" factor for a bank's
in-house assets if they allow consumer deposits. We'll do this by
setting a custom field, `FIELD48`, equal to a retainer value if the bank
allows consumer deposit accounts as indicated in `RCONP752`.

Interference from an external transaction would alter the application of
our factor. Repeatable read protects your transaction from outside
sources changing data that was available to us when we ran our first
query in the transaction.

**Instructions**

- `Start` a transactions in the repeatable read isolation level.
- End the transaction.

**Answer**

```{python}
%%sql
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
```

### Savepoint's effect on isolation levels

Now that you've explored savepoints, let's use them to set up a series
of transactions that all need to work from the same initial snapshot of
the data. `REPEATABLE READ` is an isolation level that enables us to
give each statement inside the transaction the same data as the first
statement operated on instead of the data as a result of the prior
statement(s).

Recently, the FFEIC allowed for a progressive curtailment of foreign
deposits, field `RCON2203` in thousands, in the dataset. The new
curtailment is 35% for more than \$1 billion, 25% for more than \$500
million, and 13% for more than \$300 million. It's possible to order
these statements to avoid reducing the data more than once. However,
statements have the data before any adjustments with `REPEATABLE READ`.

**Instructions**

- Start a `REPEATABLE READ` transaction.
- Reduce `RCON2203` by 35% if more than \$1 billion, by 25% if more than
  \$500 million, or by 13% if more than \$300 million with a `SAVEPOINT`
  after each.
- Close the transaction.
- Total the `RCON2203` field.

**Answer**

```{python}
%%sql
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
```

## Handling Exceptions

### Writing do statements

Commonly when cleaning data, we'll get data that will have bad dates in
it. This would cause an exception and halt our SQL statement; however,
by using a `DO` function with an exception handler, our statement will
run to completion. Let's see how we can handle that type of exception
with the `patients` table and the `created_on` column. This will also
give us a chance to use a `DO` style function.

**Instructions**

- Create a `DO` function to initiate catching an exception.
- BEGIN a transaction where you `INSERT` the row (`a1c` = `5.8`,
  `glucose` = `89`, `fasting` = `TRUE`, and `created_on` =
  '`37-03-2020 01:15:54'`) into patients.
- Add an `EXCEPTION` handler, that inserts `'bad date'` in the `detail`
  column of the `errors` table in case of an error.
- Specify the `'plpgsql'` language .

**Answer**

```{python}
%%sql
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
```

### Handling exceptions

In the slides, we discussed providing proper context for resolution. One
area that is often overlooked when recording messages is the deeper
reasoning for them. Oftentimes errors are generic like "Bad value" or
"Invalid date." However, we can use details and context to enrich those
messages.

Here we are going to work with A1C which is the percentage of red blood
cells that have sugar attached to the hemoglobin. Typically fasting
ranges are below 5.7% for non-affected patients, 5.7% to 6.4% for
prediabetes, and over 6.5% is typically an indicator of unmanaged
diabetes.

**Instructions**

- Complete the transaction block by filling out the `DO` and `BEGIN`
  statements where applicable.
- Add an exception that inserts `'a1c is typically less than 14'` into
  the `context` column of the `errors` table.
- End the exception by specifying the procedural language used.

**Answer**

```{python}
%%sql
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
```

### Multiple exception blocks

Since `ROLLBACK TO` and `SAVEPOINT` can not be used in functions with
exception handlers, we have a way to emulate the same behavior though
using nested blocks. These nested blocks are used to group and order the
statements in the order that they depend on each other. Here you are
going to insert a block of records with an exception handler which
emulates a `SAVEPOINT`, then update a record with an exception handler.
That update statement will error, and the exception handler will
automatically rollback just that block.

**Instructions**

- In the first block, insert the following records into `patients`
  (`a1c`=`5.6`, `glucose`=`93`, and `fasting`=`TRUE`),
  `(6.3, 111, TRUE)` `(4.7, 65, TRUE)` with an `EXCEPTION` handler that
  inserts `'failed to insert'` as the `msg` into errors.
- Open a second nested block and update the patient with the ID of 1 to
  have a `fasting` value of `'true'` with exception handling that
  records to the `errors` table with a `msg` of
  `'Inserted string into boolean.'`.
- `END` both blocks.

**Answer**

```{python}
%%sql
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
```

### Capturing specific exceptions

Let's build a DO function that captures when glucose is set to null, and
logs a message stating explicitly that Glucose can not be null.

**Instructions**

- Inside of the `BEGIN` block of the DO function, `INSERT` into
  `patients` the row (`a1c`=`7.5`, `glucose`=`null`, and `fasting`=
  `TRUE`).
- Add a `not_null_violation` exception that inserts
  `"Glucose can not be null."` in the detail column of errors in case of
  an error.

**Answer**

```{python}
%%sql
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
```

### Logging messages on specific exceptions

One of the best uses of catching multiple specific exception is to
distinctly handle and log unique error message that help you understand
exactly why an exception occurred. Let's apply this in a scenario where
both error conditions are possible. We'll discuss after the exercise why
it capture the specific message it did.

**Instructions**

- Build an exception handler for a `not_null_violation`.
- Insert `"failed to insert"` as the `msg`, `Glucose can not be null.`
  as the `detail` into the `errors` table if a `not_null_violation`
  occurs.

**Answer**

```{python}
%%sql
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
```

## Stacked Diagnostics

### Getting stacked diagnostics

Stacked diagnostics can get the internal PostgreSQL error message and
exception details. Let's revisit our patients table and try to add an
A1C that is above the testing limit. This will cause a check constraint
exception that we can capture. We can use the stacked diagnostics in the
exception handler to enrich our error recording.

**Instructions**

- `DECLARE` two variables `exc_message` and `exc_detail` as text.
- Get the diagnostics stack and set `exc_message` to be the
  `MESSAGE_TEXT` and `exc_detail` to be the `PG_EXCEPTION_DETAIL`.
- Insert `exc_message` and `exc_detail` into the `msg` and `detail`
  field of the errors table.

**Answer**

```{python}
%%sql
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
```

### Capturing a context stack

Getting the stack context, which is like a stack trace in other
languages, is a powerful way to debug complex and nested functions.

In the code below, we want to capture the stack context and record it in
the exception handlers of both nested blocks. Then, we want to review
its output in the errors table to help debug what's causing the
exception in this function.

**Instructions**

- Declare a text variable, `exc_context`, to hold the stack context.
- Store the `PG_EXCEPTION_CONTEXT` in our `exc_context` variable in the
  first handler.
- Store the `PG_EXCEPTION_DETAIL` in our `exc_detail` variable in the
  second handler.
- Record both the error message and the stack context in both blocks.

**Answer**

```{python}
%%sql
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
```

### Creating named functions and declaring variables

Now that you've seen a powerful debugging function in action, let's
build one of your own. First, start by using defining the function
signature which supplied the function name, any parameters, and a return
type. After that point, it's the same as a `DO` function.

**Instructions**

- Define a function named `debug_statement` that takes a SQL statement
  as `sql_stmt`.
- The return type of the function should be a `BOOLEAN`.
- The function should execute the supplied SQL statement and catch any
  exception.
- The function should return `True` if it triggers debugging and `False`
  if it does not.

**Answer**

```{python}
%%sql
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
```
