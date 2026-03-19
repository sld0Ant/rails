## ADDED Requirements

### Requirement: Entity transitions DSL
ApplicationEntity SHALL provide `transitions(field, **config)` class method that stores state machine configuration.

#### Scenario: Define transitions
- **WHEN** entity declares `transitions :status, publish: {from: "draft", to: "active"}`
- **THEN** `Entity.transitions_config` SHALL contain `{publish: {from: "draft", to: "active"}}`
- **THEN** `Entity.state_field` SHALL equal `"status"`

#### Scenario: can_transition? check
- **WHEN** entity has `status: "draft"` and transition `publish` requires `from: "draft"`
- **THEN** `entity.can_transition?(:publish)` SHALL return true
- **WHEN** entity has `status: "active"` and transition `publish` requires `from: "draft"`
- **THEN** `entity.can_transition?(:publish)` SHALL return false

### Requirement: Service performs transitions
ApplicationService SHALL provide `perform_transition(id, transition_name)` that validates and executes the transition.

#### Scenario: Valid transition
- **WHEN** `service.perform_transition(id, :publish)` is called on entity with status "draft"
- **THEN** entity status SHALL be updated to "active" and persisted entity returned

#### Scenario: Invalid transition
- **WHEN** `service.perform_transition(id, :publish)` is called on entity with status "active"
- **THEN** it SHALL return entity with error on status field

### Requirement: HATEOAS links conditional on state
`_links` SHALL include transition links only when the transition is valid for the current state.

#### Scenario: Draft shows publish link
- **WHEN** GET /parcels/1 returns entity with status "draft"
- **THEN** `_links` SHALL include `"publish": {"href": "/parcels/1/publish", "method": "POST"}`
- **THEN** `_links` SHALL NOT include `"archive"`

#### Scenario: Active shows archive link
- **WHEN** GET /parcels/1 returns entity with status "active"
- **THEN** `_links` SHALL include `"archive"` but NOT `"publish"`

### Requirement: Transition endpoint
Each transition SHALL be callable via `POST /resources/:id/transition_name`.

#### Scenario: POST publish
- **WHEN** POST /parcels/1/publish is called and parcel status is "draft"
- **THEN** response SHALL be 200 with updated entity (status "active")

#### Scenario: POST invalid transition
- **WHEN** POST /parcels/1/publish is called and parcel status is "active"
- **THEN** response SHALL be 422 with error message
