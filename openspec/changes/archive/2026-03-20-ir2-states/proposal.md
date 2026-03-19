## Why

Resources have lifecycles: a Parcel can be `draft → active → archived`. Currently there's no way to express state transitions — clients call generic PATCH to change status with no validation of allowed transitions. With state machines: transitions are explicit Action Objects (`POST /parcels/1/publish`), only valid transitions are exposed in HATEOAS `_links`, and invalid transitions are rejected.

## What Changes

- Entity DSL gains `transitions` class method defining state machine (field, states, transitions)
- Scaffold generates Action Objects for each transition
- Service gains transition methods delegating to repository with guard
- HATEOAS `_links` includes transition links only when transition is available
- IR format gains `states` field per resource
- Endpoint generator creates routes for transitions

## Capabilities

### New Capabilities
- `state-machines`: Entity-level state machine with guarded transitions, Action Objects, conditional HATEOAS links

### Modified Capabilities
- `hateoas-links`: _links include/exclude transition actions based on current state
- `ddd-generators`: Scaffold generates Action Objects for transitions
- `ddd-ir-format`: IR resource gains optional `states` field

## Impact

- **New**: transition Action Objects generated per state transition
- **Modified**: ApplicationEntity (transitions DSL), ApplicationEndpoint (_links with conditions), Service template, from_ir generator
- **No new dependencies**
