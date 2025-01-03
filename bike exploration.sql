use bike;

alter table sale rename station;
alter table sale_london rename station_london;
alter table bike rename sale;

select * from sale;
select * from london;
select * from station;

-- 1. male purchased bike number of each region
select Gender, Region, `Purchased Bike`, count(*) as cnt
from sale 
where gender = "Male" and `Purchased Bike` = 'Yes'
group by gender, region, `Purchased Bike`
order by cnt desc;

-- 2. commute distance and bike purchasing cross-table
select a.`Commute Distance`, Purchased, Non_Purchased, Total
from (select `Commute Distance`, count(*) as Purchased
from sale
where `Purchased Bike` = 'Yes'
group by `Commute Distance`) a 
join (select `Commute Distance`, count(*) as Non_Purchased
from sale
where `Purchased Bike` = 'No'
group by `Commute Distance`) b 
on a.`Commute Distance` = b.`Commute Distance` 
join (select `Commute Distance`, count(*) as Total
from sale
group by `Commute Distance`) c
on a.`Commute Distance` = c.`Commute Distance` 
order by field(a.`Commute Distance`, '0-1 Miles','1-2 Miles','2-5 Miles','5-10 Miles','10+ Miles');

-- 3. income level of bike purchaser
select 'High Income' as `Income Level`, count(*) as cnt, round(avg(income),2) as avg_income
from sale 
where `Purchased Bike` = 'Yes' and income >= 80000
union 
select 'Low Income' as `Income Level`, count(*) as cnt, round(avg(income),2) as avg_income
from sale 
where `Purchased Bike` = 'Yes' and income < 80000;
-- OR
select `Income Level`, 
	count(*) as cnt,
	round(avg(income),2) as avg_income
from (
select `Purchased Bike`, income, 
	case 
		when income < 80000 then 'Low Income'
        when income >= 80000 then 'High Income'
	end as `Income Level`
from sale
) inc
where `Purchased Bike` = 'Yes'
group by `Income Level`;

-- 4. what occupation's income is the highest among bike purchaser
with temp as (
select Occupation, round(avg(income),2) as avg_income
from sale
where `Purchased Bike` = 'Yes'
group by Occupation)
select Occupation, avg_income, 
rank() over (order by avg_income desc) as rank_income
from temp;

-- 5. car number difference between bike purchasers and non-purchasers
with temp as (
select `Purchased Bike`, row_number() over (order by `Purchased Bike`) as row_cars, avg(cars) as avg_cars
from sale 
group by `Purchased Bike`)
select a.`Purchased Bike`, a.avg_cars, b.`Purchased Bike`, b.avg_cars, (a.avg_cars - b.avg_cars) as diff_cars
from temp a
join temp b
on a.row_cars = (b.row_cars - 1);

-- 6. view max and min age of bike purchaser in terms of marital status
drop view if exists view_age;
create view view_age as 
select `Marital Status`, min(age) as min_age, max(age) as max_age
from sale
where `Purchased Bike` = 'Yes'
group by `Marital Status`
order by 1;

select * from view_age;

insert into sale (`Marital Status`, `Purchased Bike`, Age) values ('Single', 'Yes', 20);
select * from view_age;

delete from sale where age = 20;
select * from view_age;

-- 7. average income relative to number of children between bike purchasers and non-purchasers
select `Purchased Bike`, Children, avg(income) as avg_income, 
	rank() over (partition by `Purchased Bike` order by avg(income) desc) as rank_income
from sale
group by `Purchased Bike`, children;

-- 8. home owner bike purchasers' average cars
update sale set `Home Owner` = null where `Home Owner` = '';
select * from 
(select `Home Owner`, `Purchased Bike`, avg(cars) as avg_car
from sale
where `Home Owner` is not null
group by `Purchased Bike`, `Home Owner`
order by field(`Home Owner`, 'Yes','No'), field(`Purchased Bike`, 'Yes','No')
) a
union
select * from 
(select `Home Owner`, 'Total' as label, avg(cars) as avg_car
from sale
where `Home Owner` is not null
group by `Home Owner`
order by field(1, 'Yes','No')
) b;
