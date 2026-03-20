## ADDED Requirements

### Requirement: IR validates relation targets
IR.validate! SHALL check that every relation resource target exists as a resource name in the same IR document.

#### Scenario: Invalid relation target
- **WHEN** IR has resource Parcel with relation `"unicorn": {"kind":"belongs_to","resource":"Unicorn"}` and no Unicorn resource
- **THEN** validate! SHALL raise InvalidIRError with message naming the bad target

#### Scenario: Valid relations pass
- **WHEN** all relation targets reference existing resources
- **THEN** validate! SHALL not raise

### Requirement: Text type preserved in round-trip
SchemaRegistry SHALL use Record column sql_type to distinguish `text` from `string`. Entity generator SHALL map `"text"` IR type to `:string` ActiveModel type but IR SHALL store `"text"` not `"string"`.

#### Scenario: Text column round-trip
- **WHEN** Record has a `text` sql_type column named `description`
- **THEN** SchemaRegistry SHALL output IR attribute with `"type": "text"`
- **THEN** from_ir SHALL pass `description:text` to scaffold
- **THEN** migration SHALL create `text` column

### Requirement: has_many appended to parent Record
from_ir SHALL append `has_many` declarations to parent Record files after scaffolding children.

#### Scenario: Child belongs_to parent
- **WHEN** from_ir scaffolds Parcel with `district:references`
- **THEN** DistrictRecord SHALL contain `has_many :parcels, class_name: "ParcelRecord"`

### Requirement: Endpoint instrumentation
endpoint_dispatch SHALL wrap action execution in `ActiveSupport::Notifications.instrument` and call `Rails.error.report` on exceptions.

#### Scenario: Successful request instrumented
- **WHEN** GET /parcels is called
- **THEN** an `endpoint.process` notification SHALL be emitted with endpoint name, action, and status

#### Scenario: Error reported
- **WHEN** an unhandled exception occurs in endpoint
- **THEN** `Rails.error.report` SHALL be called before returning 500

### Requirement: from_ir generates routes file
from_ir SHALL create `config/routes_ddd.rb` with endpoint declarations and nested scoping for resources with parent field.

#### Scenario: Routes file generated
- **WHEN** from_ir runs with 3 resources (Org, Member belongs_to Org, Parcel no parent)
- **THEN** `config/routes_ddd.rb` SHALL contain `endpoint OrganizationsEndpoint`, `endpoint MembersEndpoint`, `endpoint ParcelsEndpoint`
