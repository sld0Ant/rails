## ADDED Requirements

### Requirement: Value Object as JSON attribute
ApplicationEntity SHALL support attributes with type `:json` that store structured data without identity.

#### Scenario: JSON attribute
- **WHEN** entity declares `attribute :address, :json`
- **THEN** entity SHALL accept a hash `{street: "Main St", city: "Moscow"}` and serialize to JSON

#### Scenario: Record stores as JSON column
- **WHEN** scaffold generates a resource with a `:json` type attribute
- **THEN** migration SHALL create a `json` or `text` column for it

### Requirement: IR value_objects field
IR MAY contain a top-level `value_objects` map defining reusable embedded schemas.

#### Scenario: IR output
- **WHEN** entity has a `:json` attribute named `address`
- **THEN** IR SHALL include the attribute with `"type": "json"`
