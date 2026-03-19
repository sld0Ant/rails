# DDD Layered Architecture для Rails

## Tech Stack

- Ruby on Rails 8.2.0.alpha (исходники фреймворка)
- ActiveModel (API, Attributes, Validations, Serializers::JSON) — основа для PORO-сущностей
- ActiveRecord — деталь реализации в Infrastructure-слое, скрыт за Repository
- ActionPack (Metal, StrongParameters, Rendering) — ядро для Endpoint/Action
- Генераторы Rails (Thor) — модифицируются для DDD-структуры

## Architecture & Patterns

**Четырёхслойная архитектура (Eric Evans, Blue Book), API-only (без View-слоя):**

```
UI Layer              → app/endpoints/, app/actions/
Application Layer     → app/services/
Domain Layer          → app/entities/
Infrastructure Layer  → app/repositories/, app/records/
```

**Убираемые слои из стандартного Rails MVC:**
- `app/models/` → заменяется на `app/entities/` + `app/records/`
- `app/controllers/` → заменяется на `app/endpoints/` + `app/actions/`
- `app/views/` → убирается полностью (API-only, JSON)
- `app/helpers/` → убирается (нет views)

### UI Layer: Endpoint + Action (гибрид, вдохновлён Hanami)

Два паттерна для UI-слоя:

**1. Declarative Endpoint** — для стандартного CRUD (1 файл, ~4 строки):
```ruby
class PostsEndpoint < ApplicationEndpoint
  resource :post,
    service: PostService,
    permit: [:title, :body]
end
```

Базовый класс `ApplicationEndpoint` автоматически генерирует 5 CRUD-действий
(index, show, create, update, destroy), каждое из которых:
- извлекает params (на основе `permit`)
- вызывает соответствующий метод Service
- возвращает JSON с правильным HTTP-статусом

**2. Action Objects** — для кастомных/сложных действий (1 файл на action):
```ruby
module Posts
  class Publish < ApplicationAction
    def handle(req, res)
      post = PostService.new.publish(req.params[:id])
      res.json(post, status: 200)
    end
  end
end
```

Каждый Action — отдельный класс с единственным методом `handle(req, res)`.
Явный контракт request/response (вдохновлён Hanami `def handle(req, res)`).
Подходит для нестандартных действий: publish, archive, approve, bulk operations.

### Что взято из Hanami (обосновано анализом исходников)

- **`def handle(req, res)`** — явный контракт, нет implicit render magic
- **1 action = 1 class** — SRP для кастомных действий
- **Rack-native** — каждый endpoint/action = callable `#call(env)`

### Что НЕ взято из Hanami (обосновано анализом исходников)

- **7 файлов на CRUD-ресурс** — заменяем 1 Declarative Endpoint (4 строки)
- **Строковые container-ключи** (`"actions.posts.index"`) — используем прямые классы
- **dry-rb зависимости** (dry-container, dry-configurable, dry-validation) — остаёмся на ActiveModel/ActiveSupport
- **Отсутствие scaffold** — наш генератор создаёт всё автоматически

### Сравнение файлов на ресурс Post (CRUD + 1 кастомный action)

| Подход | Файлов | Строк кода |
|--------|--------|------------|
| Rails MVC (текущий) | 1 controller + 5 views | ~120 |
| Hanami 2.x | 6 action-классов | ~70 |
| **Наш DDD Endpoint+Action** | **1 endpoint + 1 action** | **~14** |

## Базовые классы

### ApplicationEndpoint

