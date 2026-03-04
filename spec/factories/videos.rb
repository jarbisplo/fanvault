FactoryBot.define do
  factory :video do
    association :creator, factory: :user, strategy: :create
    title       { Faker::Lorem.sentence(word_count: 4).chomp('.') }
    description { Faker::Lorem.paragraph }
    status      { :published }
    visibility  { :subscribers_only }
    category    { :physical_training }
    duration_seconds { 300 }
    free             { false }

    # Skip file-presence validation in tests — we're not testing uploads here
    to_create { |instance| instance.save!(validate: false) }
  end
end
