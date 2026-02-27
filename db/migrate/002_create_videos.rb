class CreateVideos < ActiveRecord::Migration[7.1]
  def change
    create_table :videos do |t|
      t.references :creator,      null: false, foreign_key: { to_table: :users }
      t.string     :title,        null: false
      t.text       :description
      t.string     :video_file
      t.string     :thumbnail
      t.integer    :duration_seconds
      t.integer    :status,       null: false, default: 0   # draft
      t.integer    :visibility,   null: false, default: 0   # subscribers_only
      t.integer    :views_count,  null: false, default: 0
      t.timestamps
    end

    add_index :videos, [:creator_id, :status]
    add_index :videos, :created_at
  end
end
