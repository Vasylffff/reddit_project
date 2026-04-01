# Codex Handover Summary

Last updated: 2026-04-01

This file explains the main work that was done in this repo during the recent cleanup, pipeline fixes, modeling changes, and visual-report work.

It is written as a practical project handover, not as a commit log.

## 1. What the project is doing now

The active project is a Reddit flow-tracking pipeline built around the public Reddit `.json` endpoints.

Current high-level flow:

1. `run_collection_schedule_window.ps1`
2. `run_free_collection_schedule.py`
3. `collect_reddit_free.py`
4. `build_reddit_history.py`
5. `build_free_tracking_pool.py`
6. exact-post refresh through `collect_reddit_free.py --post-urls-file ...`
7. `build_prediction_dataset.py`
8. `build_naive_forecast.py`
9. `evaluate_naive_forecast.py`
10. `build_post_case_studies.py`
11. `build_subreddit_health.py`
12. `build_visual_report.py`
13. `export_history_to_sqlite.py`

So the live system is:

- discovery scrape from subreddit feeds
- cumulative history build
- direct re-observation of chosen posts
- prediction dataset build
- reporting and chart generation

## 2. Apify cleanup and naming cleanup

The repo had an older Apify-era structure mixed into the current free Reddit JSON flow.

Main cleanup decisions:

- confirmed that the active background collector does not use Apify
- removed old Apify-only pieces that were not part of the live path
- renamed the active data/output naming so the current pipeline says `reddit` / `reddit_json` instead of `apify` where possible

Important consequence:

- the live pipeline should now be understood as Reddit JSON collection, not Apify collection
- some historical/generated data may still contain old strings from earlier runs, but the active flow is Reddit-based

## 3. Observation strategy change

One major issue was that the old rolling exact-post pool was not ideal for popularity prediction.

Why that mattered:

- a rolling pool is good for monitoring interesting posts right now
- it is not ideal for learning full post life trajectories
- it can bias tracking toward posts that already look strong

The tracking pool was split into two lanes in `build_free_tracking_pool.py`:

- `data/tracking/prediction_observation_pool_latest.csv`
  Fixed cohort for prediction. Posts stay in for a defined observation window.

- `data/tracking/live_watch_pool_latest.csv`
  Rolling shortlist for posts that look important right now.

- `data/tracking/free_observation_pool_latest.csv`
  Combined collector input used by the exact-post refresh.

This means the project now does both:

- stable trajectory collection for prediction
- rolling monitoring for live-interest posts

## 4. Lifecycle/state model change

The old state logic treated `dead` too bluntly for prediction work.

Problem:

- visually, some posts clearly looked finished earlier than the old label reflected
- in other cases, the old `dead` label could arrive too early or too inconsistently
- this was not ideal for forecasting the flow of a post through time

The lifecycle logic was changed so the state progression now supports:

- `surging`
- `alive`
- `cooling`
- `dying`
- `dead`

Key idea:

- `dying` is now the earlier warning state
- `dead` is more conservative and should mean the post is truly in a flat tail

This change affected:

- `build_reddit_history.py`
- `build_prediction_dataset.py`
- `build_naive_forecast.py`
- `build_subreddit_health.py`

New important output:

- `data/history/reddit/dying_posts_latest.csv`

## 5. Prediction dataset changes

The model-ready dataset was extended so it can support post-flow prediction better.

Explicit next-step labels now include:

- `rising_next_snapshot`
- `dying_next_snapshot`
- `dead_next_snapshot`
- `weakening_next_snapshot`

This makes the project more suitable for:

- predicting whether a post is likely to keep rising
- predicting whether it is entering decline
- forecasting short-horizon trajectory rather than only static popularity

Main file:

- `build_prediction_dataset.py`

Main output:

- `data/models/reddit/prediction_next_hour.csv`

## 6. Forecast changes

The naive forecasting layer was updated to match the new lifecycle logic.

It now includes a more explicit flow-style interpretation, including:

- `predicted_flow_state_next_hour`
- a `dying_watch` style recommendation

Main file:

- `build_naive_forecast.py`

Main outputs:

- `data/history/reddit/naive_next_hour_forecast_latest.csv`
- `data/history/reddit/naive_forecast_leaderboard.csv`
- `data/history/reddit/naive_forecast_watchlist_by_subreddit.csv`

## 7. Gradient-descent baseline

A subreddit-level gradient-descent regression baseline was run for next-hour prediction.

Main file:

- `train_next_hour_gradient_descent.py`

Outputs:

- `data/models/reddit/sgd_by_subreddit/sgd_subreddit_metrics.csv`
- `data/models/reddit/sgd_by_subreddit/sgd_metrics.json`
- `data/models/reddit/sgd_by_subreddit/sgd_subreddit_coefficients.csv`

Result:

- the baseline trains and runs
- but it is not currently better than the existing naive baseline on most subreddits

So this exists as a benchmark, not as the current best method.

## 8. Visual/reporting changes

### Existing report improvements

The main visual-report generator is:

- `build_visual_report.py`

Existing charts were kept and improved:

- example post timeline
- subreddit state mix
- subreddit attention vs popularity
- subreddit hourly trends

Important fixes:

