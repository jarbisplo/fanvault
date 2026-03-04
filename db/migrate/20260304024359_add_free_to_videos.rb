class AddFreeToVideos < ActiveRecord::Migration[8.1]
  def change
    add_column :videos, :free, :boolean, default: false, null: false
  end
end
