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
- **WHEN** `ParcelsEndpoint` declares `pehttps://github.com/sld0Ant/rails/pull/3/conflict?name=openspec%252Fchanges%252Farchive%252F2026-03-19-schema-registry-emitters%252Fdesign.md&base_oid=078dd48391a89d9a0ddc5e57a6911609a778a69b&head_oid=f4a18453639f7835056326515fd7911a83bb3cb8rmit: [:registration_number, :area]`
- **THEN** IR permit SHALL equal `["registration_number", "area"]`

#### Scenario: Auto-discovery without registration
- **WHEN** a new `*_endpoint.rb` file is added to `app/endpoints/`
- **THEN** next `collect` call SHALL include it automatically

#### Scenario: Skip ApplicationEndpoint
- **WHEN** `app/endpoints/application_endpoint.rb` exists
- **THEN** `collect` SHALL NOT include it in results
