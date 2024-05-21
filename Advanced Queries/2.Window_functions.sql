-- ADVANCED QUERIES FOR SPATIAL DATA MANAGEMENT, BY C. K. Kechir 
-- WINDOW FUNCTIONS.
-- Authors: Collins Kipkorir Kechir
-- LinkedIn : www.linkedin.com/in/collins-kechir-068289189
-- X : @kechircollins
-- Github : https//github.com/kechcole

-- The code in this book is free. You can copy, modify and distribute non-trivial part of the code 
-- with no restrictions, according to the terms of the Creative Commons CC0 1.0 licence
-- Nevertheless, the acknowledgement of the authorship is appreciated.


-- Corrections 
-- 1. Schema name 
-- 2. 


-- Import data 
COPY "US Election".results FROM 
'F:\Programs\PostGRE SQL\US Election Analysis_Github\countypres_results_2000_2020.csv'
with csv header;


-- Remove everything from the year 1999
DELETE FROM "US Election".results WHERE year > 1999;


-- 1. View every data from table 
SELECT * FROM "US Election".results;

-- 1.1 Determine the number of unique counties
SELECT DISTINCT county_name FROM "US Election".results;    -- 1892

-- 1.1 Find the biggest candidate vote in the five elections
-- Use aggregate function maximum 
SELECT max(candidatevotes) AS max_vote
FROM "US Election".results;


--2. Determine the county with the largest number of vote as well as the year 
-- in which the votes were cast 
-- Group rows with the same county name and year then order in descending value
-- The result is each county values are aggregated with a single value for each year
SELECT state,county_name,year, max(candidatevotes) as max_votes
FROM "US Election".results
GROUP BY state, county_name, year
ORDER BY max_votes DESC;



--      Window Functions 
-- Window functions are almost similar to aggregate functions, they summarise the value of 
-- related group of rows but the rows retain their entities rather than being grouped to a 
-- single row value. A window function is applied to all the rows in a subdivision. 

--     a) Over
--   Over specifies a set of row in which window functions are to be applied. 
-- 3. Determine the largest ever cast vote 
--    Use maximumn value as window function. Over function creates a window of records
--    thus when no parameters are passed it will create a window for all the rows.
--     N/B Note the use of aggregate functions without group by function.
SELECT res.*,  
max(candidatevotes) OVER() as max_votes  -- add the maximum value to all the counties 
FROM "US Election".results AS res;

-- 4. Determine the largest vote cast in each county for all the years
--   Group by county and determine the largest vote in that county
--   Partition by is a sub clause of over function, work similar to group by by dividing rows 
--   into various partitions based on a value. 
SELECT res.*, 
max(candidatevotes) OVER(PARTITION BY county_name) as max_votes
FROM "US Election".results AS res;

--        b) Row Number.  
--  Row number is a type pof window function that assigns a sequential number to all rows in a query set. 
-- 4. Add a unique identifier to each entity. 
SELECT res.*,
ROW_NUMBER() OVER() AS rn
FROM "US Election".results AS res;

-- 5. Assign a number based on distinct county.
--    Data grouped by counties and placed in a window, then each candidate assigned a unique number from 1. 
SELECT res.*,
ROW_NUMBER() OVER(PARTITION BY county_name) AS rn
FROM "US Election".results AS res;

--    c) ORDER BY as window function
-- 6. Sort by number of votes and assign numbers in each county. Candidate with more votes ranked highest,1. 
--    Order by the number of votes received 
SELECT year, state, county_name, candidate, candidatevotes, 
ROW_NUMBER() OVER(PARTITION BY county_name ORDER BY candidatevotes DESC) AS rn
FROM "US Election".results AS res;

--       d) Subquery 
-- 7. Pick only the top two candidates in each county every year of election. Partition by county and year.  
--    Use Subquery, a query nested inside another. Make 6 above the subquery then select those 
--    with values less that 3. 
--    A subquery must be assigned an alias. 
SELECT * FROM
		(
		SELECT year, state, county_name, candidate, candidatevotes, 
		ROW_NUMBER() OVER(PARTITION BY county_name, year ORDER BY candidatevotes DESC) AS rn
		FROM "US Election".results AS res
		) AS subqry
WHERE rn < 3;

-- Export as table 
COPY (
	SELECT * FROM
		(
		SELECT year, state, county_name, candidate, candidatevotes, 
		ROW_NUMBER() OVER(PARTITION BY county_name, year ORDER BY candidatevotes DESC) AS rn
		FROM "US Election".results AS res
		) AS subqry
	WHERE rn < 3
) TO 'F:/Programs/PostGRE SQL/US Election Analysis_Github/topcandidate.csv' DELIMITER ',' CSV HEADER;


