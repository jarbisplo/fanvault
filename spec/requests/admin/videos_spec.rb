require 'rails_helper'

RSpec.describe "Admin::Videos", type: :request do
  let(:admin) { create(:user, :admin) }
  let(:video) { create(:video, creator: admin, title: "Original Title") }

  before { sign_in admin }

  describe "PATCH /admin/videos/:id" do
    context "without uploading a new video file" do
      it "updates title without triggering video_file validation" do
        patch admin_video_path(video), params: {
          video: { title: "Updated Title", description: "New desc" }
        }
        expect(response).to redirect_to(admin_videos_path)
        expect(video.reload.title).to eq("Updated Title")
      end

      it "does not show video file blank error" do
        patch admin_video_path(video), params: {
          video: { title: "Updated" }
        }
        expect(response).not_to have_http_status(:unprocessable_entity)
      end
    end

    context "toggling free flag" do
      it "can mark a video as free" do
        patch admin_video_path(video), params: {
          video: { free: true }
        }
        expect(video.reload.free?).to be true
      end

      it "can unmark a free video" do
        video.update_column(:free, true)
        patch admin_video_path(video), params: {
          video: { free: false }
        }
        expect(video.reload.free?).to be false
      end
    end
  end
end
