require 'rails_helper'

RSpec.describe AffordabilityAssessor, "logging", type: :service do
  let(:application) { create(:mortgage_application) }

  it 'logs a structured event when an assessment is persisted' do
    output = capture_logs do
      described_class.new(application).assess_and_persist!
    end

    log_lines = output.lines.map(&:strip).reject(&:empty?)
    json_line = log_lines.find { |line| line.include?("affordability_assessment_completed") }

    expect(json_line).to be_present
    payload = JSON.parse(json_line[/\{.*\}/])
    expect(payload).to include(
      "event" => "affordability_assessment_completed",
      "application_id" => application.id,
      "decision" => application.reload.decision,
    )
  end
end
