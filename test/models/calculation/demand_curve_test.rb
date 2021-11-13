require "test_helper"

class Calculation::DemandCurveTest < ActiveSupport::TestCase
  business_subject = Calculation::DemandCurve.new(:business)
  leisure_subject = Calculation::DemandCurve.new(:leisure)

  test "demand is zero for a business trip of zero miles" do
    subject = business_subject
    expected = 0
    delta = 0.001

    assert_in_delta(subject.relative_demand(0), expected, delta)
  end

  test "demand is between 0 and 100 for a business trip between zero and SHORT_THRESHOLD_DISTANCE miles" do
    distance = Calculation::DemandCurve::SHORT_THRESHOLD_DISTANCES.fetch(:business) / 2
    subject = business_subject

    assert 0 < subject.relative_demand(distance)
    assert subject.relative_demand(distance) < 100
  end

  test "demand is closer to zero for a short business trip than to 100 for a long business trip less than SHORT_THRESHOLD_DISTANCE" do
    distance_delta = Calculation::DemandCurve::SHORT_THRESHOLD_DISTANCES.fetch(:business) / 100
    short_subject = business_subject
    long_subject = business_subject

    short_difference = short_subject.relative_demand(distance_delta)
    long_difference = 100 - long_subject.relative_demand(Calculation::DemandCurve::SHORT_THRESHOLD_DISTANCES.fetch(:business) - distance_delta)

    assert short_difference < long_difference
  end

  test "demand is 100 for a business trip of SHORT_THRESHOLD_DISTANCE" do
    distance = Calculation::DemandCurve::SHORT_THRESHOLD_DISTANCES.fetch(:business)
    subject = business_subject
    expected = 100
    delta = 0.001

    assert_in_delta(subject.relative_demand(distance), expected, delta)
  end

  test "demand is 100 for a business trip between SHORT_THRESHOLD_DISTANCE and LONG_THRESHOLD_DISTANCE" do
    distance = (Calculation::DemandCurve::SHORT_THRESHOLD_DISTANCES.fetch(:business) + Calculation::DemandCurve::LONG_THRESHOLD_DISTANCES.fetch(:business)) / 2
    subject = business_subject
    expected = 100
    delta = 0.001

    assert_in_delta(subject.relative_demand(distance), expected, delta)
  end

  test "demand is between 0 and 100 for a business trip longer than LONG_THRESHOLD_DISTANCE" do
    distance = Calculation::DemandCurve::LONG_THRESHOLD_DISTANCES.fetch(:business) + 1
    subject = business_subject

    assert 0 < subject.relative_demand(distance)
    assert subject.relative_demand(distance) < 100
  end

  test "demand is between 0 and 100 for a business trip of half of the earth's circumference" do
    subject = business_subject

    assert 0 < subject.relative_demand(12500)
    assert subject.relative_demand(12500) < 100
  end

  test "demand is greater than 100 for an island business trip of shorter than SHORT_THRESHOLD_DISTANCE" do
    distance = Calculation::DemandCurve::SHORT_THRESHOLD_DISTANCES.fetch(:business) / 2
    subject = business_subject

    assert 100 < subject.relative_demand_island(distance)
  end

  test "demand is less than 100 for an island business trip of more than SHORT_THRESHOLD_DISTANCE" do
    distance = Calculation::DemandCurve::SHORT_THRESHOLD_DISTANCES.fetch(:business) + 1
    subject = business_subject

    assert 0 < subject.relative_demand_island(distance)
    assert subject.relative_demand_island(distance) < 100
  end

  test "demand is zero for a leisure trip of zero miles" do
    subject = leisure_subject
    expected = 0
    delta = 0.001

    assert_in_delta(subject.relative_demand(0), expected, delta)
  end

  test "demand is between 0 and 100 for a leisure trip between zero and SHORT_THRESHOLD_DISTANCE miles" do
    distance = Calculation::DemandCurve::SHORT_THRESHOLD_DISTANCES.fetch(:leisure) / 2
    subject = leisure_subject

    assert 0 < subject.relative_demand(distance)
    assert subject.relative_demand(distance) < 100
  end

  test "demand is closer to zero for a short leisure trip than to 100 for a long leisure trip less than SHORT_THRESHOLD_DISTANCE" do
    distance_delta = Calculation::DemandCurve::SHORT_THRESHOLD_DISTANCES.fetch(:leisure) / 100
    short_subject = leisure_subject
    long_subject = leisure_subject

    short_difference = short_subject.relative_demand(distance_delta)
    long_difference = 100 - long_subject.relative_demand(Calculation::DemandCurve::SHORT_THRESHOLD_DISTANCES.fetch(:leisure) - distance_delta)

    assert short_difference < long_difference
  end

  test "demand is 100 for a leisure trip of SHORT_THRESHOLD_DISTANCE" do
    distance = Calculation::DemandCurve::SHORT_THRESHOLD_DISTANCES.fetch(:leisure)
    subject = leisure_subject
    expected = 100
    delta = 0.001

    assert_in_delta(subject.relative_demand(distance), expected, delta)
  end

  test "demand is 100 for a leisure trip between SHORT_THRESHOLD_DISTANCE and LONG_THRESHOLD_DISTANCE" do
    distance = (Calculation::DemandCurve::SHORT_THRESHOLD_DISTANCES.fetch(:leisure) + Calculation::DemandCurve::LONG_THRESHOLD_DISTANCES.fetch(:leisure)) / 2
    subject = leisure_subject
    expected = 100
    delta = 0.001

    assert_in_delta(subject.relative_demand(distance), expected, delta)
  end

  test "demand is between 0 and 100 for a leisure trip longer than LONG_THRESHOLD_DISTANCE" do
    distance = Calculation::DemandCurve::LONG_THRESHOLD_DISTANCES.fetch(:leisure) + 1
    subject = leisure_subject

    assert 0 < subject.relative_demand(distance)
    assert subject.relative_demand(distance) < 100
  end

  test "demand is between 0 and 100 for a leisure trip of half of the earth's circumference" do
    subject = leisure_subject

    assert 0 < subject.relative_demand(12500)
    assert subject.relative_demand(12500) < 100
  end

  test "demand is greater than 100 for an island leisure trip of shorter than SHORT_THRESHOLD_DISTANCE" do
    distance = Calculation::DemandCurve::SHORT_THRESHOLD_DISTANCES.fetch(:leisure) / 2
    subject = leisure_subject

    assert 100 < subject.relative_demand_island(distance)
  end

  test "demand is less than 100 for an island leisure trip of more than SHORT_THRESHOLD_DISTANCE" do
    distance = Calculation::DemandCurve::SHORT_THRESHOLD_DISTANCES.fetch(:leisure) + 1
    subject = leisure_subject

    assert 0 < subject.relative_demand_island(distance)
    assert subject.relative_demand_island(distance) < 100
  end
end
