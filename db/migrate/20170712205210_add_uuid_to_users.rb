class AddUuidToUsers < ActiveRecord::Migration
  def change
    add_column :users, :uuid, :string, default: '', length: '128'
    add_column :users, :login, :string, default: '', length: '128'
    add_column :users, :identity, :json

    add_index "users", ["uuid"], name: "index_users_on_uuid", using: :btree
  end
end
