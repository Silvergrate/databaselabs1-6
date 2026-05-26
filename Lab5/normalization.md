# Лабораторна робота №5. Нормалізація бази даних

**Виконав:** Гасюк Д.О.  
**Група:** ІО-41  
**Тема проєкту:** База даних Telegram-бота для продажу цифрових товарів

**Мета роботи**

Мета роботи — проаналізувати структуру створеної бази даних, знайти надлишковість та проблемні місця, а потім привести схему до більш правильної форми з погляду нормалізації.

У цій лабораторній роботі було розглянуто базу даних Telegram-бота для продажу цифрових товарів. У базі зберігаються користувачі, товари, замовлення, платежі, промокоди, публікації, реферальні зв’язки та команди бота.

**1. Аналіз початкової схеми**

Під час аналізу початкової схеми були знайдені такі проблемні місця:

1. У таблиці `publication` поле `tag_list` містило декілька тегів в одному полі.
2. У таблиці `product` поле `product_type` зберігалося як текст і повторювалося в багатьох рядках.
3. У таблиці `bot_order` поле `status` зберігалося як текстове значення.
4. У таблиці `payment` поля `method` і `status` також зберігалися як повторювані текстові значення.

Для перевірки цих проблем були виконані SQL-запити:

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
ORDER BY products_count DESC;

SELECT method, status, COUNT(*) AS payments_count
FROM payment
GROUP BY method, status
ORDER BY method, status;
```

Результати цих запитів показали, що в початковій схемі є повторювані текстові значення та одне неатомарне поле. Найбільш очевидною проблемою є `tag_list`, оскільки в одному полі зберігалося одразу кілька тегів, наприклад `news,catalog` або `promo,discount`.

**2. Функціональні залежності**

Таблиця `publication`

Початкова структура:

```text
publication(publication_id, author_id, title, content, tag_list, created_at)
```

Функціональна залежність:

```text
publication_id → author_id, title, content, tag_list, created_at
```

Проблема полягає в полі `tag_list`. Воно містить не одне значення, а список тегів. Таке поле порушує першу нормальну форму, бо значення в колонці не є атомарним.

Таблиця `product`

Початкова структура:

```text
product(product_id, name, product_type, price, is_active)
```

Функціональна залежність:

```text
product_id → name, product_type, price, is_active
```

Поле `product_type` повторюється у різних товарах. Наприклад, тип `digital_pack` може бути записаний у декількох рядках. Це створює надлишковість і може призвести до помилок при оновленні даних.

Таблиця `bot_order`

Початкова структура:

```text
bot_order(order_id, user_id, promo_code_id, status, created_at, total_amount)
```

Функціональна залежність:

```text
order_id → user_id, promo_code_id, status, created_at, total_amount
```

Поле `status` зберігалося як текст. Значення `paid`, `created`, `completed`, `cancelled` повторювалися у різних записах. Для кращої структури ці статуси варто винести в окрему таблицю.

Таблиця `payment`

Початкова структура:

```text
payment(payment_id, order_id, amount, method, status, paid_at)
```

Функціональна залежність:

```text
payment_id → order_id, amount, method, status, paid_at
```

У таблиці `payment` повторювалися текстові значення методу оплати та статусу платежу. Наприклад, `card`, `manual`, `balance`, `crypto`, а також `paid`, `pending`, `failed`.

**3. Нормалізація до 1НФ, 2НФ і 3НФ**

Перша нормальна форма

Перша нормальна форма вимагає, щоб усі значення в таблицях були атомарними.

Порушення було в таблиці `publication`, де поле `tag_list` містило список тегів. Для виправлення цього поле було прибрано, а теги винесено в окремі таблиці:

```text
publication(publication_id, author_id, title, content, created_at)
tag(tag_id, name)
publication_tag(publication_id, tag_id)
```

Тепер кожен тег зберігається окремим записом у таблиці `tag`, а зв’язок між публікаціями та тегами зберігається в таблиці `publication_tag`.

Друга нормальна форма

Друга нормальна форма вимагає, щоб таблиця була в 1НФ і щоб не було часткових залежностей від частини складеного ключа.

Більшість основних таблиць мають прості первинні ключі:

```text
user_id
product_id
order_id
payment_id
publication_id
```

Тому часткових залежностей у цих таблицях немає.

Таблиця `publication_tag` має складений ключ:

```text
(publication_id, tag_id)
```

У ній немає додаткових неключових атрибутів, тому часткових залежностей також немає.

Третя нормальна форма

Третя нормальна форма вимагає, щоб неключові атрибути залежали тільки від первинного ключа, а не від інших неключових атрибутів.

Для зменшення дублювання були створені довідникові таблиці:

```text
product_type
order_status
payment_method
payment_status
tag
```

Після цього в основних таблицях зберігаються не повторювані текстові значення, а зовнішні ключі:

```text
product.product_type_id → product_type.product_type_id
bot_order.status_id → order_status.status_id
payment.method_id → payment_method.method_id
payment.status_id → payment_status.status_id
publication_tag.tag_id → tag.tag_id
```

**4. Перероблена структура таблиць**

Нормалізація таблиці `product`

Було:

```text
product(product_id, name, product_type, price, is_active)
```

Стало:

```text
product(product_id, name, product_type_id, price, is_active)
product_type(product_type_id, name)
```

Основний SQL-код:

```sql
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
ADD CONSTRAINT fk_product_product_type
FOREIGN KEY (product_type_id)
REFERENCES product_type(product_type_id);

