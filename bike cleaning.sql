SELECT * FROM bike.bike_buyers;

-- 1. create new table for data manipulation
create table bike like bike_buyers;

insert into bike 
select * from bike_buyers;

select * from bike;

-- 2. remove duplicates
-- method 1 remove ID with duplicated rows
delete from bike 
where ID in (
	select ID
    from bike_buyers
    group by ID, Gender, Education
    having count(*) > 1
);

-- method 2 remove duplicated rows
drop table bike;
create table bike like bike_buyers;
alter table bike add column row_num int;
insert into bike 
select *,
	ROW_NUMBER() OVER(PARTITION BY ID, Gender, Education)
from bike_buyers;
delete from bike  where row_num > 1;
alter table bike drop column row_num;
select * from bike;

-- 3. standardising
-- trim leading and trailing white space
update bike set Education = Trim(Education);

-- trim trailing characters as '.'
select distinct Region from bike;
update bike set Region = Trim(LEADING '/' FROM Region);

select distinct Occupation from bike;
select * from bike where Occupation like 'Man%';
update bike set Occupation = Trim(TRAILING '.' FROM Occupation);

-- date/timestamp column
drop table london;
create table london like london_merged;
insert into london select * from london_merged;
select * from london;

update london 
set `timestamp` = STR_TO_DATE(`timestamp`, '%Y-%m-%d %T'); -- %T = %H:%i:%s 24 hour time
alter table london modify column `timestamp` datetime; -- change type from text to datetime

alter table london add `date` date, add `time` time;
update london set `date` = DATE(`timestamp`), `time` = TIME(`timestamp`);

-- 4. populate NULL value
select * from bike;
select distinct `Marital Status` from bike order by `Marital Status`; -- show blank
update bike set `Marital Status` = NULL where `Marital Status` = '';
select * from bike where `Marital Status` is null;
select * from bike where ID = 14939; -- status of same person
update bike set `Marital Status` = 'Single' where ID = 14939 and `Marital Status` is null;
-- drop rows with confidence

-- 5. remove useless columns
-- alter table X drop column x;


-- copy table
alter table londonbike rename london_sale;
create table sale
select * from london_sale;
select * from sale;
