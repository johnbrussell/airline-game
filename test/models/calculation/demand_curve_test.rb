require "test_helper"

class Calculation::DemandCurveTest < ActiveSupport::TestCase
  test "demand is zero for a business trip of zero miles" do
    subject = create_business_subject(0)
    expected = 0
    delta = 0.001

    assert_in_delta(subject.relative_demand(0), expected, delta)
  end

  test "demand is between 0 and 100 for a business trip between zero and SHORT_THRESHOLD_DISTANCE miles" do
    distance = Calculation::DemandCurve::SHORT_THRESHOLD_DISTANCES.fetch(:business) / 2
    subject = create_business_subject(distance)

    assert 0 < subject.relative_demand(distance)
    assert subject.relative_demand(distance) < 100
  end

  test "demand is closer to zero for a short business trip than to 100 for a long business trip less than SHORT_THRESHOLD_DISTANCE" do
    distance_delta = Calculation::DemandCurve::SHORT_THRESHOLD_DISTANCES.fetch(:business) / 100
    short_subject = create_business_subject(distance_delta)
    long_subject = create_business_subject(Calculation::DemandCurve::SHORT_THRESHOLD_DISTANCES.fetch(:business) - distance_delta)

    short_difference = short_subject.relative_demand(distance_delta)
    long_difference = 100 - long_subject.relative_demand(Calculation::DemandCurve::SHORT_THRESHOLD_DISTANCES.fetch(:business) - distance_delta)

    assert short_difference < long_difference
  end

  test "demand is 100 for a business trip of SHORT_THRESHOLD_DISTANCE" do
    distance = Calculation::DemandCurve::SHORT_THRESHOLD_DISTANCES.fetch(:business)
    subject = create_business_subject(distance)
    expected = 100
    delta = 0.001

    assert_in_delta(subject.relative_demand(distance), expected, delta)
  end

  test "demand is 100 for a business trip between SHORT_THRESHOLD_DISTANCE and LONG_THRESHOLD_DISTANCE" do
    distance = (Calculation::DemandCurve::SHORT_THRESHOLD_DISTANCES.fetch(:business) + Calculation::DemandCurve::LONG_THRESHOLD_DISTANCES.fetch(:business)) / 2
    subject = create_business_subject(distance)
    expected = 100
    delta = 0.001

    assert_in_delta(subject.relative_demand(distance), expected, delta)
  end

  test "demand is between 0 and 100 for a business trip longer than LONG_THRESHOLD_DISTANCE" do
    distance = Calculation::DemandCurve::LONG_THRESHOLD_DISTANCES.fetch(:business) + 1
    subject = create_business_subject(distance)

    assert 0 < subject.relative_demand(distance)
    assert subject.relative_demand(distance) < 100
  end

  test "demand is between 0 and 100 for a business trip of half of the earth's circumference" do
    subject = create_business_subject(12500)

    assert 0 < subject.relative_demand(12500)
    assert subject.relative_demand(12500) < 100
  end

  test "demand is greater than 100 for an island business trip of shorter than SHORT_THRESHOLD_DISTANCE" do
    distance = Calculation::DemandCurve::SHORT_THRESHOLD_DISTANCES.fetch(:business) / 2
    subject = create_business_subject(distance)

    assert 100 < subject.relative_demand_island(distance)
  end

  test "demand is equal to 100 for an island business trip of between SHORT_THRESHOLD_DISTANCE and LONG_THRESHOLD_DISTANCE" do
    distance = (Calculation::DemandCurve::SHORT_THRESHOLD_DISTANCES.fetch(:business) + Calculation::DemandCurve::LONG_THRESHOLD_DISTANCES.fetch(:business)) / 2
    subject = create_business_subject(distance)
    expected = 100
    delta = 0.001

    assert_in_delta(subject.relative_demand_island(distance), expected, delta)
  end

  test "demand is less than 100 for an island business trip of more than LONG_THRESHOLD_DISTANCE" do
    distance = Calculation::DemandCurve::LONG_THRESHOLD_DISTANCES.fetch(:business) + 1
    subject = create_business_subject(distance)

    assert 0 < subject.relative_demand_island(distance)
    assert subject.relative_demand_island(distance) < 100
  end

  test "demand is zero for a leisure trip of zero miles" do
    subject = create_leisure_subject(0)
    expected = 0
    delta = 0.001

    assert_in_delta(subject.relative_demand(0), expected, delta)
  end

  test "demand is between 0 and 100 for a leisure trip between zero and SHORT_THRESHOLD_DISTANCE miles" do
    distance = Calculation::DemandCurve::SHORT_THRESHOLD_DISTANCES.fetch(:leisure) / 2
    subject = create_leisure_subject(distance)

    assert 0 < subject.relative_demand(distance)
    assert subject.relative_demand(distance) < 100
  end

  test "demand is closer to zero for a short leisure trip than to 100 for a long leisure trip less than SHORT_THRESHOLD_DISTANCE" do
    distance_delta = Calculation::DemandCurve::SHORT_THRESHOLD_DISTANCES.fetch(:leisure) / 100
    short_subject = create_leisure_subject(distance_delta)
    long_subject = create_leisure_subject(Calculation::DemandCurve::SHORT_THRESHOLD_DISTANCES.fetch(:leisure) - distance_delta)

    short_difference = short_subject.relative_demand(distance_delta)
    long_difference = 100 - long_subject.relative_demand(Calculation::DemandCurve::SHORT_THRESHOLD_DISTANCES.fetch(:leisure) - distance_delta)

    assert short_difference < long_difference
  end

  test "demand is 100 for a leisure trip of SHORT_THRESHOLD_DISTANCE" do
    distance = Calculation::DemandCurve::SHORT_THRESHOLD_DISTANCES.fetch(:leisure)
    subject = create_leisure_subject(distance)
    expected = 100
    delta = 0.001

    assert_in_delta(subject.relative_demand(distance), expected, delta)
  end

  test "demand is 100 for a leisure trip between SHORT_THRESHOLD_DISTANCE and LONG_THRESHOLD_DISTANCE" do
    distance = (Calculation::DemandCurve::SHORT_THRESHOLD_DISTANCES.fetch(:leisure) + Calculation::DemandCurve::LONG_THRESHOLD_DISTANCES.fetch(:leisure)) / 2
    subject = create_leisure_subject(distance)
    expected = 100
    delta = 0.001

    assert_in_delta(subject.relative_demand(distance), expected, delta)
  end

  test "demand is between 0 and 100 for a leisure trip longer than LONG_THRESHOLD_DISTANCE" do
    distance = Calculation::DemandCurve::LONG_THRESHOLD_DISTANCES.fetch(:leisure) + 1
    subject = create_leisure_subject(distance)

    assert 0 < subject.relative_demand(distance)
    assert subject.relative_demand(distance) < 100
  end

  test "demand is between 0 and 100 for a leisure trip of half of the earth's circumference" do
    subject = create_leisure_subject(12500)

    assert 0 < subject.relative_demand(12500)
    assert subject.relative_demand(12500) < 100
  end

  test "demand is greater than 100 for an island leisure trip of shorter than SHORT_THRESHOLD_DISTANCE" do
    distance = Calculation::DemandCurve::SHORT_THRESHOLD_DISTANCES.fetch(:leisure) / 2
    subject = create_leisure_subject(distance)

    assert 100 < subject.relative_demand_island(distance)
  end

  test "demand is equal to 100 for an island leisure trip of between SHORT_THRESHOLD_DISTANCE and LONG_THRESHOLD_DISTANCE" do
    distance = (Calculation::DemandCurve::SHORT_THRESHOLD_DISTANCES.fetch(:leisure) + Calculation::DemandCurve::LONG_THRESHOLD_DISTANCES.fetch(:leisure)) / 2
    subject = create_leisure_subject(distance)
    expected = 100
    delta = 0.001

    assert_in_delta(subject.relative_demand_island(distance), expected, delta)
  end

  test "demand is less than 100 for an island leisure trip of more than LONG_THRESHOLD_DISTANCE" do
    distance = Calculation::DemandCurve::LONG_THRESHOLD_DISTANCES.fetch(:leisure) + 1
    subject = create_leisure_subject(distance)

    assert 0 < subject.relative_demand_island(distance)
    assert subject.relative_demand_island(distance) < 100
  end

  def create_business_subject(distance)
    Calculation::DemandCurve.new(distance, :business)
  end

  def create_leisure_subject(distance)
    Calculation::DemandCurve.new(distance, :leisure)
  end
end
