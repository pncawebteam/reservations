class ChangeDeletedAtToDateTime < ActiveRecord::Migration
  def change
    remove_column :users, :deleted_at
    remove_column :equipment_objects, :deleted_at
    remove_column :equipment_models, :deleted_at
    remove_column :categories, :deleted_at
    
    add_column :users, :deleted_at, :datetime
    add_column :equipment_objects, :deleted_at, :datetime
    add_column :equipment_models, :deleted_at, :datetime
    add_column :categories, :deleted_at, :datetime
  end
end