```ruby
class ApplicationEndpoint
  class_attribute :resource_name
  class_attribute :service_class
  class_attribute :permitted_params

  class << self
    def resource(name, service:, permit: [])
      self.resource_name = name
      self.service_class = service
      self.permitted_params = permit
    end
  end

  def service = @service ||= self.class.service_class.new

  def index(params)
    entities = service.list_all
    [200, json_headers, [entities.map(&:as_json).to_json]]
  end

  def show(params)
    entity = service.find(params[:id])
    [200, json_headers, [entity.as_json.to_json]]
  end

  def create(params)
    permitted = params[resource_name]&.slice(*permitted_params) || {}
    entity = service.create(permitted)
    if entity.errors.empty?
      [201, json_headers, [entity.as_json.to_json]]
    else
      [422, json_headers, [{ errors: entity.errors.as_json }.to_json]]
    end
  end

  def update(params)
    permitted = params[resource_name]&.slice(*permitted_params) || {}
    entity = service.update(params[:id], permitted)
    if entity.errors.empty?
      [200, json_headers, [entity.as_json.to_json]]
    else
      [422, json_headers, [{ errors: entity.errors.as_json }.to_json]]
    end
  end

  def destroy(params)
    service.destroy(params[:id])
    [204, {}, []]
  end

  private

  def json_headers = { "content-type" => "application/json" }
  def resource_name = self.class.resource_name
  def permitted_params = self.class.permitted_params
end
```

### ApplicationAction

```ruby
class ApplicationAction
  def call(env)
    req = ActionDispatch::Request.new(env)
    res = ActionDispatch::Response.new
    handle(req, res)
    res.to_a
  end

  private

  def handle(req, res)
    raise NotImplementedError
  end
end
```

### ApplicationEntity

```ruby
class ApplicationEntity
  include ActiveModel::API
  include ActiveModel::Attributes
  include ActiveModel::Serializers::JSON

  def persisted? = id.present?
end
```

### ApplicationRepository

```ruby
class ApplicationRepository
  class_attribute :record_class
  class_attribute :entity_class

  def all = record_class.all.map { |r| to_entity(r) }
  def find(id) = to_entity(record_class.find(id))

  def create(attributes)
    entity = entity_class.new(**attributes)
    return entity unless entity.valid?

    record = record_class.create!(attributes)
    to_entity(record)
  rescue ActiveRecord::RecordInvalid => e
    map_record_errors(entity, e.record)
    entity
  end

  def update(id, attributes)
    entity = entity_class.new(id: id, **attributes)
    return entity unless entity.valid?

    record = record_class.find(id)
    record.update!(attributes)
    to_entity(record)
  rescue ActiveRecord::RecordInvalid => e
    map_record_errors(entity, e.record)
    entity
  end

  def destroy(id) = record_class.find(id).destroy!

  private

  def to_entity(record)
    attrs = record.attributes.symbolize_keys.slice(*entity_class.attribute_names.map(&:to_sym))
    entity_class.new(**attrs)
  end

  def map_record_errors(entity, record)
    record.errors.each { |error| entity.errors.add(error.attribute, error.type, message: error.message) }
  end
end
```

### ApplicationService

```ruby
class ApplicationService
  private

  def repository = raise NotImplementedError
end
```

## Data Flow

```
HTTP Request
  → Endpoint/Action (UI): парсит params, вызывает Service
    → Service (Application): оркестрация, вызывает Repository
      → Repository (Infrastructure): CRUD через AR Record, маппит в Entity
        → Record (Infrastructure): ActiveRecord, чистая персистентность
        → Entity (Domain): PORO, валидации, бизнес-атрибуты
      ← Repository возвращает Entity
    ← Service возвращает Entity
  ← Endpoint/Action возвращает JSON response с HTTP-статусом
```

## Scaffold пример: `rails g scaffold Post title:string body:text`

Генерирует:

```ruby
# app/entities/post.rb — Domain Layer
class Post < ApplicationEntity
  attribute :id, :integer
  attribute :title, :string
  attribute :body, :string
  attribute :created_at, :datetime
  attribute :updated_at, :datetime

  validates :title, presence: true
end

# app/records/post_record.rb — Infrastructure Layer
class PostRecord < ApplicationRecord
  self.table_name = "posts"
end

# app/repositories/post_repository.rb — Infrastructure Layer
class PostRepository < ApplicationRepository
  self.record_class = PostRecord
  self.entity_class = Post
end

# app/services/post_service.rb — Application Layer
class PostService < ApplicationService
  def list_all          = repository.all
  def find(id)          = repository.find(id)
  def create(attributes) = repository.create(attributes)
  def update(id, attributes) = repository.update(id, attributes)
  def destroy(id)       = repository.destroy(id)

  private

  def repository = @repository ||= PostRepository.new
end

# app/endpoints/posts_endpoint.rb — UI Layer
class PostsEndpoint < ApplicationEndpoint
  resource :post,
    service: PostService,
    permit: [:title, :body]
end

# db/migrate/xxx_create_posts.rb — Infrastructure Layer (миграция, как в стандартном Rails)
```

