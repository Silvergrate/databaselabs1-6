# Лабораторна робота №5  
## Нормалізація бази даних

**Виконав:** Гасюк Д.О.  
**Група:** ІО-41  
**Тема проєкту:** База даних Telegram-бота для продажу цифрових товарів

---

## Мета роботи

Мета роботи — проаналізувати існуючу схему бази даних Telegram-бота, знайти надлишковість і можливі аномалії, а потім привести проблемні частини схеми до третьої нормальної форми.

У попередніх лабораторних роботах була створена база даних для Telegram-бота, який зберігає користувачів, цифрові товари, замовлення, платежі, промокоди, публікації, реферальні зв’язки та виконані команди. У цій роботі було перевірено структуру таблиць і виконано нормалізацію окремих полів, які містили повторювані або неатомарні значення.

---

## Початкова схема та знайдені проблеми

Під час аналізу початкової схеми були знайдені такі місця, які потребують нормалізації:

1. У таблиці `publication` поле `tag_list` містило список тегів в одному стовпці.
2. У таблиці `product` поле `product_type` зберігалося як текст і повторювалося в багатьох рядках.
3. У таблиці `bot_order` поле `status` зберігалося як текстове значення.
4. У таблиці `payment` поля `method` і `status` також зберігалися як повторювані текстові значення.

Для перевірки цих проблем були виконані такі SQL-запити.

