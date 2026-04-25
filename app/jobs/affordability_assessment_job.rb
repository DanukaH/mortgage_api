class AffordabilityAssessmentJob < ApplicationJob
  queue_as :default

  def perform(application_id)
    application = MortgageApplication.find(application_id)
    return if application.assessed?

    AffordabilityAssessor.new(application).assess_and_persist!
  end
end
