-- Ratings histogram.

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO uber, public;
DROP TABLE IF EXISTS q7 CASCADE;

CREATE TABLE q7(
    driver_id INTEGER,
    r5 INTEGER,
    r4 INTEGER,
    r3 INTEGER,
    r2 INTEGER,
    r1 INTEGER
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS DriveRatingInfo CASCADE;
DROP VIEW IF EXISTS rate1 CASCADE;
DROP VIEW IF EXISTS rate2 CASCADE;
DROP VIEW IF EXISTS rate3 CASCADE;
DROP VIEW IF EXISTS rate4 CASCADE;
DROP VIEW IF EXISTS rate5 CASCADE;



-- Define views for your intermediate steps here:
-- DriveRatingInfo(driver_id, rating, rating)
CREATE view DriveRatingInfo as
select DriverRating.request_id, ClockedIn.driver_id, DriverRating.rating
from DriverRating 
join Dispatch on DriverRating.request_id = Dispatch.request_id
join ClockedIn on Dispatch.shift_id = ClockedIn.shift_id;

-- r1
CREATE view rate1 as
select driver_id, count(rating) as r1
from DriveRatingInfo
where rating = 1
group by driver_id;

-- r2
CREATE view rate2 as
select driver_id, count(rating) as r2
from DriveRatingInfo
where rating = 2
group by driver_id;

-- r3
CREATE view rate3 as
select driver_id, count(rating) as r3
from DriveRatingInfo
where rating = 3
group by driver_id;

-- r4
CREATE view rate4 as
select driver_id, count(rating) as r4
from DriveRatingInfo
where rating = 4
group by driver_id;

-- r5
CREATE view rate5 as
select driver_id, count(rating) as r5
from DriveRatingInfo
where rating = 5
group by driver_id;

-- all drive rating


-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q7
select Driver.driver_id, COALESCE(r5, 0), COALESCE(r4, 0), COALESCE(r3, 0), COALESCE(r2, 0), COALESCE(r1, 0)
from Driver
left join rate5 on Driver.driver_id = rate5.driver_id
left join rate4 on Driver.driver_id = rate4.driver_id
left join rate3 on Driver.driver_id = rate3.driver_id
left join rate2 on Driver.driver_id = rate2.driver_id
left join rate1 on Driver.driver_id = rate1.driver_id;