- the subreddit trend chart was expanded from 12 to 24 snapshots per subreddit
- duplicate-looking colored lines were fixed by using day + hour labels instead of only hour labels
- subreddit-level trend panels now show more useful metrics like total upvotes/comments and sample churn

### Dead-post examples

A dedicated dead-post example generator was added:

- `build_dead_post_examples.py`

Outputs:

- `data/analysis/reddit/visuals/dead_examples/dead_post_timeline_politics_*.png`
- `data/analysis/reddit/visuals/dead_examples/dead_post_timeline_worldnews_*.png`
- `data/analysis/reddit/visuals/dead_examples/dead_post_examples_summary.md`

Purpose:

- show what a "dead" post looks like in timeline form
- make the drop in velocity visually understandable

### New charts added from the later request

Three new visuals were added to the main report:

1. `flow_trajectory_by_subreddit.png`
   Visual version of flow/state trajectories by age bucket, using historical transition behavior for one representative topic in each subreddit.

2. `live_pulse_dashboard.png`
   Current-vs-baseline active-rate chart for the strongest topic/subreddit deviations right now.

3. `deviation_history_timeline.png`
   Historical timeline of peak deviation magnitude over hourly windows.

These now live in:

- `data/analysis/reddit/visuals/`

And they are referenced in:

- `data/analysis/reddit/visuals/visual_report_summary.md`

## 9. Deviation and pulse logic

The repo already had useful flow-analysis scripts that were connected more clearly to the visual layer:

- `predict_post_flow.py`
- `detect_flow_deviation.py`

These provide the logic behind:

- Markov-style flow behavior by age bucket
- current-vs-baseline activity comparison
- deviation spikes by topic and subreddit

Note about the deviation-history chart:

- `data/history/reddit/deviation_log.csv` currently has only a limited saved history
- because of that, the visual timeline was reconstructed from the historical snapshots rather than relying only on the logged file
- extreme tiny-baseline outliers were capped in the chart so the timeline remains readable

## 10. Scheduler bug fix

When rerunning a manual hour slot, the scheduler failed because some generated CSV files had a hidden UTF-8 BOM before the `subreddit` header.

Symptoms:

- the scheduler said the manifest was missing required columns
- the file looked correct when opened normally

Fix:

- CSV header normalization was added so hidden BOM characters are stripped before validation

Files fixed:

- `run_free_collection_schedule.py`
- `build_schedule_manifests.py`

This is important because it allows manual reruns like:

- `.\.venv\Scripts\python.exe run_free_collection_schedule.py --hour 15`

## 11. Manual 15:00 rerun that was completed

A full 15:00 rerun was performed for the March 31, 2026 slot.

That rerun included:

- 15:00 discovery scrape
- history rebuild
- tracking-pool rebuild
- exact-post refresh using the combined pool
- prediction rebuild
- forecast rebuild
- case studies
- validation
- visuals
- subreddit health
- SQLite export

15:00 metadata was confirmed in the raw files.

One warning from that rerun:

- the exact-post refresh hit Reddit `429` rate limits on some tracked posts
- 14 of 525 exact post targets were skipped
- the rest of the pipeline still completed successfully

## 12. SQLite export

Earlier in the work there was a temporary `history.db` lock during export.

Later this was rerun successfully, and SQLite is now current again.

Database file:

- `data/history/reddit/history.db`

Tables include:

- `post_snapshots`
- `comment_snapshots`
- `subreddit_snapshots`
- `subreddit_health_trend`
- `subreddit_health_latest`
- `latest_post_status`
- `prediction_next_hour`
- `post_timeline_points`
- and the latest leaderboard/forecast tables

## 13. Current important output locations

Raw collection:

- `data/raw/reddit_json/`

History:

- `data/history/reddit/`

Model-ready tables:

- `data/models/reddit/`

Tracking pools:

- `data/tracking/`

Visuals:

- `data/analysis/reddit/visuals/`

## 14. Most important files to know

Collector and scheduling:

- `collect_reddit_free.py`
- `run_free_collection_schedule.py`
- `run_collection_schedule_window.ps1`
- `build_schedule_manifests.py`

History and labeling:

- `build_reddit_history.py`
- `build_free_tracking_pool.py`
- `build_subreddit_health.py`

Prediction and forecasting:

- `build_prediction_dataset.py`
- `build_naive_forecast.py`
- `evaluate_naive_forecast.py`
- `predict_post_flow.py`
- `detect_flow_deviation.py`

Reporting:

- `build_visual_report.py`
- `build_dead_post_examples.py`
- `build_post_case_studies.py`
- `export_history_to_sqlite.py`

## 15. Practical meaning of the current system

The system now tries to do three related jobs at once:

1. Observe Reddit posts and comments over time
2. Preserve enough trajectory context to predict flow/popularity
3. Surface live anomalies and visual explanations in a way that is easy to inspect

The biggest design improvement made during this work was probably this:

- prediction tracking is no longer the same thing as live monitoring

That split makes the data more useful for research.

## 16. If you continue this work next

Best next directions:

- polish the new visuals for presentation quality
- collect a longer saved deviation-log history instead of reconstructing it
- compare flow classifiers against the current naive baseline
- tune the fixed cohort window and admission rules if you want a different prediction horizon
- review whether the current `dying` thresholds feel right across all five subreddits

