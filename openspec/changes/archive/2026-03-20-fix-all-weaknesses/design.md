## Context

5 real weaknesses + 2 mitigable gaps from audit. All are isolated fixes — no architectural changes.

## Decisions

### 1. IR relation validation
Add to `validate!`: collect resource names into a Set, check each relation target exists.

### 2. text vs string
Entity generator already maps `"text" => ":string"`. Change to `"text" => ":string"` but keep "text" as IR type. SchemaRegistry should check `Record.columns` sql_type: if `text`/`TEXT` → IR type "text", else "string". from_ir already passes raw IR type to scaffold.

### 3. has_many in from_ir
After all scaffolds complete, second pass: for each resource with belongs_to, open the target's Record file, append `has_many :child_plural, class_name: "ChildRecord", foreign_key: "fk_name"` before final `end`.

### 4. Instrumentation
Wrap endpoint_dispatch body in `ActiveSupport::Notifications.instrument`. In rescue, call `Rails.error.report(e, handled: true)`.

### 5. Nested routes
from_ir generates a `config/routes_ddd.rb` file with all endpoint declarations. Resources with parent get scoped. Print instruction to require it from main routes.rb.
