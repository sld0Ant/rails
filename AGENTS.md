# AGENTS.md

DDD fork of Ruby on Rails. MVC replaced with Endpoints → Services → Entities → Repositories.

## For LLM agents

Read `docs/llm-guide.md` — it contains the complete workflow:
1. Understand the user's domain
2. Write behavioral specs (`docs/behavior/*.md`)
3. Derive IR (`docs/ir.json`)
4. Generate code (`rails generate from_ir docs/ir.json`)
5. Add business logic from specs

## Reference

- `docs/llm-guide.md` — main instruction (paste as system context)
- `docs/ddd-ir-schema.md` — IR format specification

## Environment

```bash
export GEM_HOME="$HOME/.local/share/gem/ruby/3.4.0"
export BUNDLE_PATH="$GEM_HOME"
export PATH="$GEM_HOME/bin:$PATH"

cd ~/Projects/rb-ru
ruby railties/exe/rails new /tmp/myapp --api --dev
```
