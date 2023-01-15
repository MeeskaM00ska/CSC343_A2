-- Lure them back.

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO uber, public;
DROP TABLE IF EXISTS q2 CASCADE;

CREATE TABLE q2(
    client_id INTEGER,
    name VARCHAR(41),
  	email VARCHAR(30),
  	billed FLOAT,
  	decline INTEGER
);

-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS MoreThan500b4_2020 CASCADE;
DROP VIEW IF EXISTS Oneto10rides_2020 CASCADE;
DROP VIEW IF EXISTS RideNumIn_2021 CASCADE;
DROP VIEW IF EXISTS RideNumLessThan_2020 CASCADE;

-- Define views for your intermediate steps here:
CREATE view MoreThan500b4_2020 as
select Client.client_id, concat(firstname, ' ', surname) as name, email, sum(amount) as billed
from Billed
join Request on Billed.request_id = Request.request_id
join client on Request.client_id = client.client_id
where date_part('year', Request.datetime) < 2020
group by client.client_id
having sum(amount) >= 500;

CREATE view Oneto10rides_2020 as
select Client.client_id, concat(firstname, ' ', surname) as name, email, count(Dropoff.request_id) as rides
from Dropoff
join Request on Dropoff.request_id = Request.request_id
join client on Request.client_id = client.client_id
where date_part('year', Request.datetime) = 2020
group by client.client_id
having count(Dropoff.request_id) >= 1 and count(Dropoff.request_id) <= 10;

CREATE view RideNumIn_2021 as
select client.client_id, concat(firstname, ' ', surname) as name, email, count(Dropoff.request_id) as rides
from Dropoff
join Request on Dropoff.request_id = Request.request_id
join client on Request.client_id = client.client_id
where date_part('year', Request.datetime) = 2021
group by client.client_id;

CREATE view RideNumLessThan_2020 as
select Oneto10rides_2020.client_id, RideNumIn_2021.rides - Oneto10rides_2020.rides as decline
from Oneto10rides_2020, RideNumIn_2021
where Oneto10rides_2020.rides > RideNumIn_2021.rides and Oneto10rides_2020.client_id = RideNumIn_2021.client_id;

-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q2
select MoreThan500b4_2020.client_id, MoreThan500b4_2020.name, MoreThan500b4_2020.email, MoreThan500b4_2020.billed, RideNumLessThan_2020.decline
from MoreThan500b4_2020, RideNumLessThan_2020
where MoreThan500b4_2020.client_id = RideNumLessThan_2020.client_id;