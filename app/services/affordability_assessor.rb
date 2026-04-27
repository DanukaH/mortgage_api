# Assesses mortgage affordability for a given MortgageApplication.
#
# Assumptions:
# - Max LTV: loan must not exceed 90% of property value
# - Max DTI: estimated monthly repayment must not exceed 43% of monthly income
# - Interest rate: fixed annual rate used of 5% for monthly repayment estimate
# - Maximum borrowing: lowest value of either 4.5x annual income or 90% of property value

class AffordabilityAssessor
  MAX_LTV = 0.9
  MAX_DTI = 0.43
  INTEREST_RATE = 0.05
  MAX_INCOME_MULTIPLIER = 4.5

  attr_reader :application

  def initialize(application)
    @application = application
  end

  def assess
    {
      loan_to_value: ltv.round(4),
      debt_to_income: dti.round(4),
      maximum_borrowing: max_borrowing.round(2),
      decision: decision,
      explanation: explanation
    }
  end

  def assess_and_persist!
    result = assess
    application.update!(
      loan_to_value: result[:loan_to_value],
      debt_to_income: result[:debt_to_income],
      maximum_borrowing: result[:maximum_borrowing],
      decision: result[:decision],
      explanation: result[:explanation],
      status: "assessed",
      assessed_at:       Time.current
    )
    log_assessment_event(result)
    result
  end

  private

  def log_assessment_event(result)
    Rails.logger.info({
      event: "affordability_assessment_completed",
      application_id: application.id,
      decision: result[:decision],
      loan_to_value: result[:loan_to_value],
      debt_to_income: result[:debt_to_income],
      maximum_borrowing: result[:maximum_borrowing]
    }.to_json)
  end

  def ltv
    application.loan_amount / application.property_value.to_f
  end

  def dti
    (estimated_monthly_payment + application.monthly_expenses.to_f) / monthly_income
  end

  def monthly_income
    application.annual_income / 12.0
  end

  def estimated_monthly_payment
    p = application.loan_amount.to_f
    r = INTEREST_RATE / 12.0
    n = application.term_years * 12.0

    return p / n if r.zero?

    (p * r * (1 + r) ** n) / ((1 + r) ** n - 1)
  end

  def max_borrowing
    [
      application.property_value * MAX_LTV,
      application.annual_income * MAX_INCOME_MULTIPLIER
    ].min
  end

  def approved?
    ltv <= MAX_LTV && dti <= MAX_DTI && application.loan_amount <= max_borrowing
  end

  def decision
    approved? ? "approved" : "declined"
  end

  def explanation
    reasons = []
    reasons << "Loan to Value Ratio (LTV) of #{pct(ltv)} exceeds the maximum allowed #{pct(MAX_LTV)}." if ltv > MAX_LTV
    reasons << "Debt to Income Ratio (DTI) of #{pct(dti)} exceeds the maximum allowed #{pct(MAX_DTI)}." if dti > MAX_DTI
    reasons << "Loan amount exceeds the maximum borrowing amount of £#{max_borrowing.round(2)}." if application.loan_amount > max_borrowing

    if reasons.empty?
      "Application meets all affordability criteria. LTV: #{pct(ltv)}, DTI: #{pct(dti)}."
    else
      reasons.join(" ")
    end
  end

  def pct(ratio)
    "#{(ratio * 100).round(1)}%"
  end
end
