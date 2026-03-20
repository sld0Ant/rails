# Lesson — Behavioral Spec

## Contracts

  invariant: title is present
  invariant: course_id is present
  invariant: position >= 1
  invariant: duration_minutes > 0

## Authorization

| Action  | admin | instructor | student          | guest            |
|---------|-------|------------|------------------|------------------|
| index   | ✓     | own course | published course | published course |
| show    | ✓     | own course | published course | published course |
| create  | ✓     | own course | ✗                | ✗                |
| update  | ✓     | own course | ✗                | ✗                |
| destroy | ✓     | own course | ✗                | ✗                |

## Scenarios

  Given course in status "archived"
  When instructor calls POST /lessons with {course_id: X, title: "New"}
  Then 422, "Cannot add lessons to archived course"
