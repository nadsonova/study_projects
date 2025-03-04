--=============== МОДУЛЬ 3. ОСНОВЫ SQL =======================================
--= ПОМНИТЕ, ЧТО НЕОБХОДИМО УСТАНОВИТЬ ВЕРНОЕ СОЕДИНЕНИЕ И ВЫБРАТЬ СХЕМУ PUBLIC===========
SET search_path TO public;

--======== ОСНОВНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Выведите для каждого покупателя его адрес проживания, 
--город и страну проживания.


select c.customer_id, 
	c.first_name, 
	c.last_name, 
	a.address,
	city.city,
	country.country 
from customer c
left join address a on c.address_id = a.address_id
join city on a.city_id = city.city_id 
join country on city.country_id = country.country_id  


--ЗАДАНИЕ №2
--С помощью SQL-запроса посчитайте для каждого магазина количество его покупателей.


select s.store_id, count(c.customer_id)
from store s
join customer c on s.store_id = c.store_id 
group by s.store_id 


--Доработайте запрос и выведите только те магазины, 
--у которых количество покупателей больше 300-от.
--Для решения используйте фильтрацию по сгруппированным строкам 
--с использованием функции агрегации.


select s.store_id, count(c.customer_id)
from store s
join customer c on s.store_id = c.store_id 
group by s.store_id 
having count(c.customer_id) > 300


-- Доработайте запрос, добавив в него информацию о городе магазина, 
--а также фамилию и имя продавца, который работает в этом магазине.


select s.store_id, 
	count(c.customer_id), 
	c2.city, 
	s2.last_name, 
	s2.first_name 
from store s
join customer c on s.store_id = c.store_id
join address a on s.address_id = a.address_id 
join city c2 on a.city_id = c2.city_id 
join staff s2 on s.manager_staff_id = s2.staff_id 
group by s.store_id, c2.city_id, s2.staff_id  
having count(c.customer_id) > 300


--ЗАДАНИЕ №3
--Выведите ТОП-5 покупателей, 
--которые взяли в аренду за всё время наибольшее количество фильмов


select c.customer_id, 
	c.first_name, 
	c.last_name, 
	count(r.rental_id)
from customer c
join rental r on c.customer_id = r.customer_id
group by c.customer_id
order by count(r.rental_id) desc
limit 5


--ЗАДАНИЕ №4
--Посчитайте для каждого покупателя 4 аналитических показателя:
--  1. количество фильмов, которые он взял в аренду
--  2. общую стоимость платежей за аренду всех фильмов (значение округлите до целого числа)
--  3. минимальное значение платежа за аренду фильма
--  4. максимальное значение платежа за аренду фильма


select c.customer_id, 
	concat(c.first_name, ' ', c.last_name) "customer_name", 
	count(p.payment_id) "films_count",
	round(sum(p.amount)) "sum_amount",
	min(p.amount) "min_amount",
	max(p.amount) "max_amount"
from customer c 
join payment p on c.customer_id = p.customer_id
group by c.customer_id


--ЗАДАНИЕ №5
--Используя данные из таблицы городов, составьте все возможные пары городов так, чтобы 
--в результате не было пар с одинаковыми названиями городов. Решение должно быть через Декартово произведение.


select c1.city, c2.city
from city c1, city c2
where c1.city > c2.city


--ЗАДАНИЕ №6
--Используя данные из таблицы rental о дате выдачи фильма в аренду (поле rental_date) и 
--дате возврата (поле return_date), вычислите для каждого покупателя среднее количество 
--дней, за которые он возвращает фильмы. В результате должны быть дробные значения, а не интервал.
 

select customer_id, avg(return_date::date - rental_date::date)
from rental r 
group by r.customer_id 


--======== ДОПОЛНИТЕЛЬНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Посчитайте для каждого фильма сколько раз его брали в аренду и значение общей стоимости аренды фильма за всё время.


select f.film_id, 
	f.title, 
	count(r.rental_id) "rental_count", 
	sum(p.amount) "sum_amount"
from film f
join inventory i on f.film_id = i.film_id 
join rental r on i.inventory_id = r.inventory_id 
join payment p on r.rental_id = p.rental_id 
group by f.film_id
order by f.title


--ЗАДАНИЕ №2
--Доработайте запрос из предыдущего задания и выведите с помощью него фильмы, которые отсутствуют на dvd дисках.


select f.film_id, 
	f.title,
	count(t.rental_id) "rental_count", 
	sum(t.amount) "sum_amount"
from film f
left join (select i.film_id, r.rental_id, p.amount
	from inventory i
	join rental r on i.inventory_id = r.inventory_id 
	join payment p on r.rental_id = p.rental_id) t on f.film_id = t.film_id
where t.film_id is null
group by f.film_id 
order by f.title


--ЗАДАНИЕ №3
--Посчитайте количество продаж, выполненных каждым продавцом. Добавьте вычисляемую колонку "Премия".
--Если количество продаж превышает 7300, то значение в колонке будет "Да", иначе должно быть значение "Нет".


select p.staff_id, 
	count(p.payment_id),
	case
		when count(p.payment_id) > 7300 then 'Да'
		else 'Не'
	end
from payment p 
group by p.staff_id 

