-- SQL-запросы для магазина детских товаров

-- _____________________________

-- ЗАПРОСЫ НА ЧТЕНИЕ

-- _____________________________

-- 1. Список всех заказов за последние 7 дней с именем покупателя и описанием товара
SELECT 
    o.id as order_id,
    o.order_date,
    c.first_name || ' ' || c.last_name as customer_name,
    p.description as product_name,
    o.quantity,
    os.status_name,
    (p.price * o.quantity) as total_price
FROM orders o
JOIN customer c ON o.customer_id = c.id
JOIN product p ON o.product_id = p.id
JOIN order_status os ON o.status_id = os.id
WHERE o.order_date >= CURRENT_DATE - INTERVAL '7 days'
ORDER BY o.order_date DESC;

-- 2. Топ-3 самых популярных товаров (по количеству заказов)
SELECT 
    p.description as product_name,
    p.category,
    COUNT(o.id) as order_count,
    SUM(o.quantity) as total_ordered
FROM product p
JOIN orders o ON p.id = o.product_id
GROUP BY p.id, p.description, p.category
ORDER BY order_count DESC, total_ordered DESC
LIMIT 3;

-- 3. Товары с низким остатком (менее 10 шт)
SELECT 
    p.description as product_name,
    p.category as category,
    p.quantity as current_stock,
    p.price as price,
    CASE 
        WHEN p.quantity < 5 THEN 'CRITICALLY LOW'
        WHEN p.quantity < 10 THEN 'LOW' 
        ELSE 'NORMAL'
    END as stock_level
FROM product p
WHERE p.quantity < 10
ORDER BY p.quantity ASC;

-- 4. Статистика заказов за текущий год
SELECT 
    EXTRACT(MONTH FROM o.order_date) as month_number,
    TO_CHAR(o.order_date, 'Month') as month_name,
    COUNT(o.id) as order_count,
    SUM(o.quantity) as total_items,
    SUM(p.price * o.quantity) as total_revenue
FROM orders o
JOIN product p ON o.product_id = p.id
WHERE EXTRACT(YEAR FROM o.order_date) = EXTRACT(YEAR FROM CURRENT_DATE)
GROUP BY month_number, month_name
ORDER BY month_number;

-- 5. Заказы по статусам с общей суммой
SELECT 
    os.status_name as status,
    COUNT(o.id) as order_count,
    SUM(o.quantity) as total_items,
    SUM(p.price * o.quantity) as total_amount
FROM orders o
JOIN order_status os ON o.status_id = os.id
JOIN product p ON o.product_id = p.id
GROUP BY os.status_name
ORDER BY order_count DESC;

-- _____________________________

-- ЗАПРОСЫ НА ИЗМЕНЕНИЕ (UPDATE)

-- _____________________________

-- 6. Обновление количества товара на складе для недавно отправленных заказов
UPDATE product 
SET quantity = quantity - (
    SELECT COALESCE(SUM(o.quantity), 0)
    FROM orders o 
    WHERE o.product_id = product.id 
    AND o.status_id IN (SELECT id FROM order_status WHERE status_name IN ('Отправлен', 'В пути'))
    AND o.order_date >= CURRENT_DATE - INTERVAL '3 days'
)
WHERE id IN (
    SELECT DISTINCT product_id 
    FROM orders 
    WHERE status_id IN (SELECT id FROM order_status WHERE status_name IN ('Отправлен', 'В пути'))
    AND order_date >= CURRENT_DATE - INTERVAL '3 days'
);

-- 7. Обновление статуса заказов, которые "В пути" дольше 5 дней
UPDATE orders 
SET status_id = (SELECT id FROM order_status WHERE status_name = 'Задерживается')
WHERE status_id = (SELECT id FROM order_status WHERE status_name = 'В пути')
AND order_date <= CURRENT_DATE - INTERVAL '5 days';

-- 8. Скидка 10% на товары, которые на складе больше 3 месяцев
UPDATE product 
SET price = price * 0.9
WHERE quantity > 20
AND id NOT IN (
    SELECT DISTINCT product_id 
    FROM orders 
    WHERE order_date >= CURRENT_DATE - INTERVAL '3 months'
);

-- _____________________________

-- ЗАПРОСЫ НА УДАЛЕНИЕ (DELETE)

-- _____________________________


-- 9. Удаление клиентов без заказов за последние 6 месяцев
DELETE FROM customer 
WHERE id NOT IN (
    SELECT DISTINCT customer_id 
    FROM orders 
    WHERE order_date >= CURRENT_DATE - INTERVAL '6 months'
);

-- 10. Удаление отмененных заказов старше 1 года
DELETE FROM orders 
WHERE status_id = (SELECT id FROM order_status WHERE status_name = 'Отменен')
AND order_date < CURRENT_DATE - INTERVAL '1 year';


