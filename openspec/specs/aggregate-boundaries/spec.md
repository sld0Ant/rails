## ADDED Requirements

### Requirement: Aggregate root declaration
ApplicationEntity SHALL provide `aggregate_root` class_attribute (boolean, default false).

#### Scenario: Entity declares aggregate root
- **WHEN** `Parcel` declares `aggregate_root true`
- **THEN** `Parcel.aggregate_root` SHALL return true

### Requirement: Aggregate child declaration
ApplicationEntity SHALL provide `aggregate(parent_name)` class method setting `aggregate_parent` class_attribute.

#### Scenario: Child entity
- **WHEN** `Note` declares `aggregate :Parcel`
- **THEN** `Note.aggregate_parent` SHALL equal `"Parcel"`

### Requirement: IR aggregate field
IR resource SHALL include `aggregate_root: true` or `aggregate: "ParentName"` when declared.

#### Scenario: IR output
- **WHEN** SchemaRegistry collects from app with Parcel (root) and Note (child of Parcel)
- **THEN** Parcel IR SHALL have `"aggregate_root": true`
- **THEN** Note IR SHALL have `"aggregate": "Parcel"`
