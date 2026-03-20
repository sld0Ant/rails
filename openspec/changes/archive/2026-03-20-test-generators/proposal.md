## Why

`rails g scaffold Post title:string` generates 6 DDD files but zero test files. Developers have no safety net out of the box. Each DDD layer needs its own test type: Entity (unit, no DB), Service (unit, mock repo), Repository (integration, DB), Endpoint (HTTP integration).

## What Changes

- 4 test templates for scaffold: entity_test, service_test, repository_test, endpoint_test
- Scaffold hooks test generation into existing test_framework hook
- Tests use minitest (Rails default) with standard assertions

## Capabilities

### New Capabilities
- `test-generators`: Scaffold generates test files for all 4 DDD layers

### Modified Capabilities
- `ddd-generators`: Entity, Service, Repository, Endpoint generators gain hook_for :test_framework

## Impact

- **New**: 4 test template files
- **Modified**: entity, service, repository, endpoint generators (add hook_for)
- **No new dependencies**
