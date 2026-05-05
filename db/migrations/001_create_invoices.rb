Sequel.migration do
  change do
    create_table(:invoices) do
      primary_key :id
      String :client_name, null: false
      String :currency, null: false, default: 'AUD'
      Float :amount, null: false
      Integer :item_count, null: false, default: 1
      Float :unit_price, null: false
      String :status, null: false, default: 'Generated'
      DateTime :created_at, default: Sequel::CURRENT_TIMESTAMP
    end
  end
end
