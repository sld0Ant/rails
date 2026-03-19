## 1. Base Class Templates

- [x] 1.1 Create `railties/lib/rails/generators/rails/app/templates/app/entities/application_entity.rb.tt` — ApplicationEntity with ActiveModel::API, Attributes, Serializers::JSON, persisted?
- [x] 1.2 Create `railties/lib/rails/generators/rails/app/templates/app/repositories/application_repository.rb.tt` — ApplicationRepository with class_attribute record_class/entity_class, CRUD methods, to_entity mapping, error handling
- [x] 1.3 Create `railties/lib/rails/generators/rails/app/templates/app/services/application_service.rb.tt` — ApplicationService with private repository method
- [x] 1.4 Create `railties/lib/rails/generators/rails/app/templates/app/endpoints/application_endpoint.rb.tt` — ApplicationEndpoint with resource DSL, 5 CRUD methods returning Rack tuples
- [x] 1.5 Create `railties/lib/rails/generators/rails/app/templates/app/actions/application_action.rb.tt` — ApplicationAction with call(env) and handle(req, res) contract
- [x] 1.6 Create `railties/lib/rails/generators/rails/app/templates/app/records/application_record.rb.tt` — ApplicationRecord (moved from models/)

## 2. Engine Configuration

- [x] 2.1 Modify `railties/lib/rails/engine/configuration.rb` — add `app/entities`, `app/records`, `app/repositories`, `app/services`, `app/endpoints`, `app/actions` (all eager_load: true); keep app/controllers, app/helpers, app/views for backward compat with mailers/gems

## 3. App Generator

- [x] 3.1 Modify `railties/lib/rails/generators/rails/app/app_generator.rb` AppBuilder#app — create DDD directories (endpoints, actions, entities, services, repositories, records) with base class files
- [x] 3.2 Modify `railties/lib/rails/generators/rails/app/app_generator.rb` AppGenerator — update delete_application_record_skipping_active_record to use records/ path

## 4. Routing DSL

- [x] 4.1 Create `actionpack/lib/action_dispatch/routing/mapper/endpoint_resources.rb` — module with `endpoint` and `endpoint_dispatch` methods
- [x] 4.2 Modify `actionpack/lib/action_dispatch/routing/mapper.rb` — require and include EndpointResources module

## 5. AR Model Generator (Record)

- [x] 5.1 Modify `activerecord/lib/rails/generators/active_record/model/model_generator.rb` — output to `app/records/#{file_name}_record.rb`, override table_name for migrations to use entity name (not record name)
- [x] 5.2 Modify `activerecord/lib/rails/generators/active_record/model/templates/model.rb.tt` — class name with Record suffix, add `self.table_name = "<table_name>"`

## 6. Entity Generator

- [x] 6.1 Create `railties/lib/rails/generators/rails/entity/entity_generator.rb` — accepts name + attributes, generates entity with typed attributes and id/timestamps
- [x] 6.2 Create `railties/lib/rails/generators/rails/entity/templates/entity.rb.tt` — template with attribute declarations
- [x] 6.3 Create `railties/lib/rails/generators/rails/entity/USAGE` — usage doc

## 7. Repository Generator

- [x] 7.1 Create `railties/lib/rails/generators/rails/repository/repository_generator.rb` — generates repository with record_class and entity_class
- [x] 7.2 Create `railties/lib/rails/generators/rails/repository/templates/repository.rb.tt`
- [x] 7.3 Create `railties/lib/rails/generators/rails/repository/USAGE`

## 8. Service Generator

- [x] 8.1 Create `railties/lib/rails/generators/rails/service/service_generator.rb` — generates service with CRUD methods delegating to repository
- [x] 8.2 Create `railties/lib/rails/generators/rails/service/templates/service.rb.tt`
- [x] 8.3 Create `railties/lib/rails/generators/rails/service/USAGE`

## 9. Endpoint Generator

- [x] 9.1 Create `railties/lib/rails/generators/rails/endpoint/endpoint_generator.rb` — generates endpoint with resource declaration
- [x] 9.2 Create `railties/lib/rails/generators/rails/endpoint/templates/endpoint.rb.tt`
- [x] 9.3 Create `railties/lib/rails/generators/rails/endpoint/USAGE`

## 10. Action Generator

- [x] 10.1 Create `railties/lib/rails/generators/rails/action_object/action_object_generator.rb` — generates action with handle stub (named action_object to avoid conflict with existing Rails Action)
- [x] 10.2 Create `railties/lib/rails/generators/rails/action_object/templates/action_object.rb.tt`
- [x] 10.3 Create `railties/lib/rails/generators/rails/action_object/USAGE`

## 11. Resource & Scaffold Generators

- [x] 11.1 Modify `railties/lib/rails/generators/rails/resource/resource_generator.rb` — add hook_for :entity, :repository, :service, :endpoint alongside existing :orm hook
- [x] 11.2 Modify `railties/lib/rails/generators/rails/scaffold/scaffold_generator.rb` — remove scaffold_controller hook, keep only DDD hooks from resource
- [x] 11.3 Modify `railties/lib/rails/generators/test_unit/scaffold/templates/api_functional_test.rb.tt` — update test template for endpoint-based routing (ClassRecord.count)

## 12. Cleanup

- [x] 12.1 Remove `railties/lib/rails/generators/rails/app/templates/app/models/application_record.rb.tt` (replaced by records/)
- [x] 12.2 Remove `railties/lib/rails/generators/rails/app/templates/app/controllers/application_controller.rb.tt` (replaced by endpoints/)
- [x] 12.3 Remove `railties/lib/rails/generators/rails/app/templates/app/helpers/application_helper.rb.tt` (no views)
