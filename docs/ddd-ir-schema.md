# DDD IR — Intermediate Representation Format

**Version:** 1.0
**Status:** Stable
**Media type:** `application/json`

## Purpose

DDD IR is a language-agnostic JSON format that describes API resources — their attributes, types, permitted fields, and CRUD operations. It serves as the **contract between code generation and specification emission**.

IR is NOT a replacement for OpenAPI. It is the source of truth for **code**, while OpenAPI is the source of truth for **documentation**.

```
                    ┌─────────────────┐
                    │   ir.json       │
                    │  (DDD IR 1.0)   │
                    └────────┬────────┘
                             │
          ┌──────────────────┼──────────────────┐
          ▼                  ▼                  ▼
  rails g from_ir      rake ddd:emit      bun emit-ts
          │              [openapi]              │
          ▼                  ▼                  ▼
  Ruby DDD stack       openapi.yaml        types.ts
  (6 files/resource)   (documentation)     (frontend)
```

## How to produce IR

**From existing app** (runtime introspection):
```bash
rake ddd:ir              # → docs/ir.json
rake ddd:ir[custom.json] # → custom path
```

**By hand** (design-first):
Write `ir.json` manually following this spec, then:
```bash
rails generate from_ir docs/ir.json   # → scaffold all resources
```

## Document structure

```json
{
  "$schema": "ddd-ir/1.0",
  "resources": [ ... ]
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `$schema` | string | yes | Format version. Always `"ddd-ir/1.0"` |
| `resources` | array | yes | Array of resource objects |

## Resource object

```json
{
  "name": "Parcel",
  "plural": "parcels",
  "path": "/parcels",
  "attributes": { ... },
  "permit": ["registration_number", "area", "status"],
  "operations": [ ... ],
  "validators": [ ... ]
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | string | yes | Entity class name (PascalCase). Used for class generation. |
| `plural` | string | yes | Pluralized resource name. Used for DB table, routes, and endpoint class. |
| `path` | string | yes | Base URL path for the resource. Always `"/<plural>"`. |
| `attributes` | object | yes | Map of attribute name → attribute descriptor. |
| `permit` | array | yes | List of writable attribute names (used in endpoint `permit:` and request bodies). |
| `operations` | array | yes | List of CRUD operations with HTTP method and path. |
| `validators` | array | yes | List of validation rules (may be empty). |

## Attribute descriptor

```json
{
  "type": "float",
  "nullable": true,
  "readonly": false
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `type` | string | yes | Ruby type name. See type vocabulary below. |
| `nullable` | boolean | yes | Whether the field can be null. `id` is always non-nullable. |
| `readonly` | boolean | yes | If true, the field is not writable (e.g. `id`, `created_at`, `updated_at`). Readonly fields are excluded from scaffold attribute arguments and request bodies. |

## Type vocabulary

IR uses Ruby ActiveModel type names directly. No mapping ambiguity.

| IR type | Ruby class | OpenAPI | TypeScript | JSON Schema | SQL (SQLite) |
|---------|------------|---------|------------|-------------|--------------|
| `integer` | `ActiveModel::Type::Integer` | `integer` (int64) | `number` | `integer` | `INTEGER` |
| `string` | `ActiveModel::Type::String` | `string` | `string` | `string` | `varchar` |
| `text` | `ActiveModel::Type::String` | `string` | `string` | `string` | `TEXT` |
| `float` | `ActiveModel::Type::Float` | `number` (float) | `number` | `number` | `float` |
| `decimal` | `ActiveModel::Type::Decimal` | `number` (double) | `number` | `number` | `decimal` |
| `boolean` | `ActiveModel::Type::Boolean` | `boolean` | `boolean` | `boolean` | `boolean` |
| `date` | `ActiveModel::Type::Date` | `string` (date) | `string` | `string` (date) | `date` |
| `datetime` | `ActiveModel::Type::DateTime` | `string` (date-time) | `string` | `string` (date-time) | `datetime` |
| `time` | `ActiveModel::Type::Time` | `string` (time) | `string` | `string` (time) | `time` |

## Operation object

```json
{
  "action": "create",
  "method": "POST",
  "path": "/parcels"
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `action` | string | yes | CRUD action name: `index`, `show`, `create`, `update`, `destroy` |
| `method` | string | yes | HTTP method: `GET`, `POST`, `PATCH`, `DELETE` |
| `path` | string | yes | URL path pattern. Use `{id}` for member routes. |

Standard CRUD operations:

| Action | Method | Path |
|--------|--------|------|
| `index` | `GET` | `/<plural>` |
| `show` | `GET` | `/<plural>/{id}` |
| `create` | `POST` | `/<plural>` |
| `update` | `PATCH` | `/<plural>/{id}` |
| `destroy` | `DELETE` | `/<plural>/{id}` |

## Validator object

```json
{
  "type": "presence",
  "fields": ["registration_number"]
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `type` | string | yes | Validator type (e.g. `presence`, `length`, `uniqueness`, `format`) |
| `fields` | array | yes | List of attribute names this validator applies to |

## Complete example

```json
{
  "$schema": "ddd-ir/1.0",
  "resources": [
    {
      "name": "Parcel",
      "plural": "parcels",
      "path": "/parcels",
      "attributes": {
        "id":                { "type": "integer",  "nullable": false, "readonly": true },
        "registration_number":  { "type": "string",   "nullable": true,  "readonly": false },
        "area":              { "type": "float",    "nullable": true,  "readonly": false },
        "status":            { "type": "string",   "nullable": true,  "readonly": false },
        "created_at":        { "type": "datetime", "nullable": false, "readonly": true },
        "updated_at":        { "type": "datetime", "nullable": false, "readonly": true }
      },
      "permit": ["registration_number", "area", "status"],
      "operations": [
        { "action": "index",   "method": "GET",    "path": "/parcels" },
        { "action": "show",    "method": "GET",    "path": "/parcels/{id}" },
        { "action": "create",  "method": "POST",   "path": "/parcels" },
        { "action": "update",  "method": "PATCH",  "path": "/parcels/{id}" },
        { "action": "destroy", "method": "DELETE",  "path": "/parcels/{id}" }
      ],
      "validators": [
        { "type": "presence", "fields": ["registration_number"] }
      ]
    }
  ]
}
```

## Round-trip guarantee

For any app built with DDD Rails scaffold:

```bash
rake ddd:ir                         # Code → IR
rails generate from_ir docs/ir.json # IR → Code (in a new app)
rake ddd:ir                         # Code → IR again
```

The two `ir.json` files will be **structurally identical** (attribute order may vary).

## Versioning

The `$schema` field contains the format version. Current: `"ddd-ir/1.0"`.

Breaking changes increment the major version. New optional fields increment the minor version.

Tools SHOULD check the major version and reject incompatible files.
