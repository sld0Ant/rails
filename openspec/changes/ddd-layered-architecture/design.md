## Context

Rails 8.2 использует MVC-архитектуру, где ActiveRecord совмещает доменную модель с персистентностью, контроллеры содержат бизнес-логику и транспортную обработку, а Views генерируют HTML. Для API-приложений со сложной бизнес-логикой это создаёт связанность между слоями.

Фреймворк модифицируется на уровне: генераторов (railties), engine configuration, routing (actionpack), AR model generator (activerecord). Изменения затрагивают ~8 существующих файлов и добавляют ~20 новых.

## Goals / Non-Goals

**Goals:**
- Четырёхслойная DDD-архитектура: UI → Application → Domain → Infrastructure
- Repository-паттерн вместо прямого ActiveRecord в бизнес-логике
- Declarative Endpoints для CRUD (4 строки на ресурс) + Action Objects для кастомных операций
- API-only (JSON), без View-слоя
- `rails g scaffold` генерирует полный DDD-стек
- `rails new` создаёт DDD-структуру каталогов

**Non-Goals:**
- Обратная совместимость с существующими Rails-приложениями
- Value Objects, Aggregates, Domain Events, Bounded Contexts (другие DDD-паттерны)
- Поддержка HTML/View rendering
- Тесты для самих генераторов (unit tests генераторов)
- Переписывание ActiveRecord internals

## Decisions

### 1. Entity на ActiveModel::API + Attributes (не PORO с attr_accessor)

**Выбор:** `ApplicationEntity` включает `ActiveModel::API`, `ActiveModel::Attributes`, `ActiveModel::Serializers::JSON`.

**Альтернативы:**
- Чистый PORO с `attr_accessor` — нет type casting, нет validations API, нет `as_json`
- Наследование от `ActiveRecord::Base` с `self.abstract_class = true` — тянет за собой connection pool и SQL

**Обоснование:** ActiveModel даёт typed attributes, validations, `as_json`, `persisted?`, `to_key`, `to_param` без привязки к БД. Минимальный набор для работы с JSON API и routing.

### 2. Declarative Endpoint + Action Objects (не контроллеры, не Hanami-style)

**Выбор:** Гибрид — `ApplicationEndpoint` для CRUD (5 методов, конвенция), `ApplicationAction` для кастомных операций (1 класс = 1 действие, `handle(req, res)`).

**Альтернативы:**
- Rails-контроллеры (тонкие, с Service) — 30+ строк бойлерплейта на ресурс
- Hanami-style (7 отдельных action-классов) — 70+ строк, 7 файлов на CRUD
- Route-to-Service mapping — Service получает HTTP-ответственность, нарушение слоёв

**Обоснование:** Endpoint = 4 строки на CRUD (лучше Rails и Hanami), Action = SRP для кастомных (как Hanami, но без dry-rb). Из Hanami взят `handle(req, res)` контракт и Rack-native подход.

### 3. Repository с маппингом Record ↔ Entity (не Data Mapper/ROM)

**Выбор:** `ApplicationRepository` инкапсулирует AR-запросы, маппит Record в Entity через `to_entity`. AR-ошибки (`RecordInvalid`) ловятся и транслируются в `entity.errors`.

**Альтернативы:**
- ROM (Ruby Object Mapper) — внешняя зависимость, несовместим с AR migrations
- Прямой AR с декоратором — не изолирует домен от персистентности
- Data Mapper pattern (ручной) — слишком много кода для маппинга

**Обоснование:** AR остаётся для миграций и SQL-генерации, но скрыт за Repository. Entity — PORO, не знает о БД. Маппинг через `record.attributes.slice(*)` — минимальный и предсказуемый.

### 4. Routing DSL `endpoint` в mapper.rb (не отдельный middleware)

**Выбор:** Метод `endpoint(EndpointClass)` добавляется в `ActionDispatch::Routing::Mapper`. Генерирует 5 маршрутов, каждый вызывает метод Endpoint через Rack-lambda.

**Альтернативы:**
- Rack middleware перед Router — перехватывает все запросы, overhead
- Mount endpoint как Rack app целиком — теряется интеграция с Rails URL helpers
- DSL в отдельном файле (не routes.rb) — нестандартно, сложнее discover

**Обоснование:** Интеграция в mapper.rb позволяет использовать `scope`, `namespace`, стандартные Rails route helpers рядом с endpoints.

### 5. Record с суффиксом `Record`, Entity без суффикса

**Выбор:** `Post` (entity, domain), `PostRecord` (AR, infrastructure). Таблица = `posts` (через `self.table_name`). Миграция генерирует `create_posts` (чистое имя).

**Альтернативы:**
- Оба без суффикса (конфликт имён) — невозможно
- Entity с суффиксом (`PostEntity`) — загрязняет доменный код
- Namespace (`Domain::Post`, `Infrastructure::PostRecord`) — усложняет autoloading

**Обоснование:** Доменный код оперирует чистыми именами (`Post`, `User`). AR Record — деталь реализации, суффикс `Record` подчёркивает это.

## Risks / Trade-offs

- **[Ecosystem gems]** Gems (devise, pundit) ожидают `app/models/` и AR-модели → Необходима отдельная стратегия интеграции (не в скоупе этого изменения)
- **[`all` без пагинации]** `Repository#all` загружает всю таблицу → Допустимо для scaffold boilerplate, разработчик добавляет пагинацию
- **[Service pass-through]** Scaffold Service — анемичный CRUD делегатор → Это scaffolding boilerplate, бизнес-логика добавляется разработчиком
- **[Endpoint params]** `params[resource_name].slice(*)` вместо strong params → Упрощение для API-only, в production может потребоваться усиление
- **[Rack response tuple]** Endpoint возвращает `[status, headers, body]` напрямую → Обходит Rails middleware stack частично, нужно убедиться что logging/error handling работают
