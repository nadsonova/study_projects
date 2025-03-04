-- 1. Выведите названия самолётов, которые имеют менее 50 посадочных мест.


select a.model, t_seats.count
from aircrafts a 
join (select s.aircraft_code, count(s.seat_no)
	from seats s
	group by s.aircraft_code
) t_seats on a.aircraft_code = t_seats.aircraft_code and t_seats.count < 50


-- 2. Выведите процентное изменение ежемесячной суммы бронирования билетов, округленной до сотых.


select date_trunc('month', book_date)::date date_value,
	round((sum(total_amount) - lag(sum(total_amount)) over()) / (lag(sum(total_amount)) over ()) * 100, 2) percent_change
from bookings b 
group by date_trunc('month', book_date)
order by date_trunc('month', book_date)


-- 3. Выведите названия самолётов без бизнес-класса. Используйте в решении функцию array_agg.


select a.model, t_seats.array_agg
from aircrafts a
join (select s.aircraft_code, array_agg(distinct s.fare_conditions)
	from seats s 
	group by s.aircraft_code) t_seats on a.aircraft_code = t_seats.aircraft_code 
		and array_position(t_seats.array_agg, 'Business') is null


/* 4. Выведите накопительный итог количества мест в самолётах по каждому аэропорту на каждый день. 
Учтите только те самолеты, которые летали пустыми и только те дни, когда из одного аэропорта вылетело более одного такого самолёта.

Выведите в результат код аэропорта, дату вылета, количество пустых мест и накопительный итог.*/

		
select t_flights.departure_airport, 
	t_flights.actual_departure::date, 
	t_seats.seats_count,
	sum(t_seats.seats_count) over (partition by t_flights.departure_airport, t_flights.actual_departure::date order by t_flights.actual_departure)
from (
	select f.departure_airport, f.actual_departure, f.aircraft_code,
		count(f.flight_id) over (partition by f.departure_airport, f.actual_departure::date) 
	from flights f 
	where f.actual_departure is not null and f.flight_id not in (
		select distinct bp.flight_id
		from boarding_passes bp)) t_flights
join (
	select aircraft_code, count(seat_no) seats_count
	from seats
	group by aircraft_code) t_seats on t_flights.aircraft_code = t_seats.aircraft_code and t_flights.count > 1	
		

/* 5. Найдите процентное соотношение перелётов по маршрутам от общего количества перелётов. 
Выведите в результат названия аэропортов и процентное отношение.

Используйте в решении оконную функцию.*/


select a_departure.airport_name departure_airport_name, 
	a_arrival.airport_name arrival_airport_name, 
	t_flights.count::float / t_flights.flights_count * 100 flight_percentage
from airports a_departure
join (select departure_airport, arrival_airport,
		count(flight_id) over (partition by departure_airport, arrival_airport),
		row_number() over (partition by departure_airport, arrival_airport),
		count(flight_id) over () flights_count
	from flights) t_flights on t_flights.departure_airport = a_departure.airport_code and count = row_number
join airports a_arrival on t_flights.arrival_airport = a_arrival.airport_code


-- 6. Выведите количество пассажиров по каждому коду сотового оператора. Код оператора – это три символа после +7

		
select substring(contact_data ->> 'phone' from 3 for 3) code, 
	count(passenger_id) passengers_count
from tickets
group by code


/* 7. Классифицируйте финансовые обороты (сумму стоимости билетов) по маршрутам:
 до 50 млн – low
 от 50 млн включительно до 150 млн – middle
 от 150 млн включительно – high
 Выведите в результат количество маршрутов в каждом полученном классе.*/


select amounts_class, count(*)
from (
	select f.departure_airport, f.arrival_airport, sum(tf.amount),
		case 
			when sum(tf.amount) < 50000000 then 'low'
			when sum(tf.amount) between 50000000 and 150000000 then 'middle'
			else 'high'
		end	amounts_class
	from flights f 
	join ticket_flights tf on f.flight_id = tf.flight_id 
	group by f.departure_airport, f.arrival_airport) t_amount
group by amounts_class


-- 8*. Вычислите медиану стоимости билетов, медиану стоимости бронирования и отношение медианы бронирования к медиане стоимости билетов, результат округлите до сотых. 


with cte_tickets as (
	select percentile_cont(0.5) WITHIN GROUP (ORDER BY tf.amount) tickets_amount
	from ticket_flights tf),
cte_bookings as (
	select percentile_cont(0.5) WITHIN GROUP (ORDER BY b.total_amount) bookings_amount
	from bookings b)
select cte_tickets.tickets_amount, 
	cte_bookings.bookings_amount, 
	round((cte_bookings.bookings_amount/cte_tickets.tickets_amount)::numeric, 2)
from cte_tickets, cte_bookings 


/* 9*. Найдите значение минимальной стоимости одного километра полёта для пассажира. Для этого определите расстояние между аэропортами и учтите стоимость билетов.

Для поиска расстояния между двумя точками на поверхности Земли используйте дополнительный модуль earthdistance. Для работы данного модуля нужно установить ещё один модуль – cube.

Важно: 
Установка дополнительных модулей происходит через оператор CREATE EXTENSION название_модуля.
В облачной базе данных модули уже установлены.
Функция earth_distance возвращает результат в метрах.*/


CREATE extension cube

CREATE extension earthdistance

-- Это вариант побыстрее
select min(t.amount/(earth_distance(ll_to_earth(a.latitude, a.longitude), ll_to_earth(aa.latitude, aa.longitude))/1000))
from (
	select f.departure_airport, 
		f.arrival_airport, 
		tf.amount
	from flights f
	join ticket_flights tf on f.flight_id = tf.flight_id
	group by f.departure_airport, f.arrival_airport, tf.amount) t
join airports a on t.departure_airport = a.airport_code 
join airports aa on t.arrival_airport  = aa.airport_code


-- Это более медленный вариант
select min(tf.amount/(earth_distance(ll_to_earth(a.latitude, a.longitude), ll_to_earth(aa.latitude, aa.longitude))/1000))
from flights f
join ticket_flights tf on f.flight_id = tf.flight_id
join airports a on f.departure_airport = a.airport_code 
join airports aa on f.arrival_airport  = aa.airport_code



/*

- Рейс, перелёт – это flight_id, разовый перелет между двумя аэропортами
- Маршрут – это все перелёты между двумя аэропортами.
- Знак *  указан рядом с заданиями на самостоятельную работу с документацией PostgreSQL.

aircrafts - самолеты
airports - аэропорты
boarding_passes - посадочные талоны
bookings - бронирование
flights - рейсы
seats - места
ticket_flights - перелеты
tickets - билеты

1 бронирование  	- N пассажиров
1 пассажир			- 1 билет (tickets)
1 билет				- N перелетов (ticket_flights). Несколько белетов - это пересадка, либо билет туда-обратно
1 рейс (flights)	- из 1 аэропорта в другой (airports). Одинаковый номер рейса - одинаковые пункты вылета и назначения, на дата отправления разная
1 модель самолета 	- 1 компановка салона (количество мест и распределение)

посадочный талон (boarding_passes):
- выдается пассажиру при регистрации
- указано место в самолете
- регистрация только на тот рейс, который в билете пассажира
- комбинация (рейс, место) уникальна

*/