-- Scratching backs?

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO uber, public;
DROP TABLE IF EXISTS q8 CASCADE;

CREATE TABLE q8(
    client_id INTEGER,
    reciprocals INTEGER,
    difference FLOAT
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS reciprocalsRating CASCADE;
DROP VIEW IF EXISTS reciprocalsRatingInfo CASCADE;


-- Define views for your intermediate steps here:
CREATE view reciprocalsRating as
select DriverRating.request_id, DriverRating.rating as Dr, ClientRating.rating as Cr
from DriverRating, ClientRating
where DriverRating.request_id = ClientRating.request_id;

CREATE view reciprocalsRatingInfo as
select reciprocalsRating.request_id, Request.client_id, reciprocalsRating.Dr, reciprocalsRating.Cr
from reciprocalsRating, Request
where reciprocalsRating.request_id = Request.request_id;


-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q8
select client_id, count(client_id) as reciprocals, avg(Dr - Cr) as difference
from reciprocalsRatingInfo
group by client_id;