-- ADVANCED QUERIES FOR SPATIAL DATA MANAGEMENT, BY C. K. Kechir 
-- STORED PROCEDURES.
-- Authors: Collins Kipkorir Kechir
-- LinkedIn : www.linkedin.com/in/collins-kechir-068289189
-- X : @kechircollins
-- Github : https//github.com/kechcole

-- The code in this book is free. You can copy, modify and distribute non-trivial part of the code 
-- with no restrictions, according to the terms of the Creative Commons CC0 1.0 licence
-- Nevertheless, the acknowledgement of the authorship is appreciated.







--  			Create and populate dummy tables 
SELECT * FROM business.products;
SELECT * FROM business.sales;

-- Populate products table 
INSERT INTO business.products 
VALUES('gps200', 'GPS etrex 32', 45120, 15, 19);
INSERT INTO business.products 
VALUES('gps200', 'GPS etrex 32', 45120, 15, 19);
INSERT INTO business.products
VALUES('ts050', 'Total Station', 100000, 20, 7);
INSERT INTO business.products
VALUES('tape031', 'Tape Measure', 200, 30, 3);


-- Make code primary key in both tables 
ALTER TABLE business.products
 ADD CONSTRAINT product_primary_key 
 PRIMARY KEY (code)
 
ALTER TABLE business.sales
 ADD CONSTRAINT orders_p_key 
 PRIMARY KEY (order_id)


-- Add foreign key constraint in sales table  
ALTER TABLE business.sales
 ADD CONSTRAINT orders_fkey 
 FOREIGN KEY (product_code)
 REFERENCES business.products (code) 
 MATCH SIMPLE ON UPDATE NO ACTION ON DELETE NO ACTION;
 
-- ADD date column 
ALTER TABLE business.sales 
	ADD COLUMN order_date timestamp 
	DEFAULT now();    


-- Populate sales table 
INSERT INTO business.sales
(order_id, product_code, quantity_ordered, total_price)
VALUES(3, 'ts050', 4, 400000)
INSERT INTO business.sales
(order_id, product_code, quantity_ordered, total_price)
VALUES(4, 'tape031', 2, 400)




--							 Procedure.
-- A procedure is a block of SQL code that is stored in a database or server. These are 
-- previously created SQL commands that have been preserved and are used to maintain the integrity
-- of a database. They validate data, data cleanup and used as an access control mechanism. 
-- A procedure can include ; SQL queries, loops and if-else statements, variables, DML DDL 
--  DCL and TCL commands, cursors, 
-- 

-- Sample 1. Given a requirement that for every product sold, modify the database tables 
-- accordingly. Update the sales table every time a product gets bought by a customer.

--       Design principle
-- Step 1. Declare the two variables that will hold values to be stored it the sales table
-- Step 2. Query the product table to get its code and price since we only have its code 
--        in the sales table, the two values are to be stored in a variable inside the procedure.
-- Step 3. Add queried data into sales table 
-- Step 4. Update the product table so that it reflects product quantity decrease. 
-- Step 5. Design a success message 
-- Step 6. Execute procedure,  then run it in a new window by calling its name. 
-- Step 7. Check tables if there has been a changed. Sales table must have a new product,
--         product quantity reduce while product sold increases in product table, a success 
--         message in the console. 


-- Procedure 1 with no parameter(s)
CREATE OR REPLACE PROCEDURE procedure_buy_products()
LANGUAGE plpgsql
AS   $$
DECLARE 							-- Step 1
	var_product_code VARCHAR(30);
	var_price INT;
BEGIN 								-- Step 2
	SELECT code, price 
	INTO var_product_code, var_price
	FROM business.products 
	WHERE "name" = 'Total Station';
	
	INSERT INTO business.sales       -- Step 3
	(order_id, product_code, quantity_ordered, total_price)
	VALUES(7, var_product_code, 1, (var_price * 1)) ;

	UPDATE business.products        -- Step 4
	SET quantity_remaining = (quantity_remaining - 1) ,
		quantity_sold = (quantity_sold + 1)
	WHERE code = var_product_code ;
									
	RAISE NOTICE 'Product SOLD !! Hurray !!' ;  -- Step 6
END ; $$


-- Call procedure then check tables 
CALL procedure_buy_products();



-- Sample 2. Given a requirement that for every given product and its quantity (parameters), 
--  a) Check if product is available based on he required quantity
--  b) if available then modify the database tables accordingly.
-- Before a product is sold the code will check if there is enough product quantity, if so
-- proceed with transaction and modify table else provide a meaningfull message after an error. 
-- 

CREATE OR REPLACE PROCEDURE procedure2_buy_products(parameter_prod_name VARCHAR, parameter_quantity INT)
LANGUAGE plpgsql
AS   $$
DECLARE 							-- Step 1
	var_product_code VARCHAR(30);
	var_price INT;
	var_counted INT;
BEGIN 								-- Step 2
    -- Check if enough product exist and load value to variable
	SELECT COUNT(1) 
	INTO var_counted                 
	FROM business.products 
	WHERE "name" = parameter_prod_name  
	AND quantity_remaining >= parameter_quantity ;
	
	-- Update table if enough products exist and update data records
	IF var_counted > 0 THEN 
		SELECT code, price 
		INTO var_product_code, var_price
		FROM business.products 
		WHERE "name" = parameter_prod_name;

		INSERT INTO business.sales       -- Step 3
		(order_id, product_code, quantity_ordered, total_price)
		VALUES(9, var_product_code, parameter_quantity, (var_price * parameter_quantity)) ;

		UPDATE business.products        -- Step 4
		SET quantity_remaining = (quantity_remaining - parameter_quantity) ,
			quantity_sold = (quantity_sold + parameter_quantity)
		WHERE code = var_product_code ;

		RAISE NOTICE 'Product SOLD !! Hurray !!' ;  -- Step 6
		
	ELSE                     -- var-count returns 0 meaning insufficient products
		RAISE NOTICE 'INSUFFICIENT PRODUCTS IN STORE ' ;
	
	END IF ;
END ; $$



-- Call procedure then check tables 
CALL procedure2_buy_products('Tape Measure', 15);
			-- Changes in Products table 
			-- a) Remaining products in tape measure row decreased by 15
			-- b) quantity sold in tape measure row increased by 15
			-- Changes in Sales Table 
			--  New record added
			
			-- MODIFICATION TO PROCEDURE 2
			-- In step 3 order_id value is still hard coded, alter table to auto generate this value. 

-- Try erroneous sale, more quantity than available
CALL procedure2_buy_products('GPS etrex E24', 100);

---------------------------------------------------------------------------------------
----   TEST 
-- Returns true(1) if query is fullfilled else false(0)
SELECT COUNT(*) INTO var1_count
FROM business.products 
WHERE "name" = 'Total Station' 
AND quantity_remaining >= 80;

SELECT * FROM var_count;
---------------------------------------------------------------------------------------









































