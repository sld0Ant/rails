## ADDED Requirements

### Requirement: ApplicationEntity base class
The framework SHALL provide `ApplicationEntity` as a base class for domain entities. It SHALL include `ActiveModel::API`, `ActiveModel::Attributes`, and `ActiveModel::Serializers::JSON`. It SHALL define `persisted?` returning true when `id` is present.

#### Scenario: Entity with typed attributes
- **WHEN** a class inherits from `ApplicationEntity` and declares `attribute :title, :string`
- **THEN** the attribute SHALL support type casting, assignment, and `as_json` serialization

#### Scenario: Entity validations
- **WHEN** an entity declares `validates :title, presence: true` and `valid?` is called with blank title
- **THEN** `valid?` SHALL return false and `errors` SHALL contain the validation message

#### Scenario: Entity persisted state
- **WHEN** entity has `id` attribute set to a non-nil value
- **THEN** `persisted?` SHALL return true and `to_param` SHALL return the id as string

#### Scenario: Entity without id
- **WHEN** entity has no `id` or `id` is nil
- **THEN** `persisted?` SHALL return false
