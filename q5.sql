-- Bigger and smaller spenders.

-- You must not change the next 2 lines or the table definition.
SET SEARCH_PATH TO uber, public;
DROP TABLE IF EXISTS q5 CASCADE;

CREATE TABLE q5(
    client_id INTEGER,
    month VARCHAR(7),
    total FLOAT,
    comparison VARCHAR(30)
);


-- Do this for each of the views that define your intermediate steps.  
-- (But give them better names!) The IF EXISTS avoids generating an error 
-- the first time this file is imported.
DROP VIEW IF EXISTS avgForEachExistMonth CASCADE;
DROP VIEW IF EXISTS partialClientSpend CASCADE;
DROP VIEW IF EXISTS allexistMonths CASCADE;
DROP VIEW IF EXISTS intermediate_step CASCADE;
DROP VIEW IF EXISTS allClient CASCADE;
DROP VIEW IF EXISTS fullInfoTable CASCADE;
DROP VIEW IF EXISTS compareTable CASCADE;


-- Define views for your intermediate steps here:
-- avgForEachMonth(month, avg)
CREATE view avgForEachExistMonth as
select to_char(Request.datetime, 'YYYY MM') as month, avg(amount) as avg
from Request, Billed
where Request.request_id = Billed.request_id
group by to_char(Request.datetime, 'YYYY MM');

-- partialClientSpend(client_id, month, total_spend)
CREATE view partialClientSpend as
select Request.client_id, to_char(Request.datetime, 'YYYY MM') as month, sum(amount) as total_spend
from Billed, Request
where Billed.request_id = Request.request_id
group by Request.client_id, to_char(Request.datetime, 'YYYY MM');

-- allExistMonths
CREATE view allExistMonths as
select month
from partialClientSpend
group by month;

-- allClient
CREATE view allClient as
select distinct client_id
from Client;
--AllClientMonth
CREATE VIEW AllClientMonth as
select *
from allClient, allExistMonths;

-- fullInfoTable(client_id, month, total_spend)
CREATE view fullInfoTable as
select AllClientMonth.client_id, AllClientMonth.month, COALESCE(total_spend, 0) as total_spend
from AllClientMonth
left join partialClientSpend
on AllClientMonth.client_id = partialClientSpend.client_id
and AllClientMonth.month = partialClientSpend.month
order by AllClientMonth.client_id, AllClientMonth.month;
--
CREATE view compareTable as
select fullInfoTable.client_id, fullInfoTable.month, fullInfoTable.total_spend,
case when fullInfoTable.total_spend >= avg 
then 'at or above' ELSE 'below' END AS comparison
from fullInfoTable
left join avgForEachExistMonth
on fullInfoTable.month = avgForEachExistMonth.month;


-- Your query that answers the question goes below the "insert into" line:
INSERT INTO q5
select * from compareTable;
