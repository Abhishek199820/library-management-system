SELECT * FROM books;
SELECT * FROM branch;
SELECT * FROM employees;
SELECT * FROM issued_status;
SELECT * FROM return_status;
SELECT * FROM members;

/*
Task 13: Identify Members with Overdue Books
Write a query to identify members who have overdue books (assume a 30-day return period). Display the member's_id, member's name, book title, issue date, and days overdue
*/

-- issued_status == members == books == return_ststus
-- filter books which is return
-- overdue > 30

SELECT 
	ist.issued_member_id,
	m.member_name,
	bk.book_title,
	ist.issued_date,
	-- rs.return_date,
	CURRENT_DATE - ist.issued_date as over_dues_day
	from issued_status as ist 
	JOIN
	members as m 
		ON m.member_id = ist.issued_member_id
	JOIN
	books as bk
		ON bk.isbn = ist.issued_book_isbn
	LEFT JOIN
	return_status as rs 
		ON rs.issued_id = ist.issued_id
Where rs.return_date is null
	and (CURRENT_DATE - ist.issued_date) > 30
	
/*	
Task 14: Update Book Status on Return
Write a query to update the status of books in the books table to "Yes" when they are returned (based on entries in the return_status table).
*/

SELECT * FROM issued_status
where issued_book_isbn = '978-0-679-76489-8'

select * from books
where isbn = '978-0-679-76489-8'

update books
set status = 'no'
where isbn = '978-0-679-76489-8'


select * from return_status
where issued_id = 'IS111'


--
insert into return_status (return_id, issued_id, return_date, book_quality)
values ('RS125', 'IS111', CURRENT_DATE, 'Good');
select * from return_status
where issued_id = 'IS111'



