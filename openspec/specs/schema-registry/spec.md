## ADDED Requirements

### Requirement: SchemaRegistry collects IR from runtime
`DDD::SchemaRegistry.collect` SHALL scan `app/endpoints/*_endpoint.rb`, resolve Entity and Record classes by convention, and return an array of IR resource hashes.

#### Scenario: Discover 3 endpoints
- **WHEN** app has `ParcelsEndpoint`, `DistrictsEndpoint`, `OwnersEndpoint` in `app/endpoints/`
- **THEN** `collect` SHALL return 3 IR resources with correct names, attributes, and permits

#### Scenario: Attribute introspection from Entity
- **WHEN** `Parcel` entity has `attribute :area, :float` and `attribute :status, :string`
- **THEN** IR attributes SHALL contain `"area" => {type: "float", ...}` and `"status" => {type: "string", ...}`

#### Scenario: Permit from Endpoint
- **WHEN** `ParcelsEndpoint` declares `permit: [:cadastral_number, :area]`
- **THEN** IR permit SHALL equal `["cadastral_number", "area"]`

#### Scenario: Auto-discovery without registration
- **WHEN** a new `*_endpoint.rb` file is added to `app/endpoints/`
- **THEN** next `collect` call SHALL include it automatically

#### Scenario: Skip ApplicationEndpoint
- **WHEN** `app/endpoints/application_endpoint.rb` exists
- **THEN** `collect` SHALL NOT include it in results
