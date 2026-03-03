FactoryBot.define do
  factory :subscription do
    association :creator,    factory: :user, strategy: :create
    association :subscriber, factory: :user, strategy: :create
    association :plan,       factory: :plan, strategy: :create
    status { :active }
    kind   { :paid }
    current_period_end { 1.month.from_now }
  end
end