--     e) Rank window function.
--  Rank function assigns a rank to individual rows with partition of an output, if values are 
--  similar and within the same partition then they are give the same number. 
--  Its a subpart of a window function. 
--  Next value after a duplicate will be the previous rank after sum of duplicates, i.e 1, 2, 2, 2, 5
--   8. Rank the top 20 candidates in each county for every year. Note South Caroline where 
--     multiple candidates had 1 vote each.  
SELECT * FROM
		(
		SELECT year, state, county_name, candidate, candidatevotes, 
		RANK() OVER(PARTITION BY county_name, year ORDER BY candidatevotes DESC) AS rn
		FROM "US Election".results AS res
		) AS subqry
WHERE rn < 20 AND state = 'SOUTH CAROLINA';

--		d) Dense rank
--  Similar to rank but it does not skip a rank after duplicate values.
--  9. Rank the top 20 candidates in each county for every year. Note South Caroline where 
--     multiple candidates had 1 vote each.
SELECT * FROM
		(
		SELECT year, state, county_name, candidate, candidatevotes, 
		RANK() OVER(PARTITION BY county_name, year ORDER BY candidatevotes DESC) AS rn, 
		DENSE_RANK() OVER(PARTITION BY county_name, year ORDER BY candidatevotes DESC) AS dns_rn
		FROM "US Election".results AS res
		) AS subqry
WHERE rn < 20 AND state = 'SOUTH CAROLINA';


--		f) Lag
--  Allows you to access the value of the previous row from the current row. 
-- 	Pass column from which values are extracted as parameter, other optional parameters are 
--  previous row and null value. Initial value is always null. 
--  10. Write a query to determine the votes of winning candidate and candidates name in the 
--      previous election cycle.  
--    Determine the wining candidate in all the counties as subquery(check 7), then pass in the
--    previous candidate and their votes, finally filter results for the year 2000 because
--    they are incorrect by having results from 2020. 
SELECT * FROM 
		(SELECT *, 
		LAG(candidate) OVER() as prev_candidate,
		LAG(candidatevotes) OVER() AS prev_results  -- No need to repeat partition 
		FROM
				(
				SELECT year, state, county_name, candidate, candidatevotes, 
				ROW_NUMBER() OVER(PARTITION BY county_name, year ORDER BY candidatevotes DESC) AS rn
				FROM "US Election".results AS res
				) AS subqry
		WHERE rn < 2) AS subqry2
WHERE year <> 2000;

-- 11. Fetch two previous election results of the winning candidate in each county and fill 
--     missing values with 0. The first two elections 2000 and 2004 have no/incorrect values. 
--     Need to be removed. 
SELECT * FROM 
		(SELECT *, 
		LAG(candidatevotes, 2, 0) OVER() as prev_8yr_res
		FROM
				(
				SELECT year, state, county_name, candidate, candidatevotes, 
				ROW_NUMBER() OVER(PARTITION BY county_name, year ORDER BY candidatevotes DESC) AS rn
				FROM "US Election".results AS res
				) AS subqry
		WHERE rn < 2) AS subqry2
WHERE year NOT IN (2000, 2004);


-- 		g) Lead.
-- Work similar to lag but gets prior records. When  in row n, get results for row n+1.
-- The last row contains null value. 
--  11. Write a query to determine the votes of winning candidate and candidates name in the 
--      next election cycle. 
SELECT *, 
LEAD(candidate) OVER() as next_candidate,
LEAD(candidatevotes) OVER() AS next_results  -- No need to repeat partition 
FROM
		(
		SELECT year, state, county_name, candidate, candidatevotes, 
		ROW_NUMBER() OVER(PARTITION BY county_name, year ORDER BY candidatevotes DESC) AS rn
		FROM "US Election".results AS res
		) AS subqry
WHERE rn < 2;


-- 12. Get winning candidate previous and next for each county. The year 2000 has no previous candidate 
---    while 2020 had no next candidate.
SELECT year, state, county_name, prev_candidate, candidate, next_candidate
FROM
	(   SELECT *, 
		LAG(candidate) OVER() as prev_candidate,
		LEAD(candidate) OVER() as next_candidate
		FROM
				(
				SELECT year, state, county_name, candidate, candidatevotes, 
				ROW_NUMBER() OVER(PARTITION BY county_name, year ORDER BY candidatevotes DESC) AS rn
				FROM "US Election".results AS res
				) AS subqry
		WHERE rn < 2     ) AS subqry2 
WHERE year NOT IN (2000, 2020);

