# DDD Rails — LLM Guide

You are building an API using DDD Rails, a Domain-Driven Design fork of Ruby on Rails.
Your job: turn the user's domain description into a working API with business logic.

## The Flow

```
User's words → Behavioral Spec → IR (ir.json) → Generated skeleton → Business logic
     1               2               3                 4                    5
```

You always go in this order. Never skip to code. Never generate IR without a spec first.

---

## Step 1 — Understand the Domain

Ask the user what they're building. You need to extract:
- What are the main things (nouns) in the system? → resources
- What happens to them (verbs)? → operations, transitions
- What rules exist? → constraints, policies
- Who does what? → roles, authorization

Don't ask all at once. Start with "What are you building?" and drill down.

## Step 2 — Write Behavioral Spec

For each resource, write `docs/behavior/<resource>.md`.
Use 5 sections. Skip sections that don't apply.

### Section format:

```markdown
# <Resource> — Behavioral Spec

## Contracts

Entity invariants and operation pre/postconditions.
Write ONLY rules that aren't obvious from the data types.

  invariant: <what must always be true>
  pre:  <what must be true before the operation>
  post: <what is guaranteed after the operation>

Example:
  invariant: rating in 1..5
  invariant: amount_cents > 0
  invariant: email matches URI::MailTo::EMAIL_REGEXP

  # EnrollStudent
  pre:  course.status == "published"
  pre:  student not already enrolled in course
  post: enrollment exists with status "active"
  post: course.enrollments_count incremented by 1

## Authorization

Decision table. Columns = roles, rows = actions.
Mark: ✓ (yes), ✗ (no), or a condition.

| Action   | admin | author    | member       | guest |
|----------|-------|-----------|--------------|-------|
| create   | ✓     | ✓         | ✗            | ✗     |
| show     | ✓     | own       | published    | ✗     |
| update   | ✓     | own       | ✗            | ✗     |
| destroy  | ✓     | own+draft | ✗            | ✗     |
| publish  | ✓     | own       | ✗            | ✗     |

## Lifecycle

Only for resources with a status/state field.
Draw transitions and their guards.

  [draft] --publish--> [published] --archive--> [archived]

  publish: draft → published, guard: has at least 1 lesson
  archive: draft|published → archived, no guard

## Scenarios

Concrete examples. Focus on non-obvious behavior, edge cases, error paths.
Don't write scenarios for plain CRUD — the framework handles that.

  Given published course with max_students: 2 and 2 enrollments
  When student calls POST /courses/:id/enroll
  Then 422, errors: ["Course is full"]

  Given course in status "archived"
  When author calls PATCH /courses/:id with {title: "New"}
  Then 403 (archived courses are immutable)

## Side Effects

What happens beyond the direct response.

  @on(publish):  notify wishlisted students
  @on(enroll):   send welcome email
  @on(enroll):   increment course.enrollments_count
  @on(payment.confirm): activate enrollment
```

### When to skip sections:

- **No Contracts**: resource has no invariants beyond NOT NULL (handled by DB)
- **No Authorization**: all actions are public or auth is global middleware
- **No Lifecycle**: resource has no status/state field
- **No Scenarios**: resource is pure CRUD with no edge cases
- **No Side Effects**: operations have no consequences beyond the direct write

Simple resources (Tag, Category) might have NO behavior spec at all. That's fine.

## Step 3 — Derive IR from Spec

Read all behavior specs and produce `docs/ir.json`.

### IR structure:

```json
{
  "$schema": "ddd-ir/1.1",
  "resources": [
    {
      "name": "Course",
      "plural": "courses",
      "path": "/courses",
      "attributes": {
        "id":         { "type": "integer",  "nullable": false, "readonly": true },
        "title":      { "type": "string",   "nullable": false, "readonly": false },
        "status":     { "type": "string",   "nullable": false, "readonly": false },
        "created_at": { "type": "datetime", "nullable": false, "readonly": true },
        "updated_at": { "type": "datetime", "nullable": false, "readonly": true }
      },
      "permit": ["title", "status"],
      "operations": [
        { "action": "index",   "method": "GET",    "path": "/courses" },
        { "action": "show",    "method": "GET",    "path": "/courses/{id}" },
        { "action": "create",  "method": "POST",   "path": "/courses" },
        { "action": "update",  "method": "PATCH",  "path": "/courses/{id}" },
        { "action": "destroy", "method": "DELETE",  "path": "/courses/{id}" }
      ],
      "validators": [
        { "type": "presence", "fields": ["title"] }
      ],
      "relations": {
        "instructor": { "kind": "belongs_to", "resource": "Instructor", "required": true }
      },
      "collection": {
        "sort": ["title", "created_at"],
        "filter": ["status", "instructor_id"],
        "search": ["title"],
        "per_page": 20
      }
    }
  ]
}
```

