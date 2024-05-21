-- ADVANCED QUERIES FOR SPATIAL DATA MANAGEMENT, BY C. K. Kechir 
-- SUBQUERIES AND ADVANCED JOINS.
-- Authors: Collins Kipkorir Kechir
-- LinkedIn : www.linkedin.com/in/collins-kechir-068289189
-- X : @kechircollins
-- Github : https//github.com/kechcole

-- The code in this book is free. You can copy, modify and distribute non-trivial part of the code 
-- with no restrictions, according to the terms of the Creative Commons CC0 1.0 licence
-- Nevertheless, the acknowledgement of the authorship is appreciated.






/*
					SUBQUERIES.
A subquery is a query nested inside another query, the inner query provides the results used by the 
outer (container) query. They offer more flexibility because they can be brocken down into individual 
components and are easy to use. This properties make improves performance and make debbugging and 
testing simple. 
There are multiple types of subqueries :
	1. Scalar sub queries only return a single row and single column.
	2. Row sub queries only return a single row but can have more than one
	column.
	3. Table subqueries can return multiple rows as well as columns

*/


SELECT *
FROM "Election".results
ORDER BY "year"  ASC;

----------------------------------------------------------------------------------------------
-- Qn 1. Determine the states with more voters than the average in the year 2020 ? 
----------------------------------------------------------------------------------------------
-- a) Find the national average voter population in 2020
SELECT SUM(candidatevotes)/count(DISTINCT("state")) AS avg_votes
FROM "Election".results
WHERE "year" = 2020;


-- b) Aggregate total votes in all the states
SELECT  "state", SUM(candidatevotes) AS total
FROM "Election".results
WHERE "year" = 2020 
GROUP BY  "state";


-- c) Find states where votes are lager than average 3107387, use b) as inner query
SELECT  * FROM 
	(
		SELECT  "state", SUM(candidatevotes) AS total
		FROM "Election".results
		WHERE "year" = 2020 
		GROUP BY  "state"
	)   AS S1
WHERE total > 3107387;

-- d) Use a more dynamic query, subtitute average value with query a)
--    The last subquery returns only the average value thus a scalar subquery but the 
--    first one can be termed as a table subquery because it has multiple rows and columns.
SELECT  * FROM 
	(
		SELECT  "state", SUM(candidatevotes) AS total
		FROM "Election".results
		WHERE "year" = 2020 
		GROUP BY  "state"
	)   AS S1
WHERE total > (
				SELECT SUM(candidatevotes)/count(DISTINCT("state")) AS avg_votes
				FROM "Election".results
				WHERE "year" = 2020
			  ) ;	  

-- e) Use join analysis
SELECT  * FROM 
	(
		SELECT  "state", SUM(candidatevotes) AS total
		FROM "Election".results
		WHERE "year" = 2020 
		GROUP BY  "state"
	)   AS S1
JOIN  (
		SELECT SUM(candidatevotes)/count(DISTINCT("state")) AS avg_votes
		FROM "Election".results
		WHERE "year" = 2020
	  ) AS S2
	 ON S1.total > S2.avg_votes;
	 
	 	-- S2 is treated as a table in a join operation although its a scalar subquery
		-- The output is similar to results in d) but with an added column cotaining 
		-- national average value 

-- f) Use having clause.
SELECT  "state", SUM(candidatevotes) AS total
FROM "Election".results
WHERE "year" = 2020 
GROUP BY  "state"
HAVING SUM(candidatevotes) > 
				(
				SELECT SUM(candidatevotes)/count(DISTINCT("state")) AS avg_votes
				FROM "Election".results
				WHERE "year" = 2020
	  			);
						




----------------------------------------------------------------------------------------------
-- Question 2.Find the largest county voting block in each state for the year 2020    --------
----------------------------------------------------------------------------------------------
-- a) Find the largest vote in each state 
SELECT  "state", MAX(candidatevotes) AS largest
FROM "Election".results
WHERE "year" = 2020 
GROUP BY  "state";

