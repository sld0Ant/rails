## Context

Fielding's 4th sub-constraint: HATEOAS. Client navigates API via links in responses, not hardcoded URLs. Currently `GET /parcels/1` returns `{"id":1, "registration_number":"77:01:001:123", "district_id": 5}` — client has no way to discover `/districts/5` or `/parcels/1/notes` without prior knowledge.

## Goals / Non-Goals

**Goals:**
- `_links` in every show response: self, belongs_to targets, has_many collections
- `_links` in index items: self link per entity
- Links built automatically from relations declared in IR/Endpoint
- IR `links` field for export

**Non-Goals:**
- Conditional links based on state (Chunk 4)
- HAL or JSON:API format compliance (we use simple `_links` convention)
- Link relation types (IANA registry)

## Decisions

### 1. _links built in ApplicationEndpoint from entity data + relations

```json
GET /parcels/1
{
  "id": 1,
  "registration_number": "77:01:001:123",
  "district_id": 5,
  "_links": {
    "self": "/parcels/1",
    "district": "/districts/5",
    "notes": "/parcels/1/notes"
  }
}
```

Links are computed from: path convention (`/plural/id`), belongs_to FK values, has_many conventions.

### 2. Endpoint declares `links:` mapping

```ruby
class ParcelsEndpoint < ApplicationEndpoint
  resource :parcel, ...,
    links: {
      district: ->(e) { "/districts/#{e['district_id']}" },
      notes: ->(e) { "/parcels/#{e['id']}/notes" }
    }
end
```

For scaffold, links are auto-generated from relations. Custom links via lambdas.

### 3. Simpler approach — auto-generate from relations in base class

Instead of requiring explicit link lambdas, ApplicationEndpoint reads `relations` class_attribute (populated by generator from IR) and builds links automatically:

- `self` → `/{plural}/{id}`
- each belongs_to → `/{related_plural}/{fk_value}`
- each has_many → `/{plural}/{id}/{related_plural}`

This requires no manual link configuration for standard CRUD.
