## ADDED Requirements

### Requirement: from_ir generator scaffolds DDD resources from IR JSON
`rails generate from_ir <path>` SHALL read an IR JSON file, validate its structure, and invoke `rails generate scaffold` for each resource defined in the file.

#### Scenario: Generate from valid IR with 2 resources
- **WHEN** `rails g from_ir docs/ir.json` is run and ir.json contains Parcel and District resources
- **THEN** it SHALL invoke scaffold for each resource, creating entity, record, migration, repository, service, endpoint for both

#### Scenario: Attribute type mapping
- **WHEN** IR resource has `"area": {"type": "float"}` and `"name": {"type": "string"}`
- **THEN** scaffold SHALL receive `area:float name:string` as attribute arguments

#### Scenario: Skip readonly attributes
- **WHEN** IR attribute has `"readonly": true` (id, created_at, updated_at)
- **THEN** it SHALL NOT be passed to scaffold as an attribute argument (scaffold adds these automatically)

#### Scenario: Invalid IR file
- **WHEN** ir.json does not contain `$schema` or `resources` key
- **THEN** generator SHALL print an error message and exit without generating files

#### Scenario: File not found
- **WHEN** the specified path does not exist
- **THEN** generator SHALL print "File not found: <path>" and exit

#### Scenario: Dry run
- **WHEN** `rails g from_ir docs/ir.json --pretend` is run
- **THEN** it SHALL print what would be generated without creating files
