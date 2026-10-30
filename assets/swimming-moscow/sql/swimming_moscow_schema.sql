-- =============================================================================
-- Swimming Moscow — единый SQL-скрипт схемы сайта школы плавания
-- Сайт: https://swimmingmoscow.ru/
-- СУБД: MySQL 8.0+ / MariaDB 10.5+
-- Кодировка: UTF-8 (utf8mb4)
-- Готов к выполнению «как есть»
-- =============================================================================
-- Структура:
--   1. DROP TABLE (с учётом зависимостей)
--   2. CREATE TABLE
--   3. ALTER TABLE (доп. внешние ключи при необходимости)
--   4. INSERT начальных данных
--   5. VIEW
-- =============================================================================

SET NAMES utf8mb4;
SET CHARACTER SET utf8mb4;
SET collation_connection = 'utf8mb4_unicode_ci';
SET FOREIGN_KEY_CHECKS = 0;
SET SQL_MODE = 'STRICT_TRANS_TABLES,NO_ENGINE_SUBSTITUTION';
SET time_zone = '+03:00';

-- -----------------------------------------------------------------------------
-- Создание / выбор базы (при необходимости раскомментируйте)
-- -----------------------------------------------------------------------------
-- CREATE DATABASE IF NOT EXISTS swimming_moscow
--   CHARACTER SET utf8mb4
--   COLLATE utf8mb4_unicode_ci;
-- USE swimming_moscow;

-- =============================================================================
-- 1. УДАЛЕНИЕ ТАБЛИЦ И ПРЕДСТАВЛЕНИЙ (с учётом зависимостей)
-- =============================================================================

DROP VIEW IF EXISTS v_faq_with_categories;
DROP VIEW IF EXISTS v_active_users;
DROP VIEW IF EXISTS v_published_news;
DROP VIEW IF EXISTS v_week_schedule;
DROP VIEW IF EXISTS v_active_prices;
DROP VIEW IF EXISTS v_teacher_lessons;

DROP TABLE IF EXISTS admin_logs;
DROP TABLE IF EXISTS role_permissions;
DROP TABLE IF EXISTS admin_users;
DROP TABLE IF EXISTS permissions;
DROP TABLE IF EXISTS roles;

DROP TABLE IF EXISTS faq_items;
DROP TABLE IF EXISTS faq_categories;

DROP TABLE IF EXISTS feedback;
DROP TABLE IF EXISTS contacts;

DROP TABLE IF EXISTS announcements;
DROP TABLE IF EXISTS news;

DROP TABLE IF EXISTS schedule;
DROP TABLE IF EXISTS lessons;
DROP TABLE IF EXISTS teachers;

DROP TABLE IF EXISTS prices;
DROP TABLE IF EXISTS branches;

DROP TABLE IF EXISTS user_profiles;
DROP TABLE IF EXISTS users;

-- =============================================================================
-- 2. СОЗДАНИЕ ТАБЛИЦ
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 2.1. Роли и права административной панели
-- -----------------------------------------------------------------------------

