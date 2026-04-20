class CreateMortgageApplications < ActiveRecord::Migration[8.1]
  def change
    create_table :mortgage_applications do |t|
      t.decimal :annual_income
      t.decimal :monthly_expenses
      t.decimal :deposit_amount
      t.decimal :property_value
      t.integer :term_years

      t.timestamps
    end
  end
end
