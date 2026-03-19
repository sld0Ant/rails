## ADDED Requirements

### Requirement: IR relations field
Each IR resource MAY contain a `relations` object mapping association name to association descriptor with `kind`, `resource`, and optional `required` and `through` fields.

#### Scenario: belongs_to relation
- **WHEN** IR resource Parcel has `"district": {"kind": "belongs_to", "resource": "District", "required": true}`
- **THEN** generated ParcelRecord SHALL have `belongs_to :district`
- **THEN** generated Parcel entity SHALL have `attribute :district_id, :integer`
- **THEN** generated migration SHALL have `t.references :district, null: false, foreign_key: true`

#### Scenario: has_many relation
- **WHEN** IR resource District has `"parcels": {"kind": "has_many", "resource": "Parcel"}`
- **THEN** generated DistrictRecord SHALL have `has_many :parcels, class_name: "ParcelRecord", foreign_key: "district_id"`

#### Scenario: has_many through relation
- **WHEN** IR resource Parcel has `"owners": {"kind": "has_many", "resource": "Owner", "through": "Ownership"}`
- **THEN** generated ParcelRecord SHALL have `has_many :ownerships` and `has_many :owners, through: :ownerships`

#### Scenario: belongs_to adds to permit list
- **WHEN** IR resource has belongs_to relation to District
- **THEN** generated endpoint permit SHALL include `:district_id`

### Requirement: SchemaRegistry collects relations from AR
`SchemaRegistry` SHALL read associations from Record class via `reflect_on_all_associations` and include them in IR output.

#### Scenario: Collect belongs_to
- **WHEN** ParcelRecord has `belongs_to :district`
- **THEN** `SchemaRegistry.collect` SHALL include `"district": {"kind": "belongs_to", "resource": "District"}` in Parcel's relations

### Requirement: from_ir generates relations
`from_ir` SHALL pass belongs_to relations as `name:references` arguments to scaffold, and SHALL sort resources in dependency order.

#### Scenario: Dependency ordering
- **WHEN** ir.json has Parcel (belongs_to District) and District (no belongs_to)
- **THEN** `from_ir` SHALL scaffold District before Parcel

#### Scenario: References attribute
- **WHEN** ir.json Parcel has belongs_to District
- **THEN** scaffold SHALL receive `district:references` as attribute argument
