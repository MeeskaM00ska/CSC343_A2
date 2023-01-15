-- Months.

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO uber, public;
DROP TABLE IF EXISTS q1 CASCADE;

CREATE TABLE q1(
    client_id INTEGER,
    email VARCHAR(30),
    months INTEGER
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS allClientRequest CASCADE;


-- Define views for your intermediate steps here:
CREATE VIEW allClientRequest AS
SELECT Client.client_id, email, to_char(Request.datetime, 'YYYY:MM') as month
FROM Client 
LEFT JOIN Request ON Client.client_id = Request.client_id;


-- Your query that answers the question goes below the "insert into" line:
-- For each client, report their client ID, email address, and the number 
-- of different months in which they have had a ride. January 2021 and January 2022, for example, would count as two different months.
INSERT INTO q1
(select client_id, email, count(distinct month) as months
from allClientRequest
group by client_id, email);