# Задание

Прочитай инструкцию из файла `~/Projects/rb-ru/docs/llm-guide.md` — это описание фреймворка DDD Rails и пошаговый процесс разработки. Выполни по ней задание ниже.

Шаг 1 (домен) — не спрашивай, домен описан ниже.
Шаг 2 — напиши behavioral specs в `docs/behavior/`.
Шаг 3 — собери `docs/ir.json` из спек.
Шаг 4 — создай приложение и сгенерируй код.
Шаг 5 — добавь бизнес-логику по спекам.

---

## Домен: платформа онлайн-курсов (production)

Создай приложение в `/tmp/course-platform-full`.

### Ресурсы (14)

**1. Organization** — школа/компания
- name (string, обязательное)
- slug (string, обязательное, уникальное)
- plan (string: free/pro/enterprise)
- max_courses (integer, nullable) — лимит по плану
- max_students (integer, nullable) — лимит по плану
- logo_url (string, nullable)

**2. Category** — рубрика курсов, глобальная (без organization_id, общая для всех), максимум 1 уровень вложенности
- name (string, обязательное)
- slug (string, обязательное)
- parent_id (integer, optional → belongs_to Category, self-referential)
- position (integer)
- Валидация: если parent_id задан, parent.parent_id должен быть nil (нельзя вкладывать глубже 1 уровня)

**3. Instructor** — преподаватель
- organization_id (belongs_to Organization)
- name (string, обязательное)
- email (string, обязательное, формат email)
- bio (text, nullable)
- avatar_url (string, nullable)

**4. Student** — ученик
- organization_id (belongs_to Organization)
- name (string, обязательное)
- email (string, обязательное, формат email)
- avatar_url (string, nullable)

**5. Course** — курс
- organization_id (belongs_to Organization)
- instructor_id (belongs_to Instructor)
- category_id (belongs_to Category, optional)
- title (string, обязательное)
- description (text, nullable)
- price_cents (integer, default 0, >= 0)
- currency (string, default "USD")
- max_students (integer, nullable, > 0 если задан)
- enrollments_count (integer, default 0, readonly)
- average_rating (decimal, nullable, readonly)
- status (string: draft/published/archived, default draft)
- published_at (datetime, nullable, readonly)

**6. Module** — секция/раздел внутри курса
- course_id (belongs_to Course)
- title (string, обязательное)
- position (integer, >= 1)

**7. Lesson** — урок (принадлежит Module, не Course)
- module_id (belongs_to Module)
- title (string, обязательное)
- content (text, nullable)
- lesson_type (string: video/text/quiz, default text)
- video_url (string, nullable)
- position (integer, >= 1)
- duration_minutes (integer, nullable, > 0 если задан)

**8. Enrollment** — запись студента на курс
- course_id (belongs_to Course)
- student_id (belongs_to Student)
- status (string: active/completed/cancelled, default active)
- progress_percent (integer, default 0, 0..100, readonly)
- enrolled_at (datetime, readonly — устанавливается при создании)
- completed_at (datetime, nullable, readonly)
- Нет update endpoint. Нет destroy endpoint (используй cancel transition). Admin может удалить через cascade при необходимости.

**9. LessonProgress** — прогресс студента по отдельному уроку
- enrollment_id (belongs_to Enrollment)
- lesson_id (belongs_to Lesson)
- status (string: not_started/started/completed, default not_started)
- started_at (datetime, nullable)
- completed_at (datetime, nullable)
- Уникальность: enrollment_id + lesson_id

**10. Review** — отзыв на курс
- course_id (belongs_to Course)
- student_id (belongs_to Student)
- rating (integer, 1..5)
- body (text, nullable)
- Уникальность: course_id + student_id (один отзыв от студента на курс)

**11. Payment** — оплата за запись
- enrollment_id (belongs_to Enrollment)
- coupon_id (belongs_to Coupon, optional)
- amount_cents (integer, > 0)
- net_amount_cents (integer, >= 0, readonly — вычисляется)
- currency (string)
- status (string: pending/confirmed/refunded, default pending)
- paid_at (datetime, nullable, readonly)
- refunded_at (datetime, nullable, readonly)

