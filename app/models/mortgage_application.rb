class MortgageApplication < ApplicationRecord
  STATUS = %w[pending approved declined ].freeze

  validates :annual_income, presence: true, numericality: { greater_than: 0 }
  validates :monthly_expenses, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :deposit_amount, presence: true, numericality: { greater_than: 0 }
  validates :property_value, presence: true, numericality: { greater_than: 0 }
  validates :term_years, presence: true, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 40 }
  validates :status, inclusion: { in: STATUS }

  validate :deposit_less_than_property_value

  before_validation :set_default_status, on: :create

  def loan_amount
    property_value - deposit_amount
  end

  private

  def set_default_status
    self.status ||= "pending"
  end

  def deposit_less_than_property_value
    return if deposit_amount.blank? || property_value.blank?

    if deposit_amount >= property_value
      errors.add(:deposit_amount, "must be less than the property value")
    end
  end
end
