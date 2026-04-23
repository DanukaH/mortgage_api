FactoryBot.define do
  factory :mortgage_application do
    annual_income { 60000 }
    monthly_expenses { 500 }
    deposit_amount { 30000 }
    property_value { 300000 }
    term_years { 25 }
    status { 'pending' }
  end
end
