## 1. Test Templates

- [x] 1.1 Create `railties/lib/rails/generators/rails/entity/templates/entity_test.rb.tt`
- [x] 1.2 Create `railties/lib/rails/generators/rails/service/templates/service_test.rb.tt`
- [x] 1.3 Create `railties/lib/rails/generators/rails/repository/templates/repository_test.rb.tt`
- [x] 1.4 Create `railties/lib/rails/generators/rails/endpoint/templates/endpoint_test.rb.tt`

## 2. Generator Hooks

- [x] 2.1 Update entity_generator.rb — add create_test_file method
- [x] 2.2 Update service_generator.rb — add create_test_file method
- [x] 2.3 Update repository_generator.rb — add create_test_file method
- [x] 2.4 Update endpoint_generator.rb — add create_test_file method

## 3. E2E Test

- [x] 3.1 Scaffold on real app, verify all 4 test files created, destroy removes them
