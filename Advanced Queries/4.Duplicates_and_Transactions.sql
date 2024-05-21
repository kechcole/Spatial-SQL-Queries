-- ADVANCED QUERIES FOR SPATIAL DATA MANAGEMENT, BY C. K. Kechir 
-- DUPLICATES AND TRANSACTIONS.
-- Authors: Collins Kipkorir Kechir
-- LinkedIn : www.linkedin.com/in/collins-kechir-068289189
-- X : @kechircollins
-- Github : https//github.com/kechcole

-- The code in this book is free. You can copy, modify and distribute non-trivial part of the code 
-- with no restrictions, according to the terms of the Creative Commons CC0 1.0 licence
-- Nevertheless, the acknowledgement of the authorship is appreciated.




-----------------------------------------------------------------------------------------------------
--					 1. Transactions 
-- A transaction starts with 'begin' ststement then ends with either 
-- 'rollback' or 'commit' 

-- Count all rows 
SELECT COUNT(*) FROM "US Election".results WHERE STATE = 'ALASKA';

-- Select unique data 
SELECT COUNT(*)
FROM (
     SELECT DISTINCT * FROM "US Election".results ) ;


-- Log transactions so as to retrieve or commit to disk changes 
BEGIN ;
DELETE FROM "US Election".results 
WHERE STATE = 'ALASKA';

-- Retrieve data 
ROLLBACK;

-- Commit 
COMMIT;


-- 2. Add primary key to the table 
ALTER TABLE "US Election".results ADD COLUMN id SERIAL PRIMARY KEY;
-- Add non primary key 
ALTER TABLE "US Election".results ADD COLUMN row_num GENERATED ALWAYS AS IDENTITY;




---------------------------------------------------------------------------------------------------
-- 			2. Duplicates.

-------------------------------------------------------
-- Solution 1. Delete using a unique identifier 
-------------------------------------------------------
-- Identify duplicates 
SELECT year, state, county_name, candidate, count(*)
FROM "US Election".results
GROUP BY year, state, county_name, candidate, candidatevotes
HAVING count(*) > 1;

-- Delete those with two duplicates 
BEGIN;
DELETE FROM "US Election".results
WHERE id in (
	SELECT max(id)
	FROM "US Election".results
	GROUP BY year, state, county_name, candidate, candidatevotes
	HAVING count(*) > 1
	);
ROLLBACK; 

-- WEAKNES. 1) Cannot delete records with multiple duplicate records.


-------------------------------------------------
--     Solution 2. Self Join.          ---------
-------------------------------------------------
-- Identify duplicates 
SELECT year, state, county_name, candidate, candidatevotes, count(*)
FROM "US Election".results
GROUP BY year, state, county_name, candidate, candidatevotes
HAVING count(*) > 1;

-- Identify duplicates by self join the tables on duplicated columns 
SELECT t2.id 
FROM "US Election".results AS t1
JOIN "US Election".results AS t2 
ON t1.year = t2.year AND t1.state = t2.state AND t1.county_name = t2.county_name AND
   t1.candidate = t2.candidate AND t1.candidatevotes = t2.candidatevotes
WHERE t1.id < t2.id ;

-- Delete duplicates
BEGIN;
DELETE FROM "US Election".results
WHERE id IN (
	SELECT t2.id 
	FROM "US Election".results AS t1
	JOIN "US Election".results AS t2 
	ON t1.year = t2.year AND t1.state = t2.state AND t1.county_name = t2.county_name AND
	   t1.candidate = t2.candidate AND t1.candidatevotes = t2.candidatevotes
	WHERE t1.id < t2.id 
	) ;
ROLLBACK;


-------------------------------------------------
--     Solution 3. Using MIN function.  ---------
-------------------------------------------------
-- Suitable when there multiple duplicates for an entity 
-- Identify duplicates 
SELECT * FROM "US Election".results
WHERE id NOT IN (
	SELECT MIN(id)
	FROM "US Election".results
	GROUP BY year, state, county_name, candidate, candidatevotes 
	ORDER BY MIN(id)
	) ;
	
