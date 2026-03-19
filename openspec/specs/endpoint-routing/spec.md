## ADDED Requirements

### Requirement: Endpoint routing DSL
`ActionDispatch::Routing::Mapper` SHALL provide an `endpoint` method that accepts an Endpoint class and generates RESTful routes.

#### Scenario: Full CRUD routing
- **WHEN** `endpoint PostsEndpoint` is declared in routes.rb
- **THEN** it SHALL generate GET /posts (index), GET /posts/:id (show), POST /posts (create), PATCH /posts/:id (update), DELETE /posts/:id (destroy)

#### Scenario: Routing with only filter
- **WHEN** `endpoint PostsEndpoint, only: [:index, :show]` is declared
- **THEN** it SHALL generate only GET /posts and GET /posts/:id

#### Scenario: Routing with except filter
- **WHEN** `endpoint PostsEndpoint, except: [:destroy]` is declared
- **THEN** it SHALL generate all routes except DELETE /posts/:id

#### Scenario: Custom path
- **WHEN** `endpoint PostsEndpoint, path: "articles"` is declared
- **THEN** routes SHALL use /articles and /articles/:id instead of /posts

### Requirement: Endpoint dispatch mechanism
Each generated route SHALL dispatch to the Endpoint instance method via a Rack-callable lambda that extracts params from the Rack env and request body.

#### Scenario: Params extraction
- **WHEN** a POST request to /posts with JSON body `{"post": {"title": "Hello"}}` is dispatched
- **THEN** the endpoint's `create` method SHALL receive params with `params[:post][:title] == "Hello"` and `params[:id]` from URL if present
