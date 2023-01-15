-- Frequent riders.

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO uber, public;
DROP TABLE IF EXISTS q6 CASCADE;

CREATE TABLE q6(
    client_id INTEGER,
    year CHAR(4),
    rides INTEGER
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS HasRideYear CASCADE;
DROP VIEW IF EXISTS exitsYears CASCADE;
DROP VIEW IF EXISTS ClientExitsYears CASCADE;
DROP VIEW IF EXISTS fullTable CASCADE;
---------------------------
DROP VIEW IF EXISTS theMost CASCADE;
DROP VIEW IF EXISTS DelectMost CASCADE;
DROP VIEW IF EXISTS theSecondMost CASCADE;
DROP VIEW IF EXISTS DelectSecondMost CASCADE;
DROP VIEW IF EXISTS theThirdMost CASCADE;
-------------------------
DROP VIEW IF EXISTS theLeast CASCADE;
DROP VIEW IF EXISTS theSecondLeast CASCADE;
DROP VIEW IF EXISTS DelectLeast CASCADE;
DROP VIEW IF EXISTS DelectSecondLeast CASCADE;
DROP VIEW IF EXISTS theThirdLeast CASCADE;



-- Define views for your intermediate steps here:
CREATE view HasRideYear as
select Request.client_id, to_char(Request.datetime, 'YYYY') as year, count(Dropoff.request_id) as ride_numb
from Dropoff, Request
where Dropoff.request_id = Request.request_id
group by client_id, to_char(Request.datetime, 'YYYY');

CREATE view exitsYears as
select distinct year
from HasRideYear;

CREATE view ClientExitsYears as
select client_id, year
from Client, exitsYears;

CREATE view fullTable as
select ClientExitsYears.client_id, ClientExitsYears.year, COALESCE(ride_numb, 0) as ride_numb
from ClientExitsYears
left join HasRideYear
on ClientExitsYears.client_id = HasRideYear.client_id and ClientExitsYears.year = HasRideYear.year;

-- theMost, table delect the most
CREATE view theMost as 
select *
from fullTable f1
where ride_numb = (select max(ride_numb) from fullTable 
group by fullTable.year
having f1.year = fullTable.year);

CREATE view DelectMost as
(select * from fullTable)
except
(select * from theMost);
-- thesecondMost, table delect the second most
CREATE view theSecondMost as 
select *
from DelectMost f1
where ride_numb = (select max(ride_numb) from DelectMost 
group by DelectMost.year
having f1.year = DelectMost.year);

CREATE view DelectSecondMost as
(select * from DelectMost)
except
(select * from theSecondMost);
-- the third Most
CREATE view theThirdMost as 
select *
from DelectSecondMost f1
where ride_numb = (select max(ride_numb) from DelectSecondMost 
group by DelectSecondMost.year
having f1.year = DelectSecondMost.year);

----------------------------------------------------------------------

-- the least
CREATE view theLeast as 
select *
from fullTable f1
where ride_numb = (select min(ride_numb) from fullTable 
group by fullTable.year
having f1.year = fullTable.year);

CREATE view DelectLeast as
(select * from fullTable)
except
(select * from theLeast);

-- thesecondLeast, table delect the second least
CREATE view theSecondLeast as 
select *
from DelectLeast f1
where ride_numb = (select min(ride_numb) from DelectLeast 
group by DelectLeast.year
having f1.year = DelectLeast.year);

CREATE view DelectSecondLeast as
(select * from DelectLeast)
except
(select * from theSecondLeast);

-- thesecondLeast, table delect the second least
CREATE view theThirdLeast as 
select *
from DelectSecondMost f1
where ride_numb = (select min(ride_numb) from DelectSecondMost 
group by DelectSecondMost.year
having f1.year = DelectSecondMost.year);

--answer
CREATE view answer as
(select client_id, year, ride_numb from theMost) 
union 
(select client_id, year, ride_numb from theSecondMost)
union 
(select client_id, year, ride_numb from theThirdMost)
union
(select client_id, year, ride_numb from theLeast)
union 
(select client_id, year, ride_numb from theSecondLeast)
union
(select client_id, year, ride_numb from theThirdLeast);


-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q6
select * 
from answer
order by answer.client_id, answer.year;