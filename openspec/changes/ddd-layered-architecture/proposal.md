## Why

Rails MVC смешивает доменную логику с персистентностью (ActiveRecord) и транспортом (Controller+Views). Это препятствует гибкой архитектуре для сложных приложений. Переход на четырёхслойную DDD-архитектуру (Eric Evans, Blue Book) с чётким разделением UI → Application → Domain → Infrastructure позволяет изолировать бизнес-логику от инфраструктуры, заменить ActiveRecord-модели на Repository-паттерн и убрать View-слой в пользу API-only JSON.

## What Changes

- **BREAKING**: `app/models/` заменяется на `app/entities/` (PORO доменные сущности с ActiveModel) + `app/records/` (ActiveRecord, чистая персистентность)
- **BREAKING**: `app/controllers/` заменяется на `app/endpoints/` (declarative CRUD) + `app/actions/` (custom action objects à la Hanami)
- **BREAKING**: `app/views/` и `app/helpers/` убираются полностью (API-only, JSON)
- Новый слой `app/services/` — Application Services для оркестрации бизнес-логики
- Новый слой `app/repositories/` — Repository-паттерн, маппинг Record ↔ Entity
- Новый routing DSL: `endpoint PostsEndpoint` в routes.rb (генерирует 5 RESTful маршрутов)
- Action Objects монтируются в routes как Rack-apps для кастомных операций
- Генераторы: `rails g entity`, `rails g repository`, `rails g service`, `rails g endpoint`, `rails g action`
- Scaffold генерирует полный DDD-стек: Entity + Record + Repository + Service + Endpoint + Migration

## Capabilities

### New Capabilities
- `domain-entities`: PORO-сущности на ActiveModel::API + Attributes, отделённые от персистентности
- `repository-pattern`: Инкапсуляция AR за Repository с маппингом Record ↔ Entity и обработкой ошибок
- `application-services`: Слой оркестрации между UI и Domain/Infrastructure
- `declarative-endpoints`: CRUD-endpoint в 4 строки, автоматическая генерация JSON API
- `action-objects`: Single-action классы для кастомных операций (handle(req, res))
- `endpoint-routing`: DSL `endpoint` в routes.rb для маршрутизации к Endpoint-классам
- `ddd-generators`: Генераторы entity/repository/service/endpoint/action + scaffold интеграция
- `ddd-app-structure`: Модификация `rails new` для генерации DDD-каталогов вместо MVC

### Modified Capabilities

## Impact

- **Rails core**: actionpack (routing mapper), railties (generators, engine config), activerecord (model generator)
- **Scaffold**: полностью переписан для DDD-стека
- **`rails new`**: генерирует DDD-структуру вместо MVC
- **Обратная совместимость**: отсутствует — это фундаментальная перестройка архитектуры фреймворка