-- b) Compare each record with the results in a) then filter to find matching items
SELECT * FROM "Election".results
WHERE ("state", candidatevotes) IN 
	(
		SELECT  "state", MAX(candidatevotes) AS largest
		FROM "Election".results
		WHERE "year" = 2020 
		GROUP BY  "state"
	) ;
		-- SQL executes the inner query, a multiple row subquery, and hold the results then compares 
		-- it with each record from the outer query to match the filter condition. 
		-- The inner query will contain state and largest vote but not the name of county. 
		-- So if state and candidate column values from outer query match state and largest columns
		-- from the inner query, that record is picked and returned, ideally county with the largest 
		-- vote in each state.  



----------------------------------------------------------------------------------------------
-- Qn 3. Determine the counties with more voters than the respective state in the year 2020 
--       using advanced joins and with clause.
----------------------------------------------------------------------------------------------
-- Correlated subquery is where the inner query is dependent/related on the output of the outer subquery,
-- one cannot independently execute the subquery as previously seen in 1 c), or 1 d) where all the 
-- inner queries had outputs when run individually. 
-- a) Find the average vote in each state 
SELECT "state", SUM(candidatevotes)/count(DISTINCT(county_name)) AS avg_vote 
FROM "Election".results
WHERE "year" = 2020 
GROUP BY  "state" ;

-- b) Find the sum of votes in each county
SELECT county_name, SUM(candidatevotes) AS total_votes 
FROM "Election".results
WHERE "year" = 2020 
GROUP BY county_name;

-- c) Save queries using CTE(common table expression), a WITH Clause, then perform an 
--    advanced join analysis and filter counties with larger votes that its state average. 
--    Add both queries in a) and b) as subqueries in with clause each with an alias
--    and the column to be returned from each 
--    Step 1. Create three tables using with statement : average state votes table, 
---       total county votes table, state and county name table 
--        These tables will contain data aggregated across state and county level 
---   Step 2. Join the three tables 
--    Step 4. Filter counties with votes greater than the average of its state. 
WITH average_state_vote ("state", avg_state_vote) AS 
	(
		SELECT "state", SUM(candidatevotes)/COUNT(DISTINCT(county_name)) AS avg_state_vote 
		FROM "Election".results AS res1
		WHERE res1."year" = 2020 
		GROUP BY  res1.state
	),
	total_county_votes (county_name, total_county_votes) AS 
	(
		SELECT county_name, SUM(candidatevotes) AS total_county_votes 
		FROM "Election".results AS res2
		WHERE res2."year" = 2020 
		GROUP BY res2.county_name
	) ,
	state_and_county (county_name, "state") AS 
	(
		SELECT county_name, "state" 
		FROM "Election".results AS res3
		WHERE res3."year" = 2020 
		GROUP BY res3.county_name, res3.state
	)

SELECT t1.county_name, t2."state", t1.total_county_votes, t3.avg_state_vote 
FROM total_county_votes AS t1 
JOIN state_and_county AS t2 
ON t1.county_name = t2.county_name 
JOIN average_state_vote AS t3 
ON t3.state = t2.state 
WHERE t1.total_county_votes > t3.avg_state_vote ;
			-- Note that WITH clause is more advantageous that creating a temporary table.
			-- Data from 3 subqueries were readily available for use any number of times 
			-- we needed. 
			-- It also made our query more readable by breaking the complex idea into smaller 
			-- but managable sizes giving us easy time during maintainance or debbuging. 
			-- Performance is also enhanced because we are able to reduce thousands of data to 
			-- few hundreds of rows. 
			



----------------------------------------------------------------------------------------------
-- Question 4. find counties from other elections that did not vote in 2020 elections. -------
----------------------------------------------------------------------------------------------
--  This could be due to merging of counties or other reasons since borders are usually redrawn
--  in every election.  
SELECT DISTINCT(county_name)
FROM "Election".results
WHERE (county_name) NOT IN 
		( 
			SELECT county_name 
			FROM "Election".results AS res3
			WHERE res3."year" = 2020 
			GROUP BY res3.county_name
		);





























































