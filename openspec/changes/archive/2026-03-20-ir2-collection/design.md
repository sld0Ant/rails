## Context

Current `Repository#all` returns `record_class.all.map { to_entity }`. Index endpoint dumps everything as JSON. For a table with 100k rows this is catastrophic.

## Goals / Non-Goals

**Goals:**
- Pagination with page/per_page params and meta in response
- Sorting by declared sortable fields
- Filtering by declared filterable fields (exact match)
- Text search across declared searchable fields (LIKE)
- Declarative config in Endpoint, no manual code needed
- IR collection field for export/import

**Non-Goals:**
- Full-text search engines (Elasticsearch)
- Complex filter operators (gt, lt, between) — future
- Cursor-based pagination — future

## Decisions

### 1. Endpoint DSL declares collection capabilities

```ruby
class ParcelsEndpoint < ApplicationEndpoint
  resource :parcel,
    service: ParcelService,
    permit: [:registration_number, :area, :district_id],
    sort: [:created_at, :area],
    filter: [:district_id],
    search: [:registration_number],
    per_page: 25
end
```

All collection options are optional. Without them, `index` behaves as before (returns all).

### 2. Repository#paginate builds AR scope chain

```ruby
def paginate(page: 1, per: 25, sort: nil, filter: {}, search: nil, search_fields: [])
  scope = record_class.all
  filter.each { |k, v| scope = scope.where(k => v) }
  if search && search_fields.any?
    clauses = search_fields.map { |f| "#{f} LIKE ?" }.join(" OR ")
    scope = scope.where(clauses, *search_fields.map { "%#{search}%" })
  end
  scope = scope.order(sort) if sort
  total = scope.count
  records = scope.offset((page - 1) * per).limit(per)
  { data: records.map { |r| to_entity(r) }, meta: { page: page, per: per, total: total } }
end
```

### 3. Index response includes meta

```json
{
  "data": [...],
  "meta": { "page": 1, "per_page": 25, "total": 142 }
}
```

When no collection config, response is flat array `[...]` (backward compatible).

### 4. Query params convention

```
GET /parcels?page=2&per_page=10&sort=area&filter[district_id]=5&search=77:01
```
