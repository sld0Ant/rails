## Context

HATEOAS is already implemented. The missing piece: conditional links based on resource state. When a Parcel is `draft`, client sees `publish` link. After publishing (status=`active`), `publish` disappears and `archive` appears. This is the core of Fielding's HATEOAS — API drives application state through available transitions.

## Goals / Non-Goals

**Goals:**
- Entity declares state machine via `transitions` class method
- Transitions are guarded: only allowed from specified source state
- Each transition generates an Action Object (POST endpoint)
- Service exposes transition methods
- `_links` includes transition links only when valid for current state
- IR `states` field for export/import

**Non-Goals:**
- Async state machines (event sourcing)
- Multiple state fields per entity
- State history tracking

## Decisions

### 1. Entity DSL — minimal state machine

```ruby
class Parcel < ApplicationEntity
  attribute :status, :string

  transitions :status,
    publish: { from: "draft",    to: "active" },
    archive: { from: "active",   to: "archived" },
    restore: { from: "archived", to: "active" }
end
```

`transitions` stores config as class_attribute. Entity gains `can_transition?(name)` and `transition!(name)` instance methods.

### 2. Service delegates transitions to repository

```ruby
class ParcelService < ApplicationService
  def publish(id) = perform_transition(id, :publish)
  def archive(id) = perform_transition(id, :archive)
end
```

`ApplicationService#perform_transition(id, name)`: finds entity, checks `can_transition?`, updates status field via repository.

### 3. _links conditional on state

```ruby
# In with_links:
entity_class.transitions_config.each do |name, config|
  if entity_hash[state_field] == config[:from]
    links[name.to_s] = { "href" => "/plural/id/name", "method" => "POST" }
  end
end
```

Link appears only when `current_state == from`. Client never sees invalid transitions.

### 4. Scaffold generates Action Objects per transition

`rails g scaffold Parcel ... status:string` with transitions defined → generates `app/actions/parcels/publish.rb`, `app/actions/parcels/archive.rb` etc. For simplicity in this chunk, transitions are service methods called from generic transition endpoint, not separate Action Object files.
