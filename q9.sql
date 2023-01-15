-- Consistent raters.

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO uber, public;
DROP TABLE IF EXISTS q9 CASCADE;

CREATE TABLE q9(
    client_id INTEGER,
    email VARCHAR(30)
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS Clinet_driver_num CASCADE;
DROP VIEW IF EXISTS clinet_rating_num CASCADE;


-- Define views for your intermediate steps here:

create view clinet_rating_num as
select Request.client_id as client_id, count(distinct driver_id) as rating_num
from Dropoff, Request, Dispatch, ClockedIn, DriverRating
WHERE Dropoff.request_id = Request.request_id and
        Request.request_id = Dispatch.request_id and
        Dispatch.shift_id = ClockedIn.shift_id and
        DriverRating.request_id = Request.request_id
group by Request.client_id;

create view Clinet_driver_num as
select Request.client_id as client_id, count(distinct driver_id) as driver_num
from Dropoff, Request, Dispatch, ClockedIn
WHERE Dropoff.request_id = Request.request_id and
        Request.request_id = Dispatch.request_id and
        Dispatch.shift_id = ClockedIn.shift_id
group by Request.client_id;



-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q9

select Clinet_driver_num.client_id, email
from Clinet_driver_num, clinet_rating_num, Client
where Clinet_driver_num.client_id = clinet_rating_num.client_id and
        Clinet_driver_num.driver_num = clinet_rating_num.rating_num AND
        Clinet_driver_num.client_id = Client.client_id;