### How spec maps to IR:

| Spec section         | IR field it informs                          |
|----------------------|----------------------------------------------|
| Contracts invariants | `validators`, `nullable`, attribute types     |
| Authorization table  | which `operations` exist (no destroy = omit)  |
| Lifecycle states     | `status` attribute + transitions in code      |
| Scenarios            | nothing in IR (drives step 5)                 |
| Side effects         | nothing in IR (drives step 5)                 |

### Rules:

- `id`, `created_at`, `updated_at` — always present, always `readonly: true`
- Foreign keys (`*_id`) come from `relations`, not from attributes manually
- `permit` = all non-readonly, non-id attributes
- `nullable: false` when spec has `invariant: X is present` or NOT NULL
- Type vocabulary: `integer string text float decimal boolean date datetime time`
- Topological order: if B belongs_to A, A must come before B (the generator handles this, but keep it clean)

## Step 4 — Generate

### 4a. Environment setup

DDD Rails is a local fork. Every shell session needs:

```bash
export GEM_HOME="$HOME/.local/share/gem/ruby/3.4.0"
export BUNDLE_PATH="$GEM_HOME"
export PATH="$GEM_HOME/bin:$PATH"
```

Framework source lives at: `~/Projects/rb-ru`

### 4b. Create new app

```bash
cd ~/Projects/rb-ru
ruby railties/exe/rails new /path/to/myapp --api --dev
```

`--dev` makes Gemfile point to the local fork (`gem "rails", path: "~/Projects/rb-ru"`).
`--api` skips views, assets, browser middleware.

The generator creates the DDD directory structure automatically:
```
app/
├── actions/       + application_action.rb (empty, for custom ops)
├── endpoints/     + application_endpoint.rb (153 lines — CRUD, collection, HATEOAS, cache, auth)
├── entities/      + application_entity.rb (42 lines — ActiveModel, transitions, aggregates)
├── records/       + application_record.rb (standard ActiveRecord)
├── repositories/  + application_repository.rb (paginate, CRUD, entity mapping)
└── services/      + application_service.rb (perform_transition helper)
```

### 4c. Generate from IR

```bash
cd /path/to/myapp

# Place your ir.json
mkdir -p docs
# (write docs/ir.json — see Step 3)

# Generate all resources
bundle exec bin/rails generate from_ir docs/ir.json

# Run migrations
bundle exec bin/rails db:migrate
```

Per resource this creates 6 files:
```
app/entities/course.rb
app/records/course_record.rb
app/repositories/course_repository.rb
app/services/course_service.rb
app/endpoints/courses_endpoint.rb
db/migrate/XXXXXX_create_courses.rb
```

### 4d. Wire routes

Edit `config/routes.rb`:
```ruby
Rails.application.routes.draw do
  endpoint CoursesEndpoint
  endpoint EnrollmentsEndpoint
  # one line per resource
end
```

`endpoint` is a routing DSL macro. It maps all CRUD operations automatically.
Options: `only:`, `except:`, `path:` for filtering/customizing.

### 4e. Verify

```bash
bundle exec bin/rails server
curl http://localhost:3000/courses | jq
```

At this point: working CRUD API with collection (pagination, sort, filter, search),
HATEOAS `_links`, error handling (404/422 JSON), and Cache-Control headers.
No business logic yet.

## Step 5 — Add Business Logic from Spec

The generator produced a working CRUD skeleton. Now you add three types
of domain logic, each in its own layer:

- **Entity** ← invariants (what is ALWAYS true)
- **Entity** ← state machine declaration (which transitions exist)
- **Service** ← transition guards (preconditions for state changes)
- **Service** ← domain operations (enrollment, review, payment logic)

You do NOT touch Endpoint or Repository for business logic.

### 5a. Entity — invariants and state machine

