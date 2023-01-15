-- Do drivers improve?

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO uber, public;
DROP TABLE IF EXISTS q4 CASCADE;

CREATE TABLE q4(
    type VARCHAR(9),
    number INTEGER,
    early FLOAT,
    late FLOAT
);



-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS finishedRides CASCADE;
DROP VIEW IF EXISTS uniqueTable CASCADE;
DROP VIEW IF EXISTS DriverDayInfo CASCADE;
DROP VIEW IF EXISTS InfoWithRating CASCADE;

DROP VIEW IF EXISTS InfoAfterFilled CASCADE;
DROP VIEW IF EXISTS TenDayFilter CASCADE;
DROP VIEW IF EXISTS untrainedDriver CASCADE;
DROP VIEW IF EXISTS trainedDriver CASCADE;
DROP VIEW IF EXISTS untrainData CASCADE;
DROP VIEW IF EXISTS untrainDataWithRating CASCADE;

-- Define views for your intermediate steps here:

--1 finishedRides(r_id, shift_id)
CREATE view finishedRides as
select Dispatch.request_id as request_id, Dispatch.shift_id as shift_id
from Dropoff 
left join Dispatch
on Dispatch.request_id = Dispatch.request_id;
--2 (r_id, shift_id)
CREATE view uniqueTable as
select finishedRides.request_id as request_id, finishedRides.shift_id as shift_id
from finishedRides
group by request_id, shift_id;
--3 (did, rid, day)
CREATE view DriverDayInfo as
select ClockedIn.driver_id as driver_id, Request.request_id as request_id,
date_trunc('day', Request.datetime) as day
from Request join uniqueTable
on Request.request_id = uniqueTable.request_id
join ClockedIn on uniqueTable.shift_id = ClockedIn.shift_id;
--4 TenDayFilter
CREATE view TenDayFilter as
select DriverDayInfo.driver_id as driver_id
from DriverDayInfo
group by driver_id
having count(distinct day) >= 10;
--4.1 InfoAfterFilled (did, rid, day)
CREATE view InfoAfterFilled as
select DriverDayInfo.driver_id as driver_id,
        DriverDayInfo.request_id as request_id,
        DriverDayInfo.day as day
from DriverDayInfo
natural join TenDayFilter;
--4.2 InfoAddrating
DROP VIEW IF EXISTS InfoAddrating CASCADE;
CREATE view InfoAddrating as
select InfoAfterFilled.driver_id as driver_id,
        InfoAfterFilled.request_id as request_id,
        InfoAfterFilled.day as day,
        DriverRating.rating as rating
from InfoAfterFilled
left join DriverRating
on InfoAfterFilled.request_id = DriverRating.request_id;
--4.3 InfoAddtrained
DROP VIEW IF EXISTS InfoAddtrained CASCADE;
CREATE view InfoAddtrained as
select InfoAddrating.driver_id as driver_id,
        InfoAddrating.request_id as request_id,
        InfoAddrating.day as day,
        InfoAddrating.rating as rating,
        Driver.trained as trained
from InfoAddrating
left join Driver
on InfoAddrating.driver_id = Driver.driver_id;
-------------------------------------------------------------------------
--5 untrainedDriver(Did, rid, day, rating)
CREATE view untrainedDriver as
select InfoAddtrained.driver_id as driver_id,
        InfoAddtrained.request_id as request_id,
        InfoAddtrained.day as day,
        InfoAddtrained.rating as rating
from InfoAddtrained
where trained = false;
--6 trainedDriver(Did, rid, day, rating)
CREATE view trainedDriver as
select InfoAddtrained.driver_id as driver_id,
        InfoAddtrained.request_id as request_id,
        InfoAddtrained.day as day,
        InfoAddtrained.rating as rating
from InfoAddtrained
where trained = true;

--7.1 first5day - trained
DROP VIEW IF EXISTS trainedEarly CASCADE;
CREATE VIEW trainedEarly AS
SELECT driver_id, request_id, day, rating 
FROM
(SELECT driver_id, request_id, day, rating,
dense_rank() OVER (PARTITION BY driver_id ORDER BY day ASC) AS row_number
FROM trainedDriver) subquery
WHERE row_number <= 5;

--7.2 first5day - untrained
DROP VIEW IF EXISTS untrainedEarly CASCADE;
CREATE VIEW untrainedEarly AS
SELECT driver_id, request_id, day, rating 
FROM
(SELECT driver_id, request_id, day, rating,
dense_rank() OVER (PARTITION BY driver_id ORDER BY day ASC) AS row_number
FROM untrainedDriver) subquery
WHERE row_number <= 5;

--8.1
DROP VIEW IF EXISTS trainedLate CASCADE;
CREATE VIEW trainedLate AS(
(SELECT * FROM trainedDriver)
EXCEPT
(SELECT * FROM trainedEarly));

--8.2
DROP VIEW IF EXISTS untrainedLate CASCADE;
CREATE VIEW untrainedLate AS(
(SELECT * FROM untrainedDriver)
EXCEPT
(SELECT * FROM untrainedEarly));

-- avg trained first 5
DROP VIEW IF EXISTS trainedearlyAvg CASCADE;
CREATE view trainedearlyAvg as
select avg(avgRating) as avgRating
from
(select trainedEarly.driver_id, avg(trainedEarly.rating) as avgRating
from trainedEarly
group by driver_id) subquery;

-- avg trained after 5
DROP VIEW IF EXISTS trainedlateAvg CASCADE;
CREATE view trainedlateAvg as
select avg(avgRating) as avgRating
from
(select trainedLate.driver_id, avg(rating) as avgRating
from trainedLate
group by driver_id) subquery;
-------------
-- avg untrained first 5
DROP VIEW IF EXISTS untrainedearlyAvg CASCADE;
CREATE view untrainedearlyAvg as
select avg(avgRating) as avgRating
from
(select untrainedEarly.driver_id, avg(rating) as avgRating
from untrainedEarly
group by driver_id) subquery;

-- avg untrained after 5
DROP VIEW IF EXISTS untrainedlateAvg CASCADE;
CREATE view untrainedlateAvg as
select avg(avgRating) as avgRating
from
(select untrainedLate.driver_id, avg(rating) as avgRating
from untrainedLate
group by driver_id) subquery;


DROP VIEW IF EXISTS trainedRow CASCADE;
CREATE VIEW trainedRow AS
select 'trained' as type, sub.count, trainedearlyAvg.avgRating as early, trainedlateAvg.avgRating as late
from
(select count(distinct driver_id)
from trainedDriver) sub, trainedearlyAvg, trainedlateAvg;


DROP VIEW IF EXISTS untrainedRow CASCADE;
CREATE VIEW untrainedRow AS
select 'untrained' as type, sub.count, untrainedearlyAvg.avgRating as early, untrainedlateAvg.avgRating as late
from
(select count(distinct driver_id)
from untrainedDriver) sub, untrainedearlyAvg, untrainedlateAvg;


-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q4
(select * from trainedRow)
union
(select * from untrainedRow);