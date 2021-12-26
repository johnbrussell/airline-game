require "test_helper"

class GameTest < ActiveSupport::TestCase
  today = Date.today
  yesterday = today - 1
  tomorrow = today + 1

  test "user_airline finds the user airline" do
    subject = Game.create!(start_date: yesterday, end_date: tomorrow, current_date: today)

    airline_1 = Airline.create!(game_id: subject.id, cash_on_hand: 1, name: "foo", is_user_airline: true, base_id: 1)
    airline_2 = Airline.create!(game_id: subject.id, cash_on_hand: 1, name: "bar", is_user_airline: false, base_id: 1)

    subject.reload
    assert subject.user_airline.id == airline_1.id
  end

  test "current_date fails validation when less than start_date" do
    subject = Game.new(start_date: today, end_date: tomorrow, current_date: yesterday)

    assert_not(subject.save)
    assert_not(subject.valid?)
    assert_includes(subject.errors.map{ |error| "#{error.attribute} #{error.message}" }, "current_date cannot be less than start_date")
  end

  test "current_date fails validation when greater than end_date" do
    subject = Game.new(start_date: yesterday, end_date: today, current_date: tomorrow)

    assert_not(subject.save)
    assert_not(subject.valid?)
    assert_includes(subject.errors.map{ |error| "#{error.attribute} #{error.message}" }, "current_date cannot be greater than end_date")
  end

  test "current_date fails validation when start_date is greater than end_date" do
    subject_1 = Game.new(start_date: tomorrow, end_date: yesterday, current_date: today)
    subject_2 = Game.new(start_date: tomorrow, end_date: yesterday, current_date: yesterday)
    subject_3 = Game.new(start_date: tomorrow, end_date: yesterday, current_date: tomorrow)

    [subject_1, subject_2, subject_3].each do |subject|
      assert_not(subject.save)
      assert_not(subject.valid?)
    end

    assert_includes(subject_1.errors.map{ |error| "#{error.attribute} #{error.message}" }, "current_date cannot be less than start_date")
    assert_includes(subject_1.errors.map{ |error| "#{error.attribute} #{error.message}" }, "current_date cannot be greater than end_date")
    assert_includes(subject_2.errors.map{ |error| "#{error.attribute} #{error.message}" }, "current_date cannot be less than start_date")
    assert_includes(subject_3.errors.map{ |error| "#{error.attribute} #{error.message}" }, "current_date cannot be greater than end_date")
  end

  test "current_date does not fail validation when between start_date and end_date" do
    subject_1 = Game.new(start_date: yesterday, end_date: tomorrow, current_date: yesterday)
    subject_2 = Game.new(start_date: yesterday, end_date: tomorrow, current_date: today)
    subject_3 = Game.new(start_date: yesterday, end_date: tomorrow, current_date: tomorrow)

    [subject_1, subject_2, subject_3].each do |subject|
      assert(subject.valid?)
      assert(subject.save)
    end
  end
end