Invariants from the Contracts section go directly to validations.
Lifecycle from the Lifecycle section goes to `transitions`.

```ruby
class Course < ApplicationEntity
  attribute :id, :integer
  attribute :title, :string
  attribute :status, :string
  # ... other generated attributes stay

  # Invariants → validations
  validates :title, presence: true
  validates :price_cents, numericality: { greater_than_or_equal_to: 0 }
  validates :status, inclusion: { in: %w[draft published archived] }

  # Lifecycle → transitions DSL
  # `from:` accepts a single value or an array
  transitions :status,
    publish: { from: "draft", to: "published" },
    archive: { from: ["draft", "published"], to: "archived" }
end
```

For email validation use `URI::MailTo::EMAIL_REGEXP`:
```ruby
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP }
```

### 5b. Service — transition guards

Transition guards are preconditions from the behavioral spec.
Override `guard_transition` in your service — it receives the loaded
entity and the transition name. Add errors to block the transition:

```ruby
class CourseService < ApplicationService
  # ... generated CRUD methods stay untouched

  private

  def repository = @repository ||= CourseRepository.new

  def guard_transition(entity, transition_name)
    case transition_name.to_sym
    when :publish
      if LessonRecord.where(course_id: entity.id).count < 1
        entity.errors.add(:base, "At least one lesson required")
      end
    end
  end
end
```

How the full transition flow works (you don't implement this — it's built in):
```
POST /courses/:id/publish
  → endpoint.transition(params, :publish)        # auto-routed
    → service.perform_transition(id, :publish)    # public API
      → entity = repository.find(id)             # load full entity
      → guard_transition(entity, :publish)        # YOUR guards
      → entity.transition!(:publish)              # state machine
      → repository.update(id, {status: "..."})    # persist
```

**You do NOT need to:**
- Add methods like `def publish` or `def archive` to the endpoint
- Add manual routes for transitions
- Override `perform_transition` (unless you need post-transition side effects)

The `endpoint` DSL in routes.rb reads `transitions_config` from the Entity
and automatically creates `POST /<plural>/:id/<transition_name>` routes.

### 5c. Service — domain operations with preconditions

For non-CRUD operations (enrollment, review creation with business rules),
override the CRUD method and add guards before calling repository:

```ruby
class EnrollmentService < ApplicationService
  def create(attributes)
    course = CourseRepository.new.find(attributes[:course_id])
    enrollment = Enrollment.new(**attributes)

    unless course.status == "published"
      enrollment.errors.add(:base, "Course is not published")
      return enrollment
    end

    if EnrollmentRecord.exists?(course_id: attributes[:course_id], student_id: attributes[:student_id])
      enrollment.errors.add(:base, "Already enrolled")
      return enrollment
    end

    if course.max_students && EnrollmentRecord.where(course_id: attributes[:course_id]).count >= course.max_students
      enrollment.errors.add(:base, "Course is full")
      return enrollment
    end

    result = repository.create(attributes.merge(status: "active"))
    return result if result.errors.any?

    # Side effects (from @on tags in spec)
    CourseRecord.where(id: result.course_id)
      .update_all("enrollments_count = COALESCE(enrollments_count, 0) + 1")

    result
  end

  private

  def repository = @repository ||= EnrollmentRepository.new
end
```

### 5d. Service — post-transition side effects

If a transition has side effects (from the `@on` tags in spec), override
`perform_transition` and call `super`:

```ruby
class PaymentService < ApplicationService
  def perform_transition(id, transition_name)
    entity = super
    return entity if entity.errors.any?

    case transition_name.to_sym
    when :confirm
      EnrollmentRecord.where(id: entity.enrollment_id).update_all(status: "active")
    when :refund
      EnrollmentRecord.where(id: entity.enrollment_id).update_all(status: "cancelled")
    end

    entity
  end

  private

  def repository = @repository ||= PaymentRepository.new

  def guard_transition(entity, transition_name)
    # no extra guards for payment — state machine is enough
  end
end
```

### 5e. Authorization — two levels

Authorization in the spec decision table maps to two places:

**Level 1 — Gate (endpoint).** Which roles can attempt this action at all?
Simple `✓`/`✗` entries from the table. Checked before loading the resource.

