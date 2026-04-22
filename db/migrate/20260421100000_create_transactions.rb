class CreateTransactions < ActiveRecord::Migration[8.1]
  def change
    create_table :transactions, id: :uuid, default: 'gen_random_uuid()' do |t|
      t.decimal :amount, precision: 15, scale: 2, null: false
      t.string :description
      t.string :transaction_type, null: false
      t.date :date, null: false
      t.references :account, type: :uuid, null: false, foreign_key: true
      t.references :category, type: :uuid, null: false, foreign_key: true
      t.references :user, type: :uuid, null: false, foreign_key: true

      t.timestamps
    end

    add_index :transactions, [:user_id, :date]
    add_index :transactions, [:account_id, :user_id]
  end
end
