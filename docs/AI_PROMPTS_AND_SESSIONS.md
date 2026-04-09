# AI Prompts and Session Documentation

Complete documentation of all AI tool usage across the project, including exact prompts, session timelines, and tool transitions.

## Tools Used

| Tool | Dates | Prompts | Purpose |
|------|-------|---------|---------|
| OpenAI Codex | 24–31 March 2026 | 366 (session 1: 352, session 2: 14) | Initial setup, collection pipeline, pipeline refactoring |
| Claude Code (Anthropic, Opus 4.6) | 1–8 April 2026 | ~1,500+ across 4 sessions | Analysis, prediction, topic lifecycle, report writing |

---

## Codex Session 1 (24–31 March, 352 prompts)

### Day 1: March 24 — Project Start

**14:12** — First prompt:
> "was up with agent thing what it's allows you?"

**14:13** — Project definition:
> "ok i want to make a project that will analyse redit flow and predict it. Firstly i wnat to take a new data"

**14:21** — API discovery:
> "but we dont' have yet api key although"

**14:37** — PRAW attempt:
> "ok can we use PRaw or something like that?"

**14:39** — API dependency realisation:
> "we still need api isn't?"

**14:43** — Fallback data search:
> "Can you look for redit data that we can use to train model"

**15:40** — API frustration:
> "i tryed to look out for the thing after an hour and nothing"

### Day 2: March 26 — Apify and Free JSON Discovery

**11:21** — Apify investigation:
> "what's problem wit apify again?"

**11:42** — First successful data collection:
> "Saved 10 item(s)" (Apify run)

**11:51** — Core project question:
> "i mean we want to predict the flow of the news throw redit roots appearing is this possible?"

**12:08** — Realisation about continuous collection:
> "wait so to get data we would need to constantly analyze reddit isn't?"

**12:24** — Automation idea:
> "can we make automated program that will start to collect data throw particular period of time?"

**12:34** — Seeing it work:
> "wholly shit"

**12:57** — Queue design:
> "like through one hour we gonna run in queue all 5 subreddits"

**15:20** — Post lifecycle question:
> "for how long we will take to post became old? we would need to identify it and fast"

**15:22** — Dead post concept:
> "we like need to identify is post alive or dead by the amount of activity"

**15:29** — Efficiency thinking:
> "and we would need to not analyse much post that are cooling though"

**23:02** — Free vs Apify comparison:
> "i see i mean for our understanding we need use free to understand the flow and apify to look around more precise?"

**23:05** — Apify abandoned:
> "i do not understand the usefulness of apify because for our prediction we tend to use same thing that we can find freely no?"

### Day 3: March 27 — Data Monitoring

**00:18** — Hybrid approach:
> "ok now can we make so free would analyses mostly data and in most interesting one we would use apify"

**00:57** — Tracking requirement:
> "wait but we need to see all momentum from all new posts unless they are dead"

**10:48** — Reddit structure question:
> "no like i talking about structure of reddit. There is root and root can contain even more root right?"

**17:29** — Temporal analysis:
> "i mean i think it's fine can we make some analysis throw same post but in different time?"

### Day 4: March 28 — Comments and Feature Design

**11:21** — Comment scraping decision:
> "can we keeping them on automatically? Bth we would need to scrape comments by ourselves so forget about apify for now"

**12:08** — Gradient descent concept:
> "no i meant gradient descent our score falling over time anyway because score is upvote divide over time yes?"

**14:21** — Feature engineering:
> "But for this project, the bigger issue right now is probably: feature design, separating post phases by age/time"

### Day 7: March 31 — Codex Session 1 Final Prompts

**09:38** — Visualisation request:
> "can we make graph of example of go of 1 post and presentation of the subreddits in general?"

---

## Codex Session 2 (31 March, 14 prompts)

**09:57** — Correcting assumptions:
> "we don't use apify"

**09:59** — Background collection clarification:
> "there is background thing that collects the reddit info through json"

**10:37** — Subreddit-level prediction:
> "we need to make something more like it through total subreddits"

**11:43** — Post tracking concern:
> "wait do we observe same post over time by ourselves or no?"

**11:46** — Context loss frustration:
> "hm not it's not good though we losing context of observing a bit. I wanted predict post popularity"

**12:10** — Dead post visualisation:
> "that is interesting can you make a graph example of dead post in politics and worldnews?"

**12:26** — Prediction scope:
> "hm can we make prediction of post predicting rising and like dying kinda stuff because this is beautiful and looks like something too obvious. Bth we need to change definition of dead"

**12:57** — Flow prediction:
> "can we predict post flow?"

**13:33** — Per-post gradient descent:
> "ok now can we make the gradient descent on each post? through different subreddits of course"

**16:29** — Visualisation requests:
> Asked for: flow trajectory chart, live pulse dashboard, deviation history timeline

---

## Claude Code Session 1 (1 April, 243 prompts)

### Post-Level Prediction Development

> "have a look here and understand what is going on"

> "i am trying to predict general flow and just by post is this poisble?"

> "ok now can we predict post flow with coments/"

> "no, what about the algorithm to predict it? Any thoughts? particular formaul etc etc"

> "wow so we got 80 kinda right and 20 not right? or how it works"

> "whait 64 in total right?"

> "64 for each subredit?"

> "a whait 72 for politics? wowy and we see it's releted to how much data it is"

### Dead Post Detection

> "byh i think we need to identify much erlier the dead post and don't look them up uless they will somehow get popular agin"

> "what we define dead?"

