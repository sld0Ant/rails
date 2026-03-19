## ADDED Requirements

### Requirement: Entity generator
`rails g entity Name field:type` SHALL create `app/entities/name.rb` with typed attributes and class inheriting from `ApplicationEntity`.

#### Scenario: Generate entity with fields
- **WHEN** `rails g entity Post title:string body:text` is run
- **THEN** it SHALL create `app/entities/post.rb` with `attribute :title, :string`, `attribute :body, :string`, `attribute :id, :integer`, and timestamp attributes

### Requirement: Repository generator
`rails g repository Name` SHALL create `app/repositories/name_repository.rb` inheriting from `ApplicationRepository` with `record_class` and `entity_class` configured.

#### Scenario: Generate repository
- **WHEN** `rails g repository Post` is run
- **THEN** it SHALL create `app/repositories/post_repository.rb` with `self.record_class = PostRecord` and `self.entity_class = Post`

### Requirement: Service generator
`rails g service Name` SHALL create `app/services/name_service.rb` inheriting from `ApplicationService` with CRUD delegation methods.

#### Scenario: Generate service
- **WHEN** `rails g service Post` is run
- **THEN** it SHALL create `app/services/post_service.rb` with `list_all`, `find`, `create`, `update`, `destroy` methods delegating to `PostRepository`

### Requirement: Endpoint generator
`rails g endpoint Name` SHALL create `app/endpoints/name_endpoint.rb` inheriting from `ApplicationEndpoint` with resource declaration.

#### Scenario: Generate endpoint
- **WHEN** `rails g endpoint Posts title:string body:text` is run
- **THEN** it SHALL create `app/endpoints/posts_endpoint.rb` with `resource :post, service: PostService, permit: [:title, :body]`

### Requirement: Action generator
`rails g action Namespace::Name` SHALL create `app/actions/namespace/name.rb` inheriting from `ApplicationAction` with `handle` method stub.

#### Scenario: Generate action
- **WHEN** `rails g action Posts::Publish` is run
- **THEN** it SHALL create `app/actions/posts/publish.rb` with module wrapping and `def handle(req, res)` stub

### Requirement: AR Record generator modification
The existing model generator SHALL output to `app/records/` with `Record` suffix and `self.table_name` override.

#### Scenario: Generate record via scaffold
- **WHEN** scaffold generates the AR model for `Post`
- **THEN** it SHALL create `app/records/post_record.rb` with `class PostRecord < ApplicationRecord` and `self.table_name = "posts"`

#### Scenario: Migration table name
- **WHEN** scaffold generates the migration for `Post`
- **THEN** the migration SHALL create table `posts` (not `post_records`)

### Requirement: Scaffold integration
`rails g scaffold Name field:type` SHALL invoke entity, record+migration, repository, service, and endpoint generators in sequence.

#### Scenario: Full scaffold
- **WHEN** `rails g scaffold Post title:string body:text` is run
- **THEN** it SHALL create: `app/entities/post.rb`, `app/records/post_record.rb`, `db/migrate/*_create_posts.rb`, `app/repositories/post_repository.rb`, `app/services/post_service.rb`, `app/endpoints/posts_endpoint.rb`
