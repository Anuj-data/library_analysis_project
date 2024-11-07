--- 1. Create a New Book Record -- "978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.')"

INSERT INTO books(isbn, book_title, category, rental_price, status, author, publisher)
VALUES('978-1-60129-456-2', 'To Kill a Mockingbird', 'Classic', 6.00, 'yes', 'Harper Lee', 'J.B. Lippincott & Co.');
SELECT * FROM books;

--- 2: Update an Existing Member's Address

UPDATE members
SET member_address = '125 Oak St'
WHERE member_id = 'C103';


--- 3: Delete a Record from the Issued Status Table -- Objective: Delete the record with issued_id = 'IS121' from the issued_status table.

DELETE FROM issued_status
WHERE   issued_id =   'IS121';

---Task 4: Retrieve All Books Issued by a Specific Employee -- Objective: Select all books issued by the employee with emp_id = 'E101'.

SELECT * FROM issued_status
WHERE issued_emp_id = 'E101'

--- 5: List Members Who Have Issued More Than One Book -- Objective: Use GROUP BY to find members who have issued more than one book.

SELECT
    issued_emp_id,
    COUNT(*)
FROM issued_status
GROUP BY 1
HAVING COUNT(*) > 1

---3. CTAS (Create Table As Select)
---Task 6: Create Summary Tables: Used CTAS to generate new tables based on query results - each book and total book_issued_cnt**


CREATE TABLE book_issued_cnt AS
SELECT b.isbn, b.book_title, COUNT(ist.issued_id) AS issue_count
FROM issued_status as ist
JOIN books as b
ON ist.issued_book_isbn = b.isbn
GROUP BY b.isbn, b.book_title;


---4. Data Analysis & Findings

---Task 7. Retrieve All Books in a Specific Category:

SELECT * FROM books
WHERE category = 'Classic';

--- 8: Find Total Rental Income by Category:

SELECT 
    b.category,
    SUM(b.rental_price),
    COUNT(*)
FROM 
issued_status as ist
JOIN
books as b
ON b.isbn = ist.issued_book_isbn
GROUP BY 1

--- 9. List Members Who Registered in the Last 180 Days:

SELECT * FROM members
WHERE reg_date >= CURRENT_DATE - INTERVAL '180 days';

--- 10.List Employees with Their Branch Manager's Name and their branch details:

SELECT 
    e1.emp_id,
    e1.emp_name,
    e1.position,
    e1.salary,
    b.*,
    e2.emp_name as manager
FROM employees as e1
JOIN 
branch as b
ON e1.branch_id = b.branch_id    
JOIN
employees as e2
ON e2.emp_id = b.manager_id;

--- 11. Create a Table of Books with Rental Price Above a Certain Threshold:

CREATE TABLE expensive_books AS
SELECT * FROM books
WHERE rental_price > 7.00;

--- 12: Retrieve the List of Books Not Yet Returned

SELECT * FROM issued_status as ist
LEFT JOIN
return_status as rs
ON rs.issued_id = ist.issued_id
WHERE rs.return_id IS NULL;

---Advanced SQL Operations

---13. Identify Members with Overdue Books
/* Write a query to identify members who have overdue books (assume a 30-day return period).
Display the member's_id, member's name, book title, issue date, and days overdue.*/


SELECT 
	public.issued_status.issued_member_id,
	public.members.member_name,
	public.books.book_title,
	public.issued_status.issued_date,
	public.return_status.return_date,
	CURRENT_DATE - public.issued_status.issued_date AS over_dues_days
FROM 
	public.issued_status 
JOIN
	public.members
ON 
	public.members.member_id = public.issued_status.issued_member_id
JOIN
	public.books
ON
	public.books.isbn = public.issued_status.issued_book_isbn
LEFT JOIN
	public.return_status
ON 
	public.return_status.issued_id = public.issued_status.issued_id
WHERE
	public.return_status.return_date IS NULL AND 
	(CURRENT_DATE - public.issued_status.issued_date) > 30 
ORDER BY 
	public.members.member_name;

---Task 14: Branch Performance Report

/* Create a query that generates a performance report for each branch, showing the number of
books issued, the number of books returned, and the total revenue generated from book rentals.*/


-- Number of book issuesd.
-- Number of book returned.
-- Total number of revenue generated from each book.


SELECT 
	SUM(public.book_issued_cnt.issue_count) AS number_of_book_issued,
	public.return_status.return_book_name,
	SUM(public.books.rental_price * public.book_issued_cnt.issue_count ) AS revenue_generated_from_each_book
FROM
	public.book_issued_cnt 
JOIN
	public.books
ON 
	public.book_issued_cnt.isbn = public.books.isbn
LEFT JOIN
	public.return_status
ON
	public.books.isbn = public.return_status.return_book_isbn
GROUP BY 
	public.return_status.return_book_name;


--Task 15: CTAS: Create a Table of Active Members

/* Use the CREATE TABLE AS (CTAS) statement to create a new table active_members containing 
members who have issued at least one book in the last 2 months. */

CREATE TABLE active_members
AS 
SELECT *
FROM
	public.members
WHERE member_id IN (SELECT 
					DISTINCT issued_member_id
				FROM
					public.issued_status
				WHERE
					issued_date >= CURRENT_DATE - INTERVAL '2 Months'
				)


SELECT *
FROM
	active_members


-- Task 16: Find Employees with the Most Book Issues Processed

/* Write a query to find the top 3 employees who have processed the most book issues. 
Display the employee name, number of books processed, and their branch. */

SELECT 
    employees.emp_name,
    COUNT(issued_status.issued_book_name) AS number_of_books_processed,
    branch.branch_id,
    branch.branch_address
FROM
    public.employees
JOIN
    public.issued_status ON employees.emp_id = issued_status.issued_emp_id
JOIN
    public.branch ON employees.branch_id = branch.branch_id
GROUP BY
    employees.emp_name,
    branch.branch_id,
    branch.branch_address
ORDER BY
    number_of_books_processed DESC
LIMIT 3;

-- Task 17: Identify Members Issuing High-Risk Books

/* Write a query to identify members who have issued books more than twice with the status 
"damaged" in the books table. Display the member name, book title, and the number of times 
they've issued damaged books. */

SELECT 
	public.members.member_name,
	public.books.book_title,
	COUNT(public.issued_status.issued_id) AS No_of_time_received_damaged_books
FROM
	public.books
JOIN
	public.issued_status
ON
	public.books.isbn = public.issued_status.issued_book_isbn
JOIN
	public.members
ON
	public.issued_status.issued_member_id = public.members.member_id
WHERE
	public.books.status = 'damaged'
GROUP BY
	public.members.member_name,
	public.books.book_title
HAVING 
   COUNT(public.issued_status.issued_id) > 2;






