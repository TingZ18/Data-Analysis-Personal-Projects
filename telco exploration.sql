use telco;

-- 1. view all tables procedure
drop procedure if exists tabs;
delimiter $$
create procedure tabs()
begin
	DECLARE cnt INT;
    declare tn varchar(100);
    DECLARE cur CURSOR FOR SELECT DISTINCT table_name FROM information_schema.tables Where table_schema = 'telco';

    SELECT count(*) into cnt from information_schema.tables Where table_schema = 'telco';
    
    OPEN cur;
		read_loop: LOOP
			FETCH cur INTO tn; -- select tn;
			SET @s = CONCAT('select * from ', tn); 
			PREPARE shtn FROM @s;
			EXECUTE shtn;
			DEALLOCATE PREPARE shtn;
            
            SET cnt = cnt - 1;
			IF cnt = 0 THEN
				LEAVE read_loop;
			END IF;
            
		END LOOP read_loop;
	CLOSE cur;
end $$
delimiter ;

call tabs();

-- 2. payment contract summary in customers under a certain age and of a certain gender
drop procedure if exists pays;
delimiter $$
create procedure pays(in age_p int, gender_p varchar(10))
begin
	select contract, avg(age) as avg_age, avg(total_charges) as avg_charges
    from customer_info a
    join payment_info b
    on a.customer_id = b.customer_id
    where age <= age_p and gender = gender_p
    group by contract;
end $$
delimiter ;

call pays(30, 'Male');

-- 3. average satisfaction score and total number of referred friends regards to whether referring a friend and internet type
drop procedure if exists ref_s;
delimiter //
create procedure ref_s(IN ref_p varchar(10), IN int_p varchar(20), OUT avg_sat decimal(5,2), OUT cnt_ref int)
begin
	select avg(b.satisfaction_score) into avg_sat
	from online_services a
	join status_analysis b
	on a.customer_id = b.customer_id
	join service_options c
	on a.customer_id = c.customer_id
	where a.internet_type = int_p and c.referred_a_friend = ref_p;
    
    select COALESCE(sum(coalesce(c.number_of_referrals,0)), 0) into cnt_ref
    from service_options c
    join online_services a
    on a.customer_id = c.customer_id
    where a.internet_type = int_p and c.referred_a_friend = ref_p;
end //
delimiter ;

call ref_s('Yes','DSL', @avg_sat, @cnt_ref);
select @avg_sat, @cnt_ref;

-- 4. internet type summary in certain cities
drop procedure if exists int_type;
delimiter //
CREATE PROCEDURE int_type (IN city_p VARCHAR(500))
BEGIN
    SET @sql_con = CONCAT('select city, internet_type, count(*) as cnt_type
							from location_data a
							join online_services b
							on a.customer_id = b.customer_id
							where city in (', city_p, ')
                            group by city, internet_type
                            order by city, internet_type');
    PREPARE stmt FROM @sql_con;
    EXECUTE stmt;
    DEALLOCATE PREPARE stmt;
END //
delimiter ;

call int_type("'Napa', 'Sheridan', 'Sunnyvale', 'Daly City'");

-- 5. customer stayed proportion in certain churn score range
drop procedure if exists pro;
delimiter &&
create procedure pro()
begin
	set @tot = (select count(*) as cnt_t from sco_ran); -- can't reopen temporary table
	select customer_status, avg(churn_score) as avg_sco, count(*) as cnt,
			concat(round((count(*) / @tot * 100), 2), '%') as prop
    from sco_ran
    group by customer_status;
end &&
delimiter ;

drop temporary table if exists sco_ran;
create temporary table sco_ran as 
select * 
from status_analysis 
where churn_score > 50; 

call pro();

-- 6. summing total revenue newly inserted into the payment table
drop trigger if exists pay_sum;
create trigger pay_sum before insert on payment_info
for each row set @rev_sum = @rev_sum + new.total_revenue;
set @rev_sum = (select sum(total_revenue) from payment_info);

insert into payment_info (customer_id, total_revenue) values ('0099-GWOEG', 20000), ('0293-RWIOE', 30000);
select @rev_sum as 'total revenue';

delete from payment_info where total_revenue in (20000,30000);

-- 7. update customer list under 20;
drop table if exists cus_age;
create temporary table cus_age
select customer_id, gender, age
from customer_info 
where age < 20;

drop trigger if exists cus_add;
delimiter %%
create trigger cus_add 
after insert on customer_info
for each row 
begin
	if new.age < 20 then
		insert into cus_age values (new.customer_id, new.gender, new.age);
	end if;
end %%
delimiter ;

insert into customer_info (customer_id, gender, age) values ('8883-WERWI', 'Male', 100), ('2304-WIERW', 'Female', 18);
select * from cus_age;

delete from customer_info where age in (18, 100);