```ruby
class CoursesEndpoint < ApplicationEndpoint
  resource :course,
    service: CourseService,
    permit: [:title, :description, :instructor_id],
    authorize: {
      create:  [:admin, :instructor],
      update:  [:admin, :instructor],
      destroy: [:admin, :instructor],
      publish: [:admin, :instructor],
      archive: [:admin, :instructor]
    }
    # ... sort, filter, relations stay as generated
end
```

Role is read from `X-User-Role` header. `["*"]` means public.
Transitions (publish, archive) are checked by name — same config.

**Level 2 — Domain (service).** Can THIS user do THIS to THIS resource?
Entries like `own`, `own+draft`, `published only`. Checked after loading.

```ruby
class CourseService < ApplicationService
  def update(id, attributes)
    course = repository.find(id)

    # Spec: "instructor: own" → instructor can update only own courses
    if Thread.current[:user_role] == "instructor" &&
       course.instructor_id != Thread.current[:user_id]
      course.errors.add(:base, "Forbidden")
      return course
    end

    repository.update(id, attributes)
  end

  def destroy(id)
    course = repository.find(id)

    # Spec: "instructor: own+draft" → only own draft courses
    if Thread.current[:user_role] == "instructor"
      if course.instructor_id != Thread.current[:user_id]
        course.errors.add(:base, "Forbidden")
        return course
      end
      if course.status != "draft"
        course.errors.add(:base, "Can only delete draft courses")
        return course
      end
    end

    repository.destroy(id)
  end

  # ...
end
```

How to read the decision table:

| Entry          | Level    | Where                        |
|----------------|----------|------------------------------|
| `✓`            | Gate     | endpoint `authorize:`        |
| `✗`            | Gate     | omit from `authorize:` list  |
| `own`          | Domain   | service method               |
| `own+draft`    | Domain   | service method               |
| `published`    | Domain   | service method               |

---

## Architecture Reference

```
app/
├── endpoints/    ← HTTP layer. Declarative. 5 lines per resource.
├── entities/     ← Domain objects. ActiveModel. No DB.
├── services/     ← Business logic. Orchestrates repository + entity.
├── repositories/ ← Data access. Wraps ActiveRecord. Returns entities.
├── records/      ← ActiveRecord models. DB only. Never used in domain.
└── actions/      ← Custom operations (non-CRUD). Optional.
```

### Layer rules

- Entity NEVER touches the database
- Repository is the ONLY place that uses Record
- Service is the ONLY place with business logic
- Endpoint NEVER contains logic — only wiring
- Record NEVER appears outside Repository

### What the base classes give you for free

**ApplicationEndpoint** — declare `resource` and get:
- Full CRUD (index/show/create/update/destroy)
- Collection: pagination, sorting, filtering, full-text search
- HATEOAS: `_links` with self, relations, available transitions
- Cache-Control headers per action
- Error responses: 404 JSON on missing record, 422 JSON on validation
- Authorization config (roles + owner + condition)
- Transition dispatch: `transition(params, :publish)` method

**ApplicationEntity** — inherit and get:
- `ActiveModel::API` + `ActiveModel::Attributes` (typed attrs, validations, `as_json`)
- `persisted?` (true when id present)
- `transitions :status, publish: {from: "draft", to: "published"}, ...`
- `can_transition?(:publish)` / `transition!(:publish)`
- `aggregate` and `aggregate_root` class methods

**ApplicationRepository** — set `record_class` + `entity_class` and get:
- `all`, `find(id)`, `create(attrs)`, `update(id, attrs)`, `destroy(id)`
- `paginate(page:, per:, sort:, filter:, search:, search_fields:)`
- Automatic Record → Entity mapping
- `update` merges partial attrs with existing record before validation
- Validation error propagation from Record to Entity

**ApplicationService** — inherit and get:
- `perform_transition(id, :name)` — public, called by endpoint for state changes
- `guard_transition(entity, :name)` — private hook, override to add preconditions

## Summary

```
1. Listen to the user          → understand the domain
2. Write behavior specs        → formalize rules, roles, states, effects
3. Derive ir.json              → structure for code generation
4. rails generate from_ir      → working CRUD skeleton
5. Read specs, write logic     → entity validations, service guards,
                                  transitions, authorization, side effects
```

Behavior specs are the source of truth for business logic.
IR is the source of truth for structure.
Neither replaces the other.
