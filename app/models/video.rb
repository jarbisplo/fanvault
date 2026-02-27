# == Schema Information
# id, creator_id, title, description, video_file, thumbnail,
# duration_seconds, status (processing/published/draft),
# visibility (subscribers_only/public), views_count, created_at, updated_at

class Video < ApplicationRecord
  belongs_to :creator, class_name: 'User'
  has_many :video_views, dependent: :destroy

  mount_uploader :video_file, VideoUploader
  mount_uploader :thumbnail, ThumbnailUploader

  enum :status,     { draft: 0, processing: 1, published: 2, archived: 3 }
  enum :visibility, { subscribers_only: 0, public_video: 1 }
  enum :category,   {
    health_nutrition:  0,
    sleep_recovery:    1,
    mental_game:       2,
    physical_training: 3,
    fielding_and_skills: 4
  }, prefix: true

  CATEGORY_LABELS = {
    'health_nutrition'    => 'Health & Nutrition',
    'sleep_recovery'      => 'Sleep & Recovery',
    'mental_game'         => 'Mental Game & Discipline',
    'physical_training'   => 'Physical Training',
    'fielding_and_skills' => 'Fielding, Footwork & Bat Speed'
  }.freeze

  validates :title, presence: true, length: { maximum: 120 }
  validates :description, length: { maximum: 2000 }
  validates :video_file, presence: true
  validates :creator, presence: true

  scope :published,    -> { where(status: :published) }
  scope :recent,       -> { order(created_at: :desc) }
  scope :for_creator,  ->(creator) { where(creator: creator) }
  scope :by_category,  ->(cat) { where(category: cat) }

  after_commit :enqueue_processing, on: :create

  def accessible_by?(user)
    return true if visibility == 'public_video'
    return false if user.nil?
    return true if user == creator
    user.active_subscription_for?(creator)
  end

  def formatted_duration
    return '--:--' unless duration_seconds
    mm, ss = duration_seconds.divmod(60)
    hh, mm = mm.divmod(60)
    hh > 0 ? format('%02d:%02d:%02d', hh, mm, ss) : format('%02d:%02d', mm, ss)
  end

  def increment_views!
    increment!(:views_count)
  end

  private

  def enqueue_processing
    VideoProcessingJob.perform_later(id)
  end
end
