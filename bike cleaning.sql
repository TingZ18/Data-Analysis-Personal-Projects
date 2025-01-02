SELECT * FROM bike.bike_buyers;
USE bike;

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
drop table if exists bike;
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
drop table if exists london;
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



-- 11. stored procedure
delimiter $$
create procedure tab3()
begin
	select * from bike;
	select * from sale;
	select * from london;
end $$
delimiter ;
call tab3();

drop procedure if exists arg;
delimiter $$
create procedure arg(IN num int, OUT ma char, fe int)
begin
	select count(*) into ma from bike
    where ID = num and gender = 'Male';
    select count(*) into fe from bike where ID = num and gender = 'female';
end $$
delimiter ;
call arg(11090, @ma, @fe);
select @ma, @fe;

drop procedure if exists arg2;
delimiter $$
create procedure arg2(IN ge varchar(50))
begin
	select * from bike
    where FIND_IN_SET(gender, ge)
    order by gender;
end $$
delimiter ;
call arg2('Male,'); -- 'Male' and ''

-- another way to pass multiple values: 
-- put the rows in a temporary table and pass in its name
drop procedure if exists temp_p;
delimiter go
create procedure temp_p()
begin
	select temp_t.ID, temp_t.gender, bike.ID, bike.gender from temp_t
    join bike
    on temp_t.ID = bike.ID + 1;
end go
delimiter ;
drop temporary table if exists temp_t;
create temporary table temp_t
select * from bike
where ID < 12000;
call temp_p();



-- 12. trigger
drop table if exists temp_tri1;
drop table if exists temp_tri2;
create table temp_tri1 select ID, gender, education from bike where ID < 11050;
create table temp_tri2 select ID, gender, education from bike where ID = 11090;

drop trigger if exists temp_insert;
delimiter $$
create trigger temp_insert
	after insert on temp_tri1
    for each row
begin
	insert into temp_tri2 (ID, gender, education)
    values (new.ID, new.gender, new.education);
end $$
delimiter ;

insert into temp_tri1 (ID, gender, education)
values (20000, 'Female', 'College');
select * from temp_tri1;
select * from temp_tri2;



-- event
drop table if exists temp_tri1;
create table temp_tri1 select ID, gender, education from bike where ID < 11050;

drop event if exists delete_male;
delimiter $$
create event delete_male
on schedule every 3 second
do
begin
	delete from temp_tri1
    where gender = 'Male';
end $$
delimiter ;

select * from temp_tri1;
show variables like 'event%'; -- event_scheduler ON



-- date and time
alter table sale add `date` char(10), add `time` char(10);
update sale set `date` = substr(`Start date`, 1, locate(' ', `Start date`) - 1),
				`time` = substr(`Start date` from locate(' ', `Start date`) + 1);
update sale set `date` = str_to_date(`date`, '%d/%c/%Y');
alter table sale modify `date` date;
update sale set `time` = str_to_date(concat(`time`, ':00'), '%k:%c:%s');
alter table sale modify `time` time;
select * from sale;

-- CTE common table expression
with sale_cte as
(
select `date` as s_date, `Start station` as station
from sale
where `Start station number` < 2000
), london_cte as 
(
select `date` as l_date, `time` as l_time, cnt
from london
where `time` < current_time()
)
select *
from sale_cte
join london_cte
on s_date = l_date + interval 8 year; -- add years

-- case statement
select distinct Gender from bike order by 1;
select * from bike where Gender = '';
select ID, Gender, Income,
case
	when Income < 60000 then 'Male'
    when Income < 80000 then 'Female'
    else null
end as imp
from bike 
where Gender = '';

-- string function: trim, left, right, substr/substring, locate, concat, and
select Education, upper(Education), lower(education) from bike;
select education, length(education), replace(education, 'o','zz') from bike;

-- subquery
select * from bike
where `Home Owner` in (
	select `Home Owner`
    from bike
    where ID = 11090
);

select gender, avg(Children),
(select avg(children) from bike)
from bike
group by gender;

select gender, avg(ma), avg(mi), avg(cnt)
from (
select gender, count(children) as ma, count(children) as mi, avg(children) as cnt
from bike
group by gender
) as frm
group by gender;

-- window function
select ID, Gender, Income,
	rank() over(partition by Gender order by Income) as ord_income,
	sum(Income) over(partition by Gender order by ID) as agg_income
from bike;

-- union
select ID, 'Many children Male' as Label 
from bike 
where children > 3 and gender = 'Male'
union 
select ID, 'Many cars Male' as Label 
from bike 
where cars > 3 and gender = 'Male'
order by 1;

-- join
select a.ID as ID_a, a.income as income_a, 
		b.ID as ID_b, b.income as income_b
from bike as a
join bike as b
on a.ID = b.ID + 1
order by ID_a;

select ID, gender, income, `Start station`, sale.`date`, cnt
from bike
join sale
on bike.ID = sale.`Start station number`
join london
on sale.`date` = london.`date` + interval 8 year;

-- temporary table
drop table if exists temp_table;
create temporary table temp_table
select * from bike 
where ID < 12000;
select * from temp_table;

create temporary table temp2
(a varchar(10),
b int,
c time);
select * from temp2;
insert into temp2
values("ting", 3, "01:09:13");

-- check column type
SHOW COLUMNS FROM temp2 FROM bike;