-- Store Procedure
CREATE OR REPLACE PROCEDURE add_return_records(
    p_return_id VARCHAR(10), 
    p_issued_id VARCHAR(10), 
    p_book_quality VARCHAR(10)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_isbn VARCHAR(50);
    v_book_name VARCHAR(80);
BEGIN
    -- Insert into return_status based on user input
    INSERT INTO return_status (return_id, issued_id, return_date, book_quality)
    VALUES
    (p_return_id, p_issued_id, CURRENT_DATE, p_book_quality);

    -- Retrieve the ISBN and book title from issued_status
    SELECT 
        issued_book_isbn,
        issued_book_name
    INTO 
        v_isbn,
        v_book_name
    FROM 
        issued_status
    WHERE 
        issued_id = p_issued_id;

    -- Update the books table to set the status as available
    UPDATE books
    SET status = 'yes'
    WHERE isbn = v_isbn;

    -- Raise a notice to the user
    RAISE NOTICE 'Thank You for returning the book: %', v_book_name;
END;
$$;



-- Testing FUNCTION add_return_records

issued_id = IS135
ISBN = WHERE isbn = '978-0-307-58837-1'

select * from issued_status
where issued_id = 'IS135'


SELECT * FROM issued_status
WHERE issued_book_isbn = '978-0-307-58837-1';

SELECT * FROM return_status
WHERE issued_id = 'IS140';

-- Call the procedure
CALL add_return_records('RS138', 'IS135', 'Good');
CALL add_return_records('RS148', 'IS140', 'Worst');


/*
Task 15: Branch Performance Report
Create a query that generates a performance report for each branch, showing the number of books issued, the number of books returned, and the total revenue generated from 
book rentals.
*/

Create table branch_reports
AS
SELECT b.branch_id, b.manager_id,
	count(ist.issued_id) as number_book_issued,
	count(rs.return_id) as number_of_book_return,
	sum(bk.rental_price) as total_revenue
from issued_status as ist
join employees as e
on e.emp_id = ist.issued_emp_id
join 
branch as b
on e.branch_id = b.branch_id
left join
return_status as rs
on rs.issued_id = ist.issued_id
join
books as bk
on ist.issued_book_isbn = bk.isbn
group by 1, 2

select * from branch_reports

/*
Task 16: CTAS: Create a Table of Active Members
Use the CREATE TABLE AS (CTAS) statement to create a new table active_members containing members who have issued at least one book in the last 2 months.
*/

Create table active_members
as
select * from members
where member_id in (select
							distinct issued_member_id
						from issued_status
						where 
							issued_date> Current_date - Interval '2 month')

select * from active_members

/*
Task 17: Find Employees with the Most Book Issues Processed
Write a query to find the top 3 employees who have processed the most book issues. Display the employee name, number of books processed, and their branch.
*/

select e.emp_name,
b.*,
count(ist.issued_id) as no_book_issued
from 
issued_status as ist
join 
employees as e
on e.emp_id = ist.issued_emp_id
join
branch as b 
on e.branch_id = b.branch_id
group by 1, 2

/*
Task 18: Identify Members Issuing High-Risk Books
Write a query to identify members who have issued books more than twice with the status "damaged" in the books table. Display the member name, book title, and the number of
times they've issued damaged books.
*/
select 
	m.member_name as Name,
	b.book_title as Book_Name,
	count(*) as damaged_issues_count
from
	issued_status as i
join
	books as b on i.issued_book_isbn = b.isbn
join 
	members as m on i.issued_member_id = m.member_id
where 
	b.status = 'Damaged'
group by 1, 2


/*
Task 19: Stored Procedure Objective: Create a stored procedure to manage the status of books in a library system. Description: Write a stored procedure that updates the status of a book 
in the library based on its issuance. The procedure should function as follows: The stored procedure should take the book_id as an input parameter. The procedure should first check if the
book is available (status = 'yes'). If the book is available, it should be issued, and the status in the books table should be updated to 'no'. If the book is not available (status = 'no'), 
the procedure should return an error message indicating that the book is currently not available.
*/

CREATE OR REPLACE PROCEDURE manage_book_status(
    p_issued_id VARCHAR(10),
    p_issued_member_id VARCHAR(10),
    p_issued_book_isbn VARCHAR(50),
    p_issued_emp_id VARCHAR(10)
)
LANGUAGE plpgsql
AS $$
DECLARE
    -- Variable to store the status of the book
    v_status VARCHAR(10);
BEGIN
    -- Check if the book is available ('yes')
    SELECT status
    INTO v_status
    FROM books
    WHERE isbn = p_issued_book_isbn;

    -- If the book is available, issue it
    IF v_status = 'yes' THEN
        -- Insert the record into issued_status
        INSERT INTO issued_status (
            issued_id, 
            issued_member_id, 
            issued_date, 
            issued_book_isbn, 
            issued_emp_id
        )
        VALUES (
            p_issued_id, 
            p_issued_member_id, 
            CURRENT_DATE, 
            p_issued_book_isbn, 
            p_issued_emp_id
        );

        -- Update the status of the book to 'no'
        UPDATE books
        SET status = 'no'
        WHERE isbn = p_issued_book_isbn;

        -- Notify the user of the successful issuance
        RAISE NOTICE 'Book records added successfully for book ISBN: %', p_issued_book_isbn;

    -- If the book is unavailable, raise a notice
    ELSE
        RAISE NOTICE 'Sorry to inform you, the book you have requested is unavailable. Book ISBN: %', p_issued_book_isbn;
    END IF;
END;
$$;

-- Testing The function
SELECT * FROM books;
-- "978-0-553-29698-2" -- yes
-- "978-0-375-41398-8" -- no
SELECT * FROM issued_status;

CALL manage_book_status('IS155', 'C108', '978-0-553-29698-2', 'E104');
CALL manage_book_status('IS156', 'C108', '978-0-375-41398-8', 'E104');

SELECT * FROM books
WHERE isbn = '978-0-553-29698-2'

/*
Task 20: Create Table As Select (CTAS) Objective: Create a CTAS (Create Table As Select) query to identify overdue books and calculate fines.

Description: Write a CTAS query to create a new table that lists each member and the books they have issued but not returned within 30 days. The table should include: The number of overdue books. 
The total fines, with each day's fine calculated at $0.50. The number of books issued by each member. The resulting table should show: Member ID Number of overdue books Total fines
*/


CREATE TABLE overdue_books_fines AS
SELECT 
    i.issued_member_id AS member_id,
    COUNT(CASE WHEN CURRENT_DATE - i.issued_date > 30 THEN 1 END) AS overdue_books_count,
    SUM(
        CASE 
            WHEN CURRENT_DATE - i.issued_date > 30 
            THEN (CURRENT_DATE - i.issued_date - 30) * 0.50
            ELSE 0 
        END
    ) AS total_fines,
    COUNT(i.issued_id) AS total_books_issued
FROM 
    issued_status i
LEFT JOIN 
    return_status r ON i.issued_id = r.issued_id
WHERE 
    r.return_id IS NULL -- Filter for books that are not returned
GROUP BY 
    i.issued_member_id;
	
	
	select * from overdue_books_fines
