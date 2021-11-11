require "test_helper"

class GlobalDemandTest < ActiveSupport::TestCase
  actual_date = "2021-11-11".to_date
  subject = GlobalDemand.new(date: actual_date)

  test "out_of_date_from? is true when the test date is too far in the future" do
    test_date = actual_date + GlobalDemand::OUT_OF_DATE_DISTANCE_DAYS + 1.day

    assert subject.out_of_date_from?(test_date)
  end

  test "out_of_date_from? is true when the test date is too far in the past" do
    test_date = actual_date - GlobalDemand::OUT_OF_DATE_DISTANCE_DAYS - 1.day

    assert subject.out_of_date_from?(test_date)
  end

  test "out_of_date_from? is false for close future dates" do
    test_date = actual_date + GlobalDemand::OUT_OF_DATE_DISTANCE_DAYS - 1.day

    assert_not subject.out_of_date_from?(test_date)
  end

  test "out_of_date_from? is false for recent past dates" do
    test_date = actual_date - GlobalDemand::OUT_OF_DATE_DISTANCE_DAYS + 1.day

    assert_not subject.out_of_date_from?(test_date)
  end
end
