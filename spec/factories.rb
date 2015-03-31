# Read about factories at https://github.com/thoughtbot/factory_girl

# TODO why is this here?
include ActionDispatch::TestProcess

FactoryGirl.define do

  factory :venue do
    title 'Series title'
    user
  end

  sequence :email do |n|
    "hans#{n}@example.com"
  end

  # the default user is a confirmed user, if you need an unconfirmed
  # user use the trait `unconfirmed`, as in...
  #
  #   FactoryGirl.create(:user, :unconfirmed)
  #
  factory :user do
    ignore do
      unconfirmed false
    end

    firstname 'Hans'
    lastname 'Hanebambel'
    email
    last_request_at { Time.now }
    password secret = "mysecret"
    password_confirmation secret
    timezone 'Berlin'

    trait :unconfirmed do
      unconfirmed true
    end

    after :create do |user, evaluator|
      user.confirm! unless evaluator.unconfirmed
    end
  end

  factory :comment do
    content 'Lots of content here'
    user
    association :commentable, factory: :venue
  end

  factory :participation do
    venue
    user
  end

  factory :talk do
    title "Some awesome title"
    venue
    # NOTE: times set here are not affected by `Timecop.freeze` in a
    # `before` block
    starts_at_time 1.hour.from_now.strftime('%H:%M')
    starts_at_date 1.hour.from_now.strftime('%Y-%m-%d')
    duration 60
    collect false
    tag_list 'lorem, ipsum, dolor'
    description 'Some talk description'
    language 'en'

    trait :archived do
      state 'archived'
      processed_at { 2.hours.ago }
    end

    trait :featured do
      featured_from { 1.day.ago }
    end

    trait :popular do
      play_count 25
    end
  end

  factory :appearance do
    user
    talk
  end

  factory :message do
    user
    talk
    content "MyText"
  end

  factory :setting do
    key "MyString"
    value "MyString"
  end

  factory :tag, :class => ActsAsTaggableOn::Tag do |f|
    f.sequence(:name) { |n| "tag_#{n}" }
  end

  factory :reminder do
    user
    rememberable nil
  end


  factory :purchase do
    owner factory: :user
    quantity 10
  end

  factory :purchase_transaction do
    association :source, factory: :purchase
  end

end
