## ADDED Requirements

### Requirement: Show response includes _links
Every show response SHALL include `_links` object with at minimum `self` link.

#### Scenario: Self link
- **WHEN** GET /parcels/1 returns a parcel
- **THEN** response SHALL include `"_links": { "self": "/parcels/1", ... }`

#### Scenario: belongs_to link
- **WHEN** Parcel belongs_to District with district_id=5
- **THEN** `_links` SHALL include `"district": "/districts/5"`

#### Scenario: has_many link
- **WHEN** Parcel has_many notes
- **THEN** `_links` SHALL include `"notes": "/parcels/1/notes"`

### Requirement: Index items include self link
Each entity in index response SHALL include `_links` with at least `self`.

#### Scenario: Index with links
- **WHEN** GET /parcels returns 2 parcels
- **THEN** each item in response SHALL have `_links.self` pointing to its show URL

### Requirement: Endpoint auto-generates links from relations
ApplicationEndpoint SHALL accept `relations:` class_attribute and build `_links` automatically without manual configuration.

#### Scenario: No explicit links config
- **WHEN** endpoint has relations `{district: {kind: "belongs_to"}, notes: {kind: "has_many"}}`
- **THEN** `_links` SHALL be generated automatically from conventions
