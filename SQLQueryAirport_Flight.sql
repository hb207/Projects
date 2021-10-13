
-- Create Flight table --
Create Table Flight (
flight_id int IDENTITY(1,1) primary key,
takeoff_time datetime,
landing_time datetime,
pilot_id int foreign key references Staff(staff_id),
time_zones int,
start_country varchar(255),
end_country varchar(255),
distance int,
cost int,
plane_id int foreign key references Plane(plane_id),
passengers int,
meal binary(1),
staff int
);

-- Update if needed --
update Flight
set landing_time = '20210916 15:15:00'
where flight_id in('84', '83');

-- Add Flight --
Insert into Flight 
Values ('20210916 14:00:00', '20210916 15:20:00', 73, 0, 'Scotland', 'England', 
570, 55, 4009, 97, 0, 0, 72, 27, 60, null, null);


-- Flights ordered by Revenue --
Select flight_id, start_country, end_country, cost, passengers, (passengers*cost) as "Revenue (£)"
From Airline..Flight
Order by 6 desc

-- Flight Capacity % (Join flight,plane) --
Select flight.flight_id, flight.start_country, flight.end_country, flight.passengers, plane.passenger_capacity,
(cast((passengers/cast(passenger_capacity as decimal(5,2)))*100 as decimal(5,2))) as "flight_capacity%"
From Flight
Inner Join Plane ON flight.plane_id=plane.plane_id;

-- Distance travelled (Plane) -- 
select flight.plane_id,sum(flight.distance) as Total, plane.plane_type
from Airline..Flight
inner join plane on flight.plane_id=plane.plane_id
   group by flight.plane_id, plane.plane_type
   order by Total desc;

-- Cumulative Distance & jetlag for each staff member --  
SELECT staff.staff_id, flight.flight_id, flight.crew1_id, flight.crew2_id, flight.crew3_id, flight.crew4_id,
flight.pilot_id, flight.copilot_id, flight.distance,
sum(distance) over (Partition by staff.staff_id) as TotalDistance, flight.time_dif, sum(flight.time_dif) over (Partition by staff.staff_id) as "Total +/- Jetlag"
FROM Flight
JOIN Staff
ON staff.staff_id = flight.crew1_id
or staff.staff_id = flight.crew2_id
or staff.staff_id = flight.crew3_id
or staff.staff_id = flight.crew4_id
or staff.staff_id = flight.pilot_id
or staff.staff_id = flight.copilot_id
group by staff_id, flight_id, crew1_id, crew2_id, crew3_id, crew4_id, pilot_id, copilot_id, distance, flight.time_dif
order by staff_id, flight_id