Routes:
```ruby
# config/routes.rb
Rails.application.routes.draw do
  endpoint PostsEndpoint
end
```

Добавление кастомного action (вручную, не scaffold):
```ruby
# app/actions/posts/publish.rb
module Posts
  class Publish < ApplicationAction
    def handle(req, res)
      post = PostService.new.publish(req.params[:id])
      res.status = 200
      res.content_type = "application/json"
      res.body = [post.as_json.to_json]
    end
  end
end

# config/routes.rb — добавить:
post "/posts/:id/publish", to: Posts::Publish
```

## Project Structure

### Новые файлы

```
# Базовые шаблоны app
railties/lib/rails/generators/rails/app/templates/app/endpoints/application_endpoint.rb.tt
railties/lib/rails/generators/rails/app/templates/app/actions/application_action.rb.tt
railties/lib/rails/generators/rails/app/templates/app/entities/application_entity.rb.tt
railties/lib/rails/generators/rails/app/templates/app/services/application_service.rb.tt
railties/lib/rails/generators/rails/app/templates/app/repositories/application_repository.rb.tt
railties/lib/rails/generators/rails/app/templates/app/records/application_record.rb.tt

# Генератор Entity
railties/lib/rails/generators/rails/entity/entity_generator.rb
railties/lib/rails/generators/rails/entity/templates/entity.rb.tt
railties/lib/rails/generators/rails/entity/USAGE

# Генератор Repository
railties/lib/rails/generators/rails/repository/repository_generator.rb
railties/lib/rails/generators/rails/repository/templates/repository.rb.tt
railties/lib/rails/generators/rails/repository/USAGE

# Генератор Service
railties/lib/rails/generators/rails/service/service_generator.rb
railties/lib/rails/generators/rails/service/templates/service.rb.tt
railties/lib/rails/generators/rails/service/USAGE

# Генератор Endpoint
railties/lib/rails/generators/rails/endpoint/endpoint_generator.rb
railties/lib/rails/generators/rails/endpoint/templates/endpoint.rb.tt
railties/lib/rails/generators/rails/endpoint/USAGE

# Генератор Action
railties/lib/rails/generators/rails/action/action_generator.rb
railties/lib/rails/generators/rails/action/templates/action.rb.tt
railties/lib/rails/generators/rails/action/USAGE

# Routing DSL для endpoint
actionpack/lib/action_dispatch/routing/mapper/endpoint_resources.rb
```

### Модифицируемые файлы

```
railties/lib/rails/generators/rails/app/app_generator.rb
railties/lib/rails/engine/configuration.rb
railties/lib/rails/generators/rails/resource/resource_generator.rb
railties/lib/rails/generators/rails/scaffold/scaffold_generator.rb
railties/lib/rails/generators/test_unit/scaffold/templates/api_functional_test.rb.tt
activerecord/lib/rails/generators/active_record/model/model_generator.rb
activerecord/lib/rails/generators/active_record/model/templates/model.rb.tt
actionpack/lib/action_dispatch/routing/mapper.rb
```

### Удаляемые файлы/каталоги (из шаблонов генератора приложения)

```
railties/lib/rails/generators/rails/app/templates/app/models/application_record.rb.tt
railties/lib/rails/generators/rails/app/templates/app/controllers/application_controller.rb.tt
railties/lib/rails/generators/rails/app/templates/app/helpers/application_helper.rb.tt
railties/lib/rails/generators/rails/app/templates/app/views/
railties/lib/rails/generators/rails/scaffold_controller/  (заменяется endpoint generator)
railties/lib/rails/generators/erb/scaffold/  (views убраны)
```

## Implementation Order

