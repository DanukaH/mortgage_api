class AddStatusToMortgageApplications < ActiveRecord::Migration[8.1]
  def change
    add_column :mortgage_applications, :status, :string
  end
end
