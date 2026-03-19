## Context

Current endpoint_dispatch is a bare lambda — any exception crashes with 500 and no JSON body. `Repository#find` calls `record_class.find(id)` which raises `ActiveRecord::RecordNotFound` on missing records. Clients get HTML error pages or empty responses.

## Goals / Non-Goals

**Goals:**
- Catch RecordNotFound → `[404, headers, {"error": "Not found"}]`
- Catch validation/generic errors → `[500, headers, {"error": "message"}]`
- Error handling in endpoint_dispatch (one place, not per-endpoint)
- Cache-Control headers via endpoint DSL
- ETag support via entity content hash

**Non-Goals:**
- RFC 7807 Problem Details (future — too complex for now)
- Custom exception handlers per endpoint (future)
- Cache invalidation strategy

## Decisions

### 1. Error rescue in endpoint_dispatch lambda

```ruby
def endpoint_dispatch(endpoint_class, action_name)
  lambda do |env|
    # ... params extraction ...
    endpoint_class.new.public_send(action_name, params)
  rescue ActiveRecord::RecordNotFound
    [404, json_headers, [{"error" => "Not found", "status" => 404}.to_json]]
  rescue => e
    [500, json_headers, [{"error" => e.message, "status" => 500}.to_json]]
  end
end
```

Single rescue point — all endpoints get error handling for free.

### 2. Cache via class_attribute in Endpoint

```ruby
class ParcelsEndpoint < ApplicationEndpoint
  resource :parcel, ...,
    cache: { index: { max_age: 60 }, show: { max_age: 300, public: true } }
end
```

Endpoint base class reads cache config and adds Cache-Control header to response tuple.

### 3. ETag from entity content

For show actions, ETag = MD5 of entity JSON. Enables conditional GET (If-None-Match → 304).