```sql
SELECT publication_id, title, tag_list
FROM publication;

SELECT product_type, COUNT(*) AS products_count
FROM product
GROUP BY product_type
ORDER BY products_count DESC;

SELECT status, COUNT(*) AS orders_count
FROM bot_order
GROUP BY status
ORDER BY orders_count DESC;

SELECT method, status, COUNT(*) AS payments_count
FROM payment
GROUP BY method, status
ORDER BY method, status;

Функціональні залежності початкової схеми
Таблиця publication

Початкова структура:

publication(publication_id, author_id, title, content, tag_list, created_at)

Функціональні залежності:

publication_id → author_id, title, content, tag_list, created_at

Проблема полягає в тому, що tag_list не є атомарним атрибутом. В одному полі зберігалося кілька значень, наприклад news,catalog або promo,discount. Це ускладнює пошук, фільтрацію та підтримку тегів.

Таблиця product

Початкова структура:

product(product_id, name, product_type, price, is_active)

Функціональні залежності:

product_id → name, product_type, price, is_active

Поле product_type повторювалося у різних товарах. Наприклад, тип digital_pack міг бути записаний у багатьох рядках. Якщо потрібно змінити назву типу товару, її довелося б змінювати у багатьох записах.

Таблиця bot_order

Початкова структура:

bot_order(order_id, user_id, promo_code_id, status, created_at, total_amount)

Функціональні залежності:

order_id → user_id, promo_code_id, status, created_at, total_amount

Поле status зберігалося текстом. Значення created, paid, completed, cancelled повторювалися в різних замовленнях. Це створює ризик помилок під час введення або зміни статусів.

Таблиця payment

Початкова структура:

payment(payment_id, order_id, amount, method, status, paid_at)

Функціональні залежності:

payment_id → order_id, amount, method, status, paid_at

Поля method і status також містили повторювані текстові значення. Наприклад, методи card, balance, manual, crypto і статуси paid, pending, failed повторювалися у різних платежах.

Перевірка нормальних форм
Перша нормальна форма

Для першої нормальної форми всі значення в полях мають бути атомарними.

Порушення було знайдено в таблиці publication, тому що поле tag_list містило список значень в одному стовпці.

Було:

publication(publication_id, author_id, title, content, tag_list, created_at)

Стало:

publication(publication_id, author_id, title, content, created_at)
tag(tag_id, name)
publication_tag(publication_id, tag_id)

Після цього кожен тег зберігається окремим записом у таблиці tag, а зв’язок між публікаціями і тегами зберігається в таблиці publication_tag.

Друга нормальна форма

Друга нормальна форма вимагає, щоб таблиця була в 1НФ і не мала часткових залежностей від частини складеного ключа.

У більшості основних таблиць використовуються прості первинні ключі: product_id, order_id, payment_id, publication_id. Тому часткових залежностей у цих таблицях немає.

Проміжна таблиця publication_tag має складений ключ:

(publication_id, tag_id)

У цій таблиці немає додаткових неключових атрибутів, тому часткових залежностей також немає.

Третя нормальна форма

Третя нормальна форма вимагає, щоб неключові атрибути залежали тільки від первинного ключа і не залежали від інших неключових атрибутів.

Для зменшення надлишковості повторювані довідкові значення були винесені в окремі таблиці:

product_type
order_status
payment_method
payment_status
tag

Після цього в основних таблицях зберігаються не текстові повторювані значення, а зовнішні ключі:

product.product_type_id → product_type.product_type_id
bot_order.status_id → order_status.status_id
payment.method_id → payment_method.method_id
payment.status_id → payment_status.status_id
publication_tag.tag_id → tag.tag_id
Перероблений дизайн таблиць
Нормалізація product

Було:

product(product_id, name, product_type, price, is_active)

Стало:

product(product_id, name, product_type_id, price, is_active)
product_type(product_type_id, name)

Основні зміни:

CREATE TABLE IF NOT EXISTS product_type (
    product_type_id INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE
);

INSERT INTO product_type (name)
SELECT DISTINCT product_type
FROM product
WHERE product_type IS NOT NULL
ON CONFLICT (name) DO NOTHING;

ALTER TABLE product
ADD COLUMN IF NOT EXISTS product_type_id INTEGER;

UPDATE product p
SET product_type_id = pt.product_type_id
FROM product_type pt
WHERE p.product_type = pt.name;

ALTER TABLE product
ALTER COLUMN product_type_id SET NOT NULL;

ALTER TABLE product
ADD CONSTRAINT fk_product_product_type
FOREIGN KEY (product_type_id)
REFERENCES product_type(product_type_id);

ALTER TABLE product
DROP COLUMN product_type;
Нормалізація bot_order

Було:

bot_order(order_id, user_id, promo_code_id, status, created_at, total_amount)

Стало:

bot_order(order_id, user_id, promo_code_id, status_id, created_at, total_amount)
order_status(status_id, name)

Основні зміни:

CREATE TABLE IF NOT EXISTS order_status (
    status_id INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    name VARCHAR(20) NOT NULL UNIQUE
);

INSERT INTO order_status (name)
SELECT DISTINCT status
FROM bot_order
WHERE status IS NOT NULL
ON CONFLICT (name) DO NOTHING;

ALTER TABLE bot_order
ADD COLUMN IF NOT EXISTS status_id INTEGER;

UPDATE bot_order o
SET status_id = os.status_id
FROM order_status os
WHERE o.status = os.name;

ALTER TABLE bot_order
ALTER COLUMN status_id SET NOT NULL;

ALTER TABLE bot_order
ADD CONSTRAINT fk_bot_order_status
FOREIGN KEY (status_id)
REFERENCES order_status(status_id);

ALTER TABLE bot_order
DROP CONSTRAINT IF EXISTS chk_bot_order_status;

ALTER TABLE bot_order
DROP COLUMN status;
Нормалізація payment

Було:

payment(payment_id, order_id, amount, method, status, paid_at)

Стало:

payment(payment_id, order_id, amount, method_id, status_id, paid_at)
payment_method(method_id, name)
payment_status(status_id, name)

Основні зміни:

CREATE TABLE IF NOT EXISTS payment_method (
    method_id INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    name VARCHAR(30) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS payment_status (
    status_id INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    name VARCHAR(20) NOT NULL UNIQUE
);

INSERT INTO payment_method (name)
SELECT DISTINCT method
FROM payment
WHERE method IS NOT NULL
ON CONFLICT (name) DO NOTHING;

INSERT INTO payment_status (name)
SELECT DISTINCT status
FROM payment
WHERE status IS NOT NULL
ON CONFLICT (name) DO NOTHING;

ALTER TABLE payment
ADD COLUMN IF NOT EXISTS method_id INTEGER;

ALTER TABLE payment
ADD COLUMN IF NOT EXISTS status_id INTEGER;

UPDATE payment p
SET method_id = pm.method_id
FROM payment_method pm
WHERE p.method = pm.name;

UPDATE payment p
SET status_id = ps.status_id
FROM payment_status ps
WHERE p.status = ps.name;

ALTER TABLE payment
ALTER COLUMN method_id SET NOT NULL;

ALTER TABLE payment
ALTER COLUMN status_id SET NOT NULL;

ALTER TABLE payment
ADD CONSTRAINT fk_payment_method
FOREIGN KEY (method_id)
REFERENCES payment_method(method_id);

ALTER TABLE payment
ADD CONSTRAINT fk_payment_status
FOREIGN KEY (status_id)
REFERENCES payment_status(status_id);

ALTER TABLE payment
DROP CONSTRAINT IF EXISTS chk_payment_method;

ALTER TABLE payment
DROP CONSTRAINT IF EXISTS chk_payment_status;

ALTER TABLE payment
DROP COLUMN method;

ALTER TABLE payment
DROP COLUMN status;
Нормалізація publication

Було:

publication(publication_id, author_id, title, content, tag_list, created_at)

Стало:

publication(publication_id, author_id, title, content, created_at)
tag(tag_id, name)
publication_tag(publication_id, tag_id)

Основні зміни:

CREATE TABLE IF NOT EXISTS tag (
    tag_id INTEGER GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS publication_tag (
    publication_id INTEGER NOT NULL,
    tag_id INTEGER NOT NULL,

    CONSTRAINT pk_publication_tag
        PRIMARY KEY (publication_id, tag_id),

    CONSTRAINT fk_publication_tag_publication
        FOREIGN KEY (publication_id)
        REFERENCES publication(publication_id)
        ON DELETE CASCADE,

    CONSTRAINT fk_publication_tag_tag
        FOREIGN KEY (tag_id)
        REFERENCES tag(tag_id)
        ON DELETE CASCADE
);

INSERT INTO tag (name)
SELECT DISTINCT TRIM(tag_value)
FROM publication p
CROSS JOIN LATERAL unnest(string_to_array(p.tag_list, ',')) AS tag_value
WHERE p.tag_list IS NOT NULL
  AND TRIM(tag_value) <> ''
ON CONFLICT (name) DO NOTHING;

INSERT INTO publication_tag (publication_id, tag_id)
SELECT p.publication_id, t.tag_id
FROM publication p
CROSS JOIN LATERAL unnest(string_to_array(p.tag_list, ',')) AS tag_value
JOIN tag t ON t.name = TRIM(tag_value)
WHERE p.tag_list IS NOT NULL
  AND TRIM(tag_value) <> ''
ON CONFLICT DO NOTHING;

ALTER TABLE publication
DROP COLUMN tag_list;
Перевірка після нормалізації

Після зміни структури були виконані перевірочні запити.

Перевірка таблиці product
SELECT 
    p.product_id,
    p.name AS product_name,
    pt.name AS product_type,
    p.price,
    p.is_active
FROM product p
JOIN product_type pt ON p.product_type_id = pt.product_type_id
ORDER BY p.product_id;

Перевірка таблиці bot_order
SELECT 
    o.order_id,
    u.username,
    os.name AS order_status,
    o.total_amount,
    o.created_at
FROM bot_order o
JOIN bot_user u ON o.user_id = u.user_id
JOIN order_status os ON o.status_id = os.status_id
ORDER BY o.order_id;

Перевірка таблиці payment
SELECT 
    p.payment_id,
    p.order_id,
    p.amount,
    pm.name AS payment_method,
    ps.name AS payment_status,
    p.paid_at
FROM payment p
JOIN payment_method pm ON p.method_id = pm.method_id
JOIN payment_status ps ON p.status_id = ps.status_id
ORDER BY p.payment_id;

Перевірка тегів публікацій
SELECT 
    p.publication_id,
    p.title,
    t.name AS tag_name
FROM publication p
JOIN publication_tag pt ON p.publication_id = pt.publication_id
JOIN tag t ON pt.tag_id = t.tag_id
ORDER BY p.publication_id, t.name;

Оновлена ER-діаграма

Після нормалізації була оновлена ER-діаграма. У ній додано нові довідникові таблиці та проміжну таблицю для тегів.

Основні зміни на ER-діаграмі:

product_type 1 — N product
order_status 1 — N bot_order
payment_method 1 — N payment
payment_status 1 — N payment
publication 1 — N publication_tag
tag 1 — N publication_tag

Зв’язок між публікаціями та тегами тепер реалізовано як багато-до-багатьох через таблицю publication_tag.

Підсумкова структура після нормалізації

Після нормалізації база даних містить такі нові таблиці:

product_type(product_type_id, name)
order_status(status_id, name)
payment_method(method_id, name)
payment_status(status_id, name)
tag(tag_id, name)
publication_tag(publication_id, tag_id)

З основних таблиць були прибрані такі поля:

product.product_type
bot_order.status
payment.method
payment.status
publication.tag_list

Замість них використовуються зовнішні ключі:

product.product_type_id
bot_order.status_id
payment.method_id
payment.status_id
publication_tag.publication_id
publication_tag.tag_id
Висновок

У ході лабораторної роботи було проаналізовано початкову схему бази даних Telegram-бота та знайдено кілька місць з надлишковістю. Найбільш явним порушенням було поле tag_list у таблиці publication, оскільки воно містило кілька значень в одному стовпці.

Для приведення схеми до більш правильної структури були створені довідникові таблиці product_type, order_status, payment_method, payment_status, а також таблиці tag і publication_tag для зберігання тегів публікацій. Після цього повторювані текстові значення були замінені зовнішніми ключами.

Оновлена схема краще відповідає третій нормальній формі, зменшує дублювання даних і знижує ризик аномалій вставки, оновлення та видалення.