CREATE TABLE roles (
  id            INT UNSIGNED     NOT NULL AUTO_INCREMENT COMMENT 'ID роли',
  code          VARCHAR(50)      NOT NULL COMMENT 'Код роли: admin, manager, teacher, user',
  name          VARCHAR(100)     NOT NULL COMMENT 'Название роли',
  description   TEXT             NULL COMMENT 'Описание роли',
  is_system     TINYINT(1)       NOT NULL DEFAULT 0 COMMENT 'Системная роль (нельзя удалить)',
  is_active     TINYINT(1)       NOT NULL DEFAULT 1 COMMENT 'Активна ли роль',
  created_at    DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_roles_code (code),
  KEY idx_roles_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Роли пользователей и администраторов';

CREATE TABLE permissions (
  id            INT UNSIGNED     NOT NULL AUTO_INCREMENT COMMENT 'ID права',
  code          VARCHAR(100)     NOT NULL COMMENT 'Код права, напр. faq.manage',
  name          VARCHAR(150)     NOT NULL COMMENT 'Название права',
  module        VARCHAR(50)      NOT NULL COMMENT 'Модуль: faq, news, schedule, users, admin',
  description   TEXT             NULL,
  is_active     TINYINT(1)       NOT NULL DEFAULT 1,
  created_at    DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_permissions_code (code),
  KEY idx_permissions_module (module),
  KEY idx_permissions_active (is_active)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Права доступа административной панели';

CREATE TABLE role_permissions (
  id             INT UNSIGNED    NOT NULL AUTO_INCREMENT,
  role_id        INT UNSIGNED    NOT NULL,
  permission_id  INT UNSIGNED    NOT NULL,
  created_at     DATETIME        NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_role_permission (role_id, permission_id),
  KEY idx_rp_permission (permission_id),
  CONSTRAINT fk_rp_role
    FOREIGN KEY (role_id) REFERENCES roles (id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_rp_permission
    FOREIGN KEY (permission_id) REFERENCES permissions (id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Связь ролей и прав (many-to-many)';

CREATE TABLE admin_users (
  id              INT UNSIGNED   NOT NULL AUTO_INCREMENT COMMENT 'ID администратора',
  login           VARCHAR(50)    NOT NULL COMMENT 'Логин для входа',
  email           VARCHAR(150)   NOT NULL COMMENT 'Email',
  password_hash   VARCHAR(255)   NOT NULL COMMENT 'Хеш пароля (SHA2-256 или bcrypt)',
  full_name       VARCHAR(150)   NOT NULL COMMENT 'ФИО',
  phone           VARCHAR(30)    NULL COMMENT 'Телефон',
  role_id         INT UNSIGNED   NOT NULL COMMENT 'Роль',
  is_super_admin  TINYINT(1)     NOT NULL DEFAULT 0 COMMENT 'Супер-админ (полный доступ)',
  is_active       TINYINT(1)     NOT NULL DEFAULT 1,
  last_login_at   DATETIME       NULL,
  created_at      DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_admin_login (login),
  UNIQUE KEY uq_admin_email (email),
  KEY idx_admin_role (role_id),
  KEY idx_admin_active (is_active),
  CONSTRAINT fk_admin_role
    FOREIGN KEY (role_id) REFERENCES roles (id)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Пользователи административной панели';

CREATE TABLE admin_logs (
  id            BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT COMMENT 'ID записи лога',
  admin_user_id INT UNSIGNED     NULL COMMENT 'Кто выполнил действие (NULL = система)',
  action        VARCHAR(100)     NOT NULL COMMENT 'Действие: login, create, update, delete',
  entity_type   VARCHAR(50)      NULL COMMENT 'Тип сущности: faq_items, news, ...',
  entity_id     INT UNSIGNED     NULL COMMENT 'ID сущности',
  message       TEXT             NOT NULL COMMENT 'Описание события',
  ip_address    VARCHAR(45)      NULL COMMENT 'IP (IPv4/IPv6)',
  user_agent    VARCHAR(255)     NULL,
  meta_json     JSON             NULL COMMENT 'Доп. данные (старое/новое значение)',
  created_at    DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_logs_admin (admin_user_id),
  KEY idx_logs_action (action),
  KEY idx_logs_entity (entity_type, entity_id),
  KEY idx_logs_created (created_at),
  CONSTRAINT fk_logs_admin
    FOREIGN KEY (admin_user_id) REFERENCES admin_users (id)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Журнал действий администраторов';

-- -----------------------------------------------------------------------------
-- 2.2. Пользователи сайта (клиенты / родители)
-- -----------------------------------------------------------------------------

CREATE TABLE users (
  id              INT UNSIGNED   NOT NULL AUTO_INCREMENT,
  email           VARCHAR(150)   NOT NULL,
  phone           VARCHAR(30)    NULL,
  password_hash   VARCHAR(255)   NOT NULL,
  role_id         INT UNSIGNED   NOT NULL COMMENT 'Базовая роль (обычно user)',
  is_verified     TINYINT(1)     NOT NULL DEFAULT 0 COMMENT 'Email/телефон подтверждён',
  is_active       TINYINT(1)     NOT NULL DEFAULT 1,
  last_login_at   DATETIME       NULL,
  created_at      DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_users_email (email),
  KEY idx_users_phone (phone),
  KEY idx_users_role (role_id),
  KEY idx_users_active (is_active),
  CONSTRAINT fk_users_role
    FOREIGN KEY (role_id) REFERENCES roles (id)
    ON DELETE RESTRICT ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Пользователи сайта (родители / клиенты)';

CREATE TABLE user_profiles (
  id              INT UNSIGNED   NOT NULL AUTO_INCREMENT,
  user_id         INT UNSIGNED   NOT NULL,
  first_name      VARCHAR(80)    NOT NULL,
  last_name       VARCHAR(80)    NOT NULL,
  middle_name     VARCHAR(80)    NULL,
  birth_date      DATE           NULL,
  city            VARCHAR(100)   NULL DEFAULT 'Москва',
  preferred_branch_id INT UNSIGNED NULL COMMENT 'Предпочтительный филиал',
  child_name      VARCHAR(150)   NULL COMMENT 'Имя ребёнка (если родитель)',
  child_birth_date DATE          NULL,
  notes           TEXT           NULL,
  avatar_url      VARCHAR(255)   NULL,
  is_active       TINYINT(1)     NOT NULL DEFAULT 1,
  created_at      DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_profile_user (user_id),
  KEY idx_profile_name (last_name, first_name),
  KEY idx_profile_active (is_active),
  CONSTRAINT fk_profile_user
    FOREIGN KEY (user_id) REFERENCES users (id)
    ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Профили пользователей сайта';

-- -----------------------------------------------------------------------------
-- 2.3. Филиалы и прайс (справочники школы)
-- -----------------------------------------------------------------------------

CREATE TABLE branches (
  id            INT UNSIGNED     NOT NULL AUTO_INCREMENT,
  code          VARCHAR(50)      NOT NULL COMMENT 'Код филиала: zaryad, voskhod, ...',
  name          VARCHAR(100)     NOT NULL COMMENT 'Короткое название',
  full_name     VARCHAR(200)     NOT NULL COMMENT 'Полное название бассейна',
  address       VARCHAR(255)     NOT NULL,
  metro         VARCHAR(100)     NULL,
  ages_text     VARCHAR(100)     NULL COMMENT 'Возрастные группы текстом',
  phone         VARCHAR(30)      NULL,
  capacity_max  TINYINT UNSIGNED NOT NULL DEFAULT 10 COMMENT 'Макс. человек в группе',
  sort_order    INT              NOT NULL DEFAULT 0,
  is_active     TINYINT(1)       NOT NULL DEFAULT 1,
  created_at    DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_branches_code (code),
  KEY idx_branches_active_sort (is_active, sort_order)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Филиалы Swimming Moscow';

CREATE TABLE prices (
  id            INT UNSIGNED     NOT NULL AUTO_INCREMENT,
  code          VARCHAR(50)      NOT NULL COMMENT 'Код тарифа',
  category      ENUM('trial','abonement','package','personal','single')
                                 NOT NULL COMMENT 'Категория тарифа',
  title         VARCHAR(150)     NOT NULL,
  description   TEXT             NULL,
  lessons_count SMALLINT UNSIGNED NULL COMMENT 'Кол-во занятий в пакете/абонементе',
  per_week      TINYINT UNSIGNED NULL COMMENT 'Рекомендуемая частота в неделю',
  price_rub     DECIMAL(10,2)    NOT NULL COMMENT 'Цена в рублях',
  is_featured   TINYINT(1)       NOT NULL DEFAULT 0 COMMENT 'Акцент на сайте (🔥)',
  sort_order    INT              NOT NULL DEFAULT 0,
  is_active     TINYINT(1)       NOT NULL DEFAULT 1,
  valid_from    DATE             NULL,
  valid_to      DATE             NULL,
  created_at    DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_prices_code (code),
  KEY idx_prices_category (category),
  KEY idx_prices_active_sort (is_active, sort_order),
  CONSTRAINT chk_prices_amount CHECK (price_rub >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Актуальный прайс Swimming Moscow (детская группа)';

-- -----------------------------------------------------------------------------
-- 2.4. Тренеры, уроки, расписание
-- -----------------------------------------------------------------------------

CREATE TABLE teachers (
  id            INT UNSIGNED     NOT NULL AUTO_INCREMENT,
  full_name     VARCHAR(150)     NOT NULL,
  short_name    VARCHAR(80)      NULL COMMENT 'Как в расписании: Алексей, Мария',
  phone         VARCHAR(30)      NULL,
  email         VARCHAR(150)     NULL,
  bio           TEXT             NULL,
  photo_url     VARCHAR(255)     NULL,
  specialties   VARCHAR(255)     NULL COMMENT 'Детское / персональное / сплит',
  is_active     TINYINT(1)       NOT NULL DEFAULT 1,
  sort_order    INT              NOT NULL DEFAULT 0,
  created_at    DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_teachers_active (is_active, sort_order),
  KEY idx_teachers_name (full_name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Тренеры школы';

CREATE TABLE lessons (
  id            INT UNSIGNED     NOT NULL AUTO_INCREMENT,
  branch_id     INT UNSIGNED     NOT NULL,
  teacher_id    INT UNSIGNED     NULL,
  title         VARCHAR(150)     NOT NULL COMMENT 'Название группы / занятия',
  lesson_type   ENUM('group','personal','split','trial')
                                 NOT NULL DEFAULT 'group',
  age_from      TINYINT UNSIGNED NULL COMMENT 'Возраст от',
  age_to        TINYINT UNSIGNED NULL COMMENT 'Возраст до',
  duration_min  SMALLINT UNSIGNED NOT NULL DEFAULT 45 COMMENT 'Длительность, мин',
  capacity_max  TINYINT UNSIGNED NOT NULL DEFAULT 10,
  description   TEXT             NULL,
  is_active     TINYINT(1)       NOT NULL DEFAULT 1,
  created_at    DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_lessons_branch (branch_id),
  KEY idx_lessons_teacher (teacher_id),
  KEY idx_lessons_type (lesson_type),
  KEY idx_lessons_active (is_active),
  CONSTRAINT fk_lessons_branch
    FOREIGN KEY (branch_id) REFERENCES branches (id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_lessons_teacher
    FOREIGN KEY (teacher_id) REFERENCES teachers (id)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT chk_lessons_age CHECK (
    age_from IS NULL OR age_to IS NULL OR age_from <= age_to
  )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Типы / карточки занятий (группы)';

CREATE TABLE schedule (
  id            INT UNSIGNED     NOT NULL AUTO_INCREMENT,
  lesson_id     INT UNSIGNED     NOT NULL,
  teacher_id    INT UNSIGNED     NULL COMMENT 'Переопределение тренера на слот',
  weekday       TINYINT UNSIGNED NOT NULL COMMENT '1=Пн ... 7=Вс',
  start_time    TIME             NOT NULL,
  end_time      TIME             NOT NULL,
  week_start    DATE             NULL COMMENT 'Если NULL — постоянный слот шаблона',
  specific_date DATE             NULL COMMENT 'Конкретная дата (разовый слот)',
  seats_taken   TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Занято мест',
  is_cancelled  TINYINT(1)       NOT NULL DEFAULT 0,
  comment       VARCHAR(255)     NULL,
  is_active     TINYINT(1)       NOT NULL DEFAULT 1,
  created_at    DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_schedule_lesson (lesson_id),
  KEY idx_schedule_teacher (teacher_id),
  KEY idx_schedule_weekday (weekday, start_time),
  KEY idx_schedule_date (specific_date),
  KEY idx_schedule_week (week_start),
  KEY idx_schedule_active (is_active, is_cancelled),
  CONSTRAINT fk_schedule_lesson
    FOREIGN KEY (lesson_id) REFERENCES lessons (id)
    ON DELETE CASCADE ON UPDATE CASCADE,
  CONSTRAINT fk_schedule_teacher
    FOREIGN KEY (teacher_id) REFERENCES teachers (id)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT chk_schedule_weekday CHECK (weekday BETWEEN 1 AND 7),
  CONSTRAINT chk_schedule_time CHECK (end_time > start_time),
  CONSTRAINT chk_schedule_seats CHECK (seats_taken >= 0)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Расписание занятий (шаблон + слоты недели)';

-- -----------------------------------------------------------------------------
-- 2.5. Новости и объявления
-- -----------------------------------------------------------------------------

CREATE TABLE news (
  id              INT UNSIGNED   NOT NULL AUTO_INCREMENT,
  title           VARCHAR(200)   NOT NULL,
  slug            VARCHAR(220)   NOT NULL,
  summary         VARCHAR(500)   NULL COMMENT 'Краткий анонс',
  body            TEXT           NOT NULL,
  cover_url       VARCHAR(255)   NULL,
  author_admin_id INT UNSIGNED   NULL,
  published_at    DATETIME       NULL COMMENT 'Дата публикации на сайте',
  is_published    TINYINT(1)     NOT NULL DEFAULT 0 COMMENT 'Опубликовано для сайта',
  is_active       TINYINT(1)     NOT NULL DEFAULT 1 COMMENT 'Доступно в админке / не удалено',
  views           INT UNSIGNED   NOT NULL DEFAULT 0,
  created_at      DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_news_slug (slug),
  KEY idx_news_published (is_published, published_at),
  KEY idx_news_active (is_active),
  KEY idx_news_author (author_admin_id),
  CONSTRAINT fk_news_author
    FOREIGN KEY (author_admin_id) REFERENCES admin_users (id)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Новости школы';

CREATE TABLE announcements (
  id              INT UNSIGNED   NOT NULL AUTO_INCREMENT,
  title           VARCHAR(200)   NOT NULL,
  body            TEXT           NOT NULL,
  branch_id       INT UNSIGNED   NULL COMMENT 'NULL = для всех филиалов',
  priority        TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Чем выше — выше в ленте',
  starts_at       DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
  ends_at         DATETIME       NULL,
  is_published    TINYINT(1)     NOT NULL DEFAULT 0,
  is_active       TINYINT(1)     NOT NULL DEFAULT 1,
  created_by      INT UNSIGNED   NULL,
  created_at      DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_ann_branch (branch_id),
  KEY idx_ann_pub (is_published, starts_at),
  KEY idx_ann_active (is_active),
  KEY idx_ann_priority (priority),
  CONSTRAINT fk_ann_branch
    FOREIGN KEY (branch_id) REFERENCES branches (id)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT fk_ann_author
    FOREIGN KEY (created_by) REFERENCES admin_users (id)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Объявления (баннеры / уведомления на сайте)';

-- -----------------------------------------------------------------------------
-- 2.6. FAQ — управление в админке, на сайте только опубликованные
-- -----------------------------------------------------------------------------

CREATE TABLE faq_categories (
  id            INT UNSIGNED     NOT NULL AUTO_INCREMENT,
  code          VARCHAR(50)      NOT NULL,
  name          VARCHAR(100)     NOT NULL,
  description   VARCHAR(255)     NULL,
  icon          VARCHAR(50)      NULL COMMENT 'Иконка для UI',
  sort_order    INT              NOT NULL DEFAULT 0,
  is_active     TINYINT(1)       NOT NULL DEFAULT 1,
  created_at    DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uq_faq_cat_code (code),
  KEY idx_faq_cat_active_sort (is_active, sort_order)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Категории FAQ';

CREATE TABLE faq_items (
  id              INT UNSIGNED   NOT NULL AUTO_INCREMENT,
  category_id     INT UNSIGNED   NOT NULL,
  question        VARCHAR(500)   NOT NULL,
  answer          TEXT           NOT NULL,
  views           INT UNSIGNED   NOT NULL DEFAULT 0,
  is_pinned       TINYINT(1)     NOT NULL DEFAULT 0 COMMENT 'Закрепить сверху в категории',
  sort_order      INT            NOT NULL DEFAULT 0,
  is_published    TINYINT(1)     NOT NULL DEFAULT 0 COMMENT 'Показывать на сайте',
  is_active       TINYINT(1)     NOT NULL DEFAULT 1 COMMENT 'Доступно в админке (не архив)',
  published_at    DATETIME       NULL,
  created_by      INT UNSIGNED   NULL,
  updated_by      INT UNSIGNED   NULL,
  created_at      DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at      DATETIME       NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_faq_category (category_id),
  KEY idx_faq_site (is_published, is_active, is_pinned, sort_order),
  KEY idx_faq_views (views),
  FULLTEXT KEY ft_faq_qa (question, answer),
  CONSTRAINT fk_faq_category
    FOREIGN KEY (category_id) REFERENCES faq_categories (id)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT fk_faq_created_by
    FOREIGN KEY (created_by) REFERENCES admin_users (id)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT fk_faq_updated_by
    FOREIGN KEY (updated_by) REFERENCES admin_users (id)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Вопросы FAQ: админ видит все (is_active), сайт — только is_published=1';

-- -----------------------------------------------------------------------------
-- 2.7. Контакты и обратная связь
-- -----------------------------------------------------------------------------

CREATE TABLE contacts (
  id            INT UNSIGNED     NOT NULL AUTO_INCREMENT,
  contact_type  ENUM('phone','email','messenger','address','social','other')
                                 NOT NULL DEFAULT 'phone',
  label         VARCHAR(100)     NOT NULL COMMENT 'Подпись: WhatsApp, Telegram, ...',
  value         VARCHAR(255)     NOT NULL COMMENT 'Номер, ссылка, адрес',
  branch_id     INT UNSIGNED     NULL,
  sort_order    INT              NOT NULL DEFAULT 0,
  is_primary    TINYINT(1)       NOT NULL DEFAULT 0,
  is_active     TINYINT(1)       NOT NULL DEFAULT 1,
  created_at    DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_contacts_type (contact_type),
  KEY idx_contacts_branch (branch_id),
  KEY idx_contacts_active (is_active, sort_order),
  CONSTRAINT fk_contacts_branch
    FOREIGN KEY (branch_id) REFERENCES branches (id)
    ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Контактные данные школы для сайта';

CREATE TABLE feedback (
  id            INT UNSIGNED     NOT NULL AUTO_INCREMENT,
  user_id       INT UNSIGNED     NULL COMMENT 'Если авторизован',
  name          VARCHAR(150)     NOT NULL,
  phone         VARCHAR(30)      NULL,
  email         VARCHAR(150)     NULL,
  branch_id     INT UNSIGNED     NULL,
  subject       VARCHAR(200)     NULL,
  message       TEXT             NOT NULL,
  source        VARCHAR(50)      NULL DEFAULT 'site'
                COMMENT 'site, whatsapp, yandex, 2gis, promo',
  status        ENUM('new','in_progress','done','spam')
                                 NOT NULL DEFAULT 'new',
  assigned_admin_id INT UNSIGNED NULL,
  is_active     TINYINT(1)       NOT NULL DEFAULT 1,
  created_at    DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at    DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_feedback_status (status, created_at),
  KEY idx_feedback_branch (branch_id),
  KEY idx_feedback_user (user_id),
  KEY idx_feedback_source (source),
  KEY idx_feedback_active (is_active),
  CONSTRAINT fk_feedback_user
    FOREIGN KEY (user_id) REFERENCES users (id)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT fk_feedback_branch
    FOREIGN KEY (branch_id) REFERENCES branches (id)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT fk_feedback_admin
    FOREIGN KEY (assigned_admin_id) REFERENCES admin_users (id)
    ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT chk_feedback_contact CHECK (
    phone IS NOT NULL OR email IS NOT NULL
  )
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
  COMMENT='Заявки и обратная связь с сайта';

-- =============================================================================
-- 3. ALTER TABLE — дополнительные связи (профиль → филиал)
-- =============================================================================

ALTER TABLE user_profiles
  ADD CONSTRAINT fk_profile_branch
    FOREIGN KEY (preferred_branch_id) REFERENCES branches (id)
    ON DELETE SET NULL ON UPDATE CASCADE;

SET FOREIGN_KEY_CHECKS = 1;

-- =============================================================================
-- 4. НАЧАЛЬНЫЕ ДАННЫЕ (INSERT)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 4.1. Роли: admin, manager, teacher, user
-- -----------------------------------------------------------------------------

INSERT INTO roles (id, code, name, description, is_system, is_active) VALUES
(1, 'admin',   'Администратор',     'Полный доступ к панели (супер-админ)', 1, 1),
(2, 'manager', 'Менеджер',          'CRM, заявки, расписание, продажи',     1, 1),
(3, 'teacher', 'Тренер',            'Просмотр расписания и своих групп',    1, 1),
(4, 'user',    'Пользователь сайта','Клиент / родитель на сайте',           1, 1);

-- -----------------------------------------------------------------------------
-- 4.2. Права доступа
-- -----------------------------------------------------------------------------

INSERT INTO permissions (id, code, name, module, description, is_active) VALUES
(1,  'admin.access',       'Вход в админ-панель',        'admin',    'Базовый доступ в панель', 1),
(2,  'faq.view',           'Просмотр FAQ',               'faq',      'Список всех вопросов', 1),
(3,  'faq.manage',         'Управление FAQ',             'faq',      'Создание / правка / публикация FAQ', 1),
(4,  'news.view',          'Просмотр новостей',          'news',     NULL, 1),
(5,  'news.manage',        'Управление новостями',       'news',     NULL, 1),
(6,  'schedule.view',      'Просмотр расписания',        'schedule', NULL, 1),
(7,  'schedule.manage',    'Управление расписанием',     'schedule', NULL, 1),
(8,  'users.view',         'Просмотр пользователей',     'users',    NULL, 1),
(9,  'users.manage',       'Управление пользователями',  'users',    NULL, 1),
(10, 'feedback.view',      'Просмотр заявок',            'feedback', NULL, 1),
(11, 'feedback.manage',    'Обработка заявок',           'feedback', NULL, 1),
(12, 'prices.manage',      'Управление прайсом',         'admin',    NULL, 1),
(13, 'logs.view',          'Просмотр логов',             'admin',    NULL, 1);

-- Супер-админ (role admin) — все права
INSERT INTO role_permissions (role_id, permission_id)
SELECT 1, id FROM permissions WHERE is_active = 1;

-- Менеджер
INSERT INTO role_permissions (role_id, permission_id)
SELECT 2, id FROM permissions
WHERE code IN (
  'admin.access','faq.view','faq.manage','news.view','news.manage',
  'schedule.view','schedule.manage','users.view','feedback.view',
  'feedback.manage','prices.manage'
);

-- Тренер
INSERT INTO role_permissions (role_id, permission_id)
SELECT 3, id FROM permissions
WHERE code IN ('admin.access','schedule.view','feedback.view','faq.view');

-- -----------------------------------------------------------------------------
-- 4.3. Администратор: login=admin, password=admin123, роль супер-админ
-- Пароль: admin123
-- Хеш: SHA2-256 (для демо). В проде замените на bcrypt/argon2!
-- SHA2('admin123', 256) = 240be518fabd2724ddb6f04eeb1da5967448d7e831c08c8fa822809f74c720a9
-- -----------------------------------------------------------------------------

INSERT INTO admin_users (
  id, login, email, password_hash, full_name, phone,
  role_id, is_super_admin, is_active
) VALUES (
  1,
  'admin',
  'admin@swimmingmoscow.ru',
  SHA2('admin123', 256),
  'Супер Администратор',
  '+7 (900) 000-00-00',
  1,
  1,
  1
);

INSERT INTO admin_logs (admin_user_id, action, entity_type, entity_id, message, ip_address)
VALUES (1, 'seed', 'admin_users', 1, 'Создан супер-админ при инициализации БД', '127.0.0.1');

-- -----------------------------------------------------------------------------
-- 4.4. Филиалы
-- -----------------------------------------------------------------------------

INSERT INTO branches (id, code, name, full_name, address, metro, ages_text, capacity_max, sort_order, is_active) VALUES
(1, 'zaryad',      'Заряд',       'ФОК «Заряд»',
   'ул. Краснодонская, 1к1', 'Текстильщики', 'дети от 4 лет / взрослые', 10, 10, 1),
(2, 'voskhod',     'Восход',      'ФОК «Восход»',
   'Ореховый пр-д, 26', 'Красногвардейская / Зябликово', 'дети от 3 лет / взрослые', 10, 20, 1),
(3, 'maximum',     'Максимум',    '«Максимум Спорт»',
   'Волгоградский пр-т, 46/15с4', 'Текстильщики / Волгоградский проспект', 'дети от 4 лет / взрослые', 10, 30, 1),
(4, 'kachalovsky', 'Качаловский', 'Бассейн «Качаловский»',
   'ул. Каховка, 25', 'Каховская / Севастопольская', 'дети от 3 лет', 10, 40, 1),
(5, 'pegas',       'Пегас',       'ФОК «Пегас»',
   'ул. Верхние Поля, 27с1', 'Люблино / Братиславская', 'дети от 4 лет', 10, 50, 1);

-- -----------------------------------------------------------------------------
-- 4.5. Актуальный прайс (детская группа) — обновлённый
-- -----------------------------------------------------------------------------

INSERT INTO prices (code, category, title, description, lessons_count, per_week, price_rub, is_featured, sort_order, is_active) VALUES
('trial',            'trial',     'Пробная тренировка',
 'Знакомство с тренером и мягкая адаптация', 1, NULL, 1000.00, 0, 10, 1),
('abon_4',           'abonement', 'Абонемент 4 занятия',
 '1 раз в неделю', 4, 1, 6400.00, 0, 20, 1),
('abon_8',           'abonement', 'Абонемент 8 занятий',
 '2 раза в неделю', 8, 2, 11100.00, 1, 30, 1),
('abon_12',          'abonement', 'Абонемент 12 занятий',
 '3 раза в неделю', 12, 3, 15200.00, 0, 40, 1),
('single',           'single',    'Разовое занятие',
 'Без закрепления места в группе', 1, NULL, 1900.00, 0, 50, 1),
('pack_12',          'package',   'Пакет 12 занятий',
 '1 раз в неделю', 12, 1, 17850.00, 0, 60, 1),
('pack_24',          'package',   'Пакет 24 занятия',
 '2 раза в неделю', 24, 2, 30400.00, 1, 70, 1),
('pack_36',          'package',   'Пакет 36 занятий',
 '3 раза в неделю', 36, 3, 41600.00, 0, 80, 1),
('personal',         'personal',  'Персональная тренировка',
 'Индивидуально с тренером', 1, NULL, 5000.00, 0, 90, 1),
('split',            'personal',  'Сплит-тренировка (для двоих)',
 'Персональное занятие на двоих', 1, NULL, 7000.00, 0, 100, 1);

-- -----------------------------------------------------------------------------
-- 4.6. Тренеры и занятия
-- -----------------------------------------------------------------------------

INSERT INTO teachers (id, full_name, short_name, specialties, is_active, sort_order) VALUES
(1, 'Алексей Болотов', 'Алексей', 'персональные, сплит, детские группы', 1, 10),
(2, 'Мария',           'Мария',   'детские группы, адаптация новичков', 1, 20),
(3, 'Тренер смены',    'Смена',   'группы по расписанию филиала', 1, 30);

INSERT INTO lessons (id, branch_id, teacher_id, title, lesson_type, age_from, age_to, duration_min, capacity_max, is_active) VALUES
(1, 1, 2, 'Детская группа Заряд 4–6',     'group', 4, 6, 45, 10, 1),
(2, 1, 1, 'Детская группа Заряд 7–10',    'group', 7, 10, 45, 10, 1),
(3, 2, 2, 'Детская группа Восход 3–5',    'group', 3, 5, 45, 10, 1),
(4, 2, 3, 'Детская группа Восход 6–9',    'group', 6, 9, 45, 10, 1),
(5, 3, 3, 'Детская группа Максимум 4–7',  'group', 4, 7, 45, 10, 1),
(6, 4, 2, 'Детская группа Качаловский 3–6','group', 3, 6, 45, 10, 1),
(7, 4, 1, 'Детская группа Качаловский 7–10','group', 7, 10, 45, 10, 1),
(8, 5, 3, 'Детская группа Пегас 4–7',     'group', 4, 7, 45, 10, 1),
(9, 1, 1, 'Пробное занятие',              'trial', 3, 12, 45, 1, 1),
(10,1, 1, 'Персональная тренировка',      'personal', NULL, NULL, 45, 1, 1);

-- -----------------------------------------------------------------------------
-- 4.7. Расписание на текущую неделю (31.08.2026 — 06.09.2026)
-- week_start = понедельник недели; specific_date — конкретный день
-- -----------------------------------------------------------------------------

INSERT INTO schedule
  (lesson_id, teacher_id, weekday, start_time, end_time, week_start, specific_date, seats_taken, is_active)
VALUES
-- Понедельник 31.08
(1, 2, 1, '16:00:00', '16:45:00', '2026-08-31', '2026-08-31', 6, 1),
(2, 1, 1, '17:00:00', '17:45:00', '2026-08-31', '2026-08-31', 8, 1),
(6, 2, 1, '17:30:00', '18:15:00', '2026-08-31', '2026-08-31', 7, 1),
-- Вторник 01.09
(3, 2, 2, '16:00:00', '16:45:00', '2026-08-31', '2026-09-01', 4, 1),
(5, 3, 2, '17:00:00', '17:45:00', '2026-08-31', '2026-09-01', 5, 1),
(7, 1, 2, '18:00:00', '18:45:00', '2026-08-31', '2026-09-01', 9, 1),
-- Среда 02.09
(1, 2, 3, '16:00:00', '16:45:00', '2026-08-31', '2026-09-02', 7, 1),
(4, 3, 3, '17:00:00', '17:45:00', '2026-08-31', '2026-09-02', 3, 1),
(8, 3, 3, '17:30:00', '18:15:00', '2026-08-31', '2026-09-02', 2, 1),
(9, 1, 3, '18:30:00', '19:15:00', '2026-08-31', '2026-09-02', 0, 1),
-- Четверг 03.09
(2, 1, 4, '16:30:00', '17:15:00', '2026-08-31', '2026-09-03', 8, 1),
(6, 2, 4, '17:30:00', '18:15:00', '2026-08-31', '2026-09-03', 6, 1),
(5, 3, 4, '18:00:00', '18:45:00', '2026-08-31', '2026-09-03', 4, 1),
-- Пятница 04.09
(1, 2, 5, '16:00:00', '16:45:00', '2026-08-31', '2026-09-04', 5, 1),
(7, 1, 5, '17:00:00', '17:45:00', '2026-08-31', '2026-09-04', 9, 1),
(3, 2, 5, '17:30:00', '18:15:00', '2026-08-31', '2026-09-04', 3, 1),
(10,1, 5, '19:00:00', '19:45:00', '2026-08-31', '2026-09-04', 1, 1),
-- Суббота 05.09
(6, 2, 6, '10:00:00', '10:45:00', '2026-08-31', '2026-09-05', 8, 1),
(2, 1, 6, '11:00:00', '11:45:00', '2026-08-31', '2026-09-05', 7, 1),
(8, 3, 6, '12:00:00', '12:45:00', '2026-08-31', '2026-09-05', 1, 1),
(9, 1, 6, '13:00:00', '13:45:00', '2026-08-31', '2026-09-05', 0, 1),
-- Воскресенье 06.09
(4, 3, 7, '10:00:00', '10:45:00', '2026-08-31', '2026-09-06', 2, 1),
(5, 3, 7, '11:00:00', '11:45:00', '2026-08-31', '2026-09-06', 4, 1),
(7, 1, 7, '12:00:00', '12:45:00', '2026-08-31', '2026-09-06', 6, 1);

-- Постоянный шаблон (без specific_date) — для повторяющегося расписания на сайте
INSERT INTO schedule
  (lesson_id, teacher_id, weekday, start_time, end_time, week_start, specific_date, seats_taken, is_active)
VALUES
(1, 2, 1, '16:00:00', '16:45:00', NULL, NULL, 0, 1),
(2, 1, 1, '17:00:00', '17:45:00', NULL, NULL, 0, 1),
(6, 2, 1, '17:30:00', '18:15:00', NULL, NULL, 0, 1),
(3, 2, 2, '16:00:00', '16:45:00', NULL, NULL, 0, 1),
(5, 3, 2, '17:00:00', '17:45:00', NULL, NULL, 0, 1),
(7, 1, 2, '18:00:00', '18:45:00', NULL, NULL, 0, 1),
(1, 2, 3, '16:00:00', '16:45:00', NULL, NULL, 0, 1),
(4, 3, 3, '17:00:00', '17:45:00', NULL, NULL, 0, 1),
(8, 3, 3, '17:30:00', '18:15:00', NULL, NULL, 0, 1),
(2, 1, 4, '16:30:00', '17:15:00', NULL, NULL, 0, 1),
(6, 2, 4, '17:30:00', '18:15:00', NULL, NULL, 0, 1),
(1, 2, 5, '16:00:00', '16:45:00', NULL, NULL, 0, 1),
(7, 1, 5, '17:00:00', '17:45:00', NULL, NULL, 0, 1),
(6, 2, 6, '10:00:00', '10:45:00', NULL, NULL, 0, 1),
(2, 1, 6, '11:00:00', '11:45:00', NULL, NULL, 0, 1),
(8, 3, 6, '12:00:00', '12:45:00', NULL, NULL, 0, 1);

-- -----------------------------------------------------------------------------
-- 4.8. Новости и объявления
-- -----------------------------------------------------------------------------

INSERT INTO news (
  title, slug, summary, body, author_admin_id,
  published_at, is_published, is_active, views
) VALUES
(
  'Набор групп на новый сезон',
  'nabor-grupp-na-novyj-sezon',
  'Открыт набор в детские группы во всех филиалах Swimming Moscow.',
  'Друзья, открываем набор групп на новый сезон!\n\nФилиалы: Заряд, Восход, Максимум, Качаловский, Пегас.\n\nПробная тренировка — 1 000 ₽: знакомство с тренером, мягкая адаптация, рекомендации по формату занятий (группа или индивидуально).\n\nЗапись: на сайте swimmingmoscow.ru или в мессенджерах @swimming_moscow.',
  1, '2026-09-01 10:00:00', 1, 1, 42
),
(
  'Открывается филиал Пегас',
  'otkryvaetsya-filial-pegas',
  'Новый бассейн на Верхних Полях — набор в детские группы от 4 лет.',
  'Рады сообщить: скоро стартуют занятия в ФОК «Пегас» (ул. Верхние Поля, 27с1).\n\nИдёт набор в группы для детей от 4 лет. Успейте записаться на пробное занятие, пока есть места.\n\nНа занятии нужны: очки, шапочка, купальник/плавки, шлёпанцы, полотенце, результат анализа на энтеробиоз; для родителя — сменная обувь.',
  1, '2026-09-02 12:00:00', 1, 1, 18
),
(
  'Актуальное расписание и прайс',
  'aktualnoe-raspisanie-i-price',
  'Обновили стоимость обучения и пакеты занятий.',
  'Обновлённый прайс (детская группа):\n• Пробная — 1 000 ₽\n• Абонементы 4 / 8 / 12 занятий — 6 400 / 11 100 / 15 200 ₽\n• Разовое — 1 900 ₽\n• Пакеты 12 / 24 / 36 — 17 850 / 30 400 / 41 600 ₽\n• Персональная — 5 000 ₽, сплит (для двоих) — 7 000 ₽\n\nАктуальные слоты смотрите в разделе «Расписание».',
  1, '2026-09-03 09:30:00', 1, 1, 27
);

INSERT INTO announcements (
  title, body, branch_id, priority, starts_at, ends_at, is_published, is_active, created_by
) VALUES
(
  'Пробное занятие — 1 000 ₽',
  'Полноценная тренировка: знакомство с тренером, формат занятия, ответы на вопросы, выбор группы или индивидуально. Тренер оценит навыки и даст рекомендации.',
  NULL, 10, '2026-09-01 00:00:00', '2026-10-31 23:59:59', 1, 1, 1
),
(
  'Пегас: набор в новые группы',
  'ФОК «Пегас», ул. Верхние Поля, 27с1. Дети от 4 лет. Запись на пробные — в чате администратора.',
  5, 20, '2026-09-01 00:00:00', '2026-09-30 23:59:59', 1, 1, 1
);

-- -----------------------------------------------------------------------------
-- 4.9. Категории FAQ
-- -----------------------------------------------------------------------------

INSERT INTO faq_categories (id, code, name, description, icon, sort_order, is_active) VALUES
(1, 'training',   'Обучение',      'Пробные, группы, формат занятий',        'swim',     10, 1),
(2, 'support',    'Техподдержка',  'Связь, запись, CRM, ответы администратора','headset', 20, 1),
(3, 'schedule',   'Расписание',    'Филиалы, слоты, переносы',               'calendar', 30, 1),
(4, 'documents',  'Документы',     'Справки, договор, оплата, правила',      'docs',     40, 1);

-- -----------------------------------------------------------------------------
-- 4.10. Вопросы FAQ (опубликованные + один черновик для админки)
-- На сайте: is_published = 1 AND is_active = 1
-- -----------------------------------------------------------------------------

INSERT INTO faq_items (
  category_id, question, answer, views, is_pinned, sort_order,
  is_published, is_active, published_at, created_by, updated_by
) VALUES
-- === Обучение ===
(1,
 'Что такое пробное занятие и что на нём происходит?',
 'Пробное занятие — это полноценная тренировка, во время которой вы сможете:\n• познакомиться с тренером;\n• узнать, как проходит занятие;\n• задать все интересующие вопросы;\n• выбрать наиболее комфортный формат: индивидуально или в группе.\n\nТренер оценит навыки, даст обратную связь и рекомендации по дальнейшим тренировкам.\nСтоимость пробной тренировки — 1 000 ₽.',
 120, 1, 10, 1, 1, '2026-09-01 10:00:00', 1, 1),

(1,
 'Что нужно взять с собой на занятие?',
 'На занятии при себе необходимо иметь:\n• очки, шапочку, купальник/плавки, шлёпанцы, полотенце;\n• результат анализа на энтеробиоз;\n• сменную обувь для родителя.\n\nБез справки (анализа) администрация бассейна может не допустить к воде — уточняйте правила конкретного филиала.',
 95, 1, 20, 1, 1, '2026-09-01 10:00:00', 1, 1),

(1,
 'Какие есть форматы занятий?',
 'Доступны:\n• детские группы (закреплённое место в группе);\n• разовое занятие без закрепления места — 1 900 ₽;\n• персональная тренировка — 5 000 ₽;\n• сплит-тренировка для двоих — 7 000 ₽;\n• пробная тренировка — 1 000 ₽.\n\nФормат подбирается после пробного занятия вместе с тренером.',
 70, 0, 30, 1, 1, '2026-09-01 10:00:00', 1, 1),

(1,
 'С какого возраста можно начинать?',
 'В зависимости от филиала:\n• Восход и Качаловский — дети от 3 лет;\n• Заряд, Максимум, Пегас — дети от 4 лет.\nНа части площадок есть взрослые группы. Точный возрастной диапазон группы смотрите в расписании филиала.',
 55, 0, 40, 1, 1, '2026-09-01 10:00:00', 1, 1),

(1,
 'Чем абонемент отличается от пакета занятий?',
 'Абонемент рассчитан на регулярные занятия в выбранном ритме (1 / 2 / 3 раза в неделю) с закреплением места в группе.\nПакет — это набор занятий на более длинный период с выгодной стоимостью за тренировку.\n\nАктуальные цены:\nАбонементы: 4 — 6 400 ₽, 8 — 11 100 ₽, 12 — 15 200 ₽.\nПакеты: 12 — 17 850 ₽, 24 — 30 400 ₽, 36 — 41 600 ₽.',
 88, 0, 50, 1, 1, '2026-09-01 10:00:00', 1, 1),

(1,
 'Сколько человек максимум в группе?',
 'Максимальная наполняемость группы — 10 человек. Это позволяет тренеру уделять внимание каждому ребёнку и сохранять качество обучения.',
 40, 0, 60, 1, 1, '2026-09-01 10:00:00', 1, 1),

(1,
 'Можно ли заниматься индивидуально?',
 'Да. Персональная тренировка — 5 000 ₽. Для двоих доступен сплит — 7 000 ₽.\nОплаты персональных занятий (кроме персональных Алексея) контролируются через тренеров; при необходимости возможна фиксация продажи в долг по регламенту администратора.',
 33, 0, 70, 1, 1, '2026-09-01 10:00:00', 1, 1),

(1,
 'Как проходит адаптация новичка?',
 'На пробном занятии тренер знакомится с ребёнком, оценивает уровень комфорта в воде и навыки. Далее рекомендует группу или персональный формат, частоту занятий и следующий шаг. До занятия администратор отправляет напоминание новичку накануне.',
 28, 0, 80, 1, 1, '2026-09-01 10:00:00', 1, 1),

-- === Техподдержка ===
(2,
 'Как быстро вам отвечают?',
 'Регламент ответа администратора:\n• новым клиентам — в течение 10 минут;\n• повторным обращениям — до 20 минут (в рабочее время).\nПишите в WhatsApp / Telegram — ссылки многоразовые и закреплены в шапке чатов.',
 61, 1, 10, 1, 1, '2026-09-01 10:00:00', 1, 1),

(2,
 'Как записаться на пробное занятие?',
 'Оставьте заявку на сайте swimmingmoscow.ru или напишите в мессенджер @swimming_moscow.\nАдминистратор уточнит филиал, возраст ребёнка, удобное время и оформит пробное занятие. Новую сделку помечают с указанием источника, филиала и графика.',
 77, 1, 20, 1, 1, '2026-09-01 10:00:00', 1, 1),

(2,
 'Что делать, если не смогли прийти на пробное?',
 'Напишите администратору как можно раньше. Мы предложим перенос и свяжемся с «недошедшими» в течение рабочего дня. Также можно попасть в лист ожидания на удобный слот.',
 22, 0, 30, 1, 1, '2026-09-01 10:00:00', 1, 1),

(2,
 'Как продлить абонемент?',
 'Напишите администратору или дождитесь напоминания о скором окончании абонемента.\nВ CRM обновляются задачи по клиентам, у кого заканчивается абонемент. При продаже выбирается безналичный расчёт, срок действия ставится на день последней тренировки по расписанию ученика.',
 45, 0, 40, 1, 1, '2026-09-01 10:00:00', 1, 1),

(2,
 'Где фиксируются заявки и продажи?',
 'Все новые лиды, записи и продажи фиксируются в чате администратора и CRM (Amo):\n• источник (Яндекс / 2ГИС / рекомендация / промоутер);\n• филиал;\n• график.\nВечером формируется отчёт: заявки, записи, пробные, сделки, выручка.',
 19, 0, 50, 1, 1, '2026-09-01 10:00:00', 1, 1),

(2,
 'Можно ли написать не в рабочее время?',
 'Да, сообщение сохранится в чате. Администратор обработает его в начале смены. Утром до 12:00 проверяется расписание и связь с пробниками предыдущего дня.',
 15, 0, 60, 1, 1, '2026-09-01 10:00:00', 1, 1),

(2,
 'Как связаться по конкретному филиалу?',
 'Укажите филиал в первом сообщении (Заряд, Восход, Максимум, Качаловский, Пегас) — так быстрее подберём слот. Контакты и адреса также есть в разделе «Контакты» на сайте.',
 26, 0, 70, 1, 1, '2026-09-01 10:00:00', 1, 1),

(2,
 'Кто подтверждает визиты и напоминания?',
 'Администратор: с 11:00 — подтверждение визитов, оформление пробников и напоминания; до 18:00 — напоминания новичкам на следующий день.',
 12, 0, 80, 1, 1, '2026-09-01 10:00:00', 1, 1),

-- === Расписание ===
(3,
 'В каких филиалах вы работаете?',
 'Swimming Moscow:\n1) Заряд — ул. Краснодонская, 1к1 (м. Текстильщики);\n2) Восход — Ореховый пр-д, 26;\n3) Максимум — Волгоградский пр-т, 46/15с4;\n4) Качаловский — ул. Каховка, 25;\n5) Пегас — ул. Верхние Поля, 27с1.\nАктуальное расписание — на сайте и у администратора.',
 100, 1, 10, 1, 1, '2026-09-01 10:00:00', 1, 1),

(3,
 'Как часто лучше ходить на тренировки?',
 'Оптимально 2–3 раза в неделю для прогресса. Доступны абонементы на 1 / 2 / 3 раза в неделю и пакеты на 12 / 24 / 36 занятий. Конкретный график согласуется после пробного занятия.',
 48, 0, 20, 1, 1, '2026-09-01 10:00:00', 1, 1),

(3,
 'Можно ли перенести занятие?',
 'Перенос возможен при своевременном сообщении администратору. Правила переносов зависят от типа абонемента/пакета — уточняйте при оформлении. Без уведомления занятие может быть списано.',
 36, 0, 30, 1, 1, '2026-09-01 10:00:00', 1, 1),

(3,
 'Есть ли занятия в выходные?',
 'Да, в субботу и воскресенье проходят групповые и пробные слоты (зависит от филиала). Смотрите раздел «Расписание» или уточните у администратора свободные места.',
 41, 0, 40, 1, 1, '2026-09-01 10:00:00', 1, 1),

(3,
 'Что такое лист ожидания?',
 'Если в нужной группе нет мест, администратор добавляет вас в лист ожидания и предлагает слот при освобождении или открытии нового набора (например, при запуске Пегаса).',
 17, 0, 50, 1, 1, '2026-09-01 10:00:00', 1, 1),

(3,
 'Как понять, что место в группе закреплено?',
 'Место закрепляется после оформления абонемента/пакета и внесения ученика в таблицу заполняемости по выбранному расписанию. Разовое занятие место не закрепляет.',
 29, 0, 60, 1, 1, '2026-09-01 10:00:00', 1, 1),

(3,
 'Где смотреть расписание на неделю?',
 'На сайте swimmingmoscow.ru в разделе расписания и у администратора в чате. Перед сменой администратор до 12:00 сверяет слоты и подтверждает визиты.',
 24, 0, 70, 1, 1, '2026-09-01 10:00:00', 1, 1),

(3,
 'Отличается ли расписание летом и в сезоне?',
 'Да, при наборе на новый сезон слоты и группы обновляются. Следите за новостями школы и объявлениями по филиалам.',
 14, 0, 80, 1, 1, '2026-09-01 10:00:00', 1, 1),

-- === Документы ===
(4,
 'Какие документы нужны для начала занятий?',
 'Обычно необходимы:\n• договор;\n• ознакомление с правилами абонемента;\n• справка / результат анализа на энтеробиоз (и иные мед. требования бассейна филиала).\nАдминистратор пришлёт чек-лист при оформлении.',
 66, 1, 10, 1, 1, '2026-09-01 10:00:00', 1, 1),

(4,
 'Как проходит оформление нового клиента?',
 'Последовательность:\n1) договор;\n2) правила абонемента (быстрые ответы);\n3) ссылка на оплату;\n4) внесение в таблицу заполняемости по расписанию;\n5) внесение в таблицу оплат (ФИ, график, сумма, дата оплаты).\nСсылки на оплату многоразовые и закреплены в WhatsApp / Telegram.',
 38, 1, 20, 1, 1, '2026-09-01 10:00:00', 1, 1),

(4,
 'Как оплатить занятия?',
 'Абонементы и пакеты — по безналичному расчёту (ссылка от администратора).\nОплаты персональных занятий проходят на карту Сбербанка Алексею (уточняйте актуальные реквизиты в чате).\nПосле оплаты данные вносятся в таблицу оплат.',
 52, 0, 30, 1, 1, '2026-09-01 10:00:00', 1, 1),

(4,
 'Какой сейчас прайс на обучение?',
 'Детская группа:\n• Пробная — 1 000 ₽\n• Абонемент 4 / 8 / 12 — 6 400 / 11 100 / 15 200 ₽\n• Разовое — 1 900 ₽\n• Пакет 12 / 24 / 36 — 17 850 / 30 400 / 41 600 ₽\n• Персональная — 5 000 ₽\n• Сплит (для двоих) — 7 000 ₽',
 90, 1, 40, 1, 1, '2026-09-01 10:00:00', 1, 1),

(4,
 'Нужна ли справка в каждый филиал?',
 'Требования бассейнов могут отличаться. Базово нужен результат анализа на энтеробиоз. Уточняйте актуальный список документов у администратора выбранного филиала перед первым визитом.',
 31, 0, 50, 1, 1, '2026-09-01 10:00:00', 1, 1),

(4,
 'Что считается сделкой в отчётности?',
 'Сделка — любая первая продажа в истории клиента: абонемент, пакет, разовое или персональное. Пробные занятия в сделки не включаются. В вечернем отчёте указываются количество и источник.',
 11, 0, 60, 1, 1, '2026-09-01 10:00:00', 1, 1),

(4,
 'Сколько действует абонемент?',
 'При продаже срок действия абонемента выставляется на день последней тренировки ученика по его расписанию. Детали — в правилах абонемента, которые выдаются при оформлении.',
 27, 0, 70, 1, 1, '2026-09-01 10:00:00', 1, 1),

(4,
 'Можно ли получить чек / подтверждение оплаты?',
 'Да. После оплаты администратор подтверждает поступление и вносит данные в таблицу оплат. При необходимости отправит подтверждение в чат.',
 16, 0, 80, 1, 1, '2026-09-01 10:00:00', 1, 1),

-- Черновик только для админки (не на сайте)
(4,
 'Внутренний черновик: вечерний отчёт администратора',
 'С 22:00 до 23:00: заявки, записи, пробные, сделки, выручка (план/факт) с указанием источника каждого показателя. План на месяц и день задаёт управляющий в начале месяца.',
 0, 0, 999, 0, 1, NULL, 1, 1);

-- -----------------------------------------------------------------------------
-- 4.11. Контакты
-- -----------------------------------------------------------------------------

INSERT INTO contacts (contact_type, label, value, branch_id, sort_order, is_primary, is_active) VALUES
('social',    'Instagram / сайт', 'https://swimmingmoscow.ru/', NULL, 10, 1, 1),
('messenger', 'Telegram',         'https://t.me/swimming_moscow', NULL, 20, 1, 1),
('messenger', 'WhatsApp',         'https://wa.me/79000000000', NULL, 30, 1, 1),
('address',   'Заряд',            'ул. Краснодонская, 1к1', 1, 40, 0, 1),
('address',   'Восход',           'Ореховый пр-д, 26', 2, 50, 0, 1),
('address',   'Максимум',         'Волгоградский пр-т, 46/15с4', 3, 60, 0, 1),
('address',   'Качаловский',      'ул. Каховка, 25', 4, 70, 0, 1),
('address',   'Пегас',            'ул. Верхние Поля, 27с1', 5, 80, 0, 1);

-- -----------------------------------------------------------------------------
-- 4.12. Тестовый пользователь сайта + заявка
-- -----------------------------------------------------------------------------

INSERT INTO users (id, email, phone, password_hash, role_id, is_verified, is_active)
VALUES (
  1,
  'parent@example.com',
  '+7 (900) 111-22-33',
  SHA2('parent123', 256),
  4,
  1,
  1
);

INSERT INTO user_profiles (
  user_id, first_name, last_name, preferred_branch_id,
  child_name, child_birth_date, is_active
) VALUES (
  1, 'Анна', 'Иванова', 4, 'Миша Иванов', '2018-05-12', 1
);

INSERT INTO feedback (
  user_id, name, phone, email, branch_id, subject, message, source, status, is_active
) VALUES (
  1, 'Анна Иванова', '+7 (900) 111-22-33', 'parent@example.com', 4,
  'Запись на пробное',
  'Здравствуйте! Хотим записаться на пробное в Качаловский, ребёнку 8 лет, удобнее будни после 17:00.',
  'site', 'new', 1
);

-- =============================================================================
-- 5. ПРЕДСТАВЛЕНИЯ (VIEW)
-- =============================================================================

-- FAQ для сайта: только активные категории и опубликованные вопросы
CREATE OR REPLACE VIEW v_faq_with_categories AS
SELECT
  f.id              AS faq_id,
  f.question,
  f.answer,
  f.views,
  f.is_pinned,
  f.sort_order      AS faq_sort,
  f.published_at,
  c.id              AS category_id,
  c.code            AS category_code,
  c.name            AS category_name,
  c.sort_order      AS category_sort
FROM faq_items f
INNER JOIN faq_categories c ON c.id = f.category_id
WHERE f.is_active = 1
  AND f.is_published = 1
  AND c.is_active = 1;

-- Активные пользователи сайта с профилем
CREATE OR REPLACE VIEW v_active_users AS
SELECT
  u.id AS user_id,
  u.email,
  u.phone,
  u.is_verified,
  u.last_login_at,
  u.created_at,
  p.first_name,
  p.last_name,
  p.child_name,
  b.name AS preferred_branch,
  r.code AS role_code
FROM users u
INNER JOIN roles r ON r.id = u.role_id
LEFT JOIN user_profiles p ON p.user_id = u.id AND p.is_active = 1
LEFT JOIN branches b ON b.id = p.preferred_branch_id
WHERE u.is_active = 1;

-- Опубликованные новости
CREATE OR REPLACE VIEW v_published_news AS
SELECT
  n.id,
  n.title,
  n.slug,
  n.summary,
  n.body,
  n.cover_url,
  n.published_at,
  n.views,
  a.full_name AS author_name
FROM news n
LEFT JOIN admin_users a ON a.id = n.author_admin_id
WHERE n.is_active = 1
  AND n.is_published = 1
  AND n.published_at IS NOT NULL
  AND n.published_at <= NOW();

-- Расписание на неделю с названиями
CREATE OR REPLACE VIEW v_week_schedule AS
SELECT
  s.id AS schedule_id,
  s.specific_date,
  s.week_start,
  s.weekday,
  s.start_time,
  s.end_time,
  s.seats_taken,
  l.capacity_max,
  (l.capacity_max - s.seats_taken) AS seats_free,
  l.title AS lesson_title,
  l.lesson_type,
  l.age_from,
  l.age_to,
  b.code AS branch_code,
  b.name AS branch_name,
  COALESCE(t.short_name, t2.short_name) AS teacher_name,
  s.is_cancelled,
  s.is_active
FROM schedule s
INNER JOIN lessons l ON l.id = s.lesson_id AND l.is_active = 1
INNER JOIN branches b ON b.id = l.branch_id AND b.is_active = 1
LEFT JOIN teachers t ON t.id = s.teacher_id
LEFT JOIN teachers t2 ON t2.id = l.teacher_id
WHERE s.is_active = 1;

-- Актуальный прайс для сайта
CREATE OR REPLACE VIEW v_active_prices AS
SELECT
  id, code, category, title, description,
  lessons_count, per_week, price_rub, is_featured, sort_order
FROM prices
WHERE is_active = 1
  AND (valid_from IS NULL OR valid_from <= CURDATE())
  AND (valid_to IS NULL OR valid_to >= CURDATE());

-- Занятия тренеров
CREATE OR REPLACE VIEW v_teacher_lessons AS
SELECT
  t.id AS teacher_id,
  t.full_name,
  t.short_name,
  l.id AS lesson_id,
  l.title AS lesson_title,
  l.lesson_type,
  b.name AS branch_name,
  s.weekday,
  s.start_time,
  s.end_time,
  s.specific_date
FROM teachers t
INNER JOIN lessons l ON l.teacher_id = t.id AND l.is_active = 1
INNER JOIN branches b ON b.id = l.branch_id
LEFT JOIN schedule s ON s.lesson_id = l.id AND s.is_active = 1
WHERE t.is_active = 1;

-- =============================================================================
-- 6. КРАТКИЕ ПРИМЕРЫ ЗАПРОСОВ (закомментированы)
-- =============================================================================
-- FAQ для сайта:
--   SELECT * FROM v_faq_with_categories ORDER BY category_sort, is_pinned DESC, faq_sort;
--
-- FAQ в админке (включая неопубликованные):
--   SELECT f.*, c.name AS category_name
--   FROM faq_items f
--   JOIN faq_categories c ON c.id = f.category_id
--   WHERE f.is_active = 1
--   ORDER BY c.sort_order, f.is_pinned DESC, f.sort_order;
--
-- Расписание текущей недели:
--   SELECT * FROM v_week_schedule
--   WHERE week_start = '2026-08-31' OR specific_date BETWEEN '2026-08-31' AND '2026-09-06'
--   ORDER BY specific_date, start_time;
--
-- Вход админа (проверка пароля SHA2):
--   SELECT id, login, full_name, is_super_admin
--   FROM admin_users
--   WHERE login = 'admin' AND password_hash = SHA2('admin123', 256) AND is_active = 1;
--
-- =============================================================================
-- Конец скрипта Swimming Moscow
-- =============================================================================
