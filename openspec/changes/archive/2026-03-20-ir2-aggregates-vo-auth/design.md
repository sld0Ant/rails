## Context

Final chunk of IR 2.0. Three features that complete the DDD+REST model.

## Goals / Non-Goals

**Goals:**
- Aggregate root/child entity declarations
- Child resources scoped under parent in routing (enforced, not optional)
- Value Objects as JSON-serialized embedded objects
- Per-operation authorization with role arrays
- All three reflected in IR for export/import

**Non-Goals:**
- JWT/OAuth token parsing (infrastructure concern, not framework)
- Complex authorization policies (pundit-level, future)
- Nested aggregates (aggregate within aggregate)

## Decisions

### 1. Aggregate via entity declaration

```ruby
class Parcel < ApplicationEntity
  aggregate_root true
end

class Note < ApplicationEntity
  aggregate :Parcel  # can only be accessed through Parcel
end
```

`aggregate_root` is a class_attribute boolean. `aggregate` sets `aggregate_parent` class_attribute. SchemaRegistry reads these for IR.

Routing effect: when `from_ir` generates routes for Note with `aggregate: "Parcel"`, it scopes under parent:
```ruby
scope "/parcels/:parcel_id" do
  endpoint NotesEndpoint
end
```
No top-level `/notes` route is generated.

### 2. Value Objects as JSON columns

```ruby
class Parcel < ApplicationEntity
  attribute :address, :json  # stored as JSON in DB
end
```

For IR, value objects are declared at app level:
```json
"value_objects": {
  "address": { "street": "string", "city": "string", "zip": "string" }
}
```

Implementation: use ActiveModel attribute type `:json` (custom type that serializes/deserializes). Record stores in a `jsonb`/`json`/`text` column. Simple approach — no separate class for MVP, just a JSON hash attribute.

### 3. Authorization as endpoint DSL

```ruby
class ParcelsEndpoint < ApplicationEndpoint
  resource :parcel, ...,
    authorize: {
      index: ["*"],
      show: ["*"],
      create: ["admin", "manager"],
      update: ["admin", "manager"],
      destroy: ["admin"]
    }
end
```

`"*"` means public. Endpoint dispatch checks `current_user_role` (extracted from request header `X-User-Role` for simplicity). Returns 403 if role not in allowed list.

This is a minimal convention — real apps replace with JWT middleware. But the IR captures the authorization contract.
