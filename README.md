# FanVault

A Patreon-meets-YouTube platform for creators (initially baseball players) to upload exclusive video content and share it with subscribers — either via paid subscription or direct invitation.

## What it does

- **Creator** signs up, uploads videos, sets up subscription plans or sends personal invitations
- **Subscriber** accesses content if they have an active paid subscription OR accepted an invitation from the creator
- Videos are stored privately on AWS S3 and served via signed URLs (time-limited, no direct access)

## Stack

- **Ruby on Rails 7.1**
- **PostgreSQL**
- **CarrierWave + fog-aws** — file uploads to S3 (same pattern as `ruby_trainings`)
- **Devise** — authentication
- **Pundit** — authorization
- **Stripe / Pay gem** — paid subscriptions
- **Sidekiq + Redis** — background jobs (video processing)

## Models

```
User         — creator or subscriber (rolify)
Video        — belongs to creator, uploaded to S3, processing via Sidekiq
Plan         — subscription plan (price/interval) per creator
Subscription — links subscriber to creator (paid or invited)
Invitation   — token-based invite sent by creator via email
VideoView    — tracks views per user
```

## Setup

```bash
bundle install
cp .env.example .env   # fill in your values
rails db:create db:migrate
bundle exec sidekiq     # background jobs
rails s
```

## Environment Variables

See `.env.example`. You'll need AWS credentials, Stripe keys, and a Redis URL.

## Creator Flow

1. Register → assigned `creator` role
2. Upload videos (go to `/creator/videos/new`)
3. Invite fans by email (`/creator/invitations/new`)
4. Or create a paid plan (`/creator/plans`)
5. Monitor subscribers and analytics at `/creator`

## Subscriber Flow

1. Click invitation link (email) → register/login → instant access
2. Or visit a creator's profile → subscribe via Stripe
3. Dashboard at `/subscriber` shows all subscribed creators + latest videos

## Video Access

All videos are private by default. Access check in `Video#accessible_by?(user)`:
- Creator always has access to their own videos
- Subscriber needs an active subscription (paid or invited)
- Signed S3 URLs expire after 1 hour — no hotlinking

## TODO

- [ ] AWS credentials in `rails credentials:edit`
- [ ] Stripe webhook endpoint setup
- [ ] ffmpeg for thumbnail extraction + duration metadata
- [ ] Email templates for invitations
- [ ] Mobile-responsive UI
