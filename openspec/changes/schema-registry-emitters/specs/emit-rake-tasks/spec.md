## ADDED Requirements

### Requirement: rake ddd:ir dumps IR to JSON file
`rake ddd:ir` SHALL collect IR via SchemaRegistry, serialize to JSON, and write to `docs/ir.json`.

#### Scenario: Generate ir.json
- **WHEN** `rake ddd:ir` is run in an app with 3 endpoints
- **THEN** `docs/ir.json` SHALL exist and contain 3 resources with valid IR structure

#### Scenario: Output path configurable
- **WHEN** `rake ddd:ir[custom/path.json]` is run
- **THEN** output SHALL be written to `custom/path.json`

### Requirement: rake ddd:emit generates spec file
`rake ddd:emit[format]` SHALL collect IR, pass it to the registered emitter, and write output to the conventional file path.

#### Scenario: Emit OpenAPI
- **WHEN** `rake ddd:emit[openapi]` is run
- **THEN** `docs/openapi.yaml` SHALL be created with valid OpenAPI 3.0 content

#### Scenario: Unknown format
- **WHEN** `rake ddd:emit[unknown]` is run
- **THEN** task SHALL print available formats and exit with error
