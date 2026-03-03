FactoryBot.define do
  factory :plan do
    association :creator, factory: :user, strategy: :create
    name        { "Monthly" }
    price_cents { 1900 }
    interval    { :monthly }
    active      { true }
  end
end
