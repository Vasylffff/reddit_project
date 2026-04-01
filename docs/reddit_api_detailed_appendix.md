# Detailed Appendix for Reddit Data Access Request

## Purpose of This Appendix

This appendix is intended to provide additional detail, if requested, in support of the Reddit data access application for the academic project:

Temporal Analysis and Prediction of Engagement Dynamics in Reddit Communities

Applicant: Vasyl Shcherbatykh  
Institution: Queen Mary University of London  
Program: BSc Applied AI, School of Physical and Chemical Sciences  
Adviser: John Benton

## Expanded Project Summary

This project is a non-commercial academic research study focused on understanding how engagement develops over time in selected Reddit communities. The research aims to identify which early, publicly observable factors are associated with the later engagement outcomes of Reddit posts.

The project will examine post-level engagement dynamics using approved public Reddit submissions, comments, and associated metadata. The central analytical question is whether early information available shortly after a post is published can help estimate its later interaction trajectory.

This research is limited to academic analysis of engagement patterns within Reddit discussions. It is not intended for advertising, audience targeting, commercial profiling, or unrelated general-purpose AI model training.

## Research Questions

1. Which early post and comment features are most strongly associated with later engagement outcomes?
2. How do timing, subreddit context, and initial discussion patterns affect later post visibility and activity?
3. Can post-level predictive models estimate later engagement outcomes using only early public signals?
4. How do engagement dynamics differ across selected subreddit communities?

## Proposed Scope

The project is intended to operate on a limited and clearly defined subset of Reddit rather than unrestricted platform-wide access.

The proposed scope is:

- A selected set of topic-relevant public subreddits
- Public submissions and comments only
- A defined research collection period
- Only the minimum approved data needed for the academic analysis

Illustrative subreddit scope:

- `r/investing`
- `r/stocks`
- `r/wallstreetbets`
- Additional related subreddits only if necessary for comparative analysis

If Reddit prefers a narrower scope during review, the project can begin with fewer subreddits and expand only if separately approved.

## Data Requested

The project requests access only to approved public Reddit data necessary to support post-level engagement analysis. The intended fields include:

For submissions:

- Submission ID
- Subreddit name
- Title
- Self-text or body text where public
- Creation timestamp
- Score
- Number of comments
- Permalink
- Public URL
- Public status flags relevant to interpretation, such as stickied or locked if available

For comments:

- Comment ID
- Parent submission ID
- Subreddit name
- Comment body text where public
- Creation timestamp
- Score
- Parent identifier
- Permalink

Contextual public metadata:

- Posting time
- Relative timing of comments
- Aggregate engagement indicators derivable from approved public metadata

## Data Not Requested

The project does not request and does not require:

- Private messages
- Non-public user information
- Hidden moderation data
- Deleted-content recovery beyond what is available in approved public access
- Off-platform identity information
- Contact information
- Geolocation or other private personal information

## Why Each Data Type Is Needed

- Timestamps are needed for temporal analysis and early-engagement measurement.
- Scores and comment counts are needed to define engagement outcomes.
- Post and comment text are needed for limited NLP-based feature extraction relevant to engagement prediction.
- Subreddit identifiers are needed for cross-community comparison.
- Permalinks and public IDs are needed for reproducibility, record linkage within the approved dataset, and auditability of the research workflow.

## Intended Analytical Approach

The project will use a combination of descriptive analysis, statistical modeling, and machine learning methods to study engagement dynamics.

Planned stages include:

1. Collect approved public Reddit data from the defined subreddit set.
2. Clean and preprocess the data, including timestamp normalization and removal of unnecessary fields.
3. Construct post-level features such as early comment count, early comment velocity, initial score development, posting-hour features, and text-derived signals.
4. Build and evaluate predictive models for later engagement outcomes, such as later score bands or later comment-volume outcomes.
5. Compare patterns across subreddits and summarize results in aggregate form.

The predictive work is limited to post-level academic modeling within the approved project scope. It is not intended to create a general-purpose model trained broadly on Reddit data for unrelated downstream uses.

## Example Prediction Targets

Depending on final approved scope and data availability, the project may evaluate targets such as:

- Whether a post reaches a defined engagement threshold within 24 hours
- Later comment-count range after an initial observation window
- Relative engagement class compared with contemporaneous posts in the same subreddit

These targets are used only for academic evaluation of engagement dynamics.

## Data Volume and Minimization

The project will follow a data minimization approach.

This means:

- collecting only approved public data necessary for the stated research questions
- limiting collection to selected subreddits rather than broad unrestricted crawling
- retaining only fields necessary for temporal, textual, and engagement analysis
- avoiding unnecessary duplication of raw content

If Reddit requires a defined cap on data collection, the project can operate within a bounded volume and time window.

## Privacy and Ethical Safeguards

The project is designed to minimize privacy risk and to avoid analysis focused on individual identity.

Specifically:

- The research will not attempt to identify individual Reddit users.
- The project will not link Reddit accounts to off-platform identities.
- The project will not infer or classify sensitive personal attributes.
- The project will not build user dossiers or behavioral profiles for external use.
- Reported outputs will focus on aggregate engagement patterns and model performance.
- Any illustrative textual examples, if used at all, will be minimized and handled carefully.

## Data Storage and Security

Approved data will be stored on password-protected, researcher-controlled or institutionally controlled systems with restricted access.

Access will be limited to:

- Vasyl Shcherbatykh
- Adviser John Benton, if supervisory review is required

Data will not be publicly redistributed in raw form.

## Retention and Deletion Handling

The project will retain data only as long as necessary for the approved academic purpose.

If Reddit requires refreshed queries, updated exports, or removal handling to reflect deleted or removed content, the project will follow those requirements. The research workflow can be adapted to ensure compliance with Reddit's approved retention and deletion expectations.

## Outputs and Dissemination

Expected outputs may include:

- academic coursework submissions
- dissertation or project documentation
- model evaluation summaries
- aggregate tables, charts, and findings

Outputs will not redistribute raw Reddit datasets for unrelated third-party use.

## Compliance Statement

The project will comply with Reddit's applicable terms, policies, access restrictions, rate limits, and approved-use conditions. If approval is granted subject to narrower scope, lower volume, or additional restrictions, the project will operate within those conditions.

## Project Status and Timeline

Current status:

- Early-stage academic project setup
- No API-based data retrieval has begun yet
- Access approval is being requested before collection starts

Estimated timeline:

- Month 1: approval, final scoping, and secure pipeline setup
- Months 1-2: approved data collection and preprocessing
- Months 2-3: feature engineering and exploratory analysis
- Months 3-4: predictive modeling and evaluation
- Month 4 onward: write-up and interpretation

## Optional Clarification If Reddit Requests Narrower Scope

If needed, the project can be restricted further by:

- reducing the number of subreddits
- shortening the collection period
- capping the number of posts and comments collected
- limiting analysis to one engagement target only
- omitting textual modeling and using metadata-only analysis

The project is flexible and can be narrowed to satisfy Reddit's review requirements while preserving its academic value.
