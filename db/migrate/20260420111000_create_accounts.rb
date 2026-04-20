class CreateAccounts < ActiveRecord::Migration[8.1]
  def change
    create_table :accounts do |t|
      t.string :name, null: false
      t.string :account_type, null: false
      t.decimal :balance, precision: 15, scale: 2, default: 0.0
      t.string :currency, default: 'BRL'
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
