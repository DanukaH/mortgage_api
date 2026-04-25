class AddAssessmentResultsToMortgageApplications < ActiveRecord::Migration[8.1]
  def change
    add_column :mortgage_applications, :loan_to_value, :decimal
    add_column :mortgage_applications, :debt_to_income, :decimal
    add_column :mortgage_applications, :maximum_borrowing, :decimal
    add_column :mortgage_applications, :decision, :string
    add_column :mortgage_applications, :explanation, :text
    add_column :mortgage_applications, :assessed_at, :datetime
  end
end