-- 13. Identify swing states, ones that may vote either party (are not consistent) for the year 2004, 
--  2008, 2012 and 2016. 
SELECT subqry3.* 
FROM 
	(  SELECT year, state, county_name, prev_party, party, next_party, 
	CASE WHEN prev_party <> party AND next_party <> party THEN 'swing'
		 ELSE 'loyal'
		 END AS swing_county
	FROM
		(   SELECT *, 
			LAG(party) OVER() as prev_party, 
			LEAD(party) OVER() as next_party
			FROM
					(
					SELECT year, state, county_name, party,
					ROW_NUMBER() OVER(PARTITION BY county_name, year ORDER BY candidatevotes DESC) AS rn
					FROM "US Election".results AS res
					) AS subqry
			WHERE rn < 2     ) AS subqry2 
	WHERE year NOT IN (2000, 2020)   ) AS subqry3 
WHERE swing_county = 'swing';


-- 		h) first value
-- Given a sorted partition set , first_value() returns a first value. The argument 
-- it takes is the value to be displayed and it must not be a window function because it 
-- must return a single value. 
-- 14. Write a query to display the county with the largest vote in each state in every election cycle. 
SELECT *,
FIRST_VALUE(county_name) OVER(PARTITION BY state,year  ORDER BY candidatevotes DESC) AS highest_vote_county
FROM "US Election".results;
				-- Highest county vote in each state every election year 

-- 		i) Last value
-- 15.1 Write a query to display the county with the least vote in each state in every election cycle. 
--     Used state with few number of counties 
SELECT state, COUNT(*)
FROM "US Election".results
GROUP BY state ORDER BY count;

SELECT *,
FIRST_VALUE(county_name) OVER(
	PARTITION BY year  ORDER BY candidatevotes DESC
	) AS highest_vote_county,
LAST_VALUE(county_name) OVER(
	PARTITION BY year  ORDER BY candidatevotes DESC
	) AS lowest_vote_county
FROM "US Election".results
WHERE state = 'DELAWARE';
			-- highest vote worked well, but lowest vote was not convincing should show KENT.
			-- This is because of the default frame clause, a frame is a subset of a partition.
			-- A window function creates a partition, inside them we can subdivide futher to get 
			-- frames. The default frame is mentions inside over clause at the end after your 
			-- expressions i.e after order by .
			
-- 15.2 Default frame clause with the same output as above query
SELECT *,
FIRST_VALUE(county_name) OVER(
	PARTITION BY year  ORDER BY candidatevotes DESC
	) AS highest_vote_county,
LAST_VALUE(county_name) OVER(
	PARTITION BY year  ORDER BY candidatevotes DESC
	RANGE BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW    -- Default FRAME CLAUSE  
	) AS lowest_vote_county
FROM "US Election".results
WHERE state = 'DELAWARE';
		-- This statement tell SQL that for this window function, last values, apply it to 
		-- all rows in that specific partition starting from the first row(unbounde preceeding)
		-- to the current one. i.e if in row 1 of a year partition, apply last value after sort
		-- which is NEWCASTLE (check lowest_vote_county column). 
		-- In the second rows the unbounded preceeding points to the first row and compare 
		-- with the value of current row which has 78587, thus NEWCASTLE selected in that frame.
		-- In the third row, unbounded preceeding points to the first low and ONLY compares current 
		-- with the current, frame has 3 values, one with the lowest, current has 34620, thus SUSSEX 
		-- is picked. Note that this function DOES NOT HAVE ACCESS to all the rows as the frame 
		-- only has two values, current and first row. 
		-- This default clause doesn't impact the first value function but does most other window 
		-- clauses i.e last value, nth value. 
		-- The fuction can be modified by making it access all the rows in a window, make the frame 
		-- access the unbounded preceeding and all the rows by replacing 'CURRENT ROW' with 
		-- 'UNBOUNDED FOLLOWING' . Ideally this means check all the recourds following the current row 
		-- and those after the first one. 

-- 15.3 Correct query 15.1 
SELECT *,
FIRST_VALUE(county_name) OVER(
	PARTITION BY year  ORDER BY candidatevotes DESC
	) AS highest_vote_county,
LAST_VALUE(county_name) OVER(
	PARTITION BY year  ORDER BY candidatevotes DESC
	RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING      
	) AS lowest_vote_county
FROM "US Election".results
WHERE state = 'DELAWARE';

-- 		i) Window clause
-- Used to shorten other window functions that are bound to repeat statements i.e in question 15, 
-- "PARTITION BY year  ORDER BY candidatevotes DESC" has been duplicated twice. 
-- Using an alias, a window clause will specify what in supposed to be added in a window function
-- 16.1 Write a simplified query for question 15.1  

SELECT *,
FIRST_VALUE(county_name) OVER w AS highest_vote_county,
LAST_VALUE(county_name) OVER w AS lowest_vote_county
FROM "US Election".results
WHERE state = 'DELAWARE'
WINDOW w AS (PARTITION BY year  ORDER BY candidatevotes DESC);


