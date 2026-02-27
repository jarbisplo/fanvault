class CreatePlansSubscriptionsInvitations < ActiveRecord::Migration[7.1]
  def change
    create_table :plans do |t|
      t.references :creator,       null: false, foreign_key: { to_table: :users }
      t.string     :name,          null: false
      t.text       :description
      t.integer    :price_cents,   null: false, default: 0
      t.integer    :interval,      null: false, default: 0   # monthly
      t.string     :stripe_price_id
      t.boolean    :active,        null: false, default: true
      t.timestamps
    end

    create_table :subscriptions do |t|
      t.references :creator,    null: false, foreign_key: { to_table: :users }
      t.references :subscriber, null: false, foreign_key: { to_table: :users }
      t.references :plan,       foreign_key: true
      t.references :invitation, foreign_key: true
      t.integer    :status,     null: false, default: 0    # pending
      t.integer    :kind,       null: false, default: 0    # paid
      t.string     :stripe_subscription_id
      t.datetime   :current_period_end
      t.timestamps
    end

    add_index :subscriptions, [:creator_id, :subscriber_id], unique: true

    create_table :invitations do |t|
      t.references :creator,    null: false, foreign_key: { to_table: :users }
      t.references :subscriber, foreign_key: { to_table: :users }
      t.string     :email,      null: false
      t.string     :token,      null: false
      t.text       :note
      t.integer    :status,     null: false, default: 0   # pending
      t.datetime   :expires_at, null: false
      t.datetime   :accepted_at
      t.timestamps
    end

    add_index :invitations, :token, unique: true
    add_index :invitations, [:creator_id, :email]

    create_table :video_views do |t|
      t.references :video, null: false, foreign_key: true
      t.references :user,  foreign_key: true
      t.timestamps
    end

    add_index :video_views, [:video_id, :user_id], unique: true
  end
end
