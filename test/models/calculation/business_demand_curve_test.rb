require "test_helper"

class Calculation::BusinessDemandCurveTest < ActiveSupport::TestCase
  test "demand is zero for a trip of zero miles" do
    subject = create_subject(0)
    expected = 0
    delta = 0.001

    assert_in_delta(subject.relative_demand, expected, delta)
  end

  test "demand is between 0 and 100 for a trip between zero and SHORT_THRESHOLD_DISTANCE miles" do
    subject = create_subject(Calculation::BusinessDemandCurve::SHORT_THRESHOLD_DISTANCE / 2)

    assert 0 < subject.relative_demand
    assert subject.relative_demand < 100
  end

  test "demand is closer to zero for a short trip than to 100 for a long trip less than SHORT_THRESHOLD_DISTANCE" do
    distance_delta = Calculation::BusinessDemandCurve::SHORT_THRESHOLD_DISTANCE / 100
    short_subject = create_subject(distance_delta)
    long_subject = create_subject(Calculation::BusinessDemandCurve::SHORT_THRESHOLD_DISTANCE - distance_delta)

    short_difference = short_subject.relative_demand
    long_difference = 100 - long_subject.relative_demand

    assert short_difference < long_difference
  end

  test "demand is 100 for a trip of SHORT_THRESHOLD_DISTANCE" do
    subject = create_subject(Calculation::BusinessDemandCurve::SHORT_THRESHOLD_DISTANCE)
    expected = 100
    delta = 0.001

    assert_in_delta(subject.relative_demand, expected, delta)
  end

  test "demand is 100 for a trip between SHORT_THRESHOLD_DISTANCE and LONG_THRESHOLD_DISTANCE" do
    subject = create_subject((Calculation::BusinessDemandCurve::SHORT_THRESHOLD_DISTANCE + Calculation::BusinessDemandCurve::LONG_THRESHOLD_DISTANCE) / 2)
    expected = 100
    delta = 0.001

    assert_in_delta(subject.relative_demand, expected, delta)
  end

  test "demand is between 0 and 100 for a trip longer than LONG_THRESHOLD_DISTANCE" do
    subject = create_subject(Calculation::BusinessDemandCurve::LONG_THRESHOLD_DISTANCE + 1)

    assert 0 < subject.relative_demand
    assert subject.relative_demand < 100
  end

  test "demand is between 0 and 100 for a trip of half of the earth's circumference" do
    subject = create_subject(12500)

    assert 0 < subject.relative_demand
    assert subject.relative_demand < 100
  end

  test "demand is greater than 100 for an island trip of shorter than SHORT_THRESHOLD_DISTANCE" do
    subject = create_subject(Calculation::BusinessDemandCurve::SHORT_THRESHOLD_DISTANCE / 2)

    assert 100 < subject.relative_demand_island
  end

  test "demand is equal to 100 for an island trip of between SHORT_THRESHOLD_DISTANCE and LONG_THRESHOLD_DISTANCE" do
    subject = create_subject((Calculation::BusinessDemandCurve::SHORT_THRESHOLD_DISTANCE + Calculation::BusinessDemandCurve::LONG_THRESHOLD_DISTANCE) / 2)
    expected = 100
    delta = 0.001

    assert_in_delta(subject.relative_demand_island, expected, delta)
  end

  test "demand is less than 100 for an island trip of more than LONG_THRESHOLD_DISTANCE" do
    subject = create_subject(Calculation::BusinessDemandCurve::LONG_THRESHOLD_DISTANCE + 1)

    assert 0 < subject.relative_demand_island
    assert subject.relative_demand_island < 100
  end

  def create_subject(distance)
    Calculation::BusinessDemandCurve.new(distance)
  end
end
