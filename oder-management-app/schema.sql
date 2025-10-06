-- product — id, описание, стоимость, количество, категория
CREATE TABLE IF NOT EXISTS product (
    id SERIAL PRIMARY KEY,
    description TEXT NOT NULL,
    price DECIMAL(10,2) NOT NULL CHECK (price >= 0),
    quantity INTEGER NOT NULL CHECK (quantity >= 0),
    category VARCHAR(100) NOT NULL
);

-- Комментарии к таблицам и ключевым полям
COMMENT ON TABLE product IS 'Таблица товаров';

COMMENT ON COLUMN product.id IS 'ID товара';
COMMENT ON COLUMN product.description IS 'Описание товара';
COMMENT ON COLUMN product.price IS 'Стоимость товара';
COMMENT ON COLUMN product.quantity IS 'Количество товара в наличии';
COMMENT ON COLUMN product.category IS 'Категория товара';

-- customer — id, имя, фамилия, телефон, email
CREATE TABLE IF NOT EXISTS customer (
    id SERIAL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    phone VARCHAR(20),
    email VARCHAR(100) UNIQUE
);

-- Комментарии к таблицам и ключевым полям
COMMENT ON TABLE customer IS 'Таблица клиентов';

COMMENT ON COLUMN customer.id IS 'ID клиента';
COMMENT ON COLUMN customer.first_name IS 'Имя клиента';
COMMENT ON COLUMN customer.last_name IS 'Фамилия клиента';
COMMENT ON COLUMN customer.phone IS 'Телефон клиента';
COMMENT ON COLUMN customer.email IS 'Email клиента';

-- order — id, product_id (FK), customer_id (FK), дата заказа, количество, статус
CREATE TABLE IF NOT EXISTS orders (
    id SERIAL PRIMARY KEY,
    product_id INTEGER NOT NULL,
    customer_id INTEGER NOT NULL,
    order_date DATE NOT NULL DEFAULT CURRENT_DATE,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    status_id INTEGER NOT NULL,
    FOREIGN KEY (product_id) REFERENCES product(id),
    FOREIGN KEY (customer_id) REFERENCES customer(id),
    FOREIGN KEY (status_id) REFERENCES order_status(id)
);

-- Комментарии к таблицам и ключевым полям
COMMENT ON TABLE orders IS 'Таблица заказов';

COMMENT ON COLUMN orders.id IS 'ID заказа';
COMMENT ON COLUMN orders.product_id IS 'Ссылка на товар (внешний ключ)';
COMMENT ON COLUMN orders.customer_id IS 'Ссылка на клиента (внешний ключ)';
COMMENT ON COLUMN orders.order_date IS 'Дата заказа';
COMMENT ON COLUMN orders.quantity IS 'Количество товара в заказе';
COMMENT ON COLUMN orders.status_id IS 'Статус заказа';

-- order_status — справочник статусов заказов (id, имя статуса)
CREATE TABLE IF NOT EXISTS order_status (
    id SERIAL PRIMARY KEY,
    status_name VARCHAR(50) NOT NULL UNIQUE
);

-- Комментарии к таблицам и ключевым полям
COMMENT ON TABLE order_status IS 'Справочник статусов заказов';

COMMENT ON COLUMN order_status.id IS 'ID статуса';
COMMENT ON COLUMN order_status.status_name IS 'Наименование статуса';


-- Индексы по внешним ключам и дате заказа
CREATE INDEX IF NOT EXISTS idx_orders_product_id ON orders(product_id);
CREATE INDEX IF NOT EXISTS idx_orders_customer_id ON orders(customer_id);
CREATE INDEX IF NOT EXISTS idx_orders_order_date ON orders(order_date);


-- Заполнение тестовыми данными — минимум 10 строк в каждой таблице.


