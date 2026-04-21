class MortgageApplication < ApplicationRecord
  validates :annual_income, presence: true, numericality: { greater_than: 0 }
  validates :monthly_expenses, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :deposit_amount, presence: true, numericality: { greater_than: 0 }
  validates :property_value, presence: true, numericality: { greater_than: 0 }
  validates :term_years, presence: true, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 40 }
end
