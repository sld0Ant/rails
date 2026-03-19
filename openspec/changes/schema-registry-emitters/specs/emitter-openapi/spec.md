## ADDED Requirements

### Requirement: OpenAPI 3.0 document generation
`DDD::Emitter::OpenAPI` SHALL generate a valid OpenAPI 3.0.3 YAML string from IR resources, containing `openapi`, `info`, `paths`, and `components/schemas` sections.

#### Scenario: Paths for CRUD resource
- **WHEN** IR contains resource with plural "parcels" and 5 operations
- **THEN** output SHALL contain paths `/parcels` (get, post) and `/parcels/{id}` (get, patch, delete)

#### Scenario: Schema from attributes
- **WHEN** IR has Parcel with `area: float` and `registration_number: string`
- **THEN** `components/schemas/Parcel` SHALL have `area: {type: number, format: float}` and `registration_number: {type: string}`

#### Scenario: Request body from permit
- **WHEN** IR permit is `["registration_number", "area"]`
- **THEN** POST and PATCH operations SHALL have requestBody referencing `ParcelInput` schema with only those fields

#### Scenario: Response status codes
- **WHEN** operations are generated
- **THEN** index → 200 (array), show → 200 (object), create → 201, update → 200, destroy → 204

#### Scenario: Multiple resources in one document
- **WHEN** IR contains 3 resources
- **THEN** output SHALL be a single YAML with all paths and schemas combined

#### Scenario: Type mapping
- **WHEN** IR type is `integer`
- **THEN** OpenAPI type SHALL be `integer` with format `int64`
- **WHEN** IR type is `datetime`
- **THEN** OpenAPI type SHALL be `string` with format `date-time`
- **WHEN** IR type is `boolean`
- **THEN** OpenAPI type SHALL be `boolean` with no format
