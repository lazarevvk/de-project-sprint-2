--------------------------------------------------------------------------------------------------------
--TASK4--

-- Создаем таблицу shipping_info
CREATE TABLE shipping_info (
    shipping_id BIGINT PRIMARY KEY, -- Уникальный идентификатор доставки (первичный ключ)
    vendor_id INT, -- Идентификатор вендора
    payment_amount DECIMAL(14, 2), -- Сумма платежа
    shipping_plan_datetime TIMESTAMP, -- Планируемая дата доставки
    shipping_transfer_id BIGINT,
    shipping_agreement_id BIGINT,
    shipping_country_rate_id BIGINT
);

-- Добавляем внешние ключи для связи с справочниками
ALTER TABLE shipping_info
ADD CONSTRAINT fk_shipping_country_rate_id FOREIGN KEY (shipping_country_rate_id) REFERENCES shipping_country_rates(id);

ALTER TABLE shipping_info
ADD CONSTRAINT fk_shipping_agreement_id FOREIGN KEY (shipping_agreement_id) REFERENCES shipping_agreement(agreement_id);

ALTER TABLE shipping_info
ADD CONSTRAINT fk_shipping_transfer_id FOREIGN KEY (shipping_transfer_id) REFERENCES shipping_transfer(id);

-- Вставляем данные в таблицу shipping_info из таблицы shipping и добавляем константную информацию
INSERT INTO shipping_info (
    shipping_id, vendor_id, payment_amount, shipping_plan_datetime, shipping_transfer_id,  shipping_country_rate_id, shipping_agreement_id
)
select DISTINCT
	sp.shippingid, sp.vendorid, sp.payment_amount, sp.shipping_plan_datetime, st.id as shipping_transfer_id , scr.id as shipping_country_rate_id , spa.agreement_id 
from 
	shipping sp
join 
	shipping_agreement spa on cast((regexp_split_to_array(sp.vendor_agreement_description, E':'))[1] as BIGINT) = spa.agreement_id
join
	shipping_country_rates scr on sp.shipping_country_base_rate = scr.shipping_country_base_rate 
join
	shipping_transfer st on cast((regexp_split_to_array(sp.shipping_transfer_description, E':'))[1] as TEXT) = st.transfer_type
		and
			cast((regexp_split_to_array(sp.shipping_transfer_description, E':'))[2] as TEXT) = st.transfer_model;

-- Проверка повторяющихся строк	
SELECT COUNT(*) AS count_of_duplicate_rows
FROM (
    SELECT COUNT(*) 
    FROM shipping_info
    GROUP BY vendor_id, payment_amount, shipping_plan_datetime, shipping_transfer_id,  shipping_country_rate_id, shipping_agreement_id
    HAVING COUNT(*) > 1
) AS subquery;

--------------------------------------------------------------------------------------------------------
--TASK5--

drop table shipping_status;
CREATE TABLE shipping_status (
    shipping_id BIGINT PRIMARY KEY, -- Уникальный идентификатор доставки (первичный ключ)
    status VARCHAR(255), -- Статус доставки
    state VARCHAR(255), -- Состояние доставки
    shipping_start_fact_datetime TIMESTAMP, -- Фактическое время начала доставки
    shipping_end_fact_datetime TIMESTAMP -- Фактическое время окончания доставки
);

WITH Recieved AS (
    SELECT 
        shippingid,
        state_datetime,
        state,
        status
    FROM 
        shipping
    where 
        shipping.state = 'recieved' --and shipping.status = 'finished'
)

--INSERT INTO shipping_status (shipping_id, status, state, shipping_start_fact_datetime, shipping_end_fact_datetime)
select recieved.shippingid, recieved.state, recieved.status, s.state_datetime as min, recieved.state_datetime as max from recieved
join shipping s on s.shippingid = recieved.shippingid
where s.state = 'booked';



