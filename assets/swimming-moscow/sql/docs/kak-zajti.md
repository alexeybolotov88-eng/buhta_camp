# Swimming Moscow — как зайти

> Сейчас это **сиды базы** из `swimming_moscow_schema.sql`. Отдельной веб-формы входа ещё нет.

## Админ

| Поле | Значение |
|------|----------|
| Логин | `admin` |
| Пароль | `admin123` |
| Роль | супер-админ (`admin`) |
| Email | `admin@swimmingmoscow.ru` |
| Таблица | `admin_users` |

Проверка:

```sql
SELECT id, login, full_name, is_super_admin
FROM admin_users
WHERE login = 'admin'
  AND password_hash = SHA2('admin123', 256)
  AND is_active = 1;
```

## Тестовый пользователь сайта

| Поле | Значение |
|------|----------|
| Email | `parent@example.com` |
| Пароль | `parent123` |
| Роль | `user` |
| Профиль | Анна Иванова / Миша · Качаловский |

## Роли

| Роль | Код | Доступ |
|------|-----|--------|
| Администратор | `admin` | всё |
| Менеджер | `manager` | FAQ, новости, расписание, заявки, прайс |
| Тренер | `teacher` | просмотр расписания / FAQ / заявок |
| Пользователь | `user` | кабинет сайта |

## FAQ: админка vs сайт

| Где | Условие | Что видно |
|-----|---------|-----------|
| Админка | `is_active = 1` | все вопросы + черновики |
| Сайт | `is_active = 1` и `is_published = 1` | только опубликованные |
| VIEW | `v_faq_with_categories` | готовая выборка для сайта |

## Импорт БД

```bash
mysql -u root -p -e "CREATE DATABASE swimming_moscow CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -u root -p swimming_moscow < assets/swimming-moscow/sql/swimming_moscow_schema.sql
```

Презентация со слайдами: [kak-zajti.html](./kak-zajti.html)
