class AddHlsUrlToVideos < ActiveRecord::Migration[8.1]
  def change
    add_column :videos, :hls_url, :string
  end
end
