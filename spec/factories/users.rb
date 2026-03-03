FactoryBot.define do
  factory :user do
    first_name { Faker::Name.first_name }
    last_name  { Faker::Name.last_name }
    sequence(:username) { |n| "user#{n}" }
    sequence(:email)    { |n| "user#{n}@example.com" }
    password            { "password123" }
    password_confirmation { "password123" }
    admin               { false }

    trait :admin do
      admin { true }
    end

    trait :subscriber do
      after(:create) do |user|
        create(:subscription, subscriber: user, status: :active)
      end
    end
  end
end
