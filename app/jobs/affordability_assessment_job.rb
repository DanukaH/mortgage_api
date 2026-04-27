class AffordabilityAssessmentJob < ApplicationJob
  queue_as :default

  def perform(application_id)
    started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)
    application = MortgageApplication.find(application_id)

    if application.assessed?
      log_skipped(application_id)
      return
    end

    AffordabilityAssessor.new(application).assess_and_persist!
    log_completed(application_id, started_at)
  end

  private

  def log_skipped(application_id)
    Rails.logger.info({
      event: "affordability_assessment_skipped",
      reason: "already_assessed",
      application_id: application_id
    }.to_json)
  end

  def log_completed(application_id, started_at)
    duration_ms = ((Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at) * 1000).round(2)
    Rails.logger.info({
      event: "affordability_assessment_job_completed",
      application_id: application_id,
      duration_ms: duration_ms
    }.to_json)
  end
end
