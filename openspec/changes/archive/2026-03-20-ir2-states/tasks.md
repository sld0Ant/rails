## 1. ApplicationEntity — transitions DSL

- [x] 1.1 Update `application_entity.rb.tt` — add `transitions(field, **config)` class method storing `transitions_config` and `state_field` class_attributes; add `can_transition?(name)` and `transition!(name)` instance methods

## 2. ApplicationService — perform_transition

- [x] 2.1 Update `application_service.rb.tt` — add `perform_transition(id, name)` method: find entity, check can_transition?, update state field via repository, return entity or entity with error

## 3. ApplicationEndpoint — conditional transition links

- [x] 3.1 Update `application_endpoint.rb.tt` — in `with_links`, read entity class transitions_config, add transition links only when can_transition? is true for current state; add `transitions_endpoint(params, transition_name)` method for handling POST transition

## 4. Routing — transition routes

- [x] 4.1 Update `endpoint_resources.rb` — `endpoint` method accepts `transitions:` option, generates `post "/:id/transition_name"` routes for each transition

## 5. SchemaRegistry — states in IR

- [x] 5.1 Update `schema_registry.rb` — collect `states` field from Entity.transitions_config and Entity.state_field

## 6. E2E Test

- [x] 6.1 Test: create draft parcel → publish (200) → publish again (422) → archive (200) → verify _links change at each step
