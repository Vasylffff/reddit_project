# Subreddit Flow Dataset Design

## Goal

The goal is to model **subreddit flow over time**, not just isolated post snapshots.

In this project, "subreddit flow" means how a subreddit feed evolves across repeated collection times:

- how many new posts appear
- which domains and topics show up
- how quickly posts gain engagement
- which posts persist across snapshots
- how attention shifts hour by hour

## Recommended Time Unit

Use **hourly snapshots** as the default unit.

That gives a practical balance between:

- enough temporal detail to capture fast-moving news
- manageable run volume
- manageable duplicate cleanup

If hourly is too sparse for some fast-moving events, a 30-minute cadence can be tested later.

## Two Dataset Levels

### 1. Post-Snapshot Level

Each row represents **one post as seen at one snapshot time**.

Core columns:

- `snapshot_time_utc`
- `subreddit`
- `listing_type`
- `post_id`
- `url`
- `external_link`
- `link_domain`
- `title`
- `author`
- `created_at`
- `age_minutes_at_snapshot`
- `upvotes_at_snapshot`
- `comment_count_at_snapshot`
- `upvote_ratio_at_snapshot`
- `flair`
- `is_video`
- `has_images`
- `rank_within_snapshot`
- `seen_in_snapshot` = 1

Why this matters:

- This is the main table for post growth modeling.
- It lets us compare the same post across later snapshots.

### 2. Subreddit-Snapshot Level

Each row represents **one subreddit at one snapshot time**.

Core columns:

- `snapshot_time_utc`
- `subreddit`
- `listing_type`
- `post_count_in_snapshot`
- `unique_link_domains`
- `new_post_count_since_previous_snapshot`
- `persisting_post_count_from_previous_snapshot`
- `average_upvotes`
- `median_upvotes`
- `average_comment_count`
- `median_comment_count`
- `share_of_posts_with_comments`
- `share_of_posts_with_external_links`
- `top_domain_by_frequency`
- `top_domain_share`

Why this matters:

- This is the main table for subreddit-level flow modeling.
- It summarizes how active or concentrated the feed is at each hour.

## Derived Post-Level Targets

These are realistic prediction targets for the project.

### High Engagement Target

Examples:

- `high_engagement_6h`
- `high_engagement_24h`

Definition example:

- 1 if the post is in the top 20 percent of posts in its subreddit by `comment_count_at_snapshot` or `upvotes_at_snapshot` within the chosen horizon
- 0 otherwise

### Comment Growth Target

Examples:

- `comment_delta_next_1h`
- `comment_delta_next_6h`
- `comment_delta_next_24h`

Definition:

- later comment count minus current comment count for the same post

### Survival / Persistence Target

Examples:

- `still_visible_next_hour`
- `still_visible_in_6h`

Definition:

- whether the post remains visible in the tracked subreddit/listing at a later snapshot

## Derived Subreddit-Level Targets

Examples:

- `next_hour_post_count`
- `next_hour_average_comments`
- `next_hour_new_post_count`
- `next_hour_top_domain_share`

These let us model subreddit flow at the aggregate level.

## Minimum Useful Collection Pattern

### Discovery Layer

Every hour, collect broad subreddit listing snapshots such as:

- `new`
- `hot`
- `rising`
- `top day`
- `top week`

Use:

- many posts
- comments disabled

Why:

- maximize feed coverage
- reduce wasted item budget on comment threads

### Tracking Layer

From the discovered posts, choose a smaller subset of tracked post URLs and revisit them later.

Use:

- fewer posts
- comments enabled

Why:

- measure growth and comment evolution over time

## Minimum Useful Experiment

A practical starting point:

- collect hourly discovery snapshots for 10 to 15 hours
- track 10 to 20 posts across the same period

This gives:

- subreddit flow snapshots over time
- repeated post observations
- enough structure for a first baseline model

## What "Enough Data" Means Here

Enough data does **not** mean one large scrape.

It means:

- repeated hourly subreddit snapshots
- repeated snapshots of selected posts
- enough overlap across time to compute deltas and persistence

## Recommended Immediate Next Step

Build a merged table with columns:

- `subreddit`
- `listing_type`
- `snapshot_time_utc`
- `post_id`
- `created_at`
- `upvotes_at_snapshot`
- `comment_count_at_snapshot`
- `link_domain`
- `title_length`
- `age_minutes_at_snapshot`

Then derive:

- `comment_delta_next_1h`
- `upvote_delta_next_1h`
- `still_visible_next_hour`

That is the cleanest first modeling dataset for this project.
