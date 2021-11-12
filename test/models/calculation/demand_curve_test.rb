require "test_helper"

class Calculation::DemandCurveTest < ActiveSupport::TestCase
  test "demand is zero for a business trip of zero miles" do
    subject = create_business_subject(0)
    expected = 0
    delta = 0.001

    assert_in_delta(subject.relative_demand, expected, delta)
  end

  test "demand is between 0 and 100 for a business trip between zero and SHORT_THRESHOLD_DISTANCE miles" do
    subject = create_business_subject(Calculation::DemandCurve::SHORT_THRESHOLD_DISTANCE / 2)

    assert 0 < subject.relative_demand
    assert subject.relative_demand < 100
  end

  test "demand is closer to zero for a short business trip than to 100 for a long business trip less than SHORT_THRESHOLD_DISTANCE" do
    distance_delta = Calculation::DemandCurve::SHORT_THRESHOLD_DISTANCE / 100
    short_subject = create_business_subject(distance_delta)
    long_subject = create_business_subject(Calculation::DemandCurve::SHORT_THRESHOLD_DISTANCE - distance_delta)

    short_difference = short_subject.relative_demand
    long_difference = 100 - long_subject.relative_demand

    assert short_difference < long_difference
  end

  test "demand is 100 for a business trip of SHORT_THRESHOLD_DISTANCE" do
    subject = create_business_subject(Calculation::DemandCurve::SHORT_THRESHOLD_DISTANCE)
    expected = 100
    delta = 0.001

    assert_in_delta(subject.relative_demand, expected, delta)
  end

  test "demand is 100 for a business trip between SHORT_THRESHOLD_DISTANCE and LONG_THRESHOLD_DISTANCE" do
    subject = create_business_subject((Calculation::DemandCurve::SHORT_THRESHOLD_DISTANCE + Calculation::DemandCurve::LONG_THRESHOLD_DISTANCE) / 2)
    expected = 100
    delta = 0.001

    assert_in_delta(subject.relative_demand, expected, delta)
  end

  test "demand is between 0 and 100 for a business trip longer than LONG_THRESHOLD_DISTANCE" do
    subject = create_business_subject(Calculation::DemandCurve::LONG_THRESHOLD_DISTANCE + 1)

    assert 0 < subject.relative_demand
    assert subject.relative_demand < 100
  end

  test "demand is between 0 and 100 for a business trip of half of the earth's circumference" do
    subject = create_business_subject(12500)

    assert 0 < subject.relative_demand
    assert subject.relative_demand < 100
  end

  test "demand is greater than 100 for an island business trip of shorter than SHORT_THRESHOLD_DISTANCE" do
    subject = create_business_subject(Calculation::DemandCurve::SHORT_THRESHOLD_DISTANCE / 2)

    assert 100 < subject.relative_demand_island
  end

  test "demand is equal to 100 for an island business trip of between SHORT_THRESHOLD_DISTANCE and LONG_THRESHOLD_DISTANCE" do
    subject = create_business_subject((Calculation::DemandCurve::SHORT_THRESHOLD_DISTANCE + Calculation::DemandCurve::LONG_THRESHOLD_DISTANCE) / 2)
    expected = 100
    delta = 0.001

    assert_in_delta(subject.relative_demand_island, expected, delta)
  end

  test "demand is less than 100 for an island business trip of more than LONG_THRESHOLD_DISTANCE" do
    subject = create_business_subject(Calculation::DemandCurve::LONG_THRESHOLD_DISTANCE + 1)

    assert 0 < subject.relative_demand_island
    assert subject.relative_demand_island < 100
  end

  def create_business_subject(distance)
    Calculation::DemandCurve.new(distance, :business)
  end
end