-- 16.2 Write a simplified query for question 15.3
SELECT *,
FIRST_VALUE(county_name) OVER w AS highest_vote_county,
LAST_VALUE(county_name) OVER w AS lowest_vote_county
FROM "US Election".results
WHERE state = 'DELAWARE'
WINDOW w AS (
			PARTITION BY year  ORDER BY candidatevotes DESC
			RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING	
			);
			
-- 17 Write a query that fetches the largest and smallest county in terms of voter. 
--    Partition by year and state
SELECT *,
FIRST_VALUE(county_name) OVER w AS highest_vote_county,
LAST_VALUE(county_name) OVER w AS lowest_vote_county
FROM "US Election".results
WINDOW w AS (
			PARTITION BY year,state ORDER BY candidatevotes DESC
			RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING	
			);

-- 		j) NTH Value
-- Gets the value on the nth row relative to first row in an ordered partition set window. 
-- Parameters is the column to display, position in an ordered set. Then followed by over function that 
-- tells it the group of row to act upon. If that value is not available, returns a null value. 
-- When using this clause its important to specify the frame to prevent errors. 
-- 18. Get the the runner-up in every county.
SELECT *,
FIRST_VALUE(candidate) OVER w AS winner,
FIRST_VALUE(candidatevotes) OVER w AS winner_votes,
NTH_VALUE(candidate, 2) OVER w AS runner_up,
NTH_VALUE(candidatevotes, 2) OVER w AS runner_up_votes
FROM "US Election".results
WINDOW w AS (
			PARTITION BY year,state, county_name ORDER BY candidatevotes DESC
			RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING	
			);

-- 		j) NTILE Value
-- Groups data within a sorted partition into buckets (specified by users), ranked groups of equal sizes. 
-- Each group is assigned a number starting from one, and each sub group(bucket) contains rows. 
-- If number of rows is an odd number then the first group will be give more as compared to other buckets.
-- 19. Write a query that segregates vote difference in each county to three groups ;
-- 			narrow < 2000,
-- 			general >= 2000 and < 8000
-- 			wide margin >= 8000
--  Step 1. Calculate winnung and runner up values for each county, subquery1
--  Step 2. Find the difference between winner and runner up, subquery2
--  Step 3. Classify to three equal buckets, subquery3
--  Step 4. Give category name in margin column
SELECT * ,
CASE WHEN subqry3.buckets = 1 THEN 'wide margin'
	 WHEN subqry3.buckets = 2 THEN 'general'
	 ELSE 'narrow' 
	 END AS margin
FROM
	(
	SELECT * , 
	NTILE(3) OVER(ORDER BY vote_diff DESC) AS buckets
	FROM 
		(
		SELECT * , 
		winner_votes - runner_up_votes AS vote_diff
		FROM
			(
			SELECT year, county_name, candidate, state, party,
			FIRST_VALUE(candidate) OVER w AS winner,
			FIRST_VALUE(candidatevotes) OVER w AS winner_votes,
			NTH_VALUE(candidate, 2) OVER w AS runner_up,
			NTH_VALUE(candidatevotes, 2) OVER w AS runner_up_votes
			FROM "US Election".results
			WINDOW w AS (
						PARTITION BY year, state, county_name ORDER BY candidatevotes DESC
						RANGE BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING	
						)
			 ) AS subqry1
		) AS subqry2
	) AS subqry3
WHERE state = 'DELAWARE' ;
				-- NOTE. Using ntile() we are unable to use customised groupings. 
				--       Values for delaware are not equally distributed 


-- 		k) cum dist function
-- Find the cummulative distribution of a value within a group of values. 
-- Takes in the column to be returned as parameter. 
-- Formula = current row number/total number of rows 
-- 20. Fetch the cumulative distribution of votes per state in the year 2020. 
-- Step 1. Design a query that aggregates then orders total votes in counties on a state level, sub-query 1
-- Step 2. Calculate distribution. 
-- Step 3. Show value in percentage format
SELECT *, 
CUME_DIST() OVER(ORDER BY totalvotes) AS cum_dist_fraction, 
ROUND(CUME_DIST() OVER(ORDER BY totalvotes)::numeric * 100, 1)||'%' AS cum_dist_percentage 
FROM
	(
	SELECT state, year, SUM(tot_votes) as totalvotes 
	FROM 
	"US Election".results
	WHERE YEAR = 2020
	GROUP BY state, year 
	) AS sbqry1 ; 


-- 		l) Percent rank
-- 

SELECT
    ROUND( (10.817), 2 );

















-- References.
-- 1. Window functions - 
-- https://www.youtube.com/watch?v=zAmJPdZu8Rg&list=PLavw5C92dz9GbmgiW4TWVnxhjMFOIf0Q7&index=2