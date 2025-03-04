--=============== МОДУЛЬ 5. РАБОТА С POSTGRESQL =======================================
--= ПОМНИТЕ, ЧТО НЕОБХОДИМО УСТАНОВИТЬ ВЕРНОЕ СОЕДИНЕНИЕ И ВЫБРАТЬ СХЕМУ PUBLIC===========
SET search_path TO public;

--======== ОСНОВНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--Сделайте запрос к таблице payment и с помощью оконных функций добавьте вычисляемые колонки согласно условиям:
--Пронумеруйте все платежи от 1 до N по дате платежа
--Пронумеруйте платежи для каждого покупателя, сортировка платежей должна быть по дате платежа
--Посчитайте нарастающим итогом сумму всех платежей для каждого покупателя, сортировка должна 
--быть сперва по дате платежа, а затем по размеру платежа от наименьшей к большей
--Пронумеруйте платежи для каждого покупателя по размеру платежа от наибольшего к
--меньшему так, чтобы платежи с одинаковым значением имели одинаковое значение номера.
--Можно составить на каждый пункт отдельный SQL-запрос, а можно объединить все колонки в одном запросе.


select customer_id,
	payment_id,
	payment_date::date, 
	amount,
	row_number() over (order by payment_date::date) column_1,
	row_number() over (partition by customer_id order by payment_date::date) column_2,
	sum(amount) over (partition by customer_id order by payment_date::date, amount) column_3,
	dense_rank() over (partition by customer_id order by amount desc) column_4
from payment 


--ЗАДАНИЕ №2
--С помощью оконной функции выведите для каждого покупателя стоимость платежа и стоимость 
--платежа из предыдущей строки со значением по умолчанию 0.0 с сортировкой по дате платежа.


select customer_id, payment_id, payment_date, amount,
	lag(amount, 1, 0.) over (partition by customer_id order by payment_date)
from payment p 


--ЗАДАНИЕ №3
--С помощью оконной функции определите, на сколько каждый следующий платеж покупателя больше или меньше текущего.


select customer_id, payment_id, payment_date, amount,
	lead(amount, 1, 0.) over (partition by customer_id order by payment_date) as next_amount,
	lead(amount, 1, 0.) over (partition by customer_id order by payment_date) - amount as diff_amount
from payment p 


--ЗАДАНИЕ №4
--С помощью оконной функции для каждого покупателя выведите данные о его последней оплате аренды.


select customer_id, payment_id, payment_date, amount
from (
	select *,
	first_value(payment_id) over (partition by customer_id order by payment_date desc)
	from payment) t
where payment_id = first_value	


--======== ДОПОЛНИТЕЛЬНАЯ ЧАСТЬ ==============

--ЗАДАНИЕ №1
--С помощью оконной функции выведите для каждого сотрудника сумму продаж за август 2005 года 
--с нарастающим итогом по каждому сотруднику и по каждой дате продажи (без учёта времени) 
--с сортировкой по дате.


select staff_id, payment_date::date, sum_amount, sum
from (
	select *,
		row_number() over (partition by staff_id, payment_date::date),
		sum(amount) over (partition by staff_id, payment_date::date) sum_amount,
		sum(amount) over (partition by staff_id order by payment_date::date)
	from (
		select staff_id, payment_date::date, amount
		from payment
		where date_trunc('month', payment_date) = '2005-08-01') t1) t2
where row_number = 1


--ЗАДАНИЕ №2
--20 августа 2005 года в магазинах проходила акция: покупатель каждого сотого платежа получал
--дополнительную скидку на следующую аренду. С помощью оконной функции выведите всех покупателей,
--которые в день проведения акции получили скидку


select payment_id, payment_date, customer_id, amount, row_number
from (
	select *, row_number() over (order by payment_date)
	from (
		select *
		from payment 
		where date_trunc('day', payment_date) = '2005-08-20') t1) t2
where row_number % 100 = 0


--ЗАДАНИЕ №3
--Для каждой страны определите и выведите одним SQL-запросом покупателей, которые попадают под условия:
-- 1. покупатель, арендовавший наибольшее количество фильмов
-- 2. покупатель, арендовавший фильмов на самую большую сумму
-- 3. покупатель, который последним арендовал фильм


with cte_country as (
	select country.country, country.country_id, customer.customer_id, 
		concat(customer.first_name, ' ', customer.last_name) customer_name,
		count(payment.payment_id) payment_count, 
		sum(payment.amount) sum_amount, 
		max(payment.payment_date) max_pdate
	from country
	join city on country.country_id = city.country_id  
	join address on city.city_id = address.city_id 
	join customer on customer.address_id = address.address_id
	join payment on customer.customer_id = payment.customer_id
	group by country.country_id, customer.customer_id
	order by country.country),
cte_top as (
	select *,
		first_value(customer_name) over (partition by country order by payment_count desc) best_by_number_of_films,
		first_value(customer_name) over (partition by country order by sum_amount desc) best_by_sum_amount,
		first_value(customer_name) over (partition by country order by max_pdate desc) last_customer,
		row_number() over (partition by country)
	from cte_country)
select country, best_by_number_of_films, best_by_sum_amount, last_customer
from cte_top
where row_number = 1


with cte_country as (
	select country.country, country.country_id, customer.customer_id, 
		concat(customer.first_name, ' ', customer.last_name) customer_name,
		count(payment.payment_id) payment_count, 
		sum(payment.amount) sum_amount, 
		max(payment.payment_date) max_pdate
	from country
	join city on country.country_id = city.country_id  
	join address on city.city_id = address.city_id 
	join customer on customer.address_id = address.address_id
	join payment on customer.customer_id = payment.customer_id
	group by country.country_id, customer.customer_id
	order by country.country),
cte_top as (
	select *,
		first_value(customer_name) over (partition by country order by payment_count desc) c_1,
		first_value(customer_name) over (partition by country order by sum_amount desc) c_2,
		first_value(customer_name) over (partition by country order by max_pdate desc) c_3,
		row_number() over (partition by country, customer_id)
	from cte_country)
select country, c_1, c_2, c_3, max_pdate, customer_name
from cte_top
order by country, max_pdate