> "hm maybe we can see the erlie dead on differnernce betwen velocites? there is particular patern on that"

### Scenario Layer (Developer's Idea)

> "ok what do you think about general flow like i thought general flow is going throw actuall like action that would hapened in futere and we can't predict that"

> "ok so example i gueees that trump would do something stupid at next week... ANd than i apply this sugested from the head constant to my formul. As a parmater to play on"

### Feasibility Questions

> "let's talk about general one. Firtly can we train on it actauly? and can we somehow test it? Secondly is it would be actaully posible predict or we would need to add something like key factor of rising popularity at some point?"

> "after a couple of hours of observation, would we have general understanding would people discuss it on good level or not?"

### Collection Gap

> "the problem is at around 1 time i go to subway which don't have internet at somepoint and same goes for going back plus the time i gorgeting about it at all"

---

## Claude Code Session 2 (1–6 April, 732 prompts — other machine)

### Analysis Scripts Development (15+ scripts built)

VADER sentiment, Gini coefficient, velocity curves, cross-subreddit analysis, keyword trends, post timing, domain analysis, title style, author analysis, sentiment trajectory.

### Key Findings From This Session

- Negative sentiment = longer survival (counterintuitive)
- Gini coefficient: strongest predictor at 46% feature importance
- 74.5% accuracy exposed as feature leakage (counting, not analysing)
- Multi-horizon: ROC decays from 0.843 (1h) to 0.57 (7d)
- Surging detection: 0.987 ROC AUC

### Key Developer Prompts

> "Can we predict the mood? of positive negative thing"

> "our accuracy ironically rising"

> "aaa dead alibe auc is it?"

> "whait max roc is 1 right?"

> "this one is wrong our defiing of smal emerging is basically all new small post that are rising"

> "maybe you didn't got me i want you to predict how popular will be the topics/ Like ukraine"

> "i said it wrong i mean can we predict it as a number you knoq if for example we see rise will it rises even more"

> "i liturly can predic the flow of post but i can't of keywords"

> "which even more ridciulus because we can predict posts on good maner, CAn we conect that?"

> "wow so we can predict by 1 post on new topic?"

### Developer Catching AI Mistakes

> "alive/surging state labels don't help they never should have i don't know why claud suggested using them"

> "wait so we using random forest everywhere?"

> "hahaha i mean not much parameters on each isn't?"

---

## Claude Code Session 3 (7–8 April, 501 prompts)

### Topic Lifecycle Pipeline

- Merged data from second machine (3,278 + 1,862 = 5,140 raw files)
- Co-occurrence pair detection: 0.813 ROC temporal validation
- Content-agnostic detection across all subreddit types
- Complete lifecycle: emergence → growth → spread → decline → death → revival

### Key Topic Models Built

| Task | ROC AUC |
|------|---------|
| Peaked or growing? | 0.958 |
| Will it die tomorrow? | 0.890 |
| Quick vs slow death | 0.996 |
| Ongoing vs one-shot | 0.970 |
| Subreddit spread (r/politics) | 0.756 |

### Model Comparison and Hyperparameter Tuning

- 5 classifiers × 7 tasks × 36 configurations
- Logistic Regression beats Random Forest on emergence (0.860 vs 0.829)
- Decision Tree improved +0.265 with depth tuning
- Gradient Boosting improved +0.122 with learning rate tuning

### Report Writing

- 16 figures generated
- HTML preview + Word doc
- Multiple draft iterations

---

## Claude Code Session 4 (8–9 April, 52+ prompts — this session)

### Session Reconstruction and Report Refinement

- Reconstructed full project history across all sessions
- Extracted prompts from all session JSONL files
- Added algorithm understanding/struggle steps to report
- Generated collection gap problem figure
- Trimmed report to 2,000 word limit
- Fixed grammar, figure numbering, references
- Generated final PDF
- Pushed everything to GitHub

---

## Key Decisions Made by Developer (Not AI)

| Decision | Context |
|----------|---------|
| Free JSON endpoints over Apify | Developer discovered the approach, AI verified it |
| Velocity difference for dead detection | Developer proposed the pattern, became variance collapse |
| Scenario parameter for Markov | Developer invented the concept of external event injection |
| Topic-level prediction | Developer pushed past post-level ceiling, AI had not suggested this |
| Rejecting state labels for topics | Developer caught bad AI advice, became a project rule |
| Per-subreddit model separation | Developer connected accuracy differences to data volume |
| Model comparison across classifiers | Developer noticed Random Forest was used everywhere |
| First-post comment count as bridge | Emerged from developer's systematic exploration |

---

## Session Files (for verification)

### Codex Sessions (on development machine)
- `C:\Users\Basyl\.codex\sessions\2026\03\24\rollout-...019d2030.jsonl`
- `C:\Users\Basyl\.codex\sessions\2026\03\31\rollout-...019d4353.jsonl`

### Claude Code Sessions
- `241899b4-292e-4a05-8ed3-68d2ed426a84.jsonl` (Apr 1, 243 messages, 2.5MB)
- `745d090e-3352-42a5-932a-d4ca7225ae05.jsonl` (Apr 1-6, 732 messages, 11MB)
- `f199ae2f-7774-4ab3-9629-80259291453b.jsonl` (Apr 7-8, 501 messages, 7.5MB)
- `9847cc97-e3d2-4c8b-9452-794653483501.jsonl` (Apr 8-9, 52+ messages)

### Handover Documents
- `docs/codex_handover_summary.md` — Formal Codex → Claude handover
- `docs/session_history_reconstruction.md` — Full timeline with sources
