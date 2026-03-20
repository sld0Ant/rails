# Course — Behavioral Spec

## Contracts

  invariant: title is present
  invariant: status in ["draft", "published", "archived"]
  invariant: price_cents >= 0
  invariant: max_students > 0 (when present)
  invariant: organization_id is present
  invariant: instructor_id is present

  # Publish
  pre:  status == "draft"
  pre:  course has at least 1 lesson
  post: status == "published"

  # Archive
  pre:  status in ["draft", "published"]
  post: status == "archived"

## Authorization

| Action  | admin | instructor      | student   | guest     |
|---------|-------|-----------------|-----------|-----------|
| index   | ✓     | ✓               | published | published |
| show    | ✓     | own + published | published | published |
| create  | ✓     | ✓               | ✗         | ✗         |
| update  | ✓     | own             | ✗         | ✗         |
| destroy | ✓     | own+draft       | ✗         | ✗         |
| publish | ✓     | own             | ✗         | ✗         |
| archive | ✓     | own             | ✗         | ✗         |

## Lifecycle

  [draft] --publish--> [published] --archive--> [archived]
                                                    ^
  [draft] --archive------------------------------------

  publish: draft → published, guard: at least 1 lesson
  archive: draft|published → archived, no guard

## Scenarios

  Given course in status "draft" with 0 lessons
  When instructor calls POST /courses/:id/publish
  Then 422, errors: ["At least one lesson required"]

  Given course in status "archived"
  When instructor calls PATCH /courses/:id with {title: "New"}
  Then 403, "Can only update draft or published courses"

  Given course in status "published"
  When student calls GET /courses/:id
  Then 200, course data returned

  Given course in status "draft"
  When guest calls GET /courses/:id
  Then 404

## Side Effects

  @on(publish): increment counter cache or future notification hook
