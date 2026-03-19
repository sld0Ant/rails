## ADDED Requirements

### Requirement: Endpoint collection DSL
ApplicationEndpoint SHALL accept optional `sort:`, `filter:`, `search:`, `per_page:` in `resource` declaration.

#### Scenario: Endpoint with collection config
- **WHEN** endpoint declares `sort: [:created_at, :area], filter: [:district_id], search: [:registration_number], per_page: 25`
- **THEN** class attributes `sortable_fields`, `filterable_fields`, `searchable_fields`, `default_per_page` SHALL be set

### Requirement: Repository paginate method
ApplicationRepository SHALL provide `paginate(page:, per:, sort:, filter:, search:, search_fields:)` returning `{ data: [entities], meta: { page:, per:, total: } }`.

#### Scenario: Pagination
- **WHEN** `paginate(page: 2, per: 10)` is called on 25 records
- **THEN** it SHALL return 10 entities and meta `{ page: 2, per: 10, total: 25 }`

#### Scenario: Filtering
- **WHEN** `paginate(filter: { district_id: 5 })` is called
- **THEN** it SHALL return only records where district_id = 5

#### Scenario: Sorting
- **WHEN** `paginate(sort: "area")` is called
- **THEN** results SHALL be ordered by area ascending

#### Scenario: Search
- **WHEN** `paginate(search: "77:01", search_fields: ["registration_number"])` is called
- **THEN** it SHALL return records where registration_number contains "77:01"

### Requirement: Endpoint index with collection
When collection config is present, `index` SHALL parse query params (page, per_page, sort, filter[], search) and return `{ data: [...], meta: {...} }`.

#### Scenario: Index with pagination
- **WHEN** GET /parcels?page=1&per_page=2 is called and 5 parcels exist
- **THEN** response SHALL contain `data` array with 2 items and `meta.total` = 5

#### Scenario: Index without collection config (backward compat)
- **WHEN** endpoint has no sort/filter/search/per_page options
- **THEN** index SHALL return flat array as before
