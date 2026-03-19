## Why

REST Uniform Interface requires HATEOAS — responses must include links to related resources and available actions. Currently our JSON responses are flat data with no navigation. Clients must hardcode URLs. With `_links` in responses, clients discover the API structure from the data itself.

## What Changes

- Entity JSON responses gain `_links` section with `self`, relation links, and operation links
- ApplicationEndpoint builds `_links` from resource relations and path conventions
- IR format gains optional `links` field per resource
- SchemaRegistry generates links from relations + operations

## Capabilities

### New Capabilities
- `hateoas-links`: Every JSON response includes `_links` with self, relations, and available actions

### Modified Capabilities
- `declarative-endpoints`: show/index responses include `_links`
- `ddd-ir-format`: IR resource gains optional `links` field
- `schema-registry`: Builds links from relations and operations

## Impact

- **Modified**: ApplicationEndpoint (response building), ApplicationRepository (include links data), SchemaRegistry, IR
- **No new dependencies**
