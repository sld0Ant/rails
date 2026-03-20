# Enrollment — Behavioral Spec

## Contracts

  invariant: course_id is present
  invariant: student_id is present
  invariant: status in ["pending", "active", "cancelled"]

  # Enroll (create)
  pre:  course.status == "published"
  pre:  student not already enrolled in course
  pre:  course not full (enrollments_count < max_students, when max_students set)
  post: enrollment exists with status "pending"
  post: course.enrollments_count incremented by 1

## Authorization

| Action  | admin | instructor | student | guest |
|---------|-------|------------|---------|-------|
| index   | ✓     | own course | own     | ✗     |
| show    | ✓     | own course | own     | ✗     |
| create  | ✓     | ✗          | ✓       | ✗     |
| destroy | ✓     | ✗          | ✗       | ✗     |

## Lifecycle

  [pending] --activate--> [active] --cancel--> [cancelled]

  activate: pending → active (triggered by payment confirmation)
  cancel: active → cancelled (triggered by payment refund)

## Scenarios

  Given published course with max_students: 2 and 2 enrollments
  When student calls POST /enrollments with {course_id: X}
  Then 422, errors: ["Course is full"]

  Given course in status "draft"
  When student calls POST /enrollments with {course_id: X}
  Then 422, errors: ["Course is not published"]

  Given student already enrolled in course
  When student calls POST /enrollments with {course_id: X}
  Then 422, errors: ["Already enrolled"]

## Side Effects

  @on(create): increment course.enrollments_count
  @on(activate): send welcome email (future)
  @on(cancel): decrement course.enrollments_count
