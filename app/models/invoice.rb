require 'sequel'

DB = Sequel.connect(ENV.fetch('DATABASE_URL', 'sqlite://invoices.sqlite3'))
Sequel.extension :migration
Sequel::Migrator.run(DB, File.expand_path('../../db/migrations', __dir__))

class Invoice < Sequel::Model(DB[:invoices])
  def total
    (unit_price * item_count).round(2)
  end
end