-- Identify unique records in duplicated colums 
SELECT year, state, county_name, candidate, candidatevotes
FROM "US Election".results
GROUP BY year, state, county_name, candidate, candidatevotes ;

-- Get the first record record of unique row
SELECT year, state, county_name, candidate, candidatevotes, MIN(id)
FROM "US Election".results
GROUP BY year, state, county_name, candidate , candidatevotes
ORDER BY MIN(id);

-- Maintain the unique records by deleting all other rows 
BEGIN;
DELETE FROM "US Election".results
WHERE id NOT IN (
	SELECT MIN(id)
	FROM "US Election".results
	GROUP BY year, state, county_name, candidate, candidatevotes 
	ORDER BY MIN(id)
	) ;
ROLLBACK; 



-------------------------------------------------
--     Solution 4. Using backup table.  ---------
-------------------------------------------------
-- This is the best approach in a test enviroment because it improves 
-- performance as its very fast when compared to delete operation.
-- Step 1. Create a backup table with the same structure as results table. 
CREATE TABLE results_bckup 
AS SELECT * FROM "US Election".results WHERE 1 = 2; 

-- Step 2. Insert uniques values from results table into the backup model. 
-- Get data from Solution 3 above and modify to include non duplicates. 
INSERT INTO results_bckup
SELECT * FROM "US Election".results
WHERE id IN (
	SELECT MIN(id)
	FROM "US Election".results
	GROUP BY year, state, county_name, candidate, candidatevotes 
	ORDER BY MIN(id)
	) ;
	
-- Step 3. Drop original model and then alter the name of new model to be similar as original.
BEGIN;

DROP TABLE "US Election".results;

ALTER TABLE results_bckup RENAME TO results;

ROLLBACK;

DROP TABLE results_bckup;


-------------------------------------------------
--     Solution 5. Delete Using CTID.  ---------
-------------------------------------------------
-- This is a unique method that is native to PostgreSQL.
-- By default PostgreSQL gives a unique identifier to all entities(even duplicates) when 
-- a table is created.
-- This feature is stored in a column called 'ctid', but remember the the c
-- View all rows from results table 

-- Remove unique column
ALTER TABLE  "US Election".results DROP COLUMN id;

-- Query ctid column
SELECT *, ctid FROM "US Election".results; 

-- Identify duplicate records using min() but with ctid column(unique) 
SELECT * FROM "US Election".results
WHERE ctid NOT IN (
	SELECT MIN(ctid)
	FROM "US Election".results
	GROUP BY year, state, county_name, candidate, candidatevotes 
	ORDER BY MIN(ctid)
	) ;
	
-- Remove duplicates 
BEGIN;

DELETE FROM "US Election".results
WHERE ctid NOT IN (
	SELECT MIN(ctid)
	FROM "US Election".results
	GROUP BY year, state, county_name, candidate, candidatevotes 
	ORDER BY MIN(ctid)
	) ;

ROLLBACK; 




----------------------------------------------------------------------------------
--     Solution 6. Creating backup table without deleting original.  ---------
-----------------------------------------------------------------------------------
-- Create a backup table and add unique data from results model 
CREATE TABLE results_bckup AS 
SELECT DISTINCT * FROM "US Election".results ; 

-- View new table 
SELECT * FROM results_bckup;

-- Remove all rows from original data , add transactions
BEGIN ;

TRUNCATE TABLE "US Election".results;
SELECT * FROM "US Election".results;

-- Fetch data from backup table and add to empty results table 
INSERT INTO "US Election".results 
SELECT * FROM results_bckup;

ROLLBACK ;

-- Delete backup table 
DROP TABLE results_bckup;



-- Caveat
-- Solutions 1 - 4 are appropriate if data contains a unique id 
-- Solutions 5 & 6 are used when all the columns are duplicated and table has no unique id 








