ALTER TABLE product
DROP COLUMN product_type;
```

Нормалізація таблиці `bot_order`

Було:

```text
bot_order(order_id, user_id, promo_code_id, status, created_at, total_amount)
```

Стало:

```text
bot_order(order_id, user_id, promo_code_id, status_id, created_at, total_amount)
order_status(status_id, name)
```

Основний SQL-код:

```sql
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
ADD CONSTRAINT fk_bot_order_status
FOREIGN KEY (status_id)
REFERENCES order_status(status_id);

ALTER TABLE bot_order
DROP COLUMN status;
```

Нормалізація таблиці `payment`

Було:

```text
payment(payment_id, order_id, amount, method, status, paid_at)
```

Стало:

```text
payment(payment_id, order_id, amount, method_id, status_id, paid_at)
payment_method(method_id, name)
payment_status(status_id, name)
```

Основний SQL-код:

```sql
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
ADD CONSTRAINT fk_payment_method
FOREIGN KEY (method_id)
REFERENCES payment_method(method_id);

ALTER TABLE payment
ADD CONSTRAINT fk_payment_status
FOREIGN KEY (status_id)
REFERENCES payment_status(status_id);

ALTER TABLE payment
DROP COLUMN method;

ALTER TABLE payment
DROP COLUMN status;
```

Нормалізація таблиці `publication`

Було:

```text
publication(publication_id, author_id, title, content, tag_list, created_at)
```

Стало:

```text
publication(publication_id, author_id, title, content, created_at)
tag(tag_id, name)
publication_tag(publication_id, tag_id)
```

Основний SQL-код:

```sql
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
```

Повний SQL-скрипт нормалізації знаходиться у файлі `normalization.sql`.

**5. Перевірка після нормалізації**

Після зміни структури були виконані перевірочні запити.

Перевірка нормалізованої таблиці `product`:

```sql
SELECT 
    p.product_id,
    p.name AS product_name,
    pt.name AS product_type,
    p.price,
    p.is_active
FROM product p
JOIN product_type pt ON p.product_type_id = pt.product_type_id
ORDER BY p.product_id;
```

Перевірка нормалізованої таблиці `bot_order`:

```sql
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
```

Перевірка нормалізованої таблиці `payment`:

```sql
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
```

Перевірка нормалізованих тегів публікацій:

```sql
SELECT 
    p.publication_id,
    p.title,
    t.name AS tag_name
FROM publication p
JOIN publication_tag pt ON p.publication_id = pt.publication_id
JOIN tag t ON pt.tag_id = t.tag_id
ORDER BY p.publication_id, t.name;
```

Результати перевірочних запитів показали, що дані коректно перенесені в нові таблиці, а основні таблиці тепер використовують зовнішні ключі замість повторюваних текстових значень.

**6. Оновлена ER-діаграма**

Після нормалізації була оновлена ER-діаграма. На ній додано нові довідникові таблиці та проміжну таблицю для тегів.

До схеми були додані таблиці:

```text
product_type
order_status
payment_method
payment_status
tag
publication_tag
```

Основні нові зв’язки:

```text
product_type 1 — N product
order_status 1 — N bot_order
payment_method 1 — N payment
payment_status 1 — N payment
publication 1 — N publication_tag
tag 1 — N publication_tag
```

Зв’язок між публікаціями і тегами тепер реалізовано як багато-до-багатьох через таблицю `publication_tag`.

**7. Підсумкова структура після нормалізації**

Після нормалізації було додано такі таблиці:

```text
product_type(product_type_id, name)
order_status(status_id, name)
payment_method(method_id, name)
payment_status(status_id, name)
tag(tag_id, name)
publication_tag(publication_id, tag_id)
```

З початкових таблиць були прибрані такі поля:

```text
product.product_type
bot_order.status
payment.method
payment.status
publication.tag_list
```

Замість них використовуються зовнішні ключі:

```text
product.product_type_id
bot_order.status_id
payment.method_id
payment.status_id
publication_tag.publication_id
publication_tag.tag_id
```

**Висновок**

У ході лабораторної роботи було проаналізовано початкову схему бази даних Telegram-бота та знайдено поля, які створювали надлишковість або порушували вимоги нормалізації.

Поле `tag_list` у таблиці `publication` було неатомарним, тому його замінено на окремі таблиці `tag` і `publication_tag`. Повторювані текстові значення `product_type`, `status`, `method` також були винесені в окремі довідникові таблиці.

Після нормалізації схема стала більш структурованою: повторювані значення зберігаються один раз у довідниках, а основні таблиці посилаються на них через зовнішні ключі. Це зменшує дублювання даних і знижує ризик аномалій вставки, оновлення та видалення.