**12. Certificate** — сертификат о прохождении (создаётся автоматически при completion, не вручную)
- enrollment_id (belongs_to Enrollment)
- certificate_number (string, UUID v4, readonly)
- issued_at (datetime, readonly)
- Нет endpoint для create — только read и destroy(admin)

**13. Coupon** — промокод
- code (string, обязательное, уникальное)
- discount_type (string: percent/fixed)
- discount_value (integer, > 0) — проценты (1-100) или фикс. сумма в центах
- currency (string, nullable) — обязательно для fixed, не нужно для percent
- min_purchase_cents (integer, nullable) — мин. сумма для применения
- max_uses (integer, nullable) — nil = безлимит
- used_count (integer, default 0, readonly)
- starts_at (datetime)
- expires_at (datetime)
- active (boolean, default true)

**14. Notification** — уведомление (запись в БД, без реальной отправки)
- student_id (belongs_to Student, optional)
- instructor_id (belongs_to Instructor, optional)
- event_type (string: enrollment/publish/payment/certificate)
- title (string)
- body (text, nullable)
- read_at (datetime, nullable)
- Инвариант: ровно один из student_id/instructor_id заполнен (custom validation)

---

### Lifecycle (state machines)

**Course:**

    [draft] --publish--> [published] --archive--> [archived]
      \                                             /
       `--archive--> [archived]  (из draft тоже можно)

Нет возврата из archived.

**Enrollment:**

    [active] --complete--> [completed]   (автоматический, при 100% progress)
    [active] --cancel--> [cancelled]     (ручной, студент или admin)

Completed и cancelled — финальные. Completed enrollment нельзя отменить.

**Payment:**

    [pending] --confirm--> [confirmed] --refund--> [refunded]

Нет возврата.

**LessonProgress:** Без state machine. Status меняется через обычный update:
- not_started → started (при первом открытии)
- started → completed (при завершении)

---

### Бизнес-правила

#### Organization — лимиты по плану

| Plan       | max_courses | max_students |
|------------|-------------|--------------|
| free       | 3           | 100          |
| pro        | 50          | 5000         |
| enterprise | nil         | nil          |

При создании Organization поля max_courses/max_students устанавливаются автоматически по плану. Admin может изменить вручную (override). Лимиты проверяются при публикации Course и создании Enrollment.

#### Course — publish guards

Все условия должны быть выполнены:
1. `description` не пустое
2. Хотя бы 1 Module
3. В каждом Module хотя бы 1 Lesson
4. Организация не превысила лимит `max_courses` (считать только published курсы)

При успешной публикации: `published_at = Time.current`

#### Course — archive

- Из draft или published
- Активные enrollments остаются — студенты доучиваются
- Новые enrollments запрещены (проверяется в enrollment create)

#### Course — instructor_id

- Если роль instructor: `instructor_id` автоматически = текущий user (X-User-Id)
- Если роль admin: может указать любого instructor

#### Course — delete

- Нельзя удалить если есть enrollments (любого статуса)
- Admin может удалить draft без enrollments
- Instructor может удалить только свой draft без enrollments

#### Enrollment — create guards

1. Курс `published` (не draft, не archived)
2. Студент не записан дважды (нет active/completed enrollment на этот курс). Cancelled enrollment не блокирует — re-enroll разрешён.
3. Курс не полный: `enrollments_count < max_students` (если max_students задан)
4. Организация не превысила `max_students` (считать уникальных студентов)
5. При роли student: `student_id` = текущий user (X-User-Id)
6. `enrolled_at = Time.current`, `progress_percent = 0`, `status = active`
7. `enrollments_count += 1` — атомарно через `UPDATE courses SET enrollments_count = enrollments_count + 1 WHERE id = ?`

#### Enrollment — cancel

- Только из `active` (completed нельзя отменить)
- Если есть Payment со status `confirmed` → ошибка: "Refund payment before cancelling"
- Pending payments автоматически не отменяются — студент должен разобраться с ними отдельно (за рамками MVP)
- Cancelled enrollment разрешает повторную запись (re-enroll)
- `enrollments_count -= 1` — атомарно через SQL

#### Enrollment — auto-completion

Триггерится из LessonProgress service при пересчёте progress_percent:
- Когда `progress_percent == 100`: `status → completed`, `completed_at = Time.current`
- Автоматически создаётся Certificate: `certificate_number = SecureRandom.uuid`, `issued_at = Time.current`
- Notification студенту: "Certificate issued for {course.title}"

#### LessonProgress

- Уникальность: `enrollment_id + lesson_id`
- Студент создаёт (POST): `status = started`, `started_at = Time.current`
- Студент обновляет (PATCH): `status = completed`, `completed_at = Time.current`
  - Нельзя вернуть из completed в started
- При каждом complete: пересчитать `enrollment.progress_percent`:
  ```
  completed = LessonProgressRecord.where(enrollment_id: ..., status: "completed").count
  total = LessonRecord.joins(:module).where(modules: { course_id: course.id }).count
  progress = (completed * 100) / total
  ```
  Использовать SQL COUNT (idempotent, без race condition).
- Если `progress_percent == 100` → авто-завершить enrollment (см. выше)

#### Review

- Студент enrolled (status IN: `active`, `completed`). Cancelled — нельзя.
- Один отзыв на курс от студента (uniqueness: course_id + student_id)
- `rating` 1..5
- При create/update/destroy → пересчитать `course.average_rating`:
  ```
  AVG(reviews.rating) WHERE course_id = ?
  ```
  Через SQL AVG (idempotent). Если нет отзывов → `average_rating = nil`.

#### Payment — create

- Payment не обязателен для enrollment (enrollment и payment — независимые операции)
- Нельзя создать payment для бесплатного курса (`course.price_cents == 0` или nil) → ошибка "Course is free"
- Нельзя создать second pending/confirmed payment для одного enrollment (один активный payment за раз)
- `amount_cents = course.price_cents`
- `currency = course.currency`
- Если `coupon_id` указан, валидировать купон:
  1. `coupon.active == true`
  2. `Time.current` между `coupon.starts_at` и `coupon.expires_at`
  3. `coupon.used_count < coupon.max_uses` (если max_uses задан)
  4. `amount_cents >= coupon.min_purchase_cents` (если min_purchase_cents задан)
  5. Для `discount_type: fixed` → `coupon.currency == course.currency`. Для percent → без проверки валюты.
- Вычислить `net_amount_cents`:
  - percent: `amount_cents - (amount_cents * coupon.discount_value / 100)`
  - fixed: `amount_cents - coupon.discount_value`
  - Минимум 0: `[result, 0].max`
- `coupon.used_count += 1` — атомарно через SQL
- Один купон может быть использован разными студентами (ограничение только через `max_uses`)
- Если `net_amount_cents == 0`: создать payment сразу в `status: confirmed`, `paid_at: Time.current` (авто-подтверждение бесплатной оплаты)
- Иначе: `status: pending`

#### Payment — confirm

- `paid_at = Time.current`

#### Payment — refund

- `refunded_at = Time.current`
- Если был coupon: `coupon.used_count -= 1` — атомарно через SQL

#### Notification — side effects

Все notification — записи в БД (не реальная отправка):
- `@on(enrollment.create)`: student notification, event: "enrollment", title: "Enrolled in {course.title}"
- `@on(course.publish)`: instructor notification, event: "publish", title: "Course {course.title} published"
- `@on(payment.confirm)`: student notification, event: "payment", title: "Payment confirmed for {course.title}"
- `@on(certificate.create)`: student notification, event: "certificate", title: "Certificate issued for {course.title}"

#### Notification — mark as read

Custom action: `PATCH /notifications/:id/mark_read` → `read_at = Time.current`. Односторонняя операция.

#### Cascade delete

- Organization destroy: restrict (нельзя удалить если есть курсы/инструкторы/студенты)
- Category destroy: nullify (course.category_id = nil)
- Course destroy: restrict (нельзя если есть enrollments)
- Module destroy: cascade (удалить уроки)
- Instructor destroy: restrict (нельзя если есть курсы)
- Student destroy: restrict (нельзя если есть enrollments)
- Enrollment destroy: cascade (удалить lesson_progress, payments, certificate)
- Coupon destroy: restrict (нельзя если есть payments)

---

### Авторизация

Роль: заголовок `X-User-Role` (admin / instructor / student / guest).
ID: заголовок `X-User-Id` (integer). Для guest — отсутствует или игнорируется. Отдельной модели User нет.

**Определения scope:**
- `own` для instructor: `instructor_id == X-User-Id`
- `own` для student: `student_id == X-User-Id`
- `own org`: `resource.organization_id == current_user.organization_id`
- `own course(s)`: ресурс принадлежит курсу текущего инструктора (через цепочку)
- `own enrollment`: `enrollment.student_id == X-User-Id`
- `enrolled`: у студента есть enrollment.status IN (active, completed) на этот курс
- `published`: course.status == "published". Для Module: module.course.status == "published". Для Lesson: lesson.module.course.status == "published"
- `enrolled` для Module/Lesson: у студента есть enrollment (active/completed) на lesson.module.course (или module.course)
- `own OR published` (для Course.show instructor): видит свои любые + чужие опубликованные
- `own AND draft` (для Course.destroy instructor): удалить может только свой черновик

| Resource       | Action    | admin | instructor      | student         | guest      |
|----------------|-----------|-------|-----------------|-----------------|------------|
| Organization   | index     | ✓     | ✗               | ✗               | ✗          |
| Organization   | show      | ✓     | own org         | own org         | ✗          |
| Organization   | CUD       | ✓     | ✗               | ✗               | ✗          |
| Category       | read      | ✓     | ✓               | ✓               | ✓          |
| Category       | CUD       | ✓     | ✗               | ✗               | ✗          |
| Instructor     | read      | ✓     | ✓               | ✓               | ✓          |
| Instructor     | create    | ✓     | ✗               | ✗               | ✗          |
| Instructor     | update    | ✓     | own             | ✗               | ✗          |
| Instructor     | destroy   | ✓     | ✗               | ✗               | ✗          |
| Student        | index     | ✓     | ✓               | ✗               | ✗          |
| Student        | show      | ✓     | ✓               | own             | ✗          |
| Student        | create    | ✓     | ✗               | ✗               | ✗          |
| Student        | update    | ✓     | ✗               | own             | ✗          |
| Student        | destroy   | ✓     | ✗               | ✗               | ✗          |
| Course         | index     | ✓     | ✓               | published       | published  |
| Course         | show      | ✓     | own OR published| published       | published  |
| Course         | create    | ✓     | ✓               | ✗               | ✗          |
| Course         | update    | ✓     | own             | ✗               | ✗          |
| Course         | destroy   | ✓     | own AND draft   | ✗               | ✗          |
| Course         | publish   | ✓     | own             | ✗               | ✗          |
| Course         | archive   | ✓     | own             | ✗               | ✗          |
| Module         | read      | ✓     | ✓               | enrolled        | published  |
| Module         | CUD       | ✓     | own course      | ✗               | ✗          |
| Lesson         | read      | ✓     | ✓               | enrolled        | published  |
| Lesson         | CUD       | ✓     | own course      | ✗               | ✗          |
| Enrollment     | index     | ✓     | own courses     | own             | ✗          |
| Enrollment     | show      | ✓     | own courses     | own             | ✗          |
| Enrollment     | create    | ✓     | ✗               | ✓               | ✗          |
| Enrollment     | cancel    | ✓     | ✗               | own             | ✗          |
| LessonProgress | read      | ✓     | own courses     | own enrollment  | ✗          |
| LessonProgress | create    | ✓     | ✗               | own enrollment  | ✗          |
| LessonProgress | update    | ✓     | ✗               | own enrollment  | ✗          |
| Review         | read      | ✓     | ✓               | ✓               | published  |
| Review         | create    | ✓     | ✗               | enrolled        | ✗          |
| Review         | update    | ✓     | ✗               | own             | ✗          |
| Review         | destroy   | ✓     | ✗               | own             | ✗          |
| Payment        | index     | ✓     | ✗               | own (via enroll)| ✗          |
| Payment        | show      | ✓     | ✗               | own (via enroll)| ✗          |
| Payment        | create    | ✓     | ✗               | ✓               | ✗          |
| Payment        | confirm   | ✓     | ✗               | ✗               | ✗          |
| Payment        | refund    | ✓     | ✗               | ✗               | ✗          |
| Certificate    | read      | ✓     | own courses     | own (via enroll)| ✗          |
| Certificate    | destroy   | ✓     | ✗               | ✗               | ✗          |
| Coupon         | all       | ✓     | ✗               | ✗               | ✗          |
| Notification   | index     | ✓     | own             | own             | ✗          |
| Notification   | show      | ✓     | own             | own             | ✗          |
| Notification   | mark_read | ✓     | own             | own             | ✗          |

"own (via enroll)" = `payment.enrollment.student_id == X-User-Id` (или certificate через ту же цепочку)

---

### Collection config

Все ресурсы top-level (не nested). Вложенность через filter (например `GET /lessons?filter[module_id]=5`).

| Resource       | Sort                              | Filter                                       | Search             | Per page |
|----------------|-----------------------------------|----------------------------------------------|--------------------|----------|
| Organization   | name, created_at                  | plan                                         | —                  | 20       |
| Category       | position, name                    | parent_id                                    | —                  | 50       |
| Instructor     | name, created_at                  | organization_id                              | name, email        | 20       |
| Student        | name, created_at                  | organization_id                              | name, email        | 25       |
| Course         | title, price_cents, created_at, average_rating | status, category_id, instructor_id, organization_id | title, description | 20 |
| Module         | position                          | course_id                                    | —                  | 50       |
| Lesson         | position                          | module_id                                    | title              | 50       |
| Enrollment     | created_at, progress_percent      | course_id, student_id, status                | —                  | 25       |
| LessonProgress | created_at                        | enrollment_id, lesson_id, status             | —                  | 50       |
| Review         | rating, created_at                | course_id, student_id, rating                | —                  | 10       |
| Payment        | created_at, amount_cents          | enrollment_id, status                        | —                  | 20       |
| Certificate    | issued_at                         | enrollment_id                                | —                  | 20       |
| Coupon         | created_at, expires_at            | active, discount_type                        | code               | 20       |
| Notification   | created_at                        | event_type, read                             | —                  | 25       |

`read` в фильтре Notification = boolean (read_at IS NOT NULL).

---

### Роли и сценарии (для тестирования)

Прогони полный end-to-end сценарий:

1. Admin создаёт Organization (pro plan), Category, Instructor, 2 Students
2. Instructor создаёт Course (draft, price_cents: 5000, currency: USD), 2 Module, 3 Lesson в каждом
3. Instructor пытается publish → ошибка (нет description)
4. Instructor обновляет description, publish → 200
5. Admin создаёт Coupon (20% off, max_uses: 5)
6. Student1 создаёт Enrollment → 201, enrollments_count = 1
7. Student1 создаёт Payment с купоном → net_amount_cents = 4000, coupon.used_count = 1
8. Admin confirm payment → paid_at заполнен, notification студенту
9. Student1 пытается cancel enrollment → ошибка "Refund payment before cancelling"
10. Admin refund payment → coupon.used_count = 0
11. Student1 cancel enrollment → 200, enrollments_count = 0
12. Student1 повторно создаёт Enrollment (re-enroll) → 201, enrollments_count = 1 (cancelled не блокирует)
13. Student2 создаёт Enrollment → enrollments_count = 2
14. Student2 проходит все 6 уроков: для каждого POST LessonProgress (started), PATCH (completed)
15. При последнем complete → progress_percent = 100, enrollment auto-completes, certificate создаётся, notification
16. Student2 пытается cancel → ошибка (enrollment completed, нельзя отменить)
17. Student2 создаёт Review (rating: 5) → course.average_rating = 5.0
18. Instructor archive course
19. Попытка создать Enrollment на archived course → ошибка
20. Instructor создаёт второй Course (price_cents: 0, description: "Free intro"), Module, Lesson, publish → 200
21. Student1 создаёт Enrollment на бесплатный курс → 201
22. Student1 пытается создать Payment → ошибка "Course is free"

Пройди весь путь: спеки → IR → генерация → бизнес-логика → тестирование.