1. **Базовые шаблоны** — application_endpoint.rb.tt, application_action.rb.tt, application_entity.rb.tt, application_repository.rb.tt, application_service.rb.tt, application_record.rb.tt (в records/)
2. **Engine Configuration** — configuration.rb: заменить app/models на app/entities + app/records; добавить app/endpoints, app/actions, app/repositories, app/services; убрать app/controllers, app/helpers, app/views из paths
3. **App Generator** — app_generator.rb: DDD-каталоги в AppBuilder#app, убрать models/controllers/views/helpers, добавить endpoints/actions/entities/repositories/services/records
4. **Routing DSL** — endpoint_resources.rb + модификация mapper.rb: метод `endpoint PostsEndpoint` в routes.rb, который генерирует 5 RESTful маршрутов, связанных с методами Endpoint
5. **AR Model Generator** — model_generator.rb: файл в app/records/#{file_name}_record.rb, self.table_name, правильное имя таблицы в миграции
6. **Entity Generator** — rails g entity Post title:string body:text → app/entities/post.rb
7. **Repository Generator** — rails g repository Post → app/repositories/post_repository.rb
8. **Service Generator** — rails g service Post → app/services/post_service.rb
9. **Endpoint Generator** — rails g endpoint Posts → app/endpoints/posts_endpoint.rb
10. **Action Generator** — rails g action Posts::Publish → app/actions/posts/publish.rb
11. **Resource Generator** — переделать: hooks для entity + record + repository + service + endpoint (вместо controller + model)
12. **Scaffold Generator** — связать все генераторы вместе
13. **Scaffold Test Templates** — api_functional_test.rb.tt для endpoint-based тестов

## Routing DSL

Метод `endpoint` в routes.rb генерирует маршруты из Endpoint-класса:

```ruby
# config/routes.rb
Rails.application.routes.draw do
  endpoint PostsEndpoint
  # Эквивалентно:
  # GET    /posts     → PostsEndpoint#index
  # GET    /posts/:id → PostsEndpoint#show
  # POST   /posts     → PostsEndpoint#create
  # PATCH  /posts/:id → PostsEndpoint#update
  # DELETE /posts/:id → PostsEndpoint#destroy

  # Кастомные actions монтируются напрямую как Rack-apps:
  post "/posts/:id/publish", to: Posts::Publish
end
```

`endpoint` метод внутри mapper.rb:
```ruby
def endpoint(endpoint_class, only: nil, except: nil, path: nil)
  resource_name = endpoint_class.resource_name
  path ||= resource_name.to_s.pluralize

  actions = %i[index show create update destroy]
  actions = actions & Array(only) if only
  actions -= Array(except) if except

  scope path do
    get    "/",    to: endpoint_dispatch(endpoint_class, :index)   if actions.include?(:index)
    get    "/:id", to: endpoint_dispatch(endpoint_class, :show)    if actions.include?(:show)
    post   "/",    to: endpoint_dispatch(endpoint_class, :create)  if actions.include?(:create)
    patch  "/:id", to: endpoint_dispatch(endpoint_class, :update)  if actions.include?(:update)
    delete "/:id", to: endpoint_dispatch(endpoint_class, :destroy) if actions.include?(:destroy)
  end
end
```

`endpoint_dispatch` создаёт Rack-callable lambda:
```ruby
def endpoint_dispatch(endpoint_class, action)
  ->(env) {
    params = env["router.params"]&.merge(
      ActionDispatch::Request.new(env).request_parameters
    ) || {}
    params = params.with_indifferent_access
    endpoint_class.new.public_send(action, params)
  }
end
```

## Assumptions

- API-only: View-слой полностью убран, все ответы — JSON
- Entity = `Post`, Record = `PostRecord`, таблица = `posts`
- Endpoint обрабатывает стандартный CRUD (5 действий), Action — кастомные операции
- Action Objects монтируются в routes как Rack-apps (отвечают на `#call(env)`)
- `class_attribute` (ActiveSupport) для thread-safe класс-атрибутов
- Strong params заменены на `permit` в декларации Endpoint
- Scaffold генерирует Endpoint, не Controller; views не генерируются
- Generator tests не входят в скоуп (фокус на реализации)
- `app/controllers/` больше не генерируется при `rails new`
