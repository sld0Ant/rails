## ADDED Requirements

### Requirement: Nested resource routing
Resources with `parent` field SHALL generate routes scoped under the parent resource path.

#### Scenario: Comment nested under Parcel
- **WHEN** IR Comment has `"parent": "Parcel"` and `"path": "/parcels/{parcel_id}/comments"`
- **THEN** routes SHALL scope CommentsEndpoint under `/parcels/:parcel_id`
- **THEN** CommentsEndpoint SHALL receive `parcel_id` in params

#### Scenario: Parent is optional
- **WHEN** IR resource has no `parent` field
- **THEN** routing SHALL work as before (top-level endpoint)
