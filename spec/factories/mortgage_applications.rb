FactoryBot.define do
  factory :mortgage_application do
    annual_income { "9.99" }
    monthly_expenses { "9.99" }
    deposit_amount { "9.99" }
    property_value { "9.99" }
    term_years { 1 }
  end
end