-- Товары для детского магазина
INSERT INTO product (description, price, quantity, category) VALUES 
('Конструктор LEGO Classic', 2500.00, 25, 'Конструкторы'),
('Детский велосипед 12"', 8500.00, 8, 'Транспорт'),
('Кукла Barbie', 1800.00, 30, 'Куклы'),
('Набор для рисования 100 предметов', 1200.00, 40, 'Творчество'),
('Детский рюкзак с героями мультфильмов', 1500.00, 35, 'Аксессуары'),
('Интерактивная игрушка "Умный щенок"', 3200.00, 12, 'Интерактивные игрушки'),
('Набор детской посуды "Hello Kitty"', 800.00, 50, 'Посуда'),
('Детский столик и стульчик', 4500.00, 6, 'Мебель'),
('Настольная игра "Дженга"', 900.00, 28, 'Настольные игры'),
('Толокар-машинка', 5200.00, 5, 'Транспорт'),
('Пазл 60 элементов "Тачки"', 450.00, 60, 'Настольные игры'),
('Детский костюм супергероя', 2100.00, 15, 'Одежда'),
('Музыкальный коврик для танцев', 3800.00, 7, 'Интерактивные игрушки'),
('Набор для песочницы', 650.00, 45, 'Творчество'),
('Детские наручные часы с GPS', 4200.00, 10, 'Аксессуары')
ON CONFLICT DO NOTHING;


-- Клиенты (родители)
INSERT INTO customer (first_name, last_name, phone, email) VALUES 
('Анна', 'Иванова', '+79161234567', 'anna.ivanova@mail.ru'),
('Сергей', 'Петров', '+79167654321', 'sergey.petrov@mail.ru'),
('Ольга', 'Сидорова', '+79162345678', 'olga.sidorova@mail.ru'),
('Дмитрий', 'Козлов', '+79163456789', 'dmitry.kozlov@mail.ru'),
('Екатерина', 'Николаева', '+79164567890', 'ekaterina.nikolaeva@mail.ru'),
('Алексей', 'Васильев', '+79165678901', 'alexey.vasiliev@mail.ru'),
('Мария', 'Смирнова', '+79166789012', 'maria.smirnova@mail.ru'),
('Иван', 'Попов', '+79167890123', 'ivan.popov@mail.ru'),
('Юлия', 'Морозова', '+79168901234', 'yulia.morozova@mail.ru'),
('Андрей', 'Волков', '+79169012345', 'andrey.volkov@mail.ru'),
('Татьяна', 'Зайцева', '+79160123456', 'tatyana.zaytseva@mail.ru'),
('Павел', 'Семенов', '+79161234567', 'pavel.semenov@mail.ru')
ON CONFLICT DO NOTHING;


-- Заказы с датами с 1 сентября по 6 октября 2025 года
INSERT INTO orders (product_id, customer_id, order_date, quantity, status_id) VALUES 
(1, 1, '2025-09-01', 1, 1),   -- Конструктор LEGO (1 сентября) 
(3, 2, '2025-09-03', 2, 2),   -- Куклы Barbie (3 сентября)
(2, 3, '2025-09-05', 1, 3),   -- Детский велосипед (5 сентября)
(4, 4, '2025-09-08', 1, 4),   -- Набор для рисования (8 сентября)
(5, 5, '2025-09-10', 1, 5),   -- Детский рюкзак (10 сентября)
(6, 6, '2025-09-12', 1, 6),   -- Интерактивная игрушка (12 сентября)
(7, 7, '2025-09-15', 3, 7),   -- Набор детской посуды (15 сентября)
(8, 8, '2025-09-18', 1, 8),   -- Детский столик (18 сентября)
(9, 9, '2025-09-20', 2, 1),   -- Настольная игра (20 сентября)
(10, 10, '2025-09-22', 1, 2), -- Толокар-машинка (22 сентября)
(11, 11, '2025-09-25', 1, 3), -- Пазл (25 сентября)
(12, 12, '2025-09-28', 1, 4), -- Костюм супергероя (28 сентября)
(13, 1, '2025-10-01', 1, 5),  -- Музыкальный коврик (1 октября)
(14, 2, '2025-10-03', 2, 6),  -- Набор для песочницы (3 октября)
(15, 3, '2025-10-06', 1, 7)   -- Детские часы с GPS (6 октября)
ON CONFLICT DO NOTHING;


-- Статусы заказов
INSERT INTO order_status (status_name) VALUES 
('Новый'), ('Подтвержден'), ('В обработке'), ('Отправлен'), ('В пути'), ('Доставлен'), ('Задерживается'), ('Отменен')
ON CONFLICT (status_name) DO NOTHING;
