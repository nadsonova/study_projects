--=============== МОДУЛЬ 6. POSTGRESQL =======================================
--= ПОМНИТЕ, ЧТО НЕОБХОДИМО УСТАНОВИТЬ ВЕРНОЕ СОЕДИНЕНИЕ И ВЫБРАТЬ СХЕМУ PUBLIC===========
SET search_path TO public;

--======== ОСНОВНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Напишите SQL-запрос, который выводит всю информацию о фильмах 
--со специальным атрибутом "Behind the Scenes".


select film_id, title, special_features
from film
where array_position(special_features, 'Behind the Scenes') is not null


--ЗАДАНИЕ №2
--Напишите еще 2 варианта поиска фильмов с атрибутом "Behind the Scenes",
--используя другие функции или операторы языка SQL для поиска значения в массиве.


select film_id, title, special_features
from film
where special_features && array['Behind the Scenes']


select film_id, title, special_features
from film
where 'Behind the Scenes' = any(special_features)


--ЗАДАНИЕ №3
--Для каждого покупателя посчитайте сколько он брал в аренду фильмов 
--со специальным атрибутом "Behind the Scenes.

--Обязательное условие для выполнения задания: используйте запрос из задания 1, 
--помещенный в CTE. CTE необходимо использовать для решения задания.


with cte_search as (
	select film_id, title, special_features
	from film
	where array_position(special_features, 'Behind the Scenes') is not null
)
select c.customer_id, count(cte_search.film_id)
from customer c 
join payment p on c.customer_id = p.customer_id 
join rental r on p.rental_id = r.rental_id 
join inventory i on r.inventory_id = i.inventory_id 
join cte_search on i.film_id = cte_search.film_id
group by c.customer_id 
order by c.customer_id 


--ЗАДАНИЕ №4
--Для каждого покупателя посчитайте сколько он брал в аренду фильмов
-- со специальным атрибутом "Behind the Scenes".

--Обязательное условие для выполнения задания: используйте запрос из задания 1,
--помещенный в подзапрос, который необходимо использовать для решения задания.


select c.customer_id, count(t_films.film_id)
from customer c 
join payment p on c.customer_id = p.customer_id 
join rental r on p.rental_id = r.rental_id 
join inventory i on r.inventory_id = i.inventory_id 
join (
	select film_id, title, special_features
	from film
	where array_position(special_features, 'Behind the Scenes') is not null
	) t_films on i.film_id = t_films.film_id
group by c.customer_id 
order by c.customer_id 


--ЗАДАНИЕ №5
--Создайте материализованное представление с запросом из предыдущего задания
--и напишите запрос для обновления материализованного представления


create materialized view films_count as (
	select c.customer_id, count(t_films.film_id)
	from customer c 
	join payment p on c.customer_id = p.customer_id 
	join rental r on p.rental_id = r.rental_id 
	join inventory i on r.inventory_id = i.inventory_id 
	join (
		select film_id, title, special_features
		from film
		where array_position(special_features, 'Behind the Scenes') is not null
		) t_films on i.film_id = t_films.film_id
	group by c.customer_id 
	order by c.customer_id)

refresh materialized view films_count

select *
from films_count


--ЗАДАНИЕ №6
--С помощью explain analyze проведите анализ стоимости выполнения запросов из предыдущих заданий и ответьте на вопросы:
--1. с каким оператором или функцией языка SQL, используемыми при выполнении домашнего задания: 
--поиск значения в массиве затрачивает меньше ресурсов системы;


explain analyze -- стоимость - 67.5, время - 0.58
select film_id, title, special_features
from film
where array_position(special_features, 'Behind the Scenes') is not null


explain analyze -- стоимость - 67.5, время - 0.56
select film_id, title, special_features
from film
where special_features && array['Behind the Scenes']


explain analyze -- стоимость - 77.5, время - 0.52
select film_id, title, special_features
from film
where 'Behind the Scenes' = any(special_features)


-- 1й и 2й запросы затрачивают примерно одинаковое количество ресурсов. У 3го запроса стоимость больше.  
-- Время выполнения во всех случаях меняется примерно от 0.3 до 0.9 мс.

-- Вывод: использование array_position и && (1й и 2й запросы, соотвественно) затрачивает меньше ресурсов системы для поиска значения в массиве 


--2. какой вариант вычислений затрачивает меньше ресурсов системы: 
--с использованием CTE или с использованием подзапроса.


--С использованием CTE: 

explain analyze -- стоимость - 1304.77, время - 23.0
with cte_search as (
	select film_id, title, special_features
	from film
	where array_position(special_features, 'Behind the Scenes') is not null
)
select c.customer_id, count(cte_search.film_id)
from customer c 
join payment p on c.customer_id = p.customer_id 
join rental r on p.rental_id = r.rental_id 
join inventory i on r.inventory_id = i.inventory_id 
join cte_search on i.film_id = cte_search.film_id
group by c.customer_id 
order by c.customer_id 


--С использованием подзапроса: 

explain analyze -- стоимость - 1304.77, время - 23.9
select c.customer_id, count(t_films.film_id)
from customer c 
join payment p on c.customer_id = p.customer_id 
join rental r on p.rental_id = r.rental_id 
join inventory i on r.inventory_id = i.inventory_id 
join (
	select film_id, title, special_features
	from film
	where array_position(special_features, 'Behind the Scenes') is not null
	) t_films on i.film_id = t_films.film_id
group by c.customer_id 
order by c.customer_id 


-- Вывод: примерно одинаковое количество ресурсов. Время выполнения в обоих случаях меняется примерно от 22 до 40 мс.


--======== ДОПОЛНИТЕЛЬНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Выполняйте это задание в форме ответа на сайте Нетологии 


--Узкие места в explain analyze

->  Hash Full Join  (cost=77.50..160.39 rows=4581 width=63) (actual time=0.529..2.580 rows=4623 loops=1)
full outer join film f on f.film_id = i.film_id - включит в себя все значения из film и из inventory, включая несовпадающие строки.
А потом еще и из rental и customer.

->  ProjectSet  (cost=77.50..423.80 rows=45810 width=712) (actual time=0.747..6.234 rows=9768 loops=1)
Использование unnest(f.special_features) значительно увеличивает количество строк в таблице.

->  Subquery Scan on inv  (cost=77.50..996.42 rows=5 width=4) (actual time=0.750..7.941 rows=2494 loops=1)
Сканирование подзапроса при сравнении каждой строки таблицы с '%Behind the Scenes%' имеет высокую стоимость.
Кроме того, ren.sfs like '%Behind the Scenes%' отработает и для других значений, например, для 'Behind the Scenes1' или '1Behind the Scenes'.

->  Nested Loop Left Join  (cost=81.82..1088.66 rows=5 width=6) (actual time=0.560..22.929 rows=8632 loops=1)
full outer join rental и inventory с последюущим where имеет высокие стоимость и время выполнения.

->  Nested Loop Left Join  (cost=82.09..1090.13 rows=5 width=21) (actual time=0.571..35.202 rows=8632 loops=1)
Точно так же, как и следующий full outer join с customer и последюущим where.

->  Sort  (cost=1090.19..1090.20 rows=5 width=21) (actual time=38.273..39.493 rows=8632 loops=1)
Высокие стоимость и время выполнения сортировки при выполнении оконной функции по cu.customer_id из-за того, что в таблице огромное количество строк.

->  WindowAgg  (cost=1090.19..1090.30 rows=5 width=44) (actual time=38.314..44.085 rows=8632 loops=1)
Высокие стоимость и время выполнения при вычислении количества rental.inventory_id для каждого покупателя.

->  Sort  (cost=1090.36..1090.38 rows=5 width=44) (actual time=48.116..48.734 rows=8632 loops=1)
Высокие стоимость и время выполнения сортировки по количества rental.inventory_id для каждого покупателя.

-> Unique  (cost=1090.36..1090.40 rows=5 width=44) (actual time=48.118..49.726 rows=600 loops=1)
select distinct - по сути коррекция некорректно выполненного запроса (удаление задублированных строк). 
Вместо этого логичнее использовать group by или перенести вычесление count в подзапрос.

--Оптимизированный вариант с подзапросом:

explain analyze -- cost = 784.02, time = 18.2
with cte_1 as (
	select *
	from film f
	where array_position(f.special_features, 'Behind the Scenes') is not null
)
select concat(c.first_name, ' ', c.last_name), count(r.inventory_id)
from cte_1
join inventory i on cte_1.film_id = i.film_id 
join rental r on r.inventory_id = i.inventory_id 
join customer c on r.customer_id = c.customer_id 
group by c.customer_id 
order by count desc

