# Review — Behavioral Spec

## Contracts

  invariant: rating in 1..5
  invariant: course_id is present
  invariant: student_id is present

  # Create review
  pre:  student is enrolled in course
  pre:  student has not already reviewed this course
  post: review exists

## Authorization

| Action  | admin | instructor | student | guest |
|---------|-------|------------|---------|-------|
| index   | ✓     | ✓          | ✓       | ✓     |
| show    | ✓     | ✓          | ✓       | ✓     |
| create  | ✗     | ✗          | ✓       | ✗     |
| update  | ✓     | ✗          | own     | ✗     |
| destroy | ✓     | ✗          | own     | ✗     |

## Scenarios

  Given student NOT enrolled in course
  When student calls POST /reviews with {course_id: X, rating: 5}
  Then 422, errors: ["Must be enrolled in course"]

  Given student already reviewed course
  When student calls POST /reviews with {course_id: X, rating: 4}
  Then 422, errors: ["Already reviewed this course"]

  Given student enrolled in course
  When student calls POST /reviews with {course_id: X, rating: 0}
  Then 422, errors: ["Rating must be between 1 and 5"]
