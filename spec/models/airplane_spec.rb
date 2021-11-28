require "rails_helper"

RSpec.describe Airplane do
  context "has_operator?" do
    it "is true when the airplane is owned" do
      subject = Airplane.create!(
        operator_id: 1,
        construction_date: Date.today,
      )

      expect(subject.has_operator?).to be true
    end

    it "is false when the airplane is not owned" do
      subject = Airplane.create!(
        operator_id: nil,
        construction_date: Date.today,
      )

      expect(subject.has_operator?).to be false
    end
  end
end