--Построчное описание explain analyze на русском языке оптимизированного запроса


  Sort  (cost=782.52..784.02 rows=599 width=44) (actual time=20.989..21.043 rows=599 loops=1)
  Sort Key: (count(r.inventory_id)) DESC
  Sort Method: quicksort  Memory: 67kB
  ->  HashAggregate  (cost=747.40..754.89 rows=599 width=44) (actual time=20.597..20.855 rows=599 loops=1)
        Group Key: c.customer_id
        Batches: 1  Memory Usage: 105kB
        ->  Hash Join  (cost=230.49..667.58 rows=15963 width=21) (actual time=2.779..17.937 rows=8608 loops=1)
              Hash Cond: (r.customer_id = c.customer_id)
              ->  Hash Join  (cost=208.01..602.90 rows=15963 width=6) (actual time=2.490..14.859 rows=8608 loops=1)
                    Hash Cond: (i.film_id = f.film_id)
                    ->  Hash Join  (cost=128.07..480.67 rows=16044 width=8) (actual time=1.535..10.349 rows=16044 loops=1)
                          Hash Cond: (r.inventory_id = i.inventory_id)
                          ->  Seq Scan on rental r  (cost=0.00..310.44 rows=16044 width=6) (actual time=0.017..2.088 rows=16044 loops=1)
                          ->  Hash  (cost=70.81..70.81 rows=4581 width=6) (actual time=1.499..1.499 rows=4581 loops=1)
                                Buckets: 8192  Batches: 1  Memory Usage: 243kB
                                ->  Seq Scan on inventory i  (cost=0.00..70.81 rows=4581 width=6) (actual time=0.010..0.771 rows=4581 loops=1)
                    ->  Hash  (cost=67.50..67.50 rows=995 width=4) (actual time=0.941..0.942 rows=538 loops=1)
                          Buckets: 1024  Batches: 1  Memory Usage: 27kB
                          ->  Seq Scan on film f  (cost=0.00..67.50 rows=995 width=4) (actual time=0.018..0.846 rows=538 loops=1)
                                Filter: (array_position(special_features, 'Behind the Scenes'::text) IS NOT NULL)
                                Rows Removed by Filter: 462
              ->  Hash  (cost=14.99..14.99 rows=599 width=17) (actual time=0.278..0.279 rows=599 loops=1)
                    Buckets: 1024  Batches: 1  Memory Usage: 39kB
                    ->  Seq Scan on customer c  (cost=0.00..14.99 rows=599 width=17) (actual time=0.018..0.151 rows=599 loops=1)
Planning Time: 0.799 ms
Execution Time: 21.192 ms


1. Последовательное сканирование таблицы inventory
2. Последовательное сканирование таблицы film + фильтр на наличие значения 'Behind the Scenes' в столбце special_features
3. Создание хеш-таблицы для inventory
4. Последовательное сканирование таблицы rental
5. Создание хеш-таблицы для film
6. Последовательное сканирование таблицы customer
7. Обьединение строк из хеш-таблиц rental и inventory по условию r.inventory_id = i.inventory_id
8. Создание хеш-таблицы для customer
9. Обьединение film и ранее обьедененных rental и inventory по условию i.film_id = f.film_id
10. Обьединение с customer по условию r.customer_id = c.customer_id
11. Группировка по ключу customer_id, возвращается по одной строке для каждого значения ключа + расчет агрегатной функции count
12. Сортировка по расчитанным значениям count


--ЗАДАНИЕ №2
--Используя оконную функцию выведите для каждого сотрудника
--сведения о самой первой продаже этого сотрудника.


select t1.staff_id,
	f.film_id,
	f.title,
	t1.amount,
	t1.payment_date,
	c.last_name,
	c.first_name 
from (
	select p.staff_id, 
		p.payment_date, 
		row_number() over (partition by p.staff_id order by p.payment_date),
		p.rental_id,
		p.amount,
		p.customer_id
	from payment p) t1
join rental r on t1.rental_id = r.rental_id and t1.row_number = 1
join inventory i on i.inventory_id = r.inventory_id 
join film f on i.film_id = f.film_id 
join customer c on c.customer_id = t1.customer_id 


--ЗАДАНИЕ №3
--Для каждого магазина определите и выведите одним SQL-запросом следующие аналитические показатели:
-- 1. день, в который арендовали больше всего фильмов (день в формате год-месяц-день)
-- 2. количество фильмов взятых в аренду в этот день
-- 3. день, в который продали фильмов на наименьшую сумму (день в формате год-месяц-день)
-- 4. сумму продажи в этот день


with cte_1 as (
	select s.store_id,
		r.rental_date::date,
		count(r.inventory_id) over (partition by s.store_id, r.rental_date::date),
		sum(p.amount) over (partition by s.store_id, p.payment_date::date)
	from store s 
	join inventory i on s.store_id = i.store_id  
	join rental r on i.inventory_id = r.inventory_id 
	join payment p on p.rental_id = r.rental_id),
cte_2 as (
	select *,
		first_value(rental_date::date) over (partition by store_id order by count desc) max_films,
		first_value(rental_date::date) over (partition by store_id order by sum) min_amount,
		max(count) over (partition by store_id) max_value,
		min(sum) over (partition by store_id) min_value,
		row_number() over (partition by store_id)
	from cte_1
)
select store_id, max_films, max_value, min_amount, min_value
from cte_2
where row_number = 1



