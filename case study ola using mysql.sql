create database case_ola;
use case_ola;

select * from data;
select * from localities;

-- 1. Find hour of 'pickup' and 'confirmed_at' time, and make a column of weekday as "Sun,Mon, etc"next to pickup_datetime

select pickup_time,hour(pickup_time),Confirmed_at,hour(str_to_date(confirmed_at,"%d-%m-%Y %H:%i")),
pickup_datetime,dayname(str_to_date(pickup_datetime,"%d-%m-%Y"))
from data;
                                                                               


-- 2. Make a table with count of bookings with booking_type = p2p catgorized by booking mode as 'phone', 'online','app',etc

select booking_mode, count(Booking_mode)
from data
where booking_type = "p2p"
group by booking_mode;


-- 3. Create columns for pickup and drop ZONES (using Localities data containing Zone IDs against each area) 
-- and fill corresponding values against pick-area and drop_area, using Sheet'Localities'
                                                                                          

select d.PickupArea, "" as DropArea, l.area
from data d left join localities l 
on d.droparea = l.area 
union
select "", d.DropArea, la.area
from data d left join localities la
on d.dropArea = la.area;



-- 4. Find top 5 drop zones in terms of  average revenue

SELECT Zone_id, avg(fare) as AverageFare
FROM Localities as L INNER JOIN Data as D 
ON L.Area = d.droparea
Group by Zone_id
Order By Avg(Fare) DESC
Limit 5;


-- 5. Find all unique driver numbers grouped by top 5 pickzones

select PickupArea,count(PickupArea)
from data
group by pickupArea
having PickupArea <> ""
order by 2 desc limit 5;
                                                                                 
select PickupArea, Driver_number,count(driver_number)
from data
where PickupArea in ("airport terminal 1","airport terminal 3","address (optional)","new delhi railway station","noida sector 62")
group by PickupArea, driver_number
having count(driver_number) = 1
order by 1 asc;



-- it is final work

Create View Top5PickZones As
SELECT zone_id, Sum(fare) as SumRevenue
FROM Data as D, Localities as L
WHERE D.pickuparea = L.Area
Group By Zone_id
Order By 2 DESC
Limit 5;

SELECT Distinct zone_id, driver_number
FROM localities as L INNER JOIN Data as D ON L.Area = D.PickupArea
WHERE zone_id IN (Select Zone_id FROM Top5PickZones)
order by 1, 2;




-- 6. Make a list of top 10 driver by driver numbers in terms of fare collected where service_status is done, done-issue

select Driver_number,fare,Service_status
from data
where Service_Status in ("done", "done-issue")
order by 2 desc limit 10;                                 
                                                                               

with cte as (
select Driver_number,fare,Service_status,
row_number() over (partition by service_status order by fare desc) as position
from data
where Service_Status in ("done", "done-issue")
)
select * from cte
where position <= 10;




-- 7. Make a hourwise table of bookings for week bw Nov01-Nov-07 and highlight the hrs with more than avg no.of bookings day wise

with cte1 as (
with cte as (
select str_to_date(confirmed_at,"%d-%m-%Y %H:%i") as booking, 
day(str_to_date(confirmed_at,"%d-%m-%Y %H:%i")) as day, 
hour(str_to_date(confirmed_at,"%d-%m-%Y %H:%i")) as hr
from data
where str_to_date(confirmed_at,"%d-%m-%Y %H:%i") between "2013-11-01" and "2013-11-07" 
)
select day, avg(hr) avg_hr
from cte
group by day
)
select day, avg_hr
from cte1
where avg_hr > (select avg(avg_hr) from cte1);
															


SELECT Hour(str_To_date(pickup_time,"%H:%i:%s")) as Hr, Count(*) as TotalBookings
FROM Data 
WHERE str_to_date(pickup_date,"%d-%m-%Y") between '2013-11-01' and '2013-11-07'
Group By Hour(str_to_date(pickup_time,"%H:%i:%s"))

HAVING Count(*) > (SELECT Avg(NoOfBookingsDaily)
FROM (

SELECT Day(str_to_date(pickup_date,"%d-%m-%Y")), count(*) as NoOfBookingsDaily
FROM data 
Group By Day(str_to_date(pickup_date,"%d-%m-%Y"))) as tt)
Order By 1 ASC;
