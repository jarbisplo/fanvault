class AddCategoryToVideos < ActiveRecord::Migration[8.1]
  def change
    add_column :videos, :category, :integer
  end
end
