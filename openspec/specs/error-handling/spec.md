## ADDED Requirements

### Requirement: RecordNotFound returns 404 JSON
When `ActiveRecord::RecordNotFound` is raised during endpoint dispatch, the response SHALL be `[404, {"content-type": "application/json"}, {"error": "Not found", "status": 404}]`.

#### Scenario: Show non-existent resource
- **WHEN** GET /parcels/999999 is called and no record with id 999999 exists
- **THEN** response SHALL be 404 with JSON body `{"error": "Not found", "status": 404}`

### Requirement: Unhandled errors return 500 JSON
When any unhandled `StandardError` is raised during endpoint dispatch, the response SHALL be `[500, {"content-type": "application/json"}, {"error": "<message>", "status": 500}]`.

#### Scenario: Internal server error
- **WHEN** an unexpected error occurs during endpoint processing
- **THEN** response SHALL be 500 with JSON body containing the error message

### Requirement: Validation errors return 422 JSON
This already works via ApplicationEndpoint create/update methods.

#### Scenario: Existing 422 still works
- **WHEN** create is called with invalid data
- **THEN** response SHALL be 422 with `{"errors": {...